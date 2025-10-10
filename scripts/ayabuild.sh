#!/bin/sh

builder() {
CCR_MODE="checker" . ./scripts/ccr.sh; checker && \
    docker compose -f ./compose.yml --progress=plain build --no-cache ayaya
}

# interactive container for manual tests
aya_repl() {

podman run \
    --rm -it \
    --entrypoint=/bin/sh \
    -v ./trace/ayaya/:/app/:ro
    rust:1.90.0-alpine3.20
}

just_build() {

OCI_TAG="ayaya-builder"
OCI_OUTPUT_DIR="/output"
TARGET_DIR="target/from-podman/"

docker build --target builder -t "${OCI_TAG}" .

}

print_usage() {
cat <<-END >&2
USAGE: ayabuild [-options]
                - repl
                - version
                - help
eg,
ayabuild -repl      # runs a container in interactive mode
                      with the rust:1.90.0-alpine3.20 image
ayabuild -version   # shows script version
ayabuild -help      # shows this help message

See the man page and example file for more info.

END

}

# Check the argument passed from the command line

if [ "$BUILD_PAR" = "-builder" ] || [ "$BUILD_PAR" = "--builder" ] || [ "$BUILD_PAR" = "builder" ]; then
    builder
elif [ "$BUILD_PAR" = "-repl" ] || [ "$BUILD_PAR" = "--repl" ] || [ "$BUILD_PAR" = "repl" ]; then
    aya_repl
elif [ "$1" = "help" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    print_usage
elif [ "$1" = "version" ] || [ "$1" = "-v" ] || [ "$1" = "--version" ]; then
    printf "version"
else
    echo "Invalid function name. Please specify one of: function1, function2, function3"
    print_usage
fi

