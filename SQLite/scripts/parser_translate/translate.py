import sys
import os.path
import json
from loguru import logger
from typing import List
import re


ONETAB = " " * 4
ONESPACE = " "
default_ir_type = "kUnknown"

saved_ir_type = []

logger.remove()
logger.add(sys.stderr, level="DEBUG") # or sys.stdout or other file object

all_translated_types = []

class Token(object):
    def __init__(self, value, index):
        self.value = value 
        self.index = index

    @property
    def is_term_token(self):
        if self.value.startswith("'") or self.value.endswith("'"):
            return True
        if self.value[0].isupper():
            return True

        return False

    def __str__(self) -> str:
        if self.is_term_token:
            if self.value.startswith("'") and self.value.endswith("'"):
                return self.value.strip("'")

        return self.value

    def __repr__(self) -> str:
        return '{prefix}("{word}")'.format(
            prefix="Keyword" if self.is_term_token else "Token", word=self.value
        )

    def __gt__(self, other):
        other_index = -1
        if isinstance(other, Token):
            other_index = other.index

        return self.index > other_index


def snake_to_camel(word: str):
    return "".join(x.capitalize() or "_" for x in word.split("_"))


def camel_to_snake(word: str):
    return "".join(["_" + i.lower() if i.isupper() else i for i in word]).lstrip("_")

def is_terminating_keyword(word: str) -> bool:
    if word == "id" or word == "ids" or word == "number":
        return True
    if word[0].isupper():
        return True
    else:
        return False

def search_next_keyword(token_seq, start_index):
    curr_token = None
    term_keywords = []

    if start_index >= len(token_seq):
        return curr_token, term_keywords

    for idx in range(start_index, len(token_seq)):
        if is_terminating_keyword(token_seq[idx]):
            curr_term_keyword = Token(token_seq[idx], idx)
            term_keywords.append(curr_term_keyword)
        else:
            curr_token = Token(token_seq[idx], idx)
            break

    return curr_token, term_keywords


def ir_type_str_rewrite(cur_types) -> str:
    if cur_types == "":
        return "Unknown"

    cur_types_l = list(cur_types)
    cur_types_l[0] = cur_types_l[0].upper()

    is_upper = False
    for cur_char_idx in range(len(cur_types_l)):
        if cur_types_l[cur_char_idx] == "_":
            is_upper = True
            cur_types_l[cur_char_idx] = ""
            continue
        if is_upper == True:
            is_upper = False
            cur_types_l[cur_char_idx] = cur_types_l[cur_char_idx].upper()

    cur_types = "".join(cur_types_l)
    return cur_types

def translate_single_rule(token_seq, parent):
    
    all_saved_str = parent  + "(A) ::= "

    tmp_idx = 0
    for cur_token in token_seq:
        all_saved_str += cur_token + "(" + chr(ord('B') + tmp_idx) + ") "
        tmp_idx += 1

    return all_saved_str

def translate_single_action(token_seq, parent):

    i = 0
    tmp_num = 1
    body = ""
    need_more_ir = False

    if len(token_seq) == 0:
        logger.debug("Getting empty rule.")
        body += (
            f"""A = new IR({default_ir_type}, OP0());"""
            + "\n"
        )


    while i < len(token_seq):
        left_token, left_keywords = search_next_keyword(token_seq, i)
        logger.debug(f"Left tokens: '{left_token}', Left keywords: '{left_keywords}'")

        right_token = None
        mid_keywords = []
        if left_token is not None:
            right_token, mid_keywords = search_next_keyword(
                token_seq, left_token.index+1
            )
        right_keywords = []
        if right_token:
            _, right_keywords = search_next_keyword(
                token_seq, right_token.index + 1
            )

        left_keywords_str = " + ".join(
            ["string(" + chr(ord('B') + token.index) + ")" for token in left_keywords]
        )
        mid_keywords_str = " + ".join(
            ["string(" + chr(ord('B') + token.index) + ")" for token in mid_keywords]
        )
        right_keywords_str = " + ".join(
            ["string(" + chr(ord('B') + token.index) + ")" for token in right_keywords]
        )

        if len(left_keywords_str) == 0:
            left_keywords_str = "\"\""
        if len(mid_keywords_str) == 0:
            mid_keywords_str = "\"\""
        if len(right_keywords_str) == 0:
            right_keywords_str = "\"\""

        if need_more_ir:
            # Second or more loop
            # left node has been pre-defined as res.

            tmp_var = chr(ord('B') + left_token.index)
            body += (
                f"""A = new IR({default_ir_type}, OP3("", {left_keywords_str}, {mid_keywords_str}), (IR*)A, (IR*){tmp_var});"""
                + "\n"
            )
            tmp_num += 1

            if right_token is not None:
                tmp_var = chr(ord('B') + right_token.index)
                body += (
                    f"""A = new IR({default_ir_type}, OP3("", "", {right_keywords_str}), (IR*)A, (IR*){tmp_var});"""
                    + "\n"
                )
                tmp_num += 1

        elif right_token is not None:
            tmp_var = chr(ord('B') + left_token.index)
            tmp_var_2 = chr(ord('B') + right_token.index)
            body += (
                f"""A = new IR({default_ir_type}, OP3({left_keywords_str}, {mid_keywords_str}, {right_keywords_str}), (IR*){tmp_var}, (IR*){tmp_var_2});"""
                + "\n"
            )

            tmp_num += 2
            need_more_ir = True

        elif left_token is not None and (
                    left_token.index == len(token_seq) - 1 or
                    len(mid_keywords) > 0 and
                    mid_keywords[-1].index == len(token_seq) - 1
                ):
            # only single one token.
            logger.debug("Getting only single one non-term token. ")
            tmp_var = chr(ord('B') + left_token.index)
            body += (
                f"""A = new IR({default_ir_type}, OP3({left_keywords_str}, {mid_keywords_str}, ""), (IR*){tmp_var});"""
                + "\n"
            )

            tmp_num += 1
            need_more_ir = True
            break

        # Only zero or more keywords here.
        else:
            logger.debug("Getting Zero or more keywords only.")
            body += (
                f"""A = new IR({default_ir_type}, OP3({left_keywords_str}, "", ""));"""
                + "\n"
            )
            break

        compare_tokens = left_keywords + mid_keywords + right_keywords
        if left_token is not None:
            compare_tokens.append(left_token)
        if right_token is not None:
            compare_tokens.append(right_token)

        max_index_token = max(compare_tokens)
        i = max_index_token.index + 1

    if body:
        ir_type_str = ir_type_str_rewrite(parent)
        body = f"k{ir_type_str}".join(body.rsplit(default_ir_type, 1))
        body += "*root_ir = (IR*)(A);\n"
        if f"k{ir_type_str}" not in all_translated_types:
            all_translated_types.append(f"k{ir_type_str}")


    logger.debug(f"Result: \n{body}")
    return body

def get_predef_text() ->str:
    return """
// All token codes are small integers with #defines that begin with "TK_"
%token_prefix TKIR_

// The type of the data attached to each token is Token.  This is also the
// default type for non-terminals.
//
%token_type {const char*}
%default_type {IR*}

// An extra argument to the parse function for the parser, which is available
// to all actions.
%extra_argument {IR** root_ir}

// The name of the generated procedure that implements the parser
// is as follows:
%name IRParser

// input is the start symbol
%start_symbol input

// The following text is included near the beginning of the C source
// code file that implements the parser.
//
%include {

    #include "../include/ast.h"
    #include "../include/define.h"

}

"""


def handle_ori_comp_parser() -> str:
    # gather all the token information first. 

    file_fd = open("./assets/sqlite_ori_parse.y")

    all_lines = file_fd.readlines()
    all_saved_lines = ""

    is_fallback_multiline = False
    is_def_ignore = False
    rule_is_read = False
    macro_is_read = True 

    for cur_line in all_lines:

        # ignore the #ifdef line and all the contents between
        if cur_line.startswith("%ifdef "):
            is_def_ignore = True
            continue
        if "%endif" in cur_line:
            if is_def_ignore == True:
                is_def_ignore = False
            macro_is_read = True
            continue
        if is_def_ignore == True:
            continue

        # ignore all the `#ifndef` line, but still save all the things between.
        if cur_line.startswith("%ifndef ")  or \
                cur_line.startswith("%endif"):
                    continue

        # For the fallback grammar
        if cur_line.startswith("%fallback "):
            all_saved_lines += cur_line
            is_fallback_multiline = True
            continue
        if cur_line.startswith("%token ") or cur_line.startswith("%token\n"):
            all_saved_lines += cur_line
            if "." not in cur_line:
                is_fallback_multiline = True
            continue
        if is_fallback_multiline and "." in cur_line:
            all_saved_lines += cur_line
            is_fallback_multiline = False
            continue
        if is_fallback_multiline == True:
            all_saved_lines += cur_line
            continue


        # All other saved types.
        if cur_line.startswith("%left ") or \
                cur_line.startswith("%right ") or \
                cur_line.startswith("%nonassoc ") or \
                cur_line.startswith("%wildcard ") or \
                cur_line.startswith("%token_class "):
            # the line contains the new line symbol
            all_saved_lines += cur_line
            continue

        if cur_line.startswith("%type "):
            # Change all the non-terminal types to IR*.
            cur_line = cur_line.split("{")[0]
            cur_line += "{IR*}\n"
            all_saved_lines += cur_line
            continue


        if macro_is_read == False:
            continue

        if "%else" in cur_line:
            macro_is_read = False
            continue
        
        if rule_is_read == True and "." in cur_line:
            cur_line = cur_line.split("{")[0]
            cur_line = re.sub("\n", "", cur_line)
            # remove all the bracket and the contents within.
            cur_line = re.sub("[\(].*?[\)]", "", cur_line)
            all_saved_lines += cur_line+"\n"
            rule_is_read = False
            continue

        if rule_is_read == True and "." not in cur_line:
            cur_line = re.sub("[\(].*?[\)]", "", cur_line)
            cur_line = re.sub("\n", "", cur_line)
            all_saved_lines+=cur_line
            continue

        if "::=" in cur_line and "." not in cur_line:
            cur_line = re.sub("[\(].*?[\)]", "", cur_line)
            cur_line = re.sub("\n", "", cur_line)
            all_saved_lines+=cur_line
            rule_is_read = True
            continue

        if "::=" in cur_line and "." in cur_line:
            cur_line = cur_line.split("{")[0]
            cur_line = re.sub("\n", "", cur_line)
            # remove all the bracket and the contents within.
            cur_line = re.sub("[\(].*?[\)]", "", cur_line)
            all_saved_lines+=cur_line+"\n"
            continue

    logger.debug("\n\n\nGetting all_saved_lines for token declaration : %s\n\n\n"%(all_saved_lines))

    file_fd.close()
    
    return all_saved_lines

def get_rules_text(all_saved_str: str) -> str:
    # gather all the token information first. 

    all_lines = all_saved_str.splitlines()
    all_saved_lines = ""

    for cur_line in all_lines:
        if cur_line.startswith("// "):
            continue

        if "::=" not in cur_line:
            all_saved_lines += cur_line + "\n"
            continue

        ori_line = cur_line
        # Remove the "\n" at the end.
        cur_line = cur_line[:-1]

        # Remove the . sign
        cur_line_split = cur_line.split(".")
        cur_line = cur_line_split[0]
        cur_line_after_dot = ""
        if len(cur_line_split) > 1:
            cur_line_after_dot = cur_line_split[1]

        token_list = cur_line.split()

        cur_keyword = token_list[0]

        if len(token_list) > 2:
            token_list = token_list[2:]
        else:
            token_list = []

        logger.debug(f"Translating single rule: {cur_keyword}")
        all_saved_lines += translate_single_rule(token_list, cur_keyword)
        all_saved_lines += ". " + cur_line_after_dot + "{\n"
        all_saved_lines += translate_single_action(token_list, cur_keyword)
        all_saved_lines += "}\n\n"

    return all_saved_lines


def run(output_fd, all_ir_type_fd):

    predef_str = get_predef_text()
    token_str = handle_ori_comp_parser()

    rules_str = get_rules_text(token_str)

    output_fd.write(predef_str)
    # output_fd.write(token_str)
    output_fd.write(rules_str)

    all_ir_type_fd.write("\n".join(all_translated_types))

    return

if __name__ == "__main__":

    output_file_str = "sqlite_lemon_parser.y"
    all_ir_type_str = "sqlite_type_str.txt"
    if len(sys.argv) == 2:
        output_file_str = sys.argv[1] 
    elif len(sys.argv) > 2:
        os.error("Usage: python3 translate.py lemon_output_file.y")

    if os.path.exists(output_file_str):
        os.remove(output_file_str)

    if not os.path.exists("./assets"):
        os.error("Error: The assets folder does not exists in the current working \
                directory: %s. \n", os.getcwd())
    if not os.path.isfile("./assets/sqlite_ori_parse.y") or \
            not os.path.isfile("./assets/sqlite_parser_rules.json") or \
            not os.path.isfile("./assets/sqlite_parse_rule_only.y"):
        os.error("Error: The assets folder is not complete. \n")

    with open(output_file_str, "w+") as fd, open(all_ir_type_str, "w+") as fd2:
        run(fd, fd2)
