import os

all_func_sig = []

with open("../mysql_func_opr_sign", "r") as in_file:
    func_type = ""
    func_name = ""
    func_arg_num = 0
    for cur_line in in_file.read().splitlines():
        if "TYPE: " in cur_line:
            func_type = cur_line.split("TYPE: ")[-1]
            continue
        elif "grab_signature(description): " in cur_line:
            tmp = cur_line.split("grab_signature(description): ")[1]
            func_name = tmp.split("(")[0]

            if len(tmp.split("(")) == 1:
                func_arg_num = 0
                all_func_sig.append([func_type, func_name, func_arg_num])
                continue
            else:
                arg_str = tmp.split("(")[1]
                arg_str = arg_str.split(")")[0]
                if len(arg_str) == 0:
                    func_arg_num = 0
                    all_func_sig.append([func_type, func_name, func_arg_num])
                    continue
                else:
                    func_arg_num = len(arg_str.split(","))
                    all_func_sig.append([func_type, func_name, func_arg_num])
                    continue

for cur_func_sig in all_func_sig:
    print(cur_func_sig)

with open("../mysql_func_opr_sign.csv", "w") as out_file:
    out_file.write(f"type,name,argnum\n")
    for cur_func_sig in all_func_sig:
        out_file.write(f"\"{cur_func_sig[0]}\",{cur_func_sig[1]},{cur_func_sig[2]}\n")
