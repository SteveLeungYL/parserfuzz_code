FROM ubuntu:20.04 AS sqlright_mysql_tools
MAINTAINER "PSU-Security-Universe"

ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN chmod 777 /tmp

RUN apt -y update
RUN apt -y upgrade
RUN apt -y install bison
RUN apt -y update && apt -y install build-essential
RUN apt -y install clang
RUN apt -y install cmake
RUN apt -y install flex
RUN apt -y install g++-9
RUN apt -y install gcc-9
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
RUN apt -y install unzip
RUN pip3 install gitpython
RUN pip3 install loguru
RUN pip3 install rich
RUN pip3 install click
RUN pip3 install pathlib
RUN apt -y install libaio1
RUN apt -y install zip
RUN apt -y install openjdk-8-jdk lsof pcre2-utils

RUN apt -y install llvm
RUN apt -y install clang

RUN apt -y install g++-9
RUN apt -y install gcc-9

RUN apt -y install libsasl2-dev

RUN apt -y install libnuma-dev


# Install mysql-client related libraries, for the compilation of sqlright.
RUN pip3 install psutil
RUN pip3 install mysql-connector-python mysql-connector-python
RUN apt -y install libmysqlclient-dev
RUN pip3 install mysqlclient

RUN useradd -ms /bin/bash mysql
RUN chown -R mysql:mysql /home/mysql

# Setup mysql git repo.
USER mysql

ENV CC=gcc-9
ENV CXX=g++-9

FROM sqlright_mysql_tools AS bisecting_setup

USER mysql
WORKDIR /home/mysql/
# Download MariaDB, use Default branch directly. (so much more easy to build and less picky than MySQL) 
RUN git clone https://github.com/MariaDB/server.git && mv server mariadb && cd mariadb

USER root
WORKDIR /home/mysql/
COPY bisecting_scripts /home/mysql/bisecting_scripts
RUN chown -R mysql:mysql /home/mysql/bisecting_scripts
COPY scripts /home/mysql/scripts
RUN chown -R mysql:mysql /home/mysql/scripts

USER mysql
WORKDIR /home/mysql/
RUN mkdir -p depen && cd depen && wget https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.42/pcre2-10.42.tar.gz && tar -xf pcre2-10.42.tar.gz && \
    cd pcre2-10.42 && ./configure --prefix=/usr --docdir=/usr/share/doc/pcre2-10.34 --enable-unicode --enable-pcre2test-libreadline --disable-static && make
USER root
WORKDIR /home/mysql/pcre2-10.42
RUN make install

USER root
WORKDIR /home/mysql
