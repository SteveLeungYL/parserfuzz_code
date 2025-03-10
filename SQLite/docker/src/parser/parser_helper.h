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

/*
** The interface to the LEMON-generated parser
*/
void *ParserCovAlloc(void* (*)(size_t));
void ParserCovFree(void*, void(*)(void*));
void ParserCov(void*, int, const char*, GramCovMap*);

#endif // SRC_PARSER_HELPER_H