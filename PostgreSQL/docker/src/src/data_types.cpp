#include "../include/data_types.h"
#include "../include/utils.h"

map<string, string> DataTypeAlias2TypeStr = {
    {"INT8", "BIGINT"},
    {"SERIAL8", "BIGSERIAL"},
    {"BIT VARYING", "VARBIT"},
    {"BOOLEAN", "BOOL"},
    {"CHARACTER", "CHAR"},
    {"CHARACTER VARYING", "VARCHAR"},
    {"DOUBLE PRECISION", "FLOAT8"},
    {"INT", "INTEGER"},
    {"INT4", "INTEGER"},
    {"DECIMAL", "NUMERIC"},
    {"FLOAT4", "REAL"},
    {"INT2", "SMALLINT"},
    {"SERIAL2", "SMALLSERIAL"},
    {"SERIAL4", "SERIAL"},
    {"TIME WITH TIME ZONE", "TIMETZ"},
    {"TIMESTAMP WITH TIME ZONE", "TIMESTAMPTZ"}
};

string get_string_by_data_type(DATATYPE type) {
#define DECLARE_CASE(classname)                                                \
  if (type == k##classname)                                                    \
    return #classname;
  ALLDATATYPE(DECLARE_CASE);
#undef DECLARE_CASE
  assert(false);
  return "";
}

DATATYPE DataType::get_data_type_from_simple_str(string in) {

#define DECLARE_CASE(dataTypeName)                                             \
  if (str_toupper(in) == #dataTypeName)                                                      \
    return k##dataTypeName;
  ALLDATATYPE(DECLARE_CASE);
#undef DECLARE_CASE

  cerr << "\n\n\nError: Cannot find the matching data affinity by"
               " string: \"" +
               in + "\" \n\n\n";
  assert(false);
  return kTYPEUNKNOWN;
}

void DataType::init_data_type_with_str(string in) {

  /* Parse the Data Type string,
   * rewriting the alias string to its original form,
   * and then init the DataType struct with the given information.
   * */

  // Sample type string: char (3)[3][3]. The `()` stands for char size, the second
  // and third `[]` stands for array size.

  in = str_toupper(in);

  // Spot the ARRAY keyword. Remove it.
  bool is_keyword_array = false;
  vector<string> v_in_split = string_splitter(in, "ARRAY");
  if (v_in_split.size() > 1) {
    in = "";
    for (int idx = 0; idx < v_in_split.size(); idx++) {
      in += v_in_split[idx];
    }
    is_keyword_array = true;
  }

  trim_string(in);

  // Remove new line symbol \n.
  string tmp_in = "";
  tmp_in.reserve(in.size());
  for (auto p = in.begin(); p != in.end(); p++) {
    if (*p == '\n') {
      continue;
    } else {
      tmp_in += *p;
    }
  }
  in = tmp_in;
  // Finished removing the \n symbol.

  // Remove the () or [] symbol following the Data Type Name. Construct the simple string
  // that only declare the data type.
  string sep = "(";
  v_in_split = string_splitter(in, "(");
  if (v_in_split.size() <= 1) {
    // Does not detect the '()' symbol.
    v_in_split = string_splitter(in, "[");
    sep = "[";
    if (v_in_split.size() <= 1) {
      // Does not detect the '[]' symbol.
      sep = "";
    }
  }

  string simple_str = v_in_split.front();
  trim_string(simple_str); // May be a duplicated call. Remove suffix space.

  if (DataTypeAlias2TypeStr.count(simple_str) != 0) {
    simple_str = DataTypeAlias2TypeStr[simple_str];
  }

  this->data_type = this->get_data_type_from_simple_str(simple_str);

  if (sep == "(") {
    // The statement contains "()". It is a varying size data type.
    // There can only be one "()" in one type.
    if (v_in_split.size() <= 1) {
      assert(false);
      return;
    }
    string varying_size_str = v_in_split.back();
    if (varying_size_str.size() == 0) {
      assert(false);
      return;
    }
    varying_size_str = string_splitter(varying_size_str, "[").front(); // always existed.
    varying_size_str = varying_size_str.substr(0, varying_size_str.size() - 1); // remove the right ).

    try {
      this->varying_size = std::stoi(varying_size_str);
    } catch (std::invalid_argument const &e) {
      this->varying_size = VaryingArraySizeAny;
    } catch (std::out_of_range const &e) {
      this->varying_size = VaryingArraySizeAny;
    }
  }

  // Parse the multi-dimension array size. e.g. [6][6]
  v_in_split = string_splitter(in, "[");
  this->v_array_size.clear();
  for (int idx = 1; idx < v_in_split.size(); idx++) {
    string array_size_str = v_in_split[idx];
    if (array_size_str.size() == 0) {
      assert(false);
      return;
    }
    array_size_str = array_size_str.substr(0, array_size_str.size()-1);
    int array_size_int = VaryingArraySizeAny;
    try {
      array_size_int = std::stoi(array_size_str);
    } catch (std::invalid_argument const &e) {
      array_size_int = VaryingArraySizeAny;
    } catch (std::out_of_range const &e) {
      array_size_int = VaryingArraySizeAny;
    }

    this->v_array_size.push_back(array_size_int);
  }

  // If the ARRAY keyword has been provided, but the varying size is not,
  // create one dimensional any size array.
  if (v_array_size.size() == 0  && is_keyword_array) {
    this->v_array_size.push_back(VaryingArraySizeAny);
  }

  return;

}

unsigned long long DataType::calc_hash() {

  string res_str;

  // Handle the Tuple type first. XOR on each hash.
  if (this->data_type == kTYPETUPLE) {
    if (this->get_v_tuple_type().size() == 0) {
      assert(false);
      return 0;
    }
    unsigned long long res_hash = v_tuple_types.front()->calc_hash();

    for (int idx = 1; idx < v_tuple_types.size(); idx++) {
      auto cur_tuple_type = v_tuple_types[idx];
      unsigned long long cur_tuple_hash = cur_tuple_type->calc_hash();
      res_hash = res_hash ^ cur_tuple_hash;
    }

    return res_hash;
  }

  // Handle the array type.
  if (this->get_v_array_size().size() != 0 &&
      this->get_v_array_size().front() > VaryingArraySizeNone
      ) {
    // Ignore the varying size for each array elements.
    res_str = get_string_by_data_type(this->get_data_type());
    for (int i = 0; i < get_v_array_size().size(); i++) {
      res_str += "_" + to_string(get_v_array_size()[i]);
    }

    return get_str_hash(res_str.c_str(), res_str.size());
  }

  // Handle rest of the normal types. Also need to care about the varying size.
  res_str = get_string_by_data_type(this->get_data_type());
  if (varying_size != VaryingArraySizeNone) {
    res_str += to_string(varying_size);
  }
  return get_str_hash(res_str.c_str(), res_str.size());

}

string DataType::get_str_from_data_type() {

  return get_string_by_data_type(this->data_type);

}