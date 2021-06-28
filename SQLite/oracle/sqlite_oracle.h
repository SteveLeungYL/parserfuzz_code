#ifndef __SQLITE_ORACLE_H__
#define __SQLITE_ORACLE_H__

#include "../include/ast.h"
#include "../include/define.h"
#include "../include/mutator.h"
#include "../include/utils.h"
#include "../include/ir_wrapper.h"

#include <string>
#include <vector>

using namespace std;

class Mutator;

class SQL_ORACLE {
public:
  /* Functions to check and count how many query validation statements are in
   * the string. */
  virtual int count_valid_stmts(const string &input) = 0;
  virtual bool is_oracle_valid_stmt(const string &query) = 0;

  virtual int count_oracle_select_stmts(IR* ir_root);
  virtual int count_oracle_normal_stmts(IR* ir_root) {return 0;}
  virtual bool is_oracle_select_stmt(IR* cur_IR) {return false;}
  virtual bool is_oracle_normal_stmt(IR* cur_IR) {return false;}

  /* Used to detect non-select query that needs some rewrite. */
  virtual bool is_oracle_valid_stmt_2(const string &query) { return false; }
  virtual bool is_oracle_normal_stmt_2(IR* cur_IR) {return false;}

  /* Randomly add some statements into the query sets. Will append to the query
   * in a pretty early stage. Can be used to append some non-select verification
   * statements into the query set, and rewrite using
   * rewrite_valid_stmt_from_ori_2() later.
   */
  virtual string get_random_append_stmts() { return ""; }
  virtual IR* get_random_append_stmts_ir() {return nullptr;}

  /* Mark all the IR node in the IR tree, that is related to teh validation
   * statement, that you do not want to mutate. */
  virtual bool mark_all_valid_node(vector<IR *> &v_ir_collector) = 0;

  virtual string remove_valid_stmts_from_str(string query) = 0;
  virtual void remove_oracle_select_stmts_from_ir(IR* ir_root);
  virtual void remove_oracle_normal_stmts_from_ir(IR* ir_root);

  /* Given the validation SELECT statement ori, rewrite the ori to validation
   * statement to rewrite_1 and rewrite_2. */
  virtual void rewrite_valid_stmt_from_ori(string &ori, string &rew_1,
                                           string &rew_2, string &rew_3,
                                           unsigned multi_run_id) = 0;
  virtual void rewrite_valid_stmt_from_ori(string &ori, string &rew_1,
                                           string &rew_2, string &rew_3) {
    this->rewrite_valid_stmt_from_ori(ori, rew_1, rew_2, rew_3, 0);
  }

  virtual vector<IR*> transform_select_stmt(IR* ir_root, unsigned multi_run_id) = 0;
  virtual vector<IR*> transform_select_stmt(IR* ir_root) {return this->transform_select_stmt(ir_root, 0);}

  /* Given the validation NON-SELECT statement ori, rewrite the ori to
   * validation statement to rewrite_1 and rewrite_2. */
  virtual void rewrite_valid_stmt_from_ori_2(string &query,
                                             const unsigned multi_run_id) {
    return;
  }
  virtual void rewrite_valid_stmt_from_ori_2(string &query) {
    this->rewrite_valid_stmt_from_ori_2(query, 0);
  }

  virtual vector<IR*> transform_normal_stmt(IR* ir_root, unsigned multi_run_id) {vector<IR*> tmp {ir_root}; return tmp;} //non-select
  virtual vector<IR*> transform_normal_stmt(IR* ir_root) {return this->transform_normal_stmt(ir_root, 0);} //non-select

  /* Compare the results from validation statements ori, rewrite_1 and
     rewrite_2.
      If the results are all errors, return -1, all consistent, return 1, found
     inconsistent, return 0. */
  virtual void compare_results(ALL_COMP_RES &res_out) = 0;

  virtual IR* get_random_mutated_valid_stmt();

  /* Helper function. */
  void set_mutator(Mutator *mutator);

  virtual string get_temp_valid_stmts() = 0;

  virtual unsigned get_mul_run_num() { return 1; }

  virtual string get_oracle_type() = 0;

  /* Debug */
  unsigned long total_rand_valid = 0;
  unsigned long total_temp = 0;

  /* IRWrapper related */
  /* Everytime we need to modify the IR tree, we need to call this function first. */
  virtual bool init_ir_wrapper(IR* ir_root) {this->ir_wrapper.set_ir_root(ir_root); return true;}
  virtual bool init_ir_wrapper(vector<IR*> ir_vec) {return this->init_ir_wrapper(ir_vec.back());}

  IRWrapper ir_wrapper; // Make it public, so that afl-fuzz.cpp can also call its function. 

protected:
  Mutator *g_mutator;

  virtual bool mark_node_valid(IR *root);
};

#endif