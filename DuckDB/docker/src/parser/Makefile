LEMON?=lemon

SRCS = parser_helper.cpp

all: $(SRCS:%.cpp=%.o)

clean:
	rm -rf sqlite_lemon_parser.cpp sqlite_lemon_parser.h sqlite_lemon_parser.out sqlite_lemon_parser_cov.cpp sqlite_lemon_parser_cov.h sqlite_lemon_parser_cov.out *.o .deps

DEPDIR := .deps
DEPFLAGS = -MT $@ -MMD -MP -MF $(DEPDIR)/$*.d

COMPILE.c = $(CC) $(DEPFLAGS) $(CFLAGS) $(CPPFLAGS) $(TARGET_ARCH) -c

%.o : %.cpp $(SRCS)  $(DEPDIR)/%.d | $(DEPDIR)
	$(COMPILE.c) $(OUTPUT_OPTION) $<

$(DEPDIR): ; @mkdir -p $@

DEPFILES := $(SRCS:%.cpp=$(DEPDIR)/%.d)
$(DEPFILES):

include $(wildcard $(DEPFILES))
