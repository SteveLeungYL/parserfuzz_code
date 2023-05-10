SRCS := *.cpp grammar/*.cpp

CFLAGS := -I/usr/local/include/antlr4-runtime -std=c++17 -pthread
LINKER_FLAGS := -L/usr/local/lib/ -lantlr4-runtime -lpthread

all: MySQLLexer.cpp
	g++ $(SRCS) $(CFLAGS) -o test $(LINKER_FLAGS)

MySQLLexer.cpp:
	java -jar ~/antlr-4.12.0-complete.jar -Dlanguage=Cpp -no-listener -visitor -o ./grammar -package parsers MySQLLexer.g4 MySQLParser.g4

clean:
	rm -rf grammar test

