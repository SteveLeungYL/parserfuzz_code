# /bin/bash

rm test.h test.so parser_helper.h parser_helper.so test_binary &> /dev/null

go build -o parser_helper.so  -buildmode=c-shared ./main.go
clang++ -std=c++17 -o test_binary ./test_cpp_main.cpp ./parser_helper.so

./test_binary
