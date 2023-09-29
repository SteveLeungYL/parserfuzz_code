#ifndef __PARSER_ENTRY_H__
#define __PARSER_ENTRY_H__

#include <vector>
#include <string>

using namespace std;

class IR;

uint32_t get_total_grammar_path_cov_size_num();
uint32_t get_total_grammar_edge_cov_size_num();
int run_parser(string in, vector<IR*>&, bool is_debug = false);

#endif