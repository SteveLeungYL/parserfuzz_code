#ifndef __AST_H__
#define __AST_H__

#include "../AFL/config.h"
#include "define.h"
#include <cstring>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <map>
#include <set>
#include <string>
#include <vector>

using namespace std;

#define DECLARE_CLASS(v) class v;

ALLCLASS(DECLARE_CLASS);
#undef DECLARE_CLASS

//#include "../parser/bison_parser.h"
//#include "../parser/flex_lexer.h"

#define reset_counter() g_id_counter = 0;

static unsigned long g_id_counter;

static inline void clear_id() { g_id_counter = 0; }

static string gen_id_name() { return "v" + to_string(g_id_counter++); }
static string gen_table_name() { return "t" + to_string(g_id_counter++); }
static string gen_column_name() { return "c" + to_string(g_id_counter++); }
static string gen_index_name() { return "i" + to_string(g_id_counter++); }
static string gen_alias_name() { return "a" + to_string(g_id_counter++); }
static string gen_window_name() { return "w" + to_string(g_id_counter++); }

enum CASEIDX {
  CASE0,
  CASE1,
  CASE2,
  CASE3,
  CASE4,
  CASE5,
  CASE6,
  CASE7,
  CASE8,
  CASE9,
  CASE10,
  CASE11,
  CASE12,
  CASE13,
  CASE14,
  CASE15,
  CASE16,
  CASE17,
  CASE18,
  CASE19,
};

enum NODETYPE {
#define DECLARE_TYPE(v) v,
  ALLTYPE(DECLARE_TYPE)
#undef DECLARE_TYPE
};

enum IDTYPE {
  id_whatever,

  id_create_table_name,
  id_create_view_name,
  id_view_name,
  id_create_table_name_with_tmp,  // In with clause, the table_name created are
                                  // temporary. Only effective for one single
                                  // stmt. Thus the id_type_.
  id_create_column_name_with_tmp, // In with clause, the column_name created are
                                  // temporary. Only effective for one single
                                  // stmt. Thus the id_type_.
  id_top_table_name,
  id_table_name,

  id_create_column_name,
  id_column_name,
  id_top_column_name,

  id_pragma_name,
  id_pragma_value,

  id_create_index_name,
  id_index_name,

  id_create_trigger_name,
  id_trigger_name,

  id_create_window_name,
  id_window_name,
  id_base_window_name,

  id_create_savepoint_name,
  id_savepoint_name,

  id_schema_name,
  id_vtab_module_name,
  id_collation_name,
  id_database_name,
  id_alias_name,
  id_table_alias_name,
  id_column_alias_name,
  id_function_name,
  id_table_constraint_name,
  id_transaction_name
};

typedef NODETYPE IRTYPE;

class GramCovMap {

public:
  GramCovMap() {
    this->block_cov_map = new unsigned char[MAP_SIZE]();
    memset(this->block_cov_map, 0, MAP_SIZE);
    this->block_virgin_map = new unsigned char[MAP_SIZE]();
    memset(this->block_virgin_map, 0xff, MAP_SIZE);

    this->edge_cov_map = new unsigned char[MAP_SIZE]();
    memset(this->edge_cov_map, 0, MAP_SIZE);
    this->edge_virgin_map = new unsigned char[MAP_SIZE]();
    memset(this->edge_virgin_map, 0xff, MAP_SIZE);
    edge_prev_cov = 0;
  }
  ~GramCovMap() {
    delete[](this->block_cov_map);
    delete[](this->block_virgin_map);
    delete[](this->edge_cov_map);
    delete[](this->edge_virgin_map);
  }

  u8 has_new_grammar_bits(bool is_debug = false, const string in = "") {
//    has_new_grammar_bits(this->block_cov_map, this->block_virgin_map, is_debug);
    return has_new_grammar_bits(this->edge_cov_map, this->edge_virgin_map, is_debug, in);
  }
  u8 has_new_grammar_bits(u8 *, u8 *, bool is_debug = false, const string in = "");

  void reset_block_cov_map() { memset(this->block_cov_map, 0, MAP_SIZE); }
  void reset_block_virgin_map() { memset(this->block_virgin_map, 0, MAP_SIZE); }

  void reset_edge_cov_map() {
    memset(this->edge_cov_map, 0, MAP_SIZE);
    edge_prev_cov = 0;
  }
  void reset_edge_virgin_map() {
    memset(this->edge_virgin_map, 0, MAP_SIZE);
    edge_prev_cov = 0;
  }

  void log_cov_map(unsigned int cur_cov) {
    unsigned int offset = (edge_prev_cov ^ cur_cov);
    if (edge_cov_map[offset] < 0xff) {
      edge_cov_map[offset]++;
    }
    edge_prev_cov = (cur_cov >> 1);

    if (block_cov_map[cur_cov] < 0xff) {
      block_cov_map[cur_cov]++;
    }
  }

  inline double get_total_block_cov_size() {
    u32 t_bytes = this->count_non_255_bytes(this->block_virgin_map);
    return ((double)t_bytes * 100.0) / MAP_SIZE;
  }
  inline u32 get_total_block_cov_size_num() {
    return this->count_non_255_bytes(this->block_virgin_map);
  }

  inline double get_total_edge_cov_size() {
    u32 t_bytes = this->count_non_255_bytes(this->edge_virgin_map);
    return ((double)t_bytes * 100.0) / MAP_SIZE;
  }
  inline u32 get_total_edge_cov_size_num() {
    return this->count_non_255_bytes(this->edge_virgin_map);
  }

  unsigned char *get_edge_cov_map() { return this->edge_cov_map; }

private:
  unsigned char *block_cov_map = nullptr;
  unsigned char *block_virgin_map = nullptr;
  unsigned char *edge_cov_map = nullptr;
  unsigned char *edge_virgin_map = nullptr;
  unsigned int edge_prev_cov;

  /* Count the number of non-255 bytes set in the bitmap. Used strictly for the
   status screen, several calls per second or so. */
  // Copy from afl-fuzz.
  u32 count_non_255_bytes(u8 *mem);

  inline vector<u8> get_cur_new_byte(u8 *cur, u8 *vir) {
    vector<u8> new_byte_v;
    for (u8 i = 0; i < 8; i++) {
      if (cur[i] && vir[i] == 0xff)
        new_byte_v.push_back(i);
    }
    return new_byte_v;
  }

  inline void gram_log_map_id (u32 i, u8 byte, const string in = "") {
    fstream gram_id_out;
    i = (MAP_SIZE >> 3) - i - 1 ;
    u32 actual_idx = i * 8 + byte;

    if (!filesystem::exists("./gram_cov.txt")) {
      gram_id_out.open("./gram_cov.txt", std::fstream::out |
      std::fstream::trunc);
    } else {
      gram_id_out.open("./gram_cov.txt", std::fstream::out |
      std::fstream::app);
    }
    gram_id_out << actual_idx << endl;
    gram_id_out.flush();
    gram_id_out.close();

    if (!filesystem::exists("./new_gram_file/")) {
      filesystem::create_directory("./new_gram_file/");
    }
    fstream map_id_seed_output;
    map_id_seed_output.open(
        "./new_gram_file/" + to_string(actual_idx) + ".txt",
        std::fstream::out | std::fstream::trunc);
    map_id_seed_output << in;
    map_id_seed_output.close();

  }
};

class IROperator {
public:
  IROperator(const string prefix = "", const string middle = "",
             const string suffix = "")
      : prefix_(prefix), middle_(middle), suffix_(suffix) {}

  string prefix_;
  string middle_;
  string suffix_;
};

class IR {
public:
  IR(IRTYPE type, IROperator *op, IR *left = NULL, IR *right = NULL)
      : type_(type), op_(op), left_(left), right_(right), parent_(NULL),
        operand_num_((!!right) + (!!left)), id_type_(id_whatever) {
    if (left_)
      left_->parent_ = this;
    if (right_)
      right_->parent_ = this;
  }

  IR(IRTYPE type, string str_val, IDTYPE id_type = id_whatever)
      : type_(type), str_val_(str_val), op_(NULL), left_(NULL), right_(NULL),
        parent_(NULL), operand_num_(0), id_type_(id_type) {}

  IR(IRTYPE type, bool b_val)
      : type_(type), b_val_(b_val), left_(NULL), op_(NULL), right_(NULL),
        parent_(NULL), operand_num_(0), id_type_(id_whatever) {}

  IR(IRTYPE type, unsigned long int_val)
      : type_(type), int_val_(int_val), left_(NULL), op_(NULL), right_(NULL),
        parent_(NULL), operand_num_(0), id_type_(id_whatever) {}

  IR(IRTYPE type, double f_val)
      : type_(type), f_val_(f_val), left_(NULL), op_(NULL), right_(NULL),
        parent_(NULL), operand_num_(0), id_type_(id_whatever) {}

  IR(IRTYPE type, IROperator *op, IR *left, IR *right, double f_val,
     string str_val, unsigned int mutated_times)
      : type_(type), op_(op), left_(left), right_(right), parent_(NULL),
        operand_num_((!!right) + (!!left)), str_val_(str_val), f_val_(f_val),
        mutated_times_(mutated_times), id_type_(id_whatever) {
    if (left_)
      left_->parent_ = this;
    if (right_)
      right_->parent_ = this;
  }

  union {
    unsigned long int_val_;
    double f_val_;
    bool b_val_;
  };

  int uniq_id_in_tree_;
  IDTYPE id_type_;
  IRTYPE type_;
  string str_val_;
  IROperator *op_;
  IR *left_;
  IR *right_;
  IR *parent_;
  bool is_node_struct_fixed =
      false; // Do not mutate this IR if this set to be true.
  int operand_num_;
  unsigned int mutated_times_ = 0;
  string to_string();
  void _to_string(string &);

  // delete this IR and necessary clean up
  void drop();
  // delete the IR tree
  void deep_drop();
  // copy the IR tree
  IR *deep_copy();
  // find the parent node of child inside this IR tree
  IR *locate_parent(IR *child);
  // find the root node of this node
  IR *get_root();
  // find the parent node of this node
  IR *get_parent();
  // unlink the node from this IR tree, but keep the node
  bool detach_node(IR *node);
  // swap the node, keep both
  bool swap_node(IR *old_node, IR *new_node);

  void update_left(IR *);
  void update_right(IR *);

  inline bool is_empty() {
    if (this->str_val_.size() || this->left_ != nullptr ||
        this->right_ != nullptr || this->op_->prefix_.size() ||
        this->op_->middle_.size() || this->op_->suffix_.size()) {
      return false;
    }
    return true;
  }
};

string get_string_by_ir_type(IRTYPE);
string get_string_by_id_type(IDTYPE);

#endif
