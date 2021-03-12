import os

import re
from sqlite.bisecting_sqlite_root.bisecting_sqlite_config import SQLITE_BLD_DIR
from git import Repo
import subprocess
import signal
import shutil
import re
from bisecting_sqlite_config import *


sqlite_process_id : subprocess.Popen = None

def _get_all_commits(repo:Repo): 
    # TODO:: Implement starting and ending searched commits.
    all_commits = repo.iter_commits()
    all_commits_hexsha = []
    for commit in all_commits:
        all_commits_hexsha.append(commit.hexsha)
    all_commits_hexsha.reverse()
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
        subprocess.check_call(['git', 'clean', '-xdf'], stdout=devnull, stderr=subprocess.STDOUT)   # TODO:: Should we clean up the dir?
    print("Checkout commit completed. ")

def _compile_sqlite_binary(CACHED_INSTALL_DEST_DIR:str):
    if not os.path.isdir(CACHED_INSTALL_DEST_DIR):
        os.mkdir(CACHED_INSTALL_DEST_DIR)
    os.chdir(CACHED_INSTALL_DEST_DIR)
    with open(os.devnull, 'wb') as devnull:
        subprocess.check_call(["../../configure"], stdout=devnull, stderr=subprocess.STDOUT)
        subprocess.check_call(["make", "-j" + str(COMPILE_THREAD_COUNT)], stdout=devnull, stderr=subprocess.STDOUT)
    print("Compilation completed. ")
    


def _setup_SQLITE_with_commit(hexsha:str):
    print("Setting up SQLite3 with commitID: %s" % (hexsha))
    # if sqlite_process_id is not None:
    #     os.killpg(os.getpgid(sqlite_process_id.pid), signal.SIGTERM)
    if not os.path.isdir(SQLITE_BLD_DIR):
        os.mkdir(SQLITE_BLD_DIR)
    INSTALL_DEST_DIR = os.path.join(SQLITE_BLD_DIR, hexsha)
    if not os.path.isdir(INSTALL_DEST_DIR):  # Not precompiled.
        _checkout_commit(hexsha=hexsha)
        _compile_sqlite_binary(CACHED_INSTALL_DEST_DIR=INSTALL_DEST_DIR)
    return INSTALL_DEST_DIR

def _check_query_exec_correctness_under_commitID(opt_unopt_queries, commit_ID:str) -> bool:
    INSTALL_DEST_DIR = _setup_SQLITE_with_commit(hexsha=commit_ID)
    opt_queries = opt_unopt_queries[0]
    unopt_queries = opt_unopt_queries[1]
    
    opt_result = _execute_queries(queries=opt_queries)
    unopt_result = _execute_queries(queries=unopt_queries)
    if compare_mysql_results(opt_queries, unopt_result):
        return True
    else:
        return False

def bi_secting_commits(opt_unopt_queries, all_commits_str, all_tags):
    newer_commit_str = ""
    older_commit_str = ""
    for current_tag in reversed(all_tags):   # From the latest tag to the earliest tag.
        current_commit_str = current_tag.commit.hexsha
        if _check_query_exec_correctness_under_commitID(opt_unopt_queries=opt_unopt_queries, commit_ID=current_commit_str):
            older_commit_str = current_commit_str
            break
        else:
            newer_commit_str = current_commit_str
    
    if newer_commit_str == "":
        newer_commit_str = all_commits_str[-1]
    if older_commit_str == "":
        print("Cannot find the bug introduced commit for queries opt: %s, unopt: %s. Returning None. " % (opt_unopt_queries[0], opt_unopt_queries[1]))
        return None
    
    newer_commit_index = all_commits_str.index(newer_commit_str)
    older_commit_index = all_commits_str.index(older_commit_str)

    is_buggy_commit_found = False

    while not is_buggy_commit_found:
        if (newer_commit_index - older_commit_index) <= 1:
            is_buggy_commit_found = True
            break
        tmp_commit_index = int((newer_commit_index + older_commit_index) / 2 )

        if _check_query_exec_correctness_under_commitID(opt_unopt_queries=opt_unopt_queries, commit_ID=all_commits_str[tmp_commit_index]):   # The buggy version.
            older_commit_index = tmp_commit_index
        else:   # The correct version without the buggy code being added.
            newer_commit_index = tmp_commit_index
    
    if is_buggy_commit_found:
        return all_commits_str[newer_commit_index]
    else:
        return None



def _execute_queries(queries, cnx = None, params = None, is_destructive = True):
    # TODO:: execute_queries.
    return results


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
        current_opt_queries_out = []
        current_unopt_queries_out = []
        is_unopt = False
        for query in current_queries_in:
            if 'Unoptimized cmd' in query:
                is_unopt = True
                continue
            if not re.search(r'\w', query):
                continue
            if 'Optimized cmd' in query or 'use test' in query or query == ';' or query == ' ' or query == '':
                continue
            # if 'SELECT' in query:
            #     query = "EXPLAIN " + query
            if not is_unopt:
                current_opt_queries_out.append(query)
            else:
                current_unopt_queries_out.append(query)
        
        output_all_queries.append([current_opt_queries_out, current_unopt_queries_out])

    return output_all_queries

def compare_sqlite_results(l_result, r_result) -> bool:
        # TODO:: Implement compare results.
        return False


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

print("Getting %d number of commits, and %d number of tags. \n" % (len(all_commits_hexsha), len(all_tags)))

# _setup_MYSQL_with_commit(hexsha="7ed30a748964c009d4909cb8b4b22036ebdef239")

all_queries = read_queries_from_files(file_directory=QUERY_SAMPLE_DIR)
all_queries = restructured_and_clean_all_queries(all_queries=all_queries)  # all_queries = [[opt_queries, unopt_queries]]

all_results = []
for idx, opt_unopt_queries in enumerate(all_queries):
    first_buggy_commit_ID = bi_secting_commits(opt_unopt_queries = opt_unopt_queries, all_commits_str = all_commits_hexsha, all_tags = all_tags)
    if first_buggy_commit_ID != None:
        current_result_l = [idx, first_buggy_commit_ID]
        all_results.append(current_result_l)


all_unique_bug_idx = cross_compare(all_results=all_results)
if all_unique_bug_idx is not None:
    for current_unique_bug_idx in all_unique_bug_idx:
        print("\n\n\nUnique bug queries: " + str(all_queries[current_unique_bug_idx]) + "\n\n\n")