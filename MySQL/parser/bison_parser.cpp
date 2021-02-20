/* A Bison parser, made by GNU Bison 3.5.1.  */

/* Bison implementation for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015, 2018-2020 Free Software Foundation,
   Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* C LALR(1) parser skeleton written by Richard Stallman, by
   simplifying the original so-called "semantic" parser.  */

/* All symbols defined below should begin with yy or YY, to avoid
   infringing on user name space.  This should be done even for local
   variables, as they might otherwise be expanded by user macros.
   There are some unavoidable exceptions within include files to
   define necessary library symbols; they are noted "INFRINGES ON
   USER NAME SPACE" below.  */

/* Undocumented macros, especially those whose name start with YY_,
   are private implementation details.  Do not rely on them.  */

/* Identify Bison output.  */
#define YYBISON 1

/* Bison version.  */
#define YYBISON_VERSION "3.5.1"

/* Skeleton name.  */
#define YYSKELETON_NAME "yacc.c"

/* Pure parsers.  */
#define YYPURE 2

/* Push parsers.  */
#define YYPUSH 0

/* Pull parsers.  */
#define YYPULL 1

/* Substitute the type names.  */
#define YYSTYPE         FF_STYPE
#define YYLTYPE         FF_LTYPE
/* Substitute the variable and function names.  */
#define yyparse         ff_parse
#define yylex           ff_lex
#define yyerror         ff_error
#define yydebug         ff_debug
#define yynerrs         ff_nerrs

/* First part of user prologue.  */
#line 1 "bison.y"

#include "bison_parser.h"
#include "flex_lexer.h"
#include <stdio.h>
#include <string.h>
int yyerror(YYLTYPE* llocp, Program * result, yyscan_t scanner, const char *msg) { return 0; }

#line 85 "y.tab.c"

# ifndef YY_CAST
#  ifdef __cplusplus
#   define YY_CAST(Type, Val) static_cast<Type> (Val)
#   define YY_REINTERPRET_CAST(Type, Val) reinterpret_cast<Type> (Val)
#  else
#   define YY_CAST(Type, Val) ((Type) (Val))
#   define YY_REINTERPRET_CAST(Type, Val) ((Type) (Val))
#  endif
# endif
# ifndef YY_NULLPTR
#  if defined __cplusplus
#   if 201103L <= __cplusplus
#    define YY_NULLPTR nullptr
#   else
#    define YY_NULLPTR 0
#   endif
#  else
#   define YY_NULLPTR ((void*)0)
#  endif
# endif

/* Enabling verbose error messages.  */
#ifdef YYERROR_VERBOSE
# undef YYERROR_VERBOSE
# define YYERROR_VERBOSE 1
#else
# define YYERROR_VERBOSE 1
#endif

/* Use api.header.include to #include this header
   instead of duplicating it here.  */
#ifndef YY_FF_Y_TAB_H_INCLUDED
# define YY_FF_Y_TAB_H_INCLUDED
/* Debug traces.  */
#ifndef FF_DEBUG
# if defined YYDEBUG
#if YYDEBUG
#   define FF_DEBUG 1
#  else
#   define FF_DEBUG 0
#  endif
# else /* ! defined YYDEBUG */
#  define FF_DEBUG 1
# endif /* ! defined YYDEBUG */
#endif  /* ! defined FF_DEBUG */
#if FF_DEBUG
extern int ff_debug;
#endif
/* "%code requires" blocks.  */
#line 8 "bison.y"

#include "../include/ast.h"
#include "parser_typedef.h"

#line 141 "y.tab.c"

/* Token type.  */
#ifndef FF_TOKENTYPE
# define FF_TOKENTYPE
  enum ff_tokentype
  {
    SQL_OP_NOTEQUAL = 258,
    SQL_ENABLE = 259,
    SQL_SIMPLE = 260,
    SQL_TEXT = 261,
    SQL_OVER = 262,
    SQL_YEAR = 263,
    SQL_INSERT_METHOD = 264,
    SQL_OP_SEMI = 265,
    SQL_BIGINT = 266,
    SQL_LIMIT = 267,
    SQL_OP_GREATERTHAN = 268,
    SQL_WITH = 269,
    SQL_ORDER = 270,
    SQL_OPTION = 271,
    SQL_LAST = 272,
    SQL_UNBOUNDED = 273,
    SQL_PRECEDING = 274,
    SQL_EXCEPT = 275,
    SQL_NUMERIC = 276,
    SQL_OP_LESSTHAN = 277,
    SQL_ACTION = 278,
    SQL_BEFORE = 279,
    SQL_OP_GREATEREQ = 280,
    SQL_CHECK = 281,
    SQL_COMPACT = 282,
    SQL_FULL = 283,
    SQL_NATURAL = 284,
    SQL_BINARY = 285,
    SQL_NATIONAL = 286,
    SQL_ENUM = 287,
    SQL_REDUNDANT = 288,
    SQL_OP_ADD = 289,
    SQL_CURRENT = 290,
    SQL_MERGE = 291,
    SQL_TRIGGER = 292,
    SQL_COMPRESSED = 293,
    SQL_OP_SUB = 294,
    SQL_FALSE = 295,
    SQL_UNIQUE = 296,
    SQL_WHERE = 297,
    SQL_MINUTE = 298,
    SQL_FIRST = 299,
    SQL_ON = 300,
    SQL_PARTIAL = 301,
    SQL_DOUBLE = 302,
    SQL_AFTER = 303,
    SQL_PRIMARY = 304,
    SQL_MONTH = 305,
    SQL_DEFERRED = 306,
    SQL_VALUES = 307,
    SQL_LONGTEXT = 308,
    SQL_SQL = 309,
    SQL_SHARED = 310,
    SQL_VALIDATION = 311,
    SQL_OR = 312,
    SQL_VIEW = 313,
    SQL_INDEX = 314,
    SQL_GROUP = 315,
    SQL_OP_MUL = 316,
    SQL_INPLACE = 317,
    SQL_FOREIGN = 318,
    SQL_RESTRICT = 319,
    SQL_SPATIAL = 320,
    SQL_FOLLOWING = 321,
    SQL_DEC = 322,
    SQL_SELECT = 323,
    SQL_NONE = 324,
    SQL_DISTINCT = 325,
    SQL_TRUE = 326,
    SQL_DYNAMIC = 327,
    SQL_BY = 328,
    SQL_OP_MOD = 329,
    SQL_INTEGER = 330,
    SQL_SECURITY = 331,
    SQL_IS = 332,
    SQL_DEFINER = 333,
    SQL_ROW = 334,
    SQL_ENFORCED = 335,
    SQL_END = 336,
    SQL_RECURSIVE = 337,
    SQL_FOR = 338,
    SQL_TEMPTABLE = 339,
    SQL_UNION = 340,
    SQL_NULLS = 341,
    SQL_UPDATE = 342,
    SQL_ELSE = 343,
    SQL_RANGE = 344,
    SQL_SET = 345,
    SQL_INVOKER = 346,
    SQL_OFFSET = 347,
    SQL_INDEXED = 348,
    SQL_FORCE = 349,
    SQL_NCHAR = 350,
    SQL_AND = 351,
    SQL_INITIALLY = 352,
    SQL_PRECISION = 353,
    SQL_FILTER = 354,
    SQL_WITHOUT = 355,
    SQL_NOT = 356,
    SQL_DELETE = 357,
    SQL_DEFFERRABLE = 358,
    SQL_REAL = 359,
    SQL_THEN = 360,
    SQL_UNDEFINED = 361,
    SQL_DEFAULT = 362,
    SQL_CROSS = 363,
    SQL_CHAR = 364,
    SQL_REFERENCES = 365,
    SQL_OP_XOR = 366,
    SQL_CASE = 367,
    SQL_FIXED = 368,
    SQL_HOUR = 369,
    SQL_NO = 370,
    SQL_COLUMN = 371,
    SQL_LOCAL = 372,
    SQL_DROP = 373,
    SQL_REPLACE = 374,
    SQL_ASC = 375,
    SQL_OP_COMMA = 376,
    SQL_DISABLE = 377,
    SQL_TABLE = 378,
    SQL_ARRAY = 379,
    SQL_IF = 380,
    SQL_EXTRACT = 381,
    SQL_LEFT = 382,
    SQL_FULLTEXT = 383,
    SQL_HASH = 384,
    SQL_ALGORITHM = 385,
    SQL_LOCK = 386,
    SQL_DECIMAL = 387,
    SQL_PARTITION = 388,
    SQL_CASCADE = 389,
    SQL_ADD = 390,
    SQL_BETWEEN = 391,
    SQL_OP_LESSEQ = 392,
    SQL_MATCH = 393,
    SQL_ALL = 394,
    SQL_ROWS = 395,
    SQL_JOIN = 396,
    SQL_LIKE = 397,
    SQL_OP_RP = 398,
    SQL_IGNORE = 399,
    SQL_INT = 400,
    SQL_UNSIGNED = 401,
    SQL_MEDIUMTEXT = 402,
    SQL_BOOLEAN = 403,
    SQL_KEY = 404,
    SQL_EACH = 405,
    SQL_USING = 406,
    SQL_RENAME = 407,
    SQL_DO = 408,
    SQL_OP_LP = 409,
    SQL_CHARACTER = 410,
    SQL_UMINUS = 411,
    SQL_CAST = 412,
    SQL_GROUPS = 413,
    SQL_OUTER = 414,
    SQL_NULL = 415,
    SQL_SMALLINT = 416,
    SQL_EXCLUSIVE = 417,
    SQL_TEMPORARY = 418,
    SQL_CONSTRAINT = 419,
    SQL_CREATE = 420,
    SQL_OP_LBRACKET = 421,
    SQL_WHEN = 422,
    SQL_IMMEDIATE = 423,
    SQL_TO = 424,
    SQL_BTREE = 425,
    SQL_DAY = 426,
    SQL_CONFLICT = 427,
    SQL_ROW_FORMAT = 428,
    SQL_OP_RBRACKET = 429,
    SQL_EXISTS = 430,
    SQL_INSERT = 431,
    SQL_KEYS = 432,
    SQL_INTO = 433,
    SQL_OP_DIVIDE = 434,
    SQL_CASCADED = 435,
    SQL_ISNULL = 436,
    SQL_AS = 437,
    SQL_INNER = 438,
    SQL_INTERSECT = 439,
    SQL_IN = 440,
    SQL_OP_EQUAL = 441,
    SQL_VARCHAR = 442,
    SQL_COPY = 443,
    SQL_ALTER = 444,
    SQL_DESC = 445,
    SQL_FROM = 446,
    SQL_TINYTEXT = 447,
    SQL_FLOAT = 448,
    SQL_SECOND = 449,
    SQL_WINDOW = 450,
    SQL_NOTHING = 451,
    SQL_HAVING = 452,
    SQL_INTLITERAL = 453,
    SQL_FLOATLITERAL = 454,
    SQL_IDENTIFIER = 455,
    SQL_STRINGLITERAL = 456
  };
#endif
/* Tokens.  */
#define SQL_OP_NOTEQUAL 258
#define SQL_ENABLE 259
#define SQL_SIMPLE 260
#define SQL_TEXT 261
#define SQL_OVER 262
#define SQL_YEAR 263
#define SQL_INSERT_METHOD 264
#define SQL_OP_SEMI 265
#define SQL_BIGINT 266
#define SQL_LIMIT 267
#define SQL_OP_GREATERTHAN 268
#define SQL_WITH 269
#define SQL_ORDER 270
#define SQL_OPTION 271
#define SQL_LAST 272
#define SQL_UNBOUNDED 273
#define SQL_PRECEDING 274
#define SQL_EXCEPT 275
#define SQL_NUMERIC 276
#define SQL_OP_LESSTHAN 277
#define SQL_ACTION 278
#define SQL_BEFORE 279
#define SQL_OP_GREATEREQ 280
#define SQL_CHECK 281
#define SQL_COMPACT 282
#define SQL_FULL 283
#define SQL_NATURAL 284
#define SQL_BINARY 285
#define SQL_NATIONAL 286
#define SQL_ENUM 287
#define SQL_REDUNDANT 288
#define SQL_OP_ADD 289
#define SQL_CURRENT 290
#define SQL_MERGE 291
#define SQL_TRIGGER 292
#define SQL_COMPRESSED 293
#define SQL_OP_SUB 294
#define SQL_FALSE 295
#define SQL_UNIQUE 296
#define SQL_WHERE 297
#define SQL_MINUTE 298
#define SQL_FIRST 299
#define SQL_ON 300
#define SQL_PARTIAL 301
#define SQL_DOUBLE 302
#define SQL_AFTER 303
#define SQL_PRIMARY 304
#define SQL_MONTH 305
#define SQL_DEFERRED 306
#define SQL_VALUES 307
#define SQL_LONGTEXT 308
#define SQL_SQL 309
#define SQL_SHARED 310
#define SQL_VALIDATION 311
#define SQL_OR 312
#define SQL_VIEW 313
#define SQL_INDEX 314
#define SQL_GROUP 315
#define SQL_OP_MUL 316
#define SQL_INPLACE 317
#define SQL_FOREIGN 318
#define SQL_RESTRICT 319
#define SQL_SPATIAL 320
#define SQL_FOLLOWING 321
#define SQL_DEC 322
#define SQL_SELECT 323
#define SQL_NONE 324
#define SQL_DISTINCT 325
#define SQL_TRUE 326
#define SQL_DYNAMIC 327
#define SQL_BY 328
#define SQL_OP_MOD 329
#define SQL_INTEGER 330
#define SQL_SECURITY 331
#define SQL_IS 332
#define SQL_DEFINER 333
#define SQL_ROW 334
#define SQL_ENFORCED 335
#define SQL_END 336
#define SQL_RECURSIVE 337
#define SQL_FOR 338
#define SQL_TEMPTABLE 339
#define SQL_UNION 340
#define SQL_NULLS 341
#define SQL_UPDATE 342
#define SQL_ELSE 343
#define SQL_RANGE 344
#define SQL_SET 345
#define SQL_INVOKER 346
#define SQL_OFFSET 347
#define SQL_INDEXED 348
#define SQL_FORCE 349
#define SQL_NCHAR 350
#define SQL_AND 351
#define SQL_INITIALLY 352
#define SQL_PRECISION 353
#define SQL_FILTER 354
#define SQL_WITHOUT 355
#define SQL_NOT 356
#define SQL_DELETE 357
#define SQL_DEFFERRABLE 358
#define SQL_REAL 359
#define SQL_THEN 360
#define SQL_UNDEFINED 361
#define SQL_DEFAULT 362
#define SQL_CROSS 363
#define SQL_CHAR 364
#define SQL_REFERENCES 365
#define SQL_OP_XOR 366
#define SQL_CASE 367
#define SQL_FIXED 368
#define SQL_HOUR 369
#define SQL_NO 370
#define SQL_COLUMN 371
#define SQL_LOCAL 372
#define SQL_DROP 373
#define SQL_REPLACE 374
#define SQL_ASC 375
#define SQL_OP_COMMA 376
#define SQL_DISABLE 377
#define SQL_TABLE 378
#define SQL_ARRAY 379
#define SQL_IF 380
#define SQL_EXTRACT 381
#define SQL_LEFT 382
#define SQL_FULLTEXT 383
#define SQL_HASH 384
#define SQL_ALGORITHM 385
#define SQL_LOCK 386
#define SQL_DECIMAL 387
#define SQL_PARTITION 388
#define SQL_CASCADE 389
#define SQL_ADD 390
#define SQL_BETWEEN 391
#define SQL_OP_LESSEQ 392
#define SQL_MATCH 393
#define SQL_ALL 394
#define SQL_ROWS 395
#define SQL_JOIN 396
#define SQL_LIKE 397
#define SQL_OP_RP 398
#define SQL_IGNORE 399
#define SQL_INT 400
#define SQL_UNSIGNED 401
#define SQL_MEDIUMTEXT 402
#define SQL_BOOLEAN 403
#define SQL_KEY 404
#define SQL_EACH 405
#define SQL_USING 406
#define SQL_RENAME 407
#define SQL_DO 408
#define SQL_OP_LP 409
#define SQL_CHARACTER 410
#define SQL_UMINUS 411
#define SQL_CAST 412
#define SQL_GROUPS 413
#define SQL_OUTER 414
#define SQL_NULL 415
#define SQL_SMALLINT 416
#define SQL_EXCLUSIVE 417
#define SQL_TEMPORARY 418
#define SQL_CONSTRAINT 419
#define SQL_CREATE 420
#define SQL_OP_LBRACKET 421
#define SQL_WHEN 422
#define SQL_IMMEDIATE 423
#define SQL_TO 424
#define SQL_BTREE 425
#define SQL_DAY 426
#define SQL_CONFLICT 427
#define SQL_ROW_FORMAT 428
#define SQL_OP_RBRACKET 429
#define SQL_EXISTS 430
#define SQL_INSERT 431
#define SQL_KEYS 432
#define SQL_INTO 433
#define SQL_OP_DIVIDE 434
#define SQL_CASCADED 435
#define SQL_ISNULL 436
#define SQL_AS 437
#define SQL_INNER 438
#define SQL_INTERSECT 439
#define SQL_IN 440
#define SQL_OP_EQUAL 441
#define SQL_VARCHAR 442
#define SQL_COPY 443
#define SQL_ALTER 444
#define SQL_DESC 445
#define SQL_FROM 446
#define SQL_TINYTEXT 447
#define SQL_FLOAT 448
#define SQL_SECOND 449
#define SQL_WINDOW 450
#define SQL_NOTHING 451
#define SQL_HAVING 452
#define SQL_INTLITERAL 453
#define SQL_FLOATLITERAL 454
#define SQL_IDENTIFIER 455
#define SQL_STRINGLITERAL 456

/* Value type.  */
#if ! defined FF_STYPE && ! defined FF_STYPE_IS_DECLARED
#line 30 "bison.y"
union FF_STYPE
{
#line 30 "bison.y"

	long	ival;
	char*	sval;
	double	fval;
	Program *	program_t;
	Stmtlist *	stmtlist_t;
	Stmt *	stmt_t;
	CreateStmt *	create_stmt_t;
	DropStmt *	drop_stmt_t;
	AlterStmt *	alter_stmt_t;
	SelectStmt *	select_stmt_t;
	SelectWithParens *	select_with_parens_t;
	SelectNoParens *	select_no_parens_t;
	SelectClauseList *	select_clause_list_t;
	SelectClause *	select_clause_t;
	CombineClause *	combine_clause_t;
	OptFromClause *	opt_from_clause_t;
	SelectTarget *	select_target_t;
	OptWindowClause *	opt_window_clause_t;
	WindowClause *	window_clause_t;
	WindowDefList *	window_def_list_t;
	WindowDef *	window_def_t;
	WindowName *	window_name_t;
	Window *	window_t;
	OptPartition *	opt_partition_t;
	OptFrameClause *	opt_frame_clause_t;
	RangeOrRows *	range_or_rows_t;
	FrameBoundStart *	frame_bound_start_t;
	FrameBoundEnd *	frame_bound_end_t;
	FrameBound *	frame_bound_t;
	OptExistWindowName *	opt_exist_window_name_t;
	OptGroupClause *	opt_group_clause_t;
	OptHavingClause *	opt_having_clause_t;
	OptWhereClause *	opt_where_clause_t;
	WhereClause *	where_clause_t;
	FromClause *	from_clause_t;
	TableRef *	table_ref_t;
	OptIndex *	opt_index_t;
	OptOn *	opt_on_t;
	OptUsing *	opt_using_t;
	ColumnNameList *	column_name_list_t;
	OptTablePrefix *	opt_table_prefix_t;
	JoinOp *	join_op_t;
	OptJoinType *	opt_join_type_t;
	ExprList *	expr_list_t;
	OptLimitClause *	opt_limit_clause_t;
	LimitClause *	limit_clause_t;
	OptLimitRowCount *	opt_limit_row_count_t;
	OptOrderClause *	opt_order_clause_t;
	OptOrderNulls *	opt_order_nulls_t;
	OrderItemList *	order_item_list_t;
	OrderItem *	order_item_t;
	OptOrderBehavior *	opt_order_behavior_t;
	OptWithClause *	opt_with_clause_t;
	CteTableList *	cte_table_list_t;
	CteTable *	cte_table_t;
	CteTableName *	cte_table_name_t;
	OptAllOrDistinct *	opt_all_or_distinct_t;
	CreateTableStmt *	create_table_stmt_t;
	CreateIndexStmt *	create_index_stmt_t;
	CreateTriggerStmt *	create_trigger_stmt_t;
	CreateViewStmt *	create_view_stmt_t;
	OptTableOptionList *	opt_table_option_list_t;
	TableOptionList *	table_option_list_t;
	TableOption *	table_option_t;
	OptOpComma *	opt_op_comma_t;
	OptIgnoreOrReplace *	opt_ignore_or_replace_t;
	OptViewAlgorithm *	opt_view_algorithm_t;
	OptSqlSecurity *	opt_sql_security_t;
	OptIndexOption *	opt_index_option_t;
	OptExtraOption *	opt_extra_option_t;
	IndexAlgorithmOption *	index_algorithm_option_t;
	LockOption *	lock_option_t;
	OptOpEqual *	opt_op_equal_t;
	TriggerEvents *	trigger_events_t;
	TriggerName *	trigger_name_t;
	TriggerActionTime *	trigger_action_time_t;
	DropIndexStmt *	drop_index_stmt_t;
	DropTableStmt *	drop_table_stmt_t;
	OptRestrictOrCascade *	opt_restrict_or_cascade_t;
	DropTriggerStmt *	drop_trigger_stmt_t;
	DropViewStmt *	drop_view_stmt_t;
	InsertStmt *	insert_stmt_t;
	InsertRest *	insert_rest_t;
	SuperValuesList *	super_values_list_t;
	ValuesList *	values_list_t;
	OptOnConflict *	opt_on_conflict_t;
	OptConflictExpr *	opt_conflict_expr_t;
	IndexedColumnList *	indexed_column_list_t;
	IndexedColumn *	indexed_column_t;
	UpdateStmt *	update_stmt_t;
	AlterAction *	alter_action_t;
	AlterConstantAction *	alter_constant_action_t;
	ColumnDefList *	column_def_list_t;
	ColumnDef *	column_def_t;
	OptColumnConstraintList *	opt_column_constraint_list_t;
	ColumnConstraintList *	column_constraint_list_t;
	ColumnConstraint *	column_constraint_t;
	OptReferenceClause *	opt_reference_clause_t;
	OptCheck *	opt_check_t;
	ConstraintType *	constraint_type_t;
	ReferenceClause *	reference_clause_t;
	OptForeignKey *	opt_foreign_key_t;
	OptForeignKeyActions *	opt_foreign_key_actions_t;
	ForeignKeyActions *	foreign_key_actions_t;
	KeyActions *	key_actions_t;
	OptConstraintAttributeSpec *	opt_constraint_attribute_spec_t;
	OptInitialTime *	opt_initial_time_t;
	ConstraintName *	constraint_name_t;
	OptTemp *	opt_temp_t;
	OptCheckOption *	opt_check_option_t;
	OptColumnNameListP *	opt_column_name_list_p_t;
	SetClauseList *	set_clause_list_t;
	SetClause *	set_clause_t;
	OptAsAlias *	opt_as_alias_t;
	Expr *	expr_t;
	Operand *	operand_t;
	CastExpr *	cast_expr_t;
	ScalarExpr *	scalar_expr_t;
	UnaryExpr *	unary_expr_t;
	BinaryExpr *	binary_expr_t;
	LogicExpr *	logic_expr_t;
	InExpr *	in_expr_t;
	CaseExpr *	case_expr_t;
	BetweenExpr *	between_expr_t;
	ExistsExpr *	exists_expr_t;
	FunctionExpr *	function_expr_t;
	OptDistinct *	opt_distinct_t;
	OptFilterClause *	opt_filter_clause_t;
	OptOverClause *	opt_over_clause_t;
	CaseList *	case_list_t;
	CaseClause *	case_clause_t;
	CompExpr *	comp_expr_t;
	ExtractExpr *	extract_expr_t;
	DatetimeField *	datetime_field_t;
	ArrayExpr *	array_expr_t;
	ArrayIndex *	array_index_t;
	Literal *	literal_t;
	StringLiteral *	string_literal_t;
	BoolLiteral *	bool_literal_t;
	NumLiteral *	num_literal_t;
	IntLiteral *	int_literal_t;
	FloatLiteral *	float_literal_t;
	OptColumn *	opt_column_t;
	TriggerBody *	trigger_body_t;
	OptIfNotExist *	opt_if_not_exist_t;
	OptIfExist *	opt_if_exist_t;
	Identifier *	identifier_t;
	AsAlias *	as_alias_t;
	TableName *	table_name_t;
	ColumnName *	column_name_t;
	OptIndexKeyword *	opt_index_keyword_t;
	ViewName *	view_name_t;
	FunctionName *	function_name_t;
	BinaryOp *	binary_op_t;
	OptNot *	opt_not_t;
	Name *	name_t;
	TypeName *	type_name_t;
	CharacterType *	character_type_t;
	CharacterWithLength *	character_with_length_t;
	CharacterWithoutLength *	character_without_length_t;
	CharacterConflicta *	character_conflicta_t;
	NumericType *	numeric_type_t;
	OptTableConstraintList *	opt_table_constraint_list_t;
	TableConstraintList *	table_constraint_list_t;
	TableConstraint *	table_constraint_t;
	OptEnforced *	opt_enforced_t;

#line 724 "y.tab.c"

};
#line 30 "bison.y"
typedef union FF_STYPE FF_STYPE;
# define FF_STYPE_IS_TRIVIAL 1
# define FF_STYPE_IS_DECLARED 1
#endif

/* Location type.  */
#if ! defined FF_LTYPE && ! defined FF_LTYPE_IS_DECLARED
typedef struct FF_LTYPE FF_LTYPE;
struct FF_LTYPE
{
  int first_line;
  int first_column;
  int last_line;
  int last_column;
};
# define FF_LTYPE_IS_DECLARED 1
# define FF_LTYPE_IS_TRIVIAL 1
#endif



int ff_parse (Program* result, yyscan_t scanner);

#endif /* !YY_FF_Y_TAB_H_INCLUDED  */



#ifdef short
# undef short
#endif

/* On compilers that do not define __PTRDIFF_MAX__ etc., make sure
   <limits.h> and (if available) <stdint.h> are included
   so that the code can choose integer types of a good width.  */

#ifndef __PTRDIFF_MAX__
# include <limits.h> /* INFRINGES ON USER NAME SPACE */
# if defined __STDC_VERSION__ && 199901 <= __STDC_VERSION__
#  include <stdint.h> /* INFRINGES ON USER NAME SPACE */
#  define YY_STDINT_H
# endif
#endif

/* Narrow types that promote to a signed type and that can represent a
   signed or unsigned integer of at least N bits.  In tables they can
   save space and decrease cache pressure.  Promoting to a signed type
   helps avoid bugs in integer arithmetic.  */

#ifdef __INT_LEAST8_MAX__
typedef __INT_LEAST8_TYPE__ yytype_int8;
#elif defined YY_STDINT_H
typedef int_least8_t yytype_int8;
#else
typedef signed char yytype_int8;
#endif

#ifdef __INT_LEAST16_MAX__
typedef __INT_LEAST16_TYPE__ yytype_int16;
#elif defined YY_STDINT_H
typedef int_least16_t yytype_int16;
#else
typedef short yytype_int16;
#endif

#if defined __UINT_LEAST8_MAX__ && __UINT_LEAST8_MAX__ <= __INT_MAX__
typedef __UINT_LEAST8_TYPE__ yytype_uint8;
#elif (!defined __UINT_LEAST8_MAX__ && defined YY_STDINT_H \
       && UINT_LEAST8_MAX <= INT_MAX)
typedef uint_least8_t yytype_uint8;
#elif !defined __UINT_LEAST8_MAX__ && UCHAR_MAX <= INT_MAX
typedef unsigned char yytype_uint8;
#else
typedef short yytype_uint8;
#endif

#if defined __UINT_LEAST16_MAX__ && __UINT_LEAST16_MAX__ <= __INT_MAX__
typedef __UINT_LEAST16_TYPE__ yytype_uint16;
#elif (!defined __UINT_LEAST16_MAX__ && defined YY_STDINT_H \
       && UINT_LEAST16_MAX <= INT_MAX)
typedef uint_least16_t yytype_uint16;
#elif !defined __UINT_LEAST16_MAX__ && USHRT_MAX <= INT_MAX
typedef unsigned short yytype_uint16;
#else
typedef int yytype_uint16;
#endif

#ifndef YYPTRDIFF_T
# if defined __PTRDIFF_TYPE__ && defined __PTRDIFF_MAX__
#  define YYPTRDIFF_T __PTRDIFF_TYPE__
#  define YYPTRDIFF_MAXIMUM __PTRDIFF_MAX__
# elif defined PTRDIFF_MAX
#  ifndef ptrdiff_t
#   include <stddef.h> /* INFRINGES ON USER NAME SPACE */
#  endif
#  define YYPTRDIFF_T ptrdiff_t
#  define YYPTRDIFF_MAXIMUM PTRDIFF_MAX
# else
#  define YYPTRDIFF_T long
#  define YYPTRDIFF_MAXIMUM LONG_MAX
# endif
#endif

#ifndef YYSIZE_T
# ifdef __SIZE_TYPE__
#  define YYSIZE_T __SIZE_TYPE__
# elif defined size_t
#  define YYSIZE_T size_t
# elif defined __STDC_VERSION__ && 199901 <= __STDC_VERSION__
#  include <stddef.h> /* INFRINGES ON USER NAME SPACE */
#  define YYSIZE_T size_t
# else
#  define YYSIZE_T unsigned
# endif
#endif

#define YYSIZE_MAXIMUM                                  \
  YY_CAST (YYPTRDIFF_T,                                 \
           (YYPTRDIFF_MAXIMUM < YY_CAST (YYSIZE_T, -1)  \
            ? YYPTRDIFF_MAXIMUM                         \
            : YY_CAST (YYSIZE_T, -1)))

#define YYSIZEOF(X) YY_CAST (YYPTRDIFF_T, sizeof (X))

/* Stored state numbers (used for stacks). */
typedef yytype_int16 yy_state_t;

/* State numbers in computations.  */
typedef int yy_state_fast_t;

#ifndef YY_
# if defined YYENABLE_NLS && YYENABLE_NLS
#  if ENABLE_NLS
#   include <libintl.h> /* INFRINGES ON USER NAME SPACE */
#   define YY_(Msgid) dgettext ("bison-runtime", Msgid)
#  endif
# endif
# ifndef YY_
#  define YY_(Msgid) Msgid
# endif
#endif

#ifndef YY_ATTRIBUTE_PURE
# if defined __GNUC__ && 2 < __GNUC__ + (96 <= __GNUC_MINOR__)
#  define YY_ATTRIBUTE_PURE __attribute__ ((__pure__))
# else
#  define YY_ATTRIBUTE_PURE
# endif
#endif

#ifndef YY_ATTRIBUTE_UNUSED
# if defined __GNUC__ && 2 < __GNUC__ + (7 <= __GNUC_MINOR__)
#  define YY_ATTRIBUTE_UNUSED __attribute__ ((__unused__))
# else
#  define YY_ATTRIBUTE_UNUSED
# endif
#endif

/* Suppress unused-variable warnings by "using" E.  */
#if ! defined lint || defined __GNUC__
# define YYUSE(E) ((void) (E))
#else
# define YYUSE(E) /* empty */
#endif

#if defined __GNUC__ && ! defined __ICC && 407 <= __GNUC__ * 100 + __GNUC_MINOR__
/* Suppress an incorrect diagnostic about yylval being uninitialized.  */
# define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN                            \
    _Pragma ("GCC diagnostic push")                                     \
    _Pragma ("GCC diagnostic ignored \"-Wuninitialized\"")              \
    _Pragma ("GCC diagnostic ignored \"-Wmaybe-uninitialized\"")
# define YY_IGNORE_MAYBE_UNINITIALIZED_END      \
    _Pragma ("GCC diagnostic pop")
#else
# define YY_INITIAL_VALUE(Value) Value
#endif
#ifndef YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
# define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
# define YY_IGNORE_MAYBE_UNINITIALIZED_END
#endif
#ifndef YY_INITIAL_VALUE
# define YY_INITIAL_VALUE(Value) /* Nothing. */
#endif

#if defined __cplusplus && defined __GNUC__ && ! defined __ICC && 6 <= __GNUC__
# define YY_IGNORE_USELESS_CAST_BEGIN                          \
    _Pragma ("GCC diagnostic push")                            \
    _Pragma ("GCC diagnostic ignored \"-Wuseless-cast\"")
# define YY_IGNORE_USELESS_CAST_END            \
    _Pragma ("GCC diagnostic pop")
#endif
#ifndef YY_IGNORE_USELESS_CAST_BEGIN
# define YY_IGNORE_USELESS_CAST_BEGIN
# define YY_IGNORE_USELESS_CAST_END
#endif


#define YY_ASSERT(E) ((void) (0 && (E)))

#if ! defined yyoverflow || YYERROR_VERBOSE

/* The parser invokes alloca or malloc; define the necessary symbols.  */

# ifdef YYSTACK_USE_ALLOCA
#  if YYSTACK_USE_ALLOCA
#   ifdef __GNUC__
#    define YYSTACK_ALLOC __builtin_alloca
#   elif defined __BUILTIN_VA_ARG_INCR
#    include <alloca.h> /* INFRINGES ON USER NAME SPACE */
#   elif defined _AIX
#    define YYSTACK_ALLOC __alloca
#   elif defined _MSC_VER
#    include <malloc.h> /* INFRINGES ON USER NAME SPACE */
#    define alloca _alloca
#   else
#    define YYSTACK_ALLOC alloca
#    if ! defined _ALLOCA_H && ! defined EXIT_SUCCESS
#     include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
      /* Use EXIT_SUCCESS as a witness for stdlib.h.  */
#     ifndef EXIT_SUCCESS
#      define EXIT_SUCCESS 0
#     endif
#    endif
#   endif
#  endif
# endif

# ifdef YYSTACK_ALLOC
   /* Pacify GCC's 'empty if-body' warning.  */
#  define YYSTACK_FREE(Ptr) do { /* empty */; } while (0)
#  ifndef YYSTACK_ALLOC_MAXIMUM
    /* The OS might guarantee only one guard page at the bottom of the stack,
       and a page size can be as small as 4096 bytes.  So we cannot safely
       invoke alloca (N) if N exceeds 4096.  Use a slightly smaller number
       to allow for a few compiler-allocated temporary stack slots.  */
#   define YYSTACK_ALLOC_MAXIMUM 4032 /* reasonable circa 2006 */
#  endif
# else
#  define YYSTACK_ALLOC YYMALLOC
#  define YYSTACK_FREE YYFREE
#  ifndef YYSTACK_ALLOC_MAXIMUM
#   define YYSTACK_ALLOC_MAXIMUM YYSIZE_MAXIMUM
#  endif
#  if (defined __cplusplus && ! defined EXIT_SUCCESS \
       && ! ((defined YYMALLOC || defined malloc) \
             && (defined YYFREE || defined free)))
#   include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
#   ifndef EXIT_SUCCESS
#    define EXIT_SUCCESS 0
#   endif
#  endif
#  ifndef YYMALLOC
#   define YYMALLOC malloc
#   if ! defined malloc && ! defined EXIT_SUCCESS
void *malloc (YYSIZE_T); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
#  ifndef YYFREE
#   define YYFREE free
#   if ! defined free && ! defined EXIT_SUCCESS
void free (void *); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
# endif
#endif /* ! defined yyoverflow || YYERROR_VERBOSE */


#if (! defined yyoverflow \
     && (! defined __cplusplus \
         || (defined FF_LTYPE_IS_TRIVIAL && FF_LTYPE_IS_TRIVIAL \
             && defined FF_STYPE_IS_TRIVIAL && FF_STYPE_IS_TRIVIAL)))

/* A type that is properly aligned for any stack member.  */
union yyalloc
{
  yy_state_t yyss_alloc;
  YYSTYPE yyvs_alloc;
  YYLTYPE yyls_alloc;
};

/* The size of the maximum gap between one aligned stack and the next.  */
# define YYSTACK_GAP_MAXIMUM (YYSIZEOF (union yyalloc) - 1)

/* The size of an array large to enough to hold all stacks, each with
   N elements.  */
# define YYSTACK_BYTES(N) \
     ((N) * (YYSIZEOF (yy_state_t) + YYSIZEOF (YYSTYPE) \
             + YYSIZEOF (YYLTYPE)) \
      + 2 * YYSTACK_GAP_MAXIMUM)

# define YYCOPY_NEEDED 1

/* Relocate STACK from its old location to the new one.  The
   local variables YYSIZE and YYSTACKSIZE give the old and new number of
   elements in the stack, and YYPTR gives the new location of the
   stack.  Advance YYPTR to a properly aligned location for the next
   stack.  */
# define YYSTACK_RELOCATE(Stack_alloc, Stack)                           \
    do                                                                  \
      {                                                                 \
        YYPTRDIFF_T yynewbytes;                                         \
        YYCOPY (&yyptr->Stack_alloc, Stack, yysize);                    \
        Stack = &yyptr->Stack_alloc;                                    \
        yynewbytes = yystacksize * YYSIZEOF (*Stack) + YYSTACK_GAP_MAXIMUM; \
        yyptr += yynewbytes / YYSIZEOF (*yyptr);                        \
      }                                                                 \
    while (0)

#endif

#if defined YYCOPY_NEEDED && YYCOPY_NEEDED
/* Copy COUNT objects from SRC to DST.  The source and destination do
   not overlap.  */
# ifndef YYCOPY
#  if defined __GNUC__ && 1 < __GNUC__
#   define YYCOPY(Dst, Src, Count) \
      __builtin_memcpy (Dst, Src, YY_CAST (YYSIZE_T, (Count)) * sizeof (*(Src)))
#  else
#   define YYCOPY(Dst, Src, Count)              \
      do                                        \
        {                                       \
          YYPTRDIFF_T yyi;                      \
          for (yyi = 0; yyi < (Count); yyi++)   \
            (Dst)[yyi] = (Src)[yyi];            \
        }                                       \
      while (0)
#  endif
# endif
#endif /* !YYCOPY_NEEDED */

/* YYFINAL -- State number of the termination state.  */
#define YYFINAL  54
/* YYLAST -- Last index in YYTABLE.  */
#define YYLAST   1119

/* YYNTOKENS -- Number of terminals.  */
#define YYNTOKENS  202
/* YYNNTS -- Number of nonterminals.  */
#define YYNNTS  164
/* YYNRULES -- Number of rules.  */
#define YYNRULES  410
/* YYNSTATES -- Number of states.  */
#define YYNSTATES  722

#define YYUNDEFTOK  2
#define YYMAXUTOK   456


/* YYTRANSLATE(TOKEN-NUM) -- Symbol number corresponding to TOKEN-NUM
   as returned by yylex, with out-of-bounds checking.  */
#define YYTRANSLATE(YYX)                                                \
  (0 <= (YYX) && (YYX) <= YYMAXUTOK ? yytranslate[YYX] : YYUNDEFTOK)

/* YYTRANSLATE[TOKEN-NUM] -- Symbol number corresponding to TOKEN-NUM
   as returned by yylex.  */
static const yytype_uint8 yytranslate[] =
{
       0,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     1,     2,     3,     4,
       5,     6,     7,     8,     9,    10,    11,    12,    13,    14,
      15,    16,    17,    18,    19,    20,    21,    22,    23,    24,
      25,    26,    27,    28,    29,    30,    31,    32,    33,    34,
      35,    36,    37,    38,    39,    40,    41,    42,    43,    44,
      45,    46,    47,    48,    49,    50,    51,    52,    53,    54,
      55,    56,    57,    58,    59,    60,    61,    62,    63,    64,
      65,    66,    67,    68,    69,    70,    71,    72,    73,    74,
      75,    76,    77,    78,    79,    80,    81,    82,    83,    84,
      85,    86,    87,    88,    89,    90,    91,    92,    93,    94,
      95,    96,    97,    98,    99,   100,   101,   102,   103,   104,
     105,   106,   107,   108,   109,   110,   111,   112,   113,   114,
     115,   116,   117,   118,   119,   120,   121,   122,   123,   124,
     125,   126,   127,   128,   129,   130,   131,   132,   133,   134,
     135,   136,   137,   138,   139,   140,   141,   142,   143,   144,
     145,   146,   147,   148,   149,   150,   151,   152,   153,   154,
     155,   156,   157,   158,   159,   160,   161,   162,   163,   164,
     165,   166,   167,   168,   169,   170,   171,   172,   173,   174,
     175,   176,   177,   178,   179,   180,   181,   182,   183,   184,
     185,   186,   187,   188,   189,   190,   191,   192,   193,   194,
     195,   196,   197,   198,   199,   200,   201
};

#if FF_DEBUG
  /* YYRLINE[YYN] -- Source line where rule number YYN was defined.  */
static const yytype_int16 yyrline[] =
{
       0,   425,   425,   435,   442,   451,   457,   463,   469,   475,
     481,   490,   496,   502,   508,   517,   523,   529,   535,   544,
     554,   560,   569,   575,   584,   596,   602,   613,   627,   632,
     637,   645,   651,   659,   668,   674,   682,   691,   697,   707,
     729,   738,   750,   756,   764,   771,   779,   787,   792,   797,
     805,   811,   819,   825,   833,   839,   845,   853,   868,   876,
     883,   891,   897,   905,   911,   919,   928,   937,   948,   959,
     969,   982,   988,   993,  1001,  1007,  1015,  1021,  1029,  1035,
    1045,  1052,  1060,  1065,  1070,  1079,  1084,  1089,  1094,  1099,
    1107,  1115,  1125,  1131,  1139,  1145,  1152,  1162,  1168,  1176,
    1182,  1190,  1195,  1200,  1208,  1214,  1224,  1235,  1240,  1245,
    1253,  1259,  1265,  1273,  1279,  1289,  1299,  1309,  1314,  1319,
    1327,  1350,  1392,  1430,  1467,  1509,  1554,  1560,  1568,  1574,
    1585,  1591,  1597,  1603,  1609,  1615,  1621,  1627,  1633,  1642,
    1647,  1655,  1660,  1665,  1673,  1678,  1683,  1688,  1696,  1701,
    1706,  1714,  1719,  1724,  1732,  1738,  1744,  1752,  1758,  1764,
    1773,  1779,  1785,  1791,  1800,  1805,  1813,  1818,  1823,  1831,
    1840,  1845,  1853,  1875,  1899,  1904,  1909,  1917,  1939,  1962,
    1975,  1982,  1988,  1998,  2004,  2014,  2023,  2029,  2037,  2045,
    2052,  2060,  2066,  2076,  2086,  2097,  2111,  2129,  2161,  2180,
    2199,  2208,  2213,  2218,  2223,  2228,  2234,  2239,  2247,  2253,
    2263,  2283,  2291,  2299,  2305,  2315,  2324,  2331,  2339,  2346,
    2354,  2359,  2364,  2372,  2415,  2420,  2428,  2434,  2442,  2447,
    2452,  2457,  2463,  2472,  2477,  2482,  2487,  2492,  2500,  2506,
    2512,  2520,  2525,  2530,  2538,  2547,  2552,  2560,  2565,  2570,
    2575,  2583,  2589,  2597,  2603,  2613,  2620,  2630,  2636,  2644,
    2650,  2656,  2662,  2668,  2674,  2683,  2689,  2695,  2701,  2707,
    2713,  2719,  2725,  2731,  2737,  2746,  2756,  2762,  2771,  2777,
    2783,  2789,  2795,  2801,  2806,  2814,  2820,  2828,  2835,  2845,
    2852,  2862,  2870,  2878,  2889,  2896,  2902,  2910,  2920,  2928,
    2939,  2949,  2957,  2970,  2975,  2983,  2989,  2997,  3003,  3009,
    3017,  3023,  3033,  3043,  3050,  3057,  3064,  3071,  3078,  3088,
    3098,  3103,  3108,  3113,  3118,  3123,  3131,  3140,  3150,  3156,
    3162,  3171,  3180,  3185,  3193,  3199,  3208,  3216,  3224,  3229,
    3237,  3243,  3249,  3255,  3264,  3269,  3277,  3282,  3290,  3299,
    3317,  3335,  3353,  3358,  3363,  3368,  3376,  3385,  3403,  3408,
    3413,  3418,  3423,  3428,  3436,  3441,  3449,  3458,  3464,  3473,
    3479,  3488,  3498,  3504,  3509,  3514,  3522,  3527,  3532,  3537,
    3542,  3547,  3552,  3557,  3562,  3567,  3575,  3580,  3585,  3590,
    3595,  3600,  3605,  3610,  3615,  3620,  3625,  3630,  3635,  3640,
    3648,  3654,  3662,  3668,  3678,  3685,  3692,  3700,  3727,  3732,
    3737
};
#endif

#if FF_DEBUG || YYERROR_VERBOSE || 1
/* YYTNAME[SYMBOL-NUM] -- String name of the symbol SYMBOL-NUM.
   First, the terminals, then, starting at YYNTOKENS, nonterminals.  */
static const char *const yytname[] =
{
  "$end", "error", "$undefined", "OP_NOTEQUAL", "ENABLE", "SIMPLE",
  "TEXT", "OVER", "YEAR", "INSERT_METHOD", "OP_SEMI", "BIGINT", "LIMIT",
  "OP_GREATERTHAN", "WITH", "ORDER", "OPTION", "LAST", "UNBOUNDED",
  "PRECEDING", "EXCEPT", "NUMERIC", "OP_LESSTHAN", "ACTION", "BEFORE",
  "OP_GREATEREQ", "CHECK", "COMPACT", "FULL", "NATURAL", "BINARY",
  "NATIONAL", "ENUM", "REDUNDANT", "OP_ADD", "CURRENT", "MERGE", "TRIGGER",
  "COMPRESSED", "OP_SUB", "FALSE", "UNIQUE", "WHERE", "MINUTE", "FIRST",
  "ON", "PARTIAL", "DOUBLE", "AFTER", "PRIMARY", "MONTH", "DEFERRED",
  "VALUES", "LONGTEXT", "SQL", "SHARED", "VALIDATION", "OR", "VIEW",
  "INDEX", "GROUP", "OP_MUL", "INPLACE", "FOREIGN", "RESTRICT", "SPATIAL",
  "FOLLOWING", "DEC", "SELECT", "NONE", "DISTINCT", "TRUE", "DYNAMIC",
  "BY", "OP_MOD", "INTEGER", "SECURITY", "IS", "DEFINER", "ROW",
  "ENFORCED", "END", "RECURSIVE", "FOR", "TEMPTABLE", "UNION", "NULLS",
  "UPDATE", "ELSE", "RANGE", "SET", "INVOKER", "OFFSET", "INDEXED",
  "FORCE", "NCHAR", "AND", "INITIALLY", "PRECISION", "FILTER", "WITHOUT",
  "NOT", "DELETE", "DEFFERRABLE", "REAL", "THEN", "UNDEFINED", "DEFAULT",
  "CROSS", "CHAR", "REFERENCES", "OP_XOR", "CASE", "FIXED", "HOUR", "NO",
  "COLUMN", "LOCAL", "DROP", "REPLACE", "ASC", "OP_COMMA", "DISABLE",
  "TABLE", "ARRAY", "IF", "EXTRACT", "LEFT", "FULLTEXT", "HASH",
  "ALGORITHM", "LOCK", "DECIMAL", "PARTITION", "CASCADE", "ADD", "BETWEEN",
  "OP_LESSEQ", "MATCH", "ALL", "ROWS", "JOIN", "LIKE", "OP_RP", "IGNORE",
  "INT", "UNSIGNED", "MEDIUMTEXT", "BOOLEAN", "KEY", "EACH", "USING",
  "RENAME", "DO", "OP_LP", "CHARACTER", "UMINUS", "CAST", "GROUPS",
  "OUTER", "NULL", "SMALLINT", "EXCLUSIVE", "TEMPORARY", "CONSTRAINT",
  "CREATE", "OP_LBRACKET", "WHEN", "IMMEDIATE", "TO", "BTREE", "DAY",
  "CONFLICT", "ROW_FORMAT", "OP_RBRACKET", "EXISTS", "INSERT", "KEYS",
  "INTO", "OP_DIVIDE", "CASCADED", "ISNULL", "AS", "INNER", "INTERSECT",
  "IN", "OP_EQUAL", "VARCHAR", "COPY", "ALTER", "DESC", "FROM", "TINYTEXT",
  "FLOAT", "SECOND", "WINDOW", "NOTHING", "HAVING", "INTLITERAL",
  "FLOATLITERAL", "IDENTIFIER", "STRINGLITERAL", "$accept", "program",
  "stmtlist", "stmt", "create_stmt", "drop_stmt", "alter_stmt",
  "select_stmt", "select_with_parens", "select_no_parens",
  "select_clause_list", "select_clause", "combine_clause",
  "opt_from_clause", "select_target", "opt_window_clause", "window_clause",
  "window_def_list", "window_def", "window_name", "window",
  "opt_partition", "opt_frame_clause", "range_or_rows",
  "frame_bound_start", "frame_bound_end", "frame_bound",
  "opt_exist_window_name", "opt_group_clause", "opt_having_clause",
  "opt_where_clause", "where_clause", "from_clause", "table_ref",
  "opt_index", "opt_on", "opt_using", "column_name_list",
  "opt_table_prefix", "join_op", "opt_join_type", "expr_list",
  "opt_limit_clause", "limit_clause", "opt_limit_row_count",
  "opt_order_clause", "opt_order_nulls", "order_item_list", "order_item",
  "opt_order_behavior", "opt_with_clause", "cte_table_list", "cte_table",
  "cte_table_name", "opt_all_or_distinct", "create_table_stmt",
  "create_index_stmt", "create_trigger_stmt", "create_view_stmt",
  "opt_table_option_list", "table_option_list", "table_option",
  "opt_op_comma", "opt_ignore_or_replace", "opt_view_algorithm",
  "opt_sql_security", "opt_index_option", "opt_extra_option",
  "index_algorithm_option", "lock_option", "opt_op_equal",
  "trigger_events", "trigger_name", "trigger_action_time",
  "drop_index_stmt", "drop_table_stmt", "opt_restrict_or_cascade",
  "drop_trigger_stmt", "drop_view_stmt", "insert_stmt", "insert_rest",
  "super_values_list", "values_list", "opt_on_conflict",
  "opt_conflict_expr", "indexed_column_list", "indexed_column",
  "update_stmt", "alter_action", "alter_constant_action",
  "column_def_list", "column_def", "opt_column_constraint_list",
  "column_constraint_list", "column_constraint", "opt_reference_clause",
  "opt_check", "constraint_type", "reference_clause", "opt_foreign_key",
  "opt_foreign_key_actions", "foreign_key_actions", "key_actions",
  "opt_constraint_attribute_spec", "opt_initial_time", "constraint_name",
  "opt_temp", "opt_check_option", "opt_column_name_list_p",
  "set_clause_list", "set_clause", "opt_as_alias", "expr", "operand",
  "cast_expr", "scalar_expr", "unary_expr", "binary_expr", "logic_expr",
  "in_expr", "case_expr", "between_expr", "exists_expr", "function_expr",
  "opt_distinct", "opt_filter_clause", "opt_over_clause", "case_list",
  "case_clause", "comp_expr", "extract_expr", "datetime_field",
  "array_expr", "array_index", "literal", "string_literal", "bool_literal",
  "num_literal", "int_literal", "float_literal", "opt_column",
  "trigger_body", "opt_if_not_exist", "opt_if_exist", "identifier",
  "as_alias", "table_name", "column_name", "opt_index_keyword",
  "view_name", "function_name", "binary_op", "opt_not", "name",
  "type_name", "character_type", "character_with_length",
  "character_without_length", "character_conflicta", "numeric_type",
  "opt_table_constraint_list", "table_constraint_list", "table_constraint",
  "opt_enforced", YY_NULLPTR
};
#endif

# ifdef YYPRINT
/* YYTOKNUM[NUM] -- (External) token number corresponding to the
   (internal) symbol number NUM (which must be that of a token).  */
static const yytype_int16 yytoknum[] =
{
       0,   256,   257,   258,   259,   260,   261,   262,   263,   264,
     265,   266,   267,   268,   269,   270,   271,   272,   273,   274,
     275,   276,   277,   278,   279,   280,   281,   282,   283,   284,
     285,   286,   287,   288,   289,   290,   291,   292,   293,   294,
     295,   296,   297,   298,   299,   300,   301,   302,   303,   304,
     305,   306,   307,   308,   309,   310,   311,   312,   313,   314,
     315,   316,   317,   318,   319,   320,   321,   322,   323,   324,
     325,   326,   327,   328,   329,   330,   331,   332,   333,   334,
     335,   336,   337,   338,   339,   340,   341,   342,   343,   344,
     345,   346,   347,   348,   349,   350,   351,   352,   353,   354,
     355,   356,   357,   358,   359,   360,   361,   362,   363,   364,
     365,   366,   367,   368,   369,   370,   371,   372,   373,   374,
     375,   376,   377,   378,   379,   380,   381,   382,   383,   384,
     385,   386,   387,   388,   389,   390,   391,   392,   393,   394,
     395,   396,   397,   398,   399,   400,   401,   402,   403,   404,
     405,   406,   407,   408,   409,   410,   411,   412,   413,   414,
     415,   416,   417,   418,   419,   420,   421,   422,   423,   424,
     425,   426,   427,   428,   429,   430,   431,   432,   433,   434,
     435,   436,   437,   438,   439,   440,   441,   442,   443,   444,
     445,   446,   447,   448,   449,   450,   451,   452,   453,   454,
     455,   456
};
# endif

#define YYPACT_NINF (-294)

#define yypact_value_is_default(Yyn) \
  ((Yyn) == YYPACT_NINF)

#define YYTABLE_NINF (-366)

#define yytable_value_is_error(Yyn) \
  ((Yyn) == YYTABLE_NINF)

  /* YYPACT[STATE-NUM] -- Index in YYTABLE of the portion describing
     STATE-NUM.  */
static const yytype_int16 yypact[] =
{
      16,   -46,    -8,    19,    14,     9,   -34,   100,  -294,   170,
    -294,  -294,  -294,  -294,  -294,  -294,   -45,  -294,  -294,  -294,
    -294,  -294,  -294,  -294,  -294,  -294,  -294,    -3,  -294,  -294,
      87,    60,  -294,    59,    -3,    69,   161,   161,    -3,  -294,
     173,   165,   179,   306,    -3,  -294,   229,  -294,  -294,   192,
     334,   260,   343,    -3,  -294,    11,     5,   239,   414,     0,
    -294,    -3,   277,    -3,  -294,    69,    -3,   342,  -294,   263,
      -3,    -3,   295,   161,  -294,  -294,   329,  -294,   307,   208,
     363,   382,   317,    -3,   136,  -294,  -294,  -294,   909,    -3,
     368,   431,  -294,  -294,  -294,   306,  -294,    14,   303,  -294,
     326,   358,  -294,  -101,  -294,  -294,  -294,   -24,   265,   265,
    -294,  -294,  -294,    -3,  -294,  -294,   144,   334,  -294,  -294,
    -294,   325,    -3,   355,    -3,   412,   281,   403,  -294,   404,
      37,   285,   347,   116,  -294,  -294,  -294,   918,  -294,  -294,
    -294,   918,   799,   300,   311,   102,   318,  -294,  -294,  -294,
    -294,   276,  -294,   -35,   308,  -294,  -294,  -294,  -294,  -294,
    -294,  -294,  -294,  -294,  -294,  -294,  -294,  -294,  -294,  -294,
    -294,  -294,  -294,  -294,  -294,   321,  -294,   323,   293,    69,
     909,   909,  -294,  -294,  -294,   330,  -294,    -3,  -101,    -3,
     427,   359,   284,  -294,  -294,  -294,  -294,    39,   183,   -24,
    -294,  -294,  -294,   436,   432,  -294,  -294,    59,   310,    10,
      -3,  -294,  -294,  -294,   348,  -294,    -3,  -294,    -3,    -3,
      -3,   918,    82,   795,   909,    -9,   316,   324,   909,     8,
     356,   360,   909,  -294,   427,  -294,   909,   909,   377,   918,
     918,   918,   918,  -294,  -294,  -294,  -294,   -69,   282,  -294,
     918,   918,   918,   304,  -294,  -294,   918,   918,   320,   -32,
     353,    59,  -294,   380,   -23,   268,  -294,  -294,   427,   365,
     909,   414,  -294,  -101,   909,  -294,  -294,  -294,  -294,  -294,
    -294,  -294,  -294,    -3,    -3,   328,  -294,   265,    -3,   265,
     224,  -294,    12,   357,  -294,  -294,  -294,   508,  -294,   346,
     375,   219,   319,  -294,   909,  -294,   344,  -294,  -294,  -294,
    -294,  -294,  -294,   332,  -294,  -294,   -16,    80,    99,   460,
     425,  -294,   909,   841,   784,   784,   784,   364,  -294,   918,
     918,   598,   784,   841,   354,   841,    82,   110,  -294,   428,
     909,   512,   486,   138,   909,  -294,  -294,   446,   909,   909,
     414,   350,   280,   521,  -294,   280,   451,    59,    14,   101,
     371,   416,   222,  -294,  -294,   361,  -294,    18,   909,  -294,
    -294,  -294,  -294,   186,  -294,   444,  -294,  -294,  -294,  -294,
    -294,  -294,  -294,  -294,  -294,  -294,  -294,  -294,  -294,  -294,
    -294,  -294,  -294,  -294,   248,  -294,  -294,  -294,   390,  -294,
      -3,   909,  -294,   909,   314,  -294,   909,   508,    67,  -294,
    -294,  -294,    49,   321,    69,   391,   473,   367,  -294,  -294,
     645,   841,   918,  -294,   102,  -294,   393,   541,   406,   411,
     386,  -294,   405,   511,  -294,  -294,   262,  -294,   280,   280,
     521,   909,   909,  -294,   410,   383,   550,  -294,  -294,  -294,
      -3,   349,   423,  -294,   447,    -3,  -294,  -294,  -294,  -294,
    -294,  -294,    14,  -294,   424,   449,   -23,  -294,  -294,  -294,
    -294,   422,   413,  -294,   546,   248,  -294,   304,  -294,   280,
     315,  -294,   -13,   433,  -294,   415,  -294,   437,   434,   122,
     313,   909,   909,    -3,  -294,  -294,   918,   649,   438,   439,
     538,   150,  -294,   428,  -294,   430,   909,  -294,   465,  -294,
    -294,  -294,  -294,   280,   280,   509,    14,    -2,  -294,  -294,
    -294,   435,   440,   441,   448,    18,   371,  -294,  -294,   442,
     909,  -294,  -294,  -294,   450,   -14,  -294,   452,  -294,  -294,
    -294,  -294,  -294,    69,    69,   514,   503,   555,   459,   408,
    -294,   485,   426,  -294,   649,  -294,  -294,   909,    -3,  -294,
     541,   909,   454,   466,   405,    17,   550,   597,   588,   589,
     909,   909,   464,   471,  -294,  -294,   -57,   295,  -294,   909,
     470,  -294,   516,  -294,   555,   555,    -3,  -294,   909,   476,
      69,   909,  -294,    -3,   474,   114,   487,   496,  -294,  -294,
     488,   -58,  -294,  -294,  -294,  -294,   458,  -294,  -294,  -294,
    -294,  -294,   619,   622,   209,   498,   909,    -3,  -294,  -294,
    -294,   213,  -294,    -3,  -294,   476,   476,  -294,   280,   489,
    -294,   555,   280,  -294,    -3,  -294,  -294,   569,   414,   427,
    -101,  -294,  -294,  -294,   254,  -294,   501,   502,   254,    59,
    -294,  -294,    -3,   476,   504,   909,   158,  -294,   427,  -294,
     566,  -294,  -294,   516,  -294,    31,   506,  -294,  -294,  -294,
    -294,  -294,  -294,  -294,   352,  -294,  -294,  -294,   299,   335,
     327,  -294,  -294,   631,   578,   642,  -294,  -294,   261,   217,
     217,  -294,  -294,  -294,   558,   567,  -294,  -294,  -294,   570,
    -294,  -294,  -294,   -52,   653,  -294,  -294,  -294,   567,     6,
    -294,   650,  -294,  -294,  -294,  -294,  -294,  -294,   599,  -294,
    -294,  -294
};

  /* YYDEFACT[STATE-NUM] -- Default reduction number in state STATE-NUM.
     Performed when YYTABLE does not specify something else to do.  Zero
     means the default is an error.  */
static const yytype_int16 yydefact[] =
{
     112,     0,     0,   246,   112,   147,     0,     0,     2,     0,
       5,     6,    10,     7,    21,    20,     0,    11,    12,    13,
      14,    15,    16,    17,    18,     9,     8,     0,   348,   110,
     113,     0,   350,   252,     0,   258,   347,   347,     0,   245,
       0,     0,     0,     0,     0,   352,     0,   354,   353,     0,
     150,     0,     0,     0,     1,   112,   119,     0,   100,    25,
     111,     0,     0,     0,   116,   258,     0,     0,   257,     0,
       0,     0,   156,   347,    23,    22,     0,   169,   147,     0,
       0,     0,   345,     0,     0,     3,   118,   117,   365,     0,
       0,    93,    30,    28,    29,     0,   114,   112,     0,   351,
      78,     0,   349,     0,   346,   177,   356,   176,   165,   165,
     172,   154,   155,     0,   170,   171,     0,   150,   145,   146,
     144,     0,     0,     0,     0,     0,     0,     0,   202,     0,
     339,     0,   339,   339,   205,    19,   200,     0,   333,   284,
     332,   364,   365,     0,     0,   112,     0,   283,   336,   337,
     331,    32,    33,   258,   259,   263,   267,   268,   269,   264,
     262,   270,   260,   261,   273,   285,   271,   272,   266,   277,
     328,   329,   330,   334,   335,   351,   276,     0,     0,   258,
     365,   365,    24,    92,    26,     0,   251,     0,     0,     0,
      64,   253,     0,   174,   175,   178,   164,     0,     0,   176,
     168,   166,   167,     0,     0,   148,   149,   252,     0,   127,
       0,   204,   206,   207,     0,   338,     0,   203,     0,     0,
       0,     0,   278,   279,   365,     0,     0,   310,   365,     0,
       0,     0,   365,    81,    64,    31,   365,   365,    91,     0,
       0,     0,     0,   358,   359,   362,   361,     0,   364,   363,
       0,     0,     0,     0,   360,   280,     0,     0,     0,   304,
       0,   252,    99,   104,   109,    94,   115,    79,    64,     0,
     365,   100,    63,     0,   365,   158,   157,   159,   162,   161,
     160,   163,   173,     0,     0,     0,   344,   165,     0,   165,
     143,   126,   128,     0,   201,   199,   198,     0,   196,     0,
       0,     0,     0,   295,   365,   311,     0,   325,   321,   324,
     322,   323,   320,     0,   274,   265,     0,    66,     0,    60,
     290,   289,   365,   314,   315,   316,   318,     0,   281,     0,
       0,     0,   317,   287,     0,   313,   286,     0,   303,   306,
     365,   112,   188,   112,   365,   107,   108,   103,   365,   365,
     100,     0,    65,    98,   254,   255,     0,   252,   112,     0,
     401,   208,     0,   142,   141,     0,   139,     0,   365,   379,
     389,   397,   375,     0,   374,   393,   382,   396,   387,   373,
     385,   390,   377,   392,   395,   386,   399,   381,   398,   376,
     388,   378,   380,   391,   212,   368,   369,   370,   372,   367,
       0,   365,   294,   365,     0,   326,   365,     0,    89,    82,
      83,    80,    81,   350,   258,     0,     0,    35,    90,   282,
       0,   288,     0,   327,   112,   293,     0,   309,     0,     0,
       0,   179,     0,     0,   180,   105,     0,   106,    95,    96,
      98,   365,   365,   195,     0,     0,   250,   132,   131,   130,
       0,     0,     0,   400,   402,     0,   138,   137,   136,   134,
     133,   135,   112,   129,     0,   191,   109,   384,   383,   394,
     222,     0,     0,   210,   219,   213,   215,     0,   197,   312,
       0,   297,     0,     0,    88,    85,    87,     0,     0,     0,
      73,   365,   365,     0,    27,    34,     0,   298,     0,     0,
       0,     0,   301,   306,   300,   190,   365,   182,   183,   181,
     102,   101,   194,   256,    97,     0,   112,     0,   124,   366,
     244,     0,     0,     0,     0,   127,     0,   209,   120,   153,
     365,   193,   220,   221,     0,   217,   214,     0,   296,   319,
     275,    86,    84,   258,   258,     0,     0,    75,     0,    62,
      36,    37,     0,    40,   299,   291,   292,   365,    58,   308,
     309,   365,     0,     0,     0,   112,   250,     0,     0,     0,
     365,   365,     0,     0,   121,   403,     0,   156,   192,   365,
       0,   211,     0,   371,    75,    75,     0,    72,   365,    77,
     258,   365,    59,     0,     0,     0,     0,    43,    57,   302,
       0,     0,   185,   184,   340,   343,     0,   342,   341,   123,
     125,   247,     0,     0,     0,     0,   365,     0,   152,   151,
     122,     0,   224,     0,   216,    77,    77,    71,    74,     0,
      67,    75,    61,    38,    58,   305,   307,     0,   100,     0,
       0,   186,   249,   248,   410,   405,     0,     0,   410,   252,
      69,    70,     0,    77,     0,   365,    46,   189,     0,   408,
       0,   406,   404,     0,   218,   227,     0,    68,    39,    42,
      47,    48,    49,    41,   365,   187,   409,   407,     0,     0,
     240,   226,    76,     0,     0,   365,    44,    50,     0,     0,
       0,   230,   228,   229,     0,   243,   223,    51,    56,     0,
      54,    55,   236,     0,     0,   235,   231,   232,   243,     0,
     238,   365,   234,   233,   237,   239,   241,   242,     0,    45,
      52,    53
};

  /* YYPGOTO[NTERM-NUM].  */
static const yytype_int16 yypgoto[] =
{
    -294,  -294,   618,  -294,  -294,   113,   115,   -83,   682,     3,
     592,  -294,  -294,  -294,  -294,  -294,  -294,    98,  -294,   191,
      62,  -294,  -294,  -294,    13,  -294,   -18,  -294,  -294,  -294,
    -189,  -274,  -294,   290,  -294,  -223,  -232,  -181,  -294,  -294,
    -294,  -133,  -294,  -294,   257,  -258,  -294,   370,  -294,   238,
       4,    20,  -294,  -294,  -294,  -294,  -294,  -294,  -294,   180,
     340,  -294,  -294,  -294,   630,   595,  -294,   139,  -294,   633,
     -91,  -294,   648,  -294,  -294,  -294,   525,  -294,  -294,   155,
    -294,   151,  -294,  -294,  -294,  -293,  -294,   160,  -294,  -294,
     272,   510,  -294,   255,  -294,  -294,  -294,  -294,    66,  -294,
    -294,  -294,    41,  -294,    24,  -294,   728,   168,  -197,  -179,
    -294,   -60,   -75,   -17,  -294,  -294,  -294,  -294,  -294,  -294,
    -294,  -294,  -294,  -294,  -294,   233,   177,   195,  -294,  -294,
    -294,  -294,  -294,  -294,  -294,  -294,  -294,  -294,  -236,  -294,
     302,  -294,  -294,    34,    -1,  -294,     1,   -61,  -294,  -107,
     420,  -294,   585,  -294,   337,  -294,  -294,  -294,  -294,  -294,
    -294,   216,  -294,    97
};

  /* YYDEFGOTO[NTERM-NUM].  */
static const yytype_int16 yydefgoto[] =
{
      -1,     7,     8,     9,    10,    11,    12,    13,    14,    15,
      58,    59,    95,   234,   151,   494,   495,   550,   551,   552,
     596,   638,   673,   674,   686,   719,   687,   597,   417,   592,
     271,   272,   235,   317,   547,   589,   630,    98,   318,   411,
     487,   152,   182,   183,   443,    91,   437,   262,   263,   347,
      43,    29,    30,    31,    88,    17,    18,    19,    20,   290,
     291,   292,   367,   365,    50,    81,   577,   110,   111,   112,
     197,   203,    76,   116,    21,    22,   195,    23,    24,    25,
     342,   507,   508,   431,   562,   464,   465,    26,   135,   136,
     360,   361,   473,   474,   475,   581,   535,   476,   624,   582,
     680,   681,   706,   696,   710,   451,    40,   518,    64,   190,
     191,    67,   153,   154,   155,   156,   157,   158,   159,   160,
     161,   162,   163,   164,   340,   427,   502,   226,   227,   165,
     166,   313,   167,   168,   169,   170,   171,   172,   173,   174,
     216,   609,   124,    70,   175,    68,    33,   176,    52,   107,
     177,   257,   178,   520,   394,   395,   396,   397,   398,   399,
     452,   453,   454,   661
};

  /* YYTABLE[YYPACT[STATE-NUM]] -- What to do in state STATE-NUM.  If
     positive, shift that token.  If negative, reduce the rule whose
     number is the opposite.  If YYTABLE_NINF, syntax error.  */
static const yytype_int16 yytable[] =
{
      32,    32,   100,    35,    16,   101,   267,    42,   269,   268,
     285,    -4,   231,   353,   185,   207,   307,   334,   198,   287,
      92,  -140,   236,    56,   567,     1,    32,   287,     1,   640,
       1,     1,   327,    32,   236,    65,    27,    32,   338,    72,
     193,   236,   192,    77,   236,   319,    44,    60,   236,   580,
      45,   308,    32,   189,    84,   712,    36,   716,   309,    16,
      32,   237,    99,     1,   343,   102,    46,   225,  -355,    77,
     106,    71,   618,   237,    47,    86,   678,    37,    38,   350,
     237,    96,    32,   237,   125,    93,   214,   237,    32,    53,
     179,   328,   440,   238,   354,   306,  -225,   345,     2,    28,
      54,   275,    99,     2,     2,   264,   265,   113,   713,   408,
     194,   339,    32,   619,   199,   568,     1,  -112,   447,   261,
     222,   106,   310,    32,   223,   209,   100,   192,   100,     3,
     539,    57,  -246,   366,     3,     3,    34,    48,   641,    49,
     126,   137,   138,   245,    87,   448,   276,    66,   230,   301,
     127,   408,     1,   215,    28,   295,   246,   316,   224,   299,
     445,   320,   321,   139,   288,     4,   407,   346,     4,   679,
       4,   236,    39,   140,   717,   484,     5,   357,   569,   311,
      55,     5,    39,   289,    94,  -140,    99,    99,    99,   418,
     432,   289,    28,   249,   485,   352,   359,    28,   362,   355,
       6,   409,   312,   141,   223,     6,     6,   428,    61,    32,
     237,   293,   192,    63,   142,    99,   449,   297,    32,    99,
     298,   410,   323,   324,   325,   326,   143,   277,   144,   404,
     128,   200,   215,   331,   332,   333,   129,   578,   278,   335,
     336,   537,    62,   409,   118,   433,   201,   670,   253,   456,
     486,    66,   279,   412,   130,   457,   145,   635,   131,   146,
     458,   254,   147,   410,   424,   544,   236,   109,   600,   264,
     236,   132,    99,   438,   439,   446,   236,  -365,   615,   510,
     700,   702,    32,   106,   356,   219,    69,   297,   133,   470,
     280,   499,   119,   466,   459,   467,    73,   471,   671,    28,
     148,   149,    28,   150,   558,   237,   511,   703,    74,   237,
      28,   239,   420,   421,   120,   237,   672,   413,   236,   414,
     202,   240,    75,   646,   401,   236,   479,   701,   480,   460,
     241,   482,   704,   242,   659,   461,    32,   236,   425,   478,
     691,   468,   243,   363,   429,   281,   434,   244,    78,   472,
      28,   705,   644,   114,   490,   660,   648,   237,   548,   549,
     348,   625,   626,   692,   237,   657,   513,   514,   364,   245,
     683,   236,   236,   563,    56,   521,   237,   115,    79,   528,
     656,   693,   246,    82,   675,   247,   689,   684,    80,   349,
     522,   137,   138,   650,   651,   481,   538,   303,   523,    99,
     402,   690,    83,   205,   304,   497,   545,   403,   653,   248,
     237,   237,   524,   139,   546,   488,   206,    89,   329,   249,
     302,   667,   305,   140,   330,   108,   109,   498,   694,    90,
     695,    97,   103,   566,   218,   220,   647,    49,   104,   121,
     122,   180,   123,   181,   250,   251,   186,   187,   188,   519,
     252,   196,   665,   141,   297,   466,   208,   210,   211,   212,
     213,   658,   217,   215,   142,   229,   228,   233,   260,   270,
     274,   666,   232,   266,   253,  -357,   143,   259,   144,   554,
     273,   283,   595,   584,   585,   286,   466,   254,   685,   255,
     284,   224,   553,  -365,   256,   614,   466,   294,   322,   314,
     553,   344,   148,   315,   621,   337,   145,   341,   351,   146,
     358,   368,   147,   628,   369,   400,   632,   330,   405,   370,
     416,   237,   669,   406,   419,   627,     1,   426,   423,   371,
     631,   430,   436,   442,   444,   450,   441,   455,   372,   373,
     374,   466,   469,   462,   477,   491,   492,   500,   501,   503,
     148,   149,    28,   150,   504,   375,   100,   598,   505,   506,
     515,   376,   493,   509,   517,   516,   525,   529,   526,   606,
     530,   532,   534,   533,   541,   377,   540,   543,   542,   192,
     557,   555,   556,   378,   561,    99,   564,   586,   565,   570,
     572,   100,   553,   576,   571,   583,   587,   573,   379,   688,
     588,   239,   590,   380,   579,   591,   593,   601,   594,   602,
     688,   240,   381,   611,   612,   613,    99,   382,   616,   622,
     241,   383,    32,   242,   649,   617,   623,   629,   634,   637,
     636,   639,   243,   598,    57,   642,   688,   244,   643,    99,
     384,   645,   655,   652,   662,   663,   676,   668,   239,   682,
     697,    99,   239,   385,   386,   387,   388,   698,   240,   245,
     683,   708,   240,   389,   709,   721,   711,   241,   718,   390,
     242,   241,   246,    85,   242,   247,   714,   684,   604,   243,
     605,   137,   138,   243,   244,   684,    41,   184,   244,   137,
     138,   633,   559,   720,   422,   391,   654,   512,   699,   300,
     392,   393,   489,   139,   531,   574,   245,   463,   117,   249,
     245,   139,   204,   140,   435,   603,   620,   134,   105,   246,
     607,   140,   247,   246,   282,   608,   247,   527,   296,   677,
     536,   707,   715,    51,   610,   251,   560,   599,   415,   258,
     252,   496,   575,   141,   483,   664,   300,     0,     0,     0,
     300,   141,     0,     0,   142,     0,   249,     0,     0,     0,
     249,     0,   142,     0,   253,     0,   143,     0,   144,     0,
       0,     0,     0,     0,   143,     0,   144,   254,     0,   255,
       0,     0,   251,     0,   256,     0,   251,   252,     0,     0,
       0,   252,     0,     0,     0,     0,   145,  -366,   239,   146,
       0,     0,   147,     0,   145,     0,  -366,   146,   240,  -366,
     147,   253,     0,     0,     0,   253,     0,   241,   243,     0,
     242,     0,     0,   244,   254,     0,   255,     0,   254,   243,
     255,   256,     0,     0,   244,   256,     0,     0,   137,   138,
     148,   149,    28,   150,  -366,   245,     0,     0,   148,   149,
      28,   150,     0,     0,   240,     0,   245,     0,   246,     0,
     139,   247,     0,   241,     0,     0,   242,     0,     0,   246,
     140,     0,   247,     0,     0,   243,     0,     0,     0,     0,
     244,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,   249,     0,     0,     0,     0,
     141,     0,   245,     0,     0,     0,   249,     0,     0,     0,
       0,   142,     0,     0,     0,   246,     0,     0,   247,     0,
       0,  -366,     0,   143,     0,   144,     0,     0,     0,     0,
       0,     0,   251,     0,     0,     0,     0,   252,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,   137,   138,
     253,     0,   249,   145,     0,     0,   146,   137,   138,   147,
       0,   253,     0,   254,     0,   255,   224,     0,     0,     0,
     139,     0,     0,     0,   254,     0,   255,     0,   251,   139,
     140,   256,     0,  -366,     0,     0,     0,     0,     0,   140,
       0,     0,     0,     0,     0,     0,     0,   148,   149,    28,
     150,     0,     0,     0,     0,     0,     0,   253,     0,     0,
     141,     0,     0,     0,     0,     0,     0,     0,     0,   221,
     254,   142,   255,     0,     0,     0,     0,  -366,     0,     0,
     142,     0,     0,   143,     0,   144,     0,     0,     0,     0,
       0,     0,   143,     0,   144,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,   145,     0,     0,   146,     0,     0,   147,
       0,     0,   145,     0,     0,     0,     0,     0,   147,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,   148,   149,    28,
     150,     0,     0,     0,     0,     0,   148,   149,    28,   150
};

static const yytype_int16 yycheck[] =
{
       1,     2,    63,     2,     0,    65,   187,     4,   189,   188,
     207,     0,   145,   271,    97,   122,     8,   253,   109,     9,
      20,     9,    57,    68,    26,    14,    27,     9,    14,    87,
      14,    14,   101,    34,    57,    34,    82,    38,    70,    38,
      64,    57,   103,    44,    57,   234,    37,    27,    57,    63,
      41,    43,    53,   154,    53,   107,    37,    51,    50,    55,
      61,    96,    63,    14,   261,    66,    57,   142,    59,    70,
      71,    37,   129,    96,    65,    70,    45,    58,    59,   268,
      96,    61,    83,    96,    83,    85,    49,    96,    89,   123,
      89,   160,   350,   153,   273,   228,   110,   120,    87,   200,
       0,    62,   103,    87,    87,   180,   181,    73,   160,    29,
     134,   143,   113,   170,   113,   117,    14,    68,    17,   179,
     137,   122,   114,   124,   141,   124,   187,   188,   189,   118,
     143,   176,   123,   121,   118,   118,   144,   128,   196,   130,
       4,    39,    40,    61,   139,    44,   107,   182,   145,   224,
      14,    29,    14,   116,   200,   216,    74,   232,   167,   220,
     357,   236,   237,    61,   154,   154,   182,   190,   154,   138,
     154,    57,   163,    71,   168,   108,   165,   284,   180,   171,
      10,   165,   163,   173,   184,   173,   187,   188,   189,   322,
      52,   173,   200,   111,   127,   270,   287,   200,   289,   274,
     189,   121,   194,   101,   221,   189,   189,   340,   121,   210,
      96,   210,   273,   154,   112,   216,   115,   218,   219,   220,
     219,   141,   239,   240,   241,   242,   124,   188,   126,   304,
      94,    87,   116,   250,   251,   252,   100,   530,    55,   256,
     257,   477,   182,   121,    36,   107,   102,    89,   166,    27,
     183,   182,    69,   154,   118,    33,   154,   143,   122,   157,
      38,   179,   160,   141,   154,   143,    57,   131,   561,   344,
      57,   135,   273,   348,   349,   358,    57,   175,   571,    17,
      19,    64,   283,   284,   283,   169,   125,   288,   152,    41,
     107,   424,    84,   368,    72,   109,   123,    49,   140,   200,
     198,   199,   200,   201,   154,    96,    44,    90,   143,    96,
     200,     3,   329,   330,   106,    96,   158,   318,    57,   318,
     176,    13,   143,   616,   105,    57,   401,    66,   403,   107,
      22,   406,   115,    25,    80,   113,   337,    57,   337,   400,
       5,   155,    34,   119,   341,   162,   343,    39,   119,   101,
     200,   134,   143,    24,   414,   101,   143,    96,   491,   492,
      92,   584,   585,    28,    96,   639,   441,   442,   144,    61,
      18,    57,    57,   506,    68,    26,    96,    48,   186,   462,
     638,    46,    74,   123,   658,    77,    87,    35,    54,   121,
      41,    39,    40,   625,   626,    81,    81,    81,    49,   400,
      81,   102,    59,    78,    88,   422,    93,    88,   631,   101,
      96,    96,    63,    61,   101,   412,    91,   178,   136,   111,
     225,   653,   227,    71,   142,   130,   131,   424,   101,    15,
     103,   154,    90,   516,   132,   133,   617,   130,   175,    76,
      58,    73,   125,    12,   136,   137,   143,   121,    90,   450,
     142,   186,   649,   101,   455,   530,   101,    45,   177,    56,
      56,   640,   177,   116,   112,   154,   166,   191,   175,    42,
     186,   652,   154,   143,   166,   154,   124,   154,   126,   496,
     121,    45,   557,   543,   544,   175,   561,   179,   136,   181,
      58,   167,   493,   185,   186,   570,   571,   149,   121,   143,
     501,   121,   198,   143,   579,   185,   154,   154,   143,   157,
     182,   154,   160,   588,     6,   169,   591,   142,   174,    11,
      60,    96,   655,   191,   160,   586,    14,    99,   174,    21,
     590,    45,    86,    12,    83,   164,   186,   121,    30,    31,
      32,   616,    98,   182,   154,   154,    73,   154,     7,   143,
     198,   199,   200,   201,   143,    47,   617,   558,   172,   154,
     150,    53,   195,    52,    14,   182,   143,   143,   121,   565,
     121,   149,    26,   160,   159,    67,   143,   143,   141,   640,
      42,   143,   143,    75,   154,   586,   121,    73,    79,   154,
     149,   652,   593,   151,   154,   143,    93,   149,    90,   674,
      45,     3,   143,    95,   154,   197,   121,   153,   182,   143,
     685,    13,   104,    16,    26,    26,   617,   109,   154,   149,
      22,   113,   623,    25,   623,   154,   110,   151,   154,   133,
     143,   143,    34,   634,   176,    16,   711,    39,    16,   640,
     132,   143,    73,   154,   143,   143,    80,   143,     3,   143,
      19,   652,     3,   145,   146,   147,   148,    79,    13,    61,
      18,   103,    13,   155,    97,    66,    96,    22,    18,   161,
      25,    22,    74,    55,    25,    77,    23,    35,   565,    34,
     565,    39,    40,    34,    39,    35,     4,    95,    39,    39,
      40,   593,   501,   711,    96,   187,   634,   440,   685,   101,
     192,   193,   412,    61,   466,   525,    61,   367,    78,   111,
      61,    61,   117,    71,   344,   564,   577,    84,    70,    74,
     565,    71,    77,    74,   199,   565,    77,   455,   218,   663,
     475,   690,   708,     5,   566,   137,   503,   560,   318,   154,
     142,    96,   526,   101,   407,   648,   101,    -1,    -1,    -1,
     101,   101,    -1,    -1,   112,    -1,   111,    -1,    -1,    -1,
     111,    -1,   112,    -1,   166,    -1,   124,    -1,   126,    -1,
      -1,    -1,    -1,    -1,   124,    -1,   126,   179,    -1,   181,
      -1,    -1,   137,    -1,   186,    -1,   137,   142,    -1,    -1,
      -1,   142,    -1,    -1,    -1,    -1,   154,    13,     3,   157,
      -1,    -1,   160,    -1,   154,    -1,    22,   157,    13,    25,
     160,   166,    -1,    -1,    -1,   166,    -1,    22,    34,    -1,
      25,    -1,    -1,    39,   179,    -1,   181,    -1,   179,    34,
     181,   186,    -1,    -1,    39,   186,    -1,    -1,    39,    40,
     198,   199,   200,   201,     3,    61,    -1,    -1,   198,   199,
     200,   201,    -1,    -1,    13,    -1,    61,    -1,    74,    -1,
      61,    77,    -1,    22,    -1,    -1,    25,    -1,    -1,    74,
      71,    -1,    77,    -1,    -1,    34,    -1,    -1,    -1,    -1,
      39,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,   111,    -1,    -1,    -1,    -1,
     101,    -1,    61,    -1,    -1,    -1,   111,    -1,    -1,    -1,
      -1,   112,    -1,    -1,    -1,    74,    -1,    -1,    77,    -1,
      -1,   137,    -1,   124,    -1,   126,    -1,    -1,    -1,    -1,
      -1,    -1,   137,    -1,    -1,    -1,    -1,   142,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    39,    40,
     166,    -1,   111,   154,    -1,    -1,   157,    39,    40,   160,
      -1,   166,    -1,   179,    -1,   181,   167,    -1,    -1,    -1,
      61,    -1,    -1,    -1,   179,    -1,   181,    -1,   137,    61,
      71,   186,    -1,   142,    -1,    -1,    -1,    -1,    -1,    71,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,   198,   199,   200,
     201,    -1,    -1,    -1,    -1,    -1,    -1,   166,    -1,    -1,
     101,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,   101,
     179,   112,   181,    -1,    -1,    -1,    -1,   186,    -1,    -1,
     112,    -1,    -1,   124,    -1,   126,    -1,    -1,    -1,    -1,
      -1,    -1,   124,    -1,   126,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,   154,    -1,    -1,   157,    -1,    -1,   160,
      -1,    -1,   154,    -1,    -1,    -1,    -1,    -1,   160,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,   198,   199,   200,
     201,    -1,    -1,    -1,    -1,    -1,   198,   199,   200,   201
};

  /* YYSTOS[STATE-NUM] -- The (internal number of the) accessing
     symbol of state STATE-NUM.  */
static const yytype_int16 yystos[] =
{
       0,    14,    87,   118,   154,   165,   189,   203,   204,   205,
     206,   207,   208,   209,   210,   211,   252,   257,   258,   259,
     260,   276,   277,   279,   280,   281,   289,    82,   200,   253,
     254,   255,   346,   348,   144,   348,    37,    58,    59,   163,
     308,   210,   211,   252,    37,    41,    57,    65,   128,   130,
     266,   308,   350,   123,     0,    10,    68,   176,   212,   213,
     253,   121,   182,   154,   310,   348,   182,   313,   347,   125,
     345,   345,   348,   123,   143,   143,   274,   346,   119,   186,
      54,   267,   123,    59,   348,   204,    70,   139,   256,   178,
      15,   247,    20,    85,   184,   214,   253,   154,   239,   346,
     349,   313,   346,    90,   175,   274,   346,   351,   130,   131,
     269,   270,   271,   345,    24,    48,   275,   266,    36,    84,
     106,    76,    58,   125,   344,   348,     4,    14,    94,   100,
     118,   122,   135,   152,   271,   290,   291,    39,    40,    61,
      71,   101,   112,   124,   126,   154,   157,   160,   198,   199,
     201,   216,   243,   314,   315,   316,   317,   318,   319,   320,
     321,   322,   323,   324,   325,   331,   332,   334,   335,   336,
     337,   338,   339,   340,   341,   346,   349,   352,   354,   348,
      73,    12,   244,   245,   212,   209,   143,   121,    90,   154,
     311,   312,   349,    64,   134,   278,   186,   272,   272,   348,
      87,   102,   176,   273,   267,    78,    91,   351,   101,   348,
      45,   177,    56,    56,    49,   116,   342,   177,   342,   169,
     342,   101,   315,   315,   167,   314,   329,   330,   166,   154,
     211,   243,   154,   191,   215,   234,    57,    96,   313,     3,
      13,    22,    25,    34,    39,    61,    74,    77,   101,   111,
     136,   137,   142,   166,   179,   181,   186,   353,   354,   154,
     175,   313,   249,   250,   314,   314,   143,   239,   311,   239,
      42,   232,   233,   121,   186,    62,   107,   188,    55,    69,
     107,   162,   278,    45,    58,   310,   175,     9,   154,   173,
     261,   262,   263,   348,   149,   349,   293,   346,   348,   349,
     101,   314,   329,    81,    88,   329,   243,     8,    43,    50,
     114,   171,   194,   333,   143,   143,   314,   235,   240,   232,
     314,   314,   121,   315,   315,   315,   315,   101,   160,   136,
     142,   315,   315,   315,   340,   315,   315,   185,    70,   143,
     326,   154,   282,   310,   121,   120,   190,   251,    92,   121,
     232,   143,   314,   247,   311,   314,   348,   351,   182,   272,
     292,   293,   272,   119,   144,   265,   121,   264,   154,     6,
      11,    21,    30,    31,    32,    47,    53,    67,    75,    90,
      95,   104,   109,   113,   132,   145,   146,   147,   148,   155,
     161,   187,   192,   193,   356,   357,   358,   359,   360,   361,
     169,   105,    81,    88,   314,   174,   191,   182,    29,   121,
     141,   241,   154,   346,   348,   352,    60,   230,   243,   160,
     315,   315,    96,   174,   154,   348,    99,   327,   243,   211,
      45,   285,    52,   107,   211,   249,    86,   248,   314,   314,
     247,   186,    12,   246,    83,   310,   209,    17,    44,   115,
     164,   307,   362,   363,   364,   121,    27,    33,    38,    72,
     107,   113,   182,   262,   287,   288,   314,   109,   155,    98,
      41,    49,   101,   294,   295,   296,   299,   154,   349,   314,
     314,    81,   314,   356,   108,   127,   183,   242,   211,   235,
     313,   154,    73,   195,   217,   218,    96,   315,   211,   243,
     154,     7,   328,   143,   143,   172,   154,   283,   284,    52,
      17,    44,   246,   314,   314,   150,   182,    14,   309,   346,
     355,    26,    41,    49,    63,   143,   121,   292,   209,   143,
     121,   251,   149,   160,    26,   298,   295,   340,    81,   143,
     143,   159,   141,   143,   143,    93,   101,   236,   243,   243,
     219,   220,   221,   346,   315,   143,   143,    42,   154,   221,
     327,   154,   286,   243,   121,    79,   209,    26,   117,   180,
     154,   154,   149,   149,   261,   363,   151,   268,   287,   154,
      63,   297,   301,   143,   313,   313,    73,    93,    45,   237,
     143,   197,   231,   121,   182,   314,   222,   229,   346,   328,
     287,   153,   143,   283,   207,   208,   252,   281,   289,   343,
     309,    16,    26,    26,   314,   287,   154,   154,   129,   170,
     269,   314,   149,   110,   300,   237,   237,   349,   314,   151,
     238,   313,   314,   219,   154,   143,   143,   133,   223,   143,
      87,   196,    16,    16,   143,   143,   287,   239,   143,   348,
     238,   238,   154,   237,   222,    73,   247,   233,   311,    80,
     101,   365,   143,   143,   365,   310,   239,   238,   143,   243,
      89,   140,   158,   224,   225,   233,    80,   300,    45,   138,
     302,   303,   143,    18,    35,   136,   226,   228,   314,    87,
     102,     5,    28,    46,   101,   103,   305,    19,    79,   226,
      19,    66,    64,    90,   115,   134,   304,   304,   103,    97,
     306,    96,   107,   160,    23,   306,    51,   168,    18,   227,
     228,    66
};

  /* YYR1[YYN] -- Symbol number of symbol that rule YYN derives.  */
static const yytype_int16 yyr1[] =
{
       0,   202,   203,   204,   204,   205,   205,   205,   205,   205,
     205,   206,   206,   206,   206,   207,   207,   207,   207,   208,
     209,   209,   210,   210,   211,   212,   212,   213,   214,   214,
     214,   215,   215,   216,   217,   217,   218,   219,   219,   220,
     221,   222,   223,   223,   224,   224,   224,   225,   225,   225,
     226,   226,   227,   227,   228,   228,   228,   229,   229,   230,
     230,   231,   231,   232,   232,   233,   234,   235,   235,   235,
     235,   236,   236,   236,   237,   237,   238,   238,   239,   239,
     240,   240,   241,   241,   241,   242,   242,   242,   242,   242,
     243,   243,   244,   244,   245,   245,   245,   246,   246,   247,
     247,   248,   248,   248,   249,   249,   250,   251,   251,   251,
     252,   252,   252,   253,   253,   254,   255,   256,   256,   256,
     257,   257,   258,   259,   260,   260,   261,   261,   262,   262,
     263,   263,   263,   263,   263,   263,   263,   263,   263,   264,
     264,   265,   265,   265,   266,   266,   266,   266,   267,   267,
     267,   268,   268,   268,   269,   269,   269,   270,   270,   270,
     271,   271,   271,   271,   272,   272,   273,   273,   273,   274,
     275,   275,   276,   277,   278,   278,   278,   279,   280,   281,
     282,   282,   282,   283,   283,   284,   285,   285,   285,   286,
     286,   287,   287,   288,   289,   289,   290,   290,   290,   290,
     290,   291,   291,   291,   291,   291,   291,   291,   292,   292,
     293,   294,   294,   295,   295,   296,   297,   297,   298,   298,
     299,   299,   299,   300,   301,   301,   302,   302,   303,   303,
     303,   303,   303,   304,   304,   304,   304,   304,   305,   305,
     305,   306,   306,   306,   307,   308,   308,   309,   309,   309,
     309,   310,   310,   311,   311,   312,   312,   313,   313,   314,
     314,   314,   314,   314,   314,   315,   315,   315,   315,   315,
     315,   315,   315,   315,   315,   316,   317,   317,   318,   318,
     318,   318,   318,   318,   318,   319,   319,   319,   319,   320,
     320,   321,   321,   321,   322,   322,   322,   322,   323,   323,
     324,   325,   325,   326,   326,   327,   327,   328,   328,   328,
     329,   329,   330,   331,   331,   331,   331,   331,   331,   332,
     333,   333,   333,   333,   333,   333,   334,   335,   336,   336,
     336,   337,   338,   338,   339,   339,   340,   341,   342,   342,
     343,   343,   343,   343,   344,   344,   345,   345,   346,   347,
     348,   349,   350,   350,   350,   350,   351,   352,   353,   353,
     353,   353,   353,   353,   354,   354,   355,   356,   356,   357,
     357,   358,   359,   359,   359,   359,   360,   360,   360,   360,
     360,   360,   360,   360,   360,   360,   361,   361,   361,   361,
     361,   361,   361,   361,   361,   361,   361,   361,   361,   361,
     362,   362,   363,   363,   364,   364,   364,   364,   365,   365,
     365
};

  /* YYR2[YYN] -- Number of symbols on the right hand side of rule YYN.  */
static const yytype_int8 yyr2[] =
{
       0,     2,     1,     3,     2,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     4,
       1,     1,     3,     3,     4,     1,     3,     7,     1,     1,
       1,     1,     0,     1,     1,     0,     2,     1,     3,     5,
       1,     4,     3,     0,     2,     5,     0,     1,     1,     1,
       1,     2,     1,     2,     2,     2,     2,     1,     0,     4,
       0,     2,     0,     1,     0,     2,     2,     6,     8,     7,
       7,     3,     2,     0,     2,     0,     4,     0,     1,     3,
       2,     0,     1,     1,     3,     1,     2,     1,     1,     0,
       4,     2,     1,     0,     2,     4,     4,     2,     0,     3,
       0,     2,     2,     0,     1,     3,     3,     1,     1,     0,
       2,     3,     0,     1,     3,     5,     2,     1,     1,     0,
       9,    10,    11,    11,     9,    11,     1,     0,     1,     3,
       3,     3,     3,     3,     3,     3,     3,     3,     3,     1,
       0,     1,     1,     0,     3,     3,     3,     0,     3,     3,
       0,     2,     2,     0,     1,     1,     0,     3,     3,     3,
       3,     3,     3,     3,     1,     0,     1,     1,     1,     1,
       1,     1,     4,     6,     1,     1,     0,     4,     5,     7,
       2,     3,     3,     1,     3,     3,     5,     7,     0,     4,
       0,     1,     3,     2,     9,     8,     3,     5,     3,     3,
       1,     3,     1,     2,     2,     1,     2,     2,     1,     3,
       3,     3,     0,     1,     2,     1,     2,     0,     5,     0,
       2,     2,     1,     5,     2,     0,     1,     0,     2,     2,
       2,     3,     3,     2,     2,     1,     1,     2,     2,     3,
       0,     2,     2,     0,     2,     1,     0,     3,     4,     4,
       0,     3,     0,     1,     3,     3,     5,     1,     0,     1,
       1,     1,     1,     1,     1,     3,     1,     1,     1,     1,
       1,     1,     1,     1,     3,     6,     1,     1,     2,     2,
       2,     3,     4,     1,     1,     1,     3,     3,     4,     3,
       3,     6,     6,     4,     4,     3,     6,     5,     5,     6,
       5,     5,     7,     1,     0,     5,     0,     4,     2,     0,
       1,     2,     4,     3,     3,     3,     3,     3,     3,     6,
       1,     1,     1,     1,     1,     1,     4,     4,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     0,
       1,     1,     1,     1,     3,     0,     2,     0,     1,     2,
       1,     1,     1,     1,     1,     0,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     0,     1,     1,     1,     1,
       1,     4,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     2,     2,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     2,     1,     1,     1,     1,     1,
       1,     0,     1,     3,     6,     5,     6,     7,     1,     2,
       0
};


#define yyerrok         (yyerrstatus = 0)
#define yyclearin       (yychar = YYEMPTY)
#define YYEMPTY         (-2)
#define YYEOF           0

#define YYACCEPT        goto yyacceptlab
#define YYABORT         goto yyabortlab
#define YYERROR         goto yyerrorlab


#define YYRECOVERING()  (!!yyerrstatus)

#define YYBACKUP(Token, Value)                                    \
  do                                                              \
    if (yychar == YYEMPTY)                                        \
      {                                                           \
        yychar = (Token);                                         \
        yylval = (Value);                                         \
        YYPOPSTACK (yylen);                                       \
        yystate = *yyssp;                                         \
        goto yybackup;                                            \
      }                                                           \
    else                                                          \
      {                                                           \
        yyerror (&yylloc, result, scanner, YY_("syntax error: cannot back up")); \
        YYERROR;                                                  \
      }                                                           \
  while (0)

/* Error token number */
#define YYTERROR        1
#define YYERRCODE       256


/* YYLLOC_DEFAULT -- Set CURRENT to span from RHS[1] to RHS[N].
   If N is 0, then set CURRENT to the empty location which ends
   the previous symbol: RHS[0] (always defined).  */

#ifndef YYLLOC_DEFAULT
# define YYLLOC_DEFAULT(Current, Rhs, N)                                \
    do                                                                  \
      if (N)                                                            \
        {                                                               \
          (Current).first_line   = YYRHSLOC (Rhs, 1).first_line;        \
          (Current).first_column = YYRHSLOC (Rhs, 1).first_column;      \
          (Current).last_line    = YYRHSLOC (Rhs, N).last_line;         \
          (Current).last_column  = YYRHSLOC (Rhs, N).last_column;       \
        }                                                               \
      else                                                              \
        {                                                               \
          (Current).first_line   = (Current).last_line   =              \
            YYRHSLOC (Rhs, 0).last_line;                                \
          (Current).first_column = (Current).last_column =              \
            YYRHSLOC (Rhs, 0).last_column;                              \
        }                                                               \
    while (0)
#endif

#define YYRHSLOC(Rhs, K) ((Rhs)[K])


/* Enable debugging if requested.  */
#if FF_DEBUG

# ifndef YYFPRINTF
#  include <stdio.h> /* INFRINGES ON USER NAME SPACE */
#  define YYFPRINTF fprintf
# endif

# define YYDPRINTF(Args)                        \
do {                                            \
  if (yydebug)                                  \
    YYFPRINTF Args;                             \
} while (0)


/* YY_LOCATION_PRINT -- Print the location on the stream.
   This macro was not mandated originally: define only if we know
   we won't break user code: when these are the locations we know.  */

#ifndef YY_LOCATION_PRINT
# if defined FF_LTYPE_IS_TRIVIAL && FF_LTYPE_IS_TRIVIAL

/* Print *YYLOCP on YYO.  Private, do not rely on its existence. */

YY_ATTRIBUTE_UNUSED
static int
yy_location_print_ (FILE *yyo, YYLTYPE const * const yylocp)
{
  int res = 0;
  int end_col = 0 != yylocp->last_column ? yylocp->last_column - 1 : 0;
  if (0 <= yylocp->first_line)
    {
      res += YYFPRINTF (yyo, "%d", yylocp->first_line);
      if (0 <= yylocp->first_column)
        res += YYFPRINTF (yyo, ".%d", yylocp->first_column);
    }
  if (0 <= yylocp->last_line)
    {
      if (yylocp->first_line < yylocp->last_line)
        {
          res += YYFPRINTF (yyo, "-%d", yylocp->last_line);
          if (0 <= end_col)
            res += YYFPRINTF (yyo, ".%d", end_col);
        }
      else if (0 <= end_col && yylocp->first_column < end_col)
        res += YYFPRINTF (yyo, "-%d", end_col);
    }
  return res;
 }

#  define YY_LOCATION_PRINT(File, Loc)          \
  yy_location_print_ (File, &(Loc))

# else
#  define YY_LOCATION_PRINT(File, Loc) ((void) 0)
# endif
#endif


# define YY_SYMBOL_PRINT(Title, Type, Value, Location)                    \
do {                                                                      \
  if (yydebug)                                                            \
    {                                                                     \
      YYFPRINTF (stderr, "%s ", Title);                                   \
      yy_symbol_print (stderr,                                            \
                  Type, Value, Location, result, scanner); \
      YYFPRINTF (stderr, "\n");                                           \
    }                                                                     \
} while (0)


/*-----------------------------------.
| Print this symbol's value on YYO.  |
`-----------------------------------*/

static void
yy_symbol_value_print (FILE *yyo, int yytype, YYSTYPE const * const yyvaluep, YYLTYPE const * const yylocationp, Program* result, yyscan_t scanner)
{
  FILE *yyoutput = yyo;
  YYUSE (yyoutput);
  YYUSE (yylocationp);
  YYUSE (result);
  YYUSE (scanner);
  if (!yyvaluep)
    return;
# ifdef YYPRINT
  if (yytype < YYNTOKENS)
    YYPRINT (yyo, yytoknum[yytype], *yyvaluep);
# endif
  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  YYUSE (yytype);
  YY_IGNORE_MAYBE_UNINITIALIZED_END
}


/*---------------------------.
| Print this symbol on YYO.  |
`---------------------------*/

static void
yy_symbol_print (FILE *yyo, int yytype, YYSTYPE const * const yyvaluep, YYLTYPE const * const yylocationp, Program* result, yyscan_t scanner)
{
  YYFPRINTF (yyo, "%s %s (",
             yytype < YYNTOKENS ? "token" : "nterm", yytname[yytype]);

  YY_LOCATION_PRINT (yyo, *yylocationp);
  YYFPRINTF (yyo, ": ");
  yy_symbol_value_print (yyo, yytype, yyvaluep, yylocationp, result, scanner);
  YYFPRINTF (yyo, ")");
}

/*------------------------------------------------------------------.
| yy_stack_print -- Print the state stack from its BOTTOM up to its |
| TOP (included).                                                   |
`------------------------------------------------------------------*/

static void
yy_stack_print (yy_state_t *yybottom, yy_state_t *yytop)
{
  YYFPRINTF (stderr, "Stack now");
  for (; yybottom <= yytop; yybottom++)
    {
      int yybot = *yybottom;
      YYFPRINTF (stderr, " %d", yybot);
    }
  YYFPRINTF (stderr, "\n");
}

# define YY_STACK_PRINT(Bottom, Top)                            \
do {                                                            \
  if (yydebug)                                                  \
    yy_stack_print ((Bottom), (Top));                           \
} while (0)


/*------------------------------------------------.
| Report that the YYRULE is going to be reduced.  |
`------------------------------------------------*/

static void
yy_reduce_print (yy_state_t *yyssp, YYSTYPE *yyvsp, YYLTYPE *yylsp, int yyrule, Program* result, yyscan_t scanner)
{
  int yylno = yyrline[yyrule];
  int yynrhs = yyr2[yyrule];
  int yyi;
  YYFPRINTF (stderr, "Reducing stack by rule %d (line %d):\n",
             yyrule - 1, yylno);
  /* The symbols being reduced.  */
  for (yyi = 0; yyi < yynrhs; yyi++)
    {
      YYFPRINTF (stderr, "   $%d = ", yyi + 1);
      yy_symbol_print (stderr,
                       yystos[+yyssp[yyi + 1 - yynrhs]],
                       &yyvsp[(yyi + 1) - (yynrhs)]
                       , &(yylsp[(yyi + 1) - (yynrhs)])                       , result, scanner);
      YYFPRINTF (stderr, "\n");
    }
}

# define YY_REDUCE_PRINT(Rule)          \
do {                                    \
  if (yydebug)                          \
    yy_reduce_print (yyssp, yyvsp, yylsp, Rule, result, scanner); \
} while (0)

/* Nonzero means print parse trace.  It is left uninitialized so that
   multiple parsers can coexist.  */
int yydebug;
#else /* !FF_DEBUG */
# define YYDPRINTF(Args)
# define YY_SYMBOL_PRINT(Title, Type, Value, Location)
# define YY_STACK_PRINT(Bottom, Top)
# define YY_REDUCE_PRINT(Rule)
#endif /* !FF_DEBUG */


/* YYINITDEPTH -- initial size of the parser's stacks.  */
#ifndef YYINITDEPTH
# define YYINITDEPTH 200
#endif

/* YYMAXDEPTH -- maximum size the stacks can grow to (effective only
   if the built-in stack extension method is used).

   Do not make this value too large; the results are undefined if
   YYSTACK_ALLOC_MAXIMUM < YYSTACK_BYTES (YYMAXDEPTH)
   evaluated with infinite-precision integer arithmetic.  */

#ifndef YYMAXDEPTH
# define YYMAXDEPTH 10000
#endif


#if YYERROR_VERBOSE

# ifndef yystrlen
#  if defined __GLIBC__ && defined _STRING_H
#   define yystrlen(S) (YY_CAST (YYPTRDIFF_T, strlen (S)))
#  else
/* Return the length of YYSTR.  */
static YYPTRDIFF_T
yystrlen (const char *yystr)
{
  YYPTRDIFF_T yylen;
  for (yylen = 0; yystr[yylen]; yylen++)
    continue;
  return yylen;
}
#  endif
# endif

# ifndef yystpcpy
#  if defined __GLIBC__ && defined _STRING_H && defined _GNU_SOURCE
#   define yystpcpy stpcpy
#  else
/* Copy YYSRC to YYDEST, returning the address of the terminating '\0' in
   YYDEST.  */
static char *
yystpcpy (char *yydest, const char *yysrc)
{
  char *yyd = yydest;
  const char *yys = yysrc;

  while ((*yyd++ = *yys++) != '\0')
    continue;

  return yyd - 1;
}
#  endif
# endif

# ifndef yytnamerr
/* Copy to YYRES the contents of YYSTR after stripping away unnecessary
   quotes and backslashes, so that it's suitable for yyerror.  The
   heuristic is that double-quoting is unnecessary unless the string
   contains an apostrophe, a comma, or backslash (other than
   backslash-backslash).  YYSTR is taken from yytname.  If YYRES is
   null, do not copy; instead, return the length of what the result
   would have been.  */
static YYPTRDIFF_T
yytnamerr (char *yyres, const char *yystr)
{
  if (*yystr == '"')
    {
      YYPTRDIFF_T yyn = 0;
      char const *yyp = yystr;

      for (;;)
        switch (*++yyp)
          {
          case '\'':
          case ',':
            goto do_not_strip_quotes;

          case '\\':
            if (*++yyp != '\\')
              goto do_not_strip_quotes;
            else
              goto append;

          append:
          default:
            if (yyres)
              yyres[yyn] = *yyp;
            yyn++;
            break;

          case '"':
            if (yyres)
              yyres[yyn] = '\0';
            return yyn;
          }
    do_not_strip_quotes: ;
    }

  if (yyres)
    return yystpcpy (yyres, yystr) - yyres;
  else
    return yystrlen (yystr);
}
# endif

/* Copy into *YYMSG, which is of size *YYMSG_ALLOC, an error message
   about the unexpected token YYTOKEN for the state stack whose top is
   YYSSP.

   Return 0 if *YYMSG was successfully written.  Return 1 if *YYMSG is
   not large enough to hold the message.  In that case, also set
   *YYMSG_ALLOC to the required number of bytes.  Return 2 if the
   required number of bytes is too large to store.  */
static int
yysyntax_error (YYPTRDIFF_T *yymsg_alloc, char **yymsg,
                yy_state_t *yyssp, int yytoken)
{
  enum { YYERROR_VERBOSE_ARGS_MAXIMUM = 5 };
  /* Internationalized format string. */
  const char *yyformat = YY_NULLPTR;
  /* Arguments of yyformat: reported tokens (one for the "unexpected",
     one per "expected"). */
  char const *yyarg[YYERROR_VERBOSE_ARGS_MAXIMUM];
  /* Actual size of YYARG. */
  int yycount = 0;
  /* Cumulated lengths of YYARG.  */
  YYPTRDIFF_T yysize = 0;

  /* There are many possibilities here to consider:
     - If this state is a consistent state with a default action, then
       the only way this function was invoked is if the default action
       is an error action.  In that case, don't check for expected
       tokens because there are none.
     - The only way there can be no lookahead present (in yychar) is if
       this state is a consistent state with a default action.  Thus,
       detecting the absence of a lookahead is sufficient to determine
       that there is no unexpected or expected token to report.  In that
       case, just report a simple "syntax error".
     - Don't assume there isn't a lookahead just because this state is a
       consistent state with a default action.  There might have been a
       previous inconsistent state, consistent state with a non-default
       action, or user semantic action that manipulated yychar.
     - Of course, the expected token list depends on states to have
       correct lookahead information, and it depends on the parser not
       to perform extra reductions after fetching a lookahead from the
       scanner and before detecting a syntax error.  Thus, state merging
       (from LALR or IELR) and default reductions corrupt the expected
       token list.  However, the list is correct for canonical LR with
       one exception: it will still contain any token that will not be
       accepted due to an error action in a later state.
  */
  if (yytoken != YYEMPTY)
    {
      int yyn = yypact[+*yyssp];
      YYPTRDIFF_T yysize0 = yytnamerr (YY_NULLPTR, yytname[yytoken]);
      yysize = yysize0;
      yyarg[yycount++] = yytname[yytoken];
      if (!yypact_value_is_default (yyn))
        {
          /* Start YYX at -YYN if negative to avoid negative indexes in
             YYCHECK.  In other words, skip the first -YYN actions for
             this state because they are default actions.  */
          int yyxbegin = yyn < 0 ? -yyn : 0;
          /* Stay within bounds of both yycheck and yytname.  */
          int yychecklim = YYLAST - yyn + 1;
          int yyxend = yychecklim < YYNTOKENS ? yychecklim : YYNTOKENS;
          int yyx;

          for (yyx = yyxbegin; yyx < yyxend; ++yyx)
            if (yycheck[yyx + yyn] == yyx && yyx != YYTERROR
                && !yytable_value_is_error (yytable[yyx + yyn]))
              {
                if (yycount == YYERROR_VERBOSE_ARGS_MAXIMUM)
                  {
                    yycount = 1;
                    yysize = yysize0;
                    break;
                  }
                yyarg[yycount++] = yytname[yyx];
                {
                  YYPTRDIFF_T yysize1
                    = yysize + yytnamerr (YY_NULLPTR, yytname[yyx]);
                  if (yysize <= yysize1 && yysize1 <= YYSTACK_ALLOC_MAXIMUM)
                    yysize = yysize1;
                  else
                    return 2;
                }
              }
        }
    }

  switch (yycount)
    {
# define YYCASE_(N, S)                      \
      case N:                               \
        yyformat = S;                       \
      break
    default: /* Avoid compiler warnings. */
      YYCASE_(0, YY_("syntax error"));
      YYCASE_(1, YY_("syntax error, unexpected %s"));
      YYCASE_(2, YY_("syntax error, unexpected %s, expecting %s"));
      YYCASE_(3, YY_("syntax error, unexpected %s, expecting %s or %s"));
      YYCASE_(4, YY_("syntax error, unexpected %s, expecting %s or %s or %s"));
      YYCASE_(5, YY_("syntax error, unexpected %s, expecting %s or %s or %s or %s"));
# undef YYCASE_
    }

  {
    /* Don't count the "%s"s in the final size, but reserve room for
       the terminator.  */
    YYPTRDIFF_T yysize1 = yysize + (yystrlen (yyformat) - 2 * yycount) + 1;
    if (yysize <= yysize1 && yysize1 <= YYSTACK_ALLOC_MAXIMUM)
      yysize = yysize1;
    else
      return 2;
  }

  if (*yymsg_alloc < yysize)
    {
      *yymsg_alloc = 2 * yysize;
      if (! (yysize <= *yymsg_alloc
             && *yymsg_alloc <= YYSTACK_ALLOC_MAXIMUM))
        *yymsg_alloc = YYSTACK_ALLOC_MAXIMUM;
      return 1;
    }

  /* Avoid sprintf, as that infringes on the user's name space.
     Don't have undefined behavior even if the translation
     produced a string with the wrong number of "%s"s.  */
  {
    char *yyp = *yymsg;
    int yyi = 0;
    while ((*yyp = *yyformat) != '\0')
      if (*yyp == '%' && yyformat[1] == 's' && yyi < yycount)
        {
          yyp += yytnamerr (yyp, yyarg[yyi++]);
          yyformat += 2;
        }
      else
        {
          ++yyp;
          ++yyformat;
        }
  }
  return 0;
}
#endif /* YYERROR_VERBOSE */

/*-----------------------------------------------.
| Release the memory associated to this symbol.  |
`-----------------------------------------------*/

static void
yydestruct (const char *yymsg, int yytype, YYSTYPE *yyvaluep, YYLTYPE *yylocationp, Program* result, yyscan_t scanner)
{
  YYUSE (yyvaluep);
  YYUSE (yylocationp);
  YYUSE (result);
  YYUSE (scanner);
  if (!yymsg)
    yymsg = "Deleting";
  YY_SYMBOL_PRINT (yymsg, yytype, yyvaluep, yylocationp);

  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  switch (yytype)
    {
    case 198: /* INTLITERAL  */
#line 417 "bison.y"
           {
	 
}
#line 2425 "y.tab.c"
        break;

    case 199: /* FLOATLITERAL  */
#line 417 "bison.y"
           {
	 
}
#line 2433 "y.tab.c"
        break;

    case 200: /* IDENTIFIER  */
#line 413 "bison.y"
           {
	free( (((*yyvaluep).sval)) );
}
#line 2441 "y.tab.c"
        break;

    case 201: /* STRINGLITERAL  */
#line 413 "bison.y"
           {
	free( (((*yyvaluep).sval)) );
}
#line 2449 "y.tab.c"
        break;

    case 203: /* program  */
#line 421 "bison.y"
            { if(((*yyvaluep).program_t)!=NULL)((*yyvaluep).program_t)->deep_delete(); }
#line 2455 "y.tab.c"
        break;

    case 204: /* stmtlist  */
#line 421 "bison.y"
            { if(((*yyvaluep).stmtlist_t)!=NULL)((*yyvaluep).stmtlist_t)->deep_delete(); }
#line 2461 "y.tab.c"
        break;

    case 205: /* stmt  */
#line 421 "bison.y"
            { if(((*yyvaluep).stmt_t)!=NULL)((*yyvaluep).stmt_t)->deep_delete(); }
#line 2467 "y.tab.c"
        break;

    case 206: /* create_stmt  */
#line 421 "bison.y"
            { if(((*yyvaluep).create_stmt_t)!=NULL)((*yyvaluep).create_stmt_t)->deep_delete(); }
#line 2473 "y.tab.c"
        break;

    case 207: /* drop_stmt  */
#line 421 "bison.y"
            { if(((*yyvaluep).drop_stmt_t)!=NULL)((*yyvaluep).drop_stmt_t)->deep_delete(); }
#line 2479 "y.tab.c"
        break;

    case 208: /* alter_stmt  */
#line 421 "bison.y"
            { if(((*yyvaluep).alter_stmt_t)!=NULL)((*yyvaluep).alter_stmt_t)->deep_delete(); }
#line 2485 "y.tab.c"
        break;

    case 209: /* select_stmt  */
#line 421 "bison.y"
            { if(((*yyvaluep).select_stmt_t)!=NULL)((*yyvaluep).select_stmt_t)->deep_delete(); }
#line 2491 "y.tab.c"
        break;

    case 210: /* select_with_parens  */
#line 421 "bison.y"
            { if(((*yyvaluep).select_with_parens_t)!=NULL)((*yyvaluep).select_with_parens_t)->deep_delete(); }
#line 2497 "y.tab.c"
        break;

    case 211: /* select_no_parens  */
#line 421 "bison.y"
            { if(((*yyvaluep).select_no_parens_t)!=NULL)((*yyvaluep).select_no_parens_t)->deep_delete(); }
#line 2503 "y.tab.c"
        break;

    case 212: /* select_clause_list  */
#line 421 "bison.y"
            { if(((*yyvaluep).select_clause_list_t)!=NULL)((*yyvaluep).select_clause_list_t)->deep_delete(); }
#line 2509 "y.tab.c"
        break;

    case 213: /* select_clause  */
#line 421 "bison.y"
            { if(((*yyvaluep).select_clause_t)!=NULL)((*yyvaluep).select_clause_t)->deep_delete(); }
#line 2515 "y.tab.c"
        break;

    case 214: /* combine_clause  */
#line 421 "bison.y"
            { if(((*yyvaluep).combine_clause_t)!=NULL)((*yyvaluep).combine_clause_t)->deep_delete(); }
#line 2521 "y.tab.c"
        break;

    case 215: /* opt_from_clause  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_from_clause_t)!=NULL)((*yyvaluep).opt_from_clause_t)->deep_delete(); }
#line 2527 "y.tab.c"
        break;

    case 216: /* select_target  */
#line 421 "bison.y"
            { if(((*yyvaluep).select_target_t)!=NULL)((*yyvaluep).select_target_t)->deep_delete(); }
#line 2533 "y.tab.c"
        break;

    case 217: /* opt_window_clause  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_window_clause_t)!=NULL)((*yyvaluep).opt_window_clause_t)->deep_delete(); }
#line 2539 "y.tab.c"
        break;

    case 218: /* window_clause  */
#line 421 "bison.y"
            { if(((*yyvaluep).window_clause_t)!=NULL)((*yyvaluep).window_clause_t)->deep_delete(); }
#line 2545 "y.tab.c"
        break;

    case 219: /* window_def_list  */
#line 421 "bison.y"
            { if(((*yyvaluep).window_def_list_t)!=NULL)((*yyvaluep).window_def_list_t)->deep_delete(); }
#line 2551 "y.tab.c"
        break;

    case 220: /* window_def  */
#line 421 "bison.y"
            { if(((*yyvaluep).window_def_t)!=NULL)((*yyvaluep).window_def_t)->deep_delete(); }
#line 2557 "y.tab.c"
        break;

    case 221: /* window_name  */
#line 421 "bison.y"
            { if(((*yyvaluep).window_name_t)!=NULL)((*yyvaluep).window_name_t)->deep_delete(); }
#line 2563 "y.tab.c"
        break;

    case 222: /* window  */
#line 421 "bison.y"
            { if(((*yyvaluep).window_t)!=NULL)((*yyvaluep).window_t)->deep_delete(); }
#line 2569 "y.tab.c"
        break;

    case 223: /* opt_partition  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_partition_t)!=NULL)((*yyvaluep).opt_partition_t)->deep_delete(); }
#line 2575 "y.tab.c"
        break;

    case 224: /* opt_frame_clause  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_frame_clause_t)!=NULL)((*yyvaluep).opt_frame_clause_t)->deep_delete(); }
#line 2581 "y.tab.c"
        break;

    case 225: /* range_or_rows  */
#line 421 "bison.y"
            { if(((*yyvaluep).range_or_rows_t)!=NULL)((*yyvaluep).range_or_rows_t)->deep_delete(); }
#line 2587 "y.tab.c"
        break;

    case 226: /* frame_bound_start  */
#line 421 "bison.y"
            { if(((*yyvaluep).frame_bound_start_t)!=NULL)((*yyvaluep).frame_bound_start_t)->deep_delete(); }
#line 2593 "y.tab.c"
        break;

    case 227: /* frame_bound_end  */
#line 421 "bison.y"
            { if(((*yyvaluep).frame_bound_end_t)!=NULL)((*yyvaluep).frame_bound_end_t)->deep_delete(); }
#line 2599 "y.tab.c"
        break;

    case 228: /* frame_bound  */
#line 421 "bison.y"
            { if(((*yyvaluep).frame_bound_t)!=NULL)((*yyvaluep).frame_bound_t)->deep_delete(); }
#line 2605 "y.tab.c"
        break;

    case 229: /* opt_exist_window_name  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_exist_window_name_t)!=NULL)((*yyvaluep).opt_exist_window_name_t)->deep_delete(); }
#line 2611 "y.tab.c"
        break;

    case 230: /* opt_group_clause  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_group_clause_t)!=NULL)((*yyvaluep).opt_group_clause_t)->deep_delete(); }
#line 2617 "y.tab.c"
        break;

    case 231: /* opt_having_clause  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_having_clause_t)!=NULL)((*yyvaluep).opt_having_clause_t)->deep_delete(); }
#line 2623 "y.tab.c"
        break;

    case 232: /* opt_where_clause  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_where_clause_t)!=NULL)((*yyvaluep).opt_where_clause_t)->deep_delete(); }
#line 2629 "y.tab.c"
        break;

    case 233: /* where_clause  */
#line 421 "bison.y"
            { if(((*yyvaluep).where_clause_t)!=NULL)((*yyvaluep).where_clause_t)->deep_delete(); }
#line 2635 "y.tab.c"
        break;

    case 234: /* from_clause  */
#line 421 "bison.y"
            { if(((*yyvaluep).from_clause_t)!=NULL)((*yyvaluep).from_clause_t)->deep_delete(); }
#line 2641 "y.tab.c"
        break;

    case 235: /* table_ref  */
#line 421 "bison.y"
            { if(((*yyvaluep).table_ref_t)!=NULL)((*yyvaluep).table_ref_t)->deep_delete(); }
#line 2647 "y.tab.c"
        break;

    case 236: /* opt_index  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_index_t)!=NULL)((*yyvaluep).opt_index_t)->deep_delete(); }
#line 2653 "y.tab.c"
        break;

    case 237: /* opt_on  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_on_t)!=NULL)((*yyvaluep).opt_on_t)->deep_delete(); }
#line 2659 "y.tab.c"
        break;

    case 238: /* opt_using  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_using_t)!=NULL)((*yyvaluep).opt_using_t)->deep_delete(); }
#line 2665 "y.tab.c"
        break;

    case 239: /* column_name_list  */
#line 421 "bison.y"
            { if(((*yyvaluep).column_name_list_t)!=NULL)((*yyvaluep).column_name_list_t)->deep_delete(); }
#line 2671 "y.tab.c"
        break;

    case 240: /* opt_table_prefix  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_table_prefix_t)!=NULL)((*yyvaluep).opt_table_prefix_t)->deep_delete(); }
#line 2677 "y.tab.c"
        break;

    case 241: /* join_op  */
#line 421 "bison.y"
            { if(((*yyvaluep).join_op_t)!=NULL)((*yyvaluep).join_op_t)->deep_delete(); }
#line 2683 "y.tab.c"
        break;

    case 242: /* opt_join_type  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_join_type_t)!=NULL)((*yyvaluep).opt_join_type_t)->deep_delete(); }
#line 2689 "y.tab.c"
        break;

    case 243: /* expr_list  */
#line 421 "bison.y"
            { if(((*yyvaluep).expr_list_t)!=NULL)((*yyvaluep).expr_list_t)->deep_delete(); }
#line 2695 "y.tab.c"
        break;

    case 244: /* opt_limit_clause  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_limit_clause_t)!=NULL)((*yyvaluep).opt_limit_clause_t)->deep_delete(); }
#line 2701 "y.tab.c"
        break;

    case 245: /* limit_clause  */
#line 421 "bison.y"
            { if(((*yyvaluep).limit_clause_t)!=NULL)((*yyvaluep).limit_clause_t)->deep_delete(); }
#line 2707 "y.tab.c"
        break;

    case 246: /* opt_limit_row_count  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_limit_row_count_t)!=NULL)((*yyvaluep).opt_limit_row_count_t)->deep_delete(); }
#line 2713 "y.tab.c"
        break;

    case 247: /* opt_order_clause  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_order_clause_t)!=NULL)((*yyvaluep).opt_order_clause_t)->deep_delete(); }
#line 2719 "y.tab.c"
        break;

    case 248: /* opt_order_nulls  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_order_nulls_t)!=NULL)((*yyvaluep).opt_order_nulls_t)->deep_delete(); }
#line 2725 "y.tab.c"
        break;

    case 249: /* order_item_list  */
#line 421 "bison.y"
            { if(((*yyvaluep).order_item_list_t)!=NULL)((*yyvaluep).order_item_list_t)->deep_delete(); }
#line 2731 "y.tab.c"
        break;

    case 250: /* order_item  */
#line 421 "bison.y"
            { if(((*yyvaluep).order_item_t)!=NULL)((*yyvaluep).order_item_t)->deep_delete(); }
#line 2737 "y.tab.c"
        break;

    case 251: /* opt_order_behavior  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_order_behavior_t)!=NULL)((*yyvaluep).opt_order_behavior_t)->deep_delete(); }
#line 2743 "y.tab.c"
        break;

    case 252: /* opt_with_clause  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_with_clause_t)!=NULL)((*yyvaluep).opt_with_clause_t)->deep_delete(); }
#line 2749 "y.tab.c"
        break;

    case 253: /* cte_table_list  */
#line 421 "bison.y"
            { if(((*yyvaluep).cte_table_list_t)!=NULL)((*yyvaluep).cte_table_list_t)->deep_delete(); }
#line 2755 "y.tab.c"
        break;

    case 254: /* cte_table  */
#line 421 "bison.y"
            { if(((*yyvaluep).cte_table_t)!=NULL)((*yyvaluep).cte_table_t)->deep_delete(); }
#line 2761 "y.tab.c"
        break;

    case 255: /* cte_table_name  */
#line 421 "bison.y"
            { if(((*yyvaluep).cte_table_name_t)!=NULL)((*yyvaluep).cte_table_name_t)->deep_delete(); }
#line 2767 "y.tab.c"
        break;

    case 256: /* opt_all_or_distinct  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_all_or_distinct_t)!=NULL)((*yyvaluep).opt_all_or_distinct_t)->deep_delete(); }
#line 2773 "y.tab.c"
        break;

    case 257: /* create_table_stmt  */
#line 421 "bison.y"
            { if(((*yyvaluep).create_table_stmt_t)!=NULL)((*yyvaluep).create_table_stmt_t)->deep_delete(); }
#line 2779 "y.tab.c"
        break;

    case 258: /* create_index_stmt  */
#line 421 "bison.y"
            { if(((*yyvaluep).create_index_stmt_t)!=NULL)((*yyvaluep).create_index_stmt_t)->deep_delete(); }
#line 2785 "y.tab.c"
        break;

    case 259: /* create_trigger_stmt  */
#line 421 "bison.y"
            { if(((*yyvaluep).create_trigger_stmt_t)!=NULL)((*yyvaluep).create_trigger_stmt_t)->deep_delete(); }
#line 2791 "y.tab.c"
        break;

    case 260: /* create_view_stmt  */
#line 421 "bison.y"
            { if(((*yyvaluep).create_view_stmt_t)!=NULL)((*yyvaluep).create_view_stmt_t)->deep_delete(); }
#line 2797 "y.tab.c"
        break;

    case 261: /* opt_table_option_list  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_table_option_list_t)!=NULL)((*yyvaluep).opt_table_option_list_t)->deep_delete(); }
#line 2803 "y.tab.c"
        break;

    case 262: /* table_option_list  */
#line 421 "bison.y"
            { if(((*yyvaluep).table_option_list_t)!=NULL)((*yyvaluep).table_option_list_t)->deep_delete(); }
#line 2809 "y.tab.c"
        break;

    case 263: /* table_option  */
#line 421 "bison.y"
            { if(((*yyvaluep).table_option_t)!=NULL)((*yyvaluep).table_option_t)->deep_delete(); }
#line 2815 "y.tab.c"
        break;

    case 264: /* opt_op_comma  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_op_comma_t)!=NULL)((*yyvaluep).opt_op_comma_t)->deep_delete(); }
#line 2821 "y.tab.c"
        break;

    case 265: /* opt_ignore_or_replace  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_ignore_or_replace_t)!=NULL)((*yyvaluep).opt_ignore_or_replace_t)->deep_delete(); }
#line 2827 "y.tab.c"
        break;

    case 266: /* opt_view_algorithm  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_view_algorithm_t)!=NULL)((*yyvaluep).opt_view_algorithm_t)->deep_delete(); }
#line 2833 "y.tab.c"
        break;

    case 267: /* opt_sql_security  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_sql_security_t)!=NULL)((*yyvaluep).opt_sql_security_t)->deep_delete(); }
#line 2839 "y.tab.c"
        break;

    case 268: /* opt_index_option  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_index_option_t)!=NULL)((*yyvaluep).opt_index_option_t)->deep_delete(); }
#line 2845 "y.tab.c"
        break;

    case 269: /* opt_extra_option  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_extra_option_t)!=NULL)((*yyvaluep).opt_extra_option_t)->deep_delete(); }
#line 2851 "y.tab.c"
        break;

    case 270: /* index_algorithm_option  */
#line 421 "bison.y"
            { if(((*yyvaluep).index_algorithm_option_t)!=NULL)((*yyvaluep).index_algorithm_option_t)->deep_delete(); }
#line 2857 "y.tab.c"
        break;

    case 271: /* lock_option  */
#line 421 "bison.y"
            { if(((*yyvaluep).lock_option_t)!=NULL)((*yyvaluep).lock_option_t)->deep_delete(); }
#line 2863 "y.tab.c"
        break;

    case 272: /* opt_op_equal  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_op_equal_t)!=NULL)((*yyvaluep).opt_op_equal_t)->deep_delete(); }
#line 2869 "y.tab.c"
        break;

    case 273: /* trigger_events  */
#line 421 "bison.y"
            { if(((*yyvaluep).trigger_events_t)!=NULL)((*yyvaluep).trigger_events_t)->deep_delete(); }
#line 2875 "y.tab.c"
        break;

    case 274: /* trigger_name  */
#line 421 "bison.y"
            { if(((*yyvaluep).trigger_name_t)!=NULL)((*yyvaluep).trigger_name_t)->deep_delete(); }
#line 2881 "y.tab.c"
        break;

    case 275: /* trigger_action_time  */
#line 421 "bison.y"
            { if(((*yyvaluep).trigger_action_time_t)!=NULL)((*yyvaluep).trigger_action_time_t)->deep_delete(); }
#line 2887 "y.tab.c"
        break;

    case 276: /* drop_index_stmt  */
#line 421 "bison.y"
            { if(((*yyvaluep).drop_index_stmt_t)!=NULL)((*yyvaluep).drop_index_stmt_t)->deep_delete(); }
#line 2893 "y.tab.c"
        break;

    case 277: /* drop_table_stmt  */
#line 421 "bison.y"
            { if(((*yyvaluep).drop_table_stmt_t)!=NULL)((*yyvaluep).drop_table_stmt_t)->deep_delete(); }
#line 2899 "y.tab.c"
        break;

    case 278: /* opt_restrict_or_cascade  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_restrict_or_cascade_t)!=NULL)((*yyvaluep).opt_restrict_or_cascade_t)->deep_delete(); }
#line 2905 "y.tab.c"
        break;

    case 279: /* drop_trigger_stmt  */
#line 421 "bison.y"
            { if(((*yyvaluep).drop_trigger_stmt_t)!=NULL)((*yyvaluep).drop_trigger_stmt_t)->deep_delete(); }
#line 2911 "y.tab.c"
        break;

    case 280: /* drop_view_stmt  */
#line 421 "bison.y"
            { if(((*yyvaluep).drop_view_stmt_t)!=NULL)((*yyvaluep).drop_view_stmt_t)->deep_delete(); }
#line 2917 "y.tab.c"
        break;

    case 281: /* insert_stmt  */
#line 421 "bison.y"
            { if(((*yyvaluep).insert_stmt_t)!=NULL)((*yyvaluep).insert_stmt_t)->deep_delete(); }
#line 2923 "y.tab.c"
        break;

    case 282: /* insert_rest  */
#line 421 "bison.y"
            { if(((*yyvaluep).insert_rest_t)!=NULL)((*yyvaluep).insert_rest_t)->deep_delete(); }
#line 2929 "y.tab.c"
        break;

    case 283: /* super_values_list  */
#line 421 "bison.y"
            { if(((*yyvaluep).super_values_list_t)!=NULL)((*yyvaluep).super_values_list_t)->deep_delete(); }
#line 2935 "y.tab.c"
        break;

    case 284: /* values_list  */
#line 421 "bison.y"
            { if(((*yyvaluep).values_list_t)!=NULL)((*yyvaluep).values_list_t)->deep_delete(); }
#line 2941 "y.tab.c"
        break;

    case 285: /* opt_on_conflict  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_on_conflict_t)!=NULL)((*yyvaluep).opt_on_conflict_t)->deep_delete(); }
#line 2947 "y.tab.c"
        break;

    case 286: /* opt_conflict_expr  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_conflict_expr_t)!=NULL)((*yyvaluep).opt_conflict_expr_t)->deep_delete(); }
#line 2953 "y.tab.c"
        break;

    case 287: /* indexed_column_list  */
#line 421 "bison.y"
            { if(((*yyvaluep).indexed_column_list_t)!=NULL)((*yyvaluep).indexed_column_list_t)->deep_delete(); }
#line 2959 "y.tab.c"
        break;

    case 288: /* indexed_column  */
#line 421 "bison.y"
            { if(((*yyvaluep).indexed_column_t)!=NULL)((*yyvaluep).indexed_column_t)->deep_delete(); }
#line 2965 "y.tab.c"
        break;

    case 289: /* update_stmt  */
#line 421 "bison.y"
            { if(((*yyvaluep).update_stmt_t)!=NULL)((*yyvaluep).update_stmt_t)->deep_delete(); }
#line 2971 "y.tab.c"
        break;

    case 290: /* alter_action  */
#line 421 "bison.y"
            { if(((*yyvaluep).alter_action_t)!=NULL)((*yyvaluep).alter_action_t)->deep_delete(); }
#line 2977 "y.tab.c"
        break;

    case 291: /* alter_constant_action  */
#line 421 "bison.y"
            { if(((*yyvaluep).alter_constant_action_t)!=NULL)((*yyvaluep).alter_constant_action_t)->deep_delete(); }
#line 2983 "y.tab.c"
        break;

    case 292: /* column_def_list  */
#line 421 "bison.y"
            { if(((*yyvaluep).column_def_list_t)!=NULL)((*yyvaluep).column_def_list_t)->deep_delete(); }
#line 2989 "y.tab.c"
        break;

    case 293: /* column_def  */
#line 421 "bison.y"
            { if(((*yyvaluep).column_def_t)!=NULL)((*yyvaluep).column_def_t)->deep_delete(); }
#line 2995 "y.tab.c"
        break;

    case 294: /* opt_column_constraint_list  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_column_constraint_list_t)!=NULL)((*yyvaluep).opt_column_constraint_list_t)->deep_delete(); }
#line 3001 "y.tab.c"
        break;

    case 295: /* column_constraint_list  */
#line 421 "bison.y"
            { if(((*yyvaluep).column_constraint_list_t)!=NULL)((*yyvaluep).column_constraint_list_t)->deep_delete(); }
#line 3007 "y.tab.c"
        break;

    case 296: /* column_constraint  */
#line 421 "bison.y"
            { if(((*yyvaluep).column_constraint_t)!=NULL)((*yyvaluep).column_constraint_t)->deep_delete(); }
#line 3013 "y.tab.c"
        break;

    case 297: /* opt_reference_clause  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_reference_clause_t)!=NULL)((*yyvaluep).opt_reference_clause_t)->deep_delete(); }
#line 3019 "y.tab.c"
        break;

    case 298: /* opt_check  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_check_t)!=NULL)((*yyvaluep).opt_check_t)->deep_delete(); }
#line 3025 "y.tab.c"
        break;

    case 299: /* constraint_type  */
#line 421 "bison.y"
            { if(((*yyvaluep).constraint_type_t)!=NULL)((*yyvaluep).constraint_type_t)->deep_delete(); }
#line 3031 "y.tab.c"
        break;

    case 300: /* reference_clause  */
#line 421 "bison.y"
            { if(((*yyvaluep).reference_clause_t)!=NULL)((*yyvaluep).reference_clause_t)->deep_delete(); }
#line 3037 "y.tab.c"
        break;

    case 301: /* opt_foreign_key  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_foreign_key_t)!=NULL)((*yyvaluep).opt_foreign_key_t)->deep_delete(); }
#line 3043 "y.tab.c"
        break;

    case 302: /* opt_foreign_key_actions  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_foreign_key_actions_t)!=NULL)((*yyvaluep).opt_foreign_key_actions_t)->deep_delete(); }
#line 3049 "y.tab.c"
        break;

    case 303: /* foreign_key_actions  */
#line 421 "bison.y"
            { if(((*yyvaluep).foreign_key_actions_t)!=NULL)((*yyvaluep).foreign_key_actions_t)->deep_delete(); }
#line 3055 "y.tab.c"
        break;

    case 304: /* key_actions  */
#line 421 "bison.y"
            { if(((*yyvaluep).key_actions_t)!=NULL)((*yyvaluep).key_actions_t)->deep_delete(); }
#line 3061 "y.tab.c"
        break;

    case 305: /* opt_constraint_attribute_spec  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_constraint_attribute_spec_t)!=NULL)((*yyvaluep).opt_constraint_attribute_spec_t)->deep_delete(); }
#line 3067 "y.tab.c"
        break;

    case 306: /* opt_initial_time  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_initial_time_t)!=NULL)((*yyvaluep).opt_initial_time_t)->deep_delete(); }
#line 3073 "y.tab.c"
        break;

    case 307: /* constraint_name  */
#line 421 "bison.y"
            { if(((*yyvaluep).constraint_name_t)!=NULL)((*yyvaluep).constraint_name_t)->deep_delete(); }
#line 3079 "y.tab.c"
        break;

    case 308: /* opt_temp  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_temp_t)!=NULL)((*yyvaluep).opt_temp_t)->deep_delete(); }
#line 3085 "y.tab.c"
        break;

    case 309: /* opt_check_option  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_check_option_t)!=NULL)((*yyvaluep).opt_check_option_t)->deep_delete(); }
#line 3091 "y.tab.c"
        break;

    case 310: /* opt_column_name_list_p  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_column_name_list_p_t)!=NULL)((*yyvaluep).opt_column_name_list_p_t)->deep_delete(); }
#line 3097 "y.tab.c"
        break;

    case 311: /* set_clause_list  */
#line 421 "bison.y"
            { if(((*yyvaluep).set_clause_list_t)!=NULL)((*yyvaluep).set_clause_list_t)->deep_delete(); }
#line 3103 "y.tab.c"
        break;

    case 312: /* set_clause  */
#line 421 "bison.y"
            { if(((*yyvaluep).set_clause_t)!=NULL)((*yyvaluep).set_clause_t)->deep_delete(); }
#line 3109 "y.tab.c"
        break;

    case 313: /* opt_as_alias  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_as_alias_t)!=NULL)((*yyvaluep).opt_as_alias_t)->deep_delete(); }
#line 3115 "y.tab.c"
        break;

    case 314: /* expr  */
#line 421 "bison.y"
            { if(((*yyvaluep).expr_t)!=NULL)((*yyvaluep).expr_t)->deep_delete(); }
#line 3121 "y.tab.c"
        break;

    case 315: /* operand  */
#line 421 "bison.y"
            { if(((*yyvaluep).operand_t)!=NULL)((*yyvaluep).operand_t)->deep_delete(); }
#line 3127 "y.tab.c"
        break;

    case 316: /* cast_expr  */
#line 421 "bison.y"
            { if(((*yyvaluep).cast_expr_t)!=NULL)((*yyvaluep).cast_expr_t)->deep_delete(); }
#line 3133 "y.tab.c"
        break;

    case 317: /* scalar_expr  */
#line 421 "bison.y"
            { if(((*yyvaluep).scalar_expr_t)!=NULL)((*yyvaluep).scalar_expr_t)->deep_delete(); }
#line 3139 "y.tab.c"
        break;

    case 318: /* unary_expr  */
#line 421 "bison.y"
            { if(((*yyvaluep).unary_expr_t)!=NULL)((*yyvaluep).unary_expr_t)->deep_delete(); }
#line 3145 "y.tab.c"
        break;

    case 319: /* binary_expr  */
#line 421 "bison.y"
            { if(((*yyvaluep).binary_expr_t)!=NULL)((*yyvaluep).binary_expr_t)->deep_delete(); }
#line 3151 "y.tab.c"
        break;

    case 320: /* logic_expr  */
#line 421 "bison.y"
            { if(((*yyvaluep).logic_expr_t)!=NULL)((*yyvaluep).logic_expr_t)->deep_delete(); }
#line 3157 "y.tab.c"
        break;

    case 321: /* in_expr  */
#line 421 "bison.y"
            { if(((*yyvaluep).in_expr_t)!=NULL)((*yyvaluep).in_expr_t)->deep_delete(); }
#line 3163 "y.tab.c"
        break;

    case 322: /* case_expr  */
#line 421 "bison.y"
            { if(((*yyvaluep).case_expr_t)!=NULL)((*yyvaluep).case_expr_t)->deep_delete(); }
#line 3169 "y.tab.c"
        break;

    case 323: /* between_expr  */
#line 421 "bison.y"
            { if(((*yyvaluep).between_expr_t)!=NULL)((*yyvaluep).between_expr_t)->deep_delete(); }
#line 3175 "y.tab.c"
        break;

    case 324: /* exists_expr  */
#line 421 "bison.y"
            { if(((*yyvaluep).exists_expr_t)!=NULL)((*yyvaluep).exists_expr_t)->deep_delete(); }
#line 3181 "y.tab.c"
        break;

    case 325: /* function_expr  */
#line 421 "bison.y"
            { if(((*yyvaluep).function_expr_t)!=NULL)((*yyvaluep).function_expr_t)->deep_delete(); }
#line 3187 "y.tab.c"
        break;

    case 326: /* opt_distinct  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_distinct_t)!=NULL)((*yyvaluep).opt_distinct_t)->deep_delete(); }
#line 3193 "y.tab.c"
        break;

    case 327: /* opt_filter_clause  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_filter_clause_t)!=NULL)((*yyvaluep).opt_filter_clause_t)->deep_delete(); }
#line 3199 "y.tab.c"
        break;

    case 328: /* opt_over_clause  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_over_clause_t)!=NULL)((*yyvaluep).opt_over_clause_t)->deep_delete(); }
#line 3205 "y.tab.c"
        break;

    case 329: /* case_list  */
#line 421 "bison.y"
            { if(((*yyvaluep).case_list_t)!=NULL)((*yyvaluep).case_list_t)->deep_delete(); }
#line 3211 "y.tab.c"
        break;

    case 330: /* case_clause  */
#line 421 "bison.y"
            { if(((*yyvaluep).case_clause_t)!=NULL)((*yyvaluep).case_clause_t)->deep_delete(); }
#line 3217 "y.tab.c"
        break;

    case 331: /* comp_expr  */
#line 421 "bison.y"
            { if(((*yyvaluep).comp_expr_t)!=NULL)((*yyvaluep).comp_expr_t)->deep_delete(); }
#line 3223 "y.tab.c"
        break;

    case 332: /* extract_expr  */
#line 421 "bison.y"
            { if(((*yyvaluep).extract_expr_t)!=NULL)((*yyvaluep).extract_expr_t)->deep_delete(); }
#line 3229 "y.tab.c"
        break;

    case 333: /* datetime_field  */
#line 421 "bison.y"
            { if(((*yyvaluep).datetime_field_t)!=NULL)((*yyvaluep).datetime_field_t)->deep_delete(); }
#line 3235 "y.tab.c"
        break;

    case 334: /* array_expr  */
#line 421 "bison.y"
            { if(((*yyvaluep).array_expr_t)!=NULL)((*yyvaluep).array_expr_t)->deep_delete(); }
#line 3241 "y.tab.c"
        break;

    case 335: /* array_index  */
#line 421 "bison.y"
            { if(((*yyvaluep).array_index_t)!=NULL)((*yyvaluep).array_index_t)->deep_delete(); }
#line 3247 "y.tab.c"
        break;

    case 336: /* literal  */
#line 421 "bison.y"
            { if(((*yyvaluep).literal_t)!=NULL)((*yyvaluep).literal_t)->deep_delete(); }
#line 3253 "y.tab.c"
        break;

    case 337: /* string_literal  */
#line 421 "bison.y"
            { if(((*yyvaluep).string_literal_t)!=NULL)((*yyvaluep).string_literal_t)->deep_delete(); }
#line 3259 "y.tab.c"
        break;

    case 338: /* bool_literal  */
#line 421 "bison.y"
            { if(((*yyvaluep).bool_literal_t)!=NULL)((*yyvaluep).bool_literal_t)->deep_delete(); }
#line 3265 "y.tab.c"
        break;

    case 339: /* num_literal  */
#line 421 "bison.y"
            { if(((*yyvaluep).num_literal_t)!=NULL)((*yyvaluep).num_literal_t)->deep_delete(); }
#line 3271 "y.tab.c"
        break;

    case 340: /* int_literal  */
#line 421 "bison.y"
            { if(((*yyvaluep).int_literal_t)!=NULL)((*yyvaluep).int_literal_t)->deep_delete(); }
#line 3277 "y.tab.c"
        break;

    case 341: /* float_literal  */
#line 421 "bison.y"
            { if(((*yyvaluep).float_literal_t)!=NULL)((*yyvaluep).float_literal_t)->deep_delete(); }
#line 3283 "y.tab.c"
        break;

    case 342: /* opt_column  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_column_t)!=NULL)((*yyvaluep).opt_column_t)->deep_delete(); }
#line 3289 "y.tab.c"
        break;

    case 343: /* trigger_body  */
#line 421 "bison.y"
            { if(((*yyvaluep).trigger_body_t)!=NULL)((*yyvaluep).trigger_body_t)->deep_delete(); }
#line 3295 "y.tab.c"
        break;

    case 344: /* opt_if_not_exist  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_if_not_exist_t)!=NULL)((*yyvaluep).opt_if_not_exist_t)->deep_delete(); }
#line 3301 "y.tab.c"
        break;

    case 345: /* opt_if_exist  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_if_exist_t)!=NULL)((*yyvaluep).opt_if_exist_t)->deep_delete(); }
#line 3307 "y.tab.c"
        break;

    case 346: /* identifier  */
#line 421 "bison.y"
            { if(((*yyvaluep).identifier_t)!=NULL)((*yyvaluep).identifier_t)->deep_delete(); }
#line 3313 "y.tab.c"
        break;

    case 347: /* as_alias  */
#line 421 "bison.y"
            { if(((*yyvaluep).as_alias_t)!=NULL)((*yyvaluep).as_alias_t)->deep_delete(); }
#line 3319 "y.tab.c"
        break;

    case 348: /* table_name  */
#line 421 "bison.y"
            { if(((*yyvaluep).table_name_t)!=NULL)((*yyvaluep).table_name_t)->deep_delete(); }
#line 3325 "y.tab.c"
        break;

    case 349: /* column_name  */
#line 421 "bison.y"
            { if(((*yyvaluep).column_name_t)!=NULL)((*yyvaluep).column_name_t)->deep_delete(); }
#line 3331 "y.tab.c"
        break;

    case 350: /* opt_index_keyword  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_index_keyword_t)!=NULL)((*yyvaluep).opt_index_keyword_t)->deep_delete(); }
#line 3337 "y.tab.c"
        break;

    case 351: /* view_name  */
#line 421 "bison.y"
            { if(((*yyvaluep).view_name_t)!=NULL)((*yyvaluep).view_name_t)->deep_delete(); }
#line 3343 "y.tab.c"
        break;

    case 352: /* function_name  */
#line 421 "bison.y"
            { if(((*yyvaluep).function_name_t)!=NULL)((*yyvaluep).function_name_t)->deep_delete(); }
#line 3349 "y.tab.c"
        break;

    case 353: /* binary_op  */
#line 421 "bison.y"
            { if(((*yyvaluep).binary_op_t)!=NULL)((*yyvaluep).binary_op_t)->deep_delete(); }
#line 3355 "y.tab.c"
        break;

    case 354: /* opt_not  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_not_t)!=NULL)((*yyvaluep).opt_not_t)->deep_delete(); }
#line 3361 "y.tab.c"
        break;

    case 355: /* name  */
#line 421 "bison.y"
            { if(((*yyvaluep).name_t)!=NULL)((*yyvaluep).name_t)->deep_delete(); }
#line 3367 "y.tab.c"
        break;

    case 356: /* type_name  */
#line 421 "bison.y"
            { if(((*yyvaluep).type_name_t)!=NULL)((*yyvaluep).type_name_t)->deep_delete(); }
#line 3373 "y.tab.c"
        break;

    case 357: /* character_type  */
#line 421 "bison.y"
            { if(((*yyvaluep).character_type_t)!=NULL)((*yyvaluep).character_type_t)->deep_delete(); }
#line 3379 "y.tab.c"
        break;

    case 358: /* character_with_length  */
#line 421 "bison.y"
            { if(((*yyvaluep).character_with_length_t)!=NULL)((*yyvaluep).character_with_length_t)->deep_delete(); }
#line 3385 "y.tab.c"
        break;

    case 359: /* character_without_length  */
#line 421 "bison.y"
            { if(((*yyvaluep).character_without_length_t)!=NULL)((*yyvaluep).character_without_length_t)->deep_delete(); }
#line 3391 "y.tab.c"
        break;

    case 360: /* character_conflicta  */
#line 421 "bison.y"
            { if(((*yyvaluep).character_conflicta_t)!=NULL)((*yyvaluep).character_conflicta_t)->deep_delete(); }
#line 3397 "y.tab.c"
        break;

    case 361: /* numeric_type  */
#line 421 "bison.y"
            { if(((*yyvaluep).numeric_type_t)!=NULL)((*yyvaluep).numeric_type_t)->deep_delete(); }
#line 3403 "y.tab.c"
        break;

    case 362: /* opt_table_constraint_list  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_table_constraint_list_t)!=NULL)((*yyvaluep).opt_table_constraint_list_t)->deep_delete(); }
#line 3409 "y.tab.c"
        break;

    case 363: /* table_constraint_list  */
#line 421 "bison.y"
            { if(((*yyvaluep).table_constraint_list_t)!=NULL)((*yyvaluep).table_constraint_list_t)->deep_delete(); }
#line 3415 "y.tab.c"
        break;

    case 364: /* table_constraint  */
#line 421 "bison.y"
            { if(((*yyvaluep).table_constraint_t)!=NULL)((*yyvaluep).table_constraint_t)->deep_delete(); }
#line 3421 "y.tab.c"
        break;

    case 365: /* opt_enforced  */
#line 421 "bison.y"
            { if(((*yyvaluep).opt_enforced_t)!=NULL)((*yyvaluep).opt_enforced_t)->deep_delete(); }
#line 3427 "y.tab.c"
        break;

      default:
        break;
    }
  YY_IGNORE_MAYBE_UNINITIALIZED_END
}




/*----------.
| yyparse.  |
`----------*/

int
yyparse (Program* result, yyscan_t scanner)
{
/* The lookahead symbol.  */
int yychar;


/* The semantic value of the lookahead symbol.  */
/* Default value used for initialization, for pacifying older GCCs
   or non-GCC compilers.  */
YY_INITIAL_VALUE (static YYSTYPE yyval_default;)
YYSTYPE yylval YY_INITIAL_VALUE (= yyval_default);

/* Location data for the lookahead symbol.  */
static YYLTYPE yyloc_default
# if defined FF_LTYPE_IS_TRIVIAL && FF_LTYPE_IS_TRIVIAL
  = { 1, 1, 1, 1 }
# endif
;
YYLTYPE yylloc = yyloc_default;

    /* Number of syntax errors so far.  */
    int yynerrs;

    yy_state_fast_t yystate;
    /* Number of tokens to shift before error messages enabled.  */
    int yyerrstatus;

    /* The stacks and their tools:
       'yyss': related to states.
       'yyvs': related to semantic values.
       'yyls': related to locations.

       Refer to the stacks through separate pointers, to allow yyoverflow
       to reallocate them elsewhere.  */

    /* The state stack.  */
    yy_state_t yyssa[YYINITDEPTH];
    yy_state_t *yyss;
    yy_state_t *yyssp;

    /* The semantic value stack.  */
    YYSTYPE yyvsa[YYINITDEPTH];
    YYSTYPE *yyvs;
    YYSTYPE *yyvsp;

    /* The location stack.  */
    YYLTYPE yylsa[YYINITDEPTH];
    YYLTYPE *yyls;
    YYLTYPE *yylsp;

    /* The locations where the error started and ended.  */
    YYLTYPE yyerror_range[3];

    YYPTRDIFF_T yystacksize;

  int yyn;
  int yyresult;
  /* Lookahead token as an internal (translated) token number.  */
  int yytoken = 0;
  /* The variables used to return semantic value and location from the
     action routines.  */
  YYSTYPE yyval;
  YYLTYPE yyloc;

#if YYERROR_VERBOSE
  /* Buffer for error messages, and its allocated size.  */
  char yymsgbuf[128];
  char *yymsg = yymsgbuf;
  YYPTRDIFF_T yymsg_alloc = sizeof yymsgbuf;
#endif

#define YYPOPSTACK(N)   (yyvsp -= (N), yyssp -= (N), yylsp -= (N))

  /* The number of symbols on the RHS of the reduced rule.
     Keep to zero when no symbol should be popped.  */
  int yylen = 0;

  yyssp = yyss = yyssa;
  yyvsp = yyvs = yyvsa;
  yylsp = yyls = yylsa;
  yystacksize = YYINITDEPTH;

  YYDPRINTF ((stderr, "Starting parse\n"));

  yystate = 0;
  yyerrstatus = 0;
  yynerrs = 0;
  yychar = YYEMPTY; /* Cause a token to be read.  */

/* User initialization code.  */
#line 18 "bison.y"
{
    // Initialize
    yylloc.first_column = 0;
    yylloc.last_column = 0;
    yylloc.first_line = 0;
    yylloc.last_line = 0;
    yylloc.total_column = 0;
    yylloc.string_length = 0;
}

#line 3545 "y.tab.c"

  yylsp[0] = yylloc;
  goto yysetstate;


/*------------------------------------------------------------.
| yynewstate -- push a new state, which is found in yystate.  |
`------------------------------------------------------------*/
yynewstate:
  /* In all cases, when you get here, the value and location stacks
     have just been pushed.  So pushing a state here evens the stacks.  */
  yyssp++;


/*--------------------------------------------------------------------.
| yysetstate -- set current state (the top of the stack) to yystate.  |
`--------------------------------------------------------------------*/
yysetstate:
  YYDPRINTF ((stderr, "Entering state %d\n", yystate));
  YY_ASSERT (0 <= yystate && yystate < YYNSTATES);
  YY_IGNORE_USELESS_CAST_BEGIN
  *yyssp = YY_CAST (yy_state_t, yystate);
  YY_IGNORE_USELESS_CAST_END

  if (yyss + yystacksize - 1 <= yyssp)
#if !defined yyoverflow && !defined YYSTACK_RELOCATE
    goto yyexhaustedlab;
#else
    {
      /* Get the current used size of the three stacks, in elements.  */
      YYPTRDIFF_T yysize = yyssp - yyss + 1;

# if defined yyoverflow
      {
        /* Give user a chance to reallocate the stack.  Use copies of
           these so that the &'s don't force the real ones into
           memory.  */
        yy_state_t *yyss1 = yyss;
        YYSTYPE *yyvs1 = yyvs;
        YYLTYPE *yyls1 = yyls;

        /* Each stack pointer address is followed by the size of the
           data in use in that stack, in bytes.  This used to be a
           conditional around just the two extra args, but that might
           be undefined if yyoverflow is a macro.  */
        yyoverflow (YY_("memory exhausted"),
                    &yyss1, yysize * YYSIZEOF (*yyssp),
                    &yyvs1, yysize * YYSIZEOF (*yyvsp),
                    &yyls1, yysize * YYSIZEOF (*yylsp),
                    &yystacksize);
        yyss = yyss1;
        yyvs = yyvs1;
        yyls = yyls1;
      }
# else /* defined YYSTACK_RELOCATE */
      /* Extend the stack our own way.  */
      if (YYMAXDEPTH <= yystacksize)
        goto yyexhaustedlab;
      yystacksize *= 2;
      if (YYMAXDEPTH < yystacksize)
        yystacksize = YYMAXDEPTH;

      {
        yy_state_t *yyss1 = yyss;
        union yyalloc *yyptr =
          YY_CAST (union yyalloc *,
                   YYSTACK_ALLOC (YY_CAST (YYSIZE_T, YYSTACK_BYTES (yystacksize))));
        if (! yyptr)
          goto yyexhaustedlab;
        YYSTACK_RELOCATE (yyss_alloc, yyss);
        YYSTACK_RELOCATE (yyvs_alloc, yyvs);
        YYSTACK_RELOCATE (yyls_alloc, yyls);
# undef YYSTACK_RELOCATE
        if (yyss1 != yyssa)
          YYSTACK_FREE (yyss1);
      }
# endif

      yyssp = yyss + yysize - 1;
      yyvsp = yyvs + yysize - 1;
      yylsp = yyls + yysize - 1;

      YY_IGNORE_USELESS_CAST_BEGIN
      YYDPRINTF ((stderr, "Stack size increased to %ld\n",
                  YY_CAST (long, yystacksize)));
      YY_IGNORE_USELESS_CAST_END

      if (yyss + yystacksize - 1 <= yyssp)
        YYABORT;
    }
#endif /* !defined yyoverflow && !defined YYSTACK_RELOCATE */

  if (yystate == YYFINAL)
    YYACCEPT;

  goto yybackup;


/*-----------.
| yybackup.  |
`-----------*/
yybackup:
  /* Do appropriate processing given the current state.  Read a
     lookahead token if we need one and don't already have one.  */

  /* First try to decide what to do without reference to lookahead token.  */
  yyn = yypact[yystate];
  if (yypact_value_is_default (yyn))
    goto yydefault;

  /* Not known => get a lookahead token if don't already have one.  */

  /* YYCHAR is either YYEMPTY or YYEOF or a valid lookahead symbol.  */
  if (yychar == YYEMPTY)
    {
      YYDPRINTF ((stderr, "Reading a token: "));
      yychar = yylex (&yylval, &yylloc, scanner);
    }

  if (yychar <= YYEOF)
    {
      yychar = yytoken = YYEOF;
      YYDPRINTF ((stderr, "Now at end of input.\n"));
    }
  else
    {
      yytoken = YYTRANSLATE (yychar);
      YY_SYMBOL_PRINT ("Next token is", yytoken, &yylval, &yylloc);
    }

  /* If the proper action on seeing token YYTOKEN is to reduce or to
     detect an error, take that action.  */
  yyn += yytoken;
  if (yyn < 0 || YYLAST < yyn || yycheck[yyn] != yytoken)
    goto yydefault;
  yyn = yytable[yyn];
  if (yyn <= 0)
    {
      if (yytable_value_is_error (yyn))
        goto yyerrlab;
      yyn = -yyn;
      goto yyreduce;
    }

  /* Count tokens shifted since error; after three, turn off error
     status.  */
  if (yyerrstatus)
    yyerrstatus--;

  /* Shift the lookahead token.  */
  YY_SYMBOL_PRINT ("Shifting", yytoken, &yylval, &yylloc);
  yystate = yyn;
  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  *++yyvsp = yylval;
  YY_IGNORE_MAYBE_UNINITIALIZED_END
  *++yylsp = yylloc;

  /* Discard the shifted token.  */
  yychar = YYEMPTY;
  goto yynewstate;


/*-----------------------------------------------------------.
| yydefault -- do the default action for the current state.  |
`-----------------------------------------------------------*/
yydefault:
  yyn = yydefact[yystate];
  if (yyn == 0)
    goto yyerrlab;
  goto yyreduce;


/*-----------------------------.
| yyreduce -- do a reduction.  |
`-----------------------------*/
yyreduce:
  /* yyn is the number of a rule to reduce with.  */
  yylen = yyr2[yyn];

  /* If YYLEN is nonzero, implement the default value of the action:
     '$$ = $1'.

     Otherwise, the following line sets YYVAL to garbage.
     This behavior is undocumented and Bison
     users should not rely upon it.  Assigning to YYVAL
     unconditionally makes the parser a bit smaller, and it avoids a
     GCC warning that YYVAL may be used uninitialized.  */
  yyval = yyvsp[1-yylen];

  /* Default location. */
  YYLLOC_DEFAULT (yyloc, (yylsp - yylen), yylen);
  yyerror_range[1] = yyloc;
  YY_REDUCE_PRINT (yyn);
  switch (yyn)
    {
  case 2:
#line 425 "bison.y"
                  {
		(yyval.program_t) = result;
		(yyval.program_t)->case_idx_ = CASE0;
		(yyval.program_t)->stmtlist_ = (yyvsp[0].stmtlist_t);
				(yyval.program_t) = NULL;

	}
#line 3750 "y.tab.c"
    break;

  case 3:
#line 435 "bison.y"
                               {
		(yyval.stmtlist_t) = new Stmtlist();
		(yyval.stmtlist_t)->case_idx_ = CASE0;
		(yyval.stmtlist_t)->stmt_ = (yyvsp[-2].stmt_t);
		(yyval.stmtlist_t)->stmtlist_ = (yyvsp[0].stmtlist_t);
		
	}
#line 3762 "y.tab.c"
    break;

  case 4:
#line 442 "bison.y"
                      {
		(yyval.stmtlist_t) = new Stmtlist();
		(yyval.stmtlist_t)->case_idx_ = CASE1;
		(yyval.stmtlist_t)->stmt_ = (yyvsp[-1].stmt_t);
		
	}
#line 3773 "y.tab.c"
    break;

  case 5:
#line 451 "bison.y"
                     {
		(yyval.stmt_t) = new Stmt();
		(yyval.stmt_t)->case_idx_ = CASE0;
		(yyval.stmt_t)->create_stmt_ = (yyvsp[0].create_stmt_t);
		
	}
#line 3784 "y.tab.c"
    break;

  case 6:
#line 457 "bison.y"
                   {
		(yyval.stmt_t) = new Stmt();
		(yyval.stmt_t)->case_idx_ = CASE1;
		(yyval.stmt_t)->drop_stmt_ = (yyvsp[0].drop_stmt_t);
		
	}
#line 3795 "y.tab.c"
    break;

  case 7:
#line 463 "bison.y"
                     {
		(yyval.stmt_t) = new Stmt();
		(yyval.stmt_t)->case_idx_ = CASE2;
		(yyval.stmt_t)->select_stmt_ = (yyvsp[0].select_stmt_t);
		
	}
#line 3806 "y.tab.c"
    break;

  case 8:
#line 469 "bison.y"
                     {
		(yyval.stmt_t) = new Stmt();
		(yyval.stmt_t)->case_idx_ = CASE3;
		(yyval.stmt_t)->update_stmt_ = (yyvsp[0].update_stmt_t);
		
	}
#line 3817 "y.tab.c"
    break;

  case 9:
#line 475 "bison.y"
                     {
		(yyval.stmt_t) = new Stmt();
		(yyval.stmt_t)->case_idx_ = CASE4;
		(yyval.stmt_t)->insert_stmt_ = (yyvsp[0].insert_stmt_t);
		
	}
#line 3828 "y.tab.c"
    break;

  case 10:
#line 481 "bison.y"
                    {
		(yyval.stmt_t) = new Stmt();
		(yyval.stmt_t)->case_idx_ = CASE5;
		(yyval.stmt_t)->alter_stmt_ = (yyvsp[0].alter_stmt_t);
		
	}
#line 3839 "y.tab.c"
    break;

  case 11:
#line 490 "bison.y"
                           {
		(yyval.create_stmt_t) = new CreateStmt();
		(yyval.create_stmt_t)->case_idx_ = CASE0;
		(yyval.create_stmt_t)->create_table_stmt_ = (yyvsp[0].create_table_stmt_t);
		
	}
#line 3850 "y.tab.c"
    break;

  case 12:
#line 496 "bison.y"
                           {
		(yyval.create_stmt_t) = new CreateStmt();
		(yyval.create_stmt_t)->case_idx_ = CASE1;
		(yyval.create_stmt_t)->create_index_stmt_ = (yyvsp[0].create_index_stmt_t);
		
	}
#line 3861 "y.tab.c"
    break;

  case 13:
#line 502 "bison.y"
                             {
		(yyval.create_stmt_t) = new CreateStmt();
		(yyval.create_stmt_t)->case_idx_ = CASE2;
		(yyval.create_stmt_t)->create_trigger_stmt_ = (yyvsp[0].create_trigger_stmt_t);
		
	}
#line 3872 "y.tab.c"
    break;

  case 14:
#line 508 "bison.y"
                          {
		(yyval.create_stmt_t) = new CreateStmt();
		(yyval.create_stmt_t)->case_idx_ = CASE3;
		(yyval.create_stmt_t)->create_view_stmt_ = (yyvsp[0].create_view_stmt_t);
		
	}
#line 3883 "y.tab.c"
    break;

  case 15:
#line 517 "bison.y"
                         {
		(yyval.drop_stmt_t) = new DropStmt();
		(yyval.drop_stmt_t)->case_idx_ = CASE0;
		(yyval.drop_stmt_t)->drop_index_stmt_ = (yyvsp[0].drop_index_stmt_t);
		
	}
#line 3894 "y.tab.c"
    break;

  case 16:
#line 523 "bison.y"
                         {
		(yyval.drop_stmt_t) = new DropStmt();
		(yyval.drop_stmt_t)->case_idx_ = CASE1;
		(yyval.drop_stmt_t)->drop_table_stmt_ = (yyvsp[0].drop_table_stmt_t);
		
	}
#line 3905 "y.tab.c"
    break;

  case 17:
#line 529 "bison.y"
                           {
		(yyval.drop_stmt_t) = new DropStmt();
		(yyval.drop_stmt_t)->case_idx_ = CASE2;
		(yyval.drop_stmt_t)->drop_trigger_stmt_ = (yyvsp[0].drop_trigger_stmt_t);
		
	}
#line 3916 "y.tab.c"
    break;

  case 18:
#line 535 "bison.y"
                        {
		(yyval.drop_stmt_t) = new DropStmt();
		(yyval.drop_stmt_t)->case_idx_ = CASE3;
		(yyval.drop_stmt_t)->drop_view_stmt_ = (yyvsp[0].drop_view_stmt_t);
		
	}
#line 3927 "y.tab.c"
    break;

  case 19:
#line 544 "bison.y"
                                             {
		(yyval.alter_stmt_t) = new AlterStmt();
		(yyval.alter_stmt_t)->case_idx_ = CASE0;
		(yyval.alter_stmt_t)->table_name_ = (yyvsp[-1].table_name_t);
		(yyval.alter_stmt_t)->alter_action_ = (yyvsp[0].alter_action_t);
		
	}
#line 3939 "y.tab.c"
    break;

  case 20:
#line 554 "bison.y"
                                      {
		(yyval.select_stmt_t) = new SelectStmt();
		(yyval.select_stmt_t)->case_idx_ = CASE0;
		(yyval.select_stmt_t)->select_no_parens_ = (yyvsp[0].select_no_parens_t);
		
	}
#line 3950 "y.tab.c"
    break;

  case 21:
#line 560 "bison.y"
                                        {
		(yyval.select_stmt_t) = new SelectStmt();
		(yyval.select_stmt_t)->case_idx_ = CASE1;
		(yyval.select_stmt_t)->select_with_parens_ = (yyvsp[0].select_with_parens_t);
		
	}
#line 3961 "y.tab.c"
    break;

  case 22:
#line 569 "bison.y"
                                      {
		(yyval.select_with_parens_t) = new SelectWithParens();
		(yyval.select_with_parens_t)->case_idx_ = CASE0;
		(yyval.select_with_parens_t)->select_no_parens_ = (yyvsp[-1].select_no_parens_t);
		
	}
#line 3972 "y.tab.c"
    break;

  case 23:
#line 575 "bison.y"
                                        {
		(yyval.select_with_parens_t) = new SelectWithParens();
		(yyval.select_with_parens_t)->case_idx_ = CASE1;
		(yyval.select_with_parens_t)->select_with_parens_ = (yyvsp[-1].select_with_parens_t);
		
	}
#line 3983 "y.tab.c"
    break;

  case 24:
#line 584 "bison.y"
                                                                              {
		(yyval.select_no_parens_t) = new SelectNoParens();
		(yyval.select_no_parens_t)->case_idx_ = CASE0;
		(yyval.select_no_parens_t)->opt_with_clause_ = (yyvsp[-3].opt_with_clause_t);
		(yyval.select_no_parens_t)->select_clause_list_ = (yyvsp[-2].select_clause_list_t);
		(yyval.select_no_parens_t)->opt_order_clause_ = (yyvsp[-1].opt_order_clause_t);
		(yyval.select_no_parens_t)->opt_limit_clause_ = (yyvsp[0].opt_limit_clause_t);
		
	}
#line 3997 "y.tab.c"
    break;

  case 25:
#line 596 "bison.y"
                       {
		(yyval.select_clause_list_t) = new SelectClauseList();
		(yyval.select_clause_list_t)->case_idx_ = CASE0;
		(yyval.select_clause_list_t)->select_clause_ = (yyvsp[0].select_clause_t);
		
	}
#line 4008 "y.tab.c"
    break;

  case 26:
#line 602 "bison.y"
                                                         {
		(yyval.select_clause_list_t) = new SelectClauseList();
		(yyval.select_clause_list_t)->case_idx_ = CASE1;
		(yyval.select_clause_list_t)->select_clause_ = (yyvsp[-2].select_clause_t);
		(yyval.select_clause_list_t)->combine_clause_ = (yyvsp[-1].combine_clause_t);
		(yyval.select_clause_list_t)->select_clause_list_ = (yyvsp[0].select_clause_list_t);
		
	}
#line 4021 "y.tab.c"
    break;

  case 27:
#line 613 "bison.y"
                                                                                                                      {
		(yyval.select_clause_t) = new SelectClause();
		(yyval.select_clause_t)->case_idx_ = CASE0;
		(yyval.select_clause_t)->opt_all_or_distinct_ = (yyvsp[-5].opt_all_or_distinct_t);
		(yyval.select_clause_t)->select_target_ = (yyvsp[-4].select_target_t);
		(yyval.select_clause_t)->opt_from_clause_ = (yyvsp[-3].opt_from_clause_t);
		(yyval.select_clause_t)->opt_where_clause_ = (yyvsp[-2].opt_where_clause_t);
		(yyval.select_clause_t)->opt_group_clause_ = (yyvsp[-1].opt_group_clause_t);
		(yyval.select_clause_t)->opt_window_clause_ = (yyvsp[0].opt_window_clause_t);
		
	}
#line 4037 "y.tab.c"
    break;

  case 28:
#line 627 "bison.y"
               {
		(yyval.combine_clause_t) = new CombineClause();
		(yyval.combine_clause_t)->case_idx_ = CASE0;
		
	}
#line 4047 "y.tab.c"
    break;

  case 29:
#line 632 "bison.y"
                   {
		(yyval.combine_clause_t) = new CombineClause();
		(yyval.combine_clause_t)->case_idx_ = CASE1;
		
	}
#line 4057 "y.tab.c"
    break;

  case 30:
#line 637 "bison.y"
                {
		(yyval.combine_clause_t) = new CombineClause();
		(yyval.combine_clause_t)->case_idx_ = CASE2;
		
	}
#line 4067 "y.tab.c"
    break;

  case 31:
#line 645 "bison.y"
                     {
		(yyval.opt_from_clause_t) = new OptFromClause();
		(yyval.opt_from_clause_t)->case_idx_ = CASE0;
		(yyval.opt_from_clause_t)->from_clause_ = (yyvsp[0].from_clause_t);
		
	}
#line 4078 "y.tab.c"
    break;

  case 32:
#line 651 "bison.y"
          {
		(yyval.opt_from_clause_t) = new OptFromClause();
		(yyval.opt_from_clause_t)->case_idx_ = CASE1;
		
	}
#line 4088 "y.tab.c"
    break;

  case 33:
#line 659 "bison.y"
                   {
		(yyval.select_target_t) = new SelectTarget();
		(yyval.select_target_t)->case_idx_ = CASE0;
		(yyval.select_target_t)->expr_list_ = (yyvsp[0].expr_list_t);
		
	}
#line 4099 "y.tab.c"
    break;

  case 34:
#line 668 "bison.y"
                       {
		(yyval.opt_window_clause_t) = new OptWindowClause();
		(yyval.opt_window_clause_t)->case_idx_ = CASE0;
		(yyval.opt_window_clause_t)->window_clause_ = (yyvsp[0].window_clause_t);
		
	}
#line 4110 "y.tab.c"
    break;

  case 35:
#line 674 "bison.y"
          {
		(yyval.opt_window_clause_t) = new OptWindowClause();
		(yyval.opt_window_clause_t)->case_idx_ = CASE1;
		
	}
#line 4120 "y.tab.c"
    break;

  case 36:
#line 682 "bison.y"
                                {
		(yyval.window_clause_t) = new WindowClause();
		(yyval.window_clause_t)->case_idx_ = CASE0;
		(yyval.window_clause_t)->window_def_list_ = (yyvsp[0].window_def_list_t);
		
	}
#line 4131 "y.tab.c"
    break;

  case 37:
#line 691 "bison.y"
                    {
		(yyval.window_def_list_t) = new WindowDefList();
		(yyval.window_def_list_t)->case_idx_ = CASE0;
		(yyval.window_def_list_t)->window_def_ = (yyvsp[0].window_def_t);
		
	}
#line 4142 "y.tab.c"
    break;

  case 38:
#line 697 "bison.y"
                                             {
		(yyval.window_def_list_t) = new WindowDefList();
		(yyval.window_def_list_t)->case_idx_ = CASE1;
		(yyval.window_def_list_t)->window_def_ = (yyvsp[-2].window_def_t);
		(yyval.window_def_list_t)->window_def_list_ = (yyvsp[0].window_def_list_t);
		
	}
#line 4154 "y.tab.c"
    break;

  case 39:
#line 707 "bison.y"
                                           {
		(yyval.window_def_t) = new WindowDef();
		(yyval.window_def_t)->case_idx_ = CASE0;
		(yyval.window_def_t)->window_name_ = (yyvsp[-4].window_name_t);
		(yyval.window_def_t)->window_ = (yyvsp[-1].window_t);
		if((yyval.window_def_t)){
			auto tmp1 = (yyval.window_def_t)->window_name_; 
			if(tmp1){
				auto tmp2 = tmp1->identifier_; 
				if(tmp2){
					tmp2->data_type_ = kDataWindowName; 
					tmp2->scope_ = 1; 
					tmp2->data_flag_ =(DATAFLAG)1; 
				}
			}
		}


	}
#line 4178 "y.tab.c"
    break;

  case 40:
#line 729 "bison.y"
                    {
		(yyval.window_name_t) = new WindowName();
		(yyval.window_name_t)->case_idx_ = CASE0;
		(yyval.window_name_t)->identifier_ = (yyvsp[0].identifier_t);
		
	}
#line 4189 "y.tab.c"
    break;

  case 41:
#line 738 "bison.y"
                                                                               {
		(yyval.window_t) = new Window();
		(yyval.window_t)->case_idx_ = CASE0;
		(yyval.window_t)->opt_exist_window_name_ = (yyvsp[-3].opt_exist_window_name_t);
		(yyval.window_t)->opt_partition_ = (yyvsp[-2].opt_partition_t);
		(yyval.window_t)->opt_order_clause_ = (yyvsp[-1].opt_order_clause_t);
		(yyval.window_t)->opt_frame_clause_ = (yyvsp[0].opt_frame_clause_t);
		
	}
#line 4203 "y.tab.c"
    break;

  case 42:
#line 750 "bison.y"
                                {
		(yyval.opt_partition_t) = new OptPartition();
		(yyval.opt_partition_t)->case_idx_ = CASE0;
		(yyval.opt_partition_t)->expr_list_ = (yyvsp[0].expr_list_t);
		
	}
#line 4214 "y.tab.c"
    break;

  case 43:
#line 756 "bison.y"
          {
		(yyval.opt_partition_t) = new OptPartition();
		(yyval.opt_partition_t)->case_idx_ = CASE1;
		
	}
#line 4224 "y.tab.c"
    break;

  case 44:
#line 764 "bison.y"
                                         {
		(yyval.opt_frame_clause_t) = new OptFrameClause();
		(yyval.opt_frame_clause_t)->case_idx_ = CASE0;
		(yyval.opt_frame_clause_t)->range_or_rows_ = (yyvsp[-1].range_or_rows_t);
		(yyval.opt_frame_clause_t)->frame_bound_start_ = (yyvsp[0].frame_bound_start_t);
		
	}
#line 4236 "y.tab.c"
    break;

  case 45:
#line 771 "bison.y"
                                                                     {
		(yyval.opt_frame_clause_t) = new OptFrameClause();
		(yyval.opt_frame_clause_t)->case_idx_ = CASE1;
		(yyval.opt_frame_clause_t)->range_or_rows_ = (yyvsp[-4].range_or_rows_t);
		(yyval.opt_frame_clause_t)->frame_bound_start_ = (yyvsp[-2].frame_bound_start_t);
		(yyval.opt_frame_clause_t)->frame_bound_end_ = (yyvsp[0].frame_bound_end_t);
		
	}
#line 4249 "y.tab.c"
    break;

  case 46:
#line 779 "bison.y"
          {
		(yyval.opt_frame_clause_t) = new OptFrameClause();
		(yyval.opt_frame_clause_t)->case_idx_ = CASE2;
		
	}
#line 4259 "y.tab.c"
    break;

  case 47:
#line 787 "bison.y"
               {
		(yyval.range_or_rows_t) = new RangeOrRows();
		(yyval.range_or_rows_t)->case_idx_ = CASE0;
		
	}
#line 4269 "y.tab.c"
    break;

  case 48:
#line 792 "bison.y"
              {
		(yyval.range_or_rows_t) = new RangeOrRows();
		(yyval.range_or_rows_t)->case_idx_ = CASE1;
		
	}
#line 4279 "y.tab.c"
    break;

  case 49:
#line 797 "bison.y"
                {
		(yyval.range_or_rows_t) = new RangeOrRows();
		(yyval.range_or_rows_t)->case_idx_ = CASE2;
		
	}
#line 4289 "y.tab.c"
    break;

  case 50:
#line 805 "bison.y"
                     {
		(yyval.frame_bound_start_t) = new FrameBoundStart();
		(yyval.frame_bound_start_t)->case_idx_ = CASE0;
		(yyval.frame_bound_start_t)->frame_bound_ = (yyvsp[0].frame_bound_t);
		
	}
#line 4300 "y.tab.c"
    break;

  case 51:
#line 811 "bison.y"
                             {
		(yyval.frame_bound_start_t) = new FrameBoundStart();
		(yyval.frame_bound_start_t)->case_idx_ = CASE1;
		
	}
#line 4310 "y.tab.c"
    break;

  case 52:
#line 819 "bison.y"
                     {
		(yyval.frame_bound_end_t) = new FrameBoundEnd();
		(yyval.frame_bound_end_t)->case_idx_ = CASE0;
		(yyval.frame_bound_end_t)->frame_bound_ = (yyvsp[0].frame_bound_t);
		
	}
#line 4321 "y.tab.c"
    break;

  case 53:
#line 825 "bison.y"
                             {
		(yyval.frame_bound_end_t) = new FrameBoundEnd();
		(yyval.frame_bound_end_t)->case_idx_ = CASE1;
		
	}
#line 4331 "y.tab.c"
    break;

  case 54:
#line 833 "bison.y"
                        {
		(yyval.frame_bound_t) = new FrameBound();
		(yyval.frame_bound_t)->case_idx_ = CASE0;
		(yyval.frame_bound_t)->expr_ = (yyvsp[-1].expr_t);
		
	}
#line 4342 "y.tab.c"
    break;

  case 55:
#line 839 "bison.y"
                        {
		(yyval.frame_bound_t) = new FrameBound();
		(yyval.frame_bound_t)->case_idx_ = CASE1;
		(yyval.frame_bound_t)->expr_ = (yyvsp[-1].expr_t);
		
	}
#line 4353 "y.tab.c"
    break;

  case 56:
#line 845 "bison.y"
                     {
		(yyval.frame_bound_t) = new FrameBound();
		(yyval.frame_bound_t)->case_idx_ = CASE2;
		
	}
#line 4363 "y.tab.c"
    break;

  case 57:
#line 853 "bison.y"
                    {
		(yyval.opt_exist_window_name_t) = new OptExistWindowName();
		(yyval.opt_exist_window_name_t)->case_idx_ = CASE0;
		(yyval.opt_exist_window_name_t)->identifier_ = (yyvsp[0].identifier_t);
		if((yyval.opt_exist_window_name_t)){
			auto tmp1 = (yyval.opt_exist_window_name_t)->identifier_; 
			if(tmp1){
				tmp1->data_type_ = kDataWindowName; 
				tmp1->scope_ = 1; 
				tmp1->data_flag_ =(DATAFLAG)8; 
			}
		}


	}
#line 4383 "y.tab.c"
    break;

  case 58:
#line 868 "bison.y"
          {
		(yyval.opt_exist_window_name_t) = new OptExistWindowName();
		(yyval.opt_exist_window_name_t)->case_idx_ = CASE1;
		
	}
#line 4393 "y.tab.c"
    break;

  case 59:
#line 876 "bison.y"
                                              {
		(yyval.opt_group_clause_t) = new OptGroupClause();
		(yyval.opt_group_clause_t)->case_idx_ = CASE0;
		(yyval.opt_group_clause_t)->expr_list_ = (yyvsp[-1].expr_list_t);
		(yyval.opt_group_clause_t)->opt_having_clause_ = (yyvsp[0].opt_having_clause_t);
		
	}
#line 4405 "y.tab.c"
    break;

  case 60:
#line 883 "bison.y"
          {
		(yyval.opt_group_clause_t) = new OptGroupClause();
		(yyval.opt_group_clause_t)->case_idx_ = CASE1;
		
	}
#line 4415 "y.tab.c"
    break;

  case 61:
#line 891 "bison.y"
                     {
		(yyval.opt_having_clause_t) = new OptHavingClause();
		(yyval.opt_having_clause_t)->case_idx_ = CASE0;
		(yyval.opt_having_clause_t)->expr_ = (yyvsp[0].expr_t);
		
	}
#line 4426 "y.tab.c"
    break;

  case 62:
#line 897 "bison.y"
          {
		(yyval.opt_having_clause_t) = new OptHavingClause();
		(yyval.opt_having_clause_t)->case_idx_ = CASE1;
		
	}
#line 4436 "y.tab.c"
    break;

  case 63:
#line 905 "bison.y"
                      {
		(yyval.opt_where_clause_t) = new OptWhereClause();
		(yyval.opt_where_clause_t)->case_idx_ = CASE0;
		(yyval.opt_where_clause_t)->where_clause_ = (yyvsp[0].where_clause_t);
		
	}
#line 4447 "y.tab.c"
    break;

  case 64:
#line 911 "bison.y"
          {
		(yyval.opt_where_clause_t) = new OptWhereClause();
		(yyval.opt_where_clause_t)->case_idx_ = CASE1;
		
	}
#line 4457 "y.tab.c"
    break;

  case 65:
#line 919 "bison.y"
                    {
		(yyval.where_clause_t) = new WhereClause();
		(yyval.where_clause_t)->case_idx_ = CASE0;
		(yyval.where_clause_t)->expr_ = (yyvsp[0].expr_t);
		
	}
#line 4468 "y.tab.c"
    break;

  case 66:
#line 928 "bison.y"
                        {
		(yyval.from_clause_t) = new FromClause();
		(yyval.from_clause_t)->case_idx_ = CASE0;
		(yyval.from_clause_t)->table_ref_ = (yyvsp[0].table_ref_t);
		
	}
#line 4479 "y.tab.c"
    break;

  case 67:
#line 937 "bison.y"
                                                                             {
		(yyval.table_ref_t) = new TableRef();
		(yyval.table_ref_t)->case_idx_ = CASE0;
		(yyval.table_ref_t)->opt_table_prefix_ = (yyvsp[-5].opt_table_prefix_t);
		(yyval.table_ref_t)->table_name_ = (yyvsp[-4].table_name_t);
		(yyval.table_ref_t)->opt_as_alias_ = (yyvsp[-3].opt_as_alias_t);
		(yyval.table_ref_t)->opt_index_ = (yyvsp[-2].opt_index_t);
		(yyval.table_ref_t)->opt_on_ = (yyvsp[-1].opt_on_t);
		(yyval.table_ref_t)->opt_using_ = (yyvsp[0].opt_using_t);
		
	}
#line 4495 "y.tab.c"
    break;

  case 68:
#line 948 "bison.y"
                                                                                            {
		(yyval.table_ref_t) = new TableRef();
		(yyval.table_ref_t)->case_idx_ = CASE1;
		(yyval.table_ref_t)->opt_table_prefix_ = (yyvsp[-7].opt_table_prefix_t);
		(yyval.table_ref_t)->function_name_ = (yyvsp[-6].function_name_t);
		(yyval.table_ref_t)->expr_list_ = (yyvsp[-4].expr_list_t);
		(yyval.table_ref_t)->opt_as_alias_ = (yyvsp[-2].opt_as_alias_t);
		(yyval.table_ref_t)->opt_on_ = (yyvsp[-1].opt_on_t);
		(yyval.table_ref_t)->opt_using_ = (yyvsp[0].opt_using_t);
		
	}
#line 4511 "y.tab.c"
    break;

  case 69:
#line 959 "bison.y"
                                                                                     {
		(yyval.table_ref_t) = new TableRef();
		(yyval.table_ref_t)->case_idx_ = CASE2;
		(yyval.table_ref_t)->opt_table_prefix_ = (yyvsp[-6].opt_table_prefix_t);
		(yyval.table_ref_t)->select_no_parens_ = (yyvsp[-4].select_no_parens_t);
		(yyval.table_ref_t)->opt_as_alias_ = (yyvsp[-2].opt_as_alias_t);
		(yyval.table_ref_t)->opt_on_ = (yyvsp[-1].opt_on_t);
		(yyval.table_ref_t)->opt_using_ = (yyvsp[0].opt_using_t);
		
	}
#line 4526 "y.tab.c"
    break;

  case 70:
#line 969 "bison.y"
                                                                              {
		(yyval.table_ref_t) = new TableRef();
		(yyval.table_ref_t)->case_idx_ = CASE3;
		(yyval.table_ref_t)->opt_table_prefix_ = (yyvsp[-6].opt_table_prefix_t);
		(yyval.table_ref_t)->table_ref_ = (yyvsp[-4].table_ref_t);
		(yyval.table_ref_t)->opt_as_alias_ = (yyvsp[-2].opt_as_alias_t);
		(yyval.table_ref_t)->opt_on_ = (yyvsp[-1].opt_on_t);
		(yyval.table_ref_t)->opt_using_ = (yyvsp[0].opt_using_t);
		
	}
#line 4541 "y.tab.c"
    break;

  case 71:
#line 982 "bison.y"
                                {
		(yyval.opt_index_t) = new OptIndex();
		(yyval.opt_index_t)->case_idx_ = CASE0;
		(yyval.opt_index_t)->column_name_ = (yyvsp[0].column_name_t);
		
	}
#line 4552 "y.tab.c"
    break;

  case 72:
#line 988 "bison.y"
                     {
		(yyval.opt_index_t) = new OptIndex();
		(yyval.opt_index_t)->case_idx_ = CASE1;
		
	}
#line 4562 "y.tab.c"
    break;

  case 73:
#line 993 "bison.y"
          {
		(yyval.opt_index_t) = new OptIndex();
		(yyval.opt_index_t)->case_idx_ = CASE2;
		
	}
#line 4572 "y.tab.c"
    break;

  case 74:
#line 1001 "bison.y"
                 {
		(yyval.opt_on_t) = new OptOn();
		(yyval.opt_on_t)->case_idx_ = CASE0;
		(yyval.opt_on_t)->expr_ = (yyvsp[0].expr_t);
		
	}
#line 4583 "y.tab.c"
    break;

  case 75:
#line 1007 "bison.y"
                    {
		(yyval.opt_on_t) = new OptOn();
		(yyval.opt_on_t)->case_idx_ = CASE1;
		
	}
#line 4593 "y.tab.c"
    break;

  case 76:
#line 1015 "bison.y"
                                            {
		(yyval.opt_using_t) = new OptUsing();
		(yyval.opt_using_t)->case_idx_ = CASE0;
		(yyval.opt_using_t)->column_name_list_ = (yyvsp[-1].column_name_list_t);
		
	}
#line 4604 "y.tab.c"
    break;

  case 77:
#line 1021 "bison.y"
          {
		(yyval.opt_using_t) = new OptUsing();
		(yyval.opt_using_t)->case_idx_ = CASE1;
		
	}
#line 4614 "y.tab.c"
    break;

  case 78:
#line 1029 "bison.y"
                     {
		(yyval.column_name_list_t) = new ColumnNameList();
		(yyval.column_name_list_t)->case_idx_ = CASE0;
		(yyval.column_name_list_t)->column_name_ = (yyvsp[0].column_name_t);
		
	}
#line 4625 "y.tab.c"
    break;

  case 79:
#line 1035 "bison.y"
                                               {
		(yyval.column_name_list_t) = new ColumnNameList();
		(yyval.column_name_list_t)->case_idx_ = CASE1;
		(yyval.column_name_list_t)->column_name_ = (yyvsp[-2].column_name_t);
		(yyval.column_name_list_t)->column_name_list_ = (yyvsp[0].column_name_list_t);
		
	}
#line 4637 "y.tab.c"
    break;

  case 80:
#line 1045 "bison.y"
                           {
		(yyval.opt_table_prefix_t) = new OptTablePrefix();
		(yyval.opt_table_prefix_t)->case_idx_ = CASE0;
		(yyval.opt_table_prefix_t)->table_ref_ = (yyvsp[-1].table_ref_t);
		(yyval.opt_table_prefix_t)->join_op_ = (yyvsp[0].join_op_t);
		
	}
#line 4649 "y.tab.c"
    break;

  case 81:
#line 1052 "bison.y"
          {
		(yyval.opt_table_prefix_t) = new OptTablePrefix();
		(yyval.opt_table_prefix_t)->case_idx_ = CASE1;
		
	}
#line 4659 "y.tab.c"
    break;

  case 82:
#line 1060 "bison.y"
                  {
		(yyval.join_op_t) = new JoinOp();
		(yyval.join_op_t)->case_idx_ = CASE0;
		
	}
#line 4669 "y.tab.c"
    break;

  case 83:
#line 1065 "bison.y"
              {
		(yyval.join_op_t) = new JoinOp();
		(yyval.join_op_t)->case_idx_ = CASE1;
		
	}
#line 4679 "y.tab.c"
    break;

  case 84:
#line 1070 "bison.y"
                                    {
		(yyval.join_op_t) = new JoinOp();
		(yyval.join_op_t)->case_idx_ = CASE2;
		(yyval.join_op_t)->opt_join_type_ = (yyvsp[-1].opt_join_type_t);
		
	}
#line 4690 "y.tab.c"
    break;

  case 85:
#line 1079 "bison.y"
              {
		(yyval.opt_join_type_t) = new OptJoinType();
		(yyval.opt_join_type_t)->case_idx_ = CASE0;
		
	}
#line 4700 "y.tab.c"
    break;

  case 86:
#line 1084 "bison.y"
                    {
		(yyval.opt_join_type_t) = new OptJoinType();
		(yyval.opt_join_type_t)->case_idx_ = CASE1;
		
	}
#line 4710 "y.tab.c"
    break;

  case 87:
#line 1089 "bison.y"
               {
		(yyval.opt_join_type_t) = new OptJoinType();
		(yyval.opt_join_type_t)->case_idx_ = CASE2;
		
	}
#line 4720 "y.tab.c"
    break;

  case 88:
#line 1094 "bison.y"
               {
		(yyval.opt_join_type_t) = new OptJoinType();
		(yyval.opt_join_type_t)->case_idx_ = CASE3;
		
	}
#line 4730 "y.tab.c"
    break;

  case 89:
#line 1099 "bison.y"
          {
		(yyval.opt_join_type_t) = new OptJoinType();
		(yyval.opt_join_type_t)->case_idx_ = CASE4;
		
	}
#line 4740 "y.tab.c"
    break;

  case 90:
#line 1107 "bison.y"
                                              {
		(yyval.expr_list_t) = new ExprList();
		(yyval.expr_list_t)->case_idx_ = CASE0;
		(yyval.expr_list_t)->expr_ = (yyvsp[-3].expr_t);
		(yyval.expr_list_t)->opt_as_alias_ = (yyvsp[-2].opt_as_alias_t);
		(yyval.expr_list_t)->expr_list_ = (yyvsp[0].expr_list_t);
		
	}
#line 4753 "y.tab.c"
    break;

  case 91:
#line 1115 "bison.y"
                           {
		(yyval.expr_list_t) = new ExprList();
		(yyval.expr_list_t)->case_idx_ = CASE1;
		(yyval.expr_list_t)->expr_ = (yyvsp[-1].expr_t);
		(yyval.expr_list_t)->opt_as_alias_ = (yyvsp[0].opt_as_alias_t);
		
	}
#line 4765 "y.tab.c"
    break;

  case 92:
#line 1125 "bison.y"
                      {
		(yyval.opt_limit_clause_t) = new OptLimitClause();
		(yyval.opt_limit_clause_t)->case_idx_ = CASE0;
		(yyval.opt_limit_clause_t)->limit_clause_ = (yyvsp[0].limit_clause_t);
		
	}
#line 4776 "y.tab.c"
    break;

  case 93:
#line 1131 "bison.y"
          {
		(yyval.opt_limit_clause_t) = new OptLimitClause();
		(yyval.opt_limit_clause_t)->case_idx_ = CASE1;
		
	}
#line 4786 "y.tab.c"
    break;

  case 94:
#line 1139 "bison.y"
                    {
		(yyval.limit_clause_t) = new LimitClause();
		(yyval.limit_clause_t)->case_idx_ = CASE0;
		(yyval.limit_clause_t)->expr_1_ = (yyvsp[0].expr_t);
		
	}
#line 4797 "y.tab.c"
    break;

  case 95:
#line 1145 "bison.y"
                                {
		(yyval.limit_clause_t) = new LimitClause();
		(yyval.limit_clause_t)->case_idx_ = CASE1;
		(yyval.limit_clause_t)->expr_1_ = (yyvsp[-2].expr_t);
		(yyval.limit_clause_t)->expr_2_ = (yyvsp[0].expr_t);
		
	}
#line 4809 "y.tab.c"
    break;

  case 96:
#line 1152 "bison.y"
                                  {
		(yyval.limit_clause_t) = new LimitClause();
		(yyval.limit_clause_t)->case_idx_ = CASE2;
		(yyval.limit_clause_t)->expr_1_ = (yyvsp[-2].expr_t);
		(yyval.limit_clause_t)->expr_2_ = (yyvsp[0].expr_t);
		
	}
#line 4821 "y.tab.c"
    break;

  case 97:
#line 1162 "bison.y"
                    {
		(yyval.opt_limit_row_count_t) = new OptLimitRowCount();
		(yyval.opt_limit_row_count_t)->case_idx_ = CASE0;
		(yyval.opt_limit_row_count_t)->expr_ = (yyvsp[0].expr_t);
		
	}
#line 4832 "y.tab.c"
    break;

  case 98:
#line 1168 "bison.y"
          {
		(yyval.opt_limit_row_count_t) = new OptLimitRowCount();
		(yyval.opt_limit_row_count_t)->case_idx_ = CASE1;
		
	}
#line 4842 "y.tab.c"
    break;

  case 99:
#line 1176 "bison.y"
                                  {
		(yyval.opt_order_clause_t) = new OptOrderClause();
		(yyval.opt_order_clause_t)->case_idx_ = CASE0;
		(yyval.opt_order_clause_t)->order_item_list_ = (yyvsp[0].order_item_list_t);
		
	}
#line 4853 "y.tab.c"
    break;

  case 100:
#line 1182 "bison.y"
          {
		(yyval.opt_order_clause_t) = new OptOrderClause();
		(yyval.opt_order_clause_t)->case_idx_ = CASE1;
		
	}
#line 4863 "y.tab.c"
    break;

  case 101:
#line 1190 "bison.y"
                     {
		(yyval.opt_order_nulls_t) = new OptOrderNulls();
		(yyval.opt_order_nulls_t)->case_idx_ = CASE0;
		
	}
#line 4873 "y.tab.c"
    break;

  case 102:
#line 1195 "bison.y"
                    {
		(yyval.opt_order_nulls_t) = new OptOrderNulls();
		(yyval.opt_order_nulls_t)->case_idx_ = CASE1;
		
	}
#line 4883 "y.tab.c"
    break;

  case 103:
#line 1200 "bison.y"
          {
		(yyval.opt_order_nulls_t) = new OptOrderNulls();
		(yyval.opt_order_nulls_t)->case_idx_ = CASE2;
		
	}
#line 4893 "y.tab.c"
    break;

  case 104:
#line 1208 "bison.y"
                    {
		(yyval.order_item_list_t) = new OrderItemList();
		(yyval.order_item_list_t)->case_idx_ = CASE0;
		(yyval.order_item_list_t)->order_item_ = (yyvsp[0].order_item_t);
		
	}
#line 4904 "y.tab.c"
    break;

  case 105:
#line 1214 "bison.y"
                                             {
		(yyval.order_item_list_t) = new OrderItemList();
		(yyval.order_item_list_t)->case_idx_ = CASE1;
		(yyval.order_item_list_t)->order_item_ = (yyvsp[-2].order_item_t);
		(yyval.order_item_list_t)->order_item_list_ = (yyvsp[0].order_item_list_t);
		
	}
#line 4916 "y.tab.c"
    break;

  case 106:
#line 1224 "bison.y"
                                                 {
		(yyval.order_item_t) = new OrderItem();
		(yyval.order_item_t)->case_idx_ = CASE0;
		(yyval.order_item_t)->expr_ = (yyvsp[-2].expr_t);
		(yyval.order_item_t)->opt_order_behavior_ = (yyvsp[-1].opt_order_behavior_t);
		(yyval.order_item_t)->opt_order_nulls_ = (yyvsp[0].opt_order_nulls_t);
		
	}
#line 4929 "y.tab.c"
    break;

  case 107:
#line 1235 "bison.y"
             {
		(yyval.opt_order_behavior_t) = new OptOrderBehavior();
		(yyval.opt_order_behavior_t)->case_idx_ = CASE0;
		
	}
#line 4939 "y.tab.c"
    break;

  case 108:
#line 1240 "bison.y"
              {
		(yyval.opt_order_behavior_t) = new OptOrderBehavior();
		(yyval.opt_order_behavior_t)->case_idx_ = CASE1;
		
	}
#line 4949 "y.tab.c"
    break;

  case 109:
#line 1245 "bison.y"
          {
		(yyval.opt_order_behavior_t) = new OptOrderBehavior();
		(yyval.opt_order_behavior_t)->case_idx_ = CASE2;
		
	}
#line 4959 "y.tab.c"
    break;

  case 110:
#line 1253 "bison.y"
                             {
		(yyval.opt_with_clause_t) = new OptWithClause();
		(yyval.opt_with_clause_t)->case_idx_ = CASE0;
		(yyval.opt_with_clause_t)->cte_table_list_ = (yyvsp[0].cte_table_list_t);
		
	}
#line 4970 "y.tab.c"
    break;

  case 111:
#line 1259 "bison.y"
                                       {
		(yyval.opt_with_clause_t) = new OptWithClause();
		(yyval.opt_with_clause_t)->case_idx_ = CASE1;
		(yyval.opt_with_clause_t)->cte_table_list_ = (yyvsp[0].cte_table_list_t);
		
	}
#line 4981 "y.tab.c"
    break;

  case 112:
#line 1265 "bison.y"
          {
		(yyval.opt_with_clause_t) = new OptWithClause();
		(yyval.opt_with_clause_t)->case_idx_ = CASE2;
		
	}
#line 4991 "y.tab.c"
    break;

  case 113:
#line 1273 "bison.y"
                   {
		(yyval.cte_table_list_t) = new CteTableList();
		(yyval.cte_table_list_t)->case_idx_ = CASE0;
		(yyval.cte_table_list_t)->cte_table_ = (yyvsp[0].cte_table_t);
		
	}
#line 5002 "y.tab.c"
    break;

  case 114:
#line 1279 "bison.y"
                                           {
		(yyval.cte_table_list_t) = new CteTableList();
		(yyval.cte_table_list_t)->case_idx_ = CASE1;
		(yyval.cte_table_list_t)->cte_table_ = (yyvsp[-2].cte_table_t);
		(yyval.cte_table_list_t)->cte_table_list_ = (yyvsp[0].cte_table_list_t);
		
	}
#line 5014 "y.tab.c"
    break;

  case 115:
#line 1289 "bison.y"
                                                   {
		(yyval.cte_table_t) = new CteTable();
		(yyval.cte_table_t)->case_idx_ = CASE0;
		(yyval.cte_table_t)->cte_table_name_ = (yyvsp[-4].cte_table_name_t);
		(yyval.cte_table_t)->select_stmt_ = (yyvsp[-1].select_stmt_t);
		
	}
#line 5026 "y.tab.c"
    break;

  case 116:
#line 1299 "bison.y"
                                           {
		(yyval.cte_table_name_t) = new CteTableName();
		(yyval.cte_table_name_t)->case_idx_ = CASE0;
		(yyval.cte_table_name_t)->table_name_ = (yyvsp[-1].table_name_t);
		(yyval.cte_table_name_t)->opt_column_name_list_p_ = (yyvsp[0].opt_column_name_list_p_t);
		
	}
#line 5038 "y.tab.c"
    break;

  case 117:
#line 1309 "bison.y"
             {
		(yyval.opt_all_or_distinct_t) = new OptAllOrDistinct();
		(yyval.opt_all_or_distinct_t)->case_idx_ = CASE0;
		
	}
#line 5048 "y.tab.c"
    break;

  case 118:
#line 1314 "bison.y"
                  {
		(yyval.opt_all_or_distinct_t) = new OptAllOrDistinct();
		(yyval.opt_all_or_distinct_t)->case_idx_ = CASE1;
		
	}
#line 5058 "y.tab.c"
    break;

  case 119:
#line 1319 "bison.y"
          {
		(yyval.opt_all_or_distinct_t) = new OptAllOrDistinct();
		(yyval.opt_all_or_distinct_t)->case_idx_ = CASE2;
		
	}
#line 5068 "y.tab.c"
    break;

  case 120:
#line 1327 "bison.y"
                                                                                                                      {
		(yyval.create_table_stmt_t) = new CreateTableStmt();
		(yyval.create_table_stmt_t)->case_idx_ = CASE0;
		(yyval.create_table_stmt_t)->opt_temp_ = (yyvsp[-7].opt_temp_t);
		(yyval.create_table_stmt_t)->opt_if_not_exist_ = (yyvsp[-5].opt_if_not_exist_t);
		(yyval.create_table_stmt_t)->table_name_ = (yyvsp[-4].table_name_t);
		(yyval.create_table_stmt_t)->opt_table_option_list_ = (yyvsp[-3].opt_table_option_list_t);
		(yyval.create_table_stmt_t)->opt_ignore_or_replace_ = (yyvsp[-2].opt_ignore_or_replace_t);
		(yyval.create_table_stmt_t)->select_stmt_ = (yyvsp[0].select_stmt_t);
		if((yyval.create_table_stmt_t)){
			auto tmp1 = (yyval.create_table_stmt_t)->table_name_; 
			if(tmp1){
				auto tmp2 = tmp1->identifier_; 
				if(tmp2){
					tmp2->data_type_ = kDataTableName; 
					tmp2->scope_ = 1; 
					tmp2->data_flag_ =(DATAFLAG)128; 
				}
			}
		}


	}
#line 5096 "y.tab.c"
    break;

  case 121:
#line 1350 "bison.y"
                                                                                                                                       {
		(yyval.create_table_stmt_t) = new CreateTableStmt();
		(yyval.create_table_stmt_t)->case_idx_ = CASE1;
		(yyval.create_table_stmt_t)->opt_temp_ = (yyvsp[-8].opt_temp_t);
		(yyval.create_table_stmt_t)->opt_if_not_exist_ = (yyvsp[-6].opt_if_not_exist_t);
		(yyval.create_table_stmt_t)->table_name_ = (yyvsp[-5].table_name_t);
		(yyval.create_table_stmt_t)->column_def_list_ = (yyvsp[-3].column_def_list_t);
		(yyval.create_table_stmt_t)->opt_table_constraint_list_ = (yyvsp[-2].opt_table_constraint_list_t);
		(yyval.create_table_stmt_t)->opt_table_option_list_ = (yyvsp[0].opt_table_option_list_t);
		if((yyval.create_table_stmt_t)){
			auto tmp1 = (yyval.create_table_stmt_t)->table_name_; 
			if(tmp1){
				auto tmp2 = tmp1->identifier_; 
				if(tmp2){
					tmp2->data_type_ = kDataTableName; 
					tmp2->scope_ = 1; 
					tmp2->data_flag_ =(DATAFLAG)1; 
				}
			}
		}

		if((yyval.create_table_stmt_t)){
			auto tmp1 = (yyval.create_table_stmt_t)->column_def_list_; 
			while(tmp1){
				auto tmp2 = tmp1->column_def_; 
				if(tmp2){
					auto tmp3 = tmp2->identifier_; 
					if(tmp3){
						tmp3->data_type_ = kDataColumnName; 
						tmp3->scope_ = 2; 
						tmp3->data_flag_ =(DATAFLAG)1; 
					}
				}
				tmp1 = tmp1->column_def_list_;
			}
		}


	}
#line 5140 "y.tab.c"
    break;

  case 122:
#line 1392 "bison.y"
                                                                                                                                   {
		(yyval.create_index_stmt_t) = new CreateIndexStmt();
		(yyval.create_index_stmt_t)->case_idx_ = CASE0;
		(yyval.create_index_stmt_t)->opt_index_keyword_ = (yyvsp[-9].opt_index_keyword_t);
		(yyval.create_index_stmt_t)->table_name_1_ = (yyvsp[-7].table_name_t);
		(yyval.create_index_stmt_t)->table_name_2_ = (yyvsp[-5].table_name_t);
		(yyval.create_index_stmt_t)->indexed_column_list_ = (yyvsp[-3].indexed_column_list_t);
		(yyval.create_index_stmt_t)->opt_index_option_ = (yyvsp[-1].opt_index_option_t);
		(yyval.create_index_stmt_t)->opt_extra_option_ = (yyvsp[0].opt_extra_option_t);
		if((yyval.create_index_stmt_t)){
			auto tmp1 = (yyval.create_index_stmt_t)->table_name_1_; 
			if(tmp1){
				auto tmp2 = tmp1->identifier_; 
				if(tmp2){
					tmp2->data_type_ = kDataTableName; 
					tmp2->scope_ = 2; 
					tmp2->data_flag_ =(DATAFLAG)128; 
				}
			}
		}

		if((yyval.create_index_stmt_t)){
			auto tmp1 = (yyval.create_index_stmt_t)->table_name_2_; 
			if(tmp1){
				auto tmp2 = tmp1->identifier_; 
				if(tmp2){
					tmp2->data_type_ = kDataTableName; 
					tmp2->scope_ = 1; 
					tmp2->data_flag_ =(DATAFLAG)8; 
				}
			}
		}


	}
#line 5180 "y.tab.c"
    break;

  case 123:
#line 1430 "bison.y"
                                                                                                                {
		(yyval.create_trigger_stmt_t) = new CreateTriggerStmt();
		(yyval.create_trigger_stmt_t)->case_idx_ = CASE0;
		(yyval.create_trigger_stmt_t)->trigger_name_ = (yyvsp[-8].trigger_name_t);
		(yyval.create_trigger_stmt_t)->trigger_action_time_ = (yyvsp[-7].trigger_action_time_t);
		(yyval.create_trigger_stmt_t)->trigger_events_ = (yyvsp[-6].trigger_events_t);
		(yyval.create_trigger_stmt_t)->table_name_ = (yyvsp[-4].table_name_t);
		(yyval.create_trigger_stmt_t)->trigger_body_ = (yyvsp[0].trigger_body_t);
		if((yyval.create_trigger_stmt_t)){
			auto tmp1 = (yyval.create_trigger_stmt_t)->trigger_name_; 
			if(tmp1){
				auto tmp2 = tmp1->identifier_; 
				if(tmp2){
					tmp2->data_type_ = kDataTriggerName; 
					tmp2->scope_ = 1; 
					tmp2->data_flag_ =(DATAFLAG)1; 
				}
			}
		}

		if((yyval.create_trigger_stmt_t)){
			auto tmp1 = (yyval.create_trigger_stmt_t)->table_name_; 
			if(tmp1){
				auto tmp2 = tmp1->identifier_; 
				if(tmp2){
					tmp2->data_type_ = kDataTableName; 
					tmp2->scope_ = 1; 
					tmp2->data_flag_ =(DATAFLAG)8; 
				}
			}
		}


	}
#line 5219 "y.tab.c"
    break;

  case 124:
#line 1467 "bison.y"
                                                                                                                          {
		(yyval.create_view_stmt_t) = new CreateViewStmt();
		(yyval.create_view_stmt_t)->case_idx_ = CASE0;
		(yyval.create_view_stmt_t)->opt_view_algorithm_ = (yyvsp[-7].opt_view_algorithm_t);
		(yyval.create_view_stmt_t)->opt_sql_security_ = (yyvsp[-6].opt_sql_security_t);
		(yyval.create_view_stmt_t)->view_name_ = (yyvsp[-4].view_name_t);
		(yyval.create_view_stmt_t)->opt_column_name_list_p_ = (yyvsp[-3].opt_column_name_list_p_t);
		(yyval.create_view_stmt_t)->select_stmt_ = (yyvsp[-1].select_stmt_t);
		(yyval.create_view_stmt_t)->opt_check_option_ = (yyvsp[0].opt_check_option_t);
		if((yyval.create_view_stmt_t)){
			auto tmp1 = (yyval.create_view_stmt_t)->view_name_; 
			if(tmp1){
				auto tmp2 = tmp1->identifier_; 
				if(tmp2){
					tmp2->data_type_ = kDataTableName; 
					tmp2->scope_ = 10; 
					tmp2->data_flag_ =(DATAFLAG)1; 
				}
			}
		}

		if((yyval.create_view_stmt_t)){
			auto tmp1 = (yyval.create_view_stmt_t)->opt_column_name_list_p_; 
			if(tmp1){
				auto tmp2 = tmp1->column_name_list_; 
				while(tmp2){
					auto tmp3 = tmp2->column_name_; 
					if(tmp3){
						auto tmp4 = tmp3->identifier_; 
						if(tmp4){
							tmp4->data_type_ = kDataColumnName; 
							tmp4->scope_ = 11; 
							tmp4->data_flag_ =(DATAFLAG)1; 
						}
					}
					tmp2 = tmp2->column_name_list_;
				}
			}
		}


	}
#line 5266 "y.tab.c"
    break;

  case 125:
#line 1509 "bison.y"
                                                                                                                                     {
		(yyval.create_view_stmt_t) = new CreateViewStmt();
		(yyval.create_view_stmt_t)->case_idx_ = CASE1;
		(yyval.create_view_stmt_t)->opt_view_algorithm_ = (yyvsp[-7].opt_view_algorithm_t);
		(yyval.create_view_stmt_t)->opt_sql_security_ = (yyvsp[-6].opt_sql_security_t);
		(yyval.create_view_stmt_t)->view_name_ = (yyvsp[-4].view_name_t);
		(yyval.create_view_stmt_t)->opt_column_name_list_p_ = (yyvsp[-3].opt_column_name_list_p_t);
		(yyval.create_view_stmt_t)->select_stmt_ = (yyvsp[-1].select_stmt_t);
		(yyval.create_view_stmt_t)->opt_check_option_ = (yyvsp[0].opt_check_option_t);
		if((yyval.create_view_stmt_t)){
			auto tmp1 = (yyval.create_view_stmt_t)->view_name_; 
			if(tmp1){
				auto tmp2 = tmp1->identifier_; 
				if(tmp2){
					tmp2->data_type_ = kDataTableName; 
					tmp2->scope_ = 10; 
					tmp2->data_flag_ =(DATAFLAG)1; 
				}
			}
		}

		if((yyval.create_view_stmt_t)){
			auto tmp1 = (yyval.create_view_stmt_t)->opt_column_name_list_p_; 
			if(tmp1){
				auto tmp2 = tmp1->column_name_list_; 
				while(tmp2){
					auto tmp3 = tmp2->column_name_; 
					if(tmp3){
						auto tmp4 = tmp3->identifier_; 
						if(tmp4){
							tmp4->data_type_ = kDataColumnName; 
							tmp4->scope_ = 11; 
							tmp4->data_flag_ =(DATAFLAG)1; 
						}
					}
					tmp2 = tmp2->column_name_list_;
				}
			}
		}


	}
#line 5313 "y.tab.c"
    break;

  case 126:
#line 1554 "bison.y"
                           {
		(yyval.opt_table_option_list_t) = new OptTableOptionList();
		(yyval.opt_table_option_list_t)->case_idx_ = CASE0;
		(yyval.opt_table_option_list_t)->table_option_list_ = (yyvsp[0].table_option_list_t);
		
	}
#line 5324 "y.tab.c"
    break;

  case 127:
#line 1560 "bison.y"
          {
		(yyval.opt_table_option_list_t) = new OptTableOptionList();
		(yyval.opt_table_option_list_t)->case_idx_ = CASE1;
		
	}
#line 5334 "y.tab.c"
    break;

  case 128:
#line 1568 "bison.y"
                      {
		(yyval.table_option_list_t) = new TableOptionList();
		(yyval.table_option_list_t)->case_idx_ = CASE0;
		(yyval.table_option_list_t)->table_option_ = (yyvsp[0].table_option_t);
		
	}
#line 5345 "y.tab.c"
    break;

  case 129:
#line 1574 "bison.y"
                                                     {
		(yyval.table_option_list_t) = new TableOptionList();
		(yyval.table_option_list_t)->case_idx_ = CASE1;
		(yyval.table_option_list_t)->table_option_ = (yyvsp[-2].table_option_t);
		(yyval.table_option_list_t)->opt_op_comma_ = (yyvsp[-1].opt_op_comma_t);
		(yyval.table_option_list_t)->table_option_list_ = (yyvsp[0].table_option_list_t);
		
	}
#line 5358 "y.tab.c"
    break;

  case 130:
#line 1585 "bison.y"
                                       {
		(yyval.table_option_t) = new TableOption();
		(yyval.table_option_t)->case_idx_ = CASE0;
		(yyval.table_option_t)->opt_op_equal_ = (yyvsp[-1].opt_op_equal_t);
		
	}
#line 5369 "y.tab.c"
    break;

  case 131:
#line 1591 "bison.y"
                                          {
		(yyval.table_option_t) = new TableOption();
		(yyval.table_option_t)->case_idx_ = CASE1;
		(yyval.table_option_t)->opt_op_equal_ = (yyvsp[-1].opt_op_equal_t);
		
	}
#line 5380 "y.tab.c"
    break;

  case 132:
#line 1597 "bison.y"
                                         {
		(yyval.table_option_t) = new TableOption();
		(yyval.table_option_t)->case_idx_ = CASE2;
		(yyval.table_option_t)->opt_op_equal_ = (yyvsp[-1].opt_op_equal_t);
		
	}
#line 5391 "y.tab.c"
    break;

  case 133:
#line 1603 "bison.y"
                                         {
		(yyval.table_option_t) = new TableOption();
		(yyval.table_option_t)->case_idx_ = CASE3;
		(yyval.table_option_t)->opt_op_equal_ = (yyvsp[-1].opt_op_equal_t);
		
	}
#line 5402 "y.tab.c"
    break;

  case 134:
#line 1609 "bison.y"
                                         {
		(yyval.table_option_t) = new TableOption();
		(yyval.table_option_t)->case_idx_ = CASE4;
		(yyval.table_option_t)->opt_op_equal_ = (yyvsp[-1].opt_op_equal_t);
		
	}
#line 5413 "y.tab.c"
    break;

  case 135:
#line 1615 "bison.y"
                                       {
		(yyval.table_option_t) = new TableOption();
		(yyval.table_option_t)->case_idx_ = CASE5;
		(yyval.table_option_t)->opt_op_equal_ = (yyvsp[-1].opt_op_equal_t);
		
	}
#line 5424 "y.tab.c"
    break;

  case 136:
#line 1621 "bison.y"
                                            {
		(yyval.table_option_t) = new TableOption();
		(yyval.table_option_t)->case_idx_ = CASE6;
		(yyval.table_option_t)->opt_op_equal_ = (yyvsp[-1].opt_op_equal_t);
		
	}
#line 5435 "y.tab.c"
    break;

  case 137:
#line 1627 "bison.y"
                                           {
		(yyval.table_option_t) = new TableOption();
		(yyval.table_option_t)->case_idx_ = CASE7;
		(yyval.table_option_t)->opt_op_equal_ = (yyvsp[-1].opt_op_equal_t);
		
	}
#line 5446 "y.tab.c"
    break;

  case 138:
#line 1633 "bison.y"
                                         {
		(yyval.table_option_t) = new TableOption();
		(yyval.table_option_t)->case_idx_ = CASE8;
		(yyval.table_option_t)->opt_op_equal_ = (yyvsp[-1].opt_op_equal_t);
		
	}
#line 5457 "y.tab.c"
    break;

  case 139:
#line 1642 "bison.y"
                  {
		(yyval.opt_op_comma_t) = new OptOpComma();
		(yyval.opt_op_comma_t)->case_idx_ = CASE0;
		
	}
#line 5467 "y.tab.c"
    break;

  case 140:
#line 1647 "bison.y"
          {
		(yyval.opt_op_comma_t) = new OptOpComma();
		(yyval.opt_op_comma_t)->case_idx_ = CASE1;
		
	}
#line 5477 "y.tab.c"
    break;

  case 141:
#line 1655 "bison.y"
                {
		(yyval.opt_ignore_or_replace_t) = new OptIgnoreOrReplace();
		(yyval.opt_ignore_or_replace_t)->case_idx_ = CASE0;
		
	}
#line 5487 "y.tab.c"
    break;

  case 142:
#line 1660 "bison.y"
                 {
		(yyval.opt_ignore_or_replace_t) = new OptIgnoreOrReplace();
		(yyval.opt_ignore_or_replace_t)->case_idx_ = CASE1;
		
	}
#line 5497 "y.tab.c"
    break;

  case 143:
#line 1665 "bison.y"
          {
		(yyval.opt_ignore_or_replace_t) = new OptIgnoreOrReplace();
		(yyval.opt_ignore_or_replace_t)->case_idx_ = CASE2;
		
	}
#line 5507 "y.tab.c"
    break;

  case 144:
#line 1673 "bison.y"
                                      {
		(yyval.opt_view_algorithm_t) = new OptViewAlgorithm();
		(yyval.opt_view_algorithm_t)->case_idx_ = CASE0;
		
	}
#line 5517 "y.tab.c"
    break;

  case 145:
#line 1678 "bison.y"
                                  {
		(yyval.opt_view_algorithm_t) = new OptViewAlgorithm();
		(yyval.opt_view_algorithm_t)->case_idx_ = CASE1;
		
	}
#line 5527 "y.tab.c"
    break;

  case 146:
#line 1683 "bison.y"
                                      {
		(yyval.opt_view_algorithm_t) = new OptViewAlgorithm();
		(yyval.opt_view_algorithm_t)->case_idx_ = CASE2;
		
	}
#line 5537 "y.tab.c"
    break;

  case 147:
#line 1688 "bison.y"
          {
		(yyval.opt_view_algorithm_t) = new OptViewAlgorithm();
		(yyval.opt_view_algorithm_t)->case_idx_ = CASE3;
		
	}
#line 5547 "y.tab.c"
    break;

  case 148:
#line 1696 "bison.y"
                              {
		(yyval.opt_sql_security_t) = new OptSqlSecurity();
		(yyval.opt_sql_security_t)->case_idx_ = CASE0;
		
	}
#line 5557 "y.tab.c"
    break;

  case 149:
#line 1701 "bison.y"
                              {
		(yyval.opt_sql_security_t) = new OptSqlSecurity();
		(yyval.opt_sql_security_t)->case_idx_ = CASE1;
		
	}
#line 5567 "y.tab.c"
    break;

  case 150:
#line 1706 "bison.y"
          {
		(yyval.opt_sql_security_t) = new OptSqlSecurity();
		(yyval.opt_sql_security_t)->case_idx_ = CASE2;
		
	}
#line 5577 "y.tab.c"
    break;

  case 151:
#line 1714 "bison.y"
                     {
		(yyval.opt_index_option_t) = new OptIndexOption();
		(yyval.opt_index_option_t)->case_idx_ = CASE0;
		
	}
#line 5587 "y.tab.c"
    break;

  case 152:
#line 1719 "bison.y"
                    {
		(yyval.opt_index_option_t) = new OptIndexOption();
		(yyval.opt_index_option_t)->case_idx_ = CASE1;
		
	}
#line 5597 "y.tab.c"
    break;

  case 153:
#line 1724 "bison.y"
          {
		(yyval.opt_index_option_t) = new OptIndexOption();
		(yyval.opt_index_option_t)->case_idx_ = CASE2;
		
	}
#line 5607 "y.tab.c"
    break;

  case 154:
#line 1732 "bison.y"
                                {
		(yyval.opt_extra_option_t) = new OptExtraOption();
		(yyval.opt_extra_option_t)->case_idx_ = CASE0;
		(yyval.opt_extra_option_t)->index_algorithm_option_ = (yyvsp[0].index_algorithm_option_t);
		
	}
#line 5618 "y.tab.c"
    break;

  case 155:
#line 1738 "bison.y"
                     {
		(yyval.opt_extra_option_t) = new OptExtraOption();
		(yyval.opt_extra_option_t)->case_idx_ = CASE1;
		(yyval.opt_extra_option_t)->lock_option_ = (yyvsp[0].lock_option_t);
		
	}
#line 5629 "y.tab.c"
    break;

  case 156:
#line 1744 "bison.y"
          {
		(yyval.opt_extra_option_t) = new OptExtraOption();
		(yyval.opt_extra_option_t)->case_idx_ = CASE2;
		
	}
#line 5639 "y.tab.c"
    break;

  case 157:
#line 1752 "bison.y"
                                        {
		(yyval.index_algorithm_option_t) = new IndexAlgorithmOption();
		(yyval.index_algorithm_option_t)->case_idx_ = CASE0;
		(yyval.index_algorithm_option_t)->opt_op_equal_ = (yyvsp[-1].opt_op_equal_t);
		
	}
#line 5650 "y.tab.c"
    break;

  case 158:
#line 1758 "bison.y"
                                        {
		(yyval.index_algorithm_option_t) = new IndexAlgorithmOption();
		(yyval.index_algorithm_option_t)->case_idx_ = CASE1;
		(yyval.index_algorithm_option_t)->opt_op_equal_ = (yyvsp[-1].opt_op_equal_t);
		
	}
#line 5661 "y.tab.c"
    break;

  case 159:
#line 1764 "bison.y"
                                     {
		(yyval.index_algorithm_option_t) = new IndexAlgorithmOption();
		(yyval.index_algorithm_option_t)->case_idx_ = CASE2;
		(yyval.index_algorithm_option_t)->opt_op_equal_ = (yyvsp[-1].opt_op_equal_t);
		
	}
#line 5672 "y.tab.c"
    break;

  case 160:
#line 1773 "bison.y"
                                   {
		(yyval.lock_option_t) = new LockOption();
		(yyval.lock_option_t)->case_idx_ = CASE0;
		(yyval.lock_option_t)->opt_op_equal_ = (yyvsp[-1].opt_op_equal_t);
		
	}
#line 5683 "y.tab.c"
    break;

  case 161:
#line 1779 "bison.y"
                                {
		(yyval.lock_option_t) = new LockOption();
		(yyval.lock_option_t)->case_idx_ = CASE1;
		(yyval.lock_option_t)->opt_op_equal_ = (yyvsp[-1].opt_op_equal_t);
		
	}
#line 5694 "y.tab.c"
    break;

  case 162:
#line 1785 "bison.y"
                                  {
		(yyval.lock_option_t) = new LockOption();
		(yyval.lock_option_t)->case_idx_ = CASE2;
		(yyval.lock_option_t)->opt_op_equal_ = (yyvsp[-1].opt_op_equal_t);
		
	}
#line 5705 "y.tab.c"
    break;

  case 163:
#line 1791 "bison.y"
                                     {
		(yyval.lock_option_t) = new LockOption();
		(yyval.lock_option_t)->case_idx_ = CASE3;
		(yyval.lock_option_t)->opt_op_equal_ = (yyvsp[-1].opt_op_equal_t);
		
	}
#line 5716 "y.tab.c"
    break;

  case 164:
#line 1800 "bison.y"
                  {
		(yyval.opt_op_equal_t) = new OptOpEqual();
		(yyval.opt_op_equal_t)->case_idx_ = CASE0;
		
	}
#line 5726 "y.tab.c"
    break;

  case 165:
#line 1805 "bison.y"
          {
		(yyval.opt_op_equal_t) = new OptOpEqual();
		(yyval.opt_op_equal_t)->case_idx_ = CASE1;
		
	}
#line 5736 "y.tab.c"
    break;

  case 166:
#line 1813 "bison.y"
                {
		(yyval.trigger_events_t) = new TriggerEvents();
		(yyval.trigger_events_t)->case_idx_ = CASE0;
		
	}
#line 5746 "y.tab.c"
    break;

  case 167:
#line 1818 "bison.y"
                {
		(yyval.trigger_events_t) = new TriggerEvents();
		(yyval.trigger_events_t)->case_idx_ = CASE1;
		
	}
#line 5756 "y.tab.c"
    break;

  case 168:
#line 1823 "bison.y"
                {
		(yyval.trigger_events_t) = new TriggerEvents();
		(yyval.trigger_events_t)->case_idx_ = CASE2;
		
	}
#line 5766 "y.tab.c"
    break;

  case 169:
#line 1831 "bison.y"
                    {
		(yyval.trigger_name_t) = new TriggerName();
		(yyval.trigger_name_t)->case_idx_ = CASE0;
		(yyval.trigger_name_t)->identifier_ = (yyvsp[0].identifier_t);
		
	}
#line 5777 "y.tab.c"
    break;

  case 170:
#line 1840 "bison.y"
                {
		(yyval.trigger_action_time_t) = new TriggerActionTime();
		(yyval.trigger_action_time_t)->case_idx_ = CASE0;
		
	}
#line 5787 "y.tab.c"
    break;

  case 171:
#line 1845 "bison.y"
               {
		(yyval.trigger_action_time_t) = new TriggerActionTime();
		(yyval.trigger_action_time_t)->case_idx_ = CASE1;
		
	}
#line 5797 "y.tab.c"
    break;

  case 172:
#line 1853 "bison.y"
                                                {
		(yyval.drop_index_stmt_t) = new DropIndexStmt();
		(yyval.drop_index_stmt_t)->case_idx_ = CASE0;
		(yyval.drop_index_stmt_t)->table_name_ = (yyvsp[-1].table_name_t);
		(yyval.drop_index_stmt_t)->opt_extra_option_ = (yyvsp[0].opt_extra_option_t);
		if((yyval.drop_index_stmt_t)){
			auto tmp1 = (yyval.drop_index_stmt_t)->table_name_; 
			if(tmp1){
				auto tmp2 = tmp1->identifier_; 
				if(tmp2){
					tmp2->data_type_ = kDataTableName; 
					tmp2->scope_ = 1; 
					tmp2->data_flag_ =(DATAFLAG)2; 
				}
			}
		}


	}
#line 5821 "y.tab.c"
    break;

  case 173:
#line 1875 "bison.y"
                                                                             {
		(yyval.drop_table_stmt_t) = new DropTableStmt();
		(yyval.drop_table_stmt_t)->case_idx_ = CASE0;
		(yyval.drop_table_stmt_t)->opt_temp_ = (yyvsp[-4].opt_temp_t);
		(yyval.drop_table_stmt_t)->opt_if_exist_ = (yyvsp[-2].opt_if_exist_t);
		(yyval.drop_table_stmt_t)->table_name_ = (yyvsp[-1].table_name_t);
		(yyval.drop_table_stmt_t)->opt_restrict_or_cascade_ = (yyvsp[0].opt_restrict_or_cascade_t);
		if((yyval.drop_table_stmt_t)){
			auto tmp1 = (yyval.drop_table_stmt_t)->table_name_; 
			if(tmp1){
				auto tmp2 = tmp1->identifier_; 
				if(tmp2){
					tmp2->data_type_ = kDataTableName; 
					tmp2->scope_ = 1; 
					tmp2->data_flag_ =(DATAFLAG)2; 
				}
			}
		}


	}
#line 5847 "y.tab.c"
    break;

  case 174:
#line 1899 "bison.y"
                  {
		(yyval.opt_restrict_or_cascade_t) = new OptRestrictOrCascade();
		(yyval.opt_restrict_or_cascade_t)->case_idx_ = CASE0;
		
	}
#line 5857 "y.tab.c"
    break;

  case 175:
#line 1904 "bison.y"
                 {
		(yyval.opt_restrict_or_cascade_t) = new OptRestrictOrCascade();
		(yyval.opt_restrict_or_cascade_t)->case_idx_ = CASE1;
		
	}
#line 5867 "y.tab.c"
    break;

  case 176:
#line 1909 "bison.y"
          {
		(yyval.opt_restrict_or_cascade_t) = new OptRestrictOrCascade();
		(yyval.opt_restrict_or_cascade_t)->case_idx_ = CASE2;
		
	}
#line 5877 "y.tab.c"
    break;

  case 177:
#line 1917 "bison.y"
                                                {
		(yyval.drop_trigger_stmt_t) = new DropTriggerStmt();
		(yyval.drop_trigger_stmt_t)->case_idx_ = CASE0;
		(yyval.drop_trigger_stmt_t)->opt_if_exist_ = (yyvsp[-1].opt_if_exist_t);
		(yyval.drop_trigger_stmt_t)->trigger_name_ = (yyvsp[0].trigger_name_t);
		if((yyval.drop_trigger_stmt_t)){
			auto tmp1 = (yyval.drop_trigger_stmt_t)->trigger_name_; 
			if(tmp1){
				auto tmp2 = tmp1->identifier_; 
				if(tmp2){
					tmp2->data_type_ = kDataTriggerName; 
					tmp2->scope_ = 1; 
					tmp2->data_flag_ =(DATAFLAG)2; 
				}
			}
		}


	}
#line 5901 "y.tab.c"
    break;

  case 178:
#line 1939 "bison.y"
                                                                  {
		(yyval.drop_view_stmt_t) = new DropViewStmt();
		(yyval.drop_view_stmt_t)->case_idx_ = CASE0;
		(yyval.drop_view_stmt_t)->opt_if_exist_ = (yyvsp[-2].opt_if_exist_t);
		(yyval.drop_view_stmt_t)->view_name_ = (yyvsp[-1].view_name_t);
		(yyval.drop_view_stmt_t)->opt_restrict_or_cascade_ = (yyvsp[0].opt_restrict_or_cascade_t);
		if((yyval.drop_view_stmt_t)){
			auto tmp1 = (yyval.drop_view_stmt_t)->view_name_; 
			if(tmp1){
				auto tmp2 = tmp1->identifier_; 
				if(tmp2){
					tmp2->data_type_ = kDataTableName; 
					tmp2->scope_ = 1; 
					tmp2->data_flag_ =(DATAFLAG)2; 
				}
			}
		}


	}
#line 5926 "y.tab.c"
    break;

  case 179:
#line 1962 "bison.y"
                                                                                         {
		(yyval.insert_stmt_t) = new InsertStmt();
		(yyval.insert_stmt_t)->case_idx_ = CASE0;
		(yyval.insert_stmt_t)->opt_with_clause_ = (yyvsp[-6].opt_with_clause_t);
		(yyval.insert_stmt_t)->table_name_ = (yyvsp[-3].table_name_t);
		(yyval.insert_stmt_t)->opt_as_alias_ = (yyvsp[-2].opt_as_alias_t);
		(yyval.insert_stmt_t)->insert_rest_ = (yyvsp[-1].insert_rest_t);
		(yyval.insert_stmt_t)->opt_on_conflict_ = (yyvsp[0].opt_on_conflict_t);
		
	}
#line 5941 "y.tab.c"
    break;

  case 180:
#line 1975 "bison.y"
                                                 {
		(yyval.insert_rest_t) = new InsertRest();
		(yyval.insert_rest_t)->case_idx_ = CASE0;
		(yyval.insert_rest_t)->opt_column_name_list_p_ = (yyvsp[-1].opt_column_name_list_p_t);
		(yyval.insert_rest_t)->select_no_parens_ = (yyvsp[0].select_no_parens_t);
		
	}
#line 5953 "y.tab.c"
    break;

  case 181:
#line 1982 "bison.y"
                                               {
		(yyval.insert_rest_t) = new InsertRest();
		(yyval.insert_rest_t)->case_idx_ = CASE1;
		(yyval.insert_rest_t)->opt_column_name_list_p_ = (yyvsp[-2].opt_column_name_list_p_t);
		
	}
#line 5964 "y.tab.c"
    break;

  case 182:
#line 1988 "bison.y"
                                                         {
		(yyval.insert_rest_t) = new InsertRest();
		(yyval.insert_rest_t)->case_idx_ = CASE2;
		(yyval.insert_rest_t)->opt_column_name_list_p_ = (yyvsp[-2].opt_column_name_list_p_t);
		(yyval.insert_rest_t)->super_values_list_ = (yyvsp[0].super_values_list_t);
		
	}
#line 5976 "y.tab.c"
    break;

  case 183:
#line 1998 "bison.y"
                     {
		(yyval.super_values_list_t) = new SuperValuesList();
		(yyval.super_values_list_t)->case_idx_ = CASE0;
		(yyval.super_values_list_t)->values_list_ = (yyvsp[0].values_list_t);
		
	}
#line 5987 "y.tab.c"
    break;

  case 184:
#line 2004 "bison.y"
                                                {
		(yyval.super_values_list_t) = new SuperValuesList();
		(yyval.super_values_list_t)->case_idx_ = CASE1;
		(yyval.super_values_list_t)->values_list_ = (yyvsp[-2].values_list_t);
		(yyval.super_values_list_t)->super_values_list_ = (yyvsp[0].super_values_list_t);
		
	}
#line 5999 "y.tab.c"
    break;

  case 185:
#line 2014 "bison.y"
                               {
		(yyval.values_list_t) = new ValuesList();
		(yyval.values_list_t)->case_idx_ = CASE0;
		(yyval.values_list_t)->expr_list_ = (yyvsp[-1].expr_list_t);
		
	}
#line 6010 "y.tab.c"
    break;

  case 186:
#line 2023 "bison.y"
                                                  {
		(yyval.opt_on_conflict_t) = new OptOnConflict();
		(yyval.opt_on_conflict_t)->case_idx_ = CASE0;
		(yyval.opt_on_conflict_t)->opt_conflict_expr_ = (yyvsp[-2].opt_conflict_expr_t);
		
	}
#line 6021 "y.tab.c"
    break;

  case 187:
#line 2029 "bison.y"
                                                                              {
		(yyval.opt_on_conflict_t) = new OptOnConflict();
		(yyval.opt_on_conflict_t)->case_idx_ = CASE1;
		(yyval.opt_on_conflict_t)->opt_conflict_expr_ = (yyvsp[-4].opt_conflict_expr_t);
		(yyval.opt_on_conflict_t)->set_clause_list_ = (yyvsp[-1].set_clause_list_t);
		(yyval.opt_on_conflict_t)->where_clause_ = (yyvsp[0].where_clause_t);
		
	}
#line 6034 "y.tab.c"
    break;

  case 188:
#line 2037 "bison.y"
          {
		(yyval.opt_on_conflict_t) = new OptOnConflict();
		(yyval.opt_on_conflict_t)->case_idx_ = CASE2;
		
	}
#line 6044 "y.tab.c"
    break;

  case 189:
#line 2045 "bison.y"
                                                      {
		(yyval.opt_conflict_expr_t) = new OptConflictExpr();
		(yyval.opt_conflict_expr_t)->case_idx_ = CASE0;
		(yyval.opt_conflict_expr_t)->indexed_column_list_ = (yyvsp[-2].indexed_column_list_t);
		(yyval.opt_conflict_expr_t)->where_clause_ = (yyvsp[0].where_clause_t);
		
	}
#line 6056 "y.tab.c"
    break;

  case 190:
#line 2052 "bison.y"
          {
		(yyval.opt_conflict_expr_t) = new OptConflictExpr();
		(yyval.opt_conflict_expr_t)->case_idx_ = CASE1;
		
	}
#line 6066 "y.tab.c"
    break;

  case 191:
#line 2060 "bison.y"
                        {
		(yyval.indexed_column_list_t) = new IndexedColumnList();
		(yyval.indexed_column_list_t)->case_idx_ = CASE0;
		(yyval.indexed_column_list_t)->indexed_column_ = (yyvsp[0].indexed_column_t);
		
	}
#line 6077 "y.tab.c"
    break;

  case 192:
#line 2066 "bison.y"
                                                     {
		(yyval.indexed_column_list_t) = new IndexedColumnList();
		(yyval.indexed_column_list_t)->case_idx_ = CASE1;
		(yyval.indexed_column_list_t)->indexed_column_ = (yyvsp[-2].indexed_column_t);
		(yyval.indexed_column_list_t)->indexed_column_list_ = (yyvsp[0].indexed_column_list_t);
		
	}
#line 6089 "y.tab.c"
    break;

  case 193:
#line 2076 "bison.y"
                                 {
		(yyval.indexed_column_t) = new IndexedColumn();
		(yyval.indexed_column_t)->case_idx_ = CASE0;
		(yyval.indexed_column_t)->expr_ = (yyvsp[-1].expr_t);
		(yyval.indexed_column_t)->opt_order_behavior_ = (yyvsp[0].opt_order_behavior_t);
		
	}
#line 6101 "y.tab.c"
    break;

  case 194:
#line 2086 "bison.y"
                                                                                                                         {
		(yyval.update_stmt_t) = new UpdateStmt();
		(yyval.update_stmt_t)->case_idx_ = CASE0;
		(yyval.update_stmt_t)->table_name_ = (yyvsp[-6].table_name_t);
		(yyval.update_stmt_t)->opt_as_alias_ = (yyvsp[-5].opt_as_alias_t);
		(yyval.update_stmt_t)->set_clause_list_ = (yyvsp[-3].set_clause_list_t);
		(yyval.update_stmt_t)->opt_where_clause_ = (yyvsp[-2].opt_where_clause_t);
		(yyval.update_stmt_t)->opt_order_clause_ = (yyvsp[-1].opt_order_clause_t);
		(yyval.update_stmt_t)->opt_limit_row_count_ = (yyvsp[0].opt_limit_row_count_t);
		
	}
#line 6117 "y.tab.c"
    break;

  case 195:
#line 2097 "bison.y"
                                                                                                                  {
		(yyval.update_stmt_t) = new UpdateStmt();
		(yyval.update_stmt_t)->case_idx_ = CASE1;
		(yyval.update_stmt_t)->table_name_ = (yyvsp[-6].table_name_t);
		(yyval.update_stmt_t)->opt_as_alias_ = (yyvsp[-5].opt_as_alias_t);
		(yyval.update_stmt_t)->set_clause_list_ = (yyvsp[-3].set_clause_list_t);
		(yyval.update_stmt_t)->opt_where_clause_ = (yyvsp[-2].opt_where_clause_t);
		(yyval.update_stmt_t)->opt_order_clause_ = (yyvsp[-1].opt_order_clause_t);
		(yyval.update_stmt_t)->opt_limit_row_count_ = (yyvsp[0].opt_limit_row_count_t);
		
	}
#line 6133 "y.tab.c"
    break;

  case 196:
#line 2111 "bison.y"
                              {
		(yyval.alter_action_t) = new AlterAction();
		(yyval.alter_action_t)->case_idx_ = CASE0;
		(yyval.alter_action_t)->table_name_ = (yyvsp[0].table_name_t);
		if((yyval.alter_action_t)){
			auto tmp1 = (yyval.alter_action_t)->table_name_; 
			if(tmp1){
				auto tmp2 = tmp1->identifier_; 
				if(tmp2){
					tmp2->data_type_ = kDataTableName; 
					tmp2->scope_ = 2; 
					tmp2->data_flag_ =(DATAFLAG)64; 
				}
			}
		}


	}
#line 6156 "y.tab.c"
    break;

  case 197:
#line 2129 "bison.y"
                                                      {
		(yyval.alter_action_t) = new AlterAction();
		(yyval.alter_action_t)->case_idx_ = CASE1;
		(yyval.alter_action_t)->opt_column_ = (yyvsp[-3].opt_column_t);
		(yyval.alter_action_t)->column_name_1_ = (yyvsp[-2].column_name_t);
		(yyval.alter_action_t)->column_name_2_ = (yyvsp[0].column_name_t);
		if((yyval.alter_action_t)){
			auto tmp1 = (yyval.alter_action_t)->column_name_1_; 
			if(tmp1){
				auto tmp2 = tmp1->identifier_; 
				if(tmp2){
					tmp2->data_type_ = kDataColumnName; 
					tmp2->scope_ = 2; 
					tmp2->data_flag_ =(DATAFLAG)8; 
				}
			}
		}

		if((yyval.alter_action_t)){
			auto tmp1 = (yyval.alter_action_t)->column_name_2_; 
			if(tmp1){
				auto tmp2 = tmp1->identifier_; 
				if(tmp2){
					tmp2->data_type_ = kDataColumnName; 
					tmp2->scope_ = 3; 
					tmp2->data_flag_ =(DATAFLAG)64; 
				}
			}
		}


	}
#line 6193 "y.tab.c"
    break;

  case 198:
#line 2161 "bison.y"
                                   {
		(yyval.alter_action_t) = new AlterAction();
		(yyval.alter_action_t)->case_idx_ = CASE2;
		(yyval.alter_action_t)->opt_column_ = (yyvsp[-1].opt_column_t);
		(yyval.alter_action_t)->column_def_ = (yyvsp[0].column_def_t);
		if((yyval.alter_action_t)){
			auto tmp1 = (yyval.alter_action_t)->column_def_; 
			if(tmp1){
				auto tmp2 = tmp1->identifier_; 
				if(tmp2){
					tmp2->data_type_ = kDataColumnName; 
					tmp2->scope_ = 2; 
					tmp2->data_flag_ =(DATAFLAG)1; 
				}
			}
		}


	}
#line 6217 "y.tab.c"
    break;

  case 199:
#line 2180 "bison.y"
                                     {
		(yyval.alter_action_t) = new AlterAction();
		(yyval.alter_action_t)->case_idx_ = CASE3;
		(yyval.alter_action_t)->opt_column_ = (yyvsp[-1].opt_column_t);
		(yyval.alter_action_t)->column_name_1_ = (yyvsp[0].column_name_t);
		if((yyval.alter_action_t)){
			auto tmp1 = (yyval.alter_action_t)->column_name_1_; 
			if(tmp1){
				auto tmp2 = tmp1->identifier_; 
				if(tmp2){
					tmp2->data_type_ = kDataColumnName; 
					tmp2->scope_ = 2; 
					tmp2->data_flag_ =(DATAFLAG)2; 
				}
			}
		}


	}
#line 6241 "y.tab.c"
    break;

  case 200:
#line 2199 "bison.y"
                               {
		(yyval.alter_action_t) = new AlterAction();
		(yyval.alter_action_t)->case_idx_ = CASE4;
		(yyval.alter_action_t)->alter_constant_action_ = (yyvsp[0].alter_constant_action_t);
		
	}
#line 6252 "y.tab.c"
    break;

  case 201:
#line 2208 "bison.y"
                          {
		(yyval.alter_constant_action_t) = new AlterConstantAction();
		(yyval.alter_constant_action_t)->case_idx_ = CASE0;
		
	}
#line 6262 "y.tab.c"
    break;

  case 202:
#line 2213 "bison.y"
               {
		(yyval.alter_constant_action_t) = new AlterConstantAction();
		(yyval.alter_constant_action_t)->case_idx_ = CASE1;
		
	}
#line 6272 "y.tab.c"
    break;

  case 203:
#line 2218 "bison.y"
                      {
		(yyval.alter_constant_action_t) = new AlterConstantAction();
		(yyval.alter_constant_action_t)->case_idx_ = CASE2;
		
	}
#line 6282 "y.tab.c"
    break;

  case 204:
#line 2223 "bison.y"
                     {
		(yyval.alter_constant_action_t) = new AlterConstantAction();
		(yyval.alter_constant_action_t)->case_idx_ = CASE3;
		
	}
#line 6292 "y.tab.c"
    break;

  case 205:
#line 2228 "bison.y"
                     {
		(yyval.alter_constant_action_t) = new AlterConstantAction();
		(yyval.alter_constant_action_t)->case_idx_ = CASE4;
		(yyval.alter_constant_action_t)->lock_option_ = (yyvsp[0].lock_option_t);
		
	}
#line 6303 "y.tab.c"
    break;

  case 206:
#line 2234 "bison.y"
                         {
		(yyval.alter_constant_action_t) = new AlterConstantAction();
		(yyval.alter_constant_action_t)->case_idx_ = CASE5;
		
	}
#line 6313 "y.tab.c"
    break;

  case 207:
#line 2239 "bison.y"
                            {
		(yyval.alter_constant_action_t) = new AlterConstantAction();
		(yyval.alter_constant_action_t)->case_idx_ = CASE6;
		
	}
#line 6323 "y.tab.c"
    break;

  case 208:
#line 2247 "bison.y"
                    {
		(yyval.column_def_list_t) = new ColumnDefList();
		(yyval.column_def_list_t)->case_idx_ = CASE0;
		(yyval.column_def_list_t)->column_def_ = (yyvsp[0].column_def_t);
		
	}
#line 6334 "y.tab.c"
    break;

  case 209:
#line 2253 "bison.y"
                                             {
		(yyval.column_def_list_t) = new ColumnDefList();
		(yyval.column_def_list_t)->case_idx_ = CASE1;
		(yyval.column_def_list_t)->column_def_ = (yyvsp[-2].column_def_t);
		(yyval.column_def_list_t)->column_def_list_ = (yyvsp[0].column_def_list_t);
		
	}
#line 6346 "y.tab.c"
    break;

  case 210:
#line 2263 "bison.y"
                                                         {
		(yyval.column_def_t) = new ColumnDef();
		(yyval.column_def_t)->case_idx_ = CASE0;
		(yyval.column_def_t)->identifier_ = (yyvsp[-2].identifier_t);
		(yyval.column_def_t)->type_name_ = (yyvsp[-1].type_name_t);
		(yyval.column_def_t)->opt_column_constraint_list_ = (yyvsp[0].opt_column_constraint_list_t);
		if((yyval.column_def_t)){
			auto tmp1 = (yyval.column_def_t)->identifier_; 
			if(tmp1){
				tmp1->data_type_ = kDataColumnName; 
				tmp1->scope_ = 2; 
				tmp1->data_flag_ =(DATAFLAG)1; 
			}
		}


	}
#line 6368 "y.tab.c"
    break;

  case 211:
#line 2283 "bison.y"
                                                               {
		(yyval.opt_column_constraint_list_t) = new OptColumnConstraintList();
		(yyval.opt_column_constraint_list_t)->case_idx_ = CASE0;
		(yyval.opt_column_constraint_list_t)->column_constraint_list_ = (yyvsp[-2].column_constraint_list_t);
		(yyval.opt_column_constraint_list_t)->opt_check_ = (yyvsp[-1].opt_check_t);
		(yyval.opt_column_constraint_list_t)->opt_reference_clause_ = (yyvsp[0].opt_reference_clause_t);
		
	}
#line 6381 "y.tab.c"
    break;

  case 212:
#line 2291 "bison.y"
          {
		(yyval.opt_column_constraint_list_t) = new OptColumnConstraintList();
		(yyval.opt_column_constraint_list_t)->case_idx_ = CASE1;
		
	}
#line 6391 "y.tab.c"
    break;

  case 213:
#line 2299 "bison.y"
                           {
		(yyval.column_constraint_list_t) = new ColumnConstraintList();
		(yyval.column_constraint_list_t)->case_idx_ = CASE0;
		(yyval.column_constraint_list_t)->column_constraint_ = (yyvsp[0].column_constraint_t);
		
	}
#line 6402 "y.tab.c"
    break;

  case 214:
#line 2305 "bison.y"
                                                  {
		(yyval.column_constraint_list_t) = new ColumnConstraintList();
		(yyval.column_constraint_list_t)->case_idx_ = CASE1;
		(yyval.column_constraint_list_t)->column_constraint_ = (yyvsp[-1].column_constraint_t);
		(yyval.column_constraint_list_t)->column_constraint_list_ = (yyvsp[0].column_constraint_list_t);
		
	}
#line 6414 "y.tab.c"
    break;

  case 215:
#line 2315 "bison.y"
                         {
		(yyval.column_constraint_t) = new ColumnConstraint();
		(yyval.column_constraint_t)->case_idx_ = CASE0;
		(yyval.column_constraint_t)->constraint_type_ = (yyvsp[0].constraint_type_t);
		
	}
#line 6425 "y.tab.c"
    break;

  case 216:
#line 2324 "bison.y"
                                          {
		(yyval.opt_reference_clause_t) = new OptReferenceClause();
		(yyval.opt_reference_clause_t)->case_idx_ = CASE0;
		(yyval.opt_reference_clause_t)->opt_foreign_key_ = (yyvsp[-1].opt_foreign_key_t);
		(yyval.opt_reference_clause_t)->reference_clause_ = (yyvsp[0].reference_clause_t);
		
	}
#line 6437 "y.tab.c"
    break;

  case 217:
#line 2331 "bison.y"
          {
		(yyval.opt_reference_clause_t) = new OptReferenceClause();
		(yyval.opt_reference_clause_t)->case_idx_ = CASE1;
		
	}
#line 6447 "y.tab.c"
    break;

  case 218:
#line 2339 "bison.y"
                                             {
		(yyval.opt_check_t) = new OptCheck();
		(yyval.opt_check_t)->case_idx_ = CASE0;
		(yyval.opt_check_t)->expr_ = (yyvsp[-2].expr_t);
		(yyval.opt_check_t)->opt_enforced_ = (yyvsp[0].opt_enforced_t);
		
	}
#line 6459 "y.tab.c"
    break;

  case 219:
#line 2346 "bison.y"
          {
		(yyval.opt_check_t) = new OptCheck();
		(yyval.opt_check_t)->case_idx_ = CASE1;
		
	}
#line 6469 "y.tab.c"
    break;

  case 220:
#line 2354 "bison.y"
                     {
		(yyval.constraint_type_t) = new ConstraintType();
		(yyval.constraint_type_t)->case_idx_ = CASE0;
		
	}
#line 6479 "y.tab.c"
    break;

  case 221:
#line 2359 "bison.y"
                  {
		(yyval.constraint_type_t) = new ConstraintType();
		(yyval.constraint_type_t)->case_idx_ = CASE1;
		
	}
#line 6489 "y.tab.c"
    break;

  case 222:
#line 2364 "bison.y"
                {
		(yyval.constraint_type_t) = new ConstraintType();
		(yyval.constraint_type_t)->case_idx_ = CASE2;
		
	}
#line 6499 "y.tab.c"
    break;

  case 223:
#line 2372 "bison.y"
                                                                                                            {
		(yyval.reference_clause_t) = new ReferenceClause();
		(yyval.reference_clause_t)->case_idx_ = CASE0;
		(yyval.reference_clause_t)->table_name_ = (yyvsp[-3].table_name_t);
		(yyval.reference_clause_t)->opt_column_name_list_p_ = (yyvsp[-2].opt_column_name_list_p_t);
		(yyval.reference_clause_t)->opt_foreign_key_actions_ = (yyvsp[-1].opt_foreign_key_actions_t);
		(yyval.reference_clause_t)->opt_constraint_attribute_spec_ = (yyvsp[0].opt_constraint_attribute_spec_t);
		if((yyval.reference_clause_t)){
			auto tmp1 = (yyval.reference_clause_t)->table_name_; 
			if(tmp1){
				auto tmp2 = tmp1->identifier_; 
				if(tmp2){
					tmp2->data_type_ = kDataTableName; 
					tmp2->scope_ = 100; 
					tmp2->data_flag_ =(DATAFLAG)8; 
				}
			}
		}

		if((yyval.reference_clause_t)){
			auto tmp1 = (yyval.reference_clause_t)->opt_column_name_list_p_; 
			if(tmp1){
				auto tmp2 = tmp1->column_name_list_; 
				while(tmp2){
					auto tmp3 = tmp2->column_name_; 
					if(tmp3){
						auto tmp4 = tmp3->identifier_; 
						if(tmp4){
							tmp4->data_type_ = kDataColumnName; 
							tmp4->scope_ = 101; 
							tmp4->data_flag_ =(DATAFLAG)8; 
						}
					}
					tmp2 = tmp2->column_name_list_;
				}
			}
		}


	}
#line 6544 "y.tab.c"
    break;

  case 224:
#line 2415 "bison.y"
                     {
		(yyval.opt_foreign_key_t) = new OptForeignKey();
		(yyval.opt_foreign_key_t)->case_idx_ = CASE0;
		
	}
#line 6554 "y.tab.c"
    break;

  case 225:
#line 2420 "bison.y"
          {
		(yyval.opt_foreign_key_t) = new OptForeignKey();
		(yyval.opt_foreign_key_t)->case_idx_ = CASE1;
		
	}
#line 6564 "y.tab.c"
    break;

  case 226:
#line 2428 "bison.y"
                             {
		(yyval.opt_foreign_key_actions_t) = new OptForeignKeyActions();
		(yyval.opt_foreign_key_actions_t)->case_idx_ = CASE0;
		(yyval.opt_foreign_key_actions_t)->foreign_key_actions_ = (yyvsp[0].foreign_key_actions_t);
		
	}
#line 6575 "y.tab.c"
    break;

  case 227:
#line 2434 "bison.y"
          {
		(yyval.opt_foreign_key_actions_t) = new OptForeignKeyActions();
		(yyval.opt_foreign_key_actions_t)->case_idx_ = CASE1;
		
	}
#line 6585 "y.tab.c"
    break;

  case 228:
#line 2442 "bison.y"
                    {
		(yyval.foreign_key_actions_t) = new ForeignKeyActions();
		(yyval.foreign_key_actions_t)->case_idx_ = CASE0;
		
	}
#line 6595 "y.tab.c"
    break;

  case 229:
#line 2447 "bison.y"
                       {
		(yyval.foreign_key_actions_t) = new ForeignKeyActions();
		(yyval.foreign_key_actions_t)->case_idx_ = CASE1;
		
	}
#line 6605 "y.tab.c"
    break;

  case 230:
#line 2452 "bison.y"
                      {
		(yyval.foreign_key_actions_t) = new ForeignKeyActions();
		(yyval.foreign_key_actions_t)->case_idx_ = CASE2;
		
	}
#line 6615 "y.tab.c"
    break;

  case 231:
#line 2457 "bison.y"
                               {
		(yyval.foreign_key_actions_t) = new ForeignKeyActions();
		(yyval.foreign_key_actions_t)->case_idx_ = CASE3;
		(yyval.foreign_key_actions_t)->key_actions_ = (yyvsp[0].key_actions_t);
		
	}
#line 6626 "y.tab.c"
    break;

  case 232:
#line 2463 "bison.y"
                               {
		(yyval.foreign_key_actions_t) = new ForeignKeyActions();
		(yyval.foreign_key_actions_t)->case_idx_ = CASE4;
		(yyval.foreign_key_actions_t)->key_actions_ = (yyvsp[0].key_actions_t);
		
	}
#line 6637 "y.tab.c"
    break;

  case 233:
#line 2472 "bison.y"
                  {
		(yyval.key_actions_t) = new KeyActions();
		(yyval.key_actions_t)->case_idx_ = CASE0;
		
	}
#line 6647 "y.tab.c"
    break;

  case 234:
#line 2477 "bison.y"
                     {
		(yyval.key_actions_t) = new KeyActions();
		(yyval.key_actions_t)->case_idx_ = CASE1;
		
	}
#line 6657 "y.tab.c"
    break;

  case 235:
#line 2482 "bison.y"
                 {
		(yyval.key_actions_t) = new KeyActions();
		(yyval.key_actions_t)->case_idx_ = CASE2;
		
	}
#line 6667 "y.tab.c"
    break;

  case 236:
#line 2487 "bison.y"
                  {
		(yyval.key_actions_t) = new KeyActions();
		(yyval.key_actions_t)->case_idx_ = CASE3;
		
	}
#line 6677 "y.tab.c"
    break;

  case 237:
#line 2492 "bison.y"
                   {
		(yyval.key_actions_t) = new KeyActions();
		(yyval.key_actions_t)->case_idx_ = CASE4;
		
	}
#line 6687 "y.tab.c"
    break;

  case 238:
#line 2500 "bison.y"
                                      {
		(yyval.opt_constraint_attribute_spec_t) = new OptConstraintAttributeSpec();
		(yyval.opt_constraint_attribute_spec_t)->case_idx_ = CASE0;
		(yyval.opt_constraint_attribute_spec_t)->opt_initial_time_ = (yyvsp[0].opt_initial_time_t);
		
	}
#line 6698 "y.tab.c"
    break;

  case 239:
#line 2506 "bison.y"
                                          {
		(yyval.opt_constraint_attribute_spec_t) = new OptConstraintAttributeSpec();
		(yyval.opt_constraint_attribute_spec_t)->case_idx_ = CASE1;
		(yyval.opt_constraint_attribute_spec_t)->opt_initial_time_ = (yyvsp[0].opt_initial_time_t);
		
	}
#line 6709 "y.tab.c"
    break;

  case 240:
#line 2512 "bison.y"
          {
		(yyval.opt_constraint_attribute_spec_t) = new OptConstraintAttributeSpec();
		(yyval.opt_constraint_attribute_spec_t)->case_idx_ = CASE2;
		
	}
#line 6719 "y.tab.c"
    break;

  case 241:
#line 2520 "bison.y"
                            {
		(yyval.opt_initial_time_t) = new OptInitialTime();
		(yyval.opt_initial_time_t)->case_idx_ = CASE0;
		
	}
#line 6729 "y.tab.c"
    break;

  case 242:
#line 2525 "bison.y"
                             {
		(yyval.opt_initial_time_t) = new OptInitialTime();
		(yyval.opt_initial_time_t)->case_idx_ = CASE1;
		
	}
#line 6739 "y.tab.c"
    break;

  case 243:
#line 2530 "bison.y"
          {
		(yyval.opt_initial_time_t) = new OptInitialTime();
		(yyval.opt_initial_time_t)->case_idx_ = CASE2;
		
	}
#line 6749 "y.tab.c"
    break;

  case 244:
#line 2538 "bison.y"
                         {
		(yyval.constraint_name_t) = new ConstraintName();
		(yyval.constraint_name_t)->case_idx_ = CASE0;
		(yyval.constraint_name_t)->name_ = (yyvsp[0].name_t);
		
	}
#line 6760 "y.tab.c"
    break;

  case 245:
#line 2547 "bison.y"
                   {
		(yyval.opt_temp_t) = new OptTemp();
		(yyval.opt_temp_t)->case_idx_ = CASE0;
		
	}
#line 6770 "y.tab.c"
    break;

  case 246:
#line 2552 "bison.y"
          {
		(yyval.opt_temp_t) = new OptTemp();
		(yyval.opt_temp_t)->case_idx_ = CASE1;
		
	}
#line 6780 "y.tab.c"
    break;

  case 247:
#line 2560 "bison.y"
                           {
		(yyval.opt_check_option_t) = new OptCheckOption();
		(yyval.opt_check_option_t)->case_idx_ = CASE0;
		
	}
#line 6790 "y.tab.c"
    break;

  case 248:
#line 2565 "bison.y"
                                    {
		(yyval.opt_check_option_t) = new OptCheckOption();
		(yyval.opt_check_option_t)->case_idx_ = CASE1;
		
	}
#line 6800 "y.tab.c"
    break;

  case 249:
#line 2570 "bison.y"
                                 {
		(yyval.opt_check_option_t) = new OptCheckOption();
		(yyval.opt_check_option_t)->case_idx_ = CASE2;
		
	}
#line 6810 "y.tab.c"
    break;

  case 250:
#line 2575 "bison.y"
          {
		(yyval.opt_check_option_t) = new OptCheckOption();
		(yyval.opt_check_option_t)->case_idx_ = CASE3;
		
	}
#line 6820 "y.tab.c"
    break;

  case 251:
#line 2583 "bison.y"
                                      {
		(yyval.opt_column_name_list_p_t) = new OptColumnNameListP();
		(yyval.opt_column_name_list_p_t)->case_idx_ = CASE0;
		(yyval.opt_column_name_list_p_t)->column_name_list_ = (yyvsp[-1].column_name_list_t);
		
	}
#line 6831 "y.tab.c"
    break;

  case 252:
#line 2589 "bison.y"
          {
		(yyval.opt_column_name_list_p_t) = new OptColumnNameListP();
		(yyval.opt_column_name_list_p_t)->case_idx_ = CASE1;
		
	}
#line 6841 "y.tab.c"
    break;

  case 253:
#line 2597 "bison.y"
                    {
		(yyval.set_clause_list_t) = new SetClauseList();
		(yyval.set_clause_list_t)->case_idx_ = CASE0;
		(yyval.set_clause_list_t)->set_clause_ = (yyvsp[0].set_clause_t);
		
	}
#line 6852 "y.tab.c"
    break;

  case 254:
#line 2603 "bison.y"
                                             {
		(yyval.set_clause_list_t) = new SetClauseList();
		(yyval.set_clause_list_t)->case_idx_ = CASE1;
		(yyval.set_clause_list_t)->set_clause_ = (yyvsp[-2].set_clause_t);
		(yyval.set_clause_list_t)->set_clause_list_ = (yyvsp[0].set_clause_list_t);
		
	}
#line 6864 "y.tab.c"
    break;

  case 255:
#line 2613 "bison.y"
                                   {
		(yyval.set_clause_t) = new SetClause();
		(yyval.set_clause_t)->case_idx_ = CASE0;
		(yyval.set_clause_t)->column_name_ = (yyvsp[-2].column_name_t);
		(yyval.set_clause_t)->expr_ = (yyvsp[0].expr_t);
		
	}
#line 6876 "y.tab.c"
    break;

  case 256:
#line 2620 "bison.y"
                                                    {
		(yyval.set_clause_t) = new SetClause();
		(yyval.set_clause_t)->case_idx_ = CASE1;
		(yyval.set_clause_t)->column_name_list_ = (yyvsp[-3].column_name_list_t);
		(yyval.set_clause_t)->expr_ = (yyvsp[0].expr_t);
		
	}
#line 6888 "y.tab.c"
    break;

  case 257:
#line 2630 "bison.y"
                  {
		(yyval.opt_as_alias_t) = new OptAsAlias();
		(yyval.opt_as_alias_t)->case_idx_ = CASE0;
		(yyval.opt_as_alias_t)->as_alias_ = (yyvsp[0].as_alias_t);
		
	}
#line 6899 "y.tab.c"
    break;

  case 258:
#line 2636 "bison.y"
          {
		(yyval.opt_as_alias_t) = new OptAsAlias();
		(yyval.opt_as_alias_t)->case_idx_ = CASE1;
		
	}
#line 6909 "y.tab.c"
    break;

  case 259:
#line 2644 "bison.y"
                 {
		(yyval.expr_t) = new Expr();
		(yyval.expr_t)->case_idx_ = CASE0;
		(yyval.expr_t)->operand_ = (yyvsp[0].operand_t);
		
	}
#line 6920 "y.tab.c"
    break;

  case 260:
#line 2650 "bison.y"
                      {
		(yyval.expr_t) = new Expr();
		(yyval.expr_t)->case_idx_ = CASE1;
		(yyval.expr_t)->between_expr_ = (yyvsp[0].between_expr_t);
		
	}
#line 6931 "y.tab.c"
    break;

  case 261:
#line 2656 "bison.y"
                     {
		(yyval.expr_t) = new Expr();
		(yyval.expr_t)->case_idx_ = CASE2;
		(yyval.expr_t)->exists_expr_ = (yyvsp[0].exists_expr_t);
		
	}
#line 6942 "y.tab.c"
    break;

  case 262:
#line 2662 "bison.y"
                 {
		(yyval.expr_t) = new Expr();
		(yyval.expr_t)->case_idx_ = CASE3;
		(yyval.expr_t)->in_expr_ = (yyvsp[0].in_expr_t);
		
	}
#line 6953 "y.tab.c"
    break;

  case 263:
#line 2668 "bison.y"
                   {
		(yyval.expr_t) = new Expr();
		(yyval.expr_t)->case_idx_ = CASE4;
		(yyval.expr_t)->cast_expr_ = (yyvsp[0].cast_expr_t);
		
	}
#line 6964 "y.tab.c"
    break;

  case 264:
#line 2674 "bison.y"
                    {
		(yyval.expr_t) = new Expr();
		(yyval.expr_t)->case_idx_ = CASE5;
		(yyval.expr_t)->logic_expr_ = (yyvsp[0].logic_expr_t);
		
	}
#line 6975 "y.tab.c"
    break;

  case 265:
#line 2683 "bison.y"
                               {
		(yyval.operand_t) = new Operand();
		(yyval.operand_t)->case_idx_ = CASE0;
		(yyval.operand_t)->expr_list_ = (yyvsp[-1].expr_list_t);
		
	}
#line 6986 "y.tab.c"
    break;

  case 266:
#line 2689 "bison.y"
                     {
		(yyval.operand_t) = new Operand();
		(yyval.operand_t)->case_idx_ = CASE1;
		(yyval.operand_t)->array_index_ = (yyvsp[0].array_index_t);
		
	}
#line 6997 "y.tab.c"
    break;

  case 267:
#line 2695 "bison.y"
                     {
		(yyval.operand_t) = new Operand();
		(yyval.operand_t)->case_idx_ = CASE2;
		(yyval.operand_t)->scalar_expr_ = (yyvsp[0].scalar_expr_t);
		
	}
#line 7008 "y.tab.c"
    break;

  case 268:
#line 2701 "bison.y"
                    {
		(yyval.operand_t) = new Operand();
		(yyval.operand_t)->case_idx_ = CASE3;
		(yyval.operand_t)->unary_expr_ = (yyvsp[0].unary_expr_t);
		
	}
#line 7019 "y.tab.c"
    break;

  case 269:
#line 2707 "bison.y"
                     {
		(yyval.operand_t) = new Operand();
		(yyval.operand_t)->case_idx_ = CASE4;
		(yyval.operand_t)->binary_expr_ = (yyvsp[0].binary_expr_t);
		
	}
#line 7030 "y.tab.c"
    break;

  case 270:
#line 2713 "bison.y"
                   {
		(yyval.operand_t) = new Operand();
		(yyval.operand_t)->case_idx_ = CASE5;
		(yyval.operand_t)->case_expr_ = (yyvsp[0].case_expr_t);
		
	}
#line 7041 "y.tab.c"
    break;

  case 271:
#line 2719 "bison.y"
                      {
		(yyval.operand_t) = new Operand();
		(yyval.operand_t)->case_idx_ = CASE6;
		(yyval.operand_t)->extract_expr_ = (yyvsp[0].extract_expr_t);
		
	}
#line 7052 "y.tab.c"
    break;

  case 272:
#line 2725 "bison.y"
                    {
		(yyval.operand_t) = new Operand();
		(yyval.operand_t)->case_idx_ = CASE7;
		(yyval.operand_t)->array_expr_ = (yyvsp[0].array_expr_t);
		
	}
#line 7063 "y.tab.c"
    break;

  case 273:
#line 2731 "bison.y"
                       {
		(yyval.operand_t) = new Operand();
		(yyval.operand_t)->case_idx_ = CASE8;
		(yyval.operand_t)->function_expr_ = (yyvsp[0].function_expr_t);
		
	}
#line 7074 "y.tab.c"
    break;

  case 274:
#line 2737 "bison.y"
                                      {
		(yyval.operand_t) = new Operand();
		(yyval.operand_t)->case_idx_ = CASE9;
		(yyval.operand_t)->select_no_parens_ = (yyvsp[-1].select_no_parens_t);
		
	}
#line 7085 "y.tab.c"
    break;

  case 275:
#line 2746 "bison.y"
                                            {
		(yyval.cast_expr_t) = new CastExpr();
		(yyval.cast_expr_t)->case_idx_ = CASE0;
		(yyval.cast_expr_t)->expr_ = (yyvsp[-3].expr_t);
		(yyval.cast_expr_t)->type_name_ = (yyvsp[-1].type_name_t);
		
	}
#line 7097 "y.tab.c"
    break;

  case 276:
#line 2756 "bison.y"
                     {
		(yyval.scalar_expr_t) = new ScalarExpr();
		(yyval.scalar_expr_t)->case_idx_ = CASE0;
		(yyval.scalar_expr_t)->column_name_ = (yyvsp[0].column_name_t);
		
	}
#line 7108 "y.tab.c"
    break;

  case 277:
#line 2762 "bison.y"
                 {
		(yyval.scalar_expr_t) = new ScalarExpr();
		(yyval.scalar_expr_t)->case_idx_ = CASE1;
		(yyval.scalar_expr_t)->literal_ = (yyvsp[0].literal_t);
		
	}
#line 7119 "y.tab.c"
    break;

  case 278:
#line 2771 "bison.y"
                                    {
		(yyval.unary_expr_t) = new UnaryExpr();
		(yyval.unary_expr_t)->case_idx_ = CASE0;
		(yyval.unary_expr_t)->operand_ = (yyvsp[0].operand_t);
		
	}
#line 7130 "y.tab.c"
    break;

  case 279:
#line 2777 "bison.y"
                              {
		(yyval.unary_expr_t) = new UnaryExpr();
		(yyval.unary_expr_t)->case_idx_ = CASE1;
		(yyval.unary_expr_t)->operand_ = (yyvsp[0].operand_t);
		
	}
#line 7141 "y.tab.c"
    break;

  case 280:
#line 2783 "bison.y"
                                    {
		(yyval.unary_expr_t) = new UnaryExpr();
		(yyval.unary_expr_t)->case_idx_ = CASE2;
		(yyval.unary_expr_t)->operand_ = (yyvsp[-1].operand_t);
		
	}
#line 7152 "y.tab.c"
    break;

  case 281:
#line 2789 "bison.y"
                         {
		(yyval.unary_expr_t) = new UnaryExpr();
		(yyval.unary_expr_t)->case_idx_ = CASE3;
		(yyval.unary_expr_t)->operand_ = (yyvsp[-2].operand_t);
		
	}
#line 7163 "y.tab.c"
    break;

  case 282:
#line 2795 "bison.y"
                             {
		(yyval.unary_expr_t) = new UnaryExpr();
		(yyval.unary_expr_t)->case_idx_ = CASE4;
		(yyval.unary_expr_t)->operand_ = (yyvsp[-3].operand_t);
		
	}
#line 7174 "y.tab.c"
    break;

  case 283:
#line 2801 "bison.y"
              {
		(yyval.unary_expr_t) = new UnaryExpr();
		(yyval.unary_expr_t)->case_idx_ = CASE5;
		
	}
#line 7184 "y.tab.c"
    break;

  case 284:
#line 2806 "bison.y"
                {
		(yyval.unary_expr_t) = new UnaryExpr();
		(yyval.unary_expr_t)->case_idx_ = CASE6;
		
	}
#line 7194 "y.tab.c"
    break;

  case 285:
#line 2814 "bison.y"
                   {
		(yyval.binary_expr_t) = new BinaryExpr();
		(yyval.binary_expr_t)->case_idx_ = CASE0;
		(yyval.binary_expr_t)->comp_expr_ = (yyvsp[0].comp_expr_t);
		
	}
#line 7205 "y.tab.c"
    break;

  case 286:
#line 2820 "bison.y"
                                               {
		(yyval.binary_expr_t) = new BinaryExpr();
		(yyval.binary_expr_t)->case_idx_ = CASE1;
		(yyval.binary_expr_t)->operand_1_ = (yyvsp[-2].operand_t);
		(yyval.binary_expr_t)->binary_op_ = (yyvsp[-1].binary_op_t);
		(yyval.binary_expr_t)->operand_2_ = (yyvsp[0].operand_t);
		
	}
#line 7218 "y.tab.c"
    break;

  case 287:
#line 2828 "bison.y"
                              {
		(yyval.binary_expr_t) = new BinaryExpr();
		(yyval.binary_expr_t)->case_idx_ = CASE2;
		(yyval.binary_expr_t)->operand_1_ = (yyvsp[-2].operand_t);
		(yyval.binary_expr_t)->operand_2_ = (yyvsp[0].operand_t);
		
	}
#line 7230 "y.tab.c"
    break;

  case 288:
#line 2835 "bison.y"
                                  {
		(yyval.binary_expr_t) = new BinaryExpr();
		(yyval.binary_expr_t)->case_idx_ = CASE3;
		(yyval.binary_expr_t)->operand_1_ = (yyvsp[-3].operand_t);
		(yyval.binary_expr_t)->operand_2_ = (yyvsp[0].operand_t);
		
	}
#line 7242 "y.tab.c"
    break;

  case 289:
#line 2845 "bison.y"
                       {
		(yyval.logic_expr_t) = new LogicExpr();
		(yyval.logic_expr_t)->case_idx_ = CASE0;
		(yyval.logic_expr_t)->expr_1_ = (yyvsp[-2].expr_t);
		(yyval.logic_expr_t)->expr_2_ = (yyvsp[0].expr_t);
		
	}
#line 7254 "y.tab.c"
    break;

  case 290:
#line 2852 "bison.y"
                      {
		(yyval.logic_expr_t) = new LogicExpr();
		(yyval.logic_expr_t)->case_idx_ = CASE1;
		(yyval.logic_expr_t)->expr_1_ = (yyvsp[-2].expr_t);
		(yyval.logic_expr_t)->expr_2_ = (yyvsp[0].expr_t);
		
	}
#line 7266 "y.tab.c"
    break;

  case 291:
#line 2862 "bison.y"
                                                         {
		(yyval.in_expr_t) = new InExpr();
		(yyval.in_expr_t)->case_idx_ = CASE0;
		(yyval.in_expr_t)->operand_ = (yyvsp[-5].operand_t);
		(yyval.in_expr_t)->opt_not_ = (yyvsp[-4].opt_not_t);
		(yyval.in_expr_t)->select_no_parens_ = (yyvsp[-1].select_no_parens_t);
		
	}
#line 7279 "y.tab.c"
    break;

  case 292:
#line 2870 "bison.y"
                                                  {
		(yyval.in_expr_t) = new InExpr();
		(yyval.in_expr_t)->case_idx_ = CASE1;
		(yyval.in_expr_t)->operand_ = (yyvsp[-5].operand_t);
		(yyval.in_expr_t)->opt_not_ = (yyvsp[-4].opt_not_t);
		(yyval.in_expr_t)->expr_list_ = (yyvsp[-1].expr_list_t);
		
	}
#line 7292 "y.tab.c"
    break;

  case 293:
#line 2878 "bison.y"
                                       {
		(yyval.in_expr_t) = new InExpr();
		(yyval.in_expr_t)->case_idx_ = CASE2;
		(yyval.in_expr_t)->operand_ = (yyvsp[-3].operand_t);
		(yyval.in_expr_t)->opt_not_ = (yyvsp[-2].opt_not_t);
		(yyval.in_expr_t)->table_name_ = (yyvsp[0].table_name_t);
		
	}
#line 7305 "y.tab.c"
    break;

  case 294:
#line 2889 "bison.y"
                                 {
		(yyval.case_expr_t) = new CaseExpr();
		(yyval.case_expr_t)->case_idx_ = CASE0;
		(yyval.case_expr_t)->expr_1_ = (yyvsp[-2].expr_t);
		(yyval.case_expr_t)->case_list_ = (yyvsp[-1].case_list_t);
		
	}
#line 7317 "y.tab.c"
    break;

  case 295:
#line 2896 "bison.y"
                            {
		(yyval.case_expr_t) = new CaseExpr();
		(yyval.case_expr_t)->case_idx_ = CASE1;
		(yyval.case_expr_t)->case_list_ = (yyvsp[-1].case_list_t);
		
	}
#line 7328 "y.tab.c"
    break;

  case 296:
#line 2902 "bison.y"
                                           {
		(yyval.case_expr_t) = new CaseExpr();
		(yyval.case_expr_t)->case_idx_ = CASE2;
		(yyval.case_expr_t)->expr_1_ = (yyvsp[-4].expr_t);
		(yyval.case_expr_t)->case_list_ = (yyvsp[-3].case_list_t);
		(yyval.case_expr_t)->expr_2_ = (yyvsp[-1].expr_t);
		
	}
#line 7341 "y.tab.c"
    break;

  case 297:
#line 2910 "bison.y"
                                      {
		(yyval.case_expr_t) = new CaseExpr();
		(yyval.case_expr_t)->case_idx_ = CASE3;
		(yyval.case_expr_t)->case_list_ = (yyvsp[-3].case_list_t);
		(yyval.case_expr_t)->expr_1_ = (yyvsp[-1].expr_t);
		
	}
#line 7353 "y.tab.c"
    break;

  case 298:
#line 2920 "bison.y"
                                                          {
		(yyval.between_expr_t) = new BetweenExpr();
		(yyval.between_expr_t)->case_idx_ = CASE0;
		(yyval.between_expr_t)->operand_1_ = (yyvsp[-4].operand_t);
		(yyval.between_expr_t)->operand_2_ = (yyvsp[-2].operand_t);
		(yyval.between_expr_t)->operand_3_ = (yyvsp[0].operand_t);
		
	}
#line 7366 "y.tab.c"
    break;

  case 299:
#line 2928 "bison.y"
                                                          {
		(yyval.between_expr_t) = new BetweenExpr();
		(yyval.between_expr_t)->case_idx_ = CASE1;
		(yyval.between_expr_t)->operand_1_ = (yyvsp[-5].operand_t);
		(yyval.between_expr_t)->operand_2_ = (yyvsp[-2].operand_t);
		(yyval.between_expr_t)->operand_3_ = (yyvsp[0].operand_t);
		
	}
#line 7379 "y.tab.c"
    break;

  case 300:
#line 2939 "bison.y"
                                                     {
		(yyval.exists_expr_t) = new ExistsExpr();
		(yyval.exists_expr_t)->case_idx_ = CASE0;
		(yyval.exists_expr_t)->opt_not_ = (yyvsp[-4].opt_not_t);
		(yyval.exists_expr_t)->select_no_parens_ = (yyvsp[-1].select_no_parens_t);
		
	}
#line 7391 "y.tab.c"
    break;

  case 301:
#line 2949 "bison.y"
                                                                     {
		(yyval.function_expr_t) = new FunctionExpr();
		(yyval.function_expr_t)->case_idx_ = CASE0;
		(yyval.function_expr_t)->function_name_ = (yyvsp[-4].function_name_t);
		(yyval.function_expr_t)->opt_filter_clause_ = (yyvsp[-1].opt_filter_clause_t);
		(yyval.function_expr_t)->opt_over_clause_ = (yyvsp[0].opt_over_clause_t);
		
	}
#line 7404 "y.tab.c"
    break;

  case 302:
#line 2957 "bison.y"
                                                                                            {
		(yyval.function_expr_t) = new FunctionExpr();
		(yyval.function_expr_t)->case_idx_ = CASE1;
		(yyval.function_expr_t)->function_name_ = (yyvsp[-6].function_name_t);
		(yyval.function_expr_t)->opt_distinct_ = (yyvsp[-4].opt_distinct_t);
		(yyval.function_expr_t)->expr_list_ = (yyvsp[-3].expr_list_t);
		(yyval.function_expr_t)->opt_filter_clause_ = (yyvsp[-1].opt_filter_clause_t);
		(yyval.function_expr_t)->opt_over_clause_ = (yyvsp[0].opt_over_clause_t);
		
	}
#line 7419 "y.tab.c"
    break;

  case 303:
#line 2970 "bison.y"
                  {
		(yyval.opt_distinct_t) = new OptDistinct();
		(yyval.opt_distinct_t)->case_idx_ = CASE0;
		
	}
#line 7429 "y.tab.c"
    break;

  case 304:
#line 2975 "bison.y"
          {
		(yyval.opt_distinct_t) = new OptDistinct();
		(yyval.opt_distinct_t)->case_idx_ = CASE1;
		
	}
#line 7439 "y.tab.c"
    break;

  case 305:
#line 2983 "bison.y"
                                       {
		(yyval.opt_filter_clause_t) = new OptFilterClause();
		(yyval.opt_filter_clause_t)->case_idx_ = CASE0;
		(yyval.opt_filter_clause_t)->expr_ = (yyvsp[-1].expr_t);
		
	}
#line 7450 "y.tab.c"
    break;

  case 306:
#line 2989 "bison.y"
          {
		(yyval.opt_filter_clause_t) = new OptFilterClause();
		(yyval.opt_filter_clause_t)->case_idx_ = CASE1;
		
	}
#line 7460 "y.tab.c"
    break;

  case 307:
#line 2997 "bison.y"
                                 {
		(yyval.opt_over_clause_t) = new OptOverClause();
		(yyval.opt_over_clause_t)->case_idx_ = CASE0;
		(yyval.opt_over_clause_t)->window_ = (yyvsp[-1].window_t);
		
	}
#line 7471 "y.tab.c"
    break;

  case 308:
#line 3003 "bison.y"
                          {
		(yyval.opt_over_clause_t) = new OptOverClause();
		(yyval.opt_over_clause_t)->case_idx_ = CASE1;
		(yyval.opt_over_clause_t)->window_name_ = (yyvsp[0].window_name_t);
		
	}
#line 7482 "y.tab.c"
    break;

  case 309:
#line 3009 "bison.y"
          {
		(yyval.opt_over_clause_t) = new OptOverClause();
		(yyval.opt_over_clause_t)->case_idx_ = CASE2;
		
	}
#line 7492 "y.tab.c"
    break;

  case 310:
#line 3017 "bison.y"
                     {
		(yyval.case_list_t) = new CaseList();
		(yyval.case_list_t)->case_idx_ = CASE0;
		(yyval.case_list_t)->case_clause_ = (yyvsp[0].case_clause_t);
		
	}
#line 7503 "y.tab.c"
    break;

  case 311:
#line 3023 "bison.y"
                               {
		(yyval.case_list_t) = new CaseList();
		(yyval.case_list_t)->case_idx_ = CASE1;
		(yyval.case_list_t)->case_clause_ = (yyvsp[-1].case_clause_t);
		(yyval.case_list_t)->case_list_ = (yyvsp[0].case_list_t);
		
	}
#line 7515 "y.tab.c"
    break;

  case 312:
#line 3033 "bison.y"
                             {
		(yyval.case_clause_t) = new CaseClause();
		(yyval.case_clause_t)->case_idx_ = CASE0;
		(yyval.case_clause_t)->expr_1_ = (yyvsp[-2].expr_t);
		(yyval.case_clause_t)->expr_2_ = (yyvsp[0].expr_t);
		
	}
#line 7527 "y.tab.c"
    break;

  case 313:
#line 3043 "bison.y"
                                  {
		(yyval.comp_expr_t) = new CompExpr();
		(yyval.comp_expr_t)->case_idx_ = CASE0;
		(yyval.comp_expr_t)->operand_1_ = (yyvsp[-2].operand_t);
		(yyval.comp_expr_t)->operand_2_ = (yyvsp[0].operand_t);
		
	}
#line 7539 "y.tab.c"
    break;

  case 314:
#line 3050 "bison.y"
                                     {
		(yyval.comp_expr_t) = new CompExpr();
		(yyval.comp_expr_t)->case_idx_ = CASE1;
		(yyval.comp_expr_t)->operand_1_ = (yyvsp[-2].operand_t);
		(yyval.comp_expr_t)->operand_2_ = (yyvsp[0].operand_t);
		
	}
#line 7551 "y.tab.c"
    break;

  case 315:
#line 3057 "bison.y"
                                        {
		(yyval.comp_expr_t) = new CompExpr();
		(yyval.comp_expr_t)->case_idx_ = CASE2;
		(yyval.comp_expr_t)->operand_1_ = (yyvsp[-2].operand_t);
		(yyval.comp_expr_t)->operand_2_ = (yyvsp[0].operand_t);
		
	}
#line 7563 "y.tab.c"
    break;

  case 316:
#line 3064 "bison.y"
                                     {
		(yyval.comp_expr_t) = new CompExpr();
		(yyval.comp_expr_t)->case_idx_ = CASE3;
		(yyval.comp_expr_t)->operand_1_ = (yyvsp[-2].operand_t);
		(yyval.comp_expr_t)->operand_2_ = (yyvsp[0].operand_t);
		
	}
#line 7575 "y.tab.c"
    break;

  case 317:
#line 3071 "bison.y"
                                   {
		(yyval.comp_expr_t) = new CompExpr();
		(yyval.comp_expr_t)->case_idx_ = CASE4;
		(yyval.comp_expr_t)->operand_1_ = (yyvsp[-2].operand_t);
		(yyval.comp_expr_t)->operand_2_ = (yyvsp[0].operand_t);
		
	}
#line 7587 "y.tab.c"
    break;

  case 318:
#line 3078 "bison.y"
                                      {
		(yyval.comp_expr_t) = new CompExpr();
		(yyval.comp_expr_t)->case_idx_ = CASE5;
		(yyval.comp_expr_t)->operand_1_ = (yyvsp[-2].operand_t);
		(yyval.comp_expr_t)->operand_2_ = (yyvsp[0].operand_t);
		
	}
#line 7599 "y.tab.c"
    break;

  case 319:
#line 3088 "bison.y"
                                                      {
		(yyval.extract_expr_t) = new ExtractExpr();
		(yyval.extract_expr_t)->case_idx_ = CASE0;
		(yyval.extract_expr_t)->datetime_field_ = (yyvsp[-3].datetime_field_t);
		(yyval.extract_expr_t)->expr_ = (yyvsp[-1].expr_t);
		
	}
#line 7611 "y.tab.c"
    break;

  case 320:
#line 3098 "bison.y"
                {
		(yyval.datetime_field_t) = new DatetimeField();
		(yyval.datetime_field_t)->case_idx_ = CASE0;
		
	}
#line 7621 "y.tab.c"
    break;

  case 321:
#line 3103 "bison.y"
                {
		(yyval.datetime_field_t) = new DatetimeField();
		(yyval.datetime_field_t)->case_idx_ = CASE1;
		
	}
#line 7631 "y.tab.c"
    break;

  case 322:
#line 3108 "bison.y"
              {
		(yyval.datetime_field_t) = new DatetimeField();
		(yyval.datetime_field_t)->case_idx_ = CASE2;
		
	}
#line 7641 "y.tab.c"
    break;

  case 323:
#line 3113 "bison.y"
             {
		(yyval.datetime_field_t) = new DatetimeField();
		(yyval.datetime_field_t)->case_idx_ = CASE3;
		
	}
#line 7651 "y.tab.c"
    break;

  case 324:
#line 3118 "bison.y"
               {
		(yyval.datetime_field_t) = new DatetimeField();
		(yyval.datetime_field_t)->case_idx_ = CASE4;
		
	}
#line 7661 "y.tab.c"
    break;

  case 325:
#line 3123 "bison.y"
              {
		(yyval.datetime_field_t) = new DatetimeField();
		(yyval.datetime_field_t)->case_idx_ = CASE5;
		
	}
#line 7671 "y.tab.c"
    break;

  case 326:
#line 3131 "bison.y"
                                                 {
		(yyval.array_expr_t) = new ArrayExpr();
		(yyval.array_expr_t)->case_idx_ = CASE0;
		(yyval.array_expr_t)->expr_list_ = (yyvsp[-1].expr_list_t);
		
	}
#line 7682 "y.tab.c"
    break;

  case 327:
#line 3140 "bison.y"
                                                     {
		(yyval.array_index_t) = new ArrayIndex();
		(yyval.array_index_t)->case_idx_ = CASE0;
		(yyval.array_index_t)->operand_ = (yyvsp[-3].operand_t);
		(yyval.array_index_t)->int_literal_ = (yyvsp[-1].int_literal_t);
		
	}
#line 7694 "y.tab.c"
    break;

  case 328:
#line 3150 "bison.y"
                        {
		(yyval.literal_t) = new Literal();
		(yyval.literal_t)->case_idx_ = CASE0;
		(yyval.literal_t)->string_literal_ = (yyvsp[0].string_literal_t);
		
	}
#line 7705 "y.tab.c"
    break;

  case 329:
#line 3156 "bison.y"
                      {
		(yyval.literal_t) = new Literal();
		(yyval.literal_t)->case_idx_ = CASE1;
		(yyval.literal_t)->bool_literal_ = (yyvsp[0].bool_literal_t);
		
	}
#line 7716 "y.tab.c"
    break;

  case 330:
#line 3162 "bison.y"
                     {
		(yyval.literal_t) = new Literal();
		(yyval.literal_t)->case_idx_ = CASE2;
		(yyval.literal_t)->num_literal_ = (yyvsp[0].num_literal_t);
		
	}
#line 7727 "y.tab.c"
    break;

  case 331:
#line 3171 "bison.y"
                       {
		(yyval.string_literal_t) = new StringLiteral();
		(yyval.string_literal_t)->string_val_ = (yyvsp[0].sval);
		free((yyvsp[0].sval));
		
	}
#line 7738 "y.tab.c"
    break;

  case 332:
#line 3180 "bison.y"
              {
		(yyval.bool_literal_t) = new BoolLiteral();
		(yyval.bool_literal_t)->case_idx_ = CASE0;
		
	}
#line 7748 "y.tab.c"
    break;

  case 333:
#line 3185 "bison.y"
               {
		(yyval.bool_literal_t) = new BoolLiteral();
		(yyval.bool_literal_t)->case_idx_ = CASE1;
		
	}
#line 7758 "y.tab.c"
    break;

  case 334:
#line 3193 "bison.y"
                     {
		(yyval.num_literal_t) = new NumLiteral();
		(yyval.num_literal_t)->case_idx_ = CASE0;
		(yyval.num_literal_t)->int_literal_ = (yyvsp[0].int_literal_t);
		
	}
#line 7769 "y.tab.c"
    break;

  case 335:
#line 3199 "bison.y"
                       {
		(yyval.num_literal_t) = new NumLiteral();
		(yyval.num_literal_t)->case_idx_ = CASE1;
		(yyval.num_literal_t)->float_literal_ = (yyvsp[0].float_literal_t);
		
	}
#line 7780 "y.tab.c"
    break;

  case 336:
#line 3208 "bison.y"
                    {
		(yyval.int_literal_t) = new IntLiteral();
		(yyval.int_literal_t)->int_val_ = (yyvsp[0].ival);
		
	}
#line 7790 "y.tab.c"
    break;

  case 337:
#line 3216 "bison.y"
                      {
		(yyval.float_literal_t) = new FloatLiteral();
		(yyval.float_literal_t)->float_val_ = (yyvsp[0].fval);
		
	}
#line 7800 "y.tab.c"
    break;

  case 338:
#line 3224 "bison.y"
                {
		(yyval.opt_column_t) = new OptColumn();
		(yyval.opt_column_t)->case_idx_ = CASE0;
		
	}
#line 7810 "y.tab.c"
    break;

  case 339:
#line 3229 "bison.y"
          {
		(yyval.opt_column_t) = new OptColumn();
		(yyval.opt_column_t)->case_idx_ = CASE1;
		
	}
#line 7820 "y.tab.c"
    break;

  case 340:
#line 3237 "bison.y"
                   {
		(yyval.trigger_body_t) = new TriggerBody();
		(yyval.trigger_body_t)->case_idx_ = CASE0;
		(yyval.trigger_body_t)->drop_stmt_ = (yyvsp[0].drop_stmt_t);
		
	}
#line 7831 "y.tab.c"
    break;

  case 341:
#line 3243 "bison.y"
                     {
		(yyval.trigger_body_t) = new TriggerBody();
		(yyval.trigger_body_t)->case_idx_ = CASE1;
		(yyval.trigger_body_t)->update_stmt_ = (yyvsp[0].update_stmt_t);
		
	}
#line 7842 "y.tab.c"
    break;

  case 342:
#line 3249 "bison.y"
                     {
		(yyval.trigger_body_t) = new TriggerBody();
		(yyval.trigger_body_t)->case_idx_ = CASE2;
		(yyval.trigger_body_t)->insert_stmt_ = (yyvsp[0].insert_stmt_t);
		
	}
#line 7853 "y.tab.c"
    break;

  case 343:
#line 3255 "bison.y"
                    {
		(yyval.trigger_body_t) = new TriggerBody();
		(yyval.trigger_body_t)->case_idx_ = CASE3;
		(yyval.trigger_body_t)->alter_stmt_ = (yyvsp[0].alter_stmt_t);
		
	}
#line 7864 "y.tab.c"
    break;

  case 344:
#line 3264 "bison.y"
                       {
		(yyval.opt_if_not_exist_t) = new OptIfNotExist();
		(yyval.opt_if_not_exist_t)->case_idx_ = CASE0;
		
	}
#line 7874 "y.tab.c"
    break;

  case 345:
#line 3269 "bison.y"
          {
		(yyval.opt_if_not_exist_t) = new OptIfNotExist();
		(yyval.opt_if_not_exist_t)->case_idx_ = CASE1;
		
	}
#line 7884 "y.tab.c"
    break;

  case 346:
#line 3277 "bison.y"
                   {
		(yyval.opt_if_exist_t) = new OptIfExist();
		(yyval.opt_if_exist_t)->case_idx_ = CASE0;
		
	}
#line 7894 "y.tab.c"
    break;

  case 347:
#line 3282 "bison.y"
          {
		(yyval.opt_if_exist_t) = new OptIfExist();
		(yyval.opt_if_exist_t)->case_idx_ = CASE1;
		
	}
#line 7904 "y.tab.c"
    break;

  case 348:
#line 3290 "bison.y"
                    {
		(yyval.identifier_t) = new Identifier();
		(yyval.identifier_t)->string_val_ = (yyvsp[0].sval);
		free((yyvsp[0].sval));
		
	}
#line 7915 "y.tab.c"
    break;

  case 349:
#line 3299 "bison.y"
                       {
		(yyval.as_alias_t) = new AsAlias();
		(yyval.as_alias_t)->case_idx_ = CASE0;
		(yyval.as_alias_t)->identifier_ = (yyvsp[0].identifier_t);
		if((yyval.as_alias_t)){
			auto tmp1 = (yyval.as_alias_t)->identifier_; 
			if(tmp1){
				tmp1->data_type_ = kDataAliasName; 
				tmp1->scope_ = 1; 
				tmp1->data_flag_ =(DATAFLAG)1; 
			}
		}


	}
#line 7935 "y.tab.c"
    break;

  case 350:
#line 3317 "bison.y"
                    {
		(yyval.table_name_t) = new TableName();
		(yyval.table_name_t)->case_idx_ = CASE0;
		(yyval.table_name_t)->identifier_ = (yyvsp[0].identifier_t);
		if((yyval.table_name_t)){
			auto tmp1 = (yyval.table_name_t)->identifier_; 
			if(tmp1){
				tmp1->data_type_ = kDataTableName; 
				tmp1->scope_ = 1; 
				tmp1->data_flag_ =(DATAFLAG)8; 
			}
		}


	}
#line 7955 "y.tab.c"
    break;

  case 351:
#line 3335 "bison.y"
                    {
		(yyval.column_name_t) = new ColumnName();
		(yyval.column_name_t)->case_idx_ = CASE0;
		(yyval.column_name_t)->identifier_ = (yyvsp[0].identifier_t);
		if((yyval.column_name_t)){
			auto tmp1 = (yyval.column_name_t)->identifier_; 
			if(tmp1){
				tmp1->data_type_ = kDataColumnName; 
				tmp1->scope_ = 2; 
				tmp1->data_flag_ =(DATAFLAG)8; 
			}
		}


	}
#line 7975 "y.tab.c"
    break;

  case 352:
#line 3353 "bison.y"
                {
		(yyval.opt_index_keyword_t) = new OptIndexKeyword();
		(yyval.opt_index_keyword_t)->case_idx_ = CASE0;
		
	}
#line 7985 "y.tab.c"
    break;

  case 353:
#line 3358 "bison.y"
                  {
		(yyval.opt_index_keyword_t) = new OptIndexKeyword();
		(yyval.opt_index_keyword_t)->case_idx_ = CASE1;
		
	}
#line 7995 "y.tab.c"
    break;

  case 354:
#line 3363 "bison.y"
                 {
		(yyval.opt_index_keyword_t) = new OptIndexKeyword();
		(yyval.opt_index_keyword_t)->case_idx_ = CASE2;
		
	}
#line 8005 "y.tab.c"
    break;

  case 355:
#line 3368 "bison.y"
          {
		(yyval.opt_index_keyword_t) = new OptIndexKeyword();
		(yyval.opt_index_keyword_t)->case_idx_ = CASE3;
		
	}
#line 8015 "y.tab.c"
    break;

  case 356:
#line 3376 "bison.y"
                    {
		(yyval.view_name_t) = new ViewName();
		(yyval.view_name_t)->case_idx_ = CASE0;
		(yyval.view_name_t)->identifier_ = (yyvsp[0].identifier_t);
		
	}
#line 8026 "y.tab.c"
    break;

  case 357:
#line 3385 "bison.y"
                    {
		(yyval.function_name_t) = new FunctionName();
		(yyval.function_name_t)->case_idx_ = CASE0;
		(yyval.function_name_t)->identifier_ = (yyvsp[0].identifier_t);
		if((yyval.function_name_t)){
			auto tmp1 = (yyval.function_name_t)->identifier_; 
			if(tmp1){
				tmp1->data_type_ = kDataFunctionName; 
				tmp1->scope_ = 1; 
				tmp1->data_flag_ =(DATAFLAG)4; 
			}
		}


	}
#line 8046 "y.tab.c"
    break;

  case 358:
#line 3403 "bison.y"
                {
		(yyval.binary_op_t) = new BinaryOp();
		(yyval.binary_op_t)->case_idx_ = CASE0;
		
	}
#line 8056 "y.tab.c"
    break;

  case 359:
#line 3408 "bison.y"
                {
		(yyval.binary_op_t) = new BinaryOp();
		(yyval.binary_op_t)->case_idx_ = CASE1;
		
	}
#line 8066 "y.tab.c"
    break;

  case 360:
#line 3413 "bison.y"
                   {
		(yyval.binary_op_t) = new BinaryOp();
		(yyval.binary_op_t)->case_idx_ = CASE2;
		
	}
#line 8076 "y.tab.c"
    break;

  case 361:
#line 3418 "bison.y"
                {
		(yyval.binary_op_t) = new BinaryOp();
		(yyval.binary_op_t)->case_idx_ = CASE3;
		
	}
#line 8086 "y.tab.c"
    break;

  case 362:
#line 3423 "bison.y"
                {
		(yyval.binary_op_t) = new BinaryOp();
		(yyval.binary_op_t)->case_idx_ = CASE4;
		
	}
#line 8096 "y.tab.c"
    break;

  case 363:
#line 3428 "bison.y"
                {
		(yyval.binary_op_t) = new BinaryOp();
		(yyval.binary_op_t)->case_idx_ = CASE5;
		
	}
#line 8106 "y.tab.c"
    break;

  case 364:
#line 3436 "bison.y"
             {
		(yyval.opt_not_t) = new OptNot();
		(yyval.opt_not_t)->case_idx_ = CASE0;
		
	}
#line 8116 "y.tab.c"
    break;

  case 365:
#line 3441 "bison.y"
          {
		(yyval.opt_not_t) = new OptNot();
		(yyval.opt_not_t)->case_idx_ = CASE1;
		
	}
#line 8126 "y.tab.c"
    break;

  case 366:
#line 3449 "bison.y"
                    {
		(yyval.name_t) = new Name();
		(yyval.name_t)->case_idx_ = CASE0;
		(yyval.name_t)->identifier_ = (yyvsp[0].identifier_t);
		
	}
#line 8137 "y.tab.c"
    break;

  case 367:
#line 3458 "bison.y"
                      {
		(yyval.type_name_t) = new TypeName();
		(yyval.type_name_t)->case_idx_ = CASE0;
		(yyval.type_name_t)->numeric_type_ = (yyvsp[0].numeric_type_t);
		
	}
#line 8148 "y.tab.c"
    break;

  case 368:
#line 3464 "bison.y"
                        {
		(yyval.type_name_t) = new TypeName();
		(yyval.type_name_t)->case_idx_ = CASE1;
		(yyval.type_name_t)->character_type_ = (yyvsp[0].character_type_t);
		
	}
#line 8159 "y.tab.c"
    break;

  case 369:
#line 3473 "bison.y"
                               {
		(yyval.character_type_t) = new CharacterType();
		(yyval.character_type_t)->case_idx_ = CASE0;
		(yyval.character_type_t)->character_with_length_ = (yyvsp[0].character_with_length_t);
		
	}
#line 8170 "y.tab.c"
    break;

  case 370:
#line 3479 "bison.y"
                                  {
		(yyval.character_type_t) = new CharacterType();
		(yyval.character_type_t)->case_idx_ = CASE1;
		(yyval.character_type_t)->character_without_length_ = (yyvsp[0].character_without_length_t);
		
	}
#line 8181 "y.tab.c"
    break;

  case 371:
#line 3488 "bison.y"
                                                     {
		(yyval.character_with_length_t) = new CharacterWithLength();
		(yyval.character_with_length_t)->case_idx_ = CASE0;
		(yyval.character_with_length_t)->character_conflicta_ = (yyvsp[-3].character_conflicta_t);
		(yyval.character_with_length_t)->int_literal_ = (yyvsp[-1].int_literal_t);
		
	}
#line 8193 "y.tab.c"
    break;

  case 372:
#line 3498 "bison.y"
                             {
		(yyval.character_without_length_t) = new CharacterWithoutLength();
		(yyval.character_without_length_t)->case_idx_ = CASE0;
		(yyval.character_without_length_t)->character_conflicta_ = (yyvsp[0].character_conflicta_t);
		
	}
#line 8204 "y.tab.c"
    break;

  case 373:
#line 3504 "bison.y"
             {
		(yyval.character_without_length_t) = new CharacterWithoutLength();
		(yyval.character_without_length_t)->case_idx_ = CASE1;
		
	}
#line 8214 "y.tab.c"
    break;

  case 374:
#line 3509 "bison.y"
              {
		(yyval.character_without_length_t) = new CharacterWithoutLength();
		(yyval.character_without_length_t)->case_idx_ = CASE2;
		
	}
#line 8224 "y.tab.c"
    break;

  case 375:
#line 3514 "bison.y"
                {
		(yyval.character_without_length_t) = new CharacterWithoutLength();
		(yyval.character_without_length_t)->case_idx_ = CASE3;
		
	}
#line 8234 "y.tab.c"
    break;

  case 376:
#line 3522 "bison.y"
                   {
		(yyval.character_conflicta_t) = new CharacterConflicta();
		(yyval.character_conflicta_t)->case_idx_ = CASE0;
		
	}
#line 8244 "y.tab.c"
    break;

  case 377:
#line 3527 "bison.y"
              {
		(yyval.character_conflicta_t) = new CharacterConflicta();
		(yyval.character_conflicta_t)->case_idx_ = CASE1;
		
	}
#line 8254 "y.tab.c"
    break;

  case 378:
#line 3532 "bison.y"
                 {
		(yyval.character_conflicta_t) = new CharacterConflicta();
		(yyval.character_conflicta_t)->case_idx_ = CASE2;
		
	}
#line 8264 "y.tab.c"
    break;

  case 379:
#line 3537 "bison.y"
              {
		(yyval.character_conflicta_t) = new CharacterConflicta();
		(yyval.character_conflicta_t)->case_idx_ = CASE3;
		
	}
#line 8274 "y.tab.c"
    break;

  case 380:
#line 3542 "bison.y"
                  {
		(yyval.character_conflicta_t) = new CharacterConflicta();
		(yyval.character_conflicta_t)->case_idx_ = CASE4;
		
	}
#line 8284 "y.tab.c"
    break;

  case 381:
#line 3547 "bison.y"
                    {
		(yyval.character_conflicta_t) = new CharacterConflicta();
		(yyval.character_conflicta_t)->case_idx_ = CASE5;
		
	}
#line 8294 "y.tab.c"
    break;

  case 382:
#line 3552 "bison.y"
                  {
		(yyval.character_conflicta_t) = new CharacterConflicta();
		(yyval.character_conflicta_t)->case_idx_ = CASE6;
		
	}
#line 8304 "y.tab.c"
    break;

  case 383:
#line 3557 "bison.y"
                            {
		(yyval.character_conflicta_t) = new CharacterConflicta();
		(yyval.character_conflicta_t)->case_idx_ = CASE7;
		
	}
#line 8314 "y.tab.c"
    break;

  case 384:
#line 3562 "bison.y"
                       {
		(yyval.character_conflicta_t) = new CharacterConflicta();
		(yyval.character_conflicta_t)->case_idx_ = CASE8;
		
	}
#line 8324 "y.tab.c"
    break;

  case 385:
#line 3567 "bison.y"
               {
		(yyval.character_conflicta_t) = new CharacterConflicta();
		(yyval.character_conflicta_t)->case_idx_ = CASE9;
		
	}
#line 8334 "y.tab.c"
    break;

  case 386:
#line 3575 "bison.y"
             {
		(yyval.numeric_type_t) = new NumericType();
		(yyval.numeric_type_t)->case_idx_ = CASE0;
		
	}
#line 8344 "y.tab.c"
    break;

  case 387:
#line 3580 "bison.y"
                 {
		(yyval.numeric_type_t) = new NumericType();
		(yyval.numeric_type_t)->case_idx_ = CASE1;
		
	}
#line 8354 "y.tab.c"
    break;

  case 388:
#line 3585 "bison.y"
                  {
		(yyval.numeric_type_t) = new NumericType();
		(yyval.numeric_type_t)->case_idx_ = CASE2;
		
	}
#line 8364 "y.tab.c"
    break;

  case 389:
#line 3590 "bison.y"
                {
		(yyval.numeric_type_t) = new NumericType();
		(yyval.numeric_type_t)->case_idx_ = CASE3;
		
	}
#line 8374 "y.tab.c"
    break;

  case 390:
#line 3595 "bison.y"
              {
		(yyval.numeric_type_t) = new NumericType();
		(yyval.numeric_type_t)->case_idx_ = CASE4;
		
	}
#line 8384 "y.tab.c"
    break;

  case 391:
#line 3600 "bison.y"
               {
		(yyval.numeric_type_t) = new NumericType();
		(yyval.numeric_type_t)->case_idx_ = CASE5;
		
	}
#line 8394 "y.tab.c"
    break;

  case 392:
#line 3605 "bison.y"
               {
		(yyval.numeric_type_t) = new NumericType();
		(yyval.numeric_type_t)->case_idx_ = CASE6;
		
	}
#line 8404 "y.tab.c"
    break;

  case 393:
#line 3610 "bison.y"
                {
		(yyval.numeric_type_t) = new NumericType();
		(yyval.numeric_type_t)->case_idx_ = CASE7;
		
	}
#line 8414 "y.tab.c"
    break;

  case 394:
#line 3615 "bison.y"
                          {
		(yyval.numeric_type_t) = new NumericType();
		(yyval.numeric_type_t)->case_idx_ = CASE8;
		
	}
#line 8424 "y.tab.c"
    break;

  case 395:
#line 3620 "bison.y"
                 {
		(yyval.numeric_type_t) = new NumericType();
		(yyval.numeric_type_t)->case_idx_ = CASE9;
		
	}
#line 8434 "y.tab.c"
    break;

  case 396:
#line 3625 "bison.y"
             {
		(yyval.numeric_type_t) = new NumericType();
		(yyval.numeric_type_t)->case_idx_ = CASE10;
		
	}
#line 8444 "y.tab.c"
    break;

  case 397:
#line 3630 "bison.y"
                 {
		(yyval.numeric_type_t) = new NumericType();
		(yyval.numeric_type_t)->case_idx_ = CASE11;
		
	}
#line 8454 "y.tab.c"
    break;

  case 398:
#line 3635 "bison.y"
                 {
		(yyval.numeric_type_t) = new NumericType();
		(yyval.numeric_type_t)->case_idx_ = CASE12;
		
	}
#line 8464 "y.tab.c"
    break;

  case 399:
#line 3640 "bison.y"
              {
		(yyval.numeric_type_t) = new NumericType();
		(yyval.numeric_type_t)->case_idx_ = CASE13;
		
  }
#line 8474 "y.tab.c"
    break;

  case 400:
#line 3648 "bison.y"
                               {
		(yyval.opt_table_constraint_list_t) = new OptTableConstraintList();
		(yyval.opt_table_constraint_list_t)->case_idx_ = CASE0;
		(yyval.opt_table_constraint_list_t)->table_constraint_list_ = (yyvsp[0].table_constraint_list_t);
		
	}
#line 8485 "y.tab.c"
    break;

  case 401:
#line 3654 "bison.y"
          {
		(yyval.opt_table_constraint_list_t) = new OptTableConstraintList();
		(yyval.opt_table_constraint_list_t)->case_idx_ = CASE1;
		
	}
#line 8495 "y.tab.c"
    break;

  case 402:
#line 3662 "bison.y"
                          {
		(yyval.table_constraint_list_t) = new TableConstraintList();
		(yyval.table_constraint_list_t)->case_idx_ = CASE0;
		(yyval.table_constraint_list_t)->table_constraint_ = (yyvsp[0].table_constraint_t);
		
	}
#line 8506 "y.tab.c"
    break;

  case 403:
#line 3668 "bison.y"
                                                         {
		(yyval.table_constraint_list_t) = new TableConstraintList();
		(yyval.table_constraint_list_t)->case_idx_ = CASE1;
		(yyval.table_constraint_list_t)->table_constraint_ = (yyvsp[-2].table_constraint_t);
		(yyval.table_constraint_list_t)->table_constraint_list_ = (yyvsp[0].table_constraint_list_t);
		
	}
#line 8518 "y.tab.c"
    break;

  case 404:
#line 3678 "bison.y"
                                                                     {
		(yyval.table_constraint_t) = new TableConstraint();
		(yyval.table_constraint_t)->case_idx_ = CASE0;
		(yyval.table_constraint_t)->constraint_name_ = (yyvsp[-5].constraint_name_t);
		(yyval.table_constraint_t)->indexed_column_list_ = (yyvsp[-1].indexed_column_list_t);
		
	}
#line 8530 "y.tab.c"
    break;

  case 405:
#line 3685 "bison.y"
                                                                {
		(yyval.table_constraint_t) = new TableConstraint();
		(yyval.table_constraint_t)->case_idx_ = CASE1;
		(yyval.table_constraint_t)->constraint_name_ = (yyvsp[-4].constraint_name_t);
		(yyval.table_constraint_t)->indexed_column_list_ = (yyvsp[-1].indexed_column_list_t);
		
	}
#line 8542 "y.tab.c"
    break;

  case 406:
#line 3692 "bison.y"
                                                             {
		(yyval.table_constraint_t) = new TableConstraint();
		(yyval.table_constraint_t)->case_idx_ = CASE2;
		(yyval.table_constraint_t)->constraint_name_ = (yyvsp[-5].constraint_name_t);
		(yyval.table_constraint_t)->expr_ = (yyvsp[-2].expr_t);
		(yyval.table_constraint_t)->opt_enforced_ = (yyvsp[0].opt_enforced_t);
		
	}
#line 8555 "y.tab.c"
    break;

  case 407:
#line 3700 "bison.y"
                                                                                   {
		(yyval.table_constraint_t) = new TableConstraint();
		(yyval.table_constraint_t)->case_idx_ = CASE3;
		(yyval.table_constraint_t)->constraint_name_ = (yyvsp[-6].constraint_name_t);
		(yyval.table_constraint_t)->column_name_list_ = (yyvsp[-2].column_name_list_t);
		(yyval.table_constraint_t)->reference_clause_ = (yyvsp[0].reference_clause_t);
		if((yyval.table_constraint_t)){
			auto tmp1 = (yyval.table_constraint_t)->column_name_list_; 
			while(tmp1){
				auto tmp2 = tmp1->column_name_; 
				if(tmp2){
					auto tmp3 = tmp2->identifier_; 
					if(tmp3){
						tmp3->data_type_ = kDataColumnName; 
						tmp3->scope_ = 2; 
						tmp3->data_flag_ =(DATAFLAG)8; 
					}
				}
				tmp1 = tmp1->column_name_list_;
			}
		}


	}
#line 8584 "y.tab.c"
    break;

  case 408:
#line 3727 "bison.y"
                  {
		(yyval.opt_enforced_t) = new OptEnforced();
		(yyval.opt_enforced_t)->case_idx_ = CASE0;
		
	}
#line 8594 "y.tab.c"
    break;

  case 409:
#line 3732 "bison.y"
                      {
		(yyval.opt_enforced_t) = new OptEnforced();
		(yyval.opt_enforced_t)->case_idx_ = CASE1;
		
	}
#line 8604 "y.tab.c"
    break;

  case 410:
#line 3737 "bison.y"
          {
		(yyval.opt_enforced_t) = new OptEnforced();
		(yyval.opt_enforced_t)->case_idx_ = CASE2;
		
	}
#line 8614 "y.tab.c"
    break;


#line 8618 "y.tab.c"

      default: break;
    }
  /* User semantic actions sometimes alter yychar, and that requires
     that yytoken be updated with the new translation.  We take the
     approach of translating immediately before every use of yytoken.
     One alternative is translating here after every semantic action,
     but that translation would be missed if the semantic action invokes
     YYABORT, YYACCEPT, or YYERROR immediately after altering yychar or
     if it invokes YYBACKUP.  In the case of YYABORT or YYACCEPT, an
     incorrect destructor might then be invoked immediately.  In the
     case of YYERROR or YYBACKUP, subsequent parser actions might lead
     to an incorrect destructor call or verbose syntax error message
     before the lookahead is translated.  */
  YY_SYMBOL_PRINT ("-> $$ =", yyr1[yyn], &yyval, &yyloc);

  YYPOPSTACK (yylen);
  yylen = 0;
  YY_STACK_PRINT (yyss, yyssp);

  *++yyvsp = yyval;
  *++yylsp = yyloc;

  /* Now 'shift' the result of the reduction.  Determine what state
     that goes to, based on the state we popped back to and the rule
     number reduced by.  */
  {
    const int yylhs = yyr1[yyn] - YYNTOKENS;
    const int yyi = yypgoto[yylhs] + *yyssp;
    yystate = (0 <= yyi && yyi <= YYLAST && yycheck[yyi] == *yyssp
               ? yytable[yyi]
               : yydefgoto[yylhs]);
  }

  goto yynewstate;


/*--------------------------------------.
| yyerrlab -- here on detecting error.  |
`--------------------------------------*/
yyerrlab:
  /* Make sure we have latest lookahead translation.  See comments at
     user semantic actions for why this is necessary.  */
  yytoken = yychar == YYEMPTY ? YYEMPTY : YYTRANSLATE (yychar);

  /* If not already recovering from an error, report this error.  */
  if (!yyerrstatus)
    {
      ++yynerrs;
#if ! YYERROR_VERBOSE
      yyerror (&yylloc, result, scanner, YY_("syntax error"));
#else
# define YYSYNTAX_ERROR yysyntax_error (&yymsg_alloc, &yymsg, \
                                        yyssp, yytoken)
      {
        char const *yymsgp = YY_("syntax error");
        int yysyntax_error_status;
        yysyntax_error_status = YYSYNTAX_ERROR;
        if (yysyntax_error_status == 0)
          yymsgp = yymsg;
        else if (yysyntax_error_status == 1)
          {
            if (yymsg != yymsgbuf)
              YYSTACK_FREE (yymsg);
            yymsg = YY_CAST (char *, YYSTACK_ALLOC (YY_CAST (YYSIZE_T, yymsg_alloc)));
            if (!yymsg)
              {
                yymsg = yymsgbuf;
                yymsg_alloc = sizeof yymsgbuf;
                yysyntax_error_status = 2;
              }
            else
              {
                yysyntax_error_status = YYSYNTAX_ERROR;
                yymsgp = yymsg;
              }
          }
        yyerror (&yylloc, result, scanner, yymsgp);
        if (yysyntax_error_status == 2)
          goto yyexhaustedlab;
      }
# undef YYSYNTAX_ERROR
#endif
    }

  yyerror_range[1] = yylloc;

  if (yyerrstatus == 3)
    {
      /* If just tried and failed to reuse lookahead token after an
         error, discard it.  */

      if (yychar <= YYEOF)
        {
          /* Return failure if at end of input.  */
          if (yychar == YYEOF)
            YYABORT;
        }
      else
        {
          yydestruct ("Error: discarding",
                      yytoken, &yylval, &yylloc, result, scanner);
          yychar = YYEMPTY;
        }
    }

  /* Else will try to reuse lookahead token after shifting the error
     token.  */
  goto yyerrlab1;


/*---------------------------------------------------.
| yyerrorlab -- error raised explicitly by YYERROR.  |
`---------------------------------------------------*/
yyerrorlab:
  /* Pacify compilers when the user code never invokes YYERROR and the
     label yyerrorlab therefore never appears in user code.  */
  if (0)
    YYERROR;

  /* Do not reclaim the symbols of the rule whose action triggered
     this YYERROR.  */
  YYPOPSTACK (yylen);
  yylen = 0;
  YY_STACK_PRINT (yyss, yyssp);
  yystate = *yyssp;
  goto yyerrlab1;


/*-------------------------------------------------------------.
| yyerrlab1 -- common code for both syntax error and YYERROR.  |
`-------------------------------------------------------------*/
yyerrlab1:
  yyerrstatus = 3;      /* Each real token shifted decrements this.  */

  for (;;)
    {
      yyn = yypact[yystate];
      if (!yypact_value_is_default (yyn))
        {
          yyn += YYTERROR;
          if (0 <= yyn && yyn <= YYLAST && yycheck[yyn] == YYTERROR)
            {
              yyn = yytable[yyn];
              if (0 < yyn)
                break;
            }
        }

      /* Pop the current state because it cannot handle the error token.  */
      if (yyssp == yyss)
        YYABORT;

      yyerror_range[1] = *yylsp;
      yydestruct ("Error: popping",
                  yystos[yystate], yyvsp, yylsp, result, scanner);
      YYPOPSTACK (1);
      yystate = *yyssp;
      YY_STACK_PRINT (yyss, yyssp);
    }

  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  *++yyvsp = yylval;
  YY_IGNORE_MAYBE_UNINITIALIZED_END

  yyerror_range[2] = yylloc;
  /* Using YYLLOC is tempting, but would change the location of
     the lookahead.  YYLOC is available though.  */
  YYLLOC_DEFAULT (yyloc, yyerror_range, 2);
  *++yylsp = yyloc;

  /* Shift the error token.  */
  YY_SYMBOL_PRINT ("Shifting", yystos[yyn], yyvsp, yylsp);

  yystate = yyn;
  goto yynewstate;


/*-------------------------------------.
| yyacceptlab -- YYACCEPT comes here.  |
`-------------------------------------*/
yyacceptlab:
  yyresult = 0;
  goto yyreturn;


/*-----------------------------------.
| yyabortlab -- YYABORT comes here.  |
`-----------------------------------*/
yyabortlab:
  yyresult = 1;
  goto yyreturn;


#if !defined yyoverflow || YYERROR_VERBOSE
/*-------------------------------------------------.
| yyexhaustedlab -- memory exhaustion comes here.  |
`-------------------------------------------------*/
yyexhaustedlab:
  yyerror (&yylloc, result, scanner, YY_("memory exhausted"));
  yyresult = 2;
  /* Fall through.  */
#endif


/*-----------------------------------------------------.
| yyreturn -- parsing is finished, return the result.  |
`-----------------------------------------------------*/
yyreturn:
  if (yychar != YYEMPTY)
    {
      /* Make sure we have latest lookahead translation.  See comments at
         user semantic actions for why this is necessary.  */
      yytoken = YYTRANSLATE (yychar);
      yydestruct ("Cleanup: discarding lookahead",
                  yytoken, &yylval, &yylloc, result, scanner);
    }
  /* Do not reclaim the symbols of the rule whose action triggered
     this YYABORT or YYACCEPT.  */
  YYPOPSTACK (yylen);
  YY_STACK_PRINT (yyss, yyssp);
  while (yyssp != yyss)
    {
      yydestruct ("Cleanup: popping",
                  yystos[+*yyssp], yyvsp, yylsp, result, scanner);
      YYPOPSTACK (1);
    }
#ifndef yyoverflow
  if (yyss != yyssa)
    YYSTACK_FREE (yyss);
#endif
#if YYERROR_VERBOSE
  if (yymsg != yymsgbuf)
    YYSTACK_FREE (yymsg);
#endif
  return yyresult;
}
#line 3744 "bison.y"

