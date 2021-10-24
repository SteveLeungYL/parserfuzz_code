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
%token <str>	IDENT UIDENT FCONST SCONST USCONST BCONST XCONST Op
%token <ival>	ICONST PARAM
%token			TYPECAST DOT_DOT COLON_EQUALS EQUALS_GREATER
%token			LESS_EQUALS GREATER_EQUALS NOT_EQUALS

/*
 * If you want to make any keyword changes, update the keyword table in
 * src/include/parser/kwlist.h and add new keywords to the appropriate one
 * of the reserved-or-not-so-reserved keyword lists, below; search
 * this file for "Keyword category lists".
 */

/* ordinary key words in alphabetical order */
%token <keyword> ABORT_P ABSOLUTE_P ACCESS ACTION ADD_P ADMIN AFTER
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

/*
 *	The target production for the whole parse.
 *
 * Ordinarily we parse a list of statements, but if we see one of the
 * special MODE_XXX symbols as first token, we parse something else.
 * The options here correspond to enum RawParseMode, which see for details.
 */
parse_toplevel:
			stmtmulti
			{
				$$ = result;
				IR* tmp1 = $1;
				result->update_left(tmp1);
				$$ = NULL;
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
stmtmulti:	 ';' 
				{
					$$ = new IR(kStmtlist, OP3(";", "", ""));				
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
