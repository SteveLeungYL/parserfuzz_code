import json
import os.path
import re
import sys
from typing import List

import click
from loguru import logger

ONETAB = " " * 4
ONESPACE = " "
default_ir_type = "kUnknown"

saved_ir_type = []

class Token:
    def __init__(self, word, index):
        self.word = word
        self.index = index
        self._is_terminating_keyword = None

    @property
    def is_terminating_keyword(self):
        if self._is_terminating_keyword is not None:
            return self._is_terminating_keyword

        if "'" in self.word:
            self._is_terminating_keyword = True
            return self._is_terminating_keyword

        is_term = True
        for c in self.word:
            if c.isupper() or c == "_":
                continue
            else:
                # lower case
                is_term = False
        self._is_terminating_keyword = is_term
        return self._is_terminating_keyword

    def __str__(self) -> str:
        if self.is_terminating_keyword:
            if self.word.startswith("'") and self.word.endswith("'"):
                return self.word.strip("'")
            self.word = self.word.replace("_P", "")
            self.word = self.word.replace("_LA", "")
            return self.word

        return self.word

    def __repr__(self) -> str:
        return '{prefix}("{word}")'.format(
            prefix="Keyword" if self.is_terminating_keyword else "Token", word=self.word
        )

    def __gt__(self, other):
        other_index = -1
        if isinstance(other, Token):
            other_index = other.index

        return self.index > other_index


def snake_to_camel(word):
    return "".join(x.capitalize() or "_" for x in word.split("_"))


def camel_to_snake(word):
    return "".join(["_" + i.lower() if i.isupper() else i for i in word]).lstrip("_")


def tokenize(line: List[str]) -> List[Token]:

    words = [word for word in line if word and word != "empty" and word != "/*EMPTY*/"]

    token_sequence = []
    for idx, word in enumerate(words):
        if word == "%prec":
            # ignore everything after %prec
            break
        token_sequence.append(Token(word, idx))

    return token_sequence


def replace_special_keyword_with_token(line):
    words = [word.strip() for word in line]
    # words = [word for word in words if word]

    seq = []
    for word in words:
        word = word.strip()
        if not word:
            continue

        seq.append(word)

    return " ".join(seq)


def prefix_tabs(text, tabs_num):
    result = []
    text = text.strip()
    for line in text.splitlines():
        result.append(ONETAB * tabs_num + line)
    return "\n".join(result)


def search_next_keyword(token_sequence, start_index):
    curr_token = None
    left_keywords = []

    if start_index > len(token_sequence):
        return curr_token, left_keywords

    # found_token = False
    for idx in range(start_index, len(token_sequence)):
        curr_token = token_sequence[idx]
        if curr_token.is_terminating_keyword:
            left_keywords.append(curr_token)
        else:
            # found_token = True
            break

    return curr_token, left_keywords


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

def is_identifier(cur_token):
    if cur_token.word in ("ident", "TEXT_STRING_sys_nonewline", "TEXT_STRING_sys", "TEXT_STRING_validated", "TEXT_STRING_password",
                          "TEXT_STRING_hash", "IDENT_sys", "ident_or_text", "label_ident", "role_ident", "lvalue_ident",
                          "role_ident_or_text", "schema"):
        return True
    else:
        return False

def is_literal(cur_token):
    if cur_token.word in ("TEXT_STRING_literal", "TEXT_STRING"):
        return "kStringLiteral"
    elif cur_token.word in ("HEX_NUM"):
        return "kHexLiteral"
    elif cur_token.word in ("BIN_NUM"):
        return "kBinLiteral"
    elif cur_token.word in ("FALSE_SYM", "TRUE_SYM"):
        return "kBoolLiteral"
    elif cur_token.word in ("int64_literal", "DECIMAL_NUM", "FLOAT_NUM"):
        return "kNUMLiteral"
    else:
        return None

def translate_single_line(token_sequence, parent):
    token_sequence = tokenize(token_sequence)

    i = 0
    tmp_num = 1
    body = ""
    need_more_ir = False

    if len(token_sequence) == 0:
        # For empty rules.
        body += (
                f"""res = new IR({default_ir_type}, OP3("", "", ""));""" + "\n"
            )
        body += "ir_vec.push_back(res); \n"
    
    while i < len(token_sequence):
        left_token, left_keywords = search_next_keyword(token_sequence, i)
        logger.debug(f"Left tokens: '{left_token}', Left keywords: '{left_keywords}'")

        right_token, mid_keywords = search_next_keyword(
            token_sequence, left_token.index + 1
        )
        right_keywords = []
        if right_token:
            _, right_keywords = search_next_keyword(
                token_sequence, right_token.index + 1
            )

        left_keywords_str = " ".join(
            [str(token).upper() for token in left_keywords if str(token)]
        )
        mid_keywords_str = " ".join(
            [str(token).upper() for token in mid_keywords if str(token)]
        )
        right_keywords_str = " ".join(
            [str(token).upper() for token in right_keywords if str(token)]
        )

        if need_more_ir:

            if is_identifier(left_token):
                body += f"auto tmp{tmp_num} = new IR(kIdentifier, to_string(${left_token.index+1}), kDataFixLater, 0, kFlagUnknown);" + "\n"
                body += f"ir_vec.push_back(tmp{tmp_num});\n"
            else:
                body += f"auto tmp{tmp_num} = ${left_token.index+1};" + "\n"
            body += (
                f"""res = new IR({default_ir_type}, OP3("", "{left_keywords_str}", "{mid_keywords_str}"), res, tmp{tmp_num});"""
                + "\n"
            )
            body += "ir_vec.push_back(res); \n"
            tmp_num += 1

            if right_token and not right_token.is_terminating_keyword:
                if is_identifier(right_token):
                    body += f"auto tmp{tmp_num} = new IR(kIdentifier, to_string(${right_token.index+1}), kDataFixLater, 0, kFlagUnknown);" + "\n"
                    body += f"ir_vec.push_back(tmp{tmp_num});\n"
                else:
                    body += f"auto tmp{tmp_num} = ${right_token.index + 1};" + "\n"
                body += (
                    f"""res = new IR({default_ir_type}, OP3("", "", "{right_keywords_str}"), res, tmp{tmp_num});"""
                    + "\n"
                )
                body += "ir_vec.push_back(res); \n"
                tmp_num += 1

        elif right_token and right_token.is_terminating_keyword == False:
            if is_identifier(left_token):
                body += f"auto tmp{tmp_num} = new IR(kIdentifier, to_string(${left_token.index+1}), kDataFixLater, 0, kFlagUnknown);" + "\n"
                body += f"ir_vec.push_back(tmp{tmp_num});\n"
            else:
                body += f"auto tmp{tmp_num} = ${left_token.index+1};" + "\n"
            if is_identifier(right_token):
                body += f"auto tmp{tmp_num+1} = new IR(kIdentifier, to_string(${right_token.index+1}), kDataFixLater, 0, kFlagUnknown);" + "\n"
                body += f"ir_vec.push_back(tmp{tmp_num+1});\n"
            else:
                body += f"auto tmp{tmp_num+1} = ${right_token.index+1};" + "\n"
            body += (
                f"""res = new IR({default_ir_type}, OP3("{left_keywords_str}", "{mid_keywords_str}", "{right_keywords_str}"), tmp{tmp_num}, tmp{tmp_num+1});"""
                + "\n"
            )
            body += "ir_vec.push_back(res); \n"

            tmp_num += 2
            need_more_ir = True
        elif left_token:
            # Only single one keywords here.
            if (
                not body
                and left_token.index == len(token_sequence) - 1
                and token_sequence[left_token.index].is_terminating_keyword
            ):
                # the only one keywords is a comment
                if left_keywords_str.startswith("/*") and left_keywords_str.endswith(
                    "*/"
                ):
                    # HACK for empty grammar eg. /* EMPTY */
                    left_keywords_str = ""
                body += (
                    f"""res = new IR({default_ir_type}, OP3("{left_keywords_str}", "", ""));"""
                    + "\n"
                )
                body += "ir_vec.push_back(res); \n"
                break
            body += f"auto tmp{tmp_num} = ${left_token.index+1};" + "\n"
            body += (
                f"""res = new IR({default_ir_type}, OP3("{left_keywords_str}", "{mid_keywords_str}", ""), tmp{tmp_num});"""
                + "\n"
            )
            body += "ir_vec.push_back(res); \n"

            tmp_num += 1
            need_more_ir = True
        else:
            pass

        compare_tokens = left_keywords + mid_keywords + right_keywords
        if left_token:
            compare_tokens.append(left_token)
        if right_token:
            compare_tokens.append(right_token)

        max_index_token = max(compare_tokens)
        i = max_index_token.index + 1

    if body:
        ir_type_str = ir_type_str_rewrite(parent)
        body = f"k{ir_type_str}".join(body.rsplit(default_ir_type, 1))
        body += "$$ = res;"

    logger.debug(f"Result: \n{body}")
    return body


def find_first_alpha_index(data, start_index):
    for idx, c in enumerate(data[start_index:]):
        if (
            c.isalpha()
            or c == "'"
            or c == "{"
            or c == "/"
            and data[start_index + idx + 1] == "*"
        ):
            return start_index + idx


def remove_original_actions(data):
    left_bracket_stack = []
    # data = remove_comments_if_necessary(data, True)

    clean_data = data
    for idx, ch in enumerate(data):
        if ch == "{" and not (data[idx - 1] == "'" and data[idx + 1] == "'"):
            left_bracket_stack.append(idx)
        elif ch == "}" and not (data[idx - 1] == "'" and data[idx + 1] == "'"):
            left_index = left_bracket_stack.pop()
            right_index = idx + 1
            length = right_index - left_index
            clean_data = (
                clean_data[:left_index] + " " * length + clean_data[right_index:]
            )

            # if not left_bracket_stack:
            #     # keep the outer most bracket for middle action
            #     left_data = clean_data[:left_index]
            #     right_data = clean_data[right_index + 1 :]
            #     is_middle_action = (
            #         right_data.strip()
            #         and right_data.strip()[0]
            #         not in [
            #             ";",
            #             "|",
            #         ]
            #         and not right_data.strip().startswith("/*")
            #         and len(right_data.strip()) > 0
            #     )
            #
            #     if is_middle_action:
            #         clean_data = left_data + "{}" + right_data

    # clean_data = re.sub(r"\{.*?\}", "", data, flags=re.S)
    clean_data = remove_single_line_comment(clean_data)
    return clean_data


def translate_preprocessing(data):
    """Remove comments, and remove the original actions from the parser"""

    data = data.replace("/* EMPTY */", "/*EMPTY*/")
    data = data.replace("/* empty */", "/*EMPTY*/")
    """Remove original actions here. """
    all_new_data = remove_original_actions(data)

    # all_new_data = ""  # not necessary. But it works now, no need to change. :-o
    # new_data = ""
    # cur_data = ""
    # all_lines = data.split("\n")
    # idx = -1
    # for cur_line in all_lines:
    #     idx += 1
    #     if ":" in cur_line and cur_data != "":
    #         new_data += cur_data + "\n"
    #         cur_data = " " + cur_line
    #         all_new_data += new_data
    #         new_data = ""
    #     elif "|" in cur_line:
    #         new_data += cur_data + "\n"
    #         cur_data = " " + cur_line
    #     elif cur_line == all_lines[-1]:
    #         cur_data += " " + cur_line
    #         new_data += cur_data + "\n"
    #         all_new_data += new_data
    #         new_data = ""
    #     else:
    #         cur_data += " " + cur_line

    # """Remove all semicolon in the statement? """
    # all_new_data_l = list(all_new_data)
    # semi_loc = all_new_data.rfind(";", 1)
    # if semi_loc != -1:
    #     all_new_data_l[semi_loc] = "\n"
    # all_new_data = "".join(all_new_data_l)

    # all_new_data += ";"
    #
    # with open("draft.txt", "a") as f:
    #     f.write('----------------\n')
    #     f.write(all_new_data)

    """Join comments from multiple lines into one line."""
    all_new_data = join_comments_into_oneline(all_new_data)

    return all_new_data


def remove_comments_inside_statement(text):
    text = text.strip()
    if not (text.startswith("/*") and text.endswith("*/") and text.count("/*") == 1):
        text = remove_comments_if_necessary(text, True)
    return text


def translate(parent_element: str, child_rules: [str]):

    if len(child_rules) == 0:
        logger.error(f"Error: Found empty rule from {parent_element}")
        exit(1)

    first_child_body = translate_single_line(child_rules[0], parent_element)

    mapped_first_child_element = replace_special_keyword_with_token(child_rules[0])
    logger.debug(f"First child element: '{mapped_first_child_element}'")
    translation = f"""
{parent_element}:

{ONETAB}{mapped_first_child_element}{ONESPACE}{{
{prefix_tabs(first_child_body, 2)}
{ONETAB}}}
"""

    for child_element in child_rules[1:]:
        child_body = translate_single_line(child_element, parent_element)

        mapped_child_element = replace_special_keyword_with_token(child_element)
        logger.debug(f"Child element => '{mapped_child_element}'")
        translation += f"""
{ONETAB}|{ONESPACE}{mapped_child_element}{ONESPACE}{{
{prefix_tabs(child_body, 2)}
{ONETAB}}}
"""

    translation += "\n;\n"

    # fix the IR type to kUnknown
    with open("all_ir_types.txt", "a") as f:
        ir_type_str = ir_type_str_rewrite(parent_element)

        if ir_type_str not in saved_ir_type:
            saved_ir_type.append(ir_type_str)
            f.write(f"V(k{ir_type_str})   \\\n")

        default_ir_type_num = translation.count(default_ir_type)
        for idx in range(default_ir_type_num):
            translation = translation.replace(
                default_ir_type, f"k{ir_type_str}_{idx+1}", 1
            )
            # body = body.replace(default_ir_type, f"k{ir_type_str}", 1)
            if f"{ir_type_str}_{idx+1}" not in saved_ir_type:
                saved_ir_type.append(f"{ir_type_str}_{idx+1}")
                f.write(f"V(k{ir_type_str}_{idx+1})   \\\n")

    logger.info(translation)
    return translation


def get_gram_keywords():
    global total_tokens

    tokens_file = "assets/keywords.y"
    with open(tokens_file) as f:
        token_data = f.read()

    token_data = remove_comments_if_necessary(token_data, True)

    token_data = token_data.splitlines()
    token_data = [line.strip() for line in token_data]
    token_data = [line for line in token_data if line]

    gram_tokens = set()
    for line in token_data:
        line = line.replace("\t", " ")
        line = line.replace(";", "")
        if line.endswith(">"):
            continue

        if line.startswith("%type"):
            line = line.split(" ", 2)[-1:]
            line = " ".join(line)

        line = line.strip()
        gram_tokens |= set(line.split())

    for token in gram_tokens:
        if token.startswith("<"):
            logger.info(token)

    unwanted = [
        "",
        " ",
        "IDENT",
        "IDENT_QUOTED",
        "TEXT_STRING",
        "DECIMAL_NUM",
        "FLOAT_NUM",
        "NUM",
        "LONG_NUM",
        "HEX_NUM",
        "LEX_HOSTNAME",
        "ULONGLONG_NUM",
    ]
    for elem in unwanted:
        if elem in gram_tokens:
            gram_tokens.remove(elem)


def get_gram_tokens():
    global total_keywords

    keywords_file = "assets/tokens.y"
    with open(keywords_file) as f:
        keyword_data = f.read()

    keyword_data = remove_comments_if_necessary(keyword_data, True)

    keyword_data = keyword_data.splitlines()
    keyword_data = [line.strip() for line in keyword_data if line.strip()]
    keyword_data = [
        line
        for line in keyword_data
        if not (line.startswith("*") or line.startswith("/"))
    ]

    gram_keywords = set()
    for line in keyword_data:
        line = line.replace("\t", " ")

        if line.startswith("%token") and " <" in line and "> " in line:
            line = line.split(" ", 2)[-1]
        elif line.startswith("%"):
            line = line.split(" ", 1)[-1]

        line = line.strip()
        words = [word for word in line.split() if not word.isdigit()]
        gram_keywords |= set(words)

    unwanted = ["", " "]
    for elem in unwanted:
        if elem in gram_keywords:
            gram_keywords.remove(elem)

    total_keywords |= gram_keywords
    with open("assets/keywords.json", "w") as f:
        json.dump(list(total_keywords), f, indent=2, sort_keys=True)


def join_comments_into_oneline(text):
    clean_text = text

    index = 0
    inside_comment = False
    while index < len(text) - 1:
        lch = text[index]
        rch = text[index + 1]
        if lch == "/" and rch == "*":
            inside_comment = True
        elif lch == "*" and rch == "/":
            inside_comment = False

        if lch == "\n" and inside_comment:
            clean_text = clean_text[:index] + " " + clean_text[index + 1 :]

        index += 1

    return clean_text.strip()


def remove_comments_if_necessary(text, need_remove):
    if not need_remove:
        return text

    left_comment_mark = []
    clean_text = text

    index = 0
    """Remove multiple lines comments."""
    while index < len(text) - 1:
        lch = text[index]
        rch = text[index + 1]
        if lch == "/" and rch == "*":
            left_comment_mark.append(index)
        elif lch == "*" and rch == "/":
            left_index = left_comment_mark.pop()
            right_index = index + 1 + 1
            length = right_index - left_index

            clean_text = (
                clean_text[:left_index] + " " * length + clean_text[right_index:]
            )

        index += 1

    """Remove single line comment"""
    clean_text = remove_single_line_comment(clean_text)
    return clean_text
    # pattern = r"/\*.*?\*/"
    # return re.sub(pattern, "", text, flags=re.S)


def remove_single_line_comment(text):
    clean_text = text
    while "//" in clean_text:
        start_index = clean_text.find("//")
        end_index = clean_text.find("\n", start_index + 1)
        clean_text = clean_text[:start_index] + "\n" + clean_text[end_index:]

    return clean_text.strip()


def select_translate_region(data):
    pattern = "%%"
    start_pos = data.find(pattern) + len(pattern)
    stop_pos = data.find(pattern, start_pos)
    return data[start_pos:stop_pos]


def mark_statement_location(data):
    data = translate_preprocessing(data)

    marked_str = ""
    extract_tokens = dict()
    cur_parent = ""
    cur_token_seq = []
    for cur_line in data.splitlines():

        # Remove comments.
        if cur_line.strip().startswith("#") or cur_line.strip().startswith("/*") or cur_line.strip().startswith(" *"):
            continue

        if "%prec" in cur_line:
            cur_line = cur_line.split("%prec")[0]

        cur_line = cur_line.strip()
        if len(cur_line) == 0:
            continue

        token_seq = [x for x in cur_line.split() if x != "%%" and x != ";" and x != "{}"]

        if len(token_seq) == 0:
            continue
        if token_seq[0].endswith(":"):
            if cur_parent != "" and cur_parent not in extract_tokens.keys():
                extract_tokens[cur_parent] = [cur_token_seq]
            elif cur_parent != "":
                extract_tokens[cur_parent].append(cur_token_seq)

            cur_token_seq = []
            cur_parent = token_seq[0][:-1]
            token_seq = token_seq[1:]

            marked_str += f"=== {cur_parent.strip()} ===\n"

        elif token_seq[0].endswith("|"):
            if cur_parent not in extract_tokens.keys():
                extract_tokens[cur_parent] = [cur_token_seq]
            else:
                extract_tokens[cur_parent].append(cur_token_seq)

            cur_token_seq = []
            token_seq = token_seq[1:]

        cur_token_seq.extend(token_seq)

    if cur_parent not in extract_tokens.keys():
        extract_tokens[cur_parent] = [cur_token_seq]
    else:
        extract_tokens[cur_parent].append(cur_token_seq)


    return marked_str, extract_tokens

@click.command()
@click.option("-o", "--output", default="grammar_modi.y")
@click.option("--remove-comments", is_flag=True, default=False)
def run(output, remove_comments):
    # Remove all_ir_type.txt, if exist
    if os.path.exists("./all_ir_types.txt"):
        os.remove("./all_ir_types.txt")

    data = open("assets/grammar_rule_only.y").read()

    data = remove_comments_if_necessary(data, remove_comments)
    # data = select_translate_region(data)

    marked_lines, extract_tokens = mark_statement_location(data)

    logger.debug(marked_lines)
    for idx, kind in extract_tokens.items():
        logger.debug(idx)
        for cur_kind in kind:
            logger.debug(cur_kind)
        logger.debug("")

    for parent_element, extract_token in extract_tokens.items():
        translation = translate(parent_element, extract_token)

        marked_lines = marked_lines.replace(
            f"=== {parent_element.strip()} ===", translation, 1
        )

    with open(output, "w") as f:
        f.write("/*\n")
        f.write(marked_lines)

if __name__ == "__main__":
    get_gram_keywords()
    run()
