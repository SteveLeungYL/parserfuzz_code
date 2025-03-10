#include "../include/ast.h"
#include "../include/define.h"
#include "../include/mutate.h"
#include "../include/utils.h"
#include "../oracle/cockroach_opt.h"
#include "../oracle/cockroach_oracle.h"

#include <fstream>
#include <iostream>
#include <ostream>
#include <string>
#include <utility>

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
  Modifier(Code pCode)
      : code(pCode)
  {
  }
  friend std::ostream& operator<<(std::ostream& os, const Modifier& mod)
  {
    return os << "\033[" << mod.code << "m";
  }
};
} // namespace Color

Color::Modifier RED(Color::FG_RED);
Color::Modifier DEF(Color::FG_DEFAULT);

Mutator mutator;
SQL_ORACLE* p_oracle;

inline void remove_str_bracket_space(string& parsed_str)
{
  string tmp_parsed_str;
  for (int idx = 0; idx < parsed_str.size() - 1; idx++) {
    if (parsed_str[idx] == '(' && parsed_str[idx + 1] == ' ') {
      tmp_parsed_str += "(";
      idx++;
      continue;
    } else if (parsed_str[idx] == ' ' && parsed_str[idx + 1] == ')') {
      tmp_parsed_str += ")";
      idx++;
      continue;
    } else {
      tmp_parsed_str += parsed_str[idx];
    }
  }
  tmp_parsed_str += parsed_str[parsed_str.size() - 1];
  parsed_str = tmp_parsed_str;
}

IR* test_parse(string& query, bool debug = true)
{

  vector<IR*> v_ir = mutator.parse_query_str_get_ir_set(query);
  if (v_ir.size() <= 0) {
    if (debug) {
      cerr << RED << "parse failed" << DEF << endl;
    }
    return NULL;
  }

  IR* root = v_ir.back();

  if (debug) {
    mutator.debug(root, 0);
  }

  string tostring = root->to_string();
  if (tostring.size() <= 0) {
    if (debug) {
      cerr << RED << "tostring failed" << DEF << endl;
    }
    root->deep_drop();
    return NULL;
  }
  if (debug) {
    cout << "tostring: >" << tostring << "<" << endl;
  }

  IR* root_ext_struct = root->deep_copy();
  string structure = mutator.extract_struct(root_ext_struct);
  if (structure.size() <= 0) {
    if (debug) {
      cerr << RED << "extract failed" << DEF << endl;
    }
    root->deep_drop();
    root_ext_struct->deep_drop();
    return NULL;
  }

  if (debug) {
    cout << "structur: >" << structure << "<" << endl;
  }
  root_ext_struct->deep_drop();

  IR* cur_root = root->deep_copy();
  root->deep_drop();
  return cur_root;
}

bool try_validate_query(IR* cur_root)
{
  /*
  pre_transform, post_transform and validate()
  */
  cerr << "\n\n\nRunning try_validate_query: \n\n";

  /*
  pre_transform, post_transform and validate()
  */

  mutator.pre_validate(); // Reset global variables for query sequence.

  p_oracle->init_ir_wrapper(cur_root);
  vector<IR*> all_stmt_vec = p_oracle->ir_wrapper.get_stmt_ir_vec();

  for (IR* cur_trans_stmt : all_stmt_vec) {
    mutator.reset_data_library_single_stmt();
    cerr << "\n\n\n\n\n\n\nCur stmt: " << cur_trans_stmt->to_string()
         << "\n\n\n";
    if (!mutator.validate(cur_trans_stmt, true)) { // is_debug_info == true;
      cerr << "Error: g_mutator.validate returns errors. \n\n\n";
    } else {
      cout << "Validate passing: " << cur_trans_stmt->to_string() << "\n\n\n";
    }
    //    string tmp_str = cur_trans_stmt->to_string();
    //    cur_trans_stmt = mutator.parse_query_str_get_ir_set(tmp_str).back();
    //    mutator.reset_data_library_single_stmt();
    //    if (!mutator.validate(cur_trans_stmt, true)) { // is_debug_info ==
    //    true;
    //        cerr << "Error: second time g_mutator.validate returns errors.
    //        \n\n\n";
    //    } else {
    //        cout << "Second time Validate passing: " <<
    //        cur_trans_stmt->to_string() << "\n\n\n";
    //    }
    //    mutator.rollback_instan_lib_changes();
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
  string tmp_validity = "";
  for (auto& it : validity) {
    if (it == ';') {
      tmp_validity += "; \n";
    } else {
      tmp_validity += it;
    }
  }
  validity = tmp_validity;

  cout << "validate: \n"
       << validity << "\n\n\n"
       << endl;

  cur_root->deep_drop();

  return true;
}

int main(int argc, char* argv[])
{

  if (argc != 2) {

    cout << "./test-parser sql-query-file" << endl;
    return -1;
  }

  mutator.init("");
  mutator.init_data_library();

  string input(argv[1]);
  ifstream input_test(input);
  string line;

  p_oracle = new SQL_OPT();

  mutator.set_p_oracle(p_oracle);
  p_oracle->set_mutator(&mutator);

  vector<pair<string, string>> mismatch_query_pairs;

  IR* root = NULL;

  while (getline(input_test, line)) {

    if (line.find_first_of("--") == 0)
      continue;

    trim_string(line);

    if (line.size() == 0)
      continue;

    cout << "----------------------------------------" << endl;
    cout << ">>>>>>>>>>>" << line << "<\n";

    IR* cur_root = test_parse(line);
    if (cur_root == NULL) {
      cout << "Parsing failed. Ignored. \n";
      continue;
    }

    string parsed_str = cur_root->to_string();
    trim_string(parsed_str);

    remove_str_bracket_space(line);
    remove_str_bracket_space(parsed_str);

    if (parsed_str != line) {
      mismatch_query_pairs.push_back(pair<string, string> { line, parsed_str });
    }

    if (root == NULL) {
      root = cur_root;
      // cout << "Save to root. \n\n\n";
    } else {
      IR* cur_stmt = p_oracle->ir_wrapper.get_first_stmt_from_root(cur_root);
      p_oracle->ir_wrapper.set_ir_root(root);
      p_oracle->ir_wrapper.append_stmt_at_end(cur_stmt->deep_copy());
      //       cout << "Appended stmts: \n\n\n";
      //       cout << "Cur to_string is: " << root->to_string() << "\n\n\n";
      cur_root->deep_drop();
    }
  }

  if (root == nullptr) {
    cout << "All parsing failed. Returned with NULL. \n";
    return 0;
  }

  // cout << "\n\n\n At the end of the parsing, we get to_string: \n" <<
  // root->to_string() << "\n\n\n";

  cout << "\n\n\nDebugging of the final root: \n";
  mutator.debug(root);

  mutator.init_library();

  // Ignore validation right now. Will fix later.
  try_validate_query(root);

  if (mismatch_query_pairs.size() == 0) {
    cerr << "\n\n\nNo mismatched. \n\n\n";
  }
  for (const pair<string, string>& cur_mis : mismatch_query_pairs) {
    cerr << "\n\n\nFound string mismatched: \n"
         << cur_mis.first << "\n"
         << cur_mis.second << "\n";

    // Double check whether the parsed string can pass the parser again.
    string mismatched_str = cur_mis.second;
    IR* reparsed_root = test_parse(mismatched_str, false);
    if (reparsed_root == NULL) {
      cerr << "ERROR: Reparsing failed. \n";
      continue;
    } else {
      reparsed_root->deep_drop();
    }
    cerr << "End mismatched\n\n\n";
  }

  //  // Just unit test the set statment.
  //  for (int i = 0; i < 10; i++) {
  //      // DEBUGGING.
  //      // REMOVE ME.
  //      IR* rand_set_stmt = mutator.constr_rand_set_stmt();
  //      cerr << "\nGetting random set stmt: \n" << rand_set_stmt->to_string()
  //      << "\n"; rand_set_stmt->deep_drop();
  //  }

  return 0;
}
