#ifndef __SQLITE_NOREC_H__
#define __SQLITE_NOREC_H__

#include "../include/ast.h"
#include "../include/define.h"
#include "./sqlite_oracle.h"

#include <string>
#include <vector>

using namespace std;

class SQL_NOREC: public SQL_ORACLE {
public:
    void append_ori_valid_stmts(string query_str, int valid_max_num) override;
    
    int count_valid_stmts(const string& input) override;
    bool is_oracle_valid_stmt(const string& query) override;
    bool mark_all_valid_node(vector<IR *> &v_ir_collector) override;
    string remove_valid_stmts_from_str(string query) override;
    int compare_results(const vector<string>& result_1, const vector<string>& result_2, const vector<string>& result_3) override;
    void rewrite_valid_stmt_from_ori(string& ori, string& rew_1, string& rew_2) override;
};



#endif