import os
import random
import time
import calendar

non_term_token_mapping = dict()

def init_random():
    current_GMT = time.gmtime()
    time_stamp = calendar.timegm(current_GMT)
    random.seed(time_stamp)

def get_rand_id_from_token(cur_token) -> int:
    global non_term_token_mapping

    if cur_token in non_term_token_mapping:
        return non_term_token_mapping[cur_token]
    else:
        cur_id = random.randint(0, 262143)
        non_term_token_mapping[cur_token] = cur_id
        return cur_id

def insert_grammar_cov_logging(token_sequence, parent) -> str:

    res_str = ""

    current_mapped = dict()
    for token in token_sequence:
        if token.is_terminating_keyword:
            continue
        parend_id = get_rand_id_from_token(parent)
        token_id = get_rand_id_from_token(token.word)

        if token_id in current_mapped:
            continue
        current_mapped[token_id] = 0

        res_str += f"pg_yyget_extra(yyscanner)->gram_cov.log_grammar_cov({token_id},{parend_id}); // mapping from {parent} to {token.word}\n"

    return res_str