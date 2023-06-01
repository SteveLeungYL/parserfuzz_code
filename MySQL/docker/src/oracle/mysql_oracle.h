#ifndef __MYSQL_ORACLE_H__
#define __MYSQL_ORACLE_H__

#include "../include/ast.h"
#include "../include/mutate.h"
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
  virtual int count_oracle_select_stmts(IR* ir_root);
  virtual int count_oracle_normal_stmts(IR* ir_root);
  virtual bool is_oracle_select_stmt(IR* cur_IR);
  virtual bool is_oracle_normal_stmt(IR* cur_IR) {return false;}

  virtual bool is_oracle_select_stmt(string);
  virtual bool is_oracle_normal_stmt(string);

  /* Randomly add some statements into the query sets. Will append to the query
   * in a pretty early stage. Can be used to append some non-select verification
   * statements into the query set, and rewrite using
   * rewrite_valid_stmt_from_ori_2() later.
   */
  virtual string get_random_append_stmts() { return ""; }

  /* Mark all the IR node in the IR tree, that is related to teh validation
   * statement, that you do not want to mutate. */
  virtual bool mark_all_valid_node(vector<IR *> &v_ir_collector);

  virtual void remove_select_stmt_from_ir(IR* ir_root);
  virtual void remove_oracle_select_stmt_from_ir(IR* ir_root);
  virtual void remove_explain_stmt_from_ir(IR* ir_root);
  
  string remove_explain_stmt_from_str(string in);
  string remove_select_stmt_from_str(string in);
  string remove_oracle_select_stmt_from_str(string in);
  

  /* Compare the results from validation statements ori, rewrite_1 and
     rewrite_2.
      If the results are all errors, return -1, all consistent, return 1, found
     inconsistent, return 0. */
  virtual void compare_results(ALL_COMP_RES &res_out) {};

  virtual IR* get_random_mutated_select_stmt();

  /* Helper function. */
  void set_mutator(Mutator *mutator);

  virtual string get_template_select_stmts() {return "select * from v0;";}

  virtual unsigned get_mul_run_num() { return 1; }

  virtual string get_oracle_type() {return "SQL_ORACLE";};

  /* Debug */
  unsigned long total_rand_valid = 0;
  unsigned long total_temp = 0;

  /* IRWrapper related */
  /* Everytime we need to modify the IR tree, we need to call this function first. */
  virtual bool init_ir_wrapper(IR* ir_root) {IRWrapper::set_ir_root(ir_root); return true;}
  virtual bool init_ir_wrapper(vector<IR*> ir_vec) {return this->init_ir_wrapper(ir_vec.back());}

  /* Debug */
  int num_oracle_select_mutate = 0;
  int num_oracle_select_succeed = 0;

protected:
  Mutator *g_mutator = nullptr;

  virtual bool mark_node_valid(IR *root);
};

#endif
