#!/bin/sh

PODMAN_PACKAGING_DIRECTORY="./artifacts/packaging/llcr-aio/podman"
export PODMAN_PACKAGING_DIRECTORY

# this will be called with [./scripts/sandbox/run-qemu.sh] before copying to the VIRTFS_ART_PATH
rootless_podman() {
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

    # CCR_MODE="-checker" . ./scripts/ccr.sh &&
    #     docker compose -f ./compose.yml --progress=plain build --no-cache qonq_podman
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

    if (podman images | grep "localhost:5000/qonq_podman"); then
        BUILT_PODMAN_ALREADY=$(podman images | grep "localhost:5000/qonq_podman" | awk '{print $3}')
        export BUILT_PODMAN_ALREADY

        echo "|> WARNING: found a previously built [localhost:5000/qonq_podman]. Attempting to remove image to [REBUILD]..."
        echo

        if ! (podman rmi "${BUILT_PODMAN_ALREADY:-[EMPTY_VARIABLE]}" --force); then
            echo "|> Error: YOU CAN (NOT) REDO the container image. Literally, it cannot be removed for some reason. No pun intended (or was it?). Exiting now... :)"
            echo
            return 1
        fi
        echo "|> Error: YOU (CAN) REDO the container image. Proceeding..."
    fi
    echo "|> WARNING: previously built [localhost:5000/qonq_podman] removed with sucess. ...[PASSED]"
    #
    if ! (podman images | grep "localhost:5000/qonq_podman"); then
        echo "|> Error: could not find the localhost:5000/qonq_podman image at the OCI registry:3.0 server. Attempting to build now..."
        echo && echo
        # return 1
        # Build the podman container with ccr.sh to use  Podman Service as the compose tool
        if ! (CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose -f ./compose.yml --progress=plain build --no-cache qonq_podman); then
            echo "|> Error: could not run the ccr.sh script for Podman Service as the compose tool. Exiting now..."
            echo && echo
            return 1

        fi
        echo "|> Build the [qonq_podman container with ccr.sh to use Podman Service as the compose tool with success. Proceeding..."
        echo && echo

        # push built image into the registry:3.0 localhost:5000 server container.
        if ! (podman push localhost:5000/qonq_podman:latest); then
            echo "|> Error: could not push the built [qonq_podman] image into the OCI registry:3.0 localhost:5000 server container. Exiting now..."
            echo && echo
            return 1
        fi
        echo "|> Pushed built image into the OCI registry:3.0 localhost:5000 server container. Proceeding..."
        echo && echo
    fi
    echo "|> [qonq_podman] image found at the localhost:5000/qonq_podman OCI registry:3.0 server. Proceeding..."

    # Create the built qonq_podman container
    # podman run -it --name qonq_podman -d localhost:5000/qonq_podman:latest
    if ! (CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose -f ./compose.yml create qonq_podman); then
        echo "|> Error: could not create the built [qonq_podman] container using the ccr.sh script to use Podman Service as the compose tool"
        echo && echo
        return 1
    fi
    echo "|> Created the built [qonq_podman] container using the ccr.sh script to use Podman Service as the compose tool with success. Proceeding..."
    echo && echo

    # check created containers
    CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose ps --all

    # check for the qonq_podman image at localhost:5000/qonq_podman
    podman images | grep "localhost:5000/qonq_podman" | awk '{print $1}'

    # copy qonq_podman tarball into the ./artifacts/microvms directory.
    mkdir -p "${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]}"
    if ! podman cp qonq_podman:/app/podman-so-pkg.tar.gz "${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]}"; then
        echo "|> Error: could not copy the podman shared objects tarball to the PACKAGING_ART_DIR=${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]} filepath. Exiting now..."
        return 1
    fi
    echo "|> Copied the [qonq_podman] shared objects tarball into the PACKAGING_ART_DIR=${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]} filepath with success. Proceeding... "

    mkdir -p "${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]}"
    if ! podman cp qonq_podman:/app/podman-bin-pkg.tar.gz "${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]}"; then
        echo "|> Error: could not copy the [qonq_podman] dynamically linked binaries tarball to the PACKAGING_ART_DIR=${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]} filepath. Exiting now..."
        return 1
    fi
    echo "|> Copied the [qonq_podman] dynamically linked binaries tarball into the PACKAGING_ART_DIR=${PACKAGING_ART_DIR:-[EMPTY_VARIABLE]} filepath with success. Proceeding... "
    # docker cp qonq_podman:/app/podman-so-pkg.tar.gz "${{ github.workspace }}"/artifacts/packaging/
    # docker cp qonq_podman:/app/podman-bin-pkg.tar.gz "${{ github.workspace }}"/artifacts/packaging/

    # Stop container registry
    if ! (podman stop registry); then
        echo "|> Error: could not stop the OCI registry server! Exiting now..."
        echo && echo
        return 1
    fi
    echo "|> Successfully stopped the OCI registry server."
    echo && echo

}

# old dependencies copy
#
old_deps() {

    # setup podman and its dependencies
    docker cp qemu_kjx:/podman-so.tar.gz "${OTHER_BINARIES_DIR}"/app/ &&
        docker cp qemu_kjx:/usr/bin/podman "${OTHER_BINARIES_DIR}"/app/ &&
        mkdir -p "${OTHER_BINARIES_DIR}"/usr/libexec/podman/ &&
        docker cp qemu_kjx:/usr/libexec/podman/netavark "${OTHER_BINARIES_DIR}"/app/ &&

        # setup netavark, aardvark-dns, rootlessport and catatonit init
        docker cp qemu_kjx:/usr/libexec/podman/netavark "${OTHER_BINARIES_DIR}"/usr/libexec/podman/netavark &&
        docker cp qemu_kjx:/usr/libexec/podman/aardvark-dns "${OTHER_BINARIES_DIR}"/usr/libexec/podman/aardvark-dns &&
        docker cp qemu_kjx:/usr/libexec/podman/rootlessport "${OTHER_BINARIES_DIR}"/usr/libexec/podman/rootlessport &&
        docker cp qemu_kjx:/usr/bin/catatonit "${OTHER_BINARIES_DIR}"/usr/bin/catatonit &&
        docker cp qemu_kjx:/usr/libexec/podman/catatonit "${OTHER_BINARIES_DIR}"/usr/libexec/podman/catatonit &&
        ln -s "${OTHER_BINARIES_DIR}"/usr/bin/catatonit "${OTHER_BINARIES_DIR}"/usr/libexec/podman/catatonit

    # get conmon
    docker cp qemu_kjx:/conmon-archive.tar.gz "${OTHER_BINARIES_DIR}"/app/ &&
        docker cp qemu_kjx:/usr/bin/conmon "${OTHER_BINARIES_DIR}"/usr/bin/

}
