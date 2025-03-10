/*
 * Copyright (c) 2016, 2018, Oracle and/or its affiliates. All rights reserved.
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

#pragma once

#include "Parser.h"

#ifdef _MSC_VER
#ifdef PARSERS_EXPORTS
#define PARSERS_PUBLIC_TYPE __declspec(dllexport)
#else
#define PARSERS_PUBLIC_TYPE __declspec(dllimport)
#endif
#else
#define PARSERS_PUBLIC_TYPE
#endif

namespace antlr4 {
  class PARSERS_PUBLIC_TYPE Parser;
}

namespace parsers {

  class PARSERS_PUBLIC_TYPE MySQLBaseCommon {
  public:
    // SQL modes that control parsing behavior.
    enum SqlMode {
      NoMode             = 0,
      AnsiQuotes         = 1 << 0,
      HighNotPrecedence  = 1 << 1,
      PipesAsConcat      = 1 << 2,
      IgnoreSpace        = 1 << 3,
      NoBackslashEscapes = 1 << 4
    };

    // For parameterizing the parsing process.
    long serverVersion;
    SqlMode sqlMode; // A collection of flags indicating which of relevant SQL modes are active.

    bool isSqlModeActive(size_t mode) {
      return (sqlMode & mode) != 0;
    }
  };

} // namespace parsers
