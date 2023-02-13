#include "../include/data_type_sig.h"

string FuncSig::get_mutated_func_str() {
  string res_str;
  DATATYPE rand_any_type = kTYPEUNKNOWN;

  // If the arg_types is specified as TYPEANY, randomly generate one type
  // and then assigned to it.
  // Additionally, keep all the ANY types in one function consistent.
  for (int i = 0; i < this->arg_types.size(); i++) {
    if (this->arg_types[i].get_data_type_enum() == kTYPEANY) {
      if (rand_any_type == kTYPEUNKNOWN) {
        rand_any_type = this->arg_types[i].gen_rand_any_type();
        this->arg_types[i].set_data_type(rand_any_type);
      } else {
        this->arg_types[i].set_data_type(rand_any_type);
      }
    }
  }
  if (this->ret_type.get_data_type_enum() == kTYPEANY) {
    if (rand_any_type == kTYPEUNKNOWN) {
      rand_any_type = this->ret_type.gen_rand_any_type();
      this->ret_type.set_data_type(rand_any_type);
    } else {
      this->ret_type.set_data_type(rand_any_type);
    }
  }

  res_str += get_func_name() + "(";

  int end_idx = this->arg_types.size();
  if (this->get_func_catalog() == AggregateOrder) {
    end_idx--;
  }

  for (int i = 0; i < end_idx; i++) {
    if (this->arg_types[i].get_data_type_enum() == kTYPEANY) {
      // If the arg_types is specified as TYPEANY, randomly generate one type
      // and then assigned to it.
      // Additionally, keep all the ANY types in one function consistent.
      if (rand_any_type == kTYPEUNKNOWN) {
        rand_any_type = this->arg_types[i].gen_rand_any_type();
        this->arg_types[i].set_data_type(rand_any_type);
      } else {
        this->arg_types[i].set_data_type(rand_any_type);
      }
    }
    res_str += (this->arg_types[i]).mutate_type_entry();
    if (i != (end_idx - 1)) {
      res_str += ", ";
    }
  }

  res_str += ")";

  if (this->get_func_catalog() == AggregateOrder) {
    if (this->arg_types.size() == 0) {
      cerr << "\n\n\nERROR: Cannot get the WITHIN GROUP data type from the "
              "aggregate order function: " << this->func_name << "\n\n\n";
      assert(false);
    }

    // Use the helper function. Should not use ARRAY, Tuple and Vector here.
    string order_by_str = arg_types.back().mutate_type_entry_helper();
    res_str += " WITHIN GROUP (ORDER BY" + order_by_str + ")";
  }

  else if (this->get_func_catalog() == Aggregatehypothetical) {
    // Use ad-hoc column c1 from the aggregate function.
    string order_by_str = "c1";
    res_str += " WITHIN GROUP (ORDER BY" + order_by_str + ")";
  }

  else if (this->get_func_catalog() == Window) {
    // Use ad-hoc column c1 from the aggregate function.
    string over_target = "c1";
    res_str += " OVER (PARTITION BY " + over_target + ")";
  }

  return res_str;

}