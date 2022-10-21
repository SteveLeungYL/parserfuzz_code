#include "ast.h"
#include "data_affinity.h"
#include <string>

IR *convert_json_to_IR(string json_str);
void constr_set_session_lib(string, vector<string>& all_affi_str, map<string, DataAffinity>&);
