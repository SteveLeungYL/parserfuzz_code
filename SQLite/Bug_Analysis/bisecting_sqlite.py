import os

import re
from git import Repo
import subprocess
import re
import shutil

from git.objects import commit
from bisecting_sqlite_config import *


sqlite_process_id : subprocess.Popen = None

def _get_all_commits(repo:Repo): 

    repo.git.checkout(SQLITE_BRANCH)

    all_commits = repo.iter_commits()
    all_commits_hexsha = []
    for commit in all_commits:
        all_commits_hexsha.append(commit.hexsha)
    all_commits_hexsha.reverse()

    if END_COMMIT_ID != "":
        end_index = all_commits_hexsha.index(END_COMMIT_ID)
        all_commits_hexsha = all_commits_hexsha[:end_index]
    if BEGIN_COMMIT_ID != "":
        begin_index = all_commits_hexsha.index(BEGIN_COMMIT_ID)
        all_commits_hexsha = all_commits_hexsha[begin_index:]

    all_tags = sorted(repo.tags, key=lambda t: t.commit.committed_date)
    all_tags_output = []
    for tag in all_tags:
        if tag.commit.hexsha in all_commits_hexsha:
            all_tags_output.append(tag)
    return all_commits_hexsha, all_tags_output


def _checkout_commit(hexsha:str):
    os.chdir(SQLITE_DIR)
    with open(os.devnull, 'wb') as devnull:
        subprocess.check_call(['git', 'checkout', hexsha], stdout=devnull, stderr=subprocess.STDOUT)
    print("Checkout commit completed. ")

def _compile_sqlite_binary(CACHED_INSTALL_DEST_DIR:str):
    if not os.path.isdir(CACHED_INSTALL_DEST_DIR):
        os.mkdir(CACHED_INSTALL_DEST_DIR)
    os.chdir(CACHED_INSTALL_DEST_DIR)
    with open(os.devnull, 'wb') as devnull:
        subprocess.check_call(["../../configure"], stdout=devnull, stderr=subprocess.STDOUT)
        subprocess.check_call(["make", "-j", str(COMPILE_THREAD_COUNT)], stdout=devnull, stderr=subprocess.STDOUT)
    print("Compilation completed. ")
    


def _setup_SQLITE_with_commit(hexsha:str):
    print("Setting up SQLite3 with commitID: %s" % (hexsha))
    if not os.path.isdir(SQLITE_BLD_DIR):
        os.mkdir(SQLITE_BLD_DIR)
    INSTALL_DEST_DIR = os.path.join(SQLITE_BLD_DIR, hexsha)
    if not os.path.isdir(INSTALL_DEST_DIR):  # Not precompiled.
        _checkout_commit(hexsha=hexsha)
        _compile_sqlite_binary(CACHED_INSTALL_DEST_DIR=INSTALL_DEST_DIR)
    elif not os.path.isfile(os.path.join(INSTALL_DEST_DIR, "sqlite3")):  # Probably not compiled completely.
        print("Warning: For commit: %s, installed dir exists, but sqlite3 is not compiled probably. " % (hexsha))
        shutil.rmtree(INSTALL_DEST_DIR)
        _checkout_commit(hexsha=hexsha)
        _compile_sqlite_binary(CACHED_INSTALL_DEST_DIR=INSTALL_DEST_DIR)

    if os.path.isfile(os.path.join(INSTALL_DEST_DIR, "sqlite3")):  # Compile successfully.
        return INSTALL_DEST_DIR
    else:   # Compile failed.
        return ""

def _check_query_exec_correctness_under_commitID(opt_unopt_queries, commit_ID:str) -> int:
    INSTALL_DEST_DIR = _setup_SQLITE_with_commit(hexsha=commit_ID)
    if INSTALL_DEST_DIR == "":
        return -1  # Failed to compile commit. 
    opt_queries = opt_unopt_queries[0]
    unopt_queries = opt_unopt_queries[1]
    
    opt_result = _execute_queries(queries=opt_queries, sqlite_install_dir = INSTALL_DEST_DIR, is_transformed_no_rec=False)
    unopt_result = _execute_queries(queries=unopt_queries, sqlite_install_dir = INSTALL_DEST_DIR, is_transformed_no_rec=True)
    if opt_result == unopt_result:
        print("The result is correct!")
        return 1   # The result is correct.
    else:
        print("The result is BUGGY!")
        return 0  # THe result is buggy.

def bi_secting_commits(opt_unopt_queries, all_commits_str, all_tags, ignored_commits_str):
    newer_commit_str = ""  # The oldest buggy commit, which is the commit that introduce the bug.
    older_commit_str = ""  # The latest correct commit.
    for current_tag in reversed(all_tags):   # From the latest tag to the earliest tag.
        current_commit_str = current_tag.commit.hexsha
        current_commit_index = all_commits_str.index(current_commit_str)
        is_successfully_executed = False
        is_commit_found = False

        while not is_successfully_executed:
            current_commit_str = all_commits_str[current_commit_index]
            if current_commit_str in ignored_commits_str:
                current_commit_index -= 1
                continue
            rn_correctness =  _check_query_exec_correctness_under_commitID(opt_unopt_queries=opt_unopt_queries, commit_ID=current_commit_str)  # Execution is correct
            if rn_correctness == 1:   # Execution result is correct.
                older_commit_str = current_commit_str
                is_successfully_executed = True
                is_commit_found = True
                break
            elif rn_correctness == 0:    # Execution result is buggy
                newer_commit_str = current_commit_str
                is_successfully_executed = True
                break
            else:  # Compilation failed!!!
                ignored_commits_str.append(current_commit_str)
                if current_commit_index > 0:
                    current_commit_index -= 1
                else:
                    print("Error iterating the commit. Returning None")
                    return None
        if is_commit_found:
            break
            
    
    if newer_commit_str == "":
        print("The latest commit: %s already fix this bug. Opt: %s, unopt: %s. Returning None. \n" % (older_commit_str, opt_unopt_queries[0], opt_unopt_queries[1]))
        return None
    if older_commit_str == "":
        print("Cannot find the bug introduced commit for queries opt: %s, unopt: %s. Returning None. \n" % (opt_unopt_queries[0], opt_unopt_queries[1]))
        return None
    
    newer_commit_index = all_commits_str.index(newer_commit_str)
    older_commit_index = all_commits_str.index(older_commit_str)

    is_buggy_commit_found = False
    current_ignored_commit_number = 0

    while not is_buggy_commit_found:
        if (newer_commit_index - older_commit_index - current_ignored_commit_number) <= COMMIT_SEARCH_RANGE:
            is_buggy_commit_found = True
            break
        tmp_commit_index = int((newer_commit_index + older_commit_index) / 2 )

        is_successfully_executed = False
        while not is_successfully_executed:
            commit_ID = all_commits_str[tmp_commit_index]
            if commit_ID in ignored_commits_str:  # Ignore unsuccessfully built commits.
                tmp_commit_index -= 1
                current_ignored_commit_number += 1
                if tmp_commit_index <= older_commit_index:  
                    return all_commits_str[newer_commit_index]
                continue

            rn_correctness = _check_query_exec_correctness_under_commitID(opt_unopt_queries=opt_unopt_queries, commit_ID=commit_ID)
            if rn_correctness == 1:  # The correct version.
                older_commit_index = tmp_commit_index
                is_successfully_executed = True
                break
            elif rn_correctness == 0:   # The buggy version. 
                newer_commit_index = tmp_commit_index
                is_successfully_executed = True
                break
            else:
                ignored_commits_str.append(commit_ID)
                tmp_commit_index -= 1
                current_ignored_commit_number += 1

    
    if is_buggy_commit_found:
        return all_commits_str[newer_commit_index]
    else:
        return None



def _execute_queries(queries:str, sqlite_install_dir:str, is_transformed_no_rec:bool = False):
    # TODO:: execute_queries.
    os.chdir(sqlite_install_dir)
    current_run_cmd = './sqlite3 file::memory: " ' + queries + ' "'
    result = subprocess.getstatusoutput(current_run_cmd)
    if result[0] != 0:
        return None   # Error code found!
    else:
        if not is_transformed_no_rec:
            result_str = result[1]
            if result_str != "":
                print("Opt result is: %s" % (result_str))
                return result_str.count('\n') + 1  # Results count = newline sym + 1
            else:
                print("Opt empty results.")
                return 0    # Empty results.
        else:
            result_str = result[1]
            if result_str != "":
                print("Unopt result is: %d" % (int(result_str)))
                return int(result_str) # Results count = num of 1.
            else:
                print("Unopt empty results.")
                return 0    # Empty results.



def read_queries_from_files(file_directory:str):
    all_queries = []
    for current_file_d in sorted(os.listdir(file_directory)):
        print("Filename: " + str(current_file_d))
        current_file = open(os.path.join(file_directory, current_file_d), 'r')
        current_file_str = current_file.read()
        current_file_str = re.sub(r'[^\x00-\x7F]+',' ', current_file_str)
        all_queries.append(current_file_str)
        current_file.close()
    return all_queries

def restructured_and_clean_all_queries(all_queries):
    output_all_queries = []

    for queries in all_queries:
        current_queries_in = queries.split('\n')
        current_opt_queries_out = ""
        current_unopt_queries_out = ""
        is_unopt = False
        for query in current_queries_in:
            if 'Unoptimized cmd' in query:
                is_unopt = True
                continue
            if not re.search(r'\w', query):
                continue
            if 'Optimized cmd' in query or query == ';' or query == ' ' or query == '' or query == '\n':
                continue
            # if 'SELECT' in query:
            #     query = "EXPLAIN " + query
            if not is_unopt:
                current_opt_queries_out += query
            else:
                current_unopt_queries_out += query
        
        output_all_queries.append([current_opt_queries_out, current_unopt_queries_out])

    return output_all_queries


def cross_compare(all_results):
    if all_results == [] or all_results == None or len(all_results) < 1:
        print("All results are None.")
        return None
    elif len(all_results) < 2:
        print("Very small amount of results got. (=1)")
        return [all_results[0][0]]
    
    idx_l = 0
    idx_r = 1
    is_finished = False
    removed_idx = []
    while not is_finished:
        if idx_l >= len(all_results) - 2:
            is_finished = True      # Fall through!!!
        if idx_r >= len(all_results):
            idx_l += 1
            idx_r = idx_l + 1
            continue
        if idx_l in removed_idx:
            idx_l += 1
            idx_r = idx_l + 1
            continue
        if idx_r in removed_idx:
            idx_r += 1
            continue
        if all_results[idx_l][1] == all_results[idx_r][1]:
            removed_idx.append(idx_r)
        idx_r += 1
    
    all_unique_results_idx = []
    for idx, results in enumerate(all_results):
        if idx not in removed_idx:
            all_unique_results_idx.append(results[0])
    
    return all_unique_results_idx


### Bi-sec inplementation

repo = Repo(SQLITE_DIR)
assert not repo.bare
all_commits_hexsha, all_tags = _get_all_commits(repo=repo)
ignored_commits_hexsha = []

print("Getting %d number of commits, and %d number of tags. \n" % (len(all_commits_hexsha), len(all_tags)))

all_queries = read_queries_from_files(file_directory=QUERY_SAMPLE_DIR)
all_queries = restructured_and_clean_all_queries(all_queries=all_queries)  # all_queries = [[opt_queries, unopt_queries]]

all_results = []
for idx, opt_unopt_queries in enumerate(all_queries):  # idx is the index for the all_queries struct, not for the all_commits_hexsha and all_tags. 
    first_buggy_commit_ID = bi_secting_commits(opt_unopt_queries = opt_unopt_queries, all_commits_str = all_commits_hexsha, all_tags = all_tags, ignored_commits_str = ignored_commits_hexsha)
    if first_buggy_commit_ID != None:
        current_result_l = [idx, first_buggy_commit_ID]
        all_results.append(current_result_l)
    else:
        print("For query Opt: %s, Unopt: %s. Error occurs in bug_analysis." % (opt_unopt_queries[0], opt_unopt_queries[1]))


all_unique_bug_idx = cross_compare(all_results=all_results)
if all_unique_bug_idx is not None:
    for current_unique_bug_idx in all_unique_bug_idx:
        print("\n\n\nUnique bug queries: " + str(all_queries[current_unique_bug_idx]) + "\n\n\n")