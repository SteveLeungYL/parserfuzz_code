SUB_DIRS := oracle src AFL

PARSER_SRCS := parser/parser_helper.o parser/sqlite_lemon_parser.o parser/sqlite_lemon_parser_cov.o
LIB_SRCS := $(wildcard src/*.cpp) $(wildcard oracle/*.cpp) $(PARSER_SRCS)
COMM_OBJS := $(patsubst %.cpp,%.o,$(LIB_SRCS))
COMM_OBJS += rsg/rsg.o
COMM_OBJS += rsg/rsg_helper.so

AFL_OBJS := AFL/afl-fuzz.o $(COMM_OBJS)
TEST_OBJS:= AFL/test-parser.o $(COMM_OBJS)
MINIMIZER_OBJS := AFL/query-minimizer.o $(COMM_OBJS)

export CC = g++
export CFLAGS = -std=c++17 -fpermissive -static-libstdc++ -g -O3 $(ASAN_FLAGS) -pthread
LDFLAGS = -ldl


all: afl-fuzz test-parser query-minimizer

parser:
	@$(MAKE) -C $@

rsg:
	@$(MAKE) -C $@

$(SUB_DIRS): parser rsg
	@$(MAKE) -C $@

afl-fuzz: $(SUB_DIRS)
	$(CC) $(CFLAGS) $(AFL_OBJS) -o $@ $(LDFLAGS) -lrt
	#cp afl-fuzz ./fuzz_root

test-parser: $(SUB_DIRS)
	$(CC) $(CFLAGS) $(TEST_OBJS) -o $@ $(LDFLAGS)
	#cp test-parser ./fuzz_root

query-minimizer: $(SUB_DIRS)
	$(CC) $(CFLAGS) $(MINIMIZER_OBJS) -o $@ $(LDFLAGS) -lrt

asan: ASAN_FLAGS := -fsanitize=address
asan:
	$(MAKE) -B -e ASAN_FLAGS=-fsanitize=address

.PHONY: parser rsg $(SUB_DIRS)

clean:
	@make clean -C parser
	@make clean -C src
	@make clean -C oracle
	@make clean -C rsg 
	@make clean -C AFL
	rm -rf afl-fuzz test-parser query-minimizer
