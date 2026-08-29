#!/bin/sh

# squashfs
SQ_ROOTFS="/tmp/kjx_rootfs"
SQ_SQUASHFS="/tmp/kjx_squashfs"
SQ_OVERLAY="/tmp/kjx_overlay"

# Create squashfs destination paths
mkdir -pv "${SQ_ROOTFS:-[EMPTY_VARIABLE]}"
mkdir -pv "${SQ_SQUASHFS:-[EMPTY_VARIABLE]}"
mkdir -pv "${SQ_OVERLAY:-[EMPTY_VARIABLE]}/upperdir/usr/local/bin/"

mkdir -pv "${SQ_OVERLAY:-[EMPTY_VARIABLE]}/upperdir"
mkdir -pv "${SQ_OVERLAY:-[EMPTY_VARIABLE]}/workdir"
mkdir -pv "${SQ_OVERLAY:-[EMPTY_VARIABLE]}/merged"

# This includes kernel modules
BUILDER_ROOTFS_DIR="${HOME:-[EMPTY_VARIABLE]}/Downloads/kjxh-artifacts/another/newfrdir"

BUILDER_QEMUKJX_TARBALL=

if [ "$(basename "$PWD")" = "kjx-headless" ] && [ -d "$ROOTFS_PATH" ]; then
    cp -r "$BUILDER_ROOTFS_DIR"/* "$ROOTFS_PATH"
    sudo cp "$BUILDER_ROOTFS_DIR"/lib/libdevmapper.so.1.02 "$ROOTFS_PATH"/lib/
    sudo cp "$BUILDER_ROOTFS_DIR"/usr/lib/libtcl8.6.so "$ROOTFS_PATH"/usr/lib/

    printf "\n\n|> Sucessfully copied the BUILDER_ROOTFS directory to the ISO ROOTFS_PATH, including the libdevmapper and libtcl shared objects. Exiting now...\n\n"
else
    printf "\n==========\n|> Error: not on the root of the repository project (kjx-headless). \n|> Change it before running this block. Exiting now...\n\n"
fi

# Copy the ROOTFS_PATH into the SQ_ROOTFS path.
if ! (sudo cp -r "${ROOTFS_PATH:-[EMPTY_STR]}/*" "${SQ_ROOTFS:-[EMPTY_STR]}"); then
    echo "|> Error: could not copy [${ROOTFS_PATH:-[EMPTY_STR]}/*] into the directory [${SQ_ROOTFS:-[EMPTY_STR]})]. Exiting now..."
    echo && echo
    return 1
fi
echo "|> Copied [${ROOTFS_PATH:-[EMPTY_STR]}/*] into the directory [${SQ_ROOTFS:-[EMPTY_STR]})]. Proceeding..."
echo && echo

# ================
# squashfs logic
# ================
if ! (mksquashfs "$SQ_ROOTFS" "${SQ_SQUASHFS:-[EMPTY_STR]}/busybox.squashfs" -comp xz -b 256K -Xbcj x86); then
    echo "|> Error: could not create a file squashfs [$SQ_SQUASHFS/busybox.squashfs] from [$SQ_ROOTFS]. Exiting now..."
    echo && echo
    return 1
fi
echo "|> Created a file squashfs [$SQ_SQUASHFS/busybox.squashfs] from [$SQ_ROOTFS]. Proceeding now..."
echo && echo

# mount the SQUASHFS_IMAGE="$SQ_SQUASHFS/busybox.squashfs"
if ! (sudo mount -t squashfs "${SQ_SQUASHFS:-[EMPTY_STR]}/busybox.squashfs" "${SQ_OVERLAY:-[EMPTY_STR]}/merged"); then
    echo "|> Error: could not mount the SQUASHFS_IMAGE=${SQ_SQUASHFS:-[EMPTY_STR]}/busybox.squashfs at ${SQ_OVERLAY:-[EMPTY_STR]}/merged"
    echo && echo
    return 1
fi
echo "|> Mounted the SQUASHFS_IMAGE=${SQ_SQUASHFS:-[EMPTY_STR]}/busybox.squashfs at ${SQ_OVERLAY:-[EMPTY_STR]}/merged with success. Proceeding..."
echo && echo

# use fuse-overlayfs to stack files and install additional programs
if ! (sudo fuse-overlayfs -o lowerdir=${SQ_OVERLAY:-[EMPTY_STR]}/merged,upperdir=${SQ_OVERLAY:-[EMPTY_STR]}/upperdir,workdir=${SQ_OVERLAY:-[EMPTY_STR]}/workdir ${SQ_OVERLAY:-[EMPTY_STR]}/merged); then
    echo "|> Error: could not configure the fuse-overlayfs to stack files and install additional programs. Exiting now..."
    echo && echo
    return 1
fi
echo "|> Configured fuse-overlayfs to stack files and install additional programs with success."
echo && echo
