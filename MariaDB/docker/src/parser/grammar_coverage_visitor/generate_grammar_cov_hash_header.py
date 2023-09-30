import os
import random
import time

random.seed(time.time_ns())

with open("grammar_cov_hash_header.h", "w") as fd:
    fd.write("""\
// DO NOT DIRECTLY MODIFY THIS FILE. 
// This code is generated from PYTHON script generate_grammar_cov_hash_header.h. 
""")
    fd.write("#define HASHARRAYDEFINE unsigned long hash_array [7000] = { \\\n")
    for i in range(7000):
        if i != 6999:
            fd.write(f"    {random.randint(0, 262143)}, \\\n")
        else:
            fd.write(f"    {random.randint(0, 262143)} \\\n")
    fd.write("}; \n")

random.seed(time.time_ns())

with open("grammar_cov_path_hash_header.h", "w") as fd:
    fd.write("""\
// DO NOT DIRECTLY MODIFY THIS FILE. 
// This code is generated from PYTHON script generate_grammar_cov_hash_header.h. 
""")
    fd.write("#define HASHPATHARRAYDEFINE unsigned long path_hash_array [7000] = { \\\n")
    for i in range(7000):
        if i != 6999:
            fd.write(f"    {random.randint(0, 2147483647)}, \\\n")
        else:
            fd.write(f"    {random.randint(0, 2147483647)} \\\n")
    fd.write("}; \n")
