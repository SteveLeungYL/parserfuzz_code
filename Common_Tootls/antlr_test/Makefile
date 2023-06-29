SRCS := *.cpp grammar/*.cpp grammar_IR_constructor/*.cpp ast/*.cpp

CFLAGS := -I/usr/local/include/antlr4-runtime -std=c++17 -pthread
LINKER_FLAGS := -L/usr/local/lib/ -lantlr4-runtime -lpthread

all: MySQLLexer.cpp CodeGenerator
	g++ $(SRCS) $(CFLAGS) -o test $(LINKER_FLAGS)

MySQLLexer.cpp:
	java -jar ~/antlr-4.12.0-complete.jar -Dlanguage=Cpp -no-listener -visitor -o ./grammar -package parsers MySQLLexer.g4 MySQLParser.g4

CodeGenerator:
	cd grammar_IR_constructor && python3 generate_all_rules_declare_header.py && python3 generate_MySQL_IR_constructor_header.py && cd ../

GrammarCovGenerator:
	cd grammar_coverage_visitor && python3 generate_grammar_cov_hash_header.py && python3 generate_MySQLGrammarCovVisitor.h.py && cd ../

clean:
	rm -rf grammar test grammar_IR_constructor/MySQL_IR_constructor.h grammar_IR_constructor/all_rule_declares.h

