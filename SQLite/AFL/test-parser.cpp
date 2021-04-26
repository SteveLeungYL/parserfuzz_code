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
  mutator.init("");

  string input(argv[1]);
  ifstream input_test(input);
  string line;

  while(getline(input_test, line)) {

    if (line.find_first_of("--") == 0) continue;

    cout << "----------------------------------------" << endl;

    vector<IR *> v_ir = mutator.parse_query_str_get_ir_set(line);
    if (v_ir.size() <= 0) {
      cerr << "failed to parse: " << line << endl;
      continue;
    }

    IR *root = v_ir.back();

    string tostring = root->to_string();
    string structure = mutator.extract_struct(line);

    cout << line << endl;
    cout << tostring << endl;
    cout << structure << endl;

    root->deep_drop();
    v_ir.clear();

    v_ir = mutator.parse_query_str_get_ir_set(structure);
    if (v_ir.size() <= 0) {
      cerr << "failed to paser the extracted structure" << endl;
      continue;
    }

    root = v_ir.back();
    if (root->to_string() != structure) {
      cerr << "extract_structure is no idempotent" << endl;
      continue;
    }

    string validity = mutator.validate(root);
    cout << validity << endl;

    root->deep_drop();
  }

  return 0;
}
