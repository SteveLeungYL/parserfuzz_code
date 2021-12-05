
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

%code requires {

#include <vector>
using std::vector;
#include "../include/ast.h"

#include "./sql_parse_entry.h"
}

%{


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

// #define yyoverflow(A,B,C,D,E,F,G,H)           \
//   {                                           \
//     ulong val= *(H);                          \
//     if (my_yyoverflow((B), (D), (F), &val))   \
//     {                                         \
//       yyerror(NULL, YYTHD, NULL, ir_vec, (const char*) (A));\
//       return 2;                               \
//     }                                         \
//     else                                      \
//     {                                         \
//       *(H)= (YYSIZE_T)val;                    \
//     }                                         \
//   }

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
void MYSQLerror(YYLTYPE *location, THD *thd, Parse_tree_root **, vector<IR*>& ir_vec, IR* res, const char *s)
{
  if (strcmp(s, "syntax error") == 0) {
    // thd->syntax_error_at(*location);
  } else if (strcmp(s, "memory exhausted") == 0) {
    /* my_error(ER_DA_OOM, MYF(0)); */
  } else {
    // Find omitted error messages in the generated file (sql_yacc.cc) and fix:
    assert(false);
    /* my_error(ER_UNKNOWN_ERROR, MYF(0)); */
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

/* static bool is_native_function(const LEX_STRING &name) */
/* { */
/*   if (find_native_function_builder(name) != nullptr) */
/*     return true; */

/*   if (is_lex_native_function(&name)) */
/*     return true; */

/*   return false; */
/* } */


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

/* static void case_stmt_action_case(THD *thd) */
/* { */
/*   LEX *lex= thd->lex; */
/*   sp_head *sp= lex->sphead; */
/*   sp_pcontext *pctx= lex->get_sp_current_parsing_ctx(); */

/*   sp->m_parser_data.new_cont_backpatch(); */

/*   /\* */
/*     BACKPATCH: Creating target label for the jump to */
/*     "case_stmt_action_end_case" */
/*     (Instruction 12 in the example) */
/*   *\/ */

/*   pctx->push_label(thd, EMPTY_CSTR, sp->instructions()); */
/* } */

/**
  Helper action for a case then statements.
  This helper is used for both 'simple' and 'searched' cases.
  @param lex the parser lex context
*/

/* static bool case_stmt_action_then(THD *thd, LEX *lex) */
/* { */
/*   sp_head *sp= lex->sphead; */
/*   sp_pcontext *pctx= lex->get_sp_current_parsing_ctx(); */

/*   sp_instr_jump *i = */
/*     new (thd->mem_root) sp_instr_jump(sp->instructions(), pctx); */

/*   if (!i || sp->add_instr(thd, i)) */
/*     return true; */

/*   /\* */
/*     BACKPATCH: Resolving forward jump from */
/*     "case_stmt_action_when" to "case_stmt_action_then" */
/*     (jump_if_not from instruction 2 to 5, 5 to 8 ... in the example) */
/*   *\/ */

/*   sp->m_parser_data.do_backpatch(pctx->pop_label(), sp->instructions()); */

/*   /\* */
/*     BACKPATCH: Registering forward jump from */
/*     "case_stmt_action_then" to "case_stmt_action_end_case" */
/*     (jump from instruction 4 to 12, 7 to 12 ... in the example) */
/*   *\/ */

/*   return sp->m_parser_data.add_backpatch_entry(i, pctx->last_label()); */
/* } */

/**
  Helper action for an end case.
  This helper is used for both 'simple' and 'searched' cases.
  @param lex the parser lex context
  @param simple true for simple cases, false for searched cases
*/

/* static void case_stmt_action_end_case(LEX *lex, bool simple) */
/* { */
/*   sp_head *sp= lex->sphead; */
/*   sp_pcontext *pctx= lex->get_sp_current_parsing_ctx(); */

/*   /\* */
/*     BACKPATCH: Resolving forward jump from */
/*     "case_stmt_action_then" to "case_stmt_action_end_case" */
/*     (jump from instruction 4 to 12, 7 to 12 ... in the example) */
/*   *\/ */
/*   sp->m_parser_data.do_backpatch(pctx->pop_label(), sp->instructions()); */

/*   if (simple) */
/*     pctx->pop_case_expr_id(); */

/*   sp->m_parser_data.do_cont_backpatch(sp->instructions()); */
/* } */


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

/* void warn_about_deprecated_national(THD *thd) */
/* { */
/*   if (native_strcasecmp(national_charset_info->csname, "utf8") == 0) */
/*     push_warning(thd, ER_DEPRECATED_NATIONAL); */
/* } */

/* void warn_about_deprecated_binary(THD *thd) */
/* { */
/*   push_deprecated_warn(thd, "BINARY as attribute of a type", */
/*   "a CHARACTER SET clause with _bin collation"); */
/* } */


%}

%start start_entry

%parse-param { class THD *YYTHD }
%parse-param { class Parse_tree_root **parse_tree }

%lex-param { class THD *YYTHD }
%parse-param { vector<IR*>& ir_vec }
%parse-param {IR* res }
%pure-parser                                    /* We have threads */

/*
  1. We do not accept any reduce/reduce conflicts
  2. We should not introduce new shift/reduce conflicts any more.
*/

%expect 63

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

%type <ir>
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

%type <ir>
        key_cache_name
        label_ident
        opt_table_alias
        opt_replace_password
        sp_opt_label
        json_attribute
        opt_channel

%type <ir> TEXT_STRING_sys_list

%type <ir>
        table_ident

%type <ir>
        opt_db

%type <ir>
        text_string opt_gconcat_separator
        opt_xml_rows_identified_by

%type <ir>
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


%type <ir>
        ordering_direction opt_ordering_direction

/*
  Bit field of MYSQL_START_TRANS_OPT_* flags.
*/
%type <ir> opt_start_transaction_option_list
%type <ir> start_transaction_option_list
%type <ir> start_transaction_option

%type <ir>
        opt_chain opt_release

%type <ir>
        delete_option

%type <ir>
        ulong_num real_ulong_num merge_insert_types
        ws_num_codepoints func_datetime_precision
        now
        opt_checksum_type
        opt_ignore_lines
        opt_profile_defs
        profile_defs
        profile_def
        factor

%type <ir>
        ulonglong_num real_ulonglong_num size_number
        option_autoextend_size

%type <ir>
        replace_lock_option opt_low_priority insert_lock_option load_data_lock

%type <ir> locked_row_action opt_locked_row_action

%type <ir>
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

%type <ir> window_name opt_existing_window_name

%type <ir> NUM_literal
        int64_literal

%type <ir>
        when_list
        opt_filter_db_list filter_db_list
        opt_filter_table_list filter_table_list
        opt_filter_string_list filter_string_list
        opt_filter_db_pair_list filter_db_pair_list

%type <ir>
        expr_list udf_expr_list opt_udf_expr_list opt_expr_list select_item_list
        opt_paren_expr_list ident_list_arg ident_list values opt_values row_value fields
        fields_or_vars
        opt_field_or_var_spec
        row_value_explicit

%type <ir>
        option_type opt_var_type opt_var_ident_type opt_set_var_ident_type

%type <ir>
        opt_unique constraint_key_type

%type <ir>
        index_type

%type <ir>
        string_list using_list opt_use_partition use_partition ident_string_list
        all_or_alt_part_name_list

%type <ir>
        key_part key_part_with_expression

%type <ir> date_time_type;
%type <ir> interval

%type <ir> interval_time_stamp

%type <ir> row_types

%type <ir> resource_group_types

%type <ir>
        opt_resource_group_vcpu_list
        vcpu_range_spec_list

%type <ir> opt_resource_group_priority

%type <ir> opt_resource_group_enable_disable

%type <ir> opt_force

%type <ir> thread_id_list thread_id_list_options

%type <ir> vcpu_num_or_range

%type <ir> isolation_types

%type <ir> handler_rkey_mode

%type <ir> handler_scan_function
        handler_rkey_function

%type <ir> cast_type opt_returning_type

%type <ir> ident_keyword label_keyword role_keyword
        lvalue_keyword
        ident_keywords_unambiguous
        ident_keywords_ambiguous_1_roles_and_labels
        ident_keywords_ambiguous_2_labels
        ident_keywords_ambiguous_3_roles
        ident_keywords_ambiguous_4_system_variables

%type <ir> user_ident_or_text user create_user alter_user user_func role

%type <ir>
        identification
        identified_by_password
        identified_by_random_password
        identified_with_plugin
        identified_with_plugin_as_auth
        identified_with_plugin_by_random_password
        identified_with_plugin_by_password
        opt_initial_auth
        opt_user_registration

%type <ir> opt_create_user_with_mfa

%type <ir>
        opt_collate
        charset_name
        old_or_new_charset_name
        old_or_new_charset_name_or_default
        collation_name
        opt_load_data_charset
        UNDERSCORE_CHARSET
        ascii unicode
        default_charset default_collation

%type <ir> comp_op

%type <ir>  sp_decl_idents sp_opt_inout sp_handler_type sp_hcond_list
%type <ir> sp_cond sp_hcond sqlstate signal_value opt_signal_value
%type <ir> sp_decls sp_decl
%type <ir> sp_name
%type <ir> index_hint_type
%type <ir> index_hint_clause
%type <ir> data_or_xml

%type <ir> signal_condition_information_item_name

%type <ir> which_area;
%type <ir> diagnostics_information;
%type <ir> statement_information_item;
%type <ir> statement_information_item_name;
%type <ir> statement_information;
%type <ir> condition_information_item;
%type <ir> condition_information_item_name;
%type <ir> condition_information;
%type <ir> signal_information_item_list;
%type <ir> opt_set_signal_information;

%type <ir> trigger_follows_precedes_clause;
%type <ir> trigger_action_order;

%type <ir> xid;
%type <ir> opt_join_or_resume;
%type <ir> opt_suspend;
%type <ir> opt_one_phase;

%type <ir> opt_convert_xid opt_ignore opt_linear opt_bin_mod
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

%type <ir> opt_show_cmd_type

/*
  A bit field of SLAVE_IO, SLAVE_SQL flags.
*/
%type <ir> opt_replica_thread_option_list
%type <ir> replica_thread_option_list
%type <ir> replica_thread_option

%type <ir> key_usage_element

%type <ir> key_usage_list opt_key_usage_list index_hint_definition
        index_hints_list opt_index_hints_list opt_key_definition
        opt_cache_key_list

%type <ir> order_expr alter_order_item
        grouping_expr

%type <ir> order_list group_list gorder_list opt_gorder_clause
      alter_order_list opt_partition_clause opt_window_order_by_clause

%type <ir> field_length opt_field_length type_datetime_precision
        opt_place

%type <ir> precision opt_precision float_options standard_float_options

%type <ir> opt_charset_with_opt_binary

%type <ir> limit_options

%type <ir> limit_clause opt_limit_clause

%type <ir> query_spec_option

%type <ir> select_option select_option_list select_options

%type <ir>
          option_value

%type <ir> joined_table joined_table_parens

%type <ir> opt_from_clause from_clause from_tables
        table_reference_list table_reference_list_parens explicit_table

%type <ir> olap_opt

%type <ir> opt_group_clause

%type <ir> opt_window_clause  ///< Definition of named windows
                                   ///< for the query specification
                window_definition_list

%type <ir> window_definition window_spec window_spec_details window_name_or_spec
  windowing_clause   ///< Definition of unnamed window near the window function.
  opt_windowing_clause ///< For functions which can be either set or window
                       ///< functions (e.g. SUM), non-empty clause makes the difference.

%type <ir> opt_window_frame_clause

%type <ir> window_frame_units

%type <ir> window_frame_extent window_frame_between

%type <ir> window_frame_start window_frame_bound

%type <ir> opt_window_frame_exclusion

%type <ir> opt_null_treatment

%type <ir> opt_lead_lag_info

%type <ir> opt_from_first_last

%type <ir> order_clause opt_order_clause

%type <ir> locking_clause

%type <ir> locking_clause_list

%type <ir> lock_strength

%type <ir> table_reference esc_table_reference
        table_factor single_table single_table_parens table_function

%type <ir> query_expression_body

%type <ir> internal_variable_name

%type <ir> option_value_following_option_type

%type <ir> option_value_no_option_type

%type <ir> option_value_list option_value_list_continued

%type <ir> start_option_value_list

%type <ir> transaction_access_mode
        opt_transaction_access_mode

%type <ir> isolation_level opt_isolation_level

%type <ir> transaction_characteristics

%type <ir>
        start_option_value_list_following_option_type

%type <ir> set

%type <ir> line_term line_term_list opt_line_term

%type <ir> field_term field_term_list opt_field_term

%type <ir> into_destination into_clause

%type <ir> select_var_ident

%type <ir> select_var_list

%type <ir>
        as_create_query_expression
        query_expression_or_parens
        query_expression_parens
        query_primary
        query_specification

%type <ir> query_expression

%type <ir> subquery row_subquery table_subquery

%type <ir> derived_table

%type <ir> param_marker

%type <ir> text_literal

%type <ir>
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

%type <ir> table_ident_opt_wild

%type <ir> table_alias_ref_list table_locking_list

%type <ir> simple_ident_list opt_derived_column_list

%type <ir> opt_delete_options

%type <ir> opt_delete_option

%type <ir>
        update_elem

%type <ir>
        update_list
        opt_insert_update_list

%type <ir> values_list insert_values table_value_constructor
        values_row_list

%type <ir> insert_query_expression

%type <ir> insert_from_constructor

%type <ir> SELECT_SYM INSERT_SYM REPLACE_SYM UPDATE_SYM DELETE_SYM

%type <ir> outer_join_type natural_join_type inner_join_type

%type <ir> user_list role_list default_role_clause opt_except_role_list

%type <ir> alter_instance_action

%type <ir> key_list key_list_with_expression

%type <ir> opt_index_options index_options  opt_fulltext_index_options
          fulltext_index_options opt_spatial_index_options spatial_index_options

%type <ir> opt_index_lock_and_algorithm

%type <ir> index_option common_index_option fulltext_index_option
          spatial_index_option
          index_type_clause
          opt_index_type_clause

%type <ir> alter_algorithm_option_value
        alter_algorithm_option

%type <ir> alter_lock_option_value alter_lock_option

%type <ir> table_constraint_def

%type <ir> opt_index_name_and_type

%type <ir> visibility

%type <ir> with_clause opt_with_clause
%type <ir> with_list
%type <ir> common_table_expr

%type <ir> part_option

%type <ir> opt_part_options part_option_list

%type <ir> sub_part_definition

%type <ir> sub_part_list opt_sub_partition

%type <ir> part_value_item

%type <ir> part_value_item_list

%type <ir> part_value_item_list_paren part_func_max

%type <ir> part_value_list

%type <ir> part_values_in

%type <ir> opt_part_values

%type <ir> part_definition

%type <ir> part_def_list opt_part_defs

%type <ir> opt_num_subparts opt_num_parts

%type <ir> name_list opt_name_list

%type <ir> opt_key_algo

%type <ir> opt_sub_part

%type <ir> part_type_def

%type <ir> partition_clause

%type <ir> mi_repair_type mi_repair_types opt_mi_repair_types
        mi_check_type mi_check_types opt_mi_check_types

%type <ir> opt_restrict;

%type <ir> table_list opt_table_list

%type <ir> ternary_option;

%type <ir> create_table_option

%type <ir> create_table_options

%type <ir> create_table_options_space_separated

%type <ir> duplicate opt_duplicate

%type <ir> column_attribute

%type <ir> column_format

%type <ir> storage_media

%type <ir> column_attribute_list opt_column_attribute_list

%type <ir> opt_stored_attribute

%type <ir> field_option field_opt_list field_options

%type <ir> int_type

%type <ir> spatial_type type

%type <ir> real_type numeric_type

%type <ir> sp_opt_default

%type <ir> field_def

%type <ir> check_constraint

%type <ir> opt_references

%type <ir> opt_on_update_delete

%type <ir> opt_match_clause

%type <ir> reference_list opt_ref_list

%type <ir> references

%type <ir> column_def

%type <ir> table_element

%type <ir> table_element_list

%type <ir> opt_create_table_options_etc
        opt_create_partitioning_etc opt_duplicate_as_qe

%type <ir> opt_wild_or_where

// used by JSON_TABLE
%type <ir> columns_clause columns_list
%type <ir> jt_column
%type <ir> json_on_response on_empty on_error
%type <ir> opt_on_empty_or_error
        opt_on_empty_or_error_json_table
%type <ir> jt_column_type

%type <ir> opt_acl_type
%type <ir> opt_histogram

%type <ir> column_list opt_column_list

%type <ir> role_or_privilege

%type <ir> role_or_privilege_list

%type <ir> with_validation opt_with_validation
/*%type <ir> ts_access_mode*/

%type <ir> alter_list_item alter_table_partition_options
%type <ir> logfile_group_option_list opt_logfile_group_options
                   alter_logfile_group_option_list opt_alter_logfile_group_options
                   tablespace_option_list opt_tablespace_options
                   alter_tablespace_option_list opt_alter_tablespace_options
                   opt_drop_ts_options drop_ts_option_list
                   undo_tablespace_option_list opt_undo_tablespace_options

%type <ir> standalone_alter_commands

%type <ir>alter_commands_modifier
        alter_commands_modifier_list

%type <ir> alter_list opt_alter_command_list opt_alter_table_actions

%type <ir> standalone_alter_table_action

%type <ir> assign_to_keycache

%type <ir> keycache_list

%type <ir> adm_partition

%type <ir> preload_keys

%type <ir> preload_list
%type <ir>
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

%type <ir> opt_explain_format_type
%type <ir> opt_explain_analyze_type

%type <ir> load_data_set_elem

%type <ir> load_data_set_list opt_load_data_set_spec

%type <ir> opt_array_cast
%type <ir> srs_attributes

%type <ir> opt_values_reference

%type <ir> undo_tablespace_state

%type <ir> opt_for_query


%type <ir> start_entry 

%type <ir> sql_statement 

%type <ir> opt_end_of_input 

%type <ir> simple_statement_or_begin 

%type <ir> deallocate 

%type <ir> deallocate_or_drop 

%type <ir> prepare 

%type <ir> prepare_src 

%type <ir> execute 

%type <ir> execute_using 

%type <ir> execute_var_list 

%type <ir> execute_var_ident 

%type <ir> help 

%type <ir> change_replication_source 

%type <ir> change 

%type <ir> filter_defs 

%type <ir> filter_def 

%type <ir> source_defs 

%type <ir> change_replication_source_auto_position 

%type <ir> change_replication_source_host 

%type <ir> change_replication_source_bind 

%type <ir> change_replication_source_user 

%type <ir> change_replication_source_password 

%type <ir> change_replication_source_port 

%type <ir> change_replication_source_connect_retry 

%type <ir> change_replication_source_retry_count 

%type <ir> change_replication_source_delay 

%type <ir> change_replication_source_ssl 

%type <ir> change_replication_source_ssl_ca 

%type <ir> change_replication_source_ssl_capath 

%type <ir> change_replication_source_ssl_cipher 

%type <ir> change_replication_source_ssl_crl 

%type <ir> change_replication_source_ssl_crlpath 

%type <ir> change_replication_source_ssl_key 

%type <ir> change_replication_source_ssl_verify_server_cert 

%type <ir> change_replication_source_tls_version 

%type <ir> change_replication_source_tls_ciphersuites 

%type <ir> change_replication_source_ssl_cert 

%type <ir> change_replication_source_public_key 

%type <ir> change_replication_source_get_source_public_key 

%type <ir> change_replication_source_heartbeat_period 

%type <ir> change_replication_source_compression_algorithm 

%type <ir> change_replication_source_zstd_compression_level 

%type <ir> source_def 

%type <ir> ignore_server_id_list 

%type <ir> ignore_server_id 

%type <ir> privilege_check_def 

%type <ir> table_primary_key_check_def 

%type <ir> assign_gtids_to_anonymous_transactions_def 

%type <ir> source_tls_ciphersuites_def 

%type <ir> source_log_file 

%type <ir> source_log_pos 

%type <ir> source_file_def 

%type <ir> create 

%type <ir> server_options_list 

%type <ir> server_option 

%type <ir> event_tail 

%type <ir> ev_schedule_time 

%type <ir> ev_starts 

%type <ir> ev_ends 

%type <ir> ev_sql_stmt 

%type <ir> ev_sql_stmt_inner 

%type <ir> sp_a_chistics 

%type <ir> sp_c_chistics 

%type <ir> sp_chistic 

%type <ir> sp_c_chistic 

%type <ir> sp_suid 

%type <ir> sp_fdparam_list 

%type <ir> sp_fdparams 

%type <ir> sp_fdparam 

%type <ir> sp_pdparam_list 

%type <ir> sp_pdparams 

%type <ir> sp_pdparam 

%type <ir> sp_proc_stmts 

%type <ir> sp_proc_stmts1 

%type <ir> sp_hcond_element 

%type <ir> opt_value 

%type <ir> signal_stmt 

%type <ir> resignal_stmt 

%type <ir> get_diagnostics 

%type <ir> sp_proc_stmt 

%type <ir> sp_proc_stmt_if 

%type <ir> sp_proc_stmt_statement 

%type <ir> sp_proc_stmt_return 

%type <ir> sp_proc_stmt_unlabeled 

%type <ir> sp_proc_stmt_leave 

%type <ir> sp_proc_stmt_iterate 

%type <ir> sp_proc_stmt_open 

%type <ir> sp_proc_stmt_fetch 

%type <ir> sp_proc_stmt_close 

%type <ir> sp_opt_fetch_noise 

%type <ir> sp_fetch_list 

%type <ir> sp_if 

%type <ir> sp_elseifs 

%type <ir> case_stmt_specification 

%type <ir> simple_case_stmt 

%type <ir> searched_case_stmt 

%type <ir> simple_when_clause_list 

%type <ir> searched_when_clause_list 

%type <ir> simple_when_clause 

%type <ir> searched_when_clause 

%type <ir> else_clause_opt 

%type <ir> sp_labeled_control 

%type <ir> sp_labeled_block 

%type <ir> sp_unlabeled_block 

%type <ir> sp_block_content 

%type <ir> sp_unlabeled_control 

%type <ir> alter_database_options 

%type <ir> alter_database_option 

%type <ir> opt_create_database_options 

%type <ir> create_database_options 

%type <ir> create_database_option 

%type <ir> opt_comma 

%type <ir> opt_generated_always 

%type <ir> nchar 

%type <ir> varchar 

%type <ir> nvarchar 

%type <ir> opt_PRECISION 

%type <ir> character_set 

%type <ir> opt_default 

%type <ir> opt_primary 

%type <ir> key_or_index 

%type <ir> opt_key_or_index 

%type <ir> keys_or_index 

%type <ir> alter_database_stmt 

%type <ir> alter_procedure_stmt 

%type <ir> alter_function_stmt 

%type <ir> alter_view_stmt 

%type <ir> alter_event_stmt 

%type <ir> alter_logfile_stmt 

%type <ir> alter_tablespace_stmt 

%type <ir> alter_undo_tablespace_stmt 

%type <ir> alter_server_stmt 

%type <ir> alter_user_stmt 

%type <ir> alter_user_command 

%type <ir> opt_user_attribute 

%type <ir> opt_account_lock_password_expire_options 

%type <ir> opt_account_lock_password_expire_option_list 

%type <ir> opt_account_lock_password_expire_option 

%type <ir> connect_options 

%type <ir> connect_option_list 

%type <ir> connect_option 

%type <ir> opt_column 

%type <ir> opt_to 

%type <ir> group_replication 

%type <ir> group_replication_start 

%type <ir> opt_group_replication_start_options 

%type <ir> group_replication_start_options 

%type <ir> group_replication_start_option 

%type <ir> group_replication_user 

%type <ir> group_replication_password 

%type <ir> group_replication_plugin_auth 

%type <ir> replica 

%type <ir> stop_replica_stmt 

%type <ir> start_replica_stmt 

%type <ir> start 

%type <ir> opt_user_option 

%type <ir> opt_password_option 

%type <ir> opt_default_auth_option 

%type <ir> opt_plugin_dir_option 

%type <ir> opt_replica_until 

%type <ir> replica_until 

%type <ir> checksum 

%type <ir> binlog_base64_event 

%type <ir> rename 

%type <ir> rename_list 

%type <ir> table_to_table_list 

%type <ir> table_to_table 

%type <ir> optional_braces 

%type <ir> opt_of 

%type <ir> or 

%type <ir> and 

%type <ir> not 

%type <ir> not2 

%type <ir> opt_inner 

%type <ir> opt_outer 

%type <ir> opt_as 

%type <ir> opt_all 

%type <ir> dec_num_error 

%type <ir> dec_num 

%type <ir> drop_table_stmt 

%type <ir> drop_database_stmt 

%type <ir> drop_function_stmt 

%type <ir> drop_procedure_stmt 

%type <ir> drop_user_stmt 

%type <ir> drop_view_stmt 

%type <ir> drop_event_stmt 

%type <ir> drop_trigger_stmt 

%type <ir> drop_tablespace_stmt 

%type <ir> drop_undo_tablespace_stmt 

%type <ir> drop_logfile_stmt 

%type <ir> drop_server_stmt 

%type <ir> opt_INTO 

%type <ir> value_or_values 

%type <ir> equal 

%type <ir> opt_equal 

%type <ir> opt_wild 

%type <ir> opt_table 

%type <ir> master_or_binary 

%type <ir> opt_storage 

%type <ir> from_or_in 

%type <ir> binlog_from 

%type <ir> describe_command 

%type <ir> flush 

%type <ir> flush_options 

%type <ir> opt_flush_lock 

%type <ir> flush_options_list 

%type <ir> flush_option 

%type <ir> reset 

%type <ir> reset_options 

%type <ir> opt_if_exists_ident 

%type <ir> reset_option 

%type <ir> opt_replica_reset_options 

%type <ir> source_reset_options 

%type <ir> purge 

%type <ir> purge_options 

%type <ir> purge_option 

%type <ir> kill 

%type <ir> kill_option 

%type <ir> use 

%type <ir> lines_or_rows 

%type <ir> lock 

%type <ir> table_or_tables 

%type <ir> table_lock_list 

%type <ir> table_lock 

%type <ir> unlock 

%type <ir> revoke 

%type <ir> grant 

%type <ir> opt_privileges 

%type <ir> opt_and 

%type <ir> require_list 

%type <ir> require_list_element 

%type <ir> grant_ident 

%type <ir> create_user_list 

%type <ir> alter_user_list 

%type <ir> require_clause 

%type <ir> grant_options 

%type <ir> opt_with_roles 

%type <ir> opt_grant_as 

%type <ir> begin_stmt 

%type <ir> opt_work 

%type <ir> opt_savepoint 

%type <ir> commit 

%type <ir> rollback 

%type <ir> savepoint 

%type <ir> release 

%type <ir> init_lex_create_info 

%type <ir> view_or_trigger_or_sp_or_event 

%type <ir> definer_tail 

%type <ir> no_definer_tail 

%type <ir> definer_opt 

%type <ir> no_definer 

%type <ir> definer 

%type <ir> view_replace_or_algorithm 

%type <ir> view_replace 

%type <ir> view_algorithm 

%type <ir> view_suid 

%type <ir> view_tail 

%type <ir> view_query_block 

%type <ir> trigger_tail 

%type <ir> udf_tail 

%type <ir> sf_tail 

%type <ir> sp_tail 

%type <ir> xa 

%type <ir> begin_or_start 

%type <ir> install 

%type <ir> uninstall 

%type <ir> import_stmt 

%type <ir> clone_stmt 

%type <ir> opt_ssl 


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

    sql_statement {
        auto tmp1 = $1;
        res = new IR(kStartEntry, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | GRAMMAR_SELECTOR_EXPR bit_expr END_OF_INPUT {
        auto tmp1 = $2;
        res = new IR(kStartEntry, OP3("GRAMMAR_SELECTOR_EXPR", "", ""), tmp1);
        $$ = res;
    }

    | GRAMMAR_SELECTOR_PART partition_clause END_OF_INPUT {
        auto tmp1 = $2;
        res = new IR(kStartEntry, OP3("GRAMMAR_SELECTOR_PART", "", ""), tmp1);
        $$ = res;
    }

    | GRAMMAR_SELECTOR_GCOL IDENT_sys '(' expr ')' END_OF_INPUT {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kStartEntry, OP3("GRAMMAR_SELECTOR_GCOL", "(", ")"), tmp1, tmp2);
        $$ = res;
        @1;
    }

    | GRAMMAR_SELECTOR_CTE table_subquery END_OF_INPUT {
        auto tmp1 = $2;
        res = new IR(kStartEntry, OP3("GRAMMAR_SELECTOR_CTE", "", ""), tmp1);
        $$ = res;
    }

    | GRAMMAR_SELECTOR_DERIVED_EXPR expr END_OF_INPUT {
        auto tmp1 = $2;
        res = new IR(kStartEntry, OP3("GRAMMAR_SELECTOR_DERIVED_EXPR", "", ""), tmp1);
        $$ = res;
    }

;


sql_statement:

    END_OF_INPUT {
        res = new IR(kSqlStatement, OP3("", "", ""));
        $$ = res;
    }

    | simple_statement_or_begin {} ';' opt_end_of_input {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kSqlStatement, OP3("", ";", ""), tmp1, tmp2);
        $$ = res;
    }

    | simple_statement_or_begin END_OF_INPUT {
        auto tmp1 = $1;
        res = new IR(kSqlStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_end_of_input:

    /* empty */ {
        res = new IR(kOptEndOfInput, OP3("", "", ""));
        $$ = res;
    }

    | END_OF_INPUT {
        res = new IR(kOptEndOfInput, OP3("", "", ""));
        $$ = res;
    }

;


simple_statement_or_begin:

    simple_statement {
        auto tmp1 = $1;
        res = new IR(kSimpleStatementOrBegin, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | begin_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatementOrBegin, OP3("", "", ""), tmp1);
        $$ = res;
    }

;

/* Verb clauses, except begin_stmt */

simple_statement:

    alter_database_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | alter_event_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | alter_function_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | alter_instance_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | alter_logfile_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | alter_procedure_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | alter_resource_group_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | alter_server_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | alter_tablespace_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | alter_undo_tablespace_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | alter_table_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | alter_user_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | alter_view_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | analyze_table_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | binlog_base64_event {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | call_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | change {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | check_table_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | checksum {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | clone_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | commit {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | create {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | create_index_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | create_resource_group_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | create_role_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | create_srs_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | create_table_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | deallocate {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | delete_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | describe_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | do_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | drop_database_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | drop_event_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | drop_function_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | drop_index_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | drop_logfile_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | drop_procedure_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | drop_resource_group_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | drop_role_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | drop_server_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | drop_srs_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | drop_tablespace_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | drop_undo_tablespace_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | drop_table_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | drop_trigger_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | drop_user_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | drop_view_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | execute {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | explain_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | flush {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | get_diagnostics {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | group_replication {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | grant {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | handler_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | help {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | import_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | insert_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | install {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | kill {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | load_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | lock {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | optimize_table_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keycache_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | preload_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | prepare {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | purge {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | release {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | rename {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | repair_table_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | replace_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | reset {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | resignal_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | restart_server_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | revoke {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | rollback {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | savepoint {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | select_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | set {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | set_resource_group_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | set_role_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | show_binary_logs_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | show_binlog_events_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | show_character_set_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | show_collation_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | show_columns_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | show_count_errors_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | show_count_warnings_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | show_create_database_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | show_create_event_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | show_create_function_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | show_create_procedure_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | show_create_table_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | show_create_trigger_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | show_create_user_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | show_create_view_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | show_databases_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | show_engine_logs_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | show_engine_mutex_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | show_engine_status_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | show_engines_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | show_errors_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | show_events_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | show_function_code_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | show_function_status_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | show_grants_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | show_keys_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | show_master_status_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | show_open_tables_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | show_plugins_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | show_privileges_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | show_procedure_code_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | show_procedure_status_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | show_processlist_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | show_profile_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | show_profiles_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | show_relaylog_events_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | show_replica_status_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | show_replicas_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | show_status_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | show_table_status_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | show_tables_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | show_triggers_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | show_variables_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | show_warnings_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | shutdown_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | signal_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | start {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | start_replica_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | stop_replica_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | truncate_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | uninstall {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | unlock {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | update_stmt {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | use {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | xa {
        auto tmp1 = $1;
        res = new IR(kSimpleStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


deallocate:

    deallocate_or_drop PREPARE_SYM ident {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kDeallocate, OP3("", "PREPARE", ""), tmp1, tmp2);
        $$ = res;
    }

;


deallocate_or_drop:

    DEALLOCATE_SYM {
        res = new IR(kDeallocateOrDrop, OP3("DEALLOCATE", "", ""));
        $$ = res;
    }

    | DROP {
        res = new IR(kDeallocateOrDrop, OP3("DROP", "", ""));
        $$ = res;
    }

;


prepare:

    PREPARE_SYM ident FROM prepare_src {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kPrepare, OP3("PREPARE", "FROM", ""), tmp1, tmp2);
        $$ = res;
    }

;


prepare_src:

    TEXT_STRING_sys {
        auto tmp1 = $1;
        res = new IR(kPrepareSrc, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '@' ident_or_text {
        auto tmp1 = $2;
        res = new IR(kPrepareSrc, OP3("@", "", ""), tmp1);
        $$ = res;
    }

;


execute:

    EXECUTE_SYM ident {} execute_using {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kExecute, OP3("EXECUTE", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


execute_using:

    /* nothing */ {
        res = new IR(kExecuteUsing, OP3("", "", ""));
        $$ = res;
    }

    | USING execute_var_list {
        auto tmp1 = $2;
        res = new IR(kExecuteUsing, OP3("USING", "", ""), tmp1);
        $$ = res;
    }

;


execute_var_list:

    execute_var_list ',' execute_var_ident {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kExecuteVarList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | execute_var_ident {
        auto tmp1 = $1;
        res = new IR(kExecuteVarList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


execute_var_ident:

    '@' ident_or_text {
        auto tmp1 = $2;
        res = new IR(kExecuteVarIdent, OP3("@", "", ""), tmp1);
        $$ = res;
    }

;

/* help */


help:

    HELP_SYM {} ident_or_text {
        auto tmp1 = $3;
        res = new IR(kHelp, OP3("HELP", "", ""), tmp1);
        $$ = res;
    }

;

/* change master */


change_replication_source:

    MASTER_SYM {
        res = new IR(kChangeReplicationSource, OP3("MASTER", "", ""));
        $$ = res;
    }

    | REPLICATION SOURCE_SYM {
        res = new IR(kChangeReplicationSource, OP3("REPLICATION SOURCE", "", ""));
        $$ = res;
    }

;


change:

    CHANGE change_replication_source TO_SYM {} source_defs opt_channel {
        auto tmp1 = $2;
        auto tmp2 = $5;
        res = new IR(kChange_1, OP3("CHANGE", "TO", ""), tmp1, tmp2);

        auto tmp3 = $6;
        res = new IR(kChange, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | CHANGE REPLICATION FILTER_SYM {} filter_defs opt_channel {
        auto tmp1 = $5;
        auto tmp2 = $6;
        res = new IR(kChange, OP3("CHANGE REPLICATION FILTER", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


filter_defs:

    filter_def {
        auto tmp1 = $1;
        res = new IR(kFilterDefs, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | filter_defs ',' filter_def {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kFilterDefs, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;

filter_def:

    REPLICATE_DO_DB EQ opt_filter_db_list {
        auto tmp1 = $3;
        res = new IR(kFilterDef, OP3("REPLICATE_DO_DB =", "", ""), tmp1);
        $$ = res;
    }

    | REPLICATE_IGNORE_DB EQ opt_filter_db_list {
        auto tmp1 = $3;
        res = new IR(kFilterDef, OP3("REPLICATE_IGNORE_DB =", "", ""), tmp1);
        $$ = res;
    }

    | REPLICATE_DO_TABLE EQ opt_filter_table_list {
        auto tmp1 = $3;
        res = new IR(kFilterDef, OP3("REPLICATE_DO_TABLE =", "", ""), tmp1);
        $$ = res;
    }

    | REPLICATE_IGNORE_TABLE EQ opt_filter_table_list {
        auto tmp1 = $3;
        res = new IR(kFilterDef, OP3("REPLICATE_IGNORE_TABLE =", "", ""), tmp1);
        $$ = res;
    }

    | REPLICATE_WILD_DO_TABLE EQ opt_filter_string_list {
        auto tmp1 = $3;
        res = new IR(kFilterDef, OP3("REPLICATE_WILD_DO_TABLE =", "", ""), tmp1);
        $$ = res;
    }

    | REPLICATE_WILD_IGNORE_TABLE EQ opt_filter_string_list {
        auto tmp1 = $3;
        res = new IR(kFilterDef, OP3("REPLICATE_WILD_IGNORE_TABLE =", "", ""), tmp1);
        $$ = res;
    }

    | REPLICATE_REWRITE_DB EQ opt_filter_db_pair_list {
        auto tmp1 = $3;
        res = new IR(kFilterDef, OP3("REPLICATE_REWRITE_DB =", "", ""), tmp1);
        $$ = res;
    }

;

opt_filter_db_list:

    '(' ')' {
        res = new IR(kOptFilterDbList, OP3("( )", "", ""));
        $$ = res;
    }

    | '(' filter_db_list ')' {
        auto tmp1 = $2;
        res = new IR(kOptFilterDbList, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

;


filter_db_list:

    filter_db_ident {
        auto tmp1 = $1;
        res = new IR(kFilterDbList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | filter_db_list ',' filter_db_ident {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kFilterDbList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


filter_db_ident:

    ident {
        auto tmp1 = $1;
        res = new IR(kFilterDbIdent, OP3("", "", ""), tmp1);
        $$ = res;
    }

;

opt_filter_db_pair_list:

    '(' ')' {
        res = new IR(kOptFilterDbPairList, OP3("( )", "", ""));
        $$ = res;
    }

    | '(' filter_db_pair_list ')' {
        auto tmp1 = $2;
        res = new IR(kOptFilterDbPairList, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

;

filter_db_pair_list:

    '(' filter_db_ident ',' filter_db_ident ')' {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kFilterDbPairList, OP3("(", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

    | filter_db_pair_list ',' '(' filter_db_ident ',' filter_db_ident ')' {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kFilterDbPairList_1, OP3("", ", (", ","), tmp1, tmp2);

        auto tmp3 = $6;
        res = new IR(kFilterDbPairList, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

;

opt_filter_table_list:

    '(' ')' {
        res = new IR(kOptFilterTableList, OP3("( )", "", ""));
        $$ = res;
    }

    | '(' filter_table_list ')' {
        auto tmp1 = $2;
        res = new IR(kOptFilterTableList, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

;


filter_table_list:

    filter_table_ident {
        auto tmp1 = $1;
        res = new IR(kFilterTableList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | filter_table_list ',' filter_table_ident {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kFilterTableList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


filter_table_ident:

    schema '.' ident {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kFilterTableIdent, OP3("", ".", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_filter_string_list:

    '(' ')' {
        res = new IR(kOptFilterStringList, OP3("( )", "", ""));
        $$ = res;
    }

    | '(' filter_string_list ')' {
        auto tmp1 = $2;
        res = new IR(kOptFilterStringList, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

;


filter_string_list:

    filter_string {
        auto tmp1 = $1;
        res = new IR(kFilterStringList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | filter_string_list ',' filter_string {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kFilterStringList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


filter_string:

    filter_wild_db_table_string {
        auto tmp1 = $1;
        res = new IR(kFilterString, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


source_defs:

    source_def {
        auto tmp1 = $1;
        res = new IR(kSourceDefs, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | source_defs ',' source_def {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSourceDefs, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


change_replication_source_auto_position:

    MASTER_AUTO_POSITION_SYM {
        res = new IR(kChangeReplicationSourceAutoPosition, OP3("MASTER_AUTO_POSITION", "", ""));
        $$ = res;
    }

    | SOURCE_AUTO_POSITION_SYM {
        res = new IR(kChangeReplicationSourceAutoPosition, OP3("SOURCE_AUTO_POSITION", "", ""));
        $$ = res;
    }

;


change_replication_source_host:

    MASTER_HOST_SYM {
        res = new IR(kChangeReplicationSourceHost, OP3("MASTER_HOST", "", ""));
        $$ = res;
    }

    | SOURCE_HOST_SYM {
        res = new IR(kChangeReplicationSourceHost, OP3("SOURCE_HOST", "", ""));
        $$ = res;
    }

;


change_replication_source_bind:

    MASTER_BIND_SYM {
        res = new IR(kChangeReplicationSourceBind, OP3("MASTER_BIND", "", ""));
        $$ = res;
    }

    | SOURCE_BIND_SYM {
        res = new IR(kChangeReplicationSourceBind, OP3("SOURCE_BIND", "", ""));
        $$ = res;
    }

;


change_replication_source_user:

    MASTER_USER_SYM {
        res = new IR(kChangeReplicationSourceUser, OP3("MASTER_USER", "", ""));
        $$ = res;
    }

    | SOURCE_USER_SYM {
        res = new IR(kChangeReplicationSourceUser, OP3("SOURCE_USER", "", ""));
        $$ = res;
    }

;


change_replication_source_password:

    MASTER_PASSWORD_SYM {
        res = new IR(kChangeReplicationSourcePassword, OP3("MASTER_PASSWORD", "", ""));
        $$ = res;
    }

    | SOURCE_PASSWORD_SYM {
        res = new IR(kChangeReplicationSourcePassword, OP3("SOURCE_PASSWORD", "", ""));
        $$ = res;
    }

;


change_replication_source_port:

    MASTER_PORT_SYM {
        res = new IR(kChangeReplicationSourcePort, OP3("MASTER_PORT", "", ""));
        $$ = res;
    }

    | SOURCE_PORT_SYM {
        res = new IR(kChangeReplicationSourcePort, OP3("SOURCE_PORT", "", ""));
        $$ = res;
    }

;


change_replication_source_connect_retry:

    MASTER_CONNECT_RETRY_SYM {
        res = new IR(kChangeReplicationSourceConnectRetry, OP3("MASTER_CONNECT_RETRY", "", ""));
        $$ = res;
    }

    | SOURCE_CONNECT_RETRY_SYM {
        res = new IR(kChangeReplicationSourceConnectRetry, OP3("SOURCE_CONNECT_RETRY", "", ""));
        $$ = res;
    }

;


change_replication_source_retry_count:

    MASTER_RETRY_COUNT_SYM {
        res = new IR(kChangeReplicationSourceRetryCount, OP3("MASTER_RETRY_COUNT", "", ""));
        $$ = res;
    }

    | SOURCE_RETRY_COUNT_SYM {
        res = new IR(kChangeReplicationSourceRetryCount, OP3("SOURCE_RETRY_COUNT", "", ""));
        $$ = res;
    }

;


change_replication_source_delay:

    MASTER_DELAY_SYM {
        res = new IR(kChangeReplicationSourceDelay, OP3("MASTER_DELAY", "", ""));
        $$ = res;
    }

    | SOURCE_DELAY_SYM {
        res = new IR(kChangeReplicationSourceDelay, OP3("SOURCE_DELAY", "", ""));
        $$ = res;
    }

;


change_replication_source_ssl:

    MASTER_SSL_SYM {
        res = new IR(kChangeReplicationSourceSsl, OP3("MASTER_SSL", "", ""));
        $$ = res;
    }

    | SOURCE_SSL_SYM {
        res = new IR(kChangeReplicationSourceSsl, OP3("SOURCE_SSL", "", ""));
        $$ = res;
    }

;


change_replication_source_ssl_ca:

    MASTER_SSL_CA_SYM {
        res = new IR(kChangeReplicationSourceSslCa, OP3("MASTER_SSL_CA", "", ""));
        $$ = res;
    }

    | SOURCE_SSL_CA_SYM {
        res = new IR(kChangeReplicationSourceSslCa, OP3("SOURCE_SSL_CA", "", ""));
        $$ = res;
    }

;


change_replication_source_ssl_capath:

    MASTER_SSL_CAPATH_SYM {
        res = new IR(kChangeReplicationSourceSslCapath, OP3("MASTER_SSL_CAPATH", "", ""));
        $$ = res;
    }

    | SOURCE_SSL_CAPATH_SYM {
        res = new IR(kChangeReplicationSourceSslCapath, OP3("SOURCE_SSL_CAPATH", "", ""));
        $$ = res;
    }

;


change_replication_source_ssl_cipher:

    MASTER_SSL_CIPHER_SYM {
        res = new IR(kChangeReplicationSourceSslCipher, OP3("MASTER_SSL_CIPHER", "", ""));
        $$ = res;
    }

    | SOURCE_SSL_CIPHER_SYM {
        res = new IR(kChangeReplicationSourceSslCipher, OP3("SOURCE_SSL_CIPHER", "", ""));
        $$ = res;
    }

;


change_replication_source_ssl_crl:

    MASTER_SSL_CRL_SYM {
        res = new IR(kChangeReplicationSourceSslCrl, OP3("MASTER_SSL_CRL", "", ""));
        $$ = res;
    }

    | SOURCE_SSL_CRL_SYM {
        res = new IR(kChangeReplicationSourceSslCrl, OP3("SOURCE_SSL_CRL", "", ""));
        $$ = res;
    }

;


change_replication_source_ssl_crlpath:

    MASTER_SSL_CRLPATH_SYM {
        res = new IR(kChangeReplicationSourceSslCrlpath, OP3("MASTER_SSL_CRLPATH", "", ""));
        $$ = res;
    }

    | SOURCE_SSL_CRLPATH_SYM {
        res = new IR(kChangeReplicationSourceSslCrlpath, OP3("SOURCE_SSL_CRLPATH", "", ""));
        $$ = res;
    }

;


change_replication_source_ssl_key:

    MASTER_SSL_KEY_SYM {
        res = new IR(kChangeReplicationSourceSslKey, OP3("MASTER_SSL_KEY", "", ""));
        $$ = res;
    }

    | SOURCE_SSL_KEY_SYM {
        res = new IR(kChangeReplicationSourceSslKey, OP3("SOURCE_SSL_KEY", "", ""));
        $$ = res;
    }

;


change_replication_source_ssl_verify_server_cert:

    MASTER_SSL_VERIFY_SERVER_CERT_SYM {
        res = new IR(kChangeReplicationSourceSslVerifyServerCert, OP3("MASTER_SSL_VERIFY_SERVER_CERT", "", ""));
        $$ = res;
    }

    | SOURCE_SSL_VERIFY_SERVER_CERT_SYM {
        res = new IR(kChangeReplicationSourceSslVerifyServerCert, OP3("SOURCE_SSL_VERIFY_SERVER_CERT", "", ""));
        $$ = res;
    }

;


change_replication_source_tls_version:

    MASTER_TLS_VERSION_SYM {
        res = new IR(kChangeReplicationSourceTlsVersion, OP3("MASTER_TLS_VERSION", "", ""));
        $$ = res;
    }

    | SOURCE_TLS_VERSION_SYM {
        res = new IR(kChangeReplicationSourceTlsVersion, OP3("SOURCE_TLS_VERSION", "", ""));
        $$ = res;
    }

;


change_replication_source_tls_ciphersuites:

    MASTER_TLS_CIPHERSUITES_SYM {
        res = new IR(kChangeReplicationSourceTlsCiphersuites, OP3("MASTER_TLS_CIPHERSUITES", "", ""));
        $$ = res;
    }

    | SOURCE_TLS_CIPHERSUITES_SYM {
        res = new IR(kChangeReplicationSourceTlsCiphersuites, OP3("SOURCE_TLS_CIPHERSUITES", "", ""));
        $$ = res;
    }

;


change_replication_source_ssl_cert:

    MASTER_SSL_CERT_SYM {
        res = new IR(kChangeReplicationSourceSslCert, OP3("MASTER_SSL_CERT", "", ""));
        $$ = res;
    }

    | SOURCE_SSL_CERT_SYM {
        res = new IR(kChangeReplicationSourceSslCert, OP3("SOURCE_SSL_CERT", "", ""));
        $$ = res;
    }

;


change_replication_source_public_key:

    MASTER_PUBLIC_KEY_PATH_SYM {
        res = new IR(kChangeReplicationSourcePublicKey, OP3("MASTER_PUBLIC_KEY_PATH", "", ""));
        $$ = res;
    }

    | SOURCE_PUBLIC_KEY_PATH_SYM {
        res = new IR(kChangeReplicationSourcePublicKey, OP3("SOURCE_PUBLIC_KEY_PATH", "", ""));
        $$ = res;
    }

;


change_replication_source_get_source_public_key:

    GET_MASTER_PUBLIC_KEY_SYM {
        res = new IR(kChangeReplicationSourceGetSourcePublicKey, OP3("GET_MASTER_PUBLIC_KEY", "", ""));
        $$ = res;
    }

    | GET_SOURCE_PUBLIC_KEY_SYM {
        res = new IR(kChangeReplicationSourceGetSourcePublicKey, OP3("GET_SOURCE_PUBLIC_KEY", "", ""));
        $$ = res;
    }

;


change_replication_source_heartbeat_period:

    MASTER_HEARTBEAT_PERIOD_SYM {
        res = new IR(kChangeReplicationSourceHeartbeatPeriod, OP3("MASTER_HEARTBEAT_PERIOD", "", ""));
        $$ = res;
    }

    | SOURCE_HEARTBEAT_PERIOD_SYM {
        res = new IR(kChangeReplicationSourceHeartbeatPeriod, OP3("SOURCE_HEARTBEAT_PERIOD", "", ""));
        $$ = res;
    }

;


change_replication_source_compression_algorithm:

    MASTER_COMPRESSION_ALGORITHM_SYM {
        res = new IR(kChangeReplicationSourceCompressionAlgorithm, OP3("MASTER_COMPRESSION_ALGORITHMS", "", ""));
        $$ = res;
    }

    | SOURCE_COMPRESSION_ALGORITHM_SYM {
        res = new IR(kChangeReplicationSourceCompressionAlgorithm, OP3("SOURCE_COMPRESSION_ALGORITHMS", "", ""));
        $$ = res;
    }

;


change_replication_source_zstd_compression_level:

    MASTER_ZSTD_COMPRESSION_LEVEL_SYM {
        res = new IR(kChangeReplicationSourceZstdCompressionLevel, OP3("MASTER_ZSTD_COMPRESSION_LEVEL", "", ""));
        $$ = res;
    }

    | SOURCE_ZSTD_COMPRESSION_LEVEL_SYM {
        res = new IR(kChangeReplicationSourceZstdCompressionLevel, OP3("SOURCE_ZSTD_COMPRESSION_LEVEL", "", ""));
        $$ = res;
    }

;


source_def:

    change_replication_source_host EQ TEXT_STRING_sys_nonewline {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSourceDef, OP3("", "=", ""), tmp1, tmp2);
        $$ = res;
    }

    | NETWORK_NAMESPACE_SYM EQ TEXT_STRING_sys_nonewline {
        auto tmp1 = $3;
        res = new IR(kSourceDef, OP3("NETWORK_NAMESPACE =", "", ""), tmp1);
        $$ = res;
    }

    | change_replication_source_bind EQ TEXT_STRING_sys_nonewline {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSourceDef, OP3("", "=", ""), tmp1, tmp2);
        $$ = res;
    }

    | change_replication_source_user EQ TEXT_STRING_sys_nonewline {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSourceDef, OP3("", "=", ""), tmp1, tmp2);
        $$ = res;
    }

    | change_replication_source_password EQ TEXT_STRING_sys_nonewline {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSourceDef, OP3("", "=", ""), tmp1, tmp2);
        $$ = res;
    }

    | change_replication_source_port EQ ulong_num {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSourceDef, OP3("", "=", ""), tmp1, tmp2);
        $$ = res;
    }

    | change_replication_source_connect_retry EQ ulong_num {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSourceDef, OP3("", "=", ""), tmp1, tmp2);
        $$ = res;
    }

    | change_replication_source_retry_count EQ ulong_num {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSourceDef, OP3("", "=", ""), tmp1, tmp2);
        $$ = res;
    }

    | change_replication_source_delay EQ ulong_num {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSourceDef, OP3("", "=", ""), tmp1, tmp2);
        $$ = res;
    }

    | change_replication_source_ssl EQ ulong_num {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSourceDef, OP3("", "=", ""), tmp1, tmp2);
        $$ = res;
    }

    | change_replication_source_ssl_ca EQ TEXT_STRING_sys_nonewline {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSourceDef, OP3("", "=", ""), tmp1, tmp2);
        $$ = res;
    }

    | change_replication_source_ssl_capath EQ TEXT_STRING_sys_nonewline {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSourceDef, OP3("", "=", ""), tmp1, tmp2);
        $$ = res;
    }

    | change_replication_source_tls_version EQ TEXT_STRING_sys_nonewline {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSourceDef, OP3("", "=", ""), tmp1, tmp2);
        $$ = res;
    }

    | change_replication_source_tls_ciphersuites EQ source_tls_ciphersuites_def {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSourceDef, OP3("", "=", ""), tmp1, tmp2);
        $$ = res;
    }

    | change_replication_source_ssl_cert EQ TEXT_STRING_sys_nonewline {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSourceDef, OP3("", "=", ""), tmp1, tmp2);
        $$ = res;
    }

    | change_replication_source_ssl_cipher EQ TEXT_STRING_sys_nonewline {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSourceDef, OP3("", "=", ""), tmp1, tmp2);
        $$ = res;
    }

    | change_replication_source_ssl_key EQ TEXT_STRING_sys_nonewline {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSourceDef, OP3("", "=", ""), tmp1, tmp2);
        $$ = res;
    }

    | change_replication_source_ssl_verify_server_cert EQ ulong_num {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSourceDef, OP3("", "=", ""), tmp1, tmp2);
        $$ = res;
    }

    | change_replication_source_ssl_crl EQ TEXT_STRING_sys_nonewline {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSourceDef, OP3("", "=", ""), tmp1, tmp2);
        $$ = res;
    }

    | change_replication_source_ssl_crlpath EQ TEXT_STRING_sys_nonewline {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSourceDef, OP3("", "=", ""), tmp1, tmp2);
        $$ = res;
    }

    | change_replication_source_public_key EQ TEXT_STRING_sys_nonewline {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSourceDef, OP3("", "=", ""), tmp1, tmp2);
        $$ = res;
    }

    | change_replication_source_get_source_public_key EQ ulong_num {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSourceDef, OP3("", "=", ""), tmp1, tmp2);
        $$ = res;
    }

    | change_replication_source_heartbeat_period EQ NUM_literal {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSourceDef, OP3("", "=", ""), tmp1, tmp2);
        $$ = res;
    }

    | IGNORE_SERVER_IDS_SYM EQ '(' ignore_server_id_list ')' {
        auto tmp1 = $4;
        res = new IR(kSourceDef, OP3("IGNORE_SERVER_IDS = (", ")", ""), tmp1);
        $$ = res;
    }

    | change_replication_source_compression_algorithm EQ TEXT_STRING_sys {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSourceDef, OP3("", "=", ""), tmp1, tmp2);
        $$ = res;
    }

    | change_replication_source_zstd_compression_level EQ ulong_num {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSourceDef, OP3("", "=", ""), tmp1, tmp2);
        $$ = res;
    }

    | change_replication_source_auto_position EQ ulong_num {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSourceDef, OP3("", "=", ""), tmp1, tmp2);
        $$ = res;
    }

    | PRIVILEGE_CHECKS_USER_SYM EQ privilege_check_def {
        auto tmp1 = $3;
        res = new IR(kSourceDef, OP3("PRIVILEGE_CHECKS_USER =", "", ""), tmp1);
        $$ = res;
    }

    | REQUIRE_ROW_FORMAT_SYM EQ ulong_num {
        auto tmp1 = $3;
        res = new IR(kSourceDef, OP3("REQUIRE_ROW_FORMAT =", "", ""), tmp1);
        $$ = res;
    }

    | REQUIRE_TABLE_PRIMARY_KEY_CHECK_SYM EQ table_primary_key_check_def {
        auto tmp1 = $3;
        res = new IR(kSourceDef, OP3("REQUIRE_TABLE_PRIMARY_KEY_CHECK =", "", ""), tmp1);
        $$ = res;
    }

    | SOURCE_CONNECTION_AUTO_FAILOVER_SYM EQ real_ulong_num {
        auto tmp1 = $3;
        res = new IR(kSourceDef, OP3("SOURCE_CONNECTION_AUTO_FAILOVER =", "", ""), tmp1);
        $$ = res;
    }

    | ASSIGN_GTIDS_TO_ANONYMOUS_TRANSACTIONS_SYM EQ assign_gtids_to_anonymous_transactions_def {
        auto tmp1 = $3;
        res = new IR(kSourceDef, OP3("ASSIGN_GTIDS_TO_ANONYMOUS_TRANSACTIONS =", "", ""), tmp1);
        $$ = res;
    }

    | GTID_ONLY_SYM EQ real_ulong_num {
        auto tmp1 = $3;
        res = new IR(kSourceDef, OP3("GTID_ONLY =", "", ""), tmp1);
        $$ = res;
    }

    | source_file_def {
        auto tmp1 = $1;
        res = new IR(kSourceDef, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


ignore_server_id_list:

    /* Empty */ {
        res = new IR(kIgnoreServerIdList, OP3("", "", ""));
        $$ = res;
    }

    | ignore_server_id {
        auto tmp1 = $1;
        res = new IR(kIgnoreServerIdList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ignore_server_id_list ',' ignore_server_id {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kIgnoreServerIdList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


ignore_server_id:

    ulong_num {
        auto tmp1 = $1;
        res = new IR(kIgnoreServerId, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


privilege_check_def:

    user_ident_or_text {
        auto tmp1 = $1;
        res = new IR(kPrivilegeCheckDef, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | NULL_SYM {
        res = new IR(kPrivilegeCheckDef, OP3("NULL", "", ""));
        $$ = res;
    }

;


table_primary_key_check_def:

    STREAM_SYM {
        res = new IR(kTablePrimaryKeyCheckDef, OP3("STREAM", "", ""));
        $$ = res;
    }

    | ON_SYM {
        res = new IR(kTablePrimaryKeyCheckDef, OP3("ON", "", ""));
        $$ = res;
    }

    | OFF_SYM {
        res = new IR(kTablePrimaryKeyCheckDef, OP3("OFF", "", ""));
        $$ = res;
    }

;


assign_gtids_to_anonymous_transactions_def:

    OFF_SYM {
        res = new IR(kAssignGtidsToAnonymousTransactionsDef, OP3("OFF", "", ""));
        $$ = res;
    }

    | LOCAL_SYM {
        res = new IR(kAssignGtidsToAnonymousTransactionsDef, OP3("LOCAL", "", ""));
        $$ = res;
    }

    | TEXT_STRING {
        res = new IR(kAssignGtidsToAnonymousTransactionsDef, OP3("TEXT_STRING", "", ""));
        $$ = res;
    }

;



source_tls_ciphersuites_def:

    TEXT_STRING_sys_nonewline {
        auto tmp1 = $1;
        res = new IR(kSourceTlsCiphersuitesDef, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | NULL_SYM {
        res = new IR(kSourceTlsCiphersuitesDef, OP3("NULL", "", ""));
        $$ = res;
    }

;


source_log_file:

    MASTER_LOG_FILE_SYM {
        res = new IR(kSourceLogFile, OP3("MASTER_LOG_FILE", "", ""));
        $$ = res;
    }

    | SOURCE_LOG_FILE_SYM {
        res = new IR(kSourceLogFile, OP3("SOURCE_LOG_FILE", "", ""));
        $$ = res;
    }

;


source_log_pos:

    MASTER_LOG_POS_SYM {
        res = new IR(kSourceLogPos, OP3("MASTER_LOG_POS", "", ""));
        $$ = res;
    }

    | SOURCE_LOG_POS_SYM {
        res = new IR(kSourceLogPos, OP3("SOURCE_LOG_POS", "", ""));
        $$ = res;
    }

;


source_file_def:

    source_log_file EQ TEXT_STRING_sys_nonewline {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSourceFileDef, OP3("", "=", ""), tmp1, tmp2);
        $$ = res;
    }

    | source_log_pos EQ ulonglong_num {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSourceFileDef, OP3("", "=", ""), tmp1, tmp2);
        $$ = res;
    }

    | RELAY_LOG_FILE_SYM EQ TEXT_STRING_sys_nonewline {
        auto tmp1 = $3;
        res = new IR(kSourceFileDef, OP3("RELAY_LOG_FILE =", "", ""), tmp1);
        $$ = res;
    }

    | RELAY_LOG_POS_SYM EQ ulong_num {
        auto tmp1 = $3;
        res = new IR(kSourceFileDef, OP3("RELAY_LOG_POS =", "", ""), tmp1);
        $$ = res;
    }

;


opt_channel:

    /*empty */ {
        res = new IR(kOptChannel, OP3("", "", ""));
        $$ = res;
    }

    | FOR_SYM CHANNEL_SYM TEXT_STRING_sys_nonewline {
        auto tmp1 = $3;
        res = new IR(kOptChannel, OP3("FOR CHANNEL", "", ""), tmp1);
        $$ = res;
    }

;


create_table_stmt:

    CREATE opt_temporary TABLE_SYM opt_if_not_exists table_ident '(' table_element_list ')' opt_create_table_options_etc {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kCreateTableStmt_1, OP3("CREATE", "TABLE", ""), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kCreateTableStmt_2, OP3("", "", "("), res, tmp3);

        auto tmp4 = $7;
        res = new IR(kCreateTableStmt_3, OP3("", "", ")"), res, tmp4);

        auto tmp5 = $9;
        res = new IR(kCreateTableStmt, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

    | CREATE opt_temporary TABLE_SYM opt_if_not_exists table_ident opt_create_table_options_etc {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kCreateTableStmt_4, OP3("CREATE", "TABLE", ""), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kCreateTableStmt_5, OP3("", "", ""), res, tmp3);

        auto tmp4 = $6;
        res = new IR(kCreateTableStmt, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | CREATE opt_temporary TABLE_SYM opt_if_not_exists table_ident LIKE table_ident {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kCreateTableStmt_6, OP3("CREATE", "TABLE", ""), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kCreateTableStmt_7, OP3("", "", "LIKE"), res, tmp3);

        auto tmp4 = $7;
        res = new IR(kCreateTableStmt, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | CREATE opt_temporary TABLE_SYM opt_if_not_exists table_ident '(' LIKE table_ident ')' {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kCreateTableStmt_8, OP3("CREATE", "TABLE", ""), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kCreateTableStmt_9, OP3("", "", "( LIKE"), res, tmp3);

        auto tmp4 = $8;
        res = new IR(kCreateTableStmt, OP3("", "", ")"), res, tmp4);
        $$ = res;
    }

;


create_role_stmt:

    CREATE ROLE_SYM opt_if_not_exists role_list {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kCreateRoleStmt, OP3("CREATE ROLE", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


create_resource_group_stmt:

    CREATE RESOURCE_SYM GROUP_SYM ident TYPE_SYM opt_equal resource_group_types opt_resource_group_vcpu_list opt_resource_group_priority opt_resource_group_enable_disable {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kCreateResourceGroupStmt_1, OP3("CREATE RESOURCE GROUP", "TYPE", ""), tmp1, tmp2);

        auto tmp3 = $7;
        res = new IR(kCreateResourceGroupStmt_2, OP3("", "", ""), res, tmp3);

        auto tmp4 = $8;
        res = new IR(kCreateResourceGroupStmt_3, OP3("", "", ""), res, tmp4);

        auto tmp5 = $9;
        res = new IR(kCreateResourceGroupStmt_4, OP3("", "", ""), res, tmp5);

        auto tmp6 = $10;
        res = new IR(kCreateResourceGroupStmt, OP3("", "", ""), res, tmp6);
        $$ = res;
    }

;


create:

    CREATE DATABASE opt_if_not_exists ident {} opt_create_database_options {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kCreate_1, OP3("CREATE DATABASE", "", ""), tmp1, tmp2);

        auto tmp3 = $6;
        res = new IR(kCreate, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | CREATE view_or_trigger_or_sp_or_event {
        auto tmp1 = $2;
        res = new IR(kCreate, OP3("CREATE", "", ""), tmp1);
        $$ = res;
    }

    | CREATE USER opt_if_not_exists create_user_list default_role_clause require_clause connect_options opt_account_lock_password_expire_options opt_user_attribute {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kCreate_2, OP3("CREATE USER", "", ""), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kCreate_3, OP3("", "", ""), res, tmp3);

        auto tmp4 = $6;
        res = new IR(kCreate_4, OP3("", "", ""), res, tmp4);

        auto tmp5 = $7;
        res = new IR(kCreate_5, OP3("", "", ""), res, tmp5);

        auto tmp6 = $8;
        res = new IR(kCreate_6, OP3("", "", ""), res, tmp6);

        auto tmp7 = $9;
        res = new IR(kCreate, OP3("", "", ""), res, tmp7);
        $$ = res;
    }

    | CREATE LOGFILE_SYM GROUP_SYM ident ADD lg_undofile opt_logfile_group_options {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kCreate_7, OP3("CREATE LOGFILE GROUP", "ADD", ""), tmp1, tmp2);

        auto tmp3 = $7;
        res = new IR(kCreate, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | CREATE TABLESPACE_SYM ident opt_ts_datafile_name opt_logfile_group_name opt_tablespace_options {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kCreate_8, OP3("CREATE TABLESPACE", "", ""), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kCreate_9, OP3("", "", ""), res, tmp3);

        auto tmp4 = $6;
        res = new IR(kCreate, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | CREATE UNDO_SYM TABLESPACE_SYM ident ADD ts_datafile opt_undo_tablespace_options {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kCreate_10, OP3("CREATE UNDO TABLESPACE", "ADD", ""), tmp1, tmp2);

        auto tmp3 = $7;
        res = new IR(kCreate, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | CREATE SERVER_SYM ident_or_text FOREIGN DATA_SYM WRAPPER_SYM ident_or_text OPTIONS_SYM '(' server_options_list ')' {
        auto tmp1 = $3;
        auto tmp2 = $7;
        res = new IR(kCreate_11, OP3("CREATE SERVER", "FOREIGN DATA WRAPPER", "OPTIONS ("), tmp1, tmp2);

        auto tmp3 = $10;
        res = new IR(kCreate, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

;


create_srs_stmt:

    CREATE OR_SYM REPLACE_SYM SPATIAL_SYM REFERENCE_SYM SYSTEM_SYM real_ulonglong_num srs_attributes {
        auto tmp1 = $7;
        auto tmp2 = $8;
        res = new IR(kCreateSrsStmt, OP3("CREATE OR REPLACE SPATIAL REFERENCE SYSTEM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | CREATE SPATIAL_SYM REFERENCE_SYM SYSTEM_SYM opt_if_not_exists real_ulonglong_num srs_attributes {
        auto tmp1 = $5;
        auto tmp2 = $6;
        res = new IR(kCreateSrsStmt_1, OP3("CREATE SPATIAL REFERENCE SYSTEM", "", ""), tmp1, tmp2);

        auto tmp3 = $7;
        res = new IR(kCreateSrsStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


srs_attributes:

    /* empty */ {
        res = new IR(kSrsAttributes, OP3("", "", ""));
        $$ = res;
    }

    | srs_attributes NAME_SYM TEXT_STRING_sys_nonewline {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSrsAttributes, OP3("", "NAME", ""), tmp1, tmp2);
        $$ = res;
    }

    | srs_attributes DEFINITION_SYM TEXT_STRING_sys_nonewline {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSrsAttributes, OP3("", "DEFINITION", ""), tmp1, tmp2);
        $$ = res;
    }

    | srs_attributes ORGANIZATION_SYM TEXT_STRING_sys_nonewline IDENTIFIED_SYM BY real_ulonglong_num {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSrsAttributes_1, OP3("", "ORGANIZATION", "IDENTIFIED BY"), tmp1, tmp2);

        auto tmp3 = $6;
        res = new IR(kSrsAttributes, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | srs_attributes DESCRIPTION_SYM TEXT_STRING_sys_nonewline {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSrsAttributes, OP3("", "DESCRIPTION", ""), tmp1, tmp2);
        $$ = res;
    }

;


default_role_clause:

    /* empty */ {
        res = new IR(kDefaultRoleClause, OP3("", "", ""));
        $$ = res;
    }

    | DEFAULT_SYM ROLE_SYM role_list {
        auto tmp1 = $3;
        res = new IR(kDefaultRoleClause, OP3("DEFAULT ROLE", "", ""), tmp1);
        $$ = res;
    }

;


create_index_stmt:

    CREATE opt_unique INDEX_SYM ident opt_index_type_clause ON_SYM table_ident '(' key_list_with_expression ')' opt_index_options opt_index_lock_and_algorithm {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kCreateIndexStmt_1, OP3("CREATE", "INDEX", ""), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kCreateIndexStmt_2, OP3("", "", "ON"), res, tmp3);

        auto tmp4 = $7;
        res = new IR(kCreateIndexStmt_3, OP3("", "", "("), res, tmp4);

        auto tmp5 = $9;
        res = new IR(kCreateIndexStmt_4, OP3("", "", ")"), res, tmp5);

        auto tmp6 = $11;
        res = new IR(kCreateIndexStmt_5, OP3("", "", ""), res, tmp6);

        auto tmp7 = $12;
        res = new IR(kCreateIndexStmt, OP3("", "", ""), res, tmp7);
        $$ = res;
    }

    | CREATE FULLTEXT_SYM INDEX_SYM ident ON_SYM table_ident '(' key_list_with_expression ')' opt_fulltext_index_options opt_index_lock_and_algorithm {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kCreateIndexStmt_6, OP3("CREATE FULLTEXT INDEX", "ON", "("), tmp1, tmp2);

        auto tmp3 = $8;
        res = new IR(kCreateIndexStmt_7, OP3("", "", ")"), res, tmp3);

        auto tmp4 = $10;
        res = new IR(kCreateIndexStmt_8, OP3("", "", ""), res, tmp4);

        auto tmp5 = $11;
        res = new IR(kCreateIndexStmt, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

    | CREATE SPATIAL_SYM INDEX_SYM ident ON_SYM table_ident '(' key_list_with_expression ')' opt_spatial_index_options opt_index_lock_and_algorithm {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kCreateIndexStmt_9, OP3("CREATE SPATIAL INDEX", "ON", "("), tmp1, tmp2);

        auto tmp3 = $8;
        res = new IR(kCreateIndexStmt_10, OP3("", "", ")"), res, tmp3);

        auto tmp4 = $10;
        res = new IR(kCreateIndexStmt_11, OP3("", "", ""), res, tmp4);

        auto tmp5 = $11;
        res = new IR(kCreateIndexStmt, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

;


server_options_list:

    server_option {
        auto tmp1 = $1;
        res = new IR(kServerOptionsList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | server_options_list ',' server_option {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kServerOptionsList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


server_option:

    USER TEXT_STRING_sys {
        auto tmp1 = $2;
        res = new IR(kServerOption, OP3("USER", "", ""), tmp1);
        $$ = res;
    }

    | HOST_SYM TEXT_STRING_sys {
        auto tmp1 = $2;
        res = new IR(kServerOption, OP3("HOST", "", ""), tmp1);
        $$ = res;
    }

    | DATABASE TEXT_STRING_sys {
        auto tmp1 = $2;
        res = new IR(kServerOption, OP3("DATABASE", "", ""), tmp1);
        $$ = res;
    }

    | OWNER_SYM TEXT_STRING_sys {
        auto tmp1 = $2;
        res = new IR(kServerOption, OP3("OWNER", "", ""), tmp1);
        $$ = res;
    }

    | PASSWORD TEXT_STRING_sys {
        auto tmp1 = $2;
        res = new IR(kServerOption, OP3("PASSWORD", "", ""), tmp1);
        $$ = res;
    }

    | SOCKET_SYM TEXT_STRING_sys {
        auto tmp1 = $2;
        res = new IR(kServerOption, OP3("SOCKET", "", ""), tmp1);
        $$ = res;
    }

    | PORT_SYM ulong_num {
        auto tmp1 = $2;
        res = new IR(kServerOption, OP3("PORT", "", ""), tmp1);
        $$ = res;
    }

;


event_tail:

    EVENT_SYM opt_if_not_exists sp_name {} ON_SYM SCHEDULE_SYM ev_schedule_time opt_ev_on_completion opt_ev_status opt_ev_comment DO_SYM ev_sql_stmt {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kEventTail_1, OP3("EVENT", "", "ON SCHEDULE"), tmp1, tmp2);

        auto tmp3 = $7;
        res = new IR(kEventTail_2, OP3("", "", ""), res, tmp3);

        auto tmp4 = $8;
        res = new IR(kEventTail_3, OP3("", "", ""), res, tmp4);

        auto tmp5 = $9;
        res = new IR(kEventTail_4, OP3("", "", ""), res, tmp5);

        auto tmp6 = $10;
        res = new IR(kEventTail_5, OP3("", "", "DO"), res, tmp6);

        auto tmp7 = $12;
        res = new IR(kEventTail, OP3("", "", ""), res, tmp7);
        $$ = res;
    }

;


ev_schedule_time:

    EVERY_SYM expr interval {} ev_starts ev_ends {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kEvScheduleTime_1, OP3("EVERY", "", ""), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kEvScheduleTime_2, OP3("", "", ""), res, tmp3);

        auto tmp4 = $6;
        res = new IR(kEvScheduleTime, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | AT_SYM expr {
        auto tmp1 = $2;
        res = new IR(kEvScheduleTime, OP3("AT", "", ""), tmp1);
        $$ = res;
    }

;


opt_ev_status:

    /* empty */ {
        res = new IR(kOptEvStatus, OP3("", "", ""));
        $$ = res;
    }

    | ENABLE_SYM {
        res = new IR(kOptEvStatus, OP3("ENABLE", "", ""));
        $$ = res;
    }

    | DISABLE_SYM ON_SYM SLAVE {
        res = new IR(kOptEvStatus, OP3("DISABLE ON SLAVE", "", ""));
        $$ = res;
    }

    | DISABLE_SYM {
        res = new IR(kOptEvStatus, OP3("DISABLE", "", ""));
        $$ = res;
    }

;


ev_starts:

    /* empty */ {
        res = new IR(kEvStarts, OP3("", "", ""));
        $$ = res;
    }

    | STARTS_SYM expr {
        auto tmp1 = $2;
        res = new IR(kEvStarts, OP3("STARTS", "", ""), tmp1);
        $$ = res;
    }

;


ev_ends:

    /* empty */ {
        res = new IR(kEvEnds, OP3("", "", ""));
        $$ = res;
    }

    | ENDS_SYM expr {
        auto tmp1 = $2;
        res = new IR(kEvEnds, OP3("ENDS", "", ""), tmp1);
        $$ = res;
    }

;


opt_ev_on_completion:

    /* empty */ {
        res = new IR(kOptEvOnCompletion, OP3("", "", ""));
        $$ = res;
    }

    | ev_on_completion {
        auto tmp1 = $1;
        res = new IR(kOptEvOnCompletion, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


ev_on_completion:

    ON_SYM COMPLETION_SYM PRESERVE_SYM {
        res = new IR(kEvOnCompletion, OP3("ON COMPLETION PRESERVE", "", ""));
        $$ = res;
    }

    | ON_SYM COMPLETION_SYM NOT_SYM PRESERVE_SYM {
        res = new IR(kEvOnCompletion, OP3("ON COMPLETION NOT PRESERVE", "", ""));
        $$ = res;
    }

;


opt_ev_comment:

    /* empty */ {
        res = new IR(kOptEvComment, OP3("", "", ""));
        $$ = res;
    }

    | COMMENT_SYM TEXT_STRING_sys {
        auto tmp1 = $2;
        res = new IR(kOptEvComment, OP3("COMMENT", "", ""), tmp1);
        $$ = res;
    }

;


ev_sql_stmt:

    {} ev_sql_stmt_inner {
        auto tmp1 = $2;
        res = new IR(kEvSqlStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


ev_sql_stmt_inner:

    sp_proc_stmt_statement {
        auto tmp1 = $1;
        res = new IR(kEvSqlStmtInner, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_proc_stmt_return {
        auto tmp1 = $1;
        res = new IR(kEvSqlStmtInner, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_proc_stmt_if {
        auto tmp1 = $1;
        res = new IR(kEvSqlStmtInner, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | case_stmt_specification {
        auto tmp1 = $1;
        res = new IR(kEvSqlStmtInner, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_labeled_block {
        auto tmp1 = $1;
        res = new IR(kEvSqlStmtInner, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_unlabeled_block {
        auto tmp1 = $1;
        res = new IR(kEvSqlStmtInner, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_labeled_control {
        auto tmp1 = $1;
        res = new IR(kEvSqlStmtInner, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_proc_stmt_unlabeled {
        auto tmp1 = $1;
        res = new IR(kEvSqlStmtInner, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_proc_stmt_leave {
        auto tmp1 = $1;
        res = new IR(kEvSqlStmtInner, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_proc_stmt_iterate {
        auto tmp1 = $1;
        res = new IR(kEvSqlStmtInner, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_proc_stmt_open {
        auto tmp1 = $1;
        res = new IR(kEvSqlStmtInner, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_proc_stmt_fetch {
        auto tmp1 = $1;
        res = new IR(kEvSqlStmtInner, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_proc_stmt_close {
        auto tmp1 = $1;
        res = new IR(kEvSqlStmtInner, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


sp_name:

    ident '.' ident {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSpName, OP3("", ".", ""), tmp1, tmp2);
        $$ = res;
    }

    | ident {
        auto tmp1 = $1;
        res = new IR(kSpName, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


sp_a_chistics:

    /* Empty */ {
        res = new IR(kSpAChistics, OP3("", "", ""));
        $$ = res;
    }

    | sp_a_chistics sp_chistic {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpAChistics, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


sp_c_chistics:

    /* Empty */ {
        res = new IR(kSpCChistics, OP3("", "", ""));
        $$ = res;
    }

    | sp_c_chistics sp_c_chistic {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpCChistics, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;

/* Characteristics for both create and alter */

sp_chistic:

    COMMENT_SYM TEXT_STRING_sys {
        auto tmp1 = $2;
        res = new IR(kSpChistic, OP3("COMMENT", "", ""), tmp1);
        $$ = res;
    }

    | LANGUAGE_SYM SQL_SYM {
        res = new IR(kSpChistic, OP3("LANGUAGE SQL", "", ""));
        $$ = res;
    }

    | NO_SYM SQL_SYM {
        res = new IR(kSpChistic, OP3("NO SQL", "", ""));
        $$ = res;
    }

    | CONTAINS_SYM SQL_SYM {
        res = new IR(kSpChistic, OP3("CONTAINS SQL", "", ""));
        $$ = res;
    }

    | READS_SYM SQL_SYM DATA_SYM {
        res = new IR(kSpChistic, OP3("READS SQL DATA", "", ""));
        $$ = res;
    }

    | MODIFIES_SYM SQL_SYM DATA_SYM {
        res = new IR(kSpChistic, OP3("MODIFIES SQL DATA", "", ""));
        $$ = res;
    }

    | sp_suid {
        auto tmp1 = $1;
        res = new IR(kSpChistic, OP3("", "", ""), tmp1);
        $$ = res;
    }

;

/* Create characteristics */

sp_c_chistic:

    sp_chistic {
        auto tmp1 = $1;
        res = new IR(kSpCChistic, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DETERMINISTIC_SYM {
        res = new IR(kSpCChistic, OP3("DETERMINISTIC", "", ""));
        $$ = res;
    }

    | not DETERMINISTIC_SYM {
        auto tmp1 = $1;
        res = new IR(kSpCChistic, OP3("", "DETERMINISTIC", ""), tmp1);
        $$ = res;
    }

;


sp_suid:

    SQL_SYM SECURITY_SYM DEFINER_SYM {
        res = new IR(kSpSuid, OP3("SQL SECURITY DEFINER", "", ""));
        $$ = res;
    }

    | SQL_SYM SECURITY_SYM INVOKER_SYM {
        res = new IR(kSpSuid, OP3("SQL SECURITY INVOKER", "", ""));
        $$ = res;
    }

;


call_stmt:

    CALL_SYM sp_name opt_paren_expr_list {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCallStmt, OP3("CALL", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_paren_expr_list:

    /* Empty */ {
        res = new IR(kOptParenExprList, OP3("", "", ""));
        $$ = res;
    }

    | '(' opt_expr_list ')' {
        auto tmp1 = $2;
        res = new IR(kOptParenExprList, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

;

/* Stored FUNCTION parameter declaration list */

sp_fdparam_list:

    /* Empty */ {
        res = new IR(kSpFdparamList, OP3("", "", ""));
        $$ = res;
    }

    | sp_fdparams {
        auto tmp1 = $1;
        res = new IR(kSpFdparamList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


sp_fdparams:

    sp_fdparams ',' sp_fdparam {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSpFdparams, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | sp_fdparam {
        auto tmp1 = $1;
        res = new IR(kSpFdparams, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


sp_fdparam:

    ident type opt_collate {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpFdparam_1, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kSpFdparam, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;

/* Stored PROCEDURE parameter declaration list */

sp_pdparam_list:

    /* Empty */ {
        res = new IR(kSpPdparamList, OP3("", "", ""));
        $$ = res;
    }

    | sp_pdparams {
        auto tmp1 = $1;
        res = new IR(kSpPdparamList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


sp_pdparams:

    sp_pdparams ',' sp_pdparam {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSpPdparams, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | sp_pdparam {
        auto tmp1 = $1;
        res = new IR(kSpPdparams, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


sp_pdparam:

    sp_opt_inout ident type opt_collate {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpPdparam_1, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kSpPdparam_2, OP3("", "", ""), res, tmp3);

        auto tmp4 = $4;
        res = new IR(kSpPdparam, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


sp_opt_inout:

    /* Empty */ {
        res = new IR(kSpOptInout, OP3("", "", ""));
        $$ = res;
    }

    | IN_SYM {
        res = new IR(kSpOptInout, OP3("IN", "", ""));
        $$ = res;
    }

    | OUT_SYM {
        res = new IR(kSpOptInout, OP3("OUT", "", ""));
        $$ = res;
    }

    | INOUT_SYM {
        res = new IR(kSpOptInout, OP3("INOUT", "", ""));
        $$ = res;
    }

;


sp_proc_stmts:

    /* Empty */ {
        res = new IR(kSpProcStmts, OP3("", "", ""));
        $$ = res;
    }

    | sp_proc_stmts sp_proc_stmt ';' {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpProcStmts, OP3("", "", ";"), tmp1, tmp2);
        $$ = res;
    }

;


sp_proc_stmts1:

    sp_proc_stmt ';' {
        auto tmp1 = $1;
        res = new IR(kSpProcStmts1, OP3("", ";", ""), tmp1);
        $$ = res;
    }

    | sp_proc_stmts1 sp_proc_stmt ';' {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpProcStmts1, OP3("", "", ";"), tmp1, tmp2);
        $$ = res;
    }

;


sp_decls:

    /* Empty */ {
        res = new IR(kSpDecls, OP3("", "", ""));
        $$ = res;
    }

    | sp_decls sp_decl ';' {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpDecls, OP3("", "", ";"), tmp1, tmp2);
        $$ = res;
    }

;


sp_decl:

    DECLARE_SYM sp_decl_idents type opt_collate sp_opt_default {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSpDecl_1, OP3("DECLARE", "", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kSpDecl_2, OP3("", "", ""), res, tmp3);

        auto tmp4 = $5;
        res = new IR(kSpDecl, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | DECLARE_SYM ident CONDITION_SYM FOR_SYM sp_cond {
        auto tmp1 = $2;
        auto tmp2 = $5;
        res = new IR(kSpDecl, OP3("DECLARE", "CONDITION FOR", ""), tmp1, tmp2);
        $$ = res;
    }

    | DECLARE_SYM sp_handler_type HANDLER_SYM FOR_SYM {} sp_hcond_list sp_proc_stmt {
        auto tmp1 = $2;
        auto tmp2 = $6;
        res = new IR(kSpDecl_3, OP3("DECLARE", "HANDLER FOR", ""), tmp1, tmp2);

        auto tmp3 = $7;
        res = new IR(kSpDecl, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | DECLARE_SYM ident CURSOR_SYM FOR_SYM {} select_stmt {
        auto tmp1 = $2;
        auto tmp2 = $6;
        res = new IR(kSpDecl, OP3("DECLARE", "CURSOR FOR", ""), tmp1, tmp2);
        $$ = res;
    }

;


sp_handler_type:

    EXIT_SYM {
        res = new IR(kSpHandlerType, OP3("EXIT", "", ""));
        $$ = res;
    }

    | CONTINUE_SYM {
        res = new IR(kSpHandlerType, OP3("CONTINUE", "", ""));
        $$ = res;
    }

;


sp_hcond_list:

    sp_hcond_element {
        auto tmp1 = $1;
        res = new IR(kSpHcondList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_hcond_list ',' sp_hcond_element {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSpHcondList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


sp_hcond_element:

    sp_hcond {
        auto tmp1 = $1;
        res = new IR(kSpHcondElement, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


sp_cond:

    ulong_num {
        auto tmp1 = $1;
        res = new IR(kSpCond, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sqlstate {
        auto tmp1 = $1;
        res = new IR(kSpCond, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


sqlstate:

    SQLSTATE_SYM opt_value TEXT_STRING_literal {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSqlstate, OP3("SQLSTATE", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_value:

    /* Empty */ {
        res = new IR(kOptValue, OP3("", "", ""));
        $$ = res;
    }

    | VALUE_SYM {
        res = new IR(kOptValue, OP3("VALUE", "", ""));
        $$ = res;
    }

;


sp_hcond:

    sp_cond {
        auto tmp1 = $1;
        res = new IR(kSpHcond, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ident {
        auto tmp1 = $1;
        res = new IR(kSpHcond, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | SQLWARNING_SYM {
        res = new IR(kSpHcond, OP3("SQLWARNING", "", ""));
        $$ = res;
    }

    | not FOUND_SYM {
        auto tmp1 = $1;
        res = new IR(kSpHcond, OP3("", "FOUND", ""), tmp1);
        $$ = res;
    }

    | SQLEXCEPTION_SYM {
        res = new IR(kSpHcond, OP3("SQLEXCEPTION", "", ""));
        $$ = res;
    }

;


signal_stmt:

    SIGNAL_SYM signal_value opt_set_signal_information {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSignalStmt, OP3("SIGNAL", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


signal_value:

    ident {
        auto tmp1 = $1;
        res = new IR(kSignalValue, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sqlstate {
        auto tmp1 = $1;
        res = new IR(kSignalValue, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_signal_value:

    /* empty */ {
        res = new IR(kOptSignalValue, OP3("", "", ""));
        $$ = res;
    }

    | signal_value {
        auto tmp1 = $1;
        res = new IR(kOptSignalValue, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_set_signal_information:

    /* empty */ {
        res = new IR(kOptSetSignalInformation, OP3("", "", ""));
        $$ = res;
    }

    | SET_SYM signal_information_item_list {
        auto tmp1 = $2;
        res = new IR(kOptSetSignalInformation, OP3("SET", "", ""), tmp1);
        $$ = res;
    }

;


signal_information_item_list:

    signal_condition_information_item_name EQ signal_allowed_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSignalInformationItemList, OP3("", "=", ""), tmp1, tmp2);
        $$ = res;
    }

    | signal_information_item_list ',' signal_condition_information_item_name EQ signal_allowed_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSignalInformationItemList_1, OP3("", ",", "="), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kSignalInformationItemList, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;

/*
Only a limited subset of <expr> are allowed in SIGNAL/RESIGNAL.
*/

signal_allowed_expr:

    literal_or_null {
        auto tmp1 = $1;
        res = new IR(kSignalAllowedExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | variable {
        auto tmp1 = $1;
        res = new IR(kSignalAllowedExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | simple_ident {
        auto tmp1 = $1;
        res = new IR(kSignalAllowedExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

;

/* conditions that can be set in signal / resignal */

signal_condition_information_item_name:

    CLASS_ORIGIN_SYM {
        res = new IR(kSignalConditionInformationItemName, OP3("CLASS_ORIGIN", "", ""));
        $$ = res;
    }

    | SUBCLASS_ORIGIN_SYM {
        res = new IR(kSignalConditionInformationItemName, OP3("SUBCLASS_ORIGIN", "", ""));
        $$ = res;
    }

    | CONSTRAINT_CATALOG_SYM {
        res = new IR(kSignalConditionInformationItemName, OP3("CONSTRAINT_CATALOG", "", ""));
        $$ = res;
    }

    | CONSTRAINT_SCHEMA_SYM {
        res = new IR(kSignalConditionInformationItemName, OP3("CONSTRAINT_SCHEMA", "", ""));
        $$ = res;
    }

    | CONSTRAINT_NAME_SYM {
        res = new IR(kSignalConditionInformationItemName, OP3("CONSTRAINT_NAME", "", ""));
        $$ = res;
    }

    | CATALOG_NAME_SYM {
        res = new IR(kSignalConditionInformationItemName, OP3("CATALOG_NAME", "", ""));
        $$ = res;
    }

    | SCHEMA_NAME_SYM {
        res = new IR(kSignalConditionInformationItemName, OP3("SCHEMA_NAME", "", ""));
        $$ = res;
    }

    | TABLE_NAME_SYM {
        res = new IR(kSignalConditionInformationItemName, OP3("TABLE_NAME", "", ""));
        $$ = res;
    }

    | COLUMN_NAME_SYM {
        res = new IR(kSignalConditionInformationItemName, OP3("COLUMN_NAME", "", ""));
        $$ = res;
    }

    | CURSOR_NAME_SYM {
        res = new IR(kSignalConditionInformationItemName, OP3("CURSOR_NAME", "", ""));
        $$ = res;
    }

    | MESSAGE_TEXT_SYM {
        res = new IR(kSignalConditionInformationItemName, OP3("MESSAGE_TEXT", "", ""));
        $$ = res;
    }

    | MYSQL_ERRNO_SYM {
        res = new IR(kSignalConditionInformationItemName, OP3("MYSQL_ERRNO", "", ""));
        $$ = res;
    }

;


resignal_stmt:

    RESIGNAL_SYM opt_signal_value opt_set_signal_information {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kResignalStmt, OP3("RESIGNAL", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


get_diagnostics:

    GET_SYM which_area DIAGNOSTICS_SYM diagnostics_information {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kGetDiagnostics, OP3("GET", "DIAGNOSTICS", ""), tmp1, tmp2);
        $$ = res;
    }

;


which_area:

    /* If <which area> is not specified, then CURRENT is implicit. */ {
        res = new IR(kWhichArea, OP3("", "", ""));
        $$ = res;
    }

    | CURRENT_SYM {
        res = new IR(kWhichArea, OP3("CURRENT", "", ""));
        $$ = res;
    }

    | STACKED_SYM {
        res = new IR(kWhichArea, OP3("STACKED", "", ""));
        $$ = res;
    }

;


diagnostics_information:

    statement_information {
        auto tmp1 = $1;
        res = new IR(kDiagnosticsInformation, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CONDITION_SYM condition_number condition_information {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kDiagnosticsInformation, OP3("CONDITION", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


statement_information:

    statement_information_item {
        auto tmp1 = $1;
        res = new IR(kStatementInformation, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | statement_information ',' statement_information_item {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kStatementInformation, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


statement_information_item:

    simple_target_specification EQ statement_information_item_name {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kStatementInformationItem, OP3("", "=", ""), tmp1, tmp2);
        $$ = res;
    }

;


simple_target_specification:

    ident {
        auto tmp1 = $1;
        res = new IR(kSimpleTargetSpecification, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '@' ident_or_text {
        auto tmp1 = $2;
        res = new IR(kSimpleTargetSpecification, OP3("@", "", ""), tmp1);
        $$ = res;
    }

;


statement_information_item_name:

    NUMBER_SYM {
        res = new IR(kStatementInformationItemName, OP3("NUMBER", "", ""));
        $$ = res;
    }

    | ROW_COUNT_SYM {
        res = new IR(kStatementInformationItemName, OP3("ROW_COUNT", "", ""));
        $$ = res;
    }

;

/*
Only a limited subset of <expr> are allowed in GET DIAGNOSTICS
<condition number>, same subset as for SIGNAL/RESIGNAL.
*/

condition_number:

    signal_allowed_expr {
        auto tmp1 = $1;
        res = new IR(kConditionNumber, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


condition_information:

    condition_information_item {
        auto tmp1 = $1;
        res = new IR(kConditionInformation, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | condition_information ',' condition_information_item {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kConditionInformation, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


condition_information_item:

    simple_target_specification EQ condition_information_item_name {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kConditionInformationItem, OP3("", "=", ""), tmp1, tmp2);
        $$ = res;
    }

;


condition_information_item_name:

    CLASS_ORIGIN_SYM {
        res = new IR(kConditionInformationItemName, OP3("CLASS_ORIGIN", "", ""));
        $$ = res;
    }

    | SUBCLASS_ORIGIN_SYM {
        res = new IR(kConditionInformationItemName, OP3("SUBCLASS_ORIGIN", "", ""));
        $$ = res;
    }

    | CONSTRAINT_CATALOG_SYM {
        res = new IR(kConditionInformationItemName, OP3("CONSTRAINT_CATALOG", "", ""));
        $$ = res;
    }

    | CONSTRAINT_SCHEMA_SYM {
        res = new IR(kConditionInformationItemName, OP3("CONSTRAINT_SCHEMA", "", ""));
        $$ = res;
    }

    | CONSTRAINT_NAME_SYM {
        res = new IR(kConditionInformationItemName, OP3("CONSTRAINT_NAME", "", ""));
        $$ = res;
    }

    | CATALOG_NAME_SYM {
        res = new IR(kConditionInformationItemName, OP3("CATALOG_NAME", "", ""));
        $$ = res;
    }

    | SCHEMA_NAME_SYM {
        res = new IR(kConditionInformationItemName, OP3("SCHEMA_NAME", "", ""));
        $$ = res;
    }

    | TABLE_NAME_SYM {
        res = new IR(kConditionInformationItemName, OP3("TABLE_NAME", "", ""));
        $$ = res;
    }

    | COLUMN_NAME_SYM {
        res = new IR(kConditionInformationItemName, OP3("COLUMN_NAME", "", ""));
        $$ = res;
    }

    | CURSOR_NAME_SYM {
        res = new IR(kConditionInformationItemName, OP3("CURSOR_NAME", "", ""));
        $$ = res;
    }

    | MESSAGE_TEXT_SYM {
        res = new IR(kConditionInformationItemName, OP3("MESSAGE_TEXT", "", ""));
        $$ = res;
    }

    | MYSQL_ERRNO_SYM {
        res = new IR(kConditionInformationItemName, OP3("MYSQL_ERRNO", "", ""));
        $$ = res;
    }

    | RETURNED_SQLSTATE_SYM {
        res = new IR(kConditionInformationItemName, OP3("RETURNED_SQLSTATE", "", ""));
        $$ = res;
    }

;


sp_decl_idents:

    ident {
        auto tmp1 = $1;
        res = new IR(kSpDeclIdents, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_decl_idents ',' ident {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSpDeclIdents, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


sp_opt_default:

    /* Empty */ {
        res = new IR(kSpOptDefault, OP3("", "", ""));
        $$ = res;
    }

    | DEFAULT_SYM expr {
        auto tmp1 = $2;
        res = new IR(kSpOptDefault, OP3("DEFAULT", "", ""), tmp1);
        $$ = res;
    }

;


sp_proc_stmt:

    sp_proc_stmt_statement {
        auto tmp1 = $1;
        res = new IR(kSpProcStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_proc_stmt_return {
        auto tmp1 = $1;
        res = new IR(kSpProcStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_proc_stmt_if {
        auto tmp1 = $1;
        res = new IR(kSpProcStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | case_stmt_specification {
        auto tmp1 = $1;
        res = new IR(kSpProcStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_labeled_block {
        auto tmp1 = $1;
        res = new IR(kSpProcStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_unlabeled_block {
        auto tmp1 = $1;
        res = new IR(kSpProcStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_labeled_control {
        auto tmp1 = $1;
        res = new IR(kSpProcStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_proc_stmt_unlabeled {
        auto tmp1 = $1;
        res = new IR(kSpProcStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_proc_stmt_leave {
        auto tmp1 = $1;
        res = new IR(kSpProcStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_proc_stmt_iterate {
        auto tmp1 = $1;
        res = new IR(kSpProcStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_proc_stmt_open {
        auto tmp1 = $1;
        res = new IR(kSpProcStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_proc_stmt_fetch {
        auto tmp1 = $1;
        res = new IR(kSpProcStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_proc_stmt_close {
        auto tmp1 = $1;
        res = new IR(kSpProcStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


sp_proc_stmt_if:

    IF {} sp_if END IF {
        auto tmp1 = $3;
        res = new IR(kSpProcStmtIf, OP3("IF", "END IF", ""), tmp1);
        $$ = res;
    }

;


sp_proc_stmt_statement:

    {} simple_statement {
        auto tmp1 = $2;
        res = new IR(kSpProcStmtStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


sp_proc_stmt_return:

    RETURN_SYM {} expr {
        auto tmp1 = $3;
        res = new IR(kSpProcStmtReturn, OP3("RETURN", "", ""), tmp1);
        $$ = res;
    }

;


sp_proc_stmt_unlabeled:

    {} sp_unlabeled_control {
        auto tmp1 = $2;
        res = new IR(kSpProcStmtUnlabeled, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


sp_proc_stmt_leave:

    LEAVE_SYM label_ident {
        auto tmp1 = $2;
        res = new IR(kSpProcStmtLeave, OP3("LEAVE", "", ""), tmp1);
        $$ = res;
    }

;


sp_proc_stmt_iterate:

    ITERATE_SYM label_ident {
        auto tmp1 = $2;
        res = new IR(kSpProcStmtIterate, OP3("ITERATE", "", ""), tmp1);
        $$ = res;
    }

;


sp_proc_stmt_open:

    OPEN_SYM ident {
        auto tmp1 = $2;
        res = new IR(kSpProcStmtOpen, OP3("OPEN", "", ""), tmp1);
        $$ = res;
    }

;


sp_proc_stmt_fetch:

    FETCH_SYM sp_opt_fetch_noise ident INTO {} sp_fetch_list {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSpProcStmtFetch_1, OP3("FETCH", "", "INTO"), tmp1, tmp2);

        auto tmp3 = $6;
        res = new IR(kSpProcStmtFetch, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


sp_proc_stmt_close:

    CLOSE_SYM ident {
        auto tmp1 = $2;
        res = new IR(kSpProcStmtClose, OP3("CLOSE", "", ""), tmp1);
        $$ = res;
    }

;


sp_opt_fetch_noise:

    /* Empty */ {
        res = new IR(kSpOptFetchNoise, OP3("", "", ""));
        $$ = res;
    }

    | NEXT_SYM FROM {
        res = new IR(kSpOptFetchNoise, OP3("NEXT FROM", "", ""));
        $$ = res;
    }

    | FROM {
        res = new IR(kSpOptFetchNoise, OP3("FROM", "", ""));
        $$ = res;
    }

;


sp_fetch_list:

    ident {
        auto tmp1 = $1;
        res = new IR(kSpFetchList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_fetch_list ',' ident {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSpFetchList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


sp_if:

    {} expr {} THEN_SYM sp_proc_stmts1 {} sp_elseifs {
        auto tmp1 = $2;
        auto tmp2 = $5;
        res = new IR(kSpIf_1, OP3("", "THEN", ""), tmp1, tmp2);

        auto tmp3 = $7;
        res = new IR(kSpIf, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


sp_elseifs:

    /* Empty */ {
        res = new IR(kSpElseifs, OP3("", "", ""));
        $$ = res;
    }

    | ELSEIF_SYM sp_if {
        auto tmp1 = $2;
        res = new IR(kSpElseifs, OP3("ELSEIF", "", ""), tmp1);
        $$ = res;
    }

    | ELSE sp_proc_stmts1 {
        auto tmp1 = $2;
        res = new IR(kSpElseifs, OP3("ELSE", "", ""), tmp1);
        $$ = res;
    }

;


case_stmt_specification:

    simple_case_stmt {
        auto tmp1 = $1;
        res = new IR(kCaseStmtSpecification, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | searched_case_stmt {
        auto tmp1 = $1;
        res = new IR(kCaseStmtSpecification, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


simple_case_stmt:

    CASE_SYM {} expr {} simple_when_clause_list else_clause_opt END CASE_SYM {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kSimpleCaseStmt_1, OP3("CASE", "", ""), tmp1, tmp2);

        auto tmp3 = $6;
        res = new IR(kSimpleCaseStmt, OP3("", "", "END CASE"), res, tmp3);
        $$ = res;
    }

;


searched_case_stmt:

    CASE_SYM {} searched_when_clause_list else_clause_opt END CASE_SYM {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kSearchedCaseStmt, OP3("CASE", "", "END CASE"), tmp1, tmp2);
        $$ = res;
    }

;


simple_when_clause_list:

    simple_when_clause {
        auto tmp1 = $1;
        res = new IR(kSimpleWhenClauseList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | simple_when_clause_list simple_when_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSimpleWhenClauseList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


searched_when_clause_list:

    searched_when_clause {
        auto tmp1 = $1;
        res = new IR(kSearchedWhenClauseList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | searched_when_clause_list searched_when_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSearchedWhenClauseList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


simple_when_clause:

    WHEN_SYM {} expr {} THEN_SYM sp_proc_stmts1 {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kSimpleWhenClause, OP3("WHEN", "THEN", ""), tmp1, tmp2);
        $$ = res;
    }

;


searched_when_clause:

    WHEN_SYM {} expr {} THEN_SYM sp_proc_stmts1 {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kSearchedWhenClause, OP3("WHEN", "THEN", ""), tmp1, tmp2);
        $$ = res;
    }

;


else_clause_opt:

    /* empty */ {
        res = new IR(kElseClauseOpt, OP3("", "", ""));
        $$ = res;
    }

    | ELSE sp_proc_stmts1 {
        auto tmp1 = $2;
        res = new IR(kElseClauseOpt, OP3("ELSE", "", ""), tmp1);
        $$ = res;
    }

;


sp_labeled_control:

    label_ident ':' {} sp_unlabeled_control sp_opt_label {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kSpLabeledControl_1, OP3("", ":", ""), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kSpLabeledControl, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


sp_opt_label:

    /* Empty */ {
        res = new IR(kSpOptLabel, OP3("", "", ""));
        $$ = res;
    }

    | label_ident {
        auto tmp1 = $1;
        res = new IR(kSpOptLabel, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


sp_labeled_block:

    label_ident ':' {} sp_block_content sp_opt_label {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kSpLabeledBlock_1, OP3("", ":", ""), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kSpLabeledBlock, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


sp_unlabeled_block:

    {} sp_block_content {
        auto tmp1 = $2;
        res = new IR(kSpUnlabeledBlock, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


sp_block_content:

    BEGIN_SYM {} sp_decls sp_proc_stmts END {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kSpBlockContent, OP3("BEGIN", "", "END"), tmp1, tmp2);
        $$ = res;
    }

;


sp_unlabeled_control:

    LOOP_SYM sp_proc_stmts1 END LOOP_SYM {
        auto tmp1 = $2;
        res = new IR(kSpUnlabeledControl, OP3("LOOP", "END LOOP", ""), tmp1);
        $$ = res;
    }

    | WHILE_SYM {} expr {} DO_SYM sp_proc_stmts1 END WHILE_SYM {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kSpUnlabeledControl, OP3("WHILE", "DO", "END WHILE"), tmp1, tmp2);
        $$ = res;
    }

    | REPEAT_SYM sp_proc_stmts1 UNTIL_SYM {} expr {} END REPEAT_SYM {
        auto tmp1 = $2;
        auto tmp2 = $5;
        res = new IR(kSpUnlabeledControl, OP3("REPEAT", "UNTIL", "END REPEAT"), tmp1, tmp2);
        $$ = res;
    }

;


trg_action_time:

    BEFORE_SYM {
        res = new IR(kTrgActionTime, OP3("BEFORE", "", ""));
        $$ = res;
    }

    | AFTER_SYM {
        res = new IR(kTrgActionTime, OP3("AFTER", "", ""));
        $$ = res;
    }

;


trg_event:

    INSERT_SYM {
        res = new IR(kTrgEvent, OP3("INSERT", "", ""));
        $$ = res;
    }

    | UPDATE_SYM {
        res = new IR(kTrgEvent, OP3("UPDATE", "", ""));
        $$ = res;
    }

    | DELETE_SYM {
        res = new IR(kTrgEvent, OP3("DELETE", "", ""));
        $$ = res;
    }

;
/*
This part of the parser contains common code for all TABLESPACE
commands.
CREATE TABLESPACE_SYM name ...
ALTER TABLESPACE_SYM name ADD DATAFILE ...
CREATE LOGFILE GROUP_SYM name ...
ALTER LOGFILE GROUP_SYM name ADD UNDOFILE ..
DROP TABLESPACE_SYM name
DROP LOGFILE GROUP_SYM name
*/


opt_ts_datafile_name:

    /* empty */ {
        res = new IR(kOptTsDatafileName, OP3("", "", ""));
        $$ = res;
    }

    | ADD ts_datafile {
        auto tmp1 = $2;
        res = new IR(kOptTsDatafileName, OP3("ADD", "", ""), tmp1);
        $$ = res;
    }

;


opt_logfile_group_name:

    /* empty */ {
        res = new IR(kOptLogfileGroupName, OP3("", "", ""));
        $$ = res;
    }

    | USE_SYM LOGFILE_SYM GROUP_SYM ident {
        auto tmp1 = $4;
        res = new IR(kOptLogfileGroupName, OP3("USE LOGFILE GROUP", "", ""), tmp1);
        $$ = res;
    }

;


opt_tablespace_options:

    /* empty */ {
        res = new IR(kOptTablespaceOptions, OP3("", "", ""));
        $$ = res;
    }

    | tablespace_option_list {
        auto tmp1 = $1;
        res = new IR(kOptTablespaceOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


tablespace_option_list:

    tablespace_option {
        auto tmp1 = $1;
        res = new IR(kTablespaceOptionList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | tablespace_option_list opt_comma tablespace_option {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kTablespaceOptionList_1, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kTablespaceOptionList, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


tablespace_option:

    ts_option_initial_size {
        auto tmp1 = $1;
        res = new IR(kTablespaceOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ts_option_autoextend_size {
        auto tmp1 = $1;
        res = new IR(kTablespaceOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ts_option_max_size {
        auto tmp1 = $1;
        res = new IR(kTablespaceOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ts_option_extent_size {
        auto tmp1 = $1;
        res = new IR(kTablespaceOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ts_option_nodegroup {
        auto tmp1 = $1;
        res = new IR(kTablespaceOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ts_option_engine {
        auto tmp1 = $1;
        res = new IR(kTablespaceOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ts_option_wait {
        auto tmp1 = $1;
        res = new IR(kTablespaceOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ts_option_comment {
        auto tmp1 = $1;
        res = new IR(kTablespaceOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ts_option_file_block_size {
        auto tmp1 = $1;
        res = new IR(kTablespaceOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ts_option_encryption {
        auto tmp1 = $1;
        res = new IR(kTablespaceOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ts_option_engine_attribute {
        auto tmp1 = $1;
        res = new IR(kTablespaceOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_alter_tablespace_options:

    /* empty */ {
        res = new IR(kOptAlterTablespaceOptions, OP3("", "", ""));
        $$ = res;
    }

    | alter_tablespace_option_list {
        auto tmp1 = $1;
        res = new IR(kOptAlterTablespaceOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


alter_tablespace_option_list:

    alter_tablespace_option {
        auto tmp1 = $1;
        res = new IR(kAlterTablespaceOptionList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | alter_tablespace_option_list opt_comma alter_tablespace_option {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAlterTablespaceOptionList_1, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kAlterTablespaceOptionList, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


alter_tablespace_option:

    ts_option_initial_size {
        auto tmp1 = $1;
        res = new IR(kAlterTablespaceOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ts_option_autoextend_size {
        auto tmp1 = $1;
        res = new IR(kAlterTablespaceOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ts_option_max_size {
        auto tmp1 = $1;
        res = new IR(kAlterTablespaceOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ts_option_engine {
        auto tmp1 = $1;
        res = new IR(kAlterTablespaceOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ts_option_wait {
        auto tmp1 = $1;
        res = new IR(kAlterTablespaceOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ts_option_encryption {
        auto tmp1 = $1;
        res = new IR(kAlterTablespaceOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ts_option_engine_attribute {
        auto tmp1 = $1;
        res = new IR(kAlterTablespaceOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_undo_tablespace_options:

    /* empty */ {
        res = new IR(kOptUndoTablespaceOptions, OP3("", "", ""));
        $$ = res;
    }

    | undo_tablespace_option_list {
        auto tmp1 = $1;
        res = new IR(kOptUndoTablespaceOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


undo_tablespace_option_list:

    undo_tablespace_option {
        auto tmp1 = $1;
        res = new IR(kUndoTablespaceOptionList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | undo_tablespace_option_list opt_comma undo_tablespace_option {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUndoTablespaceOptionList_1, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kUndoTablespaceOptionList, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


undo_tablespace_option:

    ts_option_engine {
        auto tmp1 = $1;
        res = new IR(kUndoTablespaceOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_logfile_group_options:

    /* empty */ {
        res = new IR(kOptLogfileGroupOptions, OP3("", "", ""));
        $$ = res;
    }

    | logfile_group_option_list {
        auto tmp1 = $1;
        res = new IR(kOptLogfileGroupOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


logfile_group_option_list:

    logfile_group_option {
        auto tmp1 = $1;
        res = new IR(kLogfileGroupOptionList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | logfile_group_option_list opt_comma logfile_group_option {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kLogfileGroupOptionList_1, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kLogfileGroupOptionList, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


logfile_group_option:

    ts_option_initial_size {
        auto tmp1 = $1;
        res = new IR(kLogfileGroupOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ts_option_undo_buffer_size {
        auto tmp1 = $1;
        res = new IR(kLogfileGroupOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ts_option_redo_buffer_size {
        auto tmp1 = $1;
        res = new IR(kLogfileGroupOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ts_option_nodegroup {
        auto tmp1 = $1;
        res = new IR(kLogfileGroupOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ts_option_engine {
        auto tmp1 = $1;
        res = new IR(kLogfileGroupOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ts_option_wait {
        auto tmp1 = $1;
        res = new IR(kLogfileGroupOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ts_option_comment {
        auto tmp1 = $1;
        res = new IR(kLogfileGroupOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_alter_logfile_group_options:

    /* empty */ {
        res = new IR(kOptAlterLogfileGroupOptions, OP3("", "", ""));
        $$ = res;
    }

    | alter_logfile_group_option_list {
        auto tmp1 = $1;
        res = new IR(kOptAlterLogfileGroupOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


alter_logfile_group_option_list:

    alter_logfile_group_option {
        auto tmp1 = $1;
        res = new IR(kAlterLogfileGroupOptionList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | alter_logfile_group_option_list opt_comma alter_logfile_group_option {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAlterLogfileGroupOptionList_1, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kAlterLogfileGroupOptionList, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


alter_logfile_group_option:

    ts_option_initial_size {
        auto tmp1 = $1;
        res = new IR(kAlterLogfileGroupOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ts_option_engine {
        auto tmp1 = $1;
        res = new IR(kAlterLogfileGroupOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ts_option_wait {
        auto tmp1 = $1;
        res = new IR(kAlterLogfileGroupOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


ts_datafile:

    DATAFILE_SYM TEXT_STRING_sys {
        auto tmp1 = $2;
        res = new IR(kTsDatafile, OP3("DATAFILE", "", ""), tmp1);
        $$ = res;
    }

;


undo_tablespace_state:

    ACTIVE_SYM {
        res = new IR(kUndoTablespaceState, OP3("ACTIVE", "", ""));
        $$ = res;
    }

    | INACTIVE_SYM {
        res = new IR(kUndoTablespaceState, OP3("INACTIVE", "", ""));
        $$ = res;
    }

;


lg_undofile:

    UNDOFILE_SYM TEXT_STRING_sys {
        auto tmp1 = $2;
        res = new IR(kLgUndofile, OP3("UNDOFILE", "", ""), tmp1);
        $$ = res;
    }

;


ts_option_initial_size:

    INITIAL_SIZE_SYM opt_equal size_number {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kTsOptionInitialSize, OP3("INITIAL_SIZE", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


ts_option_autoextend_size:

    option_autoextend_size {
        auto tmp1 = $1;
        res = new IR(kTsOptionAutoextendSize, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


option_autoextend_size:

    AUTOEXTEND_SIZE_SYM opt_equal size_number {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kOptionAutoextendSize, OP3("AUTOEXTEND_SIZE", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


ts_option_max_size:

    MAX_SIZE_SYM opt_equal size_number {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kTsOptionMaxSize, OP3("MAX_SIZE", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


ts_option_extent_size:

    EXTENT_SIZE_SYM opt_equal size_number {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kTsOptionExtentSize, OP3("EXTENT_SIZE", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


ts_option_undo_buffer_size:

    UNDO_BUFFER_SIZE_SYM opt_equal size_number {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kTsOptionUndoBufferSize, OP3("UNDO_BUFFER_SIZE", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


ts_option_redo_buffer_size:

    REDO_BUFFER_SIZE_SYM opt_equal size_number {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kTsOptionRedoBufferSize, OP3("REDO_BUFFER_SIZE", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


ts_option_nodegroup:

    NODEGROUP_SYM opt_equal real_ulong_num {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kTsOptionNodegroup, OP3("NODEGROUP", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


ts_option_comment:

    COMMENT_SYM opt_equal TEXT_STRING_sys {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kTsOptionComment, OP3("COMMENT", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


ts_option_engine:

    opt_storage ENGINE_SYM opt_equal ident_or_text {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTsOptionEngine_1, OP3("", "ENGINE", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kTsOptionEngine, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


ts_option_file_block_size:

    FILE_BLOCK_SIZE_SYM opt_equal size_number {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kTsOptionFileBlockSize, OP3("FILE_BLOCK_SIZE", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


ts_option_wait:

    WAIT_SYM {
        res = new IR(kTsOptionWait, OP3("WAIT", "", ""));
        $$ = res;
    }

    | NO_WAIT_SYM {
        res = new IR(kTsOptionWait, OP3("NO_WAIT", "", ""));
        $$ = res;
    }

;


ts_option_encryption:

    ENCRYPTION_SYM opt_equal TEXT_STRING_sys {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kTsOptionEncryption, OP3("ENCRYPTION", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


ts_option_engine_attribute:

    ENGINE_ATTRIBUTE_SYM opt_equal json_attribute {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kTsOptionEngineAttribute, OP3("ENGINE_ATTRIBUTE", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


size_number:

    real_ulonglong_num {
        auto tmp1 = $1;
        res = new IR(kSizeNumber, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | IDENT_sys {
        auto tmp1 = $1;
        res = new IR(kSizeNumber, OP3("", "", ""), tmp1);
        $$ = res;
    }

;

/*
End tablespace part
*/

/*
To avoid grammar conflicts, we introduce the next few rules in very details:
we workaround empty rules for optional AS and DUPLICATE clauses by expanding
them in place of the caller rule:

opt_create_table_options_etc ::=
create_table_options opt_create_partitioning_etc
| opt_create_partitioning_etc

opt_create_partitioning_etc ::=
partitioin [opt_duplicate_as_qe] | [opt_duplicate_as_qe]

opt_duplicate_as_qe ::=
duplicate as_create_query_expression
| as_create_query_expression

as_create_query_expression ::=
AS query_expression_or_parens
| query_expression_or_parens

*/


opt_create_table_options_etc:

    create_table_options opt_create_partitioning_etc {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptCreateTableOptionsEtc, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | opt_create_partitioning_etc {
        auto tmp1 = $1;
        res = new IR(kOptCreateTableOptionsEtc, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_create_partitioning_etc:

    partition_clause opt_duplicate_as_qe {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptCreatePartitioningEtc, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | opt_duplicate_as_qe {
        auto tmp1 = $1;
        res = new IR(kOptCreatePartitioningEtc, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_duplicate_as_qe:

    /* empty */ {
        res = new IR(kOptDuplicateAsQe, OP3("", "", ""));
        $$ = res;
    }

    | duplicate as_create_query_expression {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptDuplicateAsQe, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | as_create_query_expression {
        auto tmp1 = $1;
        res = new IR(kOptDuplicateAsQe, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


as_create_query_expression:

    AS query_expression_or_parens {
        auto tmp1 = $2;
        res = new IR(kAsCreateQueryExpression, OP3("AS", "", ""), tmp1);
        $$ = res;
    }

    | query_expression_or_parens {
        auto tmp1 = $1;
        res = new IR(kAsCreateQueryExpression, OP3("", "", ""), tmp1);
        $$ = res;
    }

;

/*
This part of the parser is about handling of the partition information.

It's first version was written by Mikael Ronström with lots of answers to
questions provided by Antony Curtis.

The partition grammar can be called from two places.
1) CREATE TABLE ... PARTITION ..
2) ALTER TABLE table_name PARTITION ...
*/

partition_clause:

    PARTITION_SYM BY part_type_def opt_num_parts opt_sub_part opt_part_defs {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kPartitionClause_1, OP3("PARTITION BY", "", ""), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kPartitionClause_2, OP3("", "", ""), res, tmp3);

        auto tmp4 = $6;
        res = new IR(kPartitionClause, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


part_type_def:

    opt_linear KEY_SYM opt_key_algo '(' opt_name_list ')' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kPartTypeDef_1, OP3("", "KEY", "("), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kPartTypeDef, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | opt_linear HASH_SYM '(' bit_expr ')' {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kPartTypeDef, OP3("", "HASH (", ")"), tmp1, tmp2);
        $$ = res;
    }

    | RANGE_SYM '(' bit_expr ')' {
        auto tmp1 = $3;
        res = new IR(kPartTypeDef, OP3("RANGE (", ")", ""), tmp1);
        $$ = res;
    }

    | RANGE_SYM COLUMNS '(' name_list ')' {
        auto tmp1 = $4;
        res = new IR(kPartTypeDef, OP3("RANGE COLUMNS (", ")", ""), tmp1);
        $$ = res;
    }

    | LIST_SYM '(' bit_expr ')' {
        auto tmp1 = $3;
        res = new IR(kPartTypeDef, OP3("LIST (", ")", ""), tmp1);
        $$ = res;
    }

    | LIST_SYM COLUMNS '(' name_list ')' {
        auto tmp1 = $4;
        res = new IR(kPartTypeDef, OP3("LIST COLUMNS (", ")", ""), tmp1);
        $$ = res;
    }

;


opt_linear:

    /* empty */ {
        res = new IR(kOptLinear, OP3("", "", ""));
        $$ = res;
    }

    | LINEAR_SYM {
        res = new IR(kOptLinear, OP3("LINEAR", "", ""));
        $$ = res;
    }

;


opt_key_algo:

    /* empty */ {
        res = new IR(kOptKeyAlgo, OP3("", "", ""));
        $$ = res;
    }

    | ALGORITHM_SYM EQ real_ulong_num {
        auto tmp1 = $3;
        res = new IR(kOptKeyAlgo, OP3("ALGORITHM =", "", ""), tmp1);
        $$ = res;
    }

;


opt_num_parts:

    /* empty */ {
        res = new IR(kOptNumParts, OP3("", "", ""));
        $$ = res;
    }

    | PARTITIONS_SYM real_ulong_num {
        auto tmp1 = $2;
        res = new IR(kOptNumParts, OP3("PARTITIONS", "", ""), tmp1);
        $$ = res;
    }

;


opt_sub_part:

    /* empty */ {
        res = new IR(kOptSubPart, OP3("", "", ""));
        $$ = res;
    }

    | SUBPARTITION_SYM BY opt_linear HASH_SYM '(' bit_expr ')' opt_num_subparts {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kOptSubPart_1, OP3("SUBPARTITION BY", "HASH (", ")"), tmp1, tmp2);

        auto tmp3 = $8;
        res = new IR(kOptSubPart, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | SUBPARTITION_SYM BY opt_linear KEY_SYM opt_key_algo '(' name_list ')' opt_num_subparts {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kOptSubPart_2, OP3("SUBPARTITION BY", "KEY", "("), tmp1, tmp2);

        auto tmp3 = $7;
        res = new IR(kOptSubPart_3, OP3("", "", ")"), res, tmp3);

        auto tmp4 = $9;
        res = new IR(kOptSubPart, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;



opt_name_list:

    /* empty */ {
        res = new IR(kOptNameList, OP3("", "", ""));
        $$ = res;
    }

    | name_list {
        auto tmp1 = $1;
        res = new IR(kOptNameList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;



name_list:

    ident {
        auto tmp1 = $1;
        res = new IR(kNameList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | name_list ',' ident {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kNameList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_num_subparts:

    /* empty */ {
        res = new IR(kOptNumSubparts, OP3("", "", ""));
        $$ = res;
    }

    | SUBPARTITIONS_SYM real_ulong_num {
        auto tmp1 = $2;
        res = new IR(kOptNumSubparts, OP3("SUBPARTITIONS", "", ""), tmp1);
        $$ = res;
    }

;


opt_part_defs:

    /* empty */ {
        res = new IR(kOptPartDefs, OP3("", "", ""));
        $$ = res;
    }

    | '(' part_def_list ')' {
        auto tmp1 = $2;
        res = new IR(kOptPartDefs, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

;


part_def_list:

    part_definition {
        auto tmp1 = $1;
        res = new IR(kPartDefList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | part_def_list ',' part_definition {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kPartDefList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


part_definition:

    PARTITION_SYM ident opt_part_values opt_part_options opt_sub_partition {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kPartDefinition_1, OP3("PARTITION", "", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kPartDefinition_2, OP3("", "", ""), res, tmp3);

        auto tmp4 = $5;
        res = new IR(kPartDefinition, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


opt_part_values:

    /* empty */ {
        res = new IR(kOptPartValues, OP3("", "", ""));
        $$ = res;
    }

    | VALUES LESS_SYM THAN_SYM part_func_max {
        auto tmp1 = $4;
        res = new IR(kOptPartValues, OP3("VALUES LESS THAN", "", ""), tmp1);
        $$ = res;
    }

    | VALUES IN_SYM part_values_in {
        auto tmp1 = $3;
        res = new IR(kOptPartValues, OP3("VALUES IN", "", ""), tmp1);
        $$ = res;
    }

;


part_func_max:

    MAX_VALUE_SYM {
        res = new IR(kPartFuncMax, OP3("MAXVALUE", "", ""));
        $$ = res;
    }

    | part_value_item_list_paren {
        auto tmp1 = $1;
        res = new IR(kPartFuncMax, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


part_values_in:

    part_value_item_list_paren {
        auto tmp1 = $1;
        res = new IR(kPartValuesIn, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '(' part_value_list ')' {
        auto tmp1 = $2;
        res = new IR(kPartValuesIn, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

;


part_value_list:

    part_value_item_list_paren {
        auto tmp1 = $1;
        res = new IR(kPartValueList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | part_value_list ',' part_value_item_list_paren {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kPartValueList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


part_value_item_list_paren:

    '(' {} part_value_item_list ')' {
        auto tmp1 = $3;
        res = new IR(kPartValueItemListParen, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

;


part_value_item_list:

    part_value_item {
        auto tmp1 = $1;
        res = new IR(kPartValueItemList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | part_value_item_list ',' part_value_item {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kPartValueItemList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


part_value_item:

    MAX_VALUE_SYM {
        res = new IR(kPartValueItem, OP3("MAXVALUE", "", ""));
        $$ = res;
    }

    | bit_expr {
        auto tmp1 = $1;
        res = new IR(kPartValueItem, OP3("", "", ""), tmp1);
        $$ = res;
    }

;



opt_sub_partition:

    /* empty */ {
        res = new IR(kOptSubPartition, OP3("", "", ""));
        $$ = res;
    }

    | '(' sub_part_list ')' {
        auto tmp1 = $2;
        res = new IR(kOptSubPartition, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

;


sub_part_list:

    sub_part_definition {
        auto tmp1 = $1;
        res = new IR(kSubPartList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sub_part_list ',' sub_part_definition {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSubPartList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


sub_part_definition:

    SUBPARTITION_SYM ident_or_text opt_part_options {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSubPartDefinition, OP3("SUBPARTITION", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_part_options:

    /* empty */ {
        res = new IR(kOptPartOptions, OP3("", "", ""));
        $$ = res;
    }

    | part_option_list {
        auto tmp1 = $1;
        res = new IR(kOptPartOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


part_option_list:

    part_option_list part_option {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kPartOptionList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | part_option {
        auto tmp1 = $1;
        res = new IR(kPartOptionList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


part_option:

    TABLESPACE_SYM opt_equal ident {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kPartOption, OP3("TABLESPACE", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | opt_storage ENGINE_SYM opt_equal ident_or_text {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kPartOption_1, OP3("", "ENGINE", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kPartOption, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | NODEGROUP_SYM opt_equal real_ulong_num {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kPartOption, OP3("NODEGROUP", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | MAX_ROWS opt_equal real_ulonglong_num {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kPartOption, OP3("MAX_ROWS", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | MIN_ROWS opt_equal real_ulonglong_num {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kPartOption, OP3("MIN_ROWS", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | DATA_SYM DIRECTORY_SYM opt_equal TEXT_STRING_sys {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kPartOption, OP3("DATA DIRECTORY", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | INDEX_SYM DIRECTORY_SYM opt_equal TEXT_STRING_sys {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kPartOption, OP3("INDEX DIRECTORY", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | COMMENT_SYM opt_equal TEXT_STRING_sys {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kPartOption, OP3("COMMENT", "", ""), tmp1, tmp2);
        $$ = res;
    }

;

/*
End of partition parser part
*/


alter_database_options:

    alter_database_option {
        auto tmp1 = $1;
        res = new IR(kAlterDatabaseOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | alter_database_options alter_database_option {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAlterDatabaseOptions, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


alter_database_option:

    create_database_option {
        auto tmp1 = $1;
        res = new IR(kAlterDatabaseOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | READ_SYM ONLY_SYM opt_equal ternary_option {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlterDatabaseOption, OP3("READ ONLY", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_create_database_options:

    /* empty */ {
        res = new IR(kOptCreateDatabaseOptions, OP3("", "", ""));
        $$ = res;
    }

    | create_database_options {
        auto tmp1 = $1;
        res = new IR(kOptCreateDatabaseOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


create_database_options:

    create_database_option {
        auto tmp1 = $1;
        res = new IR(kCreateDatabaseOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | create_database_options create_database_option {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCreateDatabaseOptions, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


create_database_option:

    default_collation {
        auto tmp1 = $1;
        res = new IR(kCreateDatabaseOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | default_charset {
        auto tmp1 = $1;
        res = new IR(kCreateDatabaseOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | default_encryption {
        auto tmp1 = $1;
        res = new IR(kCreateDatabaseOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_if_not_exists:

    /* empty */ {
        res = new IR(kOptIfNotExists, OP3("", "", ""));
        $$ = res;
    }

    | IF not EXISTS {
        auto tmp1 = $2;
        res = new IR(kOptIfNotExists, OP3("IF", "EXISTS", ""), tmp1);
        $$ = res;
    }

;


create_table_options_space_separated:

    create_table_option {
        auto tmp1 = $1;
        res = new IR(kCreateTableOptionsSpaceSeparated, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | create_table_options_space_separated create_table_option {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCreateTableOptionsSpaceSeparated, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


create_table_options:

    create_table_option {
        auto tmp1 = $1;
        res = new IR(kCreateTableOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | create_table_options opt_comma create_table_option {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCreateTableOptions_1, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kCreateTableOptions, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


opt_comma:

    /* empty */ {
        res = new IR(kOptComma, OP3("", "", ""));
        $$ = res;
    }

    | ',' {
        res = new IR(kOptComma, OP3(",", "", ""));
        $$ = res;
    }

;


create_table_option:

    ENGINE_SYM opt_equal ident_or_text {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateTableOption, OP3("ENGINE", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | SECONDARY_ENGINE_SYM opt_equal NULL_SYM {
        auto tmp1 = $2;
        res = new IR(kCreateTableOption, OP3("SECONDARY_ENGINE", "NULL", ""), tmp1);
        $$ = res;
    }

    | SECONDARY_ENGINE_SYM opt_equal ident_or_text {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateTableOption, OP3("SECONDARY_ENGINE", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | MAX_ROWS opt_equal ulonglong_num {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateTableOption, OP3("MAX_ROWS", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | MIN_ROWS opt_equal ulonglong_num {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateTableOption, OP3("MIN_ROWS", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | AVG_ROW_LENGTH opt_equal ulonglong_num {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateTableOption, OP3("AVG_ROW_LENGTH", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | PASSWORD opt_equal TEXT_STRING_sys {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateTableOption, OP3("PASSWORD", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | COMMENT_SYM opt_equal TEXT_STRING_sys {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateTableOption, OP3("COMMENT", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | COMPRESSION_SYM opt_equal TEXT_STRING_sys {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateTableOption, OP3("COMPRESSION", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ENCRYPTION_SYM opt_equal TEXT_STRING_sys {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateTableOption, OP3("ENCRYPTION", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | AUTO_INC opt_equal ulonglong_num {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateTableOption, OP3("AUTO_INCREMENT", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | PACK_KEYS_SYM opt_equal ternary_option {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateTableOption, OP3("PACK_KEYS", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | STATS_AUTO_RECALC_SYM opt_equal ternary_option {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateTableOption, OP3("STATS_AUTO_RECALC", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | STATS_PERSISTENT_SYM opt_equal ternary_option {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateTableOption, OP3("STATS_PERSISTENT", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | STATS_SAMPLE_PAGES_SYM opt_equal ulong_num {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateTableOption, OP3("STATS_SAMPLE_PAGES", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | STATS_SAMPLE_PAGES_SYM opt_equal DEFAULT_SYM {
        auto tmp1 = $2;
        res = new IR(kCreateTableOption, OP3("STATS_SAMPLE_PAGES", "DEFAULT", ""), tmp1);
        $$ = res;
    }

    | CHECKSUM_SYM opt_equal ulong_num {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateTableOption, OP3("CHECKSUM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | TABLE_CHECKSUM_SYM opt_equal ulong_num {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateTableOption, OP3("TABLE_CHECKSUM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | DELAY_KEY_WRITE_SYM opt_equal ulong_num {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateTableOption, OP3("DELAY_KEY_WRITE", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ROW_FORMAT_SYM opt_equal row_types {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateTableOption, OP3("ROW_FORMAT", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | UNION_SYM opt_equal '(' opt_table_list ')' {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kCreateTableOption, OP3("UNION", "(", ")"), tmp1, tmp2);
        $$ = res;
    }

    | default_charset {
        auto tmp1 = $1;
        res = new IR(kCreateTableOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | default_collation {
        auto tmp1 = $1;
        res = new IR(kCreateTableOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | INSERT_METHOD opt_equal merge_insert_types {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateTableOption, OP3("INSERT_METHOD", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | DATA_SYM DIRECTORY_SYM opt_equal TEXT_STRING_sys {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kCreateTableOption, OP3("DATA DIRECTORY", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | INDEX_SYM DIRECTORY_SYM opt_equal TEXT_STRING_sys {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kCreateTableOption, OP3("INDEX DIRECTORY", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | TABLESPACE_SYM opt_equal ident {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateTableOption, OP3("TABLESPACE", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | STORAGE_SYM DISK_SYM {
        res = new IR(kCreateTableOption, OP3("STORAGE DISK", "", ""));
        $$ = res;
    }

    | STORAGE_SYM MEMORY_SYM {
        res = new IR(kCreateTableOption, OP3("STORAGE MEMORY", "", ""));
        $$ = res;
    }

    | CONNECTION_SYM opt_equal TEXT_STRING_sys {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateTableOption, OP3("CONNECTION", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | KEY_BLOCK_SIZE opt_equal ulonglong_num {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateTableOption, OP3("KEY_BLOCK_SIZE", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | START_SYM TRANSACTION_SYM {
        res = new IR(kCreateTableOption, OP3("START TRANSACTION", "", ""));
        $$ = res;
    }

    | ENGINE_ATTRIBUTE_SYM opt_equal json_attribute {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateTableOption, OP3("ENGINE_ATTRIBUTE", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | SECONDARY_ENGINE_ATTRIBUTE_SYM opt_equal json_attribute {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateTableOption, OP3("SECONDARY_ENGINE_ATTRIBUTE", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | option_autoextend_size {
        auto tmp1 = $1;
        res = new IR(kCreateTableOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


ternary_option:

    ulong_num {
        auto tmp1 = $1;
        res = new IR(kTernaryOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DEFAULT_SYM {
        res = new IR(kTernaryOption, OP3("DEFAULT", "", ""));
        $$ = res;
    }

;


default_charset:

    opt_default character_set opt_equal charset_name {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kDefaultCharset_1, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kDefaultCharset_2, OP3("", "", ""), res, tmp3);

        auto tmp4 = $4;
        res = new IR(kDefaultCharset, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


default_collation:

    opt_default COLLATE_SYM opt_equal collation_name {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kDefaultCollation_1, OP3("", "COLLATE", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kDefaultCollation, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


default_encryption:

    opt_default ENCRYPTION_SYM opt_equal TEXT_STRING_sys {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kDefaultEncryption_1, OP3("", "ENCRYPTION", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kDefaultEncryption, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


row_types:

    DEFAULT_SYM {
        res = new IR(kRowTypes, OP3("DEFAULT", "", ""));
        $$ = res;
    }

    | FIXED_SYM {
        res = new IR(kRowTypes, OP3("FIXED", "", ""));
        $$ = res;
    }

    | DYNAMIC_SYM {
        res = new IR(kRowTypes, OP3("DYNAMIC", "", ""));
        $$ = res;
    }

    | COMPRESSED_SYM {
        res = new IR(kRowTypes, OP3("COMPRESSED", "", ""));
        $$ = res;
    }

    | REDUNDANT_SYM {
        res = new IR(kRowTypes, OP3("REDUNDANT", "", ""));
        $$ = res;
    }

    | COMPACT_SYM {
        res = new IR(kRowTypes, OP3("COMPACT", "", ""));
        $$ = res;
    }

;


merge_insert_types:

    NO_SYM {
        res = new IR(kMergeInsertTypes, OP3("NO", "", ""));
        $$ = res;
    }

    | FIRST_SYM {
        res = new IR(kMergeInsertTypes, OP3("FIRST", "", ""));
        $$ = res;
    }

    | LAST_SYM {
        res = new IR(kMergeInsertTypes, OP3("LAST", "", ""));
        $$ = res;
    }

;


udf_type:

    STRING_SYM {
        res = new IR(kUdfType, OP3("STRING", "", ""));
        $$ = res;
    }

    | REAL_SYM {
        res = new IR(kUdfType, OP3("REAL", "", ""));
        $$ = res;
    }

    | DECIMAL_SYM {
        res = new IR(kUdfType, OP3("DEC", "", ""));
        $$ = res;
    }

    | INT_SYM {
        res = new IR(kUdfType, OP3("INT", "", ""));
        $$ = res;
    }

;


table_element_list:

    table_element {
        auto tmp1 = $1;
        res = new IR(kTableElementList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | table_element_list ',' table_element {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTableElementList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


table_element:

    column_def {
        auto tmp1 = $1;
        res = new IR(kTableElement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | table_constraint_def {
        auto tmp1 = $1;
        res = new IR(kTableElement, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


column_def:

    ident field_def opt_references {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kColumnDef_1, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kColumnDef, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


opt_references:

    /* empty */ {
        res = new IR(kOptReferences, OP3("", "", ""));
        $$ = res;
    }

    | references {
        auto tmp1 = $1;
        res = new IR(kOptReferences, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


table_constraint_def:

    key_or_index opt_index_name_and_type '(' key_list_with_expression ')' opt_index_options {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kTableConstraintDef_1, OP3("", "", "("), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kTableConstraintDef_2, OP3("", "", ")"), res, tmp3);

        auto tmp4 = $6;
        res = new IR(kTableConstraintDef, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | FULLTEXT_SYM opt_key_or_index opt_ident '(' key_list_with_expression ')' opt_fulltext_index_options {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kTableConstraintDef_3, OP3("FULLTEXT", "", "("), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kTableConstraintDef_4, OP3("", "", ")"), res, tmp3);

        auto tmp4 = $7;
        res = new IR(kTableConstraintDef, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | SPATIAL_SYM opt_key_or_index opt_ident '(' key_list_with_expression ')' opt_spatial_index_options {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kTableConstraintDef_5, OP3("SPATIAL", "", "("), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kTableConstraintDef_6, OP3("", "", ")"), res, tmp3);

        auto tmp4 = $7;
        res = new IR(kTableConstraintDef, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | opt_constraint_name constraint_key_type opt_index_name_and_type '(' key_list_with_expression ')' opt_index_options {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kTableConstraintDef_7, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kTableConstraintDef_8, OP3("", "", "("), res, tmp3);

        auto tmp4 = $5;
        res = new IR(kTableConstraintDef_9, OP3("", "", ")"), res, tmp4);

        auto tmp5 = $7;
        res = new IR(kTableConstraintDef, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

    | opt_constraint_name FOREIGN KEY_SYM opt_ident '(' key_list ')' references {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kTableConstraintDef_10, OP3("", "FOREIGN KEY", "("), tmp1, tmp2);

        auto tmp3 = $6;
        res = new IR(kTableConstraintDef_11, OP3("", "", ")"), res, tmp3);

        auto tmp4 = $8;
        res = new IR(kTableConstraintDef, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | opt_constraint_name check_constraint opt_constraint_enforcement {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kTableConstraintDef_12, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kTableConstraintDef, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


check_constraint:

    CHECK_SYM '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kCheckConstraint, OP3("CHECK (", ")", ""), tmp1);
        $$ = res;
    }

;


opt_constraint_name:

    /* empty */ {
        res = new IR(kOptConstraintName, OP3("", "", ""));
        $$ = res;
    }

    | CONSTRAINT opt_ident {
        auto tmp1 = $2;
        res = new IR(kOptConstraintName, OP3("CONSTRAINT", "", ""), tmp1);
        $$ = res;
    }

;


opt_not:

    /* empty */ {
        res = new IR(kOptNot, OP3("", "", ""));
        $$ = res;
    }

    | NOT_SYM {
        res = new IR(kOptNot, OP3("NOT", "", ""));
        $$ = res;
    }

;


opt_constraint_enforcement:

    /* empty */ {
        res = new IR(kOptConstraintEnforcement, OP3("", "", ""));
        $$ = res;
    }

    | constraint_enforcement {
        auto tmp1 = $1;
        res = new IR(kOptConstraintEnforcement, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


constraint_enforcement:

    opt_not ENFORCED_SYM {
        auto tmp1 = $1;
        res = new IR(kConstraintEnforcement, OP3("", "ENFORCED", ""), tmp1);
        $$ = res;
    }

;


field_def:

    type opt_column_attribute_list {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFieldDef, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | type opt_collate opt_generated_always AS '(' expr ')' opt_stored_attribute opt_column_attribute_list {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFieldDef_1, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kFieldDef_2, OP3("", "", "AS ("), res, tmp3);

        auto tmp4 = $6;
        res = new IR(kFieldDef_3, OP3("", "", ")"), res, tmp4);

        auto tmp5 = $8;
        res = new IR(kFieldDef_4, OP3("", "", ""), res, tmp5);

        auto tmp6 = $9;
        res = new IR(kFieldDef, OP3("", "", ""), res, tmp6);
        $$ = res;
    }

;


opt_generated_always:

    /* empty */ {
        res = new IR(kOptGeneratedAlways, OP3("", "", ""));
        $$ = res;
    }

    | GENERATED ALWAYS_SYM {
        res = new IR(kOptGeneratedAlways, OP3("GENERATED ALWAYS", "", ""));
        $$ = res;
    }

;


opt_stored_attribute:

    /* empty */ {
        res = new IR(kOptStoredAttribute, OP3("", "", ""));
        $$ = res;
    }

    | VIRTUAL_SYM {
        res = new IR(kOptStoredAttribute, OP3("VIRTUAL", "", ""));
        $$ = res;
    }

    | STORED_SYM {
        res = new IR(kOptStoredAttribute, OP3("STORED", "", ""));
        $$ = res;
    }

;


type:

    int_type opt_field_length field_options {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kType_1, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kType, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | real_type opt_precision field_options {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kType_2, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kType, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | numeric_type float_options field_options {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kType_3, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kType, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | BIT_SYM %prec KEYWORD_USED_AS_KEYWORD {
        res = new IR(kType, OP3("BIT", "", ""));
        $$ = res;
    }

    | BIT_SYM field_length {
        auto tmp1 = $2;
        res = new IR(kType, OP3("BIT", "", ""), tmp1);
        $$ = res;
    }

    | BOOL_SYM {
        res = new IR(kType, OP3("BOOL", "", ""));
        $$ = res;
    }

    | BOOLEAN_SYM {
        res = new IR(kType, OP3("BOOLEAN", "", ""));
        $$ = res;
    }

    | CHAR_SYM field_length opt_charset_with_opt_binary {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kType, OP3("CHAR", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | CHAR_SYM opt_charset_with_opt_binary {
        auto tmp1 = $2;
        res = new IR(kType, OP3("CHAR", "", ""), tmp1);
        $$ = res;
    }

    | nchar field_length opt_bin_mod {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kType_4, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kType, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | nchar opt_bin_mod {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kType, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | BINARY_SYM field_length {
        auto tmp1 = $2;
        res = new IR(kType, OP3("BINARY", "", ""), tmp1);
        $$ = res;
    }

    | BINARY_SYM {
        res = new IR(kType, OP3("BINARY", "", ""));
        $$ = res;
    }

    | varchar field_length opt_charset_with_opt_binary {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kType_5, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kType, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | nvarchar field_length opt_bin_mod {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kType_6, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kType, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | VARBINARY_SYM field_length {
        auto tmp1 = $2;
        res = new IR(kType, OP3("VARBINARY", "", ""), tmp1);
        $$ = res;
    }

    | YEAR_SYM opt_field_length field_options {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kType, OP3("SQL_TSI_YEAR", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | DATE_SYM {
        res = new IR(kType, OP3("DATE", "", ""));
        $$ = res;
    }

    | TIME_SYM type_datetime_precision {
        auto tmp1 = $2;
        res = new IR(kType, OP3("TIME", "", ""), tmp1);
        $$ = res;
    }

    | TIMESTAMP_SYM type_datetime_precision {
        auto tmp1 = $2;
        res = new IR(kType, OP3("TIMESTAMP", "", ""), tmp1);
        $$ = res;
    }

    | DATETIME_SYM type_datetime_precision {
        auto tmp1 = $2;
        res = new IR(kType, OP3("DATETIME", "", ""), tmp1);
        $$ = res;
    }

    | TINYBLOB_SYM {
        res = new IR(kType, OP3("TINYBLOB", "", ""));
        $$ = res;
    }

    | BLOB_SYM opt_field_length {
        auto tmp1 = $2;
        res = new IR(kType, OP3("BLOB", "", ""), tmp1);
        $$ = res;
    }

    | spatial_type {
        auto tmp1 = $1;
        res = new IR(kType, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | MEDIUMBLOB_SYM {
        res = new IR(kType, OP3("MEDIUMBLOB", "", ""));
        $$ = res;
    }

    | LONGBLOB_SYM {
        res = new IR(kType, OP3("LONGBLOB", "", ""));
        $$ = res;
    }

    | LONG_SYM VARBINARY_SYM {
        res = new IR(kType, OP3("LONG VARBINARY", "", ""));
        $$ = res;
    }

    | LONG_SYM varchar opt_charset_with_opt_binary {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kType, OP3("LONG", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | TINYTEXT_SYN opt_charset_with_opt_binary {
        auto tmp1 = $2;
        res = new IR(kType, OP3("TINYTEXT", "", ""), tmp1);
        $$ = res;
    }

    | TEXT_SYM opt_field_length opt_charset_with_opt_binary {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kType, OP3("TEXT", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | MEDIUMTEXT_SYM opt_charset_with_opt_binary {
        auto tmp1 = $2;
        res = new IR(kType, OP3("MEDIUMTEXT", "", ""), tmp1);
        $$ = res;
    }

    | LONGTEXT_SYM opt_charset_with_opt_binary {
        auto tmp1 = $2;
        res = new IR(kType, OP3("LONGTEXT", "", ""), tmp1);
        $$ = res;
    }

    | ENUM_SYM '(' string_list ')' opt_charset_with_opt_binary {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kType, OP3("ENUM (", ")", ""), tmp1, tmp2);
        $$ = res;
    }

    | SET_SYM '(' string_list ')' opt_charset_with_opt_binary {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kType, OP3("SET (", ")", ""), tmp1, tmp2);
        $$ = res;
    }

    | LONG_SYM opt_charset_with_opt_binary {
        auto tmp1 = $2;
        res = new IR(kType, OP3("LONG", "", ""), tmp1);
        $$ = res;
    }

    | SERIAL_SYM {
        res = new IR(kType, OP3("SERIAL", "", ""));
        $$ = res;
    }

    | JSON_SYM {
        res = new IR(kType, OP3("JSON", "", ""));
        $$ = res;
    }

;


spatial_type:

    GEOMETRY_SYM {
        res = new IR(kSpatialType, OP3("GEOMETRY", "", ""));
        $$ = res;
    }

    | GEOMETRYCOLLECTION_SYM {
        res = new IR(kSpatialType, OP3("GEOMCOLLECTION", "", ""));
        $$ = res;
    }

    | POINT_SYM {
        res = new IR(kSpatialType, OP3("POINT", "", ""));
        $$ = res;
    }

    | MULTIPOINT_SYM {
        res = new IR(kSpatialType, OP3("MULTIPOINT", "", ""));
        $$ = res;
    }

    | LINESTRING_SYM {
        res = new IR(kSpatialType, OP3("LINESTRING", "", ""));
        $$ = res;
    }

    | MULTILINESTRING_SYM {
        res = new IR(kSpatialType, OP3("MULTILINESTRING", "", ""));
        $$ = res;
    }

    | POLYGON_SYM {
        res = new IR(kSpatialType, OP3("POLYGON", "", ""));
        $$ = res;
    }

    | MULTIPOLYGON_SYM {
        res = new IR(kSpatialType, OP3("MULTIPOLYGON", "", ""));
        $$ = res;
    }

;


nchar:

    NCHAR_SYM {
        res = new IR(kNchar, OP3("NCHAR", "", ""));
        $$ = res;
    }

    | NATIONAL_SYM CHAR_SYM {
        res = new IR(kNchar, OP3("NATIONAL CHAR", "", ""));
        $$ = res;
    }

;


varchar:

    CHAR_SYM VARYING {
        res = new IR(kVarchar, OP3("CHAR VARYING", "", ""));
        $$ = res;
    }

    | VARCHAR_SYM {
        res = new IR(kVarchar, OP3("VARCHAR", "", ""));
        $$ = res;
    }

;


nvarchar:

    NATIONAL_SYM VARCHAR_SYM {
        res = new IR(kNvarchar, OP3("NATIONAL VARCHAR", "", ""));
        $$ = res;
    }

    | NVARCHAR_SYM {
        res = new IR(kNvarchar, OP3("NVARCHAR", "", ""));
        $$ = res;
    }

    | NCHAR_SYM VARCHAR_SYM {
        res = new IR(kNvarchar, OP3("NCHAR VARCHAR", "", ""));
        $$ = res;
    }

    | NATIONAL_SYM CHAR_SYM VARYING {
        res = new IR(kNvarchar, OP3("NATIONAL CHAR VARYING", "", ""));
        $$ = res;
    }

    | NCHAR_SYM VARYING {
        res = new IR(kNvarchar, OP3("NCHAR VARYING", "", ""));
        $$ = res;
    }

;


int_type:

    INT_SYM {
        res = new IR(kIntType, OP3("INT", "", ""));
        $$ = res;
    }

    | TINYINT_SYM {
        res = new IR(kIntType, OP3("INT1", "", ""));
        $$ = res;
    }

    | SMALLINT_SYM {
        res = new IR(kIntType, OP3("INT2", "", ""));
        $$ = res;
    }

    | MEDIUMINT_SYM {
        res = new IR(kIntType, OP3("INT3", "", ""));
        $$ = res;
    }

    | BIGINT_SYM {
        res = new IR(kIntType, OP3("BIGINT", "", ""));
        $$ = res;
    }

;


real_type:

    REAL_SYM {
        res = new IR(kRealType, OP3("REAL", "", ""));
        $$ = res;
    }

    | DOUBLE_SYM opt_PRECISION {
        auto tmp1 = $2;
        res = new IR(kRealType, OP3("DOUBLE", "", ""), tmp1);
        $$ = res;
    }

;


opt_PRECISION:

    /* empty */ {
        res = new IR(kOptPRECISION, OP3("", "", ""));
        $$ = res;
    }

    | PRECISION {
        res = new IR(kOptPRECISION, OP3("PRECISION", "", ""));
        $$ = res;
    }

;


numeric_type:

    FLOAT_SYM {
        res = new IR(kNumericType, OP3("FLOAT", "", ""));
        $$ = res;
    }

    | DECIMAL_SYM {
        res = new IR(kNumericType, OP3("DEC", "", ""));
        $$ = res;
    }

    | NUMERIC_SYM {
        res = new IR(kNumericType, OP3("NUMERIC", "", ""));
        $$ = res;
    }

    | FIXED_SYM {
        res = new IR(kNumericType, OP3("FIXED", "", ""));
        $$ = res;
    }

;


standard_float_options:

    /* empty */ {
        res = new IR(kStandardFloatOptions, OP3("", "", ""));
        $$ = res;
    }

    | field_length {
        auto tmp1 = $1;
        res = new IR(kStandardFloatOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


float_options:

    /* empty */ {
        res = new IR(kFloatOptions, OP3("", "", ""));
        $$ = res;
    }

    | field_length {
        auto tmp1 = $1;
        res = new IR(kFloatOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | precision {
        auto tmp1 = $1;
        res = new IR(kFloatOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


precision:

    '(' NUM ',' NUM ')' {
        res = new IR(kPrecision, OP3("( NUM , NUM )", "", ""));
        $$ = res;
    }

;



type_datetime_precision:

    /* empty */ {
        res = new IR(kTypeDatetimePrecision, OP3("", "", ""));
        $$ = res;
    }

    | '(' NUM ')' {
        res = new IR(kTypeDatetimePrecision, OP3("( NUM )", "", ""));
        $$ = res;
    }

;


func_datetime_precision:

    /* empty */ {
        res = new IR(kFuncDatetimePrecision, OP3("", "", ""));
        $$ = res;
    }

    | '(' ')' {
        res = new IR(kFuncDatetimePrecision, OP3("( )", "", ""));
        $$ = res;
    }

    | '(' NUM ')' {
        res = new IR(kFuncDatetimePrecision, OP3("( NUM )", "", ""));
        $$ = res;
    }

;


field_options:

    /* empty */ {
        res = new IR(kFieldOptions, OP3("", "", ""));
        $$ = res;
    }

    | field_opt_list {
        auto tmp1 = $1;
        res = new IR(kFieldOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


field_opt_list:

    field_opt_list field_option {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFieldOptList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | field_option {
        auto tmp1 = $1;
        res = new IR(kFieldOptList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


field_option:

    SIGNED_SYM {
        res = new IR(kFieldOption, OP3("SIGNED", "", ""));
        $$ = res;
    }

    | UNSIGNED_SYM {
        res = new IR(kFieldOption, OP3("UNSIGNED", "", ""));
        $$ = res;
    }

    | ZEROFILL_SYM {
        res = new IR(kFieldOption, OP3("ZEROFILL", "", ""));
        $$ = res;
    }

;


field_length:

    '(' LONG_NUM ')' {
        res = new IR(kFieldLength, OP3("( LONG_NUM )", "", ""));
        $$ = res;
    }

    | '(' ULONGLONG_NUM ')' {
        res = new IR(kFieldLength, OP3("( ULONGLONG_NUM )", "", ""));
        $$ = res;
    }

    | '(' DECIMAL_NUM ')' {
        res = new IR(kFieldLength, OP3("( DECIMAL_NUM )", "", ""));
        $$ = res;
    }

    | '(' NUM ')' {
        res = new IR(kFieldLength, OP3("( NUM )", "", ""));
        $$ = res;
    }

;


opt_field_length:

    /* empty */ {
        res = new IR(kOptFieldLength, OP3("", "", ""));
        $$ = res;
    }

    | field_length {
        auto tmp1 = $1;
        res = new IR(kOptFieldLength, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_precision:

    /* empty */ {
        res = new IR(kOptPrecision, OP3("", "", ""));
        $$ = res;
    }

    | precision {
        auto tmp1 = $1;
        res = new IR(kOptPrecision, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_column_attribute_list:

    /* empty */ {
        res = new IR(kOptColumnAttributeList, OP3("", "", ""));
        $$ = res;
    }

    | column_attribute_list {
        auto tmp1 = $1;
        res = new IR(kOptColumnAttributeList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


column_attribute_list:

    column_attribute_list column_attribute {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kColumnAttributeList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | column_attribute {
        auto tmp1 = $1;
        res = new IR(kColumnAttributeList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


column_attribute:

    NULL_SYM {
        res = new IR(kColumnAttribute, OP3("NULL", "", ""));
        $$ = res;
    }

    | not NULL_SYM {
        auto tmp1 = $1;
        res = new IR(kColumnAttribute, OP3("", "NULL", ""), tmp1);
        $$ = res;
    }

    | not SECONDARY_SYM {
        auto tmp1 = $1;
        res = new IR(kColumnAttribute, OP3("", "SECONDARY", ""), tmp1);
        $$ = res;
    }

    | DEFAULT_SYM now_or_signed_literal {
        auto tmp1 = $2;
        res = new IR(kColumnAttribute, OP3("DEFAULT", "", ""), tmp1);
        $$ = res;
    }

    | DEFAULT_SYM '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kColumnAttribute, OP3("DEFAULT (", ")", ""), tmp1);
        $$ = res;
    }

    | ON_SYM UPDATE_SYM now {
        auto tmp1 = $3;
        res = new IR(kColumnAttribute, OP3("ON UPDATE", "", ""), tmp1);
        $$ = res;
    }

    | AUTO_INC {
        res = new IR(kColumnAttribute, OP3("AUTO_INCREMENT", "", ""));
        $$ = res;
    }

    | SERIAL_SYM DEFAULT_SYM VALUE_SYM {
        res = new IR(kColumnAttribute, OP3("SERIAL DEFAULT VALUE", "", ""));
        $$ = res;
    }

    | opt_primary KEY_SYM {
        auto tmp1 = $1;
        res = new IR(kColumnAttribute, OP3("", "KEY", ""), tmp1);
        $$ = res;
    }

    | UNIQUE_SYM {
        res = new IR(kColumnAttribute, OP3("UNIQUE", "", ""));
        $$ = res;
    }

    | UNIQUE_SYM KEY_SYM {
        res = new IR(kColumnAttribute, OP3("UNIQUE KEY", "", ""));
        $$ = res;
    }

    | COMMENT_SYM TEXT_STRING_sys {
        auto tmp1 = $2;
        res = new IR(kColumnAttribute, OP3("COMMENT", "", ""), tmp1);
        $$ = res;
    }

    | COLLATE_SYM collation_name {
        auto tmp1 = $2;
        res = new IR(kColumnAttribute, OP3("COLLATE", "", ""), tmp1);
        $$ = res;
    }

    | COLUMN_FORMAT_SYM column_format {
        auto tmp1 = $2;
        res = new IR(kColumnAttribute, OP3("COLUMN_FORMAT", "", ""), tmp1);
        $$ = res;
    }

    | STORAGE_SYM storage_media {
        auto tmp1 = $2;
        res = new IR(kColumnAttribute, OP3("STORAGE", "", ""), tmp1);
        $$ = res;
    }

    | SRID_SYM real_ulonglong_num {
        auto tmp1 = $2;
        res = new IR(kColumnAttribute, OP3("SRID", "", ""), tmp1);
        $$ = res;
    }

    | opt_constraint_name check_constraint {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kColumnAttribute, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | constraint_enforcement {
        auto tmp1 = $1;
        res = new IR(kColumnAttribute, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ENGINE_ATTRIBUTE_SYM opt_equal json_attribute {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kColumnAttribute, OP3("ENGINE_ATTRIBUTE", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | SECONDARY_ENGINE_ATTRIBUTE_SYM opt_equal json_attribute {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kColumnAttribute, OP3("SECONDARY_ENGINE_ATTRIBUTE", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | visibility {
        auto tmp1 = $1;
        res = new IR(kColumnAttribute, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


column_format:

    DEFAULT_SYM {
        res = new IR(kColumnFormat, OP3("DEFAULT", "", ""));
        $$ = res;
    }

    | FIXED_SYM {
        res = new IR(kColumnFormat, OP3("FIXED", "", ""));
        $$ = res;
    }

    | DYNAMIC_SYM {
        res = new IR(kColumnFormat, OP3("DYNAMIC", "", ""));
        $$ = res;
    }

;


storage_media:

    DEFAULT_SYM {
        res = new IR(kStorageMedia, OP3("DEFAULT", "", ""));
        $$ = res;
    }

    | DISK_SYM {
        res = new IR(kStorageMedia, OP3("DISK", "", ""));
        $$ = res;
    }

    | MEMORY_SYM {
        res = new IR(kStorageMedia, OP3("MEMORY", "", ""));
        $$ = res;
    }

;


now:

    NOW_SYM func_datetime_precision {
        auto tmp1 = $2;
        res = new IR(kNow, OP3("CURRENT_TIMESTAMP", "", ""), tmp1);
        $$ = res;
    }

;


now_or_signed_literal:

    now {
        auto tmp1 = $1;
        res = new IR(kNowOrSignedLiteral, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | signed_literal_or_null {
        auto tmp1 = $1;
        res = new IR(kNowOrSignedLiteral, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


character_set:

    CHAR_SYM SET_SYM {
        res = new IR(kCharacterSet, OP3("CHAR SET", "", ""));
        $$ = res;
    }

    | CHARSET {
        res = new IR(kCharacterSet, OP3("CHARSET", "", ""));
        $$ = res;
    }

;


charset_name:

    ident_or_text {
        auto tmp1 = $1;
        res = new IR(kCharsetName, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | BINARY_SYM {
        res = new IR(kCharsetName, OP3("BINARY", "", ""));
        $$ = res;
    }

;


opt_load_data_charset:

    /* Empty */ {
        res = new IR(kOptLoadDataCharset, OP3("", "", ""));
        $$ = res;
    }

    | character_set charset_name {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptLoadDataCharset, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


old_or_new_charset_name:

    ident_or_text {
        auto tmp1 = $1;
        res = new IR(kOldOrNewCharsetName, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | BINARY_SYM {
        res = new IR(kOldOrNewCharsetName, OP3("BINARY", "", ""));
        $$ = res;
    }

;


old_or_new_charset_name_or_default:

    old_or_new_charset_name {
        auto tmp1 = $1;
        res = new IR(kOldOrNewCharsetNameOrDefault, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DEFAULT_SYM {
        res = new IR(kOldOrNewCharsetNameOrDefault, OP3("DEFAULT", "", ""));
        $$ = res;
    }

;


collation_name:

    ident_or_text {
        auto tmp1 = $1;
        res = new IR(kCollationName, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | BINARY_SYM {
        res = new IR(kCollationName, OP3("BINARY", "", ""));
        $$ = res;
    }

;


opt_collate:

    /* empty */ {
        res = new IR(kOptCollate, OP3("", "", ""));
        $$ = res;
    }

    | COLLATE_SYM collation_name {
        auto tmp1 = $2;
        res = new IR(kOptCollate, OP3("COLLATE", "", ""), tmp1);
        $$ = res;
    }

;


opt_default:

    /* empty */ {
        res = new IR(kOptDefault, OP3("", "", ""));
        $$ = res;
    }

    | DEFAULT_SYM {
        res = new IR(kOptDefault, OP3("DEFAULT", "", ""));
        $$ = res;
    }

;



ascii:

    ASCII_SYM {
        res = new IR(kAscii, OP3("ASCII", "", ""));
        $$ = res;
    }

    | BINARY_SYM ASCII_SYM {
        res = new IR(kAscii, OP3("BINARY ASCII", "", ""));
        $$ = res;
    }

    | ASCII_SYM BINARY_SYM {
        res = new IR(kAscii, OP3("ASCII BINARY", "", ""));
        $$ = res;
    }

;


unicode:

    UNICODE_SYM {
        res = new IR(kUnicode, OP3("UNICODE", "", ""));
        $$ = res;
    }

    | UNICODE_SYM BINARY_SYM {
        res = new IR(kUnicode, OP3("UNICODE BINARY", "", ""));
        $$ = res;
    }

    | BINARY_SYM UNICODE_SYM {
        res = new IR(kUnicode, OP3("BINARY UNICODE", "", ""));
        $$ = res;
    }

;


opt_charset_with_opt_binary:

    /* empty */ {
        res = new IR(kOptCharsetWithOptBinary, OP3("", "", ""));
        $$ = res;
    }

    | ascii {
        auto tmp1 = $1;
        res = new IR(kOptCharsetWithOptBinary, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | unicode {
        auto tmp1 = $1;
        res = new IR(kOptCharsetWithOptBinary, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | BYTE_SYM {
        res = new IR(kOptCharsetWithOptBinary, OP3("BYTE", "", ""));
        $$ = res;
    }

    | character_set charset_name opt_bin_mod {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptCharsetWithOptBinary_1, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kOptCharsetWithOptBinary, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | BINARY_SYM {
        res = new IR(kOptCharsetWithOptBinary, OP3("BINARY", "", ""));
        $$ = res;
    }

    | BINARY_SYM character_set charset_name {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kOptCharsetWithOptBinary, OP3("BINARY", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_bin_mod:

    /* empty */ {
        res = new IR(kOptBinMod, OP3("", "", ""));
        $$ = res;
    }

    | BINARY_SYM {
        res = new IR(kOptBinMod, OP3("BINARY", "", ""));
        $$ = res;
    }

;


ws_num_codepoints:

    '(' real_ulong_num {} ')' {
        auto tmp1 = $2;
        res = new IR(kWsNumCodepoints, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

;


opt_primary:

    /* empty */ {
        res = new IR(kOptPrimary, OP3("", "", ""));
        $$ = res;
    }

    | PRIMARY_SYM {
        res = new IR(kOptPrimary, OP3("PRIMARY", "", ""));
        $$ = res;
    }

;


references:

    REFERENCES table_ident opt_ref_list opt_match_clause opt_on_update_delete {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kReferences_1, OP3("REFERENCES", "", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kReferences_2, OP3("", "", ""), res, tmp3);

        auto tmp4 = $5;
        res = new IR(kReferences, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


opt_ref_list:

    /* empty */ {
        res = new IR(kOptRefList, OP3("", "", ""));
        $$ = res;
    }

    | '(' reference_list ')' {
        auto tmp1 = $2;
        res = new IR(kOptRefList, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

;


reference_list:

    reference_list ',' ident {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kReferenceList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | ident {
        auto tmp1 = $1;
        res = new IR(kReferenceList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_match_clause:

    /* empty */ {
        res = new IR(kOptMatchClause, OP3("", "", ""));
        $$ = res;
    }

    | MATCH FULL {
        res = new IR(kOptMatchClause, OP3("MATCH FULL", "", ""));
        $$ = res;
    }

    | MATCH PARTIAL {
        res = new IR(kOptMatchClause, OP3("MATCH PARTIAL", "", ""));
        $$ = res;
    }

    | MATCH SIMPLE_SYM {
        res = new IR(kOptMatchClause, OP3("MATCH SIMPLE", "", ""));
        $$ = res;
    }

;


opt_on_update_delete:

    /* empty */ {
        res = new IR(kOptOnUpdateDelete, OP3("", "", ""));
        $$ = res;
    }

    | ON_SYM UPDATE_SYM delete_option {
        auto tmp1 = $3;
        res = new IR(kOptOnUpdateDelete, OP3("ON UPDATE", "", ""), tmp1);
        $$ = res;
    }

    | ON_SYM DELETE_SYM delete_option {
        auto tmp1 = $3;
        res = new IR(kOptOnUpdateDelete, OP3("ON DELETE", "", ""), tmp1);
        $$ = res;
    }

    | ON_SYM UPDATE_SYM delete_option ON_SYM DELETE_SYM delete_option {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kOptOnUpdateDelete, OP3("ON UPDATE", "ON DELETE", ""), tmp1, tmp2);
        $$ = res;
    }

    | ON_SYM DELETE_SYM delete_option ON_SYM UPDATE_SYM delete_option {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kOptOnUpdateDelete, OP3("ON DELETE", "ON UPDATE", ""), tmp1, tmp2);
        $$ = res;
    }

;


delete_option:

    RESTRICT {
        res = new IR(kDeleteOption, OP3("RESTRICT", "", ""));
        $$ = res;
    }

    | CASCADE {
        res = new IR(kDeleteOption, OP3("CASCADE", "", ""));
        $$ = res;
    }

    | SET_SYM NULL_SYM {
        res = new IR(kDeleteOption, OP3("SET NULL", "", ""));
        $$ = res;
    }

    | NO_SYM ACTION {
        res = new IR(kDeleteOption, OP3("NO ACTION", "", ""));
        $$ = res;
    }

    | SET_SYM DEFAULT_SYM {
        res = new IR(kDeleteOption, OP3("SET DEFAULT", "", ""));
        $$ = res;
    }

;


constraint_key_type:

    PRIMARY_SYM KEY_SYM {
        res = new IR(kConstraintKeyType, OP3("PRIMARY KEY", "", ""));
        $$ = res;
    }

    | UNIQUE_SYM opt_key_or_index {
        auto tmp1 = $2;
        res = new IR(kConstraintKeyType, OP3("UNIQUE", "", ""), tmp1);
        $$ = res;
    }

;


key_or_index:

    KEY_SYM {
        res = new IR(kKeyOrIndex, OP3("KEY", "", ""));
        $$ = res;
    }

    | INDEX_SYM {
        res = new IR(kKeyOrIndex, OP3("INDEX", "", ""));
        $$ = res;
    }

;


opt_key_or_index:

    /* empty */ {
        res = new IR(kOptKeyOrIndex, OP3("", "", ""));
        $$ = res;
    }

    | key_or_index {
        auto tmp1 = $1;
        res = new IR(kOptKeyOrIndex, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


keys_or_index:

    KEYS {
        res = new IR(kKeysOrIndex, OP3("KEYS", "", ""));
        $$ = res;
    }

    | INDEX_SYM {
        res = new IR(kKeysOrIndex, OP3("INDEX", "", ""));
        $$ = res;
    }

    | INDEXES {
        res = new IR(kKeysOrIndex, OP3("INDEXES", "", ""));
        $$ = res;
    }

;


opt_unique:

    /* empty */ {
        res = new IR(kOptUnique, OP3("", "", ""));
        $$ = res;
    }

    | UNIQUE_SYM {
        res = new IR(kOptUnique, OP3("UNIQUE", "", ""));
        $$ = res;
    }

;


opt_fulltext_index_options:

    /* Empty. */ {
        res = new IR(kOptFulltextIndexOptions, OP3("", "", ""));
        $$ = res;
    }

    | fulltext_index_options {
        auto tmp1 = $1;
        res = new IR(kOptFulltextIndexOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


fulltext_index_options:

    fulltext_index_option {
        auto tmp1 = $1;
        res = new IR(kFulltextIndexOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | fulltext_index_options fulltext_index_option {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFulltextIndexOptions, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


fulltext_index_option:

    common_index_option {
        auto tmp1 = $1;
        res = new IR(kFulltextIndexOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | WITH PARSER_SYM IDENT_sys {
        auto tmp1 = $3;
        res = new IR(kFulltextIndexOption, OP3("WITH PARSER", "", ""), tmp1);
        $$ = res;
    }

;


opt_spatial_index_options:

    /* Empty. */ {
        res = new IR(kOptSpatialIndexOptions, OP3("", "", ""));
        $$ = res;
    }

    | spatial_index_options {
        auto tmp1 = $1;
        res = new IR(kOptSpatialIndexOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


spatial_index_options:

    spatial_index_option {
        auto tmp1 = $1;
        res = new IR(kSpatialIndexOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | spatial_index_options spatial_index_option {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpatialIndexOptions, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


spatial_index_option:

    common_index_option {
        auto tmp1 = $1;
        res = new IR(kSpatialIndexOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_index_options:

    /* Empty. */ {
        res = new IR(kOptIndexOptions, OP3("", "", ""));
        $$ = res;
    }

    | index_options {
        auto tmp1 = $1;
        res = new IR(kOptIndexOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


index_options:

    index_option {
        auto tmp1 = $1;
        res = new IR(kIndexOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | index_options index_option {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kIndexOptions, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


index_option:

    common_index_option {
        auto tmp1 = $1;
        res = new IR(kIndexOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | index_type_clause {
        auto tmp1 = $1;
        res = new IR(kIndexOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

;

// These options are common for all index types.

common_index_option:

    KEY_BLOCK_SIZE opt_equal ulong_num {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCommonIndexOption, OP3("KEY_BLOCK_SIZE", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | COMMENT_SYM TEXT_STRING_sys {
        auto tmp1 = $2;
        res = new IR(kCommonIndexOption, OP3("COMMENT", "", ""), tmp1);
        $$ = res;
    }

    | visibility {
        auto tmp1 = $1;
        res = new IR(kCommonIndexOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ENGINE_ATTRIBUTE_SYM opt_equal json_attribute {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCommonIndexOption, OP3("ENGINE_ATTRIBUTE", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | SECONDARY_ENGINE_ATTRIBUTE_SYM opt_equal json_attribute {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCommonIndexOption, OP3("SECONDARY_ENGINE_ATTRIBUTE", "", ""), tmp1, tmp2);
        $$ = res;
    }

;

/*
The syntax for defining an index is:

... INDEX [index_name] [USING|TYPE] <index_type> ...

The problem is that whereas USING is a reserved word, TYPE is not. We can
still handle it if an index name is supplied, i.e.:

... INDEX type TYPE <index_type> ...

here the index's name is unmbiguously 'type', but for this:

... INDEX TYPE <index_type> ...

it's impossible to know what this actually mean - is 'type' the name or the
type? For this reason we accept the TYPE syntax only if a name is supplied.
*/

opt_index_name_and_type:

    opt_ident {
        auto tmp1 = $1;
        res = new IR(kOptIndexNameAndType, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | opt_ident USING index_type {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kOptIndexNameAndType, OP3("", "USING", ""), tmp1, tmp2);
        $$ = res;
    }

    | ident TYPE_SYM index_type {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kOptIndexNameAndType, OP3("", "TYPE", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_index_type_clause:

    /* empty */ {
        res = new IR(kOptIndexTypeClause, OP3("", "", ""));
        $$ = res;
    }

    | index_type_clause {
        auto tmp1 = $1;
        res = new IR(kOptIndexTypeClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


index_type_clause:

    USING index_type {
        auto tmp1 = $2;
        res = new IR(kIndexTypeClause, OP3("USING", "", ""), tmp1);
        $$ = res;
    }

    | TYPE_SYM index_type {
        auto tmp1 = $2;
        res = new IR(kIndexTypeClause, OP3("TYPE", "", ""), tmp1);
        $$ = res;
    }

;


visibility:

    VISIBLE_SYM {
        res = new IR(kVisibility, OP3("VISIBLE", "", ""));
        $$ = res;
    }

    | INVISIBLE_SYM {
        res = new IR(kVisibility, OP3("INVISIBLE", "", ""));
        $$ = res;
    }

;


index_type:

    BTREE_SYM {
        res = new IR(kIndexType, OP3("BTREE", "", ""));
        $$ = res;
    }

    | RTREE_SYM {
        res = new IR(kIndexType, OP3("RTREE", "", ""));
        $$ = res;
    }

    | HASH_SYM {
        res = new IR(kIndexType, OP3("HASH", "", ""));
        $$ = res;
    }

;


key_list:

    key_list ',' key_part {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kKeyList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | key_part {
        auto tmp1 = $1;
        res = new IR(kKeyList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


key_part:

    ident opt_ordering_direction {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kKeyPart, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ident '(' NUM ')' opt_ordering_direction {
        auto tmp1 = $1;
        auto tmp2 = $5;
        res = new IR(kKeyPart, OP3("", "( NUM )", ""), tmp1, tmp2);
        $$ = res;
    }

;


key_list_with_expression:

    key_list_with_expression ',' key_part_with_expression {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kKeyListWithExpression, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | key_part_with_expression {
        auto tmp1 = $1;
        res = new IR(kKeyListWithExpression, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


key_part_with_expression:

    key_part {
        auto tmp1 = $1;
        res = new IR(kKeyPartWithExpression, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '(' expr ')' opt_ordering_direction {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kKeyPartWithExpression, OP3("(", ")", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_ident:

    /* empty */ {
        res = new IR(kOptIdent, OP3("", "", ""));
        $$ = res;
    }

    | ident {
        auto tmp1 = $1;
        res = new IR(kOptIdent, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_component:

    /* empty */ {
        res = new IR(kOptComponent, OP3("", "", ""));
        $$ = res;
    }

    | '.' ident {
        auto tmp1 = $2;
        res = new IR(kOptComponent, OP3(".", "", ""), tmp1);
        $$ = res;
    }

;


string_list:

    text_string {
        auto tmp1 = $1;
        res = new IR(kStringList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | string_list ',' text_string {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kStringList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;

/*
** Alter table
*/


alter_table_stmt:

    ALTER TABLE_SYM table_ident opt_alter_table_actions {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlterTableStmt, OP3("ALTER TABLE", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER TABLE_SYM table_ident standalone_alter_table_action {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlterTableStmt, OP3("ALTER TABLE", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


alter_database_stmt:

    ALTER DATABASE ident_or_empty {} alter_database_options {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kAlterDatabaseStmt, OP3("ALTER DATABASE", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


alter_procedure_stmt:

    ALTER PROCEDURE_SYM sp_name {} sp_a_chistics {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kAlterProcedureStmt, OP3("ALTER PROCEDURE", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


alter_function_stmt:

    ALTER FUNCTION_SYM sp_name {} sp_a_chistics {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kAlterFunctionStmt, OP3("ALTER FUNCTION", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


alter_view_stmt:

    ALTER view_algorithm definer_opt {} view_tail {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterViewStmt_1, OP3("ALTER", "", ""), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kAlterViewStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER definer_opt {} view_tail {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kAlterViewStmt, OP3("ALTER", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


alter_event_stmt:

    ALTER definer_opt EVENT_SYM sp_name {} ev_alter_on_schedule_completion opt_ev_rename_to opt_ev_status opt_ev_comment opt_ev_sql_stmt {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kAlterEventStmt_1, OP3("ALTER", "EVENT", ""), tmp1, tmp2);

        auto tmp3 = $6;
        res = new IR(kAlterEventStmt_2, OP3("", "", ""), res, tmp3);

        auto tmp4 = $7;
        res = new IR(kAlterEventStmt_3, OP3("", "", ""), res, tmp4);

        auto tmp5 = $8;
        res = new IR(kAlterEventStmt_4, OP3("", "", ""), res, tmp5);

        auto tmp6 = $9;
        res = new IR(kAlterEventStmt_5, OP3("", "", ""), res, tmp6);

        auto tmp7 = $10;
        res = new IR(kAlterEventStmt, OP3("", "", ""), res, tmp7);
        $$ = res;
    }

;


alter_logfile_stmt:

    ALTER LOGFILE_SYM GROUP_SYM ident ADD lg_undofile opt_alter_logfile_group_options {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kAlterLogfileStmt_1, OP3("ALTER LOGFILE GROUP", "ADD", ""), tmp1, tmp2);

        auto tmp3 = $7;
        res = new IR(kAlterLogfileStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


alter_tablespace_stmt:

    ALTER TABLESPACE_SYM ident ADD ts_datafile opt_alter_tablespace_options {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kAlterTablespaceStmt_1, OP3("ALTER TABLESPACE", "ADD", ""), tmp1, tmp2);

        auto tmp3 = $6;
        res = new IR(kAlterTablespaceStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER TABLESPACE_SYM ident DROP ts_datafile opt_alter_tablespace_options {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kAlterTablespaceStmt_2, OP3("ALTER TABLESPACE", "DROP", ""), tmp1, tmp2);

        auto tmp3 = $6;
        res = new IR(kAlterTablespaceStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER TABLESPACE_SYM ident RENAME TO_SYM ident {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kAlterTablespaceStmt, OP3("ALTER TABLESPACE", "RENAME TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER TABLESPACE_SYM ident alter_tablespace_option_list {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlterTablespaceStmt, OP3("ALTER TABLESPACE", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


alter_undo_tablespace_stmt:

    ALTER UNDO_SYM TABLESPACE_SYM ident SET_SYM undo_tablespace_state opt_undo_tablespace_options {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kAlterUndoTablespaceStmt_1, OP3("ALTER UNDO TABLESPACE", "SET", ""), tmp1, tmp2);

        auto tmp3 = $7;
        res = new IR(kAlterUndoTablespaceStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


alter_server_stmt:

    ALTER SERVER_SYM ident_or_text OPTIONS_SYM '(' server_options_list ')' {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kAlterServerStmt, OP3("ALTER SERVER", "OPTIONS (", ")"), tmp1, tmp2);
        $$ = res;
    }

;


alter_user_stmt:

    alter_user_command alter_user_list require_clause connect_options opt_account_lock_password_expire_options opt_user_attribute {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAlterUserStmt_1, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kAlterUserStmt_2, OP3("", "", ""), res, tmp3);

        auto tmp4 = $4;
        res = new IR(kAlterUserStmt_3, OP3("", "", ""), res, tmp4);

        auto tmp5 = $5;
        res = new IR(kAlterUserStmt_4, OP3("", "", ""), res, tmp5);

        auto tmp6 = $6;
        res = new IR(kAlterUserStmt, OP3("", "", ""), res, tmp6);
        $$ = res;
    }

    | alter_user_command user_func identified_by_random_password opt_replace_password opt_retain_current_password {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAlterUserStmt_5, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kAlterUserStmt_6, OP3("", "", ""), res, tmp3);

        auto tmp4 = $4;
        res = new IR(kAlterUserStmt_7, OP3("", "", ""), res, tmp4);

        auto tmp5 = $5;
        res = new IR(kAlterUserStmt, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

    | alter_user_command user_func identified_by_password opt_replace_password opt_retain_current_password {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAlterUserStmt_8, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kAlterUserStmt_9, OP3("", "", ""), res, tmp3);

        auto tmp4 = $4;
        res = new IR(kAlterUserStmt_10, OP3("", "", ""), res, tmp4);

        auto tmp5 = $5;
        res = new IR(kAlterUserStmt, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

    | alter_user_command user_func DISCARD_SYM OLD_SYM PASSWORD {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAlterUserStmt, OP3("", "", "DISCARD OLD PASSWORD"), tmp1, tmp2);
        $$ = res;
    }

    | alter_user_command user DEFAULT_SYM ROLE_SYM ALL {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAlterUserStmt, OP3("", "", "DEFAULT ROLE ALL"), tmp1, tmp2);
        $$ = res;
    }

    | alter_user_command user DEFAULT_SYM ROLE_SYM NONE_SYM {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAlterUserStmt, OP3("", "", "DEFAULT ROLE NONE"), tmp1, tmp2);
        $$ = res;
    }

    | alter_user_command user DEFAULT_SYM ROLE_SYM role_list {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAlterUserStmt_11, OP3("", "", "DEFAULT ROLE"), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kAlterUserStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | alter_user_command user opt_user_registration {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAlterUserStmt_12, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kAlterUserStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | alter_user_command user_func opt_user_registration {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAlterUserStmt_13, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kAlterUserStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


opt_replace_password:

    /* empty */ {
        res = new IR(kOptReplacePassword, OP3("", "", ""));
        $$ = res;
    }

    | REPLACE_SYM TEXT_STRING_password {
        auto tmp1 = $2;
        res = new IR(kOptReplacePassword, OP3("REPLACE", "", ""), tmp1);
        $$ = res;
    }

;


alter_resource_group_stmt:

    ALTER RESOURCE_SYM GROUP_SYM ident opt_resource_group_vcpu_list opt_resource_group_priority opt_resource_group_enable_disable opt_force {
        auto tmp1 = $4;
        auto tmp2 = $5;
        res = new IR(kAlterResourceGroupStmt_1, OP3("ALTER RESOURCE GROUP", "", ""), tmp1, tmp2);

        auto tmp3 = $6;
        res = new IR(kAlterResourceGroupStmt_2, OP3("", "", ""), res, tmp3);

        auto tmp4 = $7;
        res = new IR(kAlterResourceGroupStmt_3, OP3("", "", ""), res, tmp4);

        auto tmp5 = $8;
        res = new IR(kAlterResourceGroupStmt, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

;


alter_user_command:

    ALTER USER if_exists {
        auto tmp1 = $3;
        res = new IR(kAlterUserCommand, OP3("ALTER USER", "", ""), tmp1);
        $$ = res;
    }

;


opt_user_attribute:

    /* empty */ {
        res = new IR(kOptUserAttribute, OP3("", "", ""));
        $$ = res;
    }

    | ATTRIBUTE_SYM TEXT_STRING_literal {
        auto tmp1 = $2;
        res = new IR(kOptUserAttribute, OP3("ATTRIBUTE", "", ""), tmp1);
        $$ = res;
    }

    | COMMENT_SYM TEXT_STRING_literal {
        auto tmp1 = $2;
        res = new IR(kOptUserAttribute, OP3("COMMENT", "", ""), tmp1);
        $$ = res;
    }

;

opt_account_lock_password_expire_options:

    /* empty */ {
        res = new IR(kOptAccountLockPasswordExpireOptions, OP3("", "", ""));
        $$ = res;
    }

    | opt_account_lock_password_expire_option_list {
        auto tmp1 = $1;
        res = new IR(kOptAccountLockPasswordExpireOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_account_lock_password_expire_option_list:

    opt_account_lock_password_expire_option {
        auto tmp1 = $1;
        res = new IR(kOptAccountLockPasswordExpireOptionList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | opt_account_lock_password_expire_option_list opt_account_lock_password_expire_option {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptAccountLockPasswordExpireOptionList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_account_lock_password_expire_option:

    ACCOUNT_SYM UNLOCK_SYM {
        res = new IR(kOptAccountLockPasswordExpireOption, OP3("ACCOUNT UNLOCK", "", ""));
        $$ = res;
    }

    | ACCOUNT_SYM LOCK_SYM {
        res = new IR(kOptAccountLockPasswordExpireOption, OP3("ACCOUNT LOCK", "", ""));
        $$ = res;
    }

    | PASSWORD EXPIRE_SYM {
        res = new IR(kOptAccountLockPasswordExpireOption, OP3("PASSWORD EXPIRE", "", ""));
        $$ = res;
    }

    | PASSWORD EXPIRE_SYM INTERVAL_SYM real_ulong_num DAY_SYM {
        auto tmp1 = $4;
        res = new IR(kOptAccountLockPasswordExpireOption, OP3("PASSWORD EXPIRE INTERVAL", "DAY", ""), tmp1);
        $$ = res;
    }

    | PASSWORD EXPIRE_SYM NEVER_SYM {
        res = new IR(kOptAccountLockPasswordExpireOption, OP3("PASSWORD EXPIRE NEVER", "", ""));
        $$ = res;
    }

    | PASSWORD EXPIRE_SYM DEFAULT_SYM {
        res = new IR(kOptAccountLockPasswordExpireOption, OP3("PASSWORD EXPIRE DEFAULT", "", ""));
        $$ = res;
    }

    | PASSWORD HISTORY_SYM real_ulong_num {
        auto tmp1 = $3;
        res = new IR(kOptAccountLockPasswordExpireOption, OP3("PASSWORD HISTORY", "", ""), tmp1);
        $$ = res;
    }

    | PASSWORD HISTORY_SYM DEFAULT_SYM {
        res = new IR(kOptAccountLockPasswordExpireOption, OP3("PASSWORD HISTORY DEFAULT", "", ""));
        $$ = res;
    }

    | PASSWORD REUSE_SYM INTERVAL_SYM real_ulong_num DAY_SYM {
        auto tmp1 = $4;
        res = new IR(kOptAccountLockPasswordExpireOption, OP3("PASSWORD REUSE INTERVAL", "DAY", ""), tmp1);
        $$ = res;
    }

    | PASSWORD REUSE_SYM INTERVAL_SYM DEFAULT_SYM {
        res = new IR(kOptAccountLockPasswordExpireOption, OP3("PASSWORD REUSE INTERVAL DEFAULT", "", ""));
        $$ = res;
    }

    | PASSWORD REQUIRE_SYM CURRENT_SYM {
        res = new IR(kOptAccountLockPasswordExpireOption, OP3("PASSWORD REQUIRE CURRENT", "", ""));
        $$ = res;
    }

    | PASSWORD REQUIRE_SYM CURRENT_SYM DEFAULT_SYM {
        res = new IR(kOptAccountLockPasswordExpireOption, OP3("PASSWORD REQUIRE CURRENT DEFAULT", "", ""));
        $$ = res;
    }

    | PASSWORD REQUIRE_SYM CURRENT_SYM OPTIONAL_SYM {
        res = new IR(kOptAccountLockPasswordExpireOption, OP3("PASSWORD REQUIRE CURRENT OPTIONAL", "", ""));
        $$ = res;
    }

    | FAILED_LOGIN_ATTEMPTS_SYM real_ulong_num {
        auto tmp1 = $2;
        res = new IR(kOptAccountLockPasswordExpireOption, OP3("FAILED_LOGIN_ATTEMPTS", "", ""), tmp1);
        $$ = res;
    }

    | PASSWORD_LOCK_TIME_SYM real_ulong_num {
        auto tmp1 = $2;
        res = new IR(kOptAccountLockPasswordExpireOption, OP3("PASSWORD_LOCK_TIME", "", ""), tmp1);
        $$ = res;
    }

    | PASSWORD_LOCK_TIME_SYM UNBOUNDED_SYM {
        res = new IR(kOptAccountLockPasswordExpireOption, OP3("PASSWORD_LOCK_TIME UNBOUNDED", "", ""));
        $$ = res;
    }

;


connect_options:

    /* empty */ {
        res = new IR(kConnectOptions, OP3("", "", ""));
        $$ = res;
    }

    | WITH connect_option_list {
        auto tmp1 = $2;
        res = new IR(kConnectOptions, OP3("WITH", "", ""), tmp1);
        $$ = res;
    }

;


connect_option_list:

    connect_option_list connect_option {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kConnectOptionList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | connect_option {
        auto tmp1 = $1;
        res = new IR(kConnectOptionList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


connect_option:

    MAX_QUERIES_PER_HOUR ulong_num {
        auto tmp1 = $2;
        res = new IR(kConnectOption, OP3("MAX_QUERIES_PER_HOUR", "", ""), tmp1);
        $$ = res;
    }

    | MAX_UPDATES_PER_HOUR ulong_num {
        auto tmp1 = $2;
        res = new IR(kConnectOption, OP3("MAX_UPDATES_PER_HOUR", "", ""), tmp1);
        $$ = res;
    }

    | MAX_CONNECTIONS_PER_HOUR ulong_num {
        auto tmp1 = $2;
        res = new IR(kConnectOption, OP3("MAX_CONNECTIONS_PER_HOUR", "", ""), tmp1);
        $$ = res;
    }

    | MAX_USER_CONNECTIONS_SYM ulong_num {
        auto tmp1 = $2;
        res = new IR(kConnectOption, OP3("MAX_USER_CONNECTIONS", "", ""), tmp1);
        $$ = res;
    }

;


user_func:

    USER '(' ')' {
        res = new IR(kUserFunc, OP3("USER ( )", "", ""));
        $$ = res;
    }

;


ev_alter_on_schedule_completion:

    /* empty */ {
        res = new IR(kEvAlterOnScheduleCompletion, OP3("", "", ""));
        $$ = res;
    }

    | ON_SYM SCHEDULE_SYM ev_schedule_time {
        auto tmp1 = $3;
        res = new IR(kEvAlterOnScheduleCompletion, OP3("ON SCHEDULE", "", ""), tmp1);
        $$ = res;
    }

    | ev_on_completion {
        auto tmp1 = $1;
        res = new IR(kEvAlterOnScheduleCompletion, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ON_SYM SCHEDULE_SYM ev_schedule_time ev_on_completion {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kEvAlterOnScheduleCompletion, OP3("ON SCHEDULE", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_ev_rename_to:

    /* empty */ {
        res = new IR(kOptEvRenameTo, OP3("", "", ""));
        $$ = res;
    }

    | RENAME TO_SYM sp_name {
        auto tmp1 = $3;
        res = new IR(kOptEvRenameTo, OP3("RENAME TO", "", ""), tmp1);
        $$ = res;
    }

;


opt_ev_sql_stmt:

    /* empty*/ {
        res = new IR(kOptEvSqlStmt, OP3("", "", ""));
        $$ = res;
    }

    | DO_SYM ev_sql_stmt {
        auto tmp1 = $2;
        res = new IR(kOptEvSqlStmt, OP3("DO", "", ""), tmp1);
        $$ = res;
    }

;


ident_or_empty:

    /* empty */ {
        res = new IR(kIdentOrEmpty, OP3("", "", ""));
        $$ = res;
    }

    | ident {
        auto tmp1 = $1;
        res = new IR(kIdentOrEmpty, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_alter_table_actions:

    opt_alter_command_list {
        auto tmp1 = $1;
        res = new IR(kOptAlterTableActions, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | opt_alter_command_list alter_table_partition_options {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptAlterTableActions, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


standalone_alter_table_action:

    standalone_alter_commands {
        auto tmp1 = $1;
        res = new IR(kStandaloneAlterTableAction, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | alter_commands_modifier_list ',' standalone_alter_commands {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kStandaloneAlterTableAction, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


alter_table_partition_options:

    partition_clause {
        auto tmp1 = $1;
        res = new IR(kAlterTablePartitionOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | REMOVE_SYM PARTITIONING_SYM {
        res = new IR(kAlterTablePartitionOptions, OP3("REMOVE PARTITIONING", "", ""));
        $$ = res;
    }

;


opt_alter_command_list:

    /* empty */ {
        res = new IR(kOptAlterCommandList, OP3("", "", ""));
        $$ = res;
    }

    | alter_commands_modifier_list {
        auto tmp1 = $1;
        res = new IR(kOptAlterCommandList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | alter_list {
        auto tmp1 = $1;
        res = new IR(kOptAlterCommandList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | alter_commands_modifier_list ',' alter_list {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kOptAlterCommandList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


standalone_alter_commands:

    DISCARD_SYM TABLESPACE_SYM {
        res = new IR(kStandaloneAlterCommands, OP3("DISCARD TABLESPACE", "", ""));
        $$ = res;
    }

    | IMPORT TABLESPACE_SYM {
        res = new IR(kStandaloneAlterCommands, OP3("IMPORT TABLESPACE", "", ""));
        $$ = res;
    }

    | ADD PARTITION_SYM opt_no_write_to_binlog {
        auto tmp1 = $3;
        res = new IR(kStandaloneAlterCommands, OP3("ADD PARTITION", "", ""), tmp1);
        $$ = res;
    }

    | ADD PARTITION_SYM opt_no_write_to_binlog '(' part_def_list ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kStandaloneAlterCommands, OP3("ADD PARTITION", "(", ")"), tmp1, tmp2);
        $$ = res;
    }

    | ADD PARTITION_SYM opt_no_write_to_binlog PARTITIONS_SYM real_ulong_num {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kStandaloneAlterCommands, OP3("ADD PARTITION", "PARTITIONS", ""), tmp1, tmp2);
        $$ = res;
    }

    | DROP PARTITION_SYM ident_string_list {
        auto tmp1 = $3;
        res = new IR(kStandaloneAlterCommands, OP3("DROP PARTITION", "", ""), tmp1);
        $$ = res;
    }

    | REBUILD_SYM PARTITION_SYM opt_no_write_to_binlog all_or_alt_part_name_list {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kStandaloneAlterCommands, OP3("REBUILD PARTITION", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | OPTIMIZE PARTITION_SYM opt_no_write_to_binlog all_or_alt_part_name_list {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kStandaloneAlterCommands, OP3("OPTIMIZE PARTITION", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ANALYZE_SYM PARTITION_SYM opt_no_write_to_binlog all_or_alt_part_name_list {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kStandaloneAlterCommands, OP3("ANALYZE PARTITION", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | CHECK_SYM PARTITION_SYM all_or_alt_part_name_list opt_mi_check_types {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kStandaloneAlterCommands, OP3("CHECK PARTITION", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | REPAIR PARTITION_SYM opt_no_write_to_binlog all_or_alt_part_name_list opt_mi_repair_types {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kStandaloneAlterCommands_1, OP3("REPAIR PARTITION", "", ""), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kStandaloneAlterCommands, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | COALESCE PARTITION_SYM opt_no_write_to_binlog real_ulong_num {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kStandaloneAlterCommands, OP3("COALESCE PARTITION", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | TRUNCATE_SYM PARTITION_SYM all_or_alt_part_name_list {
        auto tmp1 = $3;
        res = new IR(kStandaloneAlterCommands, OP3("TRUNCATE PARTITION", "", ""), tmp1);
        $$ = res;
    }

    | REORGANIZE_SYM PARTITION_SYM opt_no_write_to_binlog {
        auto tmp1 = $3;
        res = new IR(kStandaloneAlterCommands, OP3("REORGANIZE PARTITION", "", ""), tmp1);
        $$ = res;
    }

    | REORGANIZE_SYM PARTITION_SYM opt_no_write_to_binlog ident_string_list INTO '(' part_def_list ')' {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kStandaloneAlterCommands_2, OP3("REORGANIZE PARTITION", "", "INTO ("), tmp1, tmp2);

        auto tmp3 = $7;
        res = new IR(kStandaloneAlterCommands, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | EXCHANGE_SYM PARTITION_SYM ident WITH TABLE_SYM table_ident opt_with_validation {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kStandaloneAlterCommands_3, OP3("EXCHANGE PARTITION", "WITH TABLE", ""), tmp1, tmp2);

        auto tmp3 = $7;
        res = new IR(kStandaloneAlterCommands, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | DISCARD_SYM PARTITION_SYM all_or_alt_part_name_list TABLESPACE_SYM {
        auto tmp1 = $3;
        res = new IR(kStandaloneAlterCommands, OP3("DISCARD PARTITION", "TABLESPACE", ""), tmp1);
        $$ = res;
    }

    | IMPORT PARTITION_SYM all_or_alt_part_name_list TABLESPACE_SYM {
        auto tmp1 = $3;
        res = new IR(kStandaloneAlterCommands, OP3("IMPORT PARTITION", "TABLESPACE", ""), tmp1);
        $$ = res;
    }

    | SECONDARY_LOAD_SYM {
        res = new IR(kStandaloneAlterCommands, OP3("SECONDARY_LOAD", "", ""));
        $$ = res;
    }

    | SECONDARY_UNLOAD_SYM {
        res = new IR(kStandaloneAlterCommands, OP3("SECONDARY_UNLOAD", "", ""));
        $$ = res;
    }

;


opt_with_validation:

    /* empty */ {
        res = new IR(kOptWithValidation, OP3("", "", ""));
        $$ = res;
    }

    | with_validation {
        auto tmp1 = $1;
        res = new IR(kOptWithValidation, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


with_validation:

    WITH VALIDATION_SYM {
        res = new IR(kWithValidation, OP3("WITH VALIDATION", "", ""));
        $$ = res;
    }

    | WITHOUT_SYM VALIDATION_SYM {
        res = new IR(kWithValidation, OP3("WITHOUT VALIDATION", "", ""));
        $$ = res;
    }

;


all_or_alt_part_name_list:

    ALL {
        res = new IR(kAllOrAltPartNameList, OP3("ALL", "", ""));
        $$ = res;
    }

    | ident_string_list {
        auto tmp1 = $1;
        res = new IR(kAllOrAltPartNameList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;

/*
End of management of partition commands
*/


alter_list:

    alter_list_item {
        auto tmp1 = $1;
        res = new IR(kAlterList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | alter_list ',' alter_list_item {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAlterList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | alter_list ',' alter_commands_modifier {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAlterList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | create_table_options_space_separated {
        auto tmp1 = $1;
        res = new IR(kAlterList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | alter_list ',' create_table_options_space_separated {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAlterList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


alter_commands_modifier_list:

    alter_commands_modifier {
        auto tmp1 = $1;
        res = new IR(kAlterCommandsModifierList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | alter_commands_modifier_list ',' alter_commands_modifier {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAlterCommandsModifierList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


alter_list_item:

    ADD opt_column ident field_def opt_references opt_place {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterListItem_1, OP3("ADD", "", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kAlterListItem_2, OP3("", "", ""), res, tmp3);

        auto tmp4 = $5;
        res = new IR(kAlterListItem_3, OP3("", "", ""), res, tmp4);

        auto tmp5 = $6;
        res = new IR(kAlterListItem, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

    | ADD opt_column '(' table_element_list ')' {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kAlterListItem, OP3("ADD", "(", ")"), tmp1, tmp2);
        $$ = res;
    }

    | ADD table_constraint_def {
        auto tmp1 = $2;
        res = new IR(kAlterListItem, OP3("ADD", "", ""), tmp1);
        $$ = res;
    }

    | CHANGE opt_column ident ident field_def opt_place {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterListItem_4, OP3("CHANGE", "", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kAlterListItem_5, OP3("", "", ""), res, tmp3);

        auto tmp4 = $5;
        res = new IR(kAlterListItem_6, OP3("", "", ""), res, tmp4);

        auto tmp5 = $6;
        res = new IR(kAlterListItem, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

    | MODIFY_SYM opt_column ident field_def opt_place {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterListItem_7, OP3("MODIFY", "", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kAlterListItem_8, OP3("", "", ""), res, tmp3);

        auto tmp4 = $5;
        res = new IR(kAlterListItem, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | DROP opt_column ident opt_restrict {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterListItem_9, OP3("DROP", "", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kAlterListItem, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | DROP FOREIGN KEY_SYM ident {
        auto tmp1 = $4;
        res = new IR(kAlterListItem, OP3("DROP FOREIGN KEY", "", ""), tmp1);
        $$ = res;
    }

    | DROP PRIMARY_SYM KEY_SYM {
        res = new IR(kAlterListItem, OP3("DROP PRIMARY KEY", "", ""));
        $$ = res;
    }

    | DROP key_or_index ident {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterListItem, OP3("DROP", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | DROP CHECK_SYM ident {
        auto tmp1 = $3;
        res = new IR(kAlterListItem, OP3("DROP CHECK", "", ""), tmp1);
        $$ = res;
    }

    | DROP CONSTRAINT ident {
        auto tmp1 = $3;
        res = new IR(kAlterListItem, OP3("DROP CONSTRAINT", "", ""), tmp1);
        $$ = res;
    }

    | DISABLE_SYM KEYS {
        res = new IR(kAlterListItem, OP3("DISABLE KEYS", "", ""));
        $$ = res;
    }

    | ENABLE_SYM KEYS {
        res = new IR(kAlterListItem, OP3("ENABLE KEYS", "", ""));
        $$ = res;
    }

    | ALTER opt_column ident SET_SYM DEFAULT_SYM signed_literal_or_null {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterListItem_10, OP3("ALTER", "", "SET DEFAULT"), tmp1, tmp2);

        auto tmp3 = $6;
        res = new IR(kAlterListItem, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER opt_column ident SET_SYM DEFAULT_SYM '(' expr ')' {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterListItem_11, OP3("ALTER", "", "SET DEFAULT ("), tmp1, tmp2);

        auto tmp3 = $7;
        res = new IR(kAlterListItem, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | ALTER opt_column ident DROP DEFAULT_SYM {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterListItem, OP3("ALTER", "", "DROP DEFAULT"), tmp1, tmp2);
        $$ = res;
    }

    | ALTER opt_column ident SET_SYM visibility {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterListItem_12, OP3("ALTER", "", "SET"), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kAlterListItem, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER INDEX_SYM ident visibility {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlterListItem, OP3("ALTER INDEX", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER CHECK_SYM ident constraint_enforcement {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlterListItem, OP3("ALTER CHECK", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER CONSTRAINT ident constraint_enforcement {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlterListItem, OP3("ALTER CONSTRAINT", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | RENAME opt_to table_ident {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterListItem, OP3("RENAME", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | RENAME key_or_index ident TO_SYM ident {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterListItem_13, OP3("RENAME", "", "TO"), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kAlterListItem, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | RENAME COLUMN_SYM ident TO_SYM ident {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kAlterListItem, OP3("RENAME COLUMN", "TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | CONVERT_SYM TO_SYM character_set charset_name opt_collate {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlterListItem_14, OP3("CONVERT TO", "", ""), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kAlterListItem, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | CONVERT_SYM TO_SYM character_set DEFAULT_SYM opt_collate {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kAlterListItem, OP3("CONVERT TO", "DEFAULT", ""), tmp1, tmp2);
        $$ = res;
    }

    | FORCE_SYM {
        res = new IR(kAlterListItem, OP3("FORCE", "", ""));
        $$ = res;
    }

    | ORDER_SYM BY alter_order_list {
        auto tmp1 = $3;
        res = new IR(kAlterListItem, OP3("ORDER BY", "", ""), tmp1);
        $$ = res;
    }

;


alter_commands_modifier:

    alter_algorithm_option {
        auto tmp1 = $1;
        res = new IR(kAlterCommandsModifier, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | alter_lock_option {
        auto tmp1 = $1;
        res = new IR(kAlterCommandsModifier, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | with_validation {
        auto tmp1 = $1;
        res = new IR(kAlterCommandsModifier, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_index_lock_and_algorithm:

    /* Empty. */ {
        res = new IR(kOptIndexLockAndAlgorithm, OP3("", "", ""));
        $$ = res;
    }

    | alter_lock_option {
        auto tmp1 = $1;
        res = new IR(kOptIndexLockAndAlgorithm, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | alter_algorithm_option {
        auto tmp1 = $1;
        res = new IR(kOptIndexLockAndAlgorithm, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | alter_lock_option alter_algorithm_option {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptIndexLockAndAlgorithm, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | alter_algorithm_option alter_lock_option {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptIndexLockAndAlgorithm, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


alter_algorithm_option:

    ALGORITHM_SYM opt_equal alter_algorithm_option_value {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterAlgorithmOption, OP3("ALGORITHM", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


alter_algorithm_option_value:

    DEFAULT_SYM {
        res = new IR(kAlterAlgorithmOptionValue, OP3("DEFAULT", "", ""));
        $$ = res;
    }

    | ident {
        auto tmp1 = $1;
        res = new IR(kAlterAlgorithmOptionValue, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


alter_lock_option:

    LOCK_SYM opt_equal alter_lock_option_value {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterLockOption, OP3("LOCK", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


alter_lock_option_value:

    DEFAULT_SYM {
        res = new IR(kAlterLockOptionValue, OP3("DEFAULT", "", ""));
        $$ = res;
    }

    | ident {
        auto tmp1 = $1;
        res = new IR(kAlterLockOptionValue, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_column:

    /* empty */ {
        res = new IR(kOptColumn, OP3("", "", ""));
        $$ = res;
    }

    | COLUMN_SYM {
        res = new IR(kOptColumn, OP3("COLUMN", "", ""));
        $$ = res;
    }

;


opt_ignore:

    /* empty */ {
        res = new IR(kOptIgnore, OP3("", "", ""));
        $$ = res;
    }

    | IGNORE_SYM {
        res = new IR(kOptIgnore, OP3("IGNORE", "", ""));
        $$ = res;
    }

;


opt_restrict:

    /* empty */ {
        res = new IR(kOptRestrict, OP3("", "", ""));
        $$ = res;
    }

    | RESTRICT {
        res = new IR(kOptRestrict, OP3("RESTRICT", "", ""));
        $$ = res;
    }

    | CASCADE {
        res = new IR(kOptRestrict, OP3("CASCADE", "", ""));
        $$ = res;
    }

;


opt_place:

    /* empty */ {
        res = new IR(kOptPlace, OP3("", "", ""));
        $$ = res;
    }

    | AFTER_SYM ident {
        auto tmp1 = $2;
        res = new IR(kOptPlace, OP3("AFTER", "", ""), tmp1);
        $$ = res;
    }

    | FIRST_SYM {
        res = new IR(kOptPlace, OP3("FIRST", "", ""));
        $$ = res;
    }

;


opt_to:

    /* empty */ {
        res = new IR(kOptTo, OP3("", "", ""));
        $$ = res;
    }

    | TO_SYM {
        res = new IR(kOptTo, OP3("TO", "", ""));
        $$ = res;
    }

    | EQ {
        res = new IR(kOptTo, OP3("=", "", ""));
        $$ = res;
    }

    | AS {
        res = new IR(kOptTo, OP3("AS", "", ""));
        $$ = res;
    }

;


group_replication:

    group_replication_start opt_group_replication_start_options {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kGroupReplication, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | STOP_SYM GROUP_REPLICATION {
        res = new IR(kGroupReplication, OP3("STOP GROUP_REPLICATION", "", ""));
        $$ = res;
    }

;


group_replication_start:

    START_SYM GROUP_REPLICATION {
        res = new IR(kGroupReplicationStart, OP3("START GROUP_REPLICATION", "", ""));
        $$ = res;
    }

;


opt_group_replication_start_options:

    /* empty */ {
        res = new IR(kOptGroupReplicationStartOptions, OP3("", "", ""));
        $$ = res;
    }

    | group_replication_start_options {
        auto tmp1 = $1;
        res = new IR(kOptGroupReplicationStartOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


group_replication_start_options:

    group_replication_start_option {
        auto tmp1 = $1;
        res = new IR(kGroupReplicationStartOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | group_replication_start_options ',' group_replication_start_option {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kGroupReplicationStartOptions, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


group_replication_start_option:

    group_replication_user {
        auto tmp1 = $1;
        res = new IR(kGroupReplicationStartOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | group_replication_password {
        auto tmp1 = $1;
        res = new IR(kGroupReplicationStartOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | group_replication_plugin_auth {
        auto tmp1 = $1;
        res = new IR(kGroupReplicationStartOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


group_replication_user:

    USER EQ TEXT_STRING_sys_nonewline {
        auto tmp1 = $3;
        res = new IR(kGroupReplicationUser, OP3("USER =", "", ""), tmp1);
        $$ = res;
    }

;


group_replication_password:

    PASSWORD EQ TEXT_STRING_sys_nonewline {
        auto tmp1 = $3;
        res = new IR(kGroupReplicationPassword, OP3("PASSWORD =", "", ""), tmp1);
        $$ = res;
    }

;


group_replication_plugin_auth:

    DEFAULT_AUTH_SYM EQ TEXT_STRING_sys_nonewline {
        auto tmp1 = $3;
        res = new IR(kGroupReplicationPluginAuth, OP3("DEFAULT_AUTH =", "", ""), tmp1);
        $$ = res;
    }

;


replica:

    SLAVE {
        res = new IR(kReplica, OP3("SLAVE", "", ""));
        $$ = res;
    }

    | REPLICA_SYM {
        res = new IR(kReplica, OP3("REPLICA", "", ""));
        $$ = res;
    }

;


stop_replica_stmt:

    STOP_SYM replica opt_replica_thread_option_list opt_channel {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kStopReplicaStmt_1, OP3("STOP", "", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kStopReplicaStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


start_replica_stmt:

    START_SYM replica opt_replica_thread_option_list {} opt_replica_until opt_user_option opt_password_option opt_default_auth_option opt_plugin_dir_option {} opt_channel {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kStartReplicaStmt_1, OP3("START", "", ""), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kStartReplicaStmt_2, OP3("", "", ""), res, tmp3);

        auto tmp4 = $6;
        res = new IR(kStartReplicaStmt_3, OP3("", "", ""), res, tmp4);

        auto tmp5 = $7;
        res = new IR(kStartReplicaStmt_4, OP3("", "", ""), res, tmp5);

        auto tmp6 = $8;
        res = new IR(kStartReplicaStmt_5, OP3("", "", ""), res, tmp6);

        auto tmp7 = $9;
        res = new IR(kStartReplicaStmt_6, OP3("", "", ""), res, tmp7);

        auto tmp8 = $11;
        res = new IR(kStartReplicaStmt, OP3("", "", ""), res, tmp8);
        $$ = res;
    }

;


start:

    START_SYM TRANSACTION_SYM opt_start_transaction_option_list {
        auto tmp1 = $3;
        res = new IR(kStart, OP3("START TRANSACTION", "", ""), tmp1);
        $$ = res;
    }

;


opt_start_transaction_option_list:

    /* empty */ {
        res = new IR(kOptStartTransactionOptionList, OP3("", "", ""));
        $$ = res;
    }

    | start_transaction_option_list {
        auto tmp1 = $1;
        res = new IR(kOptStartTransactionOptionList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


start_transaction_option_list:

    start_transaction_option {
        auto tmp1 = $1;
        res = new IR(kStartTransactionOptionList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | start_transaction_option_list ',' start_transaction_option {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kStartTransactionOptionList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


start_transaction_option:

    WITH CONSISTENT_SYM SNAPSHOT_SYM {
        res = new IR(kStartTransactionOption, OP3("WITH CONSISTENT SNAPSHOT", "", ""));
        $$ = res;
    }

    | READ_SYM ONLY_SYM {
        res = new IR(kStartTransactionOption, OP3("READ ONLY", "", ""));
        $$ = res;
    }

    | READ_SYM WRITE_SYM {
        res = new IR(kStartTransactionOption, OP3("READ WRITE", "", ""));
        $$ = res;
    }

;


opt_user_option:

    {} {
        res = new IR(kOptUserOption, OP3("", "", ""));
        $$ = res;
    }

    | USER EQ TEXT_STRING_sys {
        auto tmp1 = $3;
        res = new IR(kOptUserOption, OP3("USER =", "", ""), tmp1);
        $$ = res;
    }

;


opt_password_option:

    {} {
        res = new IR(kOptPasswordOption, OP3("", "", ""));
        $$ = res;
    }

    | PASSWORD EQ TEXT_STRING_sys {
        auto tmp1 = $3;
        res = new IR(kOptPasswordOption, OP3("PASSWORD =", "", ""), tmp1);
        $$ = res;
    }

;


opt_default_auth_option:

    {} {
        res = new IR(kOptDefaultAuthOption, OP3("", "", ""));
        $$ = res;
    }

    | DEFAULT_AUTH_SYM EQ TEXT_STRING_sys {
        auto tmp1 = $3;
        res = new IR(kOptDefaultAuthOption, OP3("DEFAULT_AUTH =", "", ""), tmp1);
        $$ = res;
    }

;


opt_plugin_dir_option:

    {} {
        res = new IR(kOptPluginDirOption, OP3("", "", ""));
        $$ = res;
    }

    | PLUGIN_DIR_SYM EQ TEXT_STRING_sys {
        auto tmp1 = $3;
        res = new IR(kOptPluginDirOption, OP3("PLUGIN_DIR =", "", ""), tmp1);
        $$ = res;
    }

;


opt_replica_thread_option_list:

    /* empty */ {
        res = new IR(kOptReplicaThreadOptionList, OP3("", "", ""));
        $$ = res;
    }

    | replica_thread_option_list {
        auto tmp1 = $1;
        res = new IR(kOptReplicaThreadOptionList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


replica_thread_option_list:

    replica_thread_option {
        auto tmp1 = $1;
        res = new IR(kReplicaThreadOptionList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | replica_thread_option_list ',' replica_thread_option {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kReplicaThreadOptionList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


replica_thread_option:

    SQL_THREAD {
        res = new IR(kReplicaThreadOption, OP3("SQL_THREAD", "", ""));
        $$ = res;
    }

    | RELAY_THREAD {
        res = new IR(kReplicaThreadOption, OP3("IO_THREAD", "", ""));
        $$ = res;
    }

;


opt_replica_until:

    /*empty*/ {
        res = new IR(kOptReplicaUntil, OP3("", "", ""));
        $$ = res;
    }

    | UNTIL_SYM replica_until {
        auto tmp1 = $2;
        res = new IR(kOptReplicaUntil, OP3("UNTIL", "", ""), tmp1);
        $$ = res;
    }

;


replica_until:

    source_file_def {
        auto tmp1 = $1;
        res = new IR(kReplicaUntil, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | replica_until ',' source_file_def {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kReplicaUntil, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | SQL_BEFORE_GTIDS EQ TEXT_STRING_sys {
        auto tmp1 = $3;
        res = new IR(kReplicaUntil, OP3("SQL_BEFORE_GTIDS =", "", ""), tmp1);
        $$ = res;
    }

    | SQL_AFTER_GTIDS EQ TEXT_STRING_sys {
        auto tmp1 = $3;
        res = new IR(kReplicaUntil, OP3("SQL_AFTER_GTIDS =", "", ""), tmp1);
        $$ = res;
    }

    | SQL_AFTER_MTS_GAPS {
        res = new IR(kReplicaUntil, OP3("SQL_AFTER_MTS_GAPS", "", ""));
        $$ = res;
    }

;


checksum:

    CHECKSUM_SYM table_or_tables table_list opt_checksum_type {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kChecksum_1, OP3("CHECKSUM", "", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kChecksum, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


opt_checksum_type:

    /* empty */ {
        res = new IR(kOptChecksumType, OP3("", "", ""));
        $$ = res;
    }

    | QUICK {
        res = new IR(kOptChecksumType, OP3("QUICK", "", ""));
        $$ = res;
    }

    | EXTENDED_SYM {
        res = new IR(kOptChecksumType, OP3("EXTENDED", "", ""));
        $$ = res;
    }

;


repair_table_stmt:

    REPAIR opt_no_write_to_binlog table_or_tables table_list opt_mi_repair_types {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kRepairTableStmt_1, OP3("REPAIR", "", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kRepairTableStmt_2, OP3("", "", ""), res, tmp3);

        auto tmp4 = $5;
        res = new IR(kRepairTableStmt, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


opt_mi_repair_types:

    /* empty */ {
        res = new IR(kOptMiRepairTypes, OP3("", "", ""));
        $$ = res;
    }

    | mi_repair_types {
        auto tmp1 = $1;
        res = new IR(kOptMiRepairTypes, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


mi_repair_types:

    mi_repair_type {
        auto tmp1 = $1;
        res = new IR(kMiRepairTypes, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | mi_repair_types mi_repair_type {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kMiRepairTypes, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


mi_repair_type:

    QUICK {
        res = new IR(kMiRepairType, OP3("QUICK", "", ""));
        $$ = res;
    }

    | EXTENDED_SYM {
        res = new IR(kMiRepairType, OP3("EXTENDED", "", ""));
        $$ = res;
    }

    | USE_FRM {
        res = new IR(kMiRepairType, OP3("USE_FRM", "", ""));
        $$ = res;
    }

;


analyze_table_stmt:

    ANALYZE_SYM opt_no_write_to_binlog table_or_tables table_list opt_histogram {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAnalyzeTableStmt_1, OP3("ANALYZE", "", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kAnalyzeTableStmt_2, OP3("", "", ""), res, tmp3);

        auto tmp4 = $5;
        res = new IR(kAnalyzeTableStmt, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


opt_num_buckets:

    /* empty */ {
        res = new IR(kOptNumBuckets, OP3("", "", ""));
        $$ = res;
    }

    | WITH NUM BUCKETS_SYM {
        res = new IR(kOptNumBuckets, OP3("WITH NUM BUCKETS", "", ""));
        $$ = res;
    }

;


opt_histogram:

    /* empty */ {
        res = new IR(kOptHistogram, OP3("", "", ""));
        $$ = res;
    }

    | UPDATE_SYM HISTOGRAM_SYM ON_SYM ident_string_list opt_num_buckets {
        auto tmp1 = $4;
        auto tmp2 = $5;
        res = new IR(kOptHistogram, OP3("UPDATE HISTOGRAM ON", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | DROP HISTOGRAM_SYM ON_SYM ident_string_list {
        auto tmp1 = $4;
        res = new IR(kOptHistogram, OP3("DROP HISTOGRAM ON", "", ""), tmp1);
        $$ = res;
    }

;


binlog_base64_event:

    BINLOG_SYM TEXT_STRING_sys {
        auto tmp1 = $2;
        res = new IR(kBinlogBase64Event, OP3("BINLOG", "", ""), tmp1);
        $$ = res;
    }

;


check_table_stmt:

    CHECK_SYM table_or_tables table_list opt_mi_check_types {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCheckTableStmt_1, OP3("CHECK", "", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kCheckTableStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


opt_mi_check_types:

    /* empty */ {
        res = new IR(kOptMiCheckTypes, OP3("", "", ""));
        $$ = res;
    }

    | mi_check_types {
        auto tmp1 = $1;
        res = new IR(kOptMiCheckTypes, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


mi_check_types:

    mi_check_type {
        auto tmp1 = $1;
        res = new IR(kMiCheckTypes, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | mi_check_type mi_check_types {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kMiCheckTypes, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


mi_check_type:

    QUICK {
        res = new IR(kMiCheckType, OP3("QUICK", "", ""));
        $$ = res;
    }

    | FAST_SYM {
        res = new IR(kMiCheckType, OP3("FAST", "", ""));
        $$ = res;
    }

    | MEDIUM_SYM {
        res = new IR(kMiCheckType, OP3("MEDIUM", "", ""));
        $$ = res;
    }

    | EXTENDED_SYM {
        res = new IR(kMiCheckType, OP3("EXTENDED", "", ""));
        $$ = res;
    }

    | CHANGED {
        res = new IR(kMiCheckType, OP3("CHANGED", "", ""));
        $$ = res;
    }

    | FOR_SYM UPGRADE_SYM {
        res = new IR(kMiCheckType, OP3("FOR UPGRADE", "", ""));
        $$ = res;
    }

;


optimize_table_stmt:

    OPTIMIZE opt_no_write_to_binlog table_or_tables table_list {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kOptimizeTableStmt_1, OP3("OPTIMIZE", "", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kOptimizeTableStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


opt_no_write_to_binlog:

    /* empty */ {
        res = new IR(kOptNoWriteToBinlog, OP3("", "", ""));
        $$ = res;
    }

    | NO_WRITE_TO_BINLOG {
        res = new IR(kOptNoWriteToBinlog, OP3("NO_WRITE_TO_BINLOG", "", ""));
        $$ = res;
    }

    | LOCAL_SYM {
        res = new IR(kOptNoWriteToBinlog, OP3("LOCAL", "", ""));
        $$ = res;
    }

;


rename:

    RENAME table_or_tables {} table_to_table_list {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kRename, OP3("RENAME", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | RENAME USER rename_list {
        auto tmp1 = $3;
        res = new IR(kRename, OP3("RENAME USER", "", ""), tmp1);
        $$ = res;
    }

;


rename_list:

    user TO_SYM user {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kRenameList, OP3("", "TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | rename_list ',' user TO_SYM user {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kRenameList_1, OP3("", ",", "TO"), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kRenameList, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


table_to_table_list:

    table_to_table {
        auto tmp1 = $1;
        res = new IR(kTableToTableList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | table_to_table_list ',' table_to_table {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTableToTableList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


table_to_table:

    table_ident TO_SYM table_ident {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTableToTable, OP3("", "TO", ""), tmp1, tmp2);
        $$ = res;
    }

;


keycache_stmt:

    CACHE_SYM INDEX_SYM keycache_list IN_SYM key_cache_name {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kKeycacheStmt, OP3("CACHE INDEX", "IN", ""), tmp1, tmp2);
        $$ = res;
    }

    | CACHE_SYM INDEX_SYM table_ident adm_partition opt_cache_key_list IN_SYM key_cache_name {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kKeycacheStmt_1, OP3("CACHE INDEX", "", ""), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kKeycacheStmt_2, OP3("", "", "IN"), res, tmp3);

        auto tmp4 = $7;
        res = new IR(kKeycacheStmt, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


keycache_list:

    assign_to_keycache {
        auto tmp1 = $1;
        res = new IR(kKeycacheList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keycache_list ',' assign_to_keycache {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kKeycacheList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


assign_to_keycache:

    table_ident opt_cache_key_list {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAssignToKeycache, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


key_cache_name:

    ident {
        auto tmp1 = $1;
        res = new IR(kKeyCacheName, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DEFAULT_SYM {
        res = new IR(kKeyCacheName, OP3("DEFAULT", "", ""));
        $$ = res;
    }

;


preload_stmt:

    LOAD INDEX_SYM INTO CACHE_SYM table_ident adm_partition opt_cache_key_list opt_ignore_leaves {
        auto tmp1 = $5;
        auto tmp2 = $6;
        res = new IR(kPreloadStmt_1, OP3("LOAD INDEX INTO CACHE", "", ""), tmp1, tmp2);

        auto tmp3 = $7;
        res = new IR(kPreloadStmt_2, OP3("", "", ""), res, tmp3);

        auto tmp4 = $8;
        res = new IR(kPreloadStmt, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | LOAD INDEX_SYM INTO CACHE_SYM preload_list {
        auto tmp1 = $5;
        res = new IR(kPreloadStmt, OP3("LOAD INDEX INTO CACHE", "", ""), tmp1);
        $$ = res;
    }

;


preload_list:

    preload_keys {
        auto tmp1 = $1;
        res = new IR(kPreloadList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | preload_list ',' preload_keys {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kPreloadList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


preload_keys:

    table_ident opt_cache_key_list opt_ignore_leaves {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kPreloadKeys_1, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kPreloadKeys, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


adm_partition:

    PARTITION_SYM '(' all_or_alt_part_name_list ')' {
        auto tmp1 = $3;
        res = new IR(kAdmPartition, OP3("PARTITION (", ")", ""), tmp1);
        $$ = res;
    }

;


opt_cache_key_list:

    /* empty */ {
        res = new IR(kOptCacheKeyList, OP3("", "", ""));
        $$ = res;
    }

    | key_or_index '(' opt_key_usage_list ')' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kOptCacheKeyList, OP3("", "(", ")"), tmp1, tmp2);
        $$ = res;
    }

;


opt_ignore_leaves:

    /* empty */ {
        res = new IR(kOptIgnoreLeaves, OP3("", "", ""));
        $$ = res;
    }

    | IGNORE_SYM LEAVES {
        res = new IR(kOptIgnoreLeaves, OP3("IGNORE LEAVES", "", ""));
        $$ = res;
    }

;


select_stmt:

    query_expression {
        auto tmp1 = $1;
        res = new IR(kSelectStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | query_expression locking_clause_list {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSelectStmt, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | query_expression_parens {
        auto tmp1 = $1;
        res = new IR(kSelectStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | select_stmt_with_into {
        auto tmp1 = $1;
        res = new IR(kSelectStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

;

/*
MySQL has a syntax extension that allows into clauses in any one of two
places. They may appear either before the from clause or at the end. All in
a top-level select statement. This extends the standard syntax in two
ways. First, we don't have the restriction that the result can contain only
one row: the into clause might be INTO OUTFILE/DUMPFILE in which case any
number of rows is allowed. Hence MySQL does not have any special case for
the standard's <select statement: single row>. Secondly, and this has more
severe implications for the parser, it makes the grammar ambiguous, because
in a from-clause-less select statement with an into clause, it is not clear
whether the into clause is the leading or the trailing one.

While it's possible to write an unambiguous grammar, it would force us to
duplicate the entire <select statement> syntax all the way down to the <into
clause>. So instead we solve it by writing an ambiguous grammar and use
precedence rules to sort out the shift/reduce conflict.

The problem is when the parser has seen SELECT <select list>, and sees an
INTO token. It can now either shift it or reduce what it has to a table-less
query expression. If it shifts the token, it will accept seeing a FROM token
next and hence the INTO will be interpreted as the leading INTO. If it
reduces what it has seen to a table-less select, however, it will interpret
INTO as the trailing into. But what if the next token is FROM? Obviously,
we want to always shift INTO. We do this by two precedence declarations: We
make the INTO token right-associative, and we give it higher precedence than
an empty from clause, using the artificial token EMPTY_FROM_CLAUSE.

The remaining problem is that now we allow the leading INTO anywhere, when
it should be allowed on the top level only. We solve this by manually
throwing parse errors whenever we reduce a nested query expression if it
contains an into clause.
*/

select_stmt_with_into:

    '(' select_stmt_with_into ')' {
        auto tmp1 = $2;
        res = new IR(kSelectStmtWithInto, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

    | query_expression into_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSelectStmtWithInto, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | query_expression into_clause locking_clause_list {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSelectStmtWithInto_1, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kSelectStmtWithInto, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | query_expression locking_clause_list into_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSelectStmtWithInto_2, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kSelectStmtWithInto, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | query_expression_parens into_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSelectStmtWithInto, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;

/**
A <query_expression> within parentheses can be used as an <expr>. Now,
because both a <query_expression> and an <expr> can appear syntactically
within any number of parentheses, we get an ambiguous grammar: Where do the
parentheses belong? Techically, we have to tell Bison by which rule to
reduce the extra pair of parentheses. We solve it in a somewhat tedious way
by defining a query_expression so that it can't have enclosing
parentheses. This forces us to be very explicit about exactly where we allow
parentheses; while the standard defines only one rule for <query expression>
parentheses, we have to do it in several places. But this is a blessing in
disguise, as we are able to define our syntax in a more fine-grained manner,
and this is necessary in order to support some MySQL extensions, for example
as in the last two sub-rules here.

Even if we define a query_expression not to have outer parentheses, we still
get a shift/reduce conflict for the <subquery> rule, but we solve this by
using an artifical token SUBQUERY_AS_EXPR that has less priority than
parentheses. This ensures that the parser consumes as many parentheses as it
can, and only when that fails will it try to reduce, and by then it will be
clear from the lookahead token whether we have a subquery or just a
query_expression within parentheses. For example, if the lookahead token is
UNION it's just a query_expression within parentheses and the parentheses
don't mean it's a subquery. If the next token is PLUS, we know it must be an
<expr> and the parentheses really mean it's a subquery.

A word about CTE's: The rules below are duplicated, one with a with_clause
and one without, instead of using a single rule with an opt_with_clause. The
reason we do this is because it would make Bison try to cram both rules into
a single state, where it would have to decide whether to reduce a with_clause
before seeing the rest of the input. This way we force Bison to parse the
entire query expression before trying to reduce.
*/

query_expression:

    query_expression_body opt_order_clause opt_limit_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kQueryExpression_1, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kQueryExpression, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | with_clause query_expression_body opt_order_clause opt_limit_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kQueryExpression_2, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kQueryExpression_3, OP3("", "", ""), res, tmp3);

        auto tmp4 = $4;
        res = new IR(kQueryExpression, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | query_expression_parens order_clause opt_limit_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kQueryExpression_4, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kQueryExpression, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | with_clause query_expression_parens order_clause opt_limit_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kQueryExpression_5, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kQueryExpression_6, OP3("", "", ""), res, tmp3);

        auto tmp4 = $4;
        res = new IR(kQueryExpression, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | query_expression_parens limit_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kQueryExpression, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | with_clause query_expression_parens limit_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kQueryExpression_7, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kQueryExpression, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | with_clause query_expression_parens {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kQueryExpression, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


query_expression_body:

    query_primary {
        auto tmp1 = $1;
        res = new IR(kQueryExpressionBody, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | query_expression_body UNION_SYM union_option query_primary {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kQueryExpressionBody_1, OP3("", "UNION", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kQueryExpressionBody, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | query_expression_parens UNION_SYM union_option query_primary {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kQueryExpressionBody_2, OP3("", "UNION", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kQueryExpressionBody, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | query_expression_body UNION_SYM union_option query_expression_parens {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kQueryExpressionBody_3, OP3("", "UNION", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kQueryExpressionBody, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | query_expression_parens UNION_SYM union_option query_expression_parens {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kQueryExpressionBody_4, OP3("", "UNION", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kQueryExpressionBody, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;



query_expression_parens:

    '(' query_expression_parens ')' {
        auto tmp1 = $2;
        res = new IR(kQueryExpressionParens, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

    | '(' query_expression')' {
        auto tmp1 = $2;
        res = new IR(kQueryExpressionParens, OP3("( QUERY_EXPRESSION')'", "", ""), tmp1);
        $$ = res;
    }

    | '(' query_expression locking_clause_list')' {
        auto tmp1 = $2;
        res = new IR(kQueryExpressionParens, OP3("(", "LOCKING_CLAUSE_LIST')'", ""), tmp1);
        $$ = res;
    }

;


query_primary:

    query_specification {
        auto tmp1 = $1;
        res = new IR(kQueryPrimary, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | table_value_constructor {
        auto tmp1 = $1;
        res = new IR(kQueryPrimary, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | explicit_table {
        auto tmp1 = $1;
        res = new IR(kQueryPrimary, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


query_specification:

    SELECT_SYM select_options select_item_list into_clause opt_from_clause opt_where_clause opt_group_clause opt_having_clause opt_window_clause {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kQuerySpecification_1, OP3("SELECT", "", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kQuerySpecification_2, OP3("", "", ""), res, tmp3);

        auto tmp4 = $5;
        res = new IR(kQuerySpecification_3, OP3("", "", ""), res, tmp4);

        auto tmp5 = $6;
        res = new IR(kQuerySpecification_4, OP3("", "", ""), res, tmp5);

        auto tmp6 = $7;
        res = new IR(kQuerySpecification_5, OP3("", "", ""), res, tmp6);

        auto tmp7 = $8;
        res = new IR(kQuerySpecification_6, OP3("", "", ""), res, tmp7);

        auto tmp8 = $9;
        res = new IR(kQuerySpecification, OP3("", "", ""), res, tmp8);
        $$ = res;
    }

    | SELECT_SYM select_options select_item_list opt_from_clause opt_where_clause opt_group_clause opt_having_clause opt_window_clause {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kQuerySpecification_7, OP3("SELECT", "", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kQuerySpecification_8, OP3("", "", ""), res, tmp3);

        auto tmp4 = $5;
        res = new IR(kQuerySpecification_9, OP3("", "", ""), res, tmp4);

        auto tmp5 = $6;
        res = new IR(kQuerySpecification_10, OP3("", "", ""), res, tmp5);

        auto tmp6 = $7;
        res = new IR(kQuerySpecification_11, OP3("", "", ""), res, tmp6);

        auto tmp7 = $8;
        res = new IR(kQuerySpecification, OP3("", "", ""), res, tmp7);
        $$ = res;
    }

;


opt_from_clause:

    %prec EMPTY_FROM_CLAUSE {

    }

    | from_clause {
        auto tmp1 = $1;
        res = new IR(kOptFromClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


from_clause:

    FROM from_tables {
        auto tmp1 = $2;
        res = new IR(kFromClause, OP3("FROM", "", ""), tmp1);
        $$ = res;
    }

;


from_tables:

    DUAL_SYM {
        res = new IR(kFromTables, OP3("DUAL", "", ""));
        $$ = res;
    }

    | table_reference_list {
        auto tmp1 = $1;
        res = new IR(kFromTables, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


table_reference_list:

    table_reference {
        auto tmp1 = $1;
        res = new IR(kTableReferenceList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | table_reference_list ',' table_reference {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTableReferenceList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


table_value_constructor:

    VALUES values_row_list {
        auto tmp1 = $2;
        res = new IR(kTableValueConstructor, OP3("VALUES", "", ""), tmp1);
        $$ = res;
    }

;


explicit_table:

    TABLE_SYM table_ident {
        auto tmp1 = $2;
        res = new IR(kExplicitTable, OP3("TABLE", "", ""), tmp1);
        $$ = res;
    }

;


select_options:

    /* empty*/ {
        res = new IR(kSelectOptions, OP3("", "", ""));
        $$ = res;
    }

    | select_option_list {
        auto tmp1 = $1;
        res = new IR(kSelectOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


select_option_list:

    select_option_list select_option {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSelectOptionList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | select_option {
        auto tmp1 = $1;
        res = new IR(kSelectOptionList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


select_option:

    query_spec_option {
        auto tmp1 = $1;
        res = new IR(kSelectOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | SQL_NO_CACHE_SYM {
        res = new IR(kSelectOption, OP3("SQL_NO_CACHE", "", ""));
        $$ = res;
    }

;


locking_clause_list:

    locking_clause_list locking_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kLockingClauseList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | locking_clause {
        auto tmp1 = $1;
        res = new IR(kLockingClauseList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


locking_clause:

    FOR_SYM lock_strength opt_locked_row_action {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kLockingClause, OP3("FOR", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | FOR_SYM lock_strength table_locking_list opt_locked_row_action {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kLockingClause_1, OP3("FOR", "", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kLockingClause, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | LOCK_SYM IN_SYM SHARE_SYM MODE_SYM {
        res = new IR(kLockingClause, OP3("LOCK IN SHARE MODE", "", ""));
        $$ = res;
    }

;


lock_strength:

    UPDATE_SYM {
        res = new IR(kLockStrength, OP3("UPDATE", "", ""));
        $$ = res;
    }

    | SHARE_SYM {
        res = new IR(kLockStrength, OP3("SHARE", "", ""));
        $$ = res;
    }

;


table_locking_list:

    OF_SYM table_alias_ref_list {
        auto tmp1 = $2;
        res = new IR(kTableLockingList, OP3("OF", "", ""), tmp1);
        $$ = res;
    }

;


opt_locked_row_action:

    /* Empty */ {
        res = new IR(kOptLockedRowAction, OP3("", "", ""));
        $$ = res;
    }

    | locked_row_action {
        auto tmp1 = $1;
        res = new IR(kOptLockedRowAction, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


locked_row_action:

    SKIP_SYM LOCKED_SYM {
        res = new IR(kLockedRowAction, OP3("SKIP LOCKED", "", ""));
        $$ = res;
    }

    | NOWAIT_SYM {
        res = new IR(kLockedRowAction, OP3("NOWAIT", "", ""));
        $$ = res;
    }

;


select_item_list:

    select_item_list ',' select_item {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSelectItemList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | select_item {
        auto tmp1 = $1;
        res = new IR(kSelectItemList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '*' {
        res = new IR(kSelectItemList, OP3("*", "", ""));
        $$ = res;
    }

;


select_item:

    table_wild {
        auto tmp1 = $1;
        res = new IR(kSelectItem, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | expr select_alias {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSelectItem, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;



select_alias:

    /* empty */ {
        res = new IR(kSelectAlias, OP3("", "", ""));
        $$ = res;
    }

    | AS ident {
        auto tmp1 = $2;
        res = new IR(kSelectAlias, OP3("AS", "", ""), tmp1);
        $$ = res;
    }

    | AS TEXT_STRING_validated {
        auto tmp1 = $2;
        res = new IR(kSelectAlias, OP3("AS", "", ""), tmp1);
        $$ = res;
    }

    | ident {
        auto tmp1 = $1;
        res = new IR(kSelectAlias, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | TEXT_STRING_validated {
        auto tmp1 = $1;
        res = new IR(kSelectAlias, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


optional_braces:

    /* empty */ {
        res = new IR(kOptionalBraces, OP3("", "", ""));
        $$ = res;
    }

    | '(' ')' {
        res = new IR(kOptionalBraces, OP3("( )", "", ""));
        $$ = res;
    }

;

/* all possible expressions */

expr:

    expr or expr %prec OR_SYM {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kExpr_1, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kExpr, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | expr XOR expr %prec XOR {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kExpr, OP3("", "XOR", ""), tmp1, tmp2);
        $$ = res;
    }

    | expr and expr %prec AND_SYM {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kExpr_2, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kExpr, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | NOT_SYM expr %prec NOT_SYM {
        auto tmp1 = $2;
        res = new IR(kExpr, OP3("NOT", "", ""), tmp1);
        $$ = res;
    }

    | bool_pri IS TRUE_SYM %prec IS {
        auto tmp1 = $1;
        res = new IR(kExpr, OP3("", "IS TRUE", ""), tmp1);
        $$ = res;
    }

    | bool_pri IS not TRUE_SYM %prec IS {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kExpr, OP3("", "IS", "TRUE"), tmp1, tmp2);
        $$ = res;
    }

    | bool_pri IS FALSE_SYM %prec IS {
        auto tmp1 = $1;
        res = new IR(kExpr, OP3("", "IS FALSE", ""), tmp1);
        $$ = res;
    }

    | bool_pri IS not FALSE_SYM %prec IS {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kExpr, OP3("", "IS", "FALSE"), tmp1, tmp2);
        $$ = res;
    }

    | bool_pri IS UNKNOWN_SYM %prec IS {
        auto tmp1 = $1;
        res = new IR(kExpr, OP3("", "IS UNKNOWN", ""), tmp1);
        $$ = res;
    }

    | bool_pri IS not UNKNOWN_SYM %prec IS {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kExpr, OP3("", "IS", "UNKNOWN"), tmp1, tmp2);
        $$ = res;
    }

    | bool_pri %prec SET_VAR {
        auto tmp1 = $1;
        res = new IR(kExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


bool_pri:

    bool_pri IS NULL_SYM %prec IS {
        auto tmp1 = $1;
        res = new IR(kBoolPri, OP3("", "IS NULL", ""), tmp1);
        $$ = res;
    }

    | bool_pri IS not NULL_SYM %prec IS {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBoolPri, OP3("", "IS", "NULL"), tmp1, tmp2);
        $$ = res;
    }

    | bool_pri comp_op predicate {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kBoolPri_1, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kBoolPri, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | bool_pri comp_op all_or_any table_subquery %prec EQ {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kBoolPri_2, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kBoolPri_3, OP3("", "", ""), res, tmp3);

        auto tmp4 = $4;
        res = new IR(kBoolPri, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | predicate %prec SET_VAR {
        auto tmp1 = $1;
        res = new IR(kBoolPri, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


predicate:

    bit_expr IN_SYM table_subquery {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kPredicate, OP3("", "IN", ""), tmp1, tmp2);
        $$ = res;
    }

    | bit_expr not IN_SYM table_subquery {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kPredicate_1, OP3("", "", "IN"), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kPredicate, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | bit_expr IN_SYM '(' expr ')' {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kPredicate, OP3("", "IN (", ")"), tmp1, tmp2);
        $$ = res;
    }

    | bit_expr IN_SYM '(' expr ',' expr_list ')' {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kPredicate_2, OP3("", "IN (", ","), tmp1, tmp2);

        auto tmp3 = $6;
        res = new IR(kPredicate, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | bit_expr not IN_SYM '(' expr ')' {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kPredicate_3, OP3("", "", "IN ("), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kPredicate, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | bit_expr not IN_SYM '(' expr ',' expr_list ')' {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kPredicate_4, OP3("", "", "IN ("), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kPredicate_5, OP3("", "", ","), res, tmp3);

        auto tmp4 = $7;
        res = new IR(kPredicate, OP3("", "", ")"), res, tmp4);
        $$ = res;
    }

    | bit_expr MEMBER_SYM opt_of '(' simple_expr ')' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kPredicate_6, OP3("", "MEMBER", "("), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kPredicate, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | bit_expr BETWEEN_SYM bit_expr AND_SYM predicate {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kPredicate_7, OP3("", "BETWEEN", "AND"), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kPredicate, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | bit_expr not BETWEEN_SYM bit_expr AND_SYM predicate {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kPredicate_8, OP3("", "", "BETWEEN"), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kPredicate_9, OP3("", "", "AND"), res, tmp3);

        auto tmp4 = $6;
        res = new IR(kPredicate, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | bit_expr SOUNDS_SYM LIKE bit_expr {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kPredicate, OP3("", "SOUNDS LIKE", ""), tmp1, tmp2);
        $$ = res;
    }

    | bit_expr LIKE simple_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kPredicate, OP3("", "LIKE", ""), tmp1, tmp2);
        $$ = res;
    }

    | bit_expr LIKE simple_expr ESCAPE_SYM simple_expr %prec LIKE {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kPredicate_10, OP3("", "LIKE", "ESCAPE"), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kPredicate, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | bit_expr not LIKE simple_expr {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kPredicate_11, OP3("", "", "LIKE"), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kPredicate, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | bit_expr not LIKE simple_expr ESCAPE_SYM simple_expr %prec LIKE {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kPredicate_12, OP3("", "", "LIKE"), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kPredicate_13, OP3("", "", "ESCAPE"), res, tmp3);

        auto tmp4 = $6;
        res = new IR(kPredicate, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | bit_expr REGEXP bit_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kPredicate, OP3("", "REGEXP", ""), tmp1, tmp2);
        $$ = res;
    }

    | bit_expr not REGEXP bit_expr {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kPredicate_14, OP3("", "", "REGEXP"), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kPredicate, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | bit_expr %prec SET_VAR {
        auto tmp1 = $1;
        res = new IR(kPredicate, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_of:

    OF_SYM {
        res = new IR(kOptOf, OP3("OF", "", ""));
        $$ = res;
    }

    |  {

    }

;


bit_expr:

    bit_expr '|' bit_expr %prec '|' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBitExpr, OP3("", "|", ""), tmp1, tmp2);
        $$ = res;
    }

    | bit_expr '&' bit_expr %prec '&' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBitExpr, OP3("", "&", ""), tmp1, tmp2);
        $$ = res;
    }

    | bit_expr SHIFT_LEFT bit_expr %prec SHIFT_LEFT {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBitExpr, OP3("", "<<", ""), tmp1, tmp2);
        $$ = res;
    }

    | bit_expr SHIFT_RIGHT bit_expr %prec SHIFT_RIGHT {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBitExpr, OP3("", ">>", ""), tmp1, tmp2);
        $$ = res;
    }

    | bit_expr '+' bit_expr %prec '+' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBitExpr, OP3("", "+", ""), tmp1, tmp2);
        $$ = res;
    }

    | bit_expr '-' bit_expr %prec '-' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBitExpr, OP3("", "-", ""), tmp1, tmp2);
        $$ = res;
    }

    | bit_expr '+' INTERVAL_SYM expr interval %prec '+' {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kBitExpr_1, OP3("", "+ INTERVAL", ""), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kBitExpr, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | bit_expr '-' INTERVAL_SYM expr interval %prec '-' {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kBitExpr_2, OP3("", "- INTERVAL", ""), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kBitExpr, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | bit_expr '*' bit_expr %prec '*' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBitExpr, OP3("", "*", ""), tmp1, tmp2);
        $$ = res;
    }

    | bit_expr '/' bit_expr %prec '/' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBitExpr, OP3("", "/", ""), tmp1, tmp2);
        $$ = res;
    }

    | bit_expr '%' bit_expr %prec '%' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBitExpr, OP3("", "%", ""), tmp1, tmp2);
        $$ = res;
    }

    | bit_expr DIV_SYM bit_expr %prec DIV_SYM {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBitExpr, OP3("", "DIV", ""), tmp1, tmp2);
        $$ = res;
    }

    | bit_expr MOD_SYM bit_expr %prec MOD_SYM {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBitExpr, OP3("", "MOD", ""), tmp1, tmp2);
        $$ = res;
    }

    | bit_expr '^' bit_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBitExpr, OP3("", "^", ""), tmp1, tmp2);
        $$ = res;
    }

    | simple_expr %prec SET_VAR {
        auto tmp1 = $1;
        res = new IR(kBitExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


or:

    OR_SYM {
        res = new IR(kOr, OP3("OR", "", ""));
        $$ = res;
    }

    | OR2_SYM {
        res = new IR(kOr, OP3("OR2_SYM", "", ""));
        $$ = res;
    }

;


and:

    AND_SYM {
        res = new IR(kAnd, OP3("AND", "", ""));
        $$ = res;
    }

    | AND_AND_SYM {
        res = new IR(kAnd, OP3("&&", "", ""));
        $$ = res;
    }

;


not:

    NOT_SYM {
        res = new IR(kNot, OP3("NOT", "", ""));
        $$ = res;
    }

    | NOT2_SYM {
        res = new IR(kNot, OP3("NOT2_SYM", "", ""));
        $$ = res;
    }

;


not2:

    '!' {
        res = new IR(kNot2, OP3("!", "", ""));
        $$ = res;
    }

    | NOT2_SYM {
        res = new IR(kNot2, OP3("NOT2_SYM", "", ""));
        $$ = res;
    }

;


comp_op:

    EQ {
        res = new IR(kCompOp, OP3("=", "", ""));
        $$ = res;
    }

    | EQUAL_SYM {
        res = new IR(kCompOp, OP3("<=>", "", ""));
        $$ = res;
    }

    | GE {
        res = new IR(kCompOp, OP3(">=", "", ""));
        $$ = res;
    }

    | GT_SYM {
        res = new IR(kCompOp, OP3(">", "", ""));
        $$ = res;
    }

    | LE {
        res = new IR(kCompOp, OP3("<=", "", ""));
        $$ = res;
    }

    | LT {
        res = new IR(kCompOp, OP3("<", "", ""));
        $$ = res;
    }

    | NE {
        res = new IR(kCompOp, OP3("<>", "", ""));
        $$ = res;
    }

;


all_or_any:

    ALL {
        res = new IR(kAllOrAny, OP3("ALL", "", ""));
        $$ = res;
    }

    | ANY_SYM {
        res = new IR(kAllOrAny, OP3("ANY", "", ""));
        $$ = res;
    }

;


simple_expr:

    simple_ident {
        auto tmp1 = $1;
        res = new IR(kSimpleExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | function_call_keyword {
        auto tmp1 = $1;
        res = new IR(kSimpleExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | function_call_nonkeyword {
        auto tmp1 = $1;
        res = new IR(kSimpleExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | function_call_generic {
        auto tmp1 = $1;
        res = new IR(kSimpleExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | function_call_conflict {
        auto tmp1 = $1;
        res = new IR(kSimpleExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | simple_expr COLLATE_SYM ident_or_text %prec NEG {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSimpleExpr, OP3("", "COLLATE", ""), tmp1, tmp2);
        $$ = res;
    }

    | literal_or_null {
        auto tmp1 = $1;
        res = new IR(kSimpleExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | param_marker {
        auto tmp1 = $1;
        res = new IR(kSimpleExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | variable {
        auto tmp1 = $1;
        res = new IR(kSimpleExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | set_function_specification {
        auto tmp1 = $1;
        res = new IR(kSimpleExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | window_func_call {
        auto tmp1 = $1;
        res = new IR(kSimpleExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | simple_expr OR_OR_SYM simple_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSimpleExpr, OP3("", "||", ""), tmp1, tmp2);
        $$ = res;
    }

    | '+' simple_expr %prec NEG {
        auto tmp1 = $2;
        res = new IR(kSimpleExpr, OP3("+", "", ""), tmp1);
        $$ = res;
    }

    | '-' simple_expr %prec NEG {
        auto tmp1 = $2;
        res = new IR(kSimpleExpr, OP3("-", "", ""), tmp1);
        $$ = res;
    }

    | '~' simple_expr %prec NEG {
        auto tmp1 = $2;
        res = new IR(kSimpleExpr, OP3("~", "", ""), tmp1);
        $$ = res;
    }

    | not2 simple_expr %prec NEG {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSimpleExpr, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | row_subquery {
        auto tmp1 = $1;
        res = new IR(kSimpleExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '(' expr ')' {
        auto tmp1 = $2;
        res = new IR(kSimpleExpr, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

    | '(' expr ',' expr_list ')' {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kSimpleExpr, OP3("(", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

    | ROW_SYM '(' expr ',' expr_list ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kSimpleExpr, OP3("ROW (", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

    | EXISTS table_subquery {
        auto tmp1 = $2;
        res = new IR(kSimpleExpr, OP3("EXISTS", "", ""), tmp1);
        $$ = res;
    }

    | '{' ident expr '}' {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSimpleExpr, OP3("{", "", "}"), tmp1, tmp2);
        $$ = res;
    }

    | MATCH ident_list_arg AGAINST '(' bit_expr fulltext_options ')' {
        auto tmp1 = $2;
        auto tmp2 = $5;
        res = new IR(kSimpleExpr_1, OP3("MATCH", "AGAINST (", ""), tmp1, tmp2);

        auto tmp3 = $6;
        res = new IR(kSimpleExpr, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | BINARY_SYM simple_expr %prec NEG {
        auto tmp1 = $2;
        res = new IR(kSimpleExpr, OP3("BINARY", "", ""), tmp1);
        $$ = res;
    }

    | CAST_SYM '(' expr AS cast_type opt_array_cast ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kSimpleExpr_2, OP3("CAST (", "AS", ""), tmp1, tmp2);

        auto tmp3 = $6;
        res = new IR(kSimpleExpr, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | CAST_SYM '(' expr AT_SYM LOCAL_SYM AS cast_type opt_array_cast ')' {
        auto tmp1 = $3;
        auto tmp2 = $7;
        res = new IR(kSimpleExpr_3, OP3("CAST (", "AT LOCAL AS", ""), tmp1, tmp2);

        auto tmp3 = $8;
        res = new IR(kSimpleExpr, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | CAST_SYM '(' expr AT_SYM TIME_SYM ZONE_SYM opt_interval TEXT_STRING_literal AS DATETIME_SYM type_datetime_precision ')' {
        auto tmp1 = $3;
        auto tmp2 = $7;
        res = new IR(kSimpleExpr_4, OP3("CAST (", "AT TIME ZONE", ""), tmp1, tmp2);

        auto tmp3 = $8;
        res = new IR(kSimpleExpr_5, OP3("", "", "AS DATETIME"), res, tmp3);

        auto tmp4 = $11;
        res = new IR(kSimpleExpr, OP3("", "", ")"), res, tmp4);
        $$ = res;
    }

    | CASE_SYM opt_expr when_list opt_else END {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSimpleExpr_6, OP3("CASE", "", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kSimpleExpr, OP3("", "", "END"), res, tmp3);
        $$ = res;
    }

    | CONVERT_SYM '(' expr ',' cast_type ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kSimpleExpr, OP3("CONVERT (", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

    | CONVERT_SYM '(' expr USING charset_name ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kSimpleExpr, OP3("CONVERT (", "USING", ")"), tmp1, tmp2);
        $$ = res;
    }

    | DEFAULT_SYM '(' simple_ident ')' {
        auto tmp1 = $3;
        res = new IR(kSimpleExpr, OP3("DEFAULT (", ")", ""), tmp1);
        $$ = res;
    }

    | VALUES '(' simple_ident_nospvar ')' {
        auto tmp1 = $3;
        res = new IR(kSimpleExpr, OP3("VALUES (", ")", ""), tmp1);
        $$ = res;
    }

    | INTERVAL_SYM expr interval '+' expr %prec INTERVAL_SYM {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSimpleExpr_7, OP3("INTERVAL", "", "+"), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kSimpleExpr, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | simple_ident JSON_SEPARATOR_SYM TEXT_STRING_literal {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSimpleExpr, OP3("", "JSON_SEPARATOR_SYM", ""), tmp1, tmp2);
        $$ = res;
    }

    | simple_ident JSON_UNQUOTED_SEPARATOR_SYM TEXT_STRING_literal {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSimpleExpr, OP3("", "JSON_UNQUOTED_SEPARATOR_SYM", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_array_cast:

    /* empty */ {
        res = new IR(kOptArrayCast, OP3("", "", ""));
        $$ = res;
    }

    | ARRAY_SYM {
        res = new IR(kOptArrayCast, OP3("ARRAY", "", ""));
        $$ = res;
    }

;

/*
Function call syntax using official SQL 2003 keywords.
Because the function name is an official token,
a dedicated grammar rule is needed in the parser.
There is no potential for conflicts
*/

function_call_keyword:

    CHAR_SYM '(' expr_list ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallKeyword, OP3("CHAR (", ")", ""), tmp1);
        $$ = res;
    }

    | CHAR_SYM '(' expr_list USING charset_name ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallKeyword, OP3("CHAR (", "USING", ")"), tmp1, tmp2);
        $$ = res;
    }

    | CURRENT_USER optional_braces {
        auto tmp1 = $2;
        res = new IR(kFunctionCallKeyword, OP3("CURRENT_USER", "", ""), tmp1);
        $$ = res;
    }

    | DATE_SYM '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallKeyword, OP3("DATE (", ")", ""), tmp1);
        $$ = res;
    }

    | DAY_SYM '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallKeyword, OP3("DAY (", ")", ""), tmp1);
        $$ = res;
    }

    | HOUR_SYM '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallKeyword, OP3("HOUR (", ")", ""), tmp1);
        $$ = res;
    }

    | INSERT_SYM '(' expr ',' expr ',' expr ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallKeyword_1, OP3("INSERT (", ",", ","), tmp1, tmp2);

        auto tmp3 = $7;
        res = new IR(kFunctionCallKeyword_2, OP3("", "", ","), res, tmp3);

        auto tmp4 = $9;
        res = new IR(kFunctionCallKeyword, OP3("", "", ")"), res, tmp4);
        $$ = res;
    }

    | INTERVAL_SYM '(' expr ',' expr ')' %prec INTERVAL_SYM {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallKeyword, OP3("INTERVAL (", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

    | INTERVAL_SYM '(' expr ',' expr ',' expr_list ')' %prec INTERVAL_SYM {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallKeyword_3, OP3("INTERVAL (", ",", ","), tmp1, tmp2);

        auto tmp3 = $7;
        res = new IR(kFunctionCallKeyword, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | JSON_VALUE_SYM '(' simple_expr ',' text_literal opt_returning_type opt_on_empty_or_error ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallKeyword_4, OP3("JSON_VALUE (", ",", ""), tmp1, tmp2);

        auto tmp3 = $6;
        res = new IR(kFunctionCallKeyword_5, OP3("", "", ""), res, tmp3);

        auto tmp4 = $7;
        res = new IR(kFunctionCallKeyword, OP3("", "", ")"), res, tmp4);
        $$ = res;
    }

    | LEFT '(' expr ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallKeyword, OP3("LEFT (", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

    | MINUTE_SYM '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallKeyword, OP3("MINUTE (", ")", ""), tmp1);
        $$ = res;
    }

    | MONTH_SYM '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallKeyword, OP3("MONTH (", ")", ""), tmp1);
        $$ = res;
    }

    | RIGHT '(' expr ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallKeyword, OP3("RIGHT (", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

    | SECOND_SYM '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallKeyword, OP3("SECOND (", ")", ""), tmp1);
        $$ = res;
    }

    | TIME_SYM '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallKeyword, OP3("TIME (", ")", ""), tmp1);
        $$ = res;
    }

    | TIMESTAMP_SYM '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallKeyword, OP3("TIMESTAMP (", ")", ""), tmp1);
        $$ = res;
    }

    | TIMESTAMP_SYM '(' expr ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallKeyword, OP3("TIMESTAMP (", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

    | TRIM '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallKeyword, OP3("TRIM (", ")", ""), tmp1);
        $$ = res;
    }

    | TRIM '(' LEADING expr FROM expr ')' {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kFunctionCallKeyword, OP3("TRIM ( LEADING", "FROM", ")"), tmp1, tmp2);
        $$ = res;
    }

    | TRIM '(' TRAILING expr FROM expr ')' {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kFunctionCallKeyword, OP3("TRIM ( TRAILING", "FROM", ")"), tmp1, tmp2);
        $$ = res;
    }

    | TRIM '(' BOTH expr FROM expr ')' {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kFunctionCallKeyword, OP3("TRIM ( BOTH", "FROM", ")"), tmp1, tmp2);
        $$ = res;
    }

    | TRIM '(' LEADING FROM expr ')' {
        auto tmp1 = $5;
        res = new IR(kFunctionCallKeyword, OP3("TRIM ( LEADING FROM", ")", ""), tmp1);
        $$ = res;
    }

    | TRIM '(' TRAILING FROM expr ')' {
        auto tmp1 = $5;
        res = new IR(kFunctionCallKeyword, OP3("TRIM ( TRAILING FROM", ")", ""), tmp1);
        $$ = res;
    }

    | TRIM '(' BOTH FROM expr ')' {
        auto tmp1 = $5;
        res = new IR(kFunctionCallKeyword, OP3("TRIM ( BOTH FROM", ")", ""), tmp1);
        $$ = res;
    }

    | TRIM '(' expr FROM expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallKeyword, OP3("TRIM (", "FROM", ")"), tmp1, tmp2);
        $$ = res;
    }

    | USER '(' ')' {
        res = new IR(kFunctionCallKeyword, OP3("USER ( )", "", ""));
        $$ = res;
    }

    | YEAR_SYM '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallKeyword, OP3("SQL_TSI_YEAR (", ")", ""), tmp1);
        $$ = res;
    }

;

/*
Function calls using non reserved keywords, with special syntaxic forms.
Dedicated grammar rules are needed because of the syntax,
but also have the potential to cause incompatibilities with other
parts of the language.
MAINTAINER:
The only reasons a function should be added here are:
- for compatibility reasons with another SQL syntax (CURDATE),
- for typing reasons (GET_FORMAT)
Any other 'Syntaxic sugar' enhancements should be *STRONGLY*
discouraged.
*/

function_call_nonkeyword:

    ADDDATE_SYM '(' expr ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallNonkeyword, OP3("ADDDATE (", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

    | ADDDATE_SYM '(' expr ',' INTERVAL_SYM expr interval ')' {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kFunctionCallNonkeyword_1, OP3("ADDDATE (", ", INTERVAL", ""), tmp1, tmp2);

        auto tmp3 = $7;
        res = new IR(kFunctionCallNonkeyword, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | CURDATE optional_braces {
        auto tmp1 = $2;
        res = new IR(kFunctionCallNonkeyword, OP3("CURRENT_DATE", "", ""), tmp1);
        $$ = res;
    }

    | CURTIME func_datetime_precision {
        auto tmp1 = $2;
        res = new IR(kFunctionCallNonkeyword, OP3("CURRENT_TIME", "", ""), tmp1);
        $$ = res;
    }

    | DATE_ADD_INTERVAL '(' expr ',' INTERVAL_SYM expr interval ')' %prec INTERVAL_SYM {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kFunctionCallNonkeyword_2, OP3("DATE_ADD (", ", INTERVAL", ""), tmp1, tmp2);

        auto tmp3 = $7;
        res = new IR(kFunctionCallNonkeyword, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | DATE_SUB_INTERVAL '(' expr ',' INTERVAL_SYM expr interval ')' %prec INTERVAL_SYM {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kFunctionCallNonkeyword_3, OP3("DATE_SUB (", ", INTERVAL", ""), tmp1, tmp2);

        auto tmp3 = $7;
        res = new IR(kFunctionCallNonkeyword, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | EXTRACT_SYM '(' interval FROM expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallNonkeyword, OP3("EXTRACT (", "FROM", ")"), tmp1, tmp2);
        $$ = res;
    }

    | GET_FORMAT '(' date_time_type ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallNonkeyword, OP3("GET_FORMAT (", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

    | now {
        auto tmp1 = $1;
        res = new IR(kFunctionCallNonkeyword, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | POSITION_SYM '(' bit_expr IN_SYM expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallNonkeyword, OP3("POSITION (", "IN", ")"), tmp1, tmp2);
        $$ = res;
    }

    | SUBDATE_SYM '(' expr ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallNonkeyword, OP3("SUBDATE (", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

    | SUBDATE_SYM '(' expr ',' INTERVAL_SYM expr interval ')' {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kFunctionCallNonkeyword_4, OP3("SUBDATE (", ", INTERVAL", ""), tmp1, tmp2);

        auto tmp3 = $7;
        res = new IR(kFunctionCallNonkeyword, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | SUBSTRING '(' expr ',' expr ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallNonkeyword_5, OP3("MID (", ",", ","), tmp1, tmp2);

        auto tmp3 = $7;
        res = new IR(kFunctionCallNonkeyword, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | SUBSTRING '(' expr ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallNonkeyword, OP3("MID (", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

    | SUBSTRING '(' expr FROM expr FOR_SYM expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallNonkeyword_6, OP3("MID (", "FROM", "FOR"), tmp1, tmp2);

        auto tmp3 = $7;
        res = new IR(kFunctionCallNonkeyword, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | SUBSTRING '(' expr FROM expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallNonkeyword, OP3("MID (", "FROM", ")"), tmp1, tmp2);
        $$ = res;
    }

    | SYSDATE func_datetime_precision {
        auto tmp1 = $2;
        res = new IR(kFunctionCallNonkeyword, OP3("SYSDATE", "", ""), tmp1);
        $$ = res;
    }

    | TIMESTAMP_ADD '(' interval_time_stamp ',' expr ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallNonkeyword_7, OP3("TIMESTAMPADD (", ",", ","), tmp1, tmp2);

        auto tmp3 = $7;
        res = new IR(kFunctionCallNonkeyword, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | TIMESTAMP_DIFF '(' interval_time_stamp ',' expr ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallNonkeyword_8, OP3("TIMESTAMPDIFF (", ",", ","), tmp1, tmp2);

        auto tmp3 = $7;
        res = new IR(kFunctionCallNonkeyword, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | UTC_DATE_SYM optional_braces {
        auto tmp1 = $2;
        res = new IR(kFunctionCallNonkeyword, OP3("UTC_DATE", "", ""), tmp1);
        $$ = res;
    }

    | UTC_TIME_SYM func_datetime_precision {
        auto tmp1 = $2;
        res = new IR(kFunctionCallNonkeyword, OP3("UTC_TIME", "", ""), tmp1);
        $$ = res;
    }

    | UTC_TIMESTAMP_SYM func_datetime_precision {
        auto tmp1 = $2;
        res = new IR(kFunctionCallNonkeyword, OP3("UTC_TIMESTAMP", "", ""), tmp1);
        $$ = res;
    }

;

// JSON_VALUE's optional JSON returning clause.

opt_returning_type:

    // The default returning type is CHAR(512). (The max length of 512
    // is chosen so that the returned values are not handled as BLOBs
    // internally. See CONVERT_IF_BIGGER_TO_BLOB.)
    {
        res = new IR(kOptReturningType, OP3("", "", ""));
        $$ = res;
    }

    | RETURNING_SYM cast_type {
        auto tmp1 = $2;
        res = new IR(kOptReturningType, OP3("RETURNING", "", ""), tmp1);
        $$ = res;
    }

;


/*
Functions calls using a non reserved keyword, and using a regular syntax.
Because the non reserved keyword is used in another part of the grammar,
a dedicated rule is needed here.
*/

function_call_conflict:

    ASCII_SYM '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallConflict, OP3("ASCII (", ")", ""), tmp1);
        $$ = res;
    }

    | CHARSET '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallConflict, OP3("CHARSET (", ")", ""), tmp1);
        $$ = res;
    }

    | COALESCE '(' expr_list ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallConflict, OP3("COALESCE (", ")", ""), tmp1);
        $$ = res;
    }

    | COLLATION_SYM '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallConflict, OP3("COLLATION (", ")", ""), tmp1);
        $$ = res;
    }

    | DATABASE '(' ')' {
        res = new IR(kFunctionCallConflict, OP3("DATABASE ( )", "", ""));
        $$ = res;
    }

    | IF '(' expr ',' expr ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallConflict_1, OP3("IF (", ",", ","), tmp1, tmp2);

        auto tmp3 = $7;
        res = new IR(kFunctionCallConflict, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | FORMAT_SYM '(' expr ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallConflict, OP3("FORMAT (", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

    | FORMAT_SYM '(' expr ',' expr ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallConflict_2, OP3("FORMAT (", ",", ","), tmp1, tmp2);

        auto tmp3 = $7;
        res = new IR(kFunctionCallConflict, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | MICROSECOND_SYM '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallConflict, OP3("MICROSECOND (", ")", ""), tmp1);
        $$ = res;
    }

    | MOD_SYM '(' expr ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallConflict, OP3("MOD (", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

    | QUARTER_SYM '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallConflict, OP3("QUARTER (", ")", ""), tmp1);
        $$ = res;
    }

    | REPEAT_SYM '(' expr ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallConflict, OP3("REPEAT (", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

    | REPLACE_SYM '(' expr ',' expr ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallConflict_3, OP3("REPLACE (", ",", ","), tmp1, tmp2);

        auto tmp3 = $7;
        res = new IR(kFunctionCallConflict, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | REVERSE_SYM '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallConflict, OP3("REVERSE (", ")", ""), tmp1);
        $$ = res;
    }

    | ROW_COUNT_SYM '(' ')' {
        res = new IR(kFunctionCallConflict, OP3("ROW_COUNT ( )", "", ""));
        $$ = res;
    }

    | TRUNCATE_SYM '(' expr ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallConflict, OP3("TRUNCATE (", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

    | WEEK_SYM '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallConflict, OP3("SQL_TSI_WEEK (", ")", ""), tmp1);
        $$ = res;
    }

    | WEEK_SYM '(' expr ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallConflict, OP3("SQL_TSI_WEEK (", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

    | WEIGHT_STRING_SYM '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallConflict, OP3("WEIGHT_STRING (", ")", ""), tmp1);
        $$ = res;
    }

    | WEIGHT_STRING_SYM '(' expr AS CHAR_SYM ws_num_codepoints ')' {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kFunctionCallConflict, OP3("WEIGHT_STRING (", "AS CHAR", ")"), tmp1, tmp2);
        $$ = res;
    }

    | WEIGHT_STRING_SYM '(' expr AS BINARY_SYM ws_num_codepoints ')' {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kFunctionCallConflict, OP3("WEIGHT_STRING (", "AS BINARY", ")"), tmp1, tmp2);
        $$ = res;
    }

    | WEIGHT_STRING_SYM '(' expr ',' ulong_num ',' ulong_num ',' ulong_num ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallConflict_4, OP3("WEIGHT_STRING (", ",", ","), tmp1, tmp2);

        auto tmp3 = $7;
        res = new IR(kFunctionCallConflict_5, OP3("", "", ","), res, tmp3);

        auto tmp4 = $9;
        res = new IR(kFunctionCallConflict, OP3("", "", ")"), res, tmp4);
        $$ = res;
    }

    | geometry_function {
        auto tmp1 = $1;
        res = new IR(kFunctionCallConflict, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


geometry_function:

    GEOMETRYCOLLECTION_SYM '(' opt_expr_list ')' {
        auto tmp1 = $3;
        res = new IR(kGeometryFunction, OP3("GEOMCOLLECTION (", ")", ""), tmp1);
        $$ = res;
    }

    | LINESTRING_SYM '(' expr_list ')' {
        auto tmp1 = $3;
        res = new IR(kGeometryFunction, OP3("LINESTRING (", ")", ""), tmp1);
        $$ = res;
    }

    | MULTILINESTRING_SYM '(' expr_list ')' {
        auto tmp1 = $3;
        res = new IR(kGeometryFunction, OP3("MULTILINESTRING (", ")", ""), tmp1);
        $$ = res;
    }

    | MULTIPOINT_SYM '(' expr_list ')' {
        auto tmp1 = $3;
        res = new IR(kGeometryFunction, OP3("MULTIPOINT (", ")", ""), tmp1);
        $$ = res;
    }

    | MULTIPOLYGON_SYM '(' expr_list ')' {
        auto tmp1 = $3;
        res = new IR(kGeometryFunction, OP3("MULTIPOLYGON (", ")", ""), tmp1);
        $$ = res;
    }

    | POINT_SYM '(' expr ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kGeometryFunction, OP3("POINT (", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

    | POLYGON_SYM '(' expr_list ')' {
        auto tmp1 = $3;
        res = new IR(kGeometryFunction, OP3("POLYGON (", ")", ""), tmp1);
        $$ = res;
    }

;

/*
Regular function calls.
The function name is *not* a token, and therefore is guaranteed to not
introduce side effects to the language in general.
MAINTAINER:
All the new functions implemented for new features should fit into
this category. The place to implement the function itself is
in sql/item_create.cc
*/

function_call_generic:

    IDENT_sys '(' opt_udf_expr_list ')' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kFunctionCallGeneric, OP3("", "(", ")"), tmp1, tmp2);
        $$ = res;
    }

    | ident '.' ident '(' opt_expr_list ')' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kFunctionCallGeneric_1, OP3("", ".", "("), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kFunctionCallGeneric, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

;


fulltext_options:

    opt_natural_language_mode opt_query_expansion {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFulltextOptions, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | IN_SYM BOOLEAN_SYM MODE_SYM {
        res = new IR(kFulltextOptions, OP3("IN BOOLEAN MODE", "", ""));
        $$ = res;
    }

;


opt_natural_language_mode:

    /* nothing */ {
        res = new IR(kOptNaturalLanguageMode, OP3("", "", ""));
        $$ = res;
    }

    | IN_SYM NATURAL LANGUAGE_SYM MODE_SYM {
        res = new IR(kOptNaturalLanguageMode, OP3("IN NATURAL LANGUAGE MODE", "", ""));
        $$ = res;
    }

;


opt_query_expansion:

    /* nothing */ {
        res = new IR(kOptQueryExpansion, OP3("", "", ""));
        $$ = res;
    }

    | WITH QUERY_SYM EXPANSION_SYM {
        res = new IR(kOptQueryExpansion, OP3("WITH QUERY EXPANSION", "", ""));
        $$ = res;
    }

;


opt_udf_expr_list:

    /* empty */ {
        res = new IR(kOptUdfExprList, OP3("", "", ""));
        $$ = res;
    }

    | udf_expr_list {
        auto tmp1 = $1;
        res = new IR(kOptUdfExprList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


udf_expr_list:

    udf_expr {
        auto tmp1 = $1;
        res = new IR(kUdfExprList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | udf_expr_list ',' udf_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kUdfExprList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


udf_expr:

    expr select_alias {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUdfExpr, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


set_function_specification:

    sum_expr {
        auto tmp1 = $1;
        res = new IR(kSetFunctionSpecification, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | grouping_operation {
        auto tmp1 = $1;
        res = new IR(kSetFunctionSpecification, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


sum_expr:

    AVG_SYM '(' in_sum_expr ')' opt_windowing_clause {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kSumExpr, OP3("AVG (", ")", ""), tmp1, tmp2);
        $$ = res;
    }

    | AVG_SYM '(' DISTINCT in_sum_expr ')' opt_windowing_clause {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kSumExpr, OP3("AVG ( DISTINCT", ")", ""), tmp1, tmp2);
        $$ = res;
    }

    | BIT_AND_SYM '(' in_sum_expr ')' opt_windowing_clause {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kSumExpr, OP3("BIT_AND (", ")", ""), tmp1, tmp2);
        $$ = res;
    }

    | BIT_OR_SYM '(' in_sum_expr ')' opt_windowing_clause {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kSumExpr, OP3("BIT_OR (", ")", ""), tmp1, tmp2);
        $$ = res;
    }

    | JSON_ARRAYAGG '(' in_sum_expr ')' opt_windowing_clause {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kSumExpr, OP3("JSON_ARRAYAGG (", ")", ""), tmp1, tmp2);
        $$ = res;
    }

    | JSON_OBJECTAGG '(' in_sum_expr ',' in_sum_expr ')' opt_windowing_clause {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kSumExpr_1, OP3("JSON_OBJECTAGG (", ",", ")"), tmp1, tmp2);

        auto tmp3 = $7;
        res = new IR(kSumExpr, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ST_COLLECT_SYM '(' in_sum_expr ')' opt_windowing_clause {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kSumExpr, OP3("ST_COLLECT (", ")", ""), tmp1, tmp2);
        $$ = res;
    }

    | ST_COLLECT_SYM '(' DISTINCT in_sum_expr ')' opt_windowing_clause {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kSumExpr, OP3("ST_COLLECT ( DISTINCT", ")", ""), tmp1, tmp2);
        $$ = res;
    }

    | BIT_XOR_SYM '(' in_sum_expr ')' opt_windowing_clause {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kSumExpr, OP3("BIT_XOR (", ")", ""), tmp1, tmp2);
        $$ = res;
    }

    | COUNT_SYM '(' opt_all '*' ')' opt_windowing_clause {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kSumExpr, OP3("COUNT (", "* )", ""), tmp1, tmp2);
        $$ = res;
    }

    | COUNT_SYM '(' in_sum_expr ')' opt_windowing_clause {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kSumExpr, OP3("COUNT (", ")", ""), tmp1, tmp2);
        $$ = res;
    }

    | COUNT_SYM '(' DISTINCT expr_list ')' opt_windowing_clause {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kSumExpr, OP3("COUNT ( DISTINCT", ")", ""), tmp1, tmp2);
        $$ = res;
    }

    | MIN_SYM '(' in_sum_expr ')' opt_windowing_clause {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kSumExpr, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | MIN_SYM '(' DISTINCT in_sum_expr ')' opt_windowing_clause {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kSumExpr, OP3("MIN ( DISTINCT", ")", ""), tmp1, tmp2);
        $$ = res;
    }

    | MAX_SYM '(' in_sum_expr ')' opt_windowing_clause {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kSumExpr, OP3("MAX (", ")", ""), tmp1, tmp2);
        $$ = res;
    }

    | MAX_SYM '(' DISTINCT in_sum_expr ')' opt_windowing_clause {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kSumExpr, OP3("MAX ( DISTINCT", ")", ""), tmp1, tmp2);
        $$ = res;
    }

    | STD_SYM '(' in_sum_expr ')' opt_windowing_clause {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kSumExpr, OP3("STD (", ")", ""), tmp1, tmp2);
        $$ = res;
    }

    | VARIANCE_SYM '(' in_sum_expr ')' opt_windowing_clause {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kSumExpr, OP3("VARIANCE (", ")", ""), tmp1, tmp2);
        $$ = res;
    }

    | STDDEV_SAMP_SYM '(' in_sum_expr ')' opt_windowing_clause {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kSumExpr, OP3("STDDEV_SAMP (", ")", ""), tmp1, tmp2);
        $$ = res;
    }

    | VAR_SAMP_SYM '(' in_sum_expr ')' opt_windowing_clause {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kSumExpr, OP3("VAR_SAMP (", ")", ""), tmp1, tmp2);
        $$ = res;
    }

    | SUM_SYM '(' in_sum_expr ')' opt_windowing_clause {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kSumExpr, OP3("SUM (", ")", ""), tmp1, tmp2);
        $$ = res;
    }

    | SUM_SYM '(' DISTINCT in_sum_expr ')' opt_windowing_clause {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kSumExpr, OP3("SUM ( DISTINCT", ")", ""), tmp1, tmp2);
        $$ = res;
    }

    | GROUP_CONCAT_SYM '(' opt_distinct expr_list opt_gorder_clause opt_gconcat_separator ')' opt_windowing_clause {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kSumExpr_11, OP3("GROUP_CONCAT (", "", ""), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kSumExpr_12, OP3("", "", ""), res, tmp3);

        auto tmp4 = $6;
        res = new IR(kSumExpr_13, OP3("", "", ")"), res, tmp4);

        auto tmp5 = $8;
        res = new IR(kSumExpr, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

;


window_func_call:

    ROW_NUMBER_SYM '(' ')' windowing_clause {
        auto tmp1 = $4;
        res = new IR(kWindowFuncCall, OP3("ROW_NUMBER()", "", ""), tmp1);
        $$ = res;
    }

    | RANK_SYM '(' ')' windowing_clause {
        auto tmp1 = $4;
        res = new IR(kWindowFuncCall, OP3("RANK ( )", "", ""), tmp1);
        $$ = res;
    }

    | DENSE_RANK_SYM '(' ')' windowing_clause {
        auto tmp1 = $4;
        res = new IR(kWindowFuncCall, OP3("DENSE_RANK ( )", "", ""), tmp1);
        $$ = res;
    }

    | CUME_DIST_SYM '(' ')' windowing_clause {
        auto tmp1 = $4;
        res = new IR(kWindowFuncCall, OP3("CUME_DIST ( )", "", ""), tmp1);
        $$ = res;
    }

    | PERCENT_RANK_SYM '(' ')' windowing_clause {
        auto tmp1 = $4;
        res = new IR(kWindowFuncCall, OP3("PERCENT_RANK ( )", "", ""), tmp1);
        $$ = res;
    }

    | NTILE_SYM '(' stable_integer ')' windowing_clause {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kWindowFuncCall, OP3("NTILE (", ")", ""), tmp1, tmp2);
        $$ = res;
    }

    | LEAD_SYM '(' expr opt_lead_lag_info ')' opt_null_treatment windowing_clause {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kWindowFuncCall_9, OP3("LEAD (", "", ")"), tmp1, tmp2);

        auto tmp3 = $6;
        res = new IR(kWindowFuncCall_10, OP3("", "", ""), res, tmp3);

        auto tmp4 = $7;
        res = new IR(kWindowFuncCall, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | LAG_SYM '(' expr opt_lead_lag_info ')' opt_null_treatment windowing_clause {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kWindowFuncCall_11, OP3("LAG (", "", ")"), tmp1, tmp2);

        auto tmp3 = $6;
        res = new IR(kWindowFuncCall_12, OP3("", "", ""), res, tmp3);

        auto tmp4 = $7;
        res = new IR(kWindowFuncCall, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | FIRST_VALUE_SYM '(' expr ')' opt_null_treatment windowing_clause {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kWindowFuncCall_13, OP3("FIRST_VALUE (", ")", ""), tmp1, tmp2);

        auto tmp3 = $6;
        res = new IR(kWindowFuncCall, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | LAST_VALUE_SYM '(' expr ')' opt_null_treatment windowing_clause {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kWindowFuncCall_14, OP3("LAST_VALUE (", ")", ""), tmp1, tmp2);

        auto tmp3 = $6;
        res = new IR(kWindowFuncCall, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | NTH_VALUE_SYM '(' expr ',' simple_expr ')' opt_from_first_last opt_null_treatment windowing_clause {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kWindowFuncCall_15, OP3("NTH_VALUE (", ",", ")"), tmp1, tmp2);

        auto tmp3 = $7;
        res = new IR(kWindowFuncCall_16, OP3("", "", ""), res, tmp3);

        auto tmp4 = $8;
        res = new IR(kWindowFuncCall_17, OP3("", "", ""), res, tmp4);

        auto tmp5 = $9;
        res = new IR(kWindowFuncCall, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

;


opt_lead_lag_info:

    /* Nothing */ {
        res = new IR(kOptLeadLagInfo, OP3("", "", ""));
        $$ = res;
    }

    | ',' stable_integer opt_ll_default {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kOptLeadLagInfo, OP3(",", "", ""), tmp1, tmp2);
        $$ = res;
    }

;

/*
The stable_integer nonterminal symbol is not really constant, but constant
for the duration of an execution.
*/

stable_integer:

    int64_literal {
        auto tmp1 = $1;
        res = new IR(kStableInteger, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | param_or_var {
        auto tmp1 = $1;
        res = new IR(kStableInteger, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


param_or_var:

    param_marker {
        auto tmp1 = $1;
        res = new IR(kParamOrVar, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ident {
        auto tmp1 = $1;
        res = new IR(kParamOrVar, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '@' ident_or_text {
        auto tmp1 = $2;
        res = new IR(kParamOrVar, OP3("@", "", ""), tmp1);
        $$ = res;
    }

;


opt_ll_default:

    /* Nothing */ {
        res = new IR(kOptLlDefault, OP3("", "", ""));
        $$ = res;
    }

    | ',' expr {
        auto tmp1 = $2;
        res = new IR(kOptLlDefault, OP3(",", "", ""), tmp1);
        $$ = res;
    }

;


opt_null_treatment:

    /* Nothing */ {
        res = new IR(kOptNullTreatment, OP3("", "", ""));
        $$ = res;
    }

    | RESPECT_SYM NULLS_SYM {
        res = new IR(kOptNullTreatment, OP3("RESPECT NULLS", "", ""));
        $$ = res;
    }

    | IGNORE_SYM NULLS_SYM {
        res = new IR(kOptNullTreatment, OP3("IGNORE NULLS", "", ""));
        $$ = res;
    }

;



opt_from_first_last:

    /* Nothing */ {
        res = new IR(kOptFromFirstLast, OP3("", "", ""));
        $$ = res;
    }

    | FROM FIRST_SYM {
        res = new IR(kOptFromFirstLast, OP3("FROM FIRST", "", ""));
        $$ = res;
    }

    | FROM LAST_SYM {
        res = new IR(kOptFromFirstLast, OP3("FROM LAST", "", ""));
        $$ = res;
    }

;


opt_windowing_clause:

    /* Nothing */ {
        res = new IR(kOptWindowingClause, OP3("", "", ""));
        $$ = res;
    }

    | windowing_clause {
        auto tmp1 = $1;
        res = new IR(kOptWindowingClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


windowing_clause:

    OVER_SYM window_name_or_spec {
        auto tmp1 = $2;
        res = new IR(kWindowingClause, OP3("OVER", "", ""), tmp1);
        $$ = res;
    }

;


window_name_or_spec:

    window_name {
        auto tmp1 = $1;
        res = new IR(kWindowNameOrSpec, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | window_spec {
        auto tmp1 = $1;
        res = new IR(kWindowNameOrSpec, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


window_name:

    ident {
        auto tmp1 = $1;
        res = new IR(kWindowName, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


window_spec:

    '(' window_spec_details ')' {
        auto tmp1 = $2;
        res = new IR(kWindowSpec, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

;


window_spec_details:

    opt_existing_window_name opt_partition_clause opt_window_order_by_clause opt_window_frame_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kWindowSpecDetails_1, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kWindowSpecDetails_2, OP3("", "", ""), res, tmp3);

        auto tmp4 = $4;
        res = new IR(kWindowSpecDetails, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


opt_existing_window_name:

    /* Nothing */ {
        res = new IR(kOptExistingWindowName, OP3("", "", ""));
        $$ = res;
    }

    | window_name {
        auto tmp1 = $1;
        res = new IR(kOptExistingWindowName, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_partition_clause:

    /* Nothing */ {
        res = new IR(kOptPartitionClause, OP3("", "", ""));
        $$ = res;
    }

    | PARTITION_SYM BY group_list {
        auto tmp1 = $3;
        res = new IR(kOptPartitionClause, OP3("PARTITION BY", "", ""), tmp1);
        $$ = res;
    }

;


opt_window_order_by_clause:

    /* Nothing */ {
        res = new IR(kOptWindowOrderByClause, OP3("", "", ""));
        $$ = res;
    }

    | ORDER_SYM BY order_list {
        auto tmp1 = $3;
        res = new IR(kOptWindowOrderByClause, OP3("ORDER BY", "", ""), tmp1);
        $$ = res;
    }

;


opt_window_frame_clause:

    /* Nothing*/ {
        res = new IR(kOptWindowFrameClause, OP3("", "", ""));
        $$ = res;
    }

    | window_frame_units window_frame_extent opt_window_frame_exclusion {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptWindowFrameClause_1, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kOptWindowFrameClause, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


window_frame_extent:

    window_frame_start {
        auto tmp1 = $1;
        res = new IR(kWindowFrameExtent, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | window_frame_between {
        auto tmp1 = $1;
        res = new IR(kWindowFrameExtent, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


window_frame_start:

    UNBOUNDED_SYM PRECEDING_SYM {
        res = new IR(kWindowFrameStart, OP3("UNBOUNDED PRECEDING", "", ""));
        $$ = res;
    }

    | NUM_literal PRECEDING_SYM {
        auto tmp1 = $1;
        res = new IR(kWindowFrameStart, OP3("", "PRECEDING", ""), tmp1);
        $$ = res;
    }

    | param_marker PRECEDING_SYM {
        auto tmp1 = $1;
        res = new IR(kWindowFrameStart, OP3("", "PRECEDING", ""), tmp1);
        $$ = res;
    }

    | INTERVAL_SYM expr interval PRECEDING_SYM {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kWindowFrameStart, OP3("INTERVAL", "", "PRECEDING"), tmp1, tmp2);
        $$ = res;
    }

    | CURRENT_SYM ROW_SYM {
        res = new IR(kWindowFrameStart, OP3("CURRENT ROW", "", ""));
        $$ = res;
    }

;


window_frame_between:

    BETWEEN_SYM window_frame_bound AND_SYM window_frame_bound {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kWindowFrameBetween, OP3("BETWEEN", "AND", ""), tmp1, tmp2);
        $$ = res;
    }

;


window_frame_bound:

    window_frame_start {
        auto tmp1 = $1;
        res = new IR(kWindowFrameBound, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | UNBOUNDED_SYM FOLLOWING_SYM {
        res = new IR(kWindowFrameBound, OP3("UNBOUNDED FOLLOWING", "", ""));
        $$ = res;
    }

    | NUM_literal FOLLOWING_SYM {
        auto tmp1 = $1;
        res = new IR(kWindowFrameBound, OP3("", "FOLLOWING", ""), tmp1);
        $$ = res;
    }

    | param_marker FOLLOWING_SYM {
        auto tmp1 = $1;
        res = new IR(kWindowFrameBound, OP3("", "FOLLOWING", ""), tmp1);
        $$ = res;
    }

    | INTERVAL_SYM expr interval FOLLOWING_SYM {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kWindowFrameBound, OP3("INTERVAL", "", "FOLLOWING"), tmp1, tmp2);
        $$ = res;
    }

;


opt_window_frame_exclusion:

    /* Nothing */ {
        res = new IR(kOptWindowFrameExclusion, OP3("", "", ""));
        $$ = res;
    }

    | EXCLUDE_SYM CURRENT_SYM ROW_SYM {
        res = new IR(kOptWindowFrameExclusion, OP3("EXCLUDE CURRENT ROW", "", ""));
        $$ = res;
    }

    | EXCLUDE_SYM GROUP_SYM {
        res = new IR(kOptWindowFrameExclusion, OP3("EXCLUDE GROUP", "", ""));
        $$ = res;
    }

    | EXCLUDE_SYM TIES_SYM {
        res = new IR(kOptWindowFrameExclusion, OP3("EXCLUDE TIES", "", ""));
        $$ = res;
    }

    | EXCLUDE_SYM NO_SYM OTHERS_SYM {
        res = new IR(kOptWindowFrameExclusion, OP3("EXCLUDE NO OTHERS", "", ""));
        $$ = res;
    }

;


window_frame_units:

    ROWS_SYM {
        res = new IR(kWindowFrameUnits, OP3("ROWS", "", ""));
        $$ = res;
    }

    | RANGE_SYM {
        res = new IR(kWindowFrameUnits, OP3("RANGE", "", ""));
        $$ = res;
    }

    | GROUPS_SYM {
        res = new IR(kWindowFrameUnits, OP3("GROUPS", "", ""));
        $$ = res;
    }

;


grouping_operation:

    GROUPING_SYM '(' expr_list ')' {
        auto tmp1 = $3;
        res = new IR(kGroupingOperation, OP3("GROUPING (", ")", ""), tmp1);
        $$ = res;
    }

;


variable:

    '@' variable_aux {
        auto tmp1 = $2;
        res = new IR(kVariable, OP3("@", "", ""), tmp1);
        $$ = res;
    }

;


variable_aux:

    ident_or_text SET_VAR expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kVariableAux, OP3("", "SET_VAR", ""), tmp1, tmp2);
        $$ = res;
    }

    | ident_or_text {
        auto tmp1 = $1;
        res = new IR(kVariableAux, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '@' opt_var_ident_type ident_or_text opt_component {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kVariableAux_1, OP3("@", "", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kVariableAux, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


opt_distinct:

    /* empty */ {
        res = new IR(kOptDistinct, OP3("", "", ""));
        $$ = res;
    }

    | DISTINCT {
        res = new IR(kOptDistinct, OP3("DISTINCT", "", ""));
        $$ = res;
    }

;


opt_gconcat_separator:

    /* empty */ {
        res = new IR(kOptGconcatSeparator, OP3("", "", ""));
        $$ = res;
    }

    | SEPARATOR_SYM text_string {
        auto tmp1 = $2;
        res = new IR(kOptGconcatSeparator, OP3("SEPARATOR", "", ""), tmp1);
        $$ = res;
    }

;


opt_gorder_clause:

    /* empty */ {
        res = new IR(kOptGorderClause, OP3("", "", ""));
        $$ = res;
    }

    | ORDER_SYM BY gorder_list {
        auto tmp1 = $3;
        res = new IR(kOptGorderClause, OP3("ORDER BY", "", ""), tmp1);
        $$ = res;
    }

;


gorder_list:

    gorder_list ',' order_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kGorderList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | order_expr {
        auto tmp1 = $1;
        res = new IR(kGorderList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


in_sum_expr:

    opt_all expr {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kInSumExpr, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


cast_type:

    BINARY_SYM opt_field_length {
        auto tmp1 = $2;
        res = new IR(kCastType, OP3("BINARY", "", ""), tmp1);
        $$ = res;
    }

    | CHAR_SYM opt_field_length opt_charset_with_opt_binary {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCastType, OP3("CHAR", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | nchar opt_field_length {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCastType, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | SIGNED_SYM {
        res = new IR(kCastType, OP3("SIGNED", "", ""));
        $$ = res;
    }

    | SIGNED_SYM INT_SYM {
        res = new IR(kCastType, OP3("SIGNED INT", "", ""));
        $$ = res;
    }

    | UNSIGNED_SYM {
        res = new IR(kCastType, OP3("UNSIGNED", "", ""));
        $$ = res;
    }

    | UNSIGNED_SYM INT_SYM {
        res = new IR(kCastType, OP3("UNSIGNED INT", "", ""));
        $$ = res;
    }

    | DATE_SYM {
        res = new IR(kCastType, OP3("DATE", "", ""));
        $$ = res;
    }

    | YEAR_SYM {
        res = new IR(kCastType, OP3("SQL_TSI_YEAR", "", ""));
        $$ = res;
    }

    | TIME_SYM type_datetime_precision {
        auto tmp1 = $2;
        res = new IR(kCastType, OP3("TIME", "", ""), tmp1);
        $$ = res;
    }

    | DATETIME_SYM type_datetime_precision {
        auto tmp1 = $2;
        res = new IR(kCastType, OP3("DATETIME", "", ""), tmp1);
        $$ = res;
    }

    | DECIMAL_SYM float_options {
        auto tmp1 = $2;
        res = new IR(kCastType, OP3("DEC", "", ""), tmp1);
        $$ = res;
    }

    | JSON_SYM {
        res = new IR(kCastType, OP3("JSON", "", ""));
        $$ = res;
    }

    | real_type {
        auto tmp1 = $1;
        res = new IR(kCastType, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | FLOAT_SYM standard_float_options {
        auto tmp1 = $2;
        res = new IR(kCastType, OP3("FLOAT", "", ""), tmp1);
        $$ = res;
    }

    | POINT_SYM {
        res = new IR(kCastType, OP3("POINT", "", ""));
        $$ = res;
    }

    | LINESTRING_SYM {
        res = new IR(kCastType, OP3("LINESTRING", "", ""));
        $$ = res;
    }

    | POLYGON_SYM {
        res = new IR(kCastType, OP3("POLYGON", "", ""));
        $$ = res;
    }

    | MULTIPOINT_SYM {
        res = new IR(kCastType, OP3("MULTIPOINT", "", ""));
        $$ = res;
    }

    | MULTILINESTRING_SYM {
        res = new IR(kCastType, OP3("MULTILINESTRING", "", ""));
        $$ = res;
    }

    | MULTIPOLYGON_SYM {
        res = new IR(kCastType, OP3("MULTIPOLYGON", "", ""));
        $$ = res;
    }

    | GEOMETRYCOLLECTION_SYM {
        res = new IR(kCastType, OP3("GEOMCOLLECTION", "", ""));
        $$ = res;
    }

;


opt_expr_list:

    /* empty */ {
        res = new IR(kOptExprList, OP3("", "", ""));
        $$ = res;
    }

    | expr_list {
        auto tmp1 = $1;
        res = new IR(kOptExprList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


expr_list:

    expr {
        auto tmp1 = $1;
        res = new IR(kExprList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | expr_list ',' expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kExprList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


ident_list_arg:

    ident_list {
        auto tmp1 = $1;
        res = new IR(kIdentListArg, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '(' ident_list ')' {
        auto tmp1 = $2;
        res = new IR(kIdentListArg, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

;


ident_list:

    simple_ident {
        auto tmp1 = $1;
        res = new IR(kIdentList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ident_list ',' simple_ident {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kIdentList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_expr:

    /* empty */ {
        res = new IR(kOptExpr, OP3("", "", ""));
        $$ = res;
    }

    | expr {
        auto tmp1 = $1;
        res = new IR(kOptExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_else:

    /* empty */ {
        res = new IR(kOptElse, OP3("", "", ""));
        $$ = res;
    }

    | ELSE expr {
        auto tmp1 = $2;
        res = new IR(kOptElse, OP3("ELSE", "", ""), tmp1);
        $$ = res;
    }

;


when_list:

    WHEN_SYM expr THEN_SYM expr {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kWhenList, OP3("WHEN", "THEN", ""), tmp1, tmp2);
        $$ = res;
    }

    | when_list WHEN_SYM expr THEN_SYM expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kWhenList_1, OP3("", "WHEN", "THEN"), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kWhenList, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


table_reference:

    table_factor {
        auto tmp1 = $1;
        res = new IR(kTableReference, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | joined_table {
        auto tmp1 = $1;
        res = new IR(kTableReference, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '{' OJ_SYM esc_table_reference '}' {
        auto tmp1 = $3;
        res = new IR(kTableReference, OP3("{ OJ ", "", "}"), tmp1);
        $$ = res;
    }

;


esc_table_reference:

    table_factor {
        auto tmp1 = $1;
        res = new IR(kEscTableReference, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | joined_table {
        auto tmp1 = $1;
        res = new IR(kEscTableReference, OP3("", "", ""), tmp1);
        $$ = res;
    }

;
/*
Join operations are normally left-associative, as in

t1 JOIN t2 ON t1.a = t2.a JOIN t3 ON t3.a = t2.a

This is equivalent to

(t1 JOIN t2 ON t1.a = t2.a) JOIN t3 ON t3.a = t2.a

They can also be right-associative without parentheses, e.g.

t1 JOIN t2 JOIN t3 ON t2.a = t3.a ON t1.a = t2.a

Which is equivalent to

t1 JOIN (t2 JOIN t3 ON t2.a = t3.a) ON t1.a = t2.a

In MySQL, JOIN and CROSS JOIN mean the same thing, i.e.:

- A join without a <join specification> is the same as a cross join.
- A cross join with a <join specification> is the same as an inner join.

For the join operation above, this means that the parser can't know until it
has seen the last ON whether `t1 JOIN t2` was a cross join or not. The only
way to solve the abiguity is to keep shifting the tokens on the stack, and
not reduce until the last ON is seen. We tell Bison this by adding a fake
token CONDITIONLESS_JOIN which has lower precedence than all tokens that
would continue the join. These are JOIN_SYM, INNER_SYM, CROSS,
STRAIGHT_JOIN, NATURAL, LEFT, RIGHT, ON and USING. This way the automaton
only reduces to a cross join unless no other interpretation is
possible. This gives a right-deep join tree for join *with* conditions,
which is what is expected.

The challenge here is that t1 JOIN t2 *could* have been a cross join, we
just don't know it until afterwards. So if the query had been

t1 JOIN t2 JOIN t3 ON t2.a = t3.a

we will first reduce `t2 JOIN t3 ON t2.a = t3.a` to a <table_reference>,
which is correct, but a problem arises when reducing t1 JOIN
<table_reference>. If we were to do that, we'd get a right-deep tree. The
solution is to build the tree downwards instead of upwards, as is normally
done. This concept may seem outlandish at first, but it's really quite
simple. When the semantic action for table_reference JOIN table_reference is
executed, the parse tree is (please pardon the ASCII graphic):

JOIN ON t2.a = t3.a
/    \
t2    t3

Now, normally we'd just add the cross join node on top of this tree, as:

JOIN
/    \
t1    JOIN ON t2.a = t3.a
/    \
t2    t3

This is not the meaning of the query, however. The cross join should be
addded at the bottom:


JOIN ON t2.a = t3.a
/    \
JOIN    t3
/    \
t1    t2

There is only one rule to pay attention to: If the right-hand side of a
cross join is a join tree, find its left-most leaf (which is a table
name). Then replace this table name with a cross join of the left-hand side
of the top cross join, and the right hand side with the original table.

Natural joins are also syntactically conditionless, but we need to make sure
that they are never right associative. We handle them in their own rule
natural_join, which is left-associative only. In this case we know that
there is no join condition to wait for, so we can reduce immediately.
*/

joined_table:

    table_reference inner_join_type table_reference ON_SYM expr {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kJoinedTable_1, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kJoinedTable_2, OP3("", "", "ON"), res, tmp3);

        auto tmp4 = $5;
        res = new IR(kJoinedTable, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | table_reference inner_join_type table_reference USING '(' using_list ')' {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kJoinedTable_3, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kJoinedTable_4, OP3("", "", "USING ("), res, tmp3);

        auto tmp4 = $6;
        res = new IR(kJoinedTable, OP3("", "", ")"), res, tmp4);
        $$ = res;
    }

    | table_reference outer_join_type table_reference ON_SYM expr {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kJoinedTable_5, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kJoinedTable_6, OP3("", "", "ON"), res, tmp3);

        auto tmp4 = $5;
        res = new IR(kJoinedTable, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | table_reference outer_join_type table_reference USING '(' using_list ')' {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kJoinedTable_7, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kJoinedTable_8, OP3("", "", "USING ("), res, tmp3);

        auto tmp4 = $6;
        res = new IR(kJoinedTable, OP3("", "", ")"), res, tmp4);
        $$ = res;
    }

    | table_reference inner_join_type table_reference %prec CONDITIONLESS_JOIN {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kJoinedTable_9, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kJoinedTable, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | table_reference natural_join_type table_factor {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kJoinedTable_10, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kJoinedTable, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


natural_join_type:

    NATURAL opt_inner JOIN_SYM {
        auto tmp1 = $2;
        res = new IR(kNaturalJoinType, OP3("NATURAL", "JOIN", ""), tmp1);
        $$ = res;
    }

    | NATURAL RIGHT opt_outer JOIN_SYM {
        auto tmp1 = $3;
        res = new IR(kNaturalJoinType, OP3("NATURAL RIGHT", "JOIN", ""), tmp1);
        $$ = res;
    }

    | NATURAL LEFT opt_outer JOIN_SYM {
        auto tmp1 = $3;
        res = new IR(kNaturalJoinType, OP3("NATURAL LEFT", "JOIN", ""), tmp1);
        $$ = res;
    }

;


inner_join_type:

    JOIN_SYM {
        res = new IR(kInnerJoinType, OP3("JOIN", "", ""));
        $$ = res;
    }

    | INNER_SYM JOIN_SYM {
        res = new IR(kInnerJoinType, OP3("INNER JOIN", "", ""));
        $$ = res;
    }

    | CROSS JOIN_SYM {
        res = new IR(kInnerJoinType, OP3("CROSS JOIN", "", ""));
        $$ = res;
    }

    | STRAIGHT_JOIN {
        res = new IR(kInnerJoinType, OP3("STRAIGHT_JOIN", "", ""));
        $$ = res;
    }

;


outer_join_type:

    LEFT opt_outer JOIN_SYM {
        auto tmp1 = $2;
        res = new IR(kOuterJoinType, OP3("LEFT", "JOIN", ""), tmp1);
        $$ = res;
    }

    | RIGHT opt_outer JOIN_SYM {
        auto tmp1 = $2;
        res = new IR(kOuterJoinType, OP3("RIGHT", "JOIN", ""), tmp1);
        $$ = res;
    }

;


opt_inner:

    /* empty */ {
        res = new IR(kOptInner, OP3("", "", ""));
        $$ = res;
    }

    | INNER_SYM {
        res = new IR(kOptInner, OP3("INNER", "", ""));
        $$ = res;
    }

;


opt_outer:

    /* empty */ {
        res = new IR(kOptOuter, OP3("", "", ""));
        $$ = res;
    }

    | OUTER_SYM {
        res = new IR(kOptOuter, OP3("OUTER", "", ""));
        $$ = res;
    }

;

/*
table PARTITION (list of partitions), reusing using_list instead of creating
a new rule for partition_list.
*/

opt_use_partition:

    /* empty */ {
        res = new IR(kOptUsePartition, OP3("", "", ""));
        $$ = res;
    }

    | use_partition {
        auto tmp1 = $1;
        res = new IR(kOptUsePartition, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


use_partition:

    PARTITION_SYM '(' using_list ')' {
        auto tmp1 = $3;
        res = new IR(kUsePartition, OP3("PARTITION (", ")", ""), tmp1);
        $$ = res;
    }

;

/**
MySQL has a syntax extension where a comma-separated list of table
references is allowed as a table reference in itself, for instance

SELECT * FROM (t1, t2) JOIN t3 ON 1

which is not allowed in standard SQL. The syntax is equivalent to

SELECT * FROM (t1 CROSS JOIN t2) JOIN t3 ON 1

We call this rule table_reference_list_parens.

A <table_factor> may be a <single_table>, a <subquery>, a <derived_table>, a
<joined_table>, or the bespoke <table_reference_list_parens>, each of those
enclosed in any number of parentheses. This makes for an ambiguous grammar
since a <table_factor> may also be enclosed in parentheses. We get around
this by designing the grammar so that a <table_factor> does not have
parentheses, but all the sub-cases of it have their own parentheses-rules,
i.e. <single_table_parens>, <joined_table_parens> and
<table_reference_list_parens>. It's a bit tedious but the grammar is
unambiguous and doesn't have shift/reduce conflicts.
*/

table_factor:

    single_table {
        auto tmp1 = $1;
        res = new IR(kTableFactor, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | single_table_parens {
        auto tmp1 = $1;
        res = new IR(kTableFactor, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | derived_table {
        auto tmp1 = $1;
        res = new IR(kTableFactor, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | joined_table_parens {
        auto tmp1 = $1;
        res = new IR(kTableFactor, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | table_reference_list_parens {
        auto tmp1 = $1;
        res = new IR(kTableFactor, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | table_function {
        auto tmp1 = $1;
        res = new IR(kTableFactor, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


table_reference_list_parens:

    '(' table_reference_list_parens ')' {
        auto tmp1 = $2;
        res = new IR(kTableReferenceListParens, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

    | '(' table_reference_list ',' table_reference ')' {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kTableReferenceListParens, OP3("(", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

;


single_table_parens:

    '(' single_table_parens ')' {
        auto tmp1 = $2;
        res = new IR(kSingleTableParens, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

    | '(' single_table ')' {
        auto tmp1 = $2;
        res = new IR(kSingleTableParens, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

;


single_table:

    table_ident opt_use_partition opt_table_alias opt_key_definition {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSingleTable_1, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kSingleTable_2, OP3("", "", ""), res, tmp3);

        auto tmp4 = $4;
        res = new IR(kSingleTable, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


joined_table_parens:

    '(' joined_table_parens ')' {
        auto tmp1 = $2;
        res = new IR(kJoinedTableParens, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

    | '(' joined_table ')' {
        auto tmp1 = $2;
        res = new IR(kJoinedTableParens, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

;


derived_table:

    table_subquery opt_table_alias opt_derived_column_list {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kDerivedTable_1, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kDerivedTable, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | LATERAL_SYM table_subquery opt_table_alias opt_derived_column_list {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kDerivedTable_2, OP3("LATERAL", "", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kDerivedTable, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


table_function:

    JSON_TABLE_SYM '(' expr ',' text_literal columns_clause ')' opt_table_alias {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kTableFunction_1, OP3("JSON_TABLE (", ",", ""), tmp1, tmp2);

        auto tmp3 = $6;
        res = new IR(kTableFunction_2, OP3("", "", ")"), res, tmp3);

        auto tmp4 = $8;
        res = new IR(kTableFunction, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


columns_clause:

    COLUMNS '(' columns_list ')' {
        auto tmp1 = $3;
        res = new IR(kColumnsClause, OP3("COLUMNS (", ")", ""), tmp1);
        $$ = res;
    }

;


columns_list:

    jt_column {
        auto tmp1 = $1;
        res = new IR(kColumnsList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | columns_list ',' jt_column {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kColumnsList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


jt_column:

    ident FOR_SYM ORDINALITY_SYM {
        auto tmp1 = $1;
        res = new IR(kJtColumn, OP3("", "FOR ORDINALITY", ""), tmp1);
        $$ = res;
    }

    | ident type opt_collate jt_column_type PATH_SYM text_literal opt_on_empty_or_error_json_table {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kJtColumn_1, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kJtColumn_2, OP3("", "", ""), res, tmp3);

        auto tmp4 = $4;
        res = new IR(kJtColumn_3, OP3("", "", "PATH"), res, tmp4);

        auto tmp5 = $6;
        res = new IR(kJtColumn_4, OP3("", "", ""), res, tmp5);

        auto tmp6 = $7;
        res = new IR(kJtColumn, OP3("", "", ""), res, tmp6);
        $$ = res;
    }

    | NESTED_SYM PATH_SYM text_literal columns_clause {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kJtColumn, OP3("NESTED PATH", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


jt_column_type:

    {} {
        res = new IR(kJtColumnType, OP3("", "", ""));
        $$ = res;
    }

    | EXISTS {
        res = new IR(kJtColumnType, OP3("EXISTS", "", ""));
        $$ = res;
    }

;

// The optional ON EMPTY and ON ERROR clauses for JSON_TABLE and
// JSON_VALUE. If both clauses are specified, the ON EMPTY clause
// should come before the ON ERROR clause.

opt_on_empty_or_error:

    /* empty */ {
        res = new IR(kOptOnEmptyOrError, OP3("", "", ""));
        $$ = res;
    }

    | on_empty {
        auto tmp1 = $1;
        res = new IR(kOptOnEmptyOrError, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | on_error {
        auto tmp1 = $1;
        res = new IR(kOptOnEmptyOrError, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | on_empty on_error {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptOnEmptyOrError, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;

// JSON_TABLE extends the syntax by allowing ON ERROR to come before ON EMPTY.

opt_on_empty_or_error_json_table:

    opt_on_empty_or_error {
        auto tmp1 = $1;
        res = new IR(kOptOnEmptyOrErrorJsonTable, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | on_error on_empty {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptOnEmptyOrErrorJsonTable, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


on_empty:

    json_on_response ON_SYM EMPTY_SYM {
        auto tmp1 = $1;
        res = new IR(kOnEmpty, OP3("", "ON EMPTY", ""), tmp1);
        $$ = res;
    }

;

on_error:

    json_on_response ON_SYM ERROR_SYM {
        auto tmp1 = $1;
        res = new IR(kOnError, OP3("", "ON ERROR", ""), tmp1);
        $$ = res;
    }

;

json_on_response:

    ERROR_SYM {
        res = new IR(kJsonOnResponse, OP3("ERROR", "", ""));
        $$ = res;
    }

    | NULL_SYM {
        res = new IR(kJsonOnResponse, OP3("NULL", "", ""));
        $$ = res;
    }

    | DEFAULT_SYM signed_literal {
        auto tmp1 = $2;
        res = new IR(kJsonOnResponse, OP3("DEFAULT", "", ""), tmp1);
        $$ = res;
    }

;


index_hint_clause:

    /* empty */ {
        res = new IR(kIndexHintClause, OP3("", "", ""));
        $$ = res;
    }

    | FOR_SYM JOIN_SYM {
        res = new IR(kIndexHintClause, OP3("FOR JOIN", "", ""));
        $$ = res;
    }

    | FOR_SYM ORDER_SYM BY {
        res = new IR(kIndexHintClause, OP3("FOR ORDER BY", "", ""));
        $$ = res;
    }

    | FOR_SYM GROUP_SYM BY {
        res = new IR(kIndexHintClause, OP3("FOR GROUP BY", "", ""));
        $$ = res;
    }

;


index_hint_type:

    FORCE_SYM {
        res = new IR(kIndexHintType, OP3("FORCE", "", ""));
        $$ = res;
    }

    | IGNORE_SYM {
        res = new IR(kIndexHintType, OP3("IGNORE", "", ""));
        $$ = res;
    }

;


index_hint_definition:

    index_hint_type key_or_index index_hint_clause '(' key_usage_list ')' {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kIndexHintDefinition_1, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kIndexHintDefinition_2, OP3("", "", "("), res, tmp3);

        auto tmp4 = $5;
        res = new IR(kIndexHintDefinition, OP3("", "", ")"), res, tmp4);
        $$ = res;
    }

    | USE_SYM key_or_index index_hint_clause '(' opt_key_usage_list ')' {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kIndexHintDefinition_3, OP3("USE", "", "("), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kIndexHintDefinition, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

;


index_hints_list:

    index_hint_definition {
        auto tmp1 = $1;
        res = new IR(kIndexHintsList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | index_hints_list index_hint_definition {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kIndexHintsList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_index_hints_list:

    /* empty */ {
        res = new IR(kOptIndexHintsList, OP3("", "", ""));
        $$ = res;
    }

    | index_hints_list {
        auto tmp1 = $1;
        res = new IR(kOptIndexHintsList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_key_definition:

    opt_index_hints_list {
        auto tmp1 = $1;
        res = new IR(kOptKeyDefinition, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_key_usage_list:

    /* empty */ {
        res = new IR(kOptKeyUsageList, OP3("", "", ""));
        $$ = res;
    }

    | key_usage_list {
        auto tmp1 = $1;
        res = new IR(kOptKeyUsageList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


key_usage_element:

    ident {
        auto tmp1 = $1;
        res = new IR(kKeyUsageElement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | PRIMARY_SYM {
        res = new IR(kKeyUsageElement, OP3("PRIMARY", "", ""));
        $$ = res;
    }

;


key_usage_list:

    key_usage_element {
        auto tmp1 = $1;
        res = new IR(kKeyUsageList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | key_usage_list ',' key_usage_element {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kKeyUsageList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


using_list:

    ident_string_list {
        auto tmp1 = $1;
        res = new IR(kUsingList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


ident_string_list:

    ident {
        auto tmp1 = $1;
        res = new IR(kIdentStringList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ident_string_list ',' ident {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kIdentStringList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


interval:

    interval_time_stamp {
        auto tmp1 = $1;
        res = new IR(kInterval, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DAY_HOUR_SYM {
        res = new IR(kInterval, OP3("DAY_HOUR", "", ""));
        $$ = res;
    }

    | DAY_MICROSECOND_SYM {
        res = new IR(kInterval, OP3("DAY_MICROSECOND", "", ""));
        $$ = res;
    }

    | DAY_MINUTE_SYM {
        res = new IR(kInterval, OP3("DAY_MINUTE", "", ""));
        $$ = res;
    }

    | DAY_SECOND_SYM {
        res = new IR(kInterval, OP3("DAY_SECOND", "", ""));
        $$ = res;
    }

    | HOUR_MICROSECOND_SYM {
        res = new IR(kInterval, OP3("HOUR_MICROSECOND", "", ""));
        $$ = res;
    }

    | HOUR_MINUTE_SYM {
        res = new IR(kInterval, OP3("HOUR_MINUTE", "", ""));
        $$ = res;
    }

    | HOUR_SECOND_SYM {
        res = new IR(kInterval, OP3("HOUR_SECOND", "", ""));
        $$ = res;
    }

    | MINUTE_MICROSECOND_SYM {
        res = new IR(kInterval, OP3("MINUTE_MICROSECOND", "", ""));
        $$ = res;
    }

    | MINUTE_SECOND_SYM {
        res = new IR(kInterval, OP3("MINUTE_SECOND", "", ""));
        $$ = res;
    }

    | SECOND_MICROSECOND_SYM {
        res = new IR(kInterval, OP3("SECOND_MICROSECOND", "", ""));
        $$ = res;
    }

    | YEAR_MONTH_SYM {
        res = new IR(kInterval, OP3("YEAR_MONTH", "", ""));
        $$ = res;
    }

;


interval_time_stamp:

    DAY_SYM {
        res = new IR(kIntervalTimeStamp, OP3("DAY", "", ""));
        $$ = res;
    }

    | WEEK_SYM {
        res = new IR(kIntervalTimeStamp, OP3("SQL_TSI_WEEK", "", ""));
        $$ = res;
    }

    | HOUR_SYM {
        res = new IR(kIntervalTimeStamp, OP3("HOUR", "", ""));
        $$ = res;
    }

    | MINUTE_SYM {
        res = new IR(kIntervalTimeStamp, OP3("MINUTE", "", ""));
        $$ = res;
    }

    | MONTH_SYM {
        res = new IR(kIntervalTimeStamp, OP3("MONTH", "", ""));
        $$ = res;
    }

    | QUARTER_SYM {
        res = new IR(kIntervalTimeStamp, OP3("QUARTER", "", ""));
        $$ = res;
    }

    | SECOND_SYM {
        res = new IR(kIntervalTimeStamp, OP3("SECOND", "", ""));
        $$ = res;
    }

    | MICROSECOND_SYM {
        res = new IR(kIntervalTimeStamp, OP3("MICROSECOND", "", ""));
        $$ = res;
    }

    | YEAR_SYM {
        res = new IR(kIntervalTimeStamp, OP3("SQL_TSI_YEAR", "", ""));
        $$ = res;
    }

;


date_time_type:

    DATE_SYM {
        res = new IR(kDateTimeType, OP3("DATE", "", ""));
        $$ = res;
    }

    | TIME_SYM {
        res = new IR(kDateTimeType, OP3("TIME", "", ""));
        $$ = res;
    }

    | TIMESTAMP_SYM {
        res = new IR(kDateTimeType, OP3("TIMESTAMP", "", ""));
        $$ = res;
    }

    | DATETIME_SYM {
        res = new IR(kDateTimeType, OP3("DATETIME", "", ""));
        $$ = res;
    }

;


opt_as:

    /* empty */ {
        res = new IR(kOptAs, OP3("", "", ""));
        $$ = res;
    }

    | AS {
        res = new IR(kOptAs, OP3("AS", "", ""));
        $$ = res;
    }

;


opt_table_alias:

    /* empty */ {
        res = new IR(kOptTableAlias, OP3("", "", ""));
        $$ = res;
    }

    | opt_as ident {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptTableAlias, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_all:

    /* empty */ {
        res = new IR(kOptAll, OP3("", "", ""));
        $$ = res;
    }

    | ALL {
        res = new IR(kOptAll, OP3("ALL", "", ""));
        $$ = res;
    }

;


opt_where_clause:

    /* empty */ {
        res = new IR(kOptWhereClause, OP3("", "", ""));
        $$ = res;
    }

    | where_clause {
        auto tmp1 = $1;
        res = new IR(kOptWhereClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


where_clause:

    WHERE expr {
        auto tmp1 = $2;
        res = new IR(kWhereClause, OP3("WHERE", "", ""), tmp1);
        $$ = res;
    }

;


opt_having_clause:

    /* empty */ {
        res = new IR(kOptHavingClause, OP3("", "", ""));
        $$ = res;
    }

    | HAVING expr {
        auto tmp1 = $2;
        res = new IR(kOptHavingClause, OP3("HAVING", "", ""), tmp1);
        $$ = res;
    }

;


with_clause:

    WITH with_list {
        auto tmp1 = $2;
        res = new IR(kWithClause, OP3("WITH", "", ""), tmp1);
        $$ = res;
    }

    | WITH RECURSIVE_SYM with_list {
        auto tmp1 = $3;
        res = new IR(kWithClause, OP3("WITH RECURSIVE", "", ""), tmp1);
        $$ = res;
    }

;


with_list:

    with_list ',' common_table_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kWithList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | common_table_expr {
        auto tmp1 = $1;
        res = new IR(kWithList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


common_table_expr:

    ident opt_derived_column_list AS table_subquery {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCommonTableExpr_1, OP3("", "", "AS"), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kCommonTableExpr, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


opt_derived_column_list:

    /* empty */ {
        res = new IR(kOptDerivedColumnList, OP3("", "", ""));
        $$ = res;
    }

    | '(' simple_ident_list ')' {
        auto tmp1 = $2;
        res = new IR(kOptDerivedColumnList, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

;


simple_ident_list:

    ident {
        auto tmp1 = $1;
        res = new IR(kSimpleIdentList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | simple_ident_list ',' ident {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSimpleIdentList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_window_clause:

    /* Nothing */ {
        res = new IR(kOptWindowClause, OP3("", "", ""));
        $$ = res;
    }

    | WINDOW_SYM window_definition_list {
        auto tmp1 = $2;
        res = new IR(kOptWindowClause, OP3("WINDOW", "", ""), tmp1);
        $$ = res;
    }

;


window_definition_list:

    window_definition {
        auto tmp1 = $1;
        res = new IR(kWindowDefinitionList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | window_definition_list ',' window_definition {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kWindowDefinitionList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


window_definition:

    window_name AS window_spec {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kWindowDefinition, OP3("", "AS", ""), tmp1, tmp2);
        $$ = res;
    }

;

/*
group by statement in select
*/


opt_group_clause:

    /* empty */ {
        res = new IR(kOptGroupClause, OP3("", "", ""));
        $$ = res;
    }

    | GROUP_SYM BY group_list olap_opt {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kOptGroupClause, OP3("GROUP BY", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


group_list:

    group_list ',' grouping_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kGroupList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | grouping_expr {
        auto tmp1 = $1;
        res = new IR(kGroupList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;



olap_opt:

    /* empty */ {
        res = new IR(kOlapOpt, OP3("", "", ""));
        $$ = res;
    }

    | WITH_ROLLUP_SYM  {
        res = new IR(kOlapOpt, OP3("WITH ROLLUP", "", ""));
        $$ = res;
    }

;

/*
Order by statement in ALTER TABLE
*/


alter_order_list:

    alter_order_list ',' alter_order_item {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAlterOrderList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | alter_order_item {
        auto tmp1 = $1;
        res = new IR(kAlterOrderList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


alter_order_item:

    simple_ident_nospvar opt_ordering_direction {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAlterOrderItem, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_order_clause:

    /* empty */ {
        res = new IR(kOptOrderClause, OP3("", "", ""));
        $$ = res;
    }

    | order_clause {
        auto tmp1 = $1;
        res = new IR(kOptOrderClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


order_clause:

    ORDER_SYM BY order_list {
        auto tmp1 = $3;
        res = new IR(kOrderClause, OP3("ORDER BY", "", ""), tmp1);
        $$ = res;
    }

;


order_list:

    order_list ',' order_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kOrderList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | order_expr {
        auto tmp1 = $1;
        res = new IR(kOrderList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_ordering_direction:

    /* empty */ {
        res = new IR(kOptOrderingDirection, OP3("", "", ""));
        $$ = res;
    }

    | ordering_direction {
        auto tmp1 = $1;
        res = new IR(kOptOrderingDirection, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


ordering_direction:

    ASC {
        res = new IR(kOrderingDirection, OP3("ASC", "", ""));
        $$ = res;
    }

    | DESC {
        res = new IR(kOrderingDirection, OP3("DESC", "", ""));
        $$ = res;
    }

;


opt_limit_clause:

    /* empty */ {
        res = new IR(kOptLimitClause, OP3("", "", ""));
        $$ = res;
    }

    | limit_clause {
        auto tmp1 = $1;
        res = new IR(kOptLimitClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


limit_clause:

    LIMIT limit_options {
        auto tmp1 = $2;
        res = new IR(kLimitClause, OP3("LIMIT", "", ""), tmp1);
        $$ = res;
    }

;


limit_options:

    limit_option {
        auto tmp1 = $1;
        res = new IR(kLimitOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | limit_option ',' limit_option {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kLimitOptions, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | limit_option OFFSET_SYM limit_option {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kLimitOptions, OP3("", "OFFSET", ""), tmp1, tmp2);
        $$ = res;
    }

;


limit_option:

    ident {
        auto tmp1 = $1;
        res = new IR(kLimitOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | param_marker {
        auto tmp1 = $1;
        res = new IR(kLimitOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ULONGLONG_NUM {
        res = new IR(kLimitOption, OP3("ULONGLONG_NUM", "", ""));
        $$ = res;
    }

    | LONG_NUM {
        res = new IR(kLimitOption, OP3("LONG_NUM", "", ""));
        $$ = res;
    }

    | NUM {
        res = new IR(kLimitOption, OP3("NUM", "", ""));
        $$ = res;
    }

;


opt_simple_limit:

    /* empty */ {
        res = new IR(kOptSimpleLimit, OP3("", "", ""));
        $$ = res;
    }

    | LIMIT limit_option {
        auto tmp1 = $2;
        res = new IR(kOptSimpleLimit, OP3("LIMIT", "", ""), tmp1);
        $$ = res;
    }

;


ulong_num:

    NUM {
        res = new IR(kUlongNum, OP3("NUM", "", ""));
        $$ = res;
    }

    | HEX_NUM {
        res = new IR(kUlongNum, OP3("HEX_NUM", "", ""));
        $$ = res;
    }

    | LONG_NUM {
        res = new IR(kUlongNum, OP3("LONG_NUM", "", ""));
        $$ = res;
    }

    | ULONGLONG_NUM {
        res = new IR(kUlongNum, OP3("ULONGLONG_NUM", "", ""));
        $$ = res;
    }

    | DECIMAL_NUM {
        res = new IR(kUlongNum, OP3("DECIMAL_NUM", "", ""));
        $$ = res;
    }

    | FLOAT_NUM {
        res = new IR(kUlongNum, OP3("FLOAT_NUM", "", ""));
        $$ = res;
    }

;


real_ulong_num:

    NUM {
        res = new IR(kRealUlongNum, OP3("NUM", "", ""));
        $$ = res;
    }

    | HEX_NUM {
        res = new IR(kRealUlongNum, OP3("HEX_NUM", "", ""));
        $$ = res;
    }

    | LONG_NUM {
        res = new IR(kRealUlongNum, OP3("LONG_NUM", "", ""));
        $$ = res;
    }

    | ULONGLONG_NUM {
        res = new IR(kRealUlongNum, OP3("ULONGLONG_NUM", "", ""));
        $$ = res;
    }

    | dec_num_error {
        auto tmp1 = $1;
        res = new IR(kRealUlongNum, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


ulonglong_num:

    NUM {
        res = new IR(kUlonglongNum, OP3("NUM", "", ""));
        $$ = res;
    }

    | ULONGLONG_NUM {
        res = new IR(kUlonglongNum, OP3("ULONGLONG_NUM", "", ""));
        $$ = res;
    }

    | LONG_NUM {
        res = new IR(kUlonglongNum, OP3("LONG_NUM", "", ""));
        $$ = res;
    }

    | DECIMAL_NUM {
        res = new IR(kUlonglongNum, OP3("DECIMAL_NUM", "", ""));
        $$ = res;
    }

    | FLOAT_NUM {
        res = new IR(kUlonglongNum, OP3("FLOAT_NUM", "", ""));
        $$ = res;
    }

;


real_ulonglong_num:

    NUM {
        res = new IR(kRealUlonglongNum, OP3("NUM", "", ""));
        $$ = res;
    }

    | HEX_NUM {
        res = new IR(kRealUlonglongNum, OP3("HEX_NUM", "", ""));
        $$ = res;
    }

    | ULONGLONG_NUM {
        res = new IR(kRealUlonglongNum, OP3("ULONGLONG_NUM", "", ""));
        $$ = res;
    }

    | LONG_NUM {
        res = new IR(kRealUlonglongNum, OP3("LONG_NUM", "", ""));
        $$ = res;
    }

    | dec_num_error {
        auto tmp1 = $1;
        res = new IR(kRealUlonglongNum, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


dec_num_error:

    dec_num {
        auto tmp1 = $1;
        res = new IR(kDecNumError, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


dec_num:

    DECIMAL_NUM {
        res = new IR(kDecNum, OP3("DECIMAL_NUM", "", ""));
        $$ = res;
    }

    | FLOAT_NUM {
        res = new IR(kDecNum, OP3("FLOAT_NUM", "", ""));
        $$ = res;
    }

;


select_var_list:

    select_var_list ',' select_var_ident {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSelectVarList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | select_var_ident {
        auto tmp1 = $1;
        res = new IR(kSelectVarList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


select_var_ident:

    '@' ident_or_text {
        auto tmp1 = $2;
        res = new IR(kSelectVarIdent, OP3("@", "", ""), tmp1);
        $$ = res;
    }

    | ident_or_text {
        auto tmp1 = $1;
        res = new IR(kSelectVarIdent, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


into_clause:

    INTO into_destination {
        auto tmp1 = $2;
        res = new IR(kIntoClause, OP3("INTO", "", ""), tmp1);
        $$ = res;
    }

;


into_destination:

    OUTFILE TEXT_STRING_filesystem opt_load_data_charset opt_field_term opt_line_term {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kIntoDestination_1, OP3("OUTFILE", "", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kIntoDestination_2, OP3("", "", ""), res, tmp3);

        auto tmp4 = $5;
        res = new IR(kIntoDestination, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | DUMPFILE TEXT_STRING_filesystem {
        auto tmp1 = $2;
        res = new IR(kIntoDestination, OP3("DUMPFILE", "", ""), tmp1);
        $$ = res;
    }

    | select_var_list {
        auto tmp1 = $1;
        res = new IR(kIntoDestination, OP3("", "", ""), tmp1);
        $$ = res;
    }

;

/*
DO statement
*/


do_stmt:

    DO_SYM select_item_list {
        auto tmp1 = $2;
        res = new IR(kDoStmt, OP3("DO", "", ""), tmp1);
        $$ = res;
    }

;

/*
Drop : delete tables or index or user or role
*/


drop_table_stmt:

    DROP opt_temporary table_or_tables if_exists table_list opt_restrict {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kDropTableStmt_1, OP3("DROP", "", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kDropTableStmt_2, OP3("", "", ""), res, tmp3);

        auto tmp4 = $5;
        res = new IR(kDropTableStmt_3, OP3("", "", ""), res, tmp4);

        auto tmp5 = $6;
        res = new IR(kDropTableStmt, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

;


drop_index_stmt:

    DROP INDEX_SYM ident ON_SYM table_ident opt_index_lock_and_algorithm {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kDropIndexStmt_1, OP3("DROP INDEX", "ON", ""), tmp1, tmp2);

        auto tmp3 = $6;
        res = new IR(kDropIndexStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


drop_database_stmt:

    DROP DATABASE if_exists ident {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kDropDatabaseStmt, OP3("DROP DATABASE", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


drop_function_stmt:

    DROP FUNCTION_SYM if_exists ident '.' ident {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kDropFunctionStmt_1, OP3("DROP FUNCTION", "", "."), tmp1, tmp2);

        auto tmp3 = $6;
        res = new IR(kDropFunctionStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | DROP FUNCTION_SYM if_exists ident {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kDropFunctionStmt, OP3("DROP FUNCTION", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


drop_resource_group_stmt:

    DROP RESOURCE_SYM GROUP_SYM ident opt_force {
        auto tmp1 = $4;
        auto tmp2 = $5;
        res = new IR(kDropResourceGroupStmt, OP3("DROP RESOURCE GROUP", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


drop_procedure_stmt:

    DROP PROCEDURE_SYM if_exists sp_name {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kDropProcedureStmt, OP3("DROP PROCEDURE", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


drop_user_stmt:

    DROP USER if_exists user_list {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kDropUserStmt, OP3("DROP USER", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


drop_view_stmt:

    DROP VIEW_SYM if_exists table_list opt_restrict {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kDropViewStmt_1, OP3("DROP VIEW", "", ""), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kDropViewStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


drop_event_stmt:

    DROP EVENT_SYM if_exists sp_name {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kDropEventStmt, OP3("DROP EVENT", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


drop_trigger_stmt:

    DROP TRIGGER_SYM if_exists sp_name {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kDropTriggerStmt, OP3("DROP TRIGGER", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


drop_tablespace_stmt:

    DROP TABLESPACE_SYM ident opt_drop_ts_options {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kDropTablespaceStmt, OP3("DROP TABLESPACE", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


drop_undo_tablespace_stmt:

    DROP UNDO_SYM TABLESPACE_SYM ident opt_undo_tablespace_options {
        auto tmp1 = $4;
        auto tmp2 = $5;
        res = new IR(kDropUndoTablespaceStmt, OP3("DROP UNDO TABLESPACE", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


drop_logfile_stmt:

    DROP LOGFILE_SYM GROUP_SYM ident opt_drop_ts_options {
        auto tmp1 = $4;
        auto tmp2 = $5;
        res = new IR(kDropLogfileStmt, OP3("DROP LOGFILE GROUP", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


drop_server_stmt:

    DROP SERVER_SYM if_exists ident_or_text {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kDropServerStmt, OP3("DROP SERVER", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


drop_srs_stmt:

    DROP SPATIAL_SYM REFERENCE_SYM SYSTEM_SYM if_exists real_ulonglong_num {
        auto tmp1 = $5;
        auto tmp2 = $6;
        res = new IR(kDropSrsStmt, OP3("DROP SPATIAL REFERENCE SYSTEM", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


drop_role_stmt:

    DROP ROLE_SYM if_exists role_list {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kDropRoleStmt, OP3("DROP ROLE", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


table_list:

    table_ident {
        auto tmp1 = $1;
        res = new IR(kTableList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | table_list ',' table_ident {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTableList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


table_alias_ref_list:

    table_ident_opt_wild {
        auto tmp1 = $1;
        res = new IR(kTableAliasRefList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | table_alias_ref_list ',' table_ident_opt_wild {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTableAliasRefList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


if_exists:

    /* empty */ {
        res = new IR(kIfExists, OP3("", "", ""));
        $$ = res;
    }

    | IF EXISTS {
        res = new IR(kIfExists, OP3("IF EXISTS", "", ""));
        $$ = res;
    }

;


opt_temporary:

    /* empty */ {
        res = new IR(kOptTemporary, OP3("", "", ""));
        $$ = res;
    }

    | TEMPORARY {
        res = new IR(kOptTemporary, OP3("TEMPORARY", "", ""));
        $$ = res;
    }

;


opt_drop_ts_options:

    /* empty*/ {
        res = new IR(kOptDropTsOptions, OP3("", "", ""));
        $$ = res;
    }

    | drop_ts_option_list {
        auto tmp1 = $1;
        res = new IR(kOptDropTsOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


drop_ts_option_list:

    drop_ts_option {
        auto tmp1 = $1;
        res = new IR(kDropTsOptionList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | drop_ts_option_list opt_comma drop_ts_option {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kDropTsOptionList_1, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kDropTsOptionList, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


drop_ts_option:

    ts_option_engine {
        auto tmp1 = $1;
        res = new IR(kDropTsOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ts_option_wait {
        auto tmp1 = $1;
        res = new IR(kDropTsOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

;
/*
** Insert : add new data to table
*/


insert_stmt:

    INSERT_SYM insert_lock_option opt_ignore opt_INTO table_ident opt_use_partition insert_from_constructor opt_values_reference opt_insert_update_list {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kInsertStmt_1, OP3("INSERT", "", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kInsertStmt_2, OP3("", "", ""), res, tmp3);

        auto tmp4 = $5;
        res = new IR(kInsertStmt_3, OP3("", "", ""), res, tmp4);

        auto tmp5 = $6;
        res = new IR(kInsertStmt_4, OP3("", "", ""), res, tmp5);

        auto tmp6 = $7;
        res = new IR(kInsertStmt_5, OP3("", "", ""), res, tmp6);

        auto tmp7 = $8;
        res = new IR(kInsertStmt_6, OP3("", "", ""), res, tmp7);

        auto tmp8 = $9;
        res = new IR(kInsertStmt, OP3("", "", ""), res, tmp8);
        $$ = res;
    }

    | INSERT_SYM insert_lock_option opt_ignore opt_INTO table_ident opt_use_partition SET_SYM update_list opt_values_reference opt_insert_update_list {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kInsertStmt_7, OP3("INSERT", "", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kInsertStmt_8, OP3("", "", ""), res, tmp3);

        auto tmp4 = $5;
        res = new IR(kInsertStmt_9, OP3("", "", ""), res, tmp4);

        auto tmp5 = $6;
        res = new IR(kInsertStmt_10, OP3("", "", "SET"), res, tmp5);

        auto tmp6 = $8;
        res = new IR(kInsertStmt_11, OP3("", "", ""), res, tmp6);

        auto tmp7 = $9;
        res = new IR(kInsertStmt_12, OP3("", "", ""), res, tmp7);

        auto tmp8 = $10;
        res = new IR(kInsertStmt, OP3("", "", ""), res, tmp8);
        $$ = res;
    }

    | INSERT_SYM insert_lock_option opt_ignore opt_INTO table_ident opt_use_partition insert_query_expression opt_insert_update_list {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kInsertStmt_13, OP3("INSERT", "", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kInsertStmt_14, OP3("", "", ""), res, tmp3);

        auto tmp4 = $5;
        res = new IR(kInsertStmt_15, OP3("", "", ""), res, tmp4);

        auto tmp5 = $6;
        res = new IR(kInsertStmt_16, OP3("", "", ""), res, tmp5);

        auto tmp6 = $7;
        res = new IR(kInsertStmt_17, OP3("", "", ""), res, tmp6);

        auto tmp7 = $8;
        res = new IR(kInsertStmt, OP3("", "", ""), res, tmp7);
        $$ = res;
    }

;


replace_stmt:

    REPLACE_SYM replace_lock_option opt_INTO table_ident opt_use_partition insert_from_constructor {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kReplaceStmt_1, OP3("REPLACE", "", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kReplaceStmt_2, OP3("", "", ""), res, tmp3);

        auto tmp4 = $5;
        res = new IR(kReplaceStmt_3, OP3("", "", ""), res, tmp4);

        auto tmp5 = $6;
        res = new IR(kReplaceStmt, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

    | REPLACE_SYM replace_lock_option opt_INTO table_ident opt_use_partition SET_SYM update_list {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kReplaceStmt_4, OP3("REPLACE", "", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kReplaceStmt_5, OP3("", "", ""), res, tmp3);

        auto tmp4 = $5;
        res = new IR(kReplaceStmt_6, OP3("", "", "SET"), res, tmp4);

        auto tmp5 = $7;
        res = new IR(kReplaceStmt, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

    | REPLACE_SYM replace_lock_option opt_INTO table_ident opt_use_partition insert_query_expression {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kReplaceStmt_7, OP3("REPLACE", "", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kReplaceStmt_8, OP3("", "", ""), res, tmp3);

        auto tmp4 = $5;
        res = new IR(kReplaceStmt_9, OP3("", "", ""), res, tmp4);

        auto tmp5 = $6;
        res = new IR(kReplaceStmt, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

;


insert_lock_option:

    /* empty */ {
        res = new IR(kInsertLockOption, OP3("", "", ""));
        $$ = res;
    }

    | LOW_PRIORITY {
        res = new IR(kInsertLockOption, OP3("LOW_PRIORITY", "", ""));
        $$ = res;
    }

    | DELAYED_SYM {
        res = new IR(kInsertLockOption, OP3("DELAYED", "", ""));
        $$ = res;
    }

    | HIGH_PRIORITY {
        res = new IR(kInsertLockOption, OP3("HIGH_PRIORITY", "", ""));
        $$ = res;
    }

;


replace_lock_option:

    opt_low_priority {
        auto tmp1 = $1;
        res = new IR(kReplaceLockOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DELAYED_SYM {
        res = new IR(kReplaceLockOption, OP3("DELAYED", "", ""));
        $$ = res;
    }

;


opt_INTO:

    /* empty */ {
        res = new IR(kOptINTO, OP3("", "", ""));
        $$ = res;
    }

    | INTO {
        res = new IR(kOptINTO, OP3("INTO", "", ""));
        $$ = res;
    }

;


insert_from_constructor:

    insert_values {
        auto tmp1 = $1;
        res = new IR(kInsertFromConstructor, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '(' ')' insert_values {
        auto tmp1 = $3;
        res = new IR(kInsertFromConstructor, OP3("( )", "", ""), tmp1);
        $$ = res;
    }

    | '(' fields ')' insert_values {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kInsertFromConstructor, OP3("(", ")", ""), tmp1, tmp2);
        $$ = res;
    }

;


insert_query_expression:

    query_expression_or_parens {
        auto tmp1 = $1;
        res = new IR(kInsertQueryExpression, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '(' ')' query_expression_or_parens {
        auto tmp1 = $3;
        res = new IR(kInsertQueryExpression, OP3("( )", "", ""), tmp1);
        $$ = res;
    }

    | '(' fields ')' query_expression_or_parens {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kInsertQueryExpression, OP3("(", ")", ""), tmp1, tmp2);
        $$ = res;
    }

;


fields:

    fields ',' insert_ident {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kFields, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | insert_ident {
        auto tmp1 = $1;
        res = new IR(kFields, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


insert_values:

    value_or_values values_list {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kInsertValues, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


query_expression_or_parens:

    query_expression {
        auto tmp1 = $1;
        res = new IR(kQueryExpressionOrParens, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | query_expression locking_clause_list {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kQueryExpressionOrParens, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | query_expression_parens {
        auto tmp1 = $1;
        res = new IR(kQueryExpressionOrParens, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


value_or_values:

    VALUE_SYM {
        res = new IR(kValueOrValues, OP3("VALUE", "", ""));
        $$ = res;
    }

    | VALUES {
        res = new IR(kValueOrValues, OP3("VALUES", "", ""));
        $$ = res;
    }

;


values_list:

    values_list ',' row_value {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kValuesList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | row_value {
        auto tmp1 = $1;
        res = new IR(kValuesList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;



values_row_list:

    values_row_list ',' row_value_explicit {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kValuesRowList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | row_value_explicit {
        auto tmp1 = $1;
        res = new IR(kValuesRowList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


equal:

    EQ {
        res = new IR(kEqual, OP3("=", "", ""));
        $$ = res;
    }

    | SET_VAR {
        res = new IR(kEqual, OP3("SET_VAR", "", ""));
        $$ = res;
    }

;


opt_equal:

    /* empty */ {
        res = new IR(kOptEqual, OP3("", "", ""));
        $$ = res;
    }

    | equal {
        auto tmp1 = $1;
        res = new IR(kOptEqual, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


row_value:

    '(' opt_values ')' {
        auto tmp1 = $2;
        res = new IR(kRowValue, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

;


row_value_explicit:

    ROW_SYM '(' opt_values ')' {
        auto tmp1 = $3;
        res = new IR(kRowValueExplicit, OP3("ROW (", ")", ""), tmp1);
        $$ = res;
    }

;


opt_values:

    /* empty */ {
        res = new IR(kOptValues, OP3("", "", ""));
        $$ = res;
    }

    | values {
        auto tmp1 = $1;
        res = new IR(kOptValues, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


values:

    values ',' expr_or_default {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kValues, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | expr_or_default {
        auto tmp1 = $1;
        res = new IR(kValues, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


expr_or_default:

    expr {
        auto tmp1 = $1;
        res = new IR(kExprOrDefault, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DEFAULT_SYM {
        res = new IR(kExprOrDefault, OP3("DEFAULT", "", ""));
        $$ = res;
    }

;


opt_values_reference:

    /* empty */ {
        res = new IR(kOptValuesReference, OP3("", "", ""));
        $$ = res;
    }

    | AS ident opt_derived_column_list {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kOptValuesReference, OP3("AS", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_insert_update_list:

    /* empty */ {
        res = new IR(kOptInsertUpdateList, OP3("", "", ""));
        $$ = res;
    }

    | ON_SYM DUPLICATE_SYM KEY_SYM UPDATE_SYM update_list {
        auto tmp1 = $5;
        res = new IR(kOptInsertUpdateList, OP3("ON DUPLICATE KEY UPDATE", "", ""), tmp1);
        $$ = res;
    }

;

/* Update rows in a table */


update_stmt:

    opt_with_clause UPDATE_SYM opt_low_priority opt_ignore table_reference_list SET_SYM update_list opt_where_clause opt_order_clause opt_simple_limit {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kUpdateStmt_1, OP3("", "UPDATE", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kUpdateStmt_2, OP3("", "", ""), res, tmp3);

        auto tmp4 = $5;
        res = new IR(kUpdateStmt_3, OP3("", "", "SET"), res, tmp4);

        auto tmp5 = $7;
        res = new IR(kUpdateStmt_4, OP3("", "", ""), res, tmp5);

        auto tmp6 = $8;
        res = new IR(kUpdateStmt_5, OP3("", "", ""), res, tmp6);

        auto tmp7 = $9;
        res = new IR(kUpdateStmt_6, OP3("", "", ""), res, tmp7);

        auto tmp8 = $10;
        res = new IR(kUpdateStmt, OP3("", "", ""), res, tmp8);
        $$ = res;
    }

;


opt_with_clause:

    /* empty */ {
        res = new IR(kOptWithClause, OP3("", "", ""));
        $$ = res;
    }

    | with_clause {
        auto tmp1 = $1;
        res = new IR(kOptWithClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


update_list:

    update_list ',' update_elem {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kUpdateList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | update_elem {
        auto tmp1 = $1;
        res = new IR(kUpdateList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


update_elem:

    simple_ident_nospvar equal expr_or_default {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUpdateElem_1, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kUpdateElem, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


opt_low_priority:

    /* empty */ {
        res = new IR(kOptLowPriority, OP3("", "", ""));
        $$ = res;
    }

    | LOW_PRIORITY {
        res = new IR(kOptLowPriority, OP3("LOW_PRIORITY", "", ""));
        $$ = res;
    }

;

/* Delete rows from a table */


delete_stmt:

    opt_with_clause DELETE_SYM opt_delete_options FROM table_ident opt_table_alias opt_use_partition opt_where_clause opt_order_clause opt_simple_limit {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kDeleteStmt_1, OP3("", "DELETE", "FROM"), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kDeleteStmt_2, OP3("", "", ""), res, tmp3);

        auto tmp4 = $6;
        res = new IR(kDeleteStmt_3, OP3("", "", ""), res, tmp4);

        auto tmp5 = $7;
        res = new IR(kDeleteStmt_4, OP3("", "", ""), res, tmp5);

        auto tmp6 = $8;
        res = new IR(kDeleteStmt_5, OP3("", "", ""), res, tmp6);

        auto tmp7 = $9;
        res = new IR(kDeleteStmt_6, OP3("", "", ""), res, tmp7);

        auto tmp8 = $10;
        res = new IR(kDeleteStmt, OP3("", "", ""), res, tmp8);
        $$ = res;
    }

    | opt_with_clause DELETE_SYM opt_delete_options table_alias_ref_list FROM table_reference_list opt_where_clause {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kDeleteStmt_7, OP3("", "DELETE", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kDeleteStmt_8, OP3("", "", "FROM"), res, tmp3);

        auto tmp4 = $6;
        res = new IR(kDeleteStmt_9, OP3("", "", ""), res, tmp4);

        auto tmp5 = $7;
        res = new IR(kDeleteStmt, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

    | opt_with_clause DELETE_SYM opt_delete_options FROM table_alias_ref_list USING table_reference_list opt_where_clause {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kDeleteStmt_10, OP3("", "DELETE", "FROM"), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kDeleteStmt_11, OP3("", "", "USING"), res, tmp3);

        auto tmp4 = $7;
        res = new IR(kDeleteStmt_12, OP3("", "", ""), res, tmp4);

        auto tmp5 = $8;
        res = new IR(kDeleteStmt, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

;


opt_wild:

    /* empty */ {
        res = new IR(kOptWild, OP3("", "", ""));
        $$ = res;
    }

    | '.' '*' {
        res = new IR(kOptWild, OP3(". *", "", ""));
        $$ = res;
    }

;


opt_delete_options:

    /* empty */ {
        res = new IR(kOptDeleteOptions, OP3("", "", ""));
        $$ = res;
    }

    | opt_delete_option opt_delete_options {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptDeleteOptions, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_delete_option:

    QUICK {
        res = new IR(kOptDeleteOption, OP3("QUICK", "", ""));
        $$ = res;
    }

    | LOW_PRIORITY {
        res = new IR(kOptDeleteOption, OP3("LOW_PRIORITY", "", ""));
        $$ = res;
    }

    | IGNORE_SYM {
        res = new IR(kOptDeleteOption, OP3("IGNORE", "", ""));
        $$ = res;
    }

;


truncate_stmt:

    TRUNCATE_SYM opt_table table_ident {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kTruncateStmt, OP3("TRUNCATE", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_table:

    /* empty */ {
        res = new IR(kOptTable, OP3("", "", ""));
        $$ = res;
    }

    | TABLE_SYM {
        res = new IR(kOptTable, OP3("TABLE", "", ""));
        $$ = res;
    }

;


opt_profile_defs:

    /* empty */ {
        res = new IR(kOptProfileDefs, OP3("", "", ""));
        $$ = res;
    }

    | profile_defs {
        auto tmp1 = $1;
        res = new IR(kOptProfileDefs, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


profile_defs:

    profile_def {
        auto tmp1 = $1;
        res = new IR(kProfileDefs, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | profile_defs ',' profile_def {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kProfileDefs, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


profile_def:

    CPU_SYM {
        res = new IR(kProfileDef, OP3("CPU", "", ""));
        $$ = res;
    }

    | MEMORY_SYM {
        res = new IR(kProfileDef, OP3("MEMORY", "", ""));
        $$ = res;
    }

    | BLOCK_SYM IO_SYM {
        res = new IR(kProfileDef, OP3("BLOCK IO", "", ""));
        $$ = res;
    }

    | CONTEXT_SYM SWITCHES_SYM {
        res = new IR(kProfileDef, OP3("CONTEXT SWITCHES", "", ""));
        $$ = res;
    }

    | PAGE_SYM FAULTS_SYM {
        res = new IR(kProfileDef, OP3("PAGE FAULTS", "", ""));
        $$ = res;
    }

    | IPC_SYM {
        res = new IR(kProfileDef, OP3("IPC", "", ""));
        $$ = res;
    }

    | SWAPS_SYM {
        res = new IR(kProfileDef, OP3("SWAPS", "", ""));
        $$ = res;
    }

    | SOURCE_SYM {
        res = new IR(kProfileDef, OP3("SOURCE", "", ""));
        $$ = res;
    }

    | ALL {
        res = new IR(kProfileDef, OP3("ALL", "", ""));
        $$ = res;
    }

;


opt_for_query:

    /* empty */ {
        res = new IR(kOptForQuery, OP3("", "", ""));
        $$ = res;
    }

    | FOR_SYM QUERY_SYM NUM {
        res = new IR(kOptForQuery, OP3("FOR QUERY NUM", "", ""));
        $$ = res;
    }

;

/* SHOW statements */


show_databases_stmt:

    SHOW DATABASES opt_wild_or_where {
        auto tmp1 = $3;
        res = new IR(kShowDatabasesStmt, OP3("SHOW DATABASES", "", ""), tmp1);
        $$ = res;
    }

;


show_tables_stmt:

    SHOW opt_show_cmd_type TABLES opt_db opt_wild_or_where {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kShowTablesStmt_1, OP3("SHOW", "TABLES", ""), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kShowTablesStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


show_triggers_stmt:

    SHOW opt_full TRIGGERS_SYM opt_db opt_wild_or_where {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kShowTriggersStmt_1, OP3("SHOW", "TRIGGERS", ""), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kShowTriggersStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


show_events_stmt:

    SHOW EVENTS_SYM opt_db opt_wild_or_where {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kShowEventsStmt, OP3("SHOW EVENTS", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


show_table_status_stmt:

    SHOW TABLE_SYM STATUS_SYM opt_db opt_wild_or_where {
        auto tmp1 = $4;
        auto tmp2 = $5;
        res = new IR(kShowTableStatusStmt, OP3("SHOW TABLE STATUS", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


show_open_tables_stmt:

    SHOW OPEN_SYM TABLES opt_db opt_wild_or_where {
        auto tmp1 = $4;
        auto tmp2 = $5;
        res = new IR(kShowOpenTablesStmt, OP3("SHOW OPEN TABLES", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


show_plugins_stmt:

    SHOW PLUGINS_SYM {
        res = new IR(kShowPluginsStmt, OP3("SHOW PLUGINS", "", ""));
        $$ = res;
    }

;


show_engine_logs_stmt:

    SHOW ENGINE_SYM engine_or_all LOGS_SYM {
        auto tmp1 = $3;
        res = new IR(kShowEngineLogsStmt, OP3("SHOW ENGINE", "LOGS", ""), tmp1);
        $$ = res;
    }

;


show_engine_mutex_stmt:

    SHOW ENGINE_SYM engine_or_all MUTEX_SYM {
        auto tmp1 = $3;
        res = new IR(kShowEngineMutexStmt, OP3("SHOW ENGINE", "MUTEX", ""), tmp1);
        $$ = res;
    }

;


show_engine_status_stmt:

    SHOW ENGINE_SYM engine_or_all STATUS_SYM {
        auto tmp1 = $3;
        res = new IR(kShowEngineStatusStmt, OP3("SHOW ENGINE", "STATUS", ""), tmp1);
        $$ = res;
    }

;


show_columns_stmt:

    SHOW opt_show_cmd_type COLUMNS from_or_in table_ident opt_db opt_wild_or_where {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kShowColumnsStmt_1, OP3("SHOW", "COLUMNS", ""), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kShowColumnsStmt_2, OP3("", "", ""), res, tmp3);

        auto tmp4 = $6;
        res = new IR(kShowColumnsStmt_3, OP3("", "", ""), res, tmp4);

        auto tmp5 = $7;
        res = new IR(kShowColumnsStmt, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

;


show_binary_logs_stmt:

    SHOW master_or_binary LOGS_SYM {
        auto tmp1 = $2;
        res = new IR(kShowBinaryLogsStmt, OP3("SHOW", "LOGS", ""), tmp1);
        $$ = res;
    }

;


show_replicas_stmt:

    SHOW SLAVE HOSTS_SYM {
        res = new IR(kShowReplicasStmt, OP3("SHOW SLAVE HOSTS", "", ""));
        $$ = res;
    }

    | SHOW REPLICAS_SYM {
        res = new IR(kShowReplicasStmt, OP3("SHOW REPLICAS", "", ""));
        $$ = res;
    }

;


show_binlog_events_stmt:

    SHOW BINLOG_SYM EVENTS_SYM opt_binlog_in binlog_from opt_limit_clause {
        auto tmp1 = $4;
        auto tmp2 = $5;
        res = new IR(kShowBinlogEventsStmt_1, OP3("SHOW BINLOG EVENTS", "", ""), tmp1, tmp2);

        auto tmp3 = $6;
        res = new IR(kShowBinlogEventsStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


show_relaylog_events_stmt:

    SHOW RELAYLOG_SYM EVENTS_SYM opt_binlog_in binlog_from opt_limit_clause opt_channel {
        auto tmp1 = $4;
        auto tmp2 = $5;
        res = new IR(kShowRelaylogEventsStmt_1, OP3("SHOW RELAYLOG EVENTS", "", ""), tmp1, tmp2);

        auto tmp3 = $6;
        res = new IR(kShowRelaylogEventsStmt_2, OP3("", "", ""), res, tmp3);

        auto tmp4 = $7;
        res = new IR(kShowRelaylogEventsStmt, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


show_keys_stmt:

    SHOW opt_extended keys_or_index from_or_in table_ident opt_db opt_where_clause {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kShowKeysStmt_1, OP3("SHOW", "", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kShowKeysStmt_2, OP3("", "", ""), res, tmp3);

        auto tmp4 = $5;
        res = new IR(kShowKeysStmt_3, OP3("", "", ""), res, tmp4);

        auto tmp5 = $6;
        res = new IR(kShowKeysStmt_4, OP3("", "", ""), res, tmp5);

        auto tmp6 = $7;
        res = new IR(kShowKeysStmt, OP3("", "", ""), res, tmp6);
        $$ = res;
    }

;


show_engines_stmt:

    SHOW opt_storage ENGINES_SYM {
        auto tmp1 = $2;
        res = new IR(kShowEnginesStmt, OP3("SHOW", "ENGINES", ""), tmp1);
        $$ = res;
    }

;


show_count_warnings_stmt:

    SHOW COUNT_SYM '(' '*' ')' WARNINGS {
        res = new IR(kShowCountWarningsStmt, OP3("SHOW COUNT ( * ) WARNINGS", "", ""));
        $$ = res;
    }

;


show_count_errors_stmt:

    SHOW COUNT_SYM '(' '*' ')' ERRORS {
        res = new IR(kShowCountErrorsStmt, OP3("SHOW COUNT ( * ) ERRORS", "", ""));
        $$ = res;
    }

;


show_warnings_stmt:

    SHOW WARNINGS opt_limit_clause {
        auto tmp1 = $3;
        res = new IR(kShowWarningsStmt, OP3("SHOW WARNINGS", "", ""), tmp1);
        $$ = res;
    }

;


show_errors_stmt:

    SHOW ERRORS opt_limit_clause {
        auto tmp1 = $3;
        res = new IR(kShowErrorsStmt, OP3("SHOW ERRORS", "", ""), tmp1);
        $$ = res;
    }

;


show_profiles_stmt:

    SHOW PROFILES_SYM {
        res = new IR(kShowProfilesStmt, OP3("SHOW PROFILES", "", ""));
        $$ = res;
    }

;


show_profile_stmt:

    SHOW PROFILE_SYM opt_profile_defs opt_for_query opt_limit_clause {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kShowProfileStmt_1, OP3("SHOW PROFILE", "", ""), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kShowProfileStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


show_status_stmt:

    SHOW opt_var_type STATUS_SYM opt_wild_or_where {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kShowStatusStmt, OP3("SHOW", "STATUS", ""), tmp1, tmp2);
        $$ = res;
    }

;


show_processlist_stmt:

    SHOW opt_full PROCESSLIST_SYM {
        auto tmp1 = $2;
        res = new IR(kShowProcesslistStmt, OP3("SHOW", "PROCESSLIST", ""), tmp1);
        $$ = res;
    }

;


show_variables_stmt:

    SHOW opt_var_type VARIABLES opt_wild_or_where {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kShowVariablesStmt, OP3("SHOW", "VARIABLES", ""), tmp1, tmp2);
        $$ = res;
    }

;


show_character_set_stmt:

    SHOW character_set opt_wild_or_where {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kShowCharacterSetStmt, OP3("SHOW", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


show_collation_stmt:

    SHOW COLLATION_SYM opt_wild_or_where {
        auto tmp1 = $3;
        res = new IR(kShowCollationStmt, OP3("SHOW COLLATION", "", ""), tmp1);
        $$ = res;
    }

;


show_privileges_stmt:

    SHOW PRIVILEGES {
        res = new IR(kShowPrivilegesStmt, OP3("SHOW PRIVILEGES", "", ""));
        $$ = res;
    }

;


show_grants_stmt:

    SHOW GRANTS {
        res = new IR(kShowGrantsStmt, OP3("SHOW GRANTS", "", ""));
        $$ = res;
    }

    | SHOW GRANTS FOR_SYM user {
        auto tmp1 = $4;
        res = new IR(kShowGrantsStmt, OP3("SHOW GRANTS FOR", "", ""), tmp1);
        $$ = res;
    }

    | SHOW GRANTS FOR_SYM user USING user_list {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kShowGrantsStmt, OP3("SHOW GRANTS FOR", "USING", ""), tmp1, tmp2);
        $$ = res;
    }

;


show_create_database_stmt:

    SHOW CREATE DATABASE opt_if_not_exists ident {
        auto tmp1 = $4;
        auto tmp2 = $5;
        res = new IR(kShowCreateDatabaseStmt, OP3("SHOW CREATE DATABASE", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


show_create_table_stmt:

    SHOW CREATE TABLE_SYM table_ident {
        auto tmp1 = $4;
        res = new IR(kShowCreateTableStmt, OP3("SHOW CREATE TABLE", "", ""), tmp1);
        $$ = res;
    }

;


show_create_view_stmt:

    SHOW CREATE VIEW_SYM table_ident {
        auto tmp1 = $4;
        res = new IR(kShowCreateViewStmt, OP3("SHOW CREATE VIEW", "", ""), tmp1);
        $$ = res;
    }

;


show_master_status_stmt:

    SHOW MASTER_SYM STATUS_SYM {
        res = new IR(kShowMasterStatusStmt, OP3("SHOW MASTER STATUS", "", ""));
        $$ = res;
    }

;


show_replica_status_stmt:

    SHOW replica STATUS_SYM opt_channel {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kShowReplicaStatusStmt, OP3("SHOW", "STATUS", ""), tmp1, tmp2);
        $$ = res;
    }

;


show_create_procedure_stmt:

    SHOW CREATE PROCEDURE_SYM sp_name {
        auto tmp1 = $4;
        res = new IR(kShowCreateProcedureStmt, OP3("SHOW CREATE PROCEDURE", "", ""), tmp1);
        $$ = res;
    }

;


show_create_function_stmt:

    SHOW CREATE FUNCTION_SYM sp_name {
        auto tmp1 = $4;
        res = new IR(kShowCreateFunctionStmt, OP3("SHOW CREATE FUNCTION", "", ""), tmp1);
        $$ = res;
    }

;


show_create_trigger_stmt:

    SHOW CREATE TRIGGER_SYM sp_name {
        auto tmp1 = $4;
        res = new IR(kShowCreateTriggerStmt, OP3("SHOW CREATE TRIGGER", "", ""), tmp1);
        $$ = res;
    }

;


show_procedure_status_stmt:

    SHOW PROCEDURE_SYM STATUS_SYM opt_wild_or_where {
        auto tmp1 = $4;
        res = new IR(kShowProcedureStatusStmt, OP3("SHOW PROCEDURE STATUS", "", ""), tmp1);
        $$ = res;
    }

;


show_function_status_stmt:

    SHOW FUNCTION_SYM STATUS_SYM opt_wild_or_where {
        auto tmp1 = $4;
        res = new IR(kShowFunctionStatusStmt, OP3("SHOW FUNCTION STATUS", "", ""), tmp1);
        $$ = res;
    }

;


show_procedure_code_stmt:

    SHOW PROCEDURE_SYM CODE_SYM sp_name {
        auto tmp1 = $4;
        res = new IR(kShowProcedureCodeStmt, OP3("SHOW PROCEDURE CODE", "", ""), tmp1);
        $$ = res;
    }

;


show_function_code_stmt:

    SHOW FUNCTION_SYM CODE_SYM sp_name {
        auto tmp1 = $4;
        res = new IR(kShowFunctionCodeStmt, OP3("SHOW FUNCTION CODE", "", ""), tmp1);
        $$ = res;
    }

;


show_create_event_stmt:

    SHOW CREATE EVENT_SYM sp_name {
        auto tmp1 = $4;
        res = new IR(kShowCreateEventStmt, OP3("SHOW CREATE EVENT", "", ""), tmp1);
        $$ = res;
    }

;


show_create_user_stmt:

    SHOW CREATE USER user {
        auto tmp1 = $4;
        res = new IR(kShowCreateUserStmt, OP3("SHOW CREATE USER", "", ""), tmp1);
        $$ = res;
    }

;


engine_or_all:

    ident_or_text {
        auto tmp1 = $1;
        res = new IR(kEngineOrAll, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ALL {
        res = new IR(kEngineOrAll, OP3("ALL", "", ""));
        $$ = res;
    }

;


master_or_binary:

    MASTER_SYM {
        res = new IR(kMasterOrBinary, OP3("MASTER", "", ""));
        $$ = res;
    }

    | BINARY_SYM {
        res = new IR(kMasterOrBinary, OP3("BINARY", "", ""));
        $$ = res;
    }

;


opt_storage:

    /* empty */ {
        res = new IR(kOptStorage, OP3("", "", ""));
        $$ = res;
    }

    | STORAGE_SYM {
        res = new IR(kOptStorage, OP3("STORAGE", "", ""));
        $$ = res;
    }

;


opt_db:

    /* empty */ {
        res = new IR(kOptDb, OP3("", "", ""));
        $$ = res;
    }

    | from_or_in ident {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptDb, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_full:

    /* empty */ {
        res = new IR(kOptFull, OP3("", "", ""));
        $$ = res;
    }

    | FULL {
        res = new IR(kOptFull, OP3("FULL", "", ""));
        $$ = res;
    }

;


opt_extended:

    /* empty */ {
        res = new IR(kOptExtended, OP3("", "", ""));
        $$ = res;
    }

    | EXTENDED_SYM {
        res = new IR(kOptExtended, OP3("EXTENDED", "", ""));
        $$ = res;
    }

;


opt_show_cmd_type:

    /* empty */ {
        res = new IR(kOptShowCmdType, OP3("", "", ""));
        $$ = res;
    }

    | FULL {
        res = new IR(kOptShowCmdType, OP3("FULL", "", ""));
        $$ = res;
    }

    | EXTENDED_SYM {
        res = new IR(kOptShowCmdType, OP3("EXTENDED", "", ""));
        $$ = res;
    }

    | EXTENDED_SYM FULL {
        res = new IR(kOptShowCmdType, OP3("EXTENDED FULL", "", ""));
        $$ = res;
    }

;


from_or_in:

    FROM {
        res = new IR(kFromOrIn, OP3("FROM", "", ""));
        $$ = res;
    }

    | IN_SYM {
        res = new IR(kFromOrIn, OP3("IN", "", ""));
        $$ = res;
    }

;


opt_binlog_in:

    /* empty */ {
        res = new IR(kOptBinlogIn, OP3("", "", ""));
        $$ = res;
    }

    | IN_SYM TEXT_STRING_sys {
        auto tmp1 = $2;
        res = new IR(kOptBinlogIn, OP3("IN", "", ""), tmp1);
        $$ = res;
    }

;


binlog_from:

    /* empty */ {
        res = new IR(kBinlogFrom, OP3("", "", ""));
        $$ = res;
    }

    | FROM ulonglong_num {
        auto tmp1 = $2;
        res = new IR(kBinlogFrom, OP3("FROM", "", ""), tmp1);
        $$ = res;
    }

;


opt_wild_or_where:

    /* empty */ {
        res = new IR(kOptWildOrWhere, OP3("", "", ""));
        $$ = res;
    }

    | LIKE TEXT_STRING_literal {
        auto tmp1 = $2;
        res = new IR(kOptWildOrWhere, OP3("LIKE", "", ""), tmp1);
        $$ = res;
    }

    | where_clause {
        auto tmp1 = $1;
        res = new IR(kOptWildOrWhere, OP3("", "", ""), tmp1);
        $$ = res;
    }

;

/* A Oracle compatible synonym for show */

describe_stmt:

    describe_command table_ident opt_describe_column {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kDescribeStmt_1, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kDescribeStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


explain_stmt:

    describe_command opt_explain_analyze_type explainable_stmt {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kExplainStmt_1, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kExplainStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


explainable_stmt:

    select_stmt {
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | insert_stmt {
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | replace_stmt {
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | update_stmt {
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | delete_stmt {
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | FOR_SYM CONNECTION_SYM real_ulong_num {
        auto tmp1 = $3;
        res = new IR(kExplainableStmt, OP3("FOR CONNECTION", "", ""), tmp1);
        $$ = res;
    }

;


describe_command:

    DESC {
        res = new IR(kDescribeCommand, OP3("DESC", "", ""));
        $$ = res;
    }

    | DESCRIBE {
        res = new IR(kDescribeCommand, OP3("DESCRIBE", "", ""));
        $$ = res;
    }

;


opt_explain_format_type:

    /* empty */ {
        res = new IR(kOptExplainFormatType, OP3("", "", ""));
        $$ = res;
    }

    | FORMAT_SYM EQ ident_or_text {
        auto tmp1 = $3;
        res = new IR(kOptExplainFormatType, OP3("FORMAT =", "", ""), tmp1);
        $$ = res;
    }

;


opt_explain_analyze_type:

    ANALYZE_SYM opt_explain_format_type {
        auto tmp1 = $2;
        res = new IR(kOptExplainAnalyzeType, OP3("ANALYZE", "", ""), tmp1);
        $$ = res;
    }

    | opt_explain_format_type {
        auto tmp1 = $1;
        res = new IR(kOptExplainAnalyzeType, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_describe_column:

    /* empty */ {
        res = new IR(kOptDescribeColumn, OP3("", "", ""));
        $$ = res;
    }

    | text_string {
        auto tmp1 = $1;
        res = new IR(kOptDescribeColumn, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ident {
        auto tmp1 = $1;
        res = new IR(kOptDescribeColumn, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


/* flush things */


flush:

    FLUSH_SYM opt_no_write_to_binlog {} flush_options {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kFlush, OP3("FLUSH", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


flush_options:

    table_or_tables opt_table_list {} opt_flush_lock {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFlushOptions_1, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kFlushOptions, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | flush_options_list {
        auto tmp1 = $1;
        res = new IR(kFlushOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_flush_lock:

    /* empty */ {
        res = new IR(kOptFlushLock, OP3("", "", ""));
        $$ = res;
    }

    | WITH READ_SYM LOCK_SYM {
        res = new IR(kOptFlushLock, OP3("WITH READ LOCK", "", ""));
        $$ = res;
    }

    | FOR_SYM {} EXPORT_SYM {
        res = new IR(kOptFlushLock, OP3("FOR EXPORT", "", ""));
        $$ = res;
    }

;


flush_options_list:

    flush_options_list ',' flush_option {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kFlushOptionsList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | flush_option {
        auto tmp1 = $1;
        res = new IR(kFlushOptionsList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


flush_option:

    ERROR_SYM LOGS_SYM {
        res = new IR(kFlushOption, OP3("ERROR LOGS", "", ""));
        $$ = res;
    }

    | ENGINE_SYM LOGS_SYM {
        res = new IR(kFlushOption, OP3("ENGINE LOGS", "", ""));
        $$ = res;
    }

    | GENERAL LOGS_SYM {
        res = new IR(kFlushOption, OP3("GENERAL LOGS", "", ""));
        $$ = res;
    }

    | SLOW LOGS_SYM {
        res = new IR(kFlushOption, OP3("SLOW LOGS", "", ""));
        $$ = res;
    }

    | BINARY_SYM LOGS_SYM {
        res = new IR(kFlushOption, OP3("BINARY LOGS", "", ""));
        $$ = res;
    }

    | RELAY LOGS_SYM opt_channel {
        auto tmp1 = $3;
        res = new IR(kFlushOption, OP3("RELAY LOGS", "", ""), tmp1);
        $$ = res;
    }

    | HOSTS_SYM {
        res = new IR(kFlushOption, OP3("HOSTS", "", ""));
        $$ = res;
    }

    | PRIVILEGES {
        res = new IR(kFlushOption, OP3("PRIVILEGES", "", ""));
        $$ = res;
    }

    | LOGS_SYM {
        res = new IR(kFlushOption, OP3("LOGS", "", ""));
        $$ = res;
    }

    | STATUS_SYM {
        res = new IR(kFlushOption, OP3("STATUS", "", ""));
        $$ = res;
    }

    | RESOURCES {
        res = new IR(kFlushOption, OP3("USER_RESOURCES", "", ""));
        $$ = res;
    }

    | OPTIMIZER_COSTS_SYM {
        res = new IR(kFlushOption, OP3("OPTIMIZER_COSTS", "", ""));
        $$ = res;
    }

;


opt_table_list:

    /* empty */ {
        res = new IR(kOptTableList, OP3("", "", ""));
        $$ = res;
    }

    | table_list {
        auto tmp1 = $1;
        res = new IR(kOptTableList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


reset:

    RESET_SYM {} reset_options {
        auto tmp1 = $3;
        res = new IR(kReset, OP3("RESET", "", ""), tmp1);
        $$ = res;
    }

    | RESET_SYM PERSIST_SYM opt_if_exists_ident {
        auto tmp1 = $3;
        res = new IR(kReset, OP3("RESET PERSIST", "", ""), tmp1);
        $$ = res;
    }

;


reset_options:

    reset_options ',' reset_option {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kResetOptions, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | reset_option {
        auto tmp1 = $1;
        res = new IR(kResetOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_if_exists_ident:

    /* empty */ {
        res = new IR(kOptIfExistsIdent, OP3("", "", ""));
        $$ = res;
    }

    | if_exists ident {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptIfExistsIdent, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


reset_option:

    SLAVE {} opt_replica_reset_options opt_channel {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kResetOption, OP3("SLAVE", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | REPLICA_SYM {} opt_replica_reset_options opt_channel {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kResetOption, OP3("REPLICA", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | MASTER_SYM {} source_reset_options {
        auto tmp1 = $3;
        res = new IR(kResetOption, OP3("MASTER", "", ""), tmp1);
        $$ = res;
    }

;


opt_replica_reset_options:

    /* empty */ {
        res = new IR(kOptReplicaResetOptions, OP3("", "", ""));
        $$ = res;
    }

    | ALL {
        res = new IR(kOptReplicaResetOptions, OP3("ALL", "", ""));
        $$ = res;
    }

;


source_reset_options:

    /* empty */ {
        res = new IR(kSourceResetOptions, OP3("", "", ""));
        $$ = res;
    }

    | TO_SYM real_ulonglong_num {
        auto tmp1 = $2;
        res = new IR(kSourceResetOptions, OP3("TO", "", ""), tmp1);
        $$ = res;
    }

;


purge:

    PURGE {} purge_options {
        auto tmp1 = $3;
        res = new IR(kPurge, OP3("PURGE", "", ""), tmp1);
        $$ = res;
    }

;


purge_options:

    master_or_binary LOGS_SYM purge_option {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kPurgeOptions, OP3("", "LOGS", ""), tmp1, tmp2);
        $$ = res;
    }

;


purge_option:

    TO_SYM TEXT_STRING_sys {
        auto tmp1 = $2;
        res = new IR(kPurgeOption, OP3("TO", "", ""), tmp1);
        $$ = res;
    }

    | BEFORE_SYM expr {
        auto tmp1 = $2;
        res = new IR(kPurgeOption, OP3("BEFORE", "", ""), tmp1);
        $$ = res;
    }

;

/* kill threads */


kill:

    KILL_SYM kill_option expr {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kKill, OP3("KILL", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


kill_option:

    /* empty */ {
        res = new IR(kKillOption, OP3("", "", ""));
        $$ = res;
    }

    | CONNECTION_SYM {
        res = new IR(kKillOption, OP3("CONNECTION", "", ""));
        $$ = res;
    }

    | QUERY_SYM {
        res = new IR(kKillOption, OP3("QUERY", "", ""));
        $$ = res;
    }

;

/* change database */


use:

    USE_SYM ident {
        auto tmp1 = $2;
        res = new IR(kUseSym, OP3("USE", "", ""), tmp1);
        $$ = res;
    }

;

/* import, export of files */


load_stmt:

    LOAD data_or_xml load_data_lock opt_local INFILE TEXT_STRING_filesystem opt_duplicate INTO TABLE_SYM table_ident opt_use_partition opt_load_data_charset opt_xml_rows_identified_by opt_field_term opt_line_term opt_ignore_lines opt_field_or_var_spec opt_load_data_set_spec {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kLoadStmt_1, OP3("LOAD", "", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kLoadStmt_2, OP3("", "", "INFILE"), res, tmp3);

        auto tmp4 = $6;
        res = new IR(kLoadStmt_3, OP3("", "", ""), res, tmp4);

        auto tmp5 = $7;
        res = new IR(kLoadStmt_4, OP3("", "", "INTO TABLE"), res, tmp5);

        auto tmp6 = $10;
        res = new IR(kLoadStmt_5, OP3("", "", ""), res, tmp6);

        auto tmp7 = $11;
        res = new IR(kLoadStmt_6, OP3("", "", ""), res, tmp7);

        auto tmp8 = $12;
        res = new IR(kLoadStmt_7, OP3("", "", ""), res, tmp8);

        auto tmp9 = $13;
        res = new IR(kLoadStmt_8, OP3("", "", ""), res, tmp9);

        auto tmp10 = $14;
        res = new IR(kLoadStmt_9, OP3("", "", ""), res, tmp10);

        auto tmp11 = $15;
        res = new IR(kLoadStmt_10, OP3("", "", ""), res, tmp11);

        auto tmp12 = $16;
        res = new IR(kLoadStmt_11, OP3("", "", ""), res, tmp12);

        auto tmp13 = $17;
        res = new IR(kLoadStmt_12, OP3("", "", ""), res, tmp13);

        auto tmp14 = $18;
        res = new IR(kLoadStmt, OP3("", "", ""), res, tmp14);
        $$ = res;
    }

;


data_or_xml:

    DATA_SYM {
        res = new IR(kDataOrXml, OP3("DATA", "", ""));
        $$ = res;
    }

    | XML_SYM {
        res = new IR(kDataOrXml, OP3("XML", "", ""));
        $$ = res;
    }

;


opt_local:

    /* empty */ {
        res = new IR(kOptLocal, OP3("", "", ""));
        $$ = res;
    }

    | LOCAL_SYM {
        res = new IR(kOptLocal, OP3("LOCAL", "", ""));
        $$ = res;
    }

;


load_data_lock:

    /* empty */ {
        res = new IR(kLoadDataLock, OP3("", "", ""));
        $$ = res;
    }

    | CONCURRENT {
        res = new IR(kLoadDataLock, OP3("CONCURRENT", "", ""));
        $$ = res;
    }

    | LOW_PRIORITY {
        res = new IR(kLoadDataLock, OP3("LOW_PRIORITY", "", ""));
        $$ = res;
    }

;


opt_duplicate:

    /* empty */ {
        res = new IR(kOptDuplicate, OP3("", "", ""));
        $$ = res;
    }

    | duplicate {
        auto tmp1 = $1;
        res = new IR(kOptDuplicate, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


duplicate:

    REPLACE_SYM {
        res = new IR(kDuplicate, OP3("REPLACE", "", ""));
        $$ = res;
    }

    | IGNORE_SYM {
        res = new IR(kDuplicate, OP3("IGNORE", "", ""));
        $$ = res;
    }

;


opt_field_term:

    /* empty */ {
        res = new IR(kOptFieldTerm, OP3("", "", ""));
        $$ = res;
    }

    | COLUMNS field_term_list {
        auto tmp1 = $2;
        res = new IR(kOptFieldTerm, OP3("COLUMNS", "", ""), tmp1);
        $$ = res;
    }

;


field_term_list:

    field_term_list field_term {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFieldTermList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | field_term {
        auto tmp1 = $1;
        res = new IR(kFieldTermList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


field_term:

    TERMINATED BY text_string {
        auto tmp1 = $3;
        res = new IR(kFieldTerm, OP3("TERMINATED BY", "", ""), tmp1);
        $$ = res;
    }

    | OPTIONALLY ENCLOSED BY text_string {
        auto tmp1 = $4;
        res = new IR(kFieldTerm, OP3("OPTIONALLY ENCLOSED BY", "", ""), tmp1);
        $$ = res;
    }

    | ENCLOSED BY text_string {
        auto tmp1 = $3;
        res = new IR(kFieldTerm, OP3("ENCLOSED BY", "", ""), tmp1);
        $$ = res;
    }

    | ESCAPED BY text_string {
        auto tmp1 = $3;
        res = new IR(kFieldTerm, OP3("ESCAPED BY", "", ""), tmp1);
        $$ = res;
    }

;


opt_line_term:

    /* empty */ {
        res = new IR(kOptLineTerm, OP3("", "", ""));
        $$ = res;
    }

    | LINES line_term_list {
        auto tmp1 = $2;
        res = new IR(kOptLineTerm, OP3("LINES", "", ""), tmp1);
        $$ = res;
    }

;


line_term_list:

    line_term_list line_term {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kLineTermList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | line_term {
        auto tmp1 = $1;
        res = new IR(kLineTermList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


line_term:

    TERMINATED BY text_string {
        auto tmp1 = $3;
        res = new IR(kLineTerm, OP3("TERMINATED BY", "", ""), tmp1);
        $$ = res;
    }

    | STARTING BY text_string {
        auto tmp1 = $3;
        res = new IR(kLineTerm, OP3("STARTING BY", "", ""), tmp1);
        $$ = res;
    }

;


opt_xml_rows_identified_by:

    /* empty */ {
        res = new IR(kOptXmlRowsIdentifiedBy, OP3("", "", ""));
        $$ = res;
    }

    | ROWS_SYM IDENTIFIED_SYM BY text_string {
        auto tmp1 = $4;
        res = new IR(kOptXmlRowsIdentifiedBy, OP3("ROWS IDENTIFIED BY", "", ""), tmp1);
        $$ = res;
    }

;


opt_ignore_lines:

    /* empty */ {
        res = new IR(kOptIgnoreLines, OP3("", "", ""));
        $$ = res;
    }

    | IGNORE_SYM NUM lines_or_rows {
        auto tmp1 = $3;
        res = new IR(kOptIgnoreLines, OP3("IGNORE NUM", "", ""), tmp1);
        $$ = res;
    }

;


lines_or_rows:

    LINES {
        res = new IR(kLinesOrRows, OP3("LINES", "", ""));
        $$ = res;
    }

    | ROWS_SYM {
        res = new IR(kLinesOrRows, OP3("ROWS", "", ""));
        $$ = res;
    }

;


opt_field_or_var_spec:

    /* empty */ {
        res = new IR(kOptFieldOrVarSpec, OP3("", "", ""));
        $$ = res;
    }

    | '(' fields_or_vars ')' {
        auto tmp1 = $2;
        res = new IR(kOptFieldOrVarSpec, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

    | '(' ')' {
        res = new IR(kOptFieldOrVarSpec, OP3("( )", "", ""));
        $$ = res;
    }

;


fields_or_vars:

    fields_or_vars ',' field_or_var {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kFieldsOrVars, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | field_or_var {
        auto tmp1 = $1;
        res = new IR(kFieldsOrVars, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


field_or_var:

    simple_ident_nospvar {
        auto tmp1 = $1;
        res = new IR(kFieldOrVar, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '@' ident_or_text {
        auto tmp1 = $2;
        res = new IR(kFieldOrVar, OP3("@", "", ""), tmp1);
        $$ = res;
    }

;


opt_load_data_set_spec:

    /* empty */ {
        res = new IR(kOptLoadDataSetSpec, OP3("", "", ""));
        $$ = res;
    }

    | SET_SYM load_data_set_list {
        auto tmp1 = $2;
        res = new IR(kOptLoadDataSetSpec, OP3("SET", "", ""), tmp1);
        $$ = res;
    }

;


load_data_set_list:

    load_data_set_list ',' load_data_set_elem {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kLoadDataSetList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | load_data_set_elem {
        auto tmp1 = $1;
        res = new IR(kLoadDataSetList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


load_data_set_elem:

    simple_ident_nospvar equal expr_or_default {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kLoadDataSetElem_1, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kLoadDataSetElem, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;

/* Common definitions */


text_literal:

    TEXT_STRING {
        res = new IR(kTextLiteral, OP3("TEXT_STRING", "", ""));
        $$ = res;
    }

    | NCHAR_STRING {
        res = new IR(kTextLiteral, OP3("NCHAR_STRING", "", ""));
        $$ = res;
    }

    | UNDERSCORE_CHARSET TEXT_STRING {
        res = new IR(kTextLiteral, OP3("UNDERSCORE_CHARSET TEXT_STRING", "", ""));
        $$ = res;
    }

    | text_literal TEXT_STRING_literal {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kTextLiteral, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


text_string:

    TEXT_STRING_literal {
        auto tmp1 = $1;
        res = new IR(kTextString, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | HEX_NUM {
        res = new IR(kTextString, OP3("HEX_NUM", "", ""));
        $$ = res;
    }

    | BIN_NUM {
        res = new IR(kTextString, OP3("BIN_NUM", "", ""));
        $$ = res;
    }

;


param_marker:

    PARAM_MARKER {
        res = new IR(kParamMarker, OP3("PARAM_MARKER", "", ""));
        $$ = res;
    }

;


signed_literal:

    literal {
        auto tmp1 = $1;
        res = new IR(kSignedLiteral, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '+' NUM_literal {
        auto tmp1 = $2;
        res = new IR(kSignedLiteral, OP3("+", "", ""), tmp1);
        $$ = res;
    }

    | '-' NUM_literal {
        auto tmp1 = $2;
        res = new IR(kSignedLiteral, OP3("-", "", ""), tmp1);
        $$ = res;
    }

;


signed_literal_or_null:

    signed_literal {
        auto tmp1 = $1;
        res = new IR(kSignedLiteralOrNull, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | null_as_literal {
        auto tmp1 = $1;
        res = new IR(kSignedLiteralOrNull, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


null_as_literal:

    NULL_SYM {
        res = new IR(kNullAsLiteral, OP3("NULL", "", ""));
        $$ = res;
    }

;


literal:

    text_literal {
        auto tmp1 = $1;
        res = new IR(kLiteral, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | NUM_literal {
        auto tmp1 = $1;
        res = new IR(kLiteral, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | temporal_literal {
        auto tmp1 = $1;
        res = new IR(kLiteral, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | FALSE_SYM {
        res = new IR(kLiteral, OP3("FALSE", "", ""));
        $$ = res;
    }

    | TRUE_SYM {
        res = new IR(kLiteral, OP3("TRUE", "", ""));
        $$ = res;
    }

    | HEX_NUM {
        res = new IR(kLiteral, OP3("HEX_NUM", "", ""));
        $$ = res;
    }

    | BIN_NUM {
        res = new IR(kLiteral, OP3("BIN_NUM", "", ""));
        $$ = res;
    }

    | UNDERSCORE_CHARSET HEX_NUM {
        res = new IR(kLiteral, OP3("UNDERSCORE_CHARSET HEX_NUM", "", ""));
        $$ = res;
    }

    | UNDERSCORE_CHARSET BIN_NUM {
        res = new IR(kLiteral, OP3("UNDERSCORE_CHARSET BIN_NUM", "", ""));
        $$ = res;
    }

;


literal_or_null:

    literal {
        auto tmp1 = $1;
        res = new IR(kLiteralOrNull, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | null_as_literal {
        auto tmp1 = $1;
        res = new IR(kLiteralOrNull, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


NUM_literal:

    int64_literal {
        auto tmp1 = $1;
        res = new IR(kNUMLiteral, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DECIMAL_NUM {
        res = new IR(kNUMLiteral, OP3("DECIMAL_NUM", "", ""));
        $$ = res;
    }

    | FLOAT_NUM {
        res = new IR(kNUMLiteral, OP3("FLOAT_NUM", "", ""));
        $$ = res;
    }

;

/*
int64_literal if for unsigned exact integer literals in a range of
[0 .. 2^64-1].
*/

int64_literal:

    NUM {
        res = new IR(kInt64Literal, OP3("NUM", "", ""));
        $$ = res;
    }

    | LONG_NUM {
        res = new IR(kInt64Literal, OP3("LONG_NUM", "", ""));
        $$ = res;
    }

    | ULONGLONG_NUM {
        res = new IR(kInt64Literal, OP3("ULONGLONG_NUM", "", ""));
        $$ = res;
    }

;



temporal_literal:

    DATE_SYM TEXT_STRING {
        res = new IR(kTemporalLiteral, OP3("DATE TEXT_STRING", "", ""));
        $$ = res;
    }

    | TIME_SYM TEXT_STRING {
        res = new IR(kTemporalLiteral, OP3("TIME TEXT_STRING", "", ""));
        $$ = res;
    }

    | TIMESTAMP_SYM TEXT_STRING {
        res = new IR(kTemporalLiteral, OP3("TIMESTAMP TEXT_STRING", "", ""));
        $$ = res;
    }

;


opt_interval:

    /* empty */ {
        res = new IR(kOptInterval, OP3("", "", ""));
        $$ = res;
    }

    | INTERVAL_SYM {
        res = new IR(kOptInterval, OP3("INTERVAL", "", ""));
        $$ = res;
    }

;


/**********************************************************************
** Creating different items.
**********************************************************************/


insert_ident:

    simple_ident_nospvar {
        auto tmp1 = $1;
        res = new IR(kInsertIdent, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | table_wild {
        auto tmp1 = $1;
        res = new IR(kInsertIdent, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


table_wild:

    ident '.' '*' {
        auto tmp1 = $1;
        res = new IR(kTableWild, OP3("", ". *", ""), tmp1);
        $$ = res;
    }

    | ident '.' ident '.' '*' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTableWild, OP3("", ".", ". *"), tmp1, tmp2);
        $$ = res;
    }

;


order_expr:

    expr opt_ordering_direction {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOrderExpr, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


grouping_expr:

    expr {
        auto tmp1 = $1;
        res = new IR(kGroupingExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


simple_ident:

    ident {
        auto tmp1 = $1;
        res = new IR(kSimpleIdent, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | simple_ident_q {
        auto tmp1 = $1;
        res = new IR(kSimpleIdent, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


simple_ident_nospvar:

    ident {
        auto tmp1 = $1;
        res = new IR(kSimpleIdentNospvar, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | simple_ident_q {
        auto tmp1 = $1;
        res = new IR(kSimpleIdentNospvar, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


simple_ident_q:

    ident '.' ident {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSimpleIdentQ, OP3("", ".", ""), tmp1, tmp2);
        $$ = res;
    }

    | ident '.' ident '.' ident {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSimpleIdentQ_1, OP3("", ".", "."), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kSimpleIdentQ, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


table_ident:

    ident {
        auto tmp1 = $1;
        res = new IR(kTableIdent, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ident '.' ident {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTableIdent, OP3("", ".", ""), tmp1, tmp2);
        $$ = res;
    }

;


table_ident_opt_wild:

    ident opt_wild {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kTableIdentOptWild, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ident '.' ident opt_wild {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTableIdentOptWild_1, OP3("", ".", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kTableIdentOptWild, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


IDENT_sys:

    IDENT {
        res = new IR(kIDENTSys, OP3("IDENT", "", ""));
        $$ = res;
    }

    | IDENT_QUOTED {
        res = new IR(kIDENTSys, OP3("IDENT_QUOTED", "", ""));
        $$ = res;
    }

;


TEXT_STRING_sys_nonewline:

    TEXT_STRING_sys {
        auto tmp1 = $1;
        res = new IR(kTEXTSTRINGSysNonewline, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


filter_wild_db_table_string:

    TEXT_STRING_sys_nonewline {
        auto tmp1 = $1;
        res = new IR(kFilterWildDbTableString, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


TEXT_STRING_sys:

    TEXT_STRING {
        res = new IR(kTEXTSTRINGSys, OP3("TEXT_STRING", "", ""));
        $$ = res;
    }

;


TEXT_STRING_literal:

    TEXT_STRING {
        res = new IR(kTEXTSTRINGLiteral, OP3("TEXT_STRING", "", ""));
        $$ = res;
    }

;


TEXT_STRING_filesystem:

    TEXT_STRING {
        res = new IR(kTEXTSTRINGFilesystem, OP3("TEXT_STRING", "", ""));
        $$ = res;
    }

;


TEXT_STRING_password:

    TEXT_STRING {
        res = new IR(kTEXTSTRINGPassword, OP3("TEXT_STRING", "", ""));
        $$ = res;
    }

;


TEXT_STRING_hash:

    TEXT_STRING_sys {
        auto tmp1 = $1;
        res = new IR(kTEXTSTRINGHash, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | HEX_NUM {
        res = new IR(kTEXTSTRINGHash, OP3("HEX_NUM", "", ""));
        $$ = res;
    }

;


TEXT_STRING_validated:

    TEXT_STRING {
        res = new IR(kTEXTSTRINGValidated, OP3("TEXT_STRING", "", ""));
        $$ = res;
    }

;


ident:

    IDENT_sys {
        auto tmp1 = $1;
        res = new IR(kIdent, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ident_keyword {
        auto tmp1 = $1;
        res = new IR(kIdent, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


role_ident:

    IDENT_sys {
        auto tmp1 = $1;
        res = new IR(kRoleIdent, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | role_keyword {
        auto tmp1 = $1;
        res = new IR(kRoleIdent, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


label_ident:

    IDENT_sys {
        auto tmp1 = $1;
        res = new IR(kLabelIdent, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | label_keyword {
        auto tmp1 = $1;
        res = new IR(kLabelIdent, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


lvalue_ident:

    IDENT_sys {
        auto tmp1 = $1;
        res = new IR(kLvalueIdent, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | lvalue_keyword {
        auto tmp1 = $1;
        res = new IR(kLvalueIdent, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


ident_or_text:

    ident {
        auto tmp1 = $1;
        res = new IR(kIdentOrText, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | TEXT_STRING_sys {
        auto tmp1 = $1;
        res = new IR(kIdentOrText, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | LEX_HOSTNAME {
        res = new IR(kIdentOrText, OP3("LEX_HOSTNAME", "", ""));
        $$ = res;
    }

;


role_ident_or_text:

    role_ident {
        auto tmp1 = $1;
        res = new IR(kRoleIdentOrText, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | TEXT_STRING_sys {
        auto tmp1 = $1;
        res = new IR(kRoleIdentOrText, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | LEX_HOSTNAME {
        res = new IR(kRoleIdentOrText, OP3("LEX_HOSTNAME", "", ""));
        $$ = res;
    }

;


user_ident_or_text:

    ident_or_text {
        auto tmp1 = $1;
        res = new IR(kUserIdentOrText, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ident_or_text '@' ident_or_text {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kUserIdentOrText, OP3("", "@", ""), tmp1, tmp2);
        $$ = res;
    }

;


user:

    user_ident_or_text {
        auto tmp1 = $1;
        res = new IR(kUser, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CURRENT_USER optional_braces {
        auto tmp1 = $2;
        res = new IR(kUser, OP3("CURRENT_USER", "", ""), tmp1);
        $$ = res;
    }

;


role:

    role_ident_or_text {
        auto tmp1 = $1;
        res = new IR(kRole, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | role_ident_or_text '@' ident_or_text {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kRole, OP3("", "@", ""), tmp1, tmp2);
        $$ = res;
    }

;


schema:

    ident {
        auto tmp1 = $1;
        res = new IR(kSchema, OP3("", "", ""), tmp1);
        $$ = res;
    }

;

/*
Non-reserved keywords are allowed as unquoted identifiers in general.

OTOH, in a few particular cases statement-specific rules are used
instead of `ident_keyword` to avoid grammar ambiguities:

* `label_keyword` for SP label names
* `role_keyword` for role names
* `lvalue_keyword` for variable prefixes and names in left sides of
assignments in SET statements

Normally, new non-reserved words should be added to the
the rule `ident_keywords_unambiguous`. If they cause grammar conflicts, try
one of `ident_keywords_ambiguous_...` rules instead.
*/

ident_keyword:

    ident_keywords_unambiguous {
        auto tmp1 = $1;
        res = new IR(kIdentKeyword, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ident_keywords_ambiguous_1_roles_and_labels {
        auto tmp1 = $1;
        res = new IR(kIdentKeyword, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ident_keywords_ambiguous_2_labels {
        auto tmp1 = $1;
        res = new IR(kIdentKeyword, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ident_keywords_ambiguous_3_roles {
        auto tmp1 = $1;
        res = new IR(kIdentKeyword, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ident_keywords_ambiguous_4_system_variables {
        auto tmp1 = $1;
        res = new IR(kIdentKeyword, OP3("", "", ""), tmp1);
        $$ = res;
    }

;

/*
These non-reserved words cannot be used as role names and SP label names:
*/

ident_keywords_ambiguous_1_roles_and_labels:

    EXECUTE_SYM {
        res = new IR(kIdentKeywordsAmbiguous1RolesAndLabels, OP3("EXECUTE", "", ""));
        $$ = res;
    }

    | RESTART_SYM {
        res = new IR(kIdentKeywordsAmbiguous1RolesAndLabels, OP3("RESTART", "", ""));
        $$ = res;
    }

    | SHUTDOWN {
        res = new IR(kIdentKeywordsAmbiguous1RolesAndLabels, OP3("SHUTDOWN", "", ""));
        $$ = res;
    }

;

/*
These non-reserved keywords cannot be used as unquoted SP label names:
*/

ident_keywords_ambiguous_2_labels:

    ASCII_SYM {
        res = new IR(kIdentKeywordsAmbiguous2Labels, OP3("ASCII", "", ""));
        $$ = res;
    }

    | BEGIN_SYM {
        res = new IR(kIdentKeywordsAmbiguous2Labels, OP3("BEGIN", "", ""));
        $$ = res;
    }

    | BYTE_SYM {
        res = new IR(kIdentKeywordsAmbiguous2Labels, OP3("BYTE", "", ""));
        $$ = res;
    }

    | CACHE_SYM {
        res = new IR(kIdentKeywordsAmbiguous2Labels, OP3("CACHE", "", ""));
        $$ = res;
    }

    | CHARSET {
        res = new IR(kIdentKeywordsAmbiguous2Labels, OP3("CHARSET", "", ""));
        $$ = res;
    }

    | CHECKSUM_SYM {
        res = new IR(kIdentKeywordsAmbiguous2Labels, OP3("CHECKSUM", "", ""));
        $$ = res;
    }

    | CLONE_SYM {
        res = new IR(kIdentKeywordsAmbiguous2Labels, OP3("CLONE", "", ""));
        $$ = res;
    }

    | COMMENT_SYM {
        res = new IR(kIdentKeywordsAmbiguous2Labels, OP3("COMMENT", "", ""));
        $$ = res;
    }

    | COMMIT_SYM {
        res = new IR(kIdentKeywordsAmbiguous2Labels, OP3("COMMIT", "", ""));
        $$ = res;
    }

    | CONTAINS_SYM {
        res = new IR(kIdentKeywordsAmbiguous2Labels, OP3("CONTAINS", "", ""));
        $$ = res;
    }

    | DEALLOCATE_SYM {
        res = new IR(kIdentKeywordsAmbiguous2Labels, OP3("DEALLOCATE", "", ""));
        $$ = res;
    }

    | DO_SYM {
        res = new IR(kIdentKeywordsAmbiguous2Labels, OP3("DO", "", ""));
        $$ = res;
    }

    | END {
        res = new IR(kIdentKeywordsAmbiguous2Labels, OP3("END", "", ""));
        $$ = res;
    }

    | FLUSH_SYM {
        res = new IR(kIdentKeywordsAmbiguous2Labels, OP3("FLUSH", "", ""));
        $$ = res;
    }

    | FOLLOWS_SYM {
        res = new IR(kIdentKeywordsAmbiguous2Labels, OP3("FOLLOWS", "", ""));
        $$ = res;
    }

    | HANDLER_SYM {
        res = new IR(kIdentKeywordsAmbiguous2Labels, OP3("HANDLER", "", ""));
        $$ = res;
    }

    | HELP_SYM {
        res = new IR(kIdentKeywordsAmbiguous2Labels, OP3("HELP", "", ""));
        $$ = res;
    }

    | IMPORT {
        res = new IR(kIdentKeywordsAmbiguous2Labels, OP3("IMPORT", "", ""));
        $$ = res;
    }

    | INSTALL_SYM {
        res = new IR(kIdentKeywordsAmbiguous2Labels, OP3("INSTALL", "", ""));
        $$ = res;
    }

    | LANGUAGE_SYM {
        res = new IR(kIdentKeywordsAmbiguous2Labels, OP3("LANGUAGE", "", ""));
        $$ = res;
    }

    | NO_SYM {
        res = new IR(kIdentKeywordsAmbiguous2Labels, OP3("NO", "", ""));
        $$ = res;
    }

    | PRECEDES_SYM {
        res = new IR(kIdentKeywordsAmbiguous2Labels, OP3("PRECEDES", "", ""));
        $$ = res;
    }

    | PREPARE_SYM {
        res = new IR(kIdentKeywordsAmbiguous2Labels, OP3("PREPARE", "", ""));
        $$ = res;
    }

    | REPAIR {
        res = new IR(kIdentKeywordsAmbiguous2Labels, OP3("REPAIR", "", ""));
        $$ = res;
    }

    | RESET_SYM {
        res = new IR(kIdentKeywordsAmbiguous2Labels, OP3("RESET", "", ""));
        $$ = res;
    }

    | ROLLBACK_SYM {
        res = new IR(kIdentKeywordsAmbiguous2Labels, OP3("ROLLBACK", "", ""));
        $$ = res;
    }

    | SAVEPOINT_SYM {
        res = new IR(kIdentKeywordsAmbiguous2Labels, OP3("SAVEPOINT", "", ""));
        $$ = res;
    }

    | SIGNED_SYM {
        res = new IR(kIdentKeywordsAmbiguous2Labels, OP3("SIGNED", "", ""));
        $$ = res;
    }

    | SLAVE {
        res = new IR(kIdentKeywordsAmbiguous2Labels, OP3("SLAVE", "", ""));
        $$ = res;
    }

    | START_SYM {
        res = new IR(kIdentKeywordsAmbiguous2Labels, OP3("START", "", ""));
        $$ = res;
    }

    | STOP_SYM {
        res = new IR(kIdentKeywordsAmbiguous2Labels, OP3("STOP", "", ""));
        $$ = res;
    }

    | TRUNCATE_SYM {
        res = new IR(kIdentKeywordsAmbiguous2Labels, OP3("TRUNCATE", "", ""));
        $$ = res;
    }

    | UNICODE_SYM {
        res = new IR(kIdentKeywordsAmbiguous2Labels, OP3("UNICODE", "", ""));
        $$ = res;
    }

    | UNINSTALL_SYM {
        res = new IR(kIdentKeywordsAmbiguous2Labels, OP3("UNINSTALL", "", ""));
        $$ = res;
    }

    | XA_SYM {
        res = new IR(kIdentKeywordsAmbiguous2Labels, OP3("XA", "", ""));
        $$ = res;
    }

;

/*
Keywords that we allow for labels in SPs in the unquoted form.
Any keyword that is allowed to begin a statement or routine characteristics
must be in `ident_keywords_ambiguous_2_labels` above, otherwise
we get (harmful) shift/reduce conflicts.

Not allowed:

ident_keywords_ambiguous_1_roles_and_labels
ident_keywords_ambiguous_2_labels
*/

label_keyword:

    ident_keywords_unambiguous {
        auto tmp1 = $1;
        res = new IR(kLabelKeyword, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ident_keywords_ambiguous_3_roles {
        auto tmp1 = $1;
        res = new IR(kLabelKeyword, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ident_keywords_ambiguous_4_system_variables {
        auto tmp1 = $1;
        res = new IR(kLabelKeyword, OP3("", "", ""), tmp1);
        $$ = res;
    }

;

/*
These non-reserved keywords cannot be used as unquoted role names:
*/

ident_keywords_ambiguous_3_roles:

    EVENT_SYM {
        res = new IR(kIdentKeywordsAmbiguous3Roles, OP3("EVENT", "", ""));
        $$ = res;
    }

    | FILE_SYM {
        res = new IR(kIdentKeywordsAmbiguous3Roles, OP3("FILE", "", ""));
        $$ = res;
    }

    | NONE_SYM {
        res = new IR(kIdentKeywordsAmbiguous3Roles, OP3("NONE", "", ""));
        $$ = res;
    }

    | PROCESS {
        res = new IR(kIdentKeywordsAmbiguous3Roles, OP3("PROCESS", "", ""));
        $$ = res;
    }

    | PROXY_SYM {
        res = new IR(kIdentKeywordsAmbiguous3Roles, OP3("PROXY", "", ""));
        $$ = res;
    }

    | RELOAD {
        res = new IR(kIdentKeywordsAmbiguous3Roles, OP3("RELOAD", "", ""));
        $$ = res;
    }

    | REPLICATION {
        res = new IR(kIdentKeywordsAmbiguous3Roles, OP3("REPLICATION", "", ""));
        $$ = res;
    }

    | RESOURCE_SYM {
        res = new IR(kIdentKeywordsAmbiguous3Roles, OP3("RESOURCE", "", ""));
        $$ = res;
    }

    | SUPER_SYM {
        res = new IR(kIdentKeywordsAmbiguous3Roles, OP3("SUPER", "", ""));
        $$ = res;
    }

;

/*
These are the non-reserved keywords which may be used for unquoted
identifiers everywhere without introducing grammar conflicts:
*/

ident_keywords_unambiguous:

    ACTION {
        res = new IR(kIdentKeywordsUnambiguous, OP3("ACTION", "", ""));
        $$ = res;
    }

    | ACCOUNT_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("ACCOUNT", "", ""));
        $$ = res;
    }

    | ACTIVE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("ACTIVE", "", ""));
        $$ = res;
    }

    | ADDDATE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("ADDDATE", "", ""));
        $$ = res;
    }

    | ADMIN_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("ADMIN", "", ""));
        $$ = res;
    }

    | AFTER_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("AFTER", "", ""));
        $$ = res;
    }

    | AGAINST {
        res = new IR(kIdentKeywordsUnambiguous, OP3("AGAINST", "", ""));
        $$ = res;
    }

    | AGGREGATE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("AGGREGATE", "", ""));
        $$ = res;
    }

    | ALGORITHM_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("ALGORITHM", "", ""));
        $$ = res;
    }

    | ALWAYS_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("ALWAYS", "", ""));
        $$ = res;
    }

    | ANY_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("ANY", "", ""));
        $$ = res;
    }

    | ARRAY_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("ARRAY", "", ""));
        $$ = res;
    }

    | AT_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("AT", "", ""));
        $$ = res;
    }

    | ATTRIBUTE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("ATTRIBUTE", "", ""));
        $$ = res;
    }

    | AUTHENTICATION_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("AUTHENTICATION", "", ""));
        $$ = res;
    }

    | AUTOEXTEND_SIZE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("AUTOEXTEND_SIZE", "", ""));
        $$ = res;
    }

    | AUTO_INC {
        res = new IR(kIdentKeywordsUnambiguous, OP3("AUTO_INCREMENT", "", ""));
        $$ = res;
    }

    | AVG_ROW_LENGTH {
        res = new IR(kIdentKeywordsUnambiguous, OP3("AVG_ROW_LENGTH", "", ""));
        $$ = res;
    }

    | AVG_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("AVG", "", ""));
        $$ = res;
    }

    | BACKUP_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("BACKUP", "", ""));
        $$ = res;
    }

    | BINLOG_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("BINLOG", "", ""));
        $$ = res;
    }

    | BIT_SYM %prec KEYWORD_USED_AS_IDENT {
        res = new IR(kIdentKeywordsUnambiguous, OP3("BIT", "", ""));
        $$ = res;
    }

    | BLOCK_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("BLOCK", "", ""));
        $$ = res;
    }

    | BOOLEAN_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("BOOLEAN", "", ""));
        $$ = res;
    }

    | BOOL_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("BOOL", "", ""));
        $$ = res;
    }

    | BTREE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("BTREE", "", ""));
        $$ = res;
    }

    | BUCKETS_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("BUCKETS", "", ""));
        $$ = res;
    }

    | CASCADED {
        res = new IR(kIdentKeywordsUnambiguous, OP3("CASCADED", "", ""));
        $$ = res;
    }

    | CATALOG_NAME_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("CATALOG_NAME", "", ""));
        $$ = res;
    }

    | CHAIN_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("CHAIN", "", ""));
        $$ = res;
    }

    | CHALLENGE_RESPONSE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("CHALLENGE_RESPONSE", "", ""));
        $$ = res;
    }

    | CHANGED {
        res = new IR(kIdentKeywordsUnambiguous, OP3("CHANGED", "", ""));
        $$ = res;
    }

    | CHANNEL_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("CHANNEL", "", ""));
        $$ = res;
    }

    | CIPHER_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("CIPHER", "", ""));
        $$ = res;
    }

    | CLASS_ORIGIN_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("CLASS_ORIGIN", "", ""));
        $$ = res;
    }

    | CLIENT_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("CLIENT", "", ""));
        $$ = res;
    }

    | CLOSE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("CLOSE", "", ""));
        $$ = res;
    }

    | COALESCE {
        res = new IR(kIdentKeywordsUnambiguous, OP3("COALESCE", "", ""));
        $$ = res;
    }

    | CODE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("CODE", "", ""));
        $$ = res;
    }

    | COLLATION_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("COLLATION", "", ""));
        $$ = res;
    }

    | COLUMNS {
        res = new IR(kIdentKeywordsUnambiguous, OP3("COLUMNS", "", ""));
        $$ = res;
    }

    | COLUMN_FORMAT_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("COLUMN_FORMAT", "", ""));
        $$ = res;
    }

    | COLUMN_NAME_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("COLUMN_NAME", "", ""));
        $$ = res;
    }

    | COMMITTED_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("COMMITTED", "", ""));
        $$ = res;
    }

    | COMPACT_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("COMPACT", "", ""));
        $$ = res;
    }

    | COMPLETION_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("COMPLETION", "", ""));
        $$ = res;
    }

    | COMPONENT_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("COMPONENT", "", ""));
        $$ = res;
    }

    | COMPRESSED_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("COMPRESSED", "", ""));
        $$ = res;
    }

    | COMPRESSION_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("COMPRESSION", "", ""));
        $$ = res;
    }

    | CONCURRENT {
        res = new IR(kIdentKeywordsUnambiguous, OP3("CONCURRENT", "", ""));
        $$ = res;
    }

    | CONNECTION_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("CONNECTION", "", ""));
        $$ = res;
    }

    | CONSISTENT_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("CONSISTENT", "", ""));
        $$ = res;
    }

    | CONSTRAINT_CATALOG_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("CONSTRAINT_CATALOG", "", ""));
        $$ = res;
    }

    | CONSTRAINT_NAME_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("CONSTRAINT_NAME", "", ""));
        $$ = res;
    }

    | CONSTRAINT_SCHEMA_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("CONSTRAINT_SCHEMA", "", ""));
        $$ = res;
    }

    | CONTEXT_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("CONTEXT", "", ""));
        $$ = res;
    }

    | CPU_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("CPU", "", ""));
        $$ = res;
    }

    | CURRENT_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("CURRENT", "", ""));
        $$ = res;
    }

    | CURSOR_NAME_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("CURSOR_NAME", "", ""));
        $$ = res;
    }

    | DATAFILE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("DATAFILE", "", ""));
        $$ = res;
    }

    | DATA_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("DATA", "", ""));
        $$ = res;
    }

    | DATETIME_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("DATETIME", "", ""));
        $$ = res;
    }

    | DATE_SYM %prec KEYWORD_USED_AS_IDENT {
        res = new IR(kIdentKeywordsUnambiguous, OP3("DATE", "", ""));
        $$ = res;
    }

    | DAY_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("DAY", "", ""));
        $$ = res;
    }

    | DEFAULT_AUTH_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("DEFAULT_AUTH", "", ""));
        $$ = res;
    }

    | DEFINER_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("DEFINER", "", ""));
        $$ = res;
    }

    | DEFINITION_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("DEFINITION", "", ""));
        $$ = res;
    }

    | DELAY_KEY_WRITE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("DELAY_KEY_WRITE", "", ""));
        $$ = res;
    }

    | DESCRIPTION_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("DESCRIPTION", "", ""));
        $$ = res;
    }

    | DIAGNOSTICS_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("DIAGNOSTICS", "", ""));
        $$ = res;
    }

    | DIRECTORY_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("DIRECTORY", "", ""));
        $$ = res;
    }

    | DISABLE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("DISABLE", "", ""));
        $$ = res;
    }

    | DISCARD_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("DISCARD", "", ""));
        $$ = res;
    }

    | DISK_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("DISK", "", ""));
        $$ = res;
    }

    | DUMPFILE {
        res = new IR(kIdentKeywordsUnambiguous, OP3("DUMPFILE", "", ""));
        $$ = res;
    }

    | DUPLICATE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("DUPLICATE", "", ""));
        $$ = res;
    }

    | DYNAMIC_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("DYNAMIC", "", ""));
        $$ = res;
    }

    | ENABLE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("ENABLE", "", ""));
        $$ = res;
    }

    | ENCRYPTION_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("ENCRYPTION", "", ""));
        $$ = res;
    }

    | ENDS_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("ENDS", "", ""));
        $$ = res;
    }

    | ENFORCED_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("ENFORCED", "", ""));
        $$ = res;
    }

    | ENGINES_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("ENGINES", "", ""));
        $$ = res;
    }

    | ENGINE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("ENGINE", "", ""));
        $$ = res;
    }

    | ENGINE_ATTRIBUTE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("ENGINE_ATTRIBUTE", "", ""));
        $$ = res;
    }

    | ENUM_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("ENUM", "", ""));
        $$ = res;
    }

    | ERRORS {
        res = new IR(kIdentKeywordsUnambiguous, OP3("ERRORS", "", ""));
        $$ = res;
    }

    | ERROR_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("ERROR", "", ""));
        $$ = res;
    }

    | ESCAPE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("ESCAPE", "", ""));
        $$ = res;
    }

    | EVENTS_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("EVENTS", "", ""));
        $$ = res;
    }

    | EVERY_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("EVERY", "", ""));
        $$ = res;
    }

    | EXCHANGE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("EXCHANGE", "", ""));
        $$ = res;
    }

    | EXCLUDE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("EXCLUDE", "", ""));
        $$ = res;
    }

    | EXPANSION_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("EXPANSION", "", ""));
        $$ = res;
    }

    | EXPIRE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("EXPIRE", "", ""));
        $$ = res;
    }

    | EXPORT_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("EXPORT", "", ""));
        $$ = res;
    }

    | EXTENDED_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("EXTENDED", "", ""));
        $$ = res;
    }

    | EXTENT_SIZE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("EXTENT_SIZE", "", ""));
        $$ = res;
    }

    | FACTOR_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("FACTOR", "", ""));
        $$ = res;
    }

    | FAILED_LOGIN_ATTEMPTS_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("FAILED_LOGIN_ATTEMPTS", "", ""));
        $$ = res;
    }

    | FAST_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("FAST", "", ""));
        $$ = res;
    }

    | FAULTS_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("FAULTS", "", ""));
        $$ = res;
    }

    | FILE_BLOCK_SIZE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("FILE_BLOCK_SIZE", "", ""));
        $$ = res;
    }

    | FILTER_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("FILTER", "", ""));
        $$ = res;
    }

    | FINISH_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("FINISH", "", ""));
        $$ = res;
    }

    | FIRST_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("FIRST", "", ""));
        $$ = res;
    }

    | FIXED_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("FIXED", "", ""));
        $$ = res;
    }

    | FOLLOWING_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("FOLLOWING", "", ""));
        $$ = res;
    }

    | FORMAT_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("FORMAT", "", ""));
        $$ = res;
    }

    | FOUND_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("FOUND", "", ""));
        $$ = res;
    }

    | FULL {
        res = new IR(kIdentKeywordsUnambiguous, OP3("FULL", "", ""));
        $$ = res;
    }

    | GENERAL {
        res = new IR(kIdentKeywordsUnambiguous, OP3("GENERAL", "", ""));
        $$ = res;
    }

    | GEOMETRYCOLLECTION_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("GEOMCOLLECTION", "", ""));
        $$ = res;
    }

    | GEOMETRY_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("GEOMETRY", "", ""));
        $$ = res;
    }

    | GET_FORMAT {
        res = new IR(kIdentKeywordsUnambiguous, OP3("GET_FORMAT", "", ""));
        $$ = res;
    }

    | GET_MASTER_PUBLIC_KEY_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("GET_MASTER_PUBLIC_KEY", "", ""));
        $$ = res;
    }

    | GET_SOURCE_PUBLIC_KEY_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("GET_SOURCE_PUBLIC_KEY", "", ""));
        $$ = res;
    }

    | GRANTS {
        res = new IR(kIdentKeywordsUnambiguous, OP3("GRANTS", "", ""));
        $$ = res;
    }

    | GROUP_REPLICATION {
        res = new IR(kIdentKeywordsUnambiguous, OP3("GROUP_REPLICATION", "", ""));
        $$ = res;
    }

    | GTID_ONLY_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("GTID_ONLY", "", ""));
        $$ = res;
    }

    | HASH_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("HASH", "", ""));
        $$ = res;
    }

    | HISTOGRAM_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("HISTOGRAM", "", ""));
        $$ = res;
    }

    | HISTORY_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("HISTORY", "", ""));
        $$ = res;
    }

    | HOSTS_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("HOSTS", "", ""));
        $$ = res;
    }

    | HOST_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("HOST", "", ""));
        $$ = res;
    }

    | HOUR_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("HOUR", "", ""));
        $$ = res;
    }

    | IDENTIFIED_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("IDENTIFIED", "", ""));
        $$ = res;
    }

    | IGNORE_SERVER_IDS_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("IGNORE_SERVER_IDS", "", ""));
        $$ = res;
    }

    | INACTIVE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("INACTIVE", "", ""));
        $$ = res;
    }

    | INDEXES {
        res = new IR(kIdentKeywordsUnambiguous, OP3("INDEXES", "", ""));
        $$ = res;
    }

    | INITIAL_SIZE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("INITIAL_SIZE", "", ""));
        $$ = res;
    }

    | INITIAL_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("INITIAL", "", ""));
        $$ = res;
    }

    | INITIATE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("INITIATE", "", ""));
        $$ = res;
    }

    | INSERT_METHOD {
        res = new IR(kIdentKeywordsUnambiguous, OP3("INSERT_METHOD", "", ""));
        $$ = res;
    }

    | INSTANCE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("INSTANCE", "", ""));
        $$ = res;
    }

    | INVISIBLE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("INVISIBLE", "", ""));
        $$ = res;
    }

    | INVOKER_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("INVOKER", "", ""));
        $$ = res;
    }

    | IO_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("IO", "", ""));
        $$ = res;
    }

    | IPC_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("IPC", "", ""));
        $$ = res;
    }

    | ISOLATION {
        res = new IR(kIdentKeywordsUnambiguous, OP3("ISOLATION", "", ""));
        $$ = res;
    }

    | ISSUER_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("ISSUER", "", ""));
        $$ = res;
    }

    | JSON_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("JSON", "", ""));
        $$ = res;
    }

    | JSON_VALUE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("JSON_VALUE", "", ""));
        $$ = res;
    }

    | KEY_BLOCK_SIZE {
        res = new IR(kIdentKeywordsUnambiguous, OP3("KEY_BLOCK_SIZE", "", ""));
        $$ = res;
    }

    | KEYRING_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("KEYRING", "", ""));
        $$ = res;
    }

    | LAST_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("LAST", "", ""));
        $$ = res;
    }

    | LEAVES {
        res = new IR(kIdentKeywordsUnambiguous, OP3("LEAVES", "", ""));
        $$ = res;
    }

    | LESS_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("LESS", "", ""));
        $$ = res;
    }

    | LEVEL_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("LEVEL", "", ""));
        $$ = res;
    }

    | LINESTRING_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("LINESTRING", "", ""));
        $$ = res;
    }

    | LIST_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("LIST", "", ""));
        $$ = res;
    }

    | LOCKED_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("LOCKED", "", ""));
        $$ = res;
    }

    | LOCKS_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("LOCKS", "", ""));
        $$ = res;
    }

    | LOGFILE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("LOGFILE", "", ""));
        $$ = res;
    }

    | LOGS_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("LOGS", "", ""));
        $$ = res;
    }

    | MASTER_AUTO_POSITION_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MASTER_AUTO_POSITION", "", ""));
        $$ = res;
    }

    | MASTER_COMPRESSION_ALGORITHM_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MASTER_COMPRESSION_ALGORITHMS", "", ""));
        $$ = res;
    }

    | MASTER_CONNECT_RETRY_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MASTER_CONNECT_RETRY", "", ""));
        $$ = res;
    }

    | MASTER_DELAY_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MASTER_DELAY", "", ""));
        $$ = res;
    }

    | MASTER_HEARTBEAT_PERIOD_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MASTER_HEARTBEAT_PERIOD", "", ""));
        $$ = res;
    }

    | MASTER_HOST_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MASTER_HOST", "", ""));
        $$ = res;
    }

    | NETWORK_NAMESPACE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("NETWORK_NAMESPACE", "", ""));
        $$ = res;
    }

    | MASTER_LOG_FILE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MASTER_LOG_FILE", "", ""));
        $$ = res;
    }

    | MASTER_LOG_POS_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MASTER_LOG_POS", "", ""));
        $$ = res;
    }

    | MASTER_PASSWORD_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MASTER_PASSWORD", "", ""));
        $$ = res;
    }

    | MASTER_PORT_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MASTER_PORT", "", ""));
        $$ = res;
    }

    | MASTER_PUBLIC_KEY_PATH_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MASTER_PUBLIC_KEY_PATH", "", ""));
        $$ = res;
    }

    | MASTER_RETRY_COUNT_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MASTER_RETRY_COUNT", "", ""));
        $$ = res;
    }

    | MASTER_SSL_CAPATH_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MASTER_SSL_CAPATH", "", ""));
        $$ = res;
    }

    | MASTER_SSL_CA_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MASTER_SSL_CA", "", ""));
        $$ = res;
    }

    | MASTER_SSL_CERT_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MASTER_SSL_CERT", "", ""));
        $$ = res;
    }

    | MASTER_SSL_CIPHER_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MASTER_SSL_CIPHER", "", ""));
        $$ = res;
    }

    | MASTER_SSL_CRLPATH_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MASTER_SSL_CRLPATH", "", ""));
        $$ = res;
    }

    | MASTER_SSL_CRL_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MASTER_SSL_CRL", "", ""));
        $$ = res;
    }

    | MASTER_SSL_KEY_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MASTER_SSL_KEY", "", ""));
        $$ = res;
    }

    | MASTER_SSL_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MASTER_SSL", "", ""));
        $$ = res;
    }

    | MASTER_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MASTER", "", ""));
        $$ = res;
    }

    | MASTER_TLS_CIPHERSUITES_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MASTER_TLS_CIPHERSUITES", "", ""));
        $$ = res;
    }

    | MASTER_TLS_VERSION_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MASTER_TLS_VERSION", "", ""));
        $$ = res;
    }

    | MASTER_USER_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MASTER_USER", "", ""));
        $$ = res;
    }

    | MASTER_ZSTD_COMPRESSION_LEVEL_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MASTER_ZSTD_COMPRESSION_LEVEL", "", ""));
        $$ = res;
    }

    | MAX_CONNECTIONS_PER_HOUR {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MAX_CONNECTIONS_PER_HOUR", "", ""));
        $$ = res;
    }

    | MAX_QUERIES_PER_HOUR {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MAX_QUERIES_PER_HOUR", "", ""));
        $$ = res;
    }

    | MAX_ROWS {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MAX_ROWS", "", ""));
        $$ = res;
    }

    | MAX_SIZE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MAX_SIZE", "", ""));
        $$ = res;
    }

    | MAX_UPDATES_PER_HOUR {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MAX_UPDATES_PER_HOUR", "", ""));
        $$ = res;
    }

    | MAX_USER_CONNECTIONS_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MAX_USER_CONNECTIONS", "", ""));
        $$ = res;
    }

    | MEDIUM_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MEDIUM", "", ""));
        $$ = res;
    }

    | MEMBER_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MEMBER", "", ""));
        $$ = res;
    }

    | MEMORY_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MEMORY", "", ""));
        $$ = res;
    }

    | MERGE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MERGE", "", ""));
        $$ = res;
    }

    | MESSAGE_TEXT_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MESSAGE_TEXT", "", ""));
        $$ = res;
    }

    | MICROSECOND_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MICROSECOND", "", ""));
        $$ = res;
    }

    | MIGRATE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MIGRATE", "", ""));
        $$ = res;
    }

    | MINUTE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MINUTE", "", ""));
        $$ = res;
    }

    | MIN_ROWS {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MIN_ROWS", "", ""));
        $$ = res;
    }

    | MODE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MODE", "", ""));
        $$ = res;
    }

    | MODIFY_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MODIFY", "", ""));
        $$ = res;
    }

    | MONTH_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MONTH", "", ""));
        $$ = res;
    }

    | MULTILINESTRING_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MULTILINESTRING", "", ""));
        $$ = res;
    }

    | MULTIPOINT_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MULTIPOINT", "", ""));
        $$ = res;
    }

    | MULTIPOLYGON_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MULTIPOLYGON", "", ""));
        $$ = res;
    }

    | MUTEX_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MUTEX", "", ""));
        $$ = res;
    }

    | MYSQL_ERRNO_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("MYSQL_ERRNO", "", ""));
        $$ = res;
    }

    | NAMES_SYM %prec KEYWORD_USED_AS_IDENT {
        res = new IR(kIdentKeywordsUnambiguous, OP3("NAMES", "", ""));
        $$ = res;
    }

    | NAME_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("NAME", "", ""));
        $$ = res;
    }

    | NATIONAL_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("NATIONAL", "", ""));
        $$ = res;
    }

    | NCHAR_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("NCHAR", "", ""));
        $$ = res;
    }

    | NDBCLUSTER_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("NDB", "", ""));
        $$ = res;
    }

    | NESTED_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("NESTED", "", ""));
        $$ = res;
    }

    | NEVER_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("NEVER", "", ""));
        $$ = res;
    }

    | NEW_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("NEW", "", ""));
        $$ = res;
    }

    | NEXT_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("NEXT", "", ""));
        $$ = res;
    }

    | NODEGROUP_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("NODEGROUP", "", ""));
        $$ = res;
    }

    | NOWAIT_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("NOWAIT", "", ""));
        $$ = res;
    }

    | NO_WAIT_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("NO_WAIT", "", ""));
        $$ = res;
    }

    | NULLS_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("NULLS", "", ""));
        $$ = res;
    }

    | NUMBER_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("NUMBER", "", ""));
        $$ = res;
    }

    | NVARCHAR_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("NVARCHAR", "", ""));
        $$ = res;
    }

    | OFF_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("OFF", "", ""));
        $$ = res;
    }

    | OFFSET_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("OFFSET", "", ""));
        $$ = res;
    }

    | OJ_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("OJ", "", ""));
        $$ = res;
    }

    | OLD_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("OLD", "", ""));
        $$ = res;
    }

    | ONE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("ONE", "", ""));
        $$ = res;
    }

    | ONLY_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("ONLY", "", ""));
        $$ = res;
    }

    | OPEN_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("OPEN", "", ""));
        $$ = res;
    }

    | OPTIONAL_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("OPTIONAL", "", ""));
        $$ = res;
    }

    | OPTIONS_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("OPTIONS", "", ""));
        $$ = res;
    }

    | ORDINALITY_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("ORDINALITY", "", ""));
        $$ = res;
    }

    | ORGANIZATION_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("ORGANIZATION", "", ""));
        $$ = res;
    }

    | OTHERS_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("OTHERS", "", ""));
        $$ = res;
    }

    | OWNER_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("OWNER", "", ""));
        $$ = res;
    }

    | PACK_KEYS_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("PACK_KEYS", "", ""));
        $$ = res;
    }

    | PAGE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("PAGE", "", ""));
        $$ = res;
    }

    | PARSER_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("PARSER", "", ""));
        $$ = res;
    }

    | PARTIAL {
        res = new IR(kIdentKeywordsUnambiguous, OP3("PARTIAL", "", ""));
        $$ = res;
    }

    | PARTITIONING_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("PARTITIONING", "", ""));
        $$ = res;
    }

    | PARTITIONS_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("PARTITIONS", "", ""));
        $$ = res;
    }

    | PASSWORD %prec KEYWORD_USED_AS_IDENT {
        res = new IR(kIdentKeywordsUnambiguous, OP3("PASSWORD", "", ""));
        $$ = res;
    }

    | PASSWORD_LOCK_TIME_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("PASSWORD_LOCK_TIME", "", ""));
        $$ = res;
    }

    | PATH_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("PATH", "", ""));
        $$ = res;
    }

    | PHASE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("PHASE", "", ""));
        $$ = res;
    }

    | PLUGINS_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("PLUGINS", "", ""));
        $$ = res;
    }

    | PLUGIN_DIR_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("PLUGIN_DIR", "", ""));
        $$ = res;
    }

    | PLUGIN_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("PLUGIN", "", ""));
        $$ = res;
    }

    | POINT_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("POINT", "", ""));
        $$ = res;
    }

    | POLYGON_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("POLYGON", "", ""));
        $$ = res;
    }

    | PORT_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("PORT", "", ""));
        $$ = res;
    }

    | PRECEDING_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("PRECEDING", "", ""));
        $$ = res;
    }

    | PRESERVE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("PRESERVE", "", ""));
        $$ = res;
    }

    | PREV_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("PREV", "", ""));
        $$ = res;
    }

    | PRIVILEGES {
        res = new IR(kIdentKeywordsUnambiguous, OP3("PRIVILEGES", "", ""));
        $$ = res;
    }

    | PRIVILEGE_CHECKS_USER_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("PRIVILEGE_CHECKS_USER", "", ""));
        $$ = res;
    }

    | PROCESSLIST_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("PROCESSLIST", "", ""));
        $$ = res;
    }

    | PROFILES_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("PROFILES", "", ""));
        $$ = res;
    }

    | PROFILE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("PROFILE", "", ""));
        $$ = res;
    }

    | QUARTER_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("QUARTER", "", ""));
        $$ = res;
    }

    | QUERY_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("QUERY", "", ""));
        $$ = res;
    }

    | QUICK {
        res = new IR(kIdentKeywordsUnambiguous, OP3("QUICK", "", ""));
        $$ = res;
    }

    | RANDOM_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("RANDOM", "", ""));
        $$ = res;
    }

    | READ_ONLY_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("READ_ONLY", "", ""));
        $$ = res;
    }

    | REBUILD_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("REBUILD", "", ""));
        $$ = res;
    }

    | RECOVER_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("RECOVER", "", ""));
        $$ = res;
    }

    | REDO_BUFFER_SIZE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("REDO_BUFFER_SIZE", "", ""));
        $$ = res;
    }

    | REDUNDANT_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("REDUNDANT", "", ""));
        $$ = res;
    }

    | REFERENCE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("REFERENCE", "", ""));
        $$ = res;
    }

    | REGISTRATION_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("REGISTRATION", "", ""));
        $$ = res;
    }

    | RELAY {
        res = new IR(kIdentKeywordsUnambiguous, OP3("RELAY", "", ""));
        $$ = res;
    }

    | RELAYLOG_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("RELAYLOG", "", ""));
        $$ = res;
    }

    | RELAY_LOG_FILE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("RELAY_LOG_FILE", "", ""));
        $$ = res;
    }

    | RELAY_LOG_POS_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("RELAY_LOG_POS", "", ""));
        $$ = res;
    }

    | RELAY_THREAD {
        res = new IR(kIdentKeywordsUnambiguous, OP3("IO_THREAD", "", ""));
        $$ = res;
    }

    | REMOVE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("REMOVE", "", ""));
        $$ = res;
    }

    | ASSIGN_GTIDS_TO_ANONYMOUS_TRANSACTIONS_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("ASSIGN_GTIDS_TO_ANONYMOUS_TRANSACTIONS", "", ""));
        $$ = res;
    }

    | REORGANIZE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("REORGANIZE", "", ""));
        $$ = res;
    }

    | REPEATABLE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("REPEATABLE", "", ""));
        $$ = res;
    }

    | REPLICAS_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("REPLICAS", "", ""));
        $$ = res;
    }

    | REPLICATE_DO_DB {
        res = new IR(kIdentKeywordsUnambiguous, OP3("REPLICATE_DO_DB", "", ""));
        $$ = res;
    }

    | REPLICATE_DO_TABLE {
        res = new IR(kIdentKeywordsUnambiguous, OP3("REPLICATE_DO_TABLE", "", ""));
        $$ = res;
    }

    | REPLICATE_IGNORE_DB {
        res = new IR(kIdentKeywordsUnambiguous, OP3("REPLICATE_IGNORE_DB", "", ""));
        $$ = res;
    }

    | REPLICATE_IGNORE_TABLE {
        res = new IR(kIdentKeywordsUnambiguous, OP3("REPLICATE_IGNORE_TABLE", "", ""));
        $$ = res;
    }

    | REPLICATE_REWRITE_DB {
        res = new IR(kIdentKeywordsUnambiguous, OP3("REPLICATE_REWRITE_DB", "", ""));
        $$ = res;
    }

    | REPLICATE_WILD_DO_TABLE {
        res = new IR(kIdentKeywordsUnambiguous, OP3("REPLICATE_WILD_DO_TABLE", "", ""));
        $$ = res;
    }

    | REPLICATE_WILD_IGNORE_TABLE {
        res = new IR(kIdentKeywordsUnambiguous, OP3("REPLICATE_WILD_IGNORE_TABLE", "", ""));
        $$ = res;
    }

    | REPLICA_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("REPLICA", "", ""));
        $$ = res;
    }

    | REQUIRE_ROW_FORMAT_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("REQUIRE_ROW_FORMAT", "", ""));
        $$ = res;
    }

    | REQUIRE_TABLE_PRIMARY_KEY_CHECK_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("REQUIRE_TABLE_PRIMARY_KEY_CHECK", "", ""));
        $$ = res;
    }

    | RESOURCES {
        res = new IR(kIdentKeywordsUnambiguous, OP3("USER_RESOURCES", "", ""));
        $$ = res;
    }

    | RESPECT_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("RESPECT", "", ""));
        $$ = res;
    }

    | RESTORE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("RESTORE", "", ""));
        $$ = res;
    }

    | RESUME_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("RESUME", "", ""));
        $$ = res;
    }

    | RETAIN_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("RETAIN", "", ""));
        $$ = res;
    }

    | RETURNED_SQLSTATE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("RETURNED_SQLSTATE", "", ""));
        $$ = res;
    }

    | RETURNING_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("RETURNING", "", ""));
        $$ = res;
    }

    | RETURNS_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("RETURNS", "", ""));
        $$ = res;
    }

    | REUSE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("REUSE", "", ""));
        $$ = res;
    }

    | REVERSE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("REVERSE", "", ""));
        $$ = res;
    }

    | ROLE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("ROLE", "", ""));
        $$ = res;
    }

    | ROLLUP_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("ROLLUP", "", ""));
        $$ = res;
    }

    | ROTATE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("ROTATE", "", ""));
        $$ = res;
    }

    | ROUTINE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("ROUTINE", "", ""));
        $$ = res;
    }

    | ROW_COUNT_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("ROW_COUNT", "", ""));
        $$ = res;
    }

    | ROW_FORMAT_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("ROW_FORMAT", "", ""));
        $$ = res;
    }

    | RTREE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("RTREE", "", ""));
        $$ = res;
    }

    | SCHEDULE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SCHEDULE", "", ""));
        $$ = res;
    }

    | SCHEMA_NAME_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SCHEMA_NAME", "", ""));
        $$ = res;
    }

    | SECONDARY_ENGINE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SECONDARY_ENGINE", "", ""));
        $$ = res;
    }

    | SECONDARY_ENGINE_ATTRIBUTE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SECONDARY_ENGINE_ATTRIBUTE", "", ""));
        $$ = res;
    }

    | SECONDARY_LOAD_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SECONDARY_LOAD", "", ""));
        $$ = res;
    }

    | SECONDARY_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SECONDARY", "", ""));
        $$ = res;
    }

    | SECONDARY_UNLOAD_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SECONDARY_UNLOAD", "", ""));
        $$ = res;
    }

    | SECOND_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SECOND", "", ""));
        $$ = res;
    }

    | SECURITY_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SECURITY", "", ""));
        $$ = res;
    }

    | SERIALIZABLE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SERIALIZABLE", "", ""));
        $$ = res;
    }

    | SERIAL_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SERIAL", "", ""));
        $$ = res;
    }

    | SERVER_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SERVER", "", ""));
        $$ = res;
    }

    | SHARE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SHARE", "", ""));
        $$ = res;
    }

    | SIMPLE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SIMPLE", "", ""));
        $$ = res;
    }

    | SKIP_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SKIP", "", ""));
        $$ = res;
    }

    | SLOW {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SLOW", "", ""));
        $$ = res;
    }

    | SNAPSHOT_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SNAPSHOT", "", ""));
        $$ = res;
    }

    | SOCKET_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SOCKET", "", ""));
        $$ = res;
    }

    | SONAME_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SONAME", "", ""));
        $$ = res;
    }

    | SOUNDS_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SOUNDS", "", ""));
        $$ = res;
    }

    | SOURCE_AUTO_POSITION_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SOURCE_AUTO_POSITION", "", ""));
        $$ = res;
    }

    | SOURCE_BIND_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SOURCE_BIND", "", ""));
        $$ = res;
    }

    | SOURCE_COMPRESSION_ALGORITHM_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SOURCE_COMPRESSION_ALGORITHMS", "", ""));
        $$ = res;
    }

    | SOURCE_CONNECTION_AUTO_FAILOVER_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SOURCE_CONNECTION_AUTO_FAILOVER", "", ""));
        $$ = res;
    }

    | SOURCE_CONNECT_RETRY_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SOURCE_CONNECT_RETRY", "", ""));
        $$ = res;
    }

    | SOURCE_DELAY_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SOURCE_DELAY", "", ""));
        $$ = res;
    }

    | SOURCE_HEARTBEAT_PERIOD_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SOURCE_HEARTBEAT_PERIOD", "", ""));
        $$ = res;
    }

    | SOURCE_HOST_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SOURCE_HOST", "", ""));
        $$ = res;
    }

    | SOURCE_LOG_FILE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SOURCE_LOG_FILE", "", ""));
        $$ = res;
    }

    | SOURCE_LOG_POS_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SOURCE_LOG_POS", "", ""));
        $$ = res;
    }

    | SOURCE_PASSWORD_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SOURCE_PASSWORD", "", ""));
        $$ = res;
    }

    | SOURCE_PORT_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SOURCE_PORT", "", ""));
        $$ = res;
    }

    | SOURCE_PUBLIC_KEY_PATH_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SOURCE_PUBLIC_KEY_PATH", "", ""));
        $$ = res;
    }

    | SOURCE_RETRY_COUNT_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SOURCE_RETRY_COUNT", "", ""));
        $$ = res;
    }

    | SOURCE_SSL_CAPATH_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SOURCE_SSL_CAPATH", "", ""));
        $$ = res;
    }

    | SOURCE_SSL_CA_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SOURCE_SSL_CA", "", ""));
        $$ = res;
    }

    | SOURCE_SSL_CERT_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SOURCE_SSL_CERT", "", ""));
        $$ = res;
    }

    | SOURCE_SSL_CIPHER_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SOURCE_SSL_CIPHER", "", ""));
        $$ = res;
    }

    | SOURCE_SSL_CRLPATH_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SOURCE_SSL_CRLPATH", "", ""));
        $$ = res;
    }

    | SOURCE_SSL_CRL_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SOURCE_SSL_CRL", "", ""));
        $$ = res;
    }

    | SOURCE_SSL_KEY_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SOURCE_SSL_KEY", "", ""));
        $$ = res;
    }

    | SOURCE_SSL_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SOURCE_SSL", "", ""));
        $$ = res;
    }

    | SOURCE_SSL_VERIFY_SERVER_CERT_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SOURCE_SSL_VERIFY_SERVER_CERT", "", ""));
        $$ = res;
    }

    | SOURCE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SOURCE", "", ""));
        $$ = res;
    }

    | SOURCE_TLS_CIPHERSUITES_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SOURCE_TLS_CIPHERSUITES", "", ""));
        $$ = res;
    }

    | SOURCE_TLS_VERSION_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SOURCE_TLS_VERSION", "", ""));
        $$ = res;
    }

    | SOURCE_USER_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SOURCE_USER", "", ""));
        $$ = res;
    }

    | SOURCE_ZSTD_COMPRESSION_LEVEL_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SOURCE_ZSTD_COMPRESSION_LEVEL", "", ""));
        $$ = res;
    }

    | SQL_AFTER_GTIDS {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SQL_AFTER_GTIDS", "", ""));
        $$ = res;
    }

    | SQL_AFTER_MTS_GAPS {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SQL_AFTER_MTS_GAPS", "", ""));
        $$ = res;
    }

    | SQL_BEFORE_GTIDS {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SQL_BEFORE_GTIDS", "", ""));
        $$ = res;
    }

    | SQL_BUFFER_RESULT {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SQL_BUFFER_RESULT", "", ""));
        $$ = res;
    }

    | SQL_NO_CACHE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SQL_NO_CACHE", "", ""));
        $$ = res;
    }

    | SQL_THREAD {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SQL_THREAD", "", ""));
        $$ = res;
    }

    | SRID_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SRID", "", ""));
        $$ = res;
    }

    | STACKED_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("STACKED", "", ""));
        $$ = res;
    }

    | STARTS_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("STARTS", "", ""));
        $$ = res;
    }

    | STATS_AUTO_RECALC_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("STATS_AUTO_RECALC", "", ""));
        $$ = res;
    }

    | STATS_PERSISTENT_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("STATS_PERSISTENT", "", ""));
        $$ = res;
    }

    | STATS_SAMPLE_PAGES_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("STATS_SAMPLE_PAGES", "", ""));
        $$ = res;
    }

    | STATUS_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("STATUS", "", ""));
        $$ = res;
    }

    | STORAGE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("STORAGE", "", ""));
        $$ = res;
    }

    | STREAM_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("STREAM", "", ""));
        $$ = res;
    }

    | STRING_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("STRING", "", ""));
        $$ = res;
    }

    | ST_COLLECT_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("ST_COLLECT", "", ""));
        $$ = res;
    }

    | SUBCLASS_ORIGIN_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SUBCLASS_ORIGIN", "", ""));
        $$ = res;
    }

    | SUBDATE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SUBDATE", "", ""));
        $$ = res;
    }

    | SUBJECT_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SUBJECT", "", ""));
        $$ = res;
    }

    | SUBPARTITIONS_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SUBPARTITIONS", "", ""));
        $$ = res;
    }

    | SUBPARTITION_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SUBPARTITION", "", ""));
        $$ = res;
    }

    | SUSPEND_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SUSPEND", "", ""));
        $$ = res;
    }

    | SWAPS_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SWAPS", "", ""));
        $$ = res;
    }

    | SWITCHES_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SWITCHES", "", ""));
        $$ = res;
    }

    | TABLES {
        res = new IR(kIdentKeywordsUnambiguous, OP3("TABLES", "", ""));
        $$ = res;
    }

    | TABLESPACE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("TABLESPACE", "", ""));
        $$ = res;
    }

    | TABLE_CHECKSUM_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("TABLE_CHECKSUM", "", ""));
        $$ = res;
    }

    | TABLE_NAME_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("TABLE_NAME", "", ""));
        $$ = res;
    }

    | TEMPORARY {
        res = new IR(kIdentKeywordsUnambiguous, OP3("TEMPORARY", "", ""));
        $$ = res;
    }

    | TEMPTABLE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("TEMPTABLE", "", ""));
        $$ = res;
    }

    | TEXT_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("TEXT", "", ""));
        $$ = res;
    }

    | THAN_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("THAN", "", ""));
        $$ = res;
    }

    | THREAD_PRIORITY_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("THREAD_PRIORITY", "", ""));
        $$ = res;
    }

    | TIES_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("TIES", "", ""));
        $$ = res;
    }

    | TIMESTAMP_ADD {
        res = new IR(kIdentKeywordsUnambiguous, OP3("TIMESTAMPADD", "", ""));
        $$ = res;
    }

    | TIMESTAMP_DIFF {
        res = new IR(kIdentKeywordsUnambiguous, OP3("TIMESTAMPDIFF", "", ""));
        $$ = res;
    }

    | TIMESTAMP_SYM %prec KEYWORD_USED_AS_IDENT {
        res = new IR(kIdentKeywordsUnambiguous, OP3("TIMESTAMP", "", ""));
        $$ = res;
    }

    | TIME_SYM %prec KEYWORD_USED_AS_IDENT {
        res = new IR(kIdentKeywordsUnambiguous, OP3("TIME", "", ""));
        $$ = res;
    }

    | TLS_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("TLS", "", ""));
        $$ = res;
    }

    | TRANSACTION_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("TRANSACTION", "", ""));
        $$ = res;
    }

    | TRIGGERS_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("TRIGGERS", "", ""));
        $$ = res;
    }

    | TYPES_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("TYPES", "", ""));
        $$ = res;
    }

    | TYPE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("TYPE", "", ""));
        $$ = res;
    }

    | UNBOUNDED_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("UNBOUNDED", "", ""));
        $$ = res;
    }

    | UNCOMMITTED_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("UNCOMMITTED", "", ""));
        $$ = res;
    }

    | UNDEFINED_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("UNDEFINED", "", ""));
        $$ = res;
    }

    | UNDOFILE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("UNDOFILE", "", ""));
        $$ = res;
    }

    | UNDO_BUFFER_SIZE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("UNDO_BUFFER_SIZE", "", ""));
        $$ = res;
    }

    | UNKNOWN_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("UNKNOWN", "", ""));
        $$ = res;
    }

    | UNREGISTER_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("UNREGISTER", "", ""));
        $$ = res;
    }

    | UNTIL_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("UNTIL", "", ""));
        $$ = res;
    }

    | UPGRADE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("UPGRADE", "", ""));
        $$ = res;
    }

    | USER {
        res = new IR(kIdentKeywordsUnambiguous, OP3("USER", "", ""));
        $$ = res;
    }

    | USE_FRM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("USE_FRM", "", ""));
        $$ = res;
    }

    | VALIDATION_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("VALIDATION", "", ""));
        $$ = res;
    }

    | VALUE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("VALUE", "", ""));
        $$ = res;
    }

    | VARIABLES {
        res = new IR(kIdentKeywordsUnambiguous, OP3("VARIABLES", "", ""));
        $$ = res;
    }

    | VCPU_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("VCPU", "", ""));
        $$ = res;
    }

    | VIEW_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("VIEW", "", ""));
        $$ = res;
    }

    | VISIBLE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("VISIBLE", "", ""));
        $$ = res;
    }

    | WAIT_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("WAIT", "", ""));
        $$ = res;
    }

    | WARNINGS {
        res = new IR(kIdentKeywordsUnambiguous, OP3("WARNINGS", "", ""));
        $$ = res;
    }

    | WEEK_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SQL_TSI_WEEK", "", ""));
        $$ = res;
    }

    | WEIGHT_STRING_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("WEIGHT_STRING", "", ""));
        $$ = res;
    }

    | WITHOUT_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("WITHOUT", "", ""));
        $$ = res;
    }

    | WORK_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("WORK", "", ""));
        $$ = res;
    }

    | WRAPPER_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("WRAPPER", "", ""));
        $$ = res;
    }

    | X509_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("X509", "", ""));
        $$ = res;
    }

    | XID_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("XID", "", ""));
        $$ = res;
    }

    | XML_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("XML", "", ""));
        $$ = res;
    }

    | YEAR_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("SQL_TSI_YEAR", "", ""));
        $$ = res;
    }

    | ZONE_SYM {
        res = new IR(kIdentKeywordsUnambiguous, OP3("ZONE", "", ""));
        $$ = res;
    }

;

/*
Non-reserved keywords that we allow for unquoted role names:

Not allowed:

ident_keywords_ambiguous_1_roles_and_labels
ident_keywords_ambiguous_3_roles
*/

role_keyword:

    ident_keywords_unambiguous {
        auto tmp1 = $1;
        res = new IR(kRoleKeyword, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ident_keywords_ambiguous_2_labels {
        auto tmp1 = $1;
        res = new IR(kRoleKeyword, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ident_keywords_ambiguous_4_system_variables {
        auto tmp1 = $1;
        res = new IR(kRoleKeyword, OP3("", "", ""), tmp1);
        $$ = res;
    }

;

/*
Non-reserved words allowed for unquoted unprefixed variable names and
unquoted variable prefixes in the left side of assignments in SET statements:

Not allowed:

ident_keywords_ambiguous_4_system_variables
*/

lvalue_keyword:

    ident_keywords_unambiguous {
        auto tmp1 = $1;
        res = new IR(kLvalueKeyword, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ident_keywords_ambiguous_1_roles_and_labels {
        auto tmp1 = $1;
        res = new IR(kLvalueKeyword, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ident_keywords_ambiguous_2_labels {
        auto tmp1 = $1;
        res = new IR(kLvalueKeyword, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ident_keywords_ambiguous_3_roles {
        auto tmp1 = $1;
        res = new IR(kLvalueKeyword, OP3("", "", ""), tmp1);
        $$ = res;
    }

;

/*
These non-reserved keywords cannot be used as unquoted unprefixed
variable names and unquoted variable prefixes in the left side of
assignments in SET statements:
*/

ident_keywords_ambiguous_4_system_variables:

    GLOBAL_SYM {
        res = new IR(kIdentKeywordsAmbiguous4SystemVariables, OP3("GLOBAL", "", ""));
        $$ = res;
    }

    | LOCAL_SYM {
        res = new IR(kIdentKeywordsAmbiguous4SystemVariables, OP3("LOCAL", "", ""));
        $$ = res;
    }

    | PERSIST_SYM {
        res = new IR(kIdentKeywordsAmbiguous4SystemVariables, OP3("PERSIST", "", ""));
        $$ = res;
    }

    | PERSIST_ONLY_SYM {
        res = new IR(kIdentKeywordsAmbiguous4SystemVariables, OP3("PERSIST_ONLY", "", ""));
        $$ = res;
    }

    | SESSION_SYM {
        res = new IR(kIdentKeywordsAmbiguous4SystemVariables, OP3("SESSION", "", ""));
        $$ = res;
    }

;

/*
SQLCOM_SET_OPTION statement.

Note that to avoid shift/reduce conflicts, we have separate rules for the
first option listed in the statement.
*/


set:

    SET_SYM start_option_value_list {
        auto tmp1 = $2;
        res = new IR(kSet, OP3("SET", "", ""), tmp1);
        $$ = res;
    }

;


// Start of option value list

start_option_value_list:

    option_value_no_option_type option_value_list_continued {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kStartOptionValueList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | TRANSACTION_SYM transaction_characteristics {
        auto tmp1 = $2;
        res = new IR(kStartOptionValueList, OP3("TRANSACTION", "", ""), tmp1);
        $$ = res;
    }

    | option_type start_option_value_list_following_option_type {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kStartOptionValueList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | PASSWORD equal TEXT_STRING_password opt_replace_password opt_retain_current_password {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kStartOptionValueList_1, OP3("PASSWORD", "", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kStartOptionValueList_2, OP3("", "", ""), res, tmp3);

        auto tmp4 = $5;
        res = new IR(kStartOptionValueList, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | PASSWORD TO_SYM RANDOM_SYM opt_replace_password opt_retain_current_password {
        auto tmp1 = $4;
        auto tmp2 = $5;
        res = new IR(kStartOptionValueList, OP3("PASSWORD TO RANDOM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | PASSWORD FOR_SYM user equal TEXT_STRING_password opt_replace_password opt_retain_current_password {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kStartOptionValueList_3, OP3("PASSWORD FOR", "", ""), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kStartOptionValueList_4, OP3("", "", ""), res, tmp3);

        auto tmp4 = $6;
        res = new IR(kStartOptionValueList_5, OP3("", "", ""), res, tmp4);

        auto tmp5 = $7;
        res = new IR(kStartOptionValueList, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

    | PASSWORD FOR_SYM user TO_SYM RANDOM_SYM opt_replace_password opt_retain_current_password {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kStartOptionValueList_6, OP3("PASSWORD FOR", "TO RANDOM", ""), tmp1, tmp2);

        auto tmp3 = $7;
        res = new IR(kStartOptionValueList, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


set_role_stmt:

    SET_SYM ROLE_SYM role_list {
        auto tmp1 = $3;
        res = new IR(kSetRoleStmt, OP3("SET ROLE", "", ""), tmp1);
        $$ = res;
    }

    | SET_SYM ROLE_SYM NONE_SYM {
        res = new IR(kSetRoleStmt, OP3("SET ROLE NONE", "", ""));
        $$ = res;
    }

    | SET_SYM ROLE_SYM DEFAULT_SYM {
        res = new IR(kSetRoleStmt, OP3("SET ROLE DEFAULT", "", ""));
        $$ = res;
    }

    | SET_SYM DEFAULT_SYM ROLE_SYM role_list TO_SYM role_list {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kSetRoleStmt, OP3("SET DEFAULT ROLE", "TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | SET_SYM DEFAULT_SYM ROLE_SYM NONE_SYM TO_SYM role_list {
        auto tmp1 = $6;
        res = new IR(kSetRoleStmt, OP3("SET DEFAULT ROLE NONE TO", "", ""), tmp1);
        $$ = res;
    }

    | SET_SYM DEFAULT_SYM ROLE_SYM ALL TO_SYM role_list {
        auto tmp1 = $6;
        res = new IR(kSetRoleStmt, OP3("SET DEFAULT ROLE ALL TO", "", ""), tmp1);
        $$ = res;
    }

    | SET_SYM ROLE_SYM ALL opt_except_role_list {
        auto tmp1 = $4;
        res = new IR(kSetRoleStmt, OP3("SET ROLE ALL", "", ""), tmp1);
        $$ = res;
    }

;


opt_except_role_list:

    /* empty */ {
        res = new IR(kOptExceptRoleList, OP3("", "", ""));
        $$ = res;
    }

    | EXCEPT_SYM role_list {
        auto tmp1 = $2;
        res = new IR(kOptExceptRoleList, OP3("EXCEPT", "", ""), tmp1);
        $$ = res;
    }

;


set_resource_group_stmt:

    SET_SYM RESOURCE_SYM GROUP_SYM ident {
        auto tmp1 = $4;
        res = new IR(kSetResourceGroupStmt, OP3("SET RESOURCE GROUP", "", ""), tmp1);
        $$ = res;
    }

    | SET_SYM RESOURCE_SYM GROUP_SYM ident FOR_SYM thread_id_list_options {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kSetResourceGroupStmt, OP3("SET RESOURCE GROUP", "FOR", ""), tmp1, tmp2);
        $$ = res;
    }

;


thread_id_list:

    real_ulong_num {
        auto tmp1 = $1;
        res = new IR(kThreadIdList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | thread_id_list opt_comma real_ulong_num {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kThreadIdList_1, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kThreadIdList, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


thread_id_list_options:

    thread_id_list {
        auto tmp1 = $1;
        res = new IR(kThreadIdListOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

;

// Start of option value list, option_type was given

start_option_value_list_following_option_type:

    option_value_following_option_type option_value_list_continued {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kStartOptionValueListFollowingOptionType, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | TRANSACTION_SYM transaction_characteristics {
        auto tmp1 = $2;
        res = new IR(kStartOptionValueListFollowingOptionType, OP3("TRANSACTION", "", ""), tmp1);
        $$ = res;
    }

;

// Remainder of the option value list after first option value.

option_value_list_continued:

    /* empty */ {
        res = new IR(kOptionValueListContinued, OP3("", "", ""));
        $$ = res;
    }

    | ',' option_value_list {
        auto tmp1 = $2;
        res = new IR(kOptionValueListContinued, OP3(",", "", ""), tmp1);
        $$ = res;
    }

;

// Repeating list of option values after first option value.

option_value_list:

    option_value {
        auto tmp1 = $1;
        res = new IR(kOptionValueList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | option_value_list ',' option_value {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kOptionValueList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;

// Wrapper around option values following the first option value in the stmt.

option_value:

    option_type option_value_following_option_type {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptionValue, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | option_value_no_option_type {
        auto tmp1 = $1;
        res = new IR(kOptionValue, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


option_type:

    GLOBAL_SYM {
        res = new IR(kOptionType, OP3("GLOBAL", "", ""));
        $$ = res;
    }

    | PERSIST_SYM {
        res = new IR(kOptionType, OP3("PERSIST", "", ""));
        $$ = res;
    }

    | PERSIST_ONLY_SYM {
        res = new IR(kOptionType, OP3("PERSIST_ONLY", "", ""));
        $$ = res;
    }

    | LOCAL_SYM {
        res = new IR(kOptionType, OP3("LOCAL", "", ""));
        $$ = res;
    }

    | SESSION_SYM {
        res = new IR(kOptionType, OP3("SESSION", "", ""));
        $$ = res;
    }

;


opt_var_type:

    /* empty */ {
        res = new IR(kOptVarType, OP3("", "", ""));
        $$ = res;
    }

    | GLOBAL_SYM {
        res = new IR(kOptVarType, OP3("GLOBAL", "", ""));
        $$ = res;
    }

    | LOCAL_SYM {
        res = new IR(kOptVarType, OP3("LOCAL", "", ""));
        $$ = res;
    }

    | SESSION_SYM {
        res = new IR(kOptVarType, OP3("SESSION", "", ""));
        $$ = res;
    }

;


opt_var_ident_type:

    /* empty */ {
        res = new IR(kOptVarIdentType, OP3("", "", ""));
        $$ = res;
    }

    | GLOBAL_SYM '.' {
        res = new IR(kOptVarIdentType, OP3("GLOBAL .", "", ""));
        $$ = res;
    }

    | LOCAL_SYM '.' {
        res = new IR(kOptVarIdentType, OP3("LOCAL .", "", ""));
        $$ = res;
    }

    | SESSION_SYM '.' {
        res = new IR(kOptVarIdentType, OP3("SESSION .", "", ""));
        $$ = res;
    }

;


opt_set_var_ident_type:

    /* empty */ {
        res = new IR(kOptSetVarIdentType, OP3("", "", ""));
        $$ = res;
    }

    | PERSIST_SYM '.' {
        res = new IR(kOptSetVarIdentType, OP3("PERSIST .", "", ""));
        $$ = res;
    }

    | PERSIST_ONLY_SYM '.' {
        res = new IR(kOptSetVarIdentType, OP3("PERSIST_ONLY .", "", ""));
        $$ = res;
    }

    | GLOBAL_SYM '.' {
        res = new IR(kOptSetVarIdentType, OP3("GLOBAL .", "", ""));
        $$ = res;
    }

    | LOCAL_SYM '.' {
        res = new IR(kOptSetVarIdentType, OP3("LOCAL .", "", ""));
        $$ = res;
    }

    | SESSION_SYM '.' {
        res = new IR(kOptSetVarIdentType, OP3("SESSION .", "", ""));
        $$ = res;
    }

;

// Option values with preceding option_type.

option_value_following_option_type:

    internal_variable_name equal set_expr_or_default {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptionValueFollowingOptionType_1, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kOptionValueFollowingOptionType, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;

// Option values without preceding option_type.

option_value_no_option_type:

    internal_variable_name equal set_expr_or_default {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptionValueNoOptionType_1, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kOptionValueNoOptionType, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | '@' ident_or_text equal expr {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kOptionValueNoOptionType_2, OP3("@", "", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kOptionValueNoOptionType, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | '@' '@' opt_set_var_ident_type internal_variable_name equal set_expr_or_default {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kOptionValueNoOptionType_3, OP3("@ @", "", ""), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kOptionValueNoOptionType_4, OP3("", "", ""), res, tmp3);

        auto tmp4 = $6;
        res = new IR(kOptionValueNoOptionType, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | character_set old_or_new_charset_name_or_default {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptionValueNoOptionType, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | NAMES_SYM equal expr {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kOptionValueNoOptionType, OP3("NAMES", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | NAMES_SYM charset_name opt_collate {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kOptionValueNoOptionType, OP3("NAMES", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | NAMES_SYM DEFAULT_SYM {
        res = new IR(kOptionValueNoOptionType, OP3("NAMES DEFAULT", "", ""));
        $$ = res;
    }

;


internal_variable_name:

    lvalue_ident {
        auto tmp1 = $1;
        res = new IR(kInternalVariableName, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | lvalue_ident '.' ident {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kInternalVariableName, OP3("", ".", ""), tmp1, tmp2);
        $$ = res;
    }

    | DEFAULT_SYM '.' ident {
        auto tmp1 = $3;
        res = new IR(kInternalVariableName, OP3("DEFAULT .", "", ""), tmp1);
        $$ = res;
    }

;


transaction_characteristics:

    transaction_access_mode opt_isolation_level {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kTransactionCharacteristics, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | isolation_level opt_transaction_access_mode {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kTransactionCharacteristics, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


transaction_access_mode:

    transaction_access_mode_types {
        auto tmp1 = $1;
        res = new IR(kTransactionAccessMode, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_transaction_access_mode:

    /* empty */ {
        res = new IR(kOptTransactionAccessMode, OP3("", "", ""));
        $$ = res;
    }

    | ',' transaction_access_mode {
        auto tmp1 = $2;
        res = new IR(kOptTransactionAccessMode, OP3(",", "", ""), tmp1);
        $$ = res;
    }

;


isolation_level:

    ISOLATION LEVEL_SYM isolation_types {
        auto tmp1 = $3;
        res = new IR(kIsolationLevel, OP3("ISOLATION LEVEL", "", ""), tmp1);
        $$ = res;
    }

;


opt_isolation_level:

    /* empty */ {
        res = new IR(kOptIsolationLevel, OP3("", "", ""));
        $$ = res;
    }

    | ',' isolation_level {
        auto tmp1 = $2;
        res = new IR(kOptIsolationLevel, OP3(",", "", ""), tmp1);
        $$ = res;
    }

;


transaction_access_mode_types:

    READ_SYM ONLY_SYM {
        res = new IR(kTransactionAccessModeTypes, OP3("READ ONLY", "", ""));
        $$ = res;
    }

    | READ_SYM WRITE_SYM {
        res = new IR(kTransactionAccessModeTypes, OP3("READ WRITE", "", ""));
        $$ = res;
    }

;


isolation_types:

    READ_SYM UNCOMMITTED_SYM {
        res = new IR(kIsolationTypes, OP3("READ UNCOMMITTED", "", ""));
        $$ = res;
    }

    | READ_SYM COMMITTED_SYM {
        res = new IR(kIsolationTypes, OP3("READ COMMITTED", "", ""));
        $$ = res;
    }

    | REPEATABLE_SYM READ_SYM {
        res = new IR(kIsolationTypes, OP3("REPEATABLE READ", "", ""));
        $$ = res;
    }

    | SERIALIZABLE_SYM {
        res = new IR(kIsolationTypes, OP3("SERIALIZABLE", "", ""));
        $$ = res;
    }

;


set_expr_or_default:

    expr {
        auto tmp1 = $1;
        res = new IR(kSetExprOrDefault, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DEFAULT_SYM {
        res = new IR(kSetExprOrDefault, OP3("DEFAULT", "", ""));
        $$ = res;
    }

    | ON_SYM {
        res = new IR(kSetExprOrDefault, OP3("ON", "", ""));
        $$ = res;
    }

    | ALL {
        res = new IR(kSetExprOrDefault, OP3("ALL", "", ""));
        $$ = res;
    }

    | BINARY_SYM {
        res = new IR(kSetExprOrDefault, OP3("BINARY", "", ""));
        $$ = res;
    }

    | ROW_SYM {
        res = new IR(kSetExprOrDefault, OP3("ROW", "", ""));
        $$ = res;
    }

    | SYSTEM_SYM {
        res = new IR(kSetExprOrDefault, OP3("SYSTEM", "", ""));
        $$ = res;
    }

;

/* Lock function */


lock:

    LOCK_SYM table_or_tables {} table_lock_list {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kLock, OP3("LOCK", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | LOCK_SYM INSTANCE_SYM FOR_SYM BACKUP_SYM {
        res = new IR(kLock, OP3("LOCK INSTANCE FOR BACKUP", "", ""));
        $$ = res;
    }

;


table_or_tables:

    TABLE_SYM {
        res = new IR(kTableOrTables, OP3("TABLE", "", ""));
        $$ = res;
    }

    | TABLES {
        res = new IR(kTableOrTables, OP3("TABLES", "", ""));
        $$ = res;
    }

;


table_lock_list:

    table_lock {
        auto tmp1 = $1;
        res = new IR(kTableLockList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | table_lock_list ',' table_lock {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTableLockList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


table_lock:

    table_ident opt_table_alias lock_option {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kTableLock_1, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kTableLock, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


lock_option:

    READ_SYM {
        res = new IR(kLockOption, OP3("READ", "", ""));
        $$ = res;
    }

    | WRITE_SYM {
        res = new IR(kLockOption, OP3("WRITE", "", ""));
        $$ = res;
    }

    | LOW_PRIORITY WRITE_SYM {
        res = new IR(kLockOption, OP3("LOW_PRIORITY WRITE", "", ""));
        $$ = res;
    }

    | READ_SYM LOCAL_SYM {
        res = new IR(kLockOption, OP3("READ LOCAL", "", ""));
        $$ = res;
    }

;


unlock:

    UNLOCK_SYM {} table_or_tables {
        auto tmp1 = $3;
        res = new IR(kUnlock, OP3("UNLOCK", "", ""), tmp1);
        $$ = res;
    }

    | UNLOCK_SYM INSTANCE_SYM {
        res = new IR(kUnlock, OP3("UNLOCK INSTANCE", "", ""));
        $$ = res;
    }

;



shutdown_stmt:

    SHUTDOWN {
        res = new IR(kShutdownStmt, OP3("SHUTDOWN", "", ""));
        $$ = res;
    }

;


restart_server_stmt:

    RESTART_SYM {
        res = new IR(kRestartServerStmt, OP3("RESTART", "", ""));
        $$ = res;
    }

;


alter_instance_stmt:

    ALTER INSTANCE_SYM alter_instance_action {
        auto tmp1 = $3;
        res = new IR(kAlterInstanceStmt, OP3("ALTER INSTANCE", "", ""), tmp1);
        $$ = res;
    }

;


alter_instance_action:

    ROTATE_SYM ident_or_text MASTER_SYM KEY_SYM {
        auto tmp1 = $2;
        res = new IR(kAlterInstanceAction, OP3("ROTATE", "MASTER KEY", ""), tmp1);
        $$ = res;
    }

    | RELOAD TLS_SYM {
        res = new IR(kAlterInstanceAction, OP3("RELOAD TLS", "", ""));
        $$ = res;
    }

    | RELOAD TLS_SYM NO_SYM ROLLBACK_SYM ON_SYM ERROR_SYM {
        res = new IR(kAlterInstanceAction, OP3("RELOAD TLS NO ROLLBACK ON ERROR", "", ""));
        $$ = res;
    }

    | RELOAD TLS_SYM FOR_SYM CHANNEL_SYM ident {
        auto tmp1 = $5;
        res = new IR(kAlterInstanceAction, OP3("RELOAD TLS FOR CHANNEL", "", ""), tmp1);
        $$ = res;
    }

    | RELOAD TLS_SYM FOR_SYM CHANNEL_SYM ident NO_SYM ROLLBACK_SYM ON_SYM ERROR_SYM {
        auto tmp1 = $5;
        res = new IR(kAlterInstanceAction, OP3("RELOAD TLS FOR CHANNEL", "NO ROLLBACK ON ERROR", ""), tmp1);
        $$ = res;
    }

    | ENABLE_SYM ident ident {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterInstanceAction, OP3("ENABLE", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | DISABLE_SYM ident ident {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterInstanceAction, OP3("DISABLE", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | RELOAD KEYRING_SYM {
        res = new IR(kAlterInstanceAction, OP3("RELOAD KEYRING", "", ""));
        $$ = res;
    }

;

/*
** Handler: direct access to ISAM functions
*/


handler_stmt:

    HANDLER_SYM table_ident OPEN_SYM opt_table_alias {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kHandlerStmt, OP3("HANDLER", "OPEN", ""), tmp1, tmp2);
        $$ = res;
    }

    | HANDLER_SYM ident CLOSE_SYM {
        auto tmp1 = $2;
        res = new IR(kHandlerStmt, OP3("HANDLER", "CLOSE", ""), tmp1);
        $$ = res;
    }

    | HANDLER_SYM ident READ_SYM handler_scan_function opt_where_clause opt_limit_clause {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kHandlerStmt_1, OP3("HANDLER", "READ", ""), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kHandlerStmt_2, OP3("", "", ""), res, tmp3);

        auto tmp4 = $6;
        res = new IR(kHandlerStmt, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | HANDLER_SYM ident READ_SYM ident handler_rkey_function opt_where_clause opt_limit_clause {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kHandlerStmt_3, OP3("HANDLER", "READ", ""), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kHandlerStmt_4, OP3("", "", ""), res, tmp3);

        auto tmp4 = $6;
        res = new IR(kHandlerStmt_5, OP3("", "", ""), res, tmp4);

        auto tmp5 = $7;
        res = new IR(kHandlerStmt, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

    | HANDLER_SYM ident READ_SYM ident handler_rkey_mode '(' values ')' opt_where_clause opt_limit_clause {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kHandlerStmt_6, OP3("HANDLER", "READ", ""), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kHandlerStmt_7, OP3("", "", "("), res, tmp3);

        auto tmp4 = $7;
        res = new IR(kHandlerStmt_8, OP3("", "", ")"), res, tmp4);

        auto tmp5 = $9;
        res = new IR(kHandlerStmt_9, OP3("", "", ""), res, tmp5);

        auto tmp6 = $10;
        res = new IR(kHandlerStmt, OP3("", "", ""), res, tmp6);
        $$ = res;
    }

;


handler_scan_function:

    FIRST_SYM {
        res = new IR(kHandlerScanFunction, OP3("FIRST", "", ""));
        $$ = res;
    }

    | NEXT_SYM {
        res = new IR(kHandlerScanFunction, OP3("NEXT", "", ""));
        $$ = res;
    }

;


handler_rkey_function:

    FIRST_SYM {
        res = new IR(kHandlerRkeyFunction, OP3("FIRST", "", ""));
        $$ = res;
    }

    | NEXT_SYM {
        res = new IR(kHandlerRkeyFunction, OP3("NEXT", "", ""));
        $$ = res;
    }

    | PREV_SYM {
        res = new IR(kHandlerRkeyFunction, OP3("PREV", "", ""));
        $$ = res;
    }

    | LAST_SYM {
        res = new IR(kHandlerRkeyFunction, OP3("LAST", "", ""));
        $$ = res;
    }

;


handler_rkey_mode:

    EQ {
        res = new IR(kHandlerRkeyMode, OP3("=", "", ""));
        $$ = res;
    }

    | GE {
        res = new IR(kHandlerRkeyMode, OP3(">=", "", ""));
        $$ = res;
    }

    | LE {
        res = new IR(kHandlerRkeyMode, OP3("<=", "", ""));
        $$ = res;
    }

    | GT_SYM {
        res = new IR(kHandlerRkeyMode, OP3(">", "", ""));
        $$ = res;
    }

    | LT {
        res = new IR(kHandlerRkeyMode, OP3("<", "", ""));
        $$ = res;
    }

;

/* GRANT / REVOKE */


revoke:

    REVOKE role_or_privilege_list FROM user_list {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kRevoke, OP3("REVOKE", "FROM", ""), tmp1, tmp2);
        $$ = res;
    }

    | REVOKE role_or_privilege_list ON_SYM opt_acl_type grant_ident FROM user_list {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kRevoke_1, OP3("REVOKE", "ON", ""), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kRevoke_2, OP3("", "", "FROM"), res, tmp3);

        auto tmp4 = $7;
        res = new IR(kRevoke, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | REVOKE ALL opt_privileges {} ON_SYM opt_acl_type grant_ident FROM user_list {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kRevoke_3, OP3("REVOKE ALL", "ON", ""), tmp1, tmp2);

        auto tmp3 = $7;
        res = new IR(kRevoke_4, OP3("", "", "FROM"), res, tmp3);

        auto tmp4 = $9;
        res = new IR(kRevoke, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | REVOKE ALL opt_privileges ',' GRANT OPTION FROM user_list {
        auto tmp1 = $3;
        auto tmp2 = $8;
        res = new IR(kRevoke, OP3("REVOKE ALL", ", GRANT OPTION FROM", ""), tmp1, tmp2);
        $$ = res;
    }

    | REVOKE PROXY_SYM ON_SYM user FROM user_list {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kRevoke, OP3("REVOKE PROXY ON", "FROM", ""), tmp1, tmp2);
        $$ = res;
    }

;


grant:

    GRANT role_or_privilege_list TO_SYM user_list opt_with_admin_option {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kGrant_1, OP3("GRANT", "TO", ""), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kGrant, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | GRANT role_or_privilege_list ON_SYM opt_acl_type grant_ident TO_SYM user_list grant_options opt_grant_as {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kGrant_2, OP3("GRANT", "ON", ""), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kGrant_3, OP3("", "", "TO"), res, tmp3);

        auto tmp4 = $7;
        res = new IR(kGrant_4, OP3("", "", ""), res, tmp4);

        auto tmp5 = $8;
        res = new IR(kGrant_5, OP3("", "", ""), res, tmp5);

        auto tmp6 = $9;
        res = new IR(kGrant, OP3("", "", ""), res, tmp6);
        $$ = res;
    }

    | GRANT ALL opt_privileges {} ON_SYM opt_acl_type grant_ident TO_SYM user_list grant_options opt_grant_as {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kGrant_6, OP3("GRANT ALL", "ON", ""), tmp1, tmp2);

        auto tmp3 = $7;
        res = new IR(kGrant_7, OP3("", "", "TO"), res, tmp3);

        auto tmp4 = $9;
        res = new IR(kGrant_8, OP3("", "", ""), res, tmp4);

        auto tmp5 = $10;
        res = new IR(kGrant_9, OP3("", "", ""), res, tmp5);

        auto tmp6 = $11;
        res = new IR(kGrant, OP3("", "", ""), res, tmp6);
        $$ = res;
    }

    | GRANT PROXY_SYM ON_SYM user TO_SYM user_list opt_grant_option {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kGrant_10, OP3("GRANT PROXY ON", "TO", ""), tmp1, tmp2);

        auto tmp3 = $7;
        res = new IR(kGrant, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


opt_acl_type:

    /* Empty */ {
        res = new IR(kOptAclType, OP3("", "", ""));
        $$ = res;
    }

    | TABLE_SYM {
        res = new IR(kOptAclType, OP3("TABLE", "", ""));
        $$ = res;
    }

    | FUNCTION_SYM {
        res = new IR(kOptAclType, OP3("FUNCTION", "", ""));
        $$ = res;
    }

    | PROCEDURE_SYM {
        res = new IR(kOptAclType, OP3("PROCEDURE", "", ""));
        $$ = res;
    }

;


opt_privileges:

    /* empty */ {
        res = new IR(kOptPrivileges, OP3("", "", ""));
        $$ = res;
    }

    | PRIVILEGES {
        res = new IR(kOptPrivileges, OP3("PRIVILEGES", "", ""));
        $$ = res;
    }

;


role_or_privilege_list:

    role_or_privilege {
        auto tmp1 = $1;
        res = new IR(kRoleOrPrivilegeList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | role_or_privilege_list ',' role_or_privilege {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kRoleOrPrivilegeList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


role_or_privilege:

    role_ident_or_text opt_column_list {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kRoleOrPrivilege, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | role_ident_or_text '@' ident_or_text {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kRoleOrPrivilege, OP3("", "@", ""), tmp1, tmp2);
        $$ = res;
    }

    | SELECT_SYM opt_column_list {
        auto tmp1 = $2;
        res = new IR(kRoleOrPrivilege, OP3("SELECT", "", ""), tmp1);
        $$ = res;
    }

    | INSERT_SYM opt_column_list {
        auto tmp1 = $2;
        res = new IR(kRoleOrPrivilege, OP3("INSERT", "", ""), tmp1);
        $$ = res;
    }

    | UPDATE_SYM opt_column_list {
        auto tmp1 = $2;
        res = new IR(kRoleOrPrivilege, OP3("UPDATE", "", ""), tmp1);
        $$ = res;
    }

    | REFERENCES opt_column_list {
        auto tmp1 = $2;
        res = new IR(kRoleOrPrivilege, OP3("REFERENCES", "", ""), tmp1);
        $$ = res;
    }

    | DELETE_SYM {
        res = new IR(kRoleOrPrivilege, OP3("DELETE", "", ""));
        $$ = res;
    }

    | USAGE {
        res = new IR(kRoleOrPrivilege, OP3("USAGE", "", ""));
        $$ = res;
    }

    | INDEX_SYM {
        res = new IR(kRoleOrPrivilege, OP3("INDEX", "", ""));
        $$ = res;
    }

    | ALTER {
        res = new IR(kRoleOrPrivilege, OP3("ALTER", "", ""));
        $$ = res;
    }

    | CREATE {
        res = new IR(kRoleOrPrivilege, OP3("CREATE", "", ""));
        $$ = res;
    }

    | DROP {
        res = new IR(kRoleOrPrivilege, OP3("DROP", "", ""));
        $$ = res;
    }

    | EXECUTE_SYM {
        res = new IR(kRoleOrPrivilege, OP3("EXECUTE", "", ""));
        $$ = res;
    }

    | RELOAD {
        res = new IR(kRoleOrPrivilege, OP3("RELOAD", "", ""));
        $$ = res;
    }

    | SHUTDOWN {
        res = new IR(kRoleOrPrivilege, OP3("SHUTDOWN", "", ""));
        $$ = res;
    }

    | PROCESS {
        res = new IR(kRoleOrPrivilege, OP3("PROCESS", "", ""));
        $$ = res;
    }

    | FILE_SYM {
        res = new IR(kRoleOrPrivilege, OP3("FILE", "", ""));
        $$ = res;
    }

    | GRANT OPTION {
        res = new IR(kRoleOrPrivilege, OP3("GRANT OPTION", "", ""));
        $$ = res;
    }

    | SHOW DATABASES {
        res = new IR(kRoleOrPrivilege, OP3("SHOW DATABASES", "", ""));
        $$ = res;
    }

    | SUPER_SYM {
        res = new IR(kRoleOrPrivilege, OP3("SUPER", "", ""));
        $$ = res;
    }

    | CREATE TEMPORARY TABLES {
        res = new IR(kRoleOrPrivilege, OP3("CREATE TEMPORARY TABLES", "", ""));
        $$ = res;
    }

    | LOCK_SYM TABLES {
        res = new IR(kRoleOrPrivilege, OP3("LOCK TABLES", "", ""));
        $$ = res;
    }

    | REPLICATION SLAVE {
        res = new IR(kRoleOrPrivilege, OP3("REPLICATION SLAVE", "", ""));
        $$ = res;
    }

    | REPLICATION CLIENT_SYM {
        res = new IR(kRoleOrPrivilege, OP3("REPLICATION CLIENT", "", ""));
        $$ = res;
    }

    | CREATE VIEW_SYM {
        res = new IR(kRoleOrPrivilege, OP3("CREATE VIEW", "", ""));
        $$ = res;
    }

    | SHOW VIEW_SYM {
        res = new IR(kRoleOrPrivilege, OP3("SHOW VIEW", "", ""));
        $$ = res;
    }

    | CREATE ROUTINE_SYM {
        res = new IR(kRoleOrPrivilege, OP3("CREATE ROUTINE", "", ""));
        $$ = res;
    }

    | ALTER ROUTINE_SYM {
        res = new IR(kRoleOrPrivilege, OP3("ALTER ROUTINE", "", ""));
        $$ = res;
    }

    | CREATE USER {
        res = new IR(kRoleOrPrivilege, OP3("CREATE USER", "", ""));
        $$ = res;
    }

    | EVENT_SYM {
        res = new IR(kRoleOrPrivilege, OP3("EVENT", "", ""));
        $$ = res;
    }

    | TRIGGER_SYM {
        res = new IR(kRoleOrPrivilege, OP3("TRIGGER", "", ""));
        $$ = res;
    }

    | CREATE TABLESPACE_SYM {
        res = new IR(kRoleOrPrivilege, OP3("CREATE TABLESPACE", "", ""));
        $$ = res;
    }

    | CREATE ROLE_SYM {
        res = new IR(kRoleOrPrivilege, OP3("CREATE ROLE", "", ""));
        $$ = res;
    }

    | DROP ROLE_SYM {
        res = new IR(kRoleOrPrivilege, OP3("DROP ROLE", "", ""));
        $$ = res;
    }

;


opt_with_admin_option:

    /* empty */ {
        res = new IR(kOptWithAdminOption, OP3("", "", ""));
        $$ = res;
    }

    | WITH ADMIN_SYM OPTION {
        res = new IR(kOptWithAdminOption, OP3("WITH ADMIN OPTION", "", ""));
        $$ = res;
    }

;


opt_and:

    /* empty */ {
        res = new IR(kOptAnd, OP3("", "", ""));
        $$ = res;
    }

    | AND_SYM {
        res = new IR(kOptAnd, OP3("AND", "", ""));
        $$ = res;
    }

;


require_list:

    require_list_element opt_and require_list {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kRequireList_1, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kRequireList, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | require_list_element {
        auto tmp1 = $1;
        res = new IR(kRequireList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


require_list_element:

    SUBJECT_SYM TEXT_STRING {
        res = new IR(kRequireListElement, OP3("SUBJECT TEXT_STRING", "", ""));
        $$ = res;
    }

    | ISSUER_SYM TEXT_STRING {
        res = new IR(kRequireListElement, OP3("ISSUER TEXT_STRING", "", ""));
        $$ = res;
    }

    | CIPHER_SYM TEXT_STRING {
        res = new IR(kRequireListElement, OP3("CIPHER TEXT_STRING", "", ""));
        $$ = res;
    }

;


grant_ident:

    '*' {
        res = new IR(kGrantIdent, OP3("*", "", ""));
        $$ = res;
    }

    | schema '.' '*' {
        auto tmp1 = $1;
        res = new IR(kGrantIdent, OP3("", ". *", ""), tmp1);
        $$ = res;
    }

    | '*' '.' '*' {
        res = new IR(kGrantIdent, OP3("* . *", "", ""));
        $$ = res;
    }

    | ident {
        auto tmp1 = $1;
        res = new IR(kGrantIdent, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | schema '.' ident {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kGrantIdent, OP3("", ".", ""), tmp1, tmp2);
        $$ = res;
    }

;


user_list:

    user {
        auto tmp1 = $1;
        res = new IR(kUserList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | user_list ',' user {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kUserList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


role_list:

    role {
        auto tmp1 = $1;
        res = new IR(kRoleList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | role_list ',' role {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kRoleList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_retain_current_password:

    /* empty */ {
        res = new IR(kOptRetainCurrentPassword, OP3("", "", ""));
        $$ = res;
    }

    | RETAIN_SYM CURRENT_SYM PASSWORD {
        res = new IR(kOptRetainCurrentPassword, OP3("RETAIN CURRENT PASSWORD", "", ""));
        $$ = res;
    }

;


opt_discard_old_password:

    /* empty */ {
        res = new IR(kOptDiscardOldPassword, OP3("", "", ""));
        $$ = res;
    }

    | DISCARD_SYM OLD_SYM PASSWORD {
        res = new IR(kOptDiscardOldPassword, OP3("DISCARD OLD PASSWORD", "", ""));
        $$ = res;
    }

;



opt_user_registration:

    factor INITIATE_SYM REGISTRATION_SYM {
        auto tmp1 = $1;
        res = new IR(kOptUserRegistration, OP3("", "INITIATE REGISTRATION", ""), tmp1);
        $$ = res;
    }

    | factor UNREGISTER_SYM {
        auto tmp1 = $1;
        res = new IR(kOptUserRegistration, OP3("", "UNREGISTER", ""), tmp1);
        $$ = res;
    }

    | factor FINISH_SYM REGISTRATION_SYM SET_SYM CHALLENGE_RESPONSE_SYM AS TEXT_STRING_hash {
        auto tmp1 = $1;
        auto tmp2 = $7;
        res = new IR(kOptUserRegistration, OP3("", "FINISH REGISTRATION SET CHALLENGE_RESPONSE AS", ""), tmp1, tmp2);
        $$ = res;
    }

;


create_user:

    user identification opt_create_user_with_mfa {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCreateUser_1, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kCreateUser, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | user identified_with_plugin opt_initial_auth {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCreateUser_2, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kCreateUser, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | user opt_create_user_with_mfa {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCreateUser, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_create_user_with_mfa:

    /* empty */ {
        res = new IR(kOptCreateUserWithMfa, OP3("", "", ""));
        $$ = res;
    }

    | AND_SYM identification {
        auto tmp1 = $2;
        res = new IR(kOptCreateUserWithMfa, OP3("AND", "", ""), tmp1);
        $$ = res;
    }

    | AND_SYM identification AND_SYM identification {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kOptCreateUserWithMfa, OP3("AND", "AND", ""), tmp1, tmp2);
        $$ = res;
    }

;


identification:

    identified_by_password {
        auto tmp1 = $1;
        res = new IR(kIdentification, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | identified_by_random_password {
        auto tmp1 = $1;
        res = new IR(kIdentification, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | identified_with_plugin {
        auto tmp1 = $1;
        res = new IR(kIdentification, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | identified_with_plugin_as_auth {
        auto tmp1 = $1;
        res = new IR(kIdentification, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | identified_with_plugin_by_password {
        auto tmp1 = $1;
        res = new IR(kIdentification, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | identified_with_plugin_by_random_password {
        auto tmp1 = $1;
        res = new IR(kIdentification, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


identified_by_password:

    IDENTIFIED_SYM BY TEXT_STRING_password {
        auto tmp1 = $3;
        res = new IR(kIdentifiedByPassword, OP3("IDENTIFIED BY", "", ""), tmp1);
        $$ = res;
    }

;


identified_by_random_password:

    IDENTIFIED_SYM BY RANDOM_SYM PASSWORD {
        res = new IR(kIdentifiedByRandomPassword, OP3("IDENTIFIED BY RANDOM PASSWORD", "", ""));
        $$ = res;
    }

;


identified_with_plugin:

    IDENTIFIED_SYM WITH ident_or_text {
        auto tmp1 = $3;
        res = new IR(kIdentifiedWithPlugin, OP3("IDENTIFIED WITH", "", ""), tmp1);
        $$ = res;
    }

;


identified_with_plugin_as_auth:

    IDENTIFIED_SYM WITH ident_or_text AS TEXT_STRING_hash {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kIdentifiedWithPluginAsAuth, OP3("IDENTIFIED WITH", "AS", ""), tmp1, tmp2);
        $$ = res;
    }

;


identified_with_plugin_by_password:

    IDENTIFIED_SYM WITH ident_or_text BY TEXT_STRING_password {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kIdentifiedWithPluginByPassword, OP3("IDENTIFIED WITH", "BY", ""), tmp1, tmp2);
        $$ = res;
    }

;


identified_with_plugin_by_random_password:

    IDENTIFIED_SYM WITH ident_or_text BY RANDOM_SYM PASSWORD {
        auto tmp1 = $3;
        res = new IR(kIdentifiedWithPluginByRandomPassword, OP3("IDENTIFIED WITH", "BY RANDOM PASSWORD", ""), tmp1);
        $$ = res;
    }

;


opt_initial_auth:

    INITIAL_SYM AUTHENTICATION_SYM identified_by_random_password {
        auto tmp1 = $3;
        res = new IR(kOptInitialAuth, OP3("INITIAL AUTHENTICATION", "", ""), tmp1);
        $$ = res;
    }

    | INITIAL_SYM AUTHENTICATION_SYM identified_with_plugin_as_auth {
        auto tmp1 = $3;
        res = new IR(kOptInitialAuth, OP3("INITIAL AUTHENTICATION", "", ""), tmp1);
        $$ = res;
    }

    | INITIAL_SYM AUTHENTICATION_SYM identified_by_password {
        auto tmp1 = $3;
        res = new IR(kOptInitialAuth, OP3("INITIAL AUTHENTICATION", "", ""), tmp1);
        $$ = res;
    }

;


alter_user:

    user identified_by_password REPLACE_SYM TEXT_STRING_password opt_retain_current_password {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAlterUser_1, OP3("", "", "REPLACE"), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kAlterUser_2, OP3("", "", ""), res, tmp3);

        auto tmp4 = $5;
        res = new IR(kAlterUser, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | user identified_with_plugin_by_password REPLACE_SYM TEXT_STRING_password opt_retain_current_password {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAlterUser_3, OP3("", "", "REPLACE"), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kAlterUser_4, OP3("", "", ""), res, tmp3);

        auto tmp4 = $5;
        res = new IR(kAlterUser, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | user identified_by_password opt_retain_current_password {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAlterUser_5, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kAlterUser, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | user identified_by_random_password opt_retain_current_password {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAlterUser_6, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kAlterUser, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | user identified_by_random_password REPLACE_SYM TEXT_STRING_password opt_retain_current_password {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAlterUser_7, OP3("", "", "REPLACE"), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kAlterUser_8, OP3("", "", ""), res, tmp3);

        auto tmp4 = $5;
        res = new IR(kAlterUser, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | user identified_with_plugin {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAlterUser, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | user identified_with_plugin_as_auth opt_retain_current_password {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAlterUser_9, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kAlterUser, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | user identified_with_plugin_by_password opt_retain_current_password {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAlterUser_10, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kAlterUser, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | user identified_with_plugin_by_random_password opt_retain_current_password {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAlterUser_11, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kAlterUser, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | user opt_discard_old_password {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAlterUser, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | user ADD factor identification {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAlterUser_12, OP3("", "ADD", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kAlterUser, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | user ADD factor identification ADD factor identification {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAlterUser_13, OP3("", "ADD", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kAlterUser_14, OP3("", "", "ADD"), res, tmp3);

        auto tmp4 = $6;
        res = new IR(kAlterUser_15, OP3("", "", ""), res, tmp4);

        auto tmp5 = $7;
        res = new IR(kAlterUser, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

    | user MODIFY_SYM factor identification {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAlterUser_16, OP3("", "MODIFY", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kAlterUser, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | user MODIFY_SYM factor identification MODIFY_SYM factor identification {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAlterUser_17, OP3("", "MODIFY", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kAlterUser_18, OP3("", "", "MODIFY"), res, tmp3);

        auto tmp4 = $6;
        res = new IR(kAlterUser_19, OP3("", "", ""), res, tmp4);

        auto tmp5 = $7;
        res = new IR(kAlterUser, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

    | user DROP factor {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAlterUser, OP3("", "DROP", ""), tmp1, tmp2);
        $$ = res;
    }

    | user DROP factor DROP factor {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAlterUser_20, OP3("", "DROP", "DROP"), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kAlterUser, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


factor:

    NUM FACTOR_SYM {
        res = new IR(kFactor, OP3("NUM FACTOR", "", ""));
        $$ = res;
    }

;


create_user_list:

    create_user {
        auto tmp1 = $1;
        res = new IR(kCreateUserList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | create_user_list ',' create_user {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kCreateUserList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


alter_user_list:

    alter_user {
        auto tmp1 = $1;
        res = new IR(kAlterUserList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | alter_user_list ',' alter_user {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAlterUserList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_column_list:

    /* empty */ {
        res = new IR(kOptColumnList, OP3("", "", ""));
        $$ = res;
    }

    | '(' column_list ')' {
        auto tmp1 = $2;
        res = new IR(kOptColumnList, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

;


column_list:

    ident {
        auto tmp1 = $1;
        res = new IR(kColumnList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | column_list ',' ident {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kColumnList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


require_clause:

    /* empty */ {
        res = new IR(kRequireClause, OP3("", "", ""));
        $$ = res;
    }

    | REQUIRE_SYM require_list {
        auto tmp1 = $2;
        res = new IR(kRequireClause, OP3("REQUIRE", "", ""), tmp1);
        $$ = res;
    }

    | REQUIRE_SYM SSL_SYM {
        res = new IR(kRequireClause, OP3("REQUIRE SSL", "", ""));
        $$ = res;
    }

    | REQUIRE_SYM X509_SYM {
        res = new IR(kRequireClause, OP3("REQUIRE X509", "", ""));
        $$ = res;
    }

    | REQUIRE_SYM NONE_SYM {
        res = new IR(kRequireClause, OP3("REQUIRE NONE", "", ""));
        $$ = res;
    }

;


grant_options:

    /* empty */ {
        res = new IR(kGrantOptions, OP3("", "", ""));
        $$ = res;
    }

    | WITH GRANT OPTION {
        res = new IR(kGrantOptions, OP3("WITH GRANT OPTION", "", ""));
        $$ = res;
    }

;


opt_grant_option:

    /* empty */ {
        res = new IR(kOptGrantOption, OP3("", "", ""));
        $$ = res;
    }

    | WITH GRANT OPTION {
        res = new IR(kOptGrantOption, OP3("WITH GRANT OPTION", "", ""));
        $$ = res;
    }

;

opt_with_roles:

    /* empty */ {
        res = new IR(kOptWithRoles, OP3("", "", ""));
        $$ = res;
    }

    | WITH ROLE_SYM role_list {
        auto tmp1 = $3;
        res = new IR(kOptWithRoles, OP3("WITH ROLE", "", ""), tmp1);
        $$ = res;
    }

    | WITH ROLE_SYM ALL opt_except_role_list {
        auto tmp1 = $4;
        res = new IR(kOptWithRoles, OP3("WITH ROLE ALL", "", ""), tmp1);
        $$ = res;
    }

    | WITH ROLE_SYM NONE_SYM {
        res = new IR(kOptWithRoles, OP3("WITH ROLE NONE", "", ""));
        $$ = res;
    }

    | WITH ROLE_SYM DEFAULT_SYM {
        res = new IR(kOptWithRoles, OP3("WITH ROLE DEFAULT", "", ""));
        $$ = res;
    }

;


opt_grant_as:

    /* empty */ {
        res = new IR(kOptGrantAs, OP3("", "", ""));
        $$ = res;
    }

    | AS user opt_with_roles {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kOptGrantAs, OP3("AS", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


begin_stmt:

    BEGIN_SYM {} opt_work {
        auto tmp1 = $3;
        res = new IR(kBeginStmt, OP3("BEGIN", "", ""), tmp1);
        $$ = res;
    }

;


opt_work:

    /* empty */ {
        res = new IR(kOptWork, OP3("", "", ""));
        $$ = res;
    }

    | WORK_SYM {
        res = new IR(kOptWork, OP3("WORK", "", ""));
        $$ = res;
    }

;


opt_chain:

    /* empty */ {
        res = new IR(kOptChain, OP3("", "", ""));
        $$ = res;
    }

    | AND_SYM NO_SYM CHAIN_SYM {
        res = new IR(kOptChain, OP3("AND NO CHAIN", "", ""));
        $$ = res;
    }

    | AND_SYM CHAIN_SYM {
        res = new IR(kOptChain, OP3("AND CHAIN", "", ""));
        $$ = res;
    }

;


opt_release:

    /* empty */ {
        res = new IR(kOptRelease, OP3("", "", ""));
        $$ = res;
    }

    | RELEASE_SYM {
        res = new IR(kOptRelease, OP3("RELEASE", "", ""));
        $$ = res;
    }

    | NO_SYM RELEASE_SYM {
        res = new IR(kOptRelease, OP3("NO RELEASE", "", ""));
        $$ = res;
    }

;


opt_savepoint:

    /* empty */ {
        res = new IR(kOptSavepoint, OP3("", "", ""));
        $$ = res;
    }

    | SAVEPOINT_SYM {
        res = new IR(kOptSavepoint, OP3("SAVEPOINT", "", ""));
        $$ = res;
    }

;


commit:

    COMMIT_SYM opt_work opt_chain opt_release {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCommit_1, OP3("COMMIT", "", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kCommit, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


rollback:

    ROLLBACK_SYM opt_work opt_chain opt_release {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kRollback_1, OP3("ROLLBACK", "", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kRollback, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ROLLBACK_SYM opt_work TO_SYM opt_savepoint ident {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kRollback_2, OP3("ROLLBACK", "TO", ""), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kRollback, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


savepoint:

    SAVEPOINT_SYM ident {
        auto tmp1 = $2;
        res = new IR(kSavepoint, OP3("SAVEPOINT", "", ""), tmp1);
        $$ = res;
    }

;


release:

    RELEASE_SYM SAVEPOINT_SYM ident {
        auto tmp1 = $3;
        res = new IR(kRelease, OP3("RELEASE SAVEPOINT", "", ""), tmp1);
        $$ = res;
    }

;

/*
UNIONS : glue selects together
*/



union_option:

    /* empty */ {
        res = new IR(kUnionOption, OP3("", "", ""));
        $$ = res;
    }

    | DISTINCT {
        res = new IR(kUnionOption, OP3("DISTINCT", "", ""));
        $$ = res;
    }

    | ALL {
        res = new IR(kUnionOption, OP3("ALL", "", ""));
        $$ = res;
    }

;


row_subquery:

    subquery {
        auto tmp1 = $1;
        res = new IR(kRowSubquery, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


table_subquery:

    subquery {
        auto tmp1 = $1;
        res = new IR(kTableSubquery, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


subquery:

    query_expression_parens %prec SUBQUERY_AS_EXPR {
        auto tmp1 = $1;
        res = new IR(kSubquery, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


query_spec_option:

    STRAIGHT_JOIN {
        res = new IR(kQuerySpecOption, OP3("STRAIGHT_JOIN", "", ""));
        $$ = res;
    }

    | HIGH_PRIORITY {
        res = new IR(kQuerySpecOption, OP3("HIGH_PRIORITY", "", ""));
        $$ = res;
    }

    | DISTINCT {
        res = new IR(kQuerySpecOption, OP3("DISTINCT", "", ""));
        $$ = res;
    }

    | SQL_SMALL_RESULT {
        res = new IR(kQuerySpecOption, OP3("SQL_SMALL_RESULT", "", ""));
        $$ = res;
    }

    | SQL_BIG_RESULT {
        res = new IR(kQuerySpecOption, OP3("SQL_BIG_RESULT", "", ""));
        $$ = res;
    }

    | SQL_BUFFER_RESULT {
        res = new IR(kQuerySpecOption, OP3("SQL_BUFFER_RESULT", "", ""));
        $$ = res;
    }

    | SQL_CALC_FOUND_ROWS {
        res = new IR(kQuerySpecOption, OP3("SQL_CALC_FOUND_ROWS", "", ""));
        $$ = res;
    }

    | ALL {
        res = new IR(kQuerySpecOption, OP3("ALL", "", ""));
        $$ = res;
    }

;

/**************************************************************************

CREATE VIEW | TRIGGER | PROCEDURE statements.

**************************************************************************/


init_lex_create_info:

    /* empty */ {
        res = new IR(kInitLexCreateInfo, OP3("", "", ""));
        $$ = res;
    }

;


view_or_trigger_or_sp_or_event:

    definer init_lex_create_info definer_tail {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kViewOrTriggerOrSpOrEvent_1, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kViewOrTriggerOrSpOrEvent, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | no_definer init_lex_create_info no_definer_tail {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kViewOrTriggerOrSpOrEvent_2, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kViewOrTriggerOrSpOrEvent, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | view_replace_or_algorithm definer_opt init_lex_create_info view_tail {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kViewOrTriggerOrSpOrEvent_3, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kViewOrTriggerOrSpOrEvent_4, OP3("", "", ""), res, tmp3);

        auto tmp4 = $4;
        res = new IR(kViewOrTriggerOrSpOrEvent, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


definer_tail:

    view_tail {
        auto tmp1 = $1;
        res = new IR(kDefinerTail, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | trigger_tail {
        auto tmp1 = $1;
        res = new IR(kDefinerTail, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_tail {
        auto tmp1 = $1;
        res = new IR(kDefinerTail, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sf_tail {
        auto tmp1 = $1;
        res = new IR(kDefinerTail, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | event_tail {
        auto tmp1 = $1;
        res = new IR(kDefinerTail, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


no_definer_tail:

    view_tail {
        auto tmp1 = $1;
        res = new IR(kNoDefinerTail, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | trigger_tail {
        auto tmp1 = $1;
        res = new IR(kNoDefinerTail, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_tail {
        auto tmp1 = $1;
        res = new IR(kNoDefinerTail, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sf_tail {
        auto tmp1 = $1;
        res = new IR(kNoDefinerTail, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | udf_tail {
        auto tmp1 = $1;
        res = new IR(kNoDefinerTail, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | event_tail {
        auto tmp1 = $1;
        res = new IR(kNoDefinerTail, OP3("", "", ""), tmp1);
        $$ = res;
    }

;

/**************************************************************************

DEFINER clause support.

**************************************************************************/


definer_opt:

    no_definer {
        auto tmp1 = $1;
        res = new IR(kDefinerOpt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | definer {
        auto tmp1 = $1;
        res = new IR(kDefinerOpt, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


no_definer:

    /* empty */ {
        res = new IR(kNoDefiner, OP3("", "", ""));
        $$ = res;
    }

;


definer:

    DEFINER_SYM EQ user {
        auto tmp1 = $3;
        res = new IR(kDefiner, OP3("DEFINER =", "", ""), tmp1);
        $$ = res;
    }

;

/**************************************************************************

CREATE VIEW statement parts.

**************************************************************************/


view_replace_or_algorithm:

    view_replace {
        auto tmp1 = $1;
        res = new IR(kViewReplaceOrAlgorithm, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | view_replace view_algorithm {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kViewReplaceOrAlgorithm, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | view_algorithm {
        auto tmp1 = $1;
        res = new IR(kViewReplaceOrAlgorithm, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


view_replace:

    OR_SYM REPLACE_SYM {
        res = new IR(kViewReplace, OP3("OR REPLACE", "", ""));
        $$ = res;
    }

;


view_algorithm:

    ALGORITHM_SYM EQ UNDEFINED_SYM {
        res = new IR(kViewAlgorithm, OP3("ALGORITHM = UNDEFINED", "", ""));
        $$ = res;
    }

    | ALGORITHM_SYM EQ MERGE_SYM {
        res = new IR(kViewAlgorithm, OP3("ALGORITHM = MERGE", "", ""));
        $$ = res;
    }

    | ALGORITHM_SYM EQ TEMPTABLE_SYM {
        res = new IR(kViewAlgorithm, OP3("ALGORITHM = TEMPTABLE", "", ""));
        $$ = res;
    }

;


view_suid:

    /* empty */ {
        res = new IR(kViewSuid, OP3("", "", ""));
        $$ = res;
    }

    | SQL_SYM SECURITY_SYM DEFINER_SYM {
        res = new IR(kViewSuid, OP3("SQL SECURITY DEFINER", "", ""));
        $$ = res;
    }

    | SQL_SYM SECURITY_SYM INVOKER_SYM {
        res = new IR(kViewSuid, OP3("SQL SECURITY INVOKER", "", ""));
        $$ = res;
    }

;


view_tail:

    view_suid VIEW_SYM table_ident opt_derived_column_list {} AS view_query_block {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kViewTail_1, OP3("", "VIEW", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kViewTail_2, OP3("", "", "AS"), res, tmp3);

        auto tmp4 = $7;
        res = new IR(kViewTail, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


view_query_block:

    query_expression_or_parens view_check_option {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kViewQueryBlock, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


view_check_option:

    /* empty */ {
        res = new IR(kViewCheckOption, OP3("", "", ""));
        $$ = res;
    }

    | WITH CHECK_SYM OPTION {
        res = new IR(kViewCheckOption, OP3("WITH CHECK OPTION", "", ""));
        $$ = res;
    }

    | WITH CASCADED CHECK_SYM OPTION {
        res = new IR(kViewCheckOption, OP3("WITH CASCADED CHECK OPTION", "", ""));
        $$ = res;
    }

    | WITH LOCAL_SYM CHECK_SYM OPTION {
        res = new IR(kViewCheckOption, OP3("WITH LOCAL CHECK OPTION", "", ""));
        $$ = res;
    }

;

/**************************************************************************

CREATE TRIGGER statement parts.

**************************************************************************/


trigger_action_order:

    FOLLOWS_SYM {
        res = new IR(kTriggerActionOrder, OP3("FOLLOWS", "", ""));
        $$ = res;
    }

    | PRECEDES_SYM {
        res = new IR(kTriggerActionOrder, OP3("PRECEDES", "", ""));
        $$ = res;
    }

;


trigger_follows_precedes_clause:

    /* empty */ {
        res = new IR(kTriggerFollowsPrecedesClause, OP3("", "", ""));
        $$ = res;
    }

    | trigger_action_order ident_or_text {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kTriggerFollowsPrecedesClause, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


trigger_tail:

    TRIGGER_SYM sp_name trg_action_time trg_event ON_SYM table_ident FOR_SYM EACH_SYM ROW_SYM trigger_follows_precedes_clause {} sp_proc_stmt {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kTriggerTail_1, OP3("TRIGGER", "", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kTriggerTail_2, OP3("", "", "ON"), res, tmp3);

        auto tmp4 = $6;
        res = new IR(kTriggerTail_3, OP3("", "", "FOR EACH ROW"), res, tmp4);

        auto tmp5 = $10;
        res = new IR(kTriggerTail_4, OP3("", "", ""), res, tmp5);

        auto tmp6 = $12;
        res = new IR(kTriggerTail, OP3("", "", ""), res, tmp6);
        $$ = res;
    }

;

/**************************************************************************

CREATE FUNCTION | PROCEDURE statements parts.

**************************************************************************/


udf_tail:

    AGGREGATE_SYM FUNCTION_SYM ident RETURNS_SYM udf_type SONAME_SYM TEXT_STRING_sys {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kUdfTail_1, OP3("AGGREGATE FUNCTION", "RETURNS", "SONAME"), tmp1, tmp2);

        auto tmp3 = $7;
        res = new IR(kUdfTail, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | FUNCTION_SYM ident RETURNS_SYM udf_type SONAME_SYM TEXT_STRING_sys {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kUdfTail_2, OP3("FUNCTION", "RETURNS", "SONAME"), tmp1, tmp2);

        auto tmp3 = $6;
        res = new IR(kUdfTail, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


sf_tail:

    FUNCTION_SYM sp_name '(' {} sp_fdparam_list ')' {} RETURNS_SYM type opt_collate {} sp_c_chistics {} sp_proc_stmt {
        auto tmp1 = $2;
        auto tmp2 = $5;
        res = new IR(kSfTail_1, OP3("FUNCTION", "(", ") RETURNS"), tmp1, tmp2);

        auto tmp3 = $9;
        res = new IR(kSfTail_2, OP3("", "", ""), res, tmp3);

        auto tmp4 = $10;
        res = new IR(kSfTail_3, OP3("", "", ""), res, tmp4);

        auto tmp5 = $12;
        res = new IR(kSfTail_4, OP3("", "", ""), res, tmp5);

        auto tmp6 = $14;
        res = new IR(kSfTail, OP3("", "", ""), res, tmp6);
        $$ = res;
    }

;


sp_tail:

    PROCEDURE_SYM sp_name {} '(' {} sp_pdparam_list ')' {} sp_c_chistics {} sp_proc_stmt {
        auto tmp1 = $2;
        auto tmp2 = $6;
        res = new IR(kSpTail_1, OP3("PROCEDURE", "(", ")"), tmp1, tmp2);

        auto tmp3 = $9;
        res = new IR(kSpTail_2, OP3("", "", ""), res, tmp3);

        auto tmp4 = $11;
        res = new IR(kSpTail, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;

/*************************************************************************/


xa:

    XA_SYM begin_or_start xid opt_join_or_resume {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kXa_1, OP3("XA", "", ""), tmp1, tmp2);

        auto tmp3 = $4;
        res = new IR(kXa, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | XA_SYM END xid opt_suspend {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kXa, OP3("XA END", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | XA_SYM PREPARE_SYM xid {
        auto tmp1 = $3;
        res = new IR(kXa, OP3("XA PREPARE", "", ""), tmp1);
        $$ = res;
    }

    | XA_SYM COMMIT_SYM xid opt_one_phase {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kXa, OP3("XA COMMIT", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | XA_SYM ROLLBACK_SYM xid {
        auto tmp1 = $3;
        res = new IR(kXa, OP3("XA ROLLBACK", "", ""), tmp1);
        $$ = res;
    }

    | XA_SYM RECOVER_SYM opt_convert_xid {
        auto tmp1 = $3;
        res = new IR(kXa, OP3("XA RECOVER", "", ""), tmp1);
        $$ = res;
    }

;


opt_convert_xid:

    /* empty */ {
        res = new IR(kOptConvertXid, OP3("", "", ""));
        $$ = res;
    }

    | CONVERT_SYM XID_SYM {
        res = new IR(kOptConvertXid, OP3("CONVERT XID", "", ""));
        $$ = res;
    }

;


xid:

    text_string {
        auto tmp1 = $1;
        res = new IR(kXid, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | text_string ',' text_string {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kXid, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | text_string ',' text_string ',' ulong_num {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kXid_1, OP3("", ",", ","), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kXid, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


begin_or_start:

    BEGIN_SYM {
        res = new IR(kBeginOrStart, OP3("BEGIN", "", ""));
        $$ = res;
    }

    | START_SYM {
        res = new IR(kBeginOrStart, OP3("START", "", ""));
        $$ = res;
    }

;


opt_join_or_resume:

    /* nothing */ {
        res = new IR(kOptJoinOrResume, OP3("", "", ""));
        $$ = res;
    }

    | JOIN_SYM {
        res = new IR(kOptJoinOrResume, OP3("JOIN", "", ""));
        $$ = res;
    }

    | RESUME_SYM {
        res = new IR(kOptJoinOrResume, OP3("RESUME", "", ""));
        $$ = res;
    }

;


opt_one_phase:

    /* nothing */ {
        res = new IR(kOptOnePhase, OP3("", "", ""));
        $$ = res;
    }

    | ONE_SYM PHASE_SYM {
        res = new IR(kOptOnePhase, OP3("ONE PHASE", "", ""));
        $$ = res;
    }

;


opt_suspend:

    /* nothing */ {
        res = new IR(kOptSuspend, OP3("", "", ""));
        $$ = res;
    }

    | SUSPEND_SYM {
        res = new IR(kOptSuspend, OP3("SUSPEND", "", ""));
        $$ = res;
    }

    | SUSPEND_SYM FOR_SYM MIGRATE_SYM {
        res = new IR(kOptSuspend, OP3("SUSPEND FOR MIGRATE", "", ""));
        $$ = res;
    }

;


install:

    INSTALL_SYM PLUGIN_SYM ident SONAME_SYM TEXT_STRING_sys {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kInstall, OP3("INSTALL PLUGIN", "SONAME", ""), tmp1, tmp2);
        $$ = res;
    }

    | INSTALL_SYM COMPONENT_SYM TEXT_STRING_sys_list {
        auto tmp1 = $3;
        res = new IR(kInstall, OP3("INSTALL COMPONENT", "", ""), tmp1);
        $$ = res;
    }

;


uninstall:

    UNINSTALL_SYM PLUGIN_SYM ident {
        auto tmp1 = $3;
        res = new IR(kUninstall, OP3("UNINSTALL PLUGIN", "", ""), tmp1);
        $$ = res;
    }

    | UNINSTALL_SYM COMPONENT_SYM TEXT_STRING_sys_list {
        auto tmp1 = $3;
        res = new IR(kUninstall, OP3("UNINSTALL COMPONENT", "", ""), tmp1);
        $$ = res;
    }

;


TEXT_STRING_sys_list:

    TEXT_STRING_sys {
        auto tmp1 = $1;
        res = new IR(kTEXTSTRINGSysList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | TEXT_STRING_sys_list ',' TEXT_STRING_sys {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTEXTSTRINGSysList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


import_stmt:

    IMPORT TABLE_SYM FROM TEXT_STRING_sys_list {
        auto tmp1 = $4;
        res = new IR(kImportStmt, OP3("IMPORT TABLE FROM", "", ""), tmp1);
        $$ = res;
    }

;

/**************************************************************************

Clone local/remote replica statements.

**************************************************************************/

clone_stmt:

    CLONE_SYM LOCAL_SYM DATA_SYM DIRECTORY_SYM opt_equal TEXT_STRING_filesystem {
        auto tmp1 = $5;
        auto tmp2 = $6;
        res = new IR(kCloneStmt, OP3("CLONE LOCAL DATA DIRECTORY", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | CLONE_SYM INSTANCE_SYM FROM user ':' ulong_num IDENTIFIED_SYM BY TEXT_STRING_sys opt_datadir_ssl {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kCloneStmt_1, OP3("CLONE INSTANCE FROM", ":", "IDENTIFIED BY"), tmp1, tmp2);

        auto tmp3 = $9;
        res = new IR(kCloneStmt_2, OP3("", "", ""), res, tmp3);

        auto tmp4 = $10;
        res = new IR(kCloneStmt, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


opt_datadir_ssl:

    opt_ssl {
        auto tmp1 = $1;
        res = new IR(kOptDatadirSsl, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DATA_SYM DIRECTORY_SYM opt_equal TEXT_STRING_filesystem opt_ssl {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kOptDatadirSsl_1, OP3("DATA DIRECTORY", "", ""), tmp1, tmp2);

        auto tmp3 = $5;
        res = new IR(kOptDatadirSsl, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


opt_ssl:

    /* empty */ {
        res = new IR(kOptSsl, OP3("", "", ""));
        $$ = res;
    }

    | REQUIRE_SYM SSL_SYM {
        res = new IR(kOptSsl, OP3("REQUIRE SSL", "", ""));
        $$ = res;
    }

    | REQUIRE_SYM NO_SYM SSL_SYM {
        res = new IR(kOptSsl, OP3("REQUIRE NO SSL", "", ""));
        $$ = res;
    }

;


resource_group_types:

    USER {
        res = new IR(kResourceGroupTypes, OP3("USER", "", ""));
        $$ = res;
    }

    | SYSTEM_SYM {
        res = new IR(kResourceGroupTypes, OP3("SYSTEM", "", ""));
        $$ = res;
    }

;


opt_resource_group_vcpu_list:

    /* empty */ {
        res = new IR(kOptResourceGroupVcpuList, OP3("", "", ""));
        $$ = res;
    }

    | VCPU_SYM opt_equal vcpu_range_spec_list {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kOptResourceGroupVcpuList, OP3("VCPU", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


vcpu_range_spec_list:

    vcpu_num_or_range {
        auto tmp1 = $1;
        res = new IR(kVcpuRangeSpecList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | vcpu_range_spec_list opt_comma vcpu_num_or_range {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kVcpuRangeSpecList_1, OP3("", "", ""), tmp1, tmp2);

        auto tmp3 = $3;
        res = new IR(kVcpuRangeSpecList, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


vcpu_num_or_range:

    NUM {
        res = new IR(kVcpuNumOrRange, OP3("NUM", "", ""));
        $$ = res;
    }

    | NUM '-' NUM {
        res = new IR(kVcpuNumOrRange, OP3("NUM - NUM", "", ""));
        $$ = res;
    }

;


signed_num:

    NUM {
        res = new IR(kSignedNum, OP3("NUM", "", ""));
        $$ = res;
    }

    | '-' NUM {
        res = new IR(kSignedNum, OP3("- NUM", "", ""));
        $$ = res;
    }

;


opt_resource_group_priority:

    /* empty */ {
        res = new IR(kOptResourceGroupPriority, OP3("", "", ""));
        $$ = res;
    }

    | THREAD_PRIORITY_SYM opt_equal signed_num {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kOptResourceGroupPriority, OP3("THREAD_PRIORITY", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_resource_group_enable_disable:

    /* empty */ {
        res = new IR(kOptResourceGroupEnableDisable, OP3("", "", ""));
        $$ = res;
    }

    | ENABLE_SYM {
        res = new IR(kOptResourceGroupEnableDisable, OP3("ENABLE", "", ""));
        $$ = res;
    }

    | DISABLE_SYM {
        res = new IR(kOptResourceGroupEnableDisable, OP3("DISABLE", "", ""));
        $$ = res;
    }

;


opt_force:

    /* empty */ {
        res = new IR(kOptForce, OP3("", "", ""));
        $$ = res;
    }

    | FORCE_SYM {
        res = new IR(kOptForce, OP3("FORCE", "", ""));
        $$ = res;
    }

;



json_attribute:

    TEXT_STRING_sys {
        auto tmp1 = $1;
        res = new IR(kJsonAttribute, OP3("", "", ""), tmp1);
        $$ = res;
    }

;

/**
  @} (end of group Parser)
*/
