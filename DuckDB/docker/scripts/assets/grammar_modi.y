
%{
#line 1 "third_party/libpg_query/grammar/grammar.hpp"

#include "pg_functions.hpp"
#include <string.h>
#include <string>
#include <vector>
#include <memory>

#include <ctype.h>
#include <limits.h>

#include "nodes/makefuncs.hpp"
#include "nodes/nodeFuncs.hpp"
#include "parser/gramparse.hpp"
#include "parser/parser.hpp"
#include "utils/datetime.hpp"

namespace duckdb_libpgquery {
#define DEFAULT_SCHEMA "main"

std::vector< std::shared_ptr<IR> > ir_vec;

#define YYLLOC_DEFAULT(Current, Rhs, N) \
	do { \
		if ((N) > 0) \
			(Current) = (Rhs)[1]; \
		else \
			(Current) = (-1); \
	} while (0)
	
#define YYMALLOC palloc
#define YYFREE   pfree
#define YYINITDEPTH 1000

#define parser_yyerror(msg)  scanner_yyerror(msg, yyscanner)
#define parser_errposition(pos)  scanner_errposition(pos, yyscanner)

static void base_yyerror(YYLTYPE *yylloc, core_yyscan_t yyscanner, GramCovMap* gram_cov,
						 const char *msg);
						 
std::string cstr_to_string(char *str);
std::vector<IR*> get_ir_node_in_stmt_with_type(IR* cur_IR, IRTYPE ir_type);
void setup_col_id(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag);
void setup_col_id_or_string(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag);
void setup_name(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag);
void setup_table_id(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag);
void setup_drop_stmt(IR* cur_ir);
void setup_name_list(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag);
void setup_name_list_opt_comma(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag);
void setup_name_list_opt_comma_opt_bracket(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag);
void setup_opt_name_list(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag);
void setup_qualified_name(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag, DATATYPE data_type_par, DATATYPE data_type_par_par);
void setup_qualified_name_list(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag, DATATYPE data_type_par, DATATYPE data_type_par_par);
void setup_index_name(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag);
void setup_relation_expr(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag, DATATYPE data_type_par, DATATYPE data_type_par_par);
void setup_col_label(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag);
void setup_col_label_or_string(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag);
void setup_opt_column_list(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag);
void setup_column_list(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag);
void setup_alias_clause(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag);
void setup_opt_alias_clause(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag);
void setup_func_alias_clause(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag);
void setup_any_name(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag, DATATYPE data_type_par, DATATYPE data_type_par_par);
void setup_any_name_list(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag, DATATYPE data_type_par, DATATYPE data_type_par_par);
						 
%}
#line 5 "third_party/libpg_query/grammar/grammar.y"
%pure-parser
%expect 0
%name-prefix="base_yy"
%locations

%parse-param {core_yyscan_t yyscanner}
%parse-param {GramCovMap* gram_cov}
%lex-param   {core_yyscan_t yyscanner}

%union
{
    /* ParserFuzz Inject */
    IR* ir;
    /* ParserFuzz Inject END */
	core_YYSTYPE		core_yystype;
	/* these fields must match core_YYSTYPE: */
	int					ival;
	char				*str;
	const char			*keyword;
	const char          *conststr;

	char				chr;
	bool				boolean;
	PGJoinType			jtype;
	PGDropBehavior		dbehavior;
	PGOnCommitAction		oncommit;
	PGOnCreateConflict		oncreateconflict;
	PGList				*list;
	PGNode				*node;
	PGValue				*value;
	PGObjectType			objtype;
	PGTypeName			*typnam;
	PGObjectWithArgs		*objwithargs;
	PGDefElem				*defelt;
	PGSortBy				*sortby;
	PGWindowDef			*windef;
	PGJoinExpr			*jexpr;
	PGIndexElem			*ielem;
	PGAlias				*alias;
	PGRangeVar			*range;
	PGIntoClause			*into;
	PGCTEMaterialize			ctematerialize;
	PGWithClause			*with;
	PGInferClause			*infer;
	PGOnConflictClause	*onconflict;
	PGOnConflictActionAlias onconflictshorthand;
	PGAIndices			*aind;
	PGResTarget			*target;
	PGInsertStmt			*istmt;
	PGVariableSetStmt		*vsetstmt;
	PGOverridingKind       override;
	PGSortByDir            sortorder;
	PGSortByNulls          nullorder;
	PGConstrType           constr;
	PGLockClauseStrength lockstrength;
	PGLockWaitPolicy lockwaitpolicy;
	PGSubLinkType subquerytype;
	PGViewCheckOption viewcheckoption;
	PGInsertColumnOrder bynameorposition;
}

%type <ir> opt_with 
%type <ir> opt_by 
%type <ir> opt_transaction 
%type <ir> macro_alias 
%type <ir> opt_using 
%type <ir> value_or_values 
%type <ir> pivot_keyword 
%type <ir> unpivot_keyword 
%type <ir> opt_table 
%type <ir> by_name 
%type <ir> RowOrStruct 
%type <ir> year_keyword 
%type <ir> month_keyword 
%type <ir> day_keyword 
%type <ir> hour_keyword 
%type <ir> minute_keyword 
%type <ir> second_keyword 
%type <ir> millisecond_keyword 
%type <ir> microsecond_keyword 
%type <ir> opt_asymmetric 
%type <ir> analyze_keyword 
%type <ir> opt_database 
%type <ir> show_or_describe 
%type <ir> opt_tables 
%type <ir> stmt
%type <ir> stmtblock
%type <ir> stmtmulti
%type <ir>	qualified_name
%type <ir>		Sconst  ColId   ColLabel    ColIdOrString
%type <ir> indirection
%type <ir>    indirection_el
%type <ir>	    attr_name
%type <ir> var_name
%type <ir> table_id
%type <ir> opt_check_option
%type <ir> alter_identity_column_option_list
%type <ir> alter_column_default
%type <ir> alter_identity_column_option
%type <ir> alter_generic_option_list
%type <ir> alter_table_cmd
%type <ir> alter_using
%type <ir> alter_generic_option_elem
%type <ir> alter_table_cmds
%type <ir> alter_generic_options
%type <ir> opt_set_data
%type <ir> insert_rest
%type <ir> insert_target
%type <ir> opt_conf_expr
%type <ir> opt_with_clause
%type <ir> insert_column_item
%type <ir> set_clause
%type <ir> opt_on_conflict
%type <ir> opt_or_action
%type <ir> opt_by_name_or_position
%type <ir> index_elem
%type <ir> returning_clause
%type <ir> override_kind
%type <ir> set_target_list
%type <ir> opt_collate
%type <ir> opt_class
%type <ir> insert_column_list
%type <ir> set_clause_list set_clause_list_opt_comma
%type <ir> index_params
%type <ir> set_target
%type <ir> param_list
%type <ir> file_name
%type <ir> repo_path
%type <ir>	select_no_parens select_with_parens select_clause
simple_select values_clause values_clause_opt_comma
%type <ir> opt_asc_desc
%type <ir> opt_nulls_order
%type <ir> opt_collate_clause
%type <ir> indirection_expr
%type <ir> struct_expr
%type <ir>	opt_nowait_or_skip
%type <ir> name
%type <ir>	func_name qual_Op qual_all_Op subquery_Op
%type <ir>		all_Op
%type <ir> MathOp
%type <ir>	distinct_clause opt_all_clause name_list_opt_comma opt_name_list name_list_opt_comma_opt_bracket
sort_clause opt_sort_clause sortby_list name_list from_clause from_list from_list_opt_comma opt_array_bounds
qualified_name_list any_name 				any_operator expr_list	attrs expr_list_opt_comma opt_expr_list_opt_comma c_expr_list c_expr_list_opt_comma
target_list			 			 opt_indirection target_list_opt_comma opt_target_list_opt_comma
group_clause select_limit
opt_select_limit 			 			 TableFuncElementList opt_type_modifiers opt_select extended_indirection opt_extended_indirection
%type <ir>	group_by_list group_by_list_opt_comma opt_func_arguments unpivot_header
%type <ir>	group_by_item empty_grouping_set rollup_clause cube_clause grouping_sets_clause grouping_or_grouping_id
%type <ir>	OptTempTableName
%type <ir>	into_clause
%type <ir>	for_locking_strength
%type <ir>	for_locking_item
%type <ir>	for_locking_clause opt_for_locking_clause for_locking_items
%type <ir>	locked_rels_list
%type <ir>	all_or_distinct
%type <ir>	join_outer join_qual
%type <ir>	join_type
%type <ir>	extract_list overlay_list position_list
%type <ir>	substr_list trim_list
%type <ir>	opt_interval
%type <ir>	overlay_placing substr_from substr_for
%type <ir>	except_list opt_except_list replace_list_el replace_list opt_replace_list replace_list_opt_comma
%type <ir> limit_clause select_limit_value
offset_clause select_offset_value
select_fetch_first_value I_or_F_const
%type <ir>	row_or_rows first_or_next
%type <ir> TableFuncElement
%type <ir> where_clause 				a_expr b_expr c_expr d_expr AexprConst opt_slice_bound extended_indirection_el
columnref in_expr having_clause qualify_clause func_table
%type <ir>	rowsfrom_item rowsfrom_list opt_col_def_list
%type <ir> opt_ordinality
%type <ir> opt_ignore_nulls
%type <ir>	func_arg_list
%type <ir>	func_arg_expr
%type <ir>	list_comprehension
%type <ir>	row qualified_row type_list colid_type_list
%type <ir>	case_expr case_arg when_clause case_default
%type <ir>	when_clause_list
%type <ir>	sub_type
%type <ir>	dict_arg
%type <ir>	dict_arguments dict_arguments_opt_comma
%type <ir>	map_arg map_arguments map_arguments_opt_comma opt_map_arguments_opt_comma
%type <ir>	alias_clause opt_alias_clause
%type <ir>	func_alias_clause
%type <ir>	sortby
%type <ir>	table_ref
%type <ir>	joined_table
%type <ir>	relation_expr
%type <ir>	tablesample_clause opt_tablesample_clause tablesample_entry
%type <ir>	sample_clause sample_count
%type <ir>	opt_sample_func
%type <ir>	opt_repeatable_clause
%type <ir>	target_el
%type <ir>	Typename SimpleTypename ConstTypename opt_Typename
GenericType Numeric opt_float
Character ConstCharacter
CharacterWithLength CharacterWithoutLength
ConstDatetime ConstInterval
Bit ConstBit BitWithLength BitWithoutLength
%type <ir>		character
%type <ir>		extract_arg
%type <ir> opt_varying opt_timezone
%type <ir>	Iconst
%type <ir>		type_function_name param_name type_name_token function_name_token
%type <ir>		ColLabelOrString
%type <ir>	func_application func_expr_common_subexpr
%type <ir>	func_expr func_expr_windowless
%type <ir>	common_table_expr
%type <ir>	with_clause
%type <ir>	cte_list
%type <ir>	opt_materialized
%type <ir>	within_group_clause
%type <ir>	filter_clause
%type <ir>	export_clause
%type <ir>	window_clause window_definition_list opt_partition_clause
%type <ir>	window_definition over_clause window_specification
opt_frame_clause frame_extent frame_bound
%type <ir>		opt_existing_window_name
%type <ir> pivot_value pivot_column_entry single_pivot_value unpivot_value
%type <ir> pivot_value_list pivot_column_list_internal pivot_column_list pivot_header opt_pivot_group_by unpivot_value_list
%type <ir> opt_include_nulls
%type <ir> drop_type_any_name
%type <ir> drop_type_name
%type <ir> any_name_list
%type <ir> opt_drop_behavior
%type <ir> drop_type_name_on_any_name
%type <ir> type_name_list
%type <ir> prep_type_clause
%type <ir> PreparableStmt
%type <ir> opt_verbose
%type <ir> explain_option_arg
%type <ir> ExplainableStmt
%type <ir> NonReservedWord
%type <ir> NonReservedWord_or_Sconst
%type <ir> explain_option_list
%type <ir> opt_boolean_or_string
%type <ir> explain_option_elem
%type <ir> explain_option_name
%type <ir> OptSeqOptList
%type <ir> relation_expr_opt_alias
%type <ir> where_or_current_clause
%type <ir> using_clause
%type <ir> OptSchemaEltList
%type <ir> schema_stmt
%type <ir> opt_column
%type <ir> ConstraintAttributeSpec
%type <ir> def_arg
%type <ir> OptParenthesizedSeqOptList
%type <ir> generic_option_arg
%type <ir> key_action
%type <ir> ColConstraint
%type <ir> ColConstraintElem
%type <ir> generic_option_elem
%type <ir> key_update
%type <ir> key_actions
%type <ir> OnCommitOption
%type <ir> reloptions
%type <ir> opt_no_inherit
%type <ir> TableConstraint
%type <ir> TableLikeOption
%type <ir> reloption_list
%type <ir> ExistingIndex
%type <ir> ConstraintAttr
%type <ir> OptWith
%type <ir> definition
%type <ir> TableLikeOptionList
%type <ir> generic_option_name
%type <ir> ConstraintAttributeElem
%type <ir> columnDef
%type <ir> def_list
%type <ir> index_name
%type <ir> TableElement
%type <ir> def_elem
%type <ir> opt_definition
%type <ir> OptTableElementList
%type <ir> columnElem
%type <ir> opt_column_list
%type <ir> ColQualList
%type <ir> key_delete
%type <ir> reloption_elem
%type <ir> columnList columnList_opt_comma
%type <ir> func_type
%type <ir> GeneratedColumnType opt_GeneratedColumnType
%type <ir> ConstraintElem GeneratedConstraintElem
%type <ir> TableElementList
%type <ir> key_match
%type <ir> TableLikeClause
%type <ir> OptTemp
%type <ir> generated_when
%type <ir> set_rest
%type <ir> generic_set
%type <ir> var_value
%type <ir> zone_value
%type <ir> var_list
%type <ir> access_method
%type <ir> access_method_clause
%type <ir> opt_concurrently
%type <ir> opt_index_name
%type <ir> opt_reloptions
%type <ir> opt_unique
%type <ir> opt_col_id
%type <ir> generic_reset
%type <ir> reset_rest
%type <ir> SeqOptList
%type <ir> NumericOnly
%type <ir> SeqOptElem
%type <ir> SignedIconst
%type <ir> execute_param_clause
%type <ir> execute_param_list
%type <ir> execute_param_expr
%type <ir> vacuum_option_elem
%type <ir> opt_full
%type <ir> vacuum_option_list
%type <ir> opt_freeze
%type <ir> opt_with_data
%type <ir> create_as_target
%type <ir> copy_from
%type <ir> copy_delimiter
%type <ir> copy_generic_opt_arg_list
%type <ir> opt_as
%type <ir> opt_program
%type <ir> copy_options
%type <ir> copy_generic_opt_arg
%type <ir> copy_generic_opt_elem
%type <ir> opt_oids
%type <ir> copy_opt_list
%type <ir> opt_binary
%type <ir> copy_opt_item
%type <ir> copy_generic_opt_arg_list_item
%type <ir> copy_file_name
%type <ir> copy_generic_opt_list
%type <ir> opt_enum_val_list
%type <ir> enum_val_list
%type <ir> opt_database_alias
%type <ir> ident_list ident_name
%type <ir> AlterObjectSchemaStmt
%type <ir> AlterSeqStmt
%type <ir> AlterTableStmt
%type <ir> AnalyzeStmt
%type <ir> AttachStmt
%type <ir> CallStmt
%type <ir> CheckPointStmt
%type <ir> CopyStmt
%type <ir> CreateAsStmt
%type <ir> CreateFunctionStmt
%type <ir> CreateSchemaStmt
%type <ir> CreateSeqStmt
%type <ir> CreateStmt
%type <ir> CreateTypeStmt
%type <ir> DeallocateStmt
%type <ir> DeleteStmt
%type <ir> DetachStmt
%type <ir> DropStmt
%type <ir> ExecuteStmt
%type <ir> ExplainStmt
%type <ir> ExportStmt
%type <ir> ImportStmt
%type <ir> IndexStmt
%type <ir> InsertStmt
%type <ir> LoadStmt
%type <ir> PragmaStmt
%type <ir> PrepareStmt
%type <ir> RenameStmt
%type <ir> SelectStmt
%type <ir> TransactionStmt
%type <ir> UpdateStmt
%type <ir> UseStmt
%type <ir> VacuumStmt
%type <ir> VariableResetStmt
%type <ir> VariableSetStmt
%type <ir> VariableShowStmt
%type <ir> ViewStmt
/*
* Non-keyword token types.  These are hard-wired into the "flex" lexer.
* They must be listed first so that their numeric codes do not depend on
* the set of keywords.  PL/pgSQL depends on this so that it can share the
* same lexer.  If you add/change tokens here, fix PL/pgSQL to match!
*
* DOT_DOT is unused in the core SQL grammar, and so will always provoke
* parse errors.  It is needed by PL/pgSQL.
*/
%token <str>	IDENT FCONST SCONST BCONST XCONST Op
%token <ival>	ICONST PARAM
%token			TYPECAST DOT_DOT COLON_EQUALS EQUALS_GREATER INTEGER_DIVISION POWER_OF LAMBDA_ARROW DOUBLE_ARROW
%token			LESS_EQUALS GREATER_EQUALS NOT_EQUALS
/*
* If you want to make any keyword changes, update the keyword table in
* src/include/parser/kwlist.h and add new keywords to the appropriate one
* of the reserved-or-not-so-reserved keyword lists, below; search
* this file for "Keyword category lists".
*/
/* ordinary key words in alphabetical order */
%token <keyword> ABORT_P ABSOLUTE_P ACCESS ACTION ADD_P ADMIN AFTER AGGREGATE ALL ALSO ALTER ALWAYS ANALYSE ANALYZE AND ANTI ANY ARRAY AS ASC_P ASOF ASSERTION ASSIGNMENT ASYMMETRIC AT ATTACH ATTRIBUTE AUTHORIZATION BACKWARD BEFORE BEGIN_P BETWEEN BIGINT BINARY BIT BOOLEAN_P BOTH BY CACHE CALL_P CALLED CASCADE CASCADED CASE CAST CATALOG_P CHAIN CHAR_P CHARACTER CHARACTERISTICS CHECK_P CHECKPOINT CLASS CLOSE CLUSTER COALESCE COLLATE COLLATION COLUMN COLUMNS COMMENT COMMENTS COMMIT COMMITTED COMPRESSION CONCURRENTLY CONFIGURATION CONFLICT CONNECTION CONSTRAINT CONSTRAINTS CONTENT_P CONTINUE_P CONVERSION_P COPY COST CREATE_P CROSS CSV CUBE CURRENT_P CURSOR CYCLE DATA_P DATABASE DAY_P DAYS_P DEALLOCATE DEC DECIMAL_P DECLARE DEFAULT DEFAULTS DEFERRABLE DEFERRED DEFINER DELETE_P DELIMITER DELIMITERS DEPENDS DESC_P DESCRIBE DETACH DICTIONARY DISABLE_P DISCARD DISTINCT DO DOCUMENT_P DOMAIN_P DOUBLE_P DROP EACH ELSE ENABLE_P ENCODING ENCRYPTED END_P ENUM_P ESCAPE EVENT EXCEPT EXCLUDE EXCLUDING EXCLUSIVE EXECUTE EXISTS EXPLAIN EXPORT_P EXPORT_STATE EXTENSION EXTERNAL EXTRACT FALSE_P FAMILY FETCH FILTER FIRST_P FLOAT_P FOLLOWING FOR FORCE FOREIGN FORWARD FREEZE FROM FULL FUNCTION FUNCTIONS GENERATED GLOB GLOBAL GRANT GRANTED GROUP_P GROUPING GROUPING_ID HANDLER HAVING HEADER_P HOLD HOUR_P HOURS_P IDENTITY_P IF_P IGNORE_P ILIKE IMMEDIATE IMMUTABLE IMPLICIT_P IMPORT_P IN_P INCLUDE_P INCLUDING INCREMENT INDEX INDEXES INHERIT INHERITS INITIALLY INLINE_P INNER_P INOUT INPUT_P INSENSITIVE INSERT INSTALL INSTEAD INT_P INTEGER INTERSECT INTERVAL INTO INVOKER IS ISNULL ISOLATION JOIN JSON KEY LABEL LANGUAGE LARGE_P LAST_P LATERAL_P LEADING LEAKPROOF LEFT LEVEL LIKE LIMIT LISTEN LOAD LOCAL LOCATION LOCK_P LOCKED LOGGED MACRO MAP MAPPING MATCH MATERIALIZED MAXVALUE METHOD MICROSECOND_P MICROSECONDS_P MILLISECOND_P MILLISECONDS_P MINUTE_P MINUTES_P MINVALUE MODE MONTH_P MONTHS_P MOVE NAME_P NAMES NATIONAL NATURAL NCHAR NEW NEXT NO NONE NOT NOTHING NOTIFY NOTNULL NOWAIT NULL_P NULLIF NULLS_P NUMERIC OBJECT_P OF OFF OFFSET OIDS OLD ON ONLY OPERATOR OPTION OPTIONS OR ORDER ORDINALITY OUT_P OUTER_P OVER OVERLAPS OVERLAY OVERRIDING OWNED OWNER PARALLEL PARSER PARTIAL PARTITION PASSING PASSWORD PERCENT PIVOT PIVOT_LONGER PIVOT_WIDER PLACING PLANS POLICY POSITION POSITIONAL PRAGMA_P PRECEDING PRECISION PREPARE PREPARED PRESERVE PRIMARY PRIOR PRIVILEGES PROCEDURAL PROCEDURE PROGRAM PUBLICATION QUALIFY QUOTE RANGE READ_P REAL REASSIGN RECHECK RECURSIVE REF REFERENCES REFERENCING REFRESH REINDEX RELATIVE_P RELEASE RENAME REPEATABLE REPLACE REPLICA RESET RESPECT_P RESTART RESTRICT RETURNING RETURNS REVOKE RIGHT ROLE ROLLBACK ROLLUP ROW ROWS RULE SAMPLE SAVEPOINT SCHEMA SCHEMAS SCROLL SEARCH SECOND_P SECONDS_P SECURITY SELECT SEMI SEQUENCE SEQUENCES SERIALIZABLE SERVER SESSION SET SETOF SETS SHARE SHOW SIMILAR SIMPLE SKIP SMALLINT SNAPSHOT SOME SQL_P STABLE STANDALONE_P START STATEMENT STATISTICS STDIN STDOUT STORAGE STORED STRICT_P STRIP_P STRUCT SUBSCRIPTION SUBSTRING SUMMARIZE SYMMETRIC SYSID SYSTEM_P TABLE TABLES TABLESAMPLE TABLESPACE TEMP TEMPLATE TEMPORARY TEXT_P THEN TIME TIMESTAMP TO TRAILING TRANSACTION TRANSFORM TREAT TRIGGER TRIM TRUE_P TRUNCATE TRUSTED TRY_CAST TYPE_P TYPES_P UNBOUNDED UNCOMMITTED UNENCRYPTED UNION UNIQUE UNKNOWN UNLISTEN UNLOGGED UNPIVOT UNTIL UPDATE USE_P USER USING VACUUM VALID VALIDATE VALIDATOR VALUE_P VALUES VARCHAR VARIADIC VARYING VERBOSE VERSION_P VIEW VIEWS VIRTUAL VOLATILE WHEN WHERE WHITESPACE_P WINDOW WITH WITHIN WITHOUT WORK WRAPPER WRITE_P XML_P XMLATTRIBUTES XMLCONCAT XMLELEMENT XMLEXISTS XMLFOREST XMLNAMESPACES XMLPARSE XMLPI XMLROOT XMLSERIALIZE XMLTABLE YEAR_P YEARS_P YES_P ZONE
/*
* The grammar thinks these are keywords, but they are not in the kwlist.h
* list and so can never be entered directly.  The filter in parser.c
* creates these tokens when required (based on looking one token ahead).
*
* NOT_LA exists so that productions such as NOT LIKE can be given the same
* precedence as LIKE; otherwise they'd effectively have the same precedence
* as NOT, at least with respect to their left-hand subexpression.
* NULLS_LA and WITH_LA are needed to make the grammar LALR(1).
*/
%token		NOT_LA NULLS_LA WITH_LA
/* Precedence: lowest to highest */
%nonassoc	SET				/* see */
%left		UNION EXCEPT
%left		INTERSECT
%left		LAMBDA_ARROW DOUBLE_ARROW
%left		OR
%left		AND
%right		NOT
%nonassoc	IS ISNULL NOTNULL	/* IS sets precedence for IS NULL, etc */
%nonassoc	'<' '>' '=' LESS_EQUALS GREATER_EQUALS NOT_EQUALS
%nonassoc	BETWEEN IN_P GLOB LIKE ILIKE SIMILAR NOT_LA
%nonassoc	ESCAPE			/* ESCAPE must be just above LIKE/ILIKE/SIMILAR */
%left		POSTFIXOP		/* dummy for postfix Op rules */
/*
* To support target_el without AS, we must give IDENT an explicit priority
* between POSTFIXOP and Op.  We can safely assign the same priority to
* various unreserved keywords as needed to resolve ambiguities (this can't
* have any bad effects since obviously the keywords will still behave the
* same as if they weren't keywords).  We need to do this for PARTITION,
* RANGE, ROWS to support opt_existing_window_name; and for RANGE, ROWS
* so that they can follow a_expr without creating postfix-operator problems;
* for GENERATED so that it can follow b_expr;
* and for NULL so that it can follow b_expr in without creating
* postfix-operator problems.
*
* To support CUBE and ROLLUP in GROUP BY without reserving them, we give them
* an explicit priority lower than '(', so that a rule with CUBE '(' will shift
* rather than reducing a conflicting rule that takes CUBE as a function name.
* Using the same precedence as IDENT seems right for the reasons given above.
*
* The frame_bound productions UNBOUNDED PRECEDING and UNBOUNDED FOLLOWING
* are even messier: since UNBOUNDED is an unreserved keyword (per spec!),
* there is no principled way to distinguish these from the productions
* a_expr PRECEDING/FOLLOWING.  We hack this up by giving UNBOUNDED slightly
* lower precedence than PRECEDING and FOLLOWING.  At present this doesn't
* appear to cause UNBOUNDED to be treated differently from other unreserved
* keywords anywhere else in the grammar, but it's definitely risky.  We can
* blame any funny behavior of UNBOUNDED on the SQL standard, though.
*/
%nonassoc	UNBOUNDED		/* ideally should have same precedence as IDENT */
%nonassoc	IDENT GENERATED NULL_P PARTITION RANGE ROWS PRECEDING FOLLOWING CUBE ROLLUP ENUM_P
%left		Op OPERATOR		/* multi-character ops and user-defined operators */
%left		'+' '-'
%left		'*' '/' '%' INTEGER_DIVISION
%left		'^' POWER_OF
/* Unary Operators */
%left		AT				/* sets precedence for AT TIME ZONE */
%left		COLLATE
%right		UMINUS
%left		'[' ']'
%left		'(' ')'
%left		TYPECAST
%left		'.'
/*
* These might seem to be low-precedence, but actually they are not part
* of the arithmetic hierarchy at all in their use as JOIN operators.
* We make them high-precedence to support their use as function names.
* They wouldn't be given a precedence at all, were it not that we need
* left-associativity among the JOIN rules themselves.
*/
%left		JOIN CROSS LEFT FULL RIGHT INNER_P NATURAL POSITIONAL PIVOT UNPIVOT ANTI SEMI ASOF
/* kluge to keep from causing shift/reduce conflicts */
%right		PRESERVE STRIP_P IGNORE_P RESPECT_P

%%

stmtblock:

    stmtmulti {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(250811,239994); // mapping from stmtblock to stmtmulti
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kStmtblock, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
        pg_yyget_extra(yyscanner)->ir_vec = ir_vec; 
        ir_vec.clear();
    }

;


stmtmulti:

    stmtmulti ';' stmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(239994,239994); // mapping from stmtmulti to stmtmulti
        	gram_cov->log_edge_cov_map(239994,11730); // mapping from stmtmulti to stmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kStmtmulti, OP3("", ";", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | stmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(239994,11730); // mapping from stmtmulti to stmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kStmtmulti, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


stmt:

    AlterObjectSchemaStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(11730,241845); // mapping from stmt to AlterObjectSchemaStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | AlterSeqStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(11730,53506); // mapping from stmt to AlterSeqStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | AlterTableStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(11730,3339); // mapping from stmt to AlterTableStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | AnalyzeStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(11730,43238); // mapping from stmt to AnalyzeStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | AttachStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(11730,63056); // mapping from stmt to AttachStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CallStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(11730,169607); // mapping from stmt to CallStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CheckPointStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(11730,209782); // mapping from stmt to CheckPointStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CopyStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(11730,128531); // mapping from stmt to CopyStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CreateAsStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(11730,203801); // mapping from stmt to CreateAsStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CreateFunctionStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(11730,4674); // mapping from stmt to CreateFunctionStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CreateSchemaStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(11730,248310); // mapping from stmt to CreateSchemaStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CreateSeqStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(11730,206176); // mapping from stmt to CreateSeqStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CreateStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(11730,139905); // mapping from stmt to CreateStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CreateTypeStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(11730,103560); // mapping from stmt to CreateTypeStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | DeallocateStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(11730,17318); // mapping from stmt to DeallocateStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | DeleteStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(11730,147970); // mapping from stmt to DeleteStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | DetachStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(11730,12042); // mapping from stmt to DetachStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | DropStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(11730,53483); // mapping from stmt to DropStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        setup_drop_stmt(tmp1); 
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ExecuteStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(11730,220282); // mapping from stmt to ExecuteStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ExplainStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(11730,101618); // mapping from stmt to ExplainStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ExportStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(11730,60855); // mapping from stmt to ExportStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ImportStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(11730,75502); // mapping from stmt to ImportStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | IndexStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(11730,198169); // mapping from stmt to IndexStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | InsertStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(11730,254452); // mapping from stmt to InsertStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | LoadStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(11730,110711); // mapping from stmt to LoadStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | PragmaStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(11730,176050); // mapping from stmt to PragmaStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | PrepareStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(11730,246258); // mapping from stmt to PrepareStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | RenameStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(11730,122660); // mapping from stmt to RenameStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | SelectStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(11730,70058); // mapping from stmt to SelectStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | TransactionStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(11730,171693); // mapping from stmt to TransactionStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | UpdateStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(11730,157714); // mapping from stmt to UpdateStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | UseStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(11730,92978); // mapping from stmt to UseStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | VacuumStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(11730,159119); // mapping from stmt to VacuumStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | VariableResetStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(11730,212540); // mapping from stmt to VariableResetStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | VariableSetStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(11730,66533); // mapping from stmt to VariableSetStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | VariableShowStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(11730,58683); // mapping from stmt to VariableShowStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ViewStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(11730,14948); // mapping from stmt to ViewStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kStmt, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


AlterTableStmt:

    ALTER TABLE relation_expr alter_table_cmds {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(3339,135212); // mapping from AlterTableStmt to relation_expr
        	gram_cov->log_edge_cov_map(3339,41258); // mapping from AlterTableStmt to alter_table_cmds
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        setup_relation_expr(tmp1, kDataTableName, kUse, kDataSchemaName, kDataDatabase); 
        auto tmp2 = $4;
        res = new IR(kAlterTableStmt, OP3("ALTER TABLE", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ALTER TABLE IF_P EXISTS relation_expr alter_table_cmds {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(3339,135212); // mapping from AlterTableStmt to relation_expr
        	gram_cov->log_edge_cov_map(3339,41258); // mapping from AlterTableStmt to alter_table_cmds
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $5;
        setup_relation_expr(tmp1, kDataTableName, kUse, kDataSchemaName, kDataDatabase); 
        auto tmp2 = $6;
        res = new IR(kAlterTableStmt, OP3("ALTER TABLE IF EXISTS", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ALTER INDEX qualified_name alter_table_cmds {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(3339,38734); // mapping from AlterTableStmt to qualified_name
        	gram_cov->log_edge_cov_map(3339,41258); // mapping from AlterTableStmt to alter_table_cmds
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        setup_qualified_name(tmp1, kDataIndexName, kUse, kDataTableName, kDataDatabase); 
        auto tmp2 = $4;
        res = new IR(kAlterTableStmt, OP3("ALTER INDEX", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ALTER INDEX IF_P EXISTS qualified_name alter_table_cmds {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(3339,38734); // mapping from AlterTableStmt to qualified_name
        	gram_cov->log_edge_cov_map(3339,41258); // mapping from AlterTableStmt to alter_table_cmds
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $5;
        setup_qualified_name(tmp1, kDataIndexName, kUse, kDataTableName, kDataDatabase); 
        auto tmp2 = $6;
        res = new IR(kAlterTableStmt, OP3("ALTER INDEX IF EXISTS", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ALTER SEQUENCE qualified_name alter_table_cmds {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(3339,38734); // mapping from AlterTableStmt to qualified_name
        	gram_cov->log_edge_cov_map(3339,41258); // mapping from AlterTableStmt to alter_table_cmds
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        setup_qualified_name(tmp1, kDataSequenceName, kUse, kDataTableName, kDataDatabase); 
        auto tmp2 = $4;
        res = new IR(kAlterTableStmt, OP3("ALTER SEQUENCE", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ALTER SEQUENCE IF_P EXISTS qualified_name alter_table_cmds {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(3339,38734); // mapping from AlterTableStmt to qualified_name
        	gram_cov->log_edge_cov_map(3339,41258); // mapping from AlterTableStmt to alter_table_cmds
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $5;
        setup_qualified_name(tmp1, kDataSequenceName, kUse, kDataTableName, kDataDatabase); 
        auto tmp2 = $6;
        res = new IR(kAlterTableStmt, OP3("ALTER SEQUENCE IF EXISTS", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ALTER VIEW qualified_name alter_table_cmds {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(3339,38734); // mapping from AlterTableStmt to qualified_name
        	gram_cov->log_edge_cov_map(3339,41258); // mapping from AlterTableStmt to alter_table_cmds
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        setup_qualified_name(tmp1, kDataViewName, kUse, kDataTableName, kDataDatabase); 
        auto tmp2 = $4;
        res = new IR(kAlterTableStmt, OP3("ALTER VIEW", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ALTER VIEW IF_P EXISTS qualified_name alter_table_cmds {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(3339,38734); // mapping from AlterTableStmt to qualified_name
        	gram_cov->log_edge_cov_map(3339,41258); // mapping from AlterTableStmt to alter_table_cmds
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $5;
        setup_qualified_name(tmp1, kDataViewName, kUse, kDataTableName, kDataDatabase); 
        auto tmp2 = $6;
        res = new IR(kAlterTableStmt, OP3("ALTER VIEW IF EXISTS", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


alter_identity_column_option_list:

    alter_identity_column_option {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(67434,73105); // mapping from alter_identity_column_option_list to alter_identity_column_option
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kAlterIdentityColumnOptionList, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | alter_identity_column_option_list alter_identity_column_option {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(67434,67434); // mapping from alter_identity_column_option_list to alter_identity_column_option_list
        	gram_cov->log_edge_cov_map(67434,73105); // mapping from alter_identity_column_option_list to alter_identity_column_option
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAlterIdentityColumnOptionList, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


alter_column_default:

    SET DEFAULT a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(202751,53205); // mapping from alter_column_default to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kAlterColumnDefault, OP3("SET DEFAULT", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | DROP DEFAULT {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kAlterColumnDefault, OP3("DROP DEFAULT", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


alter_identity_column_option:

    RESTART {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kAlterIdentityColumnOption, OP3("RESTART", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | RESTART opt_with NumericOnly {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(73105,142489); // mapping from alter_identity_column_option to opt_with
        	gram_cov->log_edge_cov_map(73105,146194); // mapping from alter_identity_column_option to NumericOnly
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterIdentityColumnOption, OP3("RESTART", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | SET SeqOptElem {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(73105,212902); // mapping from alter_identity_column_option to SeqOptElem
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kAlterIdentityColumnOption, OP3("SET", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | SET GENERATED generated_when {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(73105,253387); // mapping from alter_identity_column_option to generated_when
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kAlterIdentityColumnOption, OP3("SET GENERATED", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


alter_generic_option_list:

    alter_generic_option_elem {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(111994,63043); // mapping from alter_generic_option_list to alter_generic_option_elem
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kAlterGenericOptionList, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | alter_generic_option_list ',' alter_generic_option_elem {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(111994,111994); // mapping from alter_generic_option_list to alter_generic_option_list
        	gram_cov->log_edge_cov_map(111994,63043); // mapping from alter_generic_option_list to alter_generic_option_elem
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAlterGenericOptionList, OP3("", ",", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


alter_table_cmd:

    ADD_P columnDef {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(46016,252287); // mapping from alter_table_cmd to columnDef
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kAlterTableCmd, OP3("ADD", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ADD_P IF_P NOT EXISTS columnDef {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(46016,252287); // mapping from alter_table_cmd to columnDef
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $5;
        res = new IR(kAlterTableCmd, OP3("ADD IF NOT EXISTS", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ADD_P COLUMN columnDef {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(46016,252287); // mapping from alter_table_cmd to columnDef
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kAlterTableCmd, OP3("ADD COLUMN", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ADD_P COLUMN IF_P NOT EXISTS columnDef {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(46016,252287); // mapping from alter_table_cmd to columnDef
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $6;
        res = new IR(kAlterTableCmd, OP3("ADD COLUMN IF NOT EXISTS", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ALTER opt_column ColId alter_column_default {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(46016,249738); // mapping from alter_table_cmd to opt_column
        	gram_cov->log_edge_cov_map(46016,133796); // mapping from alter_table_cmd to ColId
        	gram_cov->log_edge_cov_map(46016,202751); // mapping from alter_table_cmd to alter_column_default
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        setup_col_id(tmp2, kDataColumnName, kUse); 
        res = new IR(kAlterTableCmd_1, OP3("ALTER", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $4;
        res = new IR(kAlterTableCmd, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ALTER opt_column ColId DROP NOT NULL_P {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(46016,249738); // mapping from alter_table_cmd to opt_column
        	gram_cov->log_edge_cov_map(46016,133796); // mapping from alter_table_cmd to ColId
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        setup_col_id(tmp2, kDataColumnName, kUse); 
        res = new IR(kAlterTableCmd, OP3("ALTER", "", "DROP NOT NULL"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ALTER opt_column ColId SET NOT NULL_P {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(46016,249738); // mapping from alter_table_cmd to opt_column
        	gram_cov->log_edge_cov_map(46016,133796); // mapping from alter_table_cmd to ColId
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        setup_col_id(tmp2, kDataColumnName, kUse); 
        res = new IR(kAlterTableCmd, OP3("ALTER", "", "SET NOT NULL"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ALTER opt_column ColId SET STATISTICS SignedIconst {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(46016,249738); // mapping from alter_table_cmd to opt_column
        	gram_cov->log_edge_cov_map(46016,133796); // mapping from alter_table_cmd to ColId
        	gram_cov->log_edge_cov_map(46016,250694); // mapping from alter_table_cmd to SignedIconst
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        setup_col_id(tmp2, kDataColumnName, kUse); 
        res = new IR(kAlterTableCmd_2, OP3("ALTER", "", "SET STATISTICS"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $6;
        res = new IR(kAlterTableCmd, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ALTER opt_column ColId SET reloptions {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(46016,249738); // mapping from alter_table_cmd to opt_column
        	gram_cov->log_edge_cov_map(46016,133796); // mapping from alter_table_cmd to ColId
        	gram_cov->log_edge_cov_map(46016,68978); // mapping from alter_table_cmd to reloptions
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        setup_col_id(tmp2, kDataColumnName, kUse); 
        res = new IR(kAlterTableCmd_3, OP3("ALTER", "", "SET"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $5;
        res = new IR(kAlterTableCmd, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ALTER opt_column ColId RESET reloptions {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(46016,249738); // mapping from alter_table_cmd to opt_column
        	gram_cov->log_edge_cov_map(46016,133796); // mapping from alter_table_cmd to ColId
        	gram_cov->log_edge_cov_map(46016,68978); // mapping from alter_table_cmd to reloptions
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        setup_col_id(tmp2, kDataColumnName, kUse); 
        res = new IR(kAlterTableCmd_4, OP3("ALTER", "", "RESET"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $5;
        res = new IR(kAlterTableCmd, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ALTER opt_column ColId SET STORAGE ColId {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(46016,249738); // mapping from alter_table_cmd to opt_column
        	gram_cov->log_edge_cov_map(46016,133796); // mapping from alter_table_cmd to ColId
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        setup_col_id(tmp2, kDataColumnName, kUse); 
        res = new IR(kAlterTableCmd_5, OP3("ALTER", "", "SET STORAGE"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $6;
        setup_col_id(tmp3, kDataStorageName, kUse); 
        res = new IR(kAlterTableCmd, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ALTER opt_column ColId ADD_P GENERATED generated_when AS IDENTITY_P OptParenthesizedSeqOptList {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(46016,249738); // mapping from alter_table_cmd to opt_column
        	gram_cov->log_edge_cov_map(46016,133796); // mapping from alter_table_cmd to ColId
        	gram_cov->log_edge_cov_map(46016,253387); // mapping from alter_table_cmd to generated_when
        	gram_cov->log_edge_cov_map(46016,259050); // mapping from alter_table_cmd to OptParenthesizedSeqOptList
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        setup_col_id(tmp2, kDataColumnName, kUse); 
        res = new IR(kAlterTableCmd_6, OP3("ALTER", "", "ADD GENERATED"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $6;
        res = new IR(kAlterTableCmd_7, OP3("", "", "AS IDENTITY"), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $9;
        res = new IR(kAlterTableCmd, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ALTER opt_column ColId alter_identity_column_option_list {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(46016,249738); // mapping from alter_table_cmd to opt_column
        	gram_cov->log_edge_cov_map(46016,133796); // mapping from alter_table_cmd to ColId
        	gram_cov->log_edge_cov_map(46016,67434); // mapping from alter_table_cmd to alter_identity_column_option_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        setup_col_id(tmp2, kDataColumnName, kUse); 
        res = new IR(kAlterTableCmd_8, OP3("ALTER", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $4;
        res = new IR(kAlterTableCmd, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ALTER opt_column ColId DROP IDENTITY_P {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(46016,249738); // mapping from alter_table_cmd to opt_column
        	gram_cov->log_edge_cov_map(46016,133796); // mapping from alter_table_cmd to ColId
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        setup_col_id(tmp2, kDataColumnName, kUse); 
        res = new IR(kAlterTableCmd, OP3("ALTER", "", "DROP IDENTITY"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ALTER opt_column ColId DROP IDENTITY_P IF_P EXISTS {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(46016,249738); // mapping from alter_table_cmd to opt_column
        	gram_cov->log_edge_cov_map(46016,133796); // mapping from alter_table_cmd to ColId
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        setup_col_id(tmp2, kDataColumnName, kUse); 
        res = new IR(kAlterTableCmd, OP3("ALTER", "", "DROP IDENTITY IF EXISTS"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | DROP opt_column IF_P EXISTS ColId opt_drop_behavior {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(46016,249738); // mapping from alter_table_cmd to opt_column
        	gram_cov->log_edge_cov_map(46016,133796); // mapping from alter_table_cmd to ColId
        	gram_cov->log_edge_cov_map(46016,207372); // mapping from alter_table_cmd to opt_drop_behavior
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $5;
        setup_col_id(tmp2, kDataColumnName, kUndefine); 
        res = new IR(kAlterTableCmd_9, OP3("DROP", "IF EXISTS", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $6;
        res = new IR(kAlterTableCmd, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | DROP opt_column ColId opt_drop_behavior {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(46016,249738); // mapping from alter_table_cmd to opt_column
        	gram_cov->log_edge_cov_map(46016,133796); // mapping from alter_table_cmd to ColId
        	gram_cov->log_edge_cov_map(46016,207372); // mapping from alter_table_cmd to opt_drop_behavior
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        setup_col_id(tmp2, kDataColumnName, kUndefine); 
        res = new IR(kAlterTableCmd_10, OP3("DROP", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $4;
        res = new IR(kAlterTableCmd, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ALTER opt_column ColId opt_set_data TYPE_P Typename opt_collate_clause alter_using {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(46016,249738); // mapping from alter_table_cmd to opt_column
        	gram_cov->log_edge_cov_map(46016,133796); // mapping from alter_table_cmd to ColId
        	gram_cov->log_edge_cov_map(46016,187253); // mapping from alter_table_cmd to opt_set_data
        	gram_cov->log_edge_cov_map(46016,237247); // mapping from alter_table_cmd to Typename
        	gram_cov->log_edge_cov_map(46016,152257); // mapping from alter_table_cmd to opt_collate_clause
        	gram_cov->log_edge_cov_map(46016,158662); // mapping from alter_table_cmd to alter_using
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        setup_col_id(tmp2, kDataColumnName, kUse); 
        res = new IR(kAlterTableCmd_11, OP3("ALTER", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $4;
        res = new IR(kAlterTableCmd_12, OP3("", "", "TYPE"), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $6;
        res = new IR(kAlterTableCmd_13, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp5 = $7;
        res = new IR(kAlterTableCmd_14, OP3("", "", ""), res, tmp5);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp6 = $8;
        res = new IR(kAlterTableCmd, OP3("", "", ""), res, tmp6);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ALTER opt_column ColId alter_generic_options {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(46016,249738); // mapping from alter_table_cmd to opt_column
        	gram_cov->log_edge_cov_map(46016,133796); // mapping from alter_table_cmd to ColId
        	gram_cov->log_edge_cov_map(46016,161663); // mapping from alter_table_cmd to alter_generic_options
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        setup_col_id(tmp2, kDataColumnName, kUse); 
        res = new IR(kAlterTableCmd_15, OP3("ALTER", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $4;
        res = new IR(kAlterTableCmd, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ADD_P TableConstraint {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(46016,70763); // mapping from alter_table_cmd to TableConstraint
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kAlterTableCmd, OP3("ADD", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ALTER CONSTRAINT name ConstraintAttributeSpec {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(46016,212908); // mapping from alter_table_cmd to name
        	gram_cov->log_edge_cov_map(46016,220122); // mapping from alter_table_cmd to ConstraintAttributeSpec
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        setup_name(tmp1, kDataConstraintName, kUse); 
        auto tmp2 = $4;
        res = new IR(kAlterTableCmd, OP3("ALTER CONSTRAINT", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | VALIDATE CONSTRAINT name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(46016,212908); // mapping from alter_table_cmd to name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        setup_name(tmp1, kDataConstraintName, kUse); 
        res = new IR(kAlterTableCmd, OP3("VALIDATE CONSTRAINT", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | DROP CONSTRAINT IF_P EXISTS name opt_drop_behavior {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(46016,212908); // mapping from alter_table_cmd to name
        	gram_cov->log_edge_cov_map(46016,207372); // mapping from alter_table_cmd to opt_drop_behavior
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $5;
        setup_name(tmp1, kDataConstraintName, kUndefine); 
        auto tmp2 = $6;
        res = new IR(kAlterTableCmd, OP3("DROP CONSTRAINT IF EXISTS", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | DROP CONSTRAINT name opt_drop_behavior {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(46016,212908); // mapping from alter_table_cmd to name
        	gram_cov->log_edge_cov_map(46016,207372); // mapping from alter_table_cmd to opt_drop_behavior
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        setup_name(tmp1, kDataConstraintName, kUndefine); 
        auto tmp2 = $4;
        res = new IR(kAlterTableCmd, OP3("DROP CONSTRAINT", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | SET LOGGED {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kAlterTableCmd, OP3("SET LOGGED", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | SET UNLOGGED {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kAlterTableCmd, OP3("SET UNLOGGED", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | SET reloptions {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(46016,68978); // mapping from alter_table_cmd to reloptions
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kAlterTableCmd, OP3("SET", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | RESET reloptions {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(46016,68978); // mapping from alter_table_cmd to reloptions
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kAlterTableCmd, OP3("RESET", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | alter_generic_options {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(46016,161663); // mapping from alter_table_cmd to alter_generic_options
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kAlterTableCmd, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


alter_using:

    USING a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(158662,53205); // mapping from alter_using to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kAlterUsing, OP3("USING", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kAlterUsing, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


alter_generic_option_elem:

    generic_option_elem {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(63043,209686); // mapping from alter_generic_option_elem to generic_option_elem
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kAlterGenericOptionElem, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | SET generic_option_elem {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(63043,209686); // mapping from alter_generic_option_elem to generic_option_elem
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kAlterGenericOptionElem, OP3("SET", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ADD_P generic_option_elem {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(63043,209686); // mapping from alter_generic_option_elem to generic_option_elem
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kAlterGenericOptionElem, OP3("ADD", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | DROP generic_option_name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(63043,180136); // mapping from alter_generic_option_elem to generic_option_name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kAlterGenericOptionElem, OP3("DROP", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


alter_table_cmds:

    alter_table_cmd {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(41258,46016); // mapping from alter_table_cmds to alter_table_cmd
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kAlterTableCmds, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | alter_table_cmds ',' alter_table_cmd {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(41258,41258); // mapping from alter_table_cmds to alter_table_cmds
        	gram_cov->log_edge_cov_map(41258,46016); // mapping from alter_table_cmds to alter_table_cmd
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAlterTableCmds, OP3("", ",", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


alter_generic_options:

    OPTIONS '(' alter_generic_option_list ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(161663,111994); // mapping from alter_generic_options to alter_generic_option_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kAlterGenericOptions, OP3("OPTIONS (", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_set_data:

    SET DATA_P {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptSetData, OP3("SET DATA", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | SET {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptSetData, OP3("SET", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptSetData, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


DeallocateStmt:

    DEALLOCATE name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(17318,212908); // mapping from DeallocateStmt to name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        setup_name(tmp1, kDataPrepareName, kUndefine); 
        res = new IR(kDeallocateStmt, OP3("DEALLOCATE", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | DEALLOCATE PREPARE name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(17318,212908); // mapping from DeallocateStmt to name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        setup_name(tmp1, kDataPrepareName, kUndefine); 
        res = new IR(kDeallocateStmt, OP3("DEALLOCATE PREPARE", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | DEALLOCATE ALL {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kDeallocateStmt, OP3("DEALLOCATE ALL", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | DEALLOCATE PREPARE ALL {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kDeallocateStmt, OP3("DEALLOCATE PREPARE ALL", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


qualified_name:

    ColIdOrString {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(38734,227596); // mapping from qualified_name to ColIdOrString
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kQualifiedName, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ColId indirection {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(38734,133796); // mapping from qualified_name to ColId
        	gram_cov->log_edge_cov_map(38734,101888); // mapping from qualified_name to indirection
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kQualifiedName, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


ColId:

    IDENT {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(133796,69880); // mapping from ColId to IDENT
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = new IR(kIdentifier, cstr_to_string($1), kDataFixLater, kFlagUnknown);
        std::shared_ptr<IR> p_tmp1(tmp1, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_tmp1);
        res = new IR(kColId, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


ColIdOrString:

    ColId {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(227596,133796); // mapping from ColIdOrString to ColId
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kColIdOrString, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | SCONST {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(227596,26013); // mapping from ColIdOrString to SCONST
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = new IR(kStringLiteral, cstr_to_string($1), kDataFixLater, kFlagUnknown);
        std::shared_ptr<IR> p_tmp1(tmp1, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_tmp1);
        res = new IR(kColIdOrString, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


Sconst:

    SCONST {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(47445,26013); // mapping from Sconst to SCONST
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = new IR(kStringLiteral, cstr_to_string($1), kDataFixLater, kFlagUnknown);
        std::shared_ptr<IR> p_tmp1(tmp1, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_tmp1);
        res = new IR(kSconst, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


indirection:

    indirection_el {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(101888,213976); // mapping from indirection to indirection_el
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kIndirection, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | indirection indirection_el {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(101888,101888); // mapping from indirection to indirection
        	gram_cov->log_edge_cov_map(101888,213976); // mapping from indirection to indirection_el
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kIndirection, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


indirection_el:

    '.' attr_name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(213976,70483); // mapping from indirection_el to attr_name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kIndirectionEl, OP3(".", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


attr_name:

    ColLabel {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(70483,197766); // mapping from attr_name to ColLabel
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kAttrName, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


ColLabel:

    IDENT {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(197766,69880); // mapping from ColLabel to IDENT
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = new IR(kIdentifier, cstr_to_string($1), kDataFixLater, kFlagUnknown);
        std::shared_ptr<IR> p_tmp1(tmp1, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_tmp1);
        res = new IR(kColLabel, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


RenameStmt:

    ALTER SCHEMA name RENAME TO name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(122660,212908); // mapping from RenameStmt to name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        setup_name(tmp1, kDataDatabase, kUndefine); 
        auto tmp2 = $6;
        setup_name(tmp2, kDataDatabase, kDefine); 
        res = new IR(kRenameStmt, OP3("ALTER SCHEMA", "RENAME TO", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ALTER TABLE relation_expr RENAME TO name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(122660,135212); // mapping from RenameStmt to relation_expr
        	gram_cov->log_edge_cov_map(122660,212908); // mapping from RenameStmt to name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        setup_relation_expr(tmp1, kDataTableName, kUndefine, kDataSchemaName, kDataDatabase); 
        auto tmp2 = $6;
        setup_name(tmp2, kDataTableName, kDefine); 
        res = new IR(kRenameStmt, OP3("ALTER TABLE", "RENAME TO", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ALTER TABLE IF_P EXISTS relation_expr RENAME TO name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(122660,135212); // mapping from RenameStmt to relation_expr
        	gram_cov->log_edge_cov_map(122660,212908); // mapping from RenameStmt to name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $5;
        setup_relation_expr(tmp1, kDataTableName, kUndefine, kDataSchemaName, kDataDatabase); 
        auto tmp2 = $8;
        setup_name(tmp2, kDataTableName, kDefine); 
        res = new IR(kRenameStmt, OP3("ALTER TABLE IF EXISTS", "RENAME TO", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ALTER SEQUENCE qualified_name RENAME TO name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(122660,38734); // mapping from RenameStmt to qualified_name
        	gram_cov->log_edge_cov_map(122660,212908); // mapping from RenameStmt to name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        setup_qualified_name(tmp1, kDataSequenceName, kUndefine, kDataTableName, kDataDatabase); 
        auto tmp2 = $6;
        setup_name(tmp2, kDataSequenceName, kDefine); 
        res = new IR(kRenameStmt, OP3("ALTER SEQUENCE", "RENAME TO", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ALTER SEQUENCE IF_P EXISTS qualified_name RENAME TO name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(122660,38734); // mapping from RenameStmt to qualified_name
        	gram_cov->log_edge_cov_map(122660,212908); // mapping from RenameStmt to name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $5;
        setup_qualified_name(tmp1, kDataSequenceName, kUndefine, kDataTableName, kDataDatabase); 
        auto tmp2 = $8;
        setup_name(tmp2, kDataSequenceName, kDefine); 
        res = new IR(kRenameStmt, OP3("ALTER SEQUENCE IF EXISTS", "RENAME TO", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ALTER VIEW qualified_name RENAME TO name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(122660,38734); // mapping from RenameStmt to qualified_name
        	gram_cov->log_edge_cov_map(122660,212908); // mapping from RenameStmt to name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        setup_qualified_name(tmp1, kDataViewName, kUndefine, kDataTableName, kDataDatabase); 
        auto tmp2 = $6;
        setup_name(tmp2, kDataViewName, kDefine); 
        res = new IR(kRenameStmt, OP3("ALTER VIEW", "RENAME TO", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ALTER VIEW IF_P EXISTS qualified_name RENAME TO name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(122660,38734); // mapping from RenameStmt to qualified_name
        	gram_cov->log_edge_cov_map(122660,212908); // mapping from RenameStmt to name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $5;
        setup_qualified_name(tmp1, kDataViewName, kUndefine, kDataTableName, kDataDatabase); 
        auto tmp2 = $8;
        setup_name(tmp2, kDataViewName, kDefine); 
        res = new IR(kRenameStmt, OP3("ALTER VIEW IF EXISTS", "RENAME TO", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ALTER INDEX qualified_name RENAME TO name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(122660,38734); // mapping from RenameStmt to qualified_name
        	gram_cov->log_edge_cov_map(122660,212908); // mapping from RenameStmt to name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        setup_qualified_name(tmp1, kDataIndexName, kUndefine, kDataTableName, kDataDatabase); 
        auto tmp2 = $6;
        setup_name(tmp2, kDataIndexName, kDefine); 
        res = new IR(kRenameStmt, OP3("ALTER INDEX", "RENAME TO", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ALTER INDEX IF_P EXISTS qualified_name RENAME TO name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(122660,38734); // mapping from RenameStmt to qualified_name
        	gram_cov->log_edge_cov_map(122660,212908); // mapping from RenameStmt to name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $5;
        setup_qualified_name(tmp1, kDataIndexName, kUndefine, kDataTableName, kDataDatabase); 
        auto tmp2 = $8;
        setup_name(tmp2, kDataIndexName, kDefine); 
        res = new IR(kRenameStmt, OP3("ALTER INDEX IF EXISTS", "RENAME TO", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ALTER TABLE relation_expr RENAME opt_column name TO name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(122660,135212); // mapping from RenameStmt to relation_expr
        	gram_cov->log_edge_cov_map(122660,249738); // mapping from RenameStmt to opt_column
        	gram_cov->log_edge_cov_map(122660,212908); // mapping from RenameStmt to name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        setup_relation_expr(tmp1, kDataTableName, kUse, kDataSchemaName, kDataDatabase); 
        auto tmp2 = $5;
        res = new IR(kRenameStmt_1, OP3("ALTER TABLE", "RENAME", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $6;
        setup_name(tmp3, kDataColumnName, kUndefine); 
        res = new IR(kRenameStmt_2, OP3("", "", "TO"), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $8;
        setup_name(tmp4, kDataColumnName, kDefine); 
        res = new IR(kRenameStmt, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ALTER TABLE IF_P EXISTS relation_expr RENAME opt_column name TO name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(122660,135212); // mapping from RenameStmt to relation_expr
        	gram_cov->log_edge_cov_map(122660,249738); // mapping from RenameStmt to opt_column
        	gram_cov->log_edge_cov_map(122660,212908); // mapping from RenameStmt to name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $5;
        setup_relation_expr(tmp1, kDataTableName, kUse, kDataSchemaName, kDataDatabase); 
        auto tmp2 = $7;
        res = new IR(kRenameStmt_3, OP3("ALTER TABLE IF EXISTS", "RENAME", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $8;
        setup_name(tmp3, kDataColumnName, kUndefine); 
        res = new IR(kRenameStmt_4, OP3("", "", "TO"), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $10;
        setup_name(tmp4, kDataColumnName, kDefine); 
        res = new IR(kRenameStmt, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ALTER TABLE relation_expr RENAME CONSTRAINT name TO name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(122660,135212); // mapping from RenameStmt to relation_expr
        	gram_cov->log_edge_cov_map(122660,212908); // mapping from RenameStmt to name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        setup_relation_expr(tmp1, kDataTableName, kUse, kDataSchemaName, kDataDatabase); 
        auto tmp2 = $6;
        setup_name(tmp2, kDataConstraintName, kUndefine); 
        res = new IR(kRenameStmt_5, OP3("ALTER TABLE", "RENAME CONSTRAINT", "TO"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $8;
        setup_name(tmp3, kDataConstraintName, kDefine); 
        res = new IR(kRenameStmt, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ALTER TABLE IF_P EXISTS relation_expr RENAME CONSTRAINT name TO name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(122660,135212); // mapping from RenameStmt to relation_expr
        	gram_cov->log_edge_cov_map(122660,212908); // mapping from RenameStmt to name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $5;
        setup_relation_expr(tmp1, kDataTableName, kUse, kDataSchemaName, kDataDatabase); 
        auto tmp2 = $8;
        setup_name(tmp2, kDataConstraintName, kUndefine); 
        res = new IR(kRenameStmt_6, OP3("ALTER TABLE IF EXISTS", "RENAME CONSTRAINT", "TO"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $10;
        setup_name(tmp3, kDataConstraintName, kDefine); 
        res = new IR(kRenameStmt, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_column:

    COLUMN {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptColumn, OP3("COLUMN", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptColumn, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


InsertStmt:

    opt_with_clause INSERT opt_or_action INTO insert_target opt_by_name_or_position insert_rest opt_on_conflict returning_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(254452,74395); // mapping from InsertStmt to opt_with_clause
        	gram_cov->log_edge_cov_map(254452,86819); // mapping from InsertStmt to opt_or_action
        	gram_cov->log_edge_cov_map(254452,22099); // mapping from InsertStmt to insert_target
        	gram_cov->log_edge_cov_map(254452,132149); // mapping from InsertStmt to opt_by_name_or_position
        	gram_cov->log_edge_cov_map(254452,253472); // mapping from InsertStmt to insert_rest
        	gram_cov->log_edge_cov_map(254452,242786); // mapping from InsertStmt to opt_on_conflict
        	gram_cov->log_edge_cov_map(254452,132480); // mapping from InsertStmt to returning_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kInsertStmt_1, OP3("", "INSERT", "INTO"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $5;
        res = new IR(kInsertStmt_2, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $6;
        res = new IR(kInsertStmt_3, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp5 = $7;
        res = new IR(kInsertStmt_4, OP3("", "", ""), res, tmp5);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp6 = $8;
        res = new IR(kInsertStmt_5, OP3("", "", ""), res, tmp6);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp7 = $9;
        res = new IR(kInsertStmt, OP3("", "", ""), res, tmp7);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


insert_rest:

    SelectStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(253472,70058); // mapping from insert_rest to SelectStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kInsertRest, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | OVERRIDING override_kind VALUE_P SelectStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(253472,27736); // mapping from insert_rest to override_kind
        	gram_cov->log_edge_cov_map(253472,70058); // mapping from insert_rest to SelectStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kInsertRest, OP3("OVERRIDING", "VALUE", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '(' insert_column_list ')' SelectStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(253472,104521); // mapping from insert_rest to insert_column_list
        	gram_cov->log_edge_cov_map(253472,70058); // mapping from insert_rest to SelectStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kInsertRest, OP3("(", ")", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '(' insert_column_list ')' OVERRIDING override_kind VALUE_P SelectStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(253472,104521); // mapping from insert_rest to insert_column_list
        	gram_cov->log_edge_cov_map(253472,27736); // mapping from insert_rest to override_kind
        	gram_cov->log_edge_cov_map(253472,70058); // mapping from insert_rest to SelectStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $5;
        res = new IR(kInsertRest_1, OP3("(", ") OVERRIDING", "VALUE"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $7;
        res = new IR(kInsertRest, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | DEFAULT VALUES {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kInsertRest, OP3("DEFAULT VALUES", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


insert_target:

    qualified_name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(22099,38734); // mapping from insert_target to qualified_name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        setup_qualified_name(tmp1, kDataTableName, kUse, kDataDatabase, kDataWhatever); 
        res = new IR(kInsertTarget, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | qualified_name AS ColId {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(22099,38734); // mapping from insert_target to qualified_name
        	gram_cov->log_edge_cov_map(22099,133796); // mapping from insert_target to ColId
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        setup_qualified_name(tmp1, kDataTableName, kUse, kDataDatabase, kDataWhatever); 
        auto tmp2 = $3;
        setup_col_id(tmp2, kDataAliasTableName, kDefine); 
        res = new IR(kInsertTarget, OP3("", "AS", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_by_name_or_position:

    BY NAME_P {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptByNameOrPosition, OP3("BY NAME", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | BY POSITION {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptByNameOrPosition, OP3("BY POSITION", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptByNameOrPosition, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_conf_expr:

    '(' index_params ')' where_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(155860,97375); // mapping from opt_conf_expr to index_params
        	gram_cov->log_edge_cov_map(155860,16133); // mapping from opt_conf_expr to where_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kOptConfExpr, OP3("(", ")", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ON CONSTRAINT name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(155860,212908); // mapping from opt_conf_expr to name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        setup_name(tmp1, kDataConstraintName, kUse); 
        res = new IR(kOptConfExpr, OP3("ON CONSTRAINT", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptConfExpr, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_with_clause:

    with_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(74395,118320); // mapping from opt_with_clause to with_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kOptWithClause, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptWithClause, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


insert_column_item:

    ColId opt_indirection {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(75068,133796); // mapping from insert_column_item to ColId
        	gram_cov->log_edge_cov_map(75068,83135); // mapping from insert_column_item to opt_indirection
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        setup_col_id(tmp1, kDataColumnName, kUse); 
        auto tmp2 = $2;
        res = new IR(kInsertColumnItem, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


set_clause:

    set_target '=' a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(94340,10904); // mapping from set_clause to set_target
        	gram_cov->log_edge_cov_map(94340,53205); // mapping from set_clause to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSetClause, OP3("", "=", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '(' set_target_list ')' '=' a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(94340,223933); // mapping from set_clause to set_target_list
        	gram_cov->log_edge_cov_map(94340,53205); // mapping from set_clause to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $5;
        res = new IR(kSetClause, OP3("(", ") =", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_or_action:

    OR REPLACE {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptOrAction, OP3("OR REPLACE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | OR IGNORE_P {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptOrAction, OP3("OR IGNORE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptOrAction, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_on_conflict:

    ON CONFLICT opt_conf_expr DO UPDATE SET set_clause_list_opt_comma where_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(242786,155860); // mapping from opt_on_conflict to opt_conf_expr
        	gram_cov->log_edge_cov_map(242786,98100); // mapping from opt_on_conflict to set_clause_list_opt_comma
        	gram_cov->log_edge_cov_map(242786,16133); // mapping from opt_on_conflict to where_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        auto tmp2 = $7;
        res = new IR(kOptOnConflict_1, OP3("ON CONFLICT", "DO UPDATE SET", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $8;
        res = new IR(kOptOnConflict, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ON CONFLICT opt_conf_expr DO NOTHING {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(242786,155860); // mapping from opt_on_conflict to opt_conf_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kOptOnConflict, OP3("ON CONFLICT", "DO NOTHING", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptOnConflict, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


index_elem:

    ColId opt_collate opt_class opt_asc_desc opt_nulls_order {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(229755,133796); // mapping from index_elem to ColId
        	gram_cov->log_edge_cov_map(229755,254607); // mapping from index_elem to opt_collate
        	gram_cov->log_edge_cov_map(229755,9102); // mapping from index_elem to opt_class
        	gram_cov->log_edge_cov_map(229755,161558); // mapping from index_elem to opt_asc_desc
        	gram_cov->log_edge_cov_map(229755,80470); // mapping from index_elem to opt_nulls_order
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        setup_col_id(tmp1, kDataColumnName, kUse); 
        auto tmp2 = $2;
        res = new IR(kIndexElem_1, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $3;
        res = new IR(kIndexElem_2, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $4;
        res = new IR(kIndexElem_3, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp5 = $5;
        res = new IR(kIndexElem, OP3("", "", ""), res, tmp5);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | func_expr_windowless opt_collate opt_class opt_asc_desc opt_nulls_order {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(229755,18225); // mapping from index_elem to func_expr_windowless
        	gram_cov->log_edge_cov_map(229755,254607); // mapping from index_elem to opt_collate
        	gram_cov->log_edge_cov_map(229755,9102); // mapping from index_elem to opt_class
        	gram_cov->log_edge_cov_map(229755,161558); // mapping from index_elem to opt_asc_desc
        	gram_cov->log_edge_cov_map(229755,80470); // mapping from index_elem to opt_nulls_order
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kIndexElem_4, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $3;
        res = new IR(kIndexElem_5, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $4;
        res = new IR(kIndexElem_6, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp5 = $5;
        res = new IR(kIndexElem, OP3("", "", ""), res, tmp5);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '(' a_expr ')' opt_collate opt_class opt_asc_desc opt_nulls_order {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(229755,53205); // mapping from index_elem to a_expr
        	gram_cov->log_edge_cov_map(229755,254607); // mapping from index_elem to opt_collate
        	gram_cov->log_edge_cov_map(229755,9102); // mapping from index_elem to opt_class
        	gram_cov->log_edge_cov_map(229755,161558); // mapping from index_elem to opt_asc_desc
        	gram_cov->log_edge_cov_map(229755,80470); // mapping from index_elem to opt_nulls_order
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kIndexElem_7, OP3("(", ")", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $5;
        res = new IR(kIndexElem_8, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $6;
        res = new IR(kIndexElem_9, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp5 = $7;
        res = new IR(kIndexElem, OP3("", "", ""), res, tmp5);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


returning_clause:

    RETURNING target_list {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(132480,101266); // mapping from returning_clause to target_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kReturningClause, OP3("RETURNING", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kReturningClause, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


override_kind:

    USER {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOverrideKind, OP3("USER", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | SYSTEM_P {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOverrideKind, OP3("SYSTEM", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


set_target_list:

    set_target {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(223933,10904); // mapping from set_target_list to set_target
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kSetTargetList, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | set_target_list ',' set_target {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(223933,223933); // mapping from set_target_list to set_target_list
        	gram_cov->log_edge_cov_map(223933,10904); // mapping from set_target_list to set_target
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSetTargetList, OP3("", ",", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_collate:

    COLLATE any_name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(254607,38234); // mapping from opt_collate to any_name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        setup_any_name(tmp1, kDataCollate, kUse, kDataSchemaName, kDataDatabase); 
        res = new IR(kOptCollate, OP3("COLLATE", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptCollate, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_class:

    any_name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(9102,38234); // mapping from opt_class to any_name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        setup_any_name(tmp1, kDataCollate, kUse, kDataSchemaName, kDataDatabase); 
        res = new IR(kOptClass, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptClass, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


insert_column_list:

    insert_column_item {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(104521,75068); // mapping from insert_column_list to insert_column_item
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kInsertColumnList, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | insert_column_list ',' insert_column_item {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(104521,104521); // mapping from insert_column_list to insert_column_list
        	gram_cov->log_edge_cov_map(104521,75068); // mapping from insert_column_list to insert_column_item
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kInsertColumnList, OP3("", ",", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


set_clause_list:

    set_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(218419,94340); // mapping from set_clause_list to set_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kSetClauseList, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | set_clause_list ',' set_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(218419,218419); // mapping from set_clause_list to set_clause_list
        	gram_cov->log_edge_cov_map(218419,94340); // mapping from set_clause_list to set_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSetClauseList, OP3("", ",", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


set_clause_list_opt_comma:

    set_clause_list {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(98100,218419); // mapping from set_clause_list_opt_comma to set_clause_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kSetClauseListOptComma, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | set_clause_list ',' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(98100,218419); // mapping from set_clause_list_opt_comma to set_clause_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kSetClauseListOptComma, OP3("", ",", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


index_params:

    index_elem {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(97375,229755); // mapping from index_params to index_elem
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kIndexParams, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | index_params ',' index_elem {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(97375,97375); // mapping from index_params to index_params
        	gram_cov->log_edge_cov_map(97375,229755); // mapping from index_params to index_elem
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kIndexParams, OP3("", ",", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


set_target:

    ColId opt_indirection {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(10904,133796); // mapping from set_target to ColId
        	gram_cov->log_edge_cov_map(10904,83135); // mapping from set_target to opt_indirection
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        setup_col_id(tmp1, kDataPragmaKey, kUse); 
        auto tmp2 = $2;
        res = new IR(kSetTarget, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


CreateTypeStmt:

    CREATE_P TYPE_P qualified_name AS ENUM_P select_with_parens {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(103560,38734); // mapping from CreateTypeStmt to qualified_name
        	gram_cov->log_edge_cov_map(103560,178444); // mapping from CreateTypeStmt to select_with_parens
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        setup_qualified_name(tmp1, kDataTypeName, kDefine, kDataTableName, kDataDatabase); 
        auto tmp2 = $6;
        res = new IR(kCreateTypeStmt, OP3("CREATE TYPE", "AS ENUM", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CREATE_P TYPE_P qualified_name AS ENUM_P '(' opt_enum_val_list ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(103560,38734); // mapping from CreateTypeStmt to qualified_name
        	gram_cov->log_edge_cov_map(103560,216946); // mapping from CreateTypeStmt to opt_enum_val_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        setup_qualified_name(tmp1, kDataTypeName, kDefine, kDataTableName, kDataDatabase); 
        auto tmp2 = $7;
        res = new IR(kCreateTypeStmt, OP3("CREATE TYPE", "AS ENUM (", ")"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CREATE_P TYPE_P qualified_name AS Typename {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(103560,38734); // mapping from CreateTypeStmt to qualified_name
        	gram_cov->log_edge_cov_map(103560,237247); // mapping from CreateTypeStmt to Typename
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        setup_qualified_name(tmp1, kDataTypeName, kDefine, kDataTableName, kDataDatabase); 
        auto tmp2 = $5;
        res = new IR(kCreateTypeStmt, OP3("CREATE TYPE", "AS", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_enum_val_list:

    enum_val_list {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(216946,259865); // mapping from opt_enum_val_list to enum_val_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kOptEnumValList, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptEnumValList, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


enum_val_list:

    Sconst {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(259865,47445); // mapping from enum_val_list to Sconst
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kEnumValList, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | enum_val_list ',' Sconst {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(259865,259865); // mapping from enum_val_list to enum_val_list
        	gram_cov->log_edge_cov_map(259865,47445); // mapping from enum_val_list to Sconst
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kEnumValList, OP3("", ",", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


PragmaStmt:

    PRAGMA_P ColId {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(176050,133796); // mapping from PragmaStmt to ColId
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        setup_col_id(tmp1, kDataPragmaKey, kUse); 
        res = new IR(kPragmaStmt, OP3("PRAGMA", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | PRAGMA_P ColId '=' var_list {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(176050,133796); // mapping from PragmaStmt to ColId
        	gram_cov->log_edge_cov_map(176050,134748); // mapping from PragmaStmt to var_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        setup_col_id(tmp1, kDataPragmaKey, kUse); 
        auto tmp2 = $4;
        res = new IR(kPragmaStmt, OP3("PRAGMA", "=", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | PRAGMA_P ColId '(' func_arg_list ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(176050,133796); // mapping from PragmaStmt to ColId
        	gram_cov->log_edge_cov_map(176050,101501); // mapping from PragmaStmt to func_arg_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        setup_col_id(tmp1, kDataPragmaKey, kUse); 
        auto tmp2 = $4;
        res = new IR(kPragmaStmt, OP3("PRAGMA", "(", ")"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


CreateSeqStmt:

    CREATE_P OptTemp SEQUENCE qualified_name OptSeqOptList {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(206176,254974); // mapping from CreateSeqStmt to OptTemp
        	gram_cov->log_edge_cov_map(206176,38734); // mapping from CreateSeqStmt to qualified_name
        	gram_cov->log_edge_cov_map(206176,191173); // mapping from CreateSeqStmt to OptSeqOptList
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $4;
        setup_qualified_name(tmp2, kDataSequenceName, kDefine, kDataTableName, kDataDatabase); 
        res = new IR(kCreateSeqStmt_1, OP3("CREATE", "SEQUENCE", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $5;
        res = new IR(kCreateSeqStmt, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CREATE_P OptTemp SEQUENCE IF_P NOT EXISTS qualified_name OptSeqOptList {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(206176,254974); // mapping from CreateSeqStmt to OptTemp
        	gram_cov->log_edge_cov_map(206176,38734); // mapping from CreateSeqStmt to qualified_name
        	gram_cov->log_edge_cov_map(206176,191173); // mapping from CreateSeqStmt to OptSeqOptList
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $7;
        setup_qualified_name(tmp2, kDataSequenceName, kDefine, kDataTableName, kDataDatabase); 
        res = new IR(kCreateSeqStmt_2, OP3("CREATE", "SEQUENCE IF NOT EXISTS", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $8;
        res = new IR(kCreateSeqStmt, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CREATE_P OR REPLACE OptTemp SEQUENCE qualified_name OptSeqOptList {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(206176,254974); // mapping from CreateSeqStmt to OptTemp
        	gram_cov->log_edge_cov_map(206176,38734); // mapping from CreateSeqStmt to qualified_name
        	gram_cov->log_edge_cov_map(206176,191173); // mapping from CreateSeqStmt to OptSeqOptList
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $4;
        auto tmp2 = $6;
        setup_qualified_name(tmp2, kDataSequenceName, kDefine, kDataTableName, kDataDatabase); 
        res = new IR(kCreateSeqStmt_3, OP3("CREATE OR REPLACE", "SEQUENCE", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $7;
        res = new IR(kCreateSeqStmt, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


OptSeqOptList:

    SeqOptList {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(191173,209132); // mapping from OptSeqOptList to SeqOptList
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kOptSeqOptList, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptSeqOptList, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


ExecuteStmt:

    EXECUTE name execute_param_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(220282,212908); // mapping from ExecuteStmt to name
        	gram_cov->log_edge_cov_map(220282,202613); // mapping from ExecuteStmt to execute_param_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        setup_name(tmp1, kDataPrepareName, kUse); 
        auto tmp2 = $3;
        res = new IR(kExecuteStmt, OP3("EXECUTE", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CREATE_P OptTemp TABLE create_as_target AS EXECUTE name execute_param_clause opt_with_data {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(220282,254974); // mapping from ExecuteStmt to OptTemp
        	gram_cov->log_edge_cov_map(220282,173642); // mapping from ExecuteStmt to create_as_target
        	gram_cov->log_edge_cov_map(220282,212908); // mapping from ExecuteStmt to name
        	gram_cov->log_edge_cov_map(220282,202613); // mapping from ExecuteStmt to execute_param_clause
        	gram_cov->log_edge_cov_map(220282,27946); // mapping from ExecuteStmt to opt_with_data
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kExecuteStmt_1, OP3("CREATE", "TABLE", "AS EXECUTE"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $7;
        setup_name(tmp3, kDataPrepareName, kUse); 
        res = new IR(kExecuteStmt_2, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $8;
        res = new IR(kExecuteStmt_3, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp5 = $9;
        res = new IR(kExecuteStmt, OP3("", "", ""), res, tmp5);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CREATE_P OptTemp TABLE IF_P NOT EXISTS create_as_target AS EXECUTE name execute_param_clause opt_with_data {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(220282,254974); // mapping from ExecuteStmt to OptTemp
        	gram_cov->log_edge_cov_map(220282,173642); // mapping from ExecuteStmt to create_as_target
        	gram_cov->log_edge_cov_map(220282,212908); // mapping from ExecuteStmt to name
        	gram_cov->log_edge_cov_map(220282,202613); // mapping from ExecuteStmt to execute_param_clause
        	gram_cov->log_edge_cov_map(220282,27946); // mapping from ExecuteStmt to opt_with_data
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $7;
        res = new IR(kExecuteStmt_4, OP3("CREATE", "TABLE IF NOT EXISTS", "AS EXECUTE"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $10;
        setup_name(tmp3, kDataPrepareName, kUse); 
        res = new IR(kExecuteStmt_5, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $11;
        res = new IR(kExecuteStmt_6, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp5 = $12;
        res = new IR(kExecuteStmt, OP3("", "", ""), res, tmp5);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


execute_param_expr:

    a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(119671,53205); // mapping from execute_param_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExecuteParamExpr, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | param_name COLON_EQUALS a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(119671,911); // mapping from execute_param_expr to param_name
        	gram_cov->log_edge_cov_map(119671,53205); // mapping from execute_param_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kExecuteParamExpr, OP3("", "COLON_EQUALS", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


execute_param_list:

    execute_param_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(19865,119671); // mapping from execute_param_list to execute_param_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExecuteParamList, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | execute_param_list ',' execute_param_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(19865,19865); // mapping from execute_param_list to execute_param_list
        	gram_cov->log_edge_cov_map(19865,119671); // mapping from execute_param_list to execute_param_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kExecuteParamList, OP3("", ",", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


execute_param_clause:

    '(' execute_param_list ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(202613,19865); // mapping from execute_param_clause to execute_param_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kExecuteParamClause, OP3("(", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kExecuteParamClause, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


AlterSeqStmt:

    ALTER SEQUENCE qualified_name SeqOptList {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53506,38734); // mapping from AlterSeqStmt to qualified_name
        	gram_cov->log_edge_cov_map(53506,209132); // mapping from AlterSeqStmt to SeqOptList
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        setup_qualified_name(tmp1, kDataSequenceName, kUse, kDataTableName, kDataDatabase); 
        auto tmp2 = $4;
        res = new IR(kAlterSeqStmt, OP3("ALTER SEQUENCE", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ALTER SEQUENCE IF_P EXISTS qualified_name SeqOptList {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53506,38734); // mapping from AlterSeqStmt to qualified_name
        	gram_cov->log_edge_cov_map(53506,209132); // mapping from AlterSeqStmt to SeqOptList
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $5;
        setup_qualified_name(tmp1, kDataSequenceName, kUse, kDataTableName, kDataDatabase); 
        auto tmp2 = $6;
        res = new IR(kAlterSeqStmt, OP3("ALTER SEQUENCE IF EXISTS", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


SeqOptList:

    SeqOptElem {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(209132,212902); // mapping from SeqOptList to SeqOptElem
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kSeqOptList, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | SeqOptList SeqOptElem {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(209132,209132); // mapping from SeqOptList to SeqOptList
        	gram_cov->log_edge_cov_map(209132,212902); // mapping from SeqOptList to SeqOptElem
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSeqOptList, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_with:

    WITH {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptWith, OP3("WITH", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | WITH_LA {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptWith, OP3("WITH", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptWith, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


NumericOnly:

    FCONST {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(146194,128351); // mapping from NumericOnly to FCONST
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = new IR(kFloatLiteral, cstr_to_string($1), kDataFixLater, kFlagUnknown);
        std::shared_ptr<IR> p_tmp1(tmp1, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_tmp1);
        res = new IR(kNumericOnly, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '+' FCONST {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(146194,128351); // mapping from NumericOnly to FCONST
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = new IR(kFloatLiteral, cstr_to_string($2), kDataFixLater, kFlagUnknown);
        std::shared_ptr<IR> p_tmp1(tmp1, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_tmp1);
        res = new IR(kNumericOnly, OP3("+", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '-' FCONST {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(146194,128351); // mapping from NumericOnly to FCONST
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = new IR(kFloatLiteral, cstr_to_string($2), kDataFixLater, kFlagUnknown);
        std::shared_ptr<IR> p_tmp1(tmp1, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_tmp1);
        res = new IR(kNumericOnly, OP3("-", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | SignedIconst {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(146194,250694); // mapping from NumericOnly to SignedIconst
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kNumericOnly, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


SeqOptElem:

    AS SimpleTypename {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(212902,202278); // mapping from SeqOptElem to SimpleTypename
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kSeqOptElem, OP3("AS", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CACHE NumericOnly {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(212902,146194); // mapping from SeqOptElem to NumericOnly
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kSeqOptElem, OP3("CACHE", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CYCLE {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kSeqOptElem, OP3("CYCLE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | NO CYCLE {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kSeqOptElem, OP3("NO CYCLE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | INCREMENT opt_by NumericOnly {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(212902,98258); // mapping from SeqOptElem to opt_by
        	gram_cov->log_edge_cov_map(212902,146194); // mapping from SeqOptElem to NumericOnly
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSeqOptElem, OP3("INCREMENT", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | MAXVALUE NumericOnly {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(212902,146194); // mapping from SeqOptElem to NumericOnly
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kSeqOptElem, OP3("MAXVALUE", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | MINVALUE NumericOnly {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(212902,146194); // mapping from SeqOptElem to NumericOnly
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kSeqOptElem, OP3("MINVALUE", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | NO MAXVALUE {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kSeqOptElem, OP3("NO MAXVALUE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | NO MINVALUE {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kSeqOptElem, OP3("NO MINVALUE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | OWNED BY any_name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(212902,38234); // mapping from SeqOptElem to any_name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        setup_any_name(tmp1, kDataCollate, kUse, kDataSchemaName, kDataDatabase); 
        res = new IR(kSeqOptElem, OP3("OWNED BY", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | SEQUENCE NAME_P any_name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(212902,38234); // mapping from SeqOptElem to any_name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        setup_any_name(tmp1, kDataCollate, kUse, kDataSchemaName, kDataDatabase); 
        res = new IR(kSeqOptElem, OP3("SEQUENCE NAME", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | START opt_with NumericOnly {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(212902,142489); // mapping from SeqOptElem to opt_with
        	gram_cov->log_edge_cov_map(212902,146194); // mapping from SeqOptElem to NumericOnly
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSeqOptElem, OP3("START", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | RESTART {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kSeqOptElem, OP3("RESTART", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | RESTART opt_with NumericOnly {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(212902,142489); // mapping from SeqOptElem to opt_with
        	gram_cov->log_edge_cov_map(212902,146194); // mapping from SeqOptElem to NumericOnly
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSeqOptElem, OP3("RESTART", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_by:

    BY {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptBy, OP3("BY", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptBy, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


SignedIconst:

    Iconst {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(250694,255753); // mapping from SignedIconst to Iconst
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kSignedIconst, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '+' Iconst {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(250694,255753); // mapping from SignedIconst to Iconst
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kSignedIconst, OP3("+", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '-' Iconst {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(250694,255753); // mapping from SignedIconst to Iconst
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kSignedIconst, OP3("-", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


TransactionStmt:

    ABORT_P opt_transaction {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(171693,147157); // mapping from TransactionStmt to opt_transaction
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kTransactionStmt, OP3("ABORT", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | BEGIN_P opt_transaction {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(171693,147157); // mapping from TransactionStmt to opt_transaction
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kTransactionStmt, OP3("BEGIN", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | START opt_transaction {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(171693,147157); // mapping from TransactionStmt to opt_transaction
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kTransactionStmt, OP3("START", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | COMMIT opt_transaction {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(171693,147157); // mapping from TransactionStmt to opt_transaction
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kTransactionStmt, OP3("COMMIT", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | END_P opt_transaction {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(171693,147157); // mapping from TransactionStmt to opt_transaction
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kTransactionStmt, OP3("END", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ROLLBACK opt_transaction {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(171693,147157); // mapping from TransactionStmt to opt_transaction
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kTransactionStmt, OP3("ROLLBACK", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_transaction:

    WORK {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptTransaction, OP3("WORK", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | TRANSACTION {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptTransaction, OP3("TRANSACTION", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptTransaction, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


UseStmt:

    USE_P qualified_name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(92978,38734); // mapping from UseStmt to qualified_name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        setup_qualified_name(tmp1, kDataSchemaName, kUse, kDataDatabase, kDataWhatever); 
        res = new IR(kUseStmt, OP3("USE", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


CreateStmt:

    CREATE_P OptTemp TABLE qualified_name '(' OptTableElementList ')' OptWith OnCommitOption {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(139905,254974); // mapping from CreateStmt to OptTemp
        	gram_cov->log_edge_cov_map(139905,38734); // mapping from CreateStmt to qualified_name
        	gram_cov->log_edge_cov_map(139905,151754); // mapping from CreateStmt to OptTableElementList
        	gram_cov->log_edge_cov_map(139905,68169); // mapping from CreateStmt to OptWith
        	gram_cov->log_edge_cov_map(139905,141669); // mapping from CreateStmt to OnCommitOption
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $4;
        setup_qualified_name(tmp2, kDataTableName, kDefine, kDataSchemaName, kDataDatabase); 
        res = new IR(kCreateStmt_1, OP3("CREATE", "TABLE", "("), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $6;
        res = new IR(kCreateStmt_2, OP3("", "", ")"), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $8;
        res = new IR(kCreateStmt_3, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp5 = $9;
        res = new IR(kCreateStmt, OP3("", "", ""), res, tmp5);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CREATE_P OptTemp TABLE IF_P NOT EXISTS qualified_name '(' OptTableElementList ')' OptWith OnCommitOption {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(139905,254974); // mapping from CreateStmt to OptTemp
        	gram_cov->log_edge_cov_map(139905,38734); // mapping from CreateStmt to qualified_name
        	gram_cov->log_edge_cov_map(139905,151754); // mapping from CreateStmt to OptTableElementList
        	gram_cov->log_edge_cov_map(139905,68169); // mapping from CreateStmt to OptWith
        	gram_cov->log_edge_cov_map(139905,141669); // mapping from CreateStmt to OnCommitOption
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $7;
        setup_qualified_name(tmp2, kDataTableName, kDefine, kDataSchemaName, kDataDatabase); 
        res = new IR(kCreateStmt_4, OP3("CREATE", "TABLE IF NOT EXISTS", "("), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $9;
        res = new IR(kCreateStmt_5, OP3("", "", ")"), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $11;
        res = new IR(kCreateStmt_6, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp5 = $12;
        res = new IR(kCreateStmt, OP3("", "", ""), res, tmp5);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CREATE_P OR REPLACE OptTemp TABLE qualified_name '(' OptTableElementList ')' OptWith OnCommitOption {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(139905,254974); // mapping from CreateStmt to OptTemp
        	gram_cov->log_edge_cov_map(139905,38734); // mapping from CreateStmt to qualified_name
        	gram_cov->log_edge_cov_map(139905,151754); // mapping from CreateStmt to OptTableElementList
        	gram_cov->log_edge_cov_map(139905,68169); // mapping from CreateStmt to OptWith
        	gram_cov->log_edge_cov_map(139905,141669); // mapping from CreateStmt to OnCommitOption
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $4;
        auto tmp2 = $6;
        setup_qualified_name(tmp2, kDataTableName, kDefine, kDataSchemaName, kDataDatabase); 
        res = new IR(kCreateStmt_7, OP3("CREATE OR REPLACE", "TABLE", "("), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $8;
        res = new IR(kCreateStmt_8, OP3("", "", ")"), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $10;
        res = new IR(kCreateStmt_9, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp5 = $11;
        res = new IR(kCreateStmt, OP3("", "", ""), res, tmp5);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


ConstraintAttributeSpec:

    /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kConstraintAttributeSpec, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ConstraintAttributeSpec ConstraintAttributeElem {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(220122,220122); // mapping from ConstraintAttributeSpec to ConstraintAttributeSpec
        	gram_cov->log_edge_cov_map(220122,219009); // mapping from ConstraintAttributeSpec to ConstraintAttributeElem
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kConstraintAttributeSpec, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


def_arg:

    func_type {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(90650,34833); // mapping from def_arg to func_type
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kDefArg, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | qual_all_Op {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(90650,33650); // mapping from def_arg to qual_all_Op
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kDefArg, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | NumericOnly {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(90650,146194); // mapping from def_arg to NumericOnly
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kDefArg, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | Sconst {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(90650,47445); // mapping from def_arg to Sconst
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kDefArg, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | NONE {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kDefArg, OP3("NONE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


OptParenthesizedSeqOptList:

    '(' SeqOptList ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(259050,209132); // mapping from OptParenthesizedSeqOptList to SeqOptList
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kOptParenthesizedSeqOptList, OP3("(", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptParenthesizedSeqOptList, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


generic_option_arg:

    Sconst {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(143085,47445); // mapping from generic_option_arg to Sconst
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kGenericOptionArg, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


key_action:

    NO ACTION {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kKeyAction, OP3("NO ACTION", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | RESTRICT {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kKeyAction, OP3("RESTRICT", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CASCADE {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kKeyAction, OP3("CASCADE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | SET NULL_P {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kKeyAction, OP3("SET NULL", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | SET DEFAULT {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kKeyAction, OP3("SET DEFAULT", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


ColConstraint:

    CONSTRAINT name ColConstraintElem {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(212171,212908); // mapping from ColConstraint to name
        	gram_cov->log_edge_cov_map(212171,126436); // mapping from ColConstraint to ColConstraintElem
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        setup_name(tmp1, kDataConstraintName, kUse); 
        auto tmp2 = $3;
        res = new IR(kColConstraint, OP3("CONSTRAINT", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ColConstraintElem {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(212171,126436); // mapping from ColConstraint to ColConstraintElem
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kColConstraint, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ConstraintAttr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(212171,205743); // mapping from ColConstraint to ConstraintAttr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kColConstraint, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | COLLATE any_name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(212171,38234); // mapping from ColConstraint to any_name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        setup_any_name(tmp1, kDataCollate, kUse, kDataSchemaName, kDataDatabase); 
        res = new IR(kColConstraint, OP3("COLLATE", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


ColConstraintElem:

    NOT NULL_P {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kColConstraintElem, OP3("NOT NULL", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | NULL_P {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kColConstraintElem, OP3("NULL", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | UNIQUE opt_definition {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(126436,151483); // mapping from ColConstraintElem to opt_definition
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kColConstraintElem, OP3("UNIQUE", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | PRIMARY KEY opt_definition {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(126436,151483); // mapping from ColConstraintElem to opt_definition
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kColConstraintElem, OP3("PRIMARY KEY", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CHECK_P '(' a_expr ')' opt_no_inherit {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(126436,53205); // mapping from ColConstraintElem to a_expr
        	gram_cov->log_edge_cov_map(126436,22108); // mapping from ColConstraintElem to opt_no_inherit
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kColConstraintElem, OP3("CHECK (", ")", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | USING COMPRESSION name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(126436,212908); // mapping from ColConstraintElem to name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        setup_name(tmp1, kDataCompressionName, kUse); 
        res = new IR(kColConstraintElem, OP3("USING COMPRESSION", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | DEFAULT b_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(126436,25763); // mapping from ColConstraintElem to b_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kColConstraintElem, OP3("DEFAULT", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | REFERENCES qualified_name opt_column_list key_match key_actions {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(126436,38734); // mapping from ColConstraintElem to qualified_name
        	gram_cov->log_edge_cov_map(126436,193852); // mapping from ColConstraintElem to opt_column_list
        	gram_cov->log_edge_cov_map(126436,96762); // mapping from ColConstraintElem to key_match
        	gram_cov->log_edge_cov_map(126436,9781); // mapping from ColConstraintElem to key_actions
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        setup_qualified_name(tmp1, kDataTableName, kUse, kDataSchemaName, kDataDatabase); 
        auto tmp2 = $3;
        setup_opt_column_list(tmp2, kDataColumnName, kUse); 
        res = new IR(kColConstraintElem_1, OP3("REFERENCES", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $4;
        res = new IR(kColConstraintElem_2, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $5;
        res = new IR(kColConstraintElem, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


GeneratedColumnType:

    VIRTUAL {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kGeneratedColumnType, OP3("VIRTUAL", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | STORED {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kGeneratedColumnType, OP3("STORED", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_GeneratedColumnType:

    GeneratedColumnType {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(80528,195321); // mapping from opt_GeneratedColumnType to GeneratedColumnType
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kOptGeneratedColumnType, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptGeneratedColumnType, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


GeneratedConstraintElem:

    GENERATED generated_when AS IDENTITY_P OptParenthesizedSeqOptList {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(114780,253387); // mapping from GeneratedConstraintElem to generated_when
        	gram_cov->log_edge_cov_map(114780,259050); // mapping from GeneratedConstraintElem to OptParenthesizedSeqOptList
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $5;
        res = new IR(kGeneratedConstraintElem, OP3("GENERATED", "AS IDENTITY", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | GENERATED generated_when AS '(' a_expr ')' opt_GeneratedColumnType {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(114780,253387); // mapping from GeneratedConstraintElem to generated_when
        	gram_cov->log_edge_cov_map(114780,53205); // mapping from GeneratedConstraintElem to a_expr
        	gram_cov->log_edge_cov_map(114780,80528); // mapping from GeneratedConstraintElem to opt_GeneratedColumnType
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $5;
        res = new IR(kGeneratedConstraintElem_1, OP3("GENERATED", "AS (", ")"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $7;
        res = new IR(kGeneratedConstraintElem, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | AS '(' a_expr ')' opt_GeneratedColumnType {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(114780,53205); // mapping from GeneratedConstraintElem to a_expr
        	gram_cov->log_edge_cov_map(114780,80528); // mapping from GeneratedConstraintElem to opt_GeneratedColumnType
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kGeneratedConstraintElem, OP3("AS (", ")", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


generic_option_elem:

    generic_option_name generic_option_arg {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(209686,180136); // mapping from generic_option_elem to generic_option_name
        	gram_cov->log_edge_cov_map(209686,143085); // mapping from generic_option_elem to generic_option_arg
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kGenericOptionElem, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


key_update:

    ON UPDATE key_action {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(140454,141925); // mapping from key_update to key_action
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kKeyUpdate, OP3("ON UPDATE", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


key_actions:

    key_update {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(9781,140454); // mapping from key_actions to key_update
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kKeyActions, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | key_delete {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(9781,105456); // mapping from key_actions to key_delete
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kKeyActions, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | key_update key_delete {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(9781,140454); // mapping from key_actions to key_update
        	gram_cov->log_edge_cov_map(9781,105456); // mapping from key_actions to key_delete
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kKeyActions, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | key_delete key_update {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(9781,105456); // mapping from key_actions to key_delete
        	gram_cov->log_edge_cov_map(9781,140454); // mapping from key_actions to key_update
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kKeyActions, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kKeyActions, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


OnCommitOption:

    ON COMMIT DROP {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOnCommitOption, OP3("ON COMMIT DROP", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ON COMMIT DELETE_P ROWS {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOnCommitOption, OP3("ON COMMIT DELETE ROWS", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ON COMMIT PRESERVE ROWS {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOnCommitOption, OP3("ON COMMIT PRESERVE ROWS", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOnCommitOption, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


reloptions:

    '(' reloption_list ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(68978,33970); // mapping from reloptions to reloption_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kReloptions, OP3("(", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_no_inherit:

    NO INHERIT {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptNoInherit, OP3("NO INHERIT", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptNoInherit, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


TableConstraint:

    CONSTRAINT name ConstraintElem {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(70763,212908); // mapping from TableConstraint to name
        	gram_cov->log_edge_cov_map(70763,257578); // mapping from TableConstraint to ConstraintElem
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        setup_name(tmp1, kDataConstraintName, kUse); 
        auto tmp2 = $3;
        res = new IR(kTableConstraint, OP3("CONSTRAINT", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ConstraintElem {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(70763,257578); // mapping from TableConstraint to ConstraintElem
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kTableConstraint, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


TableLikeOption:

    COMMENTS {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kTableLikeOption, OP3("COMMENTS", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CONSTRAINTS {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kTableLikeOption, OP3("CONSTRAINTS", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | DEFAULTS {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kTableLikeOption, OP3("DEFAULTS", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | IDENTITY_P {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kTableLikeOption, OP3("IDENTITY", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | INDEXES {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kTableLikeOption, OP3("INDEXES", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | STATISTICS {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kTableLikeOption, OP3("STATISTICS", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | STORAGE {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kTableLikeOption, OP3("STORAGE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ALL {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kTableLikeOption, OP3("ALL", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


reloption_list:

    reloption_elem {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(33970,164080); // mapping from reloption_list to reloption_elem
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kReloptionList, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | reloption_list ',' reloption_elem {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(33970,33970); // mapping from reloption_list to reloption_list
        	gram_cov->log_edge_cov_map(33970,164080); // mapping from reloption_list to reloption_elem
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kReloptionList, OP3("", ",", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


ExistingIndex:

    USING INDEX index_name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(175389,236172); // mapping from ExistingIndex to index_name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        setup_index_name(tmp1, kDataIndexName, kUse); 
        res = new IR(kExistingIndex, OP3("USING INDEX", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


ConstraintAttr:

    DEFERRABLE {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kConstraintAttr, OP3("DEFERRABLE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | NOT DEFERRABLE {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kConstraintAttr, OP3("NOT DEFERRABLE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | INITIALLY DEFERRED {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kConstraintAttr, OP3("INITIALLY DEFERRED", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | INITIALLY IMMEDIATE {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kConstraintAttr, OP3("INITIALLY IMMEDIATE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


OptWith:

    WITH reloptions {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(68169,68978); // mapping from OptWith to reloptions
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kOptWith, OP3("WITH", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | WITH OIDS {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptWith, OP3("WITH OIDS", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | WITHOUT OIDS {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptWith, OP3("WITHOUT OIDS", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptWith, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


definition:

    '(' def_list ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(16599,185664); // mapping from definition to def_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kDefinition, OP3("(", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


TableLikeOptionList:

    TableLikeOptionList INCLUDING TableLikeOption {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(167197,167197); // mapping from TableLikeOptionList to TableLikeOptionList
        	gram_cov->log_edge_cov_map(167197,56037); // mapping from TableLikeOptionList to TableLikeOption
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTableLikeOptionList, OP3("", "INCLUDING", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | TableLikeOptionList EXCLUDING TableLikeOption {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(167197,167197); // mapping from TableLikeOptionList to TableLikeOptionList
        	gram_cov->log_edge_cov_map(167197,56037); // mapping from TableLikeOptionList to TableLikeOption
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTableLikeOptionList, OP3("", "EXCLUDING", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kTableLikeOptionList, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


generic_option_name:

    ColLabel {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(180136,197766); // mapping from generic_option_name to ColLabel
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kGenericOptionName, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


ConstraintAttributeElem:

    NOT DEFERRABLE {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kConstraintAttributeElem, OP3("NOT DEFERRABLE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | DEFERRABLE {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kConstraintAttributeElem, OP3("DEFERRABLE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | INITIALLY IMMEDIATE {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kConstraintAttributeElem, OP3("INITIALLY IMMEDIATE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | INITIALLY DEFERRED {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kConstraintAttributeElem, OP3("INITIALLY DEFERRED", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | NOT VALID {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kConstraintAttributeElem, OP3("NOT VALID", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | NO INHERIT {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kConstraintAttributeElem, OP3("NO INHERIT", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


columnDef:

    ColId Typename ColQualList {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(252287,133796); // mapping from columnDef to ColId
        	gram_cov->log_edge_cov_map(252287,237247); // mapping from columnDef to Typename
        	gram_cov->log_edge_cov_map(252287,220111); // mapping from columnDef to ColQualList
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        setup_col_id(tmp1, kDataColumnName, kDefine); 
        auto tmp2 = $2;
        res = new IR(kColumnDef_1, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $3;
        res = new IR(kColumnDef, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ColId opt_Typename GeneratedConstraintElem ColQualList {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(252287,133796); // mapping from columnDef to ColId
        	gram_cov->log_edge_cov_map(252287,54285); // mapping from columnDef to opt_Typename
        	gram_cov->log_edge_cov_map(252287,114780); // mapping from columnDef to GeneratedConstraintElem
        	gram_cov->log_edge_cov_map(252287,220111); // mapping from columnDef to ColQualList
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        setup_col_id(tmp1, kDataColumnName, kDefine); 
        auto tmp2 = $2;
        res = new IR(kColumnDef_2, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $3;
        res = new IR(kColumnDef_3, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $4;
        res = new IR(kColumnDef, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


def_list:

    def_elem {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(185664,125545); // mapping from def_list to def_elem
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kDefList, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | def_list ',' def_elem {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(185664,185664); // mapping from def_list to def_list
        	gram_cov->log_edge_cov_map(185664,125545); // mapping from def_list to def_elem
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kDefList, OP3("", ",", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


index_name:

    ColId {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(236172,133796); // mapping from index_name to ColId
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kIndexName, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


TableElement:

    columnDef {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(193673,252287); // mapping from TableElement to columnDef
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kTableElement, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | TableLikeClause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(193673,243892); // mapping from TableElement to TableLikeClause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kTableElement, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | TableConstraint {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(193673,70763); // mapping from TableElement to TableConstraint
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kTableElement, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


def_elem:

    ColLabel '=' def_arg {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(125545,197766); // mapping from def_elem to ColLabel
        	gram_cov->log_edge_cov_map(125545,90650); // mapping from def_elem to def_arg
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        setup_col_label(tmp1, kDataColumnName, kUse); 
        auto tmp2 = $3;
        res = new IR(kDefElem, OP3("", "=", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ColLabel {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(125545,197766); // mapping from def_elem to ColLabel
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        setup_col_label(tmp1, kDataColumnName, kUse); 
        res = new IR(kDefElem, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_definition:

    WITH definition {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(151483,16599); // mapping from opt_definition to definition
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kOptDefinition, OP3("WITH", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptDefinition, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


OptTableElementList:

    TableElementList {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(151754,85176); // mapping from OptTableElementList to TableElementList
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kOptTableElementList, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | TableElementList ',' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(151754,85176); // mapping from OptTableElementList to TableElementList
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kOptTableElementList, OP3("", ",", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptTableElementList, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


columnElem:

    ColId {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(130670,133796); // mapping from columnElem to ColId
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kColumnElem, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_column_list:

    '(' columnList ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(193852,63969); // mapping from opt_column_list to columnList
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kOptColumnList, OP3("(", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptColumnList, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


ColQualList:

    ColQualList ColConstraint {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(220111,220111); // mapping from ColQualList to ColQualList
        	gram_cov->log_edge_cov_map(220111,212171); // mapping from ColQualList to ColConstraint
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kColQualList, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kColQualList, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


key_delete:

    ON DELETE_P key_action {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(105456,141925); // mapping from key_delete to key_action
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kKeyDelete, OP3("ON DELETE", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


reloption_elem:

    ColLabel '=' def_arg {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(164080,197766); // mapping from reloption_elem to ColLabel
        	gram_cov->log_edge_cov_map(164080,90650); // mapping from reloption_elem to def_arg
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        setup_col_label(tmp1, kDataReloptionName, kUse); 
        auto tmp2 = $3;
        res = new IR(kReloptionElem, OP3("", "=", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ColLabel {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(164080,197766); // mapping from reloption_elem to ColLabel
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        setup_col_label(tmp1, kDataReloptionName, kUse); 
        res = new IR(kReloptionElem, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ColLabel '.' ColLabel '=' def_arg {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(164080,197766); // mapping from reloption_elem to ColLabel
        	gram_cov->log_edge_cov_map(164080,90650); // mapping from reloption_elem to def_arg
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        setup_col_label(tmp1, kDataReloptionName, kUse); 
        auto tmp2 = $3;
        setup_col_label(tmp2, kDataReloptionName, kUse); 
        res = new IR(kReloptionElem_1, OP3("", ".", "="), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $5;
        res = new IR(kReloptionElem, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ColLabel '.' ColLabel {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(164080,197766); // mapping from reloption_elem to ColLabel
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        setup_col_label(tmp1, kDataReloptionName, kUse); 
        auto tmp2 = $3;
        setup_col_label(tmp2, kDataReloptionName, kUse); 
        res = new IR(kReloptionElem, OP3("", ".", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


columnList:

    columnElem {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(63969,130670); // mapping from columnList to columnElem
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kColumnList, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | columnList ',' columnElem {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(63969,63969); // mapping from columnList to columnList
        	gram_cov->log_edge_cov_map(63969,130670); // mapping from columnList to columnElem
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kColumnList, OP3("", ",", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


columnList_opt_comma:

    columnList {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(187703,63969); // mapping from columnList_opt_comma to columnList
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        setup_column_list(tmp1, kDataColumnName, kUse); 
        res = new IR(kColumnListOptComma, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | columnList ',' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(187703,63969); // mapping from columnList_opt_comma to columnList
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        setup_column_list(tmp1, kDataColumnName, kUse); 
        res = new IR(kColumnListOptComma, OP3("", ",", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


func_type:

    Typename {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(34833,237247); // mapping from func_type to Typename
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kFuncType, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | type_function_name attrs '%' TYPE_P {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(34833,135898); // mapping from func_type to type_function_name
        	gram_cov->log_edge_cov_map(34833,56910); // mapping from func_type to attrs
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFuncType, OP3("", "", "% TYPE"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | SETOF type_function_name attrs '%' TYPE_P {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(34833,135898); // mapping from func_type to type_function_name
        	gram_cov->log_edge_cov_map(34833,56910); // mapping from func_type to attrs
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kFuncType, OP3("SETOF", "", "% TYPE"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


ConstraintElem:

    CHECK_P '(' a_expr ')' ConstraintAttributeSpec {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(257578,53205); // mapping from ConstraintElem to a_expr
        	gram_cov->log_edge_cov_map(257578,220122); // mapping from ConstraintElem to ConstraintAttributeSpec
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kConstraintElem, OP3("CHECK (", ")", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | UNIQUE '(' columnList_opt_comma ')' opt_definition ConstraintAttributeSpec {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(257578,187703); // mapping from ConstraintElem to columnList_opt_comma
        	gram_cov->log_edge_cov_map(257578,151483); // mapping from ConstraintElem to opt_definition
        	gram_cov->log_edge_cov_map(257578,220122); // mapping from ConstraintElem to ConstraintAttributeSpec
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kConstraintElem_1, OP3("UNIQUE (", ")", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $6;
        res = new IR(kConstraintElem, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | UNIQUE ExistingIndex ConstraintAttributeSpec {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(257578,175389); // mapping from ConstraintElem to ExistingIndex
        	gram_cov->log_edge_cov_map(257578,220122); // mapping from ConstraintElem to ConstraintAttributeSpec
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kConstraintElem, OP3("UNIQUE", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | PRIMARY KEY '(' columnList_opt_comma ')' opt_definition ConstraintAttributeSpec {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(257578,187703); // mapping from ConstraintElem to columnList_opt_comma
        	gram_cov->log_edge_cov_map(257578,151483); // mapping from ConstraintElem to opt_definition
        	gram_cov->log_edge_cov_map(257578,220122); // mapping from ConstraintElem to ConstraintAttributeSpec
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kConstraintElem_2, OP3("PRIMARY KEY (", ")", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $7;
        res = new IR(kConstraintElem, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | PRIMARY KEY ExistingIndex ConstraintAttributeSpec {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(257578,175389); // mapping from ConstraintElem to ExistingIndex
        	gram_cov->log_edge_cov_map(257578,220122); // mapping from ConstraintElem to ConstraintAttributeSpec
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kConstraintElem, OP3("PRIMARY KEY", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | FOREIGN KEY '(' columnList_opt_comma ')' REFERENCES qualified_name opt_column_list key_match key_actions ConstraintAttributeSpec {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(257578,187703); // mapping from ConstraintElem to columnList_opt_comma
        	gram_cov->log_edge_cov_map(257578,38734); // mapping from ConstraintElem to qualified_name
        	gram_cov->log_edge_cov_map(257578,193852); // mapping from ConstraintElem to opt_column_list
        	gram_cov->log_edge_cov_map(257578,96762); // mapping from ConstraintElem to key_match
        	gram_cov->log_edge_cov_map(257578,9781); // mapping from ConstraintElem to key_actions
        	gram_cov->log_edge_cov_map(257578,220122); // mapping from ConstraintElem to ConstraintAttributeSpec
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $4;
        auto tmp2 = $7;
        setup_qualified_name(tmp2, kDataTableName, kUse, kDataSchemaName, kDataDatabase); 
        res = new IR(kConstraintElem_3, OP3("FOREIGN KEY (", ") REFERENCES", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $8;
        setup_opt_column_list(tmp3, kDataColumnName, kUse); 
        res = new IR(kConstraintElem_4, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $9;
        res = new IR(kConstraintElem_5, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp5 = $10;
        res = new IR(kConstraintElem_6, OP3("", "", ""), res, tmp5);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp6 = $11;
        res = new IR(kConstraintElem, OP3("", "", ""), res, tmp6);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


TableElementList:

    TableElement {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(85176,193673); // mapping from TableElementList to TableElement
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kTableElementList, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | TableElementList ',' TableElement {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(85176,85176); // mapping from TableElementList to TableElementList
        	gram_cov->log_edge_cov_map(85176,193673); // mapping from TableElementList to TableElement
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTableElementList, OP3("", ",", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


key_match:

    MATCH FULL {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kKeyMatch, OP3("MATCH FULL", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | MATCH PARTIAL {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kKeyMatch, OP3("MATCH PARTIAL", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | MATCH SIMPLE {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kKeyMatch, OP3("MATCH SIMPLE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kKeyMatch, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


TableLikeClause:

    LIKE qualified_name TableLikeOptionList {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(243892,38734); // mapping from TableLikeClause to qualified_name
        	gram_cov->log_edge_cov_map(243892,167197); // mapping from TableLikeClause to TableLikeOptionList
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        setup_qualified_name(tmp1, kDataTableName, kUse, kDataSchemaName, kDataDatabase); 
        auto tmp2 = $3;
        res = new IR(kTableLikeClause, OP3("LIKE", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


OptTemp:

    TEMPORARY {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptTemp, OP3("TEMPORARY", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | TEMP {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptTemp, OP3("TEMP", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | LOCAL TEMPORARY {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptTemp, OP3("LOCAL TEMPORARY", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | LOCAL TEMP {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptTemp, OP3("LOCAL TEMP", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | GLOBAL TEMPORARY {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptTemp, OP3("GLOBAL TEMPORARY", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | GLOBAL TEMP {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptTemp, OP3("GLOBAL TEMP", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | UNLOGGED {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptTemp, OP3("UNLOGGED", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptTemp, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


generated_when:

    ALWAYS {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kGeneratedWhen, OP3("ALWAYS", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | BY DEFAULT {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kGeneratedWhen, OP3("BY DEFAULT", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


DropStmt:

    DROP drop_type_any_name IF_P EXISTS any_name_list opt_drop_behavior {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53483,259957); // mapping from DropStmt to drop_type_any_name
        	gram_cov->log_edge_cov_map(53483,177966); // mapping from DropStmt to any_name_list
        	gram_cov->log_edge_cov_map(53483,207372); // mapping from DropStmt to opt_drop_behavior
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $5;
        res = new IR(kDropStmt_1, OP3("DROP", "IF EXISTS", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $6;
        res = new IR(kDropStmt, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | DROP drop_type_any_name any_name_list opt_drop_behavior {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53483,259957); // mapping from DropStmt to drop_type_any_name
        	gram_cov->log_edge_cov_map(53483,177966); // mapping from DropStmt to any_name_list
        	gram_cov->log_edge_cov_map(53483,207372); // mapping from DropStmt to opt_drop_behavior
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kDropStmt_2, OP3("DROP", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $4;
        res = new IR(kDropStmt, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | DROP drop_type_name IF_P EXISTS name_list opt_drop_behavior {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53483,161526); // mapping from DropStmt to drop_type_name
        	gram_cov->log_edge_cov_map(53483,48207); // mapping from DropStmt to name_list
        	gram_cov->log_edge_cov_map(53483,207372); // mapping from DropStmt to opt_drop_behavior
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $5;
        res = new IR(kDropStmt_3, OP3("DROP", "IF EXISTS", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $6;
        res = new IR(kDropStmt, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | DROP drop_type_name name_list opt_drop_behavior {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53483,161526); // mapping from DropStmt to drop_type_name
        	gram_cov->log_edge_cov_map(53483,48207); // mapping from DropStmt to name_list
        	gram_cov->log_edge_cov_map(53483,207372); // mapping from DropStmt to opt_drop_behavior
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kDropStmt_4, OP3("DROP", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $4;
        res = new IR(kDropStmt, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | DROP drop_type_name_on_any_name name ON any_name opt_drop_behavior {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53483,63578); // mapping from DropStmt to drop_type_name_on_any_name
        	gram_cov->log_edge_cov_map(53483,212908); // mapping from DropStmt to name
        	gram_cov->log_edge_cov_map(53483,38234); // mapping from DropStmt to any_name
        	gram_cov->log_edge_cov_map(53483,207372); // mapping from DropStmt to opt_drop_behavior
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kDropStmt_5, OP3("DROP", "", "ON"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $5;
        setup_any_name(tmp3, kDataCollate, kUse, kDataSchemaName, kDataDatabase); 
        res = new IR(kDropStmt_6, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $6;
        res = new IR(kDropStmt, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | DROP drop_type_name_on_any_name IF_P EXISTS name ON any_name opt_drop_behavior {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53483,63578); // mapping from DropStmt to drop_type_name_on_any_name
        	gram_cov->log_edge_cov_map(53483,212908); // mapping from DropStmt to name
        	gram_cov->log_edge_cov_map(53483,38234); // mapping from DropStmt to any_name
        	gram_cov->log_edge_cov_map(53483,207372); // mapping from DropStmt to opt_drop_behavior
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $5;
        res = new IR(kDropStmt_7, OP3("DROP", "IF EXISTS", "ON"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $7;
        setup_any_name(tmp3, kDataCollate, kUse, kDataSchemaName, kDataDatabase); 
        res = new IR(kDropStmt_8, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $8;
        res = new IR(kDropStmt, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | DROP TYPE_P type_name_list opt_drop_behavior {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53483,156087); // mapping from DropStmt to type_name_list
        	gram_cov->log_edge_cov_map(53483,207372); // mapping from DropStmt to opt_drop_behavior
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kDropStmt, OP3("DROP TYPE", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | DROP TYPE_P IF_P EXISTS type_name_list opt_drop_behavior {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53483,156087); // mapping from DropStmt to type_name_list
        	gram_cov->log_edge_cov_map(53483,207372); // mapping from DropStmt to opt_drop_behavior
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $5;
        auto tmp2 = $6;
        res = new IR(kDropStmt, OP3("DROP TYPE IF EXISTS", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


drop_type_any_name:

    TABLE {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kDropTypeAnyName, OP3("TABLE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | SEQUENCE {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kDropTypeAnyName, OP3("SEQUENCE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | FUNCTION {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kDropTypeAnyName, OP3("FUNCTION", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | MACRO {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kDropTypeAnyName, OP3("MACRO", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | MACRO TABLE {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kDropTypeAnyName, OP3("MACRO TABLE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | VIEW {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kDropTypeAnyName, OP3("VIEW", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | MATERIALIZED VIEW {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kDropTypeAnyName, OP3("MATERIALIZED VIEW", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | INDEX {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kDropTypeAnyName, OP3("INDEX", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | FOREIGN TABLE {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kDropTypeAnyName, OP3("FOREIGN TABLE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | COLLATION {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kDropTypeAnyName, OP3("COLLATION", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CONVERSION_P {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kDropTypeAnyName, OP3("CONVERSION", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | SCHEMA {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kDropTypeAnyName, OP3("SCHEMA", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | STATISTICS {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kDropTypeAnyName, OP3("STATISTICS", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | TEXT_P SEARCH PARSER {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kDropTypeAnyName, OP3("TEXT SEARCH PARSER", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | TEXT_P SEARCH DICTIONARY {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kDropTypeAnyName, OP3("TEXT SEARCH DICTIONARY", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | TEXT_P SEARCH TEMPLATE {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kDropTypeAnyName, OP3("TEXT SEARCH TEMPLATE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | TEXT_P SEARCH CONFIGURATION {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kDropTypeAnyName, OP3("TEXT SEARCH CONFIGURATION", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


drop_type_name:

    ACCESS METHOD {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kDropTypeName, OP3("ACCESS METHOD", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | EVENT TRIGGER {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kDropTypeName, OP3("EVENT TRIGGER", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | EXTENSION {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kDropTypeName, OP3("EXTENSION", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | FOREIGN DATA_P WRAPPER {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kDropTypeName, OP3("FOREIGN DATA WRAPPER", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | PUBLICATION {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kDropTypeName, OP3("PUBLICATION", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | SERVER {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kDropTypeName, OP3("SERVER", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


any_name_list:

    any_name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(177966,38234); // mapping from any_name_list to any_name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        setup_any_name(tmp1, kDataCollate, kUse, kDataSchemaName, kDataDatabase); 
        res = new IR(kAnyNameList, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | any_name_list ',' any_name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(177966,177966); // mapping from any_name_list to any_name_list
        	gram_cov->log_edge_cov_map(177966,38234); // mapping from any_name_list to any_name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        setup_any_name(tmp2, kDataCollate, kUse, kDataSchemaName, kDataDatabase); 
        res = new IR(kAnyNameList, OP3("", ",", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_drop_behavior:

    CASCADE {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptDropBehavior, OP3("CASCADE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | RESTRICT {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptDropBehavior, OP3("RESTRICT", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptDropBehavior, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


drop_type_name_on_any_name:

    POLICY {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kDropTypeNameOnAnyName, OP3("POLICY", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | RULE {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kDropTypeNameOnAnyName, OP3("RULE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | TRIGGER {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kDropTypeNameOnAnyName, OP3("TRIGGER", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


type_name_list:

    Typename {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(156087,237247); // mapping from type_name_list to Typename
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kTypeNameList, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | type_name_list ',' Typename {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(156087,156087); // mapping from type_name_list to type_name_list
        	gram_cov->log_edge_cov_map(156087,237247); // mapping from type_name_list to Typename
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTypeNameList, OP3("", ",", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


CreateFunctionStmt:

    CREATE_P OptTemp macro_alias qualified_name param_list AS TABLE SelectStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(4674,254974); // mapping from CreateFunctionStmt to OptTemp
        	gram_cov->log_edge_cov_map(4674,175559); // mapping from CreateFunctionStmt to macro_alias
        	gram_cov->log_edge_cov_map(4674,38734); // mapping from CreateFunctionStmt to qualified_name
        	gram_cov->log_edge_cov_map(4674,199851); // mapping from CreateFunctionStmt to param_list
        	gram_cov->log_edge_cov_map(4674,70058); // mapping from CreateFunctionStmt to SelectStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateFunctionStmt_1, OP3("CREATE", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $4;
        setup_qualified_name(tmp3, kDataFunctionName, kDefine, kDataSchemaName, kDataDatabase); 
        res = new IR(kCreateFunctionStmt_2, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $5;
        res = new IR(kCreateFunctionStmt_3, OP3("", "", "AS TABLE"), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp5 = $8;
        res = new IR(kCreateFunctionStmt, OP3("", "", ""), res, tmp5);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CREATE_P OptTemp macro_alias IF_P NOT EXISTS qualified_name param_list AS TABLE SelectStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(4674,254974); // mapping from CreateFunctionStmt to OptTemp
        	gram_cov->log_edge_cov_map(4674,175559); // mapping from CreateFunctionStmt to macro_alias
        	gram_cov->log_edge_cov_map(4674,38734); // mapping from CreateFunctionStmt to qualified_name
        	gram_cov->log_edge_cov_map(4674,199851); // mapping from CreateFunctionStmt to param_list
        	gram_cov->log_edge_cov_map(4674,70058); // mapping from CreateFunctionStmt to SelectStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateFunctionStmt_4, OP3("CREATE", "", "IF NOT EXISTS"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $7;
        setup_qualified_name(tmp3, kDataFunctionName, kDefine, kDataSchemaName, kDataDatabase); 
        res = new IR(kCreateFunctionStmt_5, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $8;
        res = new IR(kCreateFunctionStmt_6, OP3("", "", "AS TABLE"), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp5 = $11;
        res = new IR(kCreateFunctionStmt, OP3("", "", ""), res, tmp5);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CREATE_P OR REPLACE OptTemp macro_alias qualified_name param_list AS TABLE SelectStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(4674,254974); // mapping from CreateFunctionStmt to OptTemp
        	gram_cov->log_edge_cov_map(4674,175559); // mapping from CreateFunctionStmt to macro_alias
        	gram_cov->log_edge_cov_map(4674,38734); // mapping from CreateFunctionStmt to qualified_name
        	gram_cov->log_edge_cov_map(4674,199851); // mapping from CreateFunctionStmt to param_list
        	gram_cov->log_edge_cov_map(4674,70058); // mapping from CreateFunctionStmt to SelectStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $4;
        auto tmp2 = $5;
        res = new IR(kCreateFunctionStmt_7, OP3("CREATE OR REPLACE", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $6;
        setup_qualified_name(tmp3, kDataFunctionName, kDefine, kDataSchemaName, kDataDatabase); 
        res = new IR(kCreateFunctionStmt_8, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $7;
        res = new IR(kCreateFunctionStmt_9, OP3("", "", "AS TABLE"), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp5 = $10;
        res = new IR(kCreateFunctionStmt, OP3("", "", ""), res, tmp5);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CREATE_P OptTemp macro_alias qualified_name param_list AS a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(4674,254974); // mapping from CreateFunctionStmt to OptTemp
        	gram_cov->log_edge_cov_map(4674,175559); // mapping from CreateFunctionStmt to macro_alias
        	gram_cov->log_edge_cov_map(4674,38734); // mapping from CreateFunctionStmt to qualified_name
        	gram_cov->log_edge_cov_map(4674,199851); // mapping from CreateFunctionStmt to param_list
        	gram_cov->log_edge_cov_map(4674,53205); // mapping from CreateFunctionStmt to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateFunctionStmt_10, OP3("CREATE", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $4;
        setup_qualified_name(tmp3, kDataFunctionName, kDefine, kDataSchemaName, kDataDatabase); 
        res = new IR(kCreateFunctionStmt_11, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $5;
        res = new IR(kCreateFunctionStmt_12, OP3("", "", "AS"), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp5 = $7;
        res = new IR(kCreateFunctionStmt, OP3("", "", ""), res, tmp5);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CREATE_P OptTemp macro_alias IF_P NOT EXISTS qualified_name param_list AS a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(4674,254974); // mapping from CreateFunctionStmt to OptTemp
        	gram_cov->log_edge_cov_map(4674,175559); // mapping from CreateFunctionStmt to macro_alias
        	gram_cov->log_edge_cov_map(4674,38734); // mapping from CreateFunctionStmt to qualified_name
        	gram_cov->log_edge_cov_map(4674,199851); // mapping from CreateFunctionStmt to param_list
        	gram_cov->log_edge_cov_map(4674,53205); // mapping from CreateFunctionStmt to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateFunctionStmt_13, OP3("CREATE", "", "IF NOT EXISTS"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $7;
        setup_qualified_name(tmp3, kDataFunctionName, kDefine, kDataSchemaName, kDataDatabase); 
        res = new IR(kCreateFunctionStmt_14, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $8;
        res = new IR(kCreateFunctionStmt_15, OP3("", "", "AS"), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp5 = $10;
        res = new IR(kCreateFunctionStmt, OP3("", "", ""), res, tmp5);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CREATE_P OR REPLACE OptTemp macro_alias qualified_name param_list AS a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(4674,254974); // mapping from CreateFunctionStmt to OptTemp
        	gram_cov->log_edge_cov_map(4674,175559); // mapping from CreateFunctionStmt to macro_alias
        	gram_cov->log_edge_cov_map(4674,38734); // mapping from CreateFunctionStmt to qualified_name
        	gram_cov->log_edge_cov_map(4674,199851); // mapping from CreateFunctionStmt to param_list
        	gram_cov->log_edge_cov_map(4674,53205); // mapping from CreateFunctionStmt to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $4;
        auto tmp2 = $5;
        res = new IR(kCreateFunctionStmt_16, OP3("CREATE OR REPLACE", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $6;
        setup_qualified_name(tmp3, kDataFunctionName, kDefine, kDataSchemaName, kDataDatabase); 
        res = new IR(kCreateFunctionStmt_17, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $7;
        res = new IR(kCreateFunctionStmt_18, OP3("", "", "AS"), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp5 = $9;
        res = new IR(kCreateFunctionStmt, OP3("", "", ""), res, tmp5);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


macro_alias:

    FUNCTION {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kMacroAlias, OP3("FUNCTION", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | MACRO {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kMacroAlias, OP3("MACRO", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


param_list:

    '(' ')' {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kParamList, OP3("( )", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '(' func_arg_list ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(199851,101501); // mapping from param_list to func_arg_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kParamList, OP3("(", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


UpdateStmt:

    opt_with_clause UPDATE relation_expr_opt_alias SET set_clause_list_opt_comma from_clause where_or_current_clause returning_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(157714,74395); // mapping from UpdateStmt to opt_with_clause
        	gram_cov->log_edge_cov_map(157714,6293); // mapping from UpdateStmt to relation_expr_opt_alias
        	gram_cov->log_edge_cov_map(157714,98100); // mapping from UpdateStmt to set_clause_list_opt_comma
        	gram_cov->log_edge_cov_map(157714,2951); // mapping from UpdateStmt to from_clause
        	gram_cov->log_edge_cov_map(157714,220981); // mapping from UpdateStmt to where_or_current_clause
        	gram_cov->log_edge_cov_map(157714,132480); // mapping from UpdateStmt to returning_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kUpdateStmt_1, OP3("", "UPDATE", "SET"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $5;
        res = new IR(kUpdateStmt_2, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $6;
        res = new IR(kUpdateStmt_3, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp5 = $7;
        res = new IR(kUpdateStmt_4, OP3("", "", ""), res, tmp5);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp6 = $8;
        res = new IR(kUpdateStmt, OP3("", "", ""), res, tmp6);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


CopyStmt:

    COPY opt_binary qualified_name opt_column_list opt_oids copy_from opt_program copy_file_name copy_delimiter opt_with copy_options {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(128531,204035); // mapping from CopyStmt to opt_binary
        	gram_cov->log_edge_cov_map(128531,38734); // mapping from CopyStmt to qualified_name
        	gram_cov->log_edge_cov_map(128531,193852); // mapping from CopyStmt to opt_column_list
        	gram_cov->log_edge_cov_map(128531,1522); // mapping from CopyStmt to opt_oids
        	gram_cov->log_edge_cov_map(128531,226493); // mapping from CopyStmt to copy_from
        	gram_cov->log_edge_cov_map(128531,12387); // mapping from CopyStmt to opt_program
        	gram_cov->log_edge_cov_map(128531,259383); // mapping from CopyStmt to copy_file_name
        	gram_cov->log_edge_cov_map(128531,242188); // mapping from CopyStmt to copy_delimiter
        	gram_cov->log_edge_cov_map(128531,142489); // mapping from CopyStmt to opt_with
        	gram_cov->log_edge_cov_map(128531,139201); // mapping from CopyStmt to copy_options
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        setup_qualified_name(tmp2, kDataTableName, kUse, kDataSchemaName, kDataDatabase); 
        res = new IR(kCopyStmt_1, OP3("COPY", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $4;
        setup_opt_column_list(tmp3, kDataColumnName, kUse); 
        res = new IR(kCopyStmt_2, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $5;
        res = new IR(kCopyStmt_3, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp5 = $6;
        res = new IR(kCopyStmt_4, OP3("", "", ""), res, tmp5);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp6 = $7;
        res = new IR(kCopyStmt_5, OP3("", "", ""), res, tmp6);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp7 = $8;
        res = new IR(kCopyStmt_6, OP3("", "", ""), res, tmp7);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp8 = $9;
        res = new IR(kCopyStmt_7, OP3("", "", ""), res, tmp8);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp9 = $10;
        res = new IR(kCopyStmt_8, OP3("", "", ""), res, tmp9);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp10 = $11;
        res = new IR(kCopyStmt, OP3("", "", ""), res, tmp10);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | COPY '(' SelectStmt ')' TO opt_program copy_file_name opt_with copy_options {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(128531,70058); // mapping from CopyStmt to SelectStmt
        	gram_cov->log_edge_cov_map(128531,12387); // mapping from CopyStmt to opt_program
        	gram_cov->log_edge_cov_map(128531,259383); // mapping from CopyStmt to copy_file_name
        	gram_cov->log_edge_cov_map(128531,142489); // mapping from CopyStmt to opt_with
        	gram_cov->log_edge_cov_map(128531,139201); // mapping from CopyStmt to copy_options
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kCopyStmt_9, OP3("COPY (", ") TO", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $7;
        res = new IR(kCopyStmt_10, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $8;
        res = new IR(kCopyStmt_11, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp5 = $9;
        res = new IR(kCopyStmt, OP3("", "", ""), res, tmp5);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


copy_from:

    FROM {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kCopyFrom, OP3("FROM", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | TO {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kCopyFrom, OP3("TO", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


copy_delimiter:

    opt_using DELIMITERS Sconst {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(242188,117598); // mapping from copy_delimiter to opt_using
        	gram_cov->log_edge_cov_map(242188,47445); // mapping from copy_delimiter to Sconst
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kCopyDelimiter, OP3("", "DELIMITERS", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kCopyDelimiter, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


copy_generic_opt_arg_list:

    copy_generic_opt_arg_list_item {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(241719,170222); // mapping from copy_generic_opt_arg_list to copy_generic_opt_arg_list_item
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kCopyGenericOptArgList, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | copy_generic_opt_arg_list ',' copy_generic_opt_arg_list_item {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(241719,241719); // mapping from copy_generic_opt_arg_list to copy_generic_opt_arg_list
        	gram_cov->log_edge_cov_map(241719,170222); // mapping from copy_generic_opt_arg_list to copy_generic_opt_arg_list_item
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kCopyGenericOptArgList, OP3("", ",", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_using:

    USING {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptUsing, OP3("USING", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptUsing, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_as:

    AS {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptAs, OP3("AS", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptAs, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_program:

    PROGRAM {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptProgram, OP3("PROGRAM", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptProgram, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


copy_options:

    copy_opt_list {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(139201,56098); // mapping from copy_options to copy_opt_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kCopyOptions, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '(' copy_generic_opt_list ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(139201,203064); // mapping from copy_options to copy_generic_opt_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kCopyOptions, OP3("(", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


copy_generic_opt_arg:

    opt_boolean_or_string {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(92318,231718); // mapping from copy_generic_opt_arg to opt_boolean_or_string
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kCopyGenericOptArg, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | NumericOnly {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(92318,146194); // mapping from copy_generic_opt_arg to NumericOnly
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kCopyGenericOptArg, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '*' {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kCopyGenericOptArg, OP3("*", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '(' copy_generic_opt_arg_list ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(92318,241719); // mapping from copy_generic_opt_arg to copy_generic_opt_arg_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kCopyGenericOptArg, OP3("(", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | struct_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(92318,221179); // mapping from copy_generic_opt_arg to struct_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kCopyGenericOptArg, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kCopyGenericOptArg, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


copy_generic_opt_elem:

    ColLabel copy_generic_opt_arg {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(79962,197766); // mapping from copy_generic_opt_elem to ColLabel
        	gram_cov->log_edge_cov_map(79962,92318); // mapping from copy_generic_opt_elem to copy_generic_opt_arg
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        setup_col_label(tmp1, kDataReloptionName, kUse); 
        auto tmp2 = $2;
        res = new IR(kCopyGenericOptElem, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_oids:

    WITH OIDS {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptOids, OP3("WITH OIDS", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptOids, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


copy_opt_list:

    copy_opt_list copy_opt_item {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(56098,56098); // mapping from copy_opt_list to copy_opt_list
        	gram_cov->log_edge_cov_map(56098,220634); // mapping from copy_opt_list to copy_opt_item
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCopyOptList, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kCopyOptList, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_binary:

    BINARY {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptBinary, OP3("BINARY", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptBinary, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


copy_opt_item:

    BINARY {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kCopyOptItem, OP3("BINARY", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | OIDS {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kCopyOptItem, OP3("OIDS", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | FREEZE {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kCopyOptItem, OP3("FREEZE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | DELIMITER opt_as Sconst {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(220634,190736); // mapping from copy_opt_item to opt_as
        	gram_cov->log_edge_cov_map(220634,47445); // mapping from copy_opt_item to Sconst
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCopyOptItem, OP3("DELIMITER", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | NULL_P opt_as Sconst {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(220634,190736); // mapping from copy_opt_item to opt_as
        	gram_cov->log_edge_cov_map(220634,47445); // mapping from copy_opt_item to Sconst
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCopyOptItem, OP3("NULL", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CSV {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kCopyOptItem, OP3("CSV", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | HEADER_P {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kCopyOptItem, OP3("HEADER", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | QUOTE opt_as Sconst {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(220634,190736); // mapping from copy_opt_item to opt_as
        	gram_cov->log_edge_cov_map(220634,47445); // mapping from copy_opt_item to Sconst
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCopyOptItem, OP3("QUOTE", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ESCAPE opt_as Sconst {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(220634,190736); // mapping from copy_opt_item to opt_as
        	gram_cov->log_edge_cov_map(220634,47445); // mapping from copy_opt_item to Sconst
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCopyOptItem, OP3("ESCAPE", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | FORCE QUOTE columnList {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(220634,63969); // mapping from copy_opt_item to columnList
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        setup_column_list(tmp1, kDataColumnName, kUse); 
        res = new IR(kCopyOptItem, OP3("FORCE QUOTE", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | FORCE QUOTE '*' {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kCopyOptItem, OP3("FORCE QUOTE *", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | PARTITION BY columnList {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(220634,63969); // mapping from copy_opt_item to columnList
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        setup_column_list(tmp1, kDataColumnName, kUse); 
        res = new IR(kCopyOptItem, OP3("PARTITION BY", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | PARTITION BY '*' {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kCopyOptItem, OP3("PARTITION BY *", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | FORCE NOT NULL_P columnList {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(220634,63969); // mapping from copy_opt_item to columnList
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $4;
        setup_column_list(tmp1, kDataColumnName, kUse); 
        res = new IR(kCopyOptItem, OP3("FORCE NOT NULL", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | FORCE NULL_P columnList {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(220634,63969); // mapping from copy_opt_item to columnList
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        setup_column_list(tmp1, kDataColumnName, kUse); 
        res = new IR(kCopyOptItem, OP3("FORCE NULL", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ENCODING Sconst {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(220634,47445); // mapping from copy_opt_item to Sconst
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kCopyOptItem, OP3("ENCODING", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


copy_generic_opt_arg_list_item:

    opt_boolean_or_string {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(170222,231718); // mapping from copy_generic_opt_arg_list_item to opt_boolean_or_string
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kCopyGenericOptArgListItem, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


copy_file_name:

    Sconst {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(259383,47445); // mapping from copy_file_name to Sconst
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kCopyFileName, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | STDIN {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kCopyFileName, OP3("STDIN", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | STDOUT {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kCopyFileName, OP3("STDOUT", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


copy_generic_opt_list:

    copy_generic_opt_elem {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(203064,79962); // mapping from copy_generic_opt_list to copy_generic_opt_elem
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kCopyGenericOptList, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | copy_generic_opt_list ',' copy_generic_opt_elem {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(203064,203064); // mapping from copy_generic_opt_list to copy_generic_opt_list
        	gram_cov->log_edge_cov_map(203064,79962); // mapping from copy_generic_opt_list to copy_generic_opt_elem
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kCopyGenericOptList, OP3("", ",", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


SelectStmt:

    select_no_parens %prec UMINUS {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(70058,26707); // mapping from SelectStmt to select_no_parens
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kSelectStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | select_with_parens %prec UMINUS {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(70058,178444); // mapping from SelectStmt to select_with_parens
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kSelectStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


select_with_parens:

    '(' select_no_parens ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(178444,26707); // mapping from select_with_parens to select_no_parens
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kSelectWithParens, OP3("(", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '(' select_with_parens ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(178444,178444); // mapping from select_with_parens to select_with_parens
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kSelectWithParens, OP3("(", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


select_no_parens:

    simple_select {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(26707,201914); // mapping from select_no_parens to simple_select
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kSelectNoParens, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | select_clause sort_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(26707,26880); // mapping from select_no_parens to select_clause
        	gram_cov->log_edge_cov_map(26707,159625); // mapping from select_no_parens to sort_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSelectNoParens, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | select_clause opt_sort_clause for_locking_clause opt_select_limit {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(26707,26880); // mapping from select_no_parens to select_clause
        	gram_cov->log_edge_cov_map(26707,260970); // mapping from select_no_parens to opt_sort_clause
        	gram_cov->log_edge_cov_map(26707,148643); // mapping from select_no_parens to for_locking_clause
        	gram_cov->log_edge_cov_map(26707,232132); // mapping from select_no_parens to opt_select_limit
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSelectNoParens_1, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $3;
        res = new IR(kSelectNoParens_2, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $4;
        res = new IR(kSelectNoParens, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | select_clause opt_sort_clause select_limit opt_for_locking_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(26707,26880); // mapping from select_no_parens to select_clause
        	gram_cov->log_edge_cov_map(26707,260970); // mapping from select_no_parens to opt_sort_clause
        	gram_cov->log_edge_cov_map(26707,221475); // mapping from select_no_parens to select_limit
        	gram_cov->log_edge_cov_map(26707,217976); // mapping from select_no_parens to opt_for_locking_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSelectNoParens_3, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $3;
        res = new IR(kSelectNoParens_4, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $4;
        res = new IR(kSelectNoParens, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | with_clause select_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(26707,118320); // mapping from select_no_parens to with_clause
        	gram_cov->log_edge_cov_map(26707,26880); // mapping from select_no_parens to select_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSelectNoParens, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | with_clause select_clause sort_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(26707,118320); // mapping from select_no_parens to with_clause
        	gram_cov->log_edge_cov_map(26707,26880); // mapping from select_no_parens to select_clause
        	gram_cov->log_edge_cov_map(26707,159625); // mapping from select_no_parens to sort_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSelectNoParens_5, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $3;
        res = new IR(kSelectNoParens, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | with_clause select_clause opt_sort_clause for_locking_clause opt_select_limit {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(26707,118320); // mapping from select_no_parens to with_clause
        	gram_cov->log_edge_cov_map(26707,26880); // mapping from select_no_parens to select_clause
        	gram_cov->log_edge_cov_map(26707,260970); // mapping from select_no_parens to opt_sort_clause
        	gram_cov->log_edge_cov_map(26707,148643); // mapping from select_no_parens to for_locking_clause
        	gram_cov->log_edge_cov_map(26707,232132); // mapping from select_no_parens to opt_select_limit
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSelectNoParens_6, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $3;
        res = new IR(kSelectNoParens_7, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $4;
        res = new IR(kSelectNoParens_8, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp5 = $5;
        res = new IR(kSelectNoParens, OP3("", "", ""), res, tmp5);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | with_clause select_clause opt_sort_clause select_limit opt_for_locking_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(26707,118320); // mapping from select_no_parens to with_clause
        	gram_cov->log_edge_cov_map(26707,26880); // mapping from select_no_parens to select_clause
        	gram_cov->log_edge_cov_map(26707,260970); // mapping from select_no_parens to opt_sort_clause
        	gram_cov->log_edge_cov_map(26707,221475); // mapping from select_no_parens to select_limit
        	gram_cov->log_edge_cov_map(26707,217976); // mapping from select_no_parens to opt_for_locking_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSelectNoParens_9, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $3;
        res = new IR(kSelectNoParens_10, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $4;
        res = new IR(kSelectNoParens_11, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp5 = $5;
        res = new IR(kSelectNoParens, OP3("", "", ""), res, tmp5);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


select_clause:

    simple_select {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(26880,201914); // mapping from select_clause to simple_select
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kSelectClause, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | select_with_parens {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(26880,178444); // mapping from select_clause to select_with_parens
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kSelectClause, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_select:

    SELECT opt_all_clause opt_target_list_opt_comma {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(145778,159496); // mapping from opt_select to opt_all_clause
        	gram_cov->log_edge_cov_map(145778,213781); // mapping from opt_select to opt_target_list_opt_comma
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kOptSelect, OP3("SELECT", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptSelect, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


simple_select:

    SELECT opt_all_clause opt_target_list_opt_comma into_clause from_clause where_clause group_clause having_clause window_clause qualify_clause sample_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(201914,159496); // mapping from simple_select to opt_all_clause
        	gram_cov->log_edge_cov_map(201914,213781); // mapping from simple_select to opt_target_list_opt_comma
        	gram_cov->log_edge_cov_map(201914,204130); // mapping from simple_select to into_clause
        	gram_cov->log_edge_cov_map(201914,2951); // mapping from simple_select to from_clause
        	gram_cov->log_edge_cov_map(201914,16133); // mapping from simple_select to where_clause
        	gram_cov->log_edge_cov_map(201914,60109); // mapping from simple_select to group_clause
        	gram_cov->log_edge_cov_map(201914,107493); // mapping from simple_select to having_clause
        	gram_cov->log_edge_cov_map(201914,126674); // mapping from simple_select to window_clause
        	gram_cov->log_edge_cov_map(201914,106890); // mapping from simple_select to qualify_clause
        	gram_cov->log_edge_cov_map(201914,39092); // mapping from simple_select to sample_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSimpleSelect_1, OP3("SELECT", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $4;
        res = new IR(kSimpleSelect_2, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $5;
        res = new IR(kSimpleSelect_3, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp5 = $6;
        res = new IR(kSimpleSelect_4, OP3("", "", ""), res, tmp5);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp6 = $7;
        res = new IR(kSimpleSelect_5, OP3("", "", ""), res, tmp6);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp7 = $8;
        res = new IR(kSimpleSelect_6, OP3("", "", ""), res, tmp7);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp8 = $9;
        res = new IR(kSimpleSelect_7, OP3("", "", ""), res, tmp8);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp9 = $10;
        res = new IR(kSimpleSelect_8, OP3("", "", ""), res, tmp9);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp10 = $11;
        res = new IR(kSimpleSelect, OP3("", "", ""), res, tmp10);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | SELECT distinct_clause target_list_opt_comma into_clause from_clause where_clause group_clause having_clause window_clause qualify_clause sample_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(201914,1531); // mapping from simple_select to distinct_clause
        	gram_cov->log_edge_cov_map(201914,85316); // mapping from simple_select to target_list_opt_comma
        	gram_cov->log_edge_cov_map(201914,204130); // mapping from simple_select to into_clause
        	gram_cov->log_edge_cov_map(201914,2951); // mapping from simple_select to from_clause
        	gram_cov->log_edge_cov_map(201914,16133); // mapping from simple_select to where_clause
        	gram_cov->log_edge_cov_map(201914,60109); // mapping from simple_select to group_clause
        	gram_cov->log_edge_cov_map(201914,107493); // mapping from simple_select to having_clause
        	gram_cov->log_edge_cov_map(201914,126674); // mapping from simple_select to window_clause
        	gram_cov->log_edge_cov_map(201914,106890); // mapping from simple_select to qualify_clause
        	gram_cov->log_edge_cov_map(201914,39092); // mapping from simple_select to sample_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSimpleSelect_9, OP3("SELECT", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $4;
        res = new IR(kSimpleSelect_10, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $5;
        res = new IR(kSimpleSelect_11, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp5 = $6;
        res = new IR(kSimpleSelect_12, OP3("", "", ""), res, tmp5);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp6 = $7;
        res = new IR(kSimpleSelect_13, OP3("", "", ""), res, tmp6);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp7 = $8;
        res = new IR(kSimpleSelect_14, OP3("", "", ""), res, tmp7);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp8 = $9;
        res = new IR(kSimpleSelect_15, OP3("", "", ""), res, tmp8);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp9 = $10;
        res = new IR(kSimpleSelect_16, OP3("", "", ""), res, tmp9);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp10 = $11;
        res = new IR(kSimpleSelect, OP3("", "", ""), res, tmp10);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | FROM from_list opt_select into_clause where_clause group_clause having_clause window_clause qualify_clause sample_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(201914,204196); // mapping from simple_select to from_list
        	gram_cov->log_edge_cov_map(201914,145778); // mapping from simple_select to opt_select
        	gram_cov->log_edge_cov_map(201914,204130); // mapping from simple_select to into_clause
        	gram_cov->log_edge_cov_map(201914,16133); // mapping from simple_select to where_clause
        	gram_cov->log_edge_cov_map(201914,60109); // mapping from simple_select to group_clause
        	gram_cov->log_edge_cov_map(201914,107493); // mapping from simple_select to having_clause
        	gram_cov->log_edge_cov_map(201914,126674); // mapping from simple_select to window_clause
        	gram_cov->log_edge_cov_map(201914,106890); // mapping from simple_select to qualify_clause
        	gram_cov->log_edge_cov_map(201914,39092); // mapping from simple_select to sample_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSimpleSelect_17, OP3("FROM", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $4;
        res = new IR(kSimpleSelect_18, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $5;
        res = new IR(kSimpleSelect_19, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp5 = $6;
        res = new IR(kSimpleSelect_20, OP3("", "", ""), res, tmp5);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp6 = $7;
        res = new IR(kSimpleSelect_21, OP3("", "", ""), res, tmp6);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp7 = $8;
        res = new IR(kSimpleSelect_22, OP3("", "", ""), res, tmp7);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp8 = $9;
        res = new IR(kSimpleSelect_23, OP3("", "", ""), res, tmp8);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp9 = $10;
        res = new IR(kSimpleSelect, OP3("", "", ""), res, tmp9);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | FROM from_list SELECT distinct_clause target_list_opt_comma into_clause where_clause group_clause having_clause window_clause qualify_clause sample_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(201914,204196); // mapping from simple_select to from_list
        	gram_cov->log_edge_cov_map(201914,1531); // mapping from simple_select to distinct_clause
        	gram_cov->log_edge_cov_map(201914,85316); // mapping from simple_select to target_list_opt_comma
        	gram_cov->log_edge_cov_map(201914,204130); // mapping from simple_select to into_clause
        	gram_cov->log_edge_cov_map(201914,16133); // mapping from simple_select to where_clause
        	gram_cov->log_edge_cov_map(201914,60109); // mapping from simple_select to group_clause
        	gram_cov->log_edge_cov_map(201914,107493); // mapping from simple_select to having_clause
        	gram_cov->log_edge_cov_map(201914,126674); // mapping from simple_select to window_clause
        	gram_cov->log_edge_cov_map(201914,106890); // mapping from simple_select to qualify_clause
        	gram_cov->log_edge_cov_map(201914,39092); // mapping from simple_select to sample_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kSimpleSelect_24, OP3("FROM", "SELECT", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $5;
        res = new IR(kSimpleSelect_25, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $6;
        res = new IR(kSimpleSelect_26, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp5 = $7;
        res = new IR(kSimpleSelect_27, OP3("", "", ""), res, tmp5);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp6 = $8;
        res = new IR(kSimpleSelect_28, OP3("", "", ""), res, tmp6);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp7 = $9;
        res = new IR(kSimpleSelect_29, OP3("", "", ""), res, tmp7);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp8 = $10;
        res = new IR(kSimpleSelect_30, OP3("", "", ""), res, tmp8);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp9 = $11;
        res = new IR(kSimpleSelect_31, OP3("", "", ""), res, tmp9);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp10 = $12;
        res = new IR(kSimpleSelect, OP3("", "", ""), res, tmp10);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | values_clause_opt_comma {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(201914,239110); // mapping from simple_select to values_clause_opt_comma
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kSimpleSelect, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | TABLE relation_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(201914,135212); // mapping from simple_select to relation_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        setup_relation_expr(tmp1, kDataTableName, kUse, kDataSchemaName, kDataDatabase); 
        res = new IR(kSimpleSelect, OP3("TABLE", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | select_clause UNION all_or_distinct by_name select_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(201914,26880); // mapping from simple_select to select_clause
        	gram_cov->log_edge_cov_map(201914,166671); // mapping from simple_select to all_or_distinct
        	gram_cov->log_edge_cov_map(201914,223492); // mapping from simple_select to by_name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSimpleSelect_32, OP3("", "UNION", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $4;
        res = new IR(kSimpleSelect_33, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $5;
        res = new IR(kSimpleSelect, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | select_clause UNION all_or_distinct select_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(201914,26880); // mapping from simple_select to select_clause
        	gram_cov->log_edge_cov_map(201914,166671); // mapping from simple_select to all_or_distinct
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSimpleSelect_34, OP3("", "UNION", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $4;
        res = new IR(kSimpleSelect, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | select_clause INTERSECT all_or_distinct select_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(201914,26880); // mapping from simple_select to select_clause
        	gram_cov->log_edge_cov_map(201914,166671); // mapping from simple_select to all_or_distinct
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSimpleSelect_35, OP3("", "INTERSECT", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $4;
        res = new IR(kSimpleSelect, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | select_clause EXCEPT all_or_distinct select_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(201914,26880); // mapping from simple_select to select_clause
        	gram_cov->log_edge_cov_map(201914,166671); // mapping from simple_select to all_or_distinct
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSimpleSelect_36, OP3("", "EXCEPT", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $4;
        res = new IR(kSimpleSelect, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | pivot_keyword table_ref USING target_list_opt_comma {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(201914,229709); // mapping from simple_select to pivot_keyword
        	gram_cov->log_edge_cov_map(201914,125471); // mapping from simple_select to table_ref
        	gram_cov->log_edge_cov_map(201914,85316); // mapping from simple_select to target_list_opt_comma
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSimpleSelect_37, OP3("", "", "USING"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $4;
        res = new IR(kSimpleSelect, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | pivot_keyword table_ref USING target_list_opt_comma GROUP_P BY name_list_opt_comma_opt_bracket {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(201914,229709); // mapping from simple_select to pivot_keyword
        	gram_cov->log_edge_cov_map(201914,125471); // mapping from simple_select to table_ref
        	gram_cov->log_edge_cov_map(201914,85316); // mapping from simple_select to target_list_opt_comma
        	gram_cov->log_edge_cov_map(201914,85594); // mapping from simple_select to name_list_opt_comma_opt_bracket
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSimpleSelect_38, OP3("", "", "USING"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $4;
        res = new IR(kSimpleSelect_39, OP3("", "", "GROUP BY"), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $7;
        setup_name_list_opt_comma_opt_bracket(tmp4, kDataColumnName, kUse); 
        res = new IR(kSimpleSelect, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | pivot_keyword table_ref GROUP_P BY name_list_opt_comma_opt_bracket {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(201914,229709); // mapping from simple_select to pivot_keyword
        	gram_cov->log_edge_cov_map(201914,125471); // mapping from simple_select to table_ref
        	gram_cov->log_edge_cov_map(201914,85594); // mapping from simple_select to name_list_opt_comma_opt_bracket
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSimpleSelect_40, OP3("", "", "GROUP BY"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $5;
        setup_name_list_opt_comma_opt_bracket(tmp3, kDataColumnName, kUse); 
        res = new IR(kSimpleSelect, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | pivot_keyword table_ref ON pivot_column_list {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(201914,229709); // mapping from simple_select to pivot_keyword
        	gram_cov->log_edge_cov_map(201914,125471); // mapping from simple_select to table_ref
        	gram_cov->log_edge_cov_map(201914,242536); // mapping from simple_select to pivot_column_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSimpleSelect_41, OP3("", "", "ON"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $4;
        res = new IR(kSimpleSelect, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | pivot_keyword table_ref ON pivot_column_list GROUP_P BY name_list_opt_comma_opt_bracket {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(201914,229709); // mapping from simple_select to pivot_keyword
        	gram_cov->log_edge_cov_map(201914,125471); // mapping from simple_select to table_ref
        	gram_cov->log_edge_cov_map(201914,242536); // mapping from simple_select to pivot_column_list
        	gram_cov->log_edge_cov_map(201914,85594); // mapping from simple_select to name_list_opt_comma_opt_bracket
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSimpleSelect_42, OP3("", "", "ON"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $4;
        res = new IR(kSimpleSelect_43, OP3("", "", "GROUP BY"), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $7;
        setup_name_list_opt_comma_opt_bracket(tmp4, kDataColumnName, kUse); 
        res = new IR(kSimpleSelect, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | pivot_keyword table_ref ON pivot_column_list USING target_list_opt_comma {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(201914,229709); // mapping from simple_select to pivot_keyword
        	gram_cov->log_edge_cov_map(201914,125471); // mapping from simple_select to table_ref
        	gram_cov->log_edge_cov_map(201914,242536); // mapping from simple_select to pivot_column_list
        	gram_cov->log_edge_cov_map(201914,85316); // mapping from simple_select to target_list_opt_comma
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSimpleSelect_44, OP3("", "", "ON"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $4;
        res = new IR(kSimpleSelect_45, OP3("", "", "USING"), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $6;
        res = new IR(kSimpleSelect, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | pivot_keyword table_ref ON pivot_column_list USING target_list_opt_comma GROUP_P BY name_list_opt_comma_opt_bracket {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(201914,229709); // mapping from simple_select to pivot_keyword
        	gram_cov->log_edge_cov_map(201914,125471); // mapping from simple_select to table_ref
        	gram_cov->log_edge_cov_map(201914,242536); // mapping from simple_select to pivot_column_list
        	gram_cov->log_edge_cov_map(201914,85316); // mapping from simple_select to target_list_opt_comma
        	gram_cov->log_edge_cov_map(201914,85594); // mapping from simple_select to name_list_opt_comma_opt_bracket
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSimpleSelect_46, OP3("", "", "ON"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $4;
        res = new IR(kSimpleSelect_47, OP3("", "", "USING"), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $6;
        res = new IR(kSimpleSelect_48, OP3("", "", "GROUP BY"), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp5 = $9;
        setup_name_list_opt_comma_opt_bracket(tmp5, kDataColumnName, kUse); 
        res = new IR(kSimpleSelect, OP3("", "", ""), res, tmp5);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | unpivot_keyword table_ref ON target_list_opt_comma INTO NAME_P name value_or_values name_list_opt_comma_opt_bracket {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(201914,196735); // mapping from simple_select to unpivot_keyword
        	gram_cov->log_edge_cov_map(201914,125471); // mapping from simple_select to table_ref
        	gram_cov->log_edge_cov_map(201914,85316); // mapping from simple_select to target_list_opt_comma
        	gram_cov->log_edge_cov_map(201914,212908); // mapping from simple_select to name
        	gram_cov->log_edge_cov_map(201914,174091); // mapping from simple_select to value_or_values
        	gram_cov->log_edge_cov_map(201914,85594); // mapping from simple_select to name_list_opt_comma_opt_bracket
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSimpleSelect_49, OP3("", "", "ON"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $4;
        res = new IR(kSimpleSelect_50, OP3("", "", "INTO NAME"), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $7;
        setup_name(tmp4, kDataTableName, kDefine); 
        res = new IR(kSimpleSelect_51, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp5 = $8;
        res = new IR(kSimpleSelect_52, OP3("", "", ""), res, tmp5);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp6 = $9;
        setup_name_list_opt_comma_opt_bracket(tmp6, kDataColumnName, kUse); 
        res = new IR(kSimpleSelect, OP3("", "", ""), res, tmp6);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | unpivot_keyword table_ref ON target_list_opt_comma {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(201914,196735); // mapping from simple_select to unpivot_keyword
        	gram_cov->log_edge_cov_map(201914,125471); // mapping from simple_select to table_ref
        	gram_cov->log_edge_cov_map(201914,85316); // mapping from simple_select to target_list_opt_comma
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSimpleSelect_53, OP3("", "", "ON"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $4;
        res = new IR(kSimpleSelect, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


value_or_values:

    VALUE_P {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kValueOrValues, OP3("VALUE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | VALUES {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kValueOrValues, OP3("VALUES", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


pivot_keyword:

    PIVOT {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kPivotKeyword, OP3("PIVOT", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | PIVOT_WIDER {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kPivotKeyword, OP3("PIVOT_WIDER", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


unpivot_keyword:

    UNPIVOT {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kUnpivotKeyword, OP3("UNPIVOT", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | PIVOT_LONGER {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kUnpivotKeyword, OP3("PIVOT_LONGER", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


pivot_column_entry:

    b_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(150308,25763); // mapping from pivot_column_entry to b_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kPivotColumnEntry, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | b_expr IN_P '(' select_no_parens ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(150308,25763); // mapping from pivot_column_entry to b_expr
        	gram_cov->log_edge_cov_map(150308,26707); // mapping from pivot_column_entry to select_no_parens
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kPivotColumnEntry, OP3("", "IN (", ")"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | single_pivot_value {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(150308,200789); // mapping from pivot_column_entry to single_pivot_value
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kPivotColumnEntry, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


pivot_column_list_internal:

    pivot_column_entry {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(78119,150308); // mapping from pivot_column_list_internal to pivot_column_entry
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kPivotColumnListInternal, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | pivot_column_list_internal ',' pivot_column_entry {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(78119,78119); // mapping from pivot_column_list_internal to pivot_column_list_internal
        	gram_cov->log_edge_cov_map(78119,150308); // mapping from pivot_column_list_internal to pivot_column_entry
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kPivotColumnListInternal, OP3("", ",", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


pivot_column_list:

    pivot_column_list_internal {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(242536,78119); // mapping from pivot_column_list to pivot_column_list_internal
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kPivotColumnList, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | pivot_column_list_internal ',' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(242536,78119); // mapping from pivot_column_list to pivot_column_list_internal
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kPivotColumnList, OP3("", ",", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


with_clause:

    WITH cte_list {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(118320,208420); // mapping from with_clause to cte_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kWithClause, OP3("WITH", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | WITH_LA cte_list {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(118320,208420); // mapping from with_clause to cte_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kWithClause, OP3("WITH", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | WITH RECURSIVE cte_list {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(118320,208420); // mapping from with_clause to cte_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kWithClause, OP3("WITH RECURSIVE", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


cte_list:

    common_table_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(208420,135333); // mapping from cte_list to common_table_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kCteList, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | cte_list ',' common_table_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(208420,208420); // mapping from cte_list to cte_list
        	gram_cov->log_edge_cov_map(208420,135333); // mapping from cte_list to common_table_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kCteList, OP3("", ",", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


common_table_expr:

    name opt_name_list AS opt_materialized '(' PreparableStmt ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(135333,212908); // mapping from common_table_expr to name
        	gram_cov->log_edge_cov_map(135333,254483); // mapping from common_table_expr to opt_name_list
        	gram_cov->log_edge_cov_map(135333,131493); // mapping from common_table_expr to opt_materialized
        	gram_cov->log_edge_cov_map(135333,147479); // mapping from common_table_expr to PreparableStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        setup_name(tmp1, kDataAliasTableName, kDefine); 
        auto tmp2 = $2;
        setup_opt_name_list(tmp2, kDataAliasName, kDefine); 
        res = new IR(kCommonTableExpr_1, OP3("", "", "AS"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $4;
        res = new IR(kCommonTableExpr_2, OP3("", "", "("), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $6;
        res = new IR(kCommonTableExpr, OP3("", "", ")"), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_materialized:

    MATERIALIZED {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptMaterialized, OP3("MATERIALIZED", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | NOT MATERIALIZED {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptMaterialized, OP3("NOT MATERIALIZED", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptMaterialized, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


into_clause:

    INTO OptTempTableName {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(204130,243135); // mapping from into_clause to OptTempTableName
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kIntoClause, OP3("INTO", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kIntoClause, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


OptTempTableName:

    TEMPORARY opt_table qualified_name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(243135,171318); // mapping from OptTempTableName to opt_table
        	gram_cov->log_edge_cov_map(243135,38734); // mapping from OptTempTableName to qualified_name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        setup_qualified_name(tmp2, kDataTableName, kDefine, kDataSchemaName, kDataDatabase); 
        res = new IR(kOptTempTableName, OP3("TEMPORARY", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | TEMP opt_table qualified_name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(243135,171318); // mapping from OptTempTableName to opt_table
        	gram_cov->log_edge_cov_map(243135,38734); // mapping from OptTempTableName to qualified_name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        setup_qualified_name(tmp2, kDataTableName, kDefine, kDataSchemaName, kDataDatabase); 
        res = new IR(kOptTempTableName, OP3("TEMP", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | LOCAL TEMPORARY opt_table qualified_name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(243135,171318); // mapping from OptTempTableName to opt_table
        	gram_cov->log_edge_cov_map(243135,38734); // mapping from OptTempTableName to qualified_name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        auto tmp2 = $4;
        setup_qualified_name(tmp2, kDataTableName, kDefine, kDataSchemaName, kDataDatabase); 
        res = new IR(kOptTempTableName, OP3("LOCAL TEMPORARY", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | LOCAL TEMP opt_table qualified_name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(243135,171318); // mapping from OptTempTableName to opt_table
        	gram_cov->log_edge_cov_map(243135,38734); // mapping from OptTempTableName to qualified_name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        auto tmp2 = $4;
        setup_qualified_name(tmp2, kDataTableName, kDefine, kDataSchemaName, kDataDatabase); 
        res = new IR(kOptTempTableName, OP3("LOCAL TEMP", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | GLOBAL TEMPORARY opt_table qualified_name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(243135,171318); // mapping from OptTempTableName to opt_table
        	gram_cov->log_edge_cov_map(243135,38734); // mapping from OptTempTableName to qualified_name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        auto tmp2 = $4;
        setup_qualified_name(tmp2, kDataTableName, kDefine, kDataSchemaName, kDataDatabase); 
        res = new IR(kOptTempTableName, OP3("GLOBAL TEMPORARY", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | GLOBAL TEMP opt_table qualified_name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(243135,171318); // mapping from OptTempTableName to opt_table
        	gram_cov->log_edge_cov_map(243135,38734); // mapping from OptTempTableName to qualified_name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        auto tmp2 = $4;
        setup_qualified_name(tmp2, kDataTableName, kDefine, kDataSchemaName, kDataDatabase); 
        res = new IR(kOptTempTableName, OP3("GLOBAL TEMP", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | UNLOGGED opt_table qualified_name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(243135,171318); // mapping from OptTempTableName to opt_table
        	gram_cov->log_edge_cov_map(243135,38734); // mapping from OptTempTableName to qualified_name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        setup_qualified_name(tmp2, kDataTableName, kDefine, kDataSchemaName, kDataDatabase); 
        res = new IR(kOptTempTableName, OP3("UNLOGGED", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | TABLE qualified_name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(243135,38734); // mapping from OptTempTableName to qualified_name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        setup_qualified_name(tmp1, kDataTableName, kDefine, kDataSchemaName, kDataDatabase); 
        res = new IR(kOptTempTableName, OP3("TABLE", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | qualified_name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(243135,38734); // mapping from OptTempTableName to qualified_name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        setup_qualified_name(tmp1, kDataTableName, kDefine, kDataSchemaName, kDataDatabase); 
        res = new IR(kOptTempTableName, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_table:

    TABLE {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptTable, OP3("TABLE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptTable, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


all_or_distinct:

    ALL {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kAllOrDistinct, OP3("ALL", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | DISTINCT {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kAllOrDistinct, OP3("DISTINCT", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kAllOrDistinct, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


by_name:

    BY NAME_P {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kByName, OP3("BY NAME", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


distinct_clause:

    DISTINCT {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kDistinctClause, OP3("DISTINCT", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | DISTINCT ON '(' expr_list_opt_comma ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(1531,122642); // mapping from distinct_clause to expr_list_opt_comma
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $4;
        res = new IR(kDistinctClause, OP3("DISTINCT ON (", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_all_clause:

    ALL {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptAllClause, OP3("ALL", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptAllClause, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_ignore_nulls:

    IGNORE_P NULLS_P {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptIgnoreNulls, OP3("IGNORE NULLS", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | RESPECT_P NULLS_P {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptIgnoreNulls, OP3("RESPECT NULLS", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptIgnoreNulls, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_sort_clause:

    sort_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(260970,159625); // mapping from opt_sort_clause to sort_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kOptSortClause, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptSortClause, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


sort_clause:

    ORDER BY sortby_list {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(159625,52588); // mapping from sort_clause to sortby_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kSortClause, OP3("ORDER BY", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ORDER BY ALL opt_asc_desc opt_nulls_order {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(159625,161558); // mapping from sort_clause to opt_asc_desc
        	gram_cov->log_edge_cov_map(159625,80470); // mapping from sort_clause to opt_nulls_order
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $4;
        auto tmp2 = $5;
        res = new IR(kSortClause, OP3("ORDER BY ALL", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


sortby_list:

    sortby {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(52588,76220); // mapping from sortby_list to sortby
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kSortbyList, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | sortby_list ',' sortby {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(52588,52588); // mapping from sortby_list to sortby_list
        	gram_cov->log_edge_cov_map(52588,76220); // mapping from sortby_list to sortby
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSortbyList, OP3("", ",", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


sortby:

    a_expr USING qual_all_Op opt_nulls_order {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(76220,53205); // mapping from sortby to a_expr
        	gram_cov->log_edge_cov_map(76220,33650); // mapping from sortby to qual_all_Op
        	gram_cov->log_edge_cov_map(76220,80470); // mapping from sortby to opt_nulls_order
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSortby_1, OP3("", "USING", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $4;
        res = new IR(kSortby, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr opt_asc_desc opt_nulls_order {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(76220,53205); // mapping from sortby to a_expr
        	gram_cov->log_edge_cov_map(76220,161558); // mapping from sortby to opt_asc_desc
        	gram_cov->log_edge_cov_map(76220,80470); // mapping from sortby to opt_nulls_order
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSortby_2, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $3;
        res = new IR(kSortby, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_asc_desc:

    ASC_P {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptAscDesc, OP3("ASC", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | DESC_P {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptAscDesc, OP3("DESC", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptAscDesc, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_nulls_order:

    NULLS_LA FIRST_P {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptNullsOrder, OP3("NULLS FIRST", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | NULLS_LA LAST_P {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptNullsOrder, OP3("NULLS LAST", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptNullsOrder, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


select_limit:

    limit_clause offset_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(221475,9456); // mapping from select_limit to limit_clause
        	gram_cov->log_edge_cov_map(221475,206890); // mapping from select_limit to offset_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSelectLimit, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | offset_clause limit_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(221475,206890); // mapping from select_limit to offset_clause
        	gram_cov->log_edge_cov_map(221475,9456); // mapping from select_limit to limit_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSelectLimit, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | limit_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(221475,9456); // mapping from select_limit to limit_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kSelectLimit, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | offset_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(221475,206890); // mapping from select_limit to offset_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kSelectLimit, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_select_limit:

    select_limit {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(232132,221475); // mapping from opt_select_limit to select_limit
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kOptSelectLimit, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptSelectLimit, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


limit_clause:

    LIMIT select_limit_value {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(9456,221965); // mapping from limit_clause to select_limit_value
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kLimitClause, OP3("LIMIT", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | LIMIT select_limit_value ',' select_offset_value {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(9456,221965); // mapping from limit_clause to select_limit_value
        	gram_cov->log_edge_cov_map(9456,2300); // mapping from limit_clause to select_offset_value
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kLimitClause, OP3("LIMIT", ",", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | FETCH first_or_next select_fetch_first_value row_or_rows ONLY {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(9456,202493); // mapping from limit_clause to first_or_next
        	gram_cov->log_edge_cov_map(9456,65623); // mapping from limit_clause to select_fetch_first_value
        	gram_cov->log_edge_cov_map(9456,157891); // mapping from limit_clause to row_or_rows
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kLimitClause_1, OP3("FETCH", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $4;
        res = new IR(kLimitClause, OP3("", "", "ONLY"), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | FETCH first_or_next row_or_rows ONLY {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(9456,202493); // mapping from limit_clause to first_or_next
        	gram_cov->log_edge_cov_map(9456,157891); // mapping from limit_clause to row_or_rows
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kLimitClause, OP3("FETCH", "", "ONLY"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


offset_clause:

    OFFSET select_offset_value {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(206890,2300); // mapping from offset_clause to select_offset_value
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kOffsetClause, OP3("OFFSET", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | OFFSET select_fetch_first_value row_or_rows {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(206890,65623); // mapping from offset_clause to select_fetch_first_value
        	gram_cov->log_edge_cov_map(206890,157891); // mapping from offset_clause to row_or_rows
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kOffsetClause, OP3("OFFSET", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


sample_count:

    FCONST '%' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(133218,128351); // mapping from sample_count to FCONST
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = new IR(kFloatLiteral, cstr_to_string($1), kDataFixLater, kFlagUnknown);
        std::shared_ptr<IR> p_tmp1(tmp1, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_tmp1);
        res = new IR(kSampleCount, OP3("", "%", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ICONST '%' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(133218,35280); // mapping from sample_count to ICONST
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = new IR(kIntegerLiteral, $1);
        std::shared_ptr<IR> p_tmp1(tmp1, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_tmp1);
        res = new IR(kSampleCount, OP3("", "%", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | FCONST PERCENT {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(133218,128351); // mapping from sample_count to FCONST
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = new IR(kFloatLiteral, cstr_to_string($1), kDataFixLater, kFlagUnknown);
        std::shared_ptr<IR> p_tmp1(tmp1, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_tmp1);
        res = new IR(kSampleCount, OP3("", "PERCENT", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ICONST PERCENT {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(133218,35280); // mapping from sample_count to ICONST
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = new IR(kIntegerLiteral, $1);
        std::shared_ptr<IR> p_tmp1(tmp1, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_tmp1);
        res = new IR(kSampleCount, OP3("", "PERCENT", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ICONST {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(133218,35280); // mapping from sample_count to ICONST
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = new IR(kIntegerLiteral, $1);
        std::shared_ptr<IR> p_tmp1(tmp1, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_tmp1);
        res = new IR(kSampleCount, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ICONST ROWS {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(133218,35280); // mapping from sample_count to ICONST
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = new IR(kIntegerLiteral, $1);
        std::shared_ptr<IR> p_tmp1(tmp1, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_tmp1);
        res = new IR(kSampleCount, OP3("", "ROWS", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


sample_clause:

    USING SAMPLE tablesample_entry {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(39092,64665); // mapping from sample_clause to tablesample_entry
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kSampleClause, OP3("USING SAMPLE", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kSampleClause, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_sample_func:

    ColId {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(183190,133796); // mapping from opt_sample_func to ColId
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        setup_col_id(tmp1, kDataSampleFunction, kUse); 
        res = new IR(kOptSampleFunc, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptSampleFunc, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


tablesample_entry:

    opt_sample_func '(' sample_count ')' opt_repeatable_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(64665,183190); // mapping from tablesample_entry to opt_sample_func
        	gram_cov->log_edge_cov_map(64665,133218); // mapping from tablesample_entry to sample_count
        	gram_cov->log_edge_cov_map(64665,42088); // mapping from tablesample_entry to opt_repeatable_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTablesampleEntry_1, OP3("", "(", ")"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $5;
        res = new IR(kTablesampleEntry, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | sample_count {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(64665,133218); // mapping from tablesample_entry to sample_count
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kTablesampleEntry, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | sample_count '(' ColId ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(64665,133218); // mapping from tablesample_entry to sample_count
        	gram_cov->log_edge_cov_map(64665,133796); // mapping from tablesample_entry to ColId
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        setup_col_id(tmp2, kDataSampleFunction, kUse); 
        res = new IR(kTablesampleEntry, OP3("", "(", ")"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | sample_count '(' ColId ',' ICONST ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(64665,133218); // mapping from tablesample_entry to sample_count
        	gram_cov->log_edge_cov_map(64665,133796); // mapping from tablesample_entry to ColId
        	gram_cov->log_edge_cov_map(64665,35280); // mapping from tablesample_entry to ICONST
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        setup_col_id(tmp2, kDataSampleFunction, kUse); 
        res = new IR(kTablesampleEntry_2, OP3("", "(", ","), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = new IR(kIntegerLiteral, $5);
        std::shared_ptr<IR> p_tmp3(tmp3, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_tmp3);
        res = new IR(kTablesampleEntry, OP3("", "", ")"), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


tablesample_clause:

    TABLESAMPLE tablesample_entry {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(235669,64665); // mapping from tablesample_clause to tablesample_entry
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kTablesampleClause, OP3("TABLESAMPLE", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_tablesample_clause:

    tablesample_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(192058,235669); // mapping from opt_tablesample_clause to tablesample_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kOptTablesampleClause, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptTablesampleClause, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_repeatable_clause:

    REPEATABLE '(' ICONST ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(42088,35280); // mapping from opt_repeatable_clause to ICONST
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = new IR(kIntegerLiteral, $3);
        std::shared_ptr<IR> p_tmp1(tmp1, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_tmp1);
        res = new IR(kOptRepeatableClause, OP3("REPEATABLE (", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptRepeatableClause, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


select_limit_value:

    a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(221965,53205); // mapping from select_limit_value to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kSelectLimitValue, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ALL {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kSelectLimitValue, OP3("ALL", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr '%' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(221965,53205); // mapping from select_limit_value to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kSelectLimitValue, OP3("", "%", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | FCONST PERCENT {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(221965,128351); // mapping from select_limit_value to FCONST
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = new IR(kFloatLiteral, cstr_to_string($1), kDataFixLater, kFlagUnknown);
        std::shared_ptr<IR> p_tmp1(tmp1, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_tmp1);
        res = new IR(kSelectLimitValue, OP3("", "PERCENT", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ICONST PERCENT {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(221965,35280); // mapping from select_limit_value to ICONST
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = new IR(kIntegerLiteral, $1);
        std::shared_ptr<IR> p_tmp1(tmp1, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_tmp1);
        res = new IR(kSelectLimitValue, OP3("", "PERCENT", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


select_offset_value:

    a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(2300,53205); // mapping from select_offset_value to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kSelectOffsetValue, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


select_fetch_first_value:

    c_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(65623,178628); // mapping from select_fetch_first_value to c_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kSelectFetchFirstValue, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '+' I_or_F_const {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(65623,97701); // mapping from select_fetch_first_value to I_or_F_const
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kSelectFetchFirstValue, OP3("+", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '-' I_or_F_const {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(65623,97701); // mapping from select_fetch_first_value to I_or_F_const
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kSelectFetchFirstValue, OP3("-", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


I_or_F_const:

    Iconst {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(97701,255753); // mapping from I_or_F_const to Iconst
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kIOrFConst, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | FCONST {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(97701,128351); // mapping from I_or_F_const to FCONST
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = new IR(kFloatLiteral, cstr_to_string($1), kDataFixLater, kFlagUnknown);
        std::shared_ptr<IR> p_tmp1(tmp1, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_tmp1);
        res = new IR(kIOrFConst, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


row_or_rows:

    ROW {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kRowOrRows, OP3("ROW", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ROWS {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kRowOrRows, OP3("ROWS", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


first_or_next:

    FIRST_P {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kFirstOrNext, OP3("FIRST", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | NEXT {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kFirstOrNext, OP3("NEXT", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


group_clause:

    GROUP_P BY group_by_list_opt_comma {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(60109,133024); // mapping from group_clause to group_by_list_opt_comma
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kGroupClause, OP3("GROUP BY", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | GROUP_P BY ALL {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kGroupClause, OP3("GROUP BY ALL", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kGroupClause, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


group_by_list:

    group_by_item {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(70032,9868); // mapping from group_by_list to group_by_item
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kGroupByList, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | group_by_list ',' group_by_item {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(70032,70032); // mapping from group_by_list to group_by_list
        	gram_cov->log_edge_cov_map(70032,9868); // mapping from group_by_list to group_by_item
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kGroupByList, OP3("", ",", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


group_by_list_opt_comma:

    group_by_list {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(133024,70032); // mapping from group_by_list_opt_comma to group_by_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kGroupByListOptComma, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | group_by_list ',' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(133024,70032); // mapping from group_by_list_opt_comma to group_by_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kGroupByListOptComma, OP3("", ",", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


group_by_item:

    a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(9868,53205); // mapping from group_by_item to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kGroupByItem, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | empty_grouping_set {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(9868,110958); // mapping from group_by_item to empty_grouping_set
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kGroupByItem, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | cube_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(9868,104703); // mapping from group_by_item to cube_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kGroupByItem, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | rollup_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(9868,85717); // mapping from group_by_item to rollup_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kGroupByItem, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | grouping_sets_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(9868,152548); // mapping from group_by_item to grouping_sets_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kGroupByItem, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


empty_grouping_set:

    '(' ')' {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kEmptyGroupingSet, OP3("( )", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


rollup_clause:

    ROLLUP '(' expr_list_opt_comma ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(85717,122642); // mapping from rollup_clause to expr_list_opt_comma
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kRollupClause, OP3("ROLLUP (", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


cube_clause:

    CUBE '(' expr_list_opt_comma ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(104703,122642); // mapping from cube_clause to expr_list_opt_comma
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kCubeClause, OP3("CUBE (", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


grouping_sets_clause:

    GROUPING SETS '(' group_by_list_opt_comma ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(152548,133024); // mapping from grouping_sets_clause to group_by_list_opt_comma
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $4;
        res = new IR(kGroupingSetsClause, OP3("GROUPING SETS (", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


grouping_or_grouping_id:

    GROUPING {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kGroupingOrGroupingId, OP3("GROUPING", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | GROUPING_ID {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kGroupingOrGroupingId, OP3("GROUPING_ID", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


having_clause:

    HAVING a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(107493,53205); // mapping from having_clause to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kHavingClause, OP3("HAVING", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kHavingClause, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


qualify_clause:

    QUALIFY a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(106890,53205); // mapping from qualify_clause to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kQualifyClause, OP3("QUALIFY", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kQualifyClause, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


for_locking_clause:

    for_locking_items {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(148643,11519); // mapping from for_locking_clause to for_locking_items
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kForLockingClause, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | FOR READ_P ONLY {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kForLockingClause, OP3("FOR READ ONLY", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_for_locking_clause:

    for_locking_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(217976,148643); // mapping from opt_for_locking_clause to for_locking_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kOptForLockingClause, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptForLockingClause, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


for_locking_items:

    for_locking_item {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(11519,180834); // mapping from for_locking_items to for_locking_item
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kForLockingItems, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | for_locking_items for_locking_item {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(11519,11519); // mapping from for_locking_items to for_locking_items
        	gram_cov->log_edge_cov_map(11519,180834); // mapping from for_locking_items to for_locking_item
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kForLockingItems, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


for_locking_item:

    for_locking_strength locked_rels_list opt_nowait_or_skip {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(180834,133857); // mapping from for_locking_item to for_locking_strength
        	gram_cov->log_edge_cov_map(180834,5125); // mapping from for_locking_item to locked_rels_list
        	gram_cov->log_edge_cov_map(180834,111832); // mapping from for_locking_item to opt_nowait_or_skip
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kForLockingItem_1, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $3;
        res = new IR(kForLockingItem, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


for_locking_strength:

    FOR UPDATE {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kForLockingStrength, OP3("FOR UPDATE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | FOR NO KEY UPDATE {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kForLockingStrength, OP3("FOR NO KEY UPDATE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | FOR SHARE {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kForLockingStrength, OP3("FOR SHARE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | FOR KEY SHARE {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kForLockingStrength, OP3("FOR KEY SHARE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


locked_rels_list:

    OF qualified_name_list {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(5125,38746); // mapping from locked_rels_list to qualified_name_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        setup_qualified_name_list(tmp1, kDataTableName, kUse, kDataSchemaName, kDataDatabase); 
        res = new IR(kLockedRelsList, OP3("OF", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kLockedRelsList, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_nowait_or_skip:

    NOWAIT {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptNowaitOrSkip, OP3("NOWAIT", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | SKIP LOCKED {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptNowaitOrSkip, OP3("SKIP LOCKED", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptNowaitOrSkip, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


values_clause:

    VALUES '(' expr_list_opt_comma ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(235834,122642); // mapping from values_clause to expr_list_opt_comma
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kValuesClause, OP3("VALUES (", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | values_clause ',' '(' expr_list_opt_comma ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(235834,235834); // mapping from values_clause to values_clause
        	gram_cov->log_edge_cov_map(235834,122642); // mapping from values_clause to expr_list_opt_comma
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kValuesClause, OP3("", ", (", ")"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


values_clause_opt_comma:

    values_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(239110,235834); // mapping from values_clause_opt_comma to values_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kValuesClauseOptComma, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | values_clause ',' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(239110,235834); // mapping from values_clause_opt_comma to values_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kValuesClauseOptComma, OP3("", ",", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


from_clause:

    FROM from_list_opt_comma {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(2951,94901); // mapping from from_clause to from_list_opt_comma
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kFromClause, OP3("FROM", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kFromClause, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


from_list:

    table_ref {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(204196,125471); // mapping from from_list to table_ref
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kFromList, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | from_list ',' table_ref {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(204196,204196); // mapping from from_list to from_list
        	gram_cov->log_edge_cov_map(204196,125471); // mapping from from_list to table_ref
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kFromList, OP3("", ",", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


from_list_opt_comma:

    from_list {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(94901,204196); // mapping from from_list_opt_comma to from_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kFromListOptComma, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | from_list ',' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(94901,204196); // mapping from from_list_opt_comma to from_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kFromListOptComma, OP3("", ",", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


table_ref:

    relation_expr opt_alias_clause opt_tablesample_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(125471,135212); // mapping from table_ref to relation_expr
        	gram_cov->log_edge_cov_map(125471,33335); // mapping from table_ref to opt_alias_clause
        	gram_cov->log_edge_cov_map(125471,192058); // mapping from table_ref to opt_tablesample_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        setup_relation_expr(tmp1, kDataTableName, kUse, kDataSchemaName, kDataDatabase); 
        auto tmp2 = $2;
        setup_opt_alias_clause(tmp2, kDataTableName, kDefine); 
        res = new IR(kTableRef_1, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $3;
        res = new IR(kTableRef, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | func_table func_alias_clause opt_tablesample_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(125471,194398); // mapping from table_ref to func_table
        	gram_cov->log_edge_cov_map(125471,19522); // mapping from table_ref to func_alias_clause
        	gram_cov->log_edge_cov_map(125471,192058); // mapping from table_ref to opt_tablesample_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        setup_func_alias_clause(tmp2, kDataTableName, kDefine); 
        res = new IR(kTableRef_2, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $3;
        res = new IR(kTableRef, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | values_clause_opt_comma alias_clause opt_tablesample_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(125471,239110); // mapping from table_ref to values_clause_opt_comma
        	gram_cov->log_edge_cov_map(125471,147232); // mapping from table_ref to alias_clause
        	gram_cov->log_edge_cov_map(125471,192058); // mapping from table_ref to opt_tablesample_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        setup_alias_clause(tmp2, kDataTableName, kDefine); 
        res = new IR(kTableRef_3, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $3;
        res = new IR(kTableRef, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | LATERAL_P func_table func_alias_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(125471,194398); // mapping from table_ref to func_table
        	gram_cov->log_edge_cov_map(125471,19522); // mapping from table_ref to func_alias_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        setup_func_alias_clause(tmp2, kDataTableName, kDefine); 
        res = new IR(kTableRef, OP3("LATERAL", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | select_with_parens opt_alias_clause opt_tablesample_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(125471,178444); // mapping from table_ref to select_with_parens
        	gram_cov->log_edge_cov_map(125471,33335); // mapping from table_ref to opt_alias_clause
        	gram_cov->log_edge_cov_map(125471,192058); // mapping from table_ref to opt_tablesample_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        setup_opt_alias_clause(tmp2, kDataTableName, kDefine); 
        res = new IR(kTableRef_4, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $3;
        res = new IR(kTableRef, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | LATERAL_P select_with_parens opt_alias_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(125471,178444); // mapping from table_ref to select_with_parens
        	gram_cov->log_edge_cov_map(125471,33335); // mapping from table_ref to opt_alias_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        setup_opt_alias_clause(tmp2, kDataTableName, kDefine); 
        res = new IR(kTableRef, OP3("LATERAL", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | joined_table {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(125471,205846); // mapping from table_ref to joined_table
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kTableRef, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '(' joined_table ')' alias_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(125471,205846); // mapping from table_ref to joined_table
        	gram_cov->log_edge_cov_map(125471,147232); // mapping from table_ref to alias_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $4;
        setup_alias_clause(tmp2, kDataTableName, kDefine); 
        res = new IR(kTableRef, OP3("(", ")", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | table_ref PIVOT '(' target_list_opt_comma FOR pivot_value_list opt_pivot_group_by ')' opt_alias_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(125471,125471); // mapping from table_ref to table_ref
        	gram_cov->log_edge_cov_map(125471,85316); // mapping from table_ref to target_list_opt_comma
        	gram_cov->log_edge_cov_map(125471,117538); // mapping from table_ref to pivot_value_list
        	gram_cov->log_edge_cov_map(125471,41423); // mapping from table_ref to opt_pivot_group_by
        	gram_cov->log_edge_cov_map(125471,33335); // mapping from table_ref to opt_alias_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kTableRef_5, OP3("", "PIVOT (", "FOR"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $6;
        res = new IR(kTableRef_6, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $7;
        res = new IR(kTableRef_7, OP3("", "", ")"), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp5 = $9;
        setup_opt_alias_clause(tmp5, kDataTableName, kDefine); 
        res = new IR(kTableRef, OP3("", "", ""), res, tmp5);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | table_ref UNPIVOT opt_include_nulls '(' unpivot_header FOR unpivot_value_list ')' opt_alias_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(125471,125471); // mapping from table_ref to table_ref
        	gram_cov->log_edge_cov_map(125471,160606); // mapping from table_ref to opt_include_nulls
        	gram_cov->log_edge_cov_map(125471,98282); // mapping from table_ref to unpivot_header
        	gram_cov->log_edge_cov_map(125471,144523); // mapping from table_ref to unpivot_value_list
        	gram_cov->log_edge_cov_map(125471,33335); // mapping from table_ref to opt_alias_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTableRef_8, OP3("", "UNPIVOT", "("), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $5;
        res = new IR(kTableRef_9, OP3("", "", "FOR"), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $7;
        res = new IR(kTableRef_10, OP3("", "", ")"), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp5 = $9;
        setup_opt_alias_clause(tmp5, kDataTableName, kDefine); 
        res = new IR(kTableRef, OP3("", "", ""), res, tmp5);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_pivot_group_by:

    GROUP_P BY name_list_opt_comma {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(41423,235789); // mapping from opt_pivot_group_by to name_list_opt_comma
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        setup_name_list_opt_comma(tmp1, kDataColumnName, kUse); 
        res = new IR(kOptPivotGroupBy, OP3("GROUP BY", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptPivotGroupBy, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_include_nulls:

    INCLUDE_P NULLS_P {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptIncludeNulls, OP3("INCLUDE NULLS", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | EXCLUDE NULLS_P {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptIncludeNulls, OP3("EXCLUDE NULLS", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptIncludeNulls, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


single_pivot_value:

    b_expr IN_P '(' target_list_opt_comma ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(200789,25763); // mapping from single_pivot_value to b_expr
        	gram_cov->log_edge_cov_map(200789,85316); // mapping from single_pivot_value to target_list_opt_comma
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kSinglePivotValue, OP3("", "IN (", ")"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | b_expr IN_P ColIdOrString {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(200789,25763); // mapping from single_pivot_value to b_expr
        	gram_cov->log_edge_cov_map(200789,227596); // mapping from single_pivot_value to ColIdOrString
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        setup_col_id_or_string(tmp2, kDataColumnName, kUse); 
        res = new IR(kSinglePivotValue, OP3("", "IN", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


pivot_header:

    d_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(111957,175387); // mapping from pivot_header to d_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kPivotHeader, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '(' c_expr_list_opt_comma ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(111957,38098); // mapping from pivot_header to c_expr_list_opt_comma
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kPivotHeader, OP3("(", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


pivot_value:

    pivot_header IN_P '(' target_list_opt_comma ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(259253,111957); // mapping from pivot_value to pivot_header
        	gram_cov->log_edge_cov_map(259253,85316); // mapping from pivot_value to target_list_opt_comma
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kPivotValue, OP3("", "IN (", ")"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | pivot_header IN_P ColIdOrString {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(259253,111957); // mapping from pivot_value to pivot_header
        	gram_cov->log_edge_cov_map(259253,227596); // mapping from pivot_value to ColIdOrString
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        setup_col_id_or_string(tmp2, kDataColumnName, kUse); 
        res = new IR(kPivotValue, OP3("", "IN", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


pivot_value_list:

    pivot_value {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(117538,259253); // mapping from pivot_value_list to pivot_value
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kPivotValueList, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | pivot_value_list pivot_value {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(117538,117538); // mapping from pivot_value_list to pivot_value_list
        	gram_cov->log_edge_cov_map(117538,259253); // mapping from pivot_value_list to pivot_value
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kPivotValueList, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


unpivot_header:

    ColIdOrString {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(98282,227596); // mapping from unpivot_header to ColIdOrString
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        setup_col_id_or_string(tmp1, kDataColumnName, kUse); 
        res = new IR(kUnpivotHeader, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '(' name_list_opt_comma ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(98282,235789); // mapping from unpivot_header to name_list_opt_comma
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        setup_name_list_opt_comma(tmp1, kDataColumnName, kUse); 
        res = new IR(kUnpivotHeader, OP3("(", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


unpivot_value:

    unpivot_header IN_P '(' target_list_opt_comma ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(123335,98282); // mapping from unpivot_value to unpivot_header
        	gram_cov->log_edge_cov_map(123335,85316); // mapping from unpivot_value to target_list_opt_comma
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kUnpivotValue, OP3("", "IN (", ")"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


unpivot_value_list:

    unpivot_value {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(144523,123335); // mapping from unpivot_value_list to unpivot_value
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kUnpivotValueList, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | unpivot_value_list unpivot_value {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(144523,144523); // mapping from unpivot_value_list to unpivot_value_list
        	gram_cov->log_edge_cov_map(144523,123335); // mapping from unpivot_value_list to unpivot_value
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUnpivotValueList, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


joined_table:

    '(' joined_table ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(205846,205846); // mapping from joined_table to joined_table
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kJoinedTable, OP3("(", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | table_ref CROSS JOIN table_ref {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(205846,125471); // mapping from joined_table to table_ref
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kJoinedTable, OP3("", "CROSS JOIN", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | table_ref join_type JOIN table_ref join_qual {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(205846,125471); // mapping from joined_table to table_ref
        	gram_cov->log_edge_cov_map(205846,199426); // mapping from joined_table to join_type
        	gram_cov->log_edge_cov_map(205846,90422); // mapping from joined_table to join_qual
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kJoinedTable_1, OP3("", "", "JOIN"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $4;
        res = new IR(kJoinedTable_2, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $5;
        res = new IR(kJoinedTable, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | table_ref JOIN table_ref join_qual {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(205846,125471); // mapping from joined_table to table_ref
        	gram_cov->log_edge_cov_map(205846,90422); // mapping from joined_table to join_qual
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kJoinedTable_3, OP3("", "JOIN", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $4;
        res = new IR(kJoinedTable, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | table_ref NATURAL join_type JOIN table_ref {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(205846,125471); // mapping from joined_table to table_ref
        	gram_cov->log_edge_cov_map(205846,199426); // mapping from joined_table to join_type
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kJoinedTable_4, OP3("", "NATURAL", "JOIN"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $5;
        res = new IR(kJoinedTable, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | table_ref NATURAL JOIN table_ref {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(205846,125471); // mapping from joined_table to table_ref
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kJoinedTable, OP3("", "NATURAL JOIN", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | table_ref ASOF join_type JOIN table_ref join_qual {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(205846,125471); // mapping from joined_table to table_ref
        	gram_cov->log_edge_cov_map(205846,199426); // mapping from joined_table to join_type
        	gram_cov->log_edge_cov_map(205846,90422); // mapping from joined_table to join_qual
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kJoinedTable_5, OP3("", "ASOF", "JOIN"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $5;
        res = new IR(kJoinedTable_6, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $6;
        res = new IR(kJoinedTable, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | table_ref ASOF JOIN table_ref join_qual {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(205846,125471); // mapping from joined_table to table_ref
        	gram_cov->log_edge_cov_map(205846,90422); // mapping from joined_table to join_qual
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kJoinedTable_7, OP3("", "ASOF JOIN", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $5;
        res = new IR(kJoinedTable, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | table_ref POSITIONAL JOIN table_ref {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(205846,125471); // mapping from joined_table to table_ref
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kJoinedTable, OP3("", "POSITIONAL JOIN", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | table_ref ANTI JOIN table_ref join_qual {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(205846,125471); // mapping from joined_table to table_ref
        	gram_cov->log_edge_cov_map(205846,90422); // mapping from joined_table to join_qual
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kJoinedTable_8, OP3("", "ANTI JOIN", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $5;
        res = new IR(kJoinedTable, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | table_ref SEMI JOIN table_ref join_qual {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(205846,125471); // mapping from joined_table to table_ref
        	gram_cov->log_edge_cov_map(205846,90422); // mapping from joined_table to join_qual
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kJoinedTable_9, OP3("", "SEMI JOIN", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $5;
        res = new IR(kJoinedTable, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


alias_clause:

    AS ColIdOrString '(' name_list_opt_comma ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(147232,227596); // mapping from alias_clause to ColIdOrString
        	gram_cov->log_edge_cov_map(147232,235789); // mapping from alias_clause to name_list_opt_comma
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kAliasClause, OP3("AS", "(", ")"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | AS ColIdOrString {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(147232,227596); // mapping from alias_clause to ColIdOrString
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kAliasClause, OP3("AS", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ColId '(' name_list_opt_comma ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(147232,133796); // mapping from alias_clause to ColId
        	gram_cov->log_edge_cov_map(147232,235789); // mapping from alias_clause to name_list_opt_comma
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAliasClause, OP3("", "(", ")"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ColId {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(147232,133796); // mapping from alias_clause to ColId
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kAliasClause, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_alias_clause:

    alias_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(33335,147232); // mapping from opt_alias_clause to alias_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kOptAliasClause, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptAliasClause, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


func_alias_clause:

    alias_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(19522,147232); // mapping from func_alias_clause to alias_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kFuncAliasClause, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | AS '(' TableFuncElementList ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(19522,183060); // mapping from func_alias_clause to TableFuncElementList
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kFuncAliasClause, OP3("AS (", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | AS ColIdOrString '(' TableFuncElementList ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(19522,227596); // mapping from func_alias_clause to ColIdOrString
        	gram_cov->log_edge_cov_map(19522,183060); // mapping from func_alias_clause to TableFuncElementList
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kFuncAliasClause, OP3("AS", "(", ")"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ColId '(' TableFuncElementList ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(19522,133796); // mapping from func_alias_clause to ColId
        	gram_cov->log_edge_cov_map(19522,183060); // mapping from func_alias_clause to TableFuncElementList
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kFuncAliasClause, OP3("", "(", ")"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kFuncAliasClause, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


join_type:

    FULL join_outer {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(199426,112346); // mapping from join_type to join_outer
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kJoinType, OP3("FULL", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | LEFT join_outer {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(199426,112346); // mapping from join_type to join_outer
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kJoinType, OP3("LEFT", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | RIGHT join_outer {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(199426,112346); // mapping from join_type to join_outer
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kJoinType, OP3("RIGHT", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | SEMI {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kJoinType, OP3("SEMI", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ANTI {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kJoinType, OP3("ANTI", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | INNER_P {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kJoinType, OP3("INNER", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


join_outer:

    OUTER_P {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kJoinOuter, OP3("OUTER", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kJoinOuter, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


join_qual:

    USING '(' name_list_opt_comma ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(90422,235789); // mapping from join_qual to name_list_opt_comma
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        setup_name_list_opt_comma(tmp1, kDataColumnName, kUse); 
        res = new IR(kJoinQual, OP3("USING (", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ON a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(90422,53205); // mapping from join_qual to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kJoinQual, OP3("ON", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


relation_expr:

    qualified_name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(135212,38734); // mapping from relation_expr to qualified_name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kRelationExpr, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | qualified_name '*' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(135212,38734); // mapping from relation_expr to qualified_name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kRelationExpr, OP3("", "*", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ONLY qualified_name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(135212,38734); // mapping from relation_expr to qualified_name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kRelationExpr, OP3("ONLY", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ONLY '(' qualified_name ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(135212,38734); // mapping from relation_expr to qualified_name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kRelationExpr, OP3("ONLY (", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


func_table:

    func_expr_windowless opt_ordinality {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(194398,18225); // mapping from func_table to func_expr_windowless
        	gram_cov->log_edge_cov_map(194398,144909); // mapping from func_table to opt_ordinality
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFuncTable, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ROWS FROM '(' rowsfrom_list ')' opt_ordinality {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(194398,240343); // mapping from func_table to rowsfrom_list
        	gram_cov->log_edge_cov_map(194398,144909); // mapping from func_table to opt_ordinality
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kFuncTable, OP3("ROWS FROM (", ")", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


rowsfrom_item:

    func_expr_windowless opt_col_def_list {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(230515,18225); // mapping from rowsfrom_item to func_expr_windowless
        	gram_cov->log_edge_cov_map(230515,9924); // mapping from rowsfrom_item to opt_col_def_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kRowsfromItem, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


rowsfrom_list:

    rowsfrom_item {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(240343,230515); // mapping from rowsfrom_list to rowsfrom_item
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kRowsfromList, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | rowsfrom_list ',' rowsfrom_item {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(240343,240343); // mapping from rowsfrom_list to rowsfrom_list
        	gram_cov->log_edge_cov_map(240343,230515); // mapping from rowsfrom_list to rowsfrom_item
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kRowsfromList, OP3("", ",", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_col_def_list:

    AS '(' TableFuncElementList ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(9924,183060); // mapping from opt_col_def_list to TableFuncElementList
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kOptColDefList, OP3("AS (", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptColDefList, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_ordinality:

    WITH_LA ORDINALITY {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptOrdinality, OP3("WITH ORDINALITY", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptOrdinality, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


where_clause:

    WHERE a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(16133,53205); // mapping from where_clause to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kWhereClause, OP3("WHERE", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kWhereClause, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


TableFuncElementList:

    TableFuncElement {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(183060,160282); // mapping from TableFuncElementList to TableFuncElement
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kTableFuncElementList, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | TableFuncElementList ',' TableFuncElement {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(183060,183060); // mapping from TableFuncElementList to TableFuncElementList
        	gram_cov->log_edge_cov_map(183060,160282); // mapping from TableFuncElementList to TableFuncElement
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTableFuncElementList, OP3("", ",", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


TableFuncElement:

    ColIdOrString Typename opt_collate_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(160282,227596); // mapping from TableFuncElement to ColIdOrString
        	gram_cov->log_edge_cov_map(160282,237247); // mapping from TableFuncElement to Typename
        	gram_cov->log_edge_cov_map(160282,152257); // mapping from TableFuncElement to opt_collate_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        setup_col_id_or_string(tmp1, kDataColumnName, kDefine); 
        auto tmp2 = $2;
        res = new IR(kTableFuncElement_1, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $3;
        res = new IR(kTableFuncElement, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_collate_clause:

    COLLATE any_name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(152257,38234); // mapping from opt_collate_clause to any_name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        setup_any_name(tmp1, kDataCollate, kUse, kDataSchemaName, kDataDatabase); 
        res = new IR(kOptCollateClause, OP3("COLLATE", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptCollateClause, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


colid_type_list:

    ColId Typename {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(205488,133796); // mapping from colid_type_list to ColId
        	gram_cov->log_edge_cov_map(205488,237247); // mapping from colid_type_list to Typename
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        setup_col_id(tmp1, kDataColumnName, kUse); 
        auto tmp2 = $2;
        res = new IR(kColidTypeList, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | colid_type_list ',' ColId Typename {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(205488,205488); // mapping from colid_type_list to colid_type_list
        	gram_cov->log_edge_cov_map(205488,133796); // mapping from colid_type_list to ColId
        	gram_cov->log_edge_cov_map(205488,237247); // mapping from colid_type_list to Typename
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        setup_col_id(tmp2, kDataColumnName, kUse); 
        res = new IR(kColidTypeList_1, OP3("", ",", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $4;
        res = new IR(kColidTypeList, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


RowOrStruct:

    ROW {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kRowOrStruct, OP3("ROW", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | STRUCT {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kRowOrStruct, OP3("STRUCT", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_Typename:

    Typename {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(54285,237247); // mapping from opt_Typename to Typename
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kOptTypename, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptTypename, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


Typename:

    SimpleTypename opt_array_bounds {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(237247,202278); // mapping from Typename to SimpleTypename
        	gram_cov->log_edge_cov_map(237247,151697); // mapping from Typename to opt_array_bounds
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kTypename, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | SETOF SimpleTypename opt_array_bounds {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(237247,202278); // mapping from Typename to SimpleTypename
        	gram_cov->log_edge_cov_map(237247,151697); // mapping from Typename to opt_array_bounds
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kTypename, OP3("SETOF", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | SimpleTypename ARRAY '[' Iconst ']' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(237247,202278); // mapping from Typename to SimpleTypename
        	gram_cov->log_edge_cov_map(237247,255753); // mapping from Typename to Iconst
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kTypename, OP3("", "ARRAY [", "]"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | SETOF SimpleTypename ARRAY '[' Iconst ']' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(237247,202278); // mapping from Typename to SimpleTypename
        	gram_cov->log_edge_cov_map(237247,255753); // mapping from Typename to Iconst
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $5;
        res = new IR(kTypename, OP3("SETOF", "ARRAY [", "]"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | SimpleTypename ARRAY {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(237247,202278); // mapping from Typename to SimpleTypename
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kTypename, OP3("", "ARRAY", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | SETOF SimpleTypename ARRAY {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(237247,202278); // mapping from Typename to SimpleTypename
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kTypename, OP3("SETOF", "ARRAY", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | RowOrStruct '(' colid_type_list ')' opt_array_bounds {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(237247,11339); // mapping from Typename to RowOrStruct
        	gram_cov->log_edge_cov_map(237247,205488); // mapping from Typename to colid_type_list
        	gram_cov->log_edge_cov_map(237247,151697); // mapping from Typename to opt_array_bounds
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTypename_1, OP3("", "(", ")"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $5;
        res = new IR(kTypename, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | MAP '(' type_list ')' opt_array_bounds {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(237247,134932); // mapping from Typename to type_list
        	gram_cov->log_edge_cov_map(237247,151697); // mapping from Typename to opt_array_bounds
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kTypename, OP3("MAP (", ")", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | UNION '(' colid_type_list ')' opt_array_bounds {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(237247,205488); // mapping from Typename to colid_type_list
        	gram_cov->log_edge_cov_map(237247,151697); // mapping from Typename to opt_array_bounds
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kTypename, OP3("UNION (", ")", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_array_bounds:

    opt_array_bounds '[' ']' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(151697,151697); // mapping from opt_array_bounds to opt_array_bounds
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kOptArrayBounds, OP3("", "[ ]", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | opt_array_bounds '[' Iconst ']' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(151697,151697); // mapping from opt_array_bounds to opt_array_bounds
        	gram_cov->log_edge_cov_map(151697,255753); // mapping from opt_array_bounds to Iconst
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kOptArrayBounds, OP3("", "[", "]"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptArrayBounds, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


SimpleTypename:

    GenericType {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(202278,298); // mapping from SimpleTypename to GenericType
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kSimpleTypename, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | Numeric {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(202278,76442); // mapping from SimpleTypename to Numeric
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kSimpleTypename, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | Bit {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(202278,242805); // mapping from SimpleTypename to Bit
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kSimpleTypename, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | Character {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(202278,147580); // mapping from SimpleTypename to Character
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kSimpleTypename, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ConstDatetime {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(202278,214601); // mapping from SimpleTypename to ConstDatetime
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kSimpleTypename, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ConstInterval opt_interval {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(202278,125918); // mapping from SimpleTypename to ConstInterval
        	gram_cov->log_edge_cov_map(202278,36701); // mapping from SimpleTypename to opt_interval
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSimpleTypename, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ConstInterval '(' Iconst ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(202278,125918); // mapping from SimpleTypename to ConstInterval
        	gram_cov->log_edge_cov_map(202278,255753); // mapping from SimpleTypename to Iconst
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSimpleTypename, OP3("", "(", ")"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


ConstTypename:

    Numeric {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(79933,76442); // mapping from ConstTypename to Numeric
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kConstTypename, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ConstBit {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(79933,155901); // mapping from ConstTypename to ConstBit
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kConstTypename, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ConstCharacter {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(79933,177820); // mapping from ConstTypename to ConstCharacter
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kConstTypename, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ConstDatetime {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(79933,214601); // mapping from ConstTypename to ConstDatetime
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kConstTypename, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


GenericType:

    type_name_token opt_type_modifiers {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(298,92547); // mapping from GenericType to type_name_token
        	gram_cov->log_edge_cov_map(298,192903); // mapping from GenericType to opt_type_modifiers
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kGenericType, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_type_modifiers:

    '(' opt_expr_list_opt_comma ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(192903,110285); // mapping from opt_type_modifiers to opt_expr_list_opt_comma
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kOptTypeModifiers, OP3("(", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptTypeModifiers, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


Numeric:

    INT_P {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kNumeric, OP3("INT", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | INTEGER {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kNumeric, OP3("INTEGER", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | SMALLINT {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kNumeric, OP3("SMALLINT", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | BIGINT {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kNumeric, OP3("BIGINT", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | REAL {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kNumeric, OP3("REAL", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | FLOAT_P opt_float {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(76442,251293); // mapping from Numeric to opt_float
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kNumeric, OP3("FLOAT", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | DOUBLE_P PRECISION {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kNumeric, OP3("DOUBLE PRECISION", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | DECIMAL_P opt_type_modifiers {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(76442,192903); // mapping from Numeric to opt_type_modifiers
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kNumeric, OP3("DECIMAL", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | DEC opt_type_modifiers {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(76442,192903); // mapping from Numeric to opt_type_modifiers
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kNumeric, OP3("DEC", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | NUMERIC opt_type_modifiers {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(76442,192903); // mapping from Numeric to opt_type_modifiers
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kNumeric, OP3("NUMERIC", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | BOOLEAN_P {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kNumeric, OP3("BOOLEAN", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_float:

    '(' Iconst ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(251293,255753); // mapping from opt_float to Iconst
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kOptFloat, OP3("(", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptFloat, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


Bit:

    BitWithLength {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(242805,252516); // mapping from Bit to BitWithLength
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kBit, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | BitWithoutLength {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(242805,122369); // mapping from Bit to BitWithoutLength
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kBit, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


ConstBit:

    BitWithLength {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(155901,252516); // mapping from ConstBit to BitWithLength
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kConstBit, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | BitWithoutLength {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(155901,122369); // mapping from ConstBit to BitWithoutLength
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kConstBit, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


BitWithLength:

    BIT opt_varying '(' expr_list_opt_comma ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(252516,151736); // mapping from BitWithLength to opt_varying
        	gram_cov->log_edge_cov_map(252516,122642); // mapping from BitWithLength to expr_list_opt_comma
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kBitWithLength, OP3("BIT", "(", ")"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


BitWithoutLength:

    BIT opt_varying {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(122369,151736); // mapping from BitWithoutLength to opt_varying
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kBitWithoutLength, OP3("BIT", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


Character:

    CharacterWithLength {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(147580,163297); // mapping from Character to CharacterWithLength
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kCharacter, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CharacterWithoutLength {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(147580,186214); // mapping from Character to CharacterWithoutLength
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kCharacter, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


ConstCharacter:

    CharacterWithLength {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(177820,163297); // mapping from ConstCharacter to CharacterWithLength
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kConstCharacter, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CharacterWithoutLength {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(177820,186214); // mapping from ConstCharacter to CharacterWithoutLength
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kConstCharacter, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


CharacterWithLength:

    character '(' Iconst ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(163297,12942); // mapping from CharacterWithLength to character
        	gram_cov->log_edge_cov_map(163297,255753); // mapping from CharacterWithLength to Iconst
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kCharacterWithLength, OP3("", "(", ")"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


CharacterWithoutLength:

    character {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(186214,12942); // mapping from CharacterWithoutLength to character
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kCharacterWithoutLength, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


character:

    CHARACTER opt_varying {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(12942,151736); // mapping from character to opt_varying
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kCharacter, OP3("CHARACTER", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CHAR_P opt_varying {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(12942,151736); // mapping from character to opt_varying
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kCharacter, OP3("CHAR", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | VARCHAR {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kCharacter, OP3("VARCHAR", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | NATIONAL CHARACTER opt_varying {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(12942,151736); // mapping from character to opt_varying
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kCharacter, OP3("NATIONAL CHARACTER", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | NATIONAL CHAR_P opt_varying {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(12942,151736); // mapping from character to opt_varying
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kCharacter, OP3("NATIONAL CHAR", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | NCHAR opt_varying {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(12942,151736); // mapping from character to opt_varying
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kCharacter, OP3("NCHAR", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_varying:

    VARYING {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptVarying, OP3("VARYING", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptVarying, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


ConstDatetime:

    TIMESTAMP '(' Iconst ')' opt_timezone {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(214601,255753); // mapping from ConstDatetime to Iconst
        	gram_cov->log_edge_cov_map(214601,65500); // mapping from ConstDatetime to opt_timezone
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kConstDatetime, OP3("TIMESTAMP (", ")", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | TIMESTAMP opt_timezone {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(214601,65500); // mapping from ConstDatetime to opt_timezone
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kConstDatetime, OP3("TIMESTAMP", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | TIME '(' Iconst ')' opt_timezone {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(214601,255753); // mapping from ConstDatetime to Iconst
        	gram_cov->log_edge_cov_map(214601,65500); // mapping from ConstDatetime to opt_timezone
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kConstDatetime, OP3("TIME (", ")", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | TIME opt_timezone {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(214601,65500); // mapping from ConstDatetime to opt_timezone
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kConstDatetime, OP3("TIME", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


ConstInterval:

    INTERVAL {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kConstInterval, OP3("INTERVAL", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_timezone:

    WITH_LA TIME ZONE {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptTimezone, OP3("WITH TIME ZONE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | WITHOUT TIME ZONE {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptTimezone, OP3("WITHOUT TIME ZONE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptTimezone, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


year_keyword:

    YEAR_P {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kYearKeyword, OP3("YEAR", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | YEARS_P {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kYearKeyword, OP3("YEARS", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


month_keyword:

    MONTH_P {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kMonthKeyword, OP3("MONTH", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | MONTHS_P {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kMonthKeyword, OP3("MONTHS", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


day_keyword:

    DAY_P {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kDayKeyword, OP3("DAY", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | DAYS_P {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kDayKeyword, OP3("DAYS", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


hour_keyword:

    HOUR_P {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kHourKeyword, OP3("HOUR", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | HOURS_P {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kHourKeyword, OP3("HOURS", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


minute_keyword:

    MINUTE_P {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kMinuteKeyword, OP3("MINUTE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | MINUTES_P {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kMinuteKeyword, OP3("MINUTES", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


second_keyword:

    SECOND_P {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kSecondKeyword, OP3("SECOND", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | SECONDS_P {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kSecondKeyword, OP3("SECONDS", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


millisecond_keyword:

    MILLISECOND_P {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kMillisecondKeyword, OP3("MILLISECOND", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | MILLISECONDS_P {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kMillisecondKeyword, OP3("MILLISECONDS", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


microsecond_keyword:

    MICROSECOND_P {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kMicrosecondKeyword, OP3("MICROSECOND", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | MICROSECONDS_P {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kMicrosecondKeyword, OP3("MICROSECONDS", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_interval:

    year_keyword {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(36701,250620); // mapping from opt_interval to year_keyword
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kOptInterval, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | month_keyword {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(36701,235707); // mapping from opt_interval to month_keyword
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kOptInterval, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | day_keyword {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(36701,101614); // mapping from opt_interval to day_keyword
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kOptInterval, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | hour_keyword {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(36701,102335); // mapping from opt_interval to hour_keyword
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kOptInterval, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | minute_keyword {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(36701,38492); // mapping from opt_interval to minute_keyword
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kOptInterval, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | second_keyword {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(36701,150596); // mapping from opt_interval to second_keyword
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kOptInterval, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | millisecond_keyword {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(36701,79816); // mapping from opt_interval to millisecond_keyword
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kOptInterval, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | microsecond_keyword {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(36701,218260); // mapping from opt_interval to microsecond_keyword
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kOptInterval, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | year_keyword TO month_keyword {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(36701,250620); // mapping from opt_interval to year_keyword
        	gram_cov->log_edge_cov_map(36701,235707); // mapping from opt_interval to month_keyword
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kOptInterval, OP3("", "TO", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | day_keyword TO hour_keyword {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(36701,101614); // mapping from opt_interval to day_keyword
        	gram_cov->log_edge_cov_map(36701,102335); // mapping from opt_interval to hour_keyword
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kOptInterval, OP3("", "TO", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | day_keyword TO minute_keyword {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(36701,101614); // mapping from opt_interval to day_keyword
        	gram_cov->log_edge_cov_map(36701,38492); // mapping from opt_interval to minute_keyword
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kOptInterval, OP3("", "TO", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | day_keyword TO second_keyword {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(36701,101614); // mapping from opt_interval to day_keyword
        	gram_cov->log_edge_cov_map(36701,150596); // mapping from opt_interval to second_keyword
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kOptInterval, OP3("", "TO", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | hour_keyword TO minute_keyword {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(36701,102335); // mapping from opt_interval to hour_keyword
        	gram_cov->log_edge_cov_map(36701,38492); // mapping from opt_interval to minute_keyword
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kOptInterval, OP3("", "TO", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | hour_keyword TO second_keyword {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(36701,102335); // mapping from opt_interval to hour_keyword
        	gram_cov->log_edge_cov_map(36701,150596); // mapping from opt_interval to second_keyword
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kOptInterval, OP3("", "TO", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | minute_keyword TO second_keyword {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(36701,38492); // mapping from opt_interval to minute_keyword
        	gram_cov->log_edge_cov_map(36701,150596); // mapping from opt_interval to second_keyword
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kOptInterval, OP3("", "TO", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptInterval, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


a_expr:

    c_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,178628); // mapping from a_expr to c_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kAExpr, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr TYPECAST Typename {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        	gram_cov->log_edge_cov_map(53205,237247); // mapping from a_expr to Typename
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "::", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr COLLATE any_name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        	gram_cov->log_edge_cov_map(53205,38234); // mapping from a_expr to any_name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        setup_any_name(tmp2, kDataCollate, kUse, kDataSchemaName, kDataDatabase); 
        res = new IR(kAExpr, OP3("", "COLLATE", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr AT TIME ZONE a_expr %prec AT {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $5;
        res = new IR(kAExpr, OP3("", "AT TIME ZONE", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '+' a_expr %prec UMINUS {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kAExpr, OP3("+", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '-' a_expr %prec UMINUS {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kAExpr, OP3("-", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr '+' a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "+", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr '-' a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "-", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr '*' a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "*", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr '/' a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "/", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr INTEGER_DIVISION a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "//", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr '%' a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "%", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr '^' a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "^", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr POWER_OF a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "**", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr '<' a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "<", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr '>' a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", ">", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr '=' a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "=", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr LESS_EQUALS a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "<=", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr GREATER_EQUALS a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", ">=", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr NOT_EQUALS a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "<>", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr qual_Op a_expr %prec Op {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        	gram_cov->log_edge_cov_map(53205,183992); // mapping from a_expr to qual_Op
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAExpr_1, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $3;
        res = new IR(kAExpr, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | qual_Op a_expr %prec Op {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,183992); // mapping from a_expr to qual_Op
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAExpr, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr qual_Op %prec POSTFIXOP {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        	gram_cov->log_edge_cov_map(53205,183992); // mapping from a_expr to qual_Op
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAExpr, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr AND a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "AND", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr OR a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "OR", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | NOT a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kAExpr, OP3("NOT", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | NOT_LA a_expr %prec NOT {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kAExpr, OP3("NOT", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr GLOB a_expr %prec GLOB {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "GLOB", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr LIKE a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "LIKE", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr LIKE a_expr ESCAPE a_expr %prec LIKE {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr_2, OP3("", "LIKE", "ESCAPE"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $5;
        res = new IR(kAExpr, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr NOT_LA LIKE a_expr %prec NOT_LA {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kAExpr, OP3("", "NOT LIKE", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr NOT_LA LIKE a_expr ESCAPE a_expr %prec NOT_LA {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kAExpr_3, OP3("", "NOT LIKE", "ESCAPE"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $6;
        res = new IR(kAExpr, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr ILIKE a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "ILIKE", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr ILIKE a_expr ESCAPE a_expr %prec ILIKE {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr_4, OP3("", "ILIKE", "ESCAPE"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $5;
        res = new IR(kAExpr, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr NOT_LA ILIKE a_expr %prec NOT_LA {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kAExpr, OP3("", "NOT ILIKE", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr NOT_LA ILIKE a_expr ESCAPE a_expr %prec NOT_LA {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kAExpr_5, OP3("", "NOT ILIKE", "ESCAPE"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $6;
        res = new IR(kAExpr, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr SIMILAR TO a_expr %prec SIMILAR {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kAExpr, OP3("", "SIMILAR TO", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr SIMILAR TO a_expr ESCAPE a_expr %prec SIMILAR {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kAExpr_6, OP3("", "SIMILAR TO", "ESCAPE"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $6;
        res = new IR(kAExpr, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr NOT_LA SIMILAR TO a_expr %prec NOT_LA {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $5;
        res = new IR(kAExpr, OP3("", "NOT SIMILAR TO", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr NOT_LA SIMILAR TO a_expr ESCAPE a_expr %prec NOT_LA {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $5;
        res = new IR(kAExpr_7, OP3("", "NOT SIMILAR TO", "ESCAPE"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $7;
        res = new IR(kAExpr, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr IS NULL_P %prec IS {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kAExpr, OP3("", "IS NULL", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr ISNULL {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kAExpr, OP3("", "ISNULL", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr IS NOT NULL_P %prec IS {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kAExpr, OP3("", "IS NOT NULL", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr NOT NULL_P {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kAExpr, OP3("", "NOT NULL", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr NOTNULL {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kAExpr, OP3("", "NOTNULL", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr LAMBDA_ARROW a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "LAMBDA_ARROW", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr DOUBLE_ARROW a_expr %prec Op {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "DOUBLE_ARROW", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | row OVERLAPS row {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,152186); // mapping from a_expr to row
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "OVERLAPS", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr IS TRUE_P %prec IS {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        	gram_cov->log_edge_cov_map(53205,68645); // mapping from a_expr to TRUE_P
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = new IR(kBoolLiteral, std::string("TRUE"));
        std::shared_ptr<IR> p_tmp2(tmp2, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_tmp2);
        res = new IR(kAExpr, OP3("", "IS", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr IS NOT TRUE_P %prec IS {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        	gram_cov->log_edge_cov_map(53205,68645); // mapping from a_expr to TRUE_P
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = new IR(kBoolLiteral, std::string("TRUE"));
        std::shared_ptr<IR> p_tmp2(tmp2, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_tmp2);
        res = new IR(kAExpr, OP3("", "IS NOT", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr IS FALSE_P %prec IS {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        	gram_cov->log_edge_cov_map(53205,17078); // mapping from a_expr to FALSE_P
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = new IR(kBoolLiteral, std::string("FALSE"));
        std::shared_ptr<IR> p_tmp2(tmp2, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_tmp2);
        res = new IR(kAExpr, OP3("", "IS", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr IS NOT FALSE_P %prec IS {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        	gram_cov->log_edge_cov_map(53205,17078); // mapping from a_expr to FALSE_P
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = new IR(kBoolLiteral, std::string("FALSE"));
        std::shared_ptr<IR> p_tmp2(tmp2, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_tmp2);
        res = new IR(kAExpr, OP3("", "IS NOT", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr IS UNKNOWN %prec IS {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kAExpr, OP3("", "IS UNKNOWN", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr IS NOT UNKNOWN %prec IS {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kAExpr, OP3("", "IS NOT UNKNOWN", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr IS DISTINCT FROM a_expr %prec IS {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $5;
        res = new IR(kAExpr, OP3("", "IS DISTINCT FROM", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr IS NOT DISTINCT FROM a_expr %prec IS {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $6;
        res = new IR(kAExpr, OP3("", "IS NOT DISTINCT FROM", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr IS OF '(' type_list ')' %prec IS {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        	gram_cov->log_edge_cov_map(53205,134932); // mapping from a_expr to type_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $5;
        res = new IR(kAExpr, OP3("", "IS OF (", ")"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr IS NOT OF '(' type_list ')' %prec IS {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        	gram_cov->log_edge_cov_map(53205,134932); // mapping from a_expr to type_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $6;
        res = new IR(kAExpr, OP3("", "IS NOT OF (", ")"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr BETWEEN opt_asymmetric b_expr AND a_expr %prec BETWEEN {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        	gram_cov->log_edge_cov_map(53205,176815); // mapping from a_expr to opt_asymmetric
        	gram_cov->log_edge_cov_map(53205,25763); // mapping from a_expr to b_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr_8, OP3("", "BETWEEN", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $4;
        res = new IR(kAExpr_9, OP3("", "", "AND"), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $6;
        res = new IR(kAExpr, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr NOT_LA BETWEEN opt_asymmetric b_expr AND a_expr %prec NOT_LA {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        	gram_cov->log_edge_cov_map(53205,176815); // mapping from a_expr to opt_asymmetric
        	gram_cov->log_edge_cov_map(53205,25763); // mapping from a_expr to b_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kAExpr_10, OP3("", "NOT BETWEEN", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $5;
        res = new IR(kAExpr_11, OP3("", "", "AND"), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $7;
        res = new IR(kAExpr, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr BETWEEN SYMMETRIC b_expr AND a_expr %prec BETWEEN {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        	gram_cov->log_edge_cov_map(53205,25763); // mapping from a_expr to b_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kAExpr_12, OP3("", "BETWEEN SYMMETRIC", "AND"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $6;
        res = new IR(kAExpr, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr NOT_LA BETWEEN SYMMETRIC b_expr AND a_expr %prec NOT_LA {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        	gram_cov->log_edge_cov_map(53205,25763); // mapping from a_expr to b_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $5;
        res = new IR(kAExpr_13, OP3("", "NOT BETWEEN SYMMETRIC", "AND"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $7;
        res = new IR(kAExpr, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr IN_P in_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        	gram_cov->log_edge_cov_map(53205,194757); // mapping from a_expr to in_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "IN", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr NOT_LA IN_P in_expr %prec NOT_LA {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        	gram_cov->log_edge_cov_map(53205,194757); // mapping from a_expr to in_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kAExpr, OP3("", "NOT IN", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr subquery_Op sub_type select_with_parens %prec Op {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        	gram_cov->log_edge_cov_map(53205,178554); // mapping from a_expr to subquery_Op
        	gram_cov->log_edge_cov_map(53205,243636); // mapping from a_expr to sub_type
        	gram_cov->log_edge_cov_map(53205,178444); // mapping from a_expr to select_with_parens
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAExpr_14, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $3;
        res = new IR(kAExpr_15, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $4;
        res = new IR(kAExpr, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr subquery_Op sub_type '(' a_expr ')' %prec Op {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        	gram_cov->log_edge_cov_map(53205,178554); // mapping from a_expr to subquery_Op
        	gram_cov->log_edge_cov_map(53205,243636); // mapping from a_expr to sub_type
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAExpr_16, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $3;
        res = new IR(kAExpr_17, OP3("", "", "("), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $5;
        res = new IR(kAExpr, OP3("", "", ")"), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | DEFAULT {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kAExpr, OP3("DEFAULT", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | COLUMNS '(' a_expr ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,53205); // mapping from a_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kAExpr, OP3("COLUMNS (", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '*' opt_except_list opt_replace_list {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,142060); // mapping from a_expr to opt_except_list
        	gram_cov->log_edge_cov_map(53205,155305); // mapping from a_expr to opt_replace_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("*", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ColId '.' '*' opt_except_list opt_replace_list {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(53205,133796); // mapping from a_expr to ColId
        	gram_cov->log_edge_cov_map(53205,142060); // mapping from a_expr to opt_except_list
        	gram_cov->log_edge_cov_map(53205,155305); // mapping from a_expr to opt_replace_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        setup_col_id(tmp1, kDataTableName, kUse); 
        auto tmp2 = $4;
        res = new IR(kAExpr_18, OP3("", ". *", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $5;
        res = new IR(kAExpr, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


b_expr:

    c_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(25763,178628); // mapping from b_expr to c_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kBExpr, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | b_expr TYPECAST Typename {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(25763,25763); // mapping from b_expr to b_expr
        	gram_cov->log_edge_cov_map(25763,237247); // mapping from b_expr to Typename
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBExpr, OP3("", "::", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '+' b_expr %prec UMINUS {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(25763,25763); // mapping from b_expr to b_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kBExpr, OP3("+", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '-' b_expr %prec UMINUS {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(25763,25763); // mapping from b_expr to b_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kBExpr, OP3("-", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | b_expr '+' b_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(25763,25763); // mapping from b_expr to b_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBExpr, OP3("", "+", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | b_expr '-' b_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(25763,25763); // mapping from b_expr to b_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBExpr, OP3("", "-", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | b_expr '*' b_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(25763,25763); // mapping from b_expr to b_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBExpr, OP3("", "*", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | b_expr '/' b_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(25763,25763); // mapping from b_expr to b_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBExpr, OP3("", "/", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | b_expr INTEGER_DIVISION b_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(25763,25763); // mapping from b_expr to b_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBExpr, OP3("", "//", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | b_expr '%' b_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(25763,25763); // mapping from b_expr to b_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBExpr, OP3("", "%", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | b_expr '^' b_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(25763,25763); // mapping from b_expr to b_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBExpr, OP3("", "^", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | b_expr POWER_OF b_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(25763,25763); // mapping from b_expr to b_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBExpr, OP3("", "**", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | b_expr '<' b_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(25763,25763); // mapping from b_expr to b_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBExpr, OP3("", "<", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | b_expr '>' b_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(25763,25763); // mapping from b_expr to b_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBExpr, OP3("", ">", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | b_expr '=' b_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(25763,25763); // mapping from b_expr to b_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBExpr, OP3("", "=", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | b_expr LESS_EQUALS b_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(25763,25763); // mapping from b_expr to b_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBExpr, OP3("", "<=", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | b_expr GREATER_EQUALS b_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(25763,25763); // mapping from b_expr to b_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBExpr, OP3("", ">=", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | b_expr NOT_EQUALS b_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(25763,25763); // mapping from b_expr to b_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBExpr, OP3("", "<>", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | b_expr qual_Op b_expr %prec Op {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(25763,25763); // mapping from b_expr to b_expr
        	gram_cov->log_edge_cov_map(25763,183992); // mapping from b_expr to qual_Op
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kBExpr_1, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $3;
        res = new IR(kBExpr, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | qual_Op b_expr %prec Op {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(25763,183992); // mapping from b_expr to qual_Op
        	gram_cov->log_edge_cov_map(25763,25763); // mapping from b_expr to b_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kBExpr, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | b_expr qual_Op %prec POSTFIXOP {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(25763,25763); // mapping from b_expr to b_expr
        	gram_cov->log_edge_cov_map(25763,183992); // mapping from b_expr to qual_Op
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kBExpr, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | b_expr IS DISTINCT FROM b_expr %prec IS {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(25763,25763); // mapping from b_expr to b_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $5;
        res = new IR(kBExpr, OP3("", "IS DISTINCT FROM", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | b_expr IS NOT DISTINCT FROM b_expr %prec IS {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(25763,25763); // mapping from b_expr to b_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $6;
        res = new IR(kBExpr, OP3("", "IS NOT DISTINCT FROM", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | b_expr IS OF '(' type_list ')' %prec IS {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(25763,25763); // mapping from b_expr to b_expr
        	gram_cov->log_edge_cov_map(25763,134932); // mapping from b_expr to type_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $5;
        res = new IR(kBExpr, OP3("", "IS OF (", ")"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | b_expr IS NOT OF '(' type_list ')' %prec IS {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(25763,25763); // mapping from b_expr to b_expr
        	gram_cov->log_edge_cov_map(25763,134932); // mapping from b_expr to type_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $6;
        res = new IR(kBExpr, OP3("", "IS NOT OF (", ")"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


c_expr:

    d_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(178628,175387); // mapping from c_expr to d_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kCExpr, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | row {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(178628,152186); // mapping from c_expr to row
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kCExpr, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | indirection_expr opt_extended_indirection {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(178628,163542); // mapping from c_expr to indirection_expr
        	gram_cov->log_edge_cov_map(178628,90633); // mapping from c_expr to opt_extended_indirection
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCExpr, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


d_expr:

    columnref {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(175387,77870); // mapping from d_expr to columnref
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kDExpr, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | AexprConst {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(175387,195113); // mapping from d_expr to AexprConst
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kDExpr, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '#' ICONST {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(175387,35280); // mapping from d_expr to ICONST
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = new IR(kIntegerLiteral, $2);
        std::shared_ptr<IR> p_tmp1(tmp1, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_tmp1);
        res = new IR(kDExpr, OP3("#", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '$' ColLabel {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(175387,197766); // mapping from d_expr to ColLabel
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        setup_col_label(tmp1, kDataColumnName, kUse); 
        res = new IR(kDExpr, OP3("$", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '[' opt_expr_list_opt_comma ']' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(175387,110285); // mapping from d_expr to opt_expr_list_opt_comma
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kDExpr, OP3("[", "]", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | list_comprehension {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(175387,223172); // mapping from d_expr to list_comprehension
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kDExpr, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ARRAY select_with_parens {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(175387,178444); // mapping from d_expr to select_with_parens
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kDExpr, OP3("ARRAY", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ARRAY '[' opt_expr_list_opt_comma ']' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(175387,110285); // mapping from d_expr to opt_expr_list_opt_comma
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kDExpr, OP3("ARRAY [", "]", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | case_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(175387,100595); // mapping from d_expr to case_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kDExpr, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | select_with_parens %prec UMINUS {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(175387,178444); // mapping from d_expr to select_with_parens
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kDExpr, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | select_with_parens indirection {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(175387,178444); // mapping from d_expr to select_with_parens
        	gram_cov->log_edge_cov_map(175387,101888); // mapping from d_expr to indirection
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kDExpr, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | EXISTS select_with_parens {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(175387,178444); // mapping from d_expr to select_with_parens
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kDExpr, OP3("EXISTS", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | grouping_or_grouping_id '(' expr_list_opt_comma ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(175387,171380); // mapping from d_expr to grouping_or_grouping_id
        	gram_cov->log_edge_cov_map(175387,122642); // mapping from d_expr to expr_list_opt_comma
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kDExpr, OP3("", "(", ")"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


indirection_expr:

    '?' {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kIndirectionExpr, OP3("?", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | PARAM {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(163542,81989); // mapping from indirection_expr to PARAM
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = new IR(kIntegerLiteral, $1);
        std::shared_ptr<IR> p_tmp1(tmp1, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_tmp1);
        res = new IR(kIndirectionExpr, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '(' a_expr ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(163542,53205); // mapping from indirection_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kIndirectionExpr, OP3("(", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | struct_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(163542,221179); // mapping from indirection_expr to struct_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kIndirectionExpr, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | MAP '{' opt_map_arguments_opt_comma '}' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(163542,154744); // mapping from indirection_expr to opt_map_arguments_opt_comma
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kIndirectionExpr, OP3("MAP {", "}", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | func_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(163542,57614); // mapping from indirection_expr to func_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kIndirectionExpr, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


struct_expr:

    '{' dict_arguments_opt_comma '}' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(221179,41124); // mapping from struct_expr to dict_arguments_opt_comma
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kStructExpr, OP3("{", "}", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


func_application:

    func_name '(' ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(80033,103567); // mapping from func_application to func_name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kFuncApplication, OP3("", "( )", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | func_name '(' func_arg_list opt_sort_clause opt_ignore_nulls ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(80033,103567); // mapping from func_application to func_name
        	gram_cov->log_edge_cov_map(80033,101501); // mapping from func_application to func_arg_list
        	gram_cov->log_edge_cov_map(80033,260970); // mapping from func_application to opt_sort_clause
        	gram_cov->log_edge_cov_map(80033,112897); // mapping from func_application to opt_ignore_nulls
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kFuncApplication_1, OP3("", "(", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $4;
        res = new IR(kFuncApplication_2, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $5;
        res = new IR(kFuncApplication, OP3("", "", ")"), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | func_name '(' VARIADIC func_arg_expr opt_sort_clause opt_ignore_nulls ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(80033,103567); // mapping from func_application to func_name
        	gram_cov->log_edge_cov_map(80033,181432); // mapping from func_application to func_arg_expr
        	gram_cov->log_edge_cov_map(80033,260970); // mapping from func_application to opt_sort_clause
        	gram_cov->log_edge_cov_map(80033,112897); // mapping from func_application to opt_ignore_nulls
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kFuncApplication_3, OP3("", "( VARIADIC", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $5;
        res = new IR(kFuncApplication_4, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $6;
        res = new IR(kFuncApplication, OP3("", "", ")"), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | func_name '(' func_arg_list ',' VARIADIC func_arg_expr opt_sort_clause opt_ignore_nulls ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(80033,103567); // mapping from func_application to func_name
        	gram_cov->log_edge_cov_map(80033,101501); // mapping from func_application to func_arg_list
        	gram_cov->log_edge_cov_map(80033,181432); // mapping from func_application to func_arg_expr
        	gram_cov->log_edge_cov_map(80033,260970); // mapping from func_application to opt_sort_clause
        	gram_cov->log_edge_cov_map(80033,112897); // mapping from func_application to opt_ignore_nulls
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kFuncApplication_5, OP3("", "(", ", VARIADIC"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $6;
        res = new IR(kFuncApplication_6, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $7;
        res = new IR(kFuncApplication_7, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp5 = $8;
        res = new IR(kFuncApplication, OP3("", "", ")"), res, tmp5);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | func_name '(' ALL func_arg_list opt_sort_clause opt_ignore_nulls ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(80033,103567); // mapping from func_application to func_name
        	gram_cov->log_edge_cov_map(80033,101501); // mapping from func_application to func_arg_list
        	gram_cov->log_edge_cov_map(80033,260970); // mapping from func_application to opt_sort_clause
        	gram_cov->log_edge_cov_map(80033,112897); // mapping from func_application to opt_ignore_nulls
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kFuncApplication_8, OP3("", "( ALL", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $5;
        res = new IR(kFuncApplication_9, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $6;
        res = new IR(kFuncApplication, OP3("", "", ")"), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | func_name '(' DISTINCT func_arg_list opt_sort_clause opt_ignore_nulls ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(80033,103567); // mapping from func_application to func_name
        	gram_cov->log_edge_cov_map(80033,101501); // mapping from func_application to func_arg_list
        	gram_cov->log_edge_cov_map(80033,260970); // mapping from func_application to opt_sort_clause
        	gram_cov->log_edge_cov_map(80033,112897); // mapping from func_application to opt_ignore_nulls
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kFuncApplication_10, OP3("", "( DISTINCT", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $5;
        res = new IR(kFuncApplication_11, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $6;
        res = new IR(kFuncApplication, OP3("", "", ")"), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


func_expr:

    func_application within_group_clause filter_clause export_clause over_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(57614,80033); // mapping from func_expr to func_application
        	gram_cov->log_edge_cov_map(57614,210883); // mapping from func_expr to within_group_clause
        	gram_cov->log_edge_cov_map(57614,158195); // mapping from func_expr to filter_clause
        	gram_cov->log_edge_cov_map(57614,254058); // mapping from func_expr to export_clause
        	gram_cov->log_edge_cov_map(57614,179622); // mapping from func_expr to over_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFuncExpr_1, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $3;
        res = new IR(kFuncExpr_2, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $4;
        res = new IR(kFuncExpr_3, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp5 = $5;
        res = new IR(kFuncExpr, OP3("", "", ""), res, tmp5);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | func_expr_common_subexpr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(57614,4705); // mapping from func_expr to func_expr_common_subexpr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kFuncExpr, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


func_expr_windowless:

    func_application {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(18225,80033); // mapping from func_expr_windowless to func_application
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kFuncExprWindowless, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | func_expr_common_subexpr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(18225,4705); // mapping from func_expr_windowless to func_expr_common_subexpr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kFuncExprWindowless, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


func_expr_common_subexpr:

    COLLATION FOR '(' a_expr ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(4705,53205); // mapping from func_expr_common_subexpr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $4;
        res = new IR(kFuncExprCommonSubexpr, OP3("COLLATION FOR (", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CAST '(' a_expr AS Typename ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(4705,53205); // mapping from func_expr_common_subexpr to a_expr
        	gram_cov->log_edge_cov_map(4705,237247); // mapping from func_expr_common_subexpr to Typename
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFuncExprCommonSubexpr, OP3("CAST (", "AS", ")"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | TRY_CAST '(' a_expr AS Typename ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(4705,53205); // mapping from func_expr_common_subexpr to a_expr
        	gram_cov->log_edge_cov_map(4705,237247); // mapping from func_expr_common_subexpr to Typename
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFuncExprCommonSubexpr, OP3("TRY_CAST (", "AS", ")"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | EXTRACT '(' extract_list ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(4705,235440); // mapping from func_expr_common_subexpr to extract_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kFuncExprCommonSubexpr, OP3("EXTRACT (", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | OVERLAY '(' overlay_list ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(4705,21601); // mapping from func_expr_common_subexpr to overlay_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kFuncExprCommonSubexpr, OP3("OVERLAY (", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | POSITION '(' position_list ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(4705,225279); // mapping from func_expr_common_subexpr to position_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kFuncExprCommonSubexpr, OP3("POSITION (", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | SUBSTRING '(' substr_list ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(4705,141895); // mapping from func_expr_common_subexpr to substr_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kFuncExprCommonSubexpr, OP3("SUBSTRING (", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | TREAT '(' a_expr AS Typename ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(4705,53205); // mapping from func_expr_common_subexpr to a_expr
        	gram_cov->log_edge_cov_map(4705,237247); // mapping from func_expr_common_subexpr to Typename
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFuncExprCommonSubexpr, OP3("TREAT (", "AS", ")"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | TRIM '(' BOTH trim_list ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(4705,16122); // mapping from func_expr_common_subexpr to trim_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $4;
        res = new IR(kFuncExprCommonSubexpr, OP3("TRIM ( BOTH", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | TRIM '(' LEADING trim_list ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(4705,16122); // mapping from func_expr_common_subexpr to trim_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $4;
        res = new IR(kFuncExprCommonSubexpr, OP3("TRIM ( LEADING", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | TRIM '(' TRAILING trim_list ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(4705,16122); // mapping from func_expr_common_subexpr to trim_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $4;
        res = new IR(kFuncExprCommonSubexpr, OP3("TRIM ( TRAILING", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | TRIM '(' trim_list ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(4705,16122); // mapping from func_expr_common_subexpr to trim_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kFuncExprCommonSubexpr, OP3("TRIM (", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | NULLIF '(' a_expr ',' a_expr ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(4705,53205); // mapping from func_expr_common_subexpr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFuncExprCommonSubexpr, OP3("NULLIF (", ",", ")"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | COALESCE '(' expr_list_opt_comma ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(4705,122642); // mapping from func_expr_common_subexpr to expr_list_opt_comma
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kFuncExprCommonSubexpr, OP3("COALESCE (", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


list_comprehension:

    '[' a_expr FOR ColId IN_P a_expr ']' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(223172,53205); // mapping from list_comprehension to a_expr
        	gram_cov->log_edge_cov_map(223172,133796); // mapping from list_comprehension to ColId
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $4;
        setup_col_id(tmp2, kDataAliasName, kDefine); 
        res = new IR(kListComprehension_1, OP3("[", "FOR", "IN"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $6;
        res = new IR(kListComprehension, OP3("", "", "]"), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '[' a_expr FOR ColId IN_P c_expr IF_P a_expr']' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(223172,53205); // mapping from list_comprehension to a_expr
        	gram_cov->log_edge_cov_map(223172,133796); // mapping from list_comprehension to ColId
        	gram_cov->log_edge_cov_map(223172,178628); // mapping from list_comprehension to c_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $4;
        setup_col_id(tmp2, kDataAliasName, kDefine); 
        res = new IR(kListComprehension_2, OP3("[", "FOR", "IN"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $6;
        res = new IR(kListComprehension, OP3("", "", "IF A_EXPR']'"), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


within_group_clause:

    WITHIN GROUP_P '(' sort_clause ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(210883,159625); // mapping from within_group_clause to sort_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $4;
        res = new IR(kWithinGroupClause, OP3("WITHIN GROUP (", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kWithinGroupClause, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


filter_clause:

    FILTER '(' WHERE a_expr ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(158195,53205); // mapping from filter_clause to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $4;
        res = new IR(kFilterClause, OP3("FILTER ( WHERE", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | FILTER '(' a_expr ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(158195,53205); // mapping from filter_clause to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kFilterClause, OP3("FILTER (", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kFilterClause, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


export_clause:

    EXPORT_STATE {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kExportClause, OP3("EXPORT_STATE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kExportClause, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


window_clause:

    WINDOW window_definition_list {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(126674,95505); // mapping from window_clause to window_definition_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kWindowClause, OP3("WINDOW", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kWindowClause, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


window_definition_list:

    window_definition {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(95505,128587); // mapping from window_definition_list to window_definition
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kWindowDefinitionList, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | window_definition_list ',' window_definition {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(95505,95505); // mapping from window_definition_list to window_definition_list
        	gram_cov->log_edge_cov_map(95505,128587); // mapping from window_definition_list to window_definition
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kWindowDefinitionList, OP3("", ",", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


window_definition:

    ColId AS window_specification {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(128587,133796); // mapping from window_definition to ColId
        	gram_cov->log_edge_cov_map(128587,97873); // mapping from window_definition to window_specification
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        setup_col_id(tmp1, kDataWindowName, kDefine); 
        auto tmp2 = $3;
        res = new IR(kWindowDefinition, OP3("", "AS", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


over_clause:

    OVER window_specification {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(179622,97873); // mapping from over_clause to window_specification
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kOverClause, OP3("OVER", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | OVER ColId {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(179622,133796); // mapping from over_clause to ColId
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        setup_col_id(tmp1, kDataWindowName, kUse); 
        res = new IR(kOverClause, OP3("OVER", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOverClause, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


window_specification:

    '(' opt_existing_window_name opt_partition_clause opt_sort_clause opt_frame_clause ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(97873,245673); // mapping from window_specification to opt_existing_window_name
        	gram_cov->log_edge_cov_map(97873,79066); // mapping from window_specification to opt_partition_clause
        	gram_cov->log_edge_cov_map(97873,260970); // mapping from window_specification to opt_sort_clause
        	gram_cov->log_edge_cov_map(97873,140831); // mapping from window_specification to opt_frame_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kWindowSpecification_1, OP3("(", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $4;
        res = new IR(kWindowSpecification_2, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $5;
        res = new IR(kWindowSpecification, OP3("", "", ")"), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_existing_window_name:

    ColId {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(245673,133796); // mapping from opt_existing_window_name to ColId
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        setup_col_id(tmp1, kDataWindowName, kUse); 
        res = new IR(kOptExistingWindowName, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ %prec Op {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptExistingWindowName, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_partition_clause:

    PARTITION BY expr_list {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(79066,67626); // mapping from opt_partition_clause to expr_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kOptPartitionClause, OP3("PARTITION BY", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptPartitionClause, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_frame_clause:

    RANGE frame_extent {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(140831,27378); // mapping from opt_frame_clause to frame_extent
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kOptFrameClause, OP3("RANGE", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ROWS frame_extent {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(140831,27378); // mapping from opt_frame_clause to frame_extent
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kOptFrameClause, OP3("ROWS", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptFrameClause, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


frame_extent:

    frame_bound {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(27378,66734); // mapping from frame_extent to frame_bound
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kFrameExtent, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | BETWEEN frame_bound AND frame_bound {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(27378,66734); // mapping from frame_extent to frame_bound
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kFrameExtent, OP3("BETWEEN", "AND", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


frame_bound:

    UNBOUNDED PRECEDING {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kFrameBound, OP3("UNBOUNDED PRECEDING", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | UNBOUNDED FOLLOWING {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kFrameBound, OP3("UNBOUNDED FOLLOWING", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CURRENT_P ROW {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kFrameBound, OP3("CURRENT ROW", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr PRECEDING {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(66734,53205); // mapping from frame_bound to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kFrameBound, OP3("", "PRECEDING", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr FOLLOWING {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(66734,53205); // mapping from frame_bound to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kFrameBound, OP3("", "FOLLOWING", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


qualified_row:

    ROW '(' expr_list_opt_comma ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(197931,122642); // mapping from qualified_row to expr_list_opt_comma
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kQualifiedRow, OP3("ROW (", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ROW '(' ')' {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kQualifiedRow, OP3("ROW ( )", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


row:

    qualified_row {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(152186,197931); // mapping from row to qualified_row
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kRow, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '(' expr_list ',' a_expr ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(152186,67626); // mapping from row to expr_list
        	gram_cov->log_edge_cov_map(152186,53205); // mapping from row to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kRow, OP3("(", ",", ")"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


dict_arg:

    ColIdOrString ':' a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(117052,227596); // mapping from dict_arg to ColIdOrString
        	gram_cov->log_edge_cov_map(117052,53205); // mapping from dict_arg to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        setup_col_id_or_string(tmp1, kDataDictArg, kDefine); 
        auto tmp2 = $3;
        res = new IR(kDictArg, OP3("", ":", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


dict_arguments:

    dict_arg {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(168519,117052); // mapping from dict_arguments to dict_arg
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kDictArguments, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | dict_arguments ',' dict_arg {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(168519,168519); // mapping from dict_arguments to dict_arguments
        	gram_cov->log_edge_cov_map(168519,117052); // mapping from dict_arguments to dict_arg
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kDictArguments, OP3("", ",", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


dict_arguments_opt_comma:

    dict_arguments {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(41124,168519); // mapping from dict_arguments_opt_comma to dict_arguments
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kDictArgumentsOptComma, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | dict_arguments ',' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(41124,168519); // mapping from dict_arguments_opt_comma to dict_arguments
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kDictArgumentsOptComma, OP3("", ",", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


map_arg:

    a_expr ':' a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(159788,53205); // mapping from map_arg to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kMapArg, OP3("", ":", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


map_arguments:

    map_arg {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(191772,159788); // mapping from map_arguments to map_arg
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kMapArguments, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | map_arguments ',' map_arg {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(191772,191772); // mapping from map_arguments to map_arguments
        	gram_cov->log_edge_cov_map(191772,159788); // mapping from map_arguments to map_arg
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kMapArguments, OP3("", ",", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


map_arguments_opt_comma:

    map_arguments {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(130825,191772); // mapping from map_arguments_opt_comma to map_arguments
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kMapArgumentsOptComma, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | map_arguments ',' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(130825,191772); // mapping from map_arguments_opt_comma to map_arguments
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kMapArgumentsOptComma, OP3("", ",", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_map_arguments_opt_comma:

    map_arguments_opt_comma {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(154744,130825); // mapping from opt_map_arguments_opt_comma to map_arguments_opt_comma
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kOptMapArgumentsOptComma, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptMapArgumentsOptComma, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


sub_type:

    ANY {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kSubType, OP3("ANY", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | SOME {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kSubType, OP3("SOME", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ALL {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kSubType, OP3("ALL", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


all_Op:

    Op {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kAllOp, OP3("+", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | MathOp {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(207799,2941); // mapping from all_Op to MathOp
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kAllOp, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


MathOp:

    '+' {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kMathOp, OP3("+", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '-' {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kMathOp, OP3("-", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '*' {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kMathOp, OP3("*", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '/' {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kMathOp, OP3("/", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | INTEGER_DIVISION {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kMathOp, OP3("//", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '%' {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kMathOp, OP3("%", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '^' {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kMathOp, OP3("^", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | POWER_OF {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kMathOp, OP3("**", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '<' {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kMathOp, OP3("<", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '>' {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kMathOp, OP3(">", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '=' {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kMathOp, OP3("=", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | LESS_EQUALS {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kMathOp, OP3("<=", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | GREATER_EQUALS {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kMathOp, OP3(">=", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | NOT_EQUALS {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kMathOp, OP3("<>", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


qual_Op:

    Op {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kQualOp, OP3("+", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | OPERATOR '(' any_operator ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(183992,149835); // mapping from qual_Op to any_operator
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kQualOp, OP3("OPERATOR (", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


qual_all_Op:

    all_Op {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(33650,207799); // mapping from qual_all_Op to all_Op
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kQualAllOp, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | OPERATOR '(' any_operator ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(33650,149835); // mapping from qual_all_Op to any_operator
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kQualAllOp, OP3("OPERATOR (", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


subquery_Op:

    all_Op {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(178554,207799); // mapping from subquery_Op to all_Op
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kSubqueryOp, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | OPERATOR '(' any_operator ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(178554,149835); // mapping from subquery_Op to any_operator
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kSubqueryOp, OP3("OPERATOR (", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | LIKE {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kSubqueryOp, OP3("LIKE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | NOT_LA LIKE {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kSubqueryOp, OP3("NOT LIKE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | GLOB {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kSubqueryOp, OP3("GLOB", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | NOT_LA GLOB {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kSubqueryOp, OP3("NOT GLOB", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ILIKE {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kSubqueryOp, OP3("ILIKE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | NOT_LA ILIKE {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kSubqueryOp, OP3("NOT ILIKE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


any_operator:

    all_Op {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(149835,207799); // mapping from any_operator to all_Op
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kAnyOperator, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ColId '.' any_operator {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(149835,133796); // mapping from any_operator to ColId
        	gram_cov->log_edge_cov_map(149835,149835); // mapping from any_operator to any_operator
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        setup_col_id(tmp1, kDataColumnName, kUse); 
        auto tmp2 = $3;
        res = new IR(kAnyOperator, OP3("", ".", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


c_expr_list:

    c_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(16718,178628); // mapping from c_expr_list to c_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kCExprList, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | c_expr_list ',' c_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(16718,16718); // mapping from c_expr_list to c_expr_list
        	gram_cov->log_edge_cov_map(16718,178628); // mapping from c_expr_list to c_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kCExprList, OP3("", ",", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


c_expr_list_opt_comma:

    c_expr_list {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(38098,16718); // mapping from c_expr_list_opt_comma to c_expr_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kCExprListOptComma, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | c_expr_list ',' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(38098,16718); // mapping from c_expr_list_opt_comma to c_expr_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kCExprListOptComma, OP3("", ",", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


expr_list:

    a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(67626,53205); // mapping from expr_list to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExprList, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | expr_list ',' a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(67626,67626); // mapping from expr_list to expr_list
        	gram_cov->log_edge_cov_map(67626,53205); // mapping from expr_list to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kExprList, OP3("", ",", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


expr_list_opt_comma:

    expr_list {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(122642,67626); // mapping from expr_list_opt_comma to expr_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExprListOptComma, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | expr_list ',' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(122642,67626); // mapping from expr_list_opt_comma to expr_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExprListOptComma, OP3("", ",", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_expr_list_opt_comma:

    expr_list_opt_comma {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(110285,122642); // mapping from opt_expr_list_opt_comma to expr_list_opt_comma
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kOptExprListOptComma, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptExprListOptComma, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


func_arg_list:

    func_arg_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(101501,181432); // mapping from func_arg_list to func_arg_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kFuncArgList, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | func_arg_list ',' func_arg_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(101501,101501); // mapping from func_arg_list to func_arg_list
        	gram_cov->log_edge_cov_map(101501,181432); // mapping from func_arg_list to func_arg_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kFuncArgList, OP3("", ",", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


func_arg_expr:

    a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(181432,53205); // mapping from func_arg_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kFuncArgExpr, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | param_name COLON_EQUALS a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(181432,911); // mapping from func_arg_expr to param_name
        	gram_cov->log_edge_cov_map(181432,53205); // mapping from func_arg_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kFuncArgExpr, OP3("", "COLON_EQUALS", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | param_name EQUALS_GREATER a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(181432,911); // mapping from func_arg_expr to param_name
        	gram_cov->log_edge_cov_map(181432,53205); // mapping from func_arg_expr to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kFuncArgExpr, OP3("", "EQUALS_GREATER", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


type_list:

    Typename {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(134932,237247); // mapping from type_list to Typename
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kTypeList, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | type_list ',' Typename {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(134932,134932); // mapping from type_list to type_list
        	gram_cov->log_edge_cov_map(134932,237247); // mapping from type_list to Typename
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTypeList, OP3("", ",", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


extract_list:

    extract_arg FROM a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(235440,179250); // mapping from extract_list to extract_arg
        	gram_cov->log_edge_cov_map(235440,53205); // mapping from extract_list to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kExtractList, OP3("", "FROM", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kExtractList, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


extract_arg:

    IDENT {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(179250,69880); // mapping from extract_arg to IDENT
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = new IR(kIdentifier, cstr_to_string($1), kDataFixLater, kFlagUnknown);
        std::shared_ptr<IR> p_tmp1(tmp1, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_tmp1);
        res = new IR(kExtractArg, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | year_keyword {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(179250,250620); // mapping from extract_arg to year_keyword
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExtractArg, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | month_keyword {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(179250,235707); // mapping from extract_arg to month_keyword
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExtractArg, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | day_keyword {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(179250,101614); // mapping from extract_arg to day_keyword
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExtractArg, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | hour_keyword {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(179250,102335); // mapping from extract_arg to hour_keyword
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExtractArg, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | minute_keyword {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(179250,38492); // mapping from extract_arg to minute_keyword
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExtractArg, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | second_keyword {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(179250,150596); // mapping from extract_arg to second_keyword
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExtractArg, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | millisecond_keyword {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(179250,79816); // mapping from extract_arg to millisecond_keyword
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExtractArg, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | microsecond_keyword {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(179250,218260); // mapping from extract_arg to microsecond_keyword
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExtractArg, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | Sconst {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(179250,47445); // mapping from extract_arg to Sconst
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExtractArg, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


overlay_list:

    a_expr overlay_placing substr_from substr_for {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(21601,53205); // mapping from overlay_list to a_expr
        	gram_cov->log_edge_cov_map(21601,171688); // mapping from overlay_list to overlay_placing
        	gram_cov->log_edge_cov_map(21601,200874); // mapping from overlay_list to substr_from
        	gram_cov->log_edge_cov_map(21601,4844); // mapping from overlay_list to substr_for
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOverlayList_1, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $3;
        res = new IR(kOverlayList_2, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $4;
        res = new IR(kOverlayList, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr overlay_placing substr_from {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(21601,53205); // mapping from overlay_list to a_expr
        	gram_cov->log_edge_cov_map(21601,171688); // mapping from overlay_list to overlay_placing
        	gram_cov->log_edge_cov_map(21601,200874); // mapping from overlay_list to substr_from
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOverlayList_3, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $3;
        res = new IR(kOverlayList, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


overlay_placing:

    PLACING a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(171688,53205); // mapping from overlay_placing to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kOverlayPlacing, OP3("PLACING", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


position_list:

    b_expr IN_P b_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(225279,25763); // mapping from position_list to b_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kPositionList, OP3("", "IN", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kPositionList, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


substr_list:

    a_expr substr_from substr_for {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(141895,53205); // mapping from substr_list to a_expr
        	gram_cov->log_edge_cov_map(141895,200874); // mapping from substr_list to substr_from
        	gram_cov->log_edge_cov_map(141895,4844); // mapping from substr_list to substr_for
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSubstrList_1, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $3;
        res = new IR(kSubstrList, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr substr_for substr_from {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(141895,53205); // mapping from substr_list to a_expr
        	gram_cov->log_edge_cov_map(141895,4844); // mapping from substr_list to substr_for
        	gram_cov->log_edge_cov_map(141895,200874); // mapping from substr_list to substr_from
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSubstrList_2, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $3;
        res = new IR(kSubstrList, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr substr_from {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(141895,53205); // mapping from substr_list to a_expr
        	gram_cov->log_edge_cov_map(141895,200874); // mapping from substr_list to substr_from
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSubstrList, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr substr_for {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(141895,53205); // mapping from substr_list to a_expr
        	gram_cov->log_edge_cov_map(141895,4844); // mapping from substr_list to substr_for
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSubstrList, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | expr_list {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(141895,67626); // mapping from substr_list to expr_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kSubstrList, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kSubstrList, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


substr_from:

    FROM a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(200874,53205); // mapping from substr_from to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kSubstrFrom, OP3("FROM", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


substr_for:

    FOR a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(4844,53205); // mapping from substr_for to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kSubstrFor, OP3("FOR", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


trim_list:

    a_expr FROM expr_list_opt_comma {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(16122,53205); // mapping from trim_list to a_expr
        	gram_cov->log_edge_cov_map(16122,122642); // mapping from trim_list to expr_list_opt_comma
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTrimList, OP3("", "FROM", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | FROM expr_list_opt_comma {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(16122,122642); // mapping from trim_list to expr_list_opt_comma
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kTrimList, OP3("FROM", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | expr_list_opt_comma {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(16122,122642); // mapping from trim_list to expr_list_opt_comma
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kTrimList, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


in_expr:

    select_with_parens {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(194757,178444); // mapping from in_expr to select_with_parens
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kInExpr, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '(' expr_list_opt_comma ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(194757,122642); // mapping from in_expr to expr_list_opt_comma
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kInExpr, OP3("(", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


case_expr:

    CASE case_arg when_clause_list case_default END_P {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(100595,99975); // mapping from case_expr to case_arg
        	gram_cov->log_edge_cov_map(100595,114246); // mapping from case_expr to when_clause_list
        	gram_cov->log_edge_cov_map(100595,245964); // mapping from case_expr to case_default
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCaseExpr_1, OP3("CASE", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $4;
        res = new IR(kCaseExpr, OP3("", "", "END"), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


when_clause_list:

    when_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(114246,155075); // mapping from when_clause_list to when_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kWhenClauseList, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | when_clause_list when_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(114246,114246); // mapping from when_clause_list to when_clause_list
        	gram_cov->log_edge_cov_map(114246,155075); // mapping from when_clause_list to when_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kWhenClauseList, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


when_clause:

    WHEN a_expr THEN a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(155075,53205); // mapping from when_clause to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kWhenClause, OP3("WHEN", "THEN", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


case_default:

    ELSE a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(245964,53205); // mapping from case_default to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kCaseDefault, OP3("ELSE", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kCaseDefault, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


case_arg:

    a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(99975,53205); // mapping from case_arg to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kCaseArg, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kCaseArg, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


columnref:

    ColId {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(77870,133796); // mapping from columnref to ColId
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        setup_col_id(tmp1, kDataColumnName, kUse); 
        res = new IR(kColumnref, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ColId indirection {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(77870,133796); // mapping from columnref to ColId
        	gram_cov->log_edge_cov_map(77870,101888); // mapping from columnref to indirection
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        setup_col_id(tmp1, kDataColumnName, kUse); 
        auto tmp2 = $2;
        res = new IR(kColumnref, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


indirection_el:

    '[' a_expr ']' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(213976,53205); // mapping from indirection_el to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kIndirectionEl, OP3("[", "]", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '[' opt_slice_bound ':' opt_slice_bound ']' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(213976,243740); // mapping from indirection_el to opt_slice_bound
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kIndirectionEl, OP3("[", ":", "]"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '[' opt_slice_bound ':' opt_slice_bound ':' opt_slice_bound ']' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(213976,243740); // mapping from indirection_el to opt_slice_bound
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kIndirectionEl_1, OP3("[", ":", ":"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $6;
        res = new IR(kIndirectionEl, OP3("", "", "]"), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '[' opt_slice_bound ':' '-' ':' opt_slice_bound ']' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(213976,243740); // mapping from indirection_el to opt_slice_bound
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $6;
        res = new IR(kIndirectionEl, OP3("[", ": - :", "]"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_slice_bound:

    a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(243740,53205); // mapping from opt_slice_bound to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kOptSliceBound, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptSliceBound, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_indirection:

    /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptIndirection, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | opt_indirection indirection_el {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(83135,83135); // mapping from opt_indirection to opt_indirection
        	gram_cov->log_edge_cov_map(83135,213976); // mapping from opt_indirection to indirection_el
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptIndirection, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_func_arguments:

    /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptFuncArguments, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '(' ')' {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptFuncArguments, OP3("( )", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '(' func_arg_list ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(28357,101501); // mapping from opt_func_arguments to func_arg_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kOptFuncArguments, OP3("(", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


extended_indirection_el:

    '.' attr_name opt_func_arguments {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(243553,70483); // mapping from extended_indirection_el to attr_name
        	gram_cov->log_edge_cov_map(243553,28357); // mapping from extended_indirection_el to opt_func_arguments
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kExtendedIndirectionEl, OP3(".", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '[' a_expr ']' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(243553,53205); // mapping from extended_indirection_el to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kExtendedIndirectionEl, OP3("[", "]", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '[' opt_slice_bound ':' opt_slice_bound ']' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(243553,243740); // mapping from extended_indirection_el to opt_slice_bound
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kExtendedIndirectionEl, OP3("[", ":", "]"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '[' opt_slice_bound ':' opt_slice_bound ':' opt_slice_bound ']' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(243553,243740); // mapping from extended_indirection_el to opt_slice_bound
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kExtendedIndirectionEl_1, OP3("[", ":", ":"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $6;
        res = new IR(kExtendedIndirectionEl, OP3("", "", "]"), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '[' opt_slice_bound ':' '-' ':' opt_slice_bound ']' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(243553,243740); // mapping from extended_indirection_el to opt_slice_bound
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $6;
        res = new IR(kExtendedIndirectionEl, OP3("[", ": - :", "]"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


extended_indirection:

    extended_indirection_el {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(228735,243553); // mapping from extended_indirection to extended_indirection_el
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExtendedIndirection, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | extended_indirection extended_indirection_el {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(228735,228735); // mapping from extended_indirection to extended_indirection
        	gram_cov->log_edge_cov_map(228735,243553); // mapping from extended_indirection to extended_indirection_el
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kExtendedIndirection, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_extended_indirection:

    /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptExtendedIndirection, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | opt_extended_indirection extended_indirection_el {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(90633,90633); // mapping from opt_extended_indirection to opt_extended_indirection
        	gram_cov->log_edge_cov_map(90633,243553); // mapping from opt_extended_indirection to extended_indirection_el
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptExtendedIndirection, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_asymmetric:

    ASYMMETRIC {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptAsymmetric, OP3("ASYMMETRIC", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptAsymmetric, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_target_list_opt_comma:

    target_list_opt_comma {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(213781,85316); // mapping from opt_target_list_opt_comma to target_list_opt_comma
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kOptTargetListOptComma, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptTargetListOptComma, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


target_list:

    target_el {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(101266,192086); // mapping from target_list to target_el
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kTargetList, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | target_list ',' target_el {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(101266,101266); // mapping from target_list to target_list
        	gram_cov->log_edge_cov_map(101266,192086); // mapping from target_list to target_el
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTargetList, OP3("", ",", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


target_list_opt_comma:

    target_list {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(85316,101266); // mapping from target_list_opt_comma to target_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kTargetListOptComma, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | target_list ',' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(85316,101266); // mapping from target_list_opt_comma to target_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kTargetListOptComma, OP3("", ",", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


target_el:

    a_expr AS ColLabelOrString {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(192086,53205); // mapping from target_el to a_expr
        	gram_cov->log_edge_cov_map(192086,207922); // mapping from target_el to ColLabelOrString
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        setup_col_label_or_string(tmp2, kDataAliasName, kDefine); 
        res = new IR(kTargetEl, OP3("", "AS", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr IDENT {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(192086,53205); // mapping from target_el to a_expr
        	gram_cov->log_edge_cov_map(192086,69880); // mapping from target_el to IDENT
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = new IR(kIdentifier, cstr_to_string($2), kDataFixLater, kFlagUnknown);
        std::shared_ptr<IR> p_tmp2(tmp2, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_tmp2);
        res = new IR(kTargetEl, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(192086,53205); // mapping from target_el to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kTargetEl, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


except_list:

    EXCLUDE '(' name_list_opt_comma ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(124746,235789); // mapping from except_list to name_list_opt_comma
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        setup_name_list_opt_comma(tmp1, kDataColumnName, kUse); 
        res = new IR(kExceptList, OP3("EXCLUDE (", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | EXCLUDE ColId {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(124746,133796); // mapping from except_list to ColId
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        setup_col_id(tmp1, kDataColumnName, kUse); 
        res = new IR(kExceptList, OP3("EXCLUDE", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_except_list:

    except_list {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(142060,124746); // mapping from opt_except_list to except_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kOptExceptList, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptExceptList, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


replace_list_el:

    a_expr AS ColId {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(66505,53205); // mapping from replace_list_el to a_expr
        	gram_cov->log_edge_cov_map(66505,133796); // mapping from replace_list_el to ColId
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        setup_col_id(tmp2, kDataAliasName, kDefine); 
        res = new IR(kReplaceListEl, OP3("", "AS", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


replace_list:

    replace_list_el {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(137133,66505); // mapping from replace_list to replace_list_el
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kReplaceList, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | replace_list ',' replace_list_el {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(137133,137133); // mapping from replace_list to replace_list
        	gram_cov->log_edge_cov_map(137133,66505); // mapping from replace_list to replace_list_el
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kReplaceList, OP3("", ",", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


replace_list_opt_comma:

    replace_list {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(6055,137133); // mapping from replace_list_opt_comma to replace_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kReplaceListOptComma, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | replace_list ',' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(6055,137133); // mapping from replace_list_opt_comma to replace_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kReplaceListOptComma, OP3("", ",", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_replace_list:

    REPLACE '(' replace_list_opt_comma ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(155305,6055); // mapping from opt_replace_list to replace_list_opt_comma
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kOptReplaceList, OP3("REPLACE (", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | REPLACE replace_list_el {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(155305,66505); // mapping from opt_replace_list to replace_list_el
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kOptReplaceList, OP3("REPLACE", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptReplaceList, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


qualified_name_list:

    qualified_name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(38746,38734); // mapping from qualified_name_list to qualified_name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kQualifiedNameList, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | qualified_name_list ',' qualified_name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(38746,38746); // mapping from qualified_name_list to qualified_name_list
        	gram_cov->log_edge_cov_map(38746,38734); // mapping from qualified_name_list to qualified_name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kQualifiedNameList, OP3("", ",", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


name_list:

    name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(48207,212908); // mapping from name_list to name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kNameList, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | name_list ',' name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(48207,48207); // mapping from name_list to name_list
        	gram_cov->log_edge_cov_map(48207,212908); // mapping from name_list to name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kNameList, OP3("", ",", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


name_list_opt_comma:

    name_list {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(235789,48207); // mapping from name_list_opt_comma to name_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kNameListOptComma, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | name_list ',' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(235789,48207); // mapping from name_list_opt_comma to name_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kNameListOptComma, OP3("", ",", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


name_list_opt_comma_opt_bracket:

    name_list_opt_comma {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(85594,235789); // mapping from name_list_opt_comma_opt_bracket to name_list_opt_comma
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kNameListOptCommaOptBracket, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | '(' name_list_opt_comma ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(85594,235789); // mapping from name_list_opt_comma_opt_bracket to name_list_opt_comma
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kNameListOptCommaOptBracket, OP3("(", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


name:

    ColIdOrString {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(212908,227596); // mapping from name to ColIdOrString
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kName, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


func_name:

    function_name_token {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(103567,186909); // mapping from func_name to function_name_token
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kFuncName, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ColId indirection {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(103567,133796); // mapping from func_name to ColId
        	gram_cov->log_edge_cov_map(103567,101888); // mapping from func_name to indirection
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        setup_col_id(tmp1, kDataFunctionName, kUse); 
        auto tmp2 = $2;
        res = new IR(kFuncName, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


AexprConst:

    Iconst {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(195113,255753); // mapping from AexprConst to Iconst
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kAexprConst, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | FCONST {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(195113,128351); // mapping from AexprConst to FCONST
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = new IR(kFloatLiteral, cstr_to_string($1), kDataFixLater, kFlagUnknown);
        std::shared_ptr<IR> p_tmp1(tmp1, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_tmp1);
        res = new IR(kAexprConst, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | Sconst opt_indirection {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(195113,47445); // mapping from AexprConst to Sconst
        	gram_cov->log_edge_cov_map(195113,83135); // mapping from AexprConst to opt_indirection
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAexprConst, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | BCONST {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(195113,155110); // mapping from AexprConst to BCONST
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = new IR(kBinLiteral, cstr_to_string($1), kDataFixLater, kFlagUnknown);
        std::shared_ptr<IR> p_tmp1(tmp1, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_tmp1);
        res = new IR(kAexprConst, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | XCONST {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(195113,181112); // mapping from AexprConst to XCONST
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = new IR(kBinLiteral, cstr_to_string($1), kDataFixLater, kFlagUnknown);
        std::shared_ptr<IR> p_tmp1(tmp1, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_tmp1);
        res = new IR(kAexprConst, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | func_name Sconst {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(195113,103567); // mapping from AexprConst to func_name
        	gram_cov->log_edge_cov_map(195113,47445); // mapping from AexprConst to Sconst
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAexprConst, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | func_name '(' func_arg_list opt_sort_clause opt_ignore_nulls ')' Sconst {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(195113,103567); // mapping from AexprConst to func_name
        	gram_cov->log_edge_cov_map(195113,101501); // mapping from AexprConst to func_arg_list
        	gram_cov->log_edge_cov_map(195113,260970); // mapping from AexprConst to opt_sort_clause
        	gram_cov->log_edge_cov_map(195113,112897); // mapping from AexprConst to opt_ignore_nulls
        	gram_cov->log_edge_cov_map(195113,47445); // mapping from AexprConst to Sconst
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAexprConst_1, OP3("", "(", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $4;
        res = new IR(kAexprConst_2, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $5;
        res = new IR(kAexprConst_3, OP3("", "", ")"), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp5 = $7;
        res = new IR(kAexprConst, OP3("", "", ""), res, tmp5);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ConstTypename Sconst {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(195113,79933); // mapping from AexprConst to ConstTypename
        	gram_cov->log_edge_cov_map(195113,47445); // mapping from AexprConst to Sconst
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAexprConst, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ConstInterval '(' a_expr ')' opt_interval {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(195113,125918); // mapping from AexprConst to ConstInterval
        	gram_cov->log_edge_cov_map(195113,53205); // mapping from AexprConst to a_expr
        	gram_cov->log_edge_cov_map(195113,36701); // mapping from AexprConst to opt_interval
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAexprConst_4, OP3("", "(", ")"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $5;
        res = new IR(kAexprConst, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ConstInterval Iconst opt_interval {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(195113,125918); // mapping from AexprConst to ConstInterval
        	gram_cov->log_edge_cov_map(195113,255753); // mapping from AexprConst to Iconst
        	gram_cov->log_edge_cov_map(195113,36701); // mapping from AexprConst to opt_interval
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAexprConst_5, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $3;
        res = new IR(kAexprConst, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ConstInterval Sconst opt_interval {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(195113,125918); // mapping from AexprConst to ConstInterval
        	gram_cov->log_edge_cov_map(195113,47445); // mapping from AexprConst to Sconst
        	gram_cov->log_edge_cov_map(195113,36701); // mapping from AexprConst to opt_interval
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAexprConst_6, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $3;
        res = new IR(kAexprConst, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | TRUE_P {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(195113,68645); // mapping from AexprConst to TRUE_P
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = new IR(kBoolLiteral, std::string("TRUE"));
        std::shared_ptr<IR> p_tmp1(tmp1, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_tmp1);
        res = new IR(kAexprConst, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | FALSE_P {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(195113,17078); // mapping from AexprConst to FALSE_P
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = new IR(kBoolLiteral, std::string("FALSE"));
        std::shared_ptr<IR> p_tmp1(tmp1, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_tmp1);
        res = new IR(kAexprConst, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | NULL_P {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kAexprConst, OP3("NULL", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


Iconst:

    ICONST {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(255753,35280); // mapping from Iconst to ICONST
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = new IR(kIntegerLiteral, $1);
        std::shared_ptr<IR> p_tmp1(tmp1, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_tmp1);
        res = new IR(kIconst, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


type_function_name:

    IDENT {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(135898,69880); // mapping from type_function_name to IDENT
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = new IR(kIdentifier, cstr_to_string($1), kDataFixLater, kFlagUnknown);
        std::shared_ptr<IR> p_tmp1(tmp1, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_tmp1);
        res = new IR(kTypeFunctionName, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


function_name_token:

    IDENT {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(186909,69880); // mapping from function_name_token to IDENT
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = new IR(kIdentifier, cstr_to_string($1), kDataFixLater, kFlagUnknown);
        std::shared_ptr<IR> p_tmp1(tmp1, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_tmp1);
        res = new IR(kFunctionNameToken, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


type_name_token:

    IDENT {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(92547,69880); // mapping from type_name_token to IDENT
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = new IR(kIdentifier, cstr_to_string($1), kDataFixLater, kFlagUnknown);
        std::shared_ptr<IR> p_tmp1(tmp1, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_tmp1);
        res = new IR(kTypeNameToken, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


any_name:

    ColId {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(38234,133796); // mapping from any_name to ColId
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kAnyName, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ColId attrs {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(38234,133796); // mapping from any_name to ColId
        	gram_cov->log_edge_cov_map(38234,56910); // mapping from any_name to attrs
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAnyName, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


attrs:

    '.' attr_name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(56910,70483); // mapping from attrs to attr_name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kAttrs, OP3(".", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | attrs '.' attr_name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(56910,56910); // mapping from attrs to attrs
        	gram_cov->log_edge_cov_map(56910,70483); // mapping from attrs to attr_name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAttrs, OP3("", ".", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_name_list:

    '(' name_list_opt_comma ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(254483,235789); // mapping from opt_name_list to name_list_opt_comma
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kOptNameList, OP3("(", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptNameList, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


param_name:

    type_function_name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(911,135898); // mapping from param_name to type_function_name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kParamName, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


ColLabelOrString:

    ColLabel {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(207922,197766); // mapping from ColLabelOrString to ColLabel
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kColLabelOrString, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | SCONST {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(207922,26013); // mapping from ColLabelOrString to SCONST
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = new IR(kStringLiteral, cstr_to_string($1), kDataFixLater, kFlagUnknown);
        std::shared_ptr<IR> p_tmp1(tmp1, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_tmp1);
        res = new IR(kColLabelOrString, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


PrepareStmt:

    PREPARE name prep_type_clause AS PreparableStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(246258,212908); // mapping from PrepareStmt to name
        	gram_cov->log_edge_cov_map(246258,11726); // mapping from PrepareStmt to prep_type_clause
        	gram_cov->log_edge_cov_map(246258,147479); // mapping from PrepareStmt to PreparableStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        setup_name(tmp1, kDataPrepareName, kDefine); 
        auto tmp2 = $3;
        res = new IR(kPrepareStmt_1, OP3("PREPARE", "", "AS"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $5;
        res = new IR(kPrepareStmt, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


prep_type_clause:

    '(' type_list ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(11726,134932); // mapping from prep_type_clause to type_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kPrepTypeClause, OP3("(", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kPrepTypeClause, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


PreparableStmt:

    SelectStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(147479,70058); // mapping from PreparableStmt to SelectStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kPreparableStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | InsertStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(147479,254452); // mapping from PreparableStmt to InsertStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kPreparableStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | UpdateStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(147479,157714); // mapping from PreparableStmt to UpdateStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kPreparableStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CopyStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(147479,128531); // mapping from PreparableStmt to CopyStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kPreparableStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | DeleteStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(147479,147970); // mapping from PreparableStmt to DeleteStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kPreparableStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


CreateSchemaStmt:

    CREATE_P SCHEMA qualified_name OptSchemaEltList {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(248310,38734); // mapping from CreateSchemaStmt to qualified_name
        	gram_cov->log_edge_cov_map(248310,140967); // mapping from CreateSchemaStmt to OptSchemaEltList
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        setup_qualified_name(tmp1, kDataSchemaName, kDefine, kDataDatabase, kDataWhatever); 
        auto tmp2 = $4;
        res = new IR(kCreateSchemaStmt, OP3("CREATE SCHEMA", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CREATE_P SCHEMA IF_P NOT EXISTS qualified_name OptSchemaEltList {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(248310,38734); // mapping from CreateSchemaStmt to qualified_name
        	gram_cov->log_edge_cov_map(248310,140967); // mapping from CreateSchemaStmt to OptSchemaEltList
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $6;
        setup_qualified_name(tmp1, kDataSchemaName, kDefine, kDataDatabase, kDataWhatever); 
        auto tmp2 = $7;
        res = new IR(kCreateSchemaStmt, OP3("CREATE SCHEMA IF NOT EXISTS", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CREATE_P OR REPLACE SCHEMA qualified_name OptSchemaEltList {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(248310,38734); // mapping from CreateSchemaStmt to qualified_name
        	gram_cov->log_edge_cov_map(248310,140967); // mapping from CreateSchemaStmt to OptSchemaEltList
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $5;
        setup_qualified_name(tmp1, kDataSchemaName, kDefine, kDataDatabase, kDataWhatever); 
        auto tmp2 = $6;
        res = new IR(kCreateSchemaStmt, OP3("CREATE OR REPLACE SCHEMA", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


OptSchemaEltList:

    OptSchemaEltList schema_stmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(140967,140967); // mapping from OptSchemaEltList to OptSchemaEltList
        	gram_cov->log_edge_cov_map(140967,217145); // mapping from OptSchemaEltList to schema_stmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptSchemaEltList, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptSchemaEltList, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


schema_stmt:

    CreateStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(217145,139905); // mapping from schema_stmt to CreateStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kSchemaStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | IndexStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(217145,198169); // mapping from schema_stmt to IndexStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kSchemaStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CreateSeqStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(217145,206176); // mapping from schema_stmt to CreateSeqStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kSchemaStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ViewStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(217145,14948); // mapping from schema_stmt to ViewStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kSchemaStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


IndexStmt:

    CREATE_P opt_unique INDEX opt_concurrently opt_index_name ON qualified_name access_method_clause '(' index_params ')' opt_reloptions where_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(198169,63328); // mapping from IndexStmt to opt_unique
        	gram_cov->log_edge_cov_map(198169,197176); // mapping from IndexStmt to opt_concurrently
        	gram_cov->log_edge_cov_map(198169,81525); // mapping from IndexStmt to opt_index_name
        	gram_cov->log_edge_cov_map(198169,38734); // mapping from IndexStmt to qualified_name
        	gram_cov->log_edge_cov_map(198169,87022); // mapping from IndexStmt to access_method_clause
        	gram_cov->log_edge_cov_map(198169,97375); // mapping from IndexStmt to index_params
        	gram_cov->log_edge_cov_map(198169,232613); // mapping from IndexStmt to opt_reloptions
        	gram_cov->log_edge_cov_map(198169,16133); // mapping from IndexStmt to where_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kIndexStmt_1, OP3("CREATE", "INDEX", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $5;
        res = new IR(kIndexStmt_2, OP3("", "", "ON"), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $7;
        setup_qualified_name(tmp4, kDataTableName, kUse, kDataSchemaName, kDataDatabase); 
        res = new IR(kIndexStmt_3, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp5 = $8;
        res = new IR(kIndexStmt_4, OP3("", "", "("), res, tmp5);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp6 = $10;
        res = new IR(kIndexStmt_5, OP3("", "", ")"), res, tmp6);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp7 = $12;
        res = new IR(kIndexStmt_6, OP3("", "", ""), res, tmp7);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp8 = $13;
        res = new IR(kIndexStmt, OP3("", "", ""), res, tmp8);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CREATE_P opt_unique INDEX opt_concurrently IF_P NOT EXISTS index_name ON qualified_name access_method_clause '(' index_params ')' opt_reloptions where_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(198169,63328); // mapping from IndexStmt to opt_unique
        	gram_cov->log_edge_cov_map(198169,197176); // mapping from IndexStmt to opt_concurrently
        	gram_cov->log_edge_cov_map(198169,236172); // mapping from IndexStmt to index_name
        	gram_cov->log_edge_cov_map(198169,38734); // mapping from IndexStmt to qualified_name
        	gram_cov->log_edge_cov_map(198169,87022); // mapping from IndexStmt to access_method_clause
        	gram_cov->log_edge_cov_map(198169,97375); // mapping from IndexStmt to index_params
        	gram_cov->log_edge_cov_map(198169,232613); // mapping from IndexStmt to opt_reloptions
        	gram_cov->log_edge_cov_map(198169,16133); // mapping from IndexStmt to where_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kIndexStmt_7, OP3("CREATE", "INDEX", "IF NOT EXISTS"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $8;
        setup_index_name(tmp3, kDataIndexName, kDefine); 
        res = new IR(kIndexStmt_8, OP3("", "", "ON"), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $10;
        setup_qualified_name(tmp4, kDataTableName, kUse, kDataSchemaName, kDataDatabase); 
        res = new IR(kIndexStmt_9, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp5 = $11;
        res = new IR(kIndexStmt_10, OP3("", "", "("), res, tmp5);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp6 = $13;
        res = new IR(kIndexStmt_11, OP3("", "", ")"), res, tmp6);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp7 = $15;
        res = new IR(kIndexStmt_12, OP3("", "", ""), res, tmp7);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp8 = $16;
        res = new IR(kIndexStmt, OP3("", "", ""), res, tmp8);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


access_method:

    ColId {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(142057,133796); // mapping from access_method to ColId
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        setup_col_id(tmp1, kDataAccessMethod, kUse); 
        res = new IR(kAccessMethod, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


access_method_clause:

    USING access_method {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(87022,142057); // mapping from access_method_clause to access_method
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kAccessMethodClause, OP3("USING", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kAccessMethodClause, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_concurrently:

    CONCURRENTLY {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptConcurrently, OP3("CONCURRENTLY", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptConcurrently, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_index_name:

    index_name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(81525,236172); // mapping from opt_index_name to index_name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        setup_index_name(tmp1, kDataIndexName, kDefine); 
        res = new IR(kOptIndexName, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptIndexName, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_reloptions:

    WITH reloptions {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(232613,68978); // mapping from opt_reloptions to reloptions
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kOptReloptions, OP3("WITH", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptReloptions, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_unique:

    UNIQUE {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptUnique, OP3("UNIQUE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptUnique, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


AlterObjectSchemaStmt:

    ALTER TABLE relation_expr SET SCHEMA name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(241845,135212); // mapping from AlterObjectSchemaStmt to relation_expr
        	gram_cov->log_edge_cov_map(241845,212908); // mapping from AlterObjectSchemaStmt to name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        setup_relation_expr(tmp1, kDataTableName, kUse, kDataSchemaName, kDataDatabase); 
        auto tmp2 = $6;
        setup_name(tmp2, kDataDatabase, kUse); 
        res = new IR(kAlterObjectSchemaStmt, OP3("ALTER TABLE", "SET SCHEMA", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ALTER TABLE IF_P EXISTS relation_expr SET SCHEMA name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(241845,135212); // mapping from AlterObjectSchemaStmt to relation_expr
        	gram_cov->log_edge_cov_map(241845,212908); // mapping from AlterObjectSchemaStmt to name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $5;
        setup_relation_expr(tmp1, kDataTableName, kUse, kDataSchemaName, kDataDatabase); 
        auto tmp2 = $8;
        setup_name(tmp2, kDataDatabase, kUse); 
        res = new IR(kAlterObjectSchemaStmt, OP3("ALTER TABLE IF EXISTS", "SET SCHEMA", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ALTER SEQUENCE qualified_name SET SCHEMA name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(241845,38734); // mapping from AlterObjectSchemaStmt to qualified_name
        	gram_cov->log_edge_cov_map(241845,212908); // mapping from AlterObjectSchemaStmt to name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        setup_qualified_name(tmp1, kDataSequenceName, kUse, kDataSchemaName, kDataDatabase); 
        auto tmp2 = $6;
        setup_name(tmp2, kDataDatabase, kUse); 
        res = new IR(kAlterObjectSchemaStmt, OP3("ALTER SEQUENCE", "SET SCHEMA", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ALTER SEQUENCE IF_P EXISTS qualified_name SET SCHEMA name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(241845,38734); // mapping from AlterObjectSchemaStmt to qualified_name
        	gram_cov->log_edge_cov_map(241845,212908); // mapping from AlterObjectSchemaStmt to name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $5;
        setup_qualified_name(tmp1, kDataSequenceName, kUse, kDataSchemaName, kDataDatabase); 
        auto tmp2 = $8;
        setup_name(tmp2, kDataDatabase, kUse); 
        res = new IR(kAlterObjectSchemaStmt, OP3("ALTER SEQUENCE IF EXISTS", "SET SCHEMA", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ALTER VIEW qualified_name SET SCHEMA name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(241845,38734); // mapping from AlterObjectSchemaStmt to qualified_name
        	gram_cov->log_edge_cov_map(241845,212908); // mapping from AlterObjectSchemaStmt to name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        setup_qualified_name(tmp1, kDataViewName, kUse, kDataSchemaName, kDataDatabase); 
        auto tmp2 = $6;
        setup_name(tmp2, kDataDatabase, kUse); 
        res = new IR(kAlterObjectSchemaStmt, OP3("ALTER VIEW", "SET SCHEMA", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ALTER VIEW IF_P EXISTS qualified_name SET SCHEMA name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(241845,38734); // mapping from AlterObjectSchemaStmt to qualified_name
        	gram_cov->log_edge_cov_map(241845,212908); // mapping from AlterObjectSchemaStmt to name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $5;
        setup_qualified_name(tmp1, kDataViewName, kUse, kDataSchemaName, kDataDatabase); 
        auto tmp2 = $8;
        setup_name(tmp2, kDataDatabase, kUse); 
        res = new IR(kAlterObjectSchemaStmt, OP3("ALTER VIEW IF EXISTS", "SET SCHEMA", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


CheckPointStmt:

    FORCE CHECKPOINT opt_col_id {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(209782,139135); // mapping from CheckPointStmt to opt_col_id
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kCheckPointStmt, OP3("FORCE CHECKPOINT", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CHECKPOINT opt_col_id {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(209782,139135); // mapping from CheckPointStmt to opt_col_id
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kCheckPointStmt, OP3("CHECKPOINT", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_col_id:

    ColId {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(139135,133796); // mapping from opt_col_id to ColId
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        setup_col_id(tmp1, kDataCheckPointName, kUse); 
        res = new IR(kOptColId, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptColId, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


ExportStmt:

    EXPORT_P DATABASE Sconst copy_options {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(60855,47445); // mapping from ExportStmt to Sconst
        	gram_cov->log_edge_cov_map(60855,139201); // mapping from ExportStmt to copy_options
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kExportStmt, OP3("EXPORT DATABASE", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | EXPORT_P DATABASE ColId TO Sconst copy_options {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(60855,133796); // mapping from ExportStmt to ColId
        	gram_cov->log_edge_cov_map(60855,47445); // mapping from ExportStmt to Sconst
        	gram_cov->log_edge_cov_map(60855,139201); // mapping from ExportStmt to copy_options
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        setup_col_id(tmp1, kDataDatabase, kUse); 
        auto tmp2 = $5;
        res = new IR(kExportStmt_1, OP3("EXPORT DATABASE", "TO", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $6;
        res = new IR(kExportStmt, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


ImportStmt:

    IMPORT_P DATABASE Sconst {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(75502,47445); // mapping from ImportStmt to Sconst
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kImportStmt, OP3("IMPORT DATABASE", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


ExplainStmt:

    EXPLAIN ExplainableStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(101618,165350); // mapping from ExplainStmt to ExplainableStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kExplainStmt, OP3("EXPLAIN", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | EXPLAIN analyze_keyword opt_verbose ExplainableStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(101618,64791); // mapping from ExplainStmt to analyze_keyword
        	gram_cov->log_edge_cov_map(101618,62951); // mapping from ExplainStmt to opt_verbose
        	gram_cov->log_edge_cov_map(101618,165350); // mapping from ExplainStmt to ExplainableStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kExplainStmt_1, OP3("EXPLAIN", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $4;
        res = new IR(kExplainStmt, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | EXPLAIN VERBOSE ExplainableStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(101618,165350); // mapping from ExplainStmt to ExplainableStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kExplainStmt, OP3("EXPLAIN VERBOSE", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | EXPLAIN '(' explain_option_list ')' ExplainableStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(101618,224977); // mapping from ExplainStmt to explain_option_list
        	gram_cov->log_edge_cov_map(101618,165350); // mapping from ExplainStmt to ExplainableStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kExplainStmt, OP3("EXPLAIN (", ")", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_verbose:

    VERBOSE {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptVerbose, OP3("VERBOSE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptVerbose, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


explain_option_arg:

    opt_boolean_or_string {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(243872,231718); // mapping from explain_option_arg to opt_boolean_or_string
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExplainOptionArg, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | NumericOnly {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(243872,146194); // mapping from explain_option_arg to NumericOnly
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExplainOptionArg, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kExplainOptionArg, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


ExplainableStmt:

    AlterObjectSchemaStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(165350,241845); // mapping from ExplainableStmt to AlterObjectSchemaStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | AlterSeqStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(165350,53506); // mapping from ExplainableStmt to AlterSeqStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | AlterTableStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(165350,3339); // mapping from ExplainableStmt to AlterTableStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CallStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(165350,169607); // mapping from ExplainableStmt to CallStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CheckPointStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(165350,209782); // mapping from ExplainableStmt to CheckPointStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CopyStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(165350,128531); // mapping from ExplainableStmt to CopyStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CreateAsStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(165350,203801); // mapping from ExplainableStmt to CreateAsStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CreateFunctionStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(165350,4674); // mapping from ExplainableStmt to CreateFunctionStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CreateSchemaStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(165350,248310); // mapping from ExplainableStmt to CreateSchemaStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CreateSeqStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(165350,206176); // mapping from ExplainableStmt to CreateSeqStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CreateStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(165350,139905); // mapping from ExplainableStmt to CreateStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CreateTypeStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(165350,103560); // mapping from ExplainableStmt to CreateTypeStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | DeallocateStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(165350,17318); // mapping from ExplainableStmt to DeallocateStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | DeleteStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(165350,147970); // mapping from ExplainableStmt to DeleteStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | DropStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(165350,53483); // mapping from ExplainableStmt to DropStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        setup_drop_stmt(tmp1); 
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ExecuteStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(165350,220282); // mapping from ExplainableStmt to ExecuteStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | IndexStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(165350,198169); // mapping from ExplainableStmt to IndexStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | InsertStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(165350,254452); // mapping from ExplainableStmt to InsertStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | LoadStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(165350,110711); // mapping from ExplainableStmt to LoadStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | PragmaStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(165350,176050); // mapping from ExplainableStmt to PragmaStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | PrepareStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(165350,246258); // mapping from ExplainableStmt to PrepareStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | RenameStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(165350,122660); // mapping from ExplainableStmt to RenameStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | SelectStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(165350,70058); // mapping from ExplainableStmt to SelectStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | TransactionStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(165350,171693); // mapping from ExplainableStmt to TransactionStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | UpdateStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(165350,157714); // mapping from ExplainableStmt to UpdateStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | VacuumStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(165350,159119); // mapping from ExplainableStmt to VacuumStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | VariableResetStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(165350,212540); // mapping from ExplainableStmt to VariableResetStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | VariableSetStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(165350,66533); // mapping from ExplainableStmt to VariableSetStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | VariableShowStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(165350,58683); // mapping from ExplainableStmt to VariableShowStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ViewStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(165350,14948); // mapping from ExplainableStmt to ViewStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


NonReservedWord:

    IDENT {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(173153,69880); // mapping from NonReservedWord to IDENT
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = new IR(kIdentifier, cstr_to_string($1), kDataFixLater, kFlagUnknown);
        std::shared_ptr<IR> p_tmp1(tmp1, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_tmp1);
        res = new IR(kNonReservedWord, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


NonReservedWord_or_Sconst:

    NonReservedWord {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(136947,173153); // mapping from NonReservedWord_or_Sconst to NonReservedWord
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kNonReservedWordOrSconst, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | Sconst {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(136947,47445); // mapping from NonReservedWord_or_Sconst to Sconst
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kNonReservedWordOrSconst, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


explain_option_list:

    explain_option_elem {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(224977,165880); // mapping from explain_option_list to explain_option_elem
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExplainOptionList, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | explain_option_list ',' explain_option_elem {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(224977,224977); // mapping from explain_option_list to explain_option_list
        	gram_cov->log_edge_cov_map(224977,165880); // mapping from explain_option_list to explain_option_elem
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kExplainOptionList, OP3("", ",", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


analyze_keyword:

    ANALYZE {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kAnalyzeKeyword, OP3("ANALYZE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ANALYSE {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kAnalyzeKeyword, OP3("ANALYSE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_boolean_or_string:

    TRUE_P {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(231718,68645); // mapping from opt_boolean_or_string to TRUE_P
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = new IR(kBoolLiteral, std::string("TRUE"));
        std::shared_ptr<IR> p_tmp1(tmp1, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_tmp1);
        res = new IR(kOptBooleanOrString, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | FALSE_P {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(231718,17078); // mapping from opt_boolean_or_string to FALSE_P
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = new IR(kBoolLiteral, std::string("FALSE"));
        std::shared_ptr<IR> p_tmp1(tmp1, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_tmp1);
        res = new IR(kOptBooleanOrString, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ON {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptBooleanOrString, OP3("ON", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | NonReservedWord_or_Sconst {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(231718,136947); // mapping from opt_boolean_or_string to NonReservedWord_or_Sconst
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kOptBooleanOrString, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


explain_option_elem:

    explain_option_name explain_option_arg {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(165880,60943); // mapping from explain_option_elem to explain_option_name
        	gram_cov->log_edge_cov_map(165880,243872); // mapping from explain_option_elem to explain_option_arg
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kExplainOptionElem, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


explain_option_name:

    NonReservedWord {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(60943,173153); // mapping from explain_option_name to NonReservedWord
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExplainOptionName, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | analyze_keyword {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(60943,64791); // mapping from explain_option_name to analyze_keyword
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kExplainOptionName, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


VariableSetStmt:

    SET set_rest {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(66533,114060); // mapping from VariableSetStmt to set_rest
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kVariableSetStmt, OP3("SET", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | SET LOCAL set_rest {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(66533,114060); // mapping from VariableSetStmt to set_rest
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kVariableSetStmt, OP3("SET LOCAL", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | SET SESSION set_rest {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(66533,114060); // mapping from VariableSetStmt to set_rest
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kVariableSetStmt, OP3("SET SESSION", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | SET GLOBAL set_rest {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(66533,114060); // mapping from VariableSetStmt to set_rest
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kVariableSetStmt, OP3("SET GLOBAL", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


set_rest:

    generic_set {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(114060,130163); // mapping from set_rest to generic_set
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kSetRest, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | var_name FROM CURRENT_P {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(114060,62339); // mapping from set_rest to var_name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kSetRest, OP3("", "FROM CURRENT", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | TIME ZONE zone_value {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(114060,76580); // mapping from set_rest to zone_value
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kSetRest, OP3("TIME ZONE", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | SCHEMA Sconst {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(114060,47445); // mapping from set_rest to Sconst
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kSetRest, OP3("SCHEMA", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


generic_set:

    var_name TO var_list {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(130163,62339); // mapping from generic_set to var_name
        	gram_cov->log_edge_cov_map(130163,134748); // mapping from generic_set to var_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kGenericSet, OP3("", "TO", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | var_name '=' var_list {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(130163,62339); // mapping from generic_set to var_name
        	gram_cov->log_edge_cov_map(130163,134748); // mapping from generic_set to var_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kGenericSet, OP3("", "=", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | var_name TO DEFAULT {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(130163,62339); // mapping from generic_set to var_name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kGenericSet, OP3("", "TO DEFAULT", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | var_name '=' DEFAULT {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(130163,62339); // mapping from generic_set to var_name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kGenericSet, OP3("", "= DEFAULT", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


var_value:

    opt_boolean_or_string {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(183842,231718); // mapping from var_value to opt_boolean_or_string
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kVarValue, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | NumericOnly {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(183842,146194); // mapping from var_value to NumericOnly
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kVarValue, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


zone_value:

    Sconst {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(76580,47445); // mapping from zone_value to Sconst
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kZoneValue, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | IDENT {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(76580,69880); // mapping from zone_value to IDENT
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = new IR(kIdentifier, cstr_to_string($1), kDataFixLater, kFlagUnknown);
        std::shared_ptr<IR> p_tmp1(tmp1, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_tmp1);
        res = new IR(kZoneValue, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ConstInterval Sconst opt_interval {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(76580,125918); // mapping from zone_value to ConstInterval
        	gram_cov->log_edge_cov_map(76580,47445); // mapping from zone_value to Sconst
        	gram_cov->log_edge_cov_map(76580,36701); // mapping from zone_value to opt_interval
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kZoneValue_1, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $3;
        res = new IR(kZoneValue, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ConstInterval '(' Iconst ')' Sconst {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(76580,125918); // mapping from zone_value to ConstInterval
        	gram_cov->log_edge_cov_map(76580,255753); // mapping from zone_value to Iconst
        	gram_cov->log_edge_cov_map(76580,47445); // mapping from zone_value to Sconst
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kZoneValue_2, OP3("", "(", ")"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $5;
        res = new IR(kZoneValue, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | NumericOnly {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(76580,146194); // mapping from zone_value to NumericOnly
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kZoneValue, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | DEFAULT {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kZoneValue, OP3("DEFAULT", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | LOCAL {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kZoneValue, OP3("LOCAL", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


var_list:

    var_value {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(134748,183842); // mapping from var_list to var_value
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kVarList, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | var_list ',' var_value {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(134748,134748); // mapping from var_list to var_list
        	gram_cov->log_edge_cov_map(134748,183842); // mapping from var_list to var_value
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kVarList, OP3("", ",", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


LoadStmt:

    LOAD file_name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(110711,162135); // mapping from LoadStmt to file_name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kLoadStmt, OP3("LOAD", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | INSTALL file_name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(110711,162135); // mapping from LoadStmt to file_name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kLoadStmt, OP3("INSTALL", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | FORCE INSTALL file_name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(110711,162135); // mapping from LoadStmt to file_name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kLoadStmt, OP3("FORCE INSTALL", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | INSTALL file_name FROM repo_path {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(110711,162135); // mapping from LoadStmt to file_name
        	gram_cov->log_edge_cov_map(110711,147253); // mapping from LoadStmt to repo_path
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kLoadStmt, OP3("INSTALL", "FROM", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | FORCE INSTALL file_name FROM repo_path {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(110711,162135); // mapping from LoadStmt to file_name
        	gram_cov->log_edge_cov_map(110711,147253); // mapping from LoadStmt to repo_path
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kLoadStmt, OP3("FORCE INSTALL", "FROM", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


file_name:

    Sconst {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(162135,47445); // mapping from file_name to Sconst
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kFileName, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ColId {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(162135,133796); // mapping from file_name to ColId
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        setup_col_id(tmp1, kDataFileName, kUse); 
        res = new IR(kFileName, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


repo_path:

    Sconst {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(147253,47445); // mapping from repo_path to Sconst
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kRepoPath, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ColId {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(147253,133796); // mapping from repo_path to ColId
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        setup_col_id(tmp1, kDataRepoPath, kUse); 
        res = new IR(kRepoPath, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


VacuumStmt:

    VACUUM opt_full opt_freeze opt_verbose {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(159119,235206); // mapping from VacuumStmt to opt_full
        	gram_cov->log_edge_cov_map(159119,135198); // mapping from VacuumStmt to opt_freeze
        	gram_cov->log_edge_cov_map(159119,62951); // mapping from VacuumStmt to opt_verbose
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kVacuumStmt_1, OP3("VACUUM", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $4;
        res = new IR(kVacuumStmt, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | VACUUM opt_full opt_freeze opt_verbose qualified_name opt_name_list {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(159119,235206); // mapping from VacuumStmt to opt_full
        	gram_cov->log_edge_cov_map(159119,135198); // mapping from VacuumStmt to opt_freeze
        	gram_cov->log_edge_cov_map(159119,62951); // mapping from VacuumStmt to opt_verbose
        	gram_cov->log_edge_cov_map(159119,38734); // mapping from VacuumStmt to qualified_name
        	gram_cov->log_edge_cov_map(159119,254483); // mapping from VacuumStmt to opt_name_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kVacuumStmt_2, OP3("VACUUM", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $4;
        res = new IR(kVacuumStmt_3, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $5;
        setup_qualified_name(tmp4, kDataTableName, kUse, kDataSchemaName, kDataDatabase); 
        res = new IR(kVacuumStmt_4, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp5 = $6;
        setup_opt_name_list(tmp5, kDataColumnName, kUse); 
        res = new IR(kVacuumStmt, OP3("", "", ""), res, tmp5);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | VACUUM opt_full opt_freeze opt_verbose AnalyzeStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(159119,235206); // mapping from VacuumStmt to opt_full
        	gram_cov->log_edge_cov_map(159119,135198); // mapping from VacuumStmt to opt_freeze
        	gram_cov->log_edge_cov_map(159119,62951); // mapping from VacuumStmt to opt_verbose
        	gram_cov->log_edge_cov_map(159119,43238); // mapping from VacuumStmt to AnalyzeStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kVacuumStmt_5, OP3("VACUUM", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $4;
        res = new IR(kVacuumStmt_6, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $5;
        res = new IR(kVacuumStmt, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | VACUUM '(' vacuum_option_list ')' {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(159119,211566); // mapping from VacuumStmt to vacuum_option_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kVacuumStmt, OP3("VACUUM (", ")", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | VACUUM '(' vacuum_option_list ')' qualified_name opt_name_list {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(159119,211566); // mapping from VacuumStmt to vacuum_option_list
        	gram_cov->log_edge_cov_map(159119,38734); // mapping from VacuumStmt to qualified_name
        	gram_cov->log_edge_cov_map(159119,254483); // mapping from VacuumStmt to opt_name_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        auto tmp2 = $5;
        setup_qualified_name(tmp2, kDataTableName, kUse, kDataSchemaName, kDataDatabase); 
        res = new IR(kVacuumStmt_7, OP3("VACUUM (", ")", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $6;
        setup_opt_name_list(tmp3, kDataColumnName, kUse); 
        res = new IR(kVacuumStmt, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


vacuum_option_elem:

    analyze_keyword {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(5974,64791); // mapping from vacuum_option_elem to analyze_keyword
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kVacuumOptionElem, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | VERBOSE {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kVacuumOptionElem, OP3("VERBOSE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | FREEZE {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kVacuumOptionElem, OP3("FREEZE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | FULL {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kVacuumOptionElem, OP3("FULL", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | IDENT {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(5974,69880); // mapping from vacuum_option_elem to IDENT
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = new IR(kIdentifier, cstr_to_string($1), kDataFixLater, kFlagUnknown);
        std::shared_ptr<IR> p_tmp1(tmp1, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_tmp1);
        res = new IR(kVacuumOptionElem, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_full:

    FULL {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptFull, OP3("FULL", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptFull, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


vacuum_option_list:

    vacuum_option_elem {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(211566,5974); // mapping from vacuum_option_list to vacuum_option_elem
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kVacuumOptionList, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | vacuum_option_list ',' vacuum_option_elem {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(211566,211566); // mapping from vacuum_option_list to vacuum_option_list
        	gram_cov->log_edge_cov_map(211566,5974); // mapping from vacuum_option_list to vacuum_option_elem
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kVacuumOptionList, OP3("", ",", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_freeze:

    FREEZE {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptFreeze, OP3("FREEZE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptFreeze, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


DeleteStmt:

    opt_with_clause DELETE_P FROM relation_expr_opt_alias using_clause where_or_current_clause returning_clause {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(147970,74395); // mapping from DeleteStmt to opt_with_clause
        	gram_cov->log_edge_cov_map(147970,6293); // mapping from DeleteStmt to relation_expr_opt_alias
        	gram_cov->log_edge_cov_map(147970,10801); // mapping from DeleteStmt to using_clause
        	gram_cov->log_edge_cov_map(147970,220981); // mapping from DeleteStmt to where_or_current_clause
        	gram_cov->log_edge_cov_map(147970,132480); // mapping from DeleteStmt to returning_clause
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kDeleteStmt_1, OP3("", "DELETE FROM", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $5;
        res = new IR(kDeleteStmt_2, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $6;
        res = new IR(kDeleteStmt_3, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp5 = $7;
        res = new IR(kDeleteStmt, OP3("", "", ""), res, tmp5);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | TRUNCATE opt_table relation_expr_opt_alias {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(147970,171318); // mapping from DeleteStmt to opt_table
        	gram_cov->log_edge_cov_map(147970,6293); // mapping from DeleteStmt to relation_expr_opt_alias
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kDeleteStmt, OP3("TRUNCATE", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


relation_expr_opt_alias:

    relation_expr %prec UMINUS {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(6293,135212); // mapping from relation_expr_opt_alias to relation_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        setup_relation_expr(tmp1, kDataTableName, kUse, kDataSchemaName, kDataDatabase); 
        res = new IR(kRelationExprOptAlias, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | relation_expr ColId {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(6293,135212); // mapping from relation_expr_opt_alias to relation_expr
        	gram_cov->log_edge_cov_map(6293,133796); // mapping from relation_expr_opt_alias to ColId
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        setup_relation_expr(tmp1, kDataTableName, kUse, kDataSchemaName, kDataDatabase); 
        auto tmp2 = $2;
        setup_col_id(tmp2, kDataAliasTableName, kDefine); 
        res = new IR(kRelationExprOptAlias, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | relation_expr AS ColId {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(6293,135212); // mapping from relation_expr_opt_alias to relation_expr
        	gram_cov->log_edge_cov_map(6293,133796); // mapping from relation_expr_opt_alias to ColId
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        setup_relation_expr(tmp1, kDataTableName, kUse, kDataSchemaName, kDataDatabase); 
        auto tmp2 = $3;
        setup_col_id(tmp2, kDataAliasTableName, kDefine); 
        res = new IR(kRelationExprOptAlias, OP3("", "AS", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


where_or_current_clause:

    WHERE a_expr {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(220981,53205); // mapping from where_or_current_clause to a_expr
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kWhereOrCurrentClause, OP3("WHERE", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kWhereOrCurrentClause, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


using_clause:

    USING from_list_opt_comma {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(10801,94901); // mapping from using_clause to from_list_opt_comma
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kUsingClause, OP3("USING", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kUsingClause, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


AnalyzeStmt:

    analyze_keyword opt_verbose {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(43238,64791); // mapping from AnalyzeStmt to analyze_keyword
        	gram_cov->log_edge_cov_map(43238,62951); // mapping from AnalyzeStmt to opt_verbose
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAnalyzeStmt, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | analyze_keyword opt_verbose qualified_name opt_name_list {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(43238,64791); // mapping from AnalyzeStmt to analyze_keyword
        	gram_cov->log_edge_cov_map(43238,62951); // mapping from AnalyzeStmt to opt_verbose
        	gram_cov->log_edge_cov_map(43238,38734); // mapping from AnalyzeStmt to qualified_name
        	gram_cov->log_edge_cov_map(43238,254483); // mapping from AnalyzeStmt to opt_name_list
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAnalyzeStmt_1, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $3;
        setup_qualified_name(tmp3, kDataTableName, kUse, kDataSchemaName, kDataDatabase); 
        res = new IR(kAnalyzeStmt_2, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $4;
        setup_opt_name_list(tmp4, kDataColumnName, kUse); 
        res = new IR(kAnalyzeStmt, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


AttachStmt:

    ATTACH opt_database Sconst opt_database_alias copy_options {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(63056,200560); // mapping from AttachStmt to opt_database
        	gram_cov->log_edge_cov_map(63056,47445); // mapping from AttachStmt to Sconst
        	gram_cov->log_edge_cov_map(63056,56432); // mapping from AttachStmt to opt_database_alias
        	gram_cov->log_edge_cov_map(63056,139201); // mapping from AttachStmt to copy_options
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAttachStmt_1, OP3("ATTACH", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $4;
        res = new IR(kAttachStmt_2, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $5;
        res = new IR(kAttachStmt, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


DetachStmt:

    DETACH opt_database IDENT {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(12042,200560); // mapping from DetachStmt to opt_database
        	gram_cov->log_edge_cov_map(12042,69880); // mapping from DetachStmt to IDENT
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = new IR(kIdentifier, cstr_to_string($3), kDataFixLater, kFlagUnknown);
        std::shared_ptr<IR> p_tmp2(tmp2, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_tmp2);
        res = new IR(kDetachStmt, OP3("DETACH", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | DETACH DATABASE IF_P EXISTS IDENT {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(12042,69880); // mapping from DetachStmt to IDENT
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = new IR(kIdentifier, cstr_to_string($5), kDataFixLater, kFlagUnknown);
        std::shared_ptr<IR> p_tmp1(tmp1, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_tmp1);
        res = new IR(kDetachStmt, OP3("DETACH DATABASE IF EXISTS", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_database:

    DATABASE {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptDatabase, OP3("DATABASE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptDatabase, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_database_alias:

    AS ColId {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(56432,133796); // mapping from opt_database_alias to ColId
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        setup_col_id(tmp1, kDataDatabase, kDefine); 
        res = new IR(kOptDatabaseAlias, OP3("AS", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptDatabaseAlias, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


ident_name:

    IDENT {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(105130,69880); // mapping from ident_name to IDENT
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = new IR(kIdentifier, cstr_to_string($1), kDataFixLater, kFlagUnknown);
        std::shared_ptr<IR> p_tmp1(tmp1, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_tmp1);
        res = new IR(kIdentName, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


ident_list:

    ident_name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(133781,105130); // mapping from ident_list to ident_name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kIdentList, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ident_list ',' ident_name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(133781,133781); // mapping from ident_list to ident_list
        	gram_cov->log_edge_cov_map(133781,105130); // mapping from ident_list to ident_name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kIdentList, OP3("", ",", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


VariableResetStmt:

    RESET reset_rest {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(212540,242470); // mapping from VariableResetStmt to reset_rest
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kVariableResetStmt, OP3("RESET", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | RESET LOCAL reset_rest {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(212540,242470); // mapping from VariableResetStmt to reset_rest
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kVariableResetStmt, OP3("RESET LOCAL", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | RESET SESSION reset_rest {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(212540,242470); // mapping from VariableResetStmt to reset_rest
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kVariableResetStmt, OP3("RESET SESSION", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | RESET GLOBAL reset_rest {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(212540,242470); // mapping from VariableResetStmt to reset_rest
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $3;
        res = new IR(kVariableResetStmt, OP3("RESET GLOBAL", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


generic_reset:

    var_name {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(251858,62339); // mapping from generic_reset to var_name
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kGenericReset, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | ALL {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kGenericReset, OP3("ALL", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


reset_rest:

    generic_reset {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(242470,251858); // mapping from reset_rest to generic_reset
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kResetRest, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | TIME ZONE {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kResetRest, OP3("TIME ZONE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | TRANSACTION ISOLATION LEVEL {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kResetRest, OP3("TRANSACTION ISOLATION LEVEL", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


VariableShowStmt:

    show_or_describe SelectStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(58683,135757); // mapping from VariableShowStmt to show_or_describe
        	gram_cov->log_edge_cov_map(58683,70058); // mapping from VariableShowStmt to SelectStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kVariableShowStmt, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | SUMMARIZE SelectStmt {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(58683,70058); // mapping from VariableShowStmt to SelectStmt
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kVariableShowStmt, OP3("SUMMARIZE", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | SUMMARIZE table_id {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(58683,82298); // mapping from VariableShowStmt to table_id
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kVariableShowStmt, OP3("SUMMARIZE", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | show_or_describe table_id {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(58683,135757); // mapping from VariableShowStmt to show_or_describe
        	gram_cov->log_edge_cov_map(58683,82298); // mapping from VariableShowStmt to table_id
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kVariableShowStmt, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | show_or_describe TIME ZONE {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(58683,135757); // mapping from VariableShowStmt to show_or_describe
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kVariableShowStmt, OP3("", "TIME ZONE", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | show_or_describe TRANSACTION ISOLATION LEVEL {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(58683,135757); // mapping from VariableShowStmt to show_or_describe
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kVariableShowStmt, OP3("", "TRANSACTION ISOLATION LEVEL", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | show_or_describe ALL opt_tables {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(58683,135757); // mapping from VariableShowStmt to show_or_describe
        	gram_cov->log_edge_cov_map(58683,261949); // mapping from VariableShowStmt to opt_tables
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kVariableShowStmt, OP3("", "ALL", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | show_or_describe {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(58683,135757); // mapping from VariableShowStmt to show_or_describe
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        res = new IR(kVariableShowStmt, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


show_or_describe:

    SHOW {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kShowOrDescribe, OP3("SHOW", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | DESCRIBE {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kShowOrDescribe, OP3("DESCRIBE", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_tables:

    TABLES {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptTables, OP3("TABLES", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptTables, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


var_name:

    ColId {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(62339,133796); // mapping from var_name to ColId
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        setup_col_id(tmp1, kDataPragmaKey, kUse); 
        res = new IR(kVarName, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | var_name '.' ColId {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(62339,62339); // mapping from var_name to var_name
        	gram_cov->log_edge_cov_map(62339,133796); // mapping from var_name to ColId
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        auto tmp2 = $3;
        setup_col_id(tmp2, kDataPragmaKey, kUse); 
        res = new IR(kVarName, OP3("", ".", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


table_id:

    ColId {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(82298,133796); // mapping from table_id to ColId
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        setup_col_id(tmp1, kDataTableName, kUse); 
        res = new IR(kTableId, OP3("", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | table_id '.' ColId {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(82298,82298); // mapping from table_id to table_id
        	gram_cov->log_edge_cov_map(82298,133796); // mapping from table_id to ColId
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        setup_table_id(tmp1, kDataDatabase, kUse); 
        auto tmp2 = $3;
        setup_col_id(tmp2, kDataTableName, kUse); 
        res = new IR(kTableId, OP3("", ".", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


CallStmt:

    CALL_P func_application {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(169607,80033); // mapping from CallStmt to func_application
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        res = new IR(kCallStmt, OP3("CALL", "", ""), tmp1);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


ViewStmt:

    CREATE_P OptTemp VIEW qualified_name opt_column_list opt_reloptions AS SelectStmt opt_check_option {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(14948,254974); // mapping from ViewStmt to OptTemp
        	gram_cov->log_edge_cov_map(14948,38734); // mapping from ViewStmt to qualified_name
        	gram_cov->log_edge_cov_map(14948,193852); // mapping from ViewStmt to opt_column_list
        	gram_cov->log_edge_cov_map(14948,232613); // mapping from ViewStmt to opt_reloptions
        	gram_cov->log_edge_cov_map(14948,70058); // mapping from ViewStmt to SelectStmt
        	gram_cov->log_edge_cov_map(14948,144450); // mapping from ViewStmt to opt_check_option
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $4;
        setup_qualified_name(tmp2, kDataViewName, kDefine, kDataSchemaName, kDataDatabase); 
        res = new IR(kViewStmt_1, OP3("CREATE", "VIEW", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $5;
        setup_opt_column_list(tmp3, kDataColumnName, kDefine); 
        res = new IR(kViewStmt_2, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $6;
        res = new IR(kViewStmt_3, OP3("", "", "AS"), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp5 = $8;
        res = new IR(kViewStmt_4, OP3("", "", ""), res, tmp5);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp6 = $9;
        res = new IR(kViewStmt, OP3("", "", ""), res, tmp6);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CREATE_P OptTemp VIEW IF_P NOT EXISTS qualified_name opt_column_list opt_reloptions AS SelectStmt opt_check_option {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(14948,254974); // mapping from ViewStmt to OptTemp
        	gram_cov->log_edge_cov_map(14948,38734); // mapping from ViewStmt to qualified_name
        	gram_cov->log_edge_cov_map(14948,193852); // mapping from ViewStmt to opt_column_list
        	gram_cov->log_edge_cov_map(14948,232613); // mapping from ViewStmt to opt_reloptions
        	gram_cov->log_edge_cov_map(14948,70058); // mapping from ViewStmt to SelectStmt
        	gram_cov->log_edge_cov_map(14948,144450); // mapping from ViewStmt to opt_check_option
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $7;
        setup_qualified_name(tmp2, kDataViewName, kDefine, kDataSchemaName, kDataDatabase); 
        res = new IR(kViewStmt_5, OP3("CREATE", "VIEW IF NOT EXISTS", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $8;
        setup_opt_column_list(tmp3, kDataColumnName, kDefine); 
        res = new IR(kViewStmt_6, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $9;
        res = new IR(kViewStmt_7, OP3("", "", "AS"), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp5 = $11;
        res = new IR(kViewStmt_8, OP3("", "", ""), res, tmp5);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp6 = $12;
        res = new IR(kViewStmt, OP3("", "", ""), res, tmp6);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CREATE_P OR REPLACE OptTemp VIEW qualified_name opt_column_list opt_reloptions AS SelectStmt opt_check_option {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(14948,254974); // mapping from ViewStmt to OptTemp
        	gram_cov->log_edge_cov_map(14948,38734); // mapping from ViewStmt to qualified_name
        	gram_cov->log_edge_cov_map(14948,193852); // mapping from ViewStmt to opt_column_list
        	gram_cov->log_edge_cov_map(14948,232613); // mapping from ViewStmt to opt_reloptions
        	gram_cov->log_edge_cov_map(14948,70058); // mapping from ViewStmt to SelectStmt
        	gram_cov->log_edge_cov_map(14948,144450); // mapping from ViewStmt to opt_check_option
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $4;
        auto tmp2 = $6;
        setup_qualified_name(tmp2, kDataViewName, kDefine, kDataSchemaName, kDataDatabase); 
        res = new IR(kViewStmt_9, OP3("CREATE OR REPLACE", "VIEW", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $7;
        setup_opt_column_list(tmp3, kDataColumnName, kDefine); 
        res = new IR(kViewStmt_10, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $8;
        res = new IR(kViewStmt_11, OP3("", "", "AS"), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp5 = $10;
        res = new IR(kViewStmt_12, OP3("", "", ""), res, tmp5);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp6 = $11;
        res = new IR(kViewStmt, OP3("", "", ""), res, tmp6);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CREATE_P OptTemp RECURSIVE VIEW qualified_name '(' columnList ')' opt_reloptions AS SelectStmt opt_check_option {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(14948,254974); // mapping from ViewStmt to OptTemp
        	gram_cov->log_edge_cov_map(14948,38734); // mapping from ViewStmt to qualified_name
        	gram_cov->log_edge_cov_map(14948,63969); // mapping from ViewStmt to columnList
        	gram_cov->log_edge_cov_map(14948,232613); // mapping from ViewStmt to opt_reloptions
        	gram_cov->log_edge_cov_map(14948,70058); // mapping from ViewStmt to SelectStmt
        	gram_cov->log_edge_cov_map(14948,144450); // mapping from ViewStmt to opt_check_option
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $5;
        setup_qualified_name(tmp2, kDataViewName, kDefine, kDataSchemaName, kDataDatabase); 
        res = new IR(kViewStmt_13, OP3("CREATE", "RECURSIVE VIEW", "("), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $7;
        setup_column_list(tmp3, kDataColumnName, kDefine); 
        res = new IR(kViewStmt_14, OP3("", "", ")"), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $9;
        res = new IR(kViewStmt_15, OP3("", "", "AS"), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp5 = $11;
        res = new IR(kViewStmt_16, OP3("", "", ""), res, tmp5);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp6 = $12;
        res = new IR(kViewStmt, OP3("", "", ""), res, tmp6);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CREATE_P OR REPLACE OptTemp RECURSIVE VIEW qualified_name '(' columnList ')' opt_reloptions AS SelectStmt opt_check_option {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(14948,254974); // mapping from ViewStmt to OptTemp
        	gram_cov->log_edge_cov_map(14948,38734); // mapping from ViewStmt to qualified_name
        	gram_cov->log_edge_cov_map(14948,63969); // mapping from ViewStmt to columnList
        	gram_cov->log_edge_cov_map(14948,232613); // mapping from ViewStmt to opt_reloptions
        	gram_cov->log_edge_cov_map(14948,70058); // mapping from ViewStmt to SelectStmt
        	gram_cov->log_edge_cov_map(14948,144450); // mapping from ViewStmt to opt_check_option
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $4;
        auto tmp2 = $7;
        setup_qualified_name(tmp2, kDataViewName, kDefine, kDataSchemaName, kDataDatabase); 
        res = new IR(kViewStmt_17, OP3("CREATE OR REPLACE", "RECURSIVE VIEW", "("), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $9;
        setup_column_list(tmp3, kDataColumnName, kDefine); 
        res = new IR(kViewStmt_18, OP3("", "", ")"), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $11;
        res = new IR(kViewStmt_19, OP3("", "", "AS"), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp5 = $13;
        res = new IR(kViewStmt_20, OP3("", "", ""), res, tmp5);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp6 = $14;
        res = new IR(kViewStmt, OP3("", "", ""), res, tmp6);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_check_option:

    WITH CHECK_P OPTION {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptCheckOption, OP3("WITH CHECK OPTION", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | WITH CASCADED CHECK_P OPTION {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptCheckOption, OP3("WITH CASCADED CHECK OPTION", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | WITH LOCAL CHECK_P OPTION {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptCheckOption, OP3("WITH LOCAL CHECK OPTION", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptCheckOption, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


CreateAsStmt:

    CREATE_P OptTemp TABLE create_as_target AS SelectStmt opt_with_data {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(203801,254974); // mapping from CreateAsStmt to OptTemp
        	gram_cov->log_edge_cov_map(203801,173642); // mapping from CreateAsStmt to create_as_target
        	gram_cov->log_edge_cov_map(203801,70058); // mapping from CreateAsStmt to SelectStmt
        	gram_cov->log_edge_cov_map(203801,27946); // mapping from CreateAsStmt to opt_with_data
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kCreateAsStmt_1, OP3("CREATE", "TABLE", "AS"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $6;
        res = new IR(kCreateAsStmt_2, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $7;
        res = new IR(kCreateAsStmt, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CREATE_P OptTemp TABLE IF_P NOT EXISTS create_as_target AS SelectStmt opt_with_data {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(203801,254974); // mapping from CreateAsStmt to OptTemp
        	gram_cov->log_edge_cov_map(203801,173642); // mapping from CreateAsStmt to create_as_target
        	gram_cov->log_edge_cov_map(203801,70058); // mapping from CreateAsStmt to SelectStmt
        	gram_cov->log_edge_cov_map(203801,27946); // mapping from CreateAsStmt to opt_with_data
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $2;
        auto tmp2 = $7;
        res = new IR(kCreateAsStmt_3, OP3("CREATE", "TABLE IF NOT EXISTS", "AS"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $9;
        res = new IR(kCreateAsStmt_4, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $10;
        res = new IR(kCreateAsStmt, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | CREATE_P OR REPLACE OptTemp TABLE create_as_target AS SelectStmt opt_with_data {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(203801,254974); // mapping from CreateAsStmt to OptTemp
        	gram_cov->log_edge_cov_map(203801,173642); // mapping from CreateAsStmt to create_as_target
        	gram_cov->log_edge_cov_map(203801,70058); // mapping from CreateAsStmt to SelectStmt
        	gram_cov->log_edge_cov_map(203801,27946); // mapping from CreateAsStmt to opt_with_data
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kCreateAsStmt_5, OP3("CREATE OR REPLACE", "TABLE", "AS"), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $8;
        res = new IR(kCreateAsStmt_6, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $9;
        res = new IR(kCreateAsStmt, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


opt_with_data:

    WITH DATA_P {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptWithData, OP3("WITH DATA", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | WITH NO DATA_P {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptWithData, OP3("WITH NO DATA", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        if (gram_cov != nullptr) {
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        res = new IR(kOptWithData, OP3("", "", ""));
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


create_as_target:

    qualified_name opt_column_list OptWith OnCommitOption {
        if (gram_cov != nullptr) {
        	gram_cov->log_edge_cov_map(173642,38734); // mapping from create_as_target to qualified_name
        	gram_cov->log_edge_cov_map(173642,193852); // mapping from create_as_target to opt_column_list
        	gram_cov->log_edge_cov_map(173642,68169); // mapping from create_as_target to OptWith
        	gram_cov->log_edge_cov_map(173642,141669); // mapping from create_as_target to OnCommitOption
        }
        IR* res; 
        std::shared_ptr<IR> p_res; 
        auto tmp1 = $1;
        setup_qualified_name(tmp1, kDataTableName, kDefine, kDataSchemaName, kDataDatabase); 
        auto tmp2 = $2;
        setup_opt_column_list(tmp2, kDataColumnName, kDefine); 
        res = new IR(kCreateAsTarget_1, OP3("", "", ""), tmp1, tmp2);
        p_res = std::shared_ptr<IR> (res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp3 = $3;
        res = new IR(kCreateAsTarget_2, OP3("", "", ""), res, tmp3);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        auto tmp4 = $4;
        res = new IR(kCreateAsTarget, OP3("", "", ""), res, tmp4);
        p_res = std::shared_ptr<IR>(res, [](IR *p) {p->drop();}); 
        ir_vec.push_back(p_res); 
        $$ = res;
    }

;


%%

#line 1 "third_party/libpg_query/grammar/grammar.cpp"
/*
 * The signature of this function is required by bison.  However, we
 * ignore the passed yylloc and instead use the last token position
 * available from the scanner.
 */
static void
base_yyerror(YYLTYPE *yylloc, core_yyscan_t yyscanner, GramCovMap* gram_cov, const char *msg)
{
	parser_yyerror(msg);
}

std::string cstr_to_string(char *str) {
   std::string res(str, strlen(str));
   return res;
}

std::vector<IR*> get_ir_node_in_stmt_with_type(IR* cur_IR, IRTYPE ir_type) {

    // Iterate IR binary tree, left depth prioritized.
    bool is_finished_search = false;
    std::vector<IR*> ir_vec_iter;
    std::vector<IR*> ir_vec_matching_type;
    // Begin iterating.
    while (!is_finished_search) {
        ir_vec_iter.push_back(cur_IR);
        if (cur_IR->type_ == ir_type) {
            ir_vec_matching_type.push_back(cur_IR);
        }

        if (cur_IR->left_ != nullptr){
            cur_IR = cur_IR->left_;
            continue;
        } else { // Reaching the most depth. Consulting ir_vec_iter for right_ nodes.
            cur_IR = nullptr;
            while (cur_IR == nullptr){
                if (ir_vec_iter.size() == 0){
                    is_finished_search = true;
                    break;
                }
                cur_IR = ir_vec_iter.back()->right_;
                ir_vec_iter.pop_back();
            }
            continue;
        }
    }

    return ir_vec_matching_type;
}

void setup_col_id(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag) {
    std::vector<IR*> v_iden = get_ir_node_in_stmt_with_type(cur_ir, kIdentifier);
    for (IR* cur_iden: v_iden) {
        cur_iden->set_data_type(data_type);
        cur_iden->set_data_flag(data_flag);
    }
    return;
}

void setup_col_id_or_string(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag) {
    std::vector<IR*> v_iden = get_ir_node_in_stmt_with_type(cur_ir, kIdentifier);
    for (IR* cur_iden: v_iden) {
        cur_iden->set_data_type(data_type);
        cur_iden->set_data_flag(data_flag);
    }
    return;
}

void setup_name(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag) {
    std::vector<IR*> v_iden = get_ir_node_in_stmt_with_type(cur_ir, kIdentifier);
    for (IR* cur_iden: v_iden) {
        cur_iden->set_data_type(data_type);
        cur_iden->set_data_flag(data_flag);
    }
    return;
}

void setup_table_id(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag) {
    std::vector<IR*> v_iden = get_ir_node_in_stmt_with_type(cur_ir, kIdentifier);
    for (IR* cur_iden: v_iden) {
        cur_iden->set_data_type(data_type);
        cur_iden->set_data_flag(data_flag);
    }
    return;
}

void setup_drop_stmt(IR* cur_ir) {
    
    std::string drop_stmt_str = cur_ir->to_string();
    DATATYPE data_type = kDataWhatever;
    
    if (drop_stmt_str.find("DROP TABLE") != std::string::npos) {
        data_type = kDataTableName;
    }
    else if (drop_stmt_str.find("DROP SEQUENCE") != std::string::npos) {
        data_type = kDataSequenceName;
    }
    else if (drop_stmt_str.find("DROP FUNCTION") != std::string::npos) {
        data_type = kDataFunctionName;
    }
    else if (drop_stmt_str.find("DROP VIEW") != std::string::npos) {
        data_type = kDataViewName;
    }
    else if (drop_stmt_str.find("DROP MATERIALIZED VIEW") != std::string::npos) {
        data_type = kDataViewName;
    }
    else if (drop_stmt_str.find("DROP INDEX") != std::string::npos) {
        data_type = kDataIndexName;
    }
    else if (drop_stmt_str.find("DROP FOREIGN TABLE") != std::string::npos) {
        // Not accurate. Should be kUse instead of kUndefine.
        data_type = kDataTableName;
    }
    else if (drop_stmt_str.find("DROP COLLATION") != std::string::npos) {
        data_type = kDataCollate;
    }
    else if (drop_stmt_str.find("DROP SCHEMA") != std::string::npos) {
        data_type = kDataDatabase;
    }
    else if (drop_stmt_str.find("DROP TRIGGER") != std::string::npos) {
        data_type = kDataTriggerName;
    }
    else if (drop_stmt_str.find("DROP TYPE") != std::string::npos) {
        data_type = kDataTypeName;
    }

    std::vector<IR*> v_name = get_ir_node_in_stmt_with_type(cur_ir, kName);
    if (v_name.size()) {
        IR* cur_name = v_name.front();
        setup_name(cur_name, data_type, kUndefine);
    }
    
    std::vector<IR*> v_any_name_list = get_ir_node_in_stmt_with_type(cur_ir, kAnyNameList);
    for (IR* cur_name_list : v_any_name_list) {
        setup_any_name_list(cur_name_list, data_type, kUndefine, kDataSchemaName, kDataDatabase);
    }
    return;
}

void setup_name_list(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag) {
    std::vector<IR*> v_name = get_ir_node_in_stmt_with_type(cur_ir, kName);
    for (IR* cur_name: v_name) {
        setup_name(cur_name, data_type, data_flag);
    }
    return;
}

void setup_name_list_opt_comma(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag) {
    std::vector<IR*> v_name = get_ir_node_in_stmt_with_type(cur_ir, kNameList);
    for (IR* cur_name: v_name) {
        setup_name_list(cur_name, data_type, data_flag);
    }
    return;
}

void setup_name_list_opt_comma_opt_bracket(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag) {
    std::vector<IR*> v_name = get_ir_node_in_stmt_with_type(cur_ir, kNameListOptComma);
    for (IR* cur_name: v_name) {
        setup_name_list_opt_comma(cur_name, data_type, data_flag);
    }
    return;
}

void setup_opt_name_list(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag) {
    std::vector<IR*> v_name = get_ir_node_in_stmt_with_type(cur_ir, kNameListOptComma);
    for (IR* cur_name: v_name) {
        setup_name_list_opt_comma(cur_name, data_type, data_flag);
    }
    return;
}

void setup_qualified_name(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag, DATATYPE data_type_par, DATATYPE data_type_par_par) {
    std::vector<IR*> v_col_id_or_string = get_ir_node_in_stmt_with_type(cur_ir, kColIdOrString);
    
    if (v_col_id_or_string.size()) {
        // The ColIdOrString case
        for (IR* cur_col_id: v_col_id_or_string) {
            setup_col_id_or_string(cur_col_id, data_type, data_flag);
        }
        return;
    }
    
    // The ColId indirection case
    std::vector<IR*> v_iden = get_ir_node_in_stmt_with_type(cur_ir, kIdentifier);
    
    if (v_iden.size() == 1) {
        v_iden.back()->set_data_type(data_type);
        v_iden.back()->set_data_flag(data_flag);
    } else if (v_iden.size() == 2) {
        v_iden.back()->set_data_type(data_type);
        v_iden.back()->set_data_flag(data_flag);
        v_iden.front()->set_data_type(data_type_par);
        v_iden.front()->set_data_flag(kUse);
    } else if (v_iden.size() > 2) {
        v_iden.back()->set_data_type(data_type);
        v_iden.back()->set_data_flag(data_flag);
        v_iden[1]->set_data_type(data_type_par);
        v_iden[1]->set_data_flag(kUse);
        v_iden.front()->set_data_type(data_type_par_par);
        v_iden.front()->set_data_flag(kUse);
    }
    
    return;
}

void setup_qualified_name_list(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag, DATATYPE data_type_par, DATATYPE data_type_par_par) {

    std::vector<IR*> v_qualified_name = get_ir_node_in_stmt_with_type(cur_ir, kQualifiedName);
    for (IR* cur_qualified_name: v_qualified_name) {
        setup_qualified_name(cur_qualified_name, data_type, data_flag, data_type_par, data_type_par_par);
    }
    
    return;
}

void setup_index_name(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag) {

    std::vector<IR*> v_col_id = get_ir_node_in_stmt_with_type(cur_ir, kColId);
    for (IR* cur_col_id: v_col_id) {
        setup_col_id(cur_col_id, data_type, data_flag);
    }
    
    return;
}

void setup_relation_expr(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag, DATATYPE data_type_par, DATATYPE data_type_par_par) {

    std::vector<IR*> v_qualified_name = get_ir_node_in_stmt_with_type(cur_ir, kQualifiedName);
    for (IR* cur_name: v_qualified_name) {
        setup_qualified_name(cur_name, data_type, data_flag, data_type_par, data_type_par_par);
    }
    
    return;
}

void setup_col_label(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag) {

    std::vector<IR*> v_iden = get_ir_node_in_stmt_with_type(cur_ir, kIdentifier);
    for (IR* cur_iden: v_iden) {
        cur_iden->set_data_type(data_type);
        cur_iden->set_data_flag(data_flag);
    }
    
    return;
}

void setup_col_label_or_string(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag) {

    std::vector<IR*> v_iden = get_ir_node_in_stmt_with_type(cur_ir, kColLabel);
    for (IR* cur_iden: v_iden) {
        setup_col_label(cur_iden, data_type, data_flag);
    }
    
    return;
}

void setup_column_list(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag) {

    std::vector<IR*> v_iden = get_ir_node_in_stmt_with_type(cur_ir, kColId);
    for (IR* cur_iden: v_iden) {
        setup_col_id(cur_iden, data_type, data_flag);
    }
    
    return;
}

void setup_opt_column_list(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag) {

    std::vector<IR*> v_iden = get_ir_node_in_stmt_with_type(cur_ir, kColumnList);
    for (IR* cur_iden: v_iden) {
        setup_column_list(cur_iden, data_type, data_flag);
    }
    
    return;
}

void setup_alias_clause(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag) {

    std::vector<IR*> v_col_id_or_string = get_ir_node_in_stmt_with_type(cur_ir, kColIdOrString);
    std::vector<IR*> v_col_id = get_ir_node_in_stmt_with_type(cur_ir, kColId);
    std::vector<IR*> v_name_list = get_ir_node_in_stmt_with_type(cur_ir, kNameListOptComma);
    
    if (v_col_id_or_string.size() && v_name_list.size()) {
        // Both table name and column name present, semantic fixed. 
        for (IR* cur_ident: v_col_id_or_string) {
            setup_col_id_or_string(cur_ident, kDataTableName, data_flag);
        }
        for (IR* cur_ident: v_name_list) {
            setup_name_list(cur_ident, kDataColumnName, data_flag);
        }
    }
    else if (v_col_id.size() && v_name_list.size()) {
        // Both table name and column name present, semantic fixed. 
        for (IR* cur_ident: v_col_id) {
            setup_col_id_or_string(cur_ident, kDataTableName, data_flag);
        }
        for (IR* cur_ident: v_name_list) {
            setup_name_list(cur_ident, kDataColumnName, data_flag);
        }
    }
    else if (v_col_id_or_string.size()) {
        // only one alias variable present, use passed in data_type 
        for (IR* cur_ident: v_col_id_or_string) {
            setup_col_id_or_string(cur_ident, data_type, data_flag);
        }
    }
    else if (v_col_id.size()) {
        // only one alias variable present, use passed in data_type 
        for (IR* cur_ident: v_col_id) {
            setup_col_id_or_string(cur_ident, data_type, data_flag);
        }
    }
    
    return;
}

void setup_opt_alias_clause(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag) {

    std::vector<IR*> v_alias_clause = get_ir_node_in_stmt_with_type(cur_ir, kAliasClause);
    
    for (IR* cur_alias_clause: v_alias_clause) {
        setup_alias_clause(cur_alias_clause, data_type, data_flag);
    }
    
    return;
}

void setup_func_alias_clause(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag) {

    std::vector<IR*> v_alias_clause = get_ir_node_in_stmt_with_type(cur_ir, kAliasClause);
    
    for (IR* cur_alias_clause: v_alias_clause) {
        setup_alias_clause(cur_alias_clause, data_type, data_flag);
    }
    
    std::vector<IR*> v_col_id_or_string = get_ir_node_in_stmt_with_type(cur_ir, kColIdOrString);
    
    for (IR* cur_ident: v_col_id_or_string) {
        setup_col_id_or_string(cur_ident, data_type, data_flag);
    }
    
    std::vector<IR*> v_col_id = get_ir_node_in_stmt_with_type(cur_ir, kColId);
    
    for (IR* cur_ident: v_col_id) {
        setup_col_id(cur_ident, data_type, data_flag);
    }
    
    // No need to take care of TableFuncElementList, it is already handled in the ColIdOrString handling.
    
    return;
}


void setup_any_name(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag, DATATYPE data_type_par, DATATYPE data_type_par_par) {

    std::vector<IR*> v_iden = get_ir_node_in_stmt_with_type(cur_ir, kIdentifier);
    
    if (v_iden.size() == 1) {
        v_iden.back()->set_data_type(data_type);
        v_iden.back()->set_data_flag(data_flag);
    } else if (v_iden.size() == 2) {
        v_iden.back()->set_data_type(data_type);
        v_iden.back()->set_data_flag(data_flag);
        v_iden.front()->set_data_type(data_type_par);
        v_iden.front()->set_data_flag(kUse);
    } else if (v_iden.size() > 2) {
        v_iden.back()->set_data_type(data_type);
        v_iden.back()->set_data_flag(data_flag);
        v_iden[1]->set_data_type(data_type_par);
        v_iden[1]->set_data_flag(kUse);
        v_iden.front()->set_data_type(data_type_par_par);
        v_iden.front()->set_data_flag(kUse);
    }
    
    return;
}

void setup_any_name_list(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag, DATATYPE data_type_par, DATATYPE data_type_par_par) {

    std::vector<IR*> v_iden = get_ir_node_in_stmt_with_type(cur_ir, kAnyName);
    
    for (IR* cur_ident: v_iden) {
        setup_any_name(cur_ident, data_type, data_flag, data_type_par, data_type_par_par);
    }
    
    return;
}


/* parser_init()
 * Initialize to parse one query string
 */
void
parser_init(base_yy_extra_type *yyext)
{
	yyext->parsetree = NIL;		/* in case grammar forgets to set it */
}

#undef yyparse
#undef yylex
#undef yyerror
#undef yylval
#undef yychar
#undef yydebug
#undef yynerrs
#undef yylloc

} // namespace duckdb_libpgquery

