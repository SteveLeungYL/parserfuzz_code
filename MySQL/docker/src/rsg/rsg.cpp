#include "rsg.h"
#include "rsg_helper.h"

#include <string>

using std::string;

/*
 * Initialize the RSG structure.
 */

void rsg_initialize() {

  const string parser_file_str = "./mysql_sql.y";
  GoString parser_file_gostr = {parser_file_str.c_str(),
                                long(parser_file_str.size())};

  const string dbms_name = "mysql";
  GoString dbms_name_gostr = {dbms_name.c_str(), long(dbms_name.size())};

  const string fuzzing_mode = "normal";
  GoString fuzzing_mode_gostr = {fuzzing_mode.c_str(), long(fuzzing_mode.size())};

  RSGInitialize(parser_file_gostr, dbms_name_gostr, 0.3, fuzzing_mode_gostr);
  return;
}

void rsg_clear_chosen_expr() { RSGClearChosenExpr(); }
void rsg_save_fav_node() { RSGSaveFav(); }

void rsg_exec_succeed() { RSGExecSucceed(); }
void rsg_exec_failed() { RSGExecFailed(); }

/*
 * From the RSG, generate one random query statement.
 */
string rsg_generate(const string input_str) {
  // Convert the test string to GoString format.
  // Only supporting TypeSelect and TypeStmt.
  string res_str = "";
  int gen_trial = 0;
  const int gen_trial_max = 100;

  do {

    GoString gostr_input = {input_str.c_str(), long(input_str.size())};

    const string dbms_name = "mysql";
    GoString dbms_name_gostr = {dbms_name.c_str(), long(dbms_name.size())};

    // Actual Parsing.
    RSGQueryGenerate_return gores =
        RSGQueryGenerate(gostr_input, dbms_name_gostr);
    if (gores.r0 == NULL) {
      return "";
    }

    // Extract the parsed JSON string. Free the char array memory.
    for (int i = 0; i < gores.r1; i++) {
      res_str += gores.r0[i];
    }
    free(gores.r0);

  } while (res_str == "" && gen_trial++ < gen_trial_max);

  return res_str;
}

string rsg_generate(const IRTYPE type) {

  // Convert the test string to GoString format.
  // Only supporting TypeSelect and TypeStmt.
  string input_str = "";
  if (type == kSelectStatement) {
    input_str = "select_stmt";
  } else {
    input_str = "simple_statement";
  }

  return rsg_generate(input_str);
}
