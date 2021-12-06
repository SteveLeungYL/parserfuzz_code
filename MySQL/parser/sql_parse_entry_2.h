#ifndef SQL_PARSE_ENTRY_2_H_
#define SQL_PARSE_ENTRY_2_H_


#include "sql/parser_yystype.h"
#include "sql/parse_location.h"
#include "sql/sql_class.h"

bool my_yyoverflow(short **a, YYSTYPE **b, YYLTYPE **c, ulong *yystacksize);
int MYSQLlex(YYSTYPE *yacc_yylval, YYLTYPE *yylloc, THD *thd);


#endif // SQL_PARSE_ENTRY_2_H_
