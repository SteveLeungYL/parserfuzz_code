#!/bin/bash -e
cd "$(dirname "$0")"/../docker

# Copy the RSG folder to the target location
rm -rf ./rsg
cp -r ../../Common_Tootls/rsg ./rsg

rm -rf ./AFLTriage
cp -r ../../Common_Tootls/AFLTriage ./AFLTriage

## For debug purpose, keep all intermediate steps to fast reproduce the run results.
#sudo docker build --rm=false -f ./Dockerfile -t sqlright_mysql .  

## Release code. Remove all intermediate steps to save hard drive space.
sudo docker build --rm=true -f ./Dockerfile -t sqlright_mysql .

