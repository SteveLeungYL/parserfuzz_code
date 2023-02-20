//
// Created by Yu Liang on 2/19/23.
//

#ifndef SIGNATURE_PROFILER_DATA_TYPE_SIG_H
#define SIGNATURE_PROFILER_DATA_TYPE_SIG_H

#include "data_types.h"
#include <cassert>
#include <iostream>
#include <utility>

using std::cerr;

enum FuncCatalog {
  Normal = 0,
  Aggregate,
  AggregateOrder,
  Aggregatehypothetical,
  Window
};

class FuncSig {
  // store the function signature information
public:
  bool is_contain_unsupported() {
    bool res = false;
    for (DataType& cur_arg_type : this->get_arg_types()) {
      res = res || cur_arg_type.is_contain_unsupported();
    }
    res = res || ret_type.is_contain_unsupported();

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
  FuncCatalog get_func_catalog() const { return func_catalog; }

  string get_mutated_func_str();

  void set_func_name(const string func_name) { this->func_name = func_name; }
  void set_arg_types(const vector<DataType> arg_types) {
    this->arg_types = arg_types;
  }
  void push_arg_type(const DataType arg_type) {
    this->arg_types.push_back(arg_type);
  }
  void set_ret_type(const DataType ret_type) { this->ret_type = ret_type; }
  void set_func_catalog(FuncCatalog in) { this->func_catalog = in; }
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

  void increment_execute_success() { execute_success++; }
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

  FuncSig() : execute_success(0), execute_error(0) {}
  FuncSig(const string &func_name_in, const vector<DataType> &arg_types_in,
          const DataType &ret_type_in,
          const FuncCatalog func_catalog_in = Normal)
      : func_name(func_name_in), arg_types(arg_types_in), ret_type(ret_type_in),
        execute_success(0), execute_error(0), func_catalog(func_catalog_in) {
    setup_mutation_hints();
  }
  FuncSig(const string &func_name_in, const vector<DataType> &arg_types_in,
          const DataType &ret_type_in,
          const string& catalog_in,
          const string& agg_catalog_in)
      : func_name(func_name_in), arg_types(arg_types_in), ret_type(ret_type_in),
        execute_success(0), execute_error(0), func_catalog(Normal) {
    setup_mutation_hints();
    set_func_catalog(catalog_in, agg_catalog_in);
  }

private:
  string func_name;
  vector<DataType> arg_types;
  DataType ret_type;
  int execute_success, execute_error;
  FuncCatalog func_catalog;

  // Setup function hints for better instantiation results.
  void setup_mutation_hints();

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

  OprSig() : execute_success(0), execute_error(0) {}

private:
  string operator_name;
  DataType left_type, right_type;
  DataType ret_type;
  int execute_success, execute_error;
};

#endif // SIGNATURE_PROFILER_DATA_TYPE_SIG_H
