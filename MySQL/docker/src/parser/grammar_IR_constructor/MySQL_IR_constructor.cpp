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
// -- fieldIdentifier, insertIdentifier, identListArg.

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
  default:
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
