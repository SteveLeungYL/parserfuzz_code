#ifndef __POSTGRE_TLP_H__
#define __POSTGRE_TLP_H__

#include "../include/ast.h"
#include "../include/define.h"
#include "./postgres_oracle.h"

#include <string>
#include <vector>

using namespace std;

enum class VALID_STMT_TYPE_TLP { UNIQ, NORM };

class SQL_TLP : public SQL_ORACLE {
public:
  bool mark_all_valid_node(vector<IR *> &v_ir_collector) override;
  void compare_results(ALL_COMP_RES &res_out) override;

  bool is_oracle_select_stmt(IR* cur_IR) override;

  vector<IR*> post_fix_transform_select_stmt(IR* cur_stmt, unsigned multi_run_id) override;

  string get_template_select_stmts() override { return temp_valid_stmts; };

  string get_oracle_type() override { return this->oracle_type; }



private:

//   string temp_valid_stmts = "SELECT COUNT ( * ) FROM x WHERE x;";
// Postgres need to generate 
  string temp_valid_stmts = "SELECT * FROM x WHERE x;";

  string oracle_type = "TLP";
  string post_fix_temp_UNION_ALL = "SELECT * FROM x WHERE (x=0) UNION ALL SELECT * FROM x WHERE (NOT (x=0)) UNION ALL SELECT * FROM x WHERE ((x=0) IS NULL);" ;
  string post_fix_temp_UNION = "SELECT * FROM x WHERE x=0 UNION SELECT * FROM x WHERE (NOT (x=0)) UNION SELECT * FROM x WHERE ((x=0) IS NULL);" ;
  // string post_fix_temp = "SELECT SUM(countt) FROM ( SELECT ALL( true ) :: INT as countt FROM v2 ORDER BY ( v1 ) ) as ress;" ;

  VALID_STMT_TYPE_TLP get_valid_type(const string &cur_stmt_str);
  void get_v_valid_type(const string &cmd_str,
                               vector<VALID_STMT_TYPE_TLP> &v_valid_type);
};

#endif
