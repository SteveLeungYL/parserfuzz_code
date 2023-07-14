import sys
import os.path
import json
from loguru import logger
from typing import List
import re

saved_ir_type = []

logger.remove()
logger.add(sys.stderr, level="DEBUG") # or sys.stdout or other file object

all_translated_types = []
all_rule_maps = dict()

total_edge_num = 0
total_block_num = 0

all_pos_edge_pair_fd = open("all_edge.txt", "w")

def rewrite_keyword_type_name(input: str) -> str:
    out = "Type"
    is_cap = True 
    for c in input:
        if is_cap == True:
            out += c.upper()
            is_cap = False
            continue
        elif c == "_":
            is_cap = True
            continue
        else:
            out += c
    return out

def is_terminating_keyword(word: str) -> bool:
    if "IDENT" in word:
        return False 
    elif "SCONST" in word or "BCONST" in word or "BITCONST" in word or "ICONST" in word or "FCONST" in word:
        return False 
    elif word.isupper():
        return True
    elif "'" in word:
        return True
    else:
        return False

def summarize_rules_text(all_saved_str: str):
    # gather all the token information first. 
    global all_rule_maps

    all_lines = all_saved_str.splitlines()

    cur_token_seq = ""
    cur_keyword = ""
    for cur_line in all_lines:
        if ":" in cur_line and "':'" not in cur_line:
            # Save previous token seq
            if not len(cur_keyword) == 0:
                if "error" in cur_token_seq or "keyword" in cur_token_seq:
                    pass
                elif cur_keyword not in all_rule_maps:
                    all_rule_maps[cur_keyword] = [cur_token_seq.split()]
                else:
                    all_rule_maps[cur_keyword].append(cur_token_seq.split())
                cur_token_seq = ""
            # Move to the new one.
            cur_keyword = cur_line.split(":")[0].strip()
            if len(cur_line.split(":")) == 1:
                continue
            cur_line = cur_line.split(":")[1]
        
        if "|" in cur_line:
            cur_token_seq += cur_line.split("|")[0]
            if "error" in cur_token_seq or "keyword" in cur_token_seq:
                    pass
            elif cur_keyword not in all_rule_maps:
                all_rule_maps[cur_keyword] = [cur_token_seq.split()]
            else:
                all_rule_maps[cur_keyword].append(cur_token_seq.split())
            cur_token_seq = ""

            cur_token_seq = ""
            cur_line = cur_line.split("|")[1]

        cur_token_seq += cur_line
    # Save the last one.
    all_rule_maps[cur_keyword].append(cur_token_seq.split())

def calc_total_edge_num():
    global all_pos_edge_pair_fd
    global all_rule_maps
    global total_edge_num

    total_edge_num = 0

    for cur_keyword, list_token_seq in all_rule_maps.items():
        for token_seq in list_token_seq:
            seen_token = []
            all_token_enum_num = 0
            for cur_token in token_seq:
                # if cur_token in all_rule_maps and not is_terminating_keyword(cur_token) and cur_token not in seen_token:
                if not is_terminating_keyword(cur_token) and cur_token not in seen_token:
                    seen_token.append(cur_token)
                    # all_token_enum_num += len(all_rule_maps[cur_token])
                    all_token_enum_num += 1
                    all_pos_edge_pair_fd.write(f"{rewrite_keyword_type_name(cur_keyword)},{rewrite_keyword_type_name(cur_token)}\n")

            total_edge_num += all_token_enum_num
            print("for keyword: %s, rule: %s, getting edge: %d, accumulative total: %d" % (cur_keyword, token_seq, all_token_enum_num, total_edge_num))

def run(input_fd):
    global total_block_num
    global total_edge_num

    input_str = input_fd.read()
    summarize_rules_text(input_str)
    # Summarize the total block number and total edge number
    calc_total_edge_num()
    logger.info("Total block num: %d, total edge num: %d.\n"% (total_block_num, total_edge_num))

    return

if __name__ == "__main__":

    input_file_str = "assets/cockroach_sql_modi.y"
    if len(sys.argv) == 2:
        input_file_str = sys.argv[1] 
    elif len(sys.argv) > 2:
        os.error("Usage: python3 calc_edge_cov.py cockroach_sql_removed_action_and_comments.y")

    if not os.path.isfile(input_file_str):
        os.error(f"Error: The input file: {input_file_str} is not exist. \n")

    with open(input_file_str, "r") as fd:
        run(fd)
