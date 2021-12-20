
#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <string>
#include <vector>

#include <gtest/gtest.h>

#include "thr_lock.h"

#include "parser_entry.h"

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
using std::string;

// We choose non-zero to avoid it working by coincidence.
int Fake_TABLE::highest_table_id = 5;

int run_parser(string cmd_str, vector<IR*>& ir_vec) {

  printf("Enter parser function.\n");
  Server_initializer initializer;
  initializer.SetUp();

  const LEX_CSTRING db_name = {"db", 4};
  initializer.thd()->set_db(db_name);

  ir_vec = ::parse(&initializer, cmd_str.c_str(), 0, 0);

  printf("%d \n", ir_vec.size());

  initializer.TearDown();
  printf("Exit parser function.\n");
  return 0;
}

void parser_init(const char* program_name) {
  MY_INIT(program_name);

  my_testing::setup_server_for_unit_tests();
}

void parser_teardown() {
  my_testing::teardown_server_for_unit_tests();
}

// int main(int argc, char **argv) {
//   MY_INIT(argv[0]);

//   my_testing::setup_server_for_unit_tests();
//   int ret = run_parser();

//   my_testing::teardown_server_for_unit_tests();

//   printf("Exit with status: %d.\n", ret);
//   return ret;
// }