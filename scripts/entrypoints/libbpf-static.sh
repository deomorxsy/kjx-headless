#!/bin/sh

runner() {

CCR_MODE="checker" . ./scripts/ccr.sh && \
    docker run --rm -it     \
    -v ./assets/blazesym:/app/assets/blazesym:ro \
    -v ./assets/bpftool:/app/assets/bpftool:ro \
    -v ./assets/libbpf:/app/assets/libbpf:ro \
    -v ./assets/libbpf-bootstrap:/app/assets/libbpf-bootstrap:ro \
    -v ./trace/libbpf-core:/app/trace/libbpf-core:ro \
    --entrypoint=/bin/sh    \
    alpine:3.20


# -v ./trace/libbpf-core/:/app/:ro \
}

builder() {

CCR_MODE="checker" . ./scripts/ccr.sh && \
    docker compose -f ./compose.yml --progress=plain build --no-cache libbpf_final
}
# busybox does not have apk. resort to copy dependencies between the root filesystem instead if needed
# busybox:1.36.1-musl

synch_repos() {

submods='./assets/blazesym
./assets/bpftool
./assets/libbpf
./assets/libbpf-bootstrap
'

if command -v git > /dev/null; then
    # traverse the directories and synchronize their main branches
    printf '%s' "$submods" |
        while IFS='' read -r path
        do
            #echo "$path"
            cd "$path" || return
                if ! git pull; then
                    printf "Error: git was not able to pull the repository. Exiting now...\n"
                fi
                printf "\n|> %s was synchronized with success! \o/ \n\n." "$(basename "$path")"
            cd - > /dev/null || return
        done
    printf "\n|> Current dir: %s \n\n" "$(pwd)"
else
    printf "\n|> Error: git is not installed. Exiting now...\n\n"
fi

}

hotpatch() {

    # keep it up to date before applying patches
    synch_repos

    # Old header
    OLD_HEADER="./assets/libbpf-bootstrap/libbpf/src/libbpf_internal.h"
    #OLDH_DEPS="./assets/libbpf-bootstrap/libbpf/src/libbpf.h"

    # New header to be included by libbpf_internal.h
    NEW_HEADER="./assets/libbpf-bootstrap/libbpf/src/libbpf_internal_SEDADO.h"

    # match and replace
    # sed -i 's/#include "libbpf.h"/#include "./libbpf.h"/' ./.output/bpftool/bootstrap/libbpf/include/bpf/libbpf_internal.h
    sed 's/#include "libbpf.h"/#include "./libbpf.h"/' "${OLD_HEADER}" > "${NEW_HEADER}"

    # Create patch
    diff -Naru "${OLD_HEADER}" "${NEW_HEADER}" > ./trace/libbpf-core/libbpf_internal.patch




    diff -Naru ./assets/libbpf-bootstrap/libbpf/src/libbpf_internal.h ./new > ./file.patch


}

print_usage() {
cat <<-END >&2
USAGE: libbpf-static [-options]
                - runner
                - builder
                - version
                - help
eg,
libbpf-static -runner   # runs a repl for context testing
libbpf-static -builder  # builds the project
libbpf-static -version  # shows script version
libbpf-static -help     # shows this help message

See the man page and example file for more info.

END

}


# Check the argument passed from the command line
if [ "$MODE" = "-builder" ] || [ "$MODE" = "--builder" ] || [ "$MODE" = "builder" ]; then
    builder
elif [ "$MODE" = "-runner" ] || [ "$MODE" = "--runner" ] || [ "$MODE" = "runner" ]; then
    runner
elif [ "$1" = "help" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    print_usage
elif [ "$1" = "version" ] || [ "$1" = "-v" ] || [ "$1" = "--version" ]; then
    printf "version"
else
    echo "Invalid function name. Please specify one of: function1, function2, function3"
    print_usage
fi


