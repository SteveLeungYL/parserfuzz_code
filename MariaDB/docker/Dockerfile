FROM ubuntu:20.04 AS sqlright_mariadb_tools
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
RUN apt -y install g++-multilib
RUN apt -y install gcc-multilib
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


# MariaDB can be connected using the `MySQL` connector. Therefore, we can
#   reuse the mysql python connector from the MySQL Docker image builder. 
# Install mysql-client related libraries, for the compilation of sqlright.
RUN pip3 install psutil
RUN pip3 install mysql-connector-python mysql-connector-python
RUN apt -y install libmysqlclient-dev
RUN pip3 install mysqlclient

RUN useradd -ms /bin/bash mariadb

ENV CC=clang
ENV CXX=clang++

RUN chown -R mariadb:mariadb /home/mariadb

# build block-coverage AFL
WORKDIR /home/mariadb
COPY AFL /home/mariadb/AFL
RUN chown -R mariadb:mariadb /home/mariadb

USER mariadb
WORKDIR /home/mariadb/AFL 
RUN make
WORKDIR /home/mariadb/AFL/llvm_mode
# ENV LLVM_CONFIG=llvm-config-6.0
RUN make 

# ---------------------------------------------------------------------------------------------------------------
FROM sqlright_mariadb_tools AS sqlright_mariadb_source_build

# build mariadb instrumented by afl-clang-fast
USER mariadb
WORKDIR /home/mariadb/
RUN git clone https://github.com/MariaDB/server.git --depth 1
WORKDIR /home/mariadb/server

RUN mkdir bld
WORKDIR /home/mariadb/server/bld
ENV CC=/home/mariadb/AFL/afl-clang-fast
ENV CXX=/home/mariadb/AFL/afl-clang-fast++
RUN cmake .. -DDOWNLOAD_BOOST=1 -DWITH_BOOST=../boost -DWITH_UNIT_TESTS=OFF -DUSE_LD_GOLD=1 -DCMAKE_INSTALL_PREFIX=$(pwd)
RUN make -j$(nproc) install

# Recover the original compiler. 
ENV CC=gcc-9
ENV CXX=g++-9


# ---------------------------------------------------------------------------------------------------------------
FROM sqlright_mariadb_source_build AS sqlright_src

## TODO:: FIXME:: Should change to MariaDB parser
# Install SQLRight MySQL
USER root
COPY src /home/mariadb/src
WORKDIR /home/mariadb/src/parser
RUN wget https://github.com/mysql/mysql-server/archive/refs/tags/mysql-8.0.27.zip
RUN unzip mysql-8.0.27.zip 
RUN mv mysql-server-mysql-8.0.27 mysql-server
RUN chown -R mariadb:mariadb /home/mariadb/src

# Add SQLRight modification to the MySQL source code.
USER mariadb 
WORKDIR /home/mariadb/src/parser/patches
RUN bash ./replace-changed-code.sh

# Compile the build-in MySQL source code.
WORKDIR /home/mariadb/src/parser/mysql-server
RUN mkdir bld
WORKDIR /home/mariadb/src/parser/mysql-server/bld

# Mute the Warning information. The modified version of the MySQL does return many Warnings while compiling. Known problem, ignore them. 
RUN cmake .. -DDOWNLOAD_BOOST=1 -DWITH_BOOST=../boost 
RUN make -j$(nproc)

WORKDIR /home/mariadb/src
RUN make

USER root
RUN cp /home/mariadb/src/parser/mysql-server/bld/library_output_directory/libserver_unittest_library.so /usr/lib/


# Setup other SQLRight configurations.

# Final setup. Setup all the remaining fuzzing settings.
FROM sqlright_src

# Finished setup the SQLRight source code.

# Copy all the required helper script to the container.
USER root
COPY scripts /home/mariadb/scripts
RUN chown -R mariadb:mariadb /home/mariadb/scripts

# set up fuzzing
USER root
COPY fuzz_root /home/mariadb/fuzzing/fuzz_root
RUN chown -R mariadb:mariadb /home/mariadb/fuzzing/

# Not sure why, but user mariadb doesn't have the permission to open the database.
USER root
RUN chown -R mariadb:mariadb /home/mariadb/server/bld/bin
# RUN chown -R mariadb:mariadb /home/mariadb/server/bld/library_output_directory
RUN chown mariadb:mariadb /home/mariadb/server/bld
RUN chown -R mariadb:mariadb /var
RUN chown -R mariadb:mariadb /tmp

# set up mariadb database
USER mariadb 
WORKDIR /home/mariadb/server/bld/
RUN mkdir data
RUN ./scripts/mariadb-install-db --user=mariadb --basedir=$(pwd) --datadir=$(pwd)/data
RUN mkdir data_all
RUN mv data data_all/ori_data

# Further setup the database info
USER mariadb
WORKDIR /home/mariadb/scripts
RUN python3 setup_database.py


USER root
WORKDIR /home/mariadb/fuzzing/fuzz_root
