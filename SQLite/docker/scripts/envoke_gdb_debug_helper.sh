#!/bin/bash

SCRIPT_EXEC=$(cat << EOF

export AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1
export AFL_SKIP_CPUFREQ=1

cd /home/sqlite/fuzzing/fuzz_root/outputs/outputs_$1/

gdb -ex=r --args ./afl-fuzz -i ./inputs -o /home/sqlite/fuzzing/fuzz_root/outputs/outputs_$1 -c $1 -O OPT  --  /home/sqlite/sqlite/sqlite3

EOF
)

echo ""
echo "Begin Fuzzing with core $1"
su -c "$SCRIPT_EXEC" sqlite
echo "Finished"
echo ""



