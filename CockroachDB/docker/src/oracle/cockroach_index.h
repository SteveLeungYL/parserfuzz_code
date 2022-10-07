#ifndef __COCKROACH_INDEX_H__
#define __COCKROACH_INDEX_H__

#include "../include/ast.h"
#include "../include/define.h"
#include "./cockroach_oracle.h"

#include <string>
#include <vector>

using namespace std;

enum class VALID_STMT_TYPE_INDEX {
  AGGR_MIN,
  AGGR_MAX,
  AGGR_COUNT,
  AGGR_SUM,
  AGGR_AVG,
  DISTINCT,
  GROUP_BY,
  HAVING,
  NORMAL,
  TLP_UNKNOWN
};

class SQL_INDEX : public SQL_ORACLE {
public:
  bool mark_all_valid_node(vector<IR *> &v_ir_collector) override;
  void compare_results(ALL_COMP_RES &res_out) override;

  unsigned get_mul_run_num() override { return 2; };

  string get_template_select_stmts() override {
    return temp_valid_stmts[get_rand_int(temp_valid_stmts.size())];
  };

  bool is_oracle_normal_stmt(IR *cur_IR) override;

  vector<IR *> post_fix_transform_normal_stmt(IR *cur_stmt,
                                              unsigned multi_run_id) override;

  string get_oracle_type() override { return this->oracle_type; }

  int get_random_append_stmts_num() override { return 1; }
  IR *get_random_append_stmts(Mutator &) override;

private:
  // Cockroach need to generate
  const vector<string> temp_valid_stmts = {
      "SELECT * FROM x WHERE x=0;",
      "SELECT x FROM x WHERE x GROUP BY x;",
      "SELECT x FROM x WHERE x HAVING x = 0;",
      "SELECT DISTINCT x FROM x WHERE x = 0;",
      "SELECT MIN(x) FROM x WHERE x = 0;",
      "SELECT MAX(x) FROM x WHERE x = 0;",
      "SELECT SUM(x) FROM x WHERE x = 0;",
      "SELECT AVG(x) FROM x WHERE x = 0;"};

  string oracle_type = "INDEX";

  VALID_STMT_TYPE_INDEX get_stmt_INDEX_type(IR *cur_stmt);
  void get_v_valid_type(const string &cmd_str,
                        vector<VALID_STMT_TYPE_INDEX> &v_valid_type);

  /* Compare helper function */
  bool compare_norm(COMP_RES &res); /* Handle normal valid stmt: SELECT * FROM
                                     ...; Return is_err */
  bool compare_uniq(
      COMP_RES &res); /* Handle results that is unique. Count row numbers, but
                   results from the first stmt need to be unique. */
  bool compare_aggr(
      COMP_RES &res); /* Handle MIN valid stmt: SELECT MIN(*) FROM ...; */
};

#endif //__COCKROACH_INDEX_H__
