#!/bin/sh

runner() {

CCR_MODE="checker" . ./scripts/ccr.sh && \
    docker run --rm -it \
    -v ./trace/libbpf-core/:/app/:ro \
    --entrypoint=/bin/sh \
    alpine:3.20
}

builder() {

CCR_MODE="checker" . ./scripts/ccr.sh && \
    docker compose -f ./compose.yml --progress=plain build --no-cache libbpf_final
}
# busybox does not have apk. resort to copy dependencies between the root filesystem instead if needed
# busybox:1.36.1-musl


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


