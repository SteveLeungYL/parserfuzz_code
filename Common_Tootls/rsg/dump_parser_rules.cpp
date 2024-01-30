#include <iostream>
#include <string>
#include "rsg_helper.h"

using namespace std;

int main(int argc, char*argv[]) {

    string dbmsNameStr;
    string fileNameStr;
    string outFileStr;
    string fuzzingModeStr;

    if (argc == 5) {
        cout << "Using DBMS format: " << argv[1] << ", parser in file: " << argv[2]
        << ",\n parser rules JSON out file: " << argv[3]
        << "\n\n\n";
        dbmsNameStr = argv[1];
        fileNameStr = argv[2];
        outFileStr = argv[3];
        fuzzingModeStr = argv[4];
    } else {
        cout << "Arg num: " << argc << ", using SQLite format, default sqlite_parse_rule_only.y file. \n\n\n";
        dbmsNameStr = "sqlite";
        fileNameStr = "sqlite_parse_rule_only.y";
        outFileStr = "parser_rules.json";
        fuzzingModeStr = "normal";
    }

    // Convert the test string to GoString format.
    GoString dbmsName = {dbmsNameStr.c_str(), long(dbmsNameStr.size())};
    GoString fileName = {fileNameStr.c_str(), long(fileNameStr.size())};
    GoString outFile = {outFileStr.c_str(), long(outFileStr.size())};
    GoString fuzzingMode = { fuzzingModeStr.c_str(), long(fuzzingModeStr.size()) };

    RSGInitialize(fileName, dbmsName, 0.5, fuzzingMode);

    RSGDumpParserRuleMap(outFile);

    return 0;
}
