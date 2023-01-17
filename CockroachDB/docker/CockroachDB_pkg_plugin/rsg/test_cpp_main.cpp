#include <iostream>
#include <string>
#include "rsg_helper.h"

using namespace std;

int main() {
    // Randomly generated statement type. 
    string genType= "select_stmt";

    // Convert the test string to GoString format.
    GoString genTypeInput = {genType.c_str(), long(genType.size())};

    RSGInitialize();

    auto gores = RSGQueryGenerate(genTypeInput);

    if (gores.r0 == NULL || gores.r1 == 0) {
      cout <<  "RSG Generate function returns NULL. RSG generation failed. \n";
    }

    string res_str = "";
    res_str.reserve(gores.r1+1);
    for (int i = 0; i < gores.r1; i++) {
        res_str += gores.r0[i];
    }

    free(gores.r0);

    cout << "In c++ code: generated \n" << res_str << "\n\n\n";
    return 0;
}
