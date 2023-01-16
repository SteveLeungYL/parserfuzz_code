#include <string>
#include <cstdlib>

#include "rsg_helper.h"
#include "rsg.h"
#include "../include/ast.h"

using std::string;

/*
 * From the RSG, generate one random query statement.
 */
string rsg_generate(const IRTYPE type) {

  // Convert the test string to GoString format.

  // TODO:: FOR DEBUGGING purpose.
  string input_str = "select_stmt";
  GoString gostr_input = {input_str.c_str(), long(input_str.size())};

  // Actual Parsing.
  Generate_return gores = Generate(gostr_input);
  if (gores.r0 == NULL) {
    return NULL;
  }

  // Extract the parsed JSON string. Free the char array memory.
  string res_str = "";
  for (int i = 0; i < gores.r1; i++) {
    res_str += gores.r0[i];
  }
  free(gores.r0);

  return res_str;
}
