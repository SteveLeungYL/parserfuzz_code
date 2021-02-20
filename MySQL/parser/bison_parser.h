/* A Bison parser, made by GNU Bison 3.5.1.  */

/* Bison interface for Yacc-like parsers in C

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

/* Undocumented macros, especially those whose name start with YY_,
   are private implementation details.  Do not rely on them.  */

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

#line 61 "y.tab.h"

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

#line 644 "y.tab.h"

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
