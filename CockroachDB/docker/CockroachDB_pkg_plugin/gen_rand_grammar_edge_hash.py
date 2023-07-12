import os
import random

for root, _, all_files in os.walk("./tree"):
    for cur_file in all_files:
        cur_file = os.path.join(root, cur_file)

        res_str = ""
        is_modi = False
        with open(cur_file, "r") as cur_in:
            cur_in_lines = cur_in.read().splitlines()
            for cur_line in cur_in_lines:
                if "&SQLRightIR{" in cur_line and "//root" not in cur_line and "//	root" not in cur_line:
                    cur_line = cur_line.replace("&SQLRightIR{", f"&SQLRightIR{{\nNodeHash: {random.randint(0, 262143)}, ")
                    is_modi = True
                if "rootIR.IRType = " in cur_line:
                    res_str += f"rootIR.NodeHash = {random.randint(0, 262143)}\n"
                    is_modi = True
                if "tmpIR.IRType = " in cur_line:
                    res_str += f"rootIR.NodeHash = {random.randint(0, 262143)}\n"
                    is_modi = True
                res_str += cur_line + "\n"
            
        if is_modi == True:
            with open(cur_file, "w") as cur_out:
                cur_out.write(res_str)
            os.system(f"gofmt -w {cur_file}")
            

                    

    
