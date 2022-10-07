#include <iostream>

#include "../include/utils.h"
#include "json.hpp"
#include "json_ir_convertor.h"

using json = nlohmann::json;
using std::cout, std::cerr, std::endl;

IRTYPE get_ir_type_by_idx(int idx) { return static_cast<IRTYPE>(idx); }

DATATYPE get_data_type_by_idx(int idx) { return static_cast<DATATYPE>(idx); }

DATAFLAG get_data_flag_by_idx(int idx) { return static_cast<DATAFLAG>(idx); }

inline IR *convert_json_to_IR_helper(json curJsonNode, int depth) {

  // Recursive function.

  IRTYPE type = TypeUnknown;
  DATATYPE datatype = DataNone;
  DATAFLAG dataflag = ContextUnknown;
  IR *LNode = NULL, *RNode = NULL;
  string prefix = "", infix = "", suffix = "";
  string str = "";
  int i_val = 0;
  unsigned long u_val = 0;
  double f_val = 0.0;

  // special iterator member functions for objects
  for (json::iterator it = curJsonNode.begin(); it != curJsonNode.end(); ++it) {
    if (it.key() == "Prefix") {
      prefix = string(it.value());
      continue;
    } else if (it.key() == "Infix") {
      infix = string(it.value());
      continue;
    } else if (it.key() == "Suffix") {
      suffix = string(it.value());
      continue;
    } else if (it.key() == "LNode") {
      if (it.value().empty()) {
        LNode = NULL;
      } else {
        LNode = convert_json_to_IR_helper(it.value(), depth + 1);
      }
      continue;
    } else if (it.key() == "RNode") {
      if (it.value().empty()) {
        RNode = NULL;
      } else {
        RNode = convert_json_to_IR_helper(it.value(), depth + 1);
      }
      continue;
    } else if (it.key() == "IRType") {
      type = get_ir_type_by_idx(it.value());
      continue;
    } else if (it.key() == "DataType") {
      datatype = get_data_type_by_idx(it.value());
      continue;
    } else if (it.key() == "ContextFlag") {
      dataflag = get_data_flag_by_idx(it.value());
      continue;
    } else if (it.key() == "Str") {
      str = it.value();
      continue;
    } else if (it.key() == "IValue") {
      i_val = it.value();
      continue;
    } else if (it.key() == "UValue") {
      u_val = it.value();
      continue;
    } else if (it.key() == "FValue") {
      f_val = it.value();
      continue;
    } else {
      // pass and ignored.
      continue;
    }
  }

  IR *curRootIR;

  if (type == TypeIdentifier) {
    curRootIR = new IR(type, str, datatype, -1, dataflag);
    curRootIR->op_ = new IROperator("", "", "");
  } else if (type == TypeStringLiteral) {
    curRootIR = new IR(type, str);
    curRootIR->op_ = new IROperator("", "", "");
  } else if (type == TypeIntegerLiteral) {
    if (f_val != 0.0) {
      curRootIR = new IR(type, f_val);
    } else if (u_val != 0) {
      curRootIR = new IR(type, u_val);
    } else {
      curRootIR = new IR(type, i_val);
    }
    curRootIR->op_ = new IROperator("", "", "");
  } else if (type == TypeFloatLiteral) {
    if (f_val != 0.0) {
      curRootIR = new IR(type, f_val);
    } else if (u_val != 0) {
      curRootIR = new IR(type, u_val);
    } else {
      curRootIR = new IR(type, i_val);
    }
    curRootIR->op_ = new IROperator("", "", "");
  } else {
    IROperator *ir_opt = new IROperator(prefix, infix, suffix);
    curRootIR = new IR(type, ir_opt, LNode, RNode);
  }

  return curRootIR;
}

inline IR *construct_stmt_ir(IR *curNode) {
  IROperator *tmp_op = new IROperator("", "", "; ");
  return new IR(TypeStmt, tmp_op, curNode, NULL);
}

IR *construct_stmtlist_ir(vector<IR *> v_stmtlist) {
  IR *rootIR = NULL;

  int idx = 0;
  for (IR *curStmt : v_stmtlist) {
    if (idx == 0) {
      IR *lNode = construct_stmt_ir(curStmt);
      IR *rNode = NULL;
      string infix = "";

      // Left is TypeStmt. Right is NULL
      IROperator *tmp_opt = new IROperator("", infix, "");
      rootIR = new IR(TypeStmtList, tmp_opt, lNode, rNode);
    } else {
      // idx >= 1
      IR *rNode = construct_stmt_ir(curStmt);
      IROperator *tmp_opt = new IROperator("", "", "");

      // Left is previous stmts. Right is TypeStmt.
      rootIR = new IR(TypeStmtList, tmp_opt, rootIR, rNode);
    }
    ++idx;
  }

  if (rootIR == NULL) {
    return NULL;
  }

  IROperator *tmp_opt = new IROperator("", "", "");
  rootIR = new IR(TypeRoot, tmp_opt, rootIR, NULL);

  return rootIR;
}

IR *convert_json_to_IR(string all_json_str) {

  vector<string> json_str_lines = string_splitter(all_json_str, '\n');

  IR *retRootIR;
  vector<IR *> v_stmt_ir;

  for (const string &json_str : json_str_lines) {
    if (json_str.size() == 0 || json_str[0] != '{') {
      continue;
    }
    try {
      auto json_obj = json::parse(json_str);
      IR *tmp_stmt_IR = convert_json_to_IR_helper(json_obj, 0);
      v_stmt_ir.push_back(tmp_stmt_IR);
    } catch (json::parse_error &ex) {
      return NULL;
    }
  }

  retRootIR = construct_stmtlist_ir(v_stmt_ir);

  return retRootIR;
}
