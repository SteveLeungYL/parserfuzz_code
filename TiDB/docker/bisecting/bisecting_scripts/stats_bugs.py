import tidb_driver
import constants
import utils
from loguru import logger

def filter_known_bugs(query: str, file_name: str):
    # Return is_known bugs.

    all_known_bugs = utils.load_buggy_commit()
    if len(all_known_bugs) == 0:
        return None

    current_bisecting_result = constants.BisectingResults()
    current_bisecting_result.src = file_name

    logger.info("Trying to filter based on known bug reports. \n")
    
    for cur_known_bug in all_known_bugs:
        buggy_commit = cur_known_bug["first_buggy_commit_id"]
        corr_commit = cur_known_bug["first_corr_commit_id"]

        if tidb_driver.execute_queries(query, buggy_commit) == constants.RESULT.SEG_FAULT and \
            tidb_driver.execute_queries(query, corr_commit) == constants.RESULT.PASS:
            # Match the bug introducing commit.

            logger.info("Matched the previous known bisecting commits. ")
            current_bisecting_result.first_buggy_commit_id = buggy_commit
            current_bisecting_result.first_corr_commit_id = corr_commit
            current_bisecting_result.query = query

            return current_bisecting_result

    logger.info("Matching failed. Begin bisecting. ")
    return None