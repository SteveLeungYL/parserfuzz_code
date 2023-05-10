#include "antlr4-runtime.h"
#include <iostream>
#include <string>
#include "grammar/MySQLParser.h"
#include "grammar/MySQLLexer.h"

using namespace std;
using namespace parsers;

int main() {

  string str_in = "SELECT * from v0; abc";
  antlr4::ANTLRInputStream input(str_in);
  MySQLLexer lexer(&input);
  antlr4::CommonTokenStream tokens(&lexer);
  MySQLParser parser(&tokens);
  parser.query();

  cerr << "Error: " << parser.getNumberOfSyntaxErrors() << "\n\n\n";
  lexer.reset();
  parser.reset();
  cerr << "Error: " << parser.getNumberOfSyntaxErrors() << "\n\n\n";

  return 0;
}