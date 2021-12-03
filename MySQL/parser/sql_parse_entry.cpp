#include "./sql_parse_entry.h"
#include "./bison_parser.h"
#include "sql/sql_lex_hash.h"
#include "sql/sql_lex_hints.h"

#include "include/my_config.h"


#include "sql/sql_class.h"
#include "sql/sql_lex.h"
#include "sql/parse_tree_node_base.h"
#include "sql/parse_tree_nodes.h"
#include "sql/table.h"
#include "sql/sql_parse.h"
#include "sql/error_handler.h"
#include "include/mysys_err.h"
#include "sql/sql_locale.h"
#include "sql/derror.h"
#include "sql/sp_head.h"



/* Helper functions */

static const char *long_str = "2147483647";
static const uint long_len = 10;
static const char *signed_long_str = "-2147483648";
static const char *longlong_str = "9223372036854775807";
static const uint longlong_len = 19;
static const char *signed_longlong_str = "-9223372036854775808";
static const uint signed_longlong_len = 19;
static const char *unsigned_longlong_str = "18446744073709551615";
static const uint unsigned_longlong_len = 20;

extern int MYSQLparse(class THD * thd, class Parse_tree_root * *root, vector<IR*>& ir_vec, IR* res);

bool parse_sql_entry(THD *thd, Parser_state *parser_state,
               Object_creation_ctx *creation_ctx, vector<IR*>& ir_vec);

int MYSQLlex(YYSTYPE *yacc_yylval, YYLTYPE *yylloc, THD *thd);

/*
  Return an unescaped text literal without quotes
  Fix sometimes to do only one scan of the string
*/

static bool consume_optimizer_hints(Lex_input_stream *lip) {
  const my_lex_states *state_map = lip->query_charset->state_maps->main_map;
  int whitespace = 0;
  uchar c = lip->yyPeek();
  size_t newlines = 0;

  for (; state_map[c] == MY_LEX_SKIP;
       whitespace++, c = lip->yyPeekn(whitespace)) {
    if (c == '\n') newlines++;
  }

  if (lip->yyPeekn(whitespace) == '/' && lip->yyPeekn(whitespace + 1) == '*' &&
      lip->yyPeekn(whitespace + 2) == '+') {
    lip->yylineno += newlines;
    lip->yySkipn(whitespace);  // skip whitespace

    Hint_scanner hint_scanner(lip->m_thd, lip->yylineno, lip->get_ptr(),
                              lip->get_end_of_query() - lip->get_ptr(),
                              lip->m_digest);
    PT_hint_list *hint_list = nullptr;
    int rc = HINT_PARSER_parse(lip->m_thd, &hint_scanner, &hint_list);
    if (rc == 2)
      return true;  // Bison's internal OOM error
    else if (rc == 1) {
      /*
        This branch is for 2 cases:
        1. YYABORT in the hint parser grammar (we use it to process OOM errors),
        2. open commentary error.
      */
      lip->start_token();  // adjust error message text pointer to "/*+"
      return true;
    } else {
      lip->yylineno = hint_scanner.get_lineno();
      lip->yySkipn(hint_scanner.get_ptr() - lip->get_ptr());
      lip->yylval->optimizer_hints = hint_list;  // NULL in case of syntax error
      lip->m_digest =
          hint_scanner.get_digest();  // NULL is digest buf. is full.
      return false;
    }
  } else
    return false;
}


static char *get_text(Lex_input_stream *lip, int pre_skip, int post_skip) {
  uchar c, sep;
  uint found_escape = 0;
  const CHARSET_INFO *cs = lip->m_thd->charset();

  lip->tok_bitmap = 0;
  sep = lip->yyGetLast();  // String should end with this
  while (!lip->eof()) {
    c = lip->yyGet();
    lip->tok_bitmap |= c;
    {
      int l;
      if (use_mb(cs) &&
          (l = my_ismbchar(cs, lip->get_ptr() - 1, lip->get_end_of_query()))) {
        lip->skip_binary(l - 1);
        continue;
      }
    }
    if (c == '\\' && !(lip->m_thd->variables.sql_mode &
                       MODE_NO_BACKSLASH_ESCAPES)) {  // Escaped character
      found_escape = 1;
      if (lip->eof()) return nullptr;
      lip->yySkip();
    } else if (c == sep) {
      if (c == lip->yyGet())  // Check if two separators in a row
      {
        found_escape = 1;  // duplicate. Remember for delete
        continue;
      } else
        lip->yyUnget();

      /* Found end. Unescape and return string */
      const char *str, *end;
      char *start;

      str = lip->get_tok_start();
      end = lip->get_ptr();
      /* Extract the text from the token */
      str += pre_skip;
      end -= post_skip;
      assert(end >= str);

      if (!(start =
                static_cast<char *>(lip->m_thd->alloc((uint)(end - str) + 1))))
        return const_cast<char *>("");  // MEM_ROOT has set error flag

      lip->m_cpp_text_start = lip->get_cpp_tok_start() + pre_skip;
      lip->m_cpp_text_end = lip->get_cpp_ptr() - post_skip;

      if (!found_escape) {
        lip->yytoklen = (uint)(end - str);
        memcpy(start, str, lip->yytoklen);
        start[lip->yytoklen] = 0;
      } else {
        char *to;

        for (to = start; str != end; str++) {
          int l;
          if (use_mb(cs) && (l = my_ismbchar(cs, str, end))) {
            while (l--) *to++ = *str++;
            str--;
            continue;
          }
          if (!(lip->m_thd->variables.sql_mode & MODE_NO_BACKSLASH_ESCAPES) &&
              *str == '\\' && str + 1 != end) {
            switch (*++str) {
              case 'n':
                *to++ = '\n';
                break;
              case 't':
                *to++ = '\t';
                break;
              case 'r':
                *to++ = '\r';
                break;
              case 'b':
                *to++ = '\b';
                break;
              case '0':
                *to++ = 0;  // Ascii null
                break;
              case 'Z':  // ^Z must be escaped on Win32
                *to++ = '\032';
                break;
              case '_':
              case '%':
                *to++ = '\\';  // remember prefix for wildcard
                [[fallthrough]];
              default:
                *to++ = *str;
                break;
            }
          } else if (*str == sep)
            *to++ = *str++;  // Two ' or "
          else
            *to++ = *str;
        }
        *to = 0;
        lip->yytoklen = (uint)(to - start);
      }
      return start;
    }
  }
  return nullptr;  // unexpected end of query
}

static int find_keyword(Lex_input_stream *lip, uint len, bool function) {
  const char *tok = lip->get_tok_start();

  const SYMBOL *symbol =
      function ? Lex_hash::sql_keywords_and_funcs.get_hash_symbol(tok, len)
               : Lex_hash::sql_keywords.get_hash_symbol(tok, len);

  if (symbol) {
    lip->yylval->keyword.symbol = symbol;
    lip->yylval->keyword.str = const_cast<char *>(tok);
    lip->yylval->keyword.length = len;

    if ((symbol->tok == NOT_SYM) &&
        (lip->m_thd->variables.sql_mode & MODE_HIGH_NOT_PRECEDENCE))
      return NOT2_SYM;
    if ((symbol->tok == OR_OR_SYM) &&
        !(lip->m_thd->variables.sql_mode & MODE_PIPES_AS_CONCAT)) {
      push_deprecated_warn(lip->m_thd, "|| as a synonym for OR", "OR");
      return OR2_SYM;
    }

    lip->yylval->optimizer_hints = nullptr;
    if (symbol->group & SG_HINTABLE_KEYWORDS) {
      lip->add_digest_token(symbol->tok, lip->yylval);
      if (consume_optimizer_hints(lip)) return ABORT_SYM;
      lip->skip_digest = true;
    }

    return symbol->tok;
  }
  return 0;
}

static LEX_STRING get_token(Lex_input_stream *lip, uint skip, uint length) {
  LEX_STRING tmp;
  lip->yyUnget();  // ptr points now after last token char
  tmp.length = lip->yytoklen = length;
  tmp.str = lip->m_thd->strmake(lip->get_tok_start() + skip, tmp.length);

  lip->m_cpp_text_start = lip->get_cpp_tok_start() + skip;
  lip->m_cpp_text_end = lip->m_cpp_text_start + tmp.length;

  return tmp;
}

/*
 todo:
   There are no dangerous charsets in mysql for function
   get_quoted_token yet. But it should be fixed in the
   future to operate multichar strings (like ucs2)
*/

static LEX_STRING get_quoted_token(Lex_input_stream *lip, uint skip,
                                   uint length, char quote) {
  LEX_STRING tmp;
  const char *from, *end;
  char *to;
  lip->yyUnget();  // ptr points now after last token char
  tmp.length = lip->yytoklen = length;
  tmp.str = (char *)lip->m_thd->alloc(tmp.length + 1);
  from = lip->get_tok_start() + skip;
  to = tmp.str;
  end = to + length;

  lip->m_cpp_text_start = lip->get_cpp_tok_start() + skip;
  lip->m_cpp_text_end = lip->m_cpp_text_start + length;

  for (; to != end;) {
    if ((*to++ = *from++) == quote) {
      from++;  // Skip double quotes
      lip->m_cpp_text_start++;
    }
  }
  *to = 0;  // End null for safety
  return tmp;
}

static inline uint int_token(const char *str, uint length) {
  if (length < long_len)  // quick normal case
    return NUM;
  bool neg = false;

  if (*str == '+')  // Remove sign and pre-zeros
  {
    str++;
    length--;
  } else if (*str == '-') {
    str++;
    length--;
    neg = true;
  }
  while (*str == '0' && length) {
    str++;
    length--;
  }
  if (length < long_len) return NUM;

  uint smaller, bigger;
  const char *cmp;
  if (neg) {
    if (length == long_len) {
      cmp = signed_long_str + 1;
      smaller = NUM;      // If <= signed_long_str
      bigger = LONG_NUM;  // If >= signed_long_str
    } else if (length < signed_longlong_len)
      return LONG_NUM;
    else if (length > signed_longlong_len)
      return DECIMAL_NUM;
    else {
      cmp = signed_longlong_str + 1;
      smaller = LONG_NUM;  // If <= signed_longlong_str
      bigger = DECIMAL_NUM;
    }
  } else {
    if (length == long_len) {
      cmp = long_str;
      smaller = NUM;
      bigger = LONG_NUM;
    } else if (length < longlong_len)
      return LONG_NUM;
    else if (length > longlong_len) {
      if (length > unsigned_longlong_len) return DECIMAL_NUM;
      cmp = unsigned_longlong_str;
      smaller = ULONGLONG_NUM;
      bigger = DECIMAL_NUM;
    } else {
      cmp = longlong_str;
      smaller = LONG_NUM;
      bigger = ULONGLONG_NUM;
    }
  }
  while (*cmp && *cmp++ == *str++)
    ;
  return ((uchar)str[-1] <= (uchar)cmp[-1]) ? smaller : bigger;
}

static bool consume_comment(Lex_input_stream *lip,
                            int remaining_recursions_permitted) {
  // only one level of nested comments are allowed
  assert(remaining_recursions_permitted == 0 ||
         remaining_recursions_permitted == 1);
  uchar c;
  while (!lip->eof()) {
    c = lip->yyGet();

    if (remaining_recursions_permitted == 1) {
      if ((c == '/') && (lip->yyPeek() == '*')) {
        push_warning(
            lip->m_thd, Sql_condition::SL_WARNING,
            ER_WARN_DEPRECATED_SYNTAX_NO_REPLACEMENT,
            ER_THD(lip->m_thd, ER_WARN_DEPRECATED_NESTED_COMMENT_SYNTAX));
        lip->yyUnput('(');  // Replace nested "/*..." with "(*..."
        lip->yySkip();      // and skip "("
        lip->yySkip();      /* Eat asterisk */
        if (consume_comment(lip, 0)) return true;
        lip->yyUnput(')');  // Replace "...*/" with "...*)"
        lip->yySkip();      // and skip ")"
        continue;
      }
    }

    if (c == '*') {
      if (lip->yyPeek() == '/') {
        lip->yySkip(); /* Eat slash */
        return false;
      }
    }

    if (c == '\n') lip->yylineno++;
  }

  return true;
}


static int lex_one_token(Lexer_yystype *yylval, THD *thd) {
  uchar c = 0;
  bool comment_closed;
  int tokval, result_state;
  uint length;
  enum my_lex_states state;
  Lex_input_stream *lip = &thd->m_parser_state->m_lip;
  const CHARSET_INFO *cs = thd->charset();
  const my_lex_states *state_map = cs->state_maps->main_map;
  const uchar *ident_map = cs->ident_map;

  lip->yylval = yylval;  // The global state

  lip->start_token();
  state = lip->next_state;
  lip->next_state = MY_LEX_START;
  for (;;) {
    switch (state) {
      case MY_LEX_START:  // Start of token
        // Skip starting whitespace
        while (state_map[c = lip->yyPeek()] == MY_LEX_SKIP) {
          if (c == '\n') lip->yylineno++;

          lip->yySkip();
        }

        /* Start of real token */
        lip->restart_token();
        c = lip->yyGet();
        state = state_map[c];
        break;
      case MY_LEX_CHAR:  // Unknown or single char token
      case MY_LEX_SKIP:  // This should not happen
        if (c == '-' && lip->yyPeek() == '-' &&
            (my_isspace(cs, lip->yyPeekn(1)) ||
             my_iscntrl(cs, lip->yyPeekn(1)))) {
          state = MY_LEX_COMMENT;
          break;
        }

        if (c == '-' && lip->yyPeek() == '>')  // '->'
        {
          lip->yySkip();
          lip->next_state = MY_LEX_START;
          if (lip->yyPeek() == '>') {
            lip->yySkip();
            return JSON_UNQUOTED_SEPARATOR_SYM;
          }
          return JSON_SEPARATOR_SYM;
        }

        if (c != ')') lip->next_state = MY_LEX_START;  // Allow signed numbers

        /*
          Check for a placeholder: it should not precede a possible identifier
          because of binlogging: when a placeholder is replaced with its value
          in a query for the binlog, the query must stay grammatically correct.
        */
        if (c == '?' && lip->stmt_prepare_mode && !ident_map[lip->yyPeek()])
          return (PARAM_MARKER);

        return ((int)c);

      case MY_LEX_IDENT_OR_NCHAR:
        if (lip->yyPeek() != '\'') {
          state = MY_LEX_IDENT;
          break;
        }
        /* Found N'string' */
        lip->yySkip();  // Skip '
        if (!(yylval->lex_str.str = get_text(lip, 2, 1))) {
          state = MY_LEX_CHAR;  // Read char by char
          break;
        }
        yylval->lex_str.length = lip->yytoklen;
        return (NCHAR_STRING);

      case MY_LEX_IDENT_OR_HEX:
        if (lip->yyPeek() == '\'') {  // Found x'hex-number'
          state = MY_LEX_HEX_NUMBER;
          break;
        }
        [[fallthrough]];
      case MY_LEX_IDENT_OR_BIN:
        if (lip->yyPeek() == '\'') {  // Found b'bin-number'
          state = MY_LEX_BIN_NUMBER;
          break;
        }
        [[fallthrough]];
      case MY_LEX_IDENT:
        const char *start;
        if (use_mb(cs)) {
          result_state = IDENT_QUOTED;
          switch (my_mbcharlen(cs, lip->yyGetLast())) {
            case 1:
              break;
            case 0:
              if (my_mbmaxlenlen(cs) < 2) break;
              [[fallthrough]];
            default:
              int l =
                  my_ismbchar(cs, lip->get_ptr() - 1, lip->get_end_of_query());
              if (l == 0) {
                state = MY_LEX_CHAR;
                continue;
              }
              lip->skip_binary(l - 1);
          }
          while (ident_map[c = lip->yyGet()]) {
            switch (my_mbcharlen(cs, c)) {
              case 1:
                break;
              case 0:
                if (my_mbmaxlenlen(cs) < 2) break;
                [[fallthrough]];
              default:
                int l;
                if ((l = my_ismbchar(cs, lip->get_ptr() - 1,
                                     lip->get_end_of_query())) == 0)
                  break;
                lip->skip_binary(l - 1);
            }
          }
        } else {
          for (result_state = c; ident_map[c = lip->yyGet()]; result_state |= c)
            ;
          /* If there were non-ASCII characters, mark that we must convert */
          result_state = result_state & 0x80 ? IDENT_QUOTED : IDENT;
        }
        length = lip->yyLength();
        start = lip->get_ptr();
        if (lip->ignore_space) {
          /*
            If we find a space then this can't be an identifier. We notice this
            below by checking start != lex->ptr.
          */
          for (; state_map[c] == MY_LEX_SKIP; c = lip->yyGet()) {
            if (c == '\n') lip->yylineno++;
          }
        }
        if (start == lip->get_ptr() && c == '.' && ident_map[lip->yyPeek()])
          lip->next_state = MY_LEX_IDENT_SEP;
        else {  // '(' must follow directly if function
          lip->yyUnget();
          if ((tokval = find_keyword(lip, length, c == '('))) {
            lip->next_state = MY_LEX_START;  // Allow signed numbers
            return (tokval);                 // Was keyword
          }
          lip->yySkip();  // next state does a unget
        }
        yylval->lex_str = get_token(lip, 0, length);

        /*
           Note: "SELECT _bla AS 'alias'"
           _bla should be considered as a IDENT if charset haven't been found.
           So we don't use MYF(MY_WME) with get_charset_by_csname to avoid
           producing an error.
        */

        if (yylval->lex_str.str[0] == '_') {
          auto charset_name = yylval->lex_str.str + 1;
          const CHARSET_INFO *underscore_cs =
              get_charset_by_csname(charset_name, MY_CS_PRIMARY, MYF(0));
          if (underscore_cs) {
            lip->warn_on_deprecated_charset(underscore_cs, charset_name);
            if (underscore_cs == &my_charset_utf8mb4_0900_ai_ci) {
              /*
                If underscore_cs is utf8mb4, and the collation of underscore_cs
                is the default collation of utf8mb4, then update underscore_cs
                with a value of the default_collation_for_utf8mb4 system
                variable:
              */
              underscore_cs = thd->variables.default_collation_for_utf8mb4;
            }
            yylval->charset = underscore_cs;
            lip->m_underscore_cs = underscore_cs;

            lip->body_utf8_append(lip->m_cpp_text_start,
                                  lip->get_cpp_tok_start() + length);
            return (UNDERSCORE_CHARSET);
          }
        }

        lip->body_utf8_append(lip->m_cpp_text_start);

        lip->body_utf8_append_literal(thd, &yylval->lex_str, cs,
                                      lip->m_cpp_text_end);

        return (result_state);  // IDENT or IDENT_QUOTED

      case MY_LEX_IDENT_SEP:  // Found ident and now '.'
        yylval->lex_str.str = const_cast<char *>(lip->get_ptr());
        yylval->lex_str.length = 1;
        c = lip->yyGet();  // should be '.'
        lip->next_state =
            MY_LEX_IDENT_START;         // Next is an ident (not a keyword)
        if (!ident_map[lip->yyPeek()])  // Probably ` or "
          lip->next_state = MY_LEX_START;
        return ((int)c);

      case MY_LEX_NUMBER_IDENT:  // number or ident which num-start
        if (lip->yyGetLast() == '0') {
          c = lip->yyGet();
          if (c == 'x') {
            while (my_isxdigit(cs, (c = lip->yyGet())))
              ;
            if ((lip->yyLength() >= 3) && !ident_map[c]) {
              /* skip '0x' */
              yylval->lex_str = get_token(lip, 2, lip->yyLength() - 2);
              return (HEX_NUM);
            }
            lip->yyUnget();
            state = MY_LEX_IDENT_START;
            break;
          } else if (c == 'b') {
            while ((c = lip->yyGet()) == '0' || c == '1')
              ;
            if ((lip->yyLength() >= 3) && !ident_map[c]) {
              /* Skip '0b' */
              yylval->lex_str = get_token(lip, 2, lip->yyLength() - 2);
              return (BIN_NUM);
            }
            lip->yyUnget();
            state = MY_LEX_IDENT_START;
            break;
          }
          lip->yyUnget();
        }

        while (my_isdigit(cs, (c = lip->yyGet())))
          ;
        if (!ident_map[c]) {  // Can't be identifier
          state = MY_LEX_INT_OR_REAL;
          break;
        }
        if (c == 'e' || c == 'E') {
          // The following test is written this way to allow numbers of type 1e1
          if (my_isdigit(cs, lip->yyPeek()) || (c = (lip->yyGet())) == '+' ||
              c == '-') {  // Allow 1E+10
            if (my_isdigit(cs,
                           lip->yyPeek()))  // Number must have digit after sign
            {
              lip->yySkip();
              while (my_isdigit(cs, lip->yyGet()))
                ;
              yylval->lex_str = get_token(lip, 0, lip->yyLength());
              return (FLOAT_NUM);
            }
          }
          lip->yyUnget();
        }
        [[fallthrough]];
      case MY_LEX_IDENT_START:  // We come here after '.'
        result_state = IDENT;
        if (use_mb(cs)) {
          result_state = IDENT_QUOTED;
          while (ident_map[c = lip->yyGet()]) {
            switch (my_mbcharlen(cs, c)) {
              case 1:
                break;
              case 0:
                if (my_mbmaxlenlen(cs) < 2) break;
                [[fallthrough]];
              default:
                int l;
                if ((l = my_ismbchar(cs, lip->get_ptr() - 1,
                                     lip->get_end_of_query())) == 0)
                  break;
                lip->skip_binary(l - 1);
            }
          }
        } else {
          for (result_state = 0; ident_map[c = lip->yyGet()]; result_state |= c)
            ;
          /* If there were non-ASCII characters, mark that we must convert */
          result_state = result_state & 0x80 ? IDENT_QUOTED : IDENT;
        }
        if (c == '.' && ident_map[lip->yyPeek()])
          lip->next_state = MY_LEX_IDENT_SEP;  // Next is '.'

        yylval->lex_str = get_token(lip, 0, lip->yyLength());

        lip->body_utf8_append(lip->m_cpp_text_start);

        lip->body_utf8_append_literal(thd, &yylval->lex_str, cs,
                                      lip->m_cpp_text_end);

        return (result_state);

      case MY_LEX_USER_VARIABLE_DELIMITER:  // Found quote char
      {
        uint double_quotes = 0;
        char quote_char = c;  // Used char
        for (;;) {
          c = lip->yyGet();
          if (c == 0) {
            lip->yyUnget();
            return ABORT_SYM;  // Unmatched quotes
          }

          int var_length;
          if ((var_length = my_mbcharlen(cs, c)) == 1) {
            if (c == quote_char) {
              if (lip->yyPeek() != quote_char) break;
              c = lip->yyGet();
              double_quotes++;
              continue;
            }
          } else if (use_mb(cs)) {
            if ((var_length = my_ismbchar(cs, lip->get_ptr() - 1,
                                          lip->get_end_of_query())))
              lip->skip_binary(var_length - 1);
          }
        }
        if (double_quotes)
          yylval->lex_str = get_quoted_token(
              lip, 1, lip->yyLength() - double_quotes - 1, quote_char);
        else
          yylval->lex_str = get_token(lip, 1, lip->yyLength() - 1);
        if (c == quote_char) lip->yySkip();  // Skip end `
        lip->next_state = MY_LEX_START;

        lip->body_utf8_append(lip->m_cpp_text_start);

        lip->body_utf8_append_literal(thd, &yylval->lex_str, cs,
                                      lip->m_cpp_text_end);

        return (IDENT_QUOTED);
      }
      case MY_LEX_INT_OR_REAL:  // Complete int or incomplete real
        if (c != '.') {         // Found complete integer number.
          yylval->lex_str = get_token(lip, 0, lip->yyLength());
          return int_token(yylval->lex_str.str, (uint)yylval->lex_str.length);
        }
        [[fallthrough]];
      case MY_LEX_REAL:  // Incomplete real number
        while (my_isdigit(cs, c = lip->yyGet()))
          ;

        if (c == 'e' || c == 'E') {
          c = lip->yyGet();
          if (c == '-' || c == '+') c = lip->yyGet();  // Skip sign
          if (!my_isdigit(cs, c)) {                    // No digit after sign
            state = MY_LEX_CHAR;
            break;
          }
          while (my_isdigit(cs, lip->yyGet()))
            ;
          yylval->lex_str = get_token(lip, 0, lip->yyLength());
          return (FLOAT_NUM);
        }
        yylval->lex_str = get_token(lip, 0, lip->yyLength());
        return (DECIMAL_NUM);

      case MY_LEX_HEX_NUMBER:  // Found x'hexstring'
        lip->yySkip();         // Accept opening '
        while (my_isxdigit(cs, (c = lip->yyGet())))
          ;
        if (c != '\'') return (ABORT_SYM);          // Illegal hex constant
        lip->yySkip();                              // Accept closing '
        length = lip->yyLength();                   // Length of hexnum+3
        if ((length % 2) == 0) return (ABORT_SYM);  // odd number of hex digits
        yylval->lex_str = get_token(lip,
                                    2,            // skip x'
                                    length - 3);  // don't count x' and last '
        return (HEX_NUM);

      case MY_LEX_BIN_NUMBER:  // Found b'bin-string'
        lip->yySkip();         // Accept opening '
        while ((c = lip->yyGet()) == '0' || c == '1')
          ;
        if (c != '\'') return (ABORT_SYM);  // Illegal hex constant
        lip->yySkip();                      // Accept closing '
        length = lip->yyLength();           // Length of bin-num + 3
        yylval->lex_str = get_token(lip,
                                    2,            // skip b'
                                    length - 3);  // don't count b' and last '
        return (BIN_NUM);

      case MY_LEX_CMP_OP:  // Incomplete comparison operator
        if (state_map[lip->yyPeek()] == MY_LEX_CMP_OP ||
            state_map[lip->yyPeek()] == MY_LEX_LONG_CMP_OP)
          lip->yySkip();
        if ((tokval = find_keyword(lip, lip->yyLength() + 1, false))) {
          lip->next_state = MY_LEX_START;  // Allow signed numbers
          return (tokval);
        }
        state = MY_LEX_CHAR;  // Something fishy found
        break;

      case MY_LEX_LONG_CMP_OP:  // Incomplete comparison operator
        if (state_map[lip->yyPeek()] == MY_LEX_CMP_OP ||
            state_map[lip->yyPeek()] == MY_LEX_LONG_CMP_OP) {
          lip->yySkip();
          if (state_map[lip->yyPeek()] == MY_LEX_CMP_OP) lip->yySkip();
        }
        if ((tokval = find_keyword(lip, lip->yyLength() + 1, false))) {
          lip->next_state = MY_LEX_START;  // Found long op
          return (tokval);
        }
        state = MY_LEX_CHAR;  // Something fishy found
        break;

      case MY_LEX_BOOL:
        if (c != lip->yyPeek()) {
          state = MY_LEX_CHAR;
          break;
        }
        lip->yySkip();
        tokval = find_keyword(lip, 2, false);  // Is a bool operator
        lip->next_state = MY_LEX_START;        // Allow signed numbers
        return (tokval);

      case MY_LEX_STRING_OR_DELIMITER:
        if (thd->variables.sql_mode & MODE_ANSI_QUOTES) {
          state = MY_LEX_USER_VARIABLE_DELIMITER;
          break;
        }
        /* " used for strings */
        [[fallthrough]];
      case MY_LEX_STRING:  // Incomplete text string
        if (!(yylval->lex_str.str = get_text(lip, 1, 1))) {
          state = MY_LEX_CHAR;  // Read char by char
          break;
        }
        yylval->lex_str.length = lip->yytoklen;

        lip->body_utf8_append(lip->m_cpp_text_start);

        lip->body_utf8_append_literal(
            thd, &yylval->lex_str,
            lip->m_underscore_cs ? lip->m_underscore_cs : cs,
            lip->m_cpp_text_end);

        lip->m_underscore_cs = nullptr;

        return (TEXT_STRING);

      case MY_LEX_COMMENT:  //  Comment
        thd->m_parser_state->add_comment();
        while ((c = lip->yyGet()) != '\n' && c)
          ;
        lip->yyUnget();        // Safety against eof
        state = MY_LEX_START;  // Try again
        break;
      case MY_LEX_LONG_COMMENT: /* Long C comment? */
        if (lip->yyPeek() != '*') {
          state = MY_LEX_CHAR;  // Probable division
          break;
        }
        thd->m_parser_state->add_comment();
        /* Reject '/' '*', since we might need to turn off the echo */
        lip->yyUnget();

        lip->save_in_comment_state();

        if (lip->yyPeekn(2) == '!') {
          lip->in_comment = DISCARD_COMMENT;
          /* Accept '/' '*' '!', but do not keep this marker. */
          lip->set_echo(false);
          lip->yySkip();
          lip->yySkip();
          lip->yySkip();

          /*
            The special comment format is very strict:
            '/' '*' '!', followed by exactly
            1 digit (major), 2 digits (minor), then 2 digits (dot).
            32302 -> 3.23.02
            50032 -> 5.0.32
            50114 -> 5.1.14
          */
          char version_str[6];
          if (my_isdigit(cs, (version_str[0] = lip->yyPeekn(0))) &&
              my_isdigit(cs, (version_str[1] = lip->yyPeekn(1))) &&
              my_isdigit(cs, (version_str[2] = lip->yyPeekn(2))) &&
              my_isdigit(cs, (version_str[3] = lip->yyPeekn(3))) &&
              my_isdigit(cs, (version_str[4] = lip->yyPeekn(4)))) {
            version_str[5] = 0;
            ulong version;
            version = strtol(version_str, nullptr, 10);

            if (version <= MYSQL_VERSION_ID) {
              /* Accept 'M' 'm' 'm' 'd' 'd' */
              lip->yySkipn(5);
              /* Expand the content of the special comment as real code */
              lip->set_echo(true);
              state = MY_LEX_START;
              break; /* Do not treat contents as a comment.  */
            } else {
              /*
                Patch and skip the conditional comment to avoid it
                being propagated infinitely (eg. to a slave).
              */
              char *pcom = lip->yyUnput(' ');
              comment_closed = !consume_comment(lip, 1);
              if (!comment_closed) {
                *pcom = '!';
              }
              /* version allowed to have one level of comment inside. */
            }
          } else {
            /* Not a version comment. */
            state = MY_LEX_START;
            lip->set_echo(true);
            break;
          }
        } else {
          if (lip->in_comment != NO_COMMENT) {
            push_warning(
                lip->m_thd, Sql_condition::SL_WARNING,
                ER_WARN_DEPRECATED_SYNTAX_NO_REPLACEMENT,
                ER_THD(lip->m_thd, ER_WARN_DEPRECATED_NESTED_COMMENT_SYNTAX));
          }
          lip->in_comment = PRESERVE_COMMENT;
          lip->yySkip();  // Accept /
          lip->yySkip();  // Accept *
          comment_closed = !consume_comment(lip, 0);
          /* regular comments can have zero comments inside. */
        }
        /*
          Discard:
          - regular '/' '*' comments,
          - special comments '/' '*' '!' for a future version,
          by scanning until we find a closing '*' '/' marker.

          Nesting regular comments isn't allowed.  The first
          '*' '/' returns the parser to the previous state.

          /#!VERSI oned containing /# regular #/ is allowed #/

                  Inside one versioned comment, another versioned comment
                  is treated as a regular discardable comment.  It gets
                  no special parsing.
        */

        /* Unbalanced comments with a missing '*' '/' are a syntax error */
        if (!comment_closed) return (ABORT_SYM);
        state = MY_LEX_START;  // Try again
        lip->restore_in_comment_state();
        break;
      case MY_LEX_END_LONG_COMMENT:
        if ((lip->in_comment != NO_COMMENT) && lip->yyPeek() == '/') {
          /* Reject '*' '/' */
          lip->yyUnget();
          /* Accept '*' '/', with the proper echo */
          lip->set_echo(lip->in_comment == PRESERVE_COMMENT);
          lip->yySkipn(2);
          /* And start recording the tokens again */
          lip->set_echo(true);

          /*
            C-style comments are replaced with a single space (as it
            is in C and C++).  If there is already a whitespace
            character at this point in the stream, the space is
            not inserted.

            See also ISO/IEC 9899:1999 §5.1.1.2
            ("Programming languages — C")
          */
          if (!my_isspace(cs, lip->yyPeek()) &&
              lip->get_cpp_ptr() != lip->get_cpp_buf() &&
              !my_isspace(cs, *(lip->get_cpp_ptr() - 1)))
            lip->cpp_inject(' ');

          lip->in_comment = NO_COMMENT;
          state = MY_LEX_START;
        } else
          state = MY_LEX_CHAR;  // Return '*'
        break;
      case MY_LEX_SET_VAR:  // Check if ':='
        if (lip->yyPeek() != '=') {
          state = MY_LEX_CHAR;  // Return ':'
          break;
        }
        lip->yySkip();
        return (SET_VAR);
      case MY_LEX_SEMICOLON:  // optional line terminator
        state = MY_LEX_CHAR;  // Return ';'
        break;
      case MY_LEX_EOL:
        if (lip->eof()) {
          lip->yyUnget();  // Reject the last '\0'
          lip->set_echo(false);
          lip->yySkip();
          lip->set_echo(true);
          /* Unbalanced comments with a missing '*' '/' are a syntax error */
          if (lip->in_comment != NO_COMMENT) return (ABORT_SYM);
          lip->next_state = MY_LEX_END;  // Mark for next loop
          return (END_OF_INPUT);
        }
        state = MY_LEX_CHAR;
        break;
      case MY_LEX_END:
        lip->next_state = MY_LEX_END;
        return (0);  // We found end of input last time

        /* Actually real shouldn't start with . but allow them anyhow */
      case MY_LEX_REAL_OR_POINT:
        if (my_isdigit(cs, lip->yyPeek()))
          state = MY_LEX_REAL;  // Real
        else {
          state = MY_LEX_IDENT_SEP;  // return '.'
          lip->yyUnget();            // Put back '.'
        }
        break;
      case MY_LEX_USER_END:  // end '@' of user@hostname
        switch (state_map[lip->yyPeek()]) {
          case MY_LEX_STRING:
          case MY_LEX_USER_VARIABLE_DELIMITER:
          case MY_LEX_STRING_OR_DELIMITER:
            break;
          case MY_LEX_USER_END:
            lip->next_state = MY_LEX_SYSTEM_VAR;
            break;
          default:
            lip->next_state = MY_LEX_HOSTNAME;
            break;
        }
        yylval->lex_str.str = const_cast<char *>(lip->get_ptr());
        yylval->lex_str.length = 1;
        return ((int)'@');
      case MY_LEX_HOSTNAME:  // end '@' of user@hostname
        for (c = lip->yyGet();
             my_isalnum(cs, c) || c == '.' || c == '_' || c == '$';
             c = lip->yyGet())
          ;
        yylval->lex_str = get_token(lip, 0, lip->yyLength());
        return (LEX_HOSTNAME);
      case MY_LEX_SYSTEM_VAR:
        yylval->lex_str.str = const_cast<char *>(lip->get_ptr());
        yylval->lex_str.length = 1;
        lip->yySkip();  // Skip '@'
        lip->next_state =
            (state_map[lip->yyPeek()] == MY_LEX_USER_VARIABLE_DELIMITER
                 ? MY_LEX_START
                 : MY_LEX_IDENT_OR_KEYWORD);
        return ((int)'@');
      case MY_LEX_IDENT_OR_KEYWORD:
        /*
          We come here when we have found two '@' in a row.
          We should now be able to handle:
          [(global | local | session) .]variable_name
        */

        for (result_state = 0; ident_map[c = lip->yyGet()]; result_state |= c)
          ;
        /* If there were non-ASCII characters, mark that we must convert */
        result_state = result_state & 0x80 ? IDENT_QUOTED : IDENT;

        if (c == '.') lip->next_state = MY_LEX_IDENT_SEP;
        length = lip->yyLength();
        if (length == 0) return (ABORT_SYM);  // Names must be nonempty.
        if ((tokval = find_keyword(lip, length, false))) {
          lip->yyUnget();   // Put back 'c'
          return (tokval);  // Was keyword
        }
        yylval->lex_str = get_token(lip, 0, length);

        lip->body_utf8_append(lip->m_cpp_text_start);

        lip->body_utf8_append_literal(thd, &yylval->lex_str, cs,
                                      lip->m_cpp_text_end);

        return (result_state);
    }
  }
}


/**
  yylex() function implementation for the main parser

  @param [out] yacc_yylval   semantic value of the token being parsed (yylval)
  @param [out] yylloc        "location" of the token being parsed (yylloc)
  @param thd                 THD

  @return                    token number

  @note
  MYSQLlex remember the following states from the following MYSQLlex():

  - MY_LEX_END			Found end of query
*/

int MYSQLlex(YYSTYPE *yacc_yylval, YYLTYPE *yylloc, THD *thd) {
  auto *yylval = reinterpret_cast<Lexer_yystype *>(yacc_yylval);
  Lex_input_stream *lip = &thd->m_parser_state->m_lip;
  int token;

  if (thd->is_error()) {
    if (thd->get_parser_da()->has_sql_condition(ER_CAPACITY_EXCEEDED))
      return ABORT_SYM;
  }

  if (lip->lookahead_token >= 0) {
    /*
      The next token was already parsed in advance,
      return it.
    */
    token = lip->lookahead_token;
    lip->lookahead_token = -1;
    *yylval = *(lip->lookahead_yylval);
    yylloc->cpp.start = lip->get_cpp_tok_start();
    yylloc->cpp.end = lip->get_cpp_ptr();
    yylloc->raw.start = lip->get_tok_start();
    yylloc->raw.end = lip->get_ptr();
    lip->lookahead_yylval = nullptr;
    lip->add_digest_token(token, yylval);
    return token;
  }

  token = lex_one_token(yylval, thd);
  yylloc->cpp.start = lip->get_cpp_tok_start();
  yylloc->raw.start = lip->get_tok_start();

  switch (token) {
    case WITH:
      /*
        Parsing 'WITH' 'ROLLUP' requires 2 look ups,
        which makes the grammar LALR(2).
        Replace by a single 'WITH_ROLLUP' token,
        to transform the grammar into a LALR(1) grammar,
        which sql_yacc.yy can process.
      */
      token = lex_one_token(yylval, thd);
      switch (token) {
        case ROLLUP_SYM:
          yylloc->cpp.end = lip->get_cpp_ptr();
          yylloc->raw.end = lip->get_ptr();
          lip->add_digest_token(WITH_ROLLUP_SYM, yylval);
          return WITH_ROLLUP_SYM;
        default:
          /*
            Save the token following 'WITH'
          */
          lip->lookahead_yylval = lip->yylval;
          lip->yylval = nullptr;
          lip->lookahead_token = token;
          yylloc->cpp.end = lip->get_cpp_ptr();
          yylloc->raw.end = lip->get_ptr();
          lip->add_digest_token(WITH, yylval);
          return WITH;
      }
      break;
  }

  yylloc->cpp.end = lip->get_cpp_ptr();
  yylloc->raw.end = lip->get_ptr();
  if (!lip->skip_digest) lip->add_digest_token(token, yylval);
  lip->skip_digest = false;
  return token;
}



const char *ER_THD(const THD *thd, int mysql_errno) {
  return thd->variables.lc_messages->errmsgs->lookup(mysql_errno);
}

class Parser_oom_handler : public Internal_error_handler {
 public:
  Parser_oom_handler() : m_has_errors(false), m_is_mem_error(false) {}
  bool handle_condition(THD *thd, uint sql_errno, const char *,
                        Sql_condition::enum_severity_level *level,
                        const char *) override {
    if (*level == Sql_condition::SL_ERROR) {
      m_has_errors = true;
      /* Out of memory error is reported only once. Return as handled */
      if (m_is_mem_error &&
          (sql_errno == EE_CAPACITY_EXCEEDED || sql_errno == EE_OUTOFMEMORY))
        return true;
      if (sql_errno == EE_CAPACITY_EXCEEDED || sql_errno == EE_OUTOFMEMORY) {
        m_is_mem_error = true;
        if (sql_errno == EE_CAPACITY_EXCEEDED)
          my_error(ER_CAPACITY_EXCEEDED, MYF(0),
                   static_cast<ulonglong>(thd->variables.parser_max_mem_size),
                   "parser_max_mem_size",
                   ER_THD(thd, ER_CAPACITY_EXCEEDED_IN_PARSER));
        else
          my_error(ER_OUT_OF_RESOURCES, MYF(ME_FATALERROR));
        return true;
      }
    }
    return false;
  }

 private:
  bool m_has_errors;
  bool m_is_mem_error;
};

void sp_parser_data::finish_parsing_sp_body(THD *thd) {
  /*
    In some cases the parser detects a syntax error and calls
    THD::cleanup_after_parse_error() method only after finishing parsing
    the whole routine. In such a situation sp_head::restore_thd_mem_root()
    will be called twice - the first time as part of normal parsing process
    and the second time by cleanup_after_parse_error().

    To avoid ruining active arena/mem_root state in this case we skip
    restoration of old arena/mem_root if this method has been already called
    for this routine.
  */
  if (!is_parsing_sp_body()) return;

  thd->free_items();
  thd->mem_root = m_saved_memroot;
  thd->set_item_list(m_saved_item_list);

  m_saved_memroot = nullptr;
  m_saved_item_list = nullptr;
}

/**
  Restore session state in case of parse error.

  This is a clean up function that is invoked after the Bison generated
  parser before returning an error from THD::sql_parser(). If your
  semantic actions manipulate with the session state (which
  is a very bad practice and should not normally be employed) and
  need a clean-up in case of error, and you can not use %destructor
  rule in the grammar file itself, this function should be used
  to implement the clean up.
*/

void cleanup_after_parse_error(THD* thd) {
  sp_head *sp = thd->lex->sphead;

  if (sp) {
    sp->m_parser_data.finish_parsing_sp_body(thd);
    //  Do not delete sp_head if is invoked in the context of sp execution.
    if (thd->sp_runtime_ctx == nullptr) {
      sp_head::destroy(sp);
      thd->lex->sphead = nullptr;
    }
  }
}

bool parse_sql_entry(THD *thd, Parser_state *parser_state,
               Object_creation_ctx *creation_ctx, vector<IR*>& ir_vec) {
  DBUG_TRACE;
  bool ret_value;
  assert(thd->m_parser_state == nullptr);
  // TODO fix to allow parsing gcol exprs after main query.
  //  assert(thd->lex->m_sql_cmd == NULL);

  /* Backup creation context. */

  Object_creation_ctx *backup_ctx = nullptr;

  if (creation_ctx) backup_ctx = creation_ctx->set_n_backup(thd);

  /* Set parser state. */

  thd->m_parser_state = parser_state;

  parser_state->m_digest_psi = nullptr;
  parser_state->m_lip.m_digest = nullptr;

  /*
    Partial parsers (GRAMMAR_SELECTOR_*) are not supposed to compute digests.
  */
  assert(!parser_state->m_lip.is_partial_parser() ||
         !parser_state->m_input.m_has_digest);

  /*
    Only consider statements that are supposed to have a digest,
    like top level queries.
  */
  if (parser_state->m_input.m_has_digest) {
    /*
      For these statements,
      see if the digest computation is required.
    */
    if (thd->m_digest != nullptr) {
      /* Start Digest */
      parser_state->m_digest_psi = MYSQL_DIGEST_START(thd->m_statement_psi);

      if (parser_state->m_input.m_compute_digest ||
          (parser_state->m_digest_psi != nullptr)) {
        /*
          If either:
          - the caller wants to compute a digest
          - the performance schema wants to compute a digest
          set the digest listener in the lexer.
        */
        parser_state->m_lip.m_digest = thd->m_digest;
        parser_state->m_lip.m_digest->m_digest_storage.m_charset_number =
            thd->charset()->number;
      }
    }
  }

  /* Parse the query. */

  /*
    Use a temporary DA while parsing. We don't know until after parsing
    whether the current command is a diagnostic statement, in which case
    we'll need to have the previous DA around to answer questions about it.
  */
  Diagnostics_area *parser_da = thd->get_parser_da();
  Diagnostics_area *da = thd->get_stmt_da();

  Parser_oom_handler poomh;
  // Note that we may be called recursively here, on INFORMATION_SCHEMA queries.

  thd->mem_root->set_max_capacity(thd->variables.parser_max_mem_size);
  thd->mem_root->set_error_for_capacity_exceeded(true);
  thd->push_internal_handler(&poomh);

  thd->push_diagnostics_area(parser_da, false);

  bool mysql_parse_status = false;

  Parse_tree_root *root = nullptr;
  IR* dummy_res;
  if (MYSQLparse(thd, &root, ir_vec, dummy_res))
  {
      cleanup_after_parse_error(thd);
      mysql_parse_status = true;
  }
  if (root != nullptr && thd->lex->make_sql_cmd(root)) {
    mysql_parse_status = true;
  }
  mysql_parse_status = false;

  thd->pop_internal_handler();
  thd->mem_root->set_max_capacity(0);
  thd->mem_root->set_error_for_capacity_exceeded(false);
  /*
    Unwind diagnostics area.

    If any issues occurred during parsing, they will become
    the sole conditions for the current statement.

    Otherwise, if we have a diagnostic statement on our hands,
    we'll preserve the previous diagnostics area here so we
    can answer questions about it.  This specifically means
    that repeatedly asking about a DA won't clear it.

    Otherwise, it's a regular command with no issues during
    parsing, so we'll just clear the DA in preparation for
    the processing of this command.
  */

  if (parser_da->current_statement_cond_count() != 0) {
    /*
      Error/warning during parsing: top DA should contain parse error(s)!  Any
      pre-existing conditions will be replaced. The exception is diagnostics
      statements, in which case we wish to keep the errors so they can be sent
      to the client.
    */
    if (thd->lex->sql_command != SQLCOM_SHOW_WARNS &&
        thd->lex->sql_command != SQLCOM_GET_DIAGNOSTICS)
      da->reset_condition_info(thd);

    /*
      We need to put any errors in the DA as well as the condition list.
    */
    if (parser_da->is_error() && !da->is_error()) {
      da->set_error_status(parser_da->mysql_errno(), parser_da->message_text(),
                           parser_da->returned_sqlstate());
    }

    da->copy_sql_conditions_from_da(thd, parser_da);

    parser_da->reset_diagnostics_area();
    parser_da->reset_condition_info(thd);

    /*
      Do not clear the condition list when starting execution as it
      now contains not the results of the previous executions, but
      a non-zero number of errors/warnings thrown during parsing!
    */
    thd->lex->keep_diagnostics = DA_KEEP_PARSE_ERROR;
  }

  thd->pop_diagnostics_area();

  /*
    Check that if THD::sql_parser() failed either thd->is_error() is set, or an
    internal error handler is set.

    The assert will not catch a situation where parsing fails without an
    error reported if an error handler exists. The problem is that the
    error handler might have intercepted the error, so thd->is_error() is
    not set. However, there is no way to be 100% sure here (the error
    handler might be for other errors than parsing one).
  */

  assert(!mysql_parse_status || (mysql_parse_status && thd->is_error()) ||
         (mysql_parse_status && thd->get_internal_handler()));

  /* Reset parser state. */

  thd->m_parser_state = nullptr;

  /* Restore creation context. */

  if (creation_ctx) creation_ctx->restore_env(thd, backup_ctx);

  /* That's it. */

  ret_value = mysql_parse_status || thd->is_fatal_error();

  if ((ret_value == 0) && (parser_state->m_digest_psi != nullptr)) {
    /*
      On parsing success, record the digest in the performance schema.
    */
    assert(thd->m_digest != nullptr);
    MYSQL_DIGEST_END(parser_state->m_digest_psi,
                     &thd->m_digest->m_digest_storage);
  }

  return ret_value;
}


bool exec_query_command_entry(string input, vector<IR*>& ir_vec) {
    THD *thd = new (std::nothrow) THD;
    thd->get_stmt_da()->reset_diagnostics_area();
    thd->get_stmt_da()->reset_statement_cond_count();

    // Might need a loop
    MYSQL_LEX_CSTRING cmd_mysql_cstring;

    // In stack, will be freed after function exits. 
    cmd_mysql_cstring.str = input.c_str();
    cmd_mysql_cstring.length = input.size();
    thd->set_query(cmd_mysql_cstring);

    Parser_state parser_state;
    parser_state.init(thd, thd->query().str, thd->query().length);

    parser_state.m_input.m_has_digest = true;

    // we produce digest if it's not explicitly turned off
    // by setting maximum digest length to zero
    if (get_max_digest_length() != 0)
        parser_state.m_input.m_compute_digest = true;

    while (!thd->killed && (parser_state.m_lip.found_semicolon != nullptr) &&
           !thd->is_error()) {
        /* in the dispatch_sql_command */
        lex_start(thd);
        mysql_reset_thd_for_next_command(thd);
        thd->m_digest = nullptr;
        thd->m_statement_psi = nullptr;
        // thd->m_parser_state = parser_state;

        bool err;
        err = parse_sql_entry(thd, &parser_state, nullptr, ir_vec);
        thd->end_statement();
    }

    thd->release_resources();
    thd->set_psi(nullptr);
    thd->lex->destroy();
    thd->end_statement();
    thd->cleanup_after_query();

    return true;
}
