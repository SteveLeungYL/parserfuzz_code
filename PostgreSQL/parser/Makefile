# bison's version is too old on OSX, allow user to pass in custom path
BISON?=bison
FLEX?=flex

#BISON_VERSION=$(shell $(BISON) --version | head -n 1 | grep -o '[0-9]\.[0-9]\+')
#BISON_VERSION_SUPPORTED=$(shell echo $(BISON_VERSION) \>= 3.0 | bc)
#ifneq ($(BISON_VERSION_SUPPORTED), 1)
#$(error Bison version $(BISON_VERSION) not supported. If you are using OS X, `bison` uses the system default instead of the brew version. Run BISON=/usr/local/opt/bison/bin/bison make)
#endif

#FLEX_VERSION=$(shell $(FLEX) --version | head -n 1 | grep -o '[0-9]\.[0-9]\+')
#FLEX_VERSION_SUPPORTED=$(shell echo $(FLEX_VERSION) \>= 2.6 | bc)
#ifneq ($(FLEX_VERSION_SUPPORTED), 1)
#$(error Flex version $(FLEX_VERSION) not supported. If you are using OS X, `flex` uses the system default instead of the brew version. Run FLEX=/usr/local/opt/flex/bin/flex make)
#endif

SRCS = bison_parser.cpp flex_lexer.cpp parser.cpp

all: $(SRCS:%.cpp=%.o)

bison_parser.cpp: bison_parser_2.y
	$(BISON) bison_parser_2.y  -t --output=bison_parser.cpp --defines=bison_parser.h --verbose -Wconflicts-rr # --debug

flex_lexer.cpp: flex_lexer_2.l
	$(FLEX) flex_lexer_2.l

clean:
	rm -rf bison_parser.cpp bison_bison_2.cpp flex_lexer.cpp flex_lexer_2.cpp bison_parser.h bison_parser_2.h flex_lexer.h flex_lexer_2.h *.output *.o .deps *.gch *.h

# Tests if the parser builds correctly and doesn't contain conflicts.
test:
	! $(BISON) bison_parser.y -v --output=conflict_test.cpp 2>&1 | grep "conflict" >/tmp/2

DEPDIR := .deps
DEPFLAGS = -MT $@ -MMD -MP -MF $(DEPDIR)/$*.d

COMPILE.c = $(CC) $(DEPFLAGS) $(CFLAGS) $(CPPFLAGS) $(TARGET_ARCH) -c -I ./include/

parser.o: parser.cpp
	g++ $< -o $@ -c -I ./include/

%.o : %.cpp $(SRCS)  $(DEPDIR)/%.d | $(DEPDIR)
	$(COMPILE.c) $(OUTPUT_OPTION) $<

$(DEPDIR): ; @mkdir -p $@

DEPFILES := $(SRCS:%.cpp=$(DEPDIR)/%.d)
$(DEPFILES):

include $(wildcard $(DEPFILES))
