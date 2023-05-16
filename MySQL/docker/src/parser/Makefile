SRCS = $(wildcard *.cpp)

DEPDIR := .deps
DEPFLAGS = -MT $@ -MMD -MP -MF $(DEPDIR)/$*.d
COMPILE.c = $(CC) $(DEPFLAGS) $(CFLAGS) $(CPPFLAGS) $(TARGET_ARCH) -c -I../include

all: grammar grammar_IR_constructor $(SRCS:%.cpp=%.o)

%.o: %.cpp $(DEPDIR)/%.d | $(DEPDIR)
	$(COMPILE.c) $(OUTPUT_OPTION) $<

grammar:
	java -jar ~/antlr-4.12.0-complete.jar -Dlanguage=Cpp -no-listener -visitor -o ./grammar -package parsers MySQLLexer.g4 MySQLParser.g4

grammar_IR_constructor:
	@$(MAKE) -C $@

grammar_coverage_visitor:
	@$(MAKE) -C $@

clean:
	rm -rf *.o .deps *.gch grammar
	@make clean -C grammar_IR_constructor

$(DEPDIR): ; @mkdir -p $@

DEPFILES := $(SRCS:%.cpp=$(DEPDIR)/%.d)
$(DEPFILES):

.PHONY: grammar grammar_IR_constructor grammar_coverage_visitor

include $(wildcard $(DEPFILES))

