#!/bin/bash -e

# This file is used for start the SQLRight MySQL fuzzing inside the Docker env.
# entrypoint: bash

chown -R sqlite:sqlite /home/sqlite/bisecting
chown -R sqlite:sqlite /home/sqlite/sqlite_bisecting_binary

SCRIPT_EXEC=$(cat << EOF

cd /home/sqlite/sqlite_bisecting_binary

git pull origin master

cd /home/sqlite/

python3 bisecting $@

EOF
)

su -c "$SCRIPT_EXEC" sqlite

echo "Finished\n"
