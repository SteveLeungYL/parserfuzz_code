# /bin/bash

bash ./clean.sh

go build -o rsg.so  -buildmode=c-shared ./main.go ./rsg.go
clang++ -std=c++17 -o test_binary ./test_cpp_main.cpp ./rsg.so

./test_binary
