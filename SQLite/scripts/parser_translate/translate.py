import os.path
import json
import click
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

def search_next_keyword(token_sequence, start_index):
    curr_token = None
    left_keywords = []

    if start_index > len(token_sequence):
        return curr_token, left_keywords

    # found_token = False
    for idx in range(start_index, len(token_sequence)):
        curr_token = token_sequence[idx]
        if curr_token.is_keyword:
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


def translate_single_line(line, parent):
    token_sequence = tokenize(line)

    i = 0
    tmp_num = 1
    body = ""
    need_more_ir = False
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


def translate(data):

    data = translate_preprocessing(data=data)
    data = data.strip() + "\n"

    parent_element = data[: data.find(":")]
    logger.debug(f"Parent element: '{parent_element}'")

    first_alpha_after_colon = find_first_alpha_index(data, data.find(":"))
    first_child_element = data[
        first_alpha_after_colon : data.find("\n", first_alpha_after_colon)
    ]
    first_child_element = remove_comments_inside_statement(first_child_element)
    first_child_body = translate_single_line(first_child_element, parent_element)

    mapped_first_child_element = repace_special_keyword_with_token(first_child_element)
    logger.debug(f"First child element: '{mapped_first_child_element}'")
    translation = f"""
{parent_element}:

{ONETAB}{mapped_first_child_element}{ONESPACE}{{
{prefix_tabs(first_child_body, 2)}
{ONETAB}}}
"""

    rest_children_elements = [line.strip() for line in data.splitlines() if "|" in line]
    rest_children_elements = [
        line[1:].strip() for line in rest_children_elements if line.startswith("|")
    ]
    for child_element in rest_children_elements:
        child_element = remove_comments_inside_statement(child_element)
        child_body = translate_single_line(child_element, parent_element)

        mapped_child_element = repace_special_keyword_with_token(child_element)
        logger.debug(f"Child element => '{mapped_child_element}'")
        translation += f"""
{ONETAB}|{ONESPACE}{mapped_child_element}{ONESPACE}{{
{prefix_tabs(child_body, 2)}
{ONETAB}}}
"""

    translation += "\n;"

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

@click.command()
@click.option("-o", "--output", default="bison_parser_2.y")
@click.option("--remove-comments", is_flag=True, default=False)
def run(output, remove_comments):
    # Remove all_ir_type.txt, if exist
    if os.path.exists("./all_ir_types.txt"):
        os.remove("./all_ir_types.txt")

    data = open("assets/parser_stmts.y", "r").read()

    marked_lines, extract_tokens = mark_statement_location(data)
    for token_name, extract_token in extract_tokens.items():
        if token_name in manually_translation:
            translation = manually_translation[token_name]
        else:
            translation = translate(extract_token)

        marked_lines = marked_lines.replace(
            f"=== {token_name.strip()} ===", translation, 1
        )

    if os.path.exists(output):
        backup = os.path.abspath(output + ".bak")
        os.system("cp {} {}".format(os.path.abspath(output), backup))
        logger.info(f"Backup the original bison_parser.y to {backup}")

        with open(backup, "r") as f:
            original_contents = f.read()

        with open(output, "w") as f:
            start_pos = original_contents.find("%%") + len("%%")
            stop_pos = original_contents.find("%%", start_pos + 1)

            f.write(original_contents[:start_pos])
            f.write(marked_lines)
            f.write(original_contents[stop_pos:])
    else:
        with open(output, "w") as f:
            f.write(marked_lines)


if __name__ == "__main__":
    run()
