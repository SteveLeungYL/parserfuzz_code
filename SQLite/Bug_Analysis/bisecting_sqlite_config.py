import os

SQLITE_DIR = "/home/sqlite/sqlite/sqlite/"
SQLITE_BLD_DIR = os.path.join(SQLITE_DIR, "bld")  # Change to your own sqlite3 repo root dir.
SQLITE_BRANCH = 'master'

QUERY_SAMPLE_DIR = "/home/sqlite/sqlite/bisecting_sqlite_root/query_samples"  # Change to your own query_samples dir.

COMPILE_THREAD_COUNT = 12
COMMIT_SEARCH_RANGE = 10

BEGIN_COMMIT_ID = ""  # INCLUDED!!!   Earlier commit.
END_COMMIT_ID = "9cb02640419614ae3771ebbffce076474380029b"   # EXCLUDED!!!   Later commit.