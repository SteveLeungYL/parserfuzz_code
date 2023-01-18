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
  RSGInitialize();
  return;
}

/*
 * From the RSG, generate one random query statement.
 */
string rsg_generate(const IRTYPE type) {

  // Convert the test string to GoString format.
  // Only supporting TypeSelect and TypeStmt.
  string input_str = "";
  if (type == TypeSelect) {
    input_str = "select_stmt";
  } else {
    input_str = "stmt";
  }

  string res_str = "";
  int gen_trial = 0;
  const int gen_trial_max = 100;

  do {

    GoString gostr_input = {input_str.c_str(), long(input_str.size())};

    // Actual Parsing.
    RSGQueryGenerate_return gores = RSGQueryGenerate(gostr_input);
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
