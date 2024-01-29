import os

rule_file_fd = open("./cockroach_sql.y", "r")
rule_file_str = rule_file_fd.read()

# Remove the prefix code
tmp_list = rule_file_str.split("%%")
rule_file_str = tmp_list[1]

parent_level = 0
comment_sign = 0
res_str = ""
for cur_char in rule_file_str:
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

rule_file_str = res_str

# Remove // comments
dest_str = ""
for cur_line in rule_file_str.splitlines():
    if "//" in cur_line:
        cur_line = cur_line.split("//")[0]
    dest_str += cur_line + "\n"
rule_file_str = dest_str


dest_str = ""
is_first_line = True
for cur_line in rule_file_str.splitlines():
    if cur_line.isspace() or len(cur_line) == 0:
        continue
    if ":" in cur_line and "':'" not in cur_line:
        if is_first_line:
            is_first_line = False
        else:
            dest_str += "\n; \n"
        dest_str += cur_line + "\n"
    else:
        dest_str += cur_line + "\n"
dest_str += "\n; \n"

modified_rule_fd = open("./cockroach_sql_modi.y", "w")
modified_rule_fd.write(dest_str)

