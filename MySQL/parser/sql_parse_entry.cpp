#include "./sql_parse_entry.h"
#include "./sql/sql_parse.h"
#include "../include/ast.h"

#include <algorithm>
#include <atomic>
#include <climits>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <functional>
#include <iterator>
#include <memory>
#include <optional>
#include <string>
#include <utility>
#include <vector>

#include "my_config.h"
#ifdef HAVE_LSAN_DO_RECOVERABLE_LEAK_CHECK
#include <sanitizer/lsan_interface.h>
#endif

#include "dur_prop.h"
#include "field_types.h"  // enum_field_types
#include "m_ctype.h"
#include "m_string.h"
#include "mem_root_deque.h"
#include "my_alloc.h"
#include "my_compiler.h"
#include "my_dbug.h"
#include "my_hostname.h"
#include "my_inttypes.h"  // TODO: replace with cstdint
#include "my_io.h"
#include "my_loglevel.h"
#include "my_macros.h"
#include "my_psi_config.h"
#include "my_sys.h"
#include "my_table_map.h"
#include "my_thread_local.h"
#include "my_time.h"
#include "mysql/com_data.h"
#include "mysql/components/services/bits/plugin_audit_connection_types.h"  // MYSQL_AUDIT_CONNECTION_CHANGE_USER
#include "mysql/components/services/log_builtins.h"        // LogErr
#include "mysql/components/services/psi_statement_bits.h"  // PSI_statement_info
#include "mysql/plugin_audit.h"
#include "mysql/psi/mysql_mutex.h"
#include "mysql/psi/mysql_rwlock.h"
#include "mysql/psi/mysql_statement.h"
#include "mysql/service_mysql_alloc.h"
#include "mysql/udf_registration_types.h"
#include "mysql_version.h"
#include "mysqld_error.h"
#include "mysys_err.h"  // EE_CAPACITY_EXCEEDED
#include "pfs_thread_provider.h"
#include "prealloced_array.h"
#include "scope_guard.h"
#include "sql/auth/auth_acls.h"
#include "sql/auth/auth_common.h"  // acl_authenticate
#include "sql/auth/sql_security_ctx.h"
#include "sql/binlog.h"  // purge_master_logs
#include "sql/clone_handler.h"
#include "sql/comp_creator.h"
#include "sql/create_field.h"
#include "sql/current_thd.h"
#include "sql/dd/cache/dictionary_client.h"  // dd::cache::Dictionary_client::Auto_releaser
#include "sql/dd/dd.h"                       // dd::get_dictionary
#include "sql/dd/dd_schema.h"                // Schema_MDL_locker
#include "sql/dd/dictionary.h"  // dd::Dictionary::is_system_view_name
#include "sql/dd/info_schema/table_stats.h"
#include "sql/dd/types/column.h"
#include "sql/debug_sync.h"  // DEBUG_SYNC
#include "sql/derror.h"      // ER_THD
#include "sql/discrete_interval.h"
#include "sql/error_handler.h"  // Strict_error_handler
#include "sql/events.h"         // Events
#include "sql/field.h"
#include "sql/gis/srid.h"
#include "sql/item.h"
#include "sql/item_cmpfunc.h"
#include "sql/item_func.h"
#include "sql/item_subselect.h"
#include "sql/item_timefunc.h"  // Item_func_unix_timestamp
#include "sql/key_spec.h"       // Key_spec
#include "sql/locked_tables_list.h"
#include "sql/log.h"        // query_logger
#include "sql/log_event.h"  // slave_execute_deferred_events
#include "sql/mdl.h"
#include "sql/mem_root_array.h"
#include "sql/mysqld.h"              // stage_execution_of_init_command
#include "sql/mysqld_thd_manager.h"  // Find_thd_with_id
#include "sql/nested_join.h"
#include "sql/opt_hints.h"
#include "sql/opt_trace.h"  // Opt_trace_start
#include "sql/parse_location.h"
#include "sql/parse_tree_node_base.h"
#include "sql/parse_tree_nodes.h"
#include "sql/parser_yystype.h"
#include "sql/persisted_variable.h"
#include "sql/protocol.h"
#include "sql/protocol_classic.h"
#include "sql/psi_memory_key.h"
#include "sql/query_options.h"
#include "sql/query_result.h"
#include "sql/resourcegroups/resource_group_basic_types.h"
#include "sql/resourcegroups/resource_group_mgr.h"  // Resource_group_mgr::instance
#include "sql/rpl_context.h"
#include "sql/rpl_filter.h"             // rpl_filter
#include "sql/rpl_group_replication.h"  // group_replication_start
#include "sql/rpl_gtid.h"
#include "sql/rpl_handler.h"  // launch_hook_trans_begin
#include "sql/rpl_replica.h"  // change_master_cmd
#include "sql/rpl_source.h"   // register_slave
#include "sql/rpl_utility.h"
#include "sql/session_tracker.h"
#include "sql/set_var.h"
#include "sql/sp.h"        // sp_create_routine
#include "sql/sp_cache.h"  // sp_cache_enforce_limit
#include "sql/sp_head.h"   // sp_head
#include "sql/sql_admin.h"
#include "sql/sql_alter.h"
#include "sql/sql_audit.h"   // MYSQL_AUDIT_NOTIFY_CONNECTION_CHANGE_USER
#include "sql/sql_base.h"    // find_temporary_table
#include "sql/sql_binlog.h"  // mysql_client_binlog_statement
#include "sql/sql_check_constraint.h"
#include "sql/sql_class.h"
#include "sql/sql_cmd.h"
#include "sql/sql_connect.h"  // decrease_user_connections
#include "sql/sql_const.h"
#include "sql/sql_db.h"  // mysql_change_db
#include "sql/sql_digest.h"
#include "sql/sql_digest_stream.h"
#include "sql/sql_error.h"
#include "sql/sql_handler.h"  // mysql_ha_rm_tables
#include "sql/sql_help.h"     // mysqld_help
#include "sql/sql_lex.h"
#include "sql/sql_list.h"
#include "sql/sql_prepare.h"  // mysql_stmt_execute
#include "sql/sql_profile.h"
#include "sql/sql_query_rewrite.h"  // invoke_pre_parse_rewrite_plugins
#include "sql/sql_reload.h"         // handle_reload_request
#include "sql/sql_rename.h"         // mysql_rename_tables
#include "sql/sql_rewrite.h"        // mysql_rewrite_query
#include "sql/sql_show.h"           // find_schema_table
#include "sql/sql_table.h"          // mysql_create_table
#include "sql/sql_trigger.h"        // add_table_for_trigger
#include "sql/sql_udf.h"
#include "sql/sql_view.h"  // mysql_create_view
#include "sql/strfunc.h"
#include "sql/system_variables.h"  // System_status_var
#include "sql/table.h"
#include "sql/table_cache.h"  // table_cache_manager
#include "sql/thd_raii.h"
#include "sql/transaction.h"  // trans_rollback_implicit
#include "sql/transaction_info.h"
#include "sql_string.h"
#include "template_utils.h"
#include "thr_lock.h"
#include "violite.h"

extern int MYSQLparse(class THD * thd, class Parse_tree_root * *root);


bool parse_sql(THD *thd, Parser_state *parser_state,
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
  if (MYSQLparse(this, &root, ir_vec))
  {
      cleanup_after_parse_error();
      mysql_parse_status = true;
  }
  if (root != nullptr && lex->make_sql_cmd(root)) {
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


bool exec_query_command_entry(string input) {
    THD *thd = init_new_thd(channel_info);
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
        err = parse_sql(thd, parser_state, nullptr);
        thd.end_statement();
    }

    thd->release_resources();
    thd->set_psi(nullptr);
    thd->lex->destroy();
    thd->end_statement();
    thd->cleanup_after_query();

}