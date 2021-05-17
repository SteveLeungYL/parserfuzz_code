import re
import numpy as np


from Bug_Analysis.helper.data_struct import RESULT, is_string_only_whitespace

class Oracle_NOREC():
    @staticmethod
    def retrive_all_results(result_str):
        if result_str.count("13579") < 1 or result_str.count("97531") < 1 or result_str.count("24680") < 1 or result_str.count("86420") < 1 or is_string_only_whitespace(result_str) or result_str == "":
            return None, RESULT.ERROR  # Missing the outputs from the opt or the unopt. Returnning None implying errors. 
        
        # Grab all the opt results.
        opt_results = []
        begin_idx = []
        end_idx = []
        for m in re.finditer('13579', result_str):
            begin_idx.append(m.end())
        for m in re.finditer('97531', result_str):
            end_idx.append(m.start())
        for i in range(min( len(begin_idx), len(end_idx) )):
            current_opt_result = result_str[begin_idx[i]: end_idx[i]]
            if ("Error" in current_opt_result):
                opt_results.append(-1)
            else:
                try:
                    current_opt_result_int = int(current_opt_result)
                except ValueError:
                    current_opt_result_int = -1
                opt_results.append(current_opt_result_int)

        # Grab all the unopt results.
        unopt_results = []
        begin_idx = []
        end_idx = []
        for m in re.finditer('24680', result_str):
            begin_idx.append(m.end())
        for m in re.finditer('86420', result_str):
            end_idx.append(m.start())
        for i in range(min( len(begin_idx), len(end_idx) )):
            current_unopt_result = result_str[ begin_idx[i] : end_idx[i] ]
            if ("Error" in current_unopt_result):
                unopt_results.append(-1)
            else:
                try:
                    current_unopt_result_int = int(float(current_unopt_result)+0.0001)  # Add 0.0001 to avoid inaccurate float to int transform. Transform are towards 0. 
                except ValueError:
                    current_unopt_result_int = -1
                unopt_results.append(current_unopt_result_int)

        all_results_out = []
        for i in range(min(len(opt_results), len(unopt_results))):
            cur_results_out = [opt_results[i], unopt_results[i]]
            all_results_out.append(cur_results_out)

        return all_results_out, RESULT.PASS


    @classmethod
    def comp_query_res(cls, queries_l, all_res_str_l):





