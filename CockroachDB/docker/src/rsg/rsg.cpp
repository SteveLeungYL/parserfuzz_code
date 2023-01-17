#include <string>
#include <cstdlib>

#include "rsg_helper.h"
#include "../include/ast.h"

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

  // TODO:: FOR DEBUGGING purpose.
  string input_str = "select_stmt";
  GoString gostr_input = {input_str.c_str(), long(input_str.size())};

  // Actual Parsing.
  RSGQueryGenerate_return gores = RSGQueryGenerate(gostr_input);
  if (gores.r0 == NULL) {
    return "";
  }

  // Extract the parsed JSON string. Free the char array memory.
  string res_str = "";
  for (int i = 0; i < gores.r1; i++) {
    res_str += gores.r0[i];
  }
  free(gores.r0);

  return res_str;
}
