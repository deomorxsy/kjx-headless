#!/bin/sh

# useful functions for handling
# raw virtual disk sparse files

sparseFile() {
    SPARSE="./utils/storage/eulab-hd"
    dd if=/dev/zero of=$SPARSE bs=1M count=2048
    mkfs.ext4 $SPARSE
}

virtStoraged() {
    QCOW_FILE="./utils/storage/eulab.qcow2"

    if [ ! -e $QCOW_FILE ]; then
        echo "Creating qcow2 image..."
        qemu-img create -f qcow2 $QCOW_FILE 1G
        guestmount -a $QCOW_FILE -i --ro /mnt
    elif [ -e $QCOW_FILE ]; then
        echo "Mounting qcow2 image into /mnt..."
        guestmount -a $QCOW_FILE -i --ro /mnt
    fi

}

print_usage() {
cat <<-END >&2
USAGE: rvdsf [-options]
                - sparseFile
                - virtStoraged
                - help
                - version
eg,
rvdsf -thirdver   # runs qemu pointing to a custom initramfs and kernel bzImage
rvdsf -dropbear  # runs qemu enabled with ssh for quick file copying between target vm and host
rvdsf -airgap  # runs qemu with files to run k3s air-gapped
rvdsf -debug # the same of thirdver but with serial and pty flags for kernel debug
rvdsf -help    # shows this help message
rvdsf -version # shows script version

See the man page and example file for more info.

END

}


# Check the argument passed from the command line
if [ "$MODE" = "-sf" ] || [ "$MODE" = "--sf" ] || [ "$MODE" = "--sparsefile" ] ; then
    sparseFile
elif [ "$MODE" = "-vs" ] || [ "$MODE" = "--vs" ] || [ "$MODE" = "--virtstoraged" ] ; then
    virtStoraged
elif [ "$1" = "help" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    print_usage
elif [ "$1" = "version" ] || [ "$1" = "-v" ] || [ "$1" = "--version" ]; then
    printf "\n|> kjx-headless/rvdsf version: 1.0.0\n\n"
else
    echo "Invalid function name. Please specify one of: function1, function2, function3"
    print_usage

fi
