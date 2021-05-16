import os
import re
import shutil

from Bug_Analysis.helper.data_struct import log_out_line, BisectingResults, RESULT, is_string_only_whitespace
from Bug_Analysis.bi_config import *


class IO:
    total_processed_bug_count_int: int = 0

    @classmethod
    def read_queries_from_files(cls, file_directory:str):

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

        # Grab all the opt queries.
        queries_out = []
        begin_idx = []
        end_idx = []
        for m in re.finditer(veri_begin_regex, query_str):
            begin_idx.append(m.end())
        for m in re.finditer(veri_end_regex, query_str):
            end_idx.append(m.start())
        for i in range(min( len(begin_idx), len(end_idx) )):
            current_stmt = query_str[begin_idx[i]: end_idx[i]]
            current_stmt = current_stmt.replace('\n', '')
            queries_out.append(current_stmt)

        return queries_out

    @classmethod
    def _retrive_all_normal_queries_matches(cls, query_str, veri_begin_regex, veri_end_regex):
        start_of_norec = query_str.find(veri_begin_regex)
        normal_query = query_str[:start_of_norec]

        begin_idx = []
        end_idx = []

        for m in re.finditer(veri_end_regex, query_str):
            begin_idx.append(m.end())
        for m in re.finditer(veri_begin_regex, query_str):
            end_idx.append(m.start())

        end_idx = end_idx[1:]  # Ignore the first one. The end_idx has 1 offset shift compare to begin_idx. 

        for i in range(min( len(begin_idx), len(end_idx) )):
            current_str:str = query_str[begin_idx[i]: end_idx[i]]
            current_str = current_str.replace('\n', '')
            normal_query += current_str + '\n'

        return normal_query

    @classmethod
    def _pretty_print(cls, query, same_idx):

        start_of_norec = query.find("SELECT 13579")

        # header = query[:start_of_norec]
        tail = query[start_of_norec:]

        # lines = tail.splitlines()
        # opt_selects = lines[1::6]
        # unopt_selects = lines[4::6]
        opt_selects, unopt_selects = cls._retrive_all_verifi_queries_matches(tail)

        # It is possible to have multiple normal stmts between norec select stmts. Include them to put them into the header of the output. 
        header = cls._retrive_all_normal_queries(query)

        new_tail = ""
        effect_idx = 0
        for idx in range(0, len(opt_selects)):
            if idx in same_idx:
                continue
            effect_idx += 1
            new_tail += ("SELECT \"--------- " + str(effect_idx) + "\";" + opt_selects[idx] + unopt_selects[idx] + "\n")

        return header + new_tail
    
    @classmethod
    def _pretty_process(cls, bisecting_result:BisectingResults):

        if bisecting_result.opt_result == [] or bisecting_result.opt_result == None or bisecting_result.unopt_result == [] or bisecting_result.unopt_result == None:
            return

        same_idx = []
        for idx in range(0, len(bisecting_result.opt_result)):
            # Ignore the result with the same output, and ignore the result that are negative. (-1 Error Execution for most cases)
            if bisecting_result.all_result_flags[idx] != RESULT.FAIL or bisecting_result.opt_result[idx] == "Error" or bisecting_result.unopt_result[idx] == "Error":
                same_idx.append(idx)

        bisecting_result.query = cls._pretty_print(bisecting_result.query, same_idx)

        same_idx.reverse()
        for idx in same_idx:
            bisecting_result.opt_result.pop(idx)
            bisecting_result.unopt_result.pop(idx)

    @classmethod
    def write_uniq_bugs_to_files(cls, current_bisecting_result: BisectingResults): 
        if not os.path.isdir(UNIQUE_BUG_OUTPUT_DIR):
            os.mkdir(UNIQUE_BUG_OUTPUT_DIR)
        current_unique_bug_output = os.path.join(UNIQUE_BUG_OUTPUT_DIR, "bug_" + str(current_bisecting_result.uniq_bug_id_int))
        if os.path.exists(current_unique_bug_output):
            append_or_write = 'a'
        else:
            append_or_write = 'w'
        bug_output_file = open(current_unique_bug_output, append_or_write)

        cls.pretty_process(current_bisecting_result)

        if current_bisecting_result.uniq_bug_id_int != "Unknown":
            bug_output_file.write("Bug ID: %d. \n\n" % current_bisecting_result.uniq_bug_id_int)
        else:
            bug_output_file.write("Bug ID: Unknown. \n\n")

        bug_output_file.write("Query: %s \n\n" % current_bisecting_result.query)

        if current_bisecting_result.final_res_flag == RESULT.SEG_FAULT:
            bug_output_file.write("Error: The early commit failed to compile, or crashing. Failed to find the bug introduced commit. \n")

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
        from Bug_Analysis.helper.bisecting import Bisect
        while True:
            if cls.total_processed_bug_count_int == 0:
                print("Initializing...\n")
            else:
                print("Currently, we have %d being processed. Total unique bug number: %d. \n" % (cls.total_processed_bug_count_int, Bisect.uniq_bug_id_int))

    @classmethod
    def gen_unique_bug_output_dir(cls, is_removed_ori:bool = True):
        if not os.path.isdir(os.path.join(FUZZING_ROOT_DIR, "bug_analysis")):
            os.mkdir(os.path.join(FUZZING_ROOT_DIR, "bug_analysis"))
        if not os.path.isdir(os.path.join(FUZZING_ROOT_DIR, "bug_analysis/bug_samples")):
            os.mkdir(os.path.join(FUZZING_ROOT_DIR, "bug_analysis/bug_samples"))
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
        for m in re.finditer('13579', result_str):
            begin_idx.append(m.end())
        for m in re.finditer('97531', result_str):
            end_idx.append(m.start())
        for i in range(min( len(begin_idx), len(end_idx) )):
            cur_res = result_str[begin_idx[i]: end_idx[i]]
            if ("Error" in cur_res):
                res_str_out.append("Error")
            else:
                res_str_out.append(cur_res)
        
        return res_str_out, RESULT.PASS
