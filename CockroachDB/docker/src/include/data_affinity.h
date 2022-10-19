#ifndef SRC_DATA_AFFINITY_H
#define SRC_DATA_AFFINITY_H

#include <vector>
#include "define.h" // import the ALLDATATAFFINITY(V)
#include <string>

using namespace std;

enum DATAAFFINITYTYPE {
#define DECLARE_TYPE(v) v,
    ALLDATAAFFINITY(DECLARE_TYPE)
#undef DECLARE_TYPE
        AFFIELEMENTCOUNT,
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
    int int_min;
    int int_max;
    double float_min;
    double float_max;
    vector<string> v_enum_str;



    /* Helper functions. */
    bool is_str_collation (const string& str_in);
    DATAAFFINITYTYPE detect_numerical_type(const string&);
    DATAAFFINITYTYPE detect_string_type(const string&);

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

};

#endif //SRC_DATA_AFFINITY_H
