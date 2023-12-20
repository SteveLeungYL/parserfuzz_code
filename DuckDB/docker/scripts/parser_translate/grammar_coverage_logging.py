import os
import random
import time
import calendar

non_term_token_id_map = dict()
total_injected_grammar_edge = dict()

def init_random():
    current_GMT = time.gmtime()
    time_stamp = calendar.timegm(current_GMT)
    random.seed(time_stamp)

def get_rand_id_from_token(cur_token) -> int:
    global non_term_token_id_map

    if cur_token in non_term_token_id_map:
        return non_term_token_id_map[cur_token]
    else:
        cur_id = random.randint(0, 262143)
        non_term_token_id_map[cur_token] = cur_id
        return cur_id

def get_total_injected_grammar_edge_num():
    global total_injected_grammar_edge
    return len(total_injected_grammar_edge)

def insert_grammar_cov_logging(token_sequence, parent) -> str:
    global total_injected_grammar_edge

    res_str = ""
    res_str += "if (gram_cov != nullptr) {\n"

    current_mapped = dict()
    for token in token_sequence:
        if token.is_terminating_keyword:
            continue
        parend_id = get_rand_id_from_token(parent)
        token_id = get_rand_id_from_token(token.word)

        if token_id in current_mapped:
            continue
        current_mapped[token_id] = 0

        res_str += f"\tgram_cov->log_edge_cov_map({parend_id},{token_id}); // mapping from {parent} to {token.word}\n"

        cur_grammar_edge_id = ((parend_id >> 1) ^ token_id)
        if cur_grammar_edge_id not in total_injected_grammar_edge:
            total_injected_grammar_edge[cur_grammar_edge_id] = 0

    res_str += "}\n"

    return res_str