import os
import shutil

input_folder = "./inputs/"

new_input_folder = "./new_inputs"

if os.path.isdir(new_input_folder):
    shutil.rmtree(new_input_folder)

os.mkdir(new_input_folder)

for i_file in os.listdir(input_folder):
    file_path = os.path.join(input_folder, i_file)
    if not os.path.isfile(file_path):
        continue

    cur_fd = open(file_path, "r", encoding='UTF-8', errors = "replace")
    all_lines = ""

    line_num = 0
    for cur_line in cur_fd.readlines():
        if len(cur_line) > 700:
            continue
        all_lines += cur_line

        if line_num > 80:
            break
        
        line_num += 1
    
    if all_lines != "":
        out_file_path = os.path.join(new_input_folder, i_file)
        out_fd = open(out_file_path, "w", encoding='UTF-8', errors = "replace")
        out_fd.write(all_lines)
        out_fd.close()
    
    cur_fd.close()
        

