FROM ubuntu:20.04
MAINTAINER "PSU-Security-Universe"

ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN chmod 777 /tmp

RUN apt -y upgrade \
&& apt -y update \
&& apt -y install bison  \
&& apt -y install flex  \
&& apt -y install git  \
&& apt -y install make  \
&& apt -y install cmake  \
&& apt -y install build-essential  \
&& apt -y install aptitude \
&& apt -y install clang \
&& apt -y install xinetd  \
&& apt -y install libreadline-dev  \
&& apt -y install zlib1g-dev  \
&& apt -y install gdb  \
&& apt -y install vim  \
&& apt -y install tmux  \
&& apt -y install python3 \
&& apt -y install python3-pip \
&& apt -y install libxml2-dev  \
&& apt -y install libxslt-dev  \
&& apt -y install libssl-dev  \
&& apt -y install libxml2-utils  \
&& apt -y install xsltproc \
&& apt install -y libpq-dev \
&& apt -y install screen \
&& apt -y install watch \
&& apt -y install unzip \
&& apt -y install wget \
&& apt -y install curl \
&& apt -y install autoconf \
&& apt -y install yarn \
&& apt -y install npm \
&& apt -y install llvm \
&& apt -y install clang \
&& apt install -y g++-9 \
&& apt install -y gcc-9

RUN useradd -ms /bin/bash tidb
USER tidb

RUN pip3 install libtmux loguru

USER root
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash
RUN apt update
RUN apt -y install nodejs

WORKDIR /home/tidb

USER tidb 
RUN curl --compressed -o- -L https://yarnpkg.com/install.sh | bash

# Download the original Go library. Set it up. 
RUN wget https://go.dev/dl/go1.20.linux-arm64.tar.gz
RUN tar -xf go1.20.linux-arm64.tar.gz
USER root
RUN cp -r go /usr/local/
USER tidb 
RUN echo 'export PATH="/usr/local/go/bin:$PATH"' >> ~/.bashrc
RUN echo 'export PATH="/home/tidb/.yarn/bin:$PATH"' >> ~/.bashrc
ENV PATH="/usr/local/go/bin:$PATH"
ENV PATH="/home/tidb/.yarn/bin:$PATH"

# Modify the go library, so that the CockroachDB instrumentation code would work.
# Checked working for GO 1.20.0 version.
USER root
WORKDIR /usr/local/go/src/cmd
RUN cp -r ./internal/edit ./edit

# No need for AFL. TiDB is a Golang program. Construct the GOPATH folder.
USER tidb 
RUN mkdir -p /home/tidb/go_projects/src/github.com/tidb
WORKDIR /home/tidb/go_projects/src/github.com/tidb
RUN git clone https://github.com/pingcap/tidb.git
RUN cp -r tidb tidb_ori
RUN echo 'export GOPATH="/home/tidb/go_projects"' >> ~/.bashrc
ENV GOPATH="/home/tidb/go_projects"

# Instrument the TiDB source code.
USER root
WORKDIR /home/tidb
COPY ./tidb_pkg_plugin /home/tidb/tidb_pkg_plugin
RUN chown -R tidb:tidb /home/tidb/tidb_pkg_plugin

USER tidb
WORKDIR /home/tidb/tidb_pkg_plugin/goInst
RUN go build && cp ./goInstr /home/tidb/go_projects/src/github.com/tidb/tidb/goInstr && cp /home/tidb/tidb_pkg_plugin/inst_script.py /home/tidb/go_projects/src/github.com/tidb/inst_script.py && cp /home/tidb/tidb_pkg_plugin/rewrite_tidb_code_for_cov_log.py /home/tidb/go_projects/src/github.com/tidb/rewrite_tidb_code_for_cov_log.py
WORKDIR /home/tidb/go_projects/src/github.com/tidb
RUN python3 inst_script.py && python3 rewrite_tidb_code_for_cov_log.py

WORKDIR /home/tidb/go_projects/src/github.com/tidb/tidb/
RUN cp -r /home/tidb/tidb_pkg_plugin/globalcov ./globalcov
RUN make && GOPATH=/home/tidb/go_projects cd tidb-server; GO111MODULE=on go test -c .  -ldflags '-X "github.com/pingcap/tidb/parser/mysql.TiDBReleaseVersion=v7.3.0-alpha-202-g17cda10e97" -X "github.com/pingcap/tidb/util/versioninfo.TiDBBuildTS=2023-07-20 18:18:13" -X "github.com/pingcap/tidb/util/versioninfo.TiDBGitHash=17cda10e97093c61e35a0d08800a641799f2e89f" -X "github.com/pingcap/tidb/util/versioninfo.TiDBGitBranch=master" -X "github.com/pingcap/tidb/util/versioninfo.TiDBEdition=Community"  ' -o ../bin/tidb-with-cov

USER root
WORKDIR /home/tidb/go_projects/src/github.com/tidb/tidb/

