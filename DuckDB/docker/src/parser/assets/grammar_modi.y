
%{
#line 1 "third_party/libpg_query/grammar/grammar.hpp"

#include "pg_functions.hpp"
#include <string.h>
#include <string>
#include <vector>

#include <ctype.h>
#include <limits.h>

#include "nodes/makefuncs.hpp"
#include "nodes/nodeFuncs.hpp"
#include "parser/gramparse.hpp"
#include "parser/parser.hpp"
#include "utils/datetime.hpp"

namespace duckdb_libpgquery {
#define DEFAULT_SCHEMA "main"

std::vector<IR*> ir_vec;

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

static void base_yyerror(YYLTYPE *yylloc, core_yyscan_t yyscanner,
						 const char *msg);
%}
#line 5 "third_party/libpg_query/grammar/grammar.y"
%pure-parser
%expect 0
%name-prefix="base_yy"
%locations

%parse-param {core_yyscan_t yyscanner}
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
        auto tmp1 = $1;
        res = new IR(kStmtblock, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
        pg_yyget_extra(yyscanner)->ir_vec = ir_vec; 
        ir_vec.clear();
    }

;


stmtmulti:

    stmtmulti ';' stmt {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kStmtmulti, OP3("", ";", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | stmt {
        auto tmp1 = $1;
        res = new IR(kStmtmulti, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


stmt:

    AlterObjectSchemaStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | AlterSeqStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | AlterTableStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | AnalyzeStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | AttachStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CallStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CheckPointStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CopyStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CreateAsStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CreateFunctionStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CreateSchemaStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CreateSeqStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CreateStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CreateTypeStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | DeallocateStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | DeleteStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | DetachStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | DropStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ExecuteStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ExplainStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ExportStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ImportStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | IndexStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | InsertStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | LoadStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | PragmaStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | PrepareStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | RenameStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | SelectStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | TransactionStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | UpdateStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | UseStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | VacuumStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | VariableResetStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | VariableSetStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | VariableShowStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ViewStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kStmt, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


AlterTableStmt:

    ALTER TABLE relation_expr alter_table_cmds {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlterTableStmt, OP3("ALTER TABLE", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ALTER TABLE IF_P EXISTS relation_expr alter_table_cmds {
        auto tmp1 = $5;
        auto tmp2 = $6;
        res = new IR(kAlterTableStmt, OP3("ALTER TABLE IF EXISTS", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ALTER INDEX qualified_name alter_table_cmds {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlterTableStmt, OP3("ALTER INDEX", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ALTER INDEX IF_P EXISTS qualified_name alter_table_cmds {
        auto tmp1 = $5;
        auto tmp2 = $6;
        res = new IR(kAlterTableStmt, OP3("ALTER INDEX IF EXISTS", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ALTER SEQUENCE qualified_name alter_table_cmds {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlterTableStmt, OP3("ALTER SEQUENCE", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ALTER SEQUENCE IF_P EXISTS qualified_name alter_table_cmds {
        auto tmp1 = $5;
        auto tmp2 = $6;
        res = new IR(kAlterTableStmt, OP3("ALTER SEQUENCE IF EXISTS", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ALTER VIEW qualified_name alter_table_cmds {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlterTableStmt, OP3("ALTER VIEW", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ALTER VIEW IF_P EXISTS qualified_name alter_table_cmds {
        auto tmp1 = $5;
        auto tmp2 = $6;
        res = new IR(kAlterTableStmt, OP3("ALTER VIEW IF EXISTS", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


alter_identity_column_option_list:

    alter_identity_column_option {
        auto tmp1 = $1;
        res = new IR(kAlterIdentityColumnOptionList, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | alter_identity_column_option_list alter_identity_column_option {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAlterIdentityColumnOptionList, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


alter_column_default:

    SET DEFAULT a_expr {
        auto tmp1 = $3;
        res = new IR(kAlterColumnDefault, OP3("SET DEFAULT", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | DROP DEFAULT {
        res = new IR(kAlterColumnDefault, OP3("DROP DEFAULT", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


alter_identity_column_option:

    RESTART {
        res = new IR(kAlterIdentityColumnOption, OP3("RESTART", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | RESTART opt_with NumericOnly {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterIdentityColumnOption, OP3("RESTART", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | SET SeqOptElem {
        auto tmp1 = $2;
        res = new IR(kAlterIdentityColumnOption, OP3("SET", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | SET GENERATED generated_when {
        auto tmp1 = $3;
        res = new IR(kAlterIdentityColumnOption, OP3("SET GENERATED", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


alter_generic_option_list:

    alter_generic_option_elem {
        auto tmp1 = $1;
        res = new IR(kAlterGenericOptionList, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | alter_generic_option_list ',' alter_generic_option_elem {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAlterGenericOptionList, OP3("", ",", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


alter_table_cmd:

    ADD_P columnDef {
        auto tmp1 = $2;
        res = new IR(kAlterTableCmd, OP3("ADD", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ADD_P IF_P NOT EXISTS columnDef {
        auto tmp1 = $5;
        res = new IR(kAlterTableCmd, OP3("ADD IF NOT EXISTS", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ADD_P COLUMN columnDef {
        auto tmp1 = $3;
        res = new IR(kAlterTableCmd, OP3("ADD COLUMN", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ADD_P COLUMN IF_P NOT EXISTS columnDef {
        auto tmp1 = $6;
        res = new IR(kAlterTableCmd, OP3("ADD COLUMN IF NOT EXISTS", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ALTER opt_column ColId alter_column_default {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterTableCmd_1, OP3("ALTER", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $4;
        res = new IR(kAlterTableCmd, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ALTER opt_column ColId DROP NOT NULL_P {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterTableCmd, OP3("ALTER", "", "DROP NOT NULL"), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ALTER opt_column ColId SET NOT NULL_P {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterTableCmd, OP3("ALTER", "", "SET NOT NULL"), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ALTER opt_column ColId SET STATISTICS SignedIconst {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterTableCmd_2, OP3("ALTER", "", "SET STATISTICS"), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $6;
        res = new IR(kAlterTableCmd, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ALTER opt_column ColId SET reloptions {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterTableCmd_3, OP3("ALTER", "", "SET"), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $5;
        res = new IR(kAlterTableCmd, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ALTER opt_column ColId RESET reloptions {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterTableCmd_4, OP3("ALTER", "", "RESET"), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $5;
        res = new IR(kAlterTableCmd, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ALTER opt_column ColId SET STORAGE ColId {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterTableCmd_5, OP3("ALTER", "", "SET STORAGE"), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $6;
        res = new IR(kAlterTableCmd, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ALTER opt_column ColId ADD_P GENERATED generated_when AS IDENTITY_P OptParenthesizedSeqOptList {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterTableCmd_6, OP3("ALTER", "", "ADD GENERATED"), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $6;
        res = new IR(kAlterTableCmd_7, OP3("", "", "AS IDENTITY"), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $9;
        res = new IR(kAlterTableCmd, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ALTER opt_column ColId alter_identity_column_option_list {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterTableCmd_8, OP3("ALTER", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $4;
        res = new IR(kAlterTableCmd, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ALTER opt_column ColId DROP IDENTITY_P {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterTableCmd, OP3("ALTER", "", "DROP IDENTITY"), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ALTER opt_column ColId DROP IDENTITY_P IF_P EXISTS {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterTableCmd, OP3("ALTER", "", "DROP IDENTITY IF EXISTS"), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | DROP opt_column IF_P EXISTS ColId opt_drop_behavior {
        auto tmp1 = $2;
        auto tmp2 = $5;
        res = new IR(kAlterTableCmd_9, OP3("DROP", "IF EXISTS", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $6;
        res = new IR(kAlterTableCmd, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | DROP opt_column ColId opt_drop_behavior {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterTableCmd_10, OP3("DROP", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $4;
        res = new IR(kAlterTableCmd, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ALTER opt_column ColId opt_set_data TYPE_P Typename opt_collate_clause alter_using {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterTableCmd_11, OP3("ALTER", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $4;
        res = new IR(kAlterTableCmd_12, OP3("", "", "TYPE"), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $6;
        res = new IR(kAlterTableCmd_13, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        auto tmp5 = $7;
        res = new IR(kAlterTableCmd_14, OP3("", "", ""), res, tmp5);
        ir_vec.push_back(res); 
        auto tmp6 = $8;
        res = new IR(kAlterTableCmd, OP3("", "", ""), res, tmp6);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ALTER opt_column ColId alter_generic_options {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterTableCmd_15, OP3("ALTER", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $4;
        res = new IR(kAlterTableCmd, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ADD_P TableConstraint {
        auto tmp1 = $2;
        res = new IR(kAlterTableCmd, OP3("ADD", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ALTER CONSTRAINT name ConstraintAttributeSpec {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlterTableCmd, OP3("ALTER CONSTRAINT", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | VALIDATE CONSTRAINT name {
        auto tmp1 = $3;
        res = new IR(kAlterTableCmd, OP3("VALIDATE CONSTRAINT", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | DROP CONSTRAINT IF_P EXISTS name opt_drop_behavior {
        auto tmp1 = $5;
        auto tmp2 = $6;
        res = new IR(kAlterTableCmd, OP3("DROP CONSTRAINT IF EXISTS", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | DROP CONSTRAINT name opt_drop_behavior {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlterTableCmd, OP3("DROP CONSTRAINT", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | SET LOGGED {
        res = new IR(kAlterTableCmd, OP3("SET LOGGED", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | SET UNLOGGED {
        res = new IR(kAlterTableCmd, OP3("SET UNLOGGED", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | SET reloptions {
        auto tmp1 = $2;
        res = new IR(kAlterTableCmd, OP3("SET", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | RESET reloptions {
        auto tmp1 = $2;
        res = new IR(kAlterTableCmd, OP3("RESET", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | alter_generic_options {
        auto tmp1 = $1;
        res = new IR(kAlterTableCmd, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


alter_using:

    USING a_expr {
        auto tmp1 = $2;
        res = new IR(kAlterUsing, OP3("USING", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kAlterUsing, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


alter_generic_option_elem:

    generic_option_elem {
        auto tmp1 = $1;
        res = new IR(kAlterGenericOptionElem, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | SET generic_option_elem {
        auto tmp1 = $2;
        res = new IR(kAlterGenericOptionElem, OP3("SET", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ADD_P generic_option_elem {
        auto tmp1 = $2;
        res = new IR(kAlterGenericOptionElem, OP3("ADD", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | DROP generic_option_name {
        auto tmp1 = $2;
        res = new IR(kAlterGenericOptionElem, OP3("DROP", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


alter_table_cmds:

    alter_table_cmd {
        auto tmp1 = $1;
        res = new IR(kAlterTableCmds, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | alter_table_cmds ',' alter_table_cmd {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAlterTableCmds, OP3("", ",", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


alter_generic_options:

    OPTIONS '(' alter_generic_option_list ')' {
        auto tmp1 = $3;
        res = new IR(kAlterGenericOptions, OP3("OPTIONS (", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_set_data:

    SET DATA_P {
        res = new IR(kOptSetData, OP3("SET DATA", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | SET {
        res = new IR(kOptSetData, OP3("SET", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptSetData, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


DeallocateStmt:

    DEALLOCATE name {
        auto tmp1 = $2;
        res = new IR(kDeallocateStmt, OP3("DEALLOCATE", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | DEALLOCATE PREPARE name {
        auto tmp1 = $3;
        res = new IR(kDeallocateStmt, OP3("DEALLOCATE PREPARE", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | DEALLOCATE ALL {
        res = new IR(kDeallocateStmt, OP3("DEALLOCATE ALL", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | DEALLOCATE PREPARE ALL {
        res = new IR(kDeallocateStmt, OP3("DEALLOCATE PREPARE ALL", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


qualified_name:

    ColIdOrString {
        auto tmp1 = $1;
        res = new IR(kQualifiedName, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ColId indirection {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kQualifiedName, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


ColId:

    IDENT {
        auto tmp1 = new IR(kIdentifier, to_string($1), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        res = new IR(kColId, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


ColIdOrString:

    ColId {
        auto tmp1 = $1;
        res = new IR(kColIdOrString, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | SCONST {
        auto tmp1 = new IR(kStringLiteral, to_string($1), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        res = new IR(kColIdOrString, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


Sconst:

    SCONST {
        auto tmp1 = new IR(kStringLiteral, to_string($1), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        res = new IR(kSconst, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


indirection:

    indirection_el {
        auto tmp1 = $1;
        res = new IR(kIndirection, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | indirection indirection_el {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kIndirection, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


indirection_el:

    '.' attr_name {
        auto tmp1 = $2;
        res = new IR(kIndirectionEl, OP3(".", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


attr_name:

    ColLabel {
        auto tmp1 = $1;
        res = new IR(kAttrName, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


ColLabel:

    IDENT {
        auto tmp1 = new IR(kIdentifier, to_string($1), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        res = new IR(kColLabel, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


RenameStmt:

    ALTER SCHEMA name RENAME TO name {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kRenameStmt, OP3("ALTER SCHEMA", "RENAME TO", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ALTER TABLE relation_expr RENAME TO name {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kRenameStmt, OP3("ALTER TABLE", "RENAME TO", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ALTER TABLE IF_P EXISTS relation_expr RENAME TO name {
        auto tmp1 = $5;
        auto tmp2 = $8;
        res = new IR(kRenameStmt, OP3("ALTER TABLE IF EXISTS", "RENAME TO", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ALTER SEQUENCE qualified_name RENAME TO name {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kRenameStmt, OP3("ALTER SEQUENCE", "RENAME TO", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ALTER SEQUENCE IF_P EXISTS qualified_name RENAME TO name {
        auto tmp1 = $5;
        auto tmp2 = $8;
        res = new IR(kRenameStmt, OP3("ALTER SEQUENCE IF EXISTS", "RENAME TO", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ALTER VIEW qualified_name RENAME TO name {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kRenameStmt, OP3("ALTER VIEW", "RENAME TO", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ALTER VIEW IF_P EXISTS qualified_name RENAME TO name {
        auto tmp1 = $5;
        auto tmp2 = $8;
        res = new IR(kRenameStmt, OP3("ALTER VIEW IF EXISTS", "RENAME TO", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ALTER INDEX qualified_name RENAME TO name {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kRenameStmt, OP3("ALTER INDEX", "RENAME TO", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ALTER INDEX IF_P EXISTS qualified_name RENAME TO name {
        auto tmp1 = $5;
        auto tmp2 = $8;
        res = new IR(kRenameStmt, OP3("ALTER INDEX IF EXISTS", "RENAME TO", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ALTER TABLE relation_expr RENAME opt_column name TO name {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kRenameStmt_1, OP3("ALTER TABLE", "RENAME", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $6;
        res = new IR(kRenameStmt_2, OP3("", "", "TO"), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $8;
        res = new IR(kRenameStmt, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ALTER TABLE IF_P EXISTS relation_expr RENAME opt_column name TO name {
        auto tmp1 = $5;
        auto tmp2 = $7;
        res = new IR(kRenameStmt_3, OP3("ALTER TABLE IF EXISTS", "RENAME", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $8;
        res = new IR(kRenameStmt_4, OP3("", "", "TO"), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $10;
        res = new IR(kRenameStmt, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ALTER TABLE relation_expr RENAME CONSTRAINT name TO name {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kRenameStmt_5, OP3("ALTER TABLE", "RENAME CONSTRAINT", "TO"), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $8;
        res = new IR(kRenameStmt, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ALTER TABLE IF_P EXISTS relation_expr RENAME CONSTRAINT name TO name {
        auto tmp1 = $5;
        auto tmp2 = $8;
        res = new IR(kRenameStmt_6, OP3("ALTER TABLE IF EXISTS", "RENAME CONSTRAINT", "TO"), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $10;
        res = new IR(kRenameStmt, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_column:

    COLUMN {
        res = new IR(kOptColumn, OP3("COLUMN", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptColumn, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


InsertStmt:

    opt_with_clause INSERT opt_or_action INTO insert_target opt_by_name_or_position insert_rest opt_on_conflict returning_clause {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kInsertStmt_1, OP3("", "INSERT", "INTO"), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $5;
        res = new IR(kInsertStmt_2, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $6;
        res = new IR(kInsertStmt_3, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        auto tmp5 = $7;
        res = new IR(kInsertStmt_4, OP3("", "", ""), res, tmp5);
        ir_vec.push_back(res); 
        auto tmp6 = $8;
        res = new IR(kInsertStmt_5, OP3("", "", ""), res, tmp6);
        ir_vec.push_back(res); 
        auto tmp7 = $9;
        res = new IR(kInsertStmt, OP3("", "", ""), res, tmp7);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


insert_rest:

    SelectStmt {
        auto tmp1 = $1;
        res = new IR(kInsertRest, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | OVERRIDING override_kind VALUE_P SelectStmt {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kInsertRest, OP3("OVERRIDING", "VALUE", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '(' insert_column_list ')' SelectStmt {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kInsertRest, OP3("(", ")", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '(' insert_column_list ')' OVERRIDING override_kind VALUE_P SelectStmt {
        auto tmp1 = $2;
        auto tmp2 = $5;
        res = new IR(kInsertRest_1, OP3("(", ") OVERRIDING", "VALUE"), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $7;
        res = new IR(kInsertRest, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | DEFAULT VALUES {
        res = new IR(kInsertRest, OP3("DEFAULT VALUES", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


insert_target:

    qualified_name {
        auto tmp1 = $1;
        res = new IR(kInsertTarget, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | qualified_name AS ColId {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kInsertTarget, OP3("", "AS", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_by_name_or_position:

    BY NAME_P {
        res = new IR(kOptByNameOrPosition, OP3("BY NAME", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | BY POSITION {
        res = new IR(kOptByNameOrPosition, OP3("BY POSITION", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptByNameOrPosition, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_conf_expr:

    '(' index_params ')' where_clause {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kOptConfExpr, OP3("(", ")", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ON CONSTRAINT name {
        auto tmp1 = new IR(kStringLiteral, to_string($1), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        auto tmp2 = $3;
        res = new IR(kOptConfExpr, OP3("", "CONSTRAINT", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptConfExpr, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_with_clause:

    with_clause {
        auto tmp1 = $1;
        res = new IR(kOptWithClause, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptWithClause, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


insert_column_item:

    ColId opt_indirection {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kInsertColumnItem, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


set_clause:

    set_target '=' a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSetClause, OP3("", "=", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '(' set_target_list ')' '=' a_expr {
        auto tmp1 = $2;
        auto tmp2 = $5;
        res = new IR(kSetClause, OP3("(", ") =", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_or_action:

    OR REPLACE {
        res = new IR(kOptOrAction, OP3("OR REPLACE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | OR IGNORE_P {
        res = new IR(kOptOrAction, OP3("OR IGNORE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptOrAction, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_on_conflict:

    ON CONFLICT opt_conf_expr DO UPDATE SET set_clause_list_opt_comma where_clause {
        auto tmp1 = new IR(kStringLiteral, to_string($1), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        auto tmp2 = $3;
        res = new IR(kOptOnConflict_1, OP3("", "CONFLICT", "DO UPDATE SET"), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $7;
        res = new IR(kOptOnConflict_2, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $8;
        res = new IR(kOptOnConflict, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ON CONFLICT opt_conf_expr DO NOTHING {
        auto tmp1 = new IR(kStringLiteral, to_string($1), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        auto tmp2 = $3;
        res = new IR(kOptOnConflict, OP3("", "CONFLICT", "DO NOTHING"), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptOnConflict, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


index_elem:

    ColId opt_collate opt_class opt_asc_desc opt_nulls_order {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kIndexElem_1, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $3;
        res = new IR(kIndexElem_2, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $4;
        res = new IR(kIndexElem_3, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        auto tmp5 = $5;
        res = new IR(kIndexElem, OP3("", "", ""), res, tmp5);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | func_expr_windowless opt_collate opt_class opt_asc_desc opt_nulls_order {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kIndexElem_4, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $3;
        res = new IR(kIndexElem_5, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $4;
        res = new IR(kIndexElem_6, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        auto tmp5 = $5;
        res = new IR(kIndexElem, OP3("", "", ""), res, tmp5);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '(' a_expr ')' opt_collate opt_class opt_asc_desc opt_nulls_order {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kIndexElem_7, OP3("(", ")", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $5;
        res = new IR(kIndexElem_8, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $6;
        res = new IR(kIndexElem_9, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        auto tmp5 = $7;
        res = new IR(kIndexElem, OP3("", "", ""), res, tmp5);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


returning_clause:

    RETURNING target_list {
        auto tmp1 = $2;
        res = new IR(kReturningClause, OP3("RETURNING", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kReturningClause, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


override_kind:

    USER {
        res = new IR(kOverrideKind, OP3("USER", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | SYSTEM_P {
        res = new IR(kOverrideKind, OP3("SYSTEM", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


set_target_list:

    set_target {
        auto tmp1 = $1;
        res = new IR(kSetTargetList, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | set_target_list ',' set_target {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSetTargetList, OP3("", ",", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_collate:

    COLLATE any_name {
        auto tmp1 = $2;
        res = new IR(kOptCollate, OP3("COLLATE", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptCollate, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_class:

    any_name {
        auto tmp1 = $1;
        res = new IR(kOptClass, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptClass, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


insert_column_list:

    insert_column_item {
        auto tmp1 = $1;
        res = new IR(kInsertColumnList, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | insert_column_list ',' insert_column_item {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kInsertColumnList, OP3("", ",", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


set_clause_list:

    set_clause {
        auto tmp1 = $1;
        res = new IR(kSetClauseList, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | set_clause_list ',' set_clause {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSetClauseList, OP3("", ",", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


set_clause_list_opt_comma:

    set_clause_list {
        auto tmp1 = $1;
        res = new IR(kSetClauseListOptComma, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | set_clause_list ',' {
        auto tmp1 = $1;
        res = new IR(kSetClauseListOptComma, OP3("", ",", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


index_params:

    index_elem {
        auto tmp1 = $1;
        res = new IR(kIndexParams, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | index_params ',' index_elem {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kIndexParams, OP3("", ",", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


set_target:

    ColId opt_indirection {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSetTarget, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


CreateTypeStmt:

    CREATE_P TYPE_P qualified_name AS ENUM_P select_with_parens {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kCreateTypeStmt, OP3("CREATE TYPE", "AS ENUM", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CREATE_P TYPE_P qualified_name AS ENUM_P '(' opt_enum_val_list ')' {
        auto tmp1 = $3;
        auto tmp2 = $7;
        res = new IR(kCreateTypeStmt, OP3("CREATE TYPE", "AS ENUM (", ")"), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CREATE_P TYPE_P qualified_name AS Typename {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kCreateTypeStmt, OP3("CREATE TYPE", "AS", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_enum_val_list:

    enum_val_list {
        auto tmp1 = $1;
        res = new IR(kOptEnumValList, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptEnumValList, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


enum_val_list:

    Sconst {
        auto tmp1 = $1;
        res = new IR(kEnumValList, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | enum_val_list ',' Sconst {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kEnumValList, OP3("", ",", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


PragmaStmt:

    PRAGMA_P ColId {
        auto tmp1 = $2;
        res = new IR(kPragmaStmt, OP3("PRAGMA", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | PRAGMA_P ColId '=' var_list {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kPragmaStmt, OP3("PRAGMA", "=", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | PRAGMA_P ColId '(' func_arg_list ')' {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kPragmaStmt, OP3("PRAGMA", "(", ")"), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


CreateSeqStmt:

    CREATE_P OptTemp SEQUENCE qualified_name OptSeqOptList {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kCreateSeqStmt_1, OP3("CREATE", "SEQUENCE", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $5;
        res = new IR(kCreateSeqStmt, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CREATE_P OptTemp SEQUENCE IF_P NOT EXISTS qualified_name OptSeqOptList {
        auto tmp1 = $2;
        auto tmp2 = $7;
        res = new IR(kCreateSeqStmt_2, OP3("CREATE", "SEQUENCE IF NOT EXISTS", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $8;
        res = new IR(kCreateSeqStmt, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CREATE_P OR REPLACE OptTemp SEQUENCE qualified_name OptSeqOptList {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kCreateSeqStmt_3, OP3("CREATE OR REPLACE", "SEQUENCE", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $7;
        res = new IR(kCreateSeqStmt, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


OptSeqOptList:

    SeqOptList {
        auto tmp1 = $1;
        res = new IR(kOptSeqOptList, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptSeqOptList, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


ExecuteStmt:

    EXECUTE name execute_param_clause {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kExecuteStmt, OP3("EXECUTE", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CREATE_P OptTemp TABLE create_as_target AS EXECUTE name execute_param_clause opt_with_data {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kExecuteStmt_1, OP3("CREATE", "TABLE", "AS EXECUTE"), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $7;
        res = new IR(kExecuteStmt_2, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $8;
        res = new IR(kExecuteStmt_3, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        auto tmp5 = $9;
        res = new IR(kExecuteStmt, OP3("", "", ""), res, tmp5);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CREATE_P OptTemp TABLE IF_P NOT EXISTS create_as_target AS EXECUTE name execute_param_clause opt_with_data {
        auto tmp1 = $2;
        auto tmp2 = $7;
        res = new IR(kExecuteStmt_4, OP3("CREATE", "TABLE IF NOT EXISTS", "AS EXECUTE"), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $10;
        res = new IR(kExecuteStmt_5, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $11;
        res = new IR(kExecuteStmt_6, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        auto tmp5 = $12;
        res = new IR(kExecuteStmt, OP3("", "", ""), res, tmp5);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


execute_param_expr:

    a_expr {
        auto tmp1 = $1;
        res = new IR(kExecuteParamExpr, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | param_name COLON_EQUALS a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kExecuteParamExpr, OP3("", "COLON_EQUALS", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


execute_param_list:

    execute_param_expr {
        auto tmp1 = $1;
        res = new IR(kExecuteParamList, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | execute_param_list ',' execute_param_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kExecuteParamList, OP3("", ",", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


execute_param_clause:

    '(' execute_param_list ')' {
        auto tmp1 = $2;
        res = new IR(kExecuteParamClause, OP3("(", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kExecuteParamClause, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


AlterSeqStmt:

    ALTER SEQUENCE qualified_name SeqOptList {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlterSeqStmt, OP3("ALTER SEQUENCE", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ALTER SEQUENCE IF_P EXISTS qualified_name SeqOptList {
        auto tmp1 = $5;
        auto tmp2 = $6;
        res = new IR(kAlterSeqStmt, OP3("ALTER SEQUENCE IF EXISTS", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


SeqOptList:

    SeqOptElem {
        auto tmp1 = $1;
        res = new IR(kSeqOptList, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | SeqOptList SeqOptElem {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSeqOptList, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_with:

    WITH {
        res = new IR(kOptWith, OP3("WITH", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | WITH_LA {
        res = new IR(kOptWith, OP3("WITH", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptWith, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


NumericOnly:

    FCONST {
        auto tmp1 = new IR(kFloatLiteral, to_string($1), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        res = new IR(kNumericOnly, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '+' FCONST {
        auto tmp1 = new IR(kFloatLiteral, to_string($2), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        res = new IR(kNumericOnly, OP3("+", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '-' FCONST {
        auto tmp1 = new IR(kFloatLiteral, to_string($2), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        res = new IR(kNumericOnly, OP3("-", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | SignedIconst {
        auto tmp1 = $1;
        res = new IR(kNumericOnly, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


SeqOptElem:

    AS SimpleTypename {
        auto tmp1 = $2;
        res = new IR(kSeqOptElem, OP3("AS", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CACHE NumericOnly {
        auto tmp1 = $2;
        res = new IR(kSeqOptElem, OP3("CACHE", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CYCLE {
        res = new IR(kSeqOptElem, OP3("CYCLE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | NO CYCLE {
        res = new IR(kSeqOptElem, OP3("NO CYCLE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | INCREMENT opt_by NumericOnly {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSeqOptElem, OP3("INCREMENT", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | MAXVALUE NumericOnly {
        auto tmp1 = $2;
        res = new IR(kSeqOptElem, OP3("MAXVALUE", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | MINVALUE NumericOnly {
        auto tmp1 = $2;
        res = new IR(kSeqOptElem, OP3("MINVALUE", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | NO MAXVALUE {
        res = new IR(kSeqOptElem, OP3("NO MAXVALUE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | NO MINVALUE {
        res = new IR(kSeqOptElem, OP3("NO MINVALUE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | OWNED BY any_name {
        auto tmp1 = $3;
        res = new IR(kSeqOptElem, OP3("OWNED BY", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | SEQUENCE NAME_P any_name {
        auto tmp1 = $3;
        res = new IR(kSeqOptElem, OP3("SEQUENCE NAME", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | START opt_with NumericOnly {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSeqOptElem, OP3("START", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | RESTART {
        res = new IR(kSeqOptElem, OP3("RESTART", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | RESTART opt_with NumericOnly {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSeqOptElem, OP3("RESTART", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_by:

    BY {
        res = new IR(kOptBy, OP3("BY", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptBy, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


SignedIconst:

    Iconst {
        auto tmp1 = $1;
        res = new IR(kSignedIconst, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '+' Iconst {
        auto tmp1 = $2;
        res = new IR(kSignedIconst, OP3("+", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '-' Iconst {
        auto tmp1 = $2;
        res = new IR(kSignedIconst, OP3("-", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


TransactionStmt:

    ABORT_P opt_transaction {
        auto tmp1 = $2;
        res = new IR(kTransactionStmt, OP3("ABORT", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | BEGIN_P opt_transaction {
        auto tmp1 = $2;
        res = new IR(kTransactionStmt, OP3("BEGIN", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | START opt_transaction {
        auto tmp1 = $2;
        res = new IR(kTransactionStmt, OP3("START", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | COMMIT opt_transaction {
        auto tmp1 = $2;
        res = new IR(kTransactionStmt, OP3("COMMIT", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | END_P opt_transaction {
        auto tmp1 = $2;
        res = new IR(kTransactionStmt, OP3("END", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ROLLBACK opt_transaction {
        auto tmp1 = $2;
        res = new IR(kTransactionStmt, OP3("ROLLBACK", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_transaction:

    WORK {
        res = new IR(kOptTransaction, OP3("WORK", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | TRANSACTION {
        res = new IR(kOptTransaction, OP3("TRANSACTION", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptTransaction, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


UseStmt:

    USE_P qualified_name {
        auto tmp1 = $2;
        res = new IR(kUseStmt, OP3("USE", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


CreateStmt:

    CREATE_P OptTemp TABLE qualified_name '(' OptTableElementList ')' OptWith OnCommitOption {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kCreateStmt_1, OP3("CREATE", "TABLE", "("), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $6;
        res = new IR(kCreateStmt_2, OP3("", "", ")"), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $8;
        res = new IR(kCreateStmt_3, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        auto tmp5 = $9;
        res = new IR(kCreateStmt, OP3("", "", ""), res, tmp5);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CREATE_P OptTemp TABLE IF_P NOT EXISTS qualified_name '(' OptTableElementList ')' OptWith OnCommitOption {
        auto tmp1 = $2;
        auto tmp2 = $7;
        res = new IR(kCreateStmt_4, OP3("CREATE", "TABLE IF NOT EXISTS", "("), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $9;
        res = new IR(kCreateStmt_5, OP3("", "", ")"), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $11;
        res = new IR(kCreateStmt_6, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        auto tmp5 = $12;
        res = new IR(kCreateStmt, OP3("", "", ""), res, tmp5);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CREATE_P OR REPLACE OptTemp TABLE qualified_name '(' OptTableElementList ')' OptWith OnCommitOption {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kCreateStmt_7, OP3("CREATE OR REPLACE", "TABLE", "("), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $8;
        res = new IR(kCreateStmt_8, OP3("", "", ")"), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $10;
        res = new IR(kCreateStmt_9, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        auto tmp5 = $11;
        res = new IR(kCreateStmt, OP3("", "", ""), res, tmp5);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


ConstraintAttributeSpec:

    /*EMPTY*/ {
        res = new IR(kConstraintAttributeSpec, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ConstraintAttributeSpec ConstraintAttributeElem {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kConstraintAttributeSpec, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


def_arg:

    func_type {
        auto tmp1 = $1;
        res = new IR(kDefArg, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | qual_all_Op {
        auto tmp1 = $1;
        res = new IR(kDefArg, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | NumericOnly {
        auto tmp1 = $1;
        res = new IR(kDefArg, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | Sconst {
        auto tmp1 = $1;
        res = new IR(kDefArg, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | NONE {
        res = new IR(kDefArg, OP3("NONE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


OptParenthesizedSeqOptList:

    '(' SeqOptList ')' {
        auto tmp1 = $2;
        res = new IR(kOptParenthesizedSeqOptList, OP3("(", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptParenthesizedSeqOptList, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


generic_option_arg:

    Sconst {
        auto tmp1 = $1;
        res = new IR(kGenericOptionArg, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


key_action:

    NO ACTION {
        res = new IR(kKeyAction, OP3("NO ACTION", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | RESTRICT {
        res = new IR(kKeyAction, OP3("RESTRICT", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CASCADE {
        res = new IR(kKeyAction, OP3("CASCADE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | SET NULL_P {
        res = new IR(kKeyAction, OP3("SET NULL", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | SET DEFAULT {
        res = new IR(kKeyAction, OP3("SET DEFAULT", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


ColConstraint:

    CONSTRAINT name ColConstraintElem {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kColConstraint, OP3("CONSTRAINT", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ColConstraintElem {
        auto tmp1 = $1;
        res = new IR(kColConstraint, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ConstraintAttr {
        auto tmp1 = $1;
        res = new IR(kColConstraint, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | COLLATE any_name {
        auto tmp1 = $2;
        res = new IR(kColConstraint, OP3("COLLATE", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


ColConstraintElem:

    NOT NULL_P {
        res = new IR(kColConstraintElem, OP3("NOT NULL", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | NULL_P {
        res = new IR(kColConstraintElem, OP3("NULL", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | UNIQUE opt_definition {
        auto tmp1 = $2;
        res = new IR(kColConstraintElem, OP3("UNIQUE", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | PRIMARY KEY opt_definition {
        auto tmp1 = $3;
        res = new IR(kColConstraintElem, OP3("PRIMARY KEY", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CHECK_P '(' a_expr ')' opt_no_inherit {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kColConstraintElem, OP3("CHECK (", ")", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | USING COMPRESSION name {
        auto tmp1 = $3;
        res = new IR(kColConstraintElem, OP3("USING COMPRESSION", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | DEFAULT b_expr {
        auto tmp1 = $2;
        res = new IR(kColConstraintElem, OP3("DEFAULT", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | REFERENCES qualified_name opt_column_list key_match key_actions {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kColConstraintElem_1, OP3("REFERENCES", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $4;
        res = new IR(kColConstraintElem_2, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $5;
        res = new IR(kColConstraintElem, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


GeneratedColumnType:

    VIRTUAL {
        res = new IR(kGeneratedColumnType, OP3("VIRTUAL", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | STORED {
        res = new IR(kGeneratedColumnType, OP3("STORED", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_GeneratedColumnType:

    GeneratedColumnType {
        auto tmp1 = $1;
        res = new IR(kOptGeneratedColumnType, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptGeneratedColumnType, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


GeneratedConstraintElem:

    GENERATED generated_when AS IDENTITY_P OptParenthesizedSeqOptList {
        auto tmp1 = $2;
        auto tmp2 = $5;
        res = new IR(kGeneratedConstraintElem, OP3("GENERATED", "AS IDENTITY", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | GENERATED generated_when AS '(' a_expr ')' opt_GeneratedColumnType {
        auto tmp1 = $2;
        auto tmp2 = $5;
        res = new IR(kGeneratedConstraintElem_1, OP3("GENERATED", "AS (", ")"), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $7;
        res = new IR(kGeneratedConstraintElem, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | AS '(' a_expr ')' opt_GeneratedColumnType {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kGeneratedConstraintElem, OP3("AS (", ")", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


generic_option_elem:

    generic_option_name generic_option_arg {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kGenericOptionElem, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


key_update:

    ON UPDATE key_action {
        auto tmp1 = new IR(kStringLiteral, to_string($1), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        auto tmp2 = $3;
        res = new IR(kKeyUpdate, OP3("", "UPDATE", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


key_actions:

    key_update {
        auto tmp1 = $1;
        res = new IR(kKeyActions, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | key_delete {
        auto tmp1 = $1;
        res = new IR(kKeyActions, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | key_update key_delete {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kKeyActions, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | key_delete key_update {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kKeyActions, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kKeyActions, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


OnCommitOption:

    ON COMMIT DROP {
        auto tmp1 = new IR(kStringLiteral, to_string($1), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        res = new IR(kOnCommitOption, OP3("", "COMMIT DROP", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ON COMMIT DELETE_P ROWS {
        auto tmp1 = new IR(kStringLiteral, to_string($1), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        res = new IR(kOnCommitOption, OP3("", "COMMIT DELETE ROWS", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ON COMMIT PRESERVE ROWS {
        auto tmp1 = new IR(kStringLiteral, to_string($1), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        res = new IR(kOnCommitOption, OP3("", "COMMIT PRESERVE ROWS", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOnCommitOption, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


reloptions:

    '(' reloption_list ')' {
        auto tmp1 = $2;
        res = new IR(kReloptions, OP3("(", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_no_inherit:

    NO INHERIT {
        res = new IR(kOptNoInherit, OP3("NO INHERIT", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptNoInherit, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


TableConstraint:

    CONSTRAINT name ConstraintElem {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kTableConstraint, OP3("CONSTRAINT", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ConstraintElem {
        auto tmp1 = $1;
        res = new IR(kTableConstraint, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


TableLikeOption:

    COMMENTS {
        res = new IR(kTableLikeOption, OP3("COMMENTS", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CONSTRAINTS {
        res = new IR(kTableLikeOption, OP3("CONSTRAINTS", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | DEFAULTS {
        res = new IR(kTableLikeOption, OP3("DEFAULTS", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | IDENTITY_P {
        res = new IR(kTableLikeOption, OP3("IDENTITY", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | INDEXES {
        res = new IR(kTableLikeOption, OP3("INDEXES", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | STATISTICS {
        res = new IR(kTableLikeOption, OP3("STATISTICS", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | STORAGE {
        res = new IR(kTableLikeOption, OP3("STORAGE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ALL {
        res = new IR(kTableLikeOption, OP3("ALL", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


reloption_list:

    reloption_elem {
        auto tmp1 = $1;
        res = new IR(kReloptionList, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | reloption_list ',' reloption_elem {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kReloptionList, OP3("", ",", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


ExistingIndex:

    USING INDEX index_name {
        auto tmp1 = $3;
        res = new IR(kExistingIndex, OP3("USING INDEX", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


ConstraintAttr:

    DEFERRABLE {
        res = new IR(kConstraintAttr, OP3("DEFERRABLE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | NOT DEFERRABLE {
        res = new IR(kConstraintAttr, OP3("NOT DEFERRABLE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | INITIALLY DEFERRED {
        res = new IR(kConstraintAttr, OP3("INITIALLY DEFERRED", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | INITIALLY IMMEDIATE {
        res = new IR(kConstraintAttr, OP3("INITIALLY IMMEDIATE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


OptWith:

    WITH reloptions {
        auto tmp1 = $2;
        res = new IR(kOptWith, OP3("WITH", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | WITH OIDS {
        res = new IR(kOptWith, OP3("WITH OIDS", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | WITHOUT OIDS {
        res = new IR(kOptWith, OP3("WITHOUT OIDS", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptWith, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


definition:

    '(' def_list ')' {
        auto tmp1 = $2;
        res = new IR(kDefinition, OP3("(", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


TableLikeOptionList:

    TableLikeOptionList INCLUDING TableLikeOption {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTableLikeOptionList, OP3("", "INCLUDING", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | TableLikeOptionList EXCLUDING TableLikeOption {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTableLikeOptionList, OP3("", "EXCLUDING", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kTableLikeOptionList, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


generic_option_name:

    ColLabel {
        auto tmp1 = $1;
        res = new IR(kGenericOptionName, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


ConstraintAttributeElem:

    NOT DEFERRABLE {
        res = new IR(kConstraintAttributeElem, OP3("NOT DEFERRABLE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | DEFERRABLE {
        res = new IR(kConstraintAttributeElem, OP3("DEFERRABLE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | INITIALLY IMMEDIATE {
        res = new IR(kConstraintAttributeElem, OP3("INITIALLY IMMEDIATE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | INITIALLY DEFERRED {
        res = new IR(kConstraintAttributeElem, OP3("INITIALLY DEFERRED", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | NOT VALID {
        res = new IR(kConstraintAttributeElem, OP3("NOT VALID", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | NO INHERIT {
        res = new IR(kConstraintAttributeElem, OP3("NO INHERIT", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


columnDef:

    ColId Typename ColQualList {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kColumnDef_1, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $3;
        res = new IR(kColumnDef, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ColId opt_Typename GeneratedConstraintElem ColQualList {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kColumnDef_2, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $3;
        res = new IR(kColumnDef_3, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $4;
        res = new IR(kColumnDef, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


def_list:

    def_elem {
        auto tmp1 = $1;
        res = new IR(kDefList, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | def_list ',' def_elem {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kDefList, OP3("", ",", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


index_name:

    ColId {
        auto tmp1 = $1;
        res = new IR(kIndexName, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


TableElement:

    columnDef {
        auto tmp1 = $1;
        res = new IR(kTableElement, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | TableLikeClause {
        auto tmp1 = $1;
        res = new IR(kTableElement, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | TableConstraint {
        auto tmp1 = $1;
        res = new IR(kTableElement, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


def_elem:

    ColLabel '=' def_arg {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kDefElem, OP3("", "=", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ColLabel {
        auto tmp1 = $1;
        res = new IR(kDefElem, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_definition:

    WITH definition {
        auto tmp1 = $2;
        res = new IR(kOptDefinition, OP3("WITH", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptDefinition, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


OptTableElementList:

    TableElementList {
        auto tmp1 = $1;
        res = new IR(kOptTableElementList, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | TableElementList ',' {
        auto tmp1 = $1;
        res = new IR(kOptTableElementList, OP3("", ",", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptTableElementList, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


columnElem:

    ColId {
        auto tmp1 = $1;
        res = new IR(kColumnElem, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_column_list:

    '(' columnList ')' {
        auto tmp1 = $2;
        res = new IR(kOptColumnList, OP3("(", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptColumnList, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


ColQualList:

    ColQualList ColConstraint {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kColQualList, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kColQualList, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


key_delete:

    ON DELETE_P key_action {
        auto tmp1 = new IR(kStringLiteral, to_string($1), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        auto tmp2 = $3;
        res = new IR(kKeyDelete, OP3("", "DELETE", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


reloption_elem:

    ColLabel '=' def_arg {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kReloptionElem, OP3("", "=", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ColLabel {
        auto tmp1 = $1;
        res = new IR(kReloptionElem, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ColLabel '.' ColLabel '=' def_arg {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kReloptionElem_1, OP3("", ".", "="), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $5;
        res = new IR(kReloptionElem, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ColLabel '.' ColLabel {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kReloptionElem, OP3("", ".", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


columnList:

    columnElem {
        auto tmp1 = $1;
        res = new IR(kColumnList, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | columnList ',' columnElem {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kColumnList, OP3("", ",", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


columnList_opt_comma:

    columnList {
        auto tmp1 = $1;
        res = new IR(kColumnListOptComma, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | columnList ',' {
        auto tmp1 = $1;
        res = new IR(kColumnListOptComma, OP3("", ",", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


func_type:

    Typename {
        auto tmp1 = $1;
        res = new IR(kFuncType, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | type_function_name attrs '%' TYPE_P {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFuncType, OP3("", "", "% TYPE"), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | SETOF type_function_name attrs '%' TYPE_P {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kFuncType, OP3("SETOF", "", "% TYPE"), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


ConstraintElem:

    CHECK_P '(' a_expr ')' ConstraintAttributeSpec {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kConstraintElem, OP3("CHECK (", ")", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | UNIQUE '(' columnList_opt_comma ')' opt_definition ConstraintAttributeSpec {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kConstraintElem_1, OP3("UNIQUE (", ")", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $6;
        res = new IR(kConstraintElem, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | UNIQUE ExistingIndex ConstraintAttributeSpec {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kConstraintElem, OP3("UNIQUE", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | PRIMARY KEY '(' columnList_opt_comma ')' opt_definition ConstraintAttributeSpec {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kConstraintElem_2, OP3("PRIMARY KEY (", ")", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $7;
        res = new IR(kConstraintElem, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | PRIMARY KEY ExistingIndex ConstraintAttributeSpec {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kConstraintElem, OP3("PRIMARY KEY", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | FOREIGN KEY '(' columnList_opt_comma ')' REFERENCES qualified_name opt_column_list key_match key_actions ConstraintAttributeSpec {
        auto tmp1 = $4;
        auto tmp2 = $7;
        res = new IR(kConstraintElem_3, OP3("FOREIGN KEY (", ") REFERENCES", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $8;
        res = new IR(kConstraintElem_4, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $9;
        res = new IR(kConstraintElem_5, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        auto tmp5 = $10;
        res = new IR(kConstraintElem_6, OP3("", "", ""), res, tmp5);
        ir_vec.push_back(res); 
        auto tmp6 = $11;
        res = new IR(kConstraintElem, OP3("", "", ""), res, tmp6);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


TableElementList:

    TableElement {
        auto tmp1 = $1;
        res = new IR(kTableElementList, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | TableElementList ',' TableElement {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTableElementList, OP3("", ",", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


key_match:

    MATCH FULL {
        res = new IR(kKeyMatch, OP3("MATCH FULL", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | MATCH PARTIAL {
        res = new IR(kKeyMatch, OP3("MATCH PARTIAL", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | MATCH SIMPLE {
        res = new IR(kKeyMatch, OP3("MATCH SIMPLE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kKeyMatch, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


TableLikeClause:

    LIKE qualified_name TableLikeOptionList {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kTableLikeClause, OP3("LIKE", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


OptTemp:

    TEMPORARY {
        res = new IR(kOptTemp, OP3("TEMPORARY", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | TEMP {
        res = new IR(kOptTemp, OP3("TEMP", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | LOCAL TEMPORARY {
        res = new IR(kOptTemp, OP3("LOCAL TEMPORARY", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | LOCAL TEMP {
        res = new IR(kOptTemp, OP3("LOCAL TEMP", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | GLOBAL TEMPORARY {
        res = new IR(kOptTemp, OP3("GLOBAL TEMPORARY", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | GLOBAL TEMP {
        res = new IR(kOptTemp, OP3("GLOBAL TEMP", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | UNLOGGED {
        res = new IR(kOptTemp, OP3("UNLOGGED", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptTemp, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


generated_when:

    ALWAYS {
        res = new IR(kGeneratedWhen, OP3("ALWAYS", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | BY DEFAULT {
        res = new IR(kGeneratedWhen, OP3("BY DEFAULT", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


DropStmt:

    DROP drop_type_any_name IF_P EXISTS any_name_list opt_drop_behavior {
        auto tmp1 = $2;
        auto tmp2 = $5;
        res = new IR(kDropStmt_1, OP3("DROP", "IF EXISTS", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $6;
        res = new IR(kDropStmt, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | DROP drop_type_any_name any_name_list opt_drop_behavior {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kDropStmt_2, OP3("DROP", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $4;
        res = new IR(kDropStmt, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | DROP drop_type_name IF_P EXISTS name_list opt_drop_behavior {
        auto tmp1 = $2;
        auto tmp2 = $5;
        res = new IR(kDropStmt_3, OP3("DROP", "IF EXISTS", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $6;
        res = new IR(kDropStmt, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | DROP drop_type_name name_list opt_drop_behavior {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kDropStmt_4, OP3("DROP", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $4;
        res = new IR(kDropStmt, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | DROP drop_type_name_on_any_name name ON any_name opt_drop_behavior {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kDropStmt_5, OP3("DROP", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = new IR(kStringLiteral, to_string($4), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp3);
        res = new IR(kDropStmt_6, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $5;
        res = new IR(kDropStmt_7, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        auto tmp5 = $6;
        res = new IR(kDropStmt, OP3("", "", ""), res, tmp5);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | DROP drop_type_name_on_any_name IF_P EXISTS name ON any_name opt_drop_behavior {
        auto tmp1 = $2;
        auto tmp2 = $5;
        res = new IR(kDropStmt_8, OP3("DROP", "IF EXISTS", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = new IR(kStringLiteral, to_string($6), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp3);
        res = new IR(kDropStmt_9, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $7;
        res = new IR(kDropStmt_10, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        auto tmp5 = $8;
        res = new IR(kDropStmt, OP3("", "", ""), res, tmp5);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | DROP TYPE_P type_name_list opt_drop_behavior {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kDropStmt, OP3("DROP TYPE", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | DROP TYPE_P IF_P EXISTS type_name_list opt_drop_behavior {
        auto tmp1 = $5;
        auto tmp2 = $6;
        res = new IR(kDropStmt, OP3("DROP TYPE IF EXISTS", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


drop_type_any_name:

    TABLE {
        res = new IR(kDropTypeAnyName, OP3("TABLE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | SEQUENCE {
        res = new IR(kDropTypeAnyName, OP3("SEQUENCE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | FUNCTION {
        res = new IR(kDropTypeAnyName, OP3("FUNCTION", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | MACRO {
        res = new IR(kDropTypeAnyName, OP3("MACRO", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | MACRO TABLE {
        res = new IR(kDropTypeAnyName, OP3("MACRO TABLE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | VIEW {
        res = new IR(kDropTypeAnyName, OP3("VIEW", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | MATERIALIZED VIEW {
        res = new IR(kDropTypeAnyName, OP3("MATERIALIZED VIEW", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | INDEX {
        res = new IR(kDropTypeAnyName, OP3("INDEX", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | FOREIGN TABLE {
        res = new IR(kDropTypeAnyName, OP3("FOREIGN TABLE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | COLLATION {
        res = new IR(kDropTypeAnyName, OP3("COLLATION", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CONVERSION_P {
        res = new IR(kDropTypeAnyName, OP3("CONVERSION", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | SCHEMA {
        res = new IR(kDropTypeAnyName, OP3("SCHEMA", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | STATISTICS {
        res = new IR(kDropTypeAnyName, OP3("STATISTICS", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | TEXT_P SEARCH PARSER {
        res = new IR(kDropTypeAnyName, OP3("TEXT SEARCH PARSER", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | TEXT_P SEARCH DICTIONARY {
        res = new IR(kDropTypeAnyName, OP3("TEXT SEARCH DICTIONARY", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | TEXT_P SEARCH TEMPLATE {
        res = new IR(kDropTypeAnyName, OP3("TEXT SEARCH TEMPLATE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | TEXT_P SEARCH CONFIGURATION {
        res = new IR(kDropTypeAnyName, OP3("TEXT SEARCH CONFIGURATION", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


drop_type_name:

    ACCESS METHOD {
        res = new IR(kDropTypeName, OP3("ACCESS METHOD", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | EVENT TRIGGER {
        res = new IR(kDropTypeName, OP3("EVENT TRIGGER", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | EXTENSION {
        res = new IR(kDropTypeName, OP3("EXTENSION", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | FOREIGN DATA_P WRAPPER {
        res = new IR(kDropTypeName, OP3("FOREIGN DATA WRAPPER", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | PUBLICATION {
        res = new IR(kDropTypeName, OP3("PUBLICATION", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | SERVER {
        res = new IR(kDropTypeName, OP3("SERVER", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


any_name_list:

    any_name {
        auto tmp1 = $1;
        res = new IR(kAnyNameList, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | any_name_list ',' any_name {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAnyNameList, OP3("", ",", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_drop_behavior:

    CASCADE {
        res = new IR(kOptDropBehavior, OP3("CASCADE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | RESTRICT {
        res = new IR(kOptDropBehavior, OP3("RESTRICT", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptDropBehavior, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


drop_type_name_on_any_name:

    POLICY {
        res = new IR(kDropTypeNameOnAnyName, OP3("POLICY", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | RULE {
        res = new IR(kDropTypeNameOnAnyName, OP3("RULE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | TRIGGER {
        res = new IR(kDropTypeNameOnAnyName, OP3("TRIGGER", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


type_name_list:

    Typename {
        auto tmp1 = $1;
        res = new IR(kTypeNameList, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | type_name_list ',' Typename {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTypeNameList, OP3("", ",", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


CreateFunctionStmt:

    CREATE_P OptTemp macro_alias qualified_name param_list AS TABLE SelectStmt {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateFunctionStmt_1, OP3("CREATE", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $4;
        res = new IR(kCreateFunctionStmt_2, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $5;
        res = new IR(kCreateFunctionStmt_3, OP3("", "", "AS TABLE"), res, tmp4);
        ir_vec.push_back(res); 
        auto tmp5 = $8;
        res = new IR(kCreateFunctionStmt, OP3("", "", ""), res, tmp5);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CREATE_P OptTemp macro_alias IF_P NOT EXISTS qualified_name param_list AS TABLE SelectStmt {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateFunctionStmt_4, OP3("CREATE", "", "IF NOT EXISTS"), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $7;
        res = new IR(kCreateFunctionStmt_5, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $8;
        res = new IR(kCreateFunctionStmt_6, OP3("", "", "AS TABLE"), res, tmp4);
        ir_vec.push_back(res); 
        auto tmp5 = $11;
        res = new IR(kCreateFunctionStmt, OP3("", "", ""), res, tmp5);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CREATE_P OR REPLACE OptTemp macro_alias qualified_name param_list AS TABLE SelectStmt {
        auto tmp1 = $4;
        auto tmp2 = $5;
        res = new IR(kCreateFunctionStmt_7, OP3("CREATE OR REPLACE", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $6;
        res = new IR(kCreateFunctionStmt_8, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $7;
        res = new IR(kCreateFunctionStmt_9, OP3("", "", "AS TABLE"), res, tmp4);
        ir_vec.push_back(res); 
        auto tmp5 = $10;
        res = new IR(kCreateFunctionStmt, OP3("", "", ""), res, tmp5);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CREATE_P OptTemp macro_alias qualified_name param_list AS a_expr {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateFunctionStmt_10, OP3("CREATE", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $4;
        res = new IR(kCreateFunctionStmt_11, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $5;
        res = new IR(kCreateFunctionStmt_12, OP3("", "", "AS"), res, tmp4);
        ir_vec.push_back(res); 
        auto tmp5 = $7;
        res = new IR(kCreateFunctionStmt, OP3("", "", ""), res, tmp5);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CREATE_P OptTemp macro_alias IF_P NOT EXISTS qualified_name param_list AS a_expr {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateFunctionStmt_13, OP3("CREATE", "", "IF NOT EXISTS"), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $7;
        res = new IR(kCreateFunctionStmt_14, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $8;
        res = new IR(kCreateFunctionStmt_15, OP3("", "", "AS"), res, tmp4);
        ir_vec.push_back(res); 
        auto tmp5 = $10;
        res = new IR(kCreateFunctionStmt, OP3("", "", ""), res, tmp5);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CREATE_P OR REPLACE OptTemp macro_alias qualified_name param_list AS a_expr {
        auto tmp1 = $4;
        auto tmp2 = $5;
        res = new IR(kCreateFunctionStmt_16, OP3("CREATE OR REPLACE", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $6;
        res = new IR(kCreateFunctionStmt_17, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $7;
        res = new IR(kCreateFunctionStmt_18, OP3("", "", "AS"), res, tmp4);
        ir_vec.push_back(res); 
        auto tmp5 = $9;
        res = new IR(kCreateFunctionStmt, OP3("", "", ""), res, tmp5);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


macro_alias:

    FUNCTION {
        res = new IR(kMacroAlias, OP3("FUNCTION", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | MACRO {
        res = new IR(kMacroAlias, OP3("MACRO", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


param_list:

    '(' ')' {
        res = new IR(kParamList, OP3("( )", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '(' func_arg_list ')' {
        auto tmp1 = $2;
        res = new IR(kParamList, OP3("(", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


UpdateStmt:

    opt_with_clause UPDATE relation_expr_opt_alias SET set_clause_list_opt_comma from_clause where_or_current_clause returning_clause {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kUpdateStmt_1, OP3("", "UPDATE", "SET"), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $5;
        res = new IR(kUpdateStmt_2, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $6;
        res = new IR(kUpdateStmt_3, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        auto tmp5 = $7;
        res = new IR(kUpdateStmt_4, OP3("", "", ""), res, tmp5);
        ir_vec.push_back(res); 
        auto tmp6 = $8;
        res = new IR(kUpdateStmt, OP3("", "", ""), res, tmp6);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


CopyStmt:

    COPY opt_binary qualified_name opt_column_list opt_oids copy_from opt_program copy_file_name copy_delimiter opt_with copy_options {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCopyStmt_1, OP3("COPY", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $4;
        res = new IR(kCopyStmt_2, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $5;
        res = new IR(kCopyStmt_3, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        auto tmp5 = $6;
        res = new IR(kCopyStmt_4, OP3("", "", ""), res, tmp5);
        ir_vec.push_back(res); 
        auto tmp6 = $7;
        res = new IR(kCopyStmt_5, OP3("", "", ""), res, tmp6);
        ir_vec.push_back(res); 
        auto tmp7 = $8;
        res = new IR(kCopyStmt_6, OP3("", "", ""), res, tmp7);
        ir_vec.push_back(res); 
        auto tmp8 = $9;
        res = new IR(kCopyStmt_7, OP3("", "", ""), res, tmp8);
        ir_vec.push_back(res); 
        auto tmp9 = $10;
        res = new IR(kCopyStmt_8, OP3("", "", ""), res, tmp9);
        ir_vec.push_back(res); 
        auto tmp10 = $11;
        res = new IR(kCopyStmt, OP3("", "", ""), res, tmp10);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | COPY '(' SelectStmt ')' TO opt_program copy_file_name opt_with copy_options {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kCopyStmt_9, OP3("COPY (", ") TO", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $7;
        res = new IR(kCopyStmt_10, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $8;
        res = new IR(kCopyStmt_11, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        auto tmp5 = $9;
        res = new IR(kCopyStmt, OP3("", "", ""), res, tmp5);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


copy_from:

    FROM {
        res = new IR(kCopyFrom, OP3("FROM", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | TO {
        res = new IR(kCopyFrom, OP3("TO", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


copy_delimiter:

    opt_using DELIMITERS Sconst {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kCopyDelimiter, OP3("", "DELIMITERS", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kCopyDelimiter, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


copy_generic_opt_arg_list:

    copy_generic_opt_arg_list_item {
        auto tmp1 = $1;
        res = new IR(kCopyGenericOptArgList, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | copy_generic_opt_arg_list ',' copy_generic_opt_arg_list_item {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kCopyGenericOptArgList, OP3("", ",", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_using:

    USING {
        res = new IR(kOptUsing, OP3("USING", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptUsing, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_as:

    AS {
        res = new IR(kOptAs, OP3("AS", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptAs, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_program:

    PROGRAM {
        res = new IR(kOptProgram, OP3("PROGRAM", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptProgram, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


copy_options:

    copy_opt_list {
        auto tmp1 = $1;
        res = new IR(kCopyOptions, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '(' copy_generic_opt_list ')' {
        auto tmp1 = $2;
        res = new IR(kCopyOptions, OP3("(", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


copy_generic_opt_arg:

    opt_boolean_or_string {
        auto tmp1 = $1;
        res = new IR(kCopyGenericOptArg, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | NumericOnly {
        auto tmp1 = $1;
        res = new IR(kCopyGenericOptArg, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '*' {
        res = new IR(kCopyGenericOptArg, OP3("*", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '(' copy_generic_opt_arg_list ')' {
        auto tmp1 = $2;
        res = new IR(kCopyGenericOptArg, OP3("(", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | struct_expr {
        auto tmp1 = $1;
        res = new IR(kCopyGenericOptArg, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kCopyGenericOptArg, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


copy_generic_opt_elem:

    ColLabel copy_generic_opt_arg {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCopyGenericOptElem, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_oids:

    WITH OIDS {
        res = new IR(kOptOids, OP3("WITH OIDS", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptOids, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


copy_opt_list:

    copy_opt_list copy_opt_item {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCopyOptList, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kCopyOptList, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_binary:

    BINARY {
        res = new IR(kOptBinary, OP3("BINARY", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptBinary, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


copy_opt_item:

    BINARY {
        res = new IR(kCopyOptItem, OP3("BINARY", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | OIDS {
        res = new IR(kCopyOptItem, OP3("OIDS", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | FREEZE {
        res = new IR(kCopyOptItem, OP3("FREEZE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | DELIMITER opt_as Sconst {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCopyOptItem, OP3("DELIMITER", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | NULL_P opt_as Sconst {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCopyOptItem, OP3("NULL", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CSV {
        res = new IR(kCopyOptItem, OP3("CSV", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | HEADER_P {
        res = new IR(kCopyOptItem, OP3("HEADER", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | QUOTE opt_as Sconst {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCopyOptItem, OP3("QUOTE", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ESCAPE opt_as Sconst {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCopyOptItem, OP3("ESCAPE", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | FORCE QUOTE columnList {
        auto tmp1 = $3;
        res = new IR(kCopyOptItem, OP3("FORCE QUOTE", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | FORCE QUOTE '*' {
        res = new IR(kCopyOptItem, OP3("FORCE QUOTE *", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | PARTITION BY columnList {
        auto tmp1 = $3;
        res = new IR(kCopyOptItem, OP3("PARTITION BY", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | PARTITION BY '*' {
        res = new IR(kCopyOptItem, OP3("PARTITION BY *", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | FORCE NOT NULL_P columnList {
        auto tmp1 = $4;
        res = new IR(kCopyOptItem, OP3("FORCE NOT NULL", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | FORCE NULL_P columnList {
        auto tmp1 = $3;
        res = new IR(kCopyOptItem, OP3("FORCE NULL", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ENCODING Sconst {
        auto tmp1 = $2;
        res = new IR(kCopyOptItem, OP3("ENCODING", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


copy_generic_opt_arg_list_item:

    opt_boolean_or_string {
        auto tmp1 = $1;
        res = new IR(kCopyGenericOptArgListItem, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


copy_file_name:

    Sconst {
        auto tmp1 = $1;
        res = new IR(kCopyFileName, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | STDIN {
        res = new IR(kCopyFileName, OP3("STDIN", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | STDOUT {
        res = new IR(kCopyFileName, OP3("STDOUT", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


copy_generic_opt_list:

    copy_generic_opt_elem {
        auto tmp1 = $1;
        res = new IR(kCopyGenericOptList, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | copy_generic_opt_list ',' copy_generic_opt_elem {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kCopyGenericOptList, OP3("", ",", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


SelectStmt:

    select_no_parens %prec UMINUS {
        auto tmp1 = $1;
        res = new IR(kSelectStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | select_with_parens %prec UMINUS {
        auto tmp1 = $1;
        res = new IR(kSelectStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


select_with_parens:

    '(' select_no_parens ')' {
        auto tmp1 = $2;
        res = new IR(kSelectWithParens, OP3("(", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '(' select_with_parens ')' {
        auto tmp1 = $2;
        res = new IR(kSelectWithParens, OP3("(", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


select_no_parens:

    simple_select {
        auto tmp1 = $1;
        res = new IR(kSelectNoParens, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | select_clause sort_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSelectNoParens, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | select_clause opt_sort_clause for_locking_clause opt_select_limit {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSelectNoParens_1, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $3;
        res = new IR(kSelectNoParens_2, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $4;
        res = new IR(kSelectNoParens, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | select_clause opt_sort_clause select_limit opt_for_locking_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSelectNoParens_3, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $3;
        res = new IR(kSelectNoParens_4, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $4;
        res = new IR(kSelectNoParens, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | with_clause select_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSelectNoParens, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | with_clause select_clause sort_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSelectNoParens_5, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $3;
        res = new IR(kSelectNoParens, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | with_clause select_clause opt_sort_clause for_locking_clause opt_select_limit {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSelectNoParens_6, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $3;
        res = new IR(kSelectNoParens_7, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $4;
        res = new IR(kSelectNoParens_8, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        auto tmp5 = $5;
        res = new IR(kSelectNoParens, OP3("", "", ""), res, tmp5);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | with_clause select_clause opt_sort_clause select_limit opt_for_locking_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSelectNoParens_9, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $3;
        res = new IR(kSelectNoParens_10, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $4;
        res = new IR(kSelectNoParens_11, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        auto tmp5 = $5;
        res = new IR(kSelectNoParens, OP3("", "", ""), res, tmp5);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


select_clause:

    simple_select {
        auto tmp1 = $1;
        res = new IR(kSelectClause, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | select_with_parens {
        auto tmp1 = $1;
        res = new IR(kSelectClause, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_select:

    SELECT opt_all_clause opt_target_list_opt_comma {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kOptSelect, OP3("SELECT", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptSelect, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


simple_select:

    SELECT opt_all_clause opt_target_list_opt_comma into_clause from_clause where_clause group_clause having_clause window_clause qualify_clause sample_clause {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSimpleSelect_1, OP3("SELECT", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $4;
        res = new IR(kSimpleSelect_2, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $5;
        res = new IR(kSimpleSelect_3, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        auto tmp5 = $6;
        res = new IR(kSimpleSelect_4, OP3("", "", ""), res, tmp5);
        ir_vec.push_back(res); 
        auto tmp6 = $7;
        res = new IR(kSimpleSelect_5, OP3("", "", ""), res, tmp6);
        ir_vec.push_back(res); 
        auto tmp7 = $8;
        res = new IR(kSimpleSelect_6, OP3("", "", ""), res, tmp7);
        ir_vec.push_back(res); 
        auto tmp8 = $9;
        res = new IR(kSimpleSelect_7, OP3("", "", ""), res, tmp8);
        ir_vec.push_back(res); 
        auto tmp9 = $10;
        res = new IR(kSimpleSelect_8, OP3("", "", ""), res, tmp9);
        ir_vec.push_back(res); 
        auto tmp10 = $11;
        res = new IR(kSimpleSelect, OP3("", "", ""), res, tmp10);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | SELECT distinct_clause target_list_opt_comma into_clause from_clause where_clause group_clause having_clause window_clause qualify_clause sample_clause {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSimpleSelect_9, OP3("SELECT", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $4;
        res = new IR(kSimpleSelect_10, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $5;
        res = new IR(kSimpleSelect_11, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        auto tmp5 = $6;
        res = new IR(kSimpleSelect_12, OP3("", "", ""), res, tmp5);
        ir_vec.push_back(res); 
        auto tmp6 = $7;
        res = new IR(kSimpleSelect_13, OP3("", "", ""), res, tmp6);
        ir_vec.push_back(res); 
        auto tmp7 = $8;
        res = new IR(kSimpleSelect_14, OP3("", "", ""), res, tmp7);
        ir_vec.push_back(res); 
        auto tmp8 = $9;
        res = new IR(kSimpleSelect_15, OP3("", "", ""), res, tmp8);
        ir_vec.push_back(res); 
        auto tmp9 = $10;
        res = new IR(kSimpleSelect_16, OP3("", "", ""), res, tmp9);
        ir_vec.push_back(res); 
        auto tmp10 = $11;
        res = new IR(kSimpleSelect, OP3("", "", ""), res, tmp10);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | FROM from_list opt_select into_clause where_clause group_clause having_clause window_clause qualify_clause sample_clause {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSimpleSelect_17, OP3("FROM", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $4;
        res = new IR(kSimpleSelect_18, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $5;
        res = new IR(kSimpleSelect_19, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        auto tmp5 = $6;
        res = new IR(kSimpleSelect_20, OP3("", "", ""), res, tmp5);
        ir_vec.push_back(res); 
        auto tmp6 = $7;
        res = new IR(kSimpleSelect_21, OP3("", "", ""), res, tmp6);
        ir_vec.push_back(res); 
        auto tmp7 = $8;
        res = new IR(kSimpleSelect_22, OP3("", "", ""), res, tmp7);
        ir_vec.push_back(res); 
        auto tmp8 = $9;
        res = new IR(kSimpleSelect_23, OP3("", "", ""), res, tmp8);
        ir_vec.push_back(res); 
        auto tmp9 = $10;
        res = new IR(kSimpleSelect, OP3("", "", ""), res, tmp9);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | FROM from_list SELECT distinct_clause target_list_opt_comma into_clause where_clause group_clause having_clause window_clause qualify_clause sample_clause {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kSimpleSelect_24, OP3("FROM", "SELECT", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $5;
        res = new IR(kSimpleSelect_25, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $6;
        res = new IR(kSimpleSelect_26, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        auto tmp5 = $7;
        res = new IR(kSimpleSelect_27, OP3("", "", ""), res, tmp5);
        ir_vec.push_back(res); 
        auto tmp6 = $8;
        res = new IR(kSimpleSelect_28, OP3("", "", ""), res, tmp6);
        ir_vec.push_back(res); 
        auto tmp7 = $9;
        res = new IR(kSimpleSelect_29, OP3("", "", ""), res, tmp7);
        ir_vec.push_back(res); 
        auto tmp8 = $10;
        res = new IR(kSimpleSelect_30, OP3("", "", ""), res, tmp8);
        ir_vec.push_back(res); 
        auto tmp9 = $11;
        res = new IR(kSimpleSelect_31, OP3("", "", ""), res, tmp9);
        ir_vec.push_back(res); 
        auto tmp10 = $12;
        res = new IR(kSimpleSelect, OP3("", "", ""), res, tmp10);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | values_clause_opt_comma {
        auto tmp1 = $1;
        res = new IR(kSimpleSelect, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | TABLE relation_expr {
        auto tmp1 = $2;
        res = new IR(kSimpleSelect, OP3("TABLE", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | select_clause UNION all_or_distinct by_name select_clause {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSimpleSelect_32, OP3("", "UNION", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $4;
        res = new IR(kSimpleSelect_33, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $5;
        res = new IR(kSimpleSelect, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | select_clause UNION all_or_distinct select_clause {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSimpleSelect_34, OP3("", "UNION", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $4;
        res = new IR(kSimpleSelect, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | select_clause INTERSECT all_or_distinct select_clause {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSimpleSelect_35, OP3("", "INTERSECT", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $4;
        res = new IR(kSimpleSelect, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | select_clause EXCEPT all_or_distinct select_clause {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSimpleSelect_36, OP3("", "EXCEPT", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $4;
        res = new IR(kSimpleSelect, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | pivot_keyword table_ref USING target_list_opt_comma {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSimpleSelect_37, OP3("", "", "USING"), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $4;
        res = new IR(kSimpleSelect, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | pivot_keyword table_ref USING target_list_opt_comma GROUP_P BY name_list_opt_comma_opt_bracket {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSimpleSelect_38, OP3("", "", "USING"), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $4;
        res = new IR(kSimpleSelect_39, OP3("", "", "GROUP BY"), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $7;
        res = new IR(kSimpleSelect, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | pivot_keyword table_ref GROUP_P BY name_list_opt_comma_opt_bracket {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSimpleSelect_40, OP3("", "", "GROUP BY"), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $5;
        res = new IR(kSimpleSelect, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | pivot_keyword table_ref ON pivot_column_list {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSimpleSelect_41, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = new IR(kStringLiteral, to_string($3), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp3);
        res = new IR(kSimpleSelect_42, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $4;
        res = new IR(kSimpleSelect, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | pivot_keyword table_ref ON pivot_column_list GROUP_P BY name_list_opt_comma_opt_bracket {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSimpleSelect_43, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = new IR(kStringLiteral, to_string($3), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp3);
        res = new IR(kSimpleSelect_44, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $4;
        res = new IR(kSimpleSelect_45, OP3("", "", "GROUP BY"), res, tmp4);
        ir_vec.push_back(res); 
        auto tmp5 = $7;
        res = new IR(kSimpleSelect, OP3("", "", ""), res, tmp5);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | pivot_keyword table_ref ON pivot_column_list USING target_list_opt_comma {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSimpleSelect_46, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = new IR(kStringLiteral, to_string($3), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp3);
        res = new IR(kSimpleSelect_47, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $4;
        res = new IR(kSimpleSelect_48, OP3("", "", "USING"), res, tmp4);
        ir_vec.push_back(res); 
        auto tmp5 = $6;
        res = new IR(kSimpleSelect, OP3("", "", ""), res, tmp5);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | pivot_keyword table_ref ON pivot_column_list USING target_list_opt_comma GROUP_P BY name_list_opt_comma_opt_bracket {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSimpleSelect_49, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = new IR(kStringLiteral, to_string($3), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp3);
        res = new IR(kSimpleSelect_50, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $4;
        res = new IR(kSimpleSelect_51, OP3("", "", "USING"), res, tmp4);
        ir_vec.push_back(res); 
        auto tmp5 = $6;
        res = new IR(kSimpleSelect_52, OP3("", "", "GROUP BY"), res, tmp5);
        ir_vec.push_back(res); 
        auto tmp6 = $9;
        res = new IR(kSimpleSelect, OP3("", "", ""), res, tmp6);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | unpivot_keyword table_ref ON target_list_opt_comma INTO NAME_P name value_or_values name_list_opt_comma_opt_bracket {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSimpleSelect_53, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = new IR(kStringLiteral, to_string($3), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp3);
        res = new IR(kSimpleSelect_54, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $4;
        res = new IR(kSimpleSelect_55, OP3("", "", "INTO NAME"), res, tmp4);
        ir_vec.push_back(res); 
        auto tmp5 = $7;
        res = new IR(kSimpleSelect_56, OP3("", "", ""), res, tmp5);
        ir_vec.push_back(res); 
        auto tmp6 = $8;
        res = new IR(kSimpleSelect_57, OP3("", "", ""), res, tmp6);
        ir_vec.push_back(res); 
        auto tmp7 = $9;
        res = new IR(kSimpleSelect, OP3("", "", ""), res, tmp7);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | unpivot_keyword table_ref ON target_list_opt_comma {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSimpleSelect_58, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = new IR(kStringLiteral, to_string($3), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp3);
        res = new IR(kSimpleSelect_59, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $4;
        res = new IR(kSimpleSelect, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


value_or_values:

    VALUE_P {
        res = new IR(kValueOrValues, OP3("VALUE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | VALUES {
        res = new IR(kValueOrValues, OP3("VALUES", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


pivot_keyword:

    PIVOT {
        res = new IR(kPivotKeyword, OP3("PIVOT", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | PIVOT_WIDER {
        res = new IR(kPivotKeyword, OP3("PIVOT_WIDER", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


unpivot_keyword:

    UNPIVOT {
        res = new IR(kUnpivotKeyword, OP3("UNPIVOT", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | PIVOT_LONGER {
        res = new IR(kUnpivotKeyword, OP3("PIVOT_LONGER", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


pivot_column_entry:

    b_expr {
        auto tmp1 = $1;
        res = new IR(kPivotColumnEntry, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | b_expr IN_P '(' select_no_parens ')' {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kPivotColumnEntry, OP3("", "IN (", ")"), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | single_pivot_value {
        auto tmp1 = $1;
        res = new IR(kPivotColumnEntry, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


pivot_column_list_internal:

    pivot_column_entry {
        auto tmp1 = $1;
        res = new IR(kPivotColumnListInternal, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | pivot_column_list_internal ',' pivot_column_entry {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kPivotColumnListInternal, OP3("", ",", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


pivot_column_list:

    pivot_column_list_internal {
        auto tmp1 = $1;
        res = new IR(kPivotColumnList, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | pivot_column_list_internal ',' {
        auto tmp1 = $1;
        res = new IR(kPivotColumnList, OP3("", ",", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


with_clause:

    WITH cte_list {
        auto tmp1 = $2;
        res = new IR(kWithClause, OP3("WITH", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | WITH_LA cte_list {
        auto tmp1 = $2;
        res = new IR(kWithClause, OP3("WITH", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | WITH RECURSIVE cte_list {
        auto tmp1 = $3;
        res = new IR(kWithClause, OP3("WITH RECURSIVE", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


cte_list:

    common_table_expr {
        auto tmp1 = $1;
        res = new IR(kCteList, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | cte_list ',' common_table_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kCteList, OP3("", ",", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


common_table_expr:

    name opt_name_list AS opt_materialized '(' PreparableStmt ')' {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCommonTableExpr_1, OP3("", "", "AS"), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $4;
        res = new IR(kCommonTableExpr_2, OP3("", "", "("), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $6;
        res = new IR(kCommonTableExpr, OP3("", "", ")"), res, tmp4);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_materialized:

    MATERIALIZED {
        res = new IR(kOptMaterialized, OP3("MATERIALIZED", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | NOT MATERIALIZED {
        res = new IR(kOptMaterialized, OP3("NOT MATERIALIZED", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptMaterialized, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


into_clause:

    INTO OptTempTableName {
        auto tmp1 = $2;
        res = new IR(kIntoClause, OP3("INTO", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kIntoClause, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


OptTempTableName:

    TEMPORARY opt_table qualified_name {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kOptTempTableName, OP3("TEMPORARY", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | TEMP opt_table qualified_name {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kOptTempTableName, OP3("TEMP", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | LOCAL TEMPORARY opt_table qualified_name {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kOptTempTableName, OP3("LOCAL TEMPORARY", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | LOCAL TEMP opt_table qualified_name {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kOptTempTableName, OP3("LOCAL TEMP", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | GLOBAL TEMPORARY opt_table qualified_name {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kOptTempTableName, OP3("GLOBAL TEMPORARY", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | GLOBAL TEMP opt_table qualified_name {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kOptTempTableName, OP3("GLOBAL TEMP", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | UNLOGGED opt_table qualified_name {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kOptTempTableName, OP3("UNLOGGED", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | TABLE qualified_name {
        auto tmp1 = $2;
        res = new IR(kOptTempTableName, OP3("TABLE", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | qualified_name {
        auto tmp1 = $1;
        res = new IR(kOptTempTableName, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_table:

    TABLE {
        res = new IR(kOptTable, OP3("TABLE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptTable, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


all_or_distinct:

    ALL {
        res = new IR(kAllOrDistinct, OP3("ALL", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | DISTINCT {
        res = new IR(kAllOrDistinct, OP3("DISTINCT", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kAllOrDistinct, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


by_name:

    BY NAME_P {
        res = new IR(kByName, OP3("BY NAME", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


distinct_clause:

    DISTINCT {
        res = new IR(kDistinctClause, OP3("DISTINCT", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | DISTINCT ON '(' expr_list_opt_comma ')' {
        auto tmp1 = new IR(kStringLiteral, to_string($2), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        auto tmp2 = $4;
        res = new IR(kDistinctClause, OP3("DISTINCT", "(", ")"), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_all_clause:

    ALL {
        res = new IR(kOptAllClause, OP3("ALL", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptAllClause, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_ignore_nulls:

    IGNORE_P NULLS_P {
        res = new IR(kOptIgnoreNulls, OP3("IGNORE NULLS", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | RESPECT_P NULLS_P {
        res = new IR(kOptIgnoreNulls, OP3("RESPECT NULLS", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptIgnoreNulls, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_sort_clause:

    sort_clause {
        auto tmp1 = $1;
        res = new IR(kOptSortClause, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptSortClause, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


sort_clause:

    ORDER BY sortby_list {
        auto tmp1 = $3;
        res = new IR(kSortClause, OP3("ORDER BY", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ORDER BY ALL opt_asc_desc opt_nulls_order {
        auto tmp1 = $4;
        auto tmp2 = $5;
        res = new IR(kSortClause, OP3("ORDER BY ALL", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


sortby_list:

    sortby {
        auto tmp1 = $1;
        res = new IR(kSortbyList, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | sortby_list ',' sortby {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSortbyList, OP3("", ",", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


sortby:

    a_expr USING qual_all_Op opt_nulls_order {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSortby_1, OP3("", "USING", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $4;
        res = new IR(kSortby, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr opt_asc_desc opt_nulls_order {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSortby_2, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $3;
        res = new IR(kSortby, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_asc_desc:

    ASC_P {
        res = new IR(kOptAscDesc, OP3("ASC", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | DESC_P {
        res = new IR(kOptAscDesc, OP3("DESC", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptAscDesc, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_nulls_order:

    NULLS_LA FIRST_P {
        res = new IR(kOptNullsOrder, OP3("NULLS FIRST", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | NULLS_LA LAST_P {
        res = new IR(kOptNullsOrder, OP3("NULLS LAST", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptNullsOrder, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


select_limit:

    limit_clause offset_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSelectLimit, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | offset_clause limit_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSelectLimit, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | limit_clause {
        auto tmp1 = $1;
        res = new IR(kSelectLimit, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | offset_clause {
        auto tmp1 = $1;
        res = new IR(kSelectLimit, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_select_limit:

    select_limit {
        auto tmp1 = $1;
        res = new IR(kOptSelectLimit, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptSelectLimit, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


limit_clause:

    LIMIT select_limit_value {
        auto tmp1 = $2;
        res = new IR(kLimitClause, OP3("LIMIT", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | LIMIT select_limit_value ',' select_offset_value {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kLimitClause, OP3("LIMIT", ",", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | FETCH first_or_next select_fetch_first_value row_or_rows ONLY {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kLimitClause_1, OP3("FETCH", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $4;
        res = new IR(kLimitClause, OP3("", "", "ONLY"), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | FETCH first_or_next row_or_rows ONLY {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kLimitClause, OP3("FETCH", "", "ONLY"), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


offset_clause:

    OFFSET select_offset_value {
        auto tmp1 = $2;
        res = new IR(kOffsetClause, OP3("OFFSET", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | OFFSET select_fetch_first_value row_or_rows {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kOffsetClause, OP3("OFFSET", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


sample_count:

    FCONST '%' {
        auto tmp1 = new IR(kFloatLiteral, to_string($1), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        res = new IR(kSampleCount, OP3("", "%", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ICONST '%' {
        auto tmp1 = new IR(kIntegerLiteral, to_string($1), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        res = new IR(kSampleCount, OP3("", "%", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | FCONST PERCENT {
        auto tmp1 = new IR(kFloatLiteral, to_string($1), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        res = new IR(kSampleCount, OP3("", "PERCENT", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ICONST PERCENT {
        auto tmp1 = new IR(kIntegerLiteral, to_string($1), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        res = new IR(kSampleCount, OP3("", "PERCENT", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ICONST {
        auto tmp1 = new IR(kIntegerLiteral, to_string($1), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        res = new IR(kSampleCount, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ICONST ROWS {
        auto tmp1 = new IR(kIntegerLiteral, to_string($1), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        res = new IR(kSampleCount, OP3("", "ROWS", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


sample_clause:

    USING SAMPLE tablesample_entry {
        auto tmp1 = $3;
        res = new IR(kSampleClause, OP3("USING SAMPLE", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kSampleClause, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_sample_func:

    ColId {
        auto tmp1 = $1;
        res = new IR(kOptSampleFunc, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptSampleFunc, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


tablesample_entry:

    opt_sample_func '(' sample_count ')' opt_repeatable_clause {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTablesampleEntry_1, OP3("", "(", ")"), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $5;
        res = new IR(kTablesampleEntry, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | sample_count {
        auto tmp1 = $1;
        res = new IR(kTablesampleEntry, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | sample_count '(' ColId ')' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTablesampleEntry, OP3("", "(", ")"), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | sample_count '(' ColId ',' ICONST ')' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTablesampleEntry_2, OP3("", "(", ","), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = new IR(kIntegerLiteral, to_string($5), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp3);
        res = new IR(kTablesampleEntry, OP3("", "", ")"), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


tablesample_clause:

    TABLESAMPLE tablesample_entry {
        auto tmp1 = $2;
        res = new IR(kTablesampleClause, OP3("TABLESAMPLE", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_tablesample_clause:

    tablesample_clause {
        auto tmp1 = $1;
        res = new IR(kOptTablesampleClause, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptTablesampleClause, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_repeatable_clause:

    REPEATABLE '(' ICONST ')' {
        auto tmp1 = new IR(kIntegerLiteral, to_string($3), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        res = new IR(kOptRepeatableClause, OP3("REPEATABLE (", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptRepeatableClause, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


select_limit_value:

    a_expr {
        auto tmp1 = $1;
        res = new IR(kSelectLimitValue, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ALL {
        res = new IR(kSelectLimitValue, OP3("ALL", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr '%' {
        auto tmp1 = $1;
        res = new IR(kSelectLimitValue, OP3("", "%", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | FCONST PERCENT {
        auto tmp1 = new IR(kFloatLiteral, to_string($1), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        res = new IR(kSelectLimitValue, OP3("", "PERCENT", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ICONST PERCENT {
        auto tmp1 = new IR(kIntegerLiteral, to_string($1), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        res = new IR(kSelectLimitValue, OP3("", "PERCENT", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


select_offset_value:

    a_expr {
        auto tmp1 = $1;
        res = new IR(kSelectOffsetValue, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


select_fetch_first_value:

    c_expr {
        auto tmp1 = $1;
        res = new IR(kSelectFetchFirstValue, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '+' I_or_F_const {
        auto tmp1 = $2;
        res = new IR(kSelectFetchFirstValue, OP3("+", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '-' I_or_F_const {
        auto tmp1 = $2;
        res = new IR(kSelectFetchFirstValue, OP3("-", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


I_or_F_const:

    Iconst {
        auto tmp1 = $1;
        res = new IR(kIOrFConst, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | FCONST {
        auto tmp1 = new IR(kFloatLiteral, to_string($1), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        res = new IR(kIOrFConst, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


row_or_rows:

    ROW {
        res = new IR(kRowOrRows, OP3("ROW", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ROWS {
        res = new IR(kRowOrRows, OP3("ROWS", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


first_or_next:

    FIRST_P {
        res = new IR(kFirstOrNext, OP3("FIRST", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | NEXT {
        res = new IR(kFirstOrNext, OP3("NEXT", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


group_clause:

    GROUP_P BY group_by_list_opt_comma {
        auto tmp1 = $3;
        res = new IR(kGroupClause, OP3("GROUP BY", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | GROUP_P BY ALL {
        res = new IR(kGroupClause, OP3("GROUP BY ALL", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kGroupClause, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


group_by_list:

    group_by_item {
        auto tmp1 = $1;
        res = new IR(kGroupByList, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | group_by_list ',' group_by_item {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kGroupByList, OP3("", ",", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


group_by_list_opt_comma:

    group_by_list {
        auto tmp1 = $1;
        res = new IR(kGroupByListOptComma, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | group_by_list ',' {
        auto tmp1 = $1;
        res = new IR(kGroupByListOptComma, OP3("", ",", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


group_by_item:

    a_expr {
        auto tmp1 = $1;
        res = new IR(kGroupByItem, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | empty_grouping_set {
        auto tmp1 = $1;
        res = new IR(kGroupByItem, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | cube_clause {
        auto tmp1 = $1;
        res = new IR(kGroupByItem, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | rollup_clause {
        auto tmp1 = $1;
        res = new IR(kGroupByItem, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | grouping_sets_clause {
        auto tmp1 = $1;
        res = new IR(kGroupByItem, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


empty_grouping_set:

    '(' ')' {
        res = new IR(kEmptyGroupingSet, OP3("( )", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


rollup_clause:

    ROLLUP '(' expr_list_opt_comma ')' {
        auto tmp1 = $3;
        res = new IR(kRollupClause, OP3("ROLLUP (", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


cube_clause:

    CUBE '(' expr_list_opt_comma ')' {
        auto tmp1 = $3;
        res = new IR(kCubeClause, OP3("CUBE (", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


grouping_sets_clause:

    GROUPING SETS '(' group_by_list_opt_comma ')' {
        auto tmp1 = $4;
        res = new IR(kGroupingSetsClause, OP3("GROUPING SETS (", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


grouping_or_grouping_id:

    GROUPING {
        res = new IR(kGroupingOrGroupingId, OP3("GROUPING", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | GROUPING_ID {
        res = new IR(kGroupingOrGroupingId, OP3("GROUPING_ID", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


having_clause:

    HAVING a_expr {
        auto tmp1 = $2;
        res = new IR(kHavingClause, OP3("HAVING", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kHavingClause, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


qualify_clause:

    QUALIFY a_expr {
        auto tmp1 = $2;
        res = new IR(kQualifyClause, OP3("QUALIFY", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kQualifyClause, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


for_locking_clause:

    for_locking_items {
        auto tmp1 = $1;
        res = new IR(kForLockingClause, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | FOR READ_P ONLY {
        res = new IR(kForLockingClause, OP3("FOR READ ONLY", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_for_locking_clause:

    for_locking_clause {
        auto tmp1 = $1;
        res = new IR(kOptForLockingClause, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptForLockingClause, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


for_locking_items:

    for_locking_item {
        auto tmp1 = $1;
        res = new IR(kForLockingItems, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | for_locking_items for_locking_item {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kForLockingItems, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


for_locking_item:

    for_locking_strength locked_rels_list opt_nowait_or_skip {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kForLockingItem_1, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $3;
        res = new IR(kForLockingItem, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


for_locking_strength:

    FOR UPDATE {
        res = new IR(kForLockingStrength, OP3("FOR UPDATE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | FOR NO KEY UPDATE {
        res = new IR(kForLockingStrength, OP3("FOR NO KEY UPDATE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | FOR SHARE {
        res = new IR(kForLockingStrength, OP3("FOR SHARE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | FOR KEY SHARE {
        res = new IR(kForLockingStrength, OP3("FOR KEY SHARE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


locked_rels_list:

    OF qualified_name_list {
        auto tmp1 = $2;
        res = new IR(kLockedRelsList, OP3("OF", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kLockedRelsList, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_nowait_or_skip:

    NOWAIT {
        res = new IR(kOptNowaitOrSkip, OP3("NOWAIT", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | SKIP LOCKED {
        res = new IR(kOptNowaitOrSkip, OP3("SKIP LOCKED", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptNowaitOrSkip, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


values_clause:

    VALUES '(' expr_list_opt_comma ')' {
        auto tmp1 = $3;
        res = new IR(kValuesClause, OP3("VALUES (", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | values_clause ',' '(' expr_list_opt_comma ')' {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kValuesClause, OP3("", ", (", ")"), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


values_clause_opt_comma:

    values_clause {
        auto tmp1 = $1;
        res = new IR(kValuesClauseOptComma, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | values_clause ',' {
        auto tmp1 = $1;
        res = new IR(kValuesClauseOptComma, OP3("", ",", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


from_clause:

    FROM from_list_opt_comma {
        auto tmp1 = $2;
        res = new IR(kFromClause, OP3("FROM", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kFromClause, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


from_list:

    table_ref {
        auto tmp1 = $1;
        res = new IR(kFromList, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | from_list ',' table_ref {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kFromList, OP3("", ",", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


from_list_opt_comma:

    from_list {
        auto tmp1 = $1;
        res = new IR(kFromListOptComma, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | from_list ',' {
        auto tmp1 = $1;
        res = new IR(kFromListOptComma, OP3("", ",", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


table_ref:

    relation_expr opt_alias_clause opt_tablesample_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kTableRef_1, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $3;
        res = new IR(kTableRef, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | func_table func_alias_clause opt_tablesample_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kTableRef_2, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $3;
        res = new IR(kTableRef, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | values_clause_opt_comma alias_clause opt_tablesample_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kTableRef_3, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $3;
        res = new IR(kTableRef, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | LATERAL_P func_table func_alias_clause {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kTableRef, OP3("LATERAL", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | select_with_parens opt_alias_clause opt_tablesample_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kTableRef_4, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $3;
        res = new IR(kTableRef, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | LATERAL_P select_with_parens opt_alias_clause {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kTableRef, OP3("LATERAL", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | joined_table {
        auto tmp1 = $1;
        res = new IR(kTableRef, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '(' joined_table ')' alias_clause {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kTableRef, OP3("(", ")", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | table_ref PIVOT '(' target_list_opt_comma FOR pivot_value_list opt_pivot_group_by ')' opt_alias_clause {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kTableRef_5, OP3("", "PIVOT (", "FOR"), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $6;
        res = new IR(kTableRef_6, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $7;
        res = new IR(kTableRef_7, OP3("", "", ")"), res, tmp4);
        ir_vec.push_back(res); 
        auto tmp5 = $9;
        res = new IR(kTableRef, OP3("", "", ""), res, tmp5);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | table_ref UNPIVOT opt_include_nulls '(' unpivot_header FOR unpivot_value_list ')' opt_alias_clause {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTableRef_8, OP3("", "UNPIVOT", "("), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $5;
        res = new IR(kTableRef_9, OP3("", "", "FOR"), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $7;
        res = new IR(kTableRef_10, OP3("", "", ")"), res, tmp4);
        ir_vec.push_back(res); 
        auto tmp5 = $9;
        res = new IR(kTableRef, OP3("", "", ""), res, tmp5);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_pivot_group_by:

    GROUP_P BY name_list_opt_comma {
        auto tmp1 = $3;
        res = new IR(kOptPivotGroupBy, OP3("GROUP BY", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptPivotGroupBy, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_include_nulls:

    INCLUDE_P NULLS_P {
        res = new IR(kOptIncludeNulls, OP3("INCLUDE NULLS", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | EXCLUDE NULLS_P {
        res = new IR(kOptIncludeNulls, OP3("EXCLUDE NULLS", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptIncludeNulls, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


single_pivot_value:

    b_expr IN_P '(' target_list_opt_comma ')' {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kSinglePivotValue, OP3("", "IN (", ")"), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | b_expr IN_P ColIdOrString {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSinglePivotValue, OP3("", "IN", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


pivot_header:

    d_expr {
        auto tmp1 = $1;
        res = new IR(kPivotHeader, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '(' c_expr_list_opt_comma ')' {
        auto tmp1 = $2;
        res = new IR(kPivotHeader, OP3("(", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


pivot_value:

    pivot_header IN_P '(' target_list_opt_comma ')' {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kPivotValue, OP3("", "IN (", ")"), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | pivot_header IN_P ColIdOrString {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kPivotValue, OP3("", "IN", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


pivot_value_list:

    pivot_value {
        auto tmp1 = $1;
        res = new IR(kPivotValueList, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | pivot_value_list pivot_value {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kPivotValueList, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


unpivot_header:

    ColIdOrString {
        auto tmp1 = $1;
        res = new IR(kUnpivotHeader, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '(' name_list_opt_comma ')' {
        auto tmp1 = $2;
        res = new IR(kUnpivotHeader, OP3("(", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


unpivot_value:

    unpivot_header IN_P '(' target_list_opt_comma ')' {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kUnpivotValue, OP3("", "IN (", ")"), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


unpivot_value_list:

    unpivot_value {
        auto tmp1 = $1;
        res = new IR(kUnpivotValueList, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | unpivot_value_list unpivot_value {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUnpivotValueList, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


joined_table:

    '(' joined_table ')' {
        auto tmp1 = $2;
        res = new IR(kJoinedTable, OP3("(", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | table_ref CROSS JOIN table_ref {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kJoinedTable, OP3("", "CROSS JOIN", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | table_ref join_type JOIN table_ref join_qual {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kJoinedTable_1, OP3("", "", "JOIN"), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $4;
        res = new IR(kJoinedTable_2, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $5;
        res = new IR(kJoinedTable, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | table_ref JOIN table_ref join_qual {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kJoinedTable_3, OP3("", "JOIN", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $4;
        res = new IR(kJoinedTable, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | table_ref NATURAL join_type JOIN table_ref {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kJoinedTable_4, OP3("", "NATURAL", "JOIN"), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $5;
        res = new IR(kJoinedTable, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | table_ref NATURAL JOIN table_ref {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kJoinedTable, OP3("", "NATURAL JOIN", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | table_ref ASOF join_type JOIN table_ref join_qual {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kJoinedTable_5, OP3("", "ASOF", "JOIN"), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $5;
        res = new IR(kJoinedTable_6, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $6;
        res = new IR(kJoinedTable, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | table_ref ASOF JOIN table_ref join_qual {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kJoinedTable_7, OP3("", "ASOF JOIN", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $5;
        res = new IR(kJoinedTable, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | table_ref POSITIONAL JOIN table_ref {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kJoinedTable, OP3("", "POSITIONAL JOIN", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | table_ref ANTI JOIN table_ref join_qual {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kJoinedTable_8, OP3("", "ANTI JOIN", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $5;
        res = new IR(kJoinedTable, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | table_ref SEMI JOIN table_ref join_qual {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kJoinedTable_9, OP3("", "SEMI JOIN", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $5;
        res = new IR(kJoinedTable, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


alias_clause:

    AS ColIdOrString '(' name_list_opt_comma ')' {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kAliasClause, OP3("AS", "(", ")"), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | AS ColIdOrString {
        auto tmp1 = $2;
        res = new IR(kAliasClause, OP3("AS", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ColId '(' name_list_opt_comma ')' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAliasClause, OP3("", "(", ")"), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ColId {
        auto tmp1 = $1;
        res = new IR(kAliasClause, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_alias_clause:

    alias_clause {
        auto tmp1 = $1;
        res = new IR(kOptAliasClause, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptAliasClause, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


func_alias_clause:

    alias_clause {
        auto tmp1 = $1;
        res = new IR(kFuncAliasClause, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | AS '(' TableFuncElementList ')' {
        auto tmp1 = $3;
        res = new IR(kFuncAliasClause, OP3("AS (", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | AS ColIdOrString '(' TableFuncElementList ')' {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kFuncAliasClause, OP3("AS", "(", ")"), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ColId '(' TableFuncElementList ')' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kFuncAliasClause, OP3("", "(", ")"), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kFuncAliasClause, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


join_type:

    FULL join_outer {
        auto tmp1 = $2;
        res = new IR(kJoinType, OP3("FULL", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | LEFT join_outer {
        auto tmp1 = $2;
        res = new IR(kJoinType, OP3("LEFT", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | RIGHT join_outer {
        auto tmp1 = $2;
        res = new IR(kJoinType, OP3("RIGHT", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | SEMI {
        res = new IR(kJoinType, OP3("SEMI", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ANTI {
        res = new IR(kJoinType, OP3("ANTI", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | INNER_P {
        res = new IR(kJoinType, OP3("INNER", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


join_outer:

    OUTER_P {
        res = new IR(kJoinOuter, OP3("OUTER", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kJoinOuter, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


join_qual:

    USING '(' name_list_opt_comma ')' {
        auto tmp1 = $3;
        res = new IR(kJoinQual, OP3("USING (", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ON a_expr {
        auto tmp1 = new IR(kStringLiteral, to_string($1), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        auto tmp2 = $2;
        res = new IR(kJoinQual, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


relation_expr:

    qualified_name {
        auto tmp1 = $1;
        res = new IR(kRelationExpr, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | qualified_name '*' {
        auto tmp1 = $1;
        res = new IR(kRelationExpr, OP3("", "*", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ONLY qualified_name {
        auto tmp1 = $2;
        res = new IR(kRelationExpr, OP3("ONLY", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ONLY '(' qualified_name ')' {
        auto tmp1 = $3;
        res = new IR(kRelationExpr, OP3("ONLY (", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


func_table:

    func_expr_windowless opt_ordinality {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFuncTable, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ROWS FROM '(' rowsfrom_list ')' opt_ordinality {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kFuncTable, OP3("ROWS FROM (", ")", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


rowsfrom_item:

    func_expr_windowless opt_col_def_list {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kRowsfromItem, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


rowsfrom_list:

    rowsfrom_item {
        auto tmp1 = $1;
        res = new IR(kRowsfromList, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | rowsfrom_list ',' rowsfrom_item {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kRowsfromList, OP3("", ",", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_col_def_list:

    AS '(' TableFuncElementList ')' {
        auto tmp1 = $3;
        res = new IR(kOptColDefList, OP3("AS (", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptColDefList, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_ordinality:

    WITH_LA ORDINALITY {
        res = new IR(kOptOrdinality, OP3("WITH ORDINALITY", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptOrdinality, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


where_clause:

    WHERE a_expr {
        auto tmp1 = $2;
        res = new IR(kWhereClause, OP3("WHERE", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kWhereClause, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


TableFuncElementList:

    TableFuncElement {
        auto tmp1 = $1;
        res = new IR(kTableFuncElementList, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | TableFuncElementList ',' TableFuncElement {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTableFuncElementList, OP3("", ",", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


TableFuncElement:

    ColIdOrString Typename opt_collate_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kTableFuncElement_1, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $3;
        res = new IR(kTableFuncElement, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_collate_clause:

    COLLATE any_name {
        auto tmp1 = $2;
        res = new IR(kOptCollateClause, OP3("COLLATE", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptCollateClause, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


colid_type_list:

    ColId Typename {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kColidTypeList, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | colid_type_list ',' ColId Typename {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kColidTypeList_1, OP3("", ",", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $4;
        res = new IR(kColidTypeList, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


RowOrStruct:

    ROW {
        res = new IR(kRowOrStruct, OP3("ROW", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | STRUCT {
        res = new IR(kRowOrStruct, OP3("STRUCT", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_Typename:

    Typename {
        auto tmp1 = $1;
        res = new IR(kOptTypename, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptTypename, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


Typename:

    SimpleTypename opt_array_bounds {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kTypename, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | SETOF SimpleTypename opt_array_bounds {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kTypename, OP3("SETOF", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | SimpleTypename ARRAY '[' Iconst ']' {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kTypename, OP3("", "ARRAY [", "]"), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | SETOF SimpleTypename ARRAY '[' Iconst ']' {
        auto tmp1 = $2;
        auto tmp2 = $5;
        res = new IR(kTypename, OP3("SETOF", "ARRAY [", "]"), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | SimpleTypename ARRAY {
        auto tmp1 = $1;
        res = new IR(kTypename, OP3("", "ARRAY", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | SETOF SimpleTypename ARRAY {
        auto tmp1 = $2;
        res = new IR(kTypename, OP3("SETOF", "ARRAY", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | RowOrStruct '(' colid_type_list ')' opt_array_bounds {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTypename_1, OP3("", "(", ")"), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $5;
        res = new IR(kTypename, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | MAP '(' type_list ')' opt_array_bounds {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kTypename, OP3("MAP (", ")", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | UNION '(' colid_type_list ')' opt_array_bounds {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kTypename, OP3("UNION (", ")", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_array_bounds:

    opt_array_bounds '[' ']' {
        auto tmp1 = $1;
        res = new IR(kOptArrayBounds, OP3("", "[ ]", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | opt_array_bounds '[' Iconst ']' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kOptArrayBounds, OP3("", "[", "]"), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptArrayBounds, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


SimpleTypename:

    GenericType {
        auto tmp1 = $1;
        res = new IR(kSimpleTypename, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | Numeric {
        auto tmp1 = $1;
        res = new IR(kSimpleTypename, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | Bit {
        auto tmp1 = $1;
        res = new IR(kSimpleTypename, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | Character {
        auto tmp1 = $1;
        res = new IR(kSimpleTypename, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ConstDatetime {
        auto tmp1 = $1;
        res = new IR(kSimpleTypename, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ConstInterval opt_interval {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSimpleTypename, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ConstInterval '(' Iconst ')' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSimpleTypename, OP3("", "(", ")"), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


ConstTypename:

    Numeric {
        auto tmp1 = $1;
        res = new IR(kConstTypename, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ConstBit {
        auto tmp1 = $1;
        res = new IR(kConstTypename, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ConstCharacter {
        auto tmp1 = $1;
        res = new IR(kConstTypename, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ConstDatetime {
        auto tmp1 = $1;
        res = new IR(kConstTypename, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


GenericType:

    type_name_token opt_type_modifiers {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kGenericType, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_type_modifiers:

    '(' opt_expr_list_opt_comma ')' {
        auto tmp1 = $2;
        res = new IR(kOptTypeModifiers, OP3("(", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptTypeModifiers, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


Numeric:

    INT_P {
        res = new IR(kNumeric, OP3("INT", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | INTEGER {
        res = new IR(kNumeric, OP3("INTEGER", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | SMALLINT {
        res = new IR(kNumeric, OP3("SMALLINT", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | BIGINT {
        res = new IR(kNumeric, OP3("BIGINT", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | REAL {
        res = new IR(kNumeric, OP3("REAL", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | FLOAT_P opt_float {
        auto tmp1 = $2;
        res = new IR(kNumeric, OP3("FLOAT", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | DOUBLE_P PRECISION {
        res = new IR(kNumeric, OP3("DOUBLE PRECISION", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | DECIMAL_P opt_type_modifiers {
        auto tmp1 = $2;
        res = new IR(kNumeric, OP3("DECIMAL", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | DEC opt_type_modifiers {
        auto tmp1 = $2;
        res = new IR(kNumeric, OP3("DEC", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | NUMERIC opt_type_modifiers {
        auto tmp1 = $2;
        res = new IR(kNumeric, OP3("NUMERIC", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | BOOLEAN_P {
        res = new IR(kNumeric, OP3("BOOLEAN", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_float:

    '(' Iconst ')' {
        auto tmp1 = $2;
        res = new IR(kOptFloat, OP3("(", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptFloat, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


Bit:

    BitWithLength {
        auto tmp1 = $1;
        res = new IR(kBit, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | BitWithoutLength {
        auto tmp1 = $1;
        res = new IR(kBit, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


ConstBit:

    BitWithLength {
        auto tmp1 = $1;
        res = new IR(kConstBit, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | BitWithoutLength {
        auto tmp1 = $1;
        res = new IR(kConstBit, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


BitWithLength:

    BIT opt_varying '(' expr_list_opt_comma ')' {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kBitWithLength, OP3("BIT", "(", ")"), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


BitWithoutLength:

    BIT opt_varying {
        auto tmp1 = $2;
        res = new IR(kBitWithoutLength, OP3("BIT", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


Character:

    CharacterWithLength {
        auto tmp1 = $1;
        res = new IR(kCharacter, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CharacterWithoutLength {
        auto tmp1 = $1;
        res = new IR(kCharacter, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


ConstCharacter:

    CharacterWithLength {
        auto tmp1 = $1;
        res = new IR(kConstCharacter, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CharacterWithoutLength {
        auto tmp1 = $1;
        res = new IR(kConstCharacter, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


CharacterWithLength:

    character '(' Iconst ')' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kCharacterWithLength, OP3("", "(", ")"), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


CharacterWithoutLength:

    character {
        auto tmp1 = $1;
        res = new IR(kCharacterWithoutLength, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


character:

    CHARACTER opt_varying {
        auto tmp1 = $2;
        res = new IR(kCharacter, OP3("CHARACTER", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CHAR_P opt_varying {
        auto tmp1 = $2;
        res = new IR(kCharacter, OP3("CHAR", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | VARCHAR {
        res = new IR(kCharacter, OP3("VARCHAR", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | NATIONAL CHARACTER opt_varying {
        auto tmp1 = $3;
        res = new IR(kCharacter, OP3("NATIONAL CHARACTER", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | NATIONAL CHAR_P opt_varying {
        auto tmp1 = $3;
        res = new IR(kCharacter, OP3("NATIONAL CHAR", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | NCHAR opt_varying {
        auto tmp1 = $2;
        res = new IR(kCharacter, OP3("NCHAR", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_varying:

    VARYING {
        res = new IR(kOptVarying, OP3("VARYING", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptVarying, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


ConstDatetime:

    TIMESTAMP '(' Iconst ')' opt_timezone {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kConstDatetime, OP3("TIMESTAMP (", ")", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | TIMESTAMP opt_timezone {
        auto tmp1 = $2;
        res = new IR(kConstDatetime, OP3("TIMESTAMP", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | TIME '(' Iconst ')' opt_timezone {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kConstDatetime, OP3("TIME (", ")", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | TIME opt_timezone {
        auto tmp1 = $2;
        res = new IR(kConstDatetime, OP3("TIME", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


ConstInterval:

    INTERVAL {
        res = new IR(kConstInterval, OP3("INTERVAL", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_timezone:

    WITH_LA TIME ZONE {
        res = new IR(kOptTimezone, OP3("WITH TIME ZONE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | WITHOUT TIME ZONE {
        res = new IR(kOptTimezone, OP3("WITHOUT TIME ZONE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptTimezone, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


year_keyword:

    YEAR_P {
        res = new IR(kYearKeyword, OP3("YEAR", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | YEARS_P {
        res = new IR(kYearKeyword, OP3("YEARS", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


month_keyword:

    MONTH_P {
        res = new IR(kMonthKeyword, OP3("MONTH", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | MONTHS_P {
        res = new IR(kMonthKeyword, OP3("MONTHS", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


day_keyword:

    DAY_P {
        res = new IR(kDayKeyword, OP3("DAY", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | DAYS_P {
        res = new IR(kDayKeyword, OP3("DAYS", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


hour_keyword:

    HOUR_P {
        res = new IR(kHourKeyword, OP3("HOUR", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | HOURS_P {
        res = new IR(kHourKeyword, OP3("HOURS", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


minute_keyword:

    MINUTE_P {
        res = new IR(kMinuteKeyword, OP3("MINUTE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | MINUTES_P {
        res = new IR(kMinuteKeyword, OP3("MINUTES", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


second_keyword:

    SECOND_P {
        res = new IR(kSecondKeyword, OP3("SECOND", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | SECONDS_P {
        res = new IR(kSecondKeyword, OP3("SECONDS", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


millisecond_keyword:

    MILLISECOND_P {
        res = new IR(kMillisecondKeyword, OP3("MILLISECOND", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | MILLISECONDS_P {
        res = new IR(kMillisecondKeyword, OP3("MILLISECONDS", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


microsecond_keyword:

    MICROSECOND_P {
        res = new IR(kMicrosecondKeyword, OP3("MICROSECOND", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | MICROSECONDS_P {
        res = new IR(kMicrosecondKeyword, OP3("MICROSECONDS", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_interval:

    year_keyword {
        auto tmp1 = $1;
        res = new IR(kOptInterval, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | month_keyword {
        auto tmp1 = $1;
        res = new IR(kOptInterval, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | day_keyword {
        auto tmp1 = $1;
        res = new IR(kOptInterval, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | hour_keyword {
        auto tmp1 = $1;
        res = new IR(kOptInterval, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | minute_keyword {
        auto tmp1 = $1;
        res = new IR(kOptInterval, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | second_keyword {
        auto tmp1 = $1;
        res = new IR(kOptInterval, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | millisecond_keyword {
        auto tmp1 = $1;
        res = new IR(kOptInterval, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | microsecond_keyword {
        auto tmp1 = $1;
        res = new IR(kOptInterval, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | year_keyword TO month_keyword {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kOptInterval, OP3("", "TO", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | day_keyword TO hour_keyword {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kOptInterval, OP3("", "TO", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | day_keyword TO minute_keyword {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kOptInterval, OP3("", "TO", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | day_keyword TO second_keyword {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kOptInterval, OP3("", "TO", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | hour_keyword TO minute_keyword {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kOptInterval, OP3("", "TO", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | hour_keyword TO second_keyword {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kOptInterval, OP3("", "TO", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | minute_keyword TO second_keyword {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kOptInterval, OP3("", "TO", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptInterval, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


a_expr:

    c_expr {
        auto tmp1 = $1;
        res = new IR(kAExpr, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr TYPECAST Typename {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "::", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr COLLATE any_name {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "COLLATE", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr AT TIME ZONE a_expr %prec AT {
        auto tmp1 = $1;
        auto tmp2 = $5;
        res = new IR(kAExpr, OP3("", "AT TIME ZONE", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '+' a_expr %prec UMINUS {
        auto tmp1 = $2;
        res = new IR(kAExpr, OP3("+", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '-' a_expr %prec UMINUS {
        auto tmp1 = $2;
        res = new IR(kAExpr, OP3("-", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr '+' a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "+", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr '-' a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "-", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr '*' a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "*", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr '/' a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "/", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr INTEGER_DIVISION a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "//", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr '%' a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "%", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr '^' a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "^", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr POWER_OF a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "**", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr '<' a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "<", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr '>' a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", ">", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr '=' a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "=", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr LESS_EQUALS a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "<=", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr GREATER_EQUALS a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", ">=", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr NOT_EQUALS a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "<>", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr qual_Op a_expr %prec Op {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAExpr_1, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $3;
        res = new IR(kAExpr, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | qual_Op a_expr %prec Op {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAExpr, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr qual_Op %prec POSTFIXOP {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAExpr, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr AND a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "AND", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr OR a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "OR", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | NOT a_expr {
        auto tmp1 = $2;
        res = new IR(kAExpr, OP3("NOT", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | NOT_LA a_expr %prec NOT {
        auto tmp1 = $2;
        res = new IR(kAExpr, OP3("NOT", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr GLOB a_expr %prec GLOB {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "GLOB", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr LIKE a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "LIKE", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr LIKE a_expr ESCAPE a_expr %prec LIKE {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr_2, OP3("", "LIKE", "ESCAPE"), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $5;
        res = new IR(kAExpr, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr NOT_LA LIKE a_expr %prec NOT_LA {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kAExpr, OP3("", "NOT LIKE", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr NOT_LA LIKE a_expr ESCAPE a_expr %prec NOT_LA {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kAExpr_3, OP3("", "NOT LIKE", "ESCAPE"), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $6;
        res = new IR(kAExpr, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr ILIKE a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "ILIKE", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr ILIKE a_expr ESCAPE a_expr %prec ILIKE {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr_4, OP3("", "ILIKE", "ESCAPE"), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $5;
        res = new IR(kAExpr, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr NOT_LA ILIKE a_expr %prec NOT_LA {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kAExpr, OP3("", "NOT ILIKE", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr NOT_LA ILIKE a_expr ESCAPE a_expr %prec NOT_LA {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kAExpr_5, OP3("", "NOT ILIKE", "ESCAPE"), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $6;
        res = new IR(kAExpr, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr SIMILAR TO a_expr %prec SIMILAR {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kAExpr, OP3("", "SIMILAR TO", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr SIMILAR TO a_expr ESCAPE a_expr %prec SIMILAR {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kAExpr_6, OP3("", "SIMILAR TO", "ESCAPE"), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $6;
        res = new IR(kAExpr, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr NOT_LA SIMILAR TO a_expr %prec NOT_LA {
        auto tmp1 = $1;
        auto tmp2 = $5;
        res = new IR(kAExpr, OP3("", "NOT SIMILAR TO", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr NOT_LA SIMILAR TO a_expr ESCAPE a_expr %prec NOT_LA {
        auto tmp1 = $1;
        auto tmp2 = $5;
        res = new IR(kAExpr_7, OP3("", "NOT SIMILAR TO", "ESCAPE"), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $7;
        res = new IR(kAExpr, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr IS NULL_P %prec IS {
        auto tmp1 = $1;
        res = new IR(kAExpr, OP3("", "IS NULL", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr ISNULL {
        auto tmp1 = $1;
        res = new IR(kAExpr, OP3("", "ISNULL", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr IS NOT NULL_P %prec IS {
        auto tmp1 = $1;
        res = new IR(kAExpr, OP3("", "IS NOT NULL", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr NOT NULL_P {
        auto tmp1 = $1;
        res = new IR(kAExpr, OP3("", "NOT NULL", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr NOTNULL {
        auto tmp1 = $1;
        res = new IR(kAExpr, OP3("", "NOTNULL", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr LAMBDA_ARROW a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "LAMBDA_ARROW", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr DOUBLE_ARROW a_expr %prec Op {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "DOUBLE_ARROW", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | row OVERLAPS row {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "OVERLAPS", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr IS TRUE_P %prec IS {
        auto tmp1 = $1;
        auto tmp2 = new IR(kBoolLiteral, to_string($3), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp2);
        res = new IR(kAExpr, OP3("", "IS", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr IS NOT TRUE_P %prec IS {
        auto tmp1 = $1;
        auto tmp2 = new IR(kBoolLiteral, to_string($4), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp2);
        res = new IR(kAExpr, OP3("", "IS NOT", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr IS FALSE_P %prec IS {
        auto tmp1 = $1;
        auto tmp2 = new IR(kBoolLiteral, to_string($3), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp2);
        res = new IR(kAExpr, OP3("", "IS", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr IS NOT FALSE_P %prec IS {
        auto tmp1 = $1;
        auto tmp2 = new IR(kBoolLiteral, to_string($4), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp2);
        res = new IR(kAExpr, OP3("", "IS NOT", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr IS UNKNOWN %prec IS {
        auto tmp1 = $1;
        res = new IR(kAExpr, OP3("", "IS UNKNOWN", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr IS NOT UNKNOWN %prec IS {
        auto tmp1 = $1;
        res = new IR(kAExpr, OP3("", "IS NOT UNKNOWN", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr IS DISTINCT FROM a_expr %prec IS {
        auto tmp1 = $1;
        auto tmp2 = $5;
        res = new IR(kAExpr, OP3("", "IS DISTINCT FROM", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr IS NOT DISTINCT FROM a_expr %prec IS {
        auto tmp1 = $1;
        auto tmp2 = $6;
        res = new IR(kAExpr, OP3("", "IS NOT DISTINCT FROM", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr IS OF '(' type_list ')' %prec IS {
        auto tmp1 = $1;
        auto tmp2 = $5;
        res = new IR(kAExpr, OP3("", "IS OF (", ")"), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr IS NOT OF '(' type_list ')' %prec IS {
        auto tmp1 = $1;
        auto tmp2 = $6;
        res = new IR(kAExpr, OP3("", "IS NOT OF (", ")"), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr BETWEEN opt_asymmetric b_expr AND a_expr %prec BETWEEN {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr_8, OP3("", "BETWEEN", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $4;
        res = new IR(kAExpr_9, OP3("", "", "AND"), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $6;
        res = new IR(kAExpr, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr NOT_LA BETWEEN opt_asymmetric b_expr AND a_expr %prec NOT_LA {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kAExpr_10, OP3("", "NOT BETWEEN", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $5;
        res = new IR(kAExpr_11, OP3("", "", "AND"), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $7;
        res = new IR(kAExpr, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr BETWEEN SYMMETRIC b_expr AND a_expr %prec BETWEEN {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kAExpr_12, OP3("", "BETWEEN SYMMETRIC", "AND"), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $6;
        res = new IR(kAExpr, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr NOT_LA BETWEEN SYMMETRIC b_expr AND a_expr %prec NOT_LA {
        auto tmp1 = $1;
        auto tmp2 = $5;
        res = new IR(kAExpr_13, OP3("", "NOT BETWEEN SYMMETRIC", "AND"), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $7;
        res = new IR(kAExpr, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr IN_P in_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "IN", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr NOT_LA IN_P in_expr %prec NOT_LA {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kAExpr, OP3("", "NOT IN", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr subquery_Op sub_type select_with_parens %prec Op {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAExpr_14, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $3;
        res = new IR(kAExpr_15, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $4;
        res = new IR(kAExpr, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr subquery_Op sub_type '(' a_expr ')' %prec Op {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAExpr_16, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $3;
        res = new IR(kAExpr_17, OP3("", "", "("), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $5;
        res = new IR(kAExpr, OP3("", "", ")"), res, tmp4);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | DEFAULT {
        res = new IR(kAExpr, OP3("DEFAULT", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | COLUMNS '(' a_expr ')' {
        auto tmp1 = $3;
        res = new IR(kAExpr, OP3("COLUMNS (", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '*' opt_except_list opt_replace_list {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("*", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ColId '.' '*' opt_except_list opt_replace_list {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kAExpr_18, OP3("", ". *", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $5;
        res = new IR(kAExpr, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


b_expr:

    c_expr {
        auto tmp1 = $1;
        res = new IR(kBExpr, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | b_expr TYPECAST Typename {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBExpr, OP3("", "::", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '+' b_expr %prec UMINUS {
        auto tmp1 = $2;
        res = new IR(kBExpr, OP3("+", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '-' b_expr %prec UMINUS {
        auto tmp1 = $2;
        res = new IR(kBExpr, OP3("-", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | b_expr '+' b_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBExpr, OP3("", "+", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | b_expr '-' b_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBExpr, OP3("", "-", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | b_expr '*' b_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBExpr, OP3("", "*", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | b_expr '/' b_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBExpr, OP3("", "/", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | b_expr INTEGER_DIVISION b_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBExpr, OP3("", "//", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | b_expr '%' b_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBExpr, OP3("", "%", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | b_expr '^' b_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBExpr, OP3("", "^", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | b_expr POWER_OF b_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBExpr, OP3("", "**", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | b_expr '<' b_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBExpr, OP3("", "<", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | b_expr '>' b_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBExpr, OP3("", ">", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | b_expr '=' b_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBExpr, OP3("", "=", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | b_expr LESS_EQUALS b_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBExpr, OP3("", "<=", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | b_expr GREATER_EQUALS b_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBExpr, OP3("", ">=", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | b_expr NOT_EQUALS b_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBExpr, OP3("", "<>", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | b_expr qual_Op b_expr %prec Op {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kBExpr_1, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $3;
        res = new IR(kBExpr, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | qual_Op b_expr %prec Op {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kBExpr, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | b_expr qual_Op %prec POSTFIXOP {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kBExpr, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | b_expr IS DISTINCT FROM b_expr %prec IS {
        auto tmp1 = $1;
        auto tmp2 = $5;
        res = new IR(kBExpr, OP3("", "IS DISTINCT FROM", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | b_expr IS NOT DISTINCT FROM b_expr %prec IS {
        auto tmp1 = $1;
        auto tmp2 = $6;
        res = new IR(kBExpr, OP3("", "IS NOT DISTINCT FROM", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | b_expr IS OF '(' type_list ')' %prec IS {
        auto tmp1 = $1;
        auto tmp2 = $5;
        res = new IR(kBExpr, OP3("", "IS OF (", ")"), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | b_expr IS NOT OF '(' type_list ')' %prec IS {
        auto tmp1 = $1;
        auto tmp2 = $6;
        res = new IR(kBExpr, OP3("", "IS NOT OF (", ")"), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


c_expr:

    d_expr {
        auto tmp1 = $1;
        res = new IR(kCExpr, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | row {
        auto tmp1 = $1;
        res = new IR(kCExpr, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | indirection_expr opt_extended_indirection {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCExpr, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


d_expr:

    columnref {
        auto tmp1 = $1;
        res = new IR(kDExpr, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | AexprConst {
        auto tmp1 = $1;
        res = new IR(kDExpr, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '#' ICONST {
        auto tmp1 = new IR(kIntegerLiteral, to_string($2), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        res = new IR(kDExpr, OP3("#", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '$' ColLabel {
        auto tmp1 = $2;
        res = new IR(kDExpr, OP3("$", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '[' opt_expr_list_opt_comma ']' {
        auto tmp1 = $2;
        res = new IR(kDExpr, OP3("[", "]", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | list_comprehension {
        auto tmp1 = $1;
        res = new IR(kDExpr, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ARRAY select_with_parens {
        auto tmp1 = $2;
        res = new IR(kDExpr, OP3("ARRAY", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ARRAY '[' opt_expr_list_opt_comma ']' {
        auto tmp1 = $3;
        res = new IR(kDExpr, OP3("ARRAY [", "]", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | case_expr {
        auto tmp1 = $1;
        res = new IR(kDExpr, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | select_with_parens %prec UMINUS {
        auto tmp1 = $1;
        res = new IR(kDExpr, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | select_with_parens indirection {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kDExpr, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | EXISTS select_with_parens {
        auto tmp1 = $2;
        res = new IR(kDExpr, OP3("EXISTS", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | grouping_or_grouping_id '(' expr_list_opt_comma ')' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kDExpr, OP3("", "(", ")"), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


indirection_expr:

    '?' {
        res = new IR(kIndirectionExpr, OP3("?", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | PARAM {
        auto tmp1 = new IR(kIntegerLiteral, to_string($1), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        res = new IR(kIndirectionExpr, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '(' a_expr ')' {
        auto tmp1 = $2;
        res = new IR(kIndirectionExpr, OP3("(", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | struct_expr {
        auto tmp1 = $1;
        res = new IR(kIndirectionExpr, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | MAP '{' opt_map_arguments_opt_comma '}' {
        auto tmp1 = $3;
        res = new IR(kIndirectionExpr, OP3("MAP {", "}", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | func_expr {
        auto tmp1 = $1;
        res = new IR(kIndirectionExpr, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


struct_expr:

    '{' dict_arguments_opt_comma '}' {
        auto tmp1 = $2;
        res = new IR(kStructExpr, OP3("{", "}", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


func_application:

    func_name '(' ')' {
        auto tmp1 = $1;
        res = new IR(kFuncApplication, OP3("", "( )", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | func_name '(' func_arg_list opt_sort_clause opt_ignore_nulls ')' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kFuncApplication_1, OP3("", "(", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $4;
        res = new IR(kFuncApplication_2, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $5;
        res = new IR(kFuncApplication, OP3("", "", ")"), res, tmp4);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | func_name '(' VARIADIC func_arg_expr opt_sort_clause opt_ignore_nulls ')' {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kFuncApplication_3, OP3("", "( VARIADIC", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $5;
        res = new IR(kFuncApplication_4, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $6;
        res = new IR(kFuncApplication, OP3("", "", ")"), res, tmp4);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | func_name '(' func_arg_list ',' VARIADIC func_arg_expr opt_sort_clause opt_ignore_nulls ')' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kFuncApplication_5, OP3("", "(", ", VARIADIC"), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $6;
        res = new IR(kFuncApplication_6, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $7;
        res = new IR(kFuncApplication_7, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        auto tmp5 = $8;
        res = new IR(kFuncApplication, OP3("", "", ")"), res, tmp5);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | func_name '(' ALL func_arg_list opt_sort_clause opt_ignore_nulls ')' {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kFuncApplication_8, OP3("", "( ALL", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $5;
        res = new IR(kFuncApplication_9, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $6;
        res = new IR(kFuncApplication, OP3("", "", ")"), res, tmp4);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | func_name '(' DISTINCT func_arg_list opt_sort_clause opt_ignore_nulls ')' {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kFuncApplication_10, OP3("", "( DISTINCT", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $5;
        res = new IR(kFuncApplication_11, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $6;
        res = new IR(kFuncApplication, OP3("", "", ")"), res, tmp4);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


func_expr:

    func_application within_group_clause filter_clause export_clause over_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFuncExpr_1, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $3;
        res = new IR(kFuncExpr_2, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $4;
        res = new IR(kFuncExpr_3, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        auto tmp5 = $5;
        res = new IR(kFuncExpr, OP3("", "", ""), res, tmp5);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | func_expr_common_subexpr {
        auto tmp1 = $1;
        res = new IR(kFuncExpr, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


func_expr_windowless:

    func_application {
        auto tmp1 = $1;
        res = new IR(kFuncExprWindowless, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | func_expr_common_subexpr {
        auto tmp1 = $1;
        res = new IR(kFuncExprWindowless, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


func_expr_common_subexpr:

    COLLATION FOR '(' a_expr ')' {
        auto tmp1 = $4;
        res = new IR(kFuncExprCommonSubexpr, OP3("COLLATION FOR (", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CAST '(' a_expr AS Typename ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFuncExprCommonSubexpr, OP3("CAST (", "AS", ")"), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | TRY_CAST '(' a_expr AS Typename ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFuncExprCommonSubexpr, OP3("TRY_CAST (", "AS", ")"), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | EXTRACT '(' extract_list ')' {
        auto tmp1 = $3;
        res = new IR(kFuncExprCommonSubexpr, OP3("EXTRACT (", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | OVERLAY '(' overlay_list ')' {
        auto tmp1 = $3;
        res = new IR(kFuncExprCommonSubexpr, OP3("OVERLAY (", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | POSITION '(' position_list ')' {
        auto tmp1 = $3;
        res = new IR(kFuncExprCommonSubexpr, OP3("POSITION (", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | SUBSTRING '(' substr_list ')' {
        auto tmp1 = $3;
        res = new IR(kFuncExprCommonSubexpr, OP3("SUBSTRING (", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | TREAT '(' a_expr AS Typename ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFuncExprCommonSubexpr, OP3("TREAT (", "AS", ")"), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | TRIM '(' BOTH trim_list ')' {
        auto tmp1 = $4;
        res = new IR(kFuncExprCommonSubexpr, OP3("TRIM ( BOTH", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | TRIM '(' LEADING trim_list ')' {
        auto tmp1 = $4;
        res = new IR(kFuncExprCommonSubexpr, OP3("TRIM ( LEADING", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | TRIM '(' TRAILING trim_list ')' {
        auto tmp1 = $4;
        res = new IR(kFuncExprCommonSubexpr, OP3("TRIM ( TRAILING", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | TRIM '(' trim_list ')' {
        auto tmp1 = $3;
        res = new IR(kFuncExprCommonSubexpr, OP3("TRIM (", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | NULLIF '(' a_expr ',' a_expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFuncExprCommonSubexpr, OP3("NULLIF (", ",", ")"), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | COALESCE '(' expr_list_opt_comma ')' {
        auto tmp1 = $3;
        res = new IR(kFuncExprCommonSubexpr, OP3("COALESCE (", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


list_comprehension:

    '[' a_expr FOR ColId IN_P a_expr ']' {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kListComprehension_1, OP3("[", "FOR", "IN"), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $6;
        res = new IR(kListComprehension, OP3("", "", "]"), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '[' a_expr FOR ColId IN_P c_expr IF_P a_expr']' {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kListComprehension_2, OP3("[", "FOR", "IN"), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $6;
        res = new IR(kListComprehension, OP3("", "", "IF A_EXPR']'"), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


within_group_clause:

    WITHIN GROUP_P '(' sort_clause ')' {
        auto tmp1 = $4;
        res = new IR(kWithinGroupClause, OP3("WITHIN GROUP (", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kWithinGroupClause, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


filter_clause:

    FILTER '(' WHERE a_expr ')' {
        auto tmp1 = $4;
        res = new IR(kFilterClause, OP3("FILTER ( WHERE", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | FILTER '(' a_expr ')' {
        auto tmp1 = $3;
        res = new IR(kFilterClause, OP3("FILTER (", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kFilterClause, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


export_clause:

    EXPORT_STATE {
        res = new IR(kExportClause, OP3("EXPORT_STATE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kExportClause, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


window_clause:

    WINDOW window_definition_list {
        auto tmp1 = $2;
        res = new IR(kWindowClause, OP3("WINDOW", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kWindowClause, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


window_definition_list:

    window_definition {
        auto tmp1 = $1;
        res = new IR(kWindowDefinitionList, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | window_definition_list ',' window_definition {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kWindowDefinitionList, OP3("", ",", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


window_definition:

    ColId AS window_specification {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kWindowDefinition, OP3("", "AS", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


over_clause:

    OVER window_specification {
        auto tmp1 = $2;
        res = new IR(kOverClause, OP3("OVER", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | OVER ColId {
        auto tmp1 = $2;
        res = new IR(kOverClause, OP3("OVER", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOverClause, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


window_specification:

    '(' opt_existing_window_name opt_partition_clause opt_sort_clause opt_frame_clause ')' {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kWindowSpecification_1, OP3("(", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $4;
        res = new IR(kWindowSpecification_2, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $5;
        res = new IR(kWindowSpecification, OP3("", "", ")"), res, tmp4);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_existing_window_name:

    ColId {
        auto tmp1 = $1;
        res = new IR(kOptExistingWindowName, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ %prec Op {
        res = new IR(kOptExistingWindowName, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_partition_clause:

    PARTITION BY expr_list {
        auto tmp1 = $3;
        res = new IR(kOptPartitionClause, OP3("PARTITION BY", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptPartitionClause, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_frame_clause:

    RANGE frame_extent {
        auto tmp1 = $2;
        res = new IR(kOptFrameClause, OP3("RANGE", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ROWS frame_extent {
        auto tmp1 = $2;
        res = new IR(kOptFrameClause, OP3("ROWS", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptFrameClause, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


frame_extent:

    frame_bound {
        auto tmp1 = $1;
        res = new IR(kFrameExtent, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | BETWEEN frame_bound AND frame_bound {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kFrameExtent, OP3("BETWEEN", "AND", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


frame_bound:

    UNBOUNDED PRECEDING {
        res = new IR(kFrameBound, OP3("UNBOUNDED PRECEDING", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | UNBOUNDED FOLLOWING {
        res = new IR(kFrameBound, OP3("UNBOUNDED FOLLOWING", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CURRENT_P ROW {
        res = new IR(kFrameBound, OP3("CURRENT ROW", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr PRECEDING {
        auto tmp1 = $1;
        res = new IR(kFrameBound, OP3("", "PRECEDING", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr FOLLOWING {
        auto tmp1 = $1;
        res = new IR(kFrameBound, OP3("", "FOLLOWING", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


qualified_row:

    ROW '(' expr_list_opt_comma ')' {
        auto tmp1 = $3;
        res = new IR(kQualifiedRow, OP3("ROW (", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ROW '(' ')' {
        res = new IR(kQualifiedRow, OP3("ROW ( )", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


row:

    qualified_row {
        auto tmp1 = $1;
        res = new IR(kRow, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '(' expr_list ',' a_expr ')' {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kRow, OP3("(", ",", ")"), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


dict_arg:

    ColIdOrString ':' a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kDictArg, OP3("", ":", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


dict_arguments:

    dict_arg {
        auto tmp1 = $1;
        res = new IR(kDictArguments, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | dict_arguments ',' dict_arg {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kDictArguments, OP3("", ",", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


dict_arguments_opt_comma:

    dict_arguments {
        auto tmp1 = $1;
        res = new IR(kDictArgumentsOptComma, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | dict_arguments ',' {
        auto tmp1 = $1;
        res = new IR(kDictArgumentsOptComma, OP3("", ",", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


map_arg:

    a_expr ':' a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kMapArg, OP3("", ":", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


map_arguments:

    map_arg {
        auto tmp1 = $1;
        res = new IR(kMapArguments, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | map_arguments ',' map_arg {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kMapArguments, OP3("", ",", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


map_arguments_opt_comma:

    map_arguments {
        auto tmp1 = $1;
        res = new IR(kMapArgumentsOptComma, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | map_arguments ',' {
        auto tmp1 = $1;
        res = new IR(kMapArgumentsOptComma, OP3("", ",", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_map_arguments_opt_comma:

    map_arguments_opt_comma {
        auto tmp1 = $1;
        res = new IR(kOptMapArgumentsOptComma, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptMapArgumentsOptComma, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


sub_type:

    ANY {
        res = new IR(kSubType, OP3("ANY", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | SOME {
        res = new IR(kSubType, OP3("SOME", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ALL {
        res = new IR(kSubType, OP3("ALL", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


all_Op:

    Op {
        res = new IR(kAllOp, OP3("+", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | MathOp {
        auto tmp1 = $1;
        res = new IR(kAllOp, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


MathOp:

    '+' {
        res = new IR(kMathOp, OP3("+", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '-' {
        res = new IR(kMathOp, OP3("-", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '*' {
        res = new IR(kMathOp, OP3("*", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '/' {
        res = new IR(kMathOp, OP3("/", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | INTEGER_DIVISION {
        res = new IR(kMathOp, OP3("//", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '%' {
        res = new IR(kMathOp, OP3("%", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '^' {
        res = new IR(kMathOp, OP3("^", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | POWER_OF {
        res = new IR(kMathOp, OP3("**", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '<' {
        res = new IR(kMathOp, OP3("<", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '>' {
        res = new IR(kMathOp, OP3(">", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '=' {
        res = new IR(kMathOp, OP3("=", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | LESS_EQUALS {
        res = new IR(kMathOp, OP3("<=", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | GREATER_EQUALS {
        res = new IR(kMathOp, OP3(">=", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | NOT_EQUALS {
        res = new IR(kMathOp, OP3("<>", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


qual_Op:

    Op {
        res = new IR(kQualOp, OP3("+", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | OPERATOR '(' any_operator ')' {
        auto tmp1 = $3;
        res = new IR(kQualOp, OP3("OPERATOR (", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


qual_all_Op:

    all_Op {
        auto tmp1 = $1;
        res = new IR(kQualAllOp, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | OPERATOR '(' any_operator ')' {
        auto tmp1 = $3;
        res = new IR(kQualAllOp, OP3("OPERATOR (", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


subquery_Op:

    all_Op {
        auto tmp1 = $1;
        res = new IR(kSubqueryOp, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | OPERATOR '(' any_operator ')' {
        auto tmp1 = $3;
        res = new IR(kSubqueryOp, OP3("OPERATOR (", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | LIKE {
        res = new IR(kSubqueryOp, OP3("LIKE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | NOT_LA LIKE {
        res = new IR(kSubqueryOp, OP3("NOT LIKE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | GLOB {
        res = new IR(kSubqueryOp, OP3("GLOB", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | NOT_LA GLOB {
        res = new IR(kSubqueryOp, OP3("NOT GLOB", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ILIKE {
        res = new IR(kSubqueryOp, OP3("ILIKE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | NOT_LA ILIKE {
        res = new IR(kSubqueryOp, OP3("NOT ILIKE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


any_operator:

    all_Op {
        auto tmp1 = $1;
        res = new IR(kAnyOperator, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ColId '.' any_operator {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAnyOperator, OP3("", ".", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


c_expr_list:

    c_expr {
        auto tmp1 = $1;
        res = new IR(kCExprList, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | c_expr_list ',' c_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kCExprList, OP3("", ",", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


c_expr_list_opt_comma:

    c_expr_list {
        auto tmp1 = $1;
        res = new IR(kCExprListOptComma, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | c_expr_list ',' {
        auto tmp1 = $1;
        res = new IR(kCExprListOptComma, OP3("", ",", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


expr_list:

    a_expr {
        auto tmp1 = $1;
        res = new IR(kExprList, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | expr_list ',' a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kExprList, OP3("", ",", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


expr_list_opt_comma:

    expr_list {
        auto tmp1 = $1;
        res = new IR(kExprListOptComma, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | expr_list ',' {
        auto tmp1 = $1;
        res = new IR(kExprListOptComma, OP3("", ",", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_expr_list_opt_comma:

    expr_list_opt_comma {
        auto tmp1 = $1;
        res = new IR(kOptExprListOptComma, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptExprListOptComma, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


func_arg_list:

    func_arg_expr {
        auto tmp1 = $1;
        res = new IR(kFuncArgList, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | func_arg_list ',' func_arg_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kFuncArgList, OP3("", ",", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


func_arg_expr:

    a_expr {
        auto tmp1 = $1;
        res = new IR(kFuncArgExpr, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | param_name COLON_EQUALS a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kFuncArgExpr, OP3("", "COLON_EQUALS", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | param_name EQUALS_GREATER a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kFuncArgExpr, OP3("", "EQUALS_GREATER", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


type_list:

    Typename {
        auto tmp1 = $1;
        res = new IR(kTypeList, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | type_list ',' Typename {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTypeList, OP3("", ",", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


extract_list:

    extract_arg FROM a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kExtractList, OP3("", "FROM", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kExtractList, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


extract_arg:

    IDENT {
        auto tmp1 = new IR(kIdentifier, to_string($1), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        res = new IR(kExtractArg, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | year_keyword {
        auto tmp1 = $1;
        res = new IR(kExtractArg, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | month_keyword {
        auto tmp1 = $1;
        res = new IR(kExtractArg, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | day_keyword {
        auto tmp1 = $1;
        res = new IR(kExtractArg, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | hour_keyword {
        auto tmp1 = $1;
        res = new IR(kExtractArg, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | minute_keyword {
        auto tmp1 = $1;
        res = new IR(kExtractArg, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | second_keyword {
        auto tmp1 = $1;
        res = new IR(kExtractArg, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | millisecond_keyword {
        auto tmp1 = $1;
        res = new IR(kExtractArg, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | microsecond_keyword {
        auto tmp1 = $1;
        res = new IR(kExtractArg, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | Sconst {
        auto tmp1 = $1;
        res = new IR(kExtractArg, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


overlay_list:

    a_expr overlay_placing substr_from substr_for {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOverlayList_1, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $3;
        res = new IR(kOverlayList_2, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $4;
        res = new IR(kOverlayList, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr overlay_placing substr_from {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOverlayList_3, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $3;
        res = new IR(kOverlayList, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


overlay_placing:

    PLACING a_expr {
        auto tmp1 = $2;
        res = new IR(kOverlayPlacing, OP3("PLACING", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


position_list:

    b_expr IN_P b_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kPositionList, OP3("", "IN", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kPositionList, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


substr_list:

    a_expr substr_from substr_for {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSubstrList_1, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $3;
        res = new IR(kSubstrList, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr substr_for substr_from {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSubstrList_2, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $3;
        res = new IR(kSubstrList, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr substr_from {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSubstrList, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr substr_for {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSubstrList, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | expr_list {
        auto tmp1 = $1;
        res = new IR(kSubstrList, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kSubstrList, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


substr_from:

    FROM a_expr {
        auto tmp1 = $2;
        res = new IR(kSubstrFrom, OP3("FROM", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


substr_for:

    FOR a_expr {
        auto tmp1 = $2;
        res = new IR(kSubstrFor, OP3("FOR", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


trim_list:

    a_expr FROM expr_list_opt_comma {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTrimList, OP3("", "FROM", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | FROM expr_list_opt_comma {
        auto tmp1 = $2;
        res = new IR(kTrimList, OP3("FROM", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | expr_list_opt_comma {
        auto tmp1 = $1;
        res = new IR(kTrimList, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


in_expr:

    select_with_parens {
        auto tmp1 = $1;
        res = new IR(kInExpr, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '(' expr_list_opt_comma ')' {
        auto tmp1 = $2;
        res = new IR(kInExpr, OP3("(", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


case_expr:

    CASE case_arg when_clause_list case_default END_P {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCaseExpr_1, OP3("CASE", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $4;
        res = new IR(kCaseExpr, OP3("", "", "END"), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


when_clause_list:

    when_clause {
        auto tmp1 = $1;
        res = new IR(kWhenClauseList, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | when_clause_list when_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kWhenClauseList, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


when_clause:

    WHEN a_expr THEN a_expr {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kWhenClause, OP3("WHEN", "THEN", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


case_default:

    ELSE a_expr {
        auto tmp1 = $2;
        res = new IR(kCaseDefault, OP3("ELSE", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kCaseDefault, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


case_arg:

    a_expr {
        auto tmp1 = $1;
        res = new IR(kCaseArg, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kCaseArg, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


columnref:

    ColId {
        auto tmp1 = $1;
        res = new IR(kColumnref, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ColId indirection {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kColumnref, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


indirection_el:

    '[' a_expr ']' {
        auto tmp1 = $2;
        res = new IR(kIndirectionEl, OP3("[", "]", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '[' opt_slice_bound ':' opt_slice_bound ']' {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kIndirectionEl, OP3("[", ":", "]"), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '[' opt_slice_bound ':' opt_slice_bound ':' opt_slice_bound ']' {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kIndirectionEl_1, OP3("[", ":", ":"), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $6;
        res = new IR(kIndirectionEl, OP3("", "", "]"), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '[' opt_slice_bound ':' '-' ':' opt_slice_bound ']' {
        auto tmp1 = $2;
        auto tmp2 = $6;
        res = new IR(kIndirectionEl, OP3("[", ": - :", "]"), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_slice_bound:

    a_expr {
        auto tmp1 = $1;
        res = new IR(kOptSliceBound, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptSliceBound, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_indirection:

    /*EMPTY*/ {
        res = new IR(kOptIndirection, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | opt_indirection indirection_el {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptIndirection, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_func_arguments:

    /*EMPTY*/ {
        res = new IR(kOptFuncArguments, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '(' ')' {
        res = new IR(kOptFuncArguments, OP3("( )", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '(' func_arg_list ')' {
        auto tmp1 = $2;
        res = new IR(kOptFuncArguments, OP3("(", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


extended_indirection_el:

    '.' attr_name opt_func_arguments {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kExtendedIndirectionEl, OP3(".", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '[' a_expr ']' {
        auto tmp1 = $2;
        res = new IR(kExtendedIndirectionEl, OP3("[", "]", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '[' opt_slice_bound ':' opt_slice_bound ']' {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kExtendedIndirectionEl, OP3("[", ":", "]"), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '[' opt_slice_bound ':' opt_slice_bound ':' opt_slice_bound ']' {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kExtendedIndirectionEl_1, OP3("[", ":", ":"), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $6;
        res = new IR(kExtendedIndirectionEl, OP3("", "", "]"), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '[' opt_slice_bound ':' '-' ':' opt_slice_bound ']' {
        auto tmp1 = $2;
        auto tmp2 = $6;
        res = new IR(kExtendedIndirectionEl, OP3("[", ": - :", "]"), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


extended_indirection:

    extended_indirection_el {
        auto tmp1 = $1;
        res = new IR(kExtendedIndirection, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | extended_indirection extended_indirection_el {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kExtendedIndirection, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_extended_indirection:

    /*EMPTY*/ {
        res = new IR(kOptExtendedIndirection, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | opt_extended_indirection extended_indirection_el {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptExtendedIndirection, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_asymmetric:

    ASYMMETRIC {
        res = new IR(kOptAsymmetric, OP3("ASYMMETRIC", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptAsymmetric, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_target_list_opt_comma:

    target_list_opt_comma {
        auto tmp1 = $1;
        res = new IR(kOptTargetListOptComma, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptTargetListOptComma, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


target_list:

    target_el {
        auto tmp1 = $1;
        res = new IR(kTargetList, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | target_list ',' target_el {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTargetList, OP3("", ",", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


target_list_opt_comma:

    target_list {
        auto tmp1 = $1;
        res = new IR(kTargetListOptComma, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | target_list ',' {
        auto tmp1 = $1;
        res = new IR(kTargetListOptComma, OP3("", ",", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


target_el:

    a_expr AS ColLabelOrString {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTargetEl, OP3("", "AS", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr IDENT {
        auto tmp1 = $1;
        auto tmp2 = new IR(kIdentifier, to_string($2), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp2);
        res = new IR(kTargetEl, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | a_expr {
        auto tmp1 = $1;
        res = new IR(kTargetEl, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


except_list:

    EXCLUDE '(' name_list_opt_comma ')' {
        auto tmp1 = $3;
        res = new IR(kExceptList, OP3("EXCLUDE (", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | EXCLUDE ColId {
        auto tmp1 = $2;
        res = new IR(kExceptList, OP3("EXCLUDE", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_except_list:

    except_list {
        auto tmp1 = $1;
        res = new IR(kOptExceptList, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptExceptList, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


replace_list_el:

    a_expr AS ColId {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kReplaceListEl, OP3("", "AS", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


replace_list:

    replace_list_el {
        auto tmp1 = $1;
        res = new IR(kReplaceList, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | replace_list ',' replace_list_el {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kReplaceList, OP3("", ",", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


replace_list_opt_comma:

    replace_list {
        auto tmp1 = $1;
        res = new IR(kReplaceListOptComma, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | replace_list ',' {
        auto tmp1 = $1;
        res = new IR(kReplaceListOptComma, OP3("", ",", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_replace_list:

    REPLACE '(' replace_list_opt_comma ')' {
        auto tmp1 = $3;
        res = new IR(kOptReplaceList, OP3("REPLACE (", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | REPLACE replace_list_el {
        auto tmp1 = $2;
        res = new IR(kOptReplaceList, OP3("REPLACE", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptReplaceList, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


qualified_name_list:

    qualified_name {
        auto tmp1 = $1;
        res = new IR(kQualifiedNameList, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | qualified_name_list ',' qualified_name {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kQualifiedNameList, OP3("", ",", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


name_list:

    name {
        auto tmp1 = $1;
        res = new IR(kNameList, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | name_list ',' name {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kNameList, OP3("", ",", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


name_list_opt_comma:

    name_list {
        auto tmp1 = $1;
        res = new IR(kNameListOptComma, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | name_list ',' {
        auto tmp1 = $1;
        res = new IR(kNameListOptComma, OP3("", ",", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


name_list_opt_comma_opt_bracket:

    name_list_opt_comma {
        auto tmp1 = $1;
        res = new IR(kNameListOptCommaOptBracket, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | '(' name_list_opt_comma ')' {
        auto tmp1 = $2;
        res = new IR(kNameListOptCommaOptBracket, OP3("(", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


name:

    ColIdOrString {
        auto tmp1 = $1;
        res = new IR(kName, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


func_name:

    function_name_token {
        auto tmp1 = $1;
        res = new IR(kFuncName, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ColId indirection {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFuncName, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


AexprConst:

    Iconst {
        auto tmp1 = $1;
        res = new IR(kAexprConst, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | FCONST {
        auto tmp1 = new IR(kFloatLiteral, to_string($1), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        res = new IR(kAexprConst, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | Sconst opt_indirection {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAexprConst, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | BCONST {
        auto tmp1 = new IR(kBinLiteral, to_string($1), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        res = new IR(kAexprConst, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | XCONST {
        auto tmp1 = new IR(kBinLiteral, to_string($1), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        res = new IR(kAexprConst, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | func_name Sconst {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAexprConst, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | func_name '(' func_arg_list opt_sort_clause opt_ignore_nulls ')' Sconst {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAexprConst_1, OP3("", "(", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $4;
        res = new IR(kAexprConst_2, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $5;
        res = new IR(kAexprConst_3, OP3("", "", ")"), res, tmp4);
        ir_vec.push_back(res); 
        auto tmp5 = $7;
        res = new IR(kAexprConst, OP3("", "", ""), res, tmp5);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ConstTypename Sconst {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAexprConst, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ConstInterval '(' a_expr ')' opt_interval {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAexprConst_4, OP3("", "(", ")"), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $5;
        res = new IR(kAexprConst, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ConstInterval Iconst opt_interval {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAexprConst_5, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $3;
        res = new IR(kAexprConst, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ConstInterval Sconst opt_interval {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAexprConst_6, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $3;
        res = new IR(kAexprConst, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | TRUE_P {
        auto tmp1 = new IR(kBoolLiteral, to_string($1), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        res = new IR(kAexprConst, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | FALSE_P {
        auto tmp1 = new IR(kBoolLiteral, to_string($1), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        res = new IR(kAexprConst, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | NULL_P {
        res = new IR(kAexprConst, OP3("NULL", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


Iconst:

    ICONST {
        auto tmp1 = new IR(kIntegerLiteral, to_string($1), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        res = new IR(kIconst, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


type_function_name:

    IDENT {
        auto tmp1 = new IR(kIdentifier, to_string($1), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        res = new IR(kTypeFunctionName, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


function_name_token:

    IDENT {
        auto tmp1 = new IR(kIdentifier, to_string($1), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        res = new IR(kFunctionNameToken, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


type_name_token:

    IDENT {
        auto tmp1 = new IR(kIdentifier, to_string($1), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        res = new IR(kTypeNameToken, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


any_name:

    ColId {
        auto tmp1 = $1;
        res = new IR(kAnyName, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ColId attrs {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAnyName, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


attrs:

    '.' attr_name {
        auto tmp1 = $2;
        res = new IR(kAttrs, OP3(".", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | attrs '.' attr_name {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAttrs, OP3("", ".", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_name_list:

    '(' name_list_opt_comma ')' {
        auto tmp1 = $2;
        res = new IR(kOptNameList, OP3("(", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptNameList, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


param_name:

    type_function_name {
        auto tmp1 = $1;
        res = new IR(kParamName, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


ColLabelOrString:

    ColLabel {
        auto tmp1 = $1;
        res = new IR(kColLabelOrString, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | SCONST {
        auto tmp1 = new IR(kStringLiteral, to_string($1), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        res = new IR(kColLabelOrString, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


PrepareStmt:

    PREPARE name prep_type_clause AS PreparableStmt {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kPrepareStmt_1, OP3("PREPARE", "", "AS"), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $5;
        res = new IR(kPrepareStmt, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


prep_type_clause:

    '(' type_list ')' {
        auto tmp1 = $2;
        res = new IR(kPrepTypeClause, OP3("(", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kPrepTypeClause, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


PreparableStmt:

    SelectStmt {
        auto tmp1 = $1;
        res = new IR(kPreparableStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | InsertStmt {
        auto tmp1 = $1;
        res = new IR(kPreparableStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | UpdateStmt {
        auto tmp1 = $1;
        res = new IR(kPreparableStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CopyStmt {
        auto tmp1 = $1;
        res = new IR(kPreparableStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | DeleteStmt {
        auto tmp1 = $1;
        res = new IR(kPreparableStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


CreateSchemaStmt:

    CREATE_P SCHEMA qualified_name OptSchemaEltList {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kCreateSchemaStmt, OP3("CREATE SCHEMA", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CREATE_P SCHEMA IF_P NOT EXISTS qualified_name OptSchemaEltList {
        auto tmp1 = $6;
        auto tmp2 = $7;
        res = new IR(kCreateSchemaStmt, OP3("CREATE SCHEMA IF NOT EXISTS", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CREATE_P OR REPLACE SCHEMA qualified_name OptSchemaEltList {
        auto tmp1 = $5;
        auto tmp2 = $6;
        res = new IR(kCreateSchemaStmt, OP3("CREATE OR REPLACE SCHEMA", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


OptSchemaEltList:

    OptSchemaEltList schema_stmt {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptSchemaEltList, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptSchemaEltList, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


schema_stmt:

    CreateStmt {
        auto tmp1 = $1;
        res = new IR(kSchemaStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | IndexStmt {
        auto tmp1 = $1;
        res = new IR(kSchemaStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CreateSeqStmt {
        auto tmp1 = $1;
        res = new IR(kSchemaStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ViewStmt {
        auto tmp1 = $1;
        res = new IR(kSchemaStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


IndexStmt:

    CREATE_P opt_unique INDEX opt_concurrently opt_index_name ON qualified_name access_method_clause '(' index_params ')' opt_reloptions where_clause {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kIndexStmt_1, OP3("CREATE", "INDEX", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $5;
        res = new IR(kIndexStmt_2, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = new IR(kStringLiteral, to_string($6), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp4);
        res = new IR(kIndexStmt_3, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        auto tmp5 = $7;
        res = new IR(kIndexStmt_4, OP3("", "", ""), res, tmp5);
        ir_vec.push_back(res); 
        auto tmp6 = $8;
        res = new IR(kIndexStmt_5, OP3("", "", "("), res, tmp6);
        ir_vec.push_back(res); 
        auto tmp7 = $10;
        res = new IR(kIndexStmt_6, OP3("", "", ")"), res, tmp7);
        ir_vec.push_back(res); 
        auto tmp8 = $12;
        res = new IR(kIndexStmt_7, OP3("", "", ""), res, tmp8);
        ir_vec.push_back(res); 
        auto tmp9 = $13;
        res = new IR(kIndexStmt, OP3("", "", ""), res, tmp9);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CREATE_P opt_unique INDEX opt_concurrently IF_P NOT EXISTS index_name ON qualified_name access_method_clause '(' index_params ')' opt_reloptions where_clause {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kIndexStmt_8, OP3("CREATE", "INDEX", "IF NOT EXISTS"), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $8;
        res = new IR(kIndexStmt_9, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = new IR(kStringLiteral, to_string($9), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp4);
        res = new IR(kIndexStmt_10, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        auto tmp5 = $10;
        res = new IR(kIndexStmt_11, OP3("", "", ""), res, tmp5);
        ir_vec.push_back(res); 
        auto tmp6 = $11;
        res = new IR(kIndexStmt_12, OP3("", "", "("), res, tmp6);
        ir_vec.push_back(res); 
        auto tmp7 = $13;
        res = new IR(kIndexStmt_13, OP3("", "", ")"), res, tmp7);
        ir_vec.push_back(res); 
        auto tmp8 = $15;
        res = new IR(kIndexStmt_14, OP3("", "", ""), res, tmp8);
        ir_vec.push_back(res); 
        auto tmp9 = $16;
        res = new IR(kIndexStmt, OP3("", "", ""), res, tmp9);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


access_method:

    ColId {
        auto tmp1 = $1;
        res = new IR(kAccessMethod, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


access_method_clause:

    USING access_method {
        auto tmp1 = $2;
        res = new IR(kAccessMethodClause, OP3("USING", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kAccessMethodClause, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_concurrently:

    CONCURRENTLY {
        res = new IR(kOptConcurrently, OP3("CONCURRENTLY", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptConcurrently, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_index_name:

    index_name {
        auto tmp1 = $1;
        res = new IR(kOptIndexName, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptIndexName, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_reloptions:

    WITH reloptions {
        auto tmp1 = $2;
        res = new IR(kOptReloptions, OP3("WITH", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptReloptions, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_unique:

    UNIQUE {
        res = new IR(kOptUnique, OP3("UNIQUE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptUnique, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


AlterObjectSchemaStmt:

    ALTER TABLE relation_expr SET SCHEMA name {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kAlterObjectSchemaStmt, OP3("ALTER TABLE", "SET SCHEMA", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ALTER TABLE IF_P EXISTS relation_expr SET SCHEMA name {
        auto tmp1 = $5;
        auto tmp2 = $8;
        res = new IR(kAlterObjectSchemaStmt, OP3("ALTER TABLE IF EXISTS", "SET SCHEMA", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ALTER SEQUENCE qualified_name SET SCHEMA name {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kAlterObjectSchemaStmt, OP3("ALTER SEQUENCE", "SET SCHEMA", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ALTER SEQUENCE IF_P EXISTS qualified_name SET SCHEMA name {
        auto tmp1 = $5;
        auto tmp2 = $8;
        res = new IR(kAlterObjectSchemaStmt, OP3("ALTER SEQUENCE IF EXISTS", "SET SCHEMA", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ALTER VIEW qualified_name SET SCHEMA name {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kAlterObjectSchemaStmt, OP3("ALTER VIEW", "SET SCHEMA", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ALTER VIEW IF_P EXISTS qualified_name SET SCHEMA name {
        auto tmp1 = $5;
        auto tmp2 = $8;
        res = new IR(kAlterObjectSchemaStmt, OP3("ALTER VIEW IF EXISTS", "SET SCHEMA", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


CheckPointStmt:

    FORCE CHECKPOINT opt_col_id {
        auto tmp1 = $3;
        res = new IR(kCheckPointStmt, OP3("FORCE CHECKPOINT", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CHECKPOINT opt_col_id {
        auto tmp1 = $2;
        res = new IR(kCheckPointStmt, OP3("CHECKPOINT", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_col_id:

    ColId {
        auto tmp1 = $1;
        res = new IR(kOptColId, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptColId, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


ExportStmt:

    EXPORT_P DATABASE Sconst copy_options {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kExportStmt, OP3("EXPORT DATABASE", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | EXPORT_P DATABASE ColId TO Sconst copy_options {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kExportStmt_1, OP3("EXPORT DATABASE", "TO", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $6;
        res = new IR(kExportStmt, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


ImportStmt:

    IMPORT_P DATABASE Sconst {
        auto tmp1 = $3;
        res = new IR(kImportStmt, OP3("IMPORT DATABASE", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


ExplainStmt:

    EXPLAIN ExplainableStmt {
        auto tmp1 = $2;
        res = new IR(kExplainStmt, OP3("EXPLAIN", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | EXPLAIN analyze_keyword opt_verbose ExplainableStmt {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kExplainStmt_1, OP3("EXPLAIN", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $4;
        res = new IR(kExplainStmt, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | EXPLAIN VERBOSE ExplainableStmt {
        auto tmp1 = $3;
        res = new IR(kExplainStmt, OP3("EXPLAIN VERBOSE", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | EXPLAIN '(' explain_option_list ')' ExplainableStmt {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kExplainStmt, OP3("EXPLAIN (", ")", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_verbose:

    VERBOSE {
        res = new IR(kOptVerbose, OP3("VERBOSE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptVerbose, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


explain_option_arg:

    opt_boolean_or_string {
        auto tmp1 = $1;
        res = new IR(kExplainOptionArg, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | NumericOnly {
        auto tmp1 = $1;
        res = new IR(kExplainOptionArg, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kExplainOptionArg, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


ExplainableStmt:

    AlterObjectSchemaStmt {
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | AlterSeqStmt {
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | AlterTableStmt {
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CallStmt {
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CheckPointStmt {
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CopyStmt {
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CreateAsStmt {
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CreateFunctionStmt {
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CreateSchemaStmt {
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CreateSeqStmt {
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CreateStmt {
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CreateTypeStmt {
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | DeallocateStmt {
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | DeleteStmt {
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | DropStmt {
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ExecuteStmt {
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | IndexStmt {
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | InsertStmt {
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | LoadStmt {
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | PragmaStmt {
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | PrepareStmt {
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | RenameStmt {
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | SelectStmt {
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | TransactionStmt {
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | UpdateStmt {
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | VacuumStmt {
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | VariableResetStmt {
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | VariableSetStmt {
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | VariableShowStmt {
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ViewStmt {
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


NonReservedWord:

    IDENT {
        auto tmp1 = new IR(kIdentifier, to_string($1), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        res = new IR(kNonReservedWord, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


NonReservedWord_or_Sconst:

    NonReservedWord {
        auto tmp1 = $1;
        res = new IR(kNonReservedWordOrSconst, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | Sconst {
        auto tmp1 = $1;
        res = new IR(kNonReservedWordOrSconst, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


explain_option_list:

    explain_option_elem {
        auto tmp1 = $1;
        res = new IR(kExplainOptionList, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | explain_option_list ',' explain_option_elem {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kExplainOptionList, OP3("", ",", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


analyze_keyword:

    ANALYZE {
        res = new IR(kAnalyzeKeyword, OP3("ANALYZE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ANALYSE {
        res = new IR(kAnalyzeKeyword, OP3("ANALYSE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_boolean_or_string:

    TRUE_P {
        auto tmp1 = new IR(kBoolLiteral, to_string($1), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        res = new IR(kOptBooleanOrString, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | FALSE_P {
        auto tmp1 = new IR(kBoolLiteral, to_string($1), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        res = new IR(kOptBooleanOrString, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ON {
        auto tmp1 = new IR(kStringLiteral, to_string($1), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        res = new IR(kOptBooleanOrString, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | NonReservedWord_or_Sconst {
        auto tmp1 = $1;
        res = new IR(kOptBooleanOrString, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


explain_option_elem:

    explain_option_name explain_option_arg {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kExplainOptionElem, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


explain_option_name:

    NonReservedWord {
        auto tmp1 = $1;
        res = new IR(kExplainOptionName, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | analyze_keyword {
        auto tmp1 = $1;
        res = new IR(kExplainOptionName, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


VariableSetStmt:

    SET set_rest {
        auto tmp1 = $2;
        res = new IR(kVariableSetStmt, OP3("SET", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | SET LOCAL set_rest {
        auto tmp1 = $3;
        res = new IR(kVariableSetStmt, OP3("SET LOCAL", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | SET SESSION set_rest {
        auto tmp1 = $3;
        res = new IR(kVariableSetStmt, OP3("SET SESSION", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | SET GLOBAL set_rest {
        auto tmp1 = $3;
        res = new IR(kVariableSetStmt, OP3("SET GLOBAL", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


set_rest:

    generic_set {
        auto tmp1 = $1;
        res = new IR(kSetRest, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | var_name FROM CURRENT_P {
        auto tmp1 = $1;
        res = new IR(kSetRest, OP3("", "FROM CURRENT", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | TIME ZONE zone_value {
        auto tmp1 = $3;
        res = new IR(kSetRest, OP3("TIME ZONE", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | SCHEMA Sconst {
        auto tmp1 = $2;
        res = new IR(kSetRest, OP3("SCHEMA", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


generic_set:

    var_name TO var_list {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kGenericSet, OP3("", "TO", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | var_name '=' var_list {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kGenericSet, OP3("", "=", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | var_name TO DEFAULT {
        auto tmp1 = $1;
        res = new IR(kGenericSet, OP3("", "TO DEFAULT", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | var_name '=' DEFAULT {
        auto tmp1 = $1;
        res = new IR(kGenericSet, OP3("", "= DEFAULT", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


var_value:

    opt_boolean_or_string {
        auto tmp1 = $1;
        res = new IR(kVarValue, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | NumericOnly {
        auto tmp1 = $1;
        res = new IR(kVarValue, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


zone_value:

    Sconst {
        auto tmp1 = $1;
        res = new IR(kZoneValue, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | IDENT {
        auto tmp1 = new IR(kIdentifier, to_string($1), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        res = new IR(kZoneValue, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ConstInterval Sconst opt_interval {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kZoneValue_1, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $3;
        res = new IR(kZoneValue, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ConstInterval '(' Iconst ')' Sconst {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kZoneValue_2, OP3("", "(", ")"), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $5;
        res = new IR(kZoneValue, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | NumericOnly {
        auto tmp1 = $1;
        res = new IR(kZoneValue, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | DEFAULT {
        res = new IR(kZoneValue, OP3("DEFAULT", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | LOCAL {
        res = new IR(kZoneValue, OP3("LOCAL", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


var_list:

    var_value {
        auto tmp1 = $1;
        res = new IR(kVarList, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | var_list ',' var_value {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kVarList, OP3("", ",", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


LoadStmt:

    LOAD file_name {
        auto tmp1 = $2;
        res = new IR(kLoadStmt, OP3("LOAD", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | INSTALL file_name {
        auto tmp1 = $2;
        res = new IR(kLoadStmt, OP3("INSTALL", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | FORCE INSTALL file_name {
        auto tmp1 = $3;
        res = new IR(kLoadStmt, OP3("FORCE INSTALL", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | INSTALL file_name FROM repo_path {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kLoadStmt, OP3("INSTALL", "FROM", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | FORCE INSTALL file_name FROM repo_path {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kLoadStmt, OP3("FORCE INSTALL", "FROM", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


file_name:

    Sconst {
        auto tmp1 = $1;
        res = new IR(kFileName, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ColId {
        auto tmp1 = $1;
        res = new IR(kFileName, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


repo_path:

    Sconst {
        auto tmp1 = $1;
        res = new IR(kRepoPath, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ColId {
        auto tmp1 = $1;
        res = new IR(kRepoPath, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


VacuumStmt:

    VACUUM opt_full opt_freeze opt_verbose {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kVacuumStmt_1, OP3("VACUUM", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $4;
        res = new IR(kVacuumStmt, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | VACUUM opt_full opt_freeze opt_verbose qualified_name opt_name_list {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kVacuumStmt_2, OP3("VACUUM", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $4;
        res = new IR(kVacuumStmt_3, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $5;
        res = new IR(kVacuumStmt_4, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        auto tmp5 = $6;
        res = new IR(kVacuumStmt, OP3("", "", ""), res, tmp5);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | VACUUM opt_full opt_freeze opt_verbose AnalyzeStmt {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kVacuumStmt_5, OP3("VACUUM", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $4;
        res = new IR(kVacuumStmt_6, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $5;
        res = new IR(kVacuumStmt, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | VACUUM '(' vacuum_option_list ')' {
        auto tmp1 = $3;
        res = new IR(kVacuumStmt, OP3("VACUUM (", ")", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | VACUUM '(' vacuum_option_list ')' qualified_name opt_name_list {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kVacuumStmt_7, OP3("VACUUM (", ")", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $6;
        res = new IR(kVacuumStmt, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


vacuum_option_elem:

    analyze_keyword {
        auto tmp1 = $1;
        res = new IR(kVacuumOptionElem, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | VERBOSE {
        res = new IR(kVacuumOptionElem, OP3("VERBOSE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | FREEZE {
        res = new IR(kVacuumOptionElem, OP3("FREEZE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | FULL {
        res = new IR(kVacuumOptionElem, OP3("FULL", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | IDENT {
        auto tmp1 = new IR(kIdentifier, to_string($1), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        res = new IR(kVacuumOptionElem, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_full:

    FULL {
        res = new IR(kOptFull, OP3("FULL", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptFull, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


vacuum_option_list:

    vacuum_option_elem {
        auto tmp1 = $1;
        res = new IR(kVacuumOptionList, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | vacuum_option_list ',' vacuum_option_elem {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kVacuumOptionList, OP3("", ",", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_freeze:

    FREEZE {
        res = new IR(kOptFreeze, OP3("FREEZE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptFreeze, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


DeleteStmt:

    opt_with_clause DELETE_P FROM relation_expr_opt_alias using_clause where_or_current_clause returning_clause {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kDeleteStmt_1, OP3("", "DELETE FROM", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $5;
        res = new IR(kDeleteStmt_2, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $6;
        res = new IR(kDeleteStmt_3, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        auto tmp5 = $7;
        res = new IR(kDeleteStmt, OP3("", "", ""), res, tmp5);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | TRUNCATE opt_table relation_expr_opt_alias {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kDeleteStmt, OP3("TRUNCATE", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


relation_expr_opt_alias:

    relation_expr %prec UMINUS {
        auto tmp1 = $1;
        res = new IR(kRelationExprOptAlias, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | relation_expr ColId {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kRelationExprOptAlias, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | relation_expr AS ColId {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kRelationExprOptAlias, OP3("", "AS", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


where_or_current_clause:

    WHERE a_expr {
        auto tmp1 = $2;
        res = new IR(kWhereOrCurrentClause, OP3("WHERE", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kWhereOrCurrentClause, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


using_clause:

    USING from_list_opt_comma {
        auto tmp1 = $2;
        res = new IR(kUsingClause, OP3("USING", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kUsingClause, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


AnalyzeStmt:

    analyze_keyword opt_verbose {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAnalyzeStmt, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | analyze_keyword opt_verbose qualified_name opt_name_list {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAnalyzeStmt_1, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $3;
        res = new IR(kAnalyzeStmt_2, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $4;
        res = new IR(kAnalyzeStmt, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


AttachStmt:

    ATTACH opt_database Sconst opt_database_alias copy_options {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAttachStmt_1, OP3("ATTACH", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $4;
        res = new IR(kAttachStmt_2, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $5;
        res = new IR(kAttachStmt, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


DetachStmt:

    DETACH opt_database IDENT {
        auto tmp1 = $2;
        auto tmp2 = new IR(kIdentifier, to_string($3), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp2);
        res = new IR(kDetachStmt, OP3("DETACH", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | DETACH DATABASE IF_P EXISTS IDENT {
        auto tmp1 = new IR(kIdentifier, to_string($5), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        res = new IR(kDetachStmt, OP3("DETACH DATABASE IF EXISTS", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_database:

    DATABASE {
        res = new IR(kOptDatabase, OP3("DATABASE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptDatabase, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_database_alias:

    AS ColId {
        auto tmp1 = $2;
        res = new IR(kOptDatabaseAlias, OP3("AS", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptDatabaseAlias, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


ident_name:

    IDENT {
        auto tmp1 = new IR(kIdentifier, to_string($1), kDataFixLater, 0, kFlagUnknown);
        ir_vec.push_back(tmp1);
        res = new IR(kIdentName, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


ident_list:

    ident_name {
        auto tmp1 = $1;
        res = new IR(kIdentList, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ident_list ',' ident_name {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kIdentList, OP3("", ",", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


VariableResetStmt:

    RESET reset_rest {
        auto tmp1 = $2;
        res = new IR(kVariableResetStmt, OP3("RESET", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | RESET LOCAL reset_rest {
        auto tmp1 = $3;
        res = new IR(kVariableResetStmt, OP3("RESET LOCAL", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | RESET SESSION reset_rest {
        auto tmp1 = $3;
        res = new IR(kVariableResetStmt, OP3("RESET SESSION", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | RESET GLOBAL reset_rest {
        auto tmp1 = $3;
        res = new IR(kVariableResetStmt, OP3("RESET GLOBAL", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


generic_reset:

    var_name {
        auto tmp1 = $1;
        res = new IR(kGenericReset, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | ALL {
        res = new IR(kGenericReset, OP3("ALL", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


reset_rest:

    generic_reset {
        auto tmp1 = $1;
        res = new IR(kResetRest, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | TIME ZONE {
        res = new IR(kResetRest, OP3("TIME ZONE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | TRANSACTION ISOLATION LEVEL {
        res = new IR(kResetRest, OP3("TRANSACTION ISOLATION LEVEL", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


VariableShowStmt:

    show_or_describe SelectStmt {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kVariableShowStmt, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | SUMMARIZE SelectStmt {
        auto tmp1 = $2;
        res = new IR(kVariableShowStmt, OP3("SUMMARIZE", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | SUMMARIZE table_id {
        auto tmp1 = $2;
        res = new IR(kVariableShowStmt, OP3("SUMMARIZE", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | show_or_describe table_id {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kVariableShowStmt, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | show_or_describe TIME ZONE {
        auto tmp1 = $1;
        res = new IR(kVariableShowStmt, OP3("", "TIME ZONE", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | show_or_describe TRANSACTION ISOLATION LEVEL {
        auto tmp1 = $1;
        res = new IR(kVariableShowStmt, OP3("", "TRANSACTION ISOLATION LEVEL", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | show_or_describe ALL opt_tables {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kVariableShowStmt, OP3("", "ALL", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | show_or_describe {
        auto tmp1 = $1;
        res = new IR(kVariableShowStmt, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


show_or_describe:

    SHOW {
        res = new IR(kShowOrDescribe, OP3("SHOW", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | DESCRIBE {
        res = new IR(kShowOrDescribe, OP3("DESCRIBE", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_tables:

    TABLES {
        res = new IR(kOptTables, OP3("TABLES", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptTables, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


var_name:

    ColId {
        auto tmp1 = $1;
        res = new IR(kVarName, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | var_name '.' ColId {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kVarName, OP3("", ".", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


table_id:

    ColId {
        auto tmp1 = $1;
        res = new IR(kTableId, OP3("", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | table_id '.' ColId {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTableId, OP3("", ".", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


CallStmt:

    CALL_P func_application {
        auto tmp1 = $2;
        res = new IR(kCallStmt, OP3("CALL", "", ""), tmp1);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


ViewStmt:

    CREATE_P OptTemp VIEW qualified_name opt_column_list opt_reloptions AS SelectStmt opt_check_option {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kViewStmt_1, OP3("CREATE", "VIEW", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $5;
        res = new IR(kViewStmt_2, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $6;
        res = new IR(kViewStmt_3, OP3("", "", "AS"), res, tmp4);
        ir_vec.push_back(res); 
        auto tmp5 = $8;
        res = new IR(kViewStmt_4, OP3("", "", ""), res, tmp5);
        ir_vec.push_back(res); 
        auto tmp6 = $9;
        res = new IR(kViewStmt, OP3("", "", ""), res, tmp6);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CREATE_P OptTemp VIEW IF_P NOT EXISTS qualified_name opt_column_list opt_reloptions AS SelectStmt opt_check_option {
        auto tmp1 = $2;
        auto tmp2 = $7;
        res = new IR(kViewStmt_5, OP3("CREATE", "VIEW IF NOT EXISTS", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $8;
        res = new IR(kViewStmt_6, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $9;
        res = new IR(kViewStmt_7, OP3("", "", "AS"), res, tmp4);
        ir_vec.push_back(res); 
        auto tmp5 = $11;
        res = new IR(kViewStmt_8, OP3("", "", ""), res, tmp5);
        ir_vec.push_back(res); 
        auto tmp6 = $12;
        res = new IR(kViewStmt, OP3("", "", ""), res, tmp6);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CREATE_P OR REPLACE OptTemp VIEW qualified_name opt_column_list opt_reloptions AS SelectStmt opt_check_option {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kViewStmt_9, OP3("CREATE OR REPLACE", "VIEW", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $7;
        res = new IR(kViewStmt_10, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $8;
        res = new IR(kViewStmt_11, OP3("", "", "AS"), res, tmp4);
        ir_vec.push_back(res); 
        auto tmp5 = $10;
        res = new IR(kViewStmt_12, OP3("", "", ""), res, tmp5);
        ir_vec.push_back(res); 
        auto tmp6 = $11;
        res = new IR(kViewStmt, OP3("", "", ""), res, tmp6);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CREATE_P OptTemp RECURSIVE VIEW qualified_name '(' columnList ')' opt_reloptions AS SelectStmt opt_check_option {
        auto tmp1 = $2;
        auto tmp2 = $5;
        res = new IR(kViewStmt_13, OP3("CREATE", "RECURSIVE VIEW", "("), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $7;
        res = new IR(kViewStmt_14, OP3("", "", ")"), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $9;
        res = new IR(kViewStmt_15, OP3("", "", "AS"), res, tmp4);
        ir_vec.push_back(res); 
        auto tmp5 = $11;
        res = new IR(kViewStmt_16, OP3("", "", ""), res, tmp5);
        ir_vec.push_back(res); 
        auto tmp6 = $12;
        res = new IR(kViewStmt, OP3("", "", ""), res, tmp6);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CREATE_P OR REPLACE OptTemp RECURSIVE VIEW qualified_name '(' columnList ')' opt_reloptions AS SelectStmt opt_check_option {
        auto tmp1 = $4;
        auto tmp2 = $7;
        res = new IR(kViewStmt_17, OP3("CREATE OR REPLACE", "RECURSIVE VIEW", "("), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $9;
        res = new IR(kViewStmt_18, OP3("", "", ")"), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $11;
        res = new IR(kViewStmt_19, OP3("", "", "AS"), res, tmp4);
        ir_vec.push_back(res); 
        auto tmp5 = $13;
        res = new IR(kViewStmt_20, OP3("", "", ""), res, tmp5);
        ir_vec.push_back(res); 
        auto tmp6 = $14;
        res = new IR(kViewStmt, OP3("", "", ""), res, tmp6);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_check_option:

    WITH CHECK_P OPTION {
        res = new IR(kOptCheckOption, OP3("WITH CHECK OPTION", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | WITH CASCADED CHECK_P OPTION {
        res = new IR(kOptCheckOption, OP3("WITH CASCADED CHECK OPTION", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | WITH LOCAL CHECK_P OPTION {
        res = new IR(kOptCheckOption, OP3("WITH LOCAL CHECK OPTION", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptCheckOption, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


CreateAsStmt:

    CREATE_P OptTemp TABLE create_as_target AS SelectStmt opt_with_data {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kCreateAsStmt_1, OP3("CREATE", "TABLE", "AS"), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $6;
        res = new IR(kCreateAsStmt_2, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $7;
        res = new IR(kCreateAsStmt, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CREATE_P OptTemp TABLE IF_P NOT EXISTS create_as_target AS SelectStmt opt_with_data {
        auto tmp1 = $2;
        auto tmp2 = $7;
        res = new IR(kCreateAsStmt_3, OP3("CREATE", "TABLE IF NOT EXISTS", "AS"), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $9;
        res = new IR(kCreateAsStmt_4, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $10;
        res = new IR(kCreateAsStmt, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        $$ = res;
    }

    | CREATE_P OR REPLACE OptTemp TABLE create_as_target AS SelectStmt opt_with_data {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kCreateAsStmt_5, OP3("CREATE OR REPLACE", "TABLE", "AS"), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $8;
        res = new IR(kCreateAsStmt_6, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $9;
        res = new IR(kCreateAsStmt, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
        $$ = res;
    }

;


opt_with_data:

    WITH DATA_P {
        res = new IR(kOptWithData, OP3("WITH DATA", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | WITH NO DATA_P {
        res = new IR(kOptWithData, OP3("WITH NO DATA", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptWithData, OP3("", "", ""));
        ir_vec.push_back(res); 
        $$ = res;
    }

;


create_as_target:

    qualified_name opt_column_list OptWith OnCommitOption {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCreateAsTarget_1, OP3("", "", ""), tmp1, tmp2);
        ir_vec.push_back(res); 
        auto tmp3 = $3;
        res = new IR(kCreateAsTarget_2, OP3("", "", ""), res, tmp3);
        ir_vec.push_back(res); 
        auto tmp4 = $4;
        res = new IR(kCreateAsTarget, OP3("", "", ""), res, tmp4);
        ir_vec.push_back(res); 
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
base_yyerror(YYLTYPE *yylloc, core_yyscan_t yyscanner, const char *msg)
{
	parser_yyerror(msg);
}

std::string to_string(char *str) {
   std::string res(str, strlen(str));
   return res;
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

