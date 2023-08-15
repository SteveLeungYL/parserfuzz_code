import os
import re
from typing import List

import constants
from pathlib import Path
from loguru import logger
import os

def read_queries_from_files():

    def get_contents(input_file_name):
        with open(input_file_name, errors="replace") as f:
            contents = f.read()

        contents = re.sub(r"[^\x00-\x7F]+", " ", contents)
        contents = contents.replace("\ufffd", " ")
        return contents

    def debug_print_queries(queries):
        logger.debug("print queries for debug purpose. \n")
        logger.debug(queries)

    tidb_bug_root = os.path.join(constants.BUG_SAMPLES_PATH)
    cur_parser_bug_root = os.path.join(tidb_bug_root, "parser_crash")
    cur_crash_bug_root = os.path.join(tidb_bug_root, "crashes")
    total_bug_num = len(os.listdir(cur_parser_bug_root)) + len(os.listdir(cur_crash_bug_root))
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
            yield cur_file, cur_query

    if os.path.isdir(cur_crash_bug_root):
        all_files = list(os.listdir(cur_crash_bug_root))
        all_files = [os.path.join(cur_crash_bug_root, f) for f in all_files]
        all_files.sort(key=lambda x: os.path.getctime(x))
        for cur_file in all_files:
            bug_scan_index+=1
            logger.info(f"Currently scanning file: {bug_scan_index}/{total_bug_num}: {cur_file}")
            cur_query = get_contents(cur_file)
            yield cur_file, cur_query

    logger.info("Finished reading all the query files from the bug input folder. ")
