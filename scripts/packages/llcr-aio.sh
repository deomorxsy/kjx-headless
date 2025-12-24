#!/bin/sh

set_iptables() {

    # CCR_MODE="-checker" . ./scripts/ccr.sh &&
    #     docker compose -f ./compose.yml --progress=plain build --no-cache qonq_iptables
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

    if (podman images | grep "localhost:5000/qonq_iptables"); then
        BUILT_IPTABLES_ALREADY=$(podman images | grep "localhost:5000/qonq_iptables" | awk '{print $3}')
        export BUILT_IPTABLES_ALREADY

        echo "|> WARNING: found a previously built [localhost:5000/qonq_iptables]. Attempting to remove image to [REBUILD]..."
        echo

        if ! (podman rmi "${BUILT_IPTABLES_ALREADY:-[EMPTY_VARIABLE]}" --force); then
            echo "|> Error: YOU CAN (NOT) REDO the container image. Literally, it cannot be removed for some reason. No pun intended (or was it?). Exiting now... :)"
            echo
            return 1
        fi
        echo "|> Error: YOU (CAN) REDO the container image. Proceeding..."
    fi
    echo "|> WARNING: previously built [localhost:5000/qonq_iptables] removed with sucess. ...[PASSED]"
    #
    if ! (podman images | grep "localhost:5000/qonq_iptables"); then
        echo "|> Error: could not find the localhost:5000/qonq_iptables image at the OCI registry:3.0 server. Attempting to build now..."
        echo && echo
        # return 1
        # Build the iptables container with ccr.sh to use  Podman Service as the compose tool
        if ! (CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose -f ./compose.yml --progress=plain build --no-cache qonq_iptables); then
            echo "|> Error: could not run the ccr.sh script for Podman Service as the compose tool. Exiting now..."
            echo && echo
            return 1

        fi
        echo "|> Build the [qonq_iptables container with ccr.sh to use Podman Service as the compose tool with success. Proceeding..."
        echo && echo

        # push built image into the registry:3.0 localhost:5000 server container.
        if ! (podman push localhost:5000/qonq_iptables:latest); then
            echo "|> Error: could not push the built [qonq_iptables] image into the OCI registry:3.0 localhost:5000 server container. Exiting now..."
            echo && echo
            return 1
        fi
        echo "|> Pushed built image into the OCI registry:3.0 localhost:5000 server container. Proceeding..."
        echo && echo
    fi
    echo "|> [qonq_iptables] image found at the localhost:5000/qonq_iptables OCI registry:3.0 server. Proceeding..."

    # Create the built qonq_iptables container
    # podman run -it --name qonq_iptables -d localhost:5000/qonq_iptables:latest
    if ! (CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose -f ./compose.yml create qonq_iptables); then
        echo "|> Error: could not create the built [qonq_iptables] container using the ccr.sh script to use Podman Service as the compose tool"
        echo && echo
        return 1
    fi
    echo "|> Created the built [qonq_iptables] container using the ccr.sh script to use Podman Service as the compose tool with success. Proceeding..."
    echo && echo

    # check created containers
    CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose ps --all

    # check for the qonq_iptables image at localhost:5000/qonq_iptables
    podman images | grep "localhost:5000/qonq_iptables" | awk '{print $1}'

    # copy qonq_iptables tarball into the ./artifacts/microvms directory.
    mkdir -p "${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]}"
    if ! podman cp qonq_iptables:/app/iptables-so-pkg.tar.gz "${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]}"; then
        echo "|> Error: could not copy the iptables shared objects tarball to the PACKAGING_ART_DIR=${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]} filepath. Exiting now..."
        return 1
    fi
    echo "|> Copied the [qonq_iptables] shared objects tarball into the PACKAGING_ART_DIR=${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]} filepath with success. Proceeding... "

    mkdir -p "${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]}"
    if ! podman cp qonq_iptables:/app/iptables-bin-pkg.tar.gz "${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]}"; then
        echo "|> Error: could not copy the [qonq_iptables] dynamically linked binaries tarball to the PACKAGING_ART_DIR=${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]} filepath. Exiting now..."
        return 1
    fi
    echo "|> Copied the [qonq_iptables] dynamically linked binaries tarball into the PACKAGING_ART_DIR=${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]} filepath with success. Proceeding... "
    # docker cp qonq_iptables:/app/iptables-so-pkg.tar.gz "${{ github.workspace }}"/artifacts/packaging/
    # docker cp qonq_iptables:/app/iptables-bin-pkg.tar.gz "${{ github.workspace }}"/artifacts/packaging/

    # Stop container registry
    if ! (podman stop registry); then
        echo "|> Error: could not stop the OCI registry server! Exiting now..."
        echo && echo
        return 1
    fi
    echo "|> Successfully stopped the OCI registry server."
    echo && echo

}
