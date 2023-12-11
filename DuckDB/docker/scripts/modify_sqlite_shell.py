import os
import sys

fd = open("/home/duckdb/duckdb/tools/shell/shell.c", "r")
all_lines = fd.readlines()
all_modified_lines = "#include <sys/inotify.h>\n"

tmp_prev_line = ""
ignore_lines = 0
for i in range(len(all_lines)):
    cur_line = all_lines[i]
    if "data.in = stdin;" in cur_line and i+1 < len(all_lines) and "rc = process_input(&data);" in all_lines[i+1]:
        ignore_lines = 2

        all_modified_lines += """
    // stdin is not interactive.
    while (__AFL_LOOP(1000)) {
      fseek(stdin, 0, SEEK_SET);
      fseek(stdout, 0, SEEK_SET);
      data.in = stdin;
      rc = process_input(&data);
      ftruncate(fileno(stdin), 0);
      fflush(stdout);
    }
"""

    if ignore_lines == 0:
        all_modified_lines += cur_line
    else:
        # Ignore the following "data.in = stdin;" and "rc = process_input(&data);" line
        ignore_lines -= 1

fd.close()
fd = open("/home/duckdb/duckdb/tools/shell/shell.c", "wt")
fd.write(all_modified_lines)
fd.close()
