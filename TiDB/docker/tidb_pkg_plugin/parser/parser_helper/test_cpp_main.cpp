#include <iostream>
#include <string>
#include "parser_helper.h"

using namespace std;

int main() {
    // Test String
    string test_str = "CREATE TABLE v0 (v1 INT);";

    // Convert the test string to GoString format.
    GoString query_input = {test_str.c_str(), long(test_str.size())};

    auto gores = ParseHelper(query_input);

    if (gores.r0 == NULL) {
      cout <<  "ParseHelper return NULL. Parsing failed. \n";
    }

    string res_str = "";
    for (int i = 0; i < gores.r1; i++) {
        res_str += gores.r0[i];
    }

    free(gores.r0);

    cout << "In c++ code: returned \n" << res_str << endl;
    return 0;
}
