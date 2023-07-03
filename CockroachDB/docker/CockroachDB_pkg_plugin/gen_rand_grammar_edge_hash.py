import os
import random

for root, _, all_files in os.walk("./CockroachDB_pkg_plugin/tree"):
    for cur_file in all_files:
        cur_file = os.path.join(root, cur_file)

        res_str = ""
        is_modi = False
        with open(cur_file, "r").read().splitlines() as cur_in_lines:
            for cur_line in cur_in_lines:
                res_str += cur_line + "\n"
                if "&SQLRightIR{" in cur_line:
                    res_str += f"NodeHash: {random.randint(0, 262143)}\n"
                    is_modi = True
            
        if is_modi == True:
            with open(cur_file, "w") as cur_out:
                cur_out.write(res_str)
            os.system(f"gofmt -w {cur_file}")
            

                    

    
