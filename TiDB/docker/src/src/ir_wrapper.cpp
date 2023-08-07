#include "../include/ir_wrapper.h"
#include "../AFL/debug.h"
#include "../include/define.h"
#include "../include/utils.h"
#include <algorithm>
#include <cstring>
#include <fstream>
#include <iostream>
#include <vector>

bool IRWrapper::is_in_subquery(IR *cur_stmt, IR *check_node,
                               bool output_debug) {

  IR *cur_iter = check_node;
  while (1) {
    if (cur_iter == NULL) { // Iter to the parent node. This is Not a subquery.
      return false;
    } else if (cur_iter == cur_stmt) { // Iter to the cur_stmt node already. Not
                                       // in a  subquery.
      return false;
    } else if (cur_iter->type_ ==
               TypeStmt) { // Iter to the parent node. This is Not a subquery.
      return false;
    } else if (cur_iter->get_ir_type() == TypeSelectStmt &&
               cur_iter->get_parent() != NULL &&
               cur_iter->get_parent()->get_ir_type() != TypeStmt) {
      return true; // In a subquery.
    } else if (cur_iter->get_ir_type() == TypeSubqueryExpr) {
      return true; // In a subquery.
    }
    // Assuming cur_iter->get_parent() will always get
    // to TypeStmt. Otherwise, it would be error.
    cur_iter = cur_iter->get_parent();

    continue;
  }
  /* Unexpected, should not happen. */
  return false;
}

IR *IRWrapper::get_ir_node_for_stmt_with_idx(int idx) {

  if (idx < 0) {
    FATAL("Checking on non-existing stmt. Function: "
          "IRWrapper::get_ir_node_for_stmt_with_idx(). Idx < 0. idx: '%d' \n",
          idx);
  }

  if (this->ir_root == nullptr) {
    FATAL("Root IR not found in IRWrapper::get_ir_node_for_stmt_with_idx(); "
          "Forgot to initilize the IRWrapper? \n");
  }

  vector<IR *> stmt_list_v = this->get_stmtlist_IR_vec();

  if (idx >= stmt_list_v.size()) {
    std::cerr << "Statement with idx " << idx << " not found in the IR. "
              << std::endl;
    return nullptr;
  }
  IR *cur_stmt_list = stmt_list_v[idx];
  IR *cur_stmt = get_stmt_ir_from_stmtlist(cur_stmt_list);
  return cur_stmt;
}

IR *IRWrapper::get_ir_node_for_stmt_with_idx(IR *ir_root, int idx) {
  this->set_ir_root(ir_root);
  return this->get_ir_node_for_stmt_with_idx(idx);
}

/* Not accurate within query. */
bool IRWrapper::is_ir_before(IR *f, IR *l) { return this->is_ir_after(l, f); }

/* Not accurate within query. */
bool IRWrapper::is_ir_after(IR *f, IR *l) {
  if (this->ir_root == nullptr) {
    FATAL("Root IR not found in IRWrapper::is_ir_before/after(); Forgot to "
          "initilize the IRWrapper? \n");
  }

  // Left depth prioritized iteration. Should found l first if IR f is
  // behind(after) l. Iterate IR binary tree, left depth prioritized.
  bool is_finished_search = false;
  std::vector<IR *> ir_vec_iter;
  IR *cur_IR = this->ir_root;
  // Begin iterating.
  while (!is_finished_search) {
    ir_vec_iter.push_back(cur_IR);
    if (cur_IR == l) {
      return true;
    } else if (cur_IR == f) {
      return false;
    }

    if (cur_IR->left_ != nullptr) {
      cur_IR = cur_IR->left_;
      continue;
    } else { // Reaching the most depth. Consulting ir_vec_iter for right_
             // nodes.
      cur_IR = nullptr;
      while (cur_IR == nullptr) {
        if (ir_vec_iter.size() == 0) {
          is_finished_search = true;
          break;
        }
        cur_IR = ir_vec_iter.back()->right_;
        ir_vec_iter.pop_back();
      }
      continue;
    }
  }

  FATAL("Cannot find curent IR in the IR tree. Function "
        "IRWrapper::is_ir_after(). \n");
}

vector<IRTYPE> IRWrapper::get_all_stmt_ir_type() {

  vector<IR *> stmt_list_v = this->get_stmtlist_IR_vec();

  vector<IRTYPE> all_types;
  for (auto iter = stmt_list_v.begin(); iter != stmt_list_v.end(); iter++) {
    all_types.push_back((**iter).type_);
  }
  return all_types;
}

int IRWrapper::get_stmt_num() { return this->get_stmtlist_IR_vec().size(); }

int IRWrapper::get_stmt_num(IR *cur_root) {
  if (cur_root->type_ != TypeRoot) {
    cerr << "Error: Receiving NON-kProgram root. Func: "
            "IRWrapper::get_stmt_num(IR* cur_root). Aboard!\n";
    FATAL("Error: Receiving NON-kProgram root. Func: "
          "IRWrapper::get_stmt_num(IR* cur_root). Aboard!\n");
  }
  this->set_ir_root(cur_root);
  return this->get_stmt_num();
}

IR *IRWrapper::get_first_stmtlist_from_root() {

  /* First of all, given the root, we need to get to kStmtmulti. */

  if (ir_root == NULL) {
    cerr << "Error: In ir_wrapper::get_first_stmtlist_IR_vec, receiving empty "
            "IR root. \n";
    return NULL;
  }
  if (ir_root->get_left() == NULL) {
    cerr << "Error: In ir_wrapper::get_first_stmtlist_IR_vec, receiving empty "
            "IR root -> get_left(). \n";
    return NULL;
  }
  if (ir_root->get_left()->get_ir_type() != TypeStmtList) {
    cerr << "Error: In ir_wrapper:get_first_stmtlist_IR_vec, cannot find the "
            "kStmtmulti "
            "structure from the current IR tree. Empty stmt? Or PLAssignStmt? "
            "PLAssignStmt is not currently supported. \n";
    return NULL;
  }

  vector<IR *> stmtmulti_v = get_stmtlist_IR_vec();
  if (stmtmulti_v.size() != 0) {
    return stmtmulti_v.front();
  } else {
    return NULL;
  }
}

IR *IRWrapper::get_first_stmtlist_from_root(IR *cur_root) {
  this->ir_root = cur_root;
  return get_first_stmtlist_from_root();
}

IR *IRWrapper::get_first_stmt_from_root() {
  IR *first_stmtmulti = this->get_first_stmtlist_from_root();
  if (first_stmtmulti == NULL) {
    return NULL;
  }

  return this->get_stmt_ir_from_stmtlist(first_stmtmulti);
}

IR *IRWrapper::get_first_stmt_from_root(IR *cur_root) {
  this->ir_root = cur_root;
  return get_first_stmt_from_root();
}

IR *IRWrapper::get_last_stmtlist_from_root() {

  /* First of all, given the root, we need to get to kStmtmulti. */

  if (ir_root == NULL) {
    cerr << "Error: In ir_wrapper::get_stmtlist_IR_vec, receiving empty IR "
            "root. \n";
    return NULL;
  }
  if (ir_root->get_left() == NULL) {
    cerr << "Error: In ir_wrapper::get_stmtlist_IR_vec, receiving empty "
            "IR->get_left() from root. \n";
    return NULL;
  }
  if (ir_root->get_left()->get_ir_type() != TypeStmtList) {
    cerr << "Error: In ir_wrapper:get_stmtlist_IR_vec, cannot find the "
            "kStmtmulti "
            "structure from the current IR tree. Empty stmt? Or PLAssignStmt? "
            "PLAssignStmt is not currently supported. \n";
    return NULL;
  }

  return ir_root->get_left();
}

IR *IRWrapper::get_last_stmtlist_from_root(IR *cur_root) {
  this->ir_root = cur_root;
  return get_last_stmtlist_from_root();
}

IR *IRWrapper::get_last_stmt_from_root() {
  IR *last_stmtlist = this->get_last_stmtlist_from_root();
  if (last_stmtlist == NULL) {
    // Getting empty last_stmtlist
    return NULL;
  }

  return this->get_stmt_ir_from_stmtlist(last_stmtlist);
}

IR *IRWrapper::get_last_stmt_from_root(IR *cur_root) {
  this->ir_root = cur_root;
  return get_last_stmt_from_root();
}

vector<IR *> IRWrapper::get_stmtlist_IR_vec() {

  IR *stmt_IR_p = get_last_stmtlist_from_root();

  vector<IR *> stmt_list_v;

  if (stmt_IR_p == NULL) {
    stmt_list_v.clear();
    return stmt_list_v;
  }

  while (
      stmt_IR_p &&
      stmt_IR_p->get_ir_type() ==
          TypeStmtList) { // Iterate from the first kstatementlist to the last.
    stmt_list_v.push_back(stmt_IR_p);
    if (stmt_IR_p->get_right() == nullptr)
      break;                           // This is the last kstatementlist.
    stmt_IR_p = stmt_IR_p->get_left(); // Lead to the next kstatementlist.
  }

  vector<IR *> res_stmt_list_v;
  for (auto iter = stmt_list_v.rbegin(); iter != stmt_list_v.rend(); iter++) {
    res_stmt_list_v.push_back(*iter);
  }

  stmt_list_v.clear();
  return res_stmt_list_v;
}

bool IRWrapper::append_stmt_at_idx(string app_str, int idx,
                                   Mutator &g_mutator) {

  vector<IR *> stmt_list_v = this->get_stmtlist_IR_vec();

  if (idx < -1 || idx >= int(stmt_list_v.size())) {
    std::cerr << "Error: Input index exceed total statement number. \n In "
                 "function IRWrapper::append_stmt_at_idx(). \n";
    return false;
  }

  // Parse and get the new statement.
  IR *app_IR_root = g_mutator.parse_query_str_get_ir_set(app_str).back();
  IR *app_stmtlist = get_first_stmtlist_from_root();

  if (!app_stmtlist) {
    cerr << "Error: get_first_stmtlist_from_root returns NULL. \n";
    return false;
  }

  IR *app_IR_node = get_stmt_ir_from_stmtlist(app_stmtlist);
  if (!app_IR_node) {
    cerr << "Error: get_stmt_ir_from_stmtlist returns NULL. \n";
    return false;
  }
  app_IR_node = app_IR_node->deep_copy();
  app_IR_root->deep_drop();

  return this->append_stmt_at_idx(app_IR_node, idx);
}

bool IRWrapper::append_stmt_at_end(string app_str, Mutator &g_mutator) {

  vector<IR *> stmt_list_v = this->get_stmtlist_IR_vec();

  // Parse and get the new statement.
  IR *app_IR_root = g_mutator.parse_query_str_get_ir_set(app_str).back();

  IR *app_stmtmulti = get_first_stmtlist_from_root();

  if (!app_stmtmulti) {
    cerr << "Error: get_first_stmtlist_from_root returns NULL. \n";
    return false;
  }

  IR *app_IR_node = get_stmt_ir_from_stmtlist(app_stmtmulti);
  if (!app_IR_node) {
    cerr << "Error: get_stmt_ir_from_stmtlist returns NULL. \n";
    return false;
  }
  app_IR_node = app_IR_node->deep_copy();
  app_IR_root->deep_drop();

  return this->append_stmt_at_idx(app_IR_node, stmt_list_v.size() - 1);
}

bool IRWrapper::append_stmt_at_end(
    IR *app_IR_node) { // Please provide with IR* (Statement*) type, do not
                       // provide IR*(StatementList*) type.

  int total_num = this->get_stmt_num();
  if (total_num < 1) {
    cerr << "Error: total_num of stmt < 1. Directly deep_drop(); \n\n\n";
    app_IR_node->deep_drop();
    return false;
  }
  return this->append_stmt_at_idx(app_IR_node, total_num - 1);
}

bool IRWrapper::append_stmt_at_idx(
    IR *app_IR_node,
    int idx) { // Please provide with IR* (Specific_Statement*) type, do not
               // provide IR*(StatementList*) type.

  if (app_IR_node == NULL) {
    cerr << "Error: Getting app_IR_node == NULL in the append_stmt_at_idx. \n";
    return false;
  }

  vector<IR *> stmt_list_v = this->get_stmtlist_IR_vec();

  if (stmt_list_v.size() == 0) {
    cerr << "Error: Getting stmt_list_v.size() == 0; \n";
    app_IR_node->deep_drop();
    return false;
  }

  if (idx < -1 || idx >= int(stmt_list_v.size())) {
    std::cerr << "Error: Input index exceed total statement number. \n In "
                 "function IRWrapper::append_stmt_at_idx(). \n";
    std::cerr << "Error: Input index " << to_string(idx)
              << "; stmt_list_v size(): " << stmt_list_v.size() << ".\n";
    app_IR_node->deep_drop();
    return false;
  }

  app_IR_node = new IR(TypeStmt, OPEND(";"), app_IR_node);

  if (idx >= 0) {
    IR *insert_pos_ir = stmt_list_v[idx];

    auto new_res = new IR(TypeStmtList, OPMID(" "), NULL, app_IR_node);

    if (!ir_root->swap_node(
            insert_pos_ir,
            new_res)) { // swap_node only rewrite the parent of insert_pos_ir,
                        // it will not affect     insert_pos_ir.
      new_res->deep_drop();
      std::cerr << "Error: Swap node failure? In function: "
                   "IRWrapper::append_stmt_at_idx. idx = "
                << idx << "\n";
      return false;
    }

    new_res->update_left(insert_pos_ir);

    return true;
  } else { // idx == -1
           // Append at the beginning of the statement.
    IR *insert_pos_ir = stmt_list_v[0];
    if (insert_pos_ir->right_ != NULL) {
      std::cerr << "Error: The first stmt_list is having right_ sub-node. In "
                   "function IRWrapper::append_stmt_at_idx. \n";
      app_IR_node->deep_drop();
      return false;
    }

    // Switch the left and right node of the original stmtlist,
    // and attach the new stmtlist to the left node.
    auto new_res = new IR(TypeStmtList, OPMID(""), app_IR_node, NULL);
    insert_pos_ir->update_right(insert_pos_ir->get_left());
    insert_pos_ir->update_left(new_res);

    return true;
  }
}

bool IRWrapper::remove_stmt_at_idx_and_free(unsigned idx) {

  vector<IR *> stmt_list_v = this->get_stmtlist_IR_vec();

  if (idx >= int(stmt_list_v.size()) || idx < 0) {
    std::cerr << "Error: Input index exceed total statement number. \n In "
                 "function IRWrapper::remove_stmt_at_idx_and_free(). \n";
    return false;
  }

  if (stmt_list_v.size() <= 1) {
    return false;
  }

  IR *rov_stmt = stmt_list_v[idx];

  if (idx != 0 && idx < int(stmt_list_v.size())) {
    IR *parent_node = rov_stmt->get_parent();
    IR *next_stmt = rov_stmt->left_;
    parent_node->swap_node(rov_stmt, next_stmt);
    rov_stmt->left_ = NULL;
    rov_stmt->deep_drop();

  } else { // idx == 0. Remove the first stmt.
    IR *parent_node = rov_stmt->get_parent();
    parent_node->update_left(parent_node->get_right());
    parent_node->right_ = NULL;
    rov_stmt->deep_drop();
  }

  return true;
}

vector<IR *> IRWrapper::get_stmt_ir_vec() {

  vector<IR *> stmtlist_vec = this->get_stmtlist_IR_vec(), stmt_vec;
  if (stmtlist_vec.size() == 0)
    return stmt_vec;

  for (int i = 0; i < stmtlist_vec.size(); i++) {
    if (!stmtlist_vec[i]) {
      cerr << "Error: Found some stmtlist_vec == NULL. Return empty vector. \n";
      continue;
    }

    IR *stmt_ir = get_stmt_ir_from_stmtlist(stmtlist_vec[i]);
    if (stmt_ir != NULL) {
      stmt_vec.push_back(stmt_ir);
    }
  }

  return stmt_vec;
}

bool IRWrapper::remove_stmt_and_free(IR *rov_stmt) {
  vector<IR *> stmt_vec = this->get_stmt_ir_vec();
  int stmt_idx = -1;
  for (int i = 0; i < stmt_vec.size(); i++) {
    if (stmt_vec[i] == rov_stmt) {
      stmt_idx = i;
      break;
    }
  }
  if (stmt_idx == -1) {
    return false;
  } else {
    return this->remove_stmt_at_idx_and_free(stmt_idx);
  }
}

bool IRWrapper::append_components_at_ir(IR *parent_node, IR *app_node,
                                        bool is_left, bool is_replace) {

  if (is_left) {
    if (parent_node->left_ != nullptr) {
      if (!is_replace) {
        cerr << "Append location has content, use is_replace=true if "
                "necessary. Function: IRWrapper::append_components_at_ir. \n";
        return false;
      }
      IR *old_node = parent_node->left_;
      parent_node->detach_node(old_node);
      old_node->deep_drop();
    }
    parent_node->update_left(app_node);
    return true;
  } else {
    if (parent_node->right_ != nullptr) {
      if (!is_replace) {
        cerr << "Append location has content, use is_replace=true if "
                "necessary. Function: IRWrapper::append_components_at_ir. \n";
        return false;
      }
      IR *old_node = parent_node->right_;
      parent_node->detach_node(old_node);
      old_node->deep_drop();
    }
    parent_node->update_right(app_node);
    return true;
  }
}

bool IRWrapper::remove_components_at_ir(IR *rov_ir) {
  if (rov_ir && rov_ir->parent_) {
    IR *parent_node = rov_ir->get_parent();
    parent_node->detach_node(rov_ir);
    rov_ir->deep_drop();
    return true;
  }
  cerr << "Error: rov_ir or rov_ir->parent_ are nullptr. Function "
          "IRWrapper::remove_components_at_ir() \n";
  return false;
}

vector<IR *> IRWrapper::get_all_ir_node(IR *cur_ir_root) {
  this->set_ir_root(cur_ir_root);
  return this->get_all_ir_node();
}

vector<IR *> IRWrapper::get_all_ir_node() {
  if (this->ir_root == nullptr) {
    std::cerr
        << "Error: IRWrapper::ir_root is nullptr. Forget to initilized? \n";
  }
  // Iterate IR binary tree, depth prioritized.
  bool is_finished_search = false;
  std::vector<IR *> ir_vec_iter;
  std::vector<IR *> all_ir_node_vec;
  IR *cur_IR = this->ir_root;
  // Begin iterating.
  while (!is_finished_search) {
    ir_vec_iter.push_back(cur_IR);
    if (cur_IR->type_ != TypeRoot) {
      all_ir_node_vec.push_back(cur_IR);
    } // Ignore kParserTopLevel at the moment, put it at the end of the vector.

    if (cur_IR->left_ != nullptr) {
      cur_IR = cur_IR->left_;
      continue;
    } else { // Reaching the most depth. Consulting ir_vec_iter for right_
             // nodes.
      cur_IR = nullptr;
      while (cur_IR == nullptr) {
        if (ir_vec_iter.size() == 0) {
          is_finished_search = true;
          break;
        }
        cur_IR = ir_vec_iter.back()->right_;
        ir_vec_iter.pop_back();
      }
      continue;
    }
  }
  all_ir_node_vec.push_back(this->ir_root);
  return all_ir_node_vec;
}

int IRWrapper::get_stmt_idx(IR *cur_stmt) {
  vector<IR *> all_stmt_vec = this->get_stmt_ir_vec();
  int output_idx = -1;
  int count = 0;
  for (IR *iter_stmt : all_stmt_vec) {
    if (iter_stmt == cur_stmt) {
      output_idx = count;
      break;
    }
    count++;
  }
  return output_idx;
}

bool IRWrapper::replace_stmt_and_free(IR *old_stmt, IR *new_stmt) {
  int old_stmt_idx = this->get_stmt_idx(old_stmt);
  if (old_stmt_idx < 0) {
    return false;
  }
  if (!this->remove_stmt_at_idx_and_free(old_stmt_idx)) {
    return false;
  }
  if (!this->append_stmt_at_idx(new_stmt, old_stmt_idx - 1)) {
    return false;
  }
  return true;
}

bool IRWrapper::compare_ir_type(IRTYPE left, IRTYPE right) {
  /* Compare two IRTYPE, and see whether they are in the same type of stmt. */
  string left_str = get_string_by_ir_type(left);
  string right_str = get_string_by_ir_type(right);

  /* Cut suffix. */
  size_t cut_pos = left_str.find("_");
  if (cut_pos != -1) {
    left_str = left_str.substr(0, cut_pos);
  }

  cut_pos = right_str.find("_");
  if (cut_pos != -1) {
    right_str = right_str.substr(0, cut_pos);
  }

  if (left_str == right_str) {
    return true;
  } else {
    return false;
  }
}

IRTYPE IRWrapper::get_parent_type(IR *cur_IR, int depth) {
  IR *output_IR = this->get_p_parent_with_a_type(cur_IR, depth);
  if (output_IR == nullptr) {
    return TypeUnknown;
  } else {
    IRTYPE res_ir_type = output_IR->get_ir_type();
    return res_ir_type;
  }
}

IR *IRWrapper::get_p_parent_with_a_type(IR *cur_IR, int depth) {
  IRTYPE prev_ir_type = cur_IR->get_ir_type();
  while (cur_IR->get_parent() != nullptr) {
    IRTYPE parent_type = cur_IR->get_parent()->get_ir_type();
    if (parent_type == prev_ir_type || (parent_type != TypeUnknown)) {
      prev_ir_type = parent_type;
      depth--;
      if (depth <= 0) {
        return cur_IR->get_parent();
      }
    }
    cur_IR = cur_IR->get_parent();
  }
  return nullptr;
}

bool IRWrapper::is_exist_group_clause(IR *cur_stmt) {
  vector<IR *> v_group_clause =
      get_ir_node_in_stmt_with_type(cur_stmt, TypeGroupByClause, false);
  for (IR *group_clause : v_group_clause) {
    if (!group_clause->is_empty()) {
      return true;
    }
  }
  return false;
}

bool IRWrapper::is_exist_having_clause(IR *cur_stmt) {
  vector<IR *> v_having_clause =
      get_ir_node_in_stmt_with_type(cur_stmt, TypeHavingClause, false);
  for (IR *having_clause : v_having_clause) {
    if (!having_clause->is_empty()) {
      return true;
    }
  }
  return false;
}

bool IRWrapper::is_exist_limit_clause(IR *cur_stmt) {
  vector<IR *> v_limit_clause =
      get_ir_node_in_stmt_with_type(cur_stmt, TypeLimit, false);
  for (IR *limit_clause : v_limit_clause) {
    if (!limit_clause->is_empty()) {
      return true;
    }
  }
  return false;
}

bool IRWrapper::is_exist_UNION_SELECT(IR *cur_stmt) {
  if (!cur_stmt) {
    cerr << "Error: Given cur_stmt is NULL. \n";
    return false;
  }
  string to_str = cur_stmt->to_string();
  if (findStringIn(to_str, "UNION")) {
    return true;
  }
  return false;
}

bool IRWrapper::is_exist_INTERSECT_SELECT(IR *cur_stmt) {
  if (!cur_stmt) {
    cerr << "Error: Given cur_stmt is NULL. \n";
    return false;
  }
  string to_str = cur_stmt->to_string();
  if (findStringIn(to_str, "INTERSECT") || findStringIn(to_str, "INTERSECT ALL")) {
    return true;
  }
  return false;
}

bool IRWrapper::is_exist_EXCEPT_SELECT(IR *cur_stmt) {
  if (!cur_stmt) {
    cerr << "Error: Given cur_stmt is NULL. \n";
    return false;
  }
  string to_str = cur_stmt->to_string();
  if (findStringIn(to_str, "EXCEPT") || findStringIn(to_str, "EXCEPT ALL")) {
    return true;
  }
  return false;
}

bool IRWrapper::is_exist_set_operator(IR *cur_stmt) {
  return is_exist_UNION_SELECT(cur_stmt) ||
         is_exist_INTERSECT_SELECT(cur_stmt) ||
         is_exist_EXCEPT_SELECT(cur_stmt);
}

IRTYPE IRWrapper::get_cur_stmt_type_from_sub_ir(IR *cur_ir) {
  while (cur_ir->get_parent() != nullptr) {
    if (cur_ir->get_ir_type() == TypeStmt && cur_ir->get_left()) {
      return cur_ir->get_left()->get_ir_type();
    }
    if (cur_ir->get_ir_type() == TypeStmtList) {
      if (cur_ir->get_right() == nullptr) {
        if (cur_ir->get_left()->get_ir_type() == TypeStmt) {
          return cur_ir->get_left()->get_left()->get_ir_type();
        } else {
          return cur_ir->get_left()->get_ir_type();
        }
      } else {
        if (cur_ir->get_right()->get_ir_type() == TypeStmt) {
          return cur_ir->get_right()->get_left()->get_ir_type();
        } else {
          return cur_ir->get_right()->get_ir_type();
        }
      }
    }
    cur_ir = cur_ir->get_parent();
  }
  return TypeUnknown;
}

IR *IRWrapper::get_stmt_ir_from_stmtlist(IR *cur_stmtlist) {
  if (cur_stmtlist == NULL) {
    cerr << "Getting NULL cur_stmtlist. \n";
    return NULL;
  }
  if (cur_stmtlist->get_ir_type() != TypeStmtList) {
    cerr << "Error: In IRWrapper::get_stmt_ir_from_stmtlist(), not getting "
            "type kStmtmulti. \n";
    return NULL;
  }

  if (cur_stmtlist->get_right()) {
    if (cur_stmtlist->get_right()->get_left()) {
      return cur_stmtlist->get_right()->get_left();
    } else {
      /* Yu: If a stmt has right node, but the right node is an empty stmt,
       * ignored.  */
      return NULL;
    }
  } else if (cur_stmtlist->get_left() &&
             cur_stmtlist->get_left()->get_ir_type() == TypeStmt &&
             cur_stmtlist->get_left()->get_left()) {
    return cur_stmtlist->get_left()->get_left();
  } else {
    return NULL;
  }
}

bool IRWrapper::is_ir_in(IR *sub_ir, IR *par_ir) {

  while (sub_ir) {
    if (sub_ir == par_ir) {
      return true;
    }
    sub_ir = sub_ir->get_parent();
  }
  return false;
}

bool IRWrapper::is_ir_in(IR *sub_ir, IRTYPE par_type) {

  while (sub_ir) {
    if (sub_ir->get_ir_type() == par_type) {
      return true;
    }
    sub_ir = sub_ir->get_parent();
  }
  return false;
}

// Given current node, iterate through all its child node and see if it can find
// matches. Return the matched, otherwise return NULL.
void IRWrapper::iter_cur_node_with_handler(IR *cur_node, handler_t handler) {
  // Recursive function.
  // Depth first search.
  if (cur_node == NULL || handler == NULL) {
    return;
  }

  // Call the handler function to modify all the searched nodes.
  handler(cur_node);

  // Check its left and right child node.
  if (cur_node->get_left()) {
    iter_cur_node_with_handler(cur_node->get_left(), handler);
  }

  if (cur_node->get_right()) {
    iter_cur_node_with_handler(cur_node->get_right(), handler);
  }

  return;
}
