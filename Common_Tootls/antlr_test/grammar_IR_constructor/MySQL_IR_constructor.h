#ifndef ANTLR_TEST_MYSQLIRCONSTRUCTOR_H
#define ANTLR_TEST_MYSQLIRCONSTRUCTOR_H

// DO NOT MODIFY THIS FILE. 
// This code is generated from PYTHON script generate_MySQL_IR_constructor.h.
// Use ANTLR4 to generate the MySQLParserBaseVisitor.h in ../grammar/ before calling the python generation script.

#include <iostream>
#include <cstring>
#include <filesystem>
#include <typeinfo>

#include "../MySQLBaseCommon.h"
#include "../grammar/MySQLParserBaseVisitor.h"

using namespace std;
using namespace parsers;

//#define DEBUG

typedef int8_t s8;
typedef int16_t s16;
typedef int32_t s32;
typedef int64_t s64;
typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef unsigned long long u64;

#define MAP_SIZE_POW2 18
#define MAP_SIZE (1 << MAP_SIZE_POW2)

#define likely(_x) __builtin_expect(!!(_x), 1)
#define unlikely(_x) __builtin_expect(!!(_x), 0)

class MySQLIRConstructor: public parsers::MySQLParserBaseVisitor {
private:

  MySQLParser* p_parser;

public:

  void set_parser(MySQLParser* in) {this->p_parser = in;}

  virtual std::any visitQuery(MySQLParser::QueryContext *ctx) override {

    for (int i = 0; i < ctx->children.size(); i++) {
      if (antlr4::ParserRuleContext* tmp = dynamic_cast<antlr4::ParserRuleContext*>(ctx->children[i])) {
        cerr << "Current rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->children[i])->getRuleIndex()] << "\n";
      } else {
        cerr << "Current token: " << dynamic_cast<antlr4::tree::TerminalNode*>(ctx->children[i])->getSymbol()->getText() << "\n";
      }
    }

    cerr << "\n\n\n";
    return visitChildren(ctx);
  }

  virtual std::any visitPureIdentifier(MySQLParser::PureIdentifierContext *ctx) override {

    cerr << "Inside pureidentifier\n";
    for (int i = 0; i < ctx->children.size(); i++) {
      if (antlr4::ParserRuleContext* tmp = dynamic_cast<antlr4::ParserRuleContext*>(ctx->children[i])) {
        cerr << "Current rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->children[i])->getRuleIndex()] << "\n";
      } else {
        cerr << "Current token: " << dynamic_cast<antlr4::tree::TerminalNode*>(ctx->children[i])->getSymbol()->getText() << "\n";
        cerr << "token type: " << dynamic_cast<antlr4::tree::TerminalNode*>(ctx->children[i])->getSymbol()->getType() << "\n";
        if (dynamic_cast<antlr4::tree::TerminalNode*>(ctx->children[i])->getSymbol()->getType() == MySQLParser::IDENTIFIER) {
          cerr << "Matched\n\n\n";
        }
      }
    }

    cerr << "\n\n\n";

    return visitChildren(ctx);
  }
};

#endif