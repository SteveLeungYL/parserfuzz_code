import os
import random
import time

random.seed(time.time_ns())

with open("gram_edge_rand_hash.h", "w") as fd:
    fd.write("""\
// DO NOT DIRECTLY MODIFY THIS FILE. 
// This code is generated from PYTHON script gen_gram_edge_rand_hash.py. 
""")
    fd.write("static unsigned int edge_hash[7000] = { \\\n")
    for i in range(7000):
        if i != 6999:
            fd.write(f"    {random.randint(0, 262143)}, \\\n")
        else:
            fd.write(f"    {random.randint(0, 262143)} \\\n")
    fd.write("}; \n")
