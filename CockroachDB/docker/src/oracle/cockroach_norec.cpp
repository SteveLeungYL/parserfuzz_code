#include "./cockroach_norec.h"
#include "../include/mutate.h"
#include <iostream>

#include <regex>
#include <string>

bool SQL_NOREC::is_oracle_select_stmt(IR *cur_stmt) {

  if (cur_stmt == NULL) {
    // cerr << "Return false because cur_stmt is NULL; \n";
    return false;
  }

  if (cur_stmt->get_ir_type() != TypeSelect) {
    // cerr << "Return false because this is not a SELECT stmt: " <<
    // get_string_by_ir_type(cur_stmt->get_ir_type()) <<  " \n";
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

  // Remove the FOR UPDATE, FOR SHARE locking clause from the oracle stmt.
  // These are not supported for the aggregate function.
  vector<IR *> v_locking_clause =
          ir_wrapper.get_ir_node_in_stmt_with_type(cur_stmt, TypeLockingClause, false);
  for (IR *locking_clause: v_locking_clause) {
      if (!locking_clause->is_empty()){
          if (cur_stmt->swap_node(locking_clause, NULL)) {
              locking_clause->deep_drop();
          }
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

  // Ignore statements with UNION, EXCEPT and INTERCEPT
  if (ir_wrapper.is_exist_set_operator(cur_stmt)) {
    // cerr << "Return false because of set operator \n";
    return false;
  }

  vector<IR *> v_target_list_ir = ir_wrapper.get_ir_node_in_stmt_with_type(
      cur_stmt, TypeSelectExprs, false);

  if (v_target_list_ir.size() == 0)
    return false;

  IR *target_list_ir = v_target_list_ir.front();

//   cerr << "num_target_el: " << ir_wrapper.get_num_select_exprs(cur_stmt) <<
//   "\n";

  if (ir_wrapper.is_exist_ir_node_in_stmt_with_type(cur_stmt, TypeFrom,
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
    if (where_clause->is_empty() || where_clause->get_left() == NULL || where_clause->get_left()->to_string() == "HAVING") {
      // cerr << "Return false because WHERE clause is empty \n";
      return false;
    }

    vector<IR*> v_alias_clause = ir_wrapper.get_ir_node_in_stmt_with_type(cur_stmt, TypeSelectExpr, false);
    for (auto alias_clause : v_alias_clause) {
        if (alias_clause->get_middle() == " AS ") {
//            IR* alias_expr = alias_clause->get_right();
//            alias_clause->update_right(nullptr);
//            alias_expr->deep_drop();
//            alias_clause->op_->middle_ = "";
              return false;
        }
    }
    if (v_alias_clause.size() != 1) {
        // Only looking for SELECT with one select expression, that is `COUNT(*)`.
        return false;
    }

    if (ir_wrapper.is_exist_ir_node_in_stmt_with_type(cur_stmt, TypeRowsFromExpr, false)) {
        // Do not use statements with ROWS FROM expr. It does not come with column reference.
        return false;
    }

    vector<IR *> count_func_vec = ir_wrapper.get_ir_node_in_stmt_with_type(
        cur_stmt, TypeIdentifier, false);

    for (IR *count_func_ir : count_func_vec) {

      if (count_func_ir->data_type_ != DataFunctionName) {
        continue;
      }

      if (ir_wrapper.get_parent_type(count_func_ir, 0) == TypeFuncExpr &&
          ir_wrapper.get_parent_type(count_func_ir, 1) == TypeFuncExpr &&
          ir_wrapper.get_parent_type(count_func_ir, 2) == TypeSelectExpr &&
          ir_wrapper.get_parent_type(count_func_ir, 3) == TypeSelectExprs &&
          ir_wrapper.get_parent_type(count_func_ir, 4) == TypeSelectClause) {
        /* The Func expression structure is enforced. Next ensure the func is
         * COUNT */
        IR *func_app_ir =
            count_func_ir->get_parent()->get_parent()->get_right();
        // Enforce '*'
        if (func_app_ir == NULL) {
          continue;
        }
        if (func_app_ir->to_string() == "*") {

            IR* type_select_exprs_node = ir_wrapper.get_parent_node_with_type(count_func_ir, TypeSelectExprs);
            this->ir_wrapper.iter_cur_node_with_handler(
                    type_select_exprs_node, [](IR *cur_node) -> void {
                        cur_node->set_is_instantiated(true);
                        cur_node->set_data_flag(ContextNoModi);
                    });

          count_func_ir->set_str_val("COUNT");
          return true;
        }
      }
    }
    return false;
  }

  return false;
}

bool SQL_NOREC::mark_all_valid_node(IR * cur_stmt) {

    vector<IR*> v_all_select_exprs = ir_wrapper
            .get_ir_node_in_stmt_with_type(cur_stmt, TypeSelectExprs, false);

    for (auto cur_select_exprs : v_all_select_exprs)  {
        ir_wrapper.iter_cur_node_with_handler(
                cur_select_exprs, [](IR *cur_node) -> void {
                    cur_node->set_is_instantiated(true);
                    cur_node->set_data_flag(ContextNoModi);
                });
    }

  return true;
}

vector<IR *> SQL_NOREC::post_fix_transform_select_stmt(IR *cur_stmt,
                                                       unsigned multi_run_id) {
  vector<IR *> trans_IR_vec;

  cur_stmt->parent_ = NULL;

  /* Double check whether the stmt is norec compatible */
  if (!is_oracle_select_stmt(cur_stmt)) {
    return trans_IR_vec;
  }

  IR *first_stmt = cur_stmt->deep_copy();

  //  /* Remove the kOverClause, if exists.
  //   * Doesn't need to worry about double free, because all overclause that we
  //   remove
  //   * are not in subqueries.
  //   * */
  //  vector<IR* > v_over_clause =
  //  ir_wrapper.get_ir_node_in_stmt_with_type(first_stmt, TypeWindow, false);
  //
  //  if (v_over_clause.size() > 0) {
  //    IR* over_clause = v_over_clause.front();
  //    IR* new_over_clause = new IR(TypeWindow, OP0());
  //    first_stmt->swap_node(over_clause, new_over_clause);
  //    over_clause->deep_drop();
  //  }

  /* Remove the kWindowClause, if exists.
   * Doesn't need to worry about double free, because all windowclause that we
   * remove are not in subqueries.
   * */
  vector<IR *> v_window_clause =
      ir_wrapper.get_ir_node_in_stmt_with_type(first_stmt, TypeWindow, false);
  if (v_window_clause.size() > 0) {
    IR *window_clause = v_window_clause.front();
    IR *new_window_clause = new IR(TypeWindow, OP0());
    first_stmt->swap_node(window_clause, new_window_clause);
    window_clause->deep_drop();
  }

  trans_IR_vec.push_back(first_stmt); // Save the original version.

  // cerr << "DEBUG: Getting post_fix cur_stmt: " << cur_stmt->to_string() << "
  // \n\n\n";

  // cerr << "DEBUG: Getting where_clause " <<
  // ir_wrapper.get_ir_node_in_stmt_with_type(cur_stmt, kWhereClause,
  // false).size() << "\n\n\n";

  /* Take care of WHERE and FROM clauses. */
  // cerr << "Printing post_fix tree: ";
  // g_mutator->debug(cur_stmt, 0);
  // cerr << "\n\n\n\n\n\n\n";

//  is_oracle_select_stmt(cur_stmt);

  vector<IR *> transformed_temp_vec =
      g_mutator->parse_query_str_get_ir_set(this->post_fix_temp);
  if (transformed_temp_vec.size() == 0) {
    cerr << "Error: parsing the post_fix_temp from "
            "SQL_NOREC::post_fix_transform_select_stmt returns empty IR "
            "vector. \n";
    vector<IR *> tmp;
    return tmp;
  }

  IR *transformed_temp_ir = transformed_temp_vec.back();
  IR *trans_stmt_ir =
      ir_wrapper.get_first_stmt_from_root(transformed_temp_ir)->deep_copy();
  trans_stmt_ir->parent_ = NULL;
  transformed_temp_ir->deep_drop();

  /* Move the original ORDER BY function to the dest IR stmt. */
  vector<IR *> src_order_vec =
      ir_wrapper.get_ir_node_in_stmt_with_type(cur_stmt, TypeOrderBy, false);
  if (src_order_vec.size() > 0) {
    IR *src_order_clause = src_order_vec[0]->deep_copy();
    IR *dest_order_clause = ir_wrapper.get_ir_node_in_stmt_with_type(
        trans_stmt_ir, TypeOrderBy, true)[0];
    if (!trans_stmt_ir->swap_node(dest_order_clause, src_order_clause)) {
      trans_stmt_ir->deep_drop();
      src_order_clause->deep_drop();
      cerr << "Error: swap_node failed for sort_clause. In function "
              "SQL_NOREC::post_fix_transform_select_stmt. \n";
      vector<IR *> tmp;
      return tmp;
    }
    dest_order_clause->deep_drop();
  } else {
    IR *dest_order_clause = ir_wrapper.get_ir_node_in_stmt_with_type(
        trans_stmt_ir, TypeOrderBy, true)[0];
    trans_stmt_ir->detach_node(dest_order_clause);
    dest_order_clause->deep_drop();
  }

  IR *src_where_expr =
      ir_wrapper.get_ir_node_in_stmt_with_type(cur_stmt, TypeWhere, false)[0]
          ->get_right()
          ->deep_copy();
  IR *dest_where_expr = ir_wrapper.get_ir_node_in_stmt_with_type(
      trans_stmt_ir, TypeDBool, true)[0];

  IR *src_from_expr =
      ir_wrapper.get_ir_node_in_stmt_with_type(cur_stmt, TypeFrom, false)[0]
          ->deep_copy();
  IR *dest_from_expr = ir_wrapper.get_ir_node_in_stmt_with_type(
      trans_stmt_ir, TypeFrom, true)[0];

  if (!trans_stmt_ir->swap_node(dest_where_expr, src_where_expr)) {
    trans_stmt_ir->deep_drop();
    src_where_expr->deep_drop();
    src_from_expr->deep_drop();
    cerr << "Error: swap_node failed for where_clause. In function "
            "SQL_NOREC::post_fix_transform_select_stmt. \n";
    vector<IR *> tmp;
    return tmp;
  }
  dest_where_expr->deep_drop();
  if (!trans_stmt_ir->swap_node(dest_from_expr, src_from_expr)) {
    trans_stmt_ir->deep_drop();
    src_from_expr->deep_drop();
    cerr << "Error: swap_node failed for from_clause. In function "
            "SQL_NOREC::post_fix_transform_select_stmt. \n";
    vector<IR *> tmp;
    return tmp;
  }
  dest_from_expr->deep_drop();

  // At last, after the main structure of trans_stmt_ir is finished, also check
  // for
  //    the WITH clause from the original statement. Copy the WITH clause to the
  //    modified trans_stmt_ir.

  vector<IR *> v_with_clause =
      ir_wrapper.get_ir_node_in_stmt_with_type(cur_stmt, TypeWith, false);

  if (v_with_clause.size() > 0) {
    IR *with_clause = v_with_clause.front()->deep_copy();
    trans_stmt_ir = new IR(TypeStmt, OP0(), with_clause, trans_stmt_ir);
  }

  trans_IR_vec.push_back(trans_stmt_ir);

  return trans_IR_vec;
}

void SQL_NOREC::compare_results(ALL_COMP_RES &res_out) {

  res_out.final_res = ORA_COMP_RES::Pass;
  bool is_all_err = true;

  for (COMP_RES &res : res_out.v_res) {

    if ( 
            !findStringIn(res.res_str_0, "comparison overload not found") &&
            !findStringIn(res.res_str_1, "comparison overload not found")
            )  {
        if (findStringIn(res.res_str_0, "Internal Error") ||
            findStringIn(res.res_str_0, "unexpected error") ||
            findStringIn(res.res_str_1, "Internal Error") ||
            findStringIn(res.res_str_1, "unexpected error")
        ) {
          res.res_int_0 = -1;
          res.res_int_1 = -1;
          res.v_res_int.push_back(-1);
          res.v_res_int.push_back(-1);

          res.comp_res = ORA_COMP_RES::Fail;
          res_out.final_res = ORA_COMP_RES::Fail;

          continue;
        }
    } else {
          res.res_int_0 = -1;
          res.res_int_1 = -1;
          res.v_res_int.push_back(-1);
          res.v_res_int.push_back(-1);

          res.comp_res = ORA_COMP_RES::Error;
          res_out.final_res = ORA_COMP_RES::Error;

          continue;
    }

    if (findStringIn(res.res_str_0, "Error") ||
        findStringIn(res.res_str_0, "pq: ") ||
        findStringIn(res.res_str_1, "Error") ||
        findStringIn(res.res_str_1, "pq: ")) {
      res.comp_res = ORA_COMP_RES::Error;
      res.res_int_0 = -1;
      res.res_int_1 = -1;
      continue;
    }
    try {
      res.res_int_0 = stoi(res.res_str_0);
      // cout << "res_int_0: " << res.res_int_0 << endl;
      res.res_int_1 = stoi(res.res_str_1);
      // cout << "res_int_1: " << res.res_int_1 << endl;
    } catch (std::invalid_argument &e) {
      res.comp_res = ORA_COMP_RES::Error;
      continue;
    } catch (std::out_of_range &e) {
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
