#include "MySQL_IR_constructor.h"
#include "../../include/ir_wrapper.h"

IR* MySQLIRConstructor::gen_node_ir(vector<antlr4::tree::ParseTree*> v_children, IRTYPE ir_type) {

  vector<MySQLIRConstructor::ParseTreeTypeEnum> v_children_type; // 0 for terminated token, 1 for non-term rule.

  for (int i = 0; i < v_children.size(); i++) {
    v_children_type.push_back(this->get_parser_tree_node_type_enum(v_children[i]));
  }

  assert(v_children.size() == v_children_type.size());

  if (v_children_type.size() == 0) {
    // Empty node.
    return new IR(kUnknown, OP0(), NULL, NULL);
  }

  string prefix = "", middle = "";
  IR *left = nullptr, *right = nullptr;
  int keyword_idx = 0;
  IR* cur_ir = nullptr;
  int idx = 0;

  // Construct the first IR node.
  // Prefix
  while (idx < v_children_type.size() && v_children_type[idx] == TOKEN) {
    prefix += " " + this->get_terminated_token_str(v_children[idx]) + " ";
    idx++;
  }
  // Left
  if (idx < v_children_type.size()) { // SPEC or RULE
    left = this->get_rule_returned_ir(v_children[idx], v_children_type[idx]);
    idx++;
  }
  // middle str
  while (idx < v_children_type.size() && v_children_type[idx] == TOKEN) {
    middle += " " + this->get_terminated_token_str(v_children[idx]) + " ";
    idx++;
  }
  // right
  if (idx < v_children_type.size()) { // SPEC or RULE
    right = this->get_rule_returned_ir(v_children[idx], v_children_type[idx]);
    idx++;
  }

  // Ignore suffix for now.
  cur_ir = new IR(kUnknown, OP3(prefix, middle, ""), left, right);

  prefix = "";
  middle = "";
  left = nullptr;
  right = nullptr;
  while (idx < v_children_type.size()) {
    // middle str
    while (idx < v_children_type.size() && v_children_type[idx] == TOKEN) {
      middle += " " + this->get_terminated_token_str(v_children[idx]) + " ";
      idx++;
    }
    // right
    if (idx < v_children_type.size()) { // SPEC or RULE
      right = this->get_rule_returned_ir(v_children[idx], v_children_type[idx]);
      idx++;
    }

    if (right == nullptr) {
      // Reaching the end.
      cur_ir->set_suffix(middle);
      middle = "";
      break;
    } else {
      cur_ir = new IR(kUnknown, OP3("", middle, ""), cur_ir, right);
      middle = "";
      right = nullptr;
      continue;
    }
  }

  cur_ir->set_ir_type(ir_type);
  return cur_ir;

}

void MySQLIRConstructor::special_handling_rule_name(IR* root, IRTYPE ir_type) {

// The function handle all identifiers and literals.
// Fix the IRTypes, DataTypes and DataFlags from the data structure.
// pureIdentifier,
// Notation, all fixing identifier rules: pureIdentifier, identifier, identifierList, identifierListWithParentheses,
// -- qualifiedIdentifier, simpleIdentifier, dotIdentifier, textOrIdentifier,
// -- lValueIdentifier, roleIdentifierOrText, identifierList, insertIdentifier,
// -- userIdentifierOrText, schemaIdentifierPair, grantIdentifier,
// -- roleIdentifierOrText, simpleIdentifier, identList, identListArg,
// -- qualifiedIdentifier, dotIdentifier, labelIdentifier, userIdentifierOrText,
// -- fieldIdentifier, insertIdentifier, identListArg, allorpartitionnamelist

  switch(ir_type) {
  case kFunctionCall:
    handle_function_call(root);
    break;
  case kLabel:
    handle_label_node(root);
    break;
  case kRoleIdentifier:
    handle_role_iden_node(root);
    break;
  case kLValueIdentifier:
    handle_lvalue_iden(root);
    break;
  case kSizeNumber:
    handle_size_number(root);
    break;
  case kAlterEvent:
    handle_alter_event(root);
    break;
  case kAlterPartition:
    handle_alter_partition(root);
    break;
  case kAlterListItem:
    handle_alter_list_item(root);
    break;
  case kPlace:
    handle_place(root);
    break;
  case kAlterOrderList:
    handle_alter_order_list(root);
    break;
  case kAlterAlgorithmOption:
    handle_alter_algorithm_option(root);
    break;
  case kAlterLockOption:
    handle_alter_lock_option(root);
    break;
  case kAlterTablespace:
    handle_alter_table_space(root);
    break;
  case kAlterUndoTablespace:
    handle_alter_undo_table_space(root);
    break;
  case kAlterView:
    handle_alter_view(root);
    break;
  case kViewTail:
    handle_view_tail(root);
    break;
  case kCreateDatabase:
    handle_create_database(root);
    break;
  case kCreateTable:
    handle_create_table(root);
    break;
  case kColumnDefinition:
    handle_column_definition(root);
    break;
  case kCreateProcedure:
    handle_create_procedure(root);
    break;
  case kCreateFunction:
    handle_create_function(root);
    break;
  case kCreateUdf:
    handle_create_udf(root);
    break;
  case kCreateIndex:
    handle_create_index(root);
    break;
  case kIndexNameAndType:
    handle_index_name_and_type(root);
    break;
  case kCreateIndexTarget:
    handle_create_index_target(root);
    break;
  case kCreateServer:
    handle_create_server(root);
    break;
  case kCreateTablespace:
    handle_create_tablespace(root);
    break;
  case kCreateUndoTablespace:
    handle_create_undo_tablespace(root);
    break;
  case kCreateView:
    handle_create_view(root);
    break;
  case kCreateTrigger:
    handle_create_trigger(root);
    break;
  case kCreateEvent:
    handle_create_event(root);
    break;
  case kDropDatabase:
    handle_drop_database(root);
    break;
  case kDropEvent:
    handle_drop_event(root);
    break;
  case kDropFunction:
    handle_drop_function(root);
    break;
  case kDropProcedure:
    handle_drop_procedure(root);
    break;
  case kDropIndex:
    handle_drop_index(root);
    break;
  case kDropServer:
    handle_drop_server(root);
    break;
  case kDropTable:
    handle_drop_table(root);
    break;
  case kDropTableSpace:
    handle_drop_tablespace(root);
    break;
  case kDropUndoTablespace:
    handle_drop_undo_tablespace(root);
    break;
  case kDropTrigger:
    handle_drop_trigger(root);
    break;
  case kDropView:
    handle_drop_view(root);
    break;
  case kRenameTableStatement:
    handle_rename_table_statement(root);
    break;
  case kTruncateTableStatement:
    handle_truncate_table_statement(root);
    break;
  case kCallStatement:
    handle_call_statement(root);
    break;
  case kDeleteStatement:
    handle_delete_statement(root);
    break;
  case kPartitionDelete:
    handle_partition_delete(root);
    break;
  case kHandlerStatement:
    handle_handler_statement(root);
    break;
  case kHandlerReadOrScan:
    handle_handler_read_or_scan(root);
    break;

  default:
    // Do nothing.
    break;
  }

  return;

}

void MySQLIRConstructor::set_iden_type_from_pure_iden(IR* in, DATATYPE data_type, DATAFLAG data_flag) {
  assert(in->get_ir_type() == kPureIdentifier);

  IR* iden_node = in->get_left();
  iden_node->set_ir_type(kIdentifier);
  iden_node->set_data_type(data_type);
  iden_node->set_data_flag(data_flag);

}

void MySQLIRConstructor::set_iden_type_from_qualified_iden(IR* in, DATATYPE data_type, DATAFLAG data_flag) {
  assert(in->get_ir_type() == kQualifiedIdentifier);

  vector<IR*> v_iden_node = IRWrapper::get_ir_node_in_stmt_with_type(in, kIdentifier, false, false);

  // TODO: Not sure here. Need more testing.
  IR* cur_iden = v_iden_node.back();
  cur_iden->set_data_type(kDataFunctionName);
  cur_iden->set_data_flag(kFlagUnknown);

}

void MySQLIRConstructor::handle_function_call(IR* root) {

  vector<IR*> v_pure_iden = IRWrapper::get_ir_node_in_stmt_with_type(root, kPureIdentifier, false, false);
  if (!v_pure_iden.empty()) {
    this->set_iden_type_from_pure_iden(v_pure_iden.front(), kDataFunctionName, kFlagUnknown);
    return;
  }

  vector<IR*> v_qualified_iden = IRWrapper::get_ir_node_in_stmt_with_type(root, kQualifiedIdentifier, false, false);
  if (!v_qualified_iden.empty()) {
    this->set_iden_type_from_qualified_iden(v_qualified_iden.front(), kDataFunctionName, kFlagUnknown);
    return;
  }
}

void MySQLIRConstructor::handle_label_node(IR* node) {
  vector<IR*> v_pure_iden = IRWrapper::get_ir_node_in_stmt_with_type(node, kPureIdentifier, false, false);
  if (v_pure_iden.empty()) {
    return;
  }

  IR* pure_iden = v_pure_iden.front();
  this->set_iden_type_from_pure_iden(pure_iden, kDataLabelName, kFlagUnknown);

}

void MySQLIRConstructor::handle_role_iden_node(IR* node) {
  vector<IR*> v_pure_iden = IRWrapper::get_ir_node_in_stmt_with_type(node, kPureIdentifier, false, false);
  if (v_pure_iden.empty()) {
    return;
  }

  IR* pure_iden = v_pure_iden.front();
  this->set_iden_type_from_pure_iden(pure_iden, kDataLabelName, kFlagUnknown);

}

void MySQLIRConstructor::handle_identifier_non_term_rule_node(IR* node, DATATYPE data_type, DATAFLAG data_flag) {
  vector<IR*> v_pure_iden = IRWrapper::get_ir_node_in_stmt_with_type(node, kPureIdentifier, false, false);
  if (v_pure_iden.empty()) {
    return;
  }

  IR* pure_iden = v_pure_iden.front();
  this->set_iden_type_from_pure_iden(pure_iden, data_type, data_flag);
}

void MySQLIRConstructor::handle_lvalue_iden(IR* node) {
  vector<IR*> v_pure_iden = IRWrapper::get_ir_node_in_stmt_with_type(node, kPureIdentifier, false, false);
  if (v_pure_iden.empty()) {
    return;
  }

  IR* pure_iden = v_pure_iden.front();
  this->set_iden_type_from_pure_iden(pure_iden, kDataVarName, kFlagUnknown);
}

void MySQLIRConstructor::handle_size_number(IR* node) {
  vector<IR*> v_pure_iden = IRWrapper::get_ir_node_in_stmt_with_type(node, kPureIdentifier, false, false);
  if (v_pure_iden.empty()) {
    return;
  }

  IR* pure_iden = v_pure_iden.front();
  IR* new_int_literal = new IR(kIntLiteral, string(" 100 "));
  node->swap_node(pure_iden, new_int_literal);
  pure_iden->deep_drop();

}

void MySQLIRConstructor::handle_alter_event(IR* node) {
  vector<IR*> v_iden_non_term = IRWrapper::get_ir_node_in_stmt_with_type_one_level(node, kIdentifierRule);

  if(v_iden_non_term.empty()) {
    return;
  }

  IR* iden_non_term = v_iden_non_term.front();
  handle_identifier_non_term_rule_node(iden_non_term, kDataEventName, kDefine);

}

void MySQLIRConstructor::handle_alter_partition(IR* node) {
  vector<IR*> v_iden_non_term = IRWrapper::get_ir_node_in_stmt_with_type_one_level(node, kIdentifierRule);

  if(v_iden_non_term.empty()) {
    return;
  }

  IR* iden_non_term = v_iden_non_term.front();
  handle_identifier_non_term_rule_node(iden_non_term, kDataPartitionName, kUse);

}

void MySQLIRConstructor::handle_column_internal_ref(IR* node, DATATYPE data_type, DATAFLAG data_flag) {
  assert(node->get_ir_type() == kColumnInternalRef && node->get_left() != nullptr);

  IR* iden_non_term = node->get_left();
  handle_identifier_non_term_rule_node(iden_non_term, data_type, data_flag);

}

void MySQLIRConstructor::handle_table_name_node(IR* node, DATAFLAG data_flag) {
  vector<IR*> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(node, kIdentifier, false, false);
  assert(!v_iden.empty());

  IR* iden_node = v_iden.back();
  iden_node->set_data_type(kDataTableName);
  iden_node->set_data_flag(data_flag);

}

void MySQLIRConstructor::handle_index_ref_node(IR* node, DATAFLAG data_flag) {
  vector<IR*> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(node, kIdentifier, false, false);
  assert(!v_iden.empty());

  IR* iden_node = v_iden.back();
  iden_node->set_data_type(kDataIndexName);
  iden_node->set_data_flag(data_flag);

}



void MySQLIRConstructor::handle_alter_list_item(IR* node) {

  string tmp_str = node->to_string();

  DATATYPE prev_data_type = kDataWhatever, data_type = kDataWhatever;
  DATAFLAG prev_data_flag = kFlagUnknown, data_flag = kFlagUnknown;
  if (findStringIn(tmp_str, "ADD") && findStringIn(tmp_str, "COLUMN")) {
    data_type = kDataColumnName;
    data_flag = kDefine;
  } else if (findStringIn(tmp_str, "COLUMN") && findStringIn(tmp_str, "CHANGE") || findStringIn(tmp_str, "MODIFY")) {
    data_type = kDataColumnName;
    data_flag = kUndefine;
    data_type = kDataColumnName;
    data_flag = kDefine;
  } else if (findStringIn(tmp_str, "DROP") && findStringIn(tmp_str, "COLUMN")) {
    data_type = kDataColumnName;
    data_flag = kUndefine;
  } else if (findStringIn(tmp_str, "DROP") && findStringIn(tmp_str, "CHECK")) {
    prev_data_type = kDataColumnName;
    prev_data_flag = kUse;
    data_type = kDataConstraintName;
    data_flag = kUndefine;
  } else if (findStringIn(tmp_str, "DROP") && findStringIn(tmp_str, "CONSTRAINT")) {
    prev_data_type = kDataColumnName;
    prev_data_flag = kUse;
    data_type = kDataConstraintName;
    data_flag = kUndefine;
  } else if (findStringIn(tmp_str, "ALTER") && findStringIn(tmp_str, "COLUMN")) {
    prev_data_type = kDataColumnName;
    prev_data_flag = kUse;
  } else if (findStringIn(tmp_str, "ALTER") && findStringIn(tmp_str, "CHECK") || findStringIn(tmp_str, "CONSTRAINT")) {
    data_type = kDataConstraintName;
    data_flag = kUse;
  } else if (findStringIn(tmp_str, "ALTER") && findStringIn(tmp_str, "RENAME") && findStringIn(tmp_str, "COLUMN")) {
    prev_data_type = kDataColumnName;
    prev_data_flag = kUndefine;
    data_type = kDataConstraintName;
    data_flag = kDefine;
  } else if (findStringIn(tmp_str, "RENAME")) {
    // only rename, no RENAME COLUMN
    vector<IR*> v_table_name = IRWrapper::get_ir_node_in_stmt_with_type_one_level(node, kTableName);
    if (v_table_name.empty()) {
      return;
    } else {
      IR* table_name_node = v_table_name.front();
      this->handle_table_name_node(table_name_node, kDefine);
    }
  } else if (findStringIn(tmp_str, "RENAME") && findStringIn(tmp_str, "KEY") || findStringIn(tmp_str, "INDEX")) {
    vector<IR*> v_index_ref = IRWrapper::get_ir_node_in_stmt_with_type(node, kIndexRef, false, false);
    if (!v_index_ref.empty()) {
      this->handle_index_ref_node(v_index_ref.back(), kUndefine);
    }
    vector<IR*> v_index_name = IRWrapper::get_ir_node_in_stmt_with_type(node, kIndexName, false, false);
    if (!v_index_name.empty()) {
      this->handle_index_name_node(v_index_name.back(), kDefine);
    }
  }

  vector<IR*> v_column_internal = IRWrapper::get_ir_node_in_stmt_with_type_one_level(node, kColumnInternalRef);
  vector<IR*> v_iden_non_term = IRWrapper::get_ir_node_in_stmt_with_type_one_level(node, kIdentifierRule);

  if (!v_column_internal.empty()) {
    handle_column_internal_ref(v_column_internal.front(), prev_data_type, prev_data_flag);
  }

  if (!v_iden_non_term.empty()) {
    handle_identifier_non_term_rule_node(v_iden_non_term.front(), data_type, data_flag);
  }

}

void MySQLIRConstructor::handle_place(IR* node) {
  vector<IR*> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(node, kIdentifierRule, false, false);
  if (v_iden.empty()) {
    return;
  }

  this->handle_identifier_non_term_rule_node(v_iden.back(), kDataColumnName, kUse);

}

void MySQLIRConstructor::handle_alter_order_list(IR* node) {
  vector<IR*> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(node, kIdentifierRule, false, false);
  if (v_iden.empty()) {
    return;
  }

  for (IR* iden : v_iden)
    this->handle_identifier_non_term_rule_node(iden, kDataColumnName, kUse);

}

void MySQLIRConstructor::handle_alter_algorithm_option(IR* node) {
  vector<IR*> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(node, kIdentifierRule, false, false);
  if (v_iden.empty()) {
    return;
  }

  for (IR* iden : v_iden) {
    switch (get_rand_int(4)) {
    case 0:
      iden->set_str_val("DEFAULT");
      break;
    case 1:
      iden->set_str_val("INSTANT");
      break;
    case 2:
      iden->set_str_val("INPLACE");
      break;
    case 3:
      iden->set_str_val("COPY");
      break;
    }
  }

}


void MySQLIRConstructor::handle_alter_lock_option(IR* node) {
  vector<IR*> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(node, kIdentifierRule, false, false);
  if (v_iden.empty()) {
    return;
  }

  for (IR* iden : v_iden) {
    switch (get_rand_int(4)) {
    case 0:
      iden->set_str_val("DEFAULT");
      break;
    case 1:
      iden->set_str_val("NONE");
      break;
    case 2:
      iden->set_str_val("SHARED");
      break;
    case 3:
      iden->set_str_val("EXCLUSIVE");
      break;
    }
  }

}

void MySQLIRConstructor::handle_all_or_partition_name_list(IR* node, DATAFLAG data_flag) {
  vector<IR*> v_iden_list = IRWrapper::get_ir_node_in_stmt_with_type(node, kIdentifierList, false, false);
  if (!v_iden_list.empty()) {
    this->handle_identifier_list(v_iden_list.front(), kDataPartitionName, data_flag);
  }
}

void MySQLIRConstructor::handle_identifier_list(IR* node, DATATYPE data_type, DATAFLAG data_flag) {

  vector<IR*> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(node, kIdentifierRule, false, false);
  for (IR* iden : v_iden) {
    iden->set_data_type(data_type);
    iden->set_data_flag(data_flag);
  }

}

void MySQLIRConstructor::handle_tablespace_ref_node(IR* node, DATAFLAG data_flag) {
  vector<IR*> v_table_space_iden = IRWrapper::get_ir_node_in_stmt_with_type_one_level(node, kIdentifierRule);
  assert(!v_table_space_iden.empty());
  this->handle_identifier_non_term_rule_node(v_table_space_iden.front(), kDataTableSpaceName, data_flag);
}

void MySQLIRConstructor::handle_alter_table_space(IR* node) {

  vector<IR*> v_tablespace_rev = IRWrapper::get_ir_node_in_stmt_with_type(node, kTablespaceRef, false, false);
  vector<IR*> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(node, kIdentifierRule, false, false);

  for (IR* iden_rev: v_tablespace_rev) {
   this->handle_tablespace_ref_node(iden_rev, kUndefine);
  }

  for (IR* iden : v_iden) {
    iden->set_data_type(kDataTableSpaceName);
    iden->set_data_flag(kDefine);
  }

}

void MySQLIRConstructor::handle_alter_undo_table_space(IR* node) {

  vector<IR*> v_tablespace_rev = IRWrapper::get_ir_node_in_stmt_with_type(node, kTablespaceRef, false, false);

  for (IR* iden_rev: v_tablespace_rev) {
    this->handle_tablespace_ref_node(iden_rev, kUse);
  }

}

void MySQLIRConstructor::handle_view_ref(IR* node, DATAFLAG data_flag) {

  vector<IR*> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(node, kIdentifierRule, false, false);

  assert(!v_iden.empty());

  this->handle_identifier_non_term_rule_node(v_iden.front(), kDataViewName, data_flag);

}

void MySQLIRConstructor::handle_alter_view(IR* node) {

  vector<IR*> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(node, kViewRef, false, false);

  assert(!v_iden.empty());

  // TODO:: NOT SURE.
  this->handle_view_ref(v_iden.front(), kDefine);

}

void MySQLIRConstructor::handle_column_internal_ref_list(IR* node, DATAFLAG data_flag) {
  vector<IR*> v_column_inter_ref = IRWrapper::get_ir_node_in_stmt_with_type(node, kColumnInternalRef, false, false);

  for (IR* col : v_column_inter_ref) {
    this->handle_column_internal_ref(col, kDataColumnName, data_flag);
  }
}

void MySQLIRConstructor::handle_view_tail(IR* node) {

  vector<IR*> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(node, kColumnInternalRefList, false, false);

  for (IR* iden: v_iden) {
    this->handle_column_internal_ref_list(iden, kDefine);
  }

}

void MySQLIRConstructor::handle_schema_name_node(IR* node, DATAFLAG data_flag) {
  vector<IR*> v_iden = IRWrapper::get_ir_node_in_stmt_with_type_one_level(node, kIdentifierRule);
  assert(!v_iden.empty());

  handle_identifier_non_term_rule_node(v_iden.front(), kDataDatabase, data_flag);
}

void MySQLIRConstructor::handle_create_database(IR* node) {

  vector<IR*> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(node, kSchemaName, false, false);

  for (IR* iden: v_iden) {
    this->handle_schema_name_node(iden, kDefine);
  }

}

void MySQLIRConstructor::handle_table_ref(IR* node, DATAFLAG data_flag) {
  vector<IR*> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(node, kIdentifierRule, false, false);
  assert(!v_iden.empty());

  this->handle_identifier_non_term_rule_node(v_iden.front(), kDataTableName, data_flag);
}

void MySQLIRConstructor::handle_create_table(IR* node) {

  vector<IR*> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(node, kTableName, false, false);

  for (IR* iden: v_iden) {
    this->handle_table_name_node(iden, kDefine);
  }

  vector<IR*> v_table_ref = IRWrapper::get_ir_node_in_stmt_with_type(node, kTableRef, false, false);

  for (IR* iden: v_table_ref) {
    this->handle_table_ref(iden, kUse);
  }

}

void MySQLIRConstructor::handle_column_name_node(IR* node, DATAFLAG data_flag) {
  vector<IR*> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(node, kIdentifierRule, false, false);
  assert(!v_iden.empty());

  this->handle_identifier_non_term_rule_node(v_iden.front(), kDataColumnName, data_flag);
}

void MySQLIRConstructor::handle_column_definition(IR* node) {
  vector<IR*> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(node, kColumnName, false, false);

  assert(!v_iden.empty());

  this->handle_column_name_node(v_iden.front(), kDefine);

}

void MySQLIRConstructor::handle_procedure_name_node(IR* node, DATAFLAG data_flag) {
  vector<IR*> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(node, kIdentifierRule, false, false);
  assert(!v_iden.empty());

  this->handle_identifier_non_term_rule_node(v_iden.front(), kDataProcedureName, data_flag);
}

void MySQLIRConstructor::handle_create_procedure(IR* node) {

  vector<IR*> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(node, kProcedureName, false, false);

  for (IR* iden: v_iden) {
    this->handle_procedure_name_node(iden, kDefine);
  }

}

void MySQLIRConstructor::handle_function_name_node(IR* node, DATAFLAG data_flag) {
  vector<IR*> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(node, kIdentifierRule, false, false);
  assert(!v_iden.empty());

  this->handle_identifier_non_term_rule_node(v_iden.front(), kDataFunctionName, data_flag);
}

void MySQLIRConstructor::handle_create_function(IR* node) {

  vector<IR*> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(node, kFunctionName, false, false);

  for (IR* iden: v_iden) {
    this->handle_function_name_node(iden, kUse);
  }

}

void MySQLIRConstructor::handle_create_udf(IR* node) {
  // Reuse the create function name type.

  vector<IR*> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(node, kUdfName, false, false);

  for (IR* iden: v_iden) {
    this->handle_function_name_node(iden, kDefine);
  }

}


void MySQLIRConstructor::handle_index_name_node(IR* node, DATAFLAG data_flag) {
  vector<IR*> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(node, kIdentifierRule, false, false);
  assert(!v_iden.empty());

  this->handle_identifier_non_term_rule_node(v_iden.front(), kDataIndexName, data_flag);
}

void MySQLIRConstructor::handle_create_index(IR* node) {

  vector<IR*> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(node, kIndexName, false, false);

  for (IR* iden: v_iden) {
    this->handle_index_name_node(iden, kDefine);
  }

}

void MySQLIRConstructor::handle_index_name_and_type(IR* node) {

  vector<IR*> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(node, kIndexName, false, false);

  for (IR* iden: v_iden) {
    this->handle_index_name_node(iden, kDefine);
  }

}

void MySQLIRConstructor::handle_create_index_target(IR* node) {
  vector<IR*> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(node, kTableRef, false, false);

  assert(!v_iden.empty());

  this->handle_index_ref_node(v_iden.front(), kDefine);

}

void MySQLIRConstructor::handle_server_name(IR* node, DATAFLAG data_flag) {
  vector<IR*> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(node, kIdentifierRule, false, false);

  assert(!v_iden.empty());

  this->handle_identifier_non_term_rule_node(v_iden.front(), kDataServerName, data_flag);

}

void MySQLIRConstructor::handle_create_server(IR* node) {
  vector<IR*> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(node, kServerName, false, false);

  assert(!v_iden.empty());

  this->handle_server_name(v_iden.front(), kDefine);

}

void MySQLIRConstructor::handle_text_or_identifier(IR* node, DATATYPE data_type, DATAFLAG data_flag) {
  vector<IR*> v_pure_iden = IRWrapper::get_ir_node_in_stmt_with_type(node, kPureIdentifier, false, false);
  if (v_pure_iden.empty()) {
    return;
  }

  IR* pure_iden = v_pure_iden.front();
  this->set_iden_type_from_pure_iden(pure_iden, data_type, data_flag);
}


void MySQLIRConstructor::handle_table_space_name(IR* node, DATAFLAG data_flag) {
  vector<IR*> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(node, kIdentifierRule, false, false);

  assert(!v_iden.empty());

  this->handle_identifier_non_term_rule_node(v_iden.front(), kDataTableSpaceName, data_flag);

}

void MySQLIRConstructor::handle_create_tablespace(IR* node) {
  vector<IR*> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(node, kTablespaceName, false, false);

  assert(!v_iden.empty());

  this->handle_table_space_name(v_iden.front(), kDefine);

}


void MySQLIRConstructor::handle_create_undo_tablespace(IR* node) {
  vector<IR *> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(
      node, kTablespaceName, false, false);

  assert(!v_iden.empty());

  this->handle_table_space_name(v_iden.front(), kDefine);
}

void MySQLIRConstructor::handle_view_name(IR* node, DATAFLAG data_flag) {
  vector<IR*> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(node, kIdentifierRule, false, false);

  assert(!v_iden.empty());

  this->handle_identifier_non_term_rule_node(v_iden.front(), kDataViewName, data_flag);

}

void MySQLIRConstructor::handle_create_view(IR* node) {
  vector<IR *> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(
      node, kViewName, false, false);

  assert(!v_iden.empty());

  this->handle_view_name(v_iden.front(), kDefine);

  v_iden = IRWrapper::get_ir_node_in_stmt_with_type(
      node, kViewTail, false, false);
  assert(!v_iden.empty());
  this->handle_view_tail(v_iden.front());
}


void MySQLIRConstructor::handle_trigger_name(IR* node, DATAFLAG data_flag) {
  vector<IR*> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(node, kIdentifierRule, false, false);

  assert(!v_iden.empty());

  this->handle_identifier_non_term_rule_node(v_iden.front(), kDataTriggerName, data_flag);

}

void MySQLIRConstructor::handle_create_trigger(IR* node) {
  vector<IR *> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(
      node, kTriggerName, false, false);

  assert(!v_iden.empty());

  this->handle_trigger_name(v_iden.front(), kDefine);

  v_iden = IRWrapper::get_ir_node_in_stmt_with_type(
      node, kTableRef, false, false);

  assert(!v_iden.empty());

  this->handle_table_ref(v_iden.front(), kUse);

}


void MySQLIRConstructor::handle_event_name(IR* node, DATAFLAG data_flag) {
  vector<IR*> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(node, kIdentifierRule, false, false);

  assert(!v_iden.empty());

  this->handle_identifier_non_term_rule_node(v_iden.front(), kDataEventName, data_flag);

}

void MySQLIRConstructor::handle_create_event(IR* node) {
  vector<IR *> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(
      node, kEventName, false, false);

  assert(!v_iden.empty());

  this->handle_event_name(v_iden.front(), kDefine);
}

void MySQLIRConstructor::handle_drop_database(IR* node) {
  vector<IR *> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(
      node, kSchemaRef, false, false);

  assert(!v_iden.empty());

  this->handle_schema_name_node(v_iden.front(), kUndefine);

}

void MySQLIRConstructor::handle_drop_event(IR* node) {
  vector<IR *> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(
      node, kEventRef, false, false);

  assert(!v_iden.empty());

  this->handle_event_name(v_iden.front(), kUndefine);

}

void MySQLIRConstructor::handle_drop_function(IR* node) {
  vector<IR *> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(
      node, kFunctionRef, false, false);

  assert(!v_iden.empty());

  this->handle_function_name_node(v_iden.front(), kUndefine);

}

void MySQLIRConstructor::handle_drop_procedure(IR* node) {
  vector<IR *> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(
      node, kProcedureRef, false, false);

  assert(!v_iden.empty());

  this->handle_procedure_name_node(v_iden.front(), kUndefine);

}

void MySQLIRConstructor::handle_drop_index(IR* node) {
  vector<IR *> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(
      node, kIndexRef, false, false);

  assert(!v_iden.empty());

  this->handle_index_ref_node(v_iden.front(), kUndefine);

}

void MySQLIRConstructor::handle_drop_server(IR* node) {
  vector<IR *> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(
      node, kServerRef, false, false);

  assert(!v_iden.empty());

  this->handle_server_name(v_iden.front(), kUndefine);

}

void MySQLIRConstructor::handle_drop_table(IR* node) {
  vector<IR *> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(
      node, kTableRef, false, false);

  assert(!v_iden.empty());

  this->handle_table_ref(v_iden.front(), kUndefine);

}

void MySQLIRConstructor::handle_drop_tablespace(IR* node) {
  vector<IR *> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(
      node, kTablespaceRef, false, false);

  assert(!v_iden.empty());

  this->handle_tablespace_ref_node(v_iden.front(), kUndefine);

}

void MySQLIRConstructor::handle_drop_trigger(IR* node) {
  vector<IR *> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(
      node, kTriggerRef, false, false);

  assert(!v_iden.empty());

  this->handle_trigger_name(v_iden.front(), kUndefine);

}

void MySQLIRConstructor::handle_view_ref_list(IR* node, DATAFLAG data_flag) {
  vector<IR *> v_view = IRWrapper::get_ir_node_in_stmt_with_type(
      node, kViewRef, false, false);

  for (IR* view_ref: v_view) {
    this->handle_view_ref(view_ref, data_flag);
  }

}

void MySQLIRConstructor::handle_drop_view(IR* node) {
  vector<IR *> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(
      node, kViewRefList, false, false);

  assert(!v_iden.empty());

  this->handle_view_ref_list(v_iden.front(), kUndefine);

}

void MySQLIRConstructor::handle_drop_undo_tablespace(IR* node) {
  vector<IR *> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(
      node, kTablespaceRef, false, false);

  assert(!v_iden.empty());

  this->handle_tablespace_ref_node(v_iden.front(), kUndefine);

}

void MySQLIRConstructor::handle_rename_pair(IR* node, DATATYPE data_type) {
  vector<IR*> v_table_ref = IRWrapper::get_ir_node_in_stmt_with_type_one_level(node, kTableRef);
  vector<IR*> v_table_name = IRWrapper::get_ir_node_in_stmt_with_type_one_level(node, kTableName);
  assert(!v_table_ref.empty());
  assert(!v_table_name.empty());

  handle_table_ref(v_table_ref.front(), kUndefine);
  handle_table_name_node(v_table_name.front(), kDefine);
}

void MySQLIRConstructor::handle_rename_table_statement(IR* node) {
  vector<IR *> v_iden = IRWrapper::get_ir_node_in_stmt_with_type_one_level(
      node, kRenamePair);

  assert(!v_iden.empty());

  for (IR* cur_iden: v_iden) {
    this->handle_rename_pair(cur_iden, kDataTableName);
  }

}

void MySQLIRConstructor::handle_truncate_table_statement(IR* node) {
  vector<IR *> v_iden = IRWrapper::get_ir_node_in_stmt_with_type_one_level(
      node, kTableRef);

  assert(!v_iden.empty());

  for (IR* cur_iden: v_iden) {
    this->handle_table_ref(cur_iden, kUse);
  }

}


void MySQLIRConstructor::handle_call_statement(IR* node) {
  vector<IR *> v_iden = IRWrapper::get_ir_node_in_stmt_with_type_one_level(
      node, kProcedureRef);

  assert(!v_iden.empty());

  for (IR* cur_iden: v_iden) {
    this->handle_procedure_name_node(cur_iden, kUse);
  }

}

void MySQLIRConstructor::handle_table_ref_with_wildcard(IR* node, DATATYPE data_type, DATAFLAG data_flag) {
  vector<IR*> v_iden = IRWrapper::get_ir_node_in_stmt_with_type(node, kIdentifierRule);

  assert(!v_iden.empty());

  this->handle_identifier_non_term_rule_node(v_iden.front(), kDataAliasTableName, kUse);
}

void MySQLIRConstructor::handle_table_alias_ref_list(IR* node, DATAFLAG data_flag) {

  vector<IR*> v_table_ref_with_wild =
      IRWrapper::get_ir_node_in_stmt_with_type(node, kTableRefWithWildcard, false, false);

  assert(!v_table_ref_with_wild.empty());

  for (IR* cur_v: v_table_ref_with_wild) {
    // TODO: Not sure here.
    this->handle_table_ref_with_wildcard(cur_v, kDataAliasTableName, data_flag);
  }

}

void MySQLIRConstructor::handle_table_alias(IR* node, DATAFLAG data_flag) {

  vector<IR*> v_iden =
      IRWrapper::get_ir_node_in_stmt_with_type_one_level(node, kIdentifierRule);

  assert(!v_iden.empty());

  for (IR* cur_v: v_iden) {
    // TODO: Not sure here.
    this->handle_identifier_non_term_rule_node(cur_v, kDataAliasTableName, data_flag);
  }

}

void MySQLIRConstructor::handle_table_reference_list(IR* node, DATAFLAG data_flag) {

  vector<IR *> v_table_ref = IRWrapper::get_ir_node_in_stmt_with_type(
      node, kTableReference, false, false);

  assert(!v_table_ref.empty());

  for (IR *cur_v : v_table_ref) {
    // TODO: Not sure here.
    this->handle_table_ref(cur_v, kUse);
  }

}

void MySQLIRConstructor::handle_delete_statement(IR* node) {
  vector<IR *> v_table_alias_ref_list = IRWrapper::get_ir_node_in_stmt_with_type_one_level(
      node, kTableAliasRefList);

  for (IR* cur_iden: v_table_alias_ref_list) {
    this->handle_table_alias_ref_list(cur_iden, kUse);
  }

  vector<IR *> v_table_reference_list = IRWrapper::get_ir_node_in_stmt_with_type_one_level(
      node, kTableReferenceList);


  for (IR* cur_iden: v_table_reference_list) {
    this->handle_table_reference_list(cur_iden, kUse);
  }

  vector<IR *> v_table_ref = IRWrapper::get_ir_node_in_stmt_with_type_one_level(
      node, kTableRef);

  for (IR* cur_iden: v_table_ref) {
    this->handle_table_ref(cur_iden, kUse);
  }

  for (IR* cur_iden: v_table_reference_list) {
    this->handle_table_reference_list(cur_iden, kUse);
  }

  vector<IR *> v_table_alias = IRWrapper::get_ir_node_in_stmt_with_type_one_level(
      node, kTableAlias);

  for (IR* cur_iden: v_table_alias) {
    this->handle_table_alias(cur_iden, kDefine);
  }

}

void MySQLIRConstructor::handle_partition_delete(IR* node) {
  vector<IR *> v_iden_list = IRWrapper::get_ir_node_in_stmt_with_type_one_level(
      node, kIdentifierList);

  for (IR* cur_iden: v_iden_list) {
    this->handle_identifier_list(cur_iden, kDataPartitionName, kUndefine);
  }
}

void MySQLIRConstructor::handle_handler_statement(IR* node) {
  vector<IR *> v_table_ref = IRWrapper::get_ir_node_in_stmt_with_type_one_level(
      node, kTableRef);

  for (IR* cur_iden: v_table_ref) {
    this->handle_table_ref(cur_iden, kUse);
  }

  vector<IR *> v_table_alias = IRWrapper::get_ir_node_in_stmt_with_type_one_level(
      node, kTableAlias);

  for (IR* cur_iden: v_table_alias) {
    this->handle_table_alias(cur_iden, kDefine);
  }

  vector<IR *> v_iden = IRWrapper::get_ir_node_in_stmt_with_type_one_level(
      node, kIdentifierRule);

  for (IR* cur_iden: v_iden) {
    this->handle_identifier_non_term_rule_node(cur_iden, kDataTableName, kUse);
  }
}

void MySQLIRConstructor::handle_handler_read_or_scan(IR* node) {
  vector<IR *> v_iden = IRWrapper::get_ir_node_in_stmt_with_type_one_level(
      node, kIdentifierRule);

  for (IR* cur_iden: v_iden) {
    this->handle_identifier_non_term_rule_node(cur_iden, kDataIndexName, kUse);
  }
}