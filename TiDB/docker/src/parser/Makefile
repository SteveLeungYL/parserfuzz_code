SRCS = parser.cpp json_ir_convertor.cpp log_gram_cov.cpp md5.cpp

all: $(SRCS:%.cpp=%.o)

clean:
	rm -rf *.output *.o .deps *.gch

# Tests if the parser builds correctly and doesn't contain conflicts.

DEPDIR := .deps
DEPFLAGS = -MT $@ -MMD -MP -MF $(DEPDIR)/$*.d

COMPILE.c = $(CXX) $(DEPFLAGS) $(CFLAGS) $(CPPFLAGS) $(TARGET_ARCH) -std=c++17 -c -fPIC

#parser.o: parser.cpp
	#g++ $< -o $@ -c -I ./include/ $(DEBUG) $(OPT)

%.o : %.cpp $(SRCS)  $(DEPDIR)/%.d | $(DEPDIR)
	$(COMPILE.c) $(OUTPUT_OPTION) $<

$(DEPDIR): ; @mkdir -p $@

DEPFILES := $(SRCS:%.cpp=$(DEPDIR)/%.d)
$(DEPFILES):

include $(wildcard $(DEPFILES))
