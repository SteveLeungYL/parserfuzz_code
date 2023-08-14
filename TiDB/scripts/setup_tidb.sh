#!/bin/bash -e
cd "$(dirname "$0")"/../docker

rm -rf ./tidb_pkg_plugin/rsg &> /dev/null
cp -r ../../Common_Tootls/rsg ./tidb_pkg_plugin/rsg
rm ./tidb_pkg_plugin/parser/parser.y; exit 0
cp ./tidb_pkg_plugin/parser_translate/assets/tidb_parser_inst_modi.y ./tidb_pkg_plugin/parser/parser.y

## For debug purpose, keep all intermediate steps to fast reproduce the run results.
sudo docker build --rm=false -f ./Dockerfile -t sqlright_tidb .

## Release code. Remove all intermediate steps to save hard drive space.
#sudo docker build --rm=true -f ./Dockerfile -t sqlright_tidb .
