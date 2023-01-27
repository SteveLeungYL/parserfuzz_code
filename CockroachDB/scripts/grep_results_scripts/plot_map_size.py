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
    else:
        plt.plot(x, y, linestyle = (0, (3, 1, 1, 1, 1, 1)), marker = 'o', markevery=markevery, linewidth=4.0, markersize=10)
    return

def plot_sql_mapsize(file_name, markevery, line_style, is_downsampling = True):
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
        for cur_map in file['map_size']:
            cur_map = cur_map.strip('%')
            cur_map = float(cur_map)
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
        cur_map = cur_map / 1
        map_size_avg.append(cur_map)
    
    
    map_size_avg = [x * 262 / 100 for x in map_size_avg]
    
    if is_downsampling:
        time_avg, map_size_avg = sample_plots(time_avg, map_size_avg, True)
    
    plot_with_style(time_avg, map_size_avg, style_id=line_style, markevery=markevery)
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


plot_sql_mapsize("./with_rsg/plot_data_2", markevery = 20, line_style = 0)
plot_sql_mapsize("./without_rsg/plot_data_0", markevery = 20, line_style = 1)
plot_sql_mapsize("./without_dyn_fix/plot_data_0", markevery = 20, line_style = 2)



plt.xlim(0, 40)
plt.ylim(60, 100)

x_major_locator=MultipleLocator(5)
ax=plt.gca()
ax.xaxis.set_major_locator(x_major_locator)

# ax.set_yscale('log')

# ax.yaxis.set_major_formatter(mtick.PercentFormatter())

# plt.title("SQLite3 NoREC Query Validity (%) (Feedback Tests)", fontsize=15)
# plt.xlabel('Time (hour)', fontsize = 20)
plt.ylabel('Block Code Coverage (k)', fontsize = 20)

plt.legend(['Ori', 'Without RSG', 'Without dyn instan'], fontsize=13)


plt.tight_layout()

if not os.path.isdir("./plots"):
    os.mkdir("./plots")

plt.savefig('./plots/map-size.pdf', dpi = 200)
plt.savefig('./plots/map-size.png', dpi = 200)
