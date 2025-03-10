#ifndef __COCKROACH_ORACLE_H__
#define __COCKROACH_ORACLE_H__

#include "../include/ast.h"
#include "../include/define.h"
#include "../include/ir_wrapper.h"
#include "../include/mutate.h"
#include "../include/utils.h"

#include <string>
#include <vector>

using namespace std;

class Mutator;

enum SemanticErrorType {
  ColumnTypeRelatedError = 0,
  AliasRelatedError,
  SyntaxRelatedError,
  OtherUndefinedError,
  NoSemanticError
};

struct Binary_Operator {
  public:
  DATAAFFINITYTYPE ret, left, right;
  Binary_Operator(DATAAFFINITYTYPE ret, DATAAFFINITYTYPE left, DATAAFFINITYTYPE right)
      : ret(ret)
      , left(left)
      , right(right)
  {
  }

  Binary_Operator(const Binary_Operator& in)
      : ret(in.ret)
      , left(in.left)
      , right(in.right)
  {
  }
};

class SQL_ORACLE {
  public:
  /* Functions to check and count how many query validation statements are in
   * the string. */
  virtual int count_oracle_select_stmts(IR* ir_root);
  virtual int count_oracle_normal_stmts(IR* ir_root);
  virtual bool is_oracle_select_stmt(IR* cur_IR);
  virtual bool is_oracle_normal_stmt(IR* cur_IR) { return false; }

  virtual bool is_oracle_select_stmt(string);
  virtual bool is_oracle_normal_stmt(string);

  /* Randomly add some statements into the query sets. Will append to the query
   * in a pretty early stage. Can be used to append some non-select verification
   * statements into the query set, and rewrite using
   * rewrite_valid_stmt_from_ori_2() later.
   */
  virtual int get_random_append_stmts_num() { return 0; }
  virtual IR* get_random_append_stmts(Mutator& g_mutate)
  {
    assert(!this->get_random_append_stmts_num());
    return NULL;
  }

  /* Mark all the IR node in the IR tree, that is related to the validation
   * statement, that you do not want to mutate. */
  virtual bool mark_all_valid_node(IR* ir_root) = 0;

  virtual void remove_select_stmt_from_ir(IR* ir_root);
  virtual void remove_set_stmt_from_ir(IR* ir_root);
  virtual void remove_oracle_select_stmt_from_ir(IR* ir_root);
  string remove_select_stmt_from_str(string in);
  string remove_oracle_select_stmt_from_str(string in);

  /* Compare the results from validation statements ori, rewrite_1 and
     rewrite_2.
      If the results are all errors, return -1, all consistent, return 1, found
     inconsistent, return 0. */
  virtual void compare_results(ALL_COMP_RES& res_out) = 0;

  virtual IR* get_random_mutated_select_stmt();

  /* Helper function. */
  void set_mutator(Mutator* mutator);

  virtual string get_template_select_stmts() = 0;

  virtual unsigned get_mul_run_num() { return 1; }

  virtual string get_oracle_type() = 0;

  /*
  ** Transformation function for select statements. pre_fix_* functions work
  *before concret value has been filled in to the
  ** query. post_fix_* functions work after concret value filled into the query.
  *(before/after Mutator::build_dependency_graph() and
  ** Mutator::fix())
  ** If no transform is necessary, return empty vector.
  */
  virtual IR* pre_fix_transform_select_stmt(IR* cur_stmt) { return cur_stmt->deep_copy(); }
  virtual vector<IR*> post_fix_transform_select_stmt(IR* cur_stmt,
      unsigned multi_run_id)
  {
    vector<IR*> tmp { cur_stmt->deep_copy() };
    return tmp;
  }
  virtual vector<IR*> post_fix_transform_select_stmt(IR* cur_stmt)
  {
    return this->post_fix_transform_select_stmt(cur_stmt, 0);
  }

  /*
  ** Transformation function for normal (non-select) statements. pre_fix_*
  *functions work before concret value has been filled in to the
  ** query. post_fix_* functions work after concret value filled into the query.
  *(before/after Mutator::build_dependency_graph() and
  ** Mutator::fix())
  ** If no transform is necessary, return empty vector.
  */
  virtual IR* pre_fix_transform_normal_stmt(IR* cur_stmt)
  {
    return nullptr;
  } // non-select stmt pre_fix transformation.
  virtual vector<IR*> post_fix_transform_normal_stmt(IR* cur_stmt,
      unsigned multi_run_id)
  {
    vector<IR*> tmp { cur_stmt->deep_copy() };
    return tmp;
  } // non-select
  virtual vector<IR*> post_fix_transform_normal_stmt(IR* cur_stmt)
  {
    return this->post_fix_transform_normal_stmt(cur_stmt, 0);
  } // non-select

  /* Debug */
  unsigned long total_rand_valid = 0;
  unsigned long total_temp = 0;

  /* IRWrapper related */
  /* Everytime we need to modify the IR tree, we need to call this function
   * first. */
  virtual bool init_ir_wrapper(IR* ir_root)
  {
    this->ir_wrapper.set_ir_root(ir_root);
    return true;
  }
  virtual bool init_ir_wrapper(vector<IR*> ir_vec)
  {
    return this->init_ir_wrapper(ir_vec.back());
  }
  IRWrapper ir_wrapper;

  /* Debug */
  int num_oracle_select_mutate = 0;
  int num_oracle_select_succeed = 0;

  virtual int is_res_str_error(string in_ret)
  {
#define ff(x) findStringIn(in_ret, x)
    if (ff("Error: ")) {
      return 1;
    } else {
      return 0;
    }
#undef ff
  };

  virtual int is_res_str_internal_error(string in_ret)
  {
#define ff(x) findStringIn(in_ret, x)
    if (
        ff("Internal Error")) {
      return 1;
    } else {
      return 0;
    }
#undef ff
  }

  virtual int is_sql_str_transaction_related(string in_ret)
  {
#define ff(x) findStringIn(in_ret, x)
    if (
        ff("BEGIN") || ff("TRANSACTION") || ff("ROLLBACK") || ff("SAVEPOINT")) {
      return 1;
    } else {
      return 0;
    }
#undef ff
  }

  virtual SemanticErrorType detect_semantic_error_type(string in_str);

  virtual bool is_expr_types_in_where_clause(IRTYPE in);

  virtual void init_operator_supported_types();

  virtual vector<Binary_Operator> get_operator_supported_types(string in) { return this->operator_supported_types_lib[in]; }

  protected:
  Mutator* g_mutator;

  virtual bool mark_node_valid(IR* root);

  map<string, vector<Binary_Operator>> operator_supported_types_lib;
};

#define ALLEXPRTYPESINWHERE \
  case TypeBetweenExpr:         \
  case TypeBinaryOperationExpr: \
  case TypeCaseExpr:            \
  case TypeColumnNameExpr:      \
  case TypeTableNameExpr:       \
  case TypeCompareSubqueryExpr: \
  case TypeDefaultExpr:         \
  case TypeExistsSubqueryExpr:   \
  case TypeIsNullExpr:          \
  case TypeIsTruthExpr:         \
  case TypeParenthesesExpr:     \
  case TypePatternInExpr:       \
  case TypePatternLikeExpr:     \
  case TypePatternRegexpExpr:   \
  case TypePositionExpr:        \
  case TypeRowExpr:             \
  case TypeSubqueryExpr:        \
  case TypeUnaryOperationExpr:  \
  case TypeValuesExpr:          \
  case TypeVariableExpr:        \
  case TypeMatchAgainst:        \
  case TypeSetCollationExpr:    \
    // End of this list

#endif
