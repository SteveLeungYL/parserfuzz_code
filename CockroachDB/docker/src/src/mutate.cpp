#include "../include/mutate.h"
#include "../include/json_ir_convertor.h"
#include "../oracle/cockroach_oracle.h"
#include "../parser/parser.h"

#include <algorithm>
#include <assert.h>
#include <cfloat>
#include <climits>
#include <cstdio>
#include <deque>
#include <fstream>
#include <iostream>
#include <list>
#include <sstream>
#include <string>

#define _NON_REPLACE_

using namespace std;

#define find_vector(x, y) (find(x.begin(), x.end(), y) != x.end())
#define remove_vector(x, y) (x.erase(std::remove(x.begin(), \
                             x.end(), y),\
                             x.end()));
#define find_map(x, y) (x.count(y) > 0)
#define remove_map(x, y) (x.erase(y))

set<IR *>
    Mutator::visited; // Already validated/fixed node. Avoid multiple fixing.
map<string, vector<string>>
    Mutator::m_table2columns; // Table name to column name mapping.
map<string, vector<string>>
    Mutator::m_table2index;                    // Table name to index mapping.
vector<string> Mutator::v_table_names;         // All saved table names
vector<string> Mutator::v_table_names_single;  // All used table names in one
                                               // query statement.
vector<string> Mutator::v_column_names_single; // All used table names in one
// query statement.
vector<string>
    Mutator::v_create_table_names_single; // All table names just created in the
                                          // current stmt. Will clean up after
                                          // solving the current statement.
vector<string>
    Mutator::v_create_view_names_single; // All names just created in the
                                         // current stmt. Will clean up after
                                         // solving the current statement.

// All alias name local to one query statement.
// Can be used for quick alias name random referencing.
// Clean up after every single query statement.
vector<string> Mutator::v_table_alias_names_single;
vector<string> Mutator::v_column_alias_names_single;

map<string, string> Mutator::m_alias2table_single; // table alias to original
                                                   // table name mapping.
map<string, vector<string>> Mutator::m_enforced_table2alias_single; // All table alias that is NOT
                                                            // in the WITH clause.
map<string, string>
    Mutator::m_alias2column_single; // column name to alias mapping.
/* A mapping that defines an aliased table name to its resulting column name. */
map<string, vector<string>> Mutator::m_alias_table2column_single;

map<string, DataAffinity> Mutator::m_column2datatype; // New solution.
map<DATAAFFINITYTYPE, vector<string>>
    Mutator::m_datatype2column; // New solution.

map<DATAAFFINITYTYPE, vector<string>> Mutator::m_datatype2literals;

vector<string> Mutator::v_statistics_name; // All statistic names defined in the
                                           // current stmt.

// Views should share the same handling as Tables
vector<string> Mutator::v_view_name; // All saved view names.
// The column to view mapping will be saved into the m_table2columns mapping.

vector<string>
    Mutator::v_sequence_name; // All sequence names defined in the current SQL.
vector<string> Mutator::v_constraint_name;    // All constraint names defined in
                                              // the current SQL.
vector<string> Mutator::v_family_name;        // All family names defined in
                                              // the current SQL.
vector<string> Mutator::v_foreign_table_name; // All foreign table names defined
                                              // in the current SQL.
// vector<string>
//    Mutator::v_create_foreign_table_names_single; // All foreign table names
//                                                  // created in the current
//                                                  single SQL statement.

vector<string> Mutator::v_sys_column_name;
vector<string> Mutator::v_sys_catalogs_name;

vector<string> Mutator::v_table_with_partition;
map<string, vector<string>> Mutator::m_table2partition;

map<string, DataAffinity> Mutator::set_session_lib;
vector<string> Mutator::all_saved_set_session;

map<string, DataAffinity> Mutator::storage_param_lib;
vector<string> Mutator::all_storage_param;

vector<int> Mutator::v_int_literals;
vector<double> Mutator::v_float_literals;
vector<string> Mutator::v_string_literals;

//#define GRAPHLOG

IR *Mutator::deep_copy_with_record(const IR *root, const IR *record) {
  IR *left = NULL, *right = NULL, *copy_res;

  if (root->left_)
    left = deep_copy_with_record(root->left_, record);
  if (root->right_)
    right = deep_copy_with_record(root->right_, record);

  if (root->op_)
    copy_res =
        new IR(root->type_,
               OP3(root->op_->prefix_, root->op_->middle_, root->op_->suffix_),
               left, right, root->float_val_, root->str_val_, root->name_,
               root->mutated_times_, root->data_flag_);
  else
    copy_res =
        new IR(root->type_, NULL, left, right, root->float_val_, root->str_val_,
               root->name_, root->mutated_times_, root->data_flag_);

  copy_res->data_type_ = root->data_type_;

  if (root == record && record != NULL) {
    this->record_ = copy_res;
  }

  return copy_res;
}

vector<IR *> Mutator::mutate_stmtlist(IR *root) {
  IR *cur_root = nullptr;
  vector<IR *> res_vec;

  if (root == nullptr) {
    return res_vec;
  }

  // For strategy_delete
  cur_root = root->deep_copy();
  p_oracle->ir_wrapper.set_ir_root(cur_root);

  int rov_idx = get_rand_int(p_oracle->ir_wrapper.get_stmt_num());
  p_oracle->ir_wrapper.remove_stmt_at_idx_and_free(rov_idx);
  res_vec.push_back(cur_root);

  // STMTLIST_INSERT:
  cur_root = root->deep_copy();
  p_oracle->ir_wrapper.set_ir_root(cur_root);

  int insert_pos = get_rand_int(p_oracle->ir_wrapper.get_stmt_num());

  /* Get new insert statement. However, do not insert kSelectStatement */
  IR *new_stmt_ir = NULL;
  while (new_stmt_ir == NULL) {
    new_stmt_ir = get_from_libary_with_type(TypeStmt);
    if (new_stmt_ir == nullptr || new_stmt_ir->left_ == nullptr) {
      // cerr << "kStmt is empty;\n\n\n";
      cur_root->deep_drop();
      return res_vec;
    }
    if (new_stmt_ir->get_left()->get_ir_type() == TypeSelect) {
      new_stmt_ir->deep_drop();
      new_stmt_ir = NULL;
    }
    continue;
  }
  IR *new_stmt_ir_tmp =
      new_stmt_ir->left_->deep_copy(); // kStatement -> specific_stmt_type
  new_stmt_ir->deep_drop();
  new_stmt_ir = new_stmt_ir_tmp;

  // cerr << "Inserting stmt: " << new_stmt_ir->to_string() << "\n\n\n";

  p_oracle->ir_wrapper.set_ir_root(cur_root);
  if (!p_oracle->ir_wrapper.append_stmt_at_idx(new_stmt_ir, insert_pos)) {
    new_stmt_ir->deep_drop();
    cur_root->deep_drop();
    return res_vec;
  }
  res_vec.push_back(cur_root);

  return res_vec;
}

vector<IR *> Mutator::mutate_all(IR *ori_ir_root, IR *ir_to_mutate,
                                 u64 &total_mutate_failed,
                                 u64 &total_mutate_num) {

  IR *root = ori_ir_root;
  vector<IR *> res;
  vector<IR *> v_mutated_ir;

  // debug(ori_ir_root, 0);

  // cerr << "Inside mutate_all; \n\n\n";

  if (ir_to_mutate->get_ir_type() == TypeRoot)
    return res;

  /* For mutating kStmtList only */
  if (ir_to_mutate->get_ir_type() == TypeStmtList) {
    // cerr << "Inside kStmtList; \n\n\n";
    v_mutated_ir = mutate_stmtlist(root);
    // cerr << "Mutating stmt_list, getting size: " << v_mutated_ir.size() <<
    // "\n\n\n";
    for (IR *mutated_ir : v_mutated_ir) {

      string tmp = mutated_ir->to_string();

      unsigned tmp_hash = hash(tmp);
      if (global_hash_.find(tmp_hash) != global_hash_.end()) {
        mutated_ir->deep_drop();
        // cerr << "Aboard old_ir because tmp_hash being saved before. "
        //      << "In func: Mutator::mutate_all(); \n";
        continue;
      }
      // cerr << "Currently mutating (stmtlist). After mutation, the generated
      // str is: " << mutated_ir->to_string() << "\n\n\n";
      global_hash_.insert(tmp_hash);
      res.push_back(mutated_ir);
    }

    return res;
  }

  // cerr << "Inside rest; \n\n\n";
  // else, for mutating single IR node.

  v_mutated_ir = mutate(ir_to_mutate);

  for (IR *new_ir : v_mutated_ir) {
    total_mutate_num++;
    if (!root->swap_node(ir_to_mutate, new_ir)) {
      new_ir->deep_drop();
      total_mutate_failed++;
      continue;
    }

    string tmp = root->to_string();

    /* Check whether the mutated IR is the same as before */
    unsigned tmp_hash = hash(tmp);
    if (global_hash_.find(tmp_hash) != global_hash_.end()) {
      root->swap_node(new_ir, ir_to_mutate);
      new_ir->deep_drop();
      total_mutate_failed++;
      continue;
    }
    global_hash_.insert(tmp_hash);

    /* Mutate successful. Save the mutation and recover the original ir_tree */
    res.push_back(root->deep_copy());
    root->swap_node(new_ir, ir_to_mutate);
    new_ir->deep_drop();
  }

  return res;
}

void Mutator::add_ir_to_library(IR *cur) {
  extract_struct(cur);
  cur = deep_copy(cur);
  add_ir_to_library_no_deepcopy(cur);
  return;
}

void Mutator::add_ir_to_library_no_deepcopy(IR *cur) {
  if (cur->left_)
    add_ir_to_library_no_deepcopy(cur->left_);
  if (cur->right_)
    add_ir_to_library_no_deepcopy(cur->right_);

  auto type = cur->type_;
  auto h = hash(cur);
  if (find(ir_library_hash_[type].begin(), ir_library_hash_[type].end(), h) !=
      ir_library_hash_[type].end())
    return;

  ir_library_hash_[type].insert(h);
  ir_library_[type].push_back(cur);

  return;
}

void Mutator::init_common_string(string filename) {
  common_string_library_.push_back("DO_NOT_BE_EMPTY");
  if (filename != "") {
    ifstream input_string(filename);
    string s;

    while (getline(input_string, s)) {
      common_string_library_.push_back(s);
    }
  }
}

void Mutator::init_sql_type_alias_2_type() {
  if (sql_type_alias_2_type.size()) {
    return;
  }

  sql_type_alias_2_type["AFFIVARCHAR"] = "AFFISTRING";
  sql_type_alias_2_type["AFFICHAR"] = "AFFISTRING";
  sql_type_alias_2_type["CHARACTER"] = "AFFISTRING";
  sql_type_alias_2_type["AFFITEXT"] = "AFFISTRING";
  sql_type_alias_2_type["AFFICHARACTER VARYING"] = "AFFISTRING";

  sql_type_alias_2_type["AFFIVARBIT"] = "AFFIBIT";

  sql_type_alias_2_type["AFFIBYTEA"] = "AFFIBYTES";
  sql_type_alias_2_type["AFFIBLOB"] = "AFFIBYTES";

  sql_type_alias_2_type["AFFIDEC"] = "AFFIDECIMAL";
  sql_type_alias_2_type["AFFINUMERIC"] = "AFFIDECIMAL";

  sql_type_alias_2_type["AFFINUMERIC"] = "AFFIFLOAT";
  sql_type_alias_2_type["AFFIFLOAT4"] = "AFFIFLOAT";
  sql_type_alias_2_type["AFFIFLOAT8"] = "AFFIFLOAT";
  sql_type_alias_2_type["AFFIREAL"] = "AFFIFLOAT";
  sql_type_alias_2_type["AFFIDOUBLE PRECISION"] = "AFFIFLOAT";

  sql_type_alias_2_type["AFFIINT2"] = "AFFIINT";
  sql_type_alias_2_type["AFFIINT4"] = "AFFIINT";
  sql_type_alias_2_type["AFFIINT8"] = "AFFIINT";

  sql_type_alias_2_type["AFFIJSON"] = "AFFIJSONB";

  sql_type_alias_2_type["AFFITIME WITHOUT TIME ZONE"] = "AFFITIME";

  sql_type_alias_2_type["AFFITIME WITH TIME ZONE"] = "AFFITIMETZ";

  sql_type_alias_2_type["AFFITIMESTAMP WITHOUT TIME ZONE"] = "AFFITIME";
  sql_type_alias_2_type["AFFITIMESTAMP WITH TIME ZONE"] = "AFFITIMETZ";
}

void Mutator::init_data_library() {

  this->init_sql_type_alias_2_type();

  string func_file_name = FUNCTION_TYPE_PATH;

  ifstream input_file(func_file_name);
  string s;

  cout << "[*] begin init function_types library: " << func_file_name << endl;

  string function_types_path = FUNCTION_TYPE_PATH;
  std::stringstream buffer_func_types;
  buffer_func_types << input_file.rdbuf();
  string func_types_str = buffer_func_types.str();

  //  while (getline(input_file, s)) {
  //    auto pos = s.find(" ");
  //    if (pos == string::npos)
  //      continue;
  //    auto func_type = get_functype_by_string(s.substr(0, pos));
  //    auto v = s.substr(pos + 1, s.size() - pos - 1);
  //
  //    func_type_lib[func_type].push_back(v);
  //    func_str_to_type_map[v] = func_type;
  //  }
  constr_sql_func_lib(func_types_str, all_saved_func_name, func_type_lib,
                      func_str_to_type_map);
  cout << "[*] Getting all_saved_func_name.size(): "
       << this->all_saved_func_name.size() << endl;

  input_file.close();
  cout << "[*] end init function_types library: " << func_file_name << endl;

  string set_session_path = SET_SESSION_PATH;
  cout << "[*] begin init set session path library: " << set_session_path
       << endl;

  input_file.open(set_session_path);

  std::stringstream buffer_set_session;
  buffer_set_session << input_file.rdbuf();
  string set_session_json = buffer_set_session.str();

  constr_key_pair_datatype_lib(set_session_json, this->all_saved_set_session,
                               this->set_session_lib);
  input_file.close();
  buffer_set_session.clear();
  cout << "[*] Getting all_saved_set_session.size(): "
       << this->all_saved_set_session.size() << endl;
  cout << "[*] end init set session path library: " << set_session_path << endl;

  string storage_parameter_path = STORAGE_PARAM_PATH;
  cout << "[*] begin init storage parameter library: " << storage_parameter_path
       << endl;

  std::stringstream buffer_storage_param;
  input_file.open(storage_parameter_path);
  buffer_storage_param << input_file.rdbuf();
  string storage_param_str = buffer_storage_param.str();

  constr_key_pair_datatype_lib(storage_param_str, this->all_storage_param,
                               this->storage_param_lib);
  input_file.close();
  cerr << "[*] Getting all_storage_param.size(): "
       << this->all_storage_param.size() << endl;
  cout << "[*] end init storage parameter library: " << storage_parameter_path
       << endl;

  return;
}

inline void Mutator::init_value_library() {
  if (value_library_.size() != 0) {
    return;
  }
  vector<unsigned long> value_lib_init = {0,
                                          (unsigned long)LONG_MAX,
                                          (unsigned long)ULONG_MAX,
                                          (unsigned long)CHAR_BIT,
                                          (unsigned long)SCHAR_MIN,
                                          (unsigned long)SCHAR_MAX,
                                          (unsigned long)UCHAR_MAX,
                                          (unsigned long)CHAR_MIN,
                                          (unsigned long)CHAR_MAX,
                                          (unsigned long)MB_LEN_MAX,
                                          (unsigned long)SHRT_MIN,
                                          (unsigned long)INT_MIN,
                                          (unsigned long)INT_MAX,
                                          (unsigned long)SCHAR_MIN,
                                          (unsigned long)SCHAR_MIN,
                                          (unsigned long)UINT_MAX,
                                          (unsigned long)FLT_MAX,
                                          (unsigned long)DBL_MAX,
                                          (unsigned long)LDBL_MAX,
                                          (unsigned long)FLT_MIN,
                                          (unsigned long)DBL_MIN,
                                          (unsigned long)LDBL_MIN};

  value_library_.insert(value_library_.begin(), value_lib_init.begin(),
                        value_lib_init.end());

  return;
}

void Mutator::init_ir_library(string filename) {
  ifstream input_file(filename);
  string line;

  cout << "[*] init ir_library: " << filename << endl;
  while (getline(input_file, line)) {
    if (line.empty())
      continue;

    IR *res = raw_parser(line); // RAW_PARSE_DEFAULT = 0
    if (res == NULL) {
      continue;
    }

    add_ir_to_library(res);
    deep_delete(res);
  }
  return;
}

void Mutator::init_library() {

  // init value_library_
  init_value_library();

  if (not_mutatable_types_.size() == 0) {
    float_types_.insert({TypeFloatLiteral});
    int_types_.insert(TypeIntegerLiteral);
    string_types_.insert(TypeStringLiteral);

    split_stmt_types_.insert(TypeStmt);
    split_substmt_types_.insert({TypeSelect});

    not_mutatable_types_.insert({TypeRoot, TypeStmtList, TypeStmt});

    // Initialize the common_string_library();
    common_string_library_.push_back("HELLO");
    common_string_library_.push_back("WORLD");
    common_string_library_.push_back("test");
    common_string_library_.push_back("files");
    common_string_library_.push_back("music");
    common_string_library_.push_back("score");
    common_string_library_.push_back("green");
    common_string_library_.push_back("red");
    common_string_library_.push_back("right");
    common_string_library_.push_back("left");
    common_string_library_.push_back("plot");
    common_string_library_.push_back("cov");
    common_string_library_.push_back("bug");
    common_string_library_.push_back("sample");

    /* Added default column type for Postgres */
    this->v_sys_column_name.push_back("oid");
    this->v_sys_column_name.push_back("tableoid");
    this->v_sys_column_name.push_back("xmin");
    this->v_sys_column_name.push_back("cmin");
    this->v_sys_column_name.push_back("xmax");
    this->v_sys_column_name.push_back("cmax");
    this->v_sys_column_name.push_back("ctid");
  }
}

void Mutator::init(string f_testcase, string f_common_string, string file2d,
                   string file1d, string f_gen_type) {

  // if (!f_testcase.empty());
  //   init_ir_library(f_testcase);

  /* init common_string_library */
  if (!f_common_string.empty()) {
    init_common_string(f_common_string);
  }

  // init data_library_2d
  // if (!file2d.empty())
  //   init_data_library_2d(file2d);

  // if (!file1d.empty())
  //   init_data_library(file1d);
  // if (!f_gen_type.empty())
  //   init_safe_generate_type(f_gen_type);

  ifstream input_test(f_testcase);
  string line;

  // init lib from multiple sql
  while (getline(input_test, line)) {

    // cerr << "Parsing init line: " << line << "\n";

    vector<IR *> v_ir = parse_query_str_get_ir_set(line);
    if (v_ir.size() <= 0) {
//      cerr << "failed to parse: " << line << endl;
      continue;
    }

    IR *v_ir_root = v_ir.back();
    string strip_sql = extract_struct(v_ir_root);
    v_ir.back()->deep_drop();
    v_ir.clear();

    v_ir = parse_query_str_get_ir_set(strip_sql);
    if (v_ir.size() <= 0) {
//      cerr << "failed to parse after extract_struct:" << endl
//           << line << endl
//           << strip_sql << "\n\n\n";
      continue;
    }

    // cerr << "Parsing succeed. \n\n\n";

    add_all_to_library(v_ir.back());
    v_ir.back()->deep_drop();
  }

  return;
}

vector<IR *> Mutator::mutate(IR *input) {
  vector<IR *> res;

  if (!lucky_enough_to_be_mutated(input->mutated_times_)) {
    return res;
  }
  auto tmp = strategy_delete(input);
  if (tmp != NULL) {
    res.push_back(tmp);
  }

  tmp = strategy_insert(input);
  if (tmp != NULL) {
    res.push_back(tmp);
  }

  tmp = strategy_replace(input);
  if (tmp != NULL) {
    res.push_back(tmp);
  }

  input->mutated_times_ += res.size();
  for (auto i : res) {
    if (i == NULL)
      continue;
    i->mutated_times_ = input->mutated_times_;
  }
  return res;
}

bool Mutator::replace(IR *root, IR *old_ir, IR *new_ir) {
  auto parent_ir = locate_parent(root, old_ir);
  if (parent_ir == NULL)
    return false;
  if (parent_ir->left_ == old_ir) {
    deep_delete(old_ir);
    parent_ir->left_ = new_ir;
    return true;
  } else if (parent_ir->right_ == old_ir) {
    deep_delete(old_ir);
    parent_ir->right_ = new_ir;
    return true;
  }
  return false;
}

IR *Mutator::locate_parent(IR *root, IR *old_ir) {

  if (root->left_ == old_ir || root->right_ == old_ir)
    return root;

  if (root->left_ != NULL)
    if (auto res = locate_parent(root->left_, old_ir))
      return res;
  if (root->right_ != NULL)
    if (auto res = locate_parent(root->right_, old_ir))
      return res;

  return NULL;
}

IR *Mutator::strategy_delete(IR *cur) {
  assert(cur);
  MUTATESTART

  DOLEFT
  res = deep_copy(cur);
  if (res->left_ != NULL)
    deep_delete(res->left_);
  res->left_ = NULL;

  DORIGHT
  res = deep_copy(cur);
  if (res->right_ != NULL)
    deep_delete(res->right_);
  res->right_ = NULL;

  DOBOTH
  res = deep_copy(cur);
  if (res->left_ != NULL)
    deep_delete(res->left_);
  if (res->right_ != NULL)
    deep_delete(res->right_);
  res->left_ = res->right_ = NULL;

  MUTATEEND
}

IR *Mutator::strategy_insert(IR *cur) {
  // NOTE(vancir): rewritten by vancir.
  assert(cur);

  // auto res = deep_copy(cur);
  // auto parent_type = cur->type_;

  // if (res->right_ == NULL && res->left_ != NULL) {
  //   auto left_type = res->left_->type_;
  //   for (int k = 0; k < 4; k++) {
  //     auto fetch_ir = get_ir_from_library(parent_type);
  //     if (fetch_ir->left_ != NULL && fetch_ir->left_->type_ == left_type &&
  //         fetch_ir->right_ != NULL) {
  //       res->right_ = deep_copy(fetch_ir->right_);
  //       return res;
  //     }
  //   }
  // } else if (res->right_ != NULL && res->left_ == NULL) {
  //   auto right_type = res->left_->type_;
  //   for (int k = 0; k < 4; k++) {
  //     auto fetch_ir = get_ir_from_library(parent_type);
  //     if (fetch_ir->right_ != NULL && fetch_ir->right_->type_ == right_type
  //     &&
  //         fetch_ir->left_ != NULL) {
  //       res->left_ = deep_copy(fetch_ir->left_);
  //       return res;
  //     }
  //   }
  // } else if (res->left_ == NULL && res->right_ == NULL) {
  //   for (int k = 0; k < 4; k++) {
  //     auto fetch_ir = get_ir_from_library(parent_type);
  //     if (fetch_ir->right_ != NULL && fetch_ir->left_ != NULL) {
  //       res->left_ = deep_copy(fetch_ir->left_);
  //       res->right_ = deep_copy(fetch_ir->right_);
  //       return res;
  //     }
  //   }
  // }

  // return res;

  if (cur->type_ == TypeStmtList) {
    auto new_right = get_from_libary_with_left_type(cur->type_);
    if (new_right != NULL) {
      auto res = cur->deep_copy();
      auto new_res = new IR(TypeStmtList, OPMID(";"), res, new_right);
      return new_res;
    }
  }

  else if (cur->right_ == NULL && cur->left_ != NULL) {
    auto left_type = cur->left_->type_;
    auto new_right = get_from_libary_with_left_type(left_type);
    if (new_right != NULL) {
      auto res = cur->deep_copy();
      res->update_right(new_right);
      return res;
    }
  }

  else if (cur->right_ != NULL && cur->left_ == NULL) {
    auto right_type = cur->right_->type_;
    auto new_left = get_from_libary_with_right_type(right_type);
    if (new_left != NULL) {
      auto res = cur->deep_copy();
      res->update_left(new_left);
      return res;
    }
  }

  return get_from_libary_with_type(cur->type_);
}

IR *Mutator::strategy_replace(IR *cur) {
  assert(cur);

  MUTATESTART

  DOLEFT
  if (cur->left_ != NULL) {
    res = deep_copy(cur);

    auto new_node = get_ir_from_library(res->left_->type_);
    new_node->data_type_ = res->left_->data_type_;
    deep_delete(res->left_);
    res->left_ = deep_copy(new_node);
  }

  DORIGHT
  if (cur->right_ != NULL) {
    res = deep_copy(cur);

    auto new_node = get_ir_from_library(res->right_->type_);
    new_node->data_type_ = res->right_->data_type_;
    deep_delete(res->right_);
    res->right_ = deep_copy(new_node);
  }

  DOBOTH
  if (cur->left_ != NULL && cur->right_ != NULL) {
    res = deep_copy(cur);

    auto new_left = get_ir_from_library(res->left_->type_);
    auto new_right = get_ir_from_library(res->right_->type_);
    new_left->data_type_ = res->left_->data_type_;
    new_right->data_type_ = res->right_->data_type_;
    deep_delete(res->right_);
    res->right_ = deep_copy(new_right);

    deep_delete(res->left_);
    res->left_ = deep_copy(new_left);
  }

  MUTATEEND

  return res;
}

bool Mutator::lucky_enough_to_be_mutated(unsigned int mutated_times) {
  if (get_rand_int(mutated_times + 1) < LUCKY_NUMBER) {
    return true;
  }
  return false;
}

pair<string, string> Mutator::get_data_2d_by_type(DATATYPE type1,
                                                  DATATYPE type2) {
  pair<string, string> res("", "");
  auto size = data_library_2d_[type1].size();

  if (size == 0)
    return res;
  auto rint = get_rand_int(size);

  int counter = 0;
  for (auto &i : data_library_2d_[type1]) {
    if (counter++ == rint) {
      return std::make_pair(i.first, vector_rand_ele(i.second[type2]));
    }
  }
  return res;
}

// IR *Mutator::generate_ir_by_type(IRTYPE type) {
//   auto ast_node = generate_ast_node_by_type(type);
//   ast_node->generate();
//   vector<IR *> tmp_vector;
//   ast_node->translate(tmp_vector);
//   assert(tmp_vector.size());

//   return tmp_vector[tmp_vector.size() - 1];
// }

IR *Mutator::get_ir_from_library(IRTYPE type) {

  const int generate_prop = 1;
  const int threshold = 0;
  static IR *empty_ir = new IR(TypeStringLiteral, "");
#ifdef USEGENERATE
  if (ir_library_[type].empty() == true ||
      (get_rand_int(400) == 0 && type != kUnknown)) {
    auto ir = generate_ir_by_type(type);
    add_ir_to_library_no_deepcopy(ir);
    return ir;
  }
#endif
  if (ir_library_[type].empty())
    return empty_ir;
  return vector_rand_ele(ir_library_[type]);
}

string Mutator::get_a_string() {
  unsigned com_size = common_string_library_.size();
  // unsigned lib_size = string_library_.size();

  // if (get_rand_int(3) <= 1) {
  // if (lib_size == 0) {
  //   return "hello";
  // } else {
  //   return string_library_[get_rand_int(lib_size)];
  // }
  // } else {
  if (com_size == 0) {
    return "hello";
  } else {
    return common_string_library_[get_rand_int(com_size)];
  }
  // }
}

unsigned long Mutator::get_a_val() {
  assert(value_library_.size());

  return vector_rand_ele(value_library_);
}

unsigned long Mutator::hash(string &sql) {
  return fuzzing_hash(sql.c_str(), sql.size());
}

unsigned long Mutator::hash(IR *root) {
  auto tmp_str = move(root->to_string());
  return this->hash(tmp_str);
}

void Mutator::debug(IR *root) { this->debug(root, 0); }

void Mutator::debug(IR *root, unsigned level) {

  for (unsigned i = 0; i < level; i++)
    cout << " ";

  cout << level << ": " << get_string_by_ir_type(root->type_) << ": "
       << get_string_by_data_type(root->data_type_) << ": "
       << get_string_by_data_flag(root->data_flag_) << ": "
       << get_string_by_affinity_type(root->data_affinity_type) << ": "
       << root->uniq_id_in_tree_ << ": " << root->to_string() << endl;

  if (root->left_)
    debug(root->left_, level + 1);
  if (root->right_)
    debug(root->right_, level + 1);
}

Mutator::~Mutator() {
  for (auto iter = ir_library_.begin(); iter != ir_library_.end(); iter++) {
    for (IR *cur_ir : iter->second) {
      cur_ir->deep_drop();
    }
  }

  for (auto iter : all_query_pstr_set) {
    delete iter;
  }
}

string Mutator::extract_struct(IR *root) {
  string res = "";
  _extract_struct(root);
  res = root->to_string();
  trim_string(res);
  return res;
}

void Mutator::_extract_struct(IR *root) {

  if (root->left_) {
    extract_struct(root->left_);
  }
  if (root->right_) {
    extract_struct(root->right_);
  }

  auto type = root->type_;
  if (root->get_data_type() == DataTypeName ||
      root->get_data_type() == DataNone
  ) {
    return;
  }
//  if (root->get_data_flag() == ContextUnknown) {
//    return;
//  }

  if (root->get_ir_type() == TypeIntegerLiteral) {
    root->int_val_ = 0;
    root->str_val_ = "0";
    return;
  } else if (root->get_ir_type() == TypeFloatLiteral) {
    root->float_val_ = 0.0;
    root->str_val_ = "0.0";
    return;
  } else if (root->get_ir_type() == TypeStringLiteral) {
    root->str_val_ = "'x'";
    return;
  }

  if (root->left_ || root->right_ || root->data_type_ == DataFunctionName)
    return;

  if (root->data_type_ != DataUnknownType &&
      root->data_type_ != DataFunctionName) {
    root->str_val_ = "x";
    return;
  }

  if (string_types_.find(type) != string_types_.end()) {
    root->str_val_ = "'x'";
  } else if (int_types_.find(type) != int_types_.end()) {
    root->int_val_ = 1;
  } else if (float_types_.find(type) != float_types_.end()) {
    root->float_val_ = 1.0;
  }
}

void Mutator::extract_struct2(IR *root) {
  static int counter = 0;
  auto type = root->type_;
  if (root->left_) {
    extract_struct2(root->left_);
  }
  if (root->right_) {
    extract_struct2(root->right_);
  }

  if (root->left_ || root->right_)
    return;

  if (root->data_type_ != DataNone && root->data_type_ != DataUnknownType) {
    root->str_val_ = "x" + to_string(counter++);
    return;
  }

  if (string_types_.find(type) != string_types_.end()) {
    root->str_val_ = "'x'";
  } else if (int_types_.find(type) != int_types_.end()) {
    root->int_val_ = 1;
  } else if (float_types_.find(type) != float_types_.end()) {
    root->float_val_ = 1.0;
  }
}

string Mutator::parse_data(string &input) {
  string res;
  if (!input.compare("_int_")) {
    res = to_string(get_a_val());
  } else if (!input.compare("_empty_")) {
    res = "";
  } else if (!input.compare("_boolean_")) {
    if (get_rand_int(2) == 0)
      res = "false";
    else
      res = "true";
  } else if (!input.compare("_string_")) {
    res = get_a_string();
  } else {
    res = input;
  }

  return res;
}

void Mutator::pre_validate() {
  // Reset components that is local to the one query sequence.
  reset_id_counter();
  reset_data_library();
  return;
}

bool Mutator::validate(IR *&cur_stmt, bool is_debug_info) {

  bool res = true;
  if (cur_stmt->type_ == TypeRoot) {
    vector<IR *> cur_stmt_vec = p_oracle->ir_wrapper.get_stmt_ir_vec(cur_stmt);
    for (IR *cur_stmt_tmp : cur_stmt_vec) {
      res = this->validate(cur_stmt_tmp, is_debug_info) && res;
    }
    return res;
  }

  if (cur_stmt == NULL) {
    return false;
  }

  /* All the fixing steps happens here. */
  if (is_debug_info) {
    cerr << "Trying to fix stmt: " << cur_stmt->to_string() << " \n";
  }

  if (!instan_one_stmt(
          cur_stmt,
          is_debug_info)) { // Pass in kStmt, not kSpecificStatementType.
    return false;
  }
  if (is_debug_info) {
    cerr << "After fixing: " << cur_stmt->to_string() << " \n\n\n";
  }
  return true;
}

string Mutator::validate(string query, bool is_debug_info) {
  reset_data_library();

  vector<IR *> ir_set = parse_query_str_get_ir_set(query);
  if (ir_set.size() == 0)
    return "";

  IR *root = ir_set.back();
  if (root == NULL || root->type_ != TypeRoot) {
    if (root != NULL) {
      root->deep_drop();
    }
    return "";
  }

  if (!this->validate(root, is_debug_info)) {
    return "";
  }
  string res = root->to_string();
  root->deep_drop();
  return res;
}

unsigned int Mutator::calc_node(IR *root) {
  unsigned int res = 0;
  if (root->left_)
    res += calc_node(root->left_);
  if (root->right_)
    res += calc_node(root->right_);

  return res + 1;
}

bool Mutator::instan_one_stmt(IR *cur_stmt, bool is_debug_info) {
  bool res = true;

//  /* Reset library that is local to one query set. */
//  reset_data_library_single_stmt();

  /* m_substmt_save, used for reconstruct the tree. */
  map<IR *, pair<bool, IR *>> m_substmt_save;
  auto substmts =
      split_to_substmt(cur_stmt, m_substmt_save, split_substmt_types_);

  int substmt_num = substmts.size();
  if (substmt_num > 10) {
    connect_back(m_substmt_save);
    if (is_debug_info) {
      cerr << "Dependency Error: the query is too complicated to fix. Has more "
              "than 5 subqueries. \n\n\n"; // Ad-hoc number, just based on
                                           // intuition.
    }
    return false;
  }

  vector<vector<IR *>> cur_stmt_ir_to_fix;

  for (auto &substmt : substmts) {
    substmt->parent_ = NULL;

    // Disabled feature.
    /* Avoid fixing IR file that is to big. */
    //    int tmp_node_num = calc_node(substmt);
    /* No sub-queries, then <= 150, sub-queries <= 120 */
    // if ((substmt_num == 1 && tmp_node_num > 230) || tmp_node_num > 200) {
    //   if (is_debug_info) {
    //     cerr << "\n\n\nDepedency Error: The subquery is too complicated to
    //     mutate, sub_query node_num: " << tmp_node_num << " is > 200. \n\n\n";
    //   }
    //   continue;
    // }

    vector<IR *> cur_substmt_ir_to_fix;
      this->instan_preprocessing(substmt, cur_substmt_ir_to_fix);

    cur_stmt_ir_to_fix.push_back(cur_substmt_ir_to_fix);
  }

  res = connect_back(m_substmt_save) && res;

  res = instan_dependency(cur_stmt, cur_stmt_ir_to_fix, is_debug_info);

  return res;
}

vector<IR *> Mutator::pre_fix_transform(IR *root,
                                        vector<STMT_TYPE> &stmt_type_vec) {

  p_oracle->init_ir_wrapper(root);
  vector<IR *> all_trans_vec;
  vector<IR *> all_statements_vec = p_oracle->ir_wrapper.get_stmt_ir_vec();

  // cerr << "In func: Mutator::pre_fix_transform(IR * root, vector<STMT_TYPE>&
  // stmt_type_vec), we have all_statements_vec size(): "
  //     << all_statements_vec.size() << "\n\n\n";

  for (IR *cur_stmt : all_statements_vec) {
    /* Identify oracle related statements. Ready for transformation. */
    bool is_oracle_select = false, is_oracle_normal = false;
    if (p_oracle->is_oracle_normal_stmt(cur_stmt)) {
      is_oracle_normal = true;
      stmt_type_vec.push_back(ORACLE_NORMAL);
    } else if (p_oracle->is_oracle_select_stmt(cur_stmt)) {
      is_oracle_select = true;
      stmt_type_vec.push_back(ORACLE_SELECT);
    } else {
      stmt_type_vec.push_back(NOT_ORACLE);
    }

    /* Apply pre_fix_transformation functions. */
    IR *trans_IR = nullptr;
    if (is_oracle_normal) {
      trans_IR =
          p_oracle->pre_fix_transform_normal_stmt(cur_stmt); // Deep_copied
    } else if (is_oracle_select) {
      trans_IR =
          p_oracle->pre_fix_transform_select_stmt(cur_stmt); // Deep_copied
    }
    /* If no pre_fix_transformation is needed, directly use the original
     * cur_root. */
    if (trans_IR == nullptr) {
      trans_IR = cur_stmt->deep_copy();
    }
    all_trans_vec.push_back(trans_IR);
  }

  return all_trans_vec;
}

vector<vector<vector<IR *>>> Mutator::post_fix_transform(
    vector<IR *> &all_pre_trans_vec, vector<STMT_TYPE> &stmt_type_vec,
    vector<vector<STMT_TYPE>> &post_fix_stmt_type_vec_vec) {
  int total_run_count = p_oracle->get_mul_run_num();
  vector<vector<vector<IR *>>> all_trans_vec_all_run;
  vector<STMT_TYPE> tmp_post_fix_stmt_type;
  for (int run_count = 0; run_count < total_run_count; run_count++) {
    tmp_post_fix_stmt_type.clear();
    all_trans_vec_all_run.push_back(this->post_fix_transform(
        all_pre_trans_vec, stmt_type_vec, tmp_post_fix_stmt_type,
        run_count)); // All deep_copied.

    post_fix_stmt_type_vec_vec.push_back(tmp_post_fix_stmt_type);
  }
  return all_trans_vec_all_run;
}

vector<vector<IR *>> Mutator::post_fix_transform(
    vector<IR *> &all_pre_trans_vec, vector<STMT_TYPE> &stmt_type_vec,
    vector<STMT_TYPE> &post_fix_stmt_type_vec, int run_count) {
  // Apply post_fix_transform functions.
  vector<vector<IR *>> all_post_trans_vec;
  vector<int> v_stmt_to_rov;
  for (int i = 0; i < all_pre_trans_vec.size();
       i++) { // Loop through across statements.
    IR *cur_pre_trans_ir = all_pre_trans_vec[i];
    vector<IR *> post_trans_stmt_vec;
    assert(cur_pre_trans_ir != nullptr);

    bool is_oracle_normal = false, is_oracle_select = false;
    if (stmt_type_vec[i] == ORACLE_SELECT) {
      is_oracle_select = true;
    } else if (stmt_type_vec[i] == ORACLE_NORMAL) {
      is_oracle_normal = true;
    }

    if (is_oracle_normal) {
      post_trans_stmt_vec = p_oracle->post_fix_transform_normal_stmt(
          cur_pre_trans_ir, run_count); // All deep_copied
    } else if (is_oracle_select) {
      post_trans_stmt_vec = p_oracle->post_fix_transform_select_stmt(
          cur_pre_trans_ir, run_count); // All deep_copied
    } else {
      post_trans_stmt_vec.push_back(cur_pre_trans_ir->deep_copy());
    }

    if (post_trans_stmt_vec.size() > 0) {
      all_post_trans_vec.push_back(post_trans_stmt_vec);
    } else {
      /* Debug */
      // cerr << "DEBUG: stmt: " << cur_pre_trans_ir->to_string() << " returns
      // empty. \n";

      v_stmt_to_rov.push_back(i);
    }
  }

  for (int i = 0; i < stmt_type_vec.size(); i++) {
    if (find(v_stmt_to_rov.begin(), v_stmt_to_rov.end(), i) !=
        v_stmt_to_rov.end()) {
      continue;
    }
    post_fix_stmt_type_vec.push_back(stmt_type_vec[i]);
  }

  return all_post_trans_vec;
}

/*
** From the outer most parent-statements to the inner most sub-statements.
*/
vector<IR *> Mutator::split_to_substmt(IR *cur_stmt,
                                       map<IR *, pair<bool, IR *>> &m_save,
                                       set<IRTYPE> &split_set) {
  /* This function is responsible to detect
   * and detach all the subqueries from the statement.
   * Additionally, it needs to decide the order of the
   * subquery instantiation.
   * For normal subquery, it can use variables defined in the
   * parent query, which means they should be fixed later than the
   * root query.
   * However, for WITH clause SELECT, CREATE VIEW and CREATE TABLE AS,
   * the subquery that defines the main semantic should be fixed earlier,
   * so that the root stmt can correctly map the dependencies to the subquery
   * tables/columns.
   */
  cur_stmt->parent_ = NULL;

  list<IR *> res_list;
  vector<IR *> res;
  deque<IR *> bfs = {cur_stmt};

  /* The root cur_stmt should always be saved. */
  res_list.push_back(cur_stmt);

  while (!bfs.empty()) {
    auto node = bfs.front();
    bfs.pop_front();

    if (node && node->left_)
      bfs.push_back(node->left_);
    if (node && node->right_)
      bfs.push_back(node->right_);

    /* See if current node type is matching split_set. If yes, disconnect
     * node->left and node->right. */
    if (node->left_ &&
        find(split_set.begin(), split_set.end(), node->left_->type_) !=
            split_set.end() &&
        p_oracle->ir_wrapper.is_in_subquery(cur_stmt, node->left_)) {
      if (p_oracle->ir_wrapper.is_ir_in(node->get_left(), TypeWith) ||
          node->get_ir_type() == TypeCreateView ||
          node->get_ir_type() == TypeCreateTableAs) {
        // If the statement is in the WITH clause, Create Table AS
        // or Create view as, fix the subquery first.
        res_list.push_front(node->get_left());
      } else {
        res_list.push_back(node->get_left());
      }
      pair<bool, IR *> cur_m_save =
          make_pair<bool, IR *>(true, node->get_left());
      m_save[node] = cur_m_save;
    }
    if (node->right_ &&
        find(split_set.begin(), split_set.end(), node->right_->type_) !=
            split_set.end() &&
        p_oracle->ir_wrapper.is_in_subquery(cur_stmt, node->right_)) {

      if (p_oracle->ir_wrapper.is_ir_in(node->get_right(), TypeWith) ||
          node->get_ir_type() == TypeCreateView ||
          node->get_ir_type() == TypeCreateTableAs) {
        // If the statement is in the WITH clause, Create Table AS
        // or Create view as, fix the subquery first.
        res_list.push_front(node->get_right());
      } else {
        res_list.push_back(node->get_right());
      }
      pair<bool, IR *> cur_m_save =
          make_pair<bool, IR *>(false, node->get_right());
      m_save[node] = cur_m_save;
    }
  }

  for (auto ptr = res_list.begin(); ptr != res_list.end(); ptr++) {
    res.push_back(*ptr);
  }

  for (int idx = 0; idx < res.size(); idx++) {
    if (res[idx] == cur_stmt) {
      // Avoid detach the root node.
      continue;
    }
    // Detach all the subquery.
    cur_stmt->detach_node(res[idx]);
  }

  return res;
}

bool Mutator::connect_back(map<IR *, pair<bool, IR *>> &m_save) {
  for (auto &iter : m_save) {
    if (iter.second.first) { // is_left?
      iter.first->update_left(iter.second.second);
    } else {
      iter.first->update_right(iter.second.second);
    }
  }
  return true;
}

pair<string, string>
Mutator::ir_to_string(IR *root, vector<vector<IR *>> all_post_trans_vec,
                      const vector<STMT_TYPE> &stmt_type_vec) {
  // Final step, IR_to_string function.
  string output_str_mark, output_str_no_mark;
  for (int i = 0; i < all_post_trans_vec.size();
       i++) { // Loop between different statements.
    vector<IR *> post_trans_vec = all_post_trans_vec[i];
    int count = 0;
    bool is_oracle_select = false;
    if (stmt_type_vec[i] == ORACLE_SELECT) {
      is_oracle_select = true;
    }
    for (IR *cur_trans_stmt :
         post_trans_vec) { // Loop between different transformations.
      string tmp = cur_trans_stmt->to_string();
      if (is_oracle_select) {
        output_str_mark += "SELECT 'BEGIN VERI " + to_string(count) + "'; \n";
        output_str_mark += tmp + "; \n";
        output_str_mark += "SELECT 'END VERI " + to_string(count) + "'; \n";
        output_str_no_mark += tmp + "; \n";
        count++;
      } else {
        output_str_mark += tmp + "; \n";
        output_str_no_mark += tmp + "; \n";
      }
    }
  }
  pair<string, string> output_str_pair =
      make_pair(output_str_mark, output_str_no_mark);
  return output_str_pair;
}

// find tree node whose identifier type can be handled
//
// NOTE: identifier type is different from IR type
//
static void collect_ir(IR *root, set<DATATYPE> &type_to_fix,
                       vector<IR *> &ir_to_fix) {
  DATATYPE idtype = root->data_type_;

  if (root->left_) {
    collect_ir(root->left_, type_to_fix, ir_to_fix);
  }

  if (type_to_fix.find(idtype) != type_to_fix.end()) {
    ir_to_fix.push_back(root);
  }

  if (root->right_) {
    collect_ir(root->right_, type_to_fix, ir_to_fix);
  }
}

/*
** relationmap_[kDataColumnName][kDataTableName] = kRelationSubtype;
** relationmap_[kDataPragmaValue][kDataPragmaKey] = kRelationSubtype;
** relationmap_[kDataTableName][kDataTableName] = kRelationElement;
** relationmap_[kDataColumnName][kDataColumnName] = kRelationElement;
*/
void Mutator::instan_preprocessing(IR *stmt_root,
                                   vector<IR *> &ordered_all_subquery_ir) {
  set<DATATYPE> type_to_fix = {
      DataColumnName,     DataTableName,       DataIndexName,
      DataTableAliasName, DataColumnAliasName, DataSequenceName,
      DataViewName,       DataConstraintName,  DataSequenceName,
      DataTypeName,       DataLiteral,         DataDatabaseName,
      DataSchemaName,     DataViewColumnName,  DataFamilyName,
      DataStorageParams,  DataFunctionExpr};
  vector<IR *> ir_to_fix;
  collect_ir(stmt_root, type_to_fix, ordered_all_subquery_ir);
}

string Mutator::find_cloest_table_name(IR *ir_to_fix, bool is_debug_info) {
  string closest_table_name = "";
  IR *closest_table_ir = NULL;
  vector<DATATYPE> search_type = {DataTableName, DataTableAliasName};
  vector<IRTYPE> cap_type = {TypeSelect};
  closest_table_ir =
      p_oracle->ir_wrapper
          .find_closest_nearby_IR_with_type<vector<DATATYPE>, vector<IRTYPE>>(
              ir_to_fix, search_type, cap_type);
  if (closest_table_ir != NULL) {
    closest_table_name = closest_table_ir->get_str_val();
    if (is_debug_info) {
      cerr << "Dependency: In ContextUse of kDataColumnName, find table name: "
           << closest_table_name << " for column name. \n\n\n"
           << endl;
    }
  } else if (v_table_names_single.size() != 0) {
    closest_table_name =
        v_table_names_single[get_rand_int(v_table_names_single.size())];
    if (is_debug_info) {
      cerr << "Dependency: In ContextUse of kDataColumnName, find table name: "
           << closest_table_name << " for column name origin. \n\n\n"
           << endl;
    }
  } else if (v_create_table_names_single.size() != 0) {
    closest_table_name = v_create_table_names_single[0];
    if (is_debug_info) {
      cerr << "Dependency: In kUse of kDataColumnName, find newly "
              "declared table name: "
           << closest_table_name << " for column name origin. \n\n\n"
           << endl;
    }
  } else if (v_table_alias_names_single.size() != 0) {
    ir_to_fix->str_val_ = v_table_alias_names_single[get_rand_int(
        v_table_alias_names_single.size())];
    if (is_debug_info) {
      cerr << "Dependency: In kUse of kDataColumnName, use alias name as "
              "the column name. Use alias name: "
           << ir_to_fix->str_val_ << " for column name. \n\n\n"
           << endl;
    }
    // Finished assigning column name. continue;
    ir_to_fix->set_is_instantiated(true);
    return "";
  } else if (v_table_names.size() != 0) {

    /* This should be an error.
    ** 80% chances, keep original.
    ** 20%, use predefined table name.
    */
    if (get_rand_int(5) < 4) {
      ir_to_fix->set_is_instantiated(true);
      return "";
    }

    closest_table_name = v_table_names[get_rand_int(v_table_names.size())];
    if (is_debug_info) {
      cerr << "Dependency Error: In kUse of kDataColumnName, cannot find "
              "v_table_names_single. Thus find from v_table_name "
              "instead. Use table name: "
           << closest_table_name << " for column name origin. \n\n\n"
           << endl;
    }
  }

  return closest_table_name;
}

DATAAFFINITYTYPE Mutator::get_nearby_data_affinity(IR *ir_to_fix,
                                                   bool is_debug_info) {

  // First, search if we can find a nearby literal that already has the
  // affinity fixed.

  DATAAFFINITYTYPE ret_data_affi;

  vector<IRTYPE> v_matched_literal_types = {
      TypeIntegerLiteral, TypeStringLiteral, TypeFloatLiteral, TypeIdentifier};
  vector<IRTYPE> v_capped_ir_types = {TypeSelectClause, TypeSelect};
  IR *near_literal_node =
      p_oracle->ir_wrapper
          .find_closest_nearby_IR_with_type<vector<IRTYPE>, vector<IRTYPE>>(
              ir_to_fix, v_matched_literal_types, v_capped_ir_types);

  if (near_literal_node != NULL &&
      near_literal_node->get_data_affinity() != AFFIUNKNOWN &&
      near_literal_node->get_data_affinity() != AFFIANY &&
      near_literal_node->get_is_instantiated() == true) {
    //        ir_to_fix->set_data_affinity(near_literal_node->get_data_affinity());
    ret_data_affi = near_literal_node->get_data_affinity();
    if (is_debug_info) {
      cerr << "\n\n\nDependency: INFO: From Literal handling, getting "
              "nearby literal: "
           << near_literal_node->to_string()
           << ", the literal comes with affinity: "
           << get_string_by_affinity_type(
                  near_literal_node->get_data_affinity())
           << "\n\n\n";
    }
  } else {
    // If we end up in this branch, we cannot find a nearby literal or column
    // names that already has fixed affinity. This is expected, such as case:
    // `SELECT
    // * FROM v0 WHERE v1 = 100;` Then, we should look at the nearby
    // column name for more information.

    IR *nearby_column_ir =
        p_oracle->ir_wrapper.find_closest_nearby_IR_with_type(ir_to_fix,
                                                              DataColumnName);
    if (nearby_column_ir != NULL) {
      string nearby_column_str = nearby_column_ir->get_str_val();
      string actual_column_str = nearby_column_str;
      if (m_column2datatype.count(nearby_column_str) ||
          m_alias2column_single.count(nearby_column_str)) {
        if (m_alias2column_single.count(nearby_column_str)) {
          actual_column_str = m_alias2column_single[nearby_column_str];
          if (is_debug_info) {
            cerr << "\n\n\nDependency: INFO: In literal fixing, mapping the "
                    "column alias: "
                 << nearby_column_str
                 << " to column name: " << actual_column_str << "\n\n\n";
          }
        }
        DataAffinity cur_affi = m_column2datatype[actual_column_str];
        //                ir_to_fix->set_data_affinity(cur_affi);
        ret_data_affi = cur_affi.get_data_affinity();
        if (is_debug_info) {
          cerr << "Dependency: INFO: From Literal handling, getting "
                  "column name: "
               << nearby_column_str << ", the column comes with affinity: "
               << get_string_by_affinity_type(cur_affi.get_data_affinity())
               << "\n\n\n";
        }
      } else {
        //                ir_to_fix->set_data_affinity(AFFISTRING);
        ret_data_affi = AFFISTRING;
        if (is_debug_info) {
          cerr << "Dependency: INFO: From Literal handling, getting "
                  "column name: "
               << nearby_column_str
               << ". However, the colum name does not come with affinity: "
                  ", dummy fix the literal to AFFISTRING now."
               << "\n\n\n";
        }
      }
    } else {
      // Cannot find nearby COLUMN NAME?
      if (is_debug_info) {
        cerr << "\n\n\n Error: For fixing literal, cannot find nearby "
                "column name definition. "
                "Use dummy AFFISTRING instead for now. "
             << "\n\n\n";
      }
      //            ir_to_fix->set_data_affinity(AFFISTRING);
      ret_data_affi = AFFISTRING;
    }
  }

  return ret_data_affi;
}

void Mutator::instan_database_schema_name(IR *ir_to_fix, bool is_debug_info) {
  if ((ir_to_fix->data_type_ == DataDatabaseName)) {
    ir_to_fix->set_str_val("sqlrighttestdb");
  }

  if (ir_to_fix->data_type_ == DataSchemaName) {
    ir_to_fix->set_str_val("public");
  }
  return;
}

void Mutator::instan_table_name(IR *ir_to_fix, bool &is_replace_table,
                                bool is_debug_info) {

  if (p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeSetVar) ||
      p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeStorageParams)
          ) {
      return;
  }

  if ((ir_to_fix->data_type_ == DataTableName) &&
      (ir_to_fix->data_flag_ == ContextDefine ||
       ir_to_fix->data_flag_ == ContextReplaceDefine)) {
    string new_name = gen_id_name();
    ir_to_fix->str_val_ = new_name;
    ir_to_fix->set_is_instantiated(true);

    // Save the table name that just defined inside this single statement.
    // Will permanently save this table name at the end of the function.
    v_create_table_names_single.push_back(new_name);
    if (is_debug_info) {
      cerr << "Dependency: Added to v_table_names: " << new_name
           << ", in kDataTableName with kDefine or kReplace. \n\n\n";
      cerr << "Dependency: All current statement defined name: ";
      for (string &all_defined_name : v_table_names_single) {
        cerr << all_defined_name << " ";
      }
      cerr << "Dependency: All previously saved table names: ";
      for (string &all_used_name : v_table_names) {
        cerr << "previously saved table used names: " << all_used_name
             << "\n\n\n";
      }
    }

    if (ir_to_fix->data_flag_ == ContextReplaceDefine) {
      // If the newly defined table is marked as ContextReplaceDefine, which
      // means the statement is related to ALTER TABLE v0 RENAME TO v1; Mark
      // the replacing table mark.
      is_replace_table = true;
    }
  }

  else if ((ir_to_fix->data_type_ == DataTableName) &&
           (ir_to_fix->data_flag_ == ContextUndefine ||
            ir_to_fix->data_flag_ == ContextReplaceUndefine)) {
    if (v_table_names.size() > 0) {
      // Choose random table name that defined before to drop.
      string removed_table_name =
          v_table_names[get_rand_int(v_table_names.size())];
      v_table_names.erase(std::remove(v_table_names.begin(),
                                      v_table_names.end(), removed_table_name),
                          v_table_names.end());
      // Also remove the v_table_with_partition, if matched.
      v_table_with_partition.erase(std::remove(v_table_with_partition.begin(),
                                               v_table_with_partition.end(),
                                               removed_table_name),
                                   v_table_with_partition.end());

      // FIXME:: Should we also remove the table name string inside the
      // v_create_table_names_single?

      ir_to_fix->str_val_ = removed_table_name;
      ir_to_fix->set_is_instantiated(true);
      if (is_debug_info) {
        cerr << "Dependency: Removed from v_table_names: " << removed_table_name
             << ", in TypeDataTableName with ContextUndefine \n\n\n";
      }

      if (is_replace_table && v_create_table_names_single.size() != 0) {
        // In most of the case, the replacement would only have one pair of
        // table names.
        string new_table_name = v_create_table_names_single.back();
        m_table2columns[new_table_name] = m_table2columns[removed_table_name];
      }
    } else {
      if (is_debug_info) {
        cerr << "Dependency Error: Failed to find info in v_table_names, "
                "in DataTableName with ContextUndefine. \n\n\n";
      }
      // Randomly delete a not existed table.
      ir_to_fix->set_str_val("x");
      ir_to_fix->set_is_instantiated(true);
    }
  }

  else if (ir_to_fix->data_type_ == DataTableName &&
           ir_to_fix->data_flag_ == ContextUse) {

    /* INFO:: CockroachDB does not have the syntax of PARTITION OF table.
     * Therefore, we don't need to consider the PARTITION OF
     * partitioned_table grammar.
     * */

    if (v_table_names.size() == 0 && v_table_names_single.size() == 0 &&
        v_create_table_names_single.size() == 0) {
      if (is_debug_info) {
        cerr << "Dependency Error: Failed to find info in v_table_names "
                "and v_create_table_names_single, in kDataTableName with "
                "ContextUse. \n\n\n";
      }
      ir_to_fix->set_is_instantiated(true);
      ir_to_fix->set_str_val("x");
      return;
    }
    string used_name = "";

    if (v_table_alias_names_single.size() != 0 && get_rand_int(2)) {
      used_name = v_table_alias_names_single[get_rand_int(
          v_table_alias_names_single.size())];
      // Save it to the v_table_names_single, so that the ContextUsedFollow can
      // use this name.
      v_table_names_single.push_back(used_name);
    } else if (v_table_names_single.size() != 0) {
      // If the statement use some table names before,
      // we can refer to the table name here.
      // We can imagine v_table_names_single could contain
      // alias name defined in WITH clause or other places.
      used_name =
          v_table_names_single[get_rand_int(v_table_names_single.size())];

      int trial = 10;
      while (p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeInsert) &&
             trial-- != 0 &&
             find(v_view_name.begin(), v_view_name.end(), used_name) !=
                 v_view_name.end()) {
        if (is_debug_info) {
          cerr << "\n\n\nRetry table name fixing in the INSERT statement. "
                  "\n\n\n";
        }
        used_name =
            v_table_names_single[get_rand_int(v_table_names_single.size())];
      }

    } else if (v_create_table_names_single.size() != 0) {
      // If cannot find any table names defined or used before,
      // consider the table name that just defined in this statement.
      used_name = v_create_table_names_single[get_rand_int(
          v_create_table_names_single.size())];
    } else if (v_table_names.size() != 0) {
      used_name = v_table_names[get_rand_int(v_table_names.size())];

      int trial = 10;
      while (p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeInsert) &&
             trial-- != 0 &&
             find(v_view_name.begin(), v_view_name.end(), used_name) !=
                 v_view_name.end()) {
        if (is_debug_info) {
          cerr << "\n\n\nRetry table name fixing in the INSERT statement. "
                  "\n\n\n";
        }
        used_name = v_table_names[get_rand_int(v_table_names.size())];
      }

    } else {
      if (is_debug_info) {
        cerr << "Cannot find any used or defined table names. Use simple x "
                "as name. \n\n\n";
      }
      used_name = "x";
    }
    ir_to_fix->str_val_ = used_name;
    ir_to_fix->set_is_instantiated(true);
    // Save the table name used in this statement.
    // The saved table name can be referred later by
    //   contextUseFollow.
    v_table_names_single.push_back(used_name);
    if (is_debug_info) {
      cerr << "Dependency: In the context of ContextUsed table, we got "
              "table_name: "
           << used_name << ". \n\n\n";
      for (string &all_used_name : v_table_names) {
        cerr << "Dependency: All saved table used names: " << all_used_name
             << "\n\n\n";
      }
      for (string &all_used_name : v_create_table_names_single) {
        cerr << "Dependency: All saved table used names: " << all_used_name
             << "\n\n\n";
      }
    }

    // TODO: FIXME: Create AS.
    //        if (cur_stmt_root->get_ir_type() == TypeCreateTable &&
    //            p_oracle->ir_wrapper.is_ir_in(ir_to_fix,
    //            kTableLikeClause)) {
    //
    //            if (v_create_table_names_single.size() > 0) {
    //              string newly_create_table_str =
    //              v_create_table_names_single.front();
    //              m_table2columns[newly_create_table_str] =
    //              m_table2columns[ir_to_fix->get_str_val()];
    //            }
    //
    //        }
  }

  else if (ir_to_fix->data_type_ == DataTableName &&
           ir_to_fix->data_flag_ == ContextUseFollow) {

    if (v_table_alias_names_single.size() == 0 && v_table_names.size() == 0 &&
        v_table_names_single.size() == 0 &&
        v_create_table_names_single.size() == 0) {
      if (is_debug_info) {
        cerr << "Dependency Error: Failed to find info in v_table_names "
                "and v_create_table_names_single, in kDataTableName with "
                "ContextUse. \n\n\n";
      }
      ir_to_fix->set_is_instantiated(true);
      ir_to_fix->set_str_val("x");
      return;
    }
    string used_name = "";

    if (is_debug_info) {
      cerr << "\n\n\nDEBUG: In Table ContextUseFollow: getting "
              "v_table_alias_names_single.size(): "
           << v_table_alias_names_single.size()
           << ", v_table_names_single: " << v_table_names_single.size()
           << ", v_create_table_names_single"
           << v_create_table_names_single.size() << "\n\n\n";
    }
    // For the ContextUseFollow, we should use table name that already
    // mentioned in the current statement.
    // For example, for `v0.v1`, where v0 is imported from `FROM v0;`
    // Therefore, we should not directly use the Table Alias name.
    // If the table alias is defined in the FROM clause,
    // then the alias name should also be in the v_table_names_single.
    if (v_table_names_single.size() != 0) {
      used_name =
          v_table_names_single[get_rand_int(v_table_names_single.size())];
    } else if (v_create_table_names_single.size() != 0) {
      // If cannot find any table names defined or used before,
      // consider the table name that defined from previous statements.
      // Not sure whether this situation is possible or not.
      if (is_debug_info) {
        cerr << "\n\n\nIn the scenario of table name ContextUseFollow, "
                "cannot find table name inside "
                "v_table_names_single. Use previous defined table names "
                "instead. \n\n\n";
      }
      used_name = v_create_table_names_single[get_rand_int(
          v_create_table_names_single.size())];
    } else if (v_table_names.size() != 0) {
      // If the statement use some table names before,
      // we can refer to the table name here.
      // We can imagine v_table_names_single could contain
      // alias name defined in WITH clause or other places.
      if (is_debug_info) {
        cerr << "\n\n\nIn the scenario of table name ContextUseFollow, "
                "cannot find table name inside "
                "v_table_names_single. Use previous defined table names "
                "instead. \n\n\n";
      }
      used_name = v_table_names[get_rand_int(v_table_names.size())];
    } else {
      if (is_debug_info) {
        cerr << "Cannot find any used or defined table names. Use simple x "
                "as name. \n\n\n";
      }
      used_name = "x";
    }

    // Check whether the chosen alias name is inside the enforced table alias mapping.
    if (m_enforced_table2alias_single.count(used_name) != 0 && m_enforced_table2alias_single[used_name].size() != 0) {
        if (is_debug_info) {
            cerr << "\n\n\nDependency: Inside the table name use follow instantiation, forced map the table name "
                 << used_name << " to ";
        }
        used_name = vector_rand_ele(m_enforced_table2alias_single[used_name]);
        if (is_debug_info) {
            cerr << used_name << "\n\n\n";
        }
    }

    ir_to_fix->str_val_ = used_name;
    ir_to_fix->set_is_instantiated(true);

    if (is_debug_info) {
      cerr << "Dependency: In the context of ContextUsed table, we got "
              "table_name: "
           << used_name << ". \n\n\n";
      for (string &all_used_name : v_table_names) {
        cerr << "Dependency: All saved table used names: " << all_used_name
             << "\n\n\n";
      }
      for (string &all_used_name : v_create_table_names_single) {
        cerr << "Dependency: All saved table used names: " << all_used_name
             << "\n\n\n";
      }
    }
  }

  return;
}

void Mutator::instan_table_alias_name(IR *ir_to_fix, IR *cur_stmt_root, bool is_alias_optional,
                                      bool is_debug_info) {

  /* There is no need to consider the Context in this loop.
   * Because TableAliasName almost always occur on ContextDefine.
   * The Alias name will be saved into the
   */

  if (ir_to_fix->data_type_ == DataTableAliasName) {

    ir_to_fix->set_is_instantiated(true);

    string closest_table_name = "";

    IR *closest_table_ir =
        p_oracle->ir_wrapper.find_closest_nearby_IR_with_type<DATATYPE>(
            ir_to_fix, DataTableName);

    if (closest_table_ir != NULL) {
      closest_table_name = closest_table_ir->get_str_val();
    } else if (v_table_names_single.size() != 0) {
      if (is_debug_info) {
        cerr << "\n\n\nError: Dependency: When handling the "
                "DataTableAliasName, "
                "cannot find the table name nearby the ir_to_fix(). \n\n\n";
        cerr << "\n\n\n More debugging information: cur node: "
             << ir_to_fix->to_string()
             << "; whole statement: " << cur_stmt_root->to_string() << "\n\n\n";
      }
      closest_table_name =
          v_table_names_single[get_rand_int(v_table_names_single.size())];
    } else if (v_create_table_names_single.size() != 0) {
      if (is_debug_info) {
        cerr << "\n\n\nError: Dependency: When handling the "
                "DataTableAliasName, "
                "cannot find the table name nearby the ir_to_fix(). \n\n\n";
        cerr << "\n\n\n More debugging information: cur node: "
             << ir_to_fix->to_string()
             << "; whole statement: " << cur_stmt_root->to_string() << "\n\n\n";
      }
      closest_table_name = v_create_table_names_single[0];
      if (is_debug_info) {
        cerr << "Dependency: In kAlias defined, find newly declared table "
                "name: "
             << closest_table_name << ". \n\n\n"
             << endl;
      }
    } else if (v_table_names.size() != 0) {
      if (is_debug_info) {
        cerr << "Error: Dependency: When handling the DataTableAliasName, "
                "cannot find the table name nearby the ir_to_fix(). ";
        cerr << "\n More debugging information: cur node: "
             << ir_to_fix->to_string()
             << "; whole statement: " << cur_stmt_root->to_string();
      }
      closest_table_name = v_table_names[get_rand_int(v_table_names.size())];
      if (is_debug_info) {
        cerr << "Dependency Error: In defined of kDataAliasName, cannot "
                "find v_table_names_single. Thus find from v_table_name "
                "instead. Use table name: "
             << closest_table_name << ". \n\n\n"
             << endl;
      }
    } else {
      if (is_debug_info) {
        cerr << "Error: Dependency: When handling the DataTableAliasName, "
                "cannot find the any way to refer to a table name nearby "
                "the ir_to_fix(). ";
        cerr << "\n More debugging information: cur node: "
             << ir_to_fix->to_string()
             << "; whole statement: " << cur_stmt_root->to_string();
      }
      ir_to_fix->set_str_val("x");
      // Break the current ir instantiation handling.
      return;
    }

    if (is_debug_info) {
      cerr << "Dependency: In DataTableAliasName ContextDefined, find "
              "table name: "
           << closest_table_name << ". \n\n\n"
           << endl;
    }

    if (closest_table_name == "" || closest_table_name == "x" ||
        closest_table_name == "y") {
      if (is_debug_info) {
        cerr << "Dependency Error: Cannot find the closest_table_name from "
                "the query. Error cloest_table_name is: "
             << closest_table_name << ". In kAliasName Define. \n\n\n";
      }
      /* Randomly set an alias name to the defined table.
       * And ignore the mapping for the moment
       * */
      string alias_name = gen_table_alias_name();
      ir_to_fix->str_val_ = alias_name;
      v_table_alias_names_single.push_back(alias_name);
      return;
    }

    /* Found the table name that matched to the alias, now generate the
     * alias and save it.  */
    string alias_name = gen_table_alias_name();
    ir_to_fix->set_str_val(alias_name);
    m_alias2table_single[alias_name] = closest_table_name;
    if (!is_alias_optional) {
        m_enforced_table2alias_single[closest_table_name].push_back(alias_name);
    }
    m_alias_table2column_single[alias_name] =
        m_table2columns[closest_table_name];
    v_table_alias_names_single.push_back(alias_name);
    if (p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeFrom)) {
      if (is_debug_info) {
        cerr << "\n\n\n The table alias: " << alias_name
             << " is defined "
                "inside the FROM clause, so we can safely move the alias into "
                "the"
                "v_table_name_single. \n\n\n";
      }
      v_table_names_single.push_back(alias_name);
    }

    if (is_debug_info) {
      cerr << "Dependency: In TypeTableAliasName defined, generates: "
           << alias_name << " mapping to table name: " << closest_table_name
           << ". \n\n\n"
           << endl;
    }
  }

  return;
}

void Mutator::instan_view_name(IR *ir_to_fix, bool is_debug_info) {

  if (p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeSetVar) ||
      p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeStorageParams)
          ) {
      return;
  }

  /* Context Define. */
  if (ir_to_fix->data_type_ == DataViewName &&
      ir_to_fix->data_flag_ == ContextDefine) {

    string new_view_name_str = gen_view_name();
    ir_to_fix->set_str_val(new_view_name_str);
    ir_to_fix->set_is_instantiated(true);

    v_create_view_names_single.push_back(new_view_name_str);

    if (is_debug_info) {
      cerr << "Dependency: In kDefine of kDataViewName, generating view "
              "name: "
           << new_view_name_str << "\n\n\n";
    }
  }

  /* Context Undefine */
  if (ir_to_fix->data_type_ == DataViewName &&
      ir_to_fix->data_flag_ == ContextUndefine) {
    if (v_view_name.size() == 0) {
      if (is_debug_info) {
        cerr << "Dependency Error: In kUndefine of kDataViewname, cannot "
                "find view name defined before. \n\n\n";
      }
      ir_to_fix->set_is_instantiated(true);
      return;
    }
    string view_to_rov_str = vector_rand_ele(v_view_name);
    ir_to_fix->set_str_val(view_to_rov_str);
    ir_to_fix->set_is_instantiated(true);

    remove(v_view_name.begin(), v_view_name.end(), view_to_rov_str);
    remove(v_create_view_names_single.begin(), v_create_view_names_single.end(),
           view_to_rov_str);
    remove(v_table_names.begin(), v_table_names.end(), view_to_rov_str);

    if (is_debug_info) {
      cerr << "Dependency: In ContextUndefine of kDataViewName, removing "
              "view "
              "name: "
           << view_to_rov_str << "\n\n\n";
    }
  }

  /* kUse of kDataViewName */
  else if (ir_to_fix->data_type_ == DataViewName &&
           ir_to_fix->data_flag_ == ContextUse) {
    if (!v_view_name.size()) {
      if (is_debug_info) {
        cerr << "Dependency Error: In ContextUndefine of kDataViewname, "
                "cannot "
                "find view name defined before. \n\n\n";
      }
      return;
    }
    string view_str = vector_rand_ele(v_view_name);
    ir_to_fix->set_str_val(view_str);
    ir_to_fix->set_is_instantiated(true);
    v_table_names_single.push_back(view_str);

    if (is_debug_info) {
      cerr << "Dependency: In kUse of kDataViewName, using view name: "
           << view_str << "\n\n\n";
    }
  }

  return;
}

void Mutator::instan_partition_name(IR *ir_to_fix, bool is_debug_info) {

  /* Context Define, Context Use and ContextUndefine of partition name. */
  if (ir_to_fix->data_type_ == DataPartitionName &&
      ir_to_fix->data_flag_ == ContextDefine) {
    string new_partition_name_str = gen_partition_name();
    ir_to_fix->set_str_val(new_partition_name_str);
    ir_to_fix->set_is_instantiated(true);

    /* Get the table name that is mentioned by this statement. */
    string cur_table_name = "";
    if (v_create_table_names_single.size() != 0) {
      cur_table_name = v_create_table_names_single.back();
    } else if (v_table_names_single.size() != 0) {
      cur_table_name = vector_rand_ele(v_table_names_single);
    } else if (v_table_with_partition.size() != 0) {
      if (is_debug_info) {
        cerr << "Error: When trying to fetch data partition name in: "
                "partition name define. Cannot find table name defined "
                "in the statement. Use previous v_table_with_partition "
                "instead. ";
      }
      cur_table_name = vector_rand_ele(v_table_with_partition);
    } else if (v_table_names.size() != 0) {
      if (is_debug_info) {
        cerr << "Error: When trying to fetch data partition name in: "
                "partition name define. Cannot find table name defined "
                "in the statement. Use previous v_table_with_partition "
                "instead. ";
      }
      cur_table_name = vector_rand_ele(v_table_names);
    } else {
      if (is_debug_info) {
        cerr << "Error: When trying to fetch data partition name in: "
                "partition name define. Cannot find table name defined "
                "in the statement. Cannot find anything matched. Not able "
                " to connect to any table names. ";
      }
      return;
    }

    this->v_table_with_partition.push_back(cur_table_name);
    this->m_table2partition[cur_table_name].push_back(cur_table_name);

    if (is_debug_info) {
      cerr << "Dependency: In ContextDefine of DataPartitionName, "
              "generating data partition "
              "name: "
           << new_partition_name_str
           << ", attached to table name: " << cur_table_name << " \n\n\n";
    }
  }

  if (ir_to_fix->data_type_ == DataPartitionName &&
      ir_to_fix->data_flag_ == ContextUse) {

    ir_to_fix->set_is_instantiated(true);

    string cur_table_name = "";
    if (v_table_with_partition.size() > 0) {
      cur_table_name = vector_rand_ele(cur_table_name);
    } else {
      if (is_debug_info) {
        cerr << "Error: Inside Context Use of DataPartitionName, cannot "
                "find pre-defined table that contains partitions. "
                "Therefore, use dummy x for the partition name. \n";
      }
      ir_to_fix->set_str_val("x");
      // Skip the subsequent handling. Use the dummy `x`.
      return;
    }

    const vector<string> &all_partitions = m_table2partition[cur_table_name];
    if (all_partitions.size() == 0) {
      if (is_debug_info) {
        cerr << "Error: Inside Context Use of DataPartitionName, cannot "
                "find m_table2partition partitions. Table name is: "
             << cur_table_name
             << "Therefore, use dummy x for the partition name. \n";
      }
      ir_to_fix->set_str_val("x");
      // Skip the subsequent handling. Use the dummy `x`.
      return;
    }

    string used_partition_name = vector_rand_ele(all_partitions);
    ir_to_fix->set_str_val(used_partition_name);

    if (is_debug_info) {
      cerr << "Dependency: In kDefine of kDataViewName, using partition "
              "name: "
           << used_partition_name << ", matching from table: " << cur_table_name
           << "\n\n\n";
    }
    // Succeed. Continue to the next IR.
  }

  else if (ir_to_fix->data_type_ == DataPartitionName &&
           ir_to_fix->data_flag_ == ContextUndefine) {
    ir_to_fix->set_is_instantiated(true);

    string cur_table_name = "";
    if (v_table_with_partition.size() > 0) {
      cur_table_name = vector_rand_ele(cur_table_name);
    } else {
      if (is_debug_info) {
        cerr << "Error: Inside Context Use of DataPartitionName, cannot "
                "find pre-defined table that contains partitions. "
                "Therefore, use dummy x for the partition name. \n";
      }
      ir_to_fix->set_str_val("x");
      // Skip the subsequent handling. Use the dummy `x`.
      return;
    }

    vector<string> &all_partitions = m_table2partition[cur_table_name];
    if (all_partitions.size() == 0) {
      if (is_debug_info) {
        cerr << "Error: Inside Context Use of DataPartitionName, cannot "
                "find m_table2partition partitions. Table name is: "
             << cur_table_name
             << "Therefore, use dummy x for the partition name. \n";
      }
      ir_to_fix->set_str_val("x");
      // Skip the subsequent handling. Use the dummy `x`.
      return;
    }

    string used_partition_name = vector_rand_ele(all_partitions);
    ir_to_fix->set_str_val(used_partition_name);

    all_partitions.erase(std::remove(all_partitions.begin(),
                                     all_partitions.end(), used_partition_name),
                         all_partitions.end());
    if (all_partitions.size() == 0) {
      v_table_with_partition.erase(std::remove(v_table_with_partition.begin(),
                                               v_table_with_partition.end(),
                                               cur_table_name),
                                   v_table_with_partition.end());
    }

    if (is_debug_info) {
      cerr << "Dependency: In ContextUndefine of kDataPartitionName, "
              "removed partition name: "
           << used_partition_name << ", matching from table: " << cur_table_name
           << "\n\n\n";
    }
    // Succeed. Continue to the next IR.
  }

  return;
}

void Mutator::instan_index_name(IR *ir_to_fix, bool is_debug_info) {

  if (ir_to_fix->get_data_type() == DataIndexName) {
    if (ir_to_fix->get_data_flag() == ContextDefine) {
      string tmp_index_name = gen_index_name();
      ir_to_fix->set_str_val(tmp_index_name);
      ir_to_fix->set_is_instantiated(true);

      /* Find the table used in this stmt. */
      if (v_table_names_single.size() != 0) {
        string tmp_table_name = v_table_names_single[0];
        m_table2index[tmp_table_name].push_back(tmp_index_name);
      }
    } else if (ir_to_fix->get_data_flag() == ContextUndefine) {

      string tmp_index_name = "y";

      /* Find the table used in this stmt. */
      if (v_table_names_single.size() != 0) {
        string tmp_table_name = v_table_names_single[0];
        vector<string> &v_index_name = m_table2index[tmp_table_name];
        if (!v_index_name.size())
          return;
        tmp_index_name = vector_rand_ele(v_index_name);

        vector<string> tmp_v_index_name;
        for (string s : v_index_name) {
          if (s != tmp_index_name) {
            tmp_v_index_name.push_back(s);
          }
        }
        v_index_name = tmp_v_index_name;
      } else {
        for (auto it = m_table2index.begin(); it != m_table2index.end(); it++) {
          vector<string> &v_index_name = it->second;
          if (!v_index_name.size())
            continue;
          tmp_index_name = vector_rand_ele(v_index_name);

          vector<string> tmp_v_index_name;
          for (string s : v_index_name) {
            if (s != tmp_index_name) {
              tmp_v_index_name.push_back(s);
            }
          }
          v_index_name = tmp_v_index_name;
        }
      }
      if (tmp_index_name != "y") {
        ir_to_fix->set_str_val(tmp_index_name);
        ir_to_fix->set_is_instantiated(true);
      }
    }

    else if (ir_to_fix->get_data_flag() == ContextUse) {

      string tmp_index_name = "y";

      /* Find the table used in this stmt. */
      if (v_table_names_single.size() != 0) {
        string tmp_table_name = v_table_names_single[0];
        vector<string> &v_index_name = m_table2index[tmp_table_name];
        if (!v_index_name.size())
          return;
        tmp_index_name = vector_rand_ele(v_index_name);
      } else {
        for (auto it = m_table2index.begin(); it != m_table2index.end(); it++) {
          vector<string> &v_index_name = it->second;
          if (!v_index_name.size())
            continue;
          tmp_index_name = vector_rand_ele(v_index_name);
        }
      }
      if (tmp_index_name != "y") {
        ir_to_fix->set_str_val(tmp_index_name);
        ir_to_fix->set_is_instantiated(true);
      }
    }
  }

  return;
}

void Mutator::instan_column_name(IR *ir_to_fix, bool &is_replace_column,
                                 vector<IR *> &ir_to_deep_drop,
                                 bool is_debug_info) {

  if (p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeSetVar) ||
      p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeStorageParams)
          ) {
      return;
  }

  if (ir_to_fix->data_type_ == DataColumnName &&
      (ir_to_fix->data_flag_ == ContextDefine ||
       ir_to_fix->data_flag_ == ContextReplaceDefine)) {

    if (ir_to_fix->data_flag_ == ContextReplaceDefine) {
      is_replace_column = true;
    }
    string new_name = gen_column_name();
    ir_to_fix->str_val_ = new_name;
    ir_to_fix->set_is_instantiated(true);
    string closest_table_name = "";
    /* Attach the newly generated column name to the table. */
    if (v_create_table_names_single.size() > 0) {
      /* We have table name that is newly defined. Should be only one
       * newly created table name. */
      closest_table_name = v_create_table_names_single[0];
      if (is_debug_info) {
        cerr << "Dependency: For newly defined column name: " << new_name
             << ", we find v_create_table_names_single: " << closest_table_name
             << "\n\n\n";
      }
    } else if (v_table_names_single.size() != 0) {
      /* We cannot find the newly defined table name, see whether there are
       * local table name used, this is typical in ALTER statement.  */
      closest_table_name = v_table_names_single[0];
      if (is_debug_info) {
        cerr << "Dependency: For newly defined column name: " << new_name
             << ", cannot find v_create_table_names_single, is it in a "
                "ALTER statement? We find v_table_names_single: "
             << closest_table_name << "\n\n\n";
      }
    } else if (v_table_names.size() != 0) {
      /* This is an ERROR. Cannot find the TABLE name to attach to.
      ** 80% chance, keep original.
      ** 20% chance, find any declared table and attached to it. */
      if (get_rand_int(5) < 4) {
        /* Keep original */
        return;
      }
      closest_table_name = v_table_names[get_rand_int(v_table_names.size())];
      if (is_debug_info) {
        cerr << "Dependency ERROR: For newly defined column name: " << new_name
             << ", ERROR finding matched newly created table names. Used "
                "previous declared table name: "
             << closest_table_name << "\n\n\n";
      }
    }
    if (closest_table_name == "" || closest_table_name == "x" ||
        closest_table_name == "y") {
      if (is_debug_info) {
        cerr << "Dependency Error: Cannot find the closest_table_name from "
                "the query. ";
        cerr << "cloest_table_name returns: " << closest_table_name
             << "In kDataColumnName, kDefine or kReplace. \n\n\n";
      }
      // return false;
      /* Randomly set a name to the defined column.
       * And ignore the mapping for the moment
       * */

      /* Unrecognized, keep original */
      // ir_to_fix->str_val_ = gen_column_name();
      return;
    }
    if (is_debug_info) {
      cerr << "Dependency: For column_name: " << new_name
           << ", found closest_table_name: " << closest_table_name
           << ". \n\n\n";
    }

    // Avoid adding duplicated columns to the table mapping.
    vector<string> &cur_col_names = m_table2columns[closest_table_name];
    if (find(cur_col_names.begin(), cur_col_names.end(), new_name) ==
        cur_col_names.end()) {
      cur_col_names.push_back(new_name);
    }

    /* No need to map the current column to data types. */
    //        /* Next, fix the data type of the Column name. Map it to the
    //        column
    //         * name. */
    //        // The closest type to the current fixed node should be the one
    //        that
    //        // define the column type.
    //        IR *data_type_node =
    //                p_oracle->ir_wrapper.find_closest_nearby_IR_with_type<DATATYPE>(
    //                        ir_to_fix, DataTypeName);
    //        if (data_type_node != NULL) {
    //            DATAAFFINITYTYPE data_affinity =
    //                    get_data_affinity_by_string(data_type_node->get_str_val());
    //            DataAffinity data_affi;
    //            data_affi.set_data_affinity(data_affinity);
    //            m_column2datatype[new_name] = data_affi;
    //            m_datatype2column[data_affi.get_data_affinity()].push_back(new_name);
    //        } else {
    //            if (is_debug_info) {
    //                cerr << "Error: In a DataColumn ContextDefine, failed to
    //                find the "
    //                        "data type identifier that defined the "
    //                        "column data type. Use default AFFISTRING.
    //                        \n\n\n";
    //            }
    //            DataAffinity data_affi;
    //            data_affi.set_data_affinity(AFFISTRING);
    //            m_column2datatype[new_name] = data_affi;
    //            m_datatype2column[data_affi.get_data_affinity()].push_back(new_name);
    //        }

    /* ContextUndefine scenario of the DataColumnName */
  }

  else if (ir_to_fix->data_type_ == DataColumnName &&
           ir_to_fix->data_flag_ == ContextUndefine) {
    /* Find the table_name in the query first. */
    string closest_table_name = "";
    IR *closest_table_ir = NULL;
    closest_table_ir = p_oracle->ir_wrapper.find_closest_nearby_IR_with_type(
        ir_to_fix, DataTableName);
    if (closest_table_ir != NULL) {
      closest_table_name = closest_table_ir->get_str_val();
      if (is_debug_info) {
        cerr << "Dependency: For removing DataColumnName, we find "
                "closest_table_ir: "
             << closest_table_name << "\n\n\n";
      }
    } else if (v_table_names_single.size() != 0) {
      closest_table_name = v_table_names_single[0];
      if (is_debug_info) {
        cerr << "Dependency: For removing kDataColumnName: we find "
                "v_table_names_single: "
             << closest_table_name << "\n\n\n";
      }
    }
    if (closest_table_name == "" || closest_table_name == "x" ||
        closest_table_name == "y") {
      if (is_debug_info) {
        cerr << "Dependency Error: Cannot find the closest_table_name from "
                "the query. closest_table_name returns: "
             << closest_table_name << ". In kDataColumnName, kUndefine. \n\n\n";
      }
      /* Unrecognized, keep original */
      // return false;
      ir_to_fix->set_is_instantiated(true);
      return;
    }

    if (is_debug_info) {
      cerr << "Dependency: In kDataColumnName, kUndefine, found "
              "closest_table_name: "
           << closest_table_name << ". \n\n\n";
    }

    vector<string> &column_vec = m_table2columns[closest_table_name];
    if (column_vec.size() == 0) {
      if (is_debug_info) {
        cerr << "Dependency Error: Cannot find the mapped column_vec for "
                "table_name: "
             << closest_table_name << " \n\n\n";
      }
      /* Not reconized column name. Keep original */
      // ir_to_fix->str_val_ = "y";
      // return false;
      ir_to_fix->set_is_instantiated(true);
      return;
    }
    string removed_column_name = column_vec[get_rand_int(column_vec.size())];
    column_vec.erase(
        std::remove(column_vec.begin(), column_vec.end(), removed_column_name),
        column_vec.end());
    ir_to_fix->str_val_ = removed_column_name;
    ir_to_fix->set_is_instantiated(true);

    if (is_debug_info) {
      cerr << "Dependency: In kDataColumnName, kUndefine, found "
              "removed_column_name: "
           << removed_column_name
           << ", from closest_table_name: " << closest_table_name << ". \n\n\n";
    }

    return;
  }

  // Column name inside the TypeNameList.
  else if (ir_to_fix->data_type_ == DataColumnName &&
           ir_to_fix->data_flag_ == ContextUse &&
           p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeNameList) &&
           !p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeFamilyTableDef) // Not inside the FAMILY.
          ) {

    //        if (!(p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeNameList))) {
    //            // Ignore the case that is not in TypeNameList.
    //            return;
    //        }

    if (is_debug_info) {
      cerr << "\n\n\nHandling with column name inside the TypeNameList. "
              "Column Name: "
           << ir_to_fix->to_string() << ". \n\n\n";
    }

    ir_to_fix->set_is_instantiated(true);

    IR *name_list =
        p_oracle->ir_wrapper.get_parent_node_with_type(ir_to_fix, TypeNameList);

    string closest_table_name =
        this->find_cloest_table_name(name_list, is_debug_info);

    if (closest_table_name == "" || closest_table_name == "x" ||
        closest_table_name == "y") {
      if (is_debug_info) {
        cerr << "Dependency Error: Cannot find the closest_table_name from "
                "the query. Error cloest_table_name is: "
             << closest_table_name << ". In kDataColumnName, kUse. \n\n\n";
        return;
      }
    }

    vector<string> v_used_column_str;

    vector<string> v_column_names_from_table;
    if (m_alias_table2column_single.count(closest_table_name) > 0) {
      v_column_names_from_table =
          m_alias_table2column_single[closest_table_name];
    } else {
      v_column_names_from_table = m_table2columns[closest_table_name];
    }
    if (v_column_names_from_table.size() == 0) {
      if (is_debug_info) {
        cerr << "Dependency Error: Cannot find mapping from table name to "
                "column name. "
                "Find the closest_table_name from "
                "the query. Cloest_table_name is: "
             << closest_table_name << ". In kDataColumnName, kUse. \n\n\n";
      }
      return;
    }
    int max_values_clause_len = v_column_names_from_table.size();

    vector<IR *> v_new_column_list_node;
    string ret_str = "";
    for (int idx = 0; idx < max_values_clause_len;) {
      string new_rand_column = "";
      int trial = 10;
      do {
        new_rand_column = vector_rand_ele(v_column_names_from_table);
        if ((--trial) == 0) {
          break;
        }
      } while (find(v_used_column_str.begin(), v_used_column_str.end(),
                    new_rand_column) != v_used_column_str.end());
      if (is_debug_info) {
        cerr << "\n\n\n When reconstructing the column names inside the "
                "TypeNameList, "
             << ", getting random column name: " << new_rand_column << "\n\n\n";
      }
      v_used_column_str.push_back(new_rand_column);

      IR *new_column_node = new IR(TypeIdentifier, string(new_rand_column),
                                   DataColumnName, ContextNoModi);

      v_new_column_list_node.push_back(new_column_node);
      v_column_names_single.push_back(new_rand_column);

      idx++;
      if (get_rand_int(5) == 0) {
        // 1/5 chances, drop the value clause and no need for whole length
        // typelist.
        break;
      }
    }

    IR *new_name_list_expr = NULL;

    for (int idx = 0; idx < v_new_column_list_node.size(); idx++) {
      if (idx == 1) {
        continue;
      } else if (idx == 0) {
        IR *LNode = v_new_column_list_node[0];
        IR *RNode = nullptr;
        string infix = "";
        if (v_new_column_list_node.size() >= 2) {
          RNode = v_new_column_list_node[1];
          infix = ", ";
        }
        new_name_list_expr =
            new IR(TypeUnknown, OP3("", infix, ""), LNode, RNode);
      } else {
        // idx > 2
        IR *LNode = new_name_list_expr;
        IR *RNode = v_new_column_list_node[idx];

        new_name_list_expr =
            new IR(TypeUnknown, OP3("", ", ", ""), LNode, RNode);
      }
    }

    if (is_debug_info) {
      cerr << "\n\n\nDEPENDENCY: From the original name list: "
           << name_list->to_string();
    }

    IR *name_list_left_child = name_list->get_left();
    IR *name_list_right_child = name_list->get_right();
    if (name_list_left_child != nullptr) {
      ir_to_deep_drop.push_back(name_list_left_child);
    }
    if (name_list_right_child != nullptr) {
      ir_to_deep_drop.push_back(name_list_right_child);
    }
    p_oracle->ir_wrapper.iter_cur_node_with_handler(
        name_list, [](IR *cur_node) -> void {
          cur_node->set_is_instantiated(true);
          cur_node->set_data_flag(ContextNoModi);
        });
    name_list->update_left(nullptr);
    name_list->update_right(nullptr);

    new_name_list_expr->set_ir_type(TypeNameList);
    name_list->update_left(new_name_list_expr);
    name_list->op_->middle_ = "";
    name_list->set_is_instantiated(true);

    if (is_debug_info) {
      cerr << "   replaced to new name list: "
           << name_list->get_parent()->to_string() << "\n\n\n";
    }

    return;
  }

  else if (ir_to_fix->data_type_ == DataColumnName &&
           ir_to_fix->data_flag_ == ContextUse) {
    if (is_debug_info) {
      cerr << "Dependency: ori column name: " << ir_to_fix->str_val_
           << "\n\n\n";
      cerr << "In the kDataColumnName with kUse, found "
              "v_table_alias_names_single.size: "
           << v_table_alias_names_single.size() << "\n\n\n";
    }

    ir_to_fix->set_is_instantiated(true);

    // Actual random mutation of the ColumnName. ContextUse.
    string closest_table_name =
        this->find_cloest_table_name(ir_to_fix, is_debug_info);

    if (closest_table_name == "" || closest_table_name == "x" ||
        closest_table_name == "y") {
      if (is_debug_info) {
        cerr << "Dependency Error: Cannot find the closest_table_name from "
                "the query. Error closest_table_name is: "
             << closest_table_name << ". In kDataColumnName, kUse. \n\n\n";
        ir_to_fix->set_str_val("x");
        return;
      }
      bool is_found = false;
      if (v_table_alias_names_single.size() != 0) {
        closest_table_name = vector_rand_ele(v_table_alias_names_single);
        if (is_debug_info) {
          cerr << "Dependency: In column fixing, find table alias name from "
                  "v_table_alias_names_single: "
               << closest_table_name << ". \n\n\n";
        }
        is_found = true;
      }
      if (!is_found && v_table_names_single.size() != 0) {
        closest_table_name = vector_rand_ele(v_table_names_single);
        if (is_debug_info) {
          cerr << "Dependency: In column fixing, find table alias name from "
                  "v_table_names_single: "
               << closest_table_name << ". \n\n\n";
        }
        is_found = true;
      }

      if (!is_found) {
        ir_to_fix->set_str_val("x");
        if (is_debug_info) {
          cerr << "Dependency: In column fixing, failed to find any table "
                  "inside the statement. "
                  "dumping random x as column name. \n\n\n";
        }
        return;
      }
    }

    vector<string> cur_mapped_column_name_vec;
    if (m_alias_table2column_single.count(closest_table_name) > 0) {
      cur_mapped_column_name_vec =
          m_alias_table2column_single[closest_table_name];
    } else {
      cur_mapped_column_name_vec = m_table2columns[closest_table_name];
    }

    if (is_debug_info) {
      cerr << "Dependency: In kUse of kDataColunName, use origin table "
              "name: "
           << closest_table_name
           << ". column size is: " << cur_mapped_column_name_vec.size()
           << ". \n\n\n";
    }
    if (cur_mapped_column_name_vec.size() > 0) {
      string cur_chosen_column = cur_mapped_column_name_vec[get_rand_int(
          cur_mapped_column_name_vec.size())];
      ir_to_fix->str_val_ = cur_chosen_column;
      ir_to_fix->set_is_instantiated(true);
      if (m_column2datatype.count(cur_chosen_column)) {
        ir_to_fix->set_data_affinity(m_column2datatype[cur_chosen_column]);
      }

      if (!p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeValuesClause)) {
        v_column_names_single.push_back(cur_chosen_column);
        if (is_debug_info) {
          cerr << "Dependency: In kDataColumnName, kUse, we choose "
                  "closest_table_name: "
               << closest_table_name
               << " and column_name: " << cur_chosen_column << ". \n\n\n";
        }
      } else {
        if (is_debug_info) {
          cerr << "Dependency: In kDataColumnName, kUse, we choose "
                  "closest_table_name: "
               << closest_table_name
               << " and column_name: " << cur_chosen_column
               << ""
                  ", however, the column_name is in the VALUES clause, won't "
                  "saved.. \n\n\n";
        }
      }

    } else {
      /* Unreconized, keep original */
      // ir_to_fix->str_val_ = "y";
      ir_to_fix->set_is_instantiated(true);
      if (is_debug_info) {
        cerr << "Dependency Error: In kDataColumnName, kUse, cannot find "
                "mapping from table_name: "
             << closest_table_name << ". \n\n\n";
      }
    }
  }

  return;
}

void Mutator::instan_column_alias_name(IR *ir_to_fix, IR *cur_stmt_root,
                                       vector<IR *> &ir_to_deep_drop,
                                       bool is_debug_info) {

  if (ir_to_fix->data_type_ == DataColumnAliasName) {

    ir_to_fix->set_is_instantiated(true);

    string closest_table_alias_name = "";

    /* Three situations:
     * 1. TypeSelectExprs: `SELECT CustomerID AS ID, CustomerName AS
     * Customer FROM Customers;`
     * 2. TypeAliasClause: `SELECT c.x FROM (SELECT COUNT(*) FROM users) AS
     * c(x);`
     * 3. TypeAliasClause: WITH r(c) AS (SELECT * FROM v0 WHERE v1 = 100)
     * SELECT * FROM r WHERE c = 100;
     *
     * The 2 and 3 cases are similar.
     * */

    bool is_alias_clause = false;
    if (p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeAliasClause)) {
      is_alias_clause = true;
    }

    if (is_alias_clause) {
      /* Fix the TypeAliasClause scenario first.
       * This scenario must be handled before the ContextUse of
       * DataColumnName.
       * In this case, the TypeTableAlias is provided, we need to
       * connect the TypeTableAlias to the TypeColumnAlias.
       * Challenge: We need to make sure the number of
       * alise column matched the SELECT clause element in the subquery.
       * Luckily, we can ensure that when running in this scenario,
       * the subquery has already been instantiated, so that all the column
       * mappings are correct.
       */

      // First, check the nearby select subquery.
      IR *select_subquery =
          p_oracle->ir_wrapper.find_closest_nearby_IR_with_type(ir_to_fix,
                                                                TypeSelect);
      if (select_subquery != NULL && select_subquery != cur_stmt_root) {
        if (is_debug_info) {
          cerr << "\n\n\nDependency: when fixing the select subquery, "
                  "found select subquery: "
               << select_subquery->to_string() << "\n\n\n";
        }
      } else {
        if (is_debug_info) {
          cerr << "\n\n\nError: Cannot find the select subquery from the "
                  "current stmt. "
                  "skip the current statement fixing. \n\n\n";
        }
        return;
      }

      // Search whether there are columns defined in the `TypeSelectExprs`.
      vector<IR *> all_column_in_subselect =
          p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(select_subquery,
                                                             TypeSelectExpr);
      vector<IR *> all_table_in_subselect =
          p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(select_subquery,
                                                             DataTableName);
      vector<IR *> all_stars_in_subselect =
          p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(
              select_subquery, TypeUnqualifiedStar);

      // Try to handle the columns defined in the subquery first.
      // Only look at the columns defined in the SELECT clause:
      // e.g. `SELECT v1, v2 FROM v0`

      vector<IR *> ref_column_in_subselect;
      vector<string> new_column_alias_names;
      string ret_str = "";
      for (auto &cur_column_in_subselect : all_column_in_subselect) {
        if (p_oracle->ir_wrapper.is_ir_in(cur_column_in_subselect,
                                          TypeSelectExprs)) {
          if (is_debug_info) {
            cerr << "\n\n\nFound column name in TypeSelectExprs: "
                 << cur_column_in_subselect->to_string() << "\n\n\n";
          }
          ref_column_in_subselect.push_back(cur_column_in_subselect->get_left());
        }
      }

      int ref_col_idx = 0;
      if (ref_column_in_subselect.size() > 0) {
        for (auto &cur_column_in_sub : ref_column_in_subselect) {
          string cur_col_in_sub_str = cur_column_in_sub->get_str_val();
          string new_column_alias_name = gen_column_alias_name();
          m_alias2column_single[new_column_alias_name] = cur_col_in_sub_str;
          if (m_column2datatype.count(cur_col_in_sub_str) == 0 && cur_column_in_sub->get_ir_type() != TypeIdentifier) {
              m_column2datatype[cur_col_in_sub_str] = cur_column_in_sub->data_affinity;
          }
          new_column_alias_names.push_back(new_column_alias_name);
          if (ref_col_idx > 0) {
            ret_str += ", ";
          }
          ref_col_idx++;
          ret_str += new_column_alias_name;
          if (is_debug_info) {
            cerr << "\n\n\nMapping alias name: " << new_column_alias_name
                 << " to column name " << cur_col_in_sub_str
                 << " in TypeSelectExprs. ";
          }
        }
      }
      // Inherit the ref_col_idx.
      if (all_stars_in_subselect.size() > 0 &&
          all_table_in_subselect.size() > 0) {
        IR *cur_select_table = all_table_in_subselect.front();
        for (string &matched_column :
             m_table2columns[cur_select_table->get_str_val()]) {
          string new_column_alias_name = gen_column_alias_name();
          m_alias2column_single[new_column_alias_name] = matched_column;
          new_column_alias_names.push_back(new_column_alias_name);
          if (ref_col_idx > 0) {
            ret_str += ", ";
          }
          ref_col_idx++;
          ret_str += new_column_alias_name;
          if (is_debug_info) {
            cerr << "\n\n\nMapping alias name: " << new_column_alias_name
                 << " to column name " << matched_column
                 << " in TypeSelectExprs. ";
          }
        }
      }

      // Next, match the table alias name.
      IR *alias_table_ir =
          p_oracle->ir_wrapper.find_closest_nearby_IR_with_type<DATATYPE>(
              ir_to_fix, DataTableAliasName);
      string alias_table_str;
      if (alias_table_ir != NULL) {
        alias_table_str = alias_table_ir->get_str_val();
      } else {
        if (is_debug_info) {
          cerr << "\n\n\nError: Cannot find table alias name inside the "
                  "TypeAliasClause \n\n\n";
          ir_to_fix->set_str_val("x");
          return;
        }
      }

      for (string &cur_new_column_alias_name : new_column_alias_names) {
        m_alias_table2column_single[alias_table_str].push_back(
            cur_new_column_alias_name);
      }

      // Actually replace the current node.
      IR *alias_clause_ir = p_oracle->ir_wrapper.get_parent_node_with_type(
          ir_to_fix, TypeAliasClause);
      if (alias_clause_ir == NULL || alias_clause_ir->get_right() == NULL) {
        if (is_debug_info) {
          cerr << "\n\n\nLogical Error: Cannot find the TypeAliasClauseIR "
                  "from Columnaliaslist. \n\n\n";
        }
        return;
      }

      ir_to_deep_drop.push_back(alias_clause_ir->get_right());
      p_oracle->ir_wrapper.iter_cur_node_with_handler(
          alias_clause_ir->get_right(), [](IR *cur_node) -> void {
            cur_node->set_is_instantiated(true);
            cur_node->set_data_flag(ContextNoModi);
          });
      IR *new_column_alias_list = new IR(TypeColumnDefList, ret_str);
      alias_clause_ir->update_right(new_column_alias_list);

      return;

    } else {
      /* Fix the TypeSelectExprs scenario now.
       * No need for extra work for this scenario because it is
       * not very interesting.
       * 1. TypeSelectExprs: `SELECT CustomerID AS ID, CustomerName AS
       * Customer FROM Customers;`
       */

      IR *near_table_ir =
          p_oracle->ir_wrapper.find_closest_nearby_IR_with_type<DATATYPE>(
              ir_to_fix, DataTableName);
      string near_table_str;
      if (near_table_ir != NULL) {
        near_table_str = near_table_ir->get_str_val();
      } else {
        if (is_debug_info) {
          cerr << "\n\n\nError: Cannot find table alias name inside the "
                  "TypeAliasClause \n\n\n";
          ir_to_fix->set_str_val("x");
          return;
        }
      }

      string column_alias_name = gen_column_alias_name();
      ir_to_fix->set_str_val(column_alias_name);

      m_alias_table2column_single[near_table_str].push_back(column_alias_name);
      return;
    }
  }

  return;
}

void Mutator::instan_sql_type_name(IR *ir_to_fix, bool is_debug_info) {

  IRTYPE type = ir_to_fix->get_ir_type();
  DATATYPE data_type = ir_to_fix->get_data_type();
  DATAFLAG data_flag = ir_to_fix->get_data_flag();

  if (type == TypeIdentifier && data_type == DataTypeName &&
      data_flag == ContextDefine) {
    // Handling of the Column Data Type definition.
    // Use basic types.
    auto tmp_affi_type = get_random_affinity_type();
    string tmp_affi_type_str = get_affinity_type_str_formal(tmp_affi_type);

    ir_to_fix->set_str_val(tmp_affi_type_str);
    if (is_debug_info) {
      cerr << "\nFor data type definition, getting new data type: "
           << tmp_affi_type_str << "\n\n\n";
    }

    if (ir_to_fix->get_parent() && ir_to_fix->get_parent()->get_left() &&
        ir_to_fix->get_parent()->get_left()->get_data_type() ==
            DataColumnName) {
      DataAffinity cur_data_affi;
      cur_data_affi.set_data_affinity(tmp_affi_type);
      string column_str = ir_to_fix->get_parent()->get_left()->get_str_val();
      this->m_column2datatype[column_str] = cur_data_affi;
      this->m_datatype2column[cur_data_affi.get_data_affinity()].push_back(
          column_str);
      if (is_debug_info) {
        cerr << "\nAttach data affinity: "
             << get_string_by_affinity_type(cur_data_affi.get_data_affinity())
             << " to column: " << column_str << ". \n\n\n";
      }
    }
  }
}

void Mutator::instan_foreign_table_name(IR *ir_to_fix, bool is_debug_info) {

  /* TODO: FIXME: Foreign table handling. Add it back later. */
  //    if (
  //        (
  //          ir_to_fix->data_type_ == kDataForeignTableName
  //        ) &&
  //        ir_to_fix->data_flag_ == kUndefine)
  //      {
  //        if (v_foreign_table_name.size() > 0 ) {
  //          /* Find table name in the foreign table vector, not normal
  //          table vec.  */ string removed_table_name =
  //          v_foreign_table_name[get_rand_int(v_foreign_table_name.size())];
  //          v_foreign_table_name.erase(std::remove(v_foreign_table_name.begin(),
  //          v_foreign_table_name.end(), removed_table_name),
  //          v_foreign_table_name.end());
  //
  //          v_table_names.erase(std::remove(v_table_names.begin(),
  //          v_table_names.end(), removed_table_name),
  //          v_table_names.end());
  //          v_table_names_single.erase(std::remove(v_table_names_single.begin(),
  //          v_table_names_single.end(), removed_table_name),
  //          v_table_names_single.end()); ir_to_fix->str_val_ =
  //          removed_table_name; fixed_ir.push_back(ir_to_fix); if
  //          (is_debug_info) {
  //            cerr << "Dependency: Removed from v_foreign_table_names: "
  //            << removed_table_name << ", in kDataForeignTableName with
  //            kUndefine \n\n\n";
  //          }
  //          if (is_replace_table &&
  //          v_create_foreign_table_names_single.size() != 0) {
  //            string new_table_name =
  //            v_create_foreign_table_names_single.front();
  //            m_table2columns[new_table_name] =
  //            m_table2columns[removed_table_name];
  //          }
  //
  //        } else {
  //          if (is_debug_info) {
  //            cerr << "Dependency Error: Failed to find info in
  //            v_foreign_table_names, in kDataForeignTableName with
  //            kUndefine. \n\n\n";
  //          }
  //          /* Unreconized, keep original */
  //          // ir_to_fix->str_val_ = "y";
  //          fixed_ir.push_back(ir_to_fix);
  //        }
  //
  //      }
}

void Mutator::instan_statistic_name(IR *ir_to_fix, bool is_debug_info) {

  if (ir_to_fix->get_data_type() == DataStatsName) {
    if (ir_to_fix->get_data_flag() == ContextDefine) {
      string cur_chosen_name = gen_statistic_name();
      ir_to_fix->set_str_val(cur_chosen_name);
      ir_to_fix->set_is_instantiated(true);
      v_statistics_name.push_back(cur_chosen_name);
    }

    else if (ir_to_fix->get_data_flag() == ContextUndefine) {
      if (!v_statistics_name.size())
        return;
      string cur_chosen_name = vector_rand_ele(v_statistics_name);
      ir_to_fix->set_str_val(cur_chosen_name);
      ir_to_fix->set_is_instantiated(true);

      /* remove the statistic name from the vector */
      vector<string> v_tmp;
      for (string &s : v_statistics_name) {
        if (s != cur_chosen_name) {
          v_tmp.push_back(s);
        }
      }
      v_statistics_name = v_tmp;
    }

    else if (ir_to_fix->get_data_flag() == ContextUse) {
      if (!v_statistics_name.size())
        return;
      string cur_chosen_name = vector_rand_ele(v_statistics_name);
      ir_to_fix->set_str_val(cur_chosen_name);
      ir_to_fix->set_is_instantiated(true);
    }
  }

  return;
}

void Mutator::instan_sequence_name(IR *ir_to_fix, bool is_debug_info) {

  /* Fix for kDataSequenceName */
  if (ir_to_fix->get_data_type() == DataSequenceName) {
    ir_to_fix->set_is_instantiated(true);
    if (ir_to_fix->get_data_flag() == ContextDefine) {
      // string cur_chosen_name = gen_sequence_name();
      // ir_to_fix->set_str_val(cur_chosen_name);

      /* Yu: Do not fix for sequence name for now */
      string cur_chosen_name = ir_to_fix->get_str_val();
      v_sequence_name.push_back(cur_chosen_name);
    }

    else if (ir_to_fix->get_data_flag() == ContextUndefine) {
      if (!v_sequence_name.size())
        return;
      string cur_chosen_name = vector_rand_ele(v_sequence_name);
      ir_to_fix->set_str_val(cur_chosen_name);

      /* remove the statistic name from the vector */
      vector<string> v_tmp;
      for (string &s : v_sequence_name) {
        if (s != cur_chosen_name) {
          v_tmp.push_back(s);
        }
      }
      v_sequence_name = v_tmp;
    }

    else if (ir_to_fix->get_data_flag() == ContextUse) {
      if (!v_sequence_name.size())
        return;
      string cur_chosen_name = vector_rand_ele(v_sequence_name);
      ir_to_fix->set_str_val(cur_chosen_name);
    }
  }

  return;
}

void Mutator::instan_constraint_name(IR *ir_to_fix, bool is_debug_info) {

  /* Fix for kDataConstraintName */
  if (ir_to_fix->get_data_type() == DataConstraintName) {
    ir_to_fix->set_is_instantiated(true);
    if (ir_to_fix->get_data_flag() == ContextDefine) {

      string cur_chosen_name = gen_constraint_name();
      ir_to_fix->set_str_val(cur_chosen_name);
      v_constraint_name.push_back(cur_chosen_name);
    }

    else if (ir_to_fix->get_data_flag() == ContextUndefine) {
      if (!v_constraint_name.size())
        return;
      string cur_chosen_name = vector_rand_ele(v_constraint_name);
      ir_to_fix->set_str_val(cur_chosen_name);

      /* remove the statistic name from the vector */
      vector<string> v_tmp;
      for (string &s : v_constraint_name) {
        if (s != cur_chosen_name) {
          v_tmp.push_back(s);
        }
      }
      v_constraint_name = v_tmp;
    }

    else if (ir_to_fix->get_data_flag() == ContextUse) {
      if (!v_constraint_name.size())
        return;
      string cur_chosen_name = vector_rand_ele(v_constraint_name);
      ir_to_fix->set_str_val(cur_chosen_name);
    }
  }

  return;
}

void Mutator::instan_family_name(IR *ir_to_fix, bool is_debug_info) {

  /* Fix for DataFamilyName */
  if (ir_to_fix->get_data_type() == DataFamilyName) {
    ir_to_fix->set_is_instantiated(true);
    if (ir_to_fix->get_data_flag() == ContextDefine) {

      string cur_chosen_name = gen_family_name();
      ir_to_fix->set_str_val(cur_chosen_name);
      v_family_name.push_back(cur_chosen_name);
    }

    else if (ir_to_fix->get_data_flag() == ContextUndefine) {
      if (!v_family_name.size())
        return;
      string cur_chosen_name = vector_rand_ele(v_family_name);
      ir_to_fix->set_str_val(cur_chosen_name);

      /* remove the statistic name from the vector */
      vector<string> v_tmp;
      for (string &s : v_family_name) {
        if (s != cur_chosen_name) {
          v_tmp.push_back(s);
        }
      }
      v_family_name = v_tmp;
    }

    else if (ir_to_fix->get_data_flag() == ContextUse) {
      if (!v_family_name.size())
        return;
      string cur_chosen_name = vector_rand_ele(v_family_name);
      ir_to_fix->set_str_val(cur_chosen_name);
    }
  }

  return;
}

void Mutator::instan_literal(IR *ir_to_fix, IR *cur_stmt_root,
                             vector<IR *> &ir_to_deep_drop,
                             bool is_debug_info) {

  /* First Loop */

  IRTYPE type = ir_to_fix->get_ir_type();

  if ((type == TypeFloatLiteral || type == TypeStringLiteral ||
       type == TypeIntegerLiteral) &&
      p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeExprs)) {
    /* Completely rewritten Literal handling and mutation logic.
     * The idea is to search for the closest Column Name or fixed literals,
     * and try to match the type of the column name or literal.
     * */

    if (p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeOptStorageParams) ||
        p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeSetVar)) {
      /*
       * Should not change any literals inside the TypeOptStorageParams and
       * TypeSetVar clause. These literals are for Storage Parameters (Storage
       * Settings) or SET parameters. These values will be fixed by another
       * fixing function, later in the second ir_to_fix loop.
       * */
      return;
    }

    ir_to_fix->set_is_instantiated(true);

    // Handle the ValuesClause.
    // Get the TypeExprsNode first.
    IR *type_exprs_node =
        p_oracle->ir_wrapper.get_parent_node_with_type(ir_to_fix, TypeExprs);

    if (is_debug_info) {
      cerr << "\n\n\nDependency: INFO: Removing the original VALUES clause "
              "expression:"
           << type_exprs_node->to_string() << "\n\n\n";
    }

    // Remove the original expressions.
    IR *type_exprs_left_node = type_exprs_node->get_left();
    type_exprs_node->update_left(nullptr);
    // Avoid further handling of the child node from `TypeValueClauses`
    p_oracle->ir_wrapper.iter_cur_node_with_handler(
        type_exprs_left_node, [](IR *cur_node) -> void {
          cur_node->set_is_instantiated(true);
          cur_node->set_data_flag(ContextNoModi);
        });
    ir_to_deep_drop.push_back(type_exprs_left_node);

    IR *type_exprs_right_node = type_exprs_node->get_right();
    type_exprs_node->update_right(nullptr);
    // Avoid further handling of the child node from `TypeValueClauses`
    p_oracle->ir_wrapper.iter_cur_node_with_handler(
        type_exprs_right_node, [](IR *cur_node) -> void {
          cur_node->set_is_instantiated(true);
          cur_node->set_data_flag(ContextNoModi);
        });
    ir_to_deep_drop.push_back(type_exprs_right_node);
    type_exprs_node->op_->middle_ = "";

    /* Reconstruct the new type expressions clause that matched the referenced
     * table.
     */

    if (p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeINExpr)) {
      /* Fix for the IN clause. */
      vector<DATATYPE> search_type = {DataColumnName, DataColumnAliasName};
      vector<IRTYPE> cap_type = {TypeSelect};
      IR *closet_column_node =
          p_oracle->ir_wrapper.find_closest_nearby_IR_with_type(
              ir_to_fix, search_type, cap_type);

      if (closet_column_node == nullptr) {
        if (is_debug_info) {
          cerr << "\n\n\nLOGIC ERROR: Inside the IN clause, cannot find the "
                  "nearby column name. Do not fix. Return. \n\n\n";
        }
        return;
      }

      string col_str = closet_column_node->get_str_val();
      DataAffinity col_affi = m_column2datatype[col_str];

      // Avoid 0.
      int num_of_in_elem = get_rand_int(5) + 1;

      string ret_str = "";
      for (int in_idx = 0; in_idx < num_of_in_elem; in_idx++) {

        if (in_idx != 0) {
          ret_str += ", ";
        }
        ret_str += col_affi.get_mutated_literal();
      }

      IR *new_type_exprs_node = new IR(TypeStringLiteral, ret_str);
      new_type_exprs_node->set_is_instantiated(true);

      type_exprs_node->update_left(new_type_exprs_node);

      if (is_debug_info) {
        cerr << "\n\n\nDependency: getting new IN clause expression: "
             << new_type_exprs_node->to_string() << ". \n\n\n";
      }

      p_oracle->ir_wrapper.iter_cur_node_with_handler(
          type_exprs_left_node, [](IR *cur_node) -> void {
            cur_node->set_is_instantiated(true);
            cur_node->set_data_flag(ContextNoModi);
          });

      return;
    } // IN clause

    /* else, VALUE clause only?  */

    // Search whether there are referenced columns in the `TypeNameList`.
    // If there is, should be the first TypeNameList from the statement.
    vector<IR *> v_type_name_list =
        p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(cur_stmt_root,
                                                           TypeNameList, false);

    vector<DataAffinity> referencing_affinity;
    if (v_type_name_list.size() == 0) {
      // Cannot find a specifically referenced column name list.
      // Use the referenced table name to refer to the column name list.
      if (is_debug_info) {
        cerr << "\n\n\nDependency: Cannot find the column name list from "
                "the statement. \n\n\n";
      }

      // Find the table name used in this statement.
      if (v_table_names_single.size() == 0) {
        if (is_debug_info) {
          cerr << "\n\n\nERROR: Cannot find the column name list AND table "
                  "name from the statement. \n\n\n";
        }
        DataAffinity cur_affi;
        cur_affi.set_data_affinity(AFFISTRING);
        referencing_affinity.push_back(cur_affi);
      } else {
        // Found the table name referenced from the statement.
        if (is_debug_info) {
          cerr << "\n\n\nFound the table name referenced from the "
                  "statement, "
                  "table name: "
               << v_table_names_single.front() << ". \n\n\n";
        }
        string cur_table_name = v_table_names_single.front();
        vector<string> column_list;
        bool is_alias = false;
        if (m_alias_table2column_single.count(cur_table_name) > 0) {
          is_alias = true;
          column_list = m_alias_table2column_single[cur_table_name];
        } else {
          is_alias = false;
          column_list = m_table2columns[cur_table_name];
        }
        for (const string &cur_column_str : column_list) {
          string actual_column_str = cur_column_str;
          if (is_alias && m_alias2column_single.count(actual_column_str) > 0) {
            if (is_debug_info) {
              cerr << "\n\n\nDependency: INFO: In literal fixing, mapping the "
                      "column alias: "
                   << cur_column_str << " to column name: " << actual_column_str
                   << "\n\n\n";
            }
            actual_column_str = m_alias2column_single[cur_column_str];
          }
          if (m_column2datatype.count(actual_column_str) > 0) {
            DataAffinity cur_affi = m_column2datatype[actual_column_str];
            referencing_affinity.push_back(cur_affi);
            if (is_debug_info) {
              cerr << "\n\n\nMatching column: " << cur_column_str
                   << " from table: " << cur_table_name << " with data type: "
                   << get_string_by_affinity_type(cur_affi.get_data_affinity())
                   << "\n\n\n";
            }
          } else {
            DataAffinity cur_affi;
            cur_affi.set_data_affinity(AFFISTRING);
            referencing_affinity.push_back(cur_affi);
            if (is_debug_info) {
              cerr << "\n\n\n Cannot find matching column types: "
                   << cur_column_str << ". Using dummy AFFISTRING instead. "
                   << "\n\n\n";
            }
          }
        }
      }
    } else {
      if (is_debug_info) {
        cerr << "\n\n\nDependency: Find the column name list from the stmt:"
             << v_type_name_list.front()->to_string() << ". \n\n\n";
      }

      IR *type_list_node = v_type_name_list.front();
      vector<string> &v_column_str = this->v_column_names_single;
      if (v_column_str.size() != 0) {
        for (string &cur_column_str : v_column_str) {
          string actual_column_str = cur_column_str;
          if (m_alias2column_single.count(cur_column_str)) {
            actual_column_str = m_alias2column_single[cur_column_str];
            if (is_debug_info) {
              cerr << "\n\n\nDependency: INFO: In literal fixing, mapping the "
                      "column alias: "
                   << cur_column_str << " to column name: " << actual_column_str
                   << "\n\n\n";
            }
          }
          DataAffinity cur_affi = m_column2datatype[actual_column_str];
          referencing_affinity.push_back(cur_affi);
          if (is_debug_info) {
            cerr << "\n\n\nMatching column: " << cur_column_str
                 << " with data type: "
                 << get_string_by_affinity_type(cur_affi.get_data_affinity())
                 << "\n\n\n";
          }
        }
      }

      else {

        vector<IR *> v_column_node =
            p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(
                type_list_node, DataColumnName, false);
        for (IR *cur_column_node : v_column_node) {
          string cur_column_str = cur_column_node->get_str_val();
          if (m_column2datatype.count(cur_column_str) ||
              m_alias2column_single.count(cur_column_str)) {
            string actual_column_str = cur_column_str;
            if (m_alias2column_single.count(cur_column_str)) {
              actual_column_str = m_alias2column_single[cur_column_str];
              if (is_debug_info) {
                cerr << "\n\n\nDependency: INFO: In literal fixing, mapping "
                        "the column alias: "
                     << cur_column_str
                     << " to column name: " << actual_column_str << "\n\n\n";
              }
            }
            DataAffinity cur_affi = m_column2datatype[actual_column_str];
            referencing_affinity.push_back(cur_affi);
            if (is_debug_info) {
              cerr << "\n\n\nMatching column: " << cur_column_str
                   << " with data type: "
                   << get_string_by_affinity_type(cur_affi.get_data_affinity())
                   << "\n\n\n";
            }
          } else {
            DataAffinity cur_affi;
            cur_affi.set_data_affinity(AFFISTRING);
            referencing_affinity.push_back(cur_affi);
            if (is_debug_info) {
              cerr << "\n\n\n Cannot find matching column types: "
                   << cur_column_str << ". Using dummy AFFISTRING instead. "
                   << "\n\n\n";
            }
          }
        }
      }
    }

    // After we get a list of referencing_affinity, we can now begin to fill
    // in the ValuesClause expression.
    string ret_str = "";
    int idx = 0;
    for (DataAffinity &cur_affi : referencing_affinity) {
      if (idx != 0) {
        ret_str += ", ";
      }
      ret_str += cur_affi.get_mutated_literal();
      idx++;
    }
    IR *new_values_expr_node = new IR(TypeStringLiteral, ret_str);
    new_values_expr_node->set_is_instantiated(true);

    type_exprs_node->update_left(new_values_expr_node);

    if (is_debug_info) {
      cerr << "\n\n\nDependency: getting new values clause expression: "
           << new_values_expr_node->to_string() << ". \n\n\n";
    }

    p_oracle->ir_wrapper.iter_cur_node_with_handler(
        type_exprs_left_node, [](IR *cur_node) -> void {
          cur_node->set_is_instantiated(true);
          cur_node->set_data_flag(ContextNoModi);
        });

    return;
  }

  /* The second loop */

  type = ir_to_fix->get_ir_type();

  if (type == TypeFloatLiteral || type == TypeStringLiteral ||
      type == TypeIntegerLiteral) {
    /* Continue from the previous loop, we now search around the ir_to_fix
     * and see if we can find column name or literals that can help deduce
     * Data Affinity.
     * */

    if (p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeOptStorageParams) ||
        p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeSetVar)) {
      /*
       * Should not change any literals inside the TypeOptStorageParams and
       * TypeSetVar clause. These literals are for Storage Parameters (Storage
       * Settings) or SET parameters. These values will be fixed by another
       * fixing function, later in the second ir_to_fix loop.
       * */
      return;
    }

    ir_to_fix->set_is_instantiated(true);

    if (is_debug_info) {
      cerr << "\n\n\nTrying to fix literal: " << ir_to_fix->to_string()
           << "\n\n\n";
    }

    // If the literal already has fixed data affinity type, skip the
    // mutation.
    if (ir_to_fix->get_data_flag() == ContextNoModi) {
      if (is_debug_info) {
        cerr << "\n\n\nSkip fixing literal: " << ir_to_fix->to_string()
             << " because it has "
                "flag ContextNoModi. \n\n\n";
      }
      return;
    }
    //          if (ir_to_fix->get_data_affinity() != AFFIUNKNOWN) {
    //              continue;
    //          }

    if (p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeSetVar)) {
      // Do not mutate the literals inside the SET statement.
      // The set statement's literal has already been fixed when introduced.
      return;
    }

    ir_to_fix->set_data_affinity(
        this->get_nearby_data_affinity(ir_to_fix, is_debug_info));

    /* After knowing the data affinity of the literal,
     * we have two choices to instantiate the value.
     * 1. If the current data affinity is the same as previous
     * fixed literals, reuse the value.
     * 2. Mutate to get a new value.
     * */
    if (m_datatype2literals[ir_to_fix->get_data_affinity()].size() != 0 &&
        get_rand_int(2) == 0) {
      // Reuse previous defined literals.
      string tmp_new_literal =
          vector_rand_ele(m_datatype2literals[ir_to_fix->get_data_affinity()]);
      ir_to_fix->set_str_val(tmp_new_literal);
    } else {
      // Now we ensure the ir_to_fix has an affinity.
      // Mutate the literal with the affinity
      ir_to_fix->mutate_literal(); // Handles everything.
      m_datatype2literals[ir_to_fix->get_data_affinity()].push_back(
          ir_to_fix->get_str_val());
    }
  }

  return;
}

void Mutator::instan_storage_param(IR *ir_to_fix, vector<IR *> &ir_to_deep_drop,
                                   bool is_debug_info) {

  IRTYPE type = ir_to_fix->get_ir_type();
  DATATYPE data_type = ir_to_fix->get_data_type();

  if (type == TypeStorageParams && data_type == DataStorageParams) {

    if (ir_to_fix->get_parent() == NULL) {
      cerr << "\n\n\nLogical Error: Getting empty parent from "
              "TypeStorageParams. \n\n\n";
    }

    IR *opt_storage_params = ir_to_fix->get_parent();

    IR *opt_storage_params_left = opt_storage_params->get_left();
    IR *opt_storage_params_right = opt_storage_params->get_right();

    if (opt_storage_params_left != NULL) {
      p_oracle->ir_wrapper.iter_cur_node_with_handler(
          opt_storage_params_left, [](IR *cur_node) -> void {
            cur_node->set_is_instantiated(true);
            cur_node->set_data_flag(ContextNoModi);
          });
      ir_to_deep_drop.push_back(opt_storage_params_left);
    }
    if (opt_storage_params_right != NULL) {
      p_oracle->ir_wrapper.iter_cur_node_with_handler(
          opt_storage_params_right, [](IR *cur_node) -> void {
            cur_node->set_is_instantiated(true);
            cur_node->set_data_flag(ContextNoModi);
          });
      ir_to_deep_drop.push_back(opt_storage_params_right);
    }

    // Do not use param_num == 0;
    IR *new_storage_param_node =
        this->constr_rand_storage_param(get_rand_int(3) + 1);
    new_storage_param_node->set_is_instantiated(true);
    opt_storage_params->update_left(new_storage_param_node);
    opt_storage_params->update_right(NULL);
  }

  return;
}

void Mutator::map_create_view(IR *ir_to_fix, IR *cur_stmt_root,
                              const vector<vector<IR *>> cur_stmt_ir_to_fix_vec,
                              bool is_debug_info) {

  if (ir_to_fix->data_type_ != DataTableName &&
      ir_to_fix->data_type_ != DataViewName) {
    return;
  }

  /* Add missing mapping for CREATE VIEW stmt.  */
  /* Check whether we are in the CreateViewStatement. If yes, save the
   * column mapping. */
  IR *cur_ir = ir_to_fix;
  bool is_in_create_view = false;
  if (cur_stmt_root->get_ir_type() == TypeCreateView) {
    is_in_create_view = true;
  }
  if (is_in_create_view) {
    /* Added column mapping for CREATE TABLE/VIEW... v0 AS SELECT...
     * statement.
     */
    if (is_debug_info) {
      cerr << "Dependency: In CREATE VIEW statement, getting "
              "cur_stmt_ir_to_fix_vec.size: "
           << cur_stmt_ir_to_fix_vec.size() << ". \n\n\n";
    }
    // id_column_name should be in the subquery and already been resolved
    // in the previous loop.
    vector<IR *> tmp_column_vec;
    vector<IR *> all_mentioned_column_vec;
    set<DATATYPE> column_type_set = {DataColumnName};
    collect_ir(cur_stmt_root, column_type_set, all_mentioned_column_vec);

    for (IR *cur_mentioned_column : all_mentioned_column_vec) {
      if (p_oracle->ir_wrapper.is_ir_in(cur_mentioned_column,
                                        TypeSelectExprs)) {
        tmp_column_vec.push_back(cur_mentioned_column);
      }
    }
    all_mentioned_column_vec = tmp_column_vec;
    tmp_column_vec.clear();

    /* Fix: also, add column alias name defined here to the table */
    vector<IR *> all_mentioned_column_alias_vec;
    set<DATATYPE> column_alias_type_set = {DataColumnAliasName};
    collect_ir(cur_stmt_root, column_alias_type_set,
               all_mentioned_column_alias_vec);

    for (IR *cur_mentioned_alias : all_mentioned_column_alias_vec) {
      if (p_oracle->ir_wrapper.is_ir_in(cur_mentioned_alias, TypeSelectExprs)) {
        tmp_column_vec.push_back(cur_mentioned_alias);
      }
    }
    all_mentioned_column_alias_vec = tmp_column_vec;
    tmp_column_vec.clear();

    if (is_debug_info) {
      cerr << "Dependency: When building extra mapping for CREATE VIEW AS, "
              "collected kDataColumnName.size: "
           << all_mentioned_column_vec.size() << ". \n\n\n";
    }

    if (all_mentioned_column_alias_vec.size() != 0) {
      m_table2columns[ir_to_fix->get_str_val()].clear();
      for (auto &cur_column_alias_ir : all_mentioned_column_alias_vec) {
        string cur_column_alias = cur_column_alias_ir->get_str_val();
        vector<string>& v_view_column_str = m_table2columns[ir_to_fix->get_str_val()];
        if (find(v_view_column_str.begin(), v_view_column_str.end(), cur_column_alias) == v_view_column_str.end()) {
            v_view_column_str.push_back(cur_column_alias);
        }
        if (is_debug_info) {
          cerr << "Dependency: Adding mappings: For table/view: "
               << ir_to_fix->str_val_
               << ", map from column alias to column str: " << cur_column_alias
               << ". \n\n\n";
        }
      }
    } else {
      for (const IR *const cur_men_column_ir : all_mentioned_column_vec) {
        string cur_men_column_str = cur_men_column_ir->str_val_;
        if (findStringIn(cur_men_column_str, ".")) {
          vector<string> v_cur_men_column_str =
              string_splitter(cur_men_column_str, '.');
          cur_men_column_str =
              v_cur_men_column_str[v_cur_men_column_str.size() - 1];
        }
        vector<string> &cur_m_table = m_table2columns[ir_to_fix->str_val_];
        if (std::find(cur_m_table.begin(), cur_m_table.end(),
                      cur_men_column_str) == cur_m_table.end()) {
          m_table2columns[ir_to_fix->str_val_].push_back(cur_men_column_str);
          if (is_debug_info) {
            cerr << "Dependency: Adding mappings: For table/view: "
                 << ir_to_fix->str_val_
                 << ", map with column: " << cur_men_column_str << ". \n\n\n";
          }
        }
      }

      /* For CREATE VIEW x AS SELECT * FROM v0; */
      if (all_mentioned_column_vec.size() == 0) {
        if (is_debug_info) {
          cerr << "Dependency: For mapping CREATE VIEW, cannot find column "
                  "name in the current subqueries. Thus, see if we can find "
                  "table names, and map from there. \n\n\n";
        }
        vector<IR *> all_mentioned_table_vec, all_mentioned_table_kUsed_vec;
        set<DATATYPE> table_type_set = {DataTableName};
        collect_ir(cur_stmt_root, table_type_set, all_mentioned_table_vec);
        for (IR *mentioned_table_ir : all_mentioned_table_vec) {
          if (mentioned_table_ir->data_flag_ == ContextUse) {
            all_mentioned_table_kUsed_vec.push_back(mentioned_table_ir);
            if (is_debug_info) {
              cerr << "Dependency: For mapping CREATE VIEW, getting "
                      "mentioned table name: "
                   << mentioned_table_ir->str_val_ << ". \n\n\n";
            }
          }
        }
        for (IR *cur_men_tablename_ir : all_mentioned_table_kUsed_vec) {
          string cur_men_tablename_str = cur_men_tablename_ir->str_val_;
          const vector<string> &cur_men_column_vec =
              m_table2columns[cur_men_tablename_str];
          for (const string &cur_men_column_str : cur_men_column_vec) {
            vector<string> &cur_m_table = m_table2columns[ir_to_fix->str_val_];
            if (std::find(cur_m_table.begin(), cur_m_table.end(),
                          cur_men_column_str) == cur_m_table.end()) {
              m_table2columns[ir_to_fix->str_val_].push_back(
                  cur_men_column_str);
              if (is_debug_info) {
                cerr << "Dependency: Adding mappings: For table/view: "
                     << ir_to_fix->str_val_
                     << ", map with column: " << cur_men_column_str
                     << ". \n\n\n";
              }
            }
          }
        } // for (IR* cur_men_tablename_ir : all_mentioned_table_kUsed_vec)
      }   // if (all_mentioned_column_vec.size() == 0)
    }

    /* The extra mapping only need to be done once. Once reach this point,
     * break the loop. */
    return;
  } // if (is_in_create_view)
}

void Mutator::map_create_view_column(IR *ir_to_fix,
                                     vector<IR *> &ir_to_deep_drop,
                                     bool is_debug_info) {

  IR *type_name_list =
      p_oracle->ir_wrapper.get_parent_node_with_type(ir_to_fix, TypeNameList);
  if (type_name_list == NULL) {
    if (is_debug_info) {
      cerr << "\n\n\nError: In DataViewColumnName fixing. Cannot find the "
              "type_name_list from the statement."
              "More debug info, view column is: "
           << ir_to_fix->to_string() << ". \n\n\n";
    }
    return;
  }

  string ret_str = "";
  IR *near_view_name_node =
      p_oracle->ir_wrapper.find_closest_nearby_IR_with_type(ir_to_fix,
                                                            DataViewName);
  if (near_view_name_node == NULL) {
    if (is_debug_info) {
      cerr << "\n\n\nError: In DataViewColumnName fixing. Cannot find the "
              "near_view_name from the "
              "statement. More debug info, view column is: "
           << ir_to_fix->to_string() << ". \n\n\n";
    }
  }
  string near_view_name_str = near_view_name_node->to_string();
  vector<string> matched_columns = m_table2columns[near_view_name_str];

  vector<string> v_new_view_col_name_str;
  int view_col_idx = 0;
  for (string cur_matched_columns : matched_columns) {
    string new_view_column_name = gen_view_column_name();
    v_new_view_col_name_str.push_back(new_view_column_name);
    m_column2datatype[new_view_column_name] =
        m_column2datatype[cur_matched_columns];
    m_datatype2column[m_column2datatype[cur_matched_columns]
                          .get_data_affinity()]
        .push_back(new_view_column_name);

    if (view_col_idx != 0) {
      ret_str += ", ";
    }

    view_col_idx++;
    ret_str += new_view_column_name;

    if (is_debug_info) {
      cerr
          << "\n\n\nDependency: INFO:: Transporting data affinity from column: "
          << cur_matched_columns << " to view column: " << new_view_column_name
          << ", with affinity: "
          << get_string_by_affinity_type(
                 m_column2datatype[new_view_column_name].get_data_affinity())
          << ". \n\n\n";
    }
  }

  m_table2columns[near_view_name_str] = v_new_view_col_name_str;

  if (is_debug_info) {
    for (string &view_col_name : v_new_view_col_name_str) {
      cerr << "\n\n\nDependency: INFO:: Appending new view column: "
           << view_col_name << " to view: " << near_view_name_str << ". \n\n\n";
    }
  }

  // At last, switch the whole TypeNameList node in the Create View column
  // clause.
  //            ret_str = "(" + ret_str + ")";
  IR *new_name_list_ir = new IR(TypeNameList, ret_str);

  IR *name_list_left = type_name_list->get_left();
  IR *name_list_right = type_name_list->get_right();

  if (name_list_left != NULL) {
    ir_to_deep_drop.push_back(name_list_left);
    p_oracle->ir_wrapper.iter_cur_node_with_handler(
        name_list_left, [](IR *cur_node) -> void {
          cur_node->set_is_instantiated(true);
          cur_node->set_data_flag(ContextNoModi);
        });
  }
  if (name_list_right) {
    ir_to_deep_drop.push_back(name_list_right);
    p_oracle->ir_wrapper.iter_cur_node_with_handler(
        name_list_right, [](IR *cur_node) -> void {
          cur_node->set_is_instantiated(true);
          cur_node->set_data_flag(ContextNoModi);
        });
  }

  type_name_list->update_left(new_name_list_ir);
  type_name_list->update_right(NULL);
  type_name_list->op_->middle_ = "";

  return;
}

void Mutator::instan_func_expr(IR *ir_to_fix, vector<IR *> &ir_to_deep_drop,
                               bool is_debug_info) {

  if (p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeSetVar) ||
      p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeStorageParams)
  ) {
      return;
  }

  if (ir_to_fix->get_data_type() == DataFunctionName) {
      IR* ori_ir_to_fix = ir_to_fix;
      ir_to_fix = p_oracle->ir_wrapper.get_parent_node_with_type(ir_to_fix, DataFunctionExpr);
      if (ir_to_fix == NULL) {
          ir_to_fix = p_oracle->ir_wrapper.get_parent_node_with_type(ori_ir_to_fix, TypeFuncObj);
      }
      if (ir_to_fix == NULL) {
          if (is_debug_info) {
              cerr << "\n\n\nERROR: Inside instan_func_expr, cannot get "
                      "DataFunctionExpr/TypeFuncObj from DataFunctionName. \n\n\n";
          }
          return;
      }
  }

  /* Fixing for functions.  */
  if (ir_to_fix->get_data_type() == DataFunctionExpr || ir_to_fix->get_ir_type() == TypeFuncObj ) {
    if (ir_to_fix->get_data_flag() == ContextNoModi) {
      return;
    }

    IR *parent_node = ir_to_fix->get_parent();
    if (parent_node == NULL) {
      if (is_debug_info) {
        cerr << "\n\n\nERROR: Getting parent node is empty in "
                "instan_func_expr. \n\n\n";
      }
      return;
    }

    DATAAFFINITYTYPE chosen_affi;
    if (p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeSelectExprs)) {
      // If in the SELECT clause, we can choose any affinity we want.
      chosen_affi = get_random_affinity_type(
          true, true); // no array types. Only basic types.
    } else {
      chosen_affi = this->get_nearby_data_affinity(ir_to_fix, is_debug_info);
    }

    IR *new_func_node = constr_rand_func_with_affinity(chosen_affi);

    parent_node->swap_node(ir_to_fix, new_func_node);

    if (is_debug_info) {
      cerr << "\n\n\nDependency: Inside instan_func_expr, generating new "
              "function: "
           << new_func_node->to_string() << "\n\n\n";
    }

    ir_to_deep_drop.push_back(ir_to_fix);
  }

  return;
}

void Mutator::remove_type_annotation(IR *cur_stmt_root, vector<IR*>& ir_to_deep_drop ) {

    // Ignore all kinds of Column Type changes for now.

    vector<IR*> v_type_annotation_node = p_oracle->ir_wrapper
            .get_ir_node_in_stmt_with_type(cur_stmt_root, TypeAnnotateTypeExpr, false, true);

    for (IR* cur_type_anno_node : v_type_annotation_node) {
        if (cur_type_anno_node->get_middle() != ":::") {
            // Only remove the force type casting statement.
            continue;
        }
        IR* right_node = cur_type_anno_node->get_right();
        cur_type_anno_node->update_right(NULL);
        cur_type_anno_node->op_->middle_ = "";
        if (right_node != NULL) {
            ir_to_deep_drop.push_back(right_node);
            p_oracle->ir_wrapper.iter_cur_node_with_handler(
                    right_node, [](IR *cur_node) -> void {
                        cur_node->set_is_instantiated(true);
                        cur_node->set_data_flag(ContextNoModi);
                    });
        }
    }

    v_type_annotation_node = p_oracle->ir_wrapper
            .get_ir_node_in_stmt_with_type(cur_stmt_root, TypeCastExpr, false, true);

    for (IR* cur_type_anno_node : v_type_annotation_node) {
        if (cur_type_anno_node->get_middle() == "::") {
            IR *right_node = cur_type_anno_node->get_right();
            cur_type_anno_node->update_right(NULL);
            cur_type_anno_node->op_->middle_ = "";
            if (right_node != NULL) {
                ir_to_deep_drop.push_back(right_node);
                p_oracle->ir_wrapper.iter_cur_node_with_handler(
                        right_node, [](IR *cur_node) -> void {
                            cur_node->set_is_instantiated(true);
                            cur_node->set_data_flag(ContextNoModi);
                        });
            }
        } else if (cur_type_anno_node->get_left() != NULL &&
            cur_type_anno_node->get_left()->get_data_type() == DataTypeName) {
                IR* left_node = cur_type_anno_node->get_left();
                cur_type_anno_node->update_left(nullptr);
                left_node->set_is_instantiated(true);
                left_node->set_data_flag(ContextNoModi);
                ir_to_deep_drop.push_back(left_node);
        }
    }

    return;

}

bool Mutator::instan_dependency(IR *cur_stmt_root,
                                const vector<vector<IR *>> cur_stmt_ir_to_fix_vec,
                                bool is_debug_info) {

  if (is_debug_info) {
    cerr << "Fix_dependency: cur_stmt_root: " << cur_stmt_root->to_string()
         << ", size of cur_stmt_ir_to_fix_vec " << cur_stmt_ir_to_fix_vec.size()
         << ". \n\n\n";
  }

  /* Used to mark the IRs that are needed to be deep_drop(). However, it is not
   * a good idea to deep_drop in the middle of the instan_dependency() function,
   * some ir_to_fix node might have nested IR strcuture. Use this vector to save
   * all IR that needs deep_drop, and drop them at the end of the function.
   * */
  vector<IR *> ir_to_deep_drop;
  string cur_ir_str = cur_stmt_root->to_string();

  this->remove_type_annotation(cur_stmt_root, ir_to_deep_drop);

  if (is_debug_info) {
      cerr <<  "\n\n\nAfter removing the type annotations, getting " << cur_stmt_root->to_string() << "\n\n\n";
  }

  // If set true, meaning we are in an ALTER TABLE RENAME statement.
  bool is_replace_table = false, is_replace_column = false;

  for (const vector<IR *> &ir_to_fix_vec :
       cur_stmt_ir_to_fix_vec) { // Loop for substmt.

    /* Fix all DataDataBaseName and DataSchemaName */
    for (IR *ir_to_fix : ir_to_fix_vec) {
      if (ir_to_fix->get_is_instantiated()) {
        continue;
      }
      this->instan_database_schema_name(ir_to_fix, is_debug_info);
    }

    /* Definition of TypeDataTableName */
    for (IR *ir_to_fix : ir_to_fix_vec) {
      if (ir_to_fix->get_is_instantiated()) {
        continue;
      }

      if ((ir_to_fix->data_type_ == DataTableName) &&
          (ir_to_fix->data_flag_ == ContextDefine ||
           ir_to_fix->data_flag_ == ContextReplaceDefine)) {
        this->instan_table_name(ir_to_fix, is_replace_table, is_debug_info);
      }
    }

    /* Undefine of TypeDataTableName */
    for (IR *ir_to_fix : ir_to_fix_vec) {
      if (ir_to_fix->get_is_instantiated()) {
        continue;
      }

      if (ir_to_fix->data_type_ == DataTableName &&
          (ir_to_fix->data_flag_ == ContextUndefine ||
           ir_to_fix->data_flag_ == ContextReplaceUndefine)) {
        this->instan_table_name(ir_to_fix, is_replace_table, is_debug_info);
      }
    }

    /* Fix of DataTableAlias name. */
    /* For DataTableAlias name, do not need to
     * handle ContextUse and ContextUndefine situations.
     * i,e. we only need to consider the ContextDefine.
     * After the handling of current SQL statement finished,
     * all info related to this alias should be removed
     * automatically.
     * */
    for (IR *ir_to_fix : ir_to_fix_vec) {
      if (ir_to_fix->get_is_instantiated()) {
        continue;
      }

      // If NOT IN WITH clause, do not fix before the Table Name ContextUse.
      if (!p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeWith)) {
        continue;
      }

      if (ir_to_fix->data_type_ == DataTableAliasName) {
        ir_to_fix->set_is_instantiated(true);
        // For the WITH clause table alias, the usage is optional.
        this->instan_table_alias_name(ir_to_fix, cur_stmt_root, true, is_debug_info);
      }
    }

    /* ContextUse of kDataTableName */
    /* The ContextUseFollow will be handled further below. */
    for (IR *ir_to_fix : ir_to_fix_vec) {
      if (ir_to_fix->get_is_instantiated()) {
        continue;
      }

      if (ir_to_fix->data_type_ == DataTableName &&
          ir_to_fix->data_flag_ == ContextUse) {
        this->instan_table_name(ir_to_fix, is_replace_table, is_debug_info);
      }
    }

    /* Fix of DataTableAlias name. */
    /* For DataTableAlias name, do not need to
     * handle ContextUse and ContextUndefine situations.
     * i,e. we only need to consider the ContextDefine.
     * After the handling of current SQL statement finished,
     * all info related to this alias should be removed
     * automatically.
     * */
    for (IR *ir_to_fix : ir_to_fix_vec) {
      if (ir_to_fix->get_is_instantiated()) {
        continue;
      }

      // Fix the other aliases outside the WITH clause.
      if (p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeWith)) {
        continue;
      }

      if (ir_to_fix->data_type_ == DataTableAliasName) {
        ir_to_fix->set_is_instantiated(true);
        // For the table alias that is outside the WITH clause, the usage is enforced!
        this->instan_table_alias_name(ir_to_fix, cur_stmt_root, false, is_debug_info);
      }
    }

    /* ContextUseFollow of DataTableName. */
    /* This scenario searches for table name usage that is in the WHERE clause.
     */
    for (IR *ir_to_fix : ir_to_fix_vec) {
      if (ir_to_fix->get_is_instantiated()) {
        continue;
      }

      if (ir_to_fix->data_type_ == DataTableName &&
          ir_to_fix->data_flag_ == ContextUseFollow) {
        this->instan_table_name(ir_to_fix, is_replace_table, is_debug_info);
      }
    }

    /* Fix for kDataViewName. */
    for (IR *ir_to_fix : ir_to_fix_vec) {
      if (ir_to_fix->get_is_instantiated()) {
        continue;
      }
      if (ir_to_fix->get_data_type() == DataViewName) {
        this->instan_view_name(ir_to_fix, is_debug_info);
      }
    }

    /* Fix of DataPartitionName. */
    /* ContextDefine, ContextUse and ContextUndefine of DataPartitionName. */
    for (IR *ir_to_fix : ir_to_fix_vec) {
      if (ir_to_fix->get_is_instantiated()) {
        continue;
      }
      if (ir_to_fix->get_data_type() == DataPartitionName) {
        this->instan_partition_name(ir_to_fix, is_debug_info);
      }
    }

    /* Fix of kDataIndex name. */
    for (IR *ir_to_fix : ir_to_fix_vec) {
      if (ir_to_fix->get_is_instantiated()) {
        continue;
      }

      this->instan_index_name(ir_to_fix, is_debug_info);
    }

    /* kDefine and kReplace of kDataColumnName */
    for (IR *ir_to_fix : ir_to_fix_vec) {
      if (ir_to_fix->get_is_instantiated()) {
        continue;
      }

      if (ir_to_fix->data_type_ == DataColumnName &&
          (ir_to_fix->data_flag_ == ContextDefine ||
           ir_to_fix->data_flag_ == ContextReplaceDefine)) {

        this->instan_column_name(ir_to_fix, is_replace_column, ir_to_deep_drop,
                                 is_debug_info);

        /* ContextUndefine scenario of the DataColumnName */
      } else if (ir_to_fix->data_type_ == DataColumnName &&
                 ir_to_fix->data_flag_ == ContextUndefine) {

        this->instan_column_name(ir_to_fix, is_replace_column, ir_to_deep_drop,
                                 is_debug_info);
      }
    } // for (IR* ir_to_fix : ir_to_fix_vec)

    /* Fix of DataColumnAlias name.
     * There are two parts of the DataColumnAliasName handling.
     * The first part is inside TypeAliasClause, where the table
     * alias name and column alias name are all provided.
     * The second part is direct column referencing.
     * For the second part, we choose to ignore the mapping,
     * because these cases are not very interesting, and won't
     * reflect on the outputs.
     * */
    for (IR *ir_to_fix : ir_to_fix_vec) {
      if (ir_to_fix->get_is_instantiated()) {
        continue;
      }

      this->instan_column_alias_name(ir_to_fix, cur_stmt_root, ir_to_deep_drop,
                                     is_debug_info);
    }

    /* Fix the Data Type identifiers. Must be done after ContextDefine of
     * DataColumnName. */
    for (IR *ir_to_fix : ir_to_fix_vec) {
      if (ir_to_fix->get_is_instantiated()) {
        continue;
      }
      IRTYPE type = ir_to_fix->get_ir_type();
      DATATYPE data_type = ir_to_fix->get_data_type();
      DATAFLAG data_flag = ir_to_fix->get_data_flag();

      if (type == TypeIdentifier && data_type == DataTypeName &&
          data_flag == ContextDefine) {
        // Handling of the Column Data Type definition.
        // Use basic types.

        this->instan_sql_type_name(ir_to_fix, is_debug_info);
      }
    }

    /* For ContextUse of DataColumnName.
     * Special case, avoid using duplicated column names
     * in the TypeNameList clause.
     * */
    for (IR *ir_to_fix : ir_to_fix_vec) {
      if (ir_to_fix->get_is_instantiated()) {
        continue;
      }
      if (ir_to_fix->data_type_ == DataColumnName &&
          ir_to_fix->data_flag_ == ContextUse &&
          p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeNameList)) {
        this->instan_column_name(ir_to_fix, is_replace_column, ir_to_deep_drop,
                                 is_debug_info);
      }
    }

    /* kUse of kDataColumnName */
    for (IR *ir_to_fix : ir_to_fix_vec) {
      if (ir_to_fix->get_is_instantiated()) {
        continue;
      }

      if (ir_to_fix->data_type_ == DataColumnName &&
          ir_to_fix->data_flag_ == ContextUse) {
        this->instan_column_name(ir_to_fix, is_replace_column, ir_to_deep_drop,
                                 is_debug_info);
      }
    }

    //      /* kUse of DataForeignTable */
    //      for (IR *ir_to_fix : ir_to_fix_vec) {
    //          if (ir_to_fix->get_is_instantiated()) {
    //              continue;
    //          }
    //
    //          if (ir_to_fix->data_type_ == kDataForeignTableName &&
    //              ir_to_fix->data_flag_ == ContextDefine) {
    //              this->instan_foreign_table_name(ir_to_fix, is_debug_info);
    //          }
    //
    //      }

    /* Fix function names.  */
    for (IR *ir_to_fix : ir_to_fix_vec) {

      if (ir_to_fix->get_is_instantiated()) {
        continue;
      }

      /* Fixing for functions.  */
      if (ir_to_fix->get_data_type() == DataFunctionExpr) {
        if (ir_to_fix->get_data_flag() == ContextNoModi) {
          continue;
        }

          instan_func_expr(ir_to_fix, ir_to_deep_drop, is_debug_info);
      }
    }

    /* Fix for statistic and sequence name */
    for (IR *ir_to_fix : ir_to_fix_vec) {
      if (ir_to_fix->get_is_instantiated()) {
        continue;
      }

      if (ir_to_fix->get_data_type() == DataStatsName) {
        this->instan_statistic_name(ir_to_fix, is_debug_info);
      }

      /* Fix for kDataSequenceName */
      if (ir_to_fix->get_data_type() == DataSequenceName) {
        this->instan_sequence_name(ir_to_fix, is_debug_info);
      }

      /* Fix for kDataConstraintName */
      if (ir_to_fix->get_data_type() == DataConstraintName) {
        this->instan_constraint_name(ir_to_fix, is_debug_info);
      }

      /* Fix for DataFamilyName */
      if (ir_to_fix->get_data_type() == DataFamilyName) {
        this->instan_family_name(ir_to_fix, is_debug_info);
      }
    }

    /* Fix the Literal inside VALUES clause. */
    for (IR *ir_to_fix : ir_to_fix_vec) {
      if (ir_to_fix->get_is_instantiated()) {
        continue;
      }

      this->instan_literal(ir_to_fix, cur_stmt_root, ir_to_deep_drop,
                           is_debug_info);

    } /* for (IR* ir_to_fix : ir_to_fix_vec) */

    /* The next loop to handle all the Literals, after setting all literals to
     * AFFIUNKNOWN. */
    for (IR *ir_to_fix : ir_to_fix_vec) {
      if (ir_to_fix->get_is_instantiated()) {
        continue;
      }

      IRTYPE type = ir_to_fix->get_ir_type();

      if (type == TypeFloatLiteral || type == TypeStringLiteral ||
          type == TypeIntegerLiteral) {
        /* Continue from the previous loop, we now search around the ir_to_fix
         * and see if we can find column name or literals that can help deduce
         * Data Affinity.
         * */

        this->instan_literal(ir_to_fix, cur_stmt_root, ir_to_deep_drop,
                             is_debug_info);
      }
    } /* for (IR* ir_to_fix : ir_to_fix_vec) */

    for (IR *ir_to_fix : ir_to_fix_vec) {
      if (ir_to_fix->get_is_instantiated()) {
        continue;
      }

      IRTYPE type = ir_to_fix->get_ir_type();
      DATATYPE data_type = ir_to_fix->get_data_type();

      if (type == TypeStorageParams && data_type == DataStorageParams) {

        this->instan_storage_param(ir_to_fix, ir_to_deep_drop, is_debug_info);
      }
    }

  } /* for (const vector<IR*>& ir_to_fix_vec : cur_stmt_ir_to_fix_vec) */

  /* For the newly declared v_table_names_single, save all these newly declared
   * statement to the global v_table_names. */

  for (string cur_add_table : v_create_table_names_single) {
      if (!find_vector(v_table_names, cur_add_table)) {
          v_table_names.push_back(cur_add_table);
      }
  }
  for (string cur_add_table : v_create_view_names_single) {
      if (!find_vector(v_table_names, cur_add_table)) {
          v_table_names.push_back(cur_add_table);
      }
  }
  for (string cur_add_table : v_view_name) {
      if (!find_vector(v_view_name, cur_add_table)) {
          v_view_name.push_back(cur_add_table);
      }
  }

  /* Reiterate the substmt.
  ** Added missing dependency information.
  */
  for (const vector<IR *> &ir_to_fix_vec : cur_stmt_ir_to_fix_vec) {

    /* Added mapping for Inheritance.  */
    for (IR *ir_to_fix : ir_to_fix_vec) {
      if (ir_to_fix->data_type_ == DataTableName &&
          (cur_stmt_root->get_ir_type() == TypeCreateTable ||
           cur_stmt_root->get_ir_type() == TypeCreateView ||
           cur_stmt_root->get_ir_type() == TypeCreateIndex) &&
          //        p_oracle->ir_wrapper.is_ir_in(ir_to_fix, kOptInherit) &&
          ir_to_fix->data_flag_ == ContextUse) {
        if (v_create_table_names_single.size() > 0) {
          string cur_new_table_name_str = v_create_table_names_single.front();
          string inherit_table_name_str = ir_to_fix->get_str_val();

          vector<string> &inherit_m_tables =
              m_table2columns[inherit_table_name_str];

          for (string col_name : inherit_m_tables) {
              vector<string> & cur_col_list = m_table2columns[cur_new_table_name_str];
              if (find(cur_col_list.begin(), cur_col_list.end(), col_name) == cur_col_list.end()) {
                 cur_col_list.push_back(col_name);
              }
          }
        }
      }
    }

    for (IR *ir_to_fix : ir_to_fix_vec) {

      this->map_create_view(ir_to_fix, cur_stmt_root, cur_stmt_ir_to_fix_vec,
                            is_debug_info);

    } // for (IR* ir_to_fix : ir_to_fix_vec)

    // The second loop that fix the DataViewColumn.
    // Need to rewrite the column mapping.
    for (IR *ir_to_fix : ir_to_fix_vec) {
      if (ir_to_fix->get_data_type() == DataViewColumnName) {
        if (cur_stmt_root->get_ir_type() != TypeCreateView) {
          cerr << "\n\n\nError: Finding DataViewColumnName that is not in the "
                  "Create View statement. \n\n\n";
          continue;
        }
        this->map_create_view_column(ir_to_fix, ir_to_deep_drop, is_debug_info);
      }
    }
  } // for (const vector<IR *> &ir_to_fix_vec : cur_stmt_ir_to_fix_vec)

  for (IR *ir_to_drop : ir_to_deep_drop) {
    if (ir_to_drop) {
      ir_to_drop->deep_drop();
    }
  }
  return true;
}

static bool replace_in_vector(string &old_str, string &new_str,
                              vector<string> &victim) {
  for (int i = 0; i < victim.size(); i++) {
    if (victim[i] == old_str) {
      victim[i] = new_str;
      return true;
    }
  }
  return false;
}

static bool remove_in_vector(string &str_to_remove, vector<string> &victim) {
  for (auto iter = victim.begin(); iter != victim.end(); iter++) {
    if (*iter == str_to_remove) {
      victim.erase(iter);
      return true;
    }
  }
  return false;
}

bool Mutator::remove_one_from_datalibrary(DATATYPE datatype, string &key) {
  return remove_in_vector(key, data_library_[datatype]);
}

bool Mutator::replace_one_from_datalibrary(DATATYPE datatype, string &old_str,
                                           string &new_str) {
  return replace_in_vector(old_str, new_str, data_library_[datatype]);
}

bool Mutator::remove_one_pair_from_datalibrary_2d(DATATYPE p_datatype,
                                                  DATATYPE c_data_type,
                                                  string &p_key) {
  for (auto &value : data_library_2d_[p_datatype][p_key][c_data_type]) {
    remove_one_from_datalibrary(c_data_type, value);
  }

  data_library_2d_[p_datatype][p_key].erase(c_data_type);
  if (data_library_2d_[p_datatype][p_key].empty()) {
    remove_one_from_datalibrary(p_datatype, p_key);
    data_library_2d_[p_datatype].erase(p_key);
  }

  return true;
}

void Mutator::reset_data_library_single_stmt() {
  this->v_table_names_single.clear();
  this->v_column_names_single.clear();
  this->v_create_view_names_single.clear();
  this->v_create_table_names_single.clear();
  this->v_table_alias_names_single.clear();
  this->v_column_alias_names_single.clear();
  this->m_alias2table_single.clear();
  this->m_enforced_table2alias_single.clear();
  this->m_alias2column_single.clear();
  this->m_alias_table2column_single.clear();
}

void Mutator::reset_data_library() {
  this->reset_data_library_single_stmt();
  m_table2columns.clear();
  m_table2partition.clear();
  v_table_names.clear();
  m_table2index.clear();
  m_column2datatype.clear();
  m_datatype2column.clear();
  m_datatype2literals.clear();
  v_statistics_name.clear();
  v_sequence_name.clear();
  v_view_name.clear();
  v_constraint_name.clear();
  v_family_name.clear();
  v_foreign_table_name.clear();
  v_table_with_partition.clear();
  v_int_literals.clear();
  v_float_literals.clear();
  v_string_literals.clear();
}

static IR *search_mapped_ir(IR *ir, DATATYPE type) {
  vector<IR *> to_search;
  vector<IR *> backup;
  to_search.push_back(ir);
  while (!to_search.empty()) {
    for (auto i : to_search) {
      if (i->data_type_ == type) {
        return i;
      }
      if (i->left_) {
        backup.push_back(i->left_);
      }
      if (i->right_) {
        backup.push_back(i->right_);
      }
    }
    to_search = move(backup);
    backup.clear();
  }
  return NULL;
}

IR *Mutator::find_closest_node(IR *stmt_root, IR *node, DATATYPE type) {
  auto cur = node;
  while (true) {
    auto parent = locate_parent(stmt_root, cur);
    if (!parent)
      break;
    bool flag = false;
    while (parent->left_ == NULL || parent->right_ == NULL) {
      cur = parent;
      parent = locate_parent(stmt_root, cur);
      if (!parent) {
        flag = true;
        break;
      }
    }
    if (flag)
      return NULL;

    auto search_root = parent->left_ == cur ? parent->right_ : parent->left_;
    auto res = search_mapped_ir(search_root, type);
    if (res)
      return res;

    cur = parent;
  }
  return NULL;
}

// added by vancir.

// Return use_temp or not.
bool Mutator::get_valid_str_from_lib(string &ori_norec_select) {
  /* For 1/2 chance, grab one query from the norec library, and return.
   * For 1/2 chance, take the template from the p_oracle and return.
   */
  bool is_succeed = false;

  while (!is_succeed) { // Potential dead loop. Only escape through return.
    bool use_temp = false;
    int query_method = get_rand_int(2);
    if (all_valid_pstr_vec.size() > 0 && query_method < 1) {
      /* Pick the query from the lib, pass to the mutator. */
      ori_norec_select =
          *(all_valid_pstr_vec[get_rand_int(all_valid_pstr_vec.size())]);

      if (ori_norec_select == "" ||
          !p_oracle->is_oracle_select_stmt(ori_norec_select))
        continue;
      use_temp = false;
    } else {
      /* Pick the query from the template, pass to the mutator. */
      ori_norec_select = p_oracle->get_template_select_stmts();
      use_temp = true;
    }

    trim_string(ori_norec_select);
    return use_temp;
  }
  fprintf(stderr, "*** FATAL ERROR: Unexpected code execution in the "
                  "Mutator::get_valid_str_from_lib function. \n");
  fflush(stderr);
  abort();
}

vector<IR *> Mutator::parse_query_str_get_ir_set(string &query_str) const {
  vector<IR *> ir_set;

  ensure_semicolon_at_query_end(query_str);

  IR *root_ir = NULL;

  try {
    root_ir = raw_parser(query_str);
    if (root_ir == NULL) {
      return ir_set;
    }
  } catch (...) {
    return ir_set;
  }

  /* Debug */
  // root_ir->deep_drop();
  // vector<IR*>dummp_vec;
  // return dummp_vec;

  ir_set = p_oracle->ir_wrapper.get_all_ir_node(root_ir);

  int unique_id_for_node = 0;
  for (auto ir : ir_set) {
    ir->uniq_id_in_tree_ = unique_id_for_node++;
  }

  return ir_set;
}

bool Mutator::check_node_num(IR *root, unsigned int limit) {

  auto v_statements = extract_statement(root);
  bool is_good = true;

  for (auto stmt : v_statements) {
    // cerr << "For current query stmt: " << root->to_string() << endl;
    // cerr << calc_node(stmt) << endl;
    if (calc_node(stmt) > limit) {
      is_good = false;
      break;
    }
  }

  return is_good;
}

vector<IR *> Mutator::extract_statement(IR *root) {
  vector<IR *> res;
  deque<IR *> bfs = {root};

  while (bfs.empty() != true) {
    auto node = bfs.front();
    bfs.pop_front();

    if (node->type_ == TypeStmt)
      res.push_back(node);
    if (node->left_)
      bfs.push_back(node->left_);
    if (node->right_)
      bfs.push_back(node->right_);
  }

  return res;
}

void Mutator::set_dump_library(bool to_dump) { this->dump_library = to_dump; }

int Mutator::get_ir_libary_2D_hash_kStatement_size() {
  return this->ir_libary_2D_hash_[TypeStmt].size();
}

bool Mutator::is_stripped_str_in_lib(string stripped_str) {
  // stripped_str = extract_struct(stripped_str);
  unsigned long str_hash = hash(stripped_str);
  if (stripped_string_hash_.find(str_hash) != stripped_string_hash_.end())
    return true;
  stripped_string_hash_.insert(str_hash);
  return false;
}

/* add_to_library supports only one stmt at a time,
 * add_all_to_library is responsible to split the
 * the current IR tree into single query stmts.
 * This function is not responsible to free the input IR tree.
 */
void Mutator::add_all_to_library(IR *ir, const vector<int> &explain_diff_id) {
  add_all_to_library(ir->to_string(), explain_diff_id);
}

/*  Save an interesting query stmt into the mutator library.
 *
 *   The uniq_id_in_tree_ should be, more idealy, being setup and kept unchanged
 * once an IR tree has been reconstructed. However, there are some difficulties
 * there. For example, how to keep the uniqueness and the fix order of the
 * unique_id_in_tree_ for each node in mutations. Therefore, setting and
 * checking the uniq_id_in_tree_ variable in every nodes of an IR tree are only
 * done when necessary by calling this funcion and
 * get_from_library_with_[_,left,right]_type. We ignore this unique_id_in_tree_
 * in other operations of the IR nodes. The unique_id_in_tree_ is setup based on
 * the order of the ir_set vector, returned from Program*->translate(ir_set).
 *
 */

void Mutator::add_all_to_library(string whole_query_str,
                                 const vector<int> &explain_diff_id) {

  /* If the query_str is empty. Ignored and return. */
  bool is_empty = true;
  for (int i = 0; i < whole_query_str.size(); i++) {
    char c = whole_query_str[i];
    if (!isspace(c) && c != '\n' && c != '\0') {
      is_empty = false; // Not empty.
      break;
    } // Empty
  }

  if (is_empty)
    return;

  vector<string> queries_vector = string_splitter(whole_query_str, ';');
  int i = 0; // For counting oracle valid stmt IDs.
  for (auto current_query : queries_vector) {
    trim_string(current_query);
    if (current_query == "") {
      continue;
    }
    current_query += ";";
    // check the validity of the IR here
    // The unique_id_in_tree_ variable are being set inside the parsing func.

    /* Debug */
    // cerr << "In initial library: getting current_query: " << current_query <<
    // "\n";

    vector<IR *> ir_set = parse_query_str_get_ir_set(current_query);
    if (ir_set.size() == 0)
      continue;

    IR *root = ir_set[ir_set.size() - 1];
    vector<IR *> v_cur_stmt_ir = p_oracle->ir_wrapper.get_stmt_ir_vec(root);
    if (v_cur_stmt_ir.size() == 0) {
      root->deep_drop();
      return;
    }
    IR *cur_stmt_ir = v_cur_stmt_ir.front();

    if (p_oracle->is_oracle_select_stmt(cur_stmt_ir)) {
      // if (p_oracle->is_oracle_valid_stmt(current_query)) {
      if (std::find(explain_diff_id.begin(), explain_diff_id.end(), i) !=
          explain_diff_id.end()) {
        add_to_valid_lib(root, current_query, true);
      } else {
        add_to_valid_lib(root, current_query, false);
      }
      ++i; // For counting oracle valid stmt IDs.
    } else {
      add_to_library(root, current_query);
    }

    root->deep_drop();
  }
}

void Mutator::add_to_valid_lib(IR *ir, string &select,
                               const bool is_explain_diff) {

  unsigned long p_hash = hash(select);

  if (norec_hash.find(p_hash) != norec_hash.end())
    return;

  norec_hash[p_hash] = true;

  string *new_select = new string(select);

  all_query_pstr_set.insert(new_select);
  all_valid_pstr_vec.push_back(new_select);

  //  if (this->dump_library) {
  //    std::ofstream f;
  //    f.open("./norec-select", std::ofstream::out | std::ofstream::app);
  //    f << *new_select << endl;
  //    f.close();
  //  }

  // cerr << "Saving select str: " << *new_select << " to the lib. \n\n\n";
  add_to_library_core(ir, new_select);

  return;
}

void Mutator::add_to_library(IR *ir, string &query) {

  if (query == "")
    return;

  IRTYPE p_type = ir->type_;
  unsigned long p_hash = hash(query);

  if (ir_libary_2D_hash_[p_type].find(p_hash) !=
      ir_libary_2D_hash_[p_type].end()) {
    /* query not interesting enough. Ignore it and clean up. */
    return;
  }
  ir_libary_2D_hash_[p_type].insert(p_hash);

  string *p_query_str = new string(query);
  all_query_pstr_set.insert(p_query_str);
  // all_valid_pstr_vec.push_back(p_query_str);

  //  if (this->dump_library) {
  //    std::ofstream f;
  //    f.open("./normal-lib", std::ofstream::out | std::ofstream::app);
  //    f << *p_query_str << endl;
  //    f.close();
  //  }

  // cerr << "Saving str: " << *p_query_str << " to the lib. \n\n\n";
  add_to_library_core(ir, p_query_str);

  // get_memory_usage();  // Debug purpose.

  return;
}

void Mutator::add_to_library_core(IR *ir, string *p_query_str) {
  /* Save an interesting query stmt into the mutator library. Helper function
   * for Mutator::add_to_library();
   */

  if (*p_query_str == "")
    return;

  int current_unique_id = ir->uniq_id_in_tree_;
  bool is_skip_saving_current_node = false; //

  IRTYPE p_type = ir->type_;
  IRTYPE left_type = TypeUnknown, right_type = TypeUnknown;

  string ir_str = ir->to_string();
  unsigned long p_hash = hash(ir_str);
  if (p_type != TypeRoot && ir_libary_2D_hash_[p_type].find(p_hash) !=
                                ir_libary_2D_hash_[p_type].end()) {
    /* current node not interesting enough. Ignore it and clean up. */
    // cerr << "current node not interesting enough. Ignore it and clean
    // up.\n\n\n";
    return;
  }
  if (p_type != TypeRoot)
    ir_libary_2D_hash_[p_type].insert(p_hash);

  if (!is_skip_saving_current_node) {
    real_ir_set[p_type].push_back(
        std::make_pair(p_query_str, current_unique_id));
    // cerr << "Saving str: " << *p_query_str << "with type: " <<
    // get_string_by_ir_type(p_type) << " \n\n\n";
  }

  // Update right_lib, left_lib
  if (ir->right_ != NULL && ir->left_ != NULL && !is_skip_saving_current_node) {
    left_type = ir->left_->type_;
    right_type = ir->right_->type_;
    left_lib_set[left_type].push_back(std::make_pair(
        p_query_str, current_unique_id)); // Saving the parent node id. When
                                          // fetching, use current_node->right.
    // if (*p_query_str == "ALTER INDEX x NO DEPENDS ON EXTENSION x;") {
    //   cerr << "Saving left_type_ ir_node with right type: " <<
    //   get_string_by_ir_type(right_type) << ", unique_id:" <<
    //   ir->right_->uniq_id_in_tree_ << "\n\n\n";
    // }
    right_lib_set[right_type].push_back(std::make_pair(
        p_query_str, current_unique_id)); // Saving the parent node id. When
                                          // fetching, use current_node->left.
    // if (*p_query_str == "ALTER INDEX x NO DEPENDS ON EXTENSION x;") {
    //   cerr << "Saving right_type_ ir_node with left type: " <<
    //   get_string_by_ir_type(left_type) << ", unique_id:" <<
    //   ir->left_->uniq_id_in_tree_ << "\n\n\n";
    // }
  }

  //  if (this->dump_library) {
  //
  //    std::ofstream f;
  //    f.open("./append-core", std::ofstream::out | std::ofstream::app);
  //    f << *p_query_str << " node_id: " << current_unique_id << endl;
  //    f.close();
  //  }

  if (ir->left_) {
    add_to_library_core(ir->left_, p_query_str);
  }

  if (ir->right_) {
    add_to_library_core(ir->right_, p_query_str);
  }

  return;
}

int Mutator::get_cri_valid_collection_size() {
  return all_cri_valid_pstr_vec.size();
}

int Mutator::get_valid_collection_size() { return all_valid_pstr_vec.size(); }

IR *Mutator::get_from_libary_with_type(IRTYPE type_) {
  /* Given a data type, return a randomly selected prevously seen IR node that
     matched the given type. If nothing has found, return an empty
     kStringLiteral.
  */

  vector<IR *> current_ir_set;
  IR *current_ir_root;
  vector<pair<string *, int>> &all_matching_node = real_ir_set[type_];
  IR *return_matched_ir_node = NULL;

  if (all_matching_node.size() > 0) {
    /* Pick a random matching node from the library. */
    int random_idx = get_rand_int(all_matching_node.size());
    std::pair<string *, int> &selected_matched_node =
        all_matching_node[random_idx];
    string *p_current_query_str = selected_matched_node.first;
    int unique_node_id = selected_matched_node.second;

    /* Reconstruct the IR tree. */
    current_ir_set = parse_query_str_get_ir_set(*p_current_query_str);
    if (current_ir_set.size() <= 0)
      return new IR(TypeStringLiteral, "");
    current_ir_root = current_ir_set.back();

    /* Retrive the required node, deep copy it, clean up the IR tree and return.
     */
    IR *matched_ir_node = current_ir_set[unique_node_id];
    if (matched_ir_node != NULL) {
      if (matched_ir_node->type_ != type_) {
        current_ir_root->deep_drop();
        return new IR(TypeStringLiteral, "");
      }
      // return_matched_ir_node = matched_ir_node->deep_copy();
      return_matched_ir_node = matched_ir_node;
      current_ir_root->detach_node(return_matched_ir_node);
    }

    current_ir_root->deep_drop();

    if (return_matched_ir_node != NULL) {
      // cerr << "\n\n\nSuccessfuly with_type: with string: " <<
      // return_matched_ir_node->to_string() << endl;
      return return_matched_ir_node;
    }
  }

  return new IR(TypeStringLiteral, "");
}

IR *Mutator::get_from_libary_with_left_type(IRTYPE type_) {
  /* Given a left_ type, return a randomly selected prevously seen right_ node
     that share the same parent. If nothing has found, return NULL.
  */

  vector<IR *> current_ir_set;
  IR *current_ir_root;
  vector<pair<string *, int>> &all_matching_node = left_lib_set[type_];
  IR *return_matched_ir_node = NULL;

  if (all_matching_node.size() > 0) {
    /* Pick a random matching node from the library. */
    int random_idx = get_rand_int(all_matching_node.size());
    std::pair<string *, int> &selected_matched_node =
        all_matching_node[random_idx];
    string *p_current_query_str = selected_matched_node.first;
    int unique_node_id = selected_matched_node.second;

    /* Reconstruct the IR tree. */
    current_ir_set = parse_query_str_get_ir_set(*p_current_query_str);
    if (current_ir_set.size() <= 0)
      return NULL;
    current_ir_root = current_ir_set.back();

    /* Retrive the required node, deep copy it, clean up the IR tree and return.
     */
    IR *matched_ir_node = current_ir_set[unique_node_id];
    if (matched_ir_node != NULL) {
      if (matched_ir_node->left_->type_ != type_) {
        current_ir_root->deep_drop();
        return NULL;
      }
      // return_matched_ir_node = matched_ir_node->right_->deep_copy();;  // Not
      // returnning the matched_ir_node itself, but its right_ child node!
      return_matched_ir_node = matched_ir_node->right_;
      current_ir_root->detach_node(return_matched_ir_node);
    }

    current_ir_root->deep_drop();

    if (return_matched_ir_node != NULL) {
      // cerr << "\n\n\nSuccessfuly left_type: with string: " <<
      // return_matched_ir_node->to_string() << endl;
      return return_matched_ir_node;
    }
  }

  return NULL;
}

IR *Mutator::get_from_libary_with_right_type(IRTYPE type_) {
  /* Given a right_ type, return a randomly selected prevously seen left_ node
     that share the same parent. If nothing has found, return NULL.
  */

  vector<IR *> current_ir_set;
  IR *current_ir_root;
  vector<pair<string *, int>> &all_matching_node = right_lib_set[type_];
  IR *return_matched_ir_node = NULL;

  if (all_matching_node.size() > 0) {
    /* Pick a random matching node from the library. */
    std::pair<string *, int> &selected_matched_node =
        all_matching_node[get_rand_int(all_matching_node.size())];
    string *p_current_query_str = selected_matched_node.first;
    int unique_node_id = selected_matched_node.second;

    /* Reconstruct the IR tree. */
    current_ir_set = parse_query_str_get_ir_set(*p_current_query_str);
    if (current_ir_set.size() <= 0)
      return NULL;
    current_ir_root = current_ir_set.back();

    /* Retrive the required node, deep copy it, clean up the IR tree and return.
     */
    IR *matched_ir_node = current_ir_set[unique_node_id];
    if (matched_ir_node != NULL) {
      if (matched_ir_node->right_->type_ != type_) {
        current_ir_root->deep_drop();
        return NULL;
      }
      // return_matched_ir_node = matched_ir_node->left_->deep_copy();  // Not
      // returnning the matched_ir_node itself, but its left_ child node!
      return_matched_ir_node = matched_ir_node->left_;
      current_ir_root->detach_node(return_matched_ir_node);
    }

    current_ir_root->deep_drop();

    if (return_matched_ir_node != NULL) {
      // cerr << "\n\n\nSuccessfuly right_type: with string: " <<
      // return_matched_ir_node->to_string() << endl;
      return return_matched_ir_node;
    }
  }

  return NULL;
}

IR *Mutator::get_ir_with_type(const IRTYPE type_) {
  IR *new_ir = get_from_libary_with_type(type_);
  if (new_ir == NULL) {
    return NULL;
  } else if (new_ir->get_ir_type() != type_) {
    cerr << "get_from_libary_with_type(type_) type doesn't matched! Return "
            "type: "
         << get_string_by_ir_type(new_ir->get_ir_type())
         << ", requested type: " << get_string_by_ir_type(type_) << ". \n\n\n";
    new_ir->deep_drop();
    return NULL;
  }

  return new_ir;
}

bool Mutator::add_missing_create_table_stmt(IR *ir_root) {
  /* Only accept ir_root as inputs. */
  if (ir_root->get_ir_type() != TypeRoot) {
    return false;
  }

  // Get Create Stmt. For the beginning.
  p_oracle->ir_wrapper.set_ir_root(ir_root);
  IR *new_stmt_ir = this->get_ir_with_type(TypeCreateTable);
  if (new_stmt_ir == NULL) {
    cerr << "Debug: add_missing_create_table_stmt: Return false because "
            "kCreateStmt is NULL. \n\n\n";
    return false;
  } else if (new_stmt_ir->get_left() == NULL) {
    new_stmt_ir->deep_drop();
    cerr << "Debug: add_missing_create_table_stmt: Return false because "
            "kCreateStmt is NULL. \n\n\n";
    return false;
  }

  // Get INSERT stmt
  p_oracle->ir_wrapper.set_ir_root(ir_root);
  IR *new_stmt_ir_2 = this->get_ir_with_type(TypeInsert);
  if (new_stmt_ir_2 == NULL) {
    cerr << "Debug: add_missing_create_table_stmt: Return false because "
            "kInsertStmt is NULL. \n\n\n";
    return false;
  } else if (new_stmt_ir_2->get_left() == NULL) {
    new_stmt_ir_2->deep_drop();
    cerr << "Debug: add_missing_create_table_stmt: Return false because "
            "kInsertStmt is NULL. \n\n\n";
    return false;
  }

  // Get CREATE INDEX stmt
  p_oracle->ir_wrapper.set_ir_root(ir_root);
  IR *new_stmt_ir_3 = this->get_ir_with_type(TypeCreateIndex);
  if (new_stmt_ir_3 == NULL) {
    cerr << "Debug: add_missing_create_table_stmt: Return false because "
            "kIndexStmt is NULL. \n\n\n";
    return false;
  } else if (new_stmt_ir_3->get_left() == NULL) {
    new_stmt_ir_3->deep_drop();
    cerr << "Debug: add_missing_create_table_stmt: Return false because "
            "kIndexStmt is NULL. \n\n\n";
    return false;
  }

  p_oracle->ir_wrapper.set_ir_root(ir_root);
  p_oracle->ir_wrapper.append_stmt_at_idx(new_stmt_ir, 0);
  p_oracle->ir_wrapper.append_stmt_at_idx(new_stmt_ir_2, 1);
  p_oracle->ir_wrapper.append_stmt_at_idx(new_stmt_ir_3, 2);

  // Get Create Stmt, for the end.
  p_oracle->ir_wrapper.set_ir_root(ir_root);
  new_stmt_ir = this->get_ir_with_type(TypeCreateTable);
  if (new_stmt_ir == NULL) {
    cerr << "Debug: add_missing_create_table_stmt: Return false because "
            "kCreateStmt is NULL. \n\n\n";
    return false;
  } else if (new_stmt_ir->get_left() == NULL) {
    new_stmt_ir->deep_drop();
    cerr << "Debug: add_missing_create_table_stmt: Return false because "
            "kCreateStmt is NULL. \n\n\n";
    return false;
  }

  // Get INSERT stmt
  p_oracle->ir_wrapper.set_ir_root(ir_root);
  new_stmt_ir_2 = this->get_ir_with_type(TypeInsert);
  if (new_stmt_ir_2 == NULL) {
    cerr << "Debug: add_missing_create_table_stmt: Return false because "
            "kInsertStmt is NULL. \n\n\n";
    return false;
  } else if (new_stmt_ir_2->get_left() == NULL) {
    new_stmt_ir_2->deep_drop();
    cerr << "Debug: add_missing_create_table_stmt: Return false because "
            "kInsertStmt is NULL. \n\n\n";
    return false;
  }

  // Get CREATE INDEX stmt
  p_oracle->ir_wrapper.set_ir_root(ir_root);
  new_stmt_ir_3 = this->get_ir_with_type(TypeCreateIndex);
  if (new_stmt_ir_3 == NULL) {
    cerr << "Debug: add_missing_create_table_stmt: Return false because "
            "kIndexStmt is NULL. \n\n\n";
    return false;
  } else if (new_stmt_ir_3->get_left() == NULL) {
    new_stmt_ir_3->deep_drop();
    cerr << "Debug: add_missing_create_table_stmt: Return false because "
            "kIndexStmt is NULL. \n\n\n";
    return false;
  }

  p_oracle->ir_wrapper.set_ir_root(ir_root);
  p_oracle->ir_wrapper.append_stmt_at_end(new_stmt_ir);
  p_oracle->ir_wrapper.append_stmt_at_end(new_stmt_ir_2);
  p_oracle->ir_wrapper.append_stmt_at_end(new_stmt_ir_3);

  return true;
}

IR *Mutator::constr_rand_set_stmt() {
  // Construct one SET statement as string,
  //  and then embed the string into one IR.
  // Return the embedded IR.

  if (this->all_saved_set_session.size() == 0 ||
      this->set_session_lib.size() == 0) {
    cerr << "Error: The all_save_set_session or set_session_lib failed to init "
            "before used. \n\n\n Abort();\n\n\n";
    abort();
  }

  string rand_chosen_var = vector_rand_ele(this->all_saved_set_session);
  DataAffinity cur_data_affi = this->set_session_lib[rand_chosen_var];

  string params_str = cur_data_affi.get_mutated_literal();

  string connector = get_rand_int(2) ? " = " : " TO ";
  string ret_str = "SET SESSION " + rand_chosen_var + connector + params_str;

  IR *ret_ir =
      new IR(TypeSetVar, ret_str, DataNone, ContextNoModi, AFFIUNKNOWN);
  ret_ir = new IR(TypeStmt, OP3("", "; ", ""), ret_ir, NULL);

  return ret_ir;
}

IR *Mutator::constr_rand_storage_param(int param_num) {
  // Construct one SET statement as string,
  //  and then embed the string into one IR.
  // Return the embedded IR.

  if (param_num < 1) {
    cerr << "\n\n\n Logic Error: Inside constr_rand_storage_param. ";
  }

  if (this->all_storage_param.size() == 0 ||
      this->storage_param_lib.size() == 0) {
    cerr << "Error: The all_storage_param or storage_param_lib failed to init "
            "before used. \n\n\n Abort();\n\n\n";
    abort();
  }

  string ret_str = "";
  for (int idx = 0; idx != param_num; idx++) {

    string rand_chosen_var = vector_rand_ele(this->all_storage_param);
    DataAffinity cur_data_affi = this->storage_param_lib[rand_chosen_var];

    string params_str = cur_data_affi.get_mutated_literal();

    if (idx > 0) {
      ret_str += ", ";
    }

    ret_str += rand_chosen_var + " = " + params_str;
  };

  IR *ret_ir =
      new IR(TypeStorageParams, ret_str, DataNone, ContextNoModi, AFFIUNKNOWN);

  return ret_ir;
}

IR *Mutator::constr_rand_func_with_affinity(DATAAFFINITYTYPE in_affi) {

  string cur_func_name = "";
  string func_name_ret_str = "";
  string arg_names_ret_str = "";
  if (in_affi == AFFIANY || in_affi == AFFIUNKNOWN) {
    cur_func_name = vector_rand_ele(this->all_saved_func_name);
  } else if (this->func_type_lib.count(in_affi) > 0) {
    cur_func_name = vector_rand_ele(func_type_lib[in_affi]);
  } else {
    cur_func_name = vector_rand_ele(this->all_saved_func_name);
  }

  func_name_ret_str = cur_func_name;
//  arg_names_ret_str = "(";

  // Randomly choose a set of arguments.
  vector<DataAffinity> v_func_affi =
      vector_rand_ele(func_str_to_type_map[cur_func_name]);

  int arg_idx = -1;
//  cerr << "\n\n\nDEBUG:: For function name: " << cur_func_name << ", getting arg size: " << v_func_affi.size() << "\n\n\n";
  for (DataAffinity &cur_arg_affi : v_func_affi) {
    arg_idx++;
    // The first arg is the function returned type.
    if (arg_idx == 0) {
        continue;
    }
    if (arg_idx > 1) {
      arg_names_ret_str += ", ";
    }

    if (this->m_datatype2column.count(cur_arg_affi.get_data_affinity()) &&
        get_rand_int(3)) {
      // Use the data column that match the affinity.
      string cur_col_str = vector_rand_ele(
          this->m_datatype2column[cur_arg_affi.get_data_affinity()]);
      arg_names_ret_str += cur_col_str;
    } else {
      // Use literal that match the affinity type.
      string cur_arg_str = cur_arg_affi.get_mutated_literal();
      arg_names_ret_str += cur_arg_str;
    }
  }

//  arg_names_ret_str += ") ";

  IR *ret_IR = new IR(TypeIdentifier, func_name_ret_str, DataFunctionName, ContextUse);
  ret_IR->set_is_instantiated(true);
  IR *arg_IR = new IR(TypeUnknown, arg_names_ret_str, DataUnknownType, ContextUndefine);
  arg_IR->set_is_instantiated(true);
  ret_IR = new IR(TypeFuncExpr, OP3("", "(", ")"), ret_IR, arg_IR);
  ret_IR->set_is_instantiated(true);
//  ret_IR->set_data_flag(ContextNoModi);

  return ret_IR;
}

DATAAFFINITYTYPE Mutator::detect_str_affinity(std::string str_in) {

    if (this->m_column2datatype.count(str_in) != 0) {
        // Useless?
        return this->m_column2datatype[str_in].get_data_affinity();
    } else {
        return get_data_affinity_by_string(str_in);
    }

}

void Mutator::fix_literal_op_err(IR *cur_stmt_root, string res_str, bool is_debug_info) {

    /* Fix type mismatched problems from the operators.
     * This function only handles the error when comparing two literals.
     * */

    vector<IR*> ir_to_deep_drop;

    // Case 1:
    // SELECT COUNT( *), SUM( x), REGR_SXX( x, type_op6), SUM( x), REGR_SYY( x, x),
    // REGR_SXY( x, x) FROM v0 WHERE c1 IN (true, true, false, true, false);
    // pq: unsupported comparison operator: c1 IN (true, true, false, true, false):
    // expected true to be of type timestamp, found type bool

    if (
            findStringIn(res_str, "unsupported comparison operator: ") &&
            findStringIn(res_str, "expected" ) &&
            findStringIn(res_str, "to be of type" ) &&
            findStringIn(res_str, "found type " )
    ) {

        if (is_debug_info) {
            cerr << "\n\n\nDEBUG::Matching rule unsupported comparison operator: \n\n\n";
        }

        string str_literal = "";
        string str_target_type = "";
        vector<string> v_tmp_split;

        // Get the troublesome variable.
        v_tmp_split = string_splitter(res_str, ": expected ");
        if (v_tmp_split.size() <= 1) {
            cerr << "\n\n\nERROR: Cannot find : expected in the string. \n\n\n";
            return;
        }
        str_literal = v_tmp_split.at(1);

        v_tmp_split = string_splitter(str_literal, " to be of type ");
        if (v_tmp_split.size() <= 1) {
            cerr << "\n\n\nERROR: Cannot find to be of type in the string. \n\n\n";
            return;
        }
        str_literal = v_tmp_split.at(0);

        // Get the target type name.
        v_tmp_split = string_splitter(res_str, " to be of type ");
        if (v_tmp_split.size() <= 1) {
            cerr << "\n\n\nERROR: Cannot find : expected in the string. \n\n\n";
            return;
        }
        str_target_type = v_tmp_split.at(1);

        v_tmp_split = string_splitter(str_target_type, ", ");
        if (v_tmp_split.size() <= 1) {
            cerr << "\n\n\nERROR: Cannot find to be of type in the string. \n\n\n";
            return;
        }
        str_target_type = v_tmp_split.at(0);

        DATAAFFINITYTYPE fix_affi = detect_str_affinity(str_target_type);

        // Find all the matching literals.
        vector<IR*> v_matched_node = p_oracle->ir_wrapper
                .get_ir_node_in_stmt_with_type(cur_stmt_root, str_literal, false, true);
        for (IR* cur_matched_node : v_matched_node) {

            bool is_skip = false;
            for (auto cur_drop: ir_to_deep_drop) {
                if (p_oracle->ir_wrapper.is_ir_in(cur_matched_node, cur_drop)) {
                    is_skip = true;
                    break;
                }
            }
            if (is_skip) {
                continue;
            }

            if (is_debug_info) {
                cerr << "\n\n\nDEBUG:: Matching node: " << cur_matched_node->to_string();
            }

            IR* new_literal_node = new IR(TypeStringLiteral, OP0());
            new_literal_node->set_is_instantiated(true);
            new_literal_node->mutate_literal(fix_affi);
            cur_stmt_root->swap_node(cur_matched_node, new_literal_node);
            ir_to_deep_drop.push_back(cur_matched_node);

            if (is_debug_info) {
                cerr << ", mutated to node: " << new_literal_node->to_string() << "\n\n\n";
            }
        }

        for (auto cur_drop: ir_to_deep_drop) {
            cur_drop->deep_drop();
        }

        return;

    }

    else if (
        findStringIn(res_str, "unsupported comparison operator: ")
    ) {
        /*
         * Type mismatched when comparing between two literals.
         * SELECT COUNT( *) FROM v0 WHERE v0.c5 = B'010' AND v0.c3 = B'10001111101';
         *   pq: unsupported comparison operator: <decimal> = <varbit>
         * */
        vector<IR*> ir_to_deep_drop;

        vector<IR*> v_binary_operator = p_oracle->ir_wrapper
                .get_ir_node_in_stmt_with_type(cur_stmt_root, TypeBinExprFmtWithParen, false, true);
        for (IR* cur_binary_operator : v_binary_operator) {

            bool is_skip = false;
            for (auto ir_drop: ir_to_deep_drop) {
                if (p_oracle->ir_wrapper.is_ir_in(cur_binary_operator, ir_drop)) {
                    is_skip = true;
                    break;
                }
            }
            if (is_skip) {
                continue;
            }

            if (cur_binary_operator->get_middle() == " LIKE ") {
                /*
                 * SELECT COUNT( *) FROM v0 WHERE c1 LIKE true;
                 * pq: unsupported comparison operator: <bool> LIKE <bool>
                 * For LIKE operator, both sides should be STRING types
                 */
                if (is_debug_info) {
                    cerr << "\n\n\nDEBUG:: Getting the LIKE error fixing. ";
                }

                IR* new_left_node = new IR(TypeUnknown, OP0(), NULL, NULL);
                new_left_node->set_is_instantiated(true);
                if (m_datatype2column.count(AFFISTRING) > 0) {
                    string col_str = vector_rand_ele(m_datatype2column[AFFISTRING]);
                    new_left_node->set_str_val(col_str);
                } else {
                    new_left_node->mutate_literal(AFFISTRING);
                }

                IR* new_right_node = new IR(TypeUnknown, OP0(), NULL, NULL);
                new_right_node->set_is_instantiated(true);
                new_right_node->mutate_literal(AFFISTRING);

                // Replacing the old nodes.
                IR* old_left_node = cur_binary_operator->get_left();
                IR* old_right_node = cur_binary_operator->get_right();

                cur_binary_operator->update_left(new_left_node);
                cur_binary_operator->update_right(new_right_node);

                ir_to_deep_drop.push_back(old_left_node);
                ir_to_deep_drop.push_back(old_right_node);

                if (is_debug_info) {
                    cerr << "\n\n\nDEBUG::Mutated the unsupported LIKE comparison to "
                         << cur_binary_operator->to_string() << "\n\n\n";
                }

            }

            else if (
                    cur_binary_operator->get_middle() == " @> " ||
                    cur_binary_operator->get_middle() == " @< " ||
                    cur_binary_operator->get_middle() == " >@ " ||
                    cur_binary_operator->get_middle() == " <@ " ||
                    cur_binary_operator->get_middle() == " #> " ||
                    cur_binary_operator->get_middle() == " #< " ||
                    cur_binary_operator->get_middle() == " #>> " ||
                    cur_binary_operator->get_middle() == " #<< " ||
                    cur_binary_operator->get_middle() == " ? " ||
                    cur_binary_operator->get_middle() == " ?& " ||
                    cur_binary_operator->get_middle() == " ?| " ||
                    cur_binary_operator->get_middle() == " -> " ||
                    cur_binary_operator->get_middle() == " ->> "
            ) {
                // Do not apply operations that is related to the JSON types.
                cur_binary_operator->op_->middle_ = " = ";
            }

            else {
                /*
                 * If it is other types of comparison, follow the types from the left side.
                 * select * FROM v0 where 123 < 'abc';
                 * ERROR: unsupported comparison operator: <int> < <string>
                 */

                /*
                 * This rule also matches the two sides column comparisons.
                 * select * from v0 where c1 > c2;
                 * ERROR: unsupported comparison operator: <int> > <string>
                 * */

                if (is_debug_info) {
                    cerr << "\n\n\nDEBUG:: Getting the other types (non-like) of the comparison operator fixing. ";
                }

                string str_target_type = "";
                vector<string> v_tmp_split;

                // Get the troublesome variable.
                v_tmp_split = string_splitter(res_str, " operator: <");
                if (v_tmp_split.size() <= 1) {
                    cerr << "\n\n\nERROR: Cannot find  operator: < in the string " << res_str << "\n\n\n";
                    return;
                }
                str_target_type = v_tmp_split.at(1);

                v_tmp_split = string_splitter(str_target_type, ">");
                if (v_tmp_split.size() <= 1) {
                    cerr << "\n\n\nERROR: Cannot find > in the string: "<< str_target_type << " \n\n\n";
                    return;
                }
                str_target_type = v_tmp_split.at(0);

                DATAAFFINITYTYPE fixed_affi = this->detect_str_affinity(str_target_type);

                // Replace the right node with the new affinity literals.
                IR* new_right_node = new IR(TypeUnknown, OP0(), NULL, NULL);
                new_right_node->set_is_instantiated(true);
                new_right_node->mutate_literal(fixed_affi);

                IR* old_right_node = cur_binary_operator->get_right();
                cur_binary_operator->update_right(new_right_node);
                if (old_right_node != NULL) {
                    ir_to_deep_drop.push_back(old_right_node);
                }

                if (is_debug_info) {
                    cerr << "\n\n\nDEBUG::Mutated the unsupported comparison to "
                         << cur_binary_operator->to_string() << "\n\n\n";
                }
            }
        }

        for (auto ir_drop: ir_to_deep_drop) {
            ir_drop->deep_drop();
        }

    }

    else if (
            findStringIn(res_str, "parsing as type ") &&
            findStringIn(res_str, "could not parse")
        ) {

//        pq: unsupported comparison operator: c4 = ANY ARRAY['2ci10p4', '09-10-66 BC 11:15:40.8179-2', '05-19-81 BC 03:33:31.6577+2', '05-08-4034 BC 06:58:13-5', '05-1
//        0-3656 14:14:21-3']: parsing as type timestamp: could not parse "2ci10p4"

        vector<IR*> ir_to_deep_drop;

        string str_literal = "";
        string str_target_type = "";
        vector<string> v_tmp_split;

        // Get the troublesome variable.
        v_tmp_split = string_splitter(res_str, "could not parse ");
        if (v_tmp_split.size() <= 1) {
            cerr << "\n\n\nERROR: Cannot find parsing as type  in the string. \n\n\n";
            return;
        }
        str_literal = v_tmp_split.at(1);

        // Remove the "" symbol.
        if (str_literal.size() > 0 && str_literal[0] == '"') {
            str_literal = str_literal.substr(1, str_literal.size()-1);
        }
        if (str_literal.size() > 0 && str_literal[str_literal.size()-1] == '\n') {
            str_literal = str_literal.substr(0, str_literal.size()-1);
        }
        if (str_literal.size() > 0 && str_literal[str_literal.size()-1] == '"') {
            str_literal = str_literal.substr(0, str_literal.size()-1);
        }

        // Get the target type name.
        v_tmp_split = string_splitter(res_str, "parsing as type ");
        if (v_tmp_split.size() <= 1) {
            cerr << "\n\n\nERROR: Cannot find parsing as type  in the string. \n\n\n";
            return;
        }
        str_target_type = v_tmp_split.at(1);

        v_tmp_split = string_splitter(str_target_type, ":");
        if (v_tmp_split.size() <= 1) {
            cerr << "\n\n\nERROR: Cannot find : in the string," << str_target_type << "\n\n\n";
            return;
        }
        str_target_type = v_tmp_split.at(0);

        DATAAFFINITYTYPE fix_affi = detect_str_affinity(str_target_type);

        // Find all the matching literals.
        vector<IR*> v_matched_node = p_oracle->ir_wrapper
                .get_ir_node_in_stmt_with_type(cur_stmt_root, str_literal, false, true);

        if (v_matched_node.size() == 0) {
            v_matched_node = p_oracle->ir_wrapper
                    .get_ir_node_in_stmt_with_type(cur_stmt_root, "'" + str_literal + "'", false, true);
        }

        for (auto cur_match_node : v_matched_node) {
            bool is_skip = false;
            for (IR* cur_drop : ir_to_deep_drop) {
                if (p_oracle->ir_wrapper.is_ir_in(cur_match_node, cur_drop)) {
                    is_skip = true;
                    break;
                }
            }
            if (is_skip) {
                continue;
            }

            IR* newLiteralNode = new IR(TypeUnknown, OP0());
            newLiteralNode->set_is_instantiated(true);
            newLiteralNode->mutate_literal(fix_affi);

            cur_stmt_root->swap_node(cur_match_node, newLiteralNode);
            ir_to_deep_drop.push_back(cur_match_node);
        }

    }

    return;
}

void Mutator::fix_column_literal_op_err(IR* cur_stmt_root, string res_str, bool is_debug_info) {
    /*
     * Fix the error when comparing columns to mismatched string literals.
     */

    if (
            findStringIn(res_str, "ERROR: could not parse ") &&
            findStringIn(res_str, " as type ")
        ) {

        vector<IR*> ir_to_deep_drop;

        if (is_debug_info) {
            cerr << "\n\n\nDEBUG:: Inside the ERROR: could not parse literal as type TYPE \n\n\n";
        }

        string str_literal = "";
        string str_target_type = "";
        vector<string> v_tmp_split;

        // Get the troublesome variable.
        v_tmp_split = string_splitter(res_str, "ERROR: could not parse ");
        if (v_tmp_split.size() <= 1) {
            cerr << "\n\n\nERROR: Cannot find ERROR: could not parse  in the string. \n\n\n";
            return;
        }
        str_literal = v_tmp_split.at(1);

        v_tmp_split = string_splitter(str_literal, " as type ");
        if (v_tmp_split.size() <= 1) {
            cerr << "\n\n\nERROR: Cannot find as type in the string. \n\n\n";
            return;
        }
        str_literal = v_tmp_split.at(0);

        // Get the target type name.
        v_tmp_split = string_splitter(res_str, " as type ");
        if (v_tmp_split.size() <= 1) {
            cerr << "\n\n\nERROR: Cannot find : expected in the string. \n\n\n";
            return;
        }
        str_target_type = v_tmp_split.at(1);

        v_tmp_split = string_splitter(str_target_type, ": ");
        if (v_tmp_split.size() <= 1) {
            cerr << "\n\n\nERROR: Cannot find to be of type in the string. \n\n\n";
            return;
        }
        str_target_type = v_tmp_split.at(0);

        DATAAFFINITYTYPE fix_affi = detect_str_affinity(str_target_type);

        vector<IR*> v_matched_nodes = p_oracle->ir_wrapper
                .get_ir_node_in_stmt_with_type(cur_stmt_root, str_literal, false, true);
        for (IR* cur_matched_node: v_matched_nodes) {

            bool is_skip = false;
            for (auto cur_drop: ir_to_deep_drop) {
                if (p_oracle->ir_wrapper.is_ir_in(cur_matched_node, cur_drop)) {
                    is_skip = true;
                    break;
                }
            }
            if (is_skip) {
                continue;
            }

            IR* new_matched_node = new IR(TypeUnknown, OP0());
            new_matched_node->set_is_instantiated(true);
            new_matched_node->mutate_literal(fix_affi);
            cur_stmt_root->swap_node(cur_matched_node, new_matched_node);
            ir_to_deep_drop.push_back(cur_matched_node);

            if (is_debug_info) {
                cerr << "\n\n\nDEBUG::Mutated the literal to " << cur_matched_node->to_string() << "\n\n\n";
            }
        }

        for (auto cur_drop: ir_to_deep_drop) {
            cur_drop->deep_drop();
        }

        return;
    }

    else if (
            findStringIn(res_str, "unsupported binary operator: ") &&
            findStringIn(res_str, "(desired ")
        ) {

        if (is_debug_info) {
            cerr << "\n\n\nDEBUG:: Inside the unsupported binary operator: (desired ...)\n\n\n";
            cerr << "\n\n\nDEBUG:: ERROR message: " << res_str << "\n\n\n";
        }

        vector<IR*> ir_to_deep_drop;

        string str_target_type = "";
        string str_operator = "";
        vector<string> v_tmp_split;

        // Get the target type name.
        v_tmp_split = string_splitter(res_str, "> ");
        if (v_tmp_split.size() <= 1) {
            cerr << "\n\n\nERROR: Cannot find > in the string. \n\n\n";
            return;
        }
        str_operator = "";
        for (int i = 1; i < v_tmp_split.size(); i++) {
            str_operator += v_tmp_split.at(i);
            if ((i+1) < v_tmp_split.size()) {
                str_operator += "> ";
            }
        }

        v_tmp_split = string_splitter(str_operator, " <");
        if (v_tmp_split.size() < 2) {
            cerr << "\n\n\nERROR: Cannot find < in the string. \n\n\n";
            return;
        }
        str_operator = v_tmp_split.at(v_tmp_split.size() - 3);

        // Get the target type name.
        v_tmp_split = string_splitter(res_str, "(desired <");
        if (v_tmp_split.size() <= 1) {
            cerr << "\n\n\nERROR: Cannot find (desired < in the string. \n\n\n";
            return;
        }
        str_target_type = v_tmp_split.at(1);

        v_tmp_split = string_splitter(str_target_type, ">)");
        if (v_tmp_split.size() <= 1) {
            cerr << "\n\n\nERROR: Cannot find >) in the string. \n\n\n";
            return;
        }
        str_target_type = v_tmp_split.at(0);

        DATAAFFINITYTYPE fix_affi = detect_str_affinity(str_target_type);

        vector<IR*> v_binary_operator = p_oracle->ir_wrapper
                .get_ir_node_in_stmt_with_type(cur_stmt_root, TypeBinaryExpr, false, true);
        for (IR* cur_binary_operator : v_binary_operator) {
            if (cur_binary_operator->get_middle() != (" " + str_operator + " ")) {
                continue;
            }

            bool is_skip = false;
            for (IR* prev_dropped : ir_to_deep_drop) {
                if (p_oracle->ir_wrapper.is_ir_in(cur_binary_operator, prev_dropped)) {
                    is_skip = true;
                    break;
                }
            }
            if (is_skip) {
                continue;
            }

            IR* par_node = cur_binary_operator->get_parent();
            if (par_node == NULL) {
                if (is_debug_info) {
                    cerr << "\n\n\nERROR:: Cannot find parent node from the cur_binary_operator->get_parent();\n\n\n";
                }
                return;
            }
            IR* new_ir = new IR(TypeUnknown, OP0(), NULL, NULL);
            new_ir->set_is_instantiated(true);
            new_ir->mutate_literal(fix_affi);

            par_node->swap_node(cur_binary_operator, new_ir);

            cur_binary_operator->parent_ = NULL;
            ir_to_deep_drop.push_back(cur_binary_operator);

        }

        for (IR* cur_dropped : ir_to_deep_drop) {
            cur_dropped->deep_drop();
        }

        return;

    }
    else if (
            findStringIn(res_str, "unsupported binary operator")
            ) {

        /*
         * pq: unsupported binary operator: <string> / <string>
         * Forced change the binary operator to '=' for now.
         * TODO:: apply operator specificed operations.
         * */

        if (is_debug_info) {
            cerr << "\n\n\nDEBUG:: Inside the unsupported binary operator. clean \n\n\n";
            cerr << "\n\n\nDEBUG:: ERROR message: " << res_str << "\n\n\n";
        }

        string str_operator = "";
        vector<string> v_tmp_split;

        // Get the target type name.
        v_tmp_split = string_splitter(res_str, "> ");
        if (v_tmp_split.size() <= 1) {
            cerr << "\n\n\nERROR: Cannot find > in the string. \n\n\n";
            return;
        }
        str_operator = "";
        for (int i = 1; i < v_tmp_split.size(); i++) {
            str_operator += v_tmp_split.at(i);
            if ((i+1) < v_tmp_split.size()) {
                str_operator += "> ";
            }
        }

        v_tmp_split = string_splitter(str_operator, " <");
        if (v_tmp_split.size() < 2) {
            cerr << "\n\n\nERROR: Cannot find < in the string. \n\n\n";
            return;
        }

        str_operator = v_tmp_split.at(v_tmp_split.size() - 2);

        vector<IR*> v_binary_operator = p_oracle->ir_wrapper
                .get_ir_node_in_stmt_with_type(cur_stmt_root, TypeBinaryExpr, false, true);
        for (IR* cur_binary_operator : v_binary_operator) {
            if (cur_binary_operator->get_middle() != (" " + str_operator + " ")) {
                continue;
            }
            cur_binary_operator->op_->middle_ = " = ";
        }

    }

}

void Mutator::fix_col_type_rel_errors(IR* cur_stmt_root, string res_str, int trial, bool is_debug_info) {

    vector tmp_err_note = string_splitter(res_str, '"');
    string ori_str = cur_stmt_root->to_string();

    if (trial < 7 &&
        findStringIn(res_str, "(desired <") &&
        findStringIn(res_str, "unknown function")
        ) {
        // select count(*) from v0 where md5(v1);
        // ERROR: unknown signature: md5(int) (desired <bool>)
        // The problem is that the function is directly used in the WHERE clause,
        // where the where clause only accept BOOL type.

        if (is_debug_info) {
            cerr << "\n\n\nGetting unknown function(signature), (desired <bool>). "
                    "Guessing it is coming from the function direct usage in the"
                    "WHERE clause. \n\n\n";
        }

        string str_func_name = "";
        vector<string> tmp_str_split;
        tmp_str_split = string_splitter(res_str, "unknown signature: ");
        if (tmp_str_split.size() < 2) {
            cerr << "\n\n\n ERROR: The error message: " << res_str << " does not match the pattern. \n\n\n";
            return;
        }
        str_func_name = tmp_str_split.at(1);
        tmp_str_split = string_splitter(str_func_name, "(");
        if (tmp_str_split.size() < 2) {
            cerr << "\n\n\n ERROR: The error message: " << res_str << " does not match the pattern. \n\n\n";
            return;
        }
        str_func_name = tmp_str_split.at(0);

        vector<IR*> v_func_names = p_oracle->ir_wrapper
                .get_ir_node_in_stmt_with_type(cur_stmt_root, str_func_name, false, true);

        // Dirty fix, directly modify the TypeFunctionExpr type nodes.
        for (IR* cur_func_node : v_func_names) {
            IR* cur_func_expr = p_oracle->ir_wrapper.get_parent_node_with_type(cur_func_node, TypeFuncExpr);
            if (cur_func_expr != NULL) {
                cur_func_expr->op_->suffix_ += " = 0";
            }
        }
    }
    else if (trial < 7 &&
        findStringIn(res_str, "unknown function") ||
        findStringIn(res_str, "unknown signature")
            ) {

        if (is_debug_info) {
            cerr << "\n\n\nGetting unknown function(signature), ";
        }

        vector<IR*> all_func_ir = p_oracle->ir_wrapper
                .get_ir_node_in_stmt_with_type(cur_stmt_root,
                                               DataFunctionName, false, true);

        if (is_debug_info) {
            for (IR *cur_func_ir : all_func_ir) {
                cerr << "\ngetting cur_func_ir: " << cur_func_ir->to_string();
            }
            cerr << "\n\n\n";
        }

//        for (IR *cur_func_ir : all_func_ir) {
//            cur_func_ir->set_is_instantiated(false);
//        }

        vector<IR*> ir_to_deep_drop;
        for (IR* cur_func_ir : all_func_ir) {
            this->instan_func_expr(cur_func_ir, ir_to_deep_drop, is_debug_info);
        }
        for (IR* ir_drop : ir_to_deep_drop) {
            ir_drop->deep_drop();
        }
    }
    else if (
            findStringIn(res_str, "unsupported comparison") ||
                (
                    findStringIn(res_str, "parsing as type ") &&
                    findStringIn(res_str, "could not parse")
                )
            ) {
        fix_literal_op_err(cur_stmt_root, res_str, is_debug_info);
    }
    else if (
            findStringIn(res_str, "unsupported binary operator") ||
            (
                    findStringIn(res_str, "ERROR: could not parse ") &&
                    findStringIn(res_str, " as type ")
            )
            ){
        fix_column_literal_op_err(cur_stmt_root, res_str, is_debug_info);
    }
    else if (findStringIn(res_str, "to be of type")) {
        // Getting error: pq: expected B'111111' to be of type string[], found type varbit

        string err_str_type = "";
        vector<string> tmp_str_split;
        tmp_str_split = string_splitter(res_str, "to be of type ");
        if (tmp_str_split.size() < 2) {
            cerr << "\n\n\n ERROR: The error message: " << res_str << " does not match the pattern. \n\n\n";
            return;
        }
        err_str_type = tmp_str_split.at(1);
        tmp_str_split = string_splitter(err_str_type, ",");
        if (tmp_str_split.size() < 2) {
            cerr << "\n\n\n ERROR: The error message: " << res_str << " does not match the pattern. \n\n\n";
            return;
        }
        err_str_type = tmp_str_split.at(0);

        string err_str_literal = "";
        tmp_str_split = string_splitter(res_str, "expected ");
        if (tmp_str_split.size() < 2) {
            cerr << "\n\n\n ERROR: The error message: " << res_str << " does not match the pattern. \n\n\n";
            return;
        }
        err_str_literal = tmp_str_split.at(1);
        tmp_str_split = string_splitter(err_str_literal, " to be of type");
        if (tmp_str_split.size() < 2) {
            cerr << "\n\n\n ERROR: The error message: " << res_str << " does not match the pattern. \n\n\n";
            return;
        }
        err_str_literal = tmp_str_split.at(0);

        DATAAFFINITYTYPE corr_affi = this->detect_str_affinity(err_str_type);

        vector<IR*> v_matched_node = p_oracle->ir_wrapper
                .get_ir_node_in_stmt_with_type(cur_stmt_root, err_str_literal, false, true);

        for (IR* cur_matched_node : v_matched_node) {
            cur_matched_node->set_data_affinity(corr_affi);
            cur_matched_node->mutate_literal(corr_affi);
        }

        if (is_debug_info) {
            cerr << "DEPENDENCY: Fixing semantic error. Matching rule 'to be of type' from: \n" << res_str
                 << "\n getting new corr_affi: " << get_string_by_affinity_type(corr_affi) << "\n\n\n";
        }

    }


    else if (tmp_err_note.size() >= 3 && trial < 7) {

        vector<string> v_err_note;

        for (int i = 1; i < tmp_err_note.size(); i+=2) {
            v_err_note.push_back(tmp_err_note.at(i));
        }

        if (v_err_note.size() == 0) {
            return;
        }

        for (string &cur_err_note: v_err_note) {
            vector<IR *> node_matching;
            vector<string> potential_matched_str;
            potential_matched_str.push_back(cur_err_note);
            potential_matched_str.push_back("'" + cur_err_note + "'");
            node_matching = p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type
                    (cur_stmt_root,
                     potential_matched_str, false, true);

            vector<IR *> node_matching_filtered;

            for (IR *cur_node_matching: node_matching) {
                if (cur_node_matching->get_data_flag() != ContextDefine &&
                    cur_node_matching->get_data_flag() != ContextUndefine &&
                    cur_node_matching->get_data_flag() != ContextNoModi
                        ) {
                    cur_node_matching->set_is_instantiated(false);
                    node_matching_filtered.push_back(cur_node_matching);
                }
            }

            vector<vector<IR*>> tmp_node_matching;
            tmp_node_matching.push_back(node_matching_filtered);

            if (is_debug_info) {
                cerr << "\n\n\nFor error message: \n" << res_str
                     << "\nGetting node: ";
                for (IR *cur_node_matching: node_matching_filtered) {
                    cerr << cur_node_matching->to_string() << ", ";
                }
                cerr << "\n\n";
            }
            this->instan_dependency(cur_stmt_root, tmp_node_matching, false);
        }
    } else {
        this->reset_data_library_single_stmt();
        this->validate(cur_stmt_root);
    }

    if (is_debug_info) {
        cerr << "After trying to fix the error from the error message, we get ori str: \n"
             << ori_str << "\nto: \n" << cur_stmt_root->to_string() << "\n\n\n";
    }

}

void Mutator::rollback_instan_lib_changes() {

    for(string& cur_create_table: v_create_table_names_single) {
        if (find_vector(v_table_names, cur_create_table)) {
            remove_vector(v_table_names, cur_create_table);
        }
        if (find_vector(v_view_name, cur_create_table)) {
            remove_vector(v_view_name, cur_create_table);
        }
        if (find_vector(v_table_with_partition, cur_create_table)) {
            remove_vector(v_table_with_partition, cur_create_table);
        }
        if (find_vector(v_foreign_table_name, cur_create_table)) {
            remove_vector(v_foreign_table_name, cur_create_table);
        }

        if (find_map(m_table2columns, cur_create_table)) {
            vector<string> all_mapped_col = m_table2columns[cur_create_table];
            for (string cur_mapped_col: all_mapped_col) {
                if (find_map(m_column2datatype, cur_mapped_col)) {
                    remove_map(m_column2datatype, cur_mapped_col);
                }
            }
            remove_map(m_table2columns, cur_create_table);
        }
        if (find_map(m_table2index, cur_create_table)) {
            remove_map(m_table2index, cur_create_table);
        }
        if (find_map(m_table2partition, cur_create_table)) {
            remove_map(m_table2partition, cur_create_table);
        }
    }

    this->v_create_table_names_single.clear();
    this->v_create_view_names_single.clear();

}

void Mutator::fix_instan_error(IR* cur_stmt_root, string res_str, int trial, bool is_debug_info) {

    string ori_str = cur_stmt_root->to_string();

    this->rollback_instan_lib_changes();

    vector<vector<IR*>> tmp_node_matching;

    SemanticErrorType cur_error_type = p_oracle->detect_semantic_error_type(res_str);

    if (cur_error_type == ColumnTypeRelatedError) {
        this->fix_col_type_rel_errors(cur_stmt_root, res_str, trial, is_debug_info);
    } else {
        this->reset_data_library_single_stmt();
        this->validate(cur_stmt_root, is_debug_info);
    }

}