/*
 * Copyright (c) 2016, 2021, Oracle and/or its affiliates.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License, version 2.0,
 * as published by the Free Software Foundation.
 *
 * This program is also distributed with certain software (including
 * but not limited to OpenSSL) that is licensed under separate terms, as
 * designated in a particular file or component or in included license
 * documentation. The authors of MySQL hereby grant you an additional
 * permission to link the program and your derivative works with the
 * separately licensed software that they have included with MySQL.
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See
 * the GNU General Public License, version 2.0, for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
 */

#include "grammar/MySQLLexer.h"
#include "MySQLBaseLexer.h"

using namespace antlr4;
using namespace parsers;

//----------------------------------------------------------------------------------------------------------------------

MySQLBaseLexer::MySQLBaseLexer(CharStream *input) : Lexer(input) {
  serverVersion = 80033;
  sqlMode = IgnoreSpace;
  inVersionComment = false;
}

//----------------------------------------------------------------------------------------------------------------------

void MySQLBaseLexer::reset() {
  inVersionComment = false;
  Lexer::reset();
}

//----------------------------------------------------------------------------------------------------------------------

bool MySQLBaseLexer::checkVersion(const std::string &text) {
  if (text.size() < 8) // Minimum is: /*!12345
    return false;

  // Skip version comment introducer.
  long version = std::stoul(text.c_str() + 3, NULL, 10);
  if (version <= serverVersion) {
    inVersionComment = true;
    return true;
  }
  return false;
}

//----------------------------------------------------------------------------------------------------------------------

size_t MySQLBaseLexer::determineFunction(size_t proposed) {
  // Skip any whitespace character if the sql mode says they should be ignored,
  // before actually trying to match the open parenthesis.
  if (isSqlModeActive(IgnoreSpace)) {
    size_t input = _input->LA(1);
    while (input == ' ' || input == '\t' || input == '\r' || input == '\n') {
      getInterpreter<atn::LexerATNSimulator>()->consume(_input);
      channel = HIDDEN;
      type = MySQLLexer::WHITESPACE;
      input = _input->LA(1);
    }
  }

  return _input->LA(1) == '(' ? proposed : MySQLLexer::IDENTIFIER;
}

//----------------------------------------------------------------------------------------------------------------------

size_t MySQLBaseLexer::determineNumericType(const std::string &text) {
  static const char *long_str = "2147483647";
  static const unsigned long_len = 10;
  static const char *signed_long_str = "-2147483648";
  static const char *longlong_str = "9223372036854775807";
  static const unsigned longlong_len = 19;
  static const char *signed_longlong_str = "-9223372036854775808";
  static const unsigned signed_longlong_len = 19;
  static const char *unsigned_longlong_str = "18446744073709551615";
  static const unsigned unsigned_longlong_len = 20;

  // The original code checks for leading +/- but actually that can never happen, neither in the
  // server parser (as a digit is used to trigger processing in the lexer) nor in our parser
  // as our rules are defined without signs. But we do it anyway for maximum compatibility.
  unsigned length = (unsigned)text.size() - 1;
  const char *str = text.c_str();
  if (length < long_len) // quick normal case
    return MySQLLexer::INT_NUMBER;
  unsigned negative = 0;

  if (*str == '+') // Remove sign and pre-zeros
  {
    str++;
    length--;
  } else if (*str == '-') {
    str++;
    length--;
    negative = 1;
  }

  while (*str == '0' && length) {
    str++;
    length--;
  }

  if (length < long_len)
    return MySQLLexer::INT_NUMBER;

  unsigned smaller, bigger;
  const char *cmp;
  if (negative) {
    if (length == long_len) {
      cmp = signed_long_str + 1;
      smaller = MySQLLexer::INT_NUMBER; // If <= signed_long_str
      bigger = MySQLLexer::LONG_NUMBER; // If >= signed_long_str
    } else if (length < signed_longlong_len)
      return MySQLLexer::LONG_NUMBER;
    else if (length > signed_longlong_len)
      return MySQLLexer::DECIMAL_NUMBER;
    else {
      cmp = signed_longlong_str + 1;
      smaller = MySQLLexer::LONG_NUMBER; // If <= signed_longlong_str
      bigger = MySQLLexer::DECIMAL_NUMBER;
    }
  } else {
    if (length == long_len) {
      cmp = long_str;
      smaller = MySQLLexer::INT_NUMBER;
      bigger = MySQLLexer::LONG_NUMBER;
    } else if (length < longlong_len)
      return MySQLLexer::LONG_NUMBER;
    else if (length > longlong_len) {
      if (length > unsigned_longlong_len)
        return MySQLLexer::DECIMAL_NUMBER;
      cmp = unsigned_longlong_str;
      smaller = MySQLLexer::ULONGLONG_NUMBER;
      bigger = MySQLLexer::DECIMAL_NUMBER;
    } else {
      cmp = longlong_str;
      smaller = MySQLLexer::LONG_NUMBER;
      bigger = MySQLLexer::ULONGLONG_NUMBER;
    }
  }

  while (*cmp && *cmp++ == *str++)
    ;

  return ((unsigned char)str[-1] <= (unsigned char)cmp[-1]) ? smaller : bigger;
}

//----------------------------------------------------------------------------------------------------------------------

size_t MySQLBaseLexer::checkCharset(const std::string &text) {
  return charsets.count(text) > 0 ? MySQLLexer::UNDERSCORE_CHARSET : MySQLLexer::IDENTIFIER;
}

//----------------------------------------------------------------------------------------------------------------------

/**
 * Puts a DOT token onto the pending token list.
 */
void MySQLBaseLexer::emitDot() {
  _pendingTokens.emplace_back(_factory->create({this, _input}, MySQLLexer::DOT_SYMBOL, _text, channel,
                                               tokenStartCharIndex, tokenStartCharIndex, tokenStartLine,
                                               tokenStartCharPositionInLine));
  ++tokenStartCharIndex;
}

//----------------------------------------------------------------------------------------------------------------------
