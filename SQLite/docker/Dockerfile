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
apt install -y g++-9 && \
apt install -y gcc-9 && \
apt install -y lemon && \
pip3 install gitpython

RUN useradd -ms /bin/bash sqlite
USER sqlite

RUN pip3 install libtmux

WORKDIR /home/sqlite

# Setup the Docker helper scripts
USER root
WORKDIR /home/sqlite
COPY scripts /home/sqlite/scripts
RUN chown -R sqlite:sqlite /home/sqlite/scripts

USER sqlite

# Build AFL. 
RUN git clone https://github.com/google/AFL.git

WORKDIR /home/sqlite/AFL
RUN sed -i  's/#define MAP_SIZE_POW2       16/#define MAP_SIZE_POW2       18/' config.h
RUN AFL_NO_X86=1 make
WORKDIR /home/sqlite/AFL/llvm_mode
# ENV LLVM_CONFIG=llvm-config-6.0
RUN make

FROM fundamental AS sqlite3_build

# Build SQLite3
WORKDIR /home/sqlite
RUN git clone https://github.com/sqlite/sqlite.git
RUN cp -r sqlite sqlite_ori

## Build instrumented SQLite3
WORKDIR /home/sqlite/sqlite
#RUN git checkout version-3.40.0
RUN git checkout master
RUN python3 /home/sqlite/scripts/modify_sqlite_shell.py
ENV CXX=/home/sqlite/AFL/afl-clang-fast++
ENV CC=/home/sqlite/AFL/afl-clang-fast
RUN ./configure --enable-debug --enable-all
RUN make -j$(nproc)

## Build uninstrumented SQLite3
WORKDIR /home/sqlite/sqlite_ori
#RUN git checkout version-3.40.0
RUN git checkout master
ENV CXX=g++-9
ENV CC=gcc-9
RUN ./configure --enable-debug --enable-all
RUN make -j$(nproc)

# Setup the Golang compilation
WORKDIR /home/sqlite/
RUN wget https://go.dev/dl/go1.20.2.linux-arm64.tar.gz && \
    tar -xf go1.20.2.linux-arm64.tar.gz

USER root
RUN cp -r /home/sqlite/go /usr/local/go

COPY rsg /home/sqlite/rsg
RUN chown -R sqlite:sqlite /home/sqlite/rsg

USER sqlite
WORKDIR /home/sqlite/rsg
RUN echo 'export PATH="/usr/local/go/bin:$PATH"' >> ~/.bashrc
RUN echo 'export PATH="/home/cockroach/.yarn/bin:$PATH"' >> ~/.bashrc
ENV PATH="/usr/local/go/bin:$PATH"
ENV PATH="/home/cockroach/.yarn/bin:$PATH"
RUN bash ./build.sh

# Setup the SQLRight source code.
FROM sqlite3_build AS sqlright_build

USER root
WORKDIR /home/sqlite/src
COPY src /home/sqlite/src
RUN cp -r /home/sqlite/rsg/rsg_helper.* /home/sqlite/src/rsg/
RUN chown -R sqlite:sqlite /home/sqlite/src

USER sqlite
WORKDIR /home/sqlite/src
RUN make -j$(nproc)

# Setup the fuzzing context
FROM sqlright_build AS sqlite3_fuzzing
USER sqlite
WORKDIR /home/sqlite
RUN mkdir -p fuzzing

USER root
WORKDIR /home/sqlite/fuzzing
COPY fuzz_root /home/sqlite/fuzzing/fuzz_root
WORKDIR /home/sqlite/fuzzing/fuzz_root
RUN cp /home/sqlite/src/sqlite_parse_rule_only.y /home/sqlite/fuzzing/fuzz_root/
RUN cp /home/sqlite/src/sqlite_func_json.json /home/sqlite/fuzzing/fuzz_root/
RUN mkdir -p rsg && cp /home/sqlite/rsg/rsg_helper.so ./rsg
RUN chown -R sqlite:sqlite /home/sqlite/fuzzing/

USER sqlite
WORKDIR /home/sqlite/fuzzing
RUN mkdir -p Bug_Analysis

# Setup the SQLite bisecting cached binaries. 
#USER root
#COPY sqlite_bisecting_binary /home/sqlite/sqlite_bisecting_binary
#RUN chown -R sqlite:sqlite /home/sqlite/sqlite_bisecting_binary

# Setup the SQLite bisecting environment
#USER root
#COPY bisecting /home/sqlite/bisecting
#RUN chown -R sqlite:sqlite /home/sqlite/bisecting

# Also, setup the bisecting sqlite folder. 
#USER sqlite
#WORKDIR /home/sqlite
#RUN git clone https://github.com/sqlite/sqlite.git ./sqlite_bisecting_binary
#WORKDIR /home/sqlite/sqlite_bisecting_binary
#RUN mkdir -p bld


# Entry workdir.
USER root
WORKDIR /home/sqlite/fuzzing/fuzz_root


