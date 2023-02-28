//
// Created by Yu Liang on 2/19/23.
//

#ifndef SIGNATURE_PROFILER_DATA_TYPE_SIG_H
#define SIGNATURE_PROFILER_DATA_TYPE_SIG_H

#include "data_types.h"
#include "json.hpp"

#include <cassert>
#include <iostream>
#include <utility>

using std::cerr;
using nlohmann::json;

enum FuncCategory {
  Normal = 0,
  Aggregate,
  AggregateOrder,
  Aggregatehypothetical,
  Window
};

class FuncSig {
  // store the function signature information
public:
  bool is_contain_unsupported() const {
    bool res = false;
    for (DataType cur_arg_type : this->get_arg_types()) {
      res = res || cur_arg_type.is_contain_unsupported();
    }
    res = res || get_ret_type().is_contain_unsupported();

    return res;
  }

  double get_success_rate() const {
    return 100.0 * double(execute_success) /
           double(execute_success + execute_error);
  }
  int get_execute_success() const { return execute_success; }
  int get_execute_error() const { return execute_error; }
  int get_total_execute() const { return (execute_success + execute_error); }
  vector<DataType> get_arg_types() const { return arg_types; }
  DataType get_ret_type() const { return ret_type; }
  string get_func_name() const { return func_name; }
  FuncCategory get_func_catalog() const { return func_catalog; }

  string get_mutated_func_str();

  void set_func_name(const string func_name) { this->func_name = func_name; }
  void set_arg_types(const vector<DataType> arg_types) {
    this->arg_types = arg_types;
  }
  void push_arg_type(const DataType arg_type) {
    this->arg_types.push_back(arg_type);
  }
  void set_ret_type(const DataType ret_type) { this->ret_type = ret_type; }
  void set_func_catalog(FuncCategory in) { this->func_catalog = in; }
  void set_func_catalog(const string &in, const string &agg_in) {
    if (in == "f") {
      this->func_catalog = Normal;
    } else if (in == "a") {
      if (agg_in == "n") {
        this->func_catalog = Aggregate;
      } else if (agg_in == "o") {
        this->func_catalog = AggregateOrder;
      } else if (agg_in == "h") {
        this->func_catalog = Aggregatehypothetical;
      } else {
        cerr << "\n\n\nERROR: Cannot detect the aggregate function type: "
             << agg_in << " \n\n\n";
        assert(false);
      }
    } else {
      this->func_catalog = Window;
    }
    return;
  }

  void increment_execute_success();
  void increment_execute_error() { execute_error++; }

  string get_func_signature() const {
    string res_signature;
    res_signature += get_func_name() + "(";
    for (int i = 0; i < arg_types.size(); i++) {
      const DataType &cur_arg = arg_types[i];
      res_signature += cur_arg.get_str_from_data_type();
      if (i != arg_types.size() - 1) {
        res_signature += ", ";
      }
    }
    res_signature += ")->" + get_ret_type().get_str_from_data_type();
    return res_signature;
  }

  void set_supported_types(vector<DATATYPE> in) {
    this->v_supported_types = in;
    return;
  }

  vector<DATATYPE> get_supported_types() const {
    return this->v_supported_types;
  }

  vector<DataType> get_tmp_infer_arg_types() const {
    return this->tmp_infer_arg_types;
  }

  DataType get_tmp_infer_ret_type() const {
    return this->tmp_infer_ret_type;
  }

  vector<vector<DataType>> get_saved_infer_arg_types() const {
    return this->saved_infer_arg_types;
  }

  vector<DataType> get_saved_infer_ret_type() const {
    return this->saved_infer_ret_type;
  }

  void set_is_consist_type(bool in) {
    this->is_consist_type = in;
  }

  bool get_is_consist_type() const {
    return this->is_consist_type;
  }

  FuncSig() : execute_success(0), execute_error(0) {}
  FuncSig(const string &func_name_in, const vector<DataType> &arg_types_in,
          const DataType &ret_type_in,
          const FuncCategory func_catalog_in = Normal,
          const bool& is_consist_in = true,
          const vector<DATATYPE>& sup_type_in = {})
      : func_name(func_name_in), arg_types(arg_types_in), ret_type(ret_type_in),
        execute_success(0), execute_error(0), func_catalog(func_catalog_in),
        is_consist_type(is_consist_in),
        v_supported_types(sup_type_in){
    setup_mutation_hints();
  }
  FuncSig(const string &func_name_in, const vector<DataType> &arg_types_in,
          const DataType &ret_type_in,
          const string& catalog_in,
          const string& agg_catalog_in,
          const bool& is_consist_in = true,
          const vector<DATATYPE>& sup_type_in = {})
      : func_name(func_name_in), arg_types(arg_types_in), ret_type(ret_type_in),
        execute_success(0), execute_error(0), func_catalog(Normal),
        is_consist_type(is_consist_in),
        v_supported_types(sup_type_in) {
    setup_mutation_hints();
    set_func_catalog(catalog_in, agg_catalog_in);
  }

  FuncSig(const FuncSig& in):
    func_name(in.get_func_name()), arg_types(in.get_arg_types()), ret_type(in.get_ret_type()),
    execute_success(in.get_execute_success()), execute_error (in.get_execute_error()), 
    func_catalog(in.get_func_catalog()),
    tmp_infer_arg_types(in.get_tmp_infer_arg_types()),
    tmp_infer_ret_type(in.get_tmp_infer_ret_type()),
    saved_infer_arg_types(in.get_saved_infer_arg_types()),
    saved_infer_ret_type(in.get_saved_infer_ret_type()),
    is_consist_type(in.get_is_consist_type()),
    v_supported_types(in.get_supported_types())
  {}

  FuncSig(const json& in, const vector<DATATYPE>& sup_type_in = {}):
    execute_success(0), execute_error(0), v_supported_types(sup_type_in) {
    
     this->func_name = in["func_name"]; 
     this->is_consist_type = in["is_consist_type"];

     vector<DataType> v_tmp_arg_types;
     for (auto& cur_arg_type: in["arg_types"]) {
       DataType cur_arg_type_enum = DataType(string(cur_arg_type));
       v_tmp_arg_types.push_back(cur_arg_type_enum);
     }
     this->set_arg_types(v_tmp_arg_types);

     DataType tmp_ret_type = DataType(string(in["ret_type"]));
     this->set_ret_type(tmp_ret_type);

     string func_cata_str = in["func_catalog"];
     if (func_cata_str == "Normal") {
       this->set_func_catalog(Normal);
     } else if (func_cata_str == "Aggregate") {
       this->set_func_catalog(Aggregate);
     } else if (func_cata_str == "AggregateOrder") {
       this->set_func_catalog(AggregateOrder);
     } else if (func_cata_str == "AggregateHypothetical") {
       this->set_func_catalog(Aggregatehypothetical);
     } else if (func_cata_str == "Window") {
       this->set_func_catalog(Window);
     } else {
       cerr << "Logic Error: cannot find func_catalog type in dump_success_types function. \n\n\n";
       assert (false);
       exit(1);
     }

  }


  // Setup function hints for better instantiation results.
  void setup_mutation_hints();

  // Dump all the successfully instantiated types to a JSON file.
  vector<json> dump_success_types(const string& path);

private:
  string func_name;
  vector<DataType> arg_types;
  DataType ret_type;
  int execute_success, execute_error;
  FuncCategory func_catalog;

  // Private helper function.
  inline bool find_types(DATATYPE data_type_in) {
    for (const DataType& cur_arg_type : this->get_arg_types()) {
      if (cur_arg_type.get_data_type_enum() == data_type_in) {
        return true;
      }
    }
    if (this->get_ret_type().get_data_type_enum() == data_type_in) {
      return true;
    }
    return false;
  }

  void setup_cstring_hint();

  // Used to save the current instantiated types, if the Function Signature
  // contains kUNDEFINE.
  vector<DataType> tmp_infer_arg_types;
  DataType tmp_infer_ret_type;

  // Used to save all the successful instantiated types, 
  // if the Function Signature contains kUNDEFINE.
  vector<vector<DataType> > saved_infer_arg_types;
  vector<DataType> saved_infer_ret_type;


  bool is_consist_type;

  // If the DBMS only support limited number of the data types, list them here.
  vector<DATATYPE> v_supported_types;

};

class OprSig {
  // store the operator signature information
public:
  double get_success_rate() const {
    return 100.0 * double(execute_success) / double(execute_success + execute_error);
  }
  int get_execute_success() const { return execute_success; }
  int get_execute_error() const { return execute_error; }
  int get_total_execute() const { return (execute_success + execute_error); }
  pair<DataType, DataType> get_arg_types() const {
    return pair<DataType, DataType>(left_type, right_type);
  }
  DataType get_arg_left_type() const { return left_type; }
  DataType get_arg_right_type() const { return right_type; }
  DataType get_ret_type() const { return ret_type; }
  string get_opr_name() const { return operator_name; }

  inline bool is_unary_opr() const {
    return (this->left_type.get_data_type_enum() == kTYPENONE);
  }

  bool is_contain_unsupported() const;

  void set_opr_name(const string opr_name) { this->operator_name = opr_name; }
  void set_left_type(const DataType arg_type) { this->left_type = arg_type; }
  void set_right_type(const DataType arg_type) { this->right_type = arg_type; }
  void set_ret_type(const DataType ret_type) { this->ret_type = ret_type; }

  void increment_execute_success() { execute_success++; }
  void increment_execute_error() { execute_error++; }

  string get_mutated_opr_str();

  string get_opr_signature() const {
    string res_signature;
    res_signature += get_opr_name() + "(";
    res_signature += left_type.get_str_from_data_type() + "," +
                     right_type.get_str_from_data_type();
    res_signature += ")->" + get_ret_type().get_str_from_data_type();
    return res_signature;
  }

  OprSig() : left_type(kTYPEUNKNOWN), right_type(kTYPEUNKNOWN), ret_type(kTYPEUNKNOWN),
             execute_success(0), execute_error(0) {}
  OprSig(const string& name_in):
                                  operator_name(name_in), left_type(kTYPEANY), right_type(kTYPEANY), ret_type(kTYPEANY),
                                  execute_success(0), execute_error(0) {}
  OprSig(const string& name_in,
         const DataType& left_type_in,
         const DataType& right_type_in,
         const DataType& ret_type_in
         ): operator_name(name_in), left_type(left_type_in), right_type(right_type_in), ret_type(ret_type_in),
             execute_success(0), execute_error(0) {}

  OprSig(const OprSig& in):
    operator_name(in.get_opr_name()), left_type(in.get_arg_left_type()), right_type(in.get_arg_right_type()),
    ret_type(in.get_ret_type()), execute_success(in.get_execute_success()), execute_error(in.get_execute_error()) {}

private:
  string operator_name;
  DataType left_type, right_type;
  DataType ret_type;
  int execute_success, execute_error;
};

#endif // SIGNATURE_PROFILER_DATA_TYPE_SIG_H
