#ifndef __RSG_H_HEADER__
#define __RSG_H_HEADER__

#include <string>
#include "../include/sql_ir_define.hpp"

using namespace std;
using namespace duckdb_libpgquery;

void rsg_initialize();
string rsg_generate(const string type = "Stmt");
string rsg_generate(const IRTYPE type = kStmt);

// Coverage feedback for the RSG module.
void rsg_clear_chosen_expr();
void rsg_exec_succeed();
void rsg_exec_failed();

#endif
