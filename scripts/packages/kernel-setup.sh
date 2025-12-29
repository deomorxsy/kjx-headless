#!/bin/sh

#!/bin/sh

#"${PKG_TEMP_KERNEL:-[EMPTY_VARIABLE]}")

kernel_tarball() {

    #kernel_CPIO_GZ="./artifacts/packages/kernel.cpio.gz"
    PKG_ISODIR_kernel="./artifacts/burn/kernel/kernel.cpio.gz"
    PKG_TEMP_KERNEL="./artifacts/packages/bzImage-6.22"

    #CCR_MODE="-checker" . ./scripts/ccr.sh &&
    #    docker compose -f ./compose.yml --progress=plain build --no-cache kernel

    # start OCI registry server
    if ! podman start registry; then
        echo "|> Error: could not start OCI registry server. Attempting to run the image..."
        echo "|> SCOPE: [kernel_tarball], file: [./scripts/packages/kernel-setup.sh], check: 01"
        echo && echo
        #return 1

        # run the registry:3.0 container image.
        if ! (podman run -d -p 5000:5000 --name registry registry:3.0); then
            echo "|> Error: could not run the registry:3.0 container image. Exiting now..."
            echo "|> SCOPE: [kernel_tarball], file: [./scripts/packages/kernel-setup.sh], check: 02"
            echo && echo
            return 1
        fi
        echo "|> Ran the OCI registry server with success. Proceeding..."
        echo "|> SCOPE: [kernel_tarball], file: [./scripts/packages/kernel-setup.sh], check: 02"
        echo && echo
    fi
    echo "|> OCI registry server started with success"
    echo "|> SCOPE: [kernel_tarball], file: [./scripts/packages/kernel-setup.sh], check: 01"

    # check if the image already exists
    if ! (podman images | grep "localhost:5000/kernel" | awk '{print $1}'); then
        echo "|> Error: could not find the localhost:5000/kernel image at the OCI registry:3.0 server. Attempting to build now..."
        echo "|> SCOPE: [kernel_tarball], file: [./scripts/packages/kernel-setup.sh], check: 03"
        echo && echo
        # return 1
        # Build the kernel container with ccr.sh to use  Podman Service as the compose tool
        if ! CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose -f ./compose.yml --progress=plain build --no-cache kernel; then
            echo "|> Error: could not run the ccr.sh script for Podman Service as the compose tool. Exiting now..."
            echo "|> SCOPE: [kernel_tarball], file: [./scripts/packages/kernel-setup.sh], check: 04"
            echo && echo
            return 1

        fi
        echo "|> Build the kernel container with ccr.sh to use  Podman Service as the compose tool with success. Proceeding..."
        echo "|> SCOPE: [kernel_tarball], file: [./scripts/packages/kernel-setup.sh], check: 04"
        echo && echo

        # push built image into the registry:3.0 localhost:5000 server container.
        if ! podman push localhost:5000/kernel:latest; then
            echo "|> Error: could not push the built kernel image into the registry:3.0 localhost:5000 server container. Exiting now..."
            echo "|> SCOPE: [kernel_tarball], file: [./scripts/packages/kernel-setup.sh], check: 05"
            echo && echo
            return 1
        fi
        echo "|> Pushed built image into the registry:3.0 localhost:5000 server container. Proceeding..."
        echo "|> SCOPE: [kernel_tarball], file: [./scripts/packages/kernel-setup.sh], check: 05"
        echo && echo
    fi
    echo "|> kernel image found at the localhost:5000/kernel OCI registry:3.0 server. Proceeding..."
    echo "|> SCOPE: [kernel_tarball], file: [./scripts/packages/kernel-setup.sh], check: 03"

    # Create the built kernel container
    # podman run -it --name kernel -d localhost:5000/kernel:latest
    if ! (CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose -f ./compose.yml create kernel); then
        echo "|> Error: could not create the built kernel container using the ccr.sh script to use Podman Service as the compose tool"
        echo "|> SCOPE: [kernel_tarball], file: [./scripts/packages/kernel-setup.sh], check: 06"
        echo && echo
        return 1
    fi
    echo "|> Created the built kernel container using the ccr.sh script to use Podman Service as the compose tool with success. Proceeding..."
    echo "|> SCOPE: [kernel_tarball], file: [./scripts/packages/kernel-setup.sh], check: 06"
    echo && echo

    # check created containers
    CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose ps --all

    # check for the kernel image at localhost:5000/kernel
    podman images | grep "localhost:5000/kernel" | awk '{print $1}'

    # copy kernel tarball into the ./artifacts/isogen directory.
    mkdir -p ./artifacts/isogen
    if ! (podman cp kernel:/app/artifacts/bzImage "${PKG_TEMP_KERNEL:-[EMPTY_VARIABLE]}"); then
        echo "|> Error: could not copy the kernel tarball to the kernel_CPIO_GZ=${PKG_TEMP_KERNEL:-[EMPTY_VARIABLE]} filepath. Exiting now..."
        echo "|> SCOPE: [kernel_tarball], file: [./scripts/packages/kernel-setup.sh], check: 07"
        return 1
    fi
    echo "|> Copied kernel tarball into the kernel_CPIO_GZ=${PKG_TEMP_KERNEL:-[EMPTY_VARIABLE]} filepath with success. Proceeding... "
    echo "|> SCOPE: [kernel_tarball], file: [./scripts/packages/kernel-setup.sh], check: 07"

    # copy kernel tarball into the ./artifacts/isogen directory.
    mkdir -p ./artifacts/isogen
    if ! (podman cp kernel:/app/artifacts/ko_tarball.tar.gz "${PKG_TEMP_KERNEL:-[EMPTY_VARIABLE]}"); then
        echo "|> Error: could not copy the kernel tarball to the kernel_CPIO_GZ=${PKG_TEMP_KERNEL:-[EMPTY_VARIABLE]} filepath. Exiting now..."
        echo "|> SCOPE: [kernel_tarball], file: [./scripts/packages/kernel-setup.sh], check: 08"
        return 1
    fi
    echo "|> Copied kernel tarball into the kernel_CPIO_GZ=${PKG_TEMP_KERNEL:-[EMPTY_VARIABLE]} filepath with success. Proceeding... "
    echo "|> SCOPE: [kernel_tarball], file: [./scripts/packages/kernel-setup.sh], check: 08"

    # Stop container registry
    if ! (podman stop registry); then
        echo "|> Error: could not stop the OCI registry server! Exiting now..."
        echo "|> SCOPE: [kernel_tarball], file: [./scripts/packages/kernel-setup.sh], check: 09"
        echo && echo
        return 1
    fi
    echo "|> Successfully stopped the OCI registry server."
    echo "|> SCOPE: [kernel_tarball], file: [./scripts/packages/kernel-setup.sh], check: 09"
    echo && echo

}

# Check the argument passed from the command line
if ! [ -z "${MODE}" ] &&
    [ "${MODE}" = "tarball" ]; then
    case "${MODE}" in
    "tarball")
        kernel_tarball
        ;;
    *)
        echo "Invalid kernel option. Please specify one of: firecracker, kernel, kata"
        print_usage
        ;;
    esac

elif [ "${MODE}" = "help" ] || [ "${MODE}" = "-h" ] || [ "${MODE}" = "--help" ]; then
    print_usage
elif [ "${MODE}" = "version" ] || [ "${MODE}" = "-v" ] || [ "${MODE}" = "--version" ]; then
    echo "|> Version: kernel-setup.sh 1.0.0"
else
    echo "Invalid function name. Please specify one of the available functions:"
    print_usage
fi
