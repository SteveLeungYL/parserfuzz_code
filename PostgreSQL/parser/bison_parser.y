%{
#include "bison_parser.h"
#include "flex_lexer.h"
#include <stdio.h>
#include <string.h>
int yyerror(YYLTYPE* llocp, Program * result, yyscan_t scanner, const char *msg) { return 0; }
%}
%code requires {
#include "../include/ast.h"
#include "parser_typedef.h"
}
%define api.prefix	{ff_}
%define parse.error	verbose
%define api.pure	full
%define api.token.prefix	{SQL_}
%locations

%initial-action {
    // Initialize
    @$.first_column = 0;
    @$.last_column = 0;
    @$.first_line = 0;
    @$.last_line = 0;
    @$.total_column = 0;
    @$.string_length = 0;
};
%lex-param { yyscan_t scanner }
%parse-param { Program* result }
%parse-param { yyscan_t scanner }
%union FF_STYPE{
	long	ival;
	char*	sval;
	double	fval;
	Program *	program_t;
	Stmtlist *	stmtlist_t;
	Stmt *	stmt_t;
	CreateStmt *	create_stmt_t;
	DropStmt *	drop_stmt_t;
	AlterStmt *	alter_stmt_t;
	AlterIndexStmt * alter_index_stmt_t;
	AlterGroupStmt * alter_group_stmt_t;
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
	OptFrameExclude *	opt_frame_exclude_t;
	FrameExclude *	frame_exclude_t;
	OptExistWindowName *	opt_exist_window_name_t;
	OptGroupClause *	opt_group_clause_t;
	OptHavingClause *	opt_having_clause_t;
	OptWhereClause *	opt_where_clause_t;
	WhereClause *	where_clause_t;
	FromClause *	from_clause_t;
	TableRef *	table_ref_t;
	OptOnOrUsing *	opt_on_or_using_t;
	OnOrUsing *	on_or_using_t;
	ColumnNameList *	column_name_list_t;
	OptTablePrefix *	opt_table_prefix_t;
	JoinOp *	join_op_t;
	OptJoinType *	opt_join_type_t;
	ExprList *	expr_list_t;
	OptLimitClause *	opt_limit_clause_t;
	LimitClause *	limit_clause_t;
	OptOrderClause *	opt_order_clause_t;
	OptOrderNulls *	opt_order_nulls_t;
	OrderItemList *	order_item_list_t;
	OrderItem *	order_item_t;
	OptOrderBehavior *	opt_order_behavior_t;
	OptWithClause *	opt_with_clause_t;
	CteList *	cte_list_t;
	CommonTableExpr * common_table_expr_t;
	CteTableName *	cte_table_name_t;
	OptAllOrDistinct *	opt_all_or_distinct_t;
	CreateTableStmt *	create_table_stmt_t;
	CreateIndexStmt *	create_index_stmt_t;
	CreateViewStmt *	create_view_stmt_t;
	DropIndexStmt *	drop_index_stmt_t;
	DropTableStmt *	drop_table_stmt_t;
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
	ReindexStmt *	reindex_stmt_t;
	AlterAction *	alter_action_t;
	ColumnDefList *	column_def_list_t;
	ColumnDef *	column_def_t;
	OptColumnConstraintList *	opt_column_constraint_list_t;
	ColumnConstraintList *	column_constraint_list_t;
	ColumnConstraint *	column_constraint_t;
	ConstraintType *	constraint_type_t;
	ForeignClause *	foreign_clause_t;
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
	CaseList *	case_list_t;
	CaseClause *	case_clause_t;
	CompExpr *	comp_expr_t;
	ExtractExpr *	extract_expr_t;
	DatetimeField *	datetime_field_t;
	ArrayIndex *	array_index_t;
	Literal *	literal_t;
	StringLiteral *	string_literal_t;
	BoolLiteral *	bool_literal_t;
	NumLiteral *	num_literal_t;
	IntLiteral *	int_literal_t;
	FloatLiteral *	float_literal_t;
	OptColumn *	opt_column_t;
	OptIfNotExist *	opt_if_not_exist_t;
	OptIfExist *	opt_if_exist_t;
	Identifier *	identifier_t;
	TableName *	table_name_t;
	ColumnName *	column_name_t;
	OptUnique *	opt_unique_t;
	ViewName *	view_name_t;
	IndexName * index_name_t;
	TablespaceName * tablespace_name_t;
	RoleName * role_name_t;
	ExtensionName * extension_name_t;
	IndexStorageParameter * index_storage_parameter_t;
	IndexStorageParameterList * index_storage_parameter_list_t;
	BinaryOp *	binary_op_t;
	OptNot *	opt_not_t;
	Name *	name_t;
	TypeName *	type_name_t;
	CharacterType *	character_type_t;
	CharacterWithLength *	character_with_length_t;
	CharacterWithoutLength *	character_without_length_t;
	CharacterConflicta *	character_conflicta_t;
	OptVarying *	opt_varying_t;
	NumericType *	numeric_type_t;
	OptTableConstraintList *	opt_table_constraint_list_t;
	TableConstraintList *	table_constraint_list_t;
	TableConstraint *	table_constraint_t;
	OptAlias *  opt_alias_t;
	FuncExpr * func_expr_t;
	FuncName * func_name_t;
	FuncArgs * func_args_t;
	OptSemi * opt_semi_t;
	OptNo * opt_no_t;
	OptNowait * opt_nowait_t;
	OptOwnedby * opt_owned_by_t;
	OnOffLiteral * on_off_literal_t;
	OptConcurrently * opt_concurrently_t;
	OptIfNotExistIndex * opt_if_not_exist_index_t;
	OptOnly * opt_only_t;
	OptUsingMethod * opt_using_method_t;
	MethodName * method_name_t;
	OptTablespace * opt_tablespace_t;
	OptWherePredicate * opt_where_predicate_t;
	PredicateName * predicate_name_t;
	OptWithIndexStorageParameterList * opt_with_index_storage_parameter_list_t;
	OptIncludeColumnNameList * opt_include_column_name_list_t;
	OptCollate * opt_collate_t;
	CollationName * collation_name_t;
	OptColumnOrExpr * opt_column_or_expr_t;
	IndexedCreateIndexRestStmtList * indexed_create_index_rest_stmt_list_t;
	CreateIndexRestStmt * create_index_rest_stmt_t;
	OptIndexOpclassParameterList * opt_index_opclass_parameter_list_t;
	OptOpclassParameterList * opt_opclass_parameter_list_t;
	IndexOpclassParameterList * index_opclass_parameter_list_t;
	IndexOpclassParameter * index_opclass_parameter_t;
	OpclassName * opclass_name_t;
	OpclassParameterName * opclass_parameter_name_t;
	OpclassParameterValue * opclass_parameter_value_t;
	OptIndexNameList * opt_index_name_list_t;
	IndexNameList * index_name_list_t;
	OptCascadeRestrict * opt_cascade_restrict_t;
	RoleSpecification * role_specification_t;
	UserName * user_name_t;
	UserNameList * user_name_list_t;
	GroupName * group_name_t;
	DropGroupStmt * drop_group_stmt_t;
	GroupNameList * group_name_list_t;
	ValuesStmt * values_stmt_t;
	ExprListWithParens * expr_list_with_parens_t;
	IntoClause * into_clause_t;
	OptTable * opt_table_t;
	AllorDistinct * all_or_distinct_t;
	DistinctClause * distinct_clause_t;
	OptTempTableName * opt_temp_table_name_t;
	OptMaterialized * opt_materialized_t;
	WithClause * with_clause_t;
	HavingClause * having_clause_t;
	OptAllClause * opt_all_clause_t;
	GroupClause * group_clause_t;
	OptSelectTarget * opt_select_target_t;
	RelationExpr * relation_expr_t;
	SimpleSelect * simple_select_t;
	OrderClause * order_clause_t;
	SelectLimit * select_limit_t;
	OptSelectLimit * opt_select_limit_t;
	ForLockingStrength * for_locking_strength_t;
	LockedRelsList * locked_rels_list_t;
	TableNameList * table_name_list_t;
	OptNoWaitorSkip * opt_nowait_or_skip_t;
	ForLockingItem * for_locking_item_t;
	ForLockingItemList * for_locking_item_list_t;
	ForLockingClause * for_locking_clause_t;
	OptForLockingClause  *  opt_for_locking_clause_t;
	PreparableStmt * preparable_stmt_t;
	AlterViewStmt * alter_view_stmt_t;
	AlterViewAction * alter_view_action_t;
	OwnerSpecification * owner_specification_t;
	SchemaName * schema_name_t;
	IndexOptViewOptionList * index_opt_view_option_list_t;
	IndexOptViewOption * index_opt_view_option_t;
	OptEqualViewOptionValue * opt_equal_view_option_value_t;
	ViewOptionName * view_option_name_t;
	ViewOptionValue * view_option_value_t;
	ViewOptionNameList * view_option_name_list_t;
	OptReindexOptionList * opt_reindex_option_list_t;
	ReindexOptionList * reindex_option_list_t;
	ReindexOption * reindex_option_t;
	DatabaseName * database_name_t;
	SystemName * system_name_t;
	CreateGroupStmt * create_group_stmt_t;
	OptWithOptionList * opt_with_option_list_t;
	OptWith * opt_with_t;
	OptionList * option_list_t;
	Option * option_t;
	RoleNameList * role_name_list_t;
	OptEncrypted * opt_encrypted_t;
	ViewNameList * view_name_list_t;
	OptOrReplace * opt_or_replace_t;
	OptTempToken * opt_temp_token_t;
	OptRecursive * opt_recursive_t;
	OptWithViewOptionList * opt_with_view_option_list_t;
	CreateTableAsStmt * create_table_as_stmt_t;
	CreateAsTarget * create_as_target_t;
	TableAccessMethodClause * table_access_method_clause_t;
	OptWithStorageParameterList * opt_with_storage_parameter_list_t;
	OnCommitOption * on_commit_option_t;
	OptWithData * opt_with_data_t;
	InsertTarget * insert_target_t;
	InsertQuery *insert_query_t;
	TargetEl * target_el_t;
	TargetList * target_list_t;
	ReturningClause * returning_clause_t;
	OverrideKind * override_kind_t;
	ValuesDefaultClause * values_default_clause_t;
	ExprDefaultListWithParens * expr_default_list_with_parens_t;
	ExprDefaultList * expr_default_list_t;
	AlterTblspcStmt * alter_tblspc_stmt_t;
	IndexOptTablespaceOptionList * index_opt_tablespace_option_list_t;
	IndexOptTablespaceOption * index_opt_tablespace_option_t;
	OptEqualTablespaceOptionValue * opt_equal_tablespace_option_value_t;
	TablespaceOptionName * tablespace_option_name_t;
	TablespaceOptionValue * tablespace_option_value_t;
	AlterConversionStmt * alter_conversion_stmt_t;
	ConversionName * conversion_name_t;
	UnreservedKeyword * unreserved_keyword_t;
	ReservedKeyword * reserved_keyword_t;
	ColNameKeyword * col_name_keyword_t;
	TypeFuncNameKeyword * type_func_name_keyword_t;
	ColId * col_id_t;
	TypeFunctionName * type_function_name_t;
	NonReservedWord * non_reserved_word_t;
	ColLabel * col_label_t;
	Attrs * attrs_t;
	AttrName * attr_name_t;
	AnyName * any_name_t;
	AnyNameList * any_name_list_t;
	OptTableElementList * opt_table_element_list_t;
	OptTypedTableElementList * opt_typed_table_element_list_t;
	TableElementList * table_element_list_t;
	TypedTableElementList * typed_table_element_list_t;
	TableElement * table_element_t;
	TypedTableElement * typed_table_element_t;
	TableLikeClause * table_like_clause_t;
	TableLikeOptionList * table_like_option_list_t;
	TableLikeOption * table_like_option_t;
	ColumnOptions * column_options_t;
	ColQualList * col_qual_list_t;
	ColConstraint * col_constraint_t;
	ColConstraintElem * col_constraint_elem_t;
	GeneratedWhen * generated_when_t;
	ConstraintAttr * constraint_attr_t;
	KeyMatch * key_match_t;
	OptInherit * opt_inherit_t;
	OptNoInherit * opt_no_inherit_t;
	OptColumnList * opt_column_list_t;
	ColumnList * column_list_t;
	ColumnElem * column_elem_t;
	OptPartitionSpec * opt_partition_spec_t;
	PartitionSpec * partition_spec_t;
	PartParams * part_params_t;
	PartElem * part_elem_t;
	OptWithReplotions * opt_with_replotions_t;
	OptTableSpace * opt_table_space_t;
	OptConsTableSpace * opt_cons_table_space_t;
	ExistingIndex * existing_index_t;
	PartitionBoundSpec * partition_bound_spec_t;
	HashPartboundElem * hash_partbound_elem_t;
	HashPartbound * hash_partbound_t;
	OptDefinition * opt_definition_t;
	Definition * definition_t;
	DefList * def_list_t;
	DefElem * def_elem_t;
	DefArg * def_arg_t;
	Iconst * Iconst_t;
	Sconst * Sconst_t;
	SignedIconst * signed_iconst_t;
	FuncType * func_type_t;
	OptBy * opt_by_t;
	NumericOnly * numeric_only_t;
	NumericOnlyList * numeric_only_list_t;
	OptParenthesizedSeqOptList * opt_parenthesized_seq_opt_list_t;
	SeqOptList * seq_opt_list_t;
	SeqOptElem * seq_opt_elem_t;
	Reloptions * reloptions_t;
	OptReloptions * opt_reloptions_t;
	ReloptionList * reloption_list_t;
	ReloptionElem * reloption_elem_t;
	OptClass * opt_class_t;
}

%token OP_NOTEQUAL SIMPLE TEXT OVER BETWEEN OP_SEMI BIGINT LIMIT
%token WITH ORDER LAST UNBOUNDED PRECEDING EXCEPT NUMERIC OP_LESSTHAN
%token PROCEDURE ACTION FIRST OP_GREATEREQ CHECK FULL NATURAL DOUBLE
%token NATIONAL OP_ADD CURRENT TRIGGER OP_SUB FALSE UNIQUE WHERE
%token MINUTE BEFORE ON OFF PARTIAL OF AFTER PRIMARY MONTH
%token DEFERRED OP_DOUBLE_DOLLAR VARYING OP_GREATERTHAN OR PLPGSQL DELETE INDEX
%token RETURN OP_MUL FOREIGN RESTRICT FOLLOWING TIES DEC SELECT
%token BEGIN LANGUAGE DISTINCT TRUE BY OP_MOD VALUES IS
%token ROW FUNCTION END RECURSIVE FOR UNION NULLS UPDATE
%token ELSE RANGE OFFSET INDEXED INSTEAD NCHAR AND REINDEX
%token INITIALLY YEAR PRECISION FILTER NOT VIEW DEFFERRABLE REAL
%token THEN OPTION DEFAULT GLOBAL CROSS CHAR REFERENCES OP_XOR
%token GROUP CASE SET RESET HOUR NO COLUMN LOCAL DROP
%token REPLACE ASC OP_COMMA TABLE ARRAY IF EXTRACT LEFT
%token OUTER DECIMAL PARTITION CASCADE ADD OTHERS OP_LESSEQ MATCH
%token ROWS JOIN LIKE INTEGER OP_RP INT BOOLEAN 
%token KEY EACH USING RENAME DO FLOAT OP_LP CHARACTER
%token UMINUS CAST GROUPS NULL SMALLINT INSERT TEMPORARY CONSTRAINT
%token CREATE OP_LBRACKET WHEN IMMEDIATE TO EXCLUDE DAY CONFLICT
%token OP_RBRACKET EXECUTE EXISTS INTO OP_DIVIDE CASCADED ISNULL AS
%token INNER INTERSECT IN OP_EQUAL VARCHAR ALTER DESC FROM
%token TEMP UNLOGGED SECOND WINDOW NOTHING HAVING DOUBLE_COLON
%token SUM COUNT COALESCE ANY SOME LOWER ALL TABLESPACE ATTACH DEPENDS EXTENSION STATISTICS OWNED NOWAIT
%token FILLFACTOR BUFFERING FASTUPDATE GINPENDINGLISTLIMIT PAGESPERRANGE AUTOSUMMARIZE DEDUPLICATEITEMS
%token CONCURRENTLY COLLATE INCLUDE ONLY USER CURRENT_USER SESSION_USER 
%token WITH_LA MATERIALIZED READ SHARE SKIP LOCKED MIN MAX
%token OWNER SCHEMA DATABASE SYSTEM VERBOSE
%token SUPERUSER NOSUPERUSER CREATEDB NOCREATEDB CREATEROLE NOCREATEROLE INHERIT NOINHERIT LOGIN NOLOGIN
%token REPLICATION NOREPLICATION BYPASSRLS NOBYPASSRLS CONNECTION PASSWORD VALID UNTIL ROLE ADMIN SYSID
%token ENCRYPTED WITHOUT OIDS COMMIT PRESERVE DATA RETURNING OVERRIDING VALUE CONVERSION
%token SETS DEFINER DISCARD EXCLUSIVE WRAPPER ROLLBACK WRITE GRANT CONTENT WITHIN UNLISTEN CSV CACHE HOLD
%token ISOLATION CURRENT_ROLE NFC INDEXES NORMALIZE FUNCTIONS OLD CURRENT_DATE LATERAL XMLEXISTS ATOMIC
%token STORED PASSING EXCLUDING INLINE CALLED XMLCONCAT EXTERNAL IMPLICIT SUBSTRING INTERVAL TEMPLATE
%token REFERENCING LABEL VIEWS ACCESS CHAIN LOCATION PLANS ABSOLUTE CURRENT_SCHEMA UNENCRYPTED SEARCH
%token CLUSTER REVOKE DOCUMENT MOVE XMLPI GROUPING METHOD PROGRAM COPY XMLSERIALIZE NFD UESCAPE IMPORT
%token CURRENT_CATALOG TRUSTED RIGHT NOTIFY SIMILAR COLLATION ASYMMETRIC ALWAYS RETURNS LOCK POLICY
%token UNCOMMITTED REF XMLFOREST INCLUDING ASSIGNMENT IDENTITY NULLIF SUPPORT SETOF MAXVALUE LISTEN DELIMITERS
%token SNAPSHOT CALL SYMMETRIC CYCLE CONSTRAINTS QUOTE DEALLOCATE GENERATED XMLELEMENT ATTRIBUTE NEXT AT INPUT
%token STRICT INCREMENT CUBE XMLROOT YES IMMUTABLE PARSER BOTH INHERITS MINVALUE STRIP ASENSITIVE ANALYZE NFKC
%token GREATEST PREPARED DICTIONARY CURRENT_TIME STDIN DELIMITER PLACING INVOKER RULE DETACH SCROLL PRIVILEGES
%token MODE EXPLAIN NAME DISABLE ANALYSE VARIADIC RESTART NOTNULL STABLE FORCE XMLTABLE FREEZE DECLARE ENCODING
%token CHARACTERISTICS REPLICA OVERLAY SHOW DOMAIN SEQUENCES ENUM WHITESPACE INSENSITIVE LOGGED HEADER DEPTH BREADTH
%token COLUMNS SERIALIZABLE CHECKPOINT TRANSACTION LEAKPROOF TRAILING STANDALONE TABLESAMPLE GRANTED MAPPING PRIOR
%token PARALLEL NFKD STDOUT OVERLAPS TIMESTAMP COST PUBLICATION CATALOG OPTIONS BIT NONE OBJECT LOAD NORMALIZED
%token COMMITTED CONFIGURATION RECHECK TYPE STATEMENT TRANSFORM SERVER VALIDATE SESSION AUTHORIZATION VALIDATOR
%token LEADING NEW FAMILY CURSOR TRUNCATE ORDINALITY TREAT EVENT CONTINUE TRIM LEVEL VOLATILE AGGREGATE COMMENT
%token ASSERTION PROCEDURAL ROUTINES VERSION TYPES REFRESH CLASS RELATIVE ESCAPE BINARY BACKWARD OPERATOR PROCEDURES
%token WORK LOCALTIMESTAMP XML UNKNOWN HANDLER REPEATABLE START COMMENTS SAVEPOINT XMLNAMESPACES SCHEMAS LOCALTIME
%token POSITION REASSIGN VACUUM FINALIZE ALSO RELEASE EXPRESSION INOUT PREPARE TIME LEAST ABORT XMLATTRIBUTES ZONE
%token FETCH XMLPARSE LARGE DEFAULTS SEQUENCE TABLES STORAGE FORWARD SQL ENABLE DEFERRABLE COMPRESSION ROLLUP SECURITY
%token SUBSCRIPTION OUT ILIKE NAMES CLOSE CURRENT_TIMESTAMP ROUTINE IDENT ICONST SCONST FCONST


%token <ival> INTLITERAL

%token <sval> STRINGLITERAL

%token <fval> FLOATLITERAL

%token <sval> IDENTIFIER


%type <program_t>	program
%type <stmtlist_t>	stmtlist
%type <stmt_t>	stmt
%type <create_stmt_t>	create_stmt
%type <drop_stmt_t>	drop_stmt
%type <alter_stmt_t>	alter_stmt
%type <alter_index_stmt_t>	alter_index_stmt
%type <alter_group_stmt_t>	alter_group_stmt
%type <select_stmt_t>	select_stmt
%type <select_with_parens_t>	select_with_parens
%type <select_no_parens_t>	select_no_parens
%type <select_clause_list_t>	select_clause_list
%type <select_clause_t>	select_clause
%type <combine_clause_t>	combine_clause
%type <opt_from_clause_t>	opt_from_clause
%type <select_target_t>	select_target
%type <opt_window_clause_t>	opt_window_clause
%type <window_clause_t>	window_clause
%type <window_def_list_t>	window_def_list
%type <window_def_t>	window_def
%type <window_name_t>	window_name
%type <window_t>	window
%type <opt_partition_t>	opt_partition
%type <opt_frame_clause_t>	opt_frame_clause
%type <range_or_rows_t>	range_or_rows
%type <frame_bound_start_t>	frame_bound_start
%type <frame_bound_end_t>	frame_bound_end
%type <frame_bound_t>	frame_bound
%type <opt_frame_exclude_t>	opt_frame_exclude
%type <frame_exclude_t>	frame_exclude
%type <opt_exist_window_name_t>	opt_exist_window_name
%type <opt_group_clause_t>	opt_group_clause
%type <opt_having_clause_t>	opt_having_clause
%type <opt_where_clause_t>	opt_where_clause
%type <where_clause_t>	where_clause
%type <from_clause_t>	from_clause
%type <table_ref_t>	table_ref
%type <opt_on_or_using_t>	opt_on_or_using
%type <on_or_using_t>	on_or_using
%type <column_name_list_t>	column_name_list
%type <opt_table_prefix_t>	opt_table_prefix
%type <join_op_t>	join_op
%type <opt_join_type_t>	opt_join_type
%type <expr_list_t>	expr_list
%type <opt_limit_clause_t>	opt_limit_clause
%type <limit_clause_t>	limit_clause
%type <opt_order_clause_t>	opt_order_clause
%type <opt_order_nulls_t>	opt_order_nulls
%type <order_item_list_t>	order_item_list
%type <order_item_t>	order_item
%type <opt_order_behavior_t>	opt_order_behavior
%type <opt_with_clause_t>	opt_with_clause
%type <cte_list_t>	cte_list
%type <common_table_expr_t> common_table_expr
%type <opt_all_or_distinct_t>	opt_all_or_distinct
%type <create_table_stmt_t>	create_table_stmt
%type <create_index_stmt_t>	create_index_stmt
%type <create_view_stmt_t>	create_view_stmt
%type <drop_index_stmt_t>	drop_index_stmt
%type <drop_table_stmt_t>	drop_table_stmt
%type <drop_view_stmt_t>	drop_view_stmt
%type <insert_stmt_t>	insert_stmt
%type <insert_rest_t>	insert_rest
%type <super_values_list_t>	super_values_list
%type <values_list_t>	values_list
%type <opt_on_conflict_t>	opt_on_conflict
%type <opt_conflict_expr_t>	opt_conflict_expr
%type <indexed_column_list_t>	indexed_column_list
%type <indexed_column_t>	indexed_column
%type <update_stmt_t>	update_stmt
%type <reindex_stmt_t>	reindex_stmt
%type <alter_action_t>	alter_action
%type <column_def_list_t>	column_def_list
%type <column_def_t>	column_def
%type <opt_column_constraint_list_t>	opt_column_constraint_list
%type <column_constraint_list_t>	column_constraint_list
%type <column_constraint_t>	column_constraint
%type <constraint_type_t>	constraint_type
%type <foreign_clause_t>	foreign_clause
%type <opt_foreign_key_actions_t>	opt_foreign_key_actions
%type <foreign_key_actions_t>	foreign_key_actions
%type <opt_constraint_attribute_spec_t>	opt_constraint_attribute_spec
%type <opt_initial_time_t>	opt_initial_time
%type <constraint_name_t>	constraint_name
%type <opt_temp_t>	opt_temp
%type <opt_check_option_t>	opt_check_option
%type <opt_column_name_list_p_t>	opt_column_name_list_p
%type <set_clause_list_t>	set_clause_list
%type <set_clause_t>	set_clause
%type <expr_t>	expr
%type <operand_t>	operand
%type <cast_expr_t>	cast_expr
%type <scalar_expr_t>	scalar_expr
%type <unary_expr_t>	unary_expr
%type <binary_expr_t>	binary_expr
%type <logic_expr_t>	logic_expr
%type <in_expr_t>	in_expr
%type <case_expr_t>	case_expr
%type <between_expr_t>	between_expr
%type <exists_expr_t>	exists_expr
%type <case_list_t>	case_list
%type <case_clause_t>	case_clause
%type <comp_expr_t>	comp_expr
%type <extract_expr_t>	extract_expr
%type <datetime_field_t>	datetime_field
%type <array_index_t>	array_index
%type <literal_t>	literal
%type <string_literal_t>	string_literal
%type <bool_literal_t>	bool_literal
%type <num_literal_t>	num_literal
%type <int_literal_t>	int_literal
%type <float_literal_t>	float_literal
%type <opt_column_t>	opt_column
%type <opt_if_not_exist_t>	opt_if_not_exist
%type <opt_if_exist_t>	opt_if_exist
%type <identifier_t>	identifier
%type <table_name_t>	table_name
%type <column_name_t>	column_name
%type <opt_unique_t>	opt_unique
%type <index_name_t>	index_name
%type <tablespace_name_t> tablespace_name
%type <role_name_t> role_name
%type <extension_name_t> extension_name
%type <index_storage_parameter_t> index_storage_parameter
%type <index_storage_parameter_list_t> index_storage_parameter_list
%type <view_name_t>	view_name
%type <binary_op_t>	binary_op
%type <opt_not_t>	opt_not
%type <name_t>	name
%type <type_name_t>	type_name
%type <character_type_t>	character_type
%type <character_with_length_t>	character_with_length
%type <character_without_length_t>	character_without_length
%type <character_conflicta_t>	character_conflicta
%type <opt_varying_t>	opt_varying
%type <numeric_type_t>	numeric_type
%type <opt_table_constraint_list_t>	opt_table_constraint_list
%type <table_constraint_list_t>	table_constraint_list
%type <table_constraint_t>	table_constraint
%type <opt_alias_t> opt_alias
%type <func_expr_t> func_expr
%type <func_name_t> func_name
%type <func_args_t> func_args
%type <opt_semi_t> opt_semi
%type <opt_no_t> opt_no
%type <opt_nowait_t> opt_nowait
%type <opt_owned_by_t> opt_owned_by
%type <on_off_literal_t> on_off_literal
%type <opt_concurrently_t> opt_concurrently
%type <opt_if_not_exist_index_t> opt_if_not_exist_index
%type <opt_only_t> opt_only
%type <opt_using_method_t> opt_using_method
%type <method_name_t> method_name
%type <opt_tablespace_t> opt_tablespace
%type <opt_where_predicate_t> opt_where_predicate
%type <predicate_name_t> predicate_name
%type <opt_with_index_storage_parameter_list_t> opt_with_index_storage_parameter_list
%type <opt_include_column_name_list_t> opt_include_column_name_list
%type <opt_collate_t> opt_collate
%type <collation_name_t> collation_name
%type <opt_column_or_expr_t> opt_column_or_expr
%type <indexed_create_index_rest_stmt_list_t> indexed_create_index_rest_stmt_list
%type <create_index_rest_stmt_t> create_index_rest_stmt
%type <opt_index_opclass_parameter_list_t> opt_index_opclass_parameter_list
%type <opt_opclass_parameter_list_t> opt_opclass_parameter_list
%type <index_opclass_parameter_list_t> index_opclass_parameter_list
%type <index_opclass_parameter_t> index_opclass_parameter
%type <opclass_name_t> opclass_name
%type <opclass_parameter_name_t> opclass_parameter_name
%type <opclass_parameter_value_t> opclass_parameter_value
%type <opt_index_name_list_t> opt_index_name_list
%type <index_name_list_t> index_name_list
%type <opt_cascade_restrict_t> opt_cascade_restrict
%type <role_specification_t> role_specification
%type <user_name_t> user_name
%type <user_name_list_t> user_name_list
%type <group_name_t> group_name
%type <drop_group_stmt_t> drop_group_stmt
%type <group_name_list_t> group_name_list
%type <values_stmt_t> values_stmt
%type <expr_list_with_parens_t> expr_list_with_parens
%type <into_clause_t> into_clause
%type <opt_table_t> opt_table
%type <all_or_distinct_t> all_or_distinct;
%type <distinct_clause_t> distinct_clause;
%type <opt_temp_table_name_t> opt_temp_table_name;
%type <opt_materialized_t> opt_materialized;
%type <with_clause_t> with_clause
%type <having_clause_t> having_clause
%type <opt_all_clause_t> opt_all_clause
%type <group_clause_t> group_clause
%type <opt_select_target_t> opt_select_target 
%type <relation_expr_t> relation_expr
%type <simple_select_t> simple_select
%type <order_clause_t> order_clause
%type <select_limit_t> select_limit
%type <opt_select_limit_t> opt_select_limit
%type <for_locking_strength_t> for_locking_strength
%type <locked_rels_list_t> locked_rels_list
%type <table_name_list_t> table_name_list
%type <opt_nowait_or_skip_t> opt_nowait_or_skip
%type <for_locking_item_t> for_locking_item
%type <for_locking_item_list_t> for_locking_item_list
%type <for_locking_clause_t> for_locking_clause
%type <opt_for_locking_clause_t> opt_for_locking_clause
%type <preparable_stmt_t> PreparableStmt
%type <alter_view_stmt_t> alter_view_stmt
%type <alter_view_action_t> alter_view_action
%type <owner_specification_t> owner_specification
%type <schema_name_t> schema_name
%type <index_opt_view_option_list_t> index_opt_view_option_list
%type <index_opt_view_option_t> index_opt_view_option
%type <opt_equal_view_option_value_t> opt_equal_view_option_value
%type <view_option_name_t> view_option_name
%type <view_option_value_t> view_option_value
%type <view_option_name_list_t> view_option_name_list
%type <opt_reindex_option_list_t> opt_reindex_option_list
%type <reindex_option_list_t> reindex_option_list
%type <reindex_option_t> reindex_option
%type <database_name_t> database_name
%type <system_name_t> system_name
%type <create_group_stmt_t> create_group_stmt
%type <opt_with_option_list_t> opt_with_option_list
%type <option_list_t> option_list
%type <option_t> option
%type <role_name_list_t> role_name_list
%type <opt_encrypted_t> opt_encrypted
%type <opt_with_t> opt_with
%type <view_name_list_t> view_name_list
%type <opt_or_replace_t> opt_or_replace
%type <opt_temp_token_t> opt_temp_token
%type <opt_recursive_t> opt_recursive
%type <opt_with_view_option_list_t> opt_with_view_option_list
%type <create_table_as_stmt_t> create_table_as_stmt
%type <create_as_target_t> create_as_target
%type <table_access_method_clause_t> table_access_method_clause
%type <opt_with_storage_parameter_list_t> opt_with_storage_parameter_list
%type <on_commit_option_t> on_commit_option
%type <opt_with_data_t> opt_with_data
%type <insert_target_t> insert_target
%type <insert_query_t> insert_query
%type <returning_clause_t> returning_clause
%type <target_list_t> target_list
%type <target_el_t> target_el
%type <override_kind_t> override_kind
%type <values_default_clause_t> values_default_clause
%type <expr_default_list_with_parens_t> expr_default_list_with_parens
%type <expr_default_list_t> expr_default_list
%type <alter_tblspc_stmt_t> alter_tblspc_stmt
%type <index_opt_tablespace_option_list_t> index_opt_tablespace_option_list
%type <index_opt_tablespace_option_t> index_opt_tablespace_option
%type <opt_equal_tablespace_option_value_t> opt_equal_tablespace_option_value
%type <tablespace_option_name_t> tablespace_option_name
%type <tablespace_option_value_t> tablespace_option_value
%type <alter_conversion_stmt_t> alter_conversion_stmt
%type <conversion_name_t> conversion_name
%type <unreserved_keyword_t> unreserved_keyword
%type <reserved_keyword_t> reserved_keyword
%type <col_name_keyword_t> col_name_keyword
%type <type_func_name_keyword_t> type_func_name_keyword
%type <col_id_t> col_id
%type <type_function_name_t> type_function_name
%type <non_reserved_word_t> non_reserved_word
%type <col_label_t> col_label
%type <attrs_t> attrs
%type <attr_name_t> attr_name
%type <any_name_t> any_name
%type <any_name_list_t> any_name_list
%type <opt_table_element_list_t> opt_table_element_list
%type <opt_typed_table_element_list_t> opt_typed_table_element_list
%type <table_element_list_t> table_element_list
%type <typed_table_element_list_t> typed_table_element_list
%type <table_element_t> table_element
%type <typed_table_element_t> typed_table_element
%type <table_like_clause_t> table_like_clause
%type <table_like_option_list_t> table_like_option_list
%type <table_like_option_t> table_like_option
%type <column_options_t> column_options
%type <col_qual_list_t> col_qual_list
%type <col_constraint_t> col_constraint
%type <col_constraint_elem_t> col_constraint_elem
%type <generated_when_t> generated_when
%type <constraint_attr_t> constraint_attr
%type <key_match_t> key_match
%type <key_actions_t> key_actions
//%type <key_update_t> key_update
//%type <key_delete_t> key_delete
//%type <key_action_t> key_action
%type <opt_inherit_t> opt_inherit
%type <opt_no_inherit_t> opt_no_inherit
%type <opt_column_list_t> opt_column_list
%type <column_list_t> column_list
%type <column_elem_t> column_elem
%type <opt_partition_spec_t> opt_partition_spec
%type <partition_spec_t> partition_spec
%type <part_params_t> part_params
%type <part_elem_t> part_elem
%type <opt_with_replotions_t> opt_with_replotions
%type <opt_table_space_t> opt_table_space
%type <opt_cons_table_space_t> opt_cons_table_space
%type <existing_index_t> existing_index
%type <partition_bound_spec_t> partition_bound_spec
%type <hash_partbound_elem_t> hash_partbound_elem
%type <hash_partbound_t> hash_partbound
%type <opt_definition_t> opt_definition
%type <definition_t> definition
%type <def_list_t> def_list
%type <def_elem_t> def_elem
%type <def_arg_t> def_arg
%type <Iconst_t> Iconst
%type <Sconst_t> Sconst
%type <signed_iconst_t> signed_iconst
%type <func_type_t> func_type
%type <opt_by_t> opt_by
%type <numeric_only_t> numeric_only
%type <numeric_only_list_t> numeric_only_list
%type <opt_parenthesized_seq_opt_list_t> opt_parenthesized_seq_opt_list
%type <seq_opt_list_t> seq_opt_list
%type <seq_opt_elem_t> seq_opt_elem
%type <reloptions_t> reloptions
%type <opt_reloptions_t> opt_reloptions
%type <reloption_list_t> reloption_list
%type <reloption_elem_t> reloption_elem
%type <opt_class_t> opt_class


%left  OR
%left  AND
%left  NOT
%nonassoc  OP_NOTEQUAL MATCH LIKE OP_EQUAL
%nonassoc  OP_LESSTHAN OP_GREATEREQ OP_GREATERTHAN OP_LESSEQ
%nonassoc  ISNULL
%nonassoc  IS
%left  OP_ADD OP_SUB
%left  OP_MUL OP_MOD OP_DIVIDE
%left  OP_XOR
%left  OP_DOT
%right  UMINUS
%left  OP_LBRACKET OP_RBRACKET
%left  OP_RP OP_LP
%nonassoc  JOIN
%nonassoc  ON

%destructor{
	free( ($$) );
}  <sval>

%destructor{
	 
}  <fval> <ival>

%destructor { if($$!=NULL)$$->deep_delete(); } <*>

%%
program:
	stmtlist  {
		$$ = result;
		$$->case_idx_ = CASE0;
		$$->stmtlist_ = $1;
				$$ = NULL;

	}
  ;

stmtlist:
	stmt opt_semi stmtlist  {
		$$ = new Stmtlist();
		$$->case_idx_ = CASE0;
		$$->stmt_ = $1;
		$$->opt_semi_ = $2;
		$$->stmtlist_ = $3;
	}
   |	stmt opt_semi  {
		$$ = new Stmtlist();
		$$->case_idx_ = CASE1;
		$$->stmt_ = $1;
		$$->opt_semi_ = $2;
		
	}
  ;

opt_semi:
	OP_SEMI {
		$$ = new OptSemi();
		$$ -> case_idx_ = CASE0;
	}
	|	OP_SEMI opt_semi {
		$$ = new OptSemi();
		$$ -> case_idx_ = CASE1;
		$$ -> opt_semi_ = $2;
	}
	|	/* empty */ {
		$$ = new OptSemi();
		$$ -> case_idx_ = CASE2;
	}
	;

stmt:
	create_stmt  {
		$$ = new Stmt();
		$$->case_idx_ = CASE0;
		$$->create_stmt_ = $1;
		
	}
   |	drop_stmt  {
		$$ = new Stmt();
		$$->case_idx_ = CASE1;
		$$->drop_stmt_ = $1;
		
	}
   |	select_stmt  {
		$$ = new Stmt();
		$$->case_idx_ = CASE2;
		$$->select_stmt_ = $1;
		
	}
   |	update_stmt  {
		$$ = new Stmt();
		$$->case_idx_ = CASE3;
		$$->update_stmt_ = $1;
		
	}
   |	insert_stmt  {
		$$ = new Stmt();
		$$->case_idx_ = CASE4;
		$$->insert_stmt_ = $1;
		
	}
   |	alter_stmt  {
		$$ = new Stmt();
		$$->case_idx_ = CASE5;
		$$->alter_stmt_ = $1;
		
	}
   |	alter_index_stmt  {
		$$ = new Stmt();
		$$->case_idx_ = CASE6;
		$$->alter_index_stmt_ = $1;
		
	}
   |	reindex_stmt  {
		$$ = new Stmt();
		$$->case_idx_ = CASE7;
		$$->reindex_stmt_ = $1;
		
	}
  |	alter_group_stmt  {
		$$ = new Stmt();
		$$->case_idx_ = CASE8;
		$$->alter_group_stmt_ = $1;
	}
  | 	drop_group_stmt {
  		$$ = new Stmt();
		$$->case_idx_ = CASE9;
		$$->drop_group_stmt_ = $1;
  	}
  | 	values_stmt {
    		$$ = new Stmt();
  		$$->case_idx_ = CASE10;
  		$$->values_stmt_ = $1;
    	}
  |	alter_view_stmt {
  		$$ = new Stmt();
		$$->case_idx_ = CASE11;
		$$->alter_view_stmt_ = $1;
  	}
  |	create_group_stmt {
  		$$ = new Stmt();
  		$$->case_idx_ = CASE12;
  		$$->create_group_stmt_ = $1;
  	}
  | 	alter_tblspc_stmt {
  		$$ = new Stmt();
		$$->case_idx_ = CASE13;
		$$->alter_tblspc_stmt_ = $1;
  	}
  | 	alter_conversion_stmt {
    		$$ = new Stmt();
  		$$->case_idx_ = CASE14;
  		$$->alter_conversion_stmt_ = $1;
    	}

  ;

PreparableStmt:
	select_stmt {
		$$ = new PreparableStmt();
		$$ -> select_stmt_ = $1;
	}
	| insert_stmt {
		$$ = new PreparableStmt();
		$$ -> insert_stmt_ = $1;
	}
	| update_stmt {
		$$ = new PreparableStmt();
		$$ -> update_stmt_ = $1;
	}
	/* | delete_stmt {

	}					by default all are $$=$1 */
	;


create_stmt:
	create_table_stmt  {
		$$ = new CreateStmt();
		$$->case_idx_ = CASE0;
		$$->create_table_stmt_ = $1;
		
	}
   |	create_index_stmt  {
		$$ = new CreateStmt();
		$$->case_idx_ = CASE1;
		$$->create_index_stmt_ = $1;
		
	}
   |	create_view_stmt  {
		$$ = new CreateStmt();
		$$->case_idx_ = CASE2;
		$$->create_view_stmt_ = $1;
		
	}
   | 	create_table_as_stmt {
   		$$ = new CreateStmt();
		$$->case_idx_ = CASE3;
		$$->create_table_as_stmt_ = $1;
   }
  ;

drop_stmt:
	drop_index_stmt  {
		$$ = new DropStmt();
		$$->case_idx_ = CASE0;
		$$->drop_index_stmt_ = $1;
		
	}
   |	drop_table_stmt  {
		$$ = new DropStmt();
		$$->case_idx_ = CASE1;
		$$->drop_table_stmt_ = $1;
		
	}
   |	drop_view_stmt  {
		$$ = new DropStmt();
		$$->case_idx_ = CASE2;
		$$->drop_view_stmt_ = $1;
		
	}
  ;

alter_stmt:
	ALTER TABLE table_name alter_action  {
		$$ = new AlterStmt();
		$$->case_idx_ = CASE0;
		$$->table_name_ = $3;
		$$->alter_action_ = $4;
		
	}
  ;

alter_index_stmt:
	ALTER INDEX IF EXISTS index_name RENAME TO index_name  {
		$$ = new AlterIndexStmt();
		$$->case_idx_ = CASE0;
		$$->index_name_0_ = $5;
		$$->index_name_1_ = $8;

		if($$){
			auto tmp1 = $$->index_name_0_; 
			if (tmp1) {
				auto tmp2 = tmp1->identifier_; 
				if(tmp2){
					tmp2->data_type_ = kDataIndexName; 
					tmp2->scope_ = 0; 
					tmp2->data_flag_ =DATAFLAG::kUse; 
				}
			}
			auto tmp3 = $$->index_name_1_; 
			if (tmp3) {
				auto tmp4 = tmp3->identifier_; 
				if(tmp4){
					tmp4->data_type_ = kDataIndexName; 
					tmp4->scope_ = 0; 
					tmp4->data_flag_ =DATAFLAG::kDefine; 
				}
			}
		}
	}
	| ALTER INDEX index_name RENAME TO index_name  {
		$$ = new AlterIndexStmt();
		$$->case_idx_ = CASE1;
		$$->index_name_0_ = $3;
		$$->index_name_1_ = $6;

		if($$){
			auto tmp1 = $$->index_name_0_; 
			if (tmp1) {
				auto tmp2 = tmp1->identifier_; 
				if(tmp2){
					tmp2->data_type_ = kDataIndexName; 
					tmp2->scope_ = 0; 
					tmp2->data_flag_ =DATAFLAG::kUse; 
				}
			}
			auto tmp3 = $$->index_name_1_; 
			if (tmp3) {
				auto tmp4 = tmp3->identifier_; 
				if(tmp4){
					tmp4->data_type_ = kDataIndexName; 
					tmp4->scope_ = 0; 
					tmp4->data_flag_ =DATAFLAG::kDefine; 
				}
			}
		}
	}
	| ALTER INDEX IF EXISTS index_name SET TABLESPACE tablespace_name {
		$$ = new AlterIndexStmt();
		$$->case_idx_ = CASE2;
		$$->index_name_0_ = $5;
		$$->tablespace_name_ = $8;
		if($$){
			auto tmp1 = $$->index_name_0_; 
			if (tmp1) {
				auto tmp2 = tmp1->identifier_; 
				if(tmp2){
					tmp2->data_type_ = kDataIndexName; 
					tmp2->scope_ = 0; 
					tmp2->data_flag_ = DATAFLAG::kUse; 
				}
			}
			auto tmp3 = $$->tablespace_name_;
			if (tmp3) {
				auto tmp4 = tmp3->identifier_;
				if (tmp4) {
					tmp4->data_type_ = kDataTableSpaceName;
					tmp4->scope_ = 0;
					tmp4->data_flag_ = DATAFLAG::kUse;
				}
			}
		}
	}
	| ALTER INDEX index_name SET TABLESPACE tablespace_name {
		$$ = new AlterIndexStmt();
		$$->case_idx_ = CASE3;
		$$->index_name_0_ = $3;
		$$->tablespace_name_ = $6;
		if($$){
			auto tmp1 = $$->index_name_0_; 
			if (tmp1) {
				auto tmp2 = tmp1->identifier_; 
				if(tmp2){
					tmp2->data_type_ = kDataIndexName; 
					tmp2->scope_ = 0; 
					tmp2->data_flag_ = DATAFLAG::kUse; 
				}
			}
			auto tmp3 = $$->tablespace_name_;
			if (tmp3) {
				auto tmp4 = tmp3->identifier_;
				if (tmp4) {
					tmp4->data_type_ = kDataTableSpaceName;
					tmp4->scope_ = 0;
					tmp4->data_flag_ = DATAFLAG::kUse;
				}
			}
		}
	}
	| ALTER INDEX index_name ATTACH PARTITION index_name {
		$$ = new AlterIndexStmt();
		$$->case_idx_ = CASE4;
		$$->index_name_0_ = $3;
		$$->index_name_1_ = $6;

		if($$){
			auto tmp1 = $$->index_name_0_; 
			if (tmp1) {
				auto tmp2 = tmp1->identifier_; 
				if(tmp2){
					tmp2->data_type_ = kDataIndexName; 
					tmp2->scope_ = 0; 
					tmp2->data_flag_ =DATAFLAG::kUse; 
				}
			}
			auto tmp3 = $$->index_name_1_; 
			if (tmp3) {
				auto tmp4 = tmp3->identifier_; 
				if(tmp4){
					tmp4->data_type_ = kDataIndexName; 
					tmp4->scope_ = 0; 
					tmp4->data_flag_ =DATAFLAG::kUse; 
				}
			}
		}

	}
	| ALTER INDEX index_name opt_no DEPENDS ON EXTENSION extension_name {
		
		$$ = new AlterIndexStmt();
		$$->case_idx_ = CASE5;
		$$->index_name_0_ = $3;
		$$->opt_no_ = $4;
		$$->extension_name_ = $8;

		if($$){
			auto tmp1 = $$->index_name_0_; 
			if (tmp1) {
				auto tmp2 = tmp1->identifier_; 
				if(tmp2){
					tmp2->data_type_ = kDataIndexName; 
					tmp2->scope_ = 0; 
					tmp2->data_flag_ = DATAFLAG::kUse; 
				}
			}
			auto tmp3 = $$->extension_name_; 
			if (tmp3) {
				auto tmp4 = tmp3->identifier_; 
				if(tmp4){
					tmp4->data_type_ = kDataExtensionName; 
					tmp4->scope_ = 0; 
					tmp4->data_flag_ = DATAFLAG::kUse; 
				}
			}
		}
		
	}
	| ALTER INDEX IF EXISTS index_name SET OP_LP index_storage_parameter_list OP_RP {
		
		$$ = new AlterIndexStmt();
		$$->case_idx_ = CASE6;
		$$->index_name_0_ = $5;
		$$->index_storage_parameter_list_ = $8;

		if($$){
			auto tmp1 = $$->index_name_0_; 
			if (tmp1) {
				auto tmp2 = tmp1->identifier_; 
				if(tmp2){
					tmp2->data_type_ = kDataIndexName; 
					tmp2->scope_ = 0; 
					tmp2->data_flag_ = DATAFLAG::kUse; 
				}
			}
		}
	}
	| ALTER INDEX index_name SET OP_LP index_storage_parameter_list OP_RP {
		
		$$ = new AlterIndexStmt();
		$$->case_idx_ = CASE7;
		$$->index_name_0_ = $3;
		$$->index_storage_parameter_list_ = $6;

		if($$){
			auto tmp1 = $$->index_name_0_; 
			if (tmp1) {
				auto tmp2 = tmp1->identifier_; 
				if(tmp2){
					tmp2->data_type_ = kDataIndexName; 
					tmp2->scope_ = 0; 
					tmp2->data_flag_ = DATAFLAG::kUse; 
				}
			}
		}
	}
	| ALTER INDEX IF EXISTS index_name RESET OP_LP index_storage_parameter_list OP_RP {
		$$ = new AlterIndexStmt();
		$$->case_idx_ = CASE8;
		$$->index_name_0_ = $5;
		$$->index_storage_parameter_list_ = $8;

		if($$){
			auto tmp1 = $$->index_name_0_; 
			if (tmp1) {
				auto tmp2 = tmp1->identifier_; 
				if(tmp2){
					tmp2->data_type_ = kDataIndexName; 
					tmp2->scope_ = 0; 
					tmp2->data_flag_ = DATAFLAG::kUse; 
				}
			}
		}
	}
	| ALTER INDEX index_name RESET OP_LP index_storage_parameter_list OP_RP {
		$$ = new AlterIndexStmt();
		$$->case_idx_ = CASE9;
		$$->index_name_0_ = $3;
		$$->index_storage_parameter_list_ = $6;

		if($$){
			auto tmp1 = $$->index_name_0_; 
			if (tmp1) {
				auto tmp2 = tmp1->identifier_; 
				if(tmp2){
					tmp2->data_type_ = kDataIndexName; 
					tmp2->scope_ = 0; 
					tmp2->data_flag_ = DATAFLAG::kUse; 
				}
			}
		}
	}

	| ALTER INDEX IF EXISTS index_name ALTER opt_column int_literal SET STATISTICS int_literal {
		$$ = new AlterIndexStmt();
		$$->case_idx_ = CASE10;
		$$->index_name_0_ = $5;
		$$->opt_column_ = $7;
		$$->int_literal_0_ = $8;
		$$->int_literal_1_ = $11;

		if($$){
			auto tmp1 = $$->index_name_0_; 
			if (tmp1) {
				auto tmp2 = tmp1->identifier_; 
				if(tmp2){
					tmp2->data_type_ = kDataIndexName; 
					tmp2->scope_ = 0; 
					tmp2->data_flag_ = DATAFLAG::kUse; 
				}
			}
		}
	}
	| ALTER INDEX index_name ALTER opt_column int_literal SET STATISTICS int_literal {
		$$ = new AlterIndexStmt();
		$$->case_idx_ = CASE11;
		$$->index_name_0_ = $3;
		$$->opt_column_ = $5;
		$$->int_literal_0_ = $6;
		$$->int_literal_1_ = $9;

		if($$){
			auto tmp1 = $$->index_name_0_; 
			if (tmp1) {
				auto tmp2 = tmp1->identifier_; 
				if(tmp2){
					tmp2->data_type_ = kDataIndexName; 
					tmp2->scope_ = 0; 
					tmp2->data_flag_ = DATAFLAG::kUse; 
				}
			}
		}
	}
	| ALTER INDEX ALL IN TABLESPACE tablespace_name opt_owned_by SET TABLESPACE tablespace_name opt_nowait {
		$$ = new AlterIndexStmt();
		$$->case_idx_ = CASE12;
		$$->tablespace_name_0_ = $6;
		$$->opt_owned_by_ = $7;
		$$->tablespace_name_1_ = $10;
		$$->opt_no_wait_ = $11;

		if($$){
			auto tmp1 = $$->tablespace_name_0_; 
			if (tmp1) {
				auto tmp2 = tmp1->identifier_; 
				if(tmp2){
					tmp2->data_type_ = kDataTableSpaceName; 
					tmp2->scope_ = 0; 
					tmp2->data_flag_ = DATAFLAG::kUse; 
				}
			}
			auto tmp3 = $$->tablespace_name_1_; 
			if (tmp3) {
				auto tmp4 = tmp3->identifier_; 
				if(tmp4){
					tmp4->data_type_ = kDataTableSpaceName; 
					tmp4->scope_ = 0; 
					tmp4->data_flag_ = DATAFLAG::kDefine; 
				}
			}
			auto tmp5 = $$->opt_owned_by_;
			if (tmp5) {
				auto tmp6 = tmp5->role_name_; 
				if(tmp6){
					auto tmp7 = tmp6->identifier_;
					if (tmp7) {
						tmp7->data_type_ = kDataRoleName; 
						tmp7->scope_ = 0; 
						tmp7->data_flag_ = DATAFLAG::kUse; 
					}
				}
			}
		}
	}
  ;


alter_group_stmt:
	ALTER GROUP role_specification ADD USER user_name_list  {
		$$ = new AlterGroupStmt();
		$$->case_idx_ = CASE0;
		$$->role_specification_ = $3;
		$$->user_name_list_ = $6;

		if($$){
			auto tmp1 = $$->role_specification_;
			if (tmp1) {
				auto tmp2 = tmp1->role_name_;
				if(tmp2){
					auto tmp3 = tmp2->identifier_;
					if(tmp3){
						tmp3->data_type_ = kDataRoleName;
						tmp3->scope_ = 0;
						tmp3->data_flag_ =DATAFLAG::kUse;
					}

				}
			}

			auto tmp4 = $$->user_name_list_;
			while (tmp4) {
				auto tmp5 = tmp4->user_name_;
				if (tmp5) {
					auto tmp6 = tmp5->identifier_;
					if(tmp6){
						tmp6->data_type_ = kDataUserName;
						tmp6->scope_ = 0;
						tmp6->data_flag_ =DATAFLAG::kUse;
					}
				}
				tmp4 = tmp4->user_name_list_;
			}
		}
	}
	| ALTER GROUP role_specification DROP USER user_name_list {
		$$ = new AlterGroupStmt();
		$$->case_idx_ = CASE1;
		$$->role_specification_ = $3;
		$$->user_name_list_ = $6;

		if($$){
			auto tmp1 = $$->role_specification_;
			if (tmp1) {
				auto tmp2 = tmp1->role_name_;
				if(tmp2){
					auto tmp3 = tmp2->identifier_;
					if(tmp3){
						tmp3->data_type_ = kDataRoleName;
						tmp3->scope_ = 0;
						tmp3->data_flag_ =DATAFLAG::kUse;
					}

				}
			}

			auto tmp4 = $$->user_name_list_;
			while (tmp4) {
				auto tmp5 = tmp4->user_name_;
				if (tmp5) {
					auto tmp6 = tmp5->identifier_;
					if(tmp6){
						tmp6->data_type_ = kDataUserName;
						tmp6->scope_ = 0;
						tmp6->data_flag_ =DATAFLAG::kUse;
					}
				}
				tmp4 = tmp4->user_name_list_;
			}

		}
	}
	| ALTER GROUP group_name RENAME TO group_name {
        		$$ = new AlterGroupStmt();
        		$$->case_idx_ = CASE2;
        		$$->group_name_0_ = $3;
        		$$->group_name_1_ = $6;

        		if($$){
        			auto tmp1 = $$->group_name_0_;
        			if (tmp1) {

					auto tmp2 = tmp1->identifier_;
					if(tmp2){
						tmp2->data_type_ = kDataGroupName;
						tmp2->scope_ = 0;
						tmp2->data_flag_ =DATAFLAG::kUse;
					}
        			}

        			auto tmp3 = $$->group_name_1_;
        			if (tmp3) {
        				auto tmp4 = tmp3->identifier_;
        				if(tmp4){
        					tmp4->data_type_ = kDataGroupName;
        					tmp4->scope_ = 0;
        					tmp4->data_flag_ =DATAFLAG::kDefine;
        				}
        			}

        		}
        	}
  ;

select_stmt:
	select_no_parens %prec UMINUS {
		$$ = new SelectStmt();
		$$->case_idx_ = CASE0;
		$$->select_no_parens_ = $1;
		
	}
   |	select_with_parens %prec UMINUS {
		$$ = new SelectStmt();
		$$->case_idx_ = CASE1;
		$$->select_with_parens_ = $1;
		
	}
  ;

select_with_parens:
	OP_LP select_no_parens OP_RP  {
		$$ = new SelectWithParens();
		$$->case_idx_ = CASE0;
		$$->select_no_parens_ = $2;
		
	}
   |	OP_LP select_with_parens OP_RP  {
		$$ = new SelectWithParens();
		$$->case_idx_ = CASE1;
		$$->select_with_parens_ = $2;
		
	}
  ;

/* select_no_parens:
	opt_with_clause select_clause_list opt_order_clause opt_limit_clause  {
		$$ = new SelectNoParens();
		$$->case_idx_ = CASE0;
		$$->opt_with_clause_ = $1;
		$$->select_clause_list_ = $2;
		$$->opt_order_clause_ = $3;
		$$->opt_limit_clause_ = $4;
		
	}
  ; */

select_no_parens:
	simple_select	{
		$$ = new SelectNoParens();
		$$ -> case_idx_ = CASE0;
		$$ -> simple_select_ = $1;
	}
	| select_clause order_clause {
		$$ = new SelectNoParens();
		$$ -> case_idx_ = CASE1;
		$$ -> select_clause_ = $1;
		$$ -> order_clause_ = $2;
	}
	| select_clause opt_order_clause for_locking_clause opt_select_limit {
		$$ = new SelectNoParens();
		$$ -> case_idx_ = CASE2;
		$$ -> select_clause_ = $1;
		$$ -> opt_order_clause_ = $2;
		$$ -> for_locking_clause_ = $3;
		$$ -> opt_select_limit_ = $4;
	}
	| select_clause opt_order_clause select_limit opt_for_locking_clause {
		$$ = new SelectNoParens();
		$$ -> case_idx_ = CASE3;
		$$ -> select_clause_ = $1;
		$$ -> opt_order_clause_ = $2;
		$$ -> select_limit_ = $3;
		$$ -> opt_for_locking_clause_ = $4;
	}
	| with_clause select_clause {
		$$ = new SelectNoParens();
		$$ -> case_idx_ = CASE4;
		$$ -> with_clause_ = $1;
		$$ -> select_clause_ = $2;
	}
	| with_clause select_clause order_clause {
		$$ = new SelectNoParens();
		$$ -> case_idx_ = CASE5;
		$$ -> with_clause_ = $1;
		$$ -> select_clause_ = $2;
		$$ -> order_clause_ = $3;
	}
	| with_clause select_clause opt_order_clause for_locking_clause opt_select_limit {
		$$ = new SelectNoParens();
		$$ -> case_idx_ = CASE6;
		$$ -> with_clause_ = $1;
		$$ -> select_clause_ = $2;
		$$ -> opt_order_clause_ = $3;
		$$ -> for_locking_clause_ = $4;
		$$ -> opt_select_limit_ = $5;
	}
	| with_clause select_clause opt_order_clause select_limit opt_for_locking_clause {
		$$ = new SelectNoParens();
		$$ -> case_idx_ = CASE7;
		$$ -> with_clause_ = $1;
		$$ -> select_clause_ = $2;
		$$ -> opt_order_clause_ = $3;
		$$ -> select_limit_ = $4;
		$$ -> opt_for_locking_clause_ = $5;
	}
;

simple_select:
	SELECT opt_all_clause opt_select_target into_clause from_clause opt_where_clause opt_group_clause opt_having_clause opt_window_clause {
		$$ = new SimpleSelect();
		$$ -> case_idx_ = CASE0;
		$$ -> opt_all_clause_ = $2;
		$$ -> opt_select_target_ = $3;
		$$ -> into_clause_ = $4;
		$$ -> from_clause_ = $5;
		$$ -> opt_where_clause_ = $6;
		$$ -> opt_group_clause_ = $7;
		$$ -> opt_having_clause_ = $8;
		$$ -> opt_window_clause_ = $9;
	}
	| SELECT distinct_clause select_target into_clause from_clause opt_where_clause opt_group_clause opt_having_clause opt_window_clause {
		$$ = new SimpleSelect();
		$$ -> case_idx_ = CASE1;
		$$ -> distinct_clause_ = $2;
		$$ -> select_target_ = $3;
		$$ -> into_clause_ = $4;
		$$ -> from_clause_ = $5;
		$$ -> opt_where_clause_ = $6;
		$$ -> opt_group_clause_ = $7;
		$$ -> opt_having_clause_ = $8;
		$$ -> opt_window_clause_ = $9;
	}
	// | values_stmt { /* Ignore value_stmt at the moment. */
	// } 
	| TABLE relation_expr {
		$$ = new SimpleSelect();
		$$ -> case_idx_ = CASE2;
		$$ -> relation_expr_ = $2;
		/* Default kUse of table_name, no need to change. */
	}
	| select_clause UNION opt_all_or_distinct select_clause {
		$$ = new SimpleSelect();
		$$ -> case_idx_ = CASE3;
		$$ -> select_clause_ = $1;
		$$ -> opt_all_or_distinct_ = $3;
		$$ -> select_clause_2_ = $4;
	}
	| select_clause INTERSECT opt_all_or_distinct select_clause {
		$$ = new SimpleSelect();
		$$ -> case_idx_ = CASE4;
		$$ -> select_clause_ = $1;
		$$ -> opt_all_or_distinct_ = $3;
		$$ -> select_clause_2_ = $4;
	}
	| select_clause EXCEPT opt_all_or_distinct select_clause {
		$$ = new SimpleSelect();
		$$ -> case_idx_ = CASE5;
		$$ -> select_clause_ = $1;
		$$ -> opt_all_or_distinct_ = $3;
		$$ -> select_clause_2_ = $4;
	}
	;

/* TODO:: Currently ignores indirection in the original parser. Check qualified_name in the original parser. */
/* All using default kUse of table_name. No need to change. */
relation_expr:
	table_name {
		$$ = new RelationExpr();
		$$ -> case_idx_ = CASE0;
		$$ -> table_name_ = $1;
	}
	| table_name OP_MUL {
		$$ = new RelationExpr();
		$$ -> case_idx_ = CASE1;
		$$ -> table_name_ = $1;
	}
	| ONLY table_name {
		$$ = new RelationExpr();
		$$ -> case_idx_ = CASE2;
		$$ -> table_name_ = $2;
	}
	| ONLY OP_LP table_name OP_RP {
		$$ = new RelationExpr();
		$$ -> case_idx_ = CASE3;
		$$ -> table_name_ = $3;
	}
	;

for_locking_clause:
	for_locking_item_list {
		$$ = new ForLockingClause();
		$$->case_idx_ = CASE0;
		$$->for_locking_item_list_ = $1;
	}
	| FOR READ ONLY {
		$$ = new ForLockingClause();
		$$->case_idx_ = CASE1;
	}
	;

opt_for_locking_clause:
	for_locking_clause {
		$$ = new OptForLockingClause();
		$$ -> case_idx_ = CASE0;
		$$-> for_locking_clause_ = $1;
	}
	| /* EMPTY */ {
		$$ = new OptForLockingClause();
		$$ -> case_idx_ = CASE1;
	}
	;

for_locking_item_list:
	for_locking_item {
		$$ = new ForLockingItemList();
		$$ -> case_idx_ = CASE0;
		$$ -> for_locking_item_ = $1;	
	}
	| for_locking_item_list for_locking_item {
		$$ = new ForLockingItemList();
		$$ -> case_idx_ = CASE1;
		$$ -> for_locking_item_list_  = $1;
		$$ -> for_locking_item_ = $2;
	}
	;

for_locking_item: 
	for_locking_strength locked_rels_list opt_nowait_or_skip {
		$$ = new ForLockingItem();
		$$ -> case_idx_ = CASE0;
		$$ -> for_locking_strength_ = $1;
		$$ -> locked_rels_list_ = $2;
		$$ -> opt_no_wait_or_skip_ = $3;
	}
	;

for_locking_strength:
	FOR UPDATE {
		$$ = new ForLockingStrength();
		$$ -> case_idx_ = CASE0;
	}
	| FOR NO KEY UPDATE {
		$$ = new ForLockingStrength();
		$$ -> case_idx_ = CASE1;
	}
	| FOR SHARE {
		$$ = new ForLockingStrength();
		$$ -> case_idx_ = CASE2;
	}
	| FOR KEY SHARE {
		$$ = new ForLockingStrength();
		$$ -> case_idx_ = CASE3;
	}

locked_rels_list:
/* Using kUse of table_name by default. No need to change. */
		OF table_name_list {
			$$ = new LockedRelsList();
			$$ -> case_idx_ = CASE0;
			$$ -> table_name_list_ = $2;
		}
		| /* EMPTY */ {
			$$ = new LockedRelsList();
			$$ -> case_idx_ = CASE1;
		}
		;

opt_nowait_or_skip:
	NOWAIT {
		$$ = new OptNoWaitorSkip();
		$$ -> case_idx_ = CASE0;
	}
	| SKIP LOCKED {
		$$ = new OptNoWaitorSkip();
		$$ -> case_idx_ = CASE1;
	}
	| /*EMPTY*/	{
		$$ = new OptNoWaitorSkip();
		$$ -> case_idx_ = CASE2;
	}
	;

select_clause_list:
	select_clause  {
		$$ = new SelectClauseList();
		$$->case_idx_ = CASE0;
		$$->select_clause_ = $1;
		
	}
   |	select_clause combine_clause select_clause_list  {
		$$ = new SelectClauseList();
		$$->case_idx_ = CASE1;
		$$->select_clause_ = $1;
		$$->combine_clause_ = $2;
		$$->select_clause_list_ = $3;
		
	}
  ;

/* select_clause:
	SELECT opt_all_or_distinct select_target opt_from_clause opt_where_clause opt_group_clause opt_window_clause  {
		$$ = new SelectClause();
		$$->case_idx_ = CASE0;
		$$->opt_all_or_distinct_ = $2;
		$$->select_target_ = $3;
		$$->opt_from_clause_ = $4;
		$$->opt_where_clause_ = $5;
		$$->opt_group_clause_ = $6;
		$$->opt_window_clause_ = $7;
		
	}
  ; */

select_clause:
	simple_select {
		$$ = new SelectClause();
		$$ -> case_idx_ = CASE0;
		$$ -> simple_select_ = $1;
	}
	| select_with_parens {
		$$ = new SelectClause();
		$$ -> case_idx_ = CASE1;
		$$ -> select_with_parens_ = $1;	
	}
	;

opt_select_limit:
	opt_limit_clause {
		$$ = new OptSelectLimit();
		$$ -> case_idx_ = CASE0;
		$$ -> opt_limit_clause_ = $1;
	}
	// | /* EMPTY */ {
	// 	$$ = new OptSelectLimit();
	// 	$$ -> case_idx_ = CASE1;
	// }
	;

/* TODO:: Not accurate enough. Reusing Squirrel's limit_clause now. */
select_limit:
	limit_clause {
		$$ = new SelectLimit();
		$$ -> case_idx_ = CASE0;
		$$ -> limit_clause_ = $1;
	}
	;


combine_clause:
	UNION  {
		$$ = new CombineClause();
		$$->case_idx_ = CASE0;
		
	}
   |	INTERSECT  {
		$$ = new CombineClause();
		$$->case_idx_ = CASE1;
		
	}
   |	EXCEPT  {
		$$ = new CombineClause();
		$$->case_idx_ = CASE2;
		
	}
  ;

opt_from_clause:
	from_clause  {
		$$ = new OptFromClause();
		$$->case_idx_ = CASE0;
		$$->from_clause_ = $1;
		
	}
   |	  {
		$$ = new OptFromClause();
		$$->case_idx_ = CASE1;
		
	}
  ;

opt_select_target: 
	select_target {
		$$ = new OptSelectTarget();
		$$ -> case_idx_ = CASE0;
		$$ -> select_target_ = $1;
	}
	| /* empty */  {
		$$ = new OptSelectTarget();
		$$ -> case_idx_ = CASE1;
	}
	;

select_target:
	expr_list  {
		$$ = new SelectTarget();
		$$->case_idx_ = CASE0;
		$$->expr_list_ = $1;
		
  }
  ;

opt_window_clause:
	window_clause  {
		$$ = new OptWindowClause();
		$$->case_idx_ = CASE0;
		$$->window_clause_ = $1;
		
	}
   |	  {
		$$ = new OptWindowClause();
		$$->case_idx_ = CASE1;
		
	}
  ;

window_clause:
	WINDOW window_def_list  {
		$$ = new WindowClause();
		$$->case_idx_ = CASE0;
		$$->window_def_list_ = $2;
		
	}
  ;

window_def_list:
	window_def  {
		$$ = new WindowDefList();
		$$->case_idx_ = CASE0;
		$$->window_def_ = $1;
		
	}
   |	window_def OP_COMMA window_def_list  {
		$$ = new WindowDefList();
		$$->case_idx_ = CASE1;
		$$->window_def_ = $1;
		$$->window_def_list_ = $3;
		
	}
  ;

window_def:
	window_name AS OP_LP window OP_RP  {
		$$ = new WindowDef();
		$$->case_idx_ = CASE0;
		$$->window_name_ = $1;
		$$->window_ = $4;
		if($$){
			auto tmp1 = $$->window_name_; 
			if(tmp1){
				auto tmp2 = tmp1->identifier_; 
				if(tmp2){
					tmp2->data_type_ = kDataWindowName; 
					tmp2->scope_ = 1; 
					tmp2->data_flag_ = DATAFLAG::kDefine; 
				}
			}
		}


	}
  ;

window_name:
	identifier  {
		$$ = new WindowName();
		$$->case_idx_ = CASE0;
		$$->identifier_ = $1;
		
	}
  ;

window:
	opt_exist_window_name opt_partition opt_order_clause opt_frame_clause  {
		$$ = new Window();
		$$->case_idx_ = CASE0;
		$$->opt_exist_window_name_ = $1;
		$$->opt_partition_ = $2;
		$$->opt_order_clause_ = $3;
		$$->opt_frame_clause_ = $4;
		
	}
  ;

opt_partition:
	PARTITION BY expr_list  {
		$$ = new OptPartition();
		$$->case_idx_ = CASE0;
		$$->expr_list_ = $3;
		
	}
   |	  {
		$$ = new OptPartition();
		$$->case_idx_ = CASE1;
		
	}
  ;

opt_frame_clause:
	range_or_rows frame_bound_start opt_frame_exclude  {
		$$ = new OptFrameClause();
		$$->case_idx_ = CASE0;
		$$->range_or_rows_ = $1;
		$$->frame_bound_start_ = $2;
		$$->opt_frame_exclude_ = $3;
		
	}
   |	range_or_rows BETWEEN frame_bound_start AND frame_bound_end opt_frame_exclude  {
		$$ = new OptFrameClause();
		$$->case_idx_ = CASE1;
		$$->range_or_rows_ = $1;
		$$->frame_bound_start_ = $3;
		$$->frame_bound_end_ = $5;
		$$->opt_frame_exclude_ = $6;
		
	}
   |	  {
		$$ = new OptFrameClause();
		$$->case_idx_ = CASE2;
		
	}
  ;

range_or_rows:
	RANGE  {
		$$ = new RangeOrRows();
		$$->case_idx_ = CASE0;
		
	}
   |	ROWS  {
		$$ = new RangeOrRows();
		$$->case_idx_ = CASE1;
		
	}
   |	GROUPS  {
		$$ = new RangeOrRows();
		$$->case_idx_ = CASE2;
		
	}
  ;

frame_bound_start:
	frame_bound  {
		$$ = new FrameBoundStart();
		$$->case_idx_ = CASE0;
		$$->frame_bound_ = $1;
		
	}
   |	UNBOUNDED PRECEDING  {
		$$ = new FrameBoundStart();
		$$->case_idx_ = CASE1;
		
	}
  ;

frame_bound_end:
	frame_bound  {
		$$ = new FrameBoundEnd();
		$$->case_idx_ = CASE0;
		$$->frame_bound_ = $1;
		
	}
   |	UNBOUNDED FOLLOWING  {
		$$ = new FrameBoundEnd();
		$$->case_idx_ = CASE1;
		
	}
  ;

frame_bound:
	expr PRECEDING  {
		$$ = new FrameBound();
		$$->case_idx_ = CASE0;
		$$->expr_ = $1;
		
	}
   |	expr FOLLOWING  {
		$$ = new FrameBound();
		$$->case_idx_ = CASE1;
		$$->expr_ = $1;
		
	}
   |	CURRENT ROW  {
		$$ = new FrameBound();
		$$->case_idx_ = CASE2;
		
	}
  ;

opt_frame_exclude:
	EXCLUDE frame_exclude  {
		$$ = new OptFrameExclude();
		$$->case_idx_ = CASE0;
		$$->frame_exclude_ = $2;
		
	}
   |	  {
		$$ = new OptFrameExclude();
		$$->case_idx_ = CASE1;
		
	}
  ;

frame_exclude:
	NO OTHERS  {
		$$ = new FrameExclude();
		$$->case_idx_ = CASE0;
		
	}
   |	CURRENT ROW  {
		$$ = new FrameExclude();
		$$->case_idx_ = CASE1;
		
	}
   |	GROUP  {
		$$ = new FrameExclude();
		$$->case_idx_ = CASE2;
		
	}
   |	TIES  {
		$$ = new FrameExclude();
		$$->case_idx_ = CASE3;
		
	}
  ;

opt_exist_window_name:
	identifier  {
		$$ = new OptExistWindowName();
		$$->case_idx_ = CASE0;
		$$->identifier_ = $1;
		if($$){
			auto tmp1 = $$->identifier_; 
			if(tmp1){
				tmp1->data_type_ = kDataWindowName; 
				tmp1->scope_ = 1; 
				if (tmp1->data_flag_ != DATAFLAG::kDefine) {
					tmp1->data_flag_ =DATAFLAG::kUse; 
				}
			}
		}


	}
   |	  {
		$$ = new OptExistWindowName();
		$$->case_idx_ = CASE1;
		
	}
  ;

opt_group_clause:
	group_clause  {
		$$ = new OptGroupClause();
		$$->case_idx_ = CASE0;
		$$->group_clause_ = $1;
	}
   | /* empty */	  {
		$$ = new OptGroupClause();
		$$->case_idx_ = CASE1;
	}
  ;

group_clause:
	GROUP BY expr_list opt_having_clause {
		$$ = new GroupClause();
		$$ -> case_idx_ = CASE0;
		$$ -> expr_list_ = $3;
		$$ -> opt_having_clause_ = $4;
	}

opt_having_clause:
	having_clause {
		$$ = new OptHavingClause();
		$$->case_idx_ = CASE0;
		$$->having_clause_ = $1;
	}
   | /* empty */  {
		$$ = new OptHavingClause();
		$$->case_idx_ = CASE1;
	}
  ;

having_clause:
	HAVING expr {
		$$ = new HavingClause();
		$$->case_idx_ = CASE0;
		$$->expr_ = $2;
	}
	;

opt_all_clause:
	ALL	{
		$$ = new OptAllClause();
		$$->case_idx_ = CASE0;
	}
	| /*EMPTY*/	{
		$$ = new OptAllClause();
		$$->case_idx_ = CASE1;
	}
	;
opt_where_clause:
	where_clause  {
		$$ = new OptWhereClause();
		$$->case_idx_ = CASE0;
		$$->where_clause_ = $1;
		
	}
   |	  {
		$$ = new OptWhereClause();
		$$->case_idx_ = CASE1;
		
	}
  ;

where_clause:
	WHERE expr  {
		$$ = new WhereClause();
		$$->case_idx_ = CASE0;
		$$->expr_ = $2;
		
	}
  ;

from_clause:
	FROM table_ref  {
		$$ = new FromClause();
		$$->case_idx_ = CASE0;
		$$->table_ref_ = $2;
		
	}
  ;

table_ref:
	opt_table_prefix table_name opt_on_or_using  {
		$$ = new TableRef();
		$$->case_idx_ = CASE0;
		$$->opt_table_prefix_ = $1;
		$$->table_name_ = $2;
		$$->opt_on_or_using_ = $3;
		
	}
   |	opt_table_prefix OP_LP select_no_parens OP_RP opt_on_or_using opt_alias  {
		$$ = new TableRef();
		$$->case_idx_ = CASE1;
		$$->opt_table_prefix_ = $1;
		$$->select_no_parens_ = $3;
		$$->opt_on_or_using_ = $5;
		$$->opt_alias_ = $6;
		
	}
   |	opt_table_prefix OP_LP table_ref OP_RP opt_on_or_using  {
		$$ = new TableRef();
		$$->case_idx_ = CASE2;
		$$->opt_table_prefix_ = $1;
		$$->table_ref_ = $3;
		$$->opt_on_or_using_ = $5;
		
	}
  ;

opt_on_or_using:
	on_or_using  {
		$$ = new OptOnOrUsing();
		$$->case_idx_ = CASE0;
		$$->on_or_using_ = $1;
		
	}
   |	 %prec JOIN {
		$$ = new OptOnOrUsing();
		$$->case_idx_ = CASE1;
		
	}
  ;

on_or_using:
	ON expr  {
		$$ = new OnOrUsing();
		$$->case_idx_ = CASE0;
		$$->expr_ = $2;
		
	}
   |	USING OP_LP column_name_list OP_RP  {
		$$ = new OnOrUsing();
		$$->case_idx_ = CASE1;
		$$->column_name_list_ = $3;
		
	}
  ;

column_name_list:
	column_name  {
		$$ = new ColumnNameList();
		$$->case_idx_ = CASE0;
		$$->column_name_ = $1;
		
	}
   |	column_name OP_COMMA column_name_list  {
		$$ = new ColumnNameList();
		$$->case_idx_ = CASE1;
		$$->column_name_ = $1;
		$$->column_name_list_ = $3;
		
	}
  ;

index_storage_parameter_list:
	index_storage_parameter  {
		$$ = new IndexStorageParameterList();
		$$->case_idx_ = CASE0;
		$$->index_storage_parameter_ = $1;
	}
   |	index_storage_parameter OP_COMMA index_storage_parameter_list  {
		$$ = new IndexStorageParameterList();
		$$->case_idx_ = CASE1;
		$$->index_storage_parameter_ = $1;
		$$->index_storage_parameter_list_  = $3;
	}
  ;

index_storage_parameter:
	FILLFACTOR OP_EQUAL int_literal {
		$$ = new IndexStorageParameter();
		$$ -> case_idx_ = CASE0;
		$$ -> int_literal_ = $3;
	} 
	| BUFFERING OP_EQUAL on_off_literal {
		$$ = new IndexStorageParameter();
		$$ -> case_idx_ = CASE1;
		$$ -> on_off_literal_ = $3;
	}
	| FASTUPDATE OP_EQUAL on_off_literal {
		$$ = new IndexStorageParameter();
		$$ -> case_idx_ = CASE2;
		$$ -> on_off_literal_ = $3;
	}
	| GINPENDINGLISTLIMIT OP_EQUAL int_literal {
		$$ = new IndexStorageParameter();
		$$ -> case_idx_ = CASE3;
		$$ -> int_literal_ = $3;
	}
	| PAGESPERRANGE OP_EQUAL int_literal {
		$$ = new IndexStorageParameter();
		$$ -> case_idx_ = CASE4;
		$$ -> int_literal_ = $3;
	}
	| AUTOSUMMARIZE OP_EQUAL on_off_literal {
		$$ = new IndexStorageParameter();
		$$ -> case_idx_ = CASE5;
		$$ -> on_off_literal_ = $3;
	}
	| DEDUPLICATEITEMS OP_EQUAL on_off_literal {
		$$ = new IndexStorageParameter();
		$$ -> case_idx_ = CASE6;
		$$ -> on_off_literal_ = $3;
	}
	;

opt_table_prefix:
	table_ref join_op  {
		$$ = new OptTablePrefix();
		$$->case_idx_ = CASE0;
		$$->table_ref_ = $1;
		$$->join_op_ = $2;
		
	}
   |	  {
		$$ = new OptTablePrefix();
		$$->case_idx_ = CASE1;
		
	}
  ;

join_op:
	OP_COMMA  {
		$$ = new JoinOp();
		$$->case_idx_ = CASE0;
		
	}
   |	JOIN  {
		$$ = new JoinOp();
		$$->case_idx_ = CASE1;
		
	}
   |	NATURAL opt_join_type JOIN  {
		$$ = new JoinOp();
		$$->case_idx_ = CASE2;
		$$->opt_join_type_ = $2;
		
	}
  ;

opt_join_type:
	LEFT  {
		$$ = new OptJoinType();
		$$->case_idx_ = CASE0;
		
	}
   |	LEFT OUTER  {
		$$ = new OptJoinType();
		$$->case_idx_ = CASE1;
		
	}
   |	INNER  {
		$$ = new OptJoinType();
		$$->case_idx_ = CASE2;
		
	}
   |	CROSS  {
		$$ = new OptJoinType();
		$$->case_idx_ = CASE3;
		
	}
   |	  {
		$$ = new OptJoinType();
		$$->case_idx_ = CASE4;
		
	}
  ;

expr_list:
	expr OP_COMMA expr_list  {
		$$ = new ExprList();
		$$->case_idx_ = CASE0;
		$$->expr_ = $1;
		$$->expr_list_ = $3;
		
	}
   |	expr  {
		$$ = new ExprList();
		$$->case_idx_ = CASE1;
		$$->expr_ = $1;
		
	}
  ;

opt_limit_clause:
	limit_clause  {
		$$ = new OptLimitClause();
		$$->case_idx_ = CASE0;
		$$->limit_clause_ = $1;
		
	}
   |	  {
		$$ = new OptLimitClause();
		$$->case_idx_ = CASE1;
		
	}
  ;

limit_clause:
	LIMIT expr  {
		$$ = new LimitClause();
		$$->case_idx_ = CASE0;
		$$->expr_1_ = $2;
		
	}
   |	LIMIT expr OFFSET expr  {
		$$ = new LimitClause();
		$$->case_idx_ = CASE1;
		$$->expr_1_ = $2;
		$$->expr_2_ = $4;
		
	}
   |	LIMIT expr OP_COMMA expr  {
		$$ = new LimitClause();
		$$->case_idx_ = CASE2;
		$$->expr_1_ = $2;
		$$->expr_2_ = $4;
		
	}
  ;

opt_order_clause:
	order_clause {
		$$ = new OptOrderClause();
		$$ -> case_idx_ = CASE0;
		$$ -> order_clause_ = $1;
	}
   | /* empty */ {
	   $$ = new OptOrderClause();
	   $$ -> case_idx_ = CASE1;
	}
  ;

order_clause:
	ORDER BY order_item_list {
		$$ = new OrderClause();
		$$ -> case_idx_ = CASE0;
		$$ -> order_item_list_ = $3;
	}
	;

opt_order_nulls:
	NULLS FIRST  {
		$$ = new OptOrderNulls();
		$$->case_idx_ = CASE0;
		
	}
   |	NULLS LAST  {
		$$ = new OptOrderNulls();
		$$->case_idx_ = CASE1;
		
	}
   |	  {
		$$ = new OptOrderNulls();
		$$->case_idx_ = CASE2;
		
	}
  ;

order_item_list:
	order_item  {
		$$ = new OrderItemList();
		$$->case_idx_ = CASE0;
		$$->order_item_ = $1;
		
	}
   |	order_item OP_COMMA order_item_list  {
		$$ = new OrderItemList();
		$$->case_idx_ = CASE1;
		$$->order_item_ = $1;
		$$->order_item_list_ = $3;
		
	}
  ;

order_item:
	expr opt_order_behavior opt_order_nulls  {
		$$ = new OrderItem();
		$$->case_idx_ = CASE0;
		$$->expr_ = $1;
		$$->opt_order_behavior_ = $2;
		$$->opt_order_nulls_ = $3;
		
	}
  ;

opt_order_behavior:
	ASC  {
		$$ = new OptOrderBehavior();
		$$->case_idx_ = CASE0;
		
	}
   |	DESC  {
		$$ = new OptOrderBehavior();
		$$->case_idx_ = CASE1;
		
	}
   |	  {
		$$ = new OptOrderBehavior();
		$$->case_idx_ = CASE2;
		
	}
  ;

opt_with_clause:
	with_clause {
		$$ = new OptWithClause();
		$$->case_idx_ = CASE0;
		$$->with_clause_ = $1;
	}
   | /* empty */  {
	   	$$ = new OptWithClause();
		$$->case_idx_ = CASE1;
	}
  ;

with_clause:
	WITH cte_list {
		$$ = new WithClause();
		$$->case_idx_ = CASE0;
		$$->cte_list_ = $2;
	}
	| WITH_LA cte_list{
		$$ = new WithClause();
		$$->case_idx_ = CASE1;
		$$->cte_list_ = $2;
	}
	| WITH RECURSIVE cte_list {
		$$ = new WithClause();
		$$->case_idx_ = CASE2;
		$$->cte_list_ = $3;
	}
	;

cte_list:
	common_table_expr  {
		$$ = new CteList();
		$$->case_idx_ = CASE0;
		$$->common_table_expr_ = $1;
	}
   |	cte_list OP_COMMA common_table_expr  {
	   $$ = new CteList();
	   $$->case_idx_ = CASE1;
	   $$->cte_list_ = $1;
	   $$->common_table_expr_ = $3;
	}
  ;

common_table_expr: 
	table_name column_name_list AS opt_materialized OP_LP PreparableStmt OP_RP {
		$$ = new CommonTableExpr();
		$$->table_name_ = $1;
		$$->column_name_list_ = $2;
		$$->opt_materialized_ = $4;
		$$->preparable_stmt_ = $6;

		if ($$) {
			auto tmp0 = $$->table_name_;
			if (tmp0) {
				auto tmp1 = tmp0 ->identifier_;
				if (tmp1) {
					tmp1->data_type_ = kDataTableName; 
					tmp1->scope_ = 1;
					tmp1->data_flag_ = DATAFLAG::kDefine; 
				}
			}
		}
	}
;

into_clause:
	INTO opt_temp_table_name {
		$$ = new IntoClause();
		$$->case_idx_ = CASE0;
		$$->opt_temp_table_name_ = $2;
	}
	| /*EMPTY*/ {
		$$ = new IntoClause();
		$$->case_idx_ = CASE1;
	}
	;

opt_materialized:
	MATERIALIZED {
		$$ = new OptMaterialized();
		$$->case_idx_ = CASE0;
	}
	| NOT MATERIALIZED {
		$$ = new OptMaterialized();
		$$->case_idx_ = CASE1;
	}
	| /*EMPTY*/ {
		$$ = new OptMaterialized();
		$$->case_idx_ = CASE2;
	}
	;

/* TODO:: Currently ignores indirection in the original parser. Check qualified_name in the original parser. */
opt_temp_table_name:
	TEMPORARY opt_table table_name
	{
		$$ = new OptTempTableName();
		$$->case_idx_ = CASE0;
		$$->opt_table_ = $2;
		$$->table_name_ = $3;

		if ($$) {
			auto tmp0 = $$->table_name_;
			if (tmp0) {
				auto tmp1 = tmp0 ->identifier_;
				if (tmp1) {
					tmp1->data_type_ = kDataTableName; 
					tmp1->scope_ = 1;
					tmp1->data_flag_ = DATAFLAG::kDefine; 
				}
			}
		}
	}
	| TEMP opt_table table_name
	{
		$$ = new OptTempTableName();
		$$->case_idx_ = CASE1;
		$$->opt_table_ = $2;
		$$->table_name_ = $3;

		if ($$) {
			auto tmp0 = $$->table_name_;
			if (tmp0) {
				auto tmp1 = tmp0 ->identifier_;
				if (tmp1) {
					tmp1->data_type_ = kDataTableName; 
					tmp1->scope_ = 1;
					tmp1->data_flag_ = DATAFLAG::kDefine; 
				}
			}
		}
	}
	| LOCAL TEMPORARY opt_table table_name
	{
		$$ = new OptTempTableName();
		$$->case_idx_ = CASE2;
		$$->opt_table_ = $3;
		$$->table_name_ = $4;

		if ($$) {
			auto tmp0 = $$->table_name_;
			if (tmp0) {
				auto tmp1 = tmp0 ->identifier_;
				if (tmp1) {
					tmp1->data_type_ = kDataTableName; 
					tmp1->scope_ = 1;
					tmp1->data_flag_ = DATAFLAG::kDefine; 
				}
			}
		}
	}
	| LOCAL TEMP opt_table table_name
	{
		$$ = new OptTempTableName();
		$$->case_idx_ = CASE3;
		$$->opt_table_ = $3;
		$$->table_name_ = $4;

		if ($$) {
			auto tmp0 = $$->table_name_;
			if (tmp0) {
				auto tmp1 = tmp0 ->identifier_;
				if (tmp1) {
					tmp1->data_type_ = kDataTableName; 
					tmp1->scope_ = 1;
					tmp1->data_flag_ = DATAFLAG::kDefine; 
				}
			}
		}
	}
	| GLOBAL TEMPORARY opt_table table_name
	{
		$$ = new OptTempTableName();
		$$->case_idx_ = CASE4;
		$$->opt_table_ = $3;
		$$->table_name_ = $4;

		if ($$) {
			auto tmp0 = $$->table_name_;
			if (tmp0) {
				auto tmp1 = tmp0 ->identifier_;
				if (tmp1) {
					tmp1->data_type_ = kDataTableName; 
					tmp1->scope_ = 1;
					tmp1->data_flag_ = DATAFLAG::kDefine; 
				}
			}
		}
	}
	| GLOBAL TEMP opt_table table_name
	{
		$$ = new OptTempTableName();
		$$->case_idx_ = CASE5;
		$$->opt_table_ = $3;
		$$->table_name_ = $4;

		if ($$) {
			auto tmp0 = $$->table_name_;
			if (tmp0) {
				auto tmp1 = tmp0 ->identifier_;
				if (tmp1) {
					tmp1->data_type_ = kDataTableName; 
					tmp1->scope_ = 1;
					tmp1->data_flag_ = DATAFLAG::kDefine; 
				}
			}
		}
	}
	| UNLOGGED opt_table table_name
	{
		$$ = new OptTempTableName();
		$$->case_idx_ = CASE6;
		$$->opt_table_ = $2;
		$$->table_name_ = $3;

		if ($$) {
			auto tmp0 = $$->table_name_;
			if (tmp0) {
				auto tmp1 = tmp0 ->identifier_;
				if (tmp1) {
					tmp1->data_type_ = kDataTableName; 
					tmp1->scope_ = 1;
					tmp1->data_flag_ = DATAFLAG::kDefine; 
				}
			}
		}
	}
	| TABLE table_name
	{
		$$ = new OptTempTableName();
		$$->case_idx_ = CASE7;
		$$->table_name_ = $2;

		if ($$) {
			auto tmp0 = $$->table_name_;
			if (tmp0) {
				auto tmp1 = tmp0 ->identifier_;
				if (tmp1) {
					tmp1->data_type_ = kDataTableName; 
					tmp1->scope_ = 1;
					tmp1->data_flag_ = DATAFLAG::kDefine; 
				}
			}
		}
	}
	| TABLE
	{
		$$ = new OptTempTableName();
		$$->case_idx_ = CASE8;

		if ($$) {
			auto tmp0 = $$->table_name_;
			if (tmp0) {
				auto tmp1 = tmp0 ->identifier_;
				if (tmp1) {
					tmp1->data_type_ = kDataTableName; 
					tmp1->scope_ = 1;
					tmp1->data_flag_ = DATAFLAG::kDefine; 
				}
			}
		}
	}
	;

opt_table:
	TABLE {
		$$ = new OptTable();
		$$->case_idx_ = CASE0;
	}
	| /* empty */ {
		$$ = new OptTable();
		$$->case_idx_ = CASE1;
	}
	;

opt_all_or_distinct:
	all_or_distinct {
		$$ = new OptAllOrDistinct();
		$$-> case_idx_ = CASE0;
		$$->all_or_distinct_ = $1;
	}
   	| /* empty */ {
		$$ = new OptAllOrDistinct();
		$$->case_idx_ = CASE1;
	}
  ;

all_or_distinct:
	ALL {
		$$ = new AllorDistinct();
		$$->case_idx_ = CASE0;
	}
	| DISTINCT {
		$$ = new AllorDistinct();
		$$->case_idx_ = CASE1;
	}
	;

distinct_clause:
	DISTINCT { 
		$$ = new DistinctClause();
		$$->case_idx_ = CASE0;
	}
	| DISTINCT ON OP_LP expr_list OP_RP	{
		$$ = new DistinctClause();
		$$->case_idx_ = CASE1;
		$$->expr_list_ = $4;
	}
	;

create_table_stmt:
	CREATE opt_temp TABLE opt_if_not_exist table_name OP_LP opt_table_element_list OP_RP opt_inherit opt_partition_spec  table_access_method_clause opt_with_replotions on_commit_option opt_tablespace {
		$$ = new CreateTableStmt();
		$$->case_idx_ = CASE0;
		$$->opt_temp_ = $2;
		$$->opt_if_not_exist_ = $4;
		$$->table_name_ = $5;
		$$->opt_table_element_list_ = $7;
		$$->opt_inherit_ = $9;
		$$->opt_partition_spec_ = $10;
		$$->table_access_method_clause_ = $11;
		$$->opt_with_replotions_ = $12;
		$$->on_commit_option_ = $13;
		$$->opt_tablespace_ = $14;

		if($$){
			auto tmp1 = $$->table_name_;
			if(tmp1){
				auto tmp2 = tmp1->identifier_;
				if(tmp2){
					tmp2->data_type_ = kDataTableName;
					tmp2->scope_ = 1;
					tmp2->data_flag_ = DATAFLAG::kDefine;
				}
			}
		}
	}
	| CREATE opt_temp TABLE opt_if_not_exist table_name OF any_name opt_typed_table_element_list opt_partition_spec table_access_method_clause opt_with_replotions on_commit_option opt_tablespace {
		$$ = new CreateTableStmt();
		$$->case_idx_ = CASE1;
		$$->opt_temp_ = $2;
		$$->opt_if_not_exist_ = $4;
		$$->table_name_ = $5;
		$$->any_name_ = $7;
		$$->opt_typed_table_element_list_ = $8;
		$$->opt_partition_spec_ = $9;
		$$->table_access_method_clause_ = $10;
		$$->opt_with_replotions_ = $11;
		$$->on_commit_option_ = $12;
		$$->opt_tablespace_ = $13;

		if($$){
			auto tmp1 = $$->table_name_;
			if(tmp1){
				auto tmp2 = tmp1->identifier_;
				if(tmp2){
					tmp2->data_type_ = kDataTableName;
					tmp2->scope_ = 1;
					tmp2->data_flag_ = DATAFLAG::kDefine;
				}
			}
		}

	}
	| CREATE opt_temp TABLE opt_if_not_exist table_name PARTITION OF table_name opt_typed_table_element_list partition_bound_spec opt_partition_spec table_access_method_clause opt_with_replotions on_commit_option opt_tablespace  {
		$$ = new CreateTableStmt();
		$$->case_idx_ = CASE2;
		$$->opt_temp_ = $2;
		$$->opt_if_not_exist_ = $4;
		$$->table_name_0_ = $5;
		$$->table_name_1_ = $8;
		$$->opt_typed_table_element_list_ = $9;
		$$->partition_bound_spec_ = $10;
		$$->opt_partition_spec_ = $11;
		$$->table_access_method_clause_ = $12;
		$$->opt_with_replotions_ = $13;
		$$->on_commit_option_ = $14;
		$$->opt_tablespace_ = $15;

		if($$){
			auto tmp1 = $$->table_name_;
			if(tmp1){
				auto tmp2 = tmp1->identifier_;
				if(tmp2){
					tmp2->data_type_ = kDataTableName;
					tmp2->scope_ = 1;
					tmp2->data_flag_ = DATAFLAG::kDefine;
				}
			}
		}
	}
  ;

create_index_stmt:
	CREATE opt_unique INDEX opt_concurrently opt_if_not_exist_index ON opt_only table_name opt_using_method OP_LP indexed_create_index_rest_stmt_list OP_RP opt_include_column_name_list opt_with_index_storage_parameter_list opt_tablespace  opt_where_predicate  {
		$$ = new CreateIndexStmt();
		$$->case_idx_ = CASE0;
		$$->opt_unique_ = $2;
		$$->opt_concurrently_ = $4;
		$$->opt_if_not_exist_index_ = $5;
		$$->opt_only_ = $7;
		$$->table_name_ = $8;
		$$->opt_using_method_ = $9;
		$$->indexed_create_index_rest_stmt_list_ = $11;
		$$->opt_include_column_name_list_ = $13;
		$$->opt_with_index_storage_parameter_list_ = $14;
		$$->opt_tablespace_ = $15;
		$$->opt_where_predicate_ = $16;

		if($$){
			auto tmp1 = $$->opt_if_not_exist_index_;
			if(tmp1){
				auto tmp2 = tmp1->index_name_;
				if(tmp2){
					auto tmp3 = tmp2->identifier_;
					if(tmp3){
						tmp3->data_type_ = kDataIndexName;
						tmp3->scope_ = 2;
						tmp3->data_flag_ = DATAFLAG::kDefine;
					}
				}

			}

		}

		if($$){
			auto tmp1 = $$->table_name_; 
			if(tmp1){
				auto tmp2 = tmp1->identifier_; 
				if(tmp2){
					tmp2->data_type_ = kDataTableName; 
					tmp2->scope_ = 1; 
					if (tmp2->data_flag_ != DATAFLAG::kDefine) {
						tmp2->data_flag_ =DATAFLAG::kUse;
				}
				}
			}
		}


	}
  ;

create_view_stmt:
	CREATE opt_or_replace opt_temp_token opt_recursive VIEW view_name opt_column_name_list_p opt_with_view_option_list AS select_stmt opt_check_option  {
		$$ = new CreateViewStmt();
		$$->case_idx_ = CASE0;
		$$->opt_or_replace_ = $2;
		$$->opt_temp_token_ = $3;
		$$->opt_recursive_ = $4;
		$$->view_name_ = $6;
		$$->opt_column_name_list_p_ = $7;
		$$->opt_with_view_option_list_ = $8;
		$$->select_stmt_ = $10;
		$$->opt_check_option_ = $11;

		if($$){
			auto tmp1 = $$->view_name_; 
			if(tmp1){
				auto tmp2 = tmp1->identifier_; 
				if(tmp2){
					tmp2->data_type_ = kDataTableName; 
					tmp2->scope_ = 10; 
					tmp2->data_flag_ = DATAFLAG::kDefine; 
				}
			}
		}

		if($$){
			auto tmp1 = $$->opt_column_name_list_p_; 
			if(tmp1){
				auto tmp2 = tmp1->column_name_list_; 
				while(tmp2){
					auto tmp3 = tmp2->column_name_; 
					if(tmp3){
						auto tmp4 = tmp3->identifier_; 
						if(tmp4){
							tmp4->data_type_ = kDataColumnName; 
							tmp4->scope_ = 11; 
							tmp4->data_flag_ = DATAFLAG::kDefine; 
						}
					}
					tmp2 = tmp2->column_name_list_;
				}
			}
		}


	}
   |	CREATE opt_or_replace opt_temp_token opt_recursive VIEW view_name opt_column_name_list_p opt_with_view_option_list AS values_stmt opt_check_option  {
		$$ = new CreateViewStmt();
		$$->case_idx_ = CASE1;
		$$->opt_or_replace_ = $2;
		$$->opt_temp_token_ = $3;
		$$->opt_recursive_ = $4;
		$$->view_name_ = $6;
		$$->opt_column_name_list_p_ = $7;
		$$->opt_with_view_option_list_ = $8;
		$$->values_stmt_ = $10;
		$$->opt_check_option_ = $11;

		if($$){
			auto tmp1 = $$->view_name_; 
			if(tmp1){
				auto tmp2 = tmp1->identifier_; 
				if(tmp2){
					tmp2->data_type_ = kDataTableName; 
					tmp2->scope_ = 10; 
					tmp2->data_flag_ = DATAFLAG::kDefine; 
				}
			}
		}

		if($$){
			auto tmp1 = $$->opt_column_name_list_p_; 
			if(tmp1){
				auto tmp2 = tmp1->column_name_list_; 
				while(tmp2){
					auto tmp3 = tmp2->column_name_; 
					if(tmp3){
						auto tmp4 = tmp3->identifier_; 
						if(tmp4){
							tmp4->data_type_ = kDataColumnName; 
							tmp4->scope_ = 11; 
							tmp4->data_flag_ = DATAFLAG::kDefine; 
						}
					}
					tmp2 = tmp2->column_name_list_;
				}
			}
		}


	}
  ;

drop_index_stmt:
	DROP INDEX opt_concurrently opt_if_exist index_name opt_index_name_list opt_cascade_restrict {
		$$ = new DropIndexStmt();
		$$->case_idx_ = CASE0;
		$$->opt_concurrently_ = $3;
		$$->opt_if_exist_ = $4;
		$$->index_name_ = $5;
		$$->opt_index_name_list_ = $6;
		$$->opt_cascade_restrict_ = $7;

		if($$){
			auto tmp1 = $$->index_name_;
			if(tmp1){
				auto tmp2 = tmp1->identifier_; 
				if(tmp2){
					tmp2->data_type_ = kDataIndexName;
					tmp2->scope_ = 1; 
					tmp2->data_flag_ = DATAFLAG::kUndefine; 
				}
			}
		}

		if($$){
			auto tmp1 = $$->opt_index_name_list_;
			if(tmp1){
				auto tmp2 = tmp1->index_name_list_;
				while(tmp2){
					auto tmp3 = tmp2->index_name_;
					if(tmp3){
						auto tmp4 = tmp3->identifier_;
						if (tmp4){
							tmp4->data_type_ = kDataIndexName;
							tmp4->scope_ = 0;
							tmp4->data_flag_ = DATAFLAG::kUndefine;
						}
					}
					tmp2 = tmp2->index_name_list_;
				}

			}
		}

	}
  ;

drop_table_stmt:
	DROP TABLE opt_if_exist table_name_list opt_cascade_restrict  {
		$$ = new DropTableStmt();
		$$->case_idx_ = CASE0;
		$$->opt_if_exist_ = $3;
		$$->table_name_list_ = $4;
		$$->opt_cascade_restrict_ = $5;

		if($$){
			auto tmp1 = $$->table_name_list_;
			while (tmp1) {
				auto tmp2 = tmp1->table_name_;
				if (tmp2) {
					auto tmp3 = tmp2->identifier_;
					if(tmp3){
						tmp3->data_type_ = kDataTableName;
						tmp3->scope_ = 1;
						tmp3->data_flag_ = DATAFLAG::kUndefine;
					}
				}
				tmp1 = tmp1->table_name_list_;
			}
		}
	}
  ;

table_name_list:
	table_name {
		$$ = new TableNameList();
		$$->case_idx_ = CASE0;
		$$->table_name_ = $1;
	}
	| table_name OP_COMMA table_name_list {
		$$ = new TableNameList();
		$$->case_idx_ = CASE1;
		$$->table_name_ = $1;
		$$->table_name_list_ = $3;
	}
;


drop_view_stmt:
	DROP VIEW opt_if_exist view_name_list opt_cascade_restrict  {
		$$ = new DropViewStmt();
		$$->case_idx_ = CASE0;
		$$->opt_if_exist_ = $3;
		$$->view_name_list_ = $4;
		$$->opt_cascade_restrict_ = $5;

		if($$){
			auto tmp1 = $$->view_name_list_;
			while (tmp1) {
				auto tmp2 = tmp1->view_name_;
				if (tmp2) {
					auto tmp3 = tmp2->identifier_;
					if(tmp3){
						tmp3->data_type_ = kDataViewName;
						tmp3->scope_ = 1;
						tmp3->data_flag_ = DATAFLAG::kUndefine;
					}
				}
				tmp1 = tmp1->view_name_list_;
			}
		}
	}
  ;

view_name_list:
	view_name {
		$$ = new ViewNameList();
		$$->case_idx_ = CASE0;
		$$->view_name_ = $1;
	}
	| view_name OP_COMMA view_name_list {
		$$ = new ViewNameList();
		$$->case_idx_ = CASE1;
		$$->view_name_ = $1;
		$$->view_name_list_ = $3;
	}
;



insert_stmt:
	opt_with_clause INSERT INTO insert_target insert_rest opt_on_conflict returning_clause {
		$$ = new InsertStmt();
		$$->case_idx_ = CASE0;
		$$->opt_with_clause_ = $1;
		$$->insert_target_ = $4;
		$$->insert_rest_ = $5;
		$$->opt_on_conflict_ = $6;
		$$->returning_clause_ = $7;

		
	}
  ;

insert_target:
	table_name opt_alias {
		$$ = new InsertTarget();
		$$->case_idx_ = CASE0;
		$$->table_name_ = $1;
		$$->opt_alias_ = $2;

		if($$){
			auto tmp1 = $$->table_name_;
			if(tmp1) {
				auto tmp2 = tmp1->identifier_;
				if(tmp2){
					tmp2->data_type_ = kDataTableName;
					tmp2->scope_ = 1;
					tmp2->data_flag_ = DATAFLAG::kUse;
				}

			}


		}
	}
;



insert_rest:
	insert_query {
		$$ = new InsertRest();
		$$->case_idx_ = CASE0;
		$$->insert_query_ = $1;
	}
	| OVERRIDING override_kind VALUE insert_query {
		$$ = new InsertRest();
		$$->case_idx_ = CASE1;
		$$->override_kind_ = $2;
		$$->insert_query_ = $4;
	}
	| OP_LP column_name_list OP_RP insert_query {
		$$ = new InsertRest();
		$$->case_idx_ = CASE2;
		$$->column_name_list_ = $2;
		$$->insert_query_ = $4;
	}
	| OP_LP column_name_list OP_RP OVERRIDING override_kind VALUE insert_query {
		$$ = new InsertRest();
		$$->case_idx_ = CASE3;
		$$->column_name_list_ = $2;
		$$->override_kind_ = $5;
		$$->insert_query_ = $7;
	}
  ;

insert_query:
	select_stmt {
		$$ = new InsertQuery();
		$$->case_idx_ = CASE0;
		$$->select_stmt_ = $1;
	}
	| values_default_clause {
		$$ = new InsertQuery();
		$$->case_idx_ = CASE1;
		$$->values_default_clause_ = $1;
	}
	| DEFAULT VALUES {
		$$ = new InsertQuery();
		$$->case_idx_ = CASE2;
	}
;


values_default_clause:
	VALUES expr_default_list_with_parens {
		$$ = new ValuesDefaultClause();
		$$->case_idx_ = CASE0;
		$$->expr_default_list_with_parens_ = $2;
	}
;

expr_default_list_with_parens:
	OP_LP expr_default_list OP_RP {
		$$ = new ExprDefaultListWithParens();
		$$->case_idx_ = CASE0;
		$$->expr_default_list_ = $2;
	}
	| OP_LP expr_default_list OP_RP OP_COMMA expr_default_list_with_parens {
		$$ = new ExprDefaultListWithParens();
		$$->case_idx_ = CASE1;
		$$->expr_default_list_ = $2;
		$$->expr_default_list_with_parens_ = $5;
	}
;

expr_default_list:
	expr OP_COMMA expr_default_list  {
		$$ = new ExprDefaultList();
		$$->case_idx_ = CASE0;
		$$->expr_ = $1;
		$$->expr_default_list_ = $3;
	}
	| DEFAULT OP_COMMA expr_default_list {
		$$ = new ExprDefaultList();
		$$->case_idx_ = CASE1;
		$$->expr_default_list_ = $3;
	}
   	| expr  {
		$$ = new ExprDefaultList();
		$$->case_idx_ = CASE2;
		$$->expr_ = $1;
	}
	| DEFAULT {
		$$ = new ExprDefaultList();
		$$->case_idx_ = CASE3;
	}
  ;

override_kind:
	USER {
		$$ = new OverrideKind();
		$$->case_idx_ = CASE0;
	}
	| SYSTEM {
		$$ = new OverrideKind();
		$$->case_idx_ = CASE1;
	}
;


returning_clause:
	RETURNING target_list {
		$$ = new ReturningClause();
		$$->case_idx_ = CASE0;
		$$->target_list_ = $2;
	}
	| RETURNING OP_MUL {
		$$ = new ReturningClause();
		$$->case_idx_ = CASE1;
	}

	| /* empty */ {
		$$ = new ReturningClause();
		$$->case_idx_ = CASE2;
	}
;

target_list:
	target_el {
		$$ = new TargetList();
		$$->case_idx_ = CASE0;
		$$->target_el_ = $1;
	}
	| target_el OP_COMMA target_list {
		$$ = new TargetList();
		$$->case_idx_ = CASE1;
		$$->target_el_ = $1;
		$$->target_list_ = $3;
	}
;

target_el:
	expr AS identifier {
		$$ = new TargetEl();
		$$->case_idx_ = CASE0;
		$$->expr_ = $1;
		$$->identifier_ = $3;

		if($$){
			auto tmp1 = $$->identifier_;
			if(tmp1){
				tmp1->data_type_ = kDataAliasName;
				tmp1->scope_ = 1;
				tmp1->data_flag_ = DATAFLAG::kDefine;
			}
		}
	}
	| expr identifier {
		$$ = new TargetEl();
		$$->case_idx_ = CASE1;
		$$->expr_ = $1;
		$$->identifier_ = $2;

		if($$){
			auto tmp1 = $$->identifier_;
			if(tmp1){
				tmp1->data_type_ = kDataAliasName;
				tmp1->scope_ = 1;
				tmp1->data_flag_ = DATAFLAG::kDefine;
			}
		}
	}
	| expr {
		$$ = new TargetEl();
		$$->case_idx_ = CASE2;
		$$->expr_ = $1;
	}
;

super_values_list:
	values_list  {
		$$ = new SuperValuesList();
		$$->case_idx_ = CASE0;
		$$->values_list_ = $1;
		
	}
   |	values_list OP_COMMA super_values_list  {
		$$ = new SuperValuesList();
		$$->case_idx_ = CASE1;
		$$->values_list_ = $1;
		$$->super_values_list_ = $3;
		
	}
  ;

values_list:
	OP_LP expr_list OP_RP  {
		$$ = new ValuesList();
		$$->case_idx_ = CASE0;
		$$->expr_list_ = $2;
		
	}
  ;

opt_on_conflict:
	ON CONFLICT opt_conflict_expr DO NOTHING  {
		$$ = new OptOnConflict();
		$$->case_idx_ = CASE0;
		$$->opt_conflict_expr_ = $3;
		
	}
   |	ON CONFLICT opt_conflict_expr DO UPDATE SET set_clause_list opt_where_clause  {
		$$ = new OptOnConflict();
		$$->case_idx_ = CASE1;
		$$->opt_conflict_expr_ = $3;
		$$->set_clause_list_ = $7;
		$$->opt_where_clause_ = $8;
		
	}
   |	  {
		$$ = new OptOnConflict();
		$$->case_idx_ = CASE2;
		
	}
  ;

opt_conflict_expr:
	OP_LP indexed_column_list OP_RP opt_where_clause  {
		$$ = new OptConflictExpr();
		$$->case_idx_ = CASE0;
		$$->indexed_column_list_ = $2;
		$$->opt_where_clause_ = $4;
		
	}
   |	  {
		$$ = new OptConflictExpr();
		$$->case_idx_ = CASE1;
		
	}
  ;

indexed_column_list:
	indexed_column  {
		$$ = new IndexedColumnList();
		$$->case_idx_ = CASE0;
		$$->indexed_column_ = $1;
		
	}
   |	indexed_column OP_COMMA indexed_column_list  {
		$$ = new IndexedColumnList();
		$$->case_idx_ = CASE1;
		$$->indexed_column_ = $1;
		$$->indexed_column_list_ = $3;
		
	}
  ;

indexed_column:
	expr opt_order_behavior  {
		$$ = new IndexedColumn();
		$$->case_idx_ = CASE0;
		$$->expr_ = $1;
		$$->opt_order_behavior_ = $2;
		
	}
  ;

update_stmt:
	opt_with_clause UPDATE table_name SET set_clause_list opt_where_clause  {
		$$ = new UpdateStmt();
		$$->case_idx_ = CASE0;
		$$->opt_with_clause_ = $1;
		$$->table_name_ = $3;
		$$->set_clause_list_ = $5;
		$$->opt_where_clause_ = $6;
		
	}
  ;

reindex_stmt:
	REINDEX opt_reindex_option_list INDEX opt_concurrently index_name  {
		$$ = new ReindexStmt();
		$$->case_idx_ = CASE0;
		$$->opt_reindex_option_list_ = $2;
		$$->opt_concurrently_ = $4;
		$$->index_name_ = $5;

		if ($$) {
			auto tmp1 = $$->index_name_;
			if(tmp1){
				auto tmp2 = tmp1->identifier_;
				if(tmp2){
					tmp2->data_type_ = kDataIndexName;
					tmp2->scope_ = 1;
					tmp2->data_flag_ = DATAFLAG::kUse;
				}
			}
		}
		
	}
   	| REINDEX opt_reindex_option_list TABLE opt_concurrently table_name  {
		$$ = new ReindexStmt();
		$$->case_idx_ = CASE1;
		$$->opt_reindex_option_list_ = $2;
		$$->opt_concurrently_ = $4;
		$$->table_name_ = $5;


		if ($$) {
			auto tmp1 = $$->table_name_;
			if(tmp1){
				auto tmp2 = tmp1->identifier_;
				if(tmp2){
					tmp2->data_type_ = kDataTableName;
					tmp2->scope_ = 1;
					tmp2->data_flag_ = DATAFLAG::kUse;
				}
			}
		}
	}
	| REINDEX opt_reindex_option_list SCHEMA opt_concurrently schema_name  {
		$$ = new ReindexStmt();
		$$->case_idx_ = CASE2;
		$$->opt_reindex_option_list_ = $2;
		$$->opt_concurrently_ = $4;
		$$->schema_name_ = $5;

		if ($$) {
			auto tmp1 = $$->schema_name_;
			if(tmp1){
				auto tmp2 = tmp1->identifier_;
				if(tmp2){
					tmp2->data_type_ = kDataSchemaName;
					tmp2->scope_ = 1;
					tmp2->data_flag_ = DATAFLAG::kUse;
				}
			}
		}
	}
	| REINDEX opt_reindex_option_list DATABASE opt_concurrently database_name  {
		$$ = new ReindexStmt();
		$$->case_idx_ = CASE3;
		$$->opt_reindex_option_list_ = $2;
		$$->opt_concurrently_ = $4;
		$$->database_name_ = $5;

		if ($$) {
			auto tmp1 = $$->database_name_;
			if(tmp1){
				auto tmp2 = tmp1->identifier_;
				if(tmp2){
					tmp2->data_type_ = kDataDatabaseName;
					tmp2->scope_ = 1;
					tmp2->data_flag_ = DATAFLAG::kUse;
				}
			}
		}
	}
	| REINDEX opt_reindex_option_list SYSTEM opt_concurrently system_name  {
		$$ = new ReindexStmt();
		$$->case_idx_ = CASE4;
		$$->opt_reindex_option_list_ = $2;
		$$->opt_concurrently_ = $4;
		$$->system_name_ = $5;

		if ($$) {
			auto tmp1 = $$->system_name_;
			if(tmp1){
				auto tmp2 = tmp1->identifier_;
				if(tmp2){
					tmp2->data_type_ = kDataSystemName;
					tmp2->scope_ = 1;
					tmp2->data_flag_ = DATAFLAG::kUse;
				}
			}
		}
	}
  ;
  

opt_reindex_option_list:
	OP_LP reindex_option_list OP_RP {
		$$ = new OptReindexOptionList();
		$$->case_idx_ = CASE0;
		$$->reindex_option_list_ = $2;
	}
	| /* empty */ {
		$$ = new OptReindexOptionList();
		$$->case_idx_ = CASE1;
	}
;

reindex_option_list:
	reindex_option {
		$$ = new ReindexOptionList();
		$$->case_idx_ = CASE0;
		$$->reindex_option_ = $1;
	}
	| reindex_option OP_COMMA reindex_option_list {
		$$ = new ReindexOptionList();
		$$->case_idx_ = CASE1;
		$$->reindex_option_ = $1;
		$$->reindex_option_list_ = $3;
	}
;

reindex_option:
	VERBOSE {
		$$ = new ReindexOption();
        	$$->case_idx_ = CASE0;
	}
	| /* empty */  {
		$$ = new ReindexOption();
		$$->case_idx_ = CASE1;
	}
;

database_name:
	identifier {
		$$ = new DatabaseName();
		$$->case_idx_ = CASE0;
		$$->identifier_ = $1;
	}
;

system_name:
	identifier {
		$$ = new SystemName();
		$$->case_idx_ = CASE0;
		$$->identifier_ = $1;
	}
;



alter_action:
	RENAME TO table_name  {
		$$ = new AlterAction();
		$$->case_idx_ = CASE0;
		$$->table_name_ = $3;
		if($$){
			auto tmp1 = $$->table_name_; 
			if(tmp1){
				auto tmp2 = tmp1->identifier_; 
				if(tmp2){
					tmp2->data_type_ = kDataTableName; 
					tmp2->scope_ = 2; 
					tmp2->data_flag_ = DATAFLAG::kReplace; 
				}
			}
		}


	}
   |	RENAME opt_column column_name TO column_name  {
		$$ = new AlterAction();
		$$->case_idx_ = CASE1;
		$$->opt_column_ = $2;
		$$->column_name_1_ = $3;
		$$->column_name_2_ = $5;
		if($$){
			auto tmp1 = $$->column_name_1_; 
			if(tmp1){
				auto tmp2 = tmp1->identifier_; 
				if(tmp2){
					tmp2->data_type_ = kDataColumnName; 
					tmp2->scope_ = 2; 
					if (tmp2->data_flag_ != DATAFLAG::kDefine) {
						tmp2->data_flag_ =DATAFLAG::kUse; 
					}
				}
			}
		}

		if($$){
			auto tmp1 = $$->column_name_2_; 
			if(tmp1){
				auto tmp2 = tmp1->identifier_; 
				if(tmp2){
					tmp2->data_type_ = kDataColumnName; 
					tmp2->scope_ = 3; 
					tmp2->data_flag_ = DATAFLAG::kReplace; 
				}
			}
		}


	}
   |	ADD opt_column column_def  {
		$$ = new AlterAction();
		$$->case_idx_ = CASE2;
		$$->opt_column_ = $2;
		$$->column_def_ = $3;
		
	}
  ;

column_def_list:
	column_def  {
		$$ = new ColumnDefList();
		$$->case_idx_ = CASE0;
		$$->column_def_ = $1;
		
	}
   |	column_def OP_COMMA column_def_list  {
		$$ = new ColumnDefList();
		$$->case_idx_ = CASE1;
		$$->column_def_ = $1;
		$$->column_def_list_ = $3;
		
	}
  ;

column_def:
	identifier type_name opt_column_constraint_list  {
		$$ = new ColumnDef();
		$$->case_idx_ = CASE0;
		$$->identifier_ = $1;
		$$->type_name_ = $2;
		$$->opt_column_constraint_list_ = $3;
		if($$){
			auto tmp1 = $$->identifier_; 
			if(tmp1){
				tmp1->data_type_ = kDataColumnName; 
				tmp1->scope_ = 2; 
				tmp1->data_flag_ = DATAFLAG::kDefine; 
			}
		}


	}
  ;

opt_column_constraint_list:
	column_constraint_list  {
		$$ = new OptColumnConstraintList();
		$$->case_idx_ = CASE0;
		$$->column_constraint_list_ = $1;
		
	}
   |	  {
		$$ = new OptColumnConstraintList();
		$$->case_idx_ = CASE1;
		
	}
  ;

column_constraint_list:
	column_constraint  {
		$$ = new ColumnConstraintList();
		$$->case_idx_ = CASE0;
		$$->column_constraint_ = $1;
		
	}
   |	column_constraint column_constraint_list  {
		$$ = new ColumnConstraintList();
		$$->case_idx_ = CASE1;
		$$->column_constraint_ = $1;
		$$->column_constraint_list_ = $2;
		
	}
  ;

column_constraint:
	constraint_type  {
		$$ = new ColumnConstraint();
		$$->case_idx_ = CASE0;
		$$->constraint_type_ = $1;
		
	}
  ;

constraint_type:
	PRIMARY KEY  {
		$$ = new ConstraintType();
		$$->case_idx_ = CASE0;
		
	}
   |	NOT NULL  {
		$$ = new ConstraintType();
		$$->case_idx_ = CASE1;
		
	}
   |	UNIQUE  {
		$$ = new ConstraintType();
		$$->case_idx_ = CASE2;
		
	}
   |	CHECK OP_LP expr OP_RP  {
		$$ = new ConstraintType();
		$$->case_idx_ = CASE3;
		$$->expr_ = $3;
		
	}
   |	foreign_clause  {
		$$ = new ConstraintType();
		$$->case_idx_ = CASE4;
		$$->foreign_clause_ = $1;
		
	}
  ;

foreign_clause:
	REFERENCES table_name opt_column_name_list_p opt_foreign_key_actions opt_constraint_attribute_spec  {
		$$ = new ForeignClause();
		$$->case_idx_ = CASE0;
		$$->table_name_ = $2;
		$$->opt_column_name_list_p_ = $3;
		$$->opt_foreign_key_actions_ = $4;
		$$->opt_constraint_attribute_spec_ = $5;
		if($$){
			auto tmp1 = $$->table_name_; 
			if(tmp1){
				auto tmp2 = tmp1->identifier_; 
				if(tmp2){
					tmp2->data_type_ = kDataTableName; 
					tmp2->scope_ = 100; 
					if (tmp2->data_flag_ != DATAFLAG::kDefine) {
						tmp2->data_flag_ =DATAFLAG::kUse; 
					}
				}
			}
		}

		if($$){
			auto tmp1 = $$->opt_column_name_list_p_; 
			if(tmp1){
				auto tmp2 = tmp1->column_name_list_; 
				while(tmp2){
					auto tmp3 = tmp2->column_name_; 
					if(tmp3){
						auto tmp4 = tmp3->identifier_; 
						if(tmp4){
							tmp4->data_type_ = kDataColumnName; 
							tmp4->scope_ = 101; 
							if (tmp4->data_flag_ != DATAFLAG::kDefine) {
								tmp4->data_flag_ =DATAFLAG::kUse; 
							}
						}
					}
					tmp2 = tmp2->column_name_list_;
				}
			}
		}


	}
  ;

opt_foreign_key_actions:
	foreign_key_actions  {
		$$ = new OptForeignKeyActions();
		$$->case_idx_ = CASE0;
		$$->foreign_key_actions_ = $1;
		
	}
   |	  {
		$$ = new OptForeignKeyActions();
		$$->case_idx_ = CASE1;
		
	}
  ;

foreign_key_actions:
	MATCH FULL  {
		$$ = new ForeignKeyActions();
		$$->case_idx_ = CASE0;
		
	}
   |	MATCH PARTIAL  {
		$$ = new ForeignKeyActions();
		$$->case_idx_ = CASE1;
		
	}
   |	MATCH SIMPLE  {
		$$ = new ForeignKeyActions();
		$$->case_idx_ = CASE2;
		
	}
   |	ON UPDATE key_actions  {
		$$ = new ForeignKeyActions();
		$$->case_idx_ = CASE3;
		$$->key_actions_ = $3;
		
	}
   |	ON DELETE key_actions  {
		$$ = new ForeignKeyActions();
		$$->case_idx_ = CASE4;
		$$->key_actions_ = $3;
		
	}
  ;

key_actions:
	SET NULL  {
		$$ = new KeyActions();
		$$->case_idx_ = CASE0;
		
	}
   |	SET DEFAULT  {
		$$ = new KeyActions();
		$$->case_idx_ = CASE1;
		
	}
   |	CASCADE  {
		$$ = new KeyActions();
		$$->case_idx_ = CASE2;
		
	}
   |	RESTRICT  {
		$$ = new KeyActions();
		$$->case_idx_ = CASE3;
		
	}
   |	NO ACTION  {
		$$ = new KeyActions();
		$$->case_idx_ = CASE4;
		
	}
  ;

opt_constraint_attribute_spec:
	DEFFERRABLE opt_initial_time  {
		$$ = new OptConstraintAttributeSpec();
		$$->case_idx_ = CASE0;
		$$->opt_initial_time_ = $2;
		
	}
   |	NOT DEFFERRABLE opt_initial_time  {
		$$ = new OptConstraintAttributeSpec();
		$$->case_idx_ = CASE1;
		$$->opt_initial_time_ = $3;
		
	}
   |	  {
		$$ = new OptConstraintAttributeSpec();
		$$->case_idx_ = CASE2;
		
	}
  ;

opt_initial_time:
	INITIALLY DEFERRED  {
		$$ = new OptInitialTime();
		$$->case_idx_ = CASE0;
		
	}
   |	INITIALLY IMMEDIATE  {
		$$ = new OptInitialTime();
		$$->case_idx_ = CASE1;
		
	}
   |	  {
		$$ = new OptInitialTime();
		$$->case_idx_ = CASE2;
		
	}
  ;

constraint_name:
	CONSTRAINT name  {
		$$ = new ConstraintName();
		$$->case_idx_ = CASE0;
		$$->name_ = $2;
		
	}
  ;

opt_temp:
	TEMPORARY  {
		$$ = new OptTemp();
		$$->case_idx_ = CASE0;
		
	}
   |	TEMP  {
		$$ = new OptTemp();
		$$->case_idx_ = CASE1;
		
	}
   |	LOCAL TEMPORARY  {
		$$ = new OptTemp();
		$$->case_idx_ = CASE2;
		
	}
   |	LOCAL TEMP  {
		$$ = new OptTemp();
		$$->case_idx_ = CASE3;
		
	}
   |	GLOBAL TEMPORARY  {
		$$ = new OptTemp();
		$$->case_idx_ = CASE4;
		
	}
   |	GLOBAL TEMP  {
		$$ = new OptTemp();
		$$->case_idx_ = CASE5;
		
	}
   |	UNLOGGED  {
		$$ = new OptTemp();
		$$->case_idx_ = CASE6;
		
	}
   |	  {
		$$ = new OptTemp();
		$$->case_idx_ = CASE7;
		
	}
  ;

opt_check_option:
	WITH CHECK OPTION  {
		$$ = new OptCheckOption();
		$$->case_idx_ = CASE0;
		
	}
   |	WITH CASCADED CHECK OPTION  {
		$$ = new OptCheckOption();
		$$->case_idx_ = CASE1;
		
	}
   |	WITH LOCAL CHECK OPTION  {
		$$ = new OptCheckOption();
		$$->case_idx_ = CASE2;
		
	}
   |	  {
		$$ = new OptCheckOption();
		$$->case_idx_ = CASE3;
		
	}
  ;

opt_column_name_list_p:
	OP_LP column_name_list OP_RP  {
		$$ = new OptColumnNameListP();
		$$->case_idx_ = CASE0;
		$$->column_name_list_ = $2;
		
	}
   |	  {
		$$ = new OptColumnNameListP();
		$$->case_idx_ = CASE1;
		
	}
  ;

set_clause_list:
	set_clause  {
		$$ = new SetClauseList();
		$$->case_idx_ = CASE0;
		$$->set_clause_ = $1;
		
	}
   |	set_clause OP_COMMA set_clause_list  {
		$$ = new SetClauseList();
		$$->case_idx_ = CASE1;
		$$->set_clause_ = $1;
		$$->set_clause_list_ = $3;
		
	}
  ;

set_clause:
	column_name OP_EQUAL expr  {
		$$ = new SetClause();
		$$->case_idx_ = CASE0;
		$$->column_name_ = $1;
		$$->expr_ = $3;
		
	}
   |	OP_LP column_name_list OP_RP OP_EQUAL expr  {
		$$ = new SetClause();
		$$->case_idx_ = CASE1;
		$$->column_name_list_ = $2;
		$$->expr_ = $5;
		
	}
  ;

expr:
	operand  {
		$$ = new Expr();
		$$->case_idx_ = CASE0;
		$$->operand_ = $1;
		
	}
   |	between_expr  {
		$$ = new Expr();
		$$->case_idx_ = CASE1;
		$$->between_expr_ = $1;
		
	}
   |	exists_expr  {
		$$ = new Expr();
		$$->case_idx_ = CASE2;
		$$->exists_expr_ = $1;
		
	}
   |	in_expr  {
		$$ = new Expr();
		$$->case_idx_ = CASE3;
		$$->in_expr_ = $1;
		
	}
   |	cast_expr opt_alias {
		$$ = new Expr();
		$$->case_idx_ = CASE4;
		$$->cast_expr_ = $1;
		$$->opt_alias_ = $2;
	}
   |	logic_expr  {
		$$ = new Expr();
		$$->case_idx_ = CASE5;
		$$->logic_expr_ = $1;
		
	}
	|	func_expr opt_alias {
		$$ = new Expr();
		$$->case_idx_ = CASE6;
		$$->func_expr_ = $1;
		$$->opt_alias_ = $2;
	}
	// |	identifier opt_alias {
	// 	$$ = new Expr();
	// 	$$->case_idx_ = CASE7;
	// 	$$->identifier_ = $1;
	// 	$$->opt_alias_ = $2;

	// 	if($$){
	// 		auto tmp1 = $$->identifier_; 
	// 		if(tmp1){
	// 			tmp1->data_type_ = kDataColumnName; 
	// 			tmp1->scope_ = 1; 
	// 			if (tmp1->data_flag_ != DATAFLAG::kDefine) {
	// 				tmp1->data_flag_ =DATAFLAG::kUse; 
	// 			}
	// 		}
	// 	}

	// }
  ;

func_expr:
	func_name OP_LP func_args OP_RP {
		$$ = new FuncExpr();
		$$->case_idx_ = CASE0;
		$$ -> func_name_ = $1;
		$$ -> func_args_ = $3;
	}
	;

func_name:
	// Aggregate
	SUM {
		$$ = new FuncName();
		$$->case_idx_ = CASE0;
	}
	// Aggregate
	| COUNT {
		$$ = new FuncName();
		$$->case_idx_ = CASE1;
	}
	| COALESCE {
		$$ = new FuncName();
		$$->case_idx_ = CASE2;
	}
	| ALL {
		$$ = new FuncName();
		$$->case_idx_ = CASE3;
	}
	| ANY {
		$$ = new FuncName();
		$$->case_idx_ = CASE4;
	}
	| SOME {
		$$ = new FuncName();
		$$->case_idx_ = CASE5;
	}
	| LOWER {
		$$ = new FuncName();
		$$->case_idx_ = CASE6;
	}
	// Aggregate
	| MIN {
		$$ = new FuncName();
		$$->case_idx_ = CASE7;
	}
	// Aggregate
	| MAX {
		$$ = new FuncName();
		$$->case_idx_ = CASE8;
	}
	;

func_args:
	expr_list {
		$$ = new FuncArgs();
		$$->case_idx_ = CASE0;
		$$->expr_list_ = $1;
	}
	| OP_MUL %prec OP_MUL {
		$$ = new FuncArgs();
		$$->case_idx_ = CASE1;
	}
	| /* empty */  {
		$$ = new FuncArgs();
		$$->case_idx_ = CASE2;
		$$->string_val_ = "";
	}
	;

opt_alias:
	AS identifier {
		$$ = new OptAlias();
		$$->case_idx_ = CASE0;
		$$->identifier_ = $2;

		if($$){
			auto tmp1 = $$->identifier_; 
			if(tmp1){
				tmp1->data_type_ = kDataAliasName; 
				tmp1->scope_ = 1; 
				tmp1->data_flag_ != DATAFLAG::kDefine;
			}
		}
	}
	|   {
		$$ = new OptAlias();
		$$->case_idx_ = CASE1;
	}
	;

operand:
	OP_LP expr_list OP_RP  {
		$$ = new Operand();
		$$->case_idx_ = CASE0;
		$$->expr_list_ = $2;
		
	}
   |	array_index  {
		$$ = new Operand();
		$$->case_idx_ = CASE1;
		$$->array_index_ = $1;
		
	}
   |	scalar_expr  {
		$$ = new Operand();
		$$->case_idx_ = CASE2;
		$$->scalar_expr_ = $1;
		
	}
   |	unary_expr  {
		$$ = new Operand();
		$$->case_idx_ = CASE3;
		$$->unary_expr_ = $1;
		
	}
   |	binary_expr  {
		$$ = new Operand();
		$$->case_idx_ = CASE4;
		$$->binary_expr_ = $1;
		
	}
   |	case_expr  {
		$$ = new Operand();
		$$->case_idx_ = CASE5;
		$$->case_expr_ = $1;
		
	}
   |	extract_expr  {
		$$ = new Operand();
		$$->case_idx_ = CASE6;
		$$->extract_expr_ = $1;
		
	}
   |	OP_LP select_no_parens OP_RP  {
		$$ = new Operand();
		$$->case_idx_ = CASE7;
		$$->select_no_parens_ = $2;
		
	}
  ;

cast_expr:
	CAST OP_LP expr AS type_name OP_RP  {
		$$ = new CastExpr();
		$$->case_idx_ = CASE0;
		$$->expr_ = $3;
		$$->type_name_ = $5;
		
	}
	| expr DOUBLE_COLON type_name {
		$$ = new CastExpr();
		$$->case_idx_ = CASE1;
		$$->expr_ = $1;
		$$->type_name_ = $3;
	}
  ;

scalar_expr:
	column_name  {
		$$ = new ScalarExpr();
		$$->case_idx_ = CASE0;
		$$->column_name_ = $1;
		
	}
   |	literal  {
		$$ = new ScalarExpr();
		$$->case_idx_ = CASE1;
		$$->literal_ = $1;
		
	}
  ;

unary_expr:
	OP_SUB operand %prec OP_SUB {
		$$ = new UnaryExpr();
		$$->case_idx_ = CASE0;
		$$->operand_ = $2;
		
	}
   |	NOT operand %prec NOT {
		$$ = new UnaryExpr();
		$$->case_idx_ = CASE1;
		$$->operand_ = $2;
		
	}
   |	operand ISNULL %prec ISNULL {
		$$ = new UnaryExpr();
		$$->case_idx_ = CASE2;
		$$->operand_ = $1;
		
	}
   |	operand IS NULL  {
		$$ = new UnaryExpr();
		$$->case_idx_ = CASE3;
		$$->operand_ = $1;
		
	}
   |	operand IS NOT NULL  {
		$$ = new UnaryExpr();
		$$->case_idx_ = CASE4;
		$$->operand_ = $1;
		
	}
   |	NULL  {
		$$ = new UnaryExpr();
		$$->case_idx_ = CASE5;
		
	}
   |	OP_MUL  {
		$$ = new UnaryExpr();
		$$->case_idx_ = CASE6;
		
	}
  ;

binary_expr:
	comp_expr  {
		$$ = new BinaryExpr();
		$$->case_idx_ = CASE0;
		$$->comp_expr_ = $1;
		
	}
   |	operand binary_op operand %prec OP_ADD {
		$$ = new BinaryExpr();
		$$->case_idx_ = CASE1;
		$$->operand_1_ = $1;
		$$->binary_op_ = $2;
		$$->operand_2_ = $3;
		
	}
   |	operand LIKE operand  {
		$$ = new BinaryExpr();
		$$->case_idx_ = CASE2;
		$$->operand_1_ = $1;
		$$->operand_2_ = $3;
		
	}
   |	operand NOT LIKE operand  {
		$$ = new BinaryExpr();
		$$->case_idx_ = CASE3;
		$$->operand_1_ = $1;
		$$->operand_2_ = $4;
		
	}
  ;

logic_expr:
	expr AND expr  {
		$$ = new LogicExpr();
		$$->case_idx_ = CASE0;
		$$->expr_1_ = $1;
		$$->expr_2_ = $3;
		
	}
   |	expr OR expr  {
		$$ = new LogicExpr();
		$$->case_idx_ = CASE1;
		$$->expr_1_ = $1;
		$$->expr_2_ = $3;
		
	}
  ;

in_expr:
	operand opt_not IN OP_LP select_no_parens OP_RP  {
		$$ = new InExpr();
		$$->case_idx_ = CASE0;
		$$->operand_ = $1;
		$$->opt_not_ = $2;
		$$->select_no_parens_ = $5;
		
	}
   |	operand opt_not IN OP_LP expr_list OP_RP  {
		$$ = new InExpr();
		$$->case_idx_ = CASE1;
		$$->operand_ = $1;
		$$->opt_not_ = $2;
		$$->expr_list_ = $5;
		
	}
   |	operand opt_not IN table_name  {
		$$ = new InExpr();
		$$->case_idx_ = CASE2;
		$$->operand_ = $1;
		$$->opt_not_ = $2;
		$$->table_name_ = $4;
		
	}
  ;

case_expr:
	CASE expr case_list END  {
		$$ = new CaseExpr();
		$$->case_idx_ = CASE0;
		$$->expr_1_ = $2;
		$$->case_list_ = $3;
		
	}
   |	CASE case_list END  {
		$$ = new CaseExpr();
		$$->case_idx_ = CASE1;
		$$->case_list_ = $2;
		
	}
   |	CASE expr case_list ELSE expr END  {
		$$ = new CaseExpr();
		$$->case_idx_ = CASE2;
		$$->expr_1_ = $2;
		$$->case_list_ = $3;
		$$->expr_2_ = $5;
		
	}
   |	CASE case_list ELSE expr END  {
		$$ = new CaseExpr();
		$$->case_idx_ = CASE3;
		$$->case_list_ = $2;
		$$->expr_1_ = $4;
		
	}
  ;

between_expr:
	operand BETWEEN operand AND operand %prec BETWEEN {
		$$ = new BetweenExpr();
		$$->case_idx_ = CASE0;
		$$->operand_1_ = $1;
		$$->operand_2_ = $3;
		$$->operand_3_ = $5;
		
	}
   |	operand NOT BETWEEN operand AND operand %prec NOT {
		$$ = new BetweenExpr();
		$$->case_idx_ = CASE1;
		$$->operand_1_ = $1;
		$$->operand_2_ = $4;
		$$->operand_3_ = $6;
		
	}
  ;

exists_expr:
	opt_not EXISTS OP_LP select_no_parens OP_RP  {
		$$ = new ExistsExpr();
		$$->case_idx_ = CASE0;
		$$->opt_not_ = $1;
		$$->select_no_parens_ = $4;
		
	}
  ;

case_list:
	case_clause  {
		$$ = new CaseList();
		$$->case_idx_ = CASE0;
		$$->case_clause_ = $1;
		
	}
   |	case_clause case_list  {
		$$ = new CaseList();
		$$->case_idx_ = CASE1;
		$$->case_clause_ = $1;
		$$->case_list_ = $2;
		
	}
  ;

case_clause:
	WHEN expr THEN expr  {
		$$ = new CaseClause();
		$$->case_idx_ = CASE0;
		$$->expr_1_ = $2;
		$$->expr_2_ = $4;
		
	}
  ;

comp_expr:
	operand OP_EQUAL operand  {
		$$ = new CompExpr();
		$$->case_idx_ = CASE0;
		$$->operand_1_ = $1;
		$$->operand_2_ = $3;
		
	}
   |	operand OP_NOTEQUAL operand  {
		$$ = new CompExpr();
		$$->case_idx_ = CASE1;
		$$->operand_1_ = $1;
		$$->operand_2_ = $3;
		
	}
   |	operand OP_GREATERTHAN operand  {
		$$ = new CompExpr();
		$$->case_idx_ = CASE2;
		$$->operand_1_ = $1;
		$$->operand_2_ = $3;
		
	}
   |	operand OP_LESSTHAN operand  {
		$$ = new CompExpr();
		$$->case_idx_ = CASE3;
		$$->operand_1_ = $1;
		$$->operand_2_ = $3;
		
	}
   |	operand OP_LESSEQ operand  {
		$$ = new CompExpr();
		$$->case_idx_ = CASE4;
		$$->operand_1_ = $1;
		$$->operand_2_ = $3;
		
	}
   |	operand OP_GREATEREQ operand  {
		$$ = new CompExpr();
		$$->case_idx_ = CASE5;
		$$->operand_1_ = $1;
		$$->operand_2_ = $3;
		
	}
  ;

extract_expr:
	EXTRACT OP_LP datetime_field FROM expr OP_RP  {
		$$ = new ExtractExpr();
		$$->case_idx_ = CASE0;
		$$->datetime_field_ = $3;
		$$->expr_ = $5;
		
	}
  ;

datetime_field:
	SECOND  {
		$$ = new DatetimeField();
		$$->case_idx_ = CASE0;
		
	}
   |	MINUTE  {
		$$ = new DatetimeField();
		$$->case_idx_ = CASE1;
		
	}
   |	HOUR  {
		$$ = new DatetimeField();
		$$->case_idx_ = CASE2;
		
	}
   |	DAY  {
		$$ = new DatetimeField();
		$$->case_idx_ = CASE3;
		
	}
   |	MONTH  {
		$$ = new DatetimeField();
		$$->case_idx_ = CASE4;
		
	}
   |	YEAR  {
		$$ = new DatetimeField();
		$$->case_idx_ = CASE5;
		
	}
  ;

array_index:
	operand OP_LBRACKET int_literal OP_RBRACKET  {
		$$ = new ArrayIndex();
		$$->case_idx_ = CASE0;
		$$->operand_ = $1;
		$$->int_literal_ = $3;
		
	}
  ;

literal:
	string_literal  {
		$$ = new Literal();
		$$->case_idx_ = CASE0;
		$$->string_literal_ = $1;
		
	}
   |	bool_literal  {
		$$ = new Literal();
		$$->case_idx_ = CASE1;
		$$->bool_literal_ = $1;
		
	}
   |	num_literal  {
		$$ = new Literal();
		$$->case_idx_ = CASE2;
		$$->num_literal_ = $1;
		
	}
  ;

string_literal:
	STRINGLITERAL  {
		$$ = new StringLiteral();
		$$->string_val_ = $1;
		free($1);
		
	}
  ;

bool_literal:
	TRUE  {
		$$ = new BoolLiteral();
		$$->case_idx_ = CASE0;
		
	}
   |	FALSE  {
		$$ = new BoolLiteral();
		$$->case_idx_ = CASE1;
		
	}
  ;

num_literal:
	int_literal  {
		$$ = new NumLiteral();
		$$->case_idx_ = CASE0;
		$$->int_literal_ = $1;
		
	}
   |	float_literal  {
		$$ = new NumLiteral();
		$$->case_idx_ = CASE1;
		$$->float_literal_ = $1;
		
	}
  ;

int_literal:
	INTLITERAL  {
		$$ = new IntLiteral();
		$$->int_val_ = $1;
		
	}
  ;

float_literal:
	FLOATLITERAL  {
		$$ = new FloatLiteral();
		$$->float_val_ = $1;
		
	}
  ;

opt_column:
	COLUMN  {
		$$ = new OptColumn();
		$$->case_idx_ = CASE0;
		
	}
   |	  {
		$$ = new OptColumn();
		$$->case_idx_ = CASE1;
		
	}
  ;

opt_if_not_exist:
	IF NOT EXISTS  {
		$$ = new OptIfNotExist();
		$$->case_idx_ = CASE0;
		
	}
   |	  {
		$$ = new OptIfNotExist();
		$$->case_idx_ = CASE1;
		
	}
  ;

opt_if_exist:
	IF EXISTS  {
		$$ = new OptIfExist();
		$$->case_idx_ = CASE0;
		
	}
   |	  {
		$$ = new OptIfExist();
		$$->case_idx_ = CASE1;
		
	}
  ;

identifier:
	IDENTIFIER  {
		$$ = new Identifier();
		$$->string_val_ = $1;
		free($1);
		
	}
  ;

table_name:
	identifier  {
		$$ = new TableName();
		$$->case_idx_ = CASE0;
		$$->identifier_ = $1;
		if($$){
			auto tmp1 = $$->identifier_; 
			if(tmp1){
				tmp1->data_type_ = kDataTableName; 
				tmp1->scope_ = 1; 
				if (tmp1->data_flag_ != DATAFLAG::kDefine) {
					tmp1->data_flag_ =DATAFLAG::kUse; 
				}
			}
		}
	}
  ;

column_name:
	identifier  {
		$$ = new ColumnName();
		$$->case_idx_ = CASE0;
		$$->identifier_ = $1;
		if($$){
			auto tmp1 = $$->identifier_; 
			if(tmp1){
				tmp1->data_type_ = kDataColumnName; 
				tmp1->scope_ = 2; 
				if (tmp1->data_flag_ != DATAFLAG::kDefine) {
					tmp1->data_flag_ =DATAFLAG::kUse; 
				}
			}
		}


	}
  ;

opt_unique:
	UNIQUE  {
		$$ = new OptUnique();
		$$->case_idx_ = CASE0;
		
	}
   |	  {
		$$ = new OptUnique();
		$$->case_idx_ = CASE1;
		
	}
  ;

view_name:
	identifier  {
		$$ = new ViewName();
		$$->case_idx_ = CASE0;
		$$->identifier_ = $1;
		
	}
  ;

index_name:
	identifier  {
		$$ = new IndexName();
		$$->case_idx_ = CASE0;
		$$->identifier_ = $1;
		
	}
  ;

tablespace_name:
	identifier {
		$$ = new TablespaceName();
		$$->case_idx_ = CASE0;
		$$->identifier_ = $1;
	}

role_name:
	identifier {
		$$ = new RoleName();
		$$->case_idx_ = CASE0;
		$$->identifier_ = $1;
	}

extension_name:
	identifier {
		$$ = new ExtensionName();
		$$->case_idx_ = CASE0;
		$$->identifier_ = $1;
	}

binary_op:
	OP_ADD  {
		$$ = new BinaryOp();
		$$->case_idx_ = CASE0;
		
	}
   |	OP_SUB  {
		$$ = new BinaryOp();
		$$->case_idx_ = CASE1;
		
	}
   |	OP_DIVIDE  {
		$$ = new BinaryOp();
		$$->case_idx_ = CASE2;
		
	}
   |	OP_MOD  {
		$$ = new BinaryOp();
		$$->case_idx_ = CASE3;
		
	}
   |	OP_MUL  {
		$$ = new BinaryOp();
		$$->case_idx_ = CASE4;
		
	}
  ;

opt_not:
	NOT  {
		$$ = new OptNot();
		$$->case_idx_ = CASE0;
		
	}
   |	  {
		$$ = new OptNot();
		$$->case_idx_ = CASE1;
		
	}
  ;

name:
	identifier  {
		$$ = new Name();
		$$->case_idx_ = CASE0;
		$$->identifier_ = $1;
		
	}
  ;

type_name:
	numeric_type  {
		$$ = new TypeName();
		$$->case_idx_ = CASE0;
		$$->numeric_type_ = $1;

	}
   |	character_type  {
		$$ = new TypeName();
		$$->case_idx_ = CASE1;
		$$->character_type_ = $1;
		
	}
  ;

character_type:
	character_with_length  {
		$$ = new CharacterType();
		$$->case_idx_ = CASE0;
		$$->character_with_length_ = $1;
		
	}
   |	character_without_length  {
		$$ = new CharacterType();
		$$->case_idx_ = CASE1;
		$$->character_without_length_ = $1;
		
	}
  ;

character_with_length:
	character_conflicta OP_LP int_literal OP_RP  {
		$$ = new CharacterWithLength();
		$$->case_idx_ = CASE0;
		$$->character_conflicta_ = $1;
		$$->int_literal_ = $3;
		
	}
  ;

character_without_length:
	character_conflicta  {
		$$ = new CharacterWithoutLength();
		$$->case_idx_ = CASE0;
		$$->character_conflicta_ = $1;
		
	}
  ;

character_conflicta:
	CHARACTER opt_varying  {
		$$ = new CharacterConflicta();
		$$->case_idx_ = CASE0;
		$$->opt_varying_ = $2;
		
	}
   |	CHAR opt_varying  {
		$$ = new CharacterConflicta();
		$$->case_idx_ = CASE1;
		$$->opt_varying_ = $2;
		
	}
   |	VARCHAR  {
		$$ = new CharacterConflicta();
		$$->case_idx_ = CASE2;
		
	}
   |	TEXT  {
		$$ = new CharacterConflicta();
		$$->case_idx_ = CASE3;
		
	}
   |	NATIONAL CHARACTER opt_varying  {
		$$ = new CharacterConflicta();
		$$->case_idx_ = CASE4;
		$$->opt_varying_ = $3;
		
	}
   |	NATIONAL CHAR opt_varying  {
		$$ = new CharacterConflicta();
		$$->case_idx_ = CASE5;
		$$->opt_varying_ = $3;
		
	}
   |	NCHAR opt_varying  {
		$$ = new CharacterConflicta();
		$$->case_idx_ = CASE6;
		$$->opt_varying_ = $2;
		
	}
	|	VARCHAR OP_LP int_literal OP_RP  {
		$$ = new CharacterConflicta();
		$$->case_idx_ = CASE7;
		$$->int_literal_ = $3;
		
	}
  ;

opt_varying:
	VARYING  {
		$$ = new OptVarying();
		$$->case_idx_ = CASE0;
		
	}
   |	  {
		$$ = new OptVarying();
		$$->case_idx_ = CASE1;
		
	}
  ;

numeric_type:
	INT  {
		$$ = new NumericType();
		$$->case_idx_ = CASE0;
		
	}
   |	INTEGER  {
		$$ = new NumericType();
		$$->case_idx_ = CASE1;
		
	}
   |	SMALLINT  {
		$$ = new NumericType();
		$$->case_idx_ = CASE2;
		
	}
   |	BIGINT  {
		$$ = new NumericType();
		$$->case_idx_ = CASE3;
		
	}
   |	REAL  {
		$$ = new NumericType();
		$$->case_idx_ = CASE4;
		
	}
   |	FLOAT  {
		$$ = new NumericType();
		$$->case_idx_ = CASE5;
		
	}
   |	DOUBLE PRECISION  {
		$$ = new NumericType();
		$$->case_idx_ = CASE6;
		
	}
   |	DECIMAL  {
		$$ = new NumericType();
		$$->case_idx_ = CASE7;
		
	}
   |	DEC  {
		$$ = new NumericType();
		$$->case_idx_ = CASE8;
		
	}
   |	NUMERIC  {
		$$ = new NumericType();
		$$->case_idx_ = CASE9;
		
	}
   |	BOOLEAN  {
		$$ = new NumericType();
		$$->case_idx_ = CASE10;
		
	}
  ;

opt_table_constraint_list:
	table_constraint_list  {
		$$ = new OptTableConstraintList();
		$$->case_idx_ = CASE0;
		$$->table_constraint_list_ = $1;
		
	}
   |	  {
		$$ = new OptTableConstraintList();
		$$->case_idx_ = CASE1;
		
	}
  ;

table_constraint_list:
	table_constraint  {
		$$ = new TableConstraintList();
		$$->case_idx_ = CASE0;
		$$->table_constraint_ = $1;
		
	}
   |	table_constraint OP_COMMA table_constraint_list  {
		$$ = new TableConstraintList();
		$$->case_idx_ = CASE1;
		$$->table_constraint_ = $1;
		$$->table_constraint_list_ = $3;
		
	}
  ;

table_constraint:
	constraint_name PRIMARY KEY OP_LP indexed_column_list OP_RP  {
		$$ = new TableConstraint();
		$$->case_idx_ = CASE0;
		$$->constraint_name_ = $1;
		$$->indexed_column_list_ = $5;
		
	}
   |	constraint_name UNIQUE OP_LP indexed_column_list OP_RP  {
		$$ = new TableConstraint();
		$$->case_idx_ = CASE1;
		$$->constraint_name_ = $1;
		$$->indexed_column_list_ = $4;
		
	}
   |	constraint_name CHECK OP_LP expr OP_RP  {
		$$ = new TableConstraint();
		$$->case_idx_ = CASE2;
		$$->constraint_name_ = $1;
		$$->expr_ = $4;
		
	}
   |	constraint_name FOREIGN KEY OP_LP column_name_list OP_RP foreign_clause  {
		$$ = new TableConstraint();
		$$->case_idx_ = CASE3;
		$$->constraint_name_ = $1;
		$$->column_name_list_ = $5;
		$$->foreign_clause_ = $7;
		if($$){
			auto tmp1 = $$->column_name_list_; 
			while(tmp1){
				auto tmp2 = tmp1->column_name_; 
				if(tmp2){
					auto tmp3 = tmp2->identifier_; 
					if(tmp3){
						tmp3->data_type_ = kDataColumnName; 
						tmp3->scope_ = 2; 
						if (tmp3->data_flag_ != DATAFLAG::kDefine) {
							tmp3->data_flag_ =DATAFLAG::kUse; 
						}
					}
				}
				tmp1 = tmp1->column_name_list_;
			}
		}


	}
  ;

opt_no:
	NO {
		$$ = new OptNo();
		$$->case_idx_ = CASE0;
	}
	| /* empty */ {
		$$ = new OptNo();
		$$->case_idx_ = CASE1;
	}
	;


opt_nowait:
	NOWAIT {
		$$ = new OptNowait();
		$$->case_idx_ = CASE0;
	}
	| /* empty */ {
		$$ = new OptNowait();
		$$->case_idx_ = CASE1;
	}
	;

opt_owned_by:
	OWNED BY role_name {
		$$ = new OptOwnedby();
		$$->case_idx_ = CASE0;
		$$->role_name_ = $3;
	}
	| /* empty */ {
		$$ = new OptOwnedby();
		$$->case_idx_ = CASE1;
	}
	;

on_off_literal:
	ON {
		$$ = new OnOffLiteral();
		$$->case_idx_ = CASE0;
	}
	| OFF {
		$$ = new OnOffLiteral();
		$$->case_idx_ = CASE1;
	}
	;

opt_concurrently:
	CONCURRENTLY {
		$$ = new OptConcurrently();
		$$->case_idx_ = CASE0;
	}
	| /* empty */ {
		$$ = new OptConcurrently();
		$$->case_idx_ = CASE1;
	}
	;


opt_if_not_exist_index:
	opt_if_not_exist index_name {
		$$ = new OptIfNotExistIndex();
		$$->case_idx_ = CASE0;
		$$->opt_if_not_exist_ = $1;
		$$->index_name_ = $2;
	}
	| /* empty */ {
		$$ = new OptIfNotExistIndex();
		$$->case_idx_ = CASE1;
	}
;

opt_only:
	ONLY {
		$$ = new OptOnly();
		$$->case_idx_ = CASE0;
	}
	| /* empty */ {
		$$ = new OptOnly();
		$$->case_idx_ = CASE1;
	}
;

opt_using_method:
	USING method_name {
		$$ = new OptUsingMethod();
		$$->case_idx_ = CASE0;
		$$->method_name_ = $2;
	}
	| /* empty */ {
		$$ = new OptUsingMethod();
		$$->case_idx_ = CASE1;
	}
;

method_name:
	identifier  {
		$$ = new MethodName();
		$$->case_idx_ = CASE0;
		$$->identifier_ = $1;

	}
;


opt_tablespace:
	TABLESPACE tablespace_name {
		$$ = new OptTablespace();
        	$$->case_idx_ = CASE0;
        	$$->tablespace_name_ = $2;
	}
	| /* empty */ {
		$$ = new OptTablespace();
		$$->case_idx_ = CASE1;
	}
;

opt_where_predicate:
	WHERE predicate_name {
		$$ = new OptWherePredicate();
        	$$->case_idx_ = CASE0;
        	$$->predicate_name_ = $2;
	}
	| /* empty */ {
		$$ = new OptWherePredicate();
		$$->case_idx_ = CASE1;
	}
;

predicate_name:
	identifier  {
		$$ = new PredicateName();
		$$->case_idx_ = CASE0;
		$$->identifier_ = $1;

	}
;


opt_with_index_storage_parameter_list:
	WITH OP_LP index_storage_parameter_list OP_RP {
		$$ = new OptWithIndexStorageParameterList();
		$$->case_idx_ = CASE0;
		$$->index_storage_parameter_list_ = $3;
	}
	| /* empty */ {
		$$ = new OptWithIndexStorageParameterList();
		$$->case_idx_ = CASE1;
	}
;

opt_include_column_name_list:
	INCLUDE OP_LP column_name_list OP_RP {
		$$ = new OptIncludeColumnNameList();
		$$->case_idx_ = CASE0;
		$$->column_name_list_ = $3;
	}
	| /* empty */ {
		$$ = new OptIncludeColumnNameList();
		$$->case_idx_ = CASE1;
	}
;


opt_collate:
	COLLATE collation_name {
		$$ = new OptCollate();
        	$$->case_idx_ = CASE0;
        	$$->collation_name_ = $2;
	}
	| /* empty */ {
		$$ = new OptCollate();
		$$->case_idx_ = CASE1;
	}
;

collation_name:
	identifier  {
		$$ = new CollationName();
		$$->case_idx_ = CASE0;
		$$->identifier_ = $1;
	}
;

opt_column_or_expr:
	column_name {
		$$ = new OptColumnOrExpr();
		$$->case_idx_ = CASE0;
		$$->column_name_ = $1;
	}
	| OP_LP expr OP_RP {
		$$ = new OptColumnOrExpr();
		$$->case_idx_ = CASE1;
		$$->expr_ = $2;
	}
	| /* empty */ {
		$$ = new OptColumnOrExpr();
		$$->case_idx_ = CASE2;
	}
;

indexed_create_index_rest_stmt_list:
	create_index_rest_stmt {
		$$ = new IndexedCreateIndexRestStmtList();
		$$->case_idx_ = CASE0;
		$$->create_index_rest_stmt_ = $1;

	}
	| create_index_rest_stmt OP_COMMA indexed_create_index_rest_stmt_list  {
		$$ = new IndexedCreateIndexRestStmtList();
		$$->case_idx_ = CASE1;
		$$->create_index_rest_stmt_ = $1;
		$$->indexed_create_index_rest_stmt_list_ = $3;

	}
  ;

create_index_rest_stmt:
	opt_column_or_expr opt_collate opt_index_opclass_parameter_list opt_order_behavior opt_order_nulls {
		$$ = new CreateIndexRestStmt();
		$$->case_idx_ = CASE0;
		$$->opt_column_or_expr_ = $1;
		$$->opt_collate_ = $2;
		$$->opt_index_opclass_parameter_list_ = $3;
		$$->opt_order_behavior_ = $4;
		$$->opt_order_nulls_ = $5;
	}
;


opt_index_opclass_parameter_list:
	opclass_name opt_opclass_parameter_list {
		$$ = new OptIndexOpclassParameterList();
        	$$->case_idx_ = CASE0;
        	$$->opclass_name_ = $1;
        	$$->opt_opclass_parameter_list_ = $2;
	}
	| /* empty */ {
		$$ = new OptIndexOpclassParameterList();
		$$->case_idx_ = CASE1;
	}
;

opclass_name:
	identifier  {
		$$ = new OpclassName();
		$$->case_idx_ = CASE0;
		$$->identifier_ = $1;

	}
;


opt_opclass_parameter_list:
	OP_LP index_opclass_parameter_list OP_RP {
		$$ = new OptOpclassParameterList();
                $$->case_idx_ = CASE0;
                $$->index_opclass_parameter_list_ = $2;
	}
	| /* empty */ {
		$$ = new OptOpclassParameterList();
		$$->case_idx_ = CASE1;
	}
;



index_opclass_parameter_list:
	index_opclass_parameter  {
		$$ = new IndexOpclassParameterList();
		$$->case_idx_ = CASE0;
		$$->index_opclass_parameter_ = $1;
	}
   |	index_opclass_parameter OP_COMMA index_opclass_parameter_list  {
		$$ = new IndexOpclassParameterList();
		$$->case_idx_ = CASE1;
		$$->index_opclass_parameter_ = $1;
		$$->index_opclass_parameter_list_  = $3;
	}
  ;

index_opclass_parameter:
	opclass_parameter_name OP_EQUAL opclass_parameter_value {
		$$ = new IndexOpclassParameter();
		$$->case_idx_ = CASE0;
		$$->opclass_parameter_name_ = $1;
		$$->opclass_parameter_value_ = $3;
	}
;


opclass_parameter_name:
	identifier  {
		$$ = new OpclassParameterName();
		$$->case_idx_ = CASE0;
		$$->identifier_ = $1;

	}
;


opclass_parameter_value:
	identifier  {
		$$ = new OpclassParameterValue();
		$$->case_idx_ = CASE0;
		$$->identifier_ = $1;

	}
;

opt_index_name_list:
	index_name_list {
		$$ = new OptIndexNameList();
        	$$->case_idx_ = CASE0;
        	$$->index_name_list_ = $1;
	}
	| /* empty */ {
		$$ = new OptIndexNameList();
		$$->case_idx_ = CASE1;
	}
;

index_name_list:
	OP_COMMA index_name {
		$$ = new IndexNameList();
        	$$->case_idx_ = CASE0;
        	$$->index_name_ = $2;
	}
	| index_name_list OP_COMMA index_name  {
		$$ = new IndexNameList();
        	$$->case_idx_ = CASE0;
        	$$->index_name_ = $3;
        	$$->index_name_list_ = $1;
	}
;

opt_cascade_restrict:
	CASCADE {
		$$ = new OptCascadeRestrict();
        	$$->case_idx_ = CASE0;
	}
	| RESTRICT {
		$$ = new OptCascadeRestrict();
		$$->case_idx_ = CASE1;
	}
	| /* empty */ {
		$$ = new OptCascadeRestrict();
		$$->case_idx_ = CASE2;
	}
;

role_specification:
	role_name {
		$$ = new RoleSpecification();
		$$->case_idx_ = CASE0;
		$$->role_name_ = $1;
	}
	| CURRENT_USER {
		$$ = new RoleSpecification();
		$$->case_idx_ = CASE1;
	}
	| SESSION_USER {
		$$ = new RoleSpecification();
		$$->case_idx_ = CASE2;
	}
;

user_name:
	identifier {
		$$ = new UserName();
		$$->case_idx_ = CASE0;
		$$->identifier_ = $1;
	}
;


user_name_list:
	user_name {
		$$ = new UserNameList();
		$$->case_idx_ = CASE0;
		$$->user_name_ = $1;
	}
	| user_name OP_COMMA user_name_list {
		$$ = new UserNameList();
		$$->case_idx_ = CASE1;
		$$->user_name_ = $1;
		$$->user_name_list_ = $3;
	}
;

group_name:
	identifier {
		$$ = new GroupName();
		$$->case_idx_ = CASE0;
		$$->identifier_ = $1;
	}
;

drop_group_stmt:
	DROP GROUP opt_if_exist group_name_list {
		$$ = new DropGroupStmt();
		$$->case_idx_ = CASE0;
		$$->opt_if_exist_ = $3;
		$$->group_name_list_ = $4;

		if($$){
			auto tmp1 = $$->group_name_list_;
			while (tmp1) {
				auto tmp2 = tmp1->group_name_;
				if(tmp2){
					auto tmp3 = tmp2->identifier_;
					if (tmp3) {
						tmp3->data_type_ = kDataGroupName;
						tmp3->scope_ = 0;
						tmp3->data_flag_ =DATAFLAG::kUndefine;
					}
				}
				tmp1 = tmp1->group_name_list_;
			}
		}

	}
;

group_name_list:
	group_name {
		$$ = new GroupNameList();
		$$->case_idx_ = CASE0;
		$$->group_name_ = $1;
	}
	| group_name OP_COMMA group_name_list {
		$$ = new GroupNameList();
		$$->case_idx_ = CASE1;
		$$->group_name_ = $1;
		$$->group_name_list_ = $3;
	}
;

values_stmt:
	VALUES expr_list_with_parens {
		$$ = new ValuesStmt();
		$$->case_idx_ = CASE0;
		$$->expr_list_with_parens_ = $2;
	}
;

expr_list_with_parens:
	OP_LP expr_list OP_RP {
		$$ = new ExprListWithParens();
		$$->case_idx_ = CASE0;
		$$->expr_list_ = $2;
	}
	| OP_LP expr_list OP_RP OP_COMMA expr_list_with_parens {
		$$ = new ExprListWithParens();
		$$->case_idx_ = CASE1;
		$$->expr_list_ = $2;
		$$->expr_list_with_parens_ = $5;
	}
;

alter_view_stmt:
	ALTER VIEW opt_if_exist view_name alter_view_action {
		$$ = new AlterViewStmt();
		$$->case_idx_ = CASE0;
		$$->opt_if_exist_ = $3;
		$$->view_name_ = $4;
		$$->alter_view_action_ = $5;

		if($$){
			auto tmp1 = $$->view_name_;
			if(tmp1){
				auto tmp2 = tmp1->identifier_;
				if(tmp2){
					tmp2->data_type_ = kDataViewName;
					tmp2->scope_ = 0;
					tmp2->data_flag_ =DATAFLAG::kUse;
				}

			}
		}
	}

alter_view_action:
	ALTER opt_column column_name SET DEFAULT expr {
		$$ = new AlterViewAction();
		$$->case_idx_ = CASE0;
		$$->opt_column_ = $2;
		$$->column_name_ = $3;
		$$->expr_ = $6;

		if($$){
			auto tmp1 = $$->column_name_;
			if(tmp1){
				auto tmp2 = tmp1->identifier_;
				if(tmp2){
					tmp2->data_type_ = kDataColumnName;
					tmp2->scope_ = 0;
					tmp2->data_flag_ =DATAFLAG::kUse;
				}

			}
		}
	}
	| ALTER opt_column column_name DROP DEFAULT {
		$$ = new AlterViewAction();
		$$->case_idx_ = CASE1;
		$$->opt_column_ = $2;
		$$->column_name_ = $3;

		if($$){
			auto tmp1 = $$->column_name_;
			if(tmp1){
				auto tmp2 = tmp1->identifier_;
				if(tmp2){
					tmp2->data_type_ = kDataColumnName;
					tmp2->scope_ = 0;
					tmp2->data_flag_ =DATAFLAG::kUse;
				}

			}
		}
	}
	| OWNER TO owner_specification {
		$$ = new AlterViewAction();
		$$->case_idx_ = CASE2;
		$$->owner_specification_ = $3;
	}
	| RENAME opt_column column_name TO column_name {
		$$ = new AlterViewAction();
		$$->case_idx_ = CASE3;
		$$->opt_column_ = $2;
		$$->column_name_0_ = $3;
		$$->column_name_1_ = $5;

		if($$){
			auto tmp1 = $$->column_name_0_;
			if(tmp1){
				auto tmp2 = tmp1->identifier_;
				if(tmp2){
					tmp2->data_type_ = kDataColumnName;
					tmp2->scope_ = 0;
					tmp2->data_flag_ =DATAFLAG::kUndefine;
				}
			}

			auto tmp3 = $$->column_name_1_;
			if(tmp3){
				auto tmp4 = tmp3->identifier_;
				if(tmp4){
					tmp4->data_type_ = kDataColumnName;
					tmp4->scope_ = 0;
					tmp4->data_flag_ =DATAFLAG::kDefine;
				}
			}
		}
	}
	| RENAME TO view_name {
		$$ = new AlterViewAction();
		$$->case_idx_ = CASE4;
		$$->view_name_ = $3;

		if($$){
			auto tmp1 = $$->view_name_;
			if(tmp1){
				auto tmp2 = tmp1->identifier_;
				if(tmp2){
					tmp2->data_type_ = kDataViewName;
					tmp2->scope_ = 0;
					tmp2->data_flag_ =DATAFLAG::kDefine;
				}
//			FIXME: how to change the data_flag_ of first view_name to kUndefine?
			}
		}
	}
	| SET SCHEMA schema_name {
		$$ = new AlterViewAction();
		$$->case_idx_ = CASE5;
		$$->schema_name_ = $3;

		if($$){
			auto tmp1 = $$->schema_name_;
			if(tmp1){
				auto tmp2 = tmp1->identifier_;
				if(tmp2){
					tmp2->data_type_ = kDataSchemaName;
					tmp2->scope_ = 0;
					tmp2->data_flag_ =DATAFLAG::kDefine;
				}

			}
		}
	}
	| SET OP_LP index_opt_view_option_list OP_RP {
		$$ = new AlterViewAction();
		$$->case_idx_ = CASE6;
		$$->index_opt_view_option_list_ = $3;		
	}
	| RESET OP_LP view_option_name_list OP_RP {
		$$ = new AlterViewAction();
		$$->case_idx_ = CASE7;
		$$->view_option_name_list_ = $3;
	}
;


owner_specification:
	user_name {
		$$ = new OwnerSpecification();
		$$->case_idx_ = CASE0;
		$$->user_name_ = $1;
	}
	| CURRENT_USER {
		$$ = new OwnerSpecification();
		$$->case_idx_ = CASE1;
	}
	| SESSION_USER {
		$$ = new OwnerSpecification();
		$$->case_idx_ = CASE2;
	}
;

schema_name:
	identifier {
		$$ = new SchemaName();
		$$->case_idx_ = CASE0;
		$$->identifier_ = $1;
	}
;


index_opt_view_option_list:
	index_opt_view_option {
		$$ = new IndexOptViewOptionList();
		$$->case_idx_ = CASE0;
		$$->index_opt_view_option_ = $1;
	}
	| index_opt_view_option OP_COMMA index_opt_view_option_list {
		$$ = new IndexOptViewOptionList();
		$$->case_idx_ = CASE1;
		$$->index_opt_view_option_ = $1;
		$$->index_opt_view_option_list_ = $3;
	}
;


index_opt_view_option:
	view_option_name opt_equal_view_option_value {
		$$ = new IndexOptViewOption();
		$$->case_idx_ = CASE0;
		$$->view_option_name_ = $1;
		$$->opt_equal_view_option_value_ = $2;
	}
;

opt_equal_view_option_value:
	OP_EQUAL view_option_value {
		$$ = new OptEqualViewOptionValue();
		$$->case_idx_ = CASE0;
		$$->view_option_value_ = $2;
	}
	| /* empty */ {
		$$ = new OptEqualViewOptionValue();
		$$->case_idx_ = CASE1;
	}
;

view_option_name:
	identifier {
		$$ = new ViewOptionName();
		$$->case_idx_ = CASE0;
		$$->identifier_ = $1;
	}
;


view_option_value:
	identifier {
		$$ = new ViewOptionValue();
		$$->case_idx_ = CASE0;
		$$->identifier_ = $1;
	}
;


view_option_name_list:
	view_option_name {
		$$ = new ViewOptionNameList();
		$$->case_idx_ = CASE0;
		$$->view_option_name_ = $1;
	}
	| view_option_name OP_COMMA view_option_name_list {
		$$ = new ViewOptionNameList();
		$$->case_idx_ = CASE1;
		$$->view_option_name_ = $1;
		$$->view_option_name_list_ = $3;
	}
;

create_group_stmt:
	CREATE GROUP group_name opt_with_option_list {
		$$ = new CreateGroupStmt();
		$$->case_idx_ = CASE0;
		$$->group_name_ = $3;
		$$->opt_with_option_list_ = $4;

		if($$){
			auto tmp1 = $$->group_name_;
			if(tmp1){
				auto tmp2 = tmp1->identifier_;
				if(tmp2){
					tmp2->data_type_ = kDataGroupName;
					tmp2->scope_ = 0;
					tmp2->data_flag_ =DATAFLAG::kDefine;
				}

			}
		}
	}
;



opt_with_option_list:
    opt_with option_list {
        $$ = new OptWithOptionList();
        $$->case_idx_ = CASE0;
        $$->opt_with_ = $1;
        $$->option_list_ = $2;
	}
    | /* empty */ {
        $$ = new OptWithOptionList();
        $$->case_idx_ = CASE1;
	}
;

opt_with:
	WITH {
		$$ = new OptWith();
        	$$->case_idx_ = CASE0;
	}
	| /* empty */ {
		$$ = new OptWith();
		$$->case_idx_ = CASE1;
	}
;



option_list:
    option {
        $$ = new OptionList();
        $$->case_idx_ = CASE0;
        $$->option_ = $1;
    }
    | option option_list {
        $$ = new OptionList();
        $$->case_idx_ = CASE1;
        $$->option_ = $1;
        $$->option_list_ = $2;
    }
;


option:
    SUPERUSER {
	$$ = new Option();
	$$->case_idx_ = CASE0;
    }
    | NOSUPERUSER {
	$$ = new Option();
	$$->case_idx_ = CASE1;
    }
    | CREATEDB {
	$$ = new Option();
	$$->case_idx_ = CASE2;
    }
    | NOCREATEDB {
	$$ = new Option();
	$$->case_idx_ = CASE3;
    }
    | CREATEROLE {
	$$ = new Option();
	$$->case_idx_ = CASE4;
    }
    | NOCREATEROLE {
	$$ = new Option();
	$$->case_idx_ = CASE5;
    }
    | INHERIT {
	$$ = new Option();
	$$->case_idx_ = CASE6;
    }
    | NOINHERIT {
	$$ = new Option();
	$$->case_idx_ = CASE7;
    }
    | LOGIN {
	$$ = new Option();
	$$->case_idx_ = CASE8;
    }
    | NOLOGIN {
	$$ = new Option();
	$$->case_idx_ = CASE9;
    }
    | REPLICATION {
	$$ = new Option();
	$$->case_idx_ = CASE10;
    }
    | NOREPLICATION {
	$$ = new Option();
	$$->case_idx_ = CASE11;
    }
    | BYPASSRLS {
	$$ = new Option();
	$$->case_idx_ = CASE12;
    }
    | NOBYPASSRLS {
	$$ = new Option();
	$$->case_idx_ = CASE13;
    }
    | CONNECTION LIMIT int_literal {
	$$ = new Option();
	$$->case_idx_ = CASE14;
	$$->int_literal_ = $3;
    }
    | opt_encrypted PASSWORD string_literal {
	$$ = new Option();
	$$->case_idx_ = CASE15;
	$$->opt_encrypted_ = $1;
	$$->string_literal_ = $3;
    }
    | PASSWORD NULL {
	$$ = new Option();
	$$->case_idx_ = CASE16;
    }
    | VALID UNTIL string_literal {
    	$$ = new Option();
    	$$->case_idx_ = CASE17;
    	$$->string_literal_ = $3;
    }
    | IN ROLE role_name_list {
    	$$ = new Option();
    	$$->case_idx_ = CASE18;
    	$$->role_name_list_ = $3;

    	if($$){
		auto tmp1 = $$->role_name_list_;
		while(tmp1){
			auto tmp2 = tmp1->role_name_;
			if(tmp2) {
				auto tmp3 = tmp2->identifier_;
				if(tmp3){
					tmp3->data_type_ = kDataRoleName;
					tmp3->scope_ = 0;
					tmp3->data_flag_ =DATAFLAG::kUse;
				}
			}
			tmp1 = tmp1->role_name_list_;
		}
	}
    }
    | IN GROUP role_name_list {
    	$$ = new Option();
    	$$->case_idx_ = CASE19;
    	$$->role_name_list_ = $3;

    	if($$){
		auto tmp1 = $$->role_name_list_;
		while(tmp1){
			auto tmp2 = tmp1->role_name_;
			if(tmp2) {
				auto tmp3 = tmp2->identifier_;
				if(tmp3){
					tmp3->data_type_ = kDataRoleName;
					tmp3->scope_ = 0;
					tmp3->data_flag_ =DATAFLAG::kUse;
				}
			}
			tmp1 = tmp1->role_name_list_;
		}
	}
    }
    | ROLE role_name_list {
    	$$ = new Option();
    	$$->case_idx_ = CASE20;
    	$$->role_name_list_ = $2;

    	if($$){
		auto tmp1 = $$->role_name_list_;
		while(tmp1){
			auto tmp2 = tmp1->role_name_;
			if(tmp2) {
				auto tmp3 = tmp2->identifier_;
				if(tmp3){
					tmp3->data_type_ = kDataRoleName;
					tmp3->scope_ = 0;
					tmp3->data_flag_ =DATAFLAG::kUse;
				}
			}
			tmp1 = tmp1->role_name_list_;
		}
	}
    }
    | ADMIN role_name_list {
    	$$ = new Option();
    	$$->case_idx_ = CASE21;
    	$$->role_name_list_ = $2;

    	if($$){
		auto tmp1 = $$->role_name_list_;
		while(tmp1){
			auto tmp2 = tmp1->role_name_;
			if(tmp2) {
				auto tmp3 = tmp2->identifier_;
				if(tmp3){
					tmp3->data_type_ = kDataRoleName;
					tmp3->scope_ = 0;
					tmp3->data_flag_ =DATAFLAG::kUse;
				}
			}
			tmp1 = tmp1->role_name_list_;
		}
	}
    }
    | USER role_name_list {
    	$$ = new Option();
    	$$->case_idx_ = CASE22;
    	$$->role_name_list_ = $2;

    	if($$){
		auto tmp1 = $$->role_name_list_;
		while(tmp1){
			auto tmp2 = tmp1->role_name_;
			if(tmp2) {
				auto tmp3 = tmp2->identifier_;
				if(tmp3){
					tmp3->data_type_ = kDataRoleName;
					tmp3->scope_ = 0;
					tmp3->data_flag_ =DATAFLAG::kUse;
				}
			}
			tmp1 = tmp1->role_name_list_;
		}
	}
    }
    | SYSID int_literal {
    	$$ = new Option();
    	$$->case_idx_ = CASE23;
	$$->int_literal_ = $2;
    }
;

role_name_list:
	role_name {
		$$ = new RoleNameList();
		$$->case_idx_ = CASE0;
		$$->role_name_ = $1;
	}
	| role_name OP_COMMA role_name_list {
		$$ = new RoleNameList();
		$$->case_idx_ = CASE1;
		$$->role_name_ = $1;
		$$->role_name_list_ = $3;
	}
;

opt_encrypted:
	ENCRYPTED {
		$$ = new OptEncrypted();
        	$$->case_idx_ = CASE0;
	}
	| /* empty */ {
		$$ = new OptEncrypted();
		$$->case_idx_ = CASE1;
	}
;

opt_or_replace:
	OR REPLACE {
		$$ = new OptOrReplace();
        	$$->case_idx_ = CASE0;
	}
	| /* empty */ {
		$$ = new OptOrReplace();
		$$->case_idx_ = CASE1;
	}
;

opt_temp_token:
	TEMPORARY  {
		$$ = new OptTempToken();
		$$->case_idx_ = CASE0;

	}
   	| TEMP  {
		$$ = new OptTempToken();
		$$->case_idx_ = CASE1;
	}
	| /* empty */ {
		$$ = new OptTempToken();
		$$->case_idx_ = CASE2;
	}
;

opt_recursive:
	RECURSIVE {
		$$ = new OptRecursive();
        	$$->case_idx_ = CASE0;
	}
	| /* empty */ {
		$$ = new OptRecursive();
		$$->case_idx_ = CASE1;
	}
;



opt_with_view_option_list:
	WITH OP_LP index_opt_view_option_list OP_RP {
		$$ = new OptWithViewOptionList();
		$$->case_idx_ = CASE0;
		$$->index_opt_view_option_list_ = $3;
	}
	| /* empty */ {
		$$ = new OptWithViewOptionList();
		$$->case_idx_ = CASE1;
	}
;

create_table_as_stmt:
	CREATE opt_temp TABLE opt_if_not_exist create_as_target AS select_stmt opt_with_data {
		$$ = new CreateTableAsStmt();
		$$->case_idx_ = CASE0;
		$$->opt_temp_ = $2;
		$$->opt_if_not_exist_ = $4;
		$$->create_as_target_ = $5;
		$$->select_stmt_ = $7;
		$$->opt_with_data_ = $8;

		if ($$) {
			auto tmp1 = $$->create_as_target_;
			if (tmp1) {
				auto tmp2 = tmp1->table_name_;
				if (tmp2) {
					auto tmp3 = tmp2->identifier_;
					if(tmp3){
						tmp3->data_type_ = kDataTableName;
						tmp3->scope_ = 0;
						tmp3->data_flag_ =DATAFLAG::kDefine;
					}
				}
			}
		}
	}
;

create_as_target:
	table_name opt_column_name_list_p table_access_method_clause opt_with_storage_parameter_list on_commit_option opt_tablespace {
		$$ = new CreateAsTarget();
		$$->case_idx_ = CASE0;
		$$->table_name_ = $1;
		$$->opt_column_name_list_p_ = $2;
		$$->table_access_method_clause_ = $3;
		$$->opt_with_storage_parameter_list_ = $4;
		$$->on_commit_option_ = $5;
		$$->opt_table_space_ = $6;
	}
;

table_access_method_clause:
	USING method_name {
		$$ = new TableAccessMethodClause();
        	$$->case_idx_ = CASE0;
        	$$->method_name_ = $2;

	}
	| /* empty */  {
		$$ = new TableAccessMethodClause();
		$$->case_idx_ = CASE1;
	}
;


opt_with_storage_parameter_list:
	WITH index_storage_parameter_list {
		$$ = new OptWithStorageParameterList();
        	$$->case_idx_ = CASE0;
        	$$->index_storage_parameter_list_ = $2;
	}
	| WITHOUT OIDS {
		$$ = new OptWithStorageParameterList();
		$$->case_idx_ = CASE1;
	}
	| /* empty */ {
		$$ = new OptWithStorageParameterList();
		$$->case_idx_ = CASE2;
	}
;

on_commit_option:
	ON COMMIT DROP {
		$$ = new OnCommitOption();
		$$->case_idx_ = CASE0;
	}
	| ON COMMIT DELETE ROWS {
		$$ = new OnCommitOption();
		$$->case_idx_ = CASE1;
	}
        | ON COMMIT PRESERVE ROWS {
		$$ = new OnCommitOption();
		$$->case_idx_ = CASE2;
	}
	| /* empty */ {
		$$ = new OnCommitOption();
		$$->case_idx_ = CASE3;
	}
;

opt_with_data:
	WITH DATA {
		$$ = new OptWithData();
        	$$->case_idx_ = CASE0;
	}
	| WITH NO DATA {
		$$ = new OptWithData();
		$$->case_idx_ = CASE1;
	}
	| /* empty */ {
		$$ = new OptWithData();
		$$->case_idx_ = CASE2;
	}
;

alter_tblspc_stmt:
	ALTER TABLESPACE tablespace_name RENAME TO tablespace_name {
		$$ = new AlterTblspcStmt();
		$$->case_idx_ = CASE0;
		$$->tablespace_name_0_ = $3;
		$$->tablespace_name_1_ = $6;

		if($$){
			auto tmp1 = $$->tablespace_name_0_;
			if (tmp1) {

				auto tmp2 = tmp1->identifier_;
				if(tmp2){
					tmp2->data_type_ = kDataTableSpaceName;
					tmp2->scope_ = 0;
					tmp2->data_flag_ =DATAFLAG::kUse;
				}
			}

			auto tmp3 = $$->tablespace_name_1_;
			if (tmp3) {
				auto tmp4 = tmp3->identifier_;
				if(tmp4){
					tmp4->data_type_ = kDataTableSpaceName;
					tmp4->scope_ = 0;
					tmp4->data_flag_ =DATAFLAG::kDefine;
				}
			}

		}

	}
        | ALTER TABLESPACE tablespace_name OWNER TO owner_specification {
		$$ = new AlterTblspcStmt();
		$$->case_idx_ = CASE1;
		$$->tablespace_name_ = $3;
		$$->owner_specification_ = $6;

		if($$){
			auto tmp1 = $$->tablespace_name_;
			if (tmp1) {

				auto tmp2 = tmp1->identifier_;
				if(tmp2){
					tmp2->data_type_ = kDataTableSpaceName;
					tmp2->scope_ = 0;
					tmp2->data_flag_ =DATAFLAG::kUse;
				}
			}
		}
        }
	| ALTER TABLESPACE tablespace_name SET OP_LP index_opt_tablespace_option_list OP_RP {
		$$ = new AlterTblspcStmt();
		$$->case_idx_ = CASE2;
		$$->tablespace_name_ = $3;
		$$->index_opt_tablespace_option_list_ = $6;

		if($$){
			auto tmp1 = $$->tablespace_name_;
			if (tmp1) {

				auto tmp2 = tmp1->identifier_;
				if(tmp2){
					tmp2->data_type_ = kDataTableSpaceName;
					tmp2->scope_ = 0;
					tmp2->data_flag_ =DATAFLAG::kUse;
				}
			}
		}
	}
	| ALTER TABLESPACE tablespace_name RESET OP_LP index_opt_tablespace_option_list OP_RP {
		$$ = new AlterTblspcStmt();
		$$->case_idx_ = CASE3;
		$$->tablespace_name_ = $3;
		$$->index_opt_tablespace_option_list_ = $6;

		if($$){
			auto tmp1 = $$->tablespace_name_;
			if (tmp1) {

				auto tmp2 = tmp1->identifier_;
				if(tmp2){
					tmp2->data_type_ = kDataTableSpaceName;
					tmp2->scope_ = 0;
					tmp2->data_flag_ =DATAFLAG::kUse;
				}
			}
		}
	}
;


index_opt_tablespace_option_list:
	index_opt_tablespace_option {
		$$ = new IndexOptTablespaceOptionList();
		$$->case_idx_ = CASE0;
		$$->index_opt_tablespace_option_ = $1;
	}
	| index_opt_tablespace_option OP_COMMA index_opt_tablespace_option_list {
		$$ = new IndexOptTablespaceOptionList();
		$$->case_idx_ = CASE1;
		$$->index_opt_tablespace_option_ = $1;
		$$->index_opt_tablespace_option_list_ = $3;
	}
;



index_opt_tablespace_option:
	tablespace_option_name opt_equal_tablespace_option_value {
		$$ = new IndexOptTablespaceOption();
		$$->case_idx_ = CASE0;
		$$->tablespace_option_name_ = $1;
		$$->opt_equal_tablespace_option_value_ = $2;
	}
;

opt_equal_tablespace_option_value:
	OP_EQUAL tablespace_option_value {
		$$ = new OptEqualTablespaceOptionValue();
		$$->case_idx_ = CASE0;
		$$->tablespace_option_value_ = $2;
	}
	| /* empty */ {
		$$ = new OptEqualTablespaceOptionValue();
		$$->case_idx_ = CASE1;
	}
;

tablespace_option_name:
	identifier {
		$$ = new TablespaceOptionName();
		$$->case_idx_ = CASE0;
		$$->identifier_ = $1;
	}
;


tablespace_option_value:
	identifier {
		$$ = new TablespaceOptionValue();
		$$->case_idx_ = CASE0;
		$$->identifier_ = $1;
	}
;

alter_conversion_stmt:
	ALTER CONVERSION conversion_name RENAME TO conversion_name {
		$$ = new AlterConversionStmt();
		$$->case_idx_ = CASE0;
		$$->conversion_name_0_ = $3;
		$$->conversion_name_1_ = $6;

		if($$){
			auto tmp1 = $$->conversion_name_0_;
			if (tmp1) {

				auto tmp2 = tmp1->identifier_;
				if(tmp2){
					tmp2->data_type_ = kDataConversionName;
					tmp2->scope_ = 0;
					tmp2->data_flag_ =DATAFLAG::kUse;
				}
			}

			auto tmp3 = $$->conversion_name_1_;
			if (tmp3) {
				auto tmp4 = tmp3->identifier_;
				if(tmp4){
					tmp4->data_type_ = kDataConversionName;
					tmp4->scope_ = 0;
					tmp4->data_flag_ =DATAFLAG::kDefine;
				}
			}

		}

	}
	| ALTER CONVERSION conversion_name OWNER TO owner_specification {
		$$ = new AlterConversionStmt();
		$$->case_idx_ = CASE1;
		$$->conversion_name_ = $3;
		$$->owner_specification_ = $6;

		if($$){
			auto tmp1 = $$->conversion_name_;
			if (tmp1) {

				auto tmp2 = tmp1->identifier_;
				if(tmp2){
					tmp2->data_type_ = kDataConversionName;
					tmp2->scope_ = 0;
					tmp2->data_flag_ =DATAFLAG::kUse;
				}
			}
		}
	}
	| ALTER CONVERSION conversion_name SET SCHEMA schema_name {
		$$ = new AlterConversionStmt();
		$$->case_idx_ = CASE2;
		$$->conversion_name_ = $3;
		$$->schema_name_ = $6;

		if($$){
			auto tmp1 = $$->conversion_name_;
			if (tmp1) {

				auto tmp2 = tmp1->identifier_;
				if(tmp2){
					tmp2->data_type_ = kDataConversionName;
					tmp2->scope_ = 0;
					tmp2->data_flag_ =DATAFLAG::kUse;
				}
			}

			auto tmp3 = $$->schema_name_;
			if (tmp3) {
				auto tmp4 = tmp3->identifier_;
				if(tmp4){
					tmp4->data_type_ = kDataSchemaName;
					tmp4->scope_ = 0;
					tmp4->data_flag_ =DATAFLAG::kUse;
				}
			}
		}
	}
;

conversion_name:
	identifier {
		$$ = new ConversionName();
		$$->case_idx_ = CASE0;
		$$->identifier_ = $1;
	}
;

unreserved_keyword:
	ABORT 		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE0; }
	| ABSOLUTE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE1; }
	| ACCESS	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE2; }
	| ACTION	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE3; }
	| ADD		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE4; }
	| ADMIN		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE5; }
	| AFTER		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE6; }
	| AGGREGATE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE7; }
	| ALSO		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE8; }
	| ALTER		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE9; }
	| ALWAYS	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE10; }
	| ASENSITIVE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE11; }
	| ASSERTION	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE12; }
	| ASSIGNMENT	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE13; }
	| AT		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE14; }
	| ATOMIC	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE15; }
	| ATTACH	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE16; }
	| ATTRIBUTE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE17; }
	| BACKWARD	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE18; }
	| BEFORE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE19; }
	| BEGIN	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE20; }
	| BREADTH	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE21; }
	| BY		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE22; }
	| CACHE		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE23; }
	| CALL		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE24; }
	| CALLED	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE25; }
	| CASCADE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE26; }
	| CASCADED	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE27; }
	| CATALOG	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE28; }
	| CHAIN		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE29; }
	| CHARACTERISTICS	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE30; }
	| CHECKPOINT	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE31; }
	| CLASS		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE32; }
	| CLOSE		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE33; }
	| CLUSTER	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE34; }
	| COLUMNS	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE35; }
	| COMMENT	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE36; }
	| COMMENTS	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE37; }
	| COMMIT	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE38; }
	| COMMITTED	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE39; }
	| COMPRESSION	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE40; }
	| CONFIGURATION	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE41; }
	| CONFLICT	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE42; }
	| CONNECTION	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE43; }
	| CONSTRAINTS	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE44; }
	| CONTENT	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE45; }
	| CONTINUE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE46; }
	| CONVERSION	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE47; }
	| COPY		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE48; }
	| COST		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE49; }
	| CSV		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE50; }
	| CUBE		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE51; }
	| CURRENT	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE52; }
	| CURSOR	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE53; }
	| CYCLE		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE54; }
	| DATA	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE55; }
	| DATABASE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE56; }
	| DAY		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE57; }
	| DEALLOCATE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE58; }
	| DECLARE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE59; }
	| DEFAULTS	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE60; }
	| DEFERRED	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE61; }
	| DEFINER	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE62; }
	| DELETE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE63; }
	| DELIMITER	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE64; }
	| DELIMITERS	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE65; }
	| DEPENDS	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE66; }
	| DEPTH		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE67; }
	| DETACH	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE68; }
	| DICTIONARY	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE69; }
	| DISABLE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE70; }
	| DISCARD	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE71; }
	| DOCUMENT	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE72; }
	| DOMAIN	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE73; }
	| DOUBLE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE74; }
	| DROP		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE75; }
	| EACH		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE76; }
	| ENABLE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE77; }
	| ENCODING	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE78; }
	| ENCRYPTED	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE79; }
	| ENUM	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE80; }
	| ESCAPE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE81; }
	| EVENT		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE82; }
	| EXCLUDE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE83; }
	| EXCLUDING	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE84; }
	| EXCLUSIVE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE85; }
	| EXECUTE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE86; }
	| EXPLAIN	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE87; }
	| EXPRESSION	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE88; }
	| EXTENSION	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE89; }
	| EXTERNAL	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE90; }
	| FAMILY	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE91; }
	| FILTER	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE92; }
	| FINALIZE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE93; }
	| FIRST	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE94; }
	| FOLLOWING	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE95; }
	| FORCE		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE96; }
	| FORWARD	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE97; }
	| FUNCTION	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE98; }
	| FUNCTIONS	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE99; }
	| GENERATED	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE100; }
	| GLOBAL	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE101; }
	| GRANTED	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE102; }
	| GROUPS	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE103; }
	| HANDLER	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE104; }
	| HEADER	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE105; }
	| HOLD		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE106; }
	| HOUR	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE107; }
	| IDENTITY	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE108; }
	| IF		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE109; }
	| IMMEDIATE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE110; }
	| IMMUTABLE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE111; }
	| IMPLICIT	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE112; }
	| IMPORT	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE113; }
	| INCLUDE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE114; }
	| INCLUDING	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE115; }
	| INCREMENT	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE116; }
	| INDEX		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE117; }
	| INDEXES	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE118; }
	| INHERIT	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE119; }
	| INHERITS	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE120; }
	| INLINE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE121; }
	| INPUT	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE122; }
	| INSENSITIVE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE123; }
	| INSERT	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE124; }
	| INSTEAD	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE125; }
	| INVOKER	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE126; }
	| ISOLATION	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE127; }
	| KEY		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE128; }
	| LABEL		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE129; }
	| LANGUAGE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE130; }
	| LARGE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE131; }
	| LAST	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE132; }
	| LEAKPROOF	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE133; }
	| LEVEL		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE134; }
	| LISTEN	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE135; }
	| LOAD		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE136; }
	| LOCAL		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE137; }
	| LOCATION	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE138; }
	| LOCK	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE139; }
	| LOCKED	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE140; }
	| LOGGED	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE141; }
	| MAPPING	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE142; }
	| MATCH		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE143; }
	| MATERIALIZED	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE144; }
	| MAXVALUE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE145; }
	| METHOD	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE146; }
	| MINUTE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE147; }
	| MINVALUE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE148; }
	| MODE		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE149; }
	| MONTH	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE150; }
	| MOVE		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE151; }
	| NAME	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE152; }
	| NAMES		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE153; }
	| NEW		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE154; }
	| NEXT		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE155; }
	| NFC		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE156; }
	| NFD		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE157; }
	| NFKC		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE158; }
	| NFKD		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE159; }
	| NO		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE160; }
	| NORMALIZED	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE161; }
	| NOTHING	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE162; }
	| NOTIFY	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE163; }
	| NOWAIT	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE164; }
	| NULLS	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE165; }
	| OBJECT	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE166; }
	| OF		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE167; }
	| OFF		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE168; }
	| OIDS		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE169; }
	| OLD		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE170; }
	| OPERATOR	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE171; }
	| OPTION	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE172; }
	| OPTIONS	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE173; }
	| ORDINALITY	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE174; }
	| OTHERS	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE175; }
	| OVER		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE176; }
	| OVERRIDING	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE177; }
	| OWNED		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE178; }
	| OWNER		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE179; }
	| PARALLEL	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE180; }
	| PARSER	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE181; }
	| PARTIAL	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE182; }
	| PARTITION	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE183; }
	| PASSING	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE184; }
	| PASSWORD	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE185; }
	| PLANS		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE186; }
	| POLICY	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE187; }
	| PRECEDING	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE188; }
	| PREPARE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE189; }
	| PREPARED	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE190; }
	| PRESERVE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE191; }
	| PRIOR		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE192; }
	| PRIVILEGES	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE193; }
	| PROCEDURAL	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE194; }
	| PROCEDURE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE195; }
	| PROCEDURES	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE196; }
	| PROGRAM	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE197; }
	| PUBLICATION	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE198; }
	| QUOTE		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE199; }
	| RANGE		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE200; }
	| READ		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE201; }
	| REASSIGN	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE202; }
	| RECHECK	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE203; }
	| RECURSIVE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE204; }
	| REF		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE205; }
	| REFERENCING	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE206; }
	| REFRESH	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE207; }
	| REINDEX	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE208; }
	| RELATIVE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE209; }
	| RELEASE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE210; }
	| RENAME	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE211; }
	| REPEATABLE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE212; }
	| REPLACE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE213; }
	| REPLICA	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE214; }
	| RESET		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE215; }
	| RESTART	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE216; }
	| RESTRICT	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE217; }
	| RETURN	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE218; }
	| RETURNS	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE219; }
	| REVOKE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE220; }
	| ROLE		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE221; }
	| ROLLBACK	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE222; }
	| ROLLUP	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE223; }
	| ROUTINE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE224; }
	| ROUTINES	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE225; }
	| ROWS		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE226; }
	| RULE		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE227; }
	| SAVEPOINT	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE228; }
	| SCHEMA	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE229; }
	| SCHEMAS	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE230; }
	| SCROLL	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE231; }
	| SEARCH	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE232; }
	| SECOND	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE233; }
	| SECURITY	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE234; }
	| SEQUENCE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE235; }
	| SEQUENCES	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE236; }
	| SERIALIZABLE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE237; }
	| SERVER	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE238; }
	| SESSION	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE239; }
	| SET		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE240; }
	| SETS		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE241; }
	| SHARE		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE242; }
	| SHOW		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE243; }
	| SIMPLE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE244; }
	| SKIP		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE245; }
	| SNAPSHOT	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE246; }
	| SQL		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE247; }
	| STABLE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE248; }
	| STANDALONE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE249; }
	| START		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE250; }
	| STATEMENT	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE251; }
	| STATISTICS	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE252; }
	| STDIN		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE253; }
	| STDOUT	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE254; }
	| STORAGE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE255; }
	| STORED	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE256; }
	| STRICT	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE257; }
	| STRIP	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE258; }
	| SUBSCRIPTION	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE259; }
	| SUPPORT	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE260; }
	| SYSID		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE261; }
	| SYSTEM	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE262; }
	| TABLES	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE263; }
	| TABLESPACE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE264; }
	| TEMP		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE265; }
	| TEMPLATE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE266; }
	| TEMPORARY	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE267; }
	| TEXT	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE268; }
	| TIES		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE269; }
	| TRANSACTION	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE270; }
	| TRANSFORM	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE271; }
	| TRIGGER	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE272; }
	| TRUNCATE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE273; }
	| TRUSTED	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE274; }
	| TYPE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE275; }
	| TYPES	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE276; }
	| UESCAPE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE277; }
	| UNBOUNDED	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE278; }
	| UNCOMMITTED	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE279; }
	| UNENCRYPTED	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE280; }
	| UNKNOWN	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE281; }
	| UNLISTEN	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE282; }
	| UNLOGGED	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE283; }
	| UNTIL		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE284; }
	| UPDATE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE285; }
	| VACUUM	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE286; }
	| VALID		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE287; }
	| VALIDATE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE288; }
	| VALIDATOR	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE289; }
	| VALUE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE290; }
	| VARYING	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE291; }
	| VERSION	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE292; }
	| VIEW		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE293; }
	| VIEWS		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE294; }
	| VOLATILE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE295; }
	| WHITESPACE	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE296; }
	| WITHIN	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE297; }
	| WITHOUT	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE298; }
	| WORK		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE299; }
	| WRAPPER	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE300; }
	| WRITE		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE301; }
	| XML		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE302; }
	| YEAR	{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE303; }
	| YES		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE304; }
	| ZONE		{ $$ = new UnreservedKeyword(); $$->case_idx_ = CASE305; }
;

reserved_keyword:
          ALL               { $$ = new ReservedKeyword(); $$->case_idx_ = CASE0; }
        | ANALYSE           { $$ = new ReservedKeyword(); $$->case_idx_ = CASE1; }
        | ANALYZE           { $$ = new ReservedKeyword(); $$->case_idx_ = CASE2; }
        | AND               { $$ = new ReservedKeyword(); $$->case_idx_ = CASE3; }
        | ANY               { $$ = new ReservedKeyword(); $$->case_idx_ = CASE4; }
        | ARRAY             { $$ = new ReservedKeyword(); $$->case_idx_ = CASE5; }
        | AS                { $$ = new ReservedKeyword(); $$->case_idx_ = CASE6; }
        | ASC               { $$ = new ReservedKeyword(); $$->case_idx_ = CASE7; }
        | ASYMMETRIC        { $$ = new ReservedKeyword(); $$->case_idx_ = CASE8; }
        | BOTH              { $$ = new ReservedKeyword(); $$->case_idx_ = CASE9; }
        | CASE              { $$ = new ReservedKeyword(); $$->case_idx_ = CASE10; }
        | CAST              { $$ = new ReservedKeyword(); $$->case_idx_ = CASE11; }
        | CHECK             { $$ = new ReservedKeyword(); $$->case_idx_ = CASE12; }
        | COLLATE           { $$ = new ReservedKeyword(); $$->case_idx_ = CASE13; }
        | COLUMN            { $$ = new ReservedKeyword(); $$->case_idx_ = CASE14; }
        | CONSTRAINT        { $$ = new ReservedKeyword(); $$->case_idx_ = CASE15; }
        | CREATE            { $$ = new ReservedKeyword(); $$->case_idx_ = CASE16; }
        | CURRENT_CATALOG   { $$ = new ReservedKeyword(); $$->case_idx_ = CASE17; }
        | CURRENT_DATE      { $$ = new ReservedKeyword(); $$->case_idx_ = CASE18; }
        | CURRENT_ROLE      { $$ = new ReservedKeyword(); $$->case_idx_ = CASE19; }
        | CURRENT_TIME      { $$ = new ReservedKeyword(); $$->case_idx_ = CASE20; }
        | CURRENT_TIMESTAMP { $$ = new ReservedKeyword(); $$->case_idx_ = CASE21; }
        | CURRENT_USER      { $$ = new ReservedKeyword(); $$->case_idx_ = CASE22; }
        | DEFAULT           { $$ = new ReservedKeyword(); $$->case_idx_ = CASE23; }
        | DEFERRABLE        { $$ = new ReservedKeyword(); $$->case_idx_ = CASE24; }
        | DESC              { $$ = new ReservedKeyword(); $$->case_idx_ = CASE25; }
        | DISTINCT          { $$ = new ReservedKeyword(); $$->case_idx_ = CASE26; }
        | DO                { $$ = new ReservedKeyword(); $$->case_idx_ = CASE27; }
        | ELSE              { $$ = new ReservedKeyword(); $$->case_idx_ = CASE28; }
        | END             { $$ = new ReservedKeyword(); $$->case_idx_ = CASE29; }
        | EXCEPT            { $$ = new ReservedKeyword(); $$->case_idx_ = CASE30; }
        | FALSE           { $$ = new ReservedKeyword(); $$->case_idx_ = CASE31; }
        | FETCH             { $$ = new ReservedKeyword(); $$->case_idx_ = CASE32; }
        | FOR               { $$ = new ReservedKeyword(); $$->case_idx_ = CASE33; }
        | FOREIGN           { $$ = new ReservedKeyword(); $$->case_idx_ = CASE34; }
        | FROM              { $$ = new ReservedKeyword(); $$->case_idx_ = CASE35; }
        | GRANT             { $$ = new ReservedKeyword(); $$->case_idx_ = CASE36; }
        | GROUP           { $$ = new ReservedKeyword(); $$->case_idx_ = CASE37; }
        | HAVING            { $$ = new ReservedKeyword(); $$->case_idx_ = CASE38; }
        | IN              { $$ = new ReservedKeyword(); $$->case_idx_ = CASE39; }
        | INITIALLY         { $$ = new ReservedKeyword(); $$->case_idx_ = CASE40; }
        | INTERSECT         { $$ = new ReservedKeyword(); $$->case_idx_ = CASE41; }
        | INTO              { $$ = new ReservedKeyword(); $$->case_idx_ = CASE42; }
        | LATERAL         { $$ = new ReservedKeyword(); $$->case_idx_ = CASE43; }
        | LEADING           { $$ = new ReservedKeyword(); $$->case_idx_ = CASE44; }
        | LIMIT             { $$ = new ReservedKeyword(); $$->case_idx_ = CASE45; }
        | LOCALTIME         { $$ = new ReservedKeyword(); $$->case_idx_ = CASE46; }
        | LOCALTIMESTAMP    { $$ = new ReservedKeyword(); $$->case_idx_ = CASE47; }
        | NOT               { $$ = new ReservedKeyword(); $$->case_idx_ = CASE48; }
        | NULL            { $$ = new ReservedKeyword(); $$->case_idx_ = CASE49; }
        | OFFSET            { $$ = new ReservedKeyword(); $$->case_idx_ = CASE50; }
        | ON                { $$ = new ReservedKeyword(); $$->case_idx_ = CASE51; }
        | ONLY              { $$ = new ReservedKeyword(); $$->case_idx_ = CASE52; }
        | OR                { $$ = new ReservedKeyword(); $$->case_idx_ = CASE53; }
        | ORDER             { $$ = new ReservedKeyword(); $$->case_idx_ = CASE54; }
        | PLACING           { $$ = new ReservedKeyword(); $$->case_idx_ = CASE55; }
        | PRIMARY           { $$ = new ReservedKeyword(); $$->case_idx_ = CASE56; }
        | REFERENCES        { $$ = new ReservedKeyword(); $$->case_idx_ = CASE57; }
        | RETURNING         { $$ = new ReservedKeyword(); $$->case_idx_ = CASE58; }
        | SELECT            { $$ = new ReservedKeyword(); $$->case_idx_ = CASE59; }
        | SESSION_USER      { $$ = new ReservedKeyword(); $$->case_idx_ = CASE60; }
        | SOME              { $$ = new ReservedKeyword(); $$->case_idx_ = CASE61; }
        | SYMMETRIC         { $$ = new ReservedKeyword(); $$->case_idx_ = CASE62; }
        | TABLE             { $$ = new ReservedKeyword(); $$->case_idx_ = CASE63; }
        | THEN              { $$ = new ReservedKeyword(); $$->case_idx_ = CASE64; }
        | TO                { $$ = new ReservedKeyword(); $$->case_idx_ = CASE65; }
        | TRAILING          { $$ = new ReservedKeyword(); $$->case_idx_ = CASE66; }
        | TRUE            { $$ = new ReservedKeyword(); $$->case_idx_ = CASE67; }
        | UNION             { $$ = new ReservedKeyword(); $$->case_idx_ = CASE68; }
        | UNIQUE            { $$ = new ReservedKeyword(); $$->case_idx_ = CASE69; }
        | USER              { $$ = new ReservedKeyword(); $$->case_idx_ = CASE70; }
        | USING             { $$ = new ReservedKeyword(); $$->case_idx_ = CASE71; }
        | VARIADIC          { $$ = new ReservedKeyword(); $$->case_idx_ = CASE72; }
        | WHEN              { $$ = new ReservedKeyword(); $$->case_idx_ = CASE73; }
        | WHERE             { $$ = new ReservedKeyword(); $$->case_idx_ = CASE74; }
        | WINDOW            { $$ = new ReservedKeyword(); $$->case_idx_ = CASE75; }
        | WITH              { $$ = new ReservedKeyword(); $$->case_idx_ = CASE76; }
;


/* Column identifier --- keywords that can be column, table, etc names.
 *
 * Many of these keywords will in fact be recognized as type or function
 * names too; but they have special productions for the purpose, and so
 * can't be treated as "generic" type or function names.
 *
 * The type names appearing here are not usable as function names
 * because they can be followed by OP_LP in typename productions, which
 * looks too much like a function call for an LR(1) parser.
 */
col_name_keyword:
	  BETWEEN 	{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE0; }
	| BIGINT	{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE1; }
	| BIT		{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE2; }
	| BOOLEAN	{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE3; }
	| CHAR	{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE4; }
	| CHARACTER	{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE5; }
	| COALESCE	{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE6; }
	| DEC		{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE7; }
	| DECIMAL	{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE8; }
	| EXISTS	{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE9; }
	| EXTRACT	{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE10; }
	| FLOAT	{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE11; }
	| GREATEST	{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE12; }
	| GROUPING	{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE13; }
	| INOUT		{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE14; }
	| INT		{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE15; }
	| INTEGER	{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE16; }
	| INTERVAL	{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE17; }
	| LEAST		{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE18; }
	| NATIONAL	{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE19; }
	| NCHAR		{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE20; }
	| NONE		{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE21; }
	| NORMALIZE	{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE22; }
	| NULLIF	{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE23; }
	| NUMERIC	{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE24; }
	| OUT		{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE25; }
	| OVERLAY	{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE26; }
	| POSITION	{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE27; }
	| PRECISION	{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE28; }
	| REAL		{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE29; }
	| ROW		{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE30; }
	| SETOF		{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE31; }
	| SMALLINT	{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE32; }
	| SUBSTRING	{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE33; }
	| TIME		{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE34; }
	| TIMESTAMP	{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE35; }
	| TREAT		{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE36; }
	| TRIM		{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE37; }
	| VALUES	{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE38; }
	| VARCHAR	{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE39; }
	| XMLATTRIBUTES	{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE40; }
	| XMLCONCAT	{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE41; }
	| XMLELEMENT	{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE42; }
	| XMLEXISTS	{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE43; }
	| XMLFOREST	{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE44; }
	| XMLNAMESPACES	{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE45; }
	| XMLPARSE	{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE46; }
	| XMLPI		{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE47; }
	| XMLROOT	{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE48; }
	| XMLSERIALIZE	{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE49; }
	| XMLTABLE	{ $$ = new ColNameKeyword(); $$->case_idx_ = CASE50; }

;

type_func_name_keyword:
	  AUTHORIZATION  { $$ = new TypeFuncNameKeyword(); $$->case_idx_ = CASE0; }
	| BINARY         { $$ = new TypeFuncNameKeyword(); $$->case_idx_ = CASE1; }
	| COLLATION      { $$ = new TypeFuncNameKeyword(); $$->case_idx_ = CASE2; }
	| CONCURRENTLY   { $$ = new TypeFuncNameKeyword(); $$->case_idx_ = CASE3; }
	| CROSS          { $$ = new TypeFuncNameKeyword(); $$->case_idx_ = CASE4; }
	| CURRENT_SCHEMA { $$ = new TypeFuncNameKeyword(); $$->case_idx_ = CASE5; }
	| FREEZE         { $$ = new TypeFuncNameKeyword(); $$->case_idx_ = CASE6; }
	| FULL           { $$ = new TypeFuncNameKeyword(); $$->case_idx_ = CASE7; }
	| ILIKE          { $$ = new TypeFuncNameKeyword(); $$->case_idx_ = CASE8; }
	| INNER        { $$ = new TypeFuncNameKeyword(); $$->case_idx_ = CASE9; }
	| IS             { $$ = new TypeFuncNameKeyword(); $$->case_idx_ = CASE10; }
	| ISNULL         { $$ = new TypeFuncNameKeyword(); $$->case_idx_ = CASE11; }
	| JOIN           { $$ = new TypeFuncNameKeyword(); $$->case_idx_ = CASE12; }
	| LEFT           { $$ = new TypeFuncNameKeyword(); $$->case_idx_ = CASE13; }
	| LIKE           { $$ = new TypeFuncNameKeyword(); $$->case_idx_ = CASE14; }
	| NATURAL        { $$ = new TypeFuncNameKeyword(); $$->case_idx_ = CASE15; }
	| NOTNULL        { $$ = new TypeFuncNameKeyword(); $$->case_idx_ = CASE16; }
	| OUTER        { $$ = new TypeFuncNameKeyword(); $$->case_idx_ = CASE17; }
	| OVERLAPS       { $$ = new TypeFuncNameKeyword(); $$->case_idx_ = CASE18; }
	| RIGHT          { $$ = new TypeFuncNameKeyword(); $$->case_idx_ = CASE19; }
	| SIMILAR        { $$ = new TypeFuncNameKeyword(); $$->case_idx_ = CASE20; }
	| TABLESAMPLE    { $$ = new TypeFuncNameKeyword(); $$->case_idx_ = CASE21; }
	| VERBOSE        { $$ = new TypeFuncNameKeyword(); $$->case_idx_ = CASE22; }
;


/* Column identifier --- names that can be column, table, etc names.
 */
col_id:
	IDENT {
		$$ = new ColId();
		$$->case_idx_ = CASE0;
	}
	| unreserved_keyword {
		$$ = new ColId();
		$$->case_idx_ = CASE1;
		$$->unreserved_keyword_ = $1;
	}
	| col_name_keyword {
		$$ = new ColId();
		$$->case_idx_ = CASE2;
		$$->col_name_keyword_ = $1;
	}
;

/* Type/function identifier --- names that can be type or function names.
 */
type_function_name:
	IDENT {
		$$ = new TypeFunctionName();
		$$->case_idx_ = CASE0;
	}
	| unreserved_keyword {
		$$ = new TypeFunctionName();
		$$->case_idx_ = CASE1;
		$$->unreserved_keyword_ = $1;
	}
	| type_func_name_keyword {
		$$ = new TypeFunctionName();
		$$->case_idx_ = CASE2;
		$$->type_func_name_keyword_ = $1;
	}
;

/* Any not-fully-reserved word --- these names can be, eg, role names.
 */
non_reserved_word:
	IDENT {
		$$ = new NonReservedWord();
		$$->case_idx_ = CASE0;
	}
	| unreserved_keyword {
		$$ = new NonReservedWord();
		$$->case_idx_ = CASE1;
		$$->unreserved_keyword_ = $1;
	}
	| col_name_keyword {
		$$ = new NonReservedWord();
		$$->case_idx_ = CASE2;
		$$->col_name_keyword_ = $1;
	}
	| type_func_name_keyword {
		$$ = new NonReservedWord();
		$$->case_idx_ = CASE3;
		$$->type_func_name_keyword_ = $1;
	}
;


col_label:
	IDENT {
		$$ = new ColLabel();
		$$->case_idx_ = CASE0;
	}
	| unreserved_keyword {
		$$ = new ColLabel();
		$$->case_idx_ = CASE1;
		$$->unreserved_keyword_ = $1;
	}
	| col_name_keyword {
		$$ = new ColLabel();
		$$->case_idx_ = CASE2;
		$$->col_name_keyword_ = $1;
	}
	| type_func_name_keyword {
		$$ = new ColLabel();
		$$->case_idx_ = CASE3;
		$$->type_func_name_keyword_ = $1;
	}
	| reserved_keyword {
		$$ = new ColLabel();
		$$->case_idx_ = CASE4;
		$$->reserved_keyword_ = $1;
	}
;

attrs:
	OP_DOT attr_name {
		$$ = new Attrs();
		$$->case_idx_ = CASE0;
		$$->attr_name_ = $2;
	}
	| attrs OP_DOT attr_name {
		$$ = new Attrs();
		$$->case_idx_ = CASE1;
		$$->attrs_ = $1;
		$$->attr_name_ = $3;
	}
;

attr_name:
	col_label {
		$$ = new AttrName();
		$$->case_idx_ = CASE0;
		$$->col_label_ = $1;
	}
;


any_name:
	col_id {
		$$ = new AnyName();
		$$->case_idx_ = CASE0;
		$$->col_id_ = $1;
	}
	| col_id attrs {
		$$ = new AnyName();
		$$->case_idx_ = CASE1;
		$$->col_id_ = $1;
		$$->attrs_ = $2;
	}
;

any_name_list:
	any_name {
		$$ = new AnyNameList();
		$$->case_idx_ = CASE0;
		$$->any_name_ = $1;
	}
	| any_name_list OP_COMMA any_name {
		$$ = new AnyNameList();
		$$->case_idx_ = CASE1;
		$$->any_name_list_ = $1;
		$$->any_name_ = $3;
	}
;


opt_table_element_list:
	table_element_list {
		$$ = new OptTableElementList();
		$$->case_idx_ = CASE0;
		$$->table_element_list_ = $1;
	}
	| /*EMPTY*/ {
		$$ = new OptTableElementList();
		$$->case_idx_ = CASE1;
	}
;


opt_typed_table_element_list:
	OP_LP typed_table_element_list OP_RP {
		$$ = new OptTypedTableElementList();
		$$->case_idx_ = CASE0;
		$$->typed_table_element_list_ = $2;
	}
	| /*EMPTY*/ {
		$$ = new OptTypedTableElementList();
		$$->case_idx_ = CASE1;
	}
;

table_element_list:
	table_element {
		$$ = new TableElementList();
		$$->case_idx_ = CASE0;
		$$->table_element_ = $1;
	}
	| table_element_list OP_COMMA table_element {
		$$ = new TableElementList();
		$$->case_idx_ = CASE1;
		$$->table_element_list_ = $1;
		$$->table_element_ = $3;
	}
;

typed_table_element_list:
	typed_table_element {
		$$ = new TypedTableElementList();
		$$->case_idx_ = CASE0;
		$$->typed_table_element_ = $1;
	}
	| typed_table_element_list OP_COMMA typed_table_element {
		$$ = new TypedTableElementList();
		$$->case_idx_ = CASE1;
		$$->typed_table_element_list_ = $1;
		$$->typed_table_element_ = $3;
	}
;

table_element:
	column_def {
		$$ = new TableElement();
		$$->case_idx_ = CASE0;
		$$->column_def_ = $1;
	}
	| table_like_clause {
		$$ = new TableElement();
		$$->case_idx_ = CASE1;
		$$->table_like_clause_ = $1;
	}
	| table_constraint {
		$$ = new TableElement();
		$$->case_idx_ = CASE2;
		$$->table_constraint_ = $1;
	}
;

typed_table_element:
	column_options {
		$$ = new TypedTableElement();
		$$->case_idx_ = CASE0;
		$$->column_options_ = $1;
	}
	| table_constraint {
		$$ = new TypedTableElement();
		$$->case_idx_ = CASE1;
		$$->table_constraint_ = $1;
	}
;


table_like_clause:
	LIKE table_name table_like_option_list {
		$$ = new TableLikeClause();
		$$->case_idx_ = CASE0;
		$$->table_name_ = $2;
		$$->table_like_option_list_ = $3;
	}
;

table_like_option_list:
	table_like_option_list INCLUDING table_like_option {
		$$ = new TableLikeOptionList();
		$$->case_idx_ = CASE0;
		$$->table_like_option_list_ = $1;
		$$->table_like_option_ = $3;
	}
	| table_like_option_list EXCLUDING table_like_option {
		$$ = new TableLikeOptionList();
		$$->case_idx_ = CASE1;
		$$->table_like_option_list_ = $1;
		$$->table_like_option_ = $3;
	}
	| /* EMPTY */ {
		$$ = new TableLikeOptionList();
		$$->case_idx_ = CASE2;
	}
;

table_like_option:
	COMMENTS {
		$$ = new TableLikeOption();
		$$->case_idx_ = CASE0;
	}
	| COMPRESSION {
		$$ = new TableLikeOption();
		$$->case_idx_ = CASE1;
	}
	| CONSTRAINTS {
		$$ = new TableLikeOption();
		$$->case_idx_ = CASE2;
	}
	| DEFAULTS {
		$$ = new TableLikeOption();
		$$->case_idx_ = CASE3;
	}
	| IDENTITY {
		$$ = new TableLikeOption();
		$$->case_idx_ = CASE4;
	}
	| GENERATED {
		$$ = new TableLikeOption();
		$$->case_idx_ = CASE5;
	}
	| INDEXES {
		$$ = new TableLikeOption();
		$$->case_idx_ = CASE6;
	}
	| STATISTICS {
		$$ = new TableLikeOption();
		$$->case_idx_ = CASE7;
	}
	| STORAGE {
		$$ = new TableLikeOption();
		$$->case_idx_ = CASE8;
	}
	| ALL {
		$$ = new TableLikeOption();
		$$->case_idx_ = CASE9;
	}
;


column_options:
	col_id col_qual_list {
		$$ = new ColumnOptions();
		$$->case_idx_ = CASE0;
		$$->col_id_ = $1;
		$$->col_qual_list_ = $2;
	}
	| col_id WITH OPTIONS col_qual_list {
		$$ = new ColumnOptions();
		$$->case_idx_ = CASE1;
		$$->col_id_ = $1;
		$$->col_qual_list_ = $4;
	}
;


col_qual_list:
	col_qual_list col_constraint {
		$$ = new ColQualList();
		$$->case_idx_ = CASE0;
		$$->col_qual_list_ = $1;
		$$->col_constraint_ = $2;
	}
	| /*EMPTY*/ {
		$$ = new ColQualList();
		$$->case_idx_ = CASE0;
	}
;

col_constraint:
	CONSTRAINT constraint_name col_constraint_elem {
		$$ = new ColConstraint();
		$$->case_idx_ = CASE0;
		$$->constraint_name_ = $2;
		$$->col_constraint_elem_ = $3;
	}
	| col_constraint_elem {
		$$ = new ColConstraint();
        	$$->case_idx_ = CASE1;
        	$$->col_constraint_elem_ = $1;
	}
	| constraint_attr {
		$$ = new ColConstraint();
        	$$->case_idx_ = CASE2;
        	$$->constraint_attr_ = $1;
	}
	| COLLATE any_name {
		$$ = new ColConstraint();
        	$$->case_idx_ = CASE3;
        	$$->any_name_ = $2;
	}
;

col_constraint_elem:
	NOT NULL {
		$$ = new ColConstraintElem();
		$$->case_idx_ = CASE0;
	}
	| NULL {
		$$ = new ColConstraintElem();
		$$->case_idx_ = CASE1;
	}
	| UNIQUE opt_definition opt_cons_table_space {
		$$ = new ColConstraintElem();
		$$->case_idx_ = CASE2;
		$$->opt_definition_ = $2;
		$$->opt_cons_table_space_ = $3;
	}
	| PRIMARY KEY opt_definition opt_cons_table_space {
		$$ = new ColConstraintElem();
		$$->case_idx_ = CASE3;
		$$->opt_definition_ = $3;
		$$->opt_cons_table_space_ = $4;
	}
	| CHECK OP_LP expr OP_RP opt_no_inherit {
		$$ = new ColConstraintElem();
		$$->case_idx_ = CASE4;
		$$->expr_ = $3;
		$$->opt_no_inherit_ = $5;
	}
	| DEFAULT expr {
		$$ = new ColConstraintElem();
		$$->case_idx_ = CASE5;
		$$->expr_ = $2;
	}
	| GENERATED generated_when AS IDENTITY opt_parenthesized_seq_opt_list {
		$$ = new ColConstraintElem();
		$$->case_idx_ = CASE6;
		$$->generated_when_ = $2;
		$$->opt_parenthesized_seq_opt_list_ = $5;
	}
	| GENERATED generated_when AS OP_LP expr OP_RP STORED {
		$$ = new ColConstraintElem();
		$$->case_idx_ = CASE7;
		$$->generated_when_ = $2;
		$$->expr_ = $5;
	}
	| REFERENCES name opt_column_list key_match key_actions {
		$$ = new ColConstraintElem();
		$$->case_idx_ = CASE8;
		$$->name_ = $2;
		$$->opt_column_list_ = $3;
		$$->key_match_ = $4;
		$$->key_actions_ = $5;
	}
;

generated_when:
	ALWAYS {
		$$ = new GeneratedWhen();
		$$->case_idx_ = CASE0;
	}
	| BY DEFAULT {
		$$ = new GeneratedWhen();
		$$->case_idx_ = CASE1;
        }
;

constraint_attr:
	DEFERRABLE {
		$$ = new ConstraintAttr();
		$$->case_idx_ = CASE0;
	}
	| NOT DEFERRABLE {
		$$ = new ConstraintAttr();
		$$->case_idx_ = CASE1;
	}
	| INITIALLY DEFERRED {
		$$ = new ConstraintAttr();
		$$->case_idx_ = CASE2;
	}
	| INITIALLY IMMEDIATE {
		$$ = new ConstraintAttr();
		$$->case_idx_ = CASE3;
	}
;

key_match:
	MATCH FULL
	{
		$$ = new KeyMatch();
		$$->case_idx_ = CASE0;
	}
	| MATCH PARTIAL
	{
		$$ = new KeyMatch();
		$$->case_idx_ = CASE1;
	}
	| MATCH SIMPLE
	{
		$$ = new KeyMatch();
		$$->case_idx_ = CASE2;
	}
	| /*EMPTY*/
	{
		$$ = new KeyMatch();
		$$->case_idx_ = CASE3;
	}
	;

//
// NOTE(Song Liu): Conflict with the previous `key_actions` implementation.
//
//key_actions:
//	key_update {
//		$$ = new KeyActions();
//		$$->case_idx_ = CASE0;
//		$$->key_update_ = $1;
//	}
//	| key_delete {
//		$$ = new KeyActions();
//		$$->case_idx_ = CASE1;
//		$$->key_delete_ = $1;
//	}
//	| key_update key_delete {
//		$$ = new KeyActions();
//		$$->case_idx_ = CASE2;
//		$$->key_update_ = $1;
//		$$->key_delete_ = $2;
//	}
//	| key_delete key_update {
//		$$ = new KeyActions();
//		$$->case_idx_ = CASE3;
//		$$->key_delete_ = $1;
//		$$->key_update_ = $2;
//	}
//	| /*EMPTY*/ {
//		$$ = new KeyActions();
//		$$->case_idx_ = CASE4;
//	}
//;
//
//key_update: ON UPDATE key_action { $$ = new KeyUpdate(); $$->case_idx_ = CASE0; $$->key_action_ = $3; }
//;
//
//key_delete: ON DELETE key_action { $$ = new KeyDelete(); $$->case_idx_ = CASE0; $$->key_action_ = $3; }
//;
//
//key_action:
//	NO ACTION { $$ = new KeyAction(); $$->case_idx_ = CASE0; }
//	| RESTRICT { $$ = new KeyAction(); $$->case_idx_ = CASE1; }
//	| CASCADE { $$ = new KeyAction(); $$->case_idx_ = CASE2; }
//	| SET NULL { $$ = new KeyAction(); $$->case_idx_ = CASE3; }
//	| SET DEFAULT { $$ = new KeyAction(); $$->case_idx_ = CASE4; }
//;

opt_inherit:
	INHERITS OP_LP table_name_list OP_RP {
		$$ = new OptInherit();
		$$->case_idx_ = CASE0;
		$$->table_name_list_ = $3;
	}
	| /*EMPTY*/ {
		$$ = new OptInherit();
		$$->case_idx_ = CASE1;
	}
;

opt_no_inherit:
	NO INHERIT {  $$ = new OptNoInherit(); $$->case_idx_ = CASE0; }
	| /* EMPTY */ {  $$ = new OptNoInherit(); $$->case_idx_ = CASE1; }
;

opt_column_list:
	OP_LP column_list OP_RP {
		$$ = new OptColumnList();
		$$->case_idx_ = CASE0;
		$$->column_list_ = $2;
	}
	| /*EMPTY*/ {
		$$ = new OptColumnList();
		$$->case_idx_ = CASE1;
	}
;

column_list:
	column_elem {
		$$ = new ColumnList();
		$$->case_idx_ = CASE0;
		$$->column_elem_ = $1;
	}
	| column_list OP_COMMA column_elem {
		$$ = new ColumnList();
		$$->case_idx_ = CASE1;
		$$->column_list_ = $1;
		$$->column_elem_ = $3;
	}
;

column_elem:
	col_id {
		$$ = new ColumnElem();
		$$->case_idx_ = CASE0;
		$$->col_id_ = $1;
	}
;


/* Optional partition key specification */
opt_partition_spec:
	partition_spec {
		$$ = new OptPartitionSpec();
		$$->case_idx_ = CASE0;
		$$->partition_spec_ = $1;
	}
	| /*EMPTY*/ {
		$$ = new OptPartitionSpec();
		$$->case_idx_ = CASE1;
	}
;

partition_spec:
	PARTITION BY col_id OP_LP part_params OP_RP {
		$$ = new PartitionSpec();
		$$->case_idx_ = CASE0;
		$$->col_id_ = $3;
		$$->part_params_ = $5;
	}
;

part_params:
	part_elem {
		$$ = new PartParams();
		$$->case_idx_ = CASE0;
		$$->part_elem_ = $1;
	}
	| part_params OP_COMMA part_elem {
		$$ = new PartParams();
		$$->case_idx_ = CASE1;
		$$->part_params_ = $1;
		$$->part_elem_ = $3;
	}
;

part_elem:
	col_id opt_collate opt_class {
		$$ = new PartElem();
		$$->case_idx_ = CASE0;
		$$->col_id_ = $1;
		$$->opt_collate_ = $2;
		$$->opt_class_ = $3;
	}
	| func_expr opt_collate opt_class {
		$$ = new PartElem();
		$$->case_idx_ = CASE1;
		$$->func_expr_ = $1;
		$$->opt_collate_ = $2;
		$$->opt_class_ = $3;
	}
	| OP_LP expr OP_RP opt_collate opt_class {
		$$ = new PartElem();
		$$->case_idx_ = CASE2;
		$$->expr_ = $2;
		$$->opt_collate_ = $4;
		$$->opt_class_ = $5;
	}
;

//
// NOTE(Song Liu): Conflict with the previous `table_access_method_clause` implementation.
//
//table_access_method_clause:
//	USING col_id {
//		$$ = new TableAccessMethodClause();
//		$$->case_idx_ = CASE0;
//		$$->col_id_ = $2;
//	}
//	| /*EMPTY*/ {
//		$$ = new TableAccessMethodClause();
//		$$->case_idx_ = CASE1;
//	}
//;

/* WITHOUT OIDS is legacy only */
opt_with_replotions:
	WITH reloptions {
		$$ = new OptWithReplotions();
		$$->case_idx_ = CASE0;
		$$->reloptions_ = $2;
	}
	| WITHOUT OIDS {
		$$ = new OptWithReplotions();
		$$->case_idx_ = CASE1;
	}
	| /*EMPTY*/ {
		$$ = new OptWithReplotions();
		$$->case_idx_ = CASE2;
	}
;

opt_table_space:
	TABLESPACE tablespace_name {
		$$ = new OptTableSpace();
		$$->case_idx_ = CASE0;
		$$->tablespace_name_ = $2;
	}
	| /*EMPTY*/ {
		$$ = new OptTableSpace();
		$$->case_idx_ = CASE1;
	}
;


opt_cons_table_space:
	USING INDEX TABLESPACE tablespace_name {
		$$ = new OptConsTableSpace();
		$$->case_idx_ = CASE0;
		$$->tablespace_name_ = $4;
	}
	| /*EMPTY*/ {
		$$ = new OptConsTableSpace();
		$$->case_idx_ = CASE1;
	}
;

existing_index:
	USING INDEX index_name {
		$$ = new ExistingIndex();
		$$->case_idx_ = CASE0;
		$$->index_name_ = $3;
	}
;

partition_bound_spec:
	/* a HASH partition */
	FOR VALUES WITH OP_LP hash_partbound OP_RP {
		$$ = new PartitionBoundSpec();
		$$->case_idx_ = CASE0;
		$$->hash_partbound_ = $5;
	}

	/* a LIST partition */
	| FOR VALUES IN OP_LP expr_list OP_RP {
		$$ = new PartitionBoundSpec();
		$$->case_idx_ = CASE1;
		$$->expr_list_ = $5;
	}

	/* a RANGE partition */
	| FOR VALUES FROM OP_LP expr_list OP_RP TO OP_LP expr_list OP_RP {
		$$ = new PartitionBoundSpec();
		$$->case_idx_ = CASE2;
		$$->expr_list_0_ = $5;
		$$->expr_list_1_ = $9;
	}

	/* a DEFAULT partition */
	| DEFAULT {
		$$ = new PartitionBoundSpec();
		$$->case_idx_ = CASE3;
	}
;


hash_partbound_elem:
	non_reserved_word ICONST {
		$$ = new HashPartboundElem();
		$$->case_idx_ = CASE0;
		$$->non_reserved_word_ = $1;
	}
;

hash_partbound:
	hash_partbound_elem {
		$$ = new HashPartbound();
		$$->case_idx_ = CASE0;
		$$->hash_partbound_elem_ = $1;
	}
	| hash_partbound OP_COMMA hash_partbound_elem {
		$$ = new HashPartbound();
		$$->case_idx_ = CASE1;
		$$->hash_partbound_ = $1;
		$$->hash_partbound_elem_ = $3;
	}
;

opt_definition:
	WITH definition {
		$$ = new OptDefinition();
		$$->case_idx_ = CASE0;
		$$->definition_ = $2;
	}
	| /*EMPTY*/ {
		$$ = new OptDefinition();
		$$->case_idx_ = CASE1;
	}
;


definition:
	OP_LP def_list OP_RP {
		$$ = new Definition();
		$$->case_idx_ = CASE0;
		$$->def_list_ = $2;
	}
;

def_list:
	def_elem {
		$$ = new DefList();
		$$->case_idx_ = CASE0;
		$$->def_elem_ = $1;
	}
	| def_list OP_COMMA def_elem {
		$$ = new DefList();
		$$->case_idx_ = CASE1;
		$$->def_list_ = $1;
		$$->def_elem_ = $3;
	}
;

def_elem:
	col_label OP_EQUAL def_arg {
		$$ = new DefElem();
		$$->case_idx_ = CASE0;
		$$->col_label_ = $1;
		$$->def_arg_ = $3;
	}
	| col_label {
		$$ = new DefElem();
		$$->case_idx_ = CASE1;
		$$->col_label_ = $1;
	}
;

/* Note: any simple identifier will be returned as a type name! */
def_arg:
	func_type { $$ = new DefArg(); $$->case_idx_ = CASE0; $$->func_type_ = $1; }
	| reserved_keyword { $$ = new DefArg(); $$->case_idx_ = CASE1; $$->reserved_keyword_ = $1; }
//	| qual_all_Op
	| numeric_only { $$ = new DefArg(); $$->case_idx_ = CASE2; $$->numeric_only_ = $1; }
	| Sconst { $$ = new DefArg(); $$->case_idx_ = CASE3; $$->Sconst_ = $1; }
	| NONE { $$ = new DefArg(); $$->case_idx_ = CASE4; }
;

Iconst: ICONST { $$ = new Iconst(); $$->case_idx_ = CASE0; };
Sconst:	SCONST { $$ = new Sconst(); $$->case_idx_ = CASE0; };

signed_iconst:
	Iconst { $$ = new SignedIconst(); $$->case_idx_ = CASE0; $$->iconst_ = $1; }
	| OP_ADD Iconst { $$ = new SignedIconst(); $$->case_idx_ = CASE0; $$->iconst_ = $2; }
	| OP_SUB Iconst { $$ = new SignedIconst(); $$->case_idx_ = CASE0; $$->iconst_ = $2; }
;

func_type:
	type_name {
		$$ = new FuncType();
		$$->case_idx_ = CASE0;
		$$->type_name_ = $1;
	}
	| type_function_name attrs OP_MOD TYPE {
		$$ = new FuncType();
		$$->case_idx_ = CASE1;
		$$->type_function_name_ = $1;
		$$->attrs_ = $2;
	}
	| SETOF type_function_name attrs OP_MOD TYPE {
		$$ = new FuncType();
		$$->case_idx_ = CASE2;
		$$->type_function_name_ = $2;
		$$->attrs_ = $3;
	}
;


opt_by:
	BY {
		$$ = new OptBy();
		$$->case_idx_ = CASE0;
	}
	| /* EMPTY */ {
		$$ = new OptBy();
		$$->case_idx_ = CASE1;
	}
;


numeric_only:
	FCONST {
		$$ = new NumericOnly();
		$$->case_idx_ = CASE0;
	}
	| OP_ADD FCONST {
		$$ = new NumericOnly();
		$$->case_idx_ = CASE1;
	}
	| OP_SUB FCONST {
		$$ = new NumericOnly();
		$$->case_idx_ = CASE2;
	}
	| signed_iconst {
		$$ = new NumericOnly();
		$$->case_idx_ = CASE3;
		$$->signed_iconst_ = $1;
	}
;

numeric_only_list:
	numeric_only {
		$$ = new NumericOnlyList();
		$$->case_idx_ = CASE0;
		$$->numeric_only_ = $1;
	}
	| numeric_only_list OP_COMMA numeric_only {
		$$ = new NumericOnlyList();
		$$->case_idx_ = CASE0;
		$$->numeric_only_list_ = $1;
		$$->numeric_only_ = $3;
	}
;


opt_parenthesized_seq_opt_list:
	OP_LP seq_opt_list OP_RP {
		$$ = new OptParenthesizedSeqOptList();
		$$->case_idx_ = CASE0;
		$$->seq_opt_list_ = $2;
	}
	| /*EMPTY*/ {
		$$ = new OptParenthesizedSeqOptList();
		$$->case_idx_ = CASE1;
	}
;

seq_opt_list:
	seq_opt_elem {
		$$ = new SeqOptList();
		$$->case_idx_ = CASE0;
		$$->seq_opt_elem_ = $1;
	}
	| seq_opt_list seq_opt_elem {
		$$ = new SeqOptList();
		$$->case_idx_ = CASE1;
		$$->seq_opt_list_ = $1;
		$$->seq_opt_elem_ = $2;
	}
;

seq_opt_elem:
	AS type_name {
		$$ = new SeqOptElem();
		$$->case_idx_ = CASE0;
		$$->type_name_ = $2;
	}
	| CACHE numeric_only {
		$$ = new SeqOptElem();
		$$->case_idx_ = CASE1;
		$$->numeric_only_ = $2;
	}
	| CYCLE {
		$$ = new SeqOptElem();
		$$->case_idx_ = CASE2;
	}
	| NO CYCLE {
		$$ = new SeqOptElem();
		$$->case_idx_ = CASE3;
	}
	| INCREMENT opt_by numeric_only {
		$$ = new SeqOptElem();
		$$->case_idx_ = CASE4;
		$$->opt_by_ = $2;
		$$->numeric_only_ = $3;
	}
	| MAXVALUE numeric_only {
		$$ = new SeqOptElem();
		$$->case_idx_ = CASE5;
		$$->numeric_only_ = $2;
	}
	| MINVALUE numeric_only {
		$$ = new SeqOptElem();
		$$->case_idx_ = CASE6;
		$$->numeric_only_ = $2;
	}
	| NO MAXVALUE {
		$$ = new SeqOptElem();
		$$->case_idx_ = CASE7;
	}
	| NO MINVALUE {
		$$ = new SeqOptElem();
		$$->case_idx_ = CASE8;
	}
	| OWNED BY any_name {
		$$ = new SeqOptElem();
		$$->case_idx_ = CASE9;
		$$->any_name_ = $3;
	}
	| SEQUENCE NAME any_name {
		$$ = new SeqOptElem();
		$$->case_idx_ = CASE10;
		$$->any_name_ = $3;
	}
	| START opt_with numeric_only {
		$$ = new SeqOptElem();
		$$->case_idx_ = CASE11;
		$$->opt_with_ = $2;
		$$->numeric_only_ = $3;
	}
	| RESTART {
		$$ = new SeqOptElem();
		$$->case_idx_ = CASE12;
	}
	| RESTART opt_with numeric_only {
		$$ = new SeqOptElem();
		$$->case_idx_ = CASE13;
		$$->opt_with_ = $2;
		$$->numeric_only_ = $3;
	}
;



reloptions:
	OP_LP reloption_list OP_RP {
		$$ = new Reloptions();
		$$->case_idx_ = CASE0;
		$$->reloption_list_ = $2;
	}
;

opt_reloptions:
	WITH reloptions {
		$$ = new OptReloptions();
		$$->case_idx_ = CASE0;
		$$->reloptions_ = $2;
	}
	| /* EMPTY */ {
		$$ = new OptReloptions();
		$$->case_idx_ = CASE1;
	}
;

reloption_list:
	reloption_elem {
		$$ = new ReloptionList();
		$$->case_idx_ = CASE0;
		$$->reloption_elem_ = $1;
	}
	| reloption_list OP_COMMA reloption_elem {
		$$ = new ReloptionList();
		$$->case_idx_ = CASE2;
		$$->reloption_list_ = $1;
		$$->reloption_elem_ = $3;
	}
;

/* This should match def_elem and also allow qualified names */
reloption_elem:
	col_label OP_EQUAL def_arg
	{
		$$ = new ReloptionElem();
		$$->case_idx_ = CASE0;
		$$->col_label_ = $1;
		$$->def_arg_ = $3;
	}
	| col_label
	{
		$$ = new ReloptionElem();
		$$->case_idx_ = CASE1;
		$$->col_label_ = $1;
	}
	| col_label OP_DOT col_label OP_EQUAL def_arg
	{
		$$ = new ReloptionElem();
		$$->case_idx_ = CASE2;
		$$->col_label_0_ = $1;
		$$->col_label_1_ = $3;
		$$->def_arg_ = $5;
	}
	| col_label OP_DOT col_label
	{
		$$ = new ReloptionElem();
		$$->case_idx_ = CASE3;
		$$->col_label_0_ = $1;
		$$->col_label_1_ = $3;
	}
;

opt_class:
	any_name {
		$$ = new OptClass();
		$$->case_idx_ = CASE0;
		$$->any_name_ = $1;
	}
	| /*EMPTY*/ {
		$$ = new OptClass();
		$$->case_idx_ = CASE1;
	}
;



%%
