#ifndef SRC_JSON_IR_CONVERTOR_H
#define SRC_JSON_IR_CONVERTOR_H

#include "ast.h"
#include "data_types.h"
#include <string>

void constr_sql_func_lib(string func_types_str, vector<string> v_all_func_str,
                         map<DATATYPE, vector<string> >& func_ret_type_to_str_map,
                         map<string, vector<vector<DataType> > >& func_str_to_type_map);

#endif // SRC_JSON_IR_CONVERTOR_H
