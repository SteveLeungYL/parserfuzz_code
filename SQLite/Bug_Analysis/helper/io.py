import enum
import os
import re
import shutil

from Bug_Analysis.helper.data_struct import log_out_line, BisectingResults, RESULT, is_string_only_whitespace
from Bug_Analysis.bi_config import *


class IO:
    total_processed_bug_count_int: int = 0

    @classmethod
    def read_queries_from_files(cls, file_directory:str, is_removed_read:bool = True):

        all_queries = []
        all_files_in_dir = os.listdir(file_directory)

        cls.total_processed_bug_count_int += 1

        for current_file_d in sorted(all_files_in_dir):
            if os.path.isdir(os.path.join(file_directory, current_file_d)) or current_file_d == "." or current_file_d == "..":
                continue
            log_out_line("Filename: " + str(current_file_d) + ". \n")
            current_file = open(os.path.join(file_directory, current_file_d), 'r', errors="replace")
            current_file_str = current_file.read()
            current_file_str = re.sub(r'[^\x00-\x7F]+',' ', current_file_str)
            current_file_str = current_file_str.replace(u'\ufffd', ' ')
            all_queries.append(current_file_str)
            current_file.close()
            if is_removed_read == True:
                os.remove(os.path.join(file_directory, current_file_d))
            # Only retrive one file at a time. 
            if len(all_queries) != 0:
                break
        
        return cls._restructured_and_clean_all_queries(all_queries=all_queries)

    @classmethod
    def _restructured_and_clean_all_queries(cls, all_queries):
        output_all_queries = []

        for queries in all_queries:
            current_queries_in = queries.split('\n')
            current_queries_out = ""
            for query in current_queries_in:
                if 'Result string' in query:
                    break
                if not re.search(r'\w', query):
                    continue
                if 'Query' in query or query == ';' or query == ' ' or query == '' or query == '\n':
                    continue
                if query != current_queries_in[-1]:
                    current_queries_out += query + " \n"
                else:
                    current_queries_out += query

            output_all_queries.append(current_queries_out)

        return output_all_queries

    @classmethod
    def _retrive_all_verifi_queries_matches(cls, query_str, veri_begin_regex, veri_end_regex):

        # Grab all the verification queries.
        queries_out = []
        queries_pairs = []
        begin_idx = []
        end_idx = []
        for m in re.finditer(veri_begin_regex, query_str):
            begin_idx.append(m.end())
        for m in re.finditer(veri_end_regex, query_str):
            end_idx.append(m.start())
        for i in range(min( len(begin_idx), len(end_idx) )):
            current_stmt = query_str[begin_idx[i]: end_idx[i]]
            current_stmt = current_stmt.replace('\n', '')
            if current_stmt == "" or current_stmt == " ":
                continue
            queries_pairs.append(current_stmt)
            if (len(queries_pairs) == 2):
                queries_out.append(queries_pairs)
                queries_pairs = []

        return queries_out

    @classmethod
    def _retrive_all_normal_queries_matches(cls, query_str, veri_begin_regex, veri_end_regex):

        begin_idx = []
        end_idx = []

        for m in re.finditer(veri_end_regex, query_str):
            begin_idx.append(m.end())
        for m in re.finditer(veri_begin_regex, query_str):
            end_idx.append(m.start())

        start_of_verification = end_idx[0]
        normal_query = query_str[:start_of_verification]

        end_idx = end_idx[1:]  # Ignore the first one. The end_idx has 1 offset shift compare to begin_idx. 

        for i in range(min( len(begin_idx), len(end_idx) )):
            current_str:str = query_str[begin_idx[i]: end_idx[i]]
            current_str = current_str.replace('\n', '')
            if is_string_only_whitespace(current_str):
                continue
            normal_query += current_str + '\n'

        log_out_line("Header is: " + str(normal_query))
        return normal_query

    @classmethod
    def _pretty_print(cls, query, same_idx, oracle):

        start_of_norec = query.find("SELECT 'BEGIN VERI 0';")

        # header = query[:start_of_norec]
        tail = query[start_of_norec:]

        # lines = tail.splitlines()
        # opt_selects = lines[1::6]
        # unopt_selects = lines[4::6]
        veri_stmts = cls._retrive_all_verifi_queries_matches(tail, r"SELECT 'BEGIN VERI [0-9]';", r"SELECT 'END VERI [0-9]';")

        # It is possible to have multiple normal stmts between norec select stmts. Include them to put them into the header of the output. 
        header = cls._retrive_all_normal_queries_matches(query, r"SELECT 'BEGIN VERI [0-9]';", r"SELECT 'END EXPLAIN [0-9]';")

        new_tail = "\n\n\n"
        effect_idx = 0
        for idx in range(len(veri_stmts)):
            if idx in same_idx:
                continue
            effect_idx += 1
            new_tail += "SELECT \"--------- " + str(effect_idx) + "  "
            for cur_veri_stmt in veri_stmts[idx]:
                new_tail += cur_veri_stmt + "    "
            new_tail += "\n"

        return header + new_tail
    
    @classmethod
    def _pretty_process(cls, bisecting_result:BisectingResults, oracle):

        if bisecting_result.last_buggy_res_str_l == [] or bisecting_result.last_buggy_res_str_l == None:
            return

        same_idx = []
        for idx in range(len(bisecting_result.last_buggy_res_flags_l)):
            # Ignore the result with the same output, and ignore the result that are negative. (-1 Error Execution for most cases)
            if bisecting_result.last_buggy_res_flags_l[idx] != RESULT.FAIL:
                same_idx.append(idx)
                continue

        # log_out_line("same_idx: %s" % (str(same_idx)))

        # log_out_line("res: %s" % (str(bisecting_result.last_buggy_res_str_l[0])))

        pretty_query = []
        for cur_query in bisecting_result.query:
            pretty_query.append(cls._pretty_print(cur_query, same_idx, oracle))
        bisecting_result.query = pretty_query

        same_idx.reverse()
        for idx in same_idx:
            for j in range(len(bisecting_result.last_buggy_res_str_l)):
                bisecting_result.last_buggy_res_str_l[j].pop(idx)

    @classmethod
    def write_uniq_bugs_to_files(cls, current_bisecting_result: BisectingResults, oracle): 
        if not os.path.isdir(UNIQUE_BUG_OUTPUT_DIR):
            os.mkdir(UNIQUE_BUG_OUTPUT_DIR)
        current_unique_bug_output = os.path.join(UNIQUE_BUG_OUTPUT_DIR, "bug_" + str(current_bisecting_result.uniq_bug_id_int))
        if os.path.exists(current_unique_bug_output):
            append_or_write = 'a'
        else:
            append_or_write = 'w'
        bug_output_file = open(current_unique_bug_output, append_or_write)

        cls._pretty_process(current_bisecting_result, oracle)

        if current_bisecting_result.uniq_bug_id_int != "Unknown":
            bug_output_file.write("Bug ID: %d. \n\n" % current_bisecting_result.uniq_bug_id_int)
        else:
            bug_output_file.write("Bug ID: Unknown. \n\n")

        for idx, cur_query in enumerate(current_bisecting_result.query):
            bug_output_file.write("Query %d: \n%s \n\n" % (idx, cur_query))

        if current_bisecting_result.final_res_flag == RESULT.SEG_FAULT:
            bug_output_file.write("Error: The early commit failed to compile, or crashing. Failed to find the bug introduced commit. \n")

        if current_bisecting_result.last_buggy_res_str_l != [] and current_bisecting_result.last_buggy_res_str_l != None:
            for i, cur_run_res in enumerate(current_bisecting_result.last_buggy_res_str_l):
                bug_output_file.write("Run ID: %d \n" % (i))
                for j, cur_res in enumerate(cur_run_res):
                    bug_output_file.write("Last Buggy Result Num: %d \n" % j)
                    for k, cur_r in enumerate(cur_res):
                        bug_output_file.write("RES %d: \n%s\n" % (k, cur_r))
        else:
            bug_output_file.write("Last buggy results: None. Possibly because the latest commit already fix the bug. \n\n")

        if current_bisecting_result.first_buggy_commit_id != "":
            bug_output_file.write("First buggy commit ID: %s. \n\n" % current_bisecting_result.first_buggy_commit_id)
        else:
            bug_output_file.write("First buggy commit ID: Unknown. \n\n")
        if current_bisecting_result.first_corr_commit_id != "":
            bug_output_file.write("First correct (or crashing) commit ID: %s. \n\n" % current_bisecting_result.first_corr_commit_id)
        else:
            bug_output_file.write("First correct commit ID: Unknown. \n\n")
        if current_bisecting_result.is_bisecting_error == True or current_bisecting_result.bisecting_error_reason != "":
            bug_output_file.write("Bisecting Error. \n\nBesecting error reason: %s. \n\n\n\n" % current_bisecting_result.bisecting_error_reason)

        bug_output_file.write("\n\n\n")

        bug_output_file.close()

    @classmethod
    def status_print(cls):
        # from Bug_Analysis.helper.bisecting import Bisect
        print("Currently, we have %d being processed. \n" % (cls.total_processed_bug_count_int))

    @classmethod
    def gen_unique_bug_output_dir(cls, is_removed_ori:bool = True):
        if not os.path.isdir(os.path.join(FUZZING_ROOT_DIR, "Bug_Analysis")):
            os.mkdir(os.path.join(FUZZING_ROOT_DIR, "Bug_Analysis"))
        if not os.path.isdir(os.path.join(FUZZING_ROOT_DIR, "Bug_Analysis/bug_samples")):
            os.mkdir(os.path.join(FUZZING_ROOT_DIR, "Bug_Analysis/bug_samples"))
        if os.path.isdir(UNIQUE_BUG_OUTPUT_DIR) and is_removed_ori == True:
            shutil.rmtree(UNIQUE_BUG_OUTPUT_DIR)
            os.mkdir(UNIQUE_BUG_OUTPUT_DIR)

    @classmethod
    def retrive_results_from_str(cls, begin_sign:str, end_sign:str, result_str:str):
        if result_str.count(begin_sign) < 1 or result_str.count(end_sign) < 1 or is_string_only_whitespace(result_str) or result_str == "":
            return None, RESULT.ALL_ERROR  # Missing the outputs from the res_str. Returnning None implying errors. 

        # Grab all matching results.
        res_str_out = []
        begin_idx = []
        end_idx = []
        for m in re.finditer(begin_sign, result_str):
            begin_idx.append(m.end())
        for m in re.finditer(end_sign, result_str):
            end_idx.append(m.start())
        for i in range(min( len(begin_idx), len(end_idx) )):
            cur_res = result_str[begin_idx[i]: end_idx[i]]
            if ("Error" in cur_res):
                res_str_out.append("Error")
            else:
                res_str_out.append(cur_res)
        
        return res_str_out, RESULT.PASS
