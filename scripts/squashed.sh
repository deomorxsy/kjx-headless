#!/bin/sh


set_vars() {
QCOW_PATH="./artifacts/foo.qcow2"
IMAGE_PATH="./artifacts/foo.img"
INITRAMFS_BASE="./artifacts/netpowered.cpio.gz"
UPPER_MOUNTPOINT="./artifacts/qcow2-rootfs"
KJX="/mnt/kjx"
SCRIPTS_DIR_PATH=./scripts

ART_SOURCES_DIR=./artifacts/sources

# squashfs
SQ_ROOTFS="/tmp/kjx_rootfs"
SQ_SQUASHFS="/tmp/kjx_squashfs"
SQ_OVERLAY="/tmp/kjx_overlay"

# wget-lists
WGET_BIN_FILES="./artifacts/wget-list-bin.txt"
WGET_COMPILE="./artifacts/wget-list-compile.txt"

# isogen
ISO_DIR="./artifacts/burn"
# fetch bzImage and initramfs.cpio.gz from previous actions:
KERNEL_PATH="./artifacts/bzImage"
RAMDISK_PATH="./artifacts/netpowered.cpio.gz"
ROOTFS_PATH="./artifacts/qcow2-rootfs/rootfs"
WHICH_VIRT="./artifacts/capScope"
ISO_GRUB_PRELOAD_MODULES="part_gpt part_msdos linux normal iso9660 udf all_video video_fb search configfile echo cat"
}

fully_capable() {
# read flag.  The container runs inside this repo should place a flag file that marks a containerized, virtualized(build/runtime) or host (normal/ mount namespaced).

CHECK_SUDO=$(command -v sudo)

if "$CHECK_SUDO" && [ -f "$WHICH_VIRT" ]; then
    if grep "oci_spec" "$WHICH_VIRT"; then
        printf "\n========\nYou are on [oci_spec].\n========\n\n"
    elif grep "host_build" "$WHICH_VIRT"; then
    printf "\n==========You are on [host_BUILD]. Setting capabilitites...\n===========\n\n"
    sudo setcap cap_sys_admin,cap_dac_override+eip "$(readlink -f "$(which qemu-img)")"
    sudo setcap cap_sys_admin+eip "$(readlink -f "$(which parted)")"
    sudo setcap cap_sys_admin,cap_dac_override,cap_dac_read_search+eip "$(readlink -f "$(which kpartx)")"
    sudo setcap cap_sys_admin+eip "$(readlink -f "$(which mkfs.ext4)")"
    sudo setcap cap_sys_admin,cap_dac_override+ep "$(readlink -f "$(which losetup)")"
    sudo setcap cap_sys_admin+ep "$(readlink -f "$(which mount)")"
    sudo setcap cap_dac_override,cap_fowner+ep "$(readlink -f "$(which mkdir)")"
    sudo setcap cap_dac_read_search,cap_dac_override+ep "$(readlink -f "$(which busybox)")"
    sudo setcap cap_wake_alarm+eip "$(readlink -f "$(which fuse-overlayfs)")"
    fi
else
    printf "\n==========You are on [host_BUILD]. Setting capabilitites...\n===========\n\n"
    setcap cap_sys_admin,cap_dac_override+eip "$(readlink -f "$(which qemu-img)")"
    setcap cap_sys_admin+eip "$(readlink -f "$(which parted)")"
    setcap cap_sys_admin,cap_dac_override,cap_dac_read_search+eip "$(readlink -f "$(which kpartx)")"
    setcap cap_sys_admin+eip "$(readlink -f "$(which mkfs.ext4)")"
    setcap cap_sys_admin,cap_dac_override+ep "$(readlink -f "$(which losetup)")"
    setcap cap_sys_admin+ep "$(readlink -f "$(which mount)")"
    setcap cap_dac_override,cap_fowner+ep "$(readlink -f "$(which mkdir)")"
    setcap cap_dac_read_search,cap_dac_override+ep "$(readlink -f "$(which busybox)")"
fi || { echo "Error message: failed setting capabilities."; exit 1; }

}

# 0. Sets up the CONST LFS variable (cross-compilation step)
lfsvar_setup() {
#KJX="/mnt/kjx"
(
cat <<EOF
# sets up the LFS variable
export KJX=/mnt/kjx
EOF
) | tee "$HOME/.bashrc"
#
}
lfsvar_setup




scaffolding() {
# ==================================================================
#
# FIRST BATCH
#
# ==================================================================


# cd ./outro/ || return

# 1. if there is no file IMAGE_PATH, create one
# workdir /app
mkdir -p ./artifacts
if ! [ -f "$IMAGE_PATH" ]; then

    printf "\n\n======\nCreating image now\n=========\n\n"
    # qemu-img create -f raw "$IMAGE_PATH" 3G
    qemu-img create -f raw "$IMAGE_PATH" 250M
else
    printf "\n\n======\nImage already exists: skipping....\n=========\n\n"
fi

# 2.
partit=$(parted -s "$IMAGE_PATH" print 2>&1 | grep "Partition" | awk 'NR==1 {print $3}')

if [ "$partit" = "unknown" ]; then

# 3. define partition properties such as filesystem type.
parted -s "$IMAGE_PATH" \
    mklabel msdos \
    mkpart primary ext4 2048s 100%

partit=$(parted -s "$IMAGE_PATH" print 2>&1 | grep "Partition" | awk 'NR==1 {print $3}')

else
    printf "[EXIT]: It seems there is already a partition in this file.\n"

fi


which qemu-img
# 4. convert raw sparse file to qcow2
if ! [ -f "$QCOW_PATH" ]; then
    printf "\n\n============\nConverting raw sparse file to Qcow2 format\n=================\n\n"
    qemu-img convert -p \
        -f raw \
        -O qcow2 \
        "$IMAGE_PATH" "$QCOW_PATH"
else
    printf "\n=======\nQCOW2 image found at %s , Skipping..... \n========\n" "$QCOW_PATH"
fi

# 5. call to *.img destructor
#rm "$IMAGE_PATH"

# 6. print qcow file type
file "$QCOW_PATH"

# 7. list partition mappings as a block device
#kpartx -a "$QCOW_PATH"
losetup -fP $QCOW_PATH

# 8. check if user_allow_other is enabled on /etc/fuse.conf for rootless passing
IS_FUSE_ALLOWED=$(grep -E '^user_allow_other' /etc/fuse.conf)

# if user_allow_other is non-zero:
if [ -n "$IS_FUSE_ALLOWED" ]; then

# 9. run qsd on background; SIGKILL when finished
qemu-storage-daemon \
    --blockdev node-name=prot-node,driver=file,filename="$QCOW_PATH" \
    --blockdev node-name=fmt-node,driver=qcow2,file=prot-node \
    --export type=fuse,id=exp0,node-name=fmt-node,mountpoint="$QCOW_PATH",writable=on \
    & qsd_pid=$!

sleep 5

# 10.
mount | grep qcow2

# 11. add partition mappings, verbose, under /dev/mapper/loopX
#kpartx -av "$QCOW_PATH"

# 12. get info from mounted qcow2 device mapping
qemu-img info "$QCOW_PATH"
#foo.qcow2

else
     echo "\n|> Error: Could not start qemu-storage-daemon process since user_allow_other is not enabled at /etc/fuse.conf.\n\n"
fi


# 13. mount the loop device (use util-linux/losetup)
## second row on losetup list
losetup -fP "$QCOW_PATH"
# -f: find and -P: scan the partition table on newly created loop device

# 14. list status of all loop devices
losetup -a

# 15. mount loopback device into the mountpoint to setup rootfs
UPPER_LOOPDEV=$(losetup -a | awk 'NR==2 {print $1}' )
UPPER_BASE_IMG=$(losetup -a | awk 'NR==2 {print $4}' | sed 's/(//' | sed 's/)//')

# make sure the soft links for mke2fs on alpine/busybox exist
# /bin/ln -sf /sbin/mke2fs /sbin/mkfs.ext4
# /bin/ln -sf /sbin/mke2fs /sbin/mkfs.ext3
# /bin/ln -sf /sbin/mke2fs /sbin/mkfs.ext2

# 16.
#setcap cap_sys_admin+eip "$(readlink -f "$(which mkfs.ext4)")"
CHECK_LOOPDEVFS=$(blkid "$QCOW_PATH" | awk 'NR==1 {print $4}' | grep ext4)
if [ -f /etc/alpine-release ] && [ -z "$CHECK_LOOPDEVFS" ]; then
# actually create the filesystem for the already created partition
#sudo
printf "\n\n=====\nCreating filesystem...[BUSYBOX]\n=======\n\n"
mkfs.ext4 -F "$UPPER_LOOPDEV" #/dev/loop0p1

# =========
# this expect is to be run on a capability-enabled environment
# in specific busybox/alpine, or adapted to include sudo
# setcap cap_sys_admin+eip $(readlink -f $(which mkfs.ext4))

elif [ -f /etc/lsb-release ] && [ -z "$CHECK_LOOPDEVFS" ]; then
# create filesystem only if the output is zero, meaning it don't have a filesystem yet.
printf "\n\n=====\nCreating filesystem [GNU]...\n=======\n\n"
#mkfs.ext4 -F "$UPPER_LOOPDEV" #/dev/loop0p1
mkfs.ext4 -F "$UPPER_LOOPDEV"

else
    echo "Skipping: The provided qcow2 image $CHECK_LOOPDEVFS is already formatted with a filesystem mounted as Loop Device at $UPPER_BASE_IMG."
fi

# sudo mkdir
mkdir -p $KJX/sources/bin
}


# the -r flag maps the root user.
unshare -r --user --mount --propagation=slave \
        --uts --ipc --net \
        --fork --pid \
        --mount-proc /bin/sh

# exit at any minor error
set -e

# get capabilitites // EDIT: not needed since you can run as if it was root and have filesystem lock - you can't alter file permissions.
#fully_capable

# second mount namespace.
# make sure propagation is used, so mount --make-private starts by default
# check podman unshare
unshare -r --mount --propagation=private \
        --uts --ipc --net \
        --fork --pid \
        --mount-proc \
        /bin/sh -c ./scripts/usfs.sh
#"$GNT"



docker run -d --name eltorito-builder  \
		-v "$$PWD/scripts:/app/scripts/" \
		alpine:3.20 \
		/bin/sh -c "chmod +x /app/scripts/install_grub.sh && /app/scripts/install_grub.sh && sleep 100"

# set environment variables
set_vars

# stop loop devices
losetup -D

# kill the daemon
kill -SIGTERM "$qsd_pid"

# unmount any qcow files left hanging by qemu-storage-daemon
#

# clean capabilities when exiting
sudo setcap -r "$(readlink -f "$(which qemu-img)")"
sudo setcap -r "$(readlink -f "$(which parted)")"
sudo setcap -r "$(readlink -f "$(which kpartx)")"
sudo setcap -r "$(readlink -f "$(which mkfs.ext4)")"
sudo setcap -r "$(readlink -f "$(which losetup)")"
sudo setcap -r "$(readlink -f "$(which mount)")"






if [ "$1" = "fetch_bin" ]; then
    fetch_bin
elif [ "$1" = "verify_bin" ]; then
    verify_bin
elif [ "$1" = "extract_bin" ]; then
    extract_bin
fi
