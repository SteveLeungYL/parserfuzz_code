import os
from typing import List
from translate_utils import Token

def handle_col_id_and_string(cur_token: Token, parent: str, token_sequence: List[str], ir_ref: str) -> (str, str):
    if parent == "qualified_name":
        # Handled by qualified_name
        return "", ""
    elif parent == "single_pivot_value" or parent == "pivot_value" or parent == "unpivot_header":
        return "kDataColumnName", "kUse"
    elif parent == "alias_clause" or parent == "func_alias_clause":
        # Handled by alias_clause and func_alias_clause
        return "", ""
    elif parent == "TableFuncElement":
        return "kDataColumnName", "kUse"
    elif parent == "dict_arg":
        return "kDataDictArg", "kCreate"
    elif parent == "name":
        # handled by name
        return "", ""
    else:
        # print(parent)
        # print(token_sequence)
        # print("\n\n")
        return "", ""

def handle_name(cur_token: Token, parent: str, token_sequence: List[str], ir_ref: str) -> (str, str):
    if parent == "alter_table_cmd" and token_sequence.count("ALTER")  and token_sequence.count("CONSTRAINT"):
        return "kDataConstraintName", "kUse"
    elif parent == "alter_table_cmd" and token_sequence.count("VALIDATE") and token_sequence.count("CONSTRAINT"):
        return "kDataConstraintName", "kUse"
    elif parent == "alter_table_cmd" and token_sequence.count("DROP") and token_sequence.count("CONSTRAINT"):
        return "kDataConstraintName", "kUndefine"
    elif parent == "DeallocateStmt":
        return "kDataPrepareName", "kUndefine"
    elif parent == "RenameStmt":
        data_type = ""
        if token_sequence.count("SCHEMA"):
            data_type = "kDataDatabase"
        elif token_sequence.count("TABLE") and not token_sequence.count("opt_column") and not token_sequence.count("CONSTRAINT"):
            data_type = "kDataTableName"
        elif token_sequence.count("SEQUENCE"):
            data_type = "kDataSequenceName"
        elif token_sequence.count("VIEW"):
            data_type = "kDataViewName"
        elif token_sequence.count("INDEX"):
            data_type = "kDataIndexName"
        elif token_sequence.count("INDEX"):
            data_type = "kDataIndexName"
        elif token_sequence.count("TABLE") and token_sequence.count("opt_column"):
            data_type = "kDataColumnName"
        elif token_sequence.count("TABLE") and token_sequence.count("CONSTRAINT"):
            data_type = "kDataConstraintName"
        else:
            print("ERROR")
            exit(1)

        data_flag = ""
        if cur_token.index != (len(token_sequence) - 1):
            data_flag = "kUndefine"
        else:
            data_flag = "kDefine"

        return data_type, data_flag

    elif parent == "opt_conf_expr":
        return "kDataConstraintName", "kUse"
    elif parent == "ExecuteStmt":
        return "kDataPrepareName", "kUse"
    elif parent == "ColConstraint":
        return "kDataConstraintName", "kUse"
    elif parent == "ColConstraintElem":
        return "kDataCompressionName", "kUse"
    elif parent == "TableConstraint":
        return "kDataConstraintName", "kUse"
    elif parent == "DropStmt":
        # handled by DropStmt
        return "", ""
    elif parent == "simple_select":
        return "kDataTableName", "kCreate"
    elif parent == "common_table_expr":
        return "kDataAliasTableName", "kCreate"
    elif parent == "name_list":
        # handled by name_list
        return "", ""
    elif parent == "PrepareStmt":
        return "kDataPrepareName", "kCreate"
    elif parent == "AlterObjectSchemaStmt":
        return "kDataDatabase", "kUse"

    else:
        # print(parent)
        # print(token_sequence)
        # print("\n\n")
        return "", ""


def handle_drop_stmt(cur_token: Token, parent: str, token_sequence: List[str], ir_ref: str) -> str:
    return f"setup_drop_stmt({ir_ref}); \n"

def handle_name_list(cur_token: Token, parent: str, token_sequence: List[str], ir_ref: str) -> str:

    if parent == "DropStmt" and token_sequence.count("drop_type_name"):
        # handled by DropStmt
        # TODO: Not implemented yet.
        return ""
    elif parent == "name_list":
        # handled by itself.
        return ""
    elif parent == "name_list_opt_comma":
        # handled by name_list_opt_comma.
        return ""
    else:
        print(parent)
        print(token_sequence)
        print("\n\n")
        return ""

def handle_name_list_opt_comma(cur_token: Token, parent: str, token_sequence: List[str], ir_ref: str) -> str:
    data_type = "kDataWhatever"
    data_flag = "kFlagUnknown"

    if parent == "opt_pivot_group_by":
        data_type = "kDataColumnName"
        data_flag = "kUse"
    elif parent == "unpivot_header":
        data_type = "kDataColumnName"
        data_flag = "kUse"
    elif parent == "alias_clause":
        # handled by alias_clause
        return ""
    elif parent == "join_qual":
        data_type = "kDataColumnName"
        data_flag = "kUse"
    elif parent == "except_list":
        data_type = "kDataColumnName"
        data_flag = "kUse"
    elif parent == "name_list_opt_comma_opt_bracket":
        # handled by name_list_opt_comma_opt_bracket
        return ""
    elif parent == "opt_name_list":
        # handled by opt_name_list
        return ""
    else:
        print(parent)
        print(token_sequence)
        print("\n\n")
        return ""

    return f"setup_name_list_opt_comma({ir_ref}, {data_type}, {data_flag}); \n"

def handle_name_list_opt_comma_opt_bracket(cur_token: Token, parent: str, token_sequence: List[str], ir_ref: str) -> str:

    data_type = ""
    data_flag = ""

    if parent == "simple_select":
        data_type = "kDataColumnName"
        data_flag = "kUse"
    else:
        print(parent)
        print(token_sequence)
        print("\n\n")
        return ""

    if data_type != "" or data_flag != "":
        return f"setup_name_list_opt_comma_opt_bracket({ir_ref}, {data_type}, {data_flag}); \n"
    else:
        return ""

def handle_opt_name_list(cur_token: Token, parent: str, token_sequence: List[str], ir_ref: str) -> str:

    if parent == "common_table_expr":
        data_type = "kDataAliasName"
        data_flag = "kCreate"
    elif parent == "VacuumStmt":
        data_type = "kDataColumnName"
        data_flag = "kUse"
    elif parent == "AnalyzeStmt":
        data_type = "kDataColumnName"
        data_flag = "kUse"
    else:
        # print(parent)
        # print(token_sequence)
        # print("\n\n")
        return ""

    return f"setup_opt_name_list({ir_ref}, {data_type}, {data_flag}); \n"

def handle_qualified_name(cur_token: Token, parent: str, token_sequence: List[str], ir_ref: str) -> str:
    data_type = ""
    data_type_par = "kDataWhatever"
    data_type_par_par = "kDataWhatever"
    data_flag = ""

    if parent == "AlterTableStmt" and token_sequence.count("ALTER") and token_sequence.count("INDEX"):
        data_type = "kDataIndexName"
        data_type_par = "kDataTableName"
        data_type_par_par = "kDataDatabase"
        data_flag = "kUse"
    elif parent == "AlterTableStmt" and token_sequence.count("ALTER") and token_sequence.count("SEQUENCE"):
        data_type = "kDataSequenceName"
        data_type_par = "kDataTableName"
        data_type_par_par = "kDataDatabase"
        data_flag = "kUse"
    elif parent == "AlterTableStmt" and token_sequence.count("ALTER") and token_sequence.count("VIEW"):
        data_type = "kDataViewName"
        data_type_par = "kDataTableName"
        data_type_par_par = "kDataDatabase"
        data_flag = "kUsed"
    elif parent == "RenameStmt" and token_sequence.count("ALTER") and token_sequence.count("INDEX"):
        data_type = "kDataIndexName"
        data_type_par = "kDataTableName"
        data_type_par_par = "kDataDatabase"
        data_flag = "kUndefine"
    elif parent == "RenameStmt" and token_sequence.count("ALTER") and token_sequence.count("SEQUENCE"):
        data_type = "kDataSequenceName"
        data_type_par = "kDataTableName"
        data_type_par_par = "kDataDatabase"
        data_flag = "kUndefine"
    elif parent == "RenameStmt" and token_sequence.count("ALTER") and token_sequence.count("VIEW"):
        data_type = "kDataViewName"
        data_type_par = "kDataTableName"
        data_type_par_par = "kDataDatabase"
        data_flag = "kUndefine"
    elif parent == "insert_target":
        data_type = "kDataColumnName"
        data_type_par = "kDataTableName"
        data_type_par_par = "kDataDatabase"
        data_flag = "kUse"
    elif parent == "CreateTypeStmt":
        data_type = "kDataTypeName"
        data_type_par = "kDataTableName"
        data_type_par_par = "kDataDatabase"
        data_flag = "kCreate"
    elif parent == "CreateSeqStmt":
        data_type = "kDataSequenceName"
        data_type_par = "kDataTableName"
        data_type_par_par = "kDataDatabase"
        data_flag = "kCreate"
    elif parent == "AlterSeqStmt":
        data_type = "kDataSequenceName"
        data_type_par = "kDataTableName"
        data_type_par_par = "kDataDatabase"
        data_flag = "kUse"
    elif parent == "UseStmt":
        data_type = "kDataSchemaName"
        data_type_par = "kDataDatabase"
        # data_type_par_par = "kDataDatabase"
        data_flag = "kUse"
    elif parent == "CreateStmt":
        data_type = "kDataTableName"
        data_type_par = "kDataSchemaName"
        data_type_par_par = "kDataDatabase"
        data_flag = "kCreate"
    elif parent == "ColConstraintElem" or parent == "ConstraintElem":
        data_type = "kDataTableName"
        data_type_par = "kDataSchemaName"
        data_type_par_par = "kDataDatabase"
        data_flag = "kUse"
    elif parent == "TableLikeClause":
        data_type = "kDataTableName"
        data_type_par = "kDataSchemaName"
        data_type_par_par = "kDataDatabase"
        data_flag = "kUse"
    elif parent == "CreateFunctionStmt":
        data_type = "kDataFunctionName"
        data_type_par = "kDataSchemaName"
        data_type_par_par = "kDataDatabase"
        data_flag = "kCreate"
    elif parent == "CopyStmt":
        data_type = "kDataTableName"
        data_type_par = "kDataSchemaName"
        data_type_par_par = "kDataDatabase"
        data_flag = "kUse"
    elif parent == "OptTempTableName":
        data_type = "kDataTableName"
        data_type_par = "kDataSchemaName"
        data_type_par_par = "kDataDatabase"
        data_flag = "kCreate"
    elif parent == "relation_expr":
        # handled by relation_expr
        return ""
    elif parent == "qualified_name_list":
        # handled by qualified_name_list
        return ""
    elif parent == "CreateSchemaStmt":
        data_type = "kDataSchemaName"
        data_type_par = "kDataDatabase"
        # data_type_par_par = "kDataDatabase"
        data_flag = "kCreate"
    elif parent == "IndexStmt":
        data_type = "kDataTableName"
        data_type_par = "kDataSchemaName"
        data_type_par_par = "kDataDatabase"
        data_flag = "kUse"
    elif parent == "AlterObjectSchemaStmt" and token_sequence.count("ALTER") and token_sequence.count("SEQUENCE"):
        data_type = "kDataSequenceName"
        data_type_par = "kDataSchemaName"
        data_type_par_par = "kDataDatabase"
        data_flag = "kUse"
    elif parent == "AlterObjectSchemaStmt" and token_sequence.count("ALTER") and token_sequence.count("VIEW"):
        data_type = "kDataViewName"
        data_type_par = "kDataSchemaName"
        data_type_par_par = "kDataDatabase"
        data_flag = "kUse"
    elif parent == "VacuumStmt" or parent == "AnalyzeStmt":
        data_type = "kDataTableName"
        data_type_par = "kDataSchemaName"
        data_type_par_par = "kDataDatabase"
        data_flag = "kUse"
    elif parent == "ViewStmt":
        data_type = "kDataViewName"
        data_type_par = "kDataSchemaName"
        data_type_par_par = "kDataDatabase"
        data_flag = "kCreate"
    elif parent == "create_as_target":
        data_type = "kDataTableName"
        data_type_par = "kDataSchemaName"
        data_type_par_par = "kDataDatabase"
        data_flag = "kCreate"
    else:
        print(parent)
        print(token_sequence)
        print("\n\n")

    if data_type != "" or data_flag != "":
        return f"setup_qualified_name({ir_ref}, {data_type}, {data_flag}, {data_type_par}, {data_type_par_par}); \n"
    else:
        return ""

def handle_qualified_name_list(cur_token: Token, parent: str, token_sequence: List[str], ir_ref: str) -> (str, str):
    # TODO:: WIP
    return "", ""

def handle_index_name(cur_token: Token, parent: str, token_sequence: List[str], ir_ref: str) -> (str, str):
    # TODO:: WIP
    return "", ""

def handle_relation_expr(cur_token: Token, parent: str, token_sequence: List[str], ir_ref: str) -> (str, str):
    # TODO:: WIP
    return "", ""

def handle_opt_index_name(cur_token: Token, parent: str, token_sequence: List[str], ir_ref: str) -> (str, str):
    # TODO:: WIP
    return "", ""

def handle_col_label(cur_token: Token, parent: str, token_sequence: List[str], ir_ref: str) -> (str, str):
    # TODO:: WIP
    return "", ""

def handle_attr_name(cur_token: Token, parent: str, token_sequence: List[str], ir_ref: str) -> (str, str):
    # TODO:: WIP
    return "", ""

def handle_opt_column_list(cur_token: Token, parent: str, token_sequence: List[str], ir_ref: str) -> (str, str):
    # TODO:: WIP
    return "", ""

def handle_column_list(cur_token: Token, parent: str, token_sequence: List[str], ir_ref: str) -> (str, str):
    # TODO:: WIP
    return "", ""


def handle_column_list_opt_comma(cur_token: Token, parent: str, token_sequence: List[str], ir_ref: str) -> (str, str):
    # TODO:: WIP
    return "", ""

def handle_alias_clause(cur_token: Token, parent: str, token_sequence: List[str], ir_ref: str) -> (str, str):
    # TODO:: WIP
    return "", ""

def handle_opt_alias_clause(cur_token: Token, parent: str, token_sequence: List[str], ir_ref: str) -> (str, str):
    # TODO:: WIP
    return "", ""

def handle_func_alias_clause(cur_token: Token, parent: str, token_sequence: List[str], ir_ref: str) -> (str, str):
    # TODO:: WIP
    return "", ""

def handle_any_name(cur_token: Token, parent: str, token_sequence: List[str], ir_ref: str) -> (str, str):
    # TODO:: WIP
    return "", ""

def handle_table_id(cur_token: Token, parent: str, token_sequence: List[str], ir_ref: str) -> str:
    res = ""
    if len(token_sequence) == 3 and parent == "table_id":
        res += f"setup_table_id({ir_ref}, kDataDatabase, kUse); \n"
    return res


def handle_col_id(cur_token: Token, parent: str, token_sequence: List[str], ir_ref: str) -> (str, str):

    if token_sequence.count("ALTER") and token_sequence.count("opt_column") and (token_sequence.count("alter_column_default") or token_sequence.count("alter_identity_column_option_list")):
        return "kDataColumnName", "kUse"
    elif token_sequence.count("ALTER") and token_sequence.count("opt_column") and token_sequence.count("NOT") and token_sequence.count("NULL"):
        return "kDataColumnName", "kUse"
    elif token_sequence.count("ALTER") and token_sequence.count("opt_column") and (token_sequence.count("reloptions") or token_sequence.count("STATISTICS")):
        return "kDataColumnName", "kUse"
    elif token_sequence.count("ALTER") and token_sequence.count("opt_column") and token_sequence.count("SET") and token_sequence.count("STORAGE"):
        if cur_token.index == 2:
            return "kDataColumnName", "kUse"
        else:
            return "kDataStorageName", "kUse"
    elif token_sequence.count("ALTER") and token_sequence.count("opt_column") and token_sequence.count("ADD") and token_sequence.count("GENERATED"):
        return "kDataColumnName", "kUse"
    elif token_sequence.count("ALTER") and token_sequence.count("opt_column") and token_sequence.count("DROP") and token_sequence.count("IDENTITY"):
        return "kDataColumnName", "kUse"
    elif token_sequence.count("DROP") and token_sequence.count("opt_column") and token_sequence.count("opt_drop_behavior"):
        # DROP COLUMN
        return "kDataColumnName", "kUndefine"
    elif token_sequence.count("ALTER") and token_sequence.count("opt_column") and token_sequence.count("TYPE_P") and token_sequence.count("alter_using"):
        return "kDataColumnName", "kUse"
    elif token_sequence.count("ALTER") and token_sequence.count("opt_column") and token_sequence.count("alter_generic_options"):
        return "kDataColumnName", "kUse"
    elif parent == "qualified_name":
        # qualified_name, leave it to the qulified_name handler
        return "", ""
    elif parent == "ColIdOrString":
        # ColIdOrString, leave it to the ColIdOrString handler
        return "", ""
    elif parent == "insert_target" and token_sequence.count("AS") and token_sequence.count("qualified_name"):
        return "kDataAliasName", "kCreate"
    elif parent == "insert_column_item":
        return "kDataColumnName", "kUse"
    elif parent == "index_elem":
        return "kDataColumnName", "kUse"
    elif parent == "set_target":
        return "kDataPragmaKey", "kUse"
    elif parent == "PragmaStmt":
        return "kDataPragmaKey", "kUse"
    elif parent == "PragmaStmt":
        return "kDataPragmaKey", "kUse"
    elif parent == "columnDef":
        return "kDataColumnName", "kDefine"
    elif parent == "index_name":
        # index_name and opt_index_name, leave it to index_name handler.
        return "", ""
    elif parent == "columnElem":
        # handled by columnlist.
        return "", ""
    elif parent == "opt_sample_func" or parent == "tablesample_entry":
        return "kDataSampleFunction", "kUse"
    elif parent == "alias_clause" or parent == "func_alias_clause":
        # handled by alias_clause and func_alias_clause
        return "", ""
    elif parent == "colid_type_list":
        return "kDataColumnName", "kUse"
    elif parent == "a_expr":
        return "kDataTableName", "kUse"
    elif parent == "a_expr":
        return "kDataTableName", "kUse"
    elif parent == "list_comprehension":
        return "kDataAliasName", "kDefine"
    elif parent == "window_definition":
        return "kDataWindowName", "kDefine"
    elif parent == "over_clause":
        return "kDataWindowName", "kUse"
    elif parent == "opt_existing_window_name":
        return "kDataWindowName", "kUse"
    elif parent == "any_operator":
        # Not sure.
        return "kDataColumnName", "kUse"
    elif parent == "columnref":
        return "kDataColumnName", "kUse"
    elif parent == "except_list":
        return "kDataColumnName", "kUse"
    elif parent == "replace_list_el":
        return "kDataAliasName", "kDefine"
    elif parent == "func_name":
        return "kDataFunctionName", "kUse"
    elif parent == "any_name":
        # handled by any_name
        return "", ""
    elif parent == "access_method":
        return "kDataAccessMethod", "kUse"
    elif parent == "opt_col_id":
        return "kDataCheckPointName", "kUse"
    elif parent == "ExportStmt":
        return "kDataDatabase", "kUse"
    elif parent == "file_name":
        return "kFileName", "kUse"
    elif parent == "repo_path":
        return "kRepoPath", "kUse"
    elif parent == "relation_expr_opt_alias":
        return "kDataAliasTableName", "kCreate"
    elif parent == "opt_database_alias":
        return "kDataDatabase", "kCreate"
    elif parent == "var_name":
        # not accurate
        return "kDataPragmaKey", "kUse"
    elif parent == "table_id":
        # not accurate
        return "kDataTableName", "kUse"
    else:
        print(parent)
        print(token_sequence)
        print("\n\n")
        return "", ""

def setup_identifier_semantics(cur_token: Token, parent: str, token_sequence: List[str], ir_ref: str) -> str:

    res = ""
    if cur_token.word == "ColId":
        data_type, data_flag = handle_col_id(cur_token, parent, token_sequence, ir_ref)
        if data_type != "" and data_flag != "":
            res += f"setup_col_id({ir_ref}, {data_type}, {data_flag}); \n"

    elif cur_token.word == "table_id":
        res += handle_table_id(cur_token, parent, token_sequence, ir_ref)

    elif cur_token.word == "ColIdOrString":
        data_type, data_flag = handle_col_id_and_string(cur_token, parent, token_sequence, ir_ref)
        res += f"setup_col_id_or_string({ir_ref}, {data_type}, {data_flag}); \n"

    elif cur_token.word == "name":
        data_type, data_flag = handle_name(cur_token, parent, token_sequence, ir_ref)
        res += f"setup_name({ir_ref}, {data_type}, {data_flag}); \n"

    elif cur_token.word == "name_list":
        res += handle_name_list(cur_token, parent, token_sequence, ir_ref)

    elif cur_token.word == "name_list_opt_comma":
        res += handle_name_list_opt_comma(cur_token, parent, token_sequence, ir_ref)

    elif cur_token.word == "name_list_opt_comma_opt_bracket":
        res += handle_name_list_opt_comma_opt_bracket(cur_token, parent, token_sequence, ir_ref)

    elif cur_token.word == "opt_name_list":
        res += handle_opt_name_list(cur_token, parent, token_sequence, ir_ref)

    elif cur_token.word == "DropStmt":
        res += handle_drop_stmt(cur_token, parent, token_sequence, ir_ref)

    elif cur_token.word == "qualified_name":
        res += handle_qualified_name(cur_token, parent, token_sequence, ir_ref)


    return res