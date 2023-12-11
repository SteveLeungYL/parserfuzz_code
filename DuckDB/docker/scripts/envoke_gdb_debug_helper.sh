#!/bin/bash

SCRIPT_EXEC=$(cat << EOF

export AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1
export AFL_SKIP_CPUFREQ=1

mkdir -p /home/duckdb/fuzzing/fuzz_root/outputs/
mkdir -p /home/duckdb/fuzzing/fuzz_root/outputs/outputs_$1/
cd /home/duckdb/fuzzing/fuzz_root/outputs/outputs_$1/

cp /home/duckdb/fuzzing/fuzz_root/afl-fuzz /home/duckdb/fuzzing/fuzz_root/outputs/outputs_$1/afl-fuzz
cp -r /home/duckdb/fuzzing/fuzz_root/rsg /home/duckdb/fuzzing/fuzz_root/outputs/outputs_$1/rsg
cp -r /home/duckdb/fuzzing/fuzz_root/duckdb_grammar.y /home/duckdb/fuzzing/fuzz_root/outputs/outputs_$1/duckdb_grammar.y
cp -r /home/duckdb/fuzzing/fuzz_root/inputs /home/duckdb/fuzzing/fuzz_root/outputs/outputs_$1/inputs

gdb -ex=r --args ./afl-fuzz -i ./inputs -o /home/duckdb/fuzzing/fuzz_root/outputs/outputs_$1 -c $1 -O OPT -t 2000 -m none --  /home/duckdb/duckdb/build/reldebug/duckdb

EOF
)

echo ""
echo "Begin Fuzzing with core $1"
su -c "$SCRIPT_EXEC" duckdb
echo "Finished"
echo ""



