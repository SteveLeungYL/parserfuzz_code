#ifndef __COCKROACH_TLP_H__
#define __COCKROACH_TLP_H__

#include "../include/ast.h"
#include "../include/define.h"
#include "./cockroach_oracle.h"

#include <string>
#include <vector>

using namespace std;

enum class VALID_STMT_TYPE_TLP {
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

class SQL_TLP : public SQL_ORACLE {
public:
  bool mark_all_valid_node(IR* cur_stmt) override;
  void compare_results(ALL_COMP_RES &res_out) override;

  bool is_oracle_select_stmt(IR *cur_IR) override;

  vector<IR *> post_fix_transform_select_stmt(IR *cur_stmt,
                                              unsigned multi_run_id) override;

  string get_template_select_stmts() override {
    return temp_valid_stmts[get_rand_int(temp_valid_stmts.size())];
  };

  string get_oracle_type() override { return this->oracle_type; }

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

  string oracle_type = "TLP";

  VALID_STMT_TYPE_TLP get_stmt_TLP_type(IR *cur_stmt);
  void get_v_valid_type(const string &cmd_str,
                        vector<VALID_STMT_TYPE_TLP> &v_valid_type);

  IR *transform_non_aggr(IR *, bool, VALID_STMT_TYPE_TLP);
  IR *transform_aggr(IR *, bool, VALID_STMT_TYPE_TLP);

  /* Compare helper function */
  bool compare_norm(COMP_RES &res); /* Handle normal valid stmt: SELECT * FROM
                                       ...; Return is_err */
  bool compare_uniq(
      COMP_RES &res); /* Handle results that is unique. Count row numbers, but
                         results from the first stmt need to be unique. */
  bool compare_aggr(
      COMP_RES &res); /* Handle MIN valid stmt: SELECT MIN(*) FROM ...; */

  string trans_outer_MIN_tmp_str = "SELECT MIN(aggr) FROM (SELECT *) AS subb;";
  string trans_outer_MAX_tmp_str = "SELECT MAX(aggr) FROM (SELECT *) AS subb;";
  string trans_outer_SUM_tmp_str = "SELECT SUM(aggr) FROM (SELECT *) AS subb;";
  string trans_outer_COUNT_tmp_str =
      "SELECT COUNT(aggr) FROM (SELECT *) AS subb;";
  string trans_outer_AVG_tmp_str =
      "SELECT SUM(s)/SUM(c) FROM (SELECT *) AS subb;";
};

#endif
