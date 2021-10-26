%{

/*#define YYDEBUG 1*/
/*-------------------------------------------------------------------------
 *
 * gram.y
 *	  POSTGRESQL BISON rules/actions
 *
 * Portions Copyright (c) 1996-2021, PostgreSQL Global Development Group
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
#include "postgres.h"

#include <ctype.h>
#include <limits.h>

#include "../include/ast.h"
#include "access/tableam.h"
#include "catalog/index.h"
#include "catalog/namespace.h"
#include "catalog/pg_am.h"
#include "catalog/pg_trigger.h"
#include "commands/defrem.h"
#include "commands/trigger.h"
#include "nodes/makefuncs.h"
#include "nodes/nodeFuncs.h"
#include "parser/gramparse.h"
#include "parser/parser.h"
#include "storage/lmgr.h"
#include "utils/date.h"
#include "utils/datetime.h"
#include "utils/numeric.h"
#include "utils/xml.h"
#include "../include/define.h"


#define palloc    malloc
#define pfree     free
#define repalloc  realloc
#define pstrdup   strdup

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

/* Private struct for the result of privilege_target production */
typedef struct PrivTarget
{
	GrantTargetType targtype;
	ObjectType	objtype;
	List	   *objs;
} PrivTarget;

/* Private struct for the result of import_qualification production */
typedef struct ImportQual
{
	ImportForeignSchemaType type;
	List	   *table_names;
} ImportQual;

/* Private struct for the result of opt_select_limit production */
typedef struct SelectLimit
{
	Node *limitOffset;
	Node *limitCount;
	LimitOption limitOption;
} SelectLimit;

/* Private struct for the result of group_clause production */
typedef struct GroupClause
{
	bool	distinct;
	List   *list;
} GroupClause;

/* ConstraintAttributeSpec yields an integer bitmask of these flags: */
#define CAS_NOT_DEFERRABLE			0x01
#define CAS_DEFERRABLE				0x02
#define CAS_INITIALLY_IMMEDIATE		0x04
#define CAS_INITIALLY_DEFERRED		0x08
#define CAS_NOT_VALID				0x10
#define CAS_NO_INHERIT				0x20


#define parser_yyerror(msg)  scanner_yyerror(msg, yyscanner)
#define parser_errposition(pos)  scanner_errposition(pos, yyscanner)

static void base_yyerror(YYLTYPE *yylloc, IR* result, core_yyscan_t yyscanner,
						 const char *msg);

%}

%pure-parser
%expect 0
%name-prefix="base_yy"
%locations

%parse-param {IR* result} {core_yyscan_t yyscanner}
%lex-param   {core_yyscan_t yyscanner}

%union
{
	core_YYSTYPE		core_yystype;
	/* these fields must match core_YYSTYPE: */
	int					ival;
	char				*str;
	const char			*keyword;

	IR                  *ir;
}

%type <ir>	stmt toplevel_stmt schema_stmt routine_body_stmt
		AlterEventTrigStmt AlterCollationStmt
		AlterDatabaseStmt AlterDatabaseSetStmt AlterDomainStmt AlterEnumStmt
		AlterFdwStmt AlterForeignServerStmt AlterGroupStmt
		AlterObjectDependsStmt AlterObjectSchemaStmt AlterOwnerStmt
		AlterOperatorStmt AlterTypeStmt AlterSeqStmt AlterSystemStmt AlterTableStmt
		AlterTblSpcStmt AlterExtensionStmt AlterExtensionContentsStmt
		AlterCompositeTypeStmt AlterUserMappingStmt
		AlterRoleStmt AlterRoleSetStmt AlterPolicyStmt AlterStatsStmt
		AlterDefaultPrivilegesStmt DefACLAction
		AnalyzeStmt CallStmt ClosePortalStmt ClusterStmt CommentStmt
		ConstraintsSetStmt CopyStmt CreateAsStmt CreateCastStmt
		CreateDomainStmt CreateExtensionStmt CreateGroupStmt CreateOpClassStmt
		CreateOpFamilyStmt AlterOpFamilyStmt CreatePLangStmt
		CreateSchemaStmt CreateSeqStmt CreateStmt CreateStatsStmt CreateTableSpaceStmt
		CreateFdwStmt CreateForeignServerStmt CreateForeignTableStmt
		CreateAssertionStmt CreateTransformStmt CreateTrigStmt CreateEventTrigStmt
		CreateUserStmt CreateUserMappingStmt CreateRoleStmt CreatePolicyStmt
		CreatedbStmt DeclareCursorStmt DefineStmt DeleteStmt DiscardStmt DoStmt
		DropOpClassStmt DropOpFamilyStmt DropStmt
		DropCastStmt DropRoleStmt
		DropdbStmt DropTableSpaceStmt
		DropTransformStmt
		DropUserMappingStmt ExplainStmt FetchStmt
		GrantStmt GrantRoleStmt ImportForeignSchemaStmt IndexStmt InsertStmt
		ListenStmt LoadStmt LockStmt NotifyStmt ExplainableStmt PreparableStmt
		CreateFunctionStmt AlterFunctionStmt ReindexStmt RemoveAggrStmt
		RemoveFuncStmt RemoveOperStmt RenameStmt ReturnStmt RevokeStmt RevokeRoleStmt
		RuleActionStmt RuleActionStmtOrEmpty RuleStmt
		SecLabelStmt SelectStmt TransactionStmt TransactionStmtLegacy TruncateStmt
		UnlistenStmt UpdateStmt VacuumStmt
		VariableResetStmt VariableSetStmt VariableShowStmt
		ViewStmt CheckPointStmt CreateConversionStmt
		DeallocateStmt PrepareStmt ExecuteStmt
		DropOwnedStmt ReassignOwnedStmt
		AlterTSConfigurationStmt AlterTSDictionaryStmt
		CreateMatViewStmt RefreshMatViewStmt CreateAmStmt
		CreatePublicationStmt AlterPublicationStmt
		CreateSubscriptionStmt AlterSubscriptionStmt DropSubscriptionStmt

%type <ir>	select_no_parens select_with_parens select_clause
				simple_select values_clause
				PLpgSQL_Expr PLAssignStmt

%type <ir>	alter_column_default opclass_item opclass_drop alter_using
%type <ir>	add_drop opt_asc_desc opt_nulls_order

%type <ir>	alter_table_cmd alter_type_cmd opt_collate_clause
	   replica_identity partition_cmd index_partition_cmd
%type <ir>	alter_table_cmds alter_type_cmds
%type <ir>    alter_identity_column_option_list
%type <ir>  alter_identity_column_option

%type <ir>	opt_drop_behavior

%type <ir>	createdb_opt_list createdb_opt_items copy_opt_list
				transaction_mode_list
				create_extension_opt_list alter_extension_opt_list
%type <ir>	createdb_opt_item copy_opt_item
				transaction_mode_item
				create_extension_opt_item alter_extension_opt_item

%type <ir>	opt_lock lock_type cast_context
%type <ir>		utility_option_name
%type <ir>	utility_option_elem
%type <ir>	utility_option_list
%type <ir>	utility_option_arg
%type <ir>	drop_option
%type <ir>	opt_or_replace opt_no
				opt_grant_grant_option opt_grant_admin_option
				opt_nowait opt_if_exists opt_with_data
				opt_transaction_chain
%type <ir>	opt_nowait_or_skip

%type <ir>	OptRoleList AlterOptRoleList
%type <ir>	CreateOptRoleElem AlterOptRoleElem

%type <ir>		opt_type
%type <ir>		foreign_server_version opt_foreign_server_version
%type <ir>		opt_in_database

%type <ir>		OptSchemaName
%type <ir>	OptSchemaEltList

%type <ir>		am_type

%type <ir> TriggerForSpec TriggerForType
%type <ir>	TriggerActionTime
%type <ir>	TriggerEvents TriggerOneEvent
%type <ir>	TriggerFuncArg
%type <ir>	TriggerWhen
%type <ir>		TransitionRelName
%type <ir>	TransitionRowOrTable TransitionOldOrNew
%type <ir>	TriggerTransition

%type <ir>	event_trigger_when_list event_trigger_value_list
%type <ir>	event_trigger_when_item
%type <ir>		enable_trigger

%type <ir>		copy_file_name
				access_method_clause attr_name
				table_access_method_clause name cursor_name file_name
				opt_index_name cluster_index_specification

%type <ir>	func_name handler_name qual_Op qual_all_Op subquery_Op
				opt_class opt_inline_handler opt_validator validator_clause
				opt_collate

%type <ir>	qualified_name insert_target OptConstrFromTable

%type <ir>		all_Op MathOp

%type <ir>		row_security_cmd RowSecurityDefaultForCmd
%type <ir> RowSecurityDefaultPermissive
%type <ir>	RowSecurityOptionalWithCheck RowSecurityOptionalExpr
%type <ir>	RowSecurityDefaultToRole RowSecurityOptionalToRole

%type <ir>		iso_level opt_encoding
%type <ir> grantee
%type <ir>	grantee_list
%type <ir> privilege
%type <ir>	privileges privilege_list
%type <ir> privilege_target
%type <ir> function_with_argtypes aggregate_with_argtypes operator_with_argtypes
%type <ir>	function_with_argtypes_list aggregate_with_argtypes_list operator_with_argtypes_list
%type <ir>	defacl_privilege_target
%type <ir>	DefACLOption
%type <ir>	DefACLOptionList
%type <ir>	import_qualification_type
%type <ir> import_qualification
%type <ir>	vacuum_relation
%type <ir> opt_select_limit select_limit limit_clause

%type <ir>	parse_toplevel stmtmulti routine_body_stmt_list
				OptTableElementList TableElementList OptInherit definition
				OptTypedTableElementList TypedTableElementList
				reloptions opt_reloptions
				OptWith opt_definition func_args func_args_list
				func_args_with_defaults func_args_with_defaults_list
				aggr_args aggr_args_list
				func_as createfunc_opt_list opt_createfunc_opt_list alterfunc_opt_list
				old_aggr_definition old_aggr_list
				oper_argtypes RuleActionList RuleActionMulti
				opt_column_list columnList opt_name_list
				sort_clause opt_sort_clause sortby_list index_params stats_params
				opt_include opt_c_include index_including_params
				name_list role_list from_clause from_list opt_array_bounds
				qualified_name_list any_name any_name_list type_name_list
				any_operator expr_list attrs
				distinct_clause opt_distinct_clause
				target_list opt_target_list insert_column_list set_target_list
				set_clause_list set_clause
				def_list operator_def_list indirection opt_indirection
				reloption_list TriggerFuncArgs opclass_item_list opclass_drop_list
				opclass_purpose opt_opfamily transaction_mode_list_or_empty
				OptTableFuncElementList TableFuncElementList opt_type_modifiers
				prep_type_clause
				execute_param_clause using_clause returning_clause
				opt_enum_val_list enum_val_list table_func_column_list
				create_generic_options alter_generic_options
				relation_expr_list dostmt_opt_list
				transform_element_list transform_type_list
				TriggerTransitions TriggerReferencing
				vacuum_relation_list opt_vacuum_relation_list
				drop_option_list

%type <ir>	opt_routine_body
%type <ir> group_clause
%type <ir>	group_by_list
%type <ir>	group_by_item empty_grouping_set rollup_clause cube_clause
%type <ir>	grouping_sets_clause
%type <ir>	opt_publication_for_tables publication_for_tables

%type <ir>	opt_fdw_options fdw_options
%type <ir>	fdw_option

%type <ir>	OptTempTableName
%type <ir>	into_clause create_as_target create_mv_target

%type <ir>	createfunc_opt_item common_func_opt_item dostmt_opt_item
%type <ir> func_arg func_arg_with_default table_func_column aggr_arg
%type <ir> arg_class
%type <ir>	func_return func_type

%type <ir>  opt_trusted opt_restart_seqs
%type <ir>	 OptTemp
%type <ir>	 OptNoLog
%type <ir> OnCommitOption

%type <ir>	for_locking_strength
%type <ir>	for_locking_item
%type <ir>	for_locking_clause opt_for_locking_clause for_locking_items
%type <ir>	locked_rels_list
%type <ir> set_quantifier

%type <ir>	join_qual
%type <ir>	join_type

%type <ir>	extract_list overlay_list position_list
%type <ir>	substr_list trim_list
%type <ir>	opt_interval interval_second
%type <ir>		unicode_normal_form

%type <ir> opt_instead
%type <ir> opt_unique opt_concurrently opt_verbose opt_full
%type <ir> opt_freeze opt_analyze opt_default opt_recheck
%type <ir>	opt_binary copy_delimiter

%type <ir> copy_from opt_program

%type <ir>	event cursor_options opt_hold opt_set_data
%type <ir>	object_type_any_name object_type_name object_type_name_on_any_name
				drop_type_name

%type <ir>	fetch_args select_limit_value
				offset_clause select_offset_value
				select_fetch_first_value I_or_F_const
%type <ir>	row_or_rows first_or_next

%type <ir>	OptSeqOptList SeqOptList OptParenthesizedSeqOptList
%type <ir>	SeqOptElem

%type <ir>	insert_rest
%type <ir>	opt_conf_expr
%type <ir> opt_on_conflict

%type <ir> generic_set set_rest set_rest_more generic_reset reset_rest
				 SetResetClause FunctionSetResetClause

%type <ir>	TableElement TypedTableElement ConstraintElem TableFuncElement
%type <ir>	columnDef columnOptions
%type <ir>	def_elem reloption_elem old_aggr_elem operator_def_elem
%type <ir>	def_arg columnElem where_clause where_or_current_clause
				a_expr b_expr c_expr AexprConst indirection_el opt_slice_bound
				columnref in_expr having_clause func_table xmltable array_expr
				OptWhereClause operator_def_arg
%type <ir>	rowsfrom_item rowsfrom_list opt_col_def_list
%type <ir> opt_ordinality
%type <ir>	ExclusionConstraintList ExclusionConstraintElem
%type <ir>	func_arg_list func_arg_list_opt
%type <ir>	func_arg_expr
%type <ir>	row explicit_row implicit_row type_list array_expr_list
%type <ir>	case_expr case_arg when_clause case_default
%type <ir>	when_clause_list
%type <ir>	opt_search_clause opt_cycle_clause
%type <ir>	sub_type opt_materialized
%type <ir>	NumericOnly
%type <ir>	NumericOnly_list
%type <ir>	alias_clause opt_alias_clause opt_alias_clause_for_join_using
%type <ir>	func_alias_clause
%type <ir>	sortby
%type <ir>	index_elem index_elem_options
%type <ir>	stats_param
%type <ir>	table_ref
%type <ir>	joined_table
%type <ir>	relation_expr
%type <ir>	relation_expr_opt_alias
%type <ir>	tablesample_clause opt_repeatable_clause
%type <ir>	target_el set_target insert_column_item

%type <ir>		generic_option_name
%type <ir>	generic_option_arg
%type <ir>	generic_option_elem alter_generic_option_elem
%type <ir>	generic_option_list alter_generic_option_list

%type <ir>	reindex_target_type reindex_target_multitable

%type <ir>	copy_generic_opt_arg copy_generic_opt_arg_list_item
%type <ir>	copy_generic_opt_elem
%type <ir>	copy_generic_opt_list copy_generic_opt_arg_list
%type <ir>	copy_options

%type <ir>	Typename SimpleTypename ConstTypename
				GenericType Numeric opt_float
				Character ConstCharacter
				CharacterWithLength CharacterWithoutLength
				ConstDatetime ConstInterval
				Bit ConstBit BitWithLength BitWithoutLength
%type <ir>		character
%type <ir>		extract_arg
%type <ir> opt_varying opt_timezone opt_no_inherit

%type <ir>	Iconst SignedIconst
%type <ir>		Sconst comment_text notify_payload
%type <ir>		RoleId opt_boolean_or_string
%type <ir>	var_list
%type <ir>		ColId ColLabel BareColLabel
%type <ir>		NonReservedWord NonReservedWord_or_Sconst
%type <ir>		var_name type_function_name param_name
%type <ir>		createdb_opt_name plassign_target
%type <ir>	var_value zone_value
%type <ir> auth_ident RoleSpec opt_granted_by

%type <ir> unreserved_keyword type_func_name_keyword
%type <ir> col_name_keyword reserved_keyword
%type <ir> bare_label_keyword

%type <ir>	TableConstraint TableLikeClause
%type <ir>	TableLikeOptionList TableLikeOption
%type <ir>		column_compression opt_column_compression
%type <ir>	ColQualList
%type <ir>	ColConstraint ColConstraintElem ConstraintAttr
%type <ir>	key_actions key_delete key_match key_update key_action
%type <ir>	ConstraintAttributeSpec ConstraintAttributeElem
%type <ir>		ExistingIndex

%type <ir>	constraints_set_list
%type <ir> constraints_set_mode
%type <ir>		OptTableSpace OptConsTableSpace
%type <ir> OptTableSpaceOwner
%type <ir>	opt_check_option

%type <ir>		opt_provider security_label

%type <ir>	xml_attribute_el
%type <ir>	xml_attribute_list xml_attributes
%type <ir>	xml_root_version opt_xml_root_standalone
%type <ir>	xmlexists_argument
%type <ir>	document_or_content
%type <ir> xml_whitespace_option
%type <ir>	xmltable_column_list xmltable_column_option_list
%type <ir>	xmltable_column_el
%type <ir>	xmltable_column_option_el
%type <ir>	xml_namespace_list
%type <ir>	xml_namespace_el

%type <ir>	func_application func_expr_common_subexpr
%type <ir>	func_expr func_expr_windowless
%type <ir>	common_table_expr
%type <ir>	with_clause opt_with_clause
%type <ir>	cte_list

%type <ir>	within_group_clause
%type <ir>	filter_clause
%type <ir>	window_clause window_definition_list opt_partition_clause
%type <ir>	window_definition over_clause window_specification
				opt_frame_clause frame_extent frame_bound
%type <ir>	opt_window_exclusion_clause
%type <ir>		opt_existing_window_name
%type <ir> opt_if_not_exists
%type <ir>	generated_when override_kind
%type <ir>	PartitionSpec OptPartitionSpec
%type <ir>	part_elem
%type <ir>		part_params
%type <ir> PartitionBoundSpec
%type <ir>		hash_partbound
%type <ir>		hash_partbound_elem

%type <ir> opt_with opt_as opt_using opt_procedural analyze_keyword from_in opt_from_in opt_transaction
%type <ir> plassign_equals opt_column opt_by FUNCTION_or_PROCEDURE TriggerForOptEach xml_passing_mech
%type <ir> opt_outer opt_table opt_restrict opt_equal any_with opt_all_clause opt_asymmetric



/*
 * Non-keyword token types.  These are hard-wired into the "flex" lexer.
 * They must be listed first so that their numeric codes do not depend on
 * the set of keywords.  PL/pgSQL depends on this so that it can share the
 * same lexer.  If you add/change tokens here, fix PL/pgSQL to match!
 *
 * UIDENT and USCONST are reduced to IDENT and SCONST in parser.c, so that
 * they need no productions here; but we must assign token codes to them.
 *
 * DOT_DOT is unused in the core SQL grammar, and so will always provoke
 * parse errors.  It is needed by PL/pgSQL.
 */
%token <ir>	IDENT UIDENT FCONST SCONST USCONST BCONST XCONST Op
%token <ir>	ICONST PARAM
%token			TYPECAST DOT_DOT COLON_EQUALS EQUALS_GREATER
%token			LESS_EQUALS GREATER_EQUALS NOT_EQUALS

/*
 * If you want to make any keyword changes, update the keyword table in
 * src/include/parser/kwlist.h and add new keywords to the appropriate one
 * of the reserved-or-not-so-reserved keyword lists, below; search
 * this file for "Keyword category lists".
 */

/* ordinary key words in alphabetical order */
%token <ir> ABORT_P ABSOLUTE_P ACCESS ACTION ADD_P ADMIN AFTER
	AGGREGATE ALL ALSO ALTER ALWAYS ANALYSE ANALYZE AND ANY ARRAY AS ASC
	ASENSITIVE ASSERTION ASSIGNMENT ASYMMETRIC ATOMIC AT ATTACH ATTRIBUTE AUTHORIZATION

	BACKWARD BEFORE BEGIN_P BETWEEN BIGINT BINARY BIT
	BOOLEAN_P BOTH BREADTH BY

	CACHE CALL CALLED CASCADE CASCADED CASE CAST CATALOG_P CHAIN CHAR_P
	CHARACTER CHARACTERISTICS CHECK CHECKPOINT CLASS CLOSE
	CLUSTER COALESCE COLLATE COLLATION COLUMN COLUMNS COMMENT COMMENTS COMMIT
	COMMITTED COMPRESSION CONCURRENTLY CONFIGURATION CONFLICT
	CONNECTION CONSTRAINT CONSTRAINTS CONTENT_P CONTINUE_P CONVERSION_P COPY
	COST CREATE CROSS CSV CUBE CURRENT_P
	CURRENT_CATALOG CURRENT_DATE CURRENT_ROLE CURRENT_SCHEMA
	CURRENT_TIME CURRENT_TIMESTAMP CURRENT_USER CURSOR CYCLE

	DATA_P DATABASE DAY_P DEALLOCATE DEC DECIMAL_P DECLARE DEFAULT DEFAULTS
	DEFERRABLE DEFERRED DEFINER DELETE_P DELIMITER DELIMITERS DEPENDS DEPTH DESC
	DETACH DICTIONARY DISABLE_P DISCARD DISTINCT DO DOCUMENT_P DOMAIN_P
	DOUBLE_P DROP

	EACH ELSE ENABLE_P ENCODING ENCRYPTED END_P ENUM_P ESCAPE EVENT EXCEPT
	EXCLUDE EXCLUDING EXCLUSIVE EXECUTE EXISTS EXPLAIN EXPRESSION
	EXTENSION EXTERNAL EXTRACT

	FALSE_P FAMILY FETCH FILTER FINALIZE FIRST_P FLOAT_P FOLLOWING FOR
	FORCE FOREIGN FORWARD FREEZE FROM FULL FUNCTION FUNCTIONS

	GENERATED GLOBAL GRANT GRANTED GREATEST GROUP_P GROUPING GROUPS

	HANDLER HAVING HEADER_P HOLD HOUR_P

	IDENTITY_P IF_P ILIKE IMMEDIATE IMMUTABLE IMPLICIT_P IMPORT_P IN_P INCLUDE
	INCLUDING INCREMENT INDEX INDEXES INHERIT INHERITS INITIALLY INLINE_P
	INNER_P INOUT INPUT_P INSENSITIVE INSERT INSTEAD INT_P INTEGER
	INTERSECT INTERVAL INTO INVOKER IS ISNULL ISOLATION

	JOIN

	KEY

	LABEL LANGUAGE LARGE_P LAST_P LATERAL_P
	LEADING LEAKPROOF LEAST LEFT LEVEL LIKE LIMIT LISTEN LOAD LOCAL
	LOCALTIME LOCALTIMESTAMP LOCATION LOCK_P LOCKED LOGGED

	MAPPING MATCH MATERIALIZED MAXVALUE METHOD MINUTE_P MINVALUE MODE MONTH_P MOVE

	NAME_P NAMES NATIONAL NATURAL NCHAR NEW NEXT NFC NFD NFKC NFKD NO NONE
	NORMALIZE NORMALIZED
	NOT NOTHING NOTIFY NOTNULL NOWAIT NULL_P NULLIF
	NULLS_P NUMERIC

	OBJECT_P OF OFF OFFSET OIDS OLD ON ONLY OPERATOR OPTION OPTIONS OR
	ORDER ORDINALITY OTHERS OUT_P OUTER_P
	OVER OVERLAPS OVERLAY OVERRIDING OWNED OWNER

	PARALLEL PARSER PARTIAL PARTITION PASSING PASSWORD PLACING PLANS POLICY
	POSITION PRECEDING PRECISION PRESERVE PREPARE PREPARED PRIMARY
	PRIOR PRIVILEGES PROCEDURAL PROCEDURE PROCEDURES PROGRAM PUBLICATION

	QUOTE

	RANGE READ REAL REASSIGN RECHECK RECURSIVE REF REFERENCES REFERENCING
	REFRESH REINDEX RELATIVE_P RELEASE RENAME REPEATABLE REPLACE REPLICA
	RESET RESTART RESTRICT RETURN RETURNING RETURNS REVOKE RIGHT ROLE ROLLBACK ROLLUP
	ROUTINE ROUTINES ROW ROWS RULE

	SAVEPOINT SCHEMA SCHEMAS SCROLL SEARCH SECOND_P SECURITY SELECT SEQUENCE SEQUENCES
	SERIALIZABLE SERVER SESSION SESSION_USER SET SETS SETOF SHARE SHOW
	SIMILAR SIMPLE SKIP SMALLINT SNAPSHOT SOME SQL_P STABLE STANDALONE_P
	START STATEMENT STATISTICS STDIN STDOUT STORAGE STORED STRICT_P STRIP_P
	SUBSCRIPTION SUBSTRING SUPPORT SYMMETRIC SYSID SYSTEM_P

	TABLE TABLES TABLESAMPLE TABLESPACE TEMP TEMPLATE TEMPORARY TEXT_P THEN
	TIES TIME TIMESTAMP TO TRAILING TRANSACTION TRANSFORM
	TREAT TRIGGER TRIM TRUE_P
	TRUNCATE TRUSTED TYPE_P TYPES_P

	UESCAPE UNBOUNDED UNCOMMITTED UNENCRYPTED UNION UNIQUE UNKNOWN
	UNLISTEN UNLOGGED UNTIL UPDATE USER USING

	VACUUM VALID VALIDATE VALIDATOR VALUE_P VALUES VARCHAR VARIADIC VARYING
	VERBOSE VERSION_P VIEW VIEWS VOLATILE

	WHEN WHERE WHITESPACE_P WINDOW WITH WITHIN WITHOUT WORK WRAPPER WRITE

	XML_P XMLATTRIBUTES XMLCONCAT XMLELEMENT XMLEXISTS XMLFOREST XMLNAMESPACES
	XMLPARSE XMLPI XMLROOT XMLSERIALIZE XMLTABLE

	YEAR_P YES_P

	ZONE

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

/*
 * The grammar likewise thinks these tokens are keywords, but they are never
 * generated by the scanner.  Rather, they can be injected by parser.c as
 * the initial token of the string (using the lookahead-token mechanism
 * implemented there).  This provides a way to tell the grammar to parse
 * something other than the usual list of SQL commands.
 */
%token		MODE_TYPE_NAME
%token		MODE_PLPGSQL_EXPR
%token		MODE_PLPGSQL_ASSIGN1
%token		MODE_PLPGSQL_ASSIGN2
%token		MODE_PLPGSQL_ASSIGN3


/* Precedence: lowest to highest */
%nonassoc	SET				/* see relation_expr_opt_alias */
%left		UNION EXCEPT
%left		INTERSECT
%left		OR
%left		AND
%right		NOT
%nonassoc	IS ISNULL NOTNULL	/* IS sets precedence for IS NULL, etc */
%nonassoc	'<' '>' '=' LESS_EQUALS GREATER_EQUALS NOT_EQUALS
%nonassoc	BETWEEN IN_P LIKE ILIKE SIMILAR NOT_LA
%nonassoc	ESCAPE			/* ESCAPE must be just above LIKE/ILIKE/SIMILAR */
/*
 * To support target_el without AS, it used to be necessary to assign IDENT an
 * explicit precedence just less than Op.  While that's not really necessary
 * since we removed postfix operators, it's still helpful to do so because
 * there are some other unreserved keywords that need precedence assignments.
 * If those keywords have the same precedence as IDENT then they clearly act
 * the same as non-keywords, reducing the risk of unwanted precedence effects.
 *
 * We need to do this for PARTITION, RANGE, ROWS, and GROUPS to support
 * opt_existing_window_name (see comment there).
 *
 * The frame_bound productions UNBOUNDED PRECEDING and UNBOUNDED FOLLOWING
 * are even messier: since UNBOUNDED is an unreserved keyword (per spec!),
 * there is no principled way to distinguish these from the productions
 * a_expr PRECEDING/FOLLOWING.  We hack this up by giving UNBOUNDED slightly
 * lower precedence than PRECEDING and FOLLOWING.  At present this doesn't
 * appear to cause UNBOUNDED to be treated differently from other unreserved
 * keywords anywhere else in the grammar, but it's definitely risky.  We can
 * blame any funny behavior of UNBOUNDED on the SQL standard, though.
 *
 * To support CUBE and ROLLUP in GROUP BY without reserving them, we give them
 * an explicit priority lower than '(', so that a rule with CUBE '(' will shift
 * rather than reducing a conflicting rule that takes CUBE as a function name.
 * Using the same precedence as IDENT seems right for the reasons given above.
 */
%nonassoc	UNBOUNDED		/* ideally would have same precedence as IDENT */
%nonassoc	IDENT PARTITION RANGE ROWS GROUPS PRECEDING FOLLOWING CUBE ROLLUP
%left		Op OPERATOR		/* multi-character ops and user-defined operators */
%left		'+' '-'
%left		'*' '/' '%'
%left		'^'
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
%left		JOIN CROSS LEFT FULL RIGHT INNER_P NATURAL

%%

parse_toplevel:

    stmtmulti {
        auto tmp1 = $1;
        res = new IR(kParseToplevel, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | MODE_TYPE_NAME Typename {
        auto tmp1 = $2;
        res = new IR(kParseToplevel, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | MODE_PLPGSQL_EXPR PLpgSQL_Expr {
        auto tmp1 = $2;
        res = new IR(kParseToplevel, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | MODE_PLPGSQL_ASSIGN1 PLAssignStmt {
        auto tmp1 = $2;
        res = new IR(kParseToplevel, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | MODE_PLPGSQL_ASSIGN2 PLAssignStmt {
        auto tmp1 = $2;
        res = new IR(kParseToplevel, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | MODE_PLPGSQL_ASSIGN3 PLAssignStmt {
        auto tmp1 = $2;
        res = new IR(kParseToplevel, OP3("", "", ""), tmp1);
        $$ = res;
    }

;

/*
* At top level, we wrap each stmt with a RawStmt node carrying start location
* and length of the stmt's text.  Notice that the start loc/len are driven
* entirely from semicolon locations (@2).  It would seem natural to use
* @1 or @3 to get the true start location of a stmt, but that doesn't work
* for statements that can start with empty nonterminals (opt_with_clause is
* the main offender here); as noted in the comments for YYLLOC_DEFAULT,
* we'd get -1 for the location in such cases.
* We also take care to discard empty statements entirely.
*/

stmtmulti:

    stmtmulti ';' toplevel_stmt {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kStmtmulti, OP3("", ";", ""), tmp1, tmp2);
        $$ = res;
    }

    | toplevel_stmt {
        auto tmp1 = $1;
        res = new IR(kStmtmulti, OP3("", "", ""), tmp1);
        $$ = res;
    }

;

/*
* toplevel_stmt includes BEGIN and END.  stmt does not include them, because
* those words have different meanings in function bodys.
*/

toplevel_stmt:

    stmt {
        auto tmp1 = $1;
        res = new IR(kToplevelStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | TransactionStmtLegacy {
        auto tmp1 = $1;
        res = new IR(kToplevelStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


stmt:

    AlterEventTrigStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterCollationStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterDatabaseStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterDatabaseSetStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterDefaultPrivilegesStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterDomainStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterEnumStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterExtensionStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterExtensionContentsStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterFdwStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterForeignServerStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterFunctionStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterGroupStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterObjectDependsStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterObjectSchemaStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterOwnerStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterOperatorStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterTypeStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterPolicyStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterSeqStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterSystemStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterTableStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterTblSpcStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterCompositeTypeStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterPublicationStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterRoleSetStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterRoleStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterSubscriptionStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterStatsStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterTSConfigurationStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterTSDictionaryStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterUserMappingStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AnalyzeStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CallStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CheckPointStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ClosePortalStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ClusterStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CommentStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ConstraintsSetStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CopyStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateAmStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateAsStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateAssertionStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateCastStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateConversionStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateDomainStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateExtensionStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateFdwStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateForeignServerStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateForeignTableStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateFunctionStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateGroupStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateMatViewStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateOpClassStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateOpFamilyStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreatePublicationStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterOpFamilyStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreatePolicyStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreatePLangStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateSchemaStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateSeqStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateSubscriptionStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateStatsStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateTableSpaceStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateTransformStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateTrigStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateEventTrigStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateRoleStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateUserStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateUserMappingStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreatedbStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DeallocateStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DeclareCursorStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DefineStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DeleteStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DiscardStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DoStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DropCastStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DropOpClassStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DropOpFamilyStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DropOwnedStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DropStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DropSubscriptionStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DropTableSpaceStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DropTransformStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DropRoleStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DropUserMappingStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DropdbStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ExecuteStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ExplainStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | FetchStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | GrantStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | GrantRoleStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ImportForeignSchemaStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | IndexStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | InsertStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ListenStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | RefreshMatViewStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | LoadStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | LockStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | NotifyStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | PrepareStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ReassignOwnedStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ReindexStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | RemoveAggrStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | RemoveFuncStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | RemoveOperStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | RenameStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | RevokeStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | RevokeRoleStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | RuleStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | SecLabelStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | SelectStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | TransactionStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | TruncateStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | UnlistenStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | UpdateStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | VacuumStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | VariableResetStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | VariableSetStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | VariableShowStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ViewStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kStmt, string(""));
        $$ = res;
    }

;

/*****************************************************************************
*
* CALL statement
*
*****************************************************************************/


CallStmt:

    CALL func_application {
        auto tmp1 = $2;
        res = new IR(kCallStmt, OP3("CALL", "", ""), tmp1);
        $$ = res;
    }

;

/*****************************************************************************
*
* Create a new Postgres DBMS role
*
*****************************************************************************/


CreateRoleStmt:

    CREATE ROLE RoleId opt_with OptRoleList {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("CREATE ROLE", "", ""), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kCreateRoleStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


opt_with:	
        WITH {
            $$ = new IR(kOptWith, OP3("WITH", "", ""));    
        }
        | WITH_LA {
            $$ = new IR(kOptWith, OP3("WITH", "", ""));
        }
        | /*EMPTY*/ {
            $$ = new IR(kOptWith, OP0());
        }
;

/*
* Options for CREATE ROLE and ALTER ROLE (also used by CREATE/ALTER USER
* for backwards compatibility).  Note: the only option required by SQL99
* is "WITH ADMIN name".
*/

OptRoleList:

    OptRoleList CreateOptRoleElem {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptRoleList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | /* EMPTY */ {
        res = new IR(kOptRoleList, string(""));
        $$ = res;
    }

;


AlterOptRoleList:

    AlterOptRoleList AlterOptRoleElem {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAlterOptRoleList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | /* EMPTY */ {
        res = new IR(kAlterOptRoleList, string(""));
        $$ = res;
    }

;


AlterOptRoleElem:

    PASSWORD Sconst {
        auto tmp1 = $2;
        res = new IR(kAlterOptRoleElem, OP3("PASSWORD", "", ""), tmp1);
        $$ = res;
    }

    | PASSWORD NULL_P {
        res = new IR(kAlterOptRoleElem, string("PASSWORD NULL"));
        $$ = res;
    }

    | ENCRYPTED PASSWORD Sconst {
        auto tmp1 = $3;
        res = new IR(kAlterOptRoleElem, OP3("ENCRYPTED PASSWORD", "", ""), tmp1);
        $$ = res;
    }

    | UNENCRYPTED PASSWORD Sconst {
        auto tmp1 = $3;
        res = new IR(kAlterOptRoleElem, OP3("UNENCRYPTED PASSWORD", "", ""), tmp1);
        $$ = res;
    }

    | INHERIT {
        res = new IR(kAlterOptRoleElem, string("INHERIT"));
        $$ = res;
    }

    | CONNECTION LIMIT SignedIconst {
        auto tmp1 = $3;
        res = new IR(kAlterOptRoleElem, OP3("CONNECTION LIMIT", "", ""), tmp1);
        $$ = res;
    }

    | VALID UNTIL Sconst {
        auto tmp1 = $3;
        res = new IR(kAlterOptRoleElem, OP3("VALID UNTIL", "", ""), tmp1);
        $$ = res;
    }

    | USER role_list {
        auto tmp1 = $2;
        res = new IR(kAlterOptRoleElem, OP3("USER", "", ""), tmp1);
        $$ = res;
    }

    | IDENT {
        res = new IR(kAlterOptRoleElem, string("IDENT"));
        $$ = res;
    }

;


CreateOptRoleElem:

    AlterOptRoleElem {
        auto tmp1 = $1;
        res = new IR(kCreateOptRoleElem, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | SYSID Iconst {
        auto tmp1 = $2;
        res = new IR(kCreateOptRoleElem, OP3("SYSID", "", ""), tmp1);
        $$ = res;
    }

    | ADMIN role_list {
        auto tmp1 = $2;
        res = new IR(kCreateOptRoleElem, OP3("ADMIN", "", ""), tmp1);
        $$ = res;
    }

    | ROLE role_list {
        auto tmp1 = $2;
        res = new IR(kCreateOptRoleElem, OP3("ROLE", "", ""), tmp1);
        $$ = res;
    }

    | IN_P ROLE role_list {
        auto tmp1 = $3;
        res = new IR(kCreateOptRoleElem, OP3("IN ROLE", "", ""), tmp1);
        $$ = res;
    }

    | IN_P GROUP_P role_list {
        auto tmp1 = $3;
        res = new IR(kCreateOptRoleElem, OP3("IN GROUP", "", ""), tmp1);
        $$ = res;
    }

;


/*****************************************************************************
*
* Create a new Postgres DBMS user (role with implied login ability)
*
*****************************************************************************/


CreateUserStmt:

    CREATE USER RoleId opt_with OptRoleList {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("CREATE USER", "", ""), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kCreateUserStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


/*****************************************************************************
*
* Alter a postgresql DBMS role
*
*****************************************************************************/


AlterRoleStmt:

    ALTER ROLE RoleSpec opt_with AlterOptRoleList {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("ALTER ROLE", "", ""), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kAlterRoleStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER USER RoleSpec opt_with AlterOptRoleList {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("ALTER USER", "", ""), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kAlterRoleStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


opt_in_database:

    /* EMPTY */ {
        res = new IR(kOptInDatabase, string(""));
        $$ = res;
    }

    | IN_P DATABASE name {
        auto tmp1 = $3;
        res = new IR(kOptInDatabase, OP3("IN DATABASE", "", ""), tmp1);
        $$ = res;
    }

;


AlterRoleSetStmt:

    ALTER ROLE RoleSpec opt_in_database SetResetClause {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("ALTER ROLE", "", ""), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kAlterRoleSetStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER ROLE ALL opt_in_database SetResetClause {
        auto tmp1 = $4;
        auto tmp2 = $5;
        res = new IR(kAlterRoleSetStmt, OP3("ALTER ROLE ALL", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER USER RoleSpec opt_in_database SetResetClause {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("ALTER USER", "", ""), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kAlterRoleSetStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER USER ALL opt_in_database SetResetClause {
        auto tmp1 = $4;
        auto tmp2 = $5;
        res = new IR(kAlterRoleSetStmt, OP3("ALTER USER ALL", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


/*****************************************************************************
*
* Drop a postgresql DBMS role
*
* XXX Ideally this would have CASCADE/RESTRICT options, but a role
* might own objects in multiple databases, and there is presently no way to
* implement cascading to other databases.  So we always behave as RESTRICT.
*****************************************************************************/


DropRoleStmt:

    DROP ROLE role_list {
        auto tmp1 = $3;
        res = new IR(kDropRoleStmt, OP3("DROP ROLE", "", ""), tmp1);
        $$ = res;
    }

    | DROP ROLE IF_P EXISTS role_list {
        auto tmp1 = $5;
        res = new IR(kDropRoleStmt, OP3("DROP ROLE IF EXISTS", "", ""), tmp1);
        $$ = res;
    }

    | DROP USER role_list {
        auto tmp1 = $3;
        res = new IR(kDropRoleStmt, OP3("DROP USER", "", ""), tmp1);
        $$ = res;
    }

    | DROP USER IF_P EXISTS role_list {
        auto tmp1 = $5;
        res = new IR(kDropRoleStmt, OP3("DROP USER IF EXISTS", "", ""), tmp1);
        $$ = res;
    }

    | DROP GROUP_P role_list {
        auto tmp1 = $3;
        res = new IR(kDropRoleStmt, OP3("DROP GROUP", "", ""), tmp1);
        $$ = res;
    }

    | DROP GROUP_P IF_P EXISTS role_list {
        auto tmp1 = $5;
        res = new IR(kDropRoleStmt, OP3("DROP GROUP IF EXISTS", "", ""), tmp1);
        $$ = res;
    }

;


/*****************************************************************************
*
* Create a postgresql group (role without login ability)
*
*****************************************************************************/


CreateGroupStmt:

    CREATE GROUP_P RoleId opt_with OptRoleList {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("CREATE GROUP", "", ""), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kCreateGroupStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


/*****************************************************************************
*
* Alter a postgresql group
*
*****************************************************************************/


AlterGroupStmt:

    ALTER GROUP_P RoleSpec add_drop USER role_list {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("ALTER GROUP", "", "USER"), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kAlterGroupStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


add_drop:

    ADD_P {
        res = new IR(kAddDrop, string("ADD"));
        $$ = res;
    }

    | DROP {
        res = new IR(kAddDrop, string("DROP"));
        $$ = res;
    }

;


/*****************************************************************************
*
* Manipulate a schema
*
*****************************************************************************/


CreateSchemaStmt:

    CREATE SCHEMA OptSchemaName AUTHORIZATION RoleSpec OptSchemaEltList {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kUnknown, OP3("CREATE SCHEMA", "AUTHORIZATION", ""), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kCreateSchemaStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | CREATE SCHEMA ColId OptSchemaEltList {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kCreateSchemaStmt, OP3("CREATE SCHEMA", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | CREATE SCHEMA IF_P NOT EXISTS OptSchemaName AUTHORIZATION RoleSpec OptSchemaEltList {
        auto tmp1 = $6;
        auto tmp2 = $8;
        res = new IR(kUnknown, OP3("CREATE SCHEMA IF NOT EXISTS", "AUTHORIZATION", ""), tmp1, tmp2);
        auto tmp3 = $9;
        res = new IR(kCreateSchemaStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | CREATE SCHEMA IF_P NOT EXISTS ColId OptSchemaEltList {
        auto tmp1 = $6;
        auto tmp2 = $7;
        res = new IR(kCreateSchemaStmt, OP3("CREATE SCHEMA IF NOT EXISTS", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


OptSchemaName:

    ColId {
        auto tmp1 = $1;
        res = new IR(kOptSchemaName, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | /* EMPTY */ {
        res = new IR(kOptSchemaName, string(""));
        $$ = res;
    }

;


OptSchemaEltList:

    OptSchemaEltList schema_stmt {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptSchemaEltList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | /* EMPTY */ {
        res = new IR(kOptSchemaEltList, string(""));
        $$ = res;
    }

;

/*
*	schema_stmt are the ones that can show up inside a CREATE SCHEMA
*	statement (in addition to by themselves).
*/

schema_stmt:

    CreateStmt {
        auto tmp1 = $1;
        res = new IR(kSchemaStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | IndexStmt {
        auto tmp1 = $1;
        res = new IR(kSchemaStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateSeqStmt {
        auto tmp1 = $1;
        res = new IR(kSchemaStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateTrigStmt {
        auto tmp1 = $1;
        res = new IR(kSchemaStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | GrantStmt {
        auto tmp1 = $1;
        res = new IR(kSchemaStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ViewStmt {
        auto tmp1 = $1;
        res = new IR(kSchemaStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


/*****************************************************************************
*
* Set PG internal variable
*	  SET name TO 'var_value'
* Include SQL syntax (thomas 1997-10-22):
*	  SET TIME ZONE 'var_value'
*
*****************************************************************************/


VariableSetStmt:

    SET set_rest {
        auto tmp1 = $2;
        res = new IR(kVariableSetStmt, OP3("SET", "", ""), tmp1);
        $$ = res;
    }

    | SET LOCAL set_rest {
        auto tmp1 = $3;
        res = new IR(kVariableSetStmt, OP3("SET LOCAL", "", ""), tmp1);
        $$ = res;
    }

    | SET SESSION set_rest {
        auto tmp1 = $3;
        res = new IR(kVariableSetStmt, OP3("SET SESSION", "", ""), tmp1);
        $$ = res;
    }

;


set_rest:

    TRANSACTION transaction_mode_list {
        auto tmp1 = $2;
        res = new IR(kSetRest, OP3("TRANSACTION", "", ""), tmp1);
        $$ = res;
    }

    | SESSION CHARACTERISTICS AS TRANSACTION transaction_mode_list {
        auto tmp1 = $5;
        res = new IR(kSetRest, OP3("SESSION CHARACTERISTICS AS TRANSACTION", "", ""), tmp1);
        $$ = res;
    }

    | set_rest_more {
        auto tmp1 = $1;
        res = new IR(kSetRest, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


generic_set:

    var_name TO var_list {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kGenericSet, OP3("", "TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | var_name '=' var_list {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kGenericSet, OP3("", "=", ""), tmp1, tmp2);
        $$ = res;
    }

    | var_name TO DEFAULT {
        auto tmp1 = $1;
        res = new IR(kGenericSet, OP3("", "TO DEFAULT", ""), tmp1);
        $$ = res;
    }

    | var_name '=' DEFAULT {
        auto tmp1 = $1;
        res = new IR(kGenericSet, OP3("", "= DEFAULT", ""), tmp1);
        $$ = res;
    }

;


set_rest_more:

    generic_set {
        auto tmp1 = $1;
        res = new IR(kSetRestMore, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | var_name FROM CURRENT_P {
        auto tmp1 = $1;
        res = new IR(kSetRestMore, OP3("", "FROM CURRENT", ""), tmp1);
        $$ = res;
    }

    | TIME ZONE zone_value {
        auto tmp1 = $3;
        res = new IR(kSetRestMore, OP3("TIME ZONE", "", ""), tmp1);
        $$ = res;
    }

    | CATALOG_P Sconst {
        auto tmp1 = $2;
        res = new IR(kSetRestMore, OP3("CATALOG", "", ""), tmp1);
        $$ = res;
    }

    | SCHEMA Sconst {
        auto tmp1 = $2;
        res = new IR(kSetRestMore, OP3("SCHEMA", "", ""), tmp1);
        $$ = res;
    }

    | NAMES opt_encoding {
        auto tmp1 = $2;
        res = new IR(kSetRestMore, OP3("NAMES", "", ""), tmp1);
        $$ = res;
    }

    | ROLE NonReservedWord_or_Sconst {
        auto tmp1 = $2;
        res = new IR(kSetRestMore, OP3("ROLE", "", ""), tmp1);
        $$ = res;
    }

    | SESSION AUTHORIZATION NonReservedWord_or_Sconst {
        auto tmp1 = $3;
        res = new IR(kSetRestMore, OP3("SESSION AUTHORIZATION", "", ""), tmp1);
        $$ = res;
    }

    | SESSION AUTHORIZATION DEFAULT {
        res = new IR(kSetRestMore, string("SESSION AUTHORIZATION DEFAULT"));
        $$ = res;
    }

    | XML_P OPTION document_or_content {
        auto tmp1 = $3;
        res = new IR(kSetRestMore, OP3("XML OPTION", "", ""), tmp1);
        $$ = res;
    }

    | TRANSACTION SNAPSHOT Sconst {
        auto tmp1 = $3;
        res = new IR(kSetRestMore, OP3("TRANSACTION SNAPSHOT", "", ""), tmp1);
        $$ = res;
    }

;


var_name:

    ColId {
        auto tmp1 = $1;
        res = new IR(kVarName, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | var_name '.' ColId {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kVarName, OP3("", ".", ""), tmp1, tmp2);
        $$ = res;
    }

;


var_list:

    var_value {
        auto tmp1 = $1;
        res = new IR(kVarList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | var_list ',' var_value {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kVarList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


var_value:

    opt_boolean_or_string {
        auto tmp1 = $1;
        res = new IR(kVarValue, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | NumericOnly {
        auto tmp1 = $1;
        res = new IR(kVarValue, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


iso_level:

    READ UNCOMMITTED {
        res = new IR(kIsoLevel, string("READ UNCOMMITTED"));
        $$ = res;
    }

    | READ COMMITTED {
        res = new IR(kIsoLevel, string("READ COMMITTED"));
        $$ = res;
    }

    | REPEATABLE READ {
        res = new IR(kIsoLevel, string("REPEATABLE READ"));
        $$ = res;
    }

    | SERIALIZABLE {
        res = new IR(kIsoLevel, string("SERIALIZABLE"));
        $$ = res;
    }

;


opt_boolean_or_string:

    TRUE_P {
        res = new IR(kOptBooleanOrString, string("TRUE"));
        $$ = res;
    }

    | FALSE_P {
        res = new IR(kOptBooleanOrString, string("FALSE"));
        $$ = res;
    }

    | ON {
        res = new IR(kOptBooleanOrString, string("ON"));
        $$ = res;
    }

    | NonReservedWord_or_Sconst {
        auto tmp1 = $1;
        res = new IR(kOptBooleanOrString, OP3("", "", ""), tmp1);
        $$ = res;
    }

;

/* Timezone values can be:
* - a string such as 'pst8pdt'
* - an identifier such as "pst8pdt"
* - an integer or floating point number
* - a time interval per SQL99
* ColId gives reduce/reduce errors against ConstInterval and LOCAL,
* so use IDENT (meaning we reject anything that is a key word).
*/

zone_value:

    Sconst {
        auto tmp1 = $1;
        res = new IR(kZoneValue, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | IDENT {
        res = new IR(kZoneValue, string("IDENT"));
        $$ = res;
    }

    | ConstInterval Sconst opt_interval {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUnknown, OP3("", "", ""), tmp1, tmp2);
        auto tmp3 = $3;
        res = new IR(kZoneValue, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ConstInterval '(' Iconst ')' Sconst {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("", "(", ")"), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kZoneValue, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | NumericOnly {
        auto tmp1 = $1;
        res = new IR(kZoneValue, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DEFAULT {
        res = new IR(kZoneValue, string("DEFAULT"));
        $$ = res;
    }

    | LOCAL {
        res = new IR(kZoneValue, string("LOCAL"));
        $$ = res;
    }

;


opt_encoding:

    Sconst {
        auto tmp1 = $1;
        res = new IR(kOptEncoding, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DEFAULT {
        res = new IR(kOptEncoding, string("DEFAULT"));
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptEncoding, string(""));
        $$ = res;
    }

;


NonReservedWord_or_Sconst:

    NonReservedWord {
        auto tmp1 = $1;
        res = new IR(kNonReservedWordOrSconst, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | Sconst {
        auto tmp1 = $1;
        res = new IR(kNonReservedWordOrSconst, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


VariableResetStmt:

    RESET reset_rest {
        auto tmp1 = $2;
        res = new IR(kVariableResetStmt, OP3("RESET", "", ""), tmp1);
        $$ = res;
    }

;


reset_rest:

    generic_reset {
        auto tmp1 = $1;
        res = new IR(kResetRest, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | TIME ZONE {
        res = new IR(kResetRest, string("TIME ZONE"));
        $$ = res;
    }

    | TRANSACTION ISOLATION LEVEL {
        res = new IR(kResetRest, string("TRANSACTION ISOLATION LEVEL"));
        $$ = res;
    }

    | SESSION AUTHORIZATION {
        res = new IR(kResetRest, string("SESSION AUTHORIZATION"));
        $$ = res;
    }

;


generic_reset:

    var_name {
        auto tmp1 = $1;
        res = new IR(kGenericReset, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ALL {
        res = new IR(kGenericReset, string("ALL"));
        $$ = res;
    }

;

/* SetResetClause allows SET or RESET without LOCAL */

SetResetClause:

    SET set_rest {
        auto tmp1 = $2;
        res = new IR(kSetResetClause, OP3("SET", "", ""), tmp1);
        $$ = res;
    }

    | VariableResetStmt {
        auto tmp1 = $1;
        res = new IR(kSetResetClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

;

/* SetResetClause allows SET or RESET without LOCAL */

FunctionSetResetClause:

    SET set_rest_more {
        auto tmp1 = $2;
        res = new IR(kFunctionSetResetClause, OP3("SET", "", ""), tmp1);
        $$ = res;
    }

    | VariableResetStmt {
        auto tmp1 = $1;
        res = new IR(kFunctionSetResetClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

;



VariableShowStmt:

    SHOW var_name {
        auto tmp1 = $2;
        res = new IR(kVariableShowStmt, OP3("SHOW", "", ""), tmp1);
        $$ = res;
    }

    | SHOW TIME ZONE {
        res = new IR(kVariableShowStmt, string("SHOW TIME ZONE"));
        $$ = res;
    }

    | SHOW TRANSACTION ISOLATION LEVEL {
        res = new IR(kVariableShowStmt, string("SHOW TRANSACTION ISOLATION LEVEL"));
        $$ = res;
    }

    | SHOW SESSION AUTHORIZATION {
        res = new IR(kVariableShowStmt, string("SHOW SESSION AUTHORIZATION"));
        $$ = res;
    }

    | SHOW ALL {
        res = new IR(kVariableShowStmt, string("SHOW ALL"));
        $$ = res;
    }

;



ConstraintsSetStmt:

    SET CONSTRAINTS constraints_set_list constraints_set_mode {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kConstraintsSetStmt, OP3("SET CONSTRAINTS", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


constraints_set_list:

    ALL {
        res = new IR(kConstraintsSetList, string("ALL"));
        $$ = res;
    }

    | qualified_name_list {
        auto tmp1 = $1;
        res = new IR(kConstraintsSetList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


constraints_set_mode:

    DEFERRED {
        res = new IR(kConstraintsSetMode, string("DEFERRED"));
        $$ = res;
    }

    | IMMEDIATE {
        res = new IR(kConstraintsSetMode, string("IMMEDIATE"));
        $$ = res;
    }

;


/*
* Checkpoint statement
*/

CheckPointStmt:

    CHECKPOINT {
        res = new IR(kCheckPointStmt, string("CHECKPOINT"));
        $$ = res;
    }

;


/*****************************************************************************
*
* DISCARD { ALL | TEMP | PLANS | SEQUENCES }
*
*****************************************************************************/


DiscardStmt:

    DISCARD ALL {
        res = new IR(kDiscardStmt, string("DISCARD ALL"));
        $$ = res;
    }

    | DISCARD TEMP {
        res = new IR(kDiscardStmt, string("DISCARD TEMP"));
        $$ = res;
    }

    | DISCARD TEMPORARY {
        res = new IR(kDiscardStmt, string("DISCARD TEMPORARY"));
        $$ = res;
    }

    | DISCARD PLANS {
        res = new IR(kDiscardStmt, string("DISCARD PLANS"));
        $$ = res;
    }

    | DISCARD SEQUENCES {
        res = new IR(kDiscardStmt, string("DISCARD SEQUENCES"));
        $$ = res;
    }

;


/*****************************************************************************
*
*	ALTER [ TABLE | INDEX | SEQUENCE | VIEW | MATERIALIZED VIEW | FOREIGN TABLE ] variations
*
* Note: we accept all subcommands for each of the variants, and sort
* out what's really legal at execution time.
*****************************************************************************/


AlterTableStmt:

    ALTER TABLE relation_expr alter_table_cmds {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlterTableStmt, OP3("ALTER TABLE", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER TABLE IF_P EXISTS relation_expr alter_table_cmds {
        auto tmp1 = $5;
        auto tmp2 = $6;
        res = new IR(kAlterTableStmt, OP3("ALTER TABLE IF EXISTS", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER TABLE relation_expr partition_cmd {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlterTableStmt, OP3("ALTER TABLE", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER TABLE IF_P EXISTS relation_expr partition_cmd {
        auto tmp1 = $5;
        auto tmp2 = $6;
        res = new IR(kAlterTableStmt, OP3("ALTER TABLE IF EXISTS", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER TABLE ALL IN_P TABLESPACE name SET TABLESPACE name opt_nowait {
        auto tmp1 = $6;
        auto tmp2 = $9;
        res = new IR(kUnknown, OP3("ALTER TABLE ALL IN TABLESPACE", "SET TABLESPACE", ""), tmp1, tmp2);
        auto tmp3 = $10;
        res = new IR(kAlterTableStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER TABLE ALL IN_P TABLESPACE name OWNED BY role_list SET TABLESPACE name opt_nowait {
        auto tmp1 = $6;
        auto tmp2 = $9;
        res = new IR(kUnknown, OP3("ALTER TABLE ALL IN TABLESPACE", "OWNED BY", "SET TABLESPACE"), tmp1, tmp2);
        auto tmp3 = $12;
        res = new IR(kAlterTableStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER INDEX qualified_name alter_table_cmds {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlterTableStmt, OP3("ALTER INDEX", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER INDEX IF_P EXISTS qualified_name alter_table_cmds {
        auto tmp1 = $5;
        auto tmp2 = $6;
        res = new IR(kAlterTableStmt, OP3("ALTER INDEX IF EXISTS", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER INDEX qualified_name index_partition_cmd {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlterTableStmt, OP3("ALTER INDEX", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER INDEX ALL IN_P TABLESPACE name SET TABLESPACE name opt_nowait {
        auto tmp1 = $6;
        auto tmp2 = $9;
        res = new IR(kUnknown, OP3("ALTER INDEX ALL IN TABLESPACE", "SET TABLESPACE", ""), tmp1, tmp2);
        auto tmp3 = $10;
        res = new IR(kAlterTableStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER INDEX ALL IN_P TABLESPACE name OWNED BY role_list SET TABLESPACE name opt_nowait {
        auto tmp1 = $6;
        auto tmp2 = $9;
        res = new IR(kUnknown, OP3("ALTER INDEX ALL IN TABLESPACE", "OWNED BY", "SET TABLESPACE"), tmp1, tmp2);
        auto tmp3 = $12;
        res = new IR(kAlterTableStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER SEQUENCE qualified_name alter_table_cmds {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlterTableStmt, OP3("ALTER SEQUENCE", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER SEQUENCE IF_P EXISTS qualified_name alter_table_cmds {
        auto tmp1 = $5;
        auto tmp2 = $6;
        res = new IR(kAlterTableStmt, OP3("ALTER SEQUENCE IF EXISTS", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER VIEW qualified_name alter_table_cmds {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlterTableStmt, OP3("ALTER VIEW", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER VIEW IF_P EXISTS qualified_name alter_table_cmds {
        auto tmp1 = $5;
        auto tmp2 = $6;
        res = new IR(kAlterTableStmt, OP3("ALTER VIEW IF EXISTS", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER MATERIALIZED VIEW qualified_name alter_table_cmds {
        auto tmp1 = $4;
        auto tmp2 = $5;
        res = new IR(kAlterTableStmt, OP3("ALTER MATERIALIZED VIEW", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER MATERIALIZED VIEW IF_P EXISTS qualified_name alter_table_cmds {
        auto tmp1 = $6;
        auto tmp2 = $7;
        res = new IR(kAlterTableStmt, OP3("ALTER MATERIALIZED VIEW IF EXISTS", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER MATERIALIZED VIEW ALL IN_P TABLESPACE name SET TABLESPACE name opt_nowait {
        auto tmp1 = $7;
        auto tmp2 = $10;
        res = new IR(kUnknown, OP3("ALTER MATERIALIZED VIEW ALL IN TABLESPACE", "SET TABLESPACE", ""), tmp1, tmp2);
        auto tmp3 = $11;
        res = new IR(kAlterTableStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER MATERIALIZED VIEW ALL IN_P TABLESPACE name OWNED BY role_list SET TABLESPACE name opt_nowait {
        auto tmp1 = $7;
        auto tmp2 = $10;
        res = new IR(kUnknown, OP3("ALTER MATERIALIZED VIEW ALL IN TABLESPACE", "OWNED BY", "SET TABLESPACE"), tmp1, tmp2);
        auto tmp3 = $13;
        res = new IR(kAlterTableStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER FOREIGN TABLE relation_expr alter_table_cmds {
        auto tmp1 = $4;
        auto tmp2 = $5;
        res = new IR(kAlterTableStmt, OP3("ALTER FOREIGN TABLE", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER FOREIGN TABLE IF_P EXISTS relation_expr alter_table_cmds {
        auto tmp1 = $6;
        auto tmp2 = $7;
        res = new IR(kAlterTableStmt, OP3("ALTER FOREIGN TABLE IF EXISTS", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


alter_table_cmds:

    alter_table_cmd {
        auto tmp1 = $1;
        res = new IR(kAlterTableCmds, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | alter_table_cmds ',' alter_table_cmd {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAlterTableCmds, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


partition_cmd:

    /* ALTER TABLE <name> ATTACH PARTITION <table_name> FOR VALUES */ ATTACH PARTITION qualified_name PartitionBoundSpec /* ALTER TABLE <name> DETACH PARTITION <partition_name> [CONCURRENTLY] */ {
        auto tmp1 = $1;
        res = new IR(kPartitionCmd, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DETACH PARTITION qualified_name opt_concurrently {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kPartitionCmd, OP3("DETACH PARTITION", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | DETACH PARTITION qualified_name FINALIZE {
        auto tmp1 = $3;
        res = new IR(kPartitionCmd, OP3("DETACH PARTITION", "FINALIZE", ""), tmp1);
        $$ = res;
    }

;


index_partition_cmd:

    ATTACH PARTITION qualified_name {
        auto tmp1 = $3;
        res = new IR(kIndexPartitionCmd, OP3("ATTACH PARTITION", "", ""), tmp1);
        $$ = res;
    }

;


alter_table_cmd:

    ADD_P columnDef {
        auto tmp1 = $2;
        res = new IR(kAlterTableCmd, OP3("ADD", "", ""), tmp1);
        $$ = res;
    }

    | ADD_P IF_P NOT EXISTS columnDef {
        auto tmp1 = $5;
        res = new IR(kAlterTableCmd, OP3("ADD IF NOT EXISTS", "", ""), tmp1);
        $$ = res;
    }

    | ADD_P COLUMN columnDef {
        auto tmp1 = $3;
        res = new IR(kAlterTableCmd, OP3("ADD COLUMN", "", ""), tmp1);
        $$ = res;
    }

    | ADD_P COLUMN IF_P NOT EXISTS columnDef {
        auto tmp1 = $6;
        res = new IR(kAlterTableCmd, OP3("ADD COLUMN IF NOT EXISTS", "", ""), tmp1);
        $$ = res;
    }

    | ALTER opt_column ColId alter_column_default {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("ALTER", "", ""), tmp1, tmp2);
        auto tmp3 = $4;
        res = new IR(kAlterTableCmd, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER opt_column ColId DROP NOT NULL_P {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterTableCmd, OP3("ALTER", "", "DROP NOT NULL"), tmp1, tmp2);
        $$ = res;
    }

    | ALTER opt_column ColId SET NOT NULL_P {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterTableCmd, OP3("ALTER", "", "SET NOT NULL"), tmp1, tmp2);
        $$ = res;
    }

    | ALTER opt_column ColId DROP EXPRESSION {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterTableCmd, OP3("ALTER", "", "DROP EXPRESSION"), tmp1, tmp2);
        $$ = res;
    }

    | ALTER opt_column ColId DROP EXPRESSION IF_P EXISTS {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterTableCmd, OP3("ALTER", "", "DROP EXPRESSION IF EXISTS"), tmp1, tmp2);
        $$ = res;
    }

    | ALTER opt_column ColId SET STATISTICS SignedIconst {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("ALTER", "", "SET STATISTICS"), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kAlterTableCmd, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER opt_column Iconst SET STATISTICS SignedIconst {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("ALTER", "", "SET STATISTICS"), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kAlterTableCmd, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER opt_column ColId SET reloptions {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("ALTER", "", "SET"), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kAlterTableCmd, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER opt_column ColId RESET reloptions {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("ALTER", "", "RESET"), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kAlterTableCmd, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER opt_column ColId SET STORAGE ColId {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("ALTER", "", "SET STORAGE"), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kAlterTableCmd, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER opt_column ColId SET column_compression {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("ALTER", "", "SET"), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kAlterTableCmd, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER opt_column ColId ADD_P GENERATED generated_when AS IDENTITY_P OptParenthesizedSeqOptList {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("ALTER", "", "ADD GENERATED"), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kAlterTableCmd, OP3("", "AS IDENTITY", ""), res, tmp3);
        $$ = res;
    }

    | ALTER opt_column ColId alter_identity_column_option_list {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("ALTER", "", ""), tmp1, tmp2);
        auto tmp3 = $4;
        res = new IR(kAlterTableCmd, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER opt_column ColId DROP IDENTITY_P {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterTableCmd, OP3("ALTER", "", "DROP IDENTITY"), tmp1, tmp2);
        $$ = res;
    }

    | ALTER opt_column ColId DROP IDENTITY_P IF_P EXISTS {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterTableCmd, OP3("ALTER", "", "DROP IDENTITY IF EXISTS"), tmp1, tmp2);
        $$ = res;
    }

    | DROP opt_column IF_P EXISTS ColId opt_drop_behavior {
        auto tmp1 = $2;
        auto tmp2 = $5;
        res = new IR(kUnknown, OP3("DROP", "IF EXISTS", ""), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kAlterTableCmd, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | DROP opt_column ColId opt_drop_behavior {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("DROP", "", ""), tmp1, tmp2);
        auto tmp3 = $4;
        res = new IR(kAlterTableCmd, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER opt_column ColId opt_set_data TYPE_P Typename opt_collate_clause alter_using {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("ALTER", "", ""), tmp1, tmp2);
        auto tmp3 = $4;
        res = new IR(kUnknown, OP3("", "TYPE", ""), res, tmp3);
        auto tmp4 = $7;
        res = new IR(kAlterTableCmd, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | ALTER opt_column ColId alter_generic_options {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("ALTER", "", ""), tmp1, tmp2);
        auto tmp3 = $4;
        res = new IR(kAlterTableCmd, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ADD_P TableConstraint {
        auto tmp1 = $2;
        res = new IR(kAlterTableCmd, OP3("ADD", "", ""), tmp1);
        $$ = res;
    }

    | ALTER CONSTRAINT name ConstraintAttributeSpec {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlterTableCmd, OP3("ALTER CONSTRAINT", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | VALIDATE CONSTRAINT name {
        auto tmp1 = $3;
        res = new IR(kAlterTableCmd, OP3("VALIDATE CONSTRAINT", "", ""), tmp1);
        $$ = res;
    }

    | DROP CONSTRAINT IF_P EXISTS name opt_drop_behavior {
        auto tmp1 = $5;
        auto tmp2 = $6;
        res = new IR(kAlterTableCmd, OP3("DROP CONSTRAINT IF EXISTS", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | DROP CONSTRAINT name opt_drop_behavior {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlterTableCmd, OP3("DROP CONSTRAINT", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | SET WITHOUT OIDS {
        res = new IR(kAlterTableCmd, string("SET WITHOUT OIDS"));
        $$ = res;
    }

    | CLUSTER ON name {
        auto tmp1 = $3;
        res = new IR(kAlterTableCmd, OP3("CLUSTER ON", "", ""), tmp1);
        $$ = res;
    }

    | SET WITHOUT CLUSTER {
        res = new IR(kAlterTableCmd, string("SET WITHOUT CLUSTER"));
        $$ = res;
    }

    | SET LOGGED {
        res = new IR(kAlterTableCmd, string("SET LOGGED"));
        $$ = res;
    }

    | SET UNLOGGED {
        res = new IR(kAlterTableCmd, string("SET UNLOGGED"));
        $$ = res;
    }

    | ENABLE_P TRIGGER name {
        auto tmp1 = $3;
        res = new IR(kAlterTableCmd, OP3("ENABLE TRIGGER", "", ""), tmp1);
        $$ = res;
    }

    | ENABLE_P ALWAYS TRIGGER name {
        auto tmp1 = $4;
        res = new IR(kAlterTableCmd, OP3("ENABLE ALWAYS TRIGGER", "", ""), tmp1);
        $$ = res;
    }

    | ENABLE_P REPLICA TRIGGER name {
        auto tmp1 = $4;
        res = new IR(kAlterTableCmd, OP3("ENABLE REPLICA TRIGGER", "", ""), tmp1);
        $$ = res;
    }

    | ENABLE_P TRIGGER ALL {
        res = new IR(kAlterTableCmd, string("ENABLE TRIGGER ALL"));
        $$ = res;
    }

    | ENABLE_P TRIGGER USER {
        res = new IR(kAlterTableCmd, string("ENABLE TRIGGER USER"));
        $$ = res;
    }

    | DISABLE_P TRIGGER name {
        auto tmp1 = $3;
        res = new IR(kAlterTableCmd, OP3("DISABLE TRIGGER", "", ""), tmp1);
        $$ = res;
    }

    | DISABLE_P TRIGGER ALL {
        res = new IR(kAlterTableCmd, string("DISABLE TRIGGER ALL"));
        $$ = res;
    }

    | DISABLE_P TRIGGER USER {
        res = new IR(kAlterTableCmd, string("DISABLE TRIGGER USER"));
        $$ = res;
    }

    | ENABLE_P RULE name {
        auto tmp1 = $3;
        res = new IR(kAlterTableCmd, OP3("ENABLE RULE", "", ""), tmp1);
        $$ = res;
    }

    | ENABLE_P ALWAYS RULE name {
        auto tmp1 = $4;
        res = new IR(kAlterTableCmd, OP3("ENABLE ALWAYS RULE", "", ""), tmp1);
        $$ = res;
    }

    | ENABLE_P REPLICA RULE name {
        auto tmp1 = $4;
        res = new IR(kAlterTableCmd, OP3("ENABLE REPLICA RULE", "", ""), tmp1);
        $$ = res;
    }

    | DISABLE_P RULE name {
        auto tmp1 = $3;
        res = new IR(kAlterTableCmd, OP3("DISABLE RULE", "", ""), tmp1);
        $$ = res;
    }

    | INHERIT qualified_name {
        auto tmp1 = $2;
        res = new IR(kAlterTableCmd, OP3("INHERIT", "", ""), tmp1);
        $$ = res;
    }

    | NO INHERIT qualified_name {
        auto tmp1 = $3;
        res = new IR(kAlterTableCmd, OP3("NO INHERIT", "", ""), tmp1);
        $$ = res;
    }

    | OF any_name {
        auto tmp1 = $2;
        res = new IR(kAlterTableCmd, OP3("OF", "", ""), tmp1);
        $$ = res;
    }

    | NOT OF {
        res = new IR(kAlterTableCmd, string("NOT OF"));
        $$ = res;
    }

    | OWNER TO RoleSpec {
        auto tmp1 = $3;
        res = new IR(kAlterTableCmd, OP3("OWNER TO", "", ""), tmp1);
        $$ = res;
    }

    | SET TABLESPACE name {
        auto tmp1 = $3;
        res = new IR(kAlterTableCmd, OP3("SET TABLESPACE", "", ""), tmp1);
        $$ = res;
    }

    | SET reloptions {
        auto tmp1 = $2;
        res = new IR(kAlterTableCmd, OP3("SET", "", ""), tmp1);
        $$ = res;
    }

    | RESET reloptions {
        auto tmp1 = $2;
        res = new IR(kAlterTableCmd, OP3("RESET", "", ""), tmp1);
        $$ = res;
    }

    | REPLICA IDENTITY_P replica_identity {
        auto tmp1 = $3;
        res = new IR(kAlterTableCmd, OP3("REPLICA IDENTITY", "", ""), tmp1);
        $$ = res;
    }

    | ENABLE_P ROW LEVEL SECURITY {
        res = new IR(kAlterTableCmd, string("ENABLE ROW LEVEL SECURITY"));
        $$ = res;
    }

    | DISABLE_P ROW LEVEL SECURITY {
        res = new IR(kAlterTableCmd, string("DISABLE ROW LEVEL SECURITY"));
        $$ = res;
    }

    | FORCE ROW LEVEL SECURITY {
        res = new IR(kAlterTableCmd, string("FORCE ROW LEVEL SECURITY"));
        $$ = res;
    }

    | NO FORCE ROW LEVEL SECURITY {
        res = new IR(kAlterTableCmd, string("NO FORCE ROW LEVEL SECURITY"));
        $$ = res;
    }

    | alter_generic_options {
        auto tmp1 = $1;
        res = new IR(kAlterTableCmd, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


alter_column_default:

    SET DEFAULT a_expr {
        auto tmp1 = $3;
        res = new IR(kAlterColumnDefault, OP3("SET DEFAULT", "", ""), tmp1);
        $$ = res;
    }

    | DROP DEFAULT {
        res = new IR(kAlterColumnDefault, string("DROP DEFAULT"));
        $$ = res;
    }

;


opt_drop_behavior:

    CASCADE {
        res = new IR(kOptDropBehavior, string("CASCADE"));
        $$ = res;
    }

    | RESTRICT {
        res = new IR(kOptDropBehavior, string("RESTRICT"));
        $$ = res;
    }

    | /* EMPTY */ {
        res = new IR(kOptDropBehavior, string(""));
        $$ = res;
    }

;


opt_collate_clause:

    COLLATE any_name {
        auto tmp1 = $2;
        res = new IR(kOptCollateClause, OP3("COLLATE", "", ""), tmp1);
        $$ = res;
    }

    | /* EMPTY */ {
        res = new IR(kOptCollateClause, string(""));
        $$ = res;
    }

;


alter_using:

    USING a_expr {
        auto tmp1 = $2;
        res = new IR(kAlterUsing, OP3("USING", "", ""), tmp1);
        $$ = res;
    }

    | /* EMPTY */ {
        res = new IR(kAlterUsing, string(""));
        $$ = res;
    }

;


replica_identity:

    NOTHING {
        res = new IR(kReplicaIdentity, string("NOTHING"));
        $$ = res;
    }

    | FULL {
        res = new IR(kReplicaIdentity, string("FULL"));
        $$ = res;
    }

    | DEFAULT {
        res = new IR(kReplicaIdentity, string("DEFAULT"));
        $$ = res;
    }

    | USING INDEX name {
        auto tmp1 = $3;
        res = new IR(kReplicaIdentity, OP3("USING INDEX", "", ""), tmp1);
        $$ = res;
    }

;


reloptions:

    reloption_list ')' {
        auto tmp1 = $1;
        res = new IR(kReloptions, OP3("", ")", ""), tmp1);
        $$ = res;
    }

;


opt_reloptions:

    WITH reloptions {
        auto tmp1 = $2;
        res = new IR(kOptReloptions, OP3("WITH", "", ""), tmp1);
        $$ = res;
    }

    | /* EMPTY */ {
        res = new IR(kOptReloptions, string(""));
        $$ = res;
    }

;


reloption_list:

    reloption_elem {
        auto tmp1 = $1;
        res = new IR(kReloptionList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | reloption_list ',' reloption_elem {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kReloptionList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;

/* This should match def_elem and also allow qualified names */

reloption_elem:

    ColLabel '=' def_arg {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kReloptionElem, OP3("", "=", ""), tmp1, tmp2);
        $$ = res;
    }

    | ColLabel {
        auto tmp1 = $1;
        res = new IR(kReloptionElem, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ColLabel '.' ColLabel '=' def_arg {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("", ".", "="), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kReloptionElem, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ColLabel '.' ColLabel {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kReloptionElem, OP3("", ".", ""), tmp1, tmp2);
        $$ = res;
    }

;


alter_identity_column_option_list:

    alter_identity_column_option {
        auto tmp1 = $1;
        res = new IR(kAlterIdentityColumnOptionList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | alter_identity_column_option_list alter_identity_column_option {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAlterIdentityColumnOptionList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


alter_identity_column_option:

    RESTART {
        res = new IR(kAlterIdentityColumnOption, string("RESTART"));
        $$ = res;
    }

    | RESTART opt_with NumericOnly {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterIdentityColumnOption, OP3("RESTART", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | SET SeqOptElem {
        auto tmp1 = $2;
        res = new IR(kAlterIdentityColumnOption, OP3("SET", "", ""), tmp1);
        $$ = res;
    }

    | SET GENERATED generated_when {
        auto tmp1 = $3;
        res = new IR(kAlterIdentityColumnOption, OP3("SET GENERATED", "", ""), tmp1);
        $$ = res;
    }

;


PartitionBoundSpec:

    FOR VALUES WITH '(' hash_partbound ')' {
        auto tmp1 = $5;
        res = new IR(kPartitionBoundSpec, OP3("FOR VALUES WITH (", ")", ""), tmp1);
        $$ = res;
    }

    | FOR VALUES IN_P '(' expr_list ')' {
        auto tmp1 = $5;
        res = new IR(kPartitionBoundSpec, OP3("FOR VALUES IN (", ")", ""), tmp1);
        $$ = res;
    }

    | FOR VALUES FROM '(' expr_list ')' TO '(' expr_list ')' {
        auto tmp1 = $5;
        auto tmp2 = $9;
        res = new IR(kPartitionBoundSpec, OP3("FOR VALUES FROM (", ") TO (", ")"), tmp1, tmp2);
        $$ = res;
    }

    | DEFAULT {
        res = new IR(kPartitionBoundSpec, string("DEFAULT"));
        $$ = res;
    }

;


hash_partbound_elem:

    NonReservedWord Iconst {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kHashPartboundElem, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


hash_partbound:

    hash_partbound_elem {
        auto tmp1 = $1;
        res = new IR(kHashPartbound, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | hash_partbound ',' hash_partbound_elem {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kHashPartbound, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;

/*****************************************************************************
*
*	ALTER TYPE
*
* really variants of the ALTER TABLE subcommands with different spellings
*****************************************************************************/


AlterCompositeTypeStmt:

    ALTER TYPE_P any_name alter_type_cmds {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlterCompositeTypeStmt, OP3("ALTER TYPE", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


alter_type_cmds:

    alter_type_cmd {
        auto tmp1 = $1;
        res = new IR(kAlterTypeCmds, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | alter_type_cmds ',' alter_type_cmd {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAlterTypeCmds, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


alter_type_cmd:

    ADD_P ATTRIBUTE TableFuncElement opt_drop_behavior {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlterTypeCmd, OP3("ADD ATTRIBUTE", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | DROP ATTRIBUTE IF_P EXISTS ColId opt_drop_behavior {
        auto tmp1 = $5;
        auto tmp2 = $6;
        res = new IR(kAlterTypeCmd, OP3("DROP ATTRIBUTE IF EXISTS", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | DROP ATTRIBUTE ColId opt_drop_behavior {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlterTypeCmd, OP3("DROP ATTRIBUTE", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER ATTRIBUTE ColId opt_set_data TYPE_P Typename opt_collate_clause opt_drop_behavior {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("ALTER ATTRIBUTE", "", "TYPE"), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp3);
        auto tmp4 = $8;
        res = new IR(kAlterTypeCmd, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


/*****************************************************************************
*
*		QUERY :
*				close <portalname>
*
*****************************************************************************/


ClosePortalStmt:

    CLOSE cursor_name {
        auto tmp1 = $2;
        res = new IR(kClosePortalStmt, OP3("CLOSE", "", ""), tmp1);
        $$ = res;
    }

    | CLOSE ALL {
        res = new IR(kClosePortalStmt, string("CLOSE ALL"));
        $$ = res;
    }

;


/*****************************************************************************
*
*		QUERY :
*				COPY relname [(columnList)] FROM/TO file [WITH] [(options)]
*				COPY ( query ) TO file	[WITH] [(options)]
*
*				where 'query' can be one of:
*				{ SELECT | UPDATE | INSERT | DELETE }
*
*				and 'file' can be one of:
*				{ PROGRAM 'command' | STDIN | STDOUT | 'filename' }
*
*				In the preferred syntax the options are comma-separated
*				and use generic identifiers instead of keywords.  The pre-9.0
*				syntax had a hard-wired, space-separated set of options.
*
*				Really old syntax, from versions 7.2 and prior:
*				COPY [ BINARY ] table FROM/TO file
*					[ [ USING ] DELIMITERS 'delimiter' ] ]
*					[ WITH NULL AS 'null string' ]
*				This option placement is not supported with COPY (query...).
*
*****************************************************************************/


CopyStmt:

    COPY opt_binary qualified_name opt_column_list copy_from opt_program copy_file_name copy_delimiter opt_with copy_options where_clause {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("COPY", "", ""), tmp1, tmp2);
        auto tmp3 = $4;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp3);
        auto tmp4 = $6;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp4);
        auto tmp5 = $8;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp5);
        auto tmp6 = $10;
        res = new IR(kCopyStmt, OP3("", "", ""), res, tmp6);
        $$ = res;
    }

    | COPY '(' PreparableStmt ')' TO opt_program copy_file_name opt_with copy_options {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kUnknown, OP3("COPY (", ") TO", ""), tmp1, tmp2);
        auto tmp3 = $7;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp3);
        auto tmp4 = $9;
        res = new IR(kCopyStmt, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


copy_from:

    FROM {
        res = new IR(kCopyFrom, string("FROM"));
        $$ = res;
    }

    | TO {
        res = new IR(kCopyFrom, string("TO"));
        $$ = res;
    }

;


opt_program:

    PROGRAM {
        res = new IR(kOptProgram, string("PROGRAM"));
        $$ = res;
    }

    | /* EMPTY */ {
        res = new IR(kOptProgram, string(""));
        $$ = res;
    }

;

/*
* copy_file_name NULL indicates stdio is used. Whether stdin or stdout is
* used depends on the direction. (It really doesn't make sense to copy from
* stdout. We silently correct the "typo".)		 - AY 9/94
*/

copy_file_name:

    Sconst {
        auto tmp1 = $1;
        res = new IR(kCopyFileName, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | STDIN {
        res = new IR(kCopyFileName, string("STDIN"));
        $$ = res;
    }

    | STDOUT {
        res = new IR(kCopyFileName, string("STDOUT"));
        $$ = res;
    }

;


copy_options:

    copy_opt_list {
        auto tmp1 = $1;
        res = new IR(kCopyOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '(' copy_generic_opt_list ')' {
        auto tmp1 = $2;
        res = new IR(kCopyOptions, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

;

/* old COPY option syntax */

copy_opt_list:

    copy_opt_list copy_opt_item {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCopyOptList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | /* EMPTY */ {
        res = new IR(kCopyOptList, string(""));
        $$ = res;
    }

;


copy_opt_item:

    BINARY {
        res = new IR(kCopyOptItem, string("BINARY"));
        $$ = res;
    }

    | FREEZE {
        res = new IR(kCopyOptItem, string("FREEZE"));
        $$ = res;
    }

    | DELIMITER opt_as Sconst {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCopyOptItem, OP3("DELIMITER", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | NULL_P opt_as Sconst {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCopyOptItem, OP3("NULL", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | CSV {
        res = new IR(kCopyOptItem, string("CSV"));
        $$ = res;
    }

    | HEADER_P {
        res = new IR(kCopyOptItem, string("HEADER"));
        $$ = res;
    }

    | QUOTE opt_as Sconst {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCopyOptItem, OP3("QUOTE", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ESCAPE opt_as Sconst {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCopyOptItem, OP3("ESCAPE", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | FORCE QUOTE columnList {
        auto tmp1 = $3;
        res = new IR(kCopyOptItem, OP3("FORCE QUOTE", "", ""), tmp1);
        $$ = res;
    }

    | FORCE QUOTE '*' {
        res = new IR(kCopyOptItem, string("FORCE QUOTE *"));
        $$ = res;
    }

    | FORCE NOT NULL_P columnList {
        auto tmp1 = $4;
        res = new IR(kCopyOptItem, OP3("FORCE NOT NULL", "", ""), tmp1);
        $$ = res;
    }

    | FORCE NULL_P columnList {
        auto tmp1 = $3;
        res = new IR(kCopyOptItem, OP3("FORCE NULL", "", ""), tmp1);
        $$ = res;
    }

    | ENCODING Sconst {
        auto tmp1 = $2;
        res = new IR(kCopyOptItem, OP3("ENCODING", "", ""), tmp1);
        $$ = res;
    }

;

/* The following exist for backward compatibility with very old versions */


opt_binary:

    BINARY {
        res = new IR(kOptBinary, string("BINARY"));
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptBinary, string(""));
        $$ = res;
    }

;


copy_delimiter:

    opt_using DELIMITERS Sconst {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kCopyDelimiter, OP3("", "DELIMITERS", ""), tmp1, tmp2);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kCopyDelimiter, string(""));
        $$ = res;
    }

;

opt_using:
    USING { 
        $$ = new IR(kOptUsing, OP3("USING", "", ""));
    }
    | /*EMPTY*/ {
        $$ = new IR(kOptUsing, OP0());
    }
;

/* new COPY option syntax */

copy_generic_opt_list:

    copy_generic_opt_elem {
        auto tmp1 = $1;
        res = new IR(kCopyGenericOptList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | copy_generic_opt_list ',' copy_generic_opt_elem {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kCopyGenericOptList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


copy_generic_opt_elem:

    ColLabel copy_generic_opt_arg {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCopyGenericOptElem, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


copy_generic_opt_arg:

    opt_boolean_or_string {
        auto tmp1 = $1;
        res = new IR(kCopyGenericOptArg, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | NumericOnly {
        auto tmp1 = $1;
        res = new IR(kCopyGenericOptArg, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '*' {
        res = new IR(kCopyGenericOptArg, string("*"));
        $$ = res;
    }

    | '(' copy_generic_opt_arg_list ')' {
        auto tmp1 = $2;
        res = new IR(kCopyGenericOptArg, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

    | /* EMPTY */ {
        res = new IR(kCopyGenericOptArg, string(""));
        $$ = res;
    }

;


copy_generic_opt_arg_list:

    copy_generic_opt_arg_list_item {
        auto tmp1 = $1;
        res = new IR(kCopyGenericOptArgList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | copy_generic_opt_arg_list ',' copy_generic_opt_arg_list_item {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kCopyGenericOptArgList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;

/* beware of emitting non-string list elements here; see commands/define.c */

copy_generic_opt_arg_list_item:

    opt_boolean_or_string {
        auto tmp1 = $1;
        res = new IR(kCopyGenericOptArgListItem, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


/*****************************************************************************
*
*		QUERY :
*				CREATE TABLE relname
*
*****************************************************************************/


CreateStmt:

    CREATE OptTemp TABLE qualified_name '(' OptTableElementList ')' OptInherit OptPartitionSpec table_access_method_clause OptWith OnCommitOption OptTableSpace {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("CREATE", "TABLE", "("), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kUnknown, OP3("", ")", ""), res, tmp3);
        auto tmp4 = $9;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp4);
        auto tmp5 = $11;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp5);
        auto tmp6 = $13;
        res = new IR(kCreateStmt, OP3("", "", ""), res, tmp6);
        $$ = res;
    }

    | CREATE OptTemp TABLE IF_P NOT EXISTS qualified_name '(' OptTableElementList ')' OptInherit OptPartitionSpec table_access_method_clause OptWith OnCommitOption OptTableSpace {
        auto tmp1 = $2;
        auto tmp2 = $7;
        res = new IR(kUnknown, OP3("CREATE", "TABLE IF NOT EXISTS", "("), tmp1, tmp2);
        auto tmp3 = $9;
        res = new IR(kUnknown, OP3("", ")", ""), res, tmp3);
        auto tmp4 = $12;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp4);
        auto tmp5 = $14;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp5);
        auto tmp6 = $16;
        res = new IR(kCreateStmt, OP3("", "", ""), res, tmp6);
        $$ = res;
    }

    | CREATE OptTemp TABLE qualified_name OF any_name OptTypedTableElementList OptPartitionSpec table_access_method_clause OptWith OnCommitOption OptTableSpace {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("CREATE", "TABLE", "OF"), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp3);
        auto tmp4 = $8;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp4);
        auto tmp5 = $10;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp5);
        auto tmp6 = $12;
        res = new IR(kCreateStmt, OP3("", "", ""), res, tmp6);
        $$ = res;
    }

    | CREATE OptTemp TABLE IF_P NOT EXISTS qualified_name OF any_name OptTypedTableElementList OptPartitionSpec table_access_method_clause OptWith OnCommitOption OptTableSpace {
        auto tmp1 = $2;
        auto tmp2 = $7;
        res = new IR(kUnknown, OP3("CREATE", "TABLE IF NOT EXISTS", "OF"), tmp1, tmp2);
        auto tmp3 = $9;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp3);
        auto tmp4 = $11;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp4);
        auto tmp5 = $13;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp5);
        auto tmp6 = $15;
        res = new IR(kCreateStmt, OP3("", "", ""), res, tmp6);
        $$ = res;
    }

    | CREATE OptTemp TABLE qualified_name PARTITION OF qualified_name OptTypedTableElementList PartitionBoundSpec OptPartitionSpec table_access_method_clause OptWith OnCommitOption OptTableSpace {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("CREATE", "TABLE", "PARTITION OF"), tmp1, tmp2);
        auto tmp3 = $7;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp3);
        auto tmp4 = $9;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp4);
        auto tmp5 = $11;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp5);
        auto tmp6 = $13;
        res = new IR(kCreateStmt, OP3("", "", ""), res, tmp6);
        $$ = res;
    }

    | CREATE OptTemp TABLE IF_P NOT EXISTS qualified_name PARTITION OF qualified_name OptTypedTableElementList PartitionBoundSpec OptPartitionSpec table_access_method_clause OptWith OnCommitOption OptTableSpace {
        auto tmp1 = $2;
        auto tmp2 = $7;
        res = new IR(kUnknown, OP3("CREATE", "TABLE IF NOT EXISTS", "PARTITION OF"), tmp1, tmp2);
        auto tmp3 = $10;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp3);
        auto tmp4 = $12;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp4);
        auto tmp5 = $14;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp5);
        auto tmp6 = $16;
        res = new IR(kCreateStmt, OP3("", "", ""), res, tmp6);
        $$ = res;
    }

;

/*
* Redundancy here is needed to avoid shift/reduce conflicts,
* since TEMP is not a reserved word.  See also OptTempTableName.
*
* NOTE: we accept both GLOBAL and LOCAL options.  They currently do nothing,
* but future versions might consider GLOBAL to request SQL-spec-compliant
* temp table behavior, so warn about that.  Since we have no modules the
* LOCAL keyword is really meaningless; furthermore, some other products
* implement LOCAL as meaning the same as our default temp table behavior,
* so we'll probably continue to treat LOCAL as a noise word.
*/

OptTemp:

    TEMPORARY {
        res = new IR(kOptTemp, string("TEMPORARY"));
        $$ = res;
    }

    | TEMP {
        res = new IR(kOptTemp, string("TEMP"));
        $$ = res;
    }

    | LOCAL TEMPORARY {
        res = new IR(kOptTemp, string("LOCAL TEMPORARY"));
        $$ = res;
    }

    | LOCAL TEMP {
        res = new IR(kOptTemp, string("LOCAL TEMP"));
        $$ = res;
    }

    | GLOBAL TEMPORARY {
        res = new IR(kOptTemp, string("GLOBAL TEMPORARY"));
        $$ = res;
    }

    | GLOBAL TEMP {
        res = new IR(kOptTemp, string("GLOBAL TEMP"));
        $$ = res;
    }

    | UNLOGGED {
        res = new IR(kOptTemp, string("UNLOGGED"));
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptTemp, string(""));
        $$ = res;
    }

;


OptTableElementList:

    TableElementList {
        auto tmp1 = $1;
        res = new IR(kOptTableElementList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptTableElementList, string(""));
        $$ = res;
    }

;


OptTypedTableElementList:

    TypedTableElementList ')' {
        auto tmp1 = $1;
        res = new IR(kOptTypedTableElementList, OP3("", ")", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptTypedTableElementList, string(""));
        $$ = res;
    }

;


TableElementList:

    TableElement {
        auto tmp1 = $1;
        res = new IR(kTableElementList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | TableElementList ',' TableElement {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTableElementList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


TypedTableElementList:

    TypedTableElement {
        auto tmp1 = $1;
        res = new IR(kTypedTableElementList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | TypedTableElementList ',' TypedTableElement {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTypedTableElementList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


TableElement:

    columnDef {
        auto tmp1 = $1;
        res = new IR(kTableElement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | TableLikeClause {
        auto tmp1 = $1;
        res = new IR(kTableElement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | TableConstraint {
        auto tmp1 = $1;
        res = new IR(kTableElement, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


TypedTableElement:

    columnOptions {
        auto tmp1 = $1;
        res = new IR(kTypedTableElement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | TableConstraint {
        auto tmp1 = $1;
        res = new IR(kTypedTableElement, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


columnDef:

    ColId Typename opt_column_compression create_generic_options ColQualList {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUnknown, OP3("", "", ""), tmp1, tmp2);
        auto tmp3 = $3;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp3);
        auto tmp4 = $5;
        res = new IR(kColumnDef, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


columnOptions:

    ColId ColQualList {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kColumnOptions, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ColId WITH OPTIONS ColQualList {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kColumnOptions, OP3("", "WITH OPTIONS", ""), tmp1, tmp2);
        $$ = res;
    }

;


column_compression:

    COMPRESSION ColId {
        auto tmp1 = $2;
        res = new IR(kColumnCompression, OP3("COMPRESSION", "", ""), tmp1);
        $$ = res;
    }

    | COMPRESSION DEFAULT {
        res = new IR(kColumnCompression, string("COMPRESSION DEFAULT"));
        $$ = res;
    }

;


opt_column_compression:

    column_compression {
        auto tmp1 = $1;
        res = new IR(kOptColumnCompression, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptColumnCompression, string(""));
        $$ = res;
    }

;


ColQualList:

    ColQualList ColConstraint {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kColQualList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kColQualList, string(""));
        $$ = res;
    }

;


ColConstraint:

    CONSTRAINT name ColConstraintElem {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kColConstraint, OP3("CONSTRAINT", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ColConstraintElem {
        auto tmp1 = $1;
        res = new IR(kColConstraint, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ConstraintAttr {
        auto tmp1 = $1;
        res = new IR(kColConstraint, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | COLLATE any_name {
        auto tmp1 = $2;
        res = new IR(kColConstraint, OP3("COLLATE", "", ""), tmp1);
        $$ = res;
    }

;

/* DEFAULT NULL is already the default for Postgres.
* But define it here and carry it forward into the system
* to make it explicit.
* - thomas 1998-09-13
*
* WITH NULL and NULL are not SQL-standard syntax elements,
* so leave them out. Use DEFAULT NULL to explicitly indicate
* that a column may have that value. WITH NULL leads to
* shift/reduce conflicts with WITH TIME ZONE anyway.
* - thomas 1999-01-08
*
* DEFAULT expression must be b_expr not a_expr to prevent shift/reduce
* conflict on NOT (since NOT might start a subsequent NOT NULL constraint,
* or be part of a_expr NOT LIKE or similar constructs).
*/

ColConstraintElem:

    NOT NULL_P {
        res = new IR(kColConstraintElem, string("NOT NULL"));
        $$ = res;
    }

    | NULL_P {
        res = new IR(kColConstraintElem, string("NULL"));
        $$ = res;
    }

    | UNIQUE opt_definition OptConsTableSpace {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kColConstraintElem, OP3("UNIQUE", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | PRIMARY KEY opt_definition OptConsTableSpace {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kColConstraintElem, OP3("PRIMARY KEY", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | CHECK '(' a_expr ')' opt_no_inherit {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kColConstraintElem, OP3("CHECK (", ")", ""), tmp1, tmp2);
        $$ = res;
    }

    | DEFAULT b_expr {
        auto tmp1 = $2;
        res = new IR(kColConstraintElem, OP3("DEFAULT", "", ""), tmp1);
        $$ = res;
    }

    | GENERATED generated_when AS IDENTITY_P OptParenthesizedSeqOptList {
        auto tmp1 = $2;
        auto tmp2 = $5;
        res = new IR(kColConstraintElem, OP3("GENERATED", "AS IDENTITY", ""), tmp1, tmp2);
        $$ = res;
    }

    | GENERATED generated_when AS '(' a_expr ')' STORED {
        auto tmp1 = $2;
        auto tmp2 = $5;
        res = new IR(kColConstraintElem, OP3("GENERATED", "AS (", ") STORED"), tmp1, tmp2);
        $$ = res;
    }

    | REFERENCES qualified_name opt_column_list key_match key_actions {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("REFERENCES", "", ""), tmp1, tmp2);
        auto tmp3 = $4;
        res = new IR(kColConstraintElem, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


generated_when:

    ALWAYS {
        res = new IR(kGeneratedWhen, string("ALWAYS"));
        $$ = res;
    }

    | BY DEFAULT {
        res = new IR(kGeneratedWhen, string("BY DEFAULT"));
        $$ = res;
    }

;

/*
* ConstraintAttr represents constraint attributes, which we parse as if
* they were independent constraint clauses, in order to avoid shift/reduce
* conflicts (since NOT might start either an independent NOT NULL clause
* or an attribute).  parse_utilcmd.c is responsible for attaching the
* attribute information to the preceding "real" constraint node, and for
* complaining if attribute clauses appear in the wrong place or wrong
* combinations.
*
* See also ConstraintAttributeSpec, which can be used in places where
* there is no parsing conflict.  (Note: currently, NOT VALID and NO INHERIT
* are allowed clauses in ConstraintAttributeSpec, but not here.  Someday we
* might need to allow them here too, but for the moment it doesn't seem
* useful in the statements that use ConstraintAttr.)
*/

ConstraintAttr:

    DEFERRABLE {
        res = new IR(kConstraintAttr, string("DEFERRABLE"));
        $$ = res;
    }

    | NOT DEFERRABLE {
        res = new IR(kConstraintAttr, string("NOT DEFERRABLE"));
        $$ = res;
    }

    | INITIALLY DEFERRED {
        res = new IR(kConstraintAttr, string("INITIALLY DEFERRED"));
        $$ = res;
    }

    | INITIALLY IMMEDIATE {
        res = new IR(kConstraintAttr, string("INITIALLY IMMEDIATE"));
        $$ = res;
    }

;



TableLikeClause:

    LIKE qualified_name TableLikeOptionList {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kTableLikeClause, OP3("LIKE", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


TableLikeOptionList:

    TableLikeOptionList INCLUDING TableLikeOption {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTableLikeOptionList, OP3("", "INCLUDING", ""), tmp1, tmp2);
        $$ = res;
    }

    | TableLikeOptionList EXCLUDING TableLikeOption {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTableLikeOptionList, OP3("", "EXCLUDING", ""), tmp1, tmp2);
        $$ = res;
    }

    | /* EMPTY */ {
        res = new IR(kTableLikeOptionList, string(""));
        $$ = res;
    }

;


TableLikeOption:

    COMMENTS {
        res = new IR(kTableLikeOption, string("COMMENTS"));
        $$ = res;
    }

    | COMPRESSION {
        res = new IR(kTableLikeOption, string("COMPRESSION"));
        $$ = res;
    }

    | CONSTRAINTS {
        res = new IR(kTableLikeOption, string("CONSTRAINTS"));
        $$ = res;
    }

    | DEFAULTS {
        res = new IR(kTableLikeOption, string("DEFAULTS"));
        $$ = res;
    }

    | IDENTITY_P {
        res = new IR(kTableLikeOption, string("IDENTITY"));
        $$ = res;
    }

    | GENERATED {
        res = new IR(kTableLikeOption, string("GENERATED"));
        $$ = res;
    }

    | INDEXES {
        res = new IR(kTableLikeOption, string("INDEXES"));
        $$ = res;
    }

    | STATISTICS {
        res = new IR(kTableLikeOption, string("STATISTICS"));
        $$ = res;
    }

    | STORAGE {
        res = new IR(kTableLikeOption, string("STORAGE"));
        $$ = res;
    }

    | ALL {
        res = new IR(kTableLikeOption, string("ALL"));
        $$ = res;
    }

;


/* ConstraintElem specifies constraint syntax which is not embedded into
*	a column definition. ColConstraintElem specifies the embedded form.
* - thomas 1997-12-03
*/

TableConstraint:

    CONSTRAINT name ConstraintElem {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kTableConstraint, OP3("CONSTRAINT", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ConstraintElem {
        auto tmp1 = $1;
        res = new IR(kTableConstraint, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


ConstraintElem:

    CHECK '(' a_expr ')' ConstraintAttributeSpec {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kConstraintElem, OP3("CHECK (", ")", ""), tmp1, tmp2);
        $$ = res;
    }

    | UNIQUE '(' columnList ')' opt_c_include opt_definition OptConsTableSpace ConstraintAttributeSpec {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kUnknown, OP3("UNIQUE (", ")", ""), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp3);
        auto tmp4 = $8;
        res = new IR(kConstraintElem, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | UNIQUE ExistingIndex ConstraintAttributeSpec {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kConstraintElem, OP3("UNIQUE", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | PRIMARY KEY '(' columnList ')' opt_c_include opt_definition OptConsTableSpace ConstraintAttributeSpec {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kUnknown, OP3("PRIMARY KEY (", ")", ""), tmp1, tmp2);
        auto tmp3 = $7;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp3);
        auto tmp4 = $9;
        res = new IR(kConstraintElem, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | PRIMARY KEY ExistingIndex ConstraintAttributeSpec {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kConstraintElem, OP3("PRIMARY KEY", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | EXCLUDE access_method_clause '(' ExclusionConstraintList ')' opt_c_include opt_definition OptConsTableSpace OptWhereClause ConstraintAttributeSpec {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("EXCLUDE", "(", ")"), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp3);
        auto tmp4 = $8;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp4);
        auto tmp5 = $10;
        res = new IR(kConstraintElem, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

    | FOREIGN KEY '(' columnList ')' REFERENCES qualified_name opt_column_list key_match key_actions ConstraintAttributeSpec {
        auto tmp1 = $4;
        auto tmp2 = $7;
        res = new IR(kUnknown, OP3("FOREIGN KEY (", ") REFERENCES", ""), tmp1, tmp2);
        auto tmp3 = $8;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp3);
        auto tmp4 = $10;
        res = new IR(kConstraintElem, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


opt_no_inherit:

    NO INHERIT {
        res = new IR(kOptNoInherit, string("NO INHERIT"));
        $$ = res;
    }

    | /* EMPTY */ {
        res = new IR(kOptNoInherit, string(""));
        $$ = res;
    }

;


opt_column_list:

    columnList ')' {
        auto tmp1 = $1;
        res = new IR(kOptColumnList, OP3("", ")", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptColumnList, string(""));
        $$ = res;
    }

;


columnList:

    columnElem {
        auto tmp1 = $1;
        res = new IR(kColumnList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | columnList ',' columnElem {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kColumnList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


columnElem:

    ColId {
        auto tmp1 = $1;
        res = new IR(kColumnElem, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_c_include:

    INCLUDE '(' columnList ')' {
        auto tmp1 = $3;
        res = new IR(kOptCInclude, OP3("INCLUDE (", ")", ""), tmp1);
        $$ = res;
    }

    | /* EMPTY */ {
        res = new IR(kOptCInclude, string(""));
        $$ = res;
    }

;


key_match:

    MATCH FULL {
        res = new IR(kKeyMatch, string("MATCH FULL"));
        $$ = res;
    }

    | MATCH PARTIAL {
        res = new IR(kKeyMatch, string("MATCH PARTIAL"));
        $$ = res;
    }

    | MATCH SIMPLE {
        res = new IR(kKeyMatch, string("MATCH SIMPLE"));
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kKeyMatch, string(""));
        $$ = res;
    }

;


ExclusionConstraintList:

    ExclusionConstraintElem {
        auto tmp1 = $1;
        res = new IR(kExclusionConstraintList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ExclusionConstraintList ',' ExclusionConstraintElem {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kExclusionConstraintList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


ExclusionConstraintElem:

    index_elem WITH any_operator {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kExclusionConstraintElem, OP3("", "WITH", ""), tmp1, tmp2);
        $$ = res;
    }

    | index_elem WITH OPERATOR '(' any_operator ')' {
        auto tmp1 = $1;
        auto tmp2 = $5;
        res = new IR(kExclusionConstraintElem, OP3("", "WITH OPERATOR (", ")"), tmp1, tmp2);
        $$ = res;
    }

;


OptWhereClause:

    WHERE '(' a_expr ')' {
        auto tmp1 = $3;
        res = new IR(kOptWhereClause, OP3("WHERE (", ")", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptWhereClause, string(""));
        $$ = res;
    }

;

/*
* We combine the update and delete actions into one value temporarily
* for simplicity of parsing, and then break them down again in the
* calling production.  update is in the left 8 bits, delete in the right.
* Note that NOACTION is the default.
*/

key_actions:

    key_update {
        auto tmp1 = $1;
        res = new IR(kKeyActions, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | key_delete {
        auto tmp1 = $1;
        res = new IR(kKeyActions, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | key_update key_delete {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kKeyActions, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | key_delete key_update {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kKeyActions, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kKeyActions, string(""));
        $$ = res;
    }

;


key_update:

    ON UPDATE key_action {
        auto tmp1 = $3;
        res = new IR(kKeyUpdate, OP3("ON UPDATE", "", ""), tmp1);
        $$ = res;
    }

;


key_delete:

    ON DELETE_P key_action {
        auto tmp1 = $3;
        res = new IR(kKeyDelete, OP3("ON DELETE", "", ""), tmp1);
        $$ = res;
    }

;


key_action:

    NO ACTION {
        res = new IR(kKeyAction, string("NO ACTION"));
        $$ = res;
    }

    | RESTRICT {
        res = new IR(kKeyAction, string("RESTRICT"));
        $$ = res;
    }

    | CASCADE {
        res = new IR(kKeyAction, string("CASCADE"));
        $$ = res;
    }

    | SET NULL_P {
        res = new IR(kKeyAction, string("SET NULL"));
        $$ = res;
    }

    | SET DEFAULT {
        res = new IR(kKeyAction, string("SET DEFAULT"));
        $$ = res;
    }

;


OptInherit:

    INHERITS '(' qualified_name_list ')' {
        auto tmp1 = $3;
        res = new IR(kOptInherit, OP3("INHERITS (", ")", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptInherit, string(""));
        $$ = res;
    }

;

/* Optional partition key specification */

OptPartitionSpec:

    PartitionSpec {
        auto tmp1 = $1;
        res = new IR(kOptPartitionSpec, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptPartitionSpec, string(""));
        $$ = res;
    }

;


PartitionSpec:

    PARTITION BY ColId '(' part_params ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kPartitionSpec, OP3("PARTITION BY", "(", ")"), tmp1, tmp2);
        $$ = res;
    }

;


part_params:

    part_elem {
        auto tmp1 = $1;
        res = new IR(kPartParams, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | part_params ',' part_elem {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kPartParams, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


part_elem:

    ColId opt_collate opt_class {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUnknown, OP3("", "", ""), tmp1, tmp2);
        auto tmp3 = $3;
        res = new IR(kPartElem, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | func_expr_windowless opt_collate opt_class {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUnknown, OP3("", "", ""), tmp1, tmp2);
        auto tmp3 = $3;
        res = new IR(kPartElem, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | '(' a_expr ')' opt_collate opt_class {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("(", ")", ""), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kPartElem, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


table_access_method_clause:

    USING name {
        auto tmp1 = $2;
        res = new IR(kTableAccessMethodClause, OP3("USING", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kTableAccessMethodClause, string(""));
        $$ = res;
    }

;

/* WITHOUT OIDS is legacy only */

OptWith:

    WITH reloptions {
        auto tmp1 = $2;
        res = new IR(kOptWith, OP3("WITH", "", ""), tmp1);
        $$ = res;
    }

    | WITHOUT OIDS {
        res = new IR(kOptWith, string("WITHOUT OIDS"));
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptWith, string(""));
        $$ = res;
    }

;


OnCommitOption:

    ON COMMIT DROP {
        res = new IR(kOnCommitOption, string("ON COMMIT DROP"));
        $$ = res;
    }

    | ON COMMIT DELETE_P ROWS {
        res = new IR(kOnCommitOption, string("ON COMMIT DELETE ROWS"));
        $$ = res;
    }

    | ON COMMIT PRESERVE ROWS {
        res = new IR(kOnCommitOption, string("ON COMMIT PRESERVE ROWS"));
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOnCommitOption, string(""));
        $$ = res;
    }

;


OptTableSpace:

    TABLESPACE name {
        auto tmp1 = $2;
        res = new IR(kOptTableSpace, OP3("TABLESPACE", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptTableSpace, string(""));
        $$ = res;
    }

;


OptConsTableSpace:

    USING INDEX TABLESPACE name {
        auto tmp1 = $4;
        res = new IR(kOptConsTableSpace, OP3("USING INDEX TABLESPACE", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptConsTableSpace, string(""));
        $$ = res;
    }

;


ExistingIndex:

    USING INDEX name {
        auto tmp1 = $3;
        res = new IR(kExistingIndex, OP3("USING INDEX", "", ""), tmp1);
        $$ = res;
    }

;

/*****************************************************************************
*
*		QUERY :
*				CREATE STATISTICS [IF NOT EXISTS] stats_name [(stat types)]
*					ON expression-list FROM from_list
*
* Note: the expectation here is that the clauses after ON are a subset of
* SELECT syntax, allowing for expressions and joined tables, and probably
* someday a WHERE clause.  Much less than that is currently implemented,
* but the grammar accepts it and then we'll throw FEATURE_NOT_SUPPORTED
* errors as necessary at execution.
*
*****************************************************************************/


CreateStatsStmt:

    CREATE STATISTICS any_name opt_name_list ON stats_params FROM from_list {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("CREATE STATISTICS", "", "ON"), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kCreateStatsStmt, OP3("", "FROM", ""), res, tmp3);
        $$ = res;
    }

    | CREATE STATISTICS IF_P NOT EXISTS any_name opt_name_list ON stats_params FROM from_list {
        auto tmp1 = $6;
        auto tmp2 = $7;
        res = new IR(kUnknown, OP3("CREATE STATISTICS IF NOT EXISTS", "", "ON"), tmp1, tmp2);
        auto tmp3 = $9;
        res = new IR(kCreateStatsStmt, OP3("", "FROM", ""), res, tmp3);
        $$ = res;
    }

;

/*
* Statistics attributes can be either simple column references, or arbitrary
* expressions in parens.  For compatibility with index attributes permitted
* in CREATE INDEX, we allow an expression that's just a function call to be
* written without parens.
*/


stats_params:

    stats_param {
        auto tmp1 = $1;
        res = new IR(kStatsParams, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | stats_params ',' stats_param {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kStatsParams, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


stats_param:

    ColId {
        auto tmp1 = $1;
        res = new IR(kStatsParam, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | func_expr_windowless {
        auto tmp1 = $1;
        res = new IR(kStatsParam, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '(' a_expr ')' {
        auto tmp1 = $2;
        res = new IR(kStatsParam, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

;

/*****************************************************************************
*
*		QUERY :
*				ALTER STATISTICS [IF EXISTS] stats_name
*					SET STATISTICS  <SignedIconst>
*
*****************************************************************************/


AlterStatsStmt:

    ALTER STATISTICS any_name SET STATISTICS SignedIconst {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kAlterStatsStmt, OP3("ALTER STATISTICS", "SET STATISTICS", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER STATISTICS IF_P EXISTS any_name SET STATISTICS SignedIconst {
        auto tmp1 = $5;
        auto tmp2 = $8;
        res = new IR(kAlterStatsStmt, OP3("ALTER STATISTICS IF EXISTS", "SET STATISTICS", ""), tmp1, tmp2);
        $$ = res;
    }

;

/*****************************************************************************
*
*		QUERY :
*				CREATE TABLE relname AS SelectStmt [ WITH [NO] DATA ]
*
*
* Note: SELECT ... INTO is a now-deprecated alternative for this.
*
*****************************************************************************/


CreateAsStmt:

    CREATE OptTemp TABLE create_as_target AS SelectStmt opt_with_data {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("CREATE", "TABLE", "AS"), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kCreateAsStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | CREATE OptTemp TABLE IF_P NOT EXISTS create_as_target AS SelectStmt opt_with_data {
        auto tmp1 = $2;
        auto tmp2 = $7;
        res = new IR(kUnknown, OP3("CREATE", "TABLE IF NOT EXISTS", "AS"), tmp1, tmp2);
        auto tmp3 = $9;
        res = new IR(kCreateAsStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


create_as_target:

    qualified_name opt_column_list table_access_method_clause OptWith OnCommitOption OptTableSpace {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUnknown, OP3("", "", ""), tmp1, tmp2);
        auto tmp3 = $3;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp3);
        auto tmp4 = $5;
        res = new IR(kCreateAsTarget, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


opt_with_data:

    WITH DATA_P {
        res = new IR(kOptWithData, string("WITH DATA"));
        $$ = res;
    }

    | WITH NO DATA_P {
        res = new IR(kOptWithData, string("WITH NO DATA"));
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptWithData, string(""));
        $$ = res;
    }

;


/*****************************************************************************
*
*		QUERY :
*				CREATE MATERIALIZED VIEW relname AS SelectStmt
*
*****************************************************************************/


CreateMatViewStmt:

    CREATE OptNoLog MATERIALIZED VIEW create_mv_target AS SelectStmt opt_with_data {
        auto tmp1 = $2;
        auto tmp2 = $5;
        res = new IR(kUnknown, OP3("CREATE", "MATERIALIZED VIEW", "AS"), tmp1, tmp2);
        auto tmp3 = $7;
        res = new IR(kCreateMatViewStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | CREATE OptNoLog MATERIALIZED VIEW IF_P NOT EXISTS create_mv_target AS SelectStmt opt_with_data {
        auto tmp1 = $2;
        auto tmp2 = $8;
        res = new IR(kUnknown, OP3("CREATE", "MATERIALIZED VIEW IF NOT EXISTS", "AS"), tmp1, tmp2);
        auto tmp3 = $10;
        res = new IR(kCreateMatViewStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


create_mv_target:

    qualified_name opt_column_list table_access_method_clause opt_reloptions OptTableSpace {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUnknown, OP3("", "", ""), tmp1, tmp2);
        auto tmp3 = $3;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp3);
        auto tmp4 = $5;
        res = new IR(kCreateMvTarget, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


OptNoLog:

    UNLOGGED {
        res = new IR(kOptNoLog, string("UNLOGGED"));
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptNoLog, string(""));
        $$ = res;
    }

;


/*****************************************************************************
*
*		QUERY :
*				REFRESH MATERIALIZED VIEW qualified_name
*
*****************************************************************************/


RefreshMatViewStmt:

    REFRESH MATERIALIZED VIEW opt_concurrently qualified_name opt_with_data {
        auto tmp1 = $4;
        auto tmp2 = $5;
        res = new IR(kUnknown, OP3("REFRESH MATERIALIZED VIEW", "", ""), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kRefreshMatViewStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


/*****************************************************************************
*
*		QUERY :
*				CREATE SEQUENCE seqname
*				ALTER SEQUENCE seqname
*
*****************************************************************************/


CreateSeqStmt:

    CREATE OptTemp SEQUENCE qualified_name OptSeqOptList {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("CREATE", "SEQUENCE", ""), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kCreateSeqStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | CREATE OptTemp SEQUENCE IF_P NOT EXISTS qualified_name OptSeqOptList {
        auto tmp1 = $2;
        auto tmp2 = $7;
        res = new IR(kUnknown, OP3("CREATE", "SEQUENCE IF NOT EXISTS", ""), tmp1, tmp2);
        auto tmp3 = $8;
        res = new IR(kCreateSeqStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


AlterSeqStmt:

    ALTER SEQUENCE qualified_name SeqOptList {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlterSeqStmt, OP3("ALTER SEQUENCE", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER SEQUENCE IF_P EXISTS qualified_name SeqOptList {
        auto tmp1 = $5;
        auto tmp2 = $6;
        res = new IR(kAlterSeqStmt, OP3("ALTER SEQUENCE IF EXISTS", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


OptSeqOptList:

    SeqOptList {
        auto tmp1 = $1;
        res = new IR(kOptSeqOptList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptSeqOptList, string(""));
        $$ = res;
    }

;


OptParenthesizedSeqOptList:

    SeqOptList ')' {
        auto tmp1 = $1;
        res = new IR(kOptParenthesizedSeqOptList, OP3("", ")", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptParenthesizedSeqOptList, string(""));
        $$ = res;
    }

;


SeqOptList:

    SeqOptElem {
        auto tmp1 = $1;
        res = new IR(kSeqOptList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | SeqOptList SeqOptElem {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSeqOptList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


SeqOptElem:

    AS SimpleTypename {
        auto tmp1 = $2;
        res = new IR(kSeqOptElem, OP3("AS", "", ""), tmp1);
        $$ = res;
    }

    | CACHE NumericOnly {
        auto tmp1 = $2;
        res = new IR(kSeqOptElem, OP3("CACHE", "", ""), tmp1);
        $$ = res;
    }

    | CYCLE {
        res = new IR(kSeqOptElem, string("CYCLE"));
        $$ = res;
    }

    | NO CYCLE {
        res = new IR(kSeqOptElem, string("NO CYCLE"));
        $$ = res;
    }

    | INCREMENT opt_by NumericOnly {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSeqOptElem, OP3("INCREMENT", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | MAXVALUE NumericOnly {
        auto tmp1 = $2;
        res = new IR(kSeqOptElem, OP3("MAXVALUE", "", ""), tmp1);
        $$ = res;
    }

    | MINVALUE NumericOnly {
        auto tmp1 = $2;
        res = new IR(kSeqOptElem, OP3("MINVALUE", "", ""), tmp1);
        $$ = res;
    }

    | NO MAXVALUE {
        res = new IR(kSeqOptElem, string("NO MAXVALUE"));
        $$ = res;
    }

    | NO MINVALUE {
        res = new IR(kSeqOptElem, string("NO MINVALUE"));
        $$ = res;
    }

    | OWNED BY any_name {
        auto tmp1 = $3;
        res = new IR(kSeqOptElem, OP3("OWNED BY", "", ""), tmp1);
        $$ = res;
    }

    | SEQUENCE NAME_P any_name {
        auto tmp1 = $3;
        res = new IR(kSeqOptElem, OP3("SEQUENCE NAME", "", ""), tmp1);
        $$ = res;
    }

    | START opt_with NumericOnly {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSeqOptElem, OP3("START", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | RESTART {
        res = new IR(kSeqOptElem, string("RESTART"));
        $$ = res;
    }

    | RESTART opt_with NumericOnly {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSeqOptElem, OP3("RESTART", "", ""), tmp1, tmp2);
        $$ = res;
    }

;

opt_by:		
    BY {
        $$ = new IR(kOptBy, OP3("BY", "", ""));
    } 
    | /* EMPTY */ {
        $$ = new IR(kOptBy, OP0());
    }
;


NumericOnly:

    FCONST {
        res = new IR(kNumericOnly, string("FCONST"));
        $$ = res;
    }

    | '+' FCONST {
        res = new IR(kNumericOnly, string("+ FCONST"));
        $$ = res;
    }

    | '-' FCONST {
        res = new IR(kNumericOnly, string("- FCONST"));
        $$ = res;
    }

    | SignedIconst {
        auto tmp1 = $1;
        res = new IR(kNumericOnly, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


NumericOnly_list:

    NumericOnly {
        auto tmp1 = $1;
        res = new IR(kNumericOnlyList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | NumericOnly_list ',' NumericOnly {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kNumericOnlyList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;

/*****************************************************************************
*
*		QUERIES :
*				CREATE [OR REPLACE] [TRUSTED] [PROCEDURAL] LANGUAGE ...
*				DROP [PROCEDURAL] LANGUAGE ...
*
*****************************************************************************/


CreatePLangStmt:

    CREATE opt_or_replace opt_trusted opt_procedural LANGUAGE name {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("CREATE", "", ""), tmp1, tmp2);
        auto tmp3 = $4;
        res = new IR(kCreatePLangStmt, OP3("", "LANGUAGE", ""), res, tmp3);
        $$ = res;
    }

    | CREATE opt_or_replace opt_trusted opt_procedural LANGUAGE name HANDLER handler_name opt_inline_handler opt_validator {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("CREATE", "", ""), tmp1, tmp2);
        auto tmp3 = $4;
        res = new IR(kUnknown, OP3("", "LANGUAGE", "HANDLER"), res, tmp3);
        auto tmp4 = $8;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp4);
        auto tmp5 = $10;
        res = new IR(kCreatePLangStmt, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

;


opt_trusted:

    TRUSTED {
        res = new IR(kOptTrusted, string("TRUSTED"));
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptTrusted, string(""));
        $$ = res;
    }

;

/* This ought to be just func_name, but that causes reduce/reduce conflicts
* (CREATE LANGUAGE is the only place where func_name isn't followed by '(').
* Work around by using simple names, instead.
*/

handler_name:

    name {
        auto tmp1 = $1;
        res = new IR(kHandlerName, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | name attrs {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kHandlerName, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_inline_handler:

    INLINE_P handler_name {
        auto tmp1 = $2;
        res = new IR(kOptInlineHandler, OP3("INLINE", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptInlineHandler, string(""));
        $$ = res;
    }

;


validator_clause:

    VALIDATOR handler_name {
        auto tmp1 = $2;
        res = new IR(kValidatorClause, OP3("VALIDATOR", "", ""), tmp1);
        $$ = res;
    }

    | NO VALIDATOR {
        res = new IR(kValidatorClause, string("NO VALIDATOR"));
        $$ = res;
    }

;


opt_validator:

    validator_clause {
        auto tmp1 = $1;
        res = new IR(kOptValidator, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptValidator, string(""));
        $$ = res;
    }

;

opt_procedural:
    PROCEDURAL {
        $$ = new IR(kOptProcedural, OP3("PROCEDURAL", "", ""));
    }
    | /*EMPTY*/ {
        $$ = new IR(kOptProcedural, OP0());
    }
;

/*****************************************************************************
*
*		QUERY:
*             CREATE TABLESPACE tablespace LOCATION '/path/to/tablespace/'
*
*****************************************************************************/


CreateTableSpaceStmt:

    CREATE TABLESPACE name OptTableSpaceOwner LOCATION Sconst opt_reloptions {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("CREATE TABLESPACE", "", "LOCATION"), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kCreateTableSpaceStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


OptTableSpaceOwner:

    OWNER RoleSpec {
        auto tmp1 = $2;
        res = new IR(kOptTableSpaceOwner, OP3("OWNER", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY */ {
        res = new IR(kOptTableSpaceOwner, OP0());
        $$ = res;
    }

;

/*****************************************************************************
*
*		QUERY :
*				DROP TABLESPACE <tablespace>
*
*		No need for drop behaviour as we cannot implement dependencies for
*		objects in other databases; we can only support RESTRICT.
*
****************************************************************************/


DropTableSpaceStmt:

    DROP TABLESPACE name {
        auto tmp1 = $3;
        res = new IR(kDropTableSpaceStmt, OP3("DROP TABLESPACE", "", ""), tmp1);
        $$ = res;
    }

    | DROP TABLESPACE IF_P EXISTS name {
        auto tmp1 = $5;
        res = new IR(kDropTableSpaceStmt, OP3("DROP TABLESPACE IF EXISTS", "", ""), tmp1);
        $$ = res;
    }

;

/*****************************************************************************
*
*		QUERY:
*             CREATE EXTENSION extension
*             [ WITH ] [ SCHEMA schema ] [ VERSION version ]
*
*****************************************************************************/


CreateExtensionStmt:

    CREATE EXTENSION name opt_with create_extension_opt_list {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("CREATE EXTENSION", "", ""), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kCreateExtensionStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | CREATE EXTENSION IF_P NOT EXISTS name opt_with create_extension_opt_list {
        auto tmp1 = $6;
        auto tmp2 = $7;
        res = new IR(kUnknown, OP3("CREATE EXTENSION IF NOT EXISTS", "", ""), tmp1, tmp2);
        auto tmp3 = $8;
        res = new IR(kCreateExtensionStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


create_extension_opt_list:

    create_extension_opt_list create_extension_opt_item {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCreateExtensionOptList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | /* EMPTY */ {
        res = new IR(kCreateExtensionOptList, string(""));
        $$ = res;
    }

;


create_extension_opt_item:

    SCHEMA name {
        auto tmp1 = $2;
        res = new IR(kCreateExtensionOptItem, OP3("SCHEMA", "", ""), tmp1);
        $$ = res;
    }

    | VERSION_P NonReservedWord_or_Sconst {
        auto tmp1 = $2;
        res = new IR(kCreateExtensionOptItem, OP3("VERSION", "", ""), tmp1);
        $$ = res;
    }

    | FROM NonReservedWord_or_Sconst {
        auto tmp1 = $2;
        res = new IR(kCreateExtensionOptItem, OP3("FROM", "", ""), tmp1);
        $$ = res;
    }

    | CASCADE {
        res = new IR(kCreateExtensionOptItem, string("CASCADE"));
        $$ = res;
    }

;

/*****************************************************************************
*
* ALTER EXTENSION name UPDATE [ TO version ]
*
*****************************************************************************/


AlterExtensionStmt:

    ALTER EXTENSION name UPDATE alter_extension_opt_list {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kAlterExtensionStmt, OP3("ALTER EXTENSION", "UPDATE", ""), tmp1, tmp2);
        $$ = res;
    }

;


alter_extension_opt_list:

    alter_extension_opt_list alter_extension_opt_item {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAlterExtensionOptList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | /* EMPTY */ {
        res = new IR(kAlterExtensionOptList, string(""));
        $$ = res;
    }

;


alter_extension_opt_item:

    TO NonReservedWord_or_Sconst {
        auto tmp1 = $2;
        res = new IR(kAlterExtensionOptItem, OP3("TO", "", ""), tmp1);
        $$ = res;
    }

;

/*****************************************************************************
*
* ALTER EXTENSION name ADD/DROP object-identifier
*
*****************************************************************************/


AlterExtensionContentsStmt:

    ALTER EXTENSION name add_drop object_type_name name {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("ALTER EXTENSION", "", ""), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kAlterExtensionContentsStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER EXTENSION name add_drop object_type_any_name any_name {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("ALTER EXTENSION", "", ""), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kAlterExtensionContentsStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER EXTENSION name add_drop AGGREGATE aggregate_with_argtypes {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("ALTER EXTENSION", "", "AGGREGATE"), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kAlterExtensionContentsStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER EXTENSION name add_drop CAST '(' Typename AS Typename ')' {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("ALTER EXTENSION", "", "CAST ("), tmp1, tmp2);
        auto tmp3 = $7;
        res = new IR(kAlterExtensionContentsStmt, OP3("", "AS", ")"), res, tmp3);
        $$ = res;
    }

    | ALTER EXTENSION name add_drop DOMAIN_P Typename {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("ALTER EXTENSION", "", "DOMAIN"), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kAlterExtensionContentsStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER EXTENSION name add_drop FUNCTION function_with_argtypes {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("ALTER EXTENSION", "", "FUNCTION"), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kAlterExtensionContentsStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER EXTENSION name add_drop OPERATOR operator_with_argtypes {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("ALTER EXTENSION", "", "OPERATOR"), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kAlterExtensionContentsStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER EXTENSION name add_drop OPERATOR CLASS any_name USING name {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("ALTER EXTENSION", "", "OPERATOR CLASS"), tmp1, tmp2);
        auto tmp3 = $7;
        res = new IR(kAlterExtensionContentsStmt, OP3("", "USING", ""), res, tmp3);
        $$ = res;
    }

    | ALTER EXTENSION name add_drop OPERATOR FAMILY any_name USING name {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("ALTER EXTENSION", "", "OPERATOR FAMILY"), tmp1, tmp2);
        auto tmp3 = $7;
        res = new IR(kAlterExtensionContentsStmt, OP3("", "USING", ""), res, tmp3);
        $$ = res;
    }

    | ALTER EXTENSION name add_drop PROCEDURE function_with_argtypes {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("ALTER EXTENSION", "", "PROCEDURE"), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kAlterExtensionContentsStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER EXTENSION name add_drop ROUTINE function_with_argtypes {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("ALTER EXTENSION", "", "ROUTINE"), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kAlterExtensionContentsStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER EXTENSION name add_drop TRANSFORM FOR Typename LANGUAGE name {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("ALTER EXTENSION", "", "TRANSFORM FOR"), tmp1, tmp2);
        auto tmp3 = $7;
        res = new IR(kAlterExtensionContentsStmt, OP3("", "LANGUAGE", ""), res, tmp3);
        $$ = res;
    }

    | ALTER EXTENSION name add_drop TYPE_P Typename {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("ALTER EXTENSION", "", "TYPE"), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kAlterExtensionContentsStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;

/*****************************************************************************
*
*		QUERY:
*             CREATE FOREIGN DATA WRAPPER name options
*
*****************************************************************************/


CreateFdwStmt:

    CREATE FOREIGN DATA_P WRAPPER name opt_fdw_options create_generic_options {
        auto tmp1 = $5;
        auto tmp2 = $6;
        res = new IR(kUnknown, OP3("CREATE FOREIGN DATA WRAPPER", "", ""), tmp1, tmp2);
        auto tmp3 = $7;
        res = new IR(kCreateFdwStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


fdw_option:

    HANDLER handler_name {
        auto tmp1 = $2;
        res = new IR(kFdwOption, OP3("HANDLER", "", ""), tmp1);
        $$ = res;
    }

    | NO HANDLER {
        res = new IR(kFdwOption, string("NO HANDLER"));
        $$ = res;
    }

    | VALIDATOR handler_name {
        auto tmp1 = $2;
        res = new IR(kFdwOption, OP3("VALIDATOR", "", ""), tmp1);
        $$ = res;
    }

    | NO VALIDATOR {
        res = new IR(kFdwOption, string("NO VALIDATOR"));
        $$ = res;
    }

;


fdw_options:

    fdw_option {
        auto tmp1 = $1;
        res = new IR(kFdwOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | fdw_options fdw_option {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFdwOptions, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_fdw_options:

    fdw_options {
        auto tmp1 = $1;
        res = new IR(kOptFdwOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptFdwOptions, string(""));
        $$ = res;
    }

;

/*****************************************************************************
*
*		QUERY :
*				ALTER FOREIGN DATA WRAPPER name options
*
****************************************************************************/


AlterFdwStmt:

    ALTER FOREIGN DATA_P WRAPPER name opt_fdw_options alter_generic_options {
        auto tmp1 = $5;
        auto tmp2 = $6;
        res = new IR(kUnknown, OP3("ALTER FOREIGN DATA WRAPPER", "", ""), tmp1, tmp2);
        auto tmp3 = $7;
        res = new IR(kAlterFdwStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER FOREIGN DATA_P WRAPPER name fdw_options {
        auto tmp1 = $5;
        auto tmp2 = $6;
        res = new IR(kAlterFdwStmt, OP3("ALTER FOREIGN DATA WRAPPER", "", ""), tmp1, tmp2);
        $$ = res;
    }

;

/* Options definition for CREATE FDW, SERVER and USER MAPPING */

create_generic_options:

    OPTIONS '(' generic_option_list ')' {
        auto tmp1 = $3;
        res = new IR(kCreateGenericOptions, OP3("OPTIONS (", ")", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kCreateGenericOptions, string(""));
        $$ = res;
    }

;


generic_option_list:

    generic_option_elem {
        auto tmp1 = $1;
        res = new IR(kGenericOptionList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | generic_option_list ',' generic_option_elem {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kGenericOptionList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;

/* Options definition for ALTER FDW, SERVER and USER MAPPING */

alter_generic_options:

    OPTIONS '(' alter_generic_option_list ')' {
        auto tmp1 = $3;
        res = new IR(kAlterGenericOptions, OP3("OPTIONS (", ")", ""), tmp1);
        $$ = res;
    }

;


alter_generic_option_list:

    alter_generic_option_elem {
        auto tmp1 = $1;
        res = new IR(kAlterGenericOptionList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | alter_generic_option_list ',' alter_generic_option_elem {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAlterGenericOptionList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


alter_generic_option_elem:

    generic_option_elem {
        auto tmp1 = $1;
        res = new IR(kAlterGenericOptionElem, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | SET generic_option_elem {
        auto tmp1 = $2;
        res = new IR(kAlterGenericOptionElem, OP3("SET", "", ""), tmp1);
        $$ = res;
    }

    | ADD_P generic_option_elem {
        auto tmp1 = $2;
        res = new IR(kAlterGenericOptionElem, OP3("ADD", "", ""), tmp1);
        $$ = res;
    }

    | DROP generic_option_name {
        auto tmp1 = $2;
        res = new IR(kAlterGenericOptionElem, OP3("DROP", "", ""), tmp1);
        $$ = res;
    }

;


generic_option_elem:

    generic_option_name generic_option_arg {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kGenericOptionElem, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


generic_option_name:

    ColLabel {
        auto tmp1 = $1;
        res = new IR(kGenericOptionName, OP3("", "", ""), tmp1);
        $$ = res;
    }

;

/* We could use def_arg here, but the spec only requires string literals */

generic_option_arg:

    Sconst {
        auto tmp1 = $1;
        res = new IR(kGenericOptionArg, OP3("", "", ""), tmp1);
        $$ = res;
    }

;

/*****************************************************************************
*
*		QUERY:
*             CREATE SERVER name [TYPE] [VERSION] [OPTIONS]
*
*****************************************************************************/


CreateForeignServerStmt:

    CREATE SERVER name opt_type opt_foreign_server_version FOREIGN DATA_P WRAPPER name create_generic_options {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("CREATE SERVER", "", ""), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kUnknown, OP3("", "FOREIGN DATA WRAPPER", ""), res, tmp3);
        auto tmp4 = $10;
        res = new IR(kCreateForeignServerStmt, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | CREATE SERVER IF_P NOT EXISTS name opt_type opt_foreign_server_version FOREIGN DATA_P WRAPPER name create_generic_options {
        auto tmp1 = $6;
        auto tmp2 = $7;
        res = new IR(kUnknown, OP3("CREATE SERVER IF NOT EXISTS", "", ""), tmp1, tmp2);
        auto tmp3 = $8;
        res = new IR(kUnknown, OP3("", "FOREIGN DATA WRAPPER", ""), res, tmp3);
        auto tmp4 = $13;
        res = new IR(kCreateForeignServerStmt, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


opt_type:

    TYPE_P Sconst {
        auto tmp1 = $2;
        res = new IR(kOptType, OP3("TYPE", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptType, string(""));
        $$ = res;
    }

;



foreign_server_version:

    VERSION_P Sconst {
        auto tmp1 = $2;
        res = new IR(kForeignServerVersion, OP3("VERSION", "", ""), tmp1);
        $$ = res;
    }

    | VERSION_P NULL_P {
        res = new IR(kForeignServerVersion, string("VERSION NULL"));
        $$ = res;
    }

;


opt_foreign_server_version:

    foreign_server_version {
        auto tmp1 = $1;
        res = new IR(kOptForeignServerVersion, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptForeignServerVersion, string(""));
        $$ = res;
    }

;

/*****************************************************************************
*
*		QUERY :
*				ALTER SERVER name [VERSION] [OPTIONS]
*
****************************************************************************/


AlterForeignServerStmt:

    ALTER SERVER name foreign_server_version alter_generic_options {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("ALTER SERVER", "", ""), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kAlterForeignServerStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER SERVER name foreign_server_version {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlterForeignServerStmt, OP3("ALTER SERVER", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER SERVER name alter_generic_options {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlterForeignServerStmt, OP3("ALTER SERVER", "", ""), tmp1, tmp2);
        $$ = res;
    }

;

/*****************************************************************************
*
*		QUERY:
*             CREATE FOREIGN TABLE relname (...) SERVER name (...)
*
*****************************************************************************/


CreateForeignTableStmt:

    CREATE FOREIGN TABLE qualified_name '(' OptTableElementList ')' OptInherit SERVER name create_generic_options {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kUnknown, OP3("CREATE FOREIGN TABLE", "(", ")"), tmp1, tmp2);
        auto tmp3 = $8;
        res = new IR(kUnknown, OP3("", "SERVER", ""), res, tmp3);
        auto tmp4 = $11;
        res = new IR(kCreateForeignTableStmt, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | CREATE FOREIGN TABLE IF_P NOT EXISTS qualified_name '(' OptTableElementList ')' OptInherit SERVER name create_generic_options {
        auto tmp1 = $7;
        auto tmp2 = $9;
        res = new IR(kUnknown, OP3("CREATE FOREIGN TABLE IF NOT EXISTS", "(", ")"), tmp1, tmp2);
        auto tmp3 = $11;
        res = new IR(kUnknown, OP3("", "SERVER", ""), res, tmp3);
        auto tmp4 = $14;
        res = new IR(kCreateForeignTableStmt, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | CREATE FOREIGN TABLE qualified_name PARTITION OF qualified_name OptTypedTableElementList PartitionBoundSpec SERVER name create_generic_options {
        auto tmp1 = $4;
        auto tmp2 = $7;
        res = new IR(kUnknown, OP3("CREATE FOREIGN TABLE", "PARTITION OF", ""), tmp1, tmp2);
        auto tmp3 = $8;
        res = new IR(kUnknown, OP3("", "", "SERVER"), res, tmp3);
        auto tmp4 = $11;
        res = new IR(kCreateForeignTableStmt, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | CREATE FOREIGN TABLE IF_P NOT EXISTS qualified_name PARTITION OF qualified_name OptTypedTableElementList PartitionBoundSpec SERVER name create_generic_options {
        auto tmp1 = $7;
        auto tmp2 = $10;
        res = new IR(kUnknown, OP3("CREATE FOREIGN TABLE IF NOT EXISTS", "PARTITION OF", ""), tmp1, tmp2);
        auto tmp3 = $11;
        res = new IR(kUnknown, OP3("", "", "SERVER"), res, tmp3);
        auto tmp4 = $14;
        res = new IR(kCreateForeignTableStmt, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;

/*****************************************************************************
*
*		QUERY:
*				IMPORT FOREIGN SCHEMA remote_schema
*				[ { LIMIT TO | EXCEPT } ( table_list ) ]
*				FROM SERVER server_name INTO local_schema [ OPTIONS (...) ]
*
****************************************************************************/


ImportForeignSchemaStmt:

    IMPORT_P FOREIGN SCHEMA name import_qualification FROM SERVER name INTO name create_generic_options {
        auto tmp1 = $4;
        auto tmp2 = $5;
        res = new IR(kUnknown, OP3("IMPORT FOREIGN SCHEMA", "", "FROM SERVER"), tmp1, tmp2);
        auto tmp3 = $8;
        res = new IR(kUnknown, OP3("", "INTO", ""), res, tmp3);
        auto tmp4 = $11;
        res = new IR(kImportForeignSchemaStmt, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


import_qualification_type:

    LIMIT TO {
        res = new IR(kImportQualificationType, string("LIMIT TO"));
        $$ = res;
    }

    | EXCEPT {
        res = new IR(kImportQualificationType, string("EXCEPT"));
        $$ = res;
    }

;


import_qualification:

    import_qualification_type '(' relation_expr_list ')' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kImportQualification, OP3("", "(", ")"), tmp1, tmp2);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kImportQualification, string(""));
        $$ = res;
    }

;

/*****************************************************************************
*
*		QUERY:
*             CREATE USER MAPPING FOR auth_ident SERVER name [OPTIONS]
*
*****************************************************************************/


CreateUserMappingStmt:

    CREATE USER MAPPING FOR auth_ident SERVER name create_generic_options {
        auto tmp1 = $5;
        auto tmp2 = $7;
        res = new IR(kUnknown, OP3("CREATE USER MAPPING FOR", "SERVER", ""), tmp1, tmp2);
        auto tmp3 = $8;
        res = new IR(kCreateUserMappingStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | CREATE USER MAPPING IF_P NOT EXISTS FOR auth_ident SERVER name create_generic_options {
        auto tmp1 = $8;
        auto tmp2 = $10;
        res = new IR(kUnknown, OP3("CREATE USER MAPPING IF NOT EXISTS FOR", "SERVER", ""), tmp1, tmp2);
        auto tmp3 = $11;
        res = new IR(kCreateUserMappingStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;

/* User mapping authorization identifier */

auth_ident:

    RoleSpec {
        auto tmp1 = $1;
        res = new IR(kAuthIdent, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | USER {
        res = new IR(kAuthIdent, string("USER"));
        $$ = res;
    }

;

/*****************************************************************************
*
*		QUERY :
*				DROP USER MAPPING FOR auth_ident SERVER name
*
* XXX you'd think this should have a CASCADE/RESTRICT option, even if it's
* only pro forma; but the SQL standard doesn't show one.
****************************************************************************/


DropUserMappingStmt:

    DROP USER MAPPING FOR auth_ident SERVER name {
        auto tmp1 = $5;
        auto tmp2 = $7;
        res = new IR(kDropUserMappingStmt, OP3("DROP USER MAPPING FOR", "SERVER", ""), tmp1, tmp2);
        $$ = res;
    }

    | DROP USER MAPPING IF_P EXISTS FOR auth_ident SERVER name {
        auto tmp1 = $7;
        auto tmp2 = $9;
        res = new IR(kDropUserMappingStmt, OP3("DROP USER MAPPING IF EXISTS FOR", "SERVER", ""), tmp1, tmp2);
        $$ = res;
    }

;

/*****************************************************************************
*
*		QUERY :
*				ALTER USER MAPPING FOR auth_ident SERVER name OPTIONS
*
****************************************************************************/


AlterUserMappingStmt:

    ALTER USER MAPPING FOR auth_ident SERVER name alter_generic_options {
        auto tmp1 = $5;
        auto tmp2 = $7;
        res = new IR(kUnknown, OP3("ALTER USER MAPPING FOR", "SERVER", ""), tmp1, tmp2);
        auto tmp3 = $8;
        res = new IR(kAlterUserMappingStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;

/*****************************************************************************
*
*		QUERIES:
*				CREATE POLICY name ON table
*					[AS { PERMISSIVE | RESTRICTIVE } ]
*					[FOR { SELECT | INSERT | UPDATE | DELETE } ]
*					[TO role, ...]
*					[USING (qual)] [WITH CHECK (with check qual)]
*				ALTER POLICY name ON table [TO role, ...]
*					[USING (qual)] [WITH CHECK (with check qual)]
*
*****************************************************************************/


CreatePolicyStmt:

    CREATE POLICY name ON qualified_name RowSecurityDefaultPermissive RowSecurityDefaultForCmd RowSecurityDefaultToRole RowSecurityOptionalExpr RowSecurityOptionalWithCheck {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kUnknown, OP3("CREATE POLICY", "ON", ""), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp3);
        auto tmp4 = $8;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp4);
        auto tmp5 = $10;
        res = new IR(kCreatePolicyStmt, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

;


AlterPolicyStmt:

    ALTER POLICY name ON qualified_name RowSecurityOptionalToRole RowSecurityOptionalExpr RowSecurityOptionalWithCheck {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kUnknown, OP3("ALTER POLICY", "ON", ""), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp3);
        auto tmp4 = $8;
        res = new IR(kAlterPolicyStmt, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


RowSecurityOptionalExpr:

    USING '(' a_expr ')' {
        auto tmp1 = $3;
        res = new IR(kRowSecurityOptionalExpr, OP3("USING (", ")", ""), tmp1);
        $$ = res;
    }

    | /* EMPTY */ {
        res = new IR(kRowSecurityOptionalExpr, string(""));
        $$ = res;
    }

;


RowSecurityOptionalWithCheck:

    WITH CHECK '(' a_expr ')' {
        auto tmp1 = $4;
        res = new IR(kRowSecurityOptionalWithCheck, OP3("WITH CHECK (", ")", ""), tmp1);
        $$ = res;
    }

    | /* EMPTY */ {
        res = new IR(kRowSecurityOptionalWithCheck, string(""));
        $$ = res;
    }

;


RowSecurityDefaultToRole:

    TO role_list {
        auto tmp1 = $2;
        res = new IR(kRowSecurityDefaultToRole, OP3("TO", "", ""), tmp1);
        $$ = res;
    }

    | /* EMPTY */ {
        res = new IR(kRowSecurityDefaultToRole, string(""));
        $$ = res;
    }

;


RowSecurityOptionalToRole:

    TO role_list {
        auto tmp1 = $2;
        res = new IR(kRowSecurityOptionalToRole, OP3("TO", "", ""), tmp1);
        $$ = res;
    }

    | /* EMPTY */ {
        res = new IR(kRowSecurityOptionalToRole, string(""));
        $$ = res;
    }

;


RowSecurityDefaultPermissive:

    AS IDENT {
        res = new IR(kRowSecurityDefaultPermissive, string("AS IDENT"));
        $$ = res;
    }

    | /* EMPTY */ {
        res = new IR(kRowSecurityDefaultPermissive, string(""));
        $$ = res;
    }

;


RowSecurityDefaultForCmd:

    FOR row_security_cmd {
        auto tmp1 = $2;
        res = new IR(kRowSecurityDefaultForCmd, OP3("FOR", "", ""), tmp1);
        $$ = res;
    }

    | /* EMPTY */ {
        res = new IR(kRowSecurityDefaultForCmd, string(""));
        $$ = res;
    }

;


row_security_cmd:

    ALL {
        res = new IR(kRowSecurityCmd, string("ALL"));
        $$ = res;
    }

    | SELECT {
        res = new IR(kRowSecurityCmd, string("SELECT"));
        $$ = res;
    }

    | INSERT {
        res = new IR(kRowSecurityCmd, string("INSERT"));
        $$ = res;
    }

    | UPDATE {
        res = new IR(kRowSecurityCmd, string("UPDATE"));
        $$ = res;
    }

    | DELETE_P {
        res = new IR(kRowSecurityCmd, string("DELETE"));
        $$ = res;
    }

;

/*****************************************************************************
*
*		QUERY:
*             CREATE ACCESS METHOD name HANDLER handler_name
*
*****************************************************************************/


CreateAmStmt:

    CREATE ACCESS METHOD name TYPE_P am_type HANDLER handler_name {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kUnknown, OP3("CREATE ACCESS METHOD", "TYPE", "HANDLER"), tmp1, tmp2);
        auto tmp3 = $8;
        res = new IR(kCreateAmStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


am_type:

    INDEX {
        res = new IR(kAmType, string("INDEX"));
        $$ = res;
    }

    | TABLE {
        res = new IR(kAmType, string("TABLE"));
        $$ = res;
    }

;

/*****************************************************************************
*
*		QUERIES :
*				CREATE TRIGGER ...
*
*****************************************************************************/


CreateTrigStmt:

    CREATE opt_or_replace TRIGGER name TriggerActionTime TriggerEvents ON qualified_name TriggerReferencing TriggerForSpec TriggerWhen EXECUTE FUNCTION_or_PROCEDURE func_name '(' TriggerFuncArgs ')' {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("CREATE", "TRIGGER", ""), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kUnknown, OP3("", "", "ON"), res, tmp3);
        auto tmp4 = $8;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp4);
        auto tmp5 = $10;
        res = new IR(kUnknown, OP3("", "", "EXECUTE"), res, tmp5);
        auto tmp6 = $13;
        res = new IR(kUnknown, OP3("", "", "("), res, tmp6);
        auto tmp7 = $16;
        res = new IR(kCreateTrigStmt, OP3("", ")", ""), res, tmp7);
        $$ = res;
    }

    | CREATE opt_or_replace CONSTRAINT TRIGGER name AFTER TriggerEvents ON qualified_name OptConstrFromTable ConstraintAttributeSpec FOR EACH ROW TriggerWhen EXECUTE FUNCTION_or_PROCEDURE func_name '(' TriggerFuncArgs ')' {
        auto tmp1 = $2;
        auto tmp2 = $5;
        res = new IR(kUnknown, OP3("CREATE", "CONSTRAINT TRIGGER", "AFTER"), tmp1, tmp2);
        auto tmp3 = $7;
        res = new IR(kUnknown, OP3("", "ON", ""), res, tmp3);
        auto tmp4 = $10;
        res = new IR(kUnknown, OP3("", "", "FOR EACH ROW"), res, tmp4);
        auto tmp5 = $15;
        res = new IR(kUnknown, OP3("", "EXECUTE", ""), res, tmp5);
        auto tmp6 = $18;
        res = new IR(kCreateTrigStmt, OP3("", "(", ")"), res, tmp6);
        $$ = res;
    }

;


TriggerActionTime:

    BEFORE {
        res = new IR(kTriggerActionTime, string("BEFORE"));
        $$ = res;
    }

    | AFTER {
        res = new IR(kTriggerActionTime, string("AFTER"));
        $$ = res;
    }

    | INSTEAD OF {
        res = new IR(kTriggerActionTime, string("INSTEAD OF"));
        $$ = res;
    }

;


TriggerEvents:

    TriggerOneEvent {
        auto tmp1 = $1;
        res = new IR(kTriggerEvents, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | TriggerEvents OR TriggerOneEvent {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTriggerEvents, OP3("", "OR", ""), tmp1, tmp2);
        $$ = res;
    }

;


TriggerOneEvent:

    INSERT {
        res = new IR(kTriggerOneEvent, string("INSERT"));
        $$ = res;
    }

    | DELETE_P {
        res = new IR(kTriggerOneEvent, string("DELETE"));
        $$ = res;
    }

    | UPDATE {
        res = new IR(kTriggerOneEvent, string("UPDATE"));
        $$ = res;
    }

    | UPDATE OF columnList {
        auto tmp1 = $3;
        res = new IR(kTriggerOneEvent, OP3("UPDATE OF", "", ""), tmp1);
        $$ = res;
    }

    | TRUNCATE {
        res = new IR(kTriggerOneEvent, string("TRUNCATE"));
        $$ = res;
    }

;


TriggerReferencing:

    REFERENCING TriggerTransitions {
        auto tmp1 = $2;
        res = new IR(kTriggerReferencing, OP3("REFERENCING", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kTriggerReferencing, string(""));
        $$ = res;
    }

;


TriggerTransitions:

    TriggerTransition {
        auto tmp1 = $1;
        res = new IR(kTriggerTransitions, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | TriggerTransitions TriggerTransition {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kTriggerTransitions, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


TriggerTransition:

    TransitionOldOrNew TransitionRowOrTable opt_as TransitionRelName {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUnknown, OP3("", "", ""), tmp1, tmp2);
        auto tmp3 = $3;
        res = new IR(kTriggerTransition, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


TransitionOldOrNew:

    NEW {
        res = new IR(kTransitionOldOrNew, string("NEW"));
        $$ = res;
    }

    | OLD {
        res = new IR(kTransitionOldOrNew, string("OLD"));
        $$ = res;
    }

;


TransitionRowOrTable:

    TABLE {
        res = new IR(kTransitionRowOrTable, string("TABLE"));
        $$ = res;
    }

    | ROW {
        res = new IR(kTransitionRowOrTable, string("ROW"));
        $$ = res;
    }

;


TransitionRelName:

    ColId {
        auto tmp1 = $1;
        res = new IR(kTransitionRelName, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


TriggerForSpec:

    FOR TriggerForOptEach TriggerForType {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kTriggerForSpec, OP3("FOR", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | /* EMPTY */ {
        res = new IR(kTriggerForSpec, string(""));
        $$ = res;
    }

;

TriggerForOptEach:
    EACH {
        $$ = new IR(kTriggerForOptEach, OP3("EACH", "", ""));
    }
    | /*EMPTY*/ {
        $$ = new IR(kTriggerForOptEach, OP0());
    }
;


TriggerForType:

    ROW {
        res = new IR(kTriggerForType, string("ROW"));
        $$ = res;
    }

    | STATEMENT {
        res = new IR(kTriggerForType, string("STATEMENT"));
        $$ = res;
    }

;


TriggerWhen:

    WHEN '(' a_expr ')' {
        auto tmp1 = $3;
        res = new IR(kTriggerWhen, OP3("WHEN (", ")", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kTriggerWhen, string(""));
        $$ = res;
    }

;

FUNCTION_or_PROCEDURE:
    FUNCTION {
        $$ = new IR(kFunctionOrProcedure, OP3("FUNCTION", "", ""));
    }
|	PROCEDURE {
        $$ = new IR(kFunctionOrProcedure, OP3("PROCEDURE", "", ""));
    }
;


TriggerFuncArgs:

    TriggerFuncArg {
        auto tmp1 = $1;
        res = new IR(kTriggerFuncArgs, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | TriggerFuncArgs ',' TriggerFuncArg {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTriggerFuncArgs, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kTriggerFuncArgs, string(""));
        $$ = res;
    }

;


TriggerFuncArg:

    Iconst {
        auto tmp1 = $1;
        res = new IR(kTriggerFuncArg, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | FCONST {
        res = new IR(kTriggerFuncArg, string("FCONST"));
        $$ = res;
    }

    | Sconst {
        auto tmp1 = $1;
        res = new IR(kTriggerFuncArg, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ColLabel {
        auto tmp1 = $1;
        res = new IR(kTriggerFuncArg, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


OptConstrFromTable:

    FROM qualified_name {
        auto tmp1 = $2;
        res = new IR(kOptConstrFromTable, OP3("FROM", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptConstrFromTable, string(""));
        $$ = res;
    }

;


ConstraintAttributeSpec:

    /*EMPTY*/ {
        res = new IR(kConstraintAttributeSpec, string(""));
        $$ = res;
    }

    | ConstraintAttributeSpec ConstraintAttributeElem {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kConstraintAttributeSpec, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


ConstraintAttributeElem:

    NOT DEFERRABLE {
        res = new IR(kConstraintAttributeElem, string("NOT DEFERRABLE"));
        $$ = res;
    }

    | DEFERRABLE {
        res = new IR(kConstraintAttributeElem, string("DEFERRABLE"));
        $$ = res;
    }

    | INITIALLY IMMEDIATE {
        res = new IR(kConstraintAttributeElem, string("INITIALLY IMMEDIATE"));
        $$ = res;
    }

    | INITIALLY DEFERRED {
        res = new IR(kConstraintAttributeElem, string("INITIALLY DEFERRED"));
        $$ = res;
    }

    | NOT VALID {
        res = new IR(kConstraintAttributeElem, string("NOT VALID"));
        $$ = res;
    }

    | NO INHERIT {
        res = new IR(kConstraintAttributeElem, string("NO INHERIT"));
        $$ = res;
    }

;


/*****************************************************************************
*
*		QUERIES :
*				CREATE EVENT TRIGGER ...
*				ALTER EVENT TRIGGER ...
*
*****************************************************************************/


CreateEventTrigStmt:

    CREATE EVENT TRIGGER name ON ColLabel EXECUTE FUNCTION_or_PROCEDURE func_name '(' ')' {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kUnknown, OP3("CREATE EVENT TRIGGER", "ON", "EXECUTE"), tmp1, tmp2);
        auto tmp3 = $8;
        res = new IR(kCreateEventTrigStmt, OP3("", "", "( )"), res, tmp3);
        $$ = res;
    }

    | CREATE EVENT TRIGGER name ON ColLabel WHEN event_trigger_when_list EXECUTE FUNCTION_or_PROCEDURE func_name '(' ')' {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kUnknown, OP3("CREATE EVENT TRIGGER", "ON", "WHEN"), tmp1, tmp2);
        auto tmp3 = $8;
        res = new IR(kUnknown, OP3("", "EXECUTE", ""), res, tmp3);
        auto tmp4 = $11;
        res = new IR(kCreateEventTrigStmt, OP3("", "( )", ""), res, tmp4);
        $$ = res;
    }

;


event_trigger_when_list:

    event_trigger_when_item {
        auto tmp1 = $1;
        res = new IR(kEventTriggerWhenList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | event_trigger_when_list AND event_trigger_when_item {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kEventTriggerWhenList, OP3("", "AND", ""), tmp1, tmp2);
        $$ = res;
    }

;


event_trigger_when_item:

    ColId IN_P '(' event_trigger_value_list ')' {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kEventTriggerWhenItem, OP3("", "IN (", ")"), tmp1, tmp2);
        $$ = res;
    }

;


event_trigger_value_list:

    SCONST {
        res = new IR(kEventTriggerValueList, string("SCONST"));
        $$ = res;
    }

    | event_trigger_value_list ',' SCONST {
        auto tmp1 = $1;
        res = new IR(kEventTriggerValueList, OP3("", ", SCONST", ""), tmp1);
        $$ = res;
    }

;


AlterEventTrigStmt:

    ALTER EVENT TRIGGER name enable_trigger {
        auto tmp1 = $4;
        auto tmp2 = $5;
        res = new IR(kAlterEventTrigStmt, OP3("ALTER EVENT TRIGGER", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


enable_trigger:

    ENABLE_P {
        res = new IR(kEnableTrigger, string("ENABLE"));
        $$ = res;
    }

    | ENABLE_P REPLICA {
        res = new IR(kEnableTrigger, string("ENABLE REPLICA"));
        $$ = res;
    }

    | ENABLE_P ALWAYS {
        res = new IR(kEnableTrigger, string("ENABLE ALWAYS"));
        $$ = res;
    }

    | DISABLE_P {
        res = new IR(kEnableTrigger, string("DISABLE"));
        $$ = res;
    }

;

/*****************************************************************************
*
*		QUERY :
*				CREATE ASSERTION ...
*
*****************************************************************************/


CreateAssertionStmt:

    CREATE ASSERTION any_name CHECK '(' a_expr ')' ConstraintAttributeSpec {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kUnknown, OP3("CREATE ASSERTION", "CHECK (", ")"), tmp1, tmp2);
        auto tmp3 = $8;
        res = new IR(kCreateAssertionStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


/*****************************************************************************
*
*		QUERY :
*				define (aggregate,operator,type)
*
*****************************************************************************/


DefineStmt:

    CREATE opt_or_replace AGGREGATE func_name aggr_args definition {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("CREATE", "AGGREGATE", ""), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kDefineStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | CREATE opt_or_replace AGGREGATE func_name old_aggr_definition {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("CREATE", "AGGREGATE", ""), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kDefineStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | CREATE OPERATOR any_operator definition {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kDefineStmt, OP3("CREATE OPERATOR", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | CREATE TYPE_P any_name definition {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kDefineStmt, OP3("CREATE TYPE", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | CREATE TYPE_P any_name {
        auto tmp1 = $3;
        res = new IR(kDefineStmt, OP3("CREATE TYPE", "", ""), tmp1);
        $$ = res;
    }

    | CREATE TYPE_P any_name AS '(' OptTableFuncElementList ')' {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kDefineStmt, OP3("CREATE TYPE", "AS (", ")"), tmp1, tmp2);
        $$ = res;
    }

    | CREATE TYPE_P any_name AS ENUM_P '(' opt_enum_val_list ')' {
        auto tmp1 = $3;
        auto tmp2 = $7;
        res = new IR(kDefineStmt, OP3("CREATE TYPE", "AS ENUM (", ")"), tmp1, tmp2);
        $$ = res;
    }

    | CREATE TYPE_P any_name AS RANGE definition {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kDefineStmt, OP3("CREATE TYPE", "AS RANGE", ""), tmp1, tmp2);
        $$ = res;
    }

    | CREATE TEXT_P SEARCH PARSER any_name definition {
        auto tmp1 = $5;
        auto tmp2 = $6;
        res = new IR(kDefineStmt, OP3("CREATE TEXT SEARCH PARSER", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | CREATE TEXT_P SEARCH DICTIONARY any_name definition {
        auto tmp1 = $5;
        auto tmp2 = $6;
        res = new IR(kDefineStmt, OP3("CREATE TEXT SEARCH DICTIONARY", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | CREATE TEXT_P SEARCH TEMPLATE any_name definition {
        auto tmp1 = $5;
        auto tmp2 = $6;
        res = new IR(kDefineStmt, OP3("CREATE TEXT SEARCH TEMPLATE", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | CREATE TEXT_P SEARCH CONFIGURATION any_name definition {
        auto tmp1 = $5;
        auto tmp2 = $6;
        res = new IR(kDefineStmt, OP3("CREATE TEXT SEARCH CONFIGURATION", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | CREATE COLLATION any_name definition {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kDefineStmt, OP3("CREATE COLLATION", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | CREATE COLLATION IF_P NOT EXISTS any_name definition {
        auto tmp1 = $6;
        auto tmp2 = $7;
        res = new IR(kDefineStmt, OP3("CREATE COLLATION IF NOT EXISTS", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | CREATE COLLATION any_name FROM any_name {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kDefineStmt, OP3("CREATE COLLATION", "FROM", ""), tmp1, tmp2);
        $$ = res;
    }

    | CREATE COLLATION IF_P NOT EXISTS any_name FROM any_name {
        auto tmp1 = $6;
        auto tmp2 = $8;
        res = new IR(kDefineStmt, OP3("CREATE COLLATION IF NOT EXISTS", "FROM", ""), tmp1, tmp2);
        $$ = res;
    }

;


definition:

    def_list ')' {
        auto tmp1 = $1;
        res = new IR(kDefinition, OP3("", ")", ""), tmp1);
        $$ = res;
    }

;


def_list:

    def_elem {
        auto tmp1 = $1;
        res = new IR(kDefList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | def_list ',' def_elem {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kDefList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


def_elem:

    ColLabel '=' def_arg {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kDefElem, OP3("", "=", ""), tmp1, tmp2);
        $$ = res;
    }

    | ColLabel {
        auto tmp1 = $1;
        res = new IR(kDefElem, OP3("", "", ""), tmp1);
        $$ = res;
    }

;

/* Note: any simple identifier will be returned as a type name! */

def_arg:

    func_type {
        auto tmp1 = $1;
        res = new IR(kDefArg, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | reserved_keyword {
        auto tmp1 = $1;
        res = new IR(kDefArg, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | qual_all_Op {
        auto tmp1 = $1;
        res = new IR(kDefArg, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | NumericOnly {
        auto tmp1 = $1;
        res = new IR(kDefArg, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | Sconst {
        auto tmp1 = $1;
        res = new IR(kDefArg, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | NONE {
        res = new IR(kDefArg, string("NONE"));
        $$ = res;
    }

;


old_aggr_definition:

    old_aggr_list ')' {
        auto tmp1 = $1;
        res = new IR(kOldAggrDefinition, OP3("", ")", ""), tmp1);
        $$ = res;
    }

;


old_aggr_list:

    old_aggr_elem {
        auto tmp1 = $1;
        res = new IR(kOldAggrList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | old_aggr_list ',' old_aggr_elem {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kOldAggrList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;

/*
* Must use IDENT here to avoid reduce/reduce conflicts; fortunately none of
* the item names needed in old aggregate definitions are likely to become
* SQL keywords.
*/

old_aggr_elem:

    IDENT '=' def_arg {
        auto tmp1 = $3;
        res = new IR(kOldAggrElem, OP3("IDENT =", "", ""), tmp1);
        $$ = res;
    }

;


opt_enum_val_list:

    enum_val_list {
        auto tmp1 = $1;
        res = new IR(kOptEnumValList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptEnumValList, string(""));
        $$ = res;
    }

;


enum_val_list:

    Sconst {
        auto tmp1 = $1;
        res = new IR(kEnumValList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | enum_val_list ',' Sconst {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kEnumValList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;

/*****************************************************************************
*
*	ALTER TYPE enumtype ADD ...
*
*****************************************************************************/


AlterEnumStmt:

    ALTER TYPE_P any_name ADD_P VALUE_P opt_if_not_exists Sconst {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kUnknown, OP3("ALTER TYPE", "ADD VALUE", ""), tmp1, tmp2);
        auto tmp3 = $7;
        res = new IR(kAlterEnumStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER TYPE_P any_name ADD_P VALUE_P opt_if_not_exists Sconst BEFORE Sconst {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kUnknown, OP3("ALTER TYPE", "ADD VALUE", ""), tmp1, tmp2);
        auto tmp3 = $7;
        res = new IR(kAlterEnumStmt, OP3("", "BEFORE", ""), res, tmp3);
        $$ = res;
    }

    | ALTER TYPE_P any_name ADD_P VALUE_P opt_if_not_exists Sconst AFTER Sconst {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kUnknown, OP3("ALTER TYPE", "ADD VALUE", ""), tmp1, tmp2);
        auto tmp3 = $7;
        res = new IR(kAlterEnumStmt, OP3("", "AFTER", ""), res, tmp3);
        $$ = res;
    }

    | ALTER TYPE_P any_name RENAME VALUE_P Sconst TO Sconst {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kUnknown, OP3("ALTER TYPE", "RENAME VALUE", "TO"), tmp1, tmp2);
        auto tmp3 = $8;
        res = new IR(kAlterEnumStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


opt_if_not_exists:

    IF_P NOT EXISTS {
        res = new IR(kOptIfNotExists, string("IF NOT EXISTS"));
        $$ = res;
    }

    | /* EMPTY */ {
        res = new IR(kOptIfNotExists, string(""));
        $$ = res;
    }

;


/*****************************************************************************
*
*		QUERIES :
*				CREATE OPERATOR CLASS ...
*				CREATE OPERATOR FAMILY ...
*				ALTER OPERATOR FAMILY ...
*				DROP OPERATOR CLASS ...
*				DROP OPERATOR FAMILY ...
*
*****************************************************************************/


CreateOpClassStmt:

    CREATE OPERATOR CLASS any_name opt_default FOR TYPE_P Typename USING name opt_opfamily AS opclass_item_list {
        auto tmp1 = $4;
        auto tmp2 = $5;
        res = new IR(kUnknown, OP3("CREATE OPERATOR CLASS", "", "FOR TYPE"), tmp1, tmp2);
        auto tmp3 = $8;
        res = new IR(kUnknown, OP3("", "USING", ""), res, tmp3);
        auto tmp4 = $11;
        res = new IR(kCreateOpClassStmt, OP3("", "AS", ""), res, tmp4);
        $$ = res;
    }

;


opclass_item_list:

    opclass_item {
        auto tmp1 = $1;
        res = new IR(kOpclassItemList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | opclass_item_list ',' opclass_item {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kOpclassItemList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


opclass_item:

    OPERATOR Iconst any_operator opclass_purpose opt_recheck {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("OPERATOR", "", ""), tmp1, tmp2);
        auto tmp3 = $4;
        res = new IR(kOpclassItem, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | OPERATOR Iconst operator_with_argtypes opclass_purpose opt_recheck {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("OPERATOR", "", ""), tmp1, tmp2);
        auto tmp3 = $4;
        res = new IR(kOpclassItem, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | FUNCTION Iconst function_with_argtypes {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kOpclassItem, OP3("FUNCTION", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | FUNCTION Iconst '(' type_list ')' function_with_argtypes {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("FUNCTION", "(", ")"), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kOpclassItem, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | STORAGE Typename {
        auto tmp1 = $2;
        res = new IR(kOpclassItem, OP3("STORAGE", "", ""), tmp1);
        $$ = res;
    }

;


opt_default:

    DEFAULT {
        res = new IR(kOptDefault, string("DEFAULT"));
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptDefault, string(""));
        $$ = res;
    }

;


opt_opfamily:

    FAMILY any_name {
        auto tmp1 = $2;
        res = new IR(kOptOpfamily, OP3("FAMILY", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptOpfamily, string(""));
        $$ = res;
    }

;


opclass_purpose:

    FOR SEARCH {
        res = new IR(kOpclassPurpose, string("FOR SEARCH"));
        $$ = res;
    }

    | FOR ORDER BY any_name {
        auto tmp1 = $4;
        res = new IR(kOpclassPurpose, OP3("FOR ORDER BY", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOpclassPurpose, string(""));
        $$ = res;
    }

;


opt_recheck:

    RECHECK {
        res = new IR(kOptRecheck, string("RECHECK"));
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptRecheck, string(""));
        $$ = res;
    }

;



CreateOpFamilyStmt:

    CREATE OPERATOR FAMILY any_name USING name {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kCreateOpFamilyStmt, OP3("CREATE OPERATOR FAMILY", "USING", ""), tmp1, tmp2);
        $$ = res;
    }

;


AlterOpFamilyStmt:

    ALTER OPERATOR FAMILY any_name USING name ADD_P opclass_item_list {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kUnknown, OP3("ALTER OPERATOR FAMILY", "USING", "ADD"), tmp1, tmp2);
        auto tmp3 = $8;
        res = new IR(kAlterOpFamilyStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER OPERATOR FAMILY any_name USING name DROP opclass_drop_list {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kUnknown, OP3("ALTER OPERATOR FAMILY", "USING", "DROP"), tmp1, tmp2);
        auto tmp3 = $8;
        res = new IR(kAlterOpFamilyStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


opclass_drop_list:

    opclass_drop {
        auto tmp1 = $1;
        res = new IR(kOpclassDropList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | opclass_drop_list ',' opclass_drop {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kOpclassDropList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


opclass_drop:

    OPERATOR Iconst '(' type_list ')' {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kOpclassDrop, OP3("OPERATOR", "(", ")"), tmp1, tmp2);
        $$ = res;
    }

    | FUNCTION Iconst '(' type_list ')' {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kOpclassDrop, OP3("FUNCTION", "(", ")"), tmp1, tmp2);
        $$ = res;
    }

;



DropOpClassStmt:

    DROP OPERATOR CLASS any_name USING name opt_drop_behavior {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kUnknown, OP3("DROP OPERATOR CLASS", "USING", ""), tmp1, tmp2);
        auto tmp3 = $7;
        res = new IR(kDropOpClassStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | DROP OPERATOR CLASS IF_P EXISTS any_name USING name opt_drop_behavior {
        auto tmp1 = $6;
        auto tmp2 = $8;
        res = new IR(kUnknown, OP3("DROP OPERATOR CLASS IF EXISTS", "USING", ""), tmp1, tmp2);
        auto tmp3 = $9;
        res = new IR(kDropOpClassStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


DropOpFamilyStmt:

    DROP OPERATOR FAMILY any_name USING name opt_drop_behavior {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kUnknown, OP3("DROP OPERATOR FAMILY", "USING", ""), tmp1, tmp2);
        auto tmp3 = $7;
        res = new IR(kDropOpFamilyStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | DROP OPERATOR FAMILY IF_P EXISTS any_name USING name opt_drop_behavior {
        auto tmp1 = $6;
        auto tmp2 = $8;
        res = new IR(kUnknown, OP3("DROP OPERATOR FAMILY IF EXISTS", "USING", ""), tmp1, tmp2);
        auto tmp3 = $9;
        res = new IR(kDropOpFamilyStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


/*****************************************************************************
*
*		QUERY:
*
*		DROP OWNED BY username [, username ...] [ RESTRICT | CASCADE ]
*		REASSIGN OWNED BY username [, username ...] TO username
*
*****************************************************************************/

DropOwnedStmt:

    DROP OWNED BY role_list opt_drop_behavior {
        auto tmp1 = $4;
        auto tmp2 = $5;
        res = new IR(kDropOwnedStmt, OP3("DROP OWNED BY", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


ReassignOwnedStmt:

    REASSIGN OWNED BY role_list TO RoleSpec {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kReassignOwnedStmt, OP3("REASSIGN OWNED BY", "TO", ""), tmp1, tmp2);
        $$ = res;
    }

;

/*****************************************************************************
*
*		QUERY:
*
*		DROP itemtype [ IF EXISTS ] itemname [, itemname ...]
*           [ RESTRICT | CASCADE ]
*
*****************************************************************************/


DropStmt:

    DROP object_type_any_name IF_P EXISTS any_name_list opt_drop_behavior {
        auto tmp1 = $2;
        auto tmp2 = $5;
        res = new IR(kUnknown, OP3("DROP", "IF EXISTS", ""), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kDropStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | DROP object_type_any_name any_name_list opt_drop_behavior {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("DROP", "", ""), tmp1, tmp2);
        auto tmp3 = $4;
        res = new IR(kDropStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | DROP drop_type_name IF_P EXISTS name_list opt_drop_behavior {
        auto tmp1 = $2;
        auto tmp2 = $5;
        res = new IR(kUnknown, OP3("DROP", "IF EXISTS", ""), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kDropStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | DROP drop_type_name name_list opt_drop_behavior {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("DROP", "", ""), tmp1, tmp2);
        auto tmp3 = $4;
        res = new IR(kDropStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | DROP object_type_name_on_any_name name ON any_name opt_drop_behavior {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("DROP", "", "ON"), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kDropStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | DROP object_type_name_on_any_name IF_P EXISTS name ON any_name opt_drop_behavior {
        auto tmp1 = $2;
        auto tmp2 = $5;
        res = new IR(kUnknown, OP3("DROP", "IF EXISTS", "ON"), tmp1, tmp2);
        auto tmp3 = $7;
        res = new IR(kDropStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | DROP TYPE_P type_name_list opt_drop_behavior {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kDropStmt, OP3("DROP TYPE", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | DROP TYPE_P IF_P EXISTS type_name_list opt_drop_behavior {
        auto tmp1 = $5;
        auto tmp2 = $6;
        res = new IR(kDropStmt, OP3("DROP TYPE IF EXISTS", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | DROP DOMAIN_P type_name_list opt_drop_behavior {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kDropStmt, OP3("DROP DOMAIN", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | DROP DOMAIN_P IF_P EXISTS type_name_list opt_drop_behavior {
        auto tmp1 = $5;
        auto tmp2 = $6;
        res = new IR(kDropStmt, OP3("DROP DOMAIN IF EXISTS", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | DROP INDEX CONCURRENTLY any_name_list opt_drop_behavior {
        auto tmp1 = $4;
        auto tmp2 = $5;
        res = new IR(kDropStmt, OP3("DROP INDEX CONCURRENTLY", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | DROP INDEX CONCURRENTLY IF_P EXISTS any_name_list opt_drop_behavior {
        auto tmp1 = $6;
        auto tmp2 = $7;
        res = new IR(kDropStmt, OP3("DROP INDEX CONCURRENTLY IF EXISTS", "", ""), tmp1, tmp2);
        $$ = res;
    }

;

/* object types taking any_name/any_name_list */

object_type_any_name:

    TABLE {
        res = new IR(kObjectTypeAnyName, string("TABLE"));
        $$ = res;
    }

    | SEQUENCE {
        res = new IR(kObjectTypeAnyName, string("SEQUENCE"));
        $$ = res;
    }

    | VIEW {
        res = new IR(kObjectTypeAnyName, string("VIEW"));
        $$ = res;
    }

    | MATERIALIZED VIEW {
        res = new IR(kObjectTypeAnyName, string("MATERIALIZED VIEW"));
        $$ = res;
    }

    | INDEX {
        res = new IR(kObjectTypeAnyName, string("INDEX"));
        $$ = res;
    }

    | FOREIGN TABLE {
        res = new IR(kObjectTypeAnyName, string("FOREIGN TABLE"));
        $$ = res;
    }

    | COLLATION {
        res = new IR(kObjectTypeAnyName, string("COLLATION"));
        $$ = res;
    }

    | CONVERSION_P {
        res = new IR(kObjectTypeAnyName, string("CONVERSION"));
        $$ = res;
    }

    | STATISTICS {
        res = new IR(kObjectTypeAnyName, string("STATISTICS"));
        $$ = res;
    }

    | TEXT_P SEARCH PARSER {
        res = new IR(kObjectTypeAnyName, string("TEXT SEARCH PARSER"));
        $$ = res;
    }

    | TEXT_P SEARCH DICTIONARY {
        res = new IR(kObjectTypeAnyName, string("TEXT SEARCH DICTIONARY"));
        $$ = res;
    }

    | TEXT_P SEARCH TEMPLATE {
        res = new IR(kObjectTypeAnyName, string("TEXT SEARCH TEMPLATE"));
        $$ = res;
    }

    | TEXT_P SEARCH CONFIGURATION {
        res = new IR(kObjectTypeAnyName, string("TEXT SEARCH CONFIGURATION"));
        $$ = res;
    }

;

/*
* object types taking name/name_list
*
* DROP handles some of them separately
*/


object_type_name:

    drop_type_name {
        auto tmp1 = $1;
        res = new IR(kObjectTypeName, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DATABASE {
        res = new IR(kObjectTypeName, string("DATABASE"));
        $$ = res;
    }

    | ROLE {
        res = new IR(kObjectTypeName, string("ROLE"));
        $$ = res;
    }

    | SUBSCRIPTION {
        res = new IR(kObjectTypeName, string("SUBSCRIPTION"));
        $$ = res;
    }

    | TABLESPACE {
        res = new IR(kObjectTypeName, string("TABLESPACE"));
        $$ = res;
    }

;


drop_type_name:

    ACCESS METHOD {
        res = new IR(kDropTypeName, string("ACCESS METHOD"));
        $$ = res;
    }

    | EVENT TRIGGER {
        res = new IR(kDropTypeName, string("EVENT TRIGGER"));
        $$ = res;
    }

    | EXTENSION {
        res = new IR(kDropTypeName, string("EXTENSION"));
        $$ = res;
    }

    | FOREIGN DATA_P WRAPPER {
        res = new IR(kDropTypeName, string("FOREIGN DATA WRAPPER"));
        $$ = res;
    }

    | opt_procedural LANGUAGE {
        auto tmp1 = $1;
        res = new IR(kDropTypeName, OP3("", "LANGUAGE", ""), tmp1);
        $$ = res;
    }

    | PUBLICATION {
        res = new IR(kDropTypeName, string("PUBLICATION"));
        $$ = res;
    }

    | SCHEMA {
        res = new IR(kDropTypeName, string("SCHEMA"));
        $$ = res;
    }

    | SERVER {
        res = new IR(kDropTypeName, string("SERVER"));
        $$ = res;
    }

;

/* object types attached to a table */

object_type_name_on_any_name:

    POLICY {
        res = new IR(kObjectTypeNameOnAnyName, string("POLICY"));
        $$ = res;
    }

    | RULE {
        res = new IR(kObjectTypeNameOnAnyName, string("RULE"));
        $$ = res;
    }

    | TRIGGER {
        res = new IR(kObjectTypeNameOnAnyName, string("TRIGGER"));
        $$ = res;
    }

;


any_name_list:

    any_name {
        auto tmp1 = $1;
        res = new IR(kAnyNameList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | any_name_list ',' any_name {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAnyNameList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


any_name:

    ColId {
        auto tmp1 = $1;
        res = new IR(kAnyName, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ColId attrs {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAnyName, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


attrs:

    attr_name {
        auto tmp1 = $1;
        res = new IR(kAttrs, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | attrs '.' attr_name {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAttrs, OP3("", ".", ""), tmp1, tmp2);
        $$ = res;
    }

;


type_name_list:

    Typename {
        auto tmp1 = $1;
        res = new IR(kTypeNameList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | type_name_list ',' Typename {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTypeNameList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;

/*****************************************************************************
*
*		QUERY:
*				truncate table relname1, relname2, ...
*
*****************************************************************************/


TruncateStmt:

    TRUNCATE opt_table relation_expr_list opt_restart_seqs opt_drop_behavior {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("TRUNCATE", "", ""), tmp1, tmp2);
        auto tmp3 = $4;
        res = new IR(kTruncateStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


opt_restart_seqs:

    CONTINUE_P IDENTITY_P {
        res = new IR(kOptRestartSeqs, string("CONTINUE IDENTITY"));
        $$ = res;
    }

    | RESTART IDENTITY_P {
        res = new IR(kOptRestartSeqs, string("RESTART IDENTITY"));
        $$ = res;
    }

    | /* EMPTY */ {
        res = new IR(kOptRestartSeqs, string(""));
        $$ = res;
    }

;

/*****************************************************************************
*
* COMMENT ON <object> IS <text>
*
*****************************************************************************/


CommentStmt:

    COMMENT ON object_type_any_name any_name IS comment_text {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("COMMENT ON", "", "IS"), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kCommentStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | COMMENT ON COLUMN any_name IS comment_text {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kCommentStmt, OP3("COMMENT ON COLUMN", "IS", ""), tmp1, tmp2);
        $$ = res;
    }

    | COMMENT ON object_type_name name IS comment_text {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("COMMENT ON", "", "IS"), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kCommentStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | COMMENT ON TYPE_P Typename IS comment_text {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kCommentStmt, OP3("COMMENT ON TYPE", "IS", ""), tmp1, tmp2);
        $$ = res;
    }

    | COMMENT ON DOMAIN_P Typename IS comment_text {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kCommentStmt, OP3("COMMENT ON DOMAIN", "IS", ""), tmp1, tmp2);
        $$ = res;
    }

    | COMMENT ON AGGREGATE aggregate_with_argtypes IS comment_text {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kCommentStmt, OP3("COMMENT ON AGGREGATE", "IS", ""), tmp1, tmp2);
        $$ = res;
    }

    | COMMENT ON FUNCTION function_with_argtypes IS comment_text {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kCommentStmt, OP3("COMMENT ON FUNCTION", "IS", ""), tmp1, tmp2);
        $$ = res;
    }

    | COMMENT ON OPERATOR operator_with_argtypes IS comment_text {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kCommentStmt, OP3("COMMENT ON OPERATOR", "IS", ""), tmp1, tmp2);
        $$ = res;
    }

    | COMMENT ON CONSTRAINT name ON any_name IS comment_text {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kUnknown, OP3("COMMENT ON CONSTRAINT", "ON", "IS"), tmp1, tmp2);
        auto tmp3 = $8;
        res = new IR(kCommentStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | COMMENT ON CONSTRAINT name ON DOMAIN_P any_name IS comment_text {
        auto tmp1 = $4;
        auto tmp2 = $7;
        res = new IR(kUnknown, OP3("COMMENT ON CONSTRAINT", "ON DOMAIN", "IS"), tmp1, tmp2);
        auto tmp3 = $9;
        res = new IR(kCommentStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | COMMENT ON object_type_name_on_any_name name ON any_name IS comment_text {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("COMMENT ON", "", "ON"), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kCommentStmt, OP3("", "IS", ""), res, tmp3);
        $$ = res;
    }

    | COMMENT ON PROCEDURE function_with_argtypes IS comment_text {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kCommentStmt, OP3("COMMENT ON PROCEDURE", "IS", ""), tmp1, tmp2);
        $$ = res;
    }

    | COMMENT ON ROUTINE function_with_argtypes IS comment_text {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kCommentStmt, OP3("COMMENT ON ROUTINE", "IS", ""), tmp1, tmp2);
        $$ = res;
    }

    | COMMENT ON TRANSFORM FOR Typename LANGUAGE name IS comment_text {
        auto tmp1 = $5;
        auto tmp2 = $7;
        res = new IR(kUnknown, OP3("COMMENT ON TRANSFORM FOR", "LANGUAGE", "IS"), tmp1, tmp2);
        auto tmp3 = $9;
        res = new IR(kCommentStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | COMMENT ON OPERATOR CLASS any_name USING name IS comment_text {
        auto tmp1 = $5;
        auto tmp2 = $7;
        res = new IR(kUnknown, OP3("COMMENT ON OPERATOR CLASS", "USING", "IS"), tmp1, tmp2);
        auto tmp3 = $9;
        res = new IR(kCommentStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | COMMENT ON OPERATOR FAMILY any_name USING name IS comment_text {
        auto tmp1 = $5;
        auto tmp2 = $7;
        res = new IR(kUnknown, OP3("COMMENT ON OPERATOR FAMILY", "USING", "IS"), tmp1, tmp2);
        auto tmp3 = $9;
        res = new IR(kCommentStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | COMMENT ON LARGE_P OBJECT_P NumericOnly IS comment_text {
        auto tmp1 = $5;
        auto tmp2 = $7;
        res = new IR(kCommentStmt, OP3("COMMENT ON LARGE OBJECT", "IS", ""), tmp1, tmp2);
        $$ = res;
    }

    | COMMENT ON CAST '(' Typename AS Typename ')' IS comment_text {
        auto tmp1 = $5;
        auto tmp2 = $7;
        res = new IR(kUnknown, OP3("COMMENT ON CAST (", "AS", ") IS"), tmp1, tmp2);
        auto tmp3 = $10;
        res = new IR(kCommentStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


comment_text:

    Sconst {
        auto tmp1 = $1;
        res = new IR(kCommentText, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | NULL_P {
        res = new IR(kCommentText, string("NULL"));
        $$ = res;
    }

;


/*****************************************************************************
*
*  SECURITY LABEL [FOR <provider>] ON <object> IS <label>
*
*  As with COMMENT ON, <object> can refer to various types of database
*  objects (e.g. TABLE, COLUMN, etc.).
*
*****************************************************************************/


SecLabelStmt:

    SECURITY LABEL opt_provider ON object_type_any_name any_name IS security_label {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kUnknown, OP3("SECURITY LABEL", "ON", ""), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kSecLabelStmt, OP3("", "IS", ""), res, tmp3);
        $$ = res;
    }

    | SECURITY LABEL opt_provider ON COLUMN any_name IS security_label {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kUnknown, OP3("SECURITY LABEL", "ON COLUMN", "IS"), tmp1, tmp2);
        auto tmp3 = $8;
        res = new IR(kSecLabelStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | SECURITY LABEL opt_provider ON object_type_name name IS security_label {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kUnknown, OP3("SECURITY LABEL", "ON", ""), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kSecLabelStmt, OP3("", "IS", ""), res, tmp3);
        $$ = res;
    }

    | SECURITY LABEL opt_provider ON TYPE_P Typename IS security_label {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kUnknown, OP3("SECURITY LABEL", "ON TYPE", "IS"), tmp1, tmp2);
        auto tmp3 = $8;
        res = new IR(kSecLabelStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | SECURITY LABEL opt_provider ON DOMAIN_P Typename IS security_label {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kUnknown, OP3("SECURITY LABEL", "ON DOMAIN", "IS"), tmp1, tmp2);
        auto tmp3 = $8;
        res = new IR(kSecLabelStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | SECURITY LABEL opt_provider ON AGGREGATE aggregate_with_argtypes IS security_label {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kUnknown, OP3("SECURITY LABEL", "ON AGGREGATE", "IS"), tmp1, tmp2);
        auto tmp3 = $8;
        res = new IR(kSecLabelStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | SECURITY LABEL opt_provider ON FUNCTION function_with_argtypes IS security_label {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kUnknown, OP3("SECURITY LABEL", "ON FUNCTION", "IS"), tmp1, tmp2);
        auto tmp3 = $8;
        res = new IR(kSecLabelStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | SECURITY LABEL opt_provider ON LARGE_P OBJECT_P NumericOnly IS security_label {
        auto tmp1 = $3;
        auto tmp2 = $7;
        res = new IR(kUnknown, OP3("SECURITY LABEL", "ON LARGE OBJECT", "IS"), tmp1, tmp2);
        auto tmp3 = $9;
        res = new IR(kSecLabelStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | SECURITY LABEL opt_provider ON PROCEDURE function_with_argtypes IS security_label {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kUnknown, OP3("SECURITY LABEL", "ON PROCEDURE", "IS"), tmp1, tmp2);
        auto tmp3 = $8;
        res = new IR(kSecLabelStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | SECURITY LABEL opt_provider ON ROUTINE function_with_argtypes IS security_label {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kUnknown, OP3("SECURITY LABEL", "ON ROUTINE", "IS"), tmp1, tmp2);
        auto tmp3 = $8;
        res = new IR(kSecLabelStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


opt_provider:

    FOR NonReservedWord_or_Sconst {
        auto tmp1 = $2;
        res = new IR(kOptProvider, OP3("FOR", "", ""), tmp1);
        $$ = res;
    }

    | /* EMPTY */ {
        res = new IR(kOptProvider, string(""));
        $$ = res;
    }

;


security_label:

    Sconst {
        auto tmp1 = $1;
        res = new IR(kSecurityLabel, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | NULL_P {
        res = new IR(kSecurityLabel, string("NULL"));
        $$ = res;
    }

;

/*****************************************************************************
*
*		QUERY:
*			fetch/move
*
*****************************************************************************/


FetchStmt:

    FETCH fetch_args {
        auto tmp1 = $2;
        res = new IR(kFetchStmt, OP3("FETCH", "", ""), tmp1);
        $$ = res;
    }

    | MOVE fetch_args {
        auto tmp1 = $2;
        res = new IR(kFetchStmt, OP3("MOVE", "", ""), tmp1);
        $$ = res;
    }

;


fetch_args:

    cursor_name {
        auto tmp1 = $1;
        res = new IR(kFetchArgs, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | from_in cursor_name {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFetchArgs, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | NEXT opt_from_in cursor_name {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kFetchArgs, OP3("NEXT", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | PRIOR opt_from_in cursor_name {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kFetchArgs, OP3("PRIOR", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | FIRST_P opt_from_in cursor_name {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kFetchArgs, OP3("FIRST", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | LAST_P opt_from_in cursor_name {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kFetchArgs, OP3("LAST", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ABSOLUTE_P SignedIconst opt_from_in cursor_name {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("ABSOLUTE", "", ""), tmp1, tmp2);
        auto tmp3 = $4;
        res = new IR(kFetchArgs, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | RELATIVE_P SignedIconst opt_from_in cursor_name {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("RELATIVE", "", ""), tmp1, tmp2);
        auto tmp3 = $4;
        res = new IR(kFetchArgs, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | SignedIconst opt_from_in cursor_name {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUnknown, OP3("", "", ""), tmp1, tmp2);
        auto tmp3 = $3;
        res = new IR(kFetchArgs, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALL opt_from_in cursor_name {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kFetchArgs, OP3("ALL", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | FORWARD opt_from_in cursor_name {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kFetchArgs, OP3("FORWARD", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | FORWARD SignedIconst opt_from_in cursor_name {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("FORWARD", "", ""), tmp1, tmp2);
        auto tmp3 = $4;
        res = new IR(kFetchArgs, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | FORWARD ALL opt_from_in cursor_name {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kFetchArgs, OP3("FORWARD ALL", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | BACKWARD opt_from_in cursor_name {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kFetchArgs, OP3("BACKWARD", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | BACKWARD SignedIconst opt_from_in cursor_name {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("BACKWARD", "", ""), tmp1, tmp2);
        auto tmp3 = $4;
        res = new IR(kFetchArgs, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | BACKWARD ALL opt_from_in cursor_name {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kFetchArgs, OP3("BACKWARD ALL", "", ""), tmp1, tmp2);
        $$ = res;
    }

;

from_in:	   
    FROM {
        $$ = new IR(kFromIn, OP3("FROM", "", ""));
    }
    | IN_P {
        $$ = new IR(kFromIn, OP3("IN", "", ""));
    }
;

opt_from_in:	
    from_in {
        IR* tmp1 = $1;
        $$ = new IR(kOptFromIn, OP0(), tmp1);
    }
    | /* EMPTY */ {
        $$ = new IR(kOptFromIn, OP0());
    }
;


/*****************************************************************************
*
* GRANT and REVOKE statements
*
*****************************************************************************/


GrantStmt:

    GRANT privileges ON privilege_target TO grantee_list opt_grant_grant_option opt_granted_by {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("GRANT", "ON", "TO"), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp3);
        auto tmp4 = $8;
        res = new IR(kGrantStmt, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


RevokeStmt:

    REVOKE privileges ON privilege_target FROM grantee_list opt_granted_by opt_drop_behavior {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("REVOKE", "ON", "FROM"), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp3);
        auto tmp4 = $8;
        res = new IR(kRevokeStmt, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | REVOKE GRANT OPTION FOR privileges ON privilege_target FROM grantee_list opt_granted_by opt_drop_behavior {
        auto tmp1 = $5;
        auto tmp2 = $7;
        res = new IR(kUnknown, OP3("REVOKE GRANT OPTION FOR", "ON", "FROM"), tmp1, tmp2);
        auto tmp3 = $9;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp3);
        auto tmp4 = $11;
        res = new IR(kRevokeStmt, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


/*
* Privilege names are represented as strings; the validity of the privilege
* names gets checked at execution.  This is a bit annoying but we have little
* choice because of the syntactic conflict with lists of role names in
* GRANT/REVOKE.  What's more, we have to call out in the "privilege"
* production any reserved keywords that need to be usable as privilege names.
*/

/* either ALL [PRIVILEGES] or a list of individual privileges */

privileges:

    privilege_list {
        auto tmp1 = $1;
        res = new IR(kPrivileges, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ALL {
        res = new IR(kPrivileges, string("ALL"));
        $$ = res;
    }

    | ALL PRIVILEGES {
        res = new IR(kPrivileges, string("ALL PRIVILEGES"));
        $$ = res;
    }

    | ALL '(' columnList ')' {
        auto tmp1 = $3;
        res = new IR(kPrivileges, OP3("ALL (", ")", ""), tmp1);
        $$ = res;
    }

    | ALL PRIVILEGES '(' columnList ')' {
        auto tmp1 = $4;
        res = new IR(kPrivileges, OP3("ALL PRIVILEGES (", ")", ""), tmp1);
        $$ = res;
    }

;


privilege_list:

    privilege {
        auto tmp1 = $1;
        res = new IR(kPrivilegeList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | privilege_list ',' privilege {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kPrivilegeList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


privilege:

    SELECT opt_column_list {
        auto tmp1 = $2;
        res = new IR(kPrivilege, OP3("SELECT", "", ""), tmp1);
        $$ = res;
    }

    | REFERENCES opt_column_list {
        auto tmp1 = $2;
        res = new IR(kPrivilege, OP3("REFERENCES", "", ""), tmp1);
        $$ = res;
    }

    | CREATE opt_column_list {
        auto tmp1 = $2;
        res = new IR(kPrivilege, OP3("CREATE", "", ""), tmp1);
        $$ = res;
    }

    | ColId opt_column_list {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kPrivilege, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


/* Don't bother trying to fold the first two rules into one using
* opt_table.  You're going to get conflicts.
*/

privilege_target:

    qualified_name_list {
        auto tmp1 = $1;
        res = new IR(kPrivilegeTarget, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | TABLE qualified_name_list {
        auto tmp1 = $2;
        res = new IR(kPrivilegeTarget, OP3("TABLE", "", ""), tmp1);
        $$ = res;
    }

    | SEQUENCE qualified_name_list {
        auto tmp1 = $2;
        res = new IR(kPrivilegeTarget, OP3("SEQUENCE", "", ""), tmp1);
        $$ = res;
    }

    | FOREIGN DATA_P WRAPPER name_list {
        auto tmp1 = $4;
        res = new IR(kPrivilegeTarget, OP3("FOREIGN DATA WRAPPER", "", ""), tmp1);
        $$ = res;
    }

    | FOREIGN SERVER name_list {
        auto tmp1 = $3;
        res = new IR(kPrivilegeTarget, OP3("FOREIGN SERVER", "", ""), tmp1);
        $$ = res;
    }

    | FUNCTION function_with_argtypes_list {
        auto tmp1 = $2;
        res = new IR(kPrivilegeTarget, OP3("FUNCTION", "", ""), tmp1);
        $$ = res;
    }

    | PROCEDURE function_with_argtypes_list {
        auto tmp1 = $2;
        res = new IR(kPrivilegeTarget, OP3("PROCEDURE", "", ""), tmp1);
        $$ = res;
    }

    | ROUTINE function_with_argtypes_list {
        auto tmp1 = $2;
        res = new IR(kPrivilegeTarget, OP3("ROUTINE", "", ""), tmp1);
        $$ = res;
    }

    | DATABASE name_list {
        auto tmp1 = $2;
        res = new IR(kPrivilegeTarget, OP3("DATABASE", "", ""), tmp1);
        $$ = res;
    }

    | DOMAIN_P any_name_list {
        auto tmp1 = $2;
        res = new IR(kPrivilegeTarget, OP3("DOMAIN", "", ""), tmp1);
        $$ = res;
    }

    | LANGUAGE name_list {
        auto tmp1 = $2;
        res = new IR(kPrivilegeTarget, OP3("LANGUAGE", "", ""), tmp1);
        $$ = res;
    }

    | LARGE_P OBJECT_P NumericOnly_list {
        auto tmp1 = $3;
        res = new IR(kPrivilegeTarget, OP3("LARGE OBJECT", "", ""), tmp1);
        $$ = res;
    }

    | SCHEMA name_list {
        auto tmp1 = $2;
        res = new IR(kPrivilegeTarget, OP3("SCHEMA", "", ""), tmp1);
        $$ = res;
    }

    | TABLESPACE name_list {
        auto tmp1 = $2;
        res = new IR(kPrivilegeTarget, OP3("TABLESPACE", "", ""), tmp1);
        $$ = res;
    }

    | TYPE_P any_name_list {
        auto tmp1 = $2;
        res = new IR(kPrivilegeTarget, OP3("TYPE", "", ""), tmp1);
        $$ = res;
    }

    | ALL TABLES IN_P SCHEMA name_list {
        auto tmp1 = $5;
        res = new IR(kPrivilegeTarget, OP3("ALL TABLES IN SCHEMA", "", ""), tmp1);
        $$ = res;
    }

    | ALL SEQUENCES IN_P SCHEMA name_list {
        auto tmp1 = $5;
        res = new IR(kPrivilegeTarget, OP3("ALL SEQUENCES IN SCHEMA", "", ""), tmp1);
        $$ = res;
    }

    | ALL FUNCTIONS IN_P SCHEMA name_list {
        auto tmp1 = $5;
        res = new IR(kPrivilegeTarget, OP3("ALL FUNCTIONS IN SCHEMA", "", ""), tmp1);
        $$ = res;
    }

    | ALL PROCEDURES IN_P SCHEMA name_list {
        auto tmp1 = $5;
        res = new IR(kPrivilegeTarget, OP3("ALL PROCEDURES IN SCHEMA", "", ""), tmp1);
        $$ = res;
    }

    | ALL ROUTINES IN_P SCHEMA name_list {
        auto tmp1 = $5;
        res = new IR(kPrivilegeTarget, OP3("ALL ROUTINES IN SCHEMA", "", ""), tmp1);
        $$ = res;
    }

;



grantee_list:

    grantee {
        auto tmp1 = $1;
        res = new IR(kGranteeList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | grantee_list ',' grantee {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kGranteeList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


grantee:

    RoleSpec {
        auto tmp1 = $1;
        res = new IR(kGrantee, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | GROUP_P RoleSpec {
        auto tmp1 = $2;
        res = new IR(kGrantee, OP3("GROUP", "", ""), tmp1);
        $$ = res;
    }

;



opt_grant_grant_option:

    WITH GRANT OPTION {
        res = new IR(kOptGrantGrantOption, string("WITH GRANT OPTION"));
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptGrantGrantOption, string(""));
        $$ = res;
    }

;

/*****************************************************************************
*
* GRANT and REVOKE ROLE statements
*
*****************************************************************************/


GrantRoleStmt:

    GRANT privilege_list TO role_list opt_grant_admin_option opt_granted_by {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("GRANT", "TO", ""), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kGrantRoleStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


RevokeRoleStmt:

    REVOKE privilege_list FROM role_list opt_granted_by opt_drop_behavior {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("REVOKE", "FROM", ""), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kRevokeRoleStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | REVOKE ADMIN OPTION FOR privilege_list FROM role_list opt_granted_by opt_drop_behavior {
        auto tmp1 = $5;
        auto tmp2 = $7;
        res = new IR(kUnknown, OP3("REVOKE ADMIN OPTION FOR", "FROM", ""), tmp1, tmp2);
        auto tmp3 = $8;
        res = new IR(kRevokeRoleStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


opt_grant_admin_option:

    WITH ADMIN OPTION {
        res = new IR(kOptGrantAdminOption, string("WITH ADMIN OPTION"));
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptGrantAdminOption, string(""));
        $$ = res;
    }

;


opt_granted_by:

    GRANTED BY RoleSpec {
        auto tmp1 = $3;
        res = new IR(kOptGrantedBy, OP3("GRANTED BY", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptGrantedBy, string(""));
        $$ = res;
    }

;

/*****************************************************************************
*
* ALTER DEFAULT PRIVILEGES statement
*
*****************************************************************************/


AlterDefaultPrivilegesStmt:

    ALTER DEFAULT PRIVILEGES DefACLOptionList DefACLAction {
        auto tmp1 = $4;
        auto tmp2 = $5;
        res = new IR(kAlterDefaultPrivilegesStmt, OP3("ALTER DEFAULT PRIVILEGES", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


DefACLOptionList:

    DefACLOptionList DefACLOption {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kDefACLOptionList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | /* EMPTY */ {
        res = new IR(kDefACLOptionList, string(""));
        $$ = res;
    }

;


DefACLOption:

    IN_P SCHEMA name_list {
        auto tmp1 = $3;
        res = new IR(kDefACLOption, OP3("IN SCHEMA", "", ""), tmp1);
        $$ = res;
    }

    | FOR ROLE role_list {
        auto tmp1 = $3;
        res = new IR(kDefACLOption, OP3("FOR ROLE", "", ""), tmp1);
        $$ = res;
    }

    | FOR USER role_list {
        auto tmp1 = $3;
        res = new IR(kDefACLOption, OP3("FOR USER", "", ""), tmp1);
        $$ = res;
    }

;

/*
* This should match GRANT/REVOKE, except that individual target objects
* are not mentioned and we only allow a subset of object types.
*/

DefACLAction:

    GRANT privileges ON defacl_privilege_target TO grantee_list opt_grant_grant_option {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("GRANT", "ON", "TO"), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kDefACLAction, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | REVOKE privileges ON defacl_privilege_target FROM grantee_list opt_drop_behavior {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("REVOKE", "ON", "FROM"), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kDefACLAction, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | REVOKE GRANT OPTION FOR privileges ON defacl_privilege_target FROM grantee_list opt_drop_behavior {
        auto tmp1 = $5;
        auto tmp2 = $7;
        res = new IR(kUnknown, OP3("REVOKE GRANT OPTION FOR", "ON", "FROM"), tmp1, tmp2);
        auto tmp3 = $9;
        res = new IR(kDefACLAction, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


defacl_privilege_target:

    TABLES {
        res = new IR(kDefaclPrivilegeTarget, string("TABLES"));
        $$ = res;
    }

    | FUNCTIONS {
        res = new IR(kDefaclPrivilegeTarget, string("FUNCTIONS"));
        $$ = res;
    }

    | ROUTINES {
        res = new IR(kDefaclPrivilegeTarget, string("ROUTINES"));
        $$ = res;
    }

    | SEQUENCES {
        res = new IR(kDefaclPrivilegeTarget, string("SEQUENCES"));
        $$ = res;
    }

    | TYPES_P {
        res = new IR(kDefaclPrivilegeTarget, string("TYPES"));
        $$ = res;
    }

    | SCHEMAS {
        res = new IR(kDefaclPrivilegeTarget, string("SCHEMAS"));
        $$ = res;
    }

;


/*****************************************************************************
*
*		QUERY: CREATE INDEX
*
* Note: we cannot put TABLESPACE clause after WHERE clause unless we are
* willing to make TABLESPACE a fully reserved word.
*****************************************************************************/


IndexStmt:

    CREATE opt_unique INDEX opt_concurrently opt_index_name ON relation_expr access_method_clause '(' index_params ')' opt_include opt_reloptions OptTableSpace where_clause {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("CREATE", "INDEX", ""), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kUnknown, OP3("", "ON", ""), res, tmp3);
        auto tmp4 = $8;
        res = new IR(kUnknown, OP3("", "(", ")"), res, tmp4);
        auto tmp5 = $12;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp5);
        auto tmp6 = $14;
        res = new IR(kIndexStmt, OP3("", "", ""), res, tmp6);
        $$ = res;
    }

    | CREATE opt_unique INDEX opt_concurrently IF_P NOT EXISTS name ON relation_expr access_method_clause '(' index_params ')' opt_include opt_reloptions OptTableSpace where_clause {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("CREATE", "INDEX", "IF NOT EXISTS"), tmp1, tmp2);
        auto tmp3 = $8;
        res = new IR(kUnknown, OP3("", "ON", ""), res, tmp3);
        auto tmp4 = $11;
        res = new IR(kUnknown, OP3("", "(", ")"), res, tmp4);
        auto tmp5 = $15;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp5);
        auto tmp6 = $17;
        res = new IR(kIndexStmt, OP3("", "", ""), res, tmp6);
        $$ = res;
    }

;


opt_unique:

    UNIQUE {
        res = new IR(kOptUnique, string("UNIQUE"));
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptUnique, string(""));
        $$ = res;
    }

;


opt_concurrently:

    CONCURRENTLY {
        res = new IR(kOptConcurrently, string("CONCURRENTLY"));
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptConcurrently, string(""));
        $$ = res;
    }

;


opt_index_name:

    name {
        auto tmp1 = $1;
        res = new IR(kOptIndexName, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptIndexName, string(""));
        $$ = res;
    }

;


access_method_clause:

    USING name {
        auto tmp1 = $2;
        res = new IR(kAccessMethodClause, OP3("USING", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kAccessMethodClause, string(""));
        $$ = res;
    }

;


index_params:

    index_elem {
        auto tmp1 = $1;
        res = new IR(kIndexParams, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | index_params ',' index_elem {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kIndexParams, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;



index_elem_options:

    opt_collate opt_class opt_asc_desc opt_nulls_order {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUnknown, OP3("", "", ""), tmp1, tmp2);
        auto tmp3 = $3;
        res = new IR(kIndexElemOptions, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | opt_collate any_name reloptions opt_asc_desc opt_nulls_order {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUnknown, OP3("", "", ""), tmp1, tmp2);
        auto tmp3 = $3;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp3);
        auto tmp4 = $5;
        res = new IR(kIndexElemOptions, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;

/*
* Index attributes can be either simple column references, or arbitrary
* expressions in parens.  For backwards-compatibility reasons, we allow
* an expression that's just a function call to be written without parens.
*/

index_elem:

    ColId index_elem_options {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kIndexElem, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | func_expr_windowless index_elem_options {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kIndexElem, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | '(' a_expr ')' index_elem_options {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kIndexElem, OP3("(", ")", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_include:

    INCLUDE '(' index_including_params ')' {
        auto tmp1 = $3;
        res = new IR(kOptInclude, OP3("INCLUDE (", ")", ""), tmp1);
        $$ = res;
    }

    | /* EMPTY */ {
        res = new IR(kOptInclude, string(""));
        $$ = res;
    }

;


index_including_params:

    index_elem {
        auto tmp1 = $1;
        res = new IR(kIndexIncludingParams, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | index_including_params ',' index_elem {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kIndexIncludingParams, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_collate:

    COLLATE any_name {
        auto tmp1 = $2;
        res = new IR(kOptCollate, OP3("COLLATE", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptCollate, string(""));
        $$ = res;
    }

;


opt_class:

    any_name {
        auto tmp1 = $1;
        res = new IR(kOptClass, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptClass, string(""));
        $$ = res;
    }

;


opt_asc_desc:

    ASC {
        res = new IR(kOptAscDesc, string("ASC"));
        $$ = res;
    }

    | DESC {
        res = new IR(kOptAscDesc, string("DESC"));
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptAscDesc, string(""));
        $$ = res;
    }

;


opt_nulls_order:

    NULLS_LA FIRST_P {
        res = new IR(kOptNullsOrder, string("NULLS_LA FIRST"));
        $$ = res;
    }

    | NULLS_LA LAST_P {
        res = new IR(kOptNullsOrder, string("NULLS_LA LAST"));
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptNullsOrder, string(""));
        $$ = res;
    }

;


/*****************************************************************************
*
*		QUERY:
*				create [or replace] function <fname>
*						[(<type-1> { , <type-n>})]
*						returns <type-r>
*						as <filename or code in language as appropriate>
*						language <lang> [with parameters]
*
*****************************************************************************/


CreateFunctionStmt:

    CREATE opt_or_replace FUNCTION func_name func_args_with_defaults RETURNS func_return opt_createfunc_opt_list opt_routine_body {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("CREATE", "FUNCTION", ""), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kUnknown, OP3("", "RETURNS", ""), res, tmp3);
        auto tmp4 = $8;
        res = new IR(kCreateFunctionStmt, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | CREATE opt_or_replace FUNCTION func_name func_args_with_defaults RETURNS TABLE '(' table_func_column_list ')' opt_createfunc_opt_list opt_routine_body {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("CREATE", "FUNCTION", ""), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kUnknown, OP3("", "RETURNS TABLE (", ")"), res, tmp3);
        auto tmp4 = $11;
        res = new IR(kCreateFunctionStmt, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | CREATE opt_or_replace FUNCTION func_name func_args_with_defaults opt_createfunc_opt_list opt_routine_body {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("CREATE", "FUNCTION", ""), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp3);
        auto tmp4 = $7;
        res = new IR(kCreateFunctionStmt, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | CREATE opt_or_replace PROCEDURE func_name func_args_with_defaults opt_createfunc_opt_list opt_routine_body {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("CREATE", "PROCEDURE", ""), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp3);
        auto tmp4 = $7;
        res = new IR(kCreateFunctionStmt, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


opt_or_replace:

    OR REPLACE {
        res = new IR(kOptOrReplace, string("OR REPLACE"));
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptOrReplace, string(""));
        $$ = res;
    }

;


func_args:

    func_args_list ')' {
        auto tmp1 = $1;
        res = new IR(kFuncArgs, OP3("", ")", ""), tmp1);
        $$ = res;
    }

    | '(' ')' {
        res = new IR(kFuncArgs, string("( )"));
        $$ = res;
    }

;


func_args_list:

    func_arg {
        auto tmp1 = $1;
        res = new IR(kFuncArgsList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | func_args_list ',' func_arg {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kFuncArgsList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


function_with_argtypes_list:

    function_with_argtypes {
        auto tmp1 = $1;
        res = new IR(kFunctionWithArgtypesList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | function_with_argtypes_list ',' function_with_argtypes {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kFunctionWithArgtypesList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


function_with_argtypes:

    func_name func_args {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFunctionWithArgtypes, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | type_func_name_keyword {
        auto tmp1 = $1;
        res = new IR(kFunctionWithArgtypes, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ColId {
        auto tmp1 = $1;
        res = new IR(kFunctionWithArgtypes, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ColId indirection {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFunctionWithArgtypes, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;

/*
* func_args_with_defaults is separate because we only want to accept
* defaults in CREATE FUNCTION, not in ALTER etc.
*/

func_args_with_defaults:

    func_args_with_defaults_list ')' {
        auto tmp1 = $1;
        res = new IR(kFuncArgsWithDefaults, OP3("", ")", ""), tmp1);
        $$ = res;
    }

    | '(' ')' {
        res = new IR(kFuncArgsWithDefaults, string("( )"));
        $$ = res;
    }

;


func_args_with_defaults_list:

    func_arg_with_default {
        auto tmp1 = $1;
        res = new IR(kFuncArgsWithDefaultsList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | func_args_with_defaults_list ',' func_arg_with_default {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kFuncArgsWithDefaultsList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;

/*
* The style with arg_class first is SQL99 standard, but Oracle puts
* param_name first; accept both since it's likely people will try both
* anyway.  Don't bother trying to save productions by letting arg_class
* have an empty alternative ... you'll get shift/reduce conflicts.
*
* We can catch over-specified arguments here if we want to,
* but for now better to silently swallow typmod, etc.
* - thomas 2000-03-22
*/

func_arg:

    arg_class param_name func_type {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUnknown, OP3("", "", ""), tmp1, tmp2);
        auto tmp3 = $3;
        res = new IR(kFuncArg, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | param_name arg_class func_type {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUnknown, OP3("", "", ""), tmp1, tmp2);
        auto tmp3 = $3;
        res = new IR(kFuncArg, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | param_name func_type {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFuncArg, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | arg_class func_type {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFuncArg, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | func_type {
        auto tmp1 = $1;
        res = new IR(kFuncArg, OP3("", "", ""), tmp1);
        $$ = res;
    }

;

/* INOUT is SQL99 standard, IN OUT is for Oracle compatibility */

arg_class:

    IN_P {
        res = new IR(kArgClass, string("IN"));
        $$ = res;
    }

    | OUT_P {
        res = new IR(kArgClass, string("OUT"));
        $$ = res;
    }

    | INOUT {
        res = new IR(kArgClass, string("INOUT"));
        $$ = res;
    }

    | IN_P OUT_P {
        res = new IR(kArgClass, string("IN OUT"));
        $$ = res;
    }

    | VARIADIC {
        res = new IR(kArgClass, string("VARIADIC"));
        $$ = res;
    }

;

/*
* Ideally param_name should be ColId, but that causes too many conflicts.
*/

param_name:

    type_function_name {
        auto tmp1 = $1;
        res = new IR(kParamName, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


func_return:

    func_type {
        auto tmp1 = $1;
        res = new IR(kFuncReturn, OP3("", "", ""), tmp1);
        $$ = res;
    }

;

/*
* We would like to make the %TYPE productions here be ColId attrs etc,
* but that causes reduce/reduce conflicts.  type_function_name
* is next best choice.
*/

func_type:

    Typename {
        auto tmp1 = $1;
        res = new IR(kFuncType, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | type_function_name attrs '%' TYPE_P {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFuncType, OP3("", "", "% TYPE"), tmp1, tmp2);
        $$ = res;
    }

    | SETOF type_function_name attrs '%' TYPE_P {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kFuncType, OP3("SETOF", "", "% TYPE"), tmp1, tmp2);
        $$ = res;
    }

;


func_arg_with_default:

    func_arg {
        auto tmp1 = $1;
        res = new IR(kFuncArgWithDefault, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | func_arg DEFAULT a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kFuncArgWithDefault, OP3("", "DEFAULT", ""), tmp1, tmp2);
        $$ = res;
    }

    | func_arg '=' a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kFuncArgWithDefault, OP3("", "=", ""), tmp1, tmp2);
        $$ = res;
    }

;

/* Aggregate args can be most things that function args can be */

aggr_arg:

    func_arg {
        auto tmp1 = $1;
        res = new IR(kAggrArg, OP3("", "", ""), tmp1);
        $$ = res;
    }

;

/*
* The SQL standard offers no guidance on how to declare aggregate argument
* lists, since it doesn't have CREATE AGGREGATE etc.  We accept these cases:
*
* (*)									- normal agg with no args
* (aggr_arg,...)						- normal agg with args
* (ORDER BY aggr_arg,...)				- ordered-set agg with no direct args
* (aggr_arg,... ORDER BY aggr_arg,...)	- ordered-set agg with direct args
*
* The zero-argument case is spelled with '*' for consistency with COUNT(*).
*
* An additional restriction is that if the direct-args list ends in a
* VARIADIC item, the ordered-args list must contain exactly one item that
* is also VARIADIC with the same type.  This allows us to collapse the two
* VARIADIC items into one, which is necessary to represent the aggregate in
* pg_proc.  We check this at the grammar stage so that we can return a list
* in which the second VARIADIC item is already discarded, avoiding extra work
* in cases such as DROP AGGREGATE.
*
* The return value of this production is a two-element list, in which the
* first item is a sublist of FunctionParameter nodes (with any duplicate
* VARIADIC item already dropped, as per above) and the second is an integer
* Value node, containing -1 if there was no ORDER BY and otherwise the number
* of argument declarations before the ORDER BY.  (If this number is equal
* to the first sublist's length, then we dropped a duplicate VARIADIC item.)
* This representation is passed as-is to CREATE AGGREGATE; for operations
* on existing aggregates, we can just apply extractArgTypes to the first
* sublist.
*/

aggr_args:

    aggr_args_list ')' {
        auto tmp1 = $1;
        res = new IR(kAggrArgs, OP3("", ")", ""), tmp1);
        $$ = res;
    }

    | '(' aggr_args_list ')' {
        auto tmp1 = $2;
        res = new IR(kAggrArgs, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

    | '(' ORDER BY aggr_args_list ')' {
        auto tmp1 = $4;
        res = new IR(kAggrArgs, OP3("( ORDER BY", ")", ""), tmp1);
        $$ = res;
    }

    | '(' aggr_args_list ORDER BY aggr_args_list ')' {
        auto tmp1 = $2;
        auto tmp2 = $5;
        res = new IR(kAggrArgs, OP3("(", "ORDER BY", ")"), tmp1, tmp2);
        $$ = res;
    }

;


aggr_args_list:

    aggr_arg {
        auto tmp1 = $1;
        res = new IR(kAggrArgsList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | aggr_args_list ',' aggr_arg {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAggrArgsList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


aggregate_with_argtypes:

    func_name aggr_args {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAggregateWithArgtypes, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


aggregate_with_argtypes_list:

    aggregate_with_argtypes {
        auto tmp1 = $1;
        res = new IR(kAggregateWithArgtypesList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | aggregate_with_argtypes_list ',' aggregate_with_argtypes {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAggregateWithArgtypesList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_createfunc_opt_list:

    createfunc_opt_list {
        auto tmp1 = $1;
        res = new IR(kOptCreatefuncOptList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptCreatefuncOptList, string(""));
        $$ = res;
    }

;


createfunc_opt_list:

    createfunc_opt_item {
        auto tmp1 = $1;
        res = new IR(kCreatefuncOptList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | createfunc_opt_list createfunc_opt_item {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCreatefuncOptList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;

/*
* Options common to both CREATE FUNCTION and ALTER FUNCTION
*/

common_func_opt_item:

    CALLED ON NULL_P INPUT_P {
        res = new IR(kCommonFuncOptItem, string("CALLED ON NULL INPUT"));
        $$ = res;
    }

    | RETURNS NULL_P ON NULL_P INPUT_P {
        res = new IR(kCommonFuncOptItem, string("RETURNS NULL ON NULL INPUT"));
        $$ = res;
    }

    | STRICT_P {
        res = new IR(kCommonFuncOptItem, string("STRICT"));
        $$ = res;
    }

    | IMMUTABLE {
        res = new IR(kCommonFuncOptItem, string("IMMUTABLE"));
        $$ = res;
    }

    | STABLE {
        res = new IR(kCommonFuncOptItem, string("STABLE"));
        $$ = res;
    }

    | VOLATILE {
        res = new IR(kCommonFuncOptItem, string("VOLATILE"));
        $$ = res;
    }

    | EXTERNAL SECURITY DEFINER {
        res = new IR(kCommonFuncOptItem, string("EXTERNAL SECURITY DEFINER"));
        $$ = res;
    }

    | EXTERNAL SECURITY INVOKER {
        res = new IR(kCommonFuncOptItem, string("EXTERNAL SECURITY INVOKER"));
        $$ = res;
    }

    | SECURITY DEFINER {
        res = new IR(kCommonFuncOptItem, string("SECURITY DEFINER"));
        $$ = res;
    }

    | SECURITY INVOKER {
        res = new IR(kCommonFuncOptItem, string("SECURITY INVOKER"));
        $$ = res;
    }

    | LEAKPROOF {
        res = new IR(kCommonFuncOptItem, string("LEAKPROOF"));
        $$ = res;
    }

    | NOT LEAKPROOF {
        res = new IR(kCommonFuncOptItem, string("NOT LEAKPROOF"));
        $$ = res;
    }

    | COST NumericOnly {
        auto tmp1 = $2;
        res = new IR(kCommonFuncOptItem, OP3("COST", "", ""), tmp1);
        $$ = res;
    }

    | ROWS NumericOnly {
        auto tmp1 = $2;
        res = new IR(kCommonFuncOptItem, OP3("ROWS", "", ""), tmp1);
        $$ = res;
    }

    | SUPPORT any_name {
        auto tmp1 = $2;
        res = new IR(kCommonFuncOptItem, OP3("SUPPORT", "", ""), tmp1);
        $$ = res;
    }

    | FunctionSetResetClause {
        auto tmp1 = $1;
        res = new IR(kCommonFuncOptItem, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | PARALLEL ColId {
        auto tmp1 = $2;
        res = new IR(kCommonFuncOptItem, OP3("PARALLEL", "", ""), tmp1);
        $$ = res;
    }

;


createfunc_opt_item:

    AS func_as {
        auto tmp1 = $2;
        res = new IR(kCreatefuncOptItem, OP3("AS", "", ""), tmp1);
        $$ = res;
    }

    | LANGUAGE NonReservedWord_or_Sconst {
        auto tmp1 = $2;
        res = new IR(kCreatefuncOptItem, OP3("LANGUAGE", "", ""), tmp1);
        $$ = res;
    }

    | TRANSFORM transform_type_list {
        auto tmp1 = $2;
        res = new IR(kCreatefuncOptItem, OP3("TRANSFORM", "", ""), tmp1);
        $$ = res;
    }

    | WINDOW {
        res = new IR(kCreatefuncOptItem, string("WINDOW"));
        $$ = res;
    }

    | common_func_opt_item {
        auto tmp1 = $1;
        res = new IR(kCreatefuncOptItem, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


func_as:

    Sconst {
        auto tmp1 = $1;
        res = new IR(kFuncAs, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | Sconst ',' Sconst {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kFuncAs, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


ReturnStmt:

    RETURN a_expr {
        auto tmp1 = $2;
        res = new IR(kReturnStmt, OP3("RETURN", "", ""), tmp1);
        $$ = res;
    }

;


opt_routine_body:

    ReturnStmt {
        auto tmp1 = $1;
        res = new IR(kOptRoutineBody, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | BEGIN_P ATOMIC routine_body_stmt_list END_P {
        auto tmp1 = $3;
        res = new IR(kOptRoutineBody, OP3("BEGIN ATOMIC", "END", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptRoutineBody, string(""));
        $$ = res;
    }

;


routine_body_stmt_list:

    routine_body_stmt_list routine_body_stmt ';' {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kRoutineBodyStmtList, OP3("", "", ";"), tmp1, tmp2);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kRoutineBodyStmtList, string(""));
        $$ = res;
    }

;


routine_body_stmt:

    stmt {
        auto tmp1 = $1;
        res = new IR(kRoutineBodyStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ReturnStmt {
        auto tmp1 = $1;
        res = new IR(kRoutineBodyStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


transform_type_list:

    FOR TYPE_P Typename {
        auto tmp1 = $3;
        res = new IR(kTransformTypeList, OP3("FOR TYPE", "", ""), tmp1);
        $$ = res;
    }

    | transform_type_list ',' FOR TYPE_P Typename {
        auto tmp1 = $1;
        auto tmp2 = $5;
        res = new IR(kTransformTypeList, OP3("", ", FOR TYPE", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_definition:

    WITH definition {
        auto tmp1 = $2;
        res = new IR(kOptDefinition, OP3("WITH", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptDefinition, string(""));
        $$ = res;
    }

;


table_func_column:

    param_name func_type {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kTableFuncColumn, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


table_func_column_list:

    table_func_column {
        auto tmp1 = $1;
        res = new IR(kTableFuncColumnList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | table_func_column_list ',' table_func_column {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTableFuncColumnList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;

/*****************************************************************************
* ALTER FUNCTION / ALTER PROCEDURE / ALTER ROUTINE
*
* RENAME and OWNER subcommands are already provided by the generic
* ALTER infrastructure, here we just specify alterations that can
* only be applied to functions.
*
*****************************************************************************/

AlterFunctionStmt:

    ALTER FUNCTION function_with_argtypes alterfunc_opt_list opt_restrict {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("ALTER FUNCTION", "", ""), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kAlterFunctionStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER PROCEDURE function_with_argtypes alterfunc_opt_list opt_restrict {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("ALTER PROCEDURE", "", ""), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kAlterFunctionStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER ROUTINE function_with_argtypes alterfunc_opt_list opt_restrict {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("ALTER ROUTINE", "", ""), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kAlterFunctionStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


alterfunc_opt_list:

    common_func_opt_item {
        auto tmp1 = $1;
        res = new IR(kAlterfuncOptList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | alterfunc_opt_list common_func_opt_item {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAlterfuncOptList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;

/* Ignored, merely for SQL compliance */
opt_restrict:
    RESTRICT {
        $$ = new IR(kOptRestrict, OP3("RESTRICT", "", ""));
    }
    | /* EMPTY */ {
        $$ = new IR(kOptRestrict, OP0());
    }
;


/*****************************************************************************
*
*		QUERY:
*
*		DROP FUNCTION funcname (arg1, arg2, ...) [ RESTRICT | CASCADE ]
*		DROP PROCEDURE procname (arg1, arg2, ...) [ RESTRICT | CASCADE ]
*		DROP ROUTINE routname (arg1, arg2, ...) [ RESTRICT | CASCADE ]
*		DROP AGGREGATE aggname (arg1, ...) [ RESTRICT | CASCADE ]
*		DROP OPERATOR opname (leftoperand_typ, rightoperand_typ) [ RESTRICT | CASCADE ]
*
*****************************************************************************/


RemoveFuncStmt:

    DROP FUNCTION function_with_argtypes_list opt_drop_behavior {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kRemoveFuncStmt, OP3("DROP FUNCTION", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | DROP FUNCTION IF_P EXISTS function_with_argtypes_list opt_drop_behavior {
        auto tmp1 = $5;
        auto tmp2 = $6;
        res = new IR(kRemoveFuncStmt, OP3("DROP FUNCTION IF EXISTS", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | DROP PROCEDURE function_with_argtypes_list opt_drop_behavior {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kRemoveFuncStmt, OP3("DROP PROCEDURE", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | DROP PROCEDURE IF_P EXISTS function_with_argtypes_list opt_drop_behavior {
        auto tmp1 = $5;
        auto tmp2 = $6;
        res = new IR(kRemoveFuncStmt, OP3("DROP PROCEDURE IF EXISTS", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | DROP ROUTINE function_with_argtypes_list opt_drop_behavior {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kRemoveFuncStmt, OP3("DROP ROUTINE", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | DROP ROUTINE IF_P EXISTS function_with_argtypes_list opt_drop_behavior {
        auto tmp1 = $5;
        auto tmp2 = $6;
        res = new IR(kRemoveFuncStmt, OP3("DROP ROUTINE IF EXISTS", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


RemoveAggrStmt:

    DROP AGGREGATE aggregate_with_argtypes_list opt_drop_behavior {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kRemoveAggrStmt, OP3("DROP AGGREGATE", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | DROP AGGREGATE IF_P EXISTS aggregate_with_argtypes_list opt_drop_behavior {
        auto tmp1 = $5;
        auto tmp2 = $6;
        res = new IR(kRemoveAggrStmt, OP3("DROP AGGREGATE IF EXISTS", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


RemoveOperStmt:

    DROP OPERATOR operator_with_argtypes_list opt_drop_behavior {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kRemoveOperStmt, OP3("DROP OPERATOR", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | DROP OPERATOR IF_P EXISTS operator_with_argtypes_list opt_drop_behavior {
        auto tmp1 = $5;
        auto tmp2 = $6;
        res = new IR(kRemoveOperStmt, OP3("DROP OPERATOR IF EXISTS", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


oper_argtypes:

    Typename ')' {
        auto tmp1 = $1;
        res = new IR(kOperArgtypes, OP3("", ")", ""), tmp1);
        $$ = res;
    }

    | '(' Typename ',' Typename ')' {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kOperArgtypes, OP3("(", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

    | '(' NONE ',' Typename ')' {
        auto tmp1 = $4;
        res = new IR(kOperArgtypes, OP3("( NONE ,", ")", ""), tmp1);
        $$ = res;
    }

    | '(' Typename ',' NONE ')' {
        auto tmp1 = $2;
        res = new IR(kOperArgtypes, OP3("(", ", NONE )", ""), tmp1);
        $$ = res;
    }

;


any_operator:

    all_Op {
        auto tmp1 = $1;
        res = new IR(kAnyOperator, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ColId '.' any_operator {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAnyOperator, OP3("", ".", ""), tmp1, tmp2);
        $$ = res;
    }

;


operator_with_argtypes_list:

    operator_with_argtypes {
        auto tmp1 = $1;
        res = new IR(kOperatorWithArgtypesList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | operator_with_argtypes_list ',' operator_with_argtypes {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kOperatorWithArgtypesList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


operator_with_argtypes:

    any_operator oper_argtypes {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOperatorWithArgtypes, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;

/*****************************************************************************
*
*		DO <anonymous code block> [ LANGUAGE language ]
*
* We use a DefElem list for future extensibility, and to allow flexibility
* in the clause order.
*
*****************************************************************************/


DoStmt:

    DO dostmt_opt_list {
        auto tmp1 = $2;
        res = new IR(kDoStmt, OP3("DO", "", ""), tmp1);
        $$ = res;
    }

;


dostmt_opt_list:

    dostmt_opt_item {
        auto tmp1 = $1;
        res = new IR(kDostmtOptList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | dostmt_opt_list dostmt_opt_item {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kDostmtOptList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


dostmt_opt_item:

    Sconst {
        auto tmp1 = $1;
        res = new IR(kDostmtOptItem, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | LANGUAGE NonReservedWord_or_Sconst {
        auto tmp1 = $2;
        res = new IR(kDostmtOptItem, OP3("LANGUAGE", "", ""), tmp1);
        $$ = res;
    }

;

/*****************************************************************************
*
*		CREATE CAST / DROP CAST
*
*****************************************************************************/


CreateCastStmt:

    CREATE CAST '(' Typename AS Typename ')' WITH FUNCTION function_with_argtypes cast_context {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kUnknown, OP3("CREATE CAST (", "AS", ") WITH FUNCTION"), tmp1, tmp2);
        auto tmp3 = $10;
        res = new IR(kCreateCastStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | CREATE CAST '(' Typename AS Typename ')' WITHOUT FUNCTION cast_context {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kUnknown, OP3("CREATE CAST (", "AS", ") WITHOUT FUNCTION"), tmp1, tmp2);
        auto tmp3 = $10;
        res = new IR(kCreateCastStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | CREATE CAST '(' Typename AS Typename ')' WITH INOUT cast_context {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kUnknown, OP3("CREATE CAST (", "AS", ") WITH INOUT"), tmp1, tmp2);
        auto tmp3 = $10;
        res = new IR(kCreateCastStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


cast_context:

    AS IMPLICIT_P {
        res = new IR(kCastContext, string("AS IMPLICIT"));
        $$ = res;
    }

    | AS ASSIGNMENT {
        res = new IR(kCastContext, string("AS ASSIGNMENT"));
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kCastContext, string(""));
        $$ = res;
    }

;



DropCastStmt:

    DROP CAST opt_if_exists '(' Typename AS Typename ')' opt_drop_behavior {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kUnknown, OP3("DROP CAST", "(", "AS"), tmp1, tmp2);
        auto tmp3 = $7;
        res = new IR(kDropCastStmt, OP3("", ")", ""), res, tmp3);
        $$ = res;
    }

;


opt_if_exists:

    IF_P EXISTS {
        res = new IR(kOptIfExists, string("IF EXISTS"));
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptIfExists, string(""));
        $$ = res;
    }

;


/*****************************************************************************
*
*		CREATE TRANSFORM / DROP TRANSFORM
*
*****************************************************************************/


CreateTransformStmt:

    CREATE opt_or_replace TRANSFORM FOR Typename LANGUAGE name '(' transform_element_list ')' {
        auto tmp1 = $2;
        auto tmp2 = $5;
        res = new IR(kUnknown, OP3("CREATE", "TRANSFORM FOR", "LANGUAGE"), tmp1, tmp2);
        auto tmp3 = $7;
        res = new IR(kCreateTransformStmt, OP3("", "(", ")"), res, tmp3);
        $$ = res;
    }

;


transform_element_list:

    FROM SQL_P WITH FUNCTION function_with_argtypes ',' TO SQL_P WITH FUNCTION function_with_argtypes {
        auto tmp1 = $5;
        auto tmp2 = $11;
        res = new IR(kTransformElementList, OP3("FROM SQL WITH FUNCTION", ", TO SQL WITH FUNCTION", ""), tmp1, tmp2);
        $$ = res;
    }

    | TO SQL_P WITH FUNCTION function_with_argtypes ',' FROM SQL_P WITH FUNCTION function_with_argtypes {
        auto tmp1 = $5;
        auto tmp2 = $11;
        res = new IR(kTransformElementList, OP3("TO SQL WITH FUNCTION", ", FROM SQL WITH FUNCTION", ""), tmp1, tmp2);
        $$ = res;
    }

    | FROM SQL_P WITH FUNCTION function_with_argtypes {
        auto tmp1 = $5;
        res = new IR(kTransformElementList, OP3("FROM SQL WITH FUNCTION", "", ""), tmp1);
        $$ = res;
    }

    | TO SQL_P WITH FUNCTION function_with_argtypes {
        auto tmp1 = $5;
        res = new IR(kTransformElementList, OP3("TO SQL WITH FUNCTION", "", ""), tmp1);
        $$ = res;
    }

;



DropTransformStmt:

    DROP TRANSFORM opt_if_exists FOR Typename LANGUAGE name opt_drop_behavior {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kUnknown, OP3("DROP TRANSFORM", "FOR", "LANGUAGE"), tmp1, tmp2);
        auto tmp3 = $7;
        res = new IR(kDropTransformStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


/*****************************************************************************
*
*		QUERY:
*
*		REINDEX [ (options) ] type [CONCURRENTLY] <name>
*****************************************************************************/


ReindexStmt:

    REINDEX reindex_target_type opt_concurrently qualified_name {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("REINDEX", "", ""), tmp1, tmp2);
        auto tmp3 = $4;
        res = new IR(kReindexStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | REINDEX reindex_target_multitable opt_concurrently name {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("REINDEX", "", ""), tmp1, tmp2);
        auto tmp3 = $4;
        res = new IR(kReindexStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | REINDEX '(' utility_option_list ')' reindex_target_type opt_concurrently qualified_name {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kUnknown, OP3("REINDEX (", ")", ""), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kReindexStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | REINDEX '(' utility_option_list ')' reindex_target_multitable opt_concurrently name {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kUnknown, OP3("REINDEX (", ")", ""), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kReindexStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;

reindex_target_type:

    INDEX {
        res = new IR(kReindexTargetType, string("INDEX"));
        $$ = res;
    }

    | TABLE {
        res = new IR(kReindexTargetType, string("TABLE"));
        $$ = res;
    }

;

reindex_target_multitable:

    SCHEMA {
        res = new IR(kReindexTargetMultitable, string("SCHEMA"));
        $$ = res;
    }

    | SYSTEM_P {
        res = new IR(kReindexTargetMultitable, string("SYSTEM"));
        $$ = res;
    }

    | DATABASE {
        res = new IR(kReindexTargetMultitable, string("DATABASE"));
        $$ = res;
    }

;

/*****************************************************************************
*
* ALTER TABLESPACE
*
*****************************************************************************/


AlterTblSpcStmt:

    ALTER TABLESPACE name SET reloptions {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kAlterTblSpcStmt, OP3("ALTER TABLESPACE", "SET", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER TABLESPACE name RESET reloptions {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kAlterTblSpcStmt, OP3("ALTER TABLESPACE", "RESET", ""), tmp1, tmp2);
        $$ = res;
    }

;

/*****************************************************************************
*
* ALTER THING name RENAME TO newname
*
*****************************************************************************/


RenameStmt:

    ALTER AGGREGATE aggregate_with_argtypes RENAME TO name {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kRenameStmt, OP3("ALTER AGGREGATE", "RENAME TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER COLLATION any_name RENAME TO name {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kRenameStmt, OP3("ALTER COLLATION", "RENAME TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER CONVERSION_P any_name RENAME TO name {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kRenameStmt, OP3("ALTER CONVERSION", "RENAME TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER DATABASE name RENAME TO name {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kRenameStmt, OP3("ALTER DATABASE", "RENAME TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER DOMAIN_P any_name RENAME TO name {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kRenameStmt, OP3("ALTER DOMAIN", "RENAME TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER DOMAIN_P any_name RENAME CONSTRAINT name TO name {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kUnknown, OP3("ALTER DOMAIN", "RENAME CONSTRAINT", "TO"), tmp1, tmp2);
        auto tmp3 = $8;
        res = new IR(kRenameStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER FOREIGN DATA_P WRAPPER name RENAME TO name {
        auto tmp1 = $5;
        auto tmp2 = $8;
        res = new IR(kRenameStmt, OP3("ALTER FOREIGN DATA WRAPPER", "RENAME TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER FUNCTION function_with_argtypes RENAME TO name {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kRenameStmt, OP3("ALTER FUNCTION", "RENAME TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER GROUP_P RoleId RENAME TO RoleId {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kRenameStmt, OP3("ALTER GROUP", "RENAME TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER opt_procedural LANGUAGE name RENAME TO name {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("ALTER", "LANGUAGE", "RENAME TO"), tmp1, tmp2);
        auto tmp3 = $7;
        res = new IR(kRenameStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER OPERATOR CLASS any_name USING name RENAME TO name {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kUnknown, OP3("ALTER OPERATOR CLASS", "USING", "RENAME TO"), tmp1, tmp2);
        auto tmp3 = $9;
        res = new IR(kRenameStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER OPERATOR FAMILY any_name USING name RENAME TO name {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kUnknown, OP3("ALTER OPERATOR FAMILY", "USING", "RENAME TO"), tmp1, tmp2);
        auto tmp3 = $9;
        res = new IR(kRenameStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER POLICY name ON qualified_name RENAME TO name {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kUnknown, OP3("ALTER POLICY", "ON", "RENAME TO"), tmp1, tmp2);
        auto tmp3 = $8;
        res = new IR(kRenameStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER POLICY IF_P EXISTS name ON qualified_name RENAME TO name {
        auto tmp1 = $5;
        auto tmp2 = $7;
        res = new IR(kUnknown, OP3("ALTER POLICY IF EXISTS", "ON", "RENAME TO"), tmp1, tmp2);
        auto tmp3 = $10;
        res = new IR(kRenameStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER PROCEDURE function_with_argtypes RENAME TO name {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kRenameStmt, OP3("ALTER PROCEDURE", "RENAME TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER PUBLICATION name RENAME TO name {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kRenameStmt, OP3("ALTER PUBLICATION", "RENAME TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER ROUTINE function_with_argtypes RENAME TO name {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kRenameStmt, OP3("ALTER ROUTINE", "RENAME TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER SCHEMA name RENAME TO name {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kRenameStmt, OP3("ALTER SCHEMA", "RENAME TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER SERVER name RENAME TO name {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kRenameStmt, OP3("ALTER SERVER", "RENAME TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER SUBSCRIPTION name RENAME TO name {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kRenameStmt, OP3("ALTER SUBSCRIPTION", "RENAME TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER TABLE relation_expr RENAME TO name {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kRenameStmt, OP3("ALTER TABLE", "RENAME TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER TABLE IF_P EXISTS relation_expr RENAME TO name {
        auto tmp1 = $5;
        auto tmp2 = $8;
        res = new IR(kRenameStmt, OP3("ALTER TABLE IF EXISTS", "RENAME TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER SEQUENCE qualified_name RENAME TO name {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kRenameStmt, OP3("ALTER SEQUENCE", "RENAME TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER SEQUENCE IF_P EXISTS qualified_name RENAME TO name {
        auto tmp1 = $5;
        auto tmp2 = $8;
        res = new IR(kRenameStmt, OP3("ALTER SEQUENCE IF EXISTS", "RENAME TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER VIEW qualified_name RENAME TO name {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kRenameStmt, OP3("ALTER VIEW", "RENAME TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER VIEW IF_P EXISTS qualified_name RENAME TO name {
        auto tmp1 = $5;
        auto tmp2 = $8;
        res = new IR(kRenameStmt, OP3("ALTER VIEW IF EXISTS", "RENAME TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER MATERIALIZED VIEW qualified_name RENAME TO name {
        auto tmp1 = $4;
        auto tmp2 = $7;
        res = new IR(kRenameStmt, OP3("ALTER MATERIALIZED VIEW", "RENAME TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER MATERIALIZED VIEW IF_P EXISTS qualified_name RENAME TO name {
        auto tmp1 = $6;
        auto tmp2 = $9;
        res = new IR(kRenameStmt, OP3("ALTER MATERIALIZED VIEW IF EXISTS", "RENAME TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER INDEX qualified_name RENAME TO name {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kRenameStmt, OP3("ALTER INDEX", "RENAME TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER INDEX IF_P EXISTS qualified_name RENAME TO name {
        auto tmp1 = $5;
        auto tmp2 = $8;
        res = new IR(kRenameStmt, OP3("ALTER INDEX IF EXISTS", "RENAME TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER FOREIGN TABLE relation_expr RENAME TO name {
        auto tmp1 = $4;
        auto tmp2 = $7;
        res = new IR(kRenameStmt, OP3("ALTER FOREIGN TABLE", "RENAME TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER FOREIGN TABLE IF_P EXISTS relation_expr RENAME TO name {
        auto tmp1 = $6;
        auto tmp2 = $9;
        res = new IR(kRenameStmt, OP3("ALTER FOREIGN TABLE IF EXISTS", "RENAME TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER TABLE relation_expr RENAME opt_column name TO name {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kUnknown, OP3("ALTER TABLE", "RENAME", ""), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kRenameStmt, OP3("", "TO", ""), res, tmp3);
        $$ = res;
    }

    | ALTER TABLE IF_P EXISTS relation_expr RENAME opt_column name TO name {
        auto tmp1 = $5;
        auto tmp2 = $7;
        res = new IR(kUnknown, OP3("ALTER TABLE IF EXISTS", "RENAME", ""), tmp1, tmp2);
        auto tmp3 = $8;
        res = new IR(kRenameStmt, OP3("", "TO", ""), res, tmp3);
        $$ = res;
    }

    | ALTER VIEW qualified_name RENAME opt_column name TO name {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kUnknown, OP3("ALTER VIEW", "RENAME", ""), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kRenameStmt, OP3("", "TO", ""), res, tmp3);
        $$ = res;
    }

    | ALTER VIEW IF_P EXISTS qualified_name RENAME opt_column name TO name {
        auto tmp1 = $5;
        auto tmp2 = $7;
        res = new IR(kUnknown, OP3("ALTER VIEW IF EXISTS", "RENAME", ""), tmp1, tmp2);
        auto tmp3 = $8;
        res = new IR(kRenameStmt, OP3("", "TO", ""), res, tmp3);
        $$ = res;
    }

    | ALTER MATERIALIZED VIEW qualified_name RENAME opt_column name TO name {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kUnknown, OP3("ALTER MATERIALIZED VIEW", "RENAME", ""), tmp1, tmp2);
        auto tmp3 = $7;
        res = new IR(kRenameStmt, OP3("", "TO", ""), res, tmp3);
        $$ = res;
    }

    | ALTER MATERIALIZED VIEW IF_P EXISTS qualified_name RENAME opt_column name TO name {
        auto tmp1 = $6;
        auto tmp2 = $8;
        res = new IR(kUnknown, OP3("ALTER MATERIALIZED VIEW IF EXISTS", "RENAME", ""), tmp1, tmp2);
        auto tmp3 = $9;
        res = new IR(kRenameStmt, OP3("", "TO", ""), res, tmp3);
        $$ = res;
    }

    | ALTER TABLE relation_expr RENAME CONSTRAINT name TO name {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kUnknown, OP3("ALTER TABLE", "RENAME CONSTRAINT", "TO"), tmp1, tmp2);
        auto tmp3 = $8;
        res = new IR(kRenameStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER TABLE IF_P EXISTS relation_expr RENAME CONSTRAINT name TO name {
        auto tmp1 = $5;
        auto tmp2 = $8;
        res = new IR(kUnknown, OP3("ALTER TABLE IF EXISTS", "RENAME CONSTRAINT", "TO"), tmp1, tmp2);
        auto tmp3 = $10;
        res = new IR(kRenameStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER FOREIGN TABLE relation_expr RENAME opt_column name TO name {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kUnknown, OP3("ALTER FOREIGN TABLE", "RENAME", ""), tmp1, tmp2);
        auto tmp3 = $7;
        res = new IR(kRenameStmt, OP3("", "TO", ""), res, tmp3);
        $$ = res;
    }

    | ALTER FOREIGN TABLE IF_P EXISTS relation_expr RENAME opt_column name TO name {
        auto tmp1 = $6;
        auto tmp2 = $8;
        res = new IR(kUnknown, OP3("ALTER FOREIGN TABLE IF EXISTS", "RENAME", ""), tmp1, tmp2);
        auto tmp3 = $9;
        res = new IR(kRenameStmt, OP3("", "TO", ""), res, tmp3);
        $$ = res;
    }

    | ALTER RULE name ON qualified_name RENAME TO name {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kUnknown, OP3("ALTER RULE", "ON", "RENAME TO"), tmp1, tmp2);
        auto tmp3 = $8;
        res = new IR(kRenameStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER TRIGGER name ON qualified_name RENAME TO name {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kUnknown, OP3("ALTER TRIGGER", "ON", "RENAME TO"), tmp1, tmp2);
        auto tmp3 = $8;
        res = new IR(kRenameStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER EVENT TRIGGER name RENAME TO name {
        auto tmp1 = $4;
        auto tmp2 = $7;
        res = new IR(kRenameStmt, OP3("ALTER EVENT TRIGGER", "RENAME TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER ROLE RoleId RENAME TO RoleId {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kRenameStmt, OP3("ALTER ROLE", "RENAME TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER USER RoleId RENAME TO RoleId {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kRenameStmt, OP3("ALTER USER", "RENAME TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER TABLESPACE name RENAME TO name {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kRenameStmt, OP3("ALTER TABLESPACE", "RENAME TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER STATISTICS any_name RENAME TO name {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kRenameStmt, OP3("ALTER STATISTICS", "RENAME TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER TEXT_P SEARCH PARSER any_name RENAME TO name {
        auto tmp1 = $5;
        auto tmp2 = $8;
        res = new IR(kRenameStmt, OP3("ALTER TEXT SEARCH PARSER", "RENAME TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER TEXT_P SEARCH DICTIONARY any_name RENAME TO name {
        auto tmp1 = $5;
        auto tmp2 = $8;
        res = new IR(kRenameStmt, OP3("ALTER TEXT SEARCH DICTIONARY", "RENAME TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER TEXT_P SEARCH TEMPLATE any_name RENAME TO name {
        auto tmp1 = $5;
        auto tmp2 = $8;
        res = new IR(kRenameStmt, OP3("ALTER TEXT SEARCH TEMPLATE", "RENAME TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER TEXT_P SEARCH CONFIGURATION any_name RENAME TO name {
        auto tmp1 = $5;
        auto tmp2 = $8;
        res = new IR(kRenameStmt, OP3("ALTER TEXT SEARCH CONFIGURATION", "RENAME TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER TYPE_P any_name RENAME TO name {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kRenameStmt, OP3("ALTER TYPE", "RENAME TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER TYPE_P any_name RENAME ATTRIBUTE name TO name opt_drop_behavior {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kUnknown, OP3("ALTER TYPE", "RENAME ATTRIBUTE", "TO"), tmp1, tmp2);
        auto tmp3 = $8;
        res = new IR(kRenameStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;

opt_column: 
    COLUMN {
        $$ = new IR(kOptColumn, OP3("COLUMN", "", ""));
    }
    | /*EMPTY*/ {
        $$ = new IR(kOptColumn, OP0());
    }
;


opt_set_data:

    SET DATA_P {
        res = new IR(kOptSetData, string("SET DATA"));
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptSetData, string(""));
        $$ = res;
    }

;

/*****************************************************************************
*
* ALTER THING name DEPENDS ON EXTENSION name
*
*****************************************************************************/


AlterObjectDependsStmt:

    ALTER FUNCTION function_with_argtypes opt_no DEPENDS ON EXTENSION name {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("ALTER FUNCTION", "", "DEPENDS ON EXTENSION"), tmp1, tmp2);
        auto tmp3 = $8;
        res = new IR(kAlterObjectDependsStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER PROCEDURE function_with_argtypes opt_no DEPENDS ON EXTENSION name {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("ALTER PROCEDURE", "", "DEPENDS ON EXTENSION"), tmp1, tmp2);
        auto tmp3 = $8;
        res = new IR(kAlterObjectDependsStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER ROUTINE function_with_argtypes opt_no DEPENDS ON EXTENSION name {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("ALTER ROUTINE", "", "DEPENDS ON EXTENSION"), tmp1, tmp2);
        auto tmp3 = $8;
        res = new IR(kAlterObjectDependsStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER TRIGGER name ON qualified_name opt_no DEPENDS ON EXTENSION name {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kUnknown, OP3("ALTER TRIGGER", "ON", ""), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kAlterObjectDependsStmt, OP3("", "DEPENDS ON EXTENSION", ""), res, tmp3);
        $$ = res;
    }

    | ALTER MATERIALIZED VIEW qualified_name opt_no DEPENDS ON EXTENSION name {
        auto tmp1 = $4;
        auto tmp2 = $5;
        res = new IR(kUnknown, OP3("ALTER MATERIALIZED VIEW", "", "DEPENDS ON EXTENSION"), tmp1, tmp2);
        auto tmp3 = $9;
        res = new IR(kAlterObjectDependsStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER INDEX qualified_name opt_no DEPENDS ON EXTENSION name {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("ALTER INDEX", "", "DEPENDS ON EXTENSION"), tmp1, tmp2);
        auto tmp3 = $8;
        res = new IR(kAlterObjectDependsStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


opt_no:

    NO {
        res = new IR(kOptNo, string("NO"));
        $$ = res;
    }

    | /* EMPTY */ {
        res = new IR(kOptNo, string(""));
        $$ = res;
    }

;

/*****************************************************************************
*
* ALTER THING name SET SCHEMA name
*
*****************************************************************************/


AlterObjectSchemaStmt:

    ALTER AGGREGATE aggregate_with_argtypes SET SCHEMA name {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kAlterObjectSchemaStmt, OP3("ALTER AGGREGATE", "SET SCHEMA", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER COLLATION any_name SET SCHEMA name {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kAlterObjectSchemaStmt, OP3("ALTER COLLATION", "SET SCHEMA", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER CONVERSION_P any_name SET SCHEMA name {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kAlterObjectSchemaStmt, OP3("ALTER CONVERSION", "SET SCHEMA", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER DOMAIN_P any_name SET SCHEMA name {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kAlterObjectSchemaStmt, OP3("ALTER DOMAIN", "SET SCHEMA", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER EXTENSION name SET SCHEMA name {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kAlterObjectSchemaStmt, OP3("ALTER EXTENSION", "SET SCHEMA", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER FUNCTION function_with_argtypes SET SCHEMA name {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kAlterObjectSchemaStmt, OP3("ALTER FUNCTION", "SET SCHEMA", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER OPERATOR operator_with_argtypes SET SCHEMA name {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kAlterObjectSchemaStmt, OP3("ALTER OPERATOR", "SET SCHEMA", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER OPERATOR CLASS any_name USING name SET SCHEMA name {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kUnknown, OP3("ALTER OPERATOR CLASS", "USING", "SET SCHEMA"), tmp1, tmp2);
        auto tmp3 = $9;
        res = new IR(kAlterObjectSchemaStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER OPERATOR FAMILY any_name USING name SET SCHEMA name {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kUnknown, OP3("ALTER OPERATOR FAMILY", "USING", "SET SCHEMA"), tmp1, tmp2);
        auto tmp3 = $9;
        res = new IR(kAlterObjectSchemaStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER PROCEDURE function_with_argtypes SET SCHEMA name {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kAlterObjectSchemaStmt, OP3("ALTER PROCEDURE", "SET SCHEMA", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER ROUTINE function_with_argtypes SET SCHEMA name {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kAlterObjectSchemaStmt, OP3("ALTER ROUTINE", "SET SCHEMA", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER TABLE relation_expr SET SCHEMA name {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kAlterObjectSchemaStmt, OP3("ALTER TABLE", "SET SCHEMA", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER TABLE IF_P EXISTS relation_expr SET SCHEMA name {
        auto tmp1 = $5;
        auto tmp2 = $8;
        res = new IR(kAlterObjectSchemaStmt, OP3("ALTER TABLE IF EXISTS", "SET SCHEMA", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER STATISTICS any_name SET SCHEMA name {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kAlterObjectSchemaStmt, OP3("ALTER STATISTICS", "SET SCHEMA", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER TEXT_P SEARCH PARSER any_name SET SCHEMA name {
        auto tmp1 = $5;
        auto tmp2 = $8;
        res = new IR(kAlterObjectSchemaStmt, OP3("ALTER TEXT SEARCH PARSER", "SET SCHEMA", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER TEXT_P SEARCH DICTIONARY any_name SET SCHEMA name {
        auto tmp1 = $5;
        auto tmp2 = $8;
        res = new IR(kAlterObjectSchemaStmt, OP3("ALTER TEXT SEARCH DICTIONARY", "SET SCHEMA", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER TEXT_P SEARCH TEMPLATE any_name SET SCHEMA name {
        auto tmp1 = $5;
        auto tmp2 = $8;
        res = new IR(kAlterObjectSchemaStmt, OP3("ALTER TEXT SEARCH TEMPLATE", "SET SCHEMA", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER TEXT_P SEARCH CONFIGURATION any_name SET SCHEMA name {
        auto tmp1 = $5;
        auto tmp2 = $8;
        res = new IR(kAlterObjectSchemaStmt, OP3("ALTER TEXT SEARCH CONFIGURATION", "SET SCHEMA", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER SEQUENCE qualified_name SET SCHEMA name {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kAlterObjectSchemaStmt, OP3("ALTER SEQUENCE", "SET SCHEMA", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER SEQUENCE IF_P EXISTS qualified_name SET SCHEMA name {
        auto tmp1 = $5;
        auto tmp2 = $8;
        res = new IR(kAlterObjectSchemaStmt, OP3("ALTER SEQUENCE IF EXISTS", "SET SCHEMA", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER VIEW qualified_name SET SCHEMA name {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kAlterObjectSchemaStmt, OP3("ALTER VIEW", "SET SCHEMA", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER VIEW IF_P EXISTS qualified_name SET SCHEMA name {
        auto tmp1 = $5;
        auto tmp2 = $8;
        res = new IR(kAlterObjectSchemaStmt, OP3("ALTER VIEW IF EXISTS", "SET SCHEMA", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER MATERIALIZED VIEW qualified_name SET SCHEMA name {
        auto tmp1 = $4;
        auto tmp2 = $7;
        res = new IR(kAlterObjectSchemaStmt, OP3("ALTER MATERIALIZED VIEW", "SET SCHEMA", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER MATERIALIZED VIEW IF_P EXISTS qualified_name SET SCHEMA name {
        auto tmp1 = $6;
        auto tmp2 = $9;
        res = new IR(kAlterObjectSchemaStmt, OP3("ALTER MATERIALIZED VIEW IF EXISTS", "SET SCHEMA", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER FOREIGN TABLE relation_expr SET SCHEMA name {
        auto tmp1 = $4;
        auto tmp2 = $7;
        res = new IR(kAlterObjectSchemaStmt, OP3("ALTER FOREIGN TABLE", "SET SCHEMA", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER FOREIGN TABLE IF_P EXISTS relation_expr SET SCHEMA name {
        auto tmp1 = $6;
        auto tmp2 = $9;
        res = new IR(kAlterObjectSchemaStmt, OP3("ALTER FOREIGN TABLE IF EXISTS", "SET SCHEMA", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER TYPE_P any_name SET SCHEMA name {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kAlterObjectSchemaStmt, OP3("ALTER TYPE", "SET SCHEMA", ""), tmp1, tmp2);
        $$ = res;
    }

;

/*****************************************************************************
*
* ALTER OPERATOR name SET define
*
*****************************************************************************/


AlterOperatorStmt:

    ALTER OPERATOR operator_with_argtypes SET '(' operator_def_list ')' {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kAlterOperatorStmt, OP3("ALTER OPERATOR", "SET (", ")"), tmp1, tmp2);
        $$ = res;
    }

;


operator_def_list:

    operator_def_elem {
        auto tmp1 = $1;
        res = new IR(kOperatorDefList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | operator_def_list ',' operator_def_elem {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kOperatorDefList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


operator_def_elem:

    ColLabel '=' NONE {
        auto tmp1 = $1;
        res = new IR(kOperatorDefElem, OP3("", "= NONE", ""), tmp1);
        $$ = res;
    }

    | ColLabel '=' operator_def_arg {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kOperatorDefElem, OP3("", "=", ""), tmp1, tmp2);
        $$ = res;
    }

;

/* must be similar enough to def_arg to avoid reduce/reduce conflicts */

operator_def_arg:

    func_type {
        auto tmp1 = $1;
        res = new IR(kOperatorDefArg, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | reserved_keyword {
        auto tmp1 = $1;
        res = new IR(kOperatorDefArg, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | qual_all_Op {
        auto tmp1 = $1;
        res = new IR(kOperatorDefArg, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | NumericOnly {
        auto tmp1 = $1;
        res = new IR(kOperatorDefArg, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | Sconst {
        auto tmp1 = $1;
        res = new IR(kOperatorDefArg, OP3("", "", ""), tmp1);
        $$ = res;
    }

;

/*****************************************************************************
*
* ALTER TYPE name SET define
*
* We repurpose ALTER OPERATOR's version of "definition" here
*
*****************************************************************************/


AlterTypeStmt:

    ALTER TYPE_P any_name SET '(' operator_def_list ')' {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kAlterTypeStmt, OP3("ALTER TYPE", "SET (", ")"), tmp1, tmp2);
        $$ = res;
    }

;

/*****************************************************************************
*
* ALTER THING name OWNER TO newname
*
*****************************************************************************/


AlterOwnerStmt:

    ALTER AGGREGATE aggregate_with_argtypes OWNER TO RoleSpec {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kAlterOwnerStmt, OP3("ALTER AGGREGATE", "OWNER TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER COLLATION any_name OWNER TO RoleSpec {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kAlterOwnerStmt, OP3("ALTER COLLATION", "OWNER TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER CONVERSION_P any_name OWNER TO RoleSpec {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kAlterOwnerStmt, OP3("ALTER CONVERSION", "OWNER TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER DATABASE name OWNER TO RoleSpec {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kAlterOwnerStmt, OP3("ALTER DATABASE", "OWNER TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER DOMAIN_P any_name OWNER TO RoleSpec {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kAlterOwnerStmt, OP3("ALTER DOMAIN", "OWNER TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER FUNCTION function_with_argtypes OWNER TO RoleSpec {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kAlterOwnerStmt, OP3("ALTER FUNCTION", "OWNER TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER opt_procedural LANGUAGE name OWNER TO RoleSpec {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("ALTER", "LANGUAGE", "OWNER TO"), tmp1, tmp2);
        auto tmp3 = $7;
        res = new IR(kAlterOwnerStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER LARGE_P OBJECT_P NumericOnly OWNER TO RoleSpec {
        auto tmp1 = $4;
        auto tmp2 = $7;
        res = new IR(kAlterOwnerStmt, OP3("ALTER LARGE OBJECT", "OWNER TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER OPERATOR operator_with_argtypes OWNER TO RoleSpec {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kAlterOwnerStmt, OP3("ALTER OPERATOR", "OWNER TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER OPERATOR CLASS any_name USING name OWNER TO RoleSpec {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kUnknown, OP3("ALTER OPERATOR CLASS", "USING", "OWNER TO"), tmp1, tmp2);
        auto tmp3 = $9;
        res = new IR(kAlterOwnerStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER OPERATOR FAMILY any_name USING name OWNER TO RoleSpec {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kUnknown, OP3("ALTER OPERATOR FAMILY", "USING", "OWNER TO"), tmp1, tmp2);
        auto tmp3 = $9;
        res = new IR(kAlterOwnerStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER PROCEDURE function_with_argtypes OWNER TO RoleSpec {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kAlterOwnerStmt, OP3("ALTER PROCEDURE", "OWNER TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER ROUTINE function_with_argtypes OWNER TO RoleSpec {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kAlterOwnerStmt, OP3("ALTER ROUTINE", "OWNER TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER SCHEMA name OWNER TO RoleSpec {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kAlterOwnerStmt, OP3("ALTER SCHEMA", "OWNER TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER TYPE_P any_name OWNER TO RoleSpec {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kAlterOwnerStmt, OP3("ALTER TYPE", "OWNER TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER TABLESPACE name OWNER TO RoleSpec {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kAlterOwnerStmt, OP3("ALTER TABLESPACE", "OWNER TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER STATISTICS any_name OWNER TO RoleSpec {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kAlterOwnerStmt, OP3("ALTER STATISTICS", "OWNER TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER TEXT_P SEARCH DICTIONARY any_name OWNER TO RoleSpec {
        auto tmp1 = $5;
        auto tmp2 = $8;
        res = new IR(kAlterOwnerStmt, OP3("ALTER TEXT SEARCH DICTIONARY", "OWNER TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER TEXT_P SEARCH CONFIGURATION any_name OWNER TO RoleSpec {
        auto tmp1 = $5;
        auto tmp2 = $8;
        res = new IR(kAlterOwnerStmt, OP3("ALTER TEXT SEARCH CONFIGURATION", "OWNER TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER FOREIGN DATA_P WRAPPER name OWNER TO RoleSpec {
        auto tmp1 = $5;
        auto tmp2 = $8;
        res = new IR(kAlterOwnerStmt, OP3("ALTER FOREIGN DATA WRAPPER", "OWNER TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER SERVER name OWNER TO RoleSpec {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kAlterOwnerStmt, OP3("ALTER SERVER", "OWNER TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER EVENT TRIGGER name OWNER TO RoleSpec {
        auto tmp1 = $4;
        auto tmp2 = $7;
        res = new IR(kAlterOwnerStmt, OP3("ALTER EVENT TRIGGER", "OWNER TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER PUBLICATION name OWNER TO RoleSpec {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kAlterOwnerStmt, OP3("ALTER PUBLICATION", "OWNER TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER SUBSCRIPTION name OWNER TO RoleSpec {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kAlterOwnerStmt, OP3("ALTER SUBSCRIPTION", "OWNER TO", ""), tmp1, tmp2);
        $$ = res;
    }

;


/*****************************************************************************
*
* CREATE PUBLICATION name [ FOR TABLE ] [ WITH options ]
*
*****************************************************************************/


CreatePublicationStmt:

    CREATE PUBLICATION name opt_publication_for_tables opt_definition {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("CREATE PUBLICATION", "", ""), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kCreatePublicationStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


opt_publication_for_tables:

    publication_for_tables {
        auto tmp1 = $1;
        res = new IR(kOptPublicationForTables, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | /* EMPTY */ {
        res = new IR(kOptPublicationForTables, string(""));
        $$ = res;
    }

;


publication_for_tables:

    FOR TABLE relation_expr_list {
        auto tmp1 = $3;
        res = new IR(kPublicationForTables, OP3("FOR TABLE", "", ""), tmp1);
        $$ = res;
    }

    | FOR ALL TABLES {
        res = new IR(kPublicationForTables, string("FOR ALL TABLES"));
        $$ = res;
    }

;


/*****************************************************************************
*
* ALTER PUBLICATION name SET ( options )
*
* ALTER PUBLICATION name ADD TABLE table [, table2]
*
* ALTER PUBLICATION name DROP TABLE table [, table2]
*
* ALTER PUBLICATION name SET TABLE table [, table2]
*
*****************************************************************************/


AlterPublicationStmt:

    ALTER PUBLICATION name SET definition {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kAlterPublicationStmt, OP3("ALTER PUBLICATION", "SET", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER PUBLICATION name ADD_P TABLE relation_expr_list {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kAlterPublicationStmt, OP3("ALTER PUBLICATION", "ADD TABLE", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER PUBLICATION name SET TABLE relation_expr_list {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kAlterPublicationStmt, OP3("ALTER PUBLICATION", "SET TABLE", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER PUBLICATION name DROP TABLE relation_expr_list {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kAlterPublicationStmt, OP3("ALTER PUBLICATION", "DROP TABLE", ""), tmp1, tmp2);
        $$ = res;
    }

;

/*****************************************************************************
*
* CREATE SUBSCRIPTION name ...
*
*****************************************************************************/


CreateSubscriptionStmt:

    CREATE SUBSCRIPTION name CONNECTION Sconst PUBLICATION name_list opt_definition {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kUnknown, OP3("CREATE SUBSCRIPTION", "CONNECTION", "PUBLICATION"), tmp1, tmp2);
        auto tmp3 = $7;
        res = new IR(kCreateSubscriptionStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;

/*****************************************************************************
*
* ALTER SUBSCRIPTION name ...
*
*****************************************************************************/


AlterSubscriptionStmt:

    ALTER SUBSCRIPTION name SET definition {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kAlterSubscriptionStmt, OP3("ALTER SUBSCRIPTION", "SET", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER SUBSCRIPTION name CONNECTION Sconst {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kAlterSubscriptionStmt, OP3("ALTER SUBSCRIPTION", "CONNECTION", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER SUBSCRIPTION name REFRESH PUBLICATION opt_definition {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kAlterSubscriptionStmt, OP3("ALTER SUBSCRIPTION", "REFRESH PUBLICATION", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER SUBSCRIPTION name ADD_P PUBLICATION name_list opt_definition {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kUnknown, OP3("ALTER SUBSCRIPTION", "ADD PUBLICATION", ""), tmp1, tmp2);
        auto tmp3 = $7;
        res = new IR(kAlterSubscriptionStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER SUBSCRIPTION name DROP PUBLICATION name_list opt_definition {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kUnknown, OP3("ALTER SUBSCRIPTION", "DROP PUBLICATION", ""), tmp1, tmp2);
        auto tmp3 = $7;
        res = new IR(kAlterSubscriptionStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER SUBSCRIPTION name SET PUBLICATION name_list opt_definition {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kUnknown, OP3("ALTER SUBSCRIPTION", "SET PUBLICATION", ""), tmp1, tmp2);
        auto tmp3 = $7;
        res = new IR(kAlterSubscriptionStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER SUBSCRIPTION name ENABLE_P {
        auto tmp1 = $3;
        res = new IR(kAlterSubscriptionStmt, OP3("ALTER SUBSCRIPTION", "ENABLE", ""), tmp1);
        $$ = res;
    }

    | ALTER SUBSCRIPTION name DISABLE_P {
        auto tmp1 = $3;
        res = new IR(kAlterSubscriptionStmt, OP3("ALTER SUBSCRIPTION", "DISABLE", ""), tmp1);
        $$ = res;
    }

;

/*****************************************************************************
*
* DROP SUBSCRIPTION [ IF EXISTS ] name
*
*****************************************************************************/


DropSubscriptionStmt:

    DROP SUBSCRIPTION name opt_drop_behavior {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kDropSubscriptionStmt, OP3("DROP SUBSCRIPTION", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | DROP SUBSCRIPTION IF_P EXISTS name opt_drop_behavior {
        auto tmp1 = $5;
        auto tmp2 = $6;
        res = new IR(kDropSubscriptionStmt, OP3("DROP SUBSCRIPTION IF EXISTS", "", ""), tmp1, tmp2);
        $$ = res;
    }

;

/*****************************************************************************
*
*		QUERY:	Define Rewrite Rule
*
*****************************************************************************/


RuleStmt:

    CREATE opt_or_replace RULE name AS ON event TO qualified_name where_clause DO opt_instead RuleActionList {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("CREATE", "RULE", "AS ON"), tmp1, tmp2);
        auto tmp3 = $7;
        res = new IR(kUnknown, OP3("", "TO", ""), res, tmp3);
        auto tmp4 = $10;
        res = new IR(kUnknown, OP3("", "DO", ""), res, tmp4);
        auto tmp5 = $13;
        res = new IR(kRuleStmt, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

;


RuleActionList:

    NOTHING {
        res = new IR(kRuleActionList, string("NOTHING"));
        $$ = res;
    }

    | RuleActionStmt {
        auto tmp1 = $1;
        res = new IR(kRuleActionList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '(' RuleActionMulti ')' {
        auto tmp1 = $2;
        res = new IR(kRuleActionList, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

;

/* the thrashing around here is to discard "empty" statements... */

RuleActionMulti:

    RuleActionMulti ';' RuleActionStmtOrEmpty {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kRuleActionMulti, OP3("", ";", ""), tmp1, tmp2);
        $$ = res;
    }

    | RuleActionStmtOrEmpty {
        auto tmp1 = $1;
        res = new IR(kRuleActionMulti, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


RuleActionStmt:

    SelectStmt {
        auto tmp1 = $1;
        res = new IR(kRuleActionStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | InsertStmt {
        auto tmp1 = $1;
        res = new IR(kRuleActionStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | UpdateStmt {
        auto tmp1 = $1;
        res = new IR(kRuleActionStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DeleteStmt {
        auto tmp1 = $1;
        res = new IR(kRuleActionStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | NotifyStmt {
        auto tmp1 = $1;
        res = new IR(kRuleActionStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


RuleActionStmtOrEmpty:

    RuleActionStmt {
        auto tmp1 = $1;
        res = new IR(kRuleActionStmtOrEmpty, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kRuleActionStmtOrEmpty, string(""));
        $$ = res;
    }

;


event:

    SELECT {
        res = new IR(kEvent, string("SELECT"));
        $$ = res;
    }

    | UPDATE {
        res = new IR(kEvent, string("UPDATE"));
        $$ = res;
    }

    | DELETE_P {
        res = new IR(kEvent, string("DELETE"));
        $$ = res;
    }

    | INSERT {
        res = new IR(kEvent, string("INSERT"));
        $$ = res;
    }

;


opt_instead:

    INSTEAD {
        res = new IR(kOptInstead, string("INSTEAD"));
        $$ = res;
    }

    | ALSO {
        res = new IR(kOptInstead, string("ALSO"));
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptInstead, string(""));
        $$ = res;
    }

;


/*****************************************************************************
*
*		QUERY:
*				NOTIFY <identifier> can appear both in rule bodies and
*				as a query-level command
*
*****************************************************************************/


NotifyStmt:

    NOTIFY ColId notify_payload {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kNotifyStmt, OP3("NOTIFY", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


notify_payload:

    Sconst {
        auto tmp1 = $1;
        res = new IR(kNotifyPayload, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kNotifyPayload, string(""));
        $$ = res;
    }

;


ListenStmt:

    LISTEN ColId {
        auto tmp1 = $2;
        res = new IR(kListenStmt, OP3("LISTEN", "", ""), tmp1);
        $$ = res;
    }

;


UnlistenStmt:

    UNLISTEN ColId {
        auto tmp1 = $2;
        res = new IR(kUnlistenStmt, OP3("UNLISTEN", "", ""), tmp1);
        $$ = res;
    }

    | UNLISTEN '*' {
        res = new IR(kUnlistenStmt, string("UNLISTEN *"));
        $$ = res;
    }

;


/*****************************************************************************
*
*		Transactions:
*
*		BEGIN / COMMIT / ROLLBACK
*		(also older versions END / ABORT)
*
*****************************************************************************/


TransactionStmt:

    ABORT_P opt_transaction opt_transaction_chain {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kTransactionStmt, OP3("ABORT", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | START TRANSACTION transaction_mode_list_or_empty {
        auto tmp1 = $3;
        res = new IR(kTransactionStmt, OP3("START TRANSACTION", "", ""), tmp1);
        $$ = res;
    }

    | COMMIT opt_transaction opt_transaction_chain {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kTransactionStmt, OP3("COMMIT", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ROLLBACK opt_transaction opt_transaction_chain {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kTransactionStmt, OP3("ROLLBACK", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | SAVEPOINT ColId {
        auto tmp1 = $2;
        res = new IR(kTransactionStmt, OP3("SAVEPOINT", "", ""), tmp1);
        $$ = res;
    }

    | RELEASE SAVEPOINT ColId {
        auto tmp1 = $3;
        res = new IR(kTransactionStmt, OP3("RELEASE SAVEPOINT", "", ""), tmp1);
        $$ = res;
    }

    | RELEASE ColId {
        auto tmp1 = $2;
        res = new IR(kTransactionStmt, OP3("RELEASE", "", ""), tmp1);
        $$ = res;
    }

    | ROLLBACK opt_transaction TO SAVEPOINT ColId {
        auto tmp1 = $2;
        auto tmp2 = $5;
        res = new IR(kTransactionStmt, OP3("ROLLBACK", "TO SAVEPOINT", ""), tmp1, tmp2);
        $$ = res;
    }

    | ROLLBACK opt_transaction TO ColId {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kTransactionStmt, OP3("ROLLBACK", "TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | PREPARE TRANSACTION Sconst {
        auto tmp1 = $3;
        res = new IR(kTransactionStmt, OP3("PREPARE TRANSACTION", "", ""), tmp1);
        $$ = res;
    }

    | COMMIT PREPARED Sconst {
        auto tmp1 = $3;
        res = new IR(kTransactionStmt, OP3("COMMIT PREPARED", "", ""), tmp1);
        $$ = res;
    }

    | ROLLBACK PREPARED Sconst {
        auto tmp1 = $3;
        res = new IR(kTransactionStmt, OP3("ROLLBACK PREPARED", "", ""), tmp1);
        $$ = res;
    }

;


TransactionStmtLegacy:

    BEGIN_P opt_transaction transaction_mode_list_or_empty {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kTransactionStmtLegacy, OP3("BEGIN", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | END_P opt_transaction opt_transaction_chain {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kTransactionStmtLegacy, OP3("END", "", ""), tmp1, tmp2);
        $$ = res;
    }

;

opt_transaction:	
    WORK {
        $$ = new IR(kOptTransaction, OP3("WORK", "", ""));
    }
    | TRANSACTION {
        $$ = new IR(kOptTransaction, OP3("TRANSACTION", "", ""));
    }
    | /*EMPTY*/ {
        $$ = new IR(kOptTransaction, OP0());
    }
;


transaction_mode_item:

    ISOLATION LEVEL iso_level {
        auto tmp1 = $3;
        res = new IR(kTransactionModeItem, OP3("ISOLATION LEVEL", "", ""), tmp1);
        $$ = res;
    }

    | READ ONLY {
        res = new IR(kTransactionModeItem, string("READ ONLY"));
        $$ = res;
    }

    | READ WRITE {
        res = new IR(kTransactionModeItem, string("READ WRITE"));
        $$ = res;
    }

    | DEFERRABLE {
        res = new IR(kTransactionModeItem, string("DEFERRABLE"));
        $$ = res;
    }

    | NOT DEFERRABLE {
        res = new IR(kTransactionModeItem, string("NOT DEFERRABLE"));
        $$ = res;
    }

;

/* Syntax with commas is SQL-spec, without commas is Postgres historical */

transaction_mode_list:

    transaction_mode_item {
        auto tmp1 = $1;
        res = new IR(kTransactionModeList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | transaction_mode_list ',' transaction_mode_item {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTransactionModeList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | transaction_mode_list transaction_mode_item {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kTransactionModeList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


transaction_mode_list_or_empty:

    transaction_mode_list {
        auto tmp1 = $1;
        res = new IR(kTransactionModeListOrEmpty, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | /* EMPTY */ {
        res = new IR(kTransactionModeListOrEmpty, string(""));
        $$ = res;
    }

;


opt_transaction_chain:

    AND CHAIN {
        res = new IR(kOptTransactionChain, string("AND CHAIN"));
        $$ = res;
    }

    | AND NO CHAIN {
        res = new IR(kOptTransactionChain, string("AND NO CHAIN"));
        $$ = res;
    }

    | /* EMPTY */ {
        res = new IR(kOptTransactionChain, string(""));
        $$ = res;
    }

;


/*****************************************************************************
*
*	QUERY:
*		CREATE [ OR REPLACE ] [ TEMP ] VIEW <viewname> '('target-list ')'
*			AS <query> [ WITH [ CASCADED | LOCAL ] CHECK OPTION ]
*
*****************************************************************************/


ViewStmt:

    CREATE OptTemp VIEW qualified_name opt_column_list opt_reloptions AS SelectStmt opt_check_option {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("CREATE", "VIEW", ""), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kUnknown, OP3("", "", "AS"), res, tmp3);
        auto tmp4 = $8;
        res = new IR(kViewStmt, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | CREATE OR REPLACE OptTemp VIEW qualified_name opt_column_list opt_reloptions AS SelectStmt opt_check_option {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kUnknown, OP3("CREATE OR REPLACE", "VIEW", ""), tmp1, tmp2);
        auto tmp3 = $7;
        res = new IR(kUnknown, OP3("", "", "AS"), res, tmp3);
        auto tmp4 = $10;
        res = new IR(kViewStmt, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | CREATE OptTemp RECURSIVE VIEW qualified_name '(' columnList ')' opt_reloptions AS SelectStmt opt_check_option {
        auto tmp1 = $2;
        auto tmp2 = $5;
        res = new IR(kUnknown, OP3("CREATE", "RECURSIVE VIEW", "("), tmp1, tmp2);
        auto tmp3 = $7;
        res = new IR(kUnknown, OP3("", ")", "AS"), res, tmp3);
        auto tmp4 = $11;
        res = new IR(kViewStmt, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | CREATE OR REPLACE OptTemp RECURSIVE VIEW qualified_name '(' columnList ')' opt_reloptions AS SelectStmt opt_check_option {
        auto tmp1 = $4;
        auto tmp2 = $7;
        res = new IR(kUnknown, OP3("CREATE OR REPLACE", "RECURSIVE VIEW", "("), tmp1, tmp2);
        auto tmp3 = $9;
        res = new IR(kUnknown, OP3("", ")", "AS"), res, tmp3);
        auto tmp4 = $13;
        res = new IR(kViewStmt, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


opt_check_option:

    WITH CHECK OPTION {
        res = new IR(kOptCheckOption, string("WITH CHECK OPTION"));
        $$ = res;
    }

    | WITH CASCADED CHECK OPTION {
        res = new IR(kOptCheckOption, string("WITH CASCADED CHECK OPTION"));
        $$ = res;
    }

    | WITH LOCAL CHECK OPTION {
        res = new IR(kOptCheckOption, string("WITH LOCAL CHECK OPTION"));
        $$ = res;
    }

    | /* EMPTY */ {
        res = new IR(kOptCheckOption, string(""));
        $$ = res;
    }

;

/*****************************************************************************
*
*		QUERY:
*				LOAD "filename"
*
*****************************************************************************/


LoadStmt:

    LOAD file_name {
        auto tmp1 = $2;
        res = new IR(kLoadStmt, OP3("LOAD", "", ""), tmp1);
        $$ = res;
    }

;


/*****************************************************************************
*
*		CREATE DATABASE
*
*****************************************************************************/


CreatedbStmt:

    CREATE DATABASE name opt_with createdb_opt_list {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("CREATE DATABASE", "", ""), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kCreatedbStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


createdb_opt_list:

    createdb_opt_items {
        auto tmp1 = $1;
        res = new IR(kCreatedbOptList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | /* EMPTY */ {
        res = new IR(kCreatedbOptList, string(""));
        $$ = res;
    }

;


createdb_opt_items:

    createdb_opt_item {
        auto tmp1 = $1;
        res = new IR(kCreatedbOptItems, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | createdb_opt_items createdb_opt_item {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCreatedbOptItems, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


createdb_opt_item:

    createdb_opt_name opt_equal SignedIconst {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUnknown, OP3("", "", ""), tmp1, tmp2);
        auto tmp3 = $3;
        res = new IR(kCreatedbOptItem, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | createdb_opt_name opt_equal opt_boolean_or_string {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUnknown, OP3("", "", ""), tmp1, tmp2);
        auto tmp3 = $3;
        res = new IR(kCreatedbOptItem, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | createdb_opt_name opt_equal DEFAULT {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCreatedbOptItem, OP3("", "", "DEFAULT"), tmp1, tmp2);
        $$ = res;
    }

;

/*
* Ideally we'd use ColId here, but that causes shift/reduce conflicts against
* the ALTER DATABASE SET/RESET syntaxes.  Instead call out specific keywords
* we need, and allow IDENT so that database option names don't have to be
* parser keywords unless they are already keywords for other reasons.
*
* XXX this coding technique is fragile since if someone makes a formerly
* non-keyword option name into a keyword and forgets to add it here, the
* option will silently break.  Best defense is to provide a regression test
* exercising every such option, at least at the syntax level.
*/

createdb_opt_name:

    IDENT {
        res = new IR(kCreatedbOptName, string("IDENT"));
        $$ = res;
    }

    | CONNECTION LIMIT {
        res = new IR(kCreatedbOptName, string("CONNECTION LIMIT"));
        $$ = res;
    }

    | ENCODING {
        res = new IR(kCreatedbOptName, string("ENCODING"));
        $$ = res;
    }

    | LOCATION {
        res = new IR(kCreatedbOptName, string("LOCATION"));
        $$ = res;
    }

    | OWNER {
        res = new IR(kCreatedbOptName, string("OWNER"));
        $$ = res;
    }

    | TABLESPACE {
        res = new IR(kCreatedbOptName, string("TABLESPACE"));
        $$ = res;
    }

    | TEMPLATE {
        res = new IR(kCreatedbOptName, string("TEMPLATE"));
        $$ = res;
    }

;

/*
*	Though the equals sign doesn't match other WITH options, pg_dump uses
*	equals for backward compatibility, and it doesn't seem worth removing it.
*/
opt_equal:	
    '=' {
        $$ = new IR(kOptEqual, OP3("=", "", ""));
    }
    | /*EMPTY*/ {
        $$ = new IR(kOptEqual, OP0());
    }
;


/*****************************************************************************
*
*		ALTER DATABASE
*
*****************************************************************************/


AlterDatabaseStmt:

    ALTER DATABASE name WITH createdb_opt_list {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kAlterDatabaseStmt, OP3("ALTER DATABASE", "WITH", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER DATABASE name createdb_opt_list {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlterDatabaseStmt, OP3("ALTER DATABASE", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER DATABASE name SET TABLESPACE name {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kAlterDatabaseStmt, OP3("ALTER DATABASE", "SET TABLESPACE", ""), tmp1, tmp2);
        $$ = res;
    }

;


AlterDatabaseSetStmt:

    ALTER DATABASE name SetResetClause {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlterDatabaseSetStmt, OP3("ALTER DATABASE", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


/*****************************************************************************
*
*		DROP DATABASE [ IF EXISTS ] dbname [ [ WITH ] ( options ) ]
*
* This is implicitly CASCADE, no need for drop behavior
*****************************************************************************/


DropdbStmt:

    DROP DATABASE name {
        auto tmp1 = $3;
        res = new IR(kDropdbStmt, OP3("DROP DATABASE", "", ""), tmp1);
        $$ = res;
    }

    | DROP DATABASE IF_P EXISTS name {
        auto tmp1 = $5;
        res = new IR(kDropdbStmt, OP3("DROP DATABASE IF EXISTS", "", ""), tmp1);
        $$ = res;
    }

    | DROP DATABASE name opt_with '(' drop_option_list ')' {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("DROP DATABASE", "", "("), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kDropdbStmt, OP3("", ")", ""), res, tmp3);
        $$ = res;
    }

    | DROP DATABASE IF_P EXISTS name opt_with '(' drop_option_list ')' {
        auto tmp1 = $5;
        auto tmp2 = $6;
        res = new IR(kUnknown, OP3("DROP DATABASE IF EXISTS", "", "("), tmp1, tmp2);
        auto tmp3 = $8;
        res = new IR(kDropdbStmt, OP3("", ")", ""), res, tmp3);
        $$ = res;
    }

;


drop_option_list:

    drop_option {
        auto tmp1 = $1;
        res = new IR(kDropOptionList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | drop_option_list ',' drop_option {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kDropOptionList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;

/*
* Currently only the FORCE option is supported, but the syntax is designed
* to be extensible so that we can add more options in the future if required.
*/

drop_option:

    FORCE {
        res = new IR(kDropOption, string("FORCE"));
        $$ = res;
    }

;

/*****************************************************************************
*
*		ALTER COLLATION
*
*****************************************************************************/


AlterCollationStmt:

    ALTER COLLATION any_name REFRESH VERSION_P {
        auto tmp1 = $3;
        res = new IR(kAlterCollationStmt, OP3("ALTER COLLATION", "REFRESH VERSION", ""), tmp1);
        $$ = res;
    }

;


/*****************************************************************************
*
*		ALTER SYSTEM
*
* This is used to change configuration parameters persistently.
*****************************************************************************/


AlterSystemStmt:

    ALTER SYSTEM_P SET generic_set {
        auto tmp1 = $4;
        res = new IR(kAlterSystemStmt, OP3("ALTER SYSTEM SET", "", ""), tmp1);
        $$ = res;
    }

    | ALTER SYSTEM_P RESET generic_reset {
        auto tmp1 = $4;
        res = new IR(kAlterSystemStmt, OP3("ALTER SYSTEM RESET", "", ""), tmp1);
        $$ = res;
    }

;


/*****************************************************************************
*
* Manipulate a domain
*
*****************************************************************************/


CreateDomainStmt:

    CREATE DOMAIN_P any_name opt_as Typename ColQualList {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("CREATE DOMAIN", "", ""), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kCreateDomainStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


AlterDomainStmt:

    ALTER DOMAIN_P any_name alter_column_default {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlterDomainStmt, OP3("ALTER DOMAIN", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER DOMAIN_P any_name DROP NOT NULL_P {
        auto tmp1 = $3;
        res = new IR(kAlterDomainStmt, OP3("ALTER DOMAIN", "DROP NOT NULL", ""), tmp1);
        $$ = res;
    }

    | ALTER DOMAIN_P any_name SET NOT NULL_P {
        auto tmp1 = $3;
        res = new IR(kAlterDomainStmt, OP3("ALTER DOMAIN", "SET NOT NULL", ""), tmp1);
        $$ = res;
    }

    | ALTER DOMAIN_P any_name ADD_P TableConstraint {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kAlterDomainStmt, OP3("ALTER DOMAIN", "ADD", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER DOMAIN_P any_name DROP CONSTRAINT name opt_drop_behavior {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kUnknown, OP3("ALTER DOMAIN", "DROP CONSTRAINT", ""), tmp1, tmp2);
        auto tmp3 = $7;
        res = new IR(kAlterDomainStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER DOMAIN_P any_name DROP CONSTRAINT IF_P EXISTS name opt_drop_behavior {
        auto tmp1 = $3;
        auto tmp2 = $8;
        res = new IR(kUnknown, OP3("ALTER DOMAIN", "DROP CONSTRAINT IF EXISTS", ""), tmp1, tmp2);
        auto tmp3 = $9;
        res = new IR(kAlterDomainStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER DOMAIN_P any_name VALIDATE CONSTRAINT name {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kAlterDomainStmt, OP3("ALTER DOMAIN", "VALIDATE CONSTRAINT", ""), tmp1, tmp2);
        $$ = res;
    }

;

opt_as:		
      AS { 
         $$ = new IR(kOptAs, OP3("AS", "", "")); 
      }
     | /* EMPTY */ {
         $$ = new IR(kOptAs, OP0());
     }
;


/*****************************************************************************
*
* Manipulate a text search dictionary or configuration
*
*****************************************************************************/


AlterTSDictionaryStmt:

    ALTER TEXT_P SEARCH DICTIONARY any_name definition {
        auto tmp1 = $5;
        auto tmp2 = $6;
        res = new IR(kAlterTSDictionaryStmt, OP3("ALTER TEXT SEARCH DICTIONARY", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


AlterTSConfigurationStmt:

    ALTER TEXT_P SEARCH CONFIGURATION any_name ADD_P MAPPING FOR name_list any_with any_name_list {
        auto tmp1 = $5;
        auto tmp2 = $9;
        res = new IR(kUnknown, OP3("ALTER TEXT SEARCH CONFIGURATION", "ADD MAPPING FOR", ""), tmp1, tmp2);
        auto tmp3 = $10;
        res = new IR(kAlterTSConfigurationStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER TEXT_P SEARCH CONFIGURATION any_name ALTER MAPPING FOR name_list any_with any_name_list {
        auto tmp1 = $5;
        auto tmp2 = $9;
        res = new IR(kUnknown, OP3("ALTER TEXT SEARCH CONFIGURATION", "ALTER MAPPING FOR", ""), tmp1, tmp2);
        auto tmp3 = $10;
        res = new IR(kAlterTSConfigurationStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER TEXT_P SEARCH CONFIGURATION any_name ALTER MAPPING REPLACE any_name any_with any_name {
        auto tmp1 = $5;
        auto tmp2 = $9;
        res = new IR(kUnknown, OP3("ALTER TEXT SEARCH CONFIGURATION", "ALTER MAPPING REPLACE", ""), tmp1, tmp2);
        auto tmp3 = $10;
        res = new IR(kAlterTSConfigurationStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER TEXT_P SEARCH CONFIGURATION any_name ALTER MAPPING FOR name_list REPLACE any_name any_with any_name {
        auto tmp1 = $5;
        auto tmp2 = $9;
        res = new IR(kUnknown, OP3("ALTER TEXT SEARCH CONFIGURATION", "ALTER MAPPING FOR", "REPLACE"), tmp1, tmp2);
        auto tmp3 = $11;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp3);
        auto tmp4 = $13;
        res = new IR(kAlterTSConfigurationStmt, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | ALTER TEXT_P SEARCH CONFIGURATION any_name DROP MAPPING FOR name_list {
        auto tmp1 = $5;
        auto tmp2 = $9;
        res = new IR(kAlterTSConfigurationStmt, OP3("ALTER TEXT SEARCH CONFIGURATION", "DROP MAPPING FOR", ""), tmp1, tmp2);
        $$ = res;
    }

    | ALTER TEXT_P SEARCH CONFIGURATION any_name DROP MAPPING IF_P EXISTS FOR name_list {
        auto tmp1 = $5;
        auto tmp2 = $11;
        res = new IR(kAlterTSConfigurationStmt, OP3("ALTER TEXT SEARCH CONFIGURATION", "DROP MAPPING IF EXISTS FOR", ""), tmp1, tmp2);
        $$ = res;
    }

;

/* Use this if TIME or ORDINALITY after WITH should be taken as an identifier */
any_with:	
    WITH {
        $$ = new IR(kAnyWith, OP3("WITH", "", ""));
    }
    | WITH_LA {
        $$ = new IR(kAnyWith, OP3("WITH", "", ""));
    }
;


/*****************************************************************************
*
* Manipulate a conversion
*
*		CREATE [DEFAULT] CONVERSION <conversion_name>
*		FOR <encoding_name> TO <encoding_name> FROM <func_name>
*
*****************************************************************************/


CreateConversionStmt:

    CREATE opt_default CONVERSION_P any_name FOR Sconst TO Sconst FROM any_name {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("CREATE", "CONVERSION", "FOR"), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kUnknown, OP3("", "TO", "FROM"), res, tmp3);
        auto tmp4 = $10;
        res = new IR(kCreateConversionStmt, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;

/*****************************************************************************
*
*		QUERY:
*				CLUSTER [VERBOSE] <qualified_name> [ USING <index_name> ]
*				CLUSTER [ (options) ] <qualified_name> [ USING <index_name> ]
*				CLUSTER [VERBOSE]
*				CLUSTER [VERBOSE] <index_name> ON <qualified_name> (for pre-8.3)
*
*****************************************************************************/


ClusterStmt:

    CLUSTER opt_verbose qualified_name cluster_index_specification {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("CLUSTER", "", ""), tmp1, tmp2);
        auto tmp3 = $4;
        res = new IR(kClusterStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | CLUSTER '(' utility_option_list ')' qualified_name cluster_index_specification {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kUnknown, OP3("CLUSTER (", ")", ""), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kClusterStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | CLUSTER opt_verbose {
        auto tmp1 = $2;
        res = new IR(kClusterStmt, OP3("CLUSTER", "", ""), tmp1);
        $$ = res;
    }

    | CLUSTER opt_verbose name ON qualified_name {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("CLUSTER", "", "ON"), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kClusterStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


cluster_index_specification:

    USING name {
        auto tmp1 = $2;
        res = new IR(kClusterIndexSpecification, OP3("USING", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kClusterIndexSpecification, string(""));
        $$ = res;
    }

;


/*****************************************************************************
*
*		QUERY:
*				VACUUM
*				ANALYZE
*
*****************************************************************************/


VacuumStmt:

    VACUUM opt_full opt_freeze opt_verbose opt_analyze opt_vacuum_relation_list {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("VACUUM", "", ""), tmp1, tmp2);
        auto tmp3 = $4;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp3);
        auto tmp4 = $6;
        res = new IR(kVacuumStmt, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | VACUUM '(' utility_option_list ')' opt_vacuum_relation_list {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kVacuumStmt, OP3("VACUUM (", ")", ""), tmp1, tmp2);
        $$ = res;
    }

;


AnalyzeStmt:

    analyze_keyword opt_verbose opt_vacuum_relation_list {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUnknown, OP3("", "", ""), tmp1, tmp2);
        auto tmp3 = $3;
        res = new IR(kAnalyzeStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | analyze_keyword '(' utility_option_list ')' opt_vacuum_relation_list {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("", "(", ")"), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kAnalyzeStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


utility_option_list:

    utility_option_elem {
        auto tmp1 = $1;
        res = new IR(kUtilityOptionList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | utility_option_list ',' utility_option_elem {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kUtilityOptionList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;

analyze_keyword:
    ANALYZE {
        $$ = new IR(kAnalyzeKeyword, OP3("ANALYZE", "", ""));
    }
    | ANALYSE /* British */ {
        $$ = new IR(kAnalyzeKeyword, OP0());
    }
;


utility_option_elem:

    utility_option_name utility_option_arg {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUtilityOptionElem, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


utility_option_name:

    NonReservedWord {
        auto tmp1 = $1;
        res = new IR(kUtilityOptionName, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | analyze_keyword {
        auto tmp1 = $1;
        res = new IR(kUtilityOptionName, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


utility_option_arg:

    opt_boolean_or_string {
        auto tmp1 = $1;
        res = new IR(kUtilityOptionArg, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | NumericOnly {
        auto tmp1 = $1;
        res = new IR(kUtilityOptionArg, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | /* EMPTY */ {
        res = new IR(kUtilityOptionArg, string(""));
        $$ = res;
    }

;


opt_analyze:

    analyze_keyword {
        auto tmp1 = $1;
        res = new IR(kOptAnalyze, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptAnalyze, string(""));
        $$ = res;
    }

;


opt_verbose:

    VERBOSE {
        res = new IR(kOptVerbose, string("VERBOSE"));
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptVerbose, string(""));
        $$ = res;
    }

;


opt_full:

    FULL {
        res = new IR(kOptFull, string("FULL"));
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptFull, string(""));
        $$ = res;
    }

;


opt_freeze:

    FREEZE {
        res = new IR(kOptFreeze, string("FREEZE"));
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptFreeze, string(""));
        $$ = res;
    }

;


opt_name_list:

    name_list ')' {
        auto tmp1 = $1;
        res = new IR(kOptNameList, OP3("", ")", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptNameList, string(""));
        $$ = res;
    }

;


vacuum_relation:

    qualified_name opt_name_list {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kVacuumRelation, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


vacuum_relation_list:

    vacuum_relation {
        auto tmp1 = $1;
        res = new IR(kVacuumRelationList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | vacuum_relation_list ',' vacuum_relation {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kVacuumRelationList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_vacuum_relation_list:

    vacuum_relation_list {
        auto tmp1 = $1;
        res = new IR(kOptVacuumRelationList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptVacuumRelationList, string(""));
        $$ = res;
    }

;


/*****************************************************************************
*
*		QUERY:
*				EXPLAIN [ANALYZE] [VERBOSE] query
*				EXPLAIN ( options ) query
*
*****************************************************************************/


ExplainStmt:

    EXPLAIN ExplainableStmt {
        auto tmp1 = $2;
        res = new IR(kExplainStmt, OP3("EXPLAIN", "", ""), tmp1);
        $$ = res;
    }

    | EXPLAIN analyze_keyword opt_verbose ExplainableStmt {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("EXPLAIN", "", ""), tmp1, tmp2);
        auto tmp3 = $4;
        res = new IR(kExplainStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | EXPLAIN VERBOSE ExplainableStmt {
        auto tmp1 = $3;
        res = new IR(kExplainStmt, OP3("EXPLAIN VERBOSE", "", ""), tmp1);
        $$ = res;
    }

    | EXPLAIN '(' utility_option_list ')' ExplainableStmt {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kExplainStmt, OP3("EXPLAIN (", ")", ""), tmp1, tmp2);
        $$ = res;
    }

;


ExplainableStmt:

    SelectStmt {
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | InsertStmt {
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | UpdateStmt {
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DeleteStmt {
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DeclareCursorStmt {
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateAsStmt {
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateMatViewStmt {
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | RefreshMatViewStmt {
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ExecuteStmt {
        auto tmp1 = $1;
        res = new IR(kExplainableStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

;

/*****************************************************************************
*
*		QUERY:
*				PREPARE <plan_name> [(args, ...)] AS <query>
*
*****************************************************************************/


PrepareStmt:

    PREPARE name prep_type_clause AS PreparableStmt {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("PREPARE", "", "AS"), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kPrepareStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


prep_type_clause:

    type_list ')' {
        auto tmp1 = $1;
        res = new IR(kPrepTypeClause, OP3("", ")", ""), tmp1);
        $$ = res;
    }

    | /* EMPTY */ {
        res = new IR(kPrepTypeClause, string(""));
        $$ = res;
    }

;


PreparableStmt:

    SelectStmt {
        auto tmp1 = $1;
        res = new IR(kPreparableStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | InsertStmt {
        auto tmp1 = $1;
        res = new IR(kPreparableStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | UpdateStmt {
        auto tmp1 = $1;
        res = new IR(kPreparableStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DeleteStmt {
        auto tmp1 = $1;
        res = new IR(kPreparableStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

;

/*****************************************************************************
*
* EXECUTE <plan_name> [(params, ...)]
* CREATE TABLE <name> AS EXECUTE <plan_name> [(params, ...)]
*
*****************************************************************************/


ExecuteStmt:

    EXECUTE name execute_param_clause {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kExecuteStmt, OP3("EXECUTE", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | CREATE OptTemp TABLE create_as_target AS EXECUTE name execute_param_clause opt_with_data {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("CREATE", "TABLE", "AS EXECUTE"), tmp1, tmp2);
        auto tmp3 = $7;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp3);
        auto tmp4 = $9;
        res = new IR(kExecuteStmt, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | CREATE OptTemp TABLE IF_P NOT EXISTS create_as_target AS EXECUTE name execute_param_clause opt_with_data {
        auto tmp1 = $2;
        auto tmp2 = $7;
        res = new IR(kUnknown, OP3("CREATE", "TABLE IF NOT EXISTS", "AS EXECUTE"), tmp1, tmp2);
        auto tmp3 = $10;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp3);
        auto tmp4 = $12;
        res = new IR(kExecuteStmt, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


execute_param_clause:

    expr_list ')' {
        auto tmp1 = $1;
        res = new IR(kExecuteParamClause, OP3("", ")", ""), tmp1);
        $$ = res;
    }

    | /* EMPTY */ {
        res = new IR(kExecuteParamClause, string(""));
        $$ = res;
    }

;

/*****************************************************************************
*
*		QUERY:
*				DEALLOCATE [PREPARE] <plan_name>
*
*****************************************************************************/


DeallocateStmt:

    DEALLOCATE name {
        auto tmp1 = $2;
        res = new IR(kDeallocateStmt, OP3("DEALLOCATE", "", ""), tmp1);
        $$ = res;
    }

    | DEALLOCATE PREPARE name {
        auto tmp1 = $3;
        res = new IR(kDeallocateStmt, OP3("DEALLOCATE PREPARE", "", ""), tmp1);
        $$ = res;
    }

    | DEALLOCATE ALL {
        res = new IR(kDeallocateStmt, string("DEALLOCATE ALL"));
        $$ = res;
    }

    | DEALLOCATE PREPARE ALL {
        res = new IR(kDeallocateStmt, string("DEALLOCATE PREPARE ALL"));
        $$ = res;
    }

;

/*****************************************************************************
*
*		QUERY:
*				INSERT STATEMENTS
*
*****************************************************************************/


InsertStmt:

    opt_with_clause INSERT INTO insert_target insert_rest opt_on_conflict returning_clause {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("", "INSERT INTO", ""), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp3);
        auto tmp4 = $7;
        res = new IR(kInsertStmt, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;

/*
* Can't easily make AS optional here, because VALUES in insert_rest would
* have a shift/reduce conflict with VALUES as an optional alias.  We could
* easily allow unreserved_keywords as optional aliases, but that'd be an odd
* divergence from other places.  So just require AS for now.
*/

insert_target:

    qualified_name {
        auto tmp1 = $1;
        res = new IR(kInsertTarget, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | qualified_name AS ColId {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kInsertTarget, OP3("", "AS", ""), tmp1, tmp2);
        $$ = res;
    }

;


insert_rest:

    SelectStmt {
        auto tmp1 = $1;
        res = new IR(kInsertRest, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | OVERRIDING override_kind VALUE_P SelectStmt {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kInsertRest, OP3("OVERRIDING", "VALUE", ""), tmp1, tmp2);
        $$ = res;
    }

    | '(' insert_column_list ')' SelectStmt {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kInsertRest, OP3("(", ")", ""), tmp1, tmp2);
        $$ = res;
    }

    | '(' insert_column_list ')' OVERRIDING override_kind VALUE_P SelectStmt {
        auto tmp1 = $2;
        auto tmp2 = $5;
        res = new IR(kUnknown, OP3("(", ") OVERRIDING", "VALUE"), tmp1, tmp2);
        auto tmp3 = $7;
        res = new IR(kInsertRest, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | DEFAULT VALUES {
        res = new IR(kInsertRest, string("DEFAULT VALUES"));
        $$ = res;
    }

;


override_kind:

    USER {
        res = new IR(kOverrideKind, string("USER"));
        $$ = res;
    }

    | SYSTEM_P {
        res = new IR(kOverrideKind, string("SYSTEM"));
        $$ = res;
    }

;


insert_column_list:

    insert_column_item {
        auto tmp1 = $1;
        res = new IR(kInsertColumnList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | insert_column_list ',' insert_column_item {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kInsertColumnList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


insert_column_item:

    ColId opt_indirection {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kInsertColumnItem, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_on_conflict:

    ON CONFLICT opt_conf_expr DO UPDATE SET set_clause_list where_clause {
        auto tmp1 = $3;
        auto tmp2 = $7;
        res = new IR(kUnknown, OP3("ON CONFLICT", "DO UPDATE SET", ""), tmp1, tmp2);
        auto tmp3 = $8;
        res = new IR(kOptOnConflict, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ON CONFLICT opt_conf_expr DO NOTHING {
        auto tmp1 = $3;
        res = new IR(kOptOnConflict, OP3("ON CONFLICT", "DO NOTHING", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptOnConflict, string(""));
        $$ = res;
    }

;


opt_conf_expr:

    index_params ')' where_clause {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kOptConfExpr, OP3("", ")", ""), tmp1, tmp2);
        $$ = res;
    }

    | ON CONSTRAINT name {
        auto tmp1 = $3;
        res = new IR(kOptConfExpr, OP3("ON CONSTRAINT", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptConfExpr, string(""));
        $$ = res;
    }

;


returning_clause:

    RETURNING target_list {
        auto tmp1 = $2;
        res = new IR(kReturningClause, OP3("RETURNING", "", ""), tmp1);
        $$ = res;
    }

    | /* EMPTY */ {
        res = new IR(kReturningClause, string(""));
        $$ = res;
    }

;


/*****************************************************************************
*
*		QUERY:
*				DELETE STATEMENTS
*
*****************************************************************************/


DeleteStmt:

    opt_with_clause DELETE_P FROM relation_expr_opt_alias using_clause where_or_current_clause returning_clause {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("", "DELETE FROM", ""), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp3);
        auto tmp4 = $7;
        res = new IR(kDeleteStmt, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


using_clause:

    USING from_list {
        auto tmp1 = $2;
        res = new IR(kUsingClause, OP3("USING", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kUsingClause, string(""));
        $$ = res;
    }

;


/*****************************************************************************
*
*		QUERY:
*				LOCK TABLE
*
*****************************************************************************/


LockStmt:

    LOCK_P opt_table relation_expr_list opt_lock opt_nowait {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("LOCK", "", ""), tmp1, tmp2);
        auto tmp3 = $4;
        res = new IR(kLockStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


opt_lock:

    IN_P lock_type MODE {
        auto tmp1 = $2;
        res = new IR(kOptLock, OP3("IN", "MODE", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptLock, string(""));
        $$ = res;
    }

;


lock_type:

    ACCESS SHARE {
        res = new IR(kLockType, string("ACCESS SHARE"));
        $$ = res;
    }

    | ROW SHARE {
        res = new IR(kLockType, string("ROW SHARE"));
        $$ = res;
    }

    | ROW EXCLUSIVE {
        res = new IR(kLockType, string("ROW EXCLUSIVE"));
        $$ = res;
    }

    | SHARE UPDATE EXCLUSIVE {
        res = new IR(kLockType, string("SHARE UPDATE EXCLUSIVE"));
        $$ = res;
    }

    | SHARE {
        res = new IR(kLockType, string("SHARE"));
        $$ = res;
    }

    | SHARE ROW EXCLUSIVE {
        res = new IR(kLockType, string("SHARE ROW EXCLUSIVE"));
        $$ = res;
    }

    | EXCLUSIVE {
        res = new IR(kLockType, string("EXCLUSIVE"));
        $$ = res;
    }

    | ACCESS EXCLUSIVE {
        res = new IR(kLockType, string("ACCESS EXCLUSIVE"));
        $$ = res;
    }

;


opt_nowait:

    NOWAIT {
        res = new IR(kOptNowait, string("NOWAIT"));
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptNowait, string(""));
        $$ = res;
    }

;


opt_nowait_or_skip:

    NOWAIT {
        res = new IR(kOptNowaitOrSkip, string("NOWAIT"));
        $$ = res;
    }

    | SKIP LOCKED {
        res = new IR(kOptNowaitOrSkip, string("SKIP LOCKED"));
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptNowaitOrSkip, string(""));
        $$ = res;
    }

;


/*****************************************************************************
*
*		QUERY:
*				UpdateStmt (UPDATE)
*
*****************************************************************************/


UpdateStmt:

    opt_with_clause UPDATE relation_expr_opt_alias SET set_clause_list from_clause where_or_current_clause returning_clause {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("", "UPDATE", "SET"), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp3);
        auto tmp4 = $7;
        res = new IR(kUpdateStmt, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


set_clause_list:

    set_clause {
        auto tmp1 = $1;
        res = new IR(kSetClauseList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | set_clause_list ',' set_clause {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSetClauseList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


set_clause:

    set_target '=' a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSetClause, OP3("", "=", ""), tmp1, tmp2);
        $$ = res;
    }

    | '(' set_target_list ')' '=' a_expr {
        auto tmp1 = $2;
        auto tmp2 = $5;
        res = new IR(kSetClause, OP3("(", ") =", ""), tmp1, tmp2);
        $$ = res;
    }

;


set_target:

    ColId opt_indirection {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSetTarget, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


set_target_list:

    set_target {
        auto tmp1 = $1;
        res = new IR(kSetTargetList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | set_target_list ',' set_target {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSetTargetList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


/*****************************************************************************
*
*		QUERY:
*				CURSOR STATEMENTS
*
*****************************************************************************/

DeclareCursorStmt:

    DECLARE cursor_name cursor_options CURSOR opt_hold FOR SelectStmt {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("DECLARE", "", "CURSOR"), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kDeclareCursorStmt, OP3("", "FOR", ""), res, tmp3);
        $$ = res;
    }

;


cursor_name:

    name {
        auto tmp1 = $1;
        res = new IR(kCursorName, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


cursor_options:

    /*EMPTY*/ {
        res = new IR(kCursorOptions, string(""));
        $$ = res;
    }

    | cursor_options NO SCROLL {
        auto tmp1 = $1;
        res = new IR(kCursorOptions, OP3("", "NO SCROLL", ""), tmp1);
        $$ = res;
    }

    | cursor_options SCROLL {
        auto tmp1 = $1;
        res = new IR(kCursorOptions, OP3("", "SCROLL", ""), tmp1);
        $$ = res;
    }

    | cursor_options BINARY {
        auto tmp1 = $1;
        res = new IR(kCursorOptions, OP3("", "BINARY", ""), tmp1);
        $$ = res;
    }

    | cursor_options ASENSITIVE {
        auto tmp1 = $1;
        res = new IR(kCursorOptions, OP3("", "ASENSITIVE", ""), tmp1);
        $$ = res;
    }

    | cursor_options INSENSITIVE {
        auto tmp1 = $1;
        res = new IR(kCursorOptions, OP3("", "INSENSITIVE", ""), tmp1);
        $$ = res;
    }

;


opt_hold:

    /* EMPTY */ {
        res = new IR(kOptHold, string(""));
        $$ = res;
    }

    | WITH HOLD {
        res = new IR(kOptHold, string("WITH HOLD"));
        $$ = res;
    }

    | WITHOUT HOLD {
        res = new IR(kOptHold, string("WITHOUT HOLD"));
        $$ = res;
    }

;

/*****************************************************************************
*
*		QUERY:
*				SELECT STATEMENTS
*
*****************************************************************************/

/* A complete SELECT statement looks like this.
*
* The rule returns either a single SelectStmt node or a tree of them,
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
* and being careful to use select_with_parens, never '(' SelectStmt ')',
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
* In non-expression contexts, we use SelectStmt which can represent a SELECT
* with or without outer parentheses.
*/


SelectStmt:

    select_no_parens %prec UMINUS {
        auto tmp1 = $1;
        res = new IR(kSelectStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | select_with_parens %prec UMINUS {
        auto tmp1 = $1;
        res = new IR(kSelectStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


select_with_parens:

    select_no_parens ')' {
        auto tmp1 = $1;
        res = new IR(kSelectWithParens, OP3("", ")", ""), tmp1);
        $$ = res;
    }

    | '(' select_with_parens ')' {
        auto tmp1 = $2;
        res = new IR(kSelectWithParens, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

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

    simple_select {
        auto tmp1 = $1;
        res = new IR(kSelectNoParens, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | select_clause sort_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSelectNoParens, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | select_clause opt_sort_clause for_locking_clause opt_select_limit {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUnknown, OP3("", "", ""), tmp1, tmp2);
        auto tmp3 = $3;
        res = new IR(kSelectNoParens, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | select_clause opt_sort_clause select_limit opt_for_locking_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUnknown, OP3("", "", ""), tmp1, tmp2);
        auto tmp3 = $3;
        res = new IR(kSelectNoParens, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | with_clause select_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSelectNoParens, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | with_clause select_clause sort_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUnknown, OP3("", "", ""), tmp1, tmp2);
        auto tmp3 = $3;
        res = new IR(kSelectNoParens, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | with_clause select_clause opt_sort_clause for_locking_clause opt_select_limit {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUnknown, OP3("", "", ""), tmp1, tmp2);
        auto tmp3 = $3;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp3);
        auto tmp4 = $5;
        res = new IR(kSelectNoParens, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | with_clause select_clause opt_sort_clause select_limit opt_for_locking_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUnknown, OP3("", "", ""), tmp1, tmp2);
        auto tmp3 = $3;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp3);
        auto tmp4 = $5;
        res = new IR(kSelectNoParens, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


select_clause:

    simple_select {
        auto tmp1 = $1;
        res = new IR(kSelectClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | select_with_parens {
        auto tmp1 = $1;
        res = new IR(kSelectClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

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
* It might appear that we could fold the first two alternatives into one
* by using opt_distinct_clause.  However, that causes a shift/reduce conflict
* against INSERT ... SELECT ... ON CONFLICT.  We avoid the ambiguity by
* requiring SELECT DISTINCT [ON] to be followed by a non-empty target_list.
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
* NOTE: only the leftmost component SelectStmt should have INTO.
* However, this is not checked by the grammar; parse analysis must check it.
*/

simple_select:

    SELECT opt_all_clause opt_target_list into_clause from_clause where_clause group_clause having_clause window_clause {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("SELECT", "", ""), tmp1, tmp2);
        auto tmp3 = $4;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp3);
        auto tmp4 = $6;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp4);
        auto tmp5 = $8;
        res = new IR(kSimpleSelect, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

    | SELECT distinct_clause target_list into_clause from_clause where_clause group_clause having_clause window_clause {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("SELECT", "", ""), tmp1, tmp2);
        auto tmp3 = $4;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp3);
        auto tmp4 = $6;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp4);
        auto tmp5 = $8;
        res = new IR(kSimpleSelect, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

    | values_clause {
        auto tmp1 = $1;
        res = new IR(kSimpleSelect, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | TABLE relation_expr {
        auto tmp1 = $2;
        res = new IR(kSimpleSelect, OP3("TABLE", "", ""), tmp1);
        $$ = res;
    }

    | select_clause UNION set_quantifier select_clause {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("", "UNION", ""), tmp1, tmp2);
        auto tmp3 = $4;
        res = new IR(kSimpleSelect, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | select_clause INTERSECT set_quantifier select_clause {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("", "INTERSECT", ""), tmp1, tmp2);
        auto tmp3 = $4;
        res = new IR(kSimpleSelect, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | select_clause EXCEPT set_quantifier select_clause {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("", "EXCEPT", ""), tmp1, tmp2);
        auto tmp3 = $4;
        res = new IR(kSimpleSelect, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;

/*
* SQL standard WITH clause looks like:
*
* WITH [ RECURSIVE ] <query name> [ (<column>,...) ]
*		AS (query) [ SEARCH or CYCLE clause ]
*
* Recognizing WITH_LA here allows a CTE to be named TIME or ORDINALITY.
*/

with_clause:

    WITH cte_list {
        auto tmp1 = $2;
        res = new IR(kWithClause, OP3("WITH", "", ""), tmp1);
        $$ = res;
    }

    | WITH_LA cte_list {
        auto tmp1 = $2;
        res = new IR(kWithClause, OP3("WITH", "", ""), tmp1);
        $$ = res;
    }

    | WITH RECURSIVE cte_list {
        auto tmp1 = $3;
        res = new IR(kWithClause, OP3("WITH RECURSIVE", "", ""), tmp1);
        $$ = res;
    }

;


cte_list:

    common_table_expr {
        auto tmp1 = $1;
        res = new IR(kCteList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | cte_list ',' common_table_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kCteList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


common_table_expr:

    name opt_name_list AS opt_materialized '(' PreparableStmt ')' opt_search_clause opt_cycle_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUnknown, OP3("", "", "AS"), tmp1, tmp2);
        auto tmp3 = $4;
        res = new IR(kUnknown, OP3("", "(", ")"), res, tmp3);
        auto tmp4 = $8;
        res = new IR(kCommonTableExpr, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


opt_materialized:

    MATERIALIZED {
        res = new IR(kOptMaterialized, string("MATERIALIZED"));
        $$ = res;
    }

    | NOT MATERIALIZED {
        res = new IR(kOptMaterialized, string("NOT MATERIALIZED"));
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptMaterialized, string(""));
        $$ = res;
    }

;


opt_search_clause:

    SEARCH DEPTH FIRST_P BY columnList SET ColId {
        auto tmp1 = $5;
        auto tmp2 = $7;
        res = new IR(kOptSearchClause, OP3("SEARCH DEPTH FIRST BY", "SET", ""), tmp1, tmp2);
        $$ = res;
    }

    | SEARCH BREADTH FIRST_P BY columnList SET ColId {
        auto tmp1 = $5;
        auto tmp2 = $7;
        res = new IR(kOptSearchClause, OP3("SEARCH BREADTH FIRST BY", "SET", ""), tmp1, tmp2);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptSearchClause, string(""));
        $$ = res;
    }

;


opt_cycle_clause:

    CYCLE columnList SET ColId TO AexprConst DEFAULT AexprConst USING ColId {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("CYCLE", "SET", "TO"), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kUnknown, OP3("", "DEFAULT", "USING"), res, tmp3);
        auto tmp4 = $10;
        res = new IR(kOptCycleClause, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | CYCLE columnList SET ColId USING ColId {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("CYCLE", "SET", "USING"), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kOptCycleClause, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptCycleClause, string(""));
        $$ = res;
    }

;


opt_with_clause:

    with_clause {
        auto tmp1 = $1;
        res = new IR(kOptWithClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptWithClause, string(""));
        $$ = res;
    }

;


into_clause:

    INTO OptTempTableName {
        auto tmp1 = $2;
        res = new IR(kIntoClause, OP3("INTO", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kIntoClause, string(""));
        $$ = res;
    }

;

/*
* Redundancy here is needed to avoid shift/reduce conflicts,
* since TEMP is not a reserved word.  See also OptTemp.
*/

OptTempTableName:

    TEMPORARY opt_table qualified_name {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kOptTempTableName, OP3("TEMPORARY", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | TEMP opt_table qualified_name {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kOptTempTableName, OP3("TEMP", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | LOCAL TEMPORARY opt_table qualified_name {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kOptTempTableName, OP3("LOCAL TEMPORARY", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | LOCAL TEMP opt_table qualified_name {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kOptTempTableName, OP3("LOCAL TEMP", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | GLOBAL TEMPORARY opt_table qualified_name {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kOptTempTableName, OP3("GLOBAL TEMPORARY", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | GLOBAL TEMP opt_table qualified_name {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kOptTempTableName, OP3("GLOBAL TEMP", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | UNLOGGED opt_table qualified_name {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kOptTempTableName, OP3("UNLOGGED", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | TABLE qualified_name {
        auto tmp1 = $2;
        res = new IR(kOptTempTableName, OP3("TABLE", "", ""), tmp1);
        $$ = res;
    }

    | qualified_name {
        auto tmp1 = $1;
        res = new IR(kOptTempTableName, OP3("", "", ""), tmp1);
        $$ = res;
    }

;

opt_table:	
    TABLE {
        $$ = new IR(kOptTable, OP3("TABLE", "", ""));
    }
    | /*EMPTY*/ {
        $$ = new IR(kOptTable, OP0());
    }
;


set_quantifier:

    ALL {
        res = new IR(kSetQuantifier, string("ALL"));
        $$ = res;
    }

    | DISTINCT {
        res = new IR(kSetQuantifier, string("DISTINCT"));
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kSetQuantifier, string(""));
        $$ = res;
    }

;

/* We use (NIL) as a placeholder to indicate that all target expressions
* should be placed in the DISTINCT list during parsetree analysis.
*/

distinct_clause:

    DISTINCT {
        res = new IR(kDistinctClause, string("DISTINCT"));
        $$ = res;
    }

    | DISTINCT ON '(' expr_list ')' {
        auto tmp1 = $4;
        res = new IR(kDistinctClause, OP3("DISTINCT ON (", ")", ""), tmp1);
        $$ = res;
    }

;

opt_all_clause:
    ALL {
        $$ = new IR(kOptAllClause, OP3("ALL", "", ""));
    }
    | /*EMPTY*/ {
        $$ = new IR(kOptAllClause, OP0());
    }
;


opt_distinct_clause:

    distinct_clause {
        auto tmp1 = $1;
        res = new IR(kOptDistinctClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | opt_all_clause {
        auto tmp1 = $1;
        res = new IR(kOptDistinctClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_sort_clause:

    sort_clause {
        auto tmp1 = $1;
        res = new IR(kOptSortClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptSortClause, string(""));
        $$ = res;
    }

;


sort_clause:

    ORDER BY sortby_list {
        auto tmp1 = $3;
        res = new IR(kSortClause, OP3("ORDER BY", "", ""), tmp1);
        $$ = res;
    }

;


sortby_list:

    sortby {
        auto tmp1 = $1;
        res = new IR(kSortbyList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sortby_list ',' sortby {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSortbyList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


sortby:

    a_expr USING qual_all_Op opt_nulls_order {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("", "USING", ""), tmp1, tmp2);
        auto tmp3 = $4;
        res = new IR(kSortby, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | a_expr opt_asc_desc opt_nulls_order {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUnknown, OP3("", "", ""), tmp1, tmp2);
        auto tmp3 = $3;
        res = new IR(kSortby, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;



select_limit:

    limit_clause offset_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSelectLimit, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | offset_clause limit_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSelectLimit, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | limit_clause {
        auto tmp1 = $1;
        res = new IR(kSelectLimit, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | offset_clause {
        auto tmp1 = $1;
        res = new IR(kSelectLimit, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_select_limit:

    select_limit {
        auto tmp1 = $1;
        res = new IR(kOptSelectLimit, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | /* EMPTY */ {
        res = new IR(kOptSelectLimit, string(""));
        $$ = res;
    }

;


limit_clause:

    LIMIT select_limit_value {
        auto tmp1 = $2;
        res = new IR(kLimitClause, OP3("LIMIT", "", ""), tmp1);
        $$ = res;
    }

    | LIMIT select_limit_value ',' select_offset_value {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kLimitClause, OP3("LIMIT", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | FETCH first_or_next select_fetch_first_value row_or_rows ONLY {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("FETCH", "", ""), tmp1, tmp2);
        auto tmp3 = $4;
        res = new IR(kLimitClause, OP3("", "ONLY", ""), res, tmp3);
        $$ = res;
    }

    | FETCH first_or_next select_fetch_first_value row_or_rows WITH TIES {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("FETCH", "", ""), tmp1, tmp2);
        auto tmp3 = $4;
        res = new IR(kLimitClause, OP3("", "WITH TIES", ""), res, tmp3);
        $$ = res;
    }

    | FETCH first_or_next row_or_rows ONLY {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kLimitClause, OP3("FETCH", "", "ONLY"), tmp1, tmp2);
        $$ = res;
    }

    | FETCH first_or_next row_or_rows WITH TIES {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kLimitClause, OP3("FETCH", "", "WITH TIES"), tmp1, tmp2);
        $$ = res;
    }

;


offset_clause:

    OFFSET select_offset_value {
        auto tmp1 = $2;
        res = new IR(kOffsetClause, OP3("OFFSET", "", ""), tmp1);
        $$ = res;
    }

    | OFFSET select_fetch_first_value row_or_rows {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kOffsetClause, OP3("OFFSET", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


select_limit_value:

    a_expr {
        auto tmp1 = $1;
        res = new IR(kSelectLimitValue, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ALL {
        res = new IR(kSelectLimitValue, string("ALL"));
        $$ = res;
    }

;


select_offset_value:

    a_expr {
        auto tmp1 = $1;
        res = new IR(kSelectOffsetValue, OP3("", "", ""), tmp1);
        $$ = res;
    }

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

    c_expr {
        auto tmp1 = $1;
        res = new IR(kSelectFetchFirstValue, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '+' I_or_F_const {
        auto tmp1 = $2;
        res = new IR(kSelectFetchFirstValue, OP3("+", "", ""), tmp1);
        $$ = res;
    }

    | '-' I_or_F_const {
        auto tmp1 = $2;
        res = new IR(kSelectFetchFirstValue, OP3("-", "", ""), tmp1);
        $$ = res;
    }

;


I_or_F_const:

    Iconst {
        auto tmp1 = $1;
        res = new IR(kIOrFConst, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | FCONST {
        res = new IR(kIOrFConst, string("FCONST"));
        $$ = res;
    }

;

/* noise words */

row_or_rows:

    ROW {
        res = new IR(kRowOrRows, string("ROW"));
        $$ = res;
    }

    | ROWS {
        res = new IR(kRowOrRows, string("ROWS"));
        $$ = res;
    }

;


first_or_next:

    FIRST_P {
        res = new IR(kFirstOrNext, string("FIRST"));
        $$ = res;
    }

    | NEXT {
        res = new IR(kFirstOrNext, string("NEXT"));
        $$ = res;
    }

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
* top node of the a_expr to see if it's an implicit RowExpr, and if so, just
* grab and use the list, discarding the node. (this is done in parse analysis,
* not here)
*
* (we abuse the row_format field of RowExpr to distinguish implicit and
* explicit row constructors; it's debatable if anyone sanely wants to use them
* in a group clause, but if they have a reason to, we make it possible.)
*
* Each item in the group_clause list is either an expression tree or a
* GroupingSet node of some type.
*/

group_clause:

    GROUP_P BY set_quantifier group_by_list {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kGroupClause, OP3("GROUP BY", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kGroupClause, string(""));
        $$ = res;
    }

;


group_by_list:

    group_by_item {
        auto tmp1 = $1;
        res = new IR(kGroupByList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | group_by_list ',' group_by_item {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kGroupByList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


group_by_item:

    a_expr {
        auto tmp1 = $1;
        res = new IR(kGroupByItem, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | empty_grouping_set {
        auto tmp1 = $1;
        res = new IR(kGroupByItem, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | cube_clause {
        auto tmp1 = $1;
        res = new IR(kGroupByItem, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | rollup_clause {
        auto tmp1 = $1;
        res = new IR(kGroupByItem, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | grouping_sets_clause {
        auto tmp1 = $1;
        res = new IR(kGroupByItem, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


empty_grouping_set: 
    '(' ')' {
        res = new IR(kEmptyGroupingSet, OP3("( )", "", ""));
        $$ = res;
    }

;

/*
* These hacks rely on setting precedence of CUBE and ROLLUP below that of '(',
* so that they shift in these rules rather than reducing the conflicting
* unreserved_keyword rule.
*/


rollup_clause:

    ROLLUP '(' expr_list ')' {
        auto tmp1 = $3;
        res = new IR(kRollupClause, OP3("ROLLUP (", ")", ""), tmp1);
        $$ = res;
    }

;


cube_clause:

    CUBE '(' expr_list ')' {
        auto tmp1 = $3;
        res = new IR(kCubeClause, OP3("CUBE (", ")", ""), tmp1);
        $$ = res;
    }

;


grouping_sets_clause:

    GROUPING SETS '(' group_by_list ')' {
        auto tmp1 = $4;
        res = new IR(kGroupingSetsClause, OP3("GROUPING SETS (", ")", ""), tmp1);
        $$ = res;
    }

;


having_clause:

    HAVING a_expr {
        auto tmp1 = $2;
        res = new IR(kHavingClause, OP3("HAVING", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kHavingClause, string(""));
        $$ = res;
    }

;


for_locking_clause:

    for_locking_items {
        auto tmp1 = $1;
        res = new IR(kForLockingClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | FOR READ ONLY {
        res = new IR(kForLockingClause, string("FOR READ ONLY"));
        $$ = res;
    }

;


opt_for_locking_clause:

    for_locking_clause {
        auto tmp1 = $1;
        res = new IR(kOptForLockingClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | /* EMPTY */ {
        res = new IR(kOptForLockingClause, string(""));
        $$ = res;
    }

;


for_locking_items:

    for_locking_item {
        auto tmp1 = $1;
        res = new IR(kForLockingItems, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | for_locking_items for_locking_item {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kForLockingItems, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


for_locking_item:

    for_locking_strength locked_rels_list opt_nowait_or_skip {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUnknown, OP3("", "", ""), tmp1, tmp2);
        auto tmp3 = $3;
        res = new IR(kForLockingItem, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


for_locking_strength:

    FOR UPDATE {
        res = new IR(kForLockingStrength, string("FOR UPDATE"));
        $$ = res;
    }

    | FOR NO KEY UPDATE {
        res = new IR(kForLockingStrength, string("FOR NO KEY UPDATE"));
        $$ = res;
    }

    | FOR SHARE {
        res = new IR(kForLockingStrength, string("FOR SHARE"));
        $$ = res;
    }

    | FOR KEY SHARE {
        res = new IR(kForLockingStrength, string("FOR KEY SHARE"));
        $$ = res;
    }

;


locked_rels_list:

    OF qualified_name_list {
        auto tmp1 = $2;
        res = new IR(kLockedRelsList, OP3("OF", "", ""), tmp1);
        $$ = res;
    }

    | /* EMPTY */ {
        res = new IR(kLockedRelsList, string(""));
        $$ = res;
    }

;


/*
* We should allow ROW '(' expr_list ')' too, but that seems to require
* making VALUES a fully reserved word, which will probably break more apps
* than allowing the noise-word is worth.
*/

values_clause:

    VALUES '(' expr_list ')' {
        auto tmp1 = $3;
        res = new IR(kValuesClause, OP3("VALUES (", ")", ""), tmp1);
        $$ = res;
    }

    | values_clause ',' '(' expr_list ')' {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kValuesClause, OP3("", ", (", ")"), tmp1, tmp2);
        $$ = res;
    }

;


/*****************************************************************************
*
*	clauses common to all Optimizable Stmts:
*		from_clause		- allow list of both JOIN expressions and table names
*		where_clause	- qualifications for joins or restrictions
*
*****************************************************************************/


from_clause:

    FROM from_list {
        auto tmp1 = $2;
        res = new IR(kFromClause, OP3("FROM", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kFromClause, string(""));
        $$ = res;
    }

;


from_list:

    table_ref {
        auto tmp1 = $1;
        res = new IR(kFromList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | from_list ',' table_ref {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kFromList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;

/*
* table_ref is where an alias clause can be attached.
*/

table_ref:

    relation_expr opt_alias_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kTableRef, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | relation_expr opt_alias_clause tablesample_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUnknown, OP3("", "", ""), tmp1, tmp2);
        auto tmp3 = $3;
        res = new IR(kTableRef, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | func_table func_alias_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kTableRef, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | LATERAL_P func_table func_alias_clause {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kTableRef, OP3("LATERAL", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | xmltable opt_alias_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kTableRef, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | LATERAL_P xmltable opt_alias_clause {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kTableRef, OP3("LATERAL", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | select_with_parens opt_alias_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kTableRef, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | LATERAL_P select_with_parens opt_alias_clause {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kTableRef, OP3("LATERAL", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | joined_table {
        auto tmp1 = $1;
        res = new IR(kTableRef, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '(' joined_table ')' alias_clause {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kTableRef, OP3("(", ")", ""), tmp1, tmp2);
        $$ = res;
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
*/


joined_table:

    joined_table ')' {
        auto tmp1 = $1;
        res = new IR(kJoinedTable, OP3("", ")", ""), tmp1);
        $$ = res;
    }

    | table_ref CROSS JOIN table_ref {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kJoinedTable, OP3("", "CROSS JOIN", ""), tmp1, tmp2);
        $$ = res;
    }

    | table_ref join_type JOIN table_ref join_qual {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUnknown, OP3("", "", "JOIN"), tmp1, tmp2);
        auto tmp3 = $4;
        res = new IR(kJoinedTable, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | table_ref JOIN table_ref join_qual {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("", "JOIN", ""), tmp1, tmp2);
        auto tmp3 = $4;
        res = new IR(kJoinedTable, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | table_ref NATURAL join_type JOIN table_ref {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("", "NATURAL", "JOIN"), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kJoinedTable, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | table_ref NATURAL JOIN table_ref {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kJoinedTable, OP3("", "NATURAL JOIN", ""), tmp1, tmp2);
        $$ = res;
    }

;


alias_clause:

    AS ColId '(' name_list ')' {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kAliasClause, OP3("AS", "(", ")"), tmp1, tmp2);
        $$ = res;
    }

    | AS ColId {
        auto tmp1 = $2;
        res = new IR(kAliasClause, OP3("AS", "", ""), tmp1);
        $$ = res;
    }

    | ColId '(' name_list ')' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAliasClause, OP3("", "(", ")"), tmp1, tmp2);
        $$ = res;
    }

    | ColId {
        auto tmp1 = $1;
        res = new IR(kAliasClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_alias_clause:

    alias_clause {
        auto tmp1 = $1;
        res = new IR(kOptAliasClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptAliasClause, string(""));
        $$ = res;
    }

;

/*
* The alias clause after JOIN ... USING only accepts the AS ColId spelling,
* per SQL standard.  (The grammar could parse the other variants, but they
* don't seem to be useful, and it might lead to parser problems in the
* future.)
*/

opt_alias_clause_for_join_using:

    AS ColId {
        auto tmp1 = $2;
        res = new IR(kOptAliasClauseForJoinUsing, OP3("AS", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptAliasClauseForJoinUsing, string(""));
        $$ = res;
    }

;

/*
* func_alias_clause can include both an Alias and a coldeflist, so we make it
* return a 2-element list that gets disassembled by calling production.
*/

func_alias_clause:

    alias_clause {
        auto tmp1 = $1;
        res = new IR(kFuncAliasClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AS '(' TableFuncElementList ')' {
        auto tmp1 = $3;
        res = new IR(kFuncAliasClause, OP3("AS (", ")", ""), tmp1);
        $$ = res;
    }

    | AS ColId '(' TableFuncElementList ')' {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kFuncAliasClause, OP3("AS", "(", ")"), tmp1, tmp2);
        $$ = res;
    }

    | ColId '(' TableFuncElementList ')' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kFuncAliasClause, OP3("", "(", ")"), tmp1, tmp2);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kFuncAliasClause, string(""));
        $$ = res;
    }

;


join_type:

    FULL opt_outer {
        auto tmp1 = $2;
        res = new IR(kJoinType, OP3("FULL", "", ""), tmp1);
        $$ = res;
    }

    | LEFT opt_outer {
        auto tmp1 = $2;
        res = new IR(kJoinType, OP3("LEFT", "", ""), tmp1);
        $$ = res;
    }

    | RIGHT opt_outer {
        auto tmp1 = $2;
        res = new IR(kJoinType, OP3("RIGHT", "", ""), tmp1);
        $$ = res;
    }

    | INNER_P {
        res = new IR(kJoinType, string("INNER"));
        $$ = res;
    }

;

/* OUTER is just noise... */
opt_outer: 
    OUTER_P  {
        $$ = new IR(kOptOuter, OP3("OUTER", "", ""));
    }
    | /*EMPTY*/ {
        $$ = new IR(kOptOuter, OP0());
    }
;

/* JOIN qualification clauses
* Possibilities are:
*	USING ( column list ) [ AS alias ]
*						  allows only unqualified column names,
*						  which must match between tables.
*	ON expr allows more general qualifications.
*
* We return USING as a two-element List (the first item being a sub-List
* of the common column names, and the second either an Alias item or NULL).
* An ON-expr will not be a List, so it can be told apart that way.
*/


join_qual:

    USING '(' name_list ')' opt_alias_clause_for_join_using {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kJoinQual, OP3("USING (", ")", ""), tmp1, tmp2);
        $$ = res;
    }

    | ON a_expr {
        auto tmp1 = $2;
        res = new IR(kJoinQual, OP3("ON", "", ""), tmp1);
        $$ = res;
    }

;



relation_expr:

    qualified_name {
        auto tmp1 = $1;
        res = new IR(kRelationExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | qualified_name '*' {
        auto tmp1 = $1;
        res = new IR(kRelationExpr, OP3("", "*", ""), tmp1);
        $$ = res;
    }

    | ONLY qualified_name {
        auto tmp1 = $2;
        res = new IR(kRelationExpr, OP3("ONLY", "", ""), tmp1);
        $$ = res;
    }

    | ONLY '(' qualified_name ')' {
        auto tmp1 = $3;
        res = new IR(kRelationExpr, OP3("ONLY (", ")", ""), tmp1);
        $$ = res;
    }

;



relation_expr_list:

    relation_expr {
        auto tmp1 = $1;
        res = new IR(kRelationExprList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | relation_expr_list ',' relation_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kRelationExprList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


/*
* Given "UPDATE foo set set ...", we have to decide without looking any
* further ahead whether the first "set" is an alias or the UPDATE's SET
* keyword.  Since "set" is allowed as a column name both interpretations
* are feasible.  We resolve the shift/reduce conflict by giving the first
* relation_expr_opt_alias production a higher precedence than the SET token
* has, causing the parser to prefer to reduce, in effect assuming that the
* SET is not an alias.
*/

relation_expr_opt_alias:

    relation_expr %prec UMINUS {
        auto tmp1 = $1;
        res = new IR(kRelationExprOptAlias, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | relation_expr ColId {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kRelationExprOptAlias, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | relation_expr AS ColId {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kRelationExprOptAlias, OP3("", "AS", ""), tmp1, tmp2);
        $$ = res;
    }

;

/*
* TABLESAMPLE decoration in a FROM item
*/

tablesample_clause:

    TABLESAMPLE func_name '(' expr_list ')' opt_repeatable_clause {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("TABLESAMPLE", "(", ")"), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kTablesampleClause, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


opt_repeatable_clause:

    REPEATABLE '(' a_expr ')' {
        auto tmp1 = $3;
        res = new IR(kOptRepeatableClause, OP3("REPEATABLE (", ")", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptRepeatableClause, string(""));
        $$ = res;
    }

;

/*
* func_table represents a function invocation in a FROM list. It can be
* a plain function call, like "foo(...)", or a ROWS FROM expression with
* one or more function calls, "ROWS FROM (foo(...), bar(...))",
* optionally with WITH ORDINALITY attached.
* In the ROWS FROM syntax, a column definition list can be given for each
* function, for example:
*     ROWS FROM (foo() AS (foo_res_a text, foo_res_b text),
*                bar() AS (bar_res_a text, bar_res_b text))
* It's also possible to attach a column definition list to the RangeFunction
* as a whole, but that's handled by the table_ref production.
*/

func_table:

    func_expr_windowless opt_ordinality {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFuncTable, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ROWS FROM '(' rowsfrom_list ')' opt_ordinality {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kFuncTable, OP3("ROWS FROM (", ")", ""), tmp1, tmp2);
        $$ = res;
    }

;


rowsfrom_item:

    func_expr_windowless opt_col_def_list {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kRowsfromItem, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


rowsfrom_list:

    rowsfrom_item {
        auto tmp1 = $1;
        res = new IR(kRowsfromList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | rowsfrom_list ',' rowsfrom_item {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kRowsfromList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_col_def_list:

    AS '(' TableFuncElementList ')' {
        auto tmp1 = $3;
        res = new IR(kOptColDefList, OP3("AS (", ")", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptColDefList, string(""));
        $$ = res;
    }

;


opt_ordinality:

    WITH_LA ORDINALITY {
        res = new IR(kOptOrdinality, string("WITH ORDINALITY"));
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptOrdinality, string(""));
        $$ = res;
    }

;



where_clause:

    WHERE a_expr {
        auto tmp1 = $2;
        res = new IR(kWhereClause, OP3("WHERE", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kWhereClause, string(""));
        $$ = res;
    }

;

/* variant for UPDATE and DELETE */

where_or_current_clause:

    WHERE a_expr {
        auto tmp1 = $2;
        res = new IR(kWhereOrCurrentClause, OP3("WHERE", "", ""), tmp1);
        $$ = res;
    }

    | WHERE CURRENT_P OF cursor_name {
        auto tmp1 = $4;
        res = new IR(kWhereOrCurrentClause, OP3("WHERE CURRENT OF", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kWhereOrCurrentClause, string(""));
        $$ = res;
    }

;



OptTableFuncElementList:

    TableFuncElementList {
        auto tmp1 = $1;
        res = new IR(kOptTableFuncElementList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptTableFuncElementList, string(""));
        $$ = res;
    }

;


TableFuncElementList:

    TableFuncElement {
        auto tmp1 = $1;
        res = new IR(kTableFuncElementList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | TableFuncElementList ',' TableFuncElement {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTableFuncElementList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


TableFuncElement:

    ColId Typename opt_collate_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUnknown, OP3("", "", ""), tmp1, tmp2);
        auto tmp3 = $3;
        res = new IR(kTableFuncElement, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;

/*
* XMLTABLE
*/

xmltable:

    XMLTABLE '(' c_expr xmlexists_argument COLUMNS xmltable_column_list ')' {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("XMLTABLE (", "", "COLUMNS"), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kXmltable, OP3("", ")", ""), res, tmp3);
        $$ = res;
    }

    | XMLTABLE '(' XMLNAMESPACES '(' xml_namespace_list ')' ',' c_expr xmlexists_argument COLUMNS xmltable_column_list ')' {
        auto tmp1 = $5;
        auto tmp2 = $8;
        res = new IR(kUnknown, OP3("XMLTABLE ( XMLNAMESPACES (", ") ,", ""), tmp1, tmp2);
        auto tmp3 = $9;
        res = new IR(kXmltable, OP3("", "COLUMNS", ")"), res, tmp3);
        $$ = res;
    }

;


xmltable_column_list:

    xmltable_column_el {
        auto tmp1 = $1;
        res = new IR(kXmltableColumnList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | xmltable_column_list ',' xmltable_column_el {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kXmltableColumnList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


xmltable_column_el:

    ColId Typename {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kXmltableColumnEl, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ColId Typename xmltable_column_option_list {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUnknown, OP3("", "", ""), tmp1, tmp2);
        auto tmp3 = $3;
        res = new IR(kXmltableColumnEl, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ColId FOR ORDINALITY {
        auto tmp1 = $1;
        res = new IR(kXmltableColumnEl, OP3("", "FOR ORDINALITY", ""), tmp1);
        $$ = res;
    }

;


xmltable_column_option_list:

    xmltable_column_option_el {
        auto tmp1 = $1;
        res = new IR(kXmltableColumnOptionList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | xmltable_column_option_list xmltable_column_option_el {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kXmltableColumnOptionList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


xmltable_column_option_el:

    IDENT b_expr {
        auto tmp1 = $2;
        res = new IR(kXmltableColumnOptionEl, OP3("IDENT", "", ""), tmp1);
        $$ = res;
    }

    | DEFAULT b_expr {
        auto tmp1 = $2;
        res = new IR(kXmltableColumnOptionEl, OP3("DEFAULT", "", ""), tmp1);
        $$ = res;
    }

    | NOT NULL_P {
        res = new IR(kXmltableColumnOptionEl, string("NOT NULL"));
        $$ = res;
    }

    | NULL_P {
        res = new IR(kXmltableColumnOptionEl, string("NULL"));
        $$ = res;
    }

;


xml_namespace_list:

    xml_namespace_el {
        auto tmp1 = $1;
        res = new IR(kXmlNamespaceList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | xml_namespace_list ',' xml_namespace_el {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kXmlNamespaceList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


xml_namespace_el:

    b_expr AS ColLabel {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kXmlNamespaceEl, OP3("", "AS", ""), tmp1, tmp2);
        $$ = res;
    }

    | DEFAULT b_expr {
        auto tmp1 = $2;
        res = new IR(kXmlNamespaceEl, OP3("DEFAULT", "", ""), tmp1);
        $$ = res;
    }

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


Typename:

    SimpleTypename opt_array_bounds {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kTypename, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | SETOF SimpleTypename opt_array_bounds {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kTypename, OP3("SETOF", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | SimpleTypename ARRAY '[' Iconst ']' {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kTypename, OP3("", "ARRAY [", "]"), tmp1, tmp2);
        $$ = res;
    }

    | SETOF SimpleTypename ARRAY '[' Iconst ']' {
        auto tmp1 = $2;
        auto tmp2 = $5;
        res = new IR(kTypename, OP3("SETOF", "ARRAY [", "]"), tmp1, tmp2);
        $$ = res;
    }

    | SimpleTypename ARRAY {
        auto tmp1 = $1;
        res = new IR(kTypename, OP3("", "ARRAY", ""), tmp1);
        $$ = res;
    }

    | SETOF SimpleTypename ARRAY {
        auto tmp1 = $2;
        res = new IR(kTypename, OP3("SETOF", "ARRAY", ""), tmp1);
        $$ = res;
    }

;


opt_array_bounds:

    opt_array_bounds '[' ']' {
        auto tmp1 = $1;
        res = new IR(kOptArrayBounds, OP3("", "[ ]", ""), tmp1);
        $$ = res;
    }

    | opt_array_bounds '[' Iconst ']' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kOptArrayBounds, OP3("", "[", "]"), tmp1, tmp2);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptArrayBounds, string(""));
        $$ = res;
    }

;


SimpleTypename:

    GenericType {
        auto tmp1 = $1;
        res = new IR(kSimpleTypename, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | Numeric {
        auto tmp1 = $1;
        res = new IR(kSimpleTypename, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | Bit {
        auto tmp1 = $1;
        res = new IR(kSimpleTypename, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | Character {
        auto tmp1 = $1;
        res = new IR(kSimpleTypename, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ConstDatetime {
        auto tmp1 = $1;
        res = new IR(kSimpleTypename, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ConstInterval opt_interval {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSimpleTypename, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ConstInterval '(' Iconst ')' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSimpleTypename, OP3("", "(", ")"), tmp1, tmp2);
        $$ = res;
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
* the generic-type-name case in AexprConst to avoid premature
* reduce/reduce conflicts against function names.
*/

ConstTypename:

    Numeric {
        auto tmp1 = $1;
        res = new IR(kConstTypename, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ConstBit {
        auto tmp1 = $1;
        res = new IR(kConstTypename, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ConstCharacter {
        auto tmp1 = $1;
        res = new IR(kConstTypename, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ConstDatetime {
        auto tmp1 = $1;
        res = new IR(kConstTypename, OP3("", "", ""), tmp1);
        $$ = res;
    }

;

/*
* GenericType covers all type names that don't have special syntax mandated
* by the standard, including qualified names.  We also allow type modifiers.
* To avoid parsing conflicts against function invocations, the modifiers
* have to be shown as expr_list here, but parse analysis will only accept
* constants for them.
*/

GenericType:

    type_function_name opt_type_modifiers {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kGenericType, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | type_function_name attrs opt_type_modifiers {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUnknown, OP3("", "", ""), tmp1, tmp2);
        auto tmp3 = $3;
        res = new IR(kGenericType, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


opt_type_modifiers:

    expr_list ')' {
        auto tmp1 = $1;
        res = new IR(kOptTypeModifiers, OP3("", ")", ""), tmp1);
        $$ = res;
    }

    | /* EMPTY */ {
        res = new IR(kOptTypeModifiers, string(""));
        $$ = res;
    }

;

/*
* SQL numeric data types
*/

Numeric:

    INT_P {
        res = new IR(kNumeric, string("INT"));
        $$ = res;
    }

    | INTEGER {
        res = new IR(kNumeric, string("INTEGER"));
        $$ = res;
    }

    | SMALLINT {
        res = new IR(kNumeric, string("SMALLINT"));
        $$ = res;
    }

    | BIGINT {
        res = new IR(kNumeric, string("BIGINT"));
        $$ = res;
    }

    | REAL {
        res = new IR(kNumeric, string("REAL"));
        $$ = res;
    }

    | FLOAT_P opt_float {
        auto tmp1 = $2;
        res = new IR(kNumeric, OP3("FLOAT", "", ""), tmp1);
        $$ = res;
    }

    | DOUBLE_P PRECISION {
        res = new IR(kNumeric, string("DOUBLE PRECISION"));
        $$ = res;
    }

    | DECIMAL_P opt_type_modifiers {
        auto tmp1 = $2;
        res = new IR(kNumeric, OP3("DECIMAL", "", ""), tmp1);
        $$ = res;
    }

    | DEC opt_type_modifiers {
        auto tmp1 = $2;
        res = new IR(kNumeric, OP3("DEC", "", ""), tmp1);
        $$ = res;
    }

    | NUMERIC opt_type_modifiers {
        auto tmp1 = $2;
        res = new IR(kNumeric, OP3("NUMERIC", "", ""), tmp1);
        $$ = res;
    }

    | BOOLEAN_P {
        res = new IR(kNumeric, string("BOOLEAN"));
        $$ = res;
    }

;


opt_float:

    Iconst ')' {
        auto tmp1 = $1;
        res = new IR(kOptFloat, OP3("", ")", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptFloat, string(""));
        $$ = res;
    }

;

/*
* SQL bit-field data types
* The following implements BIT() and BIT VARYING().
*/

Bit:

    BitWithLength {
        auto tmp1 = $1;
        res = new IR(kBit, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | BitWithoutLength {
        auto tmp1 = $1;
        res = new IR(kBit, OP3("", "", ""), tmp1);
        $$ = res;
    }

;

/* ConstBit is like Bit except "BIT" defaults to unspecified length */
/* See notes for ConstCharacter, which addresses same issue for "CHAR" */

ConstBit:

    BitWithLength {
        auto tmp1 = $1;
        res = new IR(kConstBit, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | BitWithoutLength {
        auto tmp1 = $1;
        res = new IR(kConstBit, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


BitWithLength:

    BIT opt_varying '(' expr_list ')' {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kBitWithLength, OP3("BIT", "(", ")"), tmp1, tmp2);
        $$ = res;
    }

;


BitWithoutLength:

    BIT opt_varying {
        auto tmp1 = $2;
        res = new IR(kBitWithoutLength, OP3("BIT", "", ""), tmp1);
        $$ = res;
    }

;


/*
* SQL character data types
* The following implements CHAR() and VARCHAR().
*/

Character:

    CharacterWithLength {
        auto tmp1 = $1;
        res = new IR(kCharacter, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CharacterWithoutLength {
        auto tmp1 = $1;
        res = new IR(kCharacter, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


ConstCharacter:

    CharacterWithLength {
        auto tmp1 = $1;
        res = new IR(kConstCharacter, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CharacterWithoutLength {
        auto tmp1 = $1;
        res = new IR(kConstCharacter, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


CharacterWithLength:

    character '(' Iconst ')' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kCharacterWithLength, OP3("", "(", ")"), tmp1, tmp2);
        $$ = res;
    }

;


CharacterWithoutLength:

    character {
        auto tmp1 = $1;
        res = new IR(kCharacterWithoutLength, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


character:

    CHARACTER opt_varying {
        auto tmp1 = $2;
        res = new IR(kCharacter, OP3("CHARACTER", "", ""), tmp1);
        $$ = res;
    }

    | CHAR_P opt_varying {
        auto tmp1 = $2;
        res = new IR(kCharacter, OP3("CHAR", "", ""), tmp1);
        $$ = res;
    }

    | VARCHAR {
        res = new IR(kCharacter, string("VARCHAR"));
        $$ = res;
    }

    | NATIONAL CHARACTER opt_varying {
        auto tmp1 = $3;
        res = new IR(kCharacter, OP3("NATIONAL CHARACTER", "", ""), tmp1);
        $$ = res;
    }

    | NATIONAL CHAR_P opt_varying {
        auto tmp1 = $3;
        res = new IR(kCharacter, OP3("NATIONAL CHAR", "", ""), tmp1);
        $$ = res;
    }

    | NCHAR opt_varying {
        auto tmp1 = $2;
        res = new IR(kCharacter, OP3("NCHAR", "", ""), tmp1);
        $$ = res;
    }

;


opt_varying:

    VARYING {
        res = new IR(kOptVarying, string("VARYING"));
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptVarying, string(""));
        $$ = res;
    }

;

/*
* SQL date/time types
*/

ConstDatetime:

    TIMESTAMP '(' Iconst ')' opt_timezone {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kConstDatetime, OP3("TIMESTAMP (", ")", ""), tmp1, tmp2);
        $$ = res;
    }

    | TIMESTAMP opt_timezone {
        auto tmp1 = $2;
        res = new IR(kConstDatetime, OP3("TIMESTAMP", "", ""), tmp1);
        $$ = res;
    }

    | TIME '(' Iconst ')' opt_timezone {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kConstDatetime, OP3("TIME (", ")", ""), tmp1, tmp2);
        $$ = res;
    }

    | TIME opt_timezone {
        auto tmp1 = $2;
        res = new IR(kConstDatetime, OP3("TIME", "", ""), tmp1);
        $$ = res;
    }

;


ConstInterval:

    INTERVAL {
        res = new IR(kConstInterval, string("INTERVAL"));
        $$ = res;
    }

;


opt_timezone:

    WITH_LA TIME ZONE {
        res = new IR(kOptTimezone, string("WITH TIME ZONE"));
        $$ = res;
    }

    | WITHOUT TIME ZONE {
        res = new IR(kOptTimezone, string("WITHOUT TIME ZONE"));
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptTimezone, string(""));
        $$ = res;
    }

;


opt_interval:

    YEAR_P {
        res = new IR(kOptInterval, string("YEAR"));
        $$ = res;
    }

    | MONTH_P {
        res = new IR(kOptInterval, string("MONTH"));
        $$ = res;
    }

    | DAY_P {
        res = new IR(kOptInterval, string("DAY"));
        $$ = res;
    }

    | HOUR_P {
        res = new IR(kOptInterval, string("HOUR"));
        $$ = res;
    }

    | MINUTE_P {
        res = new IR(kOptInterval, string("MINUTE"));
        $$ = res;
    }

    | interval_second {
        auto tmp1 = $1;
        res = new IR(kOptInterval, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | YEAR_P TO MONTH_P {
        res = new IR(kOptInterval, string("YEAR TO MONTH"));
        $$ = res;
    }

    | DAY_P TO HOUR_P {
        res = new IR(kOptInterval, string("DAY TO HOUR"));
        $$ = res;
    }

    | DAY_P TO MINUTE_P {
        res = new IR(kOptInterval, string("DAY TO MINUTE"));
        $$ = res;
    }

    | DAY_P TO interval_second {
        auto tmp1 = $3;
        res = new IR(kOptInterval, OP3("DAY TO", "", ""), tmp1);
        $$ = res;
    }

    | HOUR_P TO MINUTE_P {
        res = new IR(kOptInterval, string("HOUR TO MINUTE"));
        $$ = res;
    }

    | HOUR_P TO interval_second {
        auto tmp1 = $3;
        res = new IR(kOptInterval, OP3("HOUR TO", "", ""), tmp1);
        $$ = res;
    }

    | MINUTE_P TO interval_second {
        auto tmp1 = $3;
        res = new IR(kOptInterval, OP3("MINUTE TO", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptInterval, string(""));
        $$ = res;
    }

;


interval_second:

    SECOND_P {
        res = new IR(kIntervalSecond, string("SECOND"));
        $$ = res;
    }

    | SECOND_P '(' Iconst ')' {
        auto tmp1 = $3;
        res = new IR(kIntervalSecond, OP3("SECOND (", ")", ""), tmp1);
        $$ = res;
    }

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

a_expr:

    c_expr {
        auto tmp1 = $1;
        res = new IR(kAExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | a_expr TYPECAST Typename {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "TYPECAST", ""), tmp1, tmp2);
        $$ = res;
    }

    | a_expr COLLATE any_name {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "COLLATE", ""), tmp1, tmp2);
        $$ = res;
    }

    | a_expr AT TIME ZONE a_expr %prec AT  {
        auto tmp1 = $1;
        auto tmp2 = $5;
        res = new IR(kAExpr, OP3("", "AT TIME ZONE", ""), tmp1, tmp2);
        $$ = res;
    }

    | '+' a_expr %prec UMINUS {
        auto tmp1 = $2;
        res = new IR(kAExpr, OP3("+", "", ""), tmp1);
        $$ = res;
    }

    | '-' a_expr %prec UMINUS {
        auto tmp1 = $2;
        res = new IR(kAExpr, OP3("-", "", ""), tmp1);
        $$ = res;
    }

    | a_expr '+' a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "+", ""), tmp1, tmp2);
        $$ = res;
    }

    | a_expr '-' a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "-", ""), tmp1, tmp2);
        $$ = res;
    }

    | a_expr '*' a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "*", ""), tmp1, tmp2);
        $$ = res;
    }

    | a_expr '/' a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "/", ""), tmp1, tmp2);
        $$ = res;
    }

    | a_expr '%' a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "%", ""), tmp1, tmp2);
        $$ = res;
    }

    | a_expr '^' a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "^", ""), tmp1, tmp2);
        $$ = res;
    }

    | a_expr '<' a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "<", ""), tmp1, tmp2);
        $$ = res;
    }

    | a_expr '>' a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", ">", ""), tmp1, tmp2);
        $$ = res;
    }

    | a_expr '=' a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "=", ""), tmp1, tmp2);
        $$ = res;
    }

    | a_expr LESS_EQUALS a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "LESS_EQUALS", ""), tmp1, tmp2);
        $$ = res;
    }

    | a_expr GREATER_EQUALS a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "GREATER_EQUALS", ""), tmp1, tmp2);
        $$ = res;
    }

    | a_expr NOT_EQUALS a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "NOT_EQUALS", ""), tmp1, tmp2);
        $$ = res;
    }

    | a_expr qual_Op a_expr %prec Op {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUnknown, OP3("", "", ""), tmp1, tmp2);
        auto tmp3 = $3;
        res = new IR(kAExpr, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | qual_Op a_expr %prec Op {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAExpr, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | a_expr AND a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "AND", ""), tmp1, tmp2);
        $$ = res;
    }

    | a_expr OR a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "OR", ""), tmp1, tmp2);
        $$ = res;
    }

    | NOT a_expr {
        auto tmp1 = $2;
        res = new IR(kAExpr, OP3("NOT", "", ""), tmp1);
        $$ = res;
    }

    | NOT_LA a_expr %prec NOT {
        auto tmp1 = $2;
        res = new IR(kAExpr, OP3("NOT", "", ""), tmp1);
        $$ = res;
    }

    | a_expr LIKE a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "LIKE", ""), tmp1, tmp2);
        $$ = res;
    }

    | a_expr LIKE a_expr ESCAPE a_expr %prec LIKE {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("", "LIKE", "ESCAPE"), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kAExpr, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | a_expr NOT_LA LIKE a_expr %prec NOT_LA {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kAExpr, OP3("", "NOT LIKE", ""), tmp1, tmp2);
        $$ = res;
    }

    | a_expr NOT_LA LIKE a_expr ESCAPE a_expr %prec NOT_LA {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("", "NOT LIKE", "ESCAPE"), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kAExpr, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | a_expr ILIKE a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "ILIKE", ""), tmp1, tmp2);
        $$ = res;
    }

    | a_expr ILIKE a_expr ESCAPE a_expr %prec ILIKE {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("", "ILIKE", "ESCAPE"), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kAExpr, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | a_expr NOT_LA ILIKE a_expr %prec NOT_LA {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kAExpr, OP3("", "NOT ILIKE", ""), tmp1, tmp2);
        $$ = res;
    }

    | a_expr NOT_LA ILIKE a_expr ESCAPE a_expr %prec NOT_LA {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("", "NOT ILIKE", "ESCAPE"), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kAExpr, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | a_expr SIMILAR TO a_expr %prec SIMILAR {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kAExpr, OP3("", "SIMILAR TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | a_expr SIMILAR TO a_expr ESCAPE a_expr %prec SIMILAR {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("", "SIMILAR TO", "ESCAPE"), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kAExpr, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | a_expr NOT_LA SIMILAR TO a_expr %prec NOT_LA {
        auto tmp1 = $1;
        auto tmp2 = $5;
        res = new IR(kAExpr, OP3("", "NOT SIMILAR TO", ""), tmp1, tmp2);
        $$ = res;
    }

    | a_expr NOT_LA SIMILAR TO a_expr ESCAPE a_expr %prec NOT_LA {
        auto tmp1 = $1;
        auto tmp2 = $5;
        res = new IR(kUnknown, OP3("", "NOT SIMILAR TO", "ESCAPE"), tmp1, tmp2);
        auto tmp3 = $7;
        res = new IR(kAExpr, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | a_expr IS NULL_P %prec IS {
        auto tmp1 = $1;
        res = new IR(kAExpr, OP3("", "IS NULL", ""), tmp1);
        $$ = res;
    }

    | a_expr ISNULL {
        auto tmp1 = $1;
        res = new IR(kAExpr, OP3("", "ISNULL", ""), tmp1);
        $$ = res;
    }

    | a_expr IS NOT NULL_P %prec IS {
        auto tmp1 = $1;
        res = new IR(kAExpr, OP3("", "IS NOT NULL", ""), tmp1);
        $$ = res;
    }

    | a_expr NOTNULL {
        auto tmp1 = $1;
        res = new IR(kAExpr, OP3("", "NOTNULL", ""), tmp1);
        $$ = res;
    }

    | row OVERLAPS row {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "OVERLAPS", ""), tmp1, tmp2);
        $$ = res;
    }

    | a_expr IS TRUE_P %prec IS {
        auto tmp1 = $1;
        res = new IR(kAExpr, OP3("", "IS TRUE", ""), tmp1);
        $$ = res;
    }

    | a_expr IS NOT TRUE_P %prec IS {
        auto tmp1 = $1;
        res = new IR(kAExpr, OP3("", "IS NOT TRUE", ""), tmp1);
        $$ = res;
    }

    | a_expr IS FALSE_P %prec IS {
        auto tmp1 = $1;
        res = new IR(kAExpr, OP3("", "IS FALSE", ""), tmp1);
        $$ = res;
    }

    | a_expr IS NOT FALSE_P %prec IS {
        auto tmp1 = $1;
        res = new IR(kAExpr, OP3("", "IS NOT FALSE", ""), tmp1);
        $$ = res;
    }

    | a_expr IS UNKNOWN %prec IS {
        auto tmp1 = $1;
        res = new IR(kAExpr, OP3("", "IS UNKNOWN", ""), tmp1);
        $$ = res;
    }

    | a_expr IS NOT UNKNOWN %prec IS {
        auto tmp1 = $1;
        res = new IR(kAExpr, OP3("", "IS NOT UNKNOWN", ""), tmp1);
        $$ = res;
    }

    | a_expr IS DISTINCT FROM a_expr %prec IS {
        auto tmp1 = $1;
        auto tmp2 = $5;
        res = new IR(kAExpr, OP3("", "IS DISTINCT FROM", ""), tmp1, tmp2);
        $$ = res;
    }

    | a_expr IS NOT DISTINCT FROM a_expr %prec IS {
        auto tmp1 = $1;
        auto tmp2 = $6;
        res = new IR(kAExpr, OP3("", "IS NOT DISTINCT FROM", ""), tmp1, tmp2);
        $$ = res;
    }

    | a_expr BETWEEN opt_asymmetric b_expr AND a_expr %prec BETWEEN {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("", "BETWEEN", ""), tmp1, tmp2);
        auto tmp3 = $4;
        res = new IR(kAExpr, OP3("", "AND", ""), res, tmp3);
        $$ = res;
    }

    | a_expr NOT_LA BETWEEN opt_asymmetric b_expr AND a_expr %prec NOT_LA {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("", "NOT BETWEEN", ""), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kAExpr, OP3("", "AND", ""), res, tmp3);
        $$ = res;
    }

    | a_expr BETWEEN SYMMETRIC b_expr AND a_expr %prec BETWEEN {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("", "BETWEEN SYMMETRIC", "AND"), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kAExpr, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | a_expr NOT_LA BETWEEN SYMMETRIC b_expr AND a_expr %prec NOT_LA {
        auto tmp1 = $1;
        auto tmp2 = $5;
        res = new IR(kUnknown, OP3("", "NOT BETWEEN SYMMETRIC", "AND"), tmp1, tmp2);
        auto tmp3 = $7;
        res = new IR(kAExpr, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | a_expr IN_P in_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "IN", ""), tmp1, tmp2);
        $$ = res;
    }

    | a_expr NOT_LA IN_P in_expr %prec NOT_LA {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kAExpr, OP3("", "NOT IN", ""), tmp1, tmp2);
        $$ = res;
    }

    | a_expr subquery_Op sub_type select_with_parens %prec Op {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUnknown, OP3("", "", ""), tmp1, tmp2);
        auto tmp3 = $3;
        res = new IR(kAExpr, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | a_expr subquery_Op sub_type '(' a_expr ')' %prec Op {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUnknown, OP3("", "", ""), tmp1, tmp2);
        auto tmp3 = $3;
        res = new IR(kAExpr, OP3("", "(", ")"), res, tmp3);
        $$ = res;
    }

    | UNIQUE select_with_parens {
        auto tmp1 = $2;
        res = new IR(kAExpr, OP3("UNIQUE", "", ""), tmp1);
        $$ = res;
    }

    | a_expr IS DOCUMENT_P %prec IS {
        auto tmp1 = $1;
        res = new IR(kAExpr, OP3("", "IS DOCUMENT", ""), tmp1);
        $$ = res;
    }

    | a_expr IS NOT DOCUMENT_P %prec IS {
        auto tmp1 = $1;
        res = new IR(kAExpr, OP3("", "IS NOT DOCUMENT", ""), tmp1);
        $$ = res;
    }

    | a_expr IS NORMALIZED %prec IS {
        auto tmp1 = $1;
        res = new IR(kAExpr, OP3("", "IS NORMALIZED", ""), tmp1);
        $$ = res;
    }

    | a_expr IS unicode_normal_form NORMALIZED %prec IS {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAExpr, OP3("", "IS", "NORMALIZED"), tmp1, tmp2);
        $$ = res;
    }

    | a_expr IS NOT NORMALIZED %prec IS {
        auto tmp1 = $1;
        res = new IR(kAExpr, OP3("", "IS NOT NORMALIZED", ""), tmp1);
        $$ = res;
    }

    | a_expr IS NOT unicode_normal_form NORMALIZED %prec IS {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kAExpr, OP3("", "IS NOT", "NORMALIZED"), tmp1, tmp2);
        $$ = res;
    }

    | DEFAULT {
        res = new IR(kAExpr, string("DEFAULT"));
        $$ = res;
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

b_expr:

    c_expr {
        auto tmp1 = $1;
        res = new IR(kBExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | b_expr TYPECAST Typename {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBExpr, OP3("", "TYPECAST", ""), tmp1, tmp2);
        $$ = res;
    }

    | '+' b_expr %prec UMINUS {
        auto tmp1 = $2;
        res = new IR(kBExpr, OP3("+", "", ""), tmp1);
        $$ = res;
    }

    | '-' b_expr %prec UMINUS {
        auto tmp1 = $2;
        res = new IR(kBExpr, OP3("-", "", ""), tmp1);
        $$ = res;
    }

    | b_expr '+' b_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBExpr, OP3("", "+", ""), tmp1, tmp2);
        $$ = res;
    }

    | b_expr '-' b_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBExpr, OP3("", "-", ""), tmp1, tmp2);
        $$ = res;
    }

    | b_expr '*' b_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBExpr, OP3("", "*", ""), tmp1, tmp2);
        $$ = res;
    }

    | b_expr '/' b_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBExpr, OP3("", "/", ""), tmp1, tmp2);
        $$ = res;
    }

    | b_expr '%' b_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBExpr, OP3("", "%", ""), tmp1, tmp2);
        $$ = res;
    }

    | b_expr '^' b_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBExpr, OP3("", "^", ""), tmp1, tmp2);
        $$ = res;
    }

    | b_expr '<' b_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBExpr, OP3("", "<", ""), tmp1, tmp2);
        $$ = res;
    }

    | b_expr '>' b_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBExpr, OP3("", ">", ""), tmp1, tmp2);
        $$ = res;
    }

    | b_expr '=' b_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBExpr, OP3("", "=", ""), tmp1, tmp2);
        $$ = res;
    }

    | b_expr LESS_EQUALS b_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBExpr, OP3("", "LESS_EQUALS", ""), tmp1, tmp2);
        $$ = res;
    }

    | b_expr GREATER_EQUALS b_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBExpr, OP3("", "GREATER_EQUALS", ""), tmp1, tmp2);
        $$ = res;
    }

    | b_expr NOT_EQUALS b_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBExpr, OP3("", "NOT_EQUALS", ""), tmp1, tmp2);
        $$ = res;
    }

    | b_expr qual_Op b_expr %prec Op {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUnknown, OP3("", "", ""), tmp1, tmp2);
        auto tmp3 = $3;
        res = new IR(kBExpr, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | qual_Op b_expr %prec Op {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kBExpr, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | b_expr IS DISTINCT FROM b_expr %prec IS {
        auto tmp1 = $1;
        auto tmp2 = $5;
        res = new IR(kBExpr, OP3("", "IS DISTINCT FROM", ""), tmp1, tmp2);
        $$ = res;
    }

    | b_expr IS NOT DISTINCT FROM b_expr %prec IS {
        auto tmp1 = $1;
        auto tmp2 = $6;
        res = new IR(kBExpr, OP3("", "IS NOT DISTINCT FROM", ""), tmp1, tmp2);
        $$ = res;
    }

    | b_expr IS DOCUMENT_P %prec IS {
        auto tmp1 = $1;
        res = new IR(kBExpr, OP3("", "IS DOCUMENT", ""), tmp1);
        $$ = res;
    }

    | b_expr IS NOT DOCUMENT_P %prec IS {
        auto tmp1 = $1;
        res = new IR(kBExpr, OP3("", "IS NOT DOCUMENT", ""), tmp1);
        $$ = res;
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

c_expr:

    columnref {
        auto tmp1 = $1;
        res = new IR(kCExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AexprConst {
        auto tmp1 = $1;
        res = new IR(kCExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | PARAM opt_indirection {
        auto tmp1 = $2;
        res = new IR(kCExpr, OP3("PARAM", "", ""), tmp1);
        $$ = res;
    }

    | '(' a_expr ')' opt_indirection {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kCExpr, OP3("(", ")", ""), tmp1, tmp2);
        $$ = res;
    }

    | case_expr {
        auto tmp1 = $1;
        res = new IR(kCExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | func_expr {
        auto tmp1 = $1;
        res = new IR(kCExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | select_with_parens %prec UMINUS {
        auto tmp1 = $1;
        res = new IR(kCExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | select_with_parens indirection {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCExpr, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | EXISTS select_with_parens {
        auto tmp1 = $2;
        res = new IR(kCExpr, OP3("EXISTS", "", ""), tmp1);
        $$ = res;
    }

    | ARRAY select_with_parens {
        auto tmp1 = $2;
        res = new IR(kCExpr, OP3("ARRAY", "", ""), tmp1);
        $$ = res;
    }

    | ARRAY array_expr {
        auto tmp1 = $2;
        res = new IR(kCExpr, OP3("ARRAY", "", ""), tmp1);
        $$ = res;
    }

    | explicit_row {
        auto tmp1 = $1;
        res = new IR(kCExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | implicit_row {
        auto tmp1 = $1;
        res = new IR(kCExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | GROUPING '(' expr_list ')' {
        auto tmp1 = $3;
        res = new IR(kCExpr, OP3("GROUPING (", ")", ""), tmp1);
        $$ = res;
    }

;


func_application:

    func_name '(' ')' {
        auto tmp1 = $1;
        res = new IR(kFuncApplication, OP3("", "( )", ""), tmp1);
        $$ = res;
    }

    | func_name '(' func_arg_list opt_sort_clause ')' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("", "(", ""), tmp1, tmp2);
        auto tmp3 = $4;
        res = new IR(kFuncApplication, OP3("", ")", ""), res, tmp3);
        $$ = res;
    }

    | func_name '(' VARIADIC func_arg_expr opt_sort_clause ')' {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("", "( VARIADIC", ""), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kFuncApplication, OP3("", ")", ""), res, tmp3);
        $$ = res;
    }

    | func_name '(' func_arg_list ',' VARIADIC func_arg_expr opt_sort_clause ')' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("", "(", ", VARIADIC"), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kFuncApplication, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | func_name '(' ALL func_arg_list opt_sort_clause ')' {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("", "( ALL", ""), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kFuncApplication, OP3("", ")", ""), res, tmp3);
        $$ = res;
    }

    | func_name '(' DISTINCT func_arg_list opt_sort_clause ')' {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("", "( DISTINCT", ""), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kFuncApplication, OP3("", ")", ""), res, tmp3);
        $$ = res;
    }

    | func_name '(' '*' ')' {
        auto tmp1 = $1;
        res = new IR(kFuncApplication, OP3("", "( * )", ""), tmp1);
        $$ = res;
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

func_expr:

    func_application within_group_clause filter_clause over_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUnknown, OP3("", "", ""), tmp1, tmp2);
        auto tmp3 = $3;
        res = new IR(kFuncExpr, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | func_expr_common_subexpr {
        auto tmp1 = $1;
        res = new IR(kFuncExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

;

/*
* As func_expr but does not accept WINDOW functions directly
* (but they can still be contained in arguments for functions etc).
* Use this when window expressions are not allowed, where needed to
* disambiguate the grammar (e.g. in CREATE INDEX).
*/

func_expr_windowless:

    func_application {
        auto tmp1 = $1;
        res = new IR(kFuncExprWindowless, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | func_expr_common_subexpr {
        auto tmp1 = $1;
        res = new IR(kFuncExprWindowless, OP3("", "", ""), tmp1);
        $$ = res;
    }

;

/*
* Special expressions that are considered to be functions.
*/

func_expr_common_subexpr:

    COLLATION FOR '(' a_expr ')' {
        auto tmp1 = $4;
        res = new IR(kFuncExprCommonSubexpr, OP3("COLLATION FOR (", ")", ""), tmp1);
        $$ = res;
    }

    | CURRENT_DATE {
        res = new IR(kFuncExprCommonSubexpr, string("CURRENT_DATE"));
        $$ = res;
    }

    | CURRENT_TIME {
        res = new IR(kFuncExprCommonSubexpr, string("CURRENT_TIME"));
        $$ = res;
    }

    | CURRENT_TIME '(' Iconst ')' {
        auto tmp1 = $3;
        res = new IR(kFuncExprCommonSubexpr, OP3("CURRENT_TIME (", ")", ""), tmp1);
        $$ = res;
    }

    | CURRENT_TIMESTAMP {
        res = new IR(kFuncExprCommonSubexpr, string("CURRENT_TIMESTAMP"));
        $$ = res;
    }

    | CURRENT_TIMESTAMP '(' Iconst ')' {
        auto tmp1 = $3;
        res = new IR(kFuncExprCommonSubexpr, OP3("CURRENT_TIMESTAMP (", ")", ""), tmp1);
        $$ = res;
    }

    | LOCALTIME {
        res = new IR(kFuncExprCommonSubexpr, string("LOCALTIME"));
        $$ = res;
    }

    | LOCALTIME '(' Iconst ')' {
        auto tmp1 = $3;
        res = new IR(kFuncExprCommonSubexpr, OP3("LOCALTIME (", ")", ""), tmp1);
        $$ = res;
    }

    | LOCALTIMESTAMP {
        res = new IR(kFuncExprCommonSubexpr, string("LOCALTIMESTAMP"));
        $$ = res;
    }

    | LOCALTIMESTAMP '(' Iconst ')' {
        auto tmp1 = $3;
        res = new IR(kFuncExprCommonSubexpr, OP3("LOCALTIMESTAMP (", ")", ""), tmp1);
        $$ = res;
    }

    | CURRENT_ROLE {
        res = new IR(kFuncExprCommonSubexpr, string("CURRENT_ROLE"));
        $$ = res;
    }

    | CURRENT_USER {
        res = new IR(kFuncExprCommonSubexpr, string("CURRENT_USER"));
        $$ = res;
    }

    | SESSION_USER {
        res = new IR(kFuncExprCommonSubexpr, string("SESSION_USER"));
        $$ = res;
    }

    | USER {
        res = new IR(kFuncExprCommonSubexpr, string("USER"));
        $$ = res;
    }

    | CURRENT_CATALOG {
        res = new IR(kFuncExprCommonSubexpr, string("CURRENT_CATALOG"));
        $$ = res;
    }

    | CURRENT_SCHEMA {
        res = new IR(kFuncExprCommonSubexpr, string("CURRENT_SCHEMA"));
        $$ = res;
    }

    | CAST '(' a_expr AS Typename ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFuncExprCommonSubexpr, OP3("CAST (", "AS", ")"), tmp1, tmp2);
        $$ = res;
    }

    | EXTRACT '(' extract_list ')' {
        auto tmp1 = $3;
        res = new IR(kFuncExprCommonSubexpr, OP3("EXTRACT (", ")", ""), tmp1);
        $$ = res;
    }

    | NORMALIZE '(' a_expr ')' {
        auto tmp1 = $3;
        res = new IR(kFuncExprCommonSubexpr, OP3("NORMALIZE (", ")", ""), tmp1);
        $$ = res;
    }

    | NORMALIZE '(' a_expr ',' unicode_normal_form ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFuncExprCommonSubexpr, OP3("NORMALIZE (", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

    | OVERLAY '(' overlay_list ')' {
        auto tmp1 = $3;
        res = new IR(kFuncExprCommonSubexpr, OP3("OVERLAY (", ")", ""), tmp1);
        $$ = res;
    }

    | OVERLAY '(' func_arg_list_opt ')' {
        auto tmp1 = $3;
        res = new IR(kFuncExprCommonSubexpr, OP3("OVERLAY (", ")", ""), tmp1);
        $$ = res;
    }

    | POSITION '(' position_list ')' {
        auto tmp1 = $3;
        res = new IR(kFuncExprCommonSubexpr, OP3("POSITION (", ")", ""), tmp1);
        $$ = res;
    }

    | SUBSTRING '(' substr_list ')' {
        auto tmp1 = $3;
        res = new IR(kFuncExprCommonSubexpr, OP3("SUBSTRING (", ")", ""), tmp1);
        $$ = res;
    }

    | SUBSTRING '(' func_arg_list_opt ')' {
        auto tmp1 = $3;
        res = new IR(kFuncExprCommonSubexpr, OP3("SUBSTRING (", ")", ""), tmp1);
        $$ = res;
    }

    | TREAT '(' a_expr AS Typename ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFuncExprCommonSubexpr, OP3("TREAT (", "AS", ")"), tmp1, tmp2);
        $$ = res;
    }

    | TRIM '(' BOTH trim_list ')' {
        auto tmp1 = $4;
        res = new IR(kFuncExprCommonSubexpr, OP3("TRIM ( BOTH", ")", ""), tmp1);
        $$ = res;
    }

    | TRIM '(' LEADING trim_list ')' {
        auto tmp1 = $4;
        res = new IR(kFuncExprCommonSubexpr, OP3("TRIM ( LEADING", ")", ""), tmp1);
        $$ = res;
    }

    | TRIM '(' TRAILING trim_list ')' {
        auto tmp1 = $4;
        res = new IR(kFuncExprCommonSubexpr, OP3("TRIM ( TRAILING", ")", ""), tmp1);
        $$ = res;
    }

    | TRIM '(' trim_list ')' {
        auto tmp1 = $3;
        res = new IR(kFuncExprCommonSubexpr, OP3("TRIM (", ")", ""), tmp1);
        $$ = res;
    }

    | NULLIF '(' a_expr ',' a_expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFuncExprCommonSubexpr, OP3("NULLIF (", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

    | COALESCE '(' expr_list ')' {
        auto tmp1 = $3;
        res = new IR(kFuncExprCommonSubexpr, OP3("COALESCE (", ")", ""), tmp1);
        $$ = res;
    }

    | GREATEST '(' expr_list ')' {
        auto tmp1 = $3;
        res = new IR(kFuncExprCommonSubexpr, OP3("GREATEST (", ")", ""), tmp1);
        $$ = res;
    }

    | LEAST '(' expr_list ')' {
        auto tmp1 = $3;
        res = new IR(kFuncExprCommonSubexpr, OP3("LEAST (", ")", ""), tmp1);
        $$ = res;
    }

    | XMLCONCAT '(' expr_list ')' {
        auto tmp1 = $3;
        res = new IR(kFuncExprCommonSubexpr, OP3("XMLCONCAT (", ")", ""), tmp1);
        $$ = res;
    }

    | XMLELEMENT '(' NAME_P ColLabel ')' {
        auto tmp1 = $4;
        res = new IR(kFuncExprCommonSubexpr, OP3("XMLELEMENT ( NAME", ")", ""), tmp1);
        $$ = res;
    }

    | XMLELEMENT '(' NAME_P ColLabel ',' xml_attributes ')' {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kFuncExprCommonSubexpr, OP3("XMLELEMENT ( NAME", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

    | XMLELEMENT '(' NAME_P ColLabel ',' expr_list ')' {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kFuncExprCommonSubexpr, OP3("XMLELEMENT ( NAME", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

    | XMLELEMENT '(' NAME_P ColLabel ',' xml_attributes ',' expr_list ')' {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kUnknown, OP3("XMLELEMENT ( NAME", ",", ","), tmp1, tmp2);
        auto tmp3 = $8;
        res = new IR(kFuncExprCommonSubexpr, OP3("", ")", ""), res, tmp3);
        $$ = res;
    }

    | XMLEXISTS '(' c_expr xmlexists_argument ')' {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kFuncExprCommonSubexpr, OP3("XMLEXISTS (", "", ")"), tmp1, tmp2);
        $$ = res;
    }

    | XMLFOREST '(' xml_attribute_list ')' {
        auto tmp1 = $3;
        res = new IR(kFuncExprCommonSubexpr, OP3("XMLFOREST (", ")", ""), tmp1);
        $$ = res;
    }

    | XMLPARSE '(' document_or_content a_expr xml_whitespace_option ')' {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("XMLPARSE (", "", ""), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kFuncExprCommonSubexpr, OP3("", ")", ""), res, tmp3);
        $$ = res;
    }

    | XMLPI '(' NAME_P ColLabel ')' {
        auto tmp1 = $4;
        res = new IR(kFuncExprCommonSubexpr, OP3("XMLPI ( NAME", ")", ""), tmp1);
        $$ = res;
    }

    | XMLPI '(' NAME_P ColLabel ',' a_expr ')' {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kFuncExprCommonSubexpr, OP3("XMLPI ( NAME", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

    | XMLROOT '(' a_expr ',' xml_root_version opt_xml_root_standalone ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kUnknown, OP3("XMLROOT (", ",", ""), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kFuncExprCommonSubexpr, OP3("", ")", ""), res, tmp3);
        $$ = res;
    }

    | XMLSERIALIZE '(' document_or_content a_expr AS SimpleTypename ')' {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("XMLSERIALIZE (", "", "AS"), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kFuncExprCommonSubexpr, OP3("", ")", ""), res, tmp3);
        $$ = res;
    }

;

/*
* SQL/XML support
*/

xml_root_version:

    VERSION_P a_expr {
        auto tmp1 = $2;
        res = new IR(kXmlRootVersion, OP3("VERSION", "", ""), tmp1);
        $$ = res;
    }

    | VERSION_P NO VALUE_P {
        res = new IR(kXmlRootVersion, string("VERSION NO VALUE"));
        $$ = res;
    }

;


opt_xml_root_standalone:

    STANDALONE_P YES_P {
        res = new IR(kOptXmlRootStandalone, string("STANDALONE YES"));
        $$ = res;
    }

    | ',' STANDALONE_P NO {
        res = new IR(kOptXmlRootStandalone, string(", STANDALONE NO"));
        $$ = res;
    }

    | ',' STANDALONE_P NO VALUE_P {
        res = new IR(kOptXmlRootStandalone, string(", STANDALONE NO VALUE"));
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptXmlRootStandalone, string(""));
        $$ = res;
    }

;


xml_attributes:

    XMLATTRIBUTES '(' xml_attribute_list ')' {
        auto tmp1 = $3;
        res = new IR(kXmlAttributes, OP3("XMLATTRIBUTES (", ")", ""), tmp1);
        $$ = res;
    }

;


xml_attribute_list:

    xml_attribute_el {
        auto tmp1 = $1;
        res = new IR(kXmlAttributeList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | xml_attribute_list ',' xml_attribute_el {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kXmlAttributeList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


xml_attribute_el:

    a_expr AS ColLabel {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kXmlAttributeEl, OP3("", "AS", ""), tmp1, tmp2);
        $$ = res;
    }

    | a_expr {
        auto tmp1 = $1;
        res = new IR(kXmlAttributeEl, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


document_or_content:

    DOCUMENT_P {
        res = new IR(kDocumentOrContent, string("DOCUMENT"));
        $$ = res;
    }

    | CONTENT_P {
        res = new IR(kDocumentOrContent, string("CONTENT"));
        $$ = res;
    }

;


xml_whitespace_option:

    PRESERVE WHITESPACE_P {
        res = new IR(kXmlWhitespaceOption, string("PRESERVE WHITESPACE"));
        $$ = res;
    }

    | STRIP_P WHITESPACE_P {
        res = new IR(kXmlWhitespaceOption, string("STRIP WHITESPACE"));
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kXmlWhitespaceOption, string(""));
        $$ = res;
    }

;

/* We allow several variants for SQL and other compatibility. */

xmlexists_argument:

    PASSING c_expr {
        auto tmp1 = $2;
        res = new IR(kXmlexistsArgument, OP3("PASSING", "", ""), tmp1);
        $$ = res;
    }

    | PASSING c_expr xml_passing_mech {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kXmlexistsArgument, OP3("PASSING", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | PASSING xml_passing_mech c_expr {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kXmlexistsArgument, OP3("PASSING", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | PASSING xml_passing_mech c_expr xml_passing_mech {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("PASSING", "", ""), tmp1, tmp2);
        auto tmp3 = $4;
        res = new IR(kXmlexistsArgument, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;

xml_passing_mech:
    BY REF {
        $$ = new IR(kXmlPassingMech, OP3("BY REF", "", ""));
    }
    | BY VALUE_P {
        $$ = new IR(kXmlPassingMech, OP0());
    }
;


/*
* Aggregate decoration clauses
*/

within_group_clause:

    WITHIN GROUP_P '(' sort_clause ')' {
        auto tmp1 = $4;
        res = new IR(kWithinGroupClause, OP3("WITHIN GROUP (", ")", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kWithinGroupClause, string(""));
        $$ = res;
    }

;


filter_clause:

    FILTER '(' WHERE a_expr ')' {
        auto tmp1 = $4;
        res = new IR(kFilterClause, OP3("FILTER ( WHERE", ")", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kFilterClause, string(""));
        $$ = res;
    }

;


/*
* Window Definitions
*/

window_clause:

    WINDOW window_definition_list {
        auto tmp1 = $2;
        res = new IR(kWindowClause, OP3("WINDOW", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kWindowClause, string(""));
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

    ColId AS window_specification {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kWindowDefinition, OP3("", "AS", ""), tmp1, tmp2);
        $$ = res;
    }

;


over_clause:

    OVER window_specification {
        auto tmp1 = $2;
        res = new IR(kOverClause, OP3("OVER", "", ""), tmp1);
        $$ = res;
    }

    | OVER ColId {
        auto tmp1 = $2;
        res = new IR(kOverClause, OP3("OVER", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOverClause, string(""));
        $$ = res;
    }

;


window_specification:

    opt_existing_window_name opt_partition_clause opt_sort_clause opt_frame_clause ')' {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUnknown, OP3("", "", ""), tmp1, tmp2);
        auto tmp3 = $3;
        res = new IR(kWindowSpecification, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

;

/*
* If we see PARTITION, RANGE, ROWS or GROUPS as the first token after the '('
* of a window_specification, we want the assumption to be that there is
* no existing_window_name; but those keywords are unreserved and so could
* be ColIds.  We fix this by making them have the same precedence as IDENT
* and giving the empty production here a slightly higher precedence, so
* that the shift/reduce conflict is resolved in favor of reducing the rule.
* These keywords are thus precluded from being an existing_window_name but
* are not reserved for any other purpose.
*/

opt_existing_window_name:

    ColId {
        auto tmp1 = $1;
        res = new IR(kOptExistingWindowName, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ %prec Op {
        res = new IR(kOptExistingWindowName, string(""));
        $$ = res;
    }

;


opt_partition_clause:

    PARTITION BY expr_list {
        auto tmp1 = $3;
        res = new IR(kOptPartitionClause, OP3("PARTITION BY", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptPartitionClause, string(""));
        $$ = res;
    }

;

/*
* For frame clauses, we return a WindowDef, but only some fields are used:
* frameOptions, startOffset, and endOffset.
*/

opt_frame_clause:

    RANGE frame_extent opt_window_exclusion_clause {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kOptFrameClause, OP3("RANGE", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ROWS frame_extent opt_window_exclusion_clause {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kOptFrameClause, OP3("ROWS", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | GROUPS frame_extent opt_window_exclusion_clause {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kOptFrameClause, OP3("GROUPS", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptFrameClause, string(""));
        $$ = res;
    }

;


frame_extent:

    frame_bound {
        auto tmp1 = $1;
        res = new IR(kFrameExtent, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | BETWEEN frame_bound AND frame_bound {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kFrameExtent, OP3("BETWEEN", "AND", ""), tmp1, tmp2);
        $$ = res;
    }

;

/*
* This is used for both frame start and frame end, with output set up on
* the assumption it's frame start; the frame_extent productions must reject
* invalid cases.
*/

frame_bound:

    UNBOUNDED PRECEDING {
        res = new IR(kFrameBound, string("UNBOUNDED PRECEDING"));
        $$ = res;
    }

    | UNBOUNDED FOLLOWING {
        res = new IR(kFrameBound, string("UNBOUNDED FOLLOWING"));
        $$ = res;
    }

    | CURRENT_P ROW {
        res = new IR(kFrameBound, string("CURRENT ROW"));
        $$ = res;
    }

    | a_expr PRECEDING {
        auto tmp1 = $1;
        res = new IR(kFrameBound, OP3("", "PRECEDING", ""), tmp1);
        $$ = res;
    }

    | a_expr FOLLOWING {
        auto tmp1 = $1;
        res = new IR(kFrameBound, OP3("", "FOLLOWING", ""), tmp1);
        $$ = res;
    }

;


opt_window_exclusion_clause:

    EXCLUDE CURRENT_P ROW {
        res = new IR(kOptWindowExclusionClause, string("EXCLUDE CURRENT ROW"));
        $$ = res;
    }

    | EXCLUDE GROUP_P {
        res = new IR(kOptWindowExclusionClause, string("EXCLUDE GROUP"));
        $$ = res;
    }

    | EXCLUDE TIES {
        res = new IR(kOptWindowExclusionClause, string("EXCLUDE TIES"));
        $$ = res;
    }

    | EXCLUDE NO OTHERS {
        res = new IR(kOptWindowExclusionClause, string("EXCLUDE NO OTHERS"));
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptWindowExclusionClause, string(""));
        $$ = res;
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

row:

    ROW '(' expr_list ')' {
        auto tmp1 = $3;
        res = new IR(kRow, OP3("ROW (", ")", ""), tmp1);
        $$ = res;
    }

    | ROW '(' ')' {
        res = new IR(kRow, string("ROW ( )"));
        $$ = res;
    }

    | '(' expr_list ',' a_expr ')' {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kRow, OP3("(", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

;


explicit_row:

    ROW '(' expr_list ')' {
        auto tmp1 = $3;
        res = new IR(kExplicitRow, OP3("ROW (", ")", ""), tmp1);
        $$ = res;
    }

    | ROW '(' ')' {
        res = new IR(kExplicitRow, string("ROW ( )"));
        $$ = res;
    }

;


implicit_row:

    expr_list ',' a_expr ')' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kImplicitRow, OP3("", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

;


sub_type:

    ANY {
        res = new IR(kSubType, string("ANY"));
        $$ = res;
    }

    | SOME {
        res = new IR(kSubType, string("SOME"));
        $$ = res;
    }

    | ALL {
        res = new IR(kSubType, string("ALL"));
        $$ = res;
    }

;


all_Op:

    Op {
        res = new IR(kAllOp, string("OP"));
        $$ = res;
    }

    | MathOp {
        auto tmp1 = $1;
        res = new IR(kAllOp, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


MathOp:

    LESS_EQUALS {
        res = new IR(kMathOp, string("LESS_EQUALS"));
        $$ = res;
    }

    | '-' {
        res = new IR(kMathOp, string("-"));
        $$ = res;
    }

    | '*' {
        res = new IR(kMathOp, string("*"));
        $$ = res;
    }

    | '/' {
        res = new IR(kMathOp, string("/"));
        $$ = res;
    }

    | '%' {
        res = new IR(kMathOp, string("%"));
        $$ = res;
    }

    | '^' {
        res = new IR(kMathOp, string("^"));
        $$ = res;
    }

    | '<' {
        res = new IR(kMathOp, string("<"));
        $$ = res;
    }

    | '>' {
        res = new IR(kMathOp, string(">"));
        $$ = res;
    }

    | '=' {
        res = new IR(kMathOp, string("="));
        $$ = res;
    }

    | LESS_EQUALS {
        res = new IR(kMathOp, string("LESS_EQUALS"));
        $$ = res;
    }

    | GREATER_EQUALS {
        res = new IR(kMathOp, string("GREATER_EQUALS"));
        $$ = res;
    }

    | NOT_EQUALS {
        res = new IR(kMathOp, string("NOT_EQUALS"));
        $$ = res;
    }

;


qual_Op:

    Op {
        res = new IR(kQualOp, string("OP"));
        $$ = res;
    }

    | OPERATOR '(' any_operator ')' {
        auto tmp1 = $3;
        res = new IR(kQualOp, OP3("OPERATOR (", ")", ""), tmp1);
        $$ = res;
    }

;


qual_all_Op:

    all_Op {
        auto tmp1 = $1;
        res = new IR(kQualAllOp, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | OPERATOR '(' any_operator ')' {
        auto tmp1 = $3;
        res = new IR(kQualAllOp, OP3("OPERATOR (", ")", ""), tmp1);
        $$ = res;
    }

;


subquery_Op:

    all_Op {
        auto tmp1 = $1;
        res = new IR(kSubqueryOp, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | OPERATOR '(' any_operator ')' {
        auto tmp1 = $3;
        res = new IR(kSubqueryOp, OP3("OPERATOR (", ")", ""), tmp1);
        $$ = res;
    }

    | LIKE {
        res = new IR(kSubqueryOp, string("LIKE"));
        $$ = res;
    }

    | NOT_LA LIKE {
        res = new IR(kSubqueryOp, string("NOT LIKE"));
        $$ = res;
    }

    | ILIKE {
        res = new IR(kSubqueryOp, string("ILIKE"));
        $$ = res;
    }

    | NOT_LA ILIKE {
        res = new IR(kSubqueryOp, string("NOT ILIKE"));
        $$ = res;
    }

;


expr_list:

    a_expr {
        auto tmp1 = $1;
        res = new IR(kExprList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | expr_list ',' a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kExprList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;

/* function arguments can have names */

func_arg_list:

    func_arg_expr {
        auto tmp1 = $1;
        res = new IR(kFuncArgList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | func_arg_list ',' func_arg_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kFuncArgList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


func_arg_expr:

    a_expr {
        auto tmp1 = $1;
        res = new IR(kFuncArgExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | param_name COLON_EQUALS a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kFuncArgExpr, OP3("", "COLON_EQUALS", ""), tmp1, tmp2);
        $$ = res;
    }

    | param_name EQUALS_GREATER a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kFuncArgExpr, OP3("", "EQUALS_GREATER", ""), tmp1, tmp2);
        $$ = res;
    }

;


func_arg_list_opt:

    func_arg_list {
        auto tmp1 = $1;
        res = new IR(kFuncArgListOpt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kFuncArgListOpt, string(""));
        $$ = res;
    }

;


type_list:

    Typename {
        auto tmp1 = $1;
        res = new IR(kTypeList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | type_list ',' Typename {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTypeList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


array_expr:

    expr_list ']' {
        auto tmp1 = $1;
        res = new IR(kArrayExpr, OP3("", "]", ""), tmp1);
        $$ = res;
    }

    | '[' array_expr_list ']' {
        auto tmp1 = $2;
        res = new IR(kArrayExpr, OP3("[", "]", ""), tmp1);
        $$ = res;
    }

    | '[' ']' {
        res = new IR(kArrayExpr, string("[ ]"));
        $$ = res;
    }

;


array_expr_list:

    array_expr {
        auto tmp1 = $1;
        res = new IR(kArrayExprList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | array_expr_list ',' array_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kArrayExprList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;



extract_list:

    extract_arg FROM a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kExtractList, OP3("", "FROM", ""), tmp1, tmp2);
        $$ = res;
    }

;

/* Allow delimited string Sconst in extract_arg as an SQL extension.
* - thomas 2001-04-12
*/

extract_arg:

    IDENT {
        res = new IR(kExtractArg, string("IDENT"));
        $$ = res;
    }

    | YEAR_P {
        res = new IR(kExtractArg, string("YEAR"));
        $$ = res;
    }

    | MONTH_P {
        res = new IR(kExtractArg, string("MONTH"));
        $$ = res;
    }

    | DAY_P {
        res = new IR(kExtractArg, string("DAY"));
        $$ = res;
    }

    | HOUR_P {
        res = new IR(kExtractArg, string("HOUR"));
        $$ = res;
    }

    | MINUTE_P {
        res = new IR(kExtractArg, string("MINUTE"));
        $$ = res;
    }

    | SECOND_P {
        res = new IR(kExtractArg, string("SECOND"));
        $$ = res;
    }

    | Sconst {
        auto tmp1 = $1;
        res = new IR(kExtractArg, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


unicode_normal_form:

    NFC {
        res = new IR(kUnicodeNormalForm, string("NFC"));
        $$ = res;
    }

    | NFD {
        res = new IR(kUnicodeNormalForm, string("NFD"));
        $$ = res;
    }

    | NFKC {
        res = new IR(kUnicodeNormalForm, string("NFKC"));
        $$ = res;
    }

    | NFKD {
        res = new IR(kUnicodeNormalForm, string("NFKD"));
        $$ = res;
    }

;

/* OVERLAY() arguments */

overlay_list:

    a_expr PLACING a_expr FROM a_expr FOR a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("", "PLACING", "FROM"), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kOverlayList, OP3("", "FOR", ""), res, tmp3);
        $$ = res;
    }

    | a_expr PLACING a_expr FROM a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("", "PLACING", "FROM"), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kOverlayList, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;

/* position_list uses b_expr not a_expr to avoid conflict with general IN */

position_list:

    b_expr IN_P b_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kPositionList, OP3("", "IN", ""), tmp1, tmp2);
        $$ = res;
    }

;

/*
* SUBSTRING() arguments
*
* Note that SQL:1999 has both
*     text FROM int FOR int
* and
*     text FROM pattern FOR escape
*
* In the parser we map them both to a call to the substring() function and
* rely on type resolution to pick the right one.
*
* In SQL:2003, the second variant was changed to
*     text SIMILAR pattern ESCAPE escape
* We could in theory map that to a different function internally, but
* since we still support the SQL:1999 version, we don't.  However,
* ruleutils.c will reverse-list the call in the newer style.
*/

substr_list:

    a_expr FROM a_expr FOR a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("", "FROM", "FOR"), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kSubstrList, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | a_expr FOR a_expr FROM a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("", "FOR", "FROM"), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kSubstrList, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | a_expr FROM a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSubstrList, OP3("", "FROM", ""), tmp1, tmp2);
        $$ = res;
    }

    | a_expr FOR a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSubstrList, OP3("", "FOR", ""), tmp1, tmp2);
        $$ = res;
    }

    | a_expr SIMILAR a_expr ESCAPE a_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("", "SIMILAR", "ESCAPE"), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kSubstrList, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


trim_list:

    a_expr FROM expr_list {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTrimList, OP3("", "FROM", ""), tmp1, tmp2);
        $$ = res;
    }

    | FROM expr_list {
        auto tmp1 = $2;
        res = new IR(kTrimList, OP3("FROM", "", ""), tmp1);
        $$ = res;
    }

    | expr_list {
        auto tmp1 = $1;
        res = new IR(kTrimList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


in_expr:

    select_with_parens {
        auto tmp1 = $1;
        res = new IR(kInExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '(' expr_list ')' {
        auto tmp1 = $2;
        res = new IR(kInExpr, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

;

/*
* Define SQL-style CASE clause.
* - Full specification
*	CASE WHEN a = b THEN c ... ELSE d END
* - Implicit argument
*	CASE a WHEN b THEN c ... ELSE d END
*/

case_expr:

    CASE case_arg when_clause_list case_default END_P {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("CASE", "", ""), tmp1, tmp2);
        auto tmp3 = $4;
        res = new IR(kCaseExpr, OP3("", "END", ""), res, tmp3);
        $$ = res;
    }

;


when_clause_list:

    when_clause {
        auto tmp1 = $1;
        res = new IR(kWhenClauseList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | when_clause_list when_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kWhenClauseList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


when_clause:

    WHEN a_expr THEN a_expr {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kWhenClause, OP3("WHEN", "THEN", ""), tmp1, tmp2);
        $$ = res;
    }

;


case_default:

    ELSE a_expr {
        auto tmp1 = $2;
        res = new IR(kCaseDefault, OP3("ELSE", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kCaseDefault, string(""));
        $$ = res;
    }

;


case_arg:

    a_expr {
        auto tmp1 = $1;
        res = new IR(kCaseArg, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kCaseArg, string(""));
        $$ = res;
    }

;


columnref:

    ColId {
        auto tmp1 = $1;
        res = new IR(kColumnref, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ColId indirection {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kColumnref, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


indirection_el:

    attr_name {
        auto tmp1 = $1;
        res = new IR(kIndirectionEl, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '.' '*' {
        res = new IR(kIndirectionEl, string(". *"));
        $$ = res;
    }

    | '[' a_expr ']' {
        auto tmp1 = $2;
        res = new IR(kIndirectionEl, OP3("[", "]", ""), tmp1);
        $$ = res;
    }

    | '[' opt_slice_bound ':' opt_slice_bound ']' {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kIndirectionEl, OP3("[", ":", "]"), tmp1, tmp2);
        $$ = res;
    }

;


opt_slice_bound:

    a_expr {
        auto tmp1 = $1;
        res = new IR(kOptSliceBound, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptSliceBound, string(""));
        $$ = res;
    }

;


indirection:

    indirection_el {
        auto tmp1 = $1;
        res = new IR(kIndirection, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | indirection indirection_el {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kIndirection, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_indirection:

    /*EMPTY*/ {
        res = new IR(kOptIndirection, string(""));
        $$ = res;
    }

    | opt_indirection indirection_el {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptIndirection, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;

opt_asymmetric: 
    ASYMMETRIC {
        $$ = new IR(kOptAsymmetric, OP3("ASYMMETRIC", "", ""));
    }
    | /*EMPTY*/ {
        $$ = new IR(kOptAsymmetric, OP0());
    }
;


/*****************************************************************************
*
*	target list for SELECT
*
*****************************************************************************/


opt_target_list:

    target_list {
        auto tmp1 = $1;
        res = new IR(kOptTargetList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | /* EMPTY */ {
        res = new IR(kOptTargetList, string(""));
        $$ = res;
    }

;


target_list:

    target_el {
        auto tmp1 = $1;
        res = new IR(kTargetList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | target_list ',' target_el {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTargetList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


target_el:

    a_expr AS ColLabel {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTargetEl, OP3("", "AS", ""), tmp1, tmp2);
        $$ = res;
    }

    | a_expr BareColLabel {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kTargetEl, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | a_expr {
        auto tmp1 = $1;
        res = new IR(kTargetEl, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '*' {
        res = new IR(kTargetEl, string("*"));
        $$ = res;
    }

;


/*****************************************************************************
*
*	Names and constants
*
*****************************************************************************/


qualified_name_list:

    qualified_name {
        auto tmp1 = $1;
        res = new IR(kQualifiedNameList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | qualified_name_list ',' qualified_name {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kQualifiedNameList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;

/*
* The production for a qualified relation name has to exactly match the
* production for a qualified func_name, because in a FROM clause we cannot
* tell which we are parsing until we see what comes after it ('(' for a
* func_name, something else for a relation). Therefore we allow 'indirection'
* which may contain subscripts, and reject that case in the C code.
*/

qualified_name:

    ColId {
        auto tmp1 = $1;
        res = new IR(kQualifiedName, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ColId indirection {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kQualifiedName, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


name_list:

    name {
        auto tmp1 = $1;
        res = new IR(kNameList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | name_list ',' name {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kNameList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;



name:

    ColId {
        auto tmp1 = $1;
        res = new IR(kName, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


attr_name:

    ColLabel {
        auto tmp1 = $1;
        res = new IR(kAttrName, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


file_name:

    Sconst {
        auto tmp1 = $1;
        res = new IR(kFileName, OP3("", "", ""), tmp1);
        $$ = res;
    }

;

/*
* The production for a qualified func_name has to exactly match the
* production for a qualified columnref, because we cannot tell which we
* are parsing until we see what comes after it ('(' or Sconst for a func_name,
* anything else for a columnref).  Therefore we allow 'indirection' which
* may contain subscripts, and reject that case in the C code.  (If we
* ever implement SQL99-like methods, such syntax may actually become legal!)
*/

func_name:

    type_function_name {
        auto tmp1 = $1;
        res = new IR(kFuncName, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ColId indirection {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFuncName, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


/*
* Constants
*/

AexprConst:

    Iconst {
        auto tmp1 = $1;
        res = new IR(kAexprConst, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | FCONST {
        res = new IR(kAexprConst, string("FCONST"));
        $$ = res;
    }

    | Sconst {
        auto tmp1 = $1;
        res = new IR(kAexprConst, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | BCONST {
        res = new IR(kAexprConst, string("BCONST"));
        $$ = res;
    }

    | XCONST {
        res = new IR(kAexprConst, string("XCONST"));
        $$ = res;
    }

    | func_name Sconst {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAexprConst, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | func_name '(' func_arg_list opt_sort_clause ')' Sconst {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("", "(", ""), tmp1, tmp2);
        auto tmp3 = $4;
        res = new IR(kAexprConst, OP3("", ")", ""), res, tmp3);
        $$ = res;
    }

    | ConstTypename Sconst {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAexprConst, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ConstInterval Sconst opt_interval {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUnknown, OP3("", "", ""), tmp1, tmp2);
        auto tmp3 = $3;
        res = new IR(kAexprConst, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ConstInterval '(' Iconst ')' Sconst {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("", "(", ")"), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kAexprConst, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | TRUE_P {
        res = new IR(kAexprConst, string("TRUE"));
        $$ = res;
    }

    | FALSE_P {
        res = new IR(kAexprConst, string("FALSE"));
        $$ = res;
    }

    | NULL_P {
        res = new IR(kAexprConst, string("NULL"));
        $$ = res;
    }

;


Iconst:

    ICONST {
        res = new IR(kIconst, string("ICONST"));
        $$ = res;
    }

;

Sconst:

    SCONST {
        res = new IR(kSconst, string("SCONST"));
        $$ = res;
    }

;


SignedIconst:

    Iconst {
        auto tmp1 = $1;
        res = new IR(kSignedIconst, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '+' Iconst {
        auto tmp1 = $2;
        res = new IR(kSignedIconst, OP3("+", "", ""), tmp1);
        $$ = res;
    }

    | '-' Iconst {
        auto tmp1 = $2;
        res = new IR(kSignedIconst, OP3("-", "", ""), tmp1);
        $$ = res;
    }

;

/* Role specifications */

RoleId:

    RoleSpec {
        auto tmp1 = $1;
        res = new IR(kRoleId, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


RoleSpec:

    NonReservedWord {
        auto tmp1 = $1;
        res = new IR(kRoleSpec, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CURRENT_ROLE {
        res = new IR(kRoleSpec, string("CURRENT_ROLE"));
        $$ = res;
    }

    | CURRENT_USER {
        res = new IR(kRoleSpec, string("CURRENT_USER"));
        $$ = res;
    }

    | SESSION_USER {
        res = new IR(kRoleSpec, string("SESSION_USER"));
        $$ = res;
    }

;


role_list:

    RoleSpec {
        auto tmp1 = $1;
        res = new IR(kRoleList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | role_list ',' RoleSpec {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kRoleList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


/*****************************************************************************
*
* PL/pgSQL extensions
*
* You'd think a PL/pgSQL "expression" should be just an a_expr, but
* historically it can include just about anything that can follow SELECT.
* Therefore the returned struct is a SelectStmt.
*****************************************************************************/


PLpgSQL_Expr:

    opt_distinct_clause opt_target_list from_clause where_clause group_clause having_clause window_clause opt_sort_clause opt_select_limit opt_for_locking_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUnknown, OP3("", "", ""), tmp1, tmp2);
        auto tmp3 = $3;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp3);
        auto tmp4 = $5;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp4);
        auto tmp5 = $7;
        res = new IR(kUnknown, OP3("", "", ""), res, tmp5);
        auto tmp6 = $9;
        res = new IR(kPLpgSQLExpr, OP3("", "", ""), res, tmp6);
        $$ = res;
    }

;

/*
* PL/pgSQL Assignment statement: name opt_indirection := PLpgSQL_Expr
*/


PLAssignStmt:

    plassign_target opt_indirection plassign_equals PLpgSQL_Expr {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUnknown, OP3("", "", ""), tmp1, tmp2);
        auto tmp3 = $3;
        res = new IR(kPLAssignStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


plassign_target:

    ColId {
        auto tmp1 = $1;
        res = new IR(kPlassignTarget, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | PARAM {
        res = new IR(kPlassignTarget, string("PARAM"));
        $$ = res;
    }

;

plassign_equals: 
    COLON_EQUALS {
        $$ = new IR(kPlassignEquals, OP3("=", "", ""));
    }
    | '=' {
        $$ = new IR(kPlassignEquals, OP3("=", "", ""));
    }
;


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

/* Column identifier --- names that can be column, table, etc names.
*/

ColId:

    IDENT {
        res = new IR(kColId, string("IDENT"));
        $$ = res;
    }

    | unreserved_keyword {
        auto tmp1 = $1;
        res = new IR(kColId, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | col_name_keyword {
        auto tmp1 = $1;
        res = new IR(kColId, OP3("", "", ""), tmp1);
        $$ = res;
    }

;

/* Type/function identifier --- names that can be type or function names.
*/

type_function_name:

    IDENT {
        res = new IR(kTypeFunctionName, string("IDENT"));
        $$ = res;
    }

    | unreserved_keyword {
        auto tmp1 = $1;
        res = new IR(kTypeFunctionName, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | type_func_name_keyword {
        auto tmp1 = $1;
        res = new IR(kTypeFunctionName, OP3("", "", ""), tmp1);
        $$ = res;
    }

;

/* Any not-fully-reserved word --- these names can be, eg, role names.
*/

NonReservedWord:

    IDENT {
        res = new IR(kNonReservedWord, string("IDENT"));
        $$ = res;
    }

    | unreserved_keyword {
        auto tmp1 = $1;
        res = new IR(kNonReservedWord, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | col_name_keyword {
        auto tmp1 = $1;
        res = new IR(kNonReservedWord, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | type_func_name_keyword {
        auto tmp1 = $1;
        res = new IR(kNonReservedWord, OP3("", "", ""), tmp1);
        $$ = res;
    }

;

/* Column label --- allowed labels in "AS" clauses.
* This presently includes *all* Postgres keywords.
*/

ColLabel:

    IDENT {
        res = new IR(kColLabel, string("IDENT"));
        $$ = res;
    }

    | unreserved_keyword {
        auto tmp1 = $1;
        res = new IR(kColLabel, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | col_name_keyword {
        auto tmp1 = $1;
        res = new IR(kColLabel, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | type_func_name_keyword {
        auto tmp1 = $1;
        res = new IR(kColLabel, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | reserved_keyword {
        auto tmp1 = $1;
        res = new IR(kColLabel, OP3("", "", ""), tmp1);
        $$ = res;
    }

;

/* Bare column label --- names that can be column labels without writing "AS".
* This classification is orthogonal to the other keyword categories.
*/

BareColLabel:

    IDENT {
        res = new IR(kBareColLabel, string("IDENT"));
        $$ = res;
    }

    | bare_label_keyword {
        auto tmp1 = $1;
        res = new IR(kBareColLabel, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


/*
* Keyword category lists.  Generally, every keyword present in
* the Postgres grammar should appear in exactly one of these lists.
*
* Put a new keyword into the first list that it can go into without causing
* shift or reduce conflicts.  The earlier lists define "less reserved"
* categories of keywords.
*
* Make sure that each keyword's category in kwlist.h matches where
* it is listed here.  (Someday we may be able to generate these lists and
* kwlist.h's table from one source of truth.)
*/

/* "Unreserved" keywords --- available for use as any kind of name.
*/

unreserved_keyword:

    ABORT_P {
        res = new IR(kUnreservedKeyword, string("ABORT"));
        $$ = res;
    }

    | ABSOLUTE_P {
        res = new IR(kUnreservedKeyword, string("ABSOLUTE"));
        $$ = res;
    }

    | ACCESS {
        res = new IR(kUnreservedKeyword, string("ACCESS"));
        $$ = res;
    }

    | ACTION {
        res = new IR(kUnreservedKeyword, string("ACTION"));
        $$ = res;
    }

    | ADD_P {
        res = new IR(kUnreservedKeyword, string("ADD"));
        $$ = res;
    }

    | ADMIN {
        res = new IR(kUnreservedKeyword, string("ADMIN"));
        $$ = res;
    }

    | AFTER {
        res = new IR(kUnreservedKeyword, string("AFTER"));
        $$ = res;
    }

    | AGGREGATE {
        res = new IR(kUnreservedKeyword, string("AGGREGATE"));
        $$ = res;
    }

    | ALSO {
        res = new IR(kUnreservedKeyword, string("ALSO"));
        $$ = res;
    }

    | ALTER {
        res = new IR(kUnreservedKeyword, string("ALTER"));
        $$ = res;
    }

    | ALWAYS {
        res = new IR(kUnreservedKeyword, string("ALWAYS"));
        $$ = res;
    }

    | ASENSITIVE {
        res = new IR(kUnreservedKeyword, string("ASENSITIVE"));
        $$ = res;
    }

    | ASSERTION {
        res = new IR(kUnreservedKeyword, string("ASSERTION"));
        $$ = res;
    }

    | ASSIGNMENT {
        res = new IR(kUnreservedKeyword, string("ASSIGNMENT"));
        $$ = res;
    }

    | AT {
        res = new IR(kUnreservedKeyword, string("AT"));
        $$ = res;
    }

    | ATOMIC {
        res = new IR(kUnreservedKeyword, string("ATOMIC"));
        $$ = res;
    }

    | ATTACH {
        res = new IR(kUnreservedKeyword, string("ATTACH"));
        $$ = res;
    }

    | ATTRIBUTE {
        res = new IR(kUnreservedKeyword, string("ATTRIBUTE"));
        $$ = res;
    }

    | BACKWARD {
        res = new IR(kUnreservedKeyword, string("BACKWARD"));
        $$ = res;
    }

    | BEFORE {
        res = new IR(kUnreservedKeyword, string("BEFORE"));
        $$ = res;
    }

    | BEGIN_P {
        res = new IR(kUnreservedKeyword, string("BEGIN"));
        $$ = res;
    }

    | BREADTH {
        res = new IR(kUnreservedKeyword, string("BREADTH"));
        $$ = res;
    }

    | BY {
        res = new IR(kUnreservedKeyword, string("BY"));
        $$ = res;
    }

    | CACHE {
        res = new IR(kUnreservedKeyword, string("CACHE"));
        $$ = res;
    }

    | CALL {
        res = new IR(kUnreservedKeyword, string("CALL"));
        $$ = res;
    }

    | CALLED {
        res = new IR(kUnreservedKeyword, string("CALLED"));
        $$ = res;
    }

    | CASCADE {
        res = new IR(kUnreservedKeyword, string("CASCADE"));
        $$ = res;
    }

    | CASCADED {
        res = new IR(kUnreservedKeyword, string("CASCADED"));
        $$ = res;
    }

    | CATALOG_P {
        res = new IR(kUnreservedKeyword, string("CATALOG"));
        $$ = res;
    }

    | CHAIN {
        res = new IR(kUnreservedKeyword, string("CHAIN"));
        $$ = res;
    }

    | CHARACTERISTICS {
        res = new IR(kUnreservedKeyword, string("CHARACTERISTICS"));
        $$ = res;
    }

    | CHECKPOINT {
        res = new IR(kUnreservedKeyword, string("CHECKPOINT"));
        $$ = res;
    }

    | CLASS {
        res = new IR(kUnreservedKeyword, string("CLASS"));
        $$ = res;
    }

    | CLOSE {
        res = new IR(kUnreservedKeyword, string("CLOSE"));
        $$ = res;
    }

    | CLUSTER {
        res = new IR(kUnreservedKeyword, string("CLUSTER"));
        $$ = res;
    }

    | COLUMNS {
        res = new IR(kUnreservedKeyword, string("COLUMNS"));
        $$ = res;
    }

    | COMMENT {
        res = new IR(kUnreservedKeyword, string("COMMENT"));
        $$ = res;
    }

    | COMMENTS {
        res = new IR(kUnreservedKeyword, string("COMMENTS"));
        $$ = res;
    }

    | COMMIT {
        res = new IR(kUnreservedKeyword, string("COMMIT"));
        $$ = res;
    }

    | COMMITTED {
        res = new IR(kUnreservedKeyword, string("COMMITTED"));
        $$ = res;
    }

    | COMPRESSION {
        res = new IR(kUnreservedKeyword, string("COMPRESSION"));
        $$ = res;
    }

    | CONFIGURATION {
        res = new IR(kUnreservedKeyword, string("CONFIGURATION"));
        $$ = res;
    }

    | CONFLICT {
        res = new IR(kUnreservedKeyword, string("CONFLICT"));
        $$ = res;
    }

    | CONNECTION {
        res = new IR(kUnreservedKeyword, string("CONNECTION"));
        $$ = res;
    }

    | CONSTRAINTS {
        res = new IR(kUnreservedKeyword, string("CONSTRAINTS"));
        $$ = res;
    }

    | CONTENT_P {
        res = new IR(kUnreservedKeyword, string("CONTENT"));
        $$ = res;
    }

    | CONTINUE_P {
        res = new IR(kUnreservedKeyword, string("CONTINUE"));
        $$ = res;
    }

    | CONVERSION_P {
        res = new IR(kUnreservedKeyword, string("CONVERSION"));
        $$ = res;
    }

    | COPY {
        res = new IR(kUnreservedKeyword, string("COPY"));
        $$ = res;
    }

    | COST {
        res = new IR(kUnreservedKeyword, string("COST"));
        $$ = res;
    }

    | CSV {
        res = new IR(kUnreservedKeyword, string("CSV"));
        $$ = res;
    }

    | CUBE {
        res = new IR(kUnreservedKeyword, string("CUBE"));
        $$ = res;
    }

    | CURRENT_P {
        res = new IR(kUnreservedKeyword, string("CURRENT"));
        $$ = res;
    }

    | CURSOR {
        res = new IR(kUnreservedKeyword, string("CURSOR"));
        $$ = res;
    }

    | CYCLE {
        res = new IR(kUnreservedKeyword, string("CYCLE"));
        $$ = res;
    }

    | DATA_P {
        res = new IR(kUnreservedKeyword, string("DATA"));
        $$ = res;
    }

    | DATABASE {
        res = new IR(kUnreservedKeyword, string("DATABASE"));
        $$ = res;
    }

    | DAY_P {
        res = new IR(kUnreservedKeyword, string("DAY"));
        $$ = res;
    }

    | DEALLOCATE {
        res = new IR(kUnreservedKeyword, string("DEALLOCATE"));
        $$ = res;
    }

    | DECLARE {
        res = new IR(kUnreservedKeyword, string("DECLARE"));
        $$ = res;
    }

    | DEFAULTS {
        res = new IR(kUnreservedKeyword, string("DEFAULTS"));
        $$ = res;
    }

    | DEFERRED {
        res = new IR(kUnreservedKeyword, string("DEFERRED"));
        $$ = res;
    }

    | DEFINER {
        res = new IR(kUnreservedKeyword, string("DEFINER"));
        $$ = res;
    }

    | DELETE_P {
        res = new IR(kUnreservedKeyword, string("DELETE"));
        $$ = res;
    }

    | DELIMITER {
        res = new IR(kUnreservedKeyword, string("DELIMITER"));
        $$ = res;
    }

    | DELIMITERS {
        res = new IR(kUnreservedKeyword, string("DELIMITERS"));
        $$ = res;
    }

    | DEPENDS {
        res = new IR(kUnreservedKeyword, string("DEPENDS"));
        $$ = res;
    }

    | DEPTH {
        res = new IR(kUnreservedKeyword, string("DEPTH"));
        $$ = res;
    }

    | DETACH {
        res = new IR(kUnreservedKeyword, string("DETACH"));
        $$ = res;
    }

    | DICTIONARY {
        res = new IR(kUnreservedKeyword, string("DICTIONARY"));
        $$ = res;
    }

    | DISABLE_P {
        res = new IR(kUnreservedKeyword, string("DISABLE"));
        $$ = res;
    }

    | DISCARD {
        res = new IR(kUnreservedKeyword, string("DISCARD"));
        $$ = res;
    }

    | DOCUMENT_P {
        res = new IR(kUnreservedKeyword, string("DOCUMENT"));
        $$ = res;
    }

    | DOMAIN_P {
        res = new IR(kUnreservedKeyword, string("DOMAIN"));
        $$ = res;
    }

    | DOUBLE_P {
        res = new IR(kUnreservedKeyword, string("DOUBLE"));
        $$ = res;
    }

    | DROP {
        res = new IR(kUnreservedKeyword, string("DROP"));
        $$ = res;
    }

    | EACH {
        res = new IR(kUnreservedKeyword, string("EACH"));
        $$ = res;
    }

    | ENABLE_P {
        res = new IR(kUnreservedKeyword, string("ENABLE"));
        $$ = res;
    }

    | ENCODING {
        res = new IR(kUnreservedKeyword, string("ENCODING"));
        $$ = res;
    }

    | ENCRYPTED {
        res = new IR(kUnreservedKeyword, string("ENCRYPTED"));
        $$ = res;
    }

    | ENUM_P {
        res = new IR(kUnreservedKeyword, string("ENUM"));
        $$ = res;
    }

    | ESCAPE {
        res = new IR(kUnreservedKeyword, string("ESCAPE"));
        $$ = res;
    }

    | EVENT {
        res = new IR(kUnreservedKeyword, string("EVENT"));
        $$ = res;
    }

    | EXCLUDE {
        res = new IR(kUnreservedKeyword, string("EXCLUDE"));
        $$ = res;
    }

    | EXCLUDING {
        res = new IR(kUnreservedKeyword, string("EXCLUDING"));
        $$ = res;
    }

    | EXCLUSIVE {
        res = new IR(kUnreservedKeyword, string("EXCLUSIVE"));
        $$ = res;
    }

    | EXECUTE {
        res = new IR(kUnreservedKeyword, string("EXECUTE"));
        $$ = res;
    }

    | EXPLAIN {
        res = new IR(kUnreservedKeyword, string("EXPLAIN"));
        $$ = res;
    }

    | EXPRESSION {
        res = new IR(kUnreservedKeyword, string("EXPRESSION"));
        $$ = res;
    }

    | EXTENSION {
        res = new IR(kUnreservedKeyword, string("EXTENSION"));
        $$ = res;
    }

    | EXTERNAL {
        res = new IR(kUnreservedKeyword, string("EXTERNAL"));
        $$ = res;
    }

    | FAMILY {
        res = new IR(kUnreservedKeyword, string("FAMILY"));
        $$ = res;
    }

    | FILTER {
        res = new IR(kUnreservedKeyword, string("FILTER"));
        $$ = res;
    }

    | FINALIZE {
        res = new IR(kUnreservedKeyword, string("FINALIZE"));
        $$ = res;
    }

    | FIRST_P {
        res = new IR(kUnreservedKeyword, string("FIRST"));
        $$ = res;
    }

    | FOLLOWING {
        res = new IR(kUnreservedKeyword, string("FOLLOWING"));
        $$ = res;
    }

    | FORCE {
        res = new IR(kUnreservedKeyword, string("FORCE"));
        $$ = res;
    }

    | FORWARD {
        res = new IR(kUnreservedKeyword, string("FORWARD"));
        $$ = res;
    }

    | FUNCTION {
        res = new IR(kUnreservedKeyword, string("FUNCTION"));
        $$ = res;
    }

    | FUNCTIONS {
        res = new IR(kUnreservedKeyword, string("FUNCTIONS"));
        $$ = res;
    }

    | GENERATED {
        res = new IR(kUnreservedKeyword, string("GENERATED"));
        $$ = res;
    }

    | GLOBAL {
        res = new IR(kUnreservedKeyword, string("GLOBAL"));
        $$ = res;
    }

    | GRANTED {
        res = new IR(kUnreservedKeyword, string("GRANTED"));
        $$ = res;
    }

    | GROUPS {
        res = new IR(kUnreservedKeyword, string("GROUPS"));
        $$ = res;
    }

    | HANDLER {
        res = new IR(kUnreservedKeyword, string("HANDLER"));
        $$ = res;
    }

    | HEADER_P {
        res = new IR(kUnreservedKeyword, string("HEADER"));
        $$ = res;
    }

    | HOLD {
        res = new IR(kUnreservedKeyword, string("HOLD"));
        $$ = res;
    }

    | HOUR_P {
        res = new IR(kUnreservedKeyword, string("HOUR"));
        $$ = res;
    }

    | IDENTITY_P {
        res = new IR(kUnreservedKeyword, string("IDENTITY"));
        $$ = res;
    }

    | IF_P {
        res = new IR(kUnreservedKeyword, string("IF"));
        $$ = res;
    }

    | IMMEDIATE {
        res = new IR(kUnreservedKeyword, string("IMMEDIATE"));
        $$ = res;
    }

    | IMMUTABLE {
        res = new IR(kUnreservedKeyword, string("IMMUTABLE"));
        $$ = res;
    }

    | IMPLICIT_P {
        res = new IR(kUnreservedKeyword, string("IMPLICIT"));
        $$ = res;
    }

    | IMPORT_P {
        res = new IR(kUnreservedKeyword, string("IMPORT"));
        $$ = res;
    }

    | INCLUDE {
        res = new IR(kUnreservedKeyword, string("INCLUDE"));
        $$ = res;
    }

    | INCLUDING {
        res = new IR(kUnreservedKeyword, string("INCLUDING"));
        $$ = res;
    }

    | INCREMENT {
        res = new IR(kUnreservedKeyword, string("INCREMENT"));
        $$ = res;
    }

    | INDEX {
        res = new IR(kUnreservedKeyword, string("INDEX"));
        $$ = res;
    }

    | INDEXES {
        res = new IR(kUnreservedKeyword, string("INDEXES"));
        $$ = res;
    }

    | INHERIT {
        res = new IR(kUnreservedKeyword, string("INHERIT"));
        $$ = res;
    }

    | INHERITS {
        res = new IR(kUnreservedKeyword, string("INHERITS"));
        $$ = res;
    }

    | INLINE_P {
        res = new IR(kUnreservedKeyword, string("INLINE"));
        $$ = res;
    }

    | INPUT_P {
        res = new IR(kUnreservedKeyword, string("INPUT"));
        $$ = res;
    }

    | INSENSITIVE {
        res = new IR(kUnreservedKeyword, string("INSENSITIVE"));
        $$ = res;
    }

    | INSERT {
        res = new IR(kUnreservedKeyword, string("INSERT"));
        $$ = res;
    }

    | INSTEAD {
        res = new IR(kUnreservedKeyword, string("INSTEAD"));
        $$ = res;
    }

    | INVOKER {
        res = new IR(kUnreservedKeyword, string("INVOKER"));
        $$ = res;
    }

    | ISOLATION {
        res = new IR(kUnreservedKeyword, string("ISOLATION"));
        $$ = res;
    }

    | KEY {
        res = new IR(kUnreservedKeyword, string("KEY"));
        $$ = res;
    }

    | LABEL {
        res = new IR(kUnreservedKeyword, string("LABEL"));
        $$ = res;
    }

    | LANGUAGE {
        res = new IR(kUnreservedKeyword, string("LANGUAGE"));
        $$ = res;
    }

    | LARGE_P {
        res = new IR(kUnreservedKeyword, string("LARGE"));
        $$ = res;
    }

    | LAST_P {
        res = new IR(kUnreservedKeyword, string("LAST"));
        $$ = res;
    }

    | LEAKPROOF {
        res = new IR(kUnreservedKeyword, string("LEAKPROOF"));
        $$ = res;
    }

    | LEVEL {
        res = new IR(kUnreservedKeyword, string("LEVEL"));
        $$ = res;
    }

    | LISTEN {
        res = new IR(kUnreservedKeyword, string("LISTEN"));
        $$ = res;
    }

    | LOAD {
        res = new IR(kUnreservedKeyword, string("LOAD"));
        $$ = res;
    }

    | LOCAL {
        res = new IR(kUnreservedKeyword, string("LOCAL"));
        $$ = res;
    }

    | LOCATION {
        res = new IR(kUnreservedKeyword, string("LOCATION"));
        $$ = res;
    }

    | LOCK_P {
        res = new IR(kUnreservedKeyword, string("LOCK"));
        $$ = res;
    }

    | LOCKED {
        res = new IR(kUnreservedKeyword, string("LOCKED"));
        $$ = res;
    }

    | LOGGED {
        res = new IR(kUnreservedKeyword, string("LOGGED"));
        $$ = res;
    }

    | MAPPING {
        res = new IR(kUnreservedKeyword, string("MAPPING"));
        $$ = res;
    }

    | MATCH {
        res = new IR(kUnreservedKeyword, string("MATCH"));
        $$ = res;
    }

    | MATERIALIZED {
        res = new IR(kUnreservedKeyword, string("MATERIALIZED"));
        $$ = res;
    }

    | MAXVALUE {
        res = new IR(kUnreservedKeyword, string("MAXVALUE"));
        $$ = res;
    }

    | METHOD {
        res = new IR(kUnreservedKeyword, string("METHOD"));
        $$ = res;
    }

    | MINUTE_P {
        res = new IR(kUnreservedKeyword, string("MINUTE"));
        $$ = res;
    }

    | MINVALUE {
        res = new IR(kUnreservedKeyword, string("MINVALUE"));
        $$ = res;
    }

    | MODE {
        res = new IR(kUnreservedKeyword, string("MODE"));
        $$ = res;
    }

    | MONTH_P {
        res = new IR(kUnreservedKeyword, string("MONTH"));
        $$ = res;
    }

    | MOVE {
        res = new IR(kUnreservedKeyword, string("MOVE"));
        $$ = res;
    }

    | NAME_P {
        res = new IR(kUnreservedKeyword, string("NAME"));
        $$ = res;
    }

    | NAMES {
        res = new IR(kUnreservedKeyword, string("NAMES"));
        $$ = res;
    }

    | NEW {
        res = new IR(kUnreservedKeyword, string("NEW"));
        $$ = res;
    }

    | NEXT {
        res = new IR(kUnreservedKeyword, string("NEXT"));
        $$ = res;
    }

    | NFC {
        res = new IR(kUnreservedKeyword, string("NFC"));
        $$ = res;
    }

    | NFD {
        res = new IR(kUnreservedKeyword, string("NFD"));
        $$ = res;
    }

    | NFKC {
        res = new IR(kUnreservedKeyword, string("NFKC"));
        $$ = res;
    }

    | NFKD {
        res = new IR(kUnreservedKeyword, string("NFKD"));
        $$ = res;
    }

    | NO {
        res = new IR(kUnreservedKeyword, string("NO"));
        $$ = res;
    }

    | NORMALIZED {
        res = new IR(kUnreservedKeyword, string("NORMALIZED"));
        $$ = res;
    }

    | NOTHING {
        res = new IR(kUnreservedKeyword, string("NOTHING"));
        $$ = res;
    }

    | NOTIFY {
        res = new IR(kUnreservedKeyword, string("NOTIFY"));
        $$ = res;
    }

    | NOWAIT {
        res = new IR(kUnreservedKeyword, string("NOWAIT"));
        $$ = res;
    }

    | NULLS_P {
        res = new IR(kUnreservedKeyword, string("NULLS"));
        $$ = res;
    }

    | OBJECT_P {
        res = new IR(kUnreservedKeyword, string("OBJECT"));
        $$ = res;
    }

    | OF {
        res = new IR(kUnreservedKeyword, string("OF"));
        $$ = res;
    }

    | OFF {
        res = new IR(kUnreservedKeyword, string("OFF"));
        $$ = res;
    }

    | OIDS {
        res = new IR(kUnreservedKeyword, string("OIDS"));
        $$ = res;
    }

    | OLD {
        res = new IR(kUnreservedKeyword, string("OLD"));
        $$ = res;
    }

    | OPERATOR {
        res = new IR(kUnreservedKeyword, string("OPERATOR"));
        $$ = res;
    }

    | OPTION {
        res = new IR(kUnreservedKeyword, string("OPTION"));
        $$ = res;
    }

    | OPTIONS {
        res = new IR(kUnreservedKeyword, string("OPTIONS"));
        $$ = res;
    }

    | ORDINALITY {
        res = new IR(kUnreservedKeyword, string("ORDINALITY"));
        $$ = res;
    }

    | OTHERS {
        res = new IR(kUnreservedKeyword, string("OTHERS"));
        $$ = res;
    }

    | OVER {
        res = new IR(kUnreservedKeyword, string("OVER"));
        $$ = res;
    }

    | OVERRIDING {
        res = new IR(kUnreservedKeyword, string("OVERRIDING"));
        $$ = res;
    }

    | OWNED {
        res = new IR(kUnreservedKeyword, string("OWNED"));
        $$ = res;
    }

    | OWNER {
        res = new IR(kUnreservedKeyword, string("OWNER"));
        $$ = res;
    }

    | PARALLEL {
        res = new IR(kUnreservedKeyword, string("PARALLEL"));
        $$ = res;
    }

    | PARSER {
        res = new IR(kUnreservedKeyword, string("PARSER"));
        $$ = res;
    }

    | PARTIAL {
        res = new IR(kUnreservedKeyword, string("PARTIAL"));
        $$ = res;
    }

    | PARTITION {
        res = new IR(kUnreservedKeyword, string("PARTITION"));
        $$ = res;
    }

    | PASSING {
        res = new IR(kUnreservedKeyword, string("PASSING"));
        $$ = res;
    }

    | PASSWORD {
        res = new IR(kUnreservedKeyword, string("PASSWORD"));
        $$ = res;
    }

    | PLANS {
        res = new IR(kUnreservedKeyword, string("PLANS"));
        $$ = res;
    }

    | POLICY {
        res = new IR(kUnreservedKeyword, string("POLICY"));
        $$ = res;
    }

    | PRECEDING {
        res = new IR(kUnreservedKeyword, string("PRECEDING"));
        $$ = res;
    }

    | PREPARE {
        res = new IR(kUnreservedKeyword, string("PREPARE"));
        $$ = res;
    }

    | PREPARED {
        res = new IR(kUnreservedKeyword, string("PREPARED"));
        $$ = res;
    }

    | PRESERVE {
        res = new IR(kUnreservedKeyword, string("PRESERVE"));
        $$ = res;
    }

    | PRIOR {
        res = new IR(kUnreservedKeyword, string("PRIOR"));
        $$ = res;
    }

    | PRIVILEGES {
        res = new IR(kUnreservedKeyword, string("PRIVILEGES"));
        $$ = res;
    }

    | PROCEDURAL {
        res = new IR(kUnreservedKeyword, string("PROCEDURAL"));
        $$ = res;
    }

    | PROCEDURE {
        res = new IR(kUnreservedKeyword, string("PROCEDURE"));
        $$ = res;
    }

    | PROCEDURES {
        res = new IR(kUnreservedKeyword, string("PROCEDURES"));
        $$ = res;
    }

    | PROGRAM {
        res = new IR(kUnreservedKeyword, string("PROGRAM"));
        $$ = res;
    }

    | PUBLICATION {
        res = new IR(kUnreservedKeyword, string("PUBLICATION"));
        $$ = res;
    }

    | QUOTE {
        res = new IR(kUnreservedKeyword, string("QUOTE"));
        $$ = res;
    }

    | RANGE {
        res = new IR(kUnreservedKeyword, string("RANGE"));
        $$ = res;
    }

    | READ {
        res = new IR(kUnreservedKeyword, string("READ"));
        $$ = res;
    }

    | REASSIGN {
        res = new IR(kUnreservedKeyword, string("REASSIGN"));
        $$ = res;
    }

    | RECHECK {
        res = new IR(kUnreservedKeyword, string("RECHECK"));
        $$ = res;
    }

    | RECURSIVE {
        res = new IR(kUnreservedKeyword, string("RECURSIVE"));
        $$ = res;
    }

    | REF {
        res = new IR(kUnreservedKeyword, string("REF"));
        $$ = res;
    }

    | REFERENCING {
        res = new IR(kUnreservedKeyword, string("REFERENCING"));
        $$ = res;
    }

    | REFRESH {
        res = new IR(kUnreservedKeyword, string("REFRESH"));
        $$ = res;
    }

    | REINDEX {
        res = new IR(kUnreservedKeyword, string("REINDEX"));
        $$ = res;
    }

    | RELATIVE_P {
        res = new IR(kUnreservedKeyword, string("RELATIVE"));
        $$ = res;
    }

    | RELEASE {
        res = new IR(kUnreservedKeyword, string("RELEASE"));
        $$ = res;
    }

    | RENAME {
        res = new IR(kUnreservedKeyword, string("RENAME"));
        $$ = res;
    }

    | REPEATABLE {
        res = new IR(kUnreservedKeyword, string("REPEATABLE"));
        $$ = res;
    }

    | REPLACE {
        res = new IR(kUnreservedKeyword, string("REPLACE"));
        $$ = res;
    }

    | REPLICA {
        res = new IR(kUnreservedKeyword, string("REPLICA"));
        $$ = res;
    }

    | RESET {
        res = new IR(kUnreservedKeyword, string("RESET"));
        $$ = res;
    }

    | RESTART {
        res = new IR(kUnreservedKeyword, string("RESTART"));
        $$ = res;
    }

    | RESTRICT {
        res = new IR(kUnreservedKeyword, string("RESTRICT"));
        $$ = res;
    }

    | RETURN {
        res = new IR(kUnreservedKeyword, string("RETURN"));
        $$ = res;
    }

    | RETURNS {
        res = new IR(kUnreservedKeyword, string("RETURNS"));
        $$ = res;
    }

    | REVOKE {
        res = new IR(kUnreservedKeyword, string("REVOKE"));
        $$ = res;
    }

    | ROLE {
        res = new IR(kUnreservedKeyword, string("ROLE"));
        $$ = res;
    }

    | ROLLBACK {
        res = new IR(kUnreservedKeyword, string("ROLLBACK"));
        $$ = res;
    }

    | ROLLUP {
        res = new IR(kUnreservedKeyword, string("ROLLUP"));
        $$ = res;
    }

    | ROUTINE {
        res = new IR(kUnreservedKeyword, string("ROUTINE"));
        $$ = res;
    }

    | ROUTINES {
        res = new IR(kUnreservedKeyword, string("ROUTINES"));
        $$ = res;
    }

    | ROWS {
        res = new IR(kUnreservedKeyword, string("ROWS"));
        $$ = res;
    }

    | RULE {
        res = new IR(kUnreservedKeyword, string("RULE"));
        $$ = res;
    }

    | SAVEPOINT {
        res = new IR(kUnreservedKeyword, string("SAVEPOINT"));
        $$ = res;
    }

    | SCHEMA {
        res = new IR(kUnreservedKeyword, string("SCHEMA"));
        $$ = res;
    }

    | SCHEMAS {
        res = new IR(kUnreservedKeyword, string("SCHEMAS"));
        $$ = res;
    }

    | SCROLL {
        res = new IR(kUnreservedKeyword, string("SCROLL"));
        $$ = res;
    }

    | SEARCH {
        res = new IR(kUnreservedKeyword, string("SEARCH"));
        $$ = res;
    }

    | SECOND_P {
        res = new IR(kUnreservedKeyword, string("SECOND"));
        $$ = res;
    }

    | SECURITY {
        res = new IR(kUnreservedKeyword, string("SECURITY"));
        $$ = res;
    }

    | SEQUENCE {
        res = new IR(kUnreservedKeyword, string("SEQUENCE"));
        $$ = res;
    }

    | SEQUENCES {
        res = new IR(kUnreservedKeyword, string("SEQUENCES"));
        $$ = res;
    }

    | SERIALIZABLE {
        res = new IR(kUnreservedKeyword, string("SERIALIZABLE"));
        $$ = res;
    }

    | SERVER {
        res = new IR(kUnreservedKeyword, string("SERVER"));
        $$ = res;
    }

    | SESSION {
        res = new IR(kUnreservedKeyword, string("SESSION"));
        $$ = res;
    }

    | SET {
        res = new IR(kUnreservedKeyword, string("SET"));
        $$ = res;
    }

    | SETS {
        res = new IR(kUnreservedKeyword, string("SETS"));
        $$ = res;
    }

    | SHARE {
        res = new IR(kUnreservedKeyword, string("SHARE"));
        $$ = res;
    }

    | SHOW {
        res = new IR(kUnreservedKeyword, string("SHOW"));
        $$ = res;
    }

    | SIMPLE {
        res = new IR(kUnreservedKeyword, string("SIMPLE"));
        $$ = res;
    }

    | SKIP {
        res = new IR(kUnreservedKeyword, string("SKIP"));
        $$ = res;
    }

    | SNAPSHOT {
        res = new IR(kUnreservedKeyword, string("SNAPSHOT"));
        $$ = res;
    }

    | SQL_P {
        res = new IR(kUnreservedKeyword, string("SQL"));
        $$ = res;
    }

    | STABLE {
        res = new IR(kUnreservedKeyword, string("STABLE"));
        $$ = res;
    }

    | STANDALONE_P {
        res = new IR(kUnreservedKeyword, string("STANDALONE"));
        $$ = res;
    }

    | START {
        res = new IR(kUnreservedKeyword, string("START"));
        $$ = res;
    }

    | STATEMENT {
        res = new IR(kUnreservedKeyword, string("STATEMENT"));
        $$ = res;
    }

    | STATISTICS {
        res = new IR(kUnreservedKeyword, string("STATISTICS"));
        $$ = res;
    }

    | STDIN {
        res = new IR(kUnreservedKeyword, string("STDIN"));
        $$ = res;
    }

    | STDOUT {
        res = new IR(kUnreservedKeyword, string("STDOUT"));
        $$ = res;
    }

    | STORAGE {
        res = new IR(kUnreservedKeyword, string("STORAGE"));
        $$ = res;
    }

    | STORED {
        res = new IR(kUnreservedKeyword, string("STORED"));
        $$ = res;
    }

    | STRICT_P {
        res = new IR(kUnreservedKeyword, string("STRICT"));
        $$ = res;
    }

    | STRIP_P {
        res = new IR(kUnreservedKeyword, string("STRIP"));
        $$ = res;
    }

    | SUBSCRIPTION {
        res = new IR(kUnreservedKeyword, string("SUBSCRIPTION"));
        $$ = res;
    }

    | SUPPORT {
        res = new IR(kUnreservedKeyword, string("SUPPORT"));
        $$ = res;
    }

    | SYSID {
        res = new IR(kUnreservedKeyword, string("SYSID"));
        $$ = res;
    }

    | SYSTEM_P {
        res = new IR(kUnreservedKeyword, string("SYSTEM"));
        $$ = res;
    }

    | TABLES {
        res = new IR(kUnreservedKeyword, string("TABLES"));
        $$ = res;
    }

    | TABLESPACE {
        res = new IR(kUnreservedKeyword, string("TABLESPACE"));
        $$ = res;
    }

    | TEMP {
        res = new IR(kUnreservedKeyword, string("TEMP"));
        $$ = res;
    }

    | TEMPLATE {
        res = new IR(kUnreservedKeyword, string("TEMPLATE"));
        $$ = res;
    }

    | TEMPORARY {
        res = new IR(kUnreservedKeyword, string("TEMPORARY"));
        $$ = res;
    }

    | TEXT_P {
        res = new IR(kUnreservedKeyword, string("TEXT"));
        $$ = res;
    }

    | TIES {
        res = new IR(kUnreservedKeyword, string("TIES"));
        $$ = res;
    }

    | TRANSACTION {
        res = new IR(kUnreservedKeyword, string("TRANSACTION"));
        $$ = res;
    }

    | TRANSFORM {
        res = new IR(kUnreservedKeyword, string("TRANSFORM"));
        $$ = res;
    }

    | TRIGGER {
        res = new IR(kUnreservedKeyword, string("TRIGGER"));
        $$ = res;
    }

    | TRUNCATE {
        res = new IR(kUnreservedKeyword, string("TRUNCATE"));
        $$ = res;
    }

    | TRUSTED {
        res = new IR(kUnreservedKeyword, string("TRUSTED"));
        $$ = res;
    }

    | TYPE_P {
        res = new IR(kUnreservedKeyword, string("TYPE"));
        $$ = res;
    }

    | TYPES_P {
        res = new IR(kUnreservedKeyword, string("TYPES"));
        $$ = res;
    }

    | UESCAPE {
        res = new IR(kUnreservedKeyword, string("UESCAPE"));
        $$ = res;
    }

    | UNBOUNDED {
        res = new IR(kUnreservedKeyword, string("UNBOUNDED"));
        $$ = res;
    }

    | UNCOMMITTED {
        res = new IR(kUnreservedKeyword, string("UNCOMMITTED"));
        $$ = res;
    }

    | UNENCRYPTED {
        res = new IR(kUnreservedKeyword, string("UNENCRYPTED"));
        $$ = res;
    }

    | UNKNOWN {
        res = new IR(kUnreservedKeyword, string("UNKNOWN"));
        $$ = res;
    }

    | UNLISTEN {
        res = new IR(kUnreservedKeyword, string("UNLISTEN"));
        $$ = res;
    }

    | UNLOGGED {
        res = new IR(kUnreservedKeyword, string("UNLOGGED"));
        $$ = res;
    }

    | UNTIL {
        res = new IR(kUnreservedKeyword, string("UNTIL"));
        $$ = res;
    }

    | UPDATE {
        res = new IR(kUnreservedKeyword, string("UPDATE"));
        $$ = res;
    }

    | VACUUM {
        res = new IR(kUnreservedKeyword, string("VACUUM"));
        $$ = res;
    }

    | VALID {
        res = new IR(kUnreservedKeyword, string("VALID"));
        $$ = res;
    }

    | VALIDATE {
        res = new IR(kUnreservedKeyword, string("VALIDATE"));
        $$ = res;
    }

    | VALIDATOR {
        res = new IR(kUnreservedKeyword, string("VALIDATOR"));
        $$ = res;
    }

    | VALUE_P {
        res = new IR(kUnreservedKeyword, string("VALUE"));
        $$ = res;
    }

    | VARYING {
        res = new IR(kUnreservedKeyword, string("VARYING"));
        $$ = res;
    }

    | VERSION_P {
        res = new IR(kUnreservedKeyword, string("VERSION"));
        $$ = res;
    }

    | VIEW {
        res = new IR(kUnreservedKeyword, string("VIEW"));
        $$ = res;
    }

    | VIEWS {
        res = new IR(kUnreservedKeyword, string("VIEWS"));
        $$ = res;
    }

    | VOLATILE {
        res = new IR(kUnreservedKeyword, string("VOLATILE"));
        $$ = res;
    }

    | WHITESPACE_P {
        res = new IR(kUnreservedKeyword, string("WHITESPACE"));
        $$ = res;
    }

    | WITHIN {
        res = new IR(kUnreservedKeyword, string("WITHIN"));
        $$ = res;
    }

    | WITHOUT {
        res = new IR(kUnreservedKeyword, string("WITHOUT"));
        $$ = res;
    }

    | WORK {
        res = new IR(kUnreservedKeyword, string("WORK"));
        $$ = res;
    }

    | WRAPPER {
        res = new IR(kUnreservedKeyword, string("WRAPPER"));
        $$ = res;
    }

    | WRITE {
        res = new IR(kUnreservedKeyword, string("WRITE"));
        $$ = res;
    }

    | XML_P {
        res = new IR(kUnreservedKeyword, string("XML"));
        $$ = res;
    }

    | YEAR_P {
        res = new IR(kUnreservedKeyword, string("YEAR"));
        $$ = res;
    }

    | YES_P {
        res = new IR(kUnreservedKeyword, string("YES"));
        $$ = res;
    }

    | ZONE {
        res = new IR(kUnreservedKeyword, string("ZONE"));
        $$ = res;
    }

;

/* Column identifier --- keywords that can be column, table, etc names.
*
* Many of these keywords will in fact be recognized as type or function
* names too; but they have special productions for the purpose, and so
* can't be treated as "generic" type or function names.
*
* The type names appearing here are not usable as function names
* because they can be followed by '(' in typename productions, which
* looks too much like a function call for an LR(1) parser.
*/

col_name_keyword:

    BETWEEN {
        res = new IR(kColNameKeyword, string("BETWEEN"));
        $$ = res;
    }

    | BIGINT {
        res = new IR(kColNameKeyword, string("BIGINT"));
        $$ = res;
    }

    | BIT {
        res = new IR(kColNameKeyword, string("BIT"));
        $$ = res;
    }

    | BOOLEAN_P {
        res = new IR(kColNameKeyword, string("BOOLEAN"));
        $$ = res;
    }

    | CHAR_P {
        res = new IR(kColNameKeyword, string("CHAR"));
        $$ = res;
    }

    | CHARACTER {
        res = new IR(kColNameKeyword, string("CHARACTER"));
        $$ = res;
    }

    | COALESCE {
        res = new IR(kColNameKeyword, string("COALESCE"));
        $$ = res;
    }

    | DEC {
        res = new IR(kColNameKeyword, string("DEC"));
        $$ = res;
    }

    | DECIMAL_P {
        res = new IR(kColNameKeyword, string("DECIMAL"));
        $$ = res;
    }

    | EXISTS {
        res = new IR(kColNameKeyword, string("EXISTS"));
        $$ = res;
    }

    | EXTRACT {
        res = new IR(kColNameKeyword, string("EXTRACT"));
        $$ = res;
    }

    | FLOAT_P {
        res = new IR(kColNameKeyword, string("FLOAT"));
        $$ = res;
    }

    | GREATEST {
        res = new IR(kColNameKeyword, string("GREATEST"));
        $$ = res;
    }

    | GROUPING {
        res = new IR(kColNameKeyword, string("GROUPING"));
        $$ = res;
    }

    | INOUT {
        res = new IR(kColNameKeyword, string("INOUT"));
        $$ = res;
    }

    | INT_P {
        res = new IR(kColNameKeyword, string("INT"));
        $$ = res;
    }

    | INTEGER {
        res = new IR(kColNameKeyword, string("INTEGER"));
        $$ = res;
    }

    | INTERVAL {
        res = new IR(kColNameKeyword, string("INTERVAL"));
        $$ = res;
    }

    | LEAST {
        res = new IR(kColNameKeyword, string("LEAST"));
        $$ = res;
    }

    | NATIONAL {
        res = new IR(kColNameKeyword, string("NATIONAL"));
        $$ = res;
    }

    | NCHAR {
        res = new IR(kColNameKeyword, string("NCHAR"));
        $$ = res;
    }

    | NONE {
        res = new IR(kColNameKeyword, string("NONE"));
        $$ = res;
    }

    | NORMALIZE {
        res = new IR(kColNameKeyword, string("NORMALIZE"));
        $$ = res;
    }

    | NULLIF {
        res = new IR(kColNameKeyword, string("NULLIF"));
        $$ = res;
    }

    | NUMERIC {
        res = new IR(kColNameKeyword, string("NUMERIC"));
        $$ = res;
    }

    | OUT_P {
        res = new IR(kColNameKeyword, string("OUT"));
        $$ = res;
    }

    | OVERLAY {
        res = new IR(kColNameKeyword, string("OVERLAY"));
        $$ = res;
    }

    | POSITION {
        res = new IR(kColNameKeyword, string("POSITION"));
        $$ = res;
    }

    | PRECISION {
        res = new IR(kColNameKeyword, string("PRECISION"));
        $$ = res;
    }

    | REAL {
        res = new IR(kColNameKeyword, string("REAL"));
        $$ = res;
    }

    | ROW {
        res = new IR(kColNameKeyword, string("ROW"));
        $$ = res;
    }

    | SETOF {
        res = new IR(kColNameKeyword, string("SETOF"));
        $$ = res;
    }

    | SMALLINT {
        res = new IR(kColNameKeyword, string("SMALLINT"));
        $$ = res;
    }

    | SUBSTRING {
        res = new IR(kColNameKeyword, string("SUBSTRING"));
        $$ = res;
    }

    | TIME {
        res = new IR(kColNameKeyword, string("TIME"));
        $$ = res;
    }

    | TIMESTAMP {
        res = new IR(kColNameKeyword, string("TIMESTAMP"));
        $$ = res;
    }

    | TREAT {
        res = new IR(kColNameKeyword, string("TREAT"));
        $$ = res;
    }

    | TRIM {
        res = new IR(kColNameKeyword, string("TRIM"));
        $$ = res;
    }

    | VALUES {
        res = new IR(kColNameKeyword, string("VALUES"));
        $$ = res;
    }

    | VARCHAR {
        res = new IR(kColNameKeyword, string("VARCHAR"));
        $$ = res;
    }

    | XMLATTRIBUTES {
        res = new IR(kColNameKeyword, string("XMLATTRIBUTES"));
        $$ = res;
    }

    | XMLCONCAT {
        res = new IR(kColNameKeyword, string("XMLCONCAT"));
        $$ = res;
    }

    | XMLELEMENT {
        res = new IR(kColNameKeyword, string("XMLELEMENT"));
        $$ = res;
    }

    | XMLEXISTS {
        res = new IR(kColNameKeyword, string("XMLEXISTS"));
        $$ = res;
    }

    | XMLFOREST {
        res = new IR(kColNameKeyword, string("XMLFOREST"));
        $$ = res;
    }

    | XMLNAMESPACES {
        res = new IR(kColNameKeyword, string("XMLNAMESPACES"));
        $$ = res;
    }

    | XMLPARSE {
        res = new IR(kColNameKeyword, string("XMLPARSE"));
        $$ = res;
    }

    | XMLPI {
        res = new IR(kColNameKeyword, string("XMLPI"));
        $$ = res;
    }

    | XMLROOT {
        res = new IR(kColNameKeyword, string("XMLROOT"));
        $$ = res;
    }

    | XMLSERIALIZE {
        res = new IR(kColNameKeyword, string("XMLSERIALIZE"));
        $$ = res;
    }

    | XMLTABLE {
        res = new IR(kColNameKeyword, string("XMLTABLE"));
        $$ = res;
    }

;

/* Type/function identifier --- keywords that can be type or function names.
*
* Most of these are keywords that are used as operators in expressions;
* in general such keywords can't be column names because they would be
* ambiguous with variables, but they are unambiguous as function identifiers.
*
* Do not include POSITION, SUBSTRING, etc here since they have explicit
* productions in a_expr to support the goofy SQL9x argument syntax.
* - thomas 2000-11-28
*/

type_func_name_keyword:

    AUTHORIZATION {
        res = new IR(kTypeFuncNameKeyword, string("AUTHORIZATION"));
        $$ = res;
    }

    | BINARY {
        res = new IR(kTypeFuncNameKeyword, string("BINARY"));
        $$ = res;
    }

    | COLLATION {
        res = new IR(kTypeFuncNameKeyword, string("COLLATION"));
        $$ = res;
    }

    | CONCURRENTLY {
        res = new IR(kTypeFuncNameKeyword, string("CONCURRENTLY"));
        $$ = res;
    }

    | CROSS {
        res = new IR(kTypeFuncNameKeyword, string("CROSS"));
        $$ = res;
    }

    | CURRENT_SCHEMA {
        res = new IR(kTypeFuncNameKeyword, string("CURRENT_SCHEMA"));
        $$ = res;
    }

    | FREEZE {
        res = new IR(kTypeFuncNameKeyword, string("FREEZE"));
        $$ = res;
    }

    | FULL {
        res = new IR(kTypeFuncNameKeyword, string("FULL"));
        $$ = res;
    }

    | ILIKE {
        res = new IR(kTypeFuncNameKeyword, string("ILIKE"));
        $$ = res;
    }

    | INNER_P {
        res = new IR(kTypeFuncNameKeyword, string("INNER"));
        $$ = res;
    }

    | IS {
        res = new IR(kTypeFuncNameKeyword, string("IS"));
        $$ = res;
    }

    | ISNULL {
        res = new IR(kTypeFuncNameKeyword, string("ISNULL"));
        $$ = res;
    }

    | JOIN {
        res = new IR(kTypeFuncNameKeyword, string("JOIN"));
        $$ = res;
    }

    | LEFT {
        res = new IR(kTypeFuncNameKeyword, string("LEFT"));
        $$ = res;
    }

    | LIKE {
        res = new IR(kTypeFuncNameKeyword, string("LIKE"));
        $$ = res;
    }

    | NATURAL {
        res = new IR(kTypeFuncNameKeyword, string("NATURAL"));
        $$ = res;
    }

    | NOTNULL {
        res = new IR(kTypeFuncNameKeyword, string("NOTNULL"));
        $$ = res;
    }

    | OUTER_P {
        res = new IR(kTypeFuncNameKeyword, string("OUTER"));
        $$ = res;
    }

    | OVERLAPS {
        res = new IR(kTypeFuncNameKeyword, string("OVERLAPS"));
        $$ = res;
    }

    | RIGHT {
        res = new IR(kTypeFuncNameKeyword, string("RIGHT"));
        $$ = res;
    }

    | SIMILAR {
        res = new IR(kTypeFuncNameKeyword, string("SIMILAR"));
        $$ = res;
    }

    | TABLESAMPLE {
        res = new IR(kTypeFuncNameKeyword, string("TABLESAMPLE"));
        $$ = res;
    }

    | VERBOSE {
        res = new IR(kTypeFuncNameKeyword, string("VERBOSE"));
        $$ = res;
    }

;

/* Reserved keyword --- these keywords are usable only as a ColLabel.
*
* Keywords appear here if they could not be distinguished from variable,
* type, or function names in some contexts.  Don't put things here unless
* forced to.
*/

reserved_keyword:

    ALL {
        res = new IR(kReservedKeyword, string("ALL"));
        $$ = res;
    }

    | ANALYSE {
        res = new IR(kReservedKeyword, string("ANALYSE"));
        $$ = res;
    }

    | ANALYZE {
        res = new IR(kReservedKeyword, string("ANALYZE"));
        $$ = res;
    }

    | AND {
        res = new IR(kReservedKeyword, string("AND"));
        $$ = res;
    }

    | ANY {
        res = new IR(kReservedKeyword, string("ANY"));
        $$ = res;
    }

    | ARRAY {
        res = new IR(kReservedKeyword, string("ARRAY"));
        $$ = res;
    }

    | AS {
        res = new IR(kReservedKeyword, string("AS"));
        $$ = res;
    }

    | ASC {
        res = new IR(kReservedKeyword, string("ASC"));
        $$ = res;
    }

    | ASYMMETRIC {
        res = new IR(kReservedKeyword, string("ASYMMETRIC"));
        $$ = res;
    }

    | BOTH {
        res = new IR(kReservedKeyword, string("BOTH"));
        $$ = res;
    }

    | CASE {
        res = new IR(kReservedKeyword, string("CASE"));
        $$ = res;
    }

    | CAST {
        res = new IR(kReservedKeyword, string("CAST"));
        $$ = res;
    }

    | CHECK {
        res = new IR(kReservedKeyword, string("CHECK"));
        $$ = res;
    }

    | COLLATE {
        res = new IR(kReservedKeyword, string("COLLATE"));
        $$ = res;
    }

    | COLUMN {
        res = new IR(kReservedKeyword, string("COLUMN"));
        $$ = res;
    }

    | CONSTRAINT {
        res = new IR(kReservedKeyword, string("CONSTRAINT"));
        $$ = res;
    }

    | CREATE {
        res = new IR(kReservedKeyword, string("CREATE"));
        $$ = res;
    }

    | CURRENT_CATALOG {
        res = new IR(kReservedKeyword, string("CURRENT_CATALOG"));
        $$ = res;
    }

    | CURRENT_DATE {
        res = new IR(kReservedKeyword, string("CURRENT_DATE"));
        $$ = res;
    }

    | CURRENT_ROLE {
        res = new IR(kReservedKeyword, string("CURRENT_ROLE"));
        $$ = res;
    }

    | CURRENT_TIME {
        res = new IR(kReservedKeyword, string("CURRENT_TIME"));
        $$ = res;
    }

    | CURRENT_TIMESTAMP {
        res = new IR(kReservedKeyword, string("CURRENT_TIMESTAMP"));
        $$ = res;
    }

    | CURRENT_USER {
        res = new IR(kReservedKeyword, string("CURRENT_USER"));
        $$ = res;
    }

    | DEFAULT {
        res = new IR(kReservedKeyword, string("DEFAULT"));
        $$ = res;
    }

    | DEFERRABLE {
        res = new IR(kReservedKeyword, string("DEFERRABLE"));
        $$ = res;
    }

    | DESC {
        res = new IR(kReservedKeyword, string("DESC"));
        $$ = res;
    }

    | DISTINCT {
        res = new IR(kReservedKeyword, string("DISTINCT"));
        $$ = res;
    }

    | DO {
        res = new IR(kReservedKeyword, string("DO"));
        $$ = res;
    }

    | ELSE {
        res = new IR(kReservedKeyword, string("ELSE"));
        $$ = res;
    }

    | END_P {
        res = new IR(kReservedKeyword, string("END"));
        $$ = res;
    }

    | EXCEPT {
        res = new IR(kReservedKeyword, string("EXCEPT"));
        $$ = res;
    }

    | FALSE_P {
        res = new IR(kReservedKeyword, string("FALSE"));
        $$ = res;
    }

    | FETCH {
        res = new IR(kReservedKeyword, string("FETCH"));
        $$ = res;
    }

    | FOR {
        res = new IR(kReservedKeyword, string("FOR"));
        $$ = res;
    }

    | FOREIGN {
        res = new IR(kReservedKeyword, string("FOREIGN"));
        $$ = res;
    }

    | FROM {
        res = new IR(kReservedKeyword, string("FROM"));
        $$ = res;
    }

    | GRANT {
        res = new IR(kReservedKeyword, string("GRANT"));
        $$ = res;
    }

    | GROUP_P {
        res = new IR(kReservedKeyword, string("GROUP"));
        $$ = res;
    }

    | HAVING {
        res = new IR(kReservedKeyword, string("HAVING"));
        $$ = res;
    }

    | IN_P {
        res = new IR(kReservedKeyword, string("IN"));
        $$ = res;
    }

    | INITIALLY {
        res = new IR(kReservedKeyword, string("INITIALLY"));
        $$ = res;
    }

    | INTERSECT {
        res = new IR(kReservedKeyword, string("INTERSECT"));
        $$ = res;
    }

    | INTO {
        res = new IR(kReservedKeyword, string("INTO"));
        $$ = res;
    }

    | LATERAL_P {
        res = new IR(kReservedKeyword, string("LATERAL"));
        $$ = res;
    }

    | LEADING {
        res = new IR(kReservedKeyword, string("LEADING"));
        $$ = res;
    }

    | LIMIT {
        res = new IR(kReservedKeyword, string("LIMIT"));
        $$ = res;
    }

    | LOCALTIME {
        res = new IR(kReservedKeyword, string("LOCALTIME"));
        $$ = res;
    }

    | LOCALTIMESTAMP {
        res = new IR(kReservedKeyword, string("LOCALTIMESTAMP"));
        $$ = res;
    }

    | NOT {
        res = new IR(kReservedKeyword, string("NOT"));
        $$ = res;
    }

    | NULL_P {
        res = new IR(kReservedKeyword, string("NULL"));
        $$ = res;
    }

    | OFFSET {
        res = new IR(kReservedKeyword, string("OFFSET"));
        $$ = res;
    }

    | ON {
        res = new IR(kReservedKeyword, string("ON"));
        $$ = res;
    }

    | ONLY {
        res = new IR(kReservedKeyword, string("ONLY"));
        $$ = res;
    }

    | OR {
        res = new IR(kReservedKeyword, string("OR"));
        $$ = res;
    }

    | ORDER {
        res = new IR(kReservedKeyword, string("ORDER"));
        $$ = res;
    }

    | PLACING {
        res = new IR(kReservedKeyword, string("PLACING"));
        $$ = res;
    }

    | PRIMARY {
        res = new IR(kReservedKeyword, string("PRIMARY"));
        $$ = res;
    }

    | REFERENCES {
        res = new IR(kReservedKeyword, string("REFERENCES"));
        $$ = res;
    }

    | RETURNING {
        res = new IR(kReservedKeyword, string("RETURNING"));
        $$ = res;
    }

    | SELECT {
        res = new IR(kReservedKeyword, string("SELECT"));
        $$ = res;
    }

    | SESSION_USER {
        res = new IR(kReservedKeyword, string("SESSION_USER"));
        $$ = res;
    }

    | SOME {
        res = new IR(kReservedKeyword, string("SOME"));
        $$ = res;
    }

    | SYMMETRIC {
        res = new IR(kReservedKeyword, string("SYMMETRIC"));
        $$ = res;
    }

    | TABLE {
        res = new IR(kReservedKeyword, string("TABLE"));
        $$ = res;
    }

    | THEN {
        res = new IR(kReservedKeyword, string("THEN"));
        $$ = res;
    }

    | TO {
        res = new IR(kReservedKeyword, string("TO"));
        $$ = res;
    }

    | TRAILING {
        res = new IR(kReservedKeyword, string("TRAILING"));
        $$ = res;
    }

    | TRUE_P {
        res = new IR(kReservedKeyword, string("TRUE"));
        $$ = res;
    }

    | UNION {
        res = new IR(kReservedKeyword, string("UNION"));
        $$ = res;
    }

    | UNIQUE {
        res = new IR(kReservedKeyword, string("UNIQUE"));
        $$ = res;
    }

    | USER {
        res = new IR(kReservedKeyword, string("USER"));
        $$ = res;
    }

    | USING {
        res = new IR(kReservedKeyword, string("USING"));
        $$ = res;
    }

    | VARIADIC {
        res = new IR(kReservedKeyword, string("VARIADIC"));
        $$ = res;
    }

    | WHEN {
        res = new IR(kReservedKeyword, string("WHEN"));
        $$ = res;
    }

    | WHERE {
        res = new IR(kReservedKeyword, string("WHERE"));
        $$ = res;
    }

    | WINDOW {
        res = new IR(kReservedKeyword, string("WINDOW"));
        $$ = res;
    }

    | WITH {
        res = new IR(kReservedKeyword, string("WITH"));
        $$ = res;
    }

;

/*
* While all keywords can be used as column labels when preceded by AS,
* not all of them can be used as a "bare" column label without AS.
* Those that can be used as a bare label must be listed here,
* in addition to appearing in one of the category lists above.
*
* Always add a new keyword to this list if possible.  Mark it BARE_LABEL
* in kwlist.h if it is included here, or AS_LABEL if it is not.
*/

bare_label_keyword:

    ABORT_P {
        res = new IR(kBareLabelKeyword, string("ABORT"));
        $$ = res;
    }

    | ABSOLUTE_P {
        res = new IR(kBareLabelKeyword, string("ABSOLUTE"));
        $$ = res;
    }

    | ACCESS {
        res = new IR(kBareLabelKeyword, string("ACCESS"));
        $$ = res;
    }

    | ACTION {
        res = new IR(kBareLabelKeyword, string("ACTION"));
        $$ = res;
    }

    | ADD_P {
        res = new IR(kBareLabelKeyword, string("ADD"));
        $$ = res;
    }

    | ADMIN {
        res = new IR(kBareLabelKeyword, string("ADMIN"));
        $$ = res;
    }

    | AFTER {
        res = new IR(kBareLabelKeyword, string("AFTER"));
        $$ = res;
    }

    | AGGREGATE {
        res = new IR(kBareLabelKeyword, string("AGGREGATE"));
        $$ = res;
    }

    | ALL {
        res = new IR(kBareLabelKeyword, string("ALL"));
        $$ = res;
    }

    | ALSO {
        res = new IR(kBareLabelKeyword, string("ALSO"));
        $$ = res;
    }

    | ALTER {
        res = new IR(kBareLabelKeyword, string("ALTER"));
        $$ = res;
    }

    | ALWAYS {
        res = new IR(kBareLabelKeyword, string("ALWAYS"));
        $$ = res;
    }

    | ANALYSE {
        res = new IR(kBareLabelKeyword, string("ANALYSE"));
        $$ = res;
    }

    | ANALYZE {
        res = new IR(kBareLabelKeyword, string("ANALYZE"));
        $$ = res;
    }

    | AND {
        res = new IR(kBareLabelKeyword, string("AND"));
        $$ = res;
    }

    | ANY {
        res = new IR(kBareLabelKeyword, string("ANY"));
        $$ = res;
    }

    | ASC {
        res = new IR(kBareLabelKeyword, string("ASC"));
        $$ = res;
    }

    | ASENSITIVE {
        res = new IR(kBareLabelKeyword, string("ASENSITIVE"));
        $$ = res;
    }

    | ASSERTION {
        res = new IR(kBareLabelKeyword, string("ASSERTION"));
        $$ = res;
    }

    | ASSIGNMENT {
        res = new IR(kBareLabelKeyword, string("ASSIGNMENT"));
        $$ = res;
    }

    | ASYMMETRIC {
        res = new IR(kBareLabelKeyword, string("ASYMMETRIC"));
        $$ = res;
    }

    | AT {
        res = new IR(kBareLabelKeyword, string("AT"));
        $$ = res;
    }

    | ATOMIC {
        res = new IR(kBareLabelKeyword, string("ATOMIC"));
        $$ = res;
    }

    | ATTACH {
        res = new IR(kBareLabelKeyword, string("ATTACH"));
        $$ = res;
    }

    | ATTRIBUTE {
        res = new IR(kBareLabelKeyword, string("ATTRIBUTE"));
        $$ = res;
    }

    | AUTHORIZATION {
        res = new IR(kBareLabelKeyword, string("AUTHORIZATION"));
        $$ = res;
    }

    | BACKWARD {
        res = new IR(kBareLabelKeyword, string("BACKWARD"));
        $$ = res;
    }

    | BEFORE {
        res = new IR(kBareLabelKeyword, string("BEFORE"));
        $$ = res;
    }

    | BEGIN_P {
        res = new IR(kBareLabelKeyword, string("BEGIN"));
        $$ = res;
    }

    | BETWEEN {
        res = new IR(kBareLabelKeyword, string("BETWEEN"));
        $$ = res;
    }

    | BIGINT {
        res = new IR(kBareLabelKeyword, string("BIGINT"));
        $$ = res;
    }

    | BINARY {
        res = new IR(kBareLabelKeyword, string("BINARY"));
        $$ = res;
    }

    | BIT {
        res = new IR(kBareLabelKeyword, string("BIT"));
        $$ = res;
    }

    | BOOLEAN_P {
        res = new IR(kBareLabelKeyword, string("BOOLEAN"));
        $$ = res;
    }

    | BOTH {
        res = new IR(kBareLabelKeyword, string("BOTH"));
        $$ = res;
    }

    | BREADTH {
        res = new IR(kBareLabelKeyword, string("BREADTH"));
        $$ = res;
    }

    | BY {
        res = new IR(kBareLabelKeyword, string("BY"));
        $$ = res;
    }

    | CACHE {
        res = new IR(kBareLabelKeyword, string("CACHE"));
        $$ = res;
    }

    | CALL {
        res = new IR(kBareLabelKeyword, string("CALL"));
        $$ = res;
    }

    | CALLED {
        res = new IR(kBareLabelKeyword, string("CALLED"));
        $$ = res;
    }

    | CASCADE {
        res = new IR(kBareLabelKeyword, string("CASCADE"));
        $$ = res;
    }

    | CASCADED {
        res = new IR(kBareLabelKeyword, string("CASCADED"));
        $$ = res;
    }

    | CASE {
        res = new IR(kBareLabelKeyword, string("CASE"));
        $$ = res;
    }

    | CAST {
        res = new IR(kBareLabelKeyword, string("CAST"));
        $$ = res;
    }

    | CATALOG_P {
        res = new IR(kBareLabelKeyword, string("CATALOG"));
        $$ = res;
    }

    | CHAIN {
        res = new IR(kBareLabelKeyword, string("CHAIN"));
        $$ = res;
    }

    | CHARACTERISTICS {
        res = new IR(kBareLabelKeyword, string("CHARACTERISTICS"));
        $$ = res;
    }

    | CHECK {
        res = new IR(kBareLabelKeyword, string("CHECK"));
        $$ = res;
    }

    | CHECKPOINT {
        res = new IR(kBareLabelKeyword, string("CHECKPOINT"));
        $$ = res;
    }

    | CLASS {
        res = new IR(kBareLabelKeyword, string("CLASS"));
        $$ = res;
    }

    | CLOSE {
        res = new IR(kBareLabelKeyword, string("CLOSE"));
        $$ = res;
    }

    | CLUSTER {
        res = new IR(kBareLabelKeyword, string("CLUSTER"));
        $$ = res;
    }

    | COALESCE {
        res = new IR(kBareLabelKeyword, string("COALESCE"));
        $$ = res;
    }

    | COLLATE {
        res = new IR(kBareLabelKeyword, string("COLLATE"));
        $$ = res;
    }

    | COLLATION {
        res = new IR(kBareLabelKeyword, string("COLLATION"));
        $$ = res;
    }

    | COLUMN {
        res = new IR(kBareLabelKeyword, string("COLUMN"));
        $$ = res;
    }

    | COLUMNS {
        res = new IR(kBareLabelKeyword, string("COLUMNS"));
        $$ = res;
    }

    | COMMENT {
        res = new IR(kBareLabelKeyword, string("COMMENT"));
        $$ = res;
    }

    | COMMENTS {
        res = new IR(kBareLabelKeyword, string("COMMENTS"));
        $$ = res;
    }

    | COMMIT {
        res = new IR(kBareLabelKeyword, string("COMMIT"));
        $$ = res;
    }

    | COMMITTED {
        res = new IR(kBareLabelKeyword, string("COMMITTED"));
        $$ = res;
    }

    | COMPRESSION {
        res = new IR(kBareLabelKeyword, string("COMPRESSION"));
        $$ = res;
    }

    | CONCURRENTLY {
        res = new IR(kBareLabelKeyword, string("CONCURRENTLY"));
        $$ = res;
    }

    | CONFIGURATION {
        res = new IR(kBareLabelKeyword, string("CONFIGURATION"));
        $$ = res;
    }

    | CONFLICT {
        res = new IR(kBareLabelKeyword, string("CONFLICT"));
        $$ = res;
    }

    | CONNECTION {
        res = new IR(kBareLabelKeyword, string("CONNECTION"));
        $$ = res;
    }

    | CONSTRAINT {
        res = new IR(kBareLabelKeyword, string("CONSTRAINT"));
        $$ = res;
    }

    | CONSTRAINTS {
        res = new IR(kBareLabelKeyword, string("CONSTRAINTS"));
        $$ = res;
    }

    | CONTENT_P {
        res = new IR(kBareLabelKeyword, string("CONTENT"));
        $$ = res;
    }

    | CONTINUE_P {
        res = new IR(kBareLabelKeyword, string("CONTINUE"));
        $$ = res;
    }

    | CONVERSION_P {
        res = new IR(kBareLabelKeyword, string("CONVERSION"));
        $$ = res;
    }

    | COPY {
        res = new IR(kBareLabelKeyword, string("COPY"));
        $$ = res;
    }

    | COST {
        res = new IR(kBareLabelKeyword, string("COST"));
        $$ = res;
    }

    | CROSS {
        res = new IR(kBareLabelKeyword, string("CROSS"));
        $$ = res;
    }

    | CSV {
        res = new IR(kBareLabelKeyword, string("CSV"));
        $$ = res;
    }

    | CUBE {
        res = new IR(kBareLabelKeyword, string("CUBE"));
        $$ = res;
    }

    | CURRENT_P {
        res = new IR(kBareLabelKeyword, string("CURRENT"));
        $$ = res;
    }

    | CURRENT_CATALOG {
        res = new IR(kBareLabelKeyword, string("CURRENT_CATALOG"));
        $$ = res;
    }

    | CURRENT_DATE {
        res = new IR(kBareLabelKeyword, string("CURRENT_DATE"));
        $$ = res;
    }

    | CURRENT_ROLE {
        res = new IR(kBareLabelKeyword, string("CURRENT_ROLE"));
        $$ = res;
    }

    | CURRENT_SCHEMA {
        res = new IR(kBareLabelKeyword, string("CURRENT_SCHEMA"));
        $$ = res;
    }

    | CURRENT_TIME {
        res = new IR(kBareLabelKeyword, string("CURRENT_TIME"));
        $$ = res;
    }

    | CURRENT_TIMESTAMP {
        res = new IR(kBareLabelKeyword, string("CURRENT_TIMESTAMP"));
        $$ = res;
    }

    | CURRENT_USER {
        res = new IR(kBareLabelKeyword, string("CURRENT_USER"));
        $$ = res;
    }

    | CURSOR {
        res = new IR(kBareLabelKeyword, string("CURSOR"));
        $$ = res;
    }

    | CYCLE {
        res = new IR(kBareLabelKeyword, string("CYCLE"));
        $$ = res;
    }

    | DATA_P {
        res = new IR(kBareLabelKeyword, string("DATA"));
        $$ = res;
    }

    | DATABASE {
        res = new IR(kBareLabelKeyword, string("DATABASE"));
        $$ = res;
    }

    | DEALLOCATE {
        res = new IR(kBareLabelKeyword, string("DEALLOCATE"));
        $$ = res;
    }

    | DEC {
        res = new IR(kBareLabelKeyword, string("DEC"));
        $$ = res;
    }

    | DECIMAL_P {
        res = new IR(kBareLabelKeyword, string("DECIMAL"));
        $$ = res;
    }

    | DECLARE {
        res = new IR(kBareLabelKeyword, string("DECLARE"));
        $$ = res;
    }

    | DEFAULT {
        res = new IR(kBareLabelKeyword, string("DEFAULT"));
        $$ = res;
    }

    | DEFAULTS {
        res = new IR(kBareLabelKeyword, string("DEFAULTS"));
        $$ = res;
    }

    | DEFERRABLE {
        res = new IR(kBareLabelKeyword, string("DEFERRABLE"));
        $$ = res;
    }

    | DEFERRED {
        res = new IR(kBareLabelKeyword, string("DEFERRED"));
        $$ = res;
    }

    | DEFINER {
        res = new IR(kBareLabelKeyword, string("DEFINER"));
        $$ = res;
    }

    | DELETE_P {
        res = new IR(kBareLabelKeyword, string("DELETE"));
        $$ = res;
    }

    | DELIMITER {
        res = new IR(kBareLabelKeyword, string("DELIMITER"));
        $$ = res;
    }

    | DELIMITERS {
        res = new IR(kBareLabelKeyword, string("DELIMITERS"));
        $$ = res;
    }

    | DEPENDS {
        res = new IR(kBareLabelKeyword, string("DEPENDS"));
        $$ = res;
    }

    | DEPTH {
        res = new IR(kBareLabelKeyword, string("DEPTH"));
        $$ = res;
    }

    | DESC {
        res = new IR(kBareLabelKeyword, string("DESC"));
        $$ = res;
    }

    | DETACH {
        res = new IR(kBareLabelKeyword, string("DETACH"));
        $$ = res;
    }

    | DICTIONARY {
        res = new IR(kBareLabelKeyword, string("DICTIONARY"));
        $$ = res;
    }

    | DISABLE_P {
        res = new IR(kBareLabelKeyword, string("DISABLE"));
        $$ = res;
    }

    | DISCARD {
        res = new IR(kBareLabelKeyword, string("DISCARD"));
        $$ = res;
    }

    | DISTINCT {
        res = new IR(kBareLabelKeyword, string("DISTINCT"));
        $$ = res;
    }

    | DO {
        res = new IR(kBareLabelKeyword, string("DO"));
        $$ = res;
    }

    | DOCUMENT_P {
        res = new IR(kBareLabelKeyword, string("DOCUMENT"));
        $$ = res;
    }

    | DOMAIN_P {
        res = new IR(kBareLabelKeyword, string("DOMAIN"));
        $$ = res;
    }

    | DOUBLE_P {
        res = new IR(kBareLabelKeyword, string("DOUBLE"));
        $$ = res;
    }

    | DROP {
        res = new IR(kBareLabelKeyword, string("DROP"));
        $$ = res;
    }

    | EACH {
        res = new IR(kBareLabelKeyword, string("EACH"));
        $$ = res;
    }

    | ELSE {
        res = new IR(kBareLabelKeyword, string("ELSE"));
        $$ = res;
    }

    | ENABLE_P {
        res = new IR(kBareLabelKeyword, string("ENABLE"));
        $$ = res;
    }

    | ENCODING {
        res = new IR(kBareLabelKeyword, string("ENCODING"));
        $$ = res;
    }

    | ENCRYPTED {
        res = new IR(kBareLabelKeyword, string("ENCRYPTED"));
        $$ = res;
    }

    | END_P {
        res = new IR(kBareLabelKeyword, string("END"));
        $$ = res;
    }

    | ENUM_P {
        res = new IR(kBareLabelKeyword, string("ENUM"));
        $$ = res;
    }

    | ESCAPE {
        res = new IR(kBareLabelKeyword, string("ESCAPE"));
        $$ = res;
    }

    | EVENT {
        res = new IR(kBareLabelKeyword, string("EVENT"));
        $$ = res;
    }

    | EXCLUDE {
        res = new IR(kBareLabelKeyword, string("EXCLUDE"));
        $$ = res;
    }

    | EXCLUDING {
        res = new IR(kBareLabelKeyword, string("EXCLUDING"));
        $$ = res;
    }

    | EXCLUSIVE {
        res = new IR(kBareLabelKeyword, string("EXCLUSIVE"));
        $$ = res;
    }

    | EXECUTE {
        res = new IR(kBareLabelKeyword, string("EXECUTE"));
        $$ = res;
    }

    | EXISTS {
        res = new IR(kBareLabelKeyword, string("EXISTS"));
        $$ = res;
    }

    | EXPLAIN {
        res = new IR(kBareLabelKeyword, string("EXPLAIN"));
        $$ = res;
    }

    | EXPRESSION {
        res = new IR(kBareLabelKeyword, string("EXPRESSION"));
        $$ = res;
    }

    | EXTENSION {
        res = new IR(kBareLabelKeyword, string("EXTENSION"));
        $$ = res;
    }

    | EXTERNAL {
        res = new IR(kBareLabelKeyword, string("EXTERNAL"));
        $$ = res;
    }

    | EXTRACT {
        res = new IR(kBareLabelKeyword, string("EXTRACT"));
        $$ = res;
    }

    | FALSE_P {
        res = new IR(kBareLabelKeyword, string("FALSE"));
        $$ = res;
    }

    | FAMILY {
        res = new IR(kBareLabelKeyword, string("FAMILY"));
        $$ = res;
    }

    | FINALIZE {
        res = new IR(kBareLabelKeyword, string("FINALIZE"));
        $$ = res;
    }

    | FIRST_P {
        res = new IR(kBareLabelKeyword, string("FIRST"));
        $$ = res;
    }

    | FLOAT_P {
        res = new IR(kBareLabelKeyword, string("FLOAT"));
        $$ = res;
    }

    | FOLLOWING {
        res = new IR(kBareLabelKeyword, string("FOLLOWING"));
        $$ = res;
    }

    | FORCE {
        res = new IR(kBareLabelKeyword, string("FORCE"));
        $$ = res;
    }

    | FOREIGN {
        res = new IR(kBareLabelKeyword, string("FOREIGN"));
        $$ = res;
    }

    | FORWARD {
        res = new IR(kBareLabelKeyword, string("FORWARD"));
        $$ = res;
    }

    | FREEZE {
        res = new IR(kBareLabelKeyword, string("FREEZE"));
        $$ = res;
    }

    | FULL {
        res = new IR(kBareLabelKeyword, string("FULL"));
        $$ = res;
    }

    | FUNCTION {
        res = new IR(kBareLabelKeyword, string("FUNCTION"));
        $$ = res;
    }

    | FUNCTIONS {
        res = new IR(kBareLabelKeyword, string("FUNCTIONS"));
        $$ = res;
    }

    | GENERATED {
        res = new IR(kBareLabelKeyword, string("GENERATED"));
        $$ = res;
    }

    | GLOBAL {
        res = new IR(kBareLabelKeyword, string("GLOBAL"));
        $$ = res;
    }

    | GRANTED {
        res = new IR(kBareLabelKeyword, string("GRANTED"));
        $$ = res;
    }

    | GREATEST {
        res = new IR(kBareLabelKeyword, string("GREATEST"));
        $$ = res;
    }

    | GROUPING {
        res = new IR(kBareLabelKeyword, string("GROUPING"));
        $$ = res;
    }

    | GROUPS {
        res = new IR(kBareLabelKeyword, string("GROUPS"));
        $$ = res;
    }

    | HANDLER {
        res = new IR(kBareLabelKeyword, string("HANDLER"));
        $$ = res;
    }

    | HEADER_P {
        res = new IR(kBareLabelKeyword, string("HEADER"));
        $$ = res;
    }

    | HOLD {
        res = new IR(kBareLabelKeyword, string("HOLD"));
        $$ = res;
    }

    | IDENTITY_P {
        res = new IR(kBareLabelKeyword, string("IDENTITY"));
        $$ = res;
    }

    | IF_P {
        res = new IR(kBareLabelKeyword, string("IF"));
        $$ = res;
    }

    | ILIKE {
        res = new IR(kBareLabelKeyword, string("ILIKE"));
        $$ = res;
    }

    | IMMEDIATE {
        res = new IR(kBareLabelKeyword, string("IMMEDIATE"));
        $$ = res;
    }

    | IMMUTABLE {
        res = new IR(kBareLabelKeyword, string("IMMUTABLE"));
        $$ = res;
    }

    | IMPLICIT_P {
        res = new IR(kBareLabelKeyword, string("IMPLICIT"));
        $$ = res;
    }

    | IMPORT_P {
        res = new IR(kBareLabelKeyword, string("IMPORT"));
        $$ = res;
    }

    | IN_P {
        res = new IR(kBareLabelKeyword, string("IN"));
        $$ = res;
    }

    | INCLUDE {
        res = new IR(kBareLabelKeyword, string("INCLUDE"));
        $$ = res;
    }

    | INCLUDING {
        res = new IR(kBareLabelKeyword, string("INCLUDING"));
        $$ = res;
    }

    | INCREMENT {
        res = new IR(kBareLabelKeyword, string("INCREMENT"));
        $$ = res;
    }

    | INDEX {
        res = new IR(kBareLabelKeyword, string("INDEX"));
        $$ = res;
    }

    | INDEXES {
        res = new IR(kBareLabelKeyword, string("INDEXES"));
        $$ = res;
    }

    | INHERIT {
        res = new IR(kBareLabelKeyword, string("INHERIT"));
        $$ = res;
    }

    | INHERITS {
        res = new IR(kBareLabelKeyword, string("INHERITS"));
        $$ = res;
    }

    | INITIALLY {
        res = new IR(kBareLabelKeyword, string("INITIALLY"));
        $$ = res;
    }

    | INLINE_P {
        res = new IR(kBareLabelKeyword, string("INLINE"));
        $$ = res;
    }

    | INNER_P {
        res = new IR(kBareLabelKeyword, string("INNER"));
        $$ = res;
    }

    | INOUT {
        res = new IR(kBareLabelKeyword, string("INOUT"));
        $$ = res;
    }

    | INPUT_P {
        res = new IR(kBareLabelKeyword, string("INPUT"));
        $$ = res;
    }

    | INSENSITIVE {
        res = new IR(kBareLabelKeyword, string("INSENSITIVE"));
        $$ = res;
    }

    | INSERT {
        res = new IR(kBareLabelKeyword, string("INSERT"));
        $$ = res;
    }

    | INSTEAD {
        res = new IR(kBareLabelKeyword, string("INSTEAD"));
        $$ = res;
    }

    | INT_P {
        res = new IR(kBareLabelKeyword, string("INT"));
        $$ = res;
    }

    | INTEGER {
        res = new IR(kBareLabelKeyword, string("INTEGER"));
        $$ = res;
    }

    | INTERVAL {
        res = new IR(kBareLabelKeyword, string("INTERVAL"));
        $$ = res;
    }

    | INVOKER {
        res = new IR(kBareLabelKeyword, string("INVOKER"));
        $$ = res;
    }

    | IS {
        res = new IR(kBareLabelKeyword, string("IS"));
        $$ = res;
    }

    | ISOLATION {
        res = new IR(kBareLabelKeyword, string("ISOLATION"));
        $$ = res;
    }

    | JOIN {
        res = new IR(kBareLabelKeyword, string("JOIN"));
        $$ = res;
    }

    | KEY {
        res = new IR(kBareLabelKeyword, string("KEY"));
        $$ = res;
    }

    | LABEL {
        res = new IR(kBareLabelKeyword, string("LABEL"));
        $$ = res;
    }

    | LANGUAGE {
        res = new IR(kBareLabelKeyword, string("LANGUAGE"));
        $$ = res;
    }

    | LARGE_P {
        res = new IR(kBareLabelKeyword, string("LARGE"));
        $$ = res;
    }

    | LAST_P {
        res = new IR(kBareLabelKeyword, string("LAST"));
        $$ = res;
    }

    | LATERAL_P {
        res = new IR(kBareLabelKeyword, string("LATERAL"));
        $$ = res;
    }

    | LEADING {
        res = new IR(kBareLabelKeyword, string("LEADING"));
        $$ = res;
    }

    | LEAKPROOF {
        res = new IR(kBareLabelKeyword, string("LEAKPROOF"));
        $$ = res;
    }

    | LEAST {
        res = new IR(kBareLabelKeyword, string("LEAST"));
        $$ = res;
    }

    | LEFT {
        res = new IR(kBareLabelKeyword, string("LEFT"));
        $$ = res;
    }

    | LEVEL {
        res = new IR(kBareLabelKeyword, string("LEVEL"));
        $$ = res;
    }

    | LIKE {
        res = new IR(kBareLabelKeyword, string("LIKE"));
        $$ = res;
    }

    | LISTEN {
        res = new IR(kBareLabelKeyword, string("LISTEN"));
        $$ = res;
    }

    | LOAD {
        res = new IR(kBareLabelKeyword, string("LOAD"));
        $$ = res;
    }

    | LOCAL {
        res = new IR(kBareLabelKeyword, string("LOCAL"));
        $$ = res;
    }

    | LOCALTIME {
        res = new IR(kBareLabelKeyword, string("LOCALTIME"));
        $$ = res;
    }

    | LOCALTIMESTAMP {
        res = new IR(kBareLabelKeyword, string("LOCALTIMESTAMP"));
        $$ = res;
    }

    | LOCATION {
        res = new IR(kBareLabelKeyword, string("LOCATION"));
        $$ = res;
    }

    | LOCK_P {
        res = new IR(kBareLabelKeyword, string("LOCK"));
        $$ = res;
    }

    | LOCKED {
        res = new IR(kBareLabelKeyword, string("LOCKED"));
        $$ = res;
    }

    | LOGGED {
        res = new IR(kBareLabelKeyword, string("LOGGED"));
        $$ = res;
    }

    | MAPPING {
        res = new IR(kBareLabelKeyword, string("MAPPING"));
        $$ = res;
    }

    | MATCH {
        res = new IR(kBareLabelKeyword, string("MATCH"));
        $$ = res;
    }

    | MATERIALIZED {
        res = new IR(kBareLabelKeyword, string("MATERIALIZED"));
        $$ = res;
    }

    | MAXVALUE {
        res = new IR(kBareLabelKeyword, string("MAXVALUE"));
        $$ = res;
    }

    | METHOD {
        res = new IR(kBareLabelKeyword, string("METHOD"));
        $$ = res;
    }

    | MINVALUE {
        res = new IR(kBareLabelKeyword, string("MINVALUE"));
        $$ = res;
    }

    | MODE {
        res = new IR(kBareLabelKeyword, string("MODE"));
        $$ = res;
    }

    | MOVE {
        res = new IR(kBareLabelKeyword, string("MOVE"));
        $$ = res;
    }

    | NAME_P {
        res = new IR(kBareLabelKeyword, string("NAME"));
        $$ = res;
    }

    | NAMES {
        res = new IR(kBareLabelKeyword, string("NAMES"));
        $$ = res;
    }

    | NATIONAL {
        res = new IR(kBareLabelKeyword, string("NATIONAL"));
        $$ = res;
    }

    | NATURAL {
        res = new IR(kBareLabelKeyword, string("NATURAL"));
        $$ = res;
    }

    | NCHAR {
        res = new IR(kBareLabelKeyword, string("NCHAR"));
        $$ = res;
    }

    | NEW {
        res = new IR(kBareLabelKeyword, string("NEW"));
        $$ = res;
    }

    | NEXT {
        res = new IR(kBareLabelKeyword, string("NEXT"));
        $$ = res;
    }

    | NFC {
        res = new IR(kBareLabelKeyword, string("NFC"));
        $$ = res;
    }

    | NFD {
        res = new IR(kBareLabelKeyword, string("NFD"));
        $$ = res;
    }

    | NFKC {
        res = new IR(kBareLabelKeyword, string("NFKC"));
        $$ = res;
    }

    | NFKD {
        res = new IR(kBareLabelKeyword, string("NFKD"));
        $$ = res;
    }

    | NO {
        res = new IR(kBareLabelKeyword, string("NO"));
        $$ = res;
    }

    | NONE {
        res = new IR(kBareLabelKeyword, string("NONE"));
        $$ = res;
    }

    | NORMALIZE {
        res = new IR(kBareLabelKeyword, string("NORMALIZE"));
        $$ = res;
    }

    | NORMALIZED {
        res = new IR(kBareLabelKeyword, string("NORMALIZED"));
        $$ = res;
    }

    | NOT {
        res = new IR(kBareLabelKeyword, string("NOT"));
        $$ = res;
    }

    | NOTHING {
        res = new IR(kBareLabelKeyword, string("NOTHING"));
        $$ = res;
    }

    | NOTIFY {
        res = new IR(kBareLabelKeyword, string("NOTIFY"));
        $$ = res;
    }

    | NOWAIT {
        res = new IR(kBareLabelKeyword, string("NOWAIT"));
        $$ = res;
    }

    | NULL_P {
        res = new IR(kBareLabelKeyword, string("NULL"));
        $$ = res;
    }

    | NULLIF {
        res = new IR(kBareLabelKeyword, string("NULLIF"));
        $$ = res;
    }

    | NULLS_P {
        res = new IR(kBareLabelKeyword, string("NULLS"));
        $$ = res;
    }

    | NUMERIC {
        res = new IR(kBareLabelKeyword, string("NUMERIC"));
        $$ = res;
    }

    | OBJECT_P {
        res = new IR(kBareLabelKeyword, string("OBJECT"));
        $$ = res;
    }

    | OF {
        res = new IR(kBareLabelKeyword, string("OF"));
        $$ = res;
    }

    | OFF {
        res = new IR(kBareLabelKeyword, string("OFF"));
        $$ = res;
    }

    | OIDS {
        res = new IR(kBareLabelKeyword, string("OIDS"));
        $$ = res;
    }

    | OLD {
        res = new IR(kBareLabelKeyword, string("OLD"));
        $$ = res;
    }

    | ONLY {
        res = new IR(kBareLabelKeyword, string("ONLY"));
        $$ = res;
    }

    | OPERATOR {
        res = new IR(kBareLabelKeyword, string("OPERATOR"));
        $$ = res;
    }

    | OPTION {
        res = new IR(kBareLabelKeyword, string("OPTION"));
        $$ = res;
    }

    | OPTIONS {
        res = new IR(kBareLabelKeyword, string("OPTIONS"));
        $$ = res;
    }

    | OR {
        res = new IR(kBareLabelKeyword, string("OR"));
        $$ = res;
    }

    | ORDINALITY {
        res = new IR(kBareLabelKeyword, string("ORDINALITY"));
        $$ = res;
    }

    | OTHERS {
        res = new IR(kBareLabelKeyword, string("OTHERS"));
        $$ = res;
    }

    | OUT_P {
        res = new IR(kBareLabelKeyword, string("OUT"));
        $$ = res;
    }

    | OUTER_P {
        res = new IR(kBareLabelKeyword, string("OUTER"));
        $$ = res;
    }

    | OVERLAY {
        res = new IR(kBareLabelKeyword, string("OVERLAY"));
        $$ = res;
    }

    | OVERRIDING {
        res = new IR(kBareLabelKeyword, string("OVERRIDING"));
        $$ = res;
    }

    | OWNED {
        res = new IR(kBareLabelKeyword, string("OWNED"));
        $$ = res;
    }

    | OWNER {
        res = new IR(kBareLabelKeyword, string("OWNER"));
        $$ = res;
    }

    | PARALLEL {
        res = new IR(kBareLabelKeyword, string("PARALLEL"));
        $$ = res;
    }

    | PARSER {
        res = new IR(kBareLabelKeyword, string("PARSER"));
        $$ = res;
    }

    | PARTIAL {
        res = new IR(kBareLabelKeyword, string("PARTIAL"));
        $$ = res;
    }

    | PARTITION {
        res = new IR(kBareLabelKeyword, string("PARTITION"));
        $$ = res;
    }

    | PASSING {
        res = new IR(kBareLabelKeyword, string("PASSING"));
        $$ = res;
    }

    | PASSWORD {
        res = new IR(kBareLabelKeyword, string("PASSWORD"));
        $$ = res;
    }

    | PLACING {
        res = new IR(kBareLabelKeyword, string("PLACING"));
        $$ = res;
    }

    | PLANS {
        res = new IR(kBareLabelKeyword, string("PLANS"));
        $$ = res;
    }

    | POLICY {
        res = new IR(kBareLabelKeyword, string("POLICY"));
        $$ = res;
    }

    | POSITION {
        res = new IR(kBareLabelKeyword, string("POSITION"));
        $$ = res;
    }

    | PRECEDING {
        res = new IR(kBareLabelKeyword, string("PRECEDING"));
        $$ = res;
    }

    | PREPARE {
        res = new IR(kBareLabelKeyword, string("PREPARE"));
        $$ = res;
    }

    | PREPARED {
        res = new IR(kBareLabelKeyword, string("PREPARED"));
        $$ = res;
    }

    | PRESERVE {
        res = new IR(kBareLabelKeyword, string("PRESERVE"));
        $$ = res;
    }

    | PRIMARY {
        res = new IR(kBareLabelKeyword, string("PRIMARY"));
        $$ = res;
    }

    | PRIOR {
        res = new IR(kBareLabelKeyword, string("PRIOR"));
        $$ = res;
    }

    | PRIVILEGES {
        res = new IR(kBareLabelKeyword, string("PRIVILEGES"));
        $$ = res;
    }

    | PROCEDURAL {
        res = new IR(kBareLabelKeyword, string("PROCEDURAL"));
        $$ = res;
    }

    | PROCEDURE {
        res = new IR(kBareLabelKeyword, string("PROCEDURE"));
        $$ = res;
    }

    | PROCEDURES {
        res = new IR(kBareLabelKeyword, string("PROCEDURES"));
        $$ = res;
    }

    | PROGRAM {
        res = new IR(kBareLabelKeyword, string("PROGRAM"));
        $$ = res;
    }

    | PUBLICATION {
        res = new IR(kBareLabelKeyword, string("PUBLICATION"));
        $$ = res;
    }

    | QUOTE {
        res = new IR(kBareLabelKeyword, string("QUOTE"));
        $$ = res;
    }

    | RANGE {
        res = new IR(kBareLabelKeyword, string("RANGE"));
        $$ = res;
    }

    | READ {
        res = new IR(kBareLabelKeyword, string("READ"));
        $$ = res;
    }

    | REAL {
        res = new IR(kBareLabelKeyword, string("REAL"));
        $$ = res;
    }

    | REASSIGN {
        res = new IR(kBareLabelKeyword, string("REASSIGN"));
        $$ = res;
    }

    | RECHECK {
        res = new IR(kBareLabelKeyword, string("RECHECK"));
        $$ = res;
    }

    | RECURSIVE {
        res = new IR(kBareLabelKeyword, string("RECURSIVE"));
        $$ = res;
    }

    | REF {
        res = new IR(kBareLabelKeyword, string("REF"));
        $$ = res;
    }

    | REFERENCES {
        res = new IR(kBareLabelKeyword, string("REFERENCES"));
        $$ = res;
    }

    | REFERENCING {
        res = new IR(kBareLabelKeyword, string("REFERENCING"));
        $$ = res;
    }

    | REFRESH {
        res = new IR(kBareLabelKeyword, string("REFRESH"));
        $$ = res;
    }

    | REINDEX {
        res = new IR(kBareLabelKeyword, string("REINDEX"));
        $$ = res;
    }

    | RELATIVE_P {
        res = new IR(kBareLabelKeyword, string("RELATIVE"));
        $$ = res;
    }

    | RELEASE {
        res = new IR(kBareLabelKeyword, string("RELEASE"));
        $$ = res;
    }

    | RENAME {
        res = new IR(kBareLabelKeyword, string("RENAME"));
        $$ = res;
    }

    | REPEATABLE {
        res = new IR(kBareLabelKeyword, string("REPEATABLE"));
        $$ = res;
    }

    | REPLACE {
        res = new IR(kBareLabelKeyword, string("REPLACE"));
        $$ = res;
    }

    | REPLICA {
        res = new IR(kBareLabelKeyword, string("REPLICA"));
        $$ = res;
    }

    | RESET {
        res = new IR(kBareLabelKeyword, string("RESET"));
        $$ = res;
    }

    | RESTART {
        res = new IR(kBareLabelKeyword, string("RESTART"));
        $$ = res;
    }

    | RESTRICT {
        res = new IR(kBareLabelKeyword, string("RESTRICT"));
        $$ = res;
    }

    | RETURN {
        res = new IR(kBareLabelKeyword, string("RETURN"));
        $$ = res;
    }

    | RETURNS {
        res = new IR(kBareLabelKeyword, string("RETURNS"));
        $$ = res;
    }

    | REVOKE {
        res = new IR(kBareLabelKeyword, string("REVOKE"));
        $$ = res;
    }

    | RIGHT {
        res = new IR(kBareLabelKeyword, string("RIGHT"));
        $$ = res;
    }

    | ROLE {
        res = new IR(kBareLabelKeyword, string("ROLE"));
        $$ = res;
    }

    | ROLLBACK {
        res = new IR(kBareLabelKeyword, string("ROLLBACK"));
        $$ = res;
    }

    | ROLLUP {
        res = new IR(kBareLabelKeyword, string("ROLLUP"));
        $$ = res;
    }

    | ROUTINE {
        res = new IR(kBareLabelKeyword, string("ROUTINE"));
        $$ = res;
    }

    | ROUTINES {
        res = new IR(kBareLabelKeyword, string("ROUTINES"));
        $$ = res;
    }

    | ROW {
        res = new IR(kBareLabelKeyword, string("ROW"));
        $$ = res;
    }

    | ROWS {
        res = new IR(kBareLabelKeyword, string("ROWS"));
        $$ = res;
    }

    | RULE {
        res = new IR(kBareLabelKeyword, string("RULE"));
        $$ = res;
    }

    | SAVEPOINT {
        res = new IR(kBareLabelKeyword, string("SAVEPOINT"));
        $$ = res;
    }

    | SCHEMA {
        res = new IR(kBareLabelKeyword, string("SCHEMA"));
        $$ = res;
    }

    | SCHEMAS {
        res = new IR(kBareLabelKeyword, string("SCHEMAS"));
        $$ = res;
    }

    | SCROLL {
        res = new IR(kBareLabelKeyword, string("SCROLL"));
        $$ = res;
    }

    | SEARCH {
        res = new IR(kBareLabelKeyword, string("SEARCH"));
        $$ = res;
    }

    | SECURITY {
        res = new IR(kBareLabelKeyword, string("SECURITY"));
        $$ = res;
    }

    | SELECT {
        res = new IR(kBareLabelKeyword, string("SELECT"));
        $$ = res;
    }

    | SEQUENCE {
        res = new IR(kBareLabelKeyword, string("SEQUENCE"));
        $$ = res;
    }

    | SEQUENCES {
        res = new IR(kBareLabelKeyword, string("SEQUENCES"));
        $$ = res;
    }

    | SERIALIZABLE {
        res = new IR(kBareLabelKeyword, string("SERIALIZABLE"));
        $$ = res;
    }

    | SERVER {
        res = new IR(kBareLabelKeyword, string("SERVER"));
        $$ = res;
    }

    | SESSION {
        res = new IR(kBareLabelKeyword, string("SESSION"));
        $$ = res;
    }

    | SESSION_USER {
        res = new IR(kBareLabelKeyword, string("SESSION_USER"));
        $$ = res;
    }

    | SET {
        res = new IR(kBareLabelKeyword, string("SET"));
        $$ = res;
    }

    | SETOF {
        res = new IR(kBareLabelKeyword, string("SETOF"));
        $$ = res;
    }

    | SETS {
        res = new IR(kBareLabelKeyword, string("SETS"));
        $$ = res;
    }

    | SHARE {
        res = new IR(kBareLabelKeyword, string("SHARE"));
        $$ = res;
    }

    | SHOW {
        res = new IR(kBareLabelKeyword, string("SHOW"));
        $$ = res;
    }

    | SIMILAR {
        res = new IR(kBareLabelKeyword, string("SIMILAR"));
        $$ = res;
    }

    | SIMPLE {
        res = new IR(kBareLabelKeyword, string("SIMPLE"));
        $$ = res;
    }

    | SKIP {
        res = new IR(kBareLabelKeyword, string("SKIP"));
        $$ = res;
    }

    | SMALLINT {
        res = new IR(kBareLabelKeyword, string("SMALLINT"));
        $$ = res;
    }

    | SNAPSHOT {
        res = new IR(kBareLabelKeyword, string("SNAPSHOT"));
        $$ = res;
    }

    | SOME {
        res = new IR(kBareLabelKeyword, string("SOME"));
        $$ = res;
    }

    | SQL_P {
        res = new IR(kBareLabelKeyword, string("SQL"));
        $$ = res;
    }

    | STABLE {
        res = new IR(kBareLabelKeyword, string("STABLE"));
        $$ = res;
    }

    | STANDALONE_P {
        res = new IR(kBareLabelKeyword, string("STANDALONE"));
        $$ = res;
    }

    | START {
        res = new IR(kBareLabelKeyword, string("START"));
        $$ = res;
    }

    | STATEMENT {
        res = new IR(kBareLabelKeyword, string("STATEMENT"));
        $$ = res;
    }

    | STATISTICS {
        res = new IR(kBareLabelKeyword, string("STATISTICS"));
        $$ = res;
    }

    | STDIN {
        res = new IR(kBareLabelKeyword, string("STDIN"));
        $$ = res;
    }

    | STDOUT {
        res = new IR(kBareLabelKeyword, string("STDOUT"));
        $$ = res;
    }

    | STORAGE {
        res = new IR(kBareLabelKeyword, string("STORAGE"));
        $$ = res;
    }

    | STORED {
        res = new IR(kBareLabelKeyword, string("STORED"));
        $$ = res;
    }

    | STRICT_P {
        res = new IR(kBareLabelKeyword, string("STRICT"));
        $$ = res;
    }

    | STRIP_P {
        res = new IR(kBareLabelKeyword, string("STRIP"));
        $$ = res;
    }

    | SUBSCRIPTION {
        res = new IR(kBareLabelKeyword, string("SUBSCRIPTION"));
        $$ = res;
    }

    | SUBSTRING {
        res = new IR(kBareLabelKeyword, string("SUBSTRING"));
        $$ = res;
    }

    | SUPPORT {
        res = new IR(kBareLabelKeyword, string("SUPPORT"));
        $$ = res;
    }

    | SYMMETRIC {
        res = new IR(kBareLabelKeyword, string("SYMMETRIC"));
        $$ = res;
    }

    | SYSID {
        res = new IR(kBareLabelKeyword, string("SYSID"));
        $$ = res;
    }

    | SYSTEM_P {
        res = new IR(kBareLabelKeyword, string("SYSTEM"));
        $$ = res;
    }

    | TABLE {
        res = new IR(kBareLabelKeyword, string("TABLE"));
        $$ = res;
    }

    | TABLES {
        res = new IR(kBareLabelKeyword, string("TABLES"));
        $$ = res;
    }

    | TABLESAMPLE {
        res = new IR(kBareLabelKeyword, string("TABLESAMPLE"));
        $$ = res;
    }

    | TABLESPACE {
        res = new IR(kBareLabelKeyword, string("TABLESPACE"));
        $$ = res;
    }

    | TEMP {
        res = new IR(kBareLabelKeyword, string("TEMP"));
        $$ = res;
    }

    | TEMPLATE {
        res = new IR(kBareLabelKeyword, string("TEMPLATE"));
        $$ = res;
    }

    | TEMPORARY {
        res = new IR(kBareLabelKeyword, string("TEMPORARY"));
        $$ = res;
    }

    | TEXT_P {
        res = new IR(kBareLabelKeyword, string("TEXT"));
        $$ = res;
    }

    | THEN {
        res = new IR(kBareLabelKeyword, string("THEN"));
        $$ = res;
    }

    | TIES {
        res = new IR(kBareLabelKeyword, string("TIES"));
        $$ = res;
    }

    | TIME {
        res = new IR(kBareLabelKeyword, string("TIME"));
        $$ = res;
    }

    | TIMESTAMP {
        res = new IR(kBareLabelKeyword, string("TIMESTAMP"));
        $$ = res;
    }

    | TRAILING {
        res = new IR(kBareLabelKeyword, string("TRAILING"));
        $$ = res;
    }

    | TRANSACTION {
        res = new IR(kBareLabelKeyword, string("TRANSACTION"));
        $$ = res;
    }

    | TRANSFORM {
        res = new IR(kBareLabelKeyword, string("TRANSFORM"));
        $$ = res;
    }

    | TREAT {
        res = new IR(kBareLabelKeyword, string("TREAT"));
        $$ = res;
    }

    | TRIGGER {
        res = new IR(kBareLabelKeyword, string("TRIGGER"));
        $$ = res;
    }

    | TRIM {
        res = new IR(kBareLabelKeyword, string("TRIM"));
        $$ = res;
    }

    | TRUE_P {
        res = new IR(kBareLabelKeyword, string("TRUE"));
        $$ = res;
    }

    | TRUNCATE {
        res = new IR(kBareLabelKeyword, string("TRUNCATE"));
        $$ = res;
    }

    | TRUSTED {
        res = new IR(kBareLabelKeyword, string("TRUSTED"));
        $$ = res;
    }

    | TYPE_P {
        res = new IR(kBareLabelKeyword, string("TYPE"));
        $$ = res;
    }

    | TYPES_P {
        res = new IR(kBareLabelKeyword, string("TYPES"));
        $$ = res;
    }

    | UESCAPE {
        res = new IR(kBareLabelKeyword, string("UESCAPE"));
        $$ = res;
    }

    | UNBOUNDED {
        res = new IR(kBareLabelKeyword, string("UNBOUNDED"));
        $$ = res;
    }

    | UNCOMMITTED {
        res = new IR(kBareLabelKeyword, string("UNCOMMITTED"));
        $$ = res;
    }

    | UNENCRYPTED {
        res = new IR(kBareLabelKeyword, string("UNENCRYPTED"));
        $$ = res;
    }

    | UNIQUE {
        res = new IR(kBareLabelKeyword, string("UNIQUE"));
        $$ = res;
    }

    | UNKNOWN {
        res = new IR(kBareLabelKeyword, string("UNKNOWN"));
        $$ = res;
    }

    | UNLISTEN {
        res = new IR(kBareLabelKeyword, string("UNLISTEN"));
        $$ = res;
    }

    | UNLOGGED {
        res = new IR(kBareLabelKeyword, string("UNLOGGED"));
        $$ = res;
    }

    | UNTIL {
        res = new IR(kBareLabelKeyword, string("UNTIL"));
        $$ = res;
    }

    | UPDATE {
        res = new IR(kBareLabelKeyword, string("UPDATE"));
        $$ = res;
    }

    | USER {
        res = new IR(kBareLabelKeyword, string("USER"));
        $$ = res;
    }

    | USING {
        res = new IR(kBareLabelKeyword, string("USING"));
        $$ = res;
    }

    | VACUUM {
        res = new IR(kBareLabelKeyword, string("VACUUM"));
        $$ = res;
    }

    | VALID {
        res = new IR(kBareLabelKeyword, string("VALID"));
        $$ = res;
    }

    | VALIDATE {
        res = new IR(kBareLabelKeyword, string("VALIDATE"));
        $$ = res;
    }

    | VALIDATOR {
        res = new IR(kBareLabelKeyword, string("VALIDATOR"));
        $$ = res;
    }

    | VALUE_P {
        res = new IR(kBareLabelKeyword, string("VALUE"));
        $$ = res;
    }

    | VALUES {
        res = new IR(kBareLabelKeyword, string("VALUES"));
        $$ = res;
    }

    | VARCHAR {
        res = new IR(kBareLabelKeyword, string("VARCHAR"));
        $$ = res;
    }

    | VARIADIC {
        res = new IR(kBareLabelKeyword, string("VARIADIC"));
        $$ = res;
    }

    | VERBOSE {
        res = new IR(kBareLabelKeyword, string("VERBOSE"));
        $$ = res;
    }

    | VERSION_P {
        res = new IR(kBareLabelKeyword, string("VERSION"));
        $$ = res;
    }

    | VIEW {
        res = new IR(kBareLabelKeyword, string("VIEW"));
        $$ = res;
    }

    | VIEWS {
        res = new IR(kBareLabelKeyword, string("VIEWS"));
        $$ = res;
    }

    | VOLATILE {
        res = new IR(kBareLabelKeyword, string("VOLATILE"));
        $$ = res;
    }

    | WHEN {
        res = new IR(kBareLabelKeyword, string("WHEN"));
        $$ = res;
    }

    | WHITESPACE_P {
        res = new IR(kBareLabelKeyword, string("WHITESPACE"));
        $$ = res;
    }

    | WORK {
        res = new IR(kBareLabelKeyword, string("WORK"));
        $$ = res;
    }

    | WRAPPER {
        res = new IR(kBareLabelKeyword, string("WRAPPER"));
        $$ = res;
    }

    | WRITE {
        res = new IR(kBareLabelKeyword, string("WRITE"));
        $$ = res;
    }

    | XML_P {
        res = new IR(kBareLabelKeyword, string("XML"));
        $$ = res;
    }

    | XMLATTRIBUTES {
        res = new IR(kBareLabelKeyword, string("XMLATTRIBUTES"));
        $$ = res;
    }

    | XMLCONCAT {
        res = new IR(kBareLabelKeyword, string("XMLCONCAT"));
        $$ = res;
    }

    | XMLELEMENT {
        res = new IR(kBareLabelKeyword, string("XMLELEMENT"));
        $$ = res;
    }

    | XMLEXISTS {
        res = new IR(kBareLabelKeyword, string("XMLEXISTS"));
        $$ = res;
    }

    | XMLFOREST {
        res = new IR(kBareLabelKeyword, string("XMLFOREST"));
        $$ = res;
    }

    | XMLNAMESPACES {
        res = new IR(kBareLabelKeyword, string("XMLNAMESPACES"));
        $$ = res;
    }

    | XMLPARSE {
        res = new IR(kBareLabelKeyword, string("XMLPARSE"));
        $$ = res;
    }

    | XMLPI {
        res = new IR(kBareLabelKeyword, string("XMLPI"));
        $$ = res;
    }

    | XMLROOT {
        res = new IR(kBareLabelKeyword, string("XMLROOT"));
        $$ = res;
    }

    | XMLSERIALIZE {
        res = new IR(kBareLabelKeyword, string("XMLSERIALIZE"));
        $$ = res;
    }

    | XMLTABLE {
        res = new IR(kBareLabelKeyword, string("XMLTABLE"));
        $$ = res;
    }

    | YES_P {
        res = new IR(kBareLabelKeyword, string("YES"));
        $$ = res;
    }

    | ZONE {
        res = new IR(kBareLabelKeyword, string("ZONE"));
        $$ = res;
    }

;

%%

/*
 * The signature of this function is required by bison.  However, we
 * ignore the passed yylloc and instead use the last token position
 * available from the scanner.
 */
static void
base_yyerror(YYLTYPE *yylloc, IR* ir, core_yyscan_t yyscanner, const char *msg)
{
	parser_yyerror(msg);
}

/* parser_init()
 * Initialize to parse one query string
 */
void
parser_init(base_yy_extra_type *yyext)
{
	yyext->parsetree = NIL;		/* in case grammar forgets to set it */
}
