%{
#include "bison_parser.h"
#include <stdio.h>
#include <sstream>
#include <string>
#include <cstring>
#define TOKEN(name) { return SQL_##name; }
static thread_local std::stringstream strbuf;
%}

%option reentrant
%option bison-bridge
%option never-interactive
%option batch
%option noyywrap
%option nounput
%option warn
%option case-insensitive
%option bison-locations
%option header-file="flex_lexer.h"
%option outfile="flex_lexer.cpp"
%option prefix="ff_"
%s COMMENT
%x singlequotedstring

%%

"YES" TOKEN(YES)
";" TOKEN(SEMICOLON)

. {
	return 0;
	}

%%
