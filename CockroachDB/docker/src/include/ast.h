#ifndef __AST_H__
#define __AST_H__

#include "define.h"
#include "data_affinity.h"
#include "relopt_generator.h"
#include <map>
#include <set>
#include <string>
#include <vector>

using namespace std;

enum IRTYPE {
#define DECLARE_TYPE(v) v,
  ALLTYPE(DECLARE_TYPE)
#undef DECLARE_TYPE
};

enum COLTYPE { UNKNOWN_T, INT_T, FLOAT_T, BOOLEAN_T, STRING_T };

enum DATATYPE {
#define DECLARE_TYPE(v) v,
  ALLDATATYPE(DECLARE_TYPE)
#undef DECLARE_TYPE
};

enum DATAFLAG {
#define DECLARE_TYPE(v) v,
  ALLCONTEXTFLAGS(DECLARE_TYPE)
#undef DECLARE_TYPE
};

enum FUNCTIONTYPE {
#define DECLARE_TYPE(v) v,
   ALLFUNCTIONTYPES(DECLARE_TYPE)
#undef DECLARE_TYPE
};

#define GEN_NAME() name_ = gen_id_name();

static unsigned long g_id_counter;

static inline void reset_id_counter() { g_id_counter = 0; }

static string gen_id_name() { return "v" + to_string(g_id_counter++); }
static string gen_column_name() { return "c" + to_string(g_id_counter++); }
static string gen_index_name() { return "i" + to_string(g_id_counter++); }
static string gen_table_alias_name() { return "ta" + to_string(g_id_counter++); }
static string gen_column_alias_name() { return "ca" + to_string(g_id_counter++); }
static string gen_statistic_name() { return "s" + to_string(g_id_counter++); }
static string gen_sequence_name() { return "seq" + to_string(g_id_counter++); }
static string gen_view_name() { return "view" + to_string(g_id_counter++); }
static string gen_view_column_name() { return "view_c" + to_string(g_id_counter++); }
static string gen_partition_name() { return "par" + to_string(g_id_counter++); }
static string gen_constraint_name() {return "constraint_" + to_string(g_id_counter++); }
static string gen_family_name() {return "family_" + to_string(g_id_counter++); }

string get_string_by_ir_type(IRTYPE type);
string get_string_by_data_type(DATATYPE type);
string get_string_by_option_type(RelOptionType);
string get_string_by_data_flag(DATAFLAG flag_type_);

class IROperator {
public:
  IROperator(string prefix = "", string middle = "", string suffix = "")
      : prefix_(prefix), middle_(middle), suffix_(suffix) {}

  string prefix_;
  string middle_;
  string suffix_;
};

class IR {
public:
  IR(IRTYPE type, IROperator *op, IR *left = NULL, IR *right = NULL)
      : type_(type), op_(op), left_(left), right_(right), parent_(NULL),
        operand_num_((!!right) + (!!left)), data_type_(DataNone), data_affinity_type(AFFIUNKNOWN), data_affinity(AFFIUNKNOWN) {
//    GEN_NAME();
    if (left_)
      left_->parent_ = this;
    if (right_)
      right_->parent_ = this;
  }

  IR(IRTYPE type, string str_val, DATATYPE data_type = DataNone,
     DATAFLAG flag = ContextUnknown, DATAAFFINITYTYPE data_affi = AFFIUNKNOWN)
      : type_(type), str_val_(str_val), op_(NULL), left_(NULL), right_(NULL),
        parent_(NULL), operand_num_(0), data_type_(data_type),
        data_flag_(flag), data_affinity_type(data_affi) {
    this->set_data_affinity(data_affi);
  }

  IR(IRTYPE type, bool b_val, DATATYPE data_type = DataNone,
     DATAFLAG flag = ContextUnknown, DATAAFFINITYTYPE data_affi = AFFIUNKNOWN)
      : type_(type), bool_val_(b_val), left_(NULL), op_(NULL), right_(NULL),
        parent_(NULL), operand_num_(0), data_type_(data_type),
        data_flag_(flag), data_affinity_type(data_affi) {
    this->set_data_affinity(data_affi);
  }

  IR(IRTYPE type, unsigned long long_val, DATATYPE data_type = DataNone,
     DATAFLAG flag = ContextUnknown, DATAAFFINITYTYPE data_affi = AFFIUNKNOWN)
      : type_(type), long_val_(long_val), left_(NULL), op_(NULL), right_(NULL),
        parent_(NULL), operand_num_(0), data_type_(data_type),
        data_flag_(flag), data_affinity_type(data_affi) {
    this->set_data_affinity(data_affi);
  }

  IR(IRTYPE type, int int_val, DATATYPE data_type = DataNone,
     DATAFLAG flag = ContextUnknown, DATAAFFINITYTYPE data_affi = AFFIUNKNOWN)
      : type_(type), int_val_(int_val), left_(NULL), op_(NULL), right_(NULL),
        parent_(NULL), operand_num_(0), data_type_(data_type),
        data_flag_(flag), data_affinity_type(data_affi) {
    this->set_data_affinity(data_affi);
  }

  IR(IRTYPE type, double f_val, DATATYPE data_type = DataNone,
     DATAFLAG flag = ContextUnknown, DATAAFFINITYTYPE data_affi = AFFIUNKNOWN)
      : type_(type), float_val_(f_val), left_(NULL), op_(NULL), right_(NULL),
        parent_(NULL), operand_num_(0), data_type_(data_type),
        data_flag_(flag), data_affinity_type(data_affi) {
    this->set_data_affinity(data_affi);
  }

  IR(IRTYPE type, IROperator *op, IR *left, IR *right, double f_val,
     string str_val, string name, unsigned int mutated_times,
     DATAFLAG flag = ContextUnknown, DATAAFFINITYTYPE data_affi = AFFIUNKNOWN)
      : type_(type), op_(op), left_(left), right_(right), parent_(NULL),
        operand_num_((!!right) + (!!left)), name_(name), str_val_(str_val),
        float_val_(f_val), mutated_times_(mutated_times), data_type_(DataNone),
        data_flag_(flag), data_affinity_type(data_affi) {
    if (left_)
      left_->parent_ = this;
    if (right_)
      right_->parent_ = this;
    this->set_data_affinity(data_affi);
  }

  IR(DATAAFFINITYTYPE data_affi): type_(TypeStringLiteral), str_val_(""), left_(NULL),
    right_(NULL), parent_(NULL) {
      this->set_data_affinity(data_affi);
      this->mutate_literal(data_affi);
  }

  IR(DataAffinity data_affi): type_(TypeStringLiteral), str_val_("") , left_(NULL),
                              right_(NULL), parent_(NULL) {
      this->set_data_affinity(data_affi);
      this->mutate_literal(data_affi);
  }

  IR(const IR *ir, IR *left, IR *right) {
    this->type_ = ir->type_;
    if (ir->op_ != NULL)
      this->op_ = OP3(ir->op_->prefix_, ir->op_->middle_, ir->op_->suffix_);
    else {
      this->op_ = OP0();
    }

    this->left_ = left;
    this->right_ = right;
    if (this->left_)
      this->left_->parent_ = this;
    if (this->right_)
      this->right_->parent_ = this;

    this->str_val_ = ir->str_val_;
    this->long_val_ = ir->long_val_;
    this->data_type_ = ir->data_type_;
    this->data_flag_ = ir->data_flag_;
    this->data_affinity = ir->data_affinity;
    this->data_affinity_type = ir->data_affinity_type;
    this->option_type_ = ir->option_type_;
    this->name_ = ir->name_;
    this->operand_num_ = ir->operand_num_;
    this->mutated_times_ = ir->mutated_times_;
    this->is_compact_expr = ir->is_compact_expr;
  }

  union {
    int int_val_;
    unsigned long long_val_;
    double float_val_;
    bool bool_val_;
  };

  int uniq_id_in_tree_ = -1;
  DATAFLAG data_flag_ = DATAFLAG::ContextUnknown;
  DATATYPE data_type_ = DATATYPE::DataNone;
  DATAAFFINITYTYPE data_affinity_type;
  DataAffinity data_affinity;

  RelOptionType option_type_ = RelOptionType::Unknown;
  IRTYPE type_;
  string name_;

  string str_val_;

  IROperator *op_;
  IR *left_;
  IR *right_;
  IR *parent_;
  bool is_node_struct_fixed =
      false; // Do not mutate this IR if this set to be true.
  int operand_num_;
  unsigned int mutated_times_ = 0;
  bool is_instantiated = false;
  bool is_compact_expr = false;

  string to_string();
  void to_string_core(string &);

  bool get_is_instantiated() { return this->is_instantiated; }
  void set_is_instantiated(const bool& in) {this->is_instantiated = in; return;}

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

  string get_prefix();
  string get_middle();
  string get_suffix();
  string get_str_val();

  IR *get_left();
  IR *get_right();

  IRTYPE get_ir_type();
  DATATYPE get_data_type();
  DATAFLAG get_data_flag();
  DATAAFFINITYTYPE get_data_affinity();
  RelOptionType get_rel_option_type();

  void mutate_literal_random_affinity();
  void mutate_literal(DATAAFFINITYTYPE data_affi){ this->set_data_affinity(data_affi); this->mutate_literal(); }
  void mutate_literal(DataAffinity data_affi){ this->set_data_affinity(data_affi); this->mutate_literal(); }

  // Main literal mutate function.
  void mutate_literal();

  bool is_empty();

  void set_str_val(string);

  void set_ir_type(IRTYPE);
  void set_data_type(DATATYPE);
  void set_data_flag(DATAFLAG);
  void set_data_affinity(DATAAFFINITYTYPE);
  void set_data_affinity(DataAffinity);

  DATAAFFINITYTYPE detect_cur_data_type(bool is_override = true);

  /* helper functions for the IR type */

  // Return is_succeed.
  bool set_type(DATATYPE, DATAFLAG, DATAAFFINITYTYPE data_affi = AFFIUNKNOWN); // Set type regardless of its node type.
  bool func_name_set_str(string);

  bool replace_op(IROperator *);

  void set_is_compact_expr(bool in) {this->is_compact_expr = in;}
  bool get_is_compact_expr() {return this->is_compact_expr;}

  /* From the kTypename ir, return the int representing the Postgres column
   * type.
   */
  COLTYPE typename_ir_get_type();
};

DATATYPE get_datatype_by_string(string s);
FUNCTIONTYPE get_functype_by_string(string s);

IR *deep_copy(const IR *root);

void deep_delete(IR *root);

#endif
