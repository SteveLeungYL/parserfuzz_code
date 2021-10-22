%{
#include "bison_parser.h"
#include "flex_lexer.h"
#include <stdio.h>
#include <string.h>
int yyerror(YYLTYPE* llocp, IR * result, yyscan_t scanner, const char *msg) { return 0; }
%}
%code requires {
#include "../include/ast.h"
#include "parser_typedef.h"
#include "../include/define.h"
}
%define api.prefix	{ff_}
%define parse.error	verbose
%define api.pure	full
%define api.token.prefix	{SQL_}
%locations

%initial-action {
    // Initialize
    @$.first_column = 0;
    @$.last_column = 0;
    @$.first_line = 0;
    @$.last_line = 0;
    @$.total_column = 0;
    @$.string_length = 0;
};
%lex-param { yyscan_t scanner }
%parse-param { IR* result }
%parse-param { yyscan_t scanner }
%union FF_STYPE{
	IR *	program_t;
	IR *	stmtlist_t;
}

%token YES
%token SEMICOLON

%type <program_t>	program
%type <stmtlist_t>	stmtlist


%%
program:
	stmtlist SEMICOLON {
		$$ = result;
		IR* tmp1 = $1;
		result->update_left(tmp1);
		result->op_ = OP3("", ";", "");
		$$ = NULL;
	}
  ;

stmtlist:
	YES {
		$$ = new IR(kStmtlist, OP3("YES", "", ""));
	}
  ;
%%
