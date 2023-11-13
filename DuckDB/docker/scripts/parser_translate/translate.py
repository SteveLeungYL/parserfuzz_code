import os.path
import sys
from typing import List
import re
from translate_instantiation_semantic import setup_identifier_semantics
from translate_utils import *

import click
from loguru import logger

logger.remove()
logger.add(sys.stderr, level="ERROR")

ONETAB = " " * 4
ONESPACE = " "
default_ir_type = "kUnknown"

entry_parser_token = "stmtblock"

saved_ir_type = []

parser_prefix_pre_claimed_types = dict()
missing_prefix_declare = []

custom_keyword_mapping = {
    "TYPECAST": "::",
    "Op": "+",
    "INTEGER_DIVISION": "//",
    "POWER_OF": "**",
    "LESS_EQUALS": "<=",
    "GREATER_EQUALS": ">=",
    "NOT_EQUALS": "<>",
}

ignored_token_rules = [
    "unreserved_keyword",
    "col_name_keyword",
    "func_name_keyword",
    "type_name_keyword",
    "other_keyword",
    "type_func_name_keyword",
    "reserved_keyword"
]

def snake_to_camel(word):
    return "".join(x.capitalize() or "_" for x in word.split("_"))


def camel_to_snake(word):
    return "".join(["_" + i.lower() if i.isupper() else i for i in word]).lstrip("_")


grammar_suffix = """
#line 1 "third_party/libpg_query/grammar/grammar.cpp"
/*
 * The signature of this function is required by bison.  However, we
 * ignore the passed yylloc and instead use the last token position
 * available from the scanner.
 */
static void
base_yyerror(YYLTYPE *yylloc, core_yyscan_t yyscanner, const char *msg)
{
	parser_yyerror(msg);
}

std::string cstr_to_string(char *str) {
   std::string res(str, strlen(str));
   return res;
}

std::vector<IR*> get_ir_node_in_stmt_with_type(IR* cur_IR, IRTYPE ir_type) {

    // Iterate IR binary tree, left depth prioritized.
    bool is_finished_search = false;
    std::vector<IR*> ir_vec_iter;
    std::vector<IR*> ir_vec_matching_type;
    // Begin iterating.
    while (!is_finished_search) {
        ir_vec_iter.push_back(cur_IR);
        if (cur_IR->type_ == ir_type) {
            ir_vec_matching_type.push_back(cur_IR);
        }

        if (cur_IR->left_ != nullptr){
            cur_IR = cur_IR->left_;
            continue;
        } else { // Reaching the most depth. Consulting ir_vec_iter for right_ nodes.
            cur_IR = nullptr;
            while (cur_IR == nullptr){
                if (ir_vec_iter.size() == 0){
                    is_finished_search = true;
                    break;
                }
                cur_IR = ir_vec_iter.back()->right_;
                ir_vec_iter.pop_back();
            }
            continue;
        }
    }

    return ir_vec_matching_type;
}

void setup_col_id(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag) {
    std::vector<IR*> v_iden = get_ir_node_in_stmt_with_type(cur_ir, kIdentifier);
    for (IR* cur_iden: v_iden) {
        cur_iden->set_data_type(data_type);
        cur_iden->set_data_flag(data_flag);
    }
    return;
}

void setup_col_id_or_string(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag) {
    std::vector<IR*> v_iden = get_ir_node_in_stmt_with_type(cur_ir, kIdentifier);
    for (IR* cur_iden: v_iden) {
        cur_iden->set_data_type(data_type);
        cur_iden->set_data_flag(data_flag);
    }
    return;
}

void setup_name(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag) {
    std::vector<IR*> v_iden = get_ir_node_in_stmt_with_type(cur_ir, kIdentifier);
    for (IR* cur_iden: v_iden) {
        cur_iden->set_data_type(data_type);
        cur_iden->set_data_flag(data_flag);
    }
    return;
}

void setup_table_id(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag) {
    std::vector<IR*> v_iden = get_ir_node_in_stmt_with_type(cur_ir, kIdentifier);
    for (IR* cur_iden: v_iden) {
        cur_iden->set_data_type(data_type);
        cur_iden->set_data_flag(data_flag);
    }
    return;
}

/* parser_init()
 * Initialize to parse one query string
 */
void
parser_init(base_yy_extra_type *yyext)
{
	yyext->parsetree = NIL;		/* in case grammar forgets to set it */
}

#undef yyparse
#undef yylex
#undef yyerror
#undef yylval
#undef yychar
#undef yydebug
#undef yynerrs
#undef yylloc

} // namespace duckdb_libpgquery

"""

grammar_prefix = """
%{
#line 1 "third_party/libpg_query/grammar/grammar.hpp"

#include "pg_functions.hpp"
#include <string.h>
#include <string>
#include <vector>

#include <ctype.h>
#include <limits.h>

#include "nodes/makefuncs.hpp"
#include "nodes/nodeFuncs.hpp"
#include "parser/gramparse.hpp"
#include "parser/parser.hpp"
#include "utils/datetime.hpp"

namespace duckdb_libpgquery {
#define DEFAULT_SCHEMA "main"

std::vector<IR*> ir_vec;

#define YYLLOC_DEFAULT(Current, Rhs, N) \\
	do { \\
		if ((N) > 0) \\
			(Current) = (Rhs)[1]; \\
		else \\
			(Current) = (-1); \\
	} while (0)
	
#define YYMALLOC palloc
#define YYFREE   pfree
#define YYINITDEPTH 1000

#define parser_yyerror(msg)  scanner_yyerror(msg, yyscanner)
#define parser_errposition(pos)  scanner_errposition(pos, yyscanner)

static void base_yyerror(YYLTYPE *yylloc, core_yyscan_t yyscanner,
						 const char *msg);
						 
std::string cstr_to_string(char *str);
std::vector<IR*> get_ir_node_in_stmt_with_type(IR* cur_IR, IRTYPE ir_type);
void setup_col_id(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag);
void setup_col_id_or_string(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag);
void setup_name(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag);
void setup_table_id(IR* cur_ir, DATATYPE data_type, DATAFLAG data_flag);
						 
%}
#line 5 "third_party/libpg_query/grammar/grammar.y"
%pure-parser
%expect 0
%name-prefix="base_yy"
%locations

%parse-param {core_yyscan_t yyscanner}
%lex-param   {core_yyscan_t yyscanner}

%union
{
    /* ParserFuzz Inject */
    IR* ir;
    /* ParserFuzz Inject END */
	core_YYSTYPE		core_yystype;
	/* these fields must match core_YYSTYPE: */
	int					ival;
	char				*str;
	const char			*keyword;
	const char          *conststr;

	char				chr;
	bool				boolean;
	PGJoinType			jtype;
	PGDropBehavior		dbehavior;
	PGOnCommitAction		oncommit;
	PGOnCreateConflict		oncreateconflict;
	PGList				*list;
	PGNode				*node;
	PGValue				*value;
	PGObjectType			objtype;
	PGTypeName			*typnam;
	PGObjectWithArgs		*objwithargs;
	PGDefElem				*defelt;
	PGSortBy				*sortby;
	PGWindowDef			*windef;
	PGJoinExpr			*jexpr;
	PGIndexElem			*ielem;
	PGAlias				*alias;
	PGRangeVar			*range;
	PGIntoClause			*into;
	PGCTEMaterialize			ctematerialize;
	PGWithClause			*with;
	PGInferClause			*infer;
	PGOnConflictClause	*onconflict;
	PGOnConflictActionAlias onconflictshorthand;
	PGAIndices			*aind;
	PGResTarget			*target;
	PGInsertStmt			*istmt;
	PGVariableSetStmt		*vsetstmt;
	PGOverridingKind       override;
	PGSortByDir            sortorder;
	PGSortByNulls          nullorder;
	PGConstrType           constr;
	PGLockClauseStrength lockstrength;
	PGLockWaitPolicy lockwaitpolicy;
	PGSubLinkType subquerytype;
	PGViewCheckOption viewcheckoption;
	PGInsertColumnOrder bynameorposition;
}

"""

def modify_prefix(grammar_prefix: str) -> str:
    res_str = ""
    stop_reading = True
    for cur_line in grammar_prefix.splitlines():
        if "%type <" in cur_line:
            stop_reading = False

        if stop_reading:
            # skip line
            continue

        # Skip ignored keyword in the declaration
        for cur_ignored_keyword in ignored_token_rules:
            tmp_ignored_keyword = " " + cur_ignored_keyword
            if tmp_ignored_keyword in cur_line:
                cur_line = cur_line.replace(tmp_ignored_keyword, " ")

        # rewrite type names
        if re.match("%type <.*%type <", cur_line) != None:
            cur_line = cur_line.replace("%type", "\n%type")
        if "%type <" in cur_line:
            cur_line = re.sub("%type <.*>", "%type <ir>", cur_line)

        if "%type <" in cur_line and (len(cur_line.split(">")) <= 1 or cur_line.split(">")[1].strip() == ""):
            continue

        cur_line = cur_line.strip()
        if cur_line == "":
            continue

        for cur_claimed_token in cur_line.split():
            parser_prefix_pre_claimed_types[cur_claimed_token] = 0

        res_str += cur_line + "\n"

    return res_str

def tokenize(line: List[str]) -> List[Token]:

    words = [word for word in line if word and word != "empty" and word != "/*EMPTY*/"]

    words = [custom_keyword_mapping[word] if word in custom_keyword_mapping else word for word in words]

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



def get_special_handling_ir_body(cur_token: Token, parent: str, token_sequence: List[Token], tmp_num: int) -> str:
    body = ""
    type_name = is_identifier(cur_token)
    if type_name == "kIdentifier" or type_name ==  "kStringLiteral" or type_name == "kFloatLiteral" or type_name == "kBinLiteral":
        body += f"auto tmp{tmp_num} = new IR({type_name}, cstr_to_string(${cur_token.index + 1}), kDataFixLater, kFlagUnknown);" + "\n"
        body += f"ir_vec.push_back(tmp{tmp_num});\n"
    elif type_name != None and type_name == "kIntegerLiteral":
        body += f"auto tmp{tmp_num} = new IR({type_name}, ${cur_token.index + 1});" + "\n"
        body += f"ir_vec.push_back(tmp{tmp_num});\n"
    elif type_name != None and type_name == "kBoolLiteral":
        if cur_token.word == "TRUE_P":
            body += f"auto tmp{tmp_num} = new IR({type_name}, std::string(\"TRUE\"));" + "\n"
        else:
            body += f"auto tmp{tmp_num} = new IR({type_name}, std::string(\"FALSE\"));" + "\n"
        body += f"ir_vec.push_back(tmp{tmp_num});\n"
    else:
        body += f"auto tmp{tmp_num} = ${cur_token.index + 1};" + "\n"

    token_sequence = [w.word for w in token_sequence]
    body += setup_identifier_semantics(cur_token=cur_token, parent=parent, token_sequence = token_sequence, ir_ref = f"tmp{tmp_num}")

    return body

def translate_single_line(token_sequence, parent):
    token_sequence = tokenize(token_sequence)

    i = 0
    tmp_num = 1
    body = ""
    need_more_ir = False

    body += "IR* res; \n"

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

            body += get_special_handling_ir_body(left_token, parent, token_sequence, tmp_num)
            body += (
                f"""res = new IR({default_ir_type}, OP3("", "{left_keywords_str}", "{mid_keywords_str}"), res, tmp{tmp_num});"""
                + "\n"
            )
            body += "ir_vec.push_back(res); \n"
            tmp_num += 1

            if right_token and not right_token.is_terminating_keyword:
                body += get_special_handling_ir_body(right_token, parent, token_sequence, tmp_num)
                body += (
                    f"""res = new IR({default_ir_type}, OP3("", "", "{right_keywords_str}"), res, tmp{tmp_num});"""
                    + "\n"
                )
                body += "ir_vec.push_back(res); \n"
                tmp_num += 1

        elif right_token and right_token.is_terminating_keyword == False:
            body += get_special_handling_ir_body(left_token, parent, token_sequence, tmp_num)
            body += get_special_handling_ir_body(right_token, parent, token_sequence, tmp_num + 1)
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
                and not left_token.is_terminating_keyword
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
            if not left_token.is_terminating_keyword:
                body += get_special_handling_ir_body(left_token, parent, token_sequence, tmp_num)
                body += (
                    f"""res = new IR({default_ir_type}, OP3("{left_keywords_str}", "{mid_keywords_str}", ""), tmp{tmp_num});"""
                    + "\n"
                )
                body += "ir_vec.push_back(res); \n"
            else:
                body += (
                        f"""res = new IR({default_ir_type}, OP3("{left_keywords_str}", "{mid_keywords_str}", ""));"""
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

    if parent == entry_parser_token:
        body += "\npg_yyget_extra(yyscanner)->ir_vec = ir_vec; \nir_vec.clear(); \n"

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

    clean_data = remove_single_line_comment(clean_data)
    return clean_data


def translate_preprocessing(data):
    """Remove comments, and remove the original actions from the parser"""

    data = data.replace("/* EMPTY */", "/*EMPTY*/")
    data = data.replace("/* empty */", "/*EMPTY*/")
    """Remove original actions here. """
    all_new_data = remove_original_actions(data)

    """Join comments from multiple lines into one line."""
    all_new_data = join_comments_into_oneline(all_new_data)

    return all_new_data


def remove_comments_inside_statement(text):
    text = text.strip()
    if not (text.startswith("/*") and text.endswith("*/") and text.count("/*") == 1):
        text = remove_comments_if_necessary(text, True)
    return text


def translate(parent_element: str, child_rules: [str]):

    if parent_element.endswith("_2"):
        parent_element = parent_element[:-2]

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

    with open("all_ir_types.txt", "a") as f, open("missing_parser_class.txt", "a") as missing_f:

        if parent_element not in parser_prefix_pre_claimed_types:
            missing_f.write(f"{parent_element} \n")
            parser_prefix_pre_claimed_types[parent_element] = 0
            missing_prefix_declare.append(parent_element)

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

    clean_text = clean_text.strip()

    new_res = ""
    for cur_line in clean_text.splitlines():
        if "/*" in cur_line and "*/" in cur_line and "/*EMPTY*/" not in cur_line:
            cur_line = cur_line.replace("/*", "\n/*")
        new_res += cur_line + "\n"

    return new_res


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
        if (cur_line.strip().startswith("#") or
                (cur_line.strip().startswith("/*") and not cur_line.strip().startswith("/*EMPTY*/")) or
                cur_line.strip().startswith(" *")):
            continue

        cur_line = cur_line.strip()
        if len(cur_line) == 0:
            continue

        token_seq = [x for x in cur_line.split() if x != "%%" and x != ";" and x != "{}"]

        if len(token_seq) == 0:
            continue

        for cur_token in token_seq:
            if cur_token in ignored_token_rules:
                continue
            elif cur_token.endswith(":"):
                if len(cur_token_seq) > 0 and cur_parent not in ignored_token_rules:
                    if cur_parent != "" and cur_parent not in extract_tokens.keys():
                        extract_tokens[cur_parent] = [cur_token_seq]
                    elif cur_parent != "":
                        extract_tokens[cur_parent].append(cur_token_seq)

                if cur_parent not in ignored_token_rules and cur_parent != "":
                    marked_str += f"=== {cur_parent.strip()} ===\n"

                cur_token_seq = []
                cur_parent = cur_token[:-1]
                if cur_parent in extract_tokens.keys():
                    # Special handling for indirection_el:
                    cur_parent += "_2"


            elif cur_token == "|":
                if len(cur_token_seq) > 0 and cur_parent not in ignored_token_rules:
                    if cur_parent != "" and cur_parent not in extract_tokens.keys():
                        extract_tokens[cur_parent] = [cur_token_seq]
                    elif cur_parent != "":
                        extract_tokens[cur_parent].append(cur_token_seq)

                cur_token_seq = []

            else:
                cur_token_seq.append(cur_token)

    if len(cur_token_seq) > 0 and cur_parent not in ignored_token_rules:
        if cur_parent not in extract_tokens.keys():
            extract_tokens[cur_parent] = [cur_token_seq]
        else:
            extract_tokens[cur_parent].append(cur_token_seq)

    # Custom patch:
    extract_tokens["opt_enum_val_list"].append(["/*EMPTY*/"])
    return marked_str, extract_tokens

@click.command()
@click.option("-o", "--output", default="grammar_modi.y")
@click.option("--remove-comments", is_flag=True, default=False)
def run(output, remove_comments):
    global grammar_prefix
    global grammar_suffix

    # Remove all_ir_type.txt, if exist
    if os.path.exists("./all_ir_types.txt"):
        os.remove("./all_ir_types.txt")
    if os.path.exists("./missing_parser_class.txt"):
        os.remove("./missing_parser_class.txt")
    if os.path.exists("./tmp_marked_lines.txt"):
        os.remove("./tmp_marked_lines.txt")

    data = open("assets/grammar.y.ori").read()

    data_split = data.split("%%")

    grammar_prefix_add_on = modify_prefix(data_split[0])

    grammar_rule_str = data_split[1]
    grammar_rule_str = remove_comments_if_necessary(grammar_rule_str, remove_comments)

    marked_lines, extract_tokens = mark_statement_location(grammar_rule_str)

    with open("tmp_marked_lines.txt", "w") as f:
        f.write(marked_lines)

    for parent_element, extract_token in extract_tokens.items():
        translation = translate(parent_element, extract_token)

        marked_lines = marked_lines.replace(
            f"=== {parent_element.strip()} ===", translation, 1
        )

    # Adding the missing non-terminating symbol declare.
    for cur_missing_symbol in missing_prefix_declare:
        grammar_prefix += f"%type <ir> {cur_missing_symbol} \n"
    grammar_prefix += grammar_prefix_add_on


    with open(output, "w") as f:
        f.write(grammar_prefix)
        f.write("\n%%\n")
        f.write(marked_lines)
        f.write("\n%%\n")
        f.write(grammar_suffix)

    with open("all_ir_types.txt", "a") as f:
        for custom_name in ("kIdentifier", "kStringLiteral",
                            "kFloatLiteral", "kIntegerLiteral",
                            "kBinLiteral", "kBoolLiteral",
                            "kUnknown"
                            ):
            if custom_name not in saved_ir_type:
                saved_ir_type.append(custom_name)
                f.write(f"V({custom_name})   \\\n")

if __name__ == "__main__":
    run()
