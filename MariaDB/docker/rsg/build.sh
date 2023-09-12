# /bin/bash

bash ./clean.sh

go build -o rsg_helper.so  -buildmode=c-shared ./main.go ./rsg.go
clang++ -g -std=c++17 -o test_binary ./test_cpp_main.cpp ./rsg_helper.so
clang++ -g -std=c++17 -o dump_parser_rules ./dump_parser_rules.cpp ./rsg_helper.so

