#include "../include/ast.h"
#include "../include/define.h"
#include "../include/mutator.h"
#include "../include/utils.h"
#include "../oracle/sqlite_oracle.h"
#include "../oracle/sqlite_norec.h"

#include <fstream>
#include <iostream>
#include <ostream>
#include <string>

// extern int hsql_debug;

using namespace std;

namespace Color {
enum Code {
  FG_RED = 31,
  FG_GREEN = 32,
  FG_BLUE = 34,
  FG_DEFAULT = 39,
  BG_RED = 41,
  BG_GREEN = 42,
  BG_BLUE = 44,
  BG_DEFAULT = 49
};
class Modifier {
  Code code;

public:
  Modifier(Code pCode) : code(pCode) {}
  friend std::ostream &operator<<(std::ostream &os, const Modifier &mod) {
    return os << "\033[" << mod.code << "m";
  }
};
} // namespace Color

Color::Modifier RED(Color::FG_RED);
Color::Modifier DEF(Color::FG_DEFAULT);

Mutator mutator;
SQL_ORACLE* p_oracle;

bool test_parse(string &query) {

  vector<IR *> v_ir = mutator.parse_query_str_get_ir_set(query);
  if (v_ir.size() <= 0) {
    cerr << RED << "parse failed" << DEF << endl;
    return false;
  }

  IR *root = v_ir.back();

  mutator.debug(root, 0);

  string tostring = root->to_string();
  if (tostring.size() <= 0) {
    cerr << RED << "tostring failed" << DEF << endl;
    root->deep_drop();
    return false;
  }
  cout << "tostring: >" << tostring << "<" << endl;

  string structure = mutator.extract_struct(root);
  if (structure.size() <= 0) {
    cerr << RED << "extract failed" << DEF << endl;
    root->deep_drop();
    return false;
  }
  cout << "structur: >" << structure << "<" << endl;

  /* 
  pre_transform, post_transform and validate()
  */
  IR* cur_root = root->deep_copy();

  mutator.pre_validate(); // Reset global variables for query sequence. 

  p_oracle->init_ir_wrapper(cur_root);
  vector<IR*> all_stmt_vec = p_oracle->ir_wrapper.get_stmt_ir_vec();

  for (IR* cur_trans_stmt : all_stmt_vec) {
    if(!mutator.validate(cur_trans_stmt)) {
      cerr << "Error: g_mutator.validate returns errors. \n";
    }
  }

  // Clean up allocated resource. 
  // post_trans_vec are being appended to the IR tree. Free up cur_root should take care of them.

  string validity = cur_root->to_string();
  if (validity.size() <= 0) {
    cerr << RED << "validate failed" << DEF << endl;
    root->deep_drop();
    cur_root->deep_drop();
    return false;
  }
  cout << "validate: >" << validity << "<" << endl;

  root->deep_drop();
  cur_root->deep_drop();
  v_ir.clear();

  return true;
}

int main(int argc, char *argv[]) {

  if (argc != 2) {

    cout << "./test-parser sql-query-file" << endl;
    return -1;
  }

  // hsql_debug = 1;

  mutator.init("");

  string input(argv[1]);
  ifstream input_test(input);
  string line;

  p_oracle = new SQL_NOREC();

  mutator.set_p_oracle(p_oracle);
  p_oracle->set_mutator(&mutator);

  while (getline(input_test, line)) {

    if (line.find_first_of("--") == 0)
      continue;

    trim_string(line);

    if (line.size() == 0)
      continue;

    cout << "----------------------------------------" << endl;
    cout << ">>>>>>>>>>>" << line << "<\n";

    bool is_valid = test_parse(line);

    if (!is_valid)
      continue;
  }

  return 0;
}
