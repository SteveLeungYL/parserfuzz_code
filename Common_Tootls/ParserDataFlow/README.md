## files

* ParserDataflow.[cpp|h]: hook all the parser identifier string values and print the adopted variables.
* Makefile: to compiler ParserDataflow.so
* runtime.c: from every store instruction, check whether the variable is related to one identifier strings.

## build

* `make` will generate ParserDataflow.so

## test

* echo "abcdefghijklm" > hello
* ./compile.sh test-fread.c
* ./a.out
