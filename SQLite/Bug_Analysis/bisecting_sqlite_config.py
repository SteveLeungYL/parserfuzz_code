import os

SQLITE_DIR = "/home/sqlite/sqlite/sqlite/"
SQLITE_BLD_DIR = os.path.join(SQLITE_DIR, "bld")
SQLITE_BRANCH = 'master'

QUERY_SAMPLE_DIR = "/home/sqlite/sqlite/bisecting_sqlite_root/query_samples"

COMPILE_THREAD_COUNT = 12

BEGIN_COMMIT_ID = ""  # INCLUDED!!!   Earlier commit.
END_COMMIT_ID = ""   # EXCLUDED!!!   Later commit.