#!/bin/sh
#
LFS=/mnt/kjxh
#LFS_UUID=$()
LFS_UUID=/dev/sda1/
QCOW_FILE="./utils/storage/kjxh.qcow2"

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

packaging() {


groupadd kjx
useradd -sR /bin/bash -g kjx -m -k /dev/null kjx

# get software
wget --input-file=./artifacts/wget-list-sysv.txt --continue --directory-prefix="$LFS/sources"

# start fakeroot
fakeroot
# apk-tools
cp -r ./artifacts/deps mount-point-fuse/bin
chmod +x ./mount-point-fuse/bin
ln -s ./artifacts/mount-point-fuse/bin/x mount-point-fuse/sbin/x

# soft links
sudo ln -s ./artifacts/mount-point-fuse/usr/local/bin/apk /sbin/apk
sudo ln -s ./artifacts/mount-point-fuse/usr/local/bin/apk /usr/bin/apk
sudo ln -s ./artifacts/mount-point-fuse/usr/local/bin/apk /usr/sbin/apk

. ./scripts/virt-platforms/firecracker-startup.sh
. ./scripts/virt-platforms/gvisor-startup.sh
. ./scripts/virt-platforms/kata-startup.sh
#cp -r ./artifacts/deps/mount-point-fuse/
exit # exit fakeroot
}
