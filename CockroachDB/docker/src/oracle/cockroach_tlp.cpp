#include "./cockroach_tlp.h"
#include "../include/mutate.h"
#include <iostream>

#include <regex>
#include <string>

bool SQL_TLP::is_oracle_select_stmt(IR *cur_stmt) {

  if (cur_stmt == NULL) {
    // cerr << "Return false because cur_stmt is NULL; \n";
    return false;
  }

  if (cur_stmt->get_ir_type() != TypeSelect) {
    // cerr << "Return false because this is not a SELECT stmt: " <<
    // get_string_by_ir_type(cur_stmt->get_ir_type()) <<  " \n";
    return false;
  }

  if (!g_mutator->check_node_num(cur_stmt, 300)) {
    return false;
  }

  /* Remove cases that missing TypeSelectExpr */
  vector<IR *> v_select_exprs =
      ir_wrapper.get_ir_node_in_stmt_with_type(cur_stmt, TypeSelectExpr, false);
  if (v_select_exprs.size() == 0) {
    // cerr << "Return false because there is no TypeSelectExpr \n\n\n";
    return false;
  }

  /* Remove cases that contains kGroupClause, kHavingClause and kLimitClause */
  vector<IR *> v_group_clause =
      ir_wrapper.get_ir_node_in_stmt_with_type(cur_stmt, TypeGroupBy, false);
  for (IR *group_clause : v_group_clause) {
    if (!group_clause->is_empty()) {
      // cerr << "Return false because of GROUP clause \n";
      return false;
    }
  }

  vector<IR *> v_having_clause =
      ir_wrapper.get_ir_node_in_stmt_with_type(cur_stmt, TypeHaving, false);
  for (IR *having_clause : v_having_clause) {
    if (!having_clause->is_empty()) {
      // cerr << "Return false because of having clause \n";
      return false;
    }
  }

  vector<IR *> v_limit_clause = ir_wrapper.get_ir_node_in_stmt_with_type(
      cur_stmt, TypeLimitCluster, false);
  for (IR *limit_clause : v_limit_clause) {
    if (!limit_clause->is_empty()) {
      // cerr << "Return false because of LIMIT clause \n";
      return false;
    }
  }

  // Ignore stmts with UNION ALL, UNION, EXCEPT and INTERCEPT
  if (ir_wrapper.is_exist_set_operator(cur_stmt)) {
    return false;
  }

  if (ir_wrapper.is_exist_ir_node_in_stmt_with_type(cur_stmt, TypeSelect,
                                                    false) &&
      ir_wrapper.is_exist_ir_node_in_stmt_with_type(cur_stmt, TypeFrom,
                                                    false) &&
      ir_wrapper.is_exist_ir_node_in_stmt_with_type(cur_stmt, TypeWhere,
                                                    false) &&
      ir_wrapper.get_num_select_exprs(cur_stmt) == 1) {

    /* Make sure from clause and where clause are not empty.  */
    IR *from_clause =
        ir_wrapper.get_ir_node_in_stmt_with_type(cur_stmt, TypeFrom, false)[0];
    // The first one should be the parent one.
    if (from_clause->is_empty()) {
      // cerr << "Return false because FROM clause is empty \n";
      return false;
    }

    IR *where_clause =
        ir_wrapper.get_ir_node_in_stmt_with_type(cur_stmt, TypeWhere, false)[0];
    // The first one should be the parent one.
    if (where_clause->is_empty()) {
      // cerr << "Return false because WHERE clause is empty \n";
      return false;
    }

    return true;
  }

  /* Cannot pass the test of kFromClause and kWhereClause. Not compatible.  */
  return false;
}

bool SQL_TLP::mark_all_valid_node(vector<IR *> &v_ir_collector) {
  // TODO::FixLater.
  return true;
}

vector<IR *> SQL_TLP::post_fix_transform_select_stmt(IR *cur_stmt,
                                                     unsigned multi_run_id) {
  vector<IR *> trans_IR_vec;
  cur_stmt->parent_ = NULL;

  /* Directly cut all the extra targetEl inside the select target.
   * Directly delete them on the source cur_stmt tree.
   * */

  vector<IR *> v_target_list_ir = ir_wrapper.get_ir_node_in_stmt_with_type(
      cur_stmt, TypeSelectExprs, false);
  if (v_target_list_ir.size() == 0) {
    trans_IR_vec.clear();
    return trans_IR_vec;
  }
  IR *target_list_ir = v_target_list_ir.front();
  if (target_list_ir->get_ir_type() == TypeExprs &&
      target_list_ir->get_right()) {
    /* Clean all the extra select target clauses, only leave the first one
     * untouched. If this is the first kTargetList, the right sub-node should be
     * empty.
     * */
    target_list_ir->replace_op(OP0());
    IR *extra_targetel_ir = target_list_ir->get_right();
    target_list_ir->update_right(NULL);
    extra_targetel_ir->deep_drop();
  }

  /* Let's take care of the first stmt. Remove (the last?) its kWhereClause */
  IR *first_stmt = cur_stmt->deep_copy();
  vector<IR *> where_clause_in_first_vec =
      ir_wrapper.get_ir_node_in_stmt_with_type(first_stmt, TypeWhere, false);
  // for (IR* where_clause_in_first : where_clause_in_first_vec) {
  if (where_clause_in_first_vec.size() > 0) {
    IR *where_clause_in_first = where_clause_in_first_vec.back();
    first_stmt->detach_node(where_clause_in_first);
    /* Should we directly deep_drop it? Seems fine */
    where_clause_in_first->deep_drop();
  } else {
    first_stmt->deep_drop();
    cerr << "Error: Failed to find kWhereClause in the original stmt.  \n\n\n";
    vector<IR *> tmp;
    return tmp;
  }
  trans_IR_vec.push_back(first_stmt); /* Save the first oracle stmt. */

  /* Construct the second SELECT oracle stmt.  */
  VALID_STMT_TYPE_TLP cur_stmt_TLP_type = get_stmt_TLP_type(cur_stmt);

  /* Ignore unknown cases. */
  if (cur_stmt_TLP_type == VALID_STMT_TYPE_TLP::TLP_UNKNOWN) {
    first_stmt->deep_drop();
    trans_IR_vec.clear();
    return trans_IR_vec;
  }

  /* If WITH clause existed in the SELECT query, remove it and reattach it in
   * the end. */
  vector<IR *> v_with_clause =
      ir_wrapper.get_ir_node_in_stmt_with_type(first_stmt, TypeWith, false);
  IR *saved_with_clause = NULL;
  if (v_with_clause.size() != 0) {
    IR *ori_with_clause = v_with_clause.front();
    IR *ori_with_clause_parent = ori_with_clause->get_parent();
    if (ori_with_clause_parent != NULL) {
      ori_with_clause_parent->swap_node(ori_with_clause, NULL);
      ori_with_clause->parent_ = NULL;
      saved_with_clause = ori_with_clause->deep_copy();
      ori_with_clause->deep_drop();
    }
  }

  switch (cur_stmt_TLP_type) {
  case VALID_STMT_TYPE_TLP::AGGR_AVG: {
    IR *transformed_stmt = transform_aggr(cur_stmt, true, cur_stmt_TLP_type);
    trans_IR_vec.push_back(transformed_stmt);
  } break;
    //    case VALID_STMT_TYPE_TLP::AGGR_COUNT: {
    //      IR* transformed_stmt = transform_aggr(cur_stmt, true,
    //      cur_stmt_TLP_type); trans_IR_vec.push_back(transformed_stmt);
    //    }
    //      break;
  case VALID_STMT_TYPE_TLP::AGGR_MAX: {
    IR *transformed_stmt = transform_aggr(cur_stmt, true, cur_stmt_TLP_type);
    if (saved_with_clause != NULL && transformed_stmt != NULL) {
      transformed_stmt =
          new IR(TypeStmt, OP0(), saved_with_clause, transformed_stmt);
    }
    trans_IR_vec.push_back(transformed_stmt);
  } break;
  case VALID_STMT_TYPE_TLP::AGGR_MIN: {
    IR *transformed_stmt = transform_aggr(cur_stmt, true, cur_stmt_TLP_type);
    if (saved_with_clause != NULL && transformed_stmt != NULL) {
      transformed_stmt =
          new IR(TypeStmt, OP0(), saved_with_clause, transformed_stmt);
    }
    trans_IR_vec.push_back(transformed_stmt);
  } break;
  case VALID_STMT_TYPE_TLP::AGGR_SUM: {
    IR *transformed_stmt = transform_aggr(cur_stmt, true, cur_stmt_TLP_type);
    if (saved_with_clause != NULL && transformed_stmt != NULL) {
      transformed_stmt =
          new IR(TypeStmt, OP0(), saved_with_clause, transformed_stmt);
    }
    trans_IR_vec.push_back(transformed_stmt);
  } break;
  case VALID_STMT_TYPE_TLP::DISTINCT: {
    IR *transformed_stmt =
        transform_non_aggr(cur_stmt, false, cur_stmt_TLP_type);
    if (saved_with_clause != NULL && transformed_stmt != NULL) {
      transformed_stmt =
          new IR(TypeStmt, OP0(), saved_with_clause, transformed_stmt);
    }
    trans_IR_vec.push_back(transformed_stmt);
  } break;
  case VALID_STMT_TYPE_TLP::HAVING: {
    IR *transformed_stmt =
        transform_non_aggr(cur_stmt, true, cur_stmt_TLP_type);
    if (saved_with_clause != NULL && transformed_stmt != NULL) {
      transformed_stmt =
          new IR(TypeStmt, OP0(), saved_with_clause, transformed_stmt);
    }
    trans_IR_vec.push_back(transformed_stmt);
  } break;
  case VALID_STMT_TYPE_TLP::GROUP_BY: {
    IR *transformed_stmt =
        transform_non_aggr(cur_stmt, false, cur_stmt_TLP_type);
    if (saved_with_clause != NULL && transformed_stmt != NULL) {
      transformed_stmt =
          new IR(TypeStmt, OP0(), saved_with_clause, transformed_stmt);
    }
    trans_IR_vec.push_back(transformed_stmt);
  } break;
  case VALID_STMT_TYPE_TLP::NORMAL: {
    IR *transformed_stmt =
        transform_non_aggr(cur_stmt, true, cur_stmt_TLP_type);
    if (saved_with_clause != NULL && transformed_stmt != NULL) {
      transformed_stmt =
          new IR(TypeStmt, OP0(), saved_with_clause, transformed_stmt);
    }
    trans_IR_vec.push_back(transformed_stmt);
  } break;
  default:
    first_stmt->deep_drop();
    if (saved_with_clause != NULL) {
      saved_with_clause->deep_drop();
    }
    trans_IR_vec.clear();
    return trans_IR_vec;
  }
  if (trans_IR_vec[1] != NULL) {
    return trans_IR_vec;
  } else {
    // cerr << "Debug: for cur_stmt: " << cur_stmt->to_string() << ". Failed to
    // transform. \n\n\n";
    first_stmt->deep_drop();
    trans_IR_vec.clear();
    if (saved_with_clause != NULL) {
      saved_with_clause->deep_drop();
    }
    return trans_IR_vec;
  }
}

bool SQL_TLP::compare_norm(COMP_RES &res) {

  string &res_a = res.res_str_0;
  string &res_b = res.res_str_1;
  int &res_a_int = res.res_int_0;
  int &res_b_int = res.res_int_1;

  if (findStringIn(res_a, "ERROR") || findStringIn(res_a, "pq: ") ||
      findStringIn(res_a, "ERROR") || findStringIn(res_b, "pq: ")) {
    res.comp_res = ORA_COMP_RES::Error;
    return true;
  }

  res_a_int = 0;
  res_b_int = 0;

  vector<string> v_res_a = string_splitter(res_a, '\n');
  vector<string> v_res_b = string_splitter(res_b, '\n');

  if (v_res_a.size() > 50 || v_res_b.size() > 50) {
    res.comp_res = ORA_COMP_RES::Error;
    return true;
  }

  /* Remove NULL results */
  for (string &r : v_res_a) {
    if (is_str_empty(r))
      res_a_int--;
  }

  for (string &r : v_res_b) {
    if (is_str_empty(r))
      res_b_int--;
  }

  v_res_a.clear();
  v_res_b.clear();

  res_a_int += std::count(res_a.begin(), res_a.end(), '\n');
  res_b_int += std::count(res_b.begin(), res_b.end(), '\n');

  /* For case that the first stmt return NULL, but the second stmt returns all
   * 0. */
  if (res_a_int == 0) {
    bool is_all_zero = true;
    for (string &r : v_res_b) {
      if (r != "0") {
        is_all_zero = false;
        break;
      }
    }
    if (is_all_zero) {
      res.comp_res = ORA_COMP_RES::Pass;
      return false;
    }
  }

  if (res_a_int != res_b_int) { // Found inconsistent.
    // cerr << "NORMAL Found mismatched: " << "res_a: " << res_a << "res_b: " <<
    // res_b << " res_a_int: " << res_a_int << "res_b_int: " << res_b_int <<
    // endl;
    res.comp_res = ORA_COMP_RES::Fail;
    return false;
  }
  res.comp_res = ORA_COMP_RES::Pass;
  return false;
}

bool SQL_TLP::compare_uniq(COMP_RES &res) {

  string &res_a = res.res_str_0;
  string &res_b = res.res_str_1;
  int &res_a_int = res.res_int_0;
  int &res_b_int = res.res_int_1;

  if (findStringIn(res_a, "ERROR") || findStringIn(res_b, "ERROR")) {
    res.comp_res = ORA_COMP_RES::Error;
    return true;
  }

  res_a_int = 0;
  res_b_int = 0;

  vector<string> v_res_a = string_splitter(res_a, '\n');
  vector<string> v_res_b = string_splitter(res_b, '\n');

  if (v_res_a.size() > 50 || v_res_b.size() > 50) {
    res.comp_res = ORA_COMP_RES::Error;
    return true;
  }

  set<string> uniq_rows;

  /* Remove NULL results */
  for (string &r : v_res_a) {
    if (is_str_empty(r)) {
      res_a_int--;
    } else if (uniq_rows.find(r) !=
               uniq_rows.end()) { /* Remove duplicated results. */
      res_a_int--;
    } else {
      uniq_rows.insert(r);
    }
  }
  uniq_rows.clear();

  for (string &r : v_res_b) {
    if (is_str_empty(r)) {
      res_b_int--;
    } else if (uniq_rows.find(r) !=
               uniq_rows.end()) { /* Remove duplicated results. */
      res_b_int--;
    } else {
      uniq_rows.insert(r);
    }
  }
  uniq_rows.clear();

  res_a_int += std::count(res_a.begin(), res_a.end(), '\n');
  res_b_int += std::count(res_b.begin(), res_b.end(), '\n');

  /* For case that the first stmt return NULL, but the second stmt returns all
   * 0. */
  if (res_a_int == 0) {
    bool is_all_zero = true;
    for (string &r : v_res_b) {
      if (r != "0") {
        is_all_zero = false;
        break;
      }
    }
    if (is_all_zero) {
      res.comp_res = ORA_COMP_RES::Pass;
      return false;
    }
  }

  if (res_a_int != res_b_int) { // Found inconsistent.
    // cerr << "NORMAL Found mismatched: " << "res_a: " << res_a << "res_b: " <<
    // res_b << " res_a_int: " << res_a_int << "res_b_int: " << res_b_int <<
    // endl;
    res.comp_res = ORA_COMP_RES::Fail;
    return false;
  }
  res.comp_res = ORA_COMP_RES::Pass;
  return false;
}

/* Handle MIN valid stmt: SELECT MIN(*) FROM ...; and MAX valid stmt: SELECT
 * MAX(*) FROM ...;  */
bool SQL_TLP::compare_aggr(COMP_RES &res) {
  string &res_a = res.res_str_0;
  string &res_b = res.res_str_1;
  int &res_a_int = res.res_int_0;
  int &res_b_int = res.res_int_1;

  if (findStringIn(res_a, "ERROR") || findStringIn(res_b, "ERROR")) {
    res.comp_res = ORA_COMP_RES::Error;
    return true;
  }

  try {
    res_a_int = stoi(res.res_str_0);
    res_b_int = stoi(res.res_str_1);
  } catch (std::invalid_argument &e) {
    res.comp_res = ORA_COMP_RES::Error;
    return true;
  } catch (std::out_of_range &e) {
    res.comp_res = ORA_COMP_RES::Error;
    return true;
  } catch (const std::exception &e) {
    res.comp_res = ORA_COMP_RES::Error;
    return true;
  }

  if (res_a_int != res_b_int) {
    res.comp_res = ORA_COMP_RES::Fail;
  } else {
    res.comp_res = ORA_COMP_RES::Pass;
  }

  return false;
}

void SQL_TLP::compare_results(ALL_COMP_RES &res_out) {

  res_out.final_res = ORA_COMP_RES::Pass;
  bool is_all_err = true;

  vector<VALID_STMT_TYPE_TLP> v_valid_type;
  get_v_valid_type(res_out.cmd_str, v_valid_type);

  if (v_valid_type.size() != res_out.v_res.size()) {
    cerr << "Error: In oracle TLP, v_valid_type.size() is not equals to "
            "res_out.v_res.size(). Returns ALL_ERRORS. \n\n\n";
    for (COMP_RES &res : res_out.v_res) {
      res.comp_res = ORA_COMP_RES::Error;
      res.res_int_0 = -1;
      res.res_int_1 = -1;
    }
    res_out.final_res = ORA_COMP_RES::ALL_Error;
    return;
  }

  int i = 0;
  for (COMP_RES &res : res_out.v_res) {
    switch (v_valid_type[i++]) {
    case VALID_STMT_TYPE_TLP::NORMAL:
      /* Handle normal valid stmt: SELECT * FROM ...; */
      if (!compare_norm(res)) {
        is_all_err = false;
      }
      break; // Break the switch

    /* Compare unique results */
    case VALID_STMT_TYPE_TLP::DISTINCT:
      [[fallthrough]];
    case VALID_STMT_TYPE_TLP::GROUP_BY:
      compare_uniq(res);
      break;

    /* Compare concret values */
    case VALID_STMT_TYPE_TLP::AGGR_AVG:
      [[fallthrough]];
    // case VALID_STMT_TYPE_TLP::AGGR_COUNT:
    //   [[fallthrough]];
    case VALID_STMT_TYPE_TLP::AGGR_MAX:
      [[fallthrough]];
    case VALID_STMT_TYPE_TLP::AGGR_MIN:
      [[fallthrough]];
    case VALID_STMT_TYPE_TLP::AGGR_SUM:
      if (!compare_aggr(res)) {
        is_all_err = false;
      }
      break; // Break the switch

    default:
      res.comp_res = ORA_COMP_RES::Error;
      break;
    } // Switch stmt.
    if (res.comp_res == ORA_COMP_RES::Fail) {
      res_out.final_res = ORA_COMP_RES::Fail;
    }
  } // Result outer loop.

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

      vector<IR *> v_cur_stmt_ir =
          g_mutator->parse_query_str_get_ir_set(cur_cmd_str);
      if (v_cur_stmt_ir.size() == 0) {
        continue;
      }
      if (!(v_cur_stmt_ir.back()->left_ != NULL &&
            v_cur_stmt_ir.back()->left_->left_ != NULL)) {
        v_cur_stmt_ir.back()->deep_drop();
        continue;
      }

      IR *cur_stmt_ir = v_cur_stmt_ir.back()->left_->left_;
      v_valid_type.push_back(get_stmt_TLP_type(cur_stmt_ir));

      v_cur_stmt_ir.back()->deep_drop();

    } else {
      // cerr << "Error: For the current begin_idx, we cannot find the end_idx.
      // \n\n\n";
      break; // For the current begin_idx, we cannot find the end_idx. Ignore
             // the current output.
    }
  }
}

VALID_STMT_TYPE_TLP SQL_TLP::get_stmt_TLP_type(IR *cur_stmt) {
  VALID_STMT_TYPE_TLP default_type_ = VALID_STMT_TYPE_TLP::NORMAL;

  /* Distinct  */
  vector<IR *> v_opt_distinct = ir_wrapper.get_ir_node_in_stmt_with_type(
      cur_stmt, TypeOptDistinct, false);
  for (IR *opt_distinct : v_opt_distinct) {
    if (opt_distinct->get_left() != NULL &&
        !opt_distinct->get_left()->is_empty()) {
      default_type_ = VALID_STMT_TYPE_TLP::DISTINCT;
    }
    if (opt_distinct->get_prefix() == "DISTINCT") {
      default_type_ = VALID_STMT_TYPE_TLP::DISTINCT;
    }
  }

  /* Has GROUP BY clause.  */
  vector<IR *> v_group_clause =
      ir_wrapper.get_ir_node_in_stmt_with_type(cur_stmt, TypeGroupBy, false);
  if (v_group_clause.size() > 0) {
    default_type_ = VALID_STMT_TYPE_TLP::GROUP_BY;
  }

  /* Ignore having. Treat it as normal, or other type if other elements are
   * evolved. */

  /* TODO:: Here we want to restrict the SELECT target to have only one
   * targetel. Fix it later.  */
  vector<IR *> v_result_column_list = ir_wrapper.get_select_exprs(cur_stmt);
  if (v_result_column_list.size() == 0) {
    return VALID_STMT_TYPE_TLP::TLP_UNKNOWN;
  }

  // TODO: FIXME: Not working yet.
  vector<IR *> count_func_vec =
      ir_wrapper.get_ir_node_in_stmt_with_type(cur_stmt, TypeIdentifier, false);

  /* TODO:: Ignore cases like SELECT COUNT() FROM v0; */

  for (IR *count_func_ir : count_func_vec) {

    if (count_func_ir->data_type_ != DataFunctionName) {
      continue;
    }

    // if (
    // ir_wrapper.get_parent_type(count_func_ir, 0) == TypeFuncExpr &&
    // ir_wrapper.get_parent_type(count_func_ir, 1) == TypeSelectExpr &&
    // ir_wrapper.get_parent_type(count_func_ir, 2) == TypeSelectExprs  &&
    // ir_wrapper.get_parent_type(count_func_ir, 3) == TypeSelectClause
    //) {

    string func_name_str = count_func_ir->get_str_val();

    if (findStringIn(func_name_str, "count") ||
        findStringIn(func_name_str, "COUNT")) {

      if (default_type_ == VALID_STMT_TYPE_TLP::GROUP_BY) {
        return VALID_STMT_TYPE_TLP::TLP_UNKNOWN;
      }
      return VALID_STMT_TYPE_TLP::AGGR_COUNT;

    } else if (findStringIn(func_name_str, "sum") ||
               findStringIn(func_name_str, "SUM")) {

      if (default_type_ == VALID_STMT_TYPE_TLP::GROUP_BY) {
        return VALID_STMT_TYPE_TLP::TLP_UNKNOWN;
      }
      return VALID_STMT_TYPE_TLP::AGGR_SUM;

    } else if (findStringIn(func_name_str, "min") ||
               findStringIn(func_name_str, "MIN")) {

      if (default_type_ == VALID_STMT_TYPE_TLP::GROUP_BY) {
        return VALID_STMT_TYPE_TLP::TLP_UNKNOWN;
      }
      return VALID_STMT_TYPE_TLP::AGGR_MIN;

    } else if (findStringIn(func_name_str, "max") ||
               findStringIn(func_name_str, "MAX")) {
      if (default_type_ == VALID_STMT_TYPE_TLP::GROUP_BY) {
        return VALID_STMT_TYPE_TLP::TLP_UNKNOWN;
      }
      return VALID_STMT_TYPE_TLP::AGGR_MAX;
    } else if (findStringIn(func_name_str, "avg") ||
               findStringIn(func_name_str, "AVG")) {
      if (default_type_ == VALID_STMT_TYPE_TLP::GROUP_BY) {
        return VALID_STMT_TYPE_TLP::TLP_UNKNOWN;
      }
      return VALID_STMT_TYPE_TLP::AGGR_AVG;
    }
    //}
  }

  return default_type_;
}

IR *SQL_TLP::transform_non_aggr(IR *cur_stmt, bool is_UNION_ALL,
                                VALID_STMT_TYPE_TLP tlp_type) {

  /* Retrive the kSimpleSelect, that is used to construct the TLP stmt. */
  vector<IR *> src_simple_select_vec_ =
      ir_wrapper.get_ir_node_in_stmt_with_type(cur_stmt, TypeSelect, false);
  if (src_simple_select_vec_.size() == 0) {
    cerr << "Error: Failed to detect the kSimpleSelect node from the mutated "
            "oracle select stmt. Return failure. \n\n\n";
    return NULL;
  }
  /* If the logic has no error, should always pick the first one. Deep copid on
   * every used. */
  IR *src_simple_select_ = src_simple_select_vec_[0];
  /* Now we have the simple_select. :-) */

  /* modify the first part of TLP. Put the Whereclause into a brackets. */
  IR *operand_ir_ = new IR(TypeUnknown, OP3(" ( ", " ) ", ""));
  IR *expr_ir_ = new IR(TypeExprs, OP3("", "", ""), operand_ir_);

  IR *first_part_TLP = src_simple_select_->deep_copy();
  vector<IR *> v_where_first_stmt = ir_wrapper.get_ir_node_in_stmt_with_type(
      first_part_TLP, TypeWhere, false);
  if (v_where_first_stmt.size() == 0) {
    expr_ir_->deep_drop();
    first_part_TLP->deep_drop();
    cerr << "Error: Failed to detect the kWhereClause node from the mutated "
            "oracle select stmt. Return failure. \n\n\n";
    return NULL;
  }
  IR *where_first_stmt_ = v_where_first_stmt[0];
  if (where_first_stmt_->get_right() == NULL) {
    first_part_TLP->deep_drop();
    expr_ir_->deep_drop();
    cerr << "Error: The retrived where_first_stmt_ doesn't have the left_ "
            "child node. \n\n\n";
    return NULL;
  }
  IR *where_first_expr_ = where_first_stmt_->get_right();

  /* Swap the original where expr to the newly created expr_ir_ node, and attach
   * the expr we need into it.
   * */
  first_part_TLP->swap_node(where_first_expr_, expr_ir_);
  operand_ir_->update_left(where_first_expr_);

  /* Finished the first TLP part.  */

  /* Modify the second part of TLP. Pu the Whereclause into (Not (kWhereClause))
   */
  IR *operand_0 = new IR(TypeExprs, OP3("(", ")", "")); // For brackets
  IR *unary_expr_ =
      new IR(TypeExprs, OP3("NOT", "", ""), operand_0); // NOT (kWhereClause)
  IR *operand_1 =
      new IR(TypeExprs, OP3("(", ")", ""),
             unary_expr_); // For the second brackets. (NOT (kWhereClause))
  IR *expr_ = new IR(TypeExprs, OP0(), operand_1);

  IR *second_part_TLP = src_simple_select_->deep_copy();
  /* vector size has been double checked before */
  IR *where_second_stmt_ = ir_wrapper.get_ir_node_in_stmt_with_type(
      second_part_TLP, TypeWhere, false)[0];
  IR *where_second_expr_ = where_second_stmt_->get_right();

  second_part_TLP->swap_node(where_second_expr_, expr_);
  operand_0->update_left(where_second_expr_);

  /* Finished the second part TLP */

  /* Modify the third part of TLP. Put the WhereClause into ((kWhereClause) IS
   * NULL) */
  operand_0 = new IR(TypeUnknown, OP3("(", ")", "")); // For brackets
  unary_expr_ = new IR(TypeUnknown, OP3("", " IS NULL ", ""),
                       operand_0); // (kWhereClause) IS NULL
  operand_1 =
      new IR(TypeUnknown, OP3("(", ")", ""),
             unary_expr_); // For the second brackets. ((kWhereClause) IS NULL)
  expr_ = new IR(TypeUnknown, OP0(), operand_1);

  IR *third_part_TLP = src_simple_select_->deep_copy();
  /* vector size has been double checked before */
  IR *where_third_stmt_ = ir_wrapper.get_ir_node_in_stmt_with_type(
      third_part_TLP, TypeWhere, false)[0];
  IR *where_third_expr_ = where_third_stmt_->get_right();

  third_part_TLP->swap_node(where_third_expr_, expr_);
  operand_0->update_left(where_third_expr_);

  /* Finished the third part TLP.  */
  cur_stmt = first_part_TLP;
  if (is_UNION_ALL) {
    IR *set_operator = new IR(TypeUnionClause, OP3("", " UNION ALL ", ""),
                              second_part_TLP, third_part_TLP);
    set_operator = new IR(TypeUnionClause, OP3("", " UNION ALL ", ""),
                          first_part_TLP, set_operator);
    cur_stmt = set_operator;
  } else {
    IR *set_operator = new IR(TypeUnionClause, OP3("", " UNION ", ""),
                              second_part_TLP, third_part_TLP);
    set_operator = new IR(TypeUnionClause, OP3("", " UNION ", ""),
                          first_part_TLP, set_operator);
    cur_stmt = set_operator;
  }

  return cur_stmt;
}

/*
** Transform original stmt to TLP form. This function is used for SELECT stmt
*WITH aggregate functions
** in the SELECT clause.
** cur_stmt need to be freed outside this function.
*/

IR *SQL_TLP::transform_aggr(IR *cur_stmt, bool is_UNION_ALL,
                            VALID_STMT_TYPE_TLP tlp_type) {

  // TODO:: FIXME:: Not working yet.
  cur_stmt = cur_stmt->deep_copy();

  vector<IR *> v_aggr_func_ir =
      ir_wrapper.get_ir_node_in_stmt_with_type(cur_stmt, TypeIdentifier, false);
  if (v_aggr_func_ir.size() == 0) {
    cur_stmt->deep_drop();
    cerr << "Error: In SQL_TLP::transform_aggr, cannot find kFuncName. \n";
    return NULL;
  }

  // TODO:: FIXME:: Could be in-accurate.
  IR *aggr_func_ir = v_aggr_func_ir.front();

  if (
      // tlp_type == VALID_STMT_TYPE_TLP::AGGR_COUNT ||
      tlp_type == VALID_STMT_TYPE_TLP::AGGR_SUM ||
      tlp_type == VALID_STMT_TYPE_TLP::AGGR_MAX ||
      tlp_type == VALID_STMT_TYPE_TLP::AGGR_MIN) {

    /* First of all, check whether there is existing alias name in the stmt */
    vector<IR *> v_targetel = ir_wrapper.get_ir_node_in_stmt_with_type(
        cur_stmt, TypeSelectExpr, false);
    if (v_targetel.size() > 0) {
      IR *targetel = v_targetel.front();
      if (targetel->get_middle() == " AS " && targetel->get_right() != NULL) {
        /* Found the originally existed matching alias. Change it to aggr*/
        IR *iden = targetel->get_right();
        iden->set_str_val(string("aggr"));
      } else {
        /* We cannot find the existing alias, create our own */
        IR *alias_id = new IR(TypeIdentifier, string("aggr"), DataAliasName, 0,
                              ContextDefine);
        IR *res = new IR(TypeUnknown, OP3(" AS ", "", ""), alias_id);
        res = new IR(TypeSelectExpr, OP0(), NULL, res);

        /* Swap and reattach the original targetel */
        cur_stmt->swap_node(targetel, res);
        res->update_left(targetel);

        /* Finished modification to the alias, if it is not AVG. */
      }
    }
  } else {
    /* Fix for VALID_STMT_TYPE_TLP::AGGR_AVG */
    /* First of all, check whether there is existing alias name in the stmt */
    vector<IR *> v_targetel = ir_wrapper.get_ir_node_in_stmt_with_type(
        cur_stmt, TypeSelectExpr, false);
    if (v_targetel.size() > 0) {
      IR *targetel = v_targetel.front();
      vector<IR *> v_func_name_ir = ir_wrapper.get_ir_node_in_stmt_with_type(
          targetel, TypeIdentifier, false);
      if (v_func_name_ir.size() == 0) {
        cerr << "Error: Cannot find FuncName identifiers inside kTargetEl. TLP "
                "oracle logic error. \n";
        cur_stmt->deep_drop();
        return NULL;
      }
      IR *func_name_ir = v_func_name_ir.front();

      IR *res_0 = NULL;
      IR *res_1 = NULL;
      if (targetel->get_right() != NULL && targetel->get_middle() == " AS ") {
        /* Found the originally existed matching alias. Change it to aggr*/
        targetel->get_right()->set_str_val(string("c"));
        func_name_ir->set_str_val("COUNT");
        res_1 = targetel->deep_copy();

        targetel->get_right()->set_str_val(string("s"));
        func_name_ir->set_str_val("SUM");
        res_0 = targetel->deep_copy();

        IR *target_list_ir = new IR(TypeExprs, OP3("", ",", ""), res_0, res_1);
        cur_stmt->swap_node(targetel, target_list_ir);
        targetel->deep_drop();

      } else {
        /* Cannot find existing alias, create our own */
        func_name_ir->func_name_set_str("SUM");

        IR *alias_id_0 = new IR(TypeIdentifier, string("s"), DataAliasName, 0,
                                ContextDefine);
        res_0 = new IR(TypeSelectExpr, OP3(" AS ", "", ""), alias_id_0);
        res_0 = new IR(TypeSelectExpr, OP0(), targetel->deep_copy(), res_0);

        func_name_ir->func_name_set_str("COUNT");
        IR *alias_id_1 = new IR(TypeIdentifier, string("c"), DataAliasName, 0,
                                ContextDefine);
        res_1 = new IR(TypeUnknown, OP3(" AS ", "", ""), alias_id_1);
        res_1 = new IR(TypeSelectExpr, OP0(), targetel->deep_copy(), res_1);

        IR *target_list_ir =
            new IR(TypeUnknown, OP3("", ",", ""), res_0, res_1);
        cur_stmt->swap_node(targetel, target_list_ir);
        targetel->deep_drop();
      }
    }

    /* Fix for aggregate function AVG completed. */
  }

  IR *cur_stmt_inner = transform_non_aggr(cur_stmt, is_UNION_ALL, tlp_type);
  /* Finished generating inner stmt. Deep drop. */
  cur_stmt->deep_drop();

  /* Fill in SELECT AGGR(aggr) from (inner stmt) */
  IR *cur_stmt_outer;
  if (tlp_type == VALID_STMT_TYPE_TLP::AGGR_SUM) {
    cur_stmt_outer =
        g_mutator->parse_query_str_get_ir_set(this->trans_outer_SUM_tmp_str)
            .back();
    // } else if (tlp_type == VALID_STMT_TYPE_TLP::AGGR_COUNT) {
    //   // cur_stmt_outer =
    //   g_mutator->parse_query_str_get_ir_set(this->trans_outer_COUNT_tmp_str).back();
    //   cur_stmt_inner->deep_drop();
    //   return NULL;
  } else if (tlp_type == VALID_STMT_TYPE_TLP::AGGR_MIN) {
    cur_stmt_outer =
        g_mutator->parse_query_str_get_ir_set(this->trans_outer_MIN_tmp_str)
            .back();
  } else if (tlp_type == VALID_STMT_TYPE_TLP::AGGR_MAX) {
    cur_stmt_outer =
        g_mutator->parse_query_str_get_ir_set(this->trans_outer_MAX_tmp_str)
            .back();
  } else if (tlp_type == VALID_STMT_TYPE_TLP::AGGR_AVG) {
    cur_stmt_outer =
        g_mutator->parse_query_str_get_ir_set(this->trans_outer_AVG_tmp_str)
            .back();
  }

  IR *ori_outer_expr =
      ir_wrapper
          .get_ir_node_in_stmt_with_type(cur_stmt_outer, TypeParenSelect, true)
          .front()
          ->get_left();

  cur_stmt_outer->swap_node(ori_outer_expr, cur_stmt_inner);
  ori_outer_expr->deep_drop();

  return cur_stmt_outer;
}
