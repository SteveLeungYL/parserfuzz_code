#ifndef SRC_PARSER_HELPER_H
#define SRC_PARSER_HELPER_H

#include "../include/ast.h"
#include <vector>

vector<IR*> parser_helper(const string in_str, GramCovMap* p_gram);

/*
** The interface to the LEMON-generated parser
*/
void *IRParserAlloc(void* (*)(size_t));
void IRParserFree(void*, void(*)(void*));
void IRParser(void*, int, const char*, vector<IR*>* v_ir);

#endif // SRC_PARSER_HELPER_H