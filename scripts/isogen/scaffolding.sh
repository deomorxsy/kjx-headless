#!/bin/sh

scaff() {
    # ==================================================================
    #
    # FIRST BATCH
    #
    # ==================================================================

    # cd ./outro/ || return

    # 1. if there is no file IMAGE_PATH, create one
    # workdir /app
    mkdir -p ./artifacts
    if ! [ -f "${IMAGE_PATH}" ]; then

        printf "\n\n======\nCreating image now\n=========\n\n"
        qemu-img create -f raw "${IMAGE_PATH}" 512M
        # qemu-img create -f raw "${IMAGE_PATH}" 3G
        # qemu-img create -f raw "${IMAGE_PATH}" 250M
    else
        printf "\n\n======\nImage already exists: skipping....\n=========\n\n"
    fi

    printf '##                     (10%%)\r'
    sleep 1

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

    printf '##                     (15%%)\r'
    sleep 1

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

    printf '##                     (20%%)\r'
    sleep 1

    # 5. call to *.img destructor
    #rm "$IMAGE_PATH"

    # 6. print qcow file type
    file "$QCOW_PATH"

    # 7. list partition mappings as a block device
    #kpartx -a "$QCOW_PATH"
    losetup -fP "$QCOW_PATH"

    # 8. check if user_allow_other is enabled on /etc/fuse.conf for rootless passing
    IS_FUSE_ALLOWED=$(grep -E '^user_allow_other' /etc/fuse.conf)

    printf '##                     (21%%)\r'
    sleep 1

    # if user_allow_other is non-zero:
    if [ -n "$IS_FUSE_ALLOWED" ]; then

        # 9. run qsd on background; SIGKILL when finished
        qemu-storage-daemon \
            --blockdev node-name=prot-node,driver=file,filename="$QCOW_PATH" \
            --blockdev node-name=fmt-node,driver=qcow2,file=prot-node \
            --export type=fuse,id=exp0,node-name=fmt-node,mountpoint="$QCOW_PATH",writable=on \
            &
        qsd_pid=$!

        sleep 5

        # 10.
        mount | grep qcow2

        # 11. add partition mappings, verbose, under /dev/mapper/loopX
        #kpartx -av "$QCOW_PATH"

        # 12. get info from mounted qcow2 device mapping
        qemu-img info "$QCOW_PATH"
    #foo.qcow2

    else
        printf "\n|> Error: Could not start qemu-storage-daemon process since user_allow_other is not enabled at /etc/fuse.conf.\n\n"
    fi

    printf '##                     (25%%)\r'
    sleep 1

    # 13. mount the loop device (use util-linux/losetup)
    ## second row on losetup list
    losetup -fP "$QCOW_PATH"
    # -f: find and -P: scan the partition table on newly created loop device

    # 14. list status of all loop devices
    losetup -a

    # 15. mount loopback device into the mountpoint to setup rootfs
    # UPPER_LOOPDEV=$(losetup -a | awk 'NR==2 {print $1}' )
    #UPPER_BASE_IMG=$(losetup -a | awk 'NR==2 {print $4}' | sed 's/(//' | sed 's/)//')

    UPPER_LOOPDEV="$(losetup | awk 'NR==2 {print $1}')"
    UPPER_BASE_IMG=$(losetup | awk 'NR==2 {print $6}')
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
    printf "\n\n=====\nCreating filesystem...[BUSYBOX]\n=======\n\n"
    mkfs.ext4 -F "$UPPER_LOOPDEV" #/dev/loop0p1

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
