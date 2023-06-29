LLVM_CONFIG ?= llvm-config-6.0
CLANG_CFL    = `$(LLVM_CONFIG) --cxxflags` -fno-rtti -fpic $(CXXFLAGS) -g
CLANG_LFL    = `$(LLVM_CONFIG) --ldflags` $(LDFLAGS)

PREFIX      ?= /usr/local
HELPER_PATH  = $(PREFIX)/lib/afl
BIN_PATH     = $(PREFIX)/bin


CC = clang
CFLAGS      ?= -O3 -funroll-loops
CFLAGS      += -Wall -D_FORTIFY_SOURCE=2 -g -Wno-pointer-sign \
               -DAFL_PATH=\"$(HELPER_PATH)\" -DBIN_PATH=\"$(BIN_PATH)\"

all: ParserDataflow.so runtime.o afl-clang-dfsan

ParserDataflow.so: ParserDataflow.cpp ParserDataflow.h
	$(CXX) $(CLANG_CFL) -shared $< -o $@ $(CLANG_LFL)

runtime.o: runtime.c
	$(CC) $(CFLAGS) -fsanitize=dataflow -fPIC -c $< -o $@

afl-clang-dfsan: afl-clang-dfsan.c runtime.o
	$(CC) $(CFLAGS) $< -o $@ $(LDFLAGS)
	ln -sf afl-clang-dfsan afl-clang-dfsan++

clean:
	rm -rf ParserDataflow.so runtime.o afl-clang-dfsan afl-clang-dfsan++
