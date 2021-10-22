#include "./postgre_tlp.h"
#include "../include/mutate.h"
#include <iostream>

#include <regex>
#include <string>

int SQL_TLP::count_valid_stmts(const string &input) {
  int norec_select_count = 0;
  vector<string> queries_vector = string_splitter(input, ";");
  for (string &query : queries_vector)
    if (this->is_oracle_valid_stmt(query))
      norec_select_count++;
  return norec_select_count;
}

bool SQL_TLP::is_oracle_valid_stmt(const string &query) {
  return false;
}

bool SQL_TLP::is_oracle_select_stmt(IR* cur_stmt) {
  if (ir_wrapper.is_exist_group_by(cur_stmt) || ir_wrapper.is_exist_having(cur_stmt) || ir_wrapper.is_exist_limit(cur_stmt)) {
    return false;
  }

  // Remove UNION ALL, UNION, EXCEPT and INTERCEPT
  int num_selectclause = ir_wrapper.get_num_selectclause(cur_stmt);
  if (num_selectclause > 1) {
    // cerr << "In func: SQL_TLP::is_oracle_select_stmt(IR*), not a oracle_select because multiple selectclause detected. \n\n\n";
    return false;
  }

  if (
    ir_wrapper.is_exist_ir_node_in_stmt_with_type(cur_stmt, kSelectStmt, false) &&
    ir_wrapper.is_exist_ir_node_in_stmt_with_type(cur_stmt, kFromClause, false) &&
    ir_wrapper.is_exist_ir_node_in_stmt_with_type(cur_stmt, kWhereClause, false) &&
    ir_wrapper.get_num_expr_list_in_select_clause(cur_stmt) == 1
  ) {
      return true;
  }
  return false;

}

bool SQL_TLP::mark_all_valid_node(vector<IR *> &v_ir_collector) {
  bool is_mark_successfully = false;

  IR *root = v_ir_collector[v_ir_collector.size() - 1];
  IR *par_ir = nullptr;
  IR *par_par_ir = nullptr;
  IR *par_par_par_ir = nullptr; // If we find the correct selectnoparen, this
                                // should be the statementlist.
  for (auto ir : v_ir_collector) {
    if (ir != nullptr)
      ir->is_node_struct_fixed = false;
  }
  for (auto ir : v_ir_collector) {
    if (ir != nullptr && ir->type_ == kSelectClause) {
      par_ir = root->locate_parent(ir);
      if (par_ir != nullptr && par_ir->type_ == kSelectStmt) {
        par_par_ir = root->locate_parent(par_ir);
        if (par_par_ir != nullptr && par_par_ir->type_ == kStmt) {
          par_par_par_ir = root->locate_parent(par_par_ir);
          if (par_par_par_ir != nullptr &&
              par_par_par_ir->type_ == kStmt) {
            g_mutator->extract_struct(ir);
            string query = ir->to_string();
            if (!(this->is_oracle_valid_stmt(query)))
              continue; // Not norec compatible. Jump to the next ir.
            query.clear();
            is_mark_successfully = this->mark_node_valid(ir);
            // cerr << "\n\n\nThe marked norec ir is: " <<
            // this->extract_struct(ir) << " \n\n\n";
            par_ir->is_node_struct_fixed = true;
            par_par_ir->is_node_struct_fixed = true;
            par_par_par_ir->is_node_struct_fixed = true;
          }
        }
      }
    }
  }

  return is_mark_successfully;
}

vector<IR*> SQL_TLP::post_fix_transform_select_stmt(IR* cur_stmt, unsigned multi_run_id){
  vector<IR*> trans_IR_vec;
  cur_stmt->parent_ = NULL;


  IR* first_stmt = cur_stmt->deep_copy();
  vector<IR*> where_clause_in_first_vec = ir_wrapper.get_ir_node_in_stmt_with_type(first_stmt, kWhereClause, false);
  for (IR* where_clause_in_first : where_clause_in_first_vec) {
    first_stmt->detach_node(where_clause_in_first);
    where_clause_in_first->deep_drop();
  }
  trans_IR_vec.push_back(first_stmt); /* Save the first oracle stmt. */ 
  

  /* Retrive the kSimpleSelect, that is used to construct the TLP stmt. */
  vector<IR*> src_simple_select_vec_ = ir_wrapper.get_ir_node_in_stmt_with_type(cur_stmt, kSimpleSelect, false);
  if (src_simple_select_vec_.size() == 0) {
    first_stmt->deep_drop();
    cerr << "Error: Failed to detect the kSimpleSelect node from the mutated oracle select stmt. Return failure. \n\n\n";
    vector<IR*> tmp; return tmp;
  }
  /* If the logic has no error, should always pick the first one. Deep copid on every used. */
  IR* src_simple_select_ = src_simple_select_vec_[0]; 

  /* modify the first part of TLP. Put the Whereclause into a brackets. */
  IR* operand_ir_ = new IR(kOperand, OP3("(", ")", ""));
  IR* expr_ir_ = new IR(kExpr, OP3("", "", ""), operand_ir_);  
  
  IR* first_part_TLP = src_simple_select_->deep_copy();
  vector<IR*> v_where_first_stmt = ir_wrapper.get_ir_node_in_stmt_with_type(first_part_TLP, kWhereClause, false);
  if (v_where_first_stmt.size() == 0) {
    first_stmt->deep_drop();
    first_part_TLP->deep_drop();
    cerr << "Error: Failed to detect the kWhereClause node from the mutated oracle select stmt. Return failure. \n\n\n";
    vector<IR*> tmp; return tmp;
  }
  IR* where_first_stmt_ = v_where_first_stmt[0];
  if (where_first_stmt_->left_ == NULL) {
    first_stmt->deep_drop();
    first_part_TLP->deep_drop();
    cerr << "Error: The retrived where_first_stmt_ doesn't have the left_ child node. \n\n\n";
  }
  IR* where_first_expr_ = where_first_stmt_->left_;
  
  first_part_TLP->swap_node(where_first_expr_, expr_ir_);
  operand_ir_->update_left(where_first_expr_);

  /* Modify the second part of TLP. Pu the Whereclause into (Not (kWhereClause)) */
  IR* operand_0 = new IR(kExpr, OP3("(", ")", "")); // For brackets
  IR* unary_expr_ = new IR(kUnaryExpr, OP3("NOT", "", ""), operand_0); // NOT (kWhereClause)
  IR* operand_1 = new IR(kExpr, OP3("(", ")", ""), unary_expr_); // For the second brackets. (NOT (kWhereClause))
  IR* expr_ = new IR(kExpr, OP0(), operand_1);

  IR* second_part_TLP = src_simple_select_->deep_copy();
  /* vector size has been double checked before */
  IR* where_second_stmt_ = ir_wrapper.get_ir_node_in_stmt_with_type(second_part_TLP, kWhereClause, false)[0];
  IR* where_second_expr_ = where_second_stmt_->left_;

  second_part_TLP->swap_node(where_second_expr_, expr_);
  operand_0->update_left(where_second_expr_);

  /* Modify the third part of TLP. Put the WhereClause into ((kWhereClause) IS NULL) */
  operand_0 = new IR(kOperand, OP3("(", ")", "")); // For brackets
  unary_expr_ = new IR(kUnaryExpr, OP3("", "IS NULL", ""), operand_0); // (kWhereClause) IS NULL
  operand_1 = new IR(kExpr, OP3("(", ")", ""), unary_expr_); // For the second brackets. ((kWhereClause) IS NULL)
  expr_ = new IR(kExpr, OP0(), operand_1);

  IR* third_part_TLP = src_simple_select_->deep_copy();
  /* vector size has been double checked before */
  IR* where_third_stmt_ = ir_wrapper.get_ir_node_in_stmt_with_type(third_part_TLP, kWhereClause, false)[0];
  IR* where_third_expr_ = where_third_stmt_->left_;

  third_part_TLP->swap_node(where_third_expr_, expr_);
  operand_0->update_left(where_third_expr_);

  /* Finally, reconstruct the whole TLP stmt. */

  vector<IR*> transformed_temp_vec;
  if (get_valid_type(cur_stmt->to_string()) == VALID_STMT_TYPE_TLP::NORM) {
    transformed_temp_vec = g_mutator->parse_query_str_get_ir_set(this->post_fix_temp_UNION_ALL);
  } else {
    transformed_temp_vec = g_mutator->parse_query_str_get_ir_set(this->post_fix_temp_UNION);
  }
  if (transformed_temp_vec.size() == 0) {
    cerr << "Error: parsing the post_fix_temp from SQL_TLP::post_fix_transform_select_stmt returns empty IR vector. \n";
    vector<IR*> tmp; return tmp;
  }

  /* Parse and retrive the IR tree for the TLP template. */
  IR* ori_transformed_temp_ir = transformed_temp_vec.back();
  IR* trans_stmt_ir = ori_transformed_temp_ir->left_->left_->left_->deep_copy();      // Program -> stmtlist -> stmt -> transformed_stmt;
  trans_stmt_ir->parent_ = NULL;
  ori_transformed_temp_ir->deep_drop();

  /* Fill in the three parts of TLP stmt into trans_stmt_ir; */
  vector<IR*> v_dest_select_clause = ir_wrapper.get_ir_node_in_stmt_with_type(trans_stmt_ir, kSelectClause, false);
  /* For the first part */
  IR* dest_simple_select_first = v_dest_select_clause[0]->left_;
  trans_stmt_ir->swap_node(dest_simple_select_first, first_part_TLP);
  dest_simple_select_first->deep_drop();

  /* For the second part */
  IR* dest_simple_select_second = v_dest_select_clause[2]->left_;
  trans_stmt_ir->swap_node(dest_simple_select_second, second_part_TLP);
  dest_simple_select_second->deep_drop();

  /* For the third part */
  IR* dest_simple_select_third = v_dest_select_clause[3]->left_;
  trans_stmt_ir->swap_node(dest_simple_select_third, third_part_TLP);
  dest_simple_select_third->deep_drop();

  /* Save it to the result vector */
  trans_IR_vec.push_back(trans_stmt_ir);

  return trans_IR_vec;

}

void SQL_TLP::rewrite_valid_stmt_from_ori(string &query, string &rew_1,
                                            string &rew_2, string &rew_3,
                                            unsigned multi_run_id) {
}

string SQL_TLP::remove_valid_stmts_from_str(string query) {
  string output_query = "";
  vector<string> queries_vector = string_splitter(query, ";");

  for (auto current_stmt : queries_vector) {
    if (is_str_empty(current_stmt))
      continue;
    if (!is_oracle_valid_stmt(current_stmt))
      output_query += current_stmt + "; ";
  }

  return output_query;
}

void SQL_TLP::compare_results(ALL_COMP_RES &res_out) {

  res_out.final_res = ORA_COMP_RES::Pass;
  bool is_all_err = true;

  vector<VALID_STMT_TYPE_TLP> v_valid_type;
  get_v_valid_type(res_out.cmd_str, v_valid_type);

  if (v_valid_type.size() != res_out.v_res.size()) {
    cerr << "Error: In oracle TLP, v_valid_type.size() is not equals to res_out.v_res.size(). Returns ALL_ERRORS. \n\n\n";
    for (COMP_RES &res : res_out.v_res) {
      res.comp_res = ORA_COMP_RES::Error;
      res.res_int_0 = -1;
      res.res_int_1 = -1;
    }
    res_out.final_res = ORA_COMP_RES::ALL_Error;
    return;
  }

  for (int i = 0; i < res_out.v_res.size(); i++) {
    COMP_RES &res = res_out.v_res[i];
    VALID_STMT_TYPE_TLP cur_stmt_type = v_valid_type[i];
    if (findStringIn(res.res_str_0, "Error") ||
        findStringIn(res.res_str_1, "Error")) {
      res.comp_res = ORA_COMP_RES::Error;
      res.res_int_0 = -1;
      res.res_int_1 = -1;
      continue;
    }
    try {
      if (cur_stmt_type == VALID_STMT_TYPE_TLP::NORM){
       res.res_int_0 = string_splitter(res.res_str_0, "\n").size();
       res.res_int_1 = string_splitter(res.res_str_1, "\n").size();
      } else { // Aggregate Function or GROUP BY. 
        res.res_int_0 = stoi(res.res_str_0);
        res.res_int_1 = stoi(res.res_str_1);
      }
    } catch (std::invalid_argument &e) {
      res.comp_res = ORA_COMP_RES::Error;
      continue;
    } catch (std::out_of_range &e) {
      res.comp_res = ORA_COMP_RES::Error;
      continue;
    }
    is_all_err = false;
    if (res.res_int_0 != res.res_int_1) { // Found mismatched.
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

void SQL_TLP::get_v_valid_type(const string &cmd_str,
                               vector<VALID_STMT_TYPE_TLP> &v_valid_type) {
  /* Look throught first validation stmt's result_1 first */
  size_t begin_idx = cmd_str.find("SELECT 'BEGIN VERI 0';", 0);
  size_t end_idx = cmd_str.find("SELECT 'END VERI 0';", 0);

  while (begin_idx != string::npos) {
    if (end_idx != string::npos) {
      string cur_cmd_str =
          cmd_str.substr(begin_idx + 23, (end_idx - begin_idx - 23));
      begin_idx = cmd_str.find("SELECT 'BEGIN VERI 0';", begin_idx + 23);
      end_idx = cmd_str.find("SELECT 'END VERI 0';", end_idx + 21);

      v_valid_type.push_back(get_valid_type(cur_cmd_str));
    } else {
      break; // For the current begin_idx, we cannot find the end_idx. Ignore
             // the current output.
    }
  }
}

VALID_STMT_TYPE_TLP SQL_TLP::get_valid_type(const string &cur_stmt_str) {
  if (findStringIn(cur_stmt_str, "MIN") ||
      findStringIn(cur_stmt_str, "MAX") ||
      findStringIn(cur_stmt_str, "SUM") ||
      findStringIn(cur_stmt_str, "COUNT") ||
      findStringIn(cur_stmt_str, "GROUP BY") ||
      findStringIn(cur_stmt_str, "AVG")) {
        return VALID_STMT_TYPE_TLP::UNIQ;
  }
  return VALID_STMT_TYPE_TLP::NORM;
}