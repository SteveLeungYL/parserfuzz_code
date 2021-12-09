
#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <string>

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

// We choose non-zero to avoid it working by coincidence.
int Fake_TABLE::highest_table_id = 5;

int run_parser() {
  printf("Enter parser function.\n");
  Server_initializer initializer;
  initializer.SetUp();

  Query_block *query_block = parse(&initializer, "SELECT * FROM t1 JOIN t2 JOIN t3", 0);

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
