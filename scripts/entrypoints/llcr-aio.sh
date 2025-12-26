#!/bin/sh

PODMAN_PACKAGING_DIRECTORY="./artifacts/packaging/llcr-aio/podman"
export PODMAN_PACKAGING_DIRECTORY

set_runc() {

    # CCR_MODE="-checker" . ./scripts/ccr.sh &&
    #     docker compose -f ./compose.yml --progress=plain build --no-cache qonq_runc
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

    if (podman images | grep "localhost:5000/qonq_runc"); then
        BUILT_RUNC_ALREADY=$(podman images | grep "localhost:5000/qonq_runc" | awk '{print $3}')
        export BUILT_RUNC_ALREADY

        echo "|> WARNING: found a previously built [localhost:5000/qonq_runc]. Attempting to remove image to [REBUILD]..."
        echo

        if ! (podman rmi "${BUILT_RUNC_ALREADY:-[EMPTY_VARIABLE]}" --force); then
            echo "|> Error: YOU CAN (NOT) REDO the container image. Literally, it cannot be removed for some reason. No pun intended (or was it?). Exiting now... :)"
            echo
            return 1
        fi
        echo "|> Error: YOU (CAN) REDO the container image. Proceeding..."
    fi
    echo "|> WARNING: previously built [localhost:5000/qonq_runc] removed with sucess. ...[PASSED]"
    #
    if ! (podman images | grep "localhost:5000/qonq_runc"); then
        echo "|> Error: could not find the localhost:5000/qonq_runc image at the OCI registry:3.0 server. Attempting to build now..."
        echo && echo
        # return 1
        # Build the podman container with ccr.sh to use  Podman Service as the compose tool
        if ! (CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose -f ./compose.yml --progress=plain build --no-cache qonq_runc); then
            echo "|> Error: could not run the ccr.sh script for Podman Service as the compose tool. Exiting now..."
            echo && echo
            return 1

        fi
        echo "|> Build the [qonq_runc] container with ccr.sh to use Podman Service as the compose tool with success. Proceeding..."
        echo && echo

        # push built image into the registry:3.0 localhost:5000 server container.
        if ! (podman push localhost:5000/qonq_runc:latest); then
            echo "|> Error: could not push the built [qonq_runc] image into the OCI registry:3.0 localhost:5000 server container. Exiting now..."
            echo && echo
            return 1
        fi
        echo "|> Pushed built image into the OCI registry:3.0 localhost:5000 server container. Proceeding..."
        echo && echo
    fi
    echo "|> [qonq_runc] image found at the localhost:5000/qonq_runc OCI registry:3.0 server. Proceeding..."

    # Create the built qonq_runc container
    # podman run -it --name qonq_runc -d localhost:5000/qonq_runc:latest
    if ! (CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose -f ./compose.yml create qonq_runc); then
        echo "|> Error: could not create the built [qonq_runc] container using the ccr.sh script to use Podman Service as the compose tool"
        echo && echo
        return 1
    fi
    echo "|> Created the built [qonq_runc] container using the ccr.sh script to use Podman Service as the compose tool with success. Proceeding..."
    echo && echo

    # check created containers
    CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose ps --all

    # check for the qonq_runc image at localhost:5000/qonq_runc
    podman images | grep "localhost:5000/qonq_runc" | awk '{print $1}'

    # copy qonq_runc tarball into the ./artifacts/microvms directory.
    mkdir -p "${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]}"
    if ! podman cp qonq_runc:/app/runc-so-pkg.tar.gz "${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]}"; then
        echo "|> Error: could not copy the runc shared objects tarball to the PACKAGING_ART_DIR=${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]} filepath. Exiting now..."
        return 1
    fi
    echo "|> Copied the [qonq_runc] shared objects tarball into the PACKAGING_ART_DIR=${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]} filepath with success. Proceeding... "

    mkdir -p "${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]}"
    if ! podman cp qonq_runc:/app/runc-bin-pkg.tar.gz "${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]}"; then
        echo "|> Error: could not copy the [qonq_runc] dynamically linked binaries tarball to the PACKAGING_ART_DIR=${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]} filepath. Exiting now..."
        return 1
    fi
    echo "|> Copied the [qonq_runc] dynamically linked binaries tarball into the PACKAGING_ART_DIR=${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]} filepath with success. Proceeding... "
    # docker cp qonq_runc:/app/runc-so-pkg.tar.gz "${{ github.workspace }}"/artifacts/packaging/
    # docker cp qonq_runc:/app/runc-bin-pkg.tar.gz "${{ github.workspace }}"/artifacts/packaging/

    # Stop container registry
    if ! (podman stop registry); then
        echo "|> Error: could not stop the OCI registry server! Exiting now..."
        echo && echo
        return 1
    fi
    echo "|> Successfully stopped the OCI registry server."
    echo && echo

}

set_crun() {

    # CCR_MODE="-checker" . ./scripts/ccr.sh &&
    #     docker compose -f ./compose.yml --progress=plain build --no-cache qonq_crun
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

    if (podman images | grep "localhost:5000/qonq_crun"); then
        BUILT_CRUN_ALREADY=$(podman images | grep "localhost:5000/qonq_crun" | awk '{print $3}')
        export BUILT_CRUN_ALREADY

        echo "|> WARNING: found a previously built [localhost:5000/qonq_crun]. Attempting to remove image to [REBUILD]..."
        echo

        if ! (podman rmi "${BUILT_CRUN_ALREADY:-[EMPTY_VARIABLE]}" --force); then
            echo "|> Error: YOU CAN (NOT) REDO the container image. Literally, it cannot be removed for some reason. No pun intended (or was it?). Exiting now... :)"
            echo
            return 1
        fi
        echo "|> Error: YOU (CAN) REDO the container image. Proceeding..."
    fi
    echo "|> WARNING: previously built [localhost:5000/qonq_crun] removed with sucess. ...[PASSED]"
    #
    if ! (podman images | grep "localhost:5000/qonq_crun"); then
        echo "|> Error: could not find the localhost:5000/qonq_crun image at the OCI registry:3.0 server. Attempting to build now..."
        echo && echo
        # return 1
        # Build the podman container with ccr.sh to use  Podman Service as the compose tool
        if ! (CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose -f ./compose.yml --progress=plain build --no-cache qonq_crun); then
            echo "|> Error: could not run the ccr.sh script for Podman Service as the compose tool. Exiting now..."
            echo && echo
            return 1

        fi
        echo "|> Build the [qonq_crun] container with ccr.sh to use Podman Service as the compose tool with success. Proceeding..."
        echo && echo

        # push built image into the registry:3.0 localhost:5000 server container.
        if ! (podman push localhost:5000/qonq_crun:latest); then
            echo "|> Error: could not push the built [qonq_crun] image into the OCI registry:3.0 localhost:5000 server container. Exiting now..."
            echo && echo
            return 1
        fi
        echo "|> Pushed built image into the OCI registry:3.0 localhost:5000 server container. Proceeding..."
        echo && echo
    fi
    echo "|> [qonq_crun] image found at the localhost:5000/qonq_crun OCI registry:3.0 server. Proceeding..."

    # Create the built qonq_crun container
    # podman run -it --name qonq_crun -d localhost:5000/qonq_crun:latest
    if ! (CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose -f ./compose.yml create qonq_crun); then
        echo "|> Error: could not create the built [qonq_crun] container using the ccr.sh script to use Podman Service as the compose tool"
        echo && echo
        return 1
    fi
    echo "|> Created the built [qonq_crun] container using the ccr.sh script to use Podman Service as the compose tool with success. Proceeding..."
    echo && echo

    # check created containers
    CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose ps --all

    # check for the qonq_crun image at localhost:5000/qonq_crun
    podman images | grep "localhost:5000/qonq_crun" | awk '{print $1}'

    # copy qonq_crun tarball into the ./artifacts/microvms directory.
    mkdir -p "${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]}"
    if ! podman cp qonq_crun:/app/crun-so-pkg.tar.gz "${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]}"; then
        echo "|> Error: could not copy the crun shared objects tarball to the PACKAGING_ART_DIR=${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]} filepath. Exiting now..."
        return 1
    fi
    echo "|> Copied the [qonq_crun] shared objects tarball into the PACKAGING_ART_DIR=${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]} filepath with success. Proceeding... "

    mkdir -p "${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]}"
    if ! podman cp qonq_crun:/app/crun-bin-pkg.tar.gz "${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]}"; then
        echo "|> Error: could not copy the [qonq_crun] dynamically linked binaries tarball to the PACKAGING_ART_DIR=${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]} filepath. Exiting now..."
        return 1
    fi
    echo "|> Copied the [qonq_crun] dynamically linked binaries tarball into the PACKAGING_ART_DIR=${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]} filepath with success. Proceeding... "
    # docker cp qonq_crun:/app/crun-so-pkg.tar.gz "${{ github.workspace }}"/artifacts/packaging/
    # docker cp qonq_crun:/app/crun-bin-pkg.tar.gz "${{ github.workspace }}"/artifacts/packaging/

    # Stop container registry
    if ! (podman stop registry); then
        echo "|> Error: could not stop the OCI registry server! Exiting now..."
        echo && echo
        return 1
    fi
    echo "|> Successfully stopped the OCI registry server."
    echo && echo

}

# k3s already have one but sometimes need to be quickstarted by
# an standalone containerd UNIX socket.
set_containerd() {

    # CCR_MODE="-checker" . ./scripts/ccr.sh &&
    #     docker compose -f ./compose.yml --progress=plain build --no-cache qonq_containerd
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

    if (podman images | grep "localhost:5000/qonq_containerd"); then
        BUILT_CONTAINERD_ALREADY=$(podman images | grep "localhost:5000/qonq_containerd" | awk '{print $3}')
        export BUILT_CONTAINERD_ALREADY

        echo "|> WARNING: found a previously built [localhost:5000/qonq_containerd]. Attempting to remove image to [REBUILD]..."
        echo

        if ! (podman rmi "${BUILT_CONTAINERD_ALREADY:-[EMPTY_VARIABLE]}" --force); then
            echo "|> Error: YOU CAN (NOT) REDO the container image. Literally, it cannot be removed for some reason. No pun intended (or was it?). Exiting now... :)"
            echo
            return 1
        fi
        echo "|> Error: YOU (CAN) REDO the container image. Proceeding..."
    fi
    echo "|> WARNING: previously built [localhost:5000/qonq_containerd] removed with sucess. ...[PASSED]"
    #
    if ! (podman images | grep "localhost:5000/qonq_containerd"); then
        echo "|> Error: could not find the localhost:5000/qonq_containerd image at the OCI registry:3.0 server. Attempting to build now..."
        echo && echo
        # return 1
        # Build the podman container with ccr.sh to use  Podman Service as the compose tool
        if ! (CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose -f ./compose.yml --progress=plain build --no-cache qonq_containerd); then
            echo "|> Error: could not run the ccr.sh script for Podman Service as the compose tool. Exiting now..."
            echo && echo
            return 1

        fi
        echo "|> Build the [qonq_containerd] container with ccr.sh to use Podman Service as the compose tool with success. Proceeding..."
        echo && echo

        # push built image into the registry:3.0 localhost:5000 server container.
        if ! (podman push localhost:5000/qonq_containerd:latest); then
            echo "|> Error: could not push the built [qonq_containerd] image into the OCI registry:3.0 localhost:5000 server container. Exiting now..."
            echo && echo
            return 1
        fi
        echo "|> Pushed built image into the OCI registry:3.0 localhost:5000 server container. Proceeding..."
        echo && echo
    fi
    echo "|> [qonq_containerd] image found at the localhost:5000/qonq_containerd OCI registry:3.0 server. Proceeding..."

    # Create the built qonq_containerd container
    # podman run -it --name qonq_containerd -d localhost:5000/qonq_containerd:latest
    if ! (CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose -f ./compose.yml create qonq_containerd); then
        echo "|> Error: could not create the built [qonq_containerd] container using the ccr.sh script to use Podman Service as the compose tool"
        echo && echo
        return 1
    fi
    echo "|> Created the built [qonq_containerd] container using the ccr.sh script to use Podman Service as the compose tool with success. Proceeding..."
    echo && echo

    # check created containers
    CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose ps --all

    # check for the qonq_containerd image at localhost:5000/qonq_containerd
    podman images | grep "localhost:5000/qonq_containerd" | awk '{print $1}'

    # copy qonq_containerd tarball into the ./artifacts/microvms directory.
    mkdir -p "${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]}"
    if ! podman cp qonq_containerd:/app/containerd-so-pkg.tar.gz "${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]}"; then
        echo "|> Error: could not copy the containerd shared objects tarball to the PACKAGING_ART_DIR=${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]} filepath. Exiting now..."
        return 1
    fi
    echo "|> Copied the [qonq_containerd] shared objects tarball into the PACKAGING_ART_DIR=${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]} filepath with success. Proceeding... "

    mkdir -p "${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]}"
    if ! podman cp qonq_containerd:/app/containerd-bin-pkg.tar.gz "${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]}"; then
        echo "|> Error: could not copy the [qonq_containerd] dynamically linked binaries tarball to the PACKAGING_ART_DIR=${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]} filepath. Exiting now..."
        return 1
    fi
    echo "|> Copied the [qonq_containerd] dynamically linked binaries tarball into the PACKAGING_ART_DIR=${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]} filepath with success. Proceeding... "
    # docker cp qonq_containerd:/app/containerd-so-pkg.tar.gz "${{ github.workspace }}"/artifacts/packaging/
    # docker cp qonq_containerd:/app/containerd-bin-pkg.tar.gz "${{ github.workspace }}"/artifacts/packaging/

    # Stop container registry
    if ! (podman stop registry); then
        echo "|> Error: could not stop the OCI registry server! Exiting now..."
        echo && echo
        return 1
    fi
    echo "|> Successfully stopped the OCI registry server."
    echo && echo

}

set_youki() {
    # CCR_MODE="-checker" . ./scripts/ccr.sh &&
    #     docker compose -f ./compose.yml --progress=plain build --no-cache qonq_youki
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

    if (podman images | grep "localhost:5000/qonq_youki"); then
        BUILT_YOUKI_ALREADY=$(podman images | grep "localhost:5000/qonq_youki" | awk '{print $3}')
        export BUILT_YOUKI_ALREADY

        echo "|> WARNING: found a previously built [localhost:5000/qonq_youki]. Attempting to remove image to [REBUILD]..."
        echo

        if ! (podman rmi "${BUILT_YOUKI_ALREADY:-[EMPTY_VARIABLE]}" --force); then
            echo "|> Error: YOU CAN (NOT) REDO the container image. Literally, it cannot be removed for some reason. No pun intended (or was it?). Exiting now... :)"
            echo
            return 1
        fi
        echo "|> Error: YOU (CAN) REDO the container image. Proceeding..."
    fi
    echo "|> WARNING: previously built [localhost:5000/qonq_youki] removed with sucess. ...[PASSED]"
    #
    if ! (podman images | grep "localhost:5000/qonq_youki"); then
        echo "|> Error: could not find the localhost:5000/qonq_youki image at the OCI registry:3.0 server. Attempting to build now..."
        echo && echo
        # return 1
        # Build the podman container with ccr.sh to use  Podman Service as the compose tool
        if ! (CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose -f ./compose.yml --progress=plain build --no-cache qonq_youki); then
            echo "|> Error: could not run the ccr.sh script for Podman Service as the compose tool. Exiting now..."
            echo && echo
            return 1

        fi
        echo "|> Build the [qonq_youki] container with ccr.sh to use Podman Service as the compose tool with success. Proceeding..."
        echo && echo

        # push built image into the registry:3.0 localhost:5000 server container.
        if ! (podman push localhost:5000/qonq_youki:latest); then
            echo "|> Error: could not push the built [qonq_youki] image into the OCI registry:3.0 localhost:5000 server container. Exiting now..."
            echo && echo
            return 1
        fi
        echo "|> Pushed built image into the OCI registry:3.0 localhost:5000 server container. Proceeding..."
        echo && echo
    fi
    echo "|> [qonq_youki] image found at the localhost:5000/qonq_youki OCI registry:3.0 server. Proceeding..."

    # Create the built qonq_youki container
    # podman run -it --name qonq_youki -d localhost:5000/qonq_youki:latest
    if ! (CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose -f ./compose.yml create qonq_youki); then
        echo "|> Error: could not create the built [qonq_youki] container using the ccr.sh script to use Podman Service as the compose tool"
        echo && echo
        return 1
    fi
    echo "|> Created the built [qonq_youki] container using the ccr.sh script to use Podman Service as the compose tool with success. Proceeding..."
    echo && echo

    # check created containers
    CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose ps --all

    # check for the qonq_youki image at localhost:5000/qonq_youki
    podman images | grep "localhost:5000/qonq_youki" | awk '{print $1}'

    # copy qonq_youki tarball into the ./artifacts/microvms directory.
    mkdir -p "${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]}"
    if ! podman cp qonq_youki:/app/youki-so-pkg.tar.gz "${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]}"; then
        echo "|> Error: could not copy the podman shared objects tarball to the PACKAGING_ART_DIR=${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]} filepath. Exiting now..."
        return 1
    fi
    echo "|> Copied the [qonq_youki] shared objects tarball into the PACKAGING_ART_DIR=${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]} filepath with success. Proceeding... "

    mkdir -p "${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]}"
    if ! podman cp qonq_youki:/app/youki-bin-pkg.tar.gz "${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]}"; then
        echo "|> Error: could not copy the [qonq_youki] dynamically linked binaries tarball to the PACKAGING_ART_DIR=${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]} filepath. Exiting now..."
        return 1
    fi
    echo "|> Copied the [qonq_youki] dynamically linked binaries tarball into the PACKAGING_ART_DIR=${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]} filepath with success. Proceeding... "
    # docker cp qonq_youki:/app/youki-so-pkg.tar.gz "${{ github.workspace }}"/artifacts/packaging/
    # docker cp qonq_youki:/app/youki-bin-pkg.tar.gz "${{ github.workspace }}"/artifacts/packaging/

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

    if ! (set_runc); then
        echo "|> Error: could not run [set_runc]. Exiting now..."
        echo "|> SCOPE: [set_tarball], file [./scripts/entrypoints/llcr-aio.sh]; check: 01"
        echo
        return 1
    fi
    echo "|> Sucessfully ran [set_runc]. Proceeding..."

    if ! (set_crun); then
        echo "|> Error: could not run [set_crun]. Exiting now..."
        echo "|> SCOPE: [set_tarball], file [./scripts/entrypoints/llcr-aio.sh]; check: 02"
        echo
        return 1
    fi
    echo "|> Sucessfully ran [set_crun]. Proceeding..."

    if ! (set_containerd); then
        echo "|> Error: could not run [set_containerd]. Exiting now..."
        echo "|> SCOPE: [set_tarball], file [./scripts/entrypoints/llcr-aio.sh]; check: 03"
        echo
        return 1
    fi
    echo "|> Sucessfully ran [set_containerd]. Proceeding..."
    echo "|> SCOPE: [set_tarball], file [./scripts/entrypoints/llcr-aio.sh]; check: 03"

    if ! (set_youki); then
        echo "|> Error: could not run [set_youki]. Exiting now..."
        echo "|> SCOPE: [set_tarball], file [./scripts/entrypoints/llcr-aio.sh]; check: 04"
        echo
        return 1
    fi
    echo "|> Sucessfully ran [set_youki]. Proceeding..."
    echo "|> SCOPE: [set_tarball], file [./scripts/entrypoints/llcr-aio.sh]; check: 04"

}

print_usage() {
    cat <<-END >&2
USAGE: llcr-aio.sh [-options]
                - runc
                - crun
                - containerd
                - youki
                - tarball
                - version
                - help
eg,
MODE="runc"         . ./llcr-aio.sh   # setup runc tarball
MODE="crun"         . ./llcr-aio.sh   # setup crun tarball
MODE="containerd"   . ./llcr-aio.sh   # setup containerd tarball
MODE="youki"        . ./llcr-aio.sh   # setup youki tarball
MODE="tarball"      . ./llcr-aio.sh   # create a single llcr-aio tarball
MODE="version"      . ./llcr-aio.sh   # shows script version
MODE="help"         . ./llcr-aio.sh   # shows this help message

See the man page and example file for more info.

END

}

# Check the argument passed from the command line
if ! [ -z "${MODE}" ] &&
    [ "${MODE}" = "runc" ] ||
    [ "${MODE}" = "crun" ] ||
    [ "${MODE}" = "containerd" ] ||
    [ "${MODE}" = "youki" ] ||
    [ "${MODE}" = "tarball" ]; then
    case "${MODE}" in
    "runc") set_runc ;;
    "crun") set_crun ;;
    "containerd") set_containerd ;;
    "youki") set_youki ;;
    "tarball") set_aio ;;
    *)
        echo "|> Error: Invalid function name. Please specify one of the available functions: runc, crun, containerd, youki, tarball."
        print_usage
        ;;
    esac

elif [ "${MODE}" = "help" ] || [ "${MODE}" = "-h" ] || [ "${MODE}" = "--help" ]; then
    print_usage
elif [ "${MODE}" = "version" ] || [ "${MODE}" = "-v" ] || [ "${MODE}" = "--version" ]; then
    printf "\n|> Version: llcr-aio 1.0.0"
else
    echo "|> Error: Invalid function name. Please specify one of the available functions: runc, crun, containerd, youki, tarball."
    print_usage
fi
