#include "../include/ast.h"

#include <algorithm>
#include <atomic>
#include <climits>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <functional>
#include <iterator>
#include <memory>
#include <optional>
#include <string>
#include <utility>
#include <vector>

#include "my_config.h"
#ifdef HAVE_LSAN_DO_RECOVERABLE_LEAK_CHECK
#include <sanitizer/lsan_interface.h>
#endif

#include "sql/sql_class.h"
#include "sql/sql_lex.h"
#include "sql/parse_tree_node_base.h"
#include "sql/parse_tree_nodes.h"
#include "sql/table.h"
#include "sql/sql_parse.h"
#include "sql/error_handler.h"
#include "include/mysys_err.h"
#include "sql/sql_locale.h"
#include "sql/derror.h"
#include "sql/sp_head.h"

extern int MYSQLparse(class THD * thd, class Parse_tree_root * *root, vector<IR*> ir_vec, IR* res);

bool parse_sql_entry(THD *thd, Parser_state *parser_state,
               Object_creation_ctx *creation_ctx, vector<IR*>& ir_vec);

bool exec_query_command_entry(string input, vector<IR*> ir_vec);
