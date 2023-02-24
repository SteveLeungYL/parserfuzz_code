// This file is used to run and sample function/operator signatures from the
// DBMS. Read all the function signatures from the mysql_func_opr_sign , 
// test them in the DBMS, and retrieve the testing information
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
#include "../header/sqlite_connector.h"

char FUNC_OPER_TYPE_LIB_PATH[] = "./sqlite_func_sig.csv";

void init_func_sig(vector<FuncSig> &v_res_func_sig) {

  std::ifstream t(FUNC_OPER_TYPE_LIB_PATH);
  std::stringstream buffer;
  buffer << t.rdbuf();
  string all_type_str = buffer.str();

  vector<string> func_type_split = string_splitter(all_type_str, "\n");

  int func_parsing_succeed = 0, func_parsing_failure = 0, opr_parsing_succeed = 0,
      opr_parsing_failure = 0;

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
  }

}

int main() {

  vector<FuncSig> v_func_sig; 
  vector<OprSig> v_opr_sig;
  init_func_sig(v_func_sig);

  return 0;
}


