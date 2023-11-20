#ifndef SRC_PARSER_HELPER_H
#define SRC_PARSER_HELPER_H

#include <string>
#include <vector>
#include "../include/sql_ir_define.hpp"
#include "../include/gram_cov.hpp"

using namespace std;
using namespace duckdb_libpgquery;

vector<IR*> parser_helper(const string in_str, GramCovMap* p_gram);

#endif // SRC_PARSER_HELPER_H