#ifndef __SQLITE_TLP_H__
#define __SQLITE_TLP_H__

#include "../include/ast.h"
#include "../include/define.h"
#include "../include/utils.h"
#include "./sqlite_oracle.h"


#include <string>
#include <vector>

using namespace std;

enum valid_type {
    NORM,
    MIN,
    MAX,
    SUM,
    // AVG, // TODO:: Implement AVG. 
    COUNT
};

class SQL_TLP: public SQL_ORACLE {
public:
    void append_ori_valid_stmts(string& query_str, int valid_max_num) override;

    int count_valid_stmts(const string& input) override;
    bool is_oracle_valid_stmt(const string& query) override;
    bool mark_all_valid_node(vector<IR *> &v_ir_collector) override;
    string remove_valid_stmts_from_str(string query) override;
    int compare_results(const vector<string>& result_0, const vector<string>& result_1, const vector<string>& result_2, const vector<string>& result_3, const string& cmd_str) override;
    void rewrite_valid_stmt_from_ori(string& ori, string& rew_1, string& rew_2, string& rew_3) override;

    string get_temp_valid_stmts() override { return temp_valid_stmts[get_rand_int(temp_valid_stmts.size())]; }
private:
    vector<string> temp_valid_stmts = {
        "SELECT x FROM x;", 
        "SELECT x FROM WHERE x;", 
        "SELECT x FROM x WHERE x GROUP BY x;",
        // "SELECT x FROM x WHERE x HAVING x;", // TODO:: Implement HAVING. 
        "SELECT DISTINCT x FROM x WHERE x;",
        "SELECT MIN(x) FROM x WHERE x;",
        "SELECT MAX(x) FROM x WHERE x;",
        "SELECT SUM(x) FROM x WHERE x;",
        "SELECT COUNT(x) FROM x WHERE x;",
        "SELECT AVG(x) FROM x WHERE x;"
    };

    string rewrite_where_union_all(string& ori, string& rew_1, const string& bef_sel_stmt, const string& sel_stmt, const string& from_stmt, const string& where_stmt, const string& extra_stmt);
    string rewrite_where_union(string& ori, string& rew_1, const string& bef_sel_stmt, const string& sel_stmt, const string& from_stmt, const string& where_stmt, const string& extra_stmt);


// TODO: Implement HAVING stmts.
    string rewrite_having(string& ori, string& rew_1, const string& before_select_stmt, const string& select_stmt, const string& from_stmt, const string& where_stmt, const string& extra_stmt);

    void get_v_valid_type(const string& cmd_str, vector<valid_type>& v_valid_type);

};



#endif