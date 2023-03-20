FROM ubuntu:20.04 AS sqlright_mysql_tools
MAINTAINER "PSU-Security-Universe"

ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN chmod 777 /tmp

RUN apt -y update \
&& apt -y upgrade \
&& apt -y update \
&& apt -y install bison \
&& apt -y install build-essential \
&& apt -y install clang \
&& apt -y install cmake \
&& apt -y install flex \
&& apt -y install gdb \
&& apt -y install git \
&& apt -y install libncurses5-dev \
&& apt -y install libreadline-dev \
&& apt -y install libssl-dev \
&& apt -y install make \
&& apt -y install pkg-config \
&& apt -y install python3 \
&& apt -y install python3-pip \
&& apt -y install tmux \
&& apt -y install vim \
&& apt -y install xinetd \
&& apt -y install zlib1g-dev  \
&& apt -y install screen \
&& apt -y install watch \
&& apt -y install unzip \
&& pip install libtmux \
&& apt -y install wget \
&& apt -y install llvm \
&& apt -y install clang \
&& apt -y install g++-9 \
&& apt -y install gcc-9 \
&& apt -y install libnuma-dev


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
RUN wget https://github.com/mysql/mysql-server/archive/refs/tags/mysql-8.0.30.zip
RUN unzip mysql-8.0.30.zip
RUN mv mysql-server-mysql-8.0.30 mysql-server
WORKDIR /home/mysql/mysql-server
# MySQL version 8.0.30
# RUN git checkout 3290a66c89eb1625a7058e0ef732432b6952b435 
RUN mkdir bld
WORKDIR /home/mysql/mysql-server/bld
ENV CC=/home/mysql/AFL/afl-clang-fast
ENV CXX=/home/mysql/AFL/afl-clang-fast++
RUN cmake .. -DDOWNLOAD_BOOST=1 -DWITH_BOOST=../boost -DWITH_UNIT_TESTS=OFF -DUSE_LD_GOLD=1
RUN make -j$(nproc)

# Recover the original compiler. 
ENV CC=gcc-9
ENV CXX=g++-9

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

USER root
WORKDIR /home/mysql/fuzzing/fuzz_root

#ENTRYPOINT ../afl-fuzz -t 2000 -m 2000 -i ./crashes -o ../output /usr/local/pgsql/bin/postgres --single -D /usr/local/pgsql/data main 
