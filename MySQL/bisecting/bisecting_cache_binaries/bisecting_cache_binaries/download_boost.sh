#!/bin/bash

for i in $(seq 56 1 78)
do
        wget https://sourceforge.net/projects/boost/files/boost/1.$((i)).0/boost_1_$((i))_0.tar.bz2/download
        mv ./download boost_1_$((i))_0.tar.bz2

        tar -xf boost_1_$((i))_0.tar.bz2
done
