import os
import re

import constants
from loguru import logger
import os

def read_queries_from_files():

    def get_contents(input_file_name):
        with open(input_file_name, errors="replace") as f:
            contents = f.read()

        contents = re.sub(r"[^\x00-\x7F]+", " ", contents)
        contents = contents.replace("\ufffd", " ")

        # Filter out the irrelevant strings.
        if "Query: 0:" in contents:
            contents = contents.split("Query: 0:")[1]
        if "Query:" in contents:
            contents = contents.split("Query")[1]
        if "Result string:" in contents:
            contents = contents.split("Result string:")[0]
        if "--stack_out:\n" in contents:
            tmpContents = contents.split("--stack_out:\n")[0]
            stack = contents.split("--stack_out:\n")[1]
            if "handleCompareSubquery" in stack or \
                "ExtractSelectAndNormalizeDigest" in stack or \
                "buildSelect" in stack or \
                "scalar_function.go" in stack or \
                "getRecoverTableByTableName" in stack or \
                "handleScalarSubquery" in stack:
                    contents = ""
            else:
                contents = tmpContents

        return contents

    tidb_bug_root = os.path.join(constants.BUG_SAMPLES_PATH)
    cur_parser_bug_root = os.path.join(tidb_bug_root, "parser_crash")
    cur_crash_bug_root = os.path.join(tidb_bug_root, "crashes")
    total_bug_num = 0
    if os.path.isdir(cur_parser_bug_root):
        total_bug_num += len(os.listdir(cur_parser_bug_root))
    if os.path.isdir(cur_crash_bug_root):
        total_bug_num += len(os.listdir(cur_crash_bug_root))

    bug_scan_index = 0

    logger.info(f"Getting {total_bug_num} number of bugs that needs bisecting. ")

    if os.path.isdir(cur_parser_bug_root):
        all_files = list(os.listdir(cur_parser_bug_root))
        all_files = [os.path.join(cur_parser_bug_root, f) for f in all_files]
        all_files.sort(key=lambda x: os.path.getctime(x))
        for cur_file in all_files:
            bug_scan_index+=1
            logger.info(f"Currently scanning file: {bug_scan_index}/{total_bug_num}: {cur_file}")
            cur_query = get_contents(cur_file)
            if cur_query == "":
                continue
            yield cur_file, cur_query

    if os.path.isdir(cur_crash_bug_root):
        all_files = list(os.listdir(cur_crash_bug_root))
        all_files = [os.path.join(cur_crash_bug_root, f) for f in all_files]
        all_files.sort(key=lambda x: os.path.getctime(x))
        for cur_file in all_files:
            bug_scan_index+=1
            logger.info(f"Currently scanning file: {bug_scan_index}/{total_bug_num}: {cur_file}")
            cur_query = get_contents(cur_file)
            if cur_query == "":
                continue
            yield cur_file, cur_query

    logger.info("Finished reading all the query files from the bug input folder. ")
