import matplotlib.pyplot as plt
import os
import pandas as pd
import sys
from matplotlib.pyplot import MultipleLocator
import datetime
import numpy as np
import shutil
import paramiko
import matplotlib.ticker as mtick
import matplotlib
import subprocess

pd.set_option('display.max_columns', None)

# print(plt.rcParams)
plt.figure(figsize=(6.2, 4))

plt.grid(True, which="major", ls="-")

plt.xticks(fontsize=20)
plt.yticks(fontsize=20)

ax = plt.gca()
ax.set_facecolor('#F6F5F5')

matplotlib.rcParams['pdf.fonttype'] = 42
matplotlib.rcParams['ps.fonttype'] = 42

cockroachdb_binary_loc = "/media/psf/Home/Desktop/Research_Backup/SQLRight_CockroachDB_RSG/test/run_0/cockroach"

internal_error_bug_patterns = [
        "input to ArrayFlatten should be uncorrelated",
        "comparison overload not found",
        "runtime error: slice bounds out of range",
        "unexpected error from the vectorized engine",
        "tuple contents and labels must be of same length",
        "unexpected error from the vectorized engine",
        "unhandled type *tree.RangeCond",
        "lookup join with columns that are not required",
        "invalid datum type given: decimal, expected int",
        "top-level relational expression cannot have outer columns",
        "invalid memory address or nil pointer dereference",
        "an empty start boundary must be inclusive",
        "panic: runtime error: slice bounds out of range",
        "an empty end boundary must be inclusive",
        "unexpected statement: *tree.SetTracing",
        "expected *DString, found tree.dNull",
        "expected subquery to be lazily planned as routines",
        "generator functions cannot be evaluated as scalars",
        "cannot map variable 5 to an indexed var"
        ]

internal_error_triggered_idx = []

crashing_triggered_stack_trace = []

def execute_cockroach_get_crash_stack(crash_poc: str):
    if not os.path.isfile(cockroachdb_binary_loc):
        print("\n\n\nWarning: Cannot find the CockroachDB binary. Ignore the crashing bugs. \n\n\n")
        return ("", "")

    run_command = "%s demo" % (cockroachdb_binary_loc)
    p = subprocess.Popen(
            [run_command], 
            shell=True, 
            stdout=subprocess.PIPE,
            stdin=subprocess.PIPE,
            stderr=subprocess.STDOUT
            )

    out, _ = p.communicate(input=bytes(crash_poc, 'utf-8'), timeout=3)
    out = out.decode('utf-8', errors='ignore')

    is_read = False
    res_panic_mess = ""
    res_stack_trace = ""
    # print("\n\n\nDEBUG: out: %s\n\n\n"%(out))
    for cur_line in out.split("\n"):
        if "goroutine" in cur_line:
            is_read = True
            continue
        if is_read:
            res_stack_trace += cur_line + "\n"
        if "panic:" in cur_line:
            res_panic_mess += cur_line + " "
        continue

    # print("\n\n\nDEBUG: Getting crashing input: %s, \nmessage: %s, \nstack trace: %s\n\n\n" % (crash_poc, res_panic_mess, res_stack_trace))

    return [res_panic_mess, res_stack_trace]

def sample_bug_number_gen_time_file(file_dir: str):

    print("\nBegin testing with file_dir: %s\n" % (file_dir))

    internal_error_triggered_idx.clear()
    crashing_triggered_stack_trace.clear()

    ori_file_dir = file_dir

    res_time_file_fd = open(os.path.join(file_dir, "./time.txt"), "w")
    res_new_bug = open(os.path.join(file_dir, "./new_bug.txt"), 'w')
     
    if not os.path.isdir(file_dir):
        print("Warning: Bug folder %s not exists. " % (file_dir))
        exit(1)
    file_dir = os.path.join(file_dir, "bug_samples")
    if not os.path.isdir(file_dir):
        print("Warning: Bug folder %s not exists. " % (file_dir))
        exit(1)

    all_files = os.listdir(file_dir)
    all_files.sort(key=lambda x: os.stat(os.path.join(file_dir, x)).st_mtime)

    start_create_time = 0
    if len(all_files) != 0:
        start_create_time = os.stat(os.path.join(file_dir, all_files[0])).st_mtime

    for cur_file in all_files:
        cur_file = os.fsdecode(cur_file)
        if "bug:" not in cur_file or "txt" not in cur_file:
            continue
        cur_create_time = os.stat(os.path.join(file_dir, cur_file)).st_mtime
        time_gap = cur_create_time - start_create_time

        cur_file_fd = open(os.path.join(file_dir, cur_file), 'r', errors='ignore')
        cur_file_content = cur_file_fd.read()

        is_detected = False
        for idx, cur_pattern in enumerate(internal_error_bug_patterns):
            if cur_pattern in cur_file_content:
                is_detected = True
                if idx not in internal_error_triggered_idx:
                    res_time_file_fd.write("%d %d %s\n"%(idx, time_gap, cur_pattern))
                    internal_error_triggered_idx.append(idx)
                else:
                    # already reported.
                    pass
                break

        if not is_detected:
            cur_file_fd.seek(0)
            cur_file_content_lines = cur_file_fd.readlines()
            buggy_line = ""
            for cur_line in cur_file_content_lines:
                if "internal error" in cur_line:
                    buggy_line = cur_line
                    break
            res_new_bug.write("%s %s\n"%(cur_file, buggy_line))
            # TODO:: Should we add these to the bug plot?

        cur_file_fd.close()

    # And then, read the crashing bugs, and try to de-duplicate them.
    if not os.path.isfile(cockroachdb_binary_loc):
        print("\n\n\nWarning: Cannot find the CockroachDB binary. Ignore the crashing bugs. \n\n\n")
        res_new_bug.close()
        res_time_file_fd.close()
        return

    file_dir = os.path.join(file_dir, "crashes")
    if not os.path.isdir(file_dir):
        print("Warning: Bug folder %s not exists. Do not have crashes? " % (file_dir))
        res_new_bug.close()
        res_time_file_fd.close()
        return

    print("\nBegin testing with crashing bug: file_dir: %s\n" % (file_dir))

    res_new_bug.close()
    res_new_bug = open(os.path.join(ori_file_dir, "./new_crashing_bug.txt"), 'w')

    all_files = os.listdir(file_dir)
    all_files.sort(key=lambda x: os.stat(os.path.join(file_dir, x)).st_mtime)

    for cur_file in all_files:
        # Analyze each crashing file. 
        cur_file = os.fsdecode(cur_file)
        if "bug:" not in cur_file or "txt" not in cur_file:
            continue
        cur_create_time = os.stat(os.path.join(file_dir, cur_file)).st_mtime
        time_gap = cur_create_time - start_create_time
        if time_gap < 0:
            time_gap = 1

        cur_file_fd = open(os.path.join(file_dir, cur_file), 'r', errors='ignore')
        cur_file_all_lines = cur_file_fd.readlines()

        is_read = False
        all_read_line = ""
        for cur_line in cur_file_all_lines:
            if "Query: " in cur_line:
                is_read = True
                all_read_line = ""
                continue
            if "Result string:" in cur_line:
                is_read = False
                continue
            if not is_read:
                continue
            all_read_line += cur_line + "\n"
            continue
        cur_file_fd.close()
        
        if all_read_line == "":
            continue

        res_panic_mess, res_crash_stack = execute_cockroach_get_crash_stack(all_read_line)

        res_crash_stack_all_lines = res_crash_stack.split("\n")
        
        if len(res_crash_stack_all_lines) > 2 and res_crash_stack_all_lines[1] not in crashing_triggered_stack_trace:
            # print("\n\n\nSaving with: %s\n\n\n" % (res_crash_stack_all_lines[1]))
            crashing_triggered_stack_trace.append(res_crash_stack)
            res_new_bug.write("-------------------\n")
            res_new_bug.write("Message: \n%s\nStack:\n%s\n\n\n\n\n"% (res_panic_mess, res_crash_stack))
            res_time_file_fd.write("-1 %d crash %s\n"%(time_gap, os.path.join(file_dir, cur_file)))
            crashing_triggered_stack_trace.append(res_crash_stack_all_lines[1])
            continue
        else:
            continue

    res_time_file_fd.close()
    res_new_bug.close()
    return

def plot_sql_bugs(file_dir, markevery, line_style):

    if not os.path.isdir(file_dir):
        print("Warning: Bug folder %s not exists. " % (file_dir))
        exit(1)

    file_dir = os.path.join(file_dir, "time.txt")

    # If the time.txt file not exists. Treat it as no bugs. 
    if not os.path.isfile(file_dir):
        print("time.txt file: %s not exists.  It could due to no active True Positive bugs being found after bisecting and filtering. Or the bisecting algorithm is not called. " % (file_dir))
        time_l = list(np.arange(0, 72.2, 0.2))
        bug_num_l = [0] * len(time_l)
        plot_with_style(time_l, bug_num_l, style_id=line_style, markevery=markevery)
        return
    
    file_fd = open(file_dir, 'r')
    all_file_lines = file_fd.readlines()

    all_bug_time = []
    for cur_line in all_file_lines:
        cur_line = cur_line.split(" ")[1]
        cur_line = float(cur_line)
        all_bug_time.append(cur_line)
    all_bug_time.sort()
    all_bug_time = [x / 3600.0 for x in all_bug_time]

    time_l = []
    bug_num_l = []
    bug_num = 0
    for i in np.arange(0, 72.2, 0.2):
        if len(all_bug_time) == 0:
            time_l.append(i)
            bug_num_l.append(bug_num)
            continue
        if i >= all_bug_time[0]:
            time_l.append(i)
            bug_num_l.append(bug_num)
            bug_num += 1
            time_l.append(i)
            bug_num_l.append(bug_num)

            if len(all_bug_time) > 1:
                all_bug_time = all_bug_time[1:]
            else:
                all_bug_time = []
        else:
            time_l.append(i)
            bug_num_l.append(bug_num)
        continue

    plot_with_style(time_l, bug_num_l, style_id=line_style, markevery=markevery)


def plot_with_style(x, y, style_id = 0, markevery=100):
    if style_id == 0:
        plt.plot(x, y, linestyle = (0, (3, 1, 1, 1, 1, 1)), marker = 'o', markevery=markevery, linewidth=4.0, markersize=10, color = 'r')
    elif style_id == 1:
        plt.plot(x, y, linestyle = 'dashed', marker = 'p', markevery=markevery, linewidth=4.0, markersize=10, color='darkorange')
    elif style_id == 2:
        plt.plot(x, y, linestyle = 'dotted', marker = '^', markevery=markevery, linewidth=4.0, markersize=10, color='tab:blue')
    elif style_id == 3:
        plt.plot(x, y, linestyle = 'dashed', marker = '*', markevery=markevery, linewidth=4.0, markersize=10, color = 'c')
    elif style_id == 4:
        plt.plot(x, y, linestyle = "dashdot", marker = "v", markevery=markevery, linewidth=4.0, markersize=10, color = 'tab:olive')
    else:
        plt.plot(x, y, linestyle = (0, (3, 1, 1, 1, 1, 1)), marker = 'o', markevery=markevery, linewidth=4.0, markersize=10)
    return

def sample_bug_num(x, y, start_from_zero = False):
    j = 1 # idx for original x and y. 
    if start_from_zero:
        new_x = [0]
        new_y = [0]
    else:
        new_x = [x[0]]
        new_y = [y[0]]
    for i in np.arange(0, 72.2, 0.2):
        while j < len(x) and i > x[j]:
            new_x.append(x[j])
            new_y.append(y[j])
            j += 1
        new_x.append(i)
        new_y.append(new_y[-1])
    return new_x, new_y

def sample_plots(x, y, start_from_zero = False):
    j = 1 # idx for original x and y. 
    prev_x = 0
    if start_from_zero:
        new_x = [0]
        new_y = [0]
    else:
        new_x = [x[0]]
        new_y = [y[0]]
    for i in np.arange(0, 72.2, 0.2):
        is_continue = False
        while j < len(x) and (i + 0.2) < x[j]:
            new_x.append(i)
            
            src_x = prev_x
            src_y = new_y[-1]
            dest_x = x[j]
            dest_y = y[j]
            
            new_y_value =  src_y + (dest_y - src_y) * (i - src_x) / (dest_x - src_x)

            new_y.append(new_y_value)
            is_continue = True
            break
        if is_continue:
            continue
        
        # If x still exists, then plot x. 
        if j < len(x):
            new_x.append(x[j])
            new_y.append(y[j])

            prev_x = x[j]

            # Iterate x to the point of ploting
            while j < len(x) and i > x[j]:
                j += 1
        # Otherwise, extend the last x value. 
        else:
            new_x.append(i)
            new_y.append(new_y[-1])
    return new_x, new_y



sample_bug_number_gen_time_file("./with_rsg")
print("Finished with with_rsg")
sample_bug_number_gen_time_file("./without_rsg")
print("Finished with without_rsg")
sample_bug_number_gen_time_file("./without_dyn_fix")
print("Finished with without_dyn_fix")

plot_sql_bugs("./with_rsg", markevery=20, line_style=0)
plot_sql_bugs("./without_rsg", markevery=20, line_style=1)
plot_sql_bugs("./without_dyn_fix", markevery=20, line_style=2)

plt.xlim(0, 40)
# plt.ylim(0, 100)

x_major_locator=MultipleLocator(5)
ax=plt.gca()
ax.xaxis.set_major_locator(x_major_locator)

y_major_locator=MultipleLocator(1)
ax=plt.gca()
ax.yaxis.set_major_locator(y_major_locator)

# ax.set_yscale('log')

# ax.yaxis.set_major_formatter(mtick.PercentFormatter())

# plt.title("SQLite3 NoREC Query Validity (%) (Feedback Tests)", fontsize=15)
# plt.xlabel('Time (hour)', fontsize = 20)
plt.ylabel('Bug Num', fontsize = 20)

plt.legend(['Ori', 'Without RSG', 'Without dyn instan'], fontsize=13)


plt.tight_layout()

if not os.path.isdir("./plots"):
    os.mkdir("./plots")

plt.savefig('./plots/bug_num.pdf', dpi = 200)
plt.savefig('./plots/bug_num.png', dpi = 200)
