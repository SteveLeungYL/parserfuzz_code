import os
from typing import List

def setup_identifier_semantics(cur_token: str, parent: str, token_sequence: List[str], ir_ref: str) -> str:

    res = ""
    data_type = ""
    data_flag = ""
    if cur_token == "ColId":
        data_type = "kDataWhatever"
        data_flag = "kUse"

        print(f"Token Sequence: {token_sequence}\n\n\n")

    if data_type != "" or data_flag != "":
        res += f"setup_col_id({ir_ref}, {data_type}, {data_flag}); \n"

    return res