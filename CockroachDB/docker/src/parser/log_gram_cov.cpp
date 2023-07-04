#include "../include/log_gram_cov.h"

static GramCovMap gram_cov_map;

void log_grammar_coverage_helper(IR* cur_ir, unsigned int parent_hash) {

  if (cur_ir->get_ir_type() == TypeUnknown) {
    if (cur_ir->get_left() != nullptr) {
      log_grammar_coverage_helper(cur_ir->get_left(), parent_hash);
    }
    if (cur_ir->get_right() != nullptr) {
      log_grammar_coverage_helper(cur_ir->get_right(), parent_hash);
    }
  } else {
    // cur_ir->get_ir_type() != TypeUnknown
    gram_cov_map.log_edge_cov_map(parent_hash, cur_ir->node_hash);

    parent_hash = cur_ir->node_hash;
    if (cur_ir->get_left() != nullptr) {
      log_grammar_coverage_helper(cur_ir->get_left(), parent_hash);
    }
    if (cur_ir->get_right() != nullptr) {
      log_grammar_coverage_helper(cur_ir->get_right(), parent_hash);
    }
  }

}

void log_grammar_coverage(IR* root) {

  gram_cov_map.reset_edge_cov_map();

  log_grammar_coverage_helper(root, 0);

  gram_cov_map.has_new_grammar_bits(false, root->to_string());

}

u32 get_total_grammar_edge_cov_size_num() {
  return gram_cov_map.get_total_edge_cov_size_num();
}
