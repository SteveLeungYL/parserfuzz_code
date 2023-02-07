#include "../include/json_ir_convertor.h"
#include "../include/json.hpp" // From nlohmann/json

using json = nlohmann::json;

inline void constr_sql_func_lib_helper(json& json_obj, vector<string>& v_all_func_str,
                                  map<DATATYPE, vector<string> >& func_ret_type_to_str_map,
                                  map<string, vector<vector<DataType> > >& func_str_to_type_map
                                  ) {

  for (json::iterator it = json_obj.begin(); it != json_obj.end(); it++) {
    auto cur_set_node = it.value();
    if (!cur_set_node.at("enabled")) {
      // Ignored the not enabled.
      continue;
    }

    FUNCTIONTYPE func_type = get_func_type_by_string(cur_set_node.at("func_type"));
    if (
        func_type == FUNCUNKNOWN ||
        func_type == FUNCSYSADMIN ||
        func_type == FUNCSYSINFO
    ) {
      continue;
    }

    string func_name = string(cur_set_node.at("func_name"));
    bool is_type_matched = cur_set_node.at("is_type_matched");

    auto params_node = cur_set_node.at("params");
    for (json::iterator it_params = params_node.begin(); it_params != params_node.end(); it_params++) {
      vector<DataType> single_signature;

      // The ret_type must exist.
      DataType ret_type(string(it_params->at("ret_type")));
      single_signature.push_back(ret_type);

      // Save the return affinity to function name mapping.
      vector<string>& v_tmp = func_ret_type_to_str_map[ret_type.get_data_type_enum()];
      if (find(v_tmp.begin(), v_tmp.end(), func_name) == v_tmp.end()) {
        // avoid duplication.
        v_tmp.push_back(func_name);
      }

      for (int i = 0; i < it_params->size(); i++) {
        string arg_key = "arg_type_" + to_string(i);
        if (!it_params->contains(arg_key)) {
          break;
        }

        DataType cur_arg_type(string(it_params->at(arg_key)));

        string arg_key_enum = arg_key + "_enum";
        if (it_params->contains(arg_key_enum)) {
          // Is an enumeration type.
          auto enum_node = it_params->at(arg_key_enum);
          vector<string> v_enum;
          for (json::iterator it_enum = enum_node.begin(); it_enum != enum_node.end(); it_enum++) {
            string enum_str = it_enum.value();
            v_enum.push_back(enum_str);
          }
          cur_arg_type.set_v_enum_str(v_enum);
        }

        string arg_key_range = arg_key + "_range";
        if (it_params->contains(arg_key_range)) {
          auto range_node = it_params->at(arg_key_range);
          auto range_max = range_node.at("max");
          auto range_min = range_node.at("min");
          cur_arg_type.set_range(range_min, range_max, cur_arg_type.get_data_type_enum());
        }

        single_signature.push_back(cur_arg_type);
      }

      func_str_to_type_map[func_name].push_back(single_signature);
    }

    v_all_func_str.push_back(func_name);
  }

}

void constr_sql_func_lib(string func_types_str, vector<string> v_all_func_str,
                         map<DATATYPE, vector<string> >& func_ret_type_to_str_map,
                         map<string, vector<vector<DataType> > >& func_str_to_type_map){
  try {
    auto json_obj = json::parse(func_types_str);
    constr_sql_func_lib_helper(json_obj, v_all_func_str, func_ret_type_to_str_map, func_str_to_type_map);
  } catch (json::parse_error &ex) {
    assert(!"Assertion Failure: Parsing the function string to JSON failed. ");
  }

  return;
}