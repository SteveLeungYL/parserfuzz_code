#include "../include/ast.h"
#include "../include/mutator.h"
#include "../include/define.h"
#include "../include/utils.h"

#include <iostream>
#include <fstream>
#include <string>

using namespace std;

int main(int argc, char *argv[]) {

  if (argc != 2) {

    cout << "./test-parser sql-query-file" << endl;
    return -1;
  }

  Mutator mutator;

  string input(argv[1]);
  ifstream input_test(input);
  string line;

  while(getline(input_test, line)) {

    cout << "----------------------------------------" << endl;

      vector<IR *> v_ir = mutator.parse_query_str_get_ir_set(line);
    if (v_ir.size() <= 0) {
      cerr << "failed to parse: " << line << endl;
      continue;
    }

    IR *root = v_ir.back();

    cout << line << endl;
    cout << root->to_string() << endl;
    cout << mutator.extract_struct(line) << endl;

    root->deep_drop();

  }

  return 0;
}
