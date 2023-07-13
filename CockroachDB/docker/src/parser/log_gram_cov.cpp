#include "../include/log_gram_cov.h"
#include "../include/gram_edge_rand_hash.h"
#include <fstream>
#include <map>
#include <ctime>

using namespace std;

static GramCovMap gram_cov_map;
static ofstream cov_out("cov_out.txt", ios::out);
static map<unsigned int, unsigned int> saved_hash;

void log_grammar_coverage_helper(IR* cur_ir, unsigned int parent_hash, IRTYPE parent_type) {

  if (cur_ir->get_ir_type() == TypeUnknown) {
    if (cur_ir->get_left() != nullptr) {
      log_grammar_coverage_helper(cur_ir->get_left(), parent_hash, parent_type);
    }
    if (cur_ir->get_right() != nullptr) {
      log_grammar_coverage_helper(cur_ir->get_right(), parent_hash, parent_type);
    }
  } else {
    // cur_ir->get_ir_type() != TypeUnknown
    unsigned int cur_node_hash = edge_hash[cur_ir->get_ir_type() - TypeUnknown];
    gram_cov_map.log_edge_cov_map(parent_hash, cur_node_hash);

    if (saved_hash.count(((parent_hash >> 1) ^ cur_node_hash)) == 0) {
      cov_out << get_string_by_ir_type(parent_type) << "," << get_string_by_ir_type(cur_ir->get_ir_type()) << "," << ((parent_hash >> 1) ^ cur_node_hash) << "," << time(NULL) << "\n";
      saved_hash[((parent_hash >> 1) ^ cur_node_hash)]  = 1;
    }

    parent_hash = cur_node_hash;
    parent_type = cur_ir->get_ir_type();
    if (cur_ir->get_left() != nullptr) {
      log_grammar_coverage_helper(cur_ir->get_left(), parent_hash, parent_type);
    }
    if (cur_ir->get_right() != nullptr) {
      log_grammar_coverage_helper(cur_ir->get_right(), parent_hash, parent_type);
    }
  }

}
void log_grammar_coverage(IR* root) {

  gram_cov_map.reset_edge_cov_map();

  log_grammar_coverage_helper(root, 0, TypeRoot);

  gram_cov_map.has_new_grammar_bits(false, root->to_string());

}

u32 get_total_grammar_edge_cov_size_num() {
  return gram_cov_map.get_total_edge_cov_size_num();
}
