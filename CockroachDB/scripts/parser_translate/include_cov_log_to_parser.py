import os
import re

def gen_cov_logging_func_call(cur_keyword, token_seq: str) -> str:
    res_str = ""
    if "%prec" in token_seq:
        token_seq = token_seq.split("%prec")[0]
    token_seq = token_seq.split()
    for cur_token in token_seq:
        if cur_token.islower():
            #TODO: Change to Type representation instead of reuse the original keyword string?
            res_str += f"LogGrammarCoverage(\"{cur_keyword},{cur_token}\")\n"
    return res_str

grammar_fd = open("assets/cockroach_sql.y", "r")

grammar_str = grammar_fd.read()
tmp_res_str = ""

is_slash_blocked = False
is_star_comment_blocked = False

# Remove comments first.
for idx in range(len(grammar_str)):
    if grammar_str[idx] == "\n" and is_slash_blocked == True:
        is_slash_blocked = False
        # continue
    elif grammar_str[idx] == '/' and grammar_str[idx-1] == '*':
        is_star_comment_blocked = False
        continue
    elif is_slash_blocked or is_star_comment_blocked:
        continue
    elif grammar_str[idx] == '/' and grammar_str[idx+1] == '*':
        is_star_comment_blocked = True
        continue
    elif grammar_str[idx] == '/' and grammar_str[idx+1] == '/':
        is_slash_blocked = True
        continue
    tmp_res_str += grammar_str[idx]

tmp_str = ""

# Remove the prefix spacing. 
for cur_line in tmp_res_str.splitlines():
    if cur_line.startswith(" |"):
        cur_line = cur_line[1:]
    if cur_line.startswith("  |"):
        cur_line = cur_line[2:]
    tmp_str += cur_line + "\n"
tmp_res_str = tmp_str

parser_prefix_str = tmp_res_str.split("%%")[0]
parser_rule_str = tmp_res_str.split("%%")[1]

cur_keyword_has_rules = True
res_has_cov = ""
cur_token_seq = ""
cur_keyword = ""
all_rule_maps = dict()

parent_level = 0

print(parser_rule_str)

for cur_line in parser_rule_str.splitlines():
    if ":" in cur_line and "':'" not in cur_line and parent_level == 0:

        is_mistake = False
        if "{" in cur_line:
            for idx in range(len(cur_line)):
                if cur_line[idx] == "{":
                    is_mistake = True
                    break
                if cur_line[idx] == ":":
                    is_mistake = False
                    break
        if is_mistake == False:
            # This is a new token line. 
            if cur_keyword_has_rules == False and len(cur_keyword) != 0:
                res_has_cov += "{\n" + gen_cov_logging_func_call(cur_keyword=cur_keyword, token_seq=cur_token_seq) + "\n}\n"
                cur_token_seq = ""
            cur_keyword = cur_line.split(":")[0]
            cur_keyword_has_rules = False

            res_has_cov += cur_keyword + ":"
            cur_line = ":".join(cur_line.split(":")[1:])
            # always write to the result rules now. do not run 'continue'
    
    if "|" in cur_line and parent_level == 0:
        cur_token_seq += cur_line.split("|")[0]
        if "error" in cur_token_seq or "keyword" in cur_token_seq:
                pass
        elif cur_keyword not in all_rule_maps:
            all_rule_maps[cur_keyword] = [cur_token_seq.split()]
        else:
            all_rule_maps[cur_keyword].append(cur_token_seq.split())

        if cur_keyword_has_rules == False:
            res_has_cov += "{\n" + gen_cov_logging_func_call(cur_keyword=cur_keyword, token_seq=cur_token_seq) + "\n}\n"
        cur_token_seq = ""
        res_has_cov += cur_line.split("|")[0] + "|"

        cur_line = "|".join(cur_line.split("|")[1:])
        cur_keyword_has_rules = False

    saving_token = True
    is_add_gram_cov = False
    for cur_char_idx in range(len(cur_line)):
        cur_char = cur_line[cur_char_idx]
        if cur_char == '{' and cur_line[cur_char_idx-1] != "'":
            parent_level += 1
            saving_token = False
            # res_has_cov += f"parent_level: {parent_level}"

            if parent_level == 1:
                is_add_gram_cov = True
                # Trigger the ending of one single rule action.
                cur_keyword_has_rules = True

        elif cur_char == '}' and cur_line[cur_char_idx-1] != "'":
            parent_level -= 1
            # res_has_cov += f"parent_level: {parent_level}"

        # if parent_level < 0:
            # print(f"Error: parent: {parent_level}, {cur_char}, keyword: {cur_keyword}, token_seq: {cur_token_seq}\n")
            # exit(1)

        res_has_cov += cur_char

        if is_add_gram_cov == True:
            # Trigger the ending of one single rule action.
            cur_keyword_has_rules = True
            res_has_cov += "\n" + gen_cov_logging_func_call(cur_keyword=cur_keyword, token_seq=cur_token_seq) + "\n"
            cur_token_seq = ""
            is_add_gram_cov = False

        if parent_level == 0 and saving_token == True and cur_char != "}":
            cur_token_seq += cur_char

    res_has_cov += "\n"

tmp_res_str = res_has_cov
res_has_cov = ""

for cur_line in tmp_res_str.splitlines():
    if cur_line.isspace() or len(cur_line) == 0:
        continue
    res_has_cov += cur_line + "\n"

out_fd = open("test_modi.y", "w")
out_fd.write(res_has_cov)
