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

def plot_sql_grammar_size(file_name, markevery, line_style, is_downsampling = True):
    # For SQLRight. Our main tool.
    all_time_delta = []
    all_map_size = []
    time_avg = []
    map_size_avg = []
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
    
        map_size = []
        map_size.append(0)
        for cur_map in file['num_grammar_edge_cov']:
            cur_map = int(cur_map)
            map_size.append(cur_map)
    
        all_time_delta.append(time_delta)
        all_map_size.append(map_size)
        if len(time_delta) < min_size:
            min_size = len(time_delta)
    
    for i in range(min_size):
        cur_time = 0
        for j in range(1):
            cur_time += all_time_delta[j][i]
        cur_time = cur_time / 1
        time_avg.append(cur_time)
    
        cur_map = 0
        for j in range(1):
            cur_map += all_map_size[j][i]
        cur_map = cur_map / 1000.0
        map_size_avg.append(cur_map)
    
    
    # map_size_avg = [x * 262 / 100 for x in map_size_avg]
    
    if is_downsampling:
        time_avg, map_size_avg = sample_plots(time_avg, map_size_avg, True)
    
    plot_with_style(time_avg, map_size_avg, style_id=line_style, markevery=markevery)
    return

def plot_squirrel_sql_grammar_size(file_name, markevery, line_style, is_downsampling = True):
    # For SQLRight. Our main tool.
    all_time_delta = []
    all_map_size = []
    time_avg = []
    map_size_avg = []
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
    
        map_size = []
        map_size.append(0)
        for cur_map in file['total_gram_edge_cov_size_num']:
            cur_map = int(cur_map)
            map_size.append(cur_map)
    
        all_time_delta.append(time_delta)
        all_map_size.append(map_size)
        if len(time_delta) < min_size:
            min_size = len(time_delta)
    
    for i in range(min_size):
        cur_time = 0
        for j in range(1):
            cur_time += all_time_delta[j][i]
        cur_time = cur_time / 1
        time_avg.append(cur_time)
    
        cur_map = 0
        for j in range(1):
            cur_map += all_map_size[j][i]
        cur_map = cur_map / 1000.0
        map_size_avg.append(cur_map)
    
    
    # map_size_avg = [x * 262 / 100 for x in map_size_avg]
    
    if is_downsampling:
        time_avg, map_size_avg = sample_plots(time_avg, map_size_avg, True)
    
    plot_with_style(time_avg, map_size_avg, style_id=line_style, markevery=markevery)
    return

def simple_plot_bug_num(bug_time_list, markevery, plot_style):
    x = sorted(bug_time_list)
    x = [0] + x
    y = list(range(1, len(x) + 0))
    y = [0] + y 
    x, y = sample_bug_num(x, y)
    x, y = sample_plots(x, y)
    y = [i/1000.0 for i in y]
    plot_with_style(x, y, plot_style, markevery)

def plot_gram_cov_out(file_name, markevery, line_style, is_downsampling = True):
    fd = open(file_name, "r")

    start_time = -1
    time_delta = []
    
    for cur_line in fd.read().splitlines():
        unix_time = cur_line.split(",")[-1]
        unix_time = int(unix_time)
        if start_time == -1:
            start_time = unix_time
            time_delta.append(0)
        else:
            time_delta.append((unix_time - start_time)/3600)
    
    simple_plot_bug_num(time_delta, markevery=markevery, plot_style=line_style)


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


plot_gram_cov_out("./parserfuzz/gram_cov_out_0", markevery = 20, line_style = 0)
plot_gram_cov_out("./parserfuzz_nofav/gram_cov_out_0", markevery = 20, line_style = 1)
plot_gram_cov_out("./parserfuzz_nofavnomab/gram_cov_out_0", markevery = 20, line_style = 2)
plot_gram_cov_out("./parserfuzz_nofavnomabnoacc/gram_cov_out_0", markevery = 20, line_style = 3)
plot_gram_cov_out("./parserfuzz_nofavnomabnoaccnocat/gram_cov_out_0", markevery = 20, line_style = 4)

x_top = list(range(0, 49, 1))
y_top = len(x_top) * [1.446]
plot_with_style(x_top, y_top, -1, 3)

plt.xlim(0, 24)
# plt.ylim(0, 100000)

x_major_locator=MultipleLocator(4)
ax=plt.gca()
ax.xaxis.set_major_locator(x_major_locator)

# plt.ylabel('Grammar Edge', fontsize = 20)

plt.legend(['ParserFuzz', 'ParserFuzz_noFav', 'ParserFuzz_noFavNoMab', 'ParserFuzz_noFavNoMabNoAcc', 'ParserFuzz_noFavNoMabNoAccNoCat'], fontsize=13)

plt.tight_layout()

if not os.path.isdir("./plots"):
    os.mkdir("./plots")

plt.savefig('./plots/gram-size.pdf', dpi = 200)
plt.savefig('./plots/gram-size.png', dpi = 200)

# def export_legend(legend, filename="./plots/legend"):
#     fig  = legend.figure
#     fig.canvas.draw()
#     bbox  = legend.get_window_extent().transformed(fig.dpi_scale_trans.inverted())
#     fig.savefig(filename+".png", dpi=400, bbox_inches=bbox)
#     fig.savefig(filename+".pdf", dpi=400, bbox_inches=bbox)

# fig = plt.figure()
# x = []
# y = []
# plot_with_style(x_top, y_top, 0, 3)
# plot_with_style(x_top, y_top, 1, 3)
# plot_with_style(x_top, y_top, 2, 3)
# plot_with_style(x_top, y_top, 3, 3)
# plot_with_style(x_top, y_top, 4, 3)
# plot_with_style(x_top, y_top, 5, 3)

# ax.spines['top'].set_visible(False)
# ax.spines['right'].set_visible(False)
# ax.spines['bottom'].set_visible(False)
# ax.spines['left'].set_visible(False)
# ax.get_xaxis().set_ticks([])
# ax.get_yaxis().set_ticks([])
# legend = plt.legend(['ParserFuzz', 'ParserFuzz$_\mathrm{-cov}$', 'Squirrel',  'AFL++', 'SQLSmith', 'SQLancer$_\mathrm{+QPG}$'], fontsize=13, handlelength=4, ncol = 6, bbox_to_anchor=(0.5, -0.05), alignment='center')
# export_legend(legend,"./plots/legend_0")

# fig = plt.figure()
# x = []
# y = []
# plot_with_style(x_top, y_top, 6, 3)
# plot_with_style(x_top, y_top, 7, 3)
# plot_with_style(x_top, y_top, 8, 3)
# plot_with_style(x_top, y_top, -1, 3)

# ax.spines['top'].set_visible(False)
# ax.spines['right'].set_visible(False)
# ax.spines['bottom'].set_visible(False)
# ax.spines['left'].set_visible(False)
# ax.get_xaxis().set_ticks([])
# ax.get_yaxis().set_ticks([])
# legend = plt.legend(['SQLsmith$_\mathrm{C}$', 'SQLsmith$_\mathrm{G}$', 'LibFuzzer', "Upper Bound"], fontsize=13, handlelength=4, ncol = 6, bbox_to_anchor=(0.5, -0.05), alignment='center')
# export_legend(legend,"./plots/legend_1")


# fig = plt.figure()
# x = []
# y = []
# plot_with_style(x_top, y_top, 0, 3)
# plot_with_style(x_top, y_top, 1, 3)
# plot_with_style(x_top, y_top, 6, 3)
# plot_with_style(x_top, y_top, 8, 3)
# plot_with_style(x_top, y_top, 5, 3)
# plot_with_style(x_top, y_top, -1, 3)

# ax.spines['top'].set_visible(False)
# ax.spines['right'].set_visible(False)
# ax.spines['bottom'].set_visible(False)
# ax.spines['left'].set_visible(False)
# ax.get_xaxis().set_ticks([])
# ax.get_yaxis().set_ticks([])
# legend = plt.legend(['ParserFuzz', 'ParserFuzz$_\mathrm{-cov}$', 'SQLsmith$_\mathrm{CockroachDB}$', 'LibFuzzer', 'SQLancer$_\mathrm{+QPG}$', "Upper Bound"], fontsize=13, handlelength=4, ncol = 1, bbox_to_anchor=(0.5, -0.05), alignment='center')
# export_legend(legend,"./plots/legend_tmp")