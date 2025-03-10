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
&& aptitude -y install gcc-9  \
&& aptitude -y install g++-9  \
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

RUN useradd -ms /bin/bash cockroach
USER cockroach

RUN pip3 install libtmux loguru

USER root
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash
RUN apt update
RUN apt -y install nodejs

WORKDIR /home/cockroach

USER cockroach
RUN curl --compressed -o- -L https://yarnpkg.com/install.sh | bash

# Download the original Go library. Set it up. 
RUN wget https://go.dev/dl/go1.19.linux-amd64.tar.gz
RUN tar -xf go1.19.linux-amd64.tar.gz
USER root
RUN cp -r go /usr/local/
USER cockroach
RUN echo 'export PATH="/usr/local/go/bin:$PATH"' >> ~/.bashrc
RUN echo 'export PATH="/home/cockroach/.yarn/bin:$PATH"' >> ~/.bashrc
ENV PATH="/usr/local/go/bin:$PATH"
ENV PATH="/home/cockroach/.yarn/bin:$PATH"

# No need for AFL. CockroachDB is a Golang program. Construct the GOPATH folder.
USER cockroach
RUN mkdir -p /home/cockroach/go_projects/src/github.com/cockroachdb
WORKDIR /home/cockroach/go_projects/src/github.com/cockroachdb
RUN git clone https://github.com/cockroachdb/cockroach.git
RUN cp -r cockroach cockroach_ori
RUN echo 'export GOPATH="/home/cockroach/go_projects"' >> ~/.bashrc
ENV GOPATH="/home/cockroach/go_projects"

# Move the CockroachDB Package Plugin into the Docker Image. 
USER root
COPY CockroachDB_pkg_plugin /home/cockroach/CockroachDB_pkg_plugin
RUN chown -R cockroach:cockroach /home/cockroach/CockroachDB_pkg_plugin

# Compile the CockroachDB with SQLRight instrumented parser. 
USER cockroach
WORKDIR /home/cockroach/go_projects/src/github.com/cockroachdb/cockroach
RUN git checkout 566348f48c7064014438e1d2c7f46624b4e2c4f1 # The version we build our parser on. 

# Copy parser instrumentation code.
USER cockroach
WORKDIR /home/cockroach/go_projects/src/github.com/cockroachdb/cockroach/pkg/sql/sem
RUN rm -rf ./tree 
RUN cp -r /home/cockroach/CockroachDB_pkg_plugin/tree ./tree
WORKDIR /home/cockroach/go_projects/src/github.com/cockroachdb/cockroach/pkg/sql/parser
RUN cp -r  /home/cockroach/CockroachDB_pkg_plugin/parser_helper ./parser_helper
WORKDIR /home/cockroach/go_projects/src/github.com/cockroachdb/cockroach/pkg/sql/parser/parser_helper

# Instruement the original parser file to print gramamr coverage.
RUN cp -r /home/cockroach/go_projects/src/github.com/cockroachdb/cockroach/pkg/sql/parser/sql.y /home/cockroach/CockroachDB_pkg_plugin/parser_translate/assets/cockroach_sql.y
WORKDIR /home/cockroach/CockroachDB_pkg_plugin/parser_translate
RUN python3 include_cov_log_to_parser.py && python3 rewrite_parser_code_to_include_log_func.py /home/cockroach/go_projects/src/github.com/cockroachdb/cockroach/pkg/sql/parser/parse.go
RUN cp -r /home/cockroach/CockroachDB_pkg_plugin/parser_translate/assets/cockroach_sql_inst_modi.y /home/cockroach/go_projects/src/github.com/cockroachdb/cockroach/pkg/sql/parser/sql.y


# Compile the Cockroach befroe generating the parser shared library. 
WORKDIR /home/cockroach/go_projects/src/github.com/cockroachdb/cockroach/
# WIll fail because of the instrumentation.
RUN make buildshort; exit 0

# Fix a proj problem that could crash our build process. 
USER cockroach
WORKDIR /home/cockroach/go_projects/native/x86_64-linux-gnu/proj/
# Enable -fPIC
RUN cmake . -DCMAKE_POSITION_INDEPENDENT_CODE=ON
RUN make clean && make -j $(nproc)

WORKDIR /home/cockroach/go_projects/src/github.com/cockroachdb/cockroach/pkg/sql/parser/parser_helper
RUN bash ./build.sh
RUN mv ./parser_helper.* /home/cockroach/CockroachDB_pkg_plugin

# We should also compile the RSG (Random Statement Generator)
WORKDIR /home/cockroach/go_projects/src/github.com/
RUN cp -r /home/cockroach/CockroachDB_pkg_plugin/rsg ./
WORKDIR /home/cockroach/go_projects/src/github.com/rsg
RUN cp /home/cockroach/go_projects/src/github.com/cockroachdb/cockroach/pkg/sql/parser/sql.y ./parser_def_files/cockroach_sql.y
RUN bash ./build.sh
WORKDIR /home/cockroach/go_projects/src/github.com/rsg/parser_def_files
RUN python3 ./cleanup_cockroachdb_rules.py
WORKDIR /home/cockroach/go_projects/src/github.com/rsg
RUN mv ./rsg_helper.h /home/cockroach/CockroachDB_pkg_plugin
RUN mv ./rsg_helper.so /home/cockroach/CockroachDB_pkg_plugin
RUN mv ./parser_def_files/cockroach_sql_modi.y /home/cockroach/CockroachDB_pkg_plugin

# -----------------------------------------------

# Replace the original GoLang runtime to an older version
#USER cockroach
#WORKDIR /home/cockroach
#RUN wget https://go.dev/dl/go1.18.5.linux-amd64.tar.gz
#RUN tar -xf go1.18.5.linux-amd64.tar.gz
#USER root
#RUN cp -r go /usr/local/

# The compilation of the parser shared library is complete. Remove the built CockroachDB. 
USER cockroach
WORKDIR /home/cockroach/go_projects/src/github.com/cockroachdb
RUN rm -rf cockroach && cp -r cockroach_ori cockroach

# Compile the latest version of CockroachDB, prep for coverage instrumentation.
USER cockroach
WORKDIR /home/cockroach/go_projects/src/github.com/cockroachdb/cockroach
RUN git checkout v22.1.10 # This is an official release on Oct 10th, 2022.
# The first build is possible to be failed by vendor mismatched. Ignored. 
# The first build will automatically call go mod vendor. 
RUN make build; exit 0
# Actual build. After the build, the cockroach binary should be in 
# /home/cockroach/go_projects/src/github.com/cockroachdb/cockroach/cockroach
RUN make buildshort;


# Import the covtest unit test entry
USER cockroach
WORKDIR /home/cockroach
RUN cp -r ./CockroachDB_pkg_plugin/covtest /home/cockroach/go_projects/src/github.com/cockroachdb/cockroach/pkg/

# Modify the go library, so that the CockroachDB instrumentation code would work.
# Checked working for GO 19.0 version.
USER root
WORKDIR /usr/local/go/src/cmd
RUN cp -r ./internal/edit ./edit

# Instrument the CockroachDB source code. 
USER cockroach
WORKDIR /home/cockroach/
RUN cp ./CockroachDB_pkg_plugin/inst_script.py /home/cockroach/go_projects/src/github.com/cockroachdb/
WORKDIR /home/cockroach/CockroachDB_pkg_plugin/goInst/
RUN go build
RUN cp ./goInstr /home/cockroach/go_projects/src/github.com/cockroachdb/cockroach/
WORKDIR /home/cockroach/go_projects/src/github.com/cockroachdb/
RUN python3 inst_script.py

# Introduce the globalcov module. 
# TODO: Fix it later. Dirty place the globalcov module into the vendor folder. 
USER cockroach
# Modify the go.mod
WORKDIR /home/cockroach/go_projects/src/github.com/cockroachdb/cockroach
RUN cp -r ~/CockroachDB_pkg_plugin/globalcov  /home/cockroach/go_projects/src/github.com/globalcov
RUN sed -i -e '4s/^/replace github.com\/globalcov => ..\/..\/globalcov\n/' ./go.mod
RUN sed -i -e '14s/^/github.com\/globalcov v0.0.0-00010101000000-000000000000\n/' ./go.mod
RUN go mod vendor; exit 0;

# Copy the globalcov folder to the vendor folder
WORKDIR /home/cockroach/go_projects/src/github.com/cockroachdb/cockroach/vendor
RUN mkdir -p github.com
RUN cp -r ~/CockroachDB_pkg_plugin/globalcov ./github.com/globalcov
# Some package will search for the github folder (rather than the github.com)
# to look for the globalcov dependency. Dirty fix for now. 
# TODO: Fix it later.
RUN mkdir -p github
RUN cp -r ~/CockroachDB_pkg_plugin/globalcov ./github/globalcov
RUN cp -r ~/CockroachDB_pkg_plugin/globalcov /home/cockroach/go_projects/src/github.com/globalcov

#USER cockroach
### Copy the go library to the GOPATH. 
#RUN cp -r ~/go ~/go_projects/src/go
#RUN cp ~/go_modified/cover.go ~/go_projects/src/go/src/cmd/cover
#WORKDIR /home/cockroach/go_projects/src/go/src/
#RUN bash ./buildall.bash -e linux/amd64

## Replace the original Go library with the instrumented new one. 
#USER root
#RUN mv /usr/local/go /usr/local/go_1_16_15_ori
#RUN cp -r /home/cockroach/go_projects/src/go /usr/local/go

# Compile the instrumented covtest unit test binary
USER cockroach
WORKDIR /home/cockroach/go_projects/src/github.com/cockroachdb/cockroach/
# The build.rev is a randomly set commit hash. 
RUN go mod tidy && go test -c -mod=mod -tags ' gss make x86_64_linux_gnu crdb_test' -ldflags '-X github.com/cockroachdb/cockroach/pkg/build.typ=development -extldflags "" -X "github.com/cockroachdb/cockroach/pkg/build.tag=cockroach-instrumented" -X "github.com/cockroachdb/cockroach/pkg/build.rev=566348f48c7064014438e1d2c7f46624b4e2c4f1" -X "github.com/cockroachdb/cockroach/pkg/build.cgoTargetTriple=x86_64-linux-gnu"  ' -run "." -timeout 99999m ./pkg/covtest


# Compile the SQLRight main code. 
USER root
WORKDIR /home/cockroach/
COPY src /home/cockroach/src
RUN chown -R cockroach:cockroach /home/cockroach/src

USER cockroach
WORKDIR /home/cockroach/src
# Copy the built parser_helper.so
RUN cp /home/cockroach/CockroachDB_pkg_plugin/parser_helper.* ./parser/
# Copy the built rsg_helper.so
RUN cp /home/cockroach/CockroachDB_pkg_plugin/rsg_helper.* ./rsg/
RUN make

#
### Finished setup of the SQLRight Validity Configurations.
#
## Setup the fuzzing context.
USER root
RUN mkdir /home/cockroach/fuzzing/

COPY fuzz_root /home/cockroach/fuzzing/fuzz_root/
RUN mkdir -p /home/cockroach/fuzzing/fuzz_root/outputs
RUN mkdir -p /home/cockroach/fuzzing/Bug_Analysis
RUN mkdir -p /home/cockroach/fuzzing/Bug_Analysis/bug_samples

RUN cp /home/cockroach/go_projects/src/github.com/cockroachdb/cockroach/covtest.test /home/cockroach/fuzzing/fuzz_root/
RUN cp /home/cockroach/src/afl-fuzz  /home/cockroach/fuzzing/fuzz_root/

USER root
RUN chown -R cockroach:cockroach /home/cockroach/fuzzing/
#
## At last, setup the Docker run script
USER root
COPY scripts /home/cockroach/scripts
RUN chown -R cockroach:cockroach /home/cockroach/scripts

# Copy the parser shared library to the current dir. 
USER cockroach
WORKDIR /home/cockroach/fuzzing/fuzz_root
RUN mkdir -p parser
RUN mkdir -p rsg
RUN cp /home/cockroach/CockroachDB_pkg_plugin/parser_helper.so ./parser/parser_helper.so
RUN cp /home/cockroach/CockroachDB_pkg_plugin/rsg_helper.so ./rsg/rsg_helper.so

RUN cp /home/cockroach/CockroachDB_pkg_plugin/cockroach_sql_modi.y /home/cockroach/src/cockroach_sql_modi.y
RUN cp /home/cockroach/CockroachDB_pkg_plugin/cockroach_sql_modi.y /home/cockroach/fuzzing/fuzz_root

# Final entry
USER root
WORKDIR /home/cockroach/fuzzing/fuzz_root

