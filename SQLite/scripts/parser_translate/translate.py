import sys
import os.path
import json
from loguru import logger
from typing import List


ONETAB = " " * 4
ONESPACE = " "
default_ir_type = "TypeUnknown"

saved_ir_type = []

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
    if word[0].isupper():
        return True
    else:
        return False

def search_next_keyword(token_seq, start_index):
    curr_token = None
    term_keywords = []
    token_idx = start_index
    term_token_idx = start_index

    if start_index >= len(token_seq):
        return curr_token, term_keywords, len(token_seq), len(token_seq)

    for idx in range(start_index, len(token_seq)):
        if is_terminating_keyword(token_seq[idx]):
            term_keywords.append(curr_token)
            token_idx = idx + 1
            term_token_idx = idx + 1
        else:
            curr_token = token_seq[idx]
            token_idx = idx + 1
            break

    return curr_token, term_keywords, token_idx, term_token_idx


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



# def translate(data):

    # data = translate_preprocessing(data=data)
    # data = data.strip() + "\n"

    # parent_element = data[: data.find(":")]
    # logger.debug(f"Parent element: '{parent_element}'")

    # first_alpha_after_colon = find_first_alpha_index(data, data.find(":"))
    # first_child_element = data[
        # first_alpha_after_colon : data.find("\n", first_alpha_after_colon)
    # ]
    # first_child_element = remove_comments_inside_statement(first_child_element)
    # first_child_body = translate_single_line(first_child_element, parent_element)

    # mapped_first_child_element = repace_special_keyword_with_token(first_child_element)
    # logger.debug(f"First child element: '{mapped_first_child_element}'")
    # translation = f"""
# {parent_element}:

# {ONETAB}{mapped_first_child_element}{ONESPACE}{{
# {prefix_tabs(first_child_body, 2)}
# {ONETAB}}}
# """

    # rest_children_elements = [line.strip() for line in data.splitlines() if "|" in line]
    # rest_children_elements = [
        # line[1:].strip() for line in rest_children_elements if line.startswith("|")
    # ]
    # for child_element in rest_children_elements:
        # child_element = remove_comments_inside_statement(child_element)
        # child_body = translate_single_line(child_element, parent_element)

        # mapped_child_element = repace_special_keyword_with_token(child_element)
        # logger.debug(f"Child element => '{mapped_child_element}'")
        # translation += f"""
# {ONETAB}|{ONESPACE}{mapped_child_element}{ONESPACE}{{
# {prefix_tabs(child_body, 2)}
# {ONETAB}}}
# """

    # translation += "\n;"

    # # fix the IR type to kUnknown
    # with open("all_ir_types.txt", "a") as f:
        # ir_type_str = ir_type_str_rewrite(parent_element)

        # if ir_type_str not in saved_ir_type:
            # saved_ir_type.append(ir_type_str)
            # f.write(f"V(k{ir_type_str})   \\\n")

        # default_ir_type_num = translation.count(default_ir_type)
        # for idx in range(default_ir_type_num):
            # translation = translation.replace(
                # default_ir_type, f"k{ir_type_str}_{idx+1}", 1
            # )
            # # body = body.replace(default_ir_type, f"k{ir_type_str}", 1)
            # if f"{ir_type_str}_{idx+1}" not in saved_ir_type:
                # saved_ir_type.append(f"{ir_type_str}_{idx+1}")
                # f.write(f"V(k{ir_type_str}_{idx+1})   \\\n")

    # logger.info(translation)
    # return translation

def translate_single_rule(token_seq, parent):

    i = 0
    tmp_num = 1
    body = ""
    need_more_ir = False
    while i < len(token_seq):
        left_token, left_keywords, i, _ = search_next_keyword(token_seq, i)
        logger.debug(f"Left tokens: '{left_token}', Left keywords: '{left_keywords}'")

        right_token, mid_keywords, i, _ = search_next_keyword(
            token_seq, i
        )
        right_keywords = []
        if right_token:
            _, right_keywords, _, i = search_next_keyword(
                token_seq, right_token.index + 1
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

            # body += "PUSH(res);"
            body += f"auto tmp{tmp_num} = ${left_token.index+1};" + "\n"
            body += (
                f"""res = new IR({default_ir_type}, OP3("", "{left_keywords_str}", "{mid_keywords_str}"), res, tmp{tmp_num});"""
                + "\n"
            )
            tmp_num += 1

            if right_token and not right_token.is_keyword:
                # body += "PUSH(res);"
                body += f"auto tmp{tmp_num} = ${right_token.index + 1};" + "\n"
                body += (
                    f"""res = new IR({default_ir_type}, OP3("", "", "{right_keywords_str}"), res, tmp{tmp_num});"""
                    + "\n"
                )
                tmp_num += 1

        elif right_token and right_token.is_keyword == False:
            body += f"auto tmp{tmp_num} = ${left_token.index+1};" + "\n"
            body += f"auto tmp{tmp_num+1} = ${right_token.index+1};" + "\n"
            body += (
                f"""res = new IR({default_ir_type}, OP3("{left_keywords_str}", "{mid_keywords_str}", "{right_keywords_str}"), tmp{tmp_num}, tmp{tmp_num+1});"""
                + "\n"
            )

            tmp_num += 2
            need_more_ir = True
        elif left_token:
            # Only single one keywords here.
            if (
                not body
                and left_token.index == len(token_sequence) - 1
                and token_sequence[left_token.index].word in total_keywords
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
                break
            body += f"auto tmp{tmp_num} = ${left_token.index+1};" + "\n"
            body += (
                f"""res = new IR({default_ir_type}, OP3("{left_keywords_str}", "{mid_keywords_str}", ""), tmp{tmp_num});"""
                + "\n"
            )

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

def get_predef_text() ->str:
    return """
// All token codes are small integers with #defines that begin with "TK_"
%token_prefix TKIR_

// The type of the data attached to each token is Token.  This is also the
// default type for non-terminals.
//
%token_type {Token}
%default_type {Token}

// An extra argument to the constructor for the parser, which is available
// to all actions.
%extra_context {IR* ir}

// The name of the generated procedure that implements the parser
// is as follows:
%name IRParser

// The following text is included near the beginning of the C source
// code file that implements the parser.
//
%include {

    struct IR;

}

    """


def handle_ori_comp_parser() -> str:
    # gather all the token information first. 

    file_fd = open("./assets/sqlite_ori_parse.y")

    all_lines = file_fd.readlines()
    all_saved_lines = ""

    is_fallback_multiline = False
    is_def_ignore = False

    for cur_line in all_lines:

        # ignore the #ifdef line and all the contents between
        if cur_line.startswith("%ifdef "):
            is_def_ignore = True
            continue
        if is_def_ignore == True and cur_line.startswith("%endif"):
            is_def_ignore = False
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
        if is_fallback_multiline and "." in cur_line:
            all_saved_lines += cur_line
            is_fallback_multiline = False
            continue
        if is_fallback_multiline == True:
            all_saved_lines += cur_line
            continue

        # All other saved types.
        if cur_line.startswith("%token ") or \
                cur_line.startswith("%left ") or \
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

    logger.debug("\n\n\nGetting all_saved_lines for token declaration : %s\n\n\n"%(all_saved_lines))
    
    return ""

def get_rules_text() -> str:
    # gather all the token information first. 

    file_fd = open("./assets/sqlite_parse_rule_only.y")

    all_lines = file_fd.readlines()
    all_saved_lines = ""

    for cur_line in all_lines:
        if cur_line.startswith("// "):
            continue

        ori_line = cur_line
        # Remove the "." and the "\n" at the end.
        cur_line = cur_line[:-2]

        token_list = cur_line.split()

        cur_keyword = token_list[0]

        if len(token_list) > 2:
            token_list = token_list[2:]
        else:
            token_list = []

    # print(all_saved_lines)

    return ""


def run(output_fd):

    predef_str = get_predef_text()
    token_str = handle_ori_comp_parser()

    rules_str = get_rules_text()


    # marked_lines, extract_tokens = mark_statement_location(data)
    # for token_name, extract_token in extract_tokens.items():
        # if token_name in manually_translation:
            # translation = manually_translation[token_name]
        # else:
            # translation = translate(extract_token)

        # marked_lines = marked_lines.replace(
            # f"=== {token_name.strip()} ===", translation, 1
        # )

    # if os.path.exists(output):
        # backup = os.path.abspath(output + ".bak")
        # os.system("cp {} {}".format(os.path.abspath(output), backup))
        # logger.info(f"Backup the original bison_parser.y to {backup}")

        # with open(backup, "r") as f:
            # original_contents = f.read()

        # with open(output, "w") as f:
            # start_pos = original_contents.find("%%") + len("%%")
            # stop_pos = original_contents.find("%%", start_pos + 1)

            # f.write(original_contents[:start_pos])
            # f.write(marked_lines)
            # f.write(original_contents[stop_pos:])
    # else:
        # with open(output, "w") as f:
            # f.write(marked_lines)


if __name__ == "__main__":

    output_file_str = "sqlite_lemon_parser.y"
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

    with open(output_file_str, "w+") as fd:
        run(fd)
