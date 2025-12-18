#!/bin/sh

QCOW_PATH="./artifacts/foo.qcow2"
IMAGE_PATH="./artifacts/foo.img"
INITRAMFS_BASE="./artifacts/netpowered.cpio.gz"
UPPER_MOUNTPOINT="./artifacts/qcow2-rootfs"
KJX="/mnt/kjx"

scaff() {
    # ==================================================================
    # FIRST BATCH
    # ==================================================================

    MODE="-setvars" . ./scripts/isogen/set-vars.sh
    # cd ./outro/ || return

    #  create IMAGE_PATH
    mkdir -p ./artifacts
    if ! [ -f "${IMAGE_PATH}" ]; then
        echo "========="
        echo "Attempting to create the image now..."
        echo "========="

        if ! qemu-img create -f raw "${IMAGE_PATH}" 512M; then
            # echo "|> Error: it was not possible to"
            echo "|> Error: it was not possible to create the IMAGE_PATH=$IMAGE_PATH"
            return 1
        fi
        # qemu-img create -f raw "${IMAGE_PATH}" 3G
        # qemu-img create -f raw "${IMAGE_PATH}" 250M
    fi
    echo "========="
    echo "Image already exists: skipping...."
    echo "========="
    printf '##                     (10%%)\r'

    sleep 1

    # list known partitions of the image path
    partit=$(parted -s "$IMAGE_PATH" print 2>&1 | grep "Partition" | awk 'NR==1 {print $3}')

    if ! [ "$partit" = "unknown" ]; then
        echo "[EXIT]: It seems there is already a partition in this file."
        return
    fi

    # define partition properties such as filesystem type.
    if ! (parted -s "$IMAGE_PATH" \
        mklabel msdos \
        mkpart primary ext4 2048s 100%); then
        echo "|> Error: it was not possible to define partition properties such as filesystem type using parted. Exiting now..."
        return 1
    fi
    echo "|> Defined partition properties such as filesystem type using parted with success."
    echo

    partit=$(parted -s "$IMAGE_PATH" print 2>&1 | grep "Partition" | awk 'NR==1 {print $3}')

    printf '##                     (15%%)\r'
    sleep 1

    which qemu-img

    # convert raw sparse file to qcow2
    if ! [ -f "$QCOW_PATH" ]; then
        echo "================="
        echo "Converting raw sparse file to Qcow2 format"
        echo "================="

        if ! (qemu-img convert -p \
            -f raw \
            -O qcow2 \
            "$IMAGE_PATH" "$QCOW_PATH"); then
            echo "|> Error: it was not possible to conver raw image into qcow2 image. Exiting now..."
            return 1
        fi
    fi
    echo "================="
    echo "|> QCOW2 image found at $QCOW_PATH, skipping....."
    echo "================="
    printf '##                     (20%%)\r'
    sleep 1

    # 5. call to *.img destructor
    #rm "$IMAGE_PATH"

    # 6. print qcow file type
    file "$QCOW_PATH"

    # 7. list partition mappings as a block device
    #kpartx -a "$QCOW_PATH"
    if ! losetup -fP "$QCOW_PATH"; then
        echo "|> Error: partition mapping COULD NOT be listed as a block device using losetup. Exiting now..."
        echo
        return 1
    fi
    echo "|> Partition mappings were listed as a block device using losetup with success."
    echo

    # check if user_allow_other is enabled on /etc/fuse.conf for rootless passing
    if ! IS_FUSE_ALLOWED=$(grep -E '^user_allow_other' /etc/fuse.conf); then
        echo "|> Error: it was not possible to check if user_allow_other is enabled on /etc/fuse.conf for rootless passing. Exiting now..."
        echo
        return 1
    fi
    printf '##                     (21%%)\r'
    sleep 1

    # if user_allow_other is non-zero:
    if ! [ -n "$IS_FUSE_ALLOWED" ]; then
        echo "|> Error: Could not start qemu-storage-daemon process since [user_allow_other] is not enabled at [/etc/fuse.conf]. Exiting now..."
        echo
        return 1
    fi

    # run qsd on background; SIGKILL when finished
    if ! (
        qemu-storage-daemon \
            --blockdev node-name=prot-node,driver=file,filename="$QCOW_PATH" \
            --blockdev node-name=fmt-node,driver=qcow2,file=prot-node \
            --export type=fuse,id=exp0,node-name=fmt-node,mountpoint="$QCOW_PATH",writable=on &

        QSD_PID=$!
        export QSD_PID
    ); then
        echo "|> Error: it was not possible to run qemu-storage-daemon on background; SIGKILL when finished. Exiting now..."
        echo
        return 1
    fi

    sleep 5

    # list the qcow2 image on the mount lookup
    if ! mount | grep qcow2; then
        echo "|> Error: it was not possible to list the qcow2 image on the mount lookup. Exiting now..."
        echo
        return 1
    fi

    # add partition mappings, verbose, under /dev/mapper/loopX
    #kpartx -av "$QCOW_PATH"

    # get info from mounted qcow2 device mapping
    if ! qemu-img info "$QCOW_PATH"; then
        echo "|> Error: it was not possible to get info from mounted qcow2 device mapping. EXiting now..."
        return 1
    fi
    #foo.qcow2

    printf '##                     (25%%)\r'
    sleep 1

    # mount the loop device (use util-linux/losetup)
    ## second row on losetup list
    if ! losetup -fP "$QCOW_PATH"; then
        echo "|> Error: it was not possible to mount the loop device (use util-linux/losetup). Exiting now..."
        echo
        return 1
    fi
    # -f: find and -P: scan the partition table on newly created loop device

    # list status of all loop devices
    losetup -a

    # 15. mount loopback device into the mountpoint to setup rootfs
    # UPPER_LOOPDEV=$(losetup -a | awk 'NR==2 {print $1}' )
    #UPPER_BASE_IMG=$(losetup -a | awk 'NR==2 {print $4}' | sed 's/(//' | sed 's/)//')

    UPPER_LOOPDEV="$(losetup | awk 'NR==2 {print $1}')"
    UPPER_BASE_IMG="$(losetup | awk 'NR==2 {print $6}')"
    # make sure the soft links for mke2fs on alpine/busybox exist
    # /bin/ln -sf /sbin/mke2fs /sbin/mkfs.ext4
    # /bin/ln -sf /sbin/mke2fs /sbin/mkfs.ext3
    # /bin/ln -sf /sbin/mke2fs /sbin/mkfs.ext2

    # 16.
    #setcap cap_sys_admin+eip "$(readlink -f "$(which mkfs.ext4)")"
    # CHECK_LOOPDEVFS=$(blkid "$QCOW_PATH" | awk 'NR==1 {print $4}' | grep ext4)
    # if [ -f /etc/alpine-release ] && [ -z "$CHECK_LOOPDEVFS" ]; then
    # actually create the filesystem for the already created partition
    #sudo
    echo "====="
    echo "|> Creating filesystem...[BUSYBOX]"
    echo "====="

    #/dev/loop0p1
    # force mke2fs to create a file system
    if ! mkfs.ext4 -F "$UPPER_LOOPDEV"; then
        echo "|> Error: it was not possible to force mke2fs to create a file system. Exiting now..."
        echo
        return 1
    fi
    echo "|> forced mke2fs to create a file system with success."
    echo
    printf '##                     (28%%)\r'
    sleep 1

    # # =========
    # # this expect is to be run on a capability-enabled environment
    # # in specific busybox/alpine, or adapted to include sudo
    # # setcap cap_sys_admin+eip $(readlink -f $(which mkfs.ext4))
    #
    # elif [ -f /etc/lsb-release ] && [ -z "$CHECK_LOOPDEVFS" ]; then
    # # create filesystem only if the output is zero, meaning it don't have a filesystem yet.
    # printf "\n\n=====\nCreating filesystem [GNU]...\n=======\n\n"
    # #mkfs.ext4 -F "$UPPER_LOOPDEV" #/dev/loop0p1
    # mkfs.ext4 -F "$UPPER_LOOPDEV"

    # else
    #     echo "Skipping: The provided qcow2 image $CHECK_LOOPDEVFS is already formatted with a filesystem mounted as Loop Device at $UPPER_BASE_IMG."
    # fi

    # sudo mkdir
    mkdir -p "$KJX/sources/bin"
}
