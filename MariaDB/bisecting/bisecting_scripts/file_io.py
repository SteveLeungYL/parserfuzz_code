import os
import re
from typing import List

import constants
from pathlib import Path
from loguru import logger
import os

def read_queries_from_files():

    def get_contents(file):
        with open(file, errors="replace") as f:
            contents = f.read()

        contents = re.sub(r"[^\x00-\x7F]+", " ", contents)
        contents = contents.replace("\ufffd", " ")
        if "Original crashing Query:" in contents:
            contents = contents.split("Original crashing Query:")[1]
        return contents

    def debug_print_queries(queries):
        logger.debug("print queries for debug purpose. \n")
        logger.debug(queries)

    mysql_samples = Path(constants.BUG_SAMPLES_PATH)
    sample_files = [sample for sample in mysql_samples.glob("*")]
    sample_files = list(filter(lambda x: x.is_file(), sample_files))
    sample_files.sort(key=os.path.getctime)
    
    logger.info(f"Getting {len(sample_files)} number of bugs that needs bisecting. ")

    for index, sample_file_name in enumerate(sample_files):
        logger.debug(f"Got sample - {index}: {sample_file_name}")
        cur_query = get_contents(sample_file_name)
        # debug_print_queries(cur_query)
        yield str(sample_file_name.stem), cur_query

    logger.info("Finished reading all the query files from the bug input folder. ")
