#!/bin/bash -e

# This file is used for start the SQLRight TiDB fuzzing inside the Docker env.
# entrypoint: bash

chown -R tidb:tidb /home/tidb/fuzzing

SCRIPT_EXEC=$(cat << EOF
cd /home/tidb/fuzzing/fuzz_root/

printf "\n\n\n\nStart fuzzing. \n\n\n\n\n"

python3 run_parallel.py -o ./outputs $@

EOF
)

su -c "$SCRIPT_EXEC" tidb

echo "Finished\n"
