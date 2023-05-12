#include "MySQL_IR_constructor.h"

IR* MySQLIRConstructor::gen_node_ir(vector<antlr4::tree::ParseTree*> v_children, IRTYPE ir_type) {

  vector<MySQLIRConstructor::ParseTreeTypeEnum> v_children_type; // 0 for terminated token, 1 for non-term rule.

  for (int i = 0; i < v_children.size(); i++) {
    v_children_type.push_back(this->is_parser_tree_node_terminated(v_children[i]) ? TOKEN : RULE);
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
    prefix += this->get_terminated_token_str(v_children[idx]);
    idx++;
  }
  // Left
  if (idx < v_children_type.size()) {
    left = this->get_rule_returned_ir(v_children[idx]);
    idx++;
  }
  // middle str
  while (idx < v_children_type.size() && v_children_type[idx] == TOKEN) {
    middle += this->get_terminated_token_str(v_children[idx]);
    idx++;
  }
  // right
  if (idx < v_children_type.size()) {
    right = this->get_rule_returned_ir(v_children[idx]);
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
      middle += this->get_terminated_token_str(v_children[idx]);
      idx++;
    }
    // right
    if (idx < v_children_type.size()) {
      right = this->get_rule_returned_ir(v_children[idx]);
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