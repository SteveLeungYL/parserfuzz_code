SUB_DIRS := src sampler

LIB_SRCS := $(wildcard src/*.cpp) $(wildcard oracle/*.cpp) $(PARSER_SRCS)
COMM_OBJS := $(patsubst %.cpp,%.o,$(LIB_SRCS))

DEPEN_PATH  = ../src/*.cpp

SAMPLE_POSTGRESQL_OBJS:= sampler/sample_postgresql.o $(COMM_OBJS)
SAMPLE_MYSQL_OBJS:= sampler/sample_mysql.o $(COMM_OBJS)
SAMPLE_SQLITE_OBJS:= sampler/sample_sqlite.o $(COMM_OBJS)

PGSQL_INCLUDE_PATH = /usr/local/pgsql/include
PGSQL_LIB_PATH = /usr/local/pgsql/lib

MYSQL_INCLUDE_PATH = /usr/local/mysql
MYSQL_LIB_PATH =  /usr/local/mysql/lib

export CC = g++
export DEBUG =
export OPT = -O3
export CFLAGS = -std=c++17 -fpermissive -static-libstdc++ $(DEBUG) $(OPT) $(ASAN_FLAGS)
POSTGRES_LDFLAGS = -ldl -lpq
MYSQL_LDFLAGS = -ldl -lmysqlclient -lpthread


all: sample_postgresql sample_mysql sample_sqlite

$(SUB_DIRS):
	@$(MAKE) -C $@

sample_sqlite: $(SUB_DIRS)
	$(CC) $(CFLAGS) $(SAMPLE_SQLITE_OBJS) -o $@ 

sample_postgresql: $(SUB_DIRS)
	$(CC) $(CFLAGS) $(SAMPLE_POSTGRESQL_OBJS) -I$(PGSQL_INCLUDE_PATH) -L$(PGSQL_LIB_PATH) -o $@ $(POSTGRES_LDFLAGS)

sample_mysql: $(SUB_DIRS)
	$(CC) $(CFLAGS) $(SAMPLE_MYSQL_OBJS) -I$(MYSQL_INCLUDE_PATH) -L$(MYSQL_LIB_PATH) -o $@ $(MYSQL_LDFLAGS)

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
	@make clean -C src
	@make clean -C sampler
	rm -rf sample_postgresql sample_mysql
