import tidb_driver
import constants
import utils
from loguru import logger

def filter_known_bugs(query: str, file_name: str, all_commit_str: [str]):
    # Return is_known bugs.

    current_bisecting_result = constants.BisectingResults()
    current_bisecting_result.src = file_name

    logger.info("Trying to check the oldest commit first. \n")
    oldest_commit = all_commit_str[len(all_commit_str)-1]
    if tidb_driver.execute_queries(query, oldest_commit) == constants.RESULT.SEG_FAULT:
        logger.info("Bisecting failed. The oldest possible commit is still showing SEG_FAULT. ")
        current_bisecting_result.first_buggy_commit_id = oldest_commit 
        current_bisecting_result.first_corr_commit_id = "" 
        current_bisecting_result.query = query

        return current_bisecting_result


    logger.info("Trying to filter based on known bug reports. \n")

    all_known_bugs = utils.load_buggy_commit()
    if len(all_known_bugs) == 0:
        logger.info("No previous known bugs. ")
        return None
    
    for cur_known_bug in all_known_bugs:
        buggy_commit = cur_known_bug["first_buggy_commit_id"]
        corr_commit = cur_known_bug["first_corr_commit_id"]

        if corr_commit == "":
            logger.debug(f"Skip current known bug because corr_commit is empty. Buggy_commit: {buggy_commit}")
            continue

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