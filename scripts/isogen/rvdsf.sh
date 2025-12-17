#!/bin/sh

# useful functions for handling
# raw virtual disk sparse files

sparseFile() {
    SPARSE_PATH="./utils/storage/eulab-hd"

    # return if the sparse filepath already exists.
    if [ -f "${SPARSE_PATH}" ]; then
        printf "\n|> FUNCTION CALL: ./scripts/isogen/rvdsf.sh"
        printf "\n|> SCOPE: sparseFile"
        printf "\n|> CHECK 01:"
        printf "\n|> return if the sparse filepath already exists. ...[FAILED]\n"

        printf "\n|> Warning: sparse filepath exists! Exiting now...\n\n"
        return
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/isogen/rvdsf.sh"
        printf "\n|> SCOPE: sparseFile"
        printf "\n|> CHECK 01:"
        printf "\n|> return if the sparse filepath already exists. ...[PASSED]\n\n"
        ;;
    esac
    printf "\n|> sparse filepath do not exist. Attempting to create...\n\n"

    # create a sparse filepath using dd.
    if ! (dd if=/dev/zero of="${SPARSE_PATH}" bs=1M count=2048); then
        printf "\n|> Error: it was not possible to create a sparse file with dd. Exiting now...\n\n"
        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/isogen/rvdsf.sh"
        printf "\n|> SCOPE: sparseFile"
        printf "\n|> CHECK 02:"
        printf "\n|> create a sparse filepath using dd. ...[PASSED]\n\n"
        ;;
    esac
    printf "\n|> a sparse filepath was created using dd with success. ...\n\n"

    # format the sparse filepath with the ext4 filesystem.
    if ! (mkfs.ext4 "${SPARSE_PATH}"); then
        printf "\n|> Error: it was not possible to format the sparse filepath with the ext4 filesystem. Exiting now...\n\n"
        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/isogen/rvdsf.sh"
        printf "\n|> SCOPE: sparseFile"
        printf "\n|> CHECK 03:"
        printf "\n|> format the sparse filepath with the ext4 filesystem. ...[PASSED]\n\n"
        ;;
    esac
    printf "\n|> the ext4 filesystem was formatted into a sparse filepath with success. ...\n\n"
}

virtStoraged() {
    QCOW_FILE="./utils/storage/eulab.qcow2"

    if ! [ -f "${QCOW_FILE}" ]; then
        echo "Creating qcow2 image..."
        qemu-img create -f qcow2 $QCOW_FILE 1G
        guestmount -a $QCOW_FILE -i --ro /mnt
    elif [ -f "${QCOW_FILE}" ]; then
        echo "Mounting qcow2 image into /mnt..."
        guestmount -a "${QCOW_FILE}" -i --ro /mnt
    fi

}

print_usage() {
    cat <<-END >&2
USAGE: rvdsf [-options]
                - sparsefile
                - virtstoraged
                - help
                - version
eg,
rvdsf -sf       # Create a Virtual Disk Sparse File with dd and mkfs.ext4.
rvdsf -vs       # Create a qcow2 file with qemu-img and mount it with libguestfs's guestmount.
rvdsf -help    # shows this help message
rvdsf -version # shows script version

See the man page and example file for more info.

END

}

# Check the argument passed from the command line
if [ "$MODE" = "-sf" ] || [ "$MODE" = "--sf" ] || [ "$MODE" = "--sparsefile" ]; then
    sparseFile
elif [ "$MODE" = "-vs" ] || [ "$MODE" = "--vs" ] || [ "$MODE" = "--virtstoraged" ]; then
    virtStoraged
elif [ "$1" = "help" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    print_usage
elif [ "$1" = "version" ] || [ "$1" = "-v" ] || [ "$1" = "--version" ]; then
    printf "\n|> kjx-headless/rvdsf version: 1.1.1\n\n"
else
    echo "Invalid function name. Please specify one of: function1, function2, function3"
    print_usage

fi
