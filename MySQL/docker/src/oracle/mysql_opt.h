#ifndef MYSQL_OPT_H_
#define MYSQL_OPT_H_

#include "../include/ast.h"
#include "sql/sql_ir_define.h"
#include "./mysql_oracle.h"

#include <string>
#include <vector>

using namespace std;

class SQL_OPT: public SQL_ORACLE {
public:
  void compare_results(ALL_COMP_RES &res_out) override;

  unsigned get_mul_run_num() override { return 3; }

  bool is_oracle_select_stmt(IR* cur_IR) override;

  vector<IR*> post_fix_transform_select_stmt(IR* cur_stmt, unsigned multi_run_id) override;

  string get_template_select_stmts() override { return temp_valid_stmts; };

  string get_oracle_type() override { return this->oracle_type; }

private:

// Postgres need to generate
  string temp_valid_stmts = "SELECT COUNT( * ) FROM x WHERE x=0;";

  string oracle_type = "OPT";

  string post_fix_temp = "SELECT COALESCE(SUM(CAST((c0)!=0 AS UNSIGNED)), 0) FROM v0 ORDER BY c0;" ;
};

#endif // MYSQL_OPT_H_
