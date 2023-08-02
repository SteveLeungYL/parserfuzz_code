#include "./cockroach_oracle.h"
#include "../AFL/debug.h"
#include "../include/ast.h"

bool SQL_ORACLE::mark_node_valid(IR *root) {
  if (root == nullptr)
    return false;
  /* the following types do not added to the norec_select_stmt list. They should
   * be able to mutate as usual. */
  if ( // root->type_ == kNewExpr || root->type_ == kTableOrSubquery ||
      root->type_ == TypeGroupByClause || root->type_ == TypeWindowSpec)
    return false;
  root->is_node_struct_fixed = true;
  if (root->left_ != nullptr)
    this->mark_node_valid(root->left_);
  if (root->right_ != nullptr)
    this->mark_node_valid(root->right_);
  return true;
}

void SQL_ORACLE::set_mutator(Mutator *mutator) { this->g_mutator = mutator; }

// TODO:: This function is a bit too long.
// guarantee to generate grammarly correct query
IR *SQL_ORACLE::get_random_mutated_select_stmt() {
  /* Read from the previously seen norec compatible select stmt.
   * For example, for NOREC: SELECT COUNT ( * ) FROM ... WHERE ...;
   * mutate them, and then return the string of the new generated
   * norec compatible SELECT query.
   */
  bool is_success = false;
  vector<IR *> ir_tree;
  IR *root = NULL;
  string new_valid_select_str = "";

  total_rand_valid += 1;
  bool use_temp = false;

  while (!is_success) {

    string ori_valid_select = "";
    use_temp = g_mutator->get_select_str_from_lib(ori_valid_select);

    ir_tree.clear();
    ir_tree = g_mutator->parse_query_str_get_ir_set(ori_valid_select);

    if (ir_tree.size() == 0) {
      continue;
    }

    root = ir_tree.back();

    if (!g_mutator->check_node_num(root, 300)) {
      root->deep_drop();
      root = NULL;
      continue;
    }

    IR *cur_ir_stmt = ir_wrapper.get_first_stmt_from_root(root);

    if (!this->is_oracle_select_stmt(cur_ir_stmt)) {
      root->deep_drop();
      root = NULL;
      continue;
    }

    bool has_where_clause = true;
    if (!(ir_wrapper.is_exist_ir_node_in_stmt_with_type(cur_ir_stmt, TypeWhereClause))) {
      // If the retrieved IR node is a simple SELECT statement that comes without
      // WHERE, try not to use it and gives it 80% chances to skip.
      has_where_clause = false;
      if (get_rand_int(5)) {
        root->deep_drop();
        root = NULL;
        continue;
      }
    }

    /* If we are using a non template valid stmt from the p_oracle lib:
     *  2/3 of chances to return the stmt immediate without mutation.
     *  1/3 of chances to return with further mutation.
     */
    // cout << "ori_valid_select: " << ori_valid_select << endl;
    if (!use_temp && get_rand_int(3) < 2) {
      IR *returned_stmt_ir = cur_ir_stmt->deep_copy();
      root->deep_drop();
      return returned_stmt_ir;
    }

    /* Restrict changes on the signiture norec select components. Could increase
     * mutation efficiency. */
    mark_all_valid_node(ir_tree.back());

    IR* ori_extract_struct_deep_root = root->deep_copy();
    string ori_valid_select_struct = g_mutator->extract_struct_deep(ori_extract_struct_deep_root);
    ori_extract_struct_deep_root->deep_drop();
    g_mutator->extract_struct(root);
    string new_valid_select_struct = "";

    /* For every retrived norec stmt, and its parsed IR tree, give it 100 trials
     * to mutate.
     */
    for (int trial_count = 0; trial_count < 30; trial_count++) {

      num_oracle_select_mutate++;

      /* Pick random ir node in the select stmt */
      bool is_mutate_ir_node_chosen = false;
      IR *mutate_ir_node = NULL;
      IR *new_mutated_ir_node = NULL;
      int choose_node_trial = 0;
      while (!is_mutate_ir_node_chosen) {
        if (choose_node_trial > 100)
          break;
        choose_node_trial++;
        ir_tree = this->ir_wrapper.get_all_ir_node(root);
        mutate_ir_node = ir_tree[get_rand_int(
            ir_tree.size() - 1)]; // Do not choose the program_root to mutate.
        if (mutate_ir_node == NULL) {
          continue;
        }
        if (mutate_ir_node->is_node_struct_fixed) {
          continue;
        }
        if (has_where_clause && !ir_wrapper.is_ir_in(mutate_ir_node, TypeWhereClause)) {
          // If the SELECT statement comes with the WHERE clause, but
          // the mutated nodes does not choose the expressions to the where clause,
          // re-choose the mutated IR with possibility 80%.
          if (get_rand_int(5)) {
            // Re-choose mutated IR node.
            continue;
          }
        }

        is_mutate_ir_node_chosen = true;
        break;
      }

      if (!is_mutate_ir_node_chosen)
        break; // The current ir tree cannot even find the node to mutate.
               // Ignored and retrive new norec stmt from lib or from library.
      switch (get_rand_int(3)) {
      case 0: {

        new_mutated_ir_node = g_mutator->strategy_delete(mutate_ir_node);

        break;
      }
      case 1: {
        new_mutated_ir_node = g_mutator->strategy_insert(mutate_ir_node);
        break;
      }
      case 2: {
        new_mutated_ir_node = g_mutator->strategy_replace(mutate_ir_node);
        break;
      }
      }

      if (new_mutated_ir_node == NULL) {
        continue;
      }

      if (!root->swap_node(mutate_ir_node, new_mutated_ir_node)) {
        new_mutated_ir_node->deep_drop();
        continue;
      }

      new_valid_select_str = root->to_string();

      if (new_valid_select_str != ori_valid_select) {
        g_mutator->extract_struct(root);
        IR* extract_struct_deep_root = root->deep_copy();
        new_valid_select_struct = g_mutator->extract_struct_deep(extract_struct_deep_root);
        extract_struct_deep_root->deep_drop();
      }

      root->swap_node(new_mutated_ir_node, mutate_ir_node);
      new_mutated_ir_node->deep_drop();
      if (new_valid_select_str == ori_valid_select) {
        continue;
      }

      /* Final check and return string if compatible */
      vector<IR *> new_ir_verified =
          g_mutator->parse_query_str_get_ir_set(new_valid_select_str);

      if (new_ir_verified.size() <= 0) {
        continue;
      }

      // Make sure the mutated structure is different.
      IR *new_ir_verified_stmt =
          ir_wrapper.get_first_stmt_from_root(new_ir_verified.back());

      if (this->is_oracle_select_stmt(new_ir_verified_stmt) &&
          new_valid_select_struct != ori_valid_select_struct) {
        root->deep_drop();
        is_success = true;

        if (use_temp)
          total_temp++;

        IR *returned_stmt_ir = new_ir_verified_stmt->deep_copy();
        new_ir_verified.back()->deep_drop();
        num_oracle_select_succeed++;
        return returned_stmt_ir;
      } else {
        new_ir_verified.back()->deep_drop();
      }

      continue; // Retry mutating the current norec stmt and its IR tree.
    }

    /* Failed to mutate the retrived norec select stmt after 100 trials.
     * Maybe it is because the norec select stmt is too complex the mutate.
     * Grab another norec select stmt from the lib or from the template, try
     * again.
     */
    root->deep_drop();
    root = NULL;
  }
  return nullptr;
}

int SQL_ORACLE::count_oracle_select_stmts(IR *ir_root) {
  ir_wrapper.set_ir_root(ir_root);
  vector<IR *> stmt_vec = ir_wrapper.get_stmt_ir_vec();

  int oracle_stmt_num = 0;
  for (IR *cur_stmt : stmt_vec) {
    if (this->is_oracle_select_stmt(cur_stmt)) {
      oracle_stmt_num++;
    }
  }
  return oracle_stmt_num;
}

int SQL_ORACLE::count_oracle_normal_stmts(IR *ir_root) {
  ir_wrapper.set_ir_root(ir_root);
  vector<IR *> stmt_vec = ir_wrapper.get_stmt_ir_vec();

  int oracle_stmt_num = 0;
  for (IR *cur_stmt : stmt_vec) {
    if (this->is_oracle_normal_stmt(cur_stmt)) {
      oracle_stmt_num++;
    }
  }
  return oracle_stmt_num;
}

bool SQL_ORACLE::is_oracle_select_stmt(IR *cur_IR) {
  if (cur_IR != NULL && cur_IR->type_ == TypeSelectStmt) {
    /* For dummy function, treat all SELECT stmt as oracle function.  */
    return true;
  }
  return false;
}

void SQL_ORACLE::remove_select_stmt_from_ir(IR *ir_root) {
  ir_wrapper.set_ir_root(ir_root);
  vector<IR *> stmt_vec = ir_wrapper.get_stmt_ir_vec(ir_root);
  for (IR *cur_stmt : stmt_vec) {
    if (cur_stmt->type_ == TypeSelectStmt) {
      ir_wrapper.remove_stmt_and_free(cur_stmt);
    }
  }
  return;
}

void SQL_ORACLE::remove_set_stmt_from_ir(IR *ir_root) {
    ir_wrapper.set_ir_root(ir_root);
    vector<IR *> stmt_vec = ir_wrapper.get_stmt_ir_vec(ir_root);
    for (IR *cur_stmt : stmt_vec) {
        if (cur_stmt->type_ == TypeSetStmt) {
            ir_wrapper.remove_stmt_and_free(cur_stmt);
        }
    }
    return;
}

void SQL_ORACLE::remove_oracle_select_stmt_from_ir(IR *ir_root) {
  ir_wrapper.set_ir_root(ir_root);
  vector<IR *> stmt_vec = ir_wrapper.get_stmt_ir_vec(ir_root);
  for (IR *cur_stmt : stmt_vec) {
    if (this->is_oracle_select_stmt(cur_stmt)) {
      ir_wrapper.remove_stmt_and_free(cur_stmt);
    }
  }
  return;
}

string SQL_ORACLE::remove_select_stmt_from_str(string in) {
  vector<IR *> ir_set = g_mutator->parse_query_str_get_ir_set(in);
  if (ir_set.size() == 0) {
    cerr << "Error: ir_set size is 0. \n";
  }
  IR *ir_root = ir_set.back();
  remove_select_stmt_from_ir(ir_root);
  string res_str = ir_root->to_string();
  ir_root->deep_drop();
  return res_str;
}

string SQL_ORACLE::remove_oracle_select_stmt_from_str(string in) {
  vector<IR *> ir_set = g_mutator->parse_query_str_get_ir_set(in);
  if (ir_set.size() == 0) {
    cerr << "Error: ir_set size is 0. \n";
  }
  IR *ir_root = ir_set.back();
  remove_oracle_select_stmt_from_ir(ir_root);
  string res_str = ir_root->to_string();
  ir_root->deep_drop();
  return res_str;
}

bool SQL_ORACLE::is_oracle_select_stmt(string in) {
  vector<IR *> ir_vec = g_mutator->parse_query_str_get_ir_set(in);
  if (!ir_vec.size()) {
    cerr << "Error: getting empty ir_vec. Parsing failed. \n";
    cerr << "Error stmt: " << in << "\n\n\n";
    return false;
  }
  IR *cur_stmt = ir_wrapper.get_first_stmt_from_root(ir_vec.back());
  if (cur_stmt == NULL) {
    cerr << "Error: Cannot find the stmt inside the ir_vec(). \n";
    return false;
  }
  bool res = is_oracle_select_stmt(cur_stmt);
  ir_vec.back()->deep_drop();
  return res;
}

bool SQL_ORACLE::is_oracle_normal_stmt(string in) {
  vector<IR *> ir_vec = g_mutator->parse_query_str_get_ir_set(in);
  if (!ir_vec.size()) {
    cerr << "Error: getting empty ir_vec. Parsing failed. \n";
    cerr << "Error stmt: " << in << "\n\n\n";
    return false;
  }
  IR *cur_stmt = ir_wrapper.get_first_stmt_from_root(ir_vec.back());
  if (cur_stmt == NULL) {
    cerr << "Error: Cannot find the stmt inside the ir_vec(). \n";
    return false;
  }
  bool res = is_oracle_normal_stmt(cur_stmt);
  ir_vec.back()->deep_drop();
  return res;
}

SemanticErrorType SQL_ORACLE::detect_semantic_error_type(string in_str) {
    if (
            (
                    findStringIn(in_str, "unsupported comparison") &&
                    findStringIn(in_str, "operator:")
            ) ||
            findStringIn(in_str, "pq: unknown signature") ||
            findStringIn(in_str, "parsing as type") ||
            findStringIn(in_str, "pq: type") ||
            findStringIn(in_str, "cannot subscript type string") ||
            findStringIn(in_str, "function undefined") ||
            findStringIn(in_str, "to be of type") ||
            findStringIn(in_str, "pq: ambiguous call") ||
            findStringIn(in_str, "pq: unsupported binary operator") ||
            findStringIn(in_str, "invalid cast") ||
            (
                    findStringIn(in_str, "could not parse") &&
                    findStringIn(in_str, "as ")
            ) ||
          (
          findStringIn(in_str, "argument of WHERE must be type ") &&
          findStringIn(in_str, "not type ")
          )
            ) {
        return SemanticErrorType::ColumnTypeRelatedError;
    } else if (
            findStringIn(in_str, "ERROR: source") ||
            findStringIn(in_str, "pq: source") ||
            findStringIn(in_str, "pq: column")
    ) {
        return SemanticErrorType::AliasRelatedError;
    } else if (
            findStringIn(in_str, "invalid syntax") ||
            findStringIn(in_str, "syntax error") ||
            findStringIn(in_str, "invalid syntax")
            ) {
        return SemanticErrorType::SyntaxRelatedError;
    } else if (
            findStringIn(in_str, "Error") ||
            findStringIn(in_str, "ERROR") ||
            findStringIn(in_str, "pq: ")
            ) {
        return SemanticErrorType::OtherUndefinedError;
    } else {
        return SemanticErrorType::NoSemanticError;
    }
}

bool SQL_ORACLE::is_expr_types_in_where_clause(IRTYPE in) {

    switch (in) {
    ALLEXPRTYPESINWHERE
        return true;
    default:
        return false;
    }

}

void SQL_ORACLE::init_operator_supported_types() {

#define addType(ret, left, right) v_types.push_back(Binary_Operator(ret, left, right));
#define save(x) this->operator_supported_types_lib[x]=v_types; v_types.clear();

  vector<Binary_Operator> v_types;

  addType(AFFIINT, AFFIINT, AFFIINT);
  addType(AFFIBIT, AFFIBIT, AFFIBIT);
  save("#");

  addType(AFFIJSONB, AFFIJSONB, AFFIARRAYSTRING);
  save("#>");

  addType(AFFISTRING, AFFIJSONB, AFFIARRAYSTRING);
  save("#>>");

  addType(AFFIDECIMAL, AFFIDECIMAL, AFFIDECIMAL);
  addType(AFFIDECIMAL, AFFIDECIMAL, AFFIINT);
  addType(AFFIFLOAT, AFFIFLOAT, AFFIFLOAT);
  addType(AFFIDECIMAL, AFFIINT, AFFIDECIMAL);
  addType(AFFIINT, AFFIINT, AFFIINT);
  addType(AFFIBOOL, AFFISTRING, AFFISTRING);
  save("%");

  addType(AFFIINET, AFFIINET, AFFIINET);
  addType(AFFIINT, AFFIINT, AFFIINT);
  addType(AFFIBIT, AFFIBIT, AFFIBIT);
  save("&");

  addType(AFFIBOOL, AFFIINET, AFFIINET);
  save("&&");

  addType(AFFIDECIMAL, AFFIDECIMAL, AFFIDECIMAL);
  addType(AFFIDECIMAL, AFFIDECIMAL, AFFIINT);
  addType(AFFIDECIMAL, AFFIDECIMAL, AFFIINTERVAL);
  addType(AFFIINTERVAL, AFFIFLOAT, AFFIFLOAT);
  addType(AFFIFLOAT, AFFIFLOAT, AFFIFLOAT);
  addType(AFFIFLOAT, AFFIFLOAT, AFFIFLOAT);
  addType(AFFIINTERVAL, AFFIFLOAT, AFFIINTERVAL);
  addType(AFFIINTERVAL, AFFIFLOAT, AFFIINTERVAL);
  addType(AFFIDECIMAL, AFFIINT, AFFIDECIMAL);
  addType(AFFIDECIMAL, AFFIINT, AFFIDECIMAL);
  addType(AFFIINT, AFFIINT, AFFIINT);
  addType(AFFIINTERVAL, AFFIINT, AFFIINTERVAL);
  addType(AFFIINTERVAL, AFFIINTERVAL, AFFIDECIMAL);
  addType(AFFIINTERVAL, AFFIINTERVAL, AFFIFLOAT);
  addType(AFFIINTERVAL, AFFIINTERVAL, AFFIINT);
  save("*");

  addType(AFFIDECIMAL, AFFIDECIMAL, AFFIDECIMAL);
  addType(AFFIFLOAT, AFFIFLOAT, AFFIFLOAT);
  addType(AFFIINT, AFFIINT, AFFIINT);
  addType(AFFIINTERVAL, AFFIINTERVAL, AFFIINTERVAL);
  addType(AFFIDATE, AFFIDATE, AFFIINT);
  addType(AFFITIMESTAMP, AFFIDATE, AFFIINTERVAL);
  addType(AFFITIMESTAMP, AFFIDATE, AFFITIME);
  addType(AFFITIMESTAMPTZ, AFFIDATE, AFFITIMETZ);
  addType(AFFITIMESTAMPTZ, AFFIDATE, AFFIINT);
  addType(AFFIINET, AFFIINT, AFFIINET);
  addType(AFFITIMESTAMP, AFFIINTERVAL, AFFIDATE);
  addType(AFFITIME, AFFIINTERVAL, AFFITIME);
  addType(AFFITIME, AFFIINTERVAL, AFFITIME);
  addType(AFFITIMESTAMP, AFFIINTERVAL, AFFITIMESTAMP);
  addType(AFFITIMESTAMPTZ, AFFIINTERVAL, AFFITIMESTAMPTZ);
  addType(AFFITIMETZ, AFFIINTERVAL, AFFITIMETZ);
  addType(AFFITIMESTAMP, AFFITIME, AFFIDATE);
  addType(AFFITIME, AFFITIME, AFFIINTERVAL);
  addType(AFFITIMESTAMP, AFFITIMESTAMP, AFFIINTERVAL);
  addType(AFFITIMESTAMPTZ, AFFITIMESTAMPTZ, AFFIINTERVAL);
  addType(AFFITIMESTAMPTZ, AFFITIMETZ, AFFIDATE);
  addType(AFFITIMETZ, AFFITIMETZ, AFFIINTERVAL);
  save("+");

  addType(AFFIDECIMAL, AFFIDECIMAL, AFFIDECIMAL);
  addType(AFFIFLOAT, AFFIFLOAT, AFFIFLOAT);
  addType(AFFIINT, AFFIINT, AFFIINT);
  addType(AFFIINTERVAL, AFFIINTERVAL, AFFIINTERVAL);
  addType(AFFIDATE, AFFIDATE, AFFIDATE);
  addType(AFFIDATE, AFFIDATE, AFFIINT);
  addType(AFFITIMESTAMP, AFFIDATE, AFFIINTERVAL);
  addType(AFFITIMESTAMP, AFFIDATE, AFFITIME);
  addType(AFFIDECIMAL, AFFIDECIMAL, AFFIINT);
  addType(AFFIINT, AFFIINET, AFFIINET);
  addType(AFFIINET, AFFIINET, AFFIINT);
  addType(AFFIDECIMAL, AFFIINT, AFFIDECIMAL);
  addType(AFFIJSONB, AFFIJSONB, AFFIINT);
  addType(AFFIJSONB, AFFIJSONB, AFFISTRING);
  addType(AFFIJSONB, AFFIJSONB, AFFIARRAYSTRING);
  addType(AFFITIME, AFFITIME, AFFIINTERVAL);
  addType(AFFIINTERVAL, AFFITIME, AFFITIME);
  addType(AFFITIMESTAMP, AFFITIMESTAMP, AFFIINTERVAL);
  addType(AFFIINTERVAL, AFFITIMESTAMP, AFFITIMESTAMP);
  addType(AFFIINTERVAL, AFFITIMESTAMP, AFFITIMESTAMPTZ);
  addType(AFFITIMESTAMPTZ, AFFITIMESTAMPTZ, AFFIINTERVAL);
  addType(AFFIINTERVAL, AFFITIMESTAMPTZ, AFFITIMESTAMP);
  addType(AFFIINTERVAL, AFFITIMESTAMPTZ, AFFITIMESTAMPTZ);
  addType(AFFITIMETZ, AFFITIMETZ, AFFIINTERVAL);
  save("-");

  addType(AFFIJSONB, AFFIJSONB, AFFIINT);
  addType(AFFIJSONB, AFFIJSONB, AFFISTRING);
  save("->");

  addType(AFFISTRING, AFFIJSONB, AFFIINT);
  addType(AFFISTRING, AFFIJSONB, AFFISTRING);
  save("->>");

  addType(AFFIDECIMAL, AFFIDECIMAL, AFFIDECIMAL);
  addType(AFFIDECIMAL, AFFIDECIMAL, AFFIINT);
  addType(AFFIFLOAT, AFFIFLOAT, AFFIFLOAT);
  addType(AFFIDECIMAL, AFFIINT, AFFIDECIMAL);
  addType(AFFIDECIMAL, AFFIINT, AFFIINT);
  addType(AFFIINTERVAL, AFFIINTERVAL, AFFIFLOAT);
  addType(AFFIINTERVAL, AFFIINTERVAL, AFFIINT);
  save("/");

  addType(AFFIDECIMAL, AFFIDECIMAL, AFFIDECIMAL);
  addType(AFFIDECIMAL, AFFIDECIMAL, AFFIINT);
  addType(AFFIFLOAT, AFFIFLOAT, AFFIFLOAT);
  addType(AFFIDECIMAL, AFFIINT, AFFIDECIMAL);
  addType(AFFIINT, AFFIINT, AFFIINT);
  save("//");

  addType(AFFIBOOL, AFFIBOOL, AFFIBOOL);
  addType(AFFIBOOL, AFFIARRAYBOOL, AFFIARRAYBOOL);
  addType(AFFIBOOL, AFFIBYTES, AFFIBYTES);
  addType(AFFIBOOL, AFFIARRAYBYTES, AFFIARRAYBYTES);
  addType(AFFIBOOL, AFFIDATE, AFFIDATE);
  addType(AFFIBOOL, AFFIDATE, AFFITIMESTAMP);
  addType(AFFIBOOL, AFFIDATE, AFFITIMESTAMPTZ);
  addType(AFFIBOOL, AFFIARRAYDATE, AFFIARRAYDATE);
  addType(AFFIBOOL, AFFIDECIMAL, AFFIDECIMAL);
  addType(AFFIBOOL, AFFIDECIMAL, AFFIFLOAT);
  addType(AFFIBOOL, AFFIDECIMAL, AFFIINT);
  addType(AFFIBOOL, AFFIARRAYDECIMAL, AFFIARRAYDECIMAL);
  addType(AFFIBOOL, AFFIFLOAT, AFFIDECIMAL);
  addType(AFFIBOOL, AFFIFLOAT, AFFIFLOAT);
  addType(AFFIBOOL, AFFIFLOAT, AFFIINT);
  addType(AFFIBOOL, AFFIARRAYFLOAT, AFFIARRAYFLOAT);
  addType(AFFIBOOL, AFFIINET, AFFIINET);
  addType(AFFIBOOL, AFFIARRAYINET, AFFIARRAYINET);
  addType(AFFIBOOL, AFFIINT, AFFIDECIMAL);
  addType(AFFIBOOL, AFFIINT, AFFIFLOAT);
  addType(AFFIBOOL, AFFIINT, AFFIINT);
  addType(AFFIBOOL, AFFIINT, AFFIOID);
  addType(AFFIBOOL, AFFIARRAYINT, AFFIARRAYINT);
  addType(AFFIBOOL, AFFIINTERVAL, AFFIINTERVAL);
  addType(AFFIBOOL, AFFIARRAYINTERVAL, AFFIARRAYINTERVAL);
  addType(AFFIBOOL, AFFIJSONB, AFFIJSONB);
  addType(AFFIBOOL, AFFIOID, AFFIINT);
  addType(AFFIBOOL, AFFIOID, AFFIOID);
  addType(AFFIBOOL, AFFISTRING, AFFISTRING);
  addType(AFFIBOOL, AFFIARRAYSTRING, AFFIARRAYSTRING);
  addType(AFFIBOOL, AFFITIME, AFFITIME);
  addType(AFFIBOOL, AFFITIME, AFFITIMETZ);
  addType(AFFIBOOL, AFFIARRAYTIME, AFFIARRAYTIME);
  addType(AFFIBOOL, AFFITIMESTAMP, AFFIDATE);
  addType(AFFIBOOL, AFFITIMESTAMP, AFFITIMESTAMP);
  addType(AFFIBOOL, AFFITIMESTAMP, AFFITIMESTAMPTZ);
  addType(AFFIBOOL, AFFIARRAYTIMESTAMP, AFFIARRAYTIMESTAMP);
  addType(AFFIBOOL, AFFITIMESTAMPTZ, AFFIDATE);
  addType(AFFIBOOL, AFFITIMESTAMPTZ, AFFITIMESTAMP);
  addType(AFFIBOOL, AFFITIMESTAMPTZ, AFFITIMESTAMPTZ);
  addType(AFFIBOOL, AFFITIMETZ, AFFITIME);
  addType(AFFIBOOL, AFFITIMETZ, AFFITIMETZ);
  addType(AFFIBOOL, AFFITUPLE, AFFITUPLE);
  addType(AFFIBOOL, AFFIUUID, AFFIUUID);
  addType(AFFIBOOL, AFFIARRAYUUID, AFFIARRAYUUID);
  addType(AFFIBOOL, AFFIBIT, AFFIBIT);
  save("<");

  addType(AFFIBOOL, AFFIINET, AFFIINET);
  addType(AFFIINT, AFFIINT, AFFIINT);
  addType(AFFIBIT, AFFIBIT, AFFIINT);
  save("<<");

  addType(AFFIBOOL, AFFIBOOL, AFFIBOOL);
  addType(AFFIBOOL, AFFIARRAYBOOL, AFFIARRAYBOOL);
  addType(AFFIBOOL, AFFIBYTES, AFFIBYTES);
  addType(AFFIBOOL, AFFIARRAYBYTES, AFFIARRAYBYTES);
  addType(AFFIBOOL, AFFIDATE, AFFIDATE);
  addType(AFFIBOOL, AFFIDATE, AFFITIMESTAMP);
  addType(AFFIBOOL, AFFIDATE, AFFITIMESTAMPTZ);
  addType(AFFIBOOL, AFFIARRAYDATE, AFFIARRAYDATE);
  addType(AFFIBOOL, AFFIDECIMAL, AFFIDECIMAL);
  addType(AFFIBOOL, AFFIDECIMAL, AFFIFLOAT);
  addType(AFFIBOOL, AFFIDECIMAL, AFFIINT);
  addType(AFFIBOOL, AFFIARRAYDECIMAL, AFFIARRAYDECIMAL);
  addType(AFFIBOOL, AFFIFLOAT, AFFIDECIMAL);
  addType(AFFIBOOL, AFFIFLOAT, AFFIFLOAT);
  addType(AFFIBOOL, AFFIFLOAT, AFFIINT);
  addType(AFFIBOOL, AFFIARRAYFLOAT, AFFIARRAYFLOAT);
  addType(AFFIBOOL, AFFIINET, AFFIINET);
  addType(AFFIBOOL, AFFIARRAYINET, AFFIARRAYINET);
  addType(AFFIBOOL, AFFIINT, AFFIDECIMAL);
  addType(AFFIBOOL, AFFIINT, AFFIFLOAT);
  addType(AFFIBOOL, AFFIINT, AFFIINT);
  addType(AFFIBOOL, AFFIINT, AFFIOID);
  addType(AFFIBOOL, AFFIARRAYINT, AFFIARRAYINT);
  addType(AFFIBOOL, AFFIINTERVAL, AFFIINTERVAL);
  addType(AFFIBOOL, AFFIARRAYINTERVAL, AFFIARRAYINTERVAL);
  addType(AFFIBOOL, AFFIJSONB, AFFIJSONB);
  addType(AFFIBOOL, AFFIOID, AFFIINT);
  addType(AFFIBOOL, AFFIOID, AFFIOID);
  addType(AFFIBOOL, AFFISTRING, AFFISTRING);
  addType(AFFIBOOL, AFFIARRAYSTRING, AFFIARRAYSTRING);
  addType(AFFIBOOL, AFFITIME, AFFITIME);
  addType(AFFIBOOL, AFFITIME, AFFITIMETZ);
  addType(AFFIBOOL, AFFIARRAYTIME, AFFIARRAYTIME);
  addType(AFFIBOOL, AFFITIMESTAMP, AFFIDATE);
  addType(AFFIBOOL, AFFITIMESTAMP, AFFITIMESTAMP);
  addType(AFFIBOOL, AFFITIMESTAMP, AFFITIMESTAMPTZ);
  addType(AFFIBOOL, AFFIARRAYTIMESTAMP, AFFIARRAYTIMESTAMP);
  addType(AFFIBOOL, AFFITIMESTAMPTZ, AFFIDATE);
  addType(AFFIBOOL, AFFITIMESTAMPTZ, AFFITIMESTAMP);
  addType(AFFIBOOL, AFFITIMESTAMPTZ, AFFITIMESTAMPTZ);
  addType(AFFIBOOL, AFFITIMETZ, AFFITIME);
  addType(AFFIBOOL, AFFITIMETZ, AFFITIMETZ);
  addType(AFFIBOOL, AFFITUPLE, AFFITUPLE);
  addType(AFFIBOOL, AFFIUUID, AFFIUUID);
  addType(AFFIBOOL, AFFIARRAYUUID, AFFIARRAYUUID);
  addType(AFFIBOOL, AFFIBIT, AFFIBIT);
  save("<=");

  addType(AFFIBOOL, AFFIBOOL, AFFIBOOL);
  addType(AFFIBOOL, AFFIARRAYBOOL, AFFIARRAYBOOL);
  addType(AFFIBOOL, AFFIBYTES, AFFIBYTES);
  addType(AFFIBOOL, AFFIARRAYBYTES, AFFIARRAYBYTES);
  addType(AFFIBOOL, AFFIDATE, AFFIDATE);
  addType(AFFIBOOL, AFFIDATE, AFFITIMESTAMP);
  addType(AFFIBOOL, AFFIDATE, AFFITIMESTAMPTZ);
  addType(AFFIBOOL, AFFIARRAYDATE, AFFIARRAYDATE);
  addType(AFFIBOOL, AFFIDECIMAL, AFFIDECIMAL);
  addType(AFFIBOOL, AFFIDECIMAL, AFFIFLOAT);
  addType(AFFIBOOL, AFFIDECIMAL, AFFIINT);
  addType(AFFIBOOL, AFFIARRAYDECIMAL, AFFIARRAYDECIMAL);
  addType(AFFIBOOL, AFFIFLOAT, AFFIDECIMAL);
  addType(AFFIBOOL, AFFIFLOAT, AFFIFLOAT);
  addType(AFFIBOOL, AFFIFLOAT, AFFIINT);
  addType(AFFIBOOL, AFFIARRAYFLOAT, AFFIARRAYFLOAT);
  addType(AFFIBOOL, AFFIINET, AFFIINET);
  addType(AFFIBOOL, AFFIARRAYINET, AFFIARRAYINET);
  addType(AFFIBOOL, AFFIINT, AFFIDECIMAL);
  addType(AFFIBOOL, AFFIINT, AFFIFLOAT);
  addType(AFFIBOOL, AFFIINT, AFFIINT);
  addType(AFFIBOOL, AFFIINT, AFFIOID);
  addType(AFFIBOOL, AFFIARRAYINT, AFFIARRAYINT);
  addType(AFFIBOOL, AFFIINTERVAL, AFFIINTERVAL);
  addType(AFFIBOOL, AFFIARRAYINTERVAL, AFFIARRAYINTERVAL);
  addType(AFFIBOOL, AFFIJSONB, AFFIJSONB);
  addType(AFFIBOOL, AFFIOID, AFFIINT);
  addType(AFFIBOOL, AFFIOID, AFFIOID);
  addType(AFFIBOOL, AFFISTRING, AFFISTRING);
  addType(AFFIBOOL, AFFIARRAYSTRING, AFFIARRAYSTRING);
  addType(AFFIBOOL, AFFITIME, AFFITIME);
  addType(AFFIBOOL, AFFITIME, AFFITIMETZ);
  addType(AFFIBOOL, AFFIARRAYTIME, AFFIARRAYTIME);
  addType(AFFIBOOL, AFFITIMESTAMP, AFFIDATE);
  addType(AFFIBOOL, AFFITIMESTAMP, AFFITIMESTAMP);
  addType(AFFIBOOL, AFFITIMESTAMP, AFFITIMESTAMPTZ);
  addType(AFFIBOOL, AFFIARRAYTIMESTAMP, AFFIARRAYTIMESTAMP);
  addType(AFFIBOOL, AFFITIMESTAMPTZ, AFFIDATE);
  addType(AFFIBOOL, AFFITIMESTAMPTZ, AFFITIMESTAMP);
  addType(AFFIBOOL, AFFITIMESTAMPTZ, AFFITIMESTAMPTZ);
  addType(AFFIBOOL, AFFITIMETZ, AFFITIME);
  addType(AFFIBOOL, AFFITIMETZ, AFFITIMETZ);
  addType(AFFIBOOL, AFFITUPLE, AFFITUPLE);
  addType(AFFIBOOL, AFFIUUID, AFFIUUID);
  addType(AFFIBOOL, AFFIARRAYUUID, AFFIARRAYUUID);
  addType(AFFIBOOL, AFFIBIT, AFFIBIT);
  save(">=");


  addType(AFFIBOOL, AFFIJSONB, AFFIJSONB);
  save("<@");


  addType(AFFIBOOL, AFFIBOOL, AFFIBOOL);
  addType(AFFIBOOL, AFFIARRAYBOOL, AFFIARRAYBOOL);
  addType(AFFIBOOL, AFFIBYTES, AFFIBYTES);
  addType(AFFIBOOL, AFFIARRAYBYTES, AFFIARRAYBYTES);
  addType(AFFIBOOL, AFFIDATE, AFFIDATE);
  addType(AFFIBOOL, AFFIDATE, AFFITIMESTAMP);
  addType(AFFIBOOL, AFFIDATE, AFFITIMESTAMPTZ);
  addType(AFFIBOOL, AFFIARRAYDATE, AFFIARRAYDATE);
  addType(AFFIBOOL, AFFIDECIMAL, AFFIDECIMAL);
  addType(AFFIBOOL, AFFIDECIMAL, AFFIFLOAT);
  addType(AFFIBOOL, AFFIDECIMAL, AFFIINT);
  addType(AFFIBOOL, AFFIARRAYDECIMAL, AFFIARRAYDECIMAL);
  addType(AFFIBOOL, AFFIFLOAT, AFFIDECIMAL);
  addType(AFFIBOOL, AFFIFLOAT, AFFIFLOAT);
  addType(AFFIBOOL, AFFIFLOAT, AFFIINT);
  addType(AFFIBOOL, AFFIARRAYFLOAT, AFFIARRAYFLOAT);
  addType(AFFIBOOL, AFFIINET, AFFIINET);
  addType(AFFIBOOL, AFFIARRAYINET, AFFIARRAYINET);
  addType(AFFIBOOL, AFFIINT, AFFIDECIMAL);
  addType(AFFIBOOL, AFFIINT, AFFIFLOAT);
  addType(AFFIBOOL, AFFIINT, AFFIINT);
  addType(AFFIBOOL, AFFIINT, AFFIOID);
  addType(AFFIBOOL, AFFIARRAYINT, AFFIARRAYINT);
  addType(AFFIBOOL, AFFIINTERVAL, AFFIINTERVAL);
  addType(AFFIBOOL, AFFIARRAYINTERVAL, AFFIARRAYINTERVAL);
  addType(AFFIBOOL, AFFIJSONB, AFFIJSONB);
  addType(AFFIBOOL, AFFIOID, AFFIINT);
  addType(AFFIBOOL, AFFIOID, AFFIOID);
  addType(AFFIBOOL, AFFISTRING, AFFISTRING);
  addType(AFFIBOOL, AFFIARRAYSTRING, AFFIARRAYSTRING);
  addType(AFFIBOOL, AFFITIME, AFFITIME);
  addType(AFFIBOOL, AFFITIME, AFFITIMETZ);
  addType(AFFIBOOL, AFFIARRAYTIME, AFFIARRAYTIME);
  addType(AFFIBOOL, AFFITIMESTAMP, AFFIDATE);
  addType(AFFIBOOL, AFFITIMESTAMP, AFFITIMESTAMP);
  addType(AFFIBOOL, AFFITIMESTAMP, AFFITIMESTAMPTZ);
  addType(AFFIBOOL, AFFIARRAYTIMESTAMP, AFFIARRAYTIMESTAMP);
  addType(AFFIBOOL, AFFITIMESTAMPTZ, AFFIDATE);
  addType(AFFIBOOL, AFFITIMESTAMPTZ, AFFITIMESTAMP);
  addType(AFFIBOOL, AFFITIMESTAMPTZ, AFFITIMESTAMPTZ);
  addType(AFFIBOOL, AFFITIMETZ, AFFITIME);
  addType(AFFIBOOL, AFFITIMETZ, AFFITIMETZ);
  addType(AFFIBOOL, AFFITUPLE, AFFITUPLE);
  addType(AFFIBOOL, AFFIUUID, AFFIUUID);
  addType(AFFIBOOL, AFFIARRAYUUID, AFFIARRAYUUID);
  addType(AFFIBOOL, AFFIBIT, AFFIBIT);
  save("=");


  addType(AFFIBOOL, AFFIBOOL, AFFIBOOL);
  addType(AFFIBOOL, AFFIARRAYBOOL, AFFIARRAYBOOL);
  addType(AFFIBOOL, AFFIBYTES, AFFIBYTES);
  addType(AFFIBOOL, AFFIARRAYBYTES, AFFIARRAYBYTES);
  addType(AFFIBOOL, AFFIDATE, AFFIDATE);
  addType(AFFIBOOL, AFFIDATE, AFFITIMESTAMP);
  addType(AFFIBOOL, AFFIDATE, AFFITIMESTAMPTZ);
  addType(AFFIBOOL, AFFIARRAYDATE, AFFIARRAYDATE);
  addType(AFFIBOOL, AFFIDECIMAL, AFFIDECIMAL);
  addType(AFFIBOOL, AFFIDECIMAL, AFFIFLOAT);
  addType(AFFIBOOL, AFFIDECIMAL, AFFIINT);
  addType(AFFIBOOL, AFFIARRAYDECIMAL, AFFIARRAYDECIMAL);
  addType(AFFIBOOL, AFFIFLOAT, AFFIDECIMAL);
  addType(AFFIBOOL, AFFIFLOAT, AFFIFLOAT);
  addType(AFFIBOOL, AFFIFLOAT, AFFIINT);
  addType(AFFIBOOL, AFFIARRAYFLOAT, AFFIARRAYFLOAT);
  addType(AFFIBOOL, AFFIINET, AFFIINET);
  addType(AFFIBOOL, AFFIARRAYINET, AFFIARRAYINET);
  addType(AFFIBOOL, AFFIINT, AFFIDECIMAL);
  addType(AFFIBOOL, AFFIINT, AFFIFLOAT);
  addType(AFFIBOOL, AFFIINT, AFFIINT);
  addType(AFFIBOOL, AFFIINT, AFFIOID);
  addType(AFFIBOOL, AFFIARRAYINT, AFFIARRAYINT);
  addType(AFFIBOOL, AFFIINTERVAL, AFFIINTERVAL);
  addType(AFFIBOOL, AFFIARRAYINTERVAL, AFFIARRAYINTERVAL);
  addType(AFFIBOOL, AFFIJSONB, AFFIJSONB);
  addType(AFFIBOOL, AFFIOID, AFFIINT);
  addType(AFFIBOOL, AFFIOID, AFFIOID);
  addType(AFFIBOOL, AFFISTRING, AFFISTRING);
  addType(AFFIBOOL, AFFIARRAYSTRING, AFFIARRAYSTRING);
  addType(AFFIBOOL, AFFITIME, AFFITIME);
  addType(AFFIBOOL, AFFITIME, AFFITIMETZ);
  addType(AFFIBOOL, AFFIARRAYTIME, AFFIARRAYTIME);
  addType(AFFIBOOL, AFFITIMESTAMP, AFFIDATE);
  addType(AFFIBOOL, AFFITIMESTAMP, AFFITIMESTAMP);
  addType(AFFIBOOL, AFFITIMESTAMP, AFFITIMESTAMPTZ);
  addType(AFFIBOOL, AFFIARRAYTIMESTAMP, AFFIARRAYTIMESTAMP);
  addType(AFFIBOOL, AFFITIMESTAMPTZ, AFFIDATE);
  addType(AFFIBOOL, AFFITIMESTAMPTZ, AFFITIMESTAMP);
  addType(AFFIBOOL, AFFITIMESTAMPTZ, AFFITIMESTAMPTZ);
  addType(AFFIBOOL, AFFITIMETZ, AFFITIME);
  addType(AFFIBOOL, AFFITIMETZ, AFFITIMETZ);
  addType(AFFIBOOL, AFFITUPLE, AFFITUPLE);
  addType(AFFIBOOL, AFFIUUID, AFFIUUID);
  addType(AFFIBOOL, AFFIARRAYUUID, AFFIARRAYUUID);
  addType(AFFIBOOL, AFFIBIT, AFFIBIT);
  save("!=")

  addType(AFFIBOOL, AFFIINET, AFFIINET);
  addType(AFFIINT, AFFIINT, AFFIINT);
  addType(AFFIBIT, AFFIBIT, AFFIINT);
  save(">>");

  addType(AFFIBOOL, AFFIJSONB, AFFISTRING);
  save("?");

  addType(AFFIBOOL, AFFIJSONB, AFFIARRAYSTRING);
  save("?&");

  addType(AFFIBOOL, AFFIJSONB, AFFIARRAYSTRING);
  save("?|");

  addType(AFFIBOOL, AFFIJSONB, AFFIJSONB);
  save("@>");

  addType(AFFIBOOL, AFFISTRING, AFFISTRING);
  save("ILIKE");

  // Skip IN and IS NOT DISTINCT FROM for now. ADD back later.

  addType(AFFIBOOL, AFFISTRING, AFFISTRING);
  save("LIKE");

  addType(AFFIBOOL, AFFISTRING, AFFISTRING);
  save("SIMILAR TO");

  addType(AFFIDECIMAL, AFFIDECIMAL, AFFIDECIMAL);
  addType(AFFIDECIMAL, AFFIDECIMAL, AFFIINT);
  addType(AFFIFLOAT, AFFIFLOAT, AFFIFLOAT);
  addType(AFFIDECIMAL, AFFIINT, AFFIDECIMAL);
  addType(AFFIINT, AFFIINT, AFFIINT);
  save("^");

  addType(AFFIINET, AFFIINET, AFFIINET);
  addType(AFFIINT, AFFIINT, AFFIINT);
  addType(AFFIBIT, AFFIBIT, AFFIBIT);
  save("|");

  // Skip |/ because it is a unary operator.

  addType(AFFIARRAYBOOL, AFFIBOOL, AFFIARRAYBOOL);
  addType(AFFISTRING, AFFIBOOL, AFFISTRING);
  addType(AFFIARRAYBOOL, AFFIARRAYBOOL, AFFIBOOL);
  addType(AFFIARRAYBOOL, AFFIARRAYBOOL, AFFIARRAYBOOL);
  addType(AFFIBYTES, AFFIBYTES, AFFIBYTES);
  addType(AFFIARRAYBYTES, AFFIBYTES, AFFIARRAYBYTES);
  addType(AFFIARRAYBYTES, AFFIARRAYBYTES, AFFIBYTES);
  addType(AFFIARRAYBYTES, AFFIARRAYBYTES, AFFIARRAYBYTES);
  addType(AFFIARRAYDATE, AFFIDATE, AFFIARRAYDATE);
  addType(AFFIARRAYDATE, AFFIARRAYDATE, AFFIDATE);
  addType(AFFIARRAYDATE, AFFIARRAYDATE, AFFIARRAYDATE);
  addType(AFFISTRING, AFFIDATE, AFFISTRING);
  addType(AFFIARRAYDECIMAL, AFFIDECIMAL, AFFIARRAYDECIMAL);
  addType(AFFIARRAYDECIMAL, AFFIARRAYDECIMAL, AFFIDECIMAL);
  addType(AFFIARRAYDECIMAL, AFFIARRAYDECIMAL, AFFIARRAYDECIMAL);
  addType(AFFISTRING, AFFIDECIMAL, AFFISTRING);
  addType(AFFIARRAYFLOAT, AFFIFLOAT, AFFIARRAYFLOAT);
  addType(AFFIARRAYFLOAT, AFFIARRAYFLOAT, AFFIARRAYFLOAT);
  addType(AFFIARRAYFLOAT, AFFIARRAYFLOAT, AFFIFLOAT);
  addType(AFFISTRING, AFFIFLOAT, AFFISTRING);
  addType(AFFIARRAYINET, AFFIARRAYINET, AFFIINET);
  addType(AFFIARRAYINET, AFFIINET, AFFIARRAYINET);
  addType(AFFIARRAYINET, AFFIARRAYINET, AFFIARRAYINET);
  addType(AFFISTRING, AFFIINET, AFFISTRING);
  addType(AFFIARRAYINT, AFFIINT, AFFIARRAYINT);
  addType(AFFIARRAYINT, AFFIARRAYINT, AFFIINT);
  addType(AFFIARRAYINT, AFFIARRAYINT, AFFIARRAYINT);
  addType(AFFISTRING, AFFIINT, AFFISTRING);
  addType(AFFIARRAYINTERVAL, AFFIINTERVAL, AFFIARRAYINTERVAL);
  addType(AFFIARRAYINTERVAL, AFFIARRAYINTERVAL, AFFIINTERVAL);
  addType(AFFIARRAYINTERVAL, AFFIARRAYINTERVAL, AFFIARRAYINTERVAL);
  addType(AFFISTRING, AFFIINTERVAL, AFFISTRING);
  addType(AFFIJSONB, AFFIJSONB, AFFIJSONB);
  addType(AFFISTRING, AFFIJSONB, AFFISTRING);
  addType(AFFISTRING, AFFISTRING, AFFIBOOL);
  addType(AFFISTRING, AFFISTRING, AFFIDATE);
  addType(AFFISTRING, AFFISTRING, AFFIDECIMAL);
  addType(AFFISTRING, AFFISTRING, AFFIFLOAT);
  addType(AFFISTRING, AFFISTRING, AFFIINET);
  addType(AFFISTRING, AFFISTRING, AFFIINT);
  addType(AFFISTRING, AFFISTRING, AFFIINTERVAL);
  addType(AFFISTRING, AFFISTRING, AFFIJSONB);
  addType(AFFISTRING, AFFISTRING, AFFISTRING);
  addType(AFFISTRING, AFFISTRING, AFFIARRAYSTRING);
  addType(AFFISTRING, AFFISTRING, AFFITIME);
  addType(AFFISTRING, AFFISTRING, AFFITIMESTAMP);
  addType(AFFISTRING, AFFISTRING, AFFITIMESTAMPTZ);
  addType(AFFISTRING, AFFISTRING, AFFITIMETZ);
  addType(AFFISTRING, AFFISTRING, AFFITUPLE);
  addType(AFFISTRING, AFFISTRING, AFFIUUID);
  addType(AFFISTRING, AFFISTRING, AFFIBIT);
  addType(AFFIARRAYSTRING, AFFIARRAYSTRING, AFFISTRING);
  addType(AFFIARRAYSTRING, AFFIARRAYSTRING, AFFIARRAYSTRING);
  addType(AFFISTRING, AFFITIME, AFFISTRING);
  addType(AFFIARRAYTIME, AFFITIME, AFFIARRAYTIME);
  addType(AFFIARRAYTIME, AFFIARRAYTIME, AFFIARRAYTIME);
  addType(AFFIARRAYTIME, AFFIARRAYTIME, AFFITIME);
  addType(AFFISTRING, AFFITIMESTAMP, AFFISTRING);
  addType(AFFIARRAYTIMESTAMP, AFFIARRAYTIMESTAMP, AFFITIMESTAMP);
  addType(AFFIARRAYTIMESTAMP, AFFITIMESTAMP, AFFIARRAYTIMESTAMP);
  addType(AFFIARRAYTIMESTAMP, AFFIARRAYTIMESTAMP, AFFIARRAYTIMESTAMP);
  addType(AFFITIMESTAMPTZ, AFFITIMESTAMPTZ, AFFITIMESTAMPTZ);
  addType(AFFISTRING, AFFITIMETZ, AFFISTRING);
  addType(AFFITIMETZ, AFFITIMETZ, AFFITIMETZ);
  addType(AFFISTRING, AFFITUPLE, AFFISTRING);
  addType(AFFISTRING, AFFIUUID, AFFISTRING);
  addType(AFFIARRAYUUID, AFFIUUID, AFFIARRAYUUID);
  addType(AFFIARRAYUUID, AFFIARRAYUUID, AFFIUUID);
  addType(AFFIARRAYUUID, AFFIARRAYUUID, AFFIARRAYUUID);
  addType(AFFISTRING, AFFIUUID, AFFISTRING);
  addType(AFFISTRING, AFFIBIT, AFFISTRING);
  addType(AFFIBIT, AFFIBIT, AFFIBIT);
  save("||");

  // SKIP ||/ because it is a unary operator.

  addType(AFFIBOOL, AFFISTRING, AFFISTRING);
  save("~*");

#undef addType
#undef save

}
