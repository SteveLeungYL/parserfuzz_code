
#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <string>
#include <vector>

#include <gtest/gtest.h>

#include "thr_lock.h"

#include "my_config.h"
#include "my_getopt.h"
#include "my_inttypes.h"
#include "my_sys.h"
#include "storage/temptable/include/temptable/allocator.h"
#include "unittest/gunit/test_utils.h"
#include "unittest/gunit/fake_table.h"

#include "sql/item_func.h"
#include "sql/sql_lex.h"
#include "template_utils.h"
#include "thr_lock.h"
#include "unittest/gunit/parsertest.h"
#include "unittest/gunit/test_utils.h"

using std::vector;

// We choose non-zero to avoid it working by coincidence.
int Fake_TABLE::highest_table_id = 5;

int run_parser() {
  printf("Enter parser function.\n");
  Server_initializer initializer;
  initializer.SetUp();

  const LEX_CSTRING db_name = {"db", 3};
  initializer.thd()->set_db(db_name);
  // Query_block *query_block = parse(&initializer, "SELECT * FROM t1 JOIN t2 JOIN t3", 0);
  vector<IR*> ir_vec;
  vector<IR*> ir_vec_2;
  for (int i = 0; i < 100; i++) {
    ir_vec = ::parse(&initializer, "SELECT * FROM t1 JOIN t2 JOIN t3", 0, 0);
    ir_vec_2 = ::parse(&initializer, "SELECT * FROM t1 WHERE ", 0, 0);
  }

  printf("%d \n", ir_vec.size());
  printf("%s \n", ir_vec.back()->to_string().c_str());
  printf("%s \n", ir_vec_2.back()->to_string().c_str());
  // if (query_block->is_straight_join()) {
  //   printf("Not NULL\n\n\n\n\n\n\n");
  // }

  initializer.TearDown();
  printf("Exit parser function.\n");

  return 0;
}

int main(int argc, char **argv) {
  MY_INIT(argv[0]);

  my_testing::setup_server_for_unit_tests();
  int ret = run_parser();

  my_testing::teardown_server_for_unit_tests();

  printf("Exit with status: %d.\n", ret);
  return ret;
}


// #include <gtest/gtest.h>
// #include <stddef.h>
// #include <string>
// #include <vector>

// #include "sql/item_func.h"
// #include "sql/sql_lex.h"
// #include "template_utils.h"
// #include "thr_lock.h"
// #include "unittest/gunit/parsertest.h"
// #include "unittest/gunit/test_utils.h"

// int Fake_TABLE::highest_table_id = 5;

// class IR;

// namespace join_syntax_unittest {

// using my_testing::Mock_error_handler;
// using my_testing::Server_initializer;

// class JoinSyntaxTest : public ParserTest {};

// void check_name_resolution_tables(std::initializer_list<const char *> aliases,
//                                   SQL_I_List<TABLE_LIST> tables) {
//   TABLE_LIST *table_list = tables.first;
//   for (auto alias : aliases) {
//     ASSERT_FALSE(table_list == nullptr);
//     EXPECT_STREQ(alias, table_list->alias)
//         << "Wrong table alias " << table_list->alias << ", expected " << alias
//         << ".";
//     table_list = table_list->next_name_resolution_table;
//   }
// }

// TEST_F(JoinSyntaxTest, CrossJoin) {
//   std::vector<IR*> ir_vec = ::parse(&initializer, "SELECT * FROM t1 JOIN t2 JOIN t3", 0, 0);
//   printf("\n\n\nSize: %u \n", ir_vec.size());
//   printf("ir to_string: %s. \n\n\n", ir_vec.back()->to_string().c_str());
//   // check_name_resolution_tables({"t1", "t2", "t3"}, query_block->table_list);
// }

// TEST_F(JoinSyntaxTest, CrossJoinOn) {
//   Query_block *query_block = parse("SELECT * FROM t1 JOIN t2 JOIN t3 ON 1");
//   check_name_resolution_tables({"t1", "t2", "t3"}, query_block->table_list);
// }

// }  // namespace join_syntax_unittest