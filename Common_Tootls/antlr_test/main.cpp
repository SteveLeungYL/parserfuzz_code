#include "antlr4-runtime.h"
#include "grammar/MySQLLexer.h"
#include "grammar/MySQLParser.h"
#include "grammar/MySQLParserBaseVisitor.h"
#include "grammar_coverage_visitor/MySQLGrammarCovVisitor.h"
#include "grammar_IR_constructor/MySQL_IR_constructor.h"

#include <iostream>
#include <string>

using namespace std;
using namespace parsers;

void debug(IR* root, unsigned level) {

  for (unsigned i = 0; i < level; i++) {
    cerr << " ";
  }

  cerr << level << ": "
       << get_string_by_ir_type(root->type_) << ": "
       << get_string_by_data_type(root->data_type_) << ": "
       << get_string_by_data_flag(root->data_flag_) << ": "
       << root->uniq_id_in_tree_ << ": "
       << root -> to_string()
       << endl;

  if (root->left_) {
    debug(root->left_, level + 1);
  }
  if (root->right_) {
    debug(root->right_, level + 1);
  }
}

void debug(IR *root){
  debug(root, 0);
}

int main() {

  string str_in = "CREATE TABLE v0 (v1 int, v2 TEXT);";
  antlr4::ANTLRInputStream input(str_in);
  MySQLLexer lexer(&input);
  antlr4::CommonTokenStream tokens(&lexer);
  MySQLParser parser(&tokens);
  parser.query();

  cerr << "Error: " << parser.getNumberOfSyntaxErrors() << "\n\n\n";
  lexer.reset();
  parser.reset();

  str_in = "SELECT * FROM v0;";
  input.load(str_in);
  lexer.setInputStream(&input);
  tokens.setTokenSource(&lexer);
  MySQLParser::QueryContext* tree = parser.query();
  MySQLGrammarCovVisitor gram_cov_visitor;
  gram_cov_visitor.set_parser(&parser);
  gram_cov_visitor.visitQuery(tree);
  gram_cov_visitor.gram_cov.has_new_grammar_bits(false, str_in);
  cerr << "Grammar Cov: " << gram_cov_visitor.gram_cov.get_total_edge_cov_size_num() << "\n\n\n";

  MySQLIRConstructor ir_constr;
  ir_constr.set_parser(&parser);
  IR* root_ir = any_cast<IR *>(ir_constr.visitQuery(tree));
  if (root_ir != nullptr) {
    debug(root_ir);
  }

  cerr << "Error: " << parser.getNumberOfSyntaxErrors() << "\n\n\n";

  lexer.reset();
  parser.reset();


  return 0;
}