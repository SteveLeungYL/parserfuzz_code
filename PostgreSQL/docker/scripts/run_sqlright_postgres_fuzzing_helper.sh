#!/bin/bash -e

# This file is used for start the SQLRight MySQL fuzzing inside the Docker env.
# entrypoint: bash

chown -R postgres:postgres /home/postgres/fuzzing

SCRIPT_EXEC=$(cat << EOF
cd /home/postgres/fuzzing/fuzz_root

printf "\n\n\n\nStart fuzzing. \n\n\n\n\n"

python3 run_parallel.py -o /home/postgres/fuzzing/fuzz_root/outputs $@

EOF
)

su -c "$SCRIPT_EXEC" postgres

echo "Finished\n"
