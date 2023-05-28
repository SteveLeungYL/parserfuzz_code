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
    auto type = dynamic_cast<antlr4::tree::TerminalNode*>(child)->getSymbol()->getType();
    if (type == -1) {
        return "";
    } else if (type == MySQLParser::SEMICOLON_SYMBOL) {
        return ";";
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
      try {
        return any_cast<IR *>(visit(child));
      } catch (const std::bad_any_cast& e) {
        return new IR(kUnknown, OP3("", "", ""));
      }
    }
  }
  
  void set_iden_type_from_pure_iden(IR* in, DATATYPE data_type, DATAFLAG data_flag);
  void set_iden_type_from_qualified_iden(IR* in, DATATYPE data_type, DATAFLAG data_flag);
  void handle_function_call(IR*);
  void handle_label_node(IR* node);
  void handle_role_iden_node(IR* node);
  void handle_identifier_non_term_rule_node(IR* node, DATATYPE data_type, DATAFLAG data_flag);
  void handle_lvalue_iden(IR* node);
  void handle_size_number(IR* node);
  void handle_alter_event(IR* node);
  void handle_alter_partition(IR* node);
  void handle_column_internal_ref(IR* node, DATATYPE data_type, DATAFLAG data_flag);
  void handle_alter_list_item(IR* node);
  void handle_table_name_node(IR* node, DATAFLAG data_flag);
  void handle_index_ref_node(IR* node, DATAFLAG data_flag);
  void handle_place(IR* node);
  void handle_alter_order_list(IR* node);
  void handle_alter_algorithm_option(IR* node);
  void handle_alter_lock_option(IR* node);
  void handle_identifier_list(IR* node, DATATYPE data_type, DATAFLAG data_flag);
  void handle_identifier_list_with_parentheses(IR* node, DATATYPE data_type, DATAFLAG data_flag);
  void handle_all_or_partition_name_list(IR* node, DATAFLAG data_flag);
  void handle_tablespace_ref_node(IR* node, DATAFLAG data_flag);
  void handle_alter_table_space(IR* node);
  void handle_alter_undo_table_space(IR* node);
  void handle_view_ref(IR* node, DATAFLAG data_flag);
  void handle_alter_view(IR* node);
  void handle_column_internal_ref_list(IR* node, DATAFLAG data_flag);
  void handle_view_tail(IR* node);
  void handle_schema_name_node(IR* node, DATAFLAG data_flag);
  void handle_create_database(IR* node);
  void handle_create_table(IR* node);
  void handle_table_ref(IR* node, DATAFLAG data_flag);
  void handle_column_name_node(IR* node, DATAFLAG data_flag);
  void handle_column_definition(IR* node);
  void handle_procedure_name_node(IR* node, DATAFLAG data_flag);
  void handle_create_procedure(IR* node);
  void handle_function_name_node(IR* node, DATAFLAG data_flag);
  void handle_create_function(IR* node);
  void handle_create_udf(IR* node);
  void handle_index_name_node(IR* node, DATAFLAG data_flag);
  void handle_create_index(IR* node);
  void handle_index_name_and_type(IR* node);
  void handle_create_index_target(IR* node);
  void handle_server_name(IR* node, DATAFLAG data_flag);
  void handle_create_server(IR* node);
  void handle_text_or_identifier(IR* node, DATATYPE data_type, DATAFLAG data_flag);
  void handle_table_space_name(IR* node, DATAFLAG data_flag);
  void handle_create_tablespace(IR* node);
  void handle_create_undo_tablespace(IR* node);
  void handle_view_name(IR* node, DATAFLAG data_flag);
  void handle_create_view(IR* node);
  void handle_trigger_name(IR* node, DATAFLAG data_flag);
  void handle_create_trigger(IR* node);
  void handle_event_name(IR* node, DATAFLAG data_flag);
  void handle_create_event(IR* node);
  void handle_drop_database(IR* node);
  void handle_view_ref_list(IR* node, DATAFLAG data_flag);
  void handle_drop_event(IR* node);
  void handle_drop_function(IR* node);
  void handle_drop_procedure(IR* node);
  void handle_drop_index(IR* node);
  void handle_drop_server(IR* node);
  void handle_drop_table(IR* node);
  void handle_drop_tablespace(IR* node);
  void handle_drop_trigger(IR* node);
  void handle_drop_undo_tablespace(IR* node);
  void handle_drop_view(IR* node);
  void handle_rename_pair(IR* node, DATATYPE data_type);
  void handle_rename_table_statement(IR* node);
  void handle_truncate_table_statement(IR* node);
  void handle_call_statement(IR* node);
  void handle_table_ref_with_wildcard(IR* node, DATATYPE data_type, DATAFLAG data_flag);
  void handle_table_alias_ref_list(IR* node, DATAFLAG data_flag);
  void handle_table_alias(IR* node, DATAFLAG data_flag);
  void handle_table_reference_list(IR* node, DATAFLAG data_flag);
  void handle_table_reference(IR* node, DATAFLAG data_flag);
  void handle_delete_statement(IR* node);
  void handle_partition_delete(IR* node);
  void handle_handler_statement(IR* node);
  void handle_handler_read_or_scan(IR* node);
  void handle_insert_statement(IR* node);
  void handle_column_ref(IR* node, DATAFLAG data_flag);
  void handle_field_identifier(IR* node, DATATYPE data_type, DATAFLAG data_flag);
  void handle_fields(IR* node, DATAFLAG data_flag);
  void handle_insert_from_constructor(IR* node);
  void handle_load_statement(IR* node);
  void handle_field_or_variable_list(IR* node, DATAFLAG data_flag);
  void handle_load_data_target_list(IR* node);
  void handle_replace_statement(IR* node);
  void handle_explicit_table(IR* node);
  void handle_query_primary(IR* node);
  void handle_limit_option(IR* node);
  void handle_into_clause(IR* node);
  void handle_window_clause(IR* node);
  void handle_window_definition(IR* node);
  void handle_window_name(IR* node, DATAFLAG data_flag);
  void handle_window_spec_details(IR* node);
  void handle_common_table_expression(IR* node);
  void handle_from_clause(IR* node);
  void handle_locking_clause(IR* node);
  void handle_table_wild(IR* node, DATAFLAG data_flag);
  void handle_select_alias(IR* node, DATAFLAG data_flag);
  void handle_select_item(IR* node);
  void handle_joined_table(IR* node);
  void handle_single_table_parens(IR* node);
  void handle_single_table(IR* node, DATAFLAG data_flag);
  void handle_derived_table(IR* node);
  void handle_table_reference_list_parens(IR* node);
  void handle_table_function(IR* node);
  void handle_jt_column(IR* node);
  void handle_index_list_element(IR* node);
  void handle_update_statement(IR* node);
  void handle_savepoint_statement(IR* node);
  void handle_lock_item(IR* node);
  void handle_replication_load(IR* node);
  void handle_flush_tables(IR* node);
  void handle_describe_statement(IR* node);
  void handle_simple_expr_column_ref(IR* node);
  void handle_simple_identifier(IR* node);
  void handle_windowing_clause(IR* node);
  void handle_ident_list_arg(IR* node);
  void handle_table_constraint_def(IR* node);
  void handle_constraint_name(IR* node);
  void handle_references(IR* node);
  void handle_key_part(IR* node);

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