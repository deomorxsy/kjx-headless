#!/bin/sh
#
LFS=/mnt/kjh
#LFS_UUID=$()
LFS_UUID=/dev/sda1/

virtstoraged() {

QCOW_FILE="./utils/storage/kjh.qcow2"

if [ ! -e $QCOW_FILE ]; then
    echo "Creating qcow2 image..."
    qemu-img create -f qcow2 $QCOW_FILE 1G
    guestmount -a $QCOW_FILE -i --ro /mnt
elif [ -e $QCOW_FILE ]; then
    echo "Mounting qcow2 image into /mnt..."
    guestmount -a $QCOW_FILE -i --ro /mnt
fi

}

part_mount() {
mkdir -pv $LFS
mount -v -t ext4 "$LFS_UUID" "$LFS"
$LFS
}
