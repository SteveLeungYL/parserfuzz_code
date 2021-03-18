import os

SQLITE_DIR = "/home/sqlite/sqlite/sqlite/"
SQLITE_BLD_DIR = os.path.join(SQLITE_DIR, "bld")  # Change to your own sqlite3 repo root dir.
SQLITE_BRANCH = 'master'

QUERY_SAMPLE_DIR = "/home/sqlite/sqlite/bisecting_sqlite_root/query_samples"  # Change to your own query_samples dir.

LOG_OUTPUT_DIR = "/home/sqlite/sqlite/bisecting_sqlite_root"
LOG_OUTPUT_FILE = os.path.join(LOG_OUTPUT_DIR, "bisecting_sqlite_log.txt")
UNIQUE_BUG_OUTPUT_DIR = os.path.join(LOG_OUTPUT_DIR, "UniqBug_output")

COMPILE_THREAD_COUNT = 12
COMMIT_SEARCH_RANGE = 1

BEGIN_COMMIT_ID = ""  # INCLUDED!!!   Earlier commit.
END_COMMIT_ID = ""   # EXCLUDED!!!   Later commit.