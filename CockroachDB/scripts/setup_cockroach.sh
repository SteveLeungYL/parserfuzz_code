#!/bin/bash -e
cd "$(dirname "$0")"/../docker

rm -rf ./CockroachDB_pkg_plugin/rsg &> /dev/null
cp -r ../../Common_Tootls/rsg ./CockroachDB_pkg_plugin/rsg

## For debug purpose, keep all intermediate steps to fast reproduce the run results.
sudo docker build --rm=false -f ./Dockerfile -t sqlright_cockroach .

## Release code. Remove all intermediate steps to save hard drive space.
#sudo docker build --rm=true -f ./Dockerfile -t sqlright_cockroach .
