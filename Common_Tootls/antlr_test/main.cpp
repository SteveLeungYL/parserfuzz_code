#include "antlr4-runtime.h"
#include "grammar/MySQLLexer.h"
#include "grammar/MySQLParser.h"
#include "grammar/MySQLParserBaseVisitor.h"
#include "grammar_coverage_visitor/MySQLGrammarCovVisitor.h"
#include <iostream>
#include <string>

using namespace std;
using namespace parsers;

int main() {

  string str_in = "select * from v0;";
  antlr4::ANTLRInputStream input(str_in);
  MySQLLexer lexer(&input);
  antlr4::CommonTokenStream tokens(&lexer);
  MySQLParser parser(&tokens);
  parser.query();

  cerr << "Error: " << parser.getNumberOfSyntaxErrors() << "\n\n\n";
  lexer.reset();
  parser.reset();

  input.load(str_in);
  lexer.setInputStream(&input);
  tokens.setTokenSource(&lexer);
  MySQLParser::QueryContext* tree = parser.query();
  MySQLGrammarCovVisitor tv;
  tv.set_parser(&parser);
  tv.visitQuery(tree);
  cerr << "Error: " << parser.getNumberOfSyntaxErrors() << "\n\n\n";
  tv.gram_cov.has_new_grammar_bits(false, str_in);
  lexer.reset();
  parser.reset();

  cerr << "Grammar Cov: " << tv.gram_cov.get_total_edge_cov_size_num() << "\n\n\n";

  return 0;
}