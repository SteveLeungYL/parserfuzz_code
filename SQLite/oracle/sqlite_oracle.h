#ifndef __SQLITE_ORACLE_H__
#define __SQLITE_ORACLE_H__

#include "../include/ast.h"
#include "../include/define.h"

#include <string>
#include <vector>

using namespace std;

class Mutator;

class SQL_ORACLE {
public:
    virtual void append_ori_valid_stmts(string query_str, int valid_max_num) = 0;

    virtual int count_valid_stmts(const string& input) = 0;
    virtual bool is_oracle_valid_stmt(const string& query) = 0;
    virtual bool mark_all_valid_node(vector<IR *> &v_ir_collector) = 0;
    virtual string remove_valid_stmts_from_str(string query) = 0;
    virtual void rewrite_valid_stmt_from_ori(string& ori, string& rew_1, string& rew_2) = 0;
    virtual int compare_results(const vector<string>& result_1, const vector<string>& result_2, const vector<string>& result_3) = 0;
    void set_mutator(Mutator* mutator);
    bool mark_node_valid(IR *root);
protected:
    Mutator* g_mutator;
};



#endif