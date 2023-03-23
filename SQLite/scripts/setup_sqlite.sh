#!/bin/bash -e
cd "$(dirname "$0")"/../docker

rm -rf ./rsg &> /dev/null
rm ./src/sqlite_parser_rule_only.y &> /dev/null

cp -r ../../Common_Tootls/rsg ./
cp ./rsg/sqlite_parse_rule_only.y src/sqlite_parse_rule_only.y

## Release code. Remove all intermediate steps to save hard drive space.
sudo docker build --rm=true -f ./Dockerfile -t sqlright_sqlite .
