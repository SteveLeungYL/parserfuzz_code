#ifndef SRC_DATA_AFFINITY_H
#define SRC_DATA_AFFINITY_H

#include <vector>
#include "define.h" // import the ALLDATATAFFINITY(V)
#include <string>
#include <map>

using namespace std;

extern map<string, string> sql_type_alias_2_type;

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

DATAAFFINITYTYPE get_random_affinity_type(bool is_basic_type_only = true, bool is_no_array = false);
string get_random_affinity_type_str(bool is_basic_type_only = true);
string get_random_affinity_type_str_formal(bool is_basic_type_only = true);
string get_affinity_type_str_formal(DATAAFFINITYTYPE);

DATAAFFINITYTYPE get_data_affinity_by_idx(int idx);
DATAAFFINITYTYPE get_data_affinity_by_string(string s);

class DataAffinity {

private:
    // Data Structure.
    DATAAFFINITYTYPE data_affinity;
    bool is_range;
    bool is_enum;
    long long int_min;
    long long int_max;
    double float_min;
    double float_max;
    vector<string> v_enum_str;

//    unique_ptr<vector<DataAffinity>> v_array_elem;

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
    string mutate_affi_onoff();
    string mutate_affi_onoffauto();
    string mutate_affi_bit();
    string mutate_affi_byte();
    string mutate_affi_jsonb();
    string mutate_affi_interval();
    string mutate_affi_intervaltz();
    string mutate_affi_date();
    string mutate_affi_timestamp();
    string mutate_affi_timestamptz();
    string mutate_affi_uuid();
    string mutate_affi_enum();
    string mutate_affi_inet();
    string mutate_affi_time();
    string mutate_affi_timetz();
    string mutate_affi_string();

    // Spatial types
    /* Seems not implemented. */
//    string mutate_affi_box2d();
//    string mutate_affi_void();
//    string mutate_affi_point();
//    string mutate_affi_linestring();
//    string mutate_affi_polygon();
//    string mutate_affi_multipoint();
//    string mutate_affi_multilinestring();
//    string mutate_affi_multipolygon();
//    string mutate_affi_geometrycollection();

    string get_rand_alphabet_num();
    string get_rand_hex_num();
    string add_random_time_zone();
    DATAAFFINITYTYPE transfer_array_to_normal_type(DATAAFFINITYTYPE in_type);

public:
    DataAffinity(): data_affinity(AFFIUNKNOWN), is_range(false), is_enum(false),
        int_min(0), int_max(0), float_min(0.0), float_max(0.0) {
            // No need to init v_enum_str;
    }

    // Copy constructor.
    DataAffinity(const DataAffinity& copy_in):
            data_affinity(copy_in.get_data_affinity()),
            is_range(copy_in.get_is_range()),
            is_enum(copy_in.get_is_enum()),
            int_min(copy_in.get_int_min()),
            int_max(copy_in.get_int_max()),
            float_min(copy_in.get_float_min()),
            float_max(copy_in.get_float_max()),
            v_enum_str(copy_in.get_v_enum_str()) {
        // No need to handle any other things.
//        std::cerr << "\n\n\nCopy instructor called. \n\n\n";
    }

    DATAAFFINITYTYPE recognize_data_type(const string& str_in); // Return `this` pointer.

    DATAAFFINITYTYPE get_data_affinity() const { return this->data_affinity; }
    void set_data_affinity(DATAAFFINITYTYPE in) { this->data_affinity = in; }

    void set_is_range(bool in) {this->is_range = in;}
    bool get_is_range() const {return this->is_range;}

    void set_is_enum(bool in) {this->is_enum = in;}
    bool get_is_enum() const {return this->is_enum;}

    void set_v_enum_str(const vector<string>& in) {this->v_enum_str = in;}
    vector<string> get_v_enum_str() const {return this->v_enum_str;}

    void set_int_range(long long min, long long max) { this->int_min = min; this->int_max = max;}
    long long get_int_max() const {return this->int_max;}
    long long get_int_min() const {return this->int_min;}

    void set_float_range(double min, double max) { this->float_min = min; this->float_max = max;}
    double get_float_max() const {return this->float_max;}
    double get_float_min() const {return this->float_min;}

    string get_mutated_literal(DATAAFFINITYTYPE type_in = AFFIUNKNOWN);

    template <typename T>
    void set_range(T min, T max, DATAAFFINITYTYPE data_affi = AFFIINT) {
        switch(data_affi) {
            case AFFIINT:
            case AFFIARRAYINT:
            case AFFIOID:
            case AFFIARRAYOID:
            case AFFISERIAL:
            case AFFIARRAYSERIAL:
                set_int_range(min, max);
                return;
            case AFFIDECIMAL:
            case AFFIARRAYDECIMAL:
            case AFFIFLOAT:
            case AFFIARRAYFLOAT:
                set_float_range(min, max);
                return;
            default:
                set_int_range(min, max);
                return;
        }
    }

};

#endif //SRC_DATA_AFFINITY_H
