# SQLRight

<!-- <a href="https://arxiv.org/pdf/2006.02398.pdf"><img src="https://huhong789.github.io/images/squirrel.png" align="right" width="250"></a> -->

`SQLRight` is a fuzzer that aims at finding logical bugs in database managment systems (DBMSs). It is built on [AFL](https://github.com/google/AFL). 
<!-- More details can be found in our [CCS 2020 paper](http://arxiv.org/abs/2006.02398). And the bugs found by `Squirrel` can be found in [here](https://github.com/s3team/Squirrel/wiki/Bug-List). -->

Currently supported DBMSs:
1. SQLite
2. PostgreSQL
3. MySQL

## Build Instruction

Currently we test `SQLRight` on `Ubuntu 20.04 LTS`.

1. `Prerequisites`:
    ```
    sudo apt-get -y update && apt-get -y upgrade
    sudo apt-get -y install gdb bison flex git make cmake build-essential gcc-multilib g++-multilib xinetd libreadline-dev zlib1g-dev
    sudo apt-get -y install clang libssl-dev libncurses5-dev nlohmann-json3-dev libxml2-dev libxslt-dev libssl-dev libxml2-utils xsltproc
    sudo apt-get -y install libreadline-dev
    
    # Compile AFL, which is used for instrumenting the DBMSs
    cd ~
    git clone https://github.com/google/AFL.git
    cd AFL
    sed -i  's/#define MAP_SIZE_POW2       16/#define MAP_SIZE_POW2       18/' config.h
    make
    cd llvm_mode/
    make
    ```

2. `DBMS-specific requirements:` Headers and libary of `MySQL` and `PostgreSQL` if you want to test them. The most direct way is to compile the DBMSs.

3. `Compile Squirrel:`
    
    ```
    git clone 
    cd Squirrel/DBNAME/AFL
    make afl-fuzz # You need to set the path in the Makefile
    ```
    
4. `Instrument DBMS:`
    ```
    # SQLite:
    git clone https://github.com/sqlite/sqlite.git
    cd sqlite
    mkdir -p bld/$(git rev-parse HEAD)
    cd bld/$(git rev-parse HEAD)
    CC=/path/to/afl-gcc CXX=/path/to/afl-g++ ../../configure # You can also turn on debug flag if you want to find assertion
    make
   
    # MySQL/PostgreSQL/MariaDB
    cd Squirrel/DBNAME/docker/
    sudo docker build -t IMAGE_ID . 
   ```

## Run

```
# SQLite:
cd Squirrel/SQLite
mkdir -p Bug_Analysis/bug_samples
# Edit the `./Bug_Analysis/bi_config/bisecting_sqlite_config.py`
# then replace the following variables with your local path.
# 	SQLITE_DIR = /path/to/sqlite
# 	SQUIRREL_SQLITE_DIR = /path/to/Squirrel/SQLite
# 	SQLITE_MASTER_COMMIT_ID = [SQLITE MASTER COMMIT ID]
make
pip3 install -r requirements.txt
python3 ./Bug_Analysis [ORACLE]

# Run a single AFL instance. 
./afl-fuzz -i inputs -o output -- /path/to/sqlite3

# Postgres

# MySQL
docker run -it IMAGE_ID bash
cd /home/mysql/fuzzing/fuzz_root
tmux new -s fuzz
tmux rename-window sqlright
tmux new-window -n mysql-rebooter
tmux select-window -t sqlright
python3 run_parallel.py # Wait for a few seconds. 
# Use Ctrl-b + n to switch to the mysql-rebooter window. 
watch -d -n 20 python3 mysql_rebooter.py
# Use Ctrl-b + d to detach from tmux session. 
```


<!-- ## Publications

```
SQUIRREL: Testing Database Management Systems with Language Validity and Coverage Feedback

@inproceedings{zhong:squirrel,
  title        = {{SQUIRREL: Testing Database Management Systems with Language Validity and Coverage Feedback}},
  author       = {Rui Zhong and Yongheng Chen and Hong Hu and Hangfan Zhang and Wenke Lee and Dinghao Wu},
  booktitle    = {Proceedings of the 27th ACM Conference on Computer and Communications Security (CCS)},
  month        = nov,
  year         = 2020,
  address      = {Orlando, USA},
}
``` -->
