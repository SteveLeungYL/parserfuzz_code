#include "./duckdb_oracle.h"

void SQL_ORACLE::set_mutator(Mutator *mutator) { this->g_mutator = mutator; }

bool SQL_ORACLE::is_oracle_select_stmt(IR *cur_IR) {
  if (cur_IR->type_ == kSelectStmt) {
    return true;
  }
  return false;
}

void SQL_ORACLE::remove_all_select_stmt_from_ir(IR *ir_root) {
  IRWrapper::set_ir_root(ir_root);
  vector<IR *> stmt_vec = IRWrapper::get_stmt_ir_vec();
  for (IR *cur_stmt : stmt_vec) {
    if (this->is_select_stmt(cur_stmt))
      IRWrapper::remove_stmt_and_free(cur_stmt);
  }
}
