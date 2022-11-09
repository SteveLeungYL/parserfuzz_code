#!/bin/bash -e

# This file is used for start the SQLRight CockroachDB fuzzing inside the Docker env.
# entrypoint: bash

chown -R cockroach:cockroach /home/cockroach/fuzzing

SCRIPT_EXEC=$(cat << EOF
cd /home/cockroach/fuzzing/fuzz_root/

printf "\n\n\n\nStart fuzzing. \n\n\n\n\n"

python3 run_parallel.py -o ./outputs $@

EOF
)

su -c "$SCRIPT_EXEC" cockroach

echo "Finished\n"
