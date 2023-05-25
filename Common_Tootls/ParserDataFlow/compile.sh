#!/bin/bash

set -xe

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PASS_FLAGS="-Xclang -load -Xclang "$SCRIPT_DIR"/ParserDataflow.so"
DF_FLAGS="-fsanitize=dataflow"
EMIT_LL="-emit-llvm -S"

clang++-6.0 $PASS_FLAGS $DF_FLAGS $SCRIPT_DIR/runtime.cpp $@
