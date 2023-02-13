SUB_DIRS := oracle src AFL

PARSER_SRCS := $(wildcard parser/parser.cpp)
PARSER_SRCS += $(patsubst %.y,%.cpp,$(wildcard parser/*.y))
PARSER_SRCS += $(patsubst %.l,%.cpp,$(wildcard parser/*.l))
LIB_SRCS := $(wildcard src/*.cpp) $(wildcard oracle/*.cpp) $(PARSER_SRCS)
COMM_OBJS := $(patsubst %.cpp,%.o,$(LIB_SRCS))
COMM_OBJS += rsg/rsg.o
COMM_OBJS += rsg/rsg_helper.so

DEPEN_PATH  = ../src/*.cpp  ../parser/bison_parser.cpp ../parser/flex_lexer.cpp

AFL_OBJS := AFL/afl-fuzz.o $(COMM_OBJS)
TEST_OBJS:= AFL/test-parser.o $(COMM_OBJS)
GEN_OBJS:= AFL/generate_inputs.o $(COMM_OBJS)
SAMPLE_OBJS:= AFL/sample_func_opr_data_types.o $(COMM_OBJS)

PGSQL_INCLUDE_PATH = /usr/local/pgsql/include
PGSQL_LIB_PATH = /usr/local/pgsql/lib

export CC = g++
export DEBUG =
export OPT = -O3
export CFLAGS = -std=c++17 -fpermissive -static-libstdc++ $(DEBUG) $(OPT) $(ASAN_FLAGS)
LDFLAGS = -ldl -lpq


all: afl-fuzz test-parser generate_inputs sample_func_opr_data_types

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

generate_inputs: $(SUB_DIRS)
	$(CC) $(CFLAGS) $(GEN_OBJS) -I$(PGSQL_INCLUDE_PATH) -L$(PGSQL_LIB_PATH) -o $@ $(LDFLAGS)

sample_func_opr_data_types: $(SUB_DIRS)
	$(CC) $(CFLAGS) $(SAMPLE_OBJS) -I$(PGSQL_INCLUDE_PATH) -L$(PGSQL_LIB_PATH) -o $@ $(LDFLAGS)

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
	rm -rf afl-fuzz test-parser generate_inputs sample_func_opr_data_types
