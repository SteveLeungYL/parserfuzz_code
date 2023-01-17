//
// Created by Yu Liang on 12/8/22.
//
#include "../include/ast.h"
#include "../include/define.h"
#include "../include/mutate.h"
#include "../include/utils.h"
#include "../oracle/cockroach_opt.h"
#include "../oracle/cockroach_oracle.h"

#include "../rsg/rsg.h"
#include "../rsg/rsg_helper.h"

#include <fstream>
#include <iostream>
#include <ostream>
#include <string>
#include <utility>

using namespace std;

Mutator g_mutator;
SQL_ORACLE *p_oracle;

bool unit_test_rsg_behavior(bool is_debug_info) {

    int total_succeed = 0, total_exec = 0;

    rsg_initialize();

    for (int i = 0; i < 100; i++) {
        total_exec++;
        
        string tmp_query_str = rsg_generate();    
        if (is_debug_info) {
            cerr << "Getting origin query str: " << tmp_query_str << "\n";
        }
        vector<IR*> ir_vec = g_mutator.parse_query_str_get_ir_set(tmp_query_str);

        if(ir_vec.size() == 0) {
            if (is_debug_info) {
                cerr << "Parsing failed\n\n\n";
            }
        } else {
            total_succeed++;
            if (is_debug_info) {
                cerr << "Parsing succeed, getting: " << ir_vec.back()->to_string() << "\n\n\n" ;
            }
            ir_vec.back()->deep_drop();
        }
        if (is_debug_info) {
            cerr << "\n\n\nGetting total_succeed / total_exec: " << total_succeed << " / " << total_exec << "\n\n\n";
        }
    }

    if (is_debug_info) {
        cerr << "\n\n\nGetting total_succeed / total_exec: " << total_succeed << " / " << total_exec << "\n\n\n";
    }

    return true;

}

int main(int argc, char *argv[]) {

  if (argc != 1) {
    cout << "./rsg-unit-test" << endl;
    return -1;
  }

  g_mutator.init("");
  g_mutator.init_data_library();

  p_oracle = new SQL_OPT();

  g_mutator.set_p_oracle(p_oracle);
  p_oracle->set_mutator(&g_mutator);
  p_oracle->init_operator_supported_types();

  assert(unit_test_rsg_behavior(true));

  return 0;
}
