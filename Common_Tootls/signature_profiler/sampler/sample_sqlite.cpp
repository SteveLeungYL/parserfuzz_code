// This file is used to run and sample function/operator signatures from the
// DBMS. Read all the function signatures from the mysql_func_opr_sign , 
// test them in the DBMS, and retrieve the testing information
// into a JSON file.

#define DEBUG
#define LOGGING

#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

#include "../header/data_type_sig.h"
#include "../header/utils.h"
#include "../header/sqlite_connector.h"

using namespace std;

char FUNC_OPER_TYPE_LIB_PATH[] = "./sqlite_func_sig.csv";

static vector<DATATYPE> all_supported_types  = {
  kTYPEINT,
  kTYPEREAL,
  kTYPETEXT,
  kTYPEJSON
};

SQLiteClient sqlite_client;

void init_func_sig(vector<FuncSig> &v_res_func_sig) {

  std::ifstream t(FUNC_OPER_TYPE_LIB_PATH);
  std::stringstream buffer;
  buffer << t.rdbuf();
  string all_type_str = buffer.str();

  vector<string> func_type_split = string_splitter(all_type_str, "\n");

  int func_parsing_succeed = 0, func_parsing_failure = 0;

  for ( int i = 0; i < func_type_split.size(); i++ ) {
    // Only scan for lines that contains grab_signature(description):
    string& cur_type_line = func_type_split[i];

    if (is_str_empty(cur_type_line)) {
      continue;
    }

    vector<string>tmp_line_split = string_splitter(cur_type_line, ",");

    if (tmp_line_split.size() != 6) {
      cerr << "\n\n\nERROR: SQLite line split is not size 6. \n";
      cerr << "line: " << cur_type_line << "\n\n\n";
      assert (false);
      return;
    }

    string func_name = tmp_line_split.front();
    int num_args = stoi(tmp_line_split.at(4));
    if (num_args == -1) {
      num_args = get_rand_int(5) + 1; // Avoid 0
    }

    vector<DataType> v_arg_types;
    DataType ret_type(kTYPEUNDEFINE);

    for (int j = 0; j < num_args; j++) {
      v_arg_types.push_back(DataType(kTYPEUNDEFINE));
    }

    FuncCategory func_category = Normal;

    if (tmp_line_split[2] == "a") {
      func_category = Aggregate;
    } else if (tmp_line_split[2] == "w") {
      func_category = Window;
    }

    FuncSig cur_func_sig(func_name, v_arg_types, ret_type, func_category, all_supported_types);

    if (cur_func_sig.is_contain_unsupported()) {
      func_parsing_failure++;
#ifdef DEBUG
          cerr << "\nDEBUG: for cur_func_sig: " << cur_type_line
               << ", parsing failure\n";
          cerr << "parsing success rate: " << 100.0 * float(func_parsing_succeed) / 
            float(func_parsing_succeed + func_parsing_failure) << "%\n\n\n";
#endif
      continue;
    }

#ifdef DEBUG
          cerr << "saving func: " << cur_func_sig.get_func_signature() << "\n\n\n";
          cerr << "parsing success rate: " << 100.0 * float(func_parsing_succeed) / 
            float(func_parsing_succeed + func_parsing_failure) << "%\n\n\n";
#endif
    func_parsing_succeed++;
    v_res_func_sig.push_back(cur_func_sig);

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


    for (int trial = 0; trial < 100; trial++) {

      string cmd_str = "create table v0 (c1 int); ";
      // Refresh the Database for every function only.
      string res_str = "";
      res_str.clear();


      string func_str = cur_func.get_mutated_func_str();
      cmd_str += "SELECT " + func_str + " FROM v0;\n";
#ifdef DEBUG
      cerr << "\n\n\nDEBUG: running with func_str: " << cmd_str << "\n";
#endif
      auto result = sqlite_client.execute(cmd_str, 3000, res_str);

#ifdef DEBUG
      cerr << "Get res string: " << res_str << "\n";
#endif

      if (findStringIn(res_str, "ERROR") || result != kNormal) {
#ifdef DEBUG
        cerr << "Get ERROR from result. \n";
#endif
        cur_func.increment_execute_error();
      } else if (!is_str_empty(res_str)) {
#ifdef DEBUG
        cerr << "Get SUCCESS from result. \n";
#endif
        cur_func.increment_execute_success();
      } else {
#ifdef DEBUG
        cerr << "Getting empty output. Maybe the semantic is not correct. \n";
#endif
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

int main() {

  vector<FuncSig> v_func_sig; 
  vector<OprSig> v_opr_sig;
  init_func_sig(v_func_sig);

  do_func_sample_testing(v_func_sig);

  return 0;
}


