#!/bin/bash -e
cd "$(dirname "$0")"/../docker

cp -r ../../Common_Tootls/rsg ./rsg

## Release code. Remove all intermediate steps to save hard drive space.
sudo docker build --rm=true -f ./Dockerfile -t sqlright_sqlite .
