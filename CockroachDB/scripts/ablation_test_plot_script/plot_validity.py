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
    elif style_id == 5:
        plt.plot(x, y, linestyle = ":", marker = "D", markevery=markevery, linewidth=4.0, markersize=10, color = 'm')
    elif style_id == 6:
        plt.plot(x, y, linestyle = "dashed", marker = "h", markevery=markevery, linewidth=4.0, markersize=10, color = 'tab:green')
    elif style_id == 7:
        plt.plot(x, y, linestyle = "--", marker = "X", markevery=markevery, linewidth=4.0, markersize=10, color = 'tab:brown')
    elif style_id == 8:
        plt.plot(x, y, linestyle = "-.", marker = "s", markevery=markevery, linewidth=4.0, markersize=10, color = 'gray')
    else:
        plt.plot(x, y, linestyle = (0, (3, 1, 1, 1, 1, 1)), marker = 'o', markevery=markevery, linewidth=4.0, markersize=10, color = 'tab:pink')
    return


def plot_sqlancer_correct_rate(file_name, markevery, line_style, is_downsampling = True):

    cur_file_fd = open(file_name, 'r')
    succ_rate_avg = []
    time_avg = []
    start_time = 0
    idx = 0
    for cur_line in cur_file_fd.read().splitlines():
        if "successful statements: " not in cur_line:
            continue
        succ_rate_str = cur_line.split("successful statements: ")[1].split("%")[0]
        succ_rate = int(succ_rate_str)
        succ_rate_avg.append(succ_rate)

        time_str = cur_line.split("[")[1].split("]")[0]
        time_obj = datetime.datetime.strptime(time_str, '%Y/%m/%d %H:%M:%S')
        time_unix = datetime.datetime.timestamp(time_obj)/3600.0
        if idx == 0:
            start_time = time_unix 
            time_avg.append(0)
        else:
            time_unix -= start_time
            time_avg.append(time_unix)
            
        idx += 1
    
    if is_downsampling:
        time_avg, succ_rate_avg = sample_plots(time_avg, succ_rate_avg)
    
    plot_with_style(time_avg, succ_rate_avg, style_id=line_style, markevery=markevery)

def plot_sql_correct_rate_squirrel(file_name, markevery, line_style, is_downsampling = True):
    # For SQLRight. Our main tool.
    all_time_delta = []
    all_corr_rate = []
    time_avg = []
    corr_rate_avg = []
    min_size = sys.maxsize
    
    
    for i in [0]:
        file = pd.read_csv(file_name)
        file['time'] = pd.to_datetime(file['unix_time'], unit='s')
        time_delta = []
        time_delta.append(0)
        time_start = file['time'][0]
        for cur_time in file['time'][1:]:
            tmp = pd.Timedelta(cur_time - time_start).seconds / 3600
            tmp += pd.Timedelta(cur_time - time_start).days * 24
            time_delta.append(tmp)
    
        curr_rate_list = []
        for cur_curr_idx in range(file['unix_time'].size):
            cur_curr_correct = file['correct'][cur_curr_idx]
            cur_curr_error = file['semantic_error'][cur_curr_idx] + file['syntax_error'][cur_curr_idx] + 1
            cur_curr_correct_rate = float(cur_curr_correct) / (float(cur_curr_correct) + float(cur_curr_error)) * 100.0
            # print(f"Correct num: {cur_curr_correct}, Error Num: {cur_curr_error}, corr rate: {cur_curr_correct_rate}\n")
            curr_rate_list.append(cur_curr_correct_rate)

        all_time_delta.append(time_delta)
        all_corr_rate.append(curr_rate_list)
        if len(time_delta) < min_size:
            min_size = len(time_delta)
    
    for i in range(min_size):
        cur_time = 0
        for j in range(1):
            cur_time += all_time_delta[j][i]
        cur_time = cur_time / 1
        time_avg.append(cur_time)
    
        cur_curr_rate = 0
        for j in range(1):
            cur_curr_rate += all_corr_rate[j][i]
        cur_curr_rate = cur_curr_rate / 1
        corr_rate_avg.append(cur_curr_rate)
    
    if is_downsampling:
        time_avg, corr_rate_avg = sample_plots(time_avg, corr_rate_avg)
    

    corr_rate_avg = [x for x in corr_rate_avg]
    
    plot_with_style(time_avg, corr_rate_avg, style_id=line_style, markevery=markevery)

def plot_valid_file_correct_rate(file_name, markevery, line_style, is_downsampling = True):
    cor_num = 0
    err_num = 0
    start_time = -1
    time_delta = []
    corr_rate = []

    cur_file_fd = open(file_name, "r")
    for cur_line in cur_file_fd.read().splitlines():
        time = cur_line.split(",")[0]
        corr = cur_line.split(",")[1]

        if start_time == -1:
            start_time = float(time)
            time = 0
            time_delta.append(time)
        else:
            time = float(time) - start_time
            time = float(time) / 3600.0
            # print(f"Getting time {time}")
            time_delta.append(time)
        
        # print(f"Getting corr str: {corr}\n")
        if "-1" in corr:
            # print("err")
            err_num += 1
        else:
            # print("cor")
            cor_num += 1
        cur_corr_rate = float(cor_num) / (float(cor_num) + float(err_num)) * 100.0
        # print(f"correct: {cor_num}, error: {err_num}, rate: {cur_corr_rate}")
        corr_rate.append(cur_corr_rate)

    if is_downsampling:
        time_delta, corr_rate = sample_plots(time_delta, corr_rate)
    # print(f"time_delta: {time_delta}, corr_rate: {corr_rate}")
    
    plot_with_style(time_delta, corr_rate, style_id=line_style, markevery=markevery)

def plot_sql_correct_rate(file_name, markevery, line_style, is_downsampling = True):
    # For SQLRight. Our main tool.
    all_time_delta = []
    all_corr_rate = []
    time_avg = []
    corr_rate_avg = []
    min_size = sys.maxsize
    
    
    for i in [0]:
        file = pd.read_csv(file_name)
        file['time'] = pd.to_datetime(file['unix_time'], unit='s')
        time_delta = []
        time_delta.append(0)
        time_start = file['time'][0]
        for cur_time in file['time'][1:]:
            tmp = pd.Timedelta(cur_time - time_start).seconds / 3600
            tmp += pd.Timedelta(cur_time - time_start).days * 24
            time_delta.append(tmp)
    
        curr_rate_list = []
        for cur_curr_rate in file['total_good_queries']:
            cur_curr_rate = cur_curr_rate.strip('%')
            cur_curr_rate = float(cur_curr_rate)
            curr_rate_list.append(cur_curr_rate)

        all_time_delta.append(time_delta)
        all_corr_rate.append(curr_rate_list)
        if len(time_delta) < min_size:
            min_size = len(time_delta)
    
    for i in range(min_size):
        cur_time = 0
        for j in range(1):
            cur_time += all_time_delta[j][i]
        cur_time = cur_time / 1
        time_avg.append(cur_time)
    
        cur_curr_rate = 0
        for j in range(1):
            cur_curr_rate += all_corr_rate[j][i]
        cur_curr_rate = cur_curr_rate / 1
        corr_rate_avg.append(cur_curr_rate)
    
    if is_downsampling:
        time_avg, corr_rate_avg = sample_plots(time_avg, corr_rate_avg)
    

    corr_rate_avg = [x for x in corr_rate_avg]
    
    plot_with_style(time_avg, corr_rate_avg, style_id=line_style, markevery=markevery)


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

plot_sql_correct_rate("./parserfuzz/plot_data_0", markevery = 20, line_style = 0)
plot_sql_correct_rate("./parserfuzz_nofav/plot_data_0", markevery = 20, line_style = 1)
plot_sql_correct_rate("./parserfuzz_nofavnomab/plot_data_0", markevery = 20, line_style = 2)
plot_sql_correct_rate("./parserfuzz_nofavnomabnoacc/plot_data_0", markevery = 20, line_style = 3)
# plot_sql_correct_rate("./parserfuzz_nofavnomabnoaccnocat/plot_data_0", markevery = 20, line_style = 4)

x_top = list(range(0, 49, 1))
y_top = len(x_top) * [0]
plot_with_style(x_top, y_top, -1, 4)

plt.xlim(0, 24)
plt.ylim(0, 100)

x_major_locator=MultipleLocator(4)
ax=plt.gca()
ax.xaxis.set_major_locator(x_major_locator)

# plt.ylabel('Query Validity (%)', fontsize = 20)

# plt.legend(['RSG', 'RSG_no_cov', 'CockroachDB-SQLSmith', 'LibFuzzer'], fontsize=13)
plt.legend(['ParserFuzz', 'ParserFuzz_noFav', 'ParserFuzz_noFavNoMab', 'ParserFuzz_noFavNoMabNoAcc', 'ParserFuzz_noFavNoMabNoAccNoCat'], fontsize=13)

plt.tight_layout()

if not os.path.isdir("./plots"):
    os.mkdir("./plots")

plt.savefig('./plots/correct-rate.pdf', dpi = 200)
plt.savefig('./plots/correct-rate.png', dpi = 200)
