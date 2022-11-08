#include "../include/ast.h"
#include "../include/utils.h"
#include <algorithm>
#include <cassert>
#include <iomanip>
#include <iostream>
#include <sstream>

string get_string_by_ir_type(IRTYPE type) {

#define DECLARE_CASE(classname)                                                \
  if (type == classname)                                                       \
    return #classname;
  ALLTYPE(DECLARE_CASE);
#undef DECLARE_CASE

  return "";
}

string get_string_by_data_type(DATATYPE type) {

#define DECLARE_CASE(classname)                                                \
  if (type == classname)                                                       \
    return #classname;
  ALLDATATYPE(DECLARE_CASE);
#undef DECLARE_CASE

  return "";
}

string get_string_by_data_flag(DATAFLAG flag_type_) {
#define DECLARE_CASE(classname)                                                \
  if (flag_type_ == classname)                                                 \
    return #classname;
  ALLCONTEXTFLAGS(DECLARE_CASE);
#undef DECLARE_CASE
  return "";
}

DATATYPE get_datatype_by_string(string s) {
#define DECLARE_CASE(datatypename)                                             \
  if (s == #datatypename)                                                      \
    return datatypename;
  ALLDATATYPE(DECLARE_CASE);
#undef DECLARE_CASE

  string err = "\n\n\nError: Cannot find the matching data type by"
               " string: " + s + " \n\n\n";
  cerr << err;
//  abort();
  return DataUnknownType;
}

FUNCTIONTYPE get_functype_by_string(string s) {
  #define DECLARE_CASE(functiontypename)                                             \
    if (s == #functiontypename)                                                      \
      return functiontypename;
    ALLFUNCTIONTYPES(DECLARE_CASE);
  #undef DECLARE_CASE
    string err = "\n\n\nError: Cannot find the matching function type by"
                 " string: " + s + " \n\n\n";
    cerr << err;
//    abort();
    return FUNCUNKNOWN;
}

string get_string_by_option_type(RelOptionType type) {
  switch (type) {
  case Unknown:
    return "option_unknown";
  case StorageParameters:
    return "option_storageParameters";
  case SetConfigurationOptions:
    return "option_setConfigurationOptions";
  }
  return "option_unknown";
}

void deep_delete(IR *root) {
  if (root->left_)
    deep_delete(root->left_);
  if (root->right_)
    deep_delete(root->right_);

  if (root->op_)
    delete root->op_;

  delete root;
}

IR *deep_copy(const IR *root) {
  IR *left = NULL, *right = NULL, *copy_res;

  if (root->left_)
    left = deep_copy(root->left_);
  if (root->right_)
    right = deep_copy(root->right_);

  copy_res = new IR(root, left, right);

  return copy_res;
}

string IR::to_string() {
  string res = "";
  to_string_core(res);
  trim_string(res);
  return res;
}

/* Very frequently called. Must be very fast. */
void IR::to_string_core(string &res) {

  switch (type_) {
  case TypeIntegerLiteral:
    if (str_val_ != "") {
      res += str_val_;
    } else {
      res += std::to_string(int_val_);
    }
    return;
  case TypeFloatLiteral:
    if (str_val_ != "") {
      res += str_val_;
    } else {
      std::stringstream stream;
      stream << std::fixed << std::setprecision(2) << float_val_;
      res += stream.str();
    }
    return;
    //  case kBoolLiteral:
    //    if (str_val_ != "") {
    //      res += str_val_;
    //    }  else {
    //      if (bool_val_) {
    //        res += " TRUE ";
    //      } else {
    //        res += " FALSE ";
    //      }
    //    }
    //    return;
  case TypeIdentifier:
    if (str_val_ != "") {
      if (data_type_ == DataFunctionName) {
        std::transform(str_val_.begin(), str_val_.end(), str_val_.begin(),
                       ::toupper);
      }
      res += str_val_;
    }
    return;
  case TypeStringLiteral:
//    res += "'" + str_val_ + "'";
    res += str_val_;
    return;
  }

  // if (type_ == kFuncArgs && str_val_ != "") {
  //   res += str_val_;
  //   return;
  // }

  /* If we have str_val setup, directly return the str_val_; */
  if (str_val_ != "") {
    res += str_val_;
    return;
  }

  if (op_) {
    res += op_->prefix_;
    // res += " ";
  }

  if (left_) {
    left_->to_string_core(res);
    // res += " ";
  }

  if (op_) {
    res += op_->middle_;
    // res += +" ";
  }

  if (right_) {
    right_->to_string_core(res);
    // res += " ";
  }

  if (op_)
    res += op_->suffix_;

  return;
}

bool IR::detach_node(IR *node) { return swap_node(node, NULL); }

bool IR::swap_node(IR *old_node, IR *new_node) {
  if (old_node == NULL)
    return false;

  IR *parent = this->locate_parent(old_node);

  if (parent == NULL)
    return false;
  else if (parent->left_ == old_node)
    parent->update_left(new_node);
  else if (parent->right_ == old_node)
    parent->update_right(new_node);
  else
    return false;

  old_node->parent_ = NULL;

  return true;
}

IR *IR::locate_parent(IR *child) {

  for (IR *p = child; p; p = p->parent_)
    if (p->parent_ == this)
      return child->parent_;

  return NULL;
}

IR *IR::get_root() {

  IR *node = this;

  while (node->parent_ != NULL)
    node = node->parent_;

  return node;
}

IR *IR::get_parent() { return this->parent_; }

void IR::update_left(IR *new_left) {

  // we do not update the parent_ of the old left_
  // we do not update the child of the old parent_ of new_left

  this->left_ = new_left;
  if (new_left)
    new_left->parent_ = this;
}

void IR::update_right(IR *new_right) {

  // we do not update the parent_ of the old right_
  // we do not update the child of the old parent_ of new_right

  this->right_ = new_right;
  if (new_right)
    new_right->parent_ = this;
}

void IR::drop() {

  if (this->op_)
    delete this->op_;
  delete this;
}

void IR::deep_drop() {

  if (this->left_)
    this->left_->deep_drop();

  if (this->right_)
    this->right_->deep_drop();

  this->drop();
}

IR *IR::deep_copy() {

  IR *left = NULL, *right = NULL, *copy_res;
  IROperator *op = NULL;

  if (this->left_)
    left = this->left_->deep_copy();
  if (this->right_)
    right = this->right_->deep_copy();

  if (this->op_)
    op = OP3(this->op_->prefix_, this->op_->middle_, this->op_->suffix_);

  copy_res = new IR(this->type_, op, left, right, this->float_val_,
                    this->str_val_, this->name_, this->mutated_times_);
  copy_res->data_type_ = this->data_type_;
  copy_res->data_flag_ = this->data_flag_;
  copy_res->data_affinity_type = this->data_affinity_type;
  copy_res->data_affinity = this->data_affinity;
  copy_res->option_type_ = this->option_type_;

  return copy_res;
}

string IR::get_prefix() {
  if (op_) {
    return op_->prefix_;
  }
  return "";
}

string IR::get_middle() {
  if (op_) {
    return op_->middle_;
  }
  return "";
}

string IR::get_suffix() {
  if (op_) {
    return op_->suffix_;
  }
  return "";
}

string IR::get_str_val() { return str_val_; }

bool IR::is_empty() {
  if (op_) {
    if (op_->prefix_ != "" || op_->middle_ != "" || op_->suffix_ != "") {
      return false;
    }
  }
  if (str_val_ != "") {
    return false;
  }
  if (left_ || right_) {
    return false;
  }
  return true;
}

void IR::set_str_val(string in) { str_val_ = in; }

IRTYPE IR::get_ir_type() { return type_; }

DATATYPE IR::get_data_type() { return data_type_; }

DATAFLAG IR::get_data_flag() { return data_flag_; }

DATAAFFINITYTYPE IR::get_data_affinity() {return this->data_affinity_type;}

IR *IR::get_left() { return left_; }

IR *IR::get_right() { return right_; }

void IR::set_ir_type(IRTYPE type) { this->type_ = type; }

void IR::set_data_type(DATATYPE data_type) { this->data_type_ = data_type; }

void IR::set_data_flag(DATAFLAG data_flag) { this->data_flag_ = data_flag; }

void IR::set_data_affinity(DATAAFFINITYTYPE data_affinity) {
//    cerr << "\n\n\nNode: "<< this->to_string() << ", setting data affinity "
//                          <<  get_string_by_affinity_type(data_affinity) << "AFFIKNONW.\n\n\n";
    this->data_affinity_type = data_affinity;
    this->data_affinity.set_data_affinity(data_affinity);
}

void IR::set_data_affinity(DataAffinity data_affinity) {
//    cerr << "\n\n\nSetting data_affinity: " << get_string_by_affinity_type(data_affinity.get_data_affinity()) << "\n\n\n";
    this->data_affinity_type = data_affinity.get_data_affinity();
    this->data_affinity = data_affinity;
}

bool IR::set_type(DATATYPE data_type, DATAFLAG data_flag, DATAAFFINITYTYPE data_affi) {

  /* Set type regardless of the node type. Do not use this unless necessary. */
  this->set_data_type(data_type);
  this->set_data_flag(data_flag);
  this->set_data_affinity(data_affi);

  return true;
}

DATAAFFINITYTYPE IR::detect_cur_data_type(bool is_override) {

    /* TODO::FIXME Not a correct logic. Need to double check on these commented out code. */
//    if (this->get_ir_type() != TypeStringLiteral && this->get_ir_type() != TypeIdentifier) {
//        cerr << "Trying the detect data_type on non-string and non-identifier.";
//        return AFFIUNKNOWN;
//    }

    // If not overriding, return the already-setup data affinity type.
    if (!is_override && this->get_data_affinity() != AFFIUNKNOWN) {
        return this->get_data_affinity();
    }

    // Actual detection of the data affinity using the str_val_
    // TODO::FIXME:: Do we need to consider TypeIdentifier here?
    DATAAFFINITYTYPE detected_affinity = this->data_affinity.recognize_data_type(this->str_val_);
    this->data_affinity_type = detected_affinity;

    return detected_affinity;
}

bool IR::func_name_set_str(string in) {
  assert(get_ir_type() == TypeIdentifier &&
         get_data_type() == DataFunctionName);
  set_str_val(in);
  return true;
}

bool IR::replace_op(IROperator *op_in) {
  if (this->op_) {
    delete this->op_;
  }

  this->op_ = op_in;

  return true;
}

void IR::mutate_literal_random_affinity() {
    auto random_affi = get_random_affinity_type();
    this->set_data_affinity(random_affi);
    this->mutate_literal();
    return;
}
// Main literal mutate function.
void IR::mutate_literal() {
    // Upon calling this function, we should assume the Data affinity has been set up correctly.
    if (this->data_affinity_type == AFFIUNKNOWN || this->data_affinity.get_data_affinity() == AFFIUNKNOWN) {
        cerr << "\n\n\nTrying to mutate literal on IR that has Unknown data affinity. \n\n\n";
        cerr << "this->data_affinity_type: " << get_string_by_affinity_type(this->data_affinity_type);
        cerr << ", this->data_affinity.get_data_affinity(): " << get_string_by_affinity_type(this->data_affinity.get_data_affinity());
//        abort();
        this->set_data_affinity(AFFISTRING);
    }

    this->set_str_val(this->data_affinity.get_mutated_literal());
    this->float_val_ = 0.0;
    this->int_val_ = 0;
    if (this->op_) {
        this->op_->prefix_ = "";
        this->op_->suffix_ = "";
        this->op_->middle_ = "";
    }
    if (this->get_left()) {
        this->get_left()->deep_drop();
        this->update_left(NULL);
    }
    if (this->get_right()) {
        this->get_right()->deep_drop();
        this->update_right(NULL);
    }

    return;
}
