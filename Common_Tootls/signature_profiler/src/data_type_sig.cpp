#include "../header/data_type_sig.h"

string FuncSig::get_mutated_func_str() {
  string res_str;
  DATATYPE rand_any_type = kTYPEUNKNOWN;

  // Copy the argument list and ret type out. 
  // Do not change its original form.
  vector<DataType> all_arg_types = this->get_arg_types();
  DataType ret_type = this->get_ret_type();

  // If the arg_types is specified as TYPEANY, randomly generate one type
  // and then assigned to it.
  // Additionally, keep all the ANY types in one function consistent.
  for (int i = 0; i < all_arg_types.size(); i++) {
    if (all_arg_types[i].get_data_type_enum() == kTYPEANY ||
        all_arg_types[i].get_data_type_enum() == kTYPEUNDEFINE
        ) {
      if (rand_any_type == kTYPEUNKNOWN) {
        rand_any_type = all_arg_types[i].gen_rand_any_type();
        all_arg_types[i].set_data_type(rand_any_type);
      } else {
        all_arg_types[i].set_data_type(rand_any_type);
      }
    }
  }
  if (ret_type.get_data_type_enum() == kTYPEANY ||
      ret_type.get_data_type_enum() == kTYPEUNDEFINE 
      ) {
    if (rand_any_type == kTYPEUNKNOWN) {
      rand_any_type = ret_type.gen_rand_any_type();
      ret_type.set_data_type(rand_any_type);
    } else {
      ret_type.set_data_type(rand_any_type);
    }
  }

  res_str += get_func_name() + "(";

  int end_idx = all_arg_types.size();
  if (this->get_func_catalog() == AggregateOrder) {
    end_idx--;
  }

  for (int i = 0; i < end_idx; i++) {
    if (all_arg_types[i].get_data_type_enum() == kTYPEANY) {
      // If the arg_types is specified as TYPEANY, randomly generate one type
      // and then assigned to it.
      // Additionally, keep all the ANY types in one function consistent.
      if (rand_any_type == kTYPEUNKNOWN) {
        rand_any_type = all_arg_types[i].gen_rand_any_type();
        all_arg_types[i].set_data_type(rand_any_type);
      } else {
        all_arg_types[i].set_data_type(rand_any_type);
      }
    }
    res_str += (all_arg_types[i]).mutate_type_entry();
    if (i != (end_idx - 1)) {
      res_str += ", ";
    }
  }

  res_str += ")";

  if (this->get_func_catalog() == AggregateOrder) {
    if (all_arg_types.size() == 0) {
      cerr << "\n\n\nERROR: Cannot get the WITHIN GROUP data type from the "
              "aggregate order function: " << this->func_name << "\n\n\n";
      assert(false);
    }

    // Use the helper function. Should not use ARRAY, Tuple and Vector here.
    string order_by_str = all_arg_types.back().mutate_type_entry_helper();
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

void FuncSig::setup_mutation_hints() {
  // This function is used for rewriting type rules from the hints.
  // e.g. adding integer range. (can be binary search)
  // e.g., rewrite the

  this->setup_cstring_hint();

}

void FuncSig::setup_cstring_hint() {
  // Special handling for CSTRING
  // CSTRING is commonly used for construct TEXT based (null ending) representation
  // of an underlying type. For example, boolin('true') -> t.
  vector<string> tmp_str_split;
  if (this->find_types(kTYPECSTRING)) {
    string tmp_str;
    string cur_func_name = this->get_func_name();

    // Remove the in&out suffix.
    tmp_str = cur_func_name;
    if (tmp_str.size() > 3 && tmp_str.substr(tmp_str.size()-3, 3) == "_in") {
      tmp_str = tmp_str.substr(0, tmp_str.size() - 3);
    }
    if (tmp_str.size() > 2 && tmp_str.substr(tmp_str.size()-2, 2) == "in") {
      tmp_str = tmp_str.substr(0, tmp_str.size() - 2);
    }
    if (tmp_str.size() > 4 && tmp_str.substr(tmp_str.size()-4, 4) == "_out") {
      tmp_str = tmp_str.substr(0, tmp_str.size() - 4);
    }
    if (tmp_str.size() > 3 && tmp_str.substr(tmp_str.size()-3, 3) == "out") {
      tmp_str = tmp_str.substr(0, tmp_str.size() - 3);
    }

    // Try to scan for the func name without the "_in", "_out", see if it matches.
    DataType matched_data_type(tmp_str);
    if (matched_data_type.get_data_type_enum() == kTYPEUNKNOWN) {
#ifdef DEBUG
      cerr << "\n\n\nERROR: Cannot find the matching type for CSTRING. \n"
              "Func signature: " << get_func_signature() <<"\n\n\n";
#endif
      this->set_arg_types({kTYPEUNKNOWN});
      this->set_ret_type(kTYPEUNKNOWN);
      return;
    }

    // If the hinted type is pure CSTRING, use TEXT instead.
    if (matched_data_type.get_data_type_enum() == kTYPECSTRING) {
      matched_data_type.set_data_type(kTYPETEXT);
    }

    for (int i = 0; i < this->arg_types.size(); i++) {
      if (this->arg_types[i].get_data_type_enum()==kTYPECSTRING) {
        // Copy constructor.
        this->arg_types[i] = matched_data_type;
        this->arg_types[i].set_is_text_bounded(true);
      }
    }
    if (this->ret_type.get_data_type_enum() == kTYPECSTRING) {
      // Copy constructor.
      this->ret_type = matched_data_type;
      this->ret_type.set_is_text_bounded(true);
    }
  }
}


string OprSig::get_mutated_opr_str() {

  string res_str;
  DATATYPE rand_any_type = kTYPEUNKNOWN;

  // If the arg_types is specified as TYPEANY, randomly generate one type
  // and then assigned to it.
  // Additionally, keep all the ANY types in one function consistent.
  DataType tmp_data_type;
  if (this->get_arg_left_type().get_data_type_enum() == kTYPEANY){
    rand_any_type = tmp_data_type.gen_rand_any_type();
    this->left_type.set_data_type(rand_any_type);
  }
  if (this->get_arg_right_type().get_data_type_enum() == kTYPEANY) {
    if (rand_any_type == kTYPEUNKNOWN) {
      rand_any_type = tmp_data_type.gen_rand_any_type();
    }
    this->right_type.set_data_type(rand_any_type);
  }
  if (this->get_ret_type().get_data_type_enum() == kTYPEANY) {
    if (rand_any_type == kTYPEUNKNOWN) {
      rand_any_type = tmp_data_type.gen_rand_any_type();
    }
    this->ret_type.set_data_type(rand_any_type);
  }

  res_str = get_arg_left_type().mutate_type_entry() + " " + get_opr_name()
            + " " + get_arg_right_type().mutate_type_entry();

  return res_str;

}

bool OprSig::is_contain_unsupported() const {
  if (
        this->get_arg_left_type().is_contain_unsupported() ||
        this->get_arg_right_type().is_contain_unsupported() ||
        this->get_ret_type().is_contain_unsupported()
      ) {
    return true;
  } else {
    return false;
  }
}
