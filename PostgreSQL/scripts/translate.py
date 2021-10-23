import sys
import click 
from loguru import logger
from typing import List, Tuple


@click.group()
def cli():
    pass

ONETAB = " "*4
ONESPACE = " "

tokens_mapping = {
    "';'": "OP_SEMI"
}

total_tokens = (
    "PASSWORD",
    "CREATE",
    "USER",
    "DROP",
    "SUBSCRIPTION",
    "IF_P",
    "EXISTS",
)

total_tokens += tuple(tokens_mapping.keys())



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
    

@cli.command()
def run():
    data = """
stmtmulti:	CREATE USER
        {
        }
;
    """
    translate(data)

@cli.command()
def test():
    logger.remove()
    logger.add(sys.stderr, level="ERROR")
    
    try:
        TestDropSubscriptionStmt()
        TestStmtBlock()
        TestCreateUserStmt()
        TestStmtMulti()
        TestOnlyKeywords()
        print("All tests passed!")
    except Exception as e:
        logger.exception(e)
        

def _test(data, expect):
    assert expect.strip() == translate(data).strip()

def TestDropSubscriptionStmt():
    data = """
DropSubscriptionStmt: DROP SUBSCRIPTION name opt_drop_behavior
            {
                DropSubscriptionStmt *n = makeNode(DropSubscriptionStmt);
                n->subname = $3;
                n->missing_ok = false;
                n->behavior = $4;
                $$ = (Node *) n;
            }
            |  DROP SUBSCRIPTION IF_P EXISTS name opt_drop_behavior
            {
                DropSubscriptionStmt *n = makeNode(DropSubscriptionStmt);
                n->subname = $5;
                n->missing_ok = true;
                n->behavior = $6;
                $$ = (Node *) n;
            }
    ;
"""
    expect = """
DropSubscriptionStmt:

    DROP SUBSCRIPTION name opt_drop_behavior {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kDropSubscriptionStmt, OP3("DROP SUBSCRIPTION", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | DROP SUBSCRIPTION IF_P EXISTS name opt_drop_behavior {
        auto tmp1 = $5;
        auto tmp2 = $6;
        res = new IR(kDropSubscriptionStmt, OP3("DROP SUBSCRIPTION IF_P EXISTS", "", ""), tmp1, tmp2);
        $$ = res;
    }

;
    """
    
    _test(data, expect)


def TestStmtBlock(): 
        data = """
stmtblock:	stmtmulti
			{
				pg_yyget_extra(yyscanner)->parsetree = $1;
			}
		;    
"""
        expect = """
stmtblock:

    stmtmulti {
        auto tmp1 = $1;
        res = new IR(kstmtblock, OP3("", "", ""), tmp1);
        $$ = res;
    }

;        
"""        
        _test(data, expect)
        

def TestCreateUserStmt():
    data = """
CreateUserStmt:
			CREATE USER RoleId USER opt_with CREATE OptRoleList USER
				{
					CreateRoleStmt *n = makeNode(CreateRoleStmt);
					n->stmt_type = ROLESTMT_USER;
					n->role = $3;
					n->options = $5;
					$$ = (Node *)n;
				}
		;
    """
    expect = """
CreateUserStmt:

    CREATE USER RoleId USER opt_with CREATE OptRoleList USER {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kUnknown, OP3("CREATE USER", "USER", "CREATE"), tmp1, tmp2);
        auto tmp3 = $7;
        res = new IR(kCreateUserStmt, OP3("", "USER", ""), res, tmp3);
        $$ = res;
    }

;
"""

    _test(data, expect)

def TestStmtMulti():
    data = """
stmtmulti:	stmtmulti ';' stmt
            {
                if ($1 != NIL)
                {
                    /* update length of previous stmt */
                    updateRawStmtEnd(llast_node(RawStmt, $1), @2);
                }
                if ($3 != NULL)
                    $$ = lappend($1, makeRawStmt($3, @2 + 1));
                else
                    $$ = $1;
            }
        | stmt
            {
                if ($1 != NULL)
                    $$ = list_make1(makeRawStmt($1, 0));
                else
                    $$ = NIL;
            }
    ;
"""
    expect = """
stmtmulti:

    stmtmulti OP_SEMI stmt {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kstmtmulti, OP3("", "';'", ""), tmp1, tmp2);
        $$ = res;
    }

    | stmt {
        auto tmp1 = $1;
        res = new IR(kstmtmulti, OP3("", "", ""), tmp1);
        $$ = res;
    }

;
"""
    _test(data, expect)

def TestOnlyKeywords():
    data = """
stmtmulti:	CREATE USER
        {
        }
;
    """
    expect = """
stmtmulti:

    CREATE USER {
        res = new IR(kstmtmulti, string("CREATE USER"));
        $$ = res;
    }

;
"""
    _test(data, expect)

if __name__ == "__main__":
    cli()