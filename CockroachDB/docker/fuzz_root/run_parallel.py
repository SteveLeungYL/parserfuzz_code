import time
import os
import subprocess
import getopt
import sys
import shutil

fuzz_root_dir = os.getcwd()

starting_core_id = 0
parallel_num = 5
port_starting_num = 7000

# Parse the command line arguments:
output_dir_str = ""
oracle_str = "OPT"
feedback_str = ""

try:
    opts, args = getopt.getopt(sys.argv[1:], "o:c:n:O:F:", ["odir=", "start-core=", "num-concurrent=", "oracle=", "feedback="])
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
    elif opt in ("-F", "--feedback"):
        feedback_str = arg
        print("Using feedback: %s " % (feedback_str))
    else:
        print("Error. Input arguments not supported. \n")
        exit(1)

sys.stdout.flush()

for cur_inst_id in range(starting_core_id, starting_core_id + parallel_num, 1):
    print("Setting up core_id: " + str(cur_inst_id))

    # Set up SQLRight output folder
    cur_workdir = ""
    if output_dir_str != "":
        cur_workdir = output_dir_str + "/outputs_"  + str(cur_inst_id - starting_core_id)
    else:
        cur_workdir = "./outputs/outputs_" + str(cur_inst_id - starting_core_id)
    if output_dir_str != "" and not os.path.isdir(output_dir_str):
        os.mkdir(output_dir_str)
    elif not os.path.isdir("./outputs"):
        os.mkdir("outputs")
    if not os.path.isdir(cur_workdir):
        os.mkdir(cur_workdir)

    # Copy everything to the working dir. 
    shutil.copy2("./afl-fuzz", os.path.join(cur_workdir, "afl-fuzz"))
    shutil.copy2("./covtest.test", os.path.join(cur_workdir, "covtest.test"))
    shutil.copy2("./sql.y", os.path.join(cur_workdir, "sql.y"))
    shutil.copyfile("./function_type_lib.json", os.path.join(cur_workdir, "./function_type_lib.json"))
    shutil.copyfile("./set_session_variables.json", os.path.join(cur_workdir, "./set_session_variables.json"))
    shutil.copyfile("./storage_parameter.json", os.path.join(cur_workdir, "./storage_parameter.json"))
    shutil.copytree("./inputs", os.path.join(cur_workdir, "inputs"))
    shutil.copytree("./cockroach_initlib", os.path.join(cur_workdir, "./cockroach_initlib"))
    shutil.copytree("./parser", os.path.join(cur_workdir, "./parser"))
    shutil.copytree("./rsg", os.path.join(cur_workdir, "./rsg"))

    cur_output_file = os.path.join(cur_workdir, "output.txt")
    cur_output_file = open(cur_output_file, "w")
    
    # Prepare for env shared by the fuzzer and cockroach. 
    cur_port_num = port_starting_num + cur_inst_id - starting_core_id

    # Start running the SQLRight fuzzer. 
    fuzzing_command = "./afl-fuzz -t 2000 -m 8000 " \
                        + " -P " + str(cur_port_num) \
                        + " -i ./inputs " \
                        + " -o " + "./" \
                        + " -c " + str(cur_inst_id) \
                        + " -O " + oracle_str

    if feedback_str != "":
        fuzzing_command += " -F " + feedback_str

    fuzzing_command +=  " aaa " + " & "  ### Anything following. Get dump aaa. 

    modi_env = dict()
    modi_env["AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES"] = "1"
    modi_env["AFL_SKIP_CPUFREQ"] = "1"
    modi_env["LD_LIBRARY_PATH"] = fuzz_root_dir

    print("Running fuzzing command: " + fuzzing_command)

    p = subprocess.Popen(
                        [fuzzing_command],
                        cwd=cur_workdir,
                        shell=True,
                        stderr=subprocess.DEVNULL,
                        stdout=subprocess.DEVNULL,
                        stdin=subprocess.DEVNULL,
                        env=modi_env
                        )


print("Finished launching the fuzzing. ")
sys.stdout.flush()

while True:
    # Infinite loop
    time.sleep(10000)
