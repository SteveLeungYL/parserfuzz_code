#include "rsg.h"
#include "rsg_helper.h"

#include <string>

using std::string;

/*
 * Initialize the RSG structure.
 */

void rsg_initialize() {

  const string parser_file_str = "./sqlite_parse_rule_only.y";
  GoString parser_file_gostr = {parser_file_str.c_str(), long(parser_file_str.size())};

  const string dbms_name = "sqlite";
  GoString dbms_name_gostr = {dbms_name.c_str(), long(dbms_name.size())};

  RSGInitialize(parser_file_gostr, dbms_name_gostr, 0.5);
  return;
}

/*
 * From the RSG, generate one random query statement.
 */
string rsg_generate(const IRTYPE type) {

  // Convert the test string to GoString format.
  // Only supporting TypeSelect and TypeStmt.
  string input_str = "";
  if (type == kSelectStatement) {
    input_str = "select";
  } else {
    input_str = "cmd";
  }

  string res_str = "";
  int gen_trial = 0;
  const int gen_trial_max = 100;

  do {

    GoString gostr_input = {input_str.c_str(), long(input_str.size())};

    const string dbms_name = "sqlite";
    GoString dbms_name_gostr = {dbms_name.c_str(), long(dbms_name.size())};

    // Actual Parsing.
    RSGQueryGenerate_return gores = RSGQueryGenerate(gostr_input, dbms_name_gostr);
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

