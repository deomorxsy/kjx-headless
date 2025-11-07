#!/bin/sh

BEETOR_PATH=./scripts/libkjx/beetor

set_insec_registry() {

REG_CONF="/etc/containers/registries.conf"
LOCAL_REG_CONF="${HOME}/.config/containers/registries.conf"

DOCKER_JSON="/etc/docker/daemon.json"
LOCAL_DOCKER_JSON="${HOME}/.config/docker/daemon.json"

if [ "${GITHUB_ACTIONS}" = "true" ]; then

printf "\n|> Running on Github Actions. Creating registries.conf..."

(
cat <<EOF
# For more information on this configuration file, see containers-registries.conf(5).
#
# NOTE: RISK OF USING UNQUALIFIED IMAGE NAMES
#
# # An array of host[:port] registries to try when pulling an unqualified image, in order.
  unqualified-search-registries = ['docker.io', 'localhost:5000', 'registry.fedoraproject.org', 'registry.access.redhat.com', 'registry.centos.org']
#
[[registry]]
location = "localhost:5000"
insecure = true
#
EOF
) | tee "${LOCAL_REG_CONF}"


(
cat <<EOF
{
  "insecure-registries": ["localhost:5000"]
}
EOF
) | tee "${LOCAL_DOCKER_JSON}"

fi

}

builder() {

PROGRAM="$1"

# ci context
set_insec_registry


CCR_MODE="-checker" . ./scripts/ccr.sh  && \
    if [ "$(docker ps -a | grep registry | awk '{ print $13 }')" = "registry" ]; then
        if ! grep -q "registry" "$(docker ps | grep registry)"; then
            docker start registry
        fi
    else
        docker run -d -p 5000:5000 --name registry registry:3.0
    fi && \


if [ "${PROGRAM}" = "beetor" ]; then
	docker compose -f ./compose.yml --progress=plain build beetor && \
	docker push localhost:5000/beetor:latest && \
	docker stop registry
elif [ "${PROGRAM}" = "bwc" ]; then
	docker run -d -p 5000:5000 --name registry registry:3.0
	docker start registry && \
	docker compose -f ./compose.yml --progress=plain build bwc && \
	docker push localhost:5000/bwc:latest && \
	docker stop registry
fi


}

beetor() {
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
# valgrind, callgrind and vgdb debug

    if [ -f "$1" ]; then
        valgrind --tool=callgrind --trace-children=yes --dump-instr=yes --callgrind-out-file=./beetor.cg.out --vgdb-error=0 --collect-jumps=yes "$1"
        #valgrind --tool=callgrind --trace-children=yes --dump-instr=yes --callgrind-out-file=./bwc_off.cg.out --vgdb-error=0 --collect-jumps=yes ./bwc_off
    else
        printf "\n[profiler] File not found. exiting now...\n\n"
    fi
}





print_usage() {
cat <<-END >&2
USAGE: static_beetor [-options]
                - builder
                - profiler
                - version
                - help
eg,
static_beetor -builder PROGRAM    # builds either beetor or bwc
static_beetor -profile PROF_BIN   # profile the built binary with Valgrind for callgrind
static_beetor -version # shows script version
static_beetor -help    # shows this help message

See the man page and example file for more info.

END

}


# Check the argument passed from the command line
if [ "$MODE" = "-builder" ] || [ "$MODE" = "--builder" ] || [ "$MODE" = "builder" ]; then
    if  [ -z "${PROGRAM}" ]; then

        printf "\n|> Error: PROGRAM was either not defined or called for a different function."
        printf "\n\t|> Available Functions: beetor, bwc...\n"
        echo "Exiting now..."
        return
    elif  [ "${PROGRAM}" = "beetor" ] || [ "${PROGRAM}" = "bwc" ]; then
        builder "${PROGRAM}"
    else
        printf "\n|> Error: PROGRAM was either not defined or called for a different function."
        printf "\n\t|> Available Functions: beetor, bwc...\n"
        echo "Exiting now..."
        return
    fi
elif [ "$MODE" = "-profiler" ] || [ "$MODE" = "--profiler" ] || [ "$MODE" = "profiler" ]; then
    if ! [ -z "${PROF_BIN}" ] || ! [ -f "${PROF_BIN}" ]; then
        # printf "\n|> Error: the profiler() function of static_beetor must have an argument. Try again! \n\n"
        printf "\n|> Error: PROF_BIN was either not defined or called for a different function."
        printf "\n\t|> Available Functions: XXXX, YYYY"
        echo "Exiting now..."
        return
    fi
    profiler "${PROF_ARG}"
elif [ "$MODE" = "help" ] || [ "$MODE" = "-h" ] || [ "$MODE" = "--help" ]; then
    echo
    print_usage
elif [ "$MODE" = "version" ] || [ "$MODE" = "-v" ] || [ "$MODE" = "--version" ]; then
    echo
    printf "version"
else
    echo
    echo "Invalid function name. Please specify one of: function1, function2, function3"
    print_usage
fi

