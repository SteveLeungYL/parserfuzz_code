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

char FUNC_OPER_TYPE_LIB_PATH[] = "./mysql_func_opr_sign";

inline DataType parse_arg_type(string& cur_arg_str) {

  // We ignore the optional symbol of [], if the function provide optional 
  // arguments, always use them. 
  
  // Handle the ENUM type first. 
  if (findStringIn(cur_arg_str, "{")) {
    string tmp;
    vector<string> v_tmp = string_splitter(cur_arg_str, "{");
    tmp = v_tmp[1];
    v_tmp = string_splitter(tmp, "}");
    if (v_tmp.size() < 2) {
      cerr << "\n\n\nError: cannot find the matching right } that is matching the left {. Logic Error. \n\n\n";
      assert(false);
      return DataType(kTYPEUNDEFINE);
    }

    // Assuming there is only one enum in the single argument string.
    tmp = v_tmp[0];

    vector<string> v_enum_str = string_splitter(tmp, "|");

    DataType res(kTYPEENUM);
    res.set_v_enum_str(v_enum_str);

    return res;
  }


  if (cur_arg_str == "algorithm") {
    return DataType(kTYPETEXT);
  }  else if (cur_arg_str == "pos") {
    return DataType(kTYPESMALLINT);
  } else if (cur_arg_str == "N") {
    return DataType(kTYPESMALLINT);
  } else if (findStringIn(cur_arg_str, "str")) {
    return DataType(kTYPETEXT);
  } else if (findStringIn(cur_arg_str, "_len")){
    return DataType(kTYPESMALLINT);
  } else if (findStringIn(cur_arg_str, "value")) {
    return DataType(kTYPEANY);
  } else if (findStringIn(cur_arg_str, "expr")) {
    return DataType(kTYPEANY);
  } else if (findStringIn(cur_arg_str, "X") ||
        findStringIn(cur_arg_str, "Y")
        ) {
    return DataType(kTYPEANY);
  } 


  return DataType(kTYPEUNDEFINE);
}

vector<FuncSig> init_func_sig(string& cur_type_line, const string& cur_func_category) {

  // For the cur_type_line, first of all, separate the same line different
  // function signature

  vector<FuncSig> v_res_sig;
  vector<string> v_diff_sign = string_splitter(cur_type_line, "), ");


  for (int i = 0; i < v_diff_sign.size(); i++) {
    if (i == v_diff_sign.size() - 1) {
      // remove the extra ')' from the last function signature
      v_diff_sign[i] = v_diff_sign[i].substr(0, v_diff_sign[i].size()-1);
    }

    vector<DataType> v_arg_type;
    string cur_func_name;

    string cur_func_str = v_diff_sign[i];
    // Separate the function name and the arguments.
    vector<string> v_func = string_splitter(cur_func_str, "(");
    cur_func_name = v_func.front();

    string arg_list = v_func.back();
    vector<string> v_arg_str = string_splitter(arg_list, ", ");

    for (auto& cur_arg_str: v_arg_str) {
      v_arg_type.push_back(parse_arg_type(cur_arg_str));
    }

    DataType ret_type(kTYPEUNDEFINE);

    FuncCategory cur_func_cate = Normal;
    if (cur_func_category == "Window Functions") {
      cur_func_cate = Window;
    } else if (cur_func_category == "Aggregate Functions and Modifiers") {
      cur_func_cate = Aggregate;
    }

    FuncSig new_func_sig(cur_func_name, v_arg_type, ret_type, cur_func_cate);
#ifdef DEBUG
    cerr << "\n\n\nDEBUG: getting function signature: " << new_func_sig.get_func_signature() << "\n\n\n";
#endif
    v_res_sig.push_back(new_func_sig);
  }

  return v_res_sig;
}

vector<OprSig> init_opr_sig(string& cur_type_line, const string& cur_opr_category) {

  if (
      cur_type_line.size() > 10 ||
      findStringIn(cur_type_line, "expr") ||
      findStringIn(cur_type_line, "pat")
      ) {
    cerr << "\n\n\nDEBUG: Ignoring operator string: " << cur_type_line << "\n\n\n";
    return {};
  }

  vector<string> line_split = string_splitter(cur_type_line, ", ");
  vector<OprSig> v_res;

  for (string& cur_type: line_split) {
    OprSig cur_opr_sig(cur_type);
    v_res.push_back(cur_opr_sig);
#ifdef DEBUG
    cerr << "\n\n\nDEBUG:: Getting new operator type: " << cur_opr_sig.get_opr_signature() << "\n\n\n";
#endif
  }

  return v_res;
}

void init_all_sig(vector<FuncSig> &v_func_sig, vector<OprSig>& v_opr_sig) {

  std::ifstream t(FUNC_OPER_TYPE_LIB_PATH);
  std::stringstream buffer;
  buffer << t.rdbuf();
  string all_type_str = buffer.str();

  vector<string> func_type_split = string_splitter(all_type_str, "\n");

  int func_parsing_succeed = 0, func_parsing_failure = 0, opr_parsing_succeed = 0,
      opr_parsing_failure = 0;

  string cur_type_category = "";
  for (int i = 0; i < func_type_split.size(); i++) {
    // Only scan for lines that contains grab_signature(description):
    string& cur_type_line = func_type_split[i];

    if (findStringIn(cur_type_line, "TYPE: ")) {
      // This line contains the function type string.
      cur_type_category = cur_type_line.substr(29, cur_type_line.size() - 29);
      continue;
    }

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

    if (findStringIn(cur_type_line, "(") || findStringIn(cur_type_line, ")")) {
      // If the line contains "(", ")" synbols, assume this is the FUNCTION type.
      vector<FuncSig> v_func_sig = init_func_sig(cur_type_line, cur_type_category);
      for (auto cur_func_sig: v_func_sig) {
        if (cur_func_sig.is_contain_unsupported()) {
          func_parsing_failure++;
#ifdef DEBUG
          cerr << "\nDEBUG: for cur_func_sig: " << cur_type_line
               << ", parsing failure\n\n\n";
#endif
        } else {
          func_parsing_succeed++;
          v_func_sig.push_back(cur_func_sig);
        }
      }
    } else {
      vector<OprSig> v_opr_sig = init_opr_sig(cur_type_line, cur_type_category);
      for (auto cur_opr_sig : v_opr_sig) {
        if (cur_opr_sig.is_contain_unsupported()) {
#ifdef DEBUG
          cerr << "\nDEBUG: for cur_opr_sig: " << cur_type_line
               << ", parsing failure\n\n\n";
#endif
          opr_parsing_failure++;
        } else {
          opr_parsing_succeed++;
          v_opr_sig.push_back(cur_opr_sig);
        }
      }
    }
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
