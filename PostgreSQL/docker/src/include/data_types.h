#ifndef SRC_DATA_TYPES_H
#define SRC_DATA_TYPES_H

#include "define.h"
#include <map>
#include <memory>
#include <string>
#include <vector>

using namespace std;

#define VaryingArraySizeNone -1
#define VaryingArraySizeAny 0

extern map<string, string> DataTypeAlias2TypeStr;

enum RangeType {
  range_none = 0,
  single_range,
  multi_range
};

enum DATATYPE {
#define DECLARE_TYPE(v) k##v,
  ALLDATATYPE(DECLARE_TYPE)
#undef DECLARE_TYPE
};

class DataType {

private:
  // Data Structure.
  DATATYPE data_type;
  bool is_range;
  long long int_min;
  long long int_max;
  double float_min;
  double float_max;
  vector<string> v_enum_str;
  bool is_array;
  bool is_vector;
  RangeType range_type;
  bool is_text_bounded;

  int varying_size; // Determine the varying size of one data, e.g. 3 for
                    // VARCHAR[3]
  vector<int> v_array_size; // Support multiple dimensional array.

  /* For various data types inside the Tuple.  */
  vector<shared_ptr<DataType> > v_tuple_types;

  string get_rand_alphabet_num();
  string get_rand_hex_num();

public:
  DataType()
      : data_type(kTYPEUNKNOWN), is_range(false), int_min(0),
        int_max(0), float_min(0.0), float_max(0.0),
        is_array(false), is_vector(false),
        range_type(range_none), is_text_bounded(false),
        varying_size(VaryingArraySizeNone) {}

  DataType(const DATATYPE type_in)
      : data_type(type_in), is_range(false), int_min(0),
        int_max(0), float_min(0.0), float_max(0.0),
        is_array(false), is_vector(false),
        range_type(range_none), is_text_bounded(false),
        varying_size(VaryingArraySizeNone) {}

  DataType(const string &type_str): is_range(false),
                                     int_min(0),
                                     int_max(0), float_min(0.0), float_max(0.0),
                                     range_type(range_none), is_text_bounded(false),
                                     varying_size(VaryingArraySizeAny) { init_data_type_with_str(type_str); }

  // Copy constructor.
  DataType(const DataType &copy_in)
      : data_type(copy_in.get_data_type_enum()),
        is_range(false),
        int_min(copy_in.get_int_min()),
        int_max(copy_in.get_int_max()), float_min(copy_in.get_float_min()),
        float_max(copy_in.get_float_max()),
        v_enum_str(copy_in.get_v_enum_str()),
        is_array(copy_in.get_is_array()), is_vector(copy_in.get_is_vector()),
        range_type(range_none),
        is_text_bounded(false),
        varying_size(copy_in.get_varying_size()),
        v_array_size(copy_in.get_v_array_size()),
        v_tuple_types(copy_in.get_v_tuple_type()) {}

  DATATYPE get_data_type_enum() const { return this->data_type; }
  void set_data_type(DATATYPE in) { this->data_type = in; }

  void set_is_range(bool in) {this->is_range = in;}
  bool get_is_range() const {return this->is_range;}

  void set_range_type(RangeType in) { this->range_type = in; }
  RangeType get_range_type() const { return this->range_type; }

  bool get_is_text_bounded() { return this->is_text_bounded; }
  void set_is_text_bounded(bool in) { this->is_text_bounded = in; }

  void set_v_enum_str(const vector<string> &in) { this->v_enum_str = in; }
  vector<string> get_v_enum_str() const { return this->v_enum_str; }
  bool get_is_array() const {return this->is_array;}
  bool get_is_vector() const {return this->is_vector;}

  vector<shared_ptr<DataType> > get_v_tuple_type() const {
    return this->v_tuple_types;
  }

  void set_int_range(long long min, long long max) {
    this->int_min = min;
    this->int_max = max;
  }
  long long get_int_max() const { return this->int_max; }
  long long get_int_min() const { return this->int_min; }

  void set_float_range(double min, double max) {
    this->float_min = min;
    this->float_max = max;
  }
  double get_float_max() const { return this->float_max; }
  double get_float_min() const { return this->float_min; }

  int get_varying_size() const { return this->varying_size; }
  vector<int> get_v_array_size() const { return this->v_array_size; }

  template <typename T>
  void set_range(T min, T max, DATATYPE data_type = kTYPEINT) {
    switch (data_type) {
    case kTYPEINT:
    case kTYPEBIGINT:
    case kTYPEBIGSERIAL:
    case kTYPEPGLSN:
    case kTYPESMALLINT:
    case kTYPESMALLSERIAL:
    case kTYPESERIAL:
      set_int_range(min, max);
      return;
    case kTYPEMONEY:
    case kTYPENUMERIC:
    case kTYPEREAL:
    case kTYPEFLOAT:
      set_float_range(min, max);
      return;
    default:
      set_int_range(min, max);
      return;
    }
  }

  unsigned long long calc_hash();

  void init_data_type_with_str(string in);
  DATATYPE get_data_type_from_simple_str(string in);
  string get_str_from_data_type() const;

  vector<int> get_v_array_size() {return this->v_array_size;}

  bool is_number_related_type();
  bool is_text_related_type();

  DATATYPE gen_rand_any_type();
  // Mutation method entry.
  string mutate_type_entry(DATATYPE default_type = kTYPEUNKNOWN);
  string mutate_type_entry_helper();
  string mutate_array_type_helper(int depth = 0);
  // Mutation methods for the different data types.
  string mutate_type_int();
  string mutate_type_oid() {return mutate_type_int(); }
  string mutate_type_bigint();
  string mutate_type_bigserial() {return mutate_type_bigint(); }
  string mutate_type_serial() {return mutate_type_int(); }
  string mutate_type_bit();
  string mutate_type_varbit() {return mutate_type_bit(); }
  string mutate_type_bool();
  string mutate_type_bytea();
  string mutate_type_char();
  string mutate_type_varchar();
  string mutate_type_cidr();
  string mutate_type_inet() {return mutate_type_cidr(); }
  string mutate_type_date();
  string mutate_type_float();
  string mutate_type_interval();
  string mutate_type_json();
  string mutate_type_jsonb() {return mutate_type_json(); }
  string mutate_type_macaddr();
  string mutate_type_macaddr8();
  string mutate_type_money();
  string mutate_type_numeric() {return mutate_type_float(); }
  string mutate_type_real();
  string mutate_type_smallint();
  string mutate_type_smallserial() {return mutate_type_serial(); }
  string mutate_type_text() {return mutate_type_varchar(); }
  string mutate_type_time();
  string mutate_type_timetz() {return mutate_type_time();}
  string mutate_type_timestamp();
  string mutate_type_timestamptz() {return mutate_type_timestamp();}
  string mutate_type_uuid();
};

#endif // SRC_DATA_TYPES_H