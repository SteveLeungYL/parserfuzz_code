from configparser import Error
from io import StringIO
import os

import re
from typing import Dict
from git import Repo
import subprocess
import re
import shutil
import time
from threading import Thread
import atexit
from enum import Enum
from sys import maxsize

from git.objects import commit
from bisecting_sqlite_config import *

### Global Variable

all_commits_hexsha = []
all_tags = []
ignored_commits_hexsha = []
all_files_fds = dict()
all_unique_results_dict = dict()
uniq_bug_id_int = 0
total_processed_bug_count_int:int = 0
total_processing_bug_count_int:int = 0
total_bug_count_int:int = 0
log_output = open(LOG_OUTPUT_FILE, 'w')

class VALID_TYPE(Enum):
    NORM = 1
    MIN = 2
    MAX = 3
    SUM = 4
    COUNT = 5

class RESULT(Enum):
    PASS = 1
    FAIL = 0
    ERROR = -1
    ALL_ERROR = -1
    FAIL_TO_COMPILE = -2

# Fuzzing instances related. 
all_fuzzing_instances_list = []

class BisectingResults:
    query: str = ""
    first_buggy_commit_id: str = ""
    is_error_returned_from_exec: bool = ""
    opt_result = []
    unopt_result = []
    all_result_flags = []
    unique_bug_id = "Unknown"
    is_bisecting_error:bool = False
    bisecting_error_reason: str = ""


def _get_all_commits(repo:Repo): 

    _checkout_commit('master')

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
        subprocess.check_call(['git', 'checkout', hexsha, "--force"], stdout=devnull, stderr=subprocess.STDOUT)
    log_output.write("Checkout commit completed. \n")

def _compile_sqlite_binary(CACHED_INSTALL_DEST_DIR:str):
    if not os.path.isdir(CACHED_INSTALL_DEST_DIR):
        os.mkdir(CACHED_INSTALL_DEST_DIR)
    os.chdir(CACHED_INSTALL_DEST_DIR)
    with open(os.devnull, 'wb') as devnull:
        result = subprocess.getstatusoutput("chmod +x ../../configure")
        if result[0] != 0:
            log_output.write("Compilation failed. Reason: %s. \n" % (result[1]))

        result = subprocess.getstatusoutput("../../configure")
        if result[0] != 0:
            log_output.write("Compilation failed. Reason: %s. \n" % (result[1]))
            return -1
        
        result = subprocess.getstatusoutput("make -j" + str(COMPILE_THREAD_COUNT))
        if result[0] != 0:
            log_output.write("Compilation failed. Reason: %s. \n" % (result[1]))
            return -1
    log_output.write("Compilation completed. ")
    return 0
    


def _setup_SQLITE_with_commit(hexsha:str):
    log_output.write("Setting up SQLite3 with commitID: %s. \n" % (hexsha))
    if not os.path.isdir(SQLITE_BLD_DIR):
        os.mkdir(SQLITE_BLD_DIR)
    INSTALL_DEST_DIR = os.path.join(SQLITE_BLD_DIR, hexsha)
    if not os.path.isdir(INSTALL_DEST_DIR):  # Not precompiled.
        _checkout_commit(hexsha=hexsha)
        result = _compile_sqlite_binary(CACHED_INSTALL_DEST_DIR=INSTALL_DEST_DIR)
        if result != 0:
            return ""  # Compile failed.
    elif not os.path.isfile(os.path.join(INSTALL_DEST_DIR, "sqlite3")):  # Probably not compiled completely.
        log_output.write("Warning: For commit: %s, installed dir exists, but sqlite3 is not compiled probably. " % (hexsha))
        shutil.rmtree(INSTALL_DEST_DIR)
        _checkout_commit(hexsha=hexsha)
        result = _compile_sqlite_binary(CACHED_INSTALL_DEST_DIR=INSTALL_DEST_DIR)
        if result != 0:
            return ""  # Compile failed.

    if os.path.isfile(os.path.join(INSTALL_DEST_DIR, "sqlite3")):  # Compile successfully.
        return INSTALL_DEST_DIR
    else:   # Compile failed.
        return ""

def is_string_only_whitespace (input_str: str):
    if re.match(r"""^[\s]*$""", input_str, re.MULTILINE):
        return True  # Only whitespace
    return False # Not only whitespace

def check_result_norm(opt:str, unopt:str) -> RESULT:
    if opt == "Error" or unopt == "Error":
        return RESULT.ERROR
    
    opt_out_int = 0
    unopt_out_int = 0

    opt_list = opt.split('\n')
    unopt_list = unopt.split('\n')

    for cur_opt in opt_list:
        if re.match(r"""^[\|\s]*$""", cur_opt, re.MULTILINE):  # Only spaces or | (separator)
            continue
        opt_out_int += 1
    for cur_unopt in unopt_list:
        if re.match(r"""^[\|\s]*$""", cur_unopt, re.MULTILINE):  # Only spaces or | (separator)
            continue
        unopt_out_int += 1

    if opt_out_int != unopt_out_int:
        return RESULT.FAIL
    else:
        return RESULT.PASS


def check_result_minmax_count_sum(opt, unopt, valid_type)-> RESULT:
    if opt == "Error" or unopt == "Error":
        return RESULT.ERROR

    opt_out_int:int = 0
    unopt_out_int:int = 0
    if valid_type == VALID_TYPE.MAX:
        opt_out_int = 0
        unopt_out_int = 0
    elif valid_type == VALID_TYPE.MIN:
        opt_out_int = maxsize
        unopt_out_int = maxsize
    elif valid_type == VALID_TYPE.COUNT or valid_type == VALID_TYPE.SUM:
        opt_out_int = 0
        unopt_out_int = 0
    else:
        raise ValueError("Cannot handle valid_type: " + str(valid_type) + " in the check_result function. ")
    
    for cur_opt in opt.split('\n'):
        if is_string_only_whitespace(cur_opt):
            continue
        cur_res = 0
        try:
            cur_res = int(cur_opt)
        except ValueError:
            return RESULT.ERROR
        
        if valid_type == VALID_TYPE.COUNT or valid_type == VALID_TYPE.SUM:
            opt_out_int += cur_res
        elif valid_type == VALID_TYPE.MAX and cur_res > opt_out_int:
            opt_out_int = cur_res
        elif valid_type == VALID_TYPE.MIN and cur_res < opt_out_int:
            opt_out_int = cur_res


    for cur_unopt in unopt.split('\n'):
        if is_string_only_whitespace(cur_unopt):
            continue
        cur_res = 0
        try:
            cur_res = int(cur_unopt)
        except ValueError:
            return RESULT.ERROR
        
        if valid_type == VALID_TYPE.COUNT or valid_type == VALID_TYPE.SUM:
            unopt_out_int += cur_res
        elif valid_type == VALID_TYPE.MAX and cur_res > unopt_out_int:
            unopt_out_int = cur_res
        elif valid_type == VALID_TYPE.MIN and cur_res < unopt_out_int:
            unopt_out_int = cur_res

    if opt_out_int != unopt_out_int:
        return RESULT.FAIL
    else:
        return RESULT.PASS
    

def _check_query_exec_correctness_under_commitID(opt_unopt_queries, commit_ID:str):
    INSTALL_DEST_DIR = _setup_SQLITE_with_commit(hexsha=commit_ID)

    if INSTALL_DEST_DIR == "":
        return RESULT.FAIL_TO_COMPILE, None, None, None  # Failed to compile commit. 
    
    opt_result, unopt_result = _execute_queries(queries=opt_unopt_queries, sqlite_install_dir = INSTALL_DEST_DIR)

    if opt_result == None or unopt_result == None:
        return RESULT.ALL_ERROR, None, None, None

    valid_type_list = get_valid_type_list(opt_unopt_queries)

    all_res_out = []
    final_res = RESULT.PASS

    for idx, valid_type in enumerate(valid_type_list):
        # print(opt_result)
        # if idx >= len(opt_result) or idx >= len(unopt_result):
        #     break
        if valid_type == VALID_TYPE.NORM:
            curr_res = check_result_norm(opt_result[idx], unopt_result[idx])
            all_res_out.append(curr_res)
        elif valid_type == VALID_TYPE.COUNT or valid_type == VALID_TYPE.SUM or valid_type == VALID_TYPE.MIN or valid_type == VALID_TYPE.MAX:
            curr_res = check_result_minmax_count_sum(opt_result[idx], unopt_result[idx], valid_type)
            all_res_out.append(curr_res)
        else:
            raise ValueError("Encounter unknown VALID_TYPE in the check_query_exec_correctness_under_commitID func. ")
    
    for curr_res_out in all_res_out:
        if curr_res_out == RESULT.FAIL:
            final_res = RESULT.FAIL
            break
    
    is_all_query_return_errors = True
    for curr_res_out in all_res_out:
        if curr_res_out != RESULT.ERROR:
            is_all_query_return_errors = False
            break
    if is_all_query_return_errors: 
        final_res = RESULT.ALL_ERROR

    return final_res, opt_result, unopt_result, all_res_out


def bi_secting_commits(opt_unopt_queries, all_commits_str, all_tags, ignored_commits_str):   # Returns Bug introduce commit_ID:str, is_error_result:bool
    newer_commit_str = ""  # The oldest buggy commit, which is the commit that introduce the bug.
    older_commit_str = ""  # The latest correct commit.
    last_buggy_opt_result = None
    last_buggy_unopt_result = None
    last_buggy_all_result_flags = None
    is_error_returned_from_exec = False
    current_commit_str = ""
    
    current_bisecting_result = BisectingResults()

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
            rn_correctness, opt_result, unopt_result, all_results_flag =  _check_query_exec_correctness_under_commitID(opt_unopt_queries=opt_unopt_queries, commit_ID=current_commit_str)
            if rn_correctness == RESULT.PASS:   # Execution result is correct.
                older_commit_str = current_commit_str
                is_successfully_executed = True
                is_commit_found = True
                break
            elif rn_correctness == RESULT.FAIL:    # Execution result is buggy
                newer_commit_str = current_commit_str
                is_successfully_executed = True
                last_buggy_opt_result = opt_result
                last_buggy_unopt_result = unopt_result
                last_buggy_all_result_flags = all_results_flag
                break
            elif rn_correctness == RESULT.ALL_ERROR:   # Execution queries all return errors. Treat it similar to execution result is correct.
                older_commit_str = current_commit_str
                is_successfully_executed = True
                is_commit_found = True
                is_error_returned_from_exec = True
                break
            else:  # Compilation failed!!!  rn_correctness == -2
                ignored_commits_str.append(current_commit_str)
                if current_commit_index > 0:
                    current_commit_index -= 1
                else:
                    log_output.write("Error: error iterating the commit. Compilation failed. Bug trigerred when running bug_deduplication. Raising error.\n\n\n")
                    raise RuntimeError("Error compiling the released SQLite library with default tags! Error commit: " + str(current_commit_str) + "\n\n\n")
        if is_commit_found:
            break
            
    
    if newer_commit_str == "":
        # Error_reason = "Error: The latest commit: %s already fix this bug, or the latest commit is returnning errors!!! \nOpt: \"%s\", \nunopt: \"%s\". \nReturning None. \n" % (older_commit_str, opt_unopt_queries[0], opt_unopt_queries[1])
        Error_reason = "Error: The latest commit: %s already fix this bug, or the latest commit is returnning errors!!!\n\n\n" % (current_commit_str)
        log_output.write(Error_reason)

        current_bisecting_result.query = opt_unopt_queries
        current_bisecting_result.first_buggy_commit_id = current_commit_str
        current_bisecting_result.is_error_returned_from_exec = is_error_returned_from_exec
        current_bisecting_result.is_bisecting_error = True
        current_bisecting_result.bisecting_error_reason = Error_reason
        current_bisecting_result.opt_result = last_buggy_opt_result
        current_bisecting_result.unopt_result = last_buggy_unopt_result
        current_bisecting_result.all_result_flags = last_buggy_all_result_flags

        return current_bisecting_result

    if older_commit_str == "":
        # Error_reason = "Error: Cannot find the bug introduced commit (already iterating to the earliest version for queries \nopt: %s, \nunopt: %s. \nReturning None. \n" % (opt_unopt_queries[0], opt_unopt_queries[1])
        Error_reason = "Error: Cannot find the bug introduced commit (already iterating to the earliest version)!!!\n\n\n"
        log_output.write(Error_reason)

        current_bisecting_result.query = opt_unopt_queries
        current_bisecting_result.is_error_returned_from_exec = is_error_returned_from_exec
        current_bisecting_result.is_bisecting_error = True
        current_bisecting_result.bisecting_error_reason = Error_reason
        current_bisecting_result.opt_result = last_buggy_opt_result
        current_bisecting_result.unopt_result = last_buggy_unopt_result
        current_bisecting_result.all_result_flags = last_buggy_all_result_flags

        return current_bisecting_result
    
    newer_commit_index = all_commits_str.index(newer_commit_str)
    older_commit_index = all_commits_str.index(older_commit_str)

    is_buggy_commit_found = False
    current_ignored_commit_number = 0

    while not is_buggy_commit_found:
        if (newer_commit_index - older_commit_index) <= COMMIT_SEARCH_RANGE:
            is_buggy_commit_found = True
            break
        tmp_commit_index = int((newer_commit_index + older_commit_index) / 2 )  # Approximate towards 0 (older).

        is_successfully_executed = False
        while not is_successfully_executed:
            commit_ID = all_commits_str[tmp_commit_index]
            if commit_ID in ignored_commits_str:  # Ignore unsuccessfully built commits.
                tmp_commit_index -= 1
                current_ignored_commit_number += 1
                if tmp_commit_index <= older_commit_index:
                    older_commit_index = int((newer_commit_index + older_commit_index) / 2 )
                    is_successfully_executed = True  # It is a hack here. The execution failed, but we can treat all the failed execution as executed CORRECT, and continue the outer loop. 
                    break
                continue

            rn_correctness, opt_result, unopt_result, all_results_flag = _check_query_exec_correctness_under_commitID(opt_unopt_queries=opt_unopt_queries, commit_ID=commit_ID)
            if rn_correctness == RESULT.PASS:  # The correct version.
                older_commit_index = tmp_commit_index
                is_successfully_executed = True
                break
            elif rn_correctness == RESULT.FAIL:   # The buggy version. 
                newer_commit_index = tmp_commit_index
                is_successfully_executed = True
                last_buggy_opt_result = opt_result
                last_buggy_unopt_result = unopt_result
                last_buggy_all_result_flags = all_results_flag
                break
            elif rn_correctness == RESULT.ERROR:
                older_commit_index = tmp_commit_index
                is_successfully_executed = True
                is_error_returned_from_exec = True
                break
            else:
                ignored_commits_str.append(commit_ID)
                tmp_commit_index -= 1
                current_ignored_commit_number += 1

    
    if is_buggy_commit_found:
        log_output.write("Found the bug introduced commit: %s \n\n\n" % (all_commits_str[newer_commit_index]))

        current_bisecting_result.query = opt_unopt_queries
        current_bisecting_result.first_buggy_commit_id = all_commits_str[newer_commit_index]
        current_bisecting_result.is_error_returned_from_exec = is_error_returned_from_exec
        current_bisecting_result.is_bisecting_error = False
        current_bisecting_result.opt_result = last_buggy_opt_result
        current_bisecting_result.unopt_result = last_buggy_unopt_result
        current_bisecting_result.all_result_flags = last_buggy_all_result_flags

        return current_bisecting_result
    else:
        Error_reason = "Error: Returnning is_buggy_commit_found == False. Possibly related to compilation failure. \n\n\n"
        log_output.write(Error_reason)

        current_bisecting_result.query = opt_unopt_queries
        current_bisecting_result.is_error_returned_from_exec = is_error_returned_from_exec
        current_bisecting_result.is_bisecting_error = True
        current_bisecting_result.bisecting_error_reason = Error_reason
        current_bisecting_result.opt_result = last_buggy_opt_result
        current_bisecting_result.unopt_result = last_buggy_unopt_result
        current_bisecting_result.all_result_flags = last_buggy_all_result_flags

        return current_bisecting_result

def get_valid_type(query:str):
    if re.match(r"""^[\s;]*SELECT\s*(DISTINCT\s*)?MIN(.*?)$""", query, re.MULTILINE):
        # print("For query: %s, returning valid_type: MIN" % (query))
        return VALID_TYPE.MIN
    elif re.match(r"""^[\s;]*SELECT\s*(DISTINCT\s*)?MAX(.*?)$""", query, re.MULTILINE):
        # print("For query: %s, returning valid_type: MAX" % (query))
        return VALID_TYPE.MAX
    elif re.match(r"""^[\s;]*SELECT\s*(DISTINCT\s*)?SUM(.*?)$""", query, re.MULTILINE):
        # print("For query: %s, returning valid_type: SUM" % (query))
        return VALID_TYPE.SUM
    elif re.match(r"""^[\s;]*SELECT\s*(DISTINCT\s*)?COUNT(.*?)$""", query, re.MULTILINE):
        # print("For query: %s, returning valid_type: COUNT" % (query))
        return VALID_TYPE.COUNT
    else:
        # print("For query: %s, returning valid_type: NORM" % (query), re.MULTILINE)
        return VALID_TYPE.NORM

def get_valid_type_list(query:str):
    if query.count("13579") < 1 or query.count("97531") < 1 or query.count("24680") < 1 or query.count("86420") < 1 or is_string_only_whitespace(query) or query == "":
        return []  # query is not making sense at all.
    

    # Grab all the opt queries, detect its valid_type, and return.
    valid_type_list = []
    begin_idx = []
    end_idx = []
    for m in re.finditer('13579;', query):
        begin_idx.append(m.end())
    for m in re.finditer('97531', query):  # Might contains additional unnecessary characters, such as SELECT in the SELECT 97531;
        end_idx.append(m.start())
    for i in range(min( len(begin_idx), len(end_idx) )):
        current_opt_query = query[begin_idx[i]: end_idx[i]]
        valid_type_list.append(get_valid_type(current_opt_query))

    return valid_type_list
        


def _execute_queries(queries:str, sqlite_install_dir:str):
    # TODO:: execute_queries.
    os.chdir(sqlite_install_dir)
    if os.path.isfile(os.path.join(sqlite_install_dir, "file::memory:")):
        os.remove(os.path.join(sqlite_install_dir, "file::memory:"))
    current_run_cmd_list = ["./sqlite3"]
    child = subprocess.Popen(current_run_cmd_list, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, stdin = subprocess.PIPE, errors="replace")
    try:
        result_str = child.communicate(queries, timeout=3)[0]
    except subprocess.TimeoutExpired:
        child.kill()
        log_output.write("ERROR: SQLite3 time out. \n")
        print("ERROR: SQLite3 time out. ")
        return None, None
    # print("Query is: \n%s\n\n\n\n\n\n" % (queries))
    # print("Result_str is: \n%s\n\n\n\n\n\n\n\n" % (result_str))
    # print("sqlite_install_dir: %s" % (sqlite_install_dir))
    # print("return code: %d" % (child.returncode))

    if (child.returncode != 0 and child.returncode != 1):  # 1 is the default return code if we terminate the SQLite3. 
        return None, None
    

    if result_str.count("13579") < 1 or result_str.count("97531") < 1 or result_str.count("24680") < 1 or result_str.count("86420") < 1 or is_string_only_whitespace(result_str) or result_str == "":
        return None, None  # Missing the outputs from the opt or the unopt. Returnning None implying errors. 

    # Grab all the opt results.
    opt_results_str = []
    begin_idx = []
    end_idx = []
    for m in re.finditer('13579', result_str):
        begin_idx.append(m.end())
    for m in re.finditer('97531', result_str):
        end_idx.append(m.start())
    for i in range(min( len(begin_idx), len(end_idx) )):
        current_opt_result = result_str[begin_idx[i]: end_idx[i]]
        if ("Error" in current_opt_result):
            opt_results_str.append("Error")
        else:
            opt_results_str.append(current_opt_result)

    # Grab all the unopt results.
    unopt_results_str = []
    begin_idx = []
    end_idx = []
    for m in re.finditer('24680', result_str):
        begin_idx.append(m.end())
    for m in re.finditer('86420', result_str):
        end_idx.append(m.start())
    for i in range(min( len(begin_idx), len(end_idx) )):
        current_unopt_result = result_str[ begin_idx[i] : end_idx[i] ]
        if ("Error" in current_unopt_result):
            unopt_results_str.append("Error")
        else:
            unopt_results_str.append(current_unopt_result)

    return opt_results_str, unopt_results_str



def read_queries_from_files(file_directory:str):
    global total_processing_bug_count_int
    global total_processed_bug_count_int
    global total_bug_count_int

    all_queries = []
    all_files_in_dir = os.listdir(file_directory)
    total_bug_count_int = len(all_files_in_dir)
    total_processed_bug_count_int = len(all_files_fds)
    total_processing_bug_count_int = total_processed_bug_count_int
    for current_file_d in sorted(all_files_in_dir):
        if current_file_d in all_files_fds:
            continue
        # time.sleep(0.1) # Sleep 0.1 seconds, let the afl-fuzz file writing complete. Might not be necessary
        log_output.write("Filename: " + str(current_file_d) + ". \n")
        current_file = open(os.path.join(file_directory, current_file_d), 'r', errors="replace")
        current_file_str = current_file.read()
        current_file_str = re.sub(r'[^\x00-\x7F]+',' ', current_file_str)
        current_file_str = current_file_str.replace(u'\ufffd', ' ')
        all_queries.append(current_file_str)
        current_file.close()
        all_files_fds[current_file_d] = 1  # This is changing the global all_current_files variable. The changes will pass on in the program execution. 

    return all_queries


def restructured_and_clean_all_queries(all_queries):
    output_all_queries = []

    for queries in all_queries:
        current_queries_in = queries.split('\n')
        current_queries_out = ""
        for query in current_queries_in:
            if 'Result string' in query:
                break
            if not re.search(r'\w', query):
                continue
            if 'Query:' in query or query == ';' or query == ' ' or query == '' or query == '\n':
                continue
            current_queries_out += query + " \n"

        output_all_queries.append(current_queries_out)

    return output_all_queries


def cross_compare(current_bisecting_result):
    global uniq_bug_id_int
    global all_unique_results_dict
    current_commit_ID = current_bisecting_result.first_buggy_commit_id
    if current_commit_ID not in all_unique_results_dict:
        all_unique_results_dict[current_commit_ID] = uniq_bug_id_int # all_unique_results_dict is a global variable, the changes is saved in program executions.
        current_bisecting_result.uniq_bug_id_int = uniq_bug_id_int
        uniq_bug_id_int += 1 
    else:
        current_bug_id_int = all_unique_results_dict[current_commit_ID]
        current_bisecting_result.uniq_bug_id_int = current_bug_id_int
    
    return current_bisecting_result

def retrive_all_opt_and_unopt_queries(query_str):

    # Grab all the opt queries.
    opt_queries = []
    begin_idx = []
    end_idx = []
    for m in re.finditer('SELECT 13579;', query_str):
        begin_idx.append(m.end())
    for m in re.finditer('SELECT 97531;', query_str):
        end_idx.append(m.start())
    for i in range(min( len(begin_idx), len(end_idx) )):
        current_opt_stmt = query_str[begin_idx[i]: end_idx[i]]
        current_opt_stmt = current_opt_stmt.replace('\n', '')
        opt_queries.append(current_opt_stmt)

    # Grab all the unopt queries.
    unopt_queries = []
    begin_idx = []
    end_idx = []
    for m in re.finditer('SELECT 24680;', query_str):
        begin_idx.append(m.end())
    for m in re.finditer('SELECT 86420;', query_str):
        end_idx.append(m.start())
    for i in range(min( len(begin_idx), len(end_idx) )):
        current_unopt_stmt = query_str[begin_idx[i]: end_idx[i]]
        current_unopt_stmt = current_unopt_stmt.replace('\n', '')
        unopt_queries.append(current_unopt_stmt)
    
    return opt_queries, unopt_queries

def retrive_all_normal_queries(query_str):
    start_of_norec = query_str.find("SELECT 13579")
    normal_query = query_str[:start_of_norec]

    begin_idx = []
    end_idx = []

    for m in re.finditer('SELECT 86420;', query_str):
        begin_idx.append(m.end())
    for m in re.finditer('SELECT 13579;', query_str):
        end_idx.append(m.start())

    end_idx = end_idx[1:]  # Ignore the first one. The end_idx has 1 offset shift compare to begin_idx. 

    for i in range(min( len(begin_idx), len(end_idx) )):
        current_str = query_str[begin_idx[i]: end_idx[i]]
        current_str = current_str.replace('\n', '')
        normal_query += current_str + '\n'

    return normal_query



def pretty_print(query, same_idx):

    start_of_norec = query.find("SELECT 13579")

    # header = query[:start_of_norec]
    tail = query[start_of_norec:]

    # lines = tail.splitlines()
    # opt_selects = lines[1::6]
    # unopt_selects = lines[4::6]
    opt_selects, unopt_selects = retrive_all_opt_and_unopt_queries(tail)

    # It is possible to have multiple normal stmts between norec select stmts. Include them to put them into the header of the output. 
    header = retrive_all_normal_queries(query)

    new_tail = ""
    effect_idx = 0
    for idx in range(0, len(opt_selects)):
        if idx in same_idx:
            continue
        effect_idx += 1
        new_tail += ("SELECT \"--------- " + str(effect_idx) + "\";" + opt_selects[idx] + unopt_selects[idx] + "\n")

    return header + new_tail

def pretty_process(bisecting_result:BisectingResults):

    if bisecting_result.opt_result == [] or bisecting_result.opt_result == None or bisecting_result.unopt_result == [] or bisecting_result.unopt_result == None:
        return

    same_idx = []
    for idx in range(0, len(bisecting_result.opt_result)):
        # Ignore the result with the same output, and ignore the result that are negative. (-1 Error Execution for most cases)
        if bisecting_result.all_result_flags[idx] != RESULT.FAIL or bisecting_result.opt_result[idx] == "Error" or bisecting_result.unopt_result[idx] == "Error":
            same_idx.append(idx)

    bisecting_result.query = pretty_print(bisecting_result.query, same_idx)

    same_idx.reverse()
    for idx in same_idx:
        bisecting_result.opt_result.pop(idx)
        bisecting_result.unopt_result.pop(idx)

def write_uniq_bugs_to_files(current_bisecting_result: BisectingResults): 
    if not os.path.isdir(UNIQUE_BUG_OUTPUT_DIR):
        os.mkdir(UNIQUE_BUG_OUTPUT_DIR)
    current_unique_bug_output = os.path.join(UNIQUE_BUG_OUTPUT_DIR, "bug_" + str(current_bisecting_result.uniq_bug_id_int))
    if os.path.exists(current_unique_bug_output):
        append_or_write = 'a'
    else:
        append_or_write = 'w'
    bug_output_file = open(current_unique_bug_output, append_or_write)

    pretty_process(current_bisecting_result)

    if current_bisecting_result.uniq_bug_id_int != "Unknown":
        bug_output_file.write("Bug ID: %d. \n\n" % current_bisecting_result.uniq_bug_id_int)
    else:
        bug_output_file.write("Bug ID: Unknown. \n\n")

    bug_output_file.write("Query: %s \n\n" % current_bisecting_result.query)

    if current_bisecting_result.opt_result != [] and current_bisecting_result.opt_result != None \
        and current_bisecting_result.unopt_result != [] and current_bisecting_result.unopt_result != None:
        for idx in range(min(len(current_bisecting_result.opt_result), len(current_bisecting_result.unopt_result))):
            bug_output_file.write("Last buggy NUM %d: \n" % idx)
            bug_output_file.write("Last buggy Opt_result: %s \n" % current_bisecting_result.opt_result[idx])
            bug_output_file.write("Last buggy Unopt_result: %s \n" % current_bisecting_result.unopt_result[idx])
    else:
        bug_output_file.write("Last buggy results: None. Possibly because the latest commit already fix the bug. \n\n")

    if current_bisecting_result.first_buggy_commit_id != "":
        bug_output_file.write("First buggy commit ID: %s. \n\n" % current_bisecting_result.first_buggy_commit_id)
    else:
        bug_output_file.write("First buggy commit ID: Unknown. \n\n")
    if current_bisecting_result.is_bisecting_error == True and current_bisecting_result.bisecting_error_reason != "":
        bug_output_file.write("Bisecting Error. \n\nBesecting error reason: %s. \n\n\n\n" % current_bisecting_result.bisecting_error_reason)

    bug_output_file.close()

def run_bisecting(opt_unopt_queries):
    global total_processing_bug_count_int
    global total_processed_bug_count_int
    global total_bug_count_int
    global uniq_bug_id_int
    print("\n\n\nBeginning testing with query: \n%s \n" % (opt_unopt_queries))
    log_output.write("\n\n\nBeginning testing with query: \n%s \n" % (opt_unopt_queries))
    current_bisecting_result = bi_secting_commits(opt_unopt_queries = opt_unopt_queries, all_commits_str = all_commits_hexsha, all_tags = all_tags, ignored_commits_str = ignored_commits_hexsha)
    if not current_bisecting_result.is_bisecting_error:
        current_bisecting_result = cross_compare(current_bisecting_result)  # The unique bug id will be appended to current_result_l when running cross_compare
        write_uniq_bugs_to_files(current_bisecting_result)
    else:
        current_bisecting_result.uniq_bug_id_int = "Unknown"  # Unique bug id is Unknown. Meaning unsorted or unknown bug.
        write_uniq_bugs_to_files(current_bisecting_result)
    log_output.flush()
    tmp_percentage = total_processing_bug_count_int / total_bug_count_int * 100
    print("Currently, we have %d / %d being processed, %d percent. Total unique bug number: %d. \n" % (total_processing_bug_count_int, total_bug_count_int, tmp_percentage, uniq_bug_id_int))


def status_print():
    while True:
        global total_processing_bug_count_int
        global total_processed_bug_count_int
        global total_bug_count_int
        global uniq_bug_id_int
        time.sleep(1.0)  # Sleep 1 second.
        if total_bug_count_int == 0:
            print("Initializing...\n")
        else:
            tmp_percentage = total_processing_bug_count_int / total_bug_count_int * 100
            print("Currently, we have %d / %d being processed, %d percent. Total unique bug number: %d. \n" % (total_processing_bug_count_int, total_bug_count_int, tmp_percentage, uniq_bug_id_int))
            # log_output.write("Currently, we have %d/%d being processed, %d percent. Total unique bug number: %d. \n\n" % (total_processing_bug_count_int, total_bug_count_int, total_processing_bug_count_int/total_bug_count_int*100, uniq_bug_id_int))




def setup_and_run_fuzzing():
    global all_fuzzing_instances_list
    os.chdir(FUZZING_ROOT_DIR)
    for i in range(MAX_FUZZING_INSTANCE):
        try:
            shutil.rmtree(os.path.join(FUZZING_ROOT_DIR, "fuzz_root_" + str(i)))
        except:
            pass
    
    for i in range(MAX_FUZZING_INSTANCE):
        shutil.copytree(os.path.join(FUZZING_ROOT_DIR, "fuzz_root"), os.path.join(FUZZING_ROOT_DIR, "fuzz_root_" + str(i)))
        os.chdir(os.path.join(FUZZING_ROOT_DIR, "fuzz_root_" + str(i)))
        fuzzing_command = FUZZING_COMMAND + " -c " + str(i) + " -- " + SQLITE_FUZZING_BINARY_PATH + " &"
        p = subprocess.Popen([fuzzing_command], cwd=os.path.join(FUZZING_ROOT_DIR, "fuzz_root_" + str(i)), shell=True, stdout=subprocess.DEVNULL, stdin=subprocess.DEVNULL)
        print("Fuzzing process running, PID is: %d" % (p.pid))
        log_output.write("Fuzzing process running, PID is: %d \n" % (p.pid))
        all_fuzzing_instances_list.append(p)
        

def exit_handler():
    global all_fuzzing_instances_list
    for fuzzing_instance in all_fuzzing_instances_list:
        fuzzing_instance.kill()

if __name__ == "__main__":

    # setup_and_run_fuzzing()
    # atexit.register(exit_handler)

    os.chdir(os.path.join(FUZZING_ROOT_DIR, "bug_analysis")) # Change back to original workdir in case of errors. 

    if os.path.isdir(UNIQUE_BUG_OUTPUT_DIR):
        shutil.rmtree(UNIQUE_BUG_OUTPUT_DIR)
    os.mkdir(UNIQUE_BUG_OUTPUT_DIR)

    repo = Repo(SQLITE_DIR)
    assert not repo.bare

    # thread = Thread(target = status_print)
    # thread.start()

    all_commits_hexsha, all_tags = _get_all_commits(repo=repo)
    log_output.write("Getting %d number of commits, and %d number of tags. \n\n" % (len(all_commits_hexsha), len(all_tags)))
    print("Getting %d number of commits, and %d number of tags. \n\n" % (len(all_commits_hexsha), len(all_tags)))

    print("Beginning reading the buggy query files. \n\n")
    log_output.write("Beginning reading the buggy query files. \n\n")
    all_queries = read_queries_from_files(file_directory=QUERY_SAMPLE_DIR)
    all_queries = restructured_and_clean_all_queries(all_queries=all_queries)  # all_queries = [[opt_queries, unopt_queries]]
    print("Finished reading the buggy query files. \n\n")
    log_output.write("Finished reading the buggy query files. \n\n")
    log_output.flush()


    print("Beginning bisecting. \n\n")
    log_output.write("Beginning bisecting. \n\n")
    all_results = []
    for all_queries_idx, opt_unopt_queries in enumerate(all_queries):
        # print("\n\n\n Query index: %d" % (all_queries_idx))
        if "randomblob" in opt_unopt_queries or "random" in opt_unopt_queries or "julianday" in opt_unopt_queries:
            continue
        total_processing_bug_count_int = total_processed_bug_count_int + all_queries_idx + 1
        run_bisecting(opt_unopt_queries = opt_unopt_queries)
    print("Finished bisecting. \n\n")
    log_output.write("Finished bisecting already saved files. \n\n")
    log_output.flush()

    all_queries.clear()
    all_results.clear()

    print("Beginning processing the new files being generated during the time of cross comparing. (Infinite Loop) \n\n")
    log_output.write("Beginning processing the new files being generated during the time of cross comparing. (Infinite Loop) \n\n")
    while True:
        all_new_queries = read_queries_from_files(file_directory=QUERY_SAMPLE_DIR)
        if all_new_queries == []:
            time.sleep(1.0)
            continue
        all_new_queries = restructured_and_clean_all_queries(all_queries=all_new_queries)
        for all_queries_idx, opt_unopt_queries in enumerate(all_new_queries): 
            if "randomblob" in opt_unopt_queries or "random" in opt_unopt_queries or "julianday" in opt_unopt_queries:
                continue
            total_processing_bug_count_int = total_processed_bug_count_int + all_queries_idx + 1
            run_bisecting(opt_unopt_queries = opt_unopt_queries)

