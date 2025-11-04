#!/bin/sh


sparseFile() {
    SPARSE="./utils/storage/eulab-hd"
    dd if=/dev/zero of=$SPARSE bs=1M count=2048
    mkfs.ext4 $SPARSE
}

virtstoraged() {
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
