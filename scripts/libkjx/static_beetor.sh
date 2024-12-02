#!/bin/sh

set -e

cd ./assets || return
git clone git@github.com:curl/curl.git
cd - || return && cd ./assets/curl
autoreconf -fi
./configure --with-openssl
make
cd - || return
mkdir -p ./artifacts/libs
cp ./assets/curl/lib/.libs/libcurl.a ./artifacts/libs/libcurl.a

gcc ./scripts/libkjx/beetor.c ./artifacts/libs/libcurl.a -lssl -lcrypto -ldl -lm -lz -DCURL_STATICLIB -O0 -Wall -lpthread -Icurl-easy -Icurl -lcurl -g -o ./artifacts/beetor

#make test
#make install
