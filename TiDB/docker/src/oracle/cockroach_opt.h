#ifndef __COCKROACH_OPT_H__
#define __COCKROACH_OPT_H__

#include "../include/ast.h"
#include "../include/define.h"
#include "./cockroach_oracle.h"

#include <string>
#include <vector>

using namespace std;

class SQL_OPT : public SQL_ORACLE {
public:
  bool mark_all_valid_node(IR * cur_stmt) override {
    return true;
  }

  void compare_results(ALL_COMP_RES &res_out) override;

  unsigned get_mul_run_num() override { return 3; }

  bool is_oracle_select_stmt(IR *cur_IR) override;

  vector<IR *> post_fix_transform_select_stmt(IR *cur_stmt,
                                              unsigned multi_run_id) override;

  string get_template_select_stmts() override {
    return "SELECT * FROM v0 WHERE v1 = 0;";
  };

  string get_oracle_type() override { return this->oracle_type; }

private:
  string oracle_type = "OPT";
};

#endif
