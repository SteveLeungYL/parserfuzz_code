import sys

import click
from loguru import logger
from typing import List
import re


ONETAB = " "*4
ONESPACE = " "

keywords_mapping = {
    "';'": "OP_SEMI"
}

custom_additional_keywords = set([
    "PASSWORD",
    "CREATE",
    "USER",
    "DROP",
    "SUBSCRIPTION",
    "IF_P",
    "EXISTS",
    "/*EMPTY*/"
])

total_keywords = set()
total_keywords |= custom_additional_keywords
total_keywords |= set(keywords_mapping.keys())

total_tokens = set()

class Token(object):
    
    def __init__(self, word, index, is_keyword=False):
        self.word = word
        self.index = index
        self.is_keyword = is_keyword

    def __str__(self) -> str:
        return self.word

    def __repr__(self) -> str:
        return f'Token("{self.word}")'

    def __gt__(self, other):
        other_index = -1
        if isinstance(other, Token):
            other_index = other.index
            
        return self.index > other_index

def snake_to_camel(word):
    return ''.join(x.capitalize() or '_' for x in word.split('_'))


def camel_to_snake(word): 
    return ''.join(['_'+i.lower() if i.isupper()
               else i for i in word]).lstrip('_')

def tokenize(line) -> List[Token]:
    words = [word.strip() for word in line.split()]
    words = [word for word in words if word]
    
    token_sequence = []
    for idx, word in enumerate(words):            
        token_sequence.append(Token(word, idx))
        
    return token_sequence

def repace_special_keyword_with_token(line):
    words = [word.strip() for word in line.split()]
    words = [word for word in words if word]
    
    seq = []
    for word in words:
        word = word.strip() 
        if not word: 
            continue 
        if word in keywords_mapping:
            word = keywords_mapping[word] 
        seq.append(word)
    
    return " ".join(seq)        

def recognize_tokens(token_sequence: List[Token]):    
    for token in token_sequence:
        if token.word in total_keywords:
            token.is_keyword = True

def prefix_tabs(text, tabs_num):
    result = []
    text = text.strip() 
    for line in text.splitlines():
        result.append(ONETAB*tabs_num + line)
    return "\n".join(result)    

def search_next_keyword(token_sequence, start_index):
    curr_token = None
    left_keywords = []
    
    if start_index > len(token_sequence):
        return curr_token, left_keywords
    
    for idx in range(start_index, len(token_sequence)): 
        curr_token = token_sequence[idx]
        if curr_token.is_keyword:
            left_keywords.append(curr_token)
        else: 
            break 
    return curr_token, left_keywords
    
def translate_single_line(line, parent):
    token_sequence = tokenize(line)
    recognize_tokens(token_sequence)
    
    i = 0
    tmp_num = 1
    body = ""
    need_more_ir = False
    while ( i < len(token_sequence)):
        left_token, left_keywords = search_next_keyword(token_sequence, i)
        logger.debug(f"Left tokens: '{left_token}', Left keywords: '{left_keywords}'")
        
        right_token, mid_keywords = search_next_keyword(token_sequence, left_token.index+1)
        right_keywords = []
        if right_token:
            _, right_keywords = search_next_keyword(token_sequence, right_token.index+1)
            
        
        left_keywords_str = " ".join([token.word for token in left_keywords])
        mid_keywords_str = " ".join([token.word for token in mid_keywords])
        right_keywords_str = " ".join([token.word for token in right_keywords])
        

        if need_more_ir:
            # body += "PUSH(res);"
            body += f"auto tmp{tmp_num} = ${left_token.index+1};" + "\n"
            body += f"""res = new IR(kUnknown, OP3("{left_keywords_str}", "{mid_keywords_str}", "{right_keywords_str}"), res, tmp{tmp_num});""" + "\n"
            tmp_num += 1
        elif right_token:
            body += f"auto tmp{tmp_num} = ${left_token.index+1};" + "\n"
            body += f"auto tmp{tmp_num+1} = ${right_token.index+1};" + "\n"
            body += f"""res = new IR(kUnknown, OP3("{left_keywords_str}", "{mid_keywords_str}", "{right_keywords_str}"), tmp{tmp_num}, tmp{tmp_num+1});""" + "\n"
            
            tmp_num += 2
            need_more_ir = True
        elif left_token: 
            if not body and left_token.index == len(token_sequence)-1 and token_sequence[left_token.index].word in total_keywords: 
                if left_keywords_str.replace(" ", "") == "/*EMPTY*/":
                    left_keywords_str = ""
                body += f"""res = new IR(kUnknown, string("{left_keywords_str}"));""" + "\n"
                break
            body += f"auto tmp{tmp_num} = ${left_token.index+1};" + "\n"
            body += f"""res = new IR(kUnknown, OP3("{left_keywords_str}", "{mid_keywords_str}", ""), tmp{tmp_num});""" + "\n"
            
            tmp_num += 1
            need_more_ir = True
        else:
            pass
        
        
        compare_tokens = left_keywords + mid_keywords + right_keywords
        if left_token: compare_tokens.append(left_token)
        if right_token: compare_tokens.append(right_token)
        
        max_index_token = max(compare_tokens)
        i = max_index_token.index + 1


    # fix the IR type to kUnknown
    if body: 
        body = f"k{parent}".join(body.rsplit("kUnknown", 1))
        body += "$$ = res;" 


    logger.debug(f"Result: \n{body}")
    return body


def find_first_alpha_index(data, start_index):
    for idx, c in enumerate(data[start_index:]):
        if c.isalpha() or \
           c == "/" and data[start_index+idx+1] == "*":
            return start_index+idx

def translate_preprocessing(data):
    """Remove comments, and remove the original actions from the parser"""

    """Remove original actions here. """
    data = re.sub('\{.*?\}', '', data, flags=re.S)

    #
    # TODO: merge multiple line into one line
    #
    return data

def translate(data):

    data = translate_preprocessing(data)
    data = data.strip()

    parent_element = data[:data.find(":")]
    logger.debug(f"Parent element: '{parent_element}'")

    first_alpha_after_colon = find_first_alpha_index(data, data.find(":"))
    first_child_element = data[first_alpha_after_colon: data.find("\n", first_alpha_after_colon)]
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
    rest_children_elements = [line[1:].strip() for line in rest_children_elements if line.startswith("|")]
    for child_element in rest_children_elements:
        child_body = translate_single_line(child_element, parent_element)
        
        mapped_child_element = repace_special_keyword_with_token(child_element)
        logger.debug(f"Child element => '{mapped_child_element}'")
        translation += f"""
{ONETAB}|{ONESPACE}{mapped_child_element}{ONESPACE}{{
{prefix_tabs(child_body, 2)}
{ONETAB}}}
"""

    translation += "\n;"
    logger.info(translation)
    return translation

def load_keywords_from_kwlist():
    global total_keywords

    kwlist_path = "assets/kwlist.h"
    with open(kwlist_path) as f:
        keyword_data = f.read()
    
    keyword_data = remove_comments_if_necessary(keyword_data, True)
    
    keyword_data = keyword_data.splitlines()
    keyword_data = [line.strip() for line in keyword_data]
    keyword_data = [line for line in keyword_data if line.startswith("PG_KEYWORD")]
    
    kwlist_tokens = set([line.split()[1].strip(",") for line in keyword_data])
    total_keywords |= kwlist_tokens


def get_gram_tokens():
    global total_tokens

    tokens_file = "assets/tokens.y"
    with open(tokens_file) as f: 
        token_data = f.read() 
    
    token_data = remove_comments_if_necessary(token_data, True)
    
    token_data = token_data.splitlines()
    token_data = [line.strip() for line in token_data]
    token_data = [line for line in token_data if line]
    
    gram_tokens = set()
    for line in token_data:
        line = line.replace("\t", " ")
        if line.startswith("%type"):
            line = line.split(" ", 2)[-1]
            
        line = line.strip()
        gram_tokens |= set(line.split())
    
    for token in gram_tokens:
        if token.startswith("<"): 
            logger.info(token)
    
    unwanted = ["", " "]
    for elem in unwanted:
        if elem in gram_tokens: 
            gram_tokens.remove(elem)

    total_tokens |= gram_tokens

def get_gram_keywords():
    keywords_file = "assets/keywords.y"
    with open(keywords_file) as f: 
        keyword_data = f.read() 
    
    keyword_data = remove_comments_if_necessary(keyword_data, True)
    
    keyword_data = keyword_data.splitlines()
    keyword_data = [line.strip() for line in keyword_data if line.strip()]
    keyword_data = [line for line in keyword_data if not (line.startswith("*") or line.startswith("/"))]

    gram_keywords = set()
    for line in keyword_data:
        line = line.replace("\t", " ")
        
        if line.startswith("%token") and " <" in line and "> " in line: 
            line = line.split(" ", 2)[-1]
        elif line.startswith("%"):
            line = line.split(" ", 1)[-1]

        line = line.strip()
        gram_keywords|= set(line.split())
    
    unwanted = ["", " "]
    for elem in unwanted:
        if elem in gram_keywords: 
            gram_keywords.pop("")

    
        
def remove_comments_if_necessary(text, need_remove):
    if not need_remove: 
        return text
    
    pattern = '/\*.*?\*/'
    return re.sub(pattern, '', text, flags=re.S)

def remove_original_actions(text):
    pattern = '\{.*?\}'
    return re.sub(pattern, '', text, flags=re.S)

def select_translate_region(data):
    pattern = "%%"
    start_pos = data.find(pattern) + len(pattern)
    stop_pos = data.find(pattern, start_pos)
    return data[start_pos: stop_pos]

def mark_statement_location(data):

    class Line(object):
        def __init__(self, lineno,  contents):
            self.lineno:int = lineno
            self.contents:str = contents

            words = self.contents.split()
            first_elem: str = words[0] if words else ""
            self.contain_colon = ":" in first_elem
            self.first_word = first_elem.rstrip(":")
            self.first_is_token = self.first_word in total_tokens

        def __repr__(self):
            return f"Line({self.lineno}, {self.first_word})"

    lines = [line.strip() for line in data.splitlines()]
    line_objs = [Line(lineno, contents) for lineno, contents in enumerate(lines)]
    token_objs = [line_obj for line_obj in line_objs if line_obj.contain_colon]
    token_objs = [line_obj for line_obj in token_objs if line_obj.first_is_token]

    token_objs = sorted(token_objs, key=lambda x: x.lineno)

    range_bits = [i for i in range(len(lines))]

    def search_next_semicolon_line(lines, start_index, stop_index):
        partial_lines = lines[start_index: stop_index]
        for relative_index, line in enumerate(partial_lines):
            if line == ";":
                return start_index + relative_index

        # HACK: hack for single line grammar, maybe not accurate
        if partial_lines[0].endswith(";"):
            return start_index

        logger.warning("Cannot find next semicolon. ")
        logger.warning(partial_lines)


    extract_tokens = {}
    for idx in range(len(token_objs)):
        token_start = token_objs[idx]
        lineno_start = token_start.lineno

        if idx + 1 == len(token_objs):
            lineno_stop = len(lines)
        else:
            token_stop = token_objs[idx + 1]
            lineno_stop = token_stop.lineno

        semicolon_index = search_next_semicolon_line(lines, lineno_start, lineno_stop)
        extract_tokens[token_start.first_word] = "\n".join(lines[lineno_start: semicolon_index+1])

        range_bits[lineno_start] = token_start.first_word
        for j in range(lineno_start+1, semicolon_index+1):
            range_bits[j] = False

    marked_lines = []
    for k in range_bits:
        if k == False:
            continue

        if isinstance(k, str):
            marked_lines.append(f"<{k.strip()}>")
            continue

        if k:
            marked_lines.append(lines[k])
            continue

        marked_lines.append(lines[k])

    marked_lines = "\n".join(marked_lines)

    return marked_lines, extract_tokens


@click.command()
@click.option("-o", "--output", default="gram.y", type=click.Path(exists=False))
@click.option("--remove-comments", is_flag=True, default=False)
def run(output, remove_comments):
    data = open("assets/gram.y", "r").read()
    
    data = remove_comments_if_necessary(data, remove_comments)
    data = select_translate_region(data)

    get_gram_tokens()
    get_gram_keywords()
    load_keywords_from_kwlist()

    marked_lines, extract_tokens = mark_statement_location(data)
    for token_name, extract_token in extract_tokens.items():

        translation = translate(extract_token)
        marked_lines = marked_lines.replace(f"<{token_name}>", translation, 1)

    with open(output, "w") as f:
        f.write(marked_lines)


if __name__ == "__main__":
    run()