#!/bin/sh

BEETOR_PATH=./scripts/libkjx/beetor

builder() {

 # ci context

MODE="builder" . ./scripts/ccr.sh  && \
	docker run -d -p 5000:5000 --name registry registry:3.0 && \
	docker start registry && \

if [ "${PROGRAM}" = "beetor" ]; then
	docker compose -f ./compose.yml --progress=plain build beetor && \
	docker push localhost:5000/beetor:latest && \
	docker stop registry
else
	docker run -d -p 5000:5000 --name registry registry:3.0
	docker start registry && \
	docker compose -f ./compose.yml --progress=plain build beetor && \
	docker push localhost:5000/beetor:latest && \
	docker stop registry
fi


}

artifact() {
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
}

bwc() {

gcc ./scripts/libkjx/bwc_off.c -O0 -Wall -lpthread -g -o ./artifacts/bwc_off > /artifacts/foo.txt

}

profiler() {
    if [ -f "$1" ]; then
        valgrind --tool=callgrind --trace-children=yes --dump-instr=yes --callgrind-out-file=./beetor.cg.out --vgdb-error=0 --collect-jumps=yes "$1"
        #valgrind --tool=callgrind --trace-children=yes --dump-instr=yes --callgrind-out-file=./bwc_off.cg.out --vgdb-error=0 --collect-jumps=yes ./bwc_off
    else
        printf "\n[profiler] File not found. exiting now...\n\n"
    fi
}




if [ "$1" = "profiler" ]; then
    profiler "$BEETOR_PATH"
elif [ "$1" = "artifact" ]; then
    artifact
fi
