#ifndef SRC_PARSER_HELPER_H
#define SRC_PARSER_HELPER_H

#include "../include/ast.h"

vector<IR*> parse_helper(string in);

/*
** The interface to the LEMON-generated parser
*/
void *IRParserAlloc(void(*)(void*));
void IRParserFree(void*, void(*)(void*));
void IRParser(void*, int, IR*, IR*);

#endif // SRC_PARSER_HELPER_H