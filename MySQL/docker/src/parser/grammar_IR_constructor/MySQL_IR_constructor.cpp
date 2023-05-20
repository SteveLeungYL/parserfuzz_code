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