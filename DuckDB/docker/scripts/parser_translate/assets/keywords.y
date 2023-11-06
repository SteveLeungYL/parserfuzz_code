%type <node> stmt
%type <list> stmtblock
%type <list> stmtmulti
%type <range>	qualified_name
%type <str>		Sconst  ColId   ColLabel    ColIdOrString
%type <keyword> unreserved_keyword  reserved_keyword other_keyword
%type <list> indirection
%type <keyword> col_name_keyword
%type <node>    indirection_el
%type <str>	    attr_name%type <str> var_name
%type <str> table_id
%type <viewcheckoption> opt_check_option
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
%type <list> param_list
%type <str> file_name
%type <str> repo_path
%type <node>	select_no_parens select_with_parens select_clause
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
%type <boolean> opt_include_nulls%type <objtype> drop_type_any_name
%type <objtype> drop_type_name
%type <list> any_name_list
%type <dbehavior> opt_drop_behavior
%type <objtype> drop_type_name_on_any_name
%type <list> type_name_list
%type <list> prep_type_clause
%type <node> PreparableStmt
%type <boolean> opt_verbose
%type <node> explain_option_arg
%type <node> ExplainableStmt
%type <str> NonReservedWord
%type <str> NonReservedWord_or_Sconst
%type <list> explain_option_list
%type <str> opt_boolean_or_string
%type <defelt> explain_option_elem
%type <str> explain_option_name
%type <list> OptSeqOptList
%type <range> relation_expr_opt_alias
%type <node> where_or_current_clause
%type <list> using_clause
%type <list> OptSchemaEltList
%type <node> schema_stmt
%type <ival> opt_column%type <ival> ConstraintAttributeSpec
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
%type <vsetstmt> set_rest
%type <vsetstmt> generic_set
%type <node> var_value
%type <node> zone_value
%type <list> var_list
%type <str> access_method
%type <str> access_method_clause
%type <boolean> opt_concurrently
%type <str> opt_index_name
%type <list> opt_reloptions
%type <boolean> opt_unique
%type <str> opt_col_id
%type <vsetstmt> generic_reset
%type <vsetstmt> reset_rest
%type <list> SeqOptList
%type <value> NumericOnly
%type <defelt> SeqOptElem
%type <ival> SignedIconst
%type <list> execute_param_clause
%type <list> execute_param_list
%type <node> execute_param_expr%type <ival> vacuum_option_elem
%type <boolean> opt_full
%type <ival> vacuum_option_list
%type <boolean> opt_freeze
%type <boolean> opt_with_data
%type <into> create_as_target
%type <boolean> copy_from
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
%type <list> opt_enum_val_list
%type <list> enum_val_list
%type <str> opt_database_alias
%type <list> ident_list ident_name
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