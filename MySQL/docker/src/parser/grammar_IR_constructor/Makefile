SRCS = $(wildcard *.cpp)

DEPDIR := .deps
DEPFLAGS = -MT $@ -MMD -MP -MF $(DEPDIR)/$*.d
COMPILE.c = $(CC) $(DEPFLAGS) $(CFLAGS) $(CPPFLAGS) $(TARGET_ARCH) -c -I ../../include/

all: GrammarIRGen $(SRCS:%.cpp=%.o)

%.o : %.cpp $(DEPDIR)/%.d | $(DEPDIR)
	$(COMPILE.c) $(OUTPUT_OPTION) $<

GrammarIRGen:
	python3 generate_all_rules_declare_header.py && python3 generate_MySQL_IR_constructor_header.py

clean:
	rm -rf MySQL_IR_constructor.h

$(DEPDIR): ; @mkdir -p $@

DEPFILES := $(SRCS:%.cpp=$(DEPDIR)/%.d)
$(DEPFILES):

include $(wildcard $(DEPFILES))
