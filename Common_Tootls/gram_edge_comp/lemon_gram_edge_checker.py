import re
from loguru import logger
import json

total_edge_num = 0
all_rule_maps = dict()
all_hash_to_edge_maps = dict()

in_cov_parser_file = "./sqlite_lemon_parser_cov.y"

def handle_ori_comp_parser() -> str:
    # gather all the token information first. 
    global in_cov_parser_file

    file_fd = open(in_cov_parser_file)

    all_lines = file_fd.readlines()
    all_saved_lines = ""

    is_fallback_multiline = False
    is_def_ignore = False
    rule_is_read = False
    macro_is_read = True 

    for cur_line in all_lines:

        if "A = " in cur_line:
            all_saved_lines += cur_line + "\n"
            continue

        # ignore the #ifdef line and all the contents between
        if cur_line.startswith("%ifdef "):
            is_def_ignore = True
            continue
        if "%endif" in cur_line:
            if is_def_ignore == True:
                is_def_ignore = False
            macro_is_read = True
            continue
        if is_def_ignore == True:
            continue

        # ignore all the `#ifndef` line, but still save all the things between.
        if cur_line.startswith("%ifndef ")  or \
                cur_line.startswith("%endif"):
                    continue

        # For the fallback grammar
        if cur_line.startswith("%fallback "):
            all_saved_lines += cur_line
            is_fallback_multiline = True
            continue
        if cur_line.startswith("%token ") or cur_line.startswith("%token\n"):
            all_saved_lines += cur_line
            if "." not in cur_line:
                is_fallback_multiline = True
            continue
        if is_fallback_multiline and "." in cur_line:
            all_saved_lines += cur_line
            is_fallback_multiline = False
            continue
        if is_fallback_multiline == True:
            all_saved_lines += cur_line
            continue


        # All other saved types.
        if cur_line.startswith("%left ") or \
                cur_line.startswith("%right ") or \
                cur_line.startswith("%nonassoc ") or \
                cur_line.startswith("%wildcard ") or \
                cur_line.startswith("%token_class "):
            # the line contains the new line symbol
            all_saved_lines += cur_line
            continue

        if cur_line.startswith("%type "):
            # Change all the non-terminal types to unsigned int.
            cur_line = cur_line.split("{")[0]
            cur_line += "{unsigned int}\n"
            all_saved_lines += cur_line
            continue


        if macro_is_read == False:
            continue

        if "%else" in cur_line:
            macro_is_read = False
            continue
        
        if rule_is_read == True and "." in cur_line:
            cur_line = cur_line.split("{")[0]
            cur_line = re.sub("\n", "", cur_line)
            # remove all the bracket and the contents within.
            cur_line = re.sub("[\(].*?[\)]", "", cur_line)
            all_saved_lines += cur_line+"\n"
            rule_is_read = False
            continue

        if rule_is_read == True and "." not in cur_line:
            cur_line = re.sub("[\(].*?[\)]", "", cur_line)
            cur_line = re.sub("\n", "", cur_line)
            all_saved_lines+=cur_line
            continue

        if "::=" in cur_line and "." not in cur_line:
            cur_line = re.sub("[\(].*?[\)]", "", cur_line)
            cur_line = re.sub("\n", "", cur_line)
            all_saved_lines+=cur_line
            rule_is_read = True
            continue

        if "::=" in cur_line and "." in cur_line:
            cur_line = cur_line.split("{")[0]
            cur_line = re.sub("\n", "", cur_line)
            # remove all the bracket and the contents within.
            cur_line = re.sub("[\(].*?[\)]", "", cur_line)
            all_saved_lines+=cur_line+"\n"
            continue

    logger.debug("\n\n\nGetting all_saved_lines for token declaration : %s\n\n\n"%(all_saved_lines))

    file_fd.close()
    
    return all_saved_lines

def parse_single_rule(rule_line):

    cur_token_name = rule_line.split(" ::= ")[0]
    rule_line = rule_line.split(" ::= ")[1]
    rule_line = rule_line.split(".")[0]

    token_seq = rule_line.split()

    return (cur_token_name, token_seq)

def calc_total_edge_num():
    global all_rule_maps
    global all_hash_to_edge_maps
    global total_edge_num

    total_edge_num = 0


    tmp_hash_num = 0
    for cur_key, hash_and_token_seq_list in all_rule_maps.items():
        for hash_and_token_seq in hash_and_token_seq_list:

            cur_hash, cur_token_seq = hash_and_token_seq

            for cur_token in cur_token_seq:
                if cur_token in all_rule_maps:
                    child_hash_and_rules = all_rule_maps[cur_token]
                    for cur_hash_and_child_rule in child_hash_and_rules:
                        cur_child_hash = cur_hash_and_child_rule[0]
                        cur_child_token_seq = cur_hash_and_child_rule[1]
                        logger.debug("Begin\n\n\n")
                        calc_hash = (cur_child_hash >> 1) ^ cur_hash
                        logger.debug(f"Parent hash: {cur_hash}, Child hash: {cur_child_hash}, calc_hash: {calc_hash}\n")
                        if calc_hash in all_hash_to_edge_maps:
                            if all_hash_to_edge_maps[calc_hash][0] != cur_key:
                                logger.error("Error: Hash collision: %d\n"% calc_hash)
                                logger.error(f"Prev: {all_hash_to_edge_maps[calc_hash]}\n")
                                logger.error(f"Cur: {(cur_key, cur_token_seq, cur_token, cur_child_token_seq)}\n\n\n")
                        all_hash_to_edge_maps[calc_hash] = (cur_key, cur_token_seq, cur_token, cur_child_token_seq)
                        logger.debug(f"For hash: {calc_hash}, getting {all_hash_to_edge_maps[calc_hash]}\n")
                        logger.debug("END\n\n\n")

            logger.info("for %s, getting edge: %d" % (cur_key, len(all_hash_to_edge_maps) - tmp_hash_num))
            tmp_hash_num = len(all_hash_to_edge_maps)

    logger.info("Total edge number: %d" % len(all_hash_to_edge_maps))

def dump_all_hash_to_edge_maps():
    global all_hash_to_edge_maps

    with open("hash_to_edge_maps.json", "w") as out:
        out.write(json.dumps(all_hash_to_edge_maps, indent=2))

    with open("all_hash.txt", "w") as out:
        for cur_hash, _ in all_hash_to_edge_maps.items():
            out.write(f"{cur_hash}\n")


if __name__ == "__main__":
    cur_key = ""
    cur_token_seq = ""
    for cur_line in handle_ori_comp_parser().splitlines():
        logger.debug("Getting cur_line: %s" % cur_line)
        if "." in cur_line and " ::= " in cur_line:
            cur_key, cur_token_seq = parse_single_rule(cur_line)
            continue
        if "A = " in cur_line:
            cur_hash = cur_line.split("A = ")[1]
            cur_hash = cur_hash.split(";")[0]
            cur_hash = int(cur_hash)
            if cur_key in all_rule_maps:
                all_rule_maps[cur_key].append([cur_hash, cur_token_seq]) 
                logger.debug(f"Mapping: {cur_hash} to {cur_token_seq}\n")
            else:
                all_rule_maps[cur_key] = [[cur_hash, cur_token_seq]] 
                logger.debug(f"Mapping: {cur_hash} to {cur_token_seq}\n")

    print("Finished parsing the parser.")
    print("Getting all_rules_map: ")
    print(all_rule_maps)
    calc_total_edge_num()

    dump_all_hash_to_edge_maps()

            

