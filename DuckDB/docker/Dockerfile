FROM ubuntu:20.04 AS fundamental
MAINTAINER "PSU-Security-Universe"

ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN chmod 777 /tmp

RUN apt -y upgrade && \
apt -y update && \
apt -y install bison  && \
apt -y install flex  && \
apt -y install git  && \
apt -y install make  && \
apt -y install cmake  && \
apt -y install build-essential  && \
apt -y install clang && \
apt -y install libreadline-dev  && \
apt -y install zlib1g-dev  && \
apt -y install gdb  && \
apt -y install vim  && \
apt -y install tmux  && \
apt -y install python3 && \
apt -y install python3-pip && \
apt -y install screen && \
apt -y install watch && \
apt -y install unzip && \
apt -y install wget && \
apt -y install tcl && \
apt -y install llvm && \
apt -y install clang && \
apt install -y g++-10 && \
apt install -y gcc-10 && \
pip3 install gitpython

RUN useradd -ms /bin/bash duckdb
USER duckdb

RUN pip3 install libtmux

WORKDIR /home/duckdb


USER duckdb

# Build AFL.
RUN git clone https://github.com/google/AFL.git

WORKDIR /home/duckdb/AFL
RUN sed -i  's/#define MAP_SIZE_POW2       16/#define MAP_SIZE_POW2       18/' config.h
RUN make
WORKDIR /home/duckdb/AFL/llvm_mode
# ENV LLVM_CONFIG=llvm-config-6.0
RUN make

FROM fundamental AS duckdb3_build

# Build duckdb3
WORKDIR /home/duckdb
RUN git clone https://github.com/duckdb/duckdb.git
RUN cp -r duckdb duckdb_ori

## Build instrumented duckdb3
WORKDIR /home/duckdb/duckdb
RUN git checkout v0.9.1
ENV CXX=/home/duckdb/AFL/afl-clang-fast++
ENV CC=/home/duckdb/AFL/afl-clang-fast
RUN make -j$(nproc)

# Setup the Docker helper scripts
USER root
WORKDIR /home/duckdb
COPY scripts /home/duckdb/scripts
RUN chown -R duckdb:duckdb /home/duckdb/scripts

## Build IR modified duckdb3
WORKDIR /home/duckdb
RUN cp -r duckdb_ori duckdb_ir
WORKDIR /home/duckdb/duckdb_ir
RUN git checkout v0.9.1
ENV CXX=g++-10
ENV CC=gcc-10
RUN pip3 install loguru && python3 /home/duckdb/scripts/setup_duckdb_ir.py /home/duckdb/scripts/assets /home/duckdb/duckdb_ir
RUN make -j$(nproc)

# Setup the Golang compilation
WORKDIR /home/duckdb/
RUN wget https://go.dev/dl/go1.21.4.linux-amd64.tar.gz && \
    tar -xf go1.21.4.linux-amd64.tar.gz

USER root
RUN cp -r /home/duckdb/go /usr/local/go

COPY rsg /home/duckdb/rsg
RUN chown -R duckdb:duckdb /home/duckdb/rsg

USER duckdb
WORKDIR /home/duckdb/rsg
RUN echo 'export PATH="/usr/local/go/bin:$PATH"' >> ~/.bashrc
RUN echo 'export PATH="/home/duckdb/.yarn/bin:$PATH"' >> ~/.bashrc
ENV PATH="/usr/local/go/bin:$PATH"
ENV PATH="/home/duckdb/.yarn/bin:$PATH"
RUN bash ./build.sh

# Setup the SQLRight source code.
FROM duckdb3_build AS sqlright_build

USER root
WORKDIR /home/duckdb/src
COPY src /home/duckdb/src
RUN cp -r /home/duckdb/rsg/rsg_helper.* /home/duckdb/src/rsg/
RUN chown -R duckdb:duckdb /home/duckdb/src

USER duckdb
WORKDIR /home/duckdb/src
RUN cp /home/duckdb/duckdb_ir/build/release/third_party/libpg_query/libduckdb_pg_query.a /home/duckdb/src/parser/libduckdb_pg_query.a
RUN make -j$(nproc)

# Setup the fuzzing context
FROM sqlright_build AS duckdb3_fuzzing
USER duckdb
WORKDIR /home/duckdb
RUN mkdir -p fuzzing

USER root
WORKDIR /home/duckdb/fuzzing
COPY fuzz_root /home/duckdb/fuzzing/fuzz_root
WORKDIR /home/duckdb/fuzzing/fuzz_root
RUN cp /home/duckdb/src/duckdb_grammar.y /home/duckdb/fuzzing/fuzz_root/
RUN mkdir -p rsg && cp /home/duckdb/rsg/rsg_helper.so ./rsg && cp /home/duckdb/src/afl-fuzz ./afl-fuzz
RUN chown -R duckdb:duckdb /home/duckdb/fuzzing/

USER duckdb
WORKDIR /home/duckdb/fuzzing
RUN mkdir -p Bug_Analysis

# Entry workdir.
USER root
WORKDIR /home/duckdb/fuzzing/fuzz_root


