#include "../include/mutator.h"

#include "../parser/parser_helper.h"

#include "../AFL/debug.h"
#include "../oracle/sqlite_oracle.h"

#include <sys/resource.h>

#include <algorithm>
#include <sstream>
#include <assert.h>
#include <cfloat>
#include <climits>
#include <cstdio>
#include <deque>
#include <fstream>
#include <list>

using namespace std;

vector<string> Mutator::value_libary;
vector<string> Mutator::used_value_libary;
map<string, vector<string>>
    Mutator::m_tables; // Table name to column name mapping.
map<string, vector<string>>
    Mutator::m_tables_with_tmp; // Table name to column name mapping.
map<string, vector<string>>
    Mutator::m_table2index;                   // Table name to index mapping.
vector<string> Mutator::v_table_names;        // All saved table names
vector<string> Mutator::v_fts_vtable_names;        // All saved table names
vector<string> Mutator::v_table_names_single; // All used table names in one
                                              // query statement.
vector<string>
    Mutator::v_create_table_names_single;     // All created table names in the
                                              // current query statement.
vector<string> Mutator::v_window_name_single; // All the window names used in the
                                              // current query statement.
vector<string> Mutator::v_alias_names_single; // All alias name local to one
                                              // query statement.
map<string, vector<string>>
    Mutator::m_table2alias_single; // Table name to alias mapping.

/* Created table/view names, that is valid to only the single query stmts.
** Such as table created in WITH clause.
*/
vector<string> Mutator::v_create_table_names_single_with_tmp;
vector<string> Mutator::v_create_column_names_single_with_tmp;

int Mutator::dyn_fix_sql_errors(IR*& cur_stmt_root, string error_msg) {

  if (error_msg.size() > 2048) {
    // Error message too long. Ignore.
    return 1;
  }

  if (findStringIn(error_msg, "no tables specified")) {
    this->handle_no_tables_specified_error(cur_stmt_root);
    return 0;
  } else if (
      findStringIn(error_msg, "a JOIN clause is required before USING") ||
      findStringIn(error_msg, "a JOIN clause is required before ON")
      ) {
    this->handle_using_no_join_error(cur_stmt_root);
    return 0;
  } else if (findStringIn(error_msg, "DISTINCT is not supported for window functions")) {
    this->handle_distinct_in_window_func_error(cur_stmt_root);
    return 0;
  } else if (findStringIn(error_msg, "unsupported use of NULLS")) {
    this->handle_nulls_syntax_error(cur_stmt_root);
    return 0;
  } else if (findStringIn(error_msg, "syntax error after column name \"")) {
    // WITH RECURSIVE v81 ( c82 COLLATE NOCASE ASC, c83 COLLATE BINARY ) ...
    // syntax error after column name "c82"
    string column_name_str = string_splitter(error_msg, "syntax error after column name \"").back();
    column_name_str = string_splitter(column_name_str, "\"").front();
    handle_syntax_error_after_column_name_without_loc(cur_stmt_root, column_name_str);
    return 0;
  } else if (findStringIn(error_msg, "no such column")) {
    IR* err_node = locate_error_ir(cur_stmt_root, error_msg);
    if (err_node == nullptr) {
      handle_no_such_column_without_err_loc(cur_stmt_root, error_msg);
    } else {
      handle_no_such_column_with_err_loc(cur_stmt_root, err_node, error_msg);
    }
    return 0;
  } else if (findStringIn(error_msg, "no such table")) {
    IR* err_node = locate_error_ir(cur_stmt_root, error_msg);
    if (err_node == nullptr) {
      return handle_no_such_table_without_err_loc(cur_stmt_root, error_msg);
    } else {
      cerr << "TODO: not implemented. \n\n\n";
      return 1;
    }
  } else if (findStringIn(error_msg, "cannot join using column")) {
    handle_cannot_join_using_column(cur_stmt_root, error_msg);
    return 0;
  } else if (findStringIn(error_msg, "no such index: y")) {
    handle_no_such_index_y_err_without_loc(cur_stmt_root);
    return 0;
  } else if (findStringIn(error_msg, "no such index")) {
      handle_no_such_index_err_without_loc(cur_stmt_root);
      return 0;
  } else if (findStringIn(error_msg, "ORDER BY clause should come after UNION")) {
    // Remove all the order by clause
    handle_order_by_before_UNION_err(cur_stmt_root);
    return 0;
  } else if (findStringIn(error_msg, "LIMIT clause should come after UNION")) {
    // Remove all the LIMIT clause
    handle_limit_before_UNION_err(cur_stmt_root);
    return 0;
  } else if (findStringIn(error_msg, "a NATURAL join may not have an ON or USING clause")) {
    // Remove all the NATURAL keywords from the NATURAL JOIN clause.
    handle_natural_join_err(cur_stmt_root);
    return 0;
  } else if (findStringIn(error_msg, "unsupported frame specification")) {
    // Reformat the FRAME specification.
    handle_unsupported_frame(cur_stmt_root);
    return 0;
  } else if (findStringIn(error_msg, "HAVING clause on a non-aggregate query")) {
    // Remove the HAVING clause.
    handle_unsupported_having_clause(cur_stmt_root);
    return 0;
  } else if (findStringIn(error_msg, "GROUP BY term out of range - should be between")) {
    return handle_group_by_value_error(cur_stmt_root, error_msg);
  } else if (findStringIn(error_msg, "values were supplied")) {
    handle_wrong_num_of_values(cur_stmt_root, error_msg);
    return 0;
  } else if (findStringIn(error_msg, "IN(...) element has") || findStringIn(error_msg, " term - expected ")){
//    cerr << "\n\n\nDebug: Getting error: " << error_msg << "\n\n\n";
    return 1;
  }

  // Not being handled, skip fixing the current error.
  return 1;
}

IR* Mutator::locate_error_ir(IR* cur_stmt_root, string& error_msg) {

  vector<string> v_err_split = string_splitter(error_msg, "\n");
  if (v_err_split.size() != 4) {
    return nullptr;
  }
  v_err_split.pop_back(); // The very last line is empty.

  string& err_loc_line = v_err_split.back();
  if (!(findStringIn(err_loc_line, "error here"))) {
    return nullptr;
  }

  string::const_iterator match_iter = findStringIter(err_loc_line, "^");
  if (match_iter == err_loc_line.end()) {
    // Cannot find the ^ symbol at the line.
    return nullptr;
  }

  string err_loc_str = v_err_split[v_err_split.size() - 2];
  if ((match_iter-err_loc_line.begin()) >= err_loc_line.size()) {
    return nullptr;
  }

  /* Debug logging */
//  cerr << "begin\n";
//  for (auto& err: v_err_split) {
//    cerr << "err: " << err << "\n";
//  }
//  cerr << "end\n";

  int iter_index = match_iter-err_loc_line.begin();
  if (iter_index >= err_loc_str.size()) {
    return nullptr;
  }
  err_loc_str = err_loc_str.substr(iter_index);
  string tmp_err_loc_str;
  tmp_err_loc_str.reserve(err_loc_str.size());
  for (auto iter = 0; iter < err_loc_str.size(); iter++) {
    if (iter == 0) {
      tmp_err_loc_str += err_loc_str[iter];
      continue;
    }
    if (err_loc_str[iter] != ' ' && err_loc_str[iter] != ';' && err_loc_str[iter] != '(' && err_loc_str[iter] != ')' && err_loc_str[iter] != ',') {
      tmp_err_loc_str += err_loc_str[iter];
      continue;
    } else {
      break;
    }
  }
  err_loc_str = tmp_err_loc_str;
//  cerr << "Getting err_loc_str: " << err_loc_str << "\n\n";

  string err_extend_str = v_err_split[v_err_split.size() - 2];
  string::const_iterator ext_begin, ext_end;

  if ((match_iter - 5) <= err_loc_line.begin()) {
    ext_begin = err_loc_line.begin();
  } else {
    ext_begin = match_iter - 5;
  }

  if ((match_iter + int(err_loc_str.size()) + 5 - err_loc_line.begin()) >= err_extend_str.size()) {
    ext_end = err_loc_line.begin() + int(err_extend_str.size());
  } else {
    ext_end = match_iter + int(err_loc_str.size()) + 5;
  }

  if (ext_begin - err_loc_line.begin() > err_extend_str.size() ||
      ext_end - err_loc_line.begin() > err_extend_str.size()
      ) {
    cerr << "Logic Error: ext_begin or ext_end overflow!\n\n\n";
  }

  err_extend_str = err_extend_str.substr(ext_begin - err_loc_line.begin(), (ext_end - ext_begin));
  trim_string(err_extend_str);

  if (findStringIn(err_loc_str, ";")) {
    err_loc_str = err_loc_str.substr(0, err_loc_str.size() - 1);
  }
  if (findStringIn(err_extend_str, ";")) {
    err_extend_str = err_extend_str.substr(0, err_extend_str.size() - 1);
  }

  IR* err_extend_node = p_oracle->ir_wrapper.find_least_child_node_contain_str(cur_stmt_root, err_extend_str);

  /* Debug logging */
//  cerr << "For err_extend_str: " << err_extend_str << "\n\n";
//  debug(err_extend_node, 0);
//  cerr << "\n\n";

  if (err_extend_node == nullptr) {
    cerr << "Error: Getting NULL pointer on err_extend_node. \n\n\n";
    cerr << "Error message: " << error_msg << "\n\n\n";
    debug(cur_stmt_root, 0);
    return nullptr;
  }

  IR* err_loc_node = p_oracle->ir_wrapper.find_least_child_node_contain_str(err_extend_node, err_loc_str);

  /* Debug logging. */
//  debug(err_loc_node, 0);
//  cerr << "\n\n\n\n\n";

  return err_loc_node;

}

void Mutator::handle_unsupported_having_clause(IR*& cur_stmt_root) {
  // Remove the unsupported having clause.

  vector<IR*> v_having_clause = p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(cur_stmt_root, kHavingOpt, false, true);
  for (IR* cur_having_clause : v_having_clause) {
    cur_having_clause->str_val_ = " ";
  }

  return;
}

int Mutator::handle_wrong_num_of_values(IR*& cur_stmt_root, string error_msg) {

//  cerr << "\n\n\nDEBUG: inside handle_wrong_num_of_values: \n\n\n";
//  cerr << "Before fixing: " << cur_stmt_root->to_string() << "\n";

  vector<string> tmp_err_split = string_splitter(error_msg, " has ");
  if (tmp_err_split.size() <= 1) {
    cerr << "\n\n\nError, cannot find ' has ' in the handle_wrong_num_of_values function.\n\n\n";
    return 1;
  }

  error_msg = tmp_err_split.back();

  tmp_err_split = string_splitter(error_msg, " columns but ");
  if (tmp_err_split.size() <= 1) {
    cerr << "\n\n\nError, cannot find ' columns but ' in the handle_wrong_num_of_values function.\n\n\n";
    return 1;
  }
  error_msg = tmp_err_split.front();

  int target_num_of_vals = stoi(error_msg);
  if (target_num_of_vals <= 0) {
    cerr << "\n\n\nError, getting target_num_of_vals <= 0 in handle_wrong_num_of_values function.\n\n\n";
    return 1;
  }

  // Gather all the kValues clauses from the statement.
  // Change the values to the target number of values.

  vector<IR*> v_values_clauses = p_oracle
            ->ir_wrapper.get_ir_node_in_stmt_with_type(cur_stmt_root, kValues, false, true);

  for (IR* cur_value_clause : v_values_clauses) {
    IR* nexpr_node = p_oracle->ir_wrapper.get_nexprlist_from_value_clause(cur_value_clause);
    string new_vals_str = "";

    DataType cur_arg_type;
    int num_exprs = (get_rand_int(13) + 1);
    for (int i = 0; i < num_exprs; i++) {
      for (int j = 0; j < target_num_of_vals; j++) {
        if (j != 0) {
          new_vals_str += ", ";
        }
        DATATYPE rand_any_type =
            cur_arg_type.gen_rand_any_type(this->all_supported_types);
        cur_arg_type.set_data_type(rand_any_type);
        new_vals_str += cur_arg_type.mutate_type_entry();
      }
      if (i != num_exprs-1) {
        new_vals_str += "), (";
      }
    }

    nexpr_node->str_val_ = new_vals_str;

  }

//  cerr << "After fixing: " << cur_stmt_root->to_string() << "\n";

  return 0;
}

int Mutator::handle_group_by_value_error(IR*& cur_stmt_root, string& error_msg) {
  string min_val_str = string_splitter(error_msg, "GROUP BY term out of range - should be between ").back();
  string max_val_str;
  vector<string> v_tmp_split = string_splitter(min_val_str, " and ");
  min_val_str = v_tmp_split.front();
  max_val_str = v_tmp_split.back();

  int min_val = stoi(min_val_str);
  int max_val = stoi(max_val_str) + 1;

  int rand_new_num = get_rand_int(min_val, max_val);

  bool is_found = false;

  vector<IR*> v_group_clause = p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(cur_stmt_root, kGroupbyOpt, false, true);
  for (auto cur_group : v_group_clause) {
    if (cur_group->is_empty()) {
      continue;
    }
    cur_group->str_val_ = " GROUP BY " + to_string(rand_new_num);
    is_found = true;
  }

  if (is_found) {
    return 0;
  } else {
    // The group by problem could due to an error in the CREATE VIEW statement.
    return 1;
  }

}

void Mutator::handle_unsupported_frame(IR*& cur_stmt_root) {

  vector<IR*> v_frame_node = p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(cur_stmt_root, kFrameOpt, false, true);

  for (IR* cur_frame_node : v_frame_node) {
    string res_str = "RANGE BETWEEN ";
    switch (get_rand_int(2)) {
    case 0:
      res_str += "CURRENT ROW ";
      break;
    case 1:
      res_str += "UNBOUNDED PRECEDING ";
      break;
    }
    res_str += "AND ";
    switch (get_rand_int(2)) {
    case 0:
      res_str += "CURRENT ROW ";
      break;
    case 1:
      res_str += "UNBOUNDED FOLLOWING ";
      break;
    }
    cur_frame_node->str_val_ = res_str;
  }

  return;

}

void Mutator::handle_cannot_join_using_column(IR*& cur_stmt_root, string& err_str) {

  string shorten_str = string_splitter(err_str, "cannot join using column ").back();
  shorten_str = string_splitter(shorten_str, " ").front();
  vector<IR*> v_match_node = p_oracle->ir_wrapper.get_ir_node_in_stmt_with_str(cur_stmt_root, shorten_str, false, true);

  if (v_match_node.size() == 0) {
    return;
  }

  for (IR* cur_match_node: v_match_node) {
    if (
        !(p_oracle->ir_wrapper.is_ir_in(cur_match_node, kOnUsing))
        ) {
      continue;
    }

    IR* on_using_node = p_oracle->ir_wrapper.get_parent_matching_type(cur_match_node, kOnUsing);
    on_using_node->str_val_ = " ";
    continue;
  }

  return;

}
void Mutator::handle_natural_join_err(IR*& cur_stmt_root) {

  vector<IR*> v_join_clause = p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(cur_stmt_root, kJoinop, false, true);
  for (IR* cur_join : v_join_clause) {
    // Omitted the NATURAL keyword from the JOIN clause.
    cur_join->op_->prefix_ = " ";
  }

  return;

}

void Mutator::handle_order_by_before_UNION_err(IR*& cur_stmt_root) {

  vector<IR*> v_order_by_clause = p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(cur_stmt_root, kOrderbyOpt, false, true);
  for (IR* cur_order_by : v_order_by_clause) {
    cur_order_by->str_val_ = " ";
  }

  return;

}

void Mutator::handle_limit_before_UNION_err(IR*& cur_stmt_root) {
  vector<IR*> v_limit_clause = p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(cur_stmt_root, kLimitOpt, false, true);
  for (IR* cur_limit : v_limit_clause) {
    cur_limit->str_val_ = " ";
  }

  return;
}


void Mutator::handle_syntax_error_after_column_name_without_loc(IR*& cur_stmt_root, const string& column_name_str ){
  // Remove all the COLLATE and SORTORDER constraints from the WITH clause handling.

  vector<IR*> v_column_name_node = p_oracle
    ->ir_wrapper.get_ir_node_in_stmt_with_str(cur_stmt_root, column_name_str, false, true);

  for (IR* cur_col_name_node : v_column_name_node) {
    if (p_oracle->ir_wrapper.is_ir_in(cur_col_name_node, kEidlist)) {
      IR* eidlist_node = p_oracle->ir_wrapper.get_parent_matching_type(cur_col_name_node, kEidlist);
      vector<IR*> v_collate_node = p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(eidlist_node, kCollate, false, true);
      for (IR* cur_collate_node: v_collate_node) {
        IR* new_collate_node = new IR(kCollate, OP0(), nullptr, nullptr);
        eidlist_node->swap_node(cur_collate_node, new_collate_node);
        cur_collate_node->deep_drop();
      }
      vector<IR*> v_sortorder = p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(eidlist_node, kSortorder, false, true);
      for (IR* cur_sortorder: v_sortorder) {
        cur_sortorder->op_->prefix_ = "";
      }
    }
  }

  return;

}

void Mutator::handle_distinct_in_window_func_error(IR*& cur_stmt_root) {

//  cerr << "Handling distinct_in_window, before: " << cur_stmt_root->to_string() << "\n\n";

  vector<IR*> v_distinct_clause = p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(cur_stmt_root, kDistinct, false, true);

  for (IR* cur_distinct: v_distinct_clause) {
    if (p_oracle->ir_wrapper.is_ir_in(cur_distinct, kExprFunc)) {
      cur_distinct->str_val_ = "";
      cur_distinct->op_->prefix_ = "";
//      cerr << "Found one\n";
    }
  }

//  cerr << "After: " << cur_stmt_root->to_string() << "\n\n\n\n";

  return;

}

void Mutator::handle_no_tables_specified_error(IR*& cur_stmt_root) {
  // For every kFrom node, insert id_top_table_name to the statement.
  vector<IR*> v_stl_prefix = p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(cur_stmt_root, kStlPrefix, false, true);

//  cerr << "Fixing handle_no_tables_specified_error, before: " << cur_stmt_root->to_string() << "\n";

  for (IR* cur_stl_prefix: v_stl_prefix) {
    if (!(cur_stl_prefix->is_empty())) {
      continue;
    }
    // Getting an empty stl_prefix, always exist in one statement.
    // No need to worry about nested situations, because the target
    // stl_prefix is empty.
    IR* new_top_table_node = new IR(kIdentifier, string("v0"), id_top_table_name);
    IR* new_join_op = new IR(kJoinop, OP3(",", "", ""), nullptr, nullptr);
    IR* new_stl_prefix = new IR(kStlPrefix, OP0(), new_top_table_node, new_join_op);
    cur_stmt_root->swap_node(cur_stl_prefix, new_stl_prefix);
    cur_stl_prefix->deep_drop();
  }

  vector<IR*> v_from = p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(cur_stmt_root, kFrom, false, true);

  for (IR* cur_from: v_from) {
    if (!(cur_from->is_empty())) {
      continue;
    }

    // The kFrom is empty
    IR* new_top_table_node = new IR(kIdentifier, string("v0"), id_top_table_name);
    IR* new_stl_prefix = new IR(kStlPrefix, OP0(), new_top_table_node, nullptr);
    IR* new_stl_list = new IR(kSeltablist, OP0(), new_stl_prefix, nullptr);
    IR* new_from = new IR(kFrom, OP0(), new_stl_list, nullptr);

    cur_stmt_root->swap_node(cur_from, new_from);
    cur_from->deep_drop();
  }

  rollback_dependency();
  this->validate(cur_stmt_root, false, false);

//  cerr << "After: " << cur_stmt_root->to_string() << "\n\n\n";

  return;

}

void Mutator::handle_using_no_join_error(IR*& cur_stmt_root) {
  // For every kFrom node, insert id_top_table_name to the statement.
  vector<IR*> v_on_using = p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(cur_stmt_root, kOnUsing, false, true);

//  cerr << "Fixing handle_using_no_join_error, before: " << cur_stmt_root->to_string() << "\n";

  for (IR* cur_on_using: v_on_using) {
    if (cur_on_using->is_empty()) {
      continue;
    }
    if (!(p_oracle->ir_wrapper.is_ir_in(cur_on_using, kSeltablist))) {
      cerr << "Error: Found kOnUsing not inside the StlPrefix. Logic error. \n\n\n";
    }

    IR* cur_sel_tab_list = p_oracle->ir_wrapper.get_parent_matching_type(cur_on_using, kSeltablist);
    vector<IR*> v_stl_prefix = p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(cur_sel_tab_list, kStlPrefix, false, true);

    for (IR* cur_stl_prefix : v_stl_prefix) {
      if (!(cur_stl_prefix->is_empty())) {
        continue;
      }
      // Getting an empty stl_prefix, always exist in one statement.
      // No need to worry about nested situations, because the target
      // stl_prefix is empty.
      IR* new_top_table_node = new IR(kIdentifier, string("v0"), id_top_table_name);
      IR* new_join_op = new IR(kJoinop, OP3(",", "", ""), nullptr, nullptr);
      IR* new_stl_prefix = new IR(kStlPrefix, OP0(), new_top_table_node, new_join_op);
      cur_stmt_root->swap_node(cur_stl_prefix, new_stl_prefix);
      cur_stl_prefix->deep_drop();
    }
  }

  rollback_dependency();
  this->validate(cur_stmt_root, false, false);

//  cerr << "After: " << cur_stmt_root->to_string() << "\n\n\n";

  return;

}


void Mutator::handle_nulls_syntax_error(IR*& cur_stmt_root) {

  vector<IR*> v_nulls_node = p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(cur_stmt_root, kNulls, false, true);

  for (IR* nulls_node : v_nulls_node) {
    nulls_node->str_val_ = "";
    nulls_node->op_->prefix_ = "";
  }

  return;

}

void Mutator::handle_no_such_index_err_without_loc(IR*& cur_stmt_root) {

//  cerr << "Fixing handle_no_such_index_y_err_without_loc, before: " << cur_stmt_root->to_string() << "\n";

    vector<IR*> v_index_by = p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(cur_stmt_root, kIndexedBy, false, true);

    for (IR* cur_index_by: v_index_by) {
        IR* new_index_by_node = new IR(kIndexedBy, OP0(), nullptr, nullptr);
        cur_stmt_root->swap_node(cur_index_by, new_index_by_node);
        cur_index_by->deep_drop();
    }

//  cerr << "Fixing handle_no_such_index_y_err_without_loc, after: " << cur_stmt_root->to_string() << "\n";
//  cerr << "END\n\n\n";

    return;

}

void Mutator::handle_no_such_index_y_err_without_loc(IR*& cur_stmt_root) {

//  cerr << "Fixing handle_no_such_index_y_err_without_loc, before: " << cur_stmt_root->to_string() << "\n";

  vector<IR*> v_index_name = p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(cur_stmt_root, id_index_name, false, true);

  for (IR* cur_index_name: v_index_name) {
    if (
        cur_index_name->str_val_ == "y" &&
        cur_index_name->parent_ != nullptr &&
        cur_index_name->parent_->type_ == kIndexedBy
        ) {
          IR* index_by_node = cur_index_name->parent_;
          IR* new_index_by_node = new IR(kIndexedBy, OP0(), nullptr, nullptr);
          cur_stmt_root->swap_node(index_by_node, new_index_by_node);
          index_by_node->deep_drop();
    }
  }

//  cerr << "Fixing handle_no_such_index_y_err_without_loc, after: " << cur_stmt_root->to_string() << "\n";
//  cerr << "END\n\n\n";

  return;

}

int Mutator::handle_no_such_table_without_err_loc(IR*& cur_stmt_root, string& err_str) {

  string target_col = string_splitter(err_str, "no such table: ").back();
  target_col = string_splitter(target_col, "\n").front();

//  cerr << "in no such table handling, before: " << cur_stmt_root->to_string() << "\n\n\n";

  vector<IR*> v_target_node = p_oracle->ir_wrapper.get_ir_node_in_stmt_with_str(cur_stmt_root, target_col, false, true);
  if (v_target_node.empty()) {
    return 1;
  }

  // Find the target node that is not from CREATE_TABLE context.
  IR* cur_target_node = nullptr;
  bool is_succeed = false;
  for (int trial = 0; trial < 5; trial++) {
    cur_target_node = vector_rand_ele(v_target_node);
    if (cur_target_node->id_type_ != id_create_table_name &&
        cur_target_node->id_type_ != id_create_table_name_with_tmp
        ) {
          is_succeed = true;
          break;
    }
  }
  if (!is_succeed) {
//    cerr << "From target_col:" << target_col << ", v_target_node size: " << v_target_node.size() << ", cannot find\n\n\n";
//    debug(cur_stmt_root, 0);
    return 1;
  }

  string ori_str = cur_target_node->to_string();
  string tmp_as;
  vector<string> v_tmp_split = string_splitter(ori_str, " AS");
  if (v_tmp_split.size() > 1) {
    tmp_as = " AS" + v_tmp_split.back();
  }
//  cerr << "ori_str: " << ori_str << ", tmp_as" << tmp_as << "\n\n\n";

  if (!(v_table_names_single.empty())) {
    cur_target_node->str_val_ = vector_rand_ele(v_table_names_single) + tmp_as;
  } else if (!(v_table_names.empty())) {
    cur_target_node->str_val_ = vector_rand_ele(v_table_names) + tmp_as;
  } else {
    cur_target_node->str_val_ = "'" + vector_rand_ele(string_libary) + "'";
  }

//  cerr << "after: " << cur_stmt_root->to_string() << "\n\n\n";

  return 0;
}

void Mutator::handle_no_such_column_without_err_loc(IR*& cur_stmt_root, string& err_str) {
  if (findStringIn(err_str, "rowid")) {
    // Using the unsupported rowid in the context. Just re-instantiat should be fine.
    rollback_dependency();
    validate(cur_stmt_root, false, false);
    return;
  } else if (findStringIn(err_str, "no such column: y")) {
    // Using the unsupported rowid in the context. Just re-instantiat should be fine.
    handle_no_tables_specified_error(cur_stmt_root);
    return;
  } else {
    string target_col = string_splitter(err_str, "no such column: ").back();
    target_col = string_splitter(target_col, "\n").front();

    if (
        target_col.size() > 2 &&
        target_col.front() == '\'' || // This is a string.
        target_col.front() == '"' // This is a string.
    ){
       target_col = target_col.substr(1, target_col.size() - 2);
    }

    vector<IR*> v_target_node = p_oracle->ir_wrapper.get_ir_node_in_stmt_with_str(cur_stmt_root, target_col, false, true);
    for (IR* cur_target_node: v_target_node) {
      bool is_set_col = false;
      if (
          cur_target_node->type_ == kIntegerLiteral ||
          cur_target_node->type_ == kStringLiteral ||
          (cur_target_node->str_val_.size() != 0 &&
           cur_target_node->str_val_.front() == '\'' || // This is a string.
           cur_target_node->str_val_.front() == '"' // This is a string.
           )

      ) {
        if (!this->v_table_names_single.empty()) {
          string rand_tab_str = vector_rand_ele(this->v_table_names_single);
          if (!this->m_tables[rand_tab_str].empty()) {
            string rand_col_str = vector_rand_ele(this->m_tables[rand_tab_str]);
            if (m_table2alias_single.count(rand_tab_str) > 0 && !m_table2alias_single[rand_tab_str].empty()) {
              rand_tab_str = vector_rand_ele(m_table2alias_single[rand_tab_str]);
            }
            IRTYPE cur_stmt_type = cur_stmt_root->type_;
            if (cur_stmt_type != kCmdCreateIndex &&
                cur_stmt_type != kCmdAlterTableAddColumn &&
                cur_stmt_type != kCmdAlterTableDropColumn &&
                cur_stmt_type != kCmdAlterTableRename &&
                cur_stmt_type != kCmdAlterTableRenameColumn &&
                cur_stmt_type != kCmdAnalyze) {
              cur_target_node->str_val_ = rand_tab_str + "." + rand_col_str;
            } else {
              cur_target_node->str_val_ = rand_col_str;
            }
            cur_target_node->type_ = kColumnname;
            cur_target_node->id_type_ = id_column_name; // id_column_name
            is_set_col = true;
          }
        }
      }
      if (!is_set_col) {
        if (get_rand_int(2)) {
          cur_target_node->str_val_ =
              "'" + vector_rand_ele(string_libary) + "'";
          cur_target_node->type_ = kStringLiteral;
        } else {
          cur_target_node->str_val_ = to_string(get_rand_int(100));
          cur_target_node->type_ = kIntegerLiteral;
        }
      }
    }
  }

  return;
}

void Mutator::handle_no_such_column_with_err_loc(IR*& cur_stmt_root, IR* cur_target_node, string& err_str) {

//  cerr << "Inside handle_no_such_column_with_err_loc, getting err_node\n";
//  debug(err_node, 0);
//  cerr << "end\n\n\n";
  bool is_set_col = false;
  if (
      cur_target_node->type_ == kIntegerLiteral ||
      cur_target_node->type_ == kStringLiteral ||
      (cur_target_node->str_val_.size() != 0 &&
           cur_target_node->str_val_.front() == '\'' || // This is a string.
       cur_target_node->str_val_.front() == '"' // This is a string.
       )

  ) {
    if (!this->v_table_names_single.empty()) {
      string rand_tab_str = vector_rand_ele(this->v_table_names_single);
      if (!this->m_tables[rand_tab_str].empty()) {
        string rand_col_str = vector_rand_ele(this->m_tables[rand_tab_str]);
        cur_target_node->str_val_ = rand_col_str;
        cur_target_node->type_ = kColumnname;
        cur_target_node->id_type_ = id_column_name; // id_column_name
        is_set_col = true;
      }
    }
  }
  if (!is_set_col && cur_target_node->type_ == kIdentifier) {
    if (get_rand_int(2)) {
      cur_target_node->str_val_ =
          "'" + vector_rand_ele(string_libary) + "'";
      cur_target_node->type_ = kStringLiteral;
    } else {
      cur_target_node->str_val_ = to_string(get_rand_int(100));
      cur_target_node->type_ = kIntegerLiteral;
    }
  }
//  debug(err_node, 0);
//  cerr << "after\n\n\n";

  return;
}

IR *Mutator::deep_copy_with_record(const IR *root, const IR *record) {

  IR *left = NULL, *right = NULL, *copy_res;

  if (root->left_)
    left = deep_copy_with_record(root->left_, record);
  if (root->right_)
    right = deep_copy_with_record(root->right_, record);

  if (root->op_ != NULL)
    copy_res =
        new IR(root->type_,
               OP3(root->op_->prefix_, root->op_->middle_, root->op_->suffix_),
               left, right, root->f_val_, root->str_val_, root->mutated_times_);
  else
    copy_res = new IR(root->type_, NULL, left, right, root->f_val_,
                      root->str_val_, root->mutated_times_);

  copy_res->id_type_ = root->id_type_;

  if (root == record && record != NULL) {
    this->record_ = copy_res;
  }

  return copy_res;
}

bool Mutator::check_node_num(IR *root, unsigned int limit) {

  auto v_statements = extract_statement(root);
  bool is_good = true;

  for (auto stmt : v_statements) {
    // cerr << "For current query stmt: " << root->to_string() << endl;
    // cerr << calc_node(stmt) << endl;
    if (calc_node(stmt) > limit) {
      is_good = false;
      break;
    }
  }

  return is_good;
}

vector<string *> Mutator::mutate_all(vector<IR *> &v_ir_collector,
                                     u64 &total_mutate_gen_num,
                                     u64 &total_mutate_gen_failed) {
  vector<string *> res;
  set<unsigned long> res_hash;
  IR *root = v_ir_collector[v_ir_collector.size() - 1];

  // p_oracle->mark_all_valid_node(v_ir_collector);

  for (auto old_ir : v_ir_collector) {
    total_mutate_gen_num++;
    if (old_ir == root || old_ir->type_ == kInput ||
        old_ir->is_node_struct_fixed) {
      // cerr << "Aboard old_ir because it is root or kStatement, or
      // node_struct_fixed. "
      //      << "v_ir_collector.size(): " << v_ir_collector.size() << ", "
      //      << "In func: Mutator::mutate_all(); \n";
      total_mutate_gen_failed++;
      continue;
    }

    vector<IR *> v_mutated_ir;

    if (old_ir->type_ == kCmdlist) {

      if (old_ir->type_ == kCmdlist) {
        v_mutated_ir = mutate_stmtlist(root);
      } // They are all root(kProgram)!!!

      for (IR *mutated_ir : v_mutated_ir) {

        string tmp = mutated_ir->to_string();

        unsigned tmp_hash = hash(tmp);
        if (res_hash.find(tmp_hash) != res_hash.end()) {
          mutated_ir->deep_drop();
          continue;
        }

        string *new_str = new string(tmp);
        res_hash.insert(tmp_hash);
        res.push_back(new_str);

        mutated_ir->deep_drop();
      }

    } else {
      v_mutated_ir = mutate(old_ir);

      for (auto new_ir : v_mutated_ir) {
        // total_mutate_gen_num++;

        if (!root->swap_node(old_ir, new_ir)) {
          new_ir->deep_drop();
          // total_mutate_gen_failed++;
          continue;
        }

        if (!check_node_num(root, 300)) {
          root->swap_node(new_ir, old_ir);
          new_ir->deep_drop();
          // total_mutate_gen_failed++;
          continue;
        }

        string tmp = root->to_string();
        unsigned tmp_hash = hash(tmp);
        if (res_hash.find(tmp_hash) != res_hash.end()) {
          root->swap_node(new_ir, old_ir);
          new_ir->deep_drop();
          // total_mutate_gen_failed++;
          continue;
        }

        string *new_str = new string(tmp);
        res_hash.insert(tmp_hash);
        res.push_back(new_str);

        root->swap_node(new_ir, old_ir);
        new_ir->deep_drop();
      }
    }
  }

  return res;
}

vector<IR *> Mutator::parse_query_str_get_ir_set(const string &query_str) {

  vector<IR *> ir_set = parser_helper(query_str, &(this->gram_cov_map));

  return ir_set;
}

int Mutator::get_ir_libary_2D_hash_kStatement_size() {
  return this->ir_libary_2D_hash_[kCmd].size();
}

void Mutator::init(string f_testcase, string f_common_string, string pragma) {

  ifstream input_test(f_testcase);
  string line;

  // init lib from multiple sql
  while (getline(input_test, line)) {

    vector<IR *> v_ir = parse_query_str_get_ir_set(line);
    if (v_ir.size() == 0) {
      cerr << "failed to parse: " << line << endl;
      continue;
    }

    string strip_sql = extract_struct(v_ir.back());
    v_ir.back()->deep_drop();
    v_ir.clear();

    v_ir = parse_query_str_get_ir_set(strip_sql);
    if (v_ir.size() <= 0) {
      cerr << "failed to parse after extract_struct:" << endl
           << line << endl
           << strip_sql << endl;
      continue;
    }

    add_all_to_library(v_ir.back());
    v_ir.back()->deep_drop();
  }

  // init utils::m_tables
  vector<string> v_tmp = {"haha1", "haha2", "haha3"};
  v_table_names.insert(v_table_names.end(), v_tmp.begin(), v_tmp.end());
  m_tables["haha1"] = {"fuzzing_column0_1", "fuzzing_column1_1",
                       "fuzzing_column2_1"};
  m_tables["haha2"] = {"fuzzing_column0_2", "fuzzing_column1_2",
                       "fuzzing_column2_2"};
  m_tables["haha3"] = {"fuzzing_column0_3", "fuzzing_column1_3",
                       "fuzzing_column2_3"};

  // init value_libary
  vector<string> value_lib_init = {std::to_string(0),
                                   std::to_string(1),
                                   std::to_string(2),
                                   std::to_string((unsigned long)LONG_MAX),
                                   std::to_string((unsigned long)ULONG_MAX),
                                   std::to_string((unsigned long)CHAR_BIT),
                                   std::to_string((unsigned long)SCHAR_MIN),
                                   std::to_string((unsigned long)SCHAR_MAX),
                                   std::to_string((unsigned long)UCHAR_MAX),
                                   std::to_string((unsigned long)CHAR_MIN),
                                   std::to_string((unsigned long)CHAR_MAX),
                                   std::to_string((unsigned long)MB_LEN_MAX),
                                   std::to_string((unsigned long)SHRT_MIN),
                                   std::to_string((unsigned long)INT_MIN),
                                   std::to_string((unsigned long)INT_MAX),
                                   std::to_string((unsigned long)SCHAR_MIN),
                                   std::to_string((unsigned long)SCHAR_MIN),
                                   std::to_string((unsigned long)UINT_MAX),
                                   std::to_string((unsigned long)FLT_MAX),
                                   std::to_string((unsigned long)DBL_MAX),
                                   std::to_string((unsigned long)LDBL_MAX),
                                   std::to_string((unsigned long)FLT_MIN),
                                   std::to_string((unsigned long)DBL_MIN),
                                   std::to_string((unsigned long)LDBL_MIN),
                                   "10",
                                   "100"};
  value_libary.insert(value_libary.begin(), value_lib_init.begin(),
                      value_lib_init.end());

  string_libary.push_back("x");
  string_libary.push_back("xxx");
  string_libary.push_back("yyy");
  string_libary.push_back("test");
  string_libary.push_back("integrity-check");

  ifstream input_pragma("./pragma");
  string s;
  cout << "start init pragma" << endl;
  while (getline(input_pragma, s)) {
    if (s.empty())
      continue;
    auto pos = s.find('=');
    if (pos == string::npos)
      continue;

    string k = s.substr(0, pos - 1);
    string v = s.substr(pos + 2);
    if (find(cmds_.begin(), cmds_.end(), k) == cmds_.end())
      cmds_.push_back(k);
    m_cmd_value_lib_[k].push_back(v);
  }

  std::ifstream t("./sqlite_func_json.json");
  std::stringstream buffer;
  buffer << t.rdbuf();
  string func_sig_str = buffer.str();
  json func_data = json::parse(func_sig_str);

  all_supported_types  = {
      kTYPEINT,
      kTYPEREAL,
      kTYPETEXT,
      kTYPEJSON
  };

  this->v_func_sig.clear();
  this->v_func_sig_non_window.clear();
  this->v_func_sig_window.clear();
  for (const json& cur_func_json : func_data) {
    FuncSig cur_func_sig = FuncSig(cur_func_json, all_supported_types);
    v_func_sig.push_back(cur_func_sig);
    if (cur_func_sig.get_func_catalog() != Window) {
      v_func_sig_non_window.push_back(cur_func_sig);
    } else {
      v_func_sig_window.push_back(cur_func_sig);
    }
  }

  func_data.clear();

  return;
}

vector<IR *> Mutator::mutate_stmtlist(IR *root) {
  IR *cur_root = nullptr;
  vector<IR *> res_vec;

  if (root == nullptr) {
    return res_vec;
  }

  // For strategy_delete
  cur_root = root->deep_copy();
  p_oracle->ir_wrapper.set_ir_root(cur_root);

  int rov_idx = get_rand_int(p_oracle->ir_wrapper.get_stmt_num());
  p_oracle->ir_wrapper.remove_stmt_at_idx_and_free(rov_idx);
  res_vec.push_back(cur_root);

  // For strategy_replace
  cur_root = root->deep_copy();
  p_oracle->ir_wrapper.set_ir_root(cur_root);

  vector<IR *> ori_stmt_list = p_oracle->ir_wrapper.get_stmt_ir_vec();
  IR *rep_old_ir = ori_stmt_list[get_rand_int(ori_stmt_list.size())];

  /* Get new insert statement. However, do not insert kSelectStatement */
  IR *new_stmt_ir = nullptr;
  while (new_stmt_ir == nullptr) {

    if (!disable_rsg_generator && get_rand_int(2)) {
      // 1/2 chances, use RSG to generate new statement.
      string tmp_stmt_str = rsg_generate_valid(kCmd);
      vector<IR *> v_tmp_ir = this->parse_query_str_get_ir_set(tmp_stmt_str);
      if (v_tmp_ir.size() == 0) {
        new_stmt_ir = nullptr;
        this->rsg_exec_failed_helper();
        continue;
      } else {
        // Parsing succeed.
        IR *tmp_root = v_tmp_ir.back();
        vector<IR *> tmp_stmt_vec =
            p_oracle->ir_wrapper.get_stmt_ir_vec(tmp_root);
        if (tmp_stmt_vec.size() == 0) {
          cerr << "\n\n\nERROR: getting empty tmp_stmt_vec from rsg generated "
                  "string: "
               << tmp_stmt_str << "\n\n\n";
          tmp_root->deep_drop();
          new_stmt_ir = nullptr;
          continue;
        }
        new_stmt_ir = tmp_stmt_vec.front()->deep_copy();
        tmp_root->deep_drop();
        num_rsg_gen++;
      }
    } else {
      // Old normal method to generate new_stmt_ir.
      new_stmt_ir = get_from_libary_with_type(kCmd);
      if (new_stmt_ir == nullptr || new_stmt_ir->left_ == nullptr) {
        cur_root->deep_drop();
        return res_vec;
      }
      if (new_stmt_ir->left_->type_ == kCmdSelect) {
        new_stmt_ir->deep_drop();
        new_stmt_ir = NULL;
        continue;
      }
      IR *new_stmt_ir_tmp = new_stmt_ir->left_->deep_copy();
      new_stmt_ir->deep_drop();
      new_stmt_ir = new_stmt_ir_tmp;
      continue;
    }
  }

  p_oracle->ir_wrapper.set_ir_root(cur_root);
  if (!p_oracle->ir_wrapper.replace_stmt_and_free(rep_old_ir, new_stmt_ir)) {
    new_stmt_ir->deep_drop();
    cur_root->deep_drop();
    return res_vec;
  }
  res_vec.push_back(cur_root);

  // For strategy_insert
  cur_root = root->deep_copy();
  p_oracle->ir_wrapper.set_ir_root(cur_root);

  int insert_pos = get_rand_int(p_oracle->ir_wrapper.get_stmt_num());

  /* Get new insert statement. However, do not insert kSelectStatement */
  new_stmt_ir = nullptr;
  while (new_stmt_ir == nullptr) {

    if (!disable_rsg_generator && get_rand_int(2)) {
      // 1/2 chances, use RSG to generate new statement.
      string tmp_stmt_str = rsg_generate_valid(kCmd);
      vector<IR *> v_tmp_ir = this->parse_query_str_get_ir_set(tmp_stmt_str);
      if (v_tmp_ir.size() == 0) {
        rsg_exec_failed_helper();
        new_stmt_ir = nullptr;
        continue;
      } else {
        // Parsing succeed.
        IR *tmp_root = v_tmp_ir.back();
        vector<IR *> tmp_stmt_vec =
            p_oracle->ir_wrapper.get_stmt_ir_vec(tmp_root);
        if (tmp_stmt_vec.size() == 0) {
          cerr << "\n\n\nERROR: getting empty tmp_stmt_vec from rsg generated "
                  "string: "
               << tmp_stmt_str << "\n\n\n";
          assert(false);
          exit(1);
        }
        new_stmt_ir = tmp_stmt_vec.front()->deep_copy();
        tmp_root->deep_drop();
        num_rsg_gen++;
      }
    } else {
      // Old normal method to generate new_stmt_ir.
      new_stmt_ir = get_from_libary_with_type(kCmd);
      if (new_stmt_ir == nullptr || new_stmt_ir->left_ == nullptr) {
        cur_root->deep_drop();
        return res_vec;
      }
      if (new_stmt_ir->left_->type_ == kCmdSelect) {
        new_stmt_ir->deep_drop();
        new_stmt_ir = NULL;
        continue;
      }
      IR *new_stmt_ir_tmp = new_stmt_ir->left_->deep_copy();
      new_stmt_ir->deep_drop();
      new_stmt_ir = new_stmt_ir_tmp;
      continue;
    }
  }

  p_oracle->ir_wrapper.set_ir_root(cur_root);
  if (!p_oracle->ir_wrapper.append_stmt_after_idx(new_stmt_ir, insert_pos)) {
    new_stmt_ir->deep_drop();
    new_stmt_ir = nullptr;
    cur_root->deep_drop();
    return res_vec;
  }
  res_vec.push_back(cur_root);

  return res_vec;
}

vector<IR *> Mutator::mutate(IR *input) {
  vector<IR *> res;

  // if(!lucky_enough_to_be_mutated(input->mutated_times_)){
  //     return res; // return a empty set if the IR is not mutated
  // }
  IR *tmp_input = NULL;

  tmp_input = strategy_delete(input);
  if (tmp_input != NULL) {
    res.push_back(tmp_input);
  }

  tmp_input = strategy_insert(input);
  if (tmp_input != NULL) {
    res.push_back(tmp_input);
  }

  tmp_input = strategy_replace(input);
  if (tmp_input != NULL) {
    res.push_back(tmp_input);
  }

  // may do some simple filter for res, like removing some duplicated cases

  input->mutated_times_ += res.size();
  for (auto i : res) {
    if (i == NULL)
      continue;
    i->mutated_times_ = input->mutated_times_;
  }
  return res;
}

void Mutator::pre_validate() {
  // Reset components that is local to the one query sequence.
  reset_counter();
  reset_database();
  return;
}

vector<IR *> Mutator::pre_fix_transform(IR *root,
                                        vector<STMT_TYPE> &stmt_type_vec) {

  p_oracle->init_ir_wrapper(root);
  vector<IR *> all_trans_vec;
  vector<IR *> all_statements_vec = p_oracle->ir_wrapper.get_stmt_ir_vec();

  // cerr << "In func: Mutator::pre_fix_transform(IR * root, vector<STMT_TYPE>&
  // stmt_type_vec), we have all_statements_vec size(): "
  //     << all_statements_vec.size() << "\n\n\n";

  for (IR *cur_stmt : all_statements_vec) {
    /* Identify oracle related statements. Ready for transformation. */
    bool is_oracle_select = false, is_oracle_normal = false;
    if (p_oracle->is_oracle_normal_stmt(cur_stmt)) {
      is_oracle_normal = true;
      stmt_type_vec.push_back(ORACLE_NORMAL);
    } else if (p_oracle->is_oracle_select_stmt(cur_stmt)) {
      is_oracle_select = true;
      stmt_type_vec.push_back(ORACLE_SELECT);
    } else {
      stmt_type_vec.push_back(NOT_ORACLE);
    }

    /* Apply pre_fix_transformation functions. */
    IR *trans_IR = nullptr;
    if (is_oracle_normal) {
      trans_IR =
          p_oracle->pre_fix_transform_normal_stmt(cur_stmt); // Deep_copied
    } else if (is_oracle_select) {
      trans_IR =
          p_oracle->pre_fix_transform_select_stmt(cur_stmt); // Deep_copied
    }
    /* If no pre_fix_transformation is needed, directly use the original
     * cur_root. */
    if (trans_IR == nullptr) {
      trans_IR = cur_stmt->deep_copy();
    }
    all_trans_vec.push_back(trans_IR);
  }

  return all_trans_vec;
}

vector<vector<vector<IR *>>>
Mutator::post_fix_transform(vector<IR *> &all_pre_trans_vec,
                            vector<STMT_TYPE> &stmt_type_vec) {
  int total_run_count = p_oracle->get_mul_run_num();
  vector<vector<vector<IR *>>> all_trans_vec_all_run;
  for (int run_count = 0; run_count < total_run_count; run_count++) {
    all_trans_vec_all_run.push_back(this->post_fix_transform(
        all_pre_trans_vec, stmt_type_vec, run_count)); // All deep_copied.
  }
  return all_trans_vec_all_run;
}

vector<vector<IR *>>
Mutator::post_fix_transform(vector<IR *> &all_pre_trans_vec,
                            vector<STMT_TYPE> &stmt_type_vec, int run_count) {
  // Apply post_fix_transform functions.
  vector<vector<IR *>> all_post_trans_vec;
  vector<int> v_stmt_to_rov;
  for (int i = 0; i < all_pre_trans_vec.size();
       i++) { // Loop through across statements.
    IR *cur_pre_trans_ir = all_pre_trans_vec[i];
    vector<IR *> post_trans_stmt_vec;
    assert(cur_pre_trans_ir != nullptr);

    bool is_oracle_normal = false, is_oracle_select = false;
    if (stmt_type_vec[i] == ORACLE_SELECT) {
      is_oracle_select = true;
    } else if (stmt_type_vec[i] == ORACLE_NORMAL) {
      is_oracle_normal = true;
    }

    if (is_oracle_normal) {
      // cerr << "Debug: For cur_pre_trans_ir: " <<
      // cur_pre_trans_ir->to_string() << ", oracle_normal. \n\n\n";
      post_trans_stmt_vec = p_oracle->post_fix_transform_normal_stmt(
          cur_pre_trans_ir, run_count); // All deep_copied
    } else if (is_oracle_select) {
      // cerr << "Debug: For cur_pre_trans_ir: " <<
      // cur_pre_trans_ir->to_string() << ", oracle_SELECT. \n\n\n";
      post_trans_stmt_vec = p_oracle->post_fix_transform_select_stmt(
          cur_pre_trans_ir, run_count); // All deep_copied
    } else {
      // cerr << "Debug: For cur_pre_trans_ir: " <<
      // cur_pre_trans_ir->to_string() << ", NOT. \n\n\n";
      post_trans_stmt_vec.push_back(cur_pre_trans_ir->deep_copy());
    }

    // if (post_trans_stmt_vec.size() == 0){
    //   post_trans_stmt_vec.push_back(cur_pre_trans_ir->deep_copy());
    //   post_trans_stmt_vec.push_back(cur_pre_trans_ir->deep_copy());
    //   // continue;
    // }
    if (post_trans_stmt_vec.size() > 0) {
      all_post_trans_vec.push_back(post_trans_stmt_vec);
    } else {
      v_stmt_to_rov.push_back(i);
    }
  }

  vector<STMT_TYPE> new_stmt_type_vec;
  for (int i = 0; i < stmt_type_vec.size(); i++) {
    if (find(v_stmt_to_rov.begin(), v_stmt_to_rov.end(), i) !=
        v_stmt_to_rov.end()) {
      continue;
    }
    new_stmt_type_vec.push_back(stmt_type_vec[i]);
  }
  stmt_type_vec = new_stmt_type_vec;

  return all_post_trans_vec;
}

IR* Mutator::gen_rand_expr_node_no_exprfunc() {

  for (int i = 0; i < 100; i++) {
    string tmp_stmt = "SELECT " + rsg_generate("expr") + ";";
    vector<IR *> ir_vec = this->parse_query_str_get_ir_set(tmp_stmt);
    if (ir_vec.empty()) {
#ifdef DEBUG
      cerr << "\n\n\n"
           << type << ", getting tmp_query_str: " << tmp_query_str << "\n";
      cerr << "Rejected. \n\n\n";
#endif
      continue;
    }
    vector<IR*> v_res_node = p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(ir_vec.back(), kExprFunc, false);
    if (!v_res_node.empty()) {
      // Do not use kExprFunc.
      ir_vec.back()->deep_drop();
      continue;
    }
    v_res_node = p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(ir_vec.back(), kExpr, false);
    if (v_res_node.size() > 0) {
      IR* res_node = v_res_node.front()->deep_copy();
      ir_vec.back()->deep_drop();
      return res_node;
    } else {
      ir_vec.back()->deep_drop();
      continue;
    }
  }
  IR* ret_node = new IR(kIdentifier, string("v0"), id_column_name);
  return ret_node;
}


IR* Mutator::gen_rand_filter_over_clause() {

  // Enforce the OVER clause.
  for (int i = 0; i < 100; i++) {
    string tmp_stmt = "SELECT SUM(v0) ";

    // Optional FILTER clause
    if (get_rand_int(2)) {
      tmp_stmt += " FILTER ( WHERE " + rsg_generate("expr") + ") ";
    }

    // Required OVER clause.
    tmp_stmt += "OVER (";

    if (get_rand_int(2)) {
      tmp_stmt += "PARTITION BY v0";
    } else {
      tmp_stmt += "ORDER BY v0";
    }

    tmp_stmt += ") FROM v0; ";

    vector<IR *> ir_vec = this->parse_query_str_get_ir_set(tmp_stmt);
//    cerr << "\n\n\n"
//         << "Getting filter_over query str: " << tmp_stmt << "\n\n\n";
    if (ir_vec.size() == 0) {
//      cerr << "Rejected. \n\n\n";
      continue;
    }
    vector<IR*> v_res_node = p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(ir_vec.back(), kFilterOver, false);
    if (v_res_node.size() > 0) {
      IR* res_node = v_res_node.front()->deep_copy();
      ir_vec.back()->deep_drop();
//      cerr << "return: \n" << res_node->to_string() << "\n\n\n";
      return res_node;
    } else {
      ir_vec.back()->deep_drop();
//      cerr << "Cannot find kFilterOver \n\n\n";
      continue;
    }
  }

  return nullptr;
}

IR* Mutator::instan_rand_func_expr(DATATYPE req_ret_type, bool is_avoid_window) {
  // Ignore the req_ret_type for now.

  FuncSig cur_func_sig;
  if (is_avoid_window) {
    cur_func_sig = vector_rand_ele(this->v_func_sig_non_window);
  } else {
    cur_func_sig = vector_rand_ele(this->v_func_sig);
  }
  // Get all the arg types
  vector<DataType> v_arg_types = cur_func_sig.get_arg_types();

  IR* new_func_name_ir = new IR(kIdentifier, string(cur_func_sig.get_func_name()), id_function_name);
  new_func_name_ir->is_node_struct_fixed = true;
  IR* new_func_expr_ir = new IR(kUnknown, OP3("", "(", ")"), new_func_name_ir, nullptr);
  int idx = 0;
  IR* tmp_arg_node = nullptr;
  for (DataType cur_arg_type : v_arg_types) {
    IR* arg_expr_node = nullptr;
    switch(get_rand_int(14)) {
    case 0:
    case 1:
    case 2:
    case 3:
      arg_expr_node = new IR(kIdentifier, string("v0"), id_column_name);
      arg_expr_node->is_node_struct_fixed = true;
      break;
    case 4:
    case 5:
    case 6:
      if (
          cur_arg_type.get_data_type_enum() == kTYPEANY ||
          cur_arg_type.get_data_type_enum() == kTYPEUNDEFINE ||
          cur_arg_type.get_data_type_enum() == kTYPEUNKNOWN
          ) {
        DATATYPE rand_any_type = cur_arg_type.gen_rand_any_type(
            cur_func_sig.get_supported_types());
        cur_arg_type.set_data_type(rand_any_type);
      }
      arg_expr_node = new IR(kStringLiteral, string(cur_arg_type.mutate_type_entry()), id_whatever);
      arg_expr_node->is_node_struct_fixed = true;
      break;
    case 7:
    case 8:
    case 9:
    case 10:
      arg_expr_node = this->gen_rand_expr_node_no_exprfunc();
      break;
    case 11:
    case 12:
    case 13:
      // Avoid using window
      arg_expr_node = this->instan_rand_func_expr(kTYPEUNKNOWN, true);
      break;
    }

    // Finished the arg_expr_node, fill in to the func expression.
    if (tmp_arg_node == nullptr) {
      tmp_arg_node = new IR(kUnknown, OP0(), arg_expr_node, nullptr);
    } else {
      tmp_arg_node = new IR(kUnknown, OP3("", ", ", ""), tmp_arg_node, arg_expr_node);
    }
  }
  new_func_expr_ir->update_right(tmp_arg_node);

  if (cur_func_sig.get_func_catalog() == Window) {
    IR* filter_over_clause = this->gen_rand_filter_over_clause();
    new_func_expr_ir = new IR(kUnknown, OP3("", "", ""), new_func_expr_ir, filter_over_clause);
  }

  new_func_expr_ir->type_ = kExprFunc;

  return new_func_expr_ir;
}

// Recursive function to generate and test function expressions.
void Mutator::instan_rand_func_expr_helper(IR* cur_trans_stmt, bool is_avoid_window) {
  /* Handle the function expression first. */
  vector<IR*> v_func_expr_node = p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(cur_trans_stmt, kExprFunc, false, true);
  vector<int> ignore_set;
  for (int i = 0; i < v_func_expr_node.size(); i++) {
    for (int j = 0; j < v_func_expr_node.size(); j++) {
      if (i == j) {continue;}
      else if (p_oracle->ir_wrapper.is_ir_in(v_func_expr_node[i], v_func_expr_node[j])) {
        ignore_set.push_back(i);
      }
    }
  }
  for (int i = 0; i < v_func_expr_node.size(); i++) {
    if (find(ignore_set.begin(), ignore_set.end(), i) == ignore_set.end()) {
      IR* new_func_expr = instan_rand_func_expr(kTYPEUNKNOWN, is_avoid_window);
      cur_trans_stmt->swap_node(v_func_expr_node[i], new_func_expr);
      v_func_expr_node[i]->deep_drop();
      if(new_func_expr->left_) {
        this->instan_rand_func_expr_helper(new_func_expr->left_, true);
      } else if (new_func_expr->right_) {
        this->instan_rand_func_expr_helper(new_func_expr->right_, true);
      }
    }
  }

  return;
}

/* Handle and fix one single query statement. */
bool Mutator::validate(IR *cur_trans_stmt, bool is_rewrite_func, bool is_debug_info) {

  if (cur_trans_stmt == nullptr) {
    return false;
  }
  bool res = true;

  if (is_rewrite_func) {
    instan_rand_func_expr_helper(cur_trans_stmt);
  }

  /* Fill in concret values into the query. */
  vector<vector<IR *>> ordered_all_subquery_ir;

  fix_preprocessing(cur_trans_stmt, ordered_all_subquery_ir);

  // Debug
  // cerr << "After Mutator::fix_preprocessing, we have
  // ordered_all_subquery_ir.size(): " << ordered_all_subquery_ir.size() <<
  // "\n\n\n";

  res =
      fix_dependency(cur_trans_stmt, ordered_all_subquery_ir, is_debug_info) &&
      res;
  fix(cur_trans_stmt);

  this->resolve_drop_statement(cur_trans_stmt, is_debug_info);
  this->resolve_alter_statement(cur_trans_stmt, is_debug_info);

  return res;
}

bool Mutator::finalize_transform(IR *root,
                                 vector<vector<IR *>> all_post_trans_vec) {
  if (root == NULL) {
    return false;
  }
  p_oracle->init_ir_wrapper(root);
  for (vector<IR *> post_trans_vec : all_post_trans_vec) {
    /* Append the transformed statements into the IR tree. */
    int idx_offset = 0; // Consider the already inserted transformed statements.
    for (int i = 1; i < post_trans_vec.size();
         i++) { // Start from idx=1, the first element is the original stmt.
      int cur_trans_idx = p_oracle->ir_wrapper.get_stmt_idx(post_trans_vec[0]);
      if (cur_trans_idx == -1) {
        cerr << "Error: cannot find the current statement in the IR tree! "
                "Abort finalize_transform() function. \n";
        // Error.
        return false;
      }
      p_oracle->ir_wrapper.append_stmt_after_idx(post_trans_vec[i],
                                                 cur_trans_idx + idx_offset);
      idx_offset++;
    }
  }
  return true;
}

pair<string, string>
Mutator::ir_to_string(IR *root, vector<vector<IR *>> all_post_trans_vec,
                      const vector<STMT_TYPE> &stmt_type_vec) {
  // Final step, IR_to_string function.
  string output_str_mark, output_str_no_mark;
  for (int i = 0; i < all_post_trans_vec.size();
       i++) { // Loop between different statements.
    vector<IR *> post_trans_vec = all_post_trans_vec[i];
    bool is_oracle_select = false;
    if (stmt_type_vec[i] == ORACLE_SELECT) {
      is_oracle_select = true;
    }
    int count = 0;
    int trans_count = 0;
    for (IR *cur_trans_stmt :
         post_trans_vec) { // Loop between different transformations.
      string tmp = cur_trans_stmt->to_string();
      if (is_oracle_select) {
        output_str_mark += "SELECT 'BEGIN VERI " + to_string(count) + "'; \n";
        output_str_mark += tmp + "; \n";
        output_str_mark += "SELECT 'END VERI " + to_string(count) + "'; \n";
        if (trans_count == 0) {
          output_str_no_mark += tmp + "; \n";
        }
        count++;
      } else {
        output_str_mark += tmp + "; \n";
        if (trans_count == 0) {
          output_str_no_mark += tmp + "; \n";
        }
      }
      trans_count++;
    }
  }
  pair<string, string> output_str_pair =
      make_pair(output_str_mark, output_str_no_mark);
  return output_str_pair;
}

// find tree node whose identifier type can be handled
//
// NOTE: identifier type is different from IR type
//
static void collect_ir(IR *root, set<IDTYPE> &type_to_fix,
                       vector<IR *> &ir_to_fix) {
  auto idtype = root->id_type_;

  if (root->left_) {
    collect_ir(root->left_, type_to_fix, ir_to_fix);
  }

  if (type_to_fix.find(idtype) != type_to_fix.end()) {
    ir_to_fix.push_back(root);
  }

  if (root->right_) {
    collect_ir(root->right_, type_to_fix, ir_to_fix);
  }
}

static vector<IR *> search_mapped_ir_in_stmt(IR *ir, IDTYPE idtype) {
  // Find the root for the current statement.
  IR *cur_ir = ir;
  while (cur_ir->parent_ != nullptr) {
    if (cur_ir->type_ == kCmd) {
      break;
    }
    cur_ir = cur_ir->parent_;
  }

  deque<IR *> to_search = {cur_ir};
  vector<IR *> res;

  while (to_search.empty() != true) {
    auto node = to_search.front();
    to_search.pop_front();

    if (node->id_type_ == idtype) {
      res.push_back(node);
    }

    if (node->left_)
      to_search.push_back(node->left_);
    if (node->right_)
      to_search.push_back(node->right_);
  }

  return res;
}

// propagate relationship between subqueries. The logic is correct
//
// graph.second relies on graph.first
// crossmap.first relies on crossmap.second
//
// so we should propagate the dependency via
// graph.second -> graph.first = crossmap.first -> crossmap.second
//
// This function only consult cross_map, thus only care about
// [id_top_table_name] -> [id_create_table_name] across statements.
void cross_stmt_map(map<IR *, set<IR *>> &graph,
                    map<IR *, set<IR *>> &cross_graph, vector<IR *> &ir_to_fix,
                    map<IDTYPE, IDTYPE> &cross_map) {
  for (auto m : cross_map) {
    vector<IR *> value;
    vector<IR *> key;

    // Why searching for graph/cross_graph for saved matched type?
    for (auto &k :
         cross_graph) { // graph is local, thus is always empty. Only
                        // cross_graph save all the cross statements' IR.
      if (k.first->id_type_ == m.first) {
        key.push_back(k.first);
      }
    }

    for (auto &k : ir_to_fix) {
      if (k->id_type_ == m.second) {
        value.push_back(k);
      }
    }

    if (key.empty())
      return;
    for (auto val : value) {
      graph[key[get_rand_int(key.size())]].insert(val);
      cross_graph[key[get_rand_int(key.size())]].insert(val);
    }
  }
}

// randomly build connection between top_table_name and table_name
//
// top_table_name does not rely on others, while table_name relies on some
// top_table_name
//
// Local to one single statement.
void toptable_map(map<IR *, set<IR *>> &graph, vector<IR *> &ir_to_fix,
                  vector<IR *> &toptable) {
  vector<IR *> tablename;
  for (auto ir : ir_to_fix) {
    if (ir->id_type_ == id_table_name) {
      tablename.push_back(ir);
    } else if (ir->id_type_ == id_top_table_name) {
      toptable.push_back(ir);
    }
  }
  if (toptable.empty())
    return;
  for (auto k : tablename) {
    auto r = get_rand_int(toptable.size());
    graph[toptable[r]].insert(k);
  }
}

string Mutator::remove_node_from_tree_by_index(string oracle_query,
                                               int remove_index) {

  vector<IR *> tree = parse_query_str_get_ir_set(oracle_query);
  IR *root = tree[tree.size() - 1];
  deque<IR *> bfs = {root};
  string result = "";

  int current_index = 0;
  while (bfs.empty() != true) {
    auto node = bfs.front();
    bfs.pop_front();

    if (current_index == remove_index) {
      root->detach_node(node);
      result = root->to_string();
      root->deep_drop();
      return result;
    }
    current_index++;

    if (node->left_)
      bfs.push_back(node->left_);

    if (node->right_)
      bfs.push_back(node->right_);
  }

  return result;
}

set<string> Mutator::get_minimize_string_from_tree(string oracle_query) {
  set<string> res;
  vector<IR *> irtree = parse_query_str_get_ir_set(oracle_query);

  for (int i = 0; i < irtree.size(); ++i) {
    string new_string = remove_node_from_tree_by_index(oracle_query, i);
    // vector<IR *> irset = parse_query_str_get_ir_set(new_string);
    // if (irset.size() == 0)
    //   continue ;

    res.insert(new_string);
    // cout << "new string " << i << " : " << new_string.c_str() << endl;
  }
  return res;
}

vector<IR *> Mutator::extract_statement(IR *root) {
  vector<IR *> res;
  deque<IR *> bfs = {root};

  while (bfs.empty() != true) {
    auto node = bfs.front();
    bfs.pop_front();

    if (node->type_ == kCmd)
      res.push_back(node);
    if (node->left_)
      bfs.push_back(node->left_);
    if (node->right_)
      bfs.push_back(node->right_);
  }

  return res;
}

// find all subqueries (SELECT statement)
//
// find all SelectCore subtree, and save them in the returned vector
// save the mapping from the subtree address to subtree into 2nd arg
//
vector<IR *> Mutator::cut_subquery(IR *cur_stmt, TmpRecord &m_save) {

  vector<IR *> res;
  list<IR *> res_list;
  vector<IR *> v_statements{cur_stmt};

  for (auto &stmt : v_statements) {
    deque<IR *> q_bfs = {stmt};
    res_list.push_back(stmt);

    while (!q_bfs.empty()) {
      auto cur = q_bfs.front();
      q_bfs.pop_front();

      if (cur->left_) {
        q_bfs.push_back(cur->left_);
        if (cur->left_->type_ == kSelect) {
          if (p_oracle->ir_wrapper.is_ir_in(cur->left_, kWqitem)) {
            res_list.push_front(cur->left_);
          } else {
            res_list.push_back(cur->left_);
          }
          m_save[cur] = make_pair(0, cur->left_);
          cur->detach_node(cur->left_);
        }
      }

      if (cur->right_) {
        q_bfs.push_back(cur->right_);
        if (cur->right_->type_ == kSelect) {
          if (p_oracle->ir_wrapper.is_ir_in(cur->left_, kWqitem)) {
            res_list.push_front(cur->right_);
          } else {
            res_list.push_back(cur->right_);
          }
          m_save[cur] = make_pair(1, cur->right_);
          cur->detach_node(cur->right_);
        }
      }
    }
  }

  res.clear();
  res.reserve(res_list.size());
  for (auto & iter : res_list) {
    res.push_back(iter);
  }

//  cerr << "Getting res.size()" << res.size() << "\n\n\n";

  return res;
}

// Recover the subqueries, which were disconnected before.
bool Mutator::add_back(TmpRecord &m_save) {

  for (auto &i : m_save) {

    IR *parent = i.first;
    int is_right = i.second.first;
    IR *child = i.second.second;

    if (is_right)
      parent->update_right(child);
    else
      parent->update_left(child);
  }

  return true;
}

// build the dependency graph between names, for example, the column name
// should belong to one column of one already created table. The dependency
// is denfined in the "relationmap" global variable
//
// The result is a map, where the value is a set of IRs, which are dependents
// of the key
void Mutator::fix_preprocessing(IR *root,
                                vector<vector<IR *>> &ordered_all_subquery_ir) {

  map<IR *, set<IR *>> graph;
  TmpRecord m_save;
  set<IDTYPE> type_to_fix;

  type_to_fix.insert(id_top_table_name);
  type_to_fix.insert(id_top_column_name);
  type_to_fix.insert(id_table_alias_name);
  type_to_fix.insert(id_column_name);
  type_to_fix.insert(id_table_name);
  type_to_fix.insert(id_index_name);
  type_to_fix.insert(id_create_table_name);
  type_to_fix.insert(id_create_column_name);
//  type_to_fix.insert(id_pragma_name);
//  type_to_fix.insert(id_pragma_value);
  type_to_fix.insert(id_create_index_name);
  type_to_fix.insert(id_create_table_name_with_tmp);
  type_to_fix.insert(id_create_column_name_with_tmp);
  type_to_fix.insert(id_trigger_name);
  type_to_fix.insert(id_collation_name);
  type_to_fix.insert(id_view_name);
  type_to_fix.insert(id_create_view_name);
  type_to_fix.insert(id_create_window_name);
  type_to_fix.insert(id_window_name);
  type_to_fix.insert(id_vtab_module_name);

  vector<IR *> subqueries = cut_subquery(root, m_save);

//  cerr << "Getting root: " << get_string_by_ir_type(root->type_) << "\n\n\n";
//   cerr << "\n\nIn Mutator::fix_preprocessing, we have subqueries.size(): " <<
//   subqueries.size() << "\nBEGIN:";
//   for (IR* cur_q : subqueries) {
//    cerr << cur_q->to_string() << "\n";
//   }
//   cerr << "END\n\n\n";

  for (IR *subquery : subqueries) {
    vector<IR *> ir_to_fix;
    collect_ir(subquery, type_to_fix, ir_to_fix);
    ordered_all_subquery_ir.push_back(ir_to_fix);
  }
  add_back(m_save);
  return;
}

IR *Mutator::strategy_delete(IR *cur) {
  assert(cur);
  MUTATESTART

  DOLEFT
  res = cur->deep_copy();
  if (res->left_ != NULL)
    res->left_->deep_drop();
  res->update_left(NULL);

  DORIGHT
  res = cur->deep_copy();
  if (res->right_ != NULL)
    res->right_->deep_drop();
  res->update_right(NULL);

  DOBOTH
  res = cur->deep_copy();
  if (res->left_ != NULL)
    res->left_->deep_drop();
  if (res->right_ != NULL)
    res->right_->deep_drop();
  res->update_left(NULL);
  res->update_right(NULL);

  MUTATEEND
}

IR *Mutator::strategy_insert(IR *cur) {

  assert(cur);

  if (cur->type_ == kCmdlist) {
    auto new_right = get_from_libary_with_type(kEcmd);
    if (new_right != NULL) {
      auto res = cur->deep_copy();
      auto new_res = new IR(kCmdlist, OPMID(";"), res, new_right);
      return new_res;
    }
  }

  if (cur->right_ == NULL && cur->left_ != NULL) {
    auto left_type = cur->left_->type_;
    auto new_right = get_from_libary_with_left_type(left_type);
    if (new_right != NULL) {
      auto res = cur->deep_copy();
      res->update_right(new_right);
      return res;
    }
  }

  else if (cur->right_ != NULL && cur->left_ == NULL) {
    auto right_type = cur->right_->type_;
    auto new_left = get_from_libary_with_right_type(right_type);
    if (new_left != NULL) {
      auto res = cur->deep_copy();
      res->update_left(new_left);
      return res;
    }
  }

  return get_from_libary_with_type(cur->type_);
}

IR *Mutator::strategy_replace(IR *cur) {
  assert(cur);

  MUTATESTART

  DOLEFT
  res = cur->deep_copy();
  if (res->left_ == NULL) {
    res->deep_drop();
    return NULL;
  }

  auto new_node = get_from_libary_with_type(res->left_->type_);

  if (new_node != NULL) {
    if (res->left_ != NULL) {
      new_node->id_type_ = res->left_->id_type_;
    }
  } else { // new_node == NULL
    res->deep_drop();
    return NULL;
  }
  if (res->left_ != NULL)
    res->left_->deep_drop();
  res->update_left(new_node);

  DORIGHT
  res = cur->deep_copy();
  if (res->right_ == NULL) {
    res->deep_drop();
    return NULL;
  }

  auto new_node = get_from_libary_with_type(res->right_->type_);
  if (new_node != NULL) {
    if (res->right_ != NULL) {
      new_node->id_type_ = res->right_->id_type_;
    }
  } else { // new_node == NULL
    res->deep_drop();
    return NULL;
  }
  if (res->right_ != NULL)
    res->right_->deep_drop();
  res->update_right(new_node);

  DOBOTH
  res = cur->deep_copy();
  if (res->left_ == NULL || res->right_ == NULL) {
    res->deep_drop();
    return NULL;
  }

  auto new_left = get_from_libary_with_type(res->left_->type_);
  auto new_right = get_from_libary_with_type(res->right_->type_);

  if (new_left != NULL) {
    if (res->left_ != NULL) {
      new_left->id_type_ = res->left_->id_type_;
    }
  } else { // new_left == NULL
    if (new_right != NULL) {
      new_right->deep_drop();
    }
    res->deep_drop();
    return NULL;
  }

  if (new_right != NULL) {
    if (res->right_ != NULL) {
      new_right->id_type_ = res->right_->id_type_;
    }
  } else { // new_right == NULL
    if (new_left != NULL) {
      new_left->deep_drop();
    }
    res->deep_drop();
    return NULL;
  }

  if (res->left_)
    res->left_->deep_drop();
  if (res->right_)
    res->right_->deep_drop();
  res->update_left(new_left);
  res->update_right(new_right);

  MUTATEEND

  return res;
}

bool Mutator::lucky_enough_to_be_mutated(unsigned int mutated_times) {
  if (get_rand_int(mutated_times + 1) < LUCKY_NUMBER) {
    return true;
  }
  return false;
}

IR *Mutator::get_from_libary_with_type(IRTYPE type_) {
  /* Given a data type, return a randomly selected prevously seen IR node that
     matched the given type. If nothing has found, return an empty
     kStringLiteral.
  */

  vector<IR *> current_ir_set;
  IR *current_ir_root;
  vector<pair<string *, int>> &all_matching_node = real_ir_set[type_];
  IR *return_matched_ir_node = NULL;

  if (all_matching_node.size() > 0) {
    /* Pick a random matching node from the library. */
    int random_idx = get_rand_int(all_matching_node.size());
    std::pair<string *, int> &selected_matched_node =
        all_matching_node[random_idx];
    string *p_current_query_str = selected_matched_node.first;
    int unique_node_id = selected_matched_node.second;

    /* Reconstruct the IR tree. */
    current_ir_set = parse_query_str_get_ir_set(*p_current_query_str);
    if (current_ir_set.size() <= 0) {
      // cerr << "Error: with_type_ Parsing the saved string failed. str: " <<
      // *p_current_query_str << " !!!" << "\n\n\n";
      return NULL;
    }
    current_ir_root = current_ir_set.back();

    /* Retrive the required node, deep copy it, clean up the IR tree and return.
     */
    IR *matched_ir_node = current_ir_set[unique_node_id];
    if (matched_ir_node != NULL) {
      if (matched_ir_node->type_ != type_) {
        current_ir_root->deep_drop();
        // cerr << "Error: with_type_ Column type mismatched!!!" << "\n\n\n";
        return NULL;
      }
      // return_matched_ir_node = matched_ir_node->deep_copy();
      return_matched_ir_node = matched_ir_node;
      current_ir_root->detach_node(return_matched_ir_node);
    }

    current_ir_root->deep_drop();

    if (return_matched_ir_node != NULL) {
      // cerr << "\n\n\nSuccessfuly with_type: with string: " <<
      // return_matched_ir_node->to_string() << endl; cerr << "Retunning
      // with_type_ ir_type: " << get_string_by_ir_type(type_) << " with node: "
      // << return_matched_ir_node->to_string() << "\n\n\n";
      return return_matched_ir_node;
    }
  }

  return NULL;
}

IR *Mutator::get_from_libary_with_left_type(IRTYPE type_) {
  /* Given a left_ type, return a randomly selected prevously seen right_ node
     that share the same parent. If nothing has found, return NULL.
  */

  vector<IR *> current_ir_set;
  IR *current_ir_root;
  vector<pair<string *, int>> &all_matching_node = left_lib_set[type_];
  IR *return_matched_ir_node = NULL;

  if (all_matching_node.size() > 0) {
    /* Pick a random matching node from the library. */
    int random_idx = get_rand_int(all_matching_node.size());
    std::pair<string *, int> &selected_matched_node =
        all_matching_node[random_idx];
    string *p_current_query_str = selected_matched_node.first;
    int unique_node_id = selected_matched_node.second;

    /* Reconstruct the IR tree. */
    current_ir_set = parse_query_str_get_ir_set(*p_current_query_str);
    if (current_ir_set.size() <= 0) {
      // cerr << "Error: Parsing the saved string failed. str: " <<
      // *p_current_query_str << " !!!" << "\n\n\n";
      return NULL;
    }
    current_ir_root = current_ir_set.back();

    /* Retrive the required node, deep copy it, clean up the IR tree and return.
     */
    IR *matched_ir_node = current_ir_set[unique_node_id];
    if (matched_ir_node != NULL) {
      if (matched_ir_node->left_->type_ != type_) {
        current_ir_root->deep_drop();
        // cerr << "Error: Column type mismatched!!!" << "\n\n\n";
        return NULL;
      }
      // return_matched_ir_node = matched_ir_node->right_->deep_copy();;  // Not
      // returnning the matched_ir_node itself, but its right_ child node!
      return_matched_ir_node = matched_ir_node->right_;
      current_ir_root->detach_node(return_matched_ir_node);
    }

    current_ir_root->deep_drop();

    if (return_matched_ir_node != NULL) {
      // cerr << "Retunning ir_type: " << get_string_by_ir_type(type_) << " with
      // node: " << return_matched_ir_node->to_string() << "\n\n\n";
      return return_matched_ir_node;
    }
  } else {
    // cerr << "Error: Cannot find saved lib with type_ " <<
    // get_string_by_ir_type(type_) << "\n\n\n";
  }

  return NULL;
}

IR *Mutator::get_from_libary_with_right_type(IRTYPE type_) {
  /* Given a right_ type, return a randomly selected prevously seen left_ node
     that share the same parent. If nothing has found, return NULL.
  */

  vector<IR *> current_ir_set;
  IR *current_ir_root;
  vector<pair<string *, int>> &all_matching_node = right_lib_set[type_];
  IR *return_matched_ir_node = NULL;

  if (all_matching_node.size() > 0) {
    /* Pick a random matching node from the library. */
    std::pair<string *, int> &selected_matched_node =
        all_matching_node[get_rand_int(all_matching_node.size())];
    string *p_current_query_str = selected_matched_node.first;
    int unique_node_id = selected_matched_node.second;

    /* Reconstruct the IR tree. */
    current_ir_set = parse_query_str_get_ir_set(*p_current_query_str);
    if (current_ir_set.size() <= 0) {
      // cerr << "Error: Parsing the saved string failed. str: " <<
      // *p_current_query_str << " !!!" << "\n\n\n";
      return NULL;
    }
    current_ir_root = current_ir_set.back();

    /* Retrive the required node, deep copy it, clean up the IR tree and return.
     */
    IR *matched_ir_node = current_ir_set[unique_node_id];
    if (matched_ir_node != NULL) {
      if (matched_ir_node->right_->type_ != type_) {
        current_ir_root->deep_drop();
        // cerr << "Error: Column type mismatched!!!" << "\n\n\n";
        return NULL;
      }
      // return_matched_ir_node = matched_ir_node->left_->deep_copy();  // Not
      // returnning the matched_ir_node itself, but its left_ child node!
      return_matched_ir_node = matched_ir_node->left_;
      current_ir_root->detach_node(return_matched_ir_node);
    }

    current_ir_root->deep_drop();

    if (return_matched_ir_node != NULL) {
      // cerr << "Retunning ir_type: " << get_string_by_ir_type(type_) << " with
      // node: " << return_matched_ir_node->to_string() << "\n\n\n";
      return return_matched_ir_node;
    }
  } else {
    // cerr << "Error: Cannot find saved lib with type_ " <<
    // get_string_by_ir_type(type_) << "\n\n\n";
  }

  return NULL;
}

unsigned long Mutator::get_library_size() {
  unsigned long res = 0;

  for (auto &i : real_ir_set) {
    res += 1;
  }

  for (auto &i : left_lib_set) {
    res += 1;
  }

  for (auto &i : right_lib_set) {
    res += 1;
  }

  return res;
}

bool Mutator::is_stripped_str_in_lib(string stripped_str) {
  stripped_str = extract_struct(stripped_str);
  unsigned long str_hash = hash(stripped_str);
  if (stripped_string_hash_.find(str_hash) != stripped_string_hash_.end())
    return true;
  stripped_string_hash_.insert(str_hash);
  return false;
}

static bool isEmpty(string &str) {

  for (char &c : str)
    if (!isspace(c) && c != '\n' && c != '\0')
      return false;

  return true;
}

/* add_to_library supports only one stmt at a time,
 * add_all_to_library is responsible to split the
 * the current IR tree into single query stmts.
 * This function is not responsible to free the input IR tree.
 */
void Mutator::add_all_to_library(IR *ir, const ALL_COMP_RES &all_comp_res) {

  add_all_to_library(ir->to_string(), all_comp_res);
}

/*  Save an interesting query stmt into the mutator library.
 *
 *   The uniq_id_in_tree_ should be, more idealy, being setup and kept unchanged
 * once an IR tree has been reconstructed. However, there are some difficulties
 * there. For example, how to keep the uniqueness and the fix order of the
 * unique_id_in_tree_ for each node in mutations. Therefore, setting and
 * checking the uniq_id_in_tree_ variable in every nodes of an IR tree are only
 * done when necessary by calling this funcion and
 * get_from_library_with_[_,left,right]_type. We ignore this unique_id_in_tree_
 * in other operations of the IR nodes. The unique_id_in_tree_ is setup based on
 * the order of the ir_set vector, returned from Program*->translate(ir_set).
 *
 */

void Mutator::add_all_to_library(string whole_query_str,
                                 const ALL_COMP_RES &all_comp_res) {

  if (isEmpty(whole_query_str))
    return;

  int i = 0; // For counting oracle valid stmt IDs.

  vector<string> queries_vector = string_splitter(whole_query_str, ";");
  for (auto current_query : queries_vector) {

    trim_string(current_query);
    current_query += ";";

    // check the validity of the IR here
    // The unique_id_in_tree_ variable are being set inside the parsing func.
    vector<IR *> ir_set = parse_query_str_get_ir_set(current_query);
    if (ir_set.size() == 0)
      continue;

    IR *root = ir_set.back();
    vector<IR *> v_tmp_cur_stmt =
        p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(root, kCmd, false);
    if (v_tmp_cur_stmt.size() == 0) {
      root->deep_drop();
      continue;
    }
    IR *cur_stmt = v_tmp_cur_stmt.front()->left_; // kCmd to kSpecificStmt.

    if (p_oracle->is_oracle_select_stmt(cur_stmt)) {

      // if (all_comp_res.v_res.size() > i) {
      //   if (all_comp_res.v_res[i].comp_res == ORA_COMP_RES::Error ||
      //   all_comp_res.v_res[i].comp_res == ORA_COMP_RES::IGNORE) {
      //     ++i;
      //     // cerr << "Ignoring: " << i << current_query << endl;
      //     continue;
      //   }
      // }

      add_to_valid_lib(root, current_query);
      ++i; // For counting oracle valid stmt IDs.
    } else {
      add_to_library(root, current_query);
    }

    root->deep_drop();
  }
}

void Mutator::add_to_valid_lib(IR *ir, string &select) {

  unsigned long p_hash = hash(select);

  if (oracle_select_hash.find(p_hash) != oracle_select_hash.end())
    return;

  oracle_select_hash[p_hash] = true;

  string *new_select = new string(select);

  all_query_pstr_set.insert(new_select);
  all_valid_pstr_vec.push_back(new_select);

  if (use_cri_val)
    all_cri_valid_pstr_vec.push_back(new_select);

  // if (this->dump_library) {
  //   std::ofstream f;
  //   f.open("./oracle-select", std::ofstream::out | std::ofstream::app);
  //   f << *new_select << endl;
  //   f.close();
  // }

  add_to_library_core(ir, new_select);

  return;
}

void Mutator::add_to_library(IR *ir, string &query) {

  if (query == "")
    return;

  NODETYPE p_type = ir->type_;
  unsigned long p_hash = hash(query);

  if (ir_libary_2D_hash_[p_type].find(p_hash) !=
      ir_libary_2D_hash_[p_type].end()) {
    /* query not interesting enough. Ignore it and clean up. */
    return;
  }
  ir_libary_2D_hash_[p_type].insert(p_hash);

  string *p_query_str = new string(query);
  all_query_pstr_set.insert(p_query_str);

  // if (this->dump_library) {
  //   std::ofstream f;
  //   f.open("./normal-lib", std::ofstream::out | std::ofstream::app);
  //   f << *p_query_str << endl;
  //   f.close();
  // }

  add_to_library_core(ir, p_query_str);

  // get_memory_usage();  // Debug purpose.

  return;
}

void Mutator::add_to_library_core(IR *ir, string *p_query_str) {
  /* Save an interesting query stmt into the mutator library. Helper function
   * for Mutator::add_to_library();
   */

  if (*p_query_str == "")
    return;

  int current_unique_id = ir->uniq_id_in_tree_;
  bool is_skip_saving_current_node = false; //

  NODETYPE p_type = ir->type_;
  NODETYPE left_type = kUnknown, right_type = kUnknown;

  unsigned long p_hash = hash(ir->to_string());
  if (p_type != kInput && ir_libary_2D_hash_[p_type].find(p_hash) !=
                              ir_libary_2D_hash_[p_type].end()) {
    /* current node not interesting enough. Ignore it and clean up. */
    return;
  }
  if (p_type != kInput)
    ir_libary_2D_hash_[p_type].insert(p_hash);

  // Update with_lib.
  if (!is_skip_saving_current_node)
    real_ir_set[p_type].push_back(
        std::make_pair(p_query_str, current_unique_id));

  // Update right_lib, left_lib
  if (ir->right_ && ir->left_ && !is_skip_saving_current_node) {
    left_type = ir->left_->type_;
    right_type = ir->right_->type_;
    left_lib_set[left_type].push_back(std::make_pair(
        p_query_str, current_unique_id)); // Saving the parent node id. When
                                          // fetching, use current_node->right.
    right_lib_set[right_type].push_back(std::make_pair(
        p_query_str, current_unique_id)); // Saving the parent node id. When
                                          // fetching, use current_node->left.
  }

  if (this->dump_library) {

    std::ofstream f;
    f.open("./append-core", std::ofstream::out | std::ofstream::app);
    f << *p_query_str << " node_id: " << current_unique_id << endl;
    f.close();
  }

  if (ir->left_) {
    add_to_library_core(ir->left_, p_query_str);
  }

  if (ir->right_) {
    add_to_library_core(ir->right_, p_query_str);
  }

  return;
}

void Mutator::get_memory_usage() {

  static unsigned long old_use = 0;

  std::ofstream f;
  // f.rdbuf()->pubsetbuf(0, 0);
  f.open("./memlog.txt", std::ofstream::out);

  struct rusage usage;
  getrusage(RUSAGE_SELF, &usage);

  unsigned long use = usage.ru_maxrss * 1024;

  // if (use - old_use < 1024 * 1024)
  //   return;

  f << "-------------------------------------\n";
  f << "memory use:  " << use << "\n";
  old_use = use;

  unsigned long total_size = 0;

  // unsigned long size_2D_hash = 0;
  // for (auto &i : ir_libary_2D_hash_)
  //   size_2D_hash += i.second.size() * 8;
  // f << "2D hash size:" << size_2D_hash
  //      << "\t - " << size_2D_hash * 1.0 / use << "\n";
  // total_size += size_2D_hash;

  // unsigned long size_2D = 0;
  // for(auto &i: ir_libary_2D_)
  //   size_2D += i.second.size() * 8;
  // f << "2D size:     " << size_2D
  //      << "\t - " << size_2D * 1.0 / use << "\n";
  // total_size += size_2D;

  // unsigned long size_left = 0;
  // for(auto &i: left_lib)
  //   size_left += i.second.size() * 8;;
  // f << "left size:   " << size_left
  //      << "\t - " << size_left * 1.0 / use << "\n";
  // total_size += size_left;

  // unsigned long size_right = 0;
  // for(auto &i: right_lib)
  //   size_right += i.second.size();
  // f << "right size:  " << size_right
  //      << "\t - " << size_right * 1.0 / use << "\n";
  // total_size += size_right;

  unsigned long size_value = 0;
  for (auto &v : value_libary)
    size_value += v.size();
  f << "value size:   " << size_value << "\t - " << size_value * 1.0 / use
    << "\n";
  total_size += size_value;

  unsigned long size_m_tables = 0;
  for (auto &i : m_tables)
    for (auto &j : i.second)
      size_m_tables += j.capacity();
  ;
  f << "m_tables size:" << size_m_tables << "\t - " << size_m_tables * 1.0 / use
    << "\n";
  total_size += size_m_tables;

  unsigned long size_v_table_names = 0;
  for (auto &i : v_table_names)
    size_v_table_names += i.capacity();
  ;
  f << "v_tbl size:   " << size_v_table_names << "\t - "
    << size_v_table_names * 1.0 / use << "\n";
  total_size += size_v_table_names;

  unsigned long size_string_libary = 0;
  for (auto &i : string_libary)
    size_string_libary += i.capacity();
  f << "str lib size :" << size_string_libary << "\t - "
    << size_string_libary * 1.0 / use << "\n";
  total_size += size_string_libary;

  unsigned long size_real_ir_set_str_libary = 0;
  for (auto i : all_query_pstr_set)
    size_real_ir_set_str_libary += i->capacity() + 8;
  f << "all_query_pstr_set size :" << size_real_ir_set_str_libary << "\t - "
    << size_real_ir_set_str_libary * 1.0 / use << "\n";
  total_size += size_real_ir_set_str_libary;

  f << "total size:  " << total_size << "\t - " << total_size * 1.0 / use
    << "\n";

  f.close();
}

unsigned long Mutator::hash(const string &sql) {
  return fuzzing_hash(sql.c_str(), sql.size());
}

unsigned long Mutator::hash(IR *root) { return this->hash(root->to_string()); }

void Mutator::debug(IR *root, unsigned level) {

  for (unsigned i = 0; i < level; i++)
    cout << " ";

  cout << level << ": "
       << get_string_by_ir_type(root->type_) << ": "
       << get_string_by_id_type(root->id_type_)
       << ": str_val_: " << root->str_val_ << ": to_str: " << root->to_string()
       << endl;

  if (root->left_)
    debug(root->left_, level + 1);
  if (root->right_)
    debug(root->right_, level + 1);
}

Mutator::~Mutator() {
  for (auto iter : all_query_pstr_set) {
    delete iter;
  }
}

void Mutator::save_tmp_dependency() {
  tmp_m_tables = m_tables;
  tmp_m_tables_with_tmp = m_tables_with_tmp;
  tmp_m_table2index = m_table2index;
  tmp_v_table_names = v_table_names;
  tmp_used_string_library = used_string_library;
  tmp_used_value_libary = used_value_libary;
}

void Mutator::rollback_dependency() {
  m_tables = tmp_m_tables;
  m_tables_with_tmp = tmp_m_tables_with_tmp;
  m_table2index = tmp_m_table2index;
  v_table_names = tmp_v_table_names;
  used_string_library = tmp_used_string_library;
  used_value_libary = tmp_used_value_libary;
}

bool Mutator::fix_dependency(IR *root,
                             vector<vector<IR *>> &ordered_all_subquery_ir,
                             bool is_debug_info) {
  set<IR *> visited;
  reset_database_single_stmt();
  save_tmp_dependency();
  string cur_pragma_key = "";

  if (is_debug_info) {
    cerr << "Trying to fix_dependency on stmt: " << root->to_string()
         << ". \n\n\n";
  }

  /* Loop through the subqueries. From the most parent query to the most child
   * query. (In the same query statement. )*/
  for (vector<IR *> &ordered_ir : ordered_all_subquery_ir) {

    /* First loop through all ir_to_fix, resolve all id_create_table_name and
     * id_table_alias_name. */
    for (auto ir : ordered_ir) {
      if (visited.find(ir) != visited.end()) {
        continue;
      }

      /* This identifier_ is a naming placeholder that hold the newly defined
      *table name.
      ** Can be used in CREATE TABLE statement.
      */
      if (
          ir->id_type_ == id_create_table_name ||
          ir->id_type_ == id_create_view_name
          ) {
        ir->str_val_ = gen_id_name();
        v_create_table_names_single.push_back(ir->str_val_);
        visited.insert(ir);
        if (is_debug_info) {
          cerr << "Dependency: In id_create_table_name, we created "
                  "v_table_name: "
               << ir->str_val_ << "\n\n\n";
        }
        /* Take care of the alias, if any. We will not save this alias into the
         * lib, as using just id_create_table_name(with alias) will most likely
         * resulted in errors. */
        IR *alias_ir =
            p_oracle->ir_wrapper.get_alias_iden_from_tablename_iden(ir);
        if (alias_ir != nullptr && alias_ir->id_type_ == id_table_alias_name) {
          string new_alias_str = gen_alias_name();
          alias_ir->str_val_ = new_alias_str;
          visited.insert(alias_ir);
          if (is_debug_info) {
            cerr << "Dependency: In id_create_table_name, we save alias_name: "
                 << new_alias_str << ". \n\n\n";
          }
        }
      } else if (ir->id_type_ == id_create_window_name) {
        ir->str_val_ = gen_window_name();
        v_window_name_single.push_back(ir->str_val_);
        visited.insert(ir);
        if (is_debug_info) {
          cerr << "Dependency: In id_create_window_name, we created "
                  "window name: "
               << ir->str_val_ << "\n\n\n";
        }
      } else if (ir->id_type_ == id_create_table_name_with_tmp) {
        /* This is a newly created name used in the WITH clause.
        ** WITH clause defined tmp names, used by only the one statement.
        ** Thus, we only save this table_name in this single statement, don't
        *save it into v_table_names or m_tables.
        */
        ir->str_val_ = gen_id_name();
        v_create_table_names_single_with_tmp.push_back(ir->str_val_);
        visited.insert(ir);
        if (is_debug_info) {
          cerr << "Dependency: In id_create_table_name_with_tmp, we created "
                  "table_name_tmp: "
               << ir->str_val_ << "\n\n\n";
        }
      }

      else if (ir->id_type_ == id_trigger_name) {
        ir->str_val_ = gen_column_name();
        visited.insert(ir);
        if (is_debug_info) {
          cerr << "Dependency: Generated trigger name: " << ir->str_val_
               << "\n\n\n";
        }
      }
    }

    /* Second loop, resolve all id_top_table_name, id_table_alias_name. */
    for (auto ir : ordered_ir) {
      if (visited.find(ir) != visited.end()) {
        continue;
      }

      IRTYPE cur_stmt_type = p_oracle->ir_wrapper.get_cur_stmt_type(ir);

      if (ir->id_type_ == id_top_table_name) {

        if (findStringIn(ir->str_val_, "forced_view")) {
          ir->str_val_ = v_table_names.back();
          visited.insert(ir);
          continue;
        }

        /* This is the place to reference prevous defined table names. Used in
         * FROM clause etc. */
        if (v_table_names.size() != 0 ||
            v_create_table_names_single.size() != 0 ||
            v_create_table_names_single_with_tmp.size() != 0) {

          /* In 3/10 chances, we use the table name defined in the WITH clause.
           */
          if (is_debug_info) {
            cerr << "Dependency: v_create_table_names_single_with_tmp.size() "
                    "is: "
                 << v_create_table_names_single_with_tmp.size() << "\n\n\n";
          }
          if (v_create_table_names_single_with_tmp.size() != 0 &&
              cur_stmt_type != kCmdUpdate && get_rand_int(100) < 50) {
            if (is_debug_info) {
              cerr << "Dependency Error: Cannot find the "
                      "create_table_names_single_with_tmp inside the "
                      "kWithClause. \n\n\n";
            }
            ir->str_val_ = v_create_table_names_single_with_tmp[get_rand_int(
                v_create_table_names_single_with_tmp.size())];
            visited.insert(ir);
            if (is_debug_info) {
              cerr << "Dependency: In id_top_table_name, we used "
                      "v_create_table_names_single: "
                   << ir->str_val_ << ". \n\n\n";
            }

            /* If not using table_name defined in the WITH clause, then we
             * randomly pick one table that is previsouly defined. */
          } else if (v_table_names.size()) {
            ir->str_val_ = v_table_names[get_rand_int(v_table_names.size())];
            v_table_names_single.push_back(ir->str_val_);
            visited.insert(ir);

            /*
            ** If we cannot find any previously defined table_names,
            ** well, this is unexpected. see if we have table_names that is just
            *defined in this stmt.
            */
          } else {
            ir->str_val_ = v_create_table_names_single[get_rand_int(
                v_create_table_names_single.size())];
            v_table_names_single.push_back(
                ir->str_val_); /* Should we expose it to v_table_name_single? */
            visited.insert(ir);
          }

          if (is_debug_info) {
            cerr << "Dependency: In id_top_table_name, we used table_name: "
                 << ir->str_val_ << ". \n\n\n";
          }

          /* Take care of the alias, if any.  */
          IR *alias_ir =
              p_oracle->ir_wrapper.get_alias_iden_from_tablename_iden(ir);
          if (alias_ir != nullptr &&
              alias_ir->id_type_ == id_table_alias_name) {
            string new_alias_str = gen_alias_name();
            alias_ir->str_val_ = new_alias_str;
            v_alias_names_single.push_back(new_alias_str);
            m_table2alias_single[ir->str_val_].push_back(new_alias_str);
            visited.insert(alias_ir);

            if (is_debug_info) {
              cerr << "Dependency: In id_top_table_name, for table_name: "
                   << ir->str_val_
                   << ", we generate alias name: " << new_alias_str
                   << ". \n\n\n";
            }
//          } else if (cur_stmt_type == kCmdSelect) {
          } else if (
                  cur_stmt_type != kCmdCreateIndex &&
                  cur_stmt_type != kCmdAlterTableAddColumn &&
                  cur_stmt_type != kCmdAlterTableDropColumn &&
                  cur_stmt_type != kCmdAlterTableRename &&
                  cur_stmt_type != kCmdAlterTableRenameColumn &&
                  cur_stmt_type != kCmdAnalyze
                  )
          {
            string new_alias_str = gen_alias_name();
            m_table2alias_single[ir->str_val_].push_back(new_alias_str);
            ir->str_val_ += " AS " + new_alias_str;
            v_alias_names_single.push_back(new_alias_str);

            if (is_debug_info) {
              cerr << "Dependency: In id_top_table_name, for table_name: "
                   << ir->str_val_
                   << ", we generate(create AS) alias name: " << new_alias_str
                   << ". \n\n\n";
            }
          }
        } else { // if (v_table_names.size() != 0 ||
                 // v_create_table_names_single.size() != 0 ||
                 // v_create_table_names_single_with_tmp.size() != 0)
          if (is_debug_info) {
            cerr << "Dependency Error: In id_top_table_name, couldn't find any "
                    "v_table_names saved. \n\n\n";
          }
          ir->str_val_ = "y";
          continue;
        }
      }
    }

    /* Third loop, resolve id_table_name */
    for (auto ir : ordered_ir) {
      if (visited.find(ir) != visited.end()) {
        continue;
      }

      IRTYPE cur_stmt_type = p_oracle->ir_wrapper.get_cur_stmt_type(ir);

      if (ir->id_type_ == id_table_name) {
        /* id_table_name is used in the actual operations, for example, the
        *table_names in the WHERE clause.
        ** Normally, if we encounter id_table_name, there have been
        *id_top_table_name defined in the FROM clause etc.
        */
        if (is_debug_info) {
          cerr << "Dependency: v_create_table_names_single_with_tmp.size() is: "
               << v_create_table_names_single_with_tmp.size() << "\n\n\n";
        }
        if (v_create_table_names_single_with_tmp.size() != 0 &&
            cur_stmt_type != kCmdUpdate && get_rand_int(100) < 50) {
          ir->str_val_ = v_create_table_names_single_with_tmp[get_rand_int(
              v_create_table_names_single_with_tmp.size())];
          visited.insert(ir);
          if (is_debug_info) {
            cerr << "Dependency: In id_table_name, we used "
                    "v_create_table_names_single_with_tmp: "
                 << ir->str_val_ << ". \n\n\n";
          }
        } else if (v_table_names_single.size() != 0) {
          /* Check whether there are previous defined id_top_table_name. */
          string tablename_str =
              v_table_names_single[get_rand_int(v_table_names_single.size())];
          if (m_table2alias_single.count(tablename_str) != 0) {
            vector<string>& v_tmp_alias = m_table2alias_single[tablename_str];
            if (v_tmp_alias.size()) {
              tablename_str = vector_rand_ele(v_tmp_alias);
            }
          }
          ir->str_val_ = tablename_str;
          visited.insert(ir);
          if (is_debug_info) {
            cerr << "Dependency: In id_table_name, we used "
                    "v_table_names_single: "
                 << ir->str_val_ << ". \n\n\n";
          }
        } else if (v_table_names.size() != 0) {
          /* Well, this is unexpected. No id_top_table_name defined.
          ** Then, we have to fetched table_name defined in the previous
          *statment.
          */
          string tablename_str =
              v_table_names[get_rand_int(v_table_names.size())];
          if (m_table2alias_single.count(tablename_str) != 0) {
            vector<string>& v_tmp_alias = m_table2alias_single[tablename_str];
            if (v_tmp_alias.size()) {
              tablename_str = vector_rand_ele(v_tmp_alias);
            }
          }
          ir->str_val_ = tablename_str;
          v_table_names_single.push_back(tablename_str);
          visited.insert(ir);
          if (is_debug_info) {
            cerr << "Dependency: In id_table_name, while v_table_name_single "
                    "is empty, we used table_name: "
                 << ir->str_val_ << ". \n\n\n";
          }
        } else if (v_create_table_names_single.size() != 0) {
          /* This is unexpected.
          ** If cannot find any table name defined before. Then see if we can
          *find newly created table_name in this specific stmt.
          */
          string tablename_str = v_create_table_names_single[get_rand_int(
              v_create_table_names_single.size())];
          if (m_table2alias_single.count(tablename_str) != 0) {
            vector<string>& v_tmp_alias = m_table2alias_single[tablename_str];
            if (v_tmp_alias.size()) {
              tablename_str = vector_rand_ele(v_tmp_alias);
            }
          }
          ir->str_val_ = tablename_str;
          v_table_names_single.push_back(tablename_str);
          visited.insert(ir);
          if (is_debug_info) {
            cerr << "Dependency: In id_table_name, while v_table_name_single "
                    "is empty, we used table_name: "
                 << ir->str_val_ << ". \n\n\n";
          }
        } else {
          /* :-( Well, we found nothing for id_table_name. Give up. Generate a
           * new one, and fill in. Most likely a semantic error in the SQL. */
          if (is_debug_info) {
            cerr << "Dependency Error: In id_table_name, couldn't find any "
                    "v_table_names, v_table_name_single and "
                    "v_create_table_name_single saved. \n\n\n";
          }
          ir->str_val_ = "y";
          continue;
        }
      }
    }

    /* Fourth loop, resolve id_create_index_name, id_create_column_name */
    for (auto ir : ordered_ir) {
      if (visited.find(ir) != visited.end()) {
        continue;
      }

      /* There is only one case of id_create_index_name, that is in the CREATE
       * INDEX statement. */
      if (ir->id_type_ == id_create_index_name) {
        if (v_create_table_names_single.size() == 0 &&
            v_table_names_single.size() == 0) {
          if (is_debug_info) {
            cerr << "Dependency Error: id_create_index_name, couldn't find any "
                    "v_table_name saved. \n\n\n";
          }
          ir->str_val_ = gen_index_name();
          continue;
        }
        /* Find the table_name that we want to create index for. */
        string tablename_str = "";
        if (v_create_table_names_single.size() > 0) {
          tablename_str = v_create_table_names_single[get_rand_int(
              v_create_table_names_single.size())];
        } else {
          tablename_str =
              v_table_names_single[get_rand_int(v_table_names_single.size())];
        }
        string new_indexname_str = gen_index_name();
        ir->str_val_ = new_indexname_str;
        m_table2index[tablename_str].push_back(new_indexname_str);
        visited.insert(ir);

        if (is_debug_info) {
          cerr << "Dependency: In id_create_index_name, saved index name: "
               << new_indexname_str << " for table: " << tablename_str
               << ". \n\n\n";
        }
      }

      if (ir->id_type_ == id_create_column_name ||
          ir->id_type_ == id_create_column_name_with_tmp ||
          ir->id_type_ == id_top_column_name) {
        if (v_create_table_names_single.size() == 0 &&
            v_table_names_single.size() == 0 &&
            v_create_table_names_single_with_tmp.size() == 0) {
          if (is_debug_info) {
            cerr << "Dependency Error: id_create_column_name, couldn't find "
                    "any v_table_name saved. \n\n\n";
          }
          ir->str_val_ = gen_column_name();
          continue;
        }

        /* Find the table_name that we want to create columns for. */
        string tablename_str = "";
        bool is_with_clause = false;
        /* Column named defined in the WITH clause. These column name is tmp.
        *Will remove immediately after this stmt ends.
        ** Thus, we create them, but do not save into m_tables.
        */
        if (ir->id_type_ == id_create_column_name_with_tmp) {
          if (v_create_table_names_single_with_tmp.size() == 0) {
            if (is_debug_info) {
              cerr
                  << "Dependency Error: id_create_column_name_with_tmp, cannot "
                     "find any id_create_table_name_with_tmp saved. \n\n\n";
              ir->str_val_ = gen_column_name();
              continue;
            }
          }
          is_with_clause = true;
        }
        /* Normal create column stmt. Find table name using
        *v_create_table_names_single.
        ** Most of the time, one CREATE TABLE statement or ALTER stmt only have
        *one table name defined.
        ** Thus using v_create_table_names_single should be fine.
        */
        else if (v_create_table_names_single.size() > 0) {
          tablename_str = v_create_table_names_single[get_rand_int(
              v_create_table_names_single.size())];
        }
        /* If we cannot find any newly created table_names, then check the
        *table_names used in this stmt.
        ** Could happens in ALTER stmt.
        */
        else {
          tablename_str =
              v_table_names_single[get_rand_int(v_table_names_single.size())];
        }

        /* This is a special case for using column. We can directly fill in
         * random defined column_name. Mostly for debug purpose. */
        if (ir->id_type_ == id_top_column_name && v_table_names.size() != 0) {
          string random_tablename_str = vector_rand_ele(v_table_names);
          vector<string> random_column_vec = m_tables[random_tablename_str];
          if (random_column_vec.size() != 0) {
            ir->str_val_ = vector_rand_ele(random_column_vec);
            if (tablename_str != "." && !is_str_empty(ir->str_val_)) {
              m_tables[tablename_str].push_back(ir->str_val_);
            }
          } else {
            /* Cannot find any saved column name. Changed to create_column_name.
             */
            ir->id_type_ = id_create_column_name;
          }
        }

        /* For actual id_create_column_name, used in most create table or alter
         * statements. */
        string new_columnname_str = gen_column_name();
        ir->str_val_ = new_columnname_str;

        /* Save the WITH clause created column name into a tmp vector. This
         * column name can be used directly without referencing its table names
         * in the current query. */
        if (is_with_clause) {
          v_create_column_names_single_with_tmp.push_back(new_columnname_str);
        } else {
          /* In normal column name creation. Just append it to the m_tables for
           * future statements usage. */
          m_tables[tablename_str].push_back(new_columnname_str);
        }

        if (is_debug_info) {
          cerr << "Dependency: In id_create_column_name, created column name: "
               << new_columnname_str << " for table: " << tablename_str
               << ". \n\n\n";
        }

        visited.insert(ir);
      }
    }

    /* Fifth loop, resolve id_column_name, id_index_name, id_pragma_value. */
    for (auto ir : ordered_ir) {
      if (visited.find(ir) != visited.end()) {
        continue;
      }

      IRTYPE cur_stmt_type = p_oracle->ir_wrapper.get_cur_stmt_type(ir);

      if (ir->id_type_ == id_column_name) {

        if (v_table_names_single.size() == 0 &&
            v_create_table_names_single.size() == 0 &&
            v_create_column_names_single_with_tmp.size() == 0) {
          if (is_debug_info) {
            cerr << "Dependency Error: for id_column_name, couldn't find any "
                    "v_table_name_single saved. \n\n\n";
          }
//          ir->str_val_ = "y";
          if(get_rand_int(2)) {
            ir->type_ = kIntegerLiteral;
          } else {
            ir->type_ = kStringLiteral;
          }
          ir->id_type_ = id_whatever;
          visited.insert(ir);
          continue;
//          if (is_debug_info) {
//            cerr << "Dependency: using column name: " << ir->str_val_ <<  ". \n\n\n";
//          }
        }

        /* Special handling for the UPDATE stmt.
        ** We cannot use alias.column name in the UPDATE stmt.
        ** Thus, we have to manually fetch which table_name we are referring to,
        ** and updates the column name based on the table_name mentioned.
        */
        if (cur_stmt_type == kCmdUpdate) {
          IR *update_stmt_node =
              p_oracle->ir_wrapper.get_stmt_ir_from_child_ir(ir);
          // From kCmdUpdate to qualified_table_name.
          IR *qualified_table_name_ =
              p_oracle->ir_wrapper
                  .get_ir_node_in_stmt_with_type(update_stmt_node, kXfullname,
                                                 false)
                  .front();
          string cur_choosen_table_name =
              qualified_table_name_->left_->str_val_;
          vector<string> v_tmp_split =
              string_splitter(cur_choosen_table_name, ",");
          if (v_tmp_split.size() > 1) {
            cur_choosen_table_name = v_tmp_split.back();
          }

          vector<string> &column_name_vec = m_tables[cur_choosen_table_name];
          if (column_name_vec.size() != 0) {
            ir->str_val_ =
                column_name_vec[get_rand_int(column_name_vec.size())];
            if (is_debug_info) {
              cerr << "Dependency: Special handling for UPDATE stmt. Received "
                      "table_name: "
                   << cur_choosen_table_name << " Return: " << ir->str_val_
                   << " for id_column_name. \n\n\n";
            }
          } else {
            if (is_debug_info) {
              cerr << "Dependency Error: Special handling for UPDATE stmt. "
                      "Cannot find m_table column for: "
                   << cur_choosen_table_name << " \n\n\n";
            }
          }
        }

        /* 1/5 chances, pick column_names from WITH clause directly. */
        if (is_debug_info) {
          cerr << "Dependency: Getting cur_stmt_type: "
               << get_string_by_ir_type(cur_stmt_type) << " \n\n\n";
        }

        /* Do not use column name defined in WITH clause, in the UPDATE or ALTER
         * stmt. */
        if ((v_create_column_names_single_with_tmp.size() != 0 &&
             cur_stmt_type != kCmdAlterTableRename &&
             cur_stmt_type != kCmdAlterTableRenameColumn &&
             cur_stmt_type != kCmdAlterTableAddColumn &&
             cur_stmt_type != kCmdAlterTableDropColumn &&
             cur_stmt_type != kCmdAnalyze &&
             cur_stmt_type != kCmdUpdate && get_rand_int(100) < 30) ||
            (v_table_names_single.size() == 0 &&
             v_create_table_names_single.size() == 0)) {
          ir->str_val_ = v_create_column_names_single_with_tmp[get_rand_int(
              v_create_column_names_single_with_tmp.size())];
          continue;
        }

        string tablename_str;
        if (v_table_names_single.size() != 0) {
          tablename_str =
              v_table_names_single[get_rand_int(v_table_names_single.size())];
        } else {
          tablename_str = v_create_table_names_single[get_rand_int(
              v_create_table_names_single.size())];
        }

        if (p_oracle->ir_wrapper.get_cur_stmt_type(ir) == kCmdCreateVTable ||
            p_oracle->ir_wrapper.get_cur_stmt_type(ir) == kCmdCreateTrigger) {
          tablename_str = v_table_names[get_rand_int(v_table_names.size())];
        }

        vector<string> &matched_columnname_vec = m_tables[tablename_str];
        vector<string> &matched_aliasname_vec =
            m_table2alias_single[tablename_str];
        if (matched_aliasname_vec.size() != 0 &&
            matched_columnname_vec.size() != 0) {
          string aliasname_str =
              matched_aliasname_vec[get_rand_int(matched_aliasname_vec.size())];
          string column_str = matched_columnname_vec[get_rand_int(
              matched_columnname_vec.size())];
          if (is_debug_info) {
            cerr << "Dependency: Getting cur_stmt_type: "
                 << get_string_by_ir_type(cur_stmt_type) << " \n\n\n";
          }
          /* Added alias_name before the column_name. Only for SelectStmt. */
          if (
//              cur_stmt_type == kCmdSelect &&
              !(p_oracle->ir_wrapper.is_ir_in(ir, kIdlist)) && // idlist does not allow dot
              !(p_oracle->ir_wrapper.is_ir_in(ir, kTcons)) && // kTcons does not allow dot
              !(p_oracle->ir_wrapper.is_ir_in(ir, kCcons)) && // kCcons does not allow dot
              !(p_oracle->ir_wrapper.is_ir_in(ir, kSetlist)) && // kSetlist does not allow dot
              cur_stmt_type != kCmdCreateIndex &&
              cur_stmt_type != kCmdUpdate &&
              cur_stmt_type != kCmdAlterTableAddColumn &&
              cur_stmt_type != kCmdAlterTableRenameColumn &&
              cur_stmt_type != kCmdAlterTableRename &&
              cur_stmt_type != kCmdAlterTableDropColumn
              ) {
            if ((get_rand_int(20) == 0)) {
              column_str = "rowid";
            }
            ir->str_val_ = aliasname_str + "." + column_str;
          } else {
            if ((get_rand_int(20)) == 0) {
              column_str = "rowid";
            }
            { ir->str_val_ = column_str; }
          }

          if (is_debug_info) {
            cerr << "Dependency: For id_column_name, we used: " << ir->str_val_
                 << ". \n\n\n";
          }

          visited.insert(ir);
        } else if (matched_columnname_vec.size() != 0) {
          string column_str = matched_columnname_vec[get_rand_int(
              matched_columnname_vec.size())];
          if (is_debug_info) {
            cerr << "Dependency: Getting cur_stmt_type: "
                 << get_string_by_ir_type(cur_stmt_type) << " \n\n\n";
          }
          /* If cannot find alias name for the table, directly add table_name
           * before the column_name. Only for SelectStmt. */
          if (
//              cur_stmt_type == kCmdSelect &&
              !(p_oracle->ir_wrapper.is_ir_in(ir, kIdlist)) && // idlist does not allow dot
              !(p_oracle->ir_wrapper.is_ir_in(ir, kTcons)) && // kTcons does not allow dot
              !(p_oracle->ir_wrapper.is_ir_in(ir, kCcons)) && // kCcons does not allow dot
              !(p_oracle->ir_wrapper.is_ir_in(ir, kSetlist)) &&
              cur_stmt_type != kCmdCreateIndex &&
              cur_stmt_type != kCmdUpdate &&
              cur_stmt_type != kCmdAlterTableAddColumn &&
              cur_stmt_type != kCmdAlterTableRenameColumn &&
              cur_stmt_type != kCmdAlterTableRename &&
              cur_stmt_type != kCmdAlterTableDropColumn
              ) {
            if ((get_rand_int(20) == 0)) {
              column_str = "rowid";
            }
            ir->str_val_ = tablename_str + "." + column_str;
          } else {
            if ((get_rand_int(20)) == 0 && cur_stmt_type != kCmdCreateIndex) {
              column_str = "rowid";
            }
            { ir->str_val_ = column_str; }
          }
          if (is_debug_info) {
            cerr << "Dependency: For id_column_name, we used: " << ir->str_val_
                 << ". \n\n\n";
          }

          visited.insert(ir);
        } else { // Cannot find matched column for table.
          if (is_debug_info) {
            cerr << "Dependency Error: for id_column_name, couldn't find any "
                    "matched_columnname_vec saved. \n\n\n";
          }
//          ir->str_val_ = "y";
          if(get_rand_int(2)) {
            ir->type_ = kIntegerLiteral;
          } else {
            ir->type_ = kStringLiteral;
          }
          ir->id_type_ = id_whatever;
          visited.insert(ir);
          continue;
        }
      }

      if (ir->id_type_ == id_index_name) {
        if (v_table_names_single.size() == 0) {
          if (is_debug_info) {
            cerr << "Dependency Error: for id_index_name, couldn't find any "
                    "v_table_name_single saved. \n\n\n";
          }
          ir->str_val_ = "y";
          if (is_debug_info) {
            cerr << "Dependency: using index name: " << ir->str_val_ <<  ". \n\n\n";
          }
          visited.insert(ir);
          continue;
        }

        string tablename_str =
            v_table_names_single[get_rand_int(v_table_names_single.size())];
        if (m_table2index.find(tablename_str) == m_table2index.end()) {
          if (is_debug_info) {
            cerr << "Dependency Error: In id_index_name, cannot find index for "
                    "table name: "
                 << tablename_str << ". \n\n\n";
          }
          string random_tablename_str = vector_rand_ele(v_table_names);
          vector<string> random_index_vec = m_table2index[random_tablename_str];
          if (random_index_vec.size() != 0) {
            ir->str_val_ = vector_rand_ele(random_index_vec);
            if (is_debug_info) {
              cerr << "Dependency: using index name: " << ir->str_val_ <<  ". \n\n\n";
            }
          } else {
            ir->str_val_ = "y";
            if (is_debug_info) {
              cerr << "Dependency: using index name: " << ir->str_val_ <<  ". \n\n\n";
            }
          }
          visited.insert(ir);
          continue;
        }

        vector<string> &matched_indexname_vec = m_table2index[tablename_str];
        vector<string> &matched_aliasname_vec =
            m_table2alias_single[tablename_str];
        if (matched_aliasname_vec.size() != 0 &&
            matched_indexname_vec.size() != 0) {
          string aliasname_str =
              matched_aliasname_vec[get_rand_int(matched_aliasname_vec.size())];
          string index_str =
              matched_indexname_vec[get_rand_int(matched_indexname_vec.size())];
          if (is_debug_info) {
            cerr << "Dependency: Getting cur_stmt_type: "
                 << get_string_by_ir_type(cur_stmt_type) << " \n\n\n";
          }
          if (cur_stmt_type != kCmdUpdate &&
              cur_stmt_type != kCmdAlterTableAddColumn &&
              cur_stmt_type != kCmdAlterTableRenameColumn &&
              cur_stmt_type != kCmdAlterTableRename &&
              cur_stmt_type != kCmdAlterTableDropColumn &&
              cur_stmt_type != kCmdAnalyze &&
              !(p_oracle->ir_wrapper.is_ir_in(ir, kIdlist)) && // idlist does not allow dot
              !(p_oracle->ir_wrapper.is_ir_in(ir, kTcons)) && // kTcons does not allow dot
              !(p_oracle->ir_wrapper.is_ir_in(ir, kCcons)) && // kCcons does not allow dot
              !(p_oracle->ir_wrapper.is_ir_in(ir, kIndexedBy)) && // indexed by does not allow dot
              !(p_oracle->ir_wrapper.is_ir_in(ir, kSetlist)) &&
              cur_stmt_type != kCmdCreateIndex
              ) {
            ir->str_val_ = aliasname_str + "." + index_str;
          } else {
            { ir->str_val_ = index_str; }
          }
          if (is_debug_info) {
            cerr << "Dependency: For id_index_name, we used: " << ir->str_val_
                 << ". \n";
          }
          visited.insert(ir);
        } else if (matched_indexname_vec.size() != 0) {
          string index_str =
              matched_indexname_vec[get_rand_int(matched_indexname_vec.size())];
          if (is_debug_info) {
            cerr << "Dependency: Getting cur_stmt_type: "
                 << get_string_by_ir_type(cur_stmt_type) << " \n\n\n";
          }
          if (cur_stmt_type != kCmdUpdate &&
              cur_stmt_type != kCmdAlterTableAddColumn &&
              cur_stmt_type != kCmdAlterTableRenameColumn &&
              cur_stmt_type != kCmdAlterTableRename &&
              cur_stmt_type != kCmdAlterTableDropColumn &&
              cur_stmt_type != kCmdAnalyze &&
              !(p_oracle->ir_wrapper.is_ir_in(ir, kIdlist)) && // idlist does not allow dot
              !(p_oracle->ir_wrapper.is_ir_in(ir, kTcons)) && // kTcons does not allow dot
              !(p_oracle->ir_wrapper.is_ir_in(ir, kCcons)) && // kCcons does not allow dot
              !(p_oracle->ir_wrapper.is_ir_in(ir, kSetlist)) &&
              cur_stmt_type != kCmdCreateIndex
              ) {
            ir->str_val_ = tablename_str + "." + index_str;
          } else {
            { ir->str_val_ = index_str; }
          }
          if (is_debug_info) {
            cerr << "Dependency: For id_index_name, we used: " << ir->str_val_
                 << ". \n";
          }
          visited.insert(ir);
        } else { // Cannot find matched index for table.
          if (is_debug_info) {
            cerr << "Dependency Error: for id_index_name, couldn't find any "
                    "matched_indexname_vec saved. \n\n\n";
          }
          ir->str_val_ = "y";
          continue;
        }
      }

      if (ir->id_type_ == id_window_name) {
        if (this->v_window_name_single.size() != 0) {
          ir->str_val_ = vector_rand_ele(this->v_window_name_single);
          visited.insert(ir);
          if (is_debug_info) {
            cerr << "Dependency: In id_window_name, we use saved window name"
                    ": "
                 << ir->str_val_ << "\n\n\n";
          }
        } else if (this->v_table_names_single.size() != 0) {
          string rand_chosen_table_name = vector_rand_ele(v_table_names_single);
          string rand_chosen_column_name;
          if (m_tables.find(rand_chosen_table_name) != m_tables.end()) {
            vector<string> v_rand_chosen_column_name = m_tables.at(rand_chosen_table_name);
            if (!v_rand_chosen_column_name.empty()) {
              rand_chosen_column_name = vector_rand_ele(v_rand_chosen_column_name);
            } else {
              rand_chosen_column_name = "rowid";
            }
          } else {
            rand_chosen_column_name = "rowid";
          }
          if (m_table2alias_single.find(rand_chosen_table_name) != m_table2alias_single.end()) {
              vector<string> v_rand_chosen_table_name = m_table2alias_single.at(rand_chosen_table_name);
              if (!v_rand_chosen_table_name.empty()) {
                rand_chosen_table_name = vector_rand_ele(v_rand_chosen_table_name);
              }
          }

          if (get_rand_int(2)) {
              ir->str_val_ = "( ORDER BY ";
          } else {
              ir->str_val_ = "( PARTITION BY ";
          }

          if (!rand_chosen_table_name.empty()) {
              ir->str_val_ += rand_chosen_table_name + ".";
          }

          ir->str_val_ += rand_chosen_column_name + ")";

        } else {
          ir->str_val_ = "y";
          visited.insert(ir);
          if (is_debug_info) {
            cerr << "Error: In id_window_name, cannot find matching window name, "
                    "using placeholder: "
                 << ir->str_val_ << "\n\n\n";
          }
        }
      }

    }

    /* Sixth loop, resolve id_function_name. */
//    for (auto ir : ordered_ir) {
//      if (visited.find(ir) != visited.end()) {
//        continue;
//      }
//
//      if (ir->id_type_ == id_function_name) {
//        if (ir->type_ != kExprFunc) {
//          visited.insert(ir);
//          continue;
//        }
//
//        // got kExprFunc now.
//        FuncSig cur_func = vector_rand_ele(this->v_func_sig);
//        string func_str = cur_func.get_mutated_func_str();
//        ir->str_val_ = func_str;
//        visited.insert(ir);
//        continue;
//      }
//    }

    /* Seventh loop, resolve id_collation-anme. */
    for (auto ir : ordered_ir) {
      if (visited.find(ir) != visited.end()) {
        continue;
      }

      if (ir->id_type_ == id_collation_name) {
        string res_str;
        switch (get_rand_int(3)) {
        case 0:
          res_str = " BINARY ";
          break;
        case 1:
          res_str = " NOCASE ";
          break;
        case 2:
          res_str = " RTRIM ";
          break;
        }
        ir->str_val_ = res_str;
        visited.insert(ir);
        continue;
      }
    }

    /* Eighth loop, resolve id_vtab_module_name. */
    for (auto ir : ordered_ir) {
      if (visited.find(ir) != visited.end()) {
        continue;
      }

      if (ir->id_type_ == id_vtab_module_name) {
        string res_str;
        vector<IR *> v_tmp_arg_list =
            p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(
                root, kVtabarglist, false);
        IR *arg_list_node = nullptr;
        if (v_tmp_arg_list.size() > 0) {
          arg_list_node = v_tmp_arg_list.front();
        }

#define write_arg(x)  do{ if (arg_list_node == nullptr) {res_str += " ( " + string(x) + ") "; } else {arg_list_node->str_val_ = string(x);} } while(0)
        switch (get_rand_int(7)) {
        case 0:
//          res_str = " csv ";
//          write_arg("'thecsvfile.csv'");
//          break;
        case 1:
//          res_str = " dbstat ";
//          write_arg("main");
//          break;
        case 2:
          res_str = " fts5 ";
          write_arg("sender");
          if (v_create_table_names_single.size() != 0) {
            m_tables[v_create_table_names_single.front()].push_back("sender");
//            m_tables[v_create_table_names_single.front()].push_back("title");
//            m_tables[v_create_table_names_single.front()].push_back("body");
            v_fts_vtable_names.push_back(v_create_table_names_single.front());
          }
          break;
        case 3:
          res_str = " fts4 ";
          write_arg("sender");
          if (v_create_table_names_single.size() != 0) {
            m_tables[v_create_table_names_single.front()].push_back("sender");
//            m_tables[v_create_table_names_single.front()].push_back("title");
//            m_tables[v_create_table_names_single.front()].push_back("body");
            v_fts_vtable_names.push_back(v_create_table_names_single.front());
          }
          break;
        case 4:
        case 5:
        case 6:
          res_str = " rtree ";
//          if (get_rand_int(2)) {
            write_arg("id, minX, maxX");
            if (v_create_table_names_single.size() != 0) {
              m_tables[v_create_table_names_single.front()].push_back("id");
              m_tables[v_create_table_names_single.front()].push_back("minX");
              m_tables[v_create_table_names_single.front()].push_back("maxX");
            }
//          } else {
//            write_arg("id");
//            if (v_create_table_names_single.size() != 0) {
//              m_tables[v_create_table_names_single.front()].push_back("id");
////              m_tables[v_create_table_names_single.front()].push_back("minX");
////              m_tables[v_create_table_names_single.front()].push_back("maxX");
////              m_tables[v_create_table_names_single.front()].push_back("minY");
////              m_tables[v_create_table_names_single.front()].push_back("maxY");
//            }
//          }
          break;
//        case 5:
//          res_str = " zipfile ";
//          if (get_rand_int(2)) {
//            write_arg("'name'");
//            if (v_create_table_names_single.size() != 0) {
//              m_tables[v_create_table_names_single.front()].push_back("unknown0");
//              m_tables[v_create_table_names_single.front()].push_back("unknown1");
//              m_tables[v_create_table_names_single.front()].push_back("unknown2");
//              m_tables[v_create_table_names_single.front()].push_back("unknown3");
//              m_tables[v_create_table_names_single.front()].push_back("unknown4");
//              m_tables[v_create_table_names_single.front()].push_back("unknown5");
//              m_tables[v_create_table_names_single.front()].push_back("unknown6");
//            }
//          }
//          break;
//        case 6:
//          res_str = " fts5vocab ";
//          string known_fts_table_name = "v0";
//          if (v_fts_vtable_names.size() > 0) {
//            known_fts_table_name = vector_rand_ele(v_fts_vtable_names);
//          }
//          write_arg(known_fts_table_name + ", 'instance'");
//          if (v_create_table_names_single.size() != 0) {
//            v_fts_vtable_names.push_back(v_create_table_names_single.front());
//          }
//          break;

        }
#undef write_arg
        ir->str_val_ = res_str;
        visited.insert(ir);
        continue;
      } // if id_vtab_module_name
    } // ir:ordered_ir

  } // for (vector<IR*>& ordered_ir : ordered_all_subquery_ir)

  v_table_names.insert(v_table_names.end(), v_create_table_names_single.begin(),
                       v_create_table_names_single.end());

  /* Loop through the subqueries again. This loop is for logging dependency
   * information. */
  for (vector<IR *> &ordered_ir : ordered_all_subquery_ir) {

    /* First loop: Resolve column mappings for kCreateViewStatement. */
    for (auto ir : ordered_ir) {
      if (ir->id_type_ != id_create_view_name
          ) {
        continue;
      }
      /* Check whether we are in the CreateViewStatement. If yes, save the
       * column mapping. */
      IR *cur_ir = ir;
      bool is_in_create_view = false;
      while (cur_ir != nullptr) {
        if (cur_ir->type_ == kCmd) {
          break;
        }
        if (cur_ir->type_ == kCmdCreateView) {
          is_in_create_view = true;
          break;
        }
        cur_ir = cur_ir->parent_;
      }
      if (!is_in_create_view) {
        continue;
      }

      // Added column mapping for CREATE TABLE/VIEW... v0 AS SELECT...
      // statement.
      if (ordered_all_subquery_ir.size() > 1) {
        // id_column_name should be in the subqueries and already been resolved
        // in the previous loop.
        vector<IR *> all_mentioned_column_vec =
            search_mapped_ir_in_stmt(ir, id_column_name);
        for (IR *cur_men_column_ir : all_mentioned_column_vec) {
          string cur_men_column_str = cur_men_column_ir->str_val_;
          if (findStringIn(cur_men_column_str, ".")) {
            cur_men_column_str = string_splitter(cur_men_column_str, ".")[1];
          }
          m_tables[ir->str_val_].push_back(cur_men_column_str);
          if (is_debug_info) {
            cerr << "Dependency: For table/view: " << ir->str_val_
                 << ", map with column: " << cur_men_column_str << ". \n\n\n";
          }
        }
        if (all_mentioned_column_vec.size() ==
            0) { // For CREATE VIEW x AS SELECT * FROM v0;
          vector<IR *> all_mentioned_tablename =
              search_mapped_ir_in_stmt(ir, id_top_table_name);
          for (IR *cur_men_tablename_ir : all_mentioned_tablename) {
            string cur_men_tablename_str = cur_men_tablename_ir->str_val_;
            const vector<string> &cur_men_column_vec =
                m_tables[cur_men_tablename_str];
            for (const string &cur_men_column_str : cur_men_column_vec) {
              vector<string> &cur_m_table = m_tables[ir->str_val_];
              if (std::find(cur_m_table.begin(), cur_m_table.end(),
                            cur_men_column_str) == cur_m_table.end()) {
                m_tables[ir->str_val_].push_back(cur_men_column_str);
                if (is_debug_info) {
                  cerr << "Dependency: For table/view: " << ir->str_val_
                       << ", map with column: " << cur_men_column_str
                       << ". \n\n\n";
                }
              }
            }
          }
          all_mentioned_tablename = search_mapped_ir_in_stmt(ir, id_table_name);
          for (IR *cur_men_tablename_ir : all_mentioned_tablename) {
            string cur_men_tablename_str = cur_men_tablename_ir->str_val_;
            const vector<string> &cur_men_column_vec =
                m_tables[cur_men_tablename_str];
            for (const string &cur_men_column_str : cur_men_column_vec) {
              vector<string> &cur_m_table = m_tables[ir->str_val_];
              if (std::find(cur_m_table.begin(), cur_m_table.end(),
                            cur_men_column_str) == cur_m_table.end()) {
                m_tables[ir->str_val_].push_back(cur_men_column_str);
                if (is_debug_info) {
                  cerr << "Dependency: For table/view: " << ir->str_val_
                       << ", map with column: " << cur_men_column_str
                       << ". \n\n\n";
                }
              }
            }
          }
        }
      }
    } // for (auto ir : ordered_ir)
  }   // for (vector<IR*>& ordered_ir : ordered_all_subquery_ir)

  if (is_debug_info) {
    cerr << "After fixing: " << root->to_string() << " \n\n\n";
  }

  return true;
}

/* tranverse ir in the order: _right ==> root ==> left_ */

string Mutator::fix(IR *root) {

  string res = "";
  _fix(root, res);
  trim_string(res);

  /*
  ** For debugging purpose, avoid root->to_string() generates a different string
  *from _fix()
  ** The string is identical for the latest commit. However, we cannot guarantee
  *this for kPragmaStatement.
  ** We don't handle and save changes for kPragmaStatement in _fix() and
  *to_string().
  */
  string ir_to_str = root->to_string();
  trim_string(ir_to_str);
  if (res != ir_to_str && !findStringIn(res, "PRAGMA") &&
      !findStringIn(ir_to_str, "PRAGMA")) {
    ofstream error_output;
    error_output.open("./fatal_log.txt");
    error_output << "Error: ir_to_string is not the same as the string "
                    "generated from _fix. \n";
    error_output << "res: \n" << res << endl;
    error_output << "ir_to_string: \n" << ir_to_str << endl;
    error_output.close();
    debug(root, 0);
    FATAL(
        "Error: ir_to_string is not the same as the string generated from _fix. \n\
          _fix() str: %s, to_string() str: %s .\n",
        res.c_str(), ir_to_str.c_str());
  }

  return res;
}

void Mutator::_fix(IR *root, string &res) {

  auto *right_ = root->right_, *left_ = root->left_;
  auto *op_ = root->op_;
  auto type_ = root->type_;
  auto str_val_ = root->str_val_;
  auto id_type_ = root->id_type_;

  if (type_ == kIdentifier && id_type_ == id_database_name) {

    res += "main";
    root->str_val_ = "main";
    return;
  }

  if (type_ == kIdentifier && id_type_ == id_schema_name) {

    res += "sqlite_master";
    root->str_val_ = "sqlite_master";
    return;
  }

  // TODO:: not handle for now.
  if (type_ == kCmdPragma) {
    string key = "";
    int lib_size = cmds_.size();
    if (lib_size != 0) {
      key = cmds_[get_rand_int(lib_size)];
      res += ("PRAGMA " + key);
    } else {
      return;
    }

    int value_size = m_cmd_value_lib_[key].size();
    string value = m_cmd_value_lib_[key][get_rand_int(value_size)];
    if (!value.compare("_int_")) {
      string tmp_value_lib = value_libary[get_rand_int(value_libary.size())];
      if (tmp_value_lib.empty()) {
        tmp_value_lib = "0.0";
      }
      value = string("=") + tmp_value_lib;
    } else if (!value.compare("_empty_")) {
      value = "";
    } else if (!value.compare("_boolean_")) {
      if (get_rand_int(2) == 0)
        value = "=false";
      else
        value = "=true";
    } else {
      value = "=" + value;
    }
    if (!value.empty())
      res += value + ";";
    return;
  }

  if (type_ == kStringLiteral) {
    string s;
    /* 2/3 chances, uses already seen string. */
    if (used_string_library.size() != 0 && get_rand_int(3) < 2) {
      s = used_string_library[get_rand_int(used_string_library.size())];
    } else {
      s = string_libary[get_rand_int(string_libary.size())];
    }
    res += "'" + s + "'";
    root->str_val_ = "'" + s + "'";
    return;
  }

  if (type_ == kIntegerLiteral || type_ == kFloatLiteral) {
    string s;
    /* 2/3 chances, uses already seen value. */
    if (used_value_libary.size() != 0 && get_rand_int(3) < 2) {
      s = used_value_libary[get_rand_int(used_value_libary.size())];
    } else if (get_rand_int(3) == 1){
      s = value_libary[get_rand_int(value_libary.size())];
    } else {
      s = to_string(get_rand_int(100));
    }
    if (s.empty()) {
      s = to_string(get_rand_int(100));
    }
    used_value_libary.push_back(s);
    res += s;
    root->str_val_ = s;
    return;
  }

  if (!str_val_.empty()) {
    res += str_val_;
    return;
  }

  if (op_ && !(op_->prefix_.empty())) {
    res += op_->prefix_;
    res += " ";
  }

  if (left_) {
    _fix(left_, res);
    res += " ";
  }

  if (op_ && !(op_->middle_.empty())) {
    res += op_->middle_;
    res += " ";
  }

  if (right_) {
    _fix(right_, res);
    res += " ";
  }

  if (op_ && !(op_->suffix_.empty()))
    res += op_->suffix_;

  return;
}

void Mutator::resolve_drop_statement(IR *cur_trans_stmt, bool is_debug_info) {
  IRTYPE stmt_type =
      this->p_oracle->ir_wrapper.get_cur_stmt_type(cur_trans_stmt);
  if (stmt_type == kCmdDropTable || stmt_type == kCmdDropView) {
    vector<IR *> drop_tablename_vec =
        search_mapped_ir_in_stmt(cur_trans_stmt, id_top_table_name);
    for (IR *drop_table_ir : drop_tablename_vec) {
      string drop_table_str = drop_table_ir->str_val_;
      m_tables.erase(drop_table_str);
      m_table2index.erase(drop_table_str);
      v_table_names.erase(std::remove(v_table_names.begin(),
                                      v_table_names.end(), drop_table_str),
                          v_table_names.end());
      if (is_debug_info) {
        cerr << "Dependency: In resolve_drop_statement, removing table_name: "
             << drop_table_str << " from v_table_names. \n\n\n";
      }
    }
    drop_tablename_vec =
        search_mapped_ir_in_stmt(cur_trans_stmt, id_table_name);
    for (IR *drop_table_ir : drop_tablename_vec) {
      string drop_table_str = drop_table_ir->str_val_;
      m_tables.erase(drop_table_str);
      m_table2index.erase(drop_table_str);
      v_table_names.erase(std::remove(v_table_names.begin(),
                                      v_table_names.end(), drop_table_str),
                          v_table_names.end());
      if (is_debug_info) {
        cerr << "Dependency: In resolve_drop_statement, removing table_name: "
             << drop_table_str << " from v_table_names. \n\n\n";
      }
    }
  } else if (stmt_type == kCmdDropIndex) {
    vector<IR *> drop_indexname_vec =
        search_mapped_ir_in_stmt(cur_trans_stmt, id_index_name);
    for (IR *drop_indexname_ir : drop_indexname_vec) {
      string drop_indexname_str = drop_indexname_ir->str_val_;
      for (auto iter = m_table2index.begin(); iter != m_table2index.end();
           iter++) {
        vector<string> &table2index_vec = iter->second;
        table2index_vec.erase(std::remove(table2index_vec.begin(),
                                          table2index_vec.end(),
                                          drop_indexname_str),
                              table2index_vec.end());
        if (is_debug_info) {
          cerr << "Dependency: In resolve_drop_statement, removing index: "
               << drop_indexname_str << " from table2index_vec. \n\n\n";
        }
      }
    }
  }
}

void Mutator::resolve_alter_statement(IR *cur_trans_stmt, bool is_debug_info) {

  if (cur_trans_stmt->type_ == kCmdAlterTableAddColumn) {
    // Add Table Column name.
    IR *tablename_ir = cur_trans_stmt->left_->left_->left_;
    string tablename_str = tablename_ir->to_string();
    vector<string> tmp_split = string_splitter(tablename_str, ".");
    if (tmp_split.size() > 1) {
      tablename_str = tmp_split.back();
    }

    IR *columnname_ir =
        cur_trans_stmt->left_->right_;        // TypeColumnName
    string columnname_str = columnname_ir->left_->str_val_; // TypeNm

    m_tables[tablename_str].push_back(columnname_str);
    if (is_debug_info) {
      cerr << "Dependency: In resolve_alter_statement, adding column_name: "
           << columnname_str << "\n\n\n";
    }

    return;
  } else if (cur_trans_stmt->type_ == kCmdAlterTableDropColumn) {
    // Drop Table Column name.

    IR *tablename_ir = cur_trans_stmt->left_->left_;
    string tablename_str = tablename_ir->to_string();
    vector<string> tmp_split = string_splitter(tablename_str, ".");
    if (tmp_split.size() > 1) {
      tablename_str = tmp_split.back();
    }

    IR *columnname_ir = cur_trans_stmt->right_;
    string columnname_str = columnname_ir->str_val_;

    vector<string> &table2column_vec = m_tables[tablename_str];
    table2column_vec.erase(std::remove(table2column_vec.begin(),
                                       table2column_vec.end(), columnname_str),
                           table2column_vec.end());

    if (is_debug_info) {
      cerr << "Dependency: In resolve_alter_statement, dropping column_name: "
           << columnname_str << "\n\n\n";
    }

    return;
  } else if (cur_trans_stmt->type_ == kCmdAlterTableRenameColumn) {
    // Rename Column name.
    IR *tablename_ir = cur_trans_stmt->left_->left_->left_;
    string tablename_str = tablename_ir->to_string();
    vector<string> tmp_split = string_splitter(tablename_str, ".");
    if (tmp_split.size() > 1) {
      tablename_str = tmp_split.back();
    }

    IR *rov_columnname_ir = cur_trans_stmt->left_->right_;
    string rov_columnname_str = rov_columnname_ir->str_val_;

    vector<string> &table2column_vec = m_tables[tablename_str];
    table2column_vec.erase(std::remove(table2column_vec.begin(),
                                       table2column_vec.end(),
                                       rov_columnname_str),
                           table2column_vec.end());

    if (is_debug_info) {
      cerr << "Dependency: In resolve_alter_statement, dropping column_name: "
           << rov_columnname_str << "\n\n\n";
    }

    IR *new_columnname_ir = cur_trans_stmt->right_;
    string new_columnname_str = gen_column_name();
    new_columnname_ir->str_val_ = new_columnname_str;
    new_columnname_ir->id_type_ = id_create_column_name;

    m_tables[tablename_str].push_back(new_columnname_str);

    if (is_debug_info) {
      cerr << "Dependency: In resolve_alter_statement, adding column_name: "
           << new_columnname_str << "\n\n\n";
    }

    return;

  } else if (cur_trans_stmt->type_ == kCmdAlterTableRename) {
    // Rename Table Name.
    IR *ori_table_ir = cur_trans_stmt->left_;
    string ori_table_str = ori_table_ir->to_string();

    IR *new_table_ir = cur_trans_stmt->right_;
    string new_table_str = new_table_ir->to_string();

    vector<string> tmp_saved;
    for (auto iter = m_tables.begin(); iter != m_tables.end(); iter++) {
      if (iter->first == ori_table_str) {
        tmp_saved = iter->second;
        m_tables.erase(ori_table_str);
        break;
      }
    }
    m_tables[new_table_str] = tmp_saved;
    tmp_saved.clear();

    for (auto iter = m_table2index.begin(); iter != m_table2index.end();
         iter++) {
      if (iter->first == ori_table_str) {
        tmp_saved = iter->second;
        m_table2index.erase(ori_table_str);
        break;
      }
    }
    m_table2index[new_table_str] = tmp_saved;

    v_table_names.erase(std::remove(v_table_names.begin(),
                                    v_table_names.end(),
                                    ori_table_str),
                        v_table_names.end());
  }

  return;
}

unsigned int Mutator::calc_node(IR *root) {
  unsigned int res = 0;
  if (root->left_)
    res += calc_node(root->left_);
  if (root->right_)
    res += calc_node(root->right_);

  return res + 1;
}

string Mutator::extract_struct(string query) {

  vector<IR *> original_ir_tree = parse_query_str_get_ir_set(query);

  string res = "";

  if (original_ir_tree.size() > 0) {

    IR *root = original_ir_tree[original_ir_tree.size() - 1];
    res = extract_struct(root);
    root->deep_drop();
  }

  return res;
}

string Mutator::extract_struct(IR *root) {

  string res = "";
  _extract_struct(root, res);
  trim_string(res);
  return res;
}

void Mutator::_extract_struct(IR *root, string &res) {

  static int counter = 0;
  auto *right_ = root->right_, *left_ = root->left_;
  auto *op_ = root->op_;
  auto type_ = root->type_;
  auto str_val_ = root->str_val_;

  if (root->id_type_ == id_function_name) {
    res += str_val_;
    return;
  }

  if (root->id_type_ == id_pragma_name || root->id_type_ == id_pragma_value ||
      root->id_type_ == id_collation_name) {
    res += str_val_;
    return;
  }

  if (root->id_type_ != id_whatever && root->id_type_ != id_vtab_module_name) {
    res += "y";
    root->str_val_ = "y";
    return;
  }

  if (type_ == kStringLiteral) {
    string str_val = str_val_;
    str_val.erase(std::remove(str_val.begin(), str_val.end(), '\''),
                  str_val.end());
    str_val.erase(std::remove(str_val.begin(), str_val.end(), '"'),
                  str_val.end());
    string magic_string = magic_string_generator(str_val);
    unsigned long h = hash(magic_string);
    if (string_libary_hash_.find(h) == string_libary_hash_.end()) {

      string_libary.push_back(magic_string);
      string_libary_hash_.insert(h);
    }
    res += "'y'";
    root->str_val_ = "'y'";
    return;
  }

  if (type_ == kFloatLiteral || type_ == kIntegerLiteral) {
    unsigned long h = hash(root->str_val_);
    if (value_library_hash_.find(h) == value_library_hash_.end() &&
        !(root->str_val_.empty())) {
      value_libary.push_back(root->str_val_);
      value_library_hash_.insert(h);
    }
    res += "10";
    root->str_val_ = "10";
    return;
  }

  //  if (type_ == kFilePath) {
  //    res += "'file_name'";
  //    root->str_val_ = "'file_name'";
  //    return;
  //  }

  if (!str_val_.empty()) {
    res += str_val_;
    return;
  }

  if (op_ && !(op_->prefix_.empty())) {
    res += op_->prefix_;
    res += " ";
  }

  if (left_) {
    _extract_struct(left_, res);
    res += " ";
  }

  if (op_ && !(op_->middle_.empty())) {
    res += op_->middle_;
    res += " ";
  }

  if (right_) {
    _extract_struct(right_, res);
    res += " ";
  }

  if (op_ && !(op_->suffix_.empty())) {
    res += op_->suffix_;
  }

  return;
}

void Mutator::reset_database() {
  m_tables.clear();
  v_table_names.clear();
  v_fts_vtable_names.clear();
  m_table2index.clear();
  m_table2alias_single.clear();
  v_table_names_single.clear();
  v_create_table_names_single.clear();
  v_alias_names_single.clear();

  m_tables_with_tmp.clear();
  v_create_table_names_single_with_tmp.clear();
  v_create_column_names_single_with_tmp.clear();

  used_string_library.clear();
  used_value_libary.clear();
}

void Mutator::reset_database_single_stmt() {
  v_table_names_single.clear();
  v_create_table_names_single.clear();
  v_alias_names_single.clear();
  m_table2alias_single.clear();

  m_tables_with_tmp.clear();
  v_create_table_names_single_with_tmp.clear();
  v_create_column_names_single_with_tmp.clear();

  v_window_name_single.clear();
}

// Return use_temp or not.
bool Mutator::get_select_str_from_lib(string &select_str) {
  /* For 1/2 chance, grab one query from the oracle library, and return.
   * For 1/2 chance, take the template from the p_oracle and return.
   */
  bool is_succeed = false;

  while (!is_succeed) { // Potential dead loop. Only escape through return.
    bool use_temp = false;
    int query_method = get_rand_int(2);
    if (all_valid_pstr_vec.size() > 0 && query_method == 0) {
      /* Pick the query from the lib, pass to the mutator. */
      if (use_cri_val && all_cri_valid_pstr_vec.size() > 0 &&
          get_rand_int(3) < 2) {
        select_str = *(all_cri_valid_pstr_vec[get_rand_int(
            all_cri_valid_pstr_vec.size())]);

      } else {
        select_str =
            *(all_valid_pstr_vec[get_rand_int(all_valid_pstr_vec.size())]);
      }
      if (select_str.empty()) {
        continue;
      }
      use_temp = false;

    } else {
      /* get on randomly generated query from the RSG module. */
      if (!disable_rsg_generator) {
        select_str = this->rsg_generate_valid(kCmdSelect) + "; ";
        // Debug purpose
        vector<IR *> v_tmp_check = this->parse_query_str_get_ir_set(select_str);
        if (v_tmp_check.size() == 0) {
          this->rsg_exec_failed_helper();
        } else {
          v_tmp_check.back()->deep_drop();
        }
        num_rsg_gen++;
      }

      if (select_str.empty()) {
        /* Pick the query from the template, pass to the mutator. */
        select_str = p_oracle->get_temp_select_stmts();
        use_temp = true;
      }
    }

    trim_string(select_str);
    return use_temp;
  }
  fprintf(stderr, "*** FATAL ERROR: Unexpected code execution in the "
                  "Mutator::get_valid_str_from_lib function. \n");
  fflush(stderr);
  abort();
}

void Mutator::fix_common_rsg_errors(IR *root) {
  // For CREATE TABLE statement, if has WITHOUT ROWID, add PRIMARY KEY.
  if (
      p_oracle->ir_wrapper.is_exist_without_rowid(root) &&
      !(p_oracle->ir_wrapper.is_exist_primary_key(root))
  ) {
    vector<IR*> v_candidate_node = p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(root, kCarglist, false);
    if (v_candidate_node.size() != 0) {
      IR* candidate_node = v_candidate_node.front();
      candidate_node->str_val_ += " PRIMARY KEY ";
    }
  }
  return;
}

string Mutator::rsg_generate_valid(const IRTYPE type) {

  if (type == kCmd) {
    return this->rsg_generate_valid("cmd");
  } else if (type == kCmdSelect) {
    return this->rsg_generate_valid("select");
  }

  return "";
}

string Mutator::rsg_generate_valid(const string type) {

  for (int i = 0; i < 100; i++) {
    string tmp_query_str = rsg_generate(type) + ";";
#ifdef DEBUG
    cerr << "\n\n\n" << type << ", Getting tmp_query_str: " << tmp_query_str << "\n\n\n";
#endif
    vector<IR *> ir_vec = this->parse_query_str_get_ir_set(tmp_query_str);
    if (ir_vec.size() == 0) {
#ifdef DEBUG
      cerr << "\n\n\n" << type << ", getting tmp_query_str: " << tmp_query_str << "\n";
      cerr << "Rejected. \n\n\n";
#endif
//      cerr << "\n\n\nrsg_generate_valid empty. \n\n\n";
      this->rsg_exec_clear_chosen_expr();
      continue;
    }
    fix_common_rsg_errors(ir_vec.back());
    tmp_query_str = ir_vec.back()->to_string();
    ir_vec.back()->deep_drop();

    if (findStringIn(tmp_query_str, "CREATE VIEW")) {
      tmp_query_str += "\nSELECT * FROM forced_view;";
    }
#ifdef DEBUG
    cerr << "\n\n\n" << type << ", returned tmp-query-str: " << tmp_query_str << "\n\n\n";
#endif
    return tmp_query_str;
  }

  return "";
}

string Mutator::construct_rand_pragma_stmt() {
  string res_str = "PRAGMA ";
  string cur_pragma_key;

  int lib_size = cmds_.size();
  if (lib_size != 0) {
    cur_pragma_key = cmds_[get_rand_int(lib_size)];
    res_str += cur_pragma_key;
  } else {
    return "";
  }

  if (m_cmd_value_lib_[cur_pragma_key].size() != 0) {
    string value = vector_rand_ele(m_cmd_value_lib_[cur_pragma_key]);
    if (value == "_int_") {
      if (value_libary.size() != 0) {
        res_str += "=" + value_libary[get_rand_int(value_libary.size())];
      } else {
        res_str += "=" + to_string(get_rand_int(100));
      }
    } else if (value == "_empty_") {
      res_str += "";
    } else if (value == "_boolean_") {
      if (get_rand_int(2) == 0) {
        res_str += "=false";
      } else {
        res_str += "=true";
      }
    } else {
      res_str += "=" + value;
    }
  } else {
    // No value
    res_str += "";
  }

  res_str += ";";

  return res_str;

}