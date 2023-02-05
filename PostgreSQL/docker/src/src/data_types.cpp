#include "../include/data_types.h"
#include "../include/utils.h"

map<string, string> DataTypeAlias2TypeStr = {
    {"INT8", "BIGINT"},
    {"SERIAL8", "BIGSERIAL"},
    {"BIT VARYING", "VARBIT"},
    {"BOOLEAN", "BOOL"},
    {"CHARACTER", "CHAR"},
    {"CHARACTER VARYING", "VARCHAR"},
    {"DOUBLE PRECISION", "FLOAT"},
    {"FLOAT8", "FLOAT"},
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

string DataType::get_rand_alphabet_num() {
  // no capital letters;
  // Pure helper function for random mutations.
  // Generate random 0~9 number or alphabet character.
  int rand_int = get_rand_int(36);
  if (rand_int >= 26) {
    return to_string(rand_int - 26);
  } else {
    char cch = 'a' + rand_int;
    string ret_str(1, cch);
    return ret_str;
  }
}

string DataType::get_rand_hex_num() {
  // no capital letters;
  // Pure helper function for random mutations.
  // Generate 16 bit characters from 0 ~ f.
  int rand_int = get_rand_int(16);
  if (rand_int < 10) {
    return to_string(rand_int);
  } else {
    char cch = 'a' + (rand_int - 10);
    string ret_str(1, cch);
    return ret_str;
  }
}

// The implementations for the mutation methods.

string DataType::mutate_type_int() {
  // and also for serial.
  // This is actually 64 bits integers.


  if (this->is_range) {
    auto rand_int = get_rand_long_long(9223372036854775807); // Max long long.
    auto range = int_max - int_min;
    rand_int = (rand_int % range) + int_min;
    string rand_int_str = to_string(rand_int);
    return rand_int_str;
  }

  if (get_rand_int(3) == 0) { // 1/3 chance, choose special value.
    auto rand_choice = get_rand_int(3);
    switch (rand_choice) {
    case 0:
      return "-2147483648";
    case 1:
      return "2147483647";
    case 2:
      return "0";
    }
    return "0";
  } else {
    // Randomly mutate the number.
    auto rand_int = get_rand_long_long(9223372036854775807);
    rand_int = rand_int % 2147483649;
    string rand_int_str = to_string(rand_int);
    if (get_rand_int(2)) {
      return rand_int_str;
    } else {
      return "-" + rand_int_str;
    }
  }
}

string DataType::mutate_type_bigint() {
  // and also for serial.
  // This is actually 64 bits integers.

  if (this->is_range) {
    auto rand_int = get_rand_long_long(9223372036854775807); // Max long long.
    auto range = int_max - int_min;
    rand_int = (rand_int % range) + int_min;
    string rand_int_str = to_string(rand_int);
    return rand_int_str;
  }

  if (get_rand_int(3) == 0) { // 1/3 chance, choose special value.
    auto rand_choice = get_rand_int(3);
    switch (rand_choice) {
    case 0:
      return "-9223372036854775808";
    case 1:
      return "9223372036854775807";
    case 2:
      return "0";
    }
    return "0";
  } else {
    // Randomly mutate the number.
    auto rand_int = get_rand_long_long(9223372036854775807);
    string rand_int_str = to_string(rand_int);
    if (get_rand_int(2)) {
      return rand_int_str;
    } else {
      return "-" + rand_int_str;
    }
  }
}

string DataType::mutate_type_bit() {

  string ret_str = "B'";

  int length = 1;
  if (varying_size == VaryingArraySizeAny || varying_size == VaryingArraySizeNone) {
    length = get_rand_int(17) + 1; // do not use 0;
  } else {
    length = varying_size;
  }

  for (int i = 0; i < length; i++) {
    if (get_rand_int(2)) {
      ret_str += "1";
    } else {
      ret_str += "0";
    }
  }
  ret_str += "'";

  return ret_str;
}

string DataType::mutate_type_bool() {
  if (get_rand_int(2)) {
    return "true";
  } else {
    return "false";
  }
}

string DataType::mutate_type_bytea() {

  int len = 1;
  if (varying_size == VaryingArraySizeAny || varying_size == VaryingArraySizeNone) {
    len = get_rand_int(17) + 1; // do not use 0;
  } else {
    len = varying_size;
  }

  string ret_str = "b'";

  int format_choice = get_rand_int(3);
  switch (format_choice) {
  case 0:
    // b'abc'
    for (int i = 0; i < len; i++) {
      ret_str += get_rand_alphabet_num();
    }
    break;
  case 1:
    // b'\141\142\143'
    for (int i = 0; i < len; i++) {
      //        int rand_int = get_rand_int(256);
      int rand_int = get_rand_int(100);
      if (rand_int >= 100) {
        ret_str += "\\" + to_string(rand_int);
      } else if (rand_int >= 10) {
        ret_str += "\\x" + to_string(rand_int);
      } else { // rand_int < 10
        ret_str += "\\x0" + to_string(rand_int);
      }
    }
    break;
  case 2:
    // b'00001111'
    for (int i = 0; i < len; i++) {
      if (get_rand_int(2)) {
        ret_str += "1";
      } else {
        ret_str += "0";
      }
    }
    break;
  }

  ret_str += "'";
  return ret_str;
}

string DataType::mutate_type_char() {

  int len = 1;
  if (varying_size == VaryingArraySizeAny || varying_size == VaryingArraySizeNone) {
    len = get_rand_int(10) + 1; // do not use 0;
  } else {
    len = varying_size;
  }
  string ret_str = "'";
  ret_str.reserve(len+1);

    for (int i = 0; i < len; i++) {
      ret_str += get_rand_alphabet_num();
    }

  ret_str += "'";
  return ret_str;

}

string DataType::mutate_type_varchar() {

  int len = 1;
  if (varying_size == VaryingArraySizeAny || varying_size == VaryingArraySizeNone) {
    len = get_rand_int(10) + 1; // do not use 0;
  } else {
    len = get_rand_int(varying_size) + 1; // Range from 1 to the varying size.
  }
  string ret_str = "'";
  ret_str.reserve(len+1);

  for (int i = 0; i < len; i++) {
    ret_str += get_rand_alphabet_num();
  }

  ret_str += "'";
  return ret_str;

}

string DataType::mutate_type_cidr() {

    string ret_str = "";
    int format = get_rand_int(2);

    if (format == 0) {
      // ipv 4.
      // Typical ipv4 address.
      switch (get_rand_int(6)) {
      case 0:
        ret_str = "192.168.0.0/24";
        break;
      case 1:
        ret_str = "192.168.0.1";
        break;
      case 2:
        ret_str = "172.0.0.0/8"; // loopback
        break;
      case 3:
        ret_str = "169.254.0.0/16"; // link local
        break;
      case 4:
        ret_str = "127.0.0.1"; // localhost
        break;
      case 5:
        ret_str = "127.0.0.1/26257"; // localhost to CockroachDB/PostgreSQL port.
        break;
      }
    } else {
      // Random ipv 6 address.
      // Example: 2001:db88:3333:4444:5555:6666:7777:8888
      for (int i = 0; i < 32; i++) {
        if ((i % 4) == 0 && i != 0) {
          ret_str += ":";
        }
        ret_str += get_rand_hex_num();
      }
    }
    ret_str = "'" + ret_str + "'";

    return ret_str;

}

string DataType::mutate_type_date() {

     int month = get_rand_int(12) + 1;
     string month_str = "";
     if (month < 10) {
       month_str = "0" + to_string(month);
     } else {
       month_str = to_string(month);
     }

     int day = get_rand_int(32) + 1;
     string day_str = "";
     if (day < 10) {
       day_str = "0" + to_string(day);
     } else {
       day_str = to_string(day);
     }

     // For year, do not use the 1980 begin line.
     // range from 4713 BC to 294276 AD.
     bool is_BC = get_rand_int(2);

     int year = 0;
     if (is_BC) {
       year = get_rand_int(4714);
     } else {
       year = get_rand_int(5874898);
     }
     string year_str = "";

     // Add padding 0.
     if (year < 10) {
       year_str = "000" + to_string(year);
     } else if (year < 100) {
       year_str = "00" + to_string(year);
     } else if (year < 1000) {
       year_str = "0" + to_string(year);
     } else {
       year_str = to_string(year);
     }

     if (get_rand_int(2)) {
       year_str = year_str.substr(2, 2);
     }

     // Always use the default format of the date.
     // YYYY-DD-MM (default)
     string ret_str = "'" + year_str + "-" + month_str + "-" + day_str;
     if (is_BC) {
        ret_str += " BC";
     }
     ret_str += "'";

     return ret_str;
}

string mutate_type_float() {

     int format = get_rand_int(3);
     switch (format) {
     case 0: {
        int value = get_rand_int(3);
        if (value == 0) {
        return "'NaN'";
        } else if (value == 1) {
        return "'Infinity'";
        } else {
        return "'-Infinity'";
        }
        break;
     }
     case 1: {
        return to_string(get_rand_double(1e-37, 1e37));
     }
     }

     assert(false);
     return "";

}

string DataType::mutate_type_integer () {
  // and also for serial.
  // This is actually 32 bits integers.

  if (this->is_range) {
    auto rand_int = get_rand_long_long(9223372036854775807 + 9223372036854775808); // Max long long.
    auto range = int_max - int_min;
    rand_int = (rand_int % range) + int_min;
    string rand_int_str = to_string(rand_int);
    return rand_int_str;
  }

  if (get_rand_int(3) == 0) { // 1/3 chance, choose special value.
    auto rand_choice = get_rand_int(3);
    switch (rand_choice) {
    case 0:
      return "-9223372036854775808";
    case 1:
      return "9223372036854775807";
    case 2:
      return "0";
    }
    return "0";
  } else {
    // Randomly mutate the number.
    auto rand_int = get_rand_long_long(9223372036854775807 + 9223372036854775808);
    string rand_int_str = to_string(rand_int - 9223372036854775808);
    return rand_int_str;
  }

  assert(false);
  return "";

}

