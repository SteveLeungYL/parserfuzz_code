#!/bin/bash -e
cd "$(dirname "$0")"/../docker
## Release code. Remove all intermediate steps to save hard drive space.
sudo docker build --rm=true -f ./Dockerfile -t sqlright_sqlite .
