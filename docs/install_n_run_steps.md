# Installation and Run Instructions

## Prerequisite

1. Install Docker on your host machine. 

## Built Steps

1. Compile the docker image. 

It is OK to compile ParserFuzz for one DBMS only, and only test that DBMS. 

```bash
cd <DB_Name>/scripts
bash setup_<DB_Name>.sh

# SQLite
cd SQLite/scripts
bash setup_sqlite.sh

# MySQL 
cd MySQL/scripts
bash setup_mysql.sh

# MariaDB 
cd MariaDB/scripts
bash setup_mariadb.sh

# CockroachDB 
cd CockroachDB/scripts
bash setup_cockroach.sh

# TiDB
cd TiDB/scripts
bash setup_tidb.sh
```

2. Launch the Docker container and run the fuzzing. 

- For `run_parallel.py` script:
    - `-c` accepts CPU ID that ParserFuzz will attach to. CPU ID starts from 0. 
    - `-n` indicates number of parallel ParserFuzz instances (independent with each other). The ParserFuzz process starts from `-c` CPU ID, and extends to CPU ID `<START_CPU_ID> + <INSTANCES_NUM> - 1`.
    - `python3 run_parallel.py -c 0 -n 8` runs 8 ParserFuzz instances, attached to core `0-7`. 
    
---------------------------

- SQLite
```bash
# Launch SQLite fuzzing container. 
sudo docker run -it --rm --name sqlite_parserfuzz_testing  parserfuzz_sqlite /bin/bash
# inside container. 
su sqlite # Do not use root priviliege. 
python3 run_parallel -c <attach_cpu_core_id> -n <num_of_concurrent_process>
```

---------------------------

- MySQL 
```bash
# Launch MySQL fuzzing container. 
sudo docker run -it --rm --name mysql_parserfuzz_testing  parserfuzz_mysql /bin/bash
su mysql # Do not use root priviliege. 
python3 run_parallel -c <attach_cpu_core_id> -n <num_of_concurrent_process>
```

---------------------------

- MariaDB 
```bash
# Launch MariaDB fuzzing container. 
sudo docker run -it --rm --name mariadb_parserfuzz_testing  parserfuzz_mariadb /bin/bash
su mysql # Do not use root priviliege. We use mysql as account name instead of mariadb. 
python3 run_parallel -c <attach_cpu_core_id> -n <num_of_concurrent_process>
```

---------------------------

- CockroachDB
```bash
# Launch CockroachDB fuzzing container. 
sudo docker run -it --rm --name cockroach_parserfuzz_testing  parserfuzz_cockroach /bin/bash
su mysql # Do not use root priviliege.
python3 run_parallel -c <attach_cpu_core_id> -n <num_of_concurrent_process>
```

---------------------------

- TiDB
```bash
# Launch TiDB fuzzing container. 
sudo docker run -it --rm --name tidb_parserfuzz_testing  parserfuzz_tidb /bin/bash
su mysql # Do not use root priviliege.
python3 run_parallel -c <attach_cpu_core_id> -n <num_of_concurrent_process>
```