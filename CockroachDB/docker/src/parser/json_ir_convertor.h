#include "../include/ast.h"
#include "../include/data_affinity.h"
#include <string>

IR *convert_json_to_IR(string json_str);
void constr_set_session_lib(string, map<string, DataAffinity>&);
