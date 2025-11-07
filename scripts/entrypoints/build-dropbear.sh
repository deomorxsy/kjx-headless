#!/bin/sh
set_insec_registry() {

REG_CONF="/etc/containers/registries.conf"
LOCAL_REG_CONF="${HOME}/.config/containers/registries.conf"

mkdir -p "$(dirname "${REG_CONF}")"
mkdir -p "$(dirname "${LOCAL_REG_CONF}")"

DOCKER_JSON="/etc/docker/daemon.json"
LOCAL_DOCKER_JSON="${HOME}/.config/docker/daemon.json"

mkdir -p "$(dirname "${DOCKER_JSON}")"
mkdir -p "$(dirname "${LOCAL_DOCKER_JSON}")"


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

# ci context
set_insec_registry


CCR_MODE="-checker" . ./scripts/ccr.sh  && \
    docker compose -f ./compose.yml --progress=plain build dropbear && \

    if [ "${GITHUB_ACTIONS}" = "true" ]; then
        if ! docker run -d -p 5000:5000 --name registry registry:3.0; then
            printf "\n|> Error: name already exists. Starting...\n"
        fi
        if ! docker start registry; then
            printf "\n|> Error: registry container does not exist. Pulling and naming...\n"
        fi

        if ! docker pull registry:3.0; then
            printf "\n|> Error: cannot pull the image specified.\n"
        fi
    else
        docker pull registry:3.0
        docker start registry:3.0

    fi && \
    docker push localhost:5000/dropbear:latest && \
    docker stop registry


}


print_usage() {
cat <<-END >&2
USAGE: build-dropbear [-options]
                - builder
                - profiler
                - version
                - help
eg,
build-dropbear -builder PROGRAM    # builds either beetor or bwc
build-dropbear -profile PROF_BIN   # profile the built binary with Valgrind for callgrind
build-dropbear -version # shows script version
build-dropbear -help    # shows this help message

See the man page and example file for more info.

END

}


# Check the argument passed from the command line
if [ "$MODE" = "-builder" ] || [ "$MODE" = "--builder" ] || [ "$MODE" = "builder" ]; then
        builder
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

