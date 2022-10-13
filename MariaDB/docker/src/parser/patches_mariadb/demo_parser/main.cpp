#include <iostream>
#include <vector>
#include "sql_ir_define.h"
using namespace std;

extern bool parse_sql(std::vector<IR*>& ir_vec);

int main() {
    vector<IR*> tmp_input;
    bool ret = parse_sql(tmp_input);
    string a = tmp_input.front()->to_string();
    cout << "ret: " << ret << ", to_string: " << a << endl;
    return 0;
}
