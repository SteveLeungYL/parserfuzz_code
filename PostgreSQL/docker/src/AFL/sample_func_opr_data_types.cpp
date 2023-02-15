// This file is used to run and sample function/operator signatures from the
// DBMS. Read all the function signatures from the func_type_lib and
// opr_type_lib, test them in the DBMS, and retrieve the testing information
// into a JSON file.

#define DEBUG
#define LOGGING

#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

#include "../include/data_type_sig.h"
#include "../include/postgres_connector.h"

PostgresClient g_psql_client;

char *FUNC_TYPE_LIB_PATH = "./func_type_lib";
char *OPR_TYPE_LIB_PATH = "./opr_type_lib";

void init_all_func_sig(vector<FuncSig> &v_func_sig) {

  int parse_succeed = 0, parse_failed = 0;

  std::ifstream t(FUNC_TYPE_LIB_PATH);
  std::stringstream buffer;
  buffer << t.rdbuf();

  string func_type_str = buffer.str();

  vector<string> func_type_split = string_splitter(func_type_str, "\n");

  for (int i = 2; i < func_type_split.size() - 1; i++) {
    // Skip the first 2 lines and the last line.
    // The first two lines are name and separators, the last line is the row
    // number

    bool is_skip = false;

    vector<string> line_split = string_splitter(func_type_split[i], "|");
    if (line_split.size() != 4) {
      cerr << "\n\n\nERROR: For line break for line: " << func_type_split[i]
           << ", cannot split to four parts. \n\n\n";
      assert(false);
    }
    string func_sig_str = line_split[0];
    trim_string(func_sig_str);
    string ret_type_str = line_split[1];
    trim_string(ret_type_str);
    string func_category_flag = line_split[2];
    trim_string(func_category_flag);
    string func_aggregate_type = line_split[3];
    trim_string(func_aggregate_type);

    vector<string> tmp_line_break;
    string tmp_str;
    // Handle the func_sig_str
    tmp_line_break = string_splitter(func_sig_str, "(");
    if (tmp_line_break.size() != 2) {
      cerr << "\n\n\nERROR: for func_sig_str, the tmp_line_break is not at "
              "size 2. Str: "
           << func_sig_str << " \n\n\n";
      assert(false);
    }
    string cur_func_name = tmp_line_break.front();

    vector<DataType> v_arg_type;
    // Handle the function argument list.
    // remove right bracket ")".
    tmp_str = tmp_line_break[1];
    tmp_line_break = string_splitter(tmp_str, ")");
    if (tmp_line_break.size() != 2) {
      cerr << "\n\n\nERROR: for func_sig_str, the tmp_line_break is not at "
              "size 2. Str: "
           << tmp_str << " \n\n\n";
      assert(false);
    }
    tmp_str = tmp_line_break.front();

    // separate the function arguments.
    tmp_line_break = string_splitter(tmp_str, ",");
    for (const string &cur_arg_str : tmp_line_break) {
      if (cur_arg_str.empty()) {
        continue;
      }
      DataType cur_arg_type(cur_arg_str);
      if (cur_arg_type.get_data_type_enum() == kTYPEUNKNOWN) {
        is_skip = true;
#ifdef DEBUG
        cerr << "\n\n\nSkip function signature: \n"
             << func_type_split[i]
             << "\n because arguments parsing failed. \n\n\n";
#endif
        parse_failed++;
        break;
      }
      v_arg_type.push_back(cur_arg_type);
    }

    if (is_skip) {
      continue;
    }

    // And then, parse the return type string.
    DataType ret_type(ret_type_str);
    if (ret_type.get_data_type_enum() == kTYPEUNKNOWN) {
#ifdef DEBUG
      cerr << "\n\n\nSkip function signature: \n"
           << func_type_split[i]
           << "\n because arguments parsing failed. \n\n\n";
#endif
      parse_failed++;
      continue;
    }

    FuncSig cur_func_sig(cur_func_name, v_arg_type, ret_type,
                         func_category_flag, func_aggregate_type);

    v_func_sig.push_back(cur_func_sig);
    parse_succeed++;
  }

#ifdef LOGGING
  cerr << "\n\n\nLog: Successfully parse function: " << parse_succeed
       << ", failed: " << parse_failed << "\n\n\n";
#endif
}

void do_func_sample_testing(vector<FuncSig> &v_func_sig) {
  // For every saved functions, sample the function from running them in the
  // PostgreSQL DBMS. Log the validity rate.
  // Ad-hoc implementation. Please make it mature before moving it to the main
  // afl-fuzz fuzzer.

  int total_success = 0, total_fail = 0;
  int cur_process_idx = 1;

  for (FuncSig &cur_func : v_func_sig) {

    // Refresh the Database for every function only.
    string cmd_str =
        "CREATE TABLE v0 (c1 int, c2 bigint, c3 bigserial, c4 bit[3], c5 "
        "varbit[5], "
        "c6 bool, c7 bytea, c8 char[3], c9 varchar[5], c10 cidr, c11 date, "
        "c12 float, c13 inet, c14 interval, c15 json, c16 jsonb, c17 macaddr, "
        "c18 macaddr8, c19 money, c20 numeric, c21 real, c22 smallint, "
        "c23 smallserial, c24 serial, c25 text, c26 time, c27 timetz, "
        "c28 timestamp, c29 timestamptz, c30 uuid, c31 tsquery, c32 tsvector, "
        //             "c33 txidsnapshot, " // Not existed.
        "c34 xml, c35 box, c36 circle, c37 line, "
        "c38 point, c39 polygon, c40 oid); \n";
    g_psql_client.execute(cmd_str, true).outputs;
    for (int trial = 0; trial < 100; trial++) {

      string func_str = cur_func.get_mutated_func_str();
      cmd_str = "SELECT " + func_str + " FROM v0;\n";
#ifdef DEBUG
      cerr << "\n\n\nDEBUG: running with func_str: " << cmd_str << "\n";
#endif
      string res_str = g_psql_client.execute(cmd_str, false).outputs;

#ifdef DEBUG
      cerr << "Get res string: " << res_str << "\n\n\n";
#endif

      if (findStringIn(res_str, "ERROR")) {
        cur_func.increment_execute_error();
      } else {
        cur_func.increment_execute_success();
      }
    }

#ifdef LOGGING
    cerr << "For func: " << cur_func.get_func_signature()
         << ", getting success rate: " << to_string(cur_func.get_success_rate())
         << "%\n";
    total_success += cur_func.get_execute_success();
    total_fail += cur_func.get_execute_error();
    cerr << "\n\n\nUp to now, in total, success: " << total_success
         << ", error: " << total_fail << ", success rate: "
         << to_string(100.0 * double(total_success) /
                      double(total_success + total_fail))
         << "\nProcess: " << cur_process_idx << "/" << v_func_sig.size()
         << "\n\n\n";
    cur_process_idx++;
#endif
  }
}

void print_func_sample_testing(const vector<FuncSig> &v_func_sig) {

  int total_success = 0, total_fail = 0;

  cout << "\n\n\nRES: \n";
  for (const FuncSig &cur_func : v_func_sig) {
    cout << "For func: " << cur_func.get_func_name()
         << ", getting success rate: " << to_string(cur_func.get_success_rate())
         << "%\n\n";
    total_success += cur_func.get_execute_success();
    total_fail += cur_func.get_execute_error();
  }

  cout << "\n\n\nIn total, success: " << total_success
       << ", error: " << total_fail << ", success rate: "
       << to_string(100.0 * double(total_success) /
                    double(total_success + total_fail))
       << "\n\n\n";
}

void init_all_opr_sig(vector<OprSig> &v_opr_sig) {

  int parse_succeed = 0, parse_failed = 0;

  std::ifstream t(OPR_TYPE_LIB_PATH);
  std::stringstream buffer;
  buffer << t.rdbuf();

  string opr_type_str = buffer.str();

  vector<string> opr_type_split = string_splitter(opr_type_str, "\n");

  for (int i = 2; i < opr_type_split.size() - 1; i++) {
    // Skip the first 2 lines and the last line.
    // The first two lines are name and separators, the last line is the row
    // number

    vector<string> line_split = string_splitter(opr_type_split[i], "| ");
    if (line_split.size() != 4) {
      cerr << "\n\n\nERROR: For line break for line: " << opr_type_split[i]
           << ", cannot split to four parts. \n\n\n";
      assert(false);
    }
    string opr_sig_str = line_split[0];
    trim_string(opr_sig_str);
    string left_type_str = line_split[1];
    trim_string(left_type_str);
    string right_type_str = line_split[2];
    trim_string(right_type_str);
    string ret_type_str = line_split[3];
    trim_string(ret_type_str);

    OprSig cur_opr_sig;

    vector<string> tmp_line_break;
    string tmp_str;
    // Handle the opr_func_str
    tmp_line_break = string_splitter(opr_sig_str, "(");
    if (tmp_line_break.size() != 2) {
      cerr << "\n\n\nERROR: for func_sig_str, the tmp_line_break is not at "
              "size 2. Str: "
           << opr_sig_str << " \n\n\n";
      assert(false);
    }
    tmp_str = tmp_line_break.front();
    cur_opr_sig.set_opr_name(tmp_str);

    // Handle the left, right and return oprator type string
    DataType left_type(left_type_str);
    cur_opr_sig.set_left_type(left_type);
    DataType right_type(right_type_str);
    cur_opr_sig.set_right_type(right_type);
    DataType ret_type(ret_type_str);
    cur_opr_sig.set_ret_type(ret_type);

    if (left_type.get_data_type_enum() == kTYPEUNKNOWN ||
        right_type.get_data_type_enum() == kTYPEUNKNOWN ||
        ret_type.get_data_type_enum() == kTYPEUNKNOWN) {
#ifdef DEBUG
      cerr << "\n\n\nSkip oprator signature: \n"
           << opr_type_split[i]
           << "\n because arguments parsing failed. \n\n\n";
#endif
      parse_failed++;
      continue;
    }

    v_opr_sig.push_back(cur_opr_sig);
    parse_succeed++;
  }

#ifdef LOGGING
  cerr << "\n\n\nLog: Successfully parse oprator: " << parse_succeed
       << ", failed: " << parse_failed << "\n\n\n";
#endif
}

void do_opr_sample_testing(vector<OprSig> &v_opr_sig) {

  // For every saved oprators, sample the oprator from running them in the
  // PostgreSQL DBMS. Log the validity rate.
  // Ad-hoc implementation. Please make it mature before moving it to the main
  // afl-fuzz fuzzer.

  int total_success = 0, total_fail = 0;
  int cur_process_idx = 1;
  for (OprSig &cur_opr : v_opr_sig) {

    // Refresh the Database for every operator only.
    string cmd_str =
        "CREATE TABLE v0 (c1 int, c2 bigint, c3 bigserial, c4 bit[3], c5 "
        "varbit[5], "
        "c6 bool, c7 bytea, c8 char[3], c9 varchar[5], c10 cidr, c11 date, "
        "c12 float, c13 inet, c14 interval, c15 json, c16 jsonb, c17 macaddr, "
        "c18 macaddr8, c19 money, c20 numeric, c21 real, c22 smallint, "
        "c23 smallserial, c24 serial, c25 text, c26 time, c27 timetz, "
        "c28 timestamp, c29 timestamptz, c30 uuid, c31 tsquery, c32 tsvector, "
        //             "c33 txidsnapshot, " // Not existed.
        "c34 xml, c35 box, c36 circle, c37 line, "
        "c38 point, c39 polygon, c40 oid); \n";
    g_psql_client.execute(cmd_str, true).outputs;

    for (int trial = 0; trial < 100; trial++) {
      string opr_str = cur_opr.get_mutated_opr_str();
      cmd_str = "SELECT " + opr_str + " FROM v0;\n";
#ifdef DEBUG
      cerr << "\n\n\nDEBUG: running with opr_str: " << cmd_str << "\n";
#endif
      string res_str = g_psql_client.execute(cmd_str, false).outputs;

#ifdef DEBUG
      cerr << "Get res string: " << res_str << "\n\n\n";
#endif

      if (findStringIn(res_str, "ERROR")) {
        cur_opr.increment_execute_error();
      } else {
        cur_opr.increment_execute_success();
      }
    }

#ifdef LOGGING
    cerr << "For oprator: " << cur_opr.get_opr_signature()
         << ", getting success rate: " << to_string(cur_opr.get_success_rate())
         << "%\n";
    total_success += cur_opr.get_execute_success();
    total_fail += cur_opr.get_execute_error();
    cerr << "\n\n\nUp to now, in total, success: " << total_success
         << ", error: " << total_fail << ", success rate: "
         << to_string(100.0 * double(total_success) /
                      double(total_success + total_fail))
         << "\nProcess: " << cur_process_idx << "/" << v_opr_sig.size()
         << "\n\n\n";
#endif
    cur_process_idx++;
  }
}

void print_opr_sample_testing(const vector<OprSig> &v_opr_sig) {

  int total_success = 0, total_fail = 0;

  cout << "\n\n\nRES: \n";
  for (const OprSig &cur_opr : v_opr_sig) {
    cout << "For operator: " << cur_opr.get_opr_name()
         << ", getting success rate: " << to_string(cur_opr.get_success_rate())
         << "%\n\n";
    total_success += cur_opr.get_execute_success();
    total_fail += cur_opr.get_execute_error();
  }

  cout << "\n\n\nIn total, operator, success: " << total_success
       << ", error: " << total_fail << ", success rate: "
       << to_string(100.0 * double(total_success) /
                    double(total_success + total_fail))
       << "\n\n\n";
}

int main() {

  vector<FuncSig> v_func_sig;
  vector<OprSig> v_opr_sig;
  init_all_func_sig(v_func_sig);

  do_func_sample_testing(v_func_sig);
  print_func_sample_testing(v_func_sig);

  init_all_opr_sig(v_opr_sig);
  do_opr_sample_testing(v_opr_sig);

  print_opr_sample_testing(v_opr_sig);

  return 0;
}
