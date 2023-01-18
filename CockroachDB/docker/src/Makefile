SUB_DIRS := oracle src AFL

PARSER_SRCS := $(wildcard parser/*.cpp)
LIB_SRCS := $(wildcard src/*.cpp) $(wildcard oracle/*.cpp) $(PARSER_SRCS)
COMM_OBJS := $(patsubst %.cpp,%.o,$(LIB_SRCS))
COMM_OBJS += parser/parser_helper.so
COMM_OBJS += rsg/rsg.o
COMM_OBJS += rsg/rsg_helper.so

DEPEN_PATH  = ../src/*.cpp  

AFL_OBJS := AFL/afl-fuzz.o $(COMM_OBJS)
TEST_OBJS:= AFL/test-parser.o $(COMM_OBJS)
TMIN_OBJS:= AFL/afl-tmin.o $(COMM_OBJS)
GEN_OBJS:= AFL/generate_inputs.o $(COMM_OBJS)
SETTING_OBJS:= AFL/afl-setting-mutator.o $(COMM_OBJS)
UNITTEST_OBJS:= AFL/unit-test.o $(COMM_OBJS)
RSGTEST_OBJS:= AFL/rsg-unit-test.o $(COMM_OBJS)

PGSQL_INCLUDE_PATH = /usr/local/pgsql/include
PGSQL_LIB_PATH = /usr/local/pgsql/lib

export CC = g++
export DEBUG = -g
export OPT = -O3
export CFLAGS = -std=c++17 -fpermissive -static-libstdc++ $(DEBUG) $(OPT) $(ASAN_FLAGS)
LDFLAGS = -ldl


all: afl-fuzz test-parser generate_inputs afl-tmin afl-setting-mutator unit-test rsg-unit-test

parser:
	@$(MAKE) -C $@

rsg:
	@$(MAKE) -C $@

$(SUB_DIRS): parser rsg
	@$(MAKE) -C $@

afl-fuzz: $(SUB_DIRS)
	$(CC) $(CFLAGS) $(AFL_OBJS) -I$(PGSQL_INCLUDE_PATH) -L$(PGSQL_LIB_PATH) -o $@ $(LDFLAGS)

test-parser: $(SUB_DIRS)
	$(CC) $(CFLAGS) $(TEST_OBJS) -I$(PGSQL_INCLUDE_PATH) -L$(PGSQL_LIB_PATH) -o $@ $(LDFLAGS)

afl-tmin: $(SUB_DIRS)
	$(CC) $(CFLAGS) $(TMIN_OBJS) -I$(PGSQL_INCLUDE_PATH) -L$(PGSQL_LIB_PATH) -o $@ $(LDFLAGS)

generate_inputs: $(SUB_DIRS)
	$(CC) $(CFLAGS) $(GEN_OBJS) -I$(PGSQL_INCLUDE_PATH) -L$(PGSQL_LIB_PATH) -o $@ $(LDFLAGS)

afl-setting-mutator: $(SUB_DIRS)
	$(CC) $(CFLAGS) $(SETTING_OBJS) -I$(PGSQL_INCLUDE_PATH) -L$(PGSQL_LIB_PATH) -o $@ $(LDFLAGS)

unit-test: $(SUB_DIRS)
	$(CC) $(CFLAGS) $(UNITTEST_OBJS) -I$(PGSQL_INCLUDE_PATH) -L$(PGSQL_LIB_PATH) -o $@ $(LDFLAGS)

rsg-unit-test: $(SUB_DIRS)
	$(CC) $(CFLAGS) $(RSGTEST_OBJS) -I$(PGSQL_INCLUDE_PATH) -L$(PGSQL_LIB_PATH) -o $@ $(LDFLAGS)

debug: DEBUG = -g
debug: OPT = -O0
debug:
	$(MAKE) -e

asan: ASAN_FLAGS = -fsanitize=address
asan: DEBUG = -g
asan: OPT = -O0
asan:
	$(MAKE) -e

.PHONY: parser rsg $(SUB_DIRS)

clean:
	@make clean -C parser
	@make clean -C src
	@make clean -C oracle
	@make clean -C AFL
	@make clean -C rsg
	rm -rf afl-fuzz test-parser afl-tmin afl-setting-mutator generate_inputs unit-test rsg-unit-test
