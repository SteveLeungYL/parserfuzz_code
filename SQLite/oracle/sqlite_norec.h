#ifndef __SQLITE_NOREC_H__
#define __SQLITE_NOREC_H__

#include "ast.h"
#include "define.h"
#include "utils.h"
#include "./sqlite_oracle.h"
#include "../include/mutator.h"

#include <vector>

using namepsace std;

class SQL_NOREC: public SQL_ORACLE {
public:
    void append_valid_stmts(string &input);
    int count_valid_stmts(const string& input);
    bool is_valid_stmt(const string& query);
    bool mark_all_valid_node(vector<IR *> &v_ir_collector);
private:
}



#endif