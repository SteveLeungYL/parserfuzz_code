
/*
   Copyright (c) 2000, 2021, Oracle and/or its affiliates.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License, version 2.0,
   as published by the Free Software Foundation.

   This program is also distributed with certain software (including
   but not limited to OpenSSL) that is licensed under separate terms,
   as designated in a particular file or component or in included license
   documentation.  The authors of MySQL hereby grant you an additional
   permission to link the program and your derivative works with the
   separately licensed software that they have included with MySQL.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License, version 2.0, for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA */

/* sql_yacc.yy */

/**
  @defgroup Parser Parser
  @{
*/

%{

#include <vector>


/*
Note: YYTHD is passed as an argument to yyparse(), and subsequently to yylex().
*/
#define YYP (YYTHD->m_parser_state)
#define YYLIP (& YYTHD->m_parser_state->m_lip)
#define YYPS (& YYTHD->m_parser_state->m_yacc)
#define YYCSCL (YYLIP->query_charset)
#define YYMEM_ROOT (YYTHD->mem_root)
#define YYCLIENT_NO_SCHEMA (YYTHD->get_protocol()->has_client_capability(CLIENT_NO_SCHEMA))

#define YYINITDEPTH 100
#define YYMAXDEPTH 3200                        /* Because of 64K stack */
#define Lex (YYTHD->lex)
#define Select Lex->current_query_block()

#include <sys/types.h>  // TODO: replace with cstdint

#include <algorithm>
#include <cerrno>
#include <climits>
#include <cstdlib>
#include <cstring>
#include <limits>
#include <memory>
#include <string>
#include <type_traits>
#include <utility>

#include "./include/field_types.h"
#include "./include/ft_global.h"
#include "./include/lex_string.h"
#include "./libbinlogevents/include/binlog_event.h"
#include "./include/m_ctype.h"
#include "./include/m_string.h"
#include "./include/my_alloc.h"
#include "./include/my_base.h"
#include "./include/my_check_opt.h"
#include "./include/my_dbug.h"
#include "./include/my_inttypes.h"  // TODO: replace with cstdint
#include "./include/my_sqlcommand.h"
#include "./include/my_sys.h"
#include "./include/my_thread_local.h"
#include "./include/my_time.h"
#include "./include/myisam.h"
#include "./include/myisammrg.h"
#include "./include/mysql/mysql_lex_string.h"
#include "./include/mysql/plugin.h"
#include "./include/mysql/udf_registration_types.h"
#include "./include/mysql_com.h"
#include "./include/mysql_time.h"
#include "./include/mysqld_error.h"
#include "./include/prealloced_array.h"
#include "./sql/auth/auth_acls.h"
#include "./sql/auth/auth_common.h"
#include "./sql/binlog.h"                          // for MAX_LOG_UNIQUE_FN_EXT
#include "./sql/create_field.h"
#include "./sql/dd/types/abstract_table.h"         // TT_BASE_TABLE
#include "./sql/dd/types/column.h"
#include "./sql/derror.h"
#include "./sql/event_parse_data.h"
#include "./sql/field.h"
#include "./sql/gis/srid.h"                    // gis::srid_t
#include "./sql/handler.h"
#include "./sql/item.h"
#include "./sql/item_cmpfunc.h"
#include "./sql/item_create.h"
#include "./sql/item_func.h"
#include "./sql/item_geofunc.h"
#include "./sql/item_json_func.h"
#include "./sql/item_regexp_func.h"
#include "./sql/item_row.h"
#include "./sql/item_strfunc.h"
#include "./sql/item_subselect.h"
#include "./sql/item_sum.h"
#include "./sql/item_timefunc.h"
#include "./sql/json_dom.h"
#include "./sql/json_syntax_check.h"           // is_valid_json_syntax
#include "./sql/key_spec.h"
#include "./sql/keycaches.h"
#include "./sql/lex_symbol.h"
#include "./sql/lex_token.h"
#include "./sql/lexer_yystype.h"
#include "./sql/mdl.h"
#include "./sql/mem_root_array.h"
#include "./sql/mysqld.h"
#include "./sql/options_mysqld.h"
#include "./sql/parse_location.h"
#include "./sql/parse_tree_helpers.h"
#include "./sql/parse_tree_node_base.h"
#include "./sql/parser_yystype.h"
#include "./sql/partition_element.h"
#include "./sql/partition_info.h"
#include "./sql/protocol.h"
#include "./sql/query_options.h"
#include "./sql/resourcegroups/platform/thread_attrs_api.h"
#include "./sql/resourcegroups/resource_group_basic_types.h"
#include "./sql/rpl_filter.h"
#include "./sql/rpl_replica.h"                       // Sql_cmd_change_repl_filter
#include "./sql/set_var.h"
#include "./sql/sp.h"
#include "./sql/sp_head.h"
#include "./sql/sp_instr.h"
#include "./sql/sp_pcontext.h"
#include "./sql/spatial.h"
#include "./sql/sql_admin.h"                         // Sql_cmd_analyze/Check..._table
#include "./sql/sql_alter.h"                         // Sql_cmd_alter_table*
#include "./sql/sql_backup_lock.h"                   // Sql_cmd_lock_instance
#include "./sql/sql_class.h"      /* Key_part_spec, enum_filetype */
#include "./sql/sql_cmd_srs.h"
#include "./sql/sql_connect.h"
#include "./sql/sql_component.h"
#include "./sql/sql_error.h"
#include "./sql/sql_exchange.h"
#include "./sql/sql_get_diagnostics.h"               // Sql_cmd_get_diagnostics
#include "./sql/sql_handler.h"                       // Sql_cmd_handler_*
#include "./sql/sql_import.h"                        // Sql_cmd_import_table
#include "./sql/sql_lex.h"
#include "./sql/sql_list.h"
#include "./sql/sql_parse.h"                        /* comp_*_creator */
#include "./sql/sql_plugin.h"                      // plugin_is_ready
#include "./sql/sql_profile.h"
#include "./sql/sql_select.h"                      // Sql_cmd_select...
#include "./sql/sql_servers.h"
#include "./sql/sql_signal.h"
#include "./sql/sql_table.h"                        /* primary_key_name */
#include "./sql/sql_tablespace.h"                  // Sql_cmd_alter_tablespace
#include "./sql/sql_trigger.h"                     // Sql_cmd_create_trigger
#include "./sql/sql_udf.h"
#include "./sql/system_variables.h"
#include "./sql/table.h"
#include "./sql/table_function.h"
#include "./sql/thr_malloc.h"
#include "./sql/trigger_def.h"
#include "./sql/window_lex.h"
#include "./sql/xa.h"
#include "./sql_chars.h"
#include "./sql_string.h"
#include "./include/thr_lock.h"
#include "./include/violite.h"


#define yyerror         MYSQLerror
#define yylex           MYSQLlex

/* this is to get the bison compilation windows warnings out */
#ifdef _MSC_VER
/* warning C4065: switch statement contains 'default' but no 'case' labels */
#pragma warning (disable : 4065)
#endif

using std::min;
using std::max;

/// The maximum number of histogram buckets.
static const int MAX_NUMBER_OF_HISTOGRAM_BUCKETS= 1024;

/// The default number of histogram buckets when the user does not specify it
/// explicitly. A value of 100 is chosen because the gain in accuracy above this
/// point seems to be generally low.
static const int DEFAULT_NUMBER_OF_HISTOGRAM_BUCKETS= 100;

int yylex(void *yylval, void *yythd);

#define yyoverflow(A,B,C,D,E,F,G,H)           \
  {                                           \
    ulong val= *(H);                          \
    if (my_yyoverflow((B), (D), (F), &val))   \
    {                                         \
      yyerror(NULL, YYTHD, NULL, (const char*) (A));\
      return 2;                               \
    }                                         \
    else                                      \
    {                                         \
      *(H)= (YYSIZE_T)val;                    \
    }                                         \
  }

#define MYSQL_YYABORT YYABORT

#define MYSQL_YYABORT_ERROR(...)              \
  do                                          \
  {                                           \
    my_error(__VA_ARGS__);                    \
    MYSQL_YYABORT;                            \
  } while(0)

#define MYSQL_YYABORT_UNLESS(A)         \
  if (!(A))                             \
  {                                     \
    YYTHD->syntax_error();              \
    MYSQL_YYABORT;                      \
  }

#define NEW_PTN new(YYMEM_ROOT)


/**
  Parse_tree_node::contextualize() function call wrapper
*/
#define CONTEXTUALIZE(x)                                \
  do                                                    \
  {                                                     \
    std::remove_reference<decltype(*x)>::type::context_t pc(YYTHD, Select); \
    if (YYTHD->is_error() ||                                            \
        (YYTHD->lex->will_contextualize && (x)->contextualize(&pc)))    \
      MYSQL_YYABORT;                                                    \
  } while(0)


/**
  Item::itemize() function call wrapper
*/
#define ITEMIZE(x, y)                                                   \
  do                                                                    \
  {                                                                     \
    Parse_context pc(YYTHD, Select);                                    \
    if (YYTHD->is_error() ||                                            \
        (YYTHD->lex->will_contextualize && (x)->itemize(&pc, (y))))     \
      MYSQL_YYABORT;                                                    \
  } while(0)

/**
  Parse_tree_root::make_cmd() wrapper to raise postponed error message on OOM

  @note x may be NULL because of OOM error.
*/
#define MAKE_CMD(x)                                    \
  do                                                   \
  {                                                    \
    if (YYTHD->is_error() || Lex->make_sql_cmd(x))     \
      MYSQL_YYABORT;                                   \
  } while(0)


#ifndef NDEBUG
#define YYDEBUG 1
#else
#define YYDEBUG 0
#endif


/**
  @brief Bison callback to report a syntax/OOM error

  This function is invoked by the bison-generated parser
  when a syntax error or an out-of-memory
  condition occurs, then the parser function MYSQLparse()
  returns 1 to the caller.

  This function is not invoked when the
  parser is requested to abort by semantic action code
  by means of YYABORT or YYACCEPT macros..

  This function is not for use in semantic actions and is internal to
  the parser, as it performs some pre-return cleanup.
  In semantic actions, please use syntax_error or my_error to
  push an error into the error stack and MYSQL_YYABORT
  to abort from the parser.
*/

static
void MYSQLerror(YYLTYPE *location, THD *thd, Parse_tree_root **, const char *s, vector<IR*> ir_vec)
{
  if (strcmp(s, "syntax error") == 0) {
    thd->syntax_error_at(*location);
  } else if (strcmp(s, "memory exhausted") == 0) {
    my_error(ER_DA_OOM, MYF(0));
  } else {
    // Find omitted error messages in the generated file (sql_yacc.cc) and fix:
    assert(false);
    my_error(ER_UNKNOWN_ERROR, MYF(0));
  }
}


#ifndef NDEBUG
void turn_parser_debug_on()
{
  /*
     MYSQLdebug is in sql/sql_yacc.cc, in bison generated code.
     Turning this option on is **VERY** verbose, and should be
     used when investigating a syntax error problem only.

     The syntax to run with bison traces is as follows :
     - Starting a server manually :
       mysqld --debug="d,parser_debug" ...
     - Running a test :
       mysql-test-run.pl --mysqld="--debug=d,parser_debug" ...

     The result will be in the process stderr (var/log/master.err)
   */

  extern int yydebug;
  yydebug= 1;
}
#endif

static bool is_native_function(const LEX_STRING &name)
{
  if (find_native_function_builder(name) != nullptr)
    return true;

  if (is_lex_native_function(&name))
    return true;

  return false;
}


/**
  Helper action for a case statement (entering the CASE).
  This helper is used for both 'simple' and 'searched' cases.
  This helper, with the other case_stmt_action_..., is executed when
  the following SQL code is parsed:
<pre>
CREATE PROCEDURE proc_19194_simple(i int)
BEGIN
  DECLARE str CHAR(10);

  CASE i
    WHEN 1 THEN SET str="1";
    WHEN 2 THEN SET str="2";
    WHEN 3 THEN SET str="3";
    ELSE SET str="unknown";
  END CASE;

  SELECT str;
END
</pre>
  The actions are used to generate the following code:
<pre>
SHOW PROCEDURE CODE proc_19194_simple;
Pos     Instruction
0       set str@1 NULL
1       set_case_expr (12) 0 i@0
2       jump_if_not 5(12) (case_expr@0 = 1)
3       set str@1 _latin1'1'
4       jump 12
5       jump_if_not 8(12) (case_expr@0 = 2)
6       set str@1 _latin1'2'
7       jump 12
8       jump_if_not 11(12) (case_expr@0 = 3)
9       set str@1 _latin1'3'
10      jump 12
11      set str@1 _latin1'unknown'
12      stmt 0 "SELECT str"
</pre>

  @param thd thread handler
*/

static void case_stmt_action_case(THD *thd)
{
  LEX *lex= thd->lex;
  sp_head *sp= lex->sphead;
  sp_pcontext *pctx= lex->get_sp_current_parsing_ctx();

  sp->m_parser_data.new_cont_backpatch();

  /*
    BACKPATCH: Creating target label for the jump to
    "case_stmt_action_end_case"
    (Instruction 12 in the example)
  */

  pctx->push_label(thd, EMPTY_CSTR, sp->instructions());
}

/**
  Helper action for a case then statements.
  This helper is used for both 'simple' and 'searched' cases.
  @param lex the parser lex context
*/

static bool case_stmt_action_then(THD *thd, LEX *lex)
{
  sp_head *sp= lex->sphead;
  sp_pcontext *pctx= lex->get_sp_current_parsing_ctx();

  sp_instr_jump *i =
    new (thd->mem_root) sp_instr_jump(sp->instructions(), pctx);

  if (!i || sp->add_instr(thd, i))
    return true;

  /*
    BACKPATCH: Resolving forward jump from
    "case_stmt_action_when" to "case_stmt_action_then"
    (jump_if_not from instruction 2 to 5, 5 to 8 ... in the example)
  */

  sp->m_parser_data.do_backpatch(pctx->pop_label(), sp->instructions());

  /*
    BACKPATCH: Registering forward jump from
    "case_stmt_action_then" to "case_stmt_action_end_case"
    (jump from instruction 4 to 12, 7 to 12 ... in the example)
  */

  return sp->m_parser_data.add_backpatch_entry(i, pctx->last_label());
}

/**
  Helper action for an end case.
  This helper is used for both 'simple' and 'searched' cases.
  @param lex the parser lex context
  @param simple true for simple cases, false for searched cases
*/

static void case_stmt_action_end_case(LEX *lex, bool simple)
{
  sp_head *sp= lex->sphead;
  sp_pcontext *pctx= lex->get_sp_current_parsing_ctx();

  /*
    BACKPATCH: Resolving forward jump from
    "case_stmt_action_then" to "case_stmt_action_end_case"
    (jump from instruction 4 to 12, 7 to 12 ... in the example)
  */
  sp->m_parser_data.do_backpatch(pctx->pop_label(), sp->instructions());

  if (simple)
    pctx->pop_case_expr_id();

  sp->m_parser_data.do_cont_backpatch(sp->instructions());
}


static void init_index_hints(List<Index_hint> *hints, index_hint_type type,
                             index_clause_map clause)
{
  List_iterator<Index_hint> it(*hints);
  Index_hint *hint;
  while ((hint= it++))
  {
    hint->type= type;
    hint->clause= clause;
  }
}

bool my_yyoverflow(short **a, YYSTYPE **b, YYLTYPE **c, ulong *yystacksize);

#include "sql/parse_tree_column_attrs.h"
#include "sql/parse_tree_handler.h"
#include "sql/parse_tree_items.h"
#include "sql/parse_tree_nodes.h"
#include "sql/parse_tree_partitions.h"

void warn_about_deprecated_national(THD *thd)
{
  if (native_strcasecmp(national_charset_info->csname, "utf8") == 0)
    push_warning(thd, ER_DEPRECATED_NATIONAL);
}

void warn_about_deprecated_binary(THD *thd)
{
  push_deprecated_warn(thd, "BINARY as attribute of a type",
  "a CHARACTER SET clause with _bin collation");
}

#include "../include/ast.h"

%}

%start start_entry

%parse-param { class THD *YYTHD }
%parse-param { class Parse_tree_root **parse_tree }
%parse-param { vector<IR*> ir_vec }

%lex-param { class THD *YYTHD }
%pure-parser                                    /* We have threads */
/*
  1. We do not accept any reduce/reduce conflicts
  2. We should not introduce new shift/reduce conflicts any more.
*/

%expect 0
/* %expect 63 */

/*
   MAINTAINER:

   1) Comments for TOKENS.

   For each token, please include in the same line a comment that contains
   one or more of the following tags:

   SQL-2015-N : Non Reserved keyword as per SQL-2015 draft
   SQL-2015-R : Reserved keyword as per SQL-2015 draft
   SQL-2003-R : Reserved keyword as per SQL-2003
   SQL-2003-N : Non Reserved keyword as per SQL-2003
   SQL-1999-R : Reserved keyword as per SQL-1999
   SQL-1999-N : Non Reserved keyword as per SQL-1999
   MYSQL      : MySQL extension (unspecified)
   MYSQL-FUNC : MySQL extension, function
   INTERNAL   : Not a real token, lex optimization
   OPERATOR   : SQL operator
   FUTURE-USE : Reserved for futur use

   This makes the code grep-able, and helps maintenance.

   2) About token values

   Token values are assigned by bison, in order of declaration.

   Token values are used in query DIGESTS.
   To make DIGESTS stable, it is desirable to avoid changing token values.

   In practice, this means adding new tokens at the end of the list,
   in the current release section (8.0),
   instead of adding them in the middle of the list.

   Failing to comply with instructions below will trigger build failure,
   as this process is enforced by gen_lex_token.

   3) Instructions to add a new token:

   Add the new token at the end of the list,
   in the MySQL 8.0 section.

   4) Instructions to remove an old token:

   Do not remove the token, rename it as follows:
   %token OBSOLETE_TOKEN_<NNN> / * was: TOKEN_FOO * /
   where NNN is the token value (found in sql_yacc.h)

   For example, see OBSOLETE_TOKEN_820
*/

/*
   Tokens from MySQL 5.7, keep in alphabetical order.
*/

%token  ABORT_SYM 258                     /* INTERNAL (used in lex) */
%token  ACCESSIBLE_SYM 259
%token<lexer.keyword> ACCOUNT_SYM 260
%token<lexer.keyword> ACTION 261                /* SQL-2003-N */
%token  ADD 262                           /* SQL-2003-R */
%token<lexer.keyword> ADDDATE_SYM 263           /* MYSQL-FUNC */
%token<lexer.keyword> AFTER_SYM 264             /* SQL-2003-N */
%token<lexer.keyword> AGAINST 265
%token<lexer.keyword> AGGREGATE_SYM 266
%token<lexer.keyword> ALGORITHM_SYM 267
%token  ALL 268                           /* SQL-2003-R */
%token  ALTER 269                         /* SQL-2003-R */
%token<lexer.keyword> ALWAYS_SYM 270
%token  OBSOLETE_TOKEN_271 271            /* was: ANALYSE_SYM */
%token  ANALYZE_SYM 272
%token  AND_AND_SYM 273                   /* OPERATOR */
%token  AND_SYM 274                       /* SQL-2003-R */
%token<lexer.keyword> ANY_SYM 275               /* SQL-2003-R */
%token  AS 276                            /* SQL-2003-R */
%token  ASC 277                           /* SQL-2003-N */
%token<lexer.keyword> ASCII_SYM 278             /* MYSQL-FUNC */
%token  ASENSITIVE_SYM 279                /* FUTURE-USE */
%token<lexer.keyword> AT_SYM 280                /* SQL-2003-R */
%token<lexer.keyword> AUTOEXTEND_SIZE_SYM 281
%token<lexer.keyword> AUTO_INC 282
%token<lexer.keyword> AVG_ROW_LENGTH 283
%token<lexer.keyword> AVG_SYM 284               /* SQL-2003-N */
%token<lexer.keyword> BACKUP_SYM 285
%token  BEFORE_SYM 286                    /* SQL-2003-N */
%token<lexer.keyword> BEGIN_SYM 287             /* SQL-2003-R */
%token  BETWEEN_SYM 288                   /* SQL-2003-R */
%token  BIGINT_SYM 289                    /* SQL-2003-R */
%token  BINARY_SYM 290                    /* SQL-2003-R */
%token<lexer.keyword> BINLOG_SYM 291
%token  BIN_NUM 292
%token  BIT_AND_SYM 293                   /* MYSQL-FUNC */
%token  BIT_OR_SYM 294                    /* MYSQL-FUNC */
%token<lexer.keyword> BIT_SYM 295               /* MYSQL-FUNC */
%token  BIT_XOR_SYM 296                   /* MYSQL-FUNC */
%token  BLOB_SYM 297                      /* SQL-2003-R */
%token<lexer.keyword> BLOCK_SYM 298
%token<lexer.keyword> BOOLEAN_SYM 299           /* SQL-2003-R */
%token<lexer.keyword> BOOL_SYM 300
%token  BOTH 301                          /* SQL-2003-R */
%token<lexer.keyword> BTREE_SYM 302
%token  BY 303                            /* SQL-2003-R */
%token<lexer.keyword> BYTE_SYM 304
%token<lexer.keyword> CACHE_SYM 305
%token  CALL_SYM 306                      /* SQL-2003-R */
%token  CASCADE 307                       /* SQL-2003-N */
%token<lexer.keyword> CASCADED 308              /* SQL-2003-R */
%token  CASE_SYM 309                      /* SQL-2003-R */
%token  CAST_SYM 310                      /* SQL-2003-R */
%token<lexer.keyword> CATALOG_NAME_SYM 311      /* SQL-2003-N */
%token<lexer.keyword> CHAIN_SYM 312             /* SQL-2003-N */
%token  CHANGE 313
%token<lexer.keyword> CHANGED 314
%token<lexer.keyword> CHANNEL_SYM 315
%token<lexer.keyword> CHARSET 316
%token  CHAR_SYM 317                      /* SQL-2003-R */
%token<lexer.keyword> CHECKSUM_SYM 318
%token  CHECK_SYM 319                     /* SQL-2003-R */
%token<lexer.keyword> CIPHER_SYM 320
%token<lexer.keyword> CLASS_ORIGIN_SYM 321      /* SQL-2003-N */
%token<lexer.keyword> CLIENT_SYM 322
%token<lexer.keyword> CLOSE_SYM 323             /* SQL-2003-R */
%token<lexer.keyword> COALESCE 324              /* SQL-2003-N */
%token<lexer.keyword> CODE_SYM 325
%token  COLLATE_SYM 326                   /* SQL-2003-R */
%token<lexer.keyword> COLLATION_SYM 327         /* SQL-2003-N */
%token<lexer.keyword> COLUMNS 328
%token  COLUMN_SYM 329                    /* SQL-2003-R */
%token<lexer.keyword> COLUMN_FORMAT_SYM 330
%token<lexer.keyword> COLUMN_NAME_SYM 331       /* SQL-2003-N */
%token<lexer.keyword> COMMENT_SYM 332
%token<lexer.keyword> COMMITTED_SYM 333         /* SQL-2003-N */
%token<lexer.keyword> COMMIT_SYM 334            /* SQL-2003-R */
%token<lexer.keyword> COMPACT_SYM 335
%token<lexer.keyword> COMPLETION_SYM 336
%token<lexer.keyword> COMPRESSED_SYM 337
%token<lexer.keyword> COMPRESSION_SYM 338
%token<lexer.keyword> ENCRYPTION_SYM 339
%token<lexer.keyword> CONCURRENT 340
%token  CONDITION_SYM 341                 /* SQL-2003-R, SQL-2008-R */
%token<lexer.keyword> CONNECTION_SYM 342
%token<lexer.keyword> CONSISTENT_SYM 343
%token  CONSTRAINT 344                    /* SQL-2003-R */
%token<lexer.keyword> CONSTRAINT_CATALOG_SYM 345 /* SQL-2003-N */
%token<lexer.keyword> CONSTRAINT_NAME_SYM 346   /* SQL-2003-N */
%token<lexer.keyword> CONSTRAINT_SCHEMA_SYM 347 /* SQL-2003-N */
%token<lexer.keyword> CONTAINS_SYM 348          /* SQL-2003-N */
%token<lexer.keyword> CONTEXT_SYM 349
%token  CONTINUE_SYM 350                  /* SQL-2003-R */
%token  CONVERT_SYM 351                   /* SQL-2003-N */
%token  COUNT_SYM 352                     /* SQL-2003-N */
%token<lexer.keyword> CPU_SYM 353
%token  CREATE 354                        /* SQL-2003-R */
%token  CROSS 355                         /* SQL-2003-R */
%token  CUBE_SYM 356                      /* SQL-2003-R */
%token  CURDATE 357                       /* MYSQL-FUNC */
%token<lexer.keyword> CURRENT_SYM 358           /* SQL-2003-R */
%token  CURRENT_USER 359                  /* SQL-2003-R */
%token  CURSOR_SYM 360                    /* SQL-2003-R */
%token<lexer.keyword> CURSOR_NAME_SYM 361       /* SQL-2003-N */
%token  CURTIME 362                       /* MYSQL-FUNC */
%token  DATABASE 363
%token  DATABASES 364
%token<lexer.keyword> DATAFILE_SYM 365
%token<lexer.keyword> DATA_SYM 366              /* SQL-2003-N */
%token<lexer.keyword> DATETIME_SYM 367          /* MYSQL */
%token  DATE_ADD_INTERVAL 368             /* MYSQL-FUNC */
%token  DATE_SUB_INTERVAL 369             /* MYSQL-FUNC */
%token<lexer.keyword> DATE_SYM 370              /* SQL-2003-R */
%token  DAY_HOUR_SYM 371
%token  DAY_MICROSECOND_SYM 372
%token  DAY_MINUTE_SYM 373
%token  DAY_SECOND_SYM 374
%token<lexer.keyword> DAY_SYM 375               /* SQL-2003-R */
%token<lexer.keyword> DEALLOCATE_SYM 376        /* SQL-2003-R */
%token  DECIMAL_NUM 377
%token  DECIMAL_SYM 378                   /* SQL-2003-R */
%token  DECLARE_SYM 379                   /* SQL-2003-R */
%token  DEFAULT_SYM 380                   /* SQL-2003-R */
%token<lexer.keyword> DEFAULT_AUTH_SYM 381      /* INTERNAL */
%token<lexer.keyword> DEFINER_SYM 382
%token  DELAYED_SYM 383
%token<lexer.keyword> DELAY_KEY_WRITE_SYM 384
%token  DELETE_SYM 385                    /* SQL-2003-R */
%token  DESC 386                          /* SQL-2003-N */
%token  DESCRIBE 387                      /* SQL-2003-R */
%token  OBSOLETE_TOKEN_388 388            /* was: DES_KEY_FILE */
%token  DETERMINISTIC_SYM 389             /* SQL-2003-R */
%token<lexer.keyword> DIAGNOSTICS_SYM 390       /* SQL-2003-N */
%token<lexer.keyword> DIRECTORY_SYM 391
%token<lexer.keyword> DISABLE_SYM 392
%token<lexer.keyword> DISCARD_SYM 393           /* MYSQL */
%token<lexer.keyword> DISK_SYM 394
%token  DISTINCT 395                      /* SQL-2003-R */
%token  DIV_SYM 396
%token  DOUBLE_SYM 397                    /* SQL-2003-R */
%token<lexer.keyword> DO_SYM 398
%token  DROP 399                          /* SQL-2003-R */
%token  DUAL_SYM 400
%token<lexer.keyword> DUMPFILE 401
%token<lexer.keyword> DUPLICATE_SYM 402
%token<lexer.keyword> DYNAMIC_SYM 403           /* SQL-2003-R */
%token  EACH_SYM 404                      /* SQL-2003-R */
%token  ELSE 405                          /* SQL-2003-R */
%token  ELSEIF_SYM 406
%token<lexer.keyword> ENABLE_SYM 407
%token  ENCLOSED 408
%token<lexer.keyword> END 409                   /* SQL-2003-R */
%token<lexer.keyword> ENDS_SYM 410
%token  END_OF_INPUT 411                  /* INTERNAL */
%token<lexer.keyword> ENGINES_SYM 412
%token<lexer.keyword> ENGINE_SYM 413
%token<lexer.keyword> ENUM_SYM 414              /* MYSQL */
%token  EQ 415                            /* OPERATOR */
%token  EQUAL_SYM 416                     /* OPERATOR */
%token<lexer.keyword> ERROR_SYM 417
%token<lexer.keyword> ERRORS 418
%token  ESCAPED 419
%token<lexer.keyword> ESCAPE_SYM 420            /* SQL-2003-R */
%token<lexer.keyword> EVENTS_SYM 421
%token<lexer.keyword> EVENT_SYM 422
%token<lexer.keyword> EVERY_SYM 423             /* SQL-2003-N */
%token<lexer.keyword> EXCHANGE_SYM 424
%token<lexer.keyword> EXECUTE_SYM 425           /* SQL-2003-R */
%token  EXISTS 426                        /* SQL-2003-R */
%token  EXIT_SYM 427
%token<lexer.keyword> EXPANSION_SYM 428
%token<lexer.keyword> EXPIRE_SYM 429
%token<lexer.keyword> EXPORT_SYM 430
%token<lexer.keyword> EXTENDED_SYM 431
%token<lexer.keyword> EXTENT_SIZE_SYM 432
%token  EXTRACT_SYM 433                   /* SQL-2003-N */
%token  FALSE_SYM 434                     /* SQL-2003-R */
%token<lexer.keyword> FAST_SYM 435
%token<lexer.keyword> FAULTS_SYM 436
%token  FETCH_SYM 437                     /* SQL-2003-R */
%token<lexer.keyword> FILE_SYM 438
%token<lexer.keyword> FILE_BLOCK_SIZE_SYM 439
%token<lexer.keyword> FILTER_SYM 440
%token<lexer.keyword> FIRST_SYM 441             /* SQL-2003-N */
%token<lexer.keyword> FIXED_SYM 442
%token  FLOAT_NUM 443
%token  FLOAT_SYM 444                     /* SQL-2003-R */
%token<lexer.keyword> FLUSH_SYM 445
%token<lexer.keyword> FOLLOWS_SYM 446           /* MYSQL */
%token  FORCE_SYM 447
%token  FOREIGN 448                       /* SQL-2003-R */
%token  FOR_SYM 449                       /* SQL-2003-R */
%token<lexer.keyword> FORMAT_SYM 450
%token<lexer.keyword> FOUND_SYM 451             /* SQL-2003-R */
%token  FROM 452
%token<lexer.keyword> FULL 453                  /* SQL-2003-R */
%token  FULLTEXT_SYM 454
%token  FUNCTION_SYM 455                  /* SQL-2003-R */
%token  GE 456
%token<lexer.keyword> GENERAL 457
%token  GENERATED 458
%token<lexer.keyword> GROUP_REPLICATION 459
%token<lexer.keyword> GEOMETRYCOLLECTION_SYM 460 /* MYSQL */
%token<lexer.keyword> GEOMETRY_SYM 461
%token<lexer.keyword> GET_FORMAT 462            /* MYSQL-FUNC */
%token  GET_SYM 463                       /* SQL-2003-R */
%token<lexer.keyword> GLOBAL_SYM 464            /* SQL-2003-R */
%token  GRANT 465                         /* SQL-2003-R */
%token<lexer.keyword> GRANTS 466
%token  GROUP_SYM 467                     /* SQL-2003-R */
%token  GROUP_CONCAT_SYM 468
%token  GT_SYM 469                        /* OPERATOR */
%token<lexer.keyword> HANDLER_SYM 470
%token<lexer.keyword> HASH_SYM 471
%token  HAVING 472                        /* SQL-2003-R */
%token<lexer.keyword> HELP_SYM 473
%token  HEX_NUM 474
%token  HIGH_PRIORITY 475
%token<lexer.keyword> HOST_SYM 476
%token<lexer.keyword> HOSTS_SYM 477
%token  HOUR_MICROSECOND_SYM 478
%token  HOUR_MINUTE_SYM 479
%token  HOUR_SECOND_SYM 480
%token<lexer.keyword> HOUR_SYM 481              /* SQL-2003-R */
%token  IDENT 482
%token<lexer.keyword> IDENTIFIED_SYM 483
%token  IDENT_QUOTED 484
%token  IF 485
%token  IGNORE_SYM 486
%token<lexer.keyword> IGNORE_SERVER_IDS_SYM 487
%token<lexer.keyword> IMPORT 488
%token<lexer.keyword> INDEXES 489
%token  INDEX_SYM 490
%token  INFILE 491
%token<lexer.keyword> INITIAL_SIZE_SYM 492
%token  INNER_SYM 493                     /* SQL-2003-R */
%token  INOUT_SYM 494                     /* SQL-2003-R */
%token  INSENSITIVE_SYM 495               /* SQL-2003-R */
%token  INSERT_SYM 496                    /* SQL-2003-R */
%token<lexer.keyword> INSERT_METHOD 497
%token<lexer.keyword> INSTANCE_SYM 498
%token<lexer.keyword> INSTALL_SYM 499
%token  INTERVAL_SYM 500                  /* SQL-2003-R */
%token  INTO 501                          /* SQL-2003-R */
%token  INT_SYM 502                       /* SQL-2003-R */
%token<lexer.keyword> INVOKER_SYM 503
%token  IN_SYM 504                        /* SQL-2003-R */
%token  IO_AFTER_GTIDS 505                /* MYSQL, FUTURE-USE */
%token  IO_BEFORE_GTIDS 506               /* MYSQL, FUTURE-USE */
%token<lexer.keyword> IO_SYM 507
%token<lexer.keyword> IPC_SYM 508
%token  IS 509                            /* SQL-2003-R */
%token<lexer.keyword> ISOLATION 510             /* SQL-2003-R */
%token<lexer.keyword> ISSUER_SYM 511
%token  ITERATE_SYM 512
%token  JOIN_SYM 513                      /* SQL-2003-R */
%token  JSON_SEPARATOR_SYM 514            /* MYSQL */
%token<lexer.keyword> JSON_SYM 515              /* MYSQL */
%token  KEYS 516
%token<lexer.keyword> KEY_BLOCK_SIZE 517
%token  KEY_SYM 518                       /* SQL-2003-N */
%token  KILL_SYM 519
%token<lexer.keyword> LANGUAGE_SYM 520          /* SQL-2003-R */
%token<lexer.keyword> LAST_SYM 521              /* SQL-2003-N */
%token  LE 522                            /* OPERATOR */
%token  LEADING 523                       /* SQL-2003-R */
%token<lexer.keyword> LEAVES 524
%token  LEAVE_SYM 525
%token  LEFT 526                          /* SQL-2003-R */
%token<lexer.keyword> LESS_SYM 527
%token<lexer.keyword> LEVEL_SYM 528
%token  LEX_HOSTNAME 529
%token  LIKE 530                          /* SQL-2003-R */
%token  LIMIT 531
%token  LINEAR_SYM 532
%token  LINES 533
%token<lexer.keyword> LINESTRING_SYM 534        /* MYSQL */
%token<lexer.keyword> LIST_SYM 535
%token  LOAD 536
%token<lexer.keyword> LOCAL_SYM 537             /* SQL-2003-R */
%token  OBSOLETE_TOKEN_538 538            /* was: LOCATOR_SYM */
%token<lexer.keyword> LOCKS_SYM 539
%token  LOCK_SYM 540
%token<lexer.keyword> LOGFILE_SYM 541
%token<lexer.keyword> LOGS_SYM 542
%token  LONGBLOB_SYM 543                  /* MYSQL */
%token  LONGTEXT_SYM 544                  /* MYSQL */
%token  LONG_NUM 545
%token  LONG_SYM 546
%token  LOOP_SYM 547
%token  LOW_PRIORITY 548
%token  LT 549                            /* OPERATOR */
%token<lexer.keyword> MASTER_AUTO_POSITION_SYM 550
%token  MASTER_BIND_SYM 551
%token<lexer.keyword> MASTER_CONNECT_RETRY_SYM 552
%token<lexer.keyword> MASTER_DELAY_SYM 553
%token<lexer.keyword> MASTER_HOST_SYM 554
%token<lexer.keyword> MASTER_LOG_FILE_SYM 555
%token<lexer.keyword> MASTER_LOG_POS_SYM 556
%token<lexer.keyword> MASTER_PASSWORD_SYM 557
%token<lexer.keyword> MASTER_PORT_SYM 558
%token<lexer.keyword> MASTER_RETRY_COUNT_SYM 559
/* %token<lexer.keyword> MASTER_SERVER_ID_SYM 560 */ /* UNUSED */
%token<lexer.keyword> MASTER_SSL_CAPATH_SYM 561
%token<lexer.keyword> MASTER_TLS_VERSION_SYM 562
%token<lexer.keyword> MASTER_SSL_CA_SYM 563
%token<lexer.keyword> MASTER_SSL_CERT_SYM 564
%token<lexer.keyword> MASTER_SSL_CIPHER_SYM 565
%token<lexer.keyword> MASTER_SSL_CRL_SYM 566
%token<lexer.keyword> MASTER_SSL_CRLPATH_SYM 567
%token<lexer.keyword> MASTER_SSL_KEY_SYM 568
%token<lexer.keyword> MASTER_SSL_SYM 569
%token  MASTER_SSL_VERIFY_SERVER_CERT_SYM 570
%token<lexer.keyword> MASTER_SYM 571
%token<lexer.keyword> MASTER_USER_SYM 572
%token<lexer.keyword> MASTER_HEARTBEAT_PERIOD_SYM 573
%token  MATCH 574                         /* SQL-2003-R */
%token<lexer.keyword> MAX_CONNECTIONS_PER_HOUR 575
%token<lexer.keyword> MAX_QUERIES_PER_HOUR 576
%token<lexer.keyword> MAX_ROWS 577
%token<lexer.keyword> MAX_SIZE_SYM 578
%token  MAX_SYM 579                       /* SQL-2003-N */
%token<lexer.keyword> MAX_UPDATES_PER_HOUR 580
%token<lexer.keyword> MAX_USER_CONNECTIONS_SYM 581
%token  MAX_VALUE_SYM 582                 /* SQL-2003-N */
%token  MEDIUMBLOB_SYM 583                /* MYSQL */
%token  MEDIUMINT_SYM 584                 /* MYSQL */
%token  MEDIUMTEXT_SYM 585                /* MYSQL */
%token<lexer.keyword> MEDIUM_SYM 586
%token<lexer.keyword> MEMORY_SYM 587
%token<lexer.keyword> MERGE_SYM 588             /* SQL-2003-R */
%token<lexer.keyword> MESSAGE_TEXT_SYM 589      /* SQL-2003-N */
%token<lexer.keyword> MICROSECOND_SYM 590       /* MYSQL-FUNC */
%token<lexer.keyword> MIGRATE_SYM 591
%token  MINUTE_MICROSECOND_SYM 592
%token  MINUTE_SECOND_SYM 593
%token<lexer.keyword> MINUTE_SYM 594            /* SQL-2003-R */
%token<lexer.keyword> MIN_ROWS 595
%token  MIN_SYM 596                       /* SQL-2003-N */
%token<lexer.keyword> MODE_SYM 597
%token  MODIFIES_SYM 598                  /* SQL-2003-R */
%token<lexer.keyword> MODIFY_SYM 599
%token  MOD_SYM 600                       /* SQL-2003-N */
%token<lexer.keyword> MONTH_SYM 601             /* SQL-2003-R */
%token<lexer.keyword> MULTILINESTRING_SYM 602   /* MYSQL */
%token<lexer.keyword> MULTIPOINT_SYM 603        /* MYSQL */
%token<lexer.keyword> MULTIPOLYGON_SYM 604      /* MYSQL */
%token<lexer.keyword> MUTEX_SYM 605
%token<lexer.keyword> MYSQL_ERRNO_SYM 606
%token<lexer.keyword> NAMES_SYM 607             /* SQL-2003-N */
%token<lexer.keyword> NAME_SYM 608              /* SQL-2003-N */
%token<lexer.keyword> NATIONAL_SYM 609          /* SQL-2003-R */
%token  NATURAL 610                       /* SQL-2003-R */
%token  NCHAR_STRING 611
%token<lexer.keyword> NCHAR_SYM 612             /* SQL-2003-R */
%token<lexer.keyword> NDBCLUSTER_SYM 613
%token  NE 614                            /* OPERATOR */
%token  NEG 615
%token<lexer.keyword> NEVER_SYM 616
%token<lexer.keyword> NEW_SYM 617               /* SQL-2003-R */
%token<lexer.keyword> NEXT_SYM 618              /* SQL-2003-N */
%token<lexer.keyword> NODEGROUP_SYM 619
%token<lexer.keyword> NONE_SYM 620              /* SQL-2003-R */
%token  NOT2_SYM 621
%token  NOT_SYM 622                       /* SQL-2003-R */
%token  NOW_SYM 623
%token<lexer.keyword> NO_SYM 624                /* SQL-2003-R */
%token<lexer.keyword> NO_WAIT_SYM 625
%token  NO_WRITE_TO_BINLOG 626
%token  NULL_SYM 627                      /* SQL-2003-R */
%token  NUM 628
%token<lexer.keyword> NUMBER_SYM 629            /* SQL-2003-N */
%token  NUMERIC_SYM 630                   /* SQL-2003-R */
%token<lexer.keyword> NVARCHAR_SYM 631
%token<lexer.keyword> OFFSET_SYM 632
%token  ON_SYM 633                        /* SQL-2003-R */
%token<lexer.keyword> ONE_SYM 634
%token<lexer.keyword> ONLY_SYM 635              /* SQL-2003-R */
%token<lexer.keyword> OPEN_SYM 636              /* SQL-2003-R */
%token  OPTIMIZE 637
%token  OPTIMIZER_COSTS_SYM 638
%token<lexer.keyword> OPTIONS_SYM 639
%token  OPTION 640                        /* SQL-2003-N */
%token  OPTIONALLY 641
%token  OR2_SYM 642
%token  ORDER_SYM 643                     /* SQL-2003-R */
%token  OR_OR_SYM 644                     /* OPERATOR */
%token  OR_SYM 645                        /* SQL-2003-R */
%token  OUTER_SYM 646
%token  OUTFILE 647
%token  OUT_SYM 648                       /* SQL-2003-R */
%token<lexer.keyword> OWNER_SYM 649
%token<lexer.keyword> PACK_KEYS_SYM 650
%token<lexer.keyword> PAGE_SYM 651
%token  PARAM_MARKER 652
%token<lexer.keyword> PARSER_SYM 653
%token  OBSOLETE_TOKEN_654 654            /* was: PARSE_GCOL_EXPR_SYM */
%token<lexer.keyword> PARTIAL 655                       /* SQL-2003-N */
%token  PARTITION_SYM 656                 /* SQL-2003-R */
%token<lexer.keyword> PARTITIONS_SYM 657
%token<lexer.keyword> PARTITIONING_SYM 658
%token<lexer.keyword> PASSWORD 659
%token<lexer.keyword> PHASE_SYM 660
%token<lexer.keyword> PLUGIN_DIR_SYM 661        /* INTERNAL */
%token<lexer.keyword> PLUGIN_SYM 662
%token<lexer.keyword> PLUGINS_SYM 663
%token<lexer.keyword> POINT_SYM 664
%token<lexer.keyword> POLYGON_SYM 665           /* MYSQL */
%token<lexer.keyword> PORT_SYM 666
%token  POSITION_SYM 667                  /* SQL-2003-N */
%token<lexer.keyword> PRECEDES_SYM 668          /* MYSQL */
%token  PRECISION 669                     /* SQL-2003-R */
%token<lexer.keyword> PREPARE_SYM 670           /* SQL-2003-R */
%token<lexer.keyword> PRESERVE_SYM 671
%token<lexer.keyword> PREV_SYM 672
%token  PRIMARY_SYM 673                   /* SQL-2003-R */
%token<lexer.keyword> PRIVILEGES 674            /* SQL-2003-N */
%token  PROCEDURE_SYM 675                 /* SQL-2003-R */
%token<lexer.keyword> PROCESS 676
%token<lexer.keyword> PROCESSLIST_SYM 677
%token<lexer.keyword> PROFILE_SYM 678
%token<lexer.keyword> PROFILES_SYM 679
%token<lexer.keyword> PROXY_SYM 680
%token  PURGE 681
%token<lexer.keyword> QUARTER_SYM 682
%token<lexer.keyword> QUERY_SYM 683
%token<lexer.keyword> QUICK 684
%token  RANGE_SYM 685                     /* SQL-2003-R */
%token  READS_SYM 686                     /* SQL-2003-R */
%token<lexer.keyword> READ_ONLY_SYM 687
%token  READ_SYM 688                      /* SQL-2003-N */
%token  READ_WRITE_SYM 689
%token  REAL_SYM 690                      /* SQL-2003-R */
%token<lexer.keyword> REBUILD_SYM 691
%token<lexer.keyword> RECOVER_SYM 692
%token  OBSOLETE_TOKEN_693 693            /* was: REDOFILE_SYM */
%token<lexer.keyword> REDO_BUFFER_SIZE_SYM 694
%token<lexer.keyword> REDUNDANT_SYM 695
%token  REFERENCES 696                    /* SQL-2003-R */
%token  REGEXP 697
%token<lexer.keyword> RELAY 698
%token<lexer.keyword> RELAYLOG_SYM 699
%token<lexer.keyword> RELAY_LOG_FILE_SYM 700
%token<lexer.keyword> RELAY_LOG_POS_SYM 701
%token<lexer.keyword> RELAY_THREAD 702
%token  RELEASE_SYM 703                   /* SQL-2003-R */
%token<lexer.keyword> RELOAD 704
%token<lexer.keyword> REMOVE_SYM 705
%token  RENAME 706
%token<lexer.keyword> REORGANIZE_SYM 707
%token<lexer.keyword> REPAIR 708
%token<lexer.keyword> REPEATABLE_SYM 709        /* SQL-2003-N */
%token  REPEAT_SYM 710                    /* MYSQL-FUNC */
%token  REPLACE_SYM 711                   /* MYSQL-FUNC */
%token<lexer.keyword> REPLICATION 712
%token<lexer.keyword> REPLICATE_DO_DB 713
%token<lexer.keyword> REPLICATE_IGNORE_DB 714
%token<lexer.keyword> REPLICATE_DO_TABLE 715
%token<lexer.keyword> REPLICATE_IGNORE_TABLE 716
%token<lexer.keyword> REPLICATE_WILD_DO_TABLE 717
%token<lexer.keyword> REPLICATE_WILD_IGNORE_TABLE 718
%token<lexer.keyword> REPLICATE_REWRITE_DB 719
%token  REQUIRE_SYM 720
%token<lexer.keyword> RESET_SYM 721
%token  RESIGNAL_SYM 722                  /* SQL-2003-R */
%token<lexer.keyword> RESOURCES 723
%token<lexer.keyword> RESTORE_SYM 724
%token  RESTRICT 725
%token<lexer.keyword> RESUME_SYM 726
%token<lexer.keyword> RETURNED_SQLSTATE_SYM 727 /* SQL-2003-N */
%token<lexer.keyword> RETURNS_SYM 728           /* SQL-2003-R */
%token  RETURN_SYM 729                    /* SQL-2003-R */
%token<lexer.keyword> REVERSE_SYM 730
%token  REVOKE 731                        /* SQL-2003-R */
%token  RIGHT 732                         /* SQL-2003-R */
%token<lexer.keyword> ROLLBACK_SYM 733          /* SQL-2003-R */
%token<lexer.keyword> ROLLUP_SYM 734            /* SQL-2003-R */
%token<lexer.keyword> ROTATE_SYM 735
%token<lexer.keyword> ROUTINE_SYM 736           /* SQL-2003-N */
%token  ROWS_SYM 737                      /* SQL-2003-R */
%token<lexer.keyword> ROW_FORMAT_SYM 738
%token  ROW_SYM 739                       /* SQL-2003-R */
%token<lexer.keyword> ROW_COUNT_SYM 740         /* SQL-2003-N */
%token<lexer.keyword> RTREE_SYM 741
%token<lexer.keyword> SAVEPOINT_SYM 742         /* SQL-2003-R */
%token<lexer.keyword> SCHEDULE_SYM 743
%token<lexer.keyword> SCHEMA_NAME_SYM 744       /* SQL-2003-N */
%token  SECOND_MICROSECOND_SYM 745
%token<lexer.keyword> SECOND_SYM 746            /* SQL-2003-R */
%token<lexer.keyword> SECURITY_SYM 747          /* SQL-2003-N */
%token  SELECT_SYM 748                    /* SQL-2003-R */
%token  SENSITIVE_SYM 749                 /* FUTURE-USE */
%token  SEPARATOR_SYM 750
%token<lexer.keyword> SERIALIZABLE_SYM 751      /* SQL-2003-N */
%token<lexer.keyword> SERIAL_SYM 752
%token<lexer.keyword> SESSION_SYM 753           /* SQL-2003-N */
%token<lexer.keyword> SERVER_SYM 754
%token  OBSOLETE_TOKEN_755 755            /* was: SERVER_OPTIONS */
%token  SET_SYM 756                       /* SQL-2003-R */
%token  SET_VAR 757
%token<lexer.keyword> SHARE_SYM 758
%token  SHIFT_LEFT 759                    /* OPERATOR */
%token  SHIFT_RIGHT 760                   /* OPERATOR */
%token  SHOW 761
%token<lexer.keyword> SHUTDOWN 762
%token  SIGNAL_SYM 763                    /* SQL-2003-R */
%token<lexer.keyword> SIGNED_SYM 764
%token<lexer.keyword> SIMPLE_SYM 765            /* SQL-2003-N */
%token<lexer.keyword> SLAVE 766
%token<lexer.keyword> SLOW 767
%token  SMALLINT_SYM 768                  /* SQL-2003-R */
%token<lexer.keyword> SNAPSHOT_SYM 769
%token<lexer.keyword> SOCKET_SYM 770
%token<lexer.keyword> SONAME_SYM 771
%token<lexer.keyword> SOUNDS_SYM 772
%token<lexer.keyword> SOURCE_SYM 773
%token  SPATIAL_SYM 774
%token  SPECIFIC_SYM 775                  /* SQL-2003-R */
%token  SQLEXCEPTION_SYM 776              /* SQL-2003-R */
%token  SQLSTATE_SYM 777                  /* SQL-2003-R */
%token  SQLWARNING_SYM 778                /* SQL-2003-R */
%token<lexer.keyword> SQL_AFTER_GTIDS 779       /* MYSQL */
%token<lexer.keyword> SQL_AFTER_MTS_GAPS 780    /* MYSQL */
%token<lexer.keyword> SQL_BEFORE_GTIDS 781      /* MYSQL */
%token  SQL_BIG_RESULT 782
%token<lexer.keyword> SQL_BUFFER_RESULT 783
%token  OBSOLETE_TOKEN_784 784            /* was: SQL_CACHE_SYM */
%token  SQL_CALC_FOUND_ROWS 785
%token<lexer.keyword> SQL_NO_CACHE_SYM 786
%token  SQL_SMALL_RESULT 787
%token  SQL_SYM 788                       /* SQL-2003-R */
%token<lexer.keyword> SQL_THREAD 789
%token  SSL_SYM 790
%token<lexer.keyword> STACKED_SYM 791           /* SQL-2003-N */
%token  STARTING 792
%token<lexer.keyword> STARTS_SYM 793
%token<lexer.keyword> START_SYM 794             /* SQL-2003-R */
%token<lexer.keyword> STATS_AUTO_RECALC_SYM 795
%token<lexer.keyword> STATS_PERSISTENT_SYM 796
%token<lexer.keyword> STATS_SAMPLE_PAGES_SYM 797
%token<lexer.keyword> STATUS_SYM 798
%token  STDDEV_SAMP_SYM 799               /* SQL-2003-N */
%token  STD_SYM 800
%token<lexer.keyword> STOP_SYM 801
%token<lexer.keyword> STORAGE_SYM 802
%token  STORED_SYM 803
%token  STRAIGHT_JOIN 804
%token<lexer.keyword> STRING_SYM 805
%token<lexer.keyword> SUBCLASS_ORIGIN_SYM 806   /* SQL-2003-N */
%token<lexer.keyword> SUBDATE_SYM 807
%token<lexer.keyword> SUBJECT_SYM 808
%token<lexer.keyword> SUBPARTITIONS_SYM 809
%token<lexer.keyword> SUBPARTITION_SYM 810
%token  SUBSTRING 811                     /* SQL-2003-N */
%token  SUM_SYM 812                       /* SQL-2003-N */
%token<lexer.keyword> SUPER_SYM 813
%token<lexer.keyword> SUSPEND_SYM 814
%token<lexer.keyword> SWAPS_SYM 815
%token<lexer.keyword> SWITCHES_SYM 816
%token  SYSDATE 817
%token<lexer.keyword> TABLES 818
%token<lexer.keyword> TABLESPACE_SYM 819
%token  OBSOLETE_TOKEN_820 820            /* was: TABLE_REF_PRIORITY */
%token  TABLE_SYM 821                     /* SQL-2003-R */
%token<lexer.keyword> TABLE_CHECKSUM_SYM 822
%token<lexer.keyword> TABLE_NAME_SYM 823        /* SQL-2003-N */
%token<lexer.keyword> TEMPORARY 824             /* SQL-2003-N */
%token<lexer.keyword> TEMPTABLE_SYM 825
%token  TERMINATED 826
%token  TEXT_STRING 827
%token<lexer.keyword> TEXT_SYM 828
%token<lexer.keyword> THAN_SYM 829
%token  THEN_SYM 830                      /* SQL-2003-R */
%token<lexer.keyword> TIMESTAMP_SYM 831         /* SQL-2003-R */
%token<lexer.keyword> TIMESTAMP_ADD 832
%token<lexer.keyword> TIMESTAMP_DIFF 833
%token<lexer.keyword> TIME_SYM 834              /* SQL-2003-R */
%token  TINYBLOB_SYM 835                  /* MYSQL */
%token  TINYINT_SYM 836                   /* MYSQL */
%token  TINYTEXT_SYN 837                  /* MYSQL */
%token  TO_SYM 838                        /* SQL-2003-R */
%token  TRAILING 839                      /* SQL-2003-R */
%token<lexer.keyword> TRANSACTION_SYM 840
%token<lexer.keyword> TRIGGERS_SYM 841
%token  TRIGGER_SYM 842                   /* SQL-2003-R */
%token  TRIM 843                          /* SQL-2003-N */
%token  TRUE_SYM 844                      /* SQL-2003-R */
%token<lexer.keyword> TRUNCATE_SYM 845
%token<lexer.keyword> TYPES_SYM 846
%token<lexer.keyword> TYPE_SYM 847              /* SQL-2003-N */
%token  OBSOLETE_TOKEN_848 848            /* was:  UDF_RETURNS_SYM */
%token  ULONGLONG_NUM 849
%token<lexer.keyword> UNCOMMITTED_SYM 850       /* SQL-2003-N */
%token<lexer.keyword> UNDEFINED_SYM 851
%token  UNDERSCORE_CHARSET 852
%token<lexer.keyword> UNDOFILE_SYM 853
%token<lexer.keyword> UNDO_BUFFER_SIZE_SYM 854
%token  UNDO_SYM 855                      /* FUTURE-USE */
%token<lexer.keyword> UNICODE_SYM 856
%token<lexer.keyword> UNINSTALL_SYM 857
%token  UNION_SYM 858                     /* SQL-2003-R */
%token  UNIQUE_SYM 859
%token<lexer.keyword> UNKNOWN_SYM 860           /* SQL-2003-R */
%token  UNLOCK_SYM 861
%token  UNSIGNED_SYM 862                  /* MYSQL */
%token<lexer.keyword> UNTIL_SYM 863
%token  UPDATE_SYM 864                    /* SQL-2003-R */
%token<lexer.keyword> UPGRADE_SYM 865
%token  USAGE 866                         /* SQL-2003-N */
%token<lexer.keyword> USER 867                  /* SQL-2003-R */
%token<lexer.keyword> USE_FRM 868
%token  USE_SYM 869
%token  USING 870                         /* SQL-2003-R */
%token  UTC_DATE_SYM 871
%token  UTC_TIMESTAMP_SYM 872
%token  UTC_TIME_SYM 873
%token<lexer.keyword> VALIDATION_SYM 874        /* MYSQL */
%token  VALUES 875                        /* SQL-2003-R */
%token<lexer.keyword> VALUE_SYM 876             /* SQL-2003-R */
%token  VARBINARY_SYM 877                 /* SQL-2008-R */
%token  VARCHAR_SYM 878                   /* SQL-2003-R */
%token<lexer.keyword> VARIABLES 879
%token  VARIANCE_SYM 880
%token  VARYING 881                       /* SQL-2003-R */
%token  VAR_SAMP_SYM 882
%token<lexer.keyword> VIEW_SYM 883              /* SQL-2003-N */
%token  VIRTUAL_SYM 884
%token<lexer.keyword> WAIT_SYM 885
%token<lexer.keyword> WARNINGS 886
%token<lexer.keyword> WEEK_SYM 887
%token<lexer.keyword> WEIGHT_STRING_SYM 888
%token  WHEN_SYM 889                      /* SQL-2003-R */
%token  WHERE 890                         /* SQL-2003-R */
%token  WHILE_SYM 891
%token  WITH 892                          /* SQL-2003-R */
%token  OBSOLETE_TOKEN_893 893            /* was: WITH_CUBE_SYM */
%token  WITH_ROLLUP_SYM 894               /* INTERNAL */
%token<lexer.keyword> WITHOUT_SYM 895           /* SQL-2003-R */
%token<lexer.keyword> WORK_SYM 896              /* SQL-2003-N */
%token<lexer.keyword> WRAPPER_SYM 897
%token  WRITE_SYM 898                     /* SQL-2003-N */
%token<lexer.keyword> X509_SYM 899
%token<lexer.keyword> XA_SYM 900
%token<lexer.keyword> XID_SYM 901               /* MYSQL */
%token<lexer.keyword> XML_SYM 902
%token  XOR 903
%token  YEAR_MONTH_SYM 904
%token<lexer.keyword> YEAR_SYM 905              /* SQL-2003-R */
%token  ZEROFILL_SYM 906                  /* MYSQL */

/*
   Tokens from MySQL 8.0
*/
%token  JSON_UNQUOTED_SEPARATOR_SYM 907   /* MYSQL */
%token<lexer.keyword> PERSIST_SYM 908           /* MYSQL */
%token<lexer.keyword> ROLE_SYM 909              /* SQL-1999-R */
%token<lexer.keyword> ADMIN_SYM 910             /* SQL-2003-N */
%token<lexer.keyword> INVISIBLE_SYM 911
%token<lexer.keyword> VISIBLE_SYM 912
%token  EXCEPT_SYM 913                    /* SQL-1999-R */
%token<lexer.keyword> COMPONENT_SYM 914         /* MYSQL */
%token  RECURSIVE_SYM 915                 /* SQL-1999-R */
%token  GRAMMAR_SELECTOR_EXPR 916         /* synthetic token: starts single expr. */
%token  GRAMMAR_SELECTOR_GCOL 917       /* synthetic token: starts generated col. */
%token  GRAMMAR_SELECTOR_PART 918      /* synthetic token: starts partition expr. */
%token  GRAMMAR_SELECTOR_CTE 919             /* synthetic token: starts CTE expr. */
%token  JSON_OBJECTAGG 920                /* SQL-2015-R */
%token  JSON_ARRAYAGG 921                 /* SQL-2015-R */
%token  OF_SYM 922                        /* SQL-1999-R */
%token<lexer.keyword> SKIP_SYM 923              /* MYSQL */
%token<lexer.keyword> LOCKED_SYM 924            /* MYSQL */
%token<lexer.keyword> NOWAIT_SYM 925            /* MYSQL */
%token  GROUPING_SYM 926                  /* SQL-2011-R */
%token<lexer.keyword> PERSIST_ONLY_SYM 927      /* MYSQL */
%token<lexer.keyword> HISTOGRAM_SYM 928         /* MYSQL */
%token<lexer.keyword> BUCKETS_SYM 929           /* MYSQL */
%token<lexer.keyword> OBSOLETE_TOKEN_930 930    /* was: REMOTE_SYM */
%token<lexer.keyword> CLONE_SYM 931             /* MYSQL */
%token  CUME_DIST_SYM 932                 /* SQL-2003-R */
%token  DENSE_RANK_SYM 933                /* SQL-2003-R */
%token<lexer.keyword> EXCLUDE_SYM 934           /* SQL-2003-N */
%token  FIRST_VALUE_SYM 935               /* SQL-2011-R */
%token<lexer.keyword> FOLLOWING_SYM 936         /* SQL-2003-N */
%token  GROUPS_SYM 937                    /* SQL-2011-R */
%token  LAG_SYM 938                       /* SQL-2011-R */
%token  LAST_VALUE_SYM 939                /* SQL-2011-R */
%token  LEAD_SYM 940                      /* SQL-2011-R */
%token  NTH_VALUE_SYM 941                 /* SQL-2011-R */
%token  NTILE_SYM 942                     /* SQL-2011-R */
%token<lexer.keyword> NULLS_SYM 943             /* SQL-2003-N */
%token<lexer.keyword> OTHERS_SYM 944            /* SQL-2003-N */
%token  OVER_SYM 945                      /* SQL-2003-R */
%token  PERCENT_RANK_SYM 946              /* SQL-2003-R */
%token<lexer.keyword> PRECEDING_SYM 947         /* SQL-2003-N */
%token  RANK_SYM 948                      /* SQL-2003-R */
%token<lexer.keyword> RESPECT_SYM 949           /* SQL_2011-N */
%token  ROW_NUMBER_SYM 950                /* SQL-2003-R */
%token<lexer.keyword> TIES_SYM 951              /* SQL-2003-N */
%token<lexer.keyword> UNBOUNDED_SYM 952         /* SQL-2003-N */
%token  WINDOW_SYM 953                    /* SQL-2003-R */
%token  EMPTY_SYM 954                     /* SQL-2016-R */
%token  JSON_TABLE_SYM 955                /* SQL-2016-R */
%token<lexer.keyword> NESTED_SYM 956            /* SQL-2016-N */
%token<lexer.keyword> ORDINALITY_SYM 957        /* SQL-2003-N */
%token<lexer.keyword> PATH_SYM 958              /* SQL-2003-N */
%token<lexer.keyword> HISTORY_SYM 959           /* MYSQL */
%token<lexer.keyword> REUSE_SYM 960             /* MYSQL */
%token<lexer.keyword> SRID_SYM 961              /* MYSQL */
%token<lexer.keyword> THREAD_PRIORITY_SYM 962   /* MYSQL */
%token<lexer.keyword> RESOURCE_SYM 963          /* MYSQL */
%token  SYSTEM_SYM 964                    /* SQL-2003-R */
%token<lexer.keyword> VCPU_SYM 965              /* MYSQL */
%token<lexer.keyword> MASTER_PUBLIC_KEY_PATH_SYM 966    /* MYSQL */
%token<lexer.keyword> GET_MASTER_PUBLIC_KEY_SYM 967     /* MYSQL */
%token<lexer.keyword> RESTART_SYM 968                   /* SQL-2003-N */
%token<lexer.keyword> DEFINITION_SYM 969                /* MYSQL */
%token<lexer.keyword> DESCRIPTION_SYM 970               /* MYSQL */
%token<lexer.keyword> ORGANIZATION_SYM 971              /* MYSQL */
%token<lexer.keyword> REFERENCE_SYM 972                 /* MYSQL */
%token<lexer.keyword> ACTIVE_SYM 973                    /* MYSQL */
%token<lexer.keyword> INACTIVE_SYM 974                  /* MYSQL */
%token          LATERAL_SYM 975                   /* SQL-1999-R */
%token<lexer.keyword> ARRAY_SYM 976                     /* SQL-2003-R */
%token<lexer.keyword> MEMBER_SYM 977                    /* SQL-2003-R */
%token<lexer.keyword> OPTIONAL_SYM 978                  /* MYSQL */
%token<lexer.keyword> SECONDARY_SYM 979                 /* MYSQL */
%token<lexer.keyword> SECONDARY_ENGINE_SYM 980          /* MYSQL */
%token<lexer.keyword> SECONDARY_LOAD_SYM 981            /* MYSQL */
%token<lexer.keyword> SECONDARY_UNLOAD_SYM 982          /* MYSQL */
%token<lexer.keyword> RETAIN_SYM 983                    /* MYSQL */
%token<lexer.keyword> OLD_SYM 984                       /* SQL-2003-R */
%token<lexer.keyword> ENFORCED_SYM 985                  /* SQL-2015-N */
%token<lexer.keyword> OJ_SYM 986                        /* ODBC */
%token<lexer.keyword> NETWORK_NAMESPACE_SYM 987         /* MYSQL */
%token<lexer.keyword> RANDOM_SYM 988                    /* MYSQL */
%token<lexer.keyword> MASTER_COMPRESSION_ALGORITHM_SYM 989 /* MYSQL */
%token<lexer.keyword> MASTER_ZSTD_COMPRESSION_LEVEL_SYM 990  /* MYSQL */
%token<lexer.keyword> PRIVILEGE_CHECKS_USER_SYM 991     /* MYSQL */
%token<lexer.keyword> MASTER_TLS_CIPHERSUITES_SYM 992   /* MYSQL */
%token<lexer.keyword> REQUIRE_ROW_FORMAT_SYM 993        /* MYSQL */
%token<lexer.keyword> PASSWORD_LOCK_TIME_SYM 994        /* MYSQL */
%token<lexer.keyword> FAILED_LOGIN_ATTEMPTS_SYM 995     /* MYSQL */
%token<lexer.keyword> REQUIRE_TABLE_PRIMARY_KEY_CHECK_SYM 996 /* MYSQL */
%token<lexer.keyword> STREAM_SYM 997                    /* MYSQL */
%token<lexer.keyword> OFF_SYM 998                       /* SQL-1999-R */
%token<lexer.keyword> RETURNING_SYM 999                 /* SQL-2016-N */
/*
  Here is an intentional gap in token numbers.

  Token numbers starting 1000 till YYUNDEF are occupied by:
  1. hint terminals (see sql_hints.yy),
  2. digest special internal token numbers (see gen_lex_token.cc, PART 6).

  Note: YYUNDEF in internal to Bison. Please don't change its number, or change
  it in sync with YYUNDEF in sql_hints.yy.
*/
%token YYUNDEF 1150                /* INTERNAL (for use in the lexer) */
%token<lexer.keyword> JSON_VALUE_SYM 1151               /* SQL-2016-R */
%token<lexer.keyword> TLS_SYM 1152                      /* MYSQL */
%token<lexer.keyword> ATTRIBUTE_SYM 1153                /* SQL-2003-N */

%token<lexer.keyword> ENGINE_ATTRIBUTE_SYM 1154         /* MYSQL */
%token<lexer.keyword> SECONDARY_ENGINE_ATTRIBUTE_SYM 1155 /* MYSQL */
%token<lexer.keyword> SOURCE_CONNECTION_AUTO_FAILOVER_SYM 1156 /* MYSQL */
%token<lexer.keyword> ZONE_SYM 1157                     /* SQL-2003-N */
%token<lexer.keyword> GRAMMAR_SELECTOR_DERIVED_EXPR 1158  /* synthetic token:
                                                            starts derived
                                                            table expressions. */
%token<lexer.keyword> REPLICA_SYM 1159
%token<lexer.keyword> REPLICAS_SYM 1160
%token<lexer.keyword> ASSIGN_GTIDS_TO_ANONYMOUS_TRANSACTIONS_SYM 1161      /* MYSQL */
%token<lexer.keyword> GET_SOURCE_PUBLIC_KEY_SYM 1162           /* MYSQL */
%token<lexer.keyword> SOURCE_AUTO_POSITION_SYM 1163            /* MYSQL */
%token<lexer.keyword> SOURCE_BIND_SYM 1164                     /* MYSQL */
%token<lexer.keyword> SOURCE_COMPRESSION_ALGORITHM_SYM 1165    /* MYSQL */
%token<lexer.keyword> SOURCE_CONNECT_RETRY_SYM 1166            /* MYSQL */
%token<lexer.keyword> SOURCE_DELAY_SYM 1167                    /* MYSQL */
%token<lexer.keyword> SOURCE_HEARTBEAT_PERIOD_SYM 1168         /* MYSQL */
%token<lexer.keyword> SOURCE_HOST_SYM 1169                     /* MYSQL */
%token<lexer.keyword> SOURCE_LOG_FILE_SYM 1170                 /* MYSQL */
%token<lexer.keyword> SOURCE_LOG_POS_SYM 1171                  /* MYSQL */
%token<lexer.keyword> SOURCE_PASSWORD_SYM 1172                 /* MYSQL */
%token<lexer.keyword> SOURCE_PORT_SYM 1173                     /* MYSQL */
%token<lexer.keyword> SOURCE_PUBLIC_KEY_PATH_SYM 1174          /* MYSQL */
%token<lexer.keyword> SOURCE_RETRY_COUNT_SYM 1175              /* MYSQL */
%token<lexer.keyword> SOURCE_SSL_SYM 1176                      /* MYSQL */
%token<lexer.keyword> SOURCE_SSL_CA_SYM 1177                   /* MYSQL */
%token<lexer.keyword> SOURCE_SSL_CAPATH_SYM 1178               /* MYSQL */
%token<lexer.keyword> SOURCE_SSL_CERT_SYM 1179                 /* MYSQL */
%token<lexer.keyword> SOURCE_SSL_CIPHER_SYM 1180               /* MYSQL */
%token<lexer.keyword> SOURCE_SSL_CRL_SYM 1181                  /* MYSQL */
%token<lexer.keyword> SOURCE_SSL_CRLPATH_SYM 1182              /* MYSQL */
%token<lexer.keyword> SOURCE_SSL_KEY_SYM 1183                  /* MYSQL */
%token<lexer.keyword> SOURCE_SSL_VERIFY_SERVER_CERT_SYM 1184   /* MYSQL */
%token<lexer.keyword> SOURCE_TLS_CIPHERSUITES_SYM 1185         /* MYSQL */
%token<lexer.keyword> SOURCE_TLS_VERSION_SYM 1186              /* MYSQL */
%token<lexer.keyword> SOURCE_USER_SYM 1187                     /* MYSQL */
%token<lexer.keyword> SOURCE_ZSTD_COMPRESSION_LEVEL_SYM 1188   /* MYSQL */

%token<lexer.keyword> ST_COLLECT_SYM 1189                      /* MYSQL */
%token<lexer.keyword> KEYRING_SYM 1190                         /* MYSQL */

%token<lexer.keyword> AUTHENTICATION_SYM         1191      /* MYSQL */
%token<lexer.keyword> FACTOR_SYM                 1192      /* MYSQL */
%token<lexer.keyword> FINISH_SYM                 1193      /* SQL-2016-N */
%token<lexer.keyword> INITIATE_SYM               1194      /* MYSQL */
%token<lexer.keyword> REGISTRATION_SYM           1195      /* MYSQL */
%token<lexer.keyword> UNREGISTER_SYM             1196      /* MYSQL */
%token<lexer.keyword> INITIAL_SYM                1197      /* SQL-2016-R */
%token<lexer.keyword> CHALLENGE_RESPONSE_SYM     1198      /* MYSQL */

%token<lexer.keyword> GTID_ONLY_SYM 1199                       /* MYSQL */

/*
  Precedence rules used to resolve the ambiguity when using keywords as idents
  in the case e.g.:

      SELECT TIMESTAMP'...'

  vs.

      CREATE TABLE t1 ( timestamp INT );

  The use as an ident is allowed, but must never take precedence over the use
  as an actual keyword. Hence we declare the fake token KEYWORD_USED_AS_IDENT
  to have the lowest possible precedence, KEYWORD_USED_AS_KEYWORD need only be
  a bit higher. The TEXT_STRING token is added here to resolve the ambiguity
  in the above example.
*/
%left KEYWORD_USED_AS_IDENT
%nonassoc TEXT_STRING
%left KEYWORD_USED_AS_KEYWORD


/*
  Resolve column attribute ambiguity -- force precedence of "UNIQUE KEY" against
  simple "UNIQUE" and "KEY" attributes:
*/
%right UNIQUE_SYM KEY_SYM

%left CONDITIONLESS_JOIN
%left   JOIN_SYM INNER_SYM CROSS STRAIGHT_JOIN NATURAL LEFT RIGHT ON_SYM USING
%left   SET_VAR
%left   OR_SYM OR2_SYM
%left   XOR
%left   AND_SYM AND_AND_SYM
%left   BETWEEN_SYM CASE_SYM WHEN_SYM THEN_SYM ELSE
%left   EQ EQUAL_SYM GE GT_SYM LE LT NE IS LIKE REGEXP IN_SYM
%left   '|'
%left   '&'
%left   SHIFT_LEFT SHIFT_RIGHT
%left   '-' '+'
%left   '*' '/' '%' DIV_SYM MOD_SYM
%left   '^'
%left   OR_OR_SYM
%left   NEG '~'
%right  NOT_SYM NOT2_SYM
%right  BINARY_SYM COLLATE_SYM
%left  INTERVAL_SYM
%left SUBQUERY_AS_EXPR
%left '(' ')'

%left EMPTY_FROM_CLAUSE
%right INTO

%type <lexer.lex_str>
        IDENT IDENT_QUOTED TEXT_STRING DECIMAL_NUM FLOAT_NUM NUM LONG_NUM HEX_NUM
        LEX_HOSTNAME ULONGLONG_NUM select_alias ident opt_ident ident_or_text
        role_ident role_ident_or_text
        IDENT_sys TEXT_STRING_sys TEXT_STRING_literal
        NCHAR_STRING opt_component
        BIN_NUM TEXT_STRING_filesystem ident_or_empty
        TEXT_STRING_sys_nonewline TEXT_STRING_password TEXT_STRING_hash
        TEXT_STRING_validated
        filter_wild_db_table_string
        opt_constraint_name
        ts_datafile lg_undofile /*lg_redofile*/ opt_logfile_group_name opt_ts_datafile_name
        opt_describe_column
        opt_datadir_ssl default_encryption
        lvalue_ident
        schema
        engine_or_all
        opt_binlog_in

%type <lex_cstr>
        key_cache_name
        label_ident
        opt_table_alias
        opt_replace_password
        sp_opt_label
        json_attribute
        opt_channel

%type <lex_str_list> TEXT_STRING_sys_list

%type <table>
        table_ident

%type <simple_string>
        opt_db

%type <string>
        text_string opt_gconcat_separator
        opt_xml_rows_identified_by

%type <num>
        lock_option
        udf_type if_exists
        opt_no_write_to_binlog
        all_or_any opt_distinct
        fulltext_options union_option
        transaction_access_mode_types
        opt_natural_language_mode opt_query_expansion
        opt_ev_status opt_ev_on_completion ev_on_completion opt_ev_comment
        ev_alter_on_schedule_completion opt_ev_rename_to opt_ev_sql_stmt
        trg_action_time trg_event
        view_check_option
        signed_num
        opt_num_buckets


%type <order_direction>
        ordering_direction opt_ordering_direction

/*
  Bit field of MYSQL_START_TRANS_OPT_* flags.
*/
%type <num> opt_start_transaction_option_list
%type <num> start_transaction_option_list
%type <num> start_transaction_option

%type <m_yes_no_unk>
        opt_chain opt_release

%type <m_fk_option>
        delete_option

%type <ulong_num>
        ulong_num real_ulong_num merge_insert_types
        ws_num_codepoints func_datetime_precision
        now
        opt_checksum_type
        opt_ignore_lines
        opt_profile_defs
        profile_defs
        profile_def
        factor

%type <ulonglong_number>
        ulonglong_num real_ulonglong_num size_number
        option_autoextend_size

%type <lock_type>
        replace_lock_option opt_low_priority insert_lock_option load_data_lock

%type <locked_row_action> locked_row_action opt_locked_row_action

%type <item>
        literal insert_ident temporal_literal
        simple_ident expr opt_expr opt_else
        set_function_specification sum_expr
        in_sum_expr grouping_operation
        window_func_call opt_ll_default
        variable variable_aux bool_pri
        predicate bit_expr
        table_wild simple_expr udf_expr
        expr_or_default set_expr_or_default
        geometry_function
        signed_literal now_or_signed_literal
        simple_ident_nospvar simple_ident_q
        field_or_var limit_option
        function_call_keyword
        function_call_nonkeyword
        function_call_generic
        function_call_conflict
        signal_allowed_expr
        simple_target_specification
        condition_number
        filter_db_ident
        filter_table_ident
        filter_string
        select_item
        opt_where_clause
        where_clause
        opt_having_clause
        opt_simple_limit
        null_as_literal
        literal_or_null
        signed_literal_or_null
        stable_integer
        param_or_var

%type <item_string> window_name opt_existing_window_name

%type <item_num> NUM_literal
        int64_literal

%type <item_list>
        when_list
        opt_filter_db_list filter_db_list
        opt_filter_table_list filter_table_list
        opt_filter_string_list filter_string_list
        opt_filter_db_pair_list filter_db_pair_list

%type <item_list2>
        expr_list udf_expr_list opt_udf_expr_list opt_expr_list select_item_list
        opt_paren_expr_list ident_list_arg ident_list values opt_values row_value fields
        fields_or_vars
        opt_field_or_var_spec
        row_value_explicit

%type <var_type>
        option_type opt_var_type opt_var_ident_type opt_set_var_ident_type

%type <key_type>
        opt_unique constraint_key_type

%type <key_alg>
        index_type

%type <string_list>
        string_list using_list opt_use_partition use_partition ident_string_list
        all_or_alt_part_name_list

%type <key_part>
        key_part key_part_with_expression

%type <date_time_type> date_time_type;
%type <interval> interval

%type <interval_time_st> interval_time_stamp

%type <row_type> row_types

%type <resource_group_type> resource_group_types

%type <resource_group_vcpu_list_type>
        opt_resource_group_vcpu_list
        vcpu_range_spec_list

%type <resource_group_priority_type> opt_resource_group_priority

%type <resource_group_state_type> opt_resource_group_enable_disable

%type <resource_group_flag_type> opt_force

%type <thread_id_list_type> thread_id_list thread_id_list_options

%type <vcpu_range_type> vcpu_num_or_range

%type <tx_isolation> isolation_types

%type <ha_rkey_mode> handler_rkey_mode

%type <ha_read_mode> handler_scan_function
        handler_rkey_function

%type <cast_type> cast_type opt_returning_type

%type <lexer.keyword> ident_keyword label_keyword role_keyword
        lvalue_keyword
        ident_keywords_unambiguous
        ident_keywords_ambiguous_1_roles_and_labels
        ident_keywords_ambiguous_2_labels
        ident_keywords_ambiguous_3_roles
        ident_keywords_ambiguous_4_system_variables

%type <lex_user> user_ident_or_text user create_user alter_user user_func role

%type <lex_mfa>
        identification
        identified_by_password
        identified_by_random_password
        identified_with_plugin
        identified_with_plugin_as_auth
        identified_with_plugin_by_random_password
        identified_with_plugin_by_password
        opt_initial_auth
        opt_user_registration

%type <lex_mfas> opt_create_user_with_mfa

%type <lexer.charset>
        opt_collate
        charset_name
        old_or_new_charset_name
        old_or_new_charset_name_or_default
        collation_name
        opt_load_data_charset
        UNDERSCORE_CHARSET
        ascii unicode
        default_charset default_collation

%type <boolfunc2creator> comp_op

%type <num>  sp_decl_idents sp_opt_inout sp_handler_type sp_hcond_list
%type <spcondvalue> sp_cond sp_hcond sqlstate signal_value opt_signal_value
%type <spblock> sp_decls sp_decl
%type <spname> sp_name
%type <index_hint> index_hint_type
%type <num> index_hint_clause
%type <filetype> data_or_xml

%type <da_condition_item_name> signal_condition_information_item_name

%type <diag_area> which_area;
%type <diag_info> diagnostics_information;
%type <stmt_info_item> statement_information_item;
%type <stmt_info_item_name> statement_information_item_name;
%type <stmt_info_list> statement_information;
%type <cond_info_item> condition_information_item;
%type <cond_info_item_name> condition_information_item_name;
%type <cond_info_list> condition_information;
%type <signal_item_list> signal_information_item_list;
%type <signal_item_list> opt_set_signal_information;

%type <trg_characteristics> trigger_follows_precedes_clause;
%type <trigger_action_order_type> trigger_action_order;

%type <xid> xid;
%type <xa_option_type> opt_join_or_resume;
%type <xa_option_type> opt_suspend;
%type <xa_option_type> opt_one_phase;

%type <is_not_empty> opt_convert_xid opt_ignore opt_linear opt_bin_mod
        opt_if_not_exists opt_temporary
        opt_grant_option opt_with_admin_option
        opt_full opt_extended
        opt_ignore_leaves
        opt_local
        opt_retain_current_password
        opt_discard_old_password
        opt_constraint_enforcement
        constraint_enforcement
        opt_not
        opt_interval

%type <show_cmd_type> opt_show_cmd_type

/*
  A bit field of SLAVE_IO, SLAVE_SQL flags.
*/
%type <num> opt_replica_thread_option_list
%type <num> replica_thread_option_list
%type <num> replica_thread_option

%type <key_usage_element> key_usage_element

%type <key_usage_list> key_usage_list opt_key_usage_list index_hint_definition
        index_hints_list opt_index_hints_list opt_key_definition
        opt_cache_key_list

%type <order_expr> order_expr alter_order_item
        grouping_expr

%type <order_list> order_list group_list gorder_list opt_gorder_clause
      alter_order_list opt_partition_clause opt_window_order_by_clause

%type <c_str> field_length opt_field_length type_datetime_precision
        opt_place

%type <precision> precision opt_precision float_options standard_float_options

%type <charset_with_opt_binary> opt_charset_with_opt_binary

%type <limit_options> limit_options

%type <limit_clause> limit_clause opt_limit_clause

%type <ulonglong_number> query_spec_option

%type <select_options> select_option select_option_list select_options

%type <node>
          option_value

%type <join_table> joined_table joined_table_parens

%type <table_reference_list> opt_from_clause from_clause from_tables
        table_reference_list table_reference_list_parens explicit_table

%type <olap_type> olap_opt

%type <group> opt_group_clause

%type <windows> opt_window_clause  ///< Definition of named windows
                                   ///< for the query specification
                window_definition_list

%type <window> window_definition window_spec window_spec_details window_name_or_spec
  windowing_clause   ///< Definition of unnamed window near the window function.
  opt_windowing_clause ///< For functions which can be either set or window
                       ///< functions (e.g. SUM), non-empty clause makes the difference.

%type <window_frame> opt_window_frame_clause

%type <frame_units> window_frame_units

%type <frame_extent> window_frame_extent window_frame_between

%type <bound> window_frame_start window_frame_bound

%type <frame_exclusion> opt_window_frame_exclusion

%type <null_treatment> opt_null_treatment

%type <lead_lag_info> opt_lead_lag_info

%type <from_first_last> opt_from_first_last

%type <order> order_clause opt_order_clause

%type <locking_clause> locking_clause

%type <locking_clause_list> locking_clause_list

%type <lock_strength> lock_strength

%type <table_reference> table_reference esc_table_reference
        table_factor single_table single_table_parens table_function

%type <query_expression_body> query_expression_body

%type <internal_variable_name> internal_variable_name

%type <option_value_following_option_type> option_value_following_option_type

%type <option_value_no_option_type> option_value_no_option_type

%type <option_value_list> option_value_list option_value_list_continued

%type <start_option_value_list> start_option_value_list

%type <transaction_access_mode> transaction_access_mode
        opt_transaction_access_mode

%type <isolation_level> isolation_level opt_isolation_level

%type <transaction_characteristics> transaction_characteristics

%type <start_option_value_list_following_option_type>
        start_option_value_list_following_option_type

%type <set> set

%type <line_separators> line_term line_term_list opt_line_term

%type <field_separators> field_term field_term_list opt_field_term

%type <into_destination> into_destination into_clause

%type <select_var_ident> select_var_ident

%type <select_var_list> select_var_list

%type <query_primary>
        as_create_query_expression
        query_expression_or_parens
        query_expression_parens
        query_primary
        query_specification

%type <query_expression> query_expression

%type <subquery> subquery row_subquery table_subquery

%type <derived_table> derived_table

%type <param_marker> param_marker

%type <text_literal> text_literal

%type <top_level_node>
        alter_instance_stmt
        alter_resource_group_stmt
        alter_table_stmt
        analyze_table_stmt
        call_stmt
        check_table_stmt
        create_index_stmt
        create_resource_group_stmt
        create_role_stmt
        create_srs_stmt
        create_table_stmt
        delete_stmt
        describe_stmt
        do_stmt
        drop_index_stmt
        drop_resource_group_stmt
        drop_role_stmt
        drop_srs_stmt
        explain_stmt
        explainable_stmt
        handler_stmt
        insert_stmt
        keycache_stmt
        load_stmt
        optimize_table_stmt
        preload_stmt
        repair_table_stmt
        replace_stmt
        restart_server_stmt
        select_stmt
        select_stmt_with_into
        set_resource_group_stmt
        set_role_stmt
        show_binary_logs_stmt
        show_binlog_events_stmt
        show_character_set_stmt
        show_collation_stmt
        show_columns_stmt
        show_count_errors_stmt
        show_count_warnings_stmt
        show_create_database_stmt
        show_create_event_stmt
        show_create_function_stmt
        show_create_procedure_stmt
        show_create_table_stmt
        show_create_trigger_stmt
        show_create_user_stmt
        show_create_view_stmt
        show_databases_stmt
        show_engine_logs_stmt
        show_engine_mutex_stmt
        show_engine_status_stmt
        show_engines_stmt
        show_errors_stmt
        show_events_stmt
        show_function_code_stmt
        show_function_status_stmt
        show_grants_stmt
        show_keys_stmt
        show_master_status_stmt
        show_open_tables_stmt
        show_plugins_stmt
        show_privileges_stmt
        show_procedure_code_stmt
        show_procedure_status_stmt
        show_processlist_stmt
        show_profile_stmt
        show_profiles_stmt
        show_relaylog_events_stmt
        show_replica_status_stmt
        show_replicas_stmt
        show_status_stmt
        show_table_status_stmt
        show_tables_stmt
        show_triggers_stmt
        show_variables_stmt
        show_warnings_stmt
        shutdown_stmt
        simple_statement
        truncate_stmt
        update_stmt

%type <table_ident> table_ident_opt_wild

%type <table_ident_list> table_alias_ref_list table_locking_list

%type <simple_ident_list> simple_ident_list opt_derived_column_list

%type <num> opt_delete_options

%type <opt_delete_option> opt_delete_option

%type <column_value_pair>
        update_elem

%type <column_value_list_pair>
        update_list
        opt_insert_update_list

%type <values_list> values_list insert_values table_value_constructor
        values_row_list

%type <insert_query_expression> insert_query_expression

%type <column_row_value_list_pair> insert_from_constructor

%type <lexer.optimizer_hints> SELECT_SYM INSERT_SYM REPLACE_SYM UPDATE_SYM DELETE_SYM

%type <join_type> outer_join_type natural_join_type inner_join_type

%type <user_list> user_list role_list default_role_clause opt_except_role_list

%type <alter_instance_cmd> alter_instance_action

%type <index_column_list> key_list key_list_with_expression

%type <index_options> opt_index_options index_options  opt_fulltext_index_options
          fulltext_index_options opt_spatial_index_options spatial_index_options

%type <opt_index_lock_and_algorithm> opt_index_lock_and_algorithm

%type <index_option> index_option common_index_option fulltext_index_option
          spatial_index_option
          index_type_clause
          opt_index_type_clause

%type <alter_table_algorithm> alter_algorithm_option_value
        alter_algorithm_option

%type <alter_table_lock> alter_lock_option_value alter_lock_option

%type <table_constraint_def> table_constraint_def

%type <index_name_and_type> opt_index_name_and_type

%type <visibility> visibility

%type <with_clause> with_clause opt_with_clause
%type <with_list> with_list
%type <common_table_expr> common_table_expr

%type <partition_option> part_option

%type <partition_option_list> opt_part_options part_option_list

%type <sub_part_definition> sub_part_definition

%type <sub_part_list> sub_part_list opt_sub_partition

%type <part_value_item> part_value_item

%type <part_value_item_list> part_value_item_list

%type <part_value_item_list_paren> part_value_item_list_paren part_func_max

%type <part_value_list> part_value_list

%type <part_values> part_values_in

%type <opt_part_values> opt_part_values

%type <part_definition> part_definition

%type <part_def_list> part_def_list opt_part_defs

%type <ulong_num> opt_num_subparts opt_num_parts

%type <name_list> name_list opt_name_list

%type <opt_key_algo> opt_key_algo

%type <opt_sub_part> opt_sub_part

%type <part_type_def> part_type_def

%type <partition_clause> partition_clause

%type <mi_type> mi_repair_type mi_repair_types opt_mi_repair_types
        mi_check_type mi_check_types opt_mi_check_types

%type <opt_restrict> opt_restrict;

%type <table_list> table_list opt_table_list

%type <ternary_option> ternary_option;

%type <create_table_option> create_table_option

%type <create_table_options> create_table_options

%type <space_separated_alter_table_opts> create_table_options_space_separated

%type <on_duplicate> duplicate opt_duplicate

%type <col_attr> column_attribute

%type <column_format> column_format

%type <storage_media> storage_media

%type <col_attr_list> column_attribute_list opt_column_attribute_list

%type <virtual_or_stored> opt_stored_attribute

%type <field_option> field_option field_opt_list field_options

%type <int_type> int_type

%type <type> spatial_type type

%type <numeric_type> real_type numeric_type

%type <sp_default> sp_opt_default

%type <field_def> field_def

%type <item> check_constraint

%type <table_constraint_def> opt_references

%type <fk_options> opt_on_update_delete

%type <opt_match_clause> opt_match_clause

%type <reference_list> reference_list opt_ref_list

%type <fk_references> references

%type <column_def> column_def

%type <table_element> table_element

%type <table_element_list> table_element_list

%type <create_table_tail> opt_create_table_options_etc
        opt_create_partitioning_etc opt_duplicate_as_qe

%type <wild_or_where> opt_wild_or_where

// used by JSON_TABLE
%type <jtc_list> columns_clause columns_list
%type <jt_column> jt_column
%type <json_on_response> json_on_response on_empty on_error
%type <json_on_error_or_empty> opt_on_empty_or_error
        opt_on_empty_or_error_json_table
%type <jt_column_type> jt_column_type

%type <acl_type> opt_acl_type
%type <histogram> opt_histogram

%type <lex_cstring_list> column_list opt_column_list

%type <role_or_privilege> role_or_privilege

%type <role_or_privilege_list> role_or_privilege_list

%type <with_validation> with_validation opt_with_validation
/*%type <ts_access_mode> ts_access_mode*/

%type <alter_table_action> alter_list_item alter_table_partition_options
%type <ts_options> logfile_group_option_list opt_logfile_group_options
                   alter_logfile_group_option_list opt_alter_logfile_group_options
                   tablespace_option_list opt_tablespace_options
                   alter_tablespace_option_list opt_alter_tablespace_options
                   opt_drop_ts_options drop_ts_option_list
                   undo_tablespace_option_list opt_undo_tablespace_options

%type <alter_table_standalone_action> standalone_alter_commands

%type <algo_and_lock_and_validation>alter_commands_modifier
        alter_commands_modifier_list

%type <alter_list> alter_list opt_alter_command_list opt_alter_table_actions

%type <standalone_alter_table_action> standalone_alter_table_action

%type <assign_to_keycache> assign_to_keycache

%type <keycache_list> keycache_list

%type <adm_partition> adm_partition

%type <preload_keys> preload_keys

%type <preload_list> preload_list
%type <ts_option>
        alter_logfile_group_option
        alter_tablespace_option
        drop_ts_option
        logfile_group_option
        tablespace_option
        undo_tablespace_option
        ts_option_autoextend_size
        ts_option_comment
        ts_option_engine
        ts_option_extent_size
        ts_option_file_block_size
        ts_option_initial_size
        ts_option_max_size
        ts_option_nodegroup
        ts_option_redo_buffer_size
        ts_option_undo_buffer_size
        ts_option_wait
        ts_option_encryption
        ts_option_engine_attribute

%type <explain_format_type> opt_explain_format_type
%type <explain_format_type> opt_explain_analyze_type

%type <load_set_element> load_data_set_elem

%type <load_set_list> load_data_set_list opt_load_data_set_spec

%type <num> opt_array_cast
%type <sql_cmd_srs_attributes> srs_attributes

%type <insert_update_values_reference> opt_values_reference

%type <alter_tablespace_type> undo_tablespace_state

%type <query_id> opt_for_query

%%

/*
  Indentation of grammar rules:

rule: <-- starts at col 1
          rule1a rule1b rule1c <-- starts at col 11
          { <-- starts at col 11
            code <-- starts at col 13, indentation is 2 spaces
          }
        | rule2a rule2b
          {
            code
          }
        ; <-- on a line by itself, starts at col 9

  Also, please do not use any <TAB>, but spaces.
  Having a uniform indentation in this file helps
  code reviews, patches, merges, and make maintenance easier.
  Tip: grep [[:cntrl:]] sql_yacc.yy
  Thanks.
*/

start_entry:
SELECT_SYM {
  /* $$ = new IR(kProgram, OP0()); */
  ir_vec.size();
};

/**
  @} (end of group Parser)
*/
