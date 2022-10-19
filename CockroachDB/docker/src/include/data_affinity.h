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
};

string get_string_by_affinity_type(DATAAFFINITYTYPE type);

DATAAFFINITYTYPE get_data_affinity_by_idx(int idx);

DATAAFFINITYTYPE get_data_affinity_by_string(string s);

class DataAffinity {
private:
    DATAAFFINITYTYPE data_affinity;
    bool is_range;
    bool is_enum;
    int int_min;
    int int_max;
    double float_min;
    double float_max;
    vector<string> v_enum_str;


public:
    DataAffinity(): data_affinity(AFFIUNKNOWN), is_range(false), is_enum(false) {
        int_min = 0;
        int_max = 0;
        float_min = 0.0;
        float_max = 0.0;
    }

    DataAffinity* recognize_data_type(string str_in); // Return `this` pointer.


};

#endif //SRC_DATA_AFFINITY_H
