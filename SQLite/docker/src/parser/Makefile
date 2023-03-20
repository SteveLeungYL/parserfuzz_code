LEMON?=lemon

SRCS = sqlite_lemon_parser.cpp parser_helper.cpp

all: $(SRCS:%.cpp=%.o)

sqlite_lemon_parser.cpp: sqlite_lemon_parser.y
	$(LEMON) sqlite_lemon_parser.y
	mv sqlite_lemon_parser.c sqlite_lemon_parser.cpp

clean:
	rm -rf sqlite_lemon_parser.cpp sqlite_lemon_parser.h sqlite_lemon_parser.out *.o .deps

DEPDIR := .deps
DEPFLAGS = -MT $@ -MMD -MP -MF $(DEPDIR)/$*.d

COMPILE.c = $(CC) $(DEPFLAGS) $(CFLAGS) $(CPPFLAGS) $(TARGET_ARCH) -c

%.o : %.cpp $(SRCS)  $(DEPDIR)/%.d | $(DEPDIR)
	$(COMPILE.c) $(OUTPUT_OPTION) $<

$(DEPDIR): ; @mkdir -p $@

DEPFILES := $(SRCS:%.cpp=$(DEPDIR)/%.d)
$(DEPFILES):

include $(wildcard $(DEPFILES))
