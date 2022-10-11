#!/bin/bash -e

# This file is used for start the SQLRight MariaDB fuzzing inside the Docker env.
# entrypoint: bash

chown -R mariadb:mariadb /home/mysql/fuzzing

SCRIPT_EXEC=$(cat << EOF
# Setup data folder
cd /home/mariadb/fuzzing/Bug_Analysis

mkdir -p bug_samples

cd /home/mariadb/fuzzing/fuzz_root/

cp /home/mariadb/src/afl-fuzz ./

printf "\n\n\n\nStart fuzzing. \n\n\n\n\n"

python3 run_parallel.py -o /home/mariadb/fuzzing/fuzz_root/outputs $@ &

sleep 60

while :
do
    python3 mysql_rebooter.py > /dev/null
    sleep 60
done

EOF
)

su -c "$SCRIPT_EXEC" mariadb

echo "Finished\n"
