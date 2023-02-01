#ifndef __RSG_H__
#define __RSG_H__
#include "../include/ast.h"
#include <string>

void rsg_initialize();
string rsg_generate(const IRTYPE type = kUnknown);

#endif
