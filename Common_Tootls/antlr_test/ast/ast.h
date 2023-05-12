//
// Created by Yu Liang on 5/12/23.
//

#ifndef ANTLR_TEST_AST_H
#define ANTLR_TEST_AST_H

#include "../grammar_IR_constructor/all_rule_declares.h"
#include <string>

using namespace std;

void trim_string(std::string &res);

#define OP1(a) \
    new IROperator(a)

#define OP2(a, b) \
    new IROperator(a,b)

#define OP3(a,b,c) \
    new IROperator(a,b,c)

#define OPSTART(a) \
    new IROperator(a)

#define OPMID(a) \
new IROperator("", a, "")

#define OPEND(a) \
    new IROperator("", "", a)

#define OP0() \
    new IROperator()

enum IRTYPE {
#define DECLARE_TYPE(v) v,
  ALLTYPE(DECLARE_TYPE)
#undef DECLARE_TYPE
};

enum DATAFLAG {
#define DECLARE_TYPE(v) v,
  ALLDATAFLAG(DECLARE_TYPE)
#undef DECLARE_TYPE
};

enum DATATYPE {
#define DECLARE_TYPE(v) v,
  ALLDATATYPE(DECLARE_TYPE)
#undef DECLARE_TYPE
};


class IROperator{
public:
  IROperator(string prefix="", string middle="", string suffix=""):
    prefix_(prefix), middle_(middle), suffix_(suffix) {}

  string prefix_;
  string middle_;
  string suffix_;
};


class IR{
public:
  IR(IRTYPE type,  IROperator * op, IR * left=NULL, IR* right=NULL):
                                                                       type_(type), op_(op), left_(left), right_(right), operand_num_((!!right)+(!!left)), data_type_(kDataWhatever){
    name_ = "v0";
    if (left_)
      left_->parent_ = this;
    if (right_)
      right_->parent_ = this;
  }

  IR(IRTYPE type, string str_val, DATATYPE data_type=kDataWhatever, int scope = -1, DATAFLAG flag = kUse):
                                                                                                                   type_(type), str_val_(str_val), op_(NULL), left_(NULL), right_(NULL), operand_num_
                                                                                                                   (0), data_type_(data_type), scope_(scope) , data_flag_(flag){
    name_ = "v0";
    if (left_)
      left_->parent_ = this;
    if (right_)
      right_->parent_ = this;
  }

  IR(IRTYPE type, bool b_val, DATATYPE data_type=kDataWhatever, int scope = -1, DATAFLAG flag = kUse):
                                                                                                          type_(type), bool_val_(b_val),left_(NULL), op_(NULL), right_(NULL), operand_num_(0), data_type_(kDataWhatever), scope_(scope) , data_flag_(flag){
    name_ = "v0";
    if (left_)
      left_->parent_ = this;
    if (right_)
      right_->parent_ = this;
  }

  IR(IRTYPE type, unsigned long long_val, DATATYPE data_type=kDataWhatever, int scope = -1, DATAFLAG flag = kUse):
                                                                                                                      type_(type), long_val_(long_val),left_(NULL), op_(NULL), right_(NULL), operand_num_(0), data_type_(kDataWhatever), scope_(scope) , data_flag_(flag){
    name_ = "v0";
    if (left_)
      left_->parent_ = this;
    if (right_)
      right_->parent_ = this;
  }

  IR(IRTYPE type, int int_val, DATATYPE data_type=kDataWhatever, int scope = -1, DATAFLAG flag = kUse):
                                                                                                           type_(type), int_val_(int_val),left_(NULL), op_(NULL), right_(NULL), operand_num_(0), data_type_(kDataWhatever), scope_(scope) , data_flag_(flag){
    name_ = "v0";
    if (left_)
      left_->parent_ = this;
    if (right_)
      right_->parent_ = this;
  }

  IR(IRTYPE type, double f_val, DATATYPE data_type=kDataWhatever, int scope = -1, DATAFLAG flag = kUse):
                                                                                                            type_(type), float_val_(f_val),left_(NULL), op_(NULL), right_(NULL), operand_num_(0), data_type_(kDataWhatever), scope_(scope) , data_flag_(flag){
    name_ = "v0";
    if (left_)
      left_->parent_ = this;
    if (right_)
      right_->parent_ = this;
  }

  IR(IRTYPE type, IROperator * op, IR * left, IR* right, double f_val, string str_val, string name, unsigned int mutated_times, int scope, DATAFLAG flag):
                                                                                                                                                                    type_(type), op_(op), left_(left), right_(right), operand_num_((!!right)+(!!left)), name_(name), str_val_(str_val),
                                                                                                                                                                    float_val_(f_val), mutated_times_(mutated_times), data_type_(kDataWhatever), scope_(scope), data_flag_(flag){
    if (left_)
      left_->parent_ = this;
    if (right_)
      right_->parent_ = this;
  }

  IR(const IR* ir, IR* left, IR* right){
    this->type_ = ir->type_;
    if(ir->op_ != NULL)
      this->op_ = OP3(ir->op_->prefix_, ir->op_->middle_, ir->op_->suffix_);
    else{
      this->op_ = OP0();
    }
    this->left_ = left;
    this->right_ = right;
    this->str_val_ = ir->str_val_;
    this->long_val_ = ir->long_val_;
    this->data_type_ = ir->data_type_;
    this->scope_ = ir->scope_;
    this->data_flag_ = ir->data_flag_;
    this->name_ = ir->name_;
    this->operand_num_ = ir->operand_num_;
    this->mutated_times_ = ir->mutated_times_;

    if (left_)
      left_->parent_ = this;
    if (right_)
      right_->parent_ = this;

  }

  union{
    int int_val_;
    unsigned long long_val_;
    double float_val_;
    bool bool_val_;
  };

  bool is_node_struct_fixed = false; // Do not mutate this IR if this set to be true.
  bool is_mutating = false;

  IR* deep_copy();
  void drop();
  void deep_drop();

  IR* get_left();
  IR* get_right();
  string get_prefix();
  string get_middle();
  string get_suffix();
  void set_prefix(string in);
  void set_middle(string in);
  void set_suffix(string in);
  IR* get_parent();

  bool update_left(IR*);
  bool update_right(IR*);
  bool swap_node(IR*, IR*);
  bool detatch_node(IR*);

  bool is_empty();

  IR* locate_parent(IR*);
  IR* get_root();


  IRTYPE get_ir_type();
  DATATYPE get_data_type();
  void set_data_type(DATATYPE);
  DATAFLAG get_data_flag();
  void set_data_flag(DATAFLAG);

  string get_str_val();
  void set_str_val(string);

  int scope_;
  DATAFLAG data_flag_;
  DATATYPE data_type_;
  IRTYPE type_;
  string name_;

  string str_val_;
  //int int_val_ = 0xdeadbeef;
  //double float_val_ = 1.234;

  int uniq_id_in_tree_ = -1;

  IROperator* op_ = NULL;
  IR* left_ = NULL;
  IR* right_ = NULL;
  IR* parent_ = NULL;
  int operand_num_;
  unsigned int mutated_times_ = 0;

  string to_string();
  string to_string_core();

  /* Do not use this func unless necessary (don't know the IR type. ) */
  bool set_ir_type(IRTYPE in) {this->type_ = in; return true;}
  bool set_type(DATATYPE data_type, DATAFLAG data_flag) {
    this->set_data_type(data_type);
    this->set_data_flag(data_flag);
    return true;
  }
};


string get_string_by_ir_type(IRTYPE);
string get_string_by_data_type(DATATYPE);
string get_string_by_data_flag(DATAFLAG type);

#endif // ANTLR_TEST_AST_H
