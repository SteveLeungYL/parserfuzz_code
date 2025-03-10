Command to generate the share library file:

```bash
go build -o test.so -buildmode=c-shared ./main.go
```

Failed on one Ubuntu machine. Error:

```
/usr/bin/ld: /home/cockroach/go_projects/native/x86_64-linux-gnu/proj/lib/libproj.a(pj_log.c.o): relocation R_X86_64_PC32 against symbol `stderr@@GLIBC_2.2.5' can not be used when making a shared object; recompile with -fPIC
```

Only succeed on Mac. 

Solution for the above error. 

The problem is due to the `proj` library not compiled with `-fPIC`. To recompile the libary:

```bash
cd /home/cockroach/go_projects/native/x86_64-linux-gnu/proj/
cmake . -DCMAKE_POSITION_INDEPENDENT_CODE=ON
make clean && make -j $(nproc)
cd /home/cockroach/go_projects/src/github.com/cockroachdb/cockroach/pkg/sql/parser/parser_helper
go build -o test.so  -buildmode=c-shared ./main.go
```

To compile the shared library with demo `C++` code. 

```bash
clang++ -o test_binary ./main.cpp ./test.cpp
```
