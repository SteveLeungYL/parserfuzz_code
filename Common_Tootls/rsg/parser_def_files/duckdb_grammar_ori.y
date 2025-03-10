%{
#line 1 "third_party/libpg_query/grammar/grammar.hpp"
/*#define YYDEBUG 1*/
/*-------------------------------------------------------------------------
 *
 * gram.y
 *	  POSTGRESQL BISON rules/actions
 *
 * Portions Copyright (c) 1996-2017, PostgreSQL Global Development PGGroup
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 *
 * IDENTIFICATION
 *	  src/backend/parser/gram.y
 *
 * HISTORY
 *	  AUTHOR			DATE			MAJOR EVENT
 *	  Andrew Yu			Sept, 1994		POSTQUEL to SQL conversion
 *	  Andrew Yu			Oct, 1994		lispy code conversion
 *
 * NOTES
 *	  CAPITALS are used to represent terminal symbols.
 *	  non-capitals are used to represent non-terminals.
 *
 *	  In general, nothing in this file should initiate database accesses
 *	  nor depend on changeable state (such as SET variables).  If you do
 *	  database accesses, your code will fail when we have aborted the
 *	  current transaction and are just parsing commands to find the next
 *	  ROLLBACK or COMMIT.  If you make use of SET variables, then you
 *	  will do the wrong thing in multi-query strings like this:
 *			SET constraint_exclusion TO off; SELECT * FROM foo;
 *	  because the entire string is parsed by gram.y before the SET gets
 *	  executed.  Anything that depends on the database or changeable state
 *	  should be handled during parse analysis so that it happens at the
 *	  right time not the wrong time.
 *
 * WARNINGS
 *	  If you use a list, make sure the datum is a node so that the printing
 *	  routines work.
 *
 *	  Sometimes we assign constants to makeStrings. Make sure we don't free
 *	  those.
 *
 *-------------------------------------------------------------------------
 */
#include "pg_functions.hpp"
#include <string.h>

#include <ctype.h>
#include <limits.h>

#include "nodes/makefuncs.hpp"
#include "nodes/nodeFuncs.hpp"
#include "parser/gramparse.hpp"
#include "parser/parser.hpp"
#include "utils/datetime.hpp"

namespace duckdb_libpgquery {
#define DEFAULT_SCHEMA "main"

/*
 * Location tracking support --- simpler than bison's default, since we only
 * want to track the start position not the end position of each nonterminal.
 */
#define YYLLOC_DEFAULT(Current, Rhs, N) \
	do { \
		if ((N) > 0) \
			(Current) = (Rhs)[1]; \
		else \
			(Current) = (-1); \
	} while (0)

/*
 * The above macro assigns -1 (unknown) as the parse location of any
 * nonterminal that was reduced from an empty rule, or whose leftmost
 * component was reduced from an empty rule.  This is problematic
 * for nonterminals defined like
 *		OptFooList: / * EMPTY * / { ... } | OptFooList Foo { ... } ;
 * because we'll set -1 as the location during the first reduction and then
 * copy it during each subsequent reduction, leaving us with -1 for the
 * location even when the list is not empty.  To fix that, do this in the
 * action for the nonempty rule(s):
 *		if (@$ < 0) @$ = @2;
 * (Although we have many nonterminals that follow this pattern, we only
 * bother with fixing @$ like this when the nonterminal's parse location
 * is actually referenced in some rule.)
 *
 * A cleaner answer would be to make YYLLOC_DEFAULT scan all the Rhs
 * locations until it's found one that's not -1.  Then we'd get a correct
 * location for any nonterminal that isn't entirely empty.  But this way
 * would add overhead to every rule reduction, and so far there's not been
 * a compelling reason to pay that overhead.
 */

/*
 * Bison doesn't allocate anything that needs to live across parser calls,
 * so we can easily have it use palloc instead of malloc.  This prevents
 * memory leaks if we error out during parsing.  Note this only works with
 * bison >= 2.0.  However, in bison 1.875 the default is to use alloca()
 * if possible, so there's not really much problem anyhow, at least if
 * you're building with gcc.
 */
#define YYMALLOC palloc
#define YYFREE   pfree
#define YYINITDEPTH 1000

/* yields an integer bitmask of these flags: */
#define CAS_NOT_DEFERRABLE			0x01
#define CAS_DEFERRABLE				0x02
#define CAS_INITIALLY_IMMEDIATE		0x04
#define CAS_INITIALLY_DEFERRED		0x08
#define CAS_NOT_VALID				0x10
#define CAS_NO_INHERIT				0x20


#define parser_yyerror(msg)  scanner_yyerror(msg, yyscanner)
#define parser_errposition(pos)  scanner_errposition(pos, yyscanner)

static void base_yyerror(YYLTYPE *yylloc, core_yyscan_t yyscanner,
						 const char *msg);
static PGRawStmt *makeRawStmt(PGNode *stmt, int stmt_location);
static void updateRawStmtEnd(PGRawStmt *rs, int end_location);
static PGNode *makeColumnRef(char *colname, PGList *indirection,
						   int location, core_yyscan_t yyscanner);
static PGNode *makeTypeCast(PGNode *arg, PGTypeName *tpname, int trycast, int location);
static PGNode *makeStringConst(char *str, int location);
static PGNode *makeStringConstCast(char *str, int location, PGTypeName *tpname);
static PGNode *makeIntervalNode(char *str, int location, PGList *typmods);
static PGNode *makeIntervalNode(int val, int location, PGList *typmods);
static PGNode *makeIntervalNode(PGNode *arg, int location, PGList *typmods);
static PGNode *makeSampleSize(PGValue *sample_size, bool is_percentage);
static PGNode *makeSampleOptions(PGNode *sample_size, char *method, int *seed, int location);
static PGNode *makeIntConst(int val, int location);
static PGNode *makeFloatConst(char *str, int location);
static PGNode *makeBitStringConst(char *str, int location);
static PGNode *makeNullAConst(int location);
static PGNode *makeAConst(PGValue *v, int location);
static PGNode *makeBoolAConst(bool state, int location);
static PGNode *makeParamRef(int number, int location);
static PGNode *makeNamedParamRef(char* name, int location);
static void check_qualified_name(PGList *names, core_yyscan_t yyscanner);
static PGList *check_func_name(PGList *names, core_yyscan_t yyscanner);
static PGList *check_indirection(PGList *indirection, core_yyscan_t yyscanner);
static void insertSelectOptions(PGSelectStmt *stmt,
								PGList *sortClause, PGList *lockingClause,
								PGNode *limitOffset, PGNode *limitCount,
								PGWithClause *withClause,
								core_yyscan_t yyscanner);
static PGNode *makeSetOp(PGSetOperation op, bool all, PGNode *larg, PGNode *rarg);
static PGNode *doNegate(PGNode *n, int location);
static void doNegateFloat(PGValue *v);
static PGNode *makeAndExpr(PGNode *lexpr, PGNode *rexpr, int location);
static PGNode *makeOrExpr(PGNode *lexpr, PGNode *rexpr, int location);
static PGNode *makeNotExpr(PGNode *expr, int location);
static void SplitColQualList(PGList *qualList,
							 PGList **constraintList, PGCollateClause **collClause,
							 core_yyscan_t yyscanner);
static void processCASbits(int cas_bits, int location, const char *constrType,
			   bool *deferrable, bool *initdeferred, bool *not_valid,
			   bool *no_inherit, core_yyscan_t yyscanner);
static PGNode *makeRecursiveViewSelect(char *relname, PGList *aliases, PGNode *query);
static PGNode *makeLimitPercent(PGNode *limit_percent);

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

%type <node> stmt
%type <list> stmtblock
%type <list> stmtmulti
%type <list> SeqOptList
%type <value> NumericOnly
%type <defelt> SeqOptElem
%type <ival> SignedIconst
%type <list> alter_identity_column_option_list
%type <node> alter_column_default
%type <defelt> alter_identity_column_option
%type <list> alter_generic_option_list
%type <node> alter_table_cmd
%type <node> alter_using
%type <defelt> alter_generic_option_elem
%type <list> alter_table_cmds
%type <list> alter_generic_options
%type <ival> opt_set_data
%type <str> opt_database_alias
%type <list> ident_list ident_name
%type <str> opt_col_id
%type <range>	qualified_name
%type <str>		Sconst  ColId   ColLabel    ColIdOrString
%type <keyword> unreserved_keyword  reserved_keyword other_keyword
%type <list> indirection
%type <keyword> col_name_keyword
%type <node>    indirection_el
%type <str>	    attr_name%type <boolean> copy_from
%type <defelt> copy_delimiter
%type <list> copy_generic_opt_arg_list
%type <ival> opt_as
%type <boolean> opt_program
%type <list> copy_options
%type <node> copy_generic_opt_arg
%type <defelt> copy_generic_opt_elem
%type <defelt> opt_oids
%type <list> copy_opt_list
%type <defelt> opt_binary
%type <defelt> copy_opt_item
%type <node> copy_generic_opt_arg_list_item
%type <str> copy_file_name
%type <list> copy_generic_opt_list
%type <ival> ConstraintAttributeSpec
%type <node> def_arg
%type <list> OptParenthesizedSeqOptList
%type <node> generic_option_arg
%type <ival> key_action
%type <node> ColConstraint
%type <node> ColConstraintElem
%type <defelt> generic_option_elem
%type <ival> key_update
%type <ival> key_actions
%type <oncommit> OnCommitOption
%type <list> reloptions
%type <boolean> opt_no_inherit
%type <node> TableConstraint
%type <ival> TableLikeOption
%type <list> reloption_list
%type <str> ExistingIndex
%type <node> ConstraintAttr
%type <list> OptWith
%type <list> definition
%type <ival> TableLikeOptionList
%type <str> generic_option_name
%type <ival> ConstraintAttributeElem
%type <node> columnDef
%type <list> def_list
%type <str> index_name
%type <node> TableElement
%type <defelt> def_elem
%type <list> opt_definition
%type <list> OptTableElementList
%type <node> columnElem
%type <list> opt_column_list
%type <list> ColQualList
%type <ival> key_delete
%type <defelt> reloption_elem
%type <list> columnList columnList_opt_comma
%type <typnam> func_type
%type <constr> GeneratedColumnType opt_GeneratedColumnType
%type <node> ConstraintElem GeneratedConstraintElem
%type <list> TableElementList
%type <ival> key_match
%type <node> TableLikeClause
%type <ival> OptTemp
%type <ival> generated_when
%type <boolean> opt_with_data
%type <into> create_as_target
%type <list> param_list
%type <list> OptSchemaEltList
%type <node> schema_stmt
%type <list> OptSeqOptList
%type <list> opt_enum_val_list
%type <list> enum_val_list
%type <range> relation_expr_opt_alias
%type <node> where_or_current_clause
%type <list> using_clause
%type <objtype> drop_type_any_name
%type <objtype> drop_type_name
%type <list> any_name_list
%type <dbehavior> opt_drop_behavior
%type <objtype> drop_type_name_on_any_name
%type <list> type_name_list
%type <list> execute_param_clause
%type <list> execute_param_list
%type <node> execute_param_expr%type <boolean> opt_verbose
%type <node> explain_option_arg
%type <node> ExplainableStmt
%type <str> NonReservedWord
%type <str> NonReservedWord_or_Sconst
%type <list> explain_option_list
%type <str> opt_boolean_or_string
%type <defelt> explain_option_elem
%type <str> explain_option_name
%type <str> access_method
%type <str> access_method_clause
%type <boolean> opt_concurrently
%type <str> opt_index_name
%type <list> opt_reloptions
%type <boolean> opt_unique
%type <istmt> insert_rest
%type <range> insert_target
%type <infer> opt_conf_expr
%type <with> opt_with_clause
%type <target> insert_column_item
%type <list> set_clause
%type <onconflict> opt_on_conflict
%type <onconflictshorthand> opt_or_action
%type <bynameorposition> opt_by_name_or_position
%type <ielem> index_elem
%type <list> returning_clause
%type <override> override_kind
%type <list> set_target_list
%type <list> opt_collate
%type <list> opt_class
%type <list> insert_column_list
%type <list> set_clause_list set_clause_list_opt_comma
%type <list> index_params
%type <target> set_target
%type <str> file_name
%type <str> repo_path
%type <list> prep_type_clause
%type <node> PreparableStmt
%type <ival> opt_column%type <node>	select_no_parens select_with_parens select_clause
				simple_select values_clause values_clause_opt_comma


%type <sortorder> opt_asc_desc
%type <nullorder> opt_nulls_order

%type <node> opt_collate_clause

%type <node> indirection_expr
%type <node> struct_expr


%type <lockwaitpolicy>	opt_nowait_or_skip

%type <str> name
%type <list>	func_name qual_Op qual_all_Op subquery_Op

%type <str>		all_Op
%type <conststr> MathOp

%type <list>	distinct_clause opt_all_clause name_list_opt_comma opt_name_list name_list_opt_comma_opt_bracket
				sort_clause opt_sort_clause sortby_list name_list from_clause from_list from_list_opt_comma opt_array_bounds
				qualified_name_list any_name 				any_operator expr_list	attrs expr_list_opt_comma opt_expr_list_opt_comma c_expr_list c_expr_list_opt_comma
				target_list			 			 opt_indirection target_list_opt_comma opt_target_list_opt_comma
			 group_clause select_limit
				opt_select_limit 			 			 TableFuncElementList opt_type_modifiers opt_select extended_indirection opt_extended_indirection
%type <list>	group_by_list group_by_list_opt_comma opt_func_arguments unpivot_header
%type <node>	group_by_item empty_grouping_set rollup_clause cube_clause grouping_sets_clause grouping_or_grouping_id
%type <range>	OptTempTableName
%type <into>	into_clause

%type <lockstrength>	for_locking_strength
%type <node>	for_locking_item
%type <list>	for_locking_clause opt_for_locking_clause for_locking_items
%type <list>	locked_rels_list
%type <boolean>	all_or_distinct

%type <node>	join_outer join_qual
%type <jtype>	join_type

%type <list>	extract_list overlay_list position_list
%type <list>	substr_list trim_list
%type <list>	opt_interval
%type <node>	overlay_placing substr_from substr_for

%type <list>	except_list opt_except_list replace_list_el replace_list opt_replace_list replace_list_opt_comma

%type <node> limit_clause select_limit_value
				offset_clause select_offset_value
				select_fetch_first_value I_or_F_const
%type <ival>	row_or_rows first_or_next



%type <node> TableFuncElement


%type <node> where_clause 				a_expr b_expr c_expr d_expr AexprConst opt_slice_bound extended_indirection_el
				columnref in_expr having_clause qualify_clause func_table
%type <list>	rowsfrom_item rowsfrom_list opt_col_def_list
%type <boolean> opt_ordinality
%type <boolean> opt_ignore_nulls
%type <list>	func_arg_list
%type <node>	func_arg_expr
%type <node>	list_comprehension
%type <list>	row qualified_row type_list colid_type_list
%type <node>	case_expr case_arg when_clause case_default
%type <list>	when_clause_list
%type <subquerytype>	sub_type

%type <node>	dict_arg
%type <list>	dict_arguments dict_arguments_opt_comma

%type <list>	map_arg map_arguments map_arguments_opt_comma opt_map_arguments_opt_comma

%type <alias>	alias_clause opt_alias_clause
%type <list>	func_alias_clause
%type <sortby>	sortby

%type <node>	table_ref
%type <jexpr>	joined_table
%type <range>	relation_expr

%type <node>	tablesample_clause opt_tablesample_clause tablesample_entry
%type <node>	sample_clause sample_count
%type <str>	opt_sample_func
%type <ival>	opt_repeatable_clause

%type <target>	target_el



%type <typnam>	Typename SimpleTypename ConstTypename opt_Typename
				GenericType Numeric opt_float
				Character ConstCharacter
				CharacterWithLength CharacterWithoutLength
				ConstDatetime ConstInterval
				Bit ConstBit BitWithLength BitWithoutLength
%type <conststr>		character
%type <str>		extract_arg
%type <boolean> opt_varying opt_timezone
%type <ival>	Iconst
%type <str>		type_function_name param_name type_name_token function_name_token
%type <str>		ColLabelOrString

%type <keyword> type_func_name_keyword type_name_keyword func_name_keyword




%type <node>	func_application func_expr_common_subexpr
%type <node>	func_expr func_expr_windowless
%type <node>	common_table_expr
%type <with>	with_clause
%type <list>	cte_list
%type <ctematerialize>	opt_materialized

%type <list>	within_group_clause
%type <node>	filter_clause
%type <boolean>	export_clause

%type <list>	window_clause window_definition_list opt_partition_clause
%type <windef>	window_definition over_clause window_specification
				opt_frame_clause frame_extent frame_bound
%type <str>		opt_existing_window_name

%type <node> pivot_value pivot_column_entry single_pivot_value unpivot_value
%type <list> pivot_value_list pivot_column_list_internal pivot_column_list pivot_header opt_pivot_group_by unpivot_value_list
%type <boolean> opt_include_nulls%type <ival> vacuum_option_elem
%type <boolean> opt_full
%type <ival> vacuum_option_list
%type <boolean> opt_freeze
%type <vsetstmt> generic_reset
%type <vsetstmt> reset_rest
%type <vsetstmt> set_rest
%type <vsetstmt> generic_set
%type <node> var_value
%type <node> zone_value
%type <list> var_list
%type <str> var_name
%type <str> table_id
%type <viewcheckoption> opt_check_option
%type <node> AlterObjectSchemaStmt
%type <node> AlterSeqStmt
%type <node> AlterTableStmt
%type <node> AnalyzeStmt
%type <node> AttachStmt
%type <node> CallStmt
%type <node> CheckPointStmt
%type <node> CopyStmt
%type <node> CreateAsStmt
%type <node> CreateFunctionStmt
%type <node> CreateSchemaStmt
%type <node> CreateSeqStmt
%type <node> CreateStmt
%type <node> CreateTypeStmt
%type <node> DeallocateStmt
%type <node> DeleteStmt
%type <node> DetachStmt
%type <node> DropStmt
%type <node> ExecuteStmt
%type <node> ExplainStmt
%type <node> ExportStmt
%type <node> ImportStmt
%type <node> IndexStmt
%type <node> InsertStmt
%type <node> LoadStmt
%type <node> PragmaStmt
%type <node> PrepareStmt
%type <node> RenameStmt
%type <node> SelectStmt
%type <node> TransactionStmt
%type <node> UpdateStmt
%type <node> UseStmt
%type <node> VacuumStmt
%type <node> VariableResetStmt
%type <node> VariableSetStmt
%type <node> VariableShowStmt
%type <node> ViewStmt


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

/*
 *	The target production for the whole parse.
 */
stmtblock:	stmtmulti
			{
				pg_yyget_extra(yyscanner)->parsetree = $1;
			}
		;

/*
 * At top level, we wrap each stmt with a PGRawStmt node carrying start location
 * and length of the stmt's text.  Notice that the start loc/len are driven
 * entirely from semicolon locations (@2).  It would seem natural to use
 * @1 or @3 to get the true start location of a stmt, but that doesn't work
 * for statements that can start with empty nonterminals (opt_with_clause is
 * the main offender here); as noted in the comments for YYLLOC_DEFAULT,
 * we'd get -1 for the location in such cases.
 * We also take care to discard empty statements entirely.
 */
stmtmulti:	stmtmulti ';' stmt
				{
					if ($1 != NIL)
					{
						/* update length of previous stmt */
						updateRawStmtEnd(llast_node(PGRawStmt, $1), @2);
					}
					if ($3 != NULL)
						$$ = lappend($1, makeRawStmt($3, @2 + 1));
					else
						$$ = $1;
				}
			| stmt
				{
					if ($1 != NULL)
						$$ = list_make1(makeRawStmt($1, 0));
					else
						$$ = NIL;
				}
		;

stmt: AlterObjectSchemaStmt
	| AlterSeqStmt
	| AlterTableStmt
	| AnalyzeStmt
	| AttachStmt
	| CallStmt
	| CheckPointStmt
	| CopyStmt
	| CreateAsStmt
	| CreateFunctionStmt
	| CreateSchemaStmt
	| CreateSeqStmt
	| CreateStmt
	| CreateTypeStmt
	| DeallocateStmt
	| DeleteStmt
	| DetachStmt
	| DropStmt
	| ExecuteStmt
	| ExplainStmt
	| ExportStmt
	| ImportStmt
	| IndexStmt
	| InsertStmt
	| LoadStmt
	| PragmaStmt
	| PrepareStmt
	| RenameStmt
	| SelectStmt
	| TransactionStmt
	| UpdateStmt
	| UseStmt
	| VacuumStmt
	| VariableResetStmt
	| VariableSetStmt
	| VariableShowStmt
	| ViewStmt
	| /*EMPTY*/
	{ $$ = NULL; }


#line 1 "third_party/libpg_query/grammar/statements/alter_schema.y"
/*****************************************************************************
 *
 * ALTER THING name SET SCHEMA name
 *
 *****************************************************************************/
AlterObjectSchemaStmt:
			ALTER TABLE relation_expr SET SCHEMA name
				{
					PGAlterObjectSchemaStmt *n = makeNode(PGAlterObjectSchemaStmt);
					n->objectType = PG_OBJECT_TABLE;
					n->relation = $3;
					n->newschema = $6;
					n->missing_ok = false;
					$$ = (PGNode *)n;
				}
			| ALTER TABLE IF_P EXISTS relation_expr SET SCHEMA name
				{
					PGAlterObjectSchemaStmt *n = makeNode(PGAlterObjectSchemaStmt);
					n->objectType = PG_OBJECT_TABLE;
					n->relation = $5;
					n->newschema = $8;
					n->missing_ok = true;
					$$ = (PGNode *)n;
				}
			| ALTER SEQUENCE qualified_name SET SCHEMA name
				{
					PGAlterObjectSchemaStmt *n = makeNode(PGAlterObjectSchemaStmt);
					n->objectType = PG_OBJECT_SEQUENCE;
					n->relation = $3;
					n->newschema = $6;
					n->missing_ok = false;
					$$ = (PGNode *)n;
				}
			| ALTER SEQUENCE IF_P EXISTS qualified_name SET SCHEMA name
				{
					PGAlterObjectSchemaStmt *n = makeNode(PGAlterObjectSchemaStmt);
					n->objectType = PG_OBJECT_SEQUENCE;
					n->relation = $5;
					n->newschema = $8;
					n->missing_ok = true;
					$$ = (PGNode *)n;
				}
			| ALTER VIEW qualified_name SET SCHEMA name
				{
					PGAlterObjectSchemaStmt *n = makeNode(PGAlterObjectSchemaStmt);
					n->objectType = PG_OBJECT_VIEW;
					n->relation = $3;
					n->newschema = $6;
					n->missing_ok = false;
					$$ = (PGNode *)n;
				}
			| ALTER VIEW IF_P EXISTS qualified_name SET SCHEMA name
				{
					PGAlterObjectSchemaStmt *n = makeNode(PGAlterObjectSchemaStmt);
					n->objectType = PG_OBJECT_VIEW;
					n->relation = $5;
					n->newschema = $8;
					n->missing_ok = true;
					$$ = (PGNode *)n;
				}
		;
#line 1 "third_party/libpg_query/grammar/statements/alter_sequence.y"
/*****************************************************************************
 *
 *		QUERY :
 *				CREATE SEQUENCE seqname
 *				ALTER SEQUENCE seqname
 *
 *****************************************************************************/
AlterSeqStmt:
			ALTER SEQUENCE qualified_name SeqOptList
				{
					PGAlterSeqStmt *n = makeNode(PGAlterSeqStmt);
					n->sequence = $3;
					n->options = $4;
					n->missing_ok = false;
					$$ = (PGNode *)n;
				}
			| ALTER SEQUENCE IF_P EXISTS qualified_name SeqOptList
				{
					PGAlterSeqStmt *n = makeNode(PGAlterSeqStmt);
					n->sequence = $5;
					n->options = $6;
					n->missing_ok = true;
					$$ = (PGNode *)n;
				}

		;


SeqOptList: SeqOptElem								{ $$ = list_make1($1); }
			| SeqOptList SeqOptElem					{ $$ = lappend($1, $2); }
		;


opt_with:	WITH									{}
			| WITH_LA								{}
			| /*EMPTY*/								{}
		;


NumericOnly:
			FCONST								{ $$ = makeFloat($1); }
			| '+' FCONST						{ $$ = makeFloat($2); }
			| '-' FCONST
				{
					$$ = makeFloat($2);
					doNegateFloat($$);
				}
			| SignedIconst						{ $$ = makeInteger($1); }
		;


SeqOptElem: AS SimpleTypename
				{
					$$ = makeDefElem("as", (PGNode *)$2, @1);
				}
			| CACHE NumericOnly
				{
					$$ = makeDefElem("cache", (PGNode *)$2, @1);
				}
			| CYCLE
				{
					$$ = makeDefElem("cycle", (PGNode *)makeInteger(true), @1);
				}
			| NO CYCLE
				{
					$$ = makeDefElem("cycle", (PGNode *)makeInteger(false), @1);
				}
			| INCREMENT opt_by NumericOnly
				{
					$$ = makeDefElem("increment", (PGNode *)$3, @1);
				}
			| MAXVALUE NumericOnly
				{
					$$ = makeDefElem("maxvalue", (PGNode *)$2, @1);
				}
			| MINVALUE NumericOnly
				{
					$$ = makeDefElem("minvalue", (PGNode *)$2, @1);
				}
			| NO MAXVALUE
				{
					$$ = makeDefElem("maxvalue", NULL, @1);
				}
			| NO MINVALUE
				{
					$$ = makeDefElem("minvalue", NULL, @1);
				}
			| OWNED BY any_name
				{
					$$ = makeDefElem("owned_by", (PGNode *)$3, @1);
				}
			| SEQUENCE NAME_P any_name
				{
					/* not documented, only used by pg_dump */
					$$ = makeDefElem("sequence_name", (PGNode *)$3, @1);
				}
			| START opt_with NumericOnly
				{
					$$ = makeDefElem("start", (PGNode *)$3, @1);
				}
			| RESTART
				{
					$$ = makeDefElem("restart", NULL, @1);
				}
			| RESTART opt_with NumericOnly
				{
					$$ = makeDefElem("restart", (PGNode *)$3, @1);
				}
		;


opt_by:		BY				{}
			| /* empty */	{}
	  ;


SignedIconst: Iconst								{ $$ = $1; }
			| '+' Iconst							{ $$ = + $2; }
			| '-' Iconst							{ $$ = - $2; }
		;
#line 1 "third_party/libpg_query/grammar/statements/alter_table.y"
/*****************************************************************************
 *
 *	ALTER [ TABLE | INDEX | SEQUENCE | VIEW | MATERIALIZED VIEW ] variations
 *
 * Note: we accept all subcommands for each of the five variants, and sort
 * out what's really legal at execution time.
 *****************************************************************************/
AlterTableStmt:
			ALTER TABLE relation_expr alter_table_cmds
				{
					PGAlterTableStmt *n = makeNode(PGAlterTableStmt);
					n->relation = $3;
					n->cmds = $4;
					n->relkind = PG_OBJECT_TABLE;
					n->missing_ok = false;
					$$ = (PGNode *)n;
				}
		|	ALTER TABLE IF_P EXISTS relation_expr alter_table_cmds
				{
					PGAlterTableStmt *n = makeNode(PGAlterTableStmt);
					n->relation = $5;
					n->cmds = $6;
					n->relkind = PG_OBJECT_TABLE;
					n->missing_ok = true;
					$$ = (PGNode *)n;
				}
		|	ALTER INDEX qualified_name alter_table_cmds
				{
					PGAlterTableStmt *n = makeNode(PGAlterTableStmt);
					n->relation = $3;
					n->cmds = $4;
					n->relkind = PG_OBJECT_INDEX;
					n->missing_ok = false;
					$$ = (PGNode *)n;
				}
		|	ALTER INDEX IF_P EXISTS qualified_name alter_table_cmds
				{
					PGAlterTableStmt *n = makeNode(PGAlterTableStmt);
					n->relation = $5;
					n->cmds = $6;
					n->relkind = PG_OBJECT_INDEX;
					n->missing_ok = true;
					$$ = (PGNode *)n;
				}
		|	ALTER SEQUENCE qualified_name alter_table_cmds
				{
					PGAlterTableStmt *n = makeNode(PGAlterTableStmt);
					n->relation = $3;
					n->cmds = $4;
					n->relkind = PG_OBJECT_SEQUENCE;
					n->missing_ok = false;
					$$ = (PGNode *)n;
				}
		|	ALTER SEQUENCE IF_P EXISTS qualified_name alter_table_cmds
				{
					PGAlterTableStmt *n = makeNode(PGAlterTableStmt);
					n->relation = $5;
					n->cmds = $6;
					n->relkind = PG_OBJECT_SEQUENCE;
					n->missing_ok = true;
					$$ = (PGNode *)n;
				}
		|	ALTER VIEW qualified_name alter_table_cmds
				{
					PGAlterTableStmt *n = makeNode(PGAlterTableStmt);
					n->relation = $3;
					n->cmds = $4;
					n->relkind = PG_OBJECT_VIEW;
					n->missing_ok = false;
					$$ = (PGNode *)n;
				}
		|	ALTER VIEW IF_P EXISTS qualified_name alter_table_cmds
				{
					PGAlterTableStmt *n = makeNode(PGAlterTableStmt);
					n->relation = $5;
					n->cmds = $6;
					n->relkind = PG_OBJECT_VIEW;
					n->missing_ok = true;
					$$ = (PGNode *)n;
				}
		;


alter_identity_column_option_list:
			alter_identity_column_option
				{ $$ = list_make1($1); }
			| alter_identity_column_option_list alter_identity_column_option
				{ $$ = lappend($1, $2); }
		;


alter_column_default:
			SET DEFAULT a_expr			{ $$ = $3; }
			| DROP DEFAULT				{ $$ = NULL; }
		;


alter_identity_column_option:
			RESTART
				{
					$$ = makeDefElem("restart", NULL, @1);
				}
			| RESTART opt_with NumericOnly
				{
					$$ = makeDefElem("restart", (PGNode *)$3, @1);
				}
			| SET SeqOptElem
				{
					if (strcmp($2->defname, "as") == 0 ||
						strcmp($2->defname, "restart") == 0 ||
						strcmp($2->defname, "owned_by") == 0)
						ereport(ERROR,
								(errcode(PG_ERRCODE_SYNTAX_ERROR),
								 errmsg("sequence option \"%s\" not supported here", $2->defname),
								 parser_errposition(@2)));
					$$ = $2;
				}
			| SET GENERATED generated_when
				{
					$$ = makeDefElem("generated", (PGNode *) makeInteger($3), @1);
				}
		;


alter_generic_option_list:
			alter_generic_option_elem
				{
					$$ = list_make1($1);
				}
			| alter_generic_option_list ',' alter_generic_option_elem
				{
					$$ = lappend($1, $3);
				}
		;


alter_table_cmd:
			/* ALTER TABLE <name> ADD <coldef> */
			ADD_P columnDef
				{
					PGAlterTableCmd *n = makeNode(PGAlterTableCmd);
					n->subtype = PG_AT_AddColumn;
					n->def = $2;
					n->missing_ok = false;
					$$ = (PGNode *)n;
				}
			/* ALTER TABLE <name> ADD IF NOT EXISTS <coldef> */
			| ADD_P IF_P NOT EXISTS columnDef
				{
					PGAlterTableCmd *n = makeNode(PGAlterTableCmd);
					n->subtype = PG_AT_AddColumn;
					n->def = $5;
					n->missing_ok = true;
					$$ = (PGNode *)n;
				}
			/* ALTER TABLE <name> ADD COLUMN <coldef> */
			| ADD_P COLUMN columnDef
				{
					PGAlterTableCmd *n = makeNode(PGAlterTableCmd);
					n->subtype = PG_AT_AddColumn;
					n->def = $3;
					n->missing_ok = false;
					$$ = (PGNode *)n;
				}
			/* ALTER TABLE <name> ADD COLUMN IF NOT EXISTS <coldef> */
			| ADD_P COLUMN IF_P NOT EXISTS columnDef
				{
					PGAlterTableCmd *n = makeNode(PGAlterTableCmd);
					n->subtype = PG_AT_AddColumn;
					n->def = $6;
					n->missing_ok = true;
					$$ = (PGNode *)n;
				}
			/* ALTER TABLE <name> ALTER [COLUMN] <colname> {SET DEFAULT <expr>|DROP DEFAULT} */
			| ALTER opt_column ColId alter_column_default
				{
					PGAlterTableCmd *n = makeNode(PGAlterTableCmd);
					n->subtype = PG_AT_ColumnDefault;
					n->name = $3;
					n->def = $4;
					$$ = (PGNode *)n;
				}
			/* ALTER TABLE <name> ALTER [COLUMN] <colname> DROP NOT NULL */
			| ALTER opt_column ColId DROP NOT NULL_P
				{
					PGAlterTableCmd *n = makeNode(PGAlterTableCmd);
					n->subtype = PG_AT_DropNotNull;
					n->name = $3;
					$$ = (PGNode *)n;
				}
			/* ALTER TABLE <name> ALTER [COLUMN] <colname> SET NOT NULL */
			| ALTER opt_column ColId SET NOT NULL_P
				{
					PGAlterTableCmd *n = makeNode(PGAlterTableCmd);
					n->subtype = PG_AT_SetNotNull;
					n->name = $3;
					$$ = (PGNode *)n;
				}
			/* ALTER TABLE <name> ALTER [COLUMN] <colname> SET STATISTICS <SignedIconst> */
			| ALTER opt_column ColId SET STATISTICS SignedIconst
				{
					PGAlterTableCmd *n = makeNode(PGAlterTableCmd);
					n->subtype = PG_AT_SetStatistics;
					n->name = $3;
					n->def = (PGNode *) makeInteger($6);
					$$ = (PGNode *)n;
				}
			/* ALTER TABLE <name> ALTER [COLUMN] <colname> SET ( column_parameter = value [, ... ] ) */
			| ALTER opt_column ColId SET reloptions
				{
					PGAlterTableCmd *n = makeNode(PGAlterTableCmd);
					n->subtype = PG_AT_SetOptions;
					n->name = $3;
					n->def = (PGNode *) $5;
					$$ = (PGNode *)n;
				}
			/* ALTER TABLE <name> ALTER [COLUMN] <colname> RESET ( column_parameter = value [, ... ] ) */
			| ALTER opt_column ColId RESET reloptions
				{
					PGAlterTableCmd *n = makeNode(PGAlterTableCmd);
					n->subtype = PG_AT_ResetOptions;
					n->name = $3;
					n->def = (PGNode *) $5;
					$$ = (PGNode *)n;
				}
			/* ALTER TABLE <name> ALTER [COLUMN] <colname> SET STORAGE <storagemode> */
			| ALTER opt_column ColId SET STORAGE ColId
				{
					PGAlterTableCmd *n = makeNode(PGAlterTableCmd);
					n->subtype = PG_AT_SetStorage;
					n->name = $3;
					n->def = (PGNode *) makeString($6);
					$$ = (PGNode *)n;
				}
			/* ALTER TABLE <name> ALTER [COLUMN] <colname> ADD GENERATED ... AS IDENTITY ... */
			| ALTER opt_column ColId ADD_P GENERATED generated_when AS IDENTITY_P OptParenthesizedSeqOptList
				{
					PGAlterTableCmd *n = makeNode(PGAlterTableCmd);
					PGConstraint *c = makeNode(PGConstraint);

					c->contype = PG_CONSTR_IDENTITY;
					c->generated_when = $6;
					c->options = $9;
					c->location = @5;

					n->subtype = PG_AT_AddIdentity;
					n->name = $3;
					n->def = (PGNode *) c;

					$$ = (PGNode *)n;
				}
			/* ALTER TABLE <name> ALTER [COLUMN] <colname> SET <sequence options>/RESET */
			| ALTER opt_column ColId alter_identity_column_option_list
				{
					PGAlterTableCmd *n = makeNode(PGAlterTableCmd);
					n->subtype = PG_AT_SetIdentity;
					n->name = $3;
					n->def = (PGNode *) $4;
					$$ = (PGNode *)n;
				}
			/* ALTER TABLE <name> ALTER [COLUMN] <colname> DROP IDENTITY */
			| ALTER opt_column ColId DROP IDENTITY_P
				{
					PGAlterTableCmd *n = makeNode(PGAlterTableCmd);
					n->subtype = AT_DropIdentity;
					n->name = $3;
					n->missing_ok = false;
					$$ = (PGNode *)n;
				}
			/* ALTER TABLE <name> ALTER [COLUMN] <colname> DROP IDENTITY IF EXISTS */
			| ALTER opt_column ColId DROP IDENTITY_P IF_P EXISTS
				{
					PGAlterTableCmd *n = makeNode(PGAlterTableCmd);
					n->subtype = AT_DropIdentity;
					n->name = $3;
					n->missing_ok = true;
					$$ = (PGNode *)n;
				}
			/* ALTER TABLE <name> DROP [COLUMN] IF EXISTS <colname> [RESTRICT|CASCADE] */
			| DROP opt_column IF_P EXISTS ColId opt_drop_behavior
				{
					PGAlterTableCmd *n = makeNode(PGAlterTableCmd);
					n->subtype = PG_AT_DropColumn;
					n->name = $5;
					n->behavior = $6;
					n->missing_ok = true;
					$$ = (PGNode *)n;
				}
			/* ALTER TABLE <name> DROP [COLUMN] <colname> [RESTRICT|CASCADE] */
			| DROP opt_column ColId opt_drop_behavior
				{
					PGAlterTableCmd *n = makeNode(PGAlterTableCmd);
					n->subtype = PG_AT_DropColumn;
					n->name = $3;
					n->behavior = $4;
					n->missing_ok = false;
					$$ = (PGNode *)n;
				}
			/*
			 * ALTER TABLE <name> ALTER [COLUMN] <colname> [SET DATA] TYPE <typename>
			 *		[ USING <expression> ] [RESTRICT|CASCADE]
			 */
			| ALTER opt_column ColId opt_set_data TYPE_P Typename opt_collate_clause alter_using
				{
					PGAlterTableCmd *n = makeNode(PGAlterTableCmd);
					PGColumnDef *def = makeNode(PGColumnDef);
					n->subtype = PG_AT_AlterColumnType;
					n->name = $3;
					n->def = (PGNode *) def;
					/* We only use these fields of the PGColumnDef node */
					def->typeName = $6;
					def->collClause = (PGCollateClause *) $7;
					def->raw_default = $8;
					def->location = @3;
					$$ = (PGNode *)n;
				}
			/* ALTER FOREIGN TABLE <name> ALTER [COLUMN] <colname> OPTIONS */
			| ALTER opt_column ColId alter_generic_options
				{
					PGAlterTableCmd *n = makeNode(PGAlterTableCmd);
					n->subtype = PG_AT_AlterColumnGenericOptions;
					n->name = $3;
					n->def = (PGNode *) $4;
					$$ = (PGNode *)n;
				}
			/* ALTER TABLE <name> ADD CONSTRAINT ... */
			| ADD_P TableConstraint
				{
					PGAlterTableCmd *n = makeNode(PGAlterTableCmd);
					n->subtype = PG_AT_AddConstraint;
					n->def = $2;
					$$ = (PGNode *)n;
				}
			/* ALTER TABLE <name> ALTER CONSTRAINT ... */
			| ALTER CONSTRAINT name ConstraintAttributeSpec
				{
					PGAlterTableCmd *n = makeNode(PGAlterTableCmd);
					PGConstraint *c = makeNode(PGConstraint);
					n->subtype = PG_AT_AlterConstraint;
					n->def = (PGNode *) c;
					c->contype = PG_CONSTR_FOREIGN; /* others not supported, yet */
					c->conname = $3;
					processCASbits($4, @4, "ALTER CONSTRAINT statement",
									&c->deferrable,
									&c->initdeferred,
									NULL, NULL, yyscanner);
					$$ = (PGNode *)n;
				}
			/* ALTER TABLE <name> VALIDATE CONSTRAINT ... */
			| VALIDATE CONSTRAINT name
				{
					PGAlterTableCmd *n = makeNode(PGAlterTableCmd);
					n->subtype = PG_AT_ValidateConstraint;
					n->name = $3;
					$$ = (PGNode *)n;
				}
			/* ALTER TABLE <name> DROP CONSTRAINT IF EXISTS <name> [RESTRICT|CASCADE] */
			| DROP CONSTRAINT IF_P EXISTS name opt_drop_behavior
				{
					PGAlterTableCmd *n = makeNode(PGAlterTableCmd);
					n->subtype = PG_AT_DropConstraint;
					n->name = $5;
					n->behavior = $6;
					n->missing_ok = true;
					$$ = (PGNode *)n;
				}
			/* ALTER TABLE <name> DROP CONSTRAINT <name> [RESTRICT|CASCADE] */
			| DROP CONSTRAINT name opt_drop_behavior
				{
					PGAlterTableCmd *n = makeNode(PGAlterTableCmd);
					n->subtype = PG_AT_DropConstraint;
					n->name = $3;
					n->behavior = $4;
					n->missing_ok = false;
					$$ = (PGNode *)n;
				}
			/* ALTER TABLE <name> SET LOGGED  */
			| SET LOGGED
				{
					PGAlterTableCmd *n = makeNode(PGAlterTableCmd);
					n->subtype = PG_AT_SetLogged;
					$$ = (PGNode *)n;
				}
			/* ALTER TABLE <name> SET UNLOGGED  */
			| SET UNLOGGED
				{
					PGAlterTableCmd *n = makeNode(PGAlterTableCmd);
					n->subtype = PG_AT_SetUnLogged;
					$$ = (PGNode *)n;
				}
			/* ALTER TABLE <name> SET (...) */
			| SET reloptions
				{
					PGAlterTableCmd *n = makeNode(PGAlterTableCmd);
					n->subtype = PG_AT_SetRelOptions;
					n->def = (PGNode *)$2;
					$$ = (PGNode *)n;
				}
			/* ALTER TABLE <name> RESET (...) */
			| RESET reloptions
				{
					PGAlterTableCmd *n = makeNode(PGAlterTableCmd);
					n->subtype = PG_AT_ResetRelOptions;
					n->def = (PGNode *)$2;
					$$ = (PGNode *)n;
				}
			| alter_generic_options
				{
					PGAlterTableCmd *n = makeNode(PGAlterTableCmd);
					n->subtype = PG_AT_GenericOptions;
					n->def = (PGNode *)$1;
					$$ = (PGNode *) n;
				}
		;


alter_using:
			USING a_expr				{ $$ = $2; }
			| /* EMPTY */				{ $$ = NULL; }
		;


alter_generic_option_elem:
			generic_option_elem
				{
					$$ = $1;
				}
			| SET generic_option_elem
				{
					$$ = $2;
					$$->defaction = PG_DEFELEM_SET;
				}
			| ADD_P generic_option_elem
				{
					$$ = $2;
					$$->defaction = PG_DEFELEM_ADD;
				}
			| DROP generic_option_name
				{
					$$ = makeDefElemExtended(NULL, $2, NULL, DEFELEM_DROP, @2);
				}
		;


alter_table_cmds:
			alter_table_cmd							{ $$ = list_make1($1); }
			| alter_table_cmds ',' alter_table_cmd	{ $$ = lappend($1, $3); }
		;


alter_generic_options:
			OPTIONS	'(' alter_generic_option_list ')'		{ $$ = $3; }
		;


opt_set_data: SET DATA_P							{ $$ = 1; }
			| SET									{ $$ = 0; }
			| /*EMPTY*/								{ $$ = 0; }
		;
#line 1 "third_party/libpg_query/grammar/statements/analyze.y"
/*****************************************************************************
 *
 *		QUERY:
 *				VACUUM
 *				ANALYZE
 *
 *****************************************************************************/
AnalyzeStmt:
			analyze_keyword opt_verbose
				{
					PGVacuumStmt *n = makeNode(PGVacuumStmt);
					n->options = PG_VACOPT_ANALYZE;
					if ($2)
						n->options |= PG_VACOPT_VERBOSE;
					n->relation = NULL;
					n->va_cols = NIL;
					$$ = (PGNode *)n;
				}
			| analyze_keyword opt_verbose qualified_name opt_name_list
				{
					PGVacuumStmt *n = makeNode(PGVacuumStmt);
					n->options = PG_VACOPT_ANALYZE;
					if ($2)
						n->options |= PG_VACOPT_VERBOSE;
					n->relation = $3;
					n->va_cols = $4;
					$$ = (PGNode *)n;
				}
		;
#line 1 "third_party/libpg_query/grammar/statements/attach.y"
/*****************************************************************************
 *
 * Attach Statement
 *
 *****************************************************************************/
AttachStmt:
				ATTACH opt_database Sconst opt_database_alias copy_options
				{
					PGAttachStmt *n = makeNode(PGAttachStmt);
					n->path = $3;
					n->name = $4;
					n->options = $5;
					$$ = (PGNode *)n;
				}
		;

DetachStmt:
				DETACH opt_database IDENT
				{
					PGDetachStmt *n = makeNode(PGDetachStmt);
					n->missing_ok = false;
					n->db_name = $3;
					$$ = (PGNode *)n;
				}
			|	DETACH DATABASE IF_P EXISTS IDENT
				{
					PGDetachStmt *n = makeNode(PGDetachStmt);
					n->missing_ok = true;
					n->db_name = $5;
					$$ = (PGNode *)n;
				}
		;

opt_database:	DATABASE							{}
			| /*EMPTY*/								{}
		;

opt_database_alias:
			AS ColId									{ $$ = $2; }
			| /*EMPTY*/									{ $$ = NULL; }
		;

ident_name:	IDENT						{ $$ = list_make1(makeString($1)); }

ident_list:
			ident_name								{ $$ = list_make1($1); }
			| ident_list ',' ident_name				{ $$ = lappend($1, $3); }
		;
#line 1 "third_party/libpg_query/grammar/statements/call.y"
/*****************************************************************************
 *
 * CALL <proc_name> [(params, ...)]
 *
 *****************************************************************************/
CallStmt: CALL_P func_application
				{
					PGCallStmt *n = makeNode(PGCallStmt);
					n->func = $2;
					$$ = (PGNode *) n;
				}
		;
#line 1 "third_party/libpg_query/grammar/statements/checkpoint.y"
/*
 * Checkpoint statement
 */
CheckPointStmt:
			FORCE CHECKPOINT opt_col_id
				{
					PGCheckPointStmt *n = makeNode(PGCheckPointStmt);
					n->force = true;
					n->name = $3;
					$$ = (PGNode *)n;
				}
			| CHECKPOINT opt_col_id
				{
					PGCheckPointStmt *n = makeNode(PGCheckPointStmt);
					n->force = false;
					n->name = $2;
					$$ = (PGNode *)n;
				}
		;

opt_col_id:
	ColId 						{ $$ = $1; }
	| /* empty */ 				{ $$ = NULL; }
#line 1 "third_party/libpg_query/grammar/statements/common.y"
/*
 * The production for a qualified relation name has to exactly match the
 * production for a qualified func_name, because in a FROM clause we cannot
 * tell which we are parsing until we see what comes after it ('(' for a
 * func_name, something else for a relation). Therefore we allow 'indirection'
 * which may contain subscripts, and reject that case in the C code.
 */
qualified_name:
			ColIdOrString
				{
					$$ = makeRangeVar(NULL, $1, @1);
				}
			| ColId indirection
				{
					check_qualified_name($2, yyscanner);
					$$ = makeRangeVar(NULL, NULL, @1);
					switch (list_length($2))
					{
						case 1:
							$$->catalogname = NULL;
							$$->schemaname = $1;
							$$->relname = strVal(linitial($2));
							break;
						case 2:
							$$->catalogname = $1;
							$$->schemaname = strVal(linitial($2));
							$$->relname = strVal(lsecond($2));
							break;
						case 3:
						default:
							ereport(ERROR,
									(errcode(PG_ERRCODE_SYNTAX_ERROR),
									 errmsg("improper qualified name (too many dotted names): %s",
											NameListToString(lcons(makeString($1), $2))),
									 parser_errposition(@1)));
							break;
					}
				}
		;


/* Column identifier --- names that can be column, table, etc names.
 */
ColId:		IDENT									{ $$ = $1; }
			| unreserved_keyword					{ $$ = pstrdup($1); }
			| col_name_keyword						{ $$ = pstrdup($1); }
		;


ColIdOrString:	ColId											{ $$ = $1; }
				| SCONST										{ $$ = $1; }
		;


Sconst:		SCONST									{ $$ = $1; };


indirection:
			indirection_el							{ $$ = list_make1($1); }
			| indirection indirection_el			{ $$ = lappend($1, $2); }
		;

indirection_el:
			'.' attr_name
				{
					$$ = (PGNode *) makeString($2);
				}
		;

attr_name:	ColLabel								{ $$ = $1; };

/* Column label --- allowed labels in "AS" clauses.
 * This presently includes *all* Postgres keywords.
 */
ColLabel:	IDENT									{ $$ = $1; }
			| other_keyword							{ $$ = pstrdup($1); }
			| unreserved_keyword					{ $$ = pstrdup($1); }
			| reserved_keyword						{ $$ = pstrdup($1); }
		;

#line 1 "third_party/libpg_query/grammar/statements/copy.y"
CopyStmt:	COPY opt_binary qualified_name opt_column_list opt_oids
			copy_from opt_program copy_file_name copy_delimiter opt_with copy_options
				{
					PGCopyStmt *n = makeNode(PGCopyStmt);
					n->relation = $3;
					n->query = NULL;
					n->attlist = $4;
					n->is_from = $6;
					n->is_program = $7;
					n->filename = $8;

					if (n->is_program && n->filename == NULL)
						ereport(ERROR,
								(errcode(PG_ERRCODE_SYNTAX_ERROR),
								 errmsg("STDIN/STDOUT not allowed with PROGRAM"),
								 parser_errposition(@8)));

					n->options = NIL;
					/* Concatenate user-supplied flags */
					if ($2)
						n->options = lappend(n->options, $2);
					if ($5)
						n->options = lappend(n->options, $5);
					if ($9)
						n->options = lappend(n->options, $9);
					if ($11)
						n->options = list_concat(n->options, $11);
					$$ = (PGNode *)n;
				}
			| COPY '(' SelectStmt ')' TO opt_program copy_file_name opt_with copy_options
				{
					PGCopyStmt *n = makeNode(PGCopyStmt);
					n->relation = NULL;
					n->query = $3;
					n->attlist = NIL;
					n->is_from = false;
					n->is_program = $6;
					n->filename = $7;
					n->options = $9;

					if (n->is_program && n->filename == NULL)
						ereport(ERROR,
								(errcode(PG_ERRCODE_SYNTAX_ERROR),
								 errmsg("STDIN/STDOUT not allowed with PROGRAM"),
								 parser_errposition(@5)));

					$$ = (PGNode *)n;
				}
		;


copy_from:
			FROM									{ $$ = true; }
			| TO									{ $$ = false; }
		;


copy_delimiter:
			opt_using DELIMITERS Sconst
				{
					$$ = makeDefElem("delimiter", (PGNode *)makeString($3), @2);
				}
			| /*EMPTY*/								{ $$ = NULL; }
		;


copy_generic_opt_arg_list:
			  copy_generic_opt_arg_list_item
				{
					$$ = list_make1($1);
				}
			| copy_generic_opt_arg_list ',' copy_generic_opt_arg_list_item
				{
					$$ = lappend($1, $3);
				}
		;


opt_using:
			USING									{}
			| /*EMPTY*/								{}
		;


opt_as:		AS										{}
			| /* EMPTY */							{}
		;


opt_program:
			PROGRAM									{ $$ = true; }
			| /* EMPTY */							{ $$ = false; }
		;


copy_options: copy_opt_list							{ $$ = $1; }
			| '(' copy_generic_opt_list ')'			{ $$ = $2; }
		;


copy_generic_opt_arg:
			opt_boolean_or_string			{ $$ = (PGNode *) makeString($1); }
			| NumericOnly					{ $$ = (PGNode *) $1; }
			| '*'							{ $$ = (PGNode *) makeNode(PGAStar); }
			| '(' copy_generic_opt_arg_list ')'		{ $$ = (PGNode *) $2; }
			| struct_expr					{ $$ = (PGNode *) $1; }
			| /* EMPTY */					{ $$ = NULL; }
		;


copy_generic_opt_elem:
			ColLabel copy_generic_opt_arg
				{
					$$ = makeDefElem($1, $2, @1);
				}
		;


opt_oids:
			WITH OIDS
				{
					$$ = makeDefElem("oids", (PGNode *)makeInteger(true), @1);
				}
			| /*EMPTY*/								{ $$ = NULL; }
		;


copy_opt_list:
			copy_opt_list copy_opt_item				{ $$ = lappend($1, $2); }
			| /* EMPTY */							{ $$ = NIL; }
		;


opt_binary:
			BINARY
				{
					$$ = makeDefElem("format", (PGNode *)makeString("binary"), @1);
				}
			| /*EMPTY*/								{ $$ = NULL; }
		;


copy_opt_item:
			BINARY
				{
					$$ = makeDefElem("format", (PGNode *)makeString("binary"), @1);
				}
			| OIDS
				{
					$$ = makeDefElem("oids", (PGNode *)makeInteger(true), @1);
				}
			| FREEZE
				{
					$$ = makeDefElem("freeze", (PGNode *)makeInteger(true), @1);
				}
			| DELIMITER opt_as Sconst
				{
					$$ = makeDefElem("delimiter", (PGNode *)makeString($3), @1);
				}
			| NULL_P opt_as Sconst
				{
					$$ = makeDefElem("null", (PGNode *)makeString($3), @1);
				}
			| CSV
				{
					$$ = makeDefElem("format", (PGNode *)makeString("csv"), @1);
				}
			| HEADER_P
				{
					$$ = makeDefElem("header", (PGNode *)makeInteger(true), @1);
				}
			| QUOTE opt_as Sconst
				{
					$$ = makeDefElem("quote", (PGNode *)makeString($3), @1);
				}
			| ESCAPE opt_as Sconst
				{
					$$ = makeDefElem("escape", (PGNode *)makeString($3), @1);
				}
			| FORCE QUOTE columnList
				{
					$$ = makeDefElem("force_quote", (PGNode *)$3, @1);
				}
			| FORCE QUOTE '*'
				{
					$$ = makeDefElem("force_quote", (PGNode *)makeNode(PGAStar), @1);
				}
			| PARTITION BY columnList
				{
					$$ = makeDefElem("partition_by", (PGNode *)$3, @1);
				}
			| PARTITION BY '*'
				{
					$$ = makeDefElem("partition_by", (PGNode *)makeNode(PGAStar), @1);
				}
			| FORCE NOT NULL_P columnList
				{
					$$ = makeDefElem("force_not_null", (PGNode *)$4, @1);
				}
			| FORCE NULL_P columnList
				{
					$$ = makeDefElem("force_null", (PGNode *)$3, @1);
				}
			| ENCODING Sconst
				{
					$$ = makeDefElem("encoding", (PGNode *)makeString($2), @1);
				}
		;


copy_generic_opt_arg_list_item:
			opt_boolean_or_string	{ $$ = (PGNode *) makeString($1); }
		;



copy_file_name:
			Sconst									{ $$ = $1; }
			| STDIN									{ $$ = NULL; }
			| STDOUT								{ $$ = NULL; }
		;


copy_generic_opt_list:
			copy_generic_opt_elem
				{
					$$ = list_make1($1);
				}
			| copy_generic_opt_list ',' copy_generic_opt_elem
				{
					$$ = lappend($1, $3);
				}
		;
#line 1 "third_party/libpg_query/grammar/statements/create.y"
/*****************************************************************************
 *
 *		QUERY :
 *				CREATE TABLE relname
 *
 *****************************************************************************/
CreateStmt:	CREATE_P OptTemp TABLE qualified_name '(' OptTableElementList ')'
			OptWith OnCommitOption
				{
					PGCreateStmt *n = makeNode(PGCreateStmt);
					$4->relpersistence = $2;
					n->relation = $4;
					n->tableElts = $6;
					n->ofTypename = NULL;
					n->constraints = NIL;
					n->options = $8;
					n->oncommit = $9;
					n->onconflict = PG_ERROR_ON_CONFLICT;
					$$ = (PGNode *)n;
				}
		| CREATE_P OptTemp TABLE IF_P NOT EXISTS qualified_name '('
			OptTableElementList ')' OptWith
			OnCommitOption
				{
					PGCreateStmt *n = makeNode(PGCreateStmt);
					$7->relpersistence = $2;
					n->relation = $7;
					n->tableElts = $9;
					n->ofTypename = NULL;
					n->constraints = NIL;
					n->options = $11;
					n->oncommit = $12;
					n->onconflict = PG_IGNORE_ON_CONFLICT;
					$$ = (PGNode *)n;
				}
		| CREATE_P OR REPLACE OptTemp TABLE qualified_name '('
			OptTableElementList ')' OptWith
			OnCommitOption
				{
					PGCreateStmt *n = makeNode(PGCreateStmt);
					$6->relpersistence = $4;
					n->relation = $6;
					n->tableElts = $8;
					n->ofTypename = NULL;
					n->constraints = NIL;
					n->options = $10;
					n->oncommit = $11;
					n->onconflict = PG_REPLACE_ON_CONFLICT;
					$$ = (PGNode *)n;
				}
		;


ConstraintAttributeSpec:
			/*EMPTY*/
				{ $$ = 0; }
			| ConstraintAttributeSpec ConstraintAttributeElem
				{
					/*
					 * We must complain about conflicting options.
					 * We could, but choose not to, complain about redundant
					 * options (ie, where $2's bit is already set in $1).
					 */
					int		newspec = $1 | $2;

					/* special message for this case */
					if ((newspec & (CAS_NOT_DEFERRABLE | CAS_INITIALLY_DEFERRED)) == (CAS_NOT_DEFERRABLE | CAS_INITIALLY_DEFERRED))
						ereport(ERROR,
								(errcode(PG_ERRCODE_SYNTAX_ERROR),
								 errmsg("constraint declared INITIALLY DEFERRED must be DEFERRABLE"),
								 parser_errposition(@2)));
					/* generic message for other conflicts */
					if ((newspec & (CAS_NOT_DEFERRABLE | CAS_DEFERRABLE)) == (CAS_NOT_DEFERRABLE | CAS_DEFERRABLE) ||
						(newspec & (CAS_INITIALLY_IMMEDIATE | CAS_INITIALLY_DEFERRED)) == (CAS_INITIALLY_IMMEDIATE | CAS_INITIALLY_DEFERRED))
						ereport(ERROR,
								(errcode(PG_ERRCODE_SYNTAX_ERROR),
								 errmsg("conflicting constraint properties"),
								 parser_errposition(@2)));
					$$ = newspec;
				}
		;


def_arg:	func_type						{ $$ = (PGNode *)$1; }
			| reserved_keyword				{ $$ = (PGNode *)makeString(pstrdup($1)); }
			| qual_all_Op					{ $$ = (PGNode *)$1; }
			| NumericOnly					{ $$ = (PGNode *)$1; }
			| Sconst						{ $$ = (PGNode *)makeString($1); }
			| NONE							{ $$ = (PGNode *)makeString(pstrdup($1)); }
		;


OptParenthesizedSeqOptList: '(' SeqOptList ')'		{ $$ = $2; }
			| /*EMPTY*/								{ $$ = NIL; }
		;


generic_option_arg:
				Sconst				{ $$ = (PGNode *) makeString($1); }
		;


key_action:
			NO ACTION					{ $$ = PG_FKCONSTR_ACTION_NOACTION; }
			| RESTRICT					{ $$ = PG_FKCONSTR_ACTION_RESTRICT; }
			| CASCADE					{ $$ = PG_FKCONSTR_ACTION_CASCADE; }
			| SET NULL_P				{ $$ = PG_FKCONSTR_ACTION_SETNULL; }
			| SET DEFAULT				{ $$ = PG_FKCONSTR_ACTION_SETDEFAULT; }
		;


ColConstraint:
			CONSTRAINT name ColConstraintElem
				{
					PGConstraint *n = castNode(PGConstraint, $3);
					n->conname = $2;
					n->location = @1;
					$$ = (PGNode *) n;
				}
			| ColConstraintElem						{ $$ = $1; }
			| ConstraintAttr						{ $$ = $1; }
			| COLLATE any_name
				{
					/*
					 * Note: the PGCollateClause is momentarily included in
					 * the list built by ColQualList, but we split it out
					 * again in SplitColQualList.
					 */
					PGCollateClause *n = makeNode(PGCollateClause);
					n->arg = NULL;
					n->collname = $2;
					n->location = @1;
					$$ = (PGNode *) n;
				}
		;


ColConstraintElem:
			NOT NULL_P
				{
					PGConstraint *n = makeNode(PGConstraint);
					n->contype = PG_CONSTR_NOTNULL;
					n->location = @1;
					$$ = (PGNode *)n;
				}
			| NULL_P
				{
					PGConstraint *n = makeNode(PGConstraint);
					n->contype = PG_CONSTR_NULL;
					n->location = @1;
					$$ = (PGNode *)n;
				}
			| UNIQUE opt_definition
				{
					PGConstraint *n = makeNode(PGConstraint);
					n->contype = PG_CONSTR_UNIQUE;
					n->location = @1;
					n->keys = NULL;
					n->options = $2;
					n->indexname = NULL;
					$$ = (PGNode *)n;
				}
			| PRIMARY KEY opt_definition
				{
					PGConstraint *n = makeNode(PGConstraint);
					n->contype = PG_CONSTR_PRIMARY;
					n->location = @1;
					n->keys = NULL;
					n->options = $3;
					n->indexname = NULL;
					$$ = (PGNode *)n;
				}
			| CHECK_P '(' a_expr ')' opt_no_inherit
				{
					PGConstraint *n = makeNode(PGConstraint);
					n->contype = PG_CONSTR_CHECK;
					n->location = @1;
					n->is_no_inherit = $5;
					n->raw_expr = $3;
					n->cooked_expr = NULL;
					n->skip_validation = false;
					n->initially_valid = true;
					$$ = (PGNode *)n;
				}
			| USING COMPRESSION name
				{
					PGConstraint *n = makeNode(PGConstraint);
					n->contype = PG_CONSTR_COMPRESSION;
					n->location = @1;
					n->compression_name = $3;
					$$ = (PGNode *)n;
				}
			| DEFAULT b_expr
				{
					PGConstraint *n = makeNode(PGConstraint);
					n->contype = PG_CONSTR_DEFAULT;
					n->location = @1;
					n->raw_expr = $2;
					n->cooked_expr = NULL;
					$$ = (PGNode *)n;
				}
			| REFERENCES qualified_name opt_column_list key_match key_actions
				{
					PGConstraint *n = makeNode(PGConstraint);
					n->contype = PG_CONSTR_FOREIGN;
					n->location = @1;
					n->pktable			= $2;
					n->fk_attrs			= NIL;
					n->pk_attrs			= $3;
					n->fk_matchtype		= $4;
					n->fk_upd_action	= (char) ($5 >> 8);
					n->fk_del_action	= (char) ($5 & 0xFF);
					n->skip_validation  = false;
					n->initially_valid  = true;
					$$ = (PGNode *)n;
				}
		;

GeneratedColumnType:
			VIRTUAL { $$ = PG_CONSTR_GENERATED_VIRTUAL; }
			| STORED { $$ = PG_CONSTR_GENERATED_STORED; }
			;

opt_GeneratedColumnType:
			GeneratedColumnType { $$ = $1; }
			| /* EMPTY */ { $$ = PG_CONSTR_GENERATED_VIRTUAL; }
			;

GeneratedConstraintElem:
			GENERATED generated_when AS IDENTITY_P OptParenthesizedSeqOptList
				{
					PGConstraint *n = makeNode(PGConstraint);
					n->contype = PG_CONSTR_IDENTITY;
					n->generated_when = $2;
					n->options = $5;
					n->location = @1;
					$$ = (PGNode *)n;
				}
			| GENERATED generated_when AS '(' a_expr ')' opt_GeneratedColumnType
				{
					PGConstraint *n = makeNode(PGConstraint);
					n->contype = $7;
					n->generated_when = $2;
					n->raw_expr = $5;
					n->cooked_expr = NULL;
					n->location = @1;

					/*
					 * Can't do this in the grammar because of shift/reduce
					 * conflicts.  (IDENTITY allows both ALWAYS and BY
					 * DEFAULT, but generated columns only allow ALWAYS.)  We
					 * can also give a more useful error message and location.
					 */
					if ($2 != PG_ATTRIBUTE_IDENTITY_ALWAYS)
						ereport(ERROR,
								(errcode(PG_ERRCODE_SYNTAX_ERROR),
								 errmsg("for a generated column, GENERATED ALWAYS must be specified"),
								 parser_errposition(@2)));

					$$ = (PGNode *)n;
				}
			| AS '(' a_expr ')' opt_GeneratedColumnType
				{
					PGConstraint *n = makeNode(PGConstraint);
					n->contype = $5;
					n->generated_when = PG_ATTRIBUTE_IDENTITY_ALWAYS;
					n->raw_expr = $3;
					n->cooked_expr = NULL;
					n->location = @1;
					$$ = (PGNode *)n;
				}
	    ;


generic_option_elem:
			generic_option_name generic_option_arg
				{
					$$ = makeDefElem($1, $2, @1);
				}
		;


key_update: ON UPDATE key_action		{ $$ = $3; }
		;


key_actions:
			key_update
				{ $$ = ($1 << 8) | (PG_FKCONSTR_ACTION_NOACTION & 0xFF); }
			| key_delete
				{ $$ = (PG_FKCONSTR_ACTION_NOACTION << 8) | ($1 & 0xFF); }
			| key_update key_delete
				{ $$ = ($1 << 8) | ($2 & 0xFF); }
			| key_delete key_update
				{ $$ = ($2 << 8) | ($1 & 0xFF); }
			| /*EMPTY*/
				{ $$ = (PG_FKCONSTR_ACTION_NOACTION << 8) | (PG_FKCONSTR_ACTION_NOACTION & 0xFF); }
		;

OnCommitOption:  ON COMMIT DROP				{ $$ = ONCOMMIT_DROP; }
			| ON COMMIT DELETE_P ROWS		{ $$ = PG_ONCOMMIT_DELETE_ROWS; }
			| ON COMMIT PRESERVE ROWS		{ $$ = PG_ONCOMMIT_PRESERVE_ROWS; }
			| /*EMPTY*/						{ $$ = PG_ONCOMMIT_NOOP; }
		;


reloptions:
			'(' reloption_list ')'					{ $$ = $2; }
		;


opt_no_inherit:	NO INHERIT							{  $$ = true; }
			| /* EMPTY */							{  $$ = false; }
		;


TableConstraint:
			CONSTRAINT name ConstraintElem
				{
					PGConstraint *n = castNode(PGConstraint, $3);
					n->conname = $2;
					n->location = @1;
					$$ = (PGNode *) n;
				}
			| ConstraintElem						{ $$ = $1; }
		;


TableLikeOption:
				COMMENTS			{ $$ = PG_CREATE_TABLE_LIKE_COMMENTS; }
				| CONSTRAINTS		{ $$ = PG_CREATE_TABLE_LIKE_CONSTRAINTS; }
				| DEFAULTS			{ $$ = PG_CREATE_TABLE_LIKE_DEFAULTS; }
				| IDENTITY_P		{ $$ = PG_CREATE_TABLE_LIKE_IDENTITY; }
				| INDEXES			{ $$ = PG_CREATE_TABLE_LIKE_INDEXES; }
				| STATISTICS		{ $$ = PG_CREATE_TABLE_LIKE_STATISTICS; }
				| STORAGE			{ $$ = PG_CREATE_TABLE_LIKE_STORAGE; }
				| ALL				{ $$ = PG_CREATE_TABLE_LIKE_ALL; }
		;



reloption_list:
			reloption_elem							{ $$ = list_make1($1); }
			| reloption_list ',' reloption_elem		{ $$ = lappend($1, $3); }
		;


ExistingIndex:   USING INDEX index_name				{ $$ = $3; }
		;


ConstraintAttr:
			DEFERRABLE
				{
					PGConstraint *n = makeNode(PGConstraint);
					n->contype = PG_CONSTR_ATTR_DEFERRABLE;
					n->location = @1;
					$$ = (PGNode *)n;
				}
			| NOT DEFERRABLE
				{
					PGConstraint *n = makeNode(PGConstraint);
					n->contype = PG_CONSTR_ATTR_NOT_DEFERRABLE;
					n->location = @1;
					$$ = (PGNode *)n;
				}
			| INITIALLY DEFERRED
				{
					PGConstraint *n = makeNode(PGConstraint);
					n->contype = PG_CONSTR_ATTR_DEFERRED;
					n->location = @1;
					$$ = (PGNode *)n;
				}
			| INITIALLY IMMEDIATE
				{
					PGConstraint *n = makeNode(PGConstraint);
					n->contype = PG_CONSTR_ATTR_IMMEDIATE;
					n->location = @1;
					$$ = (PGNode *)n;
				}
		;



OptWith:
			WITH reloptions				{ $$ = $2; }
			| WITH OIDS					{ $$ = list_make1(makeDefElem("oids", (PGNode *) makeInteger(true), @1)); }
			| WITHOUT OIDS				{ $$ = list_make1(makeDefElem("oids", (PGNode *) makeInteger(false), @1)); }
			| /*EMPTY*/					{ $$ = NIL; }
		;


definition: '(' def_list ')'						{ $$ = $2; }
		;


TableLikeOptionList:
				TableLikeOptionList INCLUDING TableLikeOption	{ $$ = $1 | $3; }
				| TableLikeOptionList EXCLUDING TableLikeOption	{ $$ = $1 & ~$3; }
				| /* EMPTY */						{ $$ = 0; }
		;


generic_option_name:
				ColLabel			{ $$ = $1; }
		;


ConstraintAttributeElem:
			NOT DEFERRABLE					{ $$ = CAS_NOT_DEFERRABLE; }
			| DEFERRABLE					{ $$ = CAS_DEFERRABLE; }
			| INITIALLY IMMEDIATE			{ $$ = CAS_INITIALLY_IMMEDIATE; }
			| INITIALLY DEFERRED			{ $$ = CAS_INITIALLY_DEFERRED; }
			| NOT VALID						{ $$ = CAS_NOT_VALID; }
			| NO INHERIT					{ $$ = CAS_NO_INHERIT; }
		;



columnDef:	ColId Typename ColQualList
				{
					PGColumnDef *n = makeNode(PGColumnDef);
					n->category = COL_STANDARD;
					n->colname = $1;
					n->typeName = $2;
					n->inhcount = 0;
					n->is_local = true;
					n->is_not_null = false;
					n->is_from_type = false;
					n->storage = 0;
					n->raw_default = NULL;
					n->cooked_default = NULL;
					n->collOid = InvalidOid;
					SplitColQualList($3, &n->constraints, &n->collClause,
									 yyscanner);
					n->location = @1;
					$$ = (PGNode *)n;
			}
			|
			ColId opt_Typename GeneratedConstraintElem ColQualList
				{
					PGColumnDef *n = makeNode(PGColumnDef);
					n->category = COL_GENERATED;
					n->colname = $1;
					n->typeName = $2;
					n->inhcount = 0;
					n->is_local = true;
					n->is_not_null = false;
					n->is_from_type = false;
					n->storage = 0;
					n->raw_default = NULL;
					n->cooked_default = NULL;
					n->collOid = InvalidOid;
					// merge the constraints with the generated column constraint
					auto constraints = $4;
					if (constraints) {
					    constraints = lappend(constraints, $3);
					} else {
					    constraints = list_make1($3);
					}
					SplitColQualList(constraints, &n->constraints, &n->collClause,
									 yyscanner);
					n->location = @1;
					$$ = (PGNode *)n;
			}
		;


def_list:	def_elem								{ $$ = list_make1($1); }
			| def_list ',' def_elem					{ $$ = lappend($1, $3); }
		;


index_name: ColId									{ $$ = $1; };


TableElement:
			columnDef							{ $$ = $1; }
			| TableLikeClause					{ $$ = $1; }
			| TableConstraint					{ $$ = $1; }
		;


def_elem:	ColLabel '=' def_arg
				{
					$$ = makeDefElem($1, (PGNode *) $3, @1);
				}
			| ColLabel
				{
					$$ = makeDefElem($1, NULL, @1);
				}
		;


opt_definition:
			WITH definition							{ $$ = $2; }
			| /*EMPTY*/								{ $$ = NIL; }
		;


OptTableElementList:
			TableElementList					{ $$ = $1; }
			| TableElementList ','					{ $$ = $1; }
			| /*EMPTY*/							{ $$ = NIL; }
		;


columnElem: ColId
				{
					$$ = (PGNode *) makeString($1);
				}
		;


opt_column_list:
			'(' columnList ')'						{ $$ = $2; }
			| /*EMPTY*/								{ $$ = NIL; }
		;


ColQualList:
			ColQualList ColConstraint				{ $$ = lappend($1, $2); }
			| /*EMPTY*/								{ $$ = NIL; }
		;


key_delete: ON DELETE_P key_action		{ $$ = $3; }
		;


reloption_elem:
			ColLabel '=' def_arg
				{
					$$ = makeDefElem($1, (PGNode *) $3, @1);
				}
			| ColLabel
				{
					$$ = makeDefElem($1, NULL, @1);
				}
			| ColLabel '.' ColLabel '=' def_arg
				{
					$$ = makeDefElemExtended($1, $3, (PGNode *) $5,
											 PG_DEFELEM_UNSPEC, @1);
				}
			| ColLabel '.' ColLabel
				{
					$$ = makeDefElemExtended($1, $3, NULL, PG_DEFELEM_UNSPEC, @1);
				}
		;


columnList:
			columnElem								{ $$ = list_make1($1); }
			| columnList ',' columnElem				{ $$ = lappend($1, $3); }
		;

columnList_opt_comma:
			columnList								{ $$ = $1; }
			| columnList ','						{ $$ = $1; }
		;


func_type:	Typename								{ $$ = $1; }
			| type_function_name attrs '%' TYPE_P
				{
					$$ = makeTypeNameFromNameList(lcons(makeString($1), $2));
					$$->pct_type = true;
					$$->location = @1;
				}
			| SETOF type_function_name attrs '%' TYPE_P
				{
					$$ = makeTypeNameFromNameList(lcons(makeString($2), $3));
					$$->pct_type = true;
					$$->setof = true;
					$$->location = @2;
				}
		;


ConstraintElem:
			CHECK_P '(' a_expr ')' ConstraintAttributeSpec
				{
					PGConstraint *n = makeNode(PGConstraint);
					n->contype = PG_CONSTR_CHECK;
					n->location = @1;
					n->raw_expr = $3;
					n->cooked_expr = NULL;
					processCASbits($5, @5, "CHECK",
								   NULL, NULL, &n->skip_validation,
								   &n->is_no_inherit, yyscanner);
					n->initially_valid = !n->skip_validation;
					$$ = (PGNode *)n;
				}
			| UNIQUE '(' columnList_opt_comma ')' opt_definition
				ConstraintAttributeSpec
				{
					PGConstraint *n = makeNode(PGConstraint);
					n->contype = PG_CONSTR_UNIQUE;
					n->location = @1;
					n->keys = $3;
					n->options = $5;
					n->indexname = NULL;
					processCASbits($6, @6, "UNIQUE",
								   &n->deferrable, &n->initdeferred, NULL,
								   NULL, yyscanner);
					$$ = (PGNode *)n;
				}
			| UNIQUE ExistingIndex ConstraintAttributeSpec
				{
					PGConstraint *n = makeNode(PGConstraint);
					n->contype = PG_CONSTR_UNIQUE;
					n->location = @1;
					n->keys = NIL;
					n->options = NIL;
					n->indexname = $2;
					n->indexspace = NULL;
					processCASbits($3, @3, "UNIQUE",
								   &n->deferrable, &n->initdeferred, NULL,
								   NULL, yyscanner);
					$$ = (PGNode *)n;
				}
			| PRIMARY KEY '(' columnList_opt_comma ')' opt_definition
				ConstraintAttributeSpec
				{
					PGConstraint *n = makeNode(PGConstraint);
					n->contype = PG_CONSTR_PRIMARY;
					n->location = @1;
					n->keys = $4;
					n->options = $6;
					n->indexname = NULL;
					processCASbits($7, @7, "PRIMARY KEY",
								   &n->deferrable, &n->initdeferred, NULL,
								   NULL, yyscanner);
					$$ = (PGNode *)n;
				}
			| PRIMARY KEY ExistingIndex ConstraintAttributeSpec
				{
					PGConstraint *n = makeNode(PGConstraint);
					n->contype = PG_CONSTR_PRIMARY;
					n->location = @1;
					n->keys = NIL;
					n->options = NIL;
					n->indexname = $3;
					n->indexspace = NULL;
					processCASbits($4, @4, "PRIMARY KEY",
								   &n->deferrable, &n->initdeferred, NULL,
								   NULL, yyscanner);
					$$ = (PGNode *)n;
				}
			| FOREIGN KEY '(' columnList_opt_comma ')' REFERENCES qualified_name
				opt_column_list key_match key_actions ConstraintAttributeSpec
				{
					PGConstraint *n = makeNode(PGConstraint);
					n->contype = PG_CONSTR_FOREIGN;
					n->location = @1;
					n->pktable			= $7;
					n->fk_attrs			= $4;
					n->pk_attrs			= $8;
					n->fk_matchtype		= $9;
					n->fk_upd_action	= (char) ($10 >> 8);
					n->fk_del_action	= (char) ($10 & 0xFF);
					processCASbits($11, @11, "FOREIGN KEY",
								   &n->deferrable, &n->initdeferred,
								   &n->skip_validation, NULL,
								   yyscanner);
					n->initially_valid = !n->skip_validation;
					$$ = (PGNode *)n;
				}
		;


TableElementList:
			TableElement
				{
					$$ = list_make1($1);
				}
			| TableElementList ',' TableElement
				{
					$$ = lappend($1, $3);
				}
		;


key_match:  MATCH FULL
			{
				$$ = PG_FKCONSTR_MATCH_FULL;
			}
		| MATCH PARTIAL
			{
				ereport(ERROR,
						(errcode(PG_ERRCODE_FEATURE_NOT_SUPPORTED),
						 errmsg("MATCH PARTIAL not yet implemented"),
						 parser_errposition(@1)));
				$$ = PG_FKCONSTR_MATCH_PARTIAL;
			}
		| MATCH SIMPLE
			{
				$$ = PG_FKCONSTR_MATCH_SIMPLE;
			}
		| /*EMPTY*/
			{
				$$ = PG_FKCONSTR_MATCH_SIMPLE;
			}
		;


TableLikeClause:
			LIKE qualified_name TableLikeOptionList
				{
					PGTableLikeClause *n = makeNode(PGTableLikeClause);
					n->relation = $2;
					n->options = $3;
					$$ = (PGNode *)n;
				}
		;


OptTemp:	TEMPORARY					{ $$ = PG_RELPERSISTENCE_TEMP; }
			| TEMP						{ $$ = PG_RELPERSISTENCE_TEMP; }
			| LOCAL TEMPORARY			{ $$ = PG_RELPERSISTENCE_TEMP; }
			| LOCAL TEMP				{ $$ = PG_RELPERSISTENCE_TEMP; }
			| GLOBAL TEMPORARY
				{
					ereport(PGWARNING,
							(errmsg("GLOBAL is deprecated in temporary table creation"),
							 parser_errposition(@1)));
					$$ = PG_RELPERSISTENCE_TEMP;
				}
			| GLOBAL TEMP
				{
					ereport(PGWARNING,
							(errmsg("GLOBAL is deprecated in temporary table creation"),
							 parser_errposition(@1)));
					$$ = PG_RELPERSISTENCE_TEMP;
				}
			| UNLOGGED					{ $$ = PG_RELPERSISTENCE_UNLOGGED; }
			| /*EMPTY*/					{ $$ = RELPERSISTENCE_PERMANENT; }
		;


generated_when:
			ALWAYS			{ $$ = PG_ATTRIBUTE_IDENTITY_ALWAYS; }
			| BY DEFAULT	{ $$ = ATTRIBUTE_IDENTITY_BY_DEFAULT; }
		;
#line 1 "third_party/libpg_query/grammar/statements/create_as.y"
/*****************************************************************************
 *
 *		QUERY :
 *				CREATE TABLE relname AS PGSelectStmt [ WITH [NO] DATA ]
 *
 *
 * Note: SELECT ... INTO is a now-deprecated alternative for this.
 *
 *****************************************************************************/
CreateAsStmt:
		CREATE_P OptTemp TABLE create_as_target AS SelectStmt opt_with_data
				{
					PGCreateTableAsStmt *ctas = makeNode(PGCreateTableAsStmt);
					ctas->query = $6;
					ctas->into = $4;
					ctas->relkind = PG_OBJECT_TABLE;
					ctas->is_select_into = false;
					ctas->onconflict = PG_ERROR_ON_CONFLICT;
					/* cram additional flags into the PGIntoClause */
					$4->rel->relpersistence = $2;
					$4->skipData = !($7);
					$$ = (PGNode *) ctas;
				}
		| CREATE_P OptTemp TABLE IF_P NOT EXISTS create_as_target AS SelectStmt opt_with_data
				{
					PGCreateTableAsStmt *ctas = makeNode(PGCreateTableAsStmt);
					ctas->query = $9;
					ctas->into = $7;
					ctas->relkind = PG_OBJECT_TABLE;
					ctas->is_select_into = false;
					ctas->onconflict = PG_IGNORE_ON_CONFLICT;
					/* cram additional flags into the PGIntoClause */
					$7->rel->relpersistence = $2;
					$7->skipData = !($10);
					$$ = (PGNode *) ctas;
				}
		| CREATE_P OR REPLACE OptTemp TABLE create_as_target AS SelectStmt opt_with_data
				{
					PGCreateTableAsStmt *ctas = makeNode(PGCreateTableAsStmt);
					ctas->query = $8;
					ctas->into = $6;
					ctas->relkind = PG_OBJECT_TABLE;
					ctas->is_select_into = false;
					ctas->onconflict = PG_REPLACE_ON_CONFLICT;
					/* cram additional flags into the PGIntoClause */
					$6->rel->relpersistence = $4;
					$6->skipData = !($9);
					$$ = (PGNode *) ctas;
				}
		;


opt_with_data:
			WITH DATA_P								{ $$ = true; }
			| WITH NO DATA_P						{ $$ = false; }
			| /*EMPTY*/								{ $$ = true; }
		;


create_as_target:
			qualified_name opt_column_list OptWith OnCommitOption
				{
					$$ = makeNode(PGIntoClause);
					$$->rel = $1;
					$$->colNames = $2;
					$$->options = $3;
					$$->onCommit = $4;
					$$->viewQuery = NULL;
					$$->skipData = false;		/* might get changed later */
				}
		;
#line 1 "third_party/libpg_query/grammar/statements/create_function.y"
/*****************************************************************************
 *
 * CREATE FUNCTION stmt
 *
  *****************************************************************************/
 CreateFunctionStmt:
                /* the OptTemp is present but not used - to avoid conflicts with other CREATE_P Stmtatements */
		CREATE_P OptTemp macro_alias qualified_name param_list AS TABLE SelectStmt
			{
				PGCreateFunctionStmt *n = makeNode(PGCreateFunctionStmt);
				$4->relpersistence = $2;
				n->name = $4;
				n->params = $5;
				n->function = NULL;
				n->query = $8;
				n->onconflict = PG_ERROR_ON_CONFLICT;
				$$ = (PGNode *)n;
			}
 		|
 		CREATE_P OptTemp macro_alias IF_P NOT EXISTS qualified_name param_list AS TABLE SelectStmt
			{
				PGCreateFunctionStmt *n = makeNode(PGCreateFunctionStmt);
				$7->relpersistence = $2;
				n->name = $7;
				n->params = $8;
				n->function = NULL;
				n->query = $11;
				n->onconflict = PG_IGNORE_ON_CONFLICT;
				$$ = (PGNode *)n;

			}
		|
		CREATE_P OR REPLACE OptTemp macro_alias qualified_name param_list AS TABLE SelectStmt
			{
				PGCreateFunctionStmt *n = makeNode(PGCreateFunctionStmt);
				$6->relpersistence = $4;
				n->name = $6;
				n->params = $7;
				n->function = NULL;
				n->query = $10;
				n->onconflict = PG_REPLACE_ON_CONFLICT;
				$$ = (PGNode *)n;

			}
		|
		CREATE_P OptTemp macro_alias qualified_name param_list AS a_expr
                         {
				PGCreateFunctionStmt *n = makeNode(PGCreateFunctionStmt);
				$4->relpersistence = $2;
				n->name = $4;
				n->params = $5;
				n->function = $7;
				n->query = NULL;
				n->onconflict = PG_ERROR_ON_CONFLICT;
				$$ = (PGNode *)n;
                         }
		|
		CREATE_P OptTemp macro_alias IF_P NOT EXISTS qualified_name param_list AS a_expr
			 {
				PGCreateFunctionStmt *n = makeNode(PGCreateFunctionStmt);
				$7->relpersistence = $2;
				n->name = $7;
				n->params = $8;
				n->function = $10;
				n->query = NULL;
				n->onconflict = PG_IGNORE_ON_CONFLICT;
				$$ = (PGNode *)n;
			 }
		|
		CREATE_P OR REPLACE OptTemp macro_alias qualified_name param_list AS a_expr
			 {
				PGCreateFunctionStmt *n = makeNode(PGCreateFunctionStmt);
				$6->relpersistence = $4;
				n->name = $6;
				n->params = $7;
				n->function = $9;
				n->query = NULL;
				n->onconflict = PG_REPLACE_ON_CONFLICT;
				$$ = (PGNode *)n;
			 }
 		;



macro_alias:
		FUNCTION
		| MACRO


param_list:
		'(' ')'
			{
				$$ = NIL;
			}
		| '(' func_arg_list ')'
			{
				$$ = $2;
			}
	;
#line 1 "third_party/libpg_query/grammar/statements/create_schema.y"
/*****************************************************************************
 *
 * Manipulate a schema
 *
 *****************************************************************************/
CreateSchemaStmt:
			CREATE_P SCHEMA qualified_name OptSchemaEltList
				{
					PGCreateSchemaStmt *n = makeNode(PGCreateSchemaStmt);
					if ($3->catalogname) {
						ereport(ERROR,
								(errcode(PG_ERRCODE_FEATURE_NOT_SUPPORTED),
								 errmsg("CREATE SCHEMA too many dots: expected \"catalog.schema\" or \"schema\""),
								 parser_errposition(@3)));
					}
					if ($3->schemaname) {
						n->catalogname = $3->schemaname;
						n->schemaname = $3->relname;
					} else {
						n->schemaname = $3->relname;
					}
					n->schemaElts = $4;
					n->onconflict = PG_ERROR_ON_CONFLICT;
					$$ = (PGNode *)n;
				}
			| CREATE_P SCHEMA IF_P NOT EXISTS qualified_name OptSchemaEltList
				{
					PGCreateSchemaStmt *n = makeNode(PGCreateSchemaStmt);
					if ($6->catalogname) {
						ereport(ERROR,
								(errcode(PG_ERRCODE_FEATURE_NOT_SUPPORTED),
								 errmsg("CREATE SCHEMA too many dots: expected \"catalog.schema\" or \"schema\""),
								 parser_errposition(@6)));
					}
					if ($6->schemaname) {
						n->catalogname = $6->schemaname;
						n->schemaname = $6->relname;
					} else {
						n->schemaname = $6->relname;
					}
					if ($7 != NIL)
						ereport(ERROR,
								(errcode(PG_ERRCODE_FEATURE_NOT_SUPPORTED),
								 errmsg("CREATE SCHEMA IF NOT EXISTS cannot include schema elements"),
								 parser_errposition(@7)));
					n->schemaElts = $7;
					n->onconflict = PG_IGNORE_ON_CONFLICT;
					$$ = (PGNode *)n;
				}
			| CREATE_P OR REPLACE SCHEMA qualified_name OptSchemaEltList
				{
					PGCreateSchemaStmt *n = makeNode(PGCreateSchemaStmt);
					if ($5->catalogname) {
						ereport(ERROR,
								(errcode(PG_ERRCODE_FEATURE_NOT_SUPPORTED),
								 errmsg("CREATE SCHEMA too many dots: expected \"catalog.schema\" or \"schema\""),
								 parser_errposition(@5)));
					}
					if ($5->schemaname) {
						n->catalogname = $5->schemaname;
						n->schemaname = $5->relname;
					} else {
						n->schemaname = $5->relname;
					}
					n->schemaElts = $6;
					n->onconflict = PG_REPLACE_ON_CONFLICT;
					$$ = (PGNode *)n;
				}
		;


OptSchemaEltList:
			OptSchemaEltList schema_stmt
				{
					if (@$ < 0)			/* see comments for YYLLOC_DEFAULT */
						@$ = @2;
					$$ = lappend($1, $2);
				}
			| /* EMPTY */
				{ $$ = NIL; }
		;


schema_stmt:
			CreateStmt
			| IndexStmt
			| CreateSeqStmt
			| ViewStmt
		;
#line 1 "third_party/libpg_query/grammar/statements/create_sequence.y"
/*****************************************************************************
 *
 *		QUERY :
 *				CREATE SEQUENCE seqname
 *				ALTER SEQUENCE seqname
 *
 *****************************************************************************/
CreateSeqStmt:
			CREATE_P OptTemp SEQUENCE qualified_name OptSeqOptList
				{
					PGCreateSeqStmt *n = makeNode(PGCreateSeqStmt);
					$4->relpersistence = $2;
					n->sequence = $4;
					n->options = $5;
					n->ownerId = InvalidOid;
					n->onconflict = PG_ERROR_ON_CONFLICT;
					$$ = (PGNode *)n;
				}
			| CREATE_P OptTemp SEQUENCE IF_P NOT EXISTS qualified_name OptSeqOptList
				{
					PGCreateSeqStmt *n = makeNode(PGCreateSeqStmt);
					$7->relpersistence = $2;
					n->sequence = $7;
					n->options = $8;
					n->ownerId = InvalidOid;
					n->onconflict = PG_IGNORE_ON_CONFLICT;
					$$ = (PGNode *)n;
				}
			| CREATE_P OR REPLACE OptTemp SEQUENCE qualified_name OptSeqOptList
				{
					PGCreateSeqStmt *n = makeNode(PGCreateSeqStmt);
					$6->relpersistence = $4;
					n->sequence = $6;
					n->options = $7;
					n->ownerId = InvalidOid;
					n->onconflict = PG_REPLACE_ON_CONFLICT;
					$$ = (PGNode *)n;
				}
		;


OptSeqOptList: SeqOptList							{ $$ = $1; }
			| /*EMPTY*/								{ $$ = NIL; }
		;
#line 1 "third_party/libpg_query/grammar/statements/create_type.y"
/*****************************************************************************
 *
 * Create Type Statement
 *
 *****************************************************************************/
CreateTypeStmt:
				CREATE_P TYPE_P qualified_name AS ENUM_P select_with_parens
				{
					PGCreateTypeStmt *n = makeNode(PGCreateTypeStmt);
					n->typeName = $3;
					n->kind = PG_NEWTYPE_ENUM;
					n->query = $6;
					n->vals = NULL;
					$$ = (PGNode *)n;
				}
				| CREATE_P TYPE_P qualified_name AS ENUM_P '(' opt_enum_val_list ')'
				{
					PGCreateTypeStmt *n = makeNode(PGCreateTypeStmt);
					n->typeName = $3;
					n->kind = PG_NEWTYPE_ENUM;
					n->vals = $7;
					n->query = NULL;
					$$ = (PGNode *)n;
				}
				| CREATE_P TYPE_P qualified_name AS Typename
				{
					PGCreateTypeStmt *n = makeNode(PGCreateTypeStmt);
					n->typeName = $3;
					n->query = NULL;
					auto name = std::string(reinterpret_cast<PGValue *>($5->names->tail->data.ptr_value)->val.str);
					if (name == "enum") {
						n->kind = PG_NEWTYPE_ENUM;
						n->vals = $5->typmods;
					} else {
						n->kind = PG_NEWTYPE_ALIAS;
						n->ofType = $5;
					}
					$$ = (PGNode *)n;
				}
				
		;



opt_enum_val_list:
			enum_val_list { $$ = $1;}
			|				{$$ = NIL;}
			;

enum_val_list: Sconst
				{
					$$ = list_make1(makeStringConst($1, @1));
				}
				| enum_val_list ',' Sconst
				{
					$$ = lappend($1, makeStringConst($3, @3));
				}
				;



#line 1 "third_party/libpg_query/grammar/statements/deallocate.y"
/*****************************************************************************
 *
 *		QUERY:
 *				DEALLOCATE [PREPARE] <plan_name>
 *
 *****************************************************************************/
DeallocateStmt: DEALLOCATE name
					{
						PGDeallocateStmt *n = makeNode(PGDeallocateStmt);
						n->name = $2;
						$$ = (PGNode *) n;
					}
				| DEALLOCATE PREPARE name
					{
						PGDeallocateStmt *n = makeNode(PGDeallocateStmt);
						n->name = $3;
						$$ = (PGNode *) n;
					}
				| DEALLOCATE ALL
					{
						PGDeallocateStmt *n = makeNode(PGDeallocateStmt);
						n->name = NULL;
						$$ = (PGNode *) n;
					}
				| DEALLOCATE PREPARE ALL
					{
						PGDeallocateStmt *n = makeNode(PGDeallocateStmt);
						n->name = NULL;
						$$ = (PGNode *) n;
					}
		;
#line 1 "third_party/libpg_query/grammar/statements/delete.y"
/*****************************************************************************
 *
 *		QUERY:
 *				DELETE STATEMENTS
 *
 *****************************************************************************/
DeleteStmt: opt_with_clause DELETE_P FROM relation_expr_opt_alias
			using_clause where_or_current_clause returning_clause
				{
					PGDeleteStmt *n = makeNode(PGDeleteStmt);
					n->relation = $4;
					n->usingClause = $5;
					n->whereClause = $6;
					n->returningList = $7;
					n->withClause = $1;
					$$ = (PGNode *)n;
				}
			| TRUNCATE opt_table relation_expr_opt_alias
			    {
					PGDeleteStmt *n = makeNode(PGDeleteStmt);
					n->relation = $3;
					n->usingClause = NULL;
					n->whereClause = NULL;
					n->returningList = NULL;
					n->withClause = NULL;
					$$ = (PGNode *)n;
			    }
		;


relation_expr_opt_alias: relation_expr					%prec UMINUS
				{
					$$ = $1;
				}
			| relation_expr ColId
				{
					PGAlias *alias = makeNode(PGAlias);
					alias->aliasname = $2;
					$1->alias = alias;
					$$ = $1;
				}
			| relation_expr AS ColId
				{
					PGAlias *alias = makeNode(PGAlias);
					alias->aliasname = $3;
					$1->alias = alias;
					$$ = $1;
				}
		;


where_or_current_clause:
			WHERE a_expr							{ $$ = $2; }
			| /*EMPTY*/								{ $$ = NULL; }
		;



using_clause:
				USING from_list_opt_comma						{ $$ = $2; }
			| /*EMPTY*/								{ $$ = NIL; }
		;
#line 1 "third_party/libpg_query/grammar/statements/drop.y"
/*****************************************************************************
 *
 *		QUERY:
 *
 *		DROP itemtype [ IF EXISTS ] itemname [, itemname ...]
 *           [ RESTRICT | CASCADE ]
 *
 *****************************************************************************/
DropStmt:	DROP drop_type_any_name IF_P EXISTS any_name_list opt_drop_behavior
				{
					PGDropStmt *n = makeNode(PGDropStmt);
					n->removeType = $2;
					n->missing_ok = true;
					n->objects = $5;
					n->behavior = $6;
					n->concurrent = false;
					$$ = (PGNode *)n;
				}
			| DROP drop_type_any_name any_name_list opt_drop_behavior
				{
					PGDropStmt *n = makeNode(PGDropStmt);
					n->removeType = $2;
					n->missing_ok = false;
					n->objects = $3;
					n->behavior = $4;
					n->concurrent = false;
					$$ = (PGNode *)n;
				}
			| DROP drop_type_name IF_P EXISTS name_list opt_drop_behavior
				{
					PGDropStmt *n = makeNode(PGDropStmt);
					n->removeType = $2;
					n->missing_ok = true;
					n->objects = $5;
					n->behavior = $6;
					n->concurrent = false;
					$$ = (PGNode *)n;
				}
			| DROP drop_type_name name_list opt_drop_behavior
				{
					PGDropStmt *n = makeNode(PGDropStmt);
					n->removeType = $2;
					n->missing_ok = false;
					n->objects = $3;
					n->behavior = $4;
					n->concurrent = false;
					$$ = (PGNode *)n;
				}
			| DROP drop_type_name_on_any_name name ON any_name opt_drop_behavior
				{
					PGDropStmt *n = makeNode(PGDropStmt);
					n->removeType = $2;
					n->objects = list_make1(lappend($5, makeString($3)));
					n->behavior = $6;
					n->missing_ok = false;
					n->concurrent = false;
					$$ = (PGNode *) n;
				}
			| DROP drop_type_name_on_any_name IF_P EXISTS name ON any_name opt_drop_behavior
				{
					PGDropStmt *n = makeNode(PGDropStmt);
					n->removeType = $2;
					n->objects = list_make1(lappend($7, makeString($5)));
					n->behavior = $8;
					n->missing_ok = true;
					n->concurrent = false;
					$$ = (PGNode *) n;
				}
			| DROP TYPE_P type_name_list opt_drop_behavior
				{
					PGDropStmt *n = makeNode(PGDropStmt);
					n->removeType = PG_OBJECT_TYPE;
					n->missing_ok = false;
					n->objects = $3;
					n->behavior = $4;
					n->concurrent = false;
					$$ = (PGNode *) n;
				}
			| DROP TYPE_P IF_P EXISTS type_name_list opt_drop_behavior
				{
					PGDropStmt *n = makeNode(PGDropStmt);
					n->removeType = PG_OBJECT_TYPE;
					n->missing_ok = true;
					n->objects = $5;
					n->behavior = $6;
					n->concurrent = false;
					$$ = (PGNode *) n;
				}
		;


drop_type_any_name:
			TABLE									{ $$ = PG_OBJECT_TABLE; }
			| SEQUENCE								{ $$ = PG_OBJECT_SEQUENCE; }
			| FUNCTION								{ $$ = PG_OBJECT_FUNCTION; }
			| MACRO									{ $$ = PG_OBJECT_FUNCTION; }
			| MACRO TABLE                           { $$ = PG_OBJECT_TABLE_MACRO; }
			| VIEW									{ $$ = PG_OBJECT_VIEW; }
			| MATERIALIZED VIEW						{ $$ = PG_OBJECT_MATVIEW; }
			| INDEX									{ $$ = PG_OBJECT_INDEX; }
			| FOREIGN TABLE							{ $$ = PG_OBJECT_FOREIGN_TABLE; }
			| COLLATION								{ $$ = PG_OBJECT_COLLATION; }
			| CONVERSION_P							{ $$ = PG_OBJECT_CONVERSION; }
			| SCHEMA								{ $$ = PG_OBJECT_SCHEMA; }
			| STATISTICS							{ $$ = PG_OBJECT_STATISTIC_EXT; }
			| TEXT_P SEARCH PARSER					{ $$ = PG_OBJECT_TSPARSER; }
			| TEXT_P SEARCH DICTIONARY				{ $$ = PG_OBJECT_TSDICTIONARY; }
			| TEXT_P SEARCH TEMPLATE				{ $$ = PG_OBJECT_TSTEMPLATE; }
			| TEXT_P SEARCH CONFIGURATION			{ $$ = PG_OBJECT_TSCONFIGURATION; }
		;


drop_type_name:
			ACCESS METHOD							{ $$ = PG_OBJECT_ACCESS_METHOD; }
			| EVENT TRIGGER							{ $$ = PG_OBJECT_EVENT_TRIGGER; }
			| EXTENSION								{ $$ = PG_OBJECT_EXTENSION; }
			| FOREIGN DATA_P WRAPPER				{ $$ = PG_OBJECT_FDW; }
			| PUBLICATION							{ $$ = PG_OBJECT_PUBLICATION; }
			| SERVER								{ $$ = PG_OBJECT_FOREIGN_SERVER; }
		;


any_name_list:
			any_name								{ $$ = list_make1($1); }
			| any_name_list ',' any_name			{ $$ = lappend($1, $3); }
		;


opt_drop_behavior:
			CASCADE						{ $$ = PG_DROP_CASCADE; }
			| RESTRICT					{ $$ = PG_DROP_RESTRICT; }
			| /* EMPTY */				{ $$ = PG_DROP_RESTRICT; /* default */ }
		;


drop_type_name_on_any_name:
			POLICY									{ $$ = PG_OBJECT_POLICY; }
			| RULE									{ $$ = PG_OBJECT_RULE; }
			| TRIGGER								{ $$ = PG_OBJECT_TRIGGER; }
		;
type_name_list:
			Typename								{ $$ = list_make1($1); }
			| type_name_list ',' Typename			{ $$ = lappend($1, $3); }
			;
#line 1 "third_party/libpg_query/grammar/statements/execute.y"
/*****************************************************************************
 *
 * EXECUTE <plan_name> [(params, ...)]
 * CREATE TABLE <name> AS EXECUTE <plan_name> [(params, ...)]
 *
 *****************************************************************************/
ExecuteStmt: EXECUTE name execute_param_clause
				{
					PGExecuteStmt *n = makeNode(PGExecuteStmt);
					n->name = $2;
					n->params = $3;
					$$ = (PGNode *) n;
				}
			| CREATE_P OptTemp TABLE create_as_target AS
				EXECUTE name execute_param_clause opt_with_data
				{
					PGCreateTableAsStmt *ctas = makeNode(PGCreateTableAsStmt);
					PGExecuteStmt *n = makeNode(PGExecuteStmt);
					n->name = $7;
					n->params = $8;
					ctas->query = (PGNode *) n;
					ctas->into = $4;
					ctas->relkind = PG_OBJECT_TABLE;
					ctas->is_select_into = false;
					ctas->onconflict = PG_ERROR_ON_CONFLICT;
					/* cram additional flags into the PGIntoClause */
					$4->rel->relpersistence = $2;
					$4->skipData = !($9);
					$$ = (PGNode *) ctas;
				}
			| CREATE_P OptTemp TABLE IF_P NOT EXISTS create_as_target AS
				EXECUTE name execute_param_clause opt_with_data
				{
					PGCreateTableAsStmt *ctas = makeNode(PGCreateTableAsStmt);
					PGExecuteStmt *n = makeNode(PGExecuteStmt);
					n->name = $10;
					n->params = $11;
					ctas->query = (PGNode *) n;
					ctas->into = $7;
					ctas->relkind = PG_OBJECT_TABLE;
					ctas->is_select_into = false;
					ctas->onconflict = PG_IGNORE_ON_CONFLICT;
					/* cram additional flags into the PGIntoClause */
					$7->rel->relpersistence = $2;
					$7->skipData = !($12);
					$$ = (PGNode *) ctas;
				}
		;


execute_param_expr:  a_expr
				{
					$$ = $1;
				}
			| param_name COLON_EQUALS a_expr
				{
					PGNamedArgExpr *na = makeNode(PGNamedArgExpr);
					na->name = $1;
					na->arg = (PGExpr *) $3;
					na->argnumber = -1;		/* until determined */
					na->location = @1;
					$$ = (PGNode *) na;
				}

execute_param_list:  execute_param_expr
				{
					$$ = list_make1($1);
				}
			| execute_param_list ',' execute_param_expr
				{
					$$ = lappend($1, $3);
				}
		;

execute_param_clause: '(' execute_param_list ')'				{ $$ = $2; }
					| /* EMPTY */					{ $$ = NIL; }
					;
#line 1 "third_party/libpg_query/grammar/statements/explain.y"
/*****************************************************************************
 *
 *		QUERY:
 *				EXPLAIN [ANALYZE] [VERBOSE] query
 *				EXPLAIN ( options ) query
 *
 *****************************************************************************/
ExplainStmt:
		EXPLAIN ExplainableStmt
				{
					PGExplainStmt *n = makeNode(PGExplainStmt);
					n->query = $2;
					n->options = NIL;
					$$ = (PGNode *) n;
				}
		| EXPLAIN analyze_keyword opt_verbose ExplainableStmt
				{
					PGExplainStmt *n = makeNode(PGExplainStmt);
					n->query = $4;
					n->options = list_make1(makeDefElem("analyze", NULL, @2));
					if ($3)
						n->options = lappend(n->options,
											 makeDefElem("verbose", NULL, @3));
					$$ = (PGNode *) n;
				}
		| EXPLAIN VERBOSE ExplainableStmt
				{
					PGExplainStmt *n = makeNode(PGExplainStmt);
					n->query = $3;
					n->options = list_make1(makeDefElem("verbose", NULL, @2));
					$$ = (PGNode *) n;
				}
		| EXPLAIN '(' explain_option_list ')' ExplainableStmt
				{
					PGExplainStmt *n = makeNode(PGExplainStmt);
					n->query = $5;
					n->options = $3;
					$$ = (PGNode *) n;
				}
		;


opt_verbose:
			VERBOSE									{ $$ = true; }
			| /*EMPTY*/								{ $$ = false; }
		;


explain_option_arg:
			opt_boolean_or_string	{ $$ = (PGNode *) makeString($1); }
			| NumericOnly			{ $$ = (PGNode *) $1; }
			| /* EMPTY */			{ $$ = NULL; }
		;


ExplainableStmt:
			AlterObjectSchemaStmt
			| AlterSeqStmt
			| AlterTableStmt
			| CallStmt
			| CheckPointStmt
			| CopyStmt
			| CreateAsStmt
			| CreateFunctionStmt
			| CreateSchemaStmt
			| CreateSeqStmt
			| CreateStmt
			| CreateTypeStmt
			| DeallocateStmt
			| DeleteStmt
			| DropStmt
			| ExecuteStmt
			| IndexStmt
			| InsertStmt
			| LoadStmt
			| PragmaStmt
			| PrepareStmt
			| RenameStmt
			| SelectStmt
			| TransactionStmt
			| UpdateStmt
			| VacuumStmt
			| VariableResetStmt
			| VariableSetStmt
			| VariableShowStmt
			| ViewStmt
		;


NonReservedWord:	IDENT							{ $$ = $1; }
			| unreserved_keyword					{ $$ = pstrdup($1); }
			| other_keyword						{ $$ = pstrdup($1); }
		;


NonReservedWord_or_Sconst:
			NonReservedWord							{ $$ = $1; }
			| Sconst								{ $$ = $1; }
		;


explain_option_list:
			explain_option_elem
				{
					$$ = list_make1($1);
				}
			| explain_option_list ',' explain_option_elem
				{
					$$ = lappend($1, $3);
				}
		;


analyze_keyword:
			ANALYZE									{}
			| ANALYSE /* British */					{}
		;


opt_boolean_or_string:
			TRUE_P									{ $$ = (char*) "true"; }
			| FALSE_P								{ $$ = (char*) "false"; }
			| ON									{ $$ = (char*) "on"; }
			/*
			 * OFF is also accepted as a boolean value, but is handled by
			 * the NonReservedWord rule.  The action for booleans and strings
			 * is the same, so we don't need to distinguish them here.
			 */
			| NonReservedWord_or_Sconst				{ $$ = $1; }
		;


explain_option_elem:
			explain_option_name explain_option_arg
				{
					$$ = makeDefElem($1, $2, @1);
				}
		;


explain_option_name:
			NonReservedWord			{ $$ = $1; }
			| analyze_keyword		{ $$ = (char*) "analyze"; }
		;
#line 1 "third_party/libpg_query/grammar/statements/export.y"
/*****************************************************************************
 *
 * EXPORT/IMPORT stmt
 *
 *****************************************************************************/
ExportStmt:
			EXPORT_P DATABASE Sconst copy_options
				{
					PGExportStmt *n = makeNode(PGExportStmt);
					n->database = NULL;
					n->filename = $3;
					n->options = NIL;
					if ($4) {
						n->options = list_concat(n->options, $4);
					}
					$$ = (PGNode *)n;
				}
			|
			EXPORT_P DATABASE ColId TO Sconst copy_options
				{
					PGExportStmt *n = makeNode(PGExportStmt);
					n->database = $3;
					n->filename = $5;
					n->options = NIL;
					if ($6) {
						n->options = list_concat(n->options, $6);
					}
					$$ = (PGNode *)n;
				}
		;

ImportStmt:
			IMPORT_P DATABASE Sconst
				{
					PGImportStmt *n = makeNode(PGImportStmt);
					n->filename = $3;
					$$ = (PGNode *)n;
				}
		;
#line 1 "third_party/libpg_query/grammar/statements/index.y"
/*****************************************************************************
 *
 *		QUERY: CREATE INDEX
 *
 * Note: we cannot put TABLESPACE clause after WHERE clause unless we are
 * willing to make TABLESPACE a fully reserved word.
 *****************************************************************************/
IndexStmt:	CREATE_P opt_unique INDEX opt_concurrently opt_index_name
			ON qualified_name access_method_clause '(' index_params ')'
			opt_reloptions where_clause
				{
					PGIndexStmt *n = makeNode(PGIndexStmt);
					n->unique = $2;
					n->concurrent = $4;
					n->idxname = $5;
					n->relation = $7;
					n->accessMethod = $8;
					n->indexParams = $10;
					n->options = $12;
					n->whereClause = $13;
					n->excludeOpNames = NIL;
					n->idxcomment = NULL;
					n->indexOid = InvalidOid;
					n->oldNode = InvalidOid;
					n->primary = false;
					n->isconstraint = false;
					n->deferrable = false;
					n->initdeferred = false;
					n->transformed = false;
					n->onconflict = PG_ERROR_ON_CONFLICT;
					$$ = (PGNode *)n;
				}
			| CREATE_P opt_unique INDEX opt_concurrently IF_P NOT EXISTS index_name
			ON qualified_name access_method_clause '(' index_params ')'
			opt_reloptions where_clause
				{
					PGIndexStmt *n = makeNode(PGIndexStmt);
					n->unique = $2;
					n->concurrent = $4;
					n->idxname = $8;
					n->relation = $10;
					n->accessMethod = $11;
					n->indexParams = $13;
					n->options = $15;
					n->whereClause = $16;
					n->excludeOpNames = NIL;
					n->idxcomment = NULL;
					n->indexOid = InvalidOid;
					n->oldNode = InvalidOid;
					n->primary = false;
					n->isconstraint = false;
					n->deferrable = false;
					n->initdeferred = false;
					n->transformed = false;
					n->onconflict = PG_IGNORE_ON_CONFLICT;
					$$ = (PGNode *)n;
				}
		;


access_method:
			ColId									{ $$ = $1; };


access_method_clause:
			USING access_method						{ $$ = $2; }
			| /*EMPTY*/								{ $$ = (char*) DEFAULT_INDEX_TYPE; }
		;


opt_concurrently:
			CONCURRENTLY							{ $$ = true; }
			| /*EMPTY*/								{ $$ = false; }
		;


opt_index_name:
			index_name								{ $$ = $1; }
			| /*EMPTY*/								{ $$ = NULL; }
		;


opt_reloptions:		WITH reloptions					{ $$ = $2; }
			 |		/* EMPTY */						{ $$ = NIL; }
		;


opt_unique:
			UNIQUE									{ $$ = true; }
			| /*EMPTY*/								{ $$ = false; }
		;
#line 1 "third_party/libpg_query/grammar/statements/insert.y"
/*****************************************************************************
 *
 *		QUERY:
 *				INSERT STATEMENTS
 *
 *****************************************************************************/

InsertStmt:
			opt_with_clause INSERT opt_or_action INTO insert_target opt_by_name_or_position insert_rest
			opt_on_conflict returning_clause
				{
					$7->relation = $5;
					$7->onConflictAlias = $3;
					$7->onConflictClause = $8;
					$7->returningList = $9;
					$7->withClause = $1;
					$7->insert_column_order = $6;
					$$ = (PGNode *) $7;
				}
		;

insert_rest:
			SelectStmt
				{
					$$ = makeNode(PGInsertStmt);
					$$->cols = NIL;
					$$->selectStmt = $1;
				}
			| OVERRIDING override_kind VALUE_P SelectStmt
				{
					$$ = makeNode(PGInsertStmt);
					$$->cols = NIL;
					$$->override = $2;
					$$->selectStmt = $4;
				}
			| '(' insert_column_list ')' SelectStmt
				{
					$$ = makeNode(PGInsertStmt);
					$$->cols = $2;
					$$->selectStmt = $4;
				}
			| '(' insert_column_list ')' OVERRIDING override_kind VALUE_P SelectStmt
				{
					$$ = makeNode(PGInsertStmt);
					$$->cols = $2;
					$$->override = $5;
					$$->selectStmt = $7;
				}
			| DEFAULT VALUES
				{
					$$ = makeNode(PGInsertStmt);
					$$->cols = NIL;
					$$->selectStmt = NULL;
				}
		;


insert_target:
			qualified_name
				{
					$$ = $1;
				}
			| qualified_name AS ColId
				{
					$1->alias = makeAlias($3, NIL);
					$$ = $1;
				}
		;

opt_by_name_or_position:
		BY NAME_P				{ $$ = PG_INSERT_BY_NAME; }
		| BY POSITION			{ $$ = PG_INSERT_BY_POSITION; }
		| /* empty */			{ $$ = PG_INSERT_BY_POSITION; }
	;

opt_conf_expr:
			'(' index_params ')' where_clause
				{
					$$ = makeNode(PGInferClause);
					$$->indexElems = $2;
					$$->whereClause = $4;
					$$->conname = NULL;
					$$->location = @1;
				}
			|
			ON CONSTRAINT name
				{
					$$ = makeNode(PGInferClause);
					$$->indexElems = NIL;
					$$->whereClause = NULL;
					$$->conname = $3;
					$$->location = @1;
				}
			| /*EMPTY*/
				{
					$$ = NULL;
				}
		;


opt_with_clause:
		with_clause								{ $$ = $1; }
		| /*EMPTY*/								{ $$ = NULL; }
		;


insert_column_item:
			ColId opt_indirection
				{
					$$ = makeNode(PGResTarget);
					$$->name = $1;
					$$->indirection = check_indirection($2, yyscanner);
					$$->val = NULL;
					$$->location = @1;
				}
		;


set_clause:
			set_target '=' a_expr
				{
					$1->val = (PGNode *) $3;
					$$ = list_make1($1);
				}
			| '(' set_target_list ')' '=' a_expr
				{
					int ncolumns = list_length($2);
					int i = 1;
					PGListCell *col_cell;

					/* Create a PGMultiAssignRef source for each target */
					foreach(col_cell, $2)
					{
						PGResTarget *res_col = (PGResTarget *) lfirst(col_cell);
						PGMultiAssignRef *r = makeNode(PGMultiAssignRef);

						r->source = (PGNode *) $5;
						r->colno = i;
						r->ncolumns = ncolumns;
						res_col->val = (PGNode *) r;
						i++;
					}

					$$ = $2;
				}
		;


opt_or_action:
			OR REPLACE
				{
					$$ = PG_ONCONFLICT_ALIAS_REPLACE;
				}
			|
			OR IGNORE_P
				{
					$$ = PG_ONCONFLICT_ALIAS_IGNORE;
				}
			| /*EMPTY*/
				{
					$$ = PG_ONCONFLICT_ALIAS_NONE;
				}
			;

opt_on_conflict:
			ON CONFLICT opt_conf_expr DO UPDATE SET set_clause_list_opt_comma where_clause
				{
					$$ = makeNode(PGOnConflictClause);
					$$->action = PG_ONCONFLICT_UPDATE;
					$$->infer = $3;
					$$->targetList = $7;
					$$->whereClause = $8;
					$$->location = @1;
				}
			|
			ON CONFLICT opt_conf_expr DO NOTHING
				{
					$$ = makeNode(PGOnConflictClause);
					$$->action = PG_ONCONFLICT_NOTHING;
					$$->infer = $3;
					$$->targetList = NIL;
					$$->whereClause = NULL;
					$$->location = @1;
				}
			| /*EMPTY*/
				{
					$$ = NULL;
				}
		;


index_elem:	ColId opt_collate opt_class opt_asc_desc opt_nulls_order
				{
					$$ = makeNode(PGIndexElem);
					$$->name = $1;
					$$->expr = NULL;
					$$->indexcolname = NULL;
					$$->collation = $2;
					$$->opclass = $3;
					$$->ordering = $4;
					$$->nulls_ordering = $5;
				}
			| func_expr_windowless opt_collate opt_class opt_asc_desc opt_nulls_order
				{
					$$ = makeNode(PGIndexElem);
					$$->name = NULL;
					$$->expr = $1;
					$$->indexcolname = NULL;
					$$->collation = $2;
					$$->opclass = $3;
					$$->ordering = $4;
					$$->nulls_ordering = $5;
				}
			| '(' a_expr ')' opt_collate opt_class opt_asc_desc opt_nulls_order
				{
					$$ = makeNode(PGIndexElem);
					$$->name = NULL;
					$$->expr = $2;
					$$->indexcolname = NULL;
					$$->collation = $4;
					$$->opclass = $5;
					$$->ordering = $6;
					$$->nulls_ordering = $7;
				}
		;


returning_clause:
			RETURNING target_list		{ $$ = $2; }
			| /* EMPTY */				{ $$ = NIL; }
		;



override_kind:
			USER		{ $$ = PG_OVERRIDING_USER_VALUE; }
			| SYSTEM_P	{ $$ = OVERRIDING_SYSTEM_VALUE; }
		;


set_target_list:
			set_target								{ $$ = list_make1($1); }
			| set_target_list ',' set_target		{ $$ = lappend($1,$3); }
		;




opt_collate: COLLATE any_name						{ $$ = $2; }
			| /*EMPTY*/								{ $$ = NIL; }
		;


opt_class:	any_name								{ $$ = $1; }
			| /*EMPTY*/								{ $$ = NIL; }
		;


insert_column_list:
			insert_column_item
					{ $$ = list_make1($1); }
			| insert_column_list ',' insert_column_item
					{ $$ = lappend($1, $3); }
		;


set_clause_list:
			set_clause							{ $$ = $1; }
			| set_clause_list ',' set_clause	{ $$ = list_concat($1,$3); }
		;

set_clause_list_opt_comma:
			set_clause_list								{ $$ = $1; }
			| set_clause_list ','							{ $$ = $1; }
		;

index_params:	index_elem							{ $$ = list_make1($1); }
			| index_params ',' index_elem			{ $$ = lappend($1, $3); }
		;


set_target:
			ColId opt_indirection
				{
					$$ = makeNode(PGResTarget);
					$$->name = $1;
					$$->indirection = check_indirection($2, yyscanner);
					$$->val = NULL;	/* upper production sets this */
					$$->location = @1;
				}
		;
#line 1 "third_party/libpg_query/grammar/statements/load.y"
/*****************************************************************************
 *
 *		QUERY:
 *				LOAD "filename"
 *
 *****************************************************************************/
LoadStmt:	LOAD file_name
				{
					PGLoadStmt *n = makeNode(PGLoadStmt);
					n->filename = $2;
					n->repository = "";
					n->load_type = PG_LOAD_TYPE_LOAD;
					$$ = (PGNode *)n;
				} |
				INSTALL file_name {
                    PGLoadStmt *n = makeNode(PGLoadStmt);
                    n->filename = $2;
                    n->repository = "";
                    n->load_type = PG_LOAD_TYPE_INSTALL;
                    $$ = (PGNode *)n;
				} |
				FORCE INSTALL file_name {
                      PGLoadStmt *n = makeNode(PGLoadStmt);
                      n->filename = $3;
                      n->repository = "";
                      n->load_type = PG_LOAD_TYPE_FORCE_INSTALL;
                      $$ = (PGNode *)n;
                }  |
                INSTALL file_name FROM repo_path{
                      PGLoadStmt *n = makeNode(PGLoadStmt);
                      n->filename = $2;
                      n->repository = $4;
                      n->load_type = PG_LOAD_TYPE_INSTALL;
                      $$ = (PGNode *)n;
                } |
                FORCE INSTALL file_name FROM repo_path {
                        PGLoadStmt *n = makeNode(PGLoadStmt);
                        n->filename = $3;
                        n->repository = $5;
                        n->load_type = PG_LOAD_TYPE_FORCE_INSTALL;
                        $$ = (PGNode *)n;
                  }
		;

file_name:	Sconst								{ $$ = $1; } |
            ColId                               { $$ = $1; };

repo_path:	Sconst								{ $$ = $1; } |
            ColId                               { $$ = $1; };
#line 1 "third_party/libpg_query/grammar/statements/pragma.y"
/*****************************************************************************
 *
 * PRAGMA stmt
 *
 *****************************************************************************/
PragmaStmt:
			PRAGMA_P ColId
				{
					PGPragmaStmt *n = makeNode(PGPragmaStmt);
					n->kind = PG_PRAGMA_TYPE_NOTHING;
					n->name = $2;
					$$ = (PGNode *)n;
				}
			| PRAGMA_P ColId '=' var_list
				{
					PGPragmaStmt *n = makeNode(PGPragmaStmt);
					n->kind = PG_PRAGMA_TYPE_ASSIGNMENT;
					n->name = $2;
					n->args = $4;
					$$ = (PGNode *)n;
				}
			| PRAGMA_P ColId '(' func_arg_list ')'
				{
					PGPragmaStmt *n = makeNode(PGPragmaStmt);
					n->kind = PG_PRAGMA_TYPE_CALL;
					n->name = $2;
					n->args = $4;
					$$ = (PGNode *)n;
				}
		;

#line 1 "third_party/libpg_query/grammar/statements/prepare.y"
/*****************************************************************************
 *
 *		QUERY:
 *				PREPARE <plan_name> [(args, ...)] AS <query>
 *
 *****************************************************************************/
PrepareStmt: PREPARE name prep_type_clause AS PreparableStmt
				{
					PGPrepareStmt *n = makeNode(PGPrepareStmt);
					n->name = $2;
					n->argtypes = $3;
					n->query = $5;
					$$ = (PGNode *) n;
				}
		;


prep_type_clause: '(' type_list ')'			{ $$ = $2; }
				| /* EMPTY */				{ $$ = NIL; }
		;

PreparableStmt:
			SelectStmt
			| InsertStmt
			| UpdateStmt
			| CopyStmt
			| DeleteStmt					/* by default all are $$=$1 */
		;
#line 1 "third_party/libpg_query/grammar/statements/rename.y"
/*****************************************************************************
 *
 * ALTER THING name RENAME TO newname
 *
 *****************************************************************************/
RenameStmt: ALTER SCHEMA name RENAME TO name
				{
					PGRenameStmt *n = makeNode(PGRenameStmt);
					n->renameType = PG_OBJECT_SCHEMA;
					n->subname = $3;
					n->newname = $6;
					n->missing_ok = false;
					$$ = (PGNode *)n;
				}
			| ALTER TABLE relation_expr RENAME TO name
				{
					PGRenameStmt *n = makeNode(PGRenameStmt);
					n->renameType = PG_OBJECT_TABLE;
					n->relation = $3;
					n->subname = NULL;
					n->newname = $6;
					n->missing_ok = false;
					$$ = (PGNode *)n;
				}
			| ALTER TABLE IF_P EXISTS relation_expr RENAME TO name
				{
					PGRenameStmt *n = makeNode(PGRenameStmt);
					n->renameType = PG_OBJECT_TABLE;
					n->relation = $5;
					n->subname = NULL;
					n->newname = $8;
					n->missing_ok = true;
					$$ = (PGNode *)n;
				}
			| ALTER SEQUENCE qualified_name RENAME TO name
				{
					PGRenameStmt *n = makeNode(PGRenameStmt);
					n->renameType = PG_OBJECT_SEQUENCE;
					n->relation = $3;
					n->subname = NULL;
					n->newname = $6;
					n->missing_ok = false;
					$$ = (PGNode *)n;
				}
			| ALTER SEQUENCE IF_P EXISTS qualified_name RENAME TO name
				{
					PGRenameStmt *n = makeNode(PGRenameStmt);
					n->renameType = PG_OBJECT_SEQUENCE;
					n->relation = $5;
					n->subname = NULL;
					n->newname = $8;
					n->missing_ok = true;
					$$ = (PGNode *)n;
				}
			| ALTER VIEW qualified_name RENAME TO name
				{
					PGRenameStmt *n = makeNode(PGRenameStmt);
					n->renameType = PG_OBJECT_VIEW;
					n->relation = $3;
					n->subname = NULL;
					n->newname = $6;
					n->missing_ok = false;
					$$ = (PGNode *)n;
				}
			| ALTER VIEW IF_P EXISTS qualified_name RENAME TO name
				{
					PGRenameStmt *n = makeNode(PGRenameStmt);
					n->renameType = PG_OBJECT_VIEW;
					n->relation = $5;
					n->subname = NULL;
					n->newname = $8;
					n->missing_ok = true;
					$$ = (PGNode *)n;
				}
			| ALTER INDEX qualified_name RENAME TO name
				{
					PGRenameStmt *n = makeNode(PGRenameStmt);
					n->renameType = PG_OBJECT_INDEX;
					n->relation = $3;
					n->subname = NULL;
					n->newname = $6;
					n->missing_ok = false;
					$$ = (PGNode *)n;
				}
			| ALTER INDEX IF_P EXISTS qualified_name RENAME TO name
				{
					PGRenameStmt *n = makeNode(PGRenameStmt);
					n->renameType = PG_OBJECT_INDEX;
					n->relation = $5;
					n->subname = NULL;
					n->newname = $8;
					n->missing_ok = true;
					$$ = (PGNode *)n;
				}
			| ALTER TABLE relation_expr RENAME opt_column name TO name
				{
					PGRenameStmt *n = makeNode(PGRenameStmt);
					n->renameType = PG_OBJECT_COLUMN;
					n->relationType = PG_OBJECT_TABLE;
					n->relation = $3;
					n->subname = $6;
					n->newname = $8;
					n->missing_ok = false;
					$$ = (PGNode *)n;
				}
			| ALTER TABLE IF_P EXISTS relation_expr RENAME opt_column name TO name
				{
					PGRenameStmt *n = makeNode(PGRenameStmt);
					n->renameType = PG_OBJECT_COLUMN;
					n->relationType = PG_OBJECT_TABLE;
					n->relation = $5;
					n->subname = $8;
					n->newname = $10;
					n->missing_ok = true;
					$$ = (PGNode *)n;
				}
			| ALTER TABLE relation_expr RENAME CONSTRAINT name TO name
				{
					PGRenameStmt *n = makeNode(PGRenameStmt);
					n->renameType = PG_OBJECT_TABCONSTRAINT;
					n->relation = $3;
					n->subname = $6;
					n->newname = $8;
					n->missing_ok = false;
					$$ = (PGNode *)n;
				}
			| ALTER TABLE IF_P EXISTS relation_expr RENAME CONSTRAINT name TO name
				{
					PGRenameStmt *n = makeNode(PGRenameStmt);
					n->renameType = PG_OBJECT_TABCONSTRAINT;
					n->relation = $5;
					n->subname = $8;
					n->newname = $10;
					n->missing_ok = true;
					$$ = (PGNode *)n;
				}
		;


opt_column: COLUMN									{ $$ = COLUMN; }
			| /*EMPTY*/								{ $$ = 0; }
		;
#line 1 "third_party/libpg_query/grammar/statements/select.y"

/*****************************************************************************
 *
 *		QUERY:
 *				SELECT STATEMENTS
 *
 *****************************************************************************/

/* A complete SELECT statement looks like this.
 *
 * The rule returns either a single PGSelectStmt node or a tree of them,
 * representing a set-operation tree.
 *
 * There is an ambiguity when a sub-SELECT is within an a_expr and there
 * are excess parentheses: do the parentheses belong to the sub-SELECT or
 * to the surrounding a_expr?  We don't really care, but bison wants to know.
 * To resolve the ambiguity, we are careful to define the grammar so that
 * the decision is staved off as long as possible: as long as we can keep
 * absorbing parentheses into the sub-SELECT, we will do so, and only when
 * it's no longer possible to do that will we decide that parens belong to
 * the expression.	For example, in "SELECT (((SELECT 2)) + 3)" the extra
 * parentheses are treated as part of the sub-select.  The necessity of doing
 * it that way is shown by "SELECT (((SELECT 2)) UNION SELECT 2)".	Had we
 * parsed "((SELECT 2))" as an a_expr, it'd be too late to go back to the
 * SELECT viewpoint when we see the UNION.
 *
 * This approach is implemented by defining a nonterminal select_with_parens,
 * which represents a SELECT with at least one outer layer of parentheses,
 * and being careful to use select_with_parens, never '(' PGSelectStmt ')',
 * in the expression grammar.  We will then have shift-reduce conflicts
 * which we can resolve in favor of always treating '(' <select> ')' as
 * a select_with_parens.  To resolve the conflicts, the productions that
 * conflict with the select_with_parens productions are manually given
 * precedences lower than the precedence of ')', thereby ensuring that we
 * shift ')' (and then reduce to select_with_parens) rather than trying to
 * reduce the inner <select> nonterminal to something else.  We use UMINUS
 * precedence for this, which is a fairly arbitrary choice.
 *
 * To be able to define select_with_parens itself without ambiguity, we need
 * a nonterminal select_no_parens that represents a SELECT structure with no
 * outermost parentheses.  This is a little bit tedious, but it works.
 *
 * In non-expression contexts, we use PGSelectStmt which can represent a SELECT
 * with or without outer parentheses.
 */

SelectStmt: select_no_parens			%prec UMINUS
			| select_with_parens		%prec UMINUS
		;

select_with_parens:
			'(' select_no_parens ')'				{ $$ = $2; }
			| '(' select_with_parens ')'			{ $$ = $2; }
		;

/*
 * This rule parses the equivalent of the standard's <query expression>.
 * The duplicative productions are annoying, but hard to get rid of without
 * creating shift/reduce conflicts.
 *
 *	The locking clause (FOR UPDATE etc) may be before or after LIMIT/OFFSET.
 *	In <=7.2.X, LIMIT/OFFSET had to be after FOR UPDATE
 *	We now support both orderings, but prefer LIMIT/OFFSET before the locking
 * clause.
 *	2002-08-28 bjm
 */
select_no_parens:
			simple_select						{ $$ = $1; }
			| select_clause sort_clause
				{
					insertSelectOptions((PGSelectStmt *) $1, $2, NIL,
										NULL, NULL, NULL,
										yyscanner);
					$$ = $1;
				}
			| select_clause opt_sort_clause for_locking_clause opt_select_limit
				{
					insertSelectOptions((PGSelectStmt *) $1, $2, $3,
										(PGNode*) list_nth($4, 0), (PGNode*) list_nth($4, 1),
										NULL,
										yyscanner);
					$$ = $1;
				}
			| select_clause opt_sort_clause select_limit opt_for_locking_clause
				{
					insertSelectOptions((PGSelectStmt *) $1, $2, $4,
										(PGNode*) list_nth($3, 0), (PGNode*) list_nth($3, 1),
										NULL,
										yyscanner);
					$$ = $1;
				}
			| with_clause select_clause
				{
					insertSelectOptions((PGSelectStmt *) $2, NULL, NIL,
										NULL, NULL,
										$1,
										yyscanner);
					$$ = $2;
				}
			| with_clause select_clause sort_clause
				{
					insertSelectOptions((PGSelectStmt *) $2, $3, NIL,
										NULL, NULL,
										$1,
										yyscanner);
					$$ = $2;
				}
			| with_clause select_clause opt_sort_clause for_locking_clause opt_select_limit
				{
					insertSelectOptions((PGSelectStmt *) $2, $3, $4,
										(PGNode*) list_nth($5, 0), (PGNode*) list_nth($5, 1),
										$1,
										yyscanner);
					$$ = $2;
				}
			| with_clause select_clause opt_sort_clause select_limit opt_for_locking_clause
				{
					insertSelectOptions((PGSelectStmt *) $2, $3, $5,
										(PGNode*) list_nth($4, 0), (PGNode*) list_nth($4, 1),
										$1,
										yyscanner);
					$$ = $2;
				}
		;

select_clause:
			simple_select							{ $$ = $1; }
			| select_with_parens					{ $$ = $1; }
		;

/*
 * This rule parses SELECT statements that can appear within set operations,
 * including UNION, INTERSECT and EXCEPT.  '(' and ')' can be used to specify
 * the ordering of the set operations.	Without '(' and ')' we want the
 * operations to be ordered per the precedence specs at the head of this file.
 *
 * As with select_no_parens, simple_select cannot have outer parentheses,
 * but can have parenthesized subclauses.
 *
 * Note that sort clauses cannot be included at this level --- SQL requires
 *		SELECT foo UNION SELECT bar ORDER BY baz
 * to be parsed as
 *		(SELECT foo UNION SELECT bar) ORDER BY baz
 * not
 *		SELECT foo UNION (SELECT bar ORDER BY baz)
 * Likewise for WITH, FOR UPDATE and LIMIT.  Therefore, those clauses are
 * described as part of the select_no_parens production, not simple_select.
 * This does not limit functionality, because you can reintroduce these
 * clauses inside parentheses.
 *
 * NOTE: only the leftmost component PGSelectStmt should have INTO.
 * However, this is not checked by the grammar; parse analysis must check it.
 */
opt_select:
		SELECT opt_all_clause opt_target_list_opt_comma
			{
				$$ = $3;
			}
		| /* empty */
			{
				PGAStar *star = makeNode(PGAStar);
				$$ = list_make1(star);
			}
	;


simple_select:
			SELECT opt_all_clause opt_target_list_opt_comma
			into_clause from_clause where_clause
			group_clause having_clause window_clause qualify_clause sample_clause
				{
					PGSelectStmt *n = makeNode(PGSelectStmt);
					n->targetList = $3;
					n->intoClause = $4;
					n->fromClause = $5;
					n->whereClause = $6;
					n->groupClause = $7;
					n->havingClause = $8;
					n->windowClause = $9;
					n->qualifyClause = $10;
					n->sampleOptions = $11;
					$$ = (PGNode *)n;
				}
			| SELECT distinct_clause target_list_opt_comma
			into_clause from_clause where_clause
			group_clause having_clause window_clause qualify_clause sample_clause
				{
					PGSelectStmt *n = makeNode(PGSelectStmt);
					n->distinctClause = $2;
					n->targetList = $3;
					n->intoClause = $4;
					n->fromClause = $5;
					n->whereClause = $6;
					n->groupClause = $7;
					n->havingClause = $8;
					n->windowClause = $9;
					n->qualifyClause = $10;
					n->sampleOptions = $11;
					$$ = (PGNode *)n;
				}
			|  FROM from_list opt_select
			into_clause where_clause
			group_clause having_clause window_clause qualify_clause sample_clause
				{
					PGSelectStmt *n = makeNode(PGSelectStmt);
					n->targetList = $3;
					n->fromClause = $2;
					n->intoClause = $4;
					n->whereClause = $5;
					n->groupClause = $6;
					n->havingClause = $7;
					n->windowClause = $8;
					n->qualifyClause = $9;
					n->sampleOptions = $10;
					$$ = (PGNode *)n;
				}
			|
			FROM from_list SELECT distinct_clause target_list_opt_comma
			into_clause where_clause
			group_clause having_clause window_clause qualify_clause sample_clause
				{
					PGSelectStmt *n = makeNode(PGSelectStmt);
					n->targetList = $5;
					n->distinctClause = $4;
					n->fromClause = $2;
					n->intoClause = $6;
					n->whereClause = $7;
					n->groupClause = $8;
					n->havingClause = $9;
					n->windowClause = $10;
					n->qualifyClause = $11;
					n->sampleOptions = $12;
					$$ = (PGNode *)n;
				}
			| values_clause_opt_comma							{ $$ = $1; }
			| TABLE relation_expr
				{
					/* same as SELECT * FROM relation_expr */
					PGColumnRef *cr = makeNode(PGColumnRef);
					PGResTarget *rt = makeNode(PGResTarget);
					PGSelectStmt *n = makeNode(PGSelectStmt);

					cr->fields = list_make1(makeNode(PGAStar));
					cr->location = -1;

					rt->name = NULL;
					rt->indirection = NIL;
					rt->val = (PGNode *)cr;
					rt->location = -1;

					n->targetList = list_make1(rt);
					n->fromClause = list_make1($2);
					$$ = (PGNode *)n;
				}
            | select_clause UNION all_or_distinct by_name select_clause
				{
					$$ = makeSetOp(PG_SETOP_UNION_BY_NAME, $3, $1, $5);
				}
			| select_clause UNION all_or_distinct select_clause
				{
					$$ = makeSetOp(PG_SETOP_UNION, $3, $1, $4);
				}
			| select_clause INTERSECT all_or_distinct select_clause
				{
					$$ = makeSetOp(PG_SETOP_INTERSECT, $3, $1, $4);
				}
			| select_clause EXCEPT all_or_distinct select_clause
				{
					$$ = makeSetOp(PG_SETOP_EXCEPT, $3, $1, $4);
				}
			| pivot_keyword table_ref USING target_list_opt_comma
				{
					PGSelectStmt *res = makeNode(PGSelectStmt);
					PGPivotStmt *n = makeNode(PGPivotStmt);
					n->source = $2;
					n->aggrs = $4;
					res->pivot = n;
					$$ = (PGNode *)res;
				}
			| pivot_keyword table_ref USING target_list_opt_comma GROUP_P BY name_list_opt_comma_opt_bracket
				{
					PGSelectStmt *res = makeNode(PGSelectStmt);
					PGPivotStmt *n = makeNode(PGPivotStmt);
					n->source = $2;
					n->aggrs = $4;
					n->groups = $7;
					res->pivot = n;
					$$ = (PGNode *)res;
				}
			| pivot_keyword table_ref GROUP_P BY name_list_opt_comma_opt_bracket
				{
					PGSelectStmt *res = makeNode(PGSelectStmt);
					PGPivotStmt *n = makeNode(PGPivotStmt);
					n->source = $2;
					n->groups = $5;
					res->pivot = n;
					$$ = (PGNode *)res;
				}
			| pivot_keyword table_ref ON pivot_column_list
				{
					PGSelectStmt *res = makeNode(PGSelectStmt);
					PGPivotStmt *n = makeNode(PGPivotStmt);
					n->source = $2;
					n->columns = $4;
					res->pivot = n;
					$$ = (PGNode *)res;
				}
			| pivot_keyword table_ref ON pivot_column_list GROUP_P BY name_list_opt_comma_opt_bracket
				{
					PGSelectStmt *res = makeNode(PGSelectStmt);
					PGPivotStmt *n = makeNode(PGPivotStmt);
					n->source = $2;
					n->columns = $4;
					n->groups = $7;
					res->pivot = n;
					$$ = (PGNode *)res;
				}
			| pivot_keyword table_ref ON pivot_column_list USING target_list_opt_comma
				{
					PGSelectStmt *res = makeNode(PGSelectStmt);
					PGPivotStmt *n = makeNode(PGPivotStmt);
					n->source = $2;
					n->columns = $4;
					n->aggrs = $6;
					res->pivot = n;
					$$ = (PGNode *)res;
				}
			| pivot_keyword table_ref ON pivot_column_list USING target_list_opt_comma GROUP_P BY name_list_opt_comma_opt_bracket
				{
					PGSelectStmt *res = makeNode(PGSelectStmt);
					PGPivotStmt *n = makeNode(PGPivotStmt);
					n->source = $2;
					n->columns = $4;
					n->aggrs = $6;
					n->groups = $9;
					res->pivot = n;
					$$ = (PGNode *)res;
				}
			| unpivot_keyword table_ref ON target_list_opt_comma INTO NAME_P name value_or_values name_list_opt_comma_opt_bracket
				{
					PGSelectStmt *res = makeNode(PGSelectStmt);
					PGPivotStmt *n = makeNode(PGPivotStmt);
					n->source = $2;
					n->unpivots = $9;
					PGPivot *piv = makeNode(PGPivot);
					piv->unpivot_columns = list_make1(makeString($7));
					piv->pivot_value = $4;
					n->columns = list_make1(piv);

					res->pivot = n;
					$$ = (PGNode *)res;
				}
			| unpivot_keyword table_ref ON target_list_opt_comma
				{
					PGSelectStmt *res = makeNode(PGSelectStmt);
					PGPivotStmt *n = makeNode(PGPivotStmt);
					n->source = $2;
					n->unpivots = list_make1(makeString("value"));
					PGPivot *piv = makeNode(PGPivot);
					piv->unpivot_columns = list_make1(makeString("name"));
					piv->pivot_value = $4;
					n->columns = list_make1(piv);

					res->pivot = n;
					$$ = (PGNode *)res;
				}
		;

value_or_values:
		VALUE_P | VALUES
	;

pivot_keyword:
		PIVOT | PIVOT_WIDER
	;

unpivot_keyword:
		UNPIVOT | PIVOT_LONGER
	;

pivot_column_entry:
			b_expr
			{
				PGPivot *n = makeNode(PGPivot);
				n->pivot_columns = list_make1($1);
				$$ = (PGNode *) n;
			}
			| b_expr IN_P '(' select_no_parens ')'
			{
				PGPivot *n = makeNode(PGPivot);
				n->pivot_columns = list_make1($1);
				n->subquery = $4;
				$$ = (PGNode *) n;
			}
			| single_pivot_value													{ $$ = $1; }
		;

pivot_column_list_internal:
			pivot_column_entry												{ $$ = list_make1($1); }
			| pivot_column_list_internal ',' pivot_column_entry 			{ $$ = lappend($1, $3); }
		;

pivot_column_list:
			pivot_column_list_internal										{ $$ = $1; }
			| pivot_column_list_internal ','								{ $$ = $1; }
		;

/*
 * SQL standard WITH clause looks like:
 *
 * WITH [ RECURSIVE ] <query name> [ (<column>,...) ]
 *		AS (query) [ SEARCH or CYCLE clause ]
 *
 * We don't currently support the SEARCH or CYCLE clause.
 *
 * Recognizing WITH_LA here allows a CTE to be named TIME or ORDINALITY.
 */
with_clause:
		WITH cte_list
			{
				$$ = makeNode(PGWithClause);
				$$->ctes = $2;
				$$->recursive = false;
				$$->location = @1;
			}
		| WITH_LA cte_list
			{
				$$ = makeNode(PGWithClause);
				$$->ctes = $2;
				$$->recursive = false;
				$$->location = @1;
			}
		| WITH RECURSIVE cte_list
			{
				$$ = makeNode(PGWithClause);
				$$->ctes = $3;
				$$->recursive = true;
				$$->location = @1;
			}
		;

cte_list:
		common_table_expr						{ $$ = list_make1($1); }
		| cte_list ',' common_table_expr		{ $$ = lappend($1, $3); }
		;

common_table_expr:  name opt_name_list AS opt_materialized '(' PreparableStmt ')'
			{
				PGCommonTableExpr *n = makeNode(PGCommonTableExpr);
				n->ctename = $1;
				n->aliascolnames = $2;
				n->ctematerialized = $4;
				n->ctequery = $6;
				n->location = @1;
				$$ = (PGNode *) n;
			}
		;

opt_materialized:
		MATERIALIZED							{ $$ = PGCTEMaterializeAlways; }
		| NOT MATERIALIZED						{ $$ = PGCTEMaterializeNever; }
		| /*EMPTY*/								{ $$ = PGCTEMaterializeDefault; }
		;

into_clause:
			INTO OptTempTableName
				{
					$$ = makeNode(PGIntoClause);
					$$->rel = $2;
					$$->colNames = NIL;
					$$->options = NIL;
					$$->onCommit = PG_ONCOMMIT_NOOP;
					$$->viewQuery = NULL;
					$$->skipData = false;
				}
			| /*EMPTY*/
				{ $$ = NULL; }
		;

/*
 * Redundancy here is needed to avoid shift/reduce conflicts,
 * since TEMP is not a reserved word.  See also OptTemp.
 */
OptTempTableName:
			TEMPORARY opt_table qualified_name
				{
					$$ = $3;
					$$->relpersistence = PG_RELPERSISTENCE_TEMP;
				}
			| TEMP opt_table qualified_name
				{
					$$ = $3;
					$$->relpersistence = PG_RELPERSISTENCE_TEMP;
				}
			| LOCAL TEMPORARY opt_table qualified_name
				{
					$$ = $4;
					$$->relpersistence = PG_RELPERSISTENCE_TEMP;
				}
			| LOCAL TEMP opt_table qualified_name
				{
					$$ = $4;
					$$->relpersistence = PG_RELPERSISTENCE_TEMP;
				}
			| GLOBAL TEMPORARY opt_table qualified_name
				{
					ereport(PGWARNING,
							(errmsg("GLOBAL is deprecated in temporary table creation"),
							 parser_errposition(@1)));
					$$ = $4;
					$$->relpersistence = PG_RELPERSISTENCE_TEMP;
				}
			| GLOBAL TEMP opt_table qualified_name
				{
					ereport(PGWARNING,
							(errmsg("GLOBAL is deprecated in temporary table creation"),
							 parser_errposition(@1)));
					$$ = $4;
					$$->relpersistence = PG_RELPERSISTENCE_TEMP;
				}
			| UNLOGGED opt_table qualified_name
				{
					$$ = $3;
					$$->relpersistence = PG_RELPERSISTENCE_UNLOGGED;
				}
			| TABLE qualified_name
				{
					$$ = $2;
					$$->relpersistence = RELPERSISTENCE_PERMANENT;
				}
			| qualified_name
				{
					$$ = $1;
					$$->relpersistence = RELPERSISTENCE_PERMANENT;
				}
		;

opt_table:	TABLE									{}
			| /*EMPTY*/								{}
		;

all_or_distinct:
			ALL										{ $$ = true; }
			| DISTINCT								{ $$ = false; }
			| /*EMPTY*/								{ $$ = false; }
		;

by_name:
            BY NAME_P                                     { }
        ;

/* We use (NIL) as a placeholder to indicate that all target expressions
 * should be placed in the DISTINCT list during parsetree analysis.
 */
distinct_clause:
			DISTINCT								{ $$ = list_make1(NIL); }
			| DISTINCT ON '(' expr_list_opt_comma ')'			{ $$ = $4; }
		;

opt_all_clause:
			ALL										{ $$ = NIL;}
			| /*EMPTY*/								{ $$ = NIL; }
		;

opt_ignore_nulls:
			IGNORE_P NULLS_P						{ $$ = true;}
			| RESPECT_P NULLS_P						{ $$ = false;}
			| /*EMPTY*/								{ $$ = false; }
		;

opt_sort_clause:
			sort_clause								{ $$ = $1;}
			| /*EMPTY*/								{ $$ = NIL; }
		;

sort_clause:
			ORDER BY sortby_list					{ $$ = $3; }
			| ORDER BY ALL opt_asc_desc opt_nulls_order
				{
					PGSortBy *sort = makeNode(PGSortBy);
					PGAStar *star = makeNode(PGAStar);
					star->columns = true;
					star->location = @3;
					sort->node = (PGNode *) star;
					sort->sortby_dir = $4;
					sort->sortby_nulls = $5;
					sort->useOp = NIL;
					sort->location = -1;		/* no operator */
					$$ = list_make1(sort);
				}
		;

sortby_list:
			sortby									{ $$ = list_make1($1); }
			| sortby_list ',' sortby				{ $$ = lappend($1, $3); }
		;

sortby:		a_expr USING qual_all_Op opt_nulls_order
				{
					$$ = makeNode(PGSortBy);
					$$->node = $1;
					$$->sortby_dir = SORTBY_USING;
					$$->sortby_nulls = $4;
					$$->useOp = $3;
					$$->location = @3;
				}
			| a_expr opt_asc_desc opt_nulls_order
				{
					$$ = makeNode(PGSortBy);
					$$->node = $1;
					$$->sortby_dir = $2;
					$$->sortby_nulls = $3;
					$$->useOp = NIL;
					$$->location = -1;		/* no operator */
				}
		;

opt_asc_desc: ASC_P							{ $$ = PG_SORTBY_ASC; }
			| DESC_P						{ $$ = PG_SORTBY_DESC; }
			| /*EMPTY*/						{ $$ = PG_SORTBY_DEFAULT; }
		;

opt_nulls_order: NULLS_LA FIRST_P			{ $$ = PG_SORTBY_NULLS_FIRST; }
			| NULLS_LA LAST_P				{ $$ = PG_SORTBY_NULLS_LAST; }
			| /*EMPTY*/						{ $$ = PG_SORTBY_NULLS_DEFAULT; }
		;

select_limit:
			limit_clause offset_clause			{ $$ = list_make2($2, $1); }
			| offset_clause limit_clause		{ $$ = list_make2($1, $2); }
			| limit_clause						{ $$ = list_make2(NULL, $1); }
			| offset_clause						{ $$ = list_make2($1, NULL); }
		;

opt_select_limit:
			select_limit						{ $$ = $1; }
			| /* EMPTY */						{ $$ = list_make2(NULL,NULL); }
		;

limit_clause:
			LIMIT select_limit_value
				{ $$ = $2; }
			| LIMIT select_limit_value ',' select_offset_value
				{
					/* Disabled because it was too confusing, bjm 2002-02-18 */
					ereport(ERROR,
							(errcode(PG_ERRCODE_SYNTAX_ERROR),
							 errmsg("LIMIT #,# syntax is not supported"),
							 errhint("Use separate LIMIT and OFFSET clauses."),
							 parser_errposition(@1)));
				}
			/* SQL:2008 syntax */
			/* to avoid shift/reduce conflicts, handle the optional value with
			 * a separate production rather than an opt_ expression.  The fact
			 * that ONLY is fully reserved means that this way, we defer any
			 * decision about what rule reduces ROW or ROWS to the point where
			 * we can see the ONLY token in the lookahead slot.
			 */
			| FETCH first_or_next select_fetch_first_value row_or_rows ONLY
				{ $$ = $3; }
			| FETCH first_or_next row_or_rows ONLY
				{ $$ = makeIntConst(1, -1); }
		;

offset_clause:
			OFFSET select_offset_value
				{ $$ = $2; }
			/* SQL:2008 syntax */
			| OFFSET select_fetch_first_value row_or_rows
				{ $$ = $2; }
		;

/*
 * SAMPLE clause
 */
sample_count:
	FCONST '%'
		{
			$$ = makeSampleSize(makeFloat($1), true);
		}
	| ICONST '%'
		{
			$$ = makeSampleSize(makeInteger($1), true);
		}
	| FCONST PERCENT
		{
			$$ = makeSampleSize(makeFloat($1), true);
		}
	| ICONST PERCENT
		{
			$$ = makeSampleSize(makeInteger($1), true);
		}
	| ICONST
		{
			$$ = makeSampleSize(makeInteger($1), false);
		}
	| ICONST ROWS
		{
			$$ = makeSampleSize(makeInteger($1), false);
		}
	;

sample_clause:
			USING SAMPLE tablesample_entry
				{
					$$ = $3;
				}
			| /* EMPTY */
				{ $$ = NULL; }
		;

/*
 * TABLESAMPLE decoration in a FROM item
 */
opt_sample_func:
			ColId					{ $$ = $1; }
			| /*EMPTY*/				{ $$ = NULL; }
		;

tablesample_entry:
	opt_sample_func '(' sample_count ')' opt_repeatable_clause
				{
					int seed = $5;
					$$ = makeSampleOptions($3, $1, &seed, @1);
				}
	| sample_count
		{
			$$ = makeSampleOptions($1, NULL, NULL, @1);
		}
	| sample_count '(' ColId ')'
		{
			$$ = makeSampleOptions($1, $3, NULL, @1);
		}
	| sample_count '(' ColId ',' ICONST ')'
		{
			int seed = $5;
			$$ = makeSampleOptions($1, $3, &seed, @1);
		}
	;

tablesample_clause:
			TABLESAMPLE tablesample_entry
				{
					$$ = $2;
				}
		;

opt_tablesample_clause:
			tablesample_clause			{ $$ = $1; }
			| /*EMPTY*/					{ $$ = NULL; }
		;


opt_repeatable_clause:
			REPEATABLE '(' ICONST ')'	{ $$ = $3; }
			| /*EMPTY*/					{ $$ = -1; }
		;

select_limit_value:
			a_expr									{ $$ = $1; }
			| ALL
				{
					/* LIMIT ALL is represented as a NULL constant */
					$$ = makeNullAConst(@1);
				}
			| a_expr '%'
				{ $$ = makeLimitPercent($1); }
			| FCONST PERCENT
				{ $$ = makeLimitPercent(makeFloatConst($1,@1)); }
			| ICONST PERCENT
				{ $$ = makeLimitPercent(makeIntConst($1,@1)); }
		;

select_offset_value:
			a_expr									{ $$ = $1; }
		;

/*
 * Allowing full expressions without parentheses causes various parsing
 * problems with the trailing ROW/ROWS key words.  SQL spec only calls for
 * <simple value specification>, which is either a literal or a parameter (but
 * an <SQL parameter reference> could be an identifier, bringing up conflicts
 * with ROW/ROWS). We solve this by leveraging the presence of ONLY (see above)
 * to determine whether the expression is missing rather than trying to make it
 * optional in this rule.
 *
 * c_expr covers almost all the spec-required cases (and more), but it doesn't
 * cover signed numeric literals, which are allowed by the spec. So we include
 * those here explicitly. We need FCONST as well as ICONST because values that
 * don't fit in the platform's "long", but do fit in bigint, should still be
 * accepted here. (This is possible in 64-bit Windows as well as all 32-bit
 * builds.)
 */
select_fetch_first_value:
			c_expr									{ $$ = $1; }
			| '+' I_or_F_const
				{ $$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_OP, "+", NULL, $2, @1); }
			| '-' I_or_F_const
				{ $$ = doNegate($2, @1); }
		;

I_or_F_const:
			Iconst									{ $$ = makeIntConst($1,@1); }
			| FCONST								{ $$ = makeFloatConst($1,@1); }
		;

/* noise words */
row_or_rows: ROW									{ $$ = 0; }
			| ROWS									{ $$ = 0; }
		;

first_or_next: FIRST_P								{ $$ = 0; }
			| NEXT									{ $$ = 0; }
		;


/*
 * This syntax for group_clause tries to follow the spec quite closely.
 * However, the spec allows only column references, not expressions,
 * which introduces an ambiguity between implicit row constructors
 * (a,b) and lists of column references.
 *
 * We handle this by using the a_expr production for what the spec calls
 * <ordinary grouping set>, which in the spec represents either one column
 * reference or a parenthesized list of column references. Then, we check the
 * top node of the a_expr to see if it's an implicit PGRowExpr, and if so, just
 * grab and use the list, discarding the node. (this is done in parse analysis,
 * not here)
 *
 * (we abuse the row_format field of PGRowExpr to distinguish implicit and
 * explicit row constructors; it's debatable if anyone sanely wants to use them
 * in a group clause, but if they have a reason to, we make it possible.)
 *
 * Each item in the group_clause list is either an expression tree or a
 * PGGroupingSet node of some type.
 */
group_clause:
			GROUP_P BY group_by_list_opt_comma				{ $$ = $3; }
			| GROUP_P BY ALL
				{
					PGNode *node = (PGNode *) makeGroupingSet(GROUPING_SET_ALL, NIL, @3);
					$$ = list_make1(node);
				}
			| /*EMPTY*/								{ $$ = NIL; }
		;

group_by_list:
			group_by_item							{ $$ = list_make1($1); }
			| group_by_list ',' group_by_item		{ $$ = lappend($1,$3); }
		;

group_by_list_opt_comma:
			group_by_list								{ $$ = $1; }
			| group_by_list ','							{ $$ = $1; }
		;

group_by_item:
			a_expr									{ $$ = $1; }
			| empty_grouping_set					{ $$ = $1; }
			| cube_clause							{ $$ = $1; }
			| rollup_clause							{ $$ = $1; }
			| grouping_sets_clause					{ $$ = $1; }
		;

empty_grouping_set:
			'(' ')'
				{
					$$ = (PGNode *) makeGroupingSet(GROUPING_SET_EMPTY, NIL, @1);
				}
		;

/*
 * These hacks rely on setting precedence of CUBE and ROLLUP below that of '(',
 * so that they shift in these rules rather than reducing the conflicting
 * unreserved_keyword rule.
 */

rollup_clause:
			ROLLUP '(' expr_list_opt_comma ')'
				{
					$$ = (PGNode *) makeGroupingSet(GROUPING_SET_ROLLUP, $3, @1);
				}
		;

cube_clause:
			CUBE '(' expr_list_opt_comma ')'
				{
					$$ = (PGNode *) makeGroupingSet(GROUPING_SET_CUBE, $3, @1);
				}
		;

grouping_sets_clause:
			GROUPING SETS '(' group_by_list_opt_comma ')'
				{
					$$ = (PGNode *) makeGroupingSet(GROUPING_SET_SETS, $4, @1);
				}
		;

grouping_or_grouping_id:
		GROUPING								{ $$ = NULL; }
		| GROUPING_ID							{ $$ = NULL; }
		;

having_clause:
			HAVING a_expr							{ $$ = $2; }
			| /*EMPTY*/								{ $$ = NULL; }
		;

qualify_clause:
			QUALIFY a_expr							{ $$ = $2; }
			| /*EMPTY*/								{ $$ = NULL; }
		;

for_locking_clause:
			for_locking_items						{ $$ = $1; }
			| FOR READ_P ONLY							{ $$ = NIL; }
		;

opt_for_locking_clause:
			for_locking_clause						{ $$ = $1; }
			| /* EMPTY */							{ $$ = NIL; }
		;

for_locking_items:
			for_locking_item						{ $$ = list_make1($1); }
			| for_locking_items for_locking_item	{ $$ = lappend($1, $2); }
		;

for_locking_item:
			for_locking_strength locked_rels_list opt_nowait_or_skip
				{
					PGLockingClause *n = makeNode(PGLockingClause);
					n->lockedRels = $2;
					n->strength = $1;
					n->waitPolicy = $3;
					$$ = (PGNode *) n;
				}
		;

for_locking_strength:
			FOR UPDATE 							{ $$ = LCS_FORUPDATE; }
			| FOR NO KEY UPDATE 				{ $$ = PG_LCS_FORNOKEYUPDATE; }
			| FOR SHARE 						{ $$ = PG_LCS_FORSHARE; }
			| FOR KEY SHARE 					{ $$ = PG_LCS_FORKEYSHARE; }
		;

locked_rels_list:
			OF qualified_name_list					{ $$ = $2; }
			| /* EMPTY */							{ $$ = NIL; }
		;


opt_nowait_or_skip:
			NOWAIT							{ $$ = LockWaitError; }
			| SKIP LOCKED					{ $$ = PGLockWaitSkip; }
			| /*EMPTY*/						{ $$ = PGLockWaitBlock; }
		;

/*
 * We should allow ROW '(' expr_list ')' too, but that seems to require
 * making VALUES a fully reserved word, which will probably break more apps
 * than allowing the noise-word is worth.
 */
values_clause:
			VALUES '(' expr_list_opt_comma ')'
				{
					PGSelectStmt *n = makeNode(PGSelectStmt);
					n->valuesLists = list_make1($3);
					$$ = (PGNode *) n;
				}
			| values_clause ',' '(' expr_list_opt_comma ')'
				{
					PGSelectStmt *n = (PGSelectStmt *) $1;
					n->valuesLists = lappend(n->valuesLists, $4);
					$$ = (PGNode *) n;
				}
		;

values_clause_opt_comma:
			values_clause				{ $$ = $1; }
			| values_clause ','			{ $$ = $1; }
		;


/*****************************************************************************
 *
 *	clauses common to all Optimizable Stmts:
 *		from_clause		- allow list of both JOIN expressions and table names
 *		where_clause	- qualifications for joins or restrictions
 *
 *****************************************************************************/

from_clause:
			FROM from_list_opt_comma							{ $$ = $2; }
			| /*EMPTY*/								{ $$ = NIL; }
		;

from_list:
			table_ref								{ $$ = list_make1($1); }
			| from_list ',' table_ref				{ $$ = lappend($1, $3); }
		;

from_list_opt_comma:
			from_list								{ $$ = $1; }
			| from_list ','							{ $$ = $1; }
		;

/*
 * table_ref is where an alias clause can be attached.
 */
table_ref:	relation_expr opt_alias_clause opt_tablesample_clause
				{
					$1->alias = $2;
					$1->sample = $3;
					$$ = (PGNode *) $1;
				}
			| func_table func_alias_clause opt_tablesample_clause
				{
					PGRangeFunction *n = (PGRangeFunction *) $1;
					n->alias = (PGAlias*) linitial($2);
					n->coldeflist = (PGList*) lsecond($2);
					n->sample = $3;
					$$ = (PGNode *) n;
				}
			| values_clause_opt_comma alias_clause opt_tablesample_clause
			{
				PGRangeSubselect *n = makeNode(PGRangeSubselect);
				n->lateral = false;
				n->subquery = $1;
				n->alias = $2;
				n->sample = $3;
				$$ = (PGNode *) n;
			}
			| LATERAL_P func_table func_alias_clause
				{
					PGRangeFunction *n = (PGRangeFunction *) $2;
					n->lateral = true;
					n->alias = (PGAlias*) linitial($3);
					n->coldeflist = (PGList*) lsecond($3);
					$$ = (PGNode *) n;
				}
			| select_with_parens opt_alias_clause opt_tablesample_clause
				{
					PGRangeSubselect *n = makeNode(PGRangeSubselect);
					n->lateral = false;
					n->subquery = $1;
					n->alias = $2;
					n->sample = $3;
					$$ = (PGNode *) n;
				}
			| LATERAL_P select_with_parens opt_alias_clause
				{
					PGRangeSubselect *n = makeNode(PGRangeSubselect);
					n->lateral = true;
					n->subquery = $2;
					n->alias = $3;
					n->sample = NULL;
					$$ = (PGNode *) n;
				}
			| joined_table
				{
					$$ = (PGNode *) $1;
				}
			| '(' joined_table ')' alias_clause
				{
					$2->alias = $4;
					$$ = (PGNode *) $2;
				}
			| table_ref PIVOT '(' target_list_opt_comma FOR pivot_value_list opt_pivot_group_by ')' opt_alias_clause
				{
					PGPivotExpr *n = makeNode(PGPivotExpr);
					n->source = $1;
					n->aggrs = $4;
					n->pivots = $6;
					n->groups = $7;
					n->alias = $9;
					$$ = (PGNode *) n;
				}
			| table_ref UNPIVOT opt_include_nulls '(' unpivot_header FOR unpivot_value_list ')' opt_alias_clause
				{
					PGPivotExpr *n = makeNode(PGPivotExpr);
					n->source = $1;
					n->include_nulls = $3;
					n->unpivots = $5;
					n->pivots = $7;
					n->alias = $9;
					$$ = (PGNode *) n;
				}
		;

opt_pivot_group_by:
	GROUP_P BY name_list_opt_comma		{ $$ = $3; }
	| /* empty */						{ $$ = NULL; }

opt_include_nulls:
	INCLUDE_P NULLS_P					{ $$ = true; }
	| EXCLUDE NULLS_P					{ $$ = false; }
	| /* empty */						{ $$ = false; }

single_pivot_value:
	b_expr IN_P '(' target_list_opt_comma ')'
		{
			PGPivot *n = makeNode(PGPivot);
			n->pivot_columns = list_make1($1);
			n->pivot_value = $4;
			$$ = (PGNode *) n;
		}
	|
	b_expr IN_P ColIdOrString
		{
			PGPivot *n = makeNode(PGPivot);
			n->pivot_columns = list_make1($1);
			n->pivot_enum = $3;
			$$ = (PGNode *) n;
		}
	;

pivot_header:
	d_expr		                 			{ $$ = list_make1($1); }
	| '(' c_expr_list_opt_comma ')' 		{ $$ = $2; }

pivot_value:
	pivot_header IN_P '(' target_list_opt_comma ')'
		{
			PGPivot *n = makeNode(PGPivot);
			n->pivot_columns = $1;
			n->pivot_value = $4;
			$$ = (PGNode *) n;
		}
	|
	pivot_header IN_P ColIdOrString
		{
			PGPivot *n = makeNode(PGPivot);
			n->pivot_columns = $1;
			n->pivot_enum = $3;
			$$ = (PGNode *) n;
		}
	;

pivot_value_list:	pivot_value
				{
					$$ = list_make1($1);
				}
			| pivot_value_list pivot_value
				{
					$$ = lappend($1, $2);
				}
		;

unpivot_header:
		ColIdOrString 				  { $$ = list_make1(makeString($1)); }
		| '(' name_list_opt_comma ')' { $$ = $2; }
	;

unpivot_value:
	unpivot_header IN_P '(' target_list_opt_comma ')'
		{
			PGPivot *n = makeNode(PGPivot);
			n->unpivot_columns = $1;
			n->pivot_value = $4;
			$$ = (PGNode *) n;
		}
	;

unpivot_value_list:	unpivot_value
				{
					$$ = list_make1($1);
				}
			| unpivot_value_list unpivot_value
				{
					$$ = lappend($1, $2);
				}
		;

/*
 * It may seem silly to separate joined_table from table_ref, but there is
 * method in SQL's madness: if you don't do it this way you get reduce-
 * reduce conflicts, because it's not clear to the parser generator whether
 * to expect alias_clause after ')' or not.  For the same reason we must
 * treat 'JOIN' and 'join_type JOIN' separately, rather than allowing
 * join_type to expand to empty; if we try it, the parser generator can't
 * figure out when to reduce an empty join_type right after table_ref.
 *
 * Note that a CROSS JOIN is the same as an unqualified
 * INNER JOIN, and an INNER JOIN/ON has the same shape
 * but a qualification expression to limit membership.
 * A NATURAL JOIN implicitly matches column names between
 * tables and the shape is determined by which columns are
 * in common. We'll collect columns during the later transformations.
 * A POSITIONAL JOIN implicitly matches row numbers and is more like a table.
 */

joined_table:
			'(' joined_table ')'
				{
					$$ = $2;
				}
			| table_ref CROSS JOIN table_ref
				{
					/* CROSS JOIN is same as unqualified inner join */
					PGJoinExpr *n = makeNode(PGJoinExpr);
					n->jointype = PG_JOIN_INNER;
					n->joinreftype = PG_JOIN_REGULAR;
					n->larg = $1;
					n->rarg = $4;
					n->usingClause = NIL;
					n->quals = NULL;
					n->location = @2;
					$$ = n;
				}
			| table_ref join_type JOIN table_ref join_qual
				{
					PGJoinExpr *n = makeNode(PGJoinExpr);
					n->jointype = $2;
					n->joinreftype = PG_JOIN_REGULAR;
					n->larg = $1;
					n->rarg = $4;
					if ($5 != NULL && IsA($5, PGList))
						n->usingClause = (PGList *) $5; /* USING clause */
					else
						n->quals = $5; /* ON clause */
					n->location = @2;
					$$ = n;
				}
			| table_ref JOIN table_ref join_qual
				{
					/* letting join_type reduce to empty doesn't work */
					PGJoinExpr *n = makeNode(PGJoinExpr);
					n->jointype = PG_JOIN_INNER;
					n->joinreftype = PG_JOIN_REGULAR;
					n->larg = $1;
					n->rarg = $3;
					if ($4 != NULL && IsA($4, PGList))
						n->usingClause = (PGList *) $4; /* USING clause */
					else
						n->quals = $4; /* ON clause */
					n->location = @2;
					$$ = n;
				}
			| table_ref NATURAL join_type JOIN table_ref
				{
					PGJoinExpr *n = makeNode(PGJoinExpr);
					n->jointype = $3;
					n->joinreftype = PG_JOIN_NATURAL;
					n->larg = $1;
					n->rarg = $5;
					n->usingClause = NIL; /* figure out which columns later... */
					n->quals = NULL; /* fill later */
					n->location = @2;
					$$ = n;
				}
			| table_ref NATURAL JOIN table_ref
				{
					/* letting join_type reduce to empty doesn't work */
					PGJoinExpr *n = makeNode(PGJoinExpr);
					n->jointype = PG_JOIN_INNER;
					n->joinreftype = PG_JOIN_NATURAL;
					n->larg = $1;
					n->rarg = $4;
					n->usingClause = NIL; /* figure out which columns later... */
					n->quals = NULL; /* fill later */
					n->location = @2;
					$$ = n;
				}
			| table_ref ASOF join_type JOIN table_ref join_qual
				{
					PGJoinExpr *n = makeNode(PGJoinExpr);
					n->jointype = $3;
					n->joinreftype = PG_JOIN_ASOF;
					n->larg = $1;
					n->rarg = $5;
					if ($6 != NULL && IsA($6, PGList))
						n->usingClause = (PGList *) $6; /* USING clause */
					else
						n->quals = $6; /* ON clause */
					n->location = @2;
					$$ = n;
				}
			| table_ref ASOF JOIN table_ref join_qual
				{
					PGJoinExpr *n = makeNode(PGJoinExpr);
					n->jointype = PG_JOIN_INNER;
					n->joinreftype = PG_JOIN_ASOF;
					n->larg = $1;
					n->rarg = $4;
					if ($5 != NULL && IsA($5, PGList))
						n->usingClause = (PGList *) $5; /* USING clause */
					else
						n->quals = $5; /* ON clause */
					n->location = @2;
					$$ = n;
				}
			| table_ref POSITIONAL JOIN table_ref
				{
					/* POSITIONAL JOIN is a coordinated scan */
					PGJoinExpr *n = makeNode(PGJoinExpr);
					n->jointype = PG_JOIN_POSITION;
					n->joinreftype = PG_JOIN_REGULAR;
					n->larg = $1;
					n->rarg = $4;
					n->usingClause = NIL;
					n->quals = NULL;
					n->location = @2;
					$$ = n;
				}
            | table_ref ANTI JOIN table_ref join_qual
                {
                    /* ANTI JOIN is a filter */
                    PGJoinExpr *n = makeNode(PGJoinExpr);
                    n->jointype = PG_JOIN_ANTI;
                    n->joinreftype = PG_JOIN_REGULAR;
                    n->larg = $1;
                    n->rarg = $4;
                    if ($5 != NULL && IsA($5, PGList))
                        n->usingClause = (PGList *) $5; /* USING clause */
                    else
                        n->quals = $5; /* ON clause */
                    n->location = @2;
                    $$ = n;
                }
           | table_ref SEMI JOIN table_ref join_qual
               {
                   /* SEMI JOIN is also a filter */
                   PGJoinExpr *n = makeNode(PGJoinExpr);
                   n->jointype = PG_JOIN_SEMI;
                   n->joinreftype = PG_JOIN_REGULAR;
                   n->larg = $1;
                   n->rarg = $4;
                   if ($5 != NULL && IsA($5, PGList))
                       n->usingClause = (PGList *) $5; /* USING clause */
                   else
                       n->quals = $5; /* ON clause */
                   n->location = @2;
                   n->location = @2;
                   $$ = n;
               }
		;

alias_clause:
			AS ColIdOrString '(' name_list_opt_comma ')'
				{
					$$ = makeNode(PGAlias);
					$$->aliasname = $2;
					$$->colnames = $4;
				}
			| AS ColIdOrString
				{
					$$ = makeNode(PGAlias);
					$$->aliasname = $2;
				}
			| ColId '(' name_list_opt_comma ')'
				{
					$$ = makeNode(PGAlias);
					$$->aliasname = $1;
					$$->colnames = $3;
				}
			| ColId
				{
					$$ = makeNode(PGAlias);
					$$->aliasname = $1;
				}
		;

opt_alias_clause: alias_clause						{ $$ = $1; }
			| /*EMPTY*/								{ $$ = NULL; }
		;

/*
 * func_alias_clause can include both an PGAlias and a coldeflist, so we make it
 * return a 2-element list that gets disassembled by calling production.
 */
func_alias_clause:
			alias_clause
				{
					$$ = list_make2($1, NIL);
				}
			| AS '(' TableFuncElementList ')'
				{
					$$ = list_make2(NULL, $3);
				}
			| AS ColIdOrString '(' TableFuncElementList ')'
				{
					PGAlias *a = makeNode(PGAlias);
					a->aliasname = $2;
					$$ = list_make2(a, $4);
				}
			| ColId '(' TableFuncElementList ')'
				{
					PGAlias *a = makeNode(PGAlias);
					a->aliasname = $1;
					$$ = list_make2(a, $3);
				}
			| /*EMPTY*/
				{
					$$ = list_make2(NULL, NIL);
				}
		;

join_type:	FULL join_outer							{ $$ = PG_JOIN_FULL; }
			| LEFT join_outer						{ $$ = PG_JOIN_LEFT; }
			| RIGHT join_outer						{ $$ = PG_JOIN_RIGHT; }
			| SEMI          						{ $$ = PG_JOIN_SEMI; }
			| ANTI          						{ $$ = PG_JOIN_ANTI; }
			| INNER_P								{ $$ = PG_JOIN_INNER; }
		;

/* OUTER is just noise... */
join_outer: OUTER_P									{ $$ = NULL; }
			| /*EMPTY*/								{ $$ = NULL; }
		;

/* JOIN qualification clauses
 * Possibilities are:
 *	USING ( column list ) allows only unqualified column names,
 *						  which must match between tables.
 *	ON expr allows more general qualifications.
 *
 * We return USING as a PGList node, while an ON-expr will not be a List.
 */

join_qual:	USING '(' name_list_opt_comma ')'					{ $$ = (PGNode *) $3; }
			| ON a_expr								{ $$ = $2; }
		;


relation_expr:
			qualified_name
				{
					/* inheritance query, implicitly */
					$$ = $1;
					$$->inh = true;
					$$->alias = NULL;
				}
			| qualified_name '*'
				{
					/* inheritance query, explicitly */
					$$ = $1;
					$$->inh = true;
					$$->alias = NULL;
				}
			| ONLY qualified_name
				{
					/* no inheritance */
					$$ = $2;
					$$->inh = false;
					$$->alias = NULL;
				}
			| ONLY '(' qualified_name ')'
				{
					/* no inheritance, SQL99-style syntax */
					$$ = $3;
					$$->inh = false;
					$$->alias = NULL;
				}
		;


/*
 * Given "UPDATE foo set set ...", we have to decide without looking any
 * further ahead whether the first "set" is an alias or the UPDATE's SET
 * keyword.  Since "set" is allowed as a column name both interpretations
 * are feasible.  We resolve the shift/reduce conflict by giving the first
 * production a higher precedence than the SET token
 * has, causing the parser to prefer to reduce, in effect assuming that the
 * SET is not an alias.
 */

/*
 * func_table represents a function invocation in a FROM list. It can be
 * a plain function call, like "foo(...)", or a ROWS FROM expression with
 * one or more function calls, "ROWS FROM (foo(...), bar(...))",
 * optionally with WITH ORDINALITY attached.
 * In the ROWS FROM syntax, a column list can be given for each
 * function, for example:
 *     ROWS FROM (foo() AS (foo_res_a text, foo_res_b text),
 *                bar() AS (bar_res_a text, bar_res_b text))
 * It's also possible to attach a column list to the PGRangeFunction
 * as a whole, but that's handled by the table_ref production.
 */
func_table: func_expr_windowless opt_ordinality
				{
					PGRangeFunction *n = makeNode(PGRangeFunction);
					n->lateral = false;
					n->ordinality = $2;
					n->is_rowsfrom = false;
					n->functions = list_make1(list_make2($1, NIL));
					n->sample = NULL;
					/* alias and coldeflist are set by table_ref production */
					$$ = (PGNode *) n;
				}
			| ROWS FROM '(' rowsfrom_list ')' opt_ordinality
				{
					PGRangeFunction *n = makeNode(PGRangeFunction);
					n->lateral = false;
					n->ordinality = $6;
					n->is_rowsfrom = true;
					n->functions = $4;
					n->sample = NULL;
					/* alias and coldeflist are set by table_ref production */
					$$ = (PGNode *) n;
				}
		;

rowsfrom_item: func_expr_windowless opt_col_def_list
				{ $$ = list_make2($1, $2); }
		;

rowsfrom_list:
			rowsfrom_item						{ $$ = list_make1($1); }
			| rowsfrom_list ',' rowsfrom_item	{ $$ = lappend($1, $3); }
		;

opt_col_def_list: AS '(' TableFuncElementList ')'	{ $$ = $3; }
			| /*EMPTY*/								{ $$ = NIL; }
		;

opt_ordinality: WITH_LA ORDINALITY					{ $$ = true; }
			| /*EMPTY*/								{ $$ = false; }
		;


where_clause:
			WHERE a_expr							{ $$ = $2; }
			| /*EMPTY*/								{ $$ = NULL; }
		;

/* variant for UPDATE and DELETE */
TableFuncElementList:
			TableFuncElement
				{
					$$ = list_make1($1);
				}
			| TableFuncElementList ',' TableFuncElement
				{
					$$ = lappend($1, $3);
				}
		;

TableFuncElement:	ColIdOrString Typename opt_collate_clause
				{
					PGColumnDef *n = makeNode(PGColumnDef);
					n->colname = $1;
					n->typeName = $2;
					n->inhcount = 0;
					n->is_local = true;
					n->is_not_null = false;
					n->is_from_type = false;
					n->storage = 0;
					n->raw_default = NULL;
					n->cooked_default = NULL;
					n->collClause = (PGCollateClause *) $3;
					n->collOid = InvalidOid;
					n->constraints = NIL;
					n->location = @1;
					$$ = (PGNode *)n;
				}
		;

opt_collate_clause:
			COLLATE any_name
				{
					PGCollateClause *n = makeNode(PGCollateClause);
					n->arg = NULL;
					n->collname = $2;
					n->location = @1;
					$$ = (PGNode *) n;
				}
			| /* EMPTY */				{ $$ = NULL; }
		;
/*****************************************************************************
 *
 *	Type syntax
 *		SQL introduces a large amount of type-specific syntax.
 *		Define individual clauses to handle these cases, and use
 *		 the generic case to handle regular type-extensible Postgres syntax.
 *		- thomas 1997-10-10
 *
 *****************************************************************************/

colid_type_list:
            ColId Typename   {
             $$ = list_make1(list_make2(makeString($1), $2));
            }
            | colid_type_list ',' ColId Typename {
             $$ = lappend($1, list_make2(makeString($3), $4));
            }

RowOrStruct: ROW | STRUCT

opt_Typename:
			Typename						{ $$ = $1; }
			| /*EMPTY*/						{ $$ = NULL; }

Typename:	SimpleTypename opt_array_bounds
				{
					$$ = $1;
					$$->arrayBounds = $2;
				}
			| SETOF SimpleTypename opt_array_bounds
				{
					$$ = $2;
					$$->arrayBounds = $3;
					$$->setof = true;
				}
			/* SQL standard syntax, currently only one-dimensional */
			| SimpleTypename ARRAY '[' Iconst ']'
				{
					$$ = $1;
					$$->arrayBounds = list_make1(makeInteger($4));
				}
			| SETOF SimpleTypename ARRAY '[' Iconst ']'
				{
					$$ = $2;
					$$->arrayBounds = list_make1(makeInteger($5));
					$$->setof = true;
				}
			| SimpleTypename ARRAY
				{
					$$ = $1;
					$$->arrayBounds = list_make1(makeInteger(-1));
				}
			| SETOF SimpleTypename ARRAY
				{
					$$ = $2;
					$$->arrayBounds = list_make1(makeInteger(-1));
					$$->setof = true;
				}
			| RowOrStruct '(' colid_type_list ')' opt_array_bounds {
               $$ = SystemTypeName("struct");
               $$->arrayBounds = $5;
               $$->typmods = $3;
               $$->location = @1;
               }
            | MAP '(' type_list ')' opt_array_bounds {
               $$ = SystemTypeName("map");
               $$->arrayBounds = $5;
               $$->typmods = $3;
               $$->location = @1;
			}
			| UNION '(' colid_type_list ')' opt_array_bounds {
			   $$ = SystemTypeName("union");
			   $$->arrayBounds = $5;
			   $$->typmods = $3;
			   $$->location = @1;
			}
		;

opt_array_bounds:
			opt_array_bounds '[' ']'
					{  $$ = lappend($1, makeInteger(-1)); }
			| opt_array_bounds '[' Iconst ']'
					{  $$ = lappend($1, makeInteger($3)); }
			| /*EMPTY*/
					{  $$ = NIL; }
		;

SimpleTypename:
			GenericType								{ $$ = $1; }
			| Numeric								{ $$ = $1; }
			| Bit									{ $$ = $1; }
			| Character								{ $$ = $1; }
			| ConstDatetime							{ $$ = $1; }
			| ConstInterval opt_interval
				{
					$$ = $1;
					$$->typmods = $2;
				}
			| ConstInterval '(' Iconst ')'
				{
					$$ = $1;
					$$->typmods = list_make2(makeIntConst(INTERVAL_FULL_RANGE, -1),
											 makeIntConst($3, @3));
				}
		;

/* We have a separate ConstTypename to allow defaulting fixed-length
 * types such as CHAR() and BIT() to an unspecified length.
 * SQL9x requires that these default to a length of one, but this
 * makes no sense for constructs like CHAR 'hi' and BIT '0101',
 * where there is an obvious better choice to make.
 * Note that ConstInterval is not included here since it must
 * be pushed up higher in the rules to accommodate the postfix
 * options (e.g. INTERVAL '1' YEAR). Likewise, we have to handle
 * the generic-type-name case in AExprConst to avoid premature
 * reduce/reduce conflicts against function names.
 */
ConstTypename:
			Numeric									{ $$ = $1; }
			| ConstBit								{ $$ = $1; }
			| ConstCharacter						{ $$ = $1; }
			| ConstDatetime							{ $$ = $1; }
		;

/*
 * GenericType covers all type names that don't have special syntax mandated
 * by the standard, including qualified names.  We also allow type modifiers.
 * To avoid parsing conflicts against function invocations, the modifiers
 * have to be shown as expr_list here, but parse analysis will only accept
 * constants for them.
 */
GenericType:
			type_name_token opt_type_modifiers
				{
					$$ = makeTypeName($1);
					$$->typmods = $2;
					$$->location = @1;
				}
			// | type_name_token attrs opt_type_modifiers
			// 	{
			// 		$$ = makeTypeNameFromNameList(lcons(makeString($1), $2));
			// 		$$->typmods = $3;
			// 		$$->location = @1;
			// 	}
		;

opt_type_modifiers: '(' opt_expr_list_opt_comma	 ')'				{ $$ = $2; }
					| /* EMPTY */					{ $$ = NIL; }
		;

/*
 * SQL numeric data types
 */
Numeric:	INT_P
				{
					$$ = SystemTypeName("int4");
					$$->location = @1;
				}
			| INTEGER
				{
					$$ = SystemTypeName("int4");
					$$->location = @1;
				}
			| SMALLINT
				{
					$$ = SystemTypeName("int2");
					$$->location = @1;
				}
			| BIGINT
				{
					$$ = SystemTypeName("int8");
					$$->location = @1;
				}
			| REAL
				{
					$$ = SystemTypeName("float4");
					$$->location = @1;
				}
			| FLOAT_P opt_float
				{
					$$ = $2;
					$$->location = @1;
				}
			| DOUBLE_P PRECISION
				{
					$$ = SystemTypeName("float8");
					$$->location = @1;
				}
			| DECIMAL_P opt_type_modifiers
				{
					$$ = SystemTypeName("numeric");
					$$->typmods = $2;
					$$->location = @1;
				}
			| DEC opt_type_modifiers
				{
					$$ = SystemTypeName("numeric");
					$$->typmods = $2;
					$$->location = @1;
				}
			| NUMERIC opt_type_modifiers
				{
					$$ = SystemTypeName("numeric");
					$$->typmods = $2;
					$$->location = @1;
				}
			| BOOLEAN_P
				{
					$$ = SystemTypeName("bool");
					$$->location = @1;
				}
		;

opt_float:	'(' Iconst ')'
				{
					/*
					 * Check FLOAT() precision limits assuming IEEE floating
					 * types - thomas 1997-09-18
					 */
					if ($2 < 1)
						ereport(ERROR,
								(errcode(PG_ERRCODE_INVALID_PARAMETER_VALUE),
								 errmsg("precision for type float must be at least 1 bit"),
								 parser_errposition(@2)));
					else if ($2 <= 24)
						$$ = SystemTypeName("float4");
					else if ($2 <= 53)
						$$ = SystemTypeName("float8");
					else
						ereport(ERROR,
								(errcode(PG_ERRCODE_INVALID_PARAMETER_VALUE),
								 errmsg("precision for type float must be less than 54 bits"),
								 parser_errposition(@2)));
				}
			| /*EMPTY*/
				{
					$$ = SystemTypeName("float4");
				}
		;

/*
 * SQL bit-field data types
 * The following implements BIT() and BIT VARYING().
 */
Bit:		BitWithLength
				{
					$$ = $1;
				}
			| BitWithoutLength
				{
					$$ = $1;
				}
		;

/* ConstBit is like Bit except "BIT" defaults to unspecified length */
/* See notes for ConstCharacter, which addresses same issue for "CHAR" */
ConstBit:	BitWithLength
				{
					$$ = $1;
				}
			| BitWithoutLength
				{
					$$ = $1;
					$$->typmods = NIL;
				}
		;

BitWithLength:
			BIT opt_varying '(' expr_list_opt_comma ')'
				{
					const char *typname;

					typname = $2 ? "varbit" : "bit";
					$$ = SystemTypeName(typname);
					$$->typmods = $4;
					$$->location = @1;
				}
		;

BitWithoutLength:
			BIT opt_varying
				{
					/* bit defaults to bit(1), varbit to no limit */
					if ($2)
					{
						$$ = SystemTypeName("varbit");
					}
					else
					{
						$$ = SystemTypeName("bit");
						$$->typmods = list_make1(makeIntConst(1, -1));
					}
					$$->location = @1;
				}
		;


/*
 * SQL character data types
 * The following implements CHAR() and VARCHAR().
 */
Character:  CharacterWithLength
				{
					$$ = $1;
				}
			| CharacterWithoutLength
				{
					$$ = $1;
				}
		;

ConstCharacter:  CharacterWithLength
				{
					$$ = $1;
				}
			| CharacterWithoutLength
				{
					/* Length was not specified so allow to be unrestricted.
					 * This handles problems with fixed-length (bpchar) strings
					 * which in column definitions must default to a length
					 * of one, but should not be constrained if the length
					 * was not specified.
					 */
					$$ = $1;
					$$->typmods = NIL;
				}
		;

CharacterWithLength:  character '(' Iconst ')'
				{
					$$ = SystemTypeName($1);
					$$->typmods = list_make1(makeIntConst($3, @3));
					$$->location = @1;
				}
		;

CharacterWithoutLength:	 character
				{
					$$ = SystemTypeName($1);
					/* char defaults to char(1), varchar to no limit */
					if (strcmp($1, "bpchar") == 0)
						$$->typmods = list_make1(makeIntConst(1, -1));
					$$->location = @1;
				}
		;

character:	CHARACTER opt_varying
										{ $$ = $2 ? "varchar": "bpchar"; }
			| CHAR_P opt_varying
										{ $$ = $2 ? "varchar": "bpchar"; }
			| VARCHAR
										{ $$ = "varchar"; }
			| NATIONAL CHARACTER opt_varying
										{ $$ = $3 ? "varchar": "bpchar"; }
			| NATIONAL CHAR_P opt_varying
										{ $$ = $3 ? "varchar": "bpchar"; }
			| NCHAR opt_varying
										{ $$ = $2 ? "varchar": "bpchar"; }
		;

opt_varying:
			VARYING									{ $$ = true; }
			| /*EMPTY*/								{ $$ = false; }
		;

/*
 * SQL date/time types
 */
ConstDatetime:
			TIMESTAMP '(' Iconst ')' opt_timezone
				{
					if ($5)
						$$ = SystemTypeName("timestamptz");
					else
						$$ = SystemTypeName("timestamp");
					$$->typmods = list_make1(makeIntConst($3, @3));
					$$->location = @1;
				}
			| TIMESTAMP opt_timezone
				{
					if ($2)
						$$ = SystemTypeName("timestamptz");
					else
						$$ = SystemTypeName("timestamp");
					$$->location = @1;
				}
			| TIME '(' Iconst ')' opt_timezone
				{
					if ($5)
						$$ = SystemTypeName("timetz");
					else
						$$ = SystemTypeName("time");
					$$->typmods = list_make1(makeIntConst($3, @3));
					$$->location = @1;
				}
			| TIME opt_timezone
				{
					if ($2)
						$$ = SystemTypeName("timetz");
					else
						$$ = SystemTypeName("time");
					$$->location = @1;
				}
		;

ConstInterval:
			INTERVAL
				{
					$$ = SystemTypeName("interval");
					$$->location = @1;
				}
		;

opt_timezone:
			WITH_LA TIME ZONE						{ $$ = true; }
			| WITHOUT TIME ZONE						{ $$ = false; }
			| /*EMPTY*/								{ $$ = false; }
		;

year_keyword:
	YEAR_P | YEARS_P

month_keyword:
	MONTH_P | MONTHS_P

day_keyword:
	DAY_P | DAYS_P

hour_keyword:
	HOUR_P | HOURS_P

minute_keyword:
	MINUTE_P | MINUTES_P

second_keyword:
	SECOND_P | SECONDS_P

millisecond_keyword:
	MILLISECOND_P | MILLISECONDS_P

microsecond_keyword:
	MICROSECOND_P | MICROSECONDS_P

opt_interval:
			year_keyword
				{ $$ = list_make1(makeIntConst(INTERVAL_MASK(YEAR), @1)); }
			| month_keyword
				{ $$ = list_make1(makeIntConst(INTERVAL_MASK(MONTH), @1)); }
			| day_keyword
				{ $$ = list_make1(makeIntConst(INTERVAL_MASK(DAY), @1)); }
			| hour_keyword
				{ $$ = list_make1(makeIntConst(INTERVAL_MASK(HOUR), @1)); }
			| minute_keyword
				{ $$ = list_make1(makeIntConst(INTERVAL_MASK(MINUTE), @1)); }
			| second_keyword
				{ $$ = list_make1(makeIntConst(INTERVAL_MASK(SECOND), @1)); }
			| millisecond_keyword
				{ $$ = list_make1(makeIntConst(INTERVAL_MASK(MILLISECOND), @1)); }
			| microsecond_keyword
				{ $$ = list_make1(makeIntConst(INTERVAL_MASK(MICROSECOND), @1)); }
			| year_keyword TO month_keyword
				{
					$$ = list_make1(makeIntConst(INTERVAL_MASK(YEAR) |
												 INTERVAL_MASK(MONTH), @1));
				}
			| day_keyword TO hour_keyword
				{
					$$ = list_make1(makeIntConst(INTERVAL_MASK(DAY) |
												 INTERVAL_MASK(HOUR), @1));
				}
			| day_keyword TO minute_keyword
				{
					$$ = list_make1(makeIntConst(INTERVAL_MASK(DAY) |
												 INTERVAL_MASK(HOUR) |
												 INTERVAL_MASK(MINUTE), @1));
				}
			| day_keyword TO second_keyword
				{
					$$ = list_make1(makeIntConst(INTERVAL_MASK(DAY) |
												 INTERVAL_MASK(HOUR) |
												 INTERVAL_MASK(MINUTE) |
												 INTERVAL_MASK(SECOND), @1));
				}
			| hour_keyword TO minute_keyword
				{
					$$ = list_make1(makeIntConst(INTERVAL_MASK(HOUR) |
												 INTERVAL_MASK(MINUTE), @1));
				}
			| hour_keyword TO second_keyword
				{
					$$ = list_make1(makeIntConst(INTERVAL_MASK(HOUR) |
												 INTERVAL_MASK(MINUTE) |
												 INTERVAL_MASK(SECOND), @1));
				}
			| minute_keyword TO second_keyword
				{
					$$ = list_make1(makeIntConst(INTERVAL_MASK(MINUTE) |
												 INTERVAL_MASK(SECOND), @1));
				}
			| /*EMPTY*/
				{ $$ = NIL; }
		;

/*****************************************************************************
 *
 *	expression grammar
 *
 *****************************************************************************/

/*
 * General expressions
 * This is the heart of the expression syntax.
 *
 * We have two expression types: a_expr is the unrestricted kind, and
 * b_expr is a subset that must be used in some places to avoid shift/reduce
 * conflicts.  For example, we can't do BETWEEN as "BETWEEN a_expr AND a_expr"
 * because that use of AND conflicts with AND as a boolean operator.  So,
 * b_expr is used in BETWEEN and we remove boolean keywords from b_expr.
 *
 * Note that '(' a_expr ')' is a b_expr, so an unrestricted expression can
 * always be used by surrounding it with parens.
 *
 * c_expr is all the productions that are common to a_expr and b_expr;
 * it's factored out just to eliminate redundant coding.
 *
 * Be careful of productions involving more than one terminal token.
 * By default, bison will assign such productions the precedence of their
 * last terminal, but in nearly all cases you want it to be the precedence
 * of the first terminal instead; otherwise you will not get the behavior
 * you expect!  So we use %prec annotations freely to set precedences.
 */
a_expr:		c_expr									{ $$ = $1; }
			|
			a_expr TYPECAST Typename
					{ $$ = makeTypeCast($1, $3, 0, @2); }
			| a_expr COLLATE any_name
				{
					PGCollateClause *n = makeNode(PGCollateClause);
					n->arg = $1;
					n->collname = $3;
					n->location = @2;
					$$ = (PGNode *) n;
				}
			| a_expr AT TIME ZONE a_expr			%prec AT
				{
					$$ = (PGNode *) makeFuncCall(SystemFuncName("timezone"),
											   list_make2($5, $1),
											   @2);
				}
		/*
		 * These operators must be called out explicitly in order to make use
		 * of bison's automatic operator-precedence handling.  All other
		 * operator names are handled by the generic productions using "Op",
		 * below; and all those operators will have the same precedence.
		 *
		 * If you add more explicitly-known operators, be sure to add them
		 * also to b_expr and to the MathOp list below.
		 */
			| '+' a_expr					%prec UMINUS
				{ $$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_OP, "+", NULL, $2, @1); }
			| '-' a_expr					%prec UMINUS
				{ $$ = doNegate($2, @1); }
			| a_expr '+' a_expr
				{ $$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_OP, "+", $1, $3, @2); }
			| a_expr '-' a_expr
				{ $$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_OP, "-", $1, $3, @2); }
			| a_expr '*' a_expr
				{ $$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_OP, "*", $1, $3, @2); }
			| a_expr '/' a_expr
				{ $$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_OP, "/", $1, $3, @2); }
			| a_expr INTEGER_DIVISION a_expr
				{ $$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_OP, "//", $1, $3, @2); }
			| a_expr '%' a_expr
				{ $$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_OP, "%", $1, $3, @2); }
			| a_expr '^' a_expr
				{ $$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_OP, "^", $1, $3, @2); }
			| a_expr POWER_OF a_expr
				{ $$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_OP, "**", $1, $3, @2); }
			| a_expr '<' a_expr
				{ $$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_OP, "<", $1, $3, @2); }
			| a_expr '>' a_expr
				{ $$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_OP, ">", $1, $3, @2); }
			| a_expr '=' a_expr
				{ $$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_OP, "=", $1, $3, @2); }
			| a_expr LESS_EQUALS a_expr
				{ $$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_OP, "<=", $1, $3, @2); }
			| a_expr GREATER_EQUALS a_expr
				{ $$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_OP, ">=", $1, $3, @2); }
			| a_expr NOT_EQUALS a_expr
				{ $$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_OP, "<>", $1, $3, @2); }

			| a_expr qual_Op a_expr				%prec Op
				{ $$ = (PGNode *) makeAExpr(PG_AEXPR_OP, $2, $1, $3, @2); }
			| qual_Op a_expr					%prec Op
				{ $$ = (PGNode *) makeAExpr(PG_AEXPR_OP, $1, NULL, $2, @1); }
			| a_expr qual_Op					%prec POSTFIXOP
				{ $$ = (PGNode *) makeAExpr(PG_AEXPR_OP, $2, $1, NULL, @2); }

			| a_expr AND a_expr
				{ $$ = makeAndExpr($1, $3, @2); }
			| a_expr OR a_expr
				{ $$ = makeOrExpr($1, $3, @2); }
			| NOT a_expr
				{ $$ = makeNotExpr($2, @1); }
			| NOT_LA a_expr						%prec NOT
				{ $$ = makeNotExpr($2, @1); }
			| a_expr GLOB a_expr %prec GLOB
				{
					$$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_GLOB, "~~~",
												   $1, $3, @2);
				}
			| a_expr LIKE a_expr
				{
					$$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_LIKE, "~~",
												   $1, $3, @2);
				}
			| a_expr LIKE a_expr ESCAPE a_expr					%prec LIKE
				{
					PGFuncCall *n = makeFuncCall(SystemFuncName("like_escape"),
											   list_make3($1, $3, $5),
											   @2);
					$$ = (PGNode *) n;
				}
			| a_expr NOT_LA LIKE a_expr							%prec NOT_LA
				{
					$$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_LIKE, "!~~",
												   $1, $4, @2);
				}
			| a_expr NOT_LA LIKE a_expr ESCAPE a_expr			%prec NOT_LA
				{
					PGFuncCall *n = makeFuncCall(SystemFuncName("not_like_escape"),
											   list_make3($1, $4, $6),
											   @2);
					$$ = (PGNode *) n;
				}
			| a_expr ILIKE a_expr
				{
					$$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_ILIKE, "~~*",
												   $1, $3, @2);
				}
			| a_expr ILIKE a_expr ESCAPE a_expr					%prec ILIKE
				{
					PGFuncCall *n = makeFuncCall(SystemFuncName("ilike_escape"),
											   list_make3($1, $3, $5),
											   @2);
					$$ = (PGNode *) n;
				}
			| a_expr NOT_LA ILIKE a_expr						%prec NOT_LA
				{
					$$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_ILIKE, "!~~*",
												   $1, $4, @2);
				}
			| a_expr NOT_LA ILIKE a_expr ESCAPE a_expr			%prec NOT_LA
				{
					PGFuncCall *n = makeFuncCall(SystemFuncName("not_ilike_escape"),
											   list_make3($1, $4, $6),
											   @2);
					$$ = (PGNode *) n;
				}

			| a_expr SIMILAR TO a_expr							%prec SIMILAR
				{
					PGFuncCall *n = makeFuncCall(SystemFuncName("similar_escape"),
											   list_make2($4, makeNullAConst(-1)),
											   @2);
					$$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_SIMILAR, "~",
												   $1, (PGNode *) n, @2);
				}
			| a_expr SIMILAR TO a_expr ESCAPE a_expr			%prec SIMILAR
				{
					PGFuncCall *n = makeFuncCall(SystemFuncName("similar_escape"),
											   list_make2($4, $6),
											   @2);
					$$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_SIMILAR, "~",
												   $1, (PGNode *) n, @2);
				}
			| a_expr NOT_LA SIMILAR TO a_expr					%prec NOT_LA
				{
					PGFuncCall *n = makeFuncCall(SystemFuncName("similar_escape"),
											   list_make2($5, makeNullAConst(-1)),
											   @2);
					$$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_SIMILAR, "!~",
												   $1, (PGNode *) n, @2);
				}
			| a_expr NOT_LA SIMILAR TO a_expr ESCAPE a_expr		%prec NOT_LA
				{
					PGFuncCall *n = makeFuncCall(SystemFuncName("similar_escape"),
											   list_make2($5, $7),
											   @2);
					$$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_SIMILAR, "!~",
												   $1, (PGNode *) n, @2);
				}

			/* PGNullTest clause
			 * Define SQL-style Null test clause.
			 * Allow two forms described in the standard:
			 *	a IS NULL
			 *	a IS NOT NULL
			 * Allow two SQL extensions
			 *	a ISNULL
			 *	a NOTNULL
			 */
			| a_expr IS NULL_P							%prec IS
				{
					PGNullTest *n = makeNode(PGNullTest);
					n->arg = (PGExpr *) $1;
					n->nulltesttype = PG_IS_NULL;
					n->location = @2;
					$$ = (PGNode *)n;
				}
			| a_expr ISNULL
				{
					PGNullTest *n = makeNode(PGNullTest);
					n->arg = (PGExpr *) $1;
					n->nulltesttype = PG_IS_NULL;
					n->location = @2;
					$$ = (PGNode *)n;
				}
			| a_expr IS NOT NULL_P						%prec IS
				{
					PGNullTest *n = makeNode(PGNullTest);
					n->arg = (PGExpr *) $1;
					n->nulltesttype = IS_NOT_NULL;
					n->location = @2;
					$$ = (PGNode *)n;
				}
			| a_expr NOT NULL_P
				{
					PGNullTest *n = makeNode(PGNullTest);
					n->arg = (PGExpr *) $1;
					n->nulltesttype = IS_NOT_NULL;
					n->location = @2;
					$$ = (PGNode *)n;
				}
			| a_expr NOTNULL
				{
					PGNullTest *n = makeNode(PGNullTest);
					n->arg = (PGExpr *) $1;
					n->nulltesttype = IS_NOT_NULL;
					n->location = @2;
					$$ = (PGNode *)n;
				}
			| a_expr LAMBDA_ARROW a_expr
			{
				PGLambdaFunction *n = makeNode(PGLambdaFunction);
				n->lhs = $1;
				n->rhs = $3;
				n->location = @2;
				$$ = (PGNode *) n;
			}
			| a_expr DOUBLE_ARROW a_expr %prec Op
			{
							$$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_OP, "->>", $1, $3, @2);
			}
			| row OVERLAPS row
				{
					if (list_length($1) != 2)
						ereport(ERROR,
								(errcode(PG_ERRCODE_SYNTAX_ERROR),
								 errmsg("wrong number of parameters on left side of OVERLAPS expression"),
								 parser_errposition(@1)));
					if (list_length($3) != 2)
						ereport(ERROR,
								(errcode(PG_ERRCODE_SYNTAX_ERROR),
								 errmsg("wrong number of parameters on right side of OVERLAPS expression"),
								 parser_errposition(@3)));
					$$ = (PGNode *) makeFuncCall(SystemFuncName("overlaps"),
											   list_concat($1, $3),
											   @2);
				}
			| a_expr IS TRUE_P							%prec IS
				{
					PGBooleanTest *b = makeNode(PGBooleanTest);
					b->arg = (PGExpr *) $1;
					b->booltesttype = PG_IS_TRUE;
					b->location = @2;
					$$ = (PGNode *)b;
				}
			| a_expr IS NOT TRUE_P						%prec IS
				{
					PGBooleanTest *b = makeNode(PGBooleanTest);
					b->arg = (PGExpr *) $1;
					b->booltesttype = IS_NOT_TRUE;
					b->location = @2;
					$$ = (PGNode *)b;
				}
			| a_expr IS FALSE_P							%prec IS
				{
					PGBooleanTest *b = makeNode(PGBooleanTest);
					b->arg = (PGExpr *) $1;
					b->booltesttype = IS_FALSE;
					b->location = @2;
					$$ = (PGNode *)b;
				}
			| a_expr IS NOT FALSE_P						%prec IS
				{
					PGBooleanTest *b = makeNode(PGBooleanTest);
					b->arg = (PGExpr *) $1;
					b->booltesttype = IS_NOT_FALSE;
					b->location = @2;
					$$ = (PGNode *)b;
				}
			| a_expr IS UNKNOWN							%prec IS
				{
					PGBooleanTest *b = makeNode(PGBooleanTest);
					b->arg = (PGExpr *) $1;
					b->booltesttype = IS_UNKNOWN;
					b->location = @2;
					$$ = (PGNode *)b;
				}
			| a_expr IS NOT UNKNOWN						%prec IS
				{
					PGBooleanTest *b = makeNode(PGBooleanTest);
					b->arg = (PGExpr *) $1;
					b->booltesttype = IS_NOT_UNKNOWN;
					b->location = @2;
					$$ = (PGNode *)b;
				}
			| a_expr IS DISTINCT FROM a_expr			%prec IS
				{
					$$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_DISTINCT, "=", $1, $5, @2);
				}
			| a_expr IS NOT DISTINCT FROM a_expr		%prec IS
				{
					$$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_NOT_DISTINCT, "=", $1, $6, @2);
				}
			| a_expr IS OF '(' type_list ')'			%prec IS
				{
					$$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_OF, "=", $1, (PGNode *) $5, @2);
				}
			| a_expr IS NOT OF '(' type_list ')'		%prec IS
				{
					$$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_OF, "<>", $1, (PGNode *) $6, @2);
				}
			| a_expr BETWEEN opt_asymmetric b_expr AND a_expr		%prec BETWEEN
				{
					$$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_BETWEEN,
												   "BETWEEN",
												   $1,
												   (PGNode *) list_make2($4, $6),
												   @2);
				}
			| a_expr NOT_LA BETWEEN opt_asymmetric b_expr AND a_expr %prec NOT_LA
				{
					$$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_NOT_BETWEEN,
												   "NOT BETWEEN",
												   $1,
												   (PGNode *) list_make2($5, $7),
												   @2);
				}
			| a_expr BETWEEN SYMMETRIC b_expr AND a_expr			%prec BETWEEN
				{
					$$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_BETWEEN_SYM,
												   "BETWEEN SYMMETRIC",
												   $1,
												   (PGNode *) list_make2($4, $6),
												   @2);
				}
			| a_expr NOT_LA BETWEEN SYMMETRIC b_expr AND a_expr		%prec NOT_LA
				{
					$$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_NOT_BETWEEN_SYM,
												   "NOT BETWEEN SYMMETRIC",
												   $1,
												   (PGNode *) list_make2($5, $7),
												   @2);
				}
			| a_expr IN_P in_expr
				{
					/* in_expr returns a PGSubLink or a list of a_exprs */
					if (IsA($3, PGSubLink))
					{
						/* generate foo = ANY (subquery) */
						PGSubLink *n = (PGSubLink *) $3;
						n->subLinkType = PG_ANY_SUBLINK;
						n->subLinkId = 0;
						n->testexpr = $1;
						n->operName = NIL;		/* show it's IN not = ANY */
						n->location = @2;
						$$ = (PGNode *)n;
					}
					else
					{
						/* generate scalar IN expression */
						$$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_IN, "=", $1, $3, @2);
					}
				}
			| a_expr NOT_LA IN_P in_expr						%prec NOT_LA
				{
					/* in_expr returns a PGSubLink or a list of a_exprs */
					if (IsA($4, PGSubLink))
					{
						/* generate NOT (foo = ANY (subquery)) */
						/* Make an = ANY node */
						PGSubLink *n = (PGSubLink *) $4;
						n->subLinkType = PG_ANY_SUBLINK;
						n->subLinkId = 0;
						n->testexpr = $1;
						n->operName = NIL;		/* show it's IN not = ANY */
						n->location = @2;
						/* Stick a NOT on top; must have same parse location */
						$$ = makeNotExpr((PGNode *) n, @2);
					}
					else
					{
						/* generate scalar NOT IN expression */
						$$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_IN, "<>", $1, $4, @2);
					}
				}
			| a_expr subquery_Op sub_type select_with_parens	%prec Op
				{
					PGSubLink *n = makeNode(PGSubLink);
					n->subLinkType = $3;
					n->subLinkId = 0;
					n->testexpr = $1;
					n->operName = $2;
					n->subselect = $4;
					n->location = @2;
					$$ = (PGNode *)n;
				}
			| a_expr subquery_Op sub_type '(' a_expr ')'		%prec Op
				{
					if ($3 == PG_ANY_SUBLINK)
						$$ = (PGNode *) makeAExpr(PG_AEXPR_OP_ANY, $2, $1, $5, @2);
					else
						$$ = (PGNode *) makeAExpr(PG_AEXPR_OP_ALL, $2, $1, $5, @2);
				}
			| DEFAULT
				{
					/*
					 * The SQL spec only allows DEFAULT in "contextually typed
					 * expressions", but for us, it's easier to allow it in
					 * any a_expr and then throw error during parse analysis
					 * if it's in an inappropriate context.  This way also
					 * lets us say something smarter than "syntax error".
					 */
					PGSetToDefault *n = makeNode(PGSetToDefault);
					/* parse analysis will fill in the rest */
					n->location = @1;
					$$ = (PGNode *)n;
				}
			| COLUMNS '(' a_expr ')'
				{
					PGAStar *star = makeNode(PGAStar);
					star->expr = $3;
					star->columns = true;
					star->location = @1;
					$$ = (PGNode *) star;
				}
			| '*' opt_except_list opt_replace_list
				{
					PGAStar *star = makeNode(PGAStar);
					star->except_list = $2;
					star->replace_list = $3;
					star->location = @1;
					$$ = (PGNode *) star;
				}
			| ColId '.' '*' opt_except_list opt_replace_list
				{
					PGAStar *star = makeNode(PGAStar);
					star->relation = $1;
					star->except_list = $4;
					star->replace_list = $5;
					star->location = @1;
					$$ = (PGNode *) star;
				}
		;

/*
 * Restricted expressions
 *
 * b_expr is a subset of the complete expression syntax defined by a_expr.
 *
 * Presently, AND, NOT, IS, and IN are the a_expr keywords that would
 * cause trouble in the places where b_expr is used.  For simplicity, we
 * just eliminate all the boolean-keyword-operator productions from b_expr.
 */
b_expr:		c_expr
				{ $$ = $1; }
			| b_expr TYPECAST Typename
				{ $$ = makeTypeCast($1, $3, 0, @2); }
			| '+' b_expr					%prec UMINUS
				{ $$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_OP, "+", NULL, $2, @1); }
			| '-' b_expr					%prec UMINUS
				{ $$ = doNegate($2, @1); }
			| b_expr '+' b_expr
				{ $$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_OP, "+", $1, $3, @2); }
			| b_expr '-' b_expr
				{ $$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_OP, "-", $1, $3, @2); }
			| b_expr '*' b_expr
				{ $$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_OP, "*", $1, $3, @2); }
			| b_expr '/' b_expr
				{ $$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_OP, "/", $1, $3, @2); }
			| b_expr INTEGER_DIVISION b_expr
				{ $$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_OP, "//", $1, $3, @2); }
			| b_expr '%' b_expr
				{ $$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_OP, "%", $1, $3, @2); }
			| b_expr '^' b_expr
				{ $$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_OP, "^", $1, $3, @2); }
			| b_expr POWER_OF b_expr
				{ $$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_OP, "**", $1, $3, @2); }
			| b_expr '<' b_expr
				{ $$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_OP, "<", $1, $3, @2); }
			| b_expr '>' b_expr
				{ $$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_OP, ">", $1, $3, @2); }
			| b_expr '=' b_expr
				{ $$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_OP, "=", $1, $3, @2); }
			| b_expr LESS_EQUALS b_expr
				{ $$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_OP, "<=", $1, $3, @2); }
			| b_expr GREATER_EQUALS b_expr
				{ $$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_OP, ">=", $1, $3, @2); }
			| b_expr NOT_EQUALS b_expr
				{ $$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_OP, "<>", $1, $3, @2); }
			| b_expr qual_Op b_expr				%prec Op
				{ $$ = (PGNode *) makeAExpr(PG_AEXPR_OP, $2, $1, $3, @2); }
			| qual_Op b_expr					%prec Op
				{ $$ = (PGNode *) makeAExpr(PG_AEXPR_OP, $1, NULL, $2, @1); }
			| b_expr qual_Op					%prec POSTFIXOP
				{ $$ = (PGNode *) makeAExpr(PG_AEXPR_OP, $2, $1, NULL, @2); }
			| b_expr IS DISTINCT FROM b_expr		%prec IS
				{
					$$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_DISTINCT, "=", $1, $5, @2);
				}
			| b_expr IS NOT DISTINCT FROM b_expr	%prec IS
				{
					$$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_NOT_DISTINCT, "=", $1, $6, @2);
				}
			| b_expr IS OF '(' type_list ')'		%prec IS
				{
					$$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_OF, "=", $1, (PGNode *) $5, @2);
				}
			| b_expr IS NOT OF '(' type_list ')'	%prec IS
				{
					$$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_OF, "<>", $1, (PGNode *) $6, @2);
				}
		;

/*
 * Productions that can be used in both a_expr and b_expr.
 *
 * Note: productions that refer recursively to a_expr or b_expr mostly
 * cannot appear here.	However, it's OK to refer to a_exprs that occur
 * inside parentheses, such as function arguments; that cannot introduce
 * ambiguity to the b_expr syntax.
 */
c_expr:		d_expr
			| row {
				PGFuncCall *n = makeFuncCall(SystemFuncName("row"), $1, @1);
				$$ = (PGNode *) n;
			}
			| indirection_expr opt_extended_indirection
				{
					if ($2)
					{
						PGAIndirection *n = makeNode(PGAIndirection);
						n->arg = (PGNode *) $1;
						n->indirection = check_indirection($2, yyscanner);
						$$ = (PGNode *) n;
					}
					else
						$$ = (PGNode *) $1;
				}
		;

d_expr:		columnref								{ $$ = $1; }
			| AexprConst							{ $$ = $1; }
			| '#' ICONST
				{
					PGPositionalReference *n = makeNode(PGPositionalReference);
					n->position = $2;
					n->location = @1;
					$$ = (PGNode *) n;
				}
			| '$' ColLabel
				{
					$$ = makeNamedParamRef($2, @1);
				}
			| '[' opt_expr_list_opt_comma ']' {
				PGFuncCall *n = makeFuncCall(SystemFuncName("list_value"), $2, @2);
				$$ = (PGNode *) n;
			}
			| list_comprehension {
				$$ = $1;
			}
			| ARRAY select_with_parens
				{
					PGSubLink *n = makeNode(PGSubLink);
					n->subLinkType = PG_ARRAY_SUBLINK;
					n->subLinkId = 0;
					n->testexpr = NULL;
					n->operName = NULL;
					n->subselect = $2;
					n->location = @2;
					$$ = (PGNode *)n;
				}
			| ARRAY '[' opt_expr_list_opt_comma ']' {
				PGList *func_name = list_make1(makeString("construct_array"));
				PGFuncCall *n = makeFuncCall(func_name, $3, @1);
				$$ = (PGNode *) n;
			}
			| case_expr
				{ $$ = $1; }
			| select_with_parens			%prec UMINUS
				{
					PGSubLink *n = makeNode(PGSubLink);
					n->subLinkType = PG_EXPR_SUBLINK;
					n->subLinkId = 0;
					n->testexpr = NULL;
					n->operName = NIL;
					n->subselect = $1;
					n->location = @1;
					$$ = (PGNode *)n;
				}
			| select_with_parens indirection
				{
					/*
					 * Because the select_with_parens nonterminal is designed
					 * to "eat" as many levels of parens as possible, the
					 * '(' a_expr ')' opt_indirection production above will
					 * fail to match a sub-SELECT with indirection decoration;
					 * the sub-SELECT won't be regarded as an a_expr as long
					 * as there are parens around it.  To support applying
					 * subscripting or field selection to a sub-SELECT result,
					 * we need this redundant-looking production.
					 */
					PGSubLink *n = makeNode(PGSubLink);
					PGAIndirection *a = makeNode(PGAIndirection);
					n->subLinkType = PG_EXPR_SUBLINK;
					n->subLinkId = 0;
					n->testexpr = NULL;
					n->operName = NIL;
					n->subselect = $1;
					n->location = @1;
					a->arg = (PGNode *)n;
					a->indirection = check_indirection($2, yyscanner);
					$$ = (PGNode *)a;
				}
			| EXISTS select_with_parens
				{
					PGSubLink *n = makeNode(PGSubLink);
					n->subLinkType = PG_EXISTS_SUBLINK;
					n->subLinkId = 0;
					n->testexpr = NULL;
					n->operName = NIL;
					n->subselect = $2;
					n->location = @1;
					$$ = (PGNode *)n;
				}
			| grouping_or_grouping_id '(' expr_list_opt_comma ')'
			  {
				  PGGroupingFunc *g = makeNode(PGGroupingFunc);
				  g->args = $3;
				  g->location = @1;
				  $$ = (PGNode *)g;
			  }
		;



indirection_expr:		'?'
				{
					$$ = makeParamRef(0, @1);
				}
			| PARAM
				{
					PGParamRef *p = makeNode(PGParamRef);
					p->number = $1;
					p->location = @1;
					$$ = (PGNode *) p;
				}
			| '(' a_expr ')'
				{
					$$ = $2;
				}
			| struct_expr
				{
					$$ = $1;
				}
			| MAP '{' opt_map_arguments_opt_comma '}'
				{
					PGList *key_list = NULL;
					PGList *value_list = NULL;
					PGListCell *lc;
					PGList *entry_list = $3;
					foreach(lc, entry_list)
					{
						PGList *l = (PGList *) lc->data.ptr_value;
						key_list = lappend(key_list, (PGNode *) l->head->data.ptr_value);
						value_list = lappend(value_list, (PGNode *) l->tail->data.ptr_value);
					}
					PGNode *keys   = (PGNode *) makeFuncCall(SystemFuncName("list_value"), key_list, @3);
					PGNode *values = (PGNode *) makeFuncCall(SystemFuncName("list_value"), value_list, @3);
					PGFuncCall *f = makeFuncCall(SystemFuncName("map"), list_make2(keys, values), @3);
					$$ = (PGNode *) f;
				}
			| func_expr
				{
					$$ = $1;
				}
		;



struct_expr:		'{' dict_arguments_opt_comma '}'
				{
					PGFuncCall *f = makeFuncCall(SystemFuncName("struct_pack"), $2, @2);
					$$ = (PGNode *) f;
				}
		;



func_application:       func_name '(' ')'
				{
					$$ = (PGNode *) makeFuncCall($1, NIL, @1);
				}
			| func_name '(' func_arg_list opt_sort_clause opt_ignore_nulls ')'
				{
					PGFuncCall *n = makeFuncCall($1, $3, @1);
					n->agg_order = $4;
					n->agg_ignore_nulls = $5;
					$$ = (PGNode *)n;
				}
			| func_name '(' VARIADIC func_arg_expr opt_sort_clause opt_ignore_nulls ')'
				{
					PGFuncCall *n = makeFuncCall($1, list_make1($4), @1);
					n->func_variadic = true;
					n->agg_order = $5;
					n->agg_ignore_nulls = $6;
					$$ = (PGNode *)n;
				}
			| func_name '(' func_arg_list ',' VARIADIC func_arg_expr opt_sort_clause opt_ignore_nulls ')'
				{
					PGFuncCall *n = makeFuncCall($1, lappend($3, $6), @1);
					n->func_variadic = true;
					n->agg_order = $7;
					n->agg_ignore_nulls = $8;
					$$ = (PGNode *)n;
				}
			| func_name '(' ALL func_arg_list opt_sort_clause opt_ignore_nulls ')'
				{
					PGFuncCall *n = makeFuncCall($1, $4, @1);
					n->agg_order = $5;
					n->agg_ignore_nulls = $6;
					/* Ideally we'd mark the PGFuncCall node to indicate
					 * "must be an aggregate", but there's no provision
					 * for that in PGFuncCall at the moment.
					 */
					$$ = (PGNode *)n;
				}
			| func_name '(' DISTINCT func_arg_list opt_sort_clause opt_ignore_nulls ')'
				{
					PGFuncCall *n = makeFuncCall($1, $4, @1);
					n->agg_order = $5;
					n->agg_ignore_nulls = $6;
					n->agg_distinct = true;
					$$ = (PGNode *)n;
				}
		;


/*
 * func_expr and its cousin func_expr_windowless are split out from c_expr just
 * so that we have classifications for "everything that is a function call or
 * looks like one".  This isn't very important, but it saves us having to
 * document which variants are legal in places like "FROM function()" or the
 * backwards-compatible functional-index syntax for CREATE INDEX.
 * (Note that many of the special SQL functions wouldn't actually make any
 * sense as functional index entries, but we ignore that consideration here.)
 */
func_expr: func_application within_group_clause filter_clause export_clause over_clause
				{
					PGFuncCall *n = (PGFuncCall *) $1;
					/*
					 * The order clause for WITHIN GROUP and the one for
					 * plain-aggregate ORDER BY share a field, so we have to
					 * check here that at most one is present.  We also check
					 * for DISTINCT and VARIADIC here to give a better error
					 * location.  Other consistency checks are deferred to
					 * parse analysis.
					 */
					if ($2 != NIL)
					{
						if (n->agg_order != NIL)
							ereport(ERROR,
									(errcode(PG_ERRCODE_SYNTAX_ERROR),
									 errmsg("cannot use multiple ORDER BY clauses with WITHIN GROUP"),
									 parser_errposition(@2)));
						if (n->agg_distinct)
							ereport(ERROR,
									(errcode(PG_ERRCODE_SYNTAX_ERROR),
									 errmsg("cannot use DISTINCT with WITHIN GROUP"),
									 parser_errposition(@2)));
						if (n->func_variadic)
							ereport(ERROR,
									(errcode(PG_ERRCODE_SYNTAX_ERROR),
									 errmsg("cannot use VARIADIC with WITHIN GROUP"),
									 parser_errposition(@2)));
						n->agg_order = $2;
						n->agg_within_group = true;
					}
					n->agg_filter = $3;
					n->export_state = $4;
					n->over = $5;
					$$ = (PGNode *) n;
				}
			| func_expr_common_subexpr
				{ $$ = $1; }
		;

/*
 * As func_expr but does not accept WINDOW functions directly
 * (but they can still be contained in arguments for functions etc).
 * Use this when window expressions are not allowed, where needed to
 * disambiguate the grammar (e.g. in CREATE INDEX).
 */
func_expr_windowless:
			func_application						{ $$ = $1; }
			| func_expr_common_subexpr				{ $$ = $1; }
		;

/*
 * Special expressions that are considered to be functions.
 */
func_expr_common_subexpr:
			COLLATION FOR '(' a_expr ')'
				{
					$$ = (PGNode *) makeFuncCall(SystemFuncName("pg_collation_for"),
											   list_make1($4),
											   @1);
				}
			| CAST '(' a_expr AS Typename ')'
				{ $$ = makeTypeCast($3, $5, 0, @1); }
			| TRY_CAST '(' a_expr AS Typename ')'
				{ $$ = makeTypeCast($3, $5, 1, @1); }
			| EXTRACT '(' extract_list ')'
				{
					$$ = (PGNode *) makeFuncCall(SystemFuncName("date_part"), $3, @1);
				}
			| OVERLAY '(' overlay_list ')'
				{
					/* overlay(A PLACING B FROM C FOR D) is converted to
					 * overlay(A, B, C, D)
					 * overlay(A PLACING B FROM C) is converted to
					 * overlay(A, B, C)
					 */
					$$ = (PGNode *) makeFuncCall(SystemFuncName("overlay"), $3, @1);
				}
			| POSITION '(' position_list ')'
				{
					/* position(A in B) is converted to position(B, A) */
					$$ = (PGNode *) makeFuncCall(SystemFuncName("position"), $3, @1);
				}
			| SUBSTRING '(' substr_list ')'
				{
					/* substring(A from B for C) is converted to
					 * substring(A, B, C) - thomas 2000-11-28
					 */
					$$ = (PGNode *) makeFuncCall(SystemFuncName("substring"), $3, @1);
				}
			| TREAT '(' a_expr AS Typename ')'
				{
					/* TREAT(expr AS target) converts expr of a particular type to target,
					 * which is defined to be a subtype of the original expression.
					 * In SQL99, this is intended for use with structured UDTs,
					 * but let's make this a generally useful form allowing stronger
					 * coercions than are handled by implicit casting.
					 *
					 * Convert SystemTypeName() to SystemFuncName() even though
					 * at the moment they result in the same thing.
					 */
					$$ = (PGNode *) makeFuncCall(SystemFuncName(((PGValue *)llast($5->names))->val.str),
												list_make1($3),
												@1);
				}
			| TRIM '(' BOTH trim_list ')'
				{
					/* various trim expressions are defined in SQL
					 * - thomas 1997-07-19
					 */
					$$ = (PGNode *) makeFuncCall(SystemFuncName("trim"), $4, @1);
				}
			| TRIM '(' LEADING trim_list ')'
				{
					$$ = (PGNode *) makeFuncCall(SystemFuncName("ltrim"), $4, @1);
				}
			| TRIM '(' TRAILING trim_list ')'
				{
					$$ = (PGNode *) makeFuncCall(SystemFuncName("rtrim"), $4, @1);
				}
			| TRIM '(' trim_list ')'
				{
					$$ = (PGNode *) makeFuncCall(SystemFuncName("trim"), $3, @1);
				}
			| NULLIF '(' a_expr ',' a_expr ')'
				{
					$$ = (PGNode *) makeSimpleAExpr(PG_AEXPR_NULLIF, "=", $3, $5, @1);
				}
			| COALESCE '(' expr_list_opt_comma ')'
				{
					PGCoalesceExpr *c = makeNode(PGCoalesceExpr);
					c->args = $3;
					c->location = @1;
					$$ = (PGNode *)c;
				}
		;

list_comprehension:
				'[' a_expr FOR ColId IN_P a_expr ']'
				{
					PGLambdaFunction *lambda = makeNode(PGLambdaFunction);
					lambda->lhs = makeColumnRef($4, NIL, @4, yyscanner);
					lambda->rhs = $2;
					lambda->location = @1;
					PGFuncCall *n = makeFuncCall(SystemFuncName("list_apply"), list_make2($6, lambda), @1);
					$$ = (PGNode *) n;
				}
				| '[' a_expr FOR ColId IN_P c_expr IF_P a_expr']'
				{
					PGLambdaFunction *lambda = makeNode(PGLambdaFunction);
					lambda->lhs = makeColumnRef($4, NIL, @4, yyscanner);
					lambda->rhs = $2;
					lambda->location = @1;

					PGLambdaFunction *lambda_filter = makeNode(PGLambdaFunction);
					lambda_filter->lhs = makeColumnRef($4, NIL, @4, yyscanner);
					lambda_filter->rhs = $8;
					lambda_filter->location = @8;
					PGFuncCall *filter = makeFuncCall(SystemFuncName("list_filter"), list_make2($6, lambda_filter), @1);
					PGFuncCall *n = makeFuncCall(SystemFuncName("list_apply"), list_make2(filter, lambda), @1);
					$$ = (PGNode *) n;
				}
			;

/* We allow several variants for SQL and other compatibility. */
/*
 * Aggregate decoration clauses
 */
within_group_clause:
			WITHIN GROUP_P '(' sort_clause ')'		{ $$ = $4; }
			| /*EMPTY*/								{ $$ = NIL; }
		;

filter_clause:
			FILTER '(' WHERE a_expr ')'				{ $$ = $4; }
			| FILTER '(' a_expr ')'					{ $$ = $3; }
			| /*EMPTY*/								{ $$ = NULL; }
		;

export_clause:
			EXPORT_STATE            				{ $$ = true; }
			| /*EMPTY*/								{ $$ = false; }
		;

/*
 * Window Definitions
 */
window_clause:
			WINDOW window_definition_list			{ $$ = $2; }
			| /*EMPTY*/								{ $$ = NIL; }
		;

window_definition_list:
			window_definition						{ $$ = list_make1($1); }
			| window_definition_list ',' window_definition
													{ $$ = lappend($1, $3); }
		;

window_definition:
			ColId AS window_specification
				{
					PGWindowDef *n = $3;
					n->name = $1;
					$$ = n;
				}
		;

over_clause: OVER window_specification
				{ $$ = $2; }
			| OVER ColId
				{
					PGWindowDef *n = makeNode(PGWindowDef);
					n->name = $2;
					n->refname = NULL;
					n->partitionClause = NIL;
					n->orderClause = NIL;
					n->frameOptions = FRAMEOPTION_DEFAULTS;
					n->startOffset = NULL;
					n->endOffset = NULL;
					n->location = @2;
					$$ = n;
				}
			| /*EMPTY*/
				{ $$ = NULL; }
		;

window_specification: '(' opt_existing_window_name opt_partition_clause
						opt_sort_clause opt_frame_clause ')'
				{
					PGWindowDef *n = makeNode(PGWindowDef);
					n->name = NULL;
					n->refname = $2;
					n->partitionClause = $3;
					n->orderClause = $4;
					/* copy relevant fields of opt_frame_clause */
					n->frameOptions = $5->frameOptions;
					n->startOffset = $5->startOffset;
					n->endOffset = $5->endOffset;
					n->location = @1;
					$$ = n;
				}
		;

/*
 * If we see PARTITION, RANGE, or ROWS as the first token after the '('
 * of a window_specification, we want the assumption to be that there is
 * no existing_window_name; but those keywords are unreserved and so could
 * be ColIds.  We fix this by making them have the same precedence as IDENT
 * and giving the empty production here a slightly higher precedence, so
 * that the shift/reduce conflict is resolved in favor of reducing the rule.
 * These keywords are thus precluded from being an existing_window_name but
 * are not reserved for any other purpose.
 */
opt_existing_window_name: ColId						{ $$ = $1; }
			| /*EMPTY*/				%prec Op		{ $$ = NULL; }
		;

opt_partition_clause: PARTITION BY expr_list		{ $$ = $3; }
			| /*EMPTY*/								{ $$ = NIL; }
		;

/*
 * For frame clauses, we return a PGWindowDef, but only some fields are used:
 * frameOptions, startOffset, and endOffset.
 *
 * This is only a subset of the full SQL:2008 frame_clause grammar.
 * We don't support <window frame exclusion> yet.
 */
opt_frame_clause:
			RANGE frame_extent
				{
					PGWindowDef *n = $2;
					n->frameOptions |= FRAMEOPTION_NONDEFAULT | FRAMEOPTION_RANGE;
					$$ = n;
				}
			| ROWS frame_extent
				{
					PGWindowDef *n = $2;
					n->frameOptions |= FRAMEOPTION_NONDEFAULT | FRAMEOPTION_ROWS;
					$$ = n;
				}
			| /*EMPTY*/
				{
					PGWindowDef *n = makeNode(PGWindowDef);
					n->frameOptions = FRAMEOPTION_DEFAULTS;
					n->startOffset = NULL;
					n->endOffset = NULL;
					$$ = n;
				}
		;

frame_extent: frame_bound
				{
					PGWindowDef *n = $1;
					/* reject invalid cases */
					if (n->frameOptions & FRAMEOPTION_START_UNBOUNDED_FOLLOWING)
						ereport(ERROR,
								(errcode(PG_ERRCODE_WINDOWING_ERROR),
								 errmsg("frame start cannot be UNBOUNDED FOLLOWING"),
								 parser_errposition(@1)));
					if (n->frameOptions & FRAMEOPTION_START_VALUE_FOLLOWING)
						ereport(ERROR,
								(errcode(PG_ERRCODE_WINDOWING_ERROR),
								 errmsg("frame starting from following row cannot end with current row"),
								 parser_errposition(@1)));
					n->frameOptions |= FRAMEOPTION_END_CURRENT_ROW;
					$$ = n;
				}
			| BETWEEN frame_bound AND frame_bound
				{
					PGWindowDef *n1 = $2;
					PGWindowDef *n2 = $4;
					/* form merged options */
					int		frameOptions = n1->frameOptions;
					/* shift converts START_ options to END_ options */
					frameOptions |= n2->frameOptions << 1;
					frameOptions |= FRAMEOPTION_BETWEEN;
					/* reject invalid cases */
					if (frameOptions & FRAMEOPTION_START_UNBOUNDED_FOLLOWING)
						ereport(ERROR,
								(errcode(PG_ERRCODE_WINDOWING_ERROR),
								 errmsg("frame start cannot be UNBOUNDED FOLLOWING"),
								 parser_errposition(@2)));
					if (frameOptions & FRAMEOPTION_END_UNBOUNDED_PRECEDING)
						ereport(ERROR,
								(errcode(PG_ERRCODE_WINDOWING_ERROR),
								 errmsg("frame end cannot be UNBOUNDED PRECEDING"),
								 parser_errposition(@4)));
					if ((frameOptions & FRAMEOPTION_START_CURRENT_ROW) &&
						(frameOptions & FRAMEOPTION_END_VALUE_PRECEDING))
						ereport(ERROR,
								(errcode(PG_ERRCODE_WINDOWING_ERROR),
								 errmsg("frame starting from current row cannot have preceding rows"),
								 parser_errposition(@4)));
					if ((frameOptions & FRAMEOPTION_START_VALUE_FOLLOWING) &&
						(frameOptions & (FRAMEOPTION_END_VALUE_PRECEDING |
										 FRAMEOPTION_END_CURRENT_ROW)))
						ereport(ERROR,
								(errcode(PG_ERRCODE_WINDOWING_ERROR),
								 errmsg("frame starting from following row cannot have preceding rows"),
								 parser_errposition(@4)));
					n1->frameOptions = frameOptions;
					n1->endOffset = n2->startOffset;
					$$ = n1;
				}
		;

/*
 * This is used for both frame start and frame end, with output set up on
 * the assumption it's frame start; the frame_extent productions must reject
 * invalid cases.
 */
frame_bound:
			UNBOUNDED PRECEDING
				{
					PGWindowDef *n = makeNode(PGWindowDef);
					n->frameOptions = FRAMEOPTION_START_UNBOUNDED_PRECEDING;
					n->startOffset = NULL;
					n->endOffset = NULL;
					$$ = n;
				}
			| UNBOUNDED FOLLOWING
				{
					PGWindowDef *n = makeNode(PGWindowDef);
					n->frameOptions = FRAMEOPTION_START_UNBOUNDED_FOLLOWING;
					n->startOffset = NULL;
					n->endOffset = NULL;
					$$ = n;
				}
			| CURRENT_P ROW
				{
					PGWindowDef *n = makeNode(PGWindowDef);
					n->frameOptions = FRAMEOPTION_START_CURRENT_ROW;
					n->startOffset = NULL;
					n->endOffset = NULL;
					$$ = n;
				}
			| a_expr PRECEDING
				{
					PGWindowDef *n = makeNode(PGWindowDef);
					n->frameOptions = FRAMEOPTION_START_VALUE_PRECEDING;
					n->startOffset = $1;
					n->endOffset = NULL;
					$$ = n;
				}
			| a_expr FOLLOWING
				{
					PGWindowDef *n = makeNode(PGWindowDef);
					n->frameOptions = FRAMEOPTION_START_VALUE_FOLLOWING;
					n->startOffset = $1;
					n->endOffset = NULL;
					$$ = n;
				}
		;


/*
 * Supporting nonterminals for expressions.
 */

/* Explicit row production.
 *
 * SQL99 allows an optional ROW keyword, so we can now do single-element rows
 * without conflicting with the parenthesized a_expr production.  Without the
 * ROW keyword, there must be more than one a_expr inside the parens.
 */
qualified_row:	ROW '(' expr_list_opt_comma ')'					{ $$ = $3; }
			| ROW '(' ')'							{ $$ = NIL; }
		;

row:		qualified_row							{ $$ = $1;}
			| '(' expr_list ',' a_expr ')'			{ $$ = lappend($2, $4); }
		;

dict_arg:
	ColIdOrString ':' a_expr						{
		PGNamedArgExpr *na = makeNode(PGNamedArgExpr);
		na->name = $1;
		na->arg = (PGExpr *) $3;
		na->argnumber = -1;
		na->location = @1;
		$$ = (PGNode *) na;
	}

dict_arguments:
	dict_arg						{ $$ = list_make1($1); }
	| dict_arguments ',' dict_arg	{ $$ = lappend($1, $3); }


dict_arguments_opt_comma:
			dict_arguments								{ $$ = $1; }
			| dict_arguments ','							{ $$ = $1; }
		;

map_arg:
			a_expr ':' a_expr
			{
				$$ = list_make2($1, $3);
			}
	;

map_arguments:
			map_arg									{ $$ = list_make1($1); }
			| map_arguments ',' map_arg				{ $$ = lappend($1, $3); }
	;


map_arguments_opt_comma:
			map_arguments							{ $$ = $1; }
			| map_arguments ','						{ $$ = $1; }
		;


opt_map_arguments_opt_comma:
			map_arguments_opt_comma					{ $$ = $1; }
			| /* empty */							{ $$ = NULL; }
		;

sub_type:	ANY										{ $$ = PG_ANY_SUBLINK; }
			| SOME									{ $$ = PG_ANY_SUBLINK; }
			| ALL									{ $$ = PG_ALL_SUBLINK; }
		;

all_Op:		Op										{ $$ = $1; }
			| MathOp								{ $$ = (char*) $1; }
		;

MathOp:		 '+'									{ $$ = "+"; }
			| '-'									{ $$ = "-"; }
			| '*'									{ $$ = "*"; }
			| '/'									{ $$ = "/"; }
			| INTEGER_DIVISION						{ $$ = "//"; }
			| '%'									{ $$ = "%"; }
			| '^'									{ $$ = "^"; }
			| POWER_OF								{ $$ = "**"; }
			| '<'									{ $$ = "<"; }
			| '>'									{ $$ = ">"; }
			| '='									{ $$ = "="; }
			| LESS_EQUALS							{ $$ = "<="; }
			| GREATER_EQUALS						{ $$ = ">="; }
			| NOT_EQUALS							{ $$ = "<>"; }
		;

qual_Op:	Op
					{ $$ = list_make1(makeString($1)); }
			| OPERATOR '(' any_operator ')'
					{ $$ = $3; }
		;

qual_all_Op:
			all_Op
					{ $$ = list_make1(makeString($1)); }
			| OPERATOR '(' any_operator ')'
					{ $$ = $3; }
		;

subquery_Op:
			all_Op
					{ $$ = list_make1(makeString($1)); }
			| OPERATOR '(' any_operator ')'
					{ $$ = $3; }
			| LIKE
					{ $$ = list_make1(makeString("~~")); }
			| NOT_LA LIKE
					{ $$ = list_make1(makeString("!~~")); }
			| GLOB
					{ $$ = list_make1(makeString("~~~")); }
			| NOT_LA GLOB
					{ $$ = list_make1(makeString("!~~~")); }
			| ILIKE
					{ $$ = list_make1(makeString("~~*")); }
			| NOT_LA ILIKE
					{ $$ = list_make1(makeString("!~~*")); }
/* cannot put SIMILAR TO here, because SIMILAR TO is a hack.
 * the regular expression is preprocessed by a function (similar_escape),
 * and the ~ operator for posix regular expressions is used.
 *        x SIMILAR TO y     ->    x ~ similar_escape(y)
 * this transformation is made on the fly by the parser upwards.
 * however the PGSubLink structure which handles any/some/all stuff
 * is not ready for such a thing.
 */
			;


any_operator:
			all_Op
					{ $$ = list_make1(makeString($1)); }
			| ColId '.' any_operator
					{ $$ = lcons(makeString($1), $3); }
		;

c_expr_list:
			c_expr
				{
					$$ = list_make1($1);
				}
			| c_expr_list ',' c_expr
				{
					$$ = lappend($1, $3);
				}
		;

c_expr_list_opt_comma:
			c_expr_list
				{
					$$ = $1;
				}
			|
			c_expr_list ','
				{
					$$ = $1;
				}
		;

expr_list:	a_expr
				{
					$$ = list_make1($1);
				}
			| expr_list ',' a_expr
				{
					$$ = lappend($1, $3);
				}
		;

expr_list_opt_comma:
			expr_list
				{
					$$ = $1;
				}
			|
			expr_list ','
				{
					$$ = $1;
				}
		;

opt_expr_list_opt_comma:
			expr_list_opt_comma
				{
					$$ = $1;
				}
			| /* empty */
				{
					$$ = NULL;
				}
		;



/* function arguments can have names */
func_arg_list:  func_arg_expr
				{
					$$ = list_make1($1);
				}
			| func_arg_list ',' func_arg_expr
				{
					$$ = lappend($1, $3);
				}
		;

func_arg_expr:  a_expr
				{
					$$ = $1;
				}
			| param_name COLON_EQUALS a_expr
				{
					PGNamedArgExpr *na = makeNode(PGNamedArgExpr);
					na->name = $1;
					na->arg = (PGExpr *) $3;
					na->argnumber = -1;		/* until determined */
					na->location = @1;
					$$ = (PGNode *) na;
				}
			| param_name EQUALS_GREATER a_expr
				{
					PGNamedArgExpr *na = makeNode(PGNamedArgExpr);
					na->name = $1;
					na->arg = (PGExpr *) $3;
					na->argnumber = -1;		/* until determined */
					na->location = @1;
					$$ = (PGNode *) na;
				}
		;

type_list:	Typename								{ $$ = list_make1($1); }
			| type_list ',' Typename				{ $$ = lappend($1, $3); }
		;

extract_list:
			extract_arg FROM a_expr
				{
					$$ = list_make2(makeStringConst($1, @1), $3);
				}
			| /*EMPTY*/								{ $$ = NIL; }
		;

/* Allow delimited string Sconst in extract_arg as an SQL extension.
 * - thomas 2001-04-12
 */
extract_arg:
			IDENT											{ $$ = $1; }
			| year_keyword									{ $$ = (char*) "year"; }
			| month_keyword									{ $$ = (char*) "month"; }
			| day_keyword									{ $$ = (char*) "day"; }
			| hour_keyword									{ $$ = (char*) "hour"; }
			| minute_keyword								{ $$ = (char*) "minute"; }
			| second_keyword								{ $$ = (char*) "second"; }
			| millisecond_keyword							{ $$ = (char*) "millisecond"; }
			| microsecond_keyword							{ $$ = (char*) "microsecond"; }
			| Sconst										{ $$ = $1; }
		;

/* OVERLAY() arguments
 * SQL99 defines the OVERLAY() function:
 * o overlay(text placing text from int for int)
 * o overlay(text placing text from int)
 * and similarly for binary strings
 */
overlay_list:
			a_expr overlay_placing substr_from substr_for
				{
					$$ = list_make4($1, $2, $3, $4);
				}
			| a_expr overlay_placing substr_from
				{
					$$ = list_make3($1, $2, $3);
				}
		;

overlay_placing:
			PLACING a_expr
				{ $$ = $2; }
		;

/* position_list uses b_expr not a_expr to avoid conflict with general IN */

position_list:
			b_expr IN_P b_expr						{ $$ = list_make2($3, $1); }
			| /*EMPTY*/								{ $$ = NIL; }
		;

/* SUBSTRING() arguments
 * SQL9x defines a specific syntax for arguments to SUBSTRING():
 * o substring(text from int for int)
 * o substring(text from int) get entire string from starting point "int"
 * o substring(text for int) get first "int" characters of string
 * o substring(text from pattern) get entire string matching pattern
 * o substring(text from pattern for escape) same with specified escape char
 * We also want to support generic substring functions which accept
 * the usual generic list of arguments. So we will accept both styles
 * here, and convert the SQL9x style to the generic list for further
 * processing. - thomas 2000-11-28
 */
substr_list:
			a_expr substr_from substr_for
				{
					$$ = list_make3($1, $2, $3);
				}
			| a_expr substr_for substr_from
				{
					/* not legal per SQL99, but might as well allow it */
					$$ = list_make3($1, $3, $2);
				}
			| a_expr substr_from
				{
					$$ = list_make2($1, $2);
				}
			| a_expr substr_for
				{
					/*
					 * Since there are no cases where this syntax allows
					 * a textual FOR value, we forcibly cast the argument
					 * to int4.  The possible matches in pg_proc are
					 * substring(text,int4) and substring(text,text),
					 * and we don't want the parser to choose the latter,
					 * which it is likely to do if the second argument
					 * is unknown or doesn't have an implicit cast to int4.
					 */
					$$ = list_make3($1, makeIntConst(1, -1),
									makeTypeCast($2,
												 SystemTypeName("int4"), 0, -1));
				}
			| expr_list
				{
					$$ = $1;
				}
			| /*EMPTY*/
				{ $$ = NIL; }
		;

substr_from:
			FROM a_expr								{ $$ = $2; }
		;

substr_for: FOR a_expr								{ $$ = $2; }
		;

trim_list:	a_expr FROM expr_list_opt_comma					{ $$ = lappend($3, $1); }
			| FROM expr_list_opt_comma						{ $$ = $2; }
			| expr_list_opt_comma								{ $$ = $1; }
		;

in_expr:	select_with_parens
				{
					PGSubLink *n = makeNode(PGSubLink);
					n->subselect = $1;
					/* other fields will be filled later */
					$$ = (PGNode *)n;
				}
			| '(' expr_list_opt_comma ')'						{ $$ = (PGNode *)$2; }
		;

/*
 * Define SQL-style CASE clause.
 * - Full specification
 *	CASE WHEN a = b THEN c ... ELSE d END
 * - Implicit argument
 *	CASE a WHEN b THEN c ... ELSE d END
 */
case_expr:	CASE case_arg when_clause_list case_default END_P
				{
					PGCaseExpr *c = makeNode(PGCaseExpr);
					c->casetype = InvalidOid; /* not analyzed yet */
					c->arg = (PGExpr *) $2;
					c->args = $3;
					c->defresult = (PGExpr *) $4;
					c->location = @1;
					$$ = (PGNode *)c;
				}
		;

when_clause_list:
			/* There must be at least one */
			when_clause								{ $$ = list_make1($1); }
			| when_clause_list when_clause			{ $$ = lappend($1, $2); }
		;

when_clause:
			WHEN a_expr THEN a_expr
				{
					PGCaseWhen *w = makeNode(PGCaseWhen);
					w->expr = (PGExpr *) $2;
					w->result = (PGExpr *) $4;
					w->location = @1;
					$$ = (PGNode *)w;
				}
		;

case_default:
			ELSE a_expr								{ $$ = $2; }
			| /*EMPTY*/								{ $$ = NULL; }
		;

case_arg:	a_expr									{ $$ = $1; }
			| /*EMPTY*/								{ $$ = NULL; }
		;

columnref:	ColId
				{
					$$ = makeColumnRef($1, NIL, @1, yyscanner);
				}
			| ColId indirection
				{
					$$ = makeColumnRef($1, $2, @1, yyscanner);
				}
		;

indirection_el:
			'[' a_expr ']'
				{
					PGAIndices *ai = makeNode(PGAIndices);
					ai->is_slice = false;
					ai->lidx = NULL;
					ai->uidx = $2;
					$$ = (PGNode *) ai;
				}
			| '[' opt_slice_bound ':' opt_slice_bound ']'
				{
					PGAIndices *ai = makeNode(PGAIndices);
					ai->is_slice = true;
					ai->lidx = $2;
					ai->uidx = $4;
					$$ = (PGNode *) ai;
				}
			| '[' opt_slice_bound ':' opt_slice_bound ':' opt_slice_bound ']' {
				    	PGAIndices *ai = makeNode(PGAIndices);
				    	ai->is_slice = true;
				    	ai->lidx = $2;
				    	ai->uidx = $4;
				    	ai->step = $6;
				    	$$ = (PGNode *) ai;
				}
			| '[' opt_slice_bound ':' '-' ':' opt_slice_bound ']' {
					PGAIndices *ai = makeNode(PGAIndices);
					ai->is_slice = true;
					ai->lidx = $2;
					ai->step = $6;
					$$ = (PGNode *) ai;
				}
				;

opt_slice_bound:
			a_expr									{ $$ = $1; }
			| /*EMPTY*/								{ $$ = NULL; }
		;


opt_indirection:
			/*EMPTY*/								{ $$ = NIL; }
			| opt_indirection indirection_el		{ $$ = lappend($1, $2); }
		;

opt_func_arguments:
	/* empty */ 				{ $$ = NULL; }
	| '(' ')'					{ $$ = list_make1(NULL); }
	| '(' func_arg_list ')' 	{ $$ = $2; }
	;

extended_indirection_el:
			'.' attr_name opt_func_arguments
				{
					if ($3) {
						PGFuncCall *n = makeFuncCall(list_make1(makeString($2)), $3->head->data.ptr_value ? $3 : NULL, @2);
						$$ = (PGNode *) n;
					} else {
						$$ = (PGNode *) makeString($2);
					}
				}
			| '[' a_expr ']'
				{
					PGAIndices *ai = makeNode(PGAIndices);
					ai->is_slice = false;
					ai->lidx = NULL;
					ai->uidx = $2;
					$$ = (PGNode *) ai;
				}
			| '[' opt_slice_bound ':' opt_slice_bound ']'
				{
					PGAIndices *ai = makeNode(PGAIndices);
					ai->is_slice = true;
					ai->lidx = $2;
					ai->uidx = $4;
					$$ = (PGNode *) ai;
				}
		    	| '[' opt_slice_bound ':' opt_slice_bound ':' opt_slice_bound ']' {
					PGAIndices *ai = makeNode(PGAIndices);
					ai->is_slice = true;
					ai->lidx = $2;
					ai->uidx = $4;
					ai->step = $6;
                 			$$ = (PGNode *) ai;
                		}

			| '[' opt_slice_bound ':' '-' ':' opt_slice_bound ']' {
					PGAIndices *ai = makeNode(PGAIndices);
					ai->is_slice = true;
					ai->lidx = $2;
					ai->step = $6;
					$$ = (PGNode *) ai;
				}
		;

extended_indirection:
			extended_indirection_el									{ $$ = list_make1($1); }
			| extended_indirection extended_indirection_el			{ $$ = lappend($1, $2); }
		;

opt_extended_indirection:
			/*EMPTY*/												{ $$ = NIL; }
			| opt_extended_indirection extended_indirection_el		{ $$ = lappend($1, $2); }
		;



opt_asymmetric: ASYMMETRIC
			| /*EMPTY*/
		;


/*****************************************************************************
 *
 *	target list for SELECT
 *
 *****************************************************************************/

opt_target_list_opt_comma: target_list_opt_comma						{ $$ = $1; }
			| /* EMPTY */							{ $$ = NIL; }
		;

target_list:
			target_el								{ $$ = list_make1($1); }
			| target_list ',' target_el				{ $$ = lappend($1, $3); }
		;

target_list_opt_comma:
			target_list								{ $$ = $1; }
			| target_list ','						{ $$ = $1; }
		;

target_el:	a_expr AS ColLabelOrString
				{
					$$ = makeNode(PGResTarget);
					$$->name = $3;
					$$->indirection = NIL;
					$$->val = (PGNode *)$1;
					$$->location = @1;
				}
			/*
			 * We support omitting AS only for column labels that aren't
			 * any known keyword.  There is an ambiguity against postfix
			 * operators: is "a ! b" an infix expression, or a postfix
			 * expression and a column label?  We prefer to resolve this
			 * as an infix expression, which we accomplish by assigning
			 * IDENT a precedence higher than POSTFIXOP.
			 */
			| a_expr IDENT
				{
					$$ = makeNode(PGResTarget);
					$$->name = $2;
					$$->indirection = NIL;
					$$->val = (PGNode *)$1;
					$$->location = @1;
				}
			| a_expr
				{
					$$ = makeNode(PGResTarget);
					$$->name = NULL;
					$$->indirection = NIL;
					$$->val = (PGNode *)$1;
					$$->location = @1;
				}
		;

except_list: EXCLUDE '(' name_list_opt_comma ')'					{ $$ = $3; }
			| EXCLUDE ColId								{ $$ = list_make1(makeString($2)); }
		;

opt_except_list: except_list						{ $$ = $1; }
			| /*EMPTY*/								{ $$ = NULL; }
		;

replace_list_el: a_expr AS ColId					{ $$ = list_make2($1, makeString($3)); }
		;

replace_list:
			replace_list_el							{ $$ = list_make1($1); }
			| replace_list ',' replace_list_el		{ $$ = lappend($1, $3); }
		;

replace_list_opt_comma:
			replace_list								{ $$ = $1; }
			| replace_list ','							{ $$ = $1; }
		;

opt_replace_list: REPLACE '(' replace_list_opt_comma ')'		{ $$ = $3; }
			| REPLACE replace_list_el				{ $$ = list_make1($2); }
			| /*EMPTY*/								{ $$ = NULL; }
		;

/*****************************************************************************
 *
 *	Names and constants
 *
 *****************************************************************************/

qualified_name_list:
			qualified_name							{ $$ = list_make1($1); }
			| qualified_name_list ',' qualified_name { $$ = lappend($1, $3); }
		;


name_list:	name
					{ $$ = list_make1(makeString($1)); }
			| name_list ',' name
					{ $$ = lappend($1, makeString($3)); }
		;


name_list_opt_comma:
			name_list								{ $$ = $1; }
			| name_list ','							{ $$ = $1; }
		;

name_list_opt_comma_opt_bracket:
			name_list_opt_comma										{ $$ = $1; }
			| '(' name_list_opt_comma ')'							{ $$ = $2; }
		;

name:		ColIdOrString							{ $$ = $1; };


/*
 * The production for a qualified func_name has to exactly match the
 * production for a qualified columnref, because we cannot tell which we
 * are parsing until we see what comes after it ('(' or Sconst for a func_name,
 * anything else for a columnref).  Therefore we allow 'indirection' which
 * may contain subscripts, and reject that case in the C code.  (If we
 * ever implement SQL99-like methods, such syntax may actually become legal!)
 */
func_name:	function_name_token
					{ $$ = list_make1(makeString($1)); }
			|
			ColId indirection
					{
						$$ = check_func_name(lcons(makeString($1), $2),
											 yyscanner);
					}
		;


/*
 * Constants
 */
AexprConst: Iconst
				{
					$$ = makeIntConst($1, @1);
				}
			| FCONST
				{
					$$ = makeFloatConst($1, @1);
				}
			| Sconst opt_indirection
				{
					if ($2)
					{
						PGAIndirection *n = makeNode(PGAIndirection);
						n->arg = makeStringConst($1, @1);
						n->indirection = check_indirection($2, yyscanner);
						$$ = (PGNode *) n;
					}
					else
						$$ = makeStringConst($1, @1);
				}
			| BCONST
				{
					$$ = makeBitStringConst($1, @1);
				}
			| XCONST
				{
					/* This is a bit constant per SQL99:
					 * Without Feature F511, "BIT data type",
					 * a <general literal> shall not be a
					 * <bit string literal> or a <hex string literal>.
					 */
					$$ = makeBitStringConst($1, @1);
				}
			| func_name Sconst
				{
					/* generic type 'literal' syntax */
					PGTypeName *t = makeTypeNameFromNameList($1);
					t->location = @1;
					$$ = makeStringConstCast($2, @2, t);
				}
			| func_name '(' func_arg_list opt_sort_clause opt_ignore_nulls ')' Sconst
				{
					/* generic syntax with a type modifier */
					PGTypeName *t = makeTypeNameFromNameList($1);
					PGListCell *lc;

					/*
					 * We must use func_arg_list and opt_sort_clause in the
					 * production to avoid reduce/reduce conflicts, but we
					 * don't actually wish to allow PGNamedArgExpr in this
					 * context, ORDER BY, nor IGNORE NULLS.
					 */
					foreach(lc, $3)
					{
						PGNamedArgExpr *arg = (PGNamedArgExpr *) lfirst(lc);

						if (IsA(arg, PGNamedArgExpr))
							ereport(ERROR,
									(errcode(PG_ERRCODE_SYNTAX_ERROR),
									 errmsg("type modifier cannot have parameter name"),
									 parser_errposition(arg->location)));
					}
					if ($4 != NIL)
							ereport(ERROR,
									(errcode(PG_ERRCODE_SYNTAX_ERROR),
									 errmsg("type modifier cannot have ORDER BY"),
									 parser_errposition(@4)));
					if ($5 != false)
							ereport(ERROR,
									(errcode(PG_ERRCODE_SYNTAX_ERROR),
									 errmsg("type modifier cannot have IGNORE NULLS"),
									 parser_errposition(@5)));


					t->typmods = $3;
					t->location = @1;
					$$ = makeStringConstCast($7, @7, t);
				}
			| ConstTypename Sconst
				{
					$$ = makeStringConstCast($2, @2, $1);
				}
			| ConstInterval '(' a_expr ')' opt_interval
				{
					$$ = makeIntervalNode($3, @3, $5);
				}
			| ConstInterval Iconst opt_interval
				{
					$$ = makeIntervalNode($2, @2, $3);
				}
			| ConstInterval Sconst opt_interval
				{
					$$ = makeIntervalNode($2, @2, $3);
				}
			| TRUE_P
				{
					$$ = makeBoolAConst(true, @1);
				}
			| FALSE_P
				{
					$$ = makeBoolAConst(false, @1);
				}
			| NULL_P
				{
					$$ = makeNullAConst(@1);
				}
		;

Iconst:		ICONST									{ $$ = $1; };

/* Role specifications */
/*
 * Name classification hierarchy.
 *
 * IDENT is the lexeme returned by the lexer for identifiers that match
 * no known keyword.  In most cases, we can accept certain keywords as
 * names, not only IDENTs.	We prefer to accept as many such keywords
 * as possible to minimize the impact of "reserved words" on programmers.
 * So, we divide names into several possible classes.  The classification
 * is chosen in part to make keywords acceptable as names wherever possible.
 */


/* Type/function identifier --- names that can be type or function names.
 */
type_function_name:	IDENT							{ $$ = $1; }
			| unreserved_keyword					{ $$ = pstrdup($1); }
			| type_func_name_keyword				{ $$ = pstrdup($1); }
		;

function_name_token:	IDENT						{ $$ = $1; }
			| unreserved_keyword					{ $$ = pstrdup($1); }
			| func_name_keyword						{ $$ = pstrdup($1); }
		;

type_name_token:	IDENT						{ $$ = $1; }
			| unreserved_keyword					{ $$ = pstrdup($1); }
			| type_name_keyword						{ $$ = pstrdup($1); }
		;

any_name:	ColId						{ $$ = list_make1(makeString($1)); }
			| ColId attrs				{ $$ = lcons(makeString($1), $2); }
		;

attrs:		'.' attr_name
					{ $$ = list_make1(makeString($2)); }
			| attrs '.' attr_name
					{ $$ = lappend($1, makeString($3)); }
		;

opt_name_list:
			'(' name_list_opt_comma ')'						{ $$ = $2; }
			| /*EMPTY*/								{ $$ = NIL; }
		;

param_name:	type_function_name
		;


ColLabelOrString:	ColLabel						{ $$ = $1; }
					| SCONST						{ $$ = $1; }
		;
#line 1 "third_party/libpg_query/grammar/statements/transaction.y"
TransactionStmt:
			ABORT_P opt_transaction
				{
					PGTransactionStmt *n = makeNode(PGTransactionStmt);
					n->kind = PG_TRANS_STMT_ROLLBACK;
					n->options = NIL;
					$$ = (PGNode *)n;
				}
			| BEGIN_P opt_transaction
				{
					PGTransactionStmt *n = makeNode(PGTransactionStmt);
					n->kind = PG_TRANS_STMT_BEGIN;
					$$ = (PGNode *)n;
				}
			| START opt_transaction
				{
					PGTransactionStmt *n = makeNode(PGTransactionStmt);
					n->kind = PG_TRANS_STMT_START;
					$$ = (PGNode *)n;
				}
			| COMMIT opt_transaction
				{
					PGTransactionStmt *n = makeNode(PGTransactionStmt);
					n->kind = PG_TRANS_STMT_COMMIT;
					n->options = NIL;
					$$ = (PGNode *)n;
				}
			| END_P opt_transaction
				{
					PGTransactionStmt *n = makeNode(PGTransactionStmt);
					n->kind = PG_TRANS_STMT_COMMIT;
					n->options = NIL;
					$$ = (PGNode *)n;
				}
			| ROLLBACK opt_transaction
				{
					PGTransactionStmt *n = makeNode(PGTransactionStmt);
					n->kind = PG_TRANS_STMT_ROLLBACK;
					n->options = NIL;
					$$ = (PGNode *)n;
				}
		;


opt_transaction:	WORK							{}
			| TRANSACTION							{}
			| /*EMPTY*/								{}
		;
#line 1 "third_party/libpg_query/grammar/statements/update.y"
/*****************************************************************************
 *
 *		QUERY:
 *				PGUpdateStmt (UPDATE)
 *
 *****************************************************************************/
UpdateStmt: opt_with_clause UPDATE relation_expr_opt_alias
			SET set_clause_list_opt_comma
			from_clause
			where_or_current_clause
			returning_clause
				{
					PGUpdateStmt *n = makeNode(PGUpdateStmt);
					n->relation = $3;
					n->targetList = $5;
					n->fromClause = $6;
					n->whereClause = $7;
					n->returningList = $8;
					n->withClause = $1;
					$$ = (PGNode *)n;
				}
		;
#line 1 "third_party/libpg_query/grammar/statements/use.y"
UseStmt:
			USE_P qualified_name
				{
					PGUseStmt *n = makeNode(PGUseStmt);
					n->name = $2;
					$$ = (PGNode *) n;
				}
		;
#line 1 "third_party/libpg_query/grammar/statements/vacuum.y"
/*****************************************************************************
 *
 *		QUERY:
 *				VACUUM
 *				ANALYZE
 *
 *****************************************************************************/
VacuumStmt: VACUUM opt_full opt_freeze opt_verbose
				{
					PGVacuumStmt *n = makeNode(PGVacuumStmt);
					n->options = PG_VACOPT_VACUUM;
					if ($2)
						n->options |= PG_VACOPT_FULL;
					if ($3)
						n->options |= PG_VACOPT_FREEZE;
					if ($4)
						n->options |= PG_VACOPT_VERBOSE;
					n->relation = NULL;
					n->va_cols = NIL;
					$$ = (PGNode *)n;
				}
			| VACUUM opt_full opt_freeze opt_verbose qualified_name opt_name_list
				{
					PGVacuumStmt *n = makeNode(PGVacuumStmt);
					n->options = PG_VACOPT_VACUUM;
					if ($2)
						n->options |= PG_VACOPT_FULL;
					if ($3)
						n->options |= PG_VACOPT_FREEZE;
					if ($4)
						n->options |= PG_VACOPT_VERBOSE;
					n->relation = $5;
					n->va_cols = $6;
					$$ = (PGNode *)n;
				}
			| VACUUM opt_full opt_freeze opt_verbose AnalyzeStmt
				{
					PGVacuumStmt *n = (PGVacuumStmt *) $5;
					n->options |= PG_VACOPT_VACUUM;
					if ($2)
						n->options |= PG_VACOPT_FULL;
					if ($3)
						n->options |= PG_VACOPT_FREEZE;
					if ($4)
						n->options |= PG_VACOPT_VERBOSE;
					$$ = (PGNode *)n;
				}
			| VACUUM '(' vacuum_option_list ')'
				{
					PGVacuumStmt *n = makeNode(PGVacuumStmt);
					n->options = PG_VACOPT_VACUUM | $3;
					n->relation = NULL;
					n->va_cols = NIL;
					$$ = (PGNode *) n;
				}
			| VACUUM '(' vacuum_option_list ')' qualified_name opt_name_list
				{
					PGVacuumStmt *n = makeNode(PGVacuumStmt);
					n->options = PG_VACOPT_VACUUM | $3;
					n->relation = $5;
					n->va_cols = $6;
					if (n->va_cols != NIL)	/* implies analyze */
						n->options |= PG_VACOPT_ANALYZE;
					$$ = (PGNode *) n;
				}
		;


vacuum_option_elem:
			analyze_keyword		{ $$ = PG_VACOPT_ANALYZE; }
			| VERBOSE			{ $$ = PG_VACOPT_VERBOSE; }
			| FREEZE			{ $$ = PG_VACOPT_FREEZE; }
			| FULL				{ $$ = PG_VACOPT_FULL; }
			| IDENT
				{
					if (strcmp($1, "disable_page_skipping") == 0)
						$$ = PG_VACOPT_DISABLE_PAGE_SKIPPING;
					else
						ereport(ERROR,
								(errcode(PG_ERRCODE_SYNTAX_ERROR),
							 errmsg("unrecognized VACUUM option \"%s\"", $1),
									 parser_errposition(@1)));
				}
		;


opt_full:	FULL									{ $$ = true; }
			| /*EMPTY*/								{ $$ = false; }
		;


vacuum_option_list:
			vacuum_option_elem								{ $$ = $1; }
			| vacuum_option_list ',' vacuum_option_elem		{ $$ = $1 | $3; }
		;


opt_freeze: FREEZE									{ $$ = true; }
			| /*EMPTY*/								{ $$ = false; }
		;
#line 1 "third_party/libpg_query/grammar/statements/variable_reset.y"
VariableResetStmt:
			RESET reset_rest
			{
				$2->scope = VAR_SET_SCOPE_DEFAULT;
				$$ = (PGNode *) $2;
			}
			| RESET LOCAL reset_rest
				{
					$3->scope = VAR_SET_SCOPE_LOCAL;
					$$ = (PGNode *) $3;
				}
			| RESET SESSION reset_rest
				{
					$3->scope = VAR_SET_SCOPE_SESSION;
					$$ = (PGNode *) $3;
				}
			| RESET GLOBAL reset_rest
				{
					$3->scope = VAR_SET_SCOPE_GLOBAL;
					$$ = (PGNode *) $3;
				}
		;


generic_reset:
			var_name
				{
					PGVariableSetStmt *n = makeNode(PGVariableSetStmt);
					n->kind = VAR_RESET;
					n->name = $1;
					$$ = n;
				}
			| ALL
				{
					PGVariableSetStmt *n = makeNode(PGVariableSetStmt);
					n->kind = VAR_RESET_ALL;
					$$ = n;
				}
		;


reset_rest:
			generic_reset							{ $$ = $1; }
			| TIME ZONE
				{
					PGVariableSetStmt *n = makeNode(PGVariableSetStmt);
					n->kind = VAR_RESET;
					n->name = (char*) "timezone";
					$$ = n;
				}
			| TRANSACTION ISOLATION LEVEL
				{
					PGVariableSetStmt *n = makeNode(PGVariableSetStmt);
					n->kind = VAR_RESET;
					n->name = (char*) "transaction_isolation";
					$$ = n;
				}
		;
#line 1 "third_party/libpg_query/grammar/statements/variable_set.y"
/*****************************************************************************
 *
 * Set PG internal variable
 *	  SET name TO 'var_value'
 * Include SQL syntax (thomas 1997-10-22):
 *	  SET TIME ZONE 'var_value'
 *
 *****************************************************************************/
VariableSetStmt:
			SET set_rest
				{
					PGVariableSetStmt *n = $2;
					n->scope = VAR_SET_SCOPE_DEFAULT;
					$$ = (PGNode *) n;
				}
			| SET LOCAL set_rest
				{
					PGVariableSetStmt *n = $3;
					n->scope = VAR_SET_SCOPE_LOCAL;
					$$ = (PGNode *) n;
				}
			| SET SESSION set_rest
				{
					PGVariableSetStmt *n = $3;
					n->scope = VAR_SET_SCOPE_SESSION;
					$$ = (PGNode *) n;
				}
			| SET GLOBAL set_rest
				{
					PGVariableSetStmt *n = $3;
					n->scope = VAR_SET_SCOPE_GLOBAL;
					$$ = (PGNode *) n;
				}
		;


set_rest:	/* Generic SET syntaxes: */
			generic_set 						{$$ = $1;}
			| var_name FROM CURRENT_P
				{
					PGVariableSetStmt *n = makeNode(PGVariableSetStmt);
					n->kind = VAR_SET_CURRENT;
					n->name = $1;
					$$ = n;
				}
			/* Special syntaxes mandated by SQL standard: */
			| TIME ZONE zone_value
				{
					PGVariableSetStmt *n = makeNode(PGVariableSetStmt);
					n->kind = VAR_SET_VALUE;
					n->name = (char*) "timezone";
					if ($3 != NULL)
						n->args = list_make1($3);
					else
						n->kind = VAR_SET_DEFAULT;
					$$ = n;
				}
			| SCHEMA Sconst
				{
					PGVariableSetStmt *n = makeNode(PGVariableSetStmt);
					n->kind = VAR_SET_VALUE;
					n->name = (char*) "search_path";
					n->args = list_make1(makeStringConst($2, @2));
					$$ = n;
				}
		;


generic_set:
			var_name TO var_list
				{
					PGVariableSetStmt *n = makeNode(PGVariableSetStmt);
					n->kind = VAR_SET_VALUE;
					n->name = $1;
					n->args = $3;
					$$ = n;
				}
			| var_name '=' var_list
				{
					PGVariableSetStmt *n = makeNode(PGVariableSetStmt);
					n->kind = VAR_SET_VALUE;
					n->name = $1;
					n->args = $3;
					$$ = n;
				}
			| var_name TO DEFAULT
				{
					PGVariableSetStmt *n = makeNode(PGVariableSetStmt);
					n->kind = VAR_SET_DEFAULT;
					n->name = $1;
					$$ = n;
				}
			| var_name '=' DEFAULT
				{
					PGVariableSetStmt *n = makeNode(PGVariableSetStmt);
					n->kind = VAR_SET_DEFAULT;
					n->name = $1;
					$$ = n;
				}
		;


var_value:	opt_boolean_or_string
				{ $$ = makeStringConst($1, @1); }
			| NumericOnly
				{ $$ = makeAConst($1, @1); }
		;


zone_value:
			Sconst
				{
					$$ = makeStringConst($1, @1);
				}
			| IDENT
				{
					$$ = makeStringConst($1, @1);
				}
			| ConstInterval Sconst opt_interval
				{
					PGTypeName *t = $1;
					if ($3 != NIL)
					{
						PGAConst *n = (PGAConst *) linitial($3);
						if ((n->val.val.ival & ~(INTERVAL_MASK(HOUR) | INTERVAL_MASK(MINUTE))) != 0)
							ereport(ERROR,
									(errcode(PG_ERRCODE_SYNTAX_ERROR),
									 errmsg("time zone interval must be HOUR or HOUR TO MINUTE"),
									 parser_errposition(@3)));
					}
					t->typmods = $3;
					$$ = makeStringConstCast($2, @2, t);
				}
			| ConstInterval '(' Iconst ')' Sconst
				{
					PGTypeName *t = $1;
					t->typmods = list_make2(makeIntConst(INTERVAL_FULL_RANGE, -1),
											makeIntConst($3, @3));
					$$ = makeStringConstCast($5, @5, t);
				}
			| NumericOnly							{ $$ = makeAConst($1, @1); }
			| DEFAULT								{ $$ = NULL; }
			| LOCAL									{ $$ = NULL; }
		;


var_list:	var_value								{ $$ = list_make1($1); }
			| var_list ',' var_value				{ $$ = lappend($1, $3); }
		;
#line 1 "third_party/libpg_query/grammar/statements/variable_show.y"
/* allows SET or RESET without LOCAL */
VariableShowStmt:
			show_or_describe SelectStmt {
				PGVariableShowSelectStmt *n = makeNode(PGVariableShowSelectStmt);
				n->stmt = $2;
				n->name = (char*) "select";
				n->is_summary = 0;
				$$ = (PGNode *) n;
			}
		 | SUMMARIZE SelectStmt {
				PGVariableShowSelectStmt *n = makeNode(PGVariableShowSelectStmt);
				n->stmt = $2;
				n->name = (char*) "select";
				n->is_summary = 1;
				$$ = (PGNode *) n;
			}
		 | SUMMARIZE table_id
			{
				PGVariableShowStmt *n = makeNode(PGVariableShowStmt);
				n->name = $2;
				n->is_summary = 1;
				$$ = (PGNode *) n;
			}
		 | show_or_describe table_id
			{
				PGVariableShowStmt *n = makeNode(PGVariableShowStmt);
				n->name = $2;
				n->is_summary = 0;
				$$ = (PGNode *) n;
			}
		| show_or_describe TIME ZONE
			{
				PGVariableShowStmt *n = makeNode(PGVariableShowStmt);
				n->name = (char*) "timezone";
				n->is_summary = 0;
				$$ = (PGNode *) n;
			}
		| show_or_describe TRANSACTION ISOLATION LEVEL
			{
				PGVariableShowStmt *n = makeNode(PGVariableShowStmt);
				n->name = (char*) "transaction_isolation";
				n->is_summary = 0;
				$$ = (PGNode *) n;
			}
		| show_or_describe ALL opt_tables
			{
				PGVariableShowStmt *n = makeNode(PGVariableShowStmt);
				n->name = (char*) "__show_tables_expanded";
				n->is_summary = 0;
				$$ = (PGNode *) n;
			}
		| show_or_describe
			{
				PGVariableShowStmt *n = makeNode(PGVariableShowStmt);
				n->name = (char*) "__show_tables_expanded";
				n->is_summary = 0;
				$$ = (PGNode *) n;
			}
		;

show_or_describe: SHOW | DESCRIBE

opt_tables: TABLES | /* empty */

var_name:	ColId								{ $$ = $1; }
			| var_name '.' ColId
				{ $$ = psprintf("%s.%s", $1, $3); }
		;

table_id:	ColId								{ $$ = psprintf("\"%s\"", $1); }
			| table_id '.' ColId
				{ $$ = psprintf("%s.\"%s\"", $1, $3); }
		;
#line 1 "third_party/libpg_query/grammar/statements/view.y"
/*****************************************************************************
 *
 *	QUERY:
 *		CREATE [ OR REPLACE ] [ TEMP ] VIEW <viewname> '('target-list ')'
 *			AS <query> [ WITH [ CASCADED | LOCAL ] CHECK OPTION ]
 *
 *****************************************************************************/
ViewStmt: CREATE_P OptTemp VIEW qualified_name opt_column_list opt_reloptions
				AS SelectStmt opt_check_option
				{
					PGViewStmt *n = makeNode(PGViewStmt);
					n->view = $4;
					n->view->relpersistence = $2;
					n->aliases = $5;
					n->query = $8;
					n->onconflict = PG_ERROR_ON_CONFLICT;
					n->options = $6;
					n->withCheckOption = $9;
					$$ = (PGNode *) n;
				}
		| CREATE_P OptTemp VIEW IF_P NOT EXISTS qualified_name opt_column_list opt_reloptions
				AS SelectStmt opt_check_option
				{
					PGViewStmt *n = makeNode(PGViewStmt);
					n->view = $7;
					n->view->relpersistence = $2;
					n->aliases = $8;
					n->query = $11;
					n->onconflict = PG_IGNORE_ON_CONFLICT;
					n->options = $9;
					n->withCheckOption = $12;
					$$ = (PGNode *) n;
				}
		| CREATE_P OR REPLACE OptTemp VIEW qualified_name opt_column_list opt_reloptions
				AS SelectStmt opt_check_option
				{
					PGViewStmt *n = makeNode(PGViewStmt);
					n->view = $6;
					n->view->relpersistence = $4;
					n->aliases = $7;
					n->query = $10;
					n->onconflict = PG_REPLACE_ON_CONFLICT;
					n->options = $8;
					n->withCheckOption = $11;
					$$ = (PGNode *) n;
				}
		| CREATE_P OptTemp RECURSIVE VIEW qualified_name '(' columnList ')' opt_reloptions
				AS SelectStmt opt_check_option
				{
					PGViewStmt *n = makeNode(PGViewStmt);
					n->view = $5;
					n->view->relpersistence = $2;
					n->aliases = $7;
					n->query = makeRecursiveViewSelect(n->view->relname, n->aliases, $11);
					n->onconflict = PG_ERROR_ON_CONFLICT;
					n->options = $9;
					n->withCheckOption = $12;
					if (n->withCheckOption != PG_NO_CHECK_OPTION)
						ereport(ERROR,
								(errcode(PG_ERRCODE_FEATURE_NOT_SUPPORTED),
								 errmsg("WITH CHECK OPTION not supported on recursive views"),
								 parser_errposition(@12)));
					$$ = (PGNode *) n;
				}
		| CREATE_P OR REPLACE OptTemp RECURSIVE VIEW qualified_name '(' columnList ')' opt_reloptions
				AS SelectStmt opt_check_option
				{
					PGViewStmt *n = makeNode(PGViewStmt);
					n->view = $7;
					n->view->relpersistence = $4;
					n->aliases = $9;
					n->query = makeRecursiveViewSelect(n->view->relname, n->aliases, $13);
					n->onconflict = PG_REPLACE_ON_CONFLICT;
					n->options = $11;
					n->withCheckOption = $14;
					if (n->withCheckOption != PG_NO_CHECK_OPTION)
						ereport(ERROR,
								(errcode(PG_ERRCODE_FEATURE_NOT_SUPPORTED),
								 errmsg("WITH CHECK OPTION not supported on recursive views"),
								 parser_errposition(@14)));
					$$ = (PGNode *) n;
				}
		;


opt_check_option:
		WITH CHECK_P OPTION				{ $$ = CASCADED_CHECK_OPTION; }
		| WITH CASCADED CHECK_P OPTION	{ $$ = CASCADED_CHECK_OPTION; }
		| WITH LOCAL CHECK_P OPTION		{ $$ = PG_LOCAL_CHECK_OPTION; }
		| /* EMPTY */					{ $$ = PG_NO_CHECK_OPTION; }
		;


unreserved_keyword: ABORT_P | ABSOLUTE_P | ACCESS | ACTION | ADD_P | ADMIN | AFTER | AGGREGATE | ALSO | ALTER | ALWAYS | ASSERTION | ASSIGNMENT | AT | ATTACH | ATTRIBUTE | BACKWARD | BEFORE | BEGIN_P | BY | CACHE | CALL_P | CALLED | CASCADE | CASCADED | CATALOG_P | CHAIN | CHARACTERISTICS | CHECKPOINT | CLASS | CLOSE | CLUSTER | COMMENT | COMMENTS | COMMIT | COMMITTED | COMPRESSION | CONFIGURATION | CONFLICT | CONNECTION | CONSTRAINTS | CONTENT_P | CONTINUE_P | CONVERSION_P | COPY | COST | CSV | CUBE | CURRENT_P | CURSOR | CYCLE | DATA_P | DATABASE | DAY_P | DAYS_P | DEALLOCATE | DECLARE | DEFAULTS | DEFERRED | DEFINER | DELETE_P | DELIMITER | DELIMITERS | DEPENDS | DESCRIBE | DETACH | DICTIONARY | DISABLE_P | DISCARD | DOCUMENT_P | DOMAIN_P | DOUBLE_P | DROP | EACH | ENABLE_P | ENCODING | ENCRYPTED | ENUM_P | ESCAPE | EVENT | EXCLUDE | EXCLUDING | EXCLUSIVE | EXECUTE | EXPLAIN | EXPORT_P | EXPORT_STATE | EXTENSION | EXTERNAL | FAMILY | FILTER | FIRST_P | FOLLOWING | FORCE | FORWARD | FUNCTION | FUNCTIONS | GLOBAL | GRANTED | HANDLER | HEADER_P | HOLD | HOUR_P | HOURS_P | IDENTITY_P | IF_P | IGNORE_P | IMMEDIATE | IMMUTABLE | IMPLICIT_P | IMPORT_P | INCLUDE_P | INCLUDING | INCREMENT | INDEX | INDEXES | INHERIT | INHERITS | INLINE_P | INPUT_P | INSENSITIVE | INSERT | INSTALL | INSTEAD | INVOKER | ISOLATION | JSON | KEY | LABEL | LANGUAGE | LARGE_P | LAST_P | LEAKPROOF | LEVEL | LISTEN | LOAD | LOCAL | LOCATION | LOCK_P | LOCKED | LOGGED | MACRO | MAPPING | MATCH | MATERIALIZED | MAXVALUE | METHOD | MICROSECOND_P | MICROSECONDS_P | MILLISECOND_P | MILLISECONDS_P | MINUTE_P | MINUTES_P | MINVALUE | MODE | MONTH_P | MONTHS_P | MOVE | NAME_P | NAMES | NEW | NEXT | NO | NOTHING | NOTIFY | NOWAIT | NULLS_P | OBJECT_P | OF | OFF | OIDS | OLD | OPERATOR | OPTION | OPTIONS | ORDINALITY | OVER | OVERRIDING | OWNED | OWNER | PARALLEL | PARSER | PARTIAL | PARTITION | PASSING | PASSWORD | PERCENT | PLANS | POLICY | PRAGMA_P | PRECEDING | PREPARE | PREPARED | PRESERVE | PRIOR | PRIVILEGES | PROCEDURAL | PROCEDURE | PROGRAM | PUBLICATION | QUOTE | RANGE | READ_P | REASSIGN | RECHECK | RECURSIVE | REF | REFERENCING | REFRESH | REINDEX | RELATIVE_P | RELEASE | RENAME | REPEATABLE | REPLACE | REPLICA | RESET | RESPECT_P | RESTART | RESTRICT | RETURNS | REVOKE | ROLE | ROLLBACK | ROLLUP | ROWS | RULE | SAMPLE | SAVEPOINT | SCHEMA | SCHEMAS | SCROLL | SEARCH | SECOND_P | SECONDS_P | SECURITY | SEQUENCE | SEQUENCES | SERIALIZABLE | SERVER | SESSION | SET | SETS | SHARE | SHOW | SIMPLE | SKIP | SNAPSHOT | SQL_P | STABLE | STANDALONE_P | START | STATEMENT | STATISTICS | STDIN | STDOUT | STORAGE | STORED | STRICT_P | STRIP_P | SUBSCRIPTION | SUMMARIZE | SYSID | SYSTEM_P | TABLES | TABLESPACE | TEMP | TEMPLATE | TEMPORARY | TEXT_P | TRANSACTION | TRANSFORM | TRIGGER | TRUNCATE | TRUSTED | TYPE_P | TYPES_P | UNBOUNDED | UNCOMMITTED | UNENCRYPTED | UNKNOWN | UNLISTEN | UNLOGGED | UNTIL | UPDATE | USE_P | USER | VACUUM | VALID | VALIDATE | VALIDATOR | VALUE_P | VARYING | VERSION_P | VIEW | VIEWS | VIRTUAL | VOLATILE | WHITESPACE_P | WITHIN | WITHOUT | WORK | WRAPPER | WRITE_P | XML_P | YEAR_P | YEARS_P | YES_P | ZONE
col_name_keyword: BETWEEN | BIGINT | BIT | BOOLEAN_P | CHAR_P | CHARACTER | COALESCE | COLUMNS | DEC | DECIMAL_P | EXISTS | EXTRACT | FLOAT_P | GENERATED | GROUPING | GROUPING_ID | INOUT | INT_P | INTEGER | INTERVAL | MAP | NATIONAL | NCHAR | NONE | NULLIF | NUMERIC | OUT_P | OVERLAY | POSITION | PRECISION | REAL | ROW | SETOF | SMALLINT | STRUCT | SUBSTRING | TIME | TIMESTAMP | TREAT | TRIM | TRY_CAST | VALUES | VARCHAR | XMLATTRIBUTES | XMLCONCAT | XMLELEMENT | XMLEXISTS | XMLFOREST | XMLNAMESPACES | XMLPARSE | XMLPI | XMLROOT | XMLSERIALIZE | XMLTABLE
func_name_keyword: ASOF | AUTHORIZATION | BINARY | COLLATION | CONCURRENTLY | CROSS | FREEZE | FULL | GENERATED | GLOB | ILIKE | INNER_P | IS | ISNULL | JOIN | LEFT | LIKE | MAP | NATURAL | NOTNULL | OUTER_P | OVERLAPS | POSITIONAL | RIGHT | SIMILAR | STRUCT | TABLESAMPLE | VERBOSE
type_name_keyword: ANTI | ASOF | AUTHORIZATION | BINARY | COLLATION | COLUMNS | CONCURRENTLY | CROSS | FREEZE | FULL | GLOB | ILIKE | INNER_P | IS | ISNULL | JOIN | LEFT | LIKE | NATURAL | NOTNULL | OUTER_P | OVERLAPS | POSITIONAL | RIGHT | SEMI | SIMILAR | TABLESAMPLE | TRY_CAST | VERBOSE
other_keyword: ANTI | ASOF | AUTHORIZATION | BETWEEN | BIGINT | BINARY | BIT | BOOLEAN_P | CHARACTER | CHAR_P | COALESCE | COLLATION | COLUMNS | CONCURRENTLY | CROSS | DEC | DECIMAL_P | EXISTS | EXTRACT | FLOAT_P | FREEZE | FULL | GENERATED | GLOB | GROUPING | GROUPING_ID | ILIKE | INNER_P | INOUT | INTEGER | INTERVAL | INT_P | IS | ISNULL | JOIN | LEFT | LIKE | MAP | NATIONAL | NATURAL | NCHAR | NONE | NOTNULL | NULLIF | NUMERIC | OUTER_P | OUT_P | OVERLAPS | OVERLAY | POSITION | POSITIONAL | PRECISION | REAL | RIGHT | ROW | SEMI | SETOF | SIMILAR | SMALLINT | STRUCT | SUBSTRING | TABLESAMPLE | TIME | TIMESTAMP | TREAT | TRIM | TRY_CAST | VALUES | VARCHAR | VERBOSE | XMLATTRIBUTES | XMLCONCAT | XMLELEMENT | XMLEXISTS | XMLFOREST | XMLNAMESPACES | XMLPARSE | XMLPI | XMLROOT | XMLSERIALIZE | XMLTABLE
type_func_name_keyword: ANTI | ASOF | AUTHORIZATION | BINARY | COLLATION | COLUMNS | CONCURRENTLY | CROSS | FREEZE | FULL | GENERATED | GLOB | ILIKE | INNER_P | IS | ISNULL | JOIN | LEFT | LIKE | MAP | NATURAL | NOTNULL | OUTER_P | OVERLAPS | POSITIONAL | RIGHT | SEMI | SIMILAR | STRUCT | TABLESAMPLE | TRY_CAST | VERBOSE
reserved_keyword: ALL | ANALYSE | ANALYZE | AND | ANY | ARRAY | AS | ASC_P | ASYMMETRIC | BOTH | CASE | CAST | CHECK_P | COLLATE | COLUMN | CONSTRAINT | CREATE_P | DEFAULT | DEFERRABLE | DESC_P | DISTINCT | DO | ELSE | END_P | EXCEPT | FALSE_P | FETCH | FOR | FOREIGN | FROM | GRANT | GROUP_P | HAVING | IN_P | INITIALLY | INTERSECT | INTO | LATERAL_P | LEADING | LIMIT | NOT | NULL_P | OFFSET | ON | ONLY | OR | ORDER | PIVOT | PIVOT_LONGER | PIVOT_WIDER | PLACING | PRIMARY | QUALIFY | REFERENCES | RETURNING | SELECT | SOME | SYMMETRIC | TABLE | THEN | TO | TRAILING | TRUE_P | UNION | UNIQUE | UNPIVOT | USING | VARIADIC | WHEN | WHERE | WINDOW | WITH


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

static PGRawStmt *
makeRawStmt(PGNode *stmt, int stmt_location)
{
	PGRawStmt    *rs = makeNode(PGRawStmt);

	rs->stmt = stmt;
	rs->stmt_location = stmt_location;
	rs->stmt_len = 0;			/* might get changed later */
	return rs;
}

/* Adjust a PGRawStmt to reflect that it doesn't run to the end of the string */
static void
updateRawStmtEnd(PGRawStmt *rs, int end_location)
{
	/*
	 * If we already set the length, don't change it.  This is for situations
	 * like "select foo ;; select bar" where the same statement will be last
	 * in the string for more than one semicolon.
	 */
	if (rs->stmt_len > 0)
		return;

	/* OK, update length of PGRawStmt */
	rs->stmt_len = end_location - rs->stmt_location;
}

static PGNode *
makeColumnRef(char *colname, PGList *indirection,
			  int location, core_yyscan_t yyscanner)
{
	/*
	 * Generate a PGColumnRef node, with an PGAIndirection node added if there
	 * is any subscripting in the specified indirection list.  However,
	 * any field selection at the start of the indirection list must be
	 * transposed into the "fields" part of the PGColumnRef node.
	 */
	PGColumnRef  *c = makeNode(PGColumnRef);
	int		nfields = 0;
	PGListCell *l;

	c->location = location;
	foreach(l, indirection)
	{
		if (IsA(lfirst(l), PGAIndices))
		{
			PGAIndirection *i = makeNode(PGAIndirection);

			if (nfields == 0)
			{
				/* easy case - all indirection goes to PGAIndirection */
				c->fields = list_make1(makeString(colname));
				i->indirection = check_indirection(indirection, yyscanner);
			}
			else
			{
				/* got to split the list in two */
				i->indirection = check_indirection(list_copy_tail(indirection,
																  nfields),
												   yyscanner);
				indirection = list_truncate(indirection, nfields);
				c->fields = lcons(makeString(colname), indirection);
			}
			i->arg = (PGNode *) c;
			return (PGNode *) i;
		}
		else if (IsA(lfirst(l), PGAStar))
		{
			/* We only allow '*' at the end of a PGColumnRef */
			if (lnext(l) != NULL)
				parser_yyerror("improper use of \"*\"");
		}
		nfields++;
	}
	/* No subscripting, so all indirection gets added to field list */
	c->fields = lcons(makeString(colname), indirection);
	return (PGNode *) c;
}

static PGNode *
makeTypeCast(PGNode *arg, PGTypeName *tpname, int trycast, int location)
{
	PGTypeCast *n = makeNode(PGTypeCast);
	n->arg = arg;
	n->typeName = tpname;
	n->tryCast = trycast;
	n->location = location;
	return (PGNode *) n;
}

static PGNode *
makeStringConst(char *str, int location)
{
	PGAConst *n = makeNode(PGAConst);

	n->val.type = T_PGString;
	n->val.val.str = str;
	n->location = location;

	return (PGNode *)n;
}

static PGNode *
makeStringConstCast(char *str, int location, PGTypeName *tpname)
{
	PGNode *s = makeStringConst(str, location);

	return makeTypeCast(s, tpname, 0, -1);
}

static PGNode *
makeIntervalNode(char *str, int location, PGList *typmods) {
	PGIntervalConstant *n = makeNode(PGIntervalConstant);

	n->val_type = T_PGString;
	n->sval = str;
	n->location = location;
	n->typmods = typmods;

	return (PGNode *)n;

}

static PGNode *
makeIntervalNode(int val, int location, PGList *typmods) {
	PGIntervalConstant *n = makeNode(PGIntervalConstant);

	n->val_type = T_PGInteger;
	n->ival = val;
	n->location = location;
	n->typmods = typmods;

	return (PGNode *)n;
}

static PGNode *
makeIntervalNode(PGNode *arg, int location, PGList *typmods) {
	PGIntervalConstant *n = makeNode(PGIntervalConstant);

	n->val_type = T_PGAExpr;
	n->eval = arg;
	n->location = location;
	n->typmods = typmods;

	return (PGNode *)n;
}

static PGNode *
makeSampleSize(PGValue *sample_size, bool is_percentage) {
	PGSampleSize *n = makeNode(PGSampleSize);

	n->sample_size = *sample_size;
	n->is_percentage = is_percentage;

	return (PGNode *)n;
}

static PGNode *
makeSampleOptions(PGNode *sample_size, char *method, int *seed, int location) {
	PGSampleOptions *n = makeNode(PGSampleOptions);

	n->sample_size = sample_size;
	n->method = method;
	if (seed) {
		n->has_seed = true;
		n->seed = *seed;
	}
	n->location = location;

	return (PGNode *)n;
}

/* makeLimitPercent()
 * Make limit percent node
 */
static PGNode *
makeLimitPercent(PGNode *limit_percent) {
	PGLimitPercent *n = makeNode(PGLimitPercent);

	n->limit_percent = limit_percent;

	return (PGNode *)n;
}

static PGNode *
makeIntConst(int val, int location)
{
	PGAConst *n = makeNode(PGAConst);

	n->val.type = T_PGInteger;
	n->val.val.ival = val;
	n->location = location;

	return (PGNode *)n;
}

static PGNode *
makeFloatConst(char *str, int location)
{
	PGAConst *n = makeNode(PGAConst);

	n->val.type = T_PGFloat;
	n->val.val.str = str;
	n->location = location;

	return (PGNode *)n;
}

static PGNode *
makeBitStringConst(char *str, int location)
{
	PGAConst *n = makeNode(PGAConst);

	n->val.type = T_PGBitString;
	n->val.val.str = str;
	n->location = location;

	return (PGNode *)n;
}

static PGNode *
makeNullAConst(int location)
{
	PGAConst *n = makeNode(PGAConst);

	n->val.type = T_PGNull;
	n->location = location;

	return (PGNode *)n;
}

static PGNode *
makeAConst(PGValue *v, int location)
{
	PGNode *n;

	switch (v->type)
	{
		case T_PGFloat:
			n = makeFloatConst(v->val.str, location);
			break;

		case T_PGInteger:
			n = makeIntConst(v->val.ival, location);
			break;

		case T_PGString:
		default:
			n = makeStringConst(v->val.str, location);
			break;
	}

	return n;
}

/* makeBoolAConst()
 * Create an PGAConst string node and put it inside a boolean cast.
 */
static PGNode *
makeBoolAConst(bool state, int location)
{
	PGAConst *n = makeNode(PGAConst);

	n->val.type = T_PGString;
	n->val.val.str = (state ? (char*) "t" : (char*) "f");
	n->location = location;

	return makeTypeCast((PGNode *)n, SystemTypeName("bool"), 0, -1);
}

/* check_qualified_name --- check the result of qualified_name production
 *
 * It's easiest to let the grammar production for qualified_name allow
 * subscripts and '*', which we then must reject here.
 */
static void
check_qualified_name(PGList *names, core_yyscan_t yyscanner)
{
	PGListCell   *i;

	foreach(i, names)
	{
		if (!IsA(lfirst(i), PGString))
			parser_yyerror("syntax error");
	}
}

/* check_func_name --- check the result of func_name production
 *
 * It's easiest to let the grammar production for func_name allow subscripts
 * and '*', which we then must reject here.
 */
static PGList *
check_func_name(PGList *names, core_yyscan_t yyscanner)
{
	PGListCell   *i;

	foreach(i, names)
	{
		if (!IsA(lfirst(i), PGString))
			parser_yyerror("syntax error");
	}
	return names;
}

/* check_indirection --- check the result of indirection production
 *
 * We only allow '*' at the end of the list, but it's hard to enforce that
 * in the grammar, so do it here.
 */
static PGList *
check_indirection(PGList *indirection, core_yyscan_t yyscanner)
{
	PGListCell *l;

	foreach(l, indirection)
	{
		if (IsA(lfirst(l), PGAStar))
		{
			if (lnext(l) != NULL)
				parser_yyerror("improper use of \"*\"");
		}
	}
	return indirection;
}

/* makeParamRef
 * Creates a new PGParamRef node
 */
static PGNode* makeParamRef(int number, int location)
{
	PGParamRef *p = makeNode(PGParamRef);
	p->number = number;
	p->location = location;
	p->name = NULL;
	return (PGNode *) p;
}

/* makeNamedParamRef
 * Creates a new PGParamRef node
 */
static PGNode* makeNamedParamRef(char *name, int location)
{
	PGParamRef *p = (PGParamRef *)makeParamRef(0, location);
	p->name = name;
	return (PGNode *) p;
}


/* insertSelectOptions()
 * Insert ORDER BY, etc into an already-constructed SelectStmt.
 *
 * This routine is just to avoid duplicating code in PGSelectStmt productions.
 */
static void
insertSelectOptions(PGSelectStmt *stmt,
					PGList *sortClause, PGList *lockingClause,
					PGNode *limitOffset, PGNode *limitCount,
					PGWithClause *withClause,
					core_yyscan_t yyscanner)
{
	Assert(IsA(stmt, PGSelectStmt));

	/*
	 * Tests here are to reject constructs like
	 *	(SELECT foo ORDER BY bar) ORDER BY baz
	 */
	if (sortClause)
	{
		if (stmt->sortClause)
			ereport(ERROR,
					(errcode(PG_ERRCODE_SYNTAX_ERROR),
					 errmsg("multiple ORDER BY clauses not allowed"),
					 parser_errposition(exprLocation((PGNode *) sortClause))));
		stmt->sortClause = sortClause;
	}
	/* We can handle multiple locking clauses, though */
	stmt->lockingClause = list_concat(stmt->lockingClause, lockingClause);
	if (limitOffset)
	{
		if (stmt->limitOffset)
			ereport(ERROR,
					(errcode(PG_ERRCODE_SYNTAX_ERROR),
					 errmsg("multiple OFFSET clauses not allowed"),
					 parser_errposition(exprLocation(limitOffset))));
		stmt->limitOffset = limitOffset;
	}
	if (limitCount)
	{
		if (stmt->limitCount)
			ereport(ERROR,
					(errcode(PG_ERRCODE_SYNTAX_ERROR),
					 errmsg("multiple LIMIT clauses not allowed"),
					 parser_errposition(exprLocation(limitCount))));
		stmt->limitCount = limitCount;
	}
	if (withClause)
	{
		if (stmt->withClause)
			ereport(ERROR,
					(errcode(PG_ERRCODE_SYNTAX_ERROR),
					 errmsg("multiple WITH clauses not allowed"),
					 parser_errposition(exprLocation((PGNode *) withClause))));
		stmt->withClause = withClause;
	}
}

static PGNode *
makeSetOp(PGSetOperation op, bool all, PGNode *larg, PGNode *rarg)
{
	PGSelectStmt *n = makeNode(PGSelectStmt);

	n->op = op;
	n->all = all;
	n->larg = (PGSelectStmt *) larg;
	n->rarg = (PGSelectStmt *) rarg;
	return (PGNode *) n;
}

/* SystemFuncName()
 * Build a properly-qualified reference to a built-in function.
 */
PGList *
SystemFuncName(const char *name)
{
	return list_make2(makeString(DEFAULT_SCHEMA), makeString(name));
}

/* SystemTypeName()
 * Build a properly-qualified reference to a built-in type.
 *
 * typmod is defaulted, but may be changed afterwards by caller.
 * Likewise for the location.
 */
PGTypeName *
SystemTypeName(const char *name)
{
	return makeTypeNameFromNameList(list_make2(makeString(DEFAULT_SCHEMA),
											   makeString(name)));
}

/* doNegate()
 * Handle negation of a numeric constant.
 *
 * Formerly, we did this here because the optimizer couldn't cope with
 * indexquals that looked like "var = -4" --- it wants "var = const"
 * and a unary minus operator applied to a constant didn't qualify.
 * As of Postgres 7.0, that problem doesn't exist anymore because there
 * is a constant-subexpression simplifier in the optimizer.  However,
 * there's still a good reason for doing this here, which is that we can
 * postpone committing to a particular internal representation for simple
 * negative constants.	It's better to leave "-123.456" in string form
 * until we know what the desired type is.
 */
static PGNode *
doNegate(PGNode *n, int location)
{
	if (IsA(n, PGAConst))
	{
		PGAConst *con = (PGAConst *)n;

		/* report the constant's location as that of the '-' sign */
		con->location = location;

		if (con->val.type == T_PGInteger)
		{
			con->val.val.ival = -con->val.val.ival;
			return n;
		}
		if (con->val.type == T_PGFloat)
		{
			doNegateFloat(&con->val);
			return n;
		}
	}

	return (PGNode *) makeSimpleAExpr(PG_AEXPR_OP, "-", NULL, n, location);
}

static void
doNegateFloat(PGValue *v)
{
	char   *oldval = v->val.str;

	Assert(IsA(v, PGFloat));
	if (*oldval == '+')
		oldval++;
	if (*oldval == '-')
		v->val.str = oldval+1;	/* just strip the '-' */
	else
		v->val.str = psprintf("-%s", oldval);
}

static PGNode *
makeAndExpr(PGNode *lexpr, PGNode *rexpr, int location)
{
	PGNode	   *lexp = lexpr;

	/* Look through AEXPR_PAREN nodes so they don't affect flattening */
	while (IsA(lexp, PGAExpr) &&
		   ((PGAExpr *) lexp)->kind == AEXPR_PAREN)
		lexp = ((PGAExpr *) lexp)->lexpr;
	/* Flatten "a AND b AND c ..." to a single PGBoolExpr on sight */
	if (IsA(lexp, PGBoolExpr))
	{
		PGBoolExpr *blexpr = (PGBoolExpr *) lexp;

		if (blexpr->boolop == PG_AND_EXPR)
		{
			blexpr->args = lappend(blexpr->args, rexpr);
			return (PGNode *) blexpr;
		}
	}
	return (PGNode *) makeBoolExpr(PG_AND_EXPR, list_make2(lexpr, rexpr), location);
}

static PGNode *
makeOrExpr(PGNode *lexpr, PGNode *rexpr, int location)
{
	PGNode	   *lexp = lexpr;

	/* Look through AEXPR_PAREN nodes so they don't affect flattening */
	while (IsA(lexp, PGAExpr) &&
		   ((PGAExpr *) lexp)->kind == AEXPR_PAREN)
		lexp = ((PGAExpr *) lexp)->lexpr;
	/* Flatten "a OR b OR c ..." to a single PGBoolExpr on sight */
	if (IsA(lexp, PGBoolExpr))
	{
		PGBoolExpr *blexpr = (PGBoolExpr *) lexp;

		if (blexpr->boolop == PG_OR_EXPR)
		{
			blexpr->args = lappend(blexpr->args, rexpr);
			return (PGNode *) blexpr;
		}
	}
	return (PGNode *) makeBoolExpr(PG_OR_EXPR, list_make2(lexpr, rexpr), location);
}

static PGNode *
makeNotExpr(PGNode *expr, int location)
{
	return (PGNode *) makeBoolExpr(PG_NOT_EXPR, list_make1(expr), location);
}

/* Separate PGConstraint nodes from COLLATE clauses in a */
static void
SplitColQualList(PGList *qualList,
				 PGList **constraintList, PGCollateClause **collClause,
				 core_yyscan_t yyscanner)
{
	PGListCell   *cell;
	PGListCell   *prev;
	PGListCell   *next;

	*collClause = NULL;
	prev = NULL;
	for (cell = list_head(qualList); cell; cell = next)
	{
		PGNode   *n = (PGNode *) lfirst(cell);

		next = lnext(cell);
		if (IsA(n, PGConstraint))
		{
			/* keep it in list */
			prev = cell;
			continue;
		}
		if (IsA(n, PGCollateClause))
		{
			PGCollateClause *c = (PGCollateClause *) n;

			if (*collClause)
				ereport(ERROR,
						(errcode(PG_ERRCODE_SYNTAX_ERROR),
						 errmsg("multiple COLLATE clauses not allowed"),
						 parser_errposition(c->location)));
			*collClause = c;
		}
		else
			elog(ERROR, "unexpected node type %d", (int) n->type);
		/* remove non-Constraint nodes from qualList */
		qualList = list_delete_cell(qualList, cell, prev);
	}
	*constraintList = qualList;
}

/*
 * Process result of ConstraintAttributeSpec, and set appropriate bool flags
 * in the output command node.  Pass NULL for any flags the particular
 * command doesn't support.
 */
static void
processCASbits(int cas_bits, int location, const char *constrType,
			   bool *deferrable, bool *initdeferred, bool *not_valid,
			   bool *no_inherit, core_yyscan_t yyscanner)
{
	/* defaults */
	if (deferrable)
		*deferrable = false;
	if (initdeferred)
		*initdeferred = false;
	if (not_valid)
		*not_valid = false;

	if (cas_bits & (CAS_DEFERRABLE | CAS_INITIALLY_DEFERRED))
	{
		if (deferrable)
			*deferrable = true;
		else
			ereport(ERROR,
					(errcode(PG_ERRCODE_FEATURE_NOT_SUPPORTED),
					 /* translator: %s is CHECK, UNIQUE, or similar */
					 errmsg("%s constraints cannot be marked DEFERRABLE",
							constrType),
					 parser_errposition(location)));
	}

	if (cas_bits & CAS_INITIALLY_DEFERRED)
	{
		if (initdeferred)
			*initdeferred = true;
		else
			ereport(ERROR,
					(errcode(PG_ERRCODE_FEATURE_NOT_SUPPORTED),
					 /* translator: %s is CHECK, UNIQUE, or similar */
					 errmsg("%s constraints cannot be marked DEFERRABLE",
							constrType),
					 parser_errposition(location)));
	}

	if (cas_bits & CAS_NOT_VALID)
	{
		if (not_valid)
			*not_valid = true;
		else
			ereport(ERROR,
					(errcode(PG_ERRCODE_FEATURE_NOT_SUPPORTED),
					 /* translator: %s is CHECK, UNIQUE, or similar */
					 errmsg("%s constraints cannot be marked NOT VALID",
							constrType),
					 parser_errposition(location)));
	}

	if (cas_bits & CAS_NO_INHERIT)
	{
		if (no_inherit)
			*no_inherit = true;
		else
			ereport(ERROR,
					(errcode(PG_ERRCODE_FEATURE_NOT_SUPPORTED),
					 /* translator: %s is CHECK, UNIQUE, or similar */
					 errmsg("%s constraints cannot be marked NO INHERIT",
							constrType),
					 parser_errposition(location)));
	}
}

/*----------
 * Recursive view transformation
 *
 * Convert
 *
 *     CREATE RECURSIVE VIEW relname (aliases) AS query
 *
 * to
 *
 *     CREATE VIEW relname (aliases) AS
 *         WITH RECURSIVE relname (aliases) AS (query)
 *         SELECT aliases FROM relname
 *
 * Actually, just the WITH ... part, which is then inserted into the original
 * view as the query.
 * ----------
 */
static PGNode *
makeRecursiveViewSelect(char *relname, PGList *aliases, PGNode *query)
{
	PGSelectStmt *s = makeNode(PGSelectStmt);
	PGWithClause *w = makeNode(PGWithClause);
	PGCommonTableExpr *cte = makeNode(PGCommonTableExpr);
	PGList	   *tl = NIL;
	PGListCell   *lc;

	/* create common table expression */
	cte->ctename = relname;
	cte->aliascolnames = aliases;
	cte->ctequery = query;
	cte->location = -1;

	/* create WITH clause and attach CTE */
	w->recursive = true;
	w->ctes = list_make1(cte);
	w->location = -1;

	/* create target list for the new SELECT from the alias list of the
	 * recursive view specification */
	foreach (lc, aliases)
	{
		PGResTarget *rt = makeNode(PGResTarget);

		rt->name = NULL;
		rt->indirection = NIL;
		rt->val = makeColumnRef(strVal(lfirst(lc)), NIL, -1, 0);
		rt->location = -1;

		tl = lappend(tl, rt);
	}

	/* create new SELECT combining WITH clause, target list, and fake FROM
	 * clause */
	s->withClause = w;
	s->targetList = tl;
	s->fromClause = list_make1(makeRangeVar(NULL, relname, -1));

	return (PGNode *) s;
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
