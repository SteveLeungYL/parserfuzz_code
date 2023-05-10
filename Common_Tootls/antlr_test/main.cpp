#include "antlr4-runtime.h"
#include <iostream>
#include <string>
#include "grammar/MySQLParser.h"
#include "grammar/MySQLLexer.h"

using namespace std;
using namespace parsers;

int main() {

  string str_in = "abclsejlrjeslgjs;";
  antlr4::ANTLRInputStream input(str_in);
  MySQLLexer lexer(&input);
  antlr4::CommonTokenStream tokens(&lexer);
  MySQLParser parser(&tokens);
  parser.query();

  cerr << "Error: " << parser.getNumberOfSyntaxErrors() << "\n\n\n";
  lexer.reset();
  parser.reset();

  str_in = "select * from v0;";
  input.load(str_in);
  lexer.setInputStream(&input);
  tokens.setTokenSource(&lexer);
  parser.query();
  cerr << "Error: " << parser.getNumberOfSyntaxErrors() << "\n\n\n";
  lexer.reset();
  parser.reset();

  str_in = "select * from v0 abc sjrlwejtlsdlxdrqwr re.jewskwe";
  input.load(str_in);
  lexer.setInputStream(&input);
  tokens.setTokenSource(&lexer);
  parser.query();
  cerr << "Error: " << parser.getNumberOfSyntaxErrors() << "\n\n\n";
  lexer.reset();
  parser.reset();

  return 0;
}