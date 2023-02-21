// This file is used to run and sample function/operator signatures from the
// DBMS. Read all the function signatures from the postgresql_func_type_lib and
// postgresql_opr_type_lib, test them in the DBMS, and retrieve the testing information
// into a JSON file.

//#define DEBUG
#define LOGGING

#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

#include "../header/data_type_sig.h"
#include "../header/utils.h"
#include "../header/postgres_connector.h"

PostgresClient g_psql_client;

char *FUNC_OPER_TYPE_LIB_PATH = "./mysql_func_opr_sign";

void init_all_sig(vector<FuncSig> &v_func_sig, vector<OprSig>& v_opr_sig) {

  std::ifstream t(FUNC_OPER_TYPE_LIB_PATH);
  std::stringstream buffer;
  buffer << t.rdbuf();
  string all_type_str = buffer.str();

  vector<string> func_type_split = string_splitter(all_type_str, "\n");

  for (int i = 0; i < func_type_split.size(); i++) {
    // Only scan for lines that contains grab_signature(description):
    string& cur_type_line = func_type_split[i];
    if (!findStringIn(cur_type_line, "grab_signature(description)")) {
      // This line does not contain function or operator signatures.
      continue;
    }
    if (cur_type_line.size() <= 29) {
      cerr << "\n\n\nERROR: Cannot find the 'grab_signature(description): ' in the string. "
              "Code logical error\n\n\n";
      assert(false);
    }

    cur_type_line = cur_type_line.substr(29, cur_type_line.size() - 29);
    cerr << "cur_type_line: " << cur_type_line << "\n\n\n";


  }
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
         << ", getting success rate: " << to_string( cur_func.get_success_rate())
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

int main() {

  vector<FuncSig> v_func_sig;
  vector<OprSig> v_opr_sig;
  init_all_sig(v_func_sig, v_opr_sig);

//  do_func_sample_testing(v_func_sig);
//  print_func_sample_testing(v_func_sig);

  return 0;
}
