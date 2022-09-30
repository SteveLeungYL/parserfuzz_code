#include <iostream>

#include "json_ir_convertor.h"
#include "json.hpp"
#include "../include/utils.h"

using json = nlohmann::json;
using std::cout, std::cerr, std::endl;

IRTYPE get_ir_type_by_idx(int idx) {
    return static_cast<IRTYPE>(idx);
}

DATATYPE get_data_type_by_idx(int idx) {
    return static_cast<DATATYPE>(idx);
}

DATAFLAG get_data_flag_by_idx(int idx) {
    return static_cast<DATAFLAG>(idx);
}

IR* convert_json_to_IR_helper(json curJsonNode, int depth) {

    IRTYPE type = TypeUnknown;
    DATATYPE datatype = DataNone;
    DATAFLAG dataflag = ContextUnknown;
    IR* LNode = NULL, *RNode = NULL;
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
            if (it.value() == NULL) {
                LNode = NULL;
            } else {
                LNode = convert_json_to_IR_helper(it.value(), depth + 1);
            }
            continue;
        } else if (it.key() == "RNode") {
            if (it.value() == NULL) {
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
        } else if (it.key() == "Str") {
            str = it.value();
        } else if (it.key() == "IValue") {
            i_val = it.value();
        } else if (it.key() == "UValue") {
            u_val = it.value();
        } else if (it.key() == "FValue") {
            f_val = it.value();
        } else {
            // pass and ignored.
        }
    }

    IR* curRootIR;

    if (type == TypeIdentifier) {
        curRootIR = new IR(type, str, datatype, -1, dataflag);
    } else if (type == TypeStringLiteral) {
        curRootIR = new IR(type, str);
    } else if (type == TypeIntegerLiteral) {
        if (u_val != 0) {
            curRootIR = new IR(type, u_val);
        } else {
            curRootIR = new IR(type, i_val);
        }
    } else {
        IROperator* ir_opt = new IROperator(prefix, infix, suffix);
        curRootIR = new IR(type, ir_opt, LNode, RNode);
    }

    return curRootIR;
}

IR* convert_json_to_IR(string all_json_str) {

    
    vector<string> json_str_lines = string_splitter(all_json_str, '\n');

    IR* retRootIR;

    for (const string& json_str : json_str_lines) {
        if (json_str.size() == 0 || json_str[0] != '{') {
            continue;
        }
        try {
            auto json_obj = json::parse(json_str);
            retRootIR = convert_json_to_IR_helper(json_obj, 0);
        }  catch (json::parse_error& ex) {
            return NULL;
        }
    }

    return retRootIR;
}
