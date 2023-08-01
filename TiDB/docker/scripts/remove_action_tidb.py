import re

grammar_fd = open("assets/tidb_parser.y", "r")

grammar_str = grammar_fd.read()

grammar_str = grammar_str.split("%%")[1]

parent_level = 0
res_str = ""
prev_char = ""
idx = 0
for cur_char in grammar_str:
    if cur_char == '{':
        parent_level += 1
    elif cur_char == '}':
        parent_level -= 1
    elif cur_char == "/" and (idx + 1) < len(grammar_str) and grammar_str[idx+1] == "*":
        parent_level += 1
    elif cur_char == "/" and (idx - 1) >= 0 and grammar_str[idx-1] == "*":
        parent_level -= 1
    elif parent_level != 0:
        pass
    else:
        res_str += cur_char

    idx += 1

# res_str = re.sub(r"//.*\n", "\n", res_str)
res_str_tmp = ""
for cur_line in res_str.splitlines():
    if cur_line.isspace():
        continue
    if ":" in cur_line:
        if "//" in cur_line:
            commentIdx = cur_line.index("//")
            commaIdx = cur_line.index(":")
            print("Getting commentIdx: %d, commaIdx: %d\n"%(commentIdx, commaIdx))
            if commaIdx < commentIdx:
                res_str_tmp += ";\n"
        else:
            res_str_tmp += ";\n"

    res_str_tmp += cur_line + "\n"
res_str_tmp += ";\n"
res_str = res_str_tmp

res_str = res_str.replace("\"", "'")

out_fd = open("assets/tidb_parser_modi.y", "w")
out_fd.write(res_str)
