import mysql
import constants
import utils
from loguru import logger
import stats_bugs

def start_bisect(file_name: str, queries: str, all_commits):

    current_bisecting_result = stats_bugs.filter_known_bugs(queries, file_name=file_name)
    if current_bisecting_result is not None:
        utils.dump_buggy_commit(current_bisecting_result)
        return True

    current_bisecting_result = bisecting_commits(file_name, queries, all_commits)
    utils.dump_buggy_commit(current_bisecting_result)

    return False

def bisecting_commits(file_name: str, query: str, all_commits_str):

    # The buggy commit, which is the commit that introduce the bug.
    newer_commit_index = 0
    # The correct commit, which is the commit right before the bug introducing one.
    older_commit_index = len(all_commits_str)-1

    # Initialize the new bisecting results struct.  
    rn_correctness = constants.RESULT.PASS
    current_bisecting_result = constants.BisectingResults()
    current_bisecting_result.src = file_name

    is_buggy_commit_found = False

    logger.debug(f"Inside bisecting_commits function. \n")

    while not is_buggy_commit_found:

        if abs(newer_commit_index - older_commit_index) <= 1:
            # Found the bug introduced commit. 
            logger.debug(
                f"found buggy_commit: {newer_commit_index} : {older_commit_index}"
            )
            is_buggy_commit_found = True
            break

        # Approximate towards 0 (newer).
        tmp_commit_index = int((newer_commit_index + older_commit_index) / 2)

        commit_ID = all_commits_str[tmp_commit_index]

        rn_correctness = mysql.execute_queries(query, commit_ID)

        if rn_correctness == constants.RESULT.PASS:  # The correct version.
            # Good commit.
            older_commit_index = tmp_commit_index
            logger.debug(f"For commit {commit_ID}. Bisecting Pass. \n")
            continue
        elif rn_correctness == constants.RESULT.FAIL_TO_COMPILE:
            logger.debug(f"For commit {commit_ID}. Bisecting FAIL_TO_COMPILE. \n")
            utils.dump_failed_commit(commit_ID)
            del all_commits_str[tmp_commit_index]
            older_commit_index -= 1
            continue
        else:
            # SEG_FAULT
            # Buggy commit.
            newer_commit_index = tmp_commit_index
            logger.debug(
                f"For commit {commit_ID}, Bisecting Segmentation Fault. \n"
            )
            continue

    logger.info(
        "Found the bug introduced commit: %s \n\n\n"
        % (all_commits_str[newer_commit_index])
    )
    logger.info(
        f"Found the correct commit: {all_commits_str[older_commit_index]} \n\n\n"
    )

    current_bisecting_result.query = query
    current_bisecting_result.first_buggy_commit_id = all_commits_str[
        newer_commit_index
    ]
    current_bisecting_result.first_corr_commit_id = all_commits_str[
        older_commit_index
    ]
    current_bisecting_result.final_res_flag = rn_correctness

    return current_bisecting_result
