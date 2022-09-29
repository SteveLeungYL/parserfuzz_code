#include "iostream"
#include "string"

#include "parser_helper.h"
#include "json_ir_convertor.h"

using std::string;

/*
 * Parse the query. Return SQLRight IR. 
 */
IR* raw_parser(const string input_str)
{

    // Test String
    string test_str = "CREATE TABLE v0 (v1 INT);";

    // Convert the test string to GoString format.
    GoString query_input = {input_str.c_str(), long(input_str.size())};

    // Actual Parsing. 
    ParseHelper_return gores = ParseHelper(query_input);
    if (gores.r0 == NULL) {
      cout <<  "Parse Helper return NULL. Parsing failed. \n";
    }

    // Extract the parsed JSON string. Free the char array memory. 
    string res_json_str = "";
    for (int i = 0; i < gores.r1; i++) {
        res_json_str += gores.r0[i];
    }
    free(gores.r0);

    IR* ir_root = covert_json_to_IR(res_json_str);

	return ir_root;
}

