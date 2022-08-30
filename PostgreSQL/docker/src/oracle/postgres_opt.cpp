#include "./postgres_opt.h"
#include "../include/mutate.h"
#include <iostream>

#include <regex>
#include <string>

bool SQL_OPT::is_oracle_select_stmt(IR* cur_stmt) {

  if (cur_stmt == NULL) {
    // cerr << "Return false because cur_stmt is NULL; \n";
    return false;
  }

  if (cur_stmt->get_ir_type() != kSelectStmt) {
    // cerr << "Return false because this is not a SELECT stmt: " << get_string_by_ir_type(cur_stmt->get_ir_type()) <<  " \n";
    return false;
  }

  return true;

}

vector<IR*> SQL_OPT::post_fix_transform_select_stmt(IR* cur_stmt, unsigned multi_run_id){
  vector<IR*> trans_IR_vec;

  cur_stmt->parent_ = NULL;

  /* Double check whether the stmt is OPT compatible */
  if (!is_oracle_select_stmt(cur_stmt)) {
    return trans_IR_vec;
  }

  IR* first_stmt = cur_stmt->deep_copy();

  trans_IR_vec.push_back(first_stmt); // Save the original version.
  
  return trans_IR_vec;

}

void SQL_OPT::compare_results(ALL_COMP_RES &res_out) {

  res_out.final_res = ORA_COMP_RES::Pass;
  bool is_all_err = true;

  for (COMP_RES &res : res_out.v_res) {
    if (res.v_res_str.size() < 3) {
        res.comp_res = ORA_COMP_RES::Error;
        res.res_int_0 = -1;
        res.res_int_1 = -1;
        res.res_int_2 = -1;
        res.v_res_int.push_back(-1);
        res.v_res_int.push_back(-1);
        res.v_res_int.push_back(-1);
        continue;
    }
    if (findStringIn(res.v_res_str[0], "Error") ||
        findStringIn(res.v_res_str[2], "Error") ||
        findStringIn(res.v_res_str[1], "Error")) {
      res.comp_res = ORA_COMP_RES::Error;
      res.res_int_0 = -1;
      res.res_int_1 = -1;
      res.res_int_2 = -1;
      res.v_res_int.push_back(-1);
      res.v_res_int.push_back(-1);
      res.v_res_int.push_back(-1);
      continue;
    }

    vector<string> v_res_a = string_splitter(res.v_res_str[0], '\n');
    vector<string> v_res_b = string_splitter(res.v_res_str[1], '\n');
    vector<string> v_res_c = string_splitter(res.v_res_str[2], '\n');

      if (v_res_a.size() > 50 || v_res_b.size() > 50) {
          res.comp_res = ORA_COMP_RES::Error;
          res.v_res_int.push_back(-1);
          res.v_res_int.push_back(-1);
          res.v_res_int.push_back(-1);
        continue;
      }

      res.res_int_0 = v_res_a.size();
      res.res_int_1 = v_res_b.size();
      res.res_int_2 = v_res_c.size();

      res.v_res_int.push_back(res.res_int_0);
      res.v_res_int.push_back(res.res_int_1);
      res.v_res_int.push_back(res.res_int_2);

      is_all_err = false;
      if (res.res_int_0 != res.res_int_1 || res.res_int_1 != res.res_int_2) { // Found mismatched.
        res.comp_res = ORA_COMP_RES::Fail;
        res_out.final_res = ORA_COMP_RES::Fail;
      } else {
        res.comp_res = ORA_COMP_RES::Pass;
      }
 
  }

  if (is_all_err && res_out.final_res != ORA_COMP_RES::Fail)
    res_out.final_res = ORA_COMP_RES::ALL_Error;

  return;

}
