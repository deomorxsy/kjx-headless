#!/bin/sh

# Run a REPL with the environment dependencies
runner() {
    podman run --rm \
        -it \
        --name="hpota_runner" \
        -v ./trace/hpota/:/app/:ro \
        --entrypoint=/bin/sh \
        elixir:1.19.1-otp-28-alpine
}

# Build OCI image
builder() {

#FETCH_REGISTRY=$(docker run -d -p 5000:5000 --name registry registry:latest)

CCR_MODE="checker" . ./scripts/ccr.sh && \
    docker run -d -p 5000:5000 --name registry registry:latest && \
    docker compose -f ./compose.yml --progress=plain build --no-cache hpota && \
    docker push localhost:5000/hpota:latest
}

# Retrieve artifact from docker image
retriever() {

# FUNCTION CALL: builder
builder

CONTAINER_NAME="hpota"
CONTAINER_CREATE="$(docker compose -f ./compose.yml create hpota)"
CONTAINER_COPY="$(docker cp hpota:/hpota.txt ./artifacts/tracers/)"

mkdir -p ./artifacts/tracers/

# Create a container: it is only needed to copy an artifact,
# so there is no need to be run.
# docker create --name hpota localhost:5000/libbpf_core:latest


CCR_MODE="checker" . ./scripts/ccr.sh && \
    if ! "${CONTAINER_CREATE}" ; then
        echo "Error: could not create the hpota container on the compose rules! Exiting now..."
        return
    # exit 1
    fi && \
    echo "|> Running hpota builder at the background..." && \

    if ! "${CONTAINER_COPY}" ; then
        echo "Error: could not copy the artifact from the ${CONTAINER_NAME} container. Exiting now..."
        return
    fi && \
    echo "|> Artifact retrieved with success."

}

print_usage() {
cat <<-END >&2
USAGE: hpota [-options]
                - builder
                - retriever
                - runner
                - version
                - help
e.g.,
hpota -builder      # builds the project
hpota -retriever    # builds the project
hpota -runner       # runs container in interactive mode
hpota -version      # shows script version
hpota -help         # shows this help message

See the man page and example file for more info.

END

}


# Check the argument passed from the command line
 if [ "$MODE" = "-builder" ] || [ "$MODE" = "--builder" ] || [ "$MODE" = "builder" ]; then
    builder
elif [ "$MODE" = "-retriever" ] || [ "$MODE" = "--retriever" ] || [ "$MODE" = "retriever" ]; then
    retriever
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


