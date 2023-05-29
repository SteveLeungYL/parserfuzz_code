#include "parser_entry.h"
#include "../include/ir_wrapper.h"

#include "antlr4-runtime.h"
#include "grammar/MySQLLexer.h"
#include "grammar/MySQLParser.h"
#include "grammar/MySQLParserBaseVisitor.h"
#include "grammar_coverage_visitor/MySQLGrammarCovVisitor.h"
#include "grammar_IR_constructor/MySQL_IR_constructor.h"

using std::vector;
using std::string;

int run_parser(string str_in, vector<IR*>& ir_vec) {

  antlr4::ANTLRInputStream input(str_in);
  MySQLLexer lexer(&input);
  antlr4::CommonTokenStream tokens(&lexer);
  MySQLParser parser(&tokens);
  parser.removeErrorListeners();
  MySQLParser::QueryContext* tree = parser.query();

  MySQLGrammarCovVisitor gram_cov_visitor;
  gram_cov_visitor.set_parser(&parser);
  gram_cov_visitor.visitQuery(tree);
  gram_cov_visitor.gram_cov.has_new_grammar_bits(false, str_in);
#ifdef DEBUG
  cerr << "Grammar Cov: " << gram_cov_visitor.gram_cov.get_total_edge_cov_size_num() << "\n\n\n";
#endif

#ifdef DEBUG
  cerr << "Error: " << parser.getNumberOfSyntaxErrors() << "\n\n\n";
#endif
  if (parser.getNumberOfSyntaxErrors() == 0) {

    MySQLIRConstructor ir_constr;
    ir_constr.set_parser(&parser);
    IR* root_ir = any_cast<IR *>(ir_constr.visitQuery(tree));
    IRWrapper::get_all_ir_node(root_ir, ir_vec);

    return 0;
  } else {
    ir_vec.clear();
    return 1;
  }
}