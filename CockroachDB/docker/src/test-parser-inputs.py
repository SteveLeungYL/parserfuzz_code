import subprocess
import sys
import os

cwd = "./"
input_folder = os.path.join(cwd, "inputs")

mismatched_file = open("mismatched_file.txt", "w")

for cur_file in os.listdir(input_folder):
    cur_file_full = os.path.join(input_folder, cur_file)
    run_str = "./test-parser %s" % (cur_file_full)
    process = subprocess.Popen(run_str, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell = True)
    out, errs = process.communicate()


    start_record = False
    for cur_line in str(out).split("\\n"):
        if "Found string mismatched:" in cur_line:
            start_record = True
            mismatched_file.write("\n\n" + cur_line + "\n")
            continue
        if "End mismatched" in cur_line:
            start_record = False
            mismatched_file.write(cur_line + "\n")
            continue
        if start_record:
            mismatched_file.write(cur_line + "\n")

print("Finished everything.")
