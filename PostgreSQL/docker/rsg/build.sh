# /bin/bash

bash ./clean.sh

go build -o rsg_helper.so  -buildmode=c-shared ./main.go ./rsg.go
clang++ -std=c++17 -o test_binary ./test_cpp_main.cpp ./rsg_helper.so

./test_binary
