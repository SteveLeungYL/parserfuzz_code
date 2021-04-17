#
# american fuzzy lop - makefile
# -----------------------------
#
# Written and maintained by Michal Zalewski <lcamtuf@google.com>
# 
# Copyright 2013, 2014, 2015, 2016, 2017 Google LLC All rights reserved.
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# 
#   http://www.apache.org/licenses/LICENSE-2.0
#

PROGNAME    = afl
VERSION     = $(shell grep '^\#define VERSION ' config.h | cut -d '"' -f2)

PREFIX     ?= /usr/local
BIN_PATH    = $(PREFIX)/bin
HELPER_PATH = $(PREFIX)/lib/afl
DOC_PATH    = $(PREFIX)/share/doc/afl
MISC_PATH   = $(PREFIX)/share/afl
DEPEN_PATH  = ../src/*.cpp  ../parser/bison_parser.cpp ../parser/flex_lexer.cpp

CC          = g++
CFLAGS     ?= -O3 -fpermissive --std=c++17 -static-libstdc++
ASAN_FLAG   = -fsanitize=address
CFLAGS     += -w \
	      			-DAFL_PATH=\"$(HELPER_PATH)\" -DDOC_PATH=\"$(DOC_PATH)\" \
	      			-DBIN_PATH=\"$(BIN_PATH)\"

ifneq "$(filter Linux GNU%,$(shell uname))" ""
  LDFLAGS  += -ldl
endif

COMM_HDR    = alloc-inl.h config.h debug.h types.h hash.h

all: afl-fuzz

afl-fuzz: afl-fuzz.cpp $(COMM_HDR) $(DEPEN_PATH)
	$(CC) $(CFLAGS) -g $< $(DEPEN_PATH) -o $@ $(LDFLAGS)

afl-fuzz-asan: afl-fuzz.cpp $(COMM_HDR) $(DEPEN_PATH)
	$(CC) $(CFLAGS) $(ASAN_FLAG) -g $< $(DEPEN_PATH) -o $@ $(LDFLAGS)


.NOTPARALLEL: clean

clean:
	rm -f afl-fuzz afl-fuzz-asan *.o *~ a.out core core.[1-9][0-9]* *.stackdump
