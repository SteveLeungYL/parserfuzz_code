#include <iostream>
#include <vector>
#include <string>
#include <fstream>
#include <streambuf>

#include "sql_ir_define.h"
using namespace std;

extern bool parse_sql(string query_str, std::vector<IR*>& ir_vec);
extern bool init_SQLRight_parser();

int main() {
    vector<IR*> tmp_input;
    std::ifstream t("input_query.sql");
    std::string test_query;

    t.seekg(0, std::ios::end);   
    test_query.reserve(t.tellg());
    t.seekg(0, std::ios::beg);

    test_query.assign((std::istreambuf_iterator<char>(t)),
                std::istreambuf_iterator<char>());
    
    init_SQLRight_parser();

    int ret = 0;
    while (true) {
	    ret = parse_sql(test_query, tmp_input);
	    string a = tmp_input.front()->to_string();
	    cout << "ret: " << ret << ", to_string: " << a << endl;
	    tmp_input.front()->deep_drop();
	    tmp_input.clear();
        break;
    }
    return 0;
}
