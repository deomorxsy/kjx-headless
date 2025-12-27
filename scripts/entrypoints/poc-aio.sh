#!/bin/sh

PACKAGING_ART_DIR="./artifacts/packaging"
export PACKAGING_ART_DIR

set_qemukjx() {

    ROOTLESS_REGISTRIES="./artifacts/rootless-oci/registries.conf"
    export ROOTLESS_REGISTRIES
    mkdir -p "$(dirname "${ROOTLESS_REGISTRIES:-[EMPTY_VARIABLE]}")"

    # start OCI registry server
    if ! podman start registry; then
        echo "|> WARNING: could not start OCI registry server. Attempting to run the image..."
        echo "|> SCOPE: [set_qemukjx], file [./scripts/entrypoints/poc-aio.sh.sh]; check: 01"
        echo && echo
        #return 1

        #IS_ROOTLESS_REGISTRY_TOO_OLD="$(find "${ROOTLESS_REGISTRIES:-[EMPTY_VARIABLE]}" -type f -mtime +7200)"

        if ! [ -f "${ROOTLESS_REGISTRIES:-[EMPTY_VARIABLE]}" ] || (find "${ROOTLESS_REGISTRIES:-[EMPTY_VARIABLE]}" -type f -mtime +7200); then
            echo "|> WARNING: [ROOTLESS_REGISTRIES=${ROOTLESS_REGISTRIES:-[EMPTY_VARIABLE]} filepath does not exist. Attempting to create...]"
            echo "|> SCOPE: [set_qemukjx], file [./scripts/entrypoints/poc-aio.sh.sh]; check: 02"

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
        echo "|> SCOPE: [set_qemukjx], file [./scripts/entrypoints/poc-aio.sh.sh]; check: 02"

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
    echo "|> SCOPE: [set_qemukjx], file [./scripts/entrypoints/poc-aio.sh.sh]; check: 01"

    # check if the image already exists

    if (podman images | grep "localhost:5000/qonq_qemukjx"); then
        BUILT_PODMAN_ALREADY=$(podman images | grep "localhost:5000/qonq_qemukjx" | awk '{print $3}')
        export BUILT_PODMAN_ALREADY

        echo "|> WARNING: found a previously built [localhost:5000/qonq_qemukjx]. Attempting to remove image to [REBUILD]..."
        echo "|> SCOPE: [set_qemukjx], file [./scripts/entrypoints/poc-aio.sh.sh]; check: 03"
        echo

        if ! (podman rmi "${BUILT_PODMAN_ALREADY:-[EMPTY_VARIABLE]}" --force); then
            echo "|> Error: YOU CAN (NOT) REDO the container image. Literally, it cannot be removed for some reason. No pun intended (or was it?). Exiting now... :)"
            echo "|> SCOPE: [set_qemukjx], file [./scripts/entrypoints/poc-aio.sh.sh]; check: 04"
            return 1
        fi
        echo "|> Error: YOU (CAN) REDO the container image. Proceeding..."
        echo "|> SCOPE: [set_qemukjx], file [./scripts/entrypoints/poc-aio.sh.sh]; check: 04"
    fi
    echo "|> WARNING: previously built [localhost:5000/qonq_qemukjx] removed with sucess. ...[PASSED]"
    echo "|> SCOPE: [set_qemukjx], file [./scripts/entrypoints/poc-aio.sh.sh]; check: 03"
    #
    if ! (podman images | grep "localhost:5000/qonq_qemukjx"); then
        echo "|> Error: could not find the localhost:5000/qonq_qemukjx image at the OCI registry:3.0 server. Attempting to build now..."
        echo "|> SCOPE: [set_qemukjx], file [./scripts/entrypoints/poc-aio.sh.sh]; check: 05"
        echo && echo
        # return 1
        # Build the podman container with ccr.sh to use  Podman Service as the compose tool
        if ! (CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose -f ./compose.yml --progress=plain build --no-cache qonq_qemukjx); then
            echo "|> Error: could not run the ccr.sh script for Podman Service as the compose tool. Exiting now..."
            echo "|> SCOPE: [set_qemukjx], file [./scripts/entrypoints/poc-aio.sh.sh]; check: 06"
            echo && echo
            return 1
        fi
        echo "|> Build the [qonq_qemukjx] container with ccr.sh to use Podman Service as the compose tool with success. Proceeding..."
        echo "|> SCOPE: [set_qemukjx], file [./scripts/entrypoints/poc-aio.sh.sh]; check: 06"
        echo && echo

        # push built image into the registry:3.0 localhost:5000 server container.
        if ! (podman push localhost:5000/qonq_qemukjx:latest); then
            echo "|> Error: could not push the built [qonq_qemukjx] image into the OCI registry:3.0 localhost:5000 server container. Exiting now..."
            echo "|> SCOPE: [set_qemukjx], file [./scripts/entrypoints/poc-aio.sh.sh]; check: 07"
            return 1
        fi
        echo "|> Pushed built image into the OCI registry:3.0 localhost:5000 server container. Proceeding..."
        echo "|> SCOPE: [set_qemukjx], file [./scripts/entrypoints/poc-aio.sh.sh]; check: 07"
    fi
    echo "|> [qonq_qemukjx] image found at the localhost:5000/qonq_qemukjx OCI registry:3.0 server. Proceeding..."
    echo "|> SCOPE: [set_qemukjx], file [./scripts/entrypoints/poc-aio.sh.sh]; check: 05"

    # Create the built qonq_qemukjx container
    # podman run -it --name qonq_qemukjx -d localhost:5000/qonq_qemukjx:latest
    if ! (CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose -f ./compose.yml create qonq_qemukjx); then
        echo "|> Error: could not create the built [qonq_qemukjx] container using the ccr.sh script to use Podman Service as the compose tool"
        echo "|> SCOPE: [set_qemukjx], file [./scripts/entrypoints/poc-aio.sh.sh]; check: 08"
        return 1
    fi
    echo "|> Created the built [qonq_qemukjx] container using the ccr.sh script to use Podman Service as the compose tool with success. Proceeding..."
    echo "|> SCOPE: [set_qemukjx], file [./scripts/entrypoints/poc-aio.sh.sh]; check: 08"

    # check created containers
    CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose ps --all

    # check for the qonq_qemukjx image at localhost:5000/qonq_qemukjx
    podman images | grep "localhost:5000/qonq_qemukjx" | awk '{print $1}'

    # copy qonq_qemukjx tarball into the ./artifacts/microvms directory.
    mkdir -p "${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]}"
    if ! podman cp qonq_qemukjx:/app/qemukjx-tarball-pkg.tar.gz "${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]}"; then
        echo "|> Error: could not copy the podman shared objects tarball to the PACKAGING_ART_DIR=${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]} filepath. Exiting now..."
        echo "|> SCOPE: [set_qemukjx], file [./scripts/entrypoints/poc-aio.sh.sh]; check: 09"
        return 1
    fi
    echo "|> Copied the [qonq_qemukjx] shared objects tarball into the PACKAGING_ART_DIR=${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]} filepath with success. Proceeding... "
    echo "|> SCOPE: [set_qemukjx], file [./scripts/entrypoints/poc-aio.sh.sh]; check: 09"

    # Stop container registry
    if ! (podman stop registry); then
        echo "|> Error: could not stop the OCI registry server! Exiting now..."
        echo "|> SCOPE: [set_qemukjx], file [./scripts/entrypoints/poc-aio.sh.sh]; check: 10"
        return 1
    fi
    echo "|> Successfully stopped the OCI registry server."
    echo "|> SCOPE: [set_qemukjx], file [./scripts/entrypoints/poc-aio.sh.sh]; check: 10"

}

print_usage() {
    cat <<-END >&2
USAGE: poc-aio.sh.sh [-options]
                - qemukjx
                - tarball
                - version
                - help
eg,
MODE="qemukjx"     . ./poc-aio.sh.sh   # create a single tarball of dependencies for qemukjx
MODE="tarball"  . ./poc-aio.sh.sh   # create a single tarball with all
MODE="version"  . ./poc-aio.sh.sh   # shows script version
MODE="help"     . ./poc-aio.sh.sh   # shows this help message

See the man page and example file for more info.

END

}

# Check the argument passed from the command line
if ! [ -z "${MODE}" ] &&
    [ "${MODE:-[EMPTY_VARIABLE]}" = "qemukjx" ] ||
    [ "${MODE:-[EMPTY_VARIABLE]}" = "tarball" ]; then
    case "${MODE:-[EMPTY_VARIABLE]}" in
    "qemukjx") set_qemukjx ;;
    "tarball") set_tarball ;;
    *)
        echo "Invalid option. Please specify one of: qemukjx, tarball"
        print_usage
        ;;
    esac

elif [ "${MODE}" = "help" ] || [ "${MODE}" = "-h" ] || [ "${MODE}" = "--help" ]; then
    print_usage
elif [ "${MODE}" = "version" ] || [ "${MODE}" = "-v" ] || [ "${MODE}" = "--version" ]; then
    printf "\n|> Version: poc-aio.sh 1.0.0"
else
    echo "Invalid function name. Please specify one of the available functions: qemukjx, tarball"
    print_usage
fi
