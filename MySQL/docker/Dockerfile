FROM ubuntu:20.04 AS sqlright_mysql_tools
MAINTAINER "PSU-Security-Universe"

ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN chmod 777 /tmp

RUN apt -y update
RUN apt -y upgrade
RUN apt -y update
RUN apt -y install bison
RUN apt -y install build-essential
RUN apt -y install clang
RUN apt -y install cmake
RUN apt -y install flex
RUN apt -y install gdb
RUN apt -y install git
RUN apt -y install libncurses5-dev
RUN apt -y install libreadline-dev
RUN apt -y install libssl-dev
RUN apt -y install make
RUN apt -y install pkg-config
RUN apt -y install python3
RUN apt -y install python3-pip
RUN apt -y install tmux
RUN apt -y install vim
RUN apt -y install xinetd
RUN apt -y install zlib1g-dev 
RUN apt -y install screen
RUN apt -y install watch
RUN apt -y install unzip
RUN pip install libtmux
RUN apt -y install wget

RUN apt -y install llvm
RUN apt -y install clang

RUN apt -y install g++-9
RUN apt -y install gcc-9

RUN apt -y install libnuma-dev


# Install mysql-client related libraries, for the compilation of sqlright.
RUN pip3 install psutil
RUN pip3 install mysql-connector-python mysql-connector-python
RUN apt -y install libmysqlclient-dev
RUN pip3 install mysqlclient

RUN useradd -ms /bin/bash mysql

ENV CC=clang
ENV CXX=clang++

RUN chown -R mysql:mysql /home/mysql

# build block-coverage AFL
WORKDIR /home/mysql
COPY AFL /home/mysql/AFL
RUN chown -R mysql:mysql /home/mysql

USER mysql
WORKDIR /home/mysql/AFL 
RUN AFL_NO_X86=1 make
WORKDIR /home/mysql/AFL/llvm_mode
# ENV LLVM_CONFIG=llvm-config-6.0
RUN make 

# ---------------------------------------------------------------------------------------------------------------
FROM sqlright_mysql_tools AS sqlright_mysql_source_build

# build MySQL instrumented by afl-clang-fast
USER mysql
WORKDIR /home/mysql/
RUN wget https://github.com/mysql/mysql-server/archive/refs/tags/mysql-8.0.33.zip
RUN unzip mysql-8.0.33.zip
RUN mv mysql-server-mysql-8.0.33 mysql-server
WORKDIR /home/mysql/mysql-server
# MySQL version 8.0.33
# RUN git checkout 3290a66c89eb1625a7058e0ef732432b6952b435 
RUN mkdir bld
WORKDIR /home/mysql/mysql-server/bld
ENV CC=/home/mysql/AFL/afl-clang-fast
ENV CXX=/home/mysql/AFL/afl-clang-fast++
RUN cmake .. -DDOWNLOAD_BOOST=1 -DWITH_BOOST=../boost -DWITH_UNIT_TESTS=OFF -DUSE_LD_GOLD=1 -DWITH_DEBUG=1
RUN make -j$(nproc)

# Recover the original compiler. 
ENV CC=gcc-9
ENV CXX=g++-9


# ---------------------------------------------------------------------------------------------------------------
FROM sqlright_mysql_source_build AS sqlright_src

# Install SQLRight MySQL
USER root
COPY src /home/mysql/src
RUN chown -R mysql:mysql /home/mysql/src

# Setup the MySQL fuzzer compilation requirements.
USER root
RUN apt -y update
RUN apt -y install curl openjdk-11-jdk

## antlr4
USER mysql
WORKDIR /home/mysql
RUN curl -O https://www.antlr.org/download/antlr-4.12.0-complete.jar
## antlr4 runtime.
RUN wget https://github.com/antlr/antlr4/archive/4.12.0.zip
RUN unzip 4.12.0.zip
WORKDIR /home/mysql/antlr4-4.12.0/runtime/Cpp/
RUN mkdir -p bld
WORKDIR /home/mysql/antlr4-4.12.0/runtime/Cpp/bld
RUN cmake .. -DANTLR_JAR_LOCATION=/home/mysql/antlr-4.12.0-complete.jar -DWITH_DEMO=False
RUN make -j$(nproc)
USER root
RUN make install

## RSG
### Setup the Golang compilation
USER mysql
WORKDIR /home/mysql/
RUN wget https://go.dev/dl/go1.20.4.linux-amd64.tar.gz && \
    tar -xf go1.20.4.linux-amd64.tar.gz
USER root
RUN cp -r /home/mysql/go /usr/local/go

### RSG source folder
USER root
COPY rsg /home/mysql/rsg
RUN chown -R mysql:mysql /home/mysql/rsg

USER mysql 
WORKDIR /home/mysql/rsg
RUN echo 'export PATH="/usr/local/go/bin:$PATH"' >> ~/.bashrc
ENV PATH="/usr/local/go/bin:$PATH"
RUN bash ./build.sh

# Compile MySQL Fuzzer.
USER mysql
WORKDIR /home/mysql/src
RUN cp /home/mysql/rsg/rsg_helper.* ./rsg/
RUN make


# Setup other SQLRight configurations.

# Final setup. Setup all the remaining fuzzing settings.
FROM sqlright_src

# Finished setup the SQLRight source code.

# Setup the MySQL crash decuplication code. 
USER mysql
WORKDIR /home/mysql/
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | bash -s -- -y
ENV PATH="/home/mysql/.cargo/bin:${PATH}"

# Copy the AFLTriage src.
USER root
RUN apt -y install lsof
COPY AFLTriage /home/mysql/AFLTriage
RUN chown -R mysql:mysql /home/mysql/AFLTriage

# Install
USER mysql
WORKDIR /home/mysql/AFLTriage
RUN cargo build

# Copy all the required helper script to the container.
USER root
COPY scripts /home/mysql/scripts
RUN chown -R mysql:mysql /home/mysql/scripts

# set up fuzzing
USER root
COPY fuzz_root /home/mysql/fuzzing/fuzz_root
RUN chown -R mysql:mysql /home/mysql/fuzzing/

# setup the rsg required libraries
USER mysql
WORKDIR /home/mysql/fuzzing/fuzz_root
RUN mkdir -p rsg && cp -r /home/mysql/rsg/rsg_helper.so ./rsg
RUN cp /home/mysql/src/mysql_sql.y ./mysql_sql.y

# Not sure why, but user MySQL doesn't have the permission to open the database.
USER root
RUN chown -R mysql:mysql /home/mysql/mysql-server/bld/bin
RUN chown -R mysql:mysql /home/mysql/mysql-server/bld/library_output_directory
RUN chown mysql:mysql /home/mysql/mysql-server/bld
RUN chown -R mysql:mysql /var
RUN chown -R mysql:mysql /tmp

# set up MySQL database
USER mysql
WORKDIR /home/mysql/mysql-server/bld/
RUN mkdir data
RUN bin/mysqld --initialize-insecure --user=mysql --datadir=data
RUN bin/mysql_ssl_rsa_setup --datadir=data
RUN mkdir data_all
RUN mv data data_all/ori_data

# Further setup the database info
USER mysql
WORKDIR /home/mysql/scripts
RUN python3 setup_database.py

USER root
RUN echo "[mysqld]\nsql_mode = \"NO_ENGINE_SUBSTITUTION\"" > /etc/mysql/conf.d/mysql.cnf

USER root
WORKDIR /home/mysql/fuzzing/fuzz_root

#ENTRYPOINT ../afl-fuzz -t 2000 -m 2000 -i ./crashes -o ../output /usr/local/pgsql/bin/postgres --single -D /usr/local/pgsql/data main 
