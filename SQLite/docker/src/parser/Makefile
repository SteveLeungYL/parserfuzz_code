LEMON?=lemon

#FLEX_VERSION=$(shell $(FLEX) --version | head -n 1 | grep -o '[0-9]\.[0-9]\+')
#FLEX_VERSION_SUPPORTED=$(shell echo $(FLEX_VERSION) \>= 2.6 | bc)
#ifneq ($(FLEX_VERSION_SUPPORTED), 1)
#$(error Flex version $(FLEX_VERSION) not supported. If you are using OS X, `flex` uses the system default instead of the brew version. Run FLEX=/usr/local/opt/flex/bin/flex make)
#endif
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
