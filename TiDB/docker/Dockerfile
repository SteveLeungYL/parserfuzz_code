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
&& apt install -y gcc-9 \
&& pip3 install libtmux loguru click \
&& apt -y install lsof

RUN useradd -ms /bin/bash tidb
USER tidb

RUN pip3 install libtmux loguru

USER root
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash
RUN apt update
RUN apt -y install nodejs
RUN pip3 install psutil
RUN pip3 install mysql-connector-python mysql-connector-python
RUN apt -y install libmysqlclient-dev mysql-client

WORKDIR /home/tidb

USER tidb
RUN curl --compressed -o- -L https://yarnpkg.com/install.sh | bash

# Download the original Go library. Set it up.
RUN wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
RUN tar -xf go1.21.0.linux-amd64.tar.gz
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
RUN cd tidb && git checkout v6.1.7
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
# Replace the parser folder first, and then rewrite the binary.
RUN python3 inst_script.py && python3 rewrite_tidb_code_for_cov_log.py

WORKDIR /home/tidb/go_projects/src/github.com/tidb/tidb/
RUN cp -r /home/tidb/tidb_pkg_plugin/globalcov ./globalcov
RUN make
RUN cd tidb-server; GO111MODULE=on go test -c .  -ldflags '-X "github.com/pingcap/tidb/parser/mysql.TiDBReleaseVersion=v7.3.0-alpha-202-g17cda10e97" -X "github.com/pingcap/tidb/util/versioninfo.TiDBBuildTS=2023-07-20 18:18:13" -X "github.com/pingcap/tidb/util/versioninfo.TiDBGitHash=17cda10e97093c61e35a0d08800a641799f2e89f" -X "github.com/pingcap/tidb/util/versioninfo.TiDBGitBranch=master" -X "github.com/pingcap/tidb/util/versioninfo.TiDBEdition=Community"  ' -o ../bin/tidb-with-cov
RUN cp ./bin/tidb-with-cov /home/tidb/tidb-with-cov && cp ./bin/tidb-server /home/tidb/tidb-server-ori
# Finished the building of the TiDB applicaton.


# Build the parser-helper module, and the grammar coverage logging module
USER tidb
WORKDIR /home/tidb/go_projects/src/github.com/tidb
RUN rm -rf tidb && cp -r tidb_ori tidb
WORKDIR /home/tidb/go_projects/src/github.com/tidb/tidb
RUN git checkout v6.1.7 && rm -rf ./parser && cp -r /home/tidb/tidb_pkg_plugin/parser ./parser && cd ./parser && make; make; make; make; exit 0;
RUN cd ./parser/parser_helper && bash build.sh && cp ./parser_helper.* /home/tidb/tidb_pkg_plugin/


# Next, build the fuzzer source code.
COPY src /home/tidb/src
USER root
RUN chown -R tidb:tidb /home/tidb/src
USER tidb
WORKDIR /home/tidb/tidb_pkg_plugin/rsg/
RUN bash build.sh
WORKDIR /home/tidb/src/
RUN cp /home/tidb/tidb_pkg_plugin/rsg/rsg_helper.* ./rsg/ && cp /home/tidb/tidb_pkg_plugin/parser_helper.* ./parser/
RUN make -j$(nproc)

# At last, build the fuzz_root env.
COPY fuzz_root /home/tidb/fuzz_root
USER root
RUN chown -R tidb:tidb /home/tidb/fuzz_root
USER tidb
RUN cp /home/tidb/src/afl-fuzz /home/tidb/fuzz_root/afl-fuzz && cp /home/tidb/tidb_pkg_plugin/rsg/parser_def_files/tidb_parser_modi.y /home/tidb/fuzz_root/tidb_parser_modi.y \
    && cp -r /home/tidb/src/rsg /home/tidb/fuzz_root/rsg && cp -r /home/tidb/src/parser /home/tidb/fuzz_root/parser \
    && cp -r /home/tidb/tidb-with-cov /home/tidb/fuzz_root/tidb-with-cov && cp -r /home/tidb/tidb-server-ori /home/tidb/fuzz_root/tidb-server-ori \
    && cp -r /home/tidb/tidb_pkg_plugin/rsg/parser_def_files/tidb_keyword_mapping.json /home/tidb/fuzz_root/tidb_keyword_mapping.json \
    && cp -r /home/tidb/fuzz_root/tidb_parser_modi.y /home/tidb/src/tidb_parser_modi.y

# Setup the database structure.
# This has been proven to be not working.
# RUN python3 /home/tidb/tidb_pkg_plugin/setup_tidb_database.py

# Setup the Bisecting folder.
COPY bisecting /home/tidb/bisecting
USER root
RUN chown -R tidb:tidb /home/tidb/bisecting

USER root
WORKDIR /home/tidb/fuzz_root/

ENTRYPOINT echo "Setting up database. One moment. " && bash /home/tidb/tidb_pkg_plugin/setup_tidb_database.sh && bash

