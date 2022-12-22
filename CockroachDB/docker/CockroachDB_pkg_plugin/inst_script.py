import os
import sys
import getopt
from loguru import logger
import subprocess

db_dir = "./cockroach"
opts = []

logger.remove()
logger.add(sys.stdout, level="INFO")

try:
    opts, args = getopt.getopt(sys.argv[1:], "i:", ["db-dir="])
except getopt.GetoptError:
    logger.error("Input flag error. Expected flag -i or -db-dir only. ")

for opt, arg in opts:
    if opt in ("-i", "--db-dir"):
        db_dir = arg
        logger.debug("Using CockroachDB source dir: %s" % (db_dir))
    else:
        logger.error("Error: getting unexpected flag: %s" % (opt))
        exit(1)

if not os.path.isdir(db_dir):
    logger.error("The requested dir: %s is not existed. Error" % (db_dir))
    exit(1)

os.chdir(db_dir)

global_idx = 0

# Iterate all files in the CockroachDB source folder. 
for subdir, _, files in os.walk("./"):
    for cur_file in files:
        # only instrument .go files.
        if cur_file[-3:] != ".go" or "doc.go" in cur_file or "test" in cur_file:
            logger.debug("Ignore file: %s %s" % (subdir, cur_file))
            continue

        cur_file_dir = os.path.join("./", subdir, cur_file)

        tmp_contents = ""

        is_instr = False

        with open(cur_file_dir, "r") as fd:

            whole_file_str = fd.read()

            if "github.com/globalcov" in whole_file_str:
                is_instr = True

        if not is_instr:
            
            instr_command_str = "./goInstr --file=%s --idx=%d" % (cur_file_dir, global_idx)
            global_idx += 1

            logger.debug("Running with command: %s\n" % (instr_command_str))

            process = subprocess.Popen(instr_command_str, shell=True)
            process.wait()

            logger.debug("Finished running goInstr on file: %s" % (cur_file_dir))
