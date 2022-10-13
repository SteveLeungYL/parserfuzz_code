#include <iostream>
#include <vector>
using namespace std;

class IR;

extern bool parse_sql(std::vector<IR*>& ir_vec);

int main() {
    vector<IR*> tmp_input;
    bool ret = parse_sql(tmp_input);
    cout << "ret: " << ret << endl;
    return 0;
}
