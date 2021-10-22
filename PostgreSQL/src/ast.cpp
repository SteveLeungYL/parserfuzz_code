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

NODETYPE get_nodetype_by_string(string s) {
#define DECLARE_CASE(datatypename)                                             \
  if (s == #datatypename)                                                      \
    return k##datatypename;

  ALLCLASS(DECLARE_CASE);

#undef DECLARE_CASE
  return kUnknown;
}

string get_string_by_nodetype(NODETYPE tt) {
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

IR *Node::translate(vector<IR *> &v_ir_collector) { return NULL; }
IR *Program::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(stmtlist_);
  res = new IR(kProgram, OP3("", "", ""), tmp1);

  TRANSLATEEND
}

void Program::deep_delete() {
  SAFEDELETE(stmtlist_);
  delete this;
};

void Program::generate() {
  GENERATESTART(1)

  stmtlist_ = new Stmtlist();
  stmtlist_->generate();

  GENERATEEND
}

IR *Stmtlist::translate(vector<IR *> &v_ir_collector) {
  // Ignore opt_semi_. 
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(stmt_);
  auto tmp2 = SAFETRANSLATE(stmtlist_);
  res = new IR(kStmtlist, OP3("", ";", ""), tmp1, tmp2);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(stmt_);
  res = new IR(kStmtlist, OP3("", ";", ""), tmp1);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void Stmtlist::deep_delete() {
  SAFEDELETE(stmt_);
  SAFEDELETE(stmtlist_);
  SAFEDELETE(opt_semi_);
  delete this;
};

void Stmtlist::generate() {
  GENERATESTART(200)

  SWITCHSTART
  CASESTART(0)
  stmt_ = new Stmt();
  stmt_->generate();
  stmtlist_ = new Stmtlist();
  stmtlist_->generate();
  CASEEND
  CASESTART(1)
  stmt_ = new Stmt();
  stmt_->generate();
  CASEEND

  default: {
  int tmp_case_idx = rand() % 1;
  switch (tmp_case_idx) {
    CASESTART(0)
    stmt_ = new Stmt();
    stmt_->generate();
    case_idx_ = 1;
    CASEEND
  }
  }
}

GENERATEEND
}


void OptSemi::deep_delete() {
  SAFEDELETE(opt_semi_);
  delete this;
};

void OptSemi::generate() {
  GENERATESTART(3)
  SWITCHSTART
  CASESTART(0)
  CASEEND
  CASESTART(1)
  opt_semi_ = new OptSemi();
  opt_semi_->generate();
  CASEEND
  CASESTART(2)
  CASEEND
  SWITCHEND
  GENERATEEND
}

IR *OptSemi::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART
  SWITCHSTART
  CASESTART(0)
  res = new IR(kOptSemi, OP3(";", "", ""));
  CASEEND
  CASESTART(1)
  auto tmp = SAFETRANSLATE(opt_semi_);
  res = new IR(kOptSemi, OP3(";", "", ""), tmp);
  CASEEND
  CASESTART(2)
  res = new IR(kOptSemi, OP0());
  CASEEND
  SWITCHEND
  TRANSLATEEND
}

IR *Stmt::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(create_stmt_);
  res = new IR(kStmt, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(drop_stmt_);
  res = new IR(kStmt, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(2)
  auto tmp1 = SAFETRANSLATE(select_stmt_);
  res = new IR(kStmt, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(3)
  auto tmp1 = SAFETRANSLATE(update_stmt_);
  res = new IR(kStmt, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(4)
  auto tmp1 = SAFETRANSLATE(insert_stmt_);
  res = new IR(kStmt, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(5)
  auto tmp1 = SAFETRANSLATE(alter_stmt_);
  res = new IR(kStmt, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(6)
  auto tmp1 = SAFETRANSLATE(alter_index_stmt_);
  res = new IR(kStmt, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(7)
  auto tmp1 = SAFETRANSLATE(reindex_stmt_);
  res = new IR(kStmt, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(8)
  auto tmp1 = SAFETRANSLATE(alter_group_stmt_);
  res = new IR(kStmt, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(9)
  auto tmp1 = SAFETRANSLATE(drop_group_stmt_);
  res = new IR(kStmt, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(10)
  auto tmp1 = SAFETRANSLATE(values_stmt_);
  res = new IR(kStmt, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(11)
  auto tmp1 = SAFETRANSLATE(alter_view_stmt_);
  res = new IR(kStmt, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(12)
  auto tmp1 = SAFETRANSLATE(create_group_stmt_);
  res = new IR(kStmt, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(13)
  auto tmp1 = SAFETRANSLATE(alter_tblspc_stmt_);
  res = new IR(kStmt, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(14)
  auto tmp1 = SAFETRANSLATE(alter_conversion_stmt_);
  res = new IR(kStmt, OP3("", "", ""), tmp1);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void Stmt::deep_delete() {
  SAFEDELETE(insert_stmt_);
  SAFEDELETE(drop_stmt_);
  SAFEDELETE(create_stmt_);
  SAFEDELETE(select_stmt_);
  SAFEDELETE(alter_stmt_);
  SAFEDELETE(alter_index_stmt_);
  SAFEDELETE(reindex_stmt_);
  SAFEDELETE(update_stmt_);
  SAFEDELETE(alter_group_stmt_);
  SAFEDELETE(drop_group_stmt_);
  SAFEDELETE(values_stmt_);
  SAFEDELETE(alter_view_stmt_);
  SAFEDELETE(create_group_stmt_);
  SAFEDELETE(alter_tblspc_stmt_);
  SAFEDELETE(alter_conversion_stmt_);
  delete this;
};

void Stmt::generate() {
  GENERATESTART(7)

  SWITCHSTART
  CASESTART(0)
  create_stmt_ = new CreateStmt();
  create_stmt_->generate();
  CASEEND
  CASESTART(1)
  drop_stmt_ = new DropStmt();
  drop_stmt_->generate();
  CASEEND
  CASESTART(2)
  select_stmt_ = new SelectStmt();
  select_stmt_->generate();
  CASEEND
  CASESTART(3)
  update_stmt_ = new UpdateStmt();
  update_stmt_->generate();
  CASEEND
  CASESTART(4)
  insert_stmt_ = new InsertStmt();
  insert_stmt_->generate();
  CASEEND
  CASESTART(5)
  alter_stmt_ = new AlterStmt();
  alter_stmt_->generate();
  CASEEND
  CASESTART(6)
  alter_index_stmt_ = new AlterIndexStmt();
  alter_index_stmt_->generate();
  CASEEND
  CASESTART(7)
  reindex_stmt_ = new ReindexStmt();
  reindex_stmt_->generate();
  CASEEND
  CASESTART(8)
  alter_group_stmt_ = new AlterGroupStmt();
  alter_group_stmt_->generate();
  CASEEND
  CASESTART(9)
  drop_group_stmt_ = new DropGroupStmt();
  drop_group_stmt_->generate();
  CASEEND
  CASESTART(10)
  values_stmt_ = new ValuesStmt();
  values_stmt_->generate();
  CASEEND
  CASESTART(11)
  alter_view_stmt_ = new AlterViewStmt();
  alter_view_stmt_->generate();
  CASEEND
  CASESTART(12)
  create_group_stmt_ = new CreateGroupStmt();
  create_group_stmt_->generate();
  CASEEND
  CASESTART(13)
  alter_tblspc_stmt_ = new AlterTblspcStmt();
  alter_tblspc_stmt_->generate();
  CASEEND
  CASESTART(14)
  alter_conversion_stmt_ = new AlterConversionStmt();
  alter_conversion_stmt_->generate();
  CASEEND
  SWITCHEND

  GENERATEEND
}

IR *CreateStmt::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(create_table_stmt_);
  res = new IR(kCreateStmt, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(create_index_stmt_);
  res = new IR(kCreateStmt, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(2)
  auto tmp1 = SAFETRANSLATE(create_view_stmt_);
  res = new IR(kCreateStmt, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(3)
  auto tmp1 = SAFETRANSLATE(create_table_as_stmt_);
  res = new IR(kCreateStmt, OP3("", "", ""), tmp1);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void CreateStmt::deep_delete() {
  SAFEDELETE(create_index_stmt_);
  SAFEDELETE(create_view_stmt_);
  SAFEDELETE(create_table_stmt_);
  SAFEDELETE(create_table_as_stmt_);
  delete this;
};

void CreateStmt::generate() {
  GENERATESTART(3)

  SWITCHSTART
  CASESTART(0)
  create_table_stmt_ = new CreateTableStmt();
  create_table_stmt_->generate();
  CASEEND
  CASESTART(1)
  create_index_stmt_ = new CreateIndexStmt();
  create_index_stmt_->generate();
  CASEEND
  CASESTART(2)
  create_view_stmt_ = new CreateViewStmt();
  create_view_stmt_->generate();
  CASEEND
  CASESTART(3)
  create_table_as_stmt_ = new CreateTableAsStmt();
  create_table_as_stmt_->generate();
  CASEEND
  SWITCHEND

  GENERATEEND
}

IR *DropStmt::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(drop_index_stmt_);
  res = new IR(kDropStmt, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(drop_table_stmt_);
  res = new IR(kDropStmt, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(2)
  auto tmp1 = SAFETRANSLATE(drop_view_stmt_);
  res = new IR(kDropStmt, OP3("", "", ""), tmp1);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void DropStmt::deep_delete() {
  SAFEDELETE(drop_table_stmt_);
  SAFEDELETE(drop_view_stmt_);
  SAFEDELETE(drop_index_stmt_);
  delete this;
};

void DropStmt::generate() {
  GENERATESTART(3)

  SWITCHSTART
  CASESTART(0)
  drop_index_stmt_ = new DropIndexStmt();
  drop_index_stmt_->generate();
  CASEEND
  CASESTART(1)
  drop_table_stmt_ = new DropTableStmt();
  drop_table_stmt_->generate();
  CASEEND
  CASESTART(2)
  drop_view_stmt_ = new DropViewStmt();
  drop_view_stmt_->generate();
  CASEEND
  SWITCHEND

  GENERATEEND
}

IR *AlterStmt::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(table_name_);
  auto tmp2 = SAFETRANSLATE(alter_action_);
  res = new IR(kAlterStmt, OP3("ALTER TABLE", "", ""), tmp1, tmp2);

  TRANSLATEEND
}

void AlterStmt::deep_delete() {
  SAFEDELETE(alter_action_);
  SAFEDELETE(table_name_);
  delete this;
};

void AlterStmt::generate() {
  GENERATESTART(1)

  table_name_ = new TableName();
  table_name_->generate();
  alter_action_ = new AlterAction();
  alter_action_->generate();

  GENERATEEND
}



IR *AlterIndexStmt::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART
  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(index_name_0_);
  auto tmp2 = SAFETRANSLATE(index_name_1_);
  res = new IR(kAlterIndexStmt, OP3("ALTER INDEX IF EXISTS", "RENAME TO", ""), tmp1, tmp2);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(index_name_0_);
  auto tmp2 = SAFETRANSLATE(index_name_1_);
  res = new IR(kAlterIndexStmt, OP3("ALTER INDEX", "RENAME TO", ""), tmp1, tmp2);
  CASEEND
  CASESTART(2)
  auto tmp1 = SAFETRANSLATE(index_name_0_);
  auto tmp2 = SAFETRANSLATE(tablespace_name_);
  res = new IR(kAlterIndexStmt, OP3("ALTER INDEX IF EXISTS", "SET TABLESPACE", ""), tmp1, tmp2);
  CASEEND
  CASESTART(3)
  auto tmp1 = SAFETRANSLATE(index_name_0_);
  auto tmp2 = SAFETRANSLATE(tablespace_name_);
  res = new IR(kAlterIndexStmt, OP3("ALTER INDEX", "SET TABLESPACE", ""), tmp1, tmp2);
  CASEEND
  CASESTART(4)
  auto tmp1 = SAFETRANSLATE(index_name_0_);
  auto tmp2 = SAFETRANSLATE(index_name_1_);
  res = new IR(kAlterIndexStmt, OP3("ALTER INDEX", "ATTACH PARTITION", ""), tmp1, tmp2);
  CASEEND
  CASESTART(5)
  auto tmp1 = SAFETRANSLATE(index_name_0_);
  auto tmp2 = SAFETRANSLATE(opt_no_);
  auto tmp3 = SAFETRANSLATE(extension_name_);
  res = new IR(kUnknown, OP3("ALTER INDEX", "", ""), tmp1, tmp2);
  PUSH(res);
  res = new IR(kAlterIndexStmt, OP3("", "DEPENDS ON EXTENSION", ""), res, tmp3);
  CASEEND
  CASESTART(6)
  auto tmp1 = SAFETRANSLATE(index_name_0_);
  auto tmp2 = SAFETRANSLATE(index_storage_parameter_list_);
  res = new IR(kAlterIndexStmt, OP3("ALTER INDEX IF EXISTS", "SET(", ")"), tmp1, tmp2);
  CASEEND
  CASESTART(7)
  auto tmp1 = SAFETRANSLATE(index_name_0_);
  auto tmp2 = SAFETRANSLATE(index_storage_parameter_list_);
  res = new IR(kAlterIndexStmt, OP3("ALTER INDEX", "SET(", ")"), tmp1, tmp2);
  CASEEND
  CASESTART(8)
  auto tmp1 = SAFETRANSLATE(index_name_0_);
  auto tmp2 = SAFETRANSLATE(index_storage_parameter_list_);
  res = new IR(kAlterIndexStmt, OP3("ALTER INDEX IF EXISTS", "RESET(", ")"), tmp1, tmp2);
  CASEEND
  CASESTART(9)
  auto tmp1 = SAFETRANSLATE(index_name_0_);
  auto tmp2 = SAFETRANSLATE(index_storage_parameter_list_);
  res = new IR(kAlterIndexStmt, OP3("ALTER INDEX", "RESET(", ")"), tmp1, tmp2);
  CASEEND
  CASESTART(10)
  auto tmp1 = SAFETRANSLATE(index_name_0_);
  auto tmp2 = SAFETRANSLATE(opt_column_);
  auto tmp3 = SAFETRANSLATE(int_literal_0_);
  auto tmp4 = SAFETRANSLATE(int_literal_1_);
  res = new IR(kUnknown, OP3("ALTER INDEX IF EXISTS", "ALTER", ""), tmp1, tmp2);
  PUSH(res);
  res = new IR(kUnknown, OP3("", "", ""), res, tmp3);
  PUSH(res);
  res = new IR(kAlterIndexStmt, OP3("", "SET STATISTICS", ""), res, tmp4);
  CASEEND
  CASESTART(11)
  auto tmp1 = SAFETRANSLATE(index_name_0_);
  auto tmp2 = SAFETRANSLATE(opt_column_);
  auto tmp3 = SAFETRANSLATE(int_literal_0_);
  auto tmp4 = SAFETRANSLATE(int_literal_1_);
  res = new IR(kUnknown, OP3("ALTER INDEX", "ALTER", ""), tmp1, tmp2);
  PUSH(res);
  res = new IR(kUnknown, OP3("", "", ""), res, tmp3);
  PUSH(res);
  res = new IR(kAlterIndexStmt, OP3("", "SET STATISTICS", ""), res, tmp4);
  CASEEND
  CASESTART(12)
  auto tmp1 = SAFETRANSLATE(tablespace_name_0_);
  auto tmp2 = SAFETRANSLATE(opt_owned_by_);
  auto tmp3 = SAFETRANSLATE(tablespace_name_1_);
  auto tmp4 = SAFETRANSLATE(opt_no_wait_);
  res = new IR(kUnknown, OP3("ALTER INDEX ALL IN TABLESPACE", "", ""), tmp1, tmp2);
  PUSH(res);
  res = new IR(kUnknown, OP3("", "SET TABLESPACE", ""), res, tmp3);
  PUSH(res);
  res = new IR(kUnknown, OP3("", "", ""), res, tmp4);
  CASEEND
  SWITCHEND
  TRANSLATEEND
}

void AlterIndexStmt::deep_delete() {
  SAFEDELETE(index_name_0_);
  SAFEDELETE(index_name_1_);
  SAFEDELETE(tablespace_name_);
  SAFEDELETE(opt_no_);
  SAFEDELETE(extension_name_);
  SAFEDELETE(index_storage_parameter_list_);
  SAFEDELETE(opt_column_);
  SAFEDELETE(opt_owned_by_);
  SAFEDELETE(opt_no_wait_);
  SAFEDELETE(int_literal_0_);
  SAFEDELETE(int_literal_1_);
  SAFEDELETE(tablespace_name_0_);
  SAFEDELETE(tablespace_name_1_);
  delete this;
};

void AlterIndexStmt::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *AlterGroupStmt::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART
  SWITCHSTART
    CASESTART(0)
      auto tmp1 = SAFETRANSLATE(role_specification_);
      auto tmp2 = SAFETRANSLATE(user_name_list_);
      res = new IR(kAlterGroupStmt, OP3("ALTER GROUP", "ADD USER", ""), tmp1, tmp2);
    CASEEND
    CASESTART(1)
      auto tmp1 = SAFETRANSLATE(role_specification_);
      auto tmp2 = SAFETRANSLATE(user_name_list_);
      res = new IR(kAlterGroupStmt, OP3("ALTER GROUP", "DROP USER", ""), tmp1, tmp2);
    CASEEND
    CASESTART(2)
      auto tmp1 = SAFETRANSLATE(group_name_0_);
      auto tmp2 = SAFETRANSLATE(group_name_1_);
      res = new IR(kAlterGroupStmt, OP3("ALTER GROUP", "RENAME TO", ""), tmp1, tmp2);
    CASEEND
  SWITCHEND
  TRANSLATEEND
}

void AlterGroupStmt::deep_delete() {
  SAFEDELETE(role_specification_);
  SAFEDELETE(user_name_list_);
  SAFEDELETE(group_name_0_);
  SAFEDELETE(group_name_1_);
  delete this;
};

void AlterGroupStmt::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *SelectStmt::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(select_no_parens_);
  res = new IR(kSelectStmt, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(select_with_parens_);
  res = new IR(kSelectStmt, OP3("", "", ""), tmp1);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void SelectStmt::deep_delete() {
  SAFEDELETE(select_no_parens_);
  SAFEDELETE(select_with_parens_);
  delete this;
};

void SelectStmt::generate() {
  GENERATESTART(2)

  SWITCHSTART
  CASESTART(0)
  select_no_parens_ = new SelectNoParens();
  select_no_parens_->generate();
  CASEEND
  CASESTART(1)
  select_with_parens_ = new SelectWithParens();
  select_with_parens_->generate();
  CASEEND
  SWITCHEND

  GENERATEEND
}

IR *SelectWithParens::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(select_no_parens_);
  res = new IR(kSelectWithParens, OP3("(", ")", ""), tmp1);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(select_with_parens_);
  res = new IR(kSelectWithParens, OP3("(", ")", ""), tmp1);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void SelectWithParens::deep_delete() {
  SAFEDELETE(select_no_parens_);
  SAFEDELETE(select_with_parens_);
  delete this;
};

void SelectWithParens::generate() {
  GENERATESTART(200)

  SWITCHSTART
  CASESTART(0)
  select_no_parens_ = new SelectNoParens();
  select_no_parens_->generate();
  CASEEND
  CASESTART(1)
  select_with_parens_ = new SelectWithParens();
  select_with_parens_->generate();
  CASEEND

default: {
  int tmp_case_idx = rand() % 1;
  switch (tmp_case_idx) {
    CASESTART(0)
    select_no_parens_ = new SelectNoParens();
    select_no_parens_->generate();
    case_idx_ = 0;
    CASEEND
  }
}
}

GENERATEEND
}


IR *OrderClause::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART
  SWITCHSTART
  CASESTART(0)
  auto tmp0 = SAFETRANSLATE(order_item_list_);
  res = new IR(kOrderClause, OP1("ORDER BY"), tmp0);
  CASEEND
  SWITCHEND
  TRANSLATEEND
}

void OrderClause::deep_delete() {
  SAFEDELETE(order_item_list_);
  delete this;
};

void OrderClause::generate() {
}


IR *SelectClauseList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(select_clause_);
  res = new IR(kSelectClauseList, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(select_clause_);
  auto tmp2 = SAFETRANSLATE(combine_clause_);
  auto tmp3 = SAFETRANSLATE(select_clause_list_);
  auto tmp4 = new IR(kUnknown, OP3("", "", ""), tmp1, tmp2);
  PUSH(tmp4);
  res = new IR(kSelectClauseList, OP3("", "", ""), tmp4, tmp3);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void SelectClauseList::deep_delete() {
  SAFEDELETE(select_clause_list_);
  SAFEDELETE(combine_clause_);
  SAFEDELETE(select_clause_);
  delete this;
};

void SelectClauseList::generate() {
  GENERATESTART(200)

  SWITCHSTART
  CASESTART(0)
  select_clause_ = new SelectClause();
  select_clause_->generate();
  CASEEND
  CASESTART(1)
  select_clause_ = new SelectClause();
  select_clause_->generate();
  combine_clause_ = new CombineClause();
  combine_clause_->generate();
  select_clause_list_ = new SelectClauseList();
  select_clause_list_->generate();
  CASEEND

default: {
  int tmp_case_idx = rand() % 1;
  switch (tmp_case_idx) {
    CASESTART(0)
    select_clause_ = new SelectClause();
    select_clause_->generate();
    case_idx_ = 0;
    CASEEND
  }
}
}

GENERATEEND
}

IR *SelectClause::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART
  SWITCHSTART
  CASESTART(0)
  auto tmp0 = SAFETRANSLATE(simple_select_);
  res = new IR(kSelectClause, OP0(), tmp0);
  CASEEND
  CASESTART(1)
  auto tmp0 = SAFETRANSLATE(select_with_parens_);
  res = new IR(kSelectClause, OP0(), tmp0);
  CASEEND
  SWITCHEND
  TRANSLATEEND
}

void SelectClause::deep_delete() {
  SAFEDELETE(simple_select_);
  SAFEDELETE(select_with_parens_);
  delete this;
};

void SelectClause::generate() {
}

IR *SimpleSelect::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART
  SWITCHSTART
  CASESTART(0)
  auto tmp0 = SAFETRANSLATE(opt_all_clause_);
  auto tmp1 = SAFETRANSLATE(opt_select_target_);
  auto tmp2 = SAFETRANSLATE(into_clause_);
  auto tmp3 = SAFETRANSLATE(from_clause_);
  auto tmp4 = SAFETRANSLATE(opt_where_clause_);
  auto tmp5 = SAFETRANSLATE(opt_group_clause_);
  auto tmp6 = SAFETRANSLATE(opt_having_clause_);
  auto tmp7 = SAFETRANSLATE(opt_window_clause_);

  res = new IR(kUnknown, OP1("SELECT"), tmp0, tmp1);
  PUSH(res);
  res = new IR(kUnknown, OP0(), res, tmp2);
  PUSH(res);
  res = new IR(kUnknown, OP0(), res, tmp3);
  PUSH(res);
  res = new IR(kUnknown, OP0(), res, tmp4);
  PUSH(res);
  res = new IR(kUnknown, OP0(), res, tmp5);
  PUSH(res);
  res = new IR(kUnknown, OP0(), res, tmp6);
  PUSH(res);
  res = new IR(kSimpleSelect, OP0(), res, tmp7);
  CASEEND
  CASESTART(1)
  auto tmp0 = SAFETRANSLATE(distinct_clause_);
  auto tmp1 = SAFETRANSLATE(select_target_);
  auto tmp2 = SAFETRANSLATE(into_clause_);
  auto tmp3 = SAFETRANSLATE(from_clause_);
  auto tmp4 = SAFETRANSLATE(opt_where_clause_);
  auto tmp5 = SAFETRANSLATE(opt_group_clause_);
  auto tmp6 = SAFETRANSLATE(opt_having_clause_);
  auto tmp7 = SAFETRANSLATE(opt_window_clause_);

  res = new IR(kUnknown, OP1("SELECT"), tmp0, tmp1);
  PUSH(res);
  res = new IR(kUnknown, OP0(), res, tmp2);
  PUSH(res);
  res = new IR(kUnknown, OP0(), res, tmp3);
  PUSH(res);
  res = new IR(kUnknown, OP0(), res, tmp4);
  PUSH(res);
  res = new IR(kUnknown, OP0(), res, tmp5);
  PUSH(res);
  res = new IR(kUnknown, OP0(), res, tmp6);
  PUSH(res);
  res = new IR(kSimpleSelect, OP0(), res, tmp7);
  CASEEND
  CASESTART(2)
  auto tmp0 = SAFETRANSLATE(relation_expr_);
  res = new IR(kSimpleSelect, OP1("TALBE"), tmp0);
  CASEEND

  CASESTART(3)
  auto tmp0 = SAFETRANSLATE(select_clause_);
  auto tmp1 = SAFETRANSLATE(opt_all_or_distinct_);
  auto tmp2 = SAFETRANSLATE(select_clause_2_);
  res = new IR(kUnknown, OPMID("UNION"), tmp0, tmp1);
  PUSH(res);
  res = new IR(kSimpleSelect, OP0(), res, tmp2);
  CASEEND
  CASESTART(4)
  auto tmp0 = SAFETRANSLATE(select_clause_);
  auto tmp1 = SAFETRANSLATE(opt_all_or_distinct_);
  auto tmp2 = SAFETRANSLATE(select_clause_2_);
  res = new IR(kUnknown, OPMID("INTERSECT"), tmp0, tmp1);
  PUSH(res);
  res = new IR(kSimpleSelect, OP0(), res, tmp2);
  CASEEND
  CASESTART(5)
  auto tmp0 = SAFETRANSLATE(select_clause_);
  auto tmp1 = SAFETRANSLATE(opt_all_or_distinct_);
  auto tmp2 = SAFETRANSLATE(select_clause_2_);
  res = new IR(kUnknown, OPMID("EXCEPT"), tmp0, tmp1);
  PUSH(res);
  res = new IR(kSimpleSelect, OP0(), res, tmp2);
  CASEEND
  SWITCHEND
  TRANSLATEEND
}

void SimpleSelect::deep_delete() {
  SAFEDELETE(opt_all_clause_);
  SAFEDELETE(opt_select_target_);
  SAFEDELETE(into_clause_);
  SAFEDELETE(from_clause_);
  SAFEDELETE(opt_where_clause_);
  SAFEDELETE(opt_group_clause_);
  SAFEDELETE(opt_having_clause_);
  SAFEDELETE(opt_window_clause_);
  SAFEDELETE(distinct_clause_);
  SAFEDELETE(select_target_);
  SAFEDELETE(opt_all_or_distinct_);
  SAFEDELETE(select_clause_);
  SAFEDELETE(select_clause_2_);
  SAFEDELETE(relation_expr_);
  delete this;
};

void SimpleSelect::generate() {
}

IR *RelationExpr::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART
  SWITCHSTART
  CASESTART(0)
  auto tmp0 = SAFETRANSLATE(table_name_);
  res = new IR(kRelationExpr, OP0(), tmp0);
  CASEEND
  CASESTART(1)
  auto tmp0 = SAFETRANSLATE(table_name_);
  res = new IR(kRelationExpr, OP3("", "", "*"), tmp0);
  CASEEND
  CASESTART(2)
  auto tmp0 = SAFETRANSLATE(table_name_);
  res = new IR(kRelationExpr, OP3("ONLY", "", ""), tmp0);
  CASEEND
  CASESTART(3)
  auto tmp0 = SAFETRANSLATE(table_name_);
  res = new IR(kRelationExpr, OP3("ONLY (", "", ")"), tmp0);
  CASEEND
  SWITCHEND
  TRANSLATEEND
}

void RelationExpr::deep_delete() {
  SAFEDELETE(table_name_);
  delete this;
};

void RelationExpr::generate() {
}

IR *CombineClause::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  res = new IR(kCombineClause, OP3("UNION", "", ""));
  CASEEND
  CASESTART(1)
  res = new IR(kCombineClause, OP3("INTERSECT", "", ""));
  CASEEND
  CASESTART(2)
  res = new IR(kCombineClause, OP3("EXCEPT", "", ""));
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void CombineClause::deep_delete() { delete this; };

void CombineClause::generate(){GENERATESTART(3)

                                   SWITCHSTART CASESTART(0) CASEEND CASESTART(1)
                                       CASEEND CASESTART(2) CASEEND SWITCHEND

                                           GENERATEEND}

IR *OptFromClause::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(from_clause_);
  res = new IR(kOptFromClause, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(1)
  res = new IR(kOptFromClause, string(""));
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptFromClause::deep_delete() {
  SAFEDELETE(from_clause_);
  delete this;
};

void OptFromClause::generate() {
  GENERATESTART(2)

  SWITCHSTART
  CASESTART(0)
  from_clause_ = new FromClause();
  from_clause_->generate();
  CASEEND
  CASESTART(1)

  CASEEND
  SWITCHEND

  GENERATEEND
}

IR *SelectTarget::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(expr_list_);
  res = new IR(kSelectTarget, OP3("", "", ""), tmp1);

  TRANSLATEEND
}

void SelectTarget::deep_delete() {
  SAFEDELETE(expr_list_);
  delete this;
};

void SelectTarget::generate() {
  GENERATESTART(1)

  expr_list_ = new ExprList();
  expr_list_->generate();

  GENERATEEND
}

void OptSelectTarget::deep_delete() {
  SAFEDELETE(select_target_);
  delete this;
};

void OptSelectTarget::generate() {
}

IR *OptSelectTarget::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART
  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(select_target_);
  res = new IR(kOptSelectTarget, OP0(), tmp1);
  CASEEND
  CASESTART(1)
  res = new IR(kOptSelectTarget, OP0());
  CASEEND
  SWITCHEND
  TRANSLATEEND
}

IR *OptWindowClause::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(window_clause_);
  res = new IR(kOptWindowClause, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(1)
  res = new IR(kOptWindowClause, string(""));
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptWindowClause::deep_delete() {
  SAFEDELETE(window_clause_);
  delete this;
};

void OptWindowClause::generate() {
  GENERATESTART(2)

  SWITCHSTART
  CASESTART(0)
  window_clause_ = new WindowClause();
  window_clause_->generate();
  CASEEND
  CASESTART(1)

  CASEEND
  SWITCHEND

  GENERATEEND
}

IR *WindowClause::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(window_def_list_);
  res = new IR(kWindowClause, OP3("WINDOW", "", ""), tmp1);

  TRANSLATEEND
}

void WindowClause::deep_delete() {
  SAFEDELETE(window_def_list_);
  delete this;
};

void WindowClause::generate() {
  GENERATESTART(1)

  window_def_list_ = new WindowDefList();
  window_def_list_->generate();

  GENERATEEND
}

IR *WindowDefList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(window_def_);
  res = new IR(kWindowDefList, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(window_def_);
  auto tmp2 = SAFETRANSLATE(window_def_list_);
  res = new IR(kWindowDefList, OP3("", ",", ""), tmp1, tmp2);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void WindowDefList::deep_delete() {
  SAFEDELETE(window_def_);
  SAFEDELETE(window_def_list_);
  delete this;
};

void WindowDefList::generate() {
  GENERATESTART(200)

  SWITCHSTART
  CASESTART(0)
  window_def_ = new WindowDef();
  window_def_->generate();
  CASEEND
  CASESTART(1)
  window_def_ = new WindowDef();
  window_def_->generate();
  window_def_list_ = new WindowDefList();
  window_def_list_->generate();
  CASEEND

default: {
  int tmp_case_idx = rand() % 1;
  switch (tmp_case_idx) {
    CASESTART(0)
    window_def_ = new WindowDef();
    window_def_->generate();
    case_idx_ = 0;
    CASEEND
  }
}
}

GENERATEEND
}

IR *WindowDef::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(window_name_);
  auto tmp2 = SAFETRANSLATE(window_);
  res = new IR(kWindowDef, OP3("", "AS (", ")"), tmp1, tmp2);

  TRANSLATEEND
}

void WindowDef::deep_delete() {
  SAFEDELETE(window_);
  SAFEDELETE(window_name_);
  delete this;
};

void WindowDef::generate() {
  GENERATESTART(1)

  window_name_ = new WindowName();
  window_name_->generate();
  window_ = new Window();
  window_->generate();

  GENERATEEND
}

IR *WindowName::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(identifier_);
  res = new IR(kWindowName, OP3("", "", ""), tmp1);

  TRANSLATEEND
}

void WindowName::deep_delete() {
  SAFEDELETE(identifier_);
  delete this;
};

void WindowName::generate() {
  GENERATESTART(1)

  identifier_ = new Identifier();
  identifier_->generate();

  GENERATEEND
}

IR *Window::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(opt_exist_window_name_);
  auto tmp2 = SAFETRANSLATE(opt_partition_);
  auto tmp3 = SAFETRANSLATE(opt_order_clause_);
  auto tmp4 = SAFETRANSLATE(opt_frame_clause_);
  auto tmp5 = new IR(kUnknown, OP3("", "", ""), tmp1, tmp2);
  PUSH(tmp5);
  auto tmp6 = new IR(kUnknown, OP3("", "", ""), tmp5, tmp3);
  PUSH(tmp6);
  res = new IR(kWindow, OP3("", "", ""), tmp6, tmp4);

  TRANSLATEEND
}

void Window::deep_delete() {
  SAFEDELETE(opt_exist_window_name_);
  SAFEDELETE(opt_frame_clause_);
  SAFEDELETE(opt_partition_);
  SAFEDELETE(opt_order_clause_);
  delete this;
};

void Window::generate() {
  GENERATESTART(1)

  opt_exist_window_name_ = new OptExistWindowName();
  opt_exist_window_name_->generate();
  opt_partition_ = new OptPartition();
  opt_partition_->generate();
  opt_order_clause_ = new OptOrderClause();
  opt_order_clause_->generate();
  opt_frame_clause_ = new OptFrameClause();
  opt_frame_clause_->generate();

  GENERATEEND
}

IR *OptPartition::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(expr_list_);
  res = new IR(kOptPartition, OP3("PARTITION BY", "", ""), tmp1);
  CASEEND
  CASESTART(1)
  res = new IR(kOptPartition, string(""));
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptPartition::deep_delete() {
  SAFEDELETE(expr_list_);
  delete this;
};

void OptPartition::generate() {
  GENERATESTART(2)

  SWITCHSTART
  CASESTART(0)
  expr_list_ = new ExprList();
  expr_list_->generate();
  CASEEND
  CASESTART(1)

  CASEEND
  SWITCHEND

  GENERATEEND
}

IR *OptFrameClause::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(range_or_rows_);
  auto tmp2 = SAFETRANSLATE(frame_bound_start_);
  auto tmp3 = SAFETRANSLATE(opt_frame_exclude_);
  auto tmp4 = new IR(kUnknown, OP3("", "", ""), tmp1, tmp2);
  PUSH(tmp4);
  res = new IR(kOptFrameClause, OP3("", "", ""), tmp4, tmp3);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(range_or_rows_);
  auto tmp2 = SAFETRANSLATE(frame_bound_start_);
  auto tmp3 = SAFETRANSLATE(frame_bound_end_);
  auto tmp4 = SAFETRANSLATE(opt_frame_exclude_);
  auto tmp5 = new IR(kUnknown, OP3("", "BETWEEN", "AND"), tmp1, tmp2);
  PUSH(tmp5);
  auto tmp6 = new IR(kUnknown, OP3("", "", ""), tmp5, tmp3);
  PUSH(tmp6);
  res = new IR(kOptFrameClause, OP3("", "", ""), tmp6, tmp4);
  CASEEND
  CASESTART(2)
  res = new IR(kOptFrameClause, string(""));
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptFrameClause::deep_delete() {
  SAFEDELETE(frame_bound_start_);
  SAFEDELETE(opt_frame_exclude_);
  SAFEDELETE(range_or_rows_);
  SAFEDELETE(frame_bound_end_);
  delete this;
};

void OptFrameClause::generate() {
  GENERATESTART(3)

  SWITCHSTART
  CASESTART(0)
  range_or_rows_ = new RangeOrRows();
  range_or_rows_->generate();
  frame_bound_start_ = new FrameBoundStart();
  frame_bound_start_->generate();
  opt_frame_exclude_ = new OptFrameExclude();
  opt_frame_exclude_->generate();
  CASEEND
  CASESTART(1)
  range_or_rows_ = new RangeOrRows();
  range_or_rows_->generate();
  frame_bound_start_ = new FrameBoundStart();
  frame_bound_start_->generate();
  frame_bound_end_ = new FrameBoundEnd();
  frame_bound_end_->generate();
  opt_frame_exclude_ = new OptFrameExclude();
  opt_frame_exclude_->generate();
  CASEEND
  CASESTART(2)

  CASEEND
  SWITCHEND

  GENERATEEND
}

IR *RangeOrRows::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  res = new IR(kRangeOrRows, OP3("RANGE", "", ""));
  CASEEND
  CASESTART(1)
  res = new IR(kRangeOrRows, OP3("ROWS", "", ""));
  CASEEND
  CASESTART(2)
  res = new IR(kRangeOrRows, OP3("GROUPS", "", ""));
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void RangeOrRows::deep_delete() { delete this; };

void RangeOrRows::generate(){GENERATESTART(3)

                                 SWITCHSTART CASESTART(0) CASEEND CASESTART(1)
                                     CASEEND CASESTART(2) CASEEND SWITCHEND

                                         GENERATEEND}

IR *FrameBoundStart::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(frame_bound_);
  res = new IR(kFrameBoundStart, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(1)
  res = new IR(kFrameBoundStart, OP3("UNBOUNDED PRECEDING", "", ""));
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void FrameBoundStart::deep_delete() {
  SAFEDELETE(frame_bound_);
  delete this;
};

void FrameBoundStart::generate() {
  GENERATESTART(2)

  SWITCHSTART
  CASESTART(0)
  frame_bound_ = new FrameBound();
  frame_bound_->generate();
  CASEEND
  CASESTART(1)
  CASEEND
  SWITCHEND

  GENERATEEND
}

IR *FrameBoundEnd::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(frame_bound_);
  res = new IR(kFrameBoundEnd, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(1)
  res = new IR(kFrameBoundEnd, OP3("UNBOUNDED FOLLOWING", "", ""));
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void FrameBoundEnd::deep_delete() {
  SAFEDELETE(frame_bound_);
  delete this;
};

void FrameBoundEnd::generate() {
  GENERATESTART(2)

  SWITCHSTART
  CASESTART(0)
  frame_bound_ = new FrameBound();
  frame_bound_->generate();
  CASEEND
  CASESTART(1)
  CASEEND
  SWITCHEND

  GENERATEEND
}

IR *FrameBound::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(expr_);
  res = new IR(kFrameBound, OP3("", "PRECEDING", ""), tmp1);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(expr_);
  res = new IR(kFrameBound, OP3("", "FOLLOWING", ""), tmp1);
  CASEEND
  CASESTART(2)
  res = new IR(kFrameBound, OP3("CURRENT ROW", "", ""));
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void FrameBound::deep_delete() {
  SAFEDELETE(expr_);
  delete this;
};

void FrameBound::generate() {
  GENERATESTART(3)

  SWITCHSTART
  CASESTART(0)
  expr_ = new Expr();
  expr_->generate();
  CASEEND
  CASESTART(1)
  expr_ = new Expr();
  expr_->generate();
  CASEEND
  CASESTART(2)
  CASEEND
  SWITCHEND

  GENERATEEND
}

IR *OptFrameExclude::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(frame_exclude_);
  res = new IR(kOptFrameExclude, OP3("EXCLUDE", "", ""), tmp1);
  CASEEND
  CASESTART(1)
  res = new IR(kOptFrameExclude, string(""));
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptFrameExclude::deep_delete() {
  SAFEDELETE(frame_exclude_);
  delete this;
};

void OptFrameExclude::generate() {
  GENERATESTART(2)

  SWITCHSTART
  CASESTART(0)
  frame_exclude_ = new FrameExclude();
  frame_exclude_->generate();
  CASEEND
  CASESTART(1)

  CASEEND
  SWITCHEND

  GENERATEEND
}

IR *FrameExclude::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  res = new IR(kFrameExclude, OP3("NO OTHERS", "", ""));
  CASEEND
  CASESTART(1)
  res = new IR(kFrameExclude, OP3("CURRENT ROW", "", ""));
  CASEEND
  CASESTART(2)
  res = new IR(kFrameExclude, OP3("GROUP", "", ""));
  CASEEND
  CASESTART(3)
  res = new IR(kFrameExclude, OP3("TIES", "", ""));
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void FrameExclude::deep_delete() { delete this; };

void FrameExclude::generate(){GENERATESTART(4)

                                  SWITCHSTART CASESTART(0) CASEEND CASESTART(1)
                                      CASEEND CASESTART(2) CASEEND CASESTART(3)
                                          CASEEND SWITCHEND

                                              GENERATEEND}

IR *OptExistWindowName::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(identifier_);
  res = new IR(kOptExistWindowName, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(1)
  res = new IR(kOptExistWindowName, string(""));
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptExistWindowName::deep_delete() {
  SAFEDELETE(identifier_);
  delete this;
};

void OptExistWindowName::generate() {
  GENERATESTART(2)

  SWITCHSTART
  CASESTART(0)
  identifier_ = new Identifier();
  identifier_->generate();
  CASEEND
  CASESTART(1)

  CASEEND
  SWITCHEND

  GENERATEEND
}

IR *OptGroupClause::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(group_clause_);
  res = new IR(kOptGroupClause, OP0(), tmp1);
  CASEEND
  CASESTART(1)
  res = new IR(kOptGroupClause, OP0());
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptGroupClause::deep_delete() {
  SAFEDELETE(group_clause_);
  delete this;
};

void OptGroupClause::generate() {
}

IR *GroupClause::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART
  SWITCHSTART
  CASESTART(0)
  auto tmp0 = SAFETRANSLATE(expr_list_);
  auto tmp1 = SAFETRANSLATE(opt_having_clause_);
  res = new IR(kGroupClause, OP1("GROUP BY"), tmp0, tmp1);
  CASEEND
  SWITCHEND
  TRANSLATEEND
}

void GroupClause::deep_delete() {
  SAFEDELETE(expr_list_);
  SAFEDELETE(opt_having_clause_);
  delete this;
};

void GroupClause::generate() {
}

IR *OptHavingClause::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(having_clause_);
  res = new IR(kOptHavingClause, OP0(), tmp1);
  CASEEND
  CASESTART(1)
  res = new IR(kOptHavingClause, OP0());
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptHavingClause::deep_delete() {
  SAFEDELETE(having_clause_);
  delete this;
};

void OptHavingClause::generate() {
}

IR *HavingClause::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp0 = SAFETRANSLATE(expr_);
  res = new IR(kHavingClause, OP1("HAVING"), tmp0);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void HavingClause::deep_delete() {
  SAFEDELETE(expr_);
  delete this;
};

void HavingClause::generate() {
}

IR *OptWhereClause::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(where_clause_);
  res = new IR(kOptWhereClause, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(1)
  res = new IR(kOptWhereClause, string(""));
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptWhereClause::deep_delete() {
  SAFEDELETE(where_clause_);
  delete this;
};

void OptWhereClause::generate() {
  GENERATESTART(2)

  SWITCHSTART
  CASESTART(0)
  where_clause_ = new WhereClause();
  where_clause_->generate();
  CASEEND
  CASESTART(1)

  CASEEND
  SWITCHEND

  GENERATEEND
}

IR *WhereClause::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART
  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(expr_);
  res = new IR(kWhereClause, OP3("WHERE", "", ""), tmp1);
  CASEEND
  SWITCHEND
  TRANSLATEEND
}

void WhereClause::deep_delete() {
  SAFEDELETE(expr_);
  delete this;
};

void WhereClause::generate() {
  GENERATESTART(1)

  expr_ = new Expr();
  expr_->generate();

  GENERATEEND
}

IR *FromClause::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(table_ref_);
  res = new IR(kFromClause, OP3("FROM", "", ""), tmp1);

  TRANSLATEEND
}

void FromClause::deep_delete() {
  SAFEDELETE(table_ref_);
  delete this;
};

void FromClause::generate() {
  GENERATESTART(1)

  table_ref_ = new TableRef();
  table_ref_->generate();

  GENERATEEND
}

IR *TableRef::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(opt_table_prefix_);
  auto tmp2 = SAFETRANSLATE(table_name_);
  auto tmp3 = SAFETRANSLATE(opt_on_or_using_);
  auto tmp4 = new IR(kUnknown, OP3("", "", ""), tmp1, tmp2);
  PUSH(tmp4);
  res = new IR(kTableRef, OP3("", "", ""), tmp4, tmp3);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(opt_table_prefix_);
  auto tmp2 = SAFETRANSLATE(select_no_parens_);
  auto tmp3 = SAFETRANSLATE(opt_on_or_using_);
  auto tmp4 = SAFETRANSLATE(opt_alias_);
  auto tmp5 = new IR(kUnknown, OP3("", "(", ")"), tmp1, tmp2);
  PUSH(tmp5);
  res = new IR(kUnknown, OP3("", "", ""), tmp5, tmp3);
  PUSH(res);
  res = new IR(kTableRef, OP3("", "", ""), res, tmp4);
  CASEEND
  CASESTART(2)
  auto tmp1 = SAFETRANSLATE(opt_table_prefix_);
  auto tmp2 = SAFETRANSLATE(table_ref_);
  auto tmp3 = SAFETRANSLATE(opt_on_or_using_);
  auto tmp4 = new IR(kUnknown, OP3("", "(", ")"), tmp1, tmp2);
  PUSH(tmp4);
  res = new IR(kTableRef, OP3("", "", ""), tmp4, tmp3);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void TableRef::deep_delete() {
  SAFEDELETE(select_no_parens_);
  SAFEDELETE(table_ref_);
  SAFEDELETE(table_name_);
  SAFEDELETE(opt_table_prefix_);
  SAFEDELETE(opt_on_or_using_);
  SAFEDELETE(opt_alias_);
  delete this;
};

void TableRef::generate() {
  GENERATESTART(300)

  SWITCHSTART
  CASESTART(0)
  opt_table_prefix_ = new OptTablePrefix();
  opt_table_prefix_->generate();
  table_name_ = new TableName();
  table_name_->generate();
  opt_on_or_using_ = new OptOnOrUsing();
  opt_on_or_using_->generate();
  CASEEND
  CASESTART(1)
  opt_table_prefix_ = new OptTablePrefix();
  opt_table_prefix_->generate();
  select_no_parens_ = new SelectNoParens();
  select_no_parens_->generate();
  opt_on_or_using_ = new OptOnOrUsing();
  opt_on_or_using_->generate();
  opt_alias_ = new OptAlias();
  opt_alias_->generate();
  CASEEND
  CASESTART(2)
  opt_table_prefix_ = new OptTablePrefix();
  opt_table_prefix_->generate();
  table_ref_ = new TableRef();
  table_ref_->generate();
  opt_on_or_using_ = new OptOnOrUsing();
  opt_on_or_using_->generate();
  CASEEND

default: {
  int tmp_case_idx = rand() % 2;
  switch (tmp_case_idx) {
    CASESTART(0)
    opt_table_prefix_ = new OptTablePrefix();
    opt_table_prefix_->generate();
    table_name_ = new TableName();
    table_name_->generate();
    opt_on_or_using_ = new OptOnOrUsing();
    opt_on_or_using_->generate();
    case_idx_ = 0;
    CASEEND
    CASESTART(1)
    opt_table_prefix_ = new OptTablePrefix();
    opt_table_prefix_->generate();
    select_no_parens_ = new SelectNoParens();
    select_no_parens_->generate();
    opt_on_or_using_ = new OptOnOrUsing();
    opt_on_or_using_->generate();
    case_idx_ = 1;
    CASEEND
  }
}
}

GENERATEEND
}

IR *OptOnOrUsing::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(on_or_using_);
  res = new IR(kOptOnOrUsing, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(1)
  res = new IR(kOptOnOrUsing, string(""));
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptOnOrUsing::deep_delete() {
  SAFEDELETE(on_or_using_);
  delete this;
};

void OptOnOrUsing::generate() {
  GENERATESTART(2)

  SWITCHSTART
  CASESTART(0)
  on_or_using_ = new OnOrUsing();
  on_or_using_->generate();
  CASEEND
  CASESTART(1)

  CASEEND
  SWITCHEND

  GENERATEEND
}

IR *OnOrUsing::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(expr_);
  res = new IR(kOnOrUsing, OP3("ON", "", ""), tmp1);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(column_name_list_);
  res = new IR(kOnOrUsing, OP3("USING (", ")", ""), tmp1);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OnOrUsing::deep_delete() {
  SAFEDELETE(expr_);
  SAFEDELETE(column_name_list_);
  delete this;
};

void OnOrUsing::generate() {
  GENERATESTART(2)

  SWITCHSTART
  CASESTART(0)
  expr_ = new Expr();
  expr_->generate();
  CASEEND
  CASESTART(1)
  column_name_list_ = new ColumnNameList();
  column_name_list_->generate();
  CASEEND
  SWITCHEND

  GENERATEEND
}

IR *ColumnNameList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(column_name_);
  res = new IR(kColumnNameList, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(column_name_);
  auto tmp2 = SAFETRANSLATE(column_name_list_);
  res = new IR(kColumnNameList, OP3("", ",", ""), tmp1, tmp2);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void ColumnNameList::deep_delete() {
  SAFEDELETE(column_name_list_);
  SAFEDELETE(column_name_);
  delete this;
};

void ColumnNameList::generate() {
  GENERATESTART(200)

  SWITCHSTART
  CASESTART(0)
  column_name_ = new ColumnName();
  column_name_->generate();
  CASEEND
  CASESTART(1)
  column_name_ = new ColumnName();
  column_name_->generate();
  column_name_list_ = new ColumnNameList();
  column_name_list_->generate();
  CASEEND

default: {
  int tmp_case_idx = rand() % 1;
  switch (tmp_case_idx) {
    CASESTART(0)
    column_name_ = new ColumnName();
    column_name_->generate();
    case_idx_ = 0;
    CASEEND
  }
}
}

GENERATEEND
}

IR *OptTablePrefix::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(table_ref_);
  auto tmp2 = SAFETRANSLATE(join_op_);
  res = new IR(kOptTablePrefix, OP3("", "", ""), tmp1, tmp2);
  CASEEND
  CASESTART(1)
  res = new IR(kOptTablePrefix, string(""));
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptTablePrefix::deep_delete() {
  SAFEDELETE(join_op_);
  SAFEDELETE(table_ref_);
  delete this;
};

void OptTablePrefix::generate() {
  GENERATESTART(2)

  SWITCHSTART
  CASESTART(0)
  table_ref_ = new TableRef();
  table_ref_->generate();
  join_op_ = new JoinOp();
  join_op_->generate();
  CASEEND
  CASESTART(1)

  CASEEND
  SWITCHEND

  GENERATEEND
}

IR *JoinOp::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  res = new IR(kJoinOp, OP3(",", "", ""));
  CASEEND
  CASESTART(1)
  res = new IR(kJoinOp, OP3("JOIN", "", ""));
  CASEEND
  CASESTART(2)
  auto tmp1 = SAFETRANSLATE(opt_join_type_);
  res = new IR(kJoinOp, OP3("NATURAL", "JOIN", ""), tmp1);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void JoinOp::deep_delete() {
  SAFEDELETE(opt_join_type_);
  delete this;
};

void JoinOp::generate() {
  GENERATESTART(3)

  SWITCHSTART
  CASESTART(0)
  CASEEND
  CASESTART(1)
  CASEEND
  CASESTART(2)
  opt_join_type_ = new OptJoinType();
  opt_join_type_->generate();
  CASEEND
  SWITCHEND

  GENERATEEND
}

IR *OptJoinType::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  res = new IR(kOptJoinType, OP3("LEFT", "", ""));
  CASEEND
  CASESTART(1)
  res = new IR(kOptJoinType, OP3("LEFT OUTER", "", ""));
  CASEEND
  CASESTART(2)
  res = new IR(kOptJoinType, OP3("INNER", "", ""));
  CASEEND
  CASESTART(3)
  res = new IR(kOptJoinType, OP3("CROSS", "", ""));
  CASEEND
  CASESTART(4)
  res = new IR(kOptJoinType, string(""));
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptJoinType::deep_delete() { delete this; };

void OptJoinType::generate(){GENERATESTART(5)

                                 SWITCHSTART CASESTART(0) CASEEND CASESTART(1)
                                     CASEEND CASESTART(2) CASEEND CASESTART(3)
                                         CASEEND CASESTART(4)

                                             CASEEND SWITCHEND

                                                 GENERATEEND}

IR *ExprList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(expr_);
  auto tmp2 = SAFETRANSLATE(expr_list_);
  res = new IR(kExprList, OP3("", ",", ""), tmp1, tmp2);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(expr_);
  res = new IR(kExprList, OP3("", "", ""), tmp1);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void ExprList::deep_delete() {
  SAFEDELETE(expr_);
  SAFEDELETE(expr_list_);
  delete this;
};

void ExprList::generate() {
  GENERATESTART(200)

  SWITCHSTART
  CASESTART(0)
  expr_ = new Expr();
  expr_->generate();
  expr_list_ = new ExprList();
  expr_list_->generate();
  CASEEND
  CASESTART(1)
  expr_ = new Expr();
  expr_->generate();
  CASEEND

default: {
  int tmp_case_idx = rand() % 1;
  switch (tmp_case_idx) {
    CASESTART(0)
    expr_ = new Expr();
    expr_->generate();
    case_idx_ = 1;
    CASEEND
  }
}
}

GENERATEEND
}

IR *OptLimitClause::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(limit_clause_);
  res = new IR(kOptLimitClause, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(1)
  res = new IR(kOptLimitClause, string(""));
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptLimitClause::deep_delete() {
  SAFEDELETE(limit_clause_);
  delete this;
};

void OptLimitClause::generate() {
  GENERATESTART(2)

  SWITCHSTART
  CASESTART(0)
  limit_clause_ = new LimitClause();
  limit_clause_->generate();
  CASEEND
  CASESTART(1)

  CASEEND
  SWITCHEND

  GENERATEEND
}

IR *LimitClause::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(expr_1_);
  res = new IR(kLimitClause, OP3("LIMIT", "", ""), tmp1);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(expr_1_);
  auto tmp2 = SAFETRANSLATE(expr_2_);
  res = new IR(kLimitClause, OP3("LIMIT", "OFFSET", ""), tmp1, tmp2);
  CASEEND
  CASESTART(2)
  auto tmp1 = SAFETRANSLATE(expr_1_);
  auto tmp2 = SAFETRANSLATE(expr_2_);
  res = new IR(kLimitClause, OP3("LIMIT", ",", ""), tmp1, tmp2);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void LimitClause::deep_delete() {
  SAFEDELETE(expr_1_);
  SAFEDELETE(expr_2_);
  delete this;
};

void LimitClause::generate() {
  GENERATESTART(3)

  SWITCHSTART
  CASESTART(0)
  expr_1_ = new Expr();
  expr_1_->generate();
  CASEEND
  CASESTART(1)
  expr_1_ = new Expr();
  expr_1_->generate();
  expr_2_ = new Expr();
  expr_2_->generate();
  CASEEND
  CASESTART(2)
  expr_1_ = new Expr();
  expr_1_->generate();
  expr_2_ = new Expr();
  expr_2_->generate();
  CASEEND
  SWITCHEND

  GENERATEEND
}

IR *OptOrderClause::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART
  SWITCHSTART
  CASESTART(0)
  auto tmp0 = SAFETRANSLATE(order_clause_);
  res = new IR(kOptOrderClause, OP0(), tmp0);
  CASEEND
  CASESTART(1)
  res = new IR(kOptOrderClause, OP0());
  CASEEND
  SWITCHEND
  TRANSLATEEND
}

void OptOrderClause::deep_delete() {
  SAFEDELETE(order_clause_);
  delete this;
};

void OptOrderClause::generate() {
}

IR *SelectLimit::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART
  SWITCHSTART
  CASESTART(0)
  auto tmp0 = SAFETRANSLATE(limit_clause_);
  res = new IR(kSelectLimit, OP0(), tmp0);
  CASEEND
  SWITCHEND
  TRANSLATEEND
}

void SelectLimit::deep_delete() {
  SAFEDELETE(limit_clause_);
  delete this;
};

void SelectLimit::generate() {
}

IR *OptSelectLimit::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART
  SWITCHSTART
  CASESTART(0)
  auto tmp0 = SAFETRANSLATE(opt_limit_clause_);
  res = new IR(kOptSelectLimit, OP0(), tmp0);
  CASEEND
  SWITCHEND
  TRANSLATEEND
}

void OptSelectLimit::deep_delete() {
  SAFEDELETE(opt_limit_clause_);
  delete this;
};

void OptSelectLimit::generate() {
}

IR *ForLockingStrength::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART
  SWITCHSTART
  CASESTART(0)
  res = new IR(kForLockingStrength, OP1("FOR UPDATE"));
  CASEEND
  CASESTART(1)
  res = new IR(kForLockingStrength, OP1("FOR NO KEY UPDATE"));
  CASEEND
  CASESTART(2)
  res = new IR(kForLockingStrength, OP1("FOR SHARE"));
  CASEEND
  CASESTART(3)
  res = new IR(kForLockingStrength, OP1("FOR KEY SHARE"));
  CASEEND
  SWITCHEND
  TRANSLATEEND
}

void ForLockingStrength::deep_delete() {
  delete this;
};

void ForLockingStrength::generate() {
}

IR *LockedRelsList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART
  SWITCHSTART
  CASESTART(0)
  auto tmp0 = SAFETRANSLATE(table_name_list_);
  res = new IR(kLockedRelsList, OP1("OF"), tmp0);
  CASEEND
  CASESTART(1)
  res = new IR(kLockedRelsList, OP0());
  CASEEND
  SWITCHEND
  TRANSLATEEND
}

void LockedRelsList::deep_delete() {
  SAFEDELETE(table_name_list_);
  delete this;
};

void LockedRelsList::generate() {
}

IR *TableNameList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART
  SWITCHSTART
  CASESTART(0)
  auto tmp0 = SAFETRANSLATE(table_name_);
  res = new IR(kTableNameList, OP0(), tmp0);
  CASEEND
  CASESTART(1)
  auto tmp0 = SAFETRANSLATE(table_name_);
  auto tmp1 = SAFETRANSLATE(table_name_list_);
  res = new IR(kTableNameList, OPMID(","), tmp0, tmp1);
  CASEEND
  SWITCHEND
  TRANSLATEEND
}

void TableNameList::deep_delete() {
  SAFEDELETE(table_name_list_);
  SAFEDELETE(table_name_);
  delete this;
};

void TableNameList::generate() {
}

IR *OptOrderNulls::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  res = new IR(kOptOrderNulls, OP3("NULLS FIRST", "", ""));
  CASEEND
  CASESTART(1)
  res = new IR(kOptOrderNulls, OP3("NULLS LAST", "", ""));
  CASEEND
  CASESTART(2)
  res = new IR(kOptOrderNulls, string(""));
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptOrderNulls::deep_delete() { delete this; };

void OptOrderNulls::generate(){GENERATESTART(3)

                                   SWITCHSTART CASESTART(0) CASEEND CASESTART(1)
                                       CASEEND CASESTART(2)

                                           CASEEND SWITCHEND

                                               GENERATEEND}

IR *OrderItemList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(order_item_);
  res = new IR(kOrderItemList, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(order_item_);
  auto tmp2 = SAFETRANSLATE(order_item_list_);
  res = new IR(kOrderItemList, OP3("", ",", ""), tmp1, tmp2);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OrderItemList::deep_delete() {
  SAFEDELETE(order_item_);
  SAFEDELETE(order_item_list_);
  delete this;
};

void OrderItemList::generate() {
  GENERATESTART(200)

  SWITCHSTART
  CASESTART(0)
  order_item_ = new OrderItem();
  order_item_->generate();
  CASEEND
  CASESTART(1)
  order_item_ = new OrderItem();
  order_item_->generate();
  order_item_list_ = new OrderItemList();
  order_item_list_->generate();
  CASEEND

default: {
  int tmp_case_idx = rand() % 1;
  switch (tmp_case_idx) {
    CASESTART(0)
    order_item_ = new OrderItem();
    order_item_->generate();
    case_idx_ = 0;
    CASEEND
  }
}
}

GENERATEEND
}

IR *OrderItem::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(expr_);
  auto tmp2 = SAFETRANSLATE(opt_order_behavior_);
  auto tmp3 = SAFETRANSLATE(opt_order_nulls_);
  auto tmp4 = new IR(kUnknown, OP3("", "", ""), tmp1, tmp2);
  PUSH(tmp4);
  res = new IR(kOrderItem, OP3("", "", ""), tmp4, tmp3);

  TRANSLATEEND
}

void OrderItem::deep_delete() {
  SAFEDELETE(expr_);
  SAFEDELETE(opt_order_nulls_);
  SAFEDELETE(opt_order_behavior_);
  delete this;
};

void OrderItem::generate() {
  GENERATESTART(1)

  expr_ = new Expr();
  expr_->generate();
  opt_order_behavior_ = new OptOrderBehavior();
  opt_order_behavior_->generate();
  opt_order_nulls_ = new OptOrderNulls();
  opt_order_nulls_->generate();

  GENERATEEND
}

IR *OptOrderBehavior::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  res = new IR(kOptOrderBehavior, OP3("ASC", "", ""));
  CASEEND
  CASESTART(1)
  res = new IR(kOptOrderBehavior, OP3("DESC", "", ""));
  CASEEND
  CASESTART(2)
  res = new IR(kOptOrderBehavior, string(""));
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptOrderBehavior::deep_delete() { delete this; };

void OptOrderBehavior::generate(){
    GENERATESTART(3)

        SWITCHSTART CASESTART(0) CASEEND CASESTART(1) CASEEND CASESTART(2)

            CASEEND SWITCHEND

                GENERATEEND}

IR *OptWithClause::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(with_clause_);
  res = new IR(kOptWithClause, OP0(), tmp1);
  CASEEND
  CASESTART(1)
  res = new IR(kOptWithClause, OP0());
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptWithClause::deep_delete() {
  SAFEDELETE(with_clause_);
  delete this;
};

void OptWithClause::generate() {
}

IR *WithClause::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(cte_list_);
  res = new IR(kWithClause, OP1("WITH"), tmp1);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(cte_list_);
  res = new IR(kWithClause, OP1("WITH_LA"), tmp1);
  CASEEND
  CASESTART(2)
  auto tmp1 = SAFETRANSLATE(cte_list_);
  res = new IR(kWithClause, OP1("WITH RECURSIVE"), tmp1);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void WithClause::deep_delete() {
  SAFEDELETE(cte_list_);
  delete this;
};

void WithClause::generate() {
}

IR *CteList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(common_table_expr_);
  res = new IR(kCteList, OP0(), tmp1);
  CASEEND
  CASESTART(1)
  auto tmp0 = SAFETRANSLATE(cte_list_);
  auto tmp1 = SAFETRANSLATE(common_table_expr_);
  res = new IR(kCteList, OPMID(","), tmp0, tmp1);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void CteList::deep_delete() {
  SAFEDELETE(common_table_expr_);
  SAFEDELETE(cte_list_);
  delete this;
};

void CteList::generate() {
}

IR *CommonTableExpr::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART
  auto tmp1 = SAFETRANSLATE(table_name_);
  auto tmp2 = SAFETRANSLATE(column_name_list_);
  auto tmp3 = SAFETRANSLATE(opt_materialized_);
  auto tmp4 = SAFETRANSLATE(preparable_stmt_);

  res = new IR(kUnknown, OP0(), tmp1, tmp2);
  PUSH(res);
  res = new IR(kUnknown, OPMID("AS"), res, tmp3);
  PUSH(res);
  res = new IR(kCommonTableExpr, OP3("", "(", ")"), res, tmp4);
  TRANSLATEEND
}

void CommonTableExpr::deep_delete() {
  SAFEDELETE(table_name_);
  SAFEDELETE(column_name_list_);
  SAFEDELETE(opt_materialized_);
  SAFEDELETE(preparable_stmt_);
  delete this;
};

void CommonTableExpr::generate() {
}


IR *IntoClause::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART
  SWITCHSTART
  CASESTART(0)
  auto tmp0 = SAFETRANSLATE(opt_temp_table_name_);
  res = new IR(kIntoClause, OP3("INTO", "", ""), tmp0);
  CASEEND
  CASESTART(1)
  res = new IR(kIntoClause, OP0());
  CASEEND

  SWITCHEND
  TRANSLATEEND
}

void IntoClause::deep_delete() {
  SAFEDELETE(opt_temp_table_name_);
  delete this;
};

void IntoClause::generate() {
}

IR *OptTempTableName::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART
  SWITCHSTART
  CASESTART(0)
  auto tmp0 = SAFETRANSLATE(opt_table_);
  auto tmp1 = SAFETRANSLATE(table_name_);
  res = new IR(kOptTempTableName, OP3("TEMPORARY", "", ""), tmp0, tmp1);
  CASEEND
  CASESTART(1)
  auto tmp0 = SAFETRANSLATE(opt_table_);
  auto tmp1 = SAFETRANSLATE(table_name_);
  res = new IR(kOptTempTableName, OP3("TEMP", "", ""), tmp0, tmp1);
  CASEEND
  CASESTART(2)
  auto tmp0 = SAFETRANSLATE(opt_table_);
  auto tmp1 = SAFETRANSLATE(table_name_);
  res = new IR(kOptTempTableName, OP3("LOCAL TEMPORARY", "", ""), tmp0, tmp1);
  CASEEND
  CASESTART(3)
  auto tmp0 = SAFETRANSLATE(opt_table_);
  auto tmp1 = SAFETRANSLATE(table_name_);
  res = new IR(kOptTempTableName, OP3("LOCAL TEMP", "", ""), tmp0, tmp1);
  CASEEND
  CASESTART(4)
  auto tmp0 = SAFETRANSLATE(opt_table_);
  auto tmp1 = SAFETRANSLATE(table_name_);
  res = new IR(kOptTempTableName, OP3("GLOBAL TEMPORARY", "", ""), tmp0, tmp1);
  CASEEND
  CASESTART(5)
  auto tmp0 = SAFETRANSLATE(opt_table_);
  auto tmp1 = SAFETRANSLATE(table_name_);
  res = new IR(kOptTempTableName, OP3("GLOBAL TEMP", "", ""), tmp0, tmp1);
  CASEEND
  CASESTART(6)
  auto tmp0 = SAFETRANSLATE(opt_table_);
  auto tmp1 = SAFETRANSLATE(table_name_);
  res = new IR(kOptTempTableName, OP3("UNLOGGED", "", ""), tmp0, tmp1);
  CASEEND
  CASESTART(7)
  auto tmp0 = SAFETRANSLATE(table_name_);
  res = new IR(kOptTempTableName, OP3("TABLE", "", ""), tmp0);
  CASEEND
  CASESTART(8)
  res = new IR(kOptTempTableName, OP3("TABLE", "", ""));
  CASEEND
  SWITCHEND
  TRANSLATEEND
}

void OptTempTableName::deep_delete() {
  SAFEDELETE(table_name_);
  SAFEDELETE(opt_table_);
  delete this;
};

void OptTempTableName::generate() {

}

IR *OptTable::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART
  SWITCHSTART
  CASESTART(0)
  res = new IR(kOptTable, "TABLE");
  CASEEND
  CASESTART(1)
  res = new IR(kOptTable, "");
  CASEEND
  SWITCHEND
  TRANSLATEEND
}

void OptTable::deep_delete() {
  delete this;
};

void OptTable::generate() {
}


IR *CteTableName::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(table_name_);
  auto tmp2 = SAFETRANSLATE(opt_column_name_list_p_);
  res = new IR(kCteTableName, OP3("", "", ""), tmp1, tmp2);

  TRANSLATEEND
}

void CteTableName::deep_delete() {
  SAFEDELETE(opt_column_name_list_p_);
  SAFEDELETE(table_name_);
  delete this;
};

void CteTableName::generate() {
  GENERATESTART(1)

  table_name_ = new TableName();
  table_name_->generate();
  opt_column_name_list_p_ = new OptColumnNameListP();
  opt_column_name_list_p_->generate();

  GENERATEEND
}

IR *OptAllOrDistinct::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp0 = SAFETRANSLATE(all_or_distinct_);
  res = new IR(kOptAllOrDistinct, OP0(), tmp0);
  CASEEND
  CASESTART(1)
  res = new IR(kOptAllOrDistinct, string(""));
  CASEEND
  SWITCHEND
  TRANSLATEEND
}

void OptAllOrDistinct::deep_delete() { 
  SAFEDELETE(all_or_distinct_);
  delete this; 
};

void OptAllOrDistinct::generate(){
}

IR *AllorDistinct::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART
  SWITCHSTART
  CASESTART(0)
  res = new IR(kAllorDistinct, OP1("ALL"));
  CASEEND
  CASESTART(1)
  res = new IR(kAllorDistinct, OP1("DISTINCT"));
  CASEEND
  SWITCHEND
  TRANSLATEEND
}

void AllorDistinct::deep_delete() { 
  delete this; 
}

void AllorDistinct::generate(){
}

void OptAllClause::deep_delete() { 
  delete this; 
};

void OptAllClause::generate(){
}

IR *OptAllClause::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART
  SWITCHSTART
  CASESTART(0)
  res = new IR(kOptAllClause, OP1("ALL"));
  CASEEND
  CASESTART(1)
  res = new IR(kOptAllClause, OP0());
  CASEEND
  SWITCHEND
  TRANSLATEEND
}

void ForLockingItemList::deep_delete() { 
  SAFEDELETE(for_locking_item_list_);
  SAFEDELETE(for_locking_item_);
  delete this; 
};

void ForLockingItemList::generate(){
}

IR *ForLockingItemList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART
  SWITCHSTART
  CASESTART(0)
  auto tmp0 = SAFETRANSLATE(for_locking_item_);
  res = new IR(kForLockingItemList, OP0(), tmp0);
  CASEEND
  CASESTART(1)
  auto tmp0 = SAFETRANSLATE(for_locking_item_list_);
  auto tmp1 = SAFETRANSLATE(for_locking_item_);
  res = new IR(kForLockingItemList, OP0(), tmp0, tmp1);
  CASEEND
  SWITCHEND
  TRANSLATEEND
}

IR *DistinctClause::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART
  SWITCHSTART
  CASESTART(0)
  res = new IR(kDistinctClause, OP1("DISTINCT"));
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(expr_list_);
  res = new IR(kDistinctClause, OP3("DISTINCT ON", "", ""), tmp1);
  CASEEND
  SWITCHEND
  TRANSLATEEND
}

void DistinctClause::deep_delete() { 
  SAFEDELETE(expr_list_);
  delete this; 
}

void DistinctClause::generate(){
}

IR *OptMaterialized::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART
  SWITCHSTART
  CASESTART(0)
  res = new IR(kOptMaterialized, OP1("MATERIALIZED"));
  CASEEND
  CASESTART(1)
  res = new IR(kOptMaterialized, OP1("NOT MATERIALIZED"));
  CASEEND
  CASESTART(2)
  res = new IR(kOptMaterialized, OP0());
  CASEEND
  SWITCHEND
  TRANSLATEEND
}

void OptMaterialized::deep_delete() { 
  delete this; 
}

void OptMaterialized::generate(){
}

IR *OptNoWaitorSkip::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART
  SWITCHSTART
  CASESTART(0)
  res = new IR(kOptNoWaitorSkip, OP1("NOWAIT"));
  CASEEND
  CASESTART(1)
  res = new IR(kOptNoWaitorSkip, OP1("SKIP LOCKED"));
  CASEEND
  CASESTART(2)
  res = new IR(kOptNoWaitorSkip, OP0());
  CASEEND
  SWITCHEND
  TRANSLATEEND
}

void OptNoWaitorSkip::deep_delete() { 
  delete this; 
}

void OptNoWaitorSkip::generate(){
}

IR *ForLockingItem::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART
  SWITCHSTART
  CASESTART(0)
  auto tmp0 = SAFETRANSLATE(for_locking_strength_);
  auto tmp1 = SAFETRANSLATE(locked_rels_list_);
  auto tmp2 = SAFETRANSLATE(opt_no_wait_or_skip_);
  res = new IR(kUnknown, OP0(), tmp0, tmp1);
  PUSH(res);
  res = new IR(kForLockingItem, OP0(), res, tmp2);
  CASEEND
  SWITCHEND
  TRANSLATEEND
}

void ForLockingItem::deep_delete() { 
  SAFEDELETE(for_locking_strength_);
  SAFEDELETE(locked_rels_list_);
  SAFEDELETE(opt_no_wait_or_skip_);
  delete this; 
}

void ForLockingItem::generate(){
}

void ForLockingClause::deep_delete() {
  SAFEDELETE(for_locking_item_list_);
  delete this; 
}

void ForLockingClause::generate(){
}

IR *ForLockingClause::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART
  SWITCHSTART
  CASESTART(0)
  auto tmp0 = SAFETRANSLATE(for_locking_item_list_);
  res = new IR(kForLockingClause, OP0(), tmp0);
  CASEEND
  CASESTART(1)
  res = new IR(kForLockingClause, OP1("FOR READ ONLY"));
  CASEEND
  SWITCHEND
  TRANSLATEEND
}

void OptForLockingClause::deep_delete() {
  SAFEDELETE(for_locking_clause_);
  delete this; 
}

void OptForLockingClause::generate(){
}

IR *OptForLockingClause::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART
  SWITCHSTART
  CASESTART(0)
  auto tmp0 = SAFETRANSLATE(for_locking_clause_);
  res = new IR(kOptForLockingClause, OP0(), tmp0);
  CASEEND
  CASESTART(1)
  res = new IR(kOptForLockingClause, OP0());
  CASEEND
  SWITCHEND
  TRANSLATEEND
}

void SelectNoParens::deep_delete() {
  SAFEDELETE(simple_select_);
  SAFEDELETE(select_clause_);
  SAFEDELETE(order_clause_);
  SAFEDELETE(opt_order_clause_);
  SAFEDELETE(for_locking_clause_);
  SAFEDELETE(opt_select_limit_);
  SAFEDELETE(select_limit_);
  SAFEDELETE(opt_for_locking_clause_);
  SAFEDELETE(with_clause_);
  delete this; 
}

void SelectNoParens::generate(){
}

IR *SelectNoParens::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART
  SWITCHSTART
  CASESTART(0)
  auto tmp0 = SAFETRANSLATE(simple_select_);
  res = new IR(kSelectNoParens, OP0(), tmp0);
  CASEEND
  CASESTART(1)
  auto tmp0 = SAFETRANSLATE(select_clause_);
  auto tmp1 = SAFETRANSLATE(order_clause_);
  res = new IR(kSelectNoParens, OP0(), tmp0, tmp1);
  CASEEND
  CASESTART(2)
  auto tmp0 = SAFETRANSLATE(select_clause_);
  auto tmp1 = SAFETRANSLATE(opt_order_clause_);
  auto tmp2 = SAFETRANSLATE(for_locking_clause_);
  auto tmp3 = SAFETRANSLATE(opt_select_limit_);
  res = new IR(kUnknown, OP0(), tmp0, tmp1);
  PUSH(res);
  res = new IR(kUnknown, OP0(), res, tmp2);
  PUSH(res);
  res = new IR(kSelectNoParens, OP0(), res, tmp3);
  CASEEND
  CASESTART(3)
  auto tmp0 = SAFETRANSLATE(select_clause_);
  auto tmp1 = SAFETRANSLATE(opt_order_clause_);
  auto tmp2 = SAFETRANSLATE(select_limit_);
  auto tmp3 = SAFETRANSLATE(opt_for_locking_clause_);
  res = new IR(kUnknown, OP0(), tmp0, tmp1);
  PUSH(res);
  res = new IR(kUnknown, OP0(), res, tmp2);
  PUSH(res);
  res = new IR(kSelectNoParens, OP0(), res, tmp3);
  CASEEND
  CASESTART(4)
  auto tmp0 = SAFETRANSLATE(with_clause_);
  auto tmp1 = SAFETRANSLATE(select_clause_);
  res = new IR(kSelectNoParens, OP0(), tmp0, tmp1);
  CASEEND
  CASESTART(5)
  auto tmp0 = SAFETRANSLATE(with_clause_);
  auto tmp1 = SAFETRANSLATE(select_clause_);
  auto tmp2 = SAFETRANSLATE(order_clause_);
  res = new IR(kUnknown, OP0(), tmp0, tmp1);
  PUSH(res);
  res = new IR(kSelectNoParens, OP0(), res, tmp2);
  CASEEND
  CASESTART(6)
  auto tmp0 = SAFETRANSLATE(with_clause_);
  auto tmp1 = SAFETRANSLATE(select_clause_);
  auto tmp2 = SAFETRANSLATE(opt_order_clause_);
  auto tmp3 = SAFETRANSLATE(for_locking_clause_);
  auto tmp4 = SAFETRANSLATE(opt_select_limit_);
  res = new IR(kUnknown, OP0(), tmp0, tmp1);
  PUSH(res);
  res = new IR(kUnknown, OP0(), res ,tmp2);
  PUSH(res);
  res = new IR(kUnknown, OP0(), res, tmp3);
  PUSH(res);
  res = new IR(kSelectNoParens, OP0(), res, tmp4);
  CASEEND
  CASESTART(7)
  auto tmp0 = SAFETRANSLATE(with_clause_);
  auto tmp1 = SAFETRANSLATE(select_clause_);
  auto tmp2 = SAFETRANSLATE(opt_order_clause_);
  auto tmp3 = SAFETRANSLATE(select_limit_);
  auto tmp4 = SAFETRANSLATE(opt_for_locking_clause_);
  res = new IR(kUnknown, OP0(), tmp0, tmp1);
  PUSH(res);
  res = new IR(kUnknown, OP0(), res ,tmp2);
  PUSH(res);
  res = new IR(kUnknown, OP0(), res, tmp3);
  PUSH(res);
  res = new IR(kSelectNoParens, OP0(), res, tmp4);
  CASEEND
  SWITCHEND
  TRANSLATEEND
}

void PreparableStmt::deep_delete() {
  SAFEDELETE(select_stmt_);
  SAFEDELETE(insert_stmt_);
  SAFEDELETE(update_stmt_);
  delete this; 
}

void PreparableStmt::generate(){
}

IR *PreparableStmt::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART
  SWITCHSTART
  CASESTART(0)
  auto tmp0 = SAFETRANSLATE(select_stmt_);
  res = new IR(kPreparableStmt, OP0(), tmp0);
  CASEEND
  CASESTART(1)
  auto tmp0 = SAFETRANSLATE(insert_stmt_);
  res = new IR(kPreparableStmt, OP0(), tmp0);
  CASEEND
  CASESTART(2)
  auto tmp0 = SAFETRANSLATE(update_stmt_);
  res = new IR(kPreparableStmt, OP0(), tmp0);
  CASEEND
  // CASESTART(3)
  // auto tmp0 = SAFETRANSLATE(remove_stmt_);
  // res = new IR(kPreparableStmt, OP0(), tmp0);
  // CASEEND
  SWITCHEND
  TRANSLATEEND
}

IR *CreateTableStmt::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(opt_temp_);
  auto tmp2 = SAFETRANSLATE(opt_if_not_exist_);
  res = new IR(kUnknown, OP3("CREATE", "TABLE", ""), tmp1, tmp2);
  PUSH(res);
  auto tmp3 = SAFETRANSLATE(table_name_);
  res = new IR(kUnknown, OP3("", "", ""), res, tmp2);
  PUSH(res);
  auto tmp4 = SAFETRANSLATE(opt_table_element_list_);
  res = new IR(kUnknown, OP3("", "(", ")"), res, tmp4);
  PUSH(res);
  auto tmp5 = SAFETRANSLATE(opt_inherit_);
  res = new IR(kUnknown, OP3("", "", ""), res, tmp5);
  PUSH(res);
  auto tmp6 = SAFETRANSLATE(opt_partition_spec_);
  res = new IR(kUnknown, OP3("", "", ""), res, tmp6);
  PUSH(res);
  auto tmp7 = SAFETRANSLATE(table_access_method_clause_);
  res = new IR(kUnknown, OP3("", "", ""), res, tmp7);
  PUSH(res);
  auto tmp8 = SAFETRANSLATE(opt_with_replotions_);
  res = new IR(kUnknown, OP3("", "", ""), res, tmp8);
  PUSH(res);
  auto tmp9 = SAFETRANSLATE(on_commit_option_);
  res = new IR(kUnknown, OP3("", "", ""), res, tmp9);
  PUSH(res);
  auto tmp10 = SAFETRANSLATE(opt_tablespace_);
  res = new IR(kCreateTableStmt, OP3("", "", ""), res, tmp10);

  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(opt_temp_);
  auto tmp2 = SAFETRANSLATE(opt_if_not_exist_);
  res = new IR(kUnknown, OP3("CREATE", "TABLE", ""), tmp1, tmp2);
  PUSH(res);
  auto tmp3 = SAFETRANSLATE(table_name_);
  res = new IR(kUnknown, OP3("", "", ""), res, tmp2);
  PUSH(res);
  auto tmp4 = SAFETRANSLATE(any_name_);
  res = new IR(kUnknown, OP3("", "OF", ""), res, tmp4);
  PUSH(res);
  auto tmp5 = SAFETRANSLATE(opt_typed_table_element_list_);
  res = new IR(kUnknown, OP3("", "", ""), res, tmp5);
  PUSH(res);
  auto tmp6 = SAFETRANSLATE(opt_partition_spec_);
  res = new IR(kUnknown, OP3("", "", ""), res, tmp6);
  PUSH(res);
  auto tmp7 = SAFETRANSLATE(table_access_method_clause_);
  res = new IR(kUnknown, OP3("", "", ""), res, tmp7);
  PUSH(res);
  auto tmp8 = SAFETRANSLATE(opt_with_replotions_);
  res = new IR(kUnknown, OP3("", "", ""), res, tmp8);
  PUSH(res);
  auto tmp9 = SAFETRANSLATE(on_commit_option_);
  res = new IR(kUnknown, OP3("", "", ""), res, tmp9);
  PUSH(res);
  auto tmp10 = SAFETRANSLATE(opt_tablespace_);
  res = new IR(kCreateTableStmt, OP3("", "", ""), res, tmp10);
  CASEEND
    CASESTART(2)
      auto tmp1 = SAFETRANSLATE(opt_temp_);
      auto tmp2 = SAFETRANSLATE(opt_if_not_exist_);
      res = new IR(kUnknown, OP3("CREATE", "TABLE", ""), tmp1, tmp2);
      PUSH(res);
      auto tmp3 = SAFETRANSLATE(table_name_0_);
      res = new IR(kUnknown, OP3("", "", ""), res, tmp2);
      PUSH(res);
      auto tmp4 = SAFETRANSLATE(table_name_1_);
      res = new IR(kUnknown, OP3("", "PARTITION OF", ""), res, tmp4);
      PUSH(res);
      auto tmp5 = SAFETRANSLATE(opt_typed_table_element_list_);
      res = new IR(kUnknown, OP3("", "", ""), res, tmp5);
      PUSH(res);
      auto tmp6 = SAFETRANSLATE(partition_bound_spec_);
      res = new IR(kUnknown, OP3("", "", ""), res, tmp6);
      PUSH(res);
      auto tmp7 = SAFETRANSLATE(opt_partition_spec_);
      res = new IR(kUnknown, OP3("", "", ""), res, tmp7);
      PUSH(res);
      auto tmp8 = SAFETRANSLATE(table_access_method_clause_);
      res = new IR(kUnknown, OP3("", "", ""), res, tmp8);
      PUSH(res);
      auto tmp9 = SAFETRANSLATE(opt_with_replotions_);
      res = new IR(kUnknown, OP3("", "", ""), res, tmp8);
      PUSH(res);
      auto tmp10 = SAFETRANSLATE(on_commit_option_);
      res = new IR(kUnknown, OP3("", "", ""), res, tmp9);
      PUSH(res);
      auto tmp11 = SAFETRANSLATE(opt_tablespace_);
      res = new IR(kCreateTableStmt, OP3("", "", ""), res, tmp10);
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

OptTemp *opt_temp_;
OptIfNotExist *opt_if_not_exist_;
TableName *table_name_;
OptTableElementList * opt_table_element_list_;
OptInherit * opt_inherit_;
OptPartitionSpec * opt_partition_spec_;
TableAccessMethodClause * table_access_method_clause_;
OptWithReplotions * opt_with_replotions_;
OnCommitOption * on_commit_option_;
OptTablespace * opt_tablespace_;
AnyName * any_name_;
OptTypedTableElementList * opt_typed_table_element_list_;
TableName * table_name_0_;
TableName * table_name_1_;
PartitionBoundSpec * partition_bound_spec_;

void CreateTableStmt::deep_delete() {
  SAFEDELETE(opt_temp_);
  SAFEDELETE(opt_if_not_exist_);
  SAFEDELETE(table_name_);
  SAFEDELETE(opt_table_element_list_);
  SAFEDELETE(opt_inherit_);
  SAFEDELETE(opt_partition_spec_);
  SAFEDELETE(table_access_method_clause_);
  SAFEDELETE(opt_with_replotions_);
  SAFEDELETE(on_commit_option_);
  SAFEDELETE(opt_tablespace_);
  SAFEDELETE(any_name_);
  SAFEDELETE(opt_typed_table_element_list_);
  SAFEDELETE(table_name_0_);
  SAFEDELETE(table_name_1_);
  SAFEDELETE(partition_bound_spec_);
  delete this;
};

void CreateTableStmt::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *CreateIndexStmt::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(opt_unique_);
  auto tmp2 = SAFETRANSLATE(opt_concurrently_);
  auto tmp3 = SAFETRANSLATE(opt_if_not_exist_index_);
  auto tmp4 = SAFETRANSLATE(opt_only_);
  auto tmp5 = SAFETRANSLATE(table_name_);
  auto tmp6 = SAFETRANSLATE(opt_using_method_);
  auto tmp7 = SAFETRANSLATE(indexed_create_index_rest_stmt_list_);
  auto tmp8 = SAFETRANSLATE(opt_include_column_name_list_);
  auto tmp9 = SAFETRANSLATE(opt_with_index_storage_parameter_list_);
  auto tmp10 = SAFETRANSLATE(opt_tablespace_);
  auto tmp11 = SAFETRANSLATE(opt_where_predicate_);

  res = new IR(kCreateIndexStmt, OP3("CREATE", "INDEX", ""), tmp1, tmp2);
  PUSH(res);
  res = new IR(kCreateIndexStmt, OP3("", "", "ON"), res, tmp3);
  PUSH(res);
  res = new IR(kCreateIndexStmt, OP3("", "", ""), res, tmp4);
  PUSH(res);
  res = new IR(kCreateIndexStmt, OP3("", "", ""), res, tmp5);
  PUSH(res);
  res = new IR(kCreateIndexStmt, OP3("", "", "("), res, tmp6);
  PUSH(res);
  res = new IR(kCreateIndexStmt, OP3("", "", ")"), res, tmp7);
  PUSH(res);
  res = new IR(kCreateIndexStmt, OP3("", "", ""), res, tmp8);
  PUSH(res);
  res = new IR(kCreateIndexStmt, OP3("", "", ""), res, tmp9);
  PUSH(res);
  res = new IR(kCreateIndexStmt, OP3("", "", ""), res, tmp10);
  PUSH(res);
  res = new IR(kCreateIndexStmt, OP3("", "", ""), res, tmp11);

  TRANSLATEEND
}

void CreateIndexStmt::deep_delete() {
  SAFEDELETE(opt_unique_);
  SAFEDELETE(opt_concurrently_);
  SAFEDELETE(opt_if_not_exist_index_);
  SAFEDELETE(opt_only_);
  SAFEDELETE(table_name_);
  SAFEDELETE(opt_using_method_);
  SAFEDELETE(indexed_create_index_rest_stmt_list_);
  SAFEDELETE(opt_include_column_name_list_);
  SAFEDELETE(opt_with_index_storage_parameter_list_);
  SAFEDELETE(opt_tablespace_);
  SAFEDELETE(opt_where_predicate_);
  delete this;
};

void CreateIndexStmt::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *CreateViewStmt::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART

  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(opt_or_replace_);
  auto tmp2 = SAFETRANSLATE(opt_temp_token_);
  auto tmp3 = SAFETRANSLATE(opt_recursive_);
  auto tmp4 = SAFETRANSLATE(view_name_);
  auto tmp5 = SAFETRANSLATE(opt_column_name_list_p_);
  auto tmp6 = SAFETRANSLATE(opt_with_view_option_list_);
  auto tmp7 = SAFETRANSLATE(select_stmt_);
  auto tmp8 = SAFETRANSLATE(opt_check_option_);
  res = new IR(kUnknown, OP3("CREATE", "", ""), tmp1, tmp2);
  PUSH(res);
  res = new IR(kUnknown, OP3("", "", "VIEW"), res, tmp3);
  PUSH(res);
  res = new IR(kUnknown, OP3("", "", ""), res, tmp4);
  PUSH(res);
  res = new IR(kUnknown, OP3("", "", ""), res, tmp5);
  PUSH(res);
  res = new IR(kUnknown, OP3("", "", "AS"), res, tmp6);
  PUSH(res);
  res = new IR(kUnknown, OP3("", "", ""), res, tmp7);
  PUSH(res);
  res = new IR(kCreateViewStmt, OP3("", "", ""), res, tmp8);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(opt_or_replace_);
  auto tmp2 = SAFETRANSLATE(opt_temp_token_);
  auto tmp3 = SAFETRANSLATE(opt_recursive_);
  auto tmp4 = SAFETRANSLATE(view_name_);
  auto tmp5 = SAFETRANSLATE(opt_column_name_list_p_);
  auto tmp6 = SAFETRANSLATE(opt_with_view_option_list_);
  auto tmp7 = SAFETRANSLATE(values_stmt_);
  auto tmp8 = SAFETRANSLATE(opt_check_option_);
  res = new IR(kUnknown, OP3("CREATE", "", ""), tmp1, tmp2);
  PUSH(res);
  res = new IR(kUnknown, OP3("", "", "VIEW"), res, tmp3);
  PUSH(res);
  res = new IR(kUnknown, OP3("", "", ""), res, tmp4);
  PUSH(res);
  res = new IR(kUnknown, OP3("", "", ""), res, tmp5);
  PUSH(res);
  res = new IR(kUnknown, OP3("", "", "AS"), res, tmp6);
  PUSH(res);
  res = new IR(kUnknown, OP3("", "", ""), res, tmp7);
  PUSH(res);
  res = new IR(kCreateViewStmt, OP3("", "", ""), res, tmp8);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void CreateViewStmt::deep_delete() {
  SAFEDELETE(opt_or_replace_);
  SAFEDELETE(opt_temp_token_);
  SAFEDELETE(opt_recursive_);
  SAFEDELETE(view_name_);
  SAFEDELETE(opt_column_name_list_p_);
  SAFEDELETE(opt_with_view_option_list_);
  SAFEDELETE(select_stmt_);
  SAFEDELETE(values_stmt_);
  SAFEDELETE(opt_check_option_);
  delete this;
};

void CreateViewStmt::generate() {
  GENERATESTART(4)
  GENERATEEND
}

IR *DropIndexStmt::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(opt_concurrently_);
  auto tmp2 = SAFETRANSLATE(opt_if_exist_);
  auto tmp3 = SAFETRANSLATE(index_name_);
  auto tmp4 = SAFETRANSLATE(opt_index_name_list_);
  auto tmp5 = SAFETRANSLATE(opt_cascade_restrict_);
  res = new IR(kDropIndexStmt, OP3("DROP INDEX", "", ""), tmp1, tmp2);
  PUSH(res);
  res = new IR(kDropIndexStmt, OP3("", "", ""), res, tmp3);
  PUSH(res);
  res = new IR(kDropIndexStmt, OP3("", "", ""), res, tmp4);
  PUSH(res);
  res = new IR(kDropIndexStmt, OP3("", "", ""), res, tmp5);

  TRANSLATEEND
}

void DropIndexStmt::deep_delete() {
  SAFEDELETE(opt_concurrently_);
  SAFEDELETE(opt_if_exist_);
  SAFEDELETE(index_name_);
  SAFEDELETE(opt_index_name_list_);
  SAFEDELETE(opt_cascade_restrict_);
  delete this;
};

void DropIndexStmt::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *DropTableStmt::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(opt_if_exist_);
  auto tmp2 = SAFETRANSLATE(table_name_list_);
  auto tmp3 = SAFETRANSLATE(opt_cascade_restrict_);

  res = new IR(kDropTableStmt, OP3("DROP TABLE", "", ""), tmp1, tmp2);
  PUSH(res);
  res = new IR(kDropTableStmt, OP3("", "", ""), res, tmp3);

  TRANSLATEEND
}

void DropTableStmt::deep_delete() {
  SAFEDELETE(table_name_list_);
  SAFEDELETE(opt_if_exist_);
  SAFEDELETE(opt_cascade_restrict_);
  delete this;
};

void DropTableStmt::generate() {
  GENERATESTART(1)

  opt_if_exist_ = new OptIfExist();
  opt_if_exist_->generate();
  table_name_list_ = new TableNameList();
  table_name_list_->generate();
  opt_cascade_restrict_ = new OptCascadeRestrict();
  opt_cascade_restrict_->generate();

  GENERATEEND
}

IR *DropViewStmt::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(opt_if_exist_);
  auto tmp2 = SAFETRANSLATE(view_name_list_);
  auto tmp3 = SAFETRANSLATE(opt_cascade_restrict_);

  res = new IR(kDropViewStmt, OP3("DROP VIEW", "", ""), tmp1, tmp2);
  PUSH(res);
  res = new IR(kDropViewStmt, OP3("", "", ""), res, tmp3);

  TRANSLATEEND
}

void DropViewStmt::deep_delete() {
  SAFEDELETE(view_name_list_);
  SAFEDELETE(opt_if_exist_);
  SAFEDELETE(opt_cascade_restrict_);
  delete this;
};

void DropViewStmt::generate() {
  GENERATESTART(1)

  opt_if_exist_ = new OptIfExist();
  opt_if_exist_->generate();
  view_name_list_ = new ViewNameList();
  view_name_list_->generate();
  opt_cascade_restrict_ = new OptCascadeRestrict();
  opt_cascade_restrict_->generate();

  GENERATEEND
}

IR *InsertStmt::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(opt_with_clause_);
  auto tmp2 = SAFETRANSLATE(insert_target_);
  auto tmp3 = SAFETRANSLATE(insert_rest_);
  auto tmp4 = SAFETRANSLATE(opt_on_conflict_);
  auto tmp5 = SAFETRANSLATE(returning_clause_);
  res = new IR(kUnknown, OP3("", "INSERT INTO", ""), tmp1, tmp2);
  PUSH(res);
  res = new IR(kUnknown, OP3("", "", ""), res, tmp3);
  PUSH(res);
  res = new IR(kUnknown, OP3("", "", ""), res, tmp4);
  PUSH(res);
  res = new IR(kInsertStmt, OP3("", "", ""), res, tmp5);

  TRANSLATEEND
}

void InsertStmt::deep_delete() {
  SAFEDELETE(insert_rest_);
  SAFEDELETE(insert_target_);
  SAFEDELETE(opt_on_conflict_);
  SAFEDELETE(opt_with_clause_);
  SAFEDELETE(returning_clause_);
  delete this;
};

void InsertStmt::generate() {
  GENERATESTART(1)

  opt_with_clause_ = new OptWithClause();
  opt_with_clause_->generate();
  insert_target_ = new InsertTarget();
  insert_target_->generate();
  insert_rest_ = new InsertRest();
  insert_rest_->generate();
  opt_on_conflict_ = new OptOnConflict();
  opt_on_conflict_->generate();
  returning_clause_ = new ReturningClause();
  returning_clause_->generate();

  GENERATEEND
}

IR *InsertTarget::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(table_name_);
  auto tmp2 = SAFETRANSLATE(opt_alias_);
  res = new IR(kInsertTarget, OP3("", "", ""), tmp1, tmp2);

  TRANSLATEEND
}

void InsertTarget::deep_delete() {
  SAFEDELETE(table_name_);
  SAFEDELETE(opt_alias_);
  delete this;
};

void InsertTarget::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *InsertRest::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(insert_query_);
  res = new IR(kInsertRest, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(override_kind_);
  auto tmp2 = SAFETRANSLATE(insert_query_);
  res = new IR(kInsertRest, OP3("OVERRIDING", "VALUE", ""), tmp1, tmp2);
  CASEEND
  CASESTART(2)
  auto tmp1 = SAFETRANSLATE(column_name_list_);
  auto tmp2 = SAFETRANSLATE(insert_query_);
  res = new IR(kInsertRest, OP3("(", ")", ""), tmp1, tmp2);
  CASEEND
  CASESTART(3)
  auto tmp1 = SAFETRANSLATE(column_name_list_);
  auto tmp2 = SAFETRANSLATE(override_kind_);
  auto tmp3 = SAFETRANSLATE(insert_query_);
  res = new IR(kInsertRest, OP3("(", ") OVERRIDING", "VALUE"), tmp1, tmp2);
  PUSH(res);
  res = new IR(kInsertRest, OP3("", "", ""), res, tmp3);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void InsertRest::deep_delete() {
  SAFEDELETE(insert_query_);
  SAFEDELETE(override_kind_);
  SAFEDELETE(column_name_list_);
  delete this;
};

void InsertRest::generate() {
  GENERATESTART(1)
  GENERATEEND
};


IR *InsertQuery::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
      auto tmp1 = SAFETRANSLATE(select_stmt_);
      res = new IR(kInsertQuery, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(1)
      auto tmp1 = SAFETRANSLATE(values_default_clause_);
      res = new IR(kInsertQuery, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(2)
      res = new IR(kInsertQuery, OP1("DEFAULT VALUES"));
    CASEEND
  SWITCHEND

  TRANSLATEEND
};

void InsertQuery::deep_delete() {
  SAFEDELETE(select_stmt_);
  SAFEDELETE(values_default_clause_);
  delete this;
};

void InsertQuery::generate() {
  GENERATESTART(1)
  GENERATEEND
};

IR *ValuesDefaultClause::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(expr_default_list_with_parens_);
  res = new IR(kValuesDefaultClause, OP3("VALUES", "", ""), tmp1);

  TRANSLATEEND
}

void ValuesDefaultClause::deep_delete() {
  SAFEDELETE(expr_default_list_with_parens_);
  delete this;
};

void ValuesDefaultClause::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *ExprDefaultListWithParens::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(expr_default_list_);
    res = new IR(kExprDefaultListWithParens, OP3("(", ")", ""), tmp1);
    CASEEND
    CASESTART(1)
    auto tmp1 = SAFETRANSLATE(expr_default_list_);
    auto tmp2 = SAFETRANSLATE(expr_default_list_with_parens_);
    res = new IR(kExprDefaultListWithParens, OP3("(", ") ,", ""), tmp1, tmp2);
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void ExprDefaultListWithParens::deep_delete() {
  SAFEDELETE(expr_default_list_);
  SAFEDELETE(expr_default_list_with_parens_);
  delete this;
};

void ExprDefaultListWithParens::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *ExprDefaultList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(expr_);
  auto tmp2 = SAFETRANSLATE(expr_default_list_);
  res = new IR(kExprDefaultList, OP3("", ",", ""), tmp1, tmp2);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(expr_default_list_);
  res = new IR(kExprDefaultList, OP3("DEFAULT ,", "", ""), tmp1);
  CASEEND
  CASESTART(2)
  auto tmp1 = SAFETRANSLATE(expr_);
  res = new IR(kExprDefaultList, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(3)
  res = new IR(kExprDefaultList, OP1("DEFAULT"));
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void ExprDefaultList::deep_delete() {
  SAFEDELETE(expr_);
  SAFEDELETE(expr_default_list_);
  delete this;
};

void ExprDefaultList::generate() {
  GENERATESTART(1)
  GENERATEEND
}



IR *OverrideKind::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  res = new IR(kOverrideKind, OP1("USER"));
  CASEEND
  CASESTART(1)
  res = new IR(kOverrideKind, OP1("SYSTEM"));
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OverrideKind::deep_delete() {
  delete this;
};

void OverrideKind::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *ReturningClause::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(target_list_);
  res = new IR(kReturningClause, OP3("RETURNING", "", ""), tmp1);
  CASEEND
  CASESTART(1)
  res = new IR(kReturningClause, OP1("RETURNING *"));
  CASEEND
  CASESTART(2)
  res = new IR(kReturningClause, string(""));
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void ReturningClause::deep_delete() {
  SAFEDELETE(target_list_);
  delete this;
};

void ReturningClause::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *TargetList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(target_el_);
  res = new IR(kTargetList, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(target_el_);
  auto tmp2 = SAFETRANSLATE(target_list_);
  res = new IR(kTargetList, OP3("", ",", ""), tmp1, tmp2);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void TargetList::deep_delete() {
  SAFEDELETE(target_el_);
  SAFEDELETE(target_list_);
  delete this;
};

void TargetList::generate() {
  GENERATESTART(1)
  GENERATEEND
};

IR *TargetEl::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(expr_);
  auto tmp2 = SAFETRANSLATE(identifier_);
  res = new IR(kTargetEl, OP3("", "AS", ""), tmp1, tmp2);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(expr_);
  auto tmp2 = SAFETRANSLATE(identifier_);
  res = new IR(kTargetEl, OP3("", "", ""), tmp1, tmp2);
  CASEEND
  CASESTART(2)
  auto tmp1 = SAFETRANSLATE(expr_);
  res = new IR(kTargetEl, OP3("", "", ""), tmp1);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void TargetEl::deep_delete() {
  SAFEDELETE(expr_);
  SAFEDELETE(identifier_);
  delete this;
};

void TargetEl::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *SuperValuesList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(values_list_);
  res = new IR(kSuperValuesList, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(values_list_);
  auto tmp2 = SAFETRANSLATE(super_values_list_);
  res = new IR(kSuperValuesList, OP3("", ",", ""), tmp1, tmp2);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void SuperValuesList::deep_delete() {
  SAFEDELETE(values_list_);
  SAFEDELETE(super_values_list_);
  delete this;
};

void SuperValuesList::generate() {
  GENERATESTART(200)

  SWITCHSTART
  CASESTART(0)
  values_list_ = new ValuesList();
  values_list_->generate();
  CASEEND
  CASESTART(1)
  values_list_ = new ValuesList();
  values_list_->generate();
  super_values_list_ = new SuperValuesList();
  super_values_list_->generate();
  CASEEND

default: {
  int tmp_case_idx = rand() % 1;
  switch (tmp_case_idx) {
    CASESTART(0)
    values_list_ = new ValuesList();
    values_list_->generate();
    case_idx_ = 0;
    CASEEND
  }
}
}

GENERATEEND
}

IR *ValuesList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(expr_list_);
  res = new IR(kValuesList, OP3("(", ")", ""), tmp1);

  TRANSLATEEND
}

void ValuesList::deep_delete() {
  SAFEDELETE(expr_list_);
  delete this;
};

void ValuesList::generate() {
  GENERATESTART(1)

  expr_list_ = new ExprList();
  expr_list_->generate();

  GENERATEEND
}

IR *OptOnConflict::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(opt_conflict_expr_);
  res = new IR(kOptOnConflict, OP3("ON CONFLICT", "DO NOTHING", ""), tmp1);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(opt_conflict_expr_);
  auto tmp2 = SAFETRANSLATE(set_clause_list_);
  auto tmp3 = SAFETRANSLATE(opt_where_clause_);
  auto tmp4 = new IR(kUnknown, OP3("ON CONFLICT", "DO UPDATE SET", ""), tmp1, tmp2);
  PUSH(tmp4);
  res = new IR(kOptOnConflict, OP3("", "", ""), tmp4, tmp3);
  CASEEND
  CASESTART(2)
  res = new IR(kOptOnConflict, string(""));
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptOnConflict::deep_delete() {
  SAFEDELETE(opt_conflict_expr_);
  SAFEDELETE(set_clause_list_);
  SAFEDELETE(opt_where_clause_);
  delete this;
};

void OptOnConflict::generate() {
  GENERATESTART(3)

  SWITCHSTART
  CASESTART(0)
  opt_conflict_expr_ = new OptConflictExpr();
  opt_conflict_expr_->generate();
  CASEEND
  CASESTART(1)
  opt_conflict_expr_ = new OptConflictExpr();
  opt_conflict_expr_->generate();
  set_clause_list_ = new SetClauseList();
  set_clause_list_->generate();
  opt_where_clause_ = new OptWhereClause();
  opt_where_clause_->generate();
  CASEEND
  CASESTART(2)

  CASEEND
  SWITCHEND

  GENERATEEND
}

IR *OptConflictExpr::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(indexed_column_list_);
  auto tmp2 = SAFETRANSLATE(opt_where_clause_);
  res = new IR(kOptConflictExpr, OP3("(", ")", ""), tmp1, tmp2);
  CASEEND
  CASESTART(1)
  res = new IR(kOptConflictExpr, string(""));
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptConflictExpr::deep_delete() {
  SAFEDELETE(indexed_column_list_);
  SAFEDELETE(opt_where_clause_);
  delete this;
};

void OptConflictExpr::generate() {
  GENERATESTART(2)

  SWITCHSTART
  CASESTART(0)
  indexed_column_list_ = new IndexedColumnList();
  indexed_column_list_->generate();
  opt_where_clause_ = new OptWhereClause();
  opt_where_clause_->generate();
  CASEEND
  CASESTART(1)

  CASEEND
  SWITCHEND

  GENERATEEND
}

IR *IndexedColumnList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(indexed_column_);
  res = new IR(kIndexedColumnList, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(indexed_column_);
  auto tmp2 = SAFETRANSLATE(indexed_column_list_);
  res = new IR(kIndexedColumnList, OP3("", ",", ""), tmp1, tmp2);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void IndexedColumnList::deep_delete() {
  SAFEDELETE(indexed_column_);
  SAFEDELETE(indexed_column_list_);
  delete this;
};

void IndexedColumnList::generate() {
  GENERATESTART(200)

  SWITCHSTART
  CASESTART(0)
  indexed_column_ = new IndexedColumn();
  indexed_column_->generate();
  CASEEND
  CASESTART(1)
  indexed_column_ = new IndexedColumn();
  indexed_column_->generate();
  indexed_column_list_ = new IndexedColumnList();
  indexed_column_list_->generate();
  CASEEND

default: {
  int tmp_case_idx = rand() % 1;
  switch (tmp_case_idx) {
    CASESTART(0)
    indexed_column_ = new IndexedColumn();
    indexed_column_->generate();
    case_idx_ = 0;
    CASEEND
  }
}
}

GENERATEEND
}

IR *IndexedColumn::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(expr_);
  auto tmp2 = SAFETRANSLATE(opt_order_behavior_);
  res = new IR(kIndexedColumn, OP3("", "", ""), tmp1, tmp2);

  TRANSLATEEND
}

void IndexedColumn::deep_delete() {
  SAFEDELETE(expr_);
  SAFEDELETE(opt_order_behavior_);
  delete this;
};

void IndexedColumn::generate() {
  GENERATESTART(1)

  expr_ = new Expr();
  expr_->generate();
  opt_order_behavior_ = new OptOrderBehavior();
  opt_order_behavior_->generate();

  GENERATEEND
}

IR *UpdateStmt::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(opt_with_clause_);
  auto tmp2 = SAFETRANSLATE(table_name_);
  auto tmp3 = SAFETRANSLATE(set_clause_list_);
  auto tmp4 = SAFETRANSLATE(opt_where_clause_);
  auto tmp5 = new IR(kUnknown, OP3("", "UPDATE", "SET"), tmp1, tmp2);
  PUSH(tmp5);
  auto tmp6 = new IR(kUnknown, OP3("", "", ""), tmp5, tmp3);
  PUSH(tmp6);
  res = new IR(kUpdateStmt, OP3("", "", ""), tmp6, tmp4);

  TRANSLATEEND
}

void UpdateStmt::deep_delete() {
  SAFEDELETE(table_name_);
  SAFEDELETE(set_clause_list_);
  SAFEDELETE(opt_with_clause_);
  SAFEDELETE(opt_where_clause_);
  delete this;
};

void UpdateStmt::generate() {
  GENERATESTART(1)

  opt_with_clause_ = new OptWithClause();
  opt_with_clause_->generate();
  table_name_ = new TableName();
  table_name_->generate();
  set_clause_list_ = new SetClauseList();
  set_clause_list_->generate();
  opt_where_clause_ = new OptWhereClause();
  opt_where_clause_->generate();

  GENERATEEND
}

IR *ReindexStmt::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(opt_reindex_option_list_);
  auto tmp2 = SAFETRANSLATE(opt_concurrently_);
  auto tmp3 = SAFETRANSLATE(index_name_);
  res = new IR(kReindexStmt, OP3("REINDEX", "INDEX", ""), tmp1, tmp2);
  PUSH(res);
  res = new IR(kReindexStmt, OP3("", "", ""), tmp3);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(opt_reindex_option_list_);
  auto tmp2 = SAFETRANSLATE(opt_concurrently_);
  auto tmp3 = SAFETRANSLATE(table_name_);
  res = new IR(kReindexStmt, OP3("REINDEX", "TABLE", ""), tmp1, tmp2);
  PUSH(res);
  res = new IR(kReindexStmt, OP3("", "", ""), tmp3);
  CASEEND
  CASESTART(2)
  auto tmp1 = SAFETRANSLATE(opt_reindex_option_list_);
  auto tmp2 = SAFETRANSLATE(opt_concurrently_);
  auto tmp3 = SAFETRANSLATE(schema_name_);
  res = new IR(kReindexStmt, OP3("REINDEX", "SCHEMA", ""), tmp1, tmp2);
  PUSH(res);
  res = new IR(kReindexStmt, OP3("", "", ""), tmp3);
  CASEEND
  CASESTART(3)
  auto tmp1 = SAFETRANSLATE(opt_reindex_option_list_);
  auto tmp2 = SAFETRANSLATE(opt_concurrently_);
  auto tmp3 = SAFETRANSLATE(database_name_);
  res = new IR(kReindexStmt, OP3("REINDEX", "DATABASE", ""), tmp1, tmp2);
  PUSH(res);
  res = new IR(kReindexStmt, OP3("", "", ""), tmp3);
  CASEEND
  CASESTART(4)
  auto tmp1 = SAFETRANSLATE(opt_reindex_option_list_);
  auto tmp2 = SAFETRANSLATE(opt_concurrently_);
  auto tmp3 = SAFETRANSLATE(system_name_);
  res = new IR(kReindexStmt, OP3("REINDEX", "SYSTEM", ""), tmp1, tmp2);
  PUSH(res);
  res = new IR(kReindexStmt, OP3("", "", ""), tmp3);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void ReindexStmt::deep_delete() {
  SAFEDELETE(opt_reindex_option_list_);
  SAFEDELETE(opt_concurrently_);
  SAFEDELETE(index_name_);
  SAFEDELETE(table_name_);
  SAFEDELETE(schema_name_);
  SAFEDELETE(database_name_);
  SAFEDELETE(system_name_);
  delete this;
};

void ReindexStmt::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *AlterAction::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(table_name_);
  res = new IR(kAlterAction, OP3("RENAME TO", "", ""), tmp1);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(opt_column_);
  auto tmp2 = SAFETRANSLATE(column_name_1_);
  auto tmp3 = SAFETRANSLATE(column_name_2_);
  auto tmp4 = new IR(kUnknown, OP3("RENAME", "", "TO"), tmp1, tmp2);
  PUSH(tmp4);
  res = new IR(kAlterAction, OP3("", "", ""), tmp4, tmp3);
  CASEEND
  CASESTART(2)
  auto tmp1 = SAFETRANSLATE(opt_column_);
  auto tmp2 = SAFETRANSLATE(column_def_);
  res = new IR(kAlterAction, OP3("ADD", "", ""), tmp1, tmp2);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void AlterAction::deep_delete() {
  SAFEDELETE(column_def_);
  SAFEDELETE(opt_column_);
  SAFEDELETE(table_name_);
  SAFEDELETE(column_name_1_);
  SAFEDELETE(column_name_2_);
  delete this;
};

void AlterAction::generate() {
  GENERATESTART(3)

  SWITCHSTART
  CASESTART(0)
  table_name_ = new TableName();
  table_name_->generate();
  CASEEND
  CASESTART(1)
  opt_column_ = new OptColumn();
  opt_column_->generate();
  column_name_1_ = new ColumnName();
  column_name_1_->generate();
  column_name_2_ = new ColumnName();
  column_name_2_->generate();
  CASEEND
  CASESTART(2)
  opt_column_ = new OptColumn();
  opt_column_->generate();
  column_def_ = new ColumnDef();
  column_def_->generate();
  CASEEND
  SWITCHEND

  GENERATEEND
}

IR *ColumnDefList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(column_def_);
  res = new IR(kColumnDefList, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(column_def_);
  auto tmp2 = SAFETRANSLATE(column_def_list_);
  res = new IR(kColumnDefList, OP3("", ",", ""), tmp1, tmp2);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void ColumnDefList::deep_delete() {
  SAFEDELETE(column_def_);
  SAFEDELETE(column_def_list_);
  delete this;
};

void ColumnDefList::generate() {
  GENERATESTART(200)

  SWITCHSTART
  CASESTART(0)
  column_def_ = new ColumnDef();
  column_def_->generate();
  CASEEND
  CASESTART(1)
  column_def_ = new ColumnDef();
  column_def_->generate();
  column_def_list_ = new ColumnDefList();
  column_def_list_->generate();
  CASEEND

default: {
  int tmp_case_idx = rand() % 1;
  switch (tmp_case_idx) {
    CASESTART(0)
    column_def_ = new ColumnDef();
    column_def_->generate();
    case_idx_ = 0;
    CASEEND
  }
}
}

GENERATEEND
}

IR *ColumnDef::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(identifier_);
  auto tmp2 = SAFETRANSLATE(type_name_);
  auto tmp3 = SAFETRANSLATE(opt_column_constraint_list_);
  auto tmp4 = new IR(kUnknown, OP3("", "", ""), tmp1, tmp2);
  PUSH(tmp4);
  res = new IR(kColumnDef, OP3("", "", ""), tmp4, tmp3);

  TRANSLATEEND
}

void ColumnDef::deep_delete() {
  SAFEDELETE(type_name_);
  SAFEDELETE(identifier_);
  SAFEDELETE(opt_column_constraint_list_);
  delete this;
};

void ColumnDef::generate() {
  GENERATESTART(1)

  identifier_ = new Identifier();
  identifier_->generate();
  type_name_ = new TypeName();
  type_name_->generate();
  opt_column_constraint_list_ = new OptColumnConstraintList();
  opt_column_constraint_list_->generate();

  GENERATEEND
}

IR *OptColumnConstraintList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(column_constraint_list_);
  res = new IR(kOptColumnConstraintList, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(1)
  res = new IR(kOptColumnConstraintList, string(""));
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptColumnConstraintList::deep_delete() {
  SAFEDELETE(column_constraint_list_);
  delete this;
};

void OptColumnConstraintList::generate() {
  GENERATESTART(2)

  SWITCHSTART
  CASESTART(0)
  column_constraint_list_ = new ColumnConstraintList();
  column_constraint_list_->generate();
  CASEEND
  CASESTART(1)

  CASEEND
  SWITCHEND

  GENERATEEND
}

IR *ColumnConstraintList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(column_constraint_);
  res = new IR(kColumnConstraintList, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(column_constraint_);
  auto tmp2 = SAFETRANSLATE(column_constraint_list_);
  res = new IR(kColumnConstraintList, OP3("", "", ""), tmp1, tmp2);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void ColumnConstraintList::deep_delete() {
  SAFEDELETE(column_constraint_list_);
  SAFEDELETE(column_constraint_);
  delete this;
};

void ColumnConstraintList::generate() {
  GENERATESTART(200)

  SWITCHSTART
  CASESTART(0)
  column_constraint_ = new ColumnConstraint();
  column_constraint_->generate();
  CASEEND
  CASESTART(1)
  column_constraint_ = new ColumnConstraint();
  column_constraint_->generate();
  column_constraint_list_ = new ColumnConstraintList();
  column_constraint_list_->generate();
  CASEEND

default: {
  int tmp_case_idx = rand() % 1;
  switch (tmp_case_idx) {
    CASESTART(0)
    column_constraint_ = new ColumnConstraint();
    column_constraint_->generate();
    case_idx_ = 0;
    CASEEND
  }
}
}

GENERATEEND
}

IR *ColumnConstraint::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(constraint_type_);
  res = new IR(kColumnConstraint, OP3("", "", ""), tmp1);

  TRANSLATEEND
}

void ColumnConstraint::deep_delete() {
  SAFEDELETE(constraint_type_);
  delete this;
};

void ColumnConstraint::generate() {
  GENERATESTART(1)

  constraint_type_ = new ConstraintType();
  constraint_type_->generate();

  GENERATEEND
}

IR *ConstraintType::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  res = new IR(kConstraintType, OP3("PRIMARY KEY", "", ""));
  CASEEND
  CASESTART(1)
  res = new IR(kConstraintType, OP3("NOT NULL", "", ""));
  CASEEND
  CASESTART(2)
  res = new IR(kConstraintType, OP3("UNIQUE", "", ""));
  CASEEND
  CASESTART(3)
  auto tmp1 = SAFETRANSLATE(expr_);
  res = new IR(kConstraintType, OP3("CHECK (", ")", ""), tmp1);
  CASEEND
  CASESTART(4)
  auto tmp1 = SAFETRANSLATE(foreign_clause_);
  res = new IR(kConstraintType, OP3("", "", ""), tmp1);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void ConstraintType::deep_delete() {
  SAFEDELETE(expr_);
  SAFEDELETE(foreign_clause_);
  delete this;
};

void ConstraintType::generate() {
  GENERATESTART(5)

  SWITCHSTART
  CASESTART(0)
  CASEEND
  CASESTART(1)
  CASEEND
  CASESTART(2)
  CASEEND
  CASESTART(3)
  expr_ = new Expr();
  expr_->generate();
  CASEEND
  CASESTART(4)
  foreign_clause_ = new ForeignClause();
  foreign_clause_->generate();
  CASEEND
  SWITCHEND

  GENERATEEND
}

IR *ForeignClause::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(table_name_);
  auto tmp2 = SAFETRANSLATE(opt_column_name_list_p_);
  auto tmp3 = SAFETRANSLATE(opt_foreign_key_actions_);
  auto tmp4 = SAFETRANSLATE(opt_constraint_attribute_spec_);
  auto tmp5 = new IR(kUnknown, OP3("REFERENCES", "", ""), tmp1, tmp2);
  PUSH(tmp5);
  auto tmp6 = new IR(kUnknown, OP3("", "", ""), tmp5, tmp3);
  PUSH(tmp6);
  res = new IR(kForeignClause, OP3("", "", ""), tmp6, tmp4);

  TRANSLATEEND
}

void ForeignClause::deep_delete() {
  SAFEDELETE(opt_constraint_attribute_spec_);
  SAFEDELETE(opt_column_name_list_p_);
  SAFEDELETE(table_name_);
  SAFEDELETE(opt_foreign_key_actions_);
  delete this;
};

void ForeignClause::generate() {
  GENERATESTART(1)

  table_name_ = new TableName();
  table_name_->generate();
  opt_column_name_list_p_ = new OptColumnNameListP();
  opt_column_name_list_p_->generate();
  opt_foreign_key_actions_ = new OptForeignKeyActions();
  opt_foreign_key_actions_->generate();
  opt_constraint_attribute_spec_ = new OptConstraintAttributeSpec();
  opt_constraint_attribute_spec_->generate();

  GENERATEEND
}

IR *OptForeignKeyActions::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(foreign_key_actions_);
  res = new IR(kOptForeignKeyActions, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(1)
  res = new IR(kOptForeignKeyActions, string(""));
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptForeignKeyActions::deep_delete() {
  SAFEDELETE(foreign_key_actions_);
  delete this;
};

void OptForeignKeyActions::generate() {
  GENERATESTART(2)

  SWITCHSTART
  CASESTART(0)
  foreign_key_actions_ = new ForeignKeyActions();
  foreign_key_actions_->generate();
  CASEEND
  CASESTART(1)

  CASEEND
  SWITCHEND

  GENERATEEND
}

IR *ForeignKeyActions::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  res = new IR(kForeignKeyActions, OP3("MATCH FULL", "", ""));
  CASEEND
  CASESTART(1)
  res = new IR(kForeignKeyActions, OP3("MATCH PARTIAL", "", ""));
  CASEEND
  CASESTART(2)
  res = new IR(kForeignKeyActions, OP3("MATCH SIMPLE", "", ""));
  CASEEND
  CASESTART(3)
  auto tmp1 = SAFETRANSLATE(key_actions_);
  res = new IR(kForeignKeyActions, OP3("ON UPDATE", "", ""), tmp1);
  CASEEND
  CASESTART(4)
  auto tmp1 = SAFETRANSLATE(key_actions_);
  res = new IR(kForeignKeyActions, OP3("ON DELETE", "", ""), tmp1);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void ForeignKeyActions::deep_delete() {
  SAFEDELETE(key_actions_);
  delete this;
};

void ForeignKeyActions::generate() {
  GENERATESTART(5)

  SWITCHSTART
  CASESTART(0)
  CASEEND
  CASESTART(1)
  CASEEND
  CASESTART(2)
  CASEEND
  CASESTART(3)
  key_actions_ = new KeyActions();
  key_actions_->generate();
  CASEEND
  CASESTART(4)
  key_actions_ = new KeyActions();
  key_actions_->generate();
  CASEEND
  SWITCHEND

  GENERATEEND
}

IR *KeyActions::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  res = new IR(kKeyActions, OP3("SET NULL", "", ""));
  CASEEND
  CASESTART(1)
  res = new IR(kKeyActions, OP3("SET DEFAULT", "", ""));
  CASEEND
  CASESTART(2)
  res = new IR(kKeyActions, OP3("CASCADE", "", ""));
  CASEEND
  CASESTART(3)
  res = new IR(kKeyActions, OP3("RESTRICT", "", ""));
  CASEEND
  CASESTART(4)
  res = new IR(kKeyActions, OP3("NO ACTION", "", ""));
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void KeyActions::deep_delete() { delete this; };

void KeyActions::generate(){GENERATESTART(5)

                                SWITCHSTART CASESTART(0) CASEEND CASESTART(1)
                                    CASEEND CASESTART(2) CASEEND CASESTART(3)
                                        CASEEND CASESTART(4) CASEEND SWITCHEND

                                            GENERATEEND}

IR *OptConstraintAttributeSpec::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(opt_initial_time_);
  res = new IR(kOptConstraintAttributeSpec, OP3("DEFFERRABLE", "", ""), tmp1);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(opt_initial_time_);
  res =
      new IR(kOptConstraintAttributeSpec, OP3("NOT DEFFERRABLE", "", ""), tmp1);
  CASEEND
  CASESTART(2)
  res = new IR(kOptConstraintAttributeSpec, string(""));
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptConstraintAttributeSpec::deep_delete() {
  SAFEDELETE(opt_initial_time_);
  delete this;
};

void OptConstraintAttributeSpec::generate() {
  GENERATESTART(3)

  SWITCHSTART
  CASESTART(0)
  opt_initial_time_ = new OptInitialTime();
  opt_initial_time_->generate();
  CASEEND
  CASESTART(1)
  opt_initial_time_ = new OptInitialTime();
  opt_initial_time_->generate();
  CASEEND
  CASESTART(2)

  CASEEND
  SWITCHEND

  GENERATEEND
}

IR *OptInitialTime::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  res = new IR(kOptInitialTime, OP3("INITIALLY DEFERRED", "", ""));
  CASEEND
  CASESTART(1)
  res = new IR(kOptInitialTime, OP3("INITIALLY IMMEDIATE", "", ""));
  CASEEND
  CASESTART(2)
  res = new IR(kOptInitialTime, string(""));
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptInitialTime::deep_delete() { delete this; };

void OptInitialTime::generate(){
    GENERATESTART(3)

        SWITCHSTART CASESTART(0) CASEEND CASESTART(1) CASEEND CASESTART(2)

            CASEEND SWITCHEND

                GENERATEEND}

IR *ConstraintName::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(name_);
  res = new IR(kConstraintName, OP3("CONSTRAINT", "", ""), tmp1);

  TRANSLATEEND
}

void ConstraintName::deep_delete() {
  SAFEDELETE(name_);
  delete this;
};

void ConstraintName::generate() {
  GENERATESTART(1)

  name_ = new Name();
  name_->generate();

  GENERATEEND
}

IR *OptTemp::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  res = new IR(kOptTemp, OP3("TEMPORARY", "", ""));
  CASEEND
  CASESTART(1)
  res = new IR(kOptTemp, OP3("TEMP", "", ""));
  CASEEND
  CASESTART(2)
  res = new IR(kOptTemp, OP3("LOCAL TEMPORARY", "", ""));
  CASEEND
  CASESTART(3)
  res = new IR(kOptTemp, OP3("LOCAL TEMP", "", ""));
  CASEEND
  CASESTART(4)
  res = new IR(kOptTemp, OP3("GLOBAL TEMPORARY", "", ""));
  CASEEND
  CASESTART(5)
  res = new IR(kOptTemp, OP3("GLOBAL TEMP", "", ""));
  CASEEND
  CASESTART(6)
  res = new IR(kOptTemp, OP3("UNLOGGED", "", ""));
  CASEEND
  CASESTART(7)
  res = new IR(kOptTemp, string(""));
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptTemp::deep_delete() { delete this; };

void OptTemp::generate(){
    GENERATESTART(8)

        SWITCHSTART CASESTART(0) CASEEND CASESTART(1) CASEEND CASESTART(2)
            CASEEND CASESTART(3) CASEEND CASESTART(4) CASEEND CASESTART(5)
                CASEEND CASESTART(6) CASEEND CASESTART(7)

                    CASEEND SWITCHEND

                        GENERATEEND}

IR *OptCheckOption::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  res = new IR(kOptCheckOption, OP3("WITH CHECK OPTION", "", ""));
  CASEEND
  CASESTART(1)
  res = new IR(kOptCheckOption, OP3("WITH CASCADED CHECK OPTION", "", ""));
  CASEEND
  CASESTART(2)
  res = new IR(kOptCheckOption, OP3("WITH LOCAL CHECK OPTION", "", ""));
  CASEEND
  CASESTART(3)
  res = new IR(kOptCheckOption, string(""));
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptCheckOption::deep_delete() { delete this; };

void OptCheckOption::generate(){
    GENERATESTART(4)

        SWITCHSTART CASESTART(0) CASEEND CASESTART(1) CASEEND CASESTART(2)
            CASEEND CASESTART(3)

                CASEEND SWITCHEND

                    GENERATEEND}

IR *OptColumnNameListP::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(column_name_list_);
  res = new IR(kOptColumnNameListP, OP3("(", ")", ""), tmp1);
  CASEEND
  CASESTART(1)
  res = new IR(kOptColumnNameListP, string(""));
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptColumnNameListP::deep_delete() {
  SAFEDELETE(column_name_list_);
  delete this;
};

void OptColumnNameListP::generate() {
  GENERATESTART(2)

  SWITCHSTART
  CASESTART(0)
  column_name_list_ = new ColumnNameList();
  column_name_list_->generate();
  CASEEND
  CASESTART(1)

  CASEEND
  SWITCHEND

  GENERATEEND
}

IR *SetClauseList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(set_clause_);
  res = new IR(kSetClauseList, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(set_clause_);
  auto tmp2 = SAFETRANSLATE(set_clause_list_);
  res = new IR(kSetClauseList, OP3("", ",", ""), tmp1, tmp2);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void SetClauseList::deep_delete() {
  SAFEDELETE(set_clause_);
  SAFEDELETE(set_clause_list_);
  delete this;
};

void SetClauseList::generate() {
  GENERATESTART(200)

  SWITCHSTART
  CASESTART(0)
  set_clause_ = new SetClause();
  set_clause_->generate();
  CASEEND
  CASESTART(1)
  set_clause_ = new SetClause();
  set_clause_->generate();
  set_clause_list_ = new SetClauseList();
  set_clause_list_->generate();
  CASEEND

default: {
  int tmp_case_idx = rand() % 1;
  switch (tmp_case_idx) {
    CASESTART(0)
    set_clause_ = new SetClause();
    set_clause_->generate();
    case_idx_ = 0;
    CASEEND
  }
}
}

GENERATEEND
}

IR *SetClause::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(column_name_);
  auto tmp2 = SAFETRANSLATE(expr_);
  res = new IR(kSetClause, OP3("", "=", ""), tmp1, tmp2);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(column_name_list_);
  auto tmp2 = SAFETRANSLATE(expr_);
  res = new IR(kSetClause, OP3("(", ") =", ""), tmp1, tmp2);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void SetClause::deep_delete() {
  SAFEDELETE(expr_);
  SAFEDELETE(column_name_list_);
  SAFEDELETE(column_name_);
  delete this;
};

void SetClause::generate() {
  GENERATESTART(2)

  SWITCHSTART
  CASESTART(0)
  column_name_ = new ColumnName();
  column_name_->generate();
  expr_ = new Expr();
  expr_->generate();
  CASEEND
  CASESTART(1)
  column_name_list_ = new ColumnNameList();
  column_name_list_->generate();
  expr_ = new Expr();
  expr_->generate();
  CASEEND
  SWITCHEND

  GENERATEEND
}

IR *FuncExpr::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART
  auto tmp_0 = SAFETRANSLATE(func_name_);
  auto tmp_1 = SAFETRANSLATE(func_args_);
  res = new IR(kFuncExpr, OP3("", "(", ")"), tmp_0, tmp_1);
  TRANSLATEEND
}

void FuncExpr::deep_delete() {
  SAFEDELETE(func_name_);
  SAFEDELETE(func_args_);
  delete this;
}

void FuncExpr::generate() {
  GENERATESTART(1)
  func_name_ = new FuncName();
  func_name_->generate();
  func_args_ = new FuncArgs();
  func_args_->generate();
  GENERATEEND
}

IR *FuncName::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART
  SWITCHSTART
  CASESTART(0)
  res = new IR(kFuncName, OP1("SUM"));
  CASEEND
  CASESTART(1)
  res = new IR(kFuncName, OP1("COUNT"));
  CASEEND
  CASESTART(2)
  res = new IR(kFuncName, OP1("COALESCE"));
  CASEEND
  CASESTART(3)
  res = new IR(kFuncName, OP1("ALL"));
  CASEEND
  CASESTART(4)
  res = new IR(kFuncName, OP1("ANY"));
  CASEEND
  CASESTART(5)
  res = new IR(kFuncName, OP1("SOME"));
  CASEEND
  CASESTART(6)
  res = new IR(kFuncName, OP1("LOWER"));
  CASEEND
  CASESTART(7)
  res = new IR(kFuncName, OP1("MIN"));
  CASEEND
  CASESTART(8)
  res = new IR(kFuncName, OP1("MAX"));
  CASEEND
  SWITCHEND
  TRANSLATEEND
}

void FuncName::deep_delete() {
  delete this;
}

void FuncName::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *FuncArgs::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART
  SWITCHSTART
  CASESTART(0)
  auto tmp = SAFETRANSLATE(expr_list_);
  res = new IR(kFuncArgs, OP0(), tmp);
  CASEEND
  CASESTART(1)
  res = new IR(kFuncArgs, OP3("*", "", ""));
  CASEEND
  CASESTART(2)
  res = new IR(kFuncArgs, OP0());
  CASEEND
  SWITCHEND
  TRANSLATEEND
}

void FuncArgs::deep_delete() {
  SAFEDELETE(expr_list_);
  delete this;
}

void FuncArgs::generate() {
  GENERATESTART(3)
  SWITCHSTART
  CASESTART(0)
  expr_list_ = new ExprList();
  expr_list_->generate();
  CASEEND
  CASESTART(1)
  CASEEND
  CASESTART(2)
  CASEEND
  SWITCHEND
  GENERATEEND
}


IR *Expr::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(operand_);
  res = new IR(kExpr, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(between_expr_);
  res = new IR(kExpr, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(2)
  auto tmp1 = SAFETRANSLATE(exists_expr_);
  res = new IR(kExpr, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(3)
  auto tmp1 = SAFETRANSLATE(in_expr_);
  res = new IR(kExpr, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(4)
  auto tmp1 = SAFETRANSLATE(cast_expr_);
  auto tmp2 = SAFETRANSLATE(opt_alias_);
  res = new IR(kExpr, OP3("", "", ""), tmp1, tmp2);
  CASEEND
  CASESTART(5)
  auto tmp1 = SAFETRANSLATE(logic_expr_);
  res = new IR(kExpr, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(6)
  auto tmp1 = SAFETRANSLATE(func_expr_);
  auto tmp2 = SAFETRANSLATE(opt_alias_);
  res = new IR(kExpr, OP3("", "", ""), tmp1, tmp2);
  CASEEND
  CASESTART(7)
  auto tmp1 = SAFETRANSLATE(identifier_);
  auto tmp2 = SAFETRANSLATE(opt_alias_);
  res = new IR(kExpr, OP3("", "", ""), tmp1, tmp2);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void Expr::deep_delete() {
  SAFEDELETE(cast_expr_);
  SAFEDELETE(in_expr_);
  SAFEDELETE(between_expr_);
  SAFEDELETE(operand_);
  SAFEDELETE(exists_expr_);
  SAFEDELETE(logic_expr_);
  SAFEDELETE(func_expr_);
  SAFEDELETE(identifier_);
  SAFEDELETE(opt_alias_);
  delete this;
};

void Expr::generate() {
  GENERATESTART(10)

  SWITCHSTART
  CASESTART(0)
  operand_ = new Operand();
  operand_->generate();
  CASEEND
  CASESTART(1)
  between_expr_ = new BetweenExpr();
  between_expr_->generate();
  CASEEND
  CASESTART(2)
  exists_expr_ = new ExistsExpr();
  exists_expr_->generate();
  CASEEND
  CASESTART(3)
  in_expr_ = new InExpr();
  in_expr_->generate();
  CASEEND
  CASESTART(4)
  cast_expr_ = new CastExpr();
  cast_expr_->generate();
  opt_alias_ = new OptAlias();
  opt_alias_->generate();
  CASEEND
  CASESTART(5)
  logic_expr_ = new LogicExpr();
  logic_expr_->generate();
  CASEEND
  CASESTART(6)
  func_expr_ = new FuncExpr();
  func_expr_->generate();
  opt_alias_ = new OptAlias();
  opt_alias_->generate();
  CASEEND
  CASESTART(7)
  identifier_ = new Identifier();
  identifier_->generate();
  opt_alias_ = new OptAlias();
  opt_alias_->generate();
  CASEEND
  SWITCHEND

  GENERATEEND
}

IR *OptAlias::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART
  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(identifier_);
  res = new IR(kOptAlias, OP3("AS", "", ""), tmp1);
  CASEEND
  CASESTART(1)
  res = new IR(kOptAlias, string(""));
  CASEEND
  SWITCHEND
  TRANSLATEEND
}

void OptAlias::deep_delete() {
  SAFEDELETE(identifier_);
  delete this;
};

void OptAlias::generate() {
  GENERATESTART(2)
  SWITCHSTART
  CASESTART(0)
  identifier_ = new Identifier();
  identifier_->generate();
  CASEEND
  CASESTART(1)

  CASEEND
  SWITCHEND
  GENERATEEND
}

IR *Operand::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(expr_list_);
  res = new IR(kOperand, OP3("(", ")", ""), tmp1);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(array_index_);
  res = new IR(kOperand, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(2)
  auto tmp1 = SAFETRANSLATE(scalar_expr_);
  res = new IR(kOperand, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(3)
  auto tmp1 = SAFETRANSLATE(unary_expr_);
  res = new IR(kOperand, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(4)
  auto tmp1 = SAFETRANSLATE(binary_expr_);
  res = new IR(kOperand, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(5)
  auto tmp1 = SAFETRANSLATE(case_expr_);
  res = new IR(kOperand, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(6)
  auto tmp1 = SAFETRANSLATE(extract_expr_);
  res = new IR(kOperand, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(7)
  auto tmp1 = SAFETRANSLATE(select_no_parens_);
  res = new IR(kOperand, OP3("(", ")", ""), tmp1);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void Operand::deep_delete() {
  SAFEDELETE(unary_expr_);
  SAFEDELETE(expr_list_);
  SAFEDELETE(case_expr_);
  SAFEDELETE(select_no_parens_);
  SAFEDELETE(extract_expr_);
  SAFEDELETE(array_index_);
  SAFEDELETE(binary_expr_);
  SAFEDELETE(scalar_expr_);
  delete this;
};

void Operand::generate() {
  GENERATESTART(8)

  SWITCHSTART
  CASESTART(0)
  expr_list_ = new ExprList();
  expr_list_->generate();
  CASEEND
  CASESTART(1)
  array_index_ = new ArrayIndex();
  array_index_->generate();
  CASEEND
  CASESTART(2)
  scalar_expr_ = new ScalarExpr();
  scalar_expr_->generate();
  CASEEND
  CASESTART(3)
  unary_expr_ = new UnaryExpr();
  unary_expr_->generate();
  CASEEND
  CASESTART(4)
  binary_expr_ = new BinaryExpr();
  binary_expr_->generate();
  CASEEND
  CASESTART(5)
  case_expr_ = new CaseExpr();
  case_expr_->generate();
  CASEEND
  CASESTART(6)
  extract_expr_ = new ExtractExpr();
  extract_expr_->generate();
  CASEEND
  CASESTART(7)
  select_no_parens_ = new SelectNoParens();
  select_no_parens_->generate();
  CASEEND
  SWITCHEND

  GENERATEEND
}

IR *CastExpr::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART
  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(expr_);
  auto tmp2 = SAFETRANSLATE(type_name_);
  res = new IR(kCastExpr, OP3("CAST (", "AS", ")"), tmp1, tmp2);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(expr_);
  auto tmp2 = SAFETRANSLATE(type_name_);
  res = new IR(kCastExpr, OPMID("::"), tmp1, tmp2);
  CASEEND
  SWITCHEND
  TRANSLATEEND
}

void CastExpr::deep_delete() {
  SAFEDELETE(expr_);
  SAFEDELETE(type_name_);
  delete this;
};

void CastExpr::generate() {
  GENERATESTART(1)

  expr_ = new Expr();
  expr_->generate();
  type_name_ = new TypeName();
  type_name_->generate();

  GENERATEEND
}

IR *CountExpr::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(expr_);
  res = new IR(kCountExpr, OP2("COUNT (", ")"), tmp1);

  TRANSLATEEND
}

IR *AllExpr::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(expr_);
  res = new IR(kAllExpr, OP2("ALL (", ")"), tmp1);

  TRANSLATEEND
}

IR *SumExpr::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(expr_);
  res = new IR(kSumExpr, OP2("SUM (", ")"), tmp1);

  TRANSLATEEND
}

void CountExpr::deep_delete() {
  SAFEDELETE(expr_);
  delete this;
};

void AllExpr::deep_delete() {
  SAFEDELETE(expr_);
  delete this;
};

void SumExpr::deep_delete() {
  SAFEDELETE(expr_);
  delete this;
};

void CountExpr::generate() {
  GENERATESTART(1)

  expr_ = new Expr();
  expr_->generate();

  GENERATEEND
}

void AllExpr::generate() {
  GENERATESTART(1)

  expr_ = new Expr();
  expr_->generate();

  GENERATEEND
}

void SumExpr::generate() {
  GENERATESTART(1)

  expr_ = new Expr();
  expr_->generate();

  GENERATEEND
}

IR *ScalarExpr::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(column_name_);
  res = new IR(kScalarExpr, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(literal_);
  res = new IR(kScalarExpr, OP3("", "", ""), tmp1);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void ScalarExpr::deep_delete() {
  SAFEDELETE(literal_);
  SAFEDELETE(column_name_);
  delete this;
};

void ScalarExpr::generate() {
  GENERATESTART(2)

  SWITCHSTART
  CASESTART(0)
  column_name_ = new ColumnName();
  column_name_->generate();
  CASEEND
  CASESTART(1)
  literal_ = new Literal();
  literal_->generate();
  CASEEND
  SWITCHEND

  GENERATEEND
}

IR *UnaryExpr::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(operand_);
  res = new IR(kUnaryExpr, OP3("-", "", ""), tmp1);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(operand_);
  res = new IR(kUnaryExpr, OP3("NOT", "", ""), tmp1);
  CASEEND
  CASESTART(2)
  auto tmp1 = SAFETRANSLATE(operand_);
  res = new IR(kUnaryExpr, OP3("", "ISNULL", ""), tmp1);
  CASEEND
  CASESTART(3)
  auto tmp1 = SAFETRANSLATE(operand_);
  res = new IR(kUnaryExpr, OP3("", "IS NULL", ""), tmp1);
  CASEEND
  CASESTART(4)
  auto tmp1 = SAFETRANSLATE(operand_);
  res = new IR(kUnaryExpr, OP3("", "IS NOT NULL", ""), tmp1);
  CASEEND
  CASESTART(5)
  res = new IR(kUnaryExpr, OP3("NULL", "", ""));
  CASEEND
  CASESTART(6)
  res = new IR(kUnaryExpr, OP3("*", "", ""));
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void UnaryExpr::deep_delete() {
  SAFEDELETE(operand_);
  delete this;
};

void UnaryExpr::generate() {
  GENERATESTART(7)

  SWITCHSTART
  CASESTART(0)
  operand_ = new Operand();
  operand_->generate();
  CASEEND
  CASESTART(1)
  operand_ = new Operand();
  operand_->generate();
  CASEEND
  CASESTART(2)
  operand_ = new Operand();
  operand_->generate();
  CASEEND
  CASESTART(3)
  operand_ = new Operand();
  operand_->generate();
  CASEEND
  CASESTART(4)
  operand_ = new Operand();
  operand_->generate();
  CASEEND
  CASESTART(5)
  CASEEND
  CASESTART(6)
  CASEEND
  SWITCHEND

  GENERATEEND
}

IR *BinaryExpr::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(comp_expr_);
  res = new IR(kBinaryExpr, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(operand_1_);
  auto tmp2 = SAFETRANSLATE(binary_op_);
  auto tmp3 = SAFETRANSLATE(operand_2_);
  auto tmp4 = new IR(kUnknown, OP3("", "", ""), tmp1, tmp2);
  PUSH(tmp4);
  res = new IR(kBinaryExpr, OP3("", "", ""), tmp4, tmp3);
  CASEEND
  CASESTART(2)
  auto tmp1 = SAFETRANSLATE(operand_1_);
  auto tmp2 = SAFETRANSLATE(operand_2_);
  res = new IR(kBinaryExpr, OP3("", "LIKE", ""), tmp1, tmp2);
  CASEEND
  CASESTART(3)
  auto tmp1 = SAFETRANSLATE(operand_1_);
  auto tmp2 = SAFETRANSLATE(operand_2_);
  res = new IR(kBinaryExpr, OP3("", "NOT LIKE", ""), tmp1, tmp2);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void BinaryExpr::deep_delete() {
  SAFEDELETE(operand_1_);
  SAFEDELETE(operand_2_);
  SAFEDELETE(binary_op_);
  SAFEDELETE(comp_expr_);
  delete this;
};

void BinaryExpr::generate() {
  GENERATESTART(4)

  SWITCHSTART
  CASESTART(0)
  comp_expr_ = new CompExpr();
  comp_expr_->generate();
  CASEEND
  CASESTART(1)
  operand_1_ = new Operand();
  operand_1_->generate();
  binary_op_ = new BinaryOp();
  binary_op_->generate();
  operand_2_ = new Operand();
  operand_2_->generate();
  CASEEND
  CASESTART(2)
  operand_1_ = new Operand();
  operand_1_->generate();
  operand_2_ = new Operand();
  operand_2_->generate();
  CASEEND
  CASESTART(3)
  operand_1_ = new Operand();
  operand_1_->generate();
  operand_2_ = new Operand();
  operand_2_->generate();
  CASEEND
  SWITCHEND

  GENERATEEND
}

IR *LogicExpr::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(expr_1_);
  auto tmp2 = SAFETRANSLATE(expr_2_);
  res = new IR(kLogicExpr, OP3("", "AND", ""), tmp1, tmp2);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(expr_1_);
  auto tmp2 = SAFETRANSLATE(expr_2_);
  res = new IR(kLogicExpr, OP3("", "OR", ""), tmp1, tmp2);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void LogicExpr::deep_delete() {
  SAFEDELETE(expr_1_);
  SAFEDELETE(expr_2_);
  delete this;
};

void LogicExpr::generate() {
  GENERATESTART(2)

  SWITCHSTART
  CASESTART(0)
  expr_1_ = new Expr();
  expr_1_->generate();
  expr_2_ = new Expr();
  expr_2_->generate();
  CASEEND
  CASESTART(1)
  expr_1_ = new Expr();
  expr_1_->generate();
  expr_2_ = new Expr();
  expr_2_->generate();
  CASEEND
  SWITCHEND

  GENERATEEND
}

IR *InExpr::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(operand_);
  auto tmp2 = SAFETRANSLATE(opt_not_);
  auto tmp3 = SAFETRANSLATE(select_no_parens_);
  auto tmp4 = new IR(kUnknown, OP3("", "", "IN"), tmp1, tmp2);
  PUSH(tmp4);
  res = new IR(kInExpr, OP3("", "(", ")"), tmp4, tmp3);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(operand_);
  auto tmp2 = SAFETRANSLATE(opt_not_);
  auto tmp3 = SAFETRANSLATE(expr_list_);
  auto tmp4 = new IR(kUnknown, OP3("", "", "IN"), tmp1, tmp2);
  PUSH(tmp4);
  res = new IR(kInExpr, OP3("", "(", ")"), tmp4, tmp3);
  CASEEND
  CASESTART(2)
  auto tmp1 = SAFETRANSLATE(operand_);
  auto tmp2 = SAFETRANSLATE(opt_not_);
  auto tmp3 = SAFETRANSLATE(table_name_);
  auto tmp4 = new IR(kUnknown, OP3("", "", "IN"), tmp1, tmp2);
  PUSH(tmp4);
  res = new IR(kInExpr, OP3("", "", ""), tmp4, tmp3);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void InExpr::deep_delete() {
  SAFEDELETE(operand_);
  SAFEDELETE(expr_list_);
  SAFEDELETE(opt_not_);
  SAFEDELETE(table_name_);
  SAFEDELETE(select_no_parens_);
  delete this;
};

void InExpr::generate() {
  GENERATESTART(3)

  SWITCHSTART
  CASESTART(0)
  operand_ = new Operand();
  operand_->generate();
  opt_not_ = new OptNot();
  opt_not_->generate();
  select_no_parens_ = new SelectNoParens();
  select_no_parens_->generate();
  CASEEND
  CASESTART(1)
  operand_ = new Operand();
  operand_->generate();
  opt_not_ = new OptNot();
  opt_not_->generate();
  expr_list_ = new ExprList();
  expr_list_->generate();
  CASEEND
  CASESTART(2)
  operand_ = new Operand();
  operand_->generate();
  opt_not_ = new OptNot();
  opt_not_->generate();
  table_name_ = new TableName();
  table_name_->generate();
  CASEEND
  SWITCHEND

  GENERATEEND
}

IR *CaseExpr::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(expr_1_);
  auto tmp2 = SAFETRANSLATE(case_list_);
  res = new IR(kCaseExpr, OP3("CASE", "", "END"), tmp1, tmp2);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(case_list_);
  res = new IR(kCaseExpr, OP3("CASE", "END", ""), tmp1);
  CASEEND
  CASESTART(2)
  auto tmp1 = SAFETRANSLATE(expr_1_);
  auto tmp2 = SAFETRANSLATE(case_list_);
  auto tmp3 = SAFETRANSLATE(expr_2_);
  auto tmp4 = new IR(kUnknown, OP3("CASE", "", "ELSE"), tmp1, tmp2);
  PUSH(tmp4);
  res = new IR(kCaseExpr, OP3("", "", "END"), tmp4, tmp3);
  CASEEND
  CASESTART(3)
  auto tmp1 = SAFETRANSLATE(case_list_);
  auto tmp2 = SAFETRANSLATE(expr_1_);
  res = new IR(kCaseExpr, OP3("CASE", "ELSE", "END"), tmp1, tmp2);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void CaseExpr::deep_delete() {
  SAFEDELETE(expr_1_);
  SAFEDELETE(expr_2_);
  SAFEDELETE(case_list_);
  delete this;
};

void CaseExpr::generate() {
  GENERATESTART(4)

  SWITCHSTART
  CASESTART(0)
  expr_1_ = new Expr();
  expr_1_->generate();
  case_list_ = new CaseList();
  case_list_->generate();
  CASEEND
  CASESTART(1)
  case_list_ = new CaseList();
  case_list_->generate();
  CASEEND
  CASESTART(2)
  expr_1_ = new Expr();
  expr_1_->generate();
  case_list_ = new CaseList();
  case_list_->generate();
  expr_2_ = new Expr();
  expr_2_->generate();
  CASEEND
  CASESTART(3)
  case_list_ = new CaseList();
  case_list_->generate();
  expr_1_ = new Expr();
  expr_1_->generate();
  CASEEND
  SWITCHEND

  GENERATEEND
}

IR *BetweenExpr::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(operand_1_);
  auto tmp2 = SAFETRANSLATE(operand_2_);
  auto tmp3 = SAFETRANSLATE(operand_3_);
  auto tmp4 = new IR(kUnknown, OP3("", "BETWEEN", "AND"), tmp1, tmp2);
  PUSH(tmp4);
  res = new IR(kBetweenExpr, OP3("", "", ""), tmp4, tmp3);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(operand_1_);
  auto tmp2 = SAFETRANSLATE(operand_2_);
  auto tmp3 = SAFETRANSLATE(operand_3_);
  auto tmp4 = new IR(kUnknown, OP3("", "NOT BETWEEN", "AND"), tmp1, tmp2);
  PUSH(tmp4);
  res = new IR(kBetweenExpr, OP3("", "", ""), tmp4, tmp3);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void BetweenExpr::deep_delete() {
  SAFEDELETE(operand_1_);
  SAFEDELETE(operand_2_);
  SAFEDELETE(operand_3_);
  delete this;
};

void BetweenExpr::generate() {
  GENERATESTART(2)

  SWITCHSTART
  CASESTART(0)
  operand_1_ = new Operand();
  operand_1_->generate();
  operand_2_ = new Operand();
  operand_2_->generate();
  operand_3_ = new Operand();
  operand_3_->generate();
  CASEEND
  CASESTART(1)
  operand_1_ = new Operand();
  operand_1_->generate();
  operand_2_ = new Operand();
  operand_2_->generate();
  operand_3_ = new Operand();
  operand_3_->generate();
  CASEEND
  SWITCHEND

  GENERATEEND
}

IR *ExistsExpr::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(opt_not_);
  auto tmp2 = SAFETRANSLATE(select_no_parens_);
  res = new IR(kExistsExpr, OP3("", "EXISTS (", ")"), tmp1, tmp2);

  TRANSLATEEND
}

void ExistsExpr::deep_delete() {
  SAFEDELETE(opt_not_);
  SAFEDELETE(select_no_parens_);
  delete this;
};

void ExistsExpr::generate() {
  GENERATESTART(1)

  opt_not_ = new OptNot();
  opt_not_->generate();
  select_no_parens_ = new SelectNoParens();
  select_no_parens_->generate();

  GENERATEEND
}

IR *CaseList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(case_clause_);
  res = new IR(kCaseList, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(case_clause_);
  auto tmp2 = SAFETRANSLATE(case_list_);
  res = new IR(kCaseList, OP3("", "", ""), tmp1, tmp2);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void CaseList::deep_delete() {
  SAFEDELETE(case_list_);
  SAFEDELETE(case_clause_);
  delete this;
};

void CaseList::generate() {
  GENERATESTART(200)

  SWITCHSTART
  CASESTART(0)
  case_clause_ = new CaseClause();
  case_clause_->generate();
  CASEEND
  CASESTART(1)
  case_clause_ = new CaseClause();
  case_clause_->generate();
  case_list_ = new CaseList();
  case_list_->generate();
  CASEEND

default: {
  int tmp_case_idx = rand() % 1;
  switch (tmp_case_idx) {
    CASESTART(0)
    case_clause_ = new CaseClause();
    case_clause_->generate();
    case_idx_ = 0;
    CASEEND
  }
}
}

GENERATEEND
}

IR *CaseClause::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(expr_1_);
  auto tmp2 = SAFETRANSLATE(expr_2_);
  res = new IR(kCaseClause, OP3("WHEN", "THEN", ""), tmp1, tmp2);

  TRANSLATEEND
}

void CaseClause::deep_delete() {
  SAFEDELETE(expr_1_);
  SAFEDELETE(expr_2_);
  delete this;
};

void CaseClause::generate() {
  GENERATESTART(1)

  expr_1_ = new Expr();
  expr_1_->generate();
  expr_2_ = new Expr();
  expr_2_->generate();

  GENERATEEND
}

IR *CompExpr::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(operand_1_);
  auto tmp2 = SAFETRANSLATE(operand_2_);
  res = new IR(kCompExpr, OP3("", "=", ""), tmp1, tmp2);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(operand_1_);
  auto tmp2 = SAFETRANSLATE(operand_2_);
  res = new IR(kCompExpr, OP3("", "!=", ""), tmp1, tmp2);
  CASEEND
  CASESTART(2)
  auto tmp1 = SAFETRANSLATE(operand_1_);
  auto tmp2 = SAFETRANSLATE(operand_2_);
  res = new IR(kCompExpr, OP3("", ">", ""), tmp1, tmp2);
  CASEEND
  CASESTART(3)
  auto tmp1 = SAFETRANSLATE(operand_1_);
  auto tmp2 = SAFETRANSLATE(operand_2_);
  res = new IR(kCompExpr, OP3("", "<", ""), tmp1, tmp2);
  CASEEND
  CASESTART(4)
  auto tmp1 = SAFETRANSLATE(operand_1_);
  auto tmp2 = SAFETRANSLATE(operand_2_);
  res = new IR(kCompExpr, OP3("", "<=", ""), tmp1, tmp2);
  CASEEND
  CASESTART(5)
  auto tmp1 = SAFETRANSLATE(operand_1_);
  auto tmp2 = SAFETRANSLATE(operand_2_);
  res = new IR(kCompExpr, OP3("", ">=", ""), tmp1, tmp2);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void CompExpr::deep_delete() {
  SAFEDELETE(operand_1_);
  SAFEDELETE(operand_2_);
  delete this;
};

void CompExpr::generate() {
  GENERATESTART(6)

  SWITCHSTART
  CASESTART(0)
  operand_1_ = new Operand();
  operand_1_->generate();
  operand_2_ = new Operand();
  operand_2_->generate();
  CASEEND
  CASESTART(1)
  operand_1_ = new Operand();
  operand_1_->generate();
  operand_2_ = new Operand();
  operand_2_->generate();
  CASEEND
  CASESTART(2)
  operand_1_ = new Operand();
  operand_1_->generate();
  operand_2_ = new Operand();
  operand_2_->generate();
  CASEEND
  CASESTART(3)
  operand_1_ = new Operand();
  operand_1_->generate();
  operand_2_ = new Operand();
  operand_2_->generate();
  CASEEND
  CASESTART(4)
  operand_1_ = new Operand();
  operand_1_->generate();
  operand_2_ = new Operand();
  operand_2_->generate();
  CASEEND
  CASESTART(5)
  operand_1_ = new Operand();
  operand_1_->generate();
  operand_2_ = new Operand();
  operand_2_->generate();
  CASEEND
  SWITCHEND

  GENERATEEND
}

IR *ExtractExpr::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(datetime_field_);
  auto tmp2 = SAFETRANSLATE(expr_);
  res = new IR(kExtractExpr, OP3("EXTRACT (", "FROM", ")"), tmp1, tmp2);

  TRANSLATEEND
}

void ExtractExpr::deep_delete() {
  SAFEDELETE(datetime_field_);
  SAFEDELETE(expr_);
  delete this;
};

void ExtractExpr::generate() {
  GENERATESTART(1)

  datetime_field_ = new DatetimeField();
  datetime_field_->generate();
  expr_ = new Expr();
  expr_->generate();

  GENERATEEND
}

IR *DatetimeField::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  res = new IR(kDatetimeField, OP3("SECOND", "", ""));
  CASEEND
  CASESTART(1)
  res = new IR(kDatetimeField, OP3("MINUTE", "", ""));
  CASEEND
  CASESTART(2)
  res = new IR(kDatetimeField, OP3("HOUR", "", ""));
  CASEEND
  CASESTART(3)
  res = new IR(kDatetimeField, OP3("DAY", "", ""));
  CASEEND
  CASESTART(4)
  res = new IR(kDatetimeField, OP3("MONTH", "", ""));
  CASEEND
  CASESTART(5)
  res = new IR(kDatetimeField, OP3("YEAR", "", ""));
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void DatetimeField::deep_delete() { delete this; };

void DatetimeField::generate(){
    GENERATESTART(6)

        SWITCHSTART CASESTART(0) CASEEND CASESTART(1) CASEEND CASESTART(2)
            CASEEND CASESTART(3) CASEEND CASESTART(4) CASEEND CASESTART(5)
                CASEEND SWITCHEND

                    GENERATEEND}

IR *ArrayIndex::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(operand_);
  auto tmp2 = SAFETRANSLATE(int_literal_);
  res = new IR(kArrayIndex, OP3("", "[", "]"), tmp1, tmp2);

  TRANSLATEEND
}

void ArrayIndex::deep_delete() {
  SAFEDELETE(operand_);
  SAFEDELETE(int_literal_);
  delete this;
};

void ArrayIndex::generate() {
  GENERATESTART(1)

  operand_ = new Operand();
  operand_->generate();
  int_literal_ = new IntLiteral();
  int_literal_->generate();

  GENERATEEND
}

IR *Literal::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(string_literal_);
  res = new IR(kLiteral, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(bool_literal_);
  res = new IR(kLiteral, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(2)
  auto tmp1 = SAFETRANSLATE(num_literal_);
  res = new IR(kLiteral, OP3("", "", ""), tmp1);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void Literal::deep_delete() {
  SAFEDELETE(bool_literal_);
  SAFEDELETE(string_literal_);
  SAFEDELETE(num_literal_);
  delete this;
};

void Literal::generate() {
  GENERATESTART(3)

  SWITCHSTART
  CASESTART(0)
  string_literal_ = new StringLiteral();
  string_literal_->generate();
  CASEEND
  CASESTART(1)
  bool_literal_ = new BoolLiteral();
  bool_literal_->generate();
  CASEEND
  CASESTART(2)
  num_literal_ = new NumLiteral();
  num_literal_->generate();
  CASEEND
  SWITCHEND

  GENERATEEND
}

IR *StringLiteral::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  res = new IR(kStringLiteral, string_val_, kDataLiteral, scope_, data_flag_);

  TRANSLATEEND
}

void StringLiteral::deep_delete() { delete this; };

void StringLiteral::generate() {
  GENERATESTART(1)

  string_val_ = gen_string();

  GENERATEEND
}

IR *BoolLiteral::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  res = new IR(kBoolLiteral, OP3("TRUE", "", ""));
  res->data_type_ = kDataLiteral;
  CASEEND
  CASESTART(1)
  res = new IR(kBoolLiteral, OP3("FALSE", "", ""));
  res->data_type_ = kDataLiteral;
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void BoolLiteral::deep_delete() { delete this; };

void BoolLiteral::generate(){GENERATESTART(2)

                                 SWITCHSTART CASESTART(0) CASEEND CASESTART(1)
                                     CASEEND SWITCHEND

                                         GENERATEEND}

IR *NumLiteral::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(int_literal_);
  res = new IR(kNumLiteral, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(float_literal_);
  res = new IR(kNumLiteral, OP3("", "", ""), tmp1);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void NumLiteral::deep_delete() {
  SAFEDELETE(int_literal_);
  SAFEDELETE(float_literal_);
  delete this;
};

void NumLiteral::generate() {
  GENERATESTART(2)

  SWITCHSTART
  CASESTART(0)
  int_literal_ = new IntLiteral();
  int_literal_->generate();
  CASEEND
  CASESTART(1)
  float_literal_ = new FloatLiteral();
  float_literal_->generate();
  CASEEND
  SWITCHEND

  GENERATEEND
}

IR *IntLiteral::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  res = new IR(kIntLiteral, int_val_, kDataLiteral, scope_, data_flag_);

  TRANSLATEEND
}

void IntLiteral::deep_delete() { delete this; };

void IntLiteral::generate() {
  GENERATESTART(1)

  int_val_ = gen_int();

  GENERATEEND
}

IR *FloatLiteral::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  res = new IR(kFloatLiteral, float_val_, kDataLiteral, scope_, data_flag_);

  TRANSLATEEND
}

void FloatLiteral::deep_delete() { delete this; };

void FloatLiteral::generate() {
  GENERATESTART(1)

  float_val_ = gen_float();

  GENERATEEND
}

IR *OptColumn::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  res = new IR(kOptColumn, OP3("COLUMN", "", ""));
  CASEEND
  CASESTART(1)
  res = new IR(kOptColumn, string(""));
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptColumn::deep_delete() { delete this; };

void OptColumn::generate(){GENERATESTART(2)

                               SWITCHSTART CASESTART(0) CASEEND CASESTART(1)

                                   CASEEND SWITCHEND

                                       GENERATEEND}

IR *OptIfNotExist::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  res = new IR(kOptIfNotExist, OP3("IF NOT EXISTS", "", ""));
  CASEEND
  CASESTART(1)
  res = new IR(kOptIfNotExist, string(""));
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptIfNotExist::deep_delete() { delete this; };

void OptIfNotExist::generate(){GENERATESTART(2)

                                   SWITCHSTART CASESTART(0) CASEEND CASESTART(1)

                                       CASEEND SWITCHEND

                                           GENERATEEND}

IR *OptIfExist::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  res = new IR(kOptIfExist, OP3("IF EXISTS", "", ""));
  CASEEND
  CASESTART(1)
  res = new IR(kOptIfExist, string(""));
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptIfExist::deep_delete() { delete this; };

void OptIfExist::generate(){GENERATESTART(2)

                                SWITCHSTART CASESTART(0) CASEEND CASESTART(1)

                                    CASEEND SWITCHEND

                                        GENERATEEND}

IR *Identifier::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  res = new IR(kIdentifier, string_val_, data_type_, scope_, data_flag_);

  TRANSLATEEND
}

void Identifier::deep_delete() { delete this; };

void Identifier::generate() {
  GENERATESTART(1)

  string_val_ = gen_string();

  GENERATEEND
}

IR *TableName::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(identifier_);
  res = new IR(kTableName, OP3("", "", ""), tmp1);

  TRANSLATEEND
}

void TableName::deep_delete() {
  SAFEDELETE(identifier_);
  delete this;
};

void TableName::generate() {
  GENERATESTART(1)

  identifier_ = new Identifier();
  identifier_->generate();

  GENERATEEND
}

IR *ColumnName::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(identifier_);
  res = new IR(kColumnName, OP3("", "", ""), tmp1);

  TRANSLATEEND
}

void ColumnName::deep_delete() {
  SAFEDELETE(identifier_);
  delete this;
};

void ColumnName::generate() {
  GENERATESTART(1)

  identifier_ = new Identifier();
  identifier_->generate();

  GENERATEEND
}

IR *OptUnique::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  res = new IR(kOptUnique, OP3("UNIQUE", "", ""));
  CASEEND
  CASESTART(1)
  res = new IR(kOptUnique, string(""));
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptUnique::deep_delete() { delete this; };

void OptUnique::generate(){GENERATESTART(2)

                               SWITCHSTART CASESTART(0) CASEEND CASESTART(1)

                                   CASEEND SWITCHEND

                                       GENERATEEND}

IR *ViewName::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(identifier_);
  res = new IR(kViewName, OP3("", "", ""), tmp1);

  TRANSLATEEND
}

void ViewName::deep_delete() {
  SAFEDELETE(identifier_);
  delete this;
};

void ViewName::generate() {
  GENERATESTART(1)

  identifier_ = new Identifier();
  identifier_->generate();

  GENERATEEND
}

IR *IndexName::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(identifier_);
  res = new IR(kIndexName, OP3("", "", ""), tmp1);

  TRANSLATEEND
}

void IndexName::deep_delete() {
  SAFEDELETE(identifier_);
  delete this;
};

void IndexName::generate() {
  GENERATESTART(1)

  identifier_ = new Identifier();
  identifier_->generate();

  GENERATEEND
}

IR *TablespaceName::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(identifier_);
  res = new IR(kTablespaceName, OP3("", "", ""), tmp1);

  TRANSLATEEND
}

void TablespaceName::deep_delete() {
  SAFEDELETE(identifier_);
  delete this;
};

void TablespaceName::generate() {
  GENERATESTART(1)

  identifier_ = new Identifier();
  identifier_->generate();

  GENERATEEND
}

IR *RoleName::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(identifier_);
  res = new IR(kRoleName, OP3("", "", ""), tmp1);

  TRANSLATEEND
}

void RoleName::deep_delete() {
  SAFEDELETE(identifier_);
  delete this;
};

void RoleName::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *ExtensionName::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(identifier_);
  res = new IR(kExtensionName, OP3("", "", ""), tmp1);

  TRANSLATEEND
}

void ExtensionName::deep_delete() {
  SAFEDELETE(identifier_);
  delete this;
};

void ExtensionName::generate() {
  GENERATESTART(1)

  identifier_ = new Identifier();
  identifier_->generate();

  GENERATEEND
}

IR *IndexStorageParameterList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(index_storage_parameter_);
  res = new IR(kIndexStorageParameterList, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(index_storage_parameter_);
  auto tmp2 = SAFETRANSLATE(index_storage_parameter_list_);
  res = new IR(kIndexStorageParameterList, OP3("", ",", ""), tmp1, tmp2);
  CASEEND
  SWITCHEND
  TRANSLATEEND
}

void IndexStorageParameterList::deep_delete() {
  SAFEDELETE(index_storage_parameter_);
  SAFEDELETE(index_storage_parameter_list_);
  delete this;
};

void IndexStorageParameterList::generate() {
  GENERATESTART(1)
  GENERATEEND
};

IR *IndexStorageParameter::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(int_literal_);
  res = new IR(kIndexStorageParameter, OP3("FILLFACTOR=", "", ""), tmp1);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(on_off_literal_);
  res = new IR(kIndexStorageParameter, OP3("BUFFERING=", "", ""), tmp1);
  CASEEND
  CASESTART(2)
  auto tmp1 = SAFETRANSLATE(on_off_literal_);
  res = new IR(kIndexStorageParameter, OP3("FASTUPDATE=", "", ""), tmp1);
  CASEEND
  CASESTART(3)
  auto tmp1 = SAFETRANSLATE(int_literal_);
  res = new IR(kIndexStorageParameter, OP3("gin_pending_list_limit=", "", ""), tmp1);
  CASEEND
  CASESTART(4)
  auto tmp1 = SAFETRANSLATE(int_literal_);
  res = new IR(kIndexStorageParameter, OP3("pages_per_range=", "", ""), tmp1);
  CASEEND
  CASESTART(5)
  auto tmp1 = SAFETRANSLATE(on_off_literal_);
  res = new IR(kIndexStorageParameter, OP3("AUTOSUMMARIZE=", "", ""), tmp1);
  CASEEND
  CASESTART(6)
  auto tmp1 = SAFETRANSLATE(on_off_literal_);
  res = new IR(kIndexStorageParameter, OP3("deduplicate_items=", "", ""), tmp1);
  CASEEND
  SWITCHEND
  TRANSLATEEND
}

void IndexStorageParameter::deep_delete() {
  SAFEDELETE(int_literal_);
  SAFEDELETE(bool_literal_);
  SAFEDELETE(on_off_literal_);
  delete this;
};

void IndexStorageParameter::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *BinaryOp::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  res = new IR(kBinaryOp, OP3("+", "", ""));
  CASEEND
  CASESTART(1)
  res = new IR(kBinaryOp, OP3("-", "", ""));
  CASEEND
  CASESTART(2)
  res = new IR(kBinaryOp, OP3("/", "", ""));
  CASEEND
  CASESTART(3)
  res = new IR(kBinaryOp, OP3("%", "", ""));
  CASEEND
  CASESTART(4)
  res = new IR(kBinaryOp, OP3("*", "", ""));
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void BinaryOp::deep_delete() { delete this; };

void BinaryOp::generate(){GENERATESTART(5)

                              SWITCHSTART CASESTART(0) CASEEND CASESTART(1)
                                  CASEEND CASESTART(2) CASEEND CASESTART(3)
                                      CASEEND CASESTART(4) CASEEND SWITCHEND

                                          GENERATEEND}

IR *OptNot::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  res = new IR(kOptNot, OP3("NOT", "", ""));
  CASEEND
  CASESTART(1)
  res = new IR(kOptNot, string(""));
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptNot::deep_delete() { delete this; };

void OptNot::generate(){GENERATESTART(2)

                            SWITCHSTART CASESTART(0) CASEEND CASESTART(1)

                                CASEEND SWITCHEND

                                    GENERATEEND}

IR *Name::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(identifier_);
  res = new IR(kName, OP3("", "", ""), tmp1);

  TRANSLATEEND
}

void Name::deep_delete() {
  SAFEDELETE(identifier_);
  delete this;
};

void Name::generate() {
  GENERATESTART(1)

  identifier_ = new Identifier();
  identifier_->generate();

  GENERATEEND
}

IR *TypeName::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(numeric_type_);
  res = new IR(kTypeName, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(character_type_);
  res = new IR(kTypeName, OP3("", "", ""), tmp1);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void TypeName::deep_delete() {
  SAFEDELETE(numeric_type_);
  SAFEDELETE(character_type_);
  delete this;
};

void TypeName::generate() {
  GENERATESTART(2)

  SWITCHSTART
  CASESTART(0)
  numeric_type_ = new NumericType();
  numeric_type_->generate();
  CASEEND
  CASESTART(1)
  character_type_ = new CharacterType();
  character_type_->generate();
  CASEEND
  SWITCHEND

  GENERATEEND
}

IR *CharacterType::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(character_with_length_);
  res = new IR(kCharacterType, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(character_without_length_);
  res = new IR(kCharacterType, OP3("", "", ""), tmp1);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void CharacterType::deep_delete() {
  SAFEDELETE(character_with_length_);
  SAFEDELETE(character_without_length_);
  delete this;
};

void CharacterType::generate() {
  GENERATESTART(2)

  SWITCHSTART
  CASESTART(0)
  character_with_length_ = new CharacterWithLength();
  character_with_length_->generate();
  CASEEND
  CASESTART(1)
  character_without_length_ = new CharacterWithoutLength();
  character_without_length_->generate();
  CASEEND
  SWITCHEND

  GENERATEEND
}

IR *CharacterWithLength::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(character_conflicta_);
  auto tmp2 = SAFETRANSLATE(int_literal_);
  res = new IR(kCharacterWithLength, OP3("", "(", ")"), tmp1, tmp2);

  TRANSLATEEND
}

void CharacterWithLength::deep_delete() {
  SAFEDELETE(character_conflicta_);
  SAFEDELETE(int_literal_);
  delete this;
};

void CharacterWithLength::generate() {
  GENERATESTART(1)

  character_conflicta_ = new CharacterConflicta();
  character_conflicta_->generate();
  int_literal_ = new IntLiteral();
  int_literal_->generate();

  GENERATEEND
}

IR *CharacterWithoutLength::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(character_conflicta_);
  res = new IR(kCharacterWithoutLength, OP3("", "", ""), tmp1);

  TRANSLATEEND
}

void CharacterWithoutLength::deep_delete() {
  SAFEDELETE(character_conflicta_);
  delete this;
};

void CharacterWithoutLength::generate() {
  GENERATESTART(1)

  character_conflicta_ = new CharacterConflicta();
  character_conflicta_->generate();

  GENERATEEND
}

IR *CharacterConflicta::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(opt_varying_);
  res = new IR(kCharacterConflicta, OP3("CHARACTER", "", ""), tmp1);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(opt_varying_);
  res = new IR(kCharacterConflicta, OP3("CHAR", "", ""), tmp1);
  CASEEND
  CASESTART(2)
  res = new IR(kCharacterConflicta, OP3("VARCHAR", "", ""));
  CASEEND
  CASESTART(3)
  res = new IR(kCharacterConflicta, OP3("TEXT", "", ""));
  CASEEND
  CASESTART(4)
  auto tmp1 = SAFETRANSLATE(opt_varying_);
  res = new IR(kCharacterConflicta, OP3("NATIONAL CHARACTER", "", ""), tmp1);
  CASEEND
  CASESTART(5)
  auto tmp1 = SAFETRANSLATE(opt_varying_);
  res = new IR(kCharacterConflicta, OP3("NATIONAL CHAR", "", ""), tmp1);
  CASEEND
  CASESTART(6)
  auto tmp1 = SAFETRANSLATE(opt_varying_);
  res = new IR(kCharacterConflicta, OP3("NCHAR", "", ""), tmp1);
  CASEEND
  CASESTART(7)
  auto tmp1 = SAFETRANSLATE(int_literal_);
  res = new IR(kCharacterConflicta, OP3("VARCHAR (", "", ")"), tmp1);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void CharacterConflicta::deep_delete() {
  SAFEDELETE(opt_varying_);
  SAFEDELETE(int_literal_);
  delete this;
};

void CharacterConflicta::generate() {
  GENERATESTART(8)

  SWITCHSTART
  CASESTART(0)
  opt_varying_ = new OptVarying();
  opt_varying_->generate();
  CASEEND
  CASESTART(1)
  opt_varying_ = new OptVarying();
  opt_varying_->generate();
  CASEEND
  CASESTART(2)
  CASEEND
  CASESTART(3)
  CASEEND
  CASESTART(4)
  opt_varying_ = new OptVarying();
  opt_varying_->generate();
  CASEEND
  CASESTART(5)
  opt_varying_ = new OptVarying();
  opt_varying_->generate();
  CASEEND
  CASESTART(6)
  opt_varying_ = new OptVarying();
  opt_varying_->generate();
  CASEEND
  CASESTART(7)
  int_literal_ = new IntLiteral();
  int_literal_->generate();
  CASEEND
  SWITCHEND

  GENERATEEND
}

IR *OptVarying::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  res = new IR(kOptVarying, OP3("VARYING", "", ""));
  CASEEND
  CASESTART(1)
  res = new IR(kOptVarying, string(""));
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptVarying::deep_delete() { delete this; };

void OptVarying::generate(){GENERATESTART(2)

                                SWITCHSTART CASESTART(0) CASEEND CASESTART(1)

                                    CASEEND SWITCHEND

                                        GENERATEEND}

IR *NumericType::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  res = new IR(kNumericType, OP3("INT", "", ""));
  CASEEND
  CASESTART(1)
  res = new IR(kNumericType, OP3("INTEGER", "", ""));
  CASEEND
  CASESTART(2)
  res = new IR(kNumericType, OP3("SMALLINT", "", ""));
  CASEEND
  CASESTART(3)
  res = new IR(kNumericType, OP3("BIGINT", "", ""));
  CASEEND
  CASESTART(4)
  res = new IR(kNumericType, OP3("REAL", "", ""));
  CASEEND
  CASESTART(5)
  res = new IR(kNumericType, OP3("FLOAT", "", ""));
  CASEEND
  CASESTART(6)
  res = new IR(kNumericType, OP3("DOUBLE PRECISION", "", ""));
  CASEEND
  CASESTART(7)
  res = new IR(kNumericType, OP3("DECIMAL", "", ""));
  CASEEND
  CASESTART(8)
  res = new IR(kNumericType, OP3("DEC", "", ""));
  CASEEND
  CASESTART(9)
  res = new IR(kNumericType, OP3("NUMERIC", "", ""));
  CASEEND
  CASESTART(10)
  res = new IR(kNumericType, OP3("BOOLEAN", "", ""));
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void NumericType::deep_delete() { delete this; };

void NumericType::generate(){
    GENERATESTART(11)

        SWITCHSTART CASESTART(0) CASEEND CASESTART(1) CASEEND CASESTART(2)
            CASEEND CASESTART(3) CASEEND CASESTART(4) CASEEND CASESTART(5)
                CASEEND CASESTART(6) CASEEND CASESTART(7) CASEEND CASESTART(8)
                    CASEEND CASESTART(9) CASEEND CASESTART(10) CASEEND SWITCHEND

                        GENERATEEND}

IR *OptTableConstraintList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(table_constraint_list_);
  res = new IR(kOptTableConstraintList, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(1)
  res = new IR(kOptTableConstraintList, string(""));
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptTableConstraintList::deep_delete() {
  SAFEDELETE(table_constraint_list_);
  delete this;
};

void OptTableConstraintList::generate() {
  GENERATESTART(2)

  SWITCHSTART
  CASESTART(0)
  table_constraint_list_ = new TableConstraintList();
  table_constraint_list_->generate();
  CASEEND
  CASESTART(1)

  CASEEND
  SWITCHEND

  GENERATEEND
}

IR *TableConstraintList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(table_constraint_);
  res = new IR(kTableConstraintList, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(table_constraint_);
  auto tmp2 = SAFETRANSLATE(table_constraint_list_);
  res = new IR(kTableConstraintList, OP3("", ",", ""), tmp1, tmp2);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void TableConstraintList::deep_delete() {
  SAFEDELETE(table_constraint_);
  SAFEDELETE(table_constraint_list_);
  delete this;
};

void TableConstraintList::generate() {
  GENERATESTART(200)

  SWITCHSTART
  CASESTART(0)
  table_constraint_ = new TableConstraint();
  table_constraint_->generate();
  CASEEND
  CASESTART(1)
  table_constraint_ = new TableConstraint();
  table_constraint_->generate();
  table_constraint_list_ = new TableConstraintList();
  table_constraint_list_->generate();
  CASEEND

default: {
  int tmp_case_idx = rand() % 1;
  switch (tmp_case_idx) {
    CASESTART(0)
    table_constraint_ = new TableConstraint();
    table_constraint_->generate();
    case_idx_ = 0;
    CASEEND
  }
}
}

GENERATEEND
}

IR *TableConstraint::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(constraint_name_);
  auto tmp2 = SAFETRANSLATE(indexed_column_list_);
  res = new IR(kTableConstraint, OP3("", "PRIMARY KEY (", ")"), tmp1, tmp2);
  CASEEND
  CASESTART(1)
  auto tmp1 = SAFETRANSLATE(constraint_name_);
  auto tmp2 = SAFETRANSLATE(indexed_column_list_);
  res = new IR(kTableConstraint, OP3("", "UNIQUE (", ")"), tmp1, tmp2);
  CASEEND
  CASESTART(2)
  auto tmp1 = SAFETRANSLATE(constraint_name_);
  auto tmp2 = SAFETRANSLATE(expr_);
  res = new IR(kTableConstraint, OP3("", "CHECK (", ")"), tmp1, tmp2);
  CASEEND
  CASESTART(3)
  auto tmp1 = SAFETRANSLATE(constraint_name_);
  auto tmp2 = SAFETRANSLATE(column_name_list_);
  auto tmp3 = SAFETRANSLATE(foreign_clause_);
  auto tmp4 = new IR(kUnknown, OP3("", "FOREIGN KEY (", ")"), tmp1, tmp2);
  PUSH(tmp4);
  res = new IR(kTableConstraint, OP3("", "", ""), tmp4, tmp3);
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void TableConstraint::deep_delete() {
  SAFEDELETE(expr_);
  SAFEDELETE(indexed_column_list_);
  SAFEDELETE(foreign_clause_);
  SAFEDELETE(constraint_name_);
  SAFEDELETE(column_name_list_);
  delete this;
};

void TableConstraint::generate() {
  GENERATESTART(4)

  SWITCHSTART
  CASESTART(0)
  constraint_name_ = new ConstraintName();
  constraint_name_->generate();
  indexed_column_list_ = new IndexedColumnList();
  indexed_column_list_->generate();
  CASEEND
  CASESTART(1)
  constraint_name_ = new ConstraintName();
  constraint_name_->generate();
  indexed_column_list_ = new IndexedColumnList();
  indexed_column_list_->generate();
  CASEEND
  CASESTART(2)
  constraint_name_ = new ConstraintName();
  constraint_name_->generate();
  expr_ = new Expr();
  expr_->generate();
  CASEEND
  CASESTART(3)
  constraint_name_ = new ConstraintName();
  constraint_name_->generate();
  column_name_list_ = new ColumnNameList();
  column_name_list_->generate();
  foreign_clause_ = new ForeignClause();
  foreign_clause_->generate();
  CASEEND
  SWITCHEND

  GENERATEEND
}


IR *OptNo::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  res = new IR(kOptNo, OP1("NO"));
  CASEEND
  CASESTART(1)
  res = new IR(kOptNo, OP0());
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptNo::deep_delete() {
  delete this;
};

void OptNo::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *OptNowait::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  res = new IR(kOptNowait, OP1("NOWAIT"));
  CASEEND
  CASESTART(1)
  res = new IR(kOptNowait, OP0());
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptNowait::deep_delete() {
  delete this;
};

void OptNowait::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *OptOwnedby::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  auto tmp1 = SAFETRANSLATE(role_name_);
  res = new IR(kOptOwnedby, OP1("OWNED BY"), tmp1);
  CASEEND
  CASESTART(1)
  res = new IR(kOptOwnedby, OP0());
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptOwnedby::deep_delete() {
  SAFEDELETE(role_name_);
  delete this;
};

void OptOwnedby::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *OnOffLiteral::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  res = new IR(kOnOffLiteral, OP1("ON"));
  CASEEND
  CASESTART(1)
  res = new IR(kOnOffLiteral, OP1("OFF"));
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OnOffLiteral::deep_delete() {
  delete this;
};

void OnOffLiteral::generate() {
  GENERATESTART(1)
  GENERATEEND
}



IR *OptConcurrently::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  CASESTART(0)
  res = new IR(kOptConcurrently, OP1("CONCURRENTLY"));
  CASEEND
  CASESTART(1)
  res = new IR(kOptConcurrently, OP0());
  CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptConcurrently::deep_delete() {
  delete this;
};

void OptConcurrently::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *OptIfNotExistIndex::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
      auto tmp1 = SAFETRANSLATE(opt_if_not_exist_);
      auto tmp2 = SAFETRANSLATE(index_name_);
      res = new IR(kOptIfNotExistIndex, OP3("", "", ""), tmp1, tmp2);
    CASEEND
    CASESTART(1)
      res = new IR(kOptIfNotExistIndex, OP0());
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptIfNotExistIndex::deep_delete() {
  SAFEDELETE(opt_if_not_exist_);
  SAFEDELETE(index_name_);
  delete this;
};

void OptIfNotExistIndex::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *OptOnly::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
      res = new IR(kOptOnly, OP3("ONLY", "", ""));
    CASEEND
    CASESTART(1)
      res = new IR(kOptOnly, OP0());
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptOnly::deep_delete() {
  delete this;
};

void OptOnly::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *OptUsingMethod::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
      auto tmp1 = SAFETRANSLATE(method_name_);
      res = new IR(kOptUsingMethod, OP3("USING", "", ""), tmp1);
    CASEEND
    CASESTART(1)
      res = new IR(kOptUsingMethod, OP0());
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptUsingMethod::deep_delete() {
  SAFEDELETE(method_name_);
  delete this;
};

void OptUsingMethod::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *MethodName::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(identifier_);
  res = new IR(kMethodName, OP3("", "", ""), tmp1);

  TRANSLATEEND
}

void MethodName::deep_delete() {
  SAFEDELETE(identifier_);
  delete this;
};

void MethodName::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *OptTablespace::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
      auto tmp1 = SAFETRANSLATE(tablespace_name_);
      res = new IR(kOptTablespace, OP3("TABLESPACE", "", ""), tmp1);
    CASEEND
    CASESTART(1)
      res = new IR(kOptTablespace, string(""));
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptTablespace::deep_delete() {
  SAFEDELETE(tablespace_name_);
  delete this;
};

void OptTablespace::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *OptWherePredicate::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
      auto tmp1 = SAFETRANSLATE(predicate_name_);
      res = new IR(kOptWherePredicate, OP3("WHERE", "", ""), tmp1);
    CASEEND
    CASESTART(1)
      res = new IR(kOptWherePredicate, string(""));
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptWherePredicate::deep_delete() {
  SAFEDELETE(predicate_name_);
  delete this;
};

void OptWherePredicate::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *PredicateName::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(identifier_);
  res = new IR(kPredicateName, OP3("", "", ""), tmp1);

  TRANSLATEEND
}

void PredicateName::deep_delete() {
  SAFEDELETE(identifier_);
  delete this;
};

void PredicateName::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *OptWithIndexStorageParameterList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
      auto tmp1 = SAFETRANSLATE(index_storage_parameter_list_);
      res = new IR(kOptWithIndexStorageParameterList, OP3("WITH (", ")", ""), tmp1);
    CASEEND
    CASESTART(1)
      res = new IR(kOptWithIndexStorageParameterList, string(""));
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptWithIndexStorageParameterList::deep_delete() {
  SAFEDELETE(index_storage_parameter_list_);
  delete this;
};

void OptWithIndexStorageParameterList::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *OptIncludeColumnNameList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
      auto tmp1 = SAFETRANSLATE(column_name_list_);
      res = new IR(kOptWithIndexStorageParameterList, OP3("INCLUDE (", "", ")"), tmp1);
    CASEEND
    CASESTART(1)
      res = new IR(kOptWithIndexStorageParameterList, string(""));
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptIncludeColumnNameList::deep_delete() {
  SAFEDELETE(column_name_list_);
  delete this;
};

void OptIncludeColumnNameList::generate() {
  GENERATESTART(1)
  GENERATEEND
}



IR *OptCollate::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
      auto tmp1 = SAFETRANSLATE(collation_name_);
      res = new IR(kOptCollate, OP3("COLLATE", "", ""), tmp1);
    CASEEND
    CASESTART(1)
      res = new IR(kOptCollate, string(""));
    CASEEND
  SWITCHEND


  TRANSLATEEND
}

void OptCollate::deep_delete() {
  SAFEDELETE(collation_name_);
  delete this;
};

void OptCollate::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *CollationName::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(identifier_);
  res = new IR(kCollationName, OP3("", "", ""), tmp1);

  TRANSLATEEND
}

void CollationName::deep_delete() {
  SAFEDELETE(identifier_);
  delete this;
};

void CollationName::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *OptColumnOrExpr::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
      auto tmp1 = SAFETRANSLATE(column_name_);
      res = new IR(kOptColumnOrExpr, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(1)
      auto tmp1 = SAFETRANSLATE(expr_);
      res = new IR(kOptColumnOrExpr, OP3("(", ")", ""), tmp1);
    CASEEND
    CASESTART(2)
      res = new IR(kOptColumnOrExpr, string(""));
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptColumnOrExpr::deep_delete() {
  SAFEDELETE(column_name_);
  SAFEDELETE(expr_);
  delete this;
};

void OptColumnOrExpr::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *IndexedCreateIndexRestStmtList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
      auto tmp1 = SAFETRANSLATE(create_index_rest_stmt_);
      res = new IR(kIndexedCreateIndexRestStmtList, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(1)
      auto tmp1 = SAFETRANSLATE(create_index_rest_stmt_);
      auto tmp2 = SAFETRANSLATE(indexed_create_index_rest_stmt_list_);
      res = new IR(kIndexedCreateIndexRestStmtList, OP3("", ",", ""), tmp1, tmp2);
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void IndexedCreateIndexRestStmtList::deep_delete() {
  SAFEDELETE(create_index_rest_stmt_);
  SAFEDELETE(indexed_create_index_rest_stmt_list_);
  delete this;
};

void IndexedCreateIndexRestStmtList::generate() {
  GENERATESTART(1)
  GENERATEEND
}




IR *CreateIndexRestStmt::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(opt_column_or_expr_);
  auto tmp2 = SAFETRANSLATE(opt_collate_);
  auto tmp3 = SAFETRANSLATE(opt_index_opclass_parameter_list_);
  auto tmp4 = SAFETRANSLATE(opt_order_behavior_);
  auto tmp5 = SAFETRANSLATE(opt_order_nulls_);
  res = new IR(kCreateIndexRestStmt, OP3("", "", ""), tmp1, tmp2);
  PUSH(res);
  res = new IR(kCreateIndexRestStmt, OP3("", "", ""), res, tmp3);
  PUSH(res);
  res = new IR(kCreateIndexRestStmt, OP3("", "", ""), res, tmp4);
  PUSH(res);
  res = new IR(kCreateIndexRestStmt, OP3("", "", ""), res, tmp5);

  TRANSLATEEND
}

void CreateIndexRestStmt::deep_delete() {
  SAFEDELETE(opt_column_or_expr_);
  SAFEDELETE(opt_collate_);
  SAFEDELETE(opt_index_opclass_parameter_list_);
  SAFEDELETE(opt_order_behavior_);
  SAFEDELETE(opt_order_nulls_);
  delete this;
};

void CreateIndexRestStmt::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *OptIndexOpclassParameterList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
      auto tmp1 = SAFETRANSLATE(opclass_name_);
      auto tmp2 = SAFETRANSLATE(opt_opclass_parameter_list_);
      res = new IR(kOptIndexOpclassParameterList, OP3("", "", ""), tmp1, tmp2);
    CASEEND
    CASESTART(1)
      res = new IR(kOptIndexOpclassParameterList, string(""));
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptIndexOpclassParameterList::deep_delete() {
  SAFEDELETE(opclass_name_);
  SAFEDELETE(opt_opclass_parameter_list_);
  delete this;
};

void OptIndexOpclassParameterList::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *OptOpclassParameterList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
      auto tmp1 = SAFETRANSLATE(index_opclass_parameter_list_);
      res = new IR(kOptOpclassParameterList, OP3("(", "", ")"), tmp1);
    CASEEND
    CASESTART(1)
      res = new IR(kOptOpclassParameterList, string(""));
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptOpclassParameterList::deep_delete() {
  SAFEDELETE(index_opclass_parameter_list_);
  delete this;
};

void OptOpclassParameterList::generate() {
  GENERATESTART(1)
  GENERATEEND
}



IR *IndexOpclassParameterList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
      auto tmp1 = SAFETRANSLATE(index_opclass_parameter_);
      res = new IR(kIndexOpclassParameterList, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(1)
      auto tmp1 = SAFETRANSLATE(index_opclass_parameter_);
      auto tmp2 = SAFETRANSLATE(index_opclass_parameter_list_);
      res = new IR(kIndexOpclassParameterList, OP3("", ",", ""), tmp1, tmp2);
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void IndexOpclassParameterList::deep_delete() {
  SAFEDELETE(index_opclass_parameter_list_);
  delete this;
};

void IndexOpclassParameterList::generate() {
  GENERATESTART(1)
  GENERATEEND
}



IR *IndexOpclassParameter::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(opclass_parameter_name_);
  auto tmp2 = SAFETRANSLATE(opclass_parameter_value_);
  res = new IR(kIndexOpclassParameter, OP3("", "=", ""), tmp1, tmp2);

  TRANSLATEEND
}

void IndexOpclassParameter::deep_delete() {
  SAFEDELETE(opclass_parameter_name_);
  SAFEDELETE(opclass_parameter_value_);
  delete this;
};

void IndexOpclassParameter::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *OpclassName::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(identifier_);
  res = new IR(kOpclassName, OP3("", "", ""), tmp1);

  TRANSLATEEND
}

void OpclassName::deep_delete() {
  SAFEDELETE(identifier_);
  delete this;
};

void OpclassName::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *OpclassParameterName::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(identifier_);
  res = new IR(kOpclassParameterName, OP3("", "", ""), tmp1);

  TRANSLATEEND
}

void OpclassParameterName::deep_delete() {
  SAFEDELETE(identifier_);
  delete this;
};

void OpclassParameterName::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *OpclassParameterValue::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(identifier_);
  res = new IR(kOpclassParameterValue, OP3("", "", ""), tmp1);

  TRANSLATEEND
}

void OpclassParameterValue::deep_delete() {
  SAFEDELETE(identifier_);
  delete this;
};

void OpclassParameterValue::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *OptIndexNameList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
      auto tmp1 = SAFETRANSLATE(index_name_list_);
      res = new IR(kOptIndexNameList, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(1)
      res = new IR(kOptIndexNameList, string(""));
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptIndexNameList::deep_delete() {
  SAFEDELETE(index_name_list_);
  delete this;
};

void OptIndexNameList::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *IndexNameList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
      auto tmp1 = SAFETRANSLATE(index_name_);
      res = new IR(kIndexNameList, OP3(",", "", ""), tmp1);
    CASEEND
    CASESTART(1)
      auto tmp1 = SAFETRANSLATE(index_name_list_);
      auto tmp2 = SAFETRANSLATE(index_name_);
      res = new IR(kIndexNameList, OP3("", ",", ""), tmp1, tmp2);
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void IndexNameList::deep_delete() {
  SAFEDELETE(index_name_);
  SAFEDELETE(index_name_list_);
  delete this;
};

void IndexNameList::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *OptCascadeRestrict::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
      res = new IR(kOptCascadeRestrict, OP3("CASCADE", "", ""));
    CASEEND
    CASESTART(1)
      res = new IR(kOptCascadeRestrict, OP3("RESTRICT", "", ""));
    CASEEND
    CASESTART(2)
      res = new IR(kOptCascadeRestrict, string(""));
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptCascadeRestrict::deep_delete() {
  delete this;
};

void OptCascadeRestrict::generate() {
  GENERATESTART(1)
  GENERATEEND
}



IR *RoleSpecification::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
      auto tmp1 = SAFETRANSLATE(role_name_);
      res = new IR(kRoleSpecification, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(1)
      res = new IR(kRoleSpecification, OP1("CURRENT_USER"));
    CASEEND
    CASESTART(2)
      res = new IR(kRoleSpecification, OP1("SESSION_USER"));
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void RoleSpecification::deep_delete() {
  SAFEDELETE(role_name_);
  delete this;
};

void RoleSpecification::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *UserName::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(identifier_);
  res = new IR(kUserName, OP3("", "", ""), tmp1);

  TRANSLATEEND
}

void UserName::deep_delete() {
  SAFEDELETE(identifier_);
  delete this;
};

void UserName::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *UserNameList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
      auto tmp1 = SAFETRANSLATE(user_name_);
      res = new IR(kUserNameList, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(1)
      auto tmp1 = SAFETRANSLATE(user_name_);
      auto tmp2 = SAFETRANSLATE(user_name_list_);
      res = new IR(kUserNameList, OP3("", ",", ""), tmp1, tmp2);
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void UserNameList::deep_delete() {
  SAFEDELETE(user_name_);
  SAFEDELETE(user_name_list_);
  delete this;
};

void UserNameList::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *GroupName::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(identifier_);
  res = new IR(kGroupName, OP3("", "", ""), tmp1);

  TRANSLATEEND
}

void GroupName::deep_delete() {
  SAFEDELETE(identifier_);
  delete this;
};

void GroupName::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *DropGroupStmt::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(opt_if_exist_);
  auto tmp2 = SAFETRANSLATE(group_name_list_);
  res = new IR(kDropGroupStmt, OP3("DROP GROUP", "", ""), tmp1, tmp2);

  TRANSLATEEND
}

void DropGroupStmt::deep_delete() {
  SAFEDELETE(opt_if_exist_);
  SAFEDELETE(group_name_list_);
  delete this;
};

void DropGroupStmt::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *GroupNameList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
      auto tmp1 = SAFETRANSLATE(group_name_);
      res = new IR(kGroupNameList, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(1)
      auto tmp1 = SAFETRANSLATE(group_name_);
      auto tmp2 = SAFETRANSLATE(group_name_list_);
      res = new IR(kGroupNameList, OP3("", ",", ""), tmp1, tmp2);
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void GroupNameList::deep_delete() {
  SAFEDELETE(group_name_);
  SAFEDELETE(group_name_list_);
  delete this;
};

void GroupNameList::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *ValuesStmt::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(expr_list_with_parens_);
  res = new IR(kValuesStmt, OP3("VALUES", "", ""), tmp1);

  TRANSLATEEND
}

void ValuesStmt::deep_delete() {
  SAFEDELETE(expr_list_with_parens_);
  delete this;
};

void ValuesStmt::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *ExprListWithParens::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(expr_list_);
    res = new IR(kExprListWithParens, OP3("(", ")", ""), tmp1);
    CASEEND
    CASESTART(1)
    auto tmp1 = SAFETRANSLATE(expr_list_);
    auto tmp2 = SAFETRANSLATE(expr_list_with_parens_);
    res = new IR(kExprListWithParens, OP3("(", ") ,", ""), tmp1, tmp2);
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void ExprListWithParens::deep_delete() {
  SAFEDELETE(expr_list_);
  SAFEDELETE(expr_list_with_parens_);
  delete this;
};

void ExprListWithParens::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *AlterViewStmt::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(opt_if_exist_);
  auto tmp2 = SAFETRANSLATE(view_name_);
  auto tmp3 = SAFETRANSLATE(alter_view_action_);
  res = new IR(kAlterViewStmt, OP3("ALTER VIEW", "", ""), tmp1, tmp2);
  PUSH(res);
  res = new IR(kAlterViewStmt, OP3("", "", ""), res, tmp3);

  TRANSLATEEND
}

void AlterViewStmt::deep_delete() {
  SAFEDELETE(opt_if_exist_);
  SAFEDELETE(view_name_);
  SAFEDELETE(alter_view_action_);
  delete this;
};

void AlterViewStmt::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *AlterViewAction::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(opt_column_);
    auto tmp2 = SAFETRANSLATE(column_name_);
    auto tmp3 = SAFETRANSLATE(expr_);
    res = new IR(kAlterViewAction, OP3("ALTER", "", "SET DEFAULT"), tmp1, tmp2);
  PUSH(res);
    res = new IR(kAlterViewAction, OP3("", "", ""), res, tmp3);
    CASEEND
    CASESTART(1)
    auto tmp1 = SAFETRANSLATE(opt_column_);
    auto tmp2 = SAFETRANSLATE(column_name_);
    res = new IR(kAlterViewAction, OP3("ALTER", "", "DROP DEFAULT"), tmp1, tmp2);
    CASEEND
    CASESTART(2)
    auto tmp1 = SAFETRANSLATE(owner_specification_);
    res = new IR(kAlterViewAction, OP3("OWNER TO ", "", ""), tmp1);
    CASEEND
    CASESTART(3)
      auto tmp1 = SAFETRANSLATE(opt_column_);
      auto tmp2 = SAFETRANSLATE(column_name_0_);
      auto tmp3 = SAFETRANSLATE(column_name_1_);

      res = new IR(kAlterViewAction, OP3("RENAME", "", "TO"), tmp1, tmp2);
  PUSH(res);
      res = new IR(kAlterViewAction, OP3("", "", ""), res, tmp3);
    CASEEND
    CASESTART(4)
      auto tmp1 = SAFETRANSLATE(view_name_);
      res = new IR(kAlterViewAction, OP3("RENAME TO", "", ""), tmp1);
    CASEEND
    CASESTART(5)
      auto tmp1 = SAFETRANSLATE(schema_name_);
      res = new IR(kAlterViewAction, OP3("SET SCHEMA", "", ""), tmp1);
    CASEEND
    CASESTART(6)
      auto tmp1 = SAFETRANSLATE(index_opt_view_option_list_);
      res = new IR(kAlterViewAction, OP3("SET (", ")", ""), tmp1);
    CASEEND
    CASESTART(7)
      auto tmp1 = SAFETRANSLATE(view_option_name_list_);
      res = new IR(kAlterViewAction, OP3("RESET (", ")", ""), tmp1);
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void AlterViewAction::deep_delete() {
  SAFEDELETE(opt_column_);
  SAFEDELETE(expr_);
  SAFEDELETE(owner_specification_);
  SAFEDELETE(column_name_0_);
  SAFEDELETE(column_name_1_);
  SAFEDELETE(view_name_);
  SAFEDELETE(schema_name_);
  SAFEDELETE(index_opt_view_option_list_);
  SAFEDELETE(view_option_name_list_);

  delete this;
};

void AlterViewAction::generate() {
  GENERATESTART(1)
  GENERATEEND
};

IR *OwnerSpecification::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(user_name_);
    res = new IR(kOwnerSpecification, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(1)
    res = new IR(kOwnerSpecification, OP1("CURRENT_USER"));
    CASEEND
    CASESTART(2)
    res = new IR(kOwnerSpecification, OP1("SESSION_USER"));
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OwnerSpecification::deep_delete() {
  SAFEDELETE(user_name_);
  delete this;
};

void OwnerSpecification::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *SchemaName::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

    auto tmp1 = SAFETRANSLATE(identifier_);
    res = new IR(kSchemaName, OP3("", "", ""), tmp1);

  TRANSLATEEND
}

void SchemaName::deep_delete() {
  SAFEDELETE(identifier_);
  delete this;
};

void SchemaName::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *IndexOptViewOptionList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(index_opt_view_option_);
    res = new IR(kIndexOptViewOptionList, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(1)
    auto tmp1 = SAFETRANSLATE(index_opt_view_option_);
    auto tmp2 = SAFETRANSLATE(index_opt_view_option_list_);
    res = new IR(kIndexOptViewOptionList, OP3("", ",", ""), tmp1, tmp2);
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void IndexOptViewOptionList::deep_delete() {
  SAFEDELETE(index_opt_view_option_);
  SAFEDELETE(index_opt_view_option_list_);
  delete this;
};

void IndexOptViewOptionList::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *IndexOptViewOption::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(view_option_name_);
  auto tmp2 = SAFETRANSLATE(opt_equal_view_option_value_);
  res = new IR(kIndexOptViewOption, OP3("", "", ""), tmp1, tmp2);

  TRANSLATEEND
}

void IndexOptViewOption::deep_delete() {
  SAFEDELETE(view_option_name_);
  SAFEDELETE(opt_equal_view_option_value_);
  delete this;
};

void IndexOptViewOption::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *OptEqualViewOptionValue::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(view_option_value_);
    res = new IR(kOptEqualViewOptionValue, OP3("=", "", ""), tmp1);
    CASEEND
    CASESTART(1)
    res = new IR(kOptEqualViewOptionValue, string(""));
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptEqualViewOptionValue::deep_delete() {
  SAFEDELETE(view_option_value_);
  delete this;
};

void OptEqualViewOptionValue::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *ViewOptionName::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(identifier_);
  res = new IR(kViewOptionName, OP3("", "", ""), tmp1);

  TRANSLATEEND
}

void ViewOptionName::deep_delete() {
  SAFEDELETE(identifier_);
  delete this;
};

void ViewOptionName::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *ViewOptionValue::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(identifier_);
  res = new IR(kViewOptionValue, OP3("", "", ""), tmp1);

  TRANSLATEEND
}

void ViewOptionValue::deep_delete() {
  SAFEDELETE(identifier_);
  delete this;
};

void ViewOptionValue::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *ViewOptionNameList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(view_option_name_);
    res = new IR(kViewOptionNameList, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(1)
    auto tmp1 = SAFETRANSLATE(view_option_name_);
    auto tmp2 = SAFETRANSLATE(view_option_name_list_);
    res = new IR(kViewOptionNameList, OP3("", "", ""), tmp1, tmp2);
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void ViewOptionNameList::deep_delete() {
  SAFEDELETE(view_option_name_);
  SAFEDELETE(view_option_name_list_);
  delete this;
};

void ViewOptionNameList::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *OptReindexOptionList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(reindex_option_list_);
    res = new IR(kOptReindexOptionList, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(1)
    res = new IR(kOptReindexOptionList, string(""));
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptReindexOptionList::deep_delete() {
  SAFEDELETE(reindex_option_list_);
  delete this;
};

void OptReindexOptionList::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *ReindexOptionList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(reindex_option_);
    res = new IR(kReindexOptionList, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(1)
    auto tmp1 = SAFETRANSLATE(reindex_option_);
    auto tmp2 = SAFETRANSLATE(reindex_option_list_);
    res = new IR(kReindexOptionList, OP3("", ",", ""), tmp1, tmp2);
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void ReindexOptionList::deep_delete() {
  SAFEDELETE(reindex_option_);
  SAFEDELETE(reindex_option_list_);
  delete this;
};

void ReindexOptionList::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *ReindexOption::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    res = new IR(kReindexOption, OP1("VERBOSE"));
    CASEEND
    CASESTART(1)
    res = new IR(kReindexOption, string(""));
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void ReindexOption::deep_delete() {
  delete this;
};

void ReindexOption::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *DatabaseName::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART
  auto tmp1 = SAFETRANSLATE(identifier_);
  res = new IR(kDatabaseName, OP3("", "", ""), tmp1);
  TRANSLATEEND
}

void DatabaseName::deep_delete() {
  SAFEDELETE(identifier_);
  delete this;
};

void DatabaseName::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *SystemName::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART
  auto tmp1 = SAFETRANSLATE(identifier_);
  res = new IR(kSystemName, OP3("", "", ""), tmp1);
  TRANSLATEEND
}

void SystemName::deep_delete() {
  SAFEDELETE(identifier_);
  delete this;
};

void SystemName::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *CreateGroupStmt::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(group_name_);
  auto tmp2 = SAFETRANSLATE(opt_with_option_list_);
  res = new IR(kCreateGroupStmt, OP3("CREATE GROUP", "", ""), tmp1, tmp2);

  TRANSLATEEND
}

void CreateGroupStmt::deep_delete() {
  SAFEDELETE(group_name_);
  SAFEDELETE(opt_with_option_list_);
  delete this;
};

void CreateGroupStmt::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *OptWithOptionList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(opt_with_);
    auto tmp2 = SAFETRANSLATE(option_list_);
    res = new IR(kOptWithOptionList, OP3("", "", ""), tmp1, tmp2);
    CASEEND
    CASESTART(1)
    res = new IR(kOptWithOptionList, string(""));
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptWithOptionList::deep_delete() {
  SAFEDELETE(opt_with_);
  SAFEDELETE(option_list_);
  delete this;
};

void OptWithOptionList::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *OptionList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(option_);
    res = new IR(kOptionList, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(1)
    auto tmp1 = SAFETRANSLATE(option_);
    auto tmp2 = SAFETRANSLATE(option_list_);
    res = new IR(kOptionList, OP3("", "", ""), tmp1, tmp2);
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptionList::deep_delete() {
  SAFEDELETE(option_);
  SAFEDELETE(option_list_);
  delete this;
};

void OptionList::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *Option::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART

  case CASE0:
  case CASE1:
  case CASE2:
  case CASE3:
  case CASE4:
  case CASE5:
  case CASE6:
  case CASE7:
  case CASE8:
  case CASE9:
  case CASE10:
  case CASE11:
  case CASE12:
  case CASE13:
  case CASE16: {
    res = new IR(kOption, string(""));
    CASEEND
  case CASE14:
  case CASE23: {
    auto tmp1 = SAFETRANSLATE(int_literal_);
    res = new IR(kOption, OP3("", "", ""), tmp1);
  CASEEND
  CASESTART(15)
  auto tmp1 = SAFETRANSLATE(opt_encrypted_);
  auto tmp2 = SAFETRANSLATE(string_literal_);
  res = new IR(kOption, OP3("", "", ""), tmp1, tmp2);
  CASEEND
  CASESTART(17)
  auto tmp1 = SAFETRANSLATE(string_literal_);
  res = new IR(kOption, OP3("", "", ""), tmp1);
  CASEEND
case CASE18:
case CASE19:
case CASE20:
case CASE21:
case CASE22: {
    auto tmp1 = SAFETRANSLATE(role_name_list_);
    res = new IR(kOption, OP3("", "", ""), tmp1);
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void Option::deep_delete() {
  SAFEDELETE(int_literal_);
  SAFEDELETE(opt_encrypted_);
  SAFEDELETE(string_literal_);
  SAFEDELETE(role_name_list_);
  delete this;
};

void Option::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *RoleNameList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(role_name_);
    res = new IR(kRoleNameList, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(1)
    auto tmp1 = SAFETRANSLATE(role_name_);
    auto tmp2 = SAFETRANSLATE(role_name_list_);
    res = new IR(kRoleNameList, OP3("", ",", ""), tmp1, tmp2);
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void RoleNameList::deep_delete() {
  SAFEDELETE(role_name_);
  SAFEDELETE(role_name_list_);
  delete this;
};

void RoleNameList::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *OptWith::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    res = new IR(kOptWith, OP1("ENCRYPTED"));
    CASEEND
    CASESTART(1)
    res = new IR(kOptWith, string(""));
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptWith::deep_delete() {
  delete this;
};

void OptWith::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *OptEncrypted::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    res = new IR(kOptEncrypted, OP1("ENCRYPTED"));
    CASEEND
    CASESTART(1)
    res = new IR(kOptEncrypted, string(""));
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptEncrypted::deep_delete() {
  delete this;
};

void OptEncrypted::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *ViewNameList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(view_name_);
    res = new IR(kViewNameList, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(1)
    auto tmp1 = SAFETRANSLATE(view_name_);
    auto tmp2 = SAFETRANSLATE(view_name_list_);
    res = new IR(kViewNameList, OP3("", "", ""), tmp1, tmp2);
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void ViewNameList::deep_delete() {
  SAFEDELETE(view_name_);
  SAFEDELETE(view_name_list_);
  delete this;
};

void ViewNameList::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *OptOrReplace::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    res = new IR(kOptOrReplace, OP1("OR REPLACE"));
    CASEEND
    CASESTART(1)
    res = new IR(kOptOrReplace, string(""));
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptOrReplace::deep_delete() {
  delete this;
};

void OptOrReplace::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *OptTempToken::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    res = new IR(kOptTempToken, OP1("TEMPORARY"));
    CASEEND
    CASESTART(1)
    res = new IR(kOptTempToken, OP1("TEMP"));
    CASEEND
    CASESTART(2)
    res = new IR(kOptTempToken, string(""));
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptTempToken::deep_delete() {
  delete this;
};

void OptTempToken::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *OptRecursive::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    res = new IR(kOptRecursive, OP1("RECURSIVE"));
    CASEEND
    CASESTART(1)
    res = new IR(kOptRecursive, string(""));
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptRecursive::deep_delete() {
  delete this;
};

void OptRecursive::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *OptWithViewOptionList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(index_opt_view_option_list_);
    res = new IR(kOptWithViewOptionList, OP3("WITH (", ")", ""), tmp1);
    CASEEND
    CASESTART(1)
    res = new IR(kOptWithViewOptionList, string(""));
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptWithViewOptionList::deep_delete() {
  SAFEDELETE(index_opt_view_option_list_);
  delete this;
};

void OptWithViewOptionList::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *CreateTableAsStmt::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(opt_temp_);
  auto tmp2 = SAFETRANSLATE(opt_if_not_exist_);
  auto tmp3 = SAFETRANSLATE(create_as_target_);
  auto tmp4 = SAFETRANSLATE(select_stmt_);
  auto tmp5 = SAFETRANSLATE(opt_with_data_);
  res = new IR(kCreateTableAsStmt, OP3("CREATE", "TABLE", ""), tmp1, tmp2);
  PUSH(res);
  res = new IR(kCreateTableAsStmt, OP3("", "", "AS"), res, tmp3);
  PUSH(res);
  res = new IR(kCreateTableAsStmt, OP3("", "", ""), res, tmp4);
  PUSH(res);
  res = new IR(kCreateTableAsStmt, OP3("", "", ""), res, tmp5);

  TRANSLATEEND
}

void CreateTableAsStmt::deep_delete() {
  SAFEDELETE(opt_temp_);
  SAFEDELETE(opt_if_not_exist_);
  SAFEDELETE(create_as_target_);
  SAFEDELETE(select_stmt_);
  SAFEDELETE(opt_with_data_);
  delete this;
};

void CreateTableAsStmt::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *CreateAsTarget::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(table_name_);
  auto tmp2 = SAFETRANSLATE(opt_column_name_list_p_);
  auto tmp3 = SAFETRANSLATE(table_access_method_clause_);
  auto tmp4 = SAFETRANSLATE(opt_with_storage_parameter_list_);
  auto tmp5 = SAFETRANSLATE(on_commit_option_);
  auto tmp6 = SAFETRANSLATE(opt_table_space_);
  res = new IR(kCreateAsTarget, OP3("", "", ""), tmp1, tmp2);
  PUSH(res);
  res = new IR(kCreateAsTarget, OP3("", "", ""), res, tmp3);
  PUSH(res);
  res = new IR(kCreateAsTarget, OP3("", "", ""), res, tmp4);
  PUSH(res);
  res = new IR(kCreateAsTarget, OP3("", "", ""), res, tmp5);
  PUSH(res);
  res = new IR(kCreateAsTarget, OP3("", "", ""), res, tmp6);

  TRANSLATEEND
}

void CreateAsTarget::deep_delete() {
  SAFEDELETE(table_name_);
  SAFEDELETE(opt_column_name_list_p_);
  SAFEDELETE(table_access_method_clause_);
  SAFEDELETE(opt_with_storage_parameter_list_);
  SAFEDELETE(on_commit_option_);
  SAFEDELETE(opt_table_space_);
  delete this;
};

void CreateAsTarget::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *TableAccessMethodClause::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(method_name_);
    res = new IR(kTableAccessMethodClause, OP3("USING", "", ""), tmp1);
    CASEEND
    CASESTART(1)
    res = new IR(kTableAccessMethodClause, string(""));
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void TableAccessMethodClause::deep_delete() {
  SAFEDELETE(method_name_);
  delete this;
};

void TableAccessMethodClause::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *OptWithStorageParameterList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(index_storage_parameter_list_);
    res = new IR(kOptWithStorageParameterList, OP3("WITH", "", ""), tmp1);
    CASEEND
    CASESTART(1)
    res = new IR(kOptWithStorageParameterList, OP3("WITHOUT OIDS", "", ""));
    CASEEND
    CASESTART(2)
    res = new IR(kOptWithStorageParameterList, string(""));
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptWithStorageParameterList::deep_delete() {
  SAFEDELETE(index_storage_parameter_list_);
  delete this;
};

void OptWithStorageParameterList::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *OnCommitOption::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    res = new IR(kOnCommitOption, OP3("ON COMMIT DROP", "", ""));
    CASEEND
    CASESTART(1)
    res = new IR(kOnCommitOption, OP3("ON COMMIT DELETE ROWS", "", ""));
    CASEEND
    CASESTART(2)
    res = new IR(kOnCommitOption, OP3("ON COMMIT PRESERVE ROWS", "", ""));
    CASEEND
    CASESTART(3)
    res = new IR(kOnCommitOption, string(""));
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OnCommitOption::deep_delete() {
  delete this;
};

void OnCommitOption::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *OptWithData::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    res = new IR(kOptWithData, OP3("WITH DATA", "", ""));
    CASEEND
    CASESTART(1)
    res = new IR(kOptWithData, OP3("WITH NO DATA", "", ""));
    CASEEND
    CASESTART(2)
    res = new IR(kOptWithData, string(""));
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptWithData::deep_delete() {
  delete this;
};

void OptWithData::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *AlterTblspcStmt::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(tablespace_name_0_);
    auto tmp2 = SAFETRANSLATE(tablespace_name_1_);
    res = new IR(kAlterTblspcStmt, OP3("ALTER TABLESPACE", "RENAME TO", ""), tmp1, tmp2);
    CASEEND
    CASESTART(1)
    auto tmp1 = SAFETRANSLATE(tablespace_name_);
    auto tmp2 = SAFETRANSLATE(owner_specification_);
    res = new IR(kAlterTblspcStmt, OP3("ALTER TABLESPACE", "OWNER TO", ""), tmp1, tmp2);
    CASEEND
    CASESTART(2)
      auto tmp1 = SAFETRANSLATE(tablespace_name_);
      auto tmp2 = SAFETRANSLATE(index_opt_tablespace_option_list_);
      res = new IR(kAlterTblspcStmt, OP3("ALTER TABLESPACE", "SET (", ")"), tmp1, tmp2);
    CASEEND
    CASESTART(3)
      auto tmp1 = SAFETRANSLATE(tablespace_name_);
      auto tmp2 = SAFETRANSLATE(index_opt_tablespace_option_list_);
      res = new IR(kAlterTblspcStmt, OP3("ALTER TABLESPACE", "RESET (", ")"), tmp1, tmp2);
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void AlterTblspcStmt::deep_delete() {
  SAFEDELETE(tablespace_name_0_);
  SAFEDELETE(tablespace_name_1_);
  SAFEDELETE(tablespace_name_);
  SAFEDELETE(owner_specification_);
  SAFEDELETE(index_opt_tablespace_option_list_);
  delete this;
};

void AlterTblspcStmt::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *IndexOptTablespaceOptionList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(index_opt_tablespace_option_);
    res = new IR(kIndexOptTablespaceOptionList, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(1)
    auto tmp1 = SAFETRANSLATE(index_opt_tablespace_option_);
    auto tmp2 = SAFETRANSLATE(index_opt_tablespace_option_list_);
    res = new IR(kIndexOptTablespaceOptionList, OP3("", ",", ""), tmp1, tmp2);
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void IndexOptTablespaceOptionList::deep_delete() {
  SAFEDELETE(index_opt_tablespace_option_);
  SAFEDELETE(index_opt_tablespace_option_list_);
  delete this;
};

void IndexOptTablespaceOptionList::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *IndexOptTablespaceOption::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART


  auto tmp1 = SAFETRANSLATE(tablespace_option_name_);
  auto tmp2 = SAFETRANSLATE(opt_equal_tablespace_option_value_);
  res = new IR(kIndexOptTablespaceOption, OP3("", "", ""), tmp1, tmp2);


  TRANSLATEEND
}

void IndexOptTablespaceOption::deep_delete() {
  SAFEDELETE(tablespace_option_name_);
  SAFEDELETE(opt_equal_tablespace_option_value_);
  delete this;
};

void IndexOptTablespaceOption::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *OptEqualTablespaceOptionValue::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(tablespace_option_value_);
    res = new IR(kOptEqualTablespaceOptionValue, OP3("=", "", ""), tmp1);
    CASEEND
    CASESTART(1)
    res = new IR(kOptEqualTablespaceOptionValue, string(""));
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptEqualTablespaceOptionValue::deep_delete() {
  SAFEDELETE(tablespace_option_value_);
  delete this;
};

void OptEqualTablespaceOptionValue::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *TablespaceOptionName::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(identifier_);
  res = new IR(kTablespaceOptionName, OP3("", "", ""), tmp1);

  TRANSLATEEND
}

void TablespaceOptionName::deep_delete() {
  SAFEDELETE(identifier_);
  delete this;
};

void TablespaceOptionName::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *TablespaceOptionValue::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(identifier_);
  res = new IR(kTablespaceOptionValue, OP3("", "", ""), tmp1);

  TRANSLATEEND
}

void TablespaceOptionValue::deep_delete() {
  SAFEDELETE(identifier_);
  delete this;
};

void TablespaceOptionValue::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *AlterConversionStmt::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(conversion_name_0_);
    auto tmp2 = SAFETRANSLATE(conversion_name_1_);
    res = new IR(kAlterConversionStmt, OP3("ALTER CONVERSION", "RENAME TO", ""), tmp1, tmp2);
    CASEEND
    CASESTART(1)
    auto tmp1 = SAFETRANSLATE(conversion_name_);
    auto tmp2 = SAFETRANSLATE(owner_specification_);
    res = new IR(kAlterConversionStmt, OP3("ALTER CONVERSION", "OWNER TO", ""), tmp1, tmp2);
    CASEEND
    CASESTART(2)
    auto tmp1 = SAFETRANSLATE(conversion_name_);
    auto tmp2 = SAFETRANSLATE(schema_name_);
    res = new IR(kAlterConversionStmt, OP3("ALTER CONVERSION", "SET SCHEMA", ""), tmp1, tmp2);
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void AlterConversionStmt::deep_delete() {
  SAFEDELETE(conversion_name_0_);
  SAFEDELETE(conversion_name_1_);
  SAFEDELETE(conversion_name_);
  SAFEDELETE(owner_specification_);
  SAFEDELETE(schema_name_);
  delete this;
};

void AlterConversionStmt::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *ConversionName::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  auto tmp1 = SAFETRANSLATE(identifier_);
  res = new IR(kConversionName, OP3("", "", ""), tmp1);

  TRANSLATEEND
}

void ConversionName::deep_delete() {
  SAFEDELETE(identifier_);
  delete this;
};

void ConversionName::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *UnreservedKeyword::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART

  CASESTART(0) res = new IR(kUnreservedKeyword, string("ABORT")); CASEEND
  CASESTART(1) res = new IR(kUnreservedKeyword, string("ABSOLUTE")); CASEEND
  CASESTART(2) res = new IR(kUnreservedKeyword, string("ACCESS")); CASEEND
  CASESTART(3) res = new IR(kUnreservedKeyword, string("ACTION")); CASEEND
  CASESTART(4) res = new IR(kUnreservedKeyword, string("ADD")); CASEEND
  CASESTART(5) res = new IR(kUnreservedKeyword, string("ADMIN")); CASEEND
  CASESTART(6) res = new IR(kUnreservedKeyword, string("AFTER")); CASEEND
  CASESTART(7) res = new IR(kUnreservedKeyword, string("AGGREGATE")); CASEEND
  CASESTART(8) res = new IR(kUnreservedKeyword, string("ALSO")); CASEEND
  CASESTART(9) res = new IR(kUnreservedKeyword, string("ALTER")); CASEEND
  CASESTART(10) res = new IR(kUnreservedKeyword, string("ALWAYS")); CASEEND
  CASESTART(11) res = new IR(kUnreservedKeyword, string("ASENSITIVE")); CASEEND
  CASESTART(12) res = new IR(kUnreservedKeyword, string("ASSERTION")); CASEEND
  CASESTART(13) res = new IR(kUnreservedKeyword, string("ASSIGNMENT")); CASEEND
  CASESTART(14) res = new IR(kUnreservedKeyword, string("AT")); CASEEND
  CASESTART(15) res = new IR(kUnreservedKeyword, string("ATOMIC")); CASEEND
  CASESTART(16) res = new IR(kUnreservedKeyword, string("ATTACH")); CASEEND
  CASESTART(17) res = new IR(kUnreservedKeyword, string("ATTRIBUTE")); CASEEND
  CASESTART(18) res = new IR(kUnreservedKeyword, string("BACKWARD")); CASEEND
  CASESTART(19) res = new IR(kUnreservedKeyword, string("BEFORE")); CASEEND
  CASESTART(20) res = new IR(kUnreservedKeyword, string("BEGIN")); CASEEND
  CASESTART(21) res = new IR(kUnreservedKeyword, string("BREADTH")); CASEEND
  CASESTART(22) res = new IR(kUnreservedKeyword, string("BY")); CASEEND
  CASESTART(23) res = new IR(kUnreservedKeyword, string("CACHE")); CASEEND
  CASESTART(24) res = new IR(kUnreservedKeyword, string("CALL")); CASEEND
  CASESTART(25) res = new IR(kUnreservedKeyword, string("CALLED")); CASEEND
  CASESTART(26) res = new IR(kUnreservedKeyword, string("CASCADE")); CASEEND
  CASESTART(27) res = new IR(kUnreservedKeyword, string("CASCADED")); CASEEND
  CASESTART(28) res = new IR(kUnreservedKeyword, string("CATALOG")); CASEEND
  CASESTART(29) res = new IR(kUnreservedKeyword, string("CHAIN")); CASEEND
  CASESTART(30) res = new IR(kUnreservedKeyword, string("CHARACTERISTICS")); CASEEND
  CASESTART(31) res = new IR(kUnreservedKeyword, string("CHECKPOINT")); CASEEND
  CASESTART(32) res = new IR(kUnreservedKeyword, string("CLASS")); CASEEND
  CASESTART(33) res = new IR(kUnreservedKeyword, string("CLOSE")); CASEEND
  CASESTART(34) res = new IR(kUnreservedKeyword, string("CLUSTER")); CASEEND
  CASESTART(35) res = new IR(kUnreservedKeyword, string("COLUMNS")); CASEEND
  CASESTART(36) res = new IR(kUnreservedKeyword, string("COMMENT")); CASEEND
  CASESTART(37) res = new IR(kUnreservedKeyword, string("COMMENTS")); CASEEND
  CASESTART(38) res = new IR(kUnreservedKeyword, string("COMMIT")); CASEEND
  CASESTART(39) res = new IR(kUnreservedKeyword, string("COMMITTED")); CASEEND
  CASESTART(40) res = new IR(kUnreservedKeyword, string("COMPRESSION")); CASEEND
  CASESTART(41) res = new IR(kUnreservedKeyword, string("CONFIGURATION")); CASEEND
  CASESTART(42) res = new IR(kUnreservedKeyword, string("CONFLICT")); CASEEND
  CASESTART(43) res = new IR(kUnreservedKeyword, string("CONNECTION")); CASEEND
  CASESTART(44) res = new IR(kUnreservedKeyword, string("CONSTRAINTS")); CASEEND
  CASESTART(45) res = new IR(kUnreservedKeyword, string("CONTENT")); CASEEND
  CASESTART(46) res = new IR(kUnreservedKeyword, string("CONTINUE")); CASEEND
  CASESTART(47) res = new IR(kUnreservedKeyword, string("CONVERSION")); CASEEND
  CASESTART(48) res = new IR(kUnreservedKeyword, string("COPY")); CASEEND
  CASESTART(49) res = new IR(kUnreservedKeyword, string("COST")); CASEEND
  CASESTART(50) res = new IR(kUnreservedKeyword, string("CSV")); CASEEND
  CASESTART(51) res = new IR(kUnreservedKeyword, string("CUBE")); CASEEND
  CASESTART(52) res = new IR(kUnreservedKeyword, string("CURRENT")); CASEEND
  CASESTART(53) res = new IR(kUnreservedKeyword, string("CURSOR")); CASEEND
  CASESTART(54) res = new IR(kUnreservedKeyword, string("CYCLE")); CASEEND
  CASESTART(55) res = new IR(kUnreservedKeyword, string("DATA")); CASEEND
  CASESTART(56) res = new IR(kUnreservedKeyword, string("DATABASE")); CASEEND
  CASESTART(57) res = new IR(kUnreservedKeyword, string("DAY")); CASEEND
  CASESTART(58) res = new IR(kUnreservedKeyword, string("DEALLOCATE")); CASEEND
  CASESTART(59) res = new IR(kUnreservedKeyword, string("DECLARE")); CASEEND
  CASESTART(60) res = new IR(kUnreservedKeyword, string("DEFAULTS")); CASEEND
  CASESTART(61) res = new IR(kUnreservedKeyword, string("DEFERRED")); CASEEND
  CASESTART(62) res = new IR(kUnreservedKeyword, string("DEFINER")); CASEEND
  CASESTART(63) res = new IR(kUnreservedKeyword, string("DELETE")); CASEEND
  CASESTART(64) res = new IR(kUnreservedKeyword, string("DELIMITER")); CASEEND
  CASESTART(65) res = new IR(kUnreservedKeyword, string("DELIMITERS")); CASEEND
  CASESTART(66) res = new IR(kUnreservedKeyword, string("DEPENDS")); CASEEND
  CASESTART(67) res = new IR(kUnreservedKeyword, string("DEPTH")); CASEEND
  CASESTART(68) res = new IR(kUnreservedKeyword, string("DETACH")); CASEEND
  CASESTART(69) res = new IR(kUnreservedKeyword, string("DICTIONARY")); CASEEND
  CASESTART(70) res = new IR(kUnreservedKeyword, string("DISABLE")); CASEEND
  CASESTART(71) res = new IR(kUnreservedKeyword, string("DISCARD")); CASEEND
  CASESTART(72) res = new IR(kUnreservedKeyword, string("DOCUMENT")); CASEEND
  CASESTART(73) res = new IR(kUnreservedKeyword, string("DOMAIN")); CASEEND
  CASESTART(74) res = new IR(kUnreservedKeyword, string("DOUBLE")); CASEEND
  CASESTART(75) res = new IR(kUnreservedKeyword, string("DROP")); CASEEND
  CASESTART(76) res = new IR(kUnreservedKeyword, string("EACH")); CASEEND
  CASESTART(77) res = new IR(kUnreservedKeyword, string("ENABLE")); CASEEND
  CASESTART(78) res = new IR(kUnreservedKeyword, string("ENCODING")); CASEEND
  CASESTART(79) res = new IR(kUnreservedKeyword, string("ENCRYPTED")); CASEEND
  CASESTART(80) res = new IR(kUnreservedKeyword, string("ENUM")); CASEEND
  CASESTART(81) res = new IR(kUnreservedKeyword, string("ESCAPE")); CASEEND
  CASESTART(82) res = new IR(kUnreservedKeyword, string("EVENT")); CASEEND
  CASESTART(83) res = new IR(kUnreservedKeyword, string("EXCLUDE")); CASEEND
  CASESTART(84) res = new IR(kUnreservedKeyword, string("EXCLUDING")); CASEEND
  CASESTART(85) res = new IR(kUnreservedKeyword, string("EXCLUSIVE")); CASEEND
  CASESTART(86) res = new IR(kUnreservedKeyword, string("EXECUTE")); CASEEND
  CASESTART(87) res = new IR(kUnreservedKeyword, string("EXPLAIN")); CASEEND
  CASESTART(88) res = new IR(kUnreservedKeyword, string("EXPRESSION")); CASEEND
  CASESTART(89) res = new IR(kUnreservedKeyword, string("EXTENSION")); CASEEND
  CASESTART(90) res = new IR(kUnreservedKeyword, string("EXTERNAL")); CASEEND
  CASESTART(91) res = new IR(kUnreservedKeyword, string("FAMILY")); CASEEND
  CASESTART(92) res = new IR(kUnreservedKeyword, string("FILTER")); CASEEND
  CASESTART(93) res = new IR(kUnreservedKeyword, string("FINALIZE")); CASEEND
  CASESTART(94) res = new IR(kUnreservedKeyword, string("FIRST")); CASEEND
  CASESTART(95) res = new IR(kUnreservedKeyword, string("FOLLOWING")); CASEEND
  CASESTART(96) res = new IR(kUnreservedKeyword, string("FORCE")); CASEEND
  CASESTART(97) res = new IR(kUnreservedKeyword, string("FORWARD")); CASEEND
  CASESTART(98) res = new IR(kUnreservedKeyword, string("FUNCTION")); CASEEND
  CASESTART(99) res = new IR(kUnreservedKeyword, string("FUNCTIONS")); CASEEND
  CASESTART(100) res = new IR(kUnreservedKeyword, string("GENERATED")); CASEEND
  CASESTART(101) res = new IR(kUnreservedKeyword, string("GLOBAL")); CASEEND
  CASESTART(102) res = new IR(kUnreservedKeyword, string("GRANTED")); CASEEND
  CASESTART(103) res = new IR(kUnreservedKeyword, string("GROUPS")); CASEEND
  CASESTART(104) res = new IR(kUnreservedKeyword, string("HANDLER")); CASEEND
  CASESTART(105) res = new IR(kUnreservedKeyword, string("HEADER")); CASEEND
  CASESTART(106) res = new IR(kUnreservedKeyword, string("HOLD")); CASEEND
  CASESTART(107) res = new IR(kUnreservedKeyword, string("HOUR")); CASEEND
  CASESTART(108) res = new IR(kUnreservedKeyword, string("IDENTITY")); CASEEND
  CASESTART(109) res = new IR(kUnreservedKeyword, string("IF")); CASEEND
  CASESTART(110) res = new IR(kUnreservedKeyword, string("IMMEDIATE")); CASEEND
  CASESTART(111) res = new IR(kUnreservedKeyword, string("IMMUTABLE")); CASEEND
  CASESTART(112) res = new IR(kUnreservedKeyword, string("IMPLICIT")); CASEEND
  CASESTART(113) res = new IR(kUnreservedKeyword, string("IMPORT")); CASEEND
  CASESTART(114) res = new IR(kUnreservedKeyword, string("INCLUDE")); CASEEND
  CASESTART(115) res = new IR(kUnreservedKeyword, string("INCLUDING")); CASEEND
  CASESTART(116) res = new IR(kUnreservedKeyword, string("INCREMENT")); CASEEND
  CASESTART(117) res = new IR(kUnreservedKeyword, string("INDEX")); CASEEND
  CASESTART(118) res = new IR(kUnreservedKeyword, string("INDEXES")); CASEEND
  CASESTART(119) res = new IR(kUnreservedKeyword, string("INHERIT")); CASEEND
  CASESTART(120) res = new IR(kUnreservedKeyword, string("INHERITS")); CASEEND
  CASESTART(121) res = new IR(kUnreservedKeyword, string("INLINE")); CASEEND
  CASESTART(122) res = new IR(kUnreservedKeyword, string("INPUT")); CASEEND
  CASESTART(123) res = new IR(kUnreservedKeyword, string("INSENSITIVE")); CASEEND
  CASESTART(124) res = new IR(kUnreservedKeyword, string("INSERT")); CASEEND
  CASESTART(125) res = new IR(kUnreservedKeyword, string("INSTEAD")); CASEEND
  CASESTART(126) res = new IR(kUnreservedKeyword, string("INVOKER")); CASEEND
  CASESTART(127) res = new IR(kUnreservedKeyword, string("ISOLATION")); CASEEND
  CASESTART(128) res = new IR(kUnreservedKeyword, string("KEY")); CASEEND
  CASESTART(129) res = new IR(kUnreservedKeyword, string("LABEL")); CASEEND
  CASESTART(130) res = new IR(kUnreservedKeyword, string("LANGUAGE")); CASEEND
  CASESTART(131) res = new IR(kUnreservedKeyword, string("LARGE")); CASEEND
  CASESTART(132) res = new IR(kUnreservedKeyword, string("LAST")); CASEEND
  CASESTART(133) res = new IR(kUnreservedKeyword, string("LEAKPROOF")); CASEEND
  CASESTART(134) res = new IR(kUnreservedKeyword, string("LEVEL")); CASEEND
  CASESTART(135) res = new IR(kUnreservedKeyword, string("LISTEN")); CASEEND
  CASESTART(136) res = new IR(kUnreservedKeyword, string("LOAD")); CASEEND
  CASESTART(137) res = new IR(kUnreservedKeyword, string("LOCAL")); CASEEND
  CASESTART(138) res = new IR(kUnreservedKeyword, string("LOCATION")); CASEEND
  CASESTART(139) res = new IR(kUnreservedKeyword, string("LOCK")); CASEEND
  CASESTART(140) res = new IR(kUnreservedKeyword, string("LOCKED")); CASEEND
  CASESTART(141) res = new IR(kUnreservedKeyword, string("LOGGED")); CASEEND
  CASESTART(142) res = new IR(kUnreservedKeyword, string("MAPPING")); CASEEND
  CASESTART(143) res = new IR(kUnreservedKeyword, string("MATCH")); CASEEND
  CASESTART(144) res = new IR(kUnreservedKeyword, string("MATERIALIZED")); CASEEND
  CASESTART(145) res = new IR(kUnreservedKeyword, string("MAXVALUE")); CASEEND
  CASESTART(146) res = new IR(kUnreservedKeyword, string("METHOD")); CASEEND
  CASESTART(147) res = new IR(kUnreservedKeyword, string("MINUTE")); CASEEND
  CASESTART(148) res = new IR(kUnreservedKeyword, string("MINVALUE")); CASEEND
  CASESTART(149) res = new IR(kUnreservedKeyword, string("MODE")); CASEEND
  CASESTART(150) res = new IR(kUnreservedKeyword, string("MONTH")); CASEEND
  CASESTART(151) res = new IR(kUnreservedKeyword, string("MOVE")); CASEEND
  CASESTART(152) res = new IR(kUnreservedKeyword, string("NAME")); CASEEND
  CASESTART(153) res = new IR(kUnreservedKeyword, string("NAMES")); CASEEND
  CASESTART(154) res = new IR(kUnreservedKeyword, string("NEW")); CASEEND
  CASESTART(155) res = new IR(kUnreservedKeyword, string("NEXT")); CASEEND
  CASESTART(156) res = new IR(kUnreservedKeyword, string("NFC")); CASEEND
  CASESTART(157) res = new IR(kUnreservedKeyword, string("NFD")); CASEEND
  CASESTART(158) res = new IR(kUnreservedKeyword, string("NFKC")); CASEEND
  CASESTART(159) res = new IR(kUnreservedKeyword, string("NFKD")); CASEEND
  CASESTART(160) res = new IR(kUnreservedKeyword, string("NO")); CASEEND
  CASESTART(161) res = new IR(kUnreservedKeyword, string("NORMALIZED")); CASEEND
  CASESTART(162) res = new IR(kUnreservedKeyword, string("NOTHING")); CASEEND
  CASESTART(163) res = new IR(kUnreservedKeyword, string("NOTIFY")); CASEEND
  CASESTART(164) res = new IR(kUnreservedKeyword, string("NOWAIT")); CASEEND
  CASESTART(165) res = new IR(kUnreservedKeyword, string("NULLS")); CASEEND
  CASESTART(166) res = new IR(kUnreservedKeyword, string("OBJECT")); CASEEND
  CASESTART(167) res = new IR(kUnreservedKeyword, string("OF")); CASEEND
  CASESTART(168) res = new IR(kUnreservedKeyword, string("OFF")); CASEEND
  CASESTART(169) res = new IR(kUnreservedKeyword, string("OIDS")); CASEEND
  CASESTART(170) res = new IR(kUnreservedKeyword, string("OLD")); CASEEND
  CASESTART(171) res = new IR(kUnreservedKeyword, string("OPERATOR")); CASEEND
  CASESTART(172) res = new IR(kUnreservedKeyword, string("OPTION")); CASEEND
  CASESTART(173) res = new IR(kUnreservedKeyword, string("OPTIONS")); CASEEND
  CASESTART(174) res = new IR(kUnreservedKeyword, string("ORDINALITY")); CASEEND
  CASESTART(175) res = new IR(kUnreservedKeyword, string("OTHERS")); CASEEND
  CASESTART(176) res = new IR(kUnreservedKeyword, string("OVER")); CASEEND
  CASESTART(177) res = new IR(kUnreservedKeyword, string("OVERRIDING")); CASEEND
  CASESTART(178) res = new IR(kUnreservedKeyword, string("OWNED")); CASEEND
  CASESTART(179) res = new IR(kUnreservedKeyword, string("OWNER")); CASEEND
  CASESTART(180) res = new IR(kUnreservedKeyword, string("PARALLEL")); CASEEND
  CASESTART(181) res = new IR(kUnreservedKeyword, string("PARSER")); CASEEND
  CASESTART(182) res = new IR(kUnreservedKeyword, string("PARTIAL")); CASEEND
  CASESTART(183) res = new IR(kUnreservedKeyword, string("PARTITION")); CASEEND
  CASESTART(184) res = new IR(kUnreservedKeyword, string("PASSING")); CASEEND
  CASESTART(185) res = new IR(kUnreservedKeyword, string("PASSWORD")); CASEEND
  CASESTART(186) res = new IR(kUnreservedKeyword, string("PLANS")); CASEEND
  CASESTART(187) res = new IR(kUnreservedKeyword, string("POLICY")); CASEEND
  CASESTART(188) res = new IR(kUnreservedKeyword, string("PRECEDING")); CASEEND
  CASESTART(189) res = new IR(kUnreservedKeyword, string("PREPARE")); CASEEND
  CASESTART(190) res = new IR(kUnreservedKeyword, string("PREPARED")); CASEEND
  CASESTART(191) res = new IR(kUnreservedKeyword, string("PRESERVE")); CASEEND
  CASESTART(192) res = new IR(kUnreservedKeyword, string("PRIOR")); CASEEND
  CASESTART(193) res = new IR(kUnreservedKeyword, string("PRIVILEGES")); CASEEND
  CASESTART(194) res = new IR(kUnreservedKeyword, string("PROCEDURAL")); CASEEND
  CASESTART(195) res = new IR(kUnreservedKeyword, string("PROCEDURE")); CASEEND
  CASESTART(196) res = new IR(kUnreservedKeyword, string("PROCEDURES")); CASEEND
  CASESTART(197) res = new IR(kUnreservedKeyword, string("PROGRAM")); CASEEND
  CASESTART(198) res = new IR(kUnreservedKeyword, string("PUBLICATION")); CASEEND
  CASESTART(199) res = new IR(kUnreservedKeyword, string("QUOTE")); CASEEND
  CASESTART(200) res = new IR(kUnreservedKeyword, string("RANGE")); CASEEND
  CASESTART(201) res = new IR(kUnreservedKeyword, string("READ")); CASEEND
  CASESTART(202) res = new IR(kUnreservedKeyword, string("REASSIGN")); CASEEND
  CASESTART(203) res = new IR(kUnreservedKeyword, string("RECHECK")); CASEEND
  CASESTART(204) res = new IR(kUnreservedKeyword, string("RECURSIVE")); CASEEND
  CASESTART(205) res = new IR(kUnreservedKeyword, string("REF")); CASEEND
  CASESTART(206) res = new IR(kUnreservedKeyword, string("REFERENCING")); CASEEND
  CASESTART(207) res = new IR(kUnreservedKeyword, string("REFRESH")); CASEEND
  CASESTART(208) res = new IR(kUnreservedKeyword, string("REINDEX")); CASEEND
  CASESTART(209) res = new IR(kUnreservedKeyword, string("RELATIVE")); CASEEND
  CASESTART(210) res = new IR(kUnreservedKeyword, string("RELEASE")); CASEEND
  CASESTART(211) res = new IR(kUnreservedKeyword, string("RENAME")); CASEEND
  CASESTART(212) res = new IR(kUnreservedKeyword, string("REPEATABLE")); CASEEND
  CASESTART(213) res = new IR(kUnreservedKeyword, string("REPLACE")); CASEEND
  CASESTART(214) res = new IR(kUnreservedKeyword, string("REPLICA")); CASEEND
  CASESTART(215) res = new IR(kUnreservedKeyword, string("RESET")); CASEEND
  CASESTART(216) res = new IR(kUnreservedKeyword, string("RESTART")); CASEEND
  CASESTART(217) res = new IR(kUnreservedKeyword, string("RESTRICT")); CASEEND
  CASESTART(218) res = new IR(kUnreservedKeyword, string("RETURN")); CASEEND
  CASESTART(219) res = new IR(kUnreservedKeyword, string("RETURNS")); CASEEND
  CASESTART(220) res = new IR(kUnreservedKeyword, string("REVOKE")); CASEEND
  CASESTART(221) res = new IR(kUnreservedKeyword, string("ROLE")); CASEEND
  CASESTART(222) res = new IR(kUnreservedKeyword, string("ROLLBACK")); CASEEND
  CASESTART(223) res = new IR(kUnreservedKeyword, string("ROLLUP")); CASEEND
  CASESTART(224) res = new IR(kUnreservedKeyword, string("ROUTINE")); CASEEND
  CASESTART(225) res = new IR(kUnreservedKeyword, string("ROUTINES")); CASEEND
  CASESTART(226) res = new IR(kUnreservedKeyword, string("ROWS")); CASEEND
  CASESTART(227) res = new IR(kUnreservedKeyword, string("RULE")); CASEEND
  CASESTART(228) res = new IR(kUnreservedKeyword, string("SAVEPOINT")); CASEEND
  CASESTART(229) res = new IR(kUnreservedKeyword, string("SCHEMA")); CASEEND
  CASESTART(230) res = new IR(kUnreservedKeyword, string("SCHEMAS")); CASEEND
  CASESTART(231) res = new IR(kUnreservedKeyword, string("SCROLL")); CASEEND
  CASESTART(232) res = new IR(kUnreservedKeyword, string("SEARCH")); CASEEND
  CASESTART(233) res = new IR(kUnreservedKeyword, string("SECOND")); CASEEND
  CASESTART(234) res = new IR(kUnreservedKeyword, string("SECURITY")); CASEEND
  CASESTART(235) res = new IR(kUnreservedKeyword, string("SEQUENCE")); CASEEND
  CASESTART(236) res = new IR(kUnreservedKeyword, string("SEQUENCES")); CASEEND
  CASESTART(237) res = new IR(kUnreservedKeyword, string("SERIALIZABLE")); CASEEND
  CASESTART(238) res = new IR(kUnreservedKeyword, string("SERVER")); CASEEND
  CASESTART(239) res = new IR(kUnreservedKeyword, string("SESSION")); CASEEND
  CASESTART(240) res = new IR(kUnreservedKeyword, string("SET")); CASEEND
  CASESTART(241) res = new IR(kUnreservedKeyword, string("SETS")); CASEEND
  CASESTART(242) res = new IR(kUnreservedKeyword, string("SHARE")); CASEEND
  CASESTART(243) res = new IR(kUnreservedKeyword, string("SHOW")); CASEEND
  CASESTART(244) res = new IR(kUnreservedKeyword, string("SIMPLE")); CASEEND
  CASESTART(245) res = new IR(kUnreservedKeyword, string("SKIP")); CASEEND
  CASESTART(246) res = new IR(kUnreservedKeyword, string("SNAPSHOT")); CASEEND
  CASESTART(247) res = new IR(kUnreservedKeyword, string("SQL")); CASEEND
  CASESTART(248) res = new IR(kUnreservedKeyword, string("STABLE")); CASEEND
  CASESTART(249) res = new IR(kUnreservedKeyword, string("STANDALONE")); CASEEND
  CASESTART(250) res = new IR(kUnreservedKeyword, string("START")); CASEEND
  CASESTART(251) res = new IR(kUnreservedKeyword, string("STATEMENT")); CASEEND
  CASESTART(252) res = new IR(kUnreservedKeyword, string("STATISTICS")); CASEEND
  CASESTART(253) res = new IR(kUnreservedKeyword, string("STDIN")); CASEEND
  CASESTART(254) res = new IR(kUnreservedKeyword, string("STDOUT")); CASEEND
  CASESTART(255) res = new IR(kUnreservedKeyword, string("STORAGE")); CASEEND
  CASESTART(256) res = new IR(kUnreservedKeyword, string("STORED")); CASEEND
  CASESTART(257) res = new IR(kUnreservedKeyword, string("STRICT")); CASEEND
  CASESTART(258) res = new IR(kUnreservedKeyword, string("STRIP")); CASEEND
  CASESTART(259) res = new IR(kUnreservedKeyword, string("SUBSCRIPTION")); CASEEND
  CASESTART(260) res = new IR(kUnreservedKeyword, string("SUPPORT")); CASEEND
  CASESTART(261) res = new IR(kUnreservedKeyword, string("SYSID")); CASEEND
  CASESTART(262) res = new IR(kUnreservedKeyword, string("SYSTEM")); CASEEND
  CASESTART(263) res = new IR(kUnreservedKeyword, string("TABLES")); CASEEND
  CASESTART(264) res = new IR(kUnreservedKeyword, string("TABLESPACE")); CASEEND
  CASESTART(265) res = new IR(kUnreservedKeyword, string("TEMP")); CASEEND
  CASESTART(266) res = new IR(kUnreservedKeyword, string("TEMPLATE")); CASEEND
  CASESTART(267) res = new IR(kUnreservedKeyword, string("TEMPORARY")); CASEEND
  CASESTART(268) res = new IR(kUnreservedKeyword, string("TEXT")); CASEEND
  CASESTART(269) res = new IR(kUnreservedKeyword, string("TIES")); CASEEND
  CASESTART(270) res = new IR(kUnreservedKeyword, string("TRANSACTION")); CASEEND
  CASESTART(271) res = new IR(kUnreservedKeyword, string("TRANSFORM")); CASEEND
  CASESTART(272) res = new IR(kUnreservedKeyword, string("TRIGGER")); CASEEND
  CASESTART(273) res = new IR(kUnreservedKeyword, string("TRUNCATE")); CASEEND
  CASESTART(274) res = new IR(kUnreservedKeyword, string("TRUSTED")); CASEEND
  CASESTART(275) res = new IR(kUnreservedKeyword, string("TYPE")); CASEEND
  CASESTART(276) res = new IR(kUnreservedKeyword, string("TYPES")); CASEEND
  CASESTART(277) res = new IR(kUnreservedKeyword, string("UESCAPE")); CASEEND
  CASESTART(278) res = new IR(kUnreservedKeyword, string("UNBOUNDED")); CASEEND
  CASESTART(279) res = new IR(kUnreservedKeyword, string("UNCOMMITTED")); CASEEND
  CASESTART(280) res = new IR(kUnreservedKeyword, string("UNENCRYPTED")); CASEEND
  CASESTART(281) res = new IR(kUnreservedKeyword, string("UNKNOWN")); CASEEND
  CASESTART(282) res = new IR(kUnreservedKeyword, string("UNLISTEN")); CASEEND
  CASESTART(283) res = new IR(kUnreservedKeyword, string("UNLOGGED")); CASEEND
  CASESTART(284) res = new IR(kUnreservedKeyword, string("UNTIL")); CASEEND
  CASESTART(285) res = new IR(kUnreservedKeyword, string("UPDATE")); CASEEND
  CASESTART(286) res = new IR(kUnreservedKeyword, string("VACUUM")); CASEEND
  CASESTART(287) res = new IR(kUnreservedKeyword, string("VALID")); CASEEND
  CASESTART(288) res = new IR(kUnreservedKeyword, string("VALIDATE")); CASEEND
  CASESTART(289) res = new IR(kUnreservedKeyword, string("VALIDATOR")); CASEEND
  CASESTART(290) res = new IR(kUnreservedKeyword, string("VALUE")); CASEEND
  CASESTART(291) res = new IR(kUnreservedKeyword, string("VARYING")); CASEEND
  CASESTART(292) res = new IR(kUnreservedKeyword, string("VERSION")); CASEEND
  CASESTART(293) res = new IR(kUnreservedKeyword, string("VIEW")); CASEEND
  CASESTART(294) res = new IR(kUnreservedKeyword, string("VIEWS")); CASEEND
  CASESTART(295) res = new IR(kUnreservedKeyword, string("VOLATILE")); CASEEND
  CASESTART(296) res = new IR(kUnreservedKeyword, string("WHITESPACE")); CASEEND
  CASESTART(297) res = new IR(kUnreservedKeyword, string("WITHIN")); CASEEND
  CASESTART(298) res = new IR(kUnreservedKeyword, string("WITHOUT")); CASEEND
  CASESTART(299) res = new IR(kUnreservedKeyword, string("WORK")); CASEEND
  CASESTART(300) res = new IR(kUnreservedKeyword, string("WRAPPER")); CASEEND
  CASESTART(301) res = new IR(kUnreservedKeyword, string("WRITE")); CASEEND
  CASESTART(302) res = new IR(kUnreservedKeyword, string("XML")); CASEEND
  CASESTART(303) res = new IR(kUnreservedKeyword, string("YEAR")); CASEEND
  CASESTART(304) res = new IR(kUnreservedKeyword, string("YES")); CASEEND
  CASESTART(305) res = new IR(kUnreservedKeyword, string("ZONE")); CASEEND

  SWITCHEND

  TRANSLATEEND
}

void UnreservedKeyword::deep_delete() {
  delete this;
};

void UnreservedKeyword::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *ReservedKeyword::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
  
  CASESTART(0) res = new IR(kReservedKeyword, string("ALL")); CASEEND
  CASESTART(1) res = new IR(kReservedKeyword, string("ANALYSE")); CASEEND
  CASESTART(2) res = new IR(kReservedKeyword, string("ANALYZE")); CASEEND
  CASESTART(3) res = new IR(kReservedKeyword, string("AND")); CASEEND
  CASESTART(4) res = new IR(kReservedKeyword, string("ANY")); CASEEND
  CASESTART(5) res = new IR(kReservedKeyword, string("ARRAY")); CASEEND
  CASESTART(6) res = new IR(kReservedKeyword, string("AS")); CASEEND
  CASESTART(7) res = new IR(kReservedKeyword, string("ASC")); CASEEND
  CASESTART(8) res = new IR(kReservedKeyword, string("ASYMMETRIC")); CASEEND
  CASESTART(9) res = new IR(kReservedKeyword, string("BOTH")); CASEEND
  CASESTART(10) res = new IR(kReservedKeyword, string("CASE")); CASEEND
  CASESTART(11) res = new IR(kReservedKeyword, string("CAST")); CASEEND
  CASESTART(12) res = new IR(kReservedKeyword, string("CHECK")); CASEEND
  CASESTART(13) res = new IR(kReservedKeyword, string("COLLATE")); CASEEND
  CASESTART(14) res = new IR(kReservedKeyword, string("COLUMN")); CASEEND
  CASESTART(15) res = new IR(kReservedKeyword, string("CONSTRAINT")); CASEEND
  CASESTART(16) res = new IR(kReservedKeyword, string("CREATE")); CASEEND
  CASESTART(17) res = new IR(kReservedKeyword, string("CURRENT_CATALOG")); CASEEND
  CASESTART(18) res = new IR(kReservedKeyword, string("CURRENT_DATE")); CASEEND
  CASESTART(19) res = new IR(kReservedKeyword, string("CURRENT_ROLE")); CASEEND
  CASESTART(20) res = new IR(kReservedKeyword, string("CURRENT_TIME")); CASEEND
  CASESTART(21) res = new IR(kReservedKeyword, string("CURRENT_TIMESTAMP")); CASEEND
  CASESTART(22) res = new IR(kReservedKeyword, string("CURRENT_USER")); CASEEND
  CASESTART(23) res = new IR(kReservedKeyword, string("DEFAULT")); CASEEND
  CASESTART(24) res = new IR(kReservedKeyword, string("DEFERRABLE")); CASEEND
  CASESTART(25) res = new IR(kReservedKeyword, string("DESC")); CASEEND
  CASESTART(26) res = new IR(kReservedKeyword, string("DISTINCT")); CASEEND
  CASESTART(27) res = new IR(kReservedKeyword, string("DO")); CASEEND
  CASESTART(28) res = new IR(kReservedKeyword, string("ELSE")); CASEEND
  CASESTART(29) res = new IR(kReservedKeyword, string("END")); CASEEND
  CASESTART(30) res = new IR(kReservedKeyword, string("EXCEPT")); CASEEND
  CASESTART(31) res = new IR(kReservedKeyword, string("FALSE")); CASEEND
  CASESTART(32) res = new IR(kReservedKeyword, string("FETCH")); CASEEND
  CASESTART(33) res = new IR(kReservedKeyword, string("FOR")); CASEEND
  CASESTART(34) res = new IR(kReservedKeyword, string("FOREIGN")); CASEEND
  CASESTART(35) res = new IR(kReservedKeyword, string("FROM")); CASEEND
  CASESTART(36) res = new IR(kReservedKeyword, string("GRANT")); CASEEND
  CASESTART(37) res = new IR(kReservedKeyword, string("GROUP")); CASEEND
  CASESTART(38) res = new IR(kReservedKeyword, string("HAVING")); CASEEND
  CASESTART(39) res = new IR(kReservedKeyword, string("IN")); CASEEND
  CASESTART(40) res = new IR(kReservedKeyword, string("INITIALLY")); CASEEND
  CASESTART(41) res = new IR(kReservedKeyword, string("INTERSECT")); CASEEND
  CASESTART(42) res = new IR(kReservedKeyword, string("INTO")); CASEEND
  CASESTART(43) res = new IR(kReservedKeyword, string("LATERAL")); CASEEND
  CASESTART(44) res = new IR(kReservedKeyword, string("LEADING")); CASEEND
  CASESTART(45) res = new IR(kReservedKeyword, string("LIMIT")); CASEEND
  CASESTART(46) res = new IR(kReservedKeyword, string("LOCALTIME")); CASEEND
  CASESTART(47) res = new IR(kReservedKeyword, string("LOCALTIMESTAMP")); CASEEND
  CASESTART(48) res = new IR(kReservedKeyword, string("NOT")); CASEEND
  CASESTART(49) res = new IR(kReservedKeyword, string("NULL")); CASEEND
  CASESTART(50) res = new IR(kReservedKeyword, string("OFFSET")); CASEEND
  CASESTART(51) res = new IR(kReservedKeyword, string("ON")); CASEEND
  CASESTART(52) res = new IR(kReservedKeyword, string("ONLY")); CASEEND
  CASESTART(53) res = new IR(kReservedKeyword, string("OR")); CASEEND
  CASESTART(54) res = new IR(kReservedKeyword, string("ORDER")); CASEEND
  CASESTART(55) res = new IR(kReservedKeyword, string("PLACING")); CASEEND
  CASESTART(56) res = new IR(kReservedKeyword, string("PRIMARY")); CASEEND
  CASESTART(57) res = new IR(kReservedKeyword, string("REFERENCES")); CASEEND
  CASESTART(58) res = new IR(kReservedKeyword, string("RETURNING")); CASEEND
  CASESTART(59) res = new IR(kReservedKeyword, string("SELECT")); CASEEND
  CASESTART(60) res = new IR(kReservedKeyword, string("SESSION_USER")); CASEEND
  CASESTART(61) res = new IR(kReservedKeyword, string("SOME")); CASEEND
  CASESTART(62) res = new IR(kReservedKeyword, string("SYMMETRIC")); CASEEND
  CASESTART(63) res = new IR(kReservedKeyword, string("TABLE")); CASEEND
  CASESTART(64) res = new IR(kReservedKeyword, string("THEN")); CASEEND
  CASESTART(65) res = new IR(kReservedKeyword, string("TO")); CASEEND
  CASESTART(66) res = new IR(kReservedKeyword, string("TRAILING")); CASEEND
  CASESTART(67) res = new IR(kReservedKeyword, string("TRUE")); CASEEND
  CASESTART(68) res = new IR(kReservedKeyword, string("UNION")); CASEEND
  CASESTART(69) res = new IR(kReservedKeyword, string("UNIQUE")); CASEEND
  CASESTART(70) res = new IR(kReservedKeyword, string("USER")); CASEEND
  CASESTART(71) res = new IR(kReservedKeyword, string("USING")); CASEEND
  CASESTART(72) res = new IR(kReservedKeyword, string("VARIADIC")); CASEEND
  CASESTART(73) res = new IR(kReservedKeyword, string("WHEN")); CASEEND
  CASESTART(74) res = new IR(kReservedKeyword, string("WHERE")); CASEEND
  CASESTART(75) res = new IR(kReservedKeyword, string("WINDOW")); CASEEND
  CASESTART(76) res = new IR(kReservedKeyword, string("WITH")); CASEEND

  SWITCHEND

  TRANSLATEEND
}

void ReservedKeyword::deep_delete() {
  delete this;
};

void ReservedKeyword::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *ColNameKeyword::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0) res = new IR(kColNameKeyword, string("BETWEEN")); CASEEND
    CASESTART(1) res = new IR(kColNameKeyword, string("BIGINT")); CASEEND
    CASESTART(2) res = new IR(kColNameKeyword, string("BIT")); CASEEND
    CASESTART(3) res = new IR(kColNameKeyword, string("BOOLEAN")); CASEEND
    CASESTART(4) res = new IR(kColNameKeyword, string("CHAR")); CASEEND
    CASESTART(5) res = new IR(kColNameKeyword, string("CHARACTER")); CASEEND
    CASESTART(6) res = new IR(kColNameKeyword, string("COALESCE")); CASEEND
    CASESTART(7) res = new IR(kColNameKeyword, string("DEC")); CASEEND
    CASESTART(8) res = new IR(kColNameKeyword, string("DECIMAL")); CASEEND
    CASESTART(9) res = new IR(kColNameKeyword, string("EXISTS")); CASEEND
    CASESTART(10) res = new IR(kColNameKeyword, string("EXTRACT")); CASEEND
    CASESTART(11) res = new IR(kColNameKeyword, string("FLOAT")); CASEEND
    CASESTART(12) res = new IR(kColNameKeyword, string("GREATEST")); CASEEND
    CASESTART(13) res = new IR(kColNameKeyword, string("GROUPING")); CASEEND
    CASESTART(14) res = new IR(kColNameKeyword, string("INOUT")); CASEEND
    CASESTART(15) res = new IR(kColNameKeyword, string("INT")); CASEEND
    CASESTART(16) res = new IR(kColNameKeyword, string("INTEGER")); CASEEND
    CASESTART(17) res = new IR(kColNameKeyword, string("INTERVAL")); CASEEND
    CASESTART(18) res = new IR(kColNameKeyword, string("LEAST")); CASEEND
    CASESTART(19) res = new IR(kColNameKeyword, string("NATIONAL")); CASEEND
    CASESTART(20) res = new IR(kColNameKeyword, string("NCHAR")); CASEEND
    CASESTART(21) res = new IR(kColNameKeyword, string("NONE")); CASEEND
    CASESTART(22) res = new IR(kColNameKeyword, string("NORMALIZE")); CASEEND
    CASESTART(23) res = new IR(kColNameKeyword, string("NULLIF")); CASEEND
    CASESTART(24) res = new IR(kColNameKeyword, string("NUMERIC")); CASEEND
    CASESTART(25) res = new IR(kColNameKeyword, string("OUT")); CASEEND
    CASESTART(26) res = new IR(kColNameKeyword, string("OVERLAY")); CASEEND
    CASESTART(27) res = new IR(kColNameKeyword, string("POSITION")); CASEEND
    CASESTART(28) res = new IR(kColNameKeyword, string("PRECISION")); CASEEND
    CASESTART(29) res = new IR(kColNameKeyword, string("REAL")); CASEEND
    CASESTART(30) res = new IR(kColNameKeyword, string("ROW")); CASEEND
    CASESTART(31) res = new IR(kColNameKeyword, string("SETOF")); CASEEND
    CASESTART(32) res = new IR(kColNameKeyword, string("SMALLINT")); CASEEND
    CASESTART(33) res = new IR(kColNameKeyword, string("SUBSTRING")); CASEEND
    CASESTART(34) res = new IR(kColNameKeyword, string("TIME")); CASEEND
    CASESTART(35) res = new IR(kColNameKeyword, string("TIMESTAMP")); CASEEND
    CASESTART(36) res = new IR(kColNameKeyword, string("TREAT")); CASEEND
    CASESTART(37) res = new IR(kColNameKeyword, string("TRIM")); CASEEND
    CASESTART(38) res = new IR(kColNameKeyword, string("VALUES")); CASEEND
    CASESTART(39) res = new IR(kColNameKeyword, string("VARCHAR")); CASEEND
    CASESTART(40) res = new IR(kColNameKeyword, string("XMLATTRIBUTES")); CASEEND
    CASESTART(41) res = new IR(kColNameKeyword, string("XMLCONCAT")); CASEEND
    CASESTART(42) res = new IR(kColNameKeyword, string("XMLELEMENT")); CASEEND
    CASESTART(43) res = new IR(kColNameKeyword, string("XMLEXISTS")); CASEEND
    CASESTART(44) res = new IR(kColNameKeyword, string("XMLFOREST")); CASEEND
    CASESTART(45) res = new IR(kColNameKeyword, string("XMLNAMESPACES")); CASEEND
    CASESTART(46) res = new IR(kColNameKeyword, string("XMLPARSE")); CASEEND
    CASESTART(47) res = new IR(kColNameKeyword, string("XMLPI")); CASEEND
    CASESTART(48) res = new IR(kColNameKeyword, string("XMLROOT")); CASEEND
    CASESTART(49) res = new IR(kColNameKeyword, string("XMLSERIALIZE")); CASEEND
    CASESTART(50) res = new IR(kColNameKeyword, string("XMLTABLE")); CASEEND

  SWITCHEND

  TRANSLATEEND
}

void ColNameKeyword::deep_delete() {
  delete this;
};

void ColNameKeyword::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *TypeFuncNameKeyword::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0) res = new IR(kTypeFuncNameKeyword, string("AUTHORIZATION")); CASEEND
    CASESTART(1) res = new IR(kTypeFuncNameKeyword, string("BINARY")); CASEEND
    CASESTART(2) res = new IR(kTypeFuncNameKeyword, string("COLLATION")); CASEEND
    CASESTART(3) res = new IR(kTypeFuncNameKeyword, string("CONCURRENTLY")); CASEEND
    CASESTART(4) res = new IR(kTypeFuncNameKeyword, string("CROSS")); CASEEND
    CASESTART(5) res = new IR(kTypeFuncNameKeyword, string("CURRENT_SCHEMA")); CASEEND
    CASESTART(6) res = new IR(kTypeFuncNameKeyword, string("FREEZE")); CASEEND
    CASESTART(7) res = new IR(kTypeFuncNameKeyword, string("FULL")); CASEEND
    CASESTART(8) res = new IR(kTypeFuncNameKeyword, string("ILIKE")); CASEEND
    CASESTART(9) res = new IR(kTypeFuncNameKeyword, string("INNER")); CASEEND
    CASESTART(10) res = new IR(kTypeFuncNameKeyword, string("IS")); CASEEND
    CASESTART(11) res = new IR(kTypeFuncNameKeyword, string("ISNULL")); CASEEND
    CASESTART(12) res = new IR(kTypeFuncNameKeyword, string("JOIN")); CASEEND
    CASESTART(13) res = new IR(kTypeFuncNameKeyword, string("LEFT")); CASEEND
    CASESTART(14) res = new IR(kTypeFuncNameKeyword, string("LIKE")); CASEEND
    CASESTART(15) res = new IR(kTypeFuncNameKeyword, string("NATURAL")); CASEEND
    CASESTART(16) res = new IR(kTypeFuncNameKeyword, string("NOTNULL")); CASEEND
    CASESTART(17) res = new IR(kTypeFuncNameKeyword, string("OUTER")); CASEEND
    CASESTART(18) res = new IR(kTypeFuncNameKeyword, string("OVERLAPS")); CASEEND
    CASESTART(19) res = new IR(kTypeFuncNameKeyword, string("RIGHT")); CASEEND
    CASESTART(20) res = new IR(kTypeFuncNameKeyword, string("SIMILAR")); CASEEND
    CASESTART(21) res = new IR(kTypeFuncNameKeyword, string("TABLESAMPLE")); CASEEND
    CASESTART(22) res = new IR(kTypeFuncNameKeyword, string("VERBOSE")); CASEEND

  SWITCHEND

  TRANSLATEEND
}

void TypeFuncNameKeyword::deep_delete() {
  delete this;
};

void TypeFuncNameKeyword::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *ColId::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    res = new IR(kColId, string("IDENT"));
    CASEEND
    CASESTART(1)
    auto tmp1 = SAFETRANSLATE(unreserved_keyword_);
    res = new IR(kColId, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(2)
      auto tmp1 = SAFETRANSLATE(col_name_keyword_);
      res = new IR(kColId, OP3("", "", ""), tmp1);
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void ColId::deep_delete() {
  SAFEDELETE(unreserved_keyword_);
  SAFEDELETE(col_name_keyword_);
  delete this;
};

void ColId::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *TypeFunctionName::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    res = new IR(kTypeFunctionName, string("IDENT"));
    CASEEND
    CASESTART(1)
    auto tmp1 = SAFETRANSLATE(unreserved_keyword_);
    res = new IR(kTypeFunctionName, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(2)
      auto tmp1 = SAFETRANSLATE(type_func_name_keyword_);
      res = new IR(kTypeFunctionName, OP3("", "", ""), tmp1);
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void TypeFunctionName::deep_delete() {
  SAFEDELETE(unreserved_keyword_);
  SAFEDELETE(type_func_name_keyword_);
  delete this;
};

void TypeFunctionName::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *NonReservedWord::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    res = new IR(kNonReservedWord, string("IDENT"));
    CASEEND
    CASESTART(1)
    auto tmp1 = SAFETRANSLATE(unreserved_keyword_);
    res = new IR(kNonReservedWord, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(2)
      auto tmp1 = SAFETRANSLATE(col_name_keyword_);
      res = new IR(kNonReservedWord, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(3)
      auto tmp1 = SAFETRANSLATE(type_func_name_keyword_);
      res = new IR(kNonReservedWord, OP3("", "", ""), tmp1);
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void NonReservedWord::deep_delete() {
  SAFEDELETE(unreserved_keyword_);
  SAFEDELETE(type_func_name_keyword_);
  SAFEDELETE(col_name_keyword_);
  delete this;
};

void NonReservedWord::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *ColLabel::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    res = new IR(kColLabel, string("IDENT"));
    CASEEND
    CASESTART(1)
    auto tmp1 = SAFETRANSLATE(unreserved_keyword_);
    res = new IR(kColLabel, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(2)
      auto tmp1 = SAFETRANSLATE(col_name_keyword_);
      res = new IR(kColLabel, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(3)
      auto tmp1 = SAFETRANSLATE(type_func_name_keyword_);
      res = new IR(kColLabel, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(4)
      auto tmp1 = SAFETRANSLATE(reserved_keyword_);
      res = new IR(kColLabel, OP3("", "", ""), tmp1);
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void ColLabel::deep_delete() {
  SAFEDELETE(unreserved_keyword_);
  SAFEDELETE(col_name_keyword_);
  SAFEDELETE(type_func_name_keyword_);
  SAFEDELETE(reserved_keyword_);
  delete this;
};

void ColLabel::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *Attrs::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(attr_name_);
    res = new IR(kAttrs, OP3(".", "", ""), tmp1);
    CASEEND
    CASESTART(1)
    auto tmp1 = SAFETRANSLATE(attrs_);
    auto tmp2 = SAFETRANSLATE(attr_name_);
    res = new IR(kAttrs, OP3("", ".", ""), tmp1, tmp2);
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void Attrs::deep_delete() {
  SAFEDELETE(attr_name_);
  SAFEDELETE(attrs_);
  delete this;
};

void Attrs::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *AttrName::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

    auto tmp1 = SAFETRANSLATE(col_label_);
    res = new IR(kAttrName, OP3("", "", ""), tmp1);


  TRANSLATEEND
}

void AttrName::deep_delete() {
  SAFEDELETE(col_label_);
  delete this;
};

void AttrName::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *AnyName::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(col_id_);
    res = new IR(kAnyName, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(1)
    auto tmp1 = SAFETRANSLATE(col_id_);
    auto tmp2 = SAFETRANSLATE(attrs_);
    res = new IR(kAnyName, OP3("", "", ""), tmp1, tmp2);
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void AnyName::deep_delete() {
  SAFEDELETE(col_id_);
  SAFEDELETE(attrs_);
  delete this;
};

void AnyName::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *AnyNameList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(any_name_);
    res = new IR(kAnyNameList, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(1)
    auto tmp1 = SAFETRANSLATE(any_name_list_);
    auto tmp2 = SAFETRANSLATE(any_name_);
    res = new IR(kAnyNameList, OP3("", ",", ""), tmp1, tmp2);
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void AnyNameList::deep_delete() {
  SAFEDELETE(any_name_);
  SAFEDELETE(any_name_list_);
  delete this;
};

void AnyNameList::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *OptTableElementList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(table_element_list_);
    res = new IR(kOptTableElementList, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(1)
    res = new IR(kOptTableElementList, string(""));
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptTableElementList::deep_delete() {
  SAFEDELETE(table_element_list_);
  delete this;
};

void OptTableElementList::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *OptTypedTableElementList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(typed_table_element_list_);
    res = new IR(kOptTypedTableElementList, OP3("(", "", ")"), tmp1);
    CASEEND
    CASESTART(1)
    res = new IR(kOptTypedTableElementList, string(""));
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptTypedTableElementList::deep_delete() {
  SAFEDELETE(typed_table_element_list_);
  delete this;
};

void OptTypedTableElementList::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *TableElementList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(table_element_);
    res = new IR(kTableElementList, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(1)
    auto tmp1 = SAFETRANSLATE(table_element_list_);
    auto tmp2 = SAFETRANSLATE(table_element_);
    res = new IR(kTableElementList, OP3("", ",", ""), tmp1, tmp2);
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void TableElementList::deep_delete() {
  SAFEDELETE(table_element_);
  SAFEDELETE(table_element_list_);
  delete this;
};

void TableElementList::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *TypedTableElementList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(typed_table_element_);
    res = new IR(kTypedTableElementList, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(1)
    auto tmp1 = SAFETRANSLATE(typed_table_element_list_);
    auto tmp2 = SAFETRANSLATE(typed_table_element_);
    res = new IR(kTypedTableElementList, OP3("", ",", ""), tmp1, tmp2);
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void TypedTableElementList::deep_delete() {
  SAFEDELETE(typed_table_element_);
  SAFEDELETE(typed_table_element_list_);
  delete this;
};

void TypedTableElementList::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *TableElement::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(column_def_);
    res = new IR(kTableElement, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(1)
    auto tmp1 = SAFETRANSLATE(table_like_clause_);
    res = new IR(kTableElement, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(2)
      auto tmp1 = SAFETRANSLATE(table_constraint_);
      res = new IR(kTableElement, OP3("", "", ""), tmp1);
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void TableElement::deep_delete() {
  SAFEDELETE(column_def_);
  SAFEDELETE(table_like_clause_);
  SAFEDELETE(table_constraint_);
  delete this;
};

void TableElement::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *TypedTableElement::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(column_options_);
    res = new IR(kTypedTableElement, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(1)
    auto tmp1 = SAFETRANSLATE(table_constraint_);
    res = new IR(kTypedTableElement, OP3("", "", ""), tmp1);
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void TypedTableElement::deep_delete() {
  SAFEDELETE(column_options_);
  SAFEDELETE(table_constraint_);
  delete this;
};

void TypedTableElement::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *TableLikeClause::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

    auto tmp1 = SAFETRANSLATE(table_name_);
    auto tmp2 = SAFETRANSLATE(table_like_option_list_);
    res = new IR(kTableLikeClause, OP3("LIKE", "", ""), tmp1, tmp2);


  TRANSLATEEND
}

void TableLikeClause::deep_delete() {
  SAFEDELETE(table_name_);
  SAFEDELETE(table_like_option_list_);
  delete this;
};

void TableLikeClause::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *TableLikeOptionList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(table_like_option_list_);
    auto tmp2 = SAFETRANSLATE(table_like_option_);
    res = new IR(kTableLikeOptionList, OP3("", "INCLUDING", ""), tmp1, tmp2);
    CASEEND
    CASESTART(1)
      auto tmp1 = SAFETRANSLATE(table_like_option_list_);
      auto tmp2 = SAFETRANSLATE(table_like_option_);
      res = new IR(kTableLikeOptionList, OP3("", "EXCLUDING", ""), tmp1, tmp2);
    CASEEND
    CASESTART(2)
    res = new IR(kTableLikeOptionList, string(""));
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void TableLikeOptionList::deep_delete() {
  SAFEDELETE(table_like_option_list_);
  SAFEDELETE(table_like_option_);
  delete this;
};

void TableLikeOptionList::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *TableLikeOption::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0) res = new IR(kTableLikeOption, string("COMMENTS")); CASEEND
    CASESTART(1) res = new IR(kTableLikeOption, string("COMPRESSION")); CASEEND
    CASESTART(2) res = new IR(kTableLikeOption, string("CONSTRAINTS")); CASEEND
    CASESTART(3) res = new IR(kTableLikeOption, string("DEFAULTS")); CASEEND
    CASESTART(4) res = new IR(kTableLikeOption, string("IDENTITY")); CASEEND
    CASESTART(5) res = new IR(kTableLikeOption, string("GENERATED")); CASEEND
    CASESTART(6) res = new IR(kTableLikeOption, string("INDEXES")); CASEEND
    CASESTART(7) res = new IR(kTableLikeOption, string("STATISTICS")); CASEEND
    CASESTART(8) res = new IR(kTableLikeOption, string("STORAGE")); CASEEND
    CASESTART(9) res = new IR(kTableLikeOption, string("ALL")); CASEEND

  SWITCHEND

  TRANSLATEEND
}

void TableLikeOption::deep_delete() {
  delete this;
};

void TableLikeOption::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *ColumnOptions::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(col_id_);
    auto tmp2 = SAFETRANSLATE(col_qual_list_);
    res = new IR(kColumnOptions, OP3("", "", ""), tmp1, tmp2);
    CASEEND
    CASESTART(1)
    auto tmp1 = SAFETRANSLATE(col_id_);
    auto tmp2 = SAFETRANSLATE(col_qual_list_);
    res = new IR(kColumnOptions, OP3("", "WITH OPTIONS", ""), tmp1, tmp2);
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void ColumnOptions::deep_delete() {
  SAFEDELETE(col_id_);
  SAFEDELETE(col_qual_list_);
  delete this;
};

void ColumnOptions::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *ColQualList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(col_qual_list_);
    auto tmp2 = SAFETRANSLATE(col_constraint_);
    res = new IR(kColQualList, OP3("", "", ""), tmp1, tmp2);
    CASEEND
    CASESTART(1)
    res = new IR(kColQualList, string(""));
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void ColQualList::deep_delete() {
  SAFEDELETE(col_qual_list_);
  SAFEDELETE(col_constraint_);
  delete this;
};

void ColQualList::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *ColConstraint::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(constraint_name_);
    auto tmp2 = SAFETRANSLATE(col_constraint_elem_);
    res = new IR(kColConstraint, OP3("CONSTRAINT", "", ""), tmp1, tmp2);
    CASEEND
    CASESTART(1)
    auto tmp1 = SAFETRANSLATE(col_constraint_elem_);
    res = new IR(kColConstraint, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(2)
      auto tmp1 = SAFETRANSLATE(constraint_attr_);
      res = new IR(kColConstraint, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(3)
      auto tmp1 = SAFETRANSLATE(any_name_);
      res = new IR(kColConstraint, OP3("", "", ""), tmp1);
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void ColConstraint::deep_delete() {
  SAFEDELETE(constraint_name_);
  SAFEDELETE(col_constraint_elem_);
  SAFEDELETE(constraint_attr_);
  SAFEDELETE(any_name_);
  delete this;
};

void ColConstraint::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *ColConstraintElem::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)

    res = new IR(kColConstraintElem, string("NOT NULL"));
    CASEEND
    CASESTART(1)
      res = new IR(kColConstraintElem, string("NULL"));
    CASEEND
    CASESTART(2)
      auto tmp1 = SAFETRANSLATE(opt_definition_);
      auto tmp2 = SAFETRANSLATE(opt_cons_table_space_);
      res = new IR(kColConstraintElem, OP3("UNIQUE", "", ""), tmp1, tmp2);
    CASEEND
    CASESTART(3)
      auto tmp1 = SAFETRANSLATE(opt_definition_);
      auto tmp2 = SAFETRANSLATE(opt_cons_table_space_);
      res = new IR(kColConstraintElem, OP3("PRIMARY KEY", "", ""), tmp1, tmp2);
    CASEEND
    CASESTART(4)
      auto tmp1 = SAFETRANSLATE(expr_);
      auto tmp2 = SAFETRANSLATE(opt_no_inherit_);
      res = new IR(kColConstraintElem, OP3("CHECK (", ")", ""), tmp1, tmp2);
    CASEEND
    CASESTART(5)
      auto tmp1 = SAFETRANSLATE(expr_);
      res = new IR(kColConstraintElem, OP3("DEFAULT", "", ""), tmp1);
    CASEEND
    CASESTART(6)
      auto tmp1 = SAFETRANSLATE(generated_when_);
      auto tmp2 = SAFETRANSLATE(opt_parenthesized_seq_opt_list_);
      res = new IR(kColConstraintElem, OP3("GENERATED", "AS IDENTITY", ""), tmp1, tmp2);
    CASEEND
    CASESTART(7)
      auto tmp1 = SAFETRANSLATE(generated_when_);
      auto tmp2 = SAFETRANSLATE(expr_);
      res = new IR(kColConstraintElem, OP3("GENERATED", "AS (", ") STORED"), tmp1, tmp2);
    CASEEND
    CASESTART(8)
      auto tmp1 = SAFETRANSLATE(name_);
      auto tmp2 = SAFETRANSLATE(opt_column_list_);
      res = new IR(kUnknown, OP3("REFERENCES", "", ""), tmp1, tmp2);
      PUSH(res);
      auto tmp3 = SAFETRANSLATE(key_match_);
      res = new IR(kUnknown, OP3("", "", ""), res, tmp3);
      PUSH(res);
      auto tmp4 = SAFETRANSLATE(key_actions_);
      res = new IR(kColConstraintElem, OP3("", "", ""), res, tmp4);
    CASEEND

  SWITCHEND

  TRANSLATEEND
}


void ColConstraintElem::deep_delete() {
  SAFEDELETE(opt_definition_);
  SAFEDELETE(opt_cons_table_space_);
  SAFEDELETE(expr_);
  SAFEDELETE(opt_no_inherit_);
  SAFEDELETE(generated_when_);
  SAFEDELETE(opt_parenthesized_seq_opt_list_);
  SAFEDELETE(name_);
  SAFEDELETE(opt_column_list_);
  SAFEDELETE(key_match_);
  SAFEDELETE(key_actions_);
  delete this;
};

void ColConstraintElem::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *GeneratedWhen::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    res = new IR(kGeneratedWhen, string("ALWAYS"));
    CASEEND
    CASESTART(1)
    res = new IR(kGeneratedWhen, string("BY DEFAULT"));
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void GeneratedWhen::deep_delete() {
  delete this;
};

void GeneratedWhen::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *ConstraintAttr::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0) res = new IR(kConstraintAttr, string("DEFERRABLE")); CASEEND
    CASESTART(1) res = new IR(kConstraintAttr, string("NOT DEFERRABLE")); CASEEND
    CASESTART(2) res = new IR(kConstraintAttr, string("INITIALLY DEFERRED")); CASEEND
    CASESTART(3) res = new IR(kConstraintAttr, string("INITIALLY IMMEDIATE")); CASEEND

  SWITCHEND

  TRANSLATEEND
}

void ConstraintAttr::deep_delete() {
  delete this;
};

void ConstraintAttr::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *KeyMatch::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0) res = new IR(kConstraintAttr, string("MATCH FULL")); CASEEND
    CASESTART(1) res = new IR(kConstraintAttr, string("MATCH PARTIAL")); CASEEND
    CASESTART(2) res = new IR(kConstraintAttr, string("MATCH SIMPLE")); CASEEND
    CASESTART(3) res = new IR(kConstraintAttr, string("")); CASEEND

  SWITCHEND

  TRANSLATEEND
}

void KeyMatch::deep_delete() {
  delete this;
};

void KeyMatch::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *OptInherit::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(table_name_list_);
    res = new IR(kOptInherit, OP3("INHERITS (", "", ")"), tmp1);
    CASEEND
    CASESTART(1)
    res = new IR(kOptInherit, string(""));
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptInherit::deep_delete() {
  SAFEDELETE(table_name_list_);
  delete this;
};

void OptInherit::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *OptNoInherit::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    res = new IR(kOptNoInherit, string("NO INHERIT"));
    CASEEND
    CASESTART(1)
    res = new IR(kOptNoInherit, string(""));
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptNoInherit::deep_delete() {
  delete this;
};

void OptNoInherit::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *OptColumnList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(column_list_);
    res = new IR(kOptColumnList, OP3("(", "", ")"), tmp1);
    CASEEND
    CASESTART(1)
    res = new IR(kOptColumnList, string(""));
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptColumnList::deep_delete() {
  SAFEDELETE(column_list_);
  delete this;
};

void OptColumnList::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *ColumnList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(column_elem_);
    res = new IR(kColumnList, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(1)
    auto tmp1 = SAFETRANSLATE(column_list_);
    auto tmp2 = SAFETRANSLATE(column_elem_);
    res = new IR(kColumnList, OP3("", ",", ""), tmp1, tmp2);
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void ColumnList::deep_delete() {
  SAFEDELETE(column_elem_);
  SAFEDELETE(column_list_);
  delete this;
};

void ColumnList::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *ColumnElem::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

    auto tmp1 = SAFETRANSLATE(col_id_);
    res = new IR(kColumnElem, OP3("", "", ""), tmp1);

  TRANSLATEEND
}

void ColumnElem::deep_delete() {
  SAFEDELETE(col_id_);
  delete this;
};

void ColumnElem::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *OptPartitionSpec::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(partition_spec_);
    res = new IR(kOptPartitionSpec, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(1)
    res = new IR(kOptPartitionSpec, string(""));
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptPartitionSpec::deep_delete() {
  SAFEDELETE(partition_spec_);
  delete this;
};

void OptPartitionSpec::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *PartitionSpec::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

    auto tmp1 = SAFETRANSLATE(col_id_);
    auto tmp2 = SAFETRANSLATE(part_params_);
    res = new IR(kPartitionSpec, OP3("PARTITION BY", "(", ")"), tmp1, tmp2);

  TRANSLATEEND
}

void PartitionSpec::deep_delete() {
  SAFEDELETE(col_id_);
  SAFEDELETE(part_params_);
  delete this;
};

void PartitionSpec::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *PartParams::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(part_elem_);
    res = new IR(kPartParams, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(1)
    auto tmp1 = SAFETRANSLATE(part_params_);
    auto tmp2 = SAFETRANSLATE(part_elem_);
    res = new IR(kPartParams, OP3("", "", ""), tmp1, tmp2);
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void PartParams::deep_delete() {
  SAFEDELETE(part_elem_);
  SAFEDELETE(part_params_);
  delete this;
};

void PartParams::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *PartElem::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(col_id_);
    auto tmp2 = SAFETRANSLATE(opt_collate_);
    res = new IR(kUnknown, OP3("", "", ""), tmp1, tmp2);
    PUSH(res);
    auto tmp3 = SAFETRANSLATE(opt_class_);
    res = new IR(kPartElem, OP3("", "", ""), res, tmp3);
    CASEEND
    CASESTART(1)
      auto tmp1 = SAFETRANSLATE(func_expr_);
      auto tmp2 = SAFETRANSLATE(opt_collate_);
      res = new IR(kUnknown, OP3("", "", ""), tmp1, tmp2);
      PUSH(res);
      auto tmp3 = SAFETRANSLATE(opt_class_);
      res = new IR(kPartElem, OP3("", "", ""), res, tmp3);
    CASEEND
    CASESTART(2)
      auto tmp1 = SAFETRANSLATE(expr_);
      auto tmp2 = SAFETRANSLATE(opt_collate_);
      res = new IR(kUnknown, OP3("(", ")", ""), tmp1, tmp2);
      PUSH(res);
      auto tmp3 = SAFETRANSLATE(opt_class_);
      res = new IR(kPartElem, OP3("", "", ""), res, tmp3);
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void PartElem::deep_delete() {
  SAFEDELETE(col_id_);
  SAFEDELETE(opt_collate_);
  SAFEDELETE(opt_class_);
  SAFEDELETE(func_expr_);
  SAFEDELETE(expr_);
  delete this;
};

void PartElem::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *OptWithReplotions::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(reloptions_);
    res = new IR(kOptWithReplotions, OP3("WITH", "", ""), tmp1);
    CASEEND
    CASESTART(1)
    res = new IR(kOptWithReplotions, string("WITHOUT OIDS"));
    CASEEND
    CASESTART(2)
      res = new IR(kOptWithReplotions, string(""));
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptWithReplotions::deep_delete() {
  SAFEDELETE(reloptions_);
  delete this;
};

void OptWithReplotions::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *OptTableSpace::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(tablespace_name_);
    res = new IR(kOptTableSpace, OP3("TABLESPACE", "", ""), tmp1);
    CASEEND
    CASESTART(1)
    res = new IR(kOptTableSpace, string(""));
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptTableSpace::deep_delete() {
  SAFEDELETE(tablespace_name_);
  delete this;
};

void OptTableSpace::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *OptConsTableSpace::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(tablespace_name_);
    res = new IR(kOptConsTableSpace, OP3("USING INDEX TABLESPACE", "", ""), tmp1);
    CASEEND
    CASESTART(1)
    res = new IR(kOptConsTableSpace, string(""));
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptConsTableSpace::deep_delete() {
  SAFEDELETE(tablespace_name_);
  delete this;
};

void OptConsTableSpace::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *ExistingIndex::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

    auto tmp1 = SAFETRANSLATE(index_name_);
    res = new IR(kExistingIndex, OP3("USING INDEX", "", ""), tmp1);

  TRANSLATEEND
}

void ExistingIndex::deep_delete() {
  SAFEDELETE(index_name_);
  delete this;
};

void ExistingIndex::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *PartitionBoundSpec::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(hash_partbound_);
    res = new IR(kPartitionBoundSpec, OP3("FOR VALUES WITH (", ")", ""), tmp1);
    CASEEND
    CASESTART(1)
      auto tmp1 = SAFETRANSLATE(expr_list_);
      res = new IR(kPartitionBoundSpec, OP3("FOR VALUES IN (", ")", ""), tmp1);
    CASEEND
    CASESTART(2)
      auto tmp1 = SAFETRANSLATE(expr_list_0_);
      auto tmp2 = SAFETRANSLATE(expr_list_1_);
      res = new IR(kPartitionBoundSpec, OP3("FOR VALUES FROM (", ") TO (", ")"), tmp1, tmp2);
    CASEEND
    CASESTART(3)
      res = new IR(kPartitionBoundSpec, string("DEFAULT"));
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void PartitionBoundSpec::deep_delete() {
  SAFEDELETE(hash_partbound_);
  SAFEDELETE(expr_list_);
  SAFEDELETE(expr_list_0_);
  SAFEDELETE(expr_list_1_);
  delete this;
};

void PartitionBoundSpec::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *HashPartboundElem::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

    auto tmp1 = SAFETRANSLATE(non_reserved_word_);
    res = new IR(kHashPartboundElem, OP3("", "", "ICONST"), tmp1);


  TRANSLATEEND
}

void HashPartboundElem::deep_delete() {
  SAFEDELETE(non_reserved_word_);
  delete this;
};

void HashPartboundElem::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *HashPartbound::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(hash_partbound_elem_);
    res = new IR(kHashPartbound, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(1)
    auto tmp1 = SAFETRANSLATE(hash_partbound_);
    auto tmp2 = SAFETRANSLATE(hash_partbound_elem_);
    res = new IR(kHashPartbound, OP3("", ",", ""), tmp1, tmp2);
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void HashPartbound::deep_delete() {
  SAFEDELETE(hash_partbound_elem_);
  SAFEDELETE(hash_partbound_);
  delete this;
};

void HashPartbound::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *OptDefinition::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(definition_);
    res = new IR(kOptDefinition, OP3("WITH", "", ""), tmp1);
    CASEEND
    CASESTART(1)
    res = new IR(kOptDefinition, string(""));
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptDefinition::deep_delete() {
  SAFEDELETE(definition_);
  delete this;
};

void OptDefinition::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *Definition::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

    auto tmp1 = SAFETRANSLATE(def_list_);
    res = new IR(kDefinition, OP3("(", "", ")"), tmp1);


  TRANSLATEEND
}

void Definition::deep_delete() {
  SAFEDELETE(def_list_);
  delete this;
};

void Definition::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *DefList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(def_elem_);
    res = new IR(kDefList, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(1)
    auto tmp1 = SAFETRANSLATE(def_list_);
    auto tmp2 = SAFETRANSLATE(def_elem_);
    res = new IR(kDefList, OP3("", ",", ""), tmp1, tmp2);
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void DefList::deep_delete() {
  SAFEDELETE(def_elem_);
  SAFEDELETE(def_list_);
  delete this;
};

void DefList::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *DefElem::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(col_label_);
    auto tmp2 = SAFETRANSLATE(def_arg_);
    res = new IR(kDefElem, OP3("", "=", ""), tmp1, tmp2);
    CASEEND
    CASESTART(1)
    auto tmp1 = SAFETRANSLATE(col_label_);
    res = new IR(kDefElem, OP3("", "", ""), tmp1);
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void DefElem::deep_delete() {
  SAFEDELETE(col_label_);
  SAFEDELETE(def_arg_);
  delete this;
};

void DefElem::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *DefArg::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(func_type_);
    res = new IR(kDefArg, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(1)
      auto tmp1 = SAFETRANSLATE(reserved_keyword_);
      res = new IR(kDefArg, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(2)
      auto tmp1 = SAFETRANSLATE(numeric_only_);
      res = new IR(kDefArg, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(3)
      auto tmp1 = SAFETRANSLATE(Sconst_);
      res = new IR(kDefArg, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(4)
      res = new IR(kDefArg, string("NONE"));
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void DefArg::deep_delete() {
  SAFEDELETE(func_type_);
  SAFEDELETE(reserved_keyword_);
  SAFEDELETE(numeric_only_);
  SAFEDELETE(Sconst_);
  delete this;
};

void DefArg::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *Iconst::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  res = new IR(kIconst, string("ICONST"));

  TRANSLATEEND
}

void Iconst::deep_delete() {
  delete this;
};

void Iconst::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *Sconst::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART
  res = new IR(kSconst, string("SCONST"));

  TRANSLATEEND
}

void Sconst::deep_delete() {
  delete this;
};

void Sconst::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *SignedIconst::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(iconst_);
    res = new IR(kSignedIconst, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(1)
      auto tmp1 = SAFETRANSLATE(iconst_);
      res = new IR(kSignedIconst, OP3("+", "", ""), tmp1);
    CASEEND
    CASESTART(2)
      auto tmp1 = SAFETRANSLATE(iconst_);
      res = new IR(kSignedIconst, OP3("-", "", ""), tmp1);
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void SignedIconst::deep_delete() {
  SAFEDELETE(iconst_);
  delete this;
};

void SignedIconst::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *FuncType::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(type_name_);
    res = new IR(kFuncType, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(1)
    auto tmp1 = SAFETRANSLATE(type_function_name_);
    auto tmp2 = SAFETRANSLATE(attrs_);
    res = new IR(kFuncType, OP3("", "", "% TYPE"), tmp1, tmp2);
    CASEEND
    CASESTART(2)
      auto tmp1 = SAFETRANSLATE(type_function_name_);
      auto tmp2 = SAFETRANSLATE(attrs_);
      res = new IR(kFuncType, OP3("SETOF", "", "% TYPE"), tmp1, tmp2);
    CASEEND

  SWITCHEND

  TRANSLATEEND
}

void FuncType::deep_delete() {
  SAFEDELETE(type_name_);
  SAFEDELETE(type_function_name_);
  SAFEDELETE(attrs_);
  delete this;
};

void FuncType::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *OptBy::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    res = new IR(kOptBy, string("BY"));
    CASEEND
    CASESTART(1)
      res = new IR(kOptBy, string(""));
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptBy::deep_delete() {
  delete this;
};

void OptBy::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *NumericOnly::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    res = new IR(kNumericOnly, string("FCONST"));
    CASEEND
    CASESTART(1)
      res = new IR(kNumericOnly, string("+ FCONST"));
    CASEEND
    CASESTART(2)
      res = new IR(kNumericOnly, string("- FCONST"));
    CASEEND
    CASESTART(3)
    auto tmp1 = SAFETRANSLATE(signed_iconst_);
    res = new IR(kNumericOnly, OP3("", "", ""), tmp1);
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void NumericOnly::deep_delete() {
  SAFEDELETE(signed_iconst_);
  delete this;
};

void NumericOnly::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *NumericOnlyList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(numeric_only_);
    res = new IR(kNumericOnlyList, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(1)
    auto tmp1 = SAFETRANSLATE(numeric_only_list_);
    auto tmp2 = SAFETRANSLATE(numeric_only_);
    res = new IR(kNumericOnlyList, OP3("", ",", ""), tmp1, tmp2);
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void NumericOnlyList::deep_delete() {
  SAFEDELETE(numeric_only_);
  SAFEDELETE(numeric_only_list_);
  delete this;
};

void NumericOnlyList::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *OptParenthesizedSeqOptList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(seq_opt_list_);
    res = new IR(kOptParenthesizedSeqOptList, OP3("(", "", ")"), tmp1);
    CASEEND
    CASESTART(1)
    res = new IR(kOptParenthesizedSeqOptList, string(""));
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptParenthesizedSeqOptList::deep_delete() {
  SAFEDELETE(seq_opt_list_);
  delete this;
};

void OptParenthesizedSeqOptList::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *SeqOptList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(seq_opt_elem_);
    res = new IR(kSeqOptList, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(1)
    auto tmp1 = SAFETRANSLATE(seq_opt_list_);
    auto tmp2 = SAFETRANSLATE(seq_opt_elem_);
    res = new IR(kSeqOptList, OP3("", "", ""), tmp1, tmp2);
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void SeqOptList::deep_delete() {
  SAFEDELETE(seq_opt_elem_);
  SAFEDELETE(seq_opt_list_);
  delete this;
};

void SeqOptList::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *SeqOptElem::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(type_name_);
    res = new IR(kSeqOptElem, OP3("AS", "", ""), tmp1);
    CASEEND
    CASESTART(1)
      auto tmp1 = SAFETRANSLATE(numeric_only_);
      res = new IR(kSeqOptElem, OP3("CACHE", "", ""), tmp1);
    CASEEND
    CASESTART(2)
      res = new IR(kSeqOptElem, string("CYCLE"));
    CASEEND
    CASESTART(3)
      res = new IR(kSeqOptElem, string("NO CYCLE"));
    CASEEND
    CASESTART(4)
    auto tmp1 = SAFETRANSLATE(opt_by_);
    auto tmp2 = SAFETRANSLATE(numeric_only_);
    res = new IR(kSeqOptElem, OP3("INCREMENT", "", ""), tmp1, tmp2);
    CASEEND
    CASESTART(5)
      auto tmp1 = SAFETRANSLATE(numeric_only_);
      res = new IR(kSeqOptElem, OP3("MAXVALUE", "", ""), tmp1);
    CASEEND
    CASESTART(6)
      auto tmp1 = SAFETRANSLATE(numeric_only_);
      res = new IR(kSeqOptElem, OP3("MINVALUE", "", ""), tmp1);
    CASEEND
    CASESTART(7)
      res = new IR(kSeqOptElem, string("NO MAXVALUE"));
    CASEEND
    CASESTART(8)
      res = new IR(kSeqOptElem, string("NO MINVALUE"));
    CASEEND
    CASESTART(9)
      auto tmp1 = SAFETRANSLATE(any_name_);
      res = new IR(kSeqOptElem, OP3("OWNED BY", "", ""), tmp1);
    CASEEND
    CASESTART(10)
      auto tmp1 = SAFETRANSLATE(any_name_);
      res = new IR(kSeqOptElem, OP3("SEQUENCE NAME", "", ""), tmp1);
    CASEEND
    CASESTART(11)
      auto tmp1 = SAFETRANSLATE(opt_with_);
      auto tmp2 = SAFETRANSLATE(numeric_only_);
      res = new IR(kSeqOptElem, OP3("START", "", ""), tmp1, tmp2);
    CASEEND
    CASESTART(12)
      res = new IR(kSeqOptElem, string("RESTART"));
    CASEEND
    CASESTART(13)
      auto tmp1 = SAFETRANSLATE(opt_with_);
      auto tmp2 = SAFETRANSLATE(numeric_only_);
      res = new IR(kSeqOptElem, OP3("RESTART", "", ""), tmp1, tmp2);
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void SeqOptElem::deep_delete() {
  SAFEDELETE(type_name_);
  SAFEDELETE(numeric_only_);
  SAFEDELETE(any_name_);
  SAFEDELETE(opt_with_);
  SAFEDELETE(opt_by_);
  delete this;
};

void SeqOptElem::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *Reloptions::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

    auto tmp1 = SAFETRANSLATE(reloption_list_);
    res = new IR(kReloptions, OP3("(", "", ")"), tmp1);

  TRANSLATEEND
}

void Reloptions::deep_delete() {
  SAFEDELETE(reloption_list_);
  delete this;
};

void Reloptions::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *OptReloptions::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(reloptions_);
    res = new IR(kOptReloptions, OP3("WITH", "", ""), tmp1);
    CASEEND
    CASESTART(1)
    res = new IR(kOptReloptions, string(""));
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptReloptions::deep_delete() {
  SAFEDELETE(reloptions_);
  delete this;
};

void OptReloptions::generate() {
  GENERATESTART(1)
  GENERATEEND
}


IR *ReloptionList::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(reloption_elem_);
    res = new IR(kReloptionList, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(1)
    auto tmp1 = SAFETRANSLATE(reloption_list_);
    auto tmp2 = SAFETRANSLATE(reloption_elem_);
    res = new IR(kReloptionList, OP3("", ",", ""), tmp1, tmp2);
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void ReloptionList::deep_delete() {
  SAFEDELETE(reloption_elem_);
  SAFEDELETE(reloption_list_);
  delete this;
};

void ReloptionList::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *ReloptionElem::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(col_label_);
    auto tmp2 = SAFETRANSLATE(def_arg_);
    res = new IR(kReloptionElem, OP3("", "=", ""), tmp1, tmp2);
    CASEEND
    CASESTART(1)
    auto tmp1 = SAFETRANSLATE(col_label_);
    res = new IR(kReloptionElem, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(2)
      auto tmp1 = SAFETRANSLATE(col_label_0_);
      auto tmp2 = SAFETRANSLATE(col_label_1_);
      res = new IR(kReloptionElem, OP3("", ".", "="), tmp1, tmp2);
      PUSH(res);
      auto tmp3 = SAFETRANSLATE(def_arg_);
      res = new IR(kReloptionElem, OP3("", "", ""), res, tmp3);
    CASEEND
    CASESTART(3)
      auto tmp1 = SAFETRANSLATE(col_label_0_);
      auto tmp2 = SAFETRANSLATE(col_label_1_);
      res = new IR(kReloptionElem, OP3("", ".", ""), tmp1, tmp2);
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void ReloptionElem::deep_delete() {
  SAFEDELETE(col_label_);
  SAFEDELETE(def_arg_);
  SAFEDELETE(col_label_0_);
  SAFEDELETE(col_label_1_);

  delete this;
};

void ReloptionElem::generate() {
  GENERATESTART(1)
  GENERATEEND
}

IR *OptClass::translate(vector<IR *> &v_ir_collector) {
  TRANSLATESTART

  SWITCHSTART
    CASESTART(0)
    auto tmp1 = SAFETRANSLATE(any_name_);
    res = new IR(kOptClass, OP3("", "", ""), tmp1);
    CASEEND
    CASESTART(1)
    res = new IR(kOptClass, string(""));
    CASEEND
  SWITCHEND

  TRANSLATEEND
}

void OptClass::deep_delete() {
  SAFEDELETE(any_name_);
  delete this;
};

void OptClass::generate() {
  GENERATESTART(1)
  GENERATEEND
}
