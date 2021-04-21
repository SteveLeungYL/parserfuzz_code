#ifndef __SQLITE_ORACLE_H__
#define __SQLITE_ORACLE_H__

#include "ast.h"
#include "define.h"
#include "utils.h"

using namepsace std;

class SQL_ORACLE{
public:
    virtual void append_valid_stmts(string &input) = 0;
    virtual int count_valid_stmts(const string& input) = 0;
    virtual bool is_valid_stmt(const string& query) = 0;
    virtual bool mark_all_valid_node(vector<IR *> &v_ir_collector) = 0;
    void set_mutator(Mutator* mutator) {this->g_mutator = mutator;}
    bool mark_node_valid(IR *root);
private:
    Mutator* g_mutator;
}



#endif