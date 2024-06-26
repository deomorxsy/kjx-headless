#!/bin/sh
#
# 1. create sparse file if doesn't exist
sparse_file() {
if  ! [ -f "./artifacts/mount-point" ]; then

#touch ./artifacts/mount-point
qemu-img create -f raw foo.img 3G

fi
}

# 2. manipulate sparse file patition table
checkpart(){

partit=$(parted -s foo.img print 2>&1 | grep "Partition" | awk 'NR==1 {print $3}')

if [ "$partit" = "unknown" ]; then

# define partition properties such as filesystem type.
parted -s foo.img \
    mklabel msdos \
    mkpart primary ext4 2048s 100%

else
    printf "It seems there is already a partition in this file.\n"

fi
}


# 3. convert virtual disk sparse file to the qcow2 image
show_as_block() {

qemu-img convert -p \
    -f raw \
    -O qcow2 \
    foo.img foo.qcow2 \
    && rm foo.img

file foo.qcow2

# list partition mappings as a block device
sudo kpartx -l foo.qcow2
}


# 4. mount image into itself with qemu-storage-daemon
qsd_up() {

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
image_path=./artifacts/foo.qcow2
new_fmt_mp=$image_path
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
sudo kpartx -av foo.qcow2

# g. get info from mounted qcow2 device mapping
qemu-img info foo.qcow2

else
    echo: "Could not start qemu-storage-daemon process since user_allow_other is not enabled at /etc/fuse.conf."
fi
}


# 5. merge both boot directories and the LFS rootfs
#
# 5.a mount using loopback mount and then fuse-blkexport
rootfs_lp_setup() {
#
# PS1: mount the fuse-blkexport raw virtual disk file as a Loop Device
#
# PS2: losetup won't see the shadowed/blanked/opaque raw virtual disk file,
# only the mounted version.
#
# -f: find and -P: scan the partition table on newly created loop device
sudo losetup -fP ./artifacts/foo.qcow2

losetup -a # list status of all loop devices

check_loopdevfs=$(blkid ./artifacts/foo.qcow2 | awk 'NR==1 {print $4}' | grep ext4)
if [ -z "$check_loopdevfs" ]; then
    # actually create the filesystem for the already created partition
    sudo mkfs.ext4 /dev/loop0p1
fi

# mount loopback device into the mountpoint to setup rootfs
upper_loopdev=$(losetup -a | awk -F: 'NR==1 {print $1}')
upper_mountpoint=./artifacts/qcow2-rootfs

mkdir -p "$upper_mountpoint" # mkdir a directory for the rootfs
sudo mount "$upper_loopdev" "$upper_mountpoint" # mount loop device into the generic dir


# populate rootfs directory using the
# busybox directory tree from the initramfs
cp ./artifacts/netpowered.cpio.gz "$upper_mountpoint"
cd "$upper_mountpoint" || return
gzip ./netpowered.cpio.gz
cpio -itv < ./netpowered.cpio
cd - || return

# LFS packaging: fakeroot+diff hint strategy
cp -r ./artifacts/netpowered/ mount-point-fuse
cp -r ./artifacts/deps mount-point-fuse/rootfs



cp -a rootfs/* /mnt/qcow2/ # copy files, etc
#
# populate the rootfs
# generate iso
#
umount /mnt/qcow2 # umount the loop device passing the path
losetup -d /dev/loop0 # detach the loop device
}

packaging() {
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


cp -r ./artifacts/deps/mount-point-fuse/
exit # exit fakeroot
}


# 2. mount using libguestfs with guestmount
# merge_with
