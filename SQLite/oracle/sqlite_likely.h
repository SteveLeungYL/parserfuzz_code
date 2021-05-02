#ifndef __SQLITE_DEMO_H__
#define __SQLITE_DEMO_H__

#include "../include/ast.h"
#include "../include/define.h"
#include "./sqlite_oracle.h"

#include <string>
#include <vector>

using namespace std;

class SQL_LIKELY: public SQL_ORACLE {
public:
    void append_ori_valid_stmts(string& query_str, int valid_max_num) override;

    int count_valid_stmts(const string& input) override;
    bool is_oracle_valid_stmt(const string& query) override;
    bool mark_all_valid_node(vector<IR *> &v_ir_collector) override;
    string remove_valid_stmts_from_str(string query) override;
    void compare_results(ALL_COMP_RES& res_out) override;
    void rewrite_valid_stmt_from_ori(string& ori, string& rew_1, string& rew_2, string& rew_3) override;

    string get_temp_valid_stmts() override {return temp_valid_stmts;};
private:
    string temp_valid_stmts = "SELECT COUNT ( * ) FROM x WHERE x;";
};



#endif