#include <stdio.h>
#include <stdlib.h>

int main(int argc, char * argv[]) {

  FILE * file = fopen("hello", "r");

  char buf[1024];

  fread(buf, 1, 4, file);

  if (buf[0] == 'a') fprintf(stderr, "buf[0] == 'a'\n");
  else
    fprintf(stderr, "buf[0] == other\n");

  fread(buf, 1, 4, file);

  if (buf[0] == 'a') fprintf(stderr, "buf[0] == 'a'\n");
  else
    fprintf(stderr, "buf[0] == other\n");

  return 0;
}
