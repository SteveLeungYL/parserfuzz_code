#define _GNU_SOURCE
#include <dlfcn.h>

#include <sanitizer/dfsan_interface.h>
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>

#define BE_QUIET_ENV "BE_QUIET"
// TODO: 
static int be_quiet = 0;

__attribute__((constructor(0))) void __afl_auto_init(void) {
  be_quiet = !!getenv(BE_QUIET_ENV);
  // fprintf(stderr, "be_quiet: %d\n", be_quiet);
}

void get_label_origin(dfsan_label label) {

  const struct dfsan_label_info * info = dfsan_get_label_info(label);

  if (info->l1 != 0) {
    get_label_origin(info->l1);
    get_label_origin(info->l2);
  }

  if (info->desc && !be_quiet) fprintf(stderr, "%s ", info->desc); // print description. 
}

void check_iden_variable(char cond, char* var_name) {

  dfsan_label label = dfsan_get_label(cond);
  if (label==0) return;

  if (!be_quiet) fprintf(stderr, "For var_name: %s: ", var_name);
  get_label_origin(label);
  if (!be_quiet) fprintf(stderr, "\n\n");

}
