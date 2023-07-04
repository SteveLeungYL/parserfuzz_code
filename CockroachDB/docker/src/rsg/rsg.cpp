#include <cstdlib>
#include <string>

#include "../include/ast.h"
#include "rsg.h"
#include "rsg_helper.h"

using std::string;

/*
 * Initialize the RSG structure.
 */

void rsg_initialize() {
  const string parser_file_str = "./cockroach_sql_modi.y";
  GoString parser_file_gostr = {parser_file_str.c_str(),
                                long(parser_file_str.size())};

  const string dbms_name = "cockroachdb";
  GoString dbms_name_gostr = {dbms_name.c_str(), long(dbms_name.size())};

  RSGInitialize(parser_file_gostr, dbms_name_gostr, 0.3);
  return;
}

string rsg_generate(const string& input_str) {

  string res_str;
  int gen_trial = 0;
  const int gen_trial_max = 100;

  do {

    rsg_clear_chosen_expr();

    GoString gostr_input = {input_str.c_str(), long(input_str.size())};

    const string dbms_name_str = "cockroachdb";
    GoString dbms_name = {dbms_name_str.c_str(), long(dbms_name_str.size())};

    // Actual Parsing.
    RSGQueryGenerate_return gores = RSGQueryGenerate(gostr_input, dbms_name);
    if (gores.r0 == NULL) {
      return "";
    }

    // Extract the parsed JSON string. Free the char array memory.
    for (int i = 0; i < gores.r1; i++) {
      res_str += gores.r0[i];
    }
    free(gores.r0);

  } while (res_str.empty() && gen_trial++ < gen_trial_max);

  return res_str;
}

/*
 * From the RSG, generate one random query statement.
 */
string rsg_generate(const IRTYPE type) {

  // Convert the test string to GoString format.
  // Only supporting TypeSelect and TypeStmt.
  string input_str;
  if (type == TypeSelect) {
    input_str = "select_stmt";
  } else {
    input_str = "stmt_without_legacy_transaction";
  }

  return rsg_generate(input_str);
}


void rsg_clear_chosen_expr() { RSGClearChosenExpr(); }
void rsg_exec_succeed() { RSGExecSucceed(); }
void rsg_exec_failed() { RSGExecFailed(); }
