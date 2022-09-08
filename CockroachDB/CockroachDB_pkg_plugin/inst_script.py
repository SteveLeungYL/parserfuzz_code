import os
import sys
import getopt
from loguru import logger

db_dir = "./cockroach"
opts = []

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

# Iterate all files in the CockroachDB source folder. 
for subdir, _, files in os.walk("./"):
    for cur_file in files:
        # only instrument .go files.
        if cur_file[-3:] != ".go":
            logger.debug("Ignore file: %s %s" % (subdir, cur_file))
            continue

        cur_file_dir = os.path.join("./", subdir, cur_file)

        tmp_contents = ""
        with open(cur_file_dir, "r") as fd:
            is_imported = False
            for cur_line in fd.readlines():
                if not is_imported and "import" in cur_line:
                    is_imported = True
                    tmp_contents += "import \"github.com/globalcov\"\n"
                    logger.debug("Importing file: %s %s" % (subdir, cur_file))

                tmp_contents += cur_line

        logger.debug("Getting instrumented file: \n%s\n" % (tmp_contents))

        with open(cur_file_dir, "w") as fd:
            fd.write(tmp_contents)

