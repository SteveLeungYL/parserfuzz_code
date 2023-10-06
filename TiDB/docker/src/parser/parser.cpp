#include "iostream"
#include "string"

#include "../include/json_ir_convertor.h"
#include "parser_helper.h"

using std::string;

/*
 * Parse the query. Return SQLRight IR.
 */
IR* raw_parser(const string input_str)
{

#ifdef DEBUG
  cerr << "Debug: Parsing file: " << input_str << "\n\n\n";
#endif

  // Convert the test string to GoString format.
  GoString query_input = { input_str.c_str(), long(input_str.size()) };

  // Actual Parsing.
  ParseHelper_return gores = ParseHelper(query_input);
  if (gores.r0 == NULL) {
    // cout <<  "Parse Helper return NULL. Parsing failed. \n";
    return NULL;
  }
  //  else if (gores.r1 > 20000) {
  //      // cout <<  "Parse Helper return NULL because the parsed json string is too large. \n";
  //      free(gores.r0);
  //      return NULL;
  //  }

  // Extract the parsed JSON string. Free the char array memory.
  string res_json_str = "";
  for (int i = 0; i < gores.r1; i++) {
    res_json_str += gores.r0[i];
  }
  free(gores.r0);

  // std::cout << "Getting json string: \n" << res_json_str << "\n\n";
  IR *ir_root = convert_json_to_IR(res_json_str, input_str);

  return ir_root;
}
