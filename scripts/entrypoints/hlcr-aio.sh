#!/bin/sh

PACKAGING_ART_DIR="./artifacts/packaging"
export PACKAGING_ART_DIR

# this will be called with [./scripts/entrypoints/hlcr-aio.sh] before copying to the VIRTFS_ART_PATH
rootless_podman() {
    PODMAN_PACKAGING_DIRECTORY="./artifacts/packaging/llcr-aio/podman"
    export PODMAN_PACKAGING_DIRECTORY
    # avoid permission problems with crun

    # this will need users/groups configured.
    #
    (
        cat <<-EOF
    #!/bin/sh
    modprobe tun
    echo tun >>/etc/modules
    echo <USER>:100000:65536 >/etc/subuid
    echo <USER>:100000:65536 >/etc/subgid
EOF
    ) | tee "${PODMAN_PACKAGING_DIRECTORY:-[EMPTY_VARIABLE]}/set-rootless.sh"

}

set_podman() {

    ROOTLESS_REGISTRIES="./artifacts/rootless-oci/registries.conf"
    export ROOTLESS_REGISTRIES
    mkdir -p "$(dirname "${ROOTLESS_REGISTRIES:-[EMPTY_VARIABLE]}")"

    # start OCI registry server
    if ! podman start registry; then
        echo "|> WARNING: could not start OCI registry server. Attempting to run the image..."
        echo "|> SCOPE: [set_podman], file [./scripts/entrypoints/hlcr-aio.sh]; check: 01"
        echo && echo
        #return 1

        #IS_ROOTLESS_REGISTRY_TOO_OLD="$(find "${ROOTLESS_REGISTRIES:-[EMPTY_VARIABLE]}" -type f -mtime +7200)"

        if ! [ -f "${ROOTLESS_REGISTRIES:-[EMPTY_VARIABLE]}" ] || (find "${ROOTLESS_REGISTRIES:-[EMPTY_VARIABLE]}" -type f -mtime +7200); then
            echo "|> WARNING: [ROOTLESS_REGISTRIES=${ROOTLESS_REGISTRIES:-[EMPTY_VARIABLE]} filepath does not exist. Attempting to create...]"
            echo "|> SCOPE: [set_podman], file [./scripts/entrypoints/hlcr-aio.sh]; check: 02"

            if ! ( (
                cat <<EOF
[[registry]]
location = "localhost:5000"
insecure = true
EOF
            ) | tee "${ROOTLESS_REGISTRIES:-[EMPTY_VARIABLE]}"); then
                echo "|> Error: could not redirect the [insecure] configuration for OCI registries at localhost:5000 to [${ROOTLESS_REGISTRIES:-[EMPTY_VARIABLE]}]. Exiting now..."
                return 1
            fi
            echo "|> Successfully redirected the [insecure] configuration for OCI registries at localhost:5000 to [${ROOTLESS_REGISTRIES:-[EMPTY_VARIABLE]}]. Proceeding..."

        fi
        echo "|> SCOPE: [set_podman], file [./scripts/entrypoints/hlcr-aio.sh]; check: 02"

        # grep for lines of registries.conf that are not the demonstration of insecure = true being set,
        # i.e. those which do not have a "#" character.
        if ! (cat /etc/containers/registries.conf | grep "insecure = true" | grep -v "#"); then
            echo "|> WARNING: it seems there is no [insecure] configuration for registries running locally at localhost:5000. Attempting to use the rootless oci feature of Podman to set the [CONTAINERS_REGISTRIES_CONF] before running podman commands..."

            CONTAINERS_REGISTRIES_CONF="${ROOTLESS_REGISTRIES:-[EMPTY_VARIABLE]}"
            export CONTAINERS_REGISTRIES_CONF

        fi
        echo "|> Successfully set the [CONTAINERS_REGISTRIES_CONF] to point to a custom registries.conf [ROOTLESS_REGISTRIES=${ROOTLESS_REGISTRIES:-[EMPTY_VARIABLE]}]. Proceeding..."

        # run the registry:3.0 container image.
        if ! (podman run -d -p 5000:5000 --name registry registry:3.0); then
            echo "|> Error: could not run the registry:3.0 container image. Exiting now..."
            echo && echo
            return 1
        fi
        echo "|> Ran the OCI registry server with success. Proceeding..."
        echo && echo
    fi
    echo "|> OCI registry server started with success"
    echo "|> SCOPE: [set_podman], file [./scripts/entrypoints/hlcr-aio.sh]; check: 01"

    # check if the image already exists

    if (podman images | grep "localhost:5000/qonq_podman"); then
        BUILT_PODMAN_ALREADY=$(podman images | grep "localhost:5000/qonq_podman" | awk '{print $3}')
        export BUILT_PODMAN_ALREADY

        echo "|> WARNING: found a previously built [localhost:5000/qonq_podman]. Attempting to remove image to [REBUILD]..."
        echo "|> SCOPE: [set_podman], file [./scripts/entrypoints/hlcr-aio.sh]; check: 03"
        echo

        if ! (podman rmi "${BUILT_PODMAN_ALREADY:-[EMPTY_VARIABLE]}" --force); then
            echo "|> Error: YOU CAN (NOT) REDO the container image. Literally, it cannot be removed for some reason. No pun intended (or was it?). Exiting now... :)"
            echo "|> SCOPE: [set_podman], file [./scripts/entrypoints/hlcr-aio.sh]; check: 04"
            return 1
        fi
        echo "|> Error: YOU (CAN) REDO the container image. Proceeding..."
        echo "|> SCOPE: [set_podman], file [./scripts/entrypoints/hlcr-aio.sh]; check: 04"
    fi
    echo "|> WARNING: previously built [localhost:5000/qonq_podman] removed with sucess. ...[PASSED]"
    echo "|> SCOPE: [set_podman], file [./scripts/entrypoints/hlcr-aio.sh]; check: 03"
    #
    if ! (podman images | grep "localhost:5000/qonq_podman"); then
        echo "|> Error: could not find the localhost:5000/qonq_podman image at the OCI registry:3.0 server. Attempting to build now..."
        echo "|> SCOPE: [set_podman], file [./scripts/entrypoints/hlcr-aio.sh]; check: 05"
        echo && echo
        # return 1
        # Build the podman container with ccr.sh to use  Podman Service as the compose tool
        if ! (CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose -f ./compose.yml --progress=plain build --no-cache qonq_podman); then
            echo "|> Error: could not run the ccr.sh script for Podman Service as the compose tool. Exiting now..."
            echo "|> SCOPE: [set_podman], file [./scripts/entrypoints/hlcr-aio.sh]; check: 06"
            echo && echo
            return 1
        fi
        echo "|> Build the [qonq_podman] container with ccr.sh to use Podman Service as the compose tool with success. Proceeding..."
        echo "|> SCOPE: [set_podman], file [./scripts/entrypoints/hlcr-aio.sh]; check: 06"
        echo && echo

        # push built image into the registry:3.0 localhost:5000 server container.
        if ! (podman push localhost:5000/qonq_podman:latest); then
            echo "|> Error: could not push the built [qonq_podman] image into the OCI registry:3.0 localhost:5000 server container. Exiting now..."
            echo "|> SCOPE: [set_podman], file [./scripts/entrypoints/hlcr-aio.sh]; check: 07"
            return 1
        fi
        echo "|> Pushed built image into the OCI registry:3.0 localhost:5000 server container. Proceeding..."
        echo "|> SCOPE: [set_podman], file [./scripts/entrypoints/hlcr-aio.sh]; check: 07"
    fi
    echo "|> [qonq_podman] image found at the localhost:5000/qonq_podman OCI registry:3.0 server. Proceeding..."
    echo "|> SCOPE: [set_podman], file [./scripts/entrypoints/hlcr-aio.sh]; check: 05"

    # Create the built qonq_podman container
    # podman run -it --name qonq_podman -d localhost:5000/qonq_podman:latest
    if ! (CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose -f ./compose.yml create qonq_podman); then
        echo "|> Error: could not create the built [qonq_podman] container using the ccr.sh script to use Podman Service as the compose tool"
        echo "|> SCOPE: [set_podman], file [./scripts/entrypoints/hlcr-aio.sh]; check: 08"
        return 1
    fi
    echo "|> Created the built [qonq_podman] container using the ccr.sh script to use Podman Service as the compose tool with success. Proceeding..."
    echo "|> SCOPE: [set_podman], file [./scripts/entrypoints/hlcr-aio.sh]; check: 08"

    # check created containers
    CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose ps --all

    # check for the qonq_podman image at localhost:5000/qonq_podman
    podman images | grep "localhost:5000/qonq_podman" | awk '{print $1}'

    # copy qonq_podman tarball into the ./artifacts/microvms directory.
    mkdir -p "${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]}"
    if ! podman cp qonq_podman:/app/podman-tarball-pkg.tar.gz "${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]}"; then
        echo "|> Error: could not copy the podman shared objects tarball to the PACKAGING_ART_DIR=${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]} filepath. Exiting now..."
        echo "|> SCOPE: [set_podman], file [./scripts/entrypoints/hlcr-aio.sh]; check: 09"
        return 1
    fi
    echo "|> Copied the [qonq_podman] shared objects tarball into the PACKAGING_ART_DIR=${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]} filepath with success. Proceeding... "
    echo "|> SCOPE: [set_podman], file [./scripts/entrypoints/hlcr-aio.sh]; check: 09"

    # if ! podman cp qonq_podman:/app/podman-so-pkg.tar.gz "${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]}"; then
    #     echo "|> Error: could not copy the podman shared objects tarball to the PACKAGING_ART_DIR=${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]} filepath. Exiting now..."
    #     echo "|> SCOPE: [set_podman], file [./scripts/entrypoints/hlcr-aio.sh]; check: 09"
    #     return 1
    # fi
    # echo "|> Copied the [qonq_podman] shared objects tarball into the PACKAGING_ART_DIR=${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]} filepath with success. Proceeding... "
    # echo "|> SCOPE: [set_podman], file [./scripts/entrypoints/hlcr-aio.sh]; check: 09"

    # mkdir -p "${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]}"
    # if ! podman cp qonq_podman:/app/podman-bin-pkg.tar.gz "${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]}"; then
    #     echo "|> Error: could not copy the [qonq_podman] dynamically linked binaries tarball to the PACKAGING_ART_DIR=${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]} filepath. Exiting now..."
    #     echo "|> SCOPE: [set_podman], file [./scripts/entrypoints/hlcr-aio.sh]; check: 10"
    #     return 1
    # fi
    # echo "|> Copied the [qonq_podman] dynamically linked binaries tarball into the PACKAGING_ART_DIR=${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]} filepath with success. Proceeding... "
    # echo "|> SCOPE: [set_podman], file [./scripts/entrypoints/hlcr-aio.sh]; check: 10"
    # docker cp qonq_podman:/app/podman-so-pkg.tar.gz "${{ github.workspace }}"/artifacts/packaging/
    # docker cp qonq_podman:/app/podman-bin-pkg.tar.gz "${{ github.workspace }}"/artifacts/packaging/

    # Stop container registry
    if ! (podman stop registry); then
        echo "|> Error: could not stop the OCI registry server! Exiting now..."
        echo "|> SCOPE: [set_podman], file [./scripts/entrypoints/hlcr-aio.sh]; check: 10"
        return 1
    fi
    echo "|> Successfully stopped the OCI registry server."
    echo "|> SCOPE: [set_podman], file [./scripts/entrypoints/hlcr-aio.sh]; check: 10"

}

set_docker() {
    # CCR_MODE="-checker" . ./scripts/ccr.sh &&
    #     docker compose -f ./compose.yml --progress=plain build --no-cache qonq_docker
    #

    # start OCI registry server
    if ! podman start registry; then
        echo "|> Error: could not start OCI registry server. Attempting to run the image..."
        echo && echo
        #return 1

        # run the registry:3.0 container image.
        if ! (podman run -d -p 5000:5000 --name registry registry:3.0); then
            echo "|> Error: could not run the registry:3.0 container image. Exiting now..."
            echo && echo
            return 1
        fi
        echo "|> Ran the OCI registry server with success. Proceeding..."
        echo && echo
    fi
    echo "|> OCI registry server started with success"

    # check if the image already exists

    if (podman images | grep "localhost:5000/qonq_docker"); then
        BUILT_DOCKER_ALREADY=$(podman images | grep "localhost:5000/qonq_docker" | awk '{print $3}')
        export BUILT_DOCKER_ALREADY

        echo "|> WARNING: found a previously built [localhost:5000/qonq_docker]. Attempting to remove image to [REBUILD]..."
        echo

        if ! (podman rmi "${BUILT_DOCKER_ALREADY:-[EMPTY_VARIABLE]}" --force); then
            echo "|> Error: YOU CAN (NOT) REDO the container image. Literally, it cannot be removed for some reason. No pun intended (or was it?). Exiting now... :)"
            echo
            return 1
        fi
        echo "|> Error: YOU (CAN) REDO the container image. Proceeding..."
    fi
    echo "|> WARNING: previously built [localhost:5000/qonq_docker] removed with sucess. ...[PASSED]"
    #
    if ! (podman images | grep "localhost:5000/qonq_docker"); then
        echo "|> Error: could not find the localhost:5000/qonq_docker image at the OCI registry:3.0 server. Attempting to build now..."
        echo && echo
        # return 1
        # Build the podman container with ccr.sh to use  Podman Service as the compose tool
        if ! (CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose -f ./compose.yml --progress=plain build --no-cache qonq_docker); then
            echo "|> Error: could not run the ccr.sh script for Podman Service as the compose tool. Exiting now..."
            echo && echo
            return 1

        fi
        echo "|> Build the [qonq_docker] container with ccr.sh to use Podman Service as the compose tool with success. Proceeding..."
        echo && echo

        # push built image into the registry:3.0 localhost:5000 server container.
        if ! (podman push localhost:5000/qonq_docker:latest); then
            echo "|> Error: could not push the built [qonq_docker] image into the OCI registry:3.0 localhost:5000 server container. Exiting now..."
            echo && echo
            return 1
        fi
        echo "|> Pushed built image into the OCI registry:3.0 localhost:5000 server container. Proceeding..."
        echo && echo
    fi
    echo "|> [qonq_docker] image found at the localhost:5000/qonq_docker OCI registry:3.0 server. Proceeding..."

    # Create the built qonq_docker container
    # podman run -it --name qonq_docker -d localhost:5000/qonq_docker:latest
    if ! (CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose -f ./compose.yml create qonq_docker); then
        echo "|> Error: could not create the built [qonq_docker] container using the ccr.sh script to use Podman Service as the compose tool"
        echo && echo
        return 1
    fi
    echo "|> Created the built [qonq_docker] container using the ccr.sh script to use Podman Service as the compose tool with success. Proceeding..."
    echo && echo

    # check created containers
    CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose ps --all

    # check for the qonq_docker image at localhost:5000/qonq_docker
    podman images | grep "localhost:5000/qonq_docker" | awk '{print $1}'

    # copy qonq_docker tarball into the ./artifacts/microvms directory.
    mkdir -p "${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]}"
    if ! podman cp qonq_docker:/app/podman-so-pkg.tar.gz "${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]}"; then
        echo "|> Error: could not copy the docker shared objects tarball to the PACKAGING_ART_DIR=${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]} filepath. Exiting now..."
        return 1
    fi
    echo "|> Copied the [qonq_docker] shared objects tarball into the PACKAGING_ART_DIR=${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]} filepath with success. Proceeding... "

    mkdir -p "${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]}"
    if ! podman cp qonq_docker:/app/podman-bin-pkg.tar.gz "${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]}"; then
        echo "|> Error: could not copy the [qonq_docker] dynamically linked binaries tarball to the PACKAGING_ART_DIR=${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]} filepath. Exiting now..."
        return 1
    fi
    echo "|> Copied the [qonq_docker] dynamically linked binaries tarball into the PACKAGING_ART_DIR=${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]} filepath with success. Proceeding... "
    # docker cp qonq_docker:/app/podman-so-pkg.tar.gz "${{ github.workspace }}"/artifacts/packaging/
    # docker cp qonq_docker:/app/podman-bin-pkg.tar.gz "${{ github.workspace }}"/artifacts/packaging/

    # Stop container registry
    if ! (podman stop registry); then
        echo "|> Error: could not stop the OCI registry server! Exiting now..."
        echo && echo
        return 1
    fi
    echo "|> Successfully stopped the OCI registry server."
    echo && echo

}

set_crio() {

    # CCR_MODE="-checker" . ./scripts/ccr.sh &&
    #     docker compose -f ./compose.yml --progress=plain build --no-cache qonq_crio
    #

    # start OCI registry server
    if ! podman start registry; then
        echo "|> Error: could not start OCI registry server. Attempting to run the image..."
        echo && echo
        #return 1

        # run the registry:3.0 container image.
        if ! (podman run -d -p 5000:5000 --name registry registry:3.0); then
            echo "|> Error: could not run the registry:3.0 container image. Exiting now..."
            echo && echo
            return 1
        fi
        echo "|> Ran the OCI registry server with success. Proceeding..."
        echo && echo
    fi
    echo "|> OCI registry server started with success"

    # check if the image already exists

    if (podman images | grep "localhost:5000/qonq_crio"); then
        BUILT_CRIO_ALREADY=$(podman images | grep "localhost:5000/qonq_crio" | awk '{print $3}')
        export BUILT_CRIO_ALREADY

        echo "|> WARNING: found a previously built [localhost:5000/qonq_crio]. Attempting to remove image to [REBUILD]..."
        echo

        if ! (podman rmi "${BUILT_CRIO_ALREADY:-[EMPTY_VARIABLE]}" --force); then
            echo "|> Error: YOU CAN (NOT) REDO the container image. Literally, it cannot be removed for some reason. No pun intended (or was it?). Exiting now... :)"
            echo
            return 1
        fi
        echo "|> Error: YOU (CAN) REDO the container image. Proceeding..."
    fi
    echo "|> WARNING: previously built [localhost:5000/qonq_crio] removed with sucess. ...[PASSED]"
    #
    if ! (podman images | grep "localhost:5000/qonq_crio"); then
        echo "|> Error: could not find the localhost:5000/qonq_crio image at the OCI registry:3.0 server. Attempting to build now..."
        echo && echo
        # return 1
        # Build the podman container with ccr.sh to use  Podman Service as the compose tool
        if ! (CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose -f ./compose.yml --progress=plain build --no-cache qonq_crio); then
            echo "|> Error: could not run the ccr.sh script for Podman Service as the compose tool. Exiting now..."
            echo && echo
            return 1

        fi
        echo "|> Build the [qonq_crio] container with ccr.sh to use Podman Service as the compose tool with success. Proceeding..."
        echo && echo

        # push built image into the registry:3.0 localhost:5000 server container.
        if ! (podman push localhost:5000/qonq_crio:latest); then
            echo "|> Error: could not push the built [qonq_crio] image into the OCI registry:3.0 localhost:5000 server container. Exiting now..."
            echo && echo
            return 1
        fi
        echo "|> Pushed built image into the OCI registry:3.0 localhost:5000 server container. Proceeding..."
        echo && echo
    fi
    echo "|> [qonq_crio] image found at the localhost:5000/qonq_crio OCI registry:3.0 server. Proceeding..."

    # Create the built qonq_crio container
    # podman run -it --name qonq_crio -d localhost:5000/qonq_crio:latest
    if ! (CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose -f ./compose.yml create qonq_crio); then
        echo "|> Error: could not create the built [qonq_crio] container using the ccr.sh script to use Podman Service as the compose tool"
        echo && echo
        return 1
    fi
    echo "|> Created the built [qonq_crio] container using the ccr.sh script to use Podman Service as the compose tool with success. Proceeding..."
    echo && echo

    # check created containers
    CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose ps --all

    # check for the qonq_crio image at localhost:5000/qonq_crio
    podman images | grep "localhost:5000/qonq_crio" | awk '{print $1}'

    # copy qonq_crio tarball into the ./artifacts/microvms directory.
    mkdir -p "${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]}"
    if ! podman cp qonq_crio:/app/podman-so-pkg.tar.gz "${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]}"; then
        echo "|> Error: could not copy the crio shared objects tarball to the PACKAGING_ART_DIR=${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]} filepath. Exiting now..."
        return 1
    fi
    echo "|> Copied the [qonq_crio] shared objects tarball into the PACKAGING_ART_DIR=${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]} filepath with success. Proceeding... "

    mkdir -p "${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]}"
    if ! podman cp qonq_crio:/app/podman-bin-pkg.tar.gz "${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]}"; then
        echo "|> Error: could not copy the [qonq_crio] dynamically linked binaries tarball to the PACKAGING_ART_DIR=${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]} filepath. Exiting now..."
        return 1
    fi
    echo "|> Copied the [qonq_crio] dynamically linked binaries tarball into the PACKAGING_ART_DIR=${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]} filepath with success. Proceeding... "
    # docker cp qonq_crio:/app/podman-so-pkg.tar.gz "${{ github.workspace }}"/artifacts/packaging/
    # docker cp qonq_crio:/app/podman-bin-pkg.tar.gz "${{ github.workspace }}"/artifacts/packaging/

    # Stop container registry
    if ! (podman stop registry); then
        echo "|> Error: could not stop the OCI registry server! Exiting now..."
        echo && echo
        return 1
    fi
    echo "|> Successfully stopped the OCI registry server."
    echo && echo

}

set_tarball() {

    if ! (set_docker); then
        echo "|> Error: it was not possible to create the docker tarball with [set_docker]. Exiting now..."
        echo "|> SCOPE: [set_tarball], file [./scripts/entrypoints/llcr-aio.sh]; check: 02"
        return 1
    fi
    echo "|> Successfully created the docker tarball with [set_docker]. Proceeding..."
    echo "|> SCOPE: [set_tarball], file [./scripts/entrypoints/llcr-aio.sh]; check: 01"

    if ! (set_crio); then
        echo "|> Error: it was not possible to create the crio tarball with [set_crio]. Exiting now..."
        echo "|> SCOPE: [set_tarball], file [./scripts/entrypoints/llcr-aio.sh]; check: 02"
        return 1
    fi
    echo "|> Successfully created the crio tarball with [set_crio]. Proceeding..."
    echo "|> SCOPE: [set_tarball], file [./scripts/entrypoints/llcr-aio.sh]; check: 02"

    if ! (set_podman); then
        echo "|> Error: it was not possible to create the podman tarball with [set_podman]. Exiting now..."
        echo "|> SCOPE: [set_tarball], file [./scripts/entrypoints/llcr-aio.sh]; check: 03"
        return 1
    fi
    echo "|> Successfully created the podman tarball with [set_podman]. Proceeding..."
    echo "|> SCOPE: [set_tarball], file [./scripts/entrypoints/llcr-aio.sh]; check: 03"

    if ! (
        tar -czf "${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]}/hlcr-tarball.tar.gz" \
            "${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]}/podman-tarball.tar.gz" \
            "${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]}/docker-tarball.tar.gz" \
            "${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]}/crio-tarball.tar.gz"
    ); then
        echo "|> Error: it was not possible to create all-in-one tarball with [set_tarball]. Exiting now..."
        echo "|> SCOPE: [set_tarball], file [./scripts/entrypoints/llcr-aio.sh]; check: 04"
        return 1
    fi
    echo "|> Successfully created all-in-one tarball with [set_tarball]. Proceeding..."
    echo "|> SCOPE: [set_tarball], file [./scripts/entrypoints/llcr-aio.sh]; check: 04"

}

print_usage() {
    cat <<-END >&2
USAGE: llcr-aio.sh [-options]
                - podman
                - docker
                - crio
                - tarball
                - version
                - help
eg,
MODE="podman"   . ./hlcr-aio.sh   # create a single tarball of dependencies for podman
MODE="docker"   . ./hlcr-aio.sh   # create a single tarball of dependencies for docker
MODE="crio"     . ./hlcr-aio.sh   # create a single tarball of dependencies for crio
MODE="tarball"  . ./hlcr-aio.sh   # create a single tarball with all
MODE="version"  . ./hlcr-aio.sh   # shows script version
MODE="help"     . ./hlcr-aio.sh   # shows this help message

See the man page and example file for more info.

END

}

# Check the argument passed from the command line
if ! [ -z "${MODE}" ] &&
    [ "${MODE:-[EMPTY_VARIABLE]}" = "podman" ] ||
    [ "${MODE:-[EMPTY_VARIABLE]}" = "docker" ] ||
    [ "${MODE:-[EMPTY_VARIABLE]}" = "crio" ] ||
    [ "${MODE:-[EMPTY_VARIABLE]}" = "tarball" ]; then
    case "${MODE:-[EMPTY_VARIABLE]}" in
    "podman") set_podman ;;
    "docker") set_docker ;;
    "crio") set_crio ;;
    "tarball") set_tarball ;;
    *)
        echo "Invalid option. Please specify one of: bpftrace-so, bpftrace-bin, tarball"
        print_usage
        ;;
    esac

elif [ "${MODE}" = "help" ] || [ "${MODE}" = "-h" ] || [ "${MODE}" = "--help" ]; then
    print_usage
elif [ "${MODE}" = "version" ] || [ "${MODE}" = "-v" ] || [ "${MODE}" = "--version" ]; then
    printf "\n|> Version: bpftrace-setup 1.0.0"
else
    echo "Invalid function name. Please specify one of the available functions:"
    print_usage
fi
