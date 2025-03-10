//
// Created by Yu Liang on 12/8/22.
//
#include "../include/ast.h"
#include "../include/define.h"
#include "../include/mutate.h"
#include "../include/utils.h"
#include "../oracle/cockroach_opt.h"
#include "../oracle/cockroach_oracle.h"

#include <fstream>
#include <iostream>
#include <ostream>
#include <string>
#include <utility>

using namespace std;

enum {
  /* 00 */ FAULT_NONE,
  /* 01 */ FAULT_TMOUT,
  /* 02 */ FAULT_CRASH,
  /* 03 */ FAULT_ERROR,
  /* 04 */ FAULT_NOINST,
  /* 05 */ FAULT_NOBITS
};

Mutator g_mutator;
SQL_ORACLE *p_oracle;

bool iden_common_error(IR *cur_stmt) {
  vector<IR *> all_nodes = p_oracle->ir_wrapper.get_all_ir_node(cur_stmt);
  for (IR *cur_node : all_nodes) {
    string cur_node_str = cur_node->to_string();
    trim_string(cur_node_str);
    if (cur_node_str == "x" || cur_node_str == "y") {
      return false;
    }
  }
  return true;
}

bool dyn_fix_stmt_vec(vector<IR *> &all_pre_trans_vec,
                      const vector<string> &res_vec, bool is_debug) {

  IR *cur_trans_stmt;
  string whole_query_sequence = "";
  const int max_trial = 1;
  int total_instan_num = 0;
  vector<IR *> tmp_all_pre_trans_vec;

  assert(all_pre_trans_vec.size() == res_vec.size());

  for (int stmt_idx = 0; stmt_idx < all_pre_trans_vec.size(); stmt_idx++) {
    cur_trans_stmt = all_pre_trans_vec[stmt_idx];
    // Move the reset_data_library_single_stmt out in the outer loop.
    // So that rescanning the instantiation process using the
    // error hints can reuse the table data.

    string ori_stmt_before_instan = cur_trans_stmt->to_string();

    g_mutator.reset_data_library_single_stmt();

    // Avoid modifying the required nodes for the oracle.
    p_oracle->mark_all_valid_node(cur_trans_stmt);
    g_mutator.validate(cur_trans_stmt);

    int ret_res = FAULT_NONE;
    int trial = 0;
    do {
      total_instan_num++;
      trial++;
      string cur_stmt_str = cur_trans_stmt->to_string();

      if (p_oracle->is_res_str_error(res_vec[stmt_idx])) {
        ret_res = FAULT_ERROR;

        if (trial > max_trial) {
          break;
        }

        IR *ori_trans_stmt = cur_trans_stmt;
        string cur_trans_str = cur_trans_stmt->to_string();
        // Statement re-parsed.
        vector<IR *> v_new_parsed =
            g_mutator.parse_query_str_get_ir_set(cur_trans_str);
        if (v_new_parsed.size() == 0) {
          cerr << "\n\n\nFATAL ERROR: The fixed stmt cannot pass the parser: \n"
               << cur_trans_str << "\n\n\n";
          // fallback to the string before instantiation.
          g_mutator.rollback_instan_lib_changes();
          // v_new_parsed =
          // g_mutator.parse_query_str_get_ir_set(ori_stmt_before_instan);
          cur_trans_stmt = NULL;
          ori_trans_stmt->deep_drop();
          break;
        }
        //                  if (v_new_parsed.size() == 0) {
        //                      cur_trans_stmt = NULL;
        //                      ori_trans_stmt->deep_drop();
        //                      break;
        //                  }
        IR *new_parsed_root = v_new_parsed.back();
        cur_trans_stmt =
            new_parsed_root->get_left()->get_left()->get_left()->deep_copy();
        cur_trans_stmt->parent_ = NULL;
        new_parsed_root->deep_drop();
        ori_trans_stmt->deep_drop();

        // Avoid modifying the required nodes for the oracle.
        p_oracle->mark_all_valid_node(cur_trans_stmt);

        g_mutator.fix_instan_error(cur_trans_stmt, res_vec[stmt_idx], trial,
                                   is_debug);
      }

      if (ret_res == FAULT_NONE) {
        whole_query_sequence += cur_stmt_str;
      }
    } while (ret_res != FAULT_NONE && trial < max_trial);

    if (cur_trans_stmt != NULL) {
      tmp_all_pre_trans_vec.push_back(cur_trans_stmt);
    }
  }

  all_pre_trans_vec = tmp_all_pre_trans_vec;

  return true;
}

bool unit_test_failure_create(bool is_show_debug = false) {

  g_mutator.pre_validate();

  // Succeed with return true,
  // Failed with return false.

  vector<string> stmt_list{
      "create table v0 (v1 int, v2 string, family (v1, v1));",
      "select * from v0 where v1 = 0;"};

  vector<string> res_list{
      "ERROR: relation \"v0\" (112): column 1 is in both family 0 and 0", ""};

  vector<IR *> ir_list;
  for (string &cur_stmt : stmt_list) {
    IR *cur_root = g_mutator.parse_query_str_get_ir_set(cur_stmt).back();
    ir_list.push_back(
        p_oracle->ir_wrapper.get_first_stmt_from_root(cur_root)->deep_copy());
    cur_root->deep_drop();
  }

  dyn_fix_stmt_vec(ir_list, res_list, is_show_debug);
  bool is_no_error;
  for (IR *cur_stmt : ir_list) {
    if (is_show_debug) {
      cerr << "Debug: Getting final stmt: " << cur_stmt->to_string() << "\n";
    }
    is_no_error = iden_common_error(cur_stmt);
    if (!is_no_error) {
      break;
    }
  }

  for (auto cur_ir : ir_list) {
    cur_ir->deep_drop();
  }

  return is_no_error;
}

bool unit_test_alter_bugs(bool is_show_debug = false) {

  g_mutator.pre_validate();

  // Succeed with return true,
  // Failed with return false.

  vector<string>
      stmt_list{
          "CREATE TABLE v0 (c1 STRING, c2 TIMESTAMPTZ, c3 INTERVAL, c4 "
          "SERIAL);",
          "SET enable_implicit_select_for_update = off;",
          "SET transaction_read_only = off;",
          "SET null_ordered_last = true;",
          "CREATE TABLE v9 (c10 INTERVAL PRIMARY KEY, c11 DECIMAL, FAMILY "
          "family_12(c11, c10));", // "ERROR: relation \"v9\" (112): column 1 is
                                   // in both family 0 and 0",
          "INSERT INTO v9 VALUES ('4-8 29 7:21:59'::INTERVAL, 54.112271);",
          "ALTER TABLE v9 ADD COLUMN c13 TIME AS ('03:36:39'::TIME) STORED;",
          "ALTER TABLE v0 ALTER COLUMN c3 DROP STORED, DROP COLUMN c11 "
          "CASCADE;", // ERROR: column "c3" is not a computed column
          "SELECT DISTINCT ON (LOG(69.446394, -53.124958)) COUNT( *) FROM v9 "
          "WHERE x IN ('61', '20 d 4 hrs 4 mins 32 secs', '169.254.0.0/16');" // ERROR: column "x" does not exist
      };

  vector<string> res_list{
      "",
      "",
      "",
      "",
      "ERROR: relation \\\"v9\\\" (112): column 1 is in both family 0 and 0",
      "",
      "",
      "ERROR: column \"x\" does not exist",
      "",
  };

  vector<IR *> ir_list;
  for (string &cur_stmt : stmt_list) {
    IR *cur_root = g_mutator.parse_query_str_get_ir_set(cur_stmt).back();
    ir_list.push_back(
        p_oracle->ir_wrapper.get_first_stmt_from_root(cur_root)->deep_copy());
    cur_root->deep_drop();
  }

  dyn_fix_stmt_vec(ir_list, res_list, is_show_debug);
  bool is_no_error;
  for (IR *cur_stmt : ir_list) {
    if (is_show_debug) {
      cerr << "Debug: Getting final stmt: " << cur_stmt->to_string() << "\n";
    }
    is_no_error = iden_common_error(cur_stmt);
    if (!is_no_error) {
      break;
    }
  }

  for (auto cur_ir : ir_list) {
    cur_ir->deep_drop();
  }

  return is_no_error;
}

bool unit_test_alias_0(bool is_show_debug = false) {

  g_mutator.pre_validate();

  // Succeed with return true,
  // Failed with return false.

  vector<string> stmt_list{
      "CREATE TABLE v0 (c1 STRING, c2 TIMESTAMPTZ, c3 INTERVAL, c4 SERIAL);",
      "SELECT TRUNC(69.396928) FROM v0 FULL JOIN v0 AS ta10(x, x, x) USING "
      "(c1, c3, c4) FULL JOIN v0 AS ta11(x, x, x) USING (c4) FULL JOIN v0 "
      "AS ta12(x, x, x) USING (c1) WHERE c3 BETWEEN 'hss' AND '10-14-70 "
      "04:31:23.2571+1';"};

  vector<string> res_list{"", "ERROR: column \"c1\" specified in USING clause "
                              "does not exist in right table"};

  vector<IR *> ir_list;
  for (string &cur_stmt : stmt_list) {
    IR *cur_root = g_mutator.parse_query_str_get_ir_set(cur_stmt).back();
    ir_list.push_back(
        p_oracle->ir_wrapper.get_first_stmt_from_root(cur_root)->deep_copy());
    cur_root->deep_drop();
  }

  for (IR *cur_stmt : ir_list) {
    if (is_show_debug) {
      cerr << "Debug: Getting parsed stmt: " << cur_stmt->to_string() << "\n";
    }
  }

  dyn_fix_stmt_vec(ir_list, res_list, is_show_debug);
  bool is_no_error;
  for (IR *cur_stmt : ir_list) {
    if (is_show_debug) {
      cerr << "Debug: Getting final stmt: " << cur_stmt->to_string() << "\n";
    }
    is_no_error = iden_common_error(cur_stmt);
    if (!is_no_error) {
      break;
    }
  }

  for (auto cur_ir : ir_list) {
    cur_ir->deep_drop();
  }

  return is_no_error;
}

bool unit_test_with_alias_1(bool is_show_debug = false) {

  g_mutator.pre_validate();

  // Succeed with return true,
  // Failed with return false.

  vector<string> stmt_list{
      "CREATE TABLE v0 (c1 STRING, c2 TIMESTAMPTZ, c3 INTERVAL, c4 SERIAL);",
      "WITH ta0(tc1) AS (SELECT COUNT(*) FROM v0) SELECT * FROM v0;"};

  vector<string> res_list{"", "ERROR: relation \"tc0\" does not exist"};

  vector<IR *> ir_list;
  for (string &cur_stmt : stmt_list) {
    IR *cur_root = g_mutator.parse_query_str_get_ir_set(cur_stmt).back();
    ir_list.push_back(
        p_oracle->ir_wrapper.get_first_stmt_from_root(cur_root)->deep_copy());
    cur_root->deep_drop();
  }

  for (IR *cur_stmt : ir_list) {
    if (is_show_debug) {
      cerr << "Debug: Getting parsed stmt: " << cur_stmt->to_string() << "\n";
    }
  }

  dyn_fix_stmt_vec(ir_list, res_list, is_show_debug);
  bool is_no_error;
  for (IR *cur_stmt : ir_list) {
    if (is_show_debug) {
      cerr << "Debug: Getting final stmt: " << cur_stmt->to_string() << "\n";
    }
    is_no_error = iden_common_error(cur_stmt);
    if (!is_no_error) {
      break;
    }
  }

  for (auto cur_ir : ir_list) {
    cur_ir->deep_drop();
  }

  return is_no_error;
}

bool unit_test_jsonb_operator(bool is_show_debug = false) {

  g_mutator.pre_validate();

  // Succeed with return true,
  // Failed with return false.

  vector<string> stmt_list{
      "CREATE TABLE v0 (c1 STRING, c2 TIMESTAMPTZ, c3 INTERVAL, c4 SERIAL);",
      "SELECT x FROM (SELECT TIMEOFDAY( )->'9yhrt' AS ca189 FROM v0) WHERE x "
      "IS NOT NULL;",
      "SELECT DISTINCT ON (\"RIGHT\"( b'9', -688706232)) '4-7 9 5:37:27' AS "
      "ca207, ta206.c2 FROM v0 "
      "AS ta206 WHERE (ta206.c3 % B'0') = B'0';"};

  vector<string> res_list{"",
                          "pq: unsupported binary operator: <bit> -> <varbit>",
                          "pq: unsupported binary operator: <bit> % <varbit>"};

  vector<IR *> ir_list;
  for (string &cur_stmt : stmt_list) {
    IR *cur_root = g_mutator.parse_query_str_get_ir_set(cur_stmt).back();
    ir_list.push_back(
        p_oracle->ir_wrapper.get_first_stmt_from_root(cur_root)->deep_copy());
    cur_root->deep_drop();
  }

  for (IR *cur_stmt : ir_list) {
    if (is_show_debug) {
      cerr << "Debug: Getting parsed stmt: " << cur_stmt->to_string() << "\n";
    }
  }

  dyn_fix_stmt_vec(ir_list, res_list, is_show_debug);
  bool is_no_error;
  for (IR *cur_stmt : ir_list) {
    if (is_show_debug) {
      cerr << "Debug: Getting final stmt: " << cur_stmt->to_string() << "\n";
    }
    is_no_error = iden_common_error(cur_stmt);
    if (!is_no_error) {
      break;
    }
  }

  for (auto cur_ir : ir_list) {
    cur_ir->deep_drop();
  }

  return is_no_error;
}

bool unit_test_tuple_instan(bool is_show_debug = false) {

  g_mutator.pre_validate();

  // Succeed with return true,
  // Failed with return false.

  vector<string> stmt_list{
      "CREATE TABLE v0 (c1 STRING, c2 TIMESTAMPTZ, c3 INTERVAL, c4 SERIAL);",
      "SELECT * FROM v0 WHERE ('6597:6b20:879b:b681:c388:8635:ba39:1d50', "
      "'6ab3:767c:bd55:606b:67ac:f29d:9478:e420', 0, '03:42:35.1468', "
      "'05:14:42.1891') != '2douwult';"};

  vector<string> res_list{
      "", "pq: could not parse \"2douwult\" as type tuple{string, string, int, "
          "string, string}: record must be enclosed in ( and )"};

  vector<IR *> ir_list;
  for (string &cur_stmt : stmt_list) {
    IR *cur_root = g_mutator.parse_query_str_get_ir_set(cur_stmt).back();
    ir_list.push_back(
        p_oracle->ir_wrapper.get_first_stmt_from_root(cur_root)->deep_copy());
    cur_root->deep_drop();
  }

  for (IR *cur_stmt : ir_list) {
    if (is_show_debug) {
      cerr << "Debug: Getting parsed stmt: " << cur_stmt->to_string() << "\n";
    }
  }

  p_oracle->ir_wrapper.iter_cur_node_with_handler(
      ir_list[1], [](IR *cur_node) -> void {
        if (cur_node->get_ir_type() == TypeStringLiteral) {
          cur_node->set_is_instantiated(true);
        }
      });

  dyn_fix_stmt_vec(ir_list, res_list, is_show_debug);
  bool is_no_error;
  for (IR *cur_stmt : ir_list) {
    if (is_show_debug) {
      cerr << "Debug: Getting final stmt: " << cur_stmt->to_string() << "\n";
    }
    is_no_error = iden_common_error(cur_stmt);
    if (!is_no_error) {
      break;
    }
  }

  for (auto cur_ir : ir_list) {
    cur_ir->deep_drop();
  }

  return is_no_error;
}

bool unit_test_tuple_instan_2(bool is_show_debug = false) {

  g_mutator.pre_validate();

  // Succeed with return true,
  // Failed with return false.

  vector<string> stmt_list{
      "CREATE TABLE v0 (c1 STRING, c2 TIMESTAMPTZ, c3 INTERVAL, c4 SERIAL);",
      "SELECT * FROM v0 WHERE ('6597:6b20:879b:b681:c388:8635:ba39:1d50', "
      "'6ab3:767c:bd55:606b:67ac:f29d:9478:e420', 0, '03:42:35.1468', "
      "'05:14:42.1891') != c3;"};

  vector<string> res_list{
      "", "ERROR: unsupported comparison operator: <tuple{string, string, int, "
          "string, string}> != <interval>"};

  vector<IR *> ir_list;
  for (string &cur_stmt : stmt_list) {
    IR *cur_root = g_mutator.parse_query_str_get_ir_set(cur_stmt).back();
    ir_list.push_back(
        p_oracle->ir_wrapper.get_first_stmt_from_root(cur_root)->deep_copy());
    cur_root->deep_drop();
  }

  for (IR *cur_stmt : ir_list) {
    if (is_show_debug) {
      cerr << "Debug: Getting parsed stmt: " << cur_stmt->to_string() << "\n";
    }
  }

  p_oracle->ir_wrapper.iter_cur_node_with_handler(
      ir_list[1], [](IR *cur_node) -> void {
        if (cur_node->get_ir_type() == TypeStringLiteral) {
          cur_node->set_is_instantiated(true);
        }
      });

  dyn_fix_stmt_vec(ir_list, res_list, is_show_debug);
  bool is_no_error;
  for (IR *cur_stmt : ir_list) {
    if (is_show_debug) {
      cerr << "Debug: Getting final stmt: " << cur_stmt->to_string() << "\n";
    }
    is_no_error = iden_common_error(cur_stmt);
    if (!is_no_error) {
      break;
    }
  }

  for (auto cur_ir : ir_list) {
    cur_ir->deep_drop();
  }

  return is_no_error;
}

bool unit_test_literal_instan(bool is_show_debug = false) {

  g_mutator.pre_validate();

  DATAAFFINITYTYPE cur_affi = AFFIARRAYANY;

  // UNIT TEST the instantiation of the literal.
  IR *tmp_IR = new IR(TypeStringLiteral, string(""), DataLiteral,
                      ContextUnknown, cur_affi);
  tmp_IR->mutate_literal();

  if (is_show_debug) {
    cerr << "\n\n\nDEBUG: when fixing literal with affinity: "
         << get_string_by_affinity_type(cur_affi)
         << ", getting literal: " << tmp_IR->to_string() << "\n\n\n";
  }

  if (!findStringIn(tmp_IR->to_string(), "ARRAY")) {
    return false;
  }

  return true;
}

bool unit_test_missing_column(bool is_show_debug = false) {

  g_mutator.pre_validate();

  // Succeed with return true,
  // Failed with return false.

  vector<string> stmt_list{
      "CREATE TABLE v0 (c1 STRING, c2 TIMESTAMPTZ, c3 INTERVAL, c4 SERIAL);",
      "SELECT * FROM ROWS FROM (BTRIM('gj404usqz', '09-07-51')) WHERE x = "
      "'3fa467c5-898c-da8c-4abe-9576f126f949';"};

  vector<string> res_list{"", "pq: column \"x\" does not exist"};

  vector<IR *> ir_list;
  for (string &cur_stmt : stmt_list) {
    IR *cur_root = g_mutator.parse_query_str_get_ir_set(cur_stmt).back();
    ir_list.push_back(
        p_oracle->ir_wrapper.get_first_stmt_from_root(cur_root)->deep_copy());
    cur_root->deep_drop();
  }

  for (IR *cur_stmt : ir_list) {
    if (is_show_debug) {
      cerr << "Debug: Getting parsed stmt: " << cur_stmt->to_string() << "\n";
    }
  }

  p_oracle->ir_wrapper.iter_cur_node_with_handler(
      ir_list[1], [](IR *cur_node) -> void {
        if (cur_node->get_ir_type() == TypeStringLiteral) {
          cur_node->set_is_instantiated(true);
        }
      });

  dyn_fix_stmt_vec(ir_list, res_list, is_show_debug);
  bool is_no_error;
  for (IR *cur_stmt : ir_list) {
    if (is_show_debug) {
      cerr << "Debug: Getting final stmt: " << cur_stmt->to_string() << "\n";
    }
    is_no_error = iden_common_error(cur_stmt);
    if (!is_no_error) {
      break;
    }
  }

  for (auto cur_ir : ir_list) {
    cur_ir->deep_drop();
  }

  return is_no_error;
}

bool unit_test_missing_column_2(bool is_show_debug = false) {

  g_mutator.pre_validate();

  // Succeed with return true,
  // Failed with return false.

  vector<string> stmt_list{
      "SELECT * FROM ROWS FROM (BTRIM('gj404usqz', '09-07-51')) WHERE x = "
      "'3fa467c5-898c-da8c-4abe-9576f126f949';"};

  vector<string> res_list{"pq: column \"x\" does not exist"};

  vector<IR *> ir_list;
  for (string &cur_stmt : stmt_list) {
    IR *cur_root = g_mutator.parse_query_str_get_ir_set(cur_stmt).back();
    ir_list.push_back(
        p_oracle->ir_wrapper.get_first_stmt_from_root(cur_root)->deep_copy());
    cur_root->deep_drop();
  }

  for (IR *cur_stmt : ir_list) {
    if (is_show_debug) {
      cerr << "Debug: Getting parsed stmt: " << cur_stmt->to_string() << "\n";
    }
  }

  p_oracle->ir_wrapper.iter_cur_node_with_handler(
      ir_list[0], [](IR *cur_node) -> void {
        if (cur_node->get_ir_type() == TypeStringLiteral) {
          cur_node->set_is_instantiated(true);
        }
      });

  dyn_fix_stmt_vec(ir_list, res_list, is_show_debug);
  assert(ir_list.size() == res_list.size());
  bool is_no_error;
  for (IR *cur_stmt : ir_list) {
    if (is_show_debug) {
      cerr << "Debug: Getting final stmt: " << cur_stmt->to_string() << "\n";
    }
    is_no_error = iden_common_error(cur_stmt);
    if (!is_no_error) {
      break;
    }
  }

  for (auto cur_ir : ir_list) {
    cur_ir->deep_drop();
  }

  return is_no_error;
}

bool unit_test_nested_functions(bool is_show_debug = false) {

  g_mutator.pre_validate();

  // Succeed with return true,
  // Failed with return false.

  vector<string> stmt_list{
      "CREATE TABLE v0 (v1 int);",
      "SELECT * FROM x WHERE CHECK_TEST( IS_PARTITION_OF( 0, 0), 0, 0, 0, 0);"};

  vector<string> res_list{"", ""};

  vector<IR *> ir_list;
  for (string &cur_stmt : stmt_list) {
    IR *cur_root = g_mutator.parse_query_str_get_ir_set(cur_stmt).back();
    ir_list.push_back(
        p_oracle->ir_wrapper.get_first_stmt_from_root(cur_root)->deep_copy());
    cur_root->deep_drop();
  }

  for (IR *cur_stmt : ir_list) {
    if (is_show_debug) {
      cerr << "Debug: Getting parsed stmt: " << cur_stmt->to_string() << "\n";
    }
    g_mutator.validate(cur_stmt, false);
    if (is_show_debug) {
      cerr << "Debug: Getting validated stmt: " << cur_stmt->to_string()
           << "\n";
    }
  }

  assert(ir_list.size() == res_list.size());
  bool is_no_error;

  for (IR *cur_stmt : ir_list) {
    is_no_error = iden_common_error(cur_stmt);
    if (!is_no_error) {
      break;
    }
    if (!findStringIn(cur_stmt->to_string(), "CHECK_TEST")) {
      is_no_error = false;
    }
  }

  for (auto cur_ir : ir_list) {
    cur_ir->deep_drop();
  }

  return is_no_error;
}

bool unit_test_extract_struct_deep(bool is_show_debug = false) {

  // Succeed with return true,
  // Failed with return false.

  vector<string> stmt_list{
      "SELECT * FROM ROWS FROM (BTRIM('gj404usqz', '09-07-51')) WHERE x = "
      "'3fa467c5-898c-da8c-4abe-9576f126f949';"};

  vector<IR *> ir_list;
  for (string &cur_stmt : stmt_list) {
    IR *cur_root = g_mutator.parse_query_str_get_ir_set(cur_stmt).back();
    ir_list.push_back(
        p_oracle->ir_wrapper.get_first_stmt_from_root(cur_root)->deep_copy());
    cur_root->deep_drop();
  }

  for (IR *cur_stmt : ir_list) {
    if (is_show_debug) {
      cerr << "Debug: Getting parsed stmt: " << cur_stmt->to_string() << "\n";
    }
    IR *cur_stmt_ext = cur_stmt->deep_copy();
    IR *cur_stmt_ext_deep = cur_stmt->deep_copy();

    string extract_struct_str = g_mutator.extract_struct(cur_stmt_ext);
    if (is_show_debug) {
      cerr << "extract_struct: " << extract_struct_str << "\n\n\n";
    }
    if (findStringIn(extract_struct_str, "INT")) {
      return false;
    }

    string extract_struct_str_deep =
        g_mutator.extract_struct_deep(cur_stmt_ext_deep);

    if (is_show_debug) {
      cerr << "extract_struct_deep: " << extract_struct_str_deep << "\n\n\n";
    }

    if (findStringIn(extract_struct_str_deep, "INT")) {
      return false;
    }
    cur_stmt_ext->deep_drop();
    cur_stmt_ext_deep->deep_drop();
    cur_stmt->deep_drop();
  }

  return true;
}

bool unit_test_simple_select_operator(bool is_show_debug = false) {

  g_mutator.pre_validate();

  // Succeed with return true,
  // Failed with return false.

  vector<string> stmt_list{"create table v0 (v1 int);",
                           "select * from v0 where v1 > 'abc';"};

  vector<string> res_list{"",
                          "ERROR: could not parse \"abc\" as type int: "
                          "strconv.ParseInt: parsing \"abc\": invalid syntax"};

  IR *tmp_int_expr = new IR(TypeExpr, string("100 + 100"));
  DataAffinity data_affi(AFFIINT);
  uint64_t data_affi_hash = data_affi.calc_hash();
  g_mutator.data_affi_set[data_affi_hash].push_back(tmp_int_expr);

  vector<IR *> ir_list;
  for (string &cur_stmt : stmt_list) {
    IR *cur_root = g_mutator.parse_query_str_get_ir_set(cur_stmt).back();
    ir_list.push_back(
        p_oracle->ir_wrapper.get_first_stmt_from_root(cur_root)->deep_copy());
    cur_root->deep_drop();
  }

  for (IR *cur_stmt : ir_list) {
    if (is_show_debug) {
      cerr << "Debug: Getting parsed stmt: " << cur_stmt->to_string() << "\n";
    }
  }

  p_oracle->ir_wrapper.iter_cur_node_with_handler(
      ir_list[1], [](IR *cur_node) -> void {
        if (cur_node->get_data_type() == DataLiteral) {
          cur_node->set_is_instantiated(true);
        }
      });

  dyn_fix_stmt_vec(ir_list, res_list, is_show_debug);
  bool is_no_error;
  for (IR *cur_stmt : ir_list) {
    if (is_show_debug) {
      cerr << "Debug: Getting final stmt: " << cur_stmt->to_string() << "\n";
    }
    is_no_error = iden_common_error(cur_stmt);
    if (!is_no_error) {
      break;
    }
  }

  IR *cur_stmt = ir_list.back();
  if (!findStringIn(cur_stmt->to_string(), "100 + 100")) {
    if (is_show_debug) {
      cerr << "missing the tracked 100 + 100 expr. \n";
    }
    is_no_error = false;
  } else {
    if (is_show_debug) {
      cerr << "contains the tracked 100 + 100 expr. \n";
    }
  }

  for (auto cur_ir : ir_list) {
    cur_ir->deep_drop();
  }

  for (auto saved_expr : g_mutator.data_affi_set[data_affi_hash]) {
    saved_expr->deep_drop();
  }
  g_mutator.data_affi_set[data_affi_hash].clear();

  return is_no_error;
}

bool unit_test_VALUES_clause_error(bool is_show_debug = false) {

  g_mutator.pre_validate();

  // Succeed with return true,
  // Failed with return false.

  vector<string> stmt_list{"create table v0 (v1 INTERVAL);",
                           "SELECT * FROM v0 WHERE (c1, c1) IN (VALUES "
                           "(8197900870095608111), (2515221985953023599), "
                           "(-749005926222999694), (9223372036854775807)) ORDER"
                           " BY c1;"};

  vector<string> res_list{"", "ERROR: unsupported comparison operator: "
                              "<tuple{bool, bool}> IN <tuple{int}>"};

  vector<IR *> ir_list;
  for (string &cur_stmt : stmt_list) {
    IR *cur_root = g_mutator.parse_query_str_get_ir_set(cur_stmt).back();
    ir_list.push_back(
        p_oracle->ir_wrapper.get_first_stmt_from_root(cur_root)->deep_copy());
    cur_root->deep_drop();
  }

  for (IR *cur_stmt : ir_list) {
    if (is_show_debug) {
      cerr << "Debug: Getting parsed stmt: " << cur_stmt->to_string() << "\n";
    }
  }

  p_oracle->ir_wrapper.iter_cur_node_with_handler(
      ir_list[1], [](IR *cur_node) -> void {
        if (cur_node->get_data_type() == DataLiteral) {
          cur_node->set_is_instantiated(true);
        }
      });

  dyn_fix_stmt_vec(ir_list, res_list, is_show_debug);
  bool is_no_error;
  for (IR *cur_stmt : ir_list) {
    if (is_show_debug) {
      cerr << "Debug: Getting final stmt: " << cur_stmt->to_string() << "\n";
    }
    is_no_error = iden_common_error(cur_stmt);
    if (!is_no_error) {
      break;
    }
  }

  for (auto cur_ir : ir_list) {
    cur_ir->deep_drop();
  }

  return is_no_error;
}

bool unit_test_function_undefined(bool is_show_debug = false) {

  g_mutator.pre_validate();

  // Succeed with return true,
  // Failed with return false.

  vector<string> stmt_list{
      "CREATE TABLE v0 (c1 STRING, c2 TIMESTAMPTZ, c3 INTERVAL, c4 SERIAL);",
      "SELECT * FROM v0 WHERE c1 = CHECK_TEST( LANGUAGE_IS_TRUSTED( "
      "'1h49m33s'::INTERVAL), '1h49m33s'::INTERVAL, '1h49m33s'::INTERVAL, "
      "'P9Y10M26DT16H27M47S'::INTERVAL, c1);",
      "SELECT * FROM v0 WHERE c1 = SUM( CHECK_TEST( '1h49m33s'::INTERVAL), "
      "'1h49m33s'::INTERVAL, '1h49m33s'::INTERVAL, "
      "'P9Y10M26DT16H27M47S'::INTERVAL, c1);"};

  vector<string> res_list{
      "", "ERROR: unknown function: check_test(): function undefined",
      "ERROR: unknown function: check_test(): function undefined"};

  vector<IR *> ir_list;
  for (string &cur_stmt : stmt_list) {
    IR *cur_root = g_mutator.parse_query_str_get_ir_set(cur_stmt).back();
    ir_list.push_back(
        p_oracle->ir_wrapper.get_first_stmt_from_root(cur_root)->deep_copy());
    cur_root->deep_drop();
  }

  for (IR *cur_stmt : ir_list) {
    if (is_show_debug) {
      cerr << "Debug: Getting parsed stmt: " << cur_stmt->to_string() << "\n";
    }
  }

  p_oracle->ir_wrapper.iter_cur_node_with_handler(
      ir_list[1], [](IR *cur_node) -> void {
        if (cur_node->get_ir_type() == TypeStringLiteral) {
          cur_node->set_is_instantiated(true);
        }
      });
  p_oracle->ir_wrapper.iter_cur_node_with_handler(
      ir_list[2], [](IR *cur_node) -> void {
        if (cur_node->get_ir_type() == TypeStringLiteral) {
          cur_node->set_is_instantiated(true);
        }
      });

  dyn_fix_stmt_vec(ir_list, res_list, is_show_debug);
  bool is_no_error;
  for (IR *cur_stmt : ir_list) {
    if (is_show_debug) {
      cerr << "Debug: Getting final stmt: " << cur_stmt->to_string() << "\n";
    }
    is_no_error = iden_common_error(cur_stmt);
    if (!is_no_error) {
      break;
    }
  }

  for (auto cur_ir : ir_list) {
    cur_ir->deep_drop();
  }

  return is_no_error;
}

bool unit_test_literal_fixing(bool is_show_debug = false) {

  g_mutator.pre_validate();

  // Succeed with return true,
  // Failed with return false.

  vector<string> stmt_list{
      "CREATE TABLE v0 (c1 STRING, c2 TIMESTAMPTZ, c3 INTERVAL, c4 SERIAL, c5 "
      "DECIMAL);",
      "SELECT * FROM v3 WHERE "
      "NETMASK('9096:8d34:d12d:5e99:c658:6304:9b1b:8185'::INET) = 'jsmx';",
      "SELECT * from v0 where c4 = ANY ARRAY['2ci10p4', '09-10-66 BC "
      "11:15:40.8179-2', '05-19-81 BC 03:33:31.6577+2', '05-08-4034 BC "
      "06:58:13-5', '05-1"
      "0-3656 14:14:21-3'];",
      "SELECT COUNT( *) FROM v0 WHERE v0.c5 = B'010' AND v0.c3 > "
      "B'10001111101';",
      "SELECT * FROM v0 WHERE c3 << '08-05-87'::DATE"};

  vector<string> res_list{
      "",

      "pq: could not parse \"jsmx\" as inet. invalid IP",

      "ERROR: unsupported comparison operator: c4 = ANY ARRAY['2ci10p4', "
      "'09-10-66 BC 11:15:40.8179-2', '05-19-81 BC 03:33:31.6577+2', "
      "'05-08-4034 BC 06:58:13-5', '05-10-3656 14:14:21-3']: could not "
      "parse \"2ci10p4\" as type int: strconv.ParseInt: parsing \"2ci10p4\": "
      "invalid syntax",

      "pq: unsupported comparison operator: <decimal> = <varbit>",

      "pq: unsupported binary operator: <date> << <date> (desired <bool>)"};

  vector<IR *> ir_list;
  for (string &cur_stmt : stmt_list) {
    IR *cur_root = g_mutator.parse_query_str_get_ir_set(cur_stmt).back();
    ir_list.push_back(
        p_oracle->ir_wrapper.get_first_stmt_from_root(cur_root)->deep_copy());
    cur_root->deep_drop();
  }

  for (IR *cur_stmt : ir_list) {
    if (is_show_debug) {
      cerr << "Debug: Getting parsed stmt: " << cur_stmt->to_string() << "\n";
    }
  }

  DataAffinity tmp_data_affi(AFFIDECIMAL);
  IR *tmp_node = new IR(TypeStringLiteral, string("100.0 + 100.0"));
  g_mutator.data_affi_set[tmp_data_affi.calc_hash()].push_back(tmp_node);

  p_oracle->ir_wrapper.iter_cur_node_with_handler(
      ir_list[1],
      [](IR *cur_node) -> void { cur_node->set_is_instantiated(true); });
  p_oracle->ir_wrapper.iter_cur_node_with_handler(
      ir_list[2],
      [](IR *cur_node) -> void { cur_node->set_is_instantiated(true); });
  p_oracle->ir_wrapper.iter_cur_node_with_handler(
      ir_list[3],
      [](IR *cur_node) -> void { cur_node->set_is_instantiated(true); });
  p_oracle->ir_wrapper.iter_cur_node_with_handler(
      ir_list[4],
      [](IR *cur_node) -> void { cur_node->set_is_instantiated(true); });

  dyn_fix_stmt_vec(ir_list, res_list, is_show_debug);
  bool is_no_error;
  for (IR *cur_stmt : ir_list) {
    if (is_show_debug) {
      cerr << "Debug: Getting final stmt: " << cur_stmt->to_string() << "\n";
    }
    is_no_error = iden_common_error(cur_stmt);
    if (!is_no_error) {
      break;
    }
  }

  string last_stmt_final = ir_list.back()->to_string();
  if (findStringIn(last_stmt_final, "v0.c5 = B'010'")
      //      || findStringIn(last_stmt_final, "v0.c3 = B'10001111101'")
  ) {
    is_no_error = false;
  }

  for (auto cur_ir : ir_list) {
    cur_ir->deep_drop();
  }

  return is_no_error;
}

bool unit_test_type_where_mismatch(bool is_show_debug = false) {

  g_mutator.pre_validate();

  // Succeed with return true,
  // Failed with return false.

  vector<string> stmt_list{
      "CREATE TABLE v0 (c1 STRING);",
      "SELECT * FROM v0 WHERE CURRENT_SETTING('07-18-0056 BC', 'true');"};

  vector<string> res_list{
      "",

      "ERROR: argument of WHERE must be type bool, not type string"

  };

  vector<IR *> ir_list;
  for (string &cur_stmt : stmt_list) {
    IR *cur_root = g_mutator.parse_query_str_get_ir_set(cur_stmt).back();
    ir_list.push_back(
        p_oracle->ir_wrapper.get_first_stmt_from_root(cur_root)->deep_copy());
    cur_root->deep_drop();
  }

  for (IR *cur_stmt : ir_list) {
    if (is_show_debug) {
      cerr << "Debug: Getting parsed stmt: " << cur_stmt->to_string() << "\n";
    }
  }

  p_oracle->ir_wrapper.iter_cur_node_with_handler(
      ir_list[1],
      [](IR *cur_node) -> void { cur_node->set_is_instantiated(true); });

  dyn_fix_stmt_vec(ir_list, res_list, is_show_debug);
  bool is_no_error;
  for (IR *cur_stmt : ir_list) {
    if (is_show_debug) {
      cerr << "Debug: Getting final stmt: " << cur_stmt->to_string() << "\n";
    }
    is_no_error = iden_common_error(cur_stmt);
    if (!is_no_error) {
      break;
    }
  }

  for (auto cur_ir : ir_list) {
    cur_ir->deep_drop();
  }

  return is_no_error;
}


bool unit_test_function_dynamic_instan(bool is_show_debug = false) {

  g_mutator.pre_validate();

  // Succeed with return true,
  // Failed with return false.

  vector<string> stmt_list{
      "CREATE TABLE v0 (c1 STRING);",
      "SELECT ABBREV('414d:f731:acc2:32a7:cefb:a951:0833:9dfe'::INET), XOR_AGG(b'\\x93\\x57\\x39\\x19\\x79\\x97'), LOCALTIMESTAMP(9223372036854775807), AGE('08-21-2130 BC 15:39:51-6'::"
      "TIMESTAMPTZ, '11-07-49 BC 22:42:53.8134-11'::TIMESTAMPTZ), CURRENT_TIMESTAMP(), BOOL_AND(false) FROM v16 WHERE c18 IN (b'c7eaa1cebddfa593')"
  };

  vector<string> res_list{
      "",
      "pq: localtimestamp(): precision -1 out of range"
  };

  vector<IR *> ir_list;
  for (string &cur_stmt : stmt_list) {
    IR *cur_root = g_mutator.parse_query_str_get_ir_set(cur_stmt).back();
    ir_list.push_back(
        p_oracle->ir_wrapper.get_first_stmt_from_root(cur_root)->deep_copy());
    cur_root->deep_drop();
  }

  for (IR *cur_stmt : ir_list) {
    if (is_show_debug) {
      cerr << "Debug: Getting parsed stmt: " << cur_stmt->to_string() << "\n";
    }
  }

  p_oracle->ir_wrapper.iter_cur_node_with_handler(
      ir_list[1],
      [](IR *cur_node) -> void { cur_node->set_is_instantiated(true); });

  dyn_fix_stmt_vec(ir_list, res_list, is_show_debug);
  bool is_no_error;
  for (IR *cur_stmt : ir_list) {
    if (is_show_debug) {
      cerr << "Debug: Getting final stmt: " << cur_stmt->to_string() << "\n";
    }
    is_no_error = iden_common_error(cur_stmt);
    if (!is_no_error) {
      break;
    }
  }

  for (auto cur_ir : ir_list) {
    cur_ir->deep_drop();
  }

  return is_no_error;
}

int main(int argc, char *argv[]) {

  if (argc != 1) {
    cout << "./unit_test" << endl;
    return -1;
  }

  g_mutator.init("");
  g_mutator.init_data_library();

  p_oracle = new SQL_OPT();

  g_mutator.set_p_oracle(p_oracle);
  p_oracle->set_mutator(&g_mutator);
  p_oracle->init_operator_supported_types();

  assert(unit_test_failure_create(false));
  assert(unit_test_alter_bugs(false));
  assert(unit_test_alias_0(false));
  assert(unit_test_with_alias_1(false));
  assert(unit_test_jsonb_operator(false));
  assert(unit_test_tuple_instan(false));
  assert(unit_test_tuple_instan_2(false));
  assert(unit_test_literal_instan(false));
  for (int i = 0; i < 100; i++) {
    assert(unit_test_missing_column(false));
    assert(unit_test_missing_column_2(false));
  }
  assert(unit_test_extract_struct_deep(false));
  assert(unit_test_nested_functions(false));

  bool is_succeed = false;
  for (int i = 0; i < 10; i++) {
    is_succeed = is_succeed || unit_test_simple_select_operator(false);
    if (is_succeed)
      break;
  }
  assert(is_succeed);

  assert(unit_test_VALUES_clause_error(false));

  assert(unit_test_function_undefined(false));

  assert(unit_test_literal_fixing(false));

  assert(unit_test_type_where_mismatch(false));

  assert(unit_test_function_dynamic_instan(true));

  return 0;
}
