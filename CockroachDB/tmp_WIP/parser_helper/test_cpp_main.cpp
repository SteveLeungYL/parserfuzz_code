#include <iostream>
#include <string>
#include "test.h"

using namespace std;

int main() {
    string test_str = "CREATE TABLE v0 (v1 INT);";
    GoString tmp_gostr = {test_str.c_str(), test_str.size()};
    auto res_gostr = ParseHelper(tmp_gostr);
    string res_str = "";
    for (int i = 0; i < res_gostr.n; i++) {
        res_str += res_gostr.p[i];
    }
    cout << res_str << endl;
    return 0;
}
