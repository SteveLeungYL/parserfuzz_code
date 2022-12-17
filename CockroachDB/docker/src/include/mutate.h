#ifndef __MUTATOR_H__
#define __MUTATOR_H__

#include "../AFL/types.h"
#include "ast.h"
#include "define.h"
#include "utils.h"

#include <map>
#include <set>
#include <vector>

#define LUCKY_NUMBER 500

#define FUNCTION_TYPE_PATH "./function_type_lib.json"
#define SET_SESSION_PATH "./set_session_variables.json"
#define STORAGE_PARAM_PATH "./storage_parameter.json"

using namespace std;

class SQL_ORACLE;

enum RELATIONTYPE {
  kRelationElement,
  kRelationSubtype,
  kRelationAlias,
};

enum STMT_TYPE { NOT_ORACLE = 0, ORACLE_SELECT = 1, ORACLE_NORMAL = 2 };

enum DEF_ARG_TYPE {
  boolean = 0,
  integer = 1,
  floating_point = 2,
  str = 3,
  on_off_auto = 4
};

class Mutator {

public:
  Mutator() { srand(time(nullptr)); }

  IR *deep_copy_with_record(const IR *root, const IR *record);
  unsigned long hash(IR *);
  unsigned long hash(string &);

  IR *ir_random_generator(vector<IR *> v_ir_collector);

  IR* constr_rand_set_stmt();
  IR* constr_rand_storage_param(int param_num = 3);
  IR* constr_rand_func_with_affinity(DATAAFFINITYTYPE in_affi, bool is_debug_info = false);

  vector<IR *> mutate_all(IR *ori_ir_root, IR *ir_to_mutate,
                          u64 &total_mutate_failed, u64 &total_mutate_num);

  vector<IR *> mutate_stmtlist(IR *input);
  vector<IR *> mutate(IR *input);
  IR *strategy_delete(IR *cur);
  IR *strategy_insert(IR *cur);
  IR *strategy_replace(IR *cur);
  bool lucky_enough_to_be_mutated(unsigned int mutated_times);

  bool replace(IR *root, IR *old_ir, IR *new_ir);
  IR *locate_parent(IR *root, IR *old_ir);

  void init(string f_testcase = "", string f_common_string = "",
            string file2d = "", string file1d = "", string f_gen_type = "");
  void init_library();

  void init_ir_library(string filename);
  inline void init_value_library();
  void init_common_string(string filename);
  void init_data_library();
  void init_sql_type_alias_2_type();
  void init_not_mutatable_type(string filename);
  // void init_safe_generate_type(string filename);
  void add_ir_to_library(IR *);

  string get_a_string();
  unsigned long get_a_val();
  IR *get_ir_from_library(IRTYPE);
  // IR *generate_ir_by_type(IRTYPE);

  string get_data_by_type(DATATYPE);
  pair<string, string> get_data_2d_by_type(DATATYPE, DATATYPE);

  void reset_data_library();
  void reset_data_library_single_stmt();

  string parse_data(string &);
  string extract_struct(IR *root);
  void _extract_struct(IR *);
  void extract_struct2(IR *);

  vector<IR *> pre_fix_transform(IR *, vector<STMT_TYPE> &);
  vector<vector<vector<IR *>>>
  post_fix_transform(vector<IR *> &all_pre_trans_vec,
                     vector<STMT_TYPE> &stmt_type_vec,
                     vector<vector<STMT_TYPE>> &stmt_type_vec_vec);
  vector<vector<IR *>> post_fix_transform(vector<IR *> &all_pre_trans_vec,
                                          vector<STMT_TYPE> &stmt_type_vec,
                                          vector<STMT_TYPE> &, int run_count);

  bool instan_one_stmt(IR *cur_stmt, bool is_debug_info = false);

  vector<IR *> split_to_substmt(IR *root, map<IR *, pair<bool, IR *>> &m_save,
                                set<IRTYPE> &split_set);
  bool connect_back(map<IR *, pair<bool, IR *>> &m_save);

  void instan_preprocessing(IR *stmt_root, vector<IR *> &ordered_all_subquery_ir);
  string find_cloest_table_name(IR* ir_to_fix, bool is_debug_info);


  void reset_scope_library(bool clear_define);
  IR *find_closest_node(IR *stmt_root, IR *node, DATATYPE type);
  bool fill_one(IR *parent);
  // bool fill_one_pair(IR *parent, IR *child);
  // bool fill_stmt_graph_one(map<IR *, vector<IR *>> &graph, IR *ir);
  void pre_validate();
  bool validate(IR *&root, bool is_debug_info = false);
  string validate(string query, bool is_debug_info = false);

  pair<string, string>
  ir_to_string(IR *root, vector<vector<IR *>> all_post_trans_vec,
               const vector<STMT_TYPE> &all_stmt_type_vec);

  unsigned int calc_node(IR *root);
  bool replace_one_value_from_datalibray_2d(DATATYPE p_datatype,
                                            DATATYPE c_data_type, string &p_key,
                                            string &old_c_value,
                                            string &new_c_value);
  bool remove_one_pair_from_datalibrary_2d(DATATYPE p_datatype,
                                           DATATYPE c_data_type, string &p_key);
  bool replace_one_from_datalibrary(DATATYPE datatype, string &old_str,
                                    string &new_str);
  bool remove_one_from_datalibrary(DATATYPE datatype, string &key);
  ~Mutator();
  void debug(IR *root);
  void debug(IR *root, unsigned level);
  // int try_fix(char *buf, int len, char *&new_buf, int &new_len);

  void add_ir_to_library_no_deepcopy(IR *);

  // added by vancir
  bool get_valid_str_from_lib(string &);
  vector<IR *> parse_query_str_get_ir_set(string &query_str) const;
  bool check_node_num(IR *root, unsigned int limit);
  vector<IR *> extract_statement(IR *root);
  void set_p_oracle(SQL_ORACLE *oracle) { this->p_oracle = oracle; }
  void set_dump_library(bool);
  int get_ir_libary_2D_hash_kStatement_size();
  bool is_stripped_str_in_lib(string stripped_str);

  void add_all_to_library(IR *, const vector<int> &, u8 (*run_target)(char **, u32, string,
                                                                      int, string&)=NULL);
  void add_all_to_library(IR *ir, u8 (*run_target)(char **, u32, string,
                                                   int, string&)=NULL) {
    vector<int> dummy_vec;
    add_all_to_library(ir, dummy_vec, run_target);
  }
  void add_all_to_library(string, const vector<int> &, u8 (*run_target)(char **, u32, string,
                                                                        int, string&)=NULL);
  void add_all_to_library(string whole_query_str, u8 (*run_target)(char **, u32, string,
                                                                   int, string&)=NULL) {
    vector<int> dummy_vec;
    add_all_to_library(whole_query_str, dummy_vec, run_target);
  }
  void add_to_valid_lib(IR *, string &, const bool, u8 (*run_target)(char **, u32, string,
                                                                     int, string&)=NULL);
  void add_to_library(IR *, string &, u8 (*run_target)(char **, u32, string,
                                                       int, string&)=NULL);
  void add_to_library_core(IR *, string *);
  int get_valid_collection_size();
  int get_cri_valid_collection_size();
  IR *get_from_libary_with_type(IRTYPE);
  IR *get_from_libary_with_left_type(IRTYPE);
  IR *get_from_libary_with_right_type(IRTYPE);

  IR *get_ir_with_type(const IRTYPE type_);
  bool add_missing_create_table_stmt(IR *);

  DATAAFFINITYTYPE get_nearby_data_affinity(IR* ir_to_fix, bool is_debug_info);
  bool instan_dependency(IR *cur_stmt_root, const vector<vector<IR *>> cur_stmt_ir_to_fix_vec,
                         bool is_debug_info = false);
  void instan_database_schema_name(IR* ir_to_fix, bool is_debug_info);
  void instan_table_name(IR* ir_to_fix, bool& is_replace_table, bool is_debug_info);
  void instan_table_alias_name(IR* ir_to_fix, IR* cur_stmt_root, bool is_alias_optional, bool is_debug_info);
  void instan_view_name(IR* ir_to_fix, bool is_debug_info);
  void instan_partition_name(IR* ir_to_fix, bool is_debug_info);
  void instan_index_name(IR* ir_to_fix, bool is_debug_info);
  void instan_column_name(IR* ir_to_fix, IR* cur_stmt_root, bool& is_replace_column, vector<IR*>& ir_to_deep_drop, bool is_debug_info);
  void instan_column_alias_name(IR* ir_to_fix, IR* cur_stmt_root, vector<IR*>& ir_to_deep_drop, bool is_debug_info);
  void instan_sql_type_name(IR* ir_to_fix, bool is_debug_info);
  void instan_foreign_table_name(IR* ir_to_fix, bool is_debug_info);
  void instan_statistic_name (IR* ir_to_fix, bool is_debug_info);
  void instan_sequence_name (IR* ir_to_fix, bool is_debug_info);
  void instan_constraint_name (IR* ir_to_fix, bool is_debug_info);
  void instan_family_name (IR* ir_to_fix, bool is_debug_info);
  void instan_literal (IR* ir_to_fix, IR* cur_stmt_root, vector<IR*>& ir_to_deep_drop, bool is_debug_info);
  void instan_storage_param (IR* ir_to_fix, vector<IR*>& ir_to_deep_drop, bool is_debug_info);
  void instan_func_expr (IR* ir_to_fix, vector<IR*>& ir_to_deep_drop, bool is_debug_info);
  void map_create_view (IR* ir_to_fix, IR* cur_stmt_root, const vector<vector<IR *>> cur_stmt_ir_to_fix_vec, bool is_debug_info);
  void map_create_view_column (IR* ir_to_fix, vector<IR*>& ir_to_deep_drop, bool is_debug_info);

  void remove_type_annotation(IR* cur_stmt_root, vector<IR*>& ir_to_deep_drop);
  void rollback_instan_lib_changes();


  DATAAFFINITYTYPE detect_str_affinity(string);

  void fix_col_type_rel_errors(IR* cur_stmt_root, string res_str, int trial=0, bool is_debug_info = false);
  void fix_instan_error(IR* cur_stmt_root, string res_str, int trial = 0, bool is_debug_info = false);

  IR *record_ = NULL;
  IR *mutated_root_ = NULL;
  map<IRTYPE, vector<IR *>> ir_library_;
  map<IRTYPE, set<unsigned long>> ir_library_hash_;
  set<unsigned long> global_hash_;

  // Common data libraries. Can be used globally for instantiation.
  vector<string> string_library_;
  set<unsigned long> string_library_hash_;
  vector<unsigned long> value_library_;

  vector<string> common_string_library_;
  set<IRTYPE> not_mutatable_types_;
  set<IRTYPE> string_types_;
  set<IRTYPE> int_types_;
  set<IRTYPE> float_types_;

  set<IRTYPE> safe_generate_type_;
  set<IRTYPE> split_stmt_types_;
  set<IRTYPE> split_substmt_types_;

  map<DATATYPE, vector<string>> data_library_;
  map<DATATYPE, map<string, map<DATATYPE, vector<string>>>> data_library_2d_;

  vector<string> all_saved_func_name;
  map<DATAAFFINITYTYPE, vector<string>> func_type_lib;
  map<string, vector<vector<DataAffinity>>> func_str_to_type_map;

  static vector<string> v_sys_column_name;
  static vector<string> v_sys_catalogs_name;

  // Save the mapping from the SET variable name to
  //    the mapped Data Affinity for the variable.
  static map<string, DataAffinity> set_session_lib;
  static vector<string> all_saved_set_session;

  // Save the mapping from the Storage Parameter variable name to
  //    the mapped Data Affinity for the variable.
  static map<string, DataAffinity> storage_param_lib;
  static vector<string> all_storage_param;

  /* New data library. SQLRight CockroachDB data instantiation. */
  static map<string, vector<string>>
      m_table2columns, m_table2columns_snapshot; // Global Table name to column name mapping.
  static map<string, vector<string>>
      m_table2index, m_table2index_snapshot;                   // Global table name to index mapping.
      // We do not save the index to column mapping because it seems unnecessary.
  static vector<string> v_table_names, v_table_names_snapshot; // All saved table names from previous statements.

  // All used table and view names in one query statement. The table names are typically defined in
  //    `FROM` statement.
  static vector<string>
      v_table_names_single;
  // All used column names in one query statement. The column names can be used to identify number
  // of parameters required for the VALUES clause etc.
  static vector<string> v_column_names_single;

  // All table names just created in the
  // current stmt but yet to be transmitted into v_table_names.
  static vector<string>
      v_create_table_names_single;
  static vector<string>
      v_create_view_names_single;
  /* Alias names are always local to one statement. */

  // All alias name local to one query statement.
  // Can be used for quick alias name random referencing.
  // Clean up after every single query statement.
  static vector<string> v_table_alias_names_single;
  static vector<string> v_column_alias_names_single;

  // Save the relationship between the table/column name to the alias name.
  static map<string, string> m_alias2table_single;
  static map<string, vector<string>> m_enforced_table2alias_single;
  static map<string, vector<string>> m_alias_table2column_single;
  // The column alias is used in limited situations, such as GROUP BY columns AS column_alias, or `SELECT SUM(column) AS c ...`
  // Maybe also from `WITH` clause?
  static map<string, string> m_alias2column_single;

  // A mapping from the column name to the datatype class.
  // The datatype class is also responsible to handle literal mutation.
  static map<string, DataAffinity> m_column2datatype, m_column2datatype_snapshot;
  static map<DATAAFFINITYTYPE, vector<string>> m_datatype2column, m_datatype2column_snapshot;

  // A mapping to save all literals that is used inside the
  // whole SQL sequence. It maps the data type to pre-defined
  // literal string.
  static map<DATAAFFINITYTYPE, vector<string>> m_datatype2literals, m_datatype2literals_snapshot;

  // All used table names follow type in one query stmt.
  static vector<string>
      v_statistics_name, v_statistics_name_snapshot; // All statistic names defined in the current SQL.
  static vector<string>
      v_sequence_name, v_sequence_name_snapshot; // All sequence names defined in the current SQL.
  static vector<string>
      v_constraint_name, v_constraint_name_snapshot; // All constraint names defined in the current SQL.
  static vector<string>
      v_family_name, v_family_name_snapshot; // All family names defined in the current SQL.

  // The purpose to have a vector of view names is because for DROP statement,
  // ALTER stmts etc, mixed with view names and table names are not appropriate.
  static vector<string> v_view_name, v_view_name_snapshot; // All saved view names.
  static vector<string> v_foreign_table_name, v_foreign_table_name_snapshot; // All foreign table names defined
                                              // inthe current SQL.
  static vector<string>
      v_table_with_partition, v_table_with_partition_snapshot; // All table names that contiains TABLE
                                   // PARTITIONING.
  static map<string, vector<string>> m_table2partition, m_table2partition_snapshot;

  static vector<int> v_int_literals, v_int_literals_snapshot;
  static vector<double> v_float_literals, v_float_literals_snapshot;
  static vector<string> v_string_literals, v_string_literals_snapshot;


  // added by vancir
  map<unsigned long, bool> norec_hash;
  vector<string *> all_valid_pstr_vec;
  vector<string *> all_cri_valid_pstr_vec;
  set<string *> all_query_pstr_set;
  bool dump_library = false;
  SQL_ORACLE *p_oracle;
  map<IRTYPE, set<unsigned long>> ir_libary_2D_hash_;
  set<unsigned long> stripped_string_hash_;

  /* The interface of saving the required context for the mutator. Giving the
    IRTYPE, we should be able to extract all the related IR nodes from this
    library. The string* points to the string of the complete query stmt where
    the current NODE is from. And the int is the unique ID for the specific
    node, can be used to identify and extract the specific node from the IR
    tree when the tree is being reconstructed.
  */
  map<IRTYPE, vector<pair<string *, int>>> real_ir_set;
  map<IRTYPE, vector<pair<string *, int>>> left_lib_set;
  map<IRTYPE, vector<pair<string *, int>>> right_lib_set;

  /* This is the interface used for saving the mapping between detected
   * data types and its mapped query node. The logic is similar to the
   * IR mutation, as shown above. And it re-use the saving string* to
   * save the extra memory space.
   * */
  map<uint64_t, vector<pair<string *, int>>> data_affi_set;

  static set<IR *> visited;

  void setup_arguments_for_run_target(char** in_argv, u32 exec_tmout_in) {this->argv_for_run_target = in_argv; this->exec_tmout_for_run_target = exec_tmout_in; }

private:

    // Some helper function to fix the instantiation problems from the error messages.
    void fix_literal_op_err(IR* cur_stmt_root, string res_str, bool is_debug_info = false);
    void fix_column_literal_op_err(IR* cur_stmt_root, string res_str, bool is_debug_info = false);
    char** argv_for_run_target;
    u32 exec_tmout_for_run_target;

    // Auto-detect the data types from any query expressions or subqueries.
    void auto_mark_data_types_from_select_stmt(IR* cur_stmt_root, char **argv, u32 exec_tmout, int is_reset_server, u8 (*run_target)(char **, u32, string,
                                                                                                                                     int, string&), bool is_debug_info = false);
    void auto_mark_data_types_from_non_select_stmt(IR* cur_stmt_root, char **argv, u32 exec_tmout, int is_reset_server, u8 (*run_target)(char **, u32, string,
                                                                                                                                     int, string&), bool is_debug_info = false);
    void label_ir_data_type_from_err_msg(IR* ir, string& err_msg, bool& is_syntax_error);

    inline IR* get_ir_node_from_data_affi_pair(const pair<string*, int>&);
};

#endif
