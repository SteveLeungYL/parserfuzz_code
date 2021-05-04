#ifndef __SQLITE_ORACLE_H__
#define __SQLITE_ORACLE_H__

#include "../include/ast.h"
#include "../include/define.h"
#include "../include/utils.h"
#include "../include/mutator.h"

#include <string>
#include <vector>

using namespace std;

class Mutator;

class SQL_ORACLE {
public:
    /* Functions to check and count how many query validation statements are in the string. */
    virtual int count_valid_stmts(const string& input) = 0;
    virtual bool is_oracle_valid_stmt(const string& query) = 0;

    /* Mark all the IR node in the IR tree, that is related to teh validation statement, that you do not want to mutate. */
    virtual bool mark_all_valid_node(vector<IR *> &v_ir_collector) = 0;

    virtual string remove_valid_stmts_from_str(string query) = 0;

    /* Given the validation statement ori, rewrite the ori to validation statement to rewrite_1 and rewrite_2. */
    virtual void rewrite_valid_stmt_from_ori(string& ori, string& rew_1, string& rew_2, string& rew_3) = 0;

    /* Compare the results from validation statements ori, rewrite_1 and rewrite_2. 
        If the results are all errors, return -1, all consistent, return 1, found inconsistent, return 0. */
    virtual void compare_results(ALL_COMP_RES& res_out) = 0;

    virtual string get_random_mutated_valid_stmt();

    /* Helper function. */ 
    void set_mutator(Mutator* mutator);

    virtual string get_temp_valid_stmts() = 0;

    /* Debug */
    unsigned long total_rand_valid = 0;
    unsigned long total_temp = 0;

protected:
    Mutator* g_mutator;

    virtual bool mark_node_valid(IR *root);
};



#endif