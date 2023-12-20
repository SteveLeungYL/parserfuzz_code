#ifndef SRC_PARSER_HELPER_H
#define SRC_PARSER_HELPER_H

#include <string>
#include <vector>
#include "../include/sql_ir_define.hpp"

using namespace std;
using namespace duckdb_libpgquery;

vector<IR*> parser_helper(const string in_str);
uint32_t get_total_edge_cov_size_num();

#endif // SRC_PARSER_HELPER_H