#!/bin/sh
#
LFS=/mnt/kjh
#LFS_UUID=$()
LFS_UUID=/dev/sda1/
QCOW_FILE="./utils/storage/kjh.qcow2"

create_qcow2() {

if [ ! -e $QCOW_FILE ]; then
    echo "Creating qcow2 image..."
    qemu-img create -f qcow2 $QCOW_FILE 5G
    guestmount -a $QCOW_FILE -i --ro /mnt
fi
}

mount_qcow2(){

if [ -e $QCOW_FILE ]; then
    echo "Mounting qcow2 image into /mnt..."
    guestmount -a $QCOW_FILE -i --ro /mnt
fi
}

block_export() {
# block export
touch mount-point
qemu-storage-daemon \
    --block-dev node-name=prot-node,driver=file,filename="$QCOW_FILE" \
    --block-dev node-name=fmt-node,driver=qcow2,file=prot-node \
    --export \
    type=fuse,id=exp0,node-name=fmt-node,mountpoint=mount-point,writable=on
}

part_mount() {
mkdir -pv $LFS
mount -v -t ext4 "$LFS_UUID" "$LFS"
$LFS
}
