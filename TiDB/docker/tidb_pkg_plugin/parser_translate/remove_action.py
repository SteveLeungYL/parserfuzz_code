import os
import re

grammar_fd = open("sql_yacc.yy", "r")

grammar_str = grammar_fd.read()

parent_level = 0
res_str = ""
for cur_char in grammar_str:
    if cur_char == '{':
        parent_level += 1
        continue
    elif cur_char == '}':
        parent_level -= 1
        continue
    elif parent_level != 0:
        continue
    else:
        res_str += cur_char

out_fd = open("sql_yacc_modified.yy", "w")
out_fd.write(res_str)
