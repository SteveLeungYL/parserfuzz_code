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
#include <filesystem>
#include <fstream>
#include <iostream>
#include <list>
#include <sstream>
#include <string>

#define _NON_REPLACE_

using namespace std;

#define find_vector(x, y) (find(x.begin(), x.end(), y) != x.end())
#define remove_vector(x, y) \
  (x.erase(std::remove(x.begin(), x.end(), y), x.end()));
#define find_map(x, y) (x.count(y) > 0)
#define remove_map(x, y) (x.erase(y))

set<IR*>
    Mutator::visited; // Already validated/fixed node. Avoid multiple fixing.
map<string, vector<string>> Mutator::m_table2columns,
    Mutator::m_table2columns_snapshot; // Table name to column name mapping.
map<string, vector<string>> Mutator::m_table2index,
    Mutator::m_table2index_snapshot; // Table name to index mapping.
vector<string> Mutator::v_table_names,
    Mutator::v_table_names_snapshot;           // All saved table names
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
map<string, vector<string>>
    Mutator::m_enforced_table2alias_single; // All table alias that is NOT
                                            // in the WITH clause.
map<string, string>
    Mutator::m_alias2column_single; // column name to alias mapping.
/* A mapping that defines an aliased table name to its resulting column name. */
map<string, vector<string>> Mutator::m_alias_table2column_single;

map<string, DataAffinity> Mutator::m_column2datatype,
    Mutator::m_column2datatype_snapshot; // New solution.
map<DATAAFFINITYTYPE, vector<string>> Mutator::m_datatype2column,
    Mutator::m_datatype2column_snapshot; // New solution.

map<DATAAFFINITYTYPE, vector<string>> Mutator::m_datatype2literals,
    Mutator::m_datatype2literals_snapshot;

vector<string> Mutator::v_statistics_name,
    Mutator::v_statistics_name_snapshot; // All statistic names defined in the
                                         // current stmt.

// Views should share the same handling as Tables
vector<string> Mutator::v_view_name,
    Mutator::v_view_name_snapshot; // All saved view names.
// The column to view mapping will be saved into the m_table2columns mapping.

vector<string> Mutator::v_sequence_name,
    Mutator::v_sequence_name_snapshot; // All sequence names defined in the
                                       // current SQL.
vector<string> Mutator::v_constraint_name,
    Mutator::v_constraint_name_snapshot; // All constraint names defined in
                                         // the current SQL.
vector<string> Mutator::v_family_name,
    Mutator::v_family_name_snapshot; // All family names defined in
                                     // the current SQL.
vector<string> Mutator::v_foreign_table_name,
    Mutator::v_foreign_table_name_snapshot; // All foreign table names defined
                                            // in the current SQL.
// vector<string>
//    Mutator::v_create_foreign_table_names_single; // All foreign table names
//                                                  // created in the current
//                                                  single SQL statement.

vector<string> Mutator::v_sys_column_name;
vector<string> Mutator::v_sys_catalogs_name;

vector<string> Mutator::v_table_with_partition,
    Mutator::v_table_with_partition_snapshot;
map<string, vector<string>> Mutator::m_table2partition,
    Mutator::m_table2partition_snapshot;

map<string, DataAffinity> Mutator::set_session_lib;
vector<string> Mutator::all_saved_set_session;

map<string, DataAffinity> Mutator::storage_param_lib;
vector<string> Mutator::all_storage_param;

vector<int> Mutator::v_int_literals, Mutator::v_int_literals_snapshot;
vector<double> Mutator::v_float_literals, Mutator::v_float_literals_snapshot;
vector<string> Mutator::v_string_literals, Mutator::v_string_literals_snapshot;

//#define GRAPHLOG

IR* Mutator::deep_copy_with_record(const IR* root, const IR* record)
{
  IR *left = NULL, *right = NULL, *copy_res;

  if (root->left_)
    left = deep_copy_with_record(root->left_, record);
  if (root->right_)
    right = deep_copy_with_record(root->right_, record);

  if (root->op_)
    copy_res = new IR(root->type_,
        OP3(root->op_->prefix_, root->op_->middle_, root->op_->suffix_),
        left, right, root->float_val_, root->str_val_, root->name_,
        root->mutated_times_, root->data_flag_);
  else
    copy_res = new IR(root->type_, NULL, left, right, root->float_val_, root->str_val_,
        root->name_, root->mutated_times_, root->data_flag_);

  copy_res->data_type_ = root->data_type_;

  if (root == record && record != NULL) {
    this->record_ = copy_res;
  }

  return copy_res;
}

vector<IR*> Mutator::mutate_stmtlist(IR* root)
{

  // Mutate on TypeStmtlist node. Only do strategy_insert and strategy_delete.

  IR* cur_root = nullptr;
  vector<IR*> res_vec;

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
  IR* new_stmt_ir = NULL;
  while (new_stmt_ir == NULL) {
    if (!disable_rsg_generator && get_rand_int(2)) {
      // For 1/2 chance, insert one new stmt from RSG.
      string tmp_stmt_str = rsg_generate_valid(TypeStmt);
      vector<IR*> v_tmp_ir = this->parse_query_str_get_ir_set(tmp_stmt_str);
      if (v_tmp_ir.size() == 0) {
        new_stmt_ir = nullptr;
        continue;
      } else {
        IR* tmp_root = v_tmp_ir.back();
        new_stmt_ir = p_oracle->ir_wrapper.get_first_stmt_from_root(tmp_root);
        tmp_root->detach_node(new_stmt_ir);
        tmp_root->deep_drop();
      }
    } else {
      new_stmt_ir = get_from_libary_with_type(TypeStmt);
    }
    if (new_stmt_ir == nullptr || new_stmt_ir->left_ == nullptr) {
      // kStmt is empty
      cur_root->deep_drop();
      return res_vec;
    }
    if (new_stmt_ir->get_left()->get_ir_type() == TypeSelectStmt) {
      new_stmt_ir->deep_drop();
      new_stmt_ir = NULL;
    }
    continue;
  }
  IR* new_stmt_ir_tmp = new_stmt_ir->left_->deep_copy(); // kStatement -> specific_stmt_type
  new_stmt_ir->deep_drop();
  new_stmt_ir = new_stmt_ir_tmp;

  p_oracle->ir_wrapper.set_ir_root(cur_root);
  if (!p_oracle->ir_wrapper.append_stmt_at_idx(new_stmt_ir, insert_pos)) {
    new_stmt_ir->deep_drop();
    cur_root->deep_drop();
    return res_vec;
  }
  res_vec.push_back(cur_root);

  return res_vec;
}

vector<IR*> Mutator::mutate_all(IR* ori_ir_root, IR* ir_to_mutate,
    u64& total_mutate_failed,
    u64& total_mutate_num)
{

  IR* root = ori_ir_root;
  vector<IR*> res;
  vector<IR*> v_mutated_ir;

  if (ir_to_mutate->get_ir_type() == TypeRoot)
    return res;

  /* For mutating kStmtList only */
  if (ir_to_mutate->get_ir_type() == TypeStmtList) {
    v_mutated_ir = mutate_stmtlist(root);
    for (IR* mutated_ir : v_mutated_ir) {

      IR* extract_struct_root = mutated_ir->deep_copy();
      string extract_struct_str = extract_struct_deep(extract_struct_root);
      extract_struct_root->deep_drop();

      unsigned tmp_hash = hash(extract_struct_str);
      if (global_hash_.find(tmp_hash) != global_hash_.end()) {
        mutated_ir->deep_drop();
        continue;
      }
      global_hash_.insert(tmp_hash);
      res.push_back(mutated_ir);
    }

    return res;
  }

  // else, for mutating single IR node.

  v_mutated_ir = mutate(ir_to_mutate);

  for (IR* new_ir : v_mutated_ir) {
    total_mutate_num++;
    if (!root->swap_node(ir_to_mutate, new_ir)) {
      new_ir->deep_drop();
      total_mutate_failed++;
      continue;
    }

    IR* extract_struct_root = root->deep_copy();
    string extract_struct_str = extract_struct_deep(extract_struct_root);
    extract_struct_root->deep_drop();
    /* Check whether the mutated IR is the same as before */

    unsigned extract_struct_hash = hash(extract_struct_str);
    if (global_hash_.find(extract_struct_hash) != global_hash_.end()) {
      root->swap_node(new_ir, ir_to_mutate);
      new_ir->deep_drop();
      total_mutate_failed++;
      continue;
    }
    global_hash_.insert(extract_struct_hash);

    /* Mutate successful. Save the mutation and recover the original ir_tree */
    res.push_back(root->deep_copy());
    root->swap_node(new_ir, ir_to_mutate);
    new_ir->deep_drop();
  }

  return res;
}

void Mutator::init_common_string(string filename)
{
  common_string_library_.push_back("DO_NOT_BE_EMPTY");
  if (filename != "") {
    ifstream input_string(filename);
    string s;

    while (getline(input_string, s)) {
      common_string_library_.push_back(s);
    }
  }
}

void Mutator::init_sql_type_alias_2_type()
{

  sql_type_alias_2_type["AFFINAME"] = "AFFISTRING";

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

  sql_type_alias_2_type["AFFITIME WITH TIME ZONE"] = "AFFITIME";
  sql_type_alias_2_type["AFFITIME ZONE"] = "AFFITIME";

  sql_type_alias_2_type["AFFITIMESTAMP WITHOUT TIME ZONE"] = "AFFITIME";
  sql_type_alias_2_type["AFFITIMESTAMP WITH TIME ZONE"] = "AFFITIME";
}

void Mutator::init_data_library()
{

  string func_file_name = FUNCTION_TYPE_PATH;

  ifstream input_file(func_file_name);
  string s;

  cout << "[*] begin init function_types library: " << func_file_name << endl;

  string function_types_path = FUNCTION_TYPE_PATH;
  std::stringstream buffer_func_types;
  buffer_func_types << input_file.rdbuf();
  string func_types_str = buffer_func_types.str();

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

inline void Mutator::init_value_library()
{
  if (value_library_.size() != 0) {
    return;
  }
  vector<unsigned long> value_lib_init = { 0,
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
    (unsigned long)LDBL_MIN };

  value_library_.insert(value_library_.begin(), value_lib_init.begin(),
      value_lib_init.end());

  return;
}

void Mutator::init_library()
{

  // init value_library_
  init_value_library();

  if (not_mutatable_types_.size() == 0) {
    float_types_.insert({ TypeFloatLiteral });
    int_types_.insert(TypeIntegerLiteral);
    string_types_.insert(TypeStringLiteral);

    split_stmt_types_.insert(TypeStmt);
    split_substmt_types_.insert({ TypeSelectStmt });

    not_mutatable_types_.insert({ TypeRoot, TypeStmtList, TypeStmt });

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
    string file1d, string f_gen_type,
    u8 (*run_target)(char**, u32, string, int, string&))
{

  /* init common_string_library */
  if (!f_common_string.empty()) {
    init_common_string(f_common_string);
  }

  ifstream input_test(f_testcase);
  string line;

  // init lib from multiple sql
  while (getline(input_test, line)) {

    vector<IR*> v_ir = parse_query_str_get_ir_set(line);
    if (v_ir.size() <= 0) {
      continue;
    }

    IR* v_ir_root = v_ir.back();

    add_all_to_library(v_ir_root->to_string(), {}, run_target);
    v_ir_root->deep_drop();
  }

  return;
}

vector<IR*> Mutator::mutate(IR* input)
{
  vector<IR*> res;

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

bool Mutator::replace(IR* root, IR* old_ir, IR* new_ir)
{
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

IR* Mutator::locate_parent(IR* root, IR* old_ir)
{

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

IR* Mutator::strategy_delete(IR* cur)
{
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

IR* Mutator::strategy_insert(IR* cur)
{

  assert(cur);

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

IR* Mutator::strategy_replace(IR* cur)
{
  assert(cur);

  auto new_node = get_from_libary_with_type(cur->type_);

  // Could be NULL.
  return new_node;
}

bool Mutator::lucky_enough_to_be_mutated(unsigned int mutated_times)
{
  if (get_rand_int(mutated_times + 1) < LUCKY_NUMBER) {
    return true;
  }
  return false;
}

pair<string, string> Mutator::get_data_2d_by_type(DATATYPE type1,
    DATATYPE type2)
{
  pair<string, string> res("", "");
  auto size = data_library_2d_[type1].size();

  if (size == 0)
    return res;
  auto rint = get_rand_int(size);

  int counter = 0;
  for (auto& i : data_library_2d_[type1]) {
    if (counter++ == rint) {
      return std::make_pair(i.first, vector_rand_ele(i.second[type2]));
    }
  }
  return res;
}

string Mutator::get_a_string()
{
  unsigned com_size = common_string_library_.size();
  if (com_size == 0) {
    return "hello";
  } else {
    return common_string_library_[get_rand_int(com_size)];
  }
  // }
}

unsigned long Mutator::get_a_val()
{
  assert(value_library_.size());

  return vector_rand_ele(value_library_);
}

unsigned long Mutator::hash(string& sql)
{
  return fuzzing_hash(sql.c_str(), sql.size());
}

unsigned long Mutator::hash(IR* root)
{
  auto tmp_str = move(root->to_string());
  return this->hash(tmp_str);
}

void Mutator::debug(IR* root) { this->debug(root, 0); }

void Mutator::debug(IR* root, unsigned level)
{

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

Mutator::~Mutator()
{

  for (auto iter : all_query_pstr_set) {
    delete iter;
  }

  for (auto p = data_affi_set.begin(); p != data_affi_set.end(); ++p) {
    for (auto pi = p->second.begin(); pi != p->second.end(); ++pi) {
      (*pi)->deep_drop();
    }
  }
}

string Mutator::extract_struct(IR* root)
{

  // Change the ir to a uniform format.
  // Not thorough. Will not remove any ir nodes.
  // Could not handle casting expressions etc.
  string res = "";
  _extract_struct(root);
  res = root->to_string();
  trim_string(res);
  return res;
}

void Mutator::_extract_struct(IR* root)
{

  // Helper function for extract_struct.

  if (root->left_) {
    extract_struct(root->left_);
  }
  if (root->right_) {
    extract_struct(root->right_);
  }

  if (root->get_data_type() == DataTypeName) {
    if (!is_str_empty(root->to_string())) {
      root->set_str_val("INT");
    } else {
      root->set_str_val("");
    }
    return;
  }

  auto type = root->type_;
  if (root->get_data_type() == DataNone) {
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
    root->str_val_ = "0";
    return;
  } else if (root->get_ir_type() == TypeStringLiteral) {
    root->str_val_ = "0";
    return;
    /* Does not use the TypeDBool in the */
    //  } else if (root->get_ir_type() == TypeDBool) {
    //    root->str_val_ = "0";
    //    return;
  }

  if (root->left_ || root->right_ || root->data_type_ == DataFunctionName)
    return;

  if (root->data_type_ != DataUnknownType && root->data_type_ != DataFunctionName) {
    root->str_val_ = "x";
    return;
  }

  if (string_types_.find(type) != string_types_.end()) {
    root->str_val_ = "0";
  } else if (int_types_.find(type) != int_types_.end()) {
    root->int_val_ = 0;
  } else if (float_types_.find(type) != float_types_.end()) {
    root->float_val_ = 0.0;
  }
}

string Mutator::extract_struct_deep(IR* root)
{

  // Change the ir to a uniform format.
  // Try to be thorough. WILL remove some ir nodes.
  // Will need to re-gather the irs or give up
  // the usage on the root
  // if the caller plan to further evaluate on the
  // ir tree, because the ir tree has been changed after
  // this function call.

  string res = "";

  vector<IR*> ir_to_deep_drop;
  //  this->remove_type_annotation(root, ir_to_deep_drop);
  for (auto cur_ir : ir_to_deep_drop) {
    cur_ir->deep_drop();
  }

  _extract_struct_deep(root);
  res = root->to_string();
  trim_string(res);
  return res;
}

void Mutator::_extract_struct_deep(IR* root)
{

  // Helper function for extract_struct_deep.

  if (root->get_ir_type() == TypeSetStmt) {
    // Remove SET VAR statement.
    IR* parent = root->get_parent();
    if (parent != NULL && parent->get_ir_type() == TypeStmt) {
      parent->detach_node(root);
      root->deep_drop();
      return;
    }
    // Do not continue anyway.
    return;
  }

  //  if (root->get_ir_type() == TypeArray) {
  //    // Reset the array type to a pure literal.
  //    root->set_str_val("x");
  //    root->op_->prefix_ = "";
  //    root->op_->middle_ = "";
  //    root->op_->suffix_ = "";
  //
  //    if (root->get_left()) {
  //      root->get_left()->deep_drop();
  //      root->update_left(NULL);
  //    }
  //    if (root->get_right()) {
  //      root->get_right()->deep_drop();
  //      root->update_right(NULL);
  //    }
  //
  //    // Do not continue;
  //    return;
  //  }

  if (root->left_) {
    _extract_struct_deep(root->left_);
  }
  if (root->right_) {
    _extract_struct_deep(root->right_);
  }

  if (root->get_data_type() == DataTypeName) {
    if (!is_str_empty(root->to_string())) {
      root->set_str_val("INT");
    } else {
      root->set_str_val("");
    }
    return;
  }

  if (root->get_ir_type() == TypeIdentifier) {
    root->set_str_val("x");
    return;
  }

  auto type = root->type_;
  if (root->get_data_type() == DataNone) {
    return;
  }
  //  if (root->get_data_flag() == ContextUnknown) {
  //    return;
  //  }

  if (root->get_ir_type() == TypeIntegerLiteral) {
    root->int_val_ = 0;
    root->str_val_ = "x";
    return;
  } else if (root->get_ir_type() == TypeFloatLiteral) {
    root->float_val_ = 0.0;
    root->str_val_ = "x";
    return;
  } else if (root->get_ir_type() == TypeStringLiteral) {
    root->str_val_ = "x";
    return;
    //  } else if (root->get_ir_type() == TypeDBool) {
    //    root->str_val_ = "x";
    //    return;
  }

  if (root->left_ || root->right_ || root->data_type_ == DataFunctionName)
    return;

  if (root->data_type_ != DataUnknownType && root->data_type_ != DataFunctionName) {
    root->str_val_ = "x";
    return;
  }

  if (string_types_.find(type) != string_types_.end()) {
    root->str_val_ = "x";
  } else if (int_types_.find(type) != int_types_.end()) {
    root->int_val_ = 0;
  } else if (float_types_.find(type) != float_types_.end()) {
    root->float_val_ = 0.0;
  }
}

string Mutator::parse_data(string& input)
{
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

void Mutator::pre_validate()
{
  // Reset components that is local to the one query sequence.
  reset_id_counter();
  reset_data_library();
  return;
}

bool Mutator::validate(IR*& cur_stmt, bool is_debug_info)
{

  bool res = true;
  if (cur_stmt->type_ == TypeRoot) {
    vector<IR*> cur_stmt_vec = p_oracle->ir_wrapper.get_stmt_ir_vec(cur_stmt);
    for (IR* cur_stmt_tmp : cur_stmt_vec) {
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

string Mutator::validate(string query, bool is_debug_info)
{
  reset_data_library();

  vector<IR*> ir_set = parse_query_str_get_ir_set(query);
  if (ir_set.size() == 0)
    return "";

  IR* root = ir_set.back();
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

unsigned int Mutator::calc_node(IR* root)
{
  unsigned int res = 0;
  if (root->left_)
    res += calc_node(root->left_);
  if (root->right_)
    res += calc_node(root->right_);

  return res + 1;
}

bool Mutator::instan_one_stmt(IR* cur_stmt, bool is_debug_info)
{
  bool res = true;

  //  /* Reset library that is local to one query set. */
  //  reset_data_library_single_stmt();

  /* m_substmt_save, used for reconstruct the tree. */
  map<IR*, pair<bool, IR*>> m_substmt_save;
  auto substmts = split_to_substmt(cur_stmt, m_substmt_save, split_substmt_types_);

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

  vector<vector<IR*>> cur_stmt_ir_to_fix;

  for (auto& substmt : substmts) {
    if (substmt->parent_) {
      substmt->parent_ = NULL;
    }

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

    vector<IR*> cur_substmt_ir_to_fix;
    this->instan_preprocessing(substmt, cur_substmt_ir_to_fix);

    cur_stmt_ir_to_fix.push_back(cur_substmt_ir_to_fix);
  }

  res = connect_back(m_substmt_save) && res;

  res = instan_dependency(cur_stmt, cur_stmt_ir_to_fix, is_debug_info);

  return res;
}

vector<IR*> Mutator::pre_fix_transform(IR* root,
    vector<STMT_TYPE>& stmt_type_vec)
{

  p_oracle->init_ir_wrapper(root);
  vector<IR*> all_trans_vec;
  vector<IR*> all_statements_vec = p_oracle->ir_wrapper.get_stmt_ir_vec();

  // cerr << "In func: Mutator::pre_fix_transform(IR * root, vector<STMT_TYPE>&
  // stmt_type_vec), we have all_statements_vec size(): "
  //     << all_statements_vec.size() << "\n\n\n";

  for (IR* cur_stmt : all_statements_vec) {
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
    IR* trans_IR = nullptr;
    if (is_oracle_normal) {
      trans_IR = p_oracle->pre_fix_transform_normal_stmt(cur_stmt); // Deep_copied
    } else if (is_oracle_select) {
      trans_IR = p_oracle->pre_fix_transform_select_stmt(cur_stmt); // Deep_copied
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

vector<vector<vector<IR*>>> Mutator::post_fix_transform(
    vector<IR*>& all_pre_trans_vec, vector<STMT_TYPE>& stmt_type_vec,
    vector<vector<STMT_TYPE>>& post_fix_stmt_type_vec_vec)
{
  int total_run_count = p_oracle->get_mul_run_num();
  vector<vector<vector<IR*>>> all_trans_vec_all_run;
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

vector<vector<IR*>> Mutator::post_fix_transform(
    vector<IR*>& all_pre_trans_vec, vector<STMT_TYPE>& stmt_type_vec,
    vector<STMT_TYPE>& post_fix_stmt_type_vec, int run_count)
{
  // Apply post_fix_transform functions.
  vector<vector<IR*>> all_post_trans_vec;
  vector<int> v_stmt_to_rov;
  for (int i = 0; i < all_pre_trans_vec.size();
       i++) { // Loop through across statements.
    IR* cur_pre_trans_ir = all_pre_trans_vec[i];
    vector<IR*> post_trans_stmt_vec;
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
    if (find(v_stmt_to_rov.begin(), v_stmt_to_rov.end(), i) != v_stmt_to_rov.end()) {
      continue;
    }
    post_fix_stmt_type_vec.push_back(stmt_type_vec[i]);
  }

  return all_post_trans_vec;
}

/*
** From the outer most parent-statements to the inner most sub-statements.
*/
vector<IR*> Mutator::split_to_substmt(IR* cur_stmt,
    map<IR*, pair<bool, IR*>>& m_save,
    set<IRTYPE>& split_set)
{
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

  list<IR*> res_list;
  vector<IR*> res;
  deque<IR*> bfs = { cur_stmt };

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
    if (node->get_ir_type() == TypeCommonTableExpression) {
      // If the sub-statement is inside the WITH CTE clause,
      // fix them first before the main statement.
      if (node->get_right() != NULL && node->get_right()->get_ir_type() == TypeExpr) {
        res_list.push_front(node->get_right());
      }
      pair<bool, IR*> cur_m_save = make_pair<bool, IR*>(false, node->get_right());
      m_save[node] = cur_m_save;
    } else if (node->get_ir_type() == TypeCreateViewStmt || node->get_ir_type() == TypeCreateTableAsStmt) {
      // If the statement is in the Create Table AS
      // or Create view as, fix the subquery first.
      vector<IR*> v_subquery_expr = this->p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(node, TypeSelectStmt);
      for (IR* subquery_expr: v_subquery_expr) {
        IR* subquery_parent_node = subquery_expr->get_parent();
        if (subquery_parent_node != nullptr) {
          bool is_left_sub_node = true;
          if (subquery_parent_node->get_left() != subquery_expr) {
            is_left_sub_node = false;
          }
          res_list.push_front(subquery_expr);
          pair<bool, IR*> cur_m_save = make_pair(is_left_sub_node, subquery_expr);
          m_save[subquery_parent_node] = cur_m_save;
        }
      } // else: parent is nullptr. Error.
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

  //  for (auto cur_sub : res) {
  //      cerr << "\nGetting subquery: " << cur_sub->to_string() << "\n\n";
  //  }

  return res;
}

bool Mutator::connect_back(map<IR*, pair<bool, IR*>>& m_save)
{
  for (auto& iter : m_save) {
    if (iter.second.first) { // is_left?
      iter.first->update_left(iter.second.second);
    } else {
      iter.first->update_right(iter.second.second);
    }
  }
  return true;
}

pair<string, string>
Mutator::ir_to_string(IR* root, vector<vector<IR*>> all_post_trans_vec,
    const vector<STMT_TYPE>& stmt_type_vec)
{
  // Final step, IR_to_string function.
  string output_str_mark, output_str_no_mark;
  for (int i = 0; i < all_post_trans_vec.size();
       i++) { // Loop between different statements.
    vector<IR*> post_trans_vec = all_post_trans_vec[i];
    int count = 0;
    bool is_oracle_select = false;
    if (stmt_type_vec[i] == ORACLE_SELECT) {
      is_oracle_select = true;
    }
    for (IR* cur_trans_stmt :
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
  pair<string, string> output_str_pair = make_pair(output_str_mark, output_str_no_mark);
  return output_str_pair;
}

// find tree node whose identifier type can be handled
//
// NOTE: identifier type is different from IR type
//
static void collect_ir(IR* root, set<DATATYPE>& type_to_fix,
    vector<IR*>& ir_to_fix)
{
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
void Mutator::instan_preprocessing(IR* stmt_root,
    vector<IR*>& ordered_all_subquery_ir)
{
  set<DATATYPE> type_to_fix = {
    DataColumnName, DataTableName, DataIndexName,
    DataTableAliasName, DataColumnAliasName, DataSequenceName,
    DataViewName, DataConstraintName, DataSequenceName,
    DataTypeName, DataLiteral, DataDatabaseName,
    DataSchemaName, DataViewColumnName, DataFamilyName,
    DataStorageParams, DataFunctionExpr
  };
  vector<IR*> ir_to_fix;
  collect_ir(stmt_root, type_to_fix, ordered_all_subquery_ir);
}

string Mutator::find_cloest_table_name(IR* ir_to_fix, bool is_debug_info)
{
  string closest_table_name = "";
  IR* closest_table_ir = NULL;
  vector<DATATYPE> search_type = { DataTableName, DataTableAliasName };
  vector<IRTYPE> cap_type = { TypeSelectStmt };
  closest_table_ir = p_oracle->ir_wrapper
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
    closest_table_name = v_table_names_single[get_rand_int(v_table_names_single.size())];
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

    // } else if (v_table_names.size() != 0) {
    //
    //    /* This should be an error.
    //    ** 80% chances, keep original.
    //    ** 20%, use predefined table name.
    //    */
    //    if (get_rand_int(5) < 4) {
    //      ir_to_fix->set_is_instantiated(true);
    //      return "";
    //    }
    //
    //    closest_table_name =
    //    v_table_names[get_rand_int(v_table_names.size())]; if (is_debug_info)
    //    {
    //      cerr << "Dependency Error: In kUse of kDataColumnName, cannot find "
    //              "v_table_names_single. Thus find from v_table_name "
    //              "instead. Use table name: "
    //           << closest_table_name << " for column name origin. \n\n\n"
    //           << endl;
    //    }
  } else {
    if (is_debug_info) {
      cerr << "Dependency Error:  In kUse of kDataColumnName, every table names"
              "are empty. Return empty. \n\n\n"
           << endl;
    }
  }

  return closest_table_name;
}

DATAAFFINITYTYPE Mutator::get_nearby_data_affinity(IR* ir_to_fix,
    bool is_debug_info)
{

  // First, search if we can find a nearby literal that already has the
  // affinity fixed.

  DATAAFFINITYTYPE ret_data_affi;

  vector<IRTYPE> v_matched_literal_types = {
    TypeIntegerLiteral, TypeStringLiteral, TypeFloatLiteral, TypeIdentifier
  };
  vector<IRTYPE> v_capped_ir_types = { TypeSubqueryExpr, TypeSelectStmt };
  IR* near_literal_node = p_oracle->ir_wrapper
                              .find_closest_nearby_IR_with_type<vector<IRTYPE>, vector<IRTYPE>>(
                                  ir_to_fix, v_matched_literal_types, v_capped_ir_types);

  if (near_literal_node != NULL && near_literal_node->get_data_affinity() != AFFIUNKNOWN && near_literal_node->get_data_affinity() != AFFIANY && near_literal_node->get_is_instantiated() == true) {
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

    IR* nearby_column_ir = p_oracle->ir_wrapper.find_closest_nearby_IR_with_type(ir_to_fix,
        DataColumnName);
    if (nearby_column_ir != NULL) {
      string nearby_column_str = nearby_column_ir->get_str_val();
      string actual_column_str = nearby_column_str;
      if (m_column2datatype.count(nearby_column_str) || m_alias2column_single.count(nearby_column_str)) {
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

void Mutator::instan_database_schema_name(IR* ir_to_fix, bool is_debug_info)
{
  if ((ir_to_fix->data_type_ == DataDatabaseName)) {
    ir_to_fix->set_str_val("test_rsg1");
  }

  if (ir_to_fix->data_type_ == DataSchemaName) {
    ir_to_fix->set_str_val("test_rsg1");
  }
  return;
}

void Mutator::instan_table_name(IR* ir_to_fix, bool& is_replace_table,
    bool is_debug_info)
{

  if (p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeSetStmt)) {
    return;
  }

  if ((ir_to_fix->data_type_ == DataTableName) && (ir_to_fix->data_flag_ == ContextDefine || ir_to_fix->data_flag_ == ContextReplaceDefine)) {
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
      for (string& all_defined_name : v_table_names_single) {
        cerr << all_defined_name << " ";
      }
      cerr << "Dependency: All previously saved table names: ";
      for (string& all_used_name : v_table_names) {
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

  else if ((ir_to_fix->data_type_ == DataTableName) && (ir_to_fix->data_flag_ == ContextUndefine || ir_to_fix->data_flag_ == ContextReplaceUndefine)) {
    if (v_table_names.size() > 0) {
      // Choose random table name that defined before to drop.
      string removed_table_name = v_table_names[get_rand_int(v_table_names.size())];
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

  else if (ir_to_fix->data_type_ == DataTableName && ir_to_fix->data_flag_ == ContextUse) {

    /* INFO:: CockroachDB does not have the syntax of PARTITION OF table.
     * Therefore, we don't need to consider the PARTITION OF
     * partitioned_table grammar.
     * */

    if (v_table_names.size() == 0 && v_table_names_single.size() == 0 && v_create_table_names_single.size() == 0) {
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
      used_name = v_table_names_single[get_rand_int(v_table_names_single.size())];

      int trial = 10;
      while (p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeInsertStmt) && trial-- != 0 && find(v_view_name.begin(), v_view_name.end(), used_name) != v_view_name.end()) {
        if (is_debug_info) {
          cerr << "\n\n\nRetry table name fixing in the INSERT statement. "
                  "\n\n\n";
        }
        used_name = v_table_names_single[get_rand_int(v_table_names_single.size())];
      }

    } else if (v_create_table_names_single.size() != 0) {
      // If cannot find any table names defined or used before,
      // consider the table name that just defined in this statement.
      used_name = v_create_table_names_single[get_rand_int(
          v_create_table_names_single.size())];
    } else if (v_table_names.size() != 0) {
      used_name = v_table_names[get_rand_int(v_table_names.size())];

      int trial = 10;
      while (p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeInsertStmt) && trial-- != 0 && find(v_view_name.begin(), v_view_name.end(), used_name) != v_view_name.end()) {
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
      for (string& all_used_name : v_table_names) {
        cerr << "Dependency: All saved table used names: " << all_used_name
             << "\n\n\n";
      }
      for (string& all_used_name : v_create_table_names_single) {
        cerr << "Dependency: All saved table used names: " << all_used_name
             << "\n\n\n";
      }
    }

  }

  else if (ir_to_fix->data_type_ == DataTableName && ir_to_fix->data_flag_ == ContextUseFollow) {

    if (v_table_alias_names_single.size() == 0 && v_table_names.size() == 0 && v_table_names_single.size() == 0 && v_create_table_names_single.size() == 0) {
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
      used_name = v_table_names_single[get_rand_int(v_table_names_single.size())];
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

    // Check whether the chosen alias name is inside the enforced table alias
    // mapping.
    if (m_enforced_table2alias_single.count(used_name) != 0 && m_enforced_table2alias_single[used_name].size() != 0) {
      if (is_debug_info) {
        cerr << "\n\n\nDependency: Inside the table name use follow "
                "instantiation, forced map the table name "
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
      for (string& all_used_name : v_table_names) {
        cerr << "Dependency: All saved table used names: " << all_used_name
             << "\n\n\n";
      }
      for (string& all_used_name : v_create_table_names_single) {
        cerr << "Dependency: All saved table used names: " << all_used_name
             << "\n\n\n";
      }
    }
  }

  return;
}

void Mutator::instan_table_alias_name(IR* ir_to_fix, IR* cur_stmt_root,
    bool is_alias_optional,
    bool is_debug_info)
{

  /* There is no need to consider the Context in this loop.
   * Because TableAliasName almost always occur on ContextDefine.
   * The Alias name will be saved into the
   */

  //  if (p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeIndexFlags)) {
  //    return;
  //  }

  if (ir_to_fix->data_type_ == DataTableAliasName) {

    ir_to_fix->set_is_instantiated(true);

    string closest_table_name = "";

    IR* closest_table_ir = p_oracle->ir_wrapper.find_closest_nearby_IR_with_type<DATATYPE>(
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
      closest_table_name = v_table_names_single[get_rand_int(v_table_names_single.size())];
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

    if (closest_table_name == "" || closest_table_name == "x" || closest_table_name == "y") {
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
    m_alias_table2column_single[alias_name] = m_table2columns[closest_table_name];
    v_table_alias_names_single.push_back(alias_name);
    if (p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeTableRefsClause)) {
      if (is_debug_info) {
        cerr << "\n\n\n The table alias: " << alias_name
             << " is defined "
                "inside the FROM clause, so we can safely move the alias into "
                "the "
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

void Mutator::instan_view_name(IR* ir_to_fix, bool is_debug_info)
{

  if (p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeSetStmt)) {
    return;
  }

  /* Context Define. */
  if (ir_to_fix->data_type_ == DataViewName && ir_to_fix->data_flag_ == ContextDefine) {

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
  if (ir_to_fix->data_type_ == DataViewName && ir_to_fix->data_flag_ == ContextUndefine) {
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
  else if (ir_to_fix->data_type_ == DataViewName && ir_to_fix->data_flag_ == ContextUse) {
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

void Mutator::instan_partition_name(IR* ir_to_fix, bool is_debug_info)
{

  /* Context Define, Context Use and ContextUndefine of partition name. */
  if (ir_to_fix->data_type_ == DataPartitionName && ir_to_fix->data_flag_ == ContextDefine) {
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

  if (ir_to_fix->data_type_ == DataPartitionName && ir_to_fix->data_flag_ == ContextUse) {

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

    const vector<string>& all_partitions = m_table2partition[cur_table_name];
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

  else if (ir_to_fix->data_type_ == DataPartitionName && ir_to_fix->data_flag_ == ContextUndefine) {
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

    vector<string>& all_partitions = m_table2partition[cur_table_name];
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

void Mutator::instan_index_name(IR* ir_to_fix, bool is_debug_info)
{

  if (ir_to_fix->get_data_type() == DataIndexName) {
    if (is_debug_info) {
      cerr << "\n\n\nDEBUG: Inside the instan_index_name function \n\n\n";
    }
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
        vector<string>& v_index_name = m_table2index[tmp_table_name];
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
          vector<string>& v_index_name = it->second;
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
        vector<string>& v_index_name = m_table2index[tmp_table_name];
        if (!v_index_name.size()) {
          tmp_index_name = "y";
        } else {
          tmp_index_name = vector_rand_ele(v_index_name);
        }
      } else {
        for (auto it = m_table2index.begin(); it != m_table2index.end(); it++) {
          vector<string>& v_index_name = it->second;
          if (!v_index_name.size())
            continue;
          tmp_index_name = vector_rand_ele(v_index_name);
        }
      }
      if (tmp_index_name != "y") {
        ir_to_fix->set_str_val(tmp_index_name);
        ir_to_fix->set_is_instantiated(true);
      } else {
        //        if (ir_to_fix->get_parent() != nullptr &&
        //            ir_to_fix->get_parent()->get_ir_type() == TypeIndexFlags) {
        //          ir_to_fix->get_parent()->op_->prefix_ = "";
        //          ir_to_fix->set_str_val("");
        //          ir_to_fix->set_is_instantiated(true);
        //        }
      }
    }
  }

  return;
}

void Mutator::instan_column_name(IR* ir_to_fix, IR* cur_stmt_root,
    bool& is_replace_column,
    vector<IR*>& ir_to_deep_drop,
    bool is_debug_info)
{

  if (p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeSetStmt)) {
    return;
  }

  if (ir_to_fix->data_type_ == DataColumnName && (ir_to_fix->data_flag_ == ContextDefine || ir_to_fix->data_flag_ == ContextReplaceDefine)) {

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
    if (closest_table_name == "" || closest_table_name == "x" || closest_table_name == "y") {
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
    vector<string>& cur_col_names = m_table2columns[closest_table_name];
    if (find(cur_col_names.begin(), cur_col_names.end(), new_name) == cur_col_names.end()) {
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

  else if (ir_to_fix->data_type_ == DataColumnName && ir_to_fix->data_flag_ == ContextUndefine) {
    /* Find the table_name in the query first. */
    string closest_table_name = "";
    IR* closest_table_ir = NULL;
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
    if (closest_table_name == "" || closest_table_name == "x" || closest_table_name == "y") {
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

    vector<string>& column_vec = m_table2columns[closest_table_name];
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
  else if (ir_to_fix->data_type_ == DataColumnName && ir_to_fix->data_flag_ == ContextUse && p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeFieldList) && !p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeUpdateStmt)) {

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

    if (ir_to_fix->get_data_affinity() != AFFIUNKNOWN) {
      // This is a special context that the Data Affinity type of the
      // column name node has been pre-defined.
      // This is used in query dynamic fixing, where the replaced query nodes
      // are saved in a whole, and the column node data affinity are preserved.

      if (m_datatype2column.count(ir_to_fix->get_data_affinity()) == 0) {
        // If it cannot find the matching column names, instantiate this node
        // as an literal.
        ir_to_fix->type_ = TypeStringLiteral;
        ir_to_fix->data_type_ = DataUnknownType;
        ir_to_fix->mutate_literal();
        return;
      }
      string cur_chosen_col = vector_rand_ele(m_datatype2column[ir_to_fix->get_data_affinity()]);

      bool is_col_imported = false;
      for (string cur_used_table : v_table_names_single) {
        vector<string> v_imported_col = m_table2columns[cur_used_table];
        if (find_vector(v_imported_col, cur_chosen_col)) {
          is_col_imported = true;
          break;
        }
      }

      if (is_col_imported) {
        ir_to_fix->set_is_instantiated(true);
        ir_to_fix->set_str_val(cur_chosen_col);
      } else {
        // If it cannot find the matching column names, instantiate this node
        // as an literal.
        ir_to_fix->type_ = TypeStringLiteral;
        ir_to_fix->data_type_ = DataUnknownType;
        ir_to_fix->mutate_literal();
      }

      return;
    }

    IR* name_list = p_oracle->ir_wrapper.get_parent_node_with_type(ir_to_fix, TypeFieldList);

    string closest_table_name = this->find_cloest_table_name(name_list, is_debug_info);

    if (closest_table_name == "" || closest_table_name == "x" || closest_table_name == "y") {
      if (is_debug_info) {
        cerr << "Error: Cannot find the closest_table_name from "
                "the query. Error cloest_table_name is: "
             << closest_table_name
             << ". In kDataColumnName, kUse of TypeNameList. \n\n\n";
        //        cerr << "Choose to use the literal in this scenario now.
        //        \n\n\n";
        //
        //        ir_to_fix->set_is_instantiated(false);
        //        ir_to_fix->set_ir_type(TypeStringLiteral);
        //        ir_to_fix->set_data_type(DataLiteral);
        //        ir_to_fix->set_data_flag(ContextUse);
        //
        //        this->instan_literal(ir_to_fix, cur_stmt_root,
        //        ir_to_deep_drop, is_debug_info);
      }
      return;
    }

    vector<string> v_used_column_str;

    vector<string> v_column_names_from_table;
    if (m_alias_table2column_single.count(closest_table_name) > 0) {
      v_column_names_from_table = m_alias_table2column_single[closest_table_name];
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

    vector<IR*> v_new_column_list_node;
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
                   new_rand_column)
          != v_used_column_str.end());
      if (is_debug_info) {
        cerr << "\n\n\n When reconstructing the column names inside the "
                "TypeNameList, "
             << ", getting random column name: " << new_rand_column << "\n\n\n";
      }
      v_used_column_str.push_back(new_rand_column);

      IR* new_column_node = new IR(TypeIdentifier, string(new_rand_column),
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

    IR* new_name_list_expr = NULL;

    for (int idx = 0; idx < v_new_column_list_node.size(); idx++) {
      if (idx == 1) {
        continue;
      } else if (idx == 0) {
        IR* LNode = v_new_column_list_node[0];
        IR* RNode = nullptr;
        string infix = "";
        if (v_new_column_list_node.size() >= 2) {
          RNode = v_new_column_list_node[1];
          infix = ", ";
        }
        new_name_list_expr = new IR(TypeUnknown, OP3("", infix, ""), LNode, RNode);
      } else {
        // idx > 2
        IR* LNode = new_name_list_expr;
        IR* RNode = v_new_column_list_node[idx];

        new_name_list_expr = new IR(TypeUnknown, OP3("", ", ", ""), LNode, RNode);
      }
    }

    if (is_debug_info) {
      cerr << "\n\n\nDEPENDENCY: From the original name list: "
           << name_list->to_string();
    }

    IR* name_list_left_child = name_list->get_left();
    IR* name_list_right_child = name_list->get_right();
    if (name_list_left_child != nullptr) {
      ir_to_deep_drop.push_back(name_list_left_child);
    }
    if (name_list_right_child != nullptr) {
      ir_to_deep_drop.push_back(name_list_right_child);
    }
    p_oracle->ir_wrapper.iter_cur_node_with_handler(
        name_list, [](IR* cur_node) -> void {
          cur_node->set_is_instantiated(true);
          cur_node->set_data_flag(ContextNoModi);
        });
    name_list->update_left(nullptr);
    name_list->update_right(nullptr);

    new_name_list_expr->set_ir_type(TypeFieldList);
    name_list->update_left(new_name_list_expr);
    name_list->op_->middle_ = "";
    name_list->set_is_instantiated(true);

    if (is_debug_info) {
      cerr << "   replaced to new name list: "
           << name_list->get_parent()->to_string() << "\n\n\n";
    }

    return;
  }

  else if (ir_to_fix->data_type_ == DataColumnName && ir_to_fix->data_flag_ == ContextUse) {
    if (is_debug_info) {
      cerr << "Dependency: ori column name: " << ir_to_fix->str_val_
           << "\n\n\n";
      cerr << "In the kDataColumnName with kUse, found "
              "v_table_alias_names_single.size: "
           << v_table_alias_names_single.size() << "\n\n\n";
    }

    ir_to_fix->set_is_instantiated(true);

    if (ir_to_fix->get_data_affinity() != AFFIUNKNOWN) {
      // This is a special context that the Data Affinity type of the
      // column name node has been pre-defined.
      // This is used in query dynamic fixing, where the replaced query nodes
      // are saved in a whole, and the column node data affinity are preserved.

      if (is_debug_info) {
        cerr << "\n\n\nDEBUG: Special handling of the column name, in dynamic "
                "fixing"
                " context. \n\n\n";
      }

      if (m_datatype2column.count(ir_to_fix->get_data_affinity()) == 0) {
        // If it cannot find the matching column names, instantiate this node
        // as an literal.
        ir_to_fix->type_ = TypeStringLiteral;
        ir_to_fix->data_type_ = DataLiteral;
        ir_to_fix->mutate_literal(ir_to_fix->get_data_affinity());
        return;
      }
      string cur_chosen_col = vector_rand_ele(m_datatype2column[ir_to_fix->get_data_affinity()]);

      bool is_col_imported = false;
      for (string cur_used_table : v_table_names_single) {
        vector<string> v_imported_col = m_table2columns[cur_used_table];
        if (find_vector(v_imported_col, cur_chosen_col)) {
          is_col_imported = true;
          break;
        }
      }

      if (is_col_imported) {
        ir_to_fix->set_is_instantiated(true);
        ir_to_fix->set_str_val(cur_chosen_col);
      } else {
        // If it cannot find the matching column names, instantiate this node
        // as an literal.
        ir_to_fix->type_ = TypeStringLiteral;
        ir_to_fix->data_type_ = DataUnknownType;
        ir_to_fix->mutate_literal();
      }

      return;
    }

    // Actual random mutation of the ColumnName. ContextUse.

    bool is_found = false;
    string closest_table_name = "";
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

      // Last chance, try to directly search for table name in the tree nodes.
      closest_table_name = this->find_cloest_table_name(ir_to_fix, is_debug_info);

      if (closest_table_name == "" || closest_table_name == "x" || closest_table_name == "y") {
        if (is_debug_info) {
          cerr << "Dependency : Cannot find the closest_table_name from "
                  "the query. closest_table_name is: "
               << closest_table_name << ". In kDataColumnName, kUse. \n\n\n";

          cerr << "Choose to use the literal in this scenario now. \n\n\n";
        }

        ir_to_fix->set_is_instantiated(false);
        ir_to_fix->set_ir_type(TypeStringLiteral);
        ir_to_fix->set_data_type(DataLiteral);
        ir_to_fix->set_data_flag(ContextUse);

        this->instan_literal(ir_to_fix, cur_stmt_root, ir_to_deep_drop,
            is_debug_info);

        return;
      }
    }

    vector<string> cur_mapped_column_name_vec;
    if (m_alias_table2column_single.count(closest_table_name) > 0) {
      cur_mapped_column_name_vec = m_alias_table2column_single[closest_table_name];
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

void Mutator::instan_column_alias_name(IR* ir_to_fix, IR* cur_stmt_root,
    vector<IR*>& ir_to_deep_drop,
    bool is_debug_info)
{

  //  if (p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeIndexFlags)) {
  //    return;
  //  }

  if (ir_to_fix->data_type_ == DataColumnAliasName) {

    if (is_debug_info) {
      cerr << "\n\n\nDebug::Trying to fix the DataColumnAliasName. \n\n\n";
    }

    ir_to_fix->set_is_instantiated(true);

    // TODO: Recover the alias name instantiation.
    ir_to_fix->set_str_val("a0");

    //    string closest_table_alias_name = "";
    //
    //    /* Three situations:
    //     * 1. TypeSelectExprs: `SELECT CustomerID AS ID, CustomerName AS
    //     * Customer FROM Customers;`
    //     * 2. TypeAliasClause: `SELECT c.x FROM (SELECT COUNT(*) FROM users) AS
    //     * c(x);`
    //     * 3. TypeAliasClause: WITH r(c) AS (SELECT * FROM v0 WHERE v1 = 100)
    //     * SELECT * FROM r WHERE c = 100;
    //     *
    //     * The 2 and 3 cases are similar.
    //     * */
    //
    //    bool is_alias_clause = false;
    ////    if (p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeAliasClause)) {
    //    is_alias_clause = true;
    ////    }
    //
    //    if (is_alias_clause) {
    //      /* Fix the TypeAliasClause scenario first.
    //       * This scenario must be handled before the ContextUse of
    //       * DataColumnName.
    //       * In this case, the TypeTableAlias is provided, we need to
    //       * connect the TypeTableAlias to the TypeColumnAlias.
    //       * Challenge: We need to make sure the number of
    //       * alise column matched the SELECT clause element in the subquery.
    //       * Luckily, we can ensure that when running in this scenario,
    //       * the subquery has already been instantiated, so that all the column
    //       * mappings are correct.
    //       */
    //
    //      // First, check the nearby select subquery.
    //      IR *select_subquery =
    //          p_oracle->ir_wrapper.find_closest_nearby_IR_with_type(ir_to_fix,
    //                                                                TypeSubqueryExpr);
    //      if (select_subquery != NULL && select_subquery != cur_stmt_root) {
    //        if (is_debug_info) {
    //          cerr << "\n\n\nDependency: when fixing the select subquery, "
    //                  "found select subquery: "
    //               << select_subquery->to_string() << "\n\n\n";
    //        }
    //      } else {
    //        if (is_debug_info) {
    //          cerr << "\n\n\nDependency: Cannot find the select subquery from the "
    //                  "current stmt. "
    //                  "Remove the current column alias clause. \n\n\n";
    //        }
    //
    //        IR *alias_clause = p_oracle->ir_wrapper.get_parent_node_with_type(
    //            ir_to_fix, TypeAliasClause);
    //        if (alias_clause == NULL) {
    //          cerr << "\n\n\nFATAL ERROR: Cannot find the TypeAliasClause in the "
    //                  "TypeAliasClause instantiation. \n\n\n";
    //          return;
    //        }
    //
    //        // Remove the column alias clause, AS `ta0(x, x, x)`, to `AS ta0`.
    //        IR *column_alias_clause = alias_clause->get_right();
    //        if (column_alias_clause != NULL) {
    //          alias_clause->update_right(NULL);
    //          p_oracle->ir_wrapper.iter_cur_node_with_handler(
    //              column_alias_clause, [](IR *cur_node) -> void {
    //                cur_node->set_is_instantiated(true);
    //                cur_node->set_data_flag(ContextNoModi);
    //              });
    //          ir_to_deep_drop.push_back(column_alias_clause);
    //          alias_clause->op_->middle_ = "";
    //          alias_clause->op_->suffix_ = "";
    //        }
    //
    //        return;
    //      }
    //
    //      // Search whether there are columns defined in the `TypeSelectExprs`.
    //      vector<IR *> all_column_in_subselect =
    //          p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(select_subquery,
    //                                                             TypeSelectExpr);
    //      vector<IR *> all_table_in_subselect =
    //          p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(select_subquery,
    //                                                             DataTableName);
    //      vector<IR *> all_stars_in_subselect =
    //          p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(
    //              select_subquery, TypeUnqualifiedStar);
    //
    //      // Try to handle the columns defined in the subquery first.
    //      // Only look at the columns defined in the SELECT clause:
    //      // e.g. `SELECT v1, v2 FROM v0`
    //
    //      vector<IR *> ref_column_in_subselect;
    //      vector<string> new_column_alias_names;
    //      string ret_str = "";
    //      for (auto &cur_column_in_subselect : all_column_in_subselect) {
    //        if (p_oracle->ir_wrapper.is_ir_in(cur_column_in_subselect,
    //                                          TypeSelectExprs)) {
    //          if (is_debug_info) {
    //            cerr << "\n\n\nFound column name in TypeSelectExprs: "
    //                 << cur_column_in_subselect->to_string() << "\n\n\n";
    //          }
    //          ref_column_in_subselect.push_back(
    //              cur_column_in_subselect->get_left());
    //        }
    //      }
    //
    //      int ref_col_idx = 0;
    //      if (ref_column_in_subselect.size() > 0) {
    //        for (auto &cur_column_in_sub : ref_column_in_subselect) {
    //          string cur_col_in_sub_str = cur_column_in_sub->get_str_val();
    //          string new_column_alias_name = gen_column_alias_name();
    //          m_alias2column_single[new_column_alias_name] = cur_col_in_sub_str;
    //          if (m_column2datatype.count(cur_col_in_sub_str) == 0 &&
    //              cur_column_in_sub->get_ir_type() != TypeIdentifier) {
    //            m_column2datatype[cur_col_in_sub_str] =
    //                cur_column_in_sub->data_affinity;
    //          }
    //          new_column_alias_names.push_back(new_column_alias_name);
    //          if (ref_col_idx > 0) {
    //            ret_str += ", ";
    //          }
    //          ref_col_idx++;
    //          ret_str += new_column_alias_name;
    //          if (is_debug_info) {
    //            cerr << "\n\n\nMapping alias name: " << new_column_alias_name
    //                 << " to column name " << cur_col_in_sub_str
    //                 << " in TypeSelectExprs. ";
    //          }
    //        }
    //      }
    //      // Inherit the ref_col_idx.
    //      if (all_stars_in_subselect.size() > 0 &&
    //          all_table_in_subselect.size() > 0) {
    //        IR *cur_select_table = all_table_in_subselect.front();
    //        for (string &matched_column :
    //             m_table2columns[cur_select_table->get_str_val()]) {
    //          string new_column_alias_name = gen_column_alias_name();
    //          m_alias2column_single[new_column_alias_name] = matched_column;
    //          new_column_alias_names.push_back(new_column_alias_name);
    //          if (ref_col_idx > 0) {
    //            ret_str += ", ";
    //          }
    //          ref_col_idx++;
    //          ret_str += new_column_alias_name;
    //          if (is_debug_info) {
    //            cerr << "\n\n\nMapping alias name: " << new_column_alias_name
    //                 << " to column name " << matched_column
    //                 << " in TypeSelectExprs. ";
    //          }
    //        }
    //      }
    //
    //      // Next, match the table alias name.
    //      IR *alias_table_ir =
    //          p_oracle->ir_wrapper.find_closest_nearby_IR_with_type<DATATYPE>(
    //              ir_to_fix, DataTableAliasName);
    //      string alias_table_str;
    //      if (alias_table_ir != NULL) {
    //        alias_table_str = alias_table_ir->get_str_val();
    //      } else {
    //        if (is_debug_info) {
    //          cerr << "\n\n\nError: Cannot find table alias name inside the "
    //                  "TypeAliasClause \n\n\n";
    //          ir_to_fix->set_str_val("x");
    //          return;
    //        }
    //      }
    //
    //      for (string &cur_new_column_alias_name : new_column_alias_names) {
    //        m_alias_table2column_single[alias_table_str].push_back(
    //            cur_new_column_alias_name);
    //      }
    //
    //      // Actually replace the current node.
    //      IR *alias_clause_ir = p_oracle->ir_wrapper.get_parent_node_with_type(
    //          ir_to_fix, TypeAliasClause);
    //      if (alias_clause_ir == NULL || alias_clause_ir->get_right() == NULL) {
    //        if (is_debug_info) {
    //          cerr << "\n\n\nLogical Error: Cannot find the TypeAliasClauseIR "
    //                  "from Columnaliaslist. \n\n\n";
    //        }
    //        return;
    //      }
    //
    //      ir_to_deep_drop.push_back(alias_clause_ir->get_right());
    //      p_oracle->ir_wrapper.iter_cur_node_with_handler(
    //          alias_clause_ir->get_right(), [](IR *cur_node) -> void {
    //            cur_node->set_is_instantiated(true);
    //            cur_node->set_data_flag(ContextNoModi);
    //          });
    //      if (ret_str != "") {
    //        IR *new_column_alias_list = new IR(TypeColumnDefList, ret_str);
    //        alias_clause_ir->update_right(new_column_alias_list);
    //      } else {
    //        // ret_str == ""
    //        // If no column alias observed, remove the empty bracket.
    //        alias_clause_ir->update_right(NULL);
    //        alias_clause_ir->op_->middle_ = "";
    //        alias_clause_ir->op_->suffix_ = "";
    //      }
    //
    //      return;
    //
    //    } else {
    //      /* Fix the TypeSelectExprs scenario now.
    //       * No need for extra work for this scenario because it is
    //       * not very interesting.
    //       * 1. TypeSelectExprs: `SELECT CustomerID AS ID, CustomerName AS
    //       * Customer FROM Customers;`
    //       */
    //
    //      IR *near_table_ir =
    //          p_oracle->ir_wrapper.find_closest_nearby_IR_with_type<DATATYPE>(
    //              ir_to_fix, DataTableName);
    //      string near_table_str;
    //      if (near_table_ir != NULL) {
    //        near_table_str = near_table_ir->get_str_val();
    //      } else {
    //        if (is_debug_info) {
    //          cerr << "\n\n\nError: Cannot find table alias name inside the "
    //                  "TypeAliasClause \n\n\n";
    //          ir_to_fix->set_str_val("x");
    //          return;
    //        }
    //      }
    //
    //      string column_alias_name = gen_column_alias_name();
    //      ir_to_fix->set_str_val(column_alias_name);
    //
    //      m_alias_table2column_single[near_table_str].push_back(column_alias_name);
    //      return;
    //    }
  }

  return;
}

void Mutator::instan_sql_type_name(IR* ir_to_fix, bool is_debug_info)
{

  //  if (p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeIndexFlags)) {
  //    return;
  //  }

  IRTYPE type = ir_to_fix->get_ir_type();
  DATATYPE data_type = ir_to_fix->get_data_type();
  DATAFLAG data_flag = ir_to_fix->get_data_flag();

  if (type == TypeIdentifier && data_type == DataTypeName && data_flag == ContextDefine) {
    // Handling of the Column Data Type definition.
    // Use basic types.
    auto tmp_affi_type = get_random_affinity_type();
    string tmp_affi_type_str = get_affinity_type_str_formal(tmp_affi_type);

    ir_to_fix->set_str_val(tmp_affi_type_str);
    if (is_debug_info) {
      cerr << "\nFor data type definition, getting new data type: "
           << tmp_affi_type_str << "\n\n\n";
    }

    if (ir_to_fix->get_parent() && ir_to_fix->get_parent()->get_left() && ir_to_fix->get_parent()->get_left()->get_data_type() == DataColumnName) {
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

//void Mutator::instan_foreign_table_name(IR *ir_to_fix, bool is_debug_info) {

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
//}

void Mutator::instan_statistic_name(IR* ir_to_fix, bool is_debug_info)
{

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
      for (string& s : v_statistics_name) {
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

void Mutator::instan_sequence_name(IR* ir_to_fix, bool is_debug_info)
{

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
      for (string& s : v_sequence_name) {
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

void Mutator::instan_constraint_name(IR* ir_to_fix, bool is_debug_info)
{

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
      for (string& s : v_constraint_name) {
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

void Mutator::instan_family_name(IR* ir_to_fix, bool is_debug_info)
{

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
      for (string& s : v_family_name) {
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

void Mutator::instan_literal(IR* ir_to_fix, IR* cur_stmt_root,
    vector<IR*>& ir_to_deep_drop,
    bool is_debug_info)
{

  if (p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeSetStmt) || p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeSetBindingStmt) || p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeSetCollationExpr) || p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeSetConfigStmt) || p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeSetDefaultRoleStmt) || p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeSetOprStmt)) {
    /*
     * Should not change any literals inside the TypeOptStorageParams and
     * TypeSetVar clause. These literals are for Storage Parameters (Storage
     * Settings) or SET parameters. These values will be fixed by another
     * fixing function, later in the second ir_to_fix loop.
     * */
    return;
  }

  // TODO: Disable the complicated literal instantiation for now.
  return;

  //  /* First Loop, handles IN expression and Values clause.  */
  //  IRTYPE type = ir_to_fix->get_ir_type();
  //
  //  if ((type == TypeFloatLiteral || type == TypeStringLiteral ||
  ////       type == TypeDBool ||
  //       type == TypeIntegerLiteral) &&
  //      (p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeValuesClause)
  //       //          p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeTuple)
  //       )) {
  //    /* Completely rewritten Literal handling and mutation logic.
  //     * The idea is to search for the closest Column Name or fixed literals,
  //     * and try to match the type of the column name or literal.
  //     * */
  //
  //    ir_to_fix->set_is_instantiated(true);
  //
  //    // Handle the ValuesClause.
  //    // Get the TypeExprsNode first.
  //    IR *type_exprs_node =
  //        p_oracle->ir_wrapper.get_parent_node_with_type(ir_to_fix, TypeExpr);
  //
  //    if (is_debug_info) {
  //      cerr << "\n\n\nDependency: INFO: Removing the original VALUES clause "
  //              "expression:"
  //           << type_exprs_node->to_string() << "\n\n\n";
  //    }
  //
  //    // Remove the original expressions.
  //    if (type_exprs_node == nullptr || type_exprs_node->get_left() == nullptr) {
  //      // TODO: Dynamic fixing error?
  //      if (is_debug_info) {
  //        cerr << "\n\n\nERROR: Getting NULL left node from type_exprs_node. "
  //                "Give up and ignore. \n\n\n";
  //      }
  //      return;
  //    }
  //
  //    IR *type_exprs_left_node = type_exprs_node->get_left();
  //    type_exprs_node->update_left(nullptr);
  //    // Avoid further handling of the child node from `TypeValueClauses`
  //    p_oracle->ir_wrapper.iter_cur_node_with_handler(
  //        type_exprs_left_node, [](IR *cur_node) -> void {
  //          cur_node->set_is_instantiated(true);
  //          cur_node->set_data_flag(ContextNoModi);
  //        });
  //    if (type_exprs_left_node != nullptr) {
  //      ir_to_deep_drop.push_back(type_exprs_left_node);
  //    }
  //
  //    IR *type_exprs_right_node = type_exprs_node->get_right();
  //    type_exprs_node->update_right(nullptr);
  //    // Avoid further handling of the child node from `TypeValueClauses`
  //    p_oracle->ir_wrapper.iter_cur_node_with_handler(
  //        type_exprs_right_node, [](IR *cur_node) -> void {
  //          cur_node->set_is_instantiated(true);
  //          cur_node->set_data_flag(ContextNoModi);
  //        });
  //    if (type_exprs_right_node != nullptr) {
  //      ir_to_deep_drop.push_back(type_exprs_right_node);
  //    }
  //    type_exprs_node->op_->middle_ = "";
  //
  //    /* Reconstruct the new type expressions clause that matched the referenced
  //     * table.
  //     */
  //
  //    if (p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeINExpr)) {
  //      /* Fix for the IN clause. */
  //      vector<DATATYPE> search_type = {DataColumnName, DataColumnAliasName};
  //      vector<IRTYPE> cap_type = {TypeSelect};
  //      IR *closet_column_node =
  //          p_oracle->ir_wrapper.find_closest_nearby_IR_with_type(
  //              ir_to_fix, search_type, cap_type);
  //
  //      if (closet_column_node == nullptr) {
  //        if (is_debug_info) {
  //          cerr << "\n\n\nLOGIC ERROR: Inside the IN clause, cannot find the "
  //                  "nearby column name. Dummy fix. Return. \n\n\n";
  //        }
  //        IR *new_dummy_node =
  //            new IR(TypeIntegerLiteral, OP0(), nullptr, nullptr);
  //        new_dummy_node->mutate_literal(AFFIINT);
  //        new_dummy_node->set_is_instantiated(true);
  //        type_exprs_node->update_left(new_dummy_node);
  //        return;
  //      }
  //
  //      string col_str = closet_column_node->get_str_val();
  //      DataAffinity col_affi = m_column2datatype[col_str];
  //
  //      // Avoid 0.
  //      int num_of_in_elem = get_rand_int(5) + 1;
  //
  //      string ret_str = "";
  //      for (int in_idx = 0; in_idx < num_of_in_elem; in_idx++) {
  //
  //        if (in_idx != 0) {
  //          ret_str += ", ";
  //        }
  //        ret_str += col_affi.get_mutated_literal();
  //      }
  //
  //      IR *new_type_exprs_node = new IR(TypeStringLiteral, ret_str);
  //      new_type_exprs_node->set_is_instantiated(true);
  //
  //      type_exprs_node->update_left(new_type_exprs_node);
  //
  //      if (is_debug_info) {
  //        cerr << "\n\n\nDependency: getting new IN clause expression: "
  //             << new_type_exprs_node->to_string() << ". \n\n\n";
  //      }
  //
  //      p_oracle->ir_wrapper.iter_cur_node_with_handler(
  //          type_exprs_left_node, [](IR *cur_node) -> void {
  //            cur_node->set_is_instantiated(true);
  //            cur_node->set_data_flag(ContextNoModi);
  //          });
  //
  //      return;
  //    } // IN clause
  //
  //    /* else, VALUE clause only?  */
  //
  //    // Search whether there are referenced columns in the `TypeNameList`.
  //    // If there is, should be the first TypeNameList from the statement.
  //    vector<IR *> v_type_name_list =
  //        p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(cur_stmt_root,
  //                                                           TypeNameList, false);
  //
  //    vector<DataAffinity> referencing_affinity;
  //    if (v_type_name_list.size() == 0) {
  //      // Cannot find a specifically referenced column name list.
  //      // Use the referenced table name to refer to the column name list.
  //      if (is_debug_info) {
  //        cerr << "\n\n\nDependency: Cannot find the column name list from "
  //                "the statement. \n\n\n";
  //      }
  //
  //      // Find the table name used in this statement.
  //      if (v_table_names_single.size() == 0) {
  //        if (is_debug_info) {
  //          cerr << "\n\n\nERROR: Cannot find the column name list AND table "
  //                  "name from the statement. \n\n\n";
  //        }
  //        DataAffinity cur_affi;
  //        cur_affi.set_data_affinity(AFFISTRING);
  //        referencing_affinity.push_back(cur_affi);
  //      } else {
  //        // Found the table name referenced from the statement.
  //        if (is_debug_info) {
  //          cerr << "\n\n\nFound the table name referenced from the "
  //                  "statement, "
  //                  "table name: "
  //               << v_table_names_single.front() << ". \n\n\n";
  //        }
  //        string cur_table_name = v_table_names_single.front();
  //        vector<string> column_list;
  //        bool is_alias = false;
  //        if (m_alias_table2column_single.count(cur_table_name) > 0) {
  //          is_alias = true;
  //          column_list = m_alias_table2column_single[cur_table_name];
  //        } else {
  //          is_alias = false;
  //          column_list = m_table2columns[cur_table_name];
  //        }
  //        for (const string &cur_column_str : column_list) {
  //          string actual_column_str = cur_column_str;
  //          if (is_alias && m_alias2column_single.count(actual_column_str) > 0) {
  //            if (is_debug_info) {
  //              cerr << "\n\n\nDependency: INFO: In literal fixing, mapping the "
  //                      "column alias: "
  //                   << cur_column_str << " to column name: " << actual_column_str
  //                   << "\n\n\n";
  //            }
  //            actual_column_str = m_alias2column_single[cur_column_str];
  //          }
  //          if (m_column2datatype.count(actual_column_str) > 0) {
  //            DataAffinity cur_affi = m_column2datatype[actual_column_str];
  //            referencing_affinity.push_back(cur_affi);
  //            if (is_debug_info) {
  //              cerr << "\n\n\nMatching column: " << cur_column_str
  //                   << " from table: " << cur_table_name << " with data type: "
  //                   << get_string_by_affinity_type(cur_affi.get_data_affinity())
  //                   << "\n\n\n";
  //            }
  //          } else {
  //            DataAffinity cur_affi;
  //            cur_affi.set_data_affinity(AFFISTRING);
  //            referencing_affinity.push_back(cur_affi);
  //            if (is_debug_info) {
  //              cerr << "\n\n\n Cannot find matching column types: "
  //                   << cur_column_str << ". Using dummy AFFISTRING instead. "
  //                   << "\n\n\n";
  //            }
  //          }
  //        }
  //      }
  //    } else {
  //      if (is_debug_info) {
  //        cerr << "\n\n\nDependency: Find the column name list from the stmt:"
  //             << v_type_name_list.front()->to_string() << ". \n\n\n";
  //      }
  //
  //      IR *type_list_node = v_type_name_list.front();
  //      vector<string> &v_column_str = this->v_column_names_single;
  //      if (v_column_str.size() != 0) {
  //        for (string &cur_column_str : v_column_str) {
  //          string actual_column_str = cur_column_str;
  //          if (m_alias2column_single.count(cur_column_str)) {
  //            actual_column_str = m_alias2column_single[cur_column_str];
  //            if (is_debug_info) {
  //              cerr << "\n\n\nDependency: INFO: In literal fixing, mapping the "
  //                      "column alias: "
  //                   << cur_column_str << " to column name: " << actual_column_str
  //                   << "\n\n\n";
  //            }
  //          }
  //          DataAffinity cur_affi = m_column2datatype[actual_column_str];
  //          referencing_affinity.push_back(cur_affi);
  //          if (is_debug_info) {
  //            cerr << "\n\n\nMatching column: " << cur_column_str
  //                 << " with data type: "
  //                 << get_string_by_affinity_type(cur_affi.get_data_affinity())
  //                 << "\n\n\n";
  //          }
  //        }
  //      }
  //
  //      else {
  //
  //        vector<IR *> v_column_node =
  //            p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(
  //                type_list_node, DataColumnName, false);
  //        for (IR *cur_column_node : v_column_node) {
  //          string cur_column_str = cur_column_node->get_str_val();
  //          if (m_column2datatype.count(cur_column_str) ||
  //              m_alias2column_single.count(cur_column_str)) {
  //            string actual_column_str = cur_column_str;
  //            if (m_alias2column_single.count(cur_column_str)) {
  //              actual_column_str = m_alias2column_single[cur_column_str];
  //              if (is_debug_info) {
  //                cerr << "\n\n\nDependency: INFO: In literal fixing, mapping "
  //                        "the column alias: "
  //                     << cur_column_str
  //                     << " to column name: " << actual_column_str << "\n\n\n";
  //              }
  //            }
  //            DataAffinity cur_affi = m_column2datatype[actual_column_str];
  //            referencing_affinity.push_back(cur_affi);
  //            if (is_debug_info) {
  //              cerr << "\n\n\nMatching column: " << cur_column_str
  //                   << " with data type: "
  //                   << get_string_by_affinity_type(cur_affi.get_data_affinity())
  //                   << "\n\n\n";
  //            }
  //          } else {
  //            DataAffinity cur_affi;
  //            cur_affi.set_data_affinity(AFFISTRING);
  //            referencing_affinity.push_back(cur_affi);
  //            if (is_debug_info) {
  //              cerr << "\n\n\n Cannot find matching column types: "
  //                   << cur_column_str << ". Using dummy AFFISTRING instead. "
  //                   << "\n\n\n";
  //            }
  //          }
  //        }
  //      }
  //    }
  //
  //    // After we get a list of referencing_affinity, we can now begin to fill
  //    // in the ValuesClause expression.
  //    string ret_str = "";
  //    int idx = 0;
  //    for (DataAffinity &cur_affi : referencing_affinity) {
  //      if (idx != 0) {
  //        ret_str += ", ";
  //      }
  //      ret_str += cur_affi.get_mutated_literal();
  //      idx++;
  //    }
  //    IR *new_values_expr_node = new IR(TypeStringLiteral, ret_str);
  //    new_values_expr_node->set_is_instantiated(true);
  //
  //    type_exprs_node->update_left(new_values_expr_node);
  //
  //    if (is_debug_info) {
  //      cerr << "\n\n\nDependency: getting new values clause expression: "
  //           << new_values_expr_node->to_string() << ". \n\n\n";
  //    }
  //
  //    p_oracle->ir_wrapper.iter_cur_node_with_handler(
  //        type_exprs_left_node, [](IR *cur_node) -> void {
  //          cur_node->set_is_instantiated(true);
  //          cur_node->set_data_flag(ContextNoModi);
  //        });
  //
  //    return;
  //  }
  //
  //  /* The second loop */
  //
  //  type = ir_to_fix->get_ir_type();
  //
  //  if (type == TypeFloatLiteral || type == TypeStringLiteral ||
  //      type == TypeDBool || type == TypeIntegerLiteral) {
  //    /* Continue from the previous loop, we now search around the ir_to_fix
  //     * and see if we can find column name or literals that can help deduce
  //     * Data Affinity.
  //     * */
  //
  //    ir_to_fix->set_is_instantiated(true);
  //
  //    if (is_debug_info) {
  //      cerr << "\n\n\nTrying to fix literal: " << ir_to_fix->to_string()
  //           << "\n whole stmt: " << cur_stmt_root->to_string() << "\n\n\n";
  //    }
  //
  //    // Do not change the Data Affinity type for IS / IS NOT `TRUE/FALSE`.
  //    if (ir_to_fix->get_ir_type() == TypeDBool &&
  //        ir_to_fix->get_parent() != nullptr &&
  //        ir_to_fix->get_parent()->get_parent() != nullptr &&
  //        ir_to_fix->get_parent()->get_parent()->get_ir_type() ==
  //            TypeBinExprFmtWithParen &&
  //        (ir_to_fix->get_parent()->get_parent()->get_middle() == " IS " ||
  //         ir_to_fix->get_parent()->get_parent()->get_middle() == " IS NOT ")) {
  //      if (is_debug_info) {
  //        cerr << "\n\n\nDebug: Instantiate Boolean in IS or IS NOT statement. "
  //                "\n\n\n";
  //      }
  //      if (get_rand_int(2)) {
  //        ir_to_fix->set_str_val("TRUE");
  //      } else {
  //        ir_to_fix->set_str_val("FALSE");
  //      }
  //      return;
  //    }
  //
  //    // If the literal already has fixed data affinity type, skip the
  //    // mutation.
  //    if (ir_to_fix->get_data_flag() == ContextNoModi) {
  //      if (is_debug_info) {
  //        cerr << "\n\n\nSkip fixing literal: " << ir_to_fix->to_string()
  //             << " because it has "
  //                "flag ContextNoModi. \n\n\n";
  //      }
  //      return;
  //    }
  //
  //    ir_to_fix->set_data_affinity(
  //        this->get_nearby_data_affinity(ir_to_fix, is_debug_info));
  //
  //    /* After knowing the data affinity of the literal,
  //     * we have three choices to instantiate the value.
  //     * 1. If the statement contains one column that matches the
  //     * data type, use the column with probability.
  //     * 2. If the current data affinity is the same as previous
  //     * fixed literals, reuse the value.
  //     * 3. Mutate to get a new value.
  //     * */
  //    if (m_datatype2column.count(ir_to_fix->get_data_affinity()) &&
  //        get_rand_int(10) == 0 // 1/10 chance.
  //    ) {
  //      if (ir_to_fix->get_data_affinity() != AFFIUNKNOWN) {
  //        // This is a special context that the Data Affinity type of the
  //        // column name node has been pre-defined.
  //        // This is used in query dynamic fixing, where the replaced query nodes
  //        // are saved in a whole, and the column node data affinity are
  //        // preserved.
  //        string cur_chosen_col =
  //            vector_rand_ele(m_datatype2column[ir_to_fix->get_data_affinity()]);
  //
  //        bool is_col_imported = false;
  //        for (string cur_used_table : v_table_names_single) {
  //          vector<string> v_imported_col = m_table2columns[cur_used_table];
  //          if (find_vector(v_imported_col, cur_chosen_col)) {
  //            is_col_imported = true;
  //            break;
  //          }
  //        }
  //
  //        // Fix as column name.
  //        if (is_col_imported) {
  //          ir_to_fix->set_is_instantiated(true);
  //          ir_to_fix->set_str_val(cur_chosen_col);
  //          return;
  //        }
  //      }
  //    }
  //
  //    if (m_datatype2literals[ir_to_fix->get_data_affinity()].size() != 0 &&
  //        get_rand_int(2) == 0) {
  //      // Reuse previous defined literals.
  //      string tmp_new_literal =
  //          vector_rand_ele(m_datatype2literals[ir_to_fix->get_data_affinity()]);
  //      ir_to_fix->set_str_val(tmp_new_literal);
  //      if (is_debug_info) {
  //        cerr << "\n\n\nDependency: In Fixing literals, getting new literal: "
  //             << ir_to_fix->to_string() << "\n\n\n";
  //      }
  //    } else {
  //      // Now we ensure the ir_to_fix has an affinity.
  //      // Mutate the literal with the affinity
  //      ir_to_fix->mutate_literal(); // Handles everything.
  //      m_datatype2literals[ir_to_fix->get_data_affinity()].push_back(
  //          ir_to_fix->get_str_val());
  //      if (is_debug_info) {
  //        cerr << "\n\n\nDependency: In Fixing literals, getting new literal: "
  //             << ir_to_fix->to_string()
  //             << "\n whole stmt: " << cur_stmt_root->to_string() << "\n\n\n";
  //      }
  //    }
  //  }

  return;
}

//void Mutator::instan_storage_param(IR *ir_to_fix, vector<IR *> &ir_to_deep_drop,
//                                   bool is_debug_info) {
//
//  IRTYPE type = ir_to_fix->get_ir_type();
//  DATATYPE data_type = ir_to_fix->get_data_type();
//
//  if (type == TypeStorageParams && data_type == DataStorageParams) {
//
//    if (ir_to_fix->get_parent() == NULL) {
//      cerr << "\n\n\nLogical Error: Getting empty parent from "
//              "TypeStorageParams. \n\n\n";
//    }
//
//    IR *opt_storage_params = ir_to_fix->get_parent();
//
//    IR *opt_storage_params_left = opt_storage_params->get_left();
//    IR *opt_storage_params_right = opt_storage_params->get_right();
//
//    if (opt_storage_params_left != NULL) {
//      p_oracle->ir_wrapper.iter_cur_node_with_handler(
//          opt_storage_params_left, [](IR *cur_node) -> void {
//            cur_node->set_is_instantiated(true);
//            cur_node->set_data_flag(ContextNoModi);
//          });
//      ir_to_deep_drop.push_back(opt_storage_params_left);
//    }
//    if (opt_storage_params_right != NULL) {
//      p_oracle->ir_wrapper.iter_cur_node_with_handler(
//          opt_storage_params_right, [](IR *cur_node) -> void {
//            cur_node->set_is_instantiated(true);
//            cur_node->set_data_flag(ContextNoModi);
//          });
//      ir_to_deep_drop.push_back(opt_storage_params_right);
//    }
//
//    // Do not use param_num == 0;
//    IR *new_storage_param_node =
//        this->constr_rand_storage_param(get_rand_int(3) + 1);
//    new_storage_param_node->set_is_instantiated(true);
//    opt_storage_params->update_left(new_storage_param_node);
//    opt_storage_params->update_right(NULL);
//  }
//
//  return;
//}

void Mutator::map_create_view(IR* ir_to_fix, IR* cur_stmt_root,
    const vector<vector<IR*>> cur_stmt_ir_to_fix_vec,
    bool is_debug_info)
{

  if (ir_to_fix->data_type_ != DataTableName && ir_to_fix->data_type_ != DataViewName) {
    return;
  }

  /* Add missing mapping for CREATE VIEW stmt.  */
  /* Check whether we are in the CreateViewStatement. If yes, save the
   * column mapping. */
  IR* cur_ir = ir_to_fix;
  bool is_in_create_view = false;
  if (cur_stmt_root->get_ir_type() == TypeCreateViewStmt) {
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
    vector<IR*> tmp_column_vec;
    vector<IR*> all_mentioned_column_vec;
    set<DATATYPE> column_type_set = { DataColumnName };
    collect_ir(cur_stmt_root, column_type_set, all_mentioned_column_vec);

    for (IR* cur_mentioned_column : all_mentioned_column_vec) {
      if (p_oracle->ir_wrapper.is_ir_in(cur_mentioned_column,
              TypeSelectStmt)) {
        tmp_column_vec.push_back(cur_mentioned_column);
      }
    }
    all_mentioned_column_vec = tmp_column_vec;
    tmp_column_vec.clear();

    /* Fix: also, add column alias name defined here to the table */
    vector<IR*> all_mentioned_column_alias_vec;
    set<DATATYPE> column_alias_type_set = { DataColumnAliasName };
    collect_ir(cur_stmt_root, column_alias_type_set,
        all_mentioned_column_alias_vec);

    for (IR* cur_mentioned_alias : all_mentioned_column_alias_vec) {
      if (p_oracle->ir_wrapper.is_ir_in(cur_mentioned_alias, TypeSelectStmt)) {
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
      for (auto& cur_column_alias_ir : all_mentioned_column_alias_vec) {
        string cur_column_alias = cur_column_alias_ir->get_str_val();
        vector<string>& v_view_column_str = m_table2columns[ir_to_fix->get_str_val()];
        if (find(v_view_column_str.begin(), v_view_column_str.end(),
                cur_column_alias)
            == v_view_column_str.end()) {
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
      for (const IR* const cur_men_column_ir : all_mentioned_column_vec) {
        string cur_men_column_str = cur_men_column_ir->str_val_;
        if (findStringIn(cur_men_column_str, ".")) {
          vector<string> v_cur_men_column_str = string_splitter(cur_men_column_str, '.');
          cur_men_column_str = v_cur_men_column_str[v_cur_men_column_str.size() - 1];
        }
        vector<string>& cur_m_table = m_table2columns[ir_to_fix->str_val_];
        if (std::find(cur_m_table.begin(), cur_m_table.end(),
                cur_men_column_str)
            == cur_m_table.end()) {
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
        vector<IR*> all_mentioned_table_vec, all_mentioned_table_kUsed_vec;
        set<DATATYPE> table_type_set = { DataTableName };
        collect_ir(cur_stmt_root, table_type_set, all_mentioned_table_vec);
        for (IR* mentioned_table_ir : all_mentioned_table_vec) {
          if (mentioned_table_ir->data_flag_ == ContextUse) {
            all_mentioned_table_kUsed_vec.push_back(mentioned_table_ir);
            if (is_debug_info) {
              cerr << "Dependency: For mapping CREATE VIEW, getting "
                      "mentioned table name: "
                   << mentioned_table_ir->str_val_ << ". \n\n\n";
            }
          }
        }
        for (IR* cur_men_tablename_ir : all_mentioned_table_kUsed_vec) {
          string cur_men_tablename_str = cur_men_tablename_ir->str_val_;
          const vector<string>& cur_men_column_vec = m_table2columns[cur_men_tablename_str];
          for (const string& cur_men_column_str : cur_men_column_vec) {
            vector<string>& cur_m_table = m_table2columns[ir_to_fix->str_val_];
            if (std::find(cur_m_table.begin(), cur_m_table.end(),
                    cur_men_column_str)
                == cur_m_table.end()) {
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

void Mutator::map_create_view_column(IR* ir_to_fix,
    vector<IR*>& ir_to_deep_drop,
    bool is_debug_info)
{

  // TODO: Disable the create view column name instantiation for now.
  return;
  //  IR *type_name_list =
  //      p_oracle->ir_wrapper.get_parent_node_with_type(ir_to_fix, TypeNameList);
  //  if (type_name_list == NULL) {
  //    if (is_debug_info) {
  //      cerr << "\n\n\nError: In DataViewColumnName fixing. Cannot find the "
  //              "type_name_list from the statement."
  //              "More debug info, view column is: "
  //           << ir_to_fix->to_string() << ". \n\n\n";
  //    }
  //    return;
  //  }
  //
  //  string ret_str = "";
  //  IR *near_view_name_node =
  //      p_oracle->ir_wrapper.find_closest_nearby_IR_with_type(ir_to_fix,
  //                                                            DataViewName);
  //  if (near_view_name_node == NULL) {
  //    if (is_debug_info) {
  //      cerr << "\n\n\nError: In DataViewColumnName fixing. Cannot find the "
  //              "near_view_name from the "
  //              "statement. More debug info, view column is: "
  //           << ir_to_fix->to_string() << ". \n\n\n";
  //    }
  //  }
  //  string near_view_name_str = near_view_name_node->to_string();
  //  vector<string> matched_columns = m_table2columns[near_view_name_str];
  //
  //  vector<string> v_new_view_col_name_str;
  //  int view_col_idx = 0;
  //  for (string cur_matched_columns : matched_columns) {
  //    string new_view_column_name = gen_view_column_name();
  //    v_new_view_col_name_str.push_back(new_view_column_name);
  //    m_column2datatype[new_view_column_name] =
  //        m_column2datatype[cur_matched_columns];
  //    m_datatype2column[m_column2datatype[cur_matched_columns]
  //                          .get_data_affinity()]
  //        .push_back(new_view_column_name);
  //
  //    if (view_col_idx != 0) {
  //      ret_str += ", ";
  //    }
  //
  //    view_col_idx++;
  //    ret_str += new_view_column_name;
  //
  //    if (is_debug_info) {
  //      cerr
  //          << "\n\n\nDependency: INFO:: Transporting data affinity from column: "
  //          << cur_matched_columns << " to view column: " << new_view_column_name
  //          << ", with affinity: "
  //          << get_string_by_affinity_type(
  //                 m_column2datatype[new_view_column_name].get_data_affinity())
  //          << ". \n\n\n";
  //    }
  //  }
  //
  //  m_table2columns[near_view_name_str] = v_new_view_col_name_str;
  //
  //  if (is_debug_info) {
  //    for (string &view_col_name : v_new_view_col_name_str) {
  //      cerr << "\n\n\nDependency: INFO:: Appending new view column: "
  //           << view_col_name << " to view: " << near_view_name_str << ". \n\n\n";
  //    }
  //  }
  //
  //  // At last, switch the whole TypeNameList node in the Create View column
  //  // clause.
  //  //            ret_str = "(" + ret_str + ")";
  //  IR *new_name_list_ir = new IR(TypeNameList, ret_str);
  //
  //  IR *name_list_left = type_name_list->get_left();
  //  IR *name_list_right = type_name_list->get_right();
  //
  //  if (name_list_left != NULL) {
  //    ir_to_deep_drop.push_back(name_list_left);
  //    p_oracle->ir_wrapper.iter_cur_node_with_handler(
  //        name_list_left, [](IR *cur_node) -> void {
  //          cur_node->set_is_instantiated(true);
  //          cur_node->set_data_flag(ContextNoModi);
  //        });
  //  }
  //  if (name_list_right) {
  //    ir_to_deep_drop.push_back(name_list_right);
  //    p_oracle->ir_wrapper.iter_cur_node_with_handler(
  //        name_list_right, [](IR *cur_node) -> void {
  //          cur_node->set_is_instantiated(true);
  //          cur_node->set_data_flag(ContextNoModi);
  //        });
  //  }
  //
  //  type_name_list->update_left(new_name_list_ir);
  //  type_name_list->update_right(NULL);
  //  type_name_list->op_->middle_ = "";

  return;
}

void Mutator::instan_func_expr(IR* ir_to_fix, vector<IR*>& ir_to_deep_drop,
    bool is_ignore_nested_expr, bool is_debug_info)
{

  if (p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeSetStmt)) {
    if (is_debug_info) {
      cerr << "\n\n\nInside instan_func_expr, the statment is inside "
              "TypeSetVar or"
              " inside TypeStorageParams, skippped. \n\n\n";
    }
    return;
  }

  // TODO::Disable the function name instantiation for now.
  //  if (ir_to_fix->get_data_type() == DataFunctionName) {
  //    IR *ori_ir_to_fix = ir_to_fix;
  //    ir_to_fix = p_oracle->ir_wrapper.get_parent_node_with_type(
  //        ir_to_fix, DataFunctionExpr);
  //    if (ir_to_fix == NULL) {
  //      ir_to_fix = p_oracle->ir_wrapper.get_parent_node_with_type(ori_ir_to_fix,
  //                                                                 TypeFuncObj);
  //    }
  //    if (ir_to_fix == NULL) {
  //      if (is_debug_info) {
  //        cerr << "\n\n\nERROR: Inside instan_func_expr, cannot get "
  //                "DataFunctionExpr/TypeFuncObj from DataFunctionName. \n\n\n";
  //      }
  //      return;
  //    }
  //  }
  //
  //  /* Fixing for functions.  */
  //  if (ir_to_fix->get_data_type() == DataFunctionExpr ||
  //      ir_to_fix->get_ir_type() == TypeFuncObj) {
  //
  //    if (ir_to_fix->get_data_flag() == ContextNoModi) {
  //      return;
  //    }
  //
  //    // Loop through the function expression, do not mutate the current function
  //    // if the function contains nested structures.
  //    vector<IR *> all_nodes_in_func_expr =
  //        p_oracle->ir_wrapper.get_all_ir_node(ir_to_fix);
  //    for (IR *cur_node_in_func_expr : all_nodes_in_func_expr) {
  //      if (is_ignore_nested_expr) {
  //        break;
  //      }
  //
  //      if (cur_node_in_func_expr == ir_to_fix) {
  //        continue;
  //      }
  //      if (p_oracle->is_expr_types_in_where_clause(
  //              cur_node_in_func_expr->get_ir_type())) {
  //        if (is_debug_info) {
  //          cerr << "\n\n\nFound ir type: "
  //               << get_string_by_ir_type(cur_node_in_func_expr->get_ir_type())
  //               << " inside the function expression, matching with where expr "
  //                  "types. \n\n\n";
  //        }
  //        ir_to_fix->set_is_instantiated(true);
  //        break;
  //      }
  //    }
  //
  //    if (ir_to_fix->get_is_instantiated()) {
  //      // If true, the function contains nested expressions, skipped.
  //      if (is_debug_info) {
  //        cerr << "\n\n\nInside instan_func_expr, the function expression"
  //                " contains nested expressions, do not mutate on this func. "
  //                "\n\n\n";
  //      }
  //      return;
  //    }
  //
  //    IR *parent_node = ir_to_fix->get_parent();
  //    if (parent_node == NULL) {
  //      if (is_debug_info) {
  //        cerr << "\n\n\nERROR: Getting parent node is empty in "
  //                "instan_func_expr. \n\n\n";
  //      }
  //      return;
  //    }
  //
  //    DATAAFFINITYTYPE chosen_affi;
  //    if (p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeSelectExprs)) {
  //      // If in the SELECT clause, we can choose any affinity we want.
  //      chosen_affi = get_random_affinity_type(
  //          true, true); // no array types. Only basic types.
  //    } else {
  //      chosen_affi = this->get_nearby_data_affinity(ir_to_fix, is_debug_info);
  //    }
  //
  //    IR *new_func_node =
  //        constr_rand_func_with_affinity(chosen_affi, is_debug_info);
  //
  //    parent_node->swap_node(ir_to_fix, new_func_node);
  //
  //    if (is_debug_info) {
  //      cerr << "\n\n\nDependency: Inside instan_func_expr, generating new "
  //              "function: "
  //           << new_func_node->to_string() << "\n\n\n";
  //    }
  //
  //    ir_to_deep_drop.push_back(ir_to_fix);
  //    p_oracle->ir_wrapper.iter_cur_node_with_handler(
  //        ir_to_fix, [](IR *cur_node) -> void {
  //          cur_node->set_is_instantiated(true);
  //          cur_node->set_data_flag(ContextNoModi);
  //        });
  //  }

  return;
}

//void Mutator::remove_type_annotation(IR *cur_stmt_root,
//                                     vector<IR *> &ir_to_deep_drop) {
//
//  // Ignore all kinds of Column Type changes for now.
//
//  vector<IR *> v_type_annotation_node =
//      p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(
//          cur_stmt_root, TypeAnnotateTypeExpr, false, true);
//
//  for (IR *cur_type_anno_node : v_type_annotation_node) {
//    if (cur_type_anno_node->get_middle() != ":::") {
//      // Only remove the force type casting statement.
//      continue;
//    }
//    IR *right_node = cur_type_anno_node->get_right();
//    cur_type_anno_node->update_right(NULL);
//    cur_type_anno_node->op_->middle_ = "";
//    if (right_node != NULL) {
//      ir_to_deep_drop.push_back(right_node);
//      p_oracle->ir_wrapper.iter_cur_node_with_handler(
//          right_node, [](IR *cur_node) -> void {
//            cur_node->set_is_instantiated(true);
//            cur_node->set_data_flag(ContextNoModi);
//          });
//    }
//  }
//
//  v_type_annotation_node = p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(
//      cur_stmt_root, TypeCastExpr, false, true);
//
//  for (IR *cur_type_anno_node : v_type_annotation_node) {
//    if (cur_type_anno_node->get_middle() == "::") {
//      IR *right_node = cur_type_anno_node->get_right();
//      cur_type_anno_node->update_right(NULL);
//      cur_type_anno_node->op_->middle_ = "";
//      if (right_node != NULL) {
//        ir_to_deep_drop.push_back(right_node);
//        p_oracle->ir_wrapper.iter_cur_node_with_handler(
//            right_node, [](IR *cur_node) -> void {
//              cur_node->set_is_instantiated(true);
//              cur_node->set_data_flag(ContextNoModi);
//            });
//      }
//    } else if (cur_type_anno_node->get_left() != NULL &&
//               cur_type_anno_node->get_left()->get_data_type() ==
//                   DataTypeName) {
//      IR *left_node = cur_type_anno_node->get_left();
//      cur_type_anno_node->update_left(nullptr);
//      left_node->set_is_instantiated(true);
//      left_node->set_data_flag(ContextNoModi);
//      ir_to_deep_drop.push_back(left_node);
//    }
//  }
//
//  return;
//}

bool Mutator::instan_dependency(
    IR* cur_stmt_root, const vector<vector<IR*>> cur_stmt_ir_to_fix_vec,
    bool is_debug_info)
{

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
  vector<IR*> ir_to_deep_drop;
  string cur_ir_str = cur_stmt_root->to_string();

  //  this->remove_type_annotation(cur_stmt_root, ir_to_deep_drop);

//  if (is_debug_info) {
//    cerr << "\n\n\nAfter removing the type annotations, getting "
//         << cur_stmt_root->to_string() << "\n\n\n";
//  }

  // If set true, meaning we are in an ALTER TABLE RENAME statement.
  bool is_replace_table = false, is_replace_column = false;

  for (const vector<IR*>& ir_to_fix_vec :
      cur_stmt_ir_to_fix_vec) { // Loop for substmt.

    /* Fix all DataDataBaseName and DataSchemaName */
    for (IR* ir_to_fix : ir_to_fix_vec) {
      if (ir_to_fix->get_is_instantiated()) {
        continue;
      }
      this->instan_database_schema_name(ir_to_fix, is_debug_info);
    }

    /* Definition of TypeDataTableName */
    for (IR* ir_to_fix : ir_to_fix_vec) {
      if (ir_to_fix->get_is_instantiated()) {
        continue;
      }

      if ((ir_to_fix->data_type_ == DataTableName) && (ir_to_fix->data_flag_ == ContextDefine || ir_to_fix->data_flag_ == ContextReplaceDefine)) {
        this->instan_table_name(ir_to_fix, is_replace_table, is_debug_info);
      }
    }

    /* Undefine of TypeDataTableName */
    for (IR* ir_to_fix : ir_to_fix_vec) {
      if (ir_to_fix->get_is_instantiated()) {
        continue;
      }

      if (ir_to_fix->data_type_ == DataTableName && (ir_to_fix->data_flag_ == ContextUndefine || ir_to_fix->data_flag_ == ContextReplaceUndefine)) {
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
    for (IR* ir_to_fix : ir_to_fix_vec) {
      if (ir_to_fix->get_is_instantiated()) {
        continue;
      }

      // If NOT IN WITH clause, do not fix before the Table Name ContextUse.
      if (!p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeWithClause)) {
        continue;
      }

      if (ir_to_fix->data_type_ == DataTableAliasName) {
        ir_to_fix->set_is_instantiated(true);
        // For the WITH clause table alias, the usage is optional.
        this->instan_table_alias_name(ir_to_fix, cur_stmt_root, true,
            is_debug_info);
      }
    }

    /* ContextUse of kDataTableName */
    /* The ContextUseFollow will be handled further below. */
    for (IR* ir_to_fix : ir_to_fix_vec) {
      if (ir_to_fix->get_is_instantiated()) {
        continue;
      }

      if (ir_to_fix->data_type_ == DataTableName && ir_to_fix->data_flag_ == ContextUse) {
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
    for (IR* ir_to_fix : ir_to_fix_vec) {
      if (ir_to_fix->get_is_instantiated()) {
        continue;
      }

      // Fix the other aliases outside the WITH clause.
      if (p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeWithClause)) {
        continue;
      }

      if (ir_to_fix->data_type_ == DataTableAliasName) {
        ir_to_fix->set_is_instantiated(true);
        // For the table alias that is outside the WITH clause, the usage is
        // enforced!
        this->instan_table_alias_name(ir_to_fix, cur_stmt_root, false,
            is_debug_info);
      }
    }

    /* ContextUseFollow of DataTableName. */
    /* This scenario searches for table name usage that is in the WHERE clause.
     */
    for (IR* ir_to_fix : ir_to_fix_vec) {
      if (ir_to_fix->get_is_instantiated()) {
        continue;
      }

      if (ir_to_fix->data_type_ == DataTableName && ir_to_fix->data_flag_ == ContextUseFollow) {
        this->instan_table_name(ir_to_fix, is_replace_table, is_debug_info);
      }
    }

    /* Fix for kDataViewName. */
    for (IR* ir_to_fix : ir_to_fix_vec) {
      if (ir_to_fix->get_is_instantiated()) {
        continue;
      }
      if (ir_to_fix->get_data_type() == DataViewName) {
        this->instan_view_name(ir_to_fix, is_debug_info);
      }
    }

    /* Fix of DataPartitionName. */
    /* ContextDefine, ContextUse and ContextUndefine of DataPartitionName. */
    for (IR* ir_to_fix : ir_to_fix_vec) {
      if (ir_to_fix->get_is_instantiated()) {
        continue;
      }
      if (ir_to_fix->get_data_type() == DataPartitionName) {
        this->instan_partition_name(ir_to_fix, is_debug_info);
      }
    }

    /* Fix of kDataIndex name. */
    for (IR* ir_to_fix : ir_to_fix_vec) {
      if (ir_to_fix->get_is_instantiated()) {
        continue;
      }

      this->instan_index_name(ir_to_fix, is_debug_info);
    }

    /* kDefine and kReplace of kDataColumnName */
    for (IR* ir_to_fix : ir_to_fix_vec) {
      if (ir_to_fix->get_is_instantiated()) {
        continue;
      }

      if (ir_to_fix->data_type_ == DataColumnName && (ir_to_fix->data_flag_ == ContextDefine || ir_to_fix->data_flag_ == ContextReplaceDefine)) {

        this->instan_column_name(ir_to_fix, cur_stmt_root, is_replace_column,
            ir_to_deep_drop, is_debug_info);

        /* ContextUndefine scenario of the DataColumnName */
      } else if (ir_to_fix->data_type_ == DataColumnName && ir_to_fix->data_flag_ == ContextUndefine) {

        this->instan_column_name(ir_to_fix, cur_stmt_root, is_replace_column,
            ir_to_deep_drop, is_debug_info);
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
    for (IR* ir_to_fix : ir_to_fix_vec) {
      if (ir_to_fix->get_is_instantiated()) {
        continue;
      }

      this->instan_column_alias_name(ir_to_fix, cur_stmt_root, ir_to_deep_drop,
          is_debug_info);
    }

    /* Fix the Data Type identifiers. Must be done after ContextDefine of
     * DataColumnName. */
    for (IR* ir_to_fix : ir_to_fix_vec) {
      if (ir_to_fix->get_is_instantiated()) {
        continue;
      }
      IRTYPE type = ir_to_fix->get_ir_type();
      DATATYPE data_type = ir_to_fix->get_data_type();
      DATAFLAG data_flag = ir_to_fix->get_data_flag();

      if (type == TypeIdentifier && data_type == DataTypeName && data_flag == ContextDefine) {
        // Handling of the Column Data Type definition.
        // Use basic types.

        this->instan_sql_type_name(ir_to_fix, is_debug_info);
      }
    }

    /* For ContextUse of DataColumnName.
     * Special case, avoid using duplicated column names
     * in the TypeNameList clause.
     * */
    for (IR* ir_to_fix : ir_to_fix_vec) {
      if (ir_to_fix->get_is_instantiated()) {
        continue;
      }
      if (ir_to_fix->data_type_ == DataColumnName && ir_to_fix->data_flag_ == ContextUse
          //          p_oracle->ir_wrapper.is_ir_in(ir_to_fix, TypeNameList)
      ) {
        this->instan_column_name(ir_to_fix, cur_stmt_root, is_replace_column,
            ir_to_deep_drop, is_debug_info);
      }
    }

    /* kUse of kDataColumnName */
    for (IR* ir_to_fix : ir_to_fix_vec) {
      if (ir_to_fix->get_is_instantiated()) {
        continue;
      }

      if (ir_to_fix->data_type_ == DataColumnName && ir_to_fix->data_flag_ == ContextUse) {
        this->instan_column_name(ir_to_fix, cur_stmt_root, is_replace_column,
            ir_to_deep_drop, is_debug_info);
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
    for (IR* ir_to_fix : ir_to_fix_vec) {

      if (ir_to_fix->get_is_instantiated()) {
        continue;
      }

      /* Fixing for functions.  */
      if (ir_to_fix->get_data_type() == DataFunctionExpr) {
        if (ir_to_fix->get_data_flag() == ContextNoModi) {
          continue;
        }

        instan_func_expr(ir_to_fix, ir_to_deep_drop, false, is_debug_info);
      }
    }

    /* Fix for statistic and sequence name */
    for (IR* ir_to_fix : ir_to_fix_vec) {
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
    for (IR* ir_to_fix : ir_to_fix_vec) {
      if (ir_to_fix->get_is_instantiated()) {
        continue;
      }

      this->instan_literal(ir_to_fix, cur_stmt_root, ir_to_deep_drop,
          is_debug_info);

    } /* for (IR* ir_to_fix : ir_to_fix_vec) */

    /* The next loop to handle all the Literals, after setting all literals to
     * AFFIUNKNOWN. */
    for (IR* ir_to_fix : ir_to_fix_vec) {
      if (ir_to_fix->get_is_instantiated()) {
        continue;
      }

      IRTYPE type = ir_to_fix->get_ir_type();

      if (type == TypeFloatLiteral || type == TypeStringLiteral || type == TypeIntegerLiteral) {
        /* Continue from the previous loop, we now search around the ir_to_fix
         * and see if we can find column name or literals that can help deduce
         * Data Affinity.
         * */

        this->instan_literal(ir_to_fix, cur_stmt_root, ir_to_deep_drop,
            is_debug_info);
      }
    } /* for (IR* ir_to_fix : ir_to_fix_vec) */

    for (IR* ir_to_fix : ir_to_fix_vec) {
      if (ir_to_fix->get_is_instantiated()) {
        continue;
      }

      IRTYPE type = ir_to_fix->get_ir_type();
      DATATYPE data_type = ir_to_fix->get_data_type();

      //      if (type == TypeStorageParams && data_type == DataStorageParams) {
      //
      //        this->instan_storage_param(ir_to_fix, ir_to_deep_drop, is_debug_info);
      //      }
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
  for (const vector<IR*>& ir_to_fix_vec : cur_stmt_ir_to_fix_vec) {

    /* Added mapping for Inheritance.  */
    for (IR* ir_to_fix : ir_to_fix_vec) {
      if (ir_to_fix->data_type_ == DataTableName && (cur_stmt_root->get_ir_type() == TypeCreateTableStmt || cur_stmt_root->get_ir_type() == TypeCreateViewStmt || cur_stmt_root->get_ir_type() == TypeCreateIndexStmt) &&
          //        p_oracle->ir_wrapper.is_ir_in(ir_to_fix, kOptInherit) &&
          ir_to_fix->data_flag_ == ContextUse) {
        if (v_create_table_names_single.size() > 0) {
          string cur_new_table_name_str = v_create_table_names_single.front();
          string inherit_table_name_str = ir_to_fix->get_str_val();

          vector<string>& inherit_m_tables = m_table2columns[inherit_table_name_str];

          for (string col_name : inherit_m_tables) {
            vector<string>& cur_col_list = m_table2columns[cur_new_table_name_str];
            if (find(cur_col_list.begin(), cur_col_list.end(), col_name) == cur_col_list.end()) {
              cur_col_list.push_back(col_name);
            }
          }
        }
      }
    }

    for (IR* ir_to_fix : ir_to_fix_vec) {

      this->map_create_view(ir_to_fix, cur_stmt_root, cur_stmt_ir_to_fix_vec,
          is_debug_info);

    } // for (IR* ir_to_fix : ir_to_fix_vec)

    // The second loop that fix the DataViewColumn.
    // Need to rewrite the column mapping.
    for (IR* ir_to_fix : ir_to_fix_vec) {
      if (ir_to_fix->get_data_type() == DataViewColumnName) {
        if (cur_stmt_root->get_ir_type() != TypeCreateViewStmt) {
          cerr << "\n\n\nError: Finding DataViewColumnName that is not in the "
                  "Create View statement. \n\n\n";
          continue;
        }
        this->map_create_view_column(ir_to_fix, ir_to_deep_drop, is_debug_info);
      }
    }
  } // for (const vector<IR *> &ir_to_fix_vec : cur_stmt_ir_to_fix_vec)

  for (IR* ir_to_drop : ir_to_deep_drop) {
    if (ir_to_drop) {
      ir_to_drop->deep_drop();
    }
  }
  return true;
}

static bool replace_in_vector(string& old_str, string& new_str,
    vector<string>& victim)
{
  for (int i = 0; i < victim.size(); i++) {
    if (victim[i] == old_str) {
      victim[i] = new_str;
      return true;
    }
  }
  return false;
}

static bool remove_in_vector(string& str_to_remove, vector<string>& victim)
{
  for (auto iter = victim.begin(); iter != victim.end(); iter++) {
    if (*iter == str_to_remove) {
      victim.erase(iter);
      return true;
    }
  }
  return false;
}

bool Mutator::remove_one_from_datalibrary(DATATYPE datatype, string& key)
{
  return remove_in_vector(key, data_library_[datatype]);
}

bool Mutator::replace_one_from_datalibrary(DATATYPE datatype, string& old_str,
    string& new_str)
{
  return replace_in_vector(old_str, new_str, data_library_[datatype]);
}

bool Mutator::remove_one_pair_from_datalibrary_2d(DATATYPE p_datatype,
    DATATYPE c_data_type,
    string& p_key)
{
  for (auto& value : data_library_2d_[p_datatype][p_key][c_data_type]) {
    remove_one_from_datalibrary(c_data_type, value);
  }

  data_library_2d_[p_datatype][p_key].erase(c_data_type);
  if (data_library_2d_[p_datatype][p_key].empty()) {
    remove_one_from_datalibrary(p_datatype, p_key);
    data_library_2d_[p_datatype].erase(p_key);
  }

  return true;
}

void Mutator::reset_data_library_single_stmt()
{
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

  // Clear the snapshot from the previous statement,
  // and save the new one.
  this->m_table2columns_snapshot.clear();
  this->m_table2partition_snapshot.clear();
  this->v_table_names_snapshot.clear();
  this->m_table2index_snapshot.clear();
  this->m_column2datatype_snapshot.clear();
  this->m_datatype2column_snapshot.clear();
  this->m_datatype2literals_snapshot.clear();
  this->v_statistics_name_snapshot.clear();
  this->v_sequence_name_snapshot.clear();
  this->v_view_name_snapshot.clear();
  this->v_constraint_name_snapshot.clear();
  this->v_family_name_snapshot.clear();
  this->v_foreign_table_name_snapshot.clear();
  this->v_table_with_partition_snapshot.clear();
  this->v_int_literals_snapshot.clear();
  this->v_float_literals_snapshot.clear();
  this->v_string_literals_snapshot.clear();

  // Clear the snapshot from the previous statement,
  // and save the new one.
  this->m_table2columns_snapshot = m_table2columns;
  this->m_table2partition_snapshot = m_table2partition;
  this->v_table_names_snapshot = v_table_names;
  this->m_table2index_snapshot = m_table2index;
  this->m_column2datatype_snapshot = m_column2datatype;
  this->m_datatype2column_snapshot = m_datatype2column;
  this->m_datatype2literals_snapshot = m_datatype2literals;
  this->v_statistics_name_snapshot = v_statistics_name;
  this->v_sequence_name_snapshot = v_sequence_name;
  this->v_view_name_snapshot = v_view_name;
  this->v_constraint_name_snapshot = v_constraint_name;
  this->v_family_name_snapshot = v_family_name;
  this->v_foreign_table_name_snapshot = v_foreign_table_name;
  this->v_table_with_partition_snapshot = v_table_with_partition;
  this->v_int_literals_snapshot = v_int_literals;
  this->v_float_literals_snapshot = v_float_literals;
  this->v_string_literals_snapshot = v_string_literals;
}

void Mutator::reset_data_library()
{
  reset_id_counter();
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

  this->reset_data_library_single_stmt();
}

static IR* search_mapped_ir(IR* ir, DATATYPE type)
{
  vector<IR*> to_search;
  vector<IR*> backup;
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

IR* Mutator::find_closest_node(IR* stmt_root, IR* node, DATATYPE type)
{
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
bool Mutator::get_select_str_from_lib(string& select_str)
{
  /* For 1/2 chance, grab one query from the SELECT library, and return.
   * For 1/2 chance, take the template from the p_oracle and return.
   */
  bool is_succeed = false;

  while (!is_succeed) { // Potential dead loop. Only escape through return.
    bool use_temp = false;
    int query_method = get_rand_int(2);
    if (all_valid_pstr_vec.size() > 0 && query_method == 0) {
      /* Pick the query from the lib, pass to the mutator. */
      select_str = *(all_valid_pstr_vec[get_rand_int(all_valid_pstr_vec.size())]);

      if (select_str == "" || !p_oracle->is_oracle_select_stmt(select_str))
        continue;
      use_temp = false;
    } else {
      /* get on randomly generated query from the RSG module. */
      if (!disable_rsg_generator) {
        select_str = this->rsg_generate_valid(TypeSelectStmt);
      }

      if (select_str == "") {
        // If RSG doesn't work, fall back to original template.
        select_str = p_oracle->get_template_select_stmts();
        use_temp = true;
      }
    }

    trim_string(select_str);
    return use_temp;
  }

  fprintf(stderr, "*** FATAL ERROR: Unexpected code execution in the "
                  "Mutator::get_select_str_from_lib function. \n");
  fflush(stderr);
  abort();
}

void Mutator::log_parser_crashes_bugs(string query_in)
{
  if (!filesystem::exists("../../Bug_Analysis/")) {
    filesystem::create_directory("../../Bug_Analysis/");
  }
  if (!filesystem::exists("../../Bug_Analysis/bug_samples")) {
    filesystem::create_directory("../../Bug_Analysis/bug_samples");
  }
  if (!filesystem::exists("../../Bug_Analysis/bug_samples/parser_crash")) {
    filesystem::create_directory("../../Bug_Analysis/bug_samples/parser_crash");
  }

  string bug_output_dir = "../../Bug_Analysis/bug_samples/parser_crash/bug:" + to_string(unique_parser_crashes_num) + ":core:" + std::to_string(this->bind_to_core_id) + ".txt";
  // cerr << "Bug output dir is: " << bug_output_dir << endl;
  ofstream outputfile;
  outputfile.open(bug_output_dir, std::ofstream::out | std::ofstream::app);
  outputfile << query_in;
  outputfile.close();

  unique_parser_crashes_num++;

#ifdef DEBUG
  cerr << "\n\n\n\n\nFOUND PARSER CRASHING BUG. \n\n\n\n\n";
#endif

  return;
}

vector<IR*> Mutator::parse_query_str_get_ir_set(string& query_str)
{
  vector<IR*> ir_set;

  ensure_semicolon_at_query_end(query_str);

  IR* root_ir = NULL;

  try {
    root_ir = raw_parser(query_str);
    if (root_ir == NULL) {
      return ir_set;
    }
  } catch (...) {
    return ir_set;
  }



  log_grammar_coverage(root_ir);

  /* Debug */
  // root_ir->deep_drop();
  // vector<IR*>dummp_vec;
  // return dummp_vec;

  ir_set = p_oracle->ir_wrapper.get_all_ir_node(root_ir);

  int unique_id_for_node = 0;
  for (auto ir : ir_set) {
    ir->uniq_id_in_tree_ = unique_id_for_node++;
    if (ir->get_ir_type() == TypeShutdownStmt || ir->get_ir_type() == TypeAlterUserStmt ||
        ir->get_ir_type() == TypeAlterDatabaseStmt || ir->get_ir_type() == TypeGrantLevel ||
        ir->get_ir_type() == TypeGrantRoleStmt || ir->get_ir_type() == TypeGrantStmt ||
        ir->get_ir_type() == TypeDropUserStmt || ir->get_ir_type() == TypeSetPwdStmt
        ) {
      // Do not parse these statements.
      root_ir->deep_drop();
      ir_set.clear();
      return ir_set;
    }

    if (ir->get_ir_type() == TypePanic) {
      // This is a crashing problem from the parser side.
      // If too much, consider disable this logging option.
      this->log_parser_crashes_bugs(query_str);
      root_ir->deep_drop();
      ir_set.clear();
      return ir_set;
    }

  }

  return ir_set;
}

bool Mutator::check_node_num(IR* root, unsigned int limit)
{

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

vector<IR*> Mutator::extract_statement(IR* root)
{
  vector<IR*> res;
  deque<IR*> bfs = { root };

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
void Mutator::set_disable_dyn_instan(bool dis_dyn)
{
  this->disable_dyn_instan = dis_dyn;
}

void Mutator::set_disable_rsg_generator(bool in)
{
  this->disable_rsg_generator = in;
}

int Mutator::get_ir_libary_2D_hash_kStatement_size()
{
  return this->real_ir_library_hash_[TypeStmt].size();
}

bool Mutator::is_stripped_str_in_lib(string stripped_str)
{
  // stripped_str = extract_struct(stripped_str);
  unsigned long str_hash = hash(stripped_str);
  if (stripped_string_hash_.find(str_hash) != stripped_string_hash_.end())
    return true;
  stripped_string_hash_.insert(str_hash);
  return false;
}

/* add_to_library supports only one stmt at a time,
 * add_all_to_library is responsible to split
 * the current IR tree into multiple query stmts.
 * This function is not responsible to free the input IR tree.
 */
bool Mutator::add_all_to_library(IR* ir, const vector<int>& explain_diff_id,
    u8 (*run_target)(char**, u32, string, int,
        string&))
{
  return add_all_to_library(ir->to_string(), explain_diff_id, run_target);
}

/*  Save an interesting query stmt into the mutator library.
 *
 * The uniq_id_in_tree_ should be, more ideally, being setup and kept unchanged
 * once an IR tree has been reconstructed. However, there are some difficulties
 * there. For example, how to keep the uniqueness and the fix order of the
 * unique_id_in_tree_ for each node in mutations. Therefore, setting and
 * checking the uniq_id_in_tree_ variable in every node of an IR tree are only
 * done when necessary by calling this function and
 * get_from_library_with_[_,left,right]_type. We ignore this unique_id_in_tree_
 * in other operations of the IR nodes. The unique_id_in_tree_ is set up based
 * on the order of the ir_set vector, returned from
 * ir_wrapper.get_all_ir_node(root_ir).
 *
 */

bool Mutator::add_all_to_library(string whole_query_str,
    const vector<int>& explain_diff_id,
    u8 (*run_target)(char**, u32, string, int,
        string&))
{

  bool ret_is_add_to_queue = false;

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
    return false; // Do not save this empty seed to the queue.

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

    vector<IR*> ir_set = parse_query_str_get_ir_set(current_query);
    if (ir_set.size() == 0)
      continue;

    IR* root = ir_set[ir_set.size() - 1];
    vector<IR*> v_cur_stmt_ir = p_oracle->ir_wrapper.get_stmt_ir_vec(root);
    if (v_cur_stmt_ir.size() == 0) {
      root->deep_drop();
      continue;
    }
    IR* cur_stmt_ir = v_cur_stmt_ir.front();

    if (cur_stmt_ir->get_ir_type() == TypeSetStmt || cur_stmt_ir->get_ir_type() == TypeBeginStmt || cur_stmt_ir->get_ir_type() == TypeRollbackStmt || cur_stmt_ir->get_ir_type() == TypeCommitStmt) {
      // Do not save the SET VAR statements and the transaction related
      // statements.
      root->deep_drop();
      continue;
    }

    // Do not pass the uniformed IR to the add_to_library subsequent function
    // calls. Because the statements will further checked by the
    // auto_mark_data_type function, where the literals and variables need
    // to be kept unchanged for them to work successfully.
    IR* extract_struct_root_tmp = root->deep_copy();
    string uniformed_query = this->extract_struct(extract_struct_root_tmp);
    extract_struct_root_tmp->deep_drop();

    if (p_oracle->is_oracle_select_stmt(cur_stmt_ir)) {
      if (std::find(explain_diff_id.begin(), explain_diff_id.end(), i) != explain_diff_id.end()) {
        add_to_valid_lib(root, uniformed_query, true, run_target);
      } else {
        add_to_valid_lib(root, uniformed_query, false, run_target);
      }
      ++i; // For counting SELECT stmt IDs.
    } else {
      // Check whether this statement is a new and interesting non-select
      // statement. Only if yes, save the query to the fuzzing queue. The
      // ret_is_add_queue variable will be passed out and later used to
      // determine the call of add_to_queue() function.
      if (add_to_library(root, uniformed_query, run_target)) {
        ret_is_add_to_queue = true;
      }
    }

    root->deep_drop();
  }

  return ret_is_add_to_queue;
}

void Mutator::add_to_valid_lib(IR* ir, string& uniformed_select,
    const bool is_explain_diff,
    u8 (*run_target)(char**, u32, string, int,
        string&))
{

  unsigned long p_hash = hash(uniformed_select);

  if (select_stmt_lib_hash.find(p_hash) != select_stmt_lib_hash.end()) {
    return;
  }

  select_stmt_lib_hash[p_hash] = true;

  string* new_select = new string(ir->to_string());

  all_query_pstr_set.insert(new_select);
  all_valid_pstr_vec.push_back(new_select);

  if (likely(!this->disable_dyn_instan) && run_target != NULL) {
    auto_mark_data_types_from_select_stmt(ir, argv_for_run_target,
        exec_tmout_for_run_target, 0,
        run_target, true);
    p_oracle->ir_wrapper.iter_cur_node_with_handler(
        ir, [](IR* cur_node) -> void { cur_node->set_is_instantiated(false); });
  }

  // Do not use extract_struct before add_to_library_core.
  // For safety purpose, any mismatch between the ir and the
  // p_query_str could cause problem in the fuzzing.

  add_to_library_core(ir, new_select);

  return;
}

bool Mutator::add_to_library(IR* ir, string& uniformed_query,
    u8 (*run_target)(char**, u32, string, int,
        string&))
{

  if (uniformed_query == "")
    return false;

  IRTYPE p_type = ir->type_;
  unsigned long p_hash = hash(uniformed_query);

  if (real_ir_library_hash_[p_type].find(p_hash) != real_ir_library_hash_[p_type].end()) {
    /* uniformed_query not interesting enough. Ignore it and clean up. */
    return false;
  }
  real_ir_library_hash_[p_type].insert(p_hash);

  string* p_query_str = new string(ir->to_string());
  all_query_pstr_set.insert(p_query_str);

//  if (likely(!this->disable_dyn_instan) && run_target != NULL) {
//    auto_mark_data_types_from_non_select_stmt(ir, argv_for_run_target,
//        exec_tmout_for_run_target, 0,
//        run_target, true);
//    p_oracle->ir_wrapper.iter_cur_node_with_handler(
//        ir, [](IR* cur_node) -> void { cur_node->set_is_instantiated(false); });
//  }

  // Do not use extract_struct before add_to_library_core.
  // For safety purpose, any mismatch between the ir and the
  // p_query_str could cause problem in the fuzzing.

  add_to_library_core(ir, p_query_str);

  return true;
}

void Mutator::add_to_library_core(IR* ir, string* p_query_str)
{
  /* Save an interesting query stmt into the mutator library. Helper function
   * for Mutator::add_to_library();
   */

  if (ir->left_) {
    add_to_library_core(ir->left_, p_query_str);
  }

  if (ir->right_) {
    add_to_library_core(ir->right_, p_query_str);
  }

  if (*p_query_str == "")
    return;

  int current_unique_id = ir->uniq_id_in_tree_;
  bool is_skip_saving_current_node = false; //

  IRTYPE p_type = ir->type_;
  IRTYPE left_type = TypeUnknown, right_type = TypeUnknown;

  string ir_str = ir->to_string();
  unsigned long p_hash = hash(ir_str);

  if (likely(!this->disable_dyn_instan) && p_type != TypeRoot && ir->get_is_compact_expr() && this->calc_node(ir) > 13) {

    if (data_affi_set_lib_hash_.count(p_type) != 0) {
      if (data_affi_set_lib_hash_[p_type].count(p_hash) != 0) {
        return;
      }
    }

    uint64_t data_affi_hash = ir->data_affinity.calc_hash();
    data_affi_set[data_affi_hash].push_back(ir->deep_copy());
  }

  if (p_type == TypeRoot || real_ir_library_hash_[p_type].find(p_hash) != real_ir_library_hash_[p_type].end()) {
    /* current node not interesting enough. Ignore it and clean up. */
    return;
  }

  if (p_type != TypeRoot)
    real_ir_library_hash_[p_type].insert(p_hash);

  if (!is_skip_saving_current_node) {
    real_ir_set[p_type].push_back(
        std::make_pair(p_query_str, current_unique_id));

    if (p_oracle->is_expr_types_in_where_clause(p_type)) {
      real_ir_set[TypeExpr].push_back(
          std::make_pair(p_query_str, current_unique_id));
    }
  }

  // Update right_lib, left_lib
  if (ir->right_ != NULL && ir->left_ != NULL && !is_skip_saving_current_node) {
    left_type = ir->left_->type_;
    right_type = ir->right_->type_;
    left_lib_set[left_type].push_back(std::make_pair(
        p_query_str, current_unique_id)); // Saving the parent node id. When
                                          // fetching, use current_node->right.
    right_lib_set[right_type].push_back(std::make_pair(
        p_query_str, current_unique_id)); // Saving the parent node id. When
                                          // fetching, use current_node->left.

    if (p_oracle->is_expr_types_in_where_clause(left_type)) {
      left_lib_set[TypeExpr].push_back(std::make_pair(
          p_query_str,
          current_unique_id)); // Saving the parent node id. When
                               // fetching, use current_node->right.
    }
    if (p_oracle->is_expr_types_in_where_clause(right_type)) {
      right_lib_set[TypeExpr].push_back(std::make_pair(
          p_query_str, current_unique_id)); // Saving the parent node id. When
                                            // fetching, use current_node->left.
    }
  }

  return;
}

int Mutator::get_cri_valid_collection_size()
{
  return all_cri_valid_pstr_vec.size();
}

int Mutator::get_valid_collection_size() { return all_valid_pstr_vec.size(); }

IR* Mutator::get_from_libary_with_type(IRTYPE type_)
{
  /* Given a data type, return a randomly selected previously seen IR node that
     matched the given type. If nothing has found, return an empty
     kStringLiteral.
  */

  // If the ir type matches any compatible query expression types,
  // use uniformly TypeExpr type.
  if (p_oracle->is_expr_types_in_where_clause(type_)) {
    type_ = TypeExpr;
  }

  vector<IR*> current_ir_set;
  IR* current_ir_root;
  vector<pair<string*, int>>& all_matching_node = real_ir_set[type_];
  IR* return_matched_ir_node = NULL;

  if (all_matching_node.size() > 0) {
    /* Pick a random matching node from the library. */
    int random_idx = get_rand_int(all_matching_node.size());
    std::pair<string*, int>& selected_matched_node = all_matching_node[random_idx];
    string* p_current_query_str = selected_matched_node.first;
    int unique_node_id = selected_matched_node.second;

    /* Reconstruct the IR tree. */
    current_ir_set = parse_query_str_get_ir_set(*p_current_query_str);
    if (current_ir_set.size() <= 0)
      return NULL;
    current_ir_root = current_ir_set.back();

    /* Retrieve the required node, clean up the IR tree and return.
     */
    IR* matched_ir_node = current_ir_set[unique_node_id];
    if (matched_ir_node != NULL) {
      if (matched_ir_node->type_ != type_ && type_ != TypeExpr) {
        current_ir_root->deep_drop();
        return NULL;
      }
      return_matched_ir_node = matched_ir_node;
      current_ir_root->detach_node(return_matched_ir_node);
    }

    current_ir_root->deep_drop();

    if (return_matched_ir_node != NULL) {
      return return_matched_ir_node;
    }
  }

  return NULL;
}

IR* Mutator::get_from_libary_with_left_type(IRTYPE type_)
{
  /* Given a left_ type, return a randomly selected previously seen right_ node
     that share the same parent. If nothing has found, return NULL.
  */

  if (p_oracle->is_expr_types_in_where_clause(type_)) {
    // If the ir type matches any compatible query expression types,
    // use uniformly TypeExpr type.
    type_ = TypeExpr;
  }

  vector<IR*> current_ir_set;
  IR* current_ir_root;
  vector<pair<string*, int>>& all_matching_node = left_lib_set[type_];
  IR* return_matched_ir_node = NULL;

  if (all_matching_node.size() > 0) {
    /* Pick a random matching node from the library. */
    int random_idx = get_rand_int(all_matching_node.size());
    std::pair<string*, int>& selected_matched_node = all_matching_node[random_idx];
    string* p_current_query_str = selected_matched_node.first;
    int unique_node_id = selected_matched_node.second;

    /* Reconstruct the IR tree. */
    current_ir_set = parse_query_str_get_ir_set(*p_current_query_str);
    if (current_ir_set.size() <= 0)
      return NULL;
    current_ir_root = current_ir_set.back();

    /* Retrive the required node, deep copy it, clean up the IR tree and return.
     */
    IR* matched_ir_node = current_ir_set[unique_node_id];
    if (matched_ir_node != NULL) {
      if ((matched_ir_node->left_ == NULL || matched_ir_node->left_->type_ != type_) && type_ != TypeExpr) {
        //        ERROR::: Type not matched
        current_ir_root->deep_drop();
        return NULL;
      }
      return_matched_ir_node = matched_ir_node->right_;
      current_ir_root->detach_node(return_matched_ir_node);
    }

    current_ir_root->deep_drop();

    if (return_matched_ir_node != NULL) {
      return return_matched_ir_node;
    }
  }

  return NULL;
}

IR* Mutator::get_from_libary_with_right_type(IRTYPE type_)
{
  /* Given a right_ type, return a randomly selected previously seen left_ node
     that share the same parent. If nothing has found, return NULL.
  */

  if (p_oracle->is_expr_types_in_where_clause(type_)) {
    // If the ir type matches any compatible query expression types,
    // use uniformly TypeExpr type.
    type_ = TypeExpr;
  }

  vector<IR*> current_ir_set;
  IR* current_ir_root;
  vector<pair<string*, int>>& all_matching_node = right_lib_set[type_];
  IR* return_matched_ir_node = NULL;

  if (all_matching_node.size() > 0) {
    /* Pick a random matching node from the library. */
    std::pair<string*, int>& selected_matched_node = all_matching_node[get_rand_int(all_matching_node.size())];
    string* p_current_query_str = selected_matched_node.first;
    int unique_node_id = selected_matched_node.second;

    /* Reconstruct the IR tree. */
    current_ir_set = parse_query_str_get_ir_set(*p_current_query_str);
    if (current_ir_set.size() <= 0)
      return NULL;
    current_ir_root = current_ir_set.back();

    /* Retrive the required node, deep copy it, clean up the IR tree and return.
     */
    IR* matched_ir_node = current_ir_set[unique_node_id];
    if (matched_ir_node != NULL) {
      if ((matched_ir_node->right_ == NULL || matched_ir_node->right_->type_ != type_) && type_ != TypeExpr) {
        //        ERROR::: Type not matched.
        current_ir_root->deep_drop();
        return NULL;
      }
      return_matched_ir_node = matched_ir_node->left_;
      current_ir_root->detach_node(return_matched_ir_node);
    }

    current_ir_root->deep_drop();

    if (return_matched_ir_node != NULL) {
      return return_matched_ir_node;
    }
  }

  return NULL;
}

IR* Mutator::get_ir_with_type(const IRTYPE type_)
{
  IR* new_ir = get_from_libary_with_type(type_);
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

bool Mutator::add_missing_create_table_stmt(IR* ir_root)
{
  /* Only accept ir_root as inputs. */
  if (ir_root->get_ir_type() != TypeRoot) {
    return false;
  }

  // Get Create Stmt. For the beginning.
  p_oracle->ir_wrapper.set_ir_root(ir_root);
  IR* new_stmt_ir = this->get_ir_with_type(TypeCreateTableStmt);
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
  IR* new_stmt_ir_2 = this->get_ir_with_type(TypeInsertStmt);
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
  IR* new_stmt_ir_3 = this->get_ir_with_type(TypeCreateIndexStmt);
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
  p_oracle->ir_wrapper.append_stmt_at_idx(new_stmt_ir_2, 0);
  p_oracle->ir_wrapper.append_stmt_at_idx(new_stmt_ir_3, 0);

  // Get Create Stmt, for the end.
  p_oracle->ir_wrapper.set_ir_root(ir_root);
  new_stmt_ir = this->get_ir_with_type(TypeCreateTableStmt);
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
  new_stmt_ir_2 = this->get_ir_with_type(TypeInsertStmt);
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
  new_stmt_ir_3 = this->get_ir_with_type(TypeCreateIndexStmt);
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

IR* Mutator::constr_rand_set_stmt()
{
  // Construct one SET statement as string,
  //  and then embed the string into one IR.
  // Return the embedded IR.

  if (this->all_saved_set_session.size() == 0 || this->set_session_lib.size() == 0) {
    cerr << "Error: The all_save_set_session or set_session_lib failed to init "
            "before used. \n\n\n Abort();\n\n\n";
    abort();
  }

  string rand_chosen_var = vector_rand_ele(this->all_saved_set_session);
  DataAffinity cur_data_affi = this->set_session_lib[rand_chosen_var];

  string params_str = cur_data_affi.get_mutated_literal();

  string connector = get_rand_int(2) ? " = " : " TO ";
  string ret_str = "SET SESSION " + rand_chosen_var + connector + params_str;

  IR* ret_ir = new IR(TypeSetStmt, ret_str, DataNone, ContextNoModi, AFFIUNKNOWN);
  ret_ir = new IR(TypeStmt, OP3("", "; ", ""), ret_ir, NULL);

  return ret_ir;
}

//IR *Mutator::constr_rand_storage_param(int param_num) {
//  // Construct one SET statement as string,
//  //  and then embed the string into one IR.
//  // Return the embedded IR.
//
//  if (param_num < 1) {
//    cerr << "\n\n\n Logic Error: Inside constr_rand_storage_param. ";
//  }
//
//  if (this->all_storage_param.size() == 0 ||
//      this->storage_param_lib.size() == 0) {
//    cerr << "Error: The all_storage_param or storage_param_lib failed to init "
//            "before used. \n\n\n Abort();\n\n\n";
//    abort();
//  }
//
//  string ret_str = "";
//  for (int idx = 0; idx != param_num; idx++) {
//
//    string rand_chosen_var = vector_rand_ele(this->all_storage_param);
//    DataAffinity cur_data_affi = this->storage_param_lib[rand_chosen_var];
//
//    string params_str = cur_data_affi.get_mutated_literal();
//
//    if (idx > 0) {
//      ret_str += ", ";
//    }
//
//    ret_str += rand_chosen_var + " = " + params_str;
//  };
//
//  IR *ret_ir =
//      new IR(TypeStorageParams, ret_str, DataNone, ContextNoModi, AFFIUNKNOWN);
//
//  return ret_ir;
//}

IR* Mutator::constr_rand_func_with_affinity(DATAAFFINITYTYPE in_affi,
    bool is_debug_info)
{

  string cur_func_name = "";
  string func_name_ret_str = "";
  string arg_names_ret_str = "";
  if (in_affi == AFFIANY || in_affi == AFFIUNKNOWN) {
    cur_func_name = vector_rand_ele(this->all_saved_func_name);
    if (is_debug_info) {
      cerr << "\n\n\nDependency: Fixing functions with "
           << get_string_by_affinity_type(in_affi)
           << "\nGetting func name: " << cur_func_name << "\n\n\n";
    }
  } else if (this->func_type_lib.count(in_affi) > 0) {
    cur_func_name = vector_rand_ele(func_type_lib[in_affi]);
    if (is_debug_info) {
      cerr << "\n\n\nDependency: Fixing functions with "
           << get_string_by_affinity_type(in_affi)
           << "\nGetting func name: " << cur_func_name << "\n\n\n";
    }
  } else {
    cur_func_name = vector_rand_ele(this->all_saved_func_name);
    if (is_debug_info) {
      cerr << "\n\n\nError: Cannot find affinity type in_affi, "
           << get_string_by_affinity_type(in_affi)
           << "\nGetting func name: " << cur_func_name << "\n\n\n";
    }
  }

  func_name_ret_str = cur_func_name;
  //  arg_names_ret_str = "(";

  // Randomly choose a set of arguments.
  vector<DataAffinity> v_func_affi = vector_rand_ele(func_str_to_type_map[cur_func_name]);

  int arg_idx = -1;
  //  cerr << "\n\n\nDEBUG:: For function name: " << cur_func_name << ", getting
  //  arg size: " << v_func_affi.size() << "\n\n\n";
  for (DataAffinity& cur_arg_affi : v_func_affi) {
    arg_idx++;
    // The first arg is the function returned type.
    if (arg_idx == 0) {
      continue;
    }
    if (arg_idx > 1) {
      arg_names_ret_str += ", ";
    }

    string cur_col_str;
    if (this->m_datatype2column.count(cur_arg_affi.get_data_affinity())) {
      // Use the data column that match the affinity.
      cur_col_str = vector_rand_ele(
          this->m_datatype2column[cur_arg_affi.get_data_affinity()]);
    }

    bool is_col_used_ok = false;
    for (string used_table_name : v_table_names_single) {
      vector<string> cur_col_vec = m_table2columns[used_table_name];
      if (find_vector(cur_col_vec, cur_col_str)) {
        is_col_used_ok = true;
        break;
      }
    }

    // Check whether the referenced column name has been used in this table
    // before or not.
    //    if (find_vector(v_column_names_single, cur_col_str) &&
    //    get_rand_int(3)) {
    //        arg_names_ret_str += cur_col_str;
    //    }
    if (is_col_used_ok && get_rand_int(3)) {
      arg_names_ret_str += cur_col_str;
      if (is_debug_info) {
        cerr << "\n\n\nDependency: Getting good to use cur_col_str: "
             << cur_col_str << "\n\n\n";
      }
    } else {
      // Use literal that match the affinity type.
      string cur_arg_str = cur_arg_affi.get_mutated_literal();
      arg_names_ret_str += cur_arg_str;
      if (is_debug_info) {
        cerr << "\n\n\nDependency: cur_col_str is not referenced before, do "
                "not use column names, "
                "use literal instead: "
             << cur_arg_str << "\n\n\n";
      }
    }
  }

  IR* ret_IR = new IR(TypeIdentifier, func_name_ret_str, DataFunctionName, ContextUse);
  ret_IR->set_is_instantiated(true);
  IR* arg_IR = new IR(TypeUnknown, arg_names_ret_str, DataUnknownType, ContextUndefine);
  arg_IR->set_is_instantiated(true);
  ret_IR = new IR(TypeFuncCallExpr, OP3("", "(", ")"), ret_IR, arg_IR);
  ret_IR->set_is_instantiated(true);
  //  ret_IR->set_data_flag(ContextNoModi);

  return ret_IR;
}

void Mutator::fix_literal_op_err(IR* cur_stmt_root, string res_str,
    bool is_debug_info)
{

  /* Fix type mismatched problems from the operators.
   * This function only handles the error when comparing two literals.
   * */

  // Give up the fixing algorithm in the TiDB implementation for now.
  return;
  //
  //  vector<IR *> ir_to_deep_drop;
  //
  //  // Case 1:
  //  // SELECT COUNT( *), SUM( x), REGR_SXX( x, type_op6), SUM( x), REGR_SYY( x,
  //  // x), REGR_SXY( x, x) FROM v0 WHERE c1 IN (true, true, false, true, false);
  //  // pq: unsupported comparison operator: c1 IN (true, true, false, true,
  //  // false): expected true to be of type timestamp, found type bool
  //
  //  if (findStringIn(res_str, "unsupported comparison operator: ") &&
  //      findStringIn(res_str, "expected") &&
  //      findStringIn(res_str, "to be of type") &&
  //      findStringIn(res_str, "found type ")) {
  //
  //    if (is_debug_info) {
  //      cerr << "\n\n\nDEBUG::Matching rule unsupported comparison operator: "
  //              "\n\n\n";
  //    }
  //
  //    string str_literal = "";
  //    string str_target_type = "";
  //    vector<string> v_tmp_split;
  //
  //    // Get the troublesome variable.
  //    v_tmp_split = string_splitter(res_str, ": expected ");
  //    if (v_tmp_split.size() <= 1) {
  //      cerr << "\n\n\nERROR: Cannot find : expected in the string. \n\n\n";
  //      return;
  //    }
  //    str_literal = v_tmp_split.at(1);
  //
  //    v_tmp_split = string_splitter(str_literal, " to be of type ");
  //    if (v_tmp_split.size() <= 1) {
  //      cerr << "\n\n\nERROR: Cannot find to be of type in the string. \n\n\n";
  //      return;
  //    }
  //    str_literal = v_tmp_split.at(0);
  //
  //    // Get the target type name.
  //    v_tmp_split = string_splitter(res_str, " to be of type ");
  //    if (v_tmp_split.size() <= 1) {
  //      cerr << "\n\n\nERROR: Cannot find : expected in the string. \n\n\n";
  //      return;
  //    }
  //    str_target_type = v_tmp_split.at(1);
  //
  //    v_tmp_split = string_splitter(str_target_type, ", ");
  //    if (v_tmp_split.size() <= 1) {
  //      cerr << "\n\n\nERROR: Cannot find to be of type in the string. \n\n\n";
  //      return;
  //    }
  //    str_target_type = v_tmp_split.at(0);
  //
  //    DataAffinity fix_affi = get_data_affinity_by_string(str_target_type);
  //    uint64_t fix_affi_hash = fix_affi.calc_hash();
  //
  //    // Find all the matching literals.
  //    vector<IR *> v_matched_node =
  //        p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(
  //            cur_stmt_root, str_literal, false, true);
  //    for (IR *cur_matched_node : v_matched_node) {
  //
  //      bool is_skip = false;
  //      for (auto cur_drop : ir_to_deep_drop) {
  //        if (p_oracle->ir_wrapper.is_ir_in(cur_matched_node, cur_drop)) {
  //          is_skip = true;
  //          break;
  //        }
  //      }
  //      if (is_skip) {
  //        continue;
  //      }
  //
  //      if (is_debug_info) {
  //        cerr << "\n\n\nDEBUG:: Matching node: "
  //             << cur_matched_node->to_string();
  //      }
  //
  //      //            cerr << "\n\n\naffi_library size: " <<
  //      //            this->data_affi_set.size() << "\n"; cerr << "\nGetting
  //      //            current need to match type: " <<
  //      //            get_string_by_affinity_type(fix_affi.get_data_affinity())
  //      //                << "\n\n\n";
  //
  //      IR *new_node = NULL;
  //      if (this->data_affi_set.count(fix_affi_hash) != 0 &&
  //          this->data_affi_set.at(fix_affi_hash).size() != 0 &&
  //          get_rand_int(10) < 9) {
  //        //                pair<string*, int> cur_chosen_pair =
  //        //                    vector_rand_ele(this->data_affi_set[fix_affi_hash]);
  //        //                new_node =
  //        //                this->get_ir_node_from_data_affi_pair(cur_chosen_pair);
  //        new_node =
  //            vector_rand_ele(this->data_affi_set[fix_affi_hash])->deep_copy();
  //
  //        if (is_debug_info && new_node != NULL) {
  //          cerr << "\nDEBUG:: From data affinity library, "
  //               << get_string_by_affinity_type(fix_affi.get_data_affinity())
  //               << " getting " << new_node->to_string() << "\n\n\n";
  //        }
  //      } else {
  //        //                cerr << "Does not match successfully. \n";
  //        //                cerr << "res_str: " << res_str << "\n\n\n";
  //        new_node = new IR(TypeStringLiteral, OP0());
  //        new_node->set_is_instantiated(true);
  //        new_node->mutate_literal(fix_affi);
  //      }
  //
  //      if (new_node != NULL) {
  //        cur_stmt_root->swap_node(cur_matched_node, new_node);
  //        ir_to_deep_drop.push_back(cur_matched_node);
  //
  //        this->instan_replaced_node(cur_stmt_root, new_node, is_debug_info);
  //
  //        if (is_debug_info) {
  //          cerr << ", mutated to node: " << cur_stmt_root->to_string()
  //               << "\n\n\n";
  //        }
  //      } else {
  //        if (is_debug_info) {
  //          cerr << ", failed to mutate because new_node is NULL. \n\n\n ";
  //        }
  //      }
  //    }
  //
  //    for (auto cur_drop : ir_to_deep_drop) {
  //      cur_drop->deep_drop();
  //    }
  //
  //    return;
  //
  //  }
  //
  //  else if (findStringIn(res_str, "parsing as type ") &&
  //           findStringIn(res_str, "could not parse")) {
  //
  //    if (is_debug_info) {
  //      cerr << "\n\n\nDEBUG:: Using rule could not parse and parsing as type in "
  //              "the "
  //              "fix_literal_op_err \n\n\n";
  //    }
  //
  //    //        pq: unsupported comparison operator: c4 = ANY ARRAY['2ci10p4',
  //    //        '09-10-66 BC 11:15:40.8179-2', '05-19-81 BC 03:33:31.6577+2',
  //    //        '05-08-4034 BC 06:58:13-5', '05-1 0-3656 14:14:21-3']: parsing as
  //    //        type timestamp: could not parse "2ci10p4"
  //
  //    vector<IR *> ir_to_deep_drop;
  //
  //    string str_literal = "";
  //    string str_target_type = "";
  //    vector<string> v_tmp_split;
  //
  //    // Get the troublesome variable.
  //    v_tmp_split = string_splitter(res_str, "could not parse ");
  //    if (v_tmp_split.size() <= 1) {
  //      cerr << "\n\n\nERROR: Cannot find could not parse  in the string. \n\n\n";
  //      return;
  //    }
  //    str_literal = v_tmp_split.at(1);
  //
  //    // Remove the "" symbol.
  //    if (str_literal.size() > 0 && str_literal[0] == '"') {
  //      str_literal = str_literal.substr(1, str_literal.size() - 1);
  //    }
  //    if (str_literal.size() > 0 && str_literal[str_literal.size() - 1] == '\n') {
  //      str_literal = str_literal.substr(0, str_literal.size() - 1);
  //    }
  //    if (str_literal.size() > 0 && str_literal[str_literal.size() - 1] == '"') {
  //      str_literal = str_literal.substr(0, str_literal.size() - 1);
  //    }
  //
  //    // Get the target type name.
  //    v_tmp_split = string_splitter(res_str, "parsing as type ");
  //    if (v_tmp_split.size() <= 1) {
  //      cerr << "\n\n\nERROR: Cannot find parsing as type  in the string. \n\n\n";
  //      return;
  //    }
  //    str_target_type = v_tmp_split.at(1);
  //
  //    v_tmp_split = string_splitter(str_target_type, ":");
  //    if (v_tmp_split.size() <= 1) {
  //      cerr << "\n\n\nERROR: Cannot find : in the string," << str_target_type
  //           << "\n\n\n";
  //      return;
  //    }
  //
  //    if (is_debug_info) {
  //      cerr << "\n\n\nGetting str_target_type: " << str_target_type
  //           << "\nstr_literal: " << str_literal << "\n\n\n";
  //    }
  //
  //    str_target_type = v_tmp_split.at(0);
  //
  //    DataAffinity fix_affi = get_data_affinity_by_string(str_target_type);
  //
  //    // Find all the matching literals.
  //    vector<IR *> v_matched_node =
  //        p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(
  //            cur_stmt_root, str_literal, false, true);
  //
  //    if (v_matched_node.size() == 0) {
  //      v_matched_node = p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(
  //          cur_stmt_root, "'" + str_literal + "'", false, true);
  //    }
  //
  //    for (auto cur_match_node : v_matched_node) {
  //      bool is_skip = false;
  //      for (IR *cur_drop : ir_to_deep_drop) {
  //        if (p_oracle->ir_wrapper.is_ir_in(cur_match_node, cur_drop)) {
  //          is_skip = true;
  //          break;
  //        }
  //      }
  //      if (is_skip) {
  //        continue;
  //      }
  //
  //      IR *newLiteralNode = new IR(TypeUnknown, OP0());
  //      newLiteralNode->set_is_instantiated(true);
  //
  //      uint64_t fix_affi_hash = fix_affi.calc_hash();
  //
  //      if (this->data_affi_set.count(fix_affi_hash) != 0 &&
  //          this->data_affi_set.at(fix_affi_hash).size() != 0 &&
  //          get_rand_int(11) < 9) {
  //        newLiteralNode->deep_drop();
  //        newLiteralNode =
  //            vector_rand_ele(this->data_affi_set[fix_affi_hash])->deep_copy();
  //
  //        if (is_debug_info && newLiteralNode != NULL) {
  //          cerr << "\nDEBUG:: From data affinity library, "
  //               << get_string_by_affinity_type(fix_affi.get_data_affinity())
  //               << " getting " << newLiteralNode->to_string() << "\n\n\n";
  //        }
  //      } else {
  //        newLiteralNode->mutate_literal(fix_affi);
  //      }
  //
  //      cur_stmt_root->swap_node(cur_match_node, newLiteralNode);
  //      ir_to_deep_drop.push_back(cur_match_node);
  //    }
  //
  //    for (auto ir_drop : ir_to_deep_drop) {
  //      ir_drop->deep_drop();
  //    }
  //
  //  }
  //
  //  else if (findStringIn(res_str, "could not parse ") &&
  //           findStringIn(res_str, "as ")) {
  //    // Sample:
  //    // pq: could not parse "jsmx" as inet. invalid IP
  //
  //    if (is_debug_info) {
  //      cerr << "\n\n\nDEBUG:: Using rule could not parse and as in the "
  //              "fix_literal_op_err \n\n\n";
  //    }
  //
  //    vector<IR *> ir_to_deep_drop;
  //
  //    string str_literal = "";
  //    string str_target_type = "";
  //    vector<string> v_tmp_split;
  //
  //    // Get the troublesome variable.
  //    v_tmp_split = string_splitter(res_str, "could not parse ");
  //    if (v_tmp_split.size() <= 1) {
  //      cerr << "\n\n\nERROR: Cannot find could not parse  in the string. \n\n\n";
  //      return;
  //    }
  //    str_literal = v_tmp_split.at(1);
  //
  //    v_tmp_split = string_splitter(str_literal, " ");
  //
  //    if (v_tmp_split.size() <= 1) {
  //      cerr << "\n\n\nERROR: Cannot find space when retrieving the str_literal "
  //              "in the string. \n\n\n";
  //      return;
  //    }
  //
  //    str_literal = v_tmp_split.at(0);
  //
  //    // Remove the "" symbol.
  //    if (str_literal.size() > 0 && str_literal[0] == '"') {
  //      str_literal = str_literal.substr(1, str_literal.size() - 1);
  //    }
  //    if (str_literal.size() > 0 && str_literal[str_literal.size() - 1] == '\n' ||
  //        str_literal[str_literal.size() - 1] == ' ') {
  //      str_literal = str_literal.substr(0, str_literal.size() - 1);
  //    }
  //    if (str_literal.size() > 0 && str_literal[str_literal.size() - 1] == '"') {
  //      str_literal = str_literal.substr(0, str_literal.size() - 1);
  //    }
  //
  //    // Get the target type name.
  //    v_tmp_split = string_splitter(res_str, "as ");
  //    if (v_tmp_split.size() <= 1) {
  //      cerr << "\n\n\nERROR: Cannot find as (type)  in the string. \n\n\n";
  //      return;
  //    }
  //    str_target_type = v_tmp_split.at(1);
  //
  //    v_tmp_split = string_splitter(str_target_type, ".");
  //    if (v_tmp_split.size() <= 1) {
  //      if (is_debug_info) {
  //        cerr << "\n\n\nERROR: Cannot find . in the string," << str_target_type
  //             << "\n\n\n";
  //      }
  //    } else {
  //      str_target_type = v_tmp_split.at(0);
  //    }
  //    v_tmp_split = string_splitter(str_target_type, ":");
  //    if (v_tmp_split.size() <= 1) {
  //      if (is_debug_info) {
  //        cerr << "\n\n\nERROR: Cannot find : in the string," << str_target_type
  //             << "\n\n\n";
  //      }
  //    } else {
  //      str_target_type = v_tmp_split.at(0);
  //    }
  //    v_tmp_split = string_splitter(str_target_type, "type ");
  //    if (v_tmp_split.size() <= 1) {
  //      if (is_debug_info) {
  //        cerr << "\n\n\nERROR: Cannot find type in the string,"
  //             << str_target_type << "\n\n\n";
  //      }
  //    } else {
  //      str_target_type = v_tmp_split.at(1);
  //    }
  //
  //    if (is_debug_info) {
  //      cerr << "\n\n\nDEBUG: getting str_target_type: " << str_target_type
  //           << ", getting target literal: " << str_literal << ".\n\n\n";
  //    }
  //
  //    DataAffinity fix_affi = get_data_affinity_by_string(str_target_type);
  //
  //    // Find all the matching literals.
  //    vector<IR *> v_matched_node =
  //        p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(
  //            cur_stmt_root, str_literal, false, true);
  //
  //    if (v_matched_node.size() == 0) {
  //      v_matched_node = p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(
  //          cur_stmt_root, "'" + str_literal + "'", false, true);
  //    }
  //
  //    for (auto cur_match_node : v_matched_node) {
  //      bool is_skip = false;
  //      for (IR *cur_drop : ir_to_deep_drop) {
  //        if (p_oracle->ir_wrapper.is_ir_in(cur_match_node, cur_drop)) {
  //          is_skip = true;
  //          break;
  //        }
  //      }
  //      if (is_skip) {
  //        continue;
  //      }
  //
  //      IR *newLiteralNode = new IR(TypeUnknown, OP0());
  //      newLiteralNode->set_is_instantiated(true);
  //
  //      uint64_t fix_affi_hash = fix_affi.calc_hash();
  //
  //      if (this->data_affi_set.count(fix_affi_hash) != 0 &&
  //          this->data_affi_set.at(fix_affi_hash).size() != 0 &&
  //          get_rand_int(11) < 9) {
  //        newLiteralNode->deep_drop();
  //        newLiteralNode =
  //            vector_rand_ele(this->data_affi_set[fix_affi_hash])->deep_copy();
  //
  //        if (is_debug_info && newLiteralNode != NULL) {
  //          cerr << "\nDEBUG:: From data affinity library, "
  //               << get_string_by_affinity_type(fix_affi.get_data_affinity())
  //               << " getting " << newLiteralNode->to_string() << "\n\n\n";
  //        }
  //      } else {
  //        newLiteralNode->mutate_literal(fix_affi);
  //      }
  //
  //      cur_stmt_root->swap_node(cur_match_node, newLiteralNode);
  //      ir_to_deep_drop.push_back(cur_match_node);
  //    }
  //
  //    for (auto ir_drop : ir_to_deep_drop) {
  //      ir_drop->deep_drop();
  //    }
  //
  //  }
  //
  //  else if (findStringIn(res_str, "unsupported comparison operator: ")) {
  //    /*
  //     * Type mismatched when comparing between two literals.
  //     * SELECT COUNT( *) FROM v0 WHERE v0.c5 = B'010' AND v0.c3 = B'10001111101';
  //     *   pq: unsupported comparison operator: <decimal> = <varbit>
  //     * */
  //
  //    if (is_debug_info) {
  //      cerr << "Inside the unsupported comparison operator: other types. \n\n\n";
  //    }
  //
  //    // Get which binary operator is causing the problem. Only fixing the
  //    // matching one.
  //
  //    vector<string> v_tmp_str;
  //    v_tmp_str = string_splitter(res_str, "> ");
  //    if (v_tmp_str.size() < 2) {
  //      return;
  //    }
  //    string str_operator = v_tmp_str[1];
  //    v_tmp_str = string_splitter(str_operator, " <");
  //    if (v_tmp_str.size() < 2) {
  //      return;
  //    }
  //    str_operator = v_tmp_str.front();
  //    if (is_debug_info) {
  //      cerr << "DEBUG:: in unsupported comparison operator: Getting "
  //              "str_operator: "
  //           << str_operator << "\n\n\n";
  //    }
  //
  //    vector<Binary_Operator> tmp_bin_oper =
  //        p_oracle->get_operator_supported_types(str_operator);
  //
  //    vector<IR *> ir_to_deep_drop;
  //
  //    vector<IR *> v_binary_operator =
  //        p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(
  //            cur_stmt_root, TypeBinExprFmtWithParen, false, true);
  //    for (IR *cur_binary_operator : v_binary_operator) {
  //
  //      bool is_skip = false;
  //      for (auto ir_drop : ir_to_deep_drop) {
  //        if (p_oracle->ir_wrapper.is_ir_in(cur_binary_operator, ir_drop)) {
  //          is_skip = true;
  //          break;
  //        }
  //      }
  //
  //      if (is_skip) {
  //        continue;
  //      }
  //
  //      string cur_binary_opt_str = cur_binary_operator->get_middle();
  //      trim_string(cur_binary_opt_str);
  //      if (cur_binary_opt_str != str_operator) {
  //        if (is_debug_info) {
  //          cerr << "\n\n\nSkip operator: " << cur_binary_operator->get_middle()
  //               << " because it is not matched with: " << str_operator
  //               << "\n\n\n";
  //        }
  //        is_skip = true;
  //      } else {
  //        if (is_debug_info) {
  //          cerr << "\n\n\n Matching operator: "
  //               << cur_binary_operator->get_middle()
  //               << " and it is matched with: " << str_operator << "\n\n\n";
  //        }
  //      }
  //
  //      if (is_skip) {
  //        continue;
  //      }
  //
  //      if (cur_binary_operator->get_middle() == " LIKE ") {
  //        /*
  //         * SELECT COUNT( *) FROM v0 WHERE c1 LIKE true;
  //         * pq: unsupported comparison operator: <bool> LIKE <bool>
  //         * For LIKE operator, both sides should be STRING types
  //         */
  //        if (is_debug_info) {
  //          cerr << "\n\n\nDEBUG:: Getting the LIKE error fixing. ";
  //        }
  //
  //        IR *new_left_node = new IR(TypeUnknown, OP0(), NULL, NULL);
  //        new_left_node->set_is_instantiated(true);
  //
  //        DataAffinity fix_affi(AFFISTRING);
  //        uint64_t fix_affi_hash = fix_affi.calc_hash();
  //        if (this->data_affi_set.count(fix_affi_hash) != 0 &&
  //            this->data_affi_set.at(fix_affi_hash).size() != 0 &&
  //            get_rand_int(3)) {
  //          new_left_node->deep_drop();
  //          new_left_node =
  //              vector_rand_ele(this->data_affi_set[fix_affi_hash])->deep_copy();
  //
  //          if (is_debug_info && new_left_node != NULL) {
  //            cerr << "\nDEBUG:: From data affinity library, "
  //                 << get_string_by_affinity_type(fix_affi.get_data_affinity())
  //                 << " getting " << new_left_node->to_string() << "\n\n\n";
  //          }
  //        } else if (m_datatype2column.count(AFFISTRING) > 0) {
  //          string col_str = vector_rand_ele(m_datatype2column[AFFISTRING]);
  //          new_left_node->set_str_val(col_str);
  //        } else {
  //          new_left_node->mutate_literal(AFFISTRING);
  //        }
  //
  //        IR *new_right_node = new IR(TypeUnknown, OP0(), NULL, NULL);
  //        ;
  //        new_right_node->set_is_instantiated(true);
  //        if (this->data_affi_set.count(fix_affi_hash) != 0 &&
  //            this->data_affi_set.at(fix_affi_hash).size() != 0 &&
  //            get_rand_int(3)) {
  //          new_right_node->deep_drop();
  //          new_right_node =
  //              vector_rand_ele(this->data_affi_set[fix_affi_hash])->deep_copy();
  //
  //          if (is_debug_info && new_right_node != NULL) {
  //            cerr << "\nDEBUG:: From data affinity library, "
  //                 << get_string_by_affinity_type(fix_affi.get_data_affinity())
  //                 << " getting " << new_right_node->to_string() << "\n\n\n";
  //          }
  //        } else if (m_datatype2column.count(AFFISTRING) > 0) {
  //          string col_str = vector_rand_ele(m_datatype2column[AFFISTRING]);
  //          new_right_node->set_str_val(col_str);
  //        } else {
  //          new_right_node->mutate_literal(AFFISTRING);
  //        }
  //
  //        // Replacing the old nodes.
  //        IR *old_left_node = cur_binary_operator->get_left();
  //        IR *old_right_node = cur_binary_operator->get_right();
  //
  //        cur_binary_operator->update_left(new_left_node);
  //        cur_binary_operator->update_right(new_right_node);
  //
  //        ir_to_deep_drop.push_back(old_left_node);
  //        ir_to_deep_drop.push_back(old_right_node);
  //
  //        if (is_debug_info) {
  //          cerr << "\n\n\nDEBUG::Mutated the unsupported LIKE comparison to "
  //               << cur_binary_operator->to_string() << "\n\n\n";
  //        }
  //
  //      }
  //
  //      else if (tmp_bin_oper.size() != 0) {
  //
  //        if (is_debug_info) {
  //          cerr << "\n\n\nDEBUG: Trying to use the saved operator types "
  //                  "to fix the semantic error problem. \n\n\n";
  //        }
  //
  //        // Get left type and right type from the binary operations.
  //        string left_type_str, right_type_str;
  //
  //        v_tmp_str = string_splitter(res_str, " <");
  //        if (v_tmp_str.size() < 3) {
  //          return;
  //        }
  //        left_type_str = v_tmp_str[1];
  //        right_type_str = v_tmp_str[2];
  //
  //        v_tmp_str = string_splitter(left_type_str, "> ");
  //        if (v_tmp_str.size() < 2) {
  //          return;
  //        }
  //        left_type_str = v_tmp_str[0];
  //
  //        v_tmp_str = string_splitter(right_type_str, ">");
  //        if (v_tmp_str.size() < 2) {
  //          return;
  //        }
  //        right_type_str = v_tmp_str[0];
  //
  //        DATAAFFINITYTYPE
  //        left_type =
  //            get_data_affinity_by_string(left_type_str).get_data_affinity(),
  //        right_type =
  //            get_data_affinity_by_string(right_type_str).get_data_affinity();
  //
  //        if (is_debug_info) {
  //          cerr << "\n\n\nDEBUG:: Getting binary operator left type: "
  //               << get_string_by_affinity_type(left_type)
  //               << " and right type: " << get_string_by_affinity_type(right_type)
  //               << "\n\n\n";
  //        }
  //
  //        vector<Binary_Operator> v_mat_left_types;
  //        for (auto tmp_bin_oper : tmp_bin_oper) {
  //          if (tmp_bin_oper.left == left_type) {
  //            v_mat_left_types.push_back(tmp_bin_oper);
  //          }
  //        }
  //
  //        DATAAFFINITYTYPE new_left_type;
  //
  //        if (v_mat_left_types.size() == 0) {
  //          // The left expression should never be used in this context.
  //          Binary_Operator tmp_choosen_types = vector_rand_ele(tmp_bin_oper);
  //          v_mat_left_types.push_back(tmp_choosen_types);
  //
  //          new_left_type = tmp_choosen_types.left;
  //
  //          DataAffinity tmp_data_affi(new_left_type);
  //          uint64_t tmp_hash = tmp_data_affi.calc_hash();
  //          if (data_affi_set.count(tmp_hash) != 0 &&
  //              data_affi_set[tmp_hash].size() != 0) {
  //            IR *new_left_node =
  //                vector_rand_ele(data_affi_set[tmp_hash])->deep_copy();
  //            IR *ori_left_node = cur_binary_operator->get_left();
  //            cur_binary_operator->update_left(new_left_node);
  //            ir_to_deep_drop.push_back(ori_left_node);
  //          } else {
  //            IR *new_left_node = new IR(TypeStringLiteral, string(""));
  //            new_left_node->mutate_literal(new_left_type);
  //            IR *ori_left_node = cur_binary_operator->get_left();
  //            cur_binary_operator->update_left(new_left_node);
  //            ir_to_deep_drop.push_back(ori_left_node);
  //          }
  //        } else {
  //          new_left_type = left_type;
  //        }
  //
  //        if (v_mat_left_types.size() == 0) {
  //          return;
  //        }
  //
  //        DATAAFFINITYTYPE new_right_type =
  //            vector_rand_ele(v_mat_left_types).right;
  //        DataAffinity tmp_data_affi(new_right_type);
  //        uint64_t tmp_hash = tmp_data_affi.calc_hash();
  //        if (data_affi_set.count(tmp_hash) != 0 &&
  //            data_affi_set[tmp_hash].size() != 0) {
  //          IR *new_right_node =
  //              vector_rand_ele(data_affi_set[tmp_hash])->deep_copy();
  //          IR *ori_right_node = cur_binary_operator->get_right();
  //          cur_binary_operator->update_right(new_right_node);
  //          ir_to_deep_drop.push_back(ori_right_node);
  //        } else {
  //          IR *new_right_node = new IR(TypeStringLiteral, string(""));
  //          new_right_node->mutate_literal(new_right_type);
  //          IR *ori_right_node = cur_binary_operator->get_right();
  //          cur_binary_operator->update_right(new_right_node);
  //          ir_to_deep_drop.push_back(ori_right_node);
  //        }
  //
  //        if (is_debug_info) {
  //          cerr << "For operator: " << str_operator << "\nfixing the left type: "
  //               << get_string_by_affinity_type(new_left_type)
  //               << "\n right type: "
  //               << get_string_by_affinity_type(new_right_type)
  //               << "\n new operator: " << cur_binary_operator->to_string()
  //               << "\n ori res_str: " << res_str << "\n\n\n";
  //        }
  //
  //      }
  //
  //      else {
  //        // TODO:: Not accurate any more.
  //        /*
  //         * If it is other types of comparison, follow the types from the left
  //         * side. select * FROM v0 where 123 < 'abc'; ERROR: unsupported
  //         * comparison operator: <int> < <string>
  //         */
  //
  //        /*
  //         * This rule also matches the two sides column comparisons.
  //         * select * from v0 where c1 > c2;
  //         * ERROR: unsupported comparison operator: <int> > <string>
  //         * */
  //
  //        if (is_debug_info) {
  //          cerr << "\n\n\nDEBUG:: Getting the other types (non-like) of the "
  //                  "comparison operator fixing. ";
  //        }
  //
  //        string str_target_type = "";
  //        vector<string> v_tmp_split;
  //
  //        // Get the troublesome variable.
  //        v_tmp_split = string_splitter(res_str, " operator: <");
  //        if (v_tmp_split.size() <= 1) {
  //          cerr << "\n\n\nERROR: Cannot find  operator: < in the string "
  //               << res_str << "\n\n\n";
  //          return;
  //        }
  //        str_target_type = v_tmp_split.at(1);
  //
  //        v_tmp_split = string_splitter(str_target_type, ">");
  //        if (v_tmp_split.size() <= 1) {
  //          cerr << "\n\n\nERROR: Cannot find > in the string: "
  //               << str_target_type << " \n\n\n";
  //          return;
  //        }
  //        str_target_type = v_tmp_split.at(0);
  //
  //        if (is_debug_info) {
  //          cerr << "\n\n\nGetting str_target_type: " << str_target_type
  //               << "\n\n\n";
  //        }
  //
  //        DataAffinity fix_affi = get_data_affinity_by_string(str_target_type);
  //        uint64_t fix_affi_hash = fix_affi.calc_hash();
  //
  //        //                cerr << "\n\n\naffi_library size: " <<
  //        //                this->data_affi_set.size() << "\n"; cerr << "\nGetting
  //        //                current need to match type: " <<
  //        //                get_string_by_affinity_type(fix_affi.get_data_affinity())
  //        //                     << "\n\n\n";
  //
  //        IR *new_node = NULL;
  //        if (this->data_affi_set.count(fix_affi_hash) != 0 &&
  //            this->data_affi_set.at(fix_affi_hash).size() != 0 &&
  //            get_rand_int(10) != 0) {
  //          //                    pair<string*, int> cur_chosen_pair =
  //          //                        vector_rand_ele(this->data_affi_set[fix_affi_hash]);
  //          //                    new_node =
  //          //                    this->get_ir_node_from_data_affi_pair(cur_chosen_pair);
  //          new_node =
  //              vector_rand_ele(this->data_affi_set[fix_affi_hash])->deep_copy();
  //
  //          if (is_debug_info && new_node != NULL) {
  //            cerr << "\nDEBUG:: From data affinity library, "
  //                 << get_string_by_affinity_type(fix_affi.get_data_affinity())
  //                 << " getting " << new_node->to_string() << "\n\n\n";
  //          }
  //        } else {
  //          new_node = new IR(TypeUnknown, OP0(), NULL, NULL);
  //          new_node->set_is_instantiated(true);
  //          new_node->mutate_literal(fix_affi);
  //        }
  //
  //        if (new_node != NULL) {
  //          IR *old_right_node = cur_binary_operator->get_right();
  //          cur_binary_operator->update_right(new_node);
  //          if (old_right_node != NULL) {
  //            ir_to_deep_drop.push_back(old_right_node);
  //          }
  //
  //          this->instan_replaced_node(cur_stmt_root, new_node, is_debug_info);
  //
  //          if (is_debug_info) {
  //            cerr << "\n\n\nDEBUG::Mutated the unsupported comparison to "
  //                 << cur_binary_operator->to_string() << "\n\n\n";
  //          }
  //        } else {
  //          if (is_debug_info) {
  //            cerr << ", failed to mutate because new_node is NULL. \n\n\n ";
  //          }
  //        }
  //      }
  //    }
  //
  //    for (auto ir_drop : ir_to_deep_drop) {
  //      ir_drop->deep_drop();
  //    }
  //  }
  //
  return;
}

void Mutator::fix_column_literal_op_err(IR* cur_stmt_root, string res_str,
    bool is_debug_info)
{
  /*
   * Fix the error when comparing columns to mismatched string literals.
   */

  // Give up the fixing algorithm in the TiDB implementation for now.
  return;
  //
  //  if (
  //      // Could be pq: could not parse or ERROR: could not parse
  //      findStringIn(res_str, "could not parse ") &&
  //      findStringIn(res_str, " as type ")) {
  //    // SELECT * FROM v0 WHERE c1 > 'abc';
  //    // ERROR: could not parse "abc" as type int: strconv.ParseInt: parsing
  //    // "abc": invalid syntax
  //
  //    vector<IR *> ir_to_deep_drop;
  //
  //    if (is_debug_info) {
  //      cerr << "\n\n\nDEBUG:: Inside the ERROR: could not parse literal as type "
  //              "TYPE \n\n\n";
  //    }
  //
  //    string str_literal = "";
  //    string str_target_type = "";
  //    vector<string> v_tmp_split;
  //
  //    // Get the troublesome variable.
  //    v_tmp_split = string_splitter(res_str, "could not parse ");
  //    if (v_tmp_split.size() <= 1) {
  //      cerr << "\n\n\nERROR: Cannot find ERROR: could not parse  in the string. "
  //              "\n\n\n";
  //      return;
  //    }
  //    str_literal = v_tmp_split.at(1);
  //
  //    v_tmp_split = string_splitter(str_literal, " as type ");
  //    if (v_tmp_split.size() <= 1) {
  //      cerr << "\n\n\nERROR: Cannot find as type in the string. \n\n\n";
  //      return;
  //    }
  //    str_literal = v_tmp_split.at(0);
  //    if (findStringIn(str_literal, "\"")) {
  //      str_literal = "'" + str_literal.substr(1, str_literal.size() - 2) + "'";
  //    }
  //
  //    // Get the target type name.
  //    v_tmp_split = string_splitter(res_str, " as type ");
  //    if (v_tmp_split.size() <= 1) {
  //      cerr << "\n\n\nERROR: Cannot find : expected in the string. \n\n\n";
  //      return;
  //    }
  //    str_target_type = v_tmp_split.at(1);
  //
  //    v_tmp_split = string_splitter(str_target_type, ": ");
  //    if (v_tmp_split.size() <= 1) {
  //      cerr << "\n\n\nERROR: Cannot find to be of type in the string. \n\n\n";
  //      return;
  //    }
  //    str_target_type = v_tmp_split.at(0);
  //
  //    if (is_debug_info) {
  //      cerr << "\n\n\nGetting str_target_type: " << str_target_type
  //           << "\nstr_literal: " << str_literal << "\n\n\n";
  //    }
  //
  //    DataAffinity fix_affi = get_data_affinity_by_string(str_target_type);
  //
  //    if (is_debug_info) {
  //      cerr << "\n\n\nGetting parsed fix_affi: "
  //           << get_string_by_affinity_type(fix_affi.get_data_affinity())
  //           << "\n\n\n";
  //      vector<shared_ptr<DataAffinity>> tmp_debug_v =
  //          fix_affi.get_v_tuple_types();
  //      for (auto cur_debug : tmp_debug_v) {
  //        cerr << get_string_by_affinity_type(cur_debug->get_data_affinity())
  //             << ", ";
  //      }
  //      cerr << "end\n\n\n";
  //    }
  //
  //    vector<IR *> v_matched_nodes =
  //        p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(
  //            cur_stmt_root, str_literal, false, true);
  //    for (IR *cur_matched_node : v_matched_nodes) {
  //
  //      bool is_skip = false;
  //      for (auto cur_drop : ir_to_deep_drop) {
  //        if (p_oracle->ir_wrapper.is_ir_in(cur_matched_node, cur_drop)) {
  //          is_skip = true;
  //          break;
  //        }
  //      }
  //      if (is_skip) {
  //        continue;
  //      }
  //
  //      IR *new_matched_node = new IR(TypeUnknown, OP0());
  //
  //      new_matched_node->set_is_instantiated(true);
  //
  //      uint64_t fix_affi_hash = fix_affi.calc_hash();
  //
  //      if (this->data_affi_set.count(fix_affi_hash) != 0 &&
  //          this->data_affi_set.at(fix_affi_hash).size() != 0 &&
  //          get_rand_int(11) < 9) {
  //        new_matched_node->deep_drop();
  //        new_matched_node =
  //            vector_rand_ele(this->data_affi_set[fix_affi_hash])->deep_copy();
  //
  //        if (is_debug_info && new_matched_node != NULL) {
  //          cerr << "\nDEBUG:: From data affinity library, "
  //               << get_string_by_affinity_type(fix_affi.get_data_affinity())
  //               << " getting " << new_matched_node->to_string() << "\n\n\n";
  //        }
  //      } else {
  //        if (is_debug_info && new_matched_node != NULL) {
  //          cerr << "\nDEBUG:: using original mutate_literal."
  //               << "\n\n\n";
  //        }
  //        new_matched_node->mutate_literal(fix_affi);
  //      }
  //
  //      cur_stmt_root->swap_node(cur_matched_node, new_matched_node);
  //      ir_to_deep_drop.push_back(cur_matched_node);
  //
  //      if (is_debug_info) {
  //        cerr << "\n\n\nDEBUG::Mutated the literal to "
  //             << cur_matched_node->to_string() << "\n\n\n";
  //      }
  //    }
  //
  //    for (auto cur_drop : ir_to_deep_drop) {
  //      cur_drop->deep_drop();
  //    }
  //
  //    return;
  //  }
  //
  //  else if (findStringIn(res_str, "unsupported binary operator: ") &&
  //           findStringIn(res_str, "(desired ")) {
  //
  //    if (is_debug_info) {
  //      cerr << "\n\n\nDEBUG:: Inside the unsupported binary operator: (desired "
  //              "...)\n\n\n";
  //      cerr << "\n\n\nDEBUG:: ERROR message: " << res_str << "\n\n\n";
  //    }
  //
  //    vector<IR *> ir_to_deep_drop;
  //
  //    string str_target_type = "";
  //    string str_operator = "";
  //    vector<string> v_tmp_split;
  //
  //    // Get the target type name.
  //    v_tmp_split = string_splitter(res_str, "> ");
  //    if (v_tmp_split.size() <= 1) {
  //      cerr << "\n\n\nERROR: Cannot find > in the string. \n\n\n";
  //      return;
  //    }
  //    str_operator = "";
  //    for (int i = 1; i < v_tmp_split.size(); i++) {
  //      str_operator += v_tmp_split.at(i);
  //      if ((i + 1) < v_tmp_split.size()) {
  //        str_operator += "> ";
  //      }
  //    }
  //
  //    v_tmp_split = string_splitter(str_operator, " <");
  //    if (v_tmp_split.size() < 2) {
  //      cerr << "\n\n\nERROR: Cannot find < in the string. \n\n\n";
  //      return;
  //    }
  //    str_operator = v_tmp_split.at(v_tmp_split.size() - 3);
  //
  //    // Get the target type name.
  //    v_tmp_split = string_splitter(res_str, "(desired <");
  //    if (v_tmp_split.size() <= 1) {
  //      cerr << "\n\n\nERROR: Cannot find (desired < in the string. \n\n\n";
  //      return;
  //    }
  //    str_target_type = v_tmp_split.at(1);
  //
  //    v_tmp_split = string_splitter(str_target_type, ">)");
  //    if (v_tmp_split.size() <= 1) {
  //      cerr << "\n\n\nERROR: Cannot find >) in the string. \n\n\n";
  //      return;
  //    }
  //    str_target_type = v_tmp_split.at(0);
  //
  //    DataAffinity fix_affi = get_data_affinity_by_string(str_target_type);
  //
  //    vector<IR *> v_binary_operator =
  //        p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(
  //            cur_stmt_root, TypeBinaryExpr, false, true);
  //    for (IR *cur_binary_operator : v_binary_operator) {
  //      if (cur_binary_operator->get_middle() != (" " + str_operator + " ")) {
  //        continue;
  //      }
  //
  //      bool is_skip = false;
  //      for (IR *prev_dropped : ir_to_deep_drop) {
  //        if (p_oracle->ir_wrapper.is_ir_in(cur_binary_operator, prev_dropped)) {
  //          is_skip = true;
  //          break;
  //        }
  //      }
  //      if (is_skip) {
  //        continue;
  //      }
  //
  //      IR *par_node = cur_binary_operator->get_parent();
  //      if (par_node == NULL) {
  //        if (is_debug_info) {
  //          cerr << "\n\n\nERROR:: Cannot find parent node from the "
  //                  "cur_binary_operator->get_parent();\n\n\n";
  //        }
  //        return;
  //      }
  //      IR *new_ir = new IR(TypeUnknown, OP0(), NULL, NULL);
  //      new_ir->set_is_instantiated(true);
  //
  //      uint64_t fix_affi_hash = fix_affi.calc_hash();
  //
  //      if (this->data_affi_set.count(fix_affi_hash) != 0 &&
  //          this->data_affi_set.at(fix_affi_hash).size() != 0 &&
  //          get_rand_int(11) < 9) {
  //        new_ir->deep_drop();
  //        new_ir =
  //            vector_rand_ele(this->data_affi_set[fix_affi_hash])->deep_copy();
  //
  //        if (is_debug_info && new_ir != NULL) {
  //          cerr << "\nDEBUG:: From data affinity library, "
  //               << get_string_by_affinity_type(fix_affi.get_data_affinity())
  //               << " getting " << new_ir->to_string() << "\n\n\n";
  //        }
  //      } else {
  //        new_ir->mutate_literal(fix_affi);
  //      }
  //
  //      par_node->swap_node(cur_binary_operator, new_ir);
  //
  //      cur_binary_operator->parent_ = NULL;
  //      ir_to_deep_drop.push_back(cur_binary_operator);
  //    }
  //
  //    for (IR *cur_dropped : ir_to_deep_drop) {
  //      cur_dropped->deep_drop();
  //    }
  //
  //    return;
  //
  //  } else if (findStringIn(res_str, "unsupported binary operator")) {
  //
  //    /*
  //     * pq: unsupported binary operator: <string> / <string>
  //     * Forced change the binary operator to '=' for now.
  //     * TODO:: apply operator specificed operations.
  //     * */
  //
  //    if (is_debug_info) {
  //      cerr << "\n\n\nDEBUG:: Inside the unsupported binary operator. clean "
  //              "\n\n\n";
  //      cerr << "\n\n\nDEBUG:: ERROR message: " << res_str << "\n\n\n";
  //    }
  //
  //    string str_operator = "";
  //    vector<string> v_tmp_split;
  //
  //    // Get the target type name.
  //    v_tmp_split = string_splitter(res_str, "> ");
  //    if (v_tmp_split.size() <= 1) {
  //      cerr << "\n\n\nERROR: Cannot find > in the string. \n\n\n";
  //      return;
  //    }
  //    str_operator = "";
  //    for (int i = 1; i < v_tmp_split.size(); i++) {
  //      str_operator += v_tmp_split.at(i);
  //      if ((i + 1) < v_tmp_split.size()) {
  //        str_operator += "> ";
  //      }
  //    }
  //
  //    v_tmp_split = string_splitter(str_operator, " <");
  //    if (v_tmp_split.size() < 2) {
  //      cerr << "\n\n\nERROR: Cannot find < in the string. \n\n\n";
  //      return;
  //    }
  //
  //    str_operator = v_tmp_split.at(v_tmp_split.size() - 2);
  //
  //    if (is_debug_info) {
  //      cerr << "\n\n\nDEBUG::When fixing the unsupported binary operator, "
  //              "clean, getting binary operator: "
  //           << str_operator << "\n\n\n";
  //    }
  //
  //    vector<IR *> v_binary_operator =
  //        p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(
  //            cur_stmt_root, TypeBinaryExpr, false, true);
  //    for (IR *cur_binary_operator : v_binary_operator) {
  //      string cur_binary_str = cur_binary_operator->get_middle();
  //      trim_string(cur_binary_str);
  //      trim_string(str_operator);
  //      if (is_debug_info) {
  //        cerr << "\n\n\nDEBUG::When fixing the unsupported binary operator, "
  //                "clean, getting binary operator:"
  //             << str_operator << ", node str:" << cur_binary_str << ".\n\n\n";
  //      }
  //      if (cur_binary_str != str_operator) {
  //        continue;
  //      }
  //      cur_binary_operator->op_->middle_ = " = ";
  //    }
  //  }
}

void Mutator::fix_col_type_rel_errors(IR* cur_stmt_root, string res_str,
    int trial, bool is_debug_info)
{

  // Give up the fixing algorithm in the TiDB implementation for now.
  return;
  //
  //  vector tmp_err_note = string_splitter(res_str, '"');
  //  string ori_str = cur_stmt_root->to_string();
  //
  //  if (findStringIn(res_str, "argument of WHERE must be type ") &&
  //      findStringIn(res_str, "not type ")) {
  //    // SELECT * FROM v4 WHERE CURRENT_SETTING('07-18-0056 BC', 'true')
  //    // pq: argument of WHERE must be type bool, not type string
  //    if (is_debug_info) {
  //      cerr << "\n\n\nGetting rule argument of WHERE must be type.. not type... "
  //              "\n\n\n";
  //    }
  //    vector<IR *> v_type_where =
  //        p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(cur_stmt_root,
  //                                                           TypeWhere, false);
  //    if (v_type_where.size() == 0) {
  //      if (is_debug_info) {
  //        cerr << "\n\n\nError: Cannot find TypeWhere inside error: argument of "
  //                "WHERE must be type  \n\n\n";
  //      }
  //      return;
  //    }
  //
  //    for (IR *type_where : v_type_where) {
  //      if (is_debug_info) {
  //        cerr << "\n\n\nDebug:: Adding = 0 to type where.  \n\n\n";
  //      }
  //      type_where->op_->suffix_ = type_where->op_->suffix_ + " = 0";
  //    }
  //
  //    return;
  //
  //  } else if (
  //      //        trial < 7 &&
  //      findStringIn(res_str, "(desired <") &&
  //      findStringIn(res_str, "unknown function")) {
  //    // select count(*) from v0 where md5(v1);
  //    // ERROR: unknown signature: md5(int) (desired <bool>)
  //    // The problem is that the function is directly used in the WHERE clause,
  //    // where the where clause only accept BOOL type.
  //
  //    if (is_debug_info) {
  //      cerr << "\n\n\nGetting unknown function(signature), (desired <bool>). "
  //              "Guessing it is coming from the function direct usage in the"
  //              "WHERE clause. \n\n\n";
  //    }
  //
  //    string str_func_name = "";
  //    vector<string> tmp_str_split;
  //    tmp_str_split = string_splitter(res_str, "unknown signature: ");
  //    if (tmp_str_split.size() < 2) {
  //      cerr << "\n\n\n ERROR: The error message: " << res_str
  //           << " does not match the pattern. \n\n\n";
  //      return;
  //    }
  //    str_func_name = tmp_str_split.at(1);
  //    tmp_str_split = string_splitter(str_func_name, "(");
  //    if (tmp_str_split.size() < 2) {
  //      cerr << "\n\n\n ERROR: The error message: " << res_str
  //           << " does not match the pattern. \n\n\n";
  //      return;
  //    }
  //    str_func_name = tmp_str_split.at(0);
  //
  //    vector<IR *> v_func_names =
  //        p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(
  //            cur_stmt_root, str_func_name, false, true);
  //
  //    // Dirty fix, directly modify the TypeFunctionExpr type nodes.
  //    for (IR *cur_func_node : v_func_names) {
  //      IR *cur_func_expr = p_oracle->ir_wrapper.get_parent_node_with_type(
  //          cur_func_node, TypeFuncExpr);
  //      if (cur_func_expr != NULL) {
  //        cur_func_expr->op_->suffix_ += " = 0";
  //      }
  //    }
  //  } else if (
  //      //        trial < 7 &&
  //      findStringIn(res_str, "unknown function") ||
  //      findStringIn(res_str, "unknown signature")) {
  //    // Sample:
  //    // res:pq: unknown signature: oid()
  //
  //    if (is_debug_info) {
  //      cerr << "\n\n\nGetting unknown function(signature), ";
  //    }
  //
  //    vector<IR *> all_func_ir =
  //        p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(
  //            cur_stmt_root, DataFunctionName, false, true);
  //
  //    if (is_debug_info) {
  //      for (IR *cur_func_ir : all_func_ir) {
  //        cerr << "\ngetting cur_func_ir: " << cur_func_ir->to_string();
  //      }
  //      cerr << "\n\n\n";
  //    }
  //
  //    vector<string> v_target_func_str = string_splitter(res_str, ": ");
  //    string target_func_str;
  //    if (v_target_func_str.size() > 3) {
  //      target_func_str = v_target_func_str[2];
  //    } else {
  //      if (is_debug_info) {
  //        cerr << "\n\n\nError: cannot find 3 : inside the error message. \n\n\n";
  //      }
  //    }
  //
  //    if (target_func_str != "") {
  //      v_target_func_str = string_splitter(target_func_str, "(");
  //      if (v_target_func_str.size() > 1) {
  //        target_func_str = v_target_func_str.front();
  //      } else {
  //        if (is_debug_info) {
  //          cerr << "\n\n\nError: cannot find the left bracket. \n\n\n";
  //        }
  //        target_func_str = "";
  //      }
  //    }
  //
  //    //        for (IR *cur_func_ir : all_func_ir) {
  //    //            cur_func_ir->set_is_instantiated(false);
  //    //        }
  //
  //    vector<IR *> ir_to_deep_drop;
  //    for (IR *cur_func_ir : all_func_ir) {
  //
  //      if (target_func_str != "") {
  //        if (findStringIn(cur_func_ir->get_str_val(), target_func_str)) {
  //          if (is_debug_info) {
  //            cerr << "\n\n\nDEBUG: Found cur_func_ir: "
  //                 << cur_func_ir->to_string()
  //                 << " matching with error node: " << target_func_str
  //                 << "\n\n\n";
  //          }
  //          cur_func_ir->set_is_instantiated(false);
  //          // ignored nested expressions.
  //          this->instan_func_expr(cur_func_ir, ir_to_deep_drop, true,
  //                                 is_debug_info);
  //        } else {
  //          if (is_debug_info) {
  //            cerr << "\n\n\nDEBUG: Ignoring cur_func_ir: "
  //                 << cur_func_ir->to_string()
  //                 << " because not matching with error node: " << target_func_str
  //                 << "\n\n\n";
  //          }
  //          continue;
  //        }
  //      } else {
  //        if (is_debug_info) {
  //          cerr << "\n\n\nDEBUG: Cannot match the target_func_ir. Mutating "
  //                  "everything. \n\n\n";
  //        }
  //        cur_func_ir->set_is_instantiated(false);
  //        // ignored nested expressions.
  //        this->instan_func_expr(cur_func_ir, ir_to_deep_drop, true,
  //                               is_debug_info);
  //      }
  //    }
  //    for (IR *ir_drop : ir_to_deep_drop) {
  //      ir_drop->deep_drop();
  //    }
  //  } else if (findStringIn(res_str, "unsupported comparison") ||
  //             (findStringIn(res_str, "parsing as type ") &&
  //              findStringIn(res_str, "could not parse"))) {
  //    if (is_debug_info) {
  //      cerr << "\n\n\nDEBUG: Fixing column type mismatch, using rule: "
  //              "unsupported comparison or parsing as type .. could not "
  //              "parse\n\n\n";
  //    }
  //    //        pq: unsupported comparison operator: c4 = ANY ARRAY['2ci10p4',
  //    //        '09-10-66 BC 11:15:40.8179-2', '05-19-81 BC 03:33:31.6577+2',
  //    //        '05-08-4034 BC 06:58:13-5', '05-1 0-3656 14:14:21-3']: parsing as
  //    //        type timestamp: could not parse "2ci10p4"
  //    fix_literal_op_err(cur_stmt_root, res_str, is_debug_info);
  //  } else if (findStringIn(res_str, "unsupported binary operator") ||
  //             (findStringIn(res_str, "could not parse ") &&
  //              findStringIn(res_str, " as type "))) {
  //    if (is_debug_info) {
  //      cerr
  //          << "\n\n\nDEBUG: Fixing column type mismatch, using rule: "
  //             "unsupported binary operator or could not parse ... as type\n\n\n";
  //    }
  //    // SELECT * FROM v0 WHERE c1 > 'abc';
  //    // ERROR: could not parse "abc" as type int: strconv.ParseInt: parsing
  //    // "abc": invalid syntax
  //    fix_column_literal_op_err(cur_stmt_root, res_str, is_debug_info);
  //  } else if (findStringIn(res_str, "could not parse ") &&
  //             findStringIn(res_str, "as ")) {
  //    // pq: could not parse "jsmx" as inet. invalid IP
  //    fix_literal_op_err(cur_stmt_root, res_str, is_debug_info);
  //  } else if (findStringIn(res_str, "to be of type")) {
  //    // Getting error: pq: expected B'111111' to be of type string[], found type
  //    // varbit
  //
  //    if (is_debug_info) {
  //      cerr << "\n\n\nDEBUG: Fixing column type mismatch, using rule: "
  //              "to be of type\n\n\n";
  //    }
  //
  //    string err_str_type = "";
  //    vector<string> tmp_str_split;
  //    tmp_str_split = string_splitter(res_str, "to be of type ");
  //    if (tmp_str_split.size() < 2) {
  //      cerr << "\n\n\n ERROR: The error message: " << res_str
  //           << " does not match the pattern. \n\n\n";
  //      return;
  //    }
  //    err_str_type = tmp_str_split.at(1);
  //    tmp_str_split = string_splitter(err_str_type, ",");
  //    if (tmp_str_split.size() < 2) {
  //      cerr << "\n\n\n ERROR: The error message: " << res_str
  //           << " does not match the pattern. \n\n\n";
  //      return;
  //    }
  //    err_str_type = tmp_str_split.at(0);
  //
  //    string err_str_literal = "";
  //    tmp_str_split = string_splitter(res_str, "expected ");
  //    if (tmp_str_split.size() < 2) {
  //      cerr << "\n\n\n ERROR: The error message: " << res_str
  //           << " does not match the pattern. \n\n\n";
  //      return;
  //    }
  //    err_str_literal = tmp_str_split.at(1);
  //    tmp_str_split = string_splitter(err_str_literal, " to be of type");
  //    if (tmp_str_split.size() < 2) {
  //      cerr << "\n\n\n ERROR: The error message: " << res_str
  //           << " does not match the pattern. \n\n\n";
  //      return;
  //    }
  //    err_str_literal = tmp_str_split.at(0);
  //
  //    DataAffinity corr_affi = get_data_affinity_by_string(err_str_type);
  //
  //    vector<IR *> v_matched_node =
  //        p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(
  //            cur_stmt_root, err_str_literal, false, true);
  //
  //    vector<IR *> ir_to_deep_drop;
  //
  //    for (IR *cur_matched_node : v_matched_node) {
  //
  //      bool is_skip = false;
  //      for (auto cur_rov : ir_to_deep_drop) {
  //        if (p_oracle->ir_wrapper.is_ir_in(cur_matched_node, cur_rov)) {
  //          is_skip = true;
  //        }
  //      }
  //      if (is_skip) {
  //        continue;
  //      }
  //
  //      IR *new_literal = new IR(TypeStringLiteral, OP0(), NULL, NULL);
  //      new_literal->set_is_instantiated(true);
  //      new_literal->set_data_affinity(corr_affi);
  //      new_literal->mutate_literal(corr_affi);
  //
  //      p_oracle->ir_wrapper.iter_cur_node_with_handler(
  //          cur_matched_node, [](IR *cur_node) -> void {
  //            cur_node->set_is_instantiated(true);
  //            cur_node->set_data_flag(ContextNoModi);
  //          });
  //      cur_stmt_root->swap_node(cur_matched_node, new_literal);
  //      ir_to_deep_drop.push_back(cur_matched_node);
  //    }
  //
  //    if (is_debug_info) {
  //      cerr << "DEPENDENCY: Fixing semantic error. Matching rule 'to be of "
  //              "type' from: \n"
  //           << res_str << "\n getting new corr_affi: "
  //           << get_string_by_affinity_type(corr_affi.get_data_affinity())
  //           << "\n\n\n";
  //    }
  //
  //    for (IR *cur_ir : ir_to_deep_drop) {
  //      cur_ir->deep_drop();
  //    }
  //
  //  }
  //
  //  else if (tmp_err_note.size() >= 3
  //           //             && trial < 7
  //  ) {
  //    if (is_debug_info) {
  //      cerr << "\n\n\nDEBUG: Fixing column type mismatch, using rule: "
  //              "tmp_err_note.size() >= 3?\n\n\n";
  //    }
  //
  //    vector<string> v_err_note;
  //
  //    for (int i = 1; i < tmp_err_note.size(); i += 2) {
  //      v_err_note.push_back(tmp_err_note.at(i));
  //    }
  //
  //    if (v_err_note.size() == 0) {
  //      return;
  //    }
  //
  //    for (string &cur_err_note : v_err_note) {
  //      vector<IR *> node_matching;
  //      vector<string> potential_matched_str;
  //      potential_matched_str.push_back(cur_err_note);
  //      potential_matched_str.push_back("'" + cur_err_note + "'");
  //      node_matching = p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(
  //          cur_stmt_root, potential_matched_str, false, true);
  //
  //      vector<IR *> node_matching_filtered;
  //
  //      for (IR *cur_node_matching : node_matching) {
  //        if (cur_node_matching->get_data_flag() != ContextDefine &&
  //            cur_node_matching->get_data_flag() != ContextUndefine &&
  //            cur_node_matching->get_data_flag() != ContextNoModi) {
  //          cur_node_matching->set_is_instantiated(false);
  //          node_matching_filtered.push_back(cur_node_matching);
  //        }
  //      }
  //
  //      vector<vector<IR *>> tmp_node_matching;
  //      tmp_node_matching.push_back(node_matching_filtered);
  //
  //      if (is_debug_info) {
  //        cerr << "\n\n\nFor error message: \n" << res_str << "\nGetting node: ";
  //        for (IR *cur_node_matching : node_matching_filtered) {
  //          cerr << cur_node_matching->to_string() << ", ";
  //        }
  //        cerr << "\n\n";
  //      }
  //      this->instan_dependency(cur_stmt_root, tmp_node_matching, false);
  //    }
  //  } else {
  //    if (is_debug_info) {
  //      cerr << "\n\n\nDEBUG: Fall back to pure whole statement instantiation. "
  //              "\n\n\n";
  //    }
  //    p_oracle->ir_wrapper.iter_cur_node_with_handler(
  //        cur_stmt_root,
  //        [](IR *cur_node) -> void { cur_node->set_is_instantiated(false); });
  //    this->reset_data_library_single_stmt();
  //    this->validate(cur_stmt_root);
  //  }
  //
  //  if (is_debug_info) {
  //    cerr << "After trying to fix the error from the error message, we get ori "
  //            "str: \n"
  //         << ori_str << "\nto: \n"
  //         << cur_stmt_root->to_string() << "\n\n\n";
  //  }
}

void Mutator::rollback_instan_lib_changes()
{

  for (string& cur_create_table : v_create_table_names_single) {
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
      for (string cur_mapped_col : all_mapped_col) {
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

  // For ALTER TABLE statement.
  m_table2columns = m_table2columns_snapshot;
  m_table2index = m_table2index_snapshot;
  m_table2partition = m_table2partition_snapshot;

  // Remove all alias related
  this->v_table_alias_names_single.clear();
  this->v_column_alias_names_single.clear();
  this->m_alias2table_single.clear();
  this->m_alias2column_single.clear();
  this->m_alias_table2column_single.clear();

  this->v_create_table_names_single.clear();
  this->v_create_view_names_single.clear();
}

void Mutator::fix_instan_error(IR* cur_stmt_root, string res_str, int trial,
    bool is_debug_info)
{

  string ori_str = cur_stmt_root->to_string();

  this->rollback_instan_lib_changes();

  vector<vector<IR*>> tmp_node_matching;

  SemanticErrorType cur_error_type = p_oracle->detect_semantic_error_type(res_str);

  if (cur_error_type == ColumnTypeRelatedError) {
    if (is_debug_info) {
      cerr << "Debug: fix_instan_error: ColumnTypeRelatedError. \n\n\n";
    }
    this->fix_col_type_rel_errors(cur_stmt_root, res_str, trial, is_debug_info);
  } else {
    if (is_debug_info) {
      cerr << "Debug: fix_instan_error: Other types of error. \n\n\n";
    }
    this->reset_data_library_single_stmt();
    this->validate(cur_stmt_root, is_debug_info);
  }
}

// Auto-detect the data types from any query expressions or subqueries.
void Mutator::auto_mark_data_types_from_select_stmt(
    IR* cur_stmt_root, char** argv, u32 exec_tmout, int is_reset_server,
    u8 (*run_target)(char**, u32, string, int, string&), bool is_debug_info)
{
  // Pass in the run_target function from the main afl-fuzz.cpp file to here
  // through function pointer. Will not change the original signature of the
  // run_target function, which is static.

  //TODO: Disable this feature for now.
  return;

  //  vector<IR *> vec_all_nodes =
  //      p_oracle->ir_wrapper.get_all_ir_node(cur_stmt_root);
  //
  //  for (IR *cur_node : vec_all_nodes) {
  //    // Check whether the current data type matches the following types.
  //    IRTYPE cur_ir_type = cur_node->get_ir_type();
  //    if (cur_ir_type == TypeSubquery || cur_ir_type == TypeAndExpr ||
  //        cur_ir_type == TypeOrExpr || cur_ir_type == TypeIsNullExpr ||
  //        cur_ir_type == TypeIsNotNullExpr || cur_ir_type == TypeBinaryExpr ||
  //        cur_ir_type == TypeUnaryExpr || cur_ir_type == TypeComparisonExpr ||
  //        cur_ir_type == TypeRangeCond || cur_ir_type == TypeIsOfTypeExpr ||
  //        cur_ir_type == TypeExprFmtWithParen ||
  //        cur_ir_type == TypeBinExprFmtWithParen ||
  //        cur_ir_type == TypeBinExprFmtWithParenAndSubOp ||
  //        cur_ir_type == TypeNotExpr || cur_ir_type == TypeParenExpr ||
  //        cur_ir_type == TypeIfErrExpr || cur_ir_type == TypeIfExpr ||
  //        cur_ir_type == TypeNullIfExpr || cur_ir_type == TypeCoalesceExpr ||
  //        cur_ir_type == TypeFuncExpr || cur_ir_type == TypeCaseExpr ||
  //        cur_ir_type == TypeCastExpr || cur_ir_type == TypeIndirectionExpr ||
  //        cur_ir_type == TypeAnnotateTypeExpr || cur_ir_type == TypeCollateExpr ||
  //        cur_ir_type == TypeColumnAccessExpr) {
  //      // For these expression types, add a bracket to the ir node,
  //      // and then add the `= true` to the expression.
  //      string ori_prefix_ = cur_node->op_->prefix_;
  //      string ori_suffix_ = cur_node->op_->suffix_;
  //
  //      // Add a bracket and = true statement to the current node.
  //      cur_node->op_->prefix_ = "(" + cur_node->op_->prefix_;
  //      cur_node->op_->suffix_ = cur_node->op_->suffix_ + ") = TRUE";
  //
  //      string updated_stmt = "";
  //      if (p_oracle->ir_wrapper.is_ir_in(cur_node, TypeFrom)) {
  //        // The expression located in the FROM clause behaves a bit different
  //        // than the one in the WHERE clause. Bring the expressions or subquery
  //        // out as a new SELECT to check its data types. Construct a new SELECT
  //        // statement. Only use the cur_node expression, instead of using the
  //        // whole original SELECT.
  //        updated_stmt = "SELECT " + cur_node->to_string();
  //      } else {
  //        updated_stmt = cur_stmt_root->to_string();
  //      }
  //
  //      // Get the updated string, and run the statement.
  //      updated_stmt = "SAVEPOINT foo; \n" + updated_stmt +
  //                     ";\n ROLLBACK TO SAVEPOINT foo; \n";
  //      string res_str = "";
  //      run_target(argv, exec_tmout, updated_stmt, 0, res_str);
  //
  //      // Analyze the res str.
  //      //            cerr << "\n\n\nDEBUG:From Stmt: " << updated_stmt << ";\n";
  //      bool is_syntax_error = false;
  //      label_ir_data_type_from_err_msg(cur_node, res_str, is_syntax_error);
  //
  //      // Rollback to the original statement.
  //      cur_node->op_->prefix_ = ori_prefix_;
  //      cur_node->op_->suffix_ = ori_suffix_;
  //
  //      if (!is_syntax_error) {
  //        // If the change does not cause a syntax error, then
  //        // this modification is succeeded. We can move on to
  //        // the next node.
  //        //                cerr << "Not syntax error: " << updated_stmt << ",
  //        //                res_str: " << res_str << "\n\n\n";
  //        return;
  //      }
  //
  //      // Otherwise, the current modification = TRUE causes a syntax error,
  //      // let's try to add an extra bracket to the statement and try again.
  //      // Add an extra bracket and = true statement to the current node.
  //      cur_node->op_->prefix_ = "((" + cur_node->op_->prefix_;
  //      cur_node->op_->suffix_ = cur_node->op_->suffix_ + ") = TRUE)";
  //
  //      // Get the updated string, and run the statement.
  //      if (p_oracle->ir_wrapper.is_ir_in(cur_node, TypeFrom)) {
  //        // The expression located in the FROM clause behaves a bit different
  //        // than the one in the WHERE clause. Bring the expressions or subquery
  //        // out as a new SELECT to check its data types. Construct a new SELECT
  //        // statement. Only use the cur_node expression, instead of using the
  //        // whole original SELECT.
  //        updated_stmt = "SELECT " + cur_node->to_string();
  //      } else {
  //        updated_stmt = cur_stmt_root->to_string();
  //      }
  //      updated_stmt = "SAVEPOINT foo; \n" + updated_stmt +
  //                     ";\n ROLLBACK TO SAVEPOINT foo; \n";
  //      res_str.clear();
  //      run_target(argv, exec_tmout, updated_stmt, 0, res_str);
  //
  //      // Analyze the res str.
  //      cerr << "\n\n\nDEBUG:From extra bracket Stmt: " << updated_stmt << ";\n";
  //      is_syntax_error = false;
  //      label_ir_data_type_from_err_msg(cur_node, res_str, is_syntax_error);
  //
  //      //            cerr << "Not syntax error: " << updated_stmt << ", res_str:
  //      //            " << res_str << "\n\n\n";
  //
  //      // Rollback to the original statement.
  //      cur_node->op_->prefix_ = ori_prefix_;
  //      cur_node->op_->suffix_ = ori_suffix_;
  //
  //      return;
  //    } else if (cur_ir_type == TypeSubquery) {
  //
  //      // For subqueries, add the `= true` to the expression.
  //      string ori_suffix_ = cur_node->op_->suffix_;
  //
  //      // Add a bracket and = true statement to the current node.
  //      cur_node->op_->suffix_ = cur_node->op_->suffix_ + " = TRUE";
  //
  //      // Get the updated string, and run the statement.
  //      string updated_stmt = "";
  //      // Get the updated string, and run the statement.
  //      if (p_oracle->ir_wrapper.is_ir_in(cur_node, TypeFrom)) {
  //        // The expression located in the FROM clause behaves a bit different
  //        // than the one in the WHERE clause. Bring the expressions or subquery
  //        // out as a new SELECT to check its data types. Construct a new SELECT
  //        // statement. Only use the cur_node expression, instead of using the
  //        // whole original SELECT.
  //        updated_stmt = "SELECT " + cur_node->to_string();
  //      } else {
  //        updated_stmt = cur_stmt_root->to_string();
  //      }
  //      updated_stmt = "SAVEPOINT foo; \n" + updated_stmt +
  //                     ";\n ROLLBACK TO SAVEPOINT foo; \n";
  //      string res_str = "";
  //      run_target(argv, exec_tmout, updated_stmt, 0, res_str);
  //
  //      // Analyze the res str.
  //      //            cerr << "\n\n\nDEBUG: From Stmt: " << updated_stmt << ";\n";
  //      bool is_syntax_error = false;
  //      label_ir_data_type_from_err_msg(cur_node, res_str, is_syntax_error);
  //
  //      // Rollback to the original statement.
  //      cur_node->op_->suffix_ = ori_suffix_;
  //
  //      if (!is_syntax_error) {
  //        // If the change does not cause a syntax error, then
  //        // this modification is succeeded. We can move on to
  //        // the next node.
  //        //                cerr << "Not syntax error: " << updated_stmt << ",
  //        //                res_str: " << res_str << "\n\n\n";
  //        return;
  //      }
  //
  //      // Otherwise, the current modification = TRUE causes a syntax error,
  //      // let's try to add an extra bracket to the statement and try again.
  //      // Add an extra bracket and = true statement to the current node.
  //      string ori_prefix_ = cur_node->op_->prefix_;
  //      cur_node->op_->prefix_ = "(" + cur_node->op_->prefix_;
  //      cur_node->op_->suffix_ = cur_node->op_->suffix_ + " = TRUE)";
  //
  //      // Get the updated string, and run the statement.
  //      if (p_oracle->ir_wrapper.is_ir_in(cur_node, TypeFrom)) {
  //        // The expression located in the FROM clause behaves a bit different
  //        // than the one in the WHERE clause. Bring the expressions or subquery
  //        // out as a new SELECT to check its data types. Construct a new SELECT
  //        // statement. Only use the cur_node expression, instead of using the
  //        // whole original SELECT.
  //        updated_stmt = "SELECT " + cur_node->to_string();
  //      } else {
  //        updated_stmt = cur_stmt_root->to_string();
  //      }
  //      updated_stmt = "SAVEPOINT foo; \n" + updated_stmt +
  //                     ";\n ROLLBACK TO SAVEPOINT foo; \n";
  //      res_str = "";
  //      run_target(argv, exec_tmout, updated_stmt, 0, res_str);
  //
  //      // Analyze the res str.
  //      //            cerr << "\n\n\nDEBUG: From Stmt: " << updated_stmt << ";\n";
  //      is_syntax_error = false;
  //      label_ir_data_type_from_err_msg(cur_node, res_str, is_syntax_error);
  //
  //      //            cerr << "Not syntax error: " << updated_stmt << ", res_str:
  //      //            " << res_str << "\n\n\n";
  //
  //      // Rollback to the original statement.
  //      cur_node->op_->prefix_ = ori_prefix_;
  //      cur_node->op_->suffix_ = ori_suffix_;
  //
  //      return;
  //    }
  //  }

  return;
}

// Auto-detect the data types from any query expressions or subqueries.
void Mutator::auto_mark_data_types_from_non_select_stmt(
    IR* cur_stmt_root, char** argv, u32 exec_tmout, int is_reset_server,
    u8 (*run_target)(char**, u32, string, int, string&), bool is_debug_info)
{
  // Pass in the run_target function from the main afl-fuzz.cpp file to here
  // through function pointer. Will not change the original signature of the
  // run_target function, which is static.

  // TODO:: disable this feature for now.
  return;

  //  vector<IR *> vec_all_nodes =
  //      p_oracle->ir_wrapper.get_all_ir_node(cur_stmt_root);
  //
  //  vector<IR *> v_from_clause =
  //      p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(cur_stmt_root,
  //                                                         TypeFrom, false);
  //  IR *from_clause = NULL;
  //  if (v_from_clause.size() > 0) {
  //    from_clause = v_from_clause.front();
  //  }
  //
  //  for (IR *cur_node : vec_all_nodes) {
  //    // Check whether the current data type matches the following types.
  //    IRTYPE cur_ir_type = cur_node->get_ir_type();
  //    if (cur_ir_type == TypeSubquery || cur_ir_type == TypeAndExpr ||
  //        cur_ir_type == TypeOrExpr || cur_ir_type == TypeIsNullExpr ||
  //        cur_ir_type == TypeIsNotNullExpr || cur_ir_type == TypeBinaryExpr ||
  //        cur_ir_type == TypeUnaryExpr || cur_ir_type == TypeComparisonExpr ||
  //        cur_ir_type == TypeRangeCond || cur_ir_type == TypeIsOfTypeExpr ||
  //        cur_ir_type == TypeExprFmtWithParen ||
  //        cur_ir_type == TypeBinExprFmtWithParen ||
  //        cur_ir_type == TypeBinExprFmtWithParenAndSubOp ||
  //        cur_ir_type == TypeNotExpr || cur_ir_type == TypeParenExpr ||
  //        cur_ir_type == TypeIfErrExpr || cur_ir_type == TypeIfExpr ||
  //        cur_ir_type == TypeNullIfExpr || cur_ir_type == TypeCoalesceExpr ||
  //        cur_ir_type == TypeFuncExpr || cur_ir_type == TypeCaseExpr ||
  //        cur_ir_type == TypeCastExpr || cur_ir_type == TypeIndirectionExpr ||
  //        cur_ir_type == TypeAnnotateTypeExpr || cur_ir_type == TypeCollateExpr ||
  //        cur_ir_type == TypeColumnAccessExpr) {
  //      // For these expression types, add a bracket to the ir node,
  //      // and then add the `= true` to the expression.
  //      string ori_prefix_ = cur_node->op_->prefix_;
  //      string ori_suffix_ = cur_node->op_->suffix_;
  //
  //      // Add a bracket and = true statement to the current node.
  //      cur_node->op_->prefix_ = "(" + cur_node->op_->prefix_;
  //      cur_node->op_->suffix_ = cur_node->op_->suffix_ + ") = TRUE";
  //
  //      string updated_stmt = "";
  //      updated_stmt = "SELECT " + cur_node->to_string();
  //      if (from_clause) {
  //        // From non-select statement, expression could reference contents
  //        // from the FROM clause, therefore, we should import them
  //        // for usage.
  //        updated_stmt += " " + from_clause->to_string();
  //      }
  //
  //      // Get the updated string, and run the statement.
  //      updated_stmt = "SAVEPOINT foo; \n" + updated_stmt +
  //                     ";\n ROLLBACK TO SAVEPOINT foo; \n";
  //      string res_str = "";
  //      run_target(argv, exec_tmout, updated_stmt, 0, res_str);
  //
  //      // Analyze the res str.
  //      //      cerr << "\n\n\nDEBUG: From ori stmt: " <<
  //      //      cur_stmt_root->to_string() << "\nStmt: " << updated_stmt << ";\n";
  //      bool is_syntax_error = false;
  //      label_ir_data_type_from_err_msg(cur_node, res_str, is_syntax_error);
  //
  //      // Rollback to the original statement.
  //      cur_node->op_->prefix_ = ori_prefix_;
  //      cur_node->op_->suffix_ = ori_suffix_;
  //
  //      if (!is_syntax_error) {
  //        // If the change does not cause a syntax error, then
  //        // this modification is succeeded. We can move on to
  //        // the next node.
  //        //                cerr << "Not syntax error: " << updated_stmt << ",
  //        //                res_str: " << res_str << "\n\n\n";
  //        return;
  //      }
  //
  //      // Otherwise, the current modification = TRUE causes a syntax error,
  //      // let's try to add an extra bracket to the statement and try again.
  //      // Add an extra bracket and = true statement to the current node.
  //      cur_node->op_->prefix_ = "((" + cur_node->op_->prefix_;
  //      cur_node->op_->suffix_ = cur_node->op_->suffix_ + ") = TRUE)";
  //
  //      // Get the updated string, and run the statement.
  //      if (p_oracle->ir_wrapper.is_ir_in(cur_node, TypeFrom)) {
  //        // The expression located in the FROM clause behaves a bit different
  //        // than the one in the WHERE clause. Bring the expressions or subquery
  //        // out as a new SELECT to check its data types. Construct a new SELECT
  //        // statement. Only use the cur_node expression, instead of using the
  //        // whole original SELECT.
  //        updated_stmt = "SELECT " + cur_node->to_string();
  //      } else {
  //        updated_stmt = cur_stmt_root->to_string();
  //      }
  //      updated_stmt = "SAVEPOINT foo; \n" + updated_stmt +
  //                     ";\n ROLLBACK TO SAVEPOINT foo; \n";
  //      res_str.clear();
  //      run_target(argv, exec_tmout, updated_stmt, 0, res_str);
  //
  //      // Analyze the res str.
  //      //      cerr << "\n\n\nDEBUG: From ori stmt: " <<
  //      //      cur_stmt_root->to_string() << "\nStmt: " << updated_stmt << ";\n";
  //      is_syntax_error = false;
  //      label_ir_data_type_from_err_msg(cur_node, res_str, is_syntax_error);
  //
  //      //      cerr << "Not syntax error: " << updated_stmt << ", res_str: " <<
  //      //      res_str << "\n\n\n";
  //
  //      // Rollback to the original statement.
  //      cur_node->op_->prefix_ = ori_prefix_;
  //      cur_node->op_->suffix_ = ori_suffix_;
  //
  //      return;
  //    } else if (cur_ir_type == TypeSubquery) {
  //
  //      // For subqueries, add the `= true` to the expression.
  //      string ori_suffix_ = cur_node->op_->suffix_;
  //
  //      // Add a bracket and = true statement to the current node.
  //      cur_node->op_->suffix_ = cur_node->op_->suffix_ + " = TRUE";
  //
  //      // Get the updated string, and run the statement.
  //      string updated_stmt = "";
  //      // Get the updated string, and run the statement.
  //      updated_stmt = "SELECT " + cur_node->to_string();
  //      if (from_clause) {
  //        // From non-select statement, expression could reference contents
  //        // from the FROM clause, therefore, we should import them
  //        // for usage.
  //        updated_stmt += " " + from_clause->to_string();
  //      }
  //
  //      updated_stmt = "SAVEPOINT foo; \n" + updated_stmt +
  //                     ";\n ROLLBACK TO SAVEPOINT foo; \n";
  //      string res_str = "";
  //      run_target(argv, exec_tmout, updated_stmt, 0, res_str);
  //
  //      // Analyze the res str.
  //      //      cerr << "\n\n\nDEBUG: From ori stmt: " <<
  //      //      cur_stmt_root->to_string() << "\nStmt: " << updated_stmt << ";\n";
  //      bool is_syntax_error = false;
  //      label_ir_data_type_from_err_msg(cur_node, res_str, is_syntax_error);
  //
  //      // Rollback to the original statement.
  //      cur_node->op_->suffix_ = ori_suffix_;
  //
  //      if (!is_syntax_error) {
  //        // If the change does not cause a syntax error, then
  //        // this modification is succeeded. We can move on to
  //        // the next node.
  //
  //        //        cerr << "Not syntax error: " << updated_stmt << ", res_str: "
  //        //        << res_str << "\n\n\n";
  //        return;
  //      }
  //
  //      // Otherwise, the current modification = TRUE causes a syntax error,
  //      // let's try to add an extra bracket to the statement and try again.
  //      // Add an extra bracket and = true statement to the current node.
  //      string ori_prefix_ = cur_node->op_->prefix_;
  //      cur_node->op_->prefix_ = "(" + cur_node->op_->prefix_;
  //      cur_node->op_->suffix_ = cur_node->op_->suffix_ + " = TRUE)";
  //
  //      // Get the updated string, and run the statement.
  //      if (p_oracle->ir_wrapper.is_ir_in(cur_node, TypeFrom)) {
  //        // The expression located in the FROM clause behaves a bit different
  //        // than the one in the WHERE clause. Bring the expressions or subquery
  //        // out as a new SELECT to check its data types. Construct a new SELECT
  //        // statement. Only use the cur_node expression, instead of using the
  //        // whole original SELECT.
  //        updated_stmt = "SELECT " + cur_node->to_string();
  //      } else {
  //        updated_stmt = cur_stmt_root->to_string();
  //      }
  //      updated_stmt = "SAVEPOINT foo; \n" + updated_stmt +
  //                     ";\n ROLLBACK TO SAVEPOINT foo; \n";
  //      res_str = "";
  //      run_target(argv, exec_tmout, updated_stmt, 0, res_str);
  //
  //      // Analyze the res str.
  //      //      cerr << "\n\n\nDEBUG: From ori stmt: " <<
  //      //      cur_stmt_root->to_string() << "\nStmt: " << updated_stmt << ";\n";
  //      is_syntax_error = false;
  //      label_ir_data_type_from_err_msg(cur_node, res_str, is_syntax_error);
  //
  //      // Rollback to the original statement.
  //      cur_node->op_->prefix_ = ori_prefix_;
  //      cur_node->op_->suffix_ = ori_suffix_;
  //      //      cerr << "Not syntax error: " << updated_stmt << ", res_str: " <<
  //      //      res_str << "\n\n\n";
  //
  //      return;
  //    }
  //  }

  return;
}

void Mutator::label_ir_data_type_from_err_msg(IR* ir, string& err_msg,
    bool& is_syntax_error)
{

  //    cerr << "Getting ir type: " << get_string_by_ir_type(ir->get_ir_type())
  //    << "\n\n\n";
  if (is_str_empty(err_msg) ||             // err_msg is empty.
      !p_oracle->is_res_str_error(err_msg) // No error message.
  ) {
    //        cerr << "getting type boolean. \n\n\n";
    ir->set_data_affinity(AFFIBOOL);
    ir->set_is_compact_expr(true);
    return;
  }

#define ff(x) findStringIn(x, "unsupported comparison operator:")
#define fff(x) findStringIn(x, "syntax error")
#define ss(x, y) string_splitter(x, y)

  if (fff(err_msg)) {
    is_syntax_error = true;
    //      cerr << " getting syntax error: " << err_msg << "\n\n\n";
    return;
  }

  if (!ff(err_msg)) {
    // The error message does not match the expected one.
    // Ignored.
    //        cerr << "getting other error: " << err_msg << "\n\n\n";
    return;
  }

  // Grep the error hinted data types from the error message.
  string hinted_type_str;
  vector<string> v_tmp_str = ss(err_msg, "<");
  if (v_tmp_str.size() < 2) {
    cerr << "Error: cannot get the < symbol from the error: " << err_msg
         << "\n\n\n";
    return;
  }
  for (int i = 1; i < v_tmp_str.size(); i++) {
    hinted_type_str += "<" + v_tmp_str[i];
  }
  v_tmp_str = ss(hinted_type_str, " =");
  if (v_tmp_str.size() < 2) {
    cerr << "Error: cannot get the = symbol from the error: " << hinted_type_str
         << "\n\n\n";
    return;
  }
  hinted_type_str = v_tmp_str.front();

  DataAffinity data_affi = get_data_affinity_by_string(
      hinted_type_str.substr(1, hinted_type_str.size() - 2));
  //  cerr << "DEBUG:: Getting the hinted_type_str:" << hinted_type_str <<
  //  ".\n"; cerr << "DEBUG:: Getting the data_affinity:" <<
  //  get_string_by_affinity_type(data_affi.get_data_affinity()) << ".\n\n\n";

#undef fff
#undef ff
#undef ss

  ir->set_data_affinity(data_affi);
  ir->set_is_compact_expr(true);

  return;
}

IR* Mutator::get_ir_node_from_data_affi_pair(
    const pair<string*, int>& in_pair)
{

  if (in_pair.first == NULL) {
    cerr << "ERROR: The input pair from get_ir_node_from_data_affi_pair are "
            "empty! \n\n\n";
    return NULL;
  }

  vector<IR*> v_parsed_ir = parse_query_str_get_ir_set(*(in_pair.first));
  if (v_parsed_ir.size() == 0) {
    cerr << "ERROR: The input pair from get_ir_node_from_data_affi_pair cannot "
            "be parsed\n"
            "Getting: \n"
         << *(in_pair.first) << "! \n\n\n";
  }

  for (auto cur_ir : v_parsed_ir) {
    if (cur_ir->uniq_id_in_tree_ == in_pair.second) {
      IR* res_ir = cur_ir->deep_copy();
      res_ir->parent_ = NULL;
      v_parsed_ir.back()->deep_drop();
      return res_ir;
    }
  }

  cerr << "Error: The input pair from get_ir_node_from_data_affi_pair, the "
          "node number: "
       << in_pair.second << " cannot be found from string: " << *(in_pair.first)
       << "\n\n\n";
  v_parsed_ir.back()->deep_drop();
  return NULL;
}

void Mutator::instan_replaced_node(IR* cur_stmt_root, IR* cur_node,
    bool is_debug_info)
{

  /* This function is used to fix the instantiation mismatches when replacing
   * query nodes from the mutator library. The saved query parts might not
   * contain the same table/column names as the current query statement,
   * therefore, all table/column names needs rewrite.
   * */
  // Note: let's keep the literals unchanged for now.

  // Gather all the function/table/column names from the cur_node.
  vector<IR*> v_func_expr_nodes = p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(
      cur_node, DataFunctionExpr, false, true);
  vector<IR*> v_table_nodes = p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(
      cur_node, DataTableName, false, true);
  vector<IR*> v_column_nodes = p_oracle->ir_wrapper.get_ir_node_in_stmt_with_type(
      cur_node, DataColumnName, false, true);

  // Label all the column names inside the function expressions. So that the
  // instan_column_name can directly recognize the data type.

  vector<IR*> ir_to_deep_drop;
  for (IR* cur_table_node : v_table_nodes) {
    bool dummy_bool = false;
    cur_table_node->set_is_instantiated(false);
    this->instan_table_name(cur_table_node, dummy_bool, false);
  }
  for (auto cur_column_node : v_column_nodes) {
    bool dummy_bool = false;
    cur_column_node->set_is_instantiated(false);
    this->instan_column_name(cur_column_node, cur_stmt_root, dummy_bool,
        ir_to_deep_drop, false);
  }

  for (auto ir_to_drop : ir_to_deep_drop) {
    ir_to_drop->deep_drop();
  }

  return;
}

string Mutator::rsg_generate_valid(const IRTYPE type)
{

  for (int i = 0; i < 100; i++) {
    string tmp_query_str = rsg_generate(type);
    vector<IR*> ir_vec = this->parse_query_str_get_ir_set(tmp_query_str);
    if (ir_vec.size() == 0) {
      continue;
    }
    ir_vec.back()->deep_drop();
    return tmp_query_str;
  }

  return "";
}
