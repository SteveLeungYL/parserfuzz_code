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

mysql_root_dir = "/home/sly/Desktop/SQLRight/mysql_source/mysql-server-block-inst/mysql-server-mysql-8.0.27/bld_black_list"
mysql_src_data_dir = os.path.join(mysql_root_dir, "data_all/ori_data")
current_workdir = os.getcwd()

starting_core_id = 0
parallel_num = 3
port_starting_num = 9000

all_fuzzing_p_list = dict()
all_mysql_p_list = dict()
shm_env_list = []

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

signal.signal(signal.SIGTERM, exit_handler)
signal.signal(signal.SIGINT, exit_handler)
signal.signal(signal.SIGQUIT, exit_handler)
signal.signal(signal.SIGHUP, exit_handler)

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
    cur_output_dir_str = "./outputs_" + str(cur_inst_id - starting_core_id)
    if not os.path.isdir(cur_output_dir_str):
        os.mkdir(cur_output_dir_str)

    cur_output_file = os.path.join(cur_output_dir_str, "output.txt")

    cur_output_file_2 = os.path.join(cur_output_dir_str, "output_AFL.txt")
    cur_output_file_2 = open(cur_output_file_2, "w")
    
    # Prepare for env shared by the fuzzer and mysql. 
    cur_port_num = port_starting_num + cur_inst_id - starting_core_id
    socket_path = "/tmp/mysql_" + str(cur_inst_id) + ".sock"

    modi_env = dict()
    modi_env["AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES"] = "1"

    # Start running the SQLRight fuzzer. 
    # fuzzing_command = "./afl-fuzz -t 300 -m 4000 " \
    #                     + " -P " + str(cur_port_num) \
    #                     + " -K " + socket_path \
    #                     + " -i ./inputs " \
    #                     + " -o " + cur_output_dir_str \
    #                     + " -c " + str(cur_inst_id) \
    #                     + " aaa " \
    #                     + " & "
    fuzzing_command = [
        "./afl-fuzz", 
        "-t", "300", 
        "-m", "4000",
        "-P", str(cur_port_num), 
        "-K", socket_path,
        "-i", "./inputs",
        "-o", cur_output_dir_str,
        "-c", str(cur_inst_id),
        "aaa" , "&"
        ]
    fuzzing_command = " ".join(fuzzing_command)
    print("Running fuzzing command: " + fuzzing_command)
    p = subprocess.Popen(
                        fuzzing_command,
                        cwd=os.getcwd(),
                        shell=True,
                        stderr=cur_output_file_2,
                        stdout=cur_output_file_2,
                        stdin=subprocess.DEVNULL,
                        env=modi_env
                        )
    # cur_proc_l = psutil.Process(p.pid).children()
    # if len(cur_proc_l) == 1:
    #     cur_pid = cur_proc_l[0].pid
    #     all_mysql_p_list[cur_pid] = [cur_inst_id, cur_shm_str]
    #     print("Pid: %d\n\n\n" %(cur_pid))
    # else:
    #     print("Running with %d failed. \n\n\n" % (cur_inst_id))

    # Read the current generated shm_mem_id
    while not (os.path.isfile(os.path.join(os.getcwd(), "shm_env.txt"))):
        time.sleep(1)
    shm_env_fd = open(os.path.join(os.getcwd(), "shm_env.txt"))
    cur_shm_str = shm_env_fd.read()
    shm_env_list.append(cur_shm_str)
    shm_env_fd.close()

    os.remove(os.path.join(os.getcwd(), "shm_env.txt"))

    mysql_bin_dir = os.path.join(mysql_root_dir, "bin/mysqld")

    # mysql_command = "__AFL_SHM_ID=" + cur_shm_str + " " + mysql_bin_dir + " --basedir=" + mysql_root_dir + " --datadir=" + cur_mysql_data_dir_str + " --port=" + str(cur_port_num) + " --socket=" + socket_path + " & "

    mysql_command = [
        "screen",
        "-dmS",
        "test" + str(cur_inst_id),
        "bash", "-c", 
        "'",    # left quote
        mysql_bin_dir,
        "--basedir=" + mysql_root_dir,
        "--datadir=" + cur_mysql_data_dir_str,
        "--port=" + str(cur_port_num),
        "--socket=" + socket_path,
        "--performance_schema=OFF",
        "&>", cur_output_file,
        "'"  # right quote
    ]
    mysql_modi_env = dict()
    mysql_modi_env["__AFL_SHM_ID"] = cur_shm_str

    mysql_command = " ".join(mysql_command)

    print("Running mysql command: __AFL_SHM_ID=" + cur_shm_str + " " + mysql_command)
    
    p = subprocess.Popen(
                        mysql_command,
                        shell=True,
                        stderr=subprocess.DEVNULL,
                        stdout=subprocess.DEVNULL,
                        stdin=subprocess.DEVNULL,
                        env = mysql_modi_env
                        )
    time.sleep(1)
    all_mysql_p_list[cur_inst_id] = cur_shm_str

print("Finished launching the fuzzing. Now monitor the mysql process. ")

# An prarallel_num length list. 
all_prev_shutdown_time = [time.localtime()] * parallel_num

is_Test = True

while True:

    time.sleep(2)

    for cur_inst_id in range(starting_core_id, starting_core_id + parallel_num, 1):

        cur_shm_str = all_mysql_p_list[cur_inst_id]

        cur_port_num = port_starting_num + cur_inst_id - starting_core_id
        socket_path = "/tmp/mysql_" + str(cur_inst_id) + ".sock"

        is_server_down = False
        try:
            db = MySQLdb.connect(host="localhost",    # your host, usually localhost
                     user="root",         # your username
                     passwd="",  # your password
                     port=cur_port_num,
                     unix_socket=socket_path,
                     db="fuck")        # name of the data base
            db.close()
        except MySQLdb._exceptions.OperationalError:
            is_server_down = True
        
        if not is_server_down:
            continue

        # for proc in psutil.process_iter():
        #     # check whether the process name matches
        #     cur_proc_name = proc.name()
        #     print(cur_proc_name)

        ### CANNOT FIND THE MYSQL SERVER. CRASHED? 
        print("*****************\nMySQL Server with ID %d gone. Save the data folder and resume now. \n" %(cur_inst_id))

        # continue

        ### RECOVERY!!!
        ''' First, save the data folder. '''
        cur_mysql_data_dir_str = os.path.join(mysql_root_dir, "data_all/data_" + str(cur_inst_id))
        # cur_mysql_bk_data_dir_str = os.path.join(mysql_root_dir, "data_all/data_bk/")
        
        # # check whether the saving folder exists. 
        # if not os.path.isdir(cur_mysql_bk_data_dir_str):
        #     os.mkdir(cur_mysql_bk_data_dir_str)
        
        # # Find the suitable name for backup folder
        # for bk_id in range(1000):
        #     cur_mysql_bk_data_dir_str = os.path.join(mysql_root_dir, "data_all/data_bk/data_" + str(cur_inst_id) + "_" + str(bk_id))
        #     if not os.path.isdir(cur_mysql_bk_data_dir_str):
        #         break
        
        # try:
        #     # Save the bk folder. 
        #     shutil.copytree(cur_mysql_data_dir_str, cur_mysql_bk_data_dir_str)
        # except shutil.Error as err:
        #     print("Copy backup data folder failed! %d " % (cur_pid))
        #     # all_mysql_p_list.pop(cur_pid)
        #     # break


        try:
            ### DELETE THE ORIGINAL data folder, then reinvoke mysql!
            if os.path.isdir(cur_mysql_data_dir_str):
                shutil.rmtree(cur_mysql_data_dir_str)
            # print("Recovering new data dir: %s to %s"  % (mysql_src_data_dir, cur_mysql_data_dir_str))
            shutil.copytree(mysql_src_data_dir, cur_mysql_data_dir_str)
        except shutil.Error as err:
            print("Copy new data folder failed! Try again later. ID: %d. " % (cur_inst_id))
            break
        except OSError as err:
            print("Copy new data folder failed! Try again later. ID: %d. " % (cur_inst_id))
            break


        # Reinvoke mysql
        # Prepare for env shared by the fuzzer and mysql. 

        # Set up SQLRight output folder
        cur_output_dir_str = "./outputs_" + str(cur_inst_id - starting_core_id)

        cur_output_file = os.path.join(cur_output_dir_str, "output.txt")
        if os.path.isfile(cur_output_file):
            os.remove(cur_output_file)

        mysql_bin_dir = os.path.join(mysql_root_dir, "bin/mysqld")
        
        # Start the MYSQL instance
        ori_workdir = os.getcwd()

        mysql_command = [
            "screen",
            "-dmS",
            "test" + str(cur_inst_id),
            "bash", "-c", 
            "'",    # left quote
            mysql_bin_dir,
            "--basedir=" + mysql_root_dir,
            "--datadir=" + cur_mysql_data_dir_str,
            "--port=" + str(cur_port_num),
            "--socket=" + socket_path,
            "--performance_schema=OFF",
            "&>", cur_output_file,
            "'"  # right quote
        ]
        mysql_modi_env = dict()
        mysql_modi_env["__AFL_SHM_ID"] = cur_shm_str

        mysql_command = " ".join(mysql_command)

        print("Running mysql command: __AFL_SHM_ID=" + cur_shm_str + " " + mysql_command, end="\n")


        p = subprocess.Popen(
                            mysql_command,
                            shell=True,
                            stderr=subprocess.DEVNULL,
                            stdout=subprocess.DEVNULL,
                            stdin=subprocess.DEVNULL,
                            env = mysql_modi_env
                            )

        print("Finished running popen. \n")
        time.sleep(1)
        
        cur_output_file_r = os.path.join(cur_output_dir_str, "output.txt")

        if not os.path.isfile(cur_output_file_r):
            # Failed to boot mysql. Try again later. 
            print("Waiting for the mysql to reboot. Current output dir is: " + cur_output_file_r + "\n")
            continue

        # Break the loop. Do not continue in this round. In case of race condition for all_mysql_p_list
        break

    # SHUTDOWN MYSQL, periodically. 
    for prev_shutdown_time_idx in range(len(all_prev_shutdown_time)):
        prev_shutdown_time = all_prev_shutdown_time[prev_shutdown_time_idx]

        if (time.mktime(time.localtime())  -  time.mktime(prev_shutdown_time))  > 60: # 60 sec, restart mysql

            print("******************\nBegin scheduled MYSQL restart. ID: %d\n" % (prev_shutdown_time_idx))
            # Politely, restart MySQL. 
            cur_port_num = port_starting_num + prev_shutdown_time_idx - starting_core_id
            socket_path = "/tmp/mysql_" + str(prev_shutdown_time_idx) + ".sock"

            try:
                db = MySQLdb.connect(host="localhost",    # your host, usually localhost
                     user="root",         # your username
                     passwd="",  # your password
                     port=cur_port_num,
                     unix_socket=socket_path,
                     db="fuck")        # name of the data base
            except MySQLdb._exceptions.OperationalError:
                print("MYSQL server down, not recovered yet. \n\n\n")
                continue
            
            cur = db.cursor()

            cur.execute("SHUTDOWN;")

            db.close()

            time.sleep(2)

            # Update shutdown time. 
            all_prev_shutdown_time[prev_shutdown_time_idx] = time.localtime()

            print("MYSQL shutdown completed. ID: %d\n\n\n" % (prev_shutdown_time_idx))

            # 2 more seconds would be waited until the new MYSQL is being started. Thus, there would be more than 2 seconds between every MYSQL process restart. 
            # The actual restart of mysql is being handle by the same MYSQL crash handler. (Above)
            continue


            

