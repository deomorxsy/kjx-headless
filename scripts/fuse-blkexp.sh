#!/bin/sh
#
# ISO9660 image phase 1-5: bootloader config
#
cd ./artifacts/ || return

# 1. create sparse file if doesn't exist
sparse_file() {
printf "=============|> [STEP 1]: create sparse file if doesn't exist \n=============\n"

# about the mount-point: read part 4 a. and b.: you can mount the image into itself.
if  ! [ -f "foo.img" ]; then

#touch ./artifacts/mount-point
qemu-img create -f raw foo.img 3G

fi
}

# 2. manipulate sparse file partition table
checkpart(){
printf "=============|> [STEP 2]: a. manipulate sparse file partition table \nb. define partition properties such as filesystem type. \n=============\n"

partit=$(parted -s foo.img print 2>&1 | grep "Partition" | awk 'NR==1 {print $3}')

if [ "$partit" = "unknown" ]; then

# 2. define partition properties such as filesystem type.


parted -s foo.img \
    mklabel msdos \
    mkpart primary ext4 2048s 100%

else
    printf "It seems there is already a partition in this file.\n"

fi
}


# 3. convert virtual disk sparse file to the qcow2 image
show_as_block() {
printf "=============|> [STEP 3]: convert virtual disk sparse file to the qcow2 image \n=============\n"

qemu-img convert -p \
    -f raw \
    -O qcow2 \
    foo.img foo.qcow2 \
    && rm foo.img

file foo.qcow2

# 4. list partition mappings as a block device
sudo kpartx -l foo.qcow2
}


# 4. mount image into itself with qemu-storage-daemon
qsd_up() {

printf "=============|> [STEP 4]: mount image into itself with qemu-storage-daemon \n=============\n"

# a. use an auxiliar mount point (replace the mountpoint sub-arg later)
# touch ./mount-point && fmt_mp=./mount-point
#
# b. or just mount the image on itself
image_path=./foo.qcow2
new_fmt_mp=$image_path

# c. check if user_allow_other is enabled on
# /etc/fuse.conf for rootless passing

fuse_uao_check=$(grep -n '#user_allow_other' /etc/fuse.conf | tail -1)

if [ -n "$fuse_uao_check" ]; then

# d. run qsd on background; SIGKILL when finished
#image_path=./artifacts/foo.qcow2
#new_fmt_mp=$image_path
qemu-storage-daemon \
    --blockdev node-name=prot-node,driver=file,filename=$image_path \
    --blockdev node-name=fmt-node,driver=qcow2,file=prot-node \
    --export \
    type=fuse,id=exp0,node-name=fmt-node,mountpoint=$new_fmt_mp,writable=on \
    &

# e. get pid of qsd
qsd_pid=!$

mount | grep foo.qcow2

# f. add partition mappings, verbose
sudo kpartx -av "$image_path"

# g. get info from mounted qcow2 device mapping
qemu-img info foo.qcow2

else
    echo: "Could not start qemu-storage-daemon process since user_allow_other is not enabled at /etc/fuse.conf."
fi
}


# 5. merge both boot directories and the LFS rootfs
#
# 5.a mount using loop mount and then fuse-blkexport (some call it oopback mount, but the
# loopback is related to the network interface in network devices.
# A whole other abstraction layer.)
#
rootfs_lp_setup() {
printf "=============|> [STEP 5]: LFS rootfs pt. 1: mount loop and fuse-blkexport \n============="
#
# PS1: mount the fuse-blkexport raw virtual disk file as a Loop Device
#
# PS2: losetup won't see the shadowed/blanked/opaque raw virtual disk file,
# only the mounted version.
#
# 5. mount the loop device
# -f: find and -P: scan the partition table on newly created loop device
sudo losetup -fP ./artifacts/foo.qcow2

losetup -a # list status of all loop devices

# mount loopback device into the mountpoint to setup rootfs
upper_loopdev=$(losetup -a | awk -F: 'NR==1 {print $1}')
upper_base_img=$(losetup -a | awk -F: 'NR==1 {print $3}')
upper_mountpoint=./artifacts/qcow2-rootfs

check_loopdevfs=$(blkid ./artifacts/foo.qcow2 | awk 'NR==1 {print $4}' | grep ext4)
if [ -z "$check_loopdevfs" ]; then
    # actually create the filesystem for the already created partition
    sudo mkfs.ext4 "$upper_loopdev" #/dev/loop0p1
else
    echo "The provided qcow2 image $check_loopdevfs is already formatted with a filesystem mounted as Loop Device at $upper_base_img."
fi

# 6. mount the loop device into the rootfs
printf "=============|> [STEP 6]: mount the loop device into the rootfs.\n============="

mkdir -p "$upper_mountpoint"/rootfs # mkdir a directory for the rootfs
sudo mount "$upper_loopdev" "$upper_mountpoint"/rootfs # mount loop device into the generic dir

# =============
# populate rootfs directory using the
# busybox directory tree from the initramfs
# =============

initramfs_base="./artifacts/netpowered.cpio.gz"

cp "$initramfs_base" "$upper_mountpoint"
cd "$upper_mountpoint" || return

sudo gzip -dc netpowered.cpio.gz | (cd ./rootfs/ || return && sudo cpio -idmv && cd - || return)

# LFS packaging: fakeroot+diff hint strategy
mkdir -p "$upper_mountpoint"/rootfs
cp -r "$upper_mountpoint"/netpowered/* "$upper_mountpoint"/rootfs
cp -r ./artifacts/deps "$upper_mountpoint"

diff --brief --recursive "$upper_mountpoint" "$upper_mountpoint"/rootfs

cp -a rootfs/* /mnt/qcow2/ # copy files, etc
#
# populate the rootfs; generate iso
#
# 7. packaging: call ./scripts/rootfs.sh
. ./scripts/rootfs.sh
#
#LFS=/mnt/kjxh
#LFS_UUID=$()
#LFS_UUID=/dev/sda1/
#QCOW_FILE="./utils/storage/kjxh.qcow2"
#
umount /mnt/qcow2 # umount the loop device passing the path
losetup -d /dev/loop0 # detach the loop device
}




# 2. mount using libguestfs with guestmount
# merge_with
