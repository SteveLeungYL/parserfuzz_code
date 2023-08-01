#ifndef __RSG_H_HEADER__
#define __RAG_H_HEADER__

#include "../include/ast.h"
#include <string>

void rsg_initialize();
string rsg_generate(const string& type);
string rsg_generate(const IRTYPE type = TypeUnknown);

// Coverage feedback for the RSG module.
void rsg_clear_chosen_expr();
void rsg_exec_succeed();
void rsg_exec_failed();

#endif