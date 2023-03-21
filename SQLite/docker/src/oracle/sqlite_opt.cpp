#include "./sqlite_opt.h"
#include "../include/mutator.h"
#include <iostream>

#include <fstream> // Debug purpose.

#include <regex>
#include <string>

bool SQL_OPT::mark_all_valid_node(vector<IR *> &v_ir_collector) { return true; }

vector<IR *> SQL_OPT::post_fix_transform_select_stmt(IR *cur_stmt,
                                                     unsigned multi_run_id) {

  vector<IR *> trans_IR_vec;

  cur_stmt = cur_stmt->deep_copy();

  trans_IR_vec.push_back(cur_stmt);

  return trans_IR_vec;
}
