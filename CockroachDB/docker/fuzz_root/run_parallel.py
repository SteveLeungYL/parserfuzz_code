import time
import os
import subprocess
import getopt
import sys

current_workdir = os.getcwd()

starting_core_id = 0
parallel_num = 1
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
    cur_output_dir_str = ""
    if output_dir_str != "":
        cur_output_dir_str = output_dir_str + "/outputs_"  + str(cur_inst_id - starting_core_id)
    else:
        cur_output_dir_str = "./outputs/outputs_" + str(cur_inst_id - starting_core_id)
    if not os.path.isdir(cur_output_dir_str):
        os.mkdir(cur_output_dir_str)

    cur_output_file = os.path.join(cur_output_dir_str, "output.txt")
    cur_output_file = open(cur_output_file, "w")
    
    # Prepare for env shared by the fuzzer and cockroach. 
    cur_port_num = port_starting_num + cur_inst_id - starting_core_id

    # Start running the SQLRight fuzzer. 
    fuzzing_command = "./afl-fuzz -t 2000 -m 2000 " \
                        + " -P " + str(cur_port_num) \
                        + " -i ./inputs " \
                        + " -o " + cur_output_dir_str \
                        + " -c " + str(cur_inst_id) \
                        + " -O " + oracle_str

    if feedback_str != "":
        fuzzing_command += " -F " + feedback_str

    fuzzing_command +=  " aaa " + " & "

    modi_env = dict()
    modi_env["AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES"] = "1"
    modi_env["AFL_SKIP_CPUFREQ"] = "1"

    print("Running fuzzing command: " + fuzzing_command)

    p = subprocess.Popen(
                        [fuzzing_command],
                        cwd=os.getcwd(),
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
