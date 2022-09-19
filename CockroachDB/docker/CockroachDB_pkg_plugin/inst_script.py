import os
import sys
import getopt
from loguru import logger

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
        if cur_file[-3:] != ".go" or "doc.go" in cur_file:
            logger.debug("Ignore file: %s %s" % (subdir, cur_file))
            continue

        cur_file_dir = os.path.join("./", subdir, cur_file)

        tmp_contents = ""
        # TODO: Fix later
        # is_func_existed = False
        is_func_existed = True

        with open(cur_file_dir, "r") as fd:
            is_package = False
            is_already_imported = False

            all_lines = fd.readlines()
            for cur_line in all_lines:
                if "github.com/globalcov" in cur_line:
                    is_already_imported = True
                    break

            for cur_line in all_lines:
                tmp_contents += cur_line

                # Add the import line immediately after the package line. 
                if not is_package and cur_line[:8] == "package ":
                    is_package = True
                    tmp_contents += "\nimport \"github.com/globalcov\"\n"
                    logger.debug("Importing file: %s %s" % (subdir, cur_file))

                # Check whether there are func in the file. If not, do not append
                # the import
                if cur_line[:5] == "func ":
                    is_func_existed = True


        tmp_contents += "\nvar ( dumplog_%d = globalcov.LogGlobalCov );" % (global_idx)
        global_idx+=1

        if is_func_existed and not is_already_imported:
            # logger.debug("Getting instrumented file: \n%s\n" % (tmp_contents))
            with open(cur_file_dir, "w") as fd:
                fd.write(tmp_contents)
        else:
            logger.debug("Importing file: %s %s because there are no functions inside. " % (subdir, cur_file))
