#ifndef __SQLITE_ORACLE_H__
#define __SQLITE_ORACLE_H__

#include "../include/ir_wrapper.h"
#include "../include/mutator.h"
#include "../include/utils.h"

#include <string>
#include <vector>

using namespace std;

class Mutator;

class SQL_ORACLE {
public:
  /* Helper function. */
  void set_mutator(Mutator *mutator);

  inline bool is_select_stmt(IR *cur_IR) {
    if (cur_IR->type_ == kSelectStmt) {
      return true;
    } else {
      return false;
    }
  }

  virtual void remove_all_select_stmt_from_ir(IR *ir_root);
  virtual bool is_oracle_select_stmt(IR *cur_IR);

  /* Randomly add some statements into the query sets. Will append to the query
   * in a pretty early stage. Can be used to append some interesting or ORACLE
   * related non-SELECT statements into the query set.
   * For examples, can be used for randomly insert CREATE INDEX statements for
   * the INDEX oracle.
   */
  virtual int is_random_append_stmts() { return 0; }
  virtual IR *get_random_append_stmts_ir() { return nullptr; }

  /*
  ** Transformation function for select statements. pre_fix_* functions work
  *before concret value has been filled in to the
  ** query. post_fix_* functions work after concret value filled into the query.
  *(before/after validate() )
  ** If no transformation is necessary, return empty vector.
  */
  virtual IR *pre_fix_transform_select_stmt(IR *cur_stmt) { return nullptr; }
  virtual vector<IR *> post_fix_transform_select_stmt(IR *cur_stmt,
                                                      unsigned multi_run_id) {
    vector<IR *> tmp;
    return tmp;
  }
  virtual vector<IR *> post_fix_transform_select_stmt(IR *cur_stmt) {
    return this->post_fix_transform_select_stmt(cur_stmt, 0);
  }

  /*
  ** Transformation function for normal (non-select) statements. pre_fix_*
  *functions work before concret value has been filled in to the
  ** query. post_fix_* functions work after concret value filled into the query.
  *(before/after Mutator::validate() )
  ** If no transformation is necessary, return empty vector.
  */

  virtual IR *pre_fix_transform_normal_stmt(IR *cur_stmt) {
    return nullptr;
  } // non-select stmt pre_fix transformation.
  virtual vector<IR *> post_fix_transform_normal_stmt(IR *cur_stmt,
                                                      unsigned multi_run_id) {
    vector<IR *> tmp;
    return tmp;
  } // non-select
  virtual vector<IR *> post_fix_transform_normal_stmt(IR *cur_stmt) {
    return this->post_fix_transform_normal_stmt(cur_stmt, 0);
  } // non-select

  virtual unsigned get_mul_run_num() { return 1; }

  virtual string get_oracle_type() {return "";};

protected:
  Mutator *g_mutator;
};

#endif
