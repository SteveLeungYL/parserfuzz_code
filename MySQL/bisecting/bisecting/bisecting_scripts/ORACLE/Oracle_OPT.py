from typing import List, Tuple

import constants
from loguru import logger


class Oracle_OPT:

    @staticmethod
    def comp_query_res(all_res_lll) -> Tuple[constants.RESULT, List[constants.RESULT]]:
        
        if len(all_res_lll) == 0 or len(all_res_lll[0]) == 0:
            return constants.RESULT.ALL_ERROR, [constants.RESULT.ERROR]

        all_res_out = []
        ori_res = all_res_lll[0][0]
        for cur_res_single_run in all_res_lll:
            # Has only one SELECT in the query. 
            cur_res = cur_res_single_run[0]
            
            result = constants.RESULT.PASS
            if "error" in ori_res.casefold() or "error" in cur_res.casefold():
                result = constants.RESULT.ERROR
                all_res_out.append(result)
                break
            elif len(ori_res.splitlines()) != len(cur_res.splitlines()):
                result = constants.RESULT.FAIL
                all_res_out.append(result)
                break
            else:
                result = constants.RESULT.PASS
                all_res_out.append(result)

        return all_res_out[0], all_res_out
