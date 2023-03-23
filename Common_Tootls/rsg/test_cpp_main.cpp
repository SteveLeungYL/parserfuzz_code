#include <iostream>
#include <string>
#include "cstdlib"
#include "rsg_helper.h"

using namespace std;

int main(int argc, char*argv[]) {

    string dbmsNameStr;
    string fileNameStr;
    string genType;

    if (argc == 4) {
        cout << "Using DBMS format: " << argv[1] << ", file: " << argv[2]
        << ", target type: " << argv[3]
        << "\n\n\n";
        dbmsNameStr = argv[1];
        fileNameStr = argv[2];
        genType= argv[3];
    } else {
        cout << "Arg num: " << argc << ", using SQLite format, default sqlite_parse_rule_only.y file. \n\n\n";
        dbmsNameStr = "sqlite";
        fileNameStr = "sqlite_parse_rule_only.y";
        genType= "select";
    }

    // Convert the test string to GoString format.
    GoString genTypeInput = {genType.c_str(), long(genType.size())};
    GoString dbmsName = {dbmsNameStr.c_str(), long(dbmsNameStr.size())};
    GoString fileName = {fileNameStr.c_str(), long(fileNameStr.size())};

    RSGInitialize(fileName, dbmsName, 0.3);

    for (int i = 0; i < 100; i++) {

      auto gores = RSGQueryGenerate(genTypeInput, dbmsName);

      if (gores.r0 == NULL || gores.r1 == 0) {
        cerr <<  "RSG Generate function returns NULL. RSG generation failed. \n";
        continue;
      }

      string res_str = "";
      res_str.reserve(gores.r1+1);
      for (int i = 0; i < gores.r1; i++) {
          res_str += gores.r0[i];
      }

      free(gores.r0);

      if (rand() % 2) {
          RSGExecSucceed();
      } else {
          RSGExecFailed();
      }

      cerr << "In c++ code: generated idx: " << i << ": \n" << res_str << "\n\n\n";

    }
    return 0;
}
