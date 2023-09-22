#!/bin/bash -e
cd "$(dirname "$0")"/../bisecting

## Release code. Remove all intermediate steps to save hard drive space.
sudo docker build --rm=true -f ./Dockerfile -t rsg_mariadb_bisecting .



