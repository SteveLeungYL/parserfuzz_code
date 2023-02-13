//
// Created by Yu Liang on 2/12/23.
//

#ifndef SRC_DATA_TYPE_SIGNATURES_H
#define SRC_DATA_TYPE_SIGNATURES_H

#include "data_types.h"
#include <utility>

enum FuncCatalog {
  Normal = 0,
  Aggregate,
  Window
};

class FuncSig {
  // store the function signature information
public:
  double get_success_rate () const {return double(execute_success) / double(execute_success + execute_error); }
  int get_execute_success() const {return execute_success;}
  int get_execute_error() const {return execute_error;}
  int get_total_execute() const {return (execute_success + execute_error);}
  vector<DataType> get_arg_types() const {return arg_types;}
  DataType get_ret_type() const {return ret_type;}
  string get_func_name() const {return func_name;}

  void set_func_name(const string func_name) {this->func_name = func_name;}
  void set_arg_types(const vector<DataType> arg_types) {this->arg_types = arg_types;}
  void push_arg_type(const DataType arg_type) {this->arg_types.push_back(arg_type);}
  void set_ret_type(const DataType ret_type) {this->ret_type = ret_type;}
  void set_func_catalog(FuncCatalog in) {this->func_catalog = in;}
  void set_func_catalog(const string& in) {
    if (in == "f") {
      this->func_catalog = Normal;
    } else if (in == "a") {
      this->func_catalog = Aggregate;
    } else {
      this->func_catalog = Window;
    }
    return;
  }

  void increment_execute_success() {execute_success++;}
  void increment_execute_error() {execute_error++;}

  string get_func_signature() const {
    string res_signature;
    res_signature += get_func_name() + "(";
    for (auto cur_arg : arg_types) {
      res_signature += cur_arg.get_str_from_data_type() + ",";
    }
    res_signature += ")->" + get_ret_type().get_str_from_data_type();
    return res_signature;
  }

  FuncSig(): execute_success(0), execute_error(0) {}

private:
  string func_name;
  vector<DataType> arg_types;
  DataType ret_type;
  int execute_success, execute_error;
  FuncCatalog func_catalog;
};

class OprSig {
  // store the operator signature information
public:
  double get_success_rate () const {return double(execute_success) / double(execute_success + execute_error); }
  int get_execute_success() const {return execute_success;}
  int get_execute_error() const {return execute_error;}
  int get_total_execute() const {return (execute_success + execute_error);}
  pair<DataType, DataType> get_arg_types() const {return pair<DataType, DataType> (left_type, right_type);}
  DataType get_ret_type() const {return ret_type;}
  string get_opr_name() const {return operator_name;}

  void set_opr_name(const string opr_name) {this->operator_name = opr_name;}
  void set_left_type(const DataType arg_type) {this->left_type = arg_type;}
  void set_right_type(const DataType arg_type) {this->right_type = arg_type;}
  void set_ret_type(const DataType ret_type) {this->ret_type = ret_type;}

  void increment_execute_success() {execute_success++;}
  void increment_execute_error() {execute_error++;}

  string get_opr_signature() const {
    string res_signature;
    res_signature += get_opr_name() + "(";
    res_signature += left_type.get_str_from_data_type() + "," + right_type.get_str_from_data_type();
    res_signature += ")->" + get_ret_type().get_str_from_data_type();
    return res_signature;
  }

  OprSig(): execute_success(0), execute_error(0) {}

private:
  string operator_name;
  DataType left_type, right_type;
  DataType ret_type;
  int execute_success, execute_error;
};

#endif // SRC_DATA_TYPE_SIGNATURES_H
