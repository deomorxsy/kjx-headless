#!/bin/sh

#!/bin/sh

# PKG_ISODIR_INITRAMFS="./artifacts/burn/initramfs/initramfs.cpio.gz"

initramfs_tarball() {

    # rename with prefix [PKG_] due to warnings about changing the value in a subshell
    # at [./scripts/isogen/initramfs.sh]
    PKG_TEMP_INITRAMFS="./artifacts/packages/initramfs.cpio.gz"

    #CCR_MODE="-checker" . ./scripts/ccr.sh &&
    #    docker compose -f ./compose.yml --progress=plain build --no-cache initramfs

    # start OCI registry server
    if ! podman start registry; then
        echo "|> Error: could not start OCI registry server. Attempting to run the image..."
        echo "|> SCOPE: [initramfs_tarball], file: [./scripts/packages/initramfs-setup.sh], check: 01"
        echo && echo
        #return 1

        # run the registry:3.0 container image.
        if ! (podman run -d -p 5000:5000 --name registry registry:3.0); then
            echo "|> Error: could not run the registry:3.0 container image. Exiting now..."
            echo "|> SCOPE: [initramfs_tarball], file: [./scripts/packages/initramfs-setup.sh], check: 02"
            echo && echo
            return 1
        fi
        echo "|> Ran the OCI registry server with success. Proceeding..."
        echo "|> SCOPE: [initramfs_tarball], file: [./scripts/packages/initramfs-setup.sh], check: 02"
        echo && echo
    fi
    echo "|> OCI registry server started with success"
    echo "|> SCOPE: [initramfs_tarball], file: [./scripts/packages/initramfs-setup.sh], check: 01"

    # check if the image already exists
    if ! (podman images | grep "localhost:5000/initramfs" | awk '{print $1}'); then
        echo "|> Error: could not find the localhost:5000/initramfs image at the OCI registry:3.0 server. Attempting to build now..."
        echo "|> SCOPE: [initramfs_tarball], file: [./scripts/packages/initramfs-setup.sh], check: 03"
        echo && echo
        # return 1
        # Build the initramfs container with ccr.sh to use  Podman Service as the compose tool
        if ! CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose -f ./compose.yml --progress=plain build --no-cache initramfs; then
            echo "|> Error: could not run the ccr.sh script for Podman Service as the compose tool. Exiting now..."
            echo "|> SCOPE: [initramfs_tarball], file: [./scripts/packages/initramfs-setup.sh], check: 04"
            echo && echo
            return 1

        fi
        echo "|> Build the initramfs container with ccr.sh to use  Podman Service as the compose tool with success. Proceeding..."
        echo "|> SCOPE: [initramfs_tarball], file: [./scripts/packages/initramfs-setup.sh], check: 04"
        echo && echo

        # push built image into the registry:3.0 localhost:5000 server container.
        if ! podman push localhost:5000/initramfs:latest; then
            echo "|> Error: could not push the built initramfs image into the registry:3.0 localhost:5000 server container. Exiting now..."
            echo "|> SCOPE: [initramfs_tarball], file: [./scripts/packages/initramfs-setup.sh], check: 05"
            echo && echo
            return 1
        fi
        echo "|> Pushed built image into the registry:3.0 localhost:5000 server container. Proceeding..."
        echo "|> SCOPE: [initramfs_tarball], file: [./scripts/packages/initramfs-setup.sh], check: 05"
        echo && echo
    fi
    echo "|> initramfs image found at the localhost:5000/initramfs OCI registry:3.0 server. Proceeding..."
    echo "|> SCOPE: [initramfs_tarball], file: [./scripts/packages/initramfs-setup.sh], check: 03"

    # Create the built initramfs container
    # podman run -it --name initramfs -d localhost:5000/initramfs:latest
    if ! (CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose -f ./compose.yml create initramfs); then
        echo "|> Error: could not create the built initramfs container using the ccr.sh script to use Podman Service as the compose tool"
        echo "|> SCOPE: [initramfs_tarball], file: [./scripts/packages/initramfs-setup.sh], check: 06"
        echo && echo
        return 1
    fi
    echo "|> Created the built initramfs container using the ccr.sh script to use Podman Service as the compose tool with success. Proceeding..."
    echo "|> SCOPE: [initramfs_tarball], file: [./scripts/packages/initramfs-setup.sh], check: 06"
    echo && echo

    # check created containers
    CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose ps --all

    # check for the initramfs image at localhost:5000/initramfs
    podman images | grep "localhost:5000/initramfs" | awk '{print $1}'

    # copy initramfs tarball into the ./artifacts/isogen directory.
    mkdir -p ./artifacts/isogen
    if ! (podman cp initramfs:./initramfs.cpio.gz "${PKG_TEMP_INITRAMFS:-[EMPTY_VARIABLE]}"); then
        echo "|> Error: could not copy the initramfs tarball to the initramfs_CPIO_GZ=${PKG_TEMP_INITRAMFS:-[EMPTY_VARIABLE]} filepath. Exiting now..."
        echo "|> SCOPE: [initramfs_tarball], file: [./scripts/packages/initramfs-setup.sh], check: 07"
        return 1
    fi
    echo "|> Copied initramfs tarball into the initramfs_CPIO_GZ=${PKG_TEMP_INITRAMFS:-[EMPTY_VARIABLE]} filepath with success. Proceeding... "
    echo "|> SCOPE: [initramfs_tarball], file: [./scripts/packages/initramfs-setup.sh], check: 07"

    # Stop container registry
    if ! (podman stop registry); then
        echo "|> Error: could not stop the OCI registry server! Exiting now..."
        echo "|> SCOPE: [initramfs_tarball], file: [./scripts/packages/initramfs-setup.sh], check: 08"
        echo && echo
        return 1
    fi
    echo "|> Successfully stopped the OCI registry server."
    echo "|> SCOPE: [initramfs_tarball], file: [./scripts/packages/initramfs-setup.sh], check: 08"
    echo && echo

}

# Check the argument passed from the command line
if ! [ -z "${MODE}" ] &&
    [ "${MODE}" = "tarball" ]; then
    case "${MODE}" in
    "tarball")
        initramfs_tarball
        ;;
    *)
        echo "Invalid initramfs option. Please specify one of: tarball"
        print_usage
        ;;
    esac

elif [ "${MODE}" = "help" ] || [ "${MODE}" = "-h" ] || [ "${MODE}" = "--help" ]; then
    print_usage
elif [ "${MODE}" = "version" ] || [ "${MODE}" = "-v" ] || [ "${MODE}" = "--version" ]; then
    echo "|> Version: initramfs-setup.sh 1.0.0"
else
    echo "Invalid function name. Please specify one of the available functions:"
    print_usage
fi
