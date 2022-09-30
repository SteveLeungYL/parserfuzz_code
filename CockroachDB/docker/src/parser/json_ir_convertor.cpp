#include "json_ir_convertor.h"
#include "json.hpp"
#include "../include/utils.h"
#include <iostream>

using json = nlohmann::json;
using std::cout, std::cerr, std::endl;

IRTYPE get_ir_type_by_idx(int idx) {
    return static_cast<IRTYPE>(idx);
}

DATATYPE get_data_type_by_idx(int idx) {
    return static_cast<DATATYPE>(idx);
}

IR* covert_json_to_IR(string all_json_str) {

    
    vector<string> json_str_lines = string_splitter(all_json_str, '\n');

    for (const string& json_str : json_str_lines) {
        if (json_str.size() == 0 || json_str[0] != '{') {
            continue;
        }
        try {
        auto json_obj = json::parse(json_str);

        cout << "Debug: Getting json_object size: \n" << json_obj.size() << std::endl;

        }  catch (json::parse_error& ex) {
            cerr << "Debug: C++ json::parse failed. \n";
            cerr << "Debug: parse error at byte " << ex.byte << endl;
        }
    }

    auto tmpIR = new IR(TypeUnknown, "whatever");
    return tmpIR;
}
