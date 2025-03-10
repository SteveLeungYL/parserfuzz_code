#include "../include/mutator.h"
#include "../include/utils.h"
#include "../include/ir_wrapper.h"
#include "../parser/parser_helper.h"
#include "../oracle/duckdb_oracle.h"

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
SQL_ORACLE *p_oracle;

IR *test_parse(string &query) {

  vector<IR *> v_ir = mutator.parse_query_str_get_ir_set(query);
  if (v_ir.size() <= 0) {
    cerr << RED << "parse failed" << DEF << "\n\n\n";
    return NULL;
  }

  IR *root = v_ir.back();

  mutator.debug(root, 0);

  string tostring = root->to_string();
  if (tostring.size() <= 0) {
    cerr << RED << "\n\n\ntostring failed" << DEF << "\n\n\n";
    root->deep_drop();
    return NULL;
  }
  cout << "\n\n\ntostring: >" << tostring << "<"
       << "\n\n\n";

  string structure = mutator.extract_struct(root);
  if (structure.size() <= 0) {
    cerr << RED << "extract failed" << DEF << "\n\n\n";
    root->deep_drop();
    return NULL;
  }
  cout << "structur: >" << structure << "<"
       << "\n\n\n";

  IR *cur_root = root->deep_copy();
  root->deep_drop();
  v_ir.clear();

  return cur_root;
}

bool try_validate(IR *cur_root) {
  /*
  pre_transform, post_transform and validate()
  */

  if (cur_root == NULL) {
    return false;
  }

  mutator.pre_validate(); // Reset global variables for query sequence.

  vector<IR *> all_stmt_vec = IRWrapper::get_stmt_ir_vec(cur_root);

  for (IR *cur_trans_stmt : all_stmt_vec) {
    if (!mutator.validate(cur_trans_stmt, true)) { // is_debug_info == true;
      cerr << "Error: g_mutator.validate returns errors. \n";
    }
  }

  // Clean up allocated resource.
  // post_trans_vec are being appended to the IR tree. Free up cur_root should
  // take care of them.

  string validity = cur_root->to_string();
  if (validity.size() <= 0) {
    cerr << RED << "validate failed" << DEF << endl;
    cur_root->deep_drop();
    return false;
  }
  vector<string> validity_vec = string_splitter(validity, ";");
  cout << "\n\n\nValidate string: \n";
  for (string &cur_validity : validity_vec) {
	if (cur_validity == "\n" || cur_validity.size() == 0) {
		continue;
    }
    cout << cur_validity << ";\n";
  }
  cout << "\n\n\n";

  return true;
}

int main(int argc, char *argv[]) {

  if (argc != 2) {

    cout << "./test-parser sql-query-file" << endl;
    return -1;
  }

  // hsql_debug = 1;

  string input(argv[1]);
  ifstream input_test(input);
  string line;

  p_oracle = new SQL_ORACLE();

  p_oracle->set_mutator(&mutator);

  IR *root = NULL;

  while (getline(input_test, line)) {

    if (line.find_first_of("--") == 0)
      continue;

    trim_string(line);

    if (line.size() == 0)
      continue;

    cout << "----------------------------------------" << endl;
    cout << ">>>>>>>>>>>" << line << "<\n";

    IR *cur_root = test_parse(line);

    if (root == NULL && cur_root != NULL) {
      root = cur_root;
    } else if (cur_root != NULL) {
      IR *cur_stmt =
          IRWrapper::get_stmt_ir_vec(cur_root).front()->deep_copy();
      cur_root->deep_drop();
      IRWrapper::set_ir_root(root);
      IRWrapper::append_stmt_at_end(cur_stmt);
      //      mutator.debug(root, 0);
    }
  }

  try_validate(root);

  if (root != NULL) {
      root->deep_drop();
  }

  return 0;
}
