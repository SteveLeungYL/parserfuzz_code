import click 
from loguru import logger
from typing import List
import re


ONETAB = " "*4
ONESPACE = " "

tokens_mapping = {
    "';'": "OP_SEMI"
}

total_tokens = set([
    "PASSWORD",
    "CREATE",
    "USER",
    "DROP",
    "SUBSCRIPTION",
    "IF_P",
    "EXISTS",
    "/*EMPTY*/"
])

total_tokens |= set(tokens_mapping.keys())



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
    for word in line.split():
        word = word.strip() 
        if not word: 
            continue 
        if word in tokens_mapping:
            word = tokens_mapping[word] 
        seq.append(word)
    
    return " ".join(seq)        

def recognize_tokens(token_sequence: List[Token]):    
    for token in token_sequence:
        if token.word in total_tokens:
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
    
    left_keywords = []
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
            if not body and left_token.index == len(token_sequence)-1 and token_sequence[left_token.index].word in total_tokens: 
                if left_keywords_str == "/*EMPTY*/":
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
        if c.isalpha():
            return start_index+idx

def translate_preprocessing(data):
    """Remove comments, and remove the original actions from the parser"""

    """Remove original actions here. """
    data = re.sub('\{.*?\}', '', data, flags=re.S)

    data = re.sub('/\*.*?\*/', '', data, flags=re.S)

    all_new_data = []
    new_data = ""
    cur_data = ""
    all_lines = data.split('\n')
    for cur_line in all_lines:
        if ":" in cur_line:
            new_data += cur_data + "\n"
            cur_data = cur_line
            all_new_data.append(new_data)
            new_data = ""
        elif "|" in cur_line or cur_line == all_lines[-1]:
            new_data += cur_data + "\n"
            cur_data = cur_line
        else:
            cur_data += cur_line

    with open("draft.txt", "w") as f:
        for new_data in all_new_data:
            f.write(new_data)
    return all_new_data

def translate(data):
    translation = ""
    
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

def load_tokens_from_kwlist(kwlist):
    global total_tokens
    
    kwlines = []
    with open(kwlist) as f: 
        kwlines = [line.strip() for line in f.readlines() if line.startswith("PG_KEYWORD")]
    
    kwlist_tokens = set([line.split()[1].strip(",") for line in kwlines])
    total_tokens |= kwlist_tokens


def get_gram_tokens():
    tokens_file = "assets/tokens.y"
    with open(tokens_file) as f: 
        token_data = f.readlines() 
    
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

def get_gram_keywords():
    keywords_file = "assets/keywords.y"
    with open(keywords_file) as f: 
        keyword_data = f.readlines() 
    
    keyword_data = [line.strip() for line in keyword_data if line.strip()]
    keyword_data = [line for line in keyword_data if not (line.startswith("*") or line.startswith("/"))]

    # TODO
    
@click.command()
def run():
    data = open("assets/parser_stmts.y", "r").read()
    
    get_gram_tokens() 
    get_gram_keywords()
    
    kwlist_path = "assets/kwlist.h"
    load_tokens_from_kwlist(kwlist_path)
    
    logger.debug(f"len total_tokens: {len(total_tokens)}")

    all_pre_trans_str = translate_preprocessing(data = data)
    all_trans_str = []
    for cur_pre_trans_str in all_pre_trans_str:
        all_trans_str.append(translate(cur_pre_trans_str))
    with open("./trans_str.txt", "w") as f:
        for cur_trans_str in all_trans_str:
            f.write(cur_trans_str)


if __name__ == "__main__":
    run()