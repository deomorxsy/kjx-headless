#!/bin/sh
# Microvm artifact variables
MICROVM_GVISOR_TARBALL="./artifacts/microvms/gvisor-core.tar.gz"
MICROVM_FIRECRACKER_TARBALL="./artifacts/microvms/firecracker-containerd.tar.gz"
MICROVM_KATA_TARBALL="./artifacts/microvms/kata-containerd.tar.gz"

MICROVM_ART_DIR="./artifacts/microvms"

if ! [ -d "${MICROVM_ART_DIR:-[EMPTY_VARIABLE]}" ]; then
    echo "|> Error: [MICROVM_ART_DIR=${MICROVM_ART_DIR:-[EMPTY_VARIABLE]}] does not exist. Attempting to create..."
    echo "|> SCOPE: [global], file: [./scripts/entrypoints/microvms.sh], check: 01"

    if ! (mkdir -p); then
        echo "|> Error: could not create [MICROVM_ART_DIR=${MICROVM_ART_DIR:-[EMPTY_VARIABLE]}] directory. Exiting now..."
        echo "|> SCOPE: [global], file: [./scripts/entrypoints/microvms.sh], check: 02"
        return 1
    fi
    echo "|> Successfully created [MICROVM_ART_DIR=${MICROVM_ART_DIR:-[EMPTY_VARIABLE]}] directory. Proceeding..."
    echo "|> SCOPE: [global], file: [./scripts/entrypoints/microvms.sh], check: 02"
fi
echo "|> Successfully found [MICROVM_ART_DIR=${MICROVM_ART_DIR:-[EMPTY_VARIABLE]}] directory. Proceeding..."
echo "|> SCOPE: [global], file: [./scripts/entrypoints/microvms.sh], check: 01"

mvm_aio() {

    #MODE="microvm, hlcr" STACK="firecracker, podman" . ./scripts/qonq-qdb.sh
    MODE="microvm" STACK="firecracker, gvisor, kata" . ./scripts/qonq-qdb.sh
}

mvm_firecracker() {

    #CCR_MODE="-checker" . ./scripts/ccr.sh &&
    #    docker compose -f ./compose.yml --progress=plain build --no-cache firecracker
    #
    # start OCI registry server
    if ! podman start registry; then
        echo "|> Error: could not start OCI registry sever. Attempting to run the image..."
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
    if ! (podman images | grep "localhost:5000/firecracker" | awk '{print $1}'); then
        echo "|> Error: could not find the localhost:5000/firecracker image at the OCI registry:3.0 server. Attempting to build now..."
        echo && echo
        # return 1
        # Build the firecracker container with ccr.sh to use  Podman Service as the compose tool
        if ! CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose -f ./compose.yml --progress=plain build --no-cache firecracker; then
            echo "|> Error: could not run the ccr.sh script for Podman Service as the compose tool. Exiting now..."
            echo && echo
            return 1

        fi
        echo "|> Build the firecracker container with ccr.sh to use  Podman Service as the compose tool with success. Proceeding..."
        echo && echo

        # push built image into the registry:3.0 localhost:5000 server container.
        if ! podman push localhost:5000/firecracker:latest; then
            echo "|> Error: could not push the built firecracker image into the registry:3.0 localhost:5000 server container. Exiting now..."
            echo && echo
            return 1
        fi
        echo "|> Pushed built image into the registry:3.0 localhost:5000 server container. Proceeding..."
        echo && echo
    fi
    echo "|> firecracker image found at the localhost:5000/firecracker OCI registry:3.0 server. Proceeding..."

    # Create the built firecracker container
    # podman run -it --name firecracker -d localhost:5000/firecracker:latest
    if ! (CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose -f ./compose.yml create firecracker); then
        echo "|> Error: could not create the built firecracker container using the ccr.sh script to use Podman Service as the compose tool"
        echo && echo
        return 1
    fi
    echo "|> Created the built firecracker container using the ccr.sh script to use Podman Service as the compose tool with success. Proceeding..."
    echo && echo

    # check created containers
    CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose ps --all

    # check for the firecracker image at localhost:5000/firecracker
    podman images | grep "localhost:5000/firecracker" | awk '{print $1}'

    # copy firecracker tarball into the ./artifacts/microvms directory.
    mkdir -p ./artifacts/microvms/
    if ! podman cp firecracker:/firecracker-core.tar.gz ${MICROVM_FIRECRACKER_TARBALL:-[EMPTY_VARIABLE]}; then
        echo "|> Error: could not copy the firecracker tarball to the MICROVM_FIRECRACKER_TARBALL=${MICROVM_FIRECRACKER_TARBALL:-[EMPTY_VARIABLE]} filepath. Exiting now..."
        return 1
    fi
    echo "|> Copied firecracker tarball into the MICROVM_FIRECRACKER_TARBALL=${MICROVM_FIRECRACKER_TARBALL:-[EMPTY_VARIABLE]} filepath with success. Proceeding... "

    # Stop container registry
    if ! (podman stop registry); then
        echo "|> Error: could not stop the OCI registry server! Exiting now..."
        echo && echo
        return 1
    fi
    echo "|> Successfully stopped the OCI registry server."
    echo && echo

}

mvm_gvisor() {

    #CCR_MODE="-checker" . ./scripts/ccr.sh &&
    #    docker compose -f ./compose.yml --progress=plain build --no-cache gvisor

    # start OCI registry server
    if ! podman start registry; then
        echo "|> Error: could not start OCI registry sever. Attempting to run the image..."
        echo "|> SCOPE: [mvm_gvisor], file: [./scripts/entrypoints/microvms.sh], check: 01"
        echo && echo
        #return 1

        # run the registry:3.0 container image.
        if ! (podman run -d -p 5000:5000 --name registry registry:3.0); then
            echo "|> Error: could not run the registry:3.0 container image. Exiting now..."
            echo "|> SCOPE: [mvm_gvisor], file: [./scripts/entrypoints/microvms.sh], check: 02"
            echo && echo
            return 1
        fi
        echo "|> Ran the OCI registry server with success. Proceeding..."
        echo "|> SCOPE: [mvm_gvisor], file: [./scripts/entrypoints/microvms.sh], check: 02"
        echo && echo
    fi
    echo "|> OCI registry server started with success"
    echo "|> SCOPE: [mvm_gvisor], file: [./scripts/entrypoints/microvms.sh], check: 01"

    # check if the image already exists
    if ! (podman images | grep "localhost:5000/gvisor" | awk '{print $1}'); then
        echo "|> Error: could not find the localhost:5000/gvisor image at the OCI registry:3.0 server. Attempting to build now..."
        echo "|> SCOPE: [mvm_gvisor], file: [./scripts/entrypoints/microvms.sh], check: 03"
        echo && echo
        # return 1
        # Build the gvisor container with ccr.sh to use  Podman Service as the compose tool
        if ! CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose -f ./compose.yml --progress=plain build --no-cache gvisor; then
            echo "|> Error: could not run the ccr.sh script for Podman Service as the compose tool. Exiting now..."
            echo "|> SCOPE: [mvm_gvisor], file: [./scripts/entrypoints/microvms.sh], check: 04"
            echo && echo
            return 1

        fi
        echo "|> Build the gvisor container with ccr.sh to use  Podman Service as the compose tool with success. Proceeding..."
        echo "|> SCOPE: [mvm_gvisor], file: [./scripts/entrypoints/microvms.sh], check: 04"
        echo && echo

        # push built image into the registry:3.0 localhost:5000 server container.
        if ! podman push localhost:5000/gvisor:latest; then
            echo "|> Error: could not push the built gvisor image into the registry:3.0 localhost:5000 server container. Exiting now..."
            echo "|> SCOPE: [mvm_gvisor], file: [./scripts/entrypoints/microvms.sh], check: 05"
            echo && echo
            return 1
        fi
        echo "|> Pushed built image into the registry:3.0 localhost:5000 server container. Proceeding..."
        echo "|> SCOPE: [mvm_gvisor], file: [./scripts/entrypoints/microvms.sh], check: 05"
        echo && echo
    fi
    echo "|> gvisor image found at the localhost:5000/gvisor OCI registry:3.0 server. Proceeding..."
    echo "|> SCOPE: [mvm_gvisor], file: [./scripts/entrypoints/microvms.sh], check: 03"

    # Create the built gvisor container
    # podman run -it --name gvisor -d localhost:5000/gvisor:latest
    if ! (CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose -f ./compose.yml create gvisor); then
        echo "|> Error: could not create the built gvisor container using the ccr.sh script to use Podman Service as the compose tool"
        echo "|> SCOPE: [mvm_gvisor], file: [./scripts/entrypoints/microvms.sh], check: 06"
        echo && echo
        return 1
    fi
    echo "|> Created the built gvisor container using the ccr.sh script to use Podman Service as the compose tool with success. Proceeding..."
    echo "|> SCOPE: [mvm_gvisor], file: [./scripts/entrypoints/microvms.sh], check: 06"
    echo && echo

    # check created containers
    CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose ps --all

    # check for the gvisor image at localhost:5000/gvisor
    podman images | grep "localhost:5000/gvisor" | awk '{print $1}'

    # copy gvisor tarball into the ./artifacts/microvms directory.
    mkdir -p ./artifacts/microvms/
    if ! podman cp gvisor:/gvisor-core.tar.gz ${MICROVM_GVISOR_TARBALL:-[EMPTY_VARIABLE]}; then
        echo "|> Error: could not copy the gvisor tarball to the MICROVM_GVISOR_TARBALL=${MICROVM_GVISOR_TARBALL:-[EMPTY_VARIABLE]} filepath. Exiting now..."
        echo "|> SCOPE: [mvm_gvisor], file: [./scripts/entrypoints/microvms.sh], check: 07"
        return 1
    fi
    echo "|> Copied gvisor tarball into the MICROVM_GVISOR_TARBALL=${MICROVM_GVISOR_TARBALL:-[EMPTY_VARIABLE]} filepath with success. Proceeding... "
    echo "|> SCOPE: [mvm_gvisor], file: [./scripts/entrypoints/microvms.sh], check: 07"

    # Stop container registry
    if ! (podman stop registry); then
        echo "|> Error: could not stop the OCI registry server! Exiting now..."
        echo "|> SCOPE: [mvm_gvisor], file: [./scripts/entrypoints/microvms.sh], check: 08"
        echo && echo
        return 1
    fi
    echo "|> Successfully stopped the OCI registry server."
    echo "|> SCOPE: [mvm_gvisor], file: [./scripts/entrypoints/microvms.sh], check: 08"
    echo && echo

}

mvm_kata() {

    # CCR_MODE="-checker" . ./scripts/ccr.sh &&
    #     docker compose -f ./compose.yml --progress=plain build --no-cache kata
    #
    # start OCI registry server
    if ! podman start registry; then
        echo "|> Error: could not start OCI registry sever. Attempting to run the image..."
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
    if ! (podman images | grep "localhost:5000/kata" | awk '{print $1}'); then
        echo "|> Error: could not find the localhost:5000/kata image at the OCI registry:3.0 server. Attempting to build now..."
        echo && echo
        # return 1
        # Build the kata container with ccr.sh to use  Podman Service as the compose tool
        if ! CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose -f ./compose.yml --progress=plain build --no-cache kata; then
            echo "|> Error: could not run the ccr.sh script for Podman Service as the compose tool. Exiting now..."
            echo && echo
            return 1

        fi
        echo "|> Build the kata container with ccr.sh to use  Podman Service as the compose tool with success. Proceeding..."
        echo && echo

        # push built image into the registry:3.0 localhost:5000 server container.
        if ! podman push localhost:5000/kata:latest; then
            echo "|> Error: could not push the built kata image into the registry:3.0 localhost:5000 server container. Exiting now..."
            echo && echo
            return 1
        fi
        echo "|> Pushed built image into the registry:3.0 localhost:5000 server container. Proceeding..."
        echo && echo
    fi
    echo "|> kata image found at the localhost:5000/kata OCI registry:3.0 server. Proceeding..."

    # Create the built kata container
    # podman run -it --name kata -d localhost:5000/kata:latest
    if ! (CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose -f ./compose.yml create kata); then
        echo "|> Error: could not create the built kata container using the ccr.sh script to use Podman Service as the compose tool"
        echo && echo
        return 1
    fi
    echo "|> Created the built kata container using the ccr.sh script to use Podman Service as the compose tool with success. Proceeding..."
    echo && echo

    # check created containers
    CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose ps --all

    # check for the kata image at localhost:5000/kata
    podman images | grep "localhost:5000/kata" | awk '{print $1}'

    # copy kata tarball into the ./artifacts/microvms directory.
    mkdir -p ./artifacts/microvms/
    if ! podman cp kata:/kata-core.tar.gz ${MICROVM_KATA_TARBALL:-[EMPTY_VARIABLE]}; then
        echo "|> Error: could not copy the kata tarball to the MICROVM_KATA_TARBALL=${MICROVM_KATA_TARBALL:-[EMPTY_VARIABLE]} filepath. Exiting now..."
        return 1
    fi
    echo "|> Copied kata tarball into the MICROVM_KATA_TARBALL=${MICROVM_KATA_TARBALL:-[EMPTY_VARIABLE]} filepath with success. Proceeding... "

    # Stop container registry
    if ! (podman stop registry); then
        echo "|> Error: could not stop the OCI registry server! Exiting now..."
        echo && echo
        return 1
    fi
    echo "|> Successfully stopped the OCI registry server."
    echo && echo

}

print_usage() {
    cat <<-END >&2
USAGE: microvms [-options]
                - microvms-aio
                - firecracker
                - gvisor
                - kata
                - version
                - help
eg,
MODE="microvms-aio" ./microvms.sh   # Fetch dependencies for all-in-one microvms
MODE="firecracker"  ./microvms.sh   # Setup firecracker as main microvm
MODE="gvisor"       ./microvms.sh   # Setup gvisor as main microvm
MODE="kata"         ./microvms.sh   # Setup kata-containers as main microvm
MODE="version"      ./microvms.sh   # shows script version
MODE="help"         ./microvms.sh   # shows this help message

See the man page and example file for more info.

END

}

# Check the argument passed from the command line
if ! [ -z "${MODE}" ] &&
    [ "${MODE}" = "microvms-aio" ] ||
    [ "${MODE}" = "firecracker" ] ||
    [ "${MODE}" = "gvisor" ] ||
    [ "${MODE}" = "kata" ]; then
    case "${MODE}" in
    "microvms-aio")
        mvm_aio
        ;;
    "firecracker")
        mvm_firecracker
        ;;
    "gvisor")
        mvm_gvisor
        ;;
    "kata")
        mvm_kata
        ;;
    *)
        echo "Invalid microvm. Please specify one of: firecracker, gvisor, kata"
        print_usage
        ;;
    esac

elif [ "${MODE}" = "help" ] || [ "${MODE}" = "-h" ] || [ "${MODE}" = "--help" ]; then
    print_usage
elif [ "${MODE}" = "version" ] || [ "${MODE}" = "-v" ] || [ "${MODE}" = "--version" ]; then
    printf "\n|> Version: microvms 1.0.0"
else
    echo "Invalid function name. Please specify one of the available functions:"
    print_usage
fi
