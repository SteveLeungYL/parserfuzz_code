.NOTPARALLEL:

SUB_DIRS := parser oracle src AFL

LIB_SRCS := $(wildcard src/*.cpp) $(wildcard oracle/*.cpp)
COMM_OBJS := $(patsubst %.cpp,%.o,$(LIB_SRCS))
COMM_OBJS += parser/flex_lexer.cpp parser/bison_parser.cpp

AFL_OBJS := AFL/afl-fuzz.o $(COMM_OBJS)
TEST_OBJS:= AFL/test-parser.o $(COMM_OBJS)

export CC = g++
export CFLAGS = -std=c++17 -fpermissive -static-libstdc++ -g
LDFLAGS = -ldl


all: afl-fuzz #test-parser

$(SUB_DIRS):
	@$(MAKE) -C $@

afl-fuzz: $(SUB_DIRS)
	$(CC) $(CFLAGS) $(AFL_OBJS) -o $@ $(LDFLAGS)

.PHONY: all $(SUB_DIRS)

clean:
	rm -rf afl-fuzz test-parser
	cd parser && make clean && cd ..
	cd src && make clean && cd ..
	cd oracle && make clean && cd ..
	cd AFL && make clean && cd ..
