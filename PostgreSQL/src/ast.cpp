#include "../include/ast.h"
#include "../include/define.h"
#include "../include/utils.h"
#include <cassert>
#include <cstdio>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <vector>

static string s_table_name;

string get_string_by_ir_type(IRTYPE type) {

#define DECLARE_CASE(classname)                                                \
  if (type == k##classname)                                                    \
    return #classname;

  ALLCLASS(DECLARE_CASE);
#undef DECLARE_CASE

  return "Unknown";
}

string get_string_by_data_type(DATATYPE type) {

  switch (type) {
  case kDataWhatever:
    return "data_whatever";
  case kDataTableName:
    return "data_tableName";
  case kDataColumnName:
    return "data_columnName";
  case kDataViewName:
    return "data_viewNmae";
  case kDataFunctionName:
    return "data_functionName";
  case kDataPragmaKey:
    return "data_pragmaKey";
  case kDataPragmaValue:
    return "data_pragmaValue";
  case kDataTableSpaceName:
    return "data_tableSpaceName";
  case kDataSequenceName:
    return "data_SequenceName";
  case kDataExtensionName:
    return "data_extensionName";
  case kDataRoleName:
    return "data_roleName";
  case kDataSchemaName:
    return "data_SchemaName";
  case kDataDatabase:
    return "data_dataDatabase";
  case kDataTriggerName:
    return "data_triggername";
  case kDataWindowName:
    return "data_windowName";
  case kDataTriggerFunction:
    return "data_triggerFunction";
  case kDataDomainName:
    return "data_domainName";
  case kDataAliasName:
    return "data_aliasName";
  case kDataLiteral:
    return "data_literal";
  case kDataIndexName:
    return "data_indexName";
  case kDataGroupName:
    return "data_groupName";
  case kDataUserName:
    return "data_UserName";
  case kDataDatabaseName:
    return "data_DatabaseName";
  case kDataSystemName:
    return "data_SystemName";
  case kDataConversionName:
    return "data_ConversionName";
  default:
    return "data_unknown";
  }
}

string get_string_by_data_flag(DATAFLAG flag_type_) {

  switch (flag_type_) {
  case kUse:
    return "kUse";
  case kMapToClosestOne:
    return "kMapToClosestOne";
  case kNoSplit:
    return "kNoSplit";
  case kGlobal:
    return "kGlobal";
  case kReplace:
    return "kReplace";
  case kUndefine:
    return "kUndefine";
  case kAlias:
    return "kAlias";
  case kMapToAll:
    return "kMapToAll";
  case kDefine:
    return "kDefine";
  default:
    return "kUnknown";
  }
}

// TO Sqlite => get_string_by_ir_type
Node *generate_ast_node_by_type(IRTYPE type) {
#define DECLARE_CASE(classname)                                                \
  if (type == k##classname)                                                    \
    return new classname();

  ALLCLASS(DECLARE_CASE);
#undef DECLARE_CASE
  return NULL;
}

IRTYPE get_nodetype_by_string(string s) {
#define DECLARE_CASE(datatypename)                                             \
  if (s == #datatypename)                                                      \
    return k##datatypename;

  ALLCLASS(DECLARE_CASE);

#undef DECLARE_CASE
  return kUnknown;
}

string get_string_by_nodetype(IRTYPE tt) {
#define DECLARE_CASE(datatypename)                                             \
  if (tt == k##datatypename)                                                   \
    return string(#datatypename);

  ALLCLASS(DECLARE_CASE);

#undef DECLARE_CASE
  return string("");
}

string get_string_by_datatype(DATATYPE tt) {
#define DECLARE_CASE(datatypename)                                             \
  if (tt == k##datatypename)                                                   \
    return string(#datatypename);

  ALLDATATYPE(DECLARE_CASE);

#undef DECLARE_CASE
  return string("");
}

DATATYPE get_datatype_by_string(string s) {
#define DECLARE_CASE(datatypename)                                             \
  if (s == #datatypename)                                                      \
    return k##datatypename;

  ALLDATATYPE(DECLARE_CASE);

#undef DECLARE_CASE
  return kDataWhatever;
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
void IR::to_string_core(string& res) {
  switch (type_) {
  case kIntLiteral:
    if (str_val_ != "") {
      res += str_val_;
    } else {
      res += std::to_string(int_val_);
    }
    return;
  case kFloatLiteral:
    if (str_val_ != "") {
      res += str_val_;
    } else {
      res += std::to_string(float_val_);
    }
    return;
  case kIdentifier:
  case kStringLiteral:
    if (str_val_ != "") {
      res += str_val_;
    }
    return;
  }

  if (type_ == kFuncArgs && str_val_ != "") {
    res += str_val_;
    return;
  }

  if (op_ != NULL) {
    res += op_->prefix_ + " ";
  }
  if (left_ != NULL)
    left_->to_string_core(res);
    res += " ";
  if (op_ != NULL)
    res += op_->middle_ + " ";
  if (right_ != NULL)
    right_->to_string_core(res);
    res += " ";
  if (op_ != NULL)
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

  if (this->op_ != NULL)
    op = OP3(this->op_->prefix_, this->op_->middle_, this->op_->suffix_);

  copy_res = new IR(this->type_, op, left, right, this->float_val_,
                    this->str_val_, this->name_, this->mutated_times_);
  copy_res->data_type_ = this->data_type_;
  copy_res->data_flag_ = this->data_flag_;

  return copy_res;
}

// move it here. seems no active use
void IR::print_ir() {

  if (this->left_ != NULL)
    this->left_->print_ir();
  if (this->right_ != NULL)
    this->right_->print_ir();

  if (this->operand_num_ == 0) {
    cout << this->name_ << " = .str." << this->str_val_ << endl;
  } else if (this->operand_num_ == 1) {
    string res = "";
    if (this->op_ != NULL) {
      res += this->op_->prefix_ + " ";
      res += this->left_->name_ + " ";
      res += this->op_->middle_ + " ";
      res += this->op_->suffix_ + " ";
    }
    cout << this->name_ << " = " << res << endl;
  } else if (this->operand_num_ == 2) {
    string res = "";
    if (this->op_ != NULL) {
      res += this->op_->prefix_ + " ";
      res += this->left_->name_ + " ";
      res += this->op_->middle_ + " ";
      res += this->right_->name_ + " ";
      res += this->op_->suffix_ + " ";
    }
    cout << this->name_ << " = " << res << endl;
  }

  return;
}