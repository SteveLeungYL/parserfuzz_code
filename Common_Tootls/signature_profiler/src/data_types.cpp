#include "../header/data_types.h"
#include "../header/utils.h"
#include <iostream>

map<string, string> DataTypeAlias2TypeStr = {
    {"INT8", "BIGINT"},
    {"SERIAL8", "BIGSERIAL"},
    {"BIT VARYING", "VARBIT"},
    {"BOOLEAN", "BOOL"},
    {"CHARACTER", "CHAR"},
    {"CHARACTER VARYING", "VARCHAR"},
    {"\"CHAR\"", "TEXT"},
    //    {"CSTRING", "TEXT"}, // CSTRING is not a simple text. It represent a
    // text for a specific type. Create this type and special handing for
    // this type.
    {"DOUBLE PRECISION", "FLOAT"},
    {"FLOAT8", "FLOAT"},
    {"INTEGER", "INT"},
    {"INT4", "INT"},
    {"DECIMAL", "NUMERIC"},
    {"FLOAT4", "REAL"},
    {"INT2", "SMALLINT"},
    {"SERIAL2", "SMALLSERIAL"},
    {"SERIAL4", "SERIAL"},
    {"TIME WITH TIME ZONE", "TIMETZ"},
    {"TIME WITHOUT TIME ZONE", "TIME"},
    {"TIMESTAMP WITH TIME ZONE", "TIMESTAMPTZ"},
    {"TIMESTAMP WITHOUT TIME ZONE", "TIMESTAMP"},
    {"REGPROC", "OID"},
    {"REGPROCEDURE", "OID"},
    {"REGOPERATOR", "OID"},
    {"REGCLASS", "OID"},
    {"REGTYPE", "OID"},
    {"REGROLE", "OID"},
    {"REGNAMESPACE", "OID"},
    {"REGCONFIG", "OID"},
    {"REGDICTIONARY", "OID"},
    {"NAME", "TEXT"} // May not be accurate. May contains a few enum.
                     //    {"TID", "OID"}, // Not accurate.
                     //    {"XID", "OID"}, // Not accurate.
                     //    {"CID", "OID"}, // Not accurate.
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

  // Do not parse any data type that is larger than TYPENOTSUPPORT in the define.h
#define DECLARE_CASE(dataTypeName)                                             \
  if (str_toupper(in) == #dataTypeName) {                                      \
    if ((k##dataTypeName - kTYPEUNKNOWN) >                                     \
        (kTYPENOTSUPPORT - kTYPEUNKNOWN - 1)) {                                \
      return kTYPEUNKNOWN;                                                     \
    } else {                                                                   \
      return k##dataTypeName;                                                  \
    }                                                                          \
  }
  ALLDATATYPE(DECLARE_CASE);
#undef DECLARE_CASE

#ifdef DEBUG
  cerr << "\n\n\nError: Cannot find the matching data affinity by"
          " string: \"" +
              in + "\" \n\n\n";
#endif
  //  assert(false);
  return kTYPEUNKNOWN;
}

void DataType::init_data_type_with_str(string in) {

  /* Parse the Data Type string,
   * rewriting the alias string to its original form,
   * and then init the DataType struct with the given information.
   * */

  // Sample type string: char (3)[3][3]. The `()` stands for char size, the
  // second and third `[]` stands for array size.

  in = str_toupper(in);

  // Special handling for ANYRANGE and ANYMULTIRANGE.
  if (in == "ANYRANGE") {
    this->set_data_type(kTYPEANY);
    this->set_range_type(RangeType::single_range);
    return;
  } else if (in == "ANYMULTIRANGE") {
    this->set_data_type(kTYPEANY);
    this->set_range_type(RangeType::multi_range);
    return;
  }

  // Special handling for - (stands for kTYPENONE)
  else if (in == "-") {
    this->set_data_type(kTYPENONE);
    return;
  }

  string tmp;
  tmp.reserve(in.size());
  for (int idx = 0; idx < in.size(); idx++) {
    if (in[idx] != '"') {
      tmp += in[idx];
    }
  }
  in = tmp;

  // Spot the ARRAY keyword. Remove it.
  this->is_array = false;
  vector<string> v_in_split = string_splitter(in, "ARRAY");
  if (v_in_split.size() > 1) {
    in = "";
    for (int idx = 0; idx < v_in_split.size(); idx++) {
      in += v_in_split[idx];
    }
    this->is_array = true;
  }

  // Spot the VECTOR keyword. Remove it.
  this->is_vector = false;
  v_in_split = string_splitter(in, "VECTOR");
  if (v_in_split.size() > 1) {
    in = "";
    for (int idx = 0; idx < v_in_split.size(); idx++) {
      in += v_in_split[idx];
    }
    this->is_vector = true;
  }

  // Change the ANYCOMPATIBLE to ANY, remove the compatible.
  v_in_split = string_splitter(in, "COMPATIBLE");
  if (v_in_split.size() > 1) {
    in = "";
    for (int idx = 0; idx < v_in_split.size(); idx++) {
      in += v_in_split[idx];
    }
  }
  // ANYELEMENT -> ANY
  v_in_split = string_splitter(in, "ELEMENT");
  if (v_in_split.size() > 1) {
    in = "";
    for (int idx = 0; idx < v_in_split.size(); idx++) {
      in += v_in_split[idx];
    }
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

  // Remove the () or [] symbol following the Data Type Name. Construct the
  // simple string that only declare the data type.
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

  if (!findStringIn(simple_str, "TYPE")) {
    simple_str = "TYPE" + simple_str;
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
    varying_size_str =
        string_splitter(varying_size_str, "[").front(); // always existed.
    varying_size_str = varying_size_str.substr(0, varying_size_str.size() -
                                                      1); // remove the right ).

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
    array_size_str = array_size_str.substr(0, array_size_str.size() - 1);
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
  if (v_array_size.size() == 0 && is_array) {
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
      this->get_v_array_size().front() > VaryingArraySizeNone) {
    // Ignore the varying size for each array elements.
    res_str = get_string_by_data_type(this->get_data_type_enum());
    for (int i = 0; i < get_v_array_size().size(); i++) {
      res_str += "_" + to_string(get_v_array_size()[i]);
    }

    return get_str_hash(res_str.c_str(), res_str.size());
  }

  // Handle rest of the normal types. Also need to care about the varying size.
  res_str = get_string_by_data_type(this->get_data_type_enum());
  if (varying_size != VaryingArraySizeNone) {
    res_str += to_string(varying_size);
  }
  return get_str_hash(res_str.c_str(), res_str.size());
}

string DataType::get_str_from_data_type() const {

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

  if (this->get_is_range()) {
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

string DataType::mutate_type_float() {
  double value = get_rand_double(1e-37, 1e37);
  return to_string(value);
}

string DataType::mutate_type_bigint() {
  // and also for serial.
  // This is actually 64 bits integers.

  if (this->get_is_range()) {
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
  if (varying_size == VaryingArraySizeAny ||
      varying_size == VaryingArraySizeNone) {
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
  if (varying_size == VaryingArraySizeAny ||
      varying_size == VaryingArraySizeNone) {
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
  if (varying_size == VaryingArraySizeAny ||
      varying_size == VaryingArraySizeNone) {
    len = get_rand_int(10) + 1; // do not use 0;
  } else {
    len = varying_size;
  }
  string ret_str = "'";
  ret_str.reserve(len + 1);

  for (int i = 0; i < len; i++) {
    ret_str += get_rand_alphabet_num();
  }

  ret_str += "'";
  return ret_str;
}

string DataType::mutate_type_varchar() {

  int len = 1;
  if (varying_size == VaryingArraySizeAny ||
      varying_size == VaryingArraySizeNone) {
    len = get_rand_int(10) + 1; // do not use 0;
  } else {
    len = get_rand_int(varying_size) + 1; // Range from 1 to the varying size.
  }
  string ret_str = "'";
  ret_str.reserve(len + 1);

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
  }
  case 1: {
    return to_string(get_rand_double(1e-37, 1e37));
  }
  }

  assert(false);
  return "";
}

string DataType::mutate_type_interval() {
  // INTERVAL '1 year 2 months 3 days 4 hours 5 minutes 6 seconds'

  string ret_str = "";

  int second = get_rand_int(60);
  int min = get_rand_int(60);
  int hour = get_rand_int(24);
  int day = get_rand_int(31);
  int month = get_rand_int(12);
  int year = get_rand_int(10); // 10 years range?

  // Second.
  ret_str += to_string(second) + " seconds";

  if (get_rand_int(5) == 0) {
    // 80% chance, ignore the rest.
    goto interval_early_break;
  }

  // Minute.
  ret_str = to_string(min) + " minutes " + ret_str;

  if (get_rand_int(5) == 0) {
    // 80% chance, ignore the rest.
    goto interval_early_break;
  }

  // Hour.
  ret_str = to_string(hour) + " hours " + ret_str;

  if (get_rand_int(5) == 0) {
    // 80% chance, ignore the rest.
    goto interval_early_break;
  }

  // Day.
  ret_str = to_string(day) + " days " + ret_str;

  if (get_rand_int(5) == 0) {
    // 80% chance, ignore the rest.
    goto interval_early_break;
  }

  // Month.
  ret_str = to_string(month) + " months " + ret_str;

  if (get_rand_int(5) == 0) {
    // 80% chance, ignore the rest.
    goto interval_early_break;
  }

  // Year.
  ret_str = to_string(year) + " years " + ret_str;

  if (get_rand_int(5) == 0) {
    // 80% chance, ignore the rest.
    goto interval_early_break;
  }

interval_early_break:
  ret_str = "'" + ret_str + "'";

  return ret_str;
}

string DataType::mutate_type_json() {
  const string ret_str = "'{\"hello\": \"world\"}'";
  return ret_str;
}

string DataType::mutate_type_macaddr() {
  int format = get_rand_int(7);
  switch (format) {
  case 0:
    return "'08:00:2b:01:02:03'";
  case 1:
    return "'08-00-2b-01-02-03'";
  case 2:
    return "'08002b:010203'";
  case 3:
    return "'08002b-010203'";
  case 4:
    return "'0800.2b01.0203'";
  case 5:
    return "'0800-2b01-0203'";
  case 6:
    return "'08002b010203'";
  }
  assert(false);
  return "";
}

string DataType::mutate_type_macaddr8() {
  int format = get_rand_int(8);
  switch (format) {
  case 0:
    return "'08:00:2b:01:02:03:04:05'";
  case 1:
    return "'08-00-2b-01-02-03-04-05'";
  case 2:
    return "'08002b:0102030405'";
  case 3:
    return "'08002b-0102030405'";
  case 4:
    return "'0800.2b01.0203.0405'";
  case 5:
    return "'0800-2b01-0203-0405'";
  case 6:
    return "'08002b01:02030405'";
  case 7:
    return "'08002b0102030405'";
  }
  assert(false);
  return "";
}

string DataType::mutate_type_money() {
  double value = get_rand_double(-92233720368547758.08, 92233720368547758.07);
  return "'" + to_string(value) + "'::money";
}

string DataType::mutate_type_real() {
  double value = get_rand_double(1e-37, 1e37);
  return to_string(value);
}

string DataType::mutate_type_smallint() {
  int value = get_rand_int(-32768, 32767);
  return to_string(value);
}

string DataType::mutate_type_time() {

  // Only supporting the ISO 8601 format.
  // Sample: 04:05:06.789.

  string ret_str = "";

  int hours = get_rand_int(24);
  string hours_str = "";
  if (hours < 10) {
    hours_str = "0" + to_string(hours);
  } else {
    hours_str = to_string(hours);
  }

  int mins = get_rand_int(60);
  string mins_str = "";
  if (mins < 10) {
    mins_str = "0" + to_string(mins);
  } else {
    mins_str = to_string(mins);
  }

  int secs = get_rand_int(60);
  string secs_str = "";
  if (secs < 10) {
    secs_str = "0" + to_string(secs);
  } else {
    secs_str = to_string(secs);
  }

  ret_str += hours_str;
  ret_str += ":";
  ret_str += mins_str;
  ret_str += ":";
  ret_str += secs_str;

  // Optional microsecond precision. HH:MM:SS.SSSSSS
  if (get_rand_int(2) < 1) {
    // Append 4 digits microsecond precision.
    ret_str += ".";
    ret_str += to_string(get_rand_int(10));
    ret_str += to_string(get_rand_int(10));
    ret_str += to_string(get_rand_int(10));
    ret_str += to_string(get_rand_int(10));
  }

  ret_str = "'" + ret_str + "'";

  return ret_str;
}

string DataType::mutate_type_timestamp() {
  return mutate_type_date() + " " + mutate_type_time();
}

string DataType::mutate_type_uuid() {

  int format = get_rand_int(2);
  string ret_str = "";

  if (format == 0) {
    // Hyphen-separated groups of 8, 4, 4, 4, and 12 hexadecimal digits.
    // Example: acde070d-8c4c-4f0d-9d8a-162843c10333
    for (int i = 0; i < 32; i++) {
      //            cerr << "\n" << ret_str << "\n";
      if (i == 8 || i == 12 || i == 16 || i == 20) {
        ret_str += "-";
      }
      ret_str += get_rand_hex_num();
    }
    ret_str = "'" + ret_str + "'";
  } else {
    // UUID value specified as a BYTES value.
    // b'kafef00ddeadbeed'
    for (int i = 0; i < 16; i++) {
      ret_str += get_rand_hex_num();
    }
    ret_str = "b'" + ret_str + "'";
  }

  return ret_str;
}

string DataType::mutate_array_type_helper(int depth) {
  // Recursive function to instantiate one ARRAY type constant.

  string ret_str;
  if (depth == 0) {
    ret_str = "ARRAY";
  }

  ret_str += "[";
  for (int i = 0; i < v_array_size[depth]; i++) {
    if (depth != v_array_size.size() - 1) {
      ret_str += this->mutate_array_type_helper(depth + 1);
    } else {
      ret_str += this->mutate_type_entry_helper();
    }
    if (i != v_array_size[depth] - 1) {
      ret_str += ",";
    }
  }
  ret_str += "]";

  return ret_str;
}

DATATYPE DataType::gen_rand_any_type() {
  DATATYPE start_type = kTYPEBIGINT;
  DATATYPE end_type = kTYPEOID;
  return DATATYPE(start_type + (end_type - start_type));
}

string DataType::mutate_type_entry(DATATYPE default_type) {
  // Main mutate type entry. Also handles the ARRAY, TUPLE and VECTOR types.

  if (default_type != kTYPEUNKNOWN) {
    this->set_data_type(default_type);
  }

  if (this->get_data_type_enum() == kTYPENONE ||
      this->get_data_type_enum() == kTYPEVOID) {
    // If the type is TYPENONE or TYPEVOID, just return empty string.
    return "";
  }

  string ret_str;

  // Tuple type. No need to consider is_text_bounded.
  if (this->v_tuple_types.size() != 0) {
    ret_str += "(";
    for (int i = 0; i < v_tuple_types.size(); i++) {
      ret_str += v_tuple_types[i]->mutate_type_entry_helper();
      if (i != v_tuple_types.size() - 1) {
        ret_str += ",";
      }
    }
    ret_str += ")";
    return ret_str;
  }

  // Vector type. NEED to consider is_text_bounded.
  if (this->is_vector) {
    DATATYPE type_enum = this->get_data_type_enum();
#define comp(x) type_enum == x
    if (comp(kTYPEINT) || comp(kTYPEBIGINT) || comp(kTYPEBIGSERIAL) ||
        comp(kTYPEBOOL) || comp(kTYPEOID) || comp(kTYPEFLOAT) ||
        comp(kTYPEREAL) || comp(kTYPESMALLINT) || comp(kTYPESMALLSERIAL)) {
      int num_vec = get_rand_int(3) + 1; // Avoid 0
      ret_str += "'";
      for (int i = 0; i < num_vec; i++) {
        ret_str += mutate_type_entry_helper() + " "; // Separated by space.
      }
      string type_str = get_str_from_data_type();
      // the substr function removes the TYPE prefix.
      ret_str += "'::" + type_str.substr(4, type_str.size() - 4) + "VECTOR";
      if (this->get_is_text_bounded() && this->is_number_related_type()) {
        return "'" + ret_str + "'";
      } else {
        return ret_str;
      }
#undef comp
    } else {
      cerr << "\n\n\nERROR: Type: " << get_str_from_data_type()
           << " cannot be used"
              " to construct vector type. Not support. \n\n\n";
      assert(false);
    }
  }

  // Array type.
  if (this->is_array) {
    if (this->v_array_size.size() == 0) {
      cerr << "\n\n\nError: Detect empty v_array_size when is_array is true. "
              "\n\n\n";
      assert(false);
    }
    if (this->get_is_text_bounded() && this->is_number_related_type()) {
      return "'" + mutate_array_type_helper() + "'"; // depth = 0;
    } else {
      return mutate_array_type_helper(); // depth = 0;
    }
  }

  // Not array, not vector.
  // Normal constant type entry.
  if (this->get_is_text_bounded() && this->is_number_related_type()) {
    return "'" + mutate_type_entry_helper() + "'";
  } else {
    return mutate_type_entry_helper();
  }
}

string DataType::mutate_type_entry_helper() {

  switch (this->get_data_type_enum()) {
  case kTYPEINT:
    return mutate_type_int();
  case kTYPEBIGINT:
    return mutate_type_bigint();
  case kTYPEBIGSERIAL:
    return mutate_type_bigserial();
  case kTYPEBIT:
    return mutate_type_bit();
  case kTYPEVARBIT:
    return mutate_type_varbit();
  case kTYPEBOOL:
    return mutate_type_bool();
  case kTYPEBYTEA:
    return mutate_type_bytea();
  case kTYPECHAR:
    return mutate_type_char();
  case kTYPEVARCHAR:
    return mutate_type_varchar();
  case kTYPECIDR:
    return mutate_type_cidr();
  case kTYPEINET:
    return mutate_type_inet();
  case kTYPEDATE:
    return mutate_type_date();
  case kTYPEFLOAT:
    return mutate_type_float();
  case kTYPEINTERVAL:
    return mutate_type_interval();
  case kTYPEJSON:
    return mutate_type_json();
  case kTYPEJSONB:
    return mutate_type_jsonb();
  case kTYPEMACADDR:
    return mutate_type_macaddr();
  case kTYPEMACADDR8:
    return mutate_type_macaddr8();
  case kTYPEMONEY:
    return mutate_type_money();
  case kTYPENUMERIC:
    return mutate_type_numeric();
  case kTYPEREAL:
    return mutate_type_real();
  case kTYPESMALLINT:
    return mutate_type_smallint();
  case kTYPESMALLSERIAL:
    return mutate_type_smallserial();
  case kTYPETEXT:
    return mutate_type_text();
  case kTYPETIME:
    return mutate_type_time();
  case kTYPETIMETZ:
    return mutate_type_timetz();
  case kTYPETIMESTAMP:
    return mutate_type_timestamp();
  case kTYPETIMESTAMPTZ:
    return mutate_type_timestamptz();
  case kTYPEUUID:
    return mutate_type_uuid();
  case kTYPEOID:
    return mutate_type_oid();
  default:
    cerr << "\n\n\nERROR: For type: " << get_str_from_data_type()
         << ", cannot find"
            " the mutate function. \n\n\n";
    assert(false);
  }

  assert(false);
  return "";
}

bool DataType::is_number_related_type() {

  if (is_text_bounded) {
    return false;
  }

  switch (this->get_data_type_enum()) {
  case kTYPEINT:
  case kTYPEBIGINT:
  case kTYPEBIGSERIAL:
  case kTYPEFLOAT:
    //  case kTYPEMONEY:
  case kTYPENUMERIC:
  case kTYPEREAL:
  case kTYPESMALLINT:
  case kTYPESMALLSERIAL:
  case kTYPEOID:
    return true;
  default:
    return false;
  }
}

bool DataType::is_text_related_type() {
  return !(this->is_number_related_type());
}