#ifndef __RSG_H_HEADER__
#define __RSG_H_HEADER__

#include "../include/ast.h"

void rsg_initialize();
string rsg_generate(const IRTYPE type = kUnknown);

#endif
