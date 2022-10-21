#ifndef SRC_DATA_AFFINITY_H
#define SRC_DATA_AFFINITY_H

#include <vector>
#include "define.h" // import the ALLDATATAFFINITY(V)
#include <string>
#include <memory>

using namespace std;

enum DATAAFFINITYTYPE {
#define DECLARE_TYPE(v) v,
    ALLDATAAFFINITY(DECLARE_TYPE)
#undef DECLARE_TYPE
        AFFIELEMENTCOUNT,
};

enum COLLATIONTYPE {
#define DECLARE_TYPE(v) v,
    ALLCOLLATIONS(DECLARE_TYPE)
#undef DECLARE_TYPE
};

string get_string_by_affinity_type(DATAAFFINITYTYPE type);

DATAAFFINITYTYPE get_data_affinity_by_idx(int idx);
DATAAFFINITYTYPE get_data_affinity_by_string(string s);

class DataAffinity {
    /* DataAffninty. Represent all data types supported by CockroachDB EXCEPT for `ARRAY`.  */
    // TODO:: FIXME:: ARRAY type.
private:
    DATAAFFINITYTYPE data_affinity;
    bool is_range;
    bool is_enum;
    long long int_min;
    long long int_max;
    double float_min;
    double float_max;
    vector<string> v_enum_str;

    /* Helper functions. */
    bool is_str_collation (const string& str_in);
    string get_rand_collation_str();

    DATAAFFINITYTYPE detect_numerical_type(const string&);
    DATAAFFINITYTYPE detect_string_type(const string&);

    string mutate_affi_int(); // and also for serial.
    string mutate_affi_oid(); // unsigned oid.
    string mutate_affi_float(); // decimal and float.
    string mutate_affi_array();
    string mutate_affi_collate();
    string mutate_affi_bool();
    string mutate_affi_bit();
    string mutate_affi_byte();
    string mutate_affi_jsonb();
    string mutate_affi_interval();
    string mutate_affi_date();
    string mutate_affi_timestamp();
    string mutate_affi_timestamptz();
    string mutate_affi_uuid();
    string mutate_affi_enum();
    string mutate_affi_inet();
    string mutate_affi_time();
    string mutate_affi_timetz();
    string mutate_affi_string();

    string get_rand_alphabet_num();
    string add_random_time_zone();

public:
    DataAffinity(): data_affinity(AFFIUNKNOWN), is_range(false), is_enum(false) {
        int_min = 0;
        int_max = 0;
        float_min = 0.0;
        float_max = 0.0;
    }

    DATAAFFINITYTYPE recognize_data_type(const string& str_in); // Return `this` pointer.
    DATAAFFINITYTYPE get_data_affinity() { return this->data_affinity; }
    void set_data_affinity(DATAAFFINITYTYPE in) { this->data_affinity = in; }

    string get_mutated_literal();

};

#endif //SRC_DATA_AFFINITY_H
