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

char FUNC_OPER_TYPE_LIB_PATH[] = "./sqlite.csv";

void init_all_sig(vector<FuncSig> &v_res_func_sig, vector<OprSig>& v_res_opr_sig) {

  std::ifstream t(FUNC_OPER_TYPE_LIB_PATH);
  std::stringstream buffer;
  buffer << t.rdbuf();
  string all_type_str = buffer.str();

  vector<string> func_type_split = string_splitter(all_type_str, "\n");

  int func_parsing_succeed = 0, func_parsing_failure = 0, opr_parsing_succeed = 0,
      opr_parsing_failure = 0;

}

int main() {

  vector<FuncSig> v_func_sig; 
  vector<OprSig> v_opr_sig;
  init_all_sig(v_func_sig, v_opr_sig);

  return 0;
}


