#ifndef __MUTATOR_H__
#define __MUTATOR_H__

#include "../AFL/types.h"
#include "../rsg/rsg.h"
#include "data_type_sig.h"
#include "data_types.h"
#include "ast.h"
#include "define.h"
#include "utils.h"

#include <utility>
#include <vector>

#define LUCKY_NUMBER 500

using namespace std;

class SQL_ORACLE;

enum STMT_TYPE { NOT_ORACLE = 0, ORACLE_SELECT = 1, ORACLE_NORMAL = 2 };

class Mutator {

public:

  vector<DATATYPE> all_supported_types;

  int dyn_fix_sql_errors(IR*& cur_stmt_root, string error_msg);
  IR* locate_error_ir(IR* cur_stmt_root, string& error_msg);

  // simple setters
  void set_p_oracle(SQL_ORACLE *oracle) { this->p_oracle = oracle; }
  void set_dump_library(bool to_dump) { this->dump_library = to_dump; }
  int get_cri_valid_collection_size() { return all_cri_valid_pstr_vec.size(); }
  int get_valid_collection_size() { return all_valid_pstr_vec.size(); }

  void set_disable_dyn_instan(bool dis_dyn) {
    this->disable_dyn_instan = dis_dyn;
  }

  void set_disable_rsg_generator(bool in) { this->disable_rsg_generator = in; }

  void set_disable_rsg_cov_feedback(bool in) {
    this->disable_rsg_cov_feedback = in;
  }

  Mutator() {
    srand(time(nullptr));
    rsg_initialize();
  }

  typedef map<IR *, pair<int, IR *>> TmpRecord;

  IR *deep_copy_with_record(const IR *root, const IR *record);
  unsigned long hash(IR *);
  unsigned long hash(const string &);

  vector<string *> mutate_all(vector<IR *> &v_ir_collector,
                              u64 &total_mutate_gen_num,
                              u64 &total_mutate_gen_failed);

  vector<IR *> mutate_stmtlist(IR *input);
  vector<IR *> mutate_selectcorelist(IR *ir_root, IR *cur_ir);

  vector<IR *> mutate(IR *input);
  IR *strategy_delete(IR *cur);
  IR *strategy_insert(IR *cur);
  IR *strategy_replace(IR *cur);

  void pre_validate();
  vector<IR *> pre_fix_transform(IR *root, vector<STMT_TYPE> &stmt_type_vec);

  bool validate(IR *cur_trans_stmt, bool is_rewrite_func = true, bool is_debug_info = false);

  vector<vector<vector<IR *>>>
  post_fix_transform(vector<IR *> &all_pre_trans_vec,
                     vector<STMT_TYPE> &stmt_type_vec);
  vector<vector<IR *>> post_fix_transform(vector<IR *> &all_pre_trans_vec,
                                          vector<STMT_TYPE> &stmt_type_vec,
                                          int run_count);

  bool finalize_transform(IR *root, vector<vector<IR *>> all_post_trans_vec);
  pair<string, string> ir_to_string(IR *root,
                                    vector<vector<IR *>> all_post_trans_vec,
                                    const vector<STMT_TYPE> &stmt_type_vec);

  void minimize(vector<IR *> &);
  bool lucky_enough_to_be_mutated(unsigned int mutated_times);

  int get_ir_libary_2D_hash_kStatement_size();

  vector<IR *> parse_query_str_get_ir_set(const string &query_str);

  void add_all_to_library(IR *, const ALL_COMP_RES &);
  void add_all_to_library(IR *ir) {
    ALL_COMP_RES dummy_all_comp_res;
    add_all_to_library(ir, dummy_all_comp_res);
  }
  void add_all_to_library(string, const ALL_COMP_RES &);
  void add_all_to_library(string whole_query_str) {
    ALL_COMP_RES dummy_all_comp_res;
    add_all_to_library(whole_query_str, dummy_all_comp_res);
  }
  IR *get_from_libary_with_type(IRTYPE);
  IR *get_from_libary_with_left_type(IRTYPE);
  IR *get_from_libary_with_right_type(IRTYPE);

  bool get_select_str_from_lib(string &);

  string rsg_generate_valid(const IRTYPE type);
  string rsg_generate_valid(const string type);

  bool is_stripped_str_in_lib(string stripped_str);

  void init(string f_testcase, string f_common_string = "", string pragma = "");
  string fix(IR *root);
  void _fix(IR *root, string &);
  string extract_struct(IR *root);
  void _extract_struct(IR *root, string &);
  string extract_struct(string);
  void reset_database();
  void reset_database_single_stmt();
  void save_tmp_dependency();
  void rollback_dependency();

  bool check_node_num(IR *root, unsigned int limit);
  vector<IR *> extract_statement(IR *root);
  unsigned int calc_node(IR *root);

  void fix_preprocessing(IR *root,
                         vector<vector<IR *>> &ordered_ir);
  vector<IR *> cut_subquery(IR *program, TmpRecord &m_save);
  bool add_back(TmpRecord &m_save);
  // void fix_one(map<IR *, set<IR *>> &graph, IR *fixed_key, set<IR *>
  // &visited);
  bool fix_dependency(IR *root, vector<vector<IR *>> &ordered_ir,
                      bool is_debug_info = false);

  static vector<string> value_libary;
  static vector<string> used_value_libary;
  static map<string, vector<string>> m_tables;
  static map<string, vector<string>> m_tables_with_tmp;
  static map<string, vector<string>> m_table2index;
  // static map<string, vector<string>> m_table2alias;
  static vector<string> v_table_names;
  static vector<string> v_fts_vtable_names;
  static vector<string> v_table_names_single;
  static vector<string> v_create_table_names_single;
  static vector<string> v_alias_names_single;
  static vector<string> v_window_name_single;
  static map<string, vector<string>> m_table2alias_single;

  static vector<string> v_create_table_names_single_with_tmp;
  static vector<string> v_create_column_names_single_with_tmp;

  ~Mutator();

  void debug(IR *root, unsigned level);
  unsigned long get_library_size();
  void get_memory_usage();
  // int try_fix(char *buf, int len, char *&new_buf, int &new_len);

  void set_use_cri_val(const bool is_use) { this->use_cri_val = is_use; }
  bool get_is_use_cri_val() { return this->use_cri_val; }

  string remove_node_from_tree_by_index(string oracle_query, int remove_index);
  set<string> get_minimize_string_from_tree(string oracle_query);
  void resolve_drop_statement(IR *, bool is_debug_info = false);
  void resolve_alter_statement(IR *, bool is_debug_info = false);

  string construct_rand_pragma_stmt();

  void rsg_exec_succeed_helper() {
    if (!disable_rsg_cov_feedback && !disable_rsg_generator) {
      rsg_exec_succeed();
    } else {
      rsg_exec_clear_chosen_expr();
    }
  }
  void rsg_exec_failed_helper() {
    if (!disable_rsg_cov_feedback && !disable_rsg_generator) {
      rsg_exec_failed();
    } else {
      rsg_exec_clear_chosen_expr();
    }
  }
  void rsg_exec_clear_chosen_expr() {
    rsg_clear_chosen_expr();
  }

  int get_num_rsg_gen() { return this->num_rsg_gen; }

  inline double get_gram_total_block_cov_size() {
    return this->gram_cov_map.get_total_block_cov_size();
  }
  inline u32 get_gram_total_block_cov_size_num() {
    return this->gram_cov_map.get_total_block_cov_size_num();
  }
  inline double get_gram_total_edge_cov_size() {
    return this->gram_cov_map.get_total_edge_cov_size();
  }
  inline u32 get_gram_total_edge_cov_size_num() {
    return this->gram_cov_map.get_total_edge_cov_size_num();
  }
  inline u64 get_gram_total_path_cov_size_num() {
    return this->gram_cov_map.get_total_path_cov_size_num();
  }

private:
  void add_to_valid_lib(IR *, string &);
  void add_to_library(IR *, string &);
  void add_to_library_core(IR *, string *);

  void fix_common_rsg_errors(IR*);
  IR* gen_rand_expr_node_no_exprfunc();
  IR* gen_rand_filter_over_clause();
  IR* instan_rand_func_expr(DATATYPE req_ret_type = kTYPEUNKNOWN, bool is_avoid_window = false);
  void instan_rand_func_expr_helper(IR* cur_node, bool is_avoid_window = false);

  bool dump_library = false;
  bool use_cri_val = false;

  IR *record_ = NULL;
  // map<NODETYPE, map<NODETYPE, vector<IR*>> > ir_libary_3D_;
  // map<NODETYPE, map<NODETYPE, set<unsigned long>> > ir_libary_3D_hash_;
  map<NODETYPE, set<unsigned long>> ir_libary_2D_hash_;
  set<unsigned long> stripped_string_hash_;
  // map<NODETYPE, vector<IR*> > ir_libary_2D_;
  // map<NODETYPE, vector<IR *>> left_lib;
  // map<NODETYPE, vector<IR *>> right_lib;
  vector<string> string_libary;
  vector<string> used_string_library;
  set<unsigned long> string_libary_hash_;
  set<unsigned long> value_library_hash_;

  vector<string> cmds_;
  map<string, vector<string>> m_cmd_value_lib_;

  string s_table_name;

  map<NODETYPE, int> type_counter_;

  /* The interface of saving the required context for the mutator. Giving the
     NODETYPE, we should be able to extract all the related IR nodes from this
     library. The string* points to the string of the complete query stmt where
     the current NODE is from. And the int is the unique ID for the specific
     node, can be used to identify and extract the specific node from the IR
     tree when the tree is being reconstructed.
  */
  map<NODETYPE, vector<pair<string *, int>>> real_ir_set;
  map<NODETYPE, vector<pair<string *, int>>> left_lib_set;
  map<NODETYPE, vector<pair<string *, int>>> right_lib_set;

  map<unsigned long, bool> oracle_select_hash;

  set<string *> all_query_pstr_set;
  vector<string *> all_valid_pstr_vec;

  vector<string *> all_cri_valid_pstr_vec;

  SQL_ORACLE *p_oracle;

  u8 disable_rsg_generator, disable_dyn_instan, disable_rsg_cov_feedback;

  int num_rsg_gen = 0;

  GramCovMap gram_cov_map;

  vector<FuncSig> v_func_sig;
  vector<FuncSig> v_func_sig_non_window;
  vector<FuncSig> v_func_sig_window;

  vector<string> tmp_used_value_libary;
  map<string, vector<string>> tmp_m_tables;
  map<string, vector<string>> tmp_m_tables_with_tmp;
  map<string, vector<string>> tmp_m_table2index;
  // static map<string, vector<string>> m_table2alias;
  vector<string> tmp_v_table_names;
  vector<string> tmp_used_string_library;

  void handle_no_tables_specified_error(IR*& cur_stmt_root);
  void handle_using_no_join_error(IR*& cur_stmt_root);
  void handle_distinct_in_window_func_error(IR*& cur_stmt_root);
  void handle_nulls_syntax_error(IR*& cur_stmt_root);
  void handle_no_such_column_without_err_loc(IR*& cur_stmt_root, string& err_str);
  void handle_no_such_column_with_err_loc(IR*& cur_stmt_root, IR* err_node, string& err_str);
  int handle_no_such_table_without_err_loc(IR*& cur_stmt_root, string& err_str);

  void handle_syntax_error_after_column_name_without_loc(IR*& cur_stmt_root, const string& column_name_str);
  void handle_no_such_index_y_err_without_loc(IR*& cur_stmt_root);
  void handle_no_such_index_err_without_loc(IR*& cur_stmt_root);
  void handle_order_by_before_UNION_err(IR*& cur_stmt_root);
  void handle_limit_before_UNION_err(IR*& cur_stmt_root);
  void handle_natural_join_err(IR*& cur_stmt_root);
  void handle_cannot_join_using_column(IR*& cur_stmt_root, string& err_str);
  void handle_unsupported_frame(IR*& cur_stmt_root);
  void handle_unsupported_having_clause(IR*& cur_stmt_root);
  int handle_group_by_value_error(IR*& cur_stmt_root, string& err_msg);
  int handle_wrong_num_of_values(IR*& cur_stmt_root, string err_msg);

};

#endif
