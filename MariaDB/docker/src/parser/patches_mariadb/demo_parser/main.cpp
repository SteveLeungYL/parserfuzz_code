#include <iostream>
#include <vector>
#include <string>
#include "sql_ir_define.h"
using namespace std;

extern bool parse_sql(string query_str, std::vector<IR*>& ir_vec);

int main() {
    vector<IR*> tmp_input;
    string test_query = "SELECT 'abc';";
    bool ret = parse_sql(test_query, tmp_input);
    string a = tmp_input.front()->to_string();
    cout << "ret: " << ret << ", to_string: " << a << endl;
    return 0;
}
