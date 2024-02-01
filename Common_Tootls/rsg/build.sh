# /bin/bash

bash ./clean.sh

go build -o rsg_helper.so  -buildmode=c-shared ./*.go
clang++ -g -std=c++17 -o test_binary ./test_cpp_main.cpp ./rsg_helper.so
clang++ -g -std=c++17 -o dump_parser_rules ./dump_parser_rules.cpp ./rsg_helper.so

./test_binary cockroachdb ./parser_def_files/cockroach_sql_modi.y stmt noFavNoMABNoAccNoCat
