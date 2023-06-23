from enum import Enum
import os

BISECTING_SCRIPTS_ROOT = "/home/mysql/bisecting_scripts"
MYSQL_ROOT = "/home/mysql/mysql_binary"
MYSQL_SRC = "/home/mysql/mysql-server"

BUG_SAMPLES_PATH = os.path.join(BISECTING_SCRIPTS_ROOT, "bug_samples")
LOG_OUTPUT_FILE = os.path.join(BISECTING_SCRIPTS_ROOT, "logs.txt")
FAILED_COMPILE_COMMITS = os.path.join(BISECTING_SCRIPTS_ROOT, "FAILED_COMPILE_COMMITS.json")

UNIQUE_BUG_JSON = os.path.join(BISECTING_SCRIPTS_ROOT, "bug_samples/unique_bug.json")
MYSQL_SORTED_COMMITS = os.path.join( BISECTING_SCRIPTS_ROOT, "assets/sorted_commits.json")

MYSQL_SERVER_SOCKET = "/tmp/mysql_0.sock"
MYSQL_SERVER_PORT = "8000"

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
