import mysql
import constants
import utils
from loguru import logger
import stats_bugs
import mysql_builder

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
    newer_buggy_commit = all_commits_str[0]
    # The correct commit, which is the commit right before the bug introducing one.
    older_correct_commit = all_commits_str[len(all_commits_str)-1]
    # The bisecting result, the first buggy commit:
    first_buggy_commit = ""
    last_corr_commit = "" 

    # Initialize the new bisecting results struct.  
    rn_correctness = constants.RESULT.PASS
    current_bisecting_result = constants.BisectingResults()
    current_bisecting_result.src = file_name

    # Initialize the git repo. 
    mysql_builder.init_bisecting_repo(newer_buggy_commit, older_correct_commit)

    is_buggy_commit_found = False

    logger.debug(f"Inside bisecting_commits function. \n")

    while not is_buggy_commit_found:

        first_buggy_commit, last_corr_commit = mysql_builder.check_whether_buggy_commit_found()
        if first_buggy_commit != "":
            # Found the bug introduced commit. 
            logger.debug(
                f"found buggy_commit: {first_buggy_commit}"
            )
            is_buggy_commit_found = True
            break

        cur_bisecting_commit = mysql_builder.get_current_bisecting_commit()

        rn_correctness = mysql.execute_queries(query, cur_bisecting_commit)

        if rn_correctness == constants.RESULT.PASS:  # The correct version.
            # Good commit.
            logger.debug(f"For commit {cur_bisecting_commit}. Bisecting Pass. \n")
            mysql_builder.bisect_good()
            continue
        elif rn_correctness == constants.RESULT.FAIL_TO_COMPILE:
            logger.debug(f"For commit {cur_bisecting_commit}. Bisecting FAIL_TO_COMPILE. \n")
            utils.dump_failed_commit(cur_bisecting_commit)
            mysql_builder.bisect_skip()
            continue
        else:
            # SEG_FAULT
            # Buggy commit.
            logger.debug(
                f"For commit {cur_bisecting_commit}, Bisecting Segmentation Fault. \n"
            )
            mysql_builder.bisect_bad()
            continue

    logger.info(
        "Found the bug introduced commit: %s \n\n\n"
        % (first_buggy_commit)
    )
    # logger.info(
    #     f"Found the correct commit: {all_commits_str[older_commit_index]} \n\n\n"
    # )

    current_bisecting_result.query = query
    current_bisecting_result.first_buggy_commit_id = first_buggy_commit
    current_bisecting_result.first_corr_commit_id = last_corr_commit 
    current_bisecting_result.final_res_flag = rn_correctness

    return current_bisecting_result
