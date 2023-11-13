import os
from typing import List
from translate_utils import Token

def handle_qualified_name(cur_token: Token, parent: str, token_sequence: List[str], ir_ref: str) -> (str, str):
    # TODO:: WIP
    return "", ""

def handle_col_id_and_string(cur_token: Token, parent: str, token_sequence: List[str], ir_ref: str) -> (str, str):
    # TODO:: WIP
    return "", ""

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


    print(parent)
    print(token_sequence)
    print("\n\n")
    return "", ""

def setup_identifier_semantics(cur_token: Token, parent: str, token_sequence: List[str], ir_ref: str) -> str:

    res = ""
    data_type = ""
    data_flag = ""
    if cur_token.word == "ColId":
        data_type, data_flag = handle_col_id(cur_token, parent, token_sequence, ir_ref)
    elif cur_token.word == "qualified_name":
        # TODO:: WIP
        data_type, data_flag = handle_qualified_name(cur_token, parent, token_sequence, ir_ref)
    elif cur_token.word == "ColIdOrString":
        # TODO:: WIP
        data_type, data_flag = handle_col_id_and_string(cur_token, parent, token_sequence, ir_ref)

    if data_type != "" or data_flag != "":
        res += f"setup_col_id({ir_ref}, {data_type}, {data_flag}); \n"

    return res