import re
import time
import os
import shutil
import subprocess
import atexit
import signal
import psutil

mysql_root_dir = "/home/sly/Desktop/SQLRight/mysql_source/mysql-server-mysql-8.0.27/bld"
mysql_src_data_dir = os.path.join(mysql_root_dir, "data_all/ori_data")
current_workdir = os.getcwd()

starting_core_id = 0
parallel_num = 5
port_starting_num = 8100

all_fuzzing_p_list = dict()
all_mysql_p_list = dict()
shm_env_list = []

def exit_handler(signal, frame):
    for fuzzing_instance, _ in all_fuzzing_p_list.items():
        print("kill -9 %d" % (fuzzing_instance))
        os.kill(fuzzing_instance, 9)
    for mysql_instance, _ in all_mysql_p_list.items():
        print("kill -9 %d" % (mysql_instance))
        os.kill(mysql_instance, 9)
    exit()

def check_pid_exist(pid: int):
    try:
        os.kill(pid, 0)
    except OSError:
        return False
    else:
        return True

signal.signal(signal.SIGTERM, exit_handler)
signal.signal(signal.SIGINT, exit_handler)

if os.path.isfile(os.path.join(os.getcwd(), "shm_env.txt")):
    os.remove(os.path.join(os.getcwd(), "shm_env.txt"))

for cur_inst_id in range(starting_core_id, starting_core_id + parallel_num, 1):
    print("Setting up core_id: " + str(cur_inst_id))

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
    cur_output_file = open(cur_output_file, "w")
    
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
    print("Running fuzzing command: " + " ".join(fuzzing_command))
    p = subprocess.Popen(
                        fuzzing_command,
                        cwd=os.getcwd(),
                        shell=False,
                        stderr=cur_output_file,
                        stdout=cur_output_file,
                        stdin=subprocess.DEVNULL,
                        env=modi_env
                        )
    all_fuzzing_p_list[p.pid] = cur_inst_id
    print("Pid: %d\n\n\n" %(p.pid))

    # Read the current generated shm_mem_id
    while not (os.path.isfile(os.path.join(os.getcwd(), "shm_env.txt"))):
        time.sleep(1)
    shm_env_fd = open(os.path.join(os.getcwd(), "shm_env.txt"))
    cur_shm_str = shm_env_fd.read()
    shm_env_list.append(cur_shm_str)
    shm_env_fd.close()

    os.remove(os.path.join(os.getcwd(), "shm_env.txt"))

    # Start the MySQL instance
    ori_workdir = os.getcwd()
    os.chdir(mysql_root_dir)

    mysql_bin_dir = os.path.join(mysql_root_dir, "bin/mysqld")

    # mysql_command = "__AFL_SHM_ID=" + cur_shm_str + " " + mysql_bin_dir + " --basedir=" + mysql_root_dir + " --datadir=" + cur_mysql_data_dir_str + " --port=" + str(cur_port_num) + " --socket=" + socket_path + " & "

    mysql_command = [
        mysql_bin_dir,
        "--basedir=" + mysql_root_dir,
        "--datadir=" + cur_mysql_data_dir_str,
        "--port=" + str(cur_port_num),
        "--socket=" + socket_path
    ]
    mysql_modi_env = dict()
    mysql_modi_env["__AFL_SHM_ID"] = cur_shm_str

    print("Running mysql command: __AFL_SHM_ID=" + cur_shm_str + " " + " ".join(mysql_command))
    

    p = subprocess.Popen(
                        mysql_command,
                        cwd=mysql_root_dir,
                        shell=False,
                        stderr=subprocess.DEVNULL,
                        stdout=subprocess.DEVNULL,
                        stdin=subprocess.DEVNULL,
                        env = mysql_modi_env
                        )
    all_mysql_p_list[p.pid] = [cur_inst_id, cur_shm_str]
    os.chdir(ori_workdir)
    print("Pid: %d\n\n\n" %(p.pid))

print("Finished launching the fuzzing. Now monitor the mysql process. ")


while True:

    ### TODO: Make it larger. 
    time.sleep(10)

    for cur_pid, (cur_inst_id, cur_shm_str) in all_mysql_p_list.items():

        if check_pid_exist(cur_pid):
            # pid still exists. 
            proc = psutil.Process(cur_pid)
            if proc.status() != psutil.STATUS_ZOMBIE and proc.status() != psutil.STATUS_DEAD:
                # print("Pid: %d still exists. And it is not a zombile process. " % cur_pid)
                continue

        ### CANNOT FIND THE MYSQL SERVER. CRASHED? 
        print("*****************\nMySQL Server with PID %d gone. Save the data folder and resume now. \n" %(cur_pid))

        # continue

        ### RECOVERY!!!
        ''' First, save the data folder. '''
        cur_mysql_data_dir_str = os.path.join(mysql_root_dir, "data_all/data_" + str(cur_inst_id))
        cur_mysql_bk_data_dir_str = os.path.join(mysql_root_dir, "data_all/data_bk/")
        
        # check whether the saving folder exists. 
        if not os.path.isdir(cur_mysql_bk_data_dir_str):
            os.mkdir(cur_mysql_bk_data_dir_str)
        
        # Find the suitable name for backup folder
        for bk_id in range(1000):
            cur_mysql_bk_data_dir_str = os.path.join(mysql_root_dir, "data_all/data_bk/data_" + str(cur_inst_id) + "_" + str(bk_id))
            if not os.path.isdir(cur_mysql_bk_data_dir_str):
                break
        
        # Save the bk folder. 
        shutil.copytree(cur_mysql_data_dir_str, cur_mysql_bk_data_dir_str)

        ### DELETE THE ORIGINAL data folder, then reinvoke mysql!
        if os.path.isdir(cur_mysql_data_dir_str):
            shutil.rmtree(cur_mysql_data_dir_str)
        shutil.copytree(mysql_src_data_dir, cur_mysql_data_dir_str)

        # Reinvoke mysql
        # Prepare for env shared by the fuzzer and mysql. 
        mysql_bin_dir = os.path.join(mysql_root_dir, "bin/mysqld")
        cur_port_num = port_starting_num + cur_inst_id - starting_core_id
        socket_path = "/tmp/mysql_" + str(cur_inst_id) + ".sock"
        
        # Start the MYSQL instance
        ori_workdir = os.getcwd()
        os.chdir(mysql_root_dir)

        mysql_command = [
            mysql_bin_dir,
            "--basedir=" + mysql_root_dir,
            "--datadir=" + cur_mysql_data_dir_str,
            "--port=" + str(cur_port_num),
            "--socket=" + socket_path
            ]
        mysql_modi_env = dict()
        mysql_modi_env["__AFL_SHM_ID"] = cur_shm_str

        print("Running mysql command: __AFL_SHM_ID=" + cur_shm_str + " " + " ".join(mysql_command), end="\n\n\n\n\n\n")


        p = subprocess.Popen(
                            mysql_command,
                            cwd=mysql_root_dir,
                            shell=False,
                            stderr=subprocess.DEVNULL,
                            stdout=subprocess.DEVNULL,
                            stdin=subprocess.DEVNULL,
                            env = mysql_modi_env
                            )

        # Pop the old pid, save the new one. Then change dir to the original dir. 
        all_mysql_p_list.pop(cur_pid)
        all_mysql_p_list[p.pid] = [cur_inst_id, cur_shm_str]
        os.chdir(ori_workdir)

        # Break the loop. Do not continue in this round. In case of race condition for all_mysql_p_list
        break


