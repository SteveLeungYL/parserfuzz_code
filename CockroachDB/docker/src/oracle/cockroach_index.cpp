#include "./cockroach_index.h"
#include "../include/mutate.h"
#include <iostream>

#include <regex>
#include <string>

bool SQL_INDEX::mark_all_valid_node(vector<IR *> &v_ir_collector) {
  // TODO::FixLater.
  return true;
}

IR *SQL_INDEX::get_random_append_stmts(Mutator &g_mutator) {
  IR *app_index_stmt = g_mutator.get_from_libary_with_type(TypeCreateIndex);
  if (app_index_stmt == NULL) {
    return NULL;
  }
  if (app_index_stmt->get_ir_type() != TypeCreateIndex) {
    app_index_stmt->deep_drop();
    return NULL;
  }
  return app_index_stmt;
}

bool SQL_INDEX::is_oracle_normal_stmt(IR *cur_IR) {
  // Treat all CREATE INDEX statements as oracle non-select statement.
  if (cur_IR->get_ir_type() == TypeCreateIndex) {
    return true;
  } else {
    return false;
  }
}

vector<IR *> SQL_INDEX::post_fix_transform_normal_stmt(IR *cur_stmt,
                                                       unsigned multi_run_id) {
  if (!multi_run_id) { // multi_run_id == 0

    IR* new_stmt = cur_stmt->deep_copy();
    // Remove the `UNIQUE` constraint from the `CREATE INDEX` statement.
    vector<IR*> v_opt_unique_ir = ir_wrapper.get_ir_node_in_stmt_with_type(new_stmt, TypeOptUnique, false);
    for (auto &opt_unique_ir : v_opt_unique_ir) {
        // Remove the UNIQUE constraint.
        opt_unique_ir->op_->prefix_ = "";
    }

    vector<IR *> tmp;
    tmp.push_back(cur_stmt->deep_copy());
    return tmp;
  } else {
    vector<IR *> tmp;
    // Return an empty vector. Will remove the stmt.
    return tmp;
  }
}

bool SQL_INDEX::compare_norm(COMP_RES &res) {

  string &res_a = res.v_res_str[0];
  string &res_b = res.v_res_str[0];
  int &res_a_int = res.v_res_int[0];
  int &res_b_int = res.v_res_int[1];

  if (findStringIn(res_a, "ERROR") || findStringIn(res_a, "pq: ") ||
      findStringIn(res_b, "ERROR") || findStringIn(res_b, "pq: ")) {
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
    res.comp_res = ORA_COMP_RES::Fail;
    return false;
  }
  res.comp_res = ORA_COMP_RES::Pass;
  return false;
}

bool SQL_INDEX::compare_uniq(COMP_RES &res) {

  string &res_a = res.v_res_str[0];
  string &res_b = res.v_res_str[0];
  int &res_a_int = res.v_res_int[0];
  int &res_b_int = res.v_res_int[1];

  if (findStringIn(res_a, "ERROR") || findStringIn(res_b, "ERROR") ||
      findStringIn(res_a, "pq: ") || findStringIn(res_b, "pq: ")) {
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
    res.comp_res = ORA_COMP_RES::Fail;
    return false;
  }
  res.comp_res = ORA_COMP_RES::Pass;
  return false;
}

/* Handle MIN valid stmt: SELECT MIN(*) FROM ...; and MAX valid stmt: SELECT
 * MAX(*) FROM ...;  */
bool SQL_INDEX::compare_aggr(COMP_RES &res) {
  string &res_a = res.v_res_str[0];
  string &res_b = res.v_res_str[0];
  int &res_a_int = res.v_res_int[0];
  int &res_b_int = res.v_res_int[1];

  if (findStringIn(res_a, "ERROR") || findStringIn(res_b, "ERROR") ||
      findStringIn(res_a, "pq: ") || findStringIn(res_b, "pq: ")) {
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

void SQL_INDEX::compare_results(ALL_COMP_RES &res_out) {

    res_out.final_res = ORA_COMP_RES::Pass;
    bool is_all_err = true;

    vector<VALID_STMT_TYPE_INDEX> v_valid_type;
    get_v_valid_type(res_out.v_cmd_str[0], v_valid_type);

    int i = -1; // Starts from 0.
    for (COMP_RES &res : res_out.v_res) {
        i++;
        if (res.v_res_str.size() < 2) {
            // Error handling.
            res.comp_res = ORA_COMP_RES::Error;
            res.res_int_0 = -1;
            res.res_int_1 = -1;
            res.v_res_int.push_back(-1);
            res.v_res_int.push_back(-1);
            continue;
        }
        if (findStringIn(res.v_res_str[0], "Error") ||
            findStringIn(res.v_res_str[0], "pq: ") ||
            findStringIn(res.v_res_str[1], "Error") ||
            findStringIn(res.v_res_str[1], "pq: ")
            ) {
            res.comp_res = ORA_COMP_RES::Error;
            res.res_int_0 = -1;
            res.res_int_1 = -1;
            res.v_res_int.push_back(-1);
            res.v_res_int.push_back(-1);
            continue;
        }

        res.v_res_int.push_back(-1);
        res.v_res_int.push_back(-1);

        switch (v_valid_type[i]) {
            case VALID_STMT_TYPE_INDEX::NORMAL:
                /* Handle normal valid stmt: SELECT * FROM ...; */
                if (!compare_norm(res)) {
                    is_all_err = false;
                }
                break; // Break the switch

                /* Compare unique results */
            case VALID_STMT_TYPE_INDEX::DISTINCT:
                [[fallthrough]];
            case VALID_STMT_TYPE_INDEX::GROUP_BY:
                compare_uniq(res);
                break;

                /* Compare concret values */
            case VALID_STMT_TYPE_INDEX::AGGR_AVG:
                [[fallthrough]];
                // case VALID_STMT_TYPE_TLP::AGGR_COUNT:
                //   [[fallthrough]];
            case VALID_STMT_TYPE_INDEX::AGGR_MAX:
                [[fallthrough]];
            case VALID_STMT_TYPE_INDEX::AGGR_MIN:
                [[fallthrough]];
            case VALID_STMT_TYPE_INDEX::AGGR_SUM:
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

//        vector<string> v_res_a = string_splitter(res.v_res_str[0], '\n');
//        vector<string> v_res_b = string_splitter(res.v_res_str[1], '\n');
//
//        if (v_res_a.size() > 50 || v_res_b.size() > 50) {
//            res.comp_res = ORA_COMP_RES::Error;
//            res.v_res_int.push_back(-1);
//            res.v_res_int.push_back(-1);
//            continue;
//        }
//
//        res.res_int_0 = v_res_a.size();
//        res.res_int_1 = v_res_b.size();
//
//        res.v_res_int.push_back(res.res_int_0);
//        res.v_res_int.push_back(res.res_int_1);

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

void SQL_INDEX::get_v_valid_type(const string &cmd_str,
                                 vector<VALID_STMT_TYPE_INDEX> &v_valid_type) {
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
      v_valid_type.push_back(get_stmt_INDEX_type(cur_stmt_ir));

      v_cur_stmt_ir.back()->deep_drop();

    } else {
      // cerr << "Error: For the current begin_idx, we cannot find the end_idx.
      // \n\n\n";
      break; // For the current begin_idx, we cannot find the end_idx. Ignore
             // the current output.
    }
  }
}

VALID_STMT_TYPE_INDEX SQL_INDEX::get_stmt_INDEX_type(IR *cur_stmt) {
  VALID_STMT_TYPE_INDEX default_type_ = VALID_STMT_TYPE_INDEX::NORMAL;

  /* Distinct  */
  vector<IR *> v_opt_distinct = ir_wrapper.get_ir_node_in_stmt_with_type(
      cur_stmt, TypeOptDistinct, false);
  for (IR *opt_distinct : v_opt_distinct) {
    if (opt_distinct->get_left() != NULL &&
        !opt_distinct->get_left()->is_empty()) {
      default_type_ = VALID_STMT_TYPE_INDEX::DISTINCT;
    }
    if (opt_distinct->get_prefix() == "DISTINCT") {
      default_type_ = VALID_STMT_TYPE_INDEX::DISTINCT;
    }
  }

  /* Has GROUP BY clause.  */
  vector<IR *> v_group_clause =
      ir_wrapper.get_ir_node_in_stmt_with_type(cur_stmt, TypeGroupBy, false);
  if (v_group_clause.size() > 0) {
    default_type_ = VALID_STMT_TYPE_INDEX::GROUP_BY;
  }

  /* Ignore having. Treat it as normal, or other type if other elements are
   * evolved. */

  /* TODO:: Here we want to restrict the SELECT target to have only one
   * targetel. Fix it later.  */
  vector<IR *> v_result_column_list = ir_wrapper.get_select_exprs(cur_stmt);
  if (v_result_column_list.size() == 0) {
    return VALID_STMT_TYPE_INDEX::TLP_UNKNOWN;
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

      if (default_type_ == VALID_STMT_TYPE_INDEX::GROUP_BY) {
        return VALID_STMT_TYPE_INDEX::TLP_UNKNOWN;
      }
      return VALID_STMT_TYPE_INDEX::AGGR_COUNT;

    } else if (findStringIn(func_name_str, "sum") ||
               findStringIn(func_name_str, "SUM")) {

      if (default_type_ == VALID_STMT_TYPE_INDEX::GROUP_BY) {
        return VALID_STMT_TYPE_INDEX::TLP_UNKNOWN;
      }
      return VALID_STMT_TYPE_INDEX::AGGR_SUM;

    } else if (findStringIn(func_name_str, "min") ||
               findStringIn(func_name_str, "MIN")) {

      if (default_type_ == VALID_STMT_TYPE_INDEX::GROUP_BY) {
        return VALID_STMT_TYPE_INDEX::TLP_UNKNOWN;
      }
      return VALID_STMT_TYPE_INDEX::AGGR_MIN;

    } else if (findStringIn(func_name_str, "max") ||
               findStringIn(func_name_str, "MAX")) {
      if (default_type_ == VALID_STMT_TYPE_INDEX::GROUP_BY) {
        return VALID_STMT_TYPE_INDEX::TLP_UNKNOWN;
      }
      return VALID_STMT_TYPE_INDEX::AGGR_MAX;
    } else if (findStringIn(func_name_str, "avg") ||
               findStringIn(func_name_str, "AVG")) {
      if (default_type_ == VALID_STMT_TYPE_INDEX::GROUP_BY) {
        return VALID_STMT_TYPE_INDEX::TLP_UNKNOWN;
      }
      return VALID_STMT_TYPE_INDEX::AGGR_AVG;
    }
    //}
  }

  return default_type_;
}
