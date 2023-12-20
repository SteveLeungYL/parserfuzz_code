//
// Created by Yu Liang on 3/13/23.
//

#include <cassert>
#include <string.h>
#include <vector>
#include "parser_helper.h"

namespace duckdb_libpgquery {
    class IR;
    void pg_parser_init();
    void pg_parser_parse_ret_ir(const char *query, std::vector<IR*>& res);
    void pg_parser_cleanup();
    uint32_t pg_parser_get_grammar_edge_cov_num();
}

using namespace duckdb_libpgquery;


vector<IR*> parser_helper(const string in_str) {

    pg_parser_init();

    vector<IR *> ir_vec;

    duckdb_libpgquery::pg_parser_parse_ret_ir(in_str.c_str(), ir_vec);

    duckdb_libpgquery::pg_parser_cleanup();

    int unique_id_for_node = 0;
    for (auto ir: ir_vec) {
        ir->uniq_id_in_tree_ = unique_id_for_node++;
    }

    return ir_vec;

}

uint32_t get_total_edge_cov_size_num() {
    return duckdb_libpgquery::pg_parser_get_grammar_edge_cov_num();
}