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

bool iden_common_error(IR* cur_stmt) {
    vector<IR*> all_nodes = p_oracle->ir_wrapper.get_all_ir_node(cur_stmt);
    for (IR* cur_node: all_nodes) {
        string cur_node_str = cur_node->to_string();
        trim_string(cur_node_str);
        if (cur_node_str == "x" || cur_node_str == "y") {
            return false;
        }
    }
    return true;
}

bool dyn_fix_stmt_vec(vector<IR*>& all_pre_trans_vec, const vector<string>& res_vec, bool is_debug) {

    IR* cur_trans_stmt;
    string whole_query_sequence = "";
    const int max_trial = 3;
    int total_instan_num = 0;
    vector<IR*> tmp_all_pre_trans_vec;

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

                IR* ori_trans_stmt = cur_trans_stmt;
                string cur_trans_str = cur_trans_stmt->to_string();
                // Statement re-parsed.
                vector<IR*> v_new_parsed = g_mutator.parse_query_str_get_ir_set(cur_trans_str);
                if (v_new_parsed.size() == 0) {
                    cerr << "\n\n\nFATAL ERROR: The fixed stmt cannot pass the parser: \n"
                         << cur_trans_str << "\n\n\n";
                    // fallback to the string before instantiation.
                    g_mutator.rollback_instan_lib_changes();
                    // v_new_parsed = g_mutator.parse_query_str_get_ir_set(ori_stmt_before_instan);
                    cur_trans_stmt = NULL;
                    ori_trans_stmt->deep_drop();
                    break;
                }
//                  if (v_new_parsed.size() == 0) {
//                      cur_trans_stmt = NULL;
//                      ori_trans_stmt->deep_drop();
//                      break;
//                  }
                IR* new_parsed_root = v_new_parsed.back();
                cur_trans_stmt = new_parsed_root->get_left()->get_left()->get_left()->deep_copy();
                cur_trans_stmt->parent_ = NULL;
                new_parsed_root->deep_drop();
                ori_trans_stmt->deep_drop();

                // Avoid modifying the required nodes for the oracle.
                p_oracle->mark_all_valid_node(cur_trans_stmt);

                g_mutator.fix_instan_error(cur_trans_stmt, res_vec[stmt_idx], trial, is_debug);

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

    vector<string> stmt_list {
            "create table v0 (v1 int, v2 string, family (v1, v1));",
            "select * from v0 where v1 = 0;"
    };

    vector<string> res_list {
            "ERROR: relation \"v0\" (112): column 1 is in both family 0 and 0",
            ""
    };

    vector<IR*> ir_list;
    for (string& cur_stmt: stmt_list) {
        IR* cur_root = g_mutator.parse_query_str_get_ir_set(cur_stmt).back();
        ir_list.push_back(p_oracle->ir_wrapper.get_first_stmt_from_root(cur_root)->deep_copy());
        cur_root->deep_drop();
    }

    dyn_fix_stmt_vec(ir_list, res_list, is_show_debug);
    bool is_no_error;
    for (IR* cur_stmt: ir_list) {
        if (is_show_debug) {
            cerr << "Debug: Getting final stmt: " << cur_stmt->to_string() << "\n";
        }
        is_no_error = iden_common_error(cur_stmt);
        if (!is_no_error) {
            break;
        }
    }

    for (auto cur_ir: ir_list) {
        cur_ir->deep_drop();
    }

    return is_no_error;

}

bool unit_test_alter_bugs(bool is_show_debug = false) {

    g_mutator.pre_validate();

    // Succeed with return true,
    // Failed with return false.

    vector<string> stmt_list {
        "CREATE TABLE v0 (c1 STRING, c2 TIMESTAMPTZ, c3 INTERVAL, c4 SERIAL);",
        "SET enable_implicit_select_for_update = off;",
        "SET transaction_read_only = off;",
        "SET null_ordered_last = true;",
        "CREATE TABLE v9 (c10 INTERVAL PRIMARY KEY, c11 DECIMAL, FAMILY family_12(c11, c10));", // "ERROR: relation \"v9\" (112): column 1 is in both family 0 and 0",
        "INSERT INTO v9 VALUES ('4-8 29 7:21:59'::INTERVAL, 54.112271);",
        "ALTER TABLE v9 ADD COLUMN c13 TIME AS ('03:36:39'::TIME) STORED;",
        "ALTER TABLE v0 ALTER COLUMN c3 DROP STORED, DROP COLUMN c11 CASCADE;", // ERROR: column "c3" is not a computed column
        "SELECT DISTINCT ON (LOG(69.446394, -53.124958)) COUNT( *) FROM v9 WHERE x IN ('61', '20 d 4 hrs 4 mins 32 secs', '169.254.0.0/16');" // ERROR: column "x" does not exist
    };

    vector<string> res_list {
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

    vector<IR*> ir_list;
    for (string& cur_stmt: stmt_list) {
        IR* cur_root = g_mutator.parse_query_str_get_ir_set(cur_stmt).back();
        ir_list.push_back(p_oracle->ir_wrapper.get_first_stmt_from_root(cur_root)->deep_copy());
        cur_root->deep_drop();
    }

    dyn_fix_stmt_vec(ir_list, res_list, is_show_debug);
    bool is_no_error;
    for (IR* cur_stmt: ir_list) {
        if (is_show_debug) {
            cerr << "Debug: Getting final stmt: " << cur_stmt->to_string() << "\n";
        }
        is_no_error = iden_common_error(cur_stmt);
        if (!is_no_error) {
            break;
        }
    }

    for (auto cur_ir: ir_list) {
        cur_ir->deep_drop();
    }

    return is_no_error;

}


bool unit_test_alias_0(bool is_show_debug = false) {

    g_mutator.pre_validate();

    // Succeed with return true,
    // Failed with return false.

    vector<string> stmt_list {
            "CREATE TABLE v0 (c1 STRING, c2 TIMESTAMPTZ, c3 INTERVAL, c4 SERIAL);",
            "SELECT TRUNC(69.396928) FROM v0 FULL JOIN v0 AS ta10(x, x, x) USING "
            "(c1, c3, c4) FULL JOIN v0 AS ta11(x, x, x) USING (c4) FULL JOIN v0 "
            "AS ta12(x, x, x) USING (c1) WHERE c3 BETWEEN 'hss' AND '10-14-70 04:31:23.2571+1';"
    };

    vector<string> res_list {
            "",
            "ERROR: column \"c1\" specified in USING clause does not exist in right table"
    };

    vector<IR*> ir_list;
    for (string& cur_stmt: stmt_list) {
        IR* cur_root = g_mutator.parse_query_str_get_ir_set(cur_stmt).back();
        ir_list.push_back(p_oracle->ir_wrapper.get_first_stmt_from_root(cur_root)->deep_copy());
        cur_root->deep_drop();
    }

    for (IR* cur_stmt: ir_list) {
        if (is_show_debug) {
            cerr << "Debug: Getting parsed stmt: " << cur_stmt->to_string() << "\n";
        }
    }

    dyn_fix_stmt_vec(ir_list, res_list, is_show_debug);
    bool is_no_error;
    for (IR* cur_stmt: ir_list) {
        if (is_show_debug) {
            cerr << "Debug: Getting final stmt: " << cur_stmt->to_string() << "\n";
        }
        is_no_error = iden_common_error(cur_stmt);
        if (!is_no_error) {
            break;
        }
    }

    for (auto cur_ir: ir_list) {
        cur_ir->deep_drop();
    }

    return is_no_error;

}


bool unit_test_with_alias_1(bool is_show_debug = false) {

    g_mutator.pre_validate();

    // Succeed with return true,
    // Failed with return false.

    vector<string> stmt_list {
            "CREATE TABLE v0 (c1 STRING, c2 TIMESTAMPTZ, c3 INTERVAL, c4 SERIAL);",
            "WITH ta0(tc1) AS (SELECT COUNT(*) FROM v0) SELECT * FROM v0;"
    };

    vector<string> res_list {
            "",
            "ERROR: relation \"tc0\" does not exist"
    };

    vector<IR*> ir_list;
    for (string& cur_stmt: stmt_list) {
        IR* cur_root = g_mutator.parse_query_str_get_ir_set(cur_stmt).back();
        ir_list.push_back(p_oracle->ir_wrapper.get_first_stmt_from_root(cur_root)->deep_copy());
        cur_root->deep_drop();
    }

    for (IR* cur_stmt: ir_list) {
        if (is_show_debug) {
            cerr << "Debug: Getting parsed stmt: " << cur_stmt->to_string() << "\n";
        }
    }

    dyn_fix_stmt_vec(ir_list, res_list, is_show_debug);
    bool is_no_error;
    for (IR* cur_stmt: ir_list) {
        if (is_show_debug) {
            cerr << "Debug: Getting final stmt: " << cur_stmt->to_string() << "\n";
        }
        is_no_error = iden_common_error(cur_stmt);
        if (!is_no_error) {
            break;
        }
    }

    for (auto cur_ir: ir_list) {
      cur_ir->deep_drop();
    }

    return is_no_error;

}

bool unit_test_jsonb_operator(bool is_show_debug = false) {

    g_mutator.pre_validate();

    // Succeed with return true,
    // Failed with return false.

    vector<string> stmt_list {
            "CREATE TABLE v0 (c1 STRING, c2 TIMESTAMPTZ, c3 INTERVAL, c4 SERIAL);",
            "SELECT x FROM (SELECT TIMEOFDAY( )->'9yhrt' AS ca189 FROM v0) WHERE x IS NOT NULL;",
            "SELECT DISTINCT ON (\"RIGHT\"( b'9', -688706232)) '4-7 9 5:37:27' AS ca207, ta206.c2 FROM v0 "
            "AS ta206 WHERE (ta206.c3 % B'0') = B'0';"
    };

    vector<string> res_list {
            "",
            "pq: unsupported binary operator: <bit> -> <varbit>",
            "pq: unsupported binary operator: <bit> % <varbit>"
    };

    vector<IR*> ir_list;
    for (string& cur_stmt: stmt_list) {
        IR* cur_root = g_mutator.parse_query_str_get_ir_set(cur_stmt).back();
        ir_list.push_back(p_oracle->ir_wrapper.get_first_stmt_from_root(cur_root)->deep_copy());
        cur_root->deep_drop();
    }

    for (IR* cur_stmt: ir_list) {
        if (is_show_debug) {
            cerr << "Debug: Getting parsed stmt: " << cur_stmt->to_string() << "\n";
        }
    }

    dyn_fix_stmt_vec(ir_list, res_list, is_show_debug);
    bool is_no_error;
    for (IR* cur_stmt: ir_list) {
        if (is_show_debug) {
            cerr << "Debug: Getting final stmt: " << cur_stmt->to_string() << "\n";
        }
        is_no_error = iden_common_error(cur_stmt);
        if (!is_no_error) {
            break;
        }
    }

    for (auto cur_ir: ir_list) {
        cur_ir->deep_drop();
    }

    return is_no_error;
}


bool unit_test_tuple_instan(bool is_show_debug = false) {

    g_mutator.pre_validate();

    // Succeed with return true,
    // Failed with return false.

    vector<string> stmt_list {
        "CREATE TABLE v0 (c1 STRING, c2 TIMESTAMPTZ, c3 INTERVAL, c4 SERIAL);",
        "SELECT * FROM v0 WHERE ('6597:6b20:879b:b681:c388:8635:ba39:1d50', '6ab3:767c:bd55:606b:67ac:f29d:9478:e420', 0, '03:42:35.1468', '05:14:42.1891') != '2douwult';"
    };

    vector<string> res_list {
        "",
        "pq: could not parse \"2douwult\" as type tuple{string, string, int, string, string}: record must be enclosed in ( and )"
    };

    vector<IR*> ir_list;
    for (string& cur_stmt: stmt_list) {
        IR* cur_root = g_mutator.parse_query_str_get_ir_set(cur_stmt).back();
        ir_list.push_back(p_oracle->ir_wrapper.get_first_stmt_from_root(cur_root)->deep_copy());
        cur_root->deep_drop();
    }

    for (IR* cur_stmt: ir_list) {
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
    for (IR* cur_stmt: ir_list) {
        if (is_show_debug) {
            cerr << "Debug: Getting final stmt: " << cur_stmt->to_string() << "\n";
        }
        is_no_error = iden_common_error(cur_stmt);
        if (!is_no_error) {
            break;
        }
    }

    for (auto cur_ir: ir_list) {
        cur_ir->deep_drop();
    }

    return is_no_error;

}

bool unit_test_tuple_instan_2(bool is_show_debug = false) {

  g_mutator.pre_validate();

  // Succeed with return true,
  // Failed with return false.

  vector<string> stmt_list {
      "CREATE TABLE v0 (c1 STRING, c2 TIMESTAMPTZ, c3 INTERVAL, c4 SERIAL);",
      "SELECT * FROM v0 WHERE ('6597:6b20:879b:b681:c388:8635:ba39:1d50', '6ab3:767c:bd55:606b:67ac:f29d:9478:e420', 0, '03:42:35.1468', '05:14:42.1891') != c3;"
  };

  vector<string> res_list {
      "",
      "ERROR: unsupported comparison operator: <tuple{string, string, int, string, string}> != <interval>"
  };

  vector<IR*> ir_list;
  for (string& cur_stmt: stmt_list) {
    IR* cur_root = g_mutator.parse_query_str_get_ir_set(cur_stmt).back();
    ir_list.push_back(p_oracle->ir_wrapper.get_first_stmt_from_root(cur_root)->deep_copy());
    cur_root->deep_drop();
  }

  for (IR* cur_stmt: ir_list) {
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
  for (IR* cur_stmt: ir_list) {
    if (is_show_debug) {
      cerr << "Debug: Getting final stmt: " << cur_stmt->to_string() << "\n";
    }
    is_no_error = iden_common_error(cur_stmt);
    if (!is_no_error) {
      break;
    }
  }

  for (auto cur_ir: ir_list) {
    cur_ir->deep_drop();
  }

  return is_no_error;

}


bool unit_test_literal_instan(bool is_show_debug = false) {

  g_mutator.pre_validate();

  DATAAFFINITYTYPE cur_affi = AFFIARRAYANY;

  // UNIT TEST the instantiation of the literal.
  IR* tmp_IR = new IR(TypeStringLiteral, string(""), DataLiteral, ContextUnknown, cur_affi);
  tmp_IR->mutate_literal();

  if (is_show_debug) {
    cerr << "\n\n\nDEBUG: when fixing literal with affinity: " << get_string_by_affinity_type(cur_affi)
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

  vector<string> stmt_list {
      "CREATE TABLE v0 (c1 STRING, c2 TIMESTAMPTZ, c3 INTERVAL, c4 SERIAL);",
      "SELECT * FROM ROWS FROM (BTRIM('gj404usqz', '09-07-51')) WHERE x = '3fa467c5-898c-da8c-4abe-9576f126f949';"
  };

  vector<string> res_list {
      "",
      "pq: column \"x\" does not exist"
  };

  vector<IR*> ir_list;
  for (string& cur_stmt: stmt_list) {
    IR* cur_root = g_mutator.parse_query_str_get_ir_set(cur_stmt).back();
    ir_list.push_back(p_oracle->ir_wrapper.get_first_stmt_from_root(cur_root)->deep_copy());
    cur_root->deep_drop();
  }

  for (IR* cur_stmt: ir_list) {
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
  for (IR* cur_stmt: ir_list) {
    if (is_show_debug) {
      cerr << "Debug: Getting final stmt: " << cur_stmt->to_string() << "\n";
    }
    is_no_error = iden_common_error(cur_stmt);
    if (!is_no_error) {
      break;
    }
  }

  for (auto cur_ir: ir_list) {
    cur_ir->deep_drop();
  }

  return is_no_error;

}

bool unit_test_missing_column_2(bool is_show_debug = false) {

  g_mutator.pre_validate();

  // Succeed with return true,
  // Failed with return false.

  vector<string> stmt_list {
      "SELECT * FROM ROWS FROM (BTRIM('gj404usqz', '09-07-51')) WHERE x = '3fa467c5-898c-da8c-4abe-9576f126f949';"
  };

  vector<string> res_list {
      "pq: column \"x\" does not exist"
  };

  vector<IR*> ir_list;
  for (string& cur_stmt: stmt_list) {
    IR* cur_root = g_mutator.parse_query_str_get_ir_set(cur_stmt).back();
    ir_list.push_back(p_oracle->ir_wrapper.get_first_stmt_from_root(cur_root)->deep_copy());
    cur_root->deep_drop();
  }

  for (IR* cur_stmt: ir_list) {
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
  assert (ir_list.size() == res_list.size());
  bool is_no_error;
  for (IR* cur_stmt: ir_list) {
    if (is_show_debug) {
      cerr << "Debug: Getting final stmt: " << cur_stmt->to_string() << "\n";
    }
    is_no_error = iden_common_error(cur_stmt);
    if (!is_no_error) {
      break;
    }
  }

  for (auto cur_ir: ir_list) {
    cur_ir->deep_drop();
  }

  return is_no_error;

}

bool unit_test_extract_struct_deep(bool is_show_debug = false) {

  // Succeed with return true,
  // Failed with return false.

  vector<string> stmt_list {
      "SELECT * FROM ROWS FROM (BTRIM('gj404usqz', '09-07-51')) WHERE x = '3fa467c5-898c-da8c-4abe-9576f126f949';"
  };

  vector<IR*> ir_list;
  for (string& cur_stmt: stmt_list) {
    IR* cur_root = g_mutator.parse_query_str_get_ir_set(cur_stmt).back();
    ir_list.push_back(p_oracle->ir_wrapper.get_first_stmt_from_root(cur_root)->deep_copy());
    cur_root->deep_drop();
  }

  for (IR* cur_stmt: ir_list) {
    if (is_show_debug) {
      cerr << "Debug: Getting parsed stmt: " << cur_stmt->to_string() << "\n";
      IR* cur_stmt_ext = cur_stmt->deep_copy();
      IR* cur_stmt_ext_deep = cur_stmt->deep_copy();
      cerr << "extract_struct: " << g_mutator.extract_struct(cur_stmt_ext) << "\n\n\n";
      cerr << "extract_struct_deep: " << g_mutator.extract_struct_deep(cur_stmt_ext_deep) << "\n\n\n";
      cur_stmt_ext->deep_drop();
      cur_stmt_ext_deep->deep_drop();
    }
    cur_stmt->deep_drop();
  }

  return true;

}

int main(int argc, char *argv[]) {

    if (argc != 1) {
        cout << "./unit_test_dyn_fix" << endl;
        return -1;
    }

    g_mutator.init("");
    g_mutator.init_data_library();

    p_oracle = new SQL_OPT();

    g_mutator.set_p_oracle(p_oracle);
    p_oracle->set_mutator(&g_mutator);

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
    assert(unit_test_extract_struct_deep(true));

    return 0;
}
