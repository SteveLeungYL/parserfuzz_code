#include "./sql_parse_entry.h"


/* Helper functions */


const char *ER_THD(const THD *thd, int mysql_errno) {
  return thd->variables.lc_messages->errmsgs->lookup(mysql_errno);
}

class Parser_oom_handler : public Internal_error_handler {
 public:
  Parser_oom_handler() : m_has_errors(false), m_is_mem_error(false) {}
  bool handle_condition(THD *thd, uint sql_errno, const char *,
                        Sql_condition::enum_severity_level *level,
                        const char *) override {
    if (*level == Sql_condition::SL_ERROR) {
      m_has_errors = true;
      /* Out of memory error is reported only once. Return as handled */
      if (m_is_mem_error &&
          (sql_errno == EE_CAPACITY_EXCEEDED || sql_errno == EE_OUTOFMEMORY))
        return true;
      if (sql_errno == EE_CAPACITY_EXCEEDED || sql_errno == EE_OUTOFMEMORY) {
        m_is_mem_error = true;
        if (sql_errno == EE_CAPACITY_EXCEEDED)
          my_error(ER_CAPACITY_EXCEEDED, MYF(0),
                   static_cast<ulonglong>(thd->variables.parser_max_mem_size),
                   "parser_max_mem_size",
                   ER_THD(thd, ER_CAPACITY_EXCEEDED_IN_PARSER));
        else
          my_error(ER_OUT_OF_RESOURCES, MYF(ME_FATALERROR));
        return true;
      }
    }
    return false;
  }

 private:
  bool m_has_errors;
  bool m_is_mem_error;
};

void sp_parser_data::finish_parsing_sp_body(THD *thd) {
  /*
    In some cases the parser detects a syntax error and calls
    THD::cleanup_after_parse_error() method only after finishing parsing
    the whole routine. In such a situation sp_head::restore_thd_mem_root()
    will be called twice - the first time as part of normal parsing process
    and the second time by cleanup_after_parse_error().

    To avoid ruining active arena/mem_root state in this case we skip
    restoration of old arena/mem_root if this method has been already called
    for this routine.
  */
  if (!is_parsing_sp_body()) return;

  thd->free_items();
  thd->mem_root = m_saved_memroot;
  thd->set_item_list(m_saved_item_list);

  m_saved_memroot = nullptr;
  m_saved_item_list = nullptr;
}

/**
  Restore session state in case of parse error.

  This is a clean up function that is invoked after the Bison generated
  parser before returning an error from THD::sql_parser(). If your
  semantic actions manipulate with the session state (which
  is a very bad practice and should not normally be employed) and
  need a clean-up in case of error, and you can not use %destructor
  rule in the grammar file itself, this function should be used
  to implement the clean up.
*/

void cleanup_after_parse_error(THD* thd) {
  sp_head *sp = thd->lex->sphead;

  if (sp) {
    sp->m_parser_data.finish_parsing_sp_body(thd);
    //  Do not delete sp_head if is invoked in the context of sp execution.
    if (thd->sp_runtime_ctx == nullptr) {
      sp_head::destroy(sp);
      thd->lex->sphead = nullptr;
    }
  }
}

bool parse_sql_entry(THD *thd, Parser_state *parser_state,
               Object_creation_ctx *creation_ctx, vector<IR*>& ir_vec) {
  DBUG_TRACE;
  bool ret_value;
  assert(thd->m_parser_state == nullptr);
  // TODO fix to allow parsing gcol exprs after main query.
  //  assert(thd->lex->m_sql_cmd == NULL);

  /* Backup creation context. */

  Object_creation_ctx *backup_ctx = nullptr;

  if (creation_ctx) backup_ctx = creation_ctx->set_n_backup(thd);

  /* Set parser state. */

  thd->m_parser_state = parser_state;

  parser_state->m_digest_psi = nullptr;
  parser_state->m_lip.m_digest = nullptr;

  /*
    Partial parsers (GRAMMAR_SELECTOR_*) are not supposed to compute digests.
  */
  assert(!parser_state->m_lip.is_partial_parser() ||
         !parser_state->m_input.m_has_digest);

  /*
    Only consider statements that are supposed to have a digest,
    like top level queries.
  */
  if (parser_state->m_input.m_has_digest) {
    /*
      For these statements,
      see if the digest computation is required.
    */
    if (thd->m_digest != nullptr) {
      /* Start Digest */
      parser_state->m_digest_psi = MYSQL_DIGEST_START(thd->m_statement_psi);

      if (parser_state->m_input.m_compute_digest ||
          (parser_state->m_digest_psi != nullptr)) {
        /*
          If either:
          - the caller wants to compute a digest
          - the performance schema wants to compute a digest
          set the digest listener in the lexer.
        */
        parser_state->m_lip.m_digest = thd->m_digest;
        parser_state->m_lip.m_digest->m_digest_storage.m_charset_number =
            thd->charset()->number;
      }
    }
  }

  /* Parse the query. */

  /*
    Use a temporary DA while parsing. We don't know until after parsing
    whether the current command is a diagnostic statement, in which case
    we'll need to have the previous DA around to answer questions about it.
  */
  Diagnostics_area *parser_da = thd->get_parser_da();
  Diagnostics_area *da = thd->get_stmt_da();

  Parser_oom_handler poomh;
  // Note that we may be called recursively here, on INFORMATION_SCHEMA queries.

  thd->mem_root->set_max_capacity(thd->variables.parser_max_mem_size);
  thd->mem_root->set_error_for_capacity_exceeded(true);
  thd->push_internal_handler(&poomh);

  thd->push_diagnostics_area(parser_da, false);

  bool mysql_parse_status = false;

  Parse_tree_root *root = nullptr;
  IR* dummy_res;
  if (MYSQLparse(thd, &root, ir_vec, dummy_res))
  {
      cleanup_after_parse_error(thd);
      mysql_parse_status = true;
  }
  if (root != nullptr && thd->lex->make_sql_cmd(root)) {
    mysql_parse_status = true;
  }
  mysql_parse_status = false;

  thd->pop_internal_handler();
  thd->mem_root->set_max_capacity(0);
  thd->mem_root->set_error_for_capacity_exceeded(false);
  /*
    Unwind diagnostics area.

    If any issues occurred during parsing, they will become
    the sole conditions for the current statement.

    Otherwise, if we have a diagnostic statement on our hands,
    we'll preserve the previous diagnostics area here so we
    can answer questions about it.  This specifically means
    that repeatedly asking about a DA won't clear it.

    Otherwise, it's a regular command with no issues during
    parsing, so we'll just clear the DA in preparation for
    the processing of this command.
  */

  if (parser_da->current_statement_cond_count() != 0) {
    /*
      Error/warning during parsing: top DA should contain parse error(s)!  Any
      pre-existing conditions will be replaced. The exception is diagnostics
      statements, in which case we wish to keep the errors so they can be sent
      to the client.
    */
    if (thd->lex->sql_command != SQLCOM_SHOW_WARNS &&
        thd->lex->sql_command != SQLCOM_GET_DIAGNOSTICS)
      da->reset_condition_info(thd);

    /*
      We need to put any errors in the DA as well as the condition list.
    */
    if (parser_da->is_error() && !da->is_error()) {
      da->set_error_status(parser_da->mysql_errno(), parser_da->message_text(),
                           parser_da->returned_sqlstate());
    }

    da->copy_sql_conditions_from_da(thd, parser_da);

    parser_da->reset_diagnostics_area();
    parser_da->reset_condition_info(thd);

    /*
      Do not clear the condition list when starting execution as it
      now contains not the results of the previous executions, but
      a non-zero number of errors/warnings thrown during parsing!
    */
    thd->lex->keep_diagnostics = DA_KEEP_PARSE_ERROR;
  }

  thd->pop_diagnostics_area();

  /*
    Check that if THD::sql_parser() failed either thd->is_error() is set, or an
    internal error handler is set.

    The assert will not catch a situation where parsing fails without an
    error reported if an error handler exists. The problem is that the
    error handler might have intercepted the error, so thd->is_error() is
    not set. However, there is no way to be 100% sure here (the error
    handler might be for other errors than parsing one).
  */

  assert(!mysql_parse_status || (mysql_parse_status && thd->is_error()) ||
         (mysql_parse_status && thd->get_internal_handler()));

  /* Reset parser state. */

  thd->m_parser_state = nullptr;

  /* Restore creation context. */

  if (creation_ctx) creation_ctx->restore_env(thd, backup_ctx);

  /* That's it. */

  ret_value = mysql_parse_status || thd->is_fatal_error();

  if ((ret_value == 0) && (parser_state->m_digest_psi != nullptr)) {
    /*
      On parsing success, record the digest in the performance schema.
    */
    assert(thd->m_digest != nullptr);
    MYSQL_DIGEST_END(parser_state->m_digest_psi,
                     &thd->m_digest->m_digest_storage);
  }

  return ret_value;
}


bool exec_query_command_entry(string input, vector<IR*> ir_vec) {
    THD *thd = new (std::nothrow) THD;
    thd->get_stmt_da()->reset_diagnostics_area();
    thd->get_stmt_da()->reset_statement_cond_count();

    // Might need a loop
    MYSQL_LEX_CSTRING cmd_mysql_cstring;

    // In stack, will be freed after function exits. 
    cmd_mysql_cstring.str = input.c_str();
    cmd_mysql_cstring.length = input.size();
    thd->set_query(cmd_mysql_cstring);

    Parser_state parser_state;
    parser_state.init(thd, thd->query().str, thd->query().length);

    parser_state.m_input.m_has_digest = true;

    // we produce digest if it's not explicitly turned off
    // by setting maximum digest length to zero
    if (get_max_digest_length() != 0)
        parser_state.m_input.m_compute_digest = true;

    while (!thd->killed && (parser_state.m_lip.found_semicolon != nullptr) &&
           !thd->is_error()) {
        /* in the dispatch_sql_command */
        lex_start(thd);
        mysql_reset_thd_for_next_command(thd);
        thd->m_digest = nullptr;
        thd->m_statement_psi = nullptr;
        // thd->m_parser_state = parser_state;

        bool err;
        err = parse_sql_entry(thd, &parser_state, nullptr, ir_vec);
        thd->end_statement();
    }

    thd->release_resources();
    thd->set_psi(nullptr);
    thd->lex->destroy();
    thd->end_statement();
    thd->cleanup_after_query();

    return true;
}
