//
// Created by Yu Liang on 5/10/23.
//

#ifndef ANTLR_TEST_MYSQLBASERECONIZER_H
#define ANTLR_TEST_MYSQLBASERECONIZER_H


#include "MySQLBaseCommon.h"
#include "Parser.h"

namespace antlr4 {
class PARSERS_PUBLIC_TYPE Parser;
}

namespace parsers {

class PARSERS_PUBLIC_TYPE MySQLBaseRecognizer : public antlr4::Parser,
                                                public MySQLBaseCommon {
public:
  MySQLBaseRecognizer(antlr4::TokenStream *input) : Parser(input) {
//    removeErrorListeners();
  }


  virtual void reset() override { Parser::reset(); };
};

}

#endif // ANTLR_TEST_MYSQLBASERECONIZER_H
