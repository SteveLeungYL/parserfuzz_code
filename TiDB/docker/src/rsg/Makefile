SRCS = rsg.cpp

all: $(SRCS:%.cpp=%.o)

clean:
	rm -rf *.output *.o .deps *.gch

# Tests if the parser builds correctly and doesn't contain conflicts.

DEPDIR := .deps
DEPFLAGS = -MT $@ -MMD -MP -MF $(DEPDIR)/$*.d

COMPILE.c = $(CXX) $(DEPFLAGS) $(CFLAGS) $(CPPFLAGS) $(TARGET_ARCH) -std=c++17 -c -fPIC

%.o : %.cpp $(SRCS)  $(DEPDIR)/%.d | $(DEPDIR)
	$(COMPILE.c) $(OUTPUT_OPTION) $<

$(DEPDIR): ; @mkdir -p $@

DEPFILES := $(SRCS:%.cpp=$(DEPDIR)/%.d)
$(DEPFILES):

include $(wildcard $(DEPFILES))
