#!/bin/bash

SCRIPT_EXEC=$(cat << EOF

export AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1
export AFL_SKIP_CPUFREQ=1

cd /home/cockroach/fuzzing/fuzz_root/outputs/outputs_$1/

gdb -ex=r --args ./afl-fuzz -t 2000 -m 8000 -P 700$1 -i ./inputs -o ./ -c $1 -O OPT aaa

EOF
)

echo ""
echo "Begin Fuzzing with core $1"
su -c "$SCRIPT_EXEC" cockroach
echo "Finished"
echo ""


