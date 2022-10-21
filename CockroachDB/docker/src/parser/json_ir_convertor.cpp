#include <iostream>

#include "../include/utils.h"
#include "../include/json.hpp"
#include "../include/json_ir_convertor.h"

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
  DATAAFFINITYTYPE data_affi = AFFIUNKNOWN;
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
    } else if (it.key() == "DataAffinity") {
        data_affi = get_data_affinity_by_idx(it.value());
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
    curRootIR = new IR(type, str, datatype, dataflag);
    curRootIR->op_ = new IROperator("", "", "");
  } else if (type == TypeStringLiteral) {
    curRootIR = new IR(type, str, datatype, dataflag, data_affi);
    curRootIR->op_ = new IROperator("", "", "");
  } else if (type == TypeIntegerLiteral) {
    if (f_val != 0.0) {
      curRootIR = new IR(type, f_val, datatype, dataflag, data_affi);
    } else if (u_val != 0) {
      curRootIR = new IR(type, u_val, datatype, dataflag, data_affi);
    } else {
      curRootIR = new IR(type, i_val, datatype, dataflag, data_affi);
    }
    curRootIR->op_ = new IROperator("", "", "");
  } else if (type == TypeFloatLiteral) {
    if (f_val != 0.0) {
      curRootIR = new IR(type, f_val, datatype, dataflag, data_affi);
    } else if (u_val != 0) {
      curRootIR = new IR(type, u_val, datatype, dataflag, data_affi);
    } else {
      curRootIR = new IR(type, i_val, datatype, dataflag, data_affi);
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

// Helper functon for construct_set_session_library

void constr_set_session_lib_helper(json curJsonNode, map<string, DataAffinity>& affi_library) {

    for (json::iterator it = curJsonNode.begin(); it != curJsonNode.end(); it++) {
        auto cur_set_node = it.value();
        if (!cur_set_node["enabled"]) {
            // Ignore the not enabled.
            continue;
        }

        DataAffinity cur_affi;
        string var_name = string(cur_set_node["var_name"]);

        auto params_node = cur_set_node["params"];

        string affi_type_str = string(params_node.at("type"));

        DATAAFFINITYTYPE affi_type = get_data_affinity_by_string(affi_type_str);

        cur_affi.set_data_affinity(affi_type);

        if (affi_type_str == "AFFIENUM") {
            // Save all the ENUM types into the Data Affinity structure.
            auto enum_values_node = params_node.at("enum_values");
            vector<string> v_enum_values_str;
            for (json::iterator enum_it = enum_values_node.begin(); enum_it != enum_values_node.end(); enum_it++) {
                v_enum_values_str.push_back(enum_it.value());
            }
            cur_affi.set_v_enum_str(v_enum_values_str);

        } else if (affi_type_str == "AFFIINT") {
            // If the integer value has range or enum, only save them.
            if (params_node.at("is_enum")) {
                cur_affi.set_is_enum(true);
                cur_affi.set_is_range(false);
                auto enum_values_node = params_node.at("enum_values");
                vector<string> v_enum_values_str;
                for (json::iterator enum_it = enum_values_node.begin(); enum_it != enum_values_node.end(); enum_it++) {
                    v_enum_values_str.push_back(to_string(enum_it.value()));
                }
                cur_affi.set_v_enum_str(v_enum_values_str);

            } else if (params_node.at("is_range")) {
                cur_affi.set_is_enum(false);
                cur_affi.set_is_range(true);

                auto min_value = params_node.at("range").at("min");
                auto max_value = params_node.at("range").at("max");

                cur_affi.set_int_range(min_value, max_value);
            } else {
                // Simple setup of the int type, no restrictions.
                cur_affi.set_is_enum(false);
                cur_affi.set_is_range(false);
            }

        } else if (affi_type_str == "AFFIONOFF") {
            // Save all the ENUM types into the Data Affinity structure.
            // For AFFIONOFF. The enum only has two string "on" and "off".
            cur_affi.set_data_affinity(AFFIENUM);
            vector<string> v_enum_values_str;
            v_enum_values_str.push_back("on");
            v_enum_values_str.push_back("off");
            cur_affi.set_v_enum_str(v_enum_values_str);

        } else if (affi_type_str == "AFFIONOFFAUTO") {
            // Save all the ENUM types into the Data Affinity structure.
            // For AFFIONOFFAUTO. The enum only has three string "on", "off" and "auto".
            cur_affi.set_data_affinity(AFFIENUM);
            vector<string> v_enum_values_str;
            v_enum_values_str.push_back("on");
            v_enum_values_str.push_back("off");
            v_enum_values_str.push_back("auto");
            cur_affi.set_v_enum_str(v_enum_values_str);
        } else if (affi_type_str == "AFFIBOOL") {
            // Save all the ENUM types into the Data Affinity structure.
            // For AFFIBOOL. The enum only has two string "true" and "false".
            cur_affi.set_data_affinity(AFFIENUM);
            vector<string> v_enum_values_str;
            v_enum_values_str.push_back("true");
            v_enum_values_str.push_back("false");
            cur_affi.set_v_enum_str(v_enum_values_str);
        }
        affi_library[var_name] = cur_affi;
    }

    // Finished the set session handling.
    return;
}

void constr_set_session_lib(string set_session_str, map<string, DataAffinity>& affi_library) {
    if (set_session_str.size() == 0 || set_session_str[0] != '[') {
        // Return a default Data Affinity. With AFFIUNKNOWN.
        cerr << "\n\n\nInside the construct_set_session_library, not "
                "getting a correct json file. \n\n\n";
        cerr << set_session_str << "\n\n\n";
        return;
    }

    try {
        auto json_obj = json::parse(set_session_str);
        constr_set_session_lib_helper(json_obj, affi_library);
    } catch (json::parse_error &ex) {
        return;
    }


    return;
}