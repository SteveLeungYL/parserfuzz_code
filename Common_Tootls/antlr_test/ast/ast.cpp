#include "ast.h"

// remove leading and ending spaces
// reduce 2+ spaces to one
// change ' ;' to ';'
void trim_string(std::string &res) {

  // string::iterator new_end = unique(res.begin(), res.end(), BothAreSpaces);
  // res.erase(new_end, res.end());

  // res.erase(0, res.find_first_not_of(' '));
  // res.erase(res.find_last_not_of(' ') + 1);

  int effect_idx = 0, idx = 0;
  bool prev_is_space = false;
  int sz = res.size();

  // skip leading spaces
  for (; idx < sz && res[idx] == ' '; idx++)
    ;

  // now idx points to the first non-space character
  for (; idx < sz; idx++) {

    char &c = res[idx];

    if (c == ' ') {

      if (prev_is_space)
        continue;

      prev_is_space = true;
      res[effect_idx++] = c;

    } else if (c == ';' || c == ',') {

      if (prev_is_space)
        res[effect_idx - 1] = c;
      else
        res[effect_idx++] = c;

      prev_is_space = false;

    } else if (c == '@') {
      // Skip following spaces.
      res[effect_idx++] = c;
    }
    else {

      prev_is_space = false;
      res[effect_idx++] = c;
    }
  }

  if (effect_idx > 0 && res[effect_idx - 1] == ' ')
    effect_idx--;

  res.resize(effect_idx);
}

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

string get_string_by_data_flag(DATAFLAG type) {
#define DECLARE_CASE(classname)                                                \
  if (type == classname)                                                       \
    return #classname;
  ALLDATAFLAG(DECLARE_CASE);
#undef DECLARE_CASE
  return "";
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
                    this->str_val_, this->name_, this->mutated_times_, 0, kFlagUnknown);
  copy_res->data_type_ = this->data_type_;
  copy_res->data_flag_ = this->data_flag_;

  if (this->parent_) {
    copy_res->parent_ = this->parent_;
  } else {
    copy_res->parent_ = NULL;
  }

  copy_res->is_node_struct_fixed = this->is_node_struct_fixed;
  copy_res->is_mutating = this->is_mutating;

  return copy_res;
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

std::string IR::to_string(){
  auto res = to_string_core();
  trim_string(res);
  return res;
}

std::string IR::to_string_core(){
  //cout << get_string_by_nodetype(this->type_) << endl;
  //     switch(type_){
  // 	case kIntLiteral: return std::to_string(int_val_);
  // 	case kFloatLiteral: return std::to_string(float_val_);
  // 	case kIdentifier: return str_val_;
  // 	case kStringLiteral: return str_val_;

  // }

  std::string res;

  if( op_!= NULL && op_->prefix_ != "" ){
    res += op_->prefix_ + " ";
  }

  if(left_ != NULL) {
    res += left_->to_string_core() + " ";
  }


  if( op_!= NULL && op_->middle_ != "") {
    res += op_->middle_ + " ";
  }
  if (
      get_ir_type() == kTextStringLiteral
  ) {
    res += " '" + str_val_ + "' ";
  }
  else if (str_val_ != "") {
    res += " " + str_val_ + " ";
  }


  if(right_ != NULL) {
    res += right_->to_string_core() + " ";
  }


  if(op_!= NULL && op_->suffix_ != "") {
    res += op_->suffix_ + " ";
  }

  return res;
}

IR* IR::get_left() {
  if (left_ == NULL) return NULL;
  else return left_;
}
IR* IR::get_right() {
  if (right_ == NULL) return NULL;
  else return right_;
}
std::string IR::get_prefix() {
  if (!op_) return NULL;
  return op_->prefix_;
}
std::string IR::get_middle() {
  if (!op_) return NULL;
  return op_->middle_;
}
std::string IR::get_suffix() {
  if (!op_) return NULL;
  return op_->suffix_;
}
IR* IR::get_parent() {
  if (!parent_) return NULL;
  else return parent_;
}
void IR::set_prefix(string in) {
  if (!op_) this->op_ = OP0();
  this->op_->prefix_ = in;
}
void IR::set_middle(string in) {
  if (!op_) this->op_ = OP0();
  this->op_->middle_ = in;
}
void IR::set_suffix(string in) {
  if (!op_) this->op_ = OP0();
  this->op_->suffix_ = in;
}

bool IR::detatch_node(IR *node) { return swap_node(node, NULL); }

bool IR::update_left(IR* new_left) {
  // if (!new_left) return false;

  this->left_ = new_left;
  if (new_left)
    new_left->parent_ = this;

  return true;
}

bool IR::update_right(IR* new_right) {
  // if (!new_right) return false;

  this->right_ = new_right;
  if (new_right)
    new_right->parent_ = this;

  return true;
}

bool IR::swap_node(IR *old_node, IR *new_node) {
  if (old_node == NULL) {
    // printf("swap_node failed because old_node == NULL \n\n\n");
    return false;
  }

  IR *parent = this->locate_parent(old_node);

  if (parent == NULL) {
    // printf("swap_node failed because locate_parent failed. \n\n\n");
    return false;
  }
  else if (parent->left_ == old_node)
    parent->update_left(new_node);
  else if (parent->right_ == old_node)
    parent->update_right(new_node);
  else {
    // printf("swap_node failed because parent is not connected to new_node. \n\n\n");
    return false;
  }

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

IRTYPE IR::get_ir_type() {
  return type_;
}

DATATYPE IR::get_data_type() {
  return data_type_;
}

void IR::set_data_type(DATATYPE data_type) {
  this->data_type_ = data_type;
}

DATAFLAG IR::get_data_flag() {
  return data_flag_;
}

void IR::set_data_flag(DATAFLAG data_flag) {
  this->data_flag_ = data_flag;
}

bool IR::is_empty() {
  if (op_) {
    if (op_->prefix_ != "" || op_->middle_ != "" || op_->suffix_ != "" ) {
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

std::string IR::get_str_val() {
  return this->str_val_;
}

void IR::set_str_val(std::string in) {
  this->str_val_ = in;
  return;
}

bool IR::set_type(DATATYPE data_type, DATAFLAG data_flag) {
  this->set_data_type(data_type);
  this->set_data_flag(data_flag);
  return true;
}