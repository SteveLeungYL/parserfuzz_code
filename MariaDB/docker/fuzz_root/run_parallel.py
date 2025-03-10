import re
from socket import socket
import time
import os
import shutil
import subprocess
import atexit
import signal
import psutil
import MySQLdb
import getopt
import sys
import libtmux

from afl_config import *

server = libtmux.Server()
all_mysql_server_tmux_window = []

session = server.new_session(session_name="mysql_server_debug", kill_session=True, attach=False)

def exit_handler(signal, frame):
    print("########################\n\n\n\n\nRecevied terminate signal. Ignored!!!!!!! \n\n\n\n\n")
    pass

def check_pid_exist(pid: int):
    try:
        os.kill(pid, 0)
    except OSError:
        return False
    else:
        return True

# Parse the command line arguments:
output_dir_str = ""
oracle_str = "NOREC"
feedback_str = ""
parallel_num = 5
starting_core_id = 0
is_non_deter = False

try:
    opts, args = getopt.getopt(sys.argv[1:], "o:c:n:O:F:", ["odir=", "start-core=", "num-concurrent=", "oracle=", "non-deter"])
except getopt.GetoptError:
    print("Arguments parsing error")
    exit(1)
for opt, arg in opts:
    if opt in ("-o", "--odir"):
        output_dir_str = arg
        print("Using output dir: %s" % (output_dir_str))
    elif opt in ("-c", "--start-core"):
        starting_core_id = int(arg)
        print("Using starting_core_id: %d" % (starting_core_id))
    elif opt in ("-n", "--num-concurrent"):
        parallel_num = int(arg)
        print("Using num-concurrent: %d" % (parallel_num))
    elif opt in ("-O", "--oracle"):
        oracle_str = arg
        print("Using oracle: %s " % (oracle_str))
    elif opt in ("--non-deter"):
        is_non_deter = True
        print("Using Non-Deterministic Behavior. ")
    else:
        print("Error. Input arguments not supported. \n")
        exit(1)

# signal.signal(signal.SIGTERM, exit_handler)
# signal.signal(signal.SIGINT, exit_handler)
# signal.signal(signal.SIGQUIT, exit_handler)
# signal.signal(signal.SIGHUP, exit_handler)

if os.path.isfile(os.path.join(os.getcwd(), "shm_env.txt")):
    os.remove(os.path.join(os.getcwd(), "shm_env.txt"))

for cur_inst_id in range(starting_core_id, starting_core_id + parallel_num, 1):
    print("#############\nSetting up core_id: " + str(cur_inst_id))

    # Set up the mysql data folder first.
    cur_mysql_data_dir_str = os.path.join(mysql_root_dir, "data_all/data_" + str(cur_inst_id))
    if os.path.isdir(cur_mysql_data_dir_str):
        shutil.rmtree(cur_mysql_data_dir_str)
    shutil.copytree(mysql_src_data_dir, cur_mysql_data_dir_str)

    # Set up SQLRight output folder
    cur_output_dir_str = ""
    if output_dir_str != "":
        cur_output_dir_str = output_dir_str + "/outputs_"  + str(cur_inst_id - starting_core_id)
    else:
        cur_output_dir_str = "./outputs/outputs_" + str(cur_inst_id - starting_core_id)
    if not os.path.isdir(cur_output_dir_str):
        os.mkdir(cur_output_dir_str)

    cur_output_file = os.path.join(cur_output_dir_str, "output.txt")

    cur_output_file_2 = os.path.join(cur_output_dir_str, "output_AFL.txt")
    cur_output_file_2 = open(cur_output_file_2, "w")

    # Prepare for env shared by the fuzzer and mysql.
    cur_port_num = port_starting_num + cur_inst_id - starting_core_id
    socket_path = "/tmp/mysql_" + str(cur_inst_id) + ".sock"

    # modi_env = dict()
    # modi_env["AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES"] = "1"
    # modi_env["AFL_SKIP_CPUFREQ"] = "1"

    fuzzing_command = [
        # "strace -s 2000 -o afl-fuzz-strace_output_" + str(cur_inst_id - starting_core_id),
        # "gdb --ex=run --args",
        "./afl-fuzz",
        "-t", "2000",
        "-m", "none",
        "-P", str(cur_port_num),
        "-K", socket_path,
        "-i", "./inputs",
        "-o", cur_output_dir_str,
        "-c", str(cur_inst_id),
        "-O", oracle_str
        ]

    if is_non_deter == True:
        fuzzing_command.append("-w")

    fuzzing_command.append("aaa")

    fuzzing_command = " ".join(fuzzing_command)
    print("Running fuzzing command: " + fuzzing_command)
    # p = subprocess.Popen(
                        # fuzzing_command,
                        # cwd=os.getcwd(),
                        # shell=True,
                        # stderr=cur_output_file_2,
                        # stdout=cur_output_file_2,
                        # stdin=subprocess.DEVNULL,
                        # env=modi_env
                        # )

    cur_window = session.new_window(attach=True, window_name="fuzzing_test_"+str(cur_inst_id - starting_core_id))
    cur_pane = cur_window.attached_pane
    cur_pane.send_keys(fuzzing_command)

    # Read the current generated shm_mem_id
    while not (os.path.isfile(os.path.join(os.getcwd(), "shm_env.txt"))):
        time.sleep(1)
    shm_env_fd = open(os.path.join(os.getcwd(), "shm_env.txt"))
    cur_shm_str = shm_env_fd.read()
    shm_env_fd.close()

    os.remove(os.path.join(os.getcwd(), "shm_env.txt"))

    mysql_bin_dir = os.path.join(mysql_root_dir, "sql/mariadbd")

    # mysql_command = "__AFL_SHM_ID=" + cur_shm_str + " " + mysql_bin_dir + " --basedir=" + mysql_root_dir + " --datadir=" + cur_mysql_data_dir_str + " --port=" + str(cur_port_num) + " --socket=" + socket_path + " & "

    mysql_command = [
        #"gdb --ex=run --args",
        # "strace -s 2000 -o mysqld_strace_output_" + str(cur_inst_id - starting_core_id),
        "env __AFL_SHM_ID=" + cur_shm_str,
        mysql_bin_dir,
        # "--basedir=" + mysql_root_dir,
        "--datadir=" + cur_mysql_data_dir_str,
        "--port=" + str(cur_port_num),
        "--socket=" + socket_path,
        "--performance_schema=OFF",
        " & " # run in the background
     ]

    # mysql_modi_env = dict()
    # mysql_modi_env["__AFL_SHM_ID"] = cur_shm_str

    mysql_command = " ".join(mysql_command)

    print("Running mariadbd command: " + mysql_command)

    cur_window = session.new_window(attach=True, window_name="mysql_test_"+str(cur_inst_id - starting_core_id))
    cur_pane = cur_window.attached_pane
    cur_pane.send_keys(mysql_command)

    all_mysql_server_tmux_window.append([cur_window, mysql_command, cur_mysql_data_dir_str])

    time.sleep(1)


print("Finished launching the fuzzing. ")

# Avoid script exist
while True:
    time.sleep(10)

    # Go through all the created window, check whether the mysqld process is still active.
    for cur_window, mysql_command, cur_mysql_data_dir_str in all_mysql_server_tmux_window:
        is_crash = False

        cur_pane = cur_window.attached_pane

        cur_pane.send_keys("jobs -l &> mariadbd_background_pid")

        time.sleep(1)

        with open("./mariadbd_background_pid", "r") as pid_file:
            pid_file_str = pid_file.read()
            if "mariadbd" in pid_file_str and "Running" in pid_file_str:
                is_crash = False
            else:
                is_crash = True

        os.remove("./mariadbd_background_pid")

        if is_crash:
            if os.path.isdir(cur_mysql_data_dir_str):
                shutil.rmtree(cur_mysql_data_dir_str)
            shutil.copytree(mysql_src_data_dir, cur_mysql_data_dir_str)
            cur_pane.send_keys(mysql_command)

