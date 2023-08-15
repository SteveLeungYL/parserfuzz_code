from enum import Enum
import os

# IMPORTANT VARIBLES to setup
BISECTING_SCRIPTS_ROOT = "/home/tidb/bisecting/bisecting_scripts"
TIDB_CACHE_ROOT = "/home/tidb/tidb_binary"
TIDB_SRC = "/home/tidb/go_projects/src/github.com/tidb/tidb"

TIDB_SERVER_SOCKET = "/tmp/mysql_0.sock"
TIDB_SERVER_PORT = "8000"

# Auto setup variables
BUG_SAMPLES_PATH = os.path.join(BISECTING_SCRIPTS_ROOT, "bug_samples")
LOG_OUTPUT_FILE = os.path.join(BISECTING_SCRIPTS_ROOT, "logs.txt")
FAILED_COMPILE_COMMITS = os.path.join(BISECTING_SCRIPTS_ROOT, "FAILED_COMPILE_COMMITS.json")

UNIQUE_BUG_JSON = os.path.join(BISECTING_SCRIPTS_ROOT, "unique_bug.json")
TIDB_SORTED_COMMITS = os.path.join( BISECTING_SCRIPTS_ROOT, "assets/sorted_commits.json")

class RESULT(Enum):
    PASS = 1
    SEG_FAULT = 0
    FAIL_TO_COMPILE = -1

    @classmethod
    def has_value(cls, value):
        return value in cls._value2member_map_

class BisectingResults:
    query = []
    src = "Unknown"
    first_buggy_commit_id: str = "Unknown"
    first_corr_commit_id: str = "Unknown"
    final_res_flag: RESULT = RESULT.PASS
    unique_bug_id_int = "Unknown"
    dup_bug_id_list = []
    bisecting_error_reason: str = ""
