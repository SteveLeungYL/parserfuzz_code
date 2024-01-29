#!/bin/bash -e
cd "$(dirname "$0")"/../docker

rm -rf ./rsg &> /dev/null
rm ./src/duckdb_grammar.y &> /dev/null

cp -r ../../Common_Tootls/rsg ./
cp ./rsg/parser_def_files/duckdb_grammar.y src/duckdb_grammar.y

## Release code. Remove all intermediate steps to save hard drive space.
sudo docker build --rm=true -f ./Dockerfile -t parserfuzz_duckdb .
