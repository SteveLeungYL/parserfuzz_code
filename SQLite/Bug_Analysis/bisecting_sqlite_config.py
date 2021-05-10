import os

SQLITE_DIR = "/home/sqlite/sqlite/sqlite/"
SQLITE_BLD_DIR = os.path.join(SQLITE_DIR, "bld")  # Change to your own sqlite3 repo root dir.
SQLITE_BRANCH = 'master'

QUERY_SAMPLE_DIR = "/home/sqlite/fuzz_parallel_1/bug_analysis/bug_samples/"  # Change to your own query_samples dir.

LOG_OUTPUT_DIR = "/home/sqlite/fuzz_parallel_1/bug_analysis/"
LOG_OUTPUT_FILE = os.path.join(LOG_OUTPUT_DIR, "bisecting_sqlite_log.txt")
UNIQUE_BUG_OUTPUT_DIR = os.path.join(LOG_OUTPUT_DIR, "unique_bug_output")

COMPILE_THREAD_COUNT = 12
COMMIT_SEARCH_RANGE = 1

BEGIN_COMMIT_ID = ""  # INCLUDED!!!   Earlier commit.
END_COMMIT_ID = ""   # EXCLUDED!!!   Later commit.


# For fuzzing
MAX_FUZZING_INSTANCE = 3
FUZZING_ROOT_DIR = "/home/sqlite/fuzz_parallel_1/"
SQLITE_FUZZING_BINARY_PATH = "/home/sqlite/sqlite/sqlite/bld/3ddc3809bf6148d09ea02345deade44873b9064f_AFL/sqlite3"
FUZZING_COMMAND = "AFL_SKIP_CPUFREQ=1 AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1  ../afl-fuzz -i ./inputs/ -o ./ -E "
