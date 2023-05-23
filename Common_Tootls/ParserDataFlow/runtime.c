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

  if (info->desc && !be_quiet) fprintf(stderr, "%s ", info->desc);
}

static unsigned int count = 0;
//static size_t (*real_fread)(void *ptr, size_t size, size_t nmemb, FILE *stream);
size_t myfread(void *ptr, size_t size, size_t nmemb, FILE *stream, unsigned long fread_id) {

  //if (real_fread == NULL) {
  //  real_fread = dlsym(RTLD_NEXT, "fread");
  //}

  size_t res = fread(ptr, size, nmemb, stream);

  //if (!be_quiet)
  //  fprintf(stderr, "LIBHOOK_LOG fread[%p, %zu, %zu, %p] = %zu\n", 
  //      ptr, size, nmemb, stream, res);

  char *str = (char *) malloc(20);
  sprintf(str, "%ld-%d", fread_id, count++);
  dfsan_label k_label = dfsan_create_label(str, 0);
  if (!be_quiet) fprintf(stderr, "create origin: %s\n", str);
  dfsan_set_label(k_label, ptr, res * size);

  return res;
}


void check_cond_label(char cond, unsigned long branch_id) {

  dfsan_label label = dfsan_get_label(cond);
  if (label==0) return;

  if (!be_quiet) fprintf(stderr, "condition %ld: ", branch_id);
  get_label_origin(label);
  if (!be_quiet) fprintf(stderr, "\n");
}
