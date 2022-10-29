#include "ast.h"
#include "data_affinity.h"
#include <string>

IR *convert_json_to_IR(string json_str);
void constr_key_pair_datatype_lib(string key_pair_str, vector<string>& v_all_key_str, map<string, DataAffinity> &mapped_key_pair);
