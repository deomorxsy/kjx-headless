#!/bin/sh

# custom build
builder() {

CCR_MODE="checker" . ./scripts/ccr.sh && \
    docker compose -f ./compose.yml --progress=plain build --no-cache grafana
}

# runs it
runner() {

CCR_MODE="checker" . ./scripts/ccr.sh && \
    if ! docker compose -f ./compose.yml up -d grafana; then
        echo "Error: could not init the compose script! Exiting now..."
    fi
    printf "\n|> Exiting grafana...\n\n"

}

print_usage() {
cat <<-END >&2
USAGE: grafana [-options]
                - runner
                - builder
                - version
                - help
eg,
grafana -runner   # runs a repl for context testing
grafana -builder  # builds the project
grafana -version  # shows script version
grafana -help     # shows this help message

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


