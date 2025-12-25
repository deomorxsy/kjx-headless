#!/bin/sh
# usgp-man: user-group management
#
# packaging variables
PACKAGING_ART_DIR="./artifacts/packaging"

SHADOW_SO_PKG="./artifacts/packaging/shadow-so-pkg.tar.gz"
SHADOW_BIN_PKG="./artifacts/packaging/shadow-so-pkg.tar.gz"
export SHADOW_SO_PKG SHADOW_BIN_PKG

# iptables shared objects and dynamically linked binaries
IPTABLES_SO_PKG="./artifacts/packaging/iptables-so-pkg.tar.gz"
IPTABLES_BIN_PKG="./artifacts/packaging/iptables-so-pkg.tar.gz"
export IPTABLES_SO_PKG IPTABLES_BIN_PKG

# podman shared objects and dynamically linked binaries
PODMAN_SO_PKG="./artifacts/packaging/podman-so-pkg.tar.gz"
PODMAN_BIN_PKG="./artifacts/packaging/podman-bin-pkg.tar.gz"
export PODMAN_SO_PKG PODMAN_BIN_PKG

# bpftrace shared objects and dynamically linked binaries
BPFTRACE_SO_PKG=""
BPFTRACE_BIN_PKG=""
export BPFTRACE_SO_PKG BPFTRACE_BIN_PKG

# build from source URIs
BFS_SHADOW_PKG_URI="https://github.com/shadow-maint/shadow/releases/download/4.18.0/shadow-4.18.0.tar.xz"
export BFS_SHADOW_PKG_URI

set_iptables() {

    # CCR_MODE="-checker" . ./scripts/ccr.sh &&
    #     docker compose -f ./compose.yml --progress=plain build --no-cache qonq_iptables
    #

    # start OCI registry server
    if ! podman start registry; then
        echo "|> WARNING: could not start OCI registry server. Attempting to run the image..."
        echo && echo
        #return 1

        # grep for lines of registries.conf that are not the demonstration of insecure = true being set,
        # i.e. those which do not have a "#" character.
        if ! (cat /etc/containers/registries.conf | grep "insecure = true" | grep -v "#"); then
            echo "|> WARNING: it seems there is no [insecure] configuration for registries running locally at localhost:5000. Attempting to redirect a heredoc to [/etc/containers/registries.conf] to configure..."

            if ! ( (
                cat <<EOF
                [[registry]]
                location = "localhost:5000"
                insecure = true
EOF
            ) >>/etc/containers/registries.conf); then
                echo "|> Error: could not redirect the [insecure] configuration for OCI registries at localhost:5000to [/etc/containers/registries.conf]. Exiting now..."
                return 1
            fi
            echo "|> Successfully redirected the [insecure] configuration for OCI registries at localhost:5000 to [/etc/containers/registries.conf]. Proceeding..."
        fi
        echo "|> Successfully found an [insecure] configuration for registries running locally at localhost:5000. Proceeding..."

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
        echo "|> Successfully built the [qonq_iptables] container with ccr.sh to use Podman Service as the compose tool. Proceeding..."
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

set_shadow() {

    CCR_MODE="-checker" . ./scripts/ccr.sh &&
        docker compose -f ./compose.yml --progress=plain build --no-cache qonq_shadow

    echo
}

main_usgp_man() {

    if ! set_shadow; then
        return 1
    fi
    echo "|> shadow setup with success."
}

print_usage() {
    cat <<-END >&2
USAGE: usgp-man [-options]
                - shadow
                - iptables
                - podman
                - bpftrace
                - all
                - version
                - help
eg,
MODE="all"          ./usgp-man.sh   # Setup all default packaging
MODE="shadow"       ./usgp-man.sh   # Setup shadow packaging
MODE="network"      ./usgp-man.sh   # Setup iptables, tc and netfilter packaging
MODE="podman"       ./usgp-man.sh   # Setup podman HLCR packaging
MODE="bpftrace"     ./usgp-man.sh   # Setup bpftrace packaging
MODE="version"      ./usgp-man.sh   # Shows script version
MODE="help"         ./usgp-man.sh   # Shows this help message

See the man page and example file for more info.

END

}

# Check the argument passed from the command line
if ! [ -z "${MODE}" ] &&
    [ "${MODE}" = "shadow" ] ||
    [ "${MODE}" = "iptables" ] ||
    [ "${MODE}" = "all" ]; then
    case "${MODE}" in
    "all")
        main_usgp_man
        ;;
    "shadow")
        set_shadow
        ;;
    "iptables")
        set_iptables # iptables, conntrack, etc
        ;;
    *)
        echo "Invalid packaging option. Please specify one of: shadow, iptables, all"
        print_usage
        ;;
    esac

elif [ "${MODE}" = "help" ] || [ "${MODE}" = "-h" ] || [ "${MODE}" = "--help" ]; then
    print_usage
elif [ "${MODE}" = "version" ] || [ "${MODE}" = "-v" ] || [ "${MODE}" = "--version" ]; then
    printf "\n|> Version: usgp-man 1.0.0"
else
    echo "Invalid function name. Please specify one of the available functions:"
    print_usage
fi
