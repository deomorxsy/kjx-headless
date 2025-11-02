#!/bin/sh

# Run a REPL with the environment dependencies
runner() {
    podman run --rm \
        -it \
        --name="runit_runner" \
        -v ./trace/runit/:/app/:ro \
        --entrypoint=/bin/sh \
        alpine:3.22
}

# Build OCI image
builder() {

#FETCH_REGISTRY=$(docker run -d -p 5000:5000 --name registry registry:latest)

CCR_MODE="checker" . ./scripts/ccr.sh && \
    docker run -d -p 5000:5000 --name registry registry:latest && \
    docker compose -f ./compose.yml --progress=plain build runit && \
    docker push localhost:5000/runit:latest
}


print_usage() {
cat <<-END >&2
USAGE: runit [-options]
                - builder
                - retriever
                - runner
                - version
                - help
e.g.,
runit -builder      # builds the project
runit -retriever    # builds the project
runit -runner       # runs container in interactive mode
runit -version      # shows script version
runit -help         # shows this help message

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
    printf "version: 1.0.0"
else
    echo "Invalid function name. Please specify one of: function1, function2, function3"
    print_usage
fi


