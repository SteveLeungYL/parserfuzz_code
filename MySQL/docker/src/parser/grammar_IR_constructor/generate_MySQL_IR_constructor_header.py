import os

prefix_str = """\
#ifndef ANTLR_TEST_MYSQLIRCONSTRUCTOR_H
#define ANTLR_TEST_MYSQLIRCONSTRUCTOR_H

// DO NOT MODIFY THIS FILE. 
// This code is generated from PYTHON script generate_MySQL_IR_constructor.h.
// Use ANTLR4 to generate the MySQLParserBaseVisitor.h in ../grammar/ before calling the python generation script.

#include <iostream>
#include <cstring>
#include <filesystem>
#include <typeinfo>
#include <vector>
#include <cassert>
#include <array>
#include <algorithm>

#include "../MySQLBaseCommon.h"
#include "../grammar/MySQLParserBaseVisitor.h"
#include "../../include/ast.h"
#include "all_rule_declares.h"

using namespace std;
using namespace parsers;

//#define DEBUG

#define FINDINARRAY(x, y) find(x.begin(), x.end(), y) != x.end()

class MySQLIRConstructor: public parsers::MySQLParserBaseVisitor {
private:

  MySQLParser* p_parser;

  enum ParseTreeTypeEnum{
    TOKEN = 0,
    RULE = 1,
    SPEC = 2 // Special handling. Identifier. Literals
  };

  array<int, 18> special_term_token_ir_type = {
#define DECLARE_TYPE(v) MySQLParser::v,
      ALLSPECIALTERMTOKENTYPE(DECLARE_TYPE)
#undef DECLARE_TYPE
  };

  bool is_special_term_token_ir_type(antlr4::tree::ParseTree* node) {
    auto *tmp = dynamic_cast<antlr4::tree::TerminalNode*>(node);
    if (tmp != nullptr) {
      // term token type
      if (FINDINARRAY(special_term_token_ir_type, tmp->getSymbol()->getType())) {
        // matched.
        return true;
      } else {
        // not matched.
        return false;
      }
    } else {
      // not a terminated token type.
      return false;
    }
  }

  IR* gen_node_ir(vector<antlr4::tree::ParseTree*>, IRTYPE);

  inline ParseTreeTypeEnum get_parser_tree_node_type_enum (antlr4::tree::ParseTree* child) {
    if (antlr4::ParserRuleContext* tmp = dynamic_cast<antlr4::ParserRuleContext*>(child)) {
      // has sub-rule.
      return RULE;
    } else {
      // terminated token.
      if (this->is_special_term_token_ir_type(child)) {
        // Identifiers, Literals.
        return SPEC;
      } else {
        return TOKEN;
      }
    }
  }

  inline string get_terminated_token_str(antlr4::tree::ParseTree* child) {
    string out_str = dynamic_cast<antlr4::tree::TerminalNode*>(child)->getSymbol()->getText();
    if (out_str == "<EOF>") {
        return "";
    } else {
        return out_str;
    }
  }

  inline IR* gen_special_terminated_token_ir(antlr4::tree::ParseTree* child) {
    auto spec_type = dynamic_cast<antlr4::tree::TerminalNode*>(child)->getSymbol()->getType();
    auto str = string(dynamic_cast<antlr4::tree::TerminalNode*>(child)->getSymbol()->getText());
    if (spec_type == MySQLParser::IDENTIFIER) {
      return new IR(kIdentifier, str, DATATYPE::kDataWhatever, 0, DATAFLAG::kFlagUnknown);
    } else if (spec_type == MySQLParser::SINGLE_QUOTED_TEXT) {
      return new IR(kStringLiteral, str, DATATYPE::kDataWhatever, 0, DATAFLAG::kFlagUnknown);
    } else if (spec_type == MySQLParser::DOUBLE_QUOTED_TEXT) {
      return new IR(kStringLiteral, str, DATATYPE::kDataWhatever, 0, DATAFLAG::kFlagUnknown);
    } else if (spec_type == MySQLParser::NCHAR_TEXT) {
      return new IR(kStringLiteral, str, DATATYPE::kDataWhatever, 0, DATAFLAG::kFlagUnknown);
    } else if (spec_type == MySQLParser::HEX_NUMBER) {
      return new IR(kIntLiteral, str, DATATYPE::kDataWhatever, 0, DATAFLAG::kFlagUnknown);
    } else if (spec_type == MySQLParser::BIN_NUMBER) {
      return new IR(kIntLiteral, str, DATATYPE::kDataWhatever, 0, DATAFLAG::kFlagUnknown);
    } else if (spec_type == MySQLParser::INT_NUMBER) {
      return new IR(kIntLiteral, str, DATATYPE::kDataWhatever, 0, DATAFLAG::kFlagUnknown);
    } else if (spec_type == MySQLParser::LONG_NUMBER) {
      return new IR(kIntLiteral, str, DATATYPE::kDataWhatever, 0, DATAFLAG::kFlagUnknown);
    } else if (spec_type == MySQLParser::ULONGLONG_NUMBER) {
      return new IR(kIntLiteral, str, DATATYPE::kDataWhatever, 0, DATAFLAG::kFlagUnknown);
    } else if (spec_type == MySQLParser::DECIMAL_NUMBER) {
      return new IR(kIntLiteral, str, DATATYPE::kDataWhatever, 0, DATAFLAG::kFlagUnknown);
    } else if (spec_type == MySQLParser::FLOAT_NUMBER) {
      return new IR(kFloatLiteral, str, DATATYPE::kDataWhatever, 0, DATAFLAG::kFlagUnknown);
    } else if (spec_type == MySQLParser::TRUE_SYMBOL) {
      return new IR(kBooleanLiteral, str, DATATYPE::kDataWhatever, 0, DATAFLAG::kFlagUnknown);
    } else if (spec_type == MySQLParser::FALSE_SYMBOL) {
      return new IR(kBooleanLiteral, str, DATATYPE::kDataWhatever, 0, DATAFLAG::kFlagUnknown);
    } else {
        // Unknown type. Kept unchanged. 
      return new IR(kLiteral, str, DATATYPE::kDataWhatever, 0, DATAFLAG::kFlagUnknown);
    }
  }

  inline IR* get_rule_returned_ir(antlr4::tree::ParseTree* child, ParseTreeTypeEnum type) {
    if (type == SPEC) {
      // Identifiers, Literals.
      return gen_special_terminated_token_ir(child);
    } else {
      // Other normal rules.
      return any_cast<IR *>(visit(child));
    }
  }
  
  void handle_function_call(IR*);

public:
  void set_parser(MySQLParser* in) {this->p_parser = in;}
  void special_handling_rule_name(IR*, IRTYPE);
  
"""

suffix_str = """\

};

#endif
"""

with open("../grammar/MySQLParserBaseVisitor.h", "r") as base_vis, open("MySQL_IR_constructor.h", "w") as fd:
    fd.write(prefix_str)

    for cur_line in base_vis.readlines():
        if "virtual std::any visit" not in cur_line:
            continue
        # Write the function signature
        fd.write(cur_line)

        # record the IR class name.
        rule_name_str = cur_line.split("virtual std::any visit")[1]
        rule_name_str = rule_name_str.split("(")[0]

        if rule_name_str == "Identifier":
            rule_name_str = "IdentifierRule"

        fd.write(f"    IR* root = this->gen_node_ir(ctx->children, k{rule_name_str}); \n")
        fd.write(f"    special_handling_rule_name(root, k{rule_name_str});\n")

        fd.write(f"    return root;\n  }}\n\n")

    fd.write(suffix_str)