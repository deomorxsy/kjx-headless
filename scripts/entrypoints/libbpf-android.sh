#!/bin/sh


builder() {

CCR_MODE="checker" . ./scripts/ccr.sh && \
    docker compose -f ./compose.yml --progress=plain build --no-cache android
}


print_usage() {
cat <<-END >&2
USAGE: libbpf-static [-options]
                - runner
                - builder
                - version
                - help
e.g.,
libbpf-static -builder  # builds the project
libbpf-static -version  # shows script version
libbpf-static -help     # shows this help message

See the man page and example file for more info.

END

}


# Check the argument passed from the command line
if [ "$MODE" = "-builder" ] || [ "$MODE" = "--builder" ] || [ "$MODE" = "builder" ]; then
    builder
elif [ "$1" = "help" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    print_usage
elif [ "$1" = "version" ] || [ "$1" = "-v" ] || [ "$1" = "--version" ]; then
    printf "version"
else
    echo "Invalid function name. Please specify one of: function1, function2, function3"
    print_usage
fi


