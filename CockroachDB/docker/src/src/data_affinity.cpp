#include "../include/data_affinity.h"

string get_string_by_affinity_type(DATAAFFINITYTYPE type) {
#define DECLARE_CASE(classname)                                                \
  if (type == classname)                                                       \
    return #classname;
    ALLDATAAFFINITY(DECLARE_CASE);
#undef DECLARE_CASE
    return "";
}

DATAAFFINITYTYPE get_data_affinity_by_string(string s) {
#define DECLARE_CASE(dataAffiname)                                             \
  if (s == #dataAffiname)                                                      \
    return dataAffiname;
    ALLDATAAFFINITY(DECLARE_CASE);
#undef DECLARE_CASE
    return AFFIUNKNOWN;
}

DATAAFFINITYTYPE get_data_affinity_by_idx(int idx) { return static_cast<DATAAFFINITYTYPE>(idx); }

DataAffinity* DataAffinity::recognize_data_type(string str_in){
    /* Given the string input, detects its possible data type.  */

    // First, determine whether it is a numerical type or string type.
    bool is_numerical = false;

    return nullptr;
}