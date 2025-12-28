#!/bin/busybox sh

builder() {
    # prepare registry
    if ! docker run -d -p 5000:5000 --name registry registry:3.0; then
        return 1
    fi

    # env git_hash env goes into the compose.yml
    # invoke compose to build the dropbear target which will become the root filesystem (rootfs)
    if ! docker compose -f ./compose.yml --progress=plain build dropbear; then
        return 1
    fi

    # push the built image into the localhost:5000
    if ! docker push localhost:5000/dropbear:latest; then
        return 1
    fi
    #podman build -t initramfs:latest -f ./utils/busybox/Dockerfile

    # Retrieve artifact from docker image
    if ! docker run -it --name dropbear -d localhost:5000/dropbear:latest; then
        return 1
    fi

    # Copy the rootfs into artifacts
    mkdir -p ./artifacts/isogen/
    if ! docker cp dropbear:./rootfs-with-ssh.cpio.gz ./artifacts/isogen/rootfs-with-ssh.cpio.gz; then
        return 1
    fi

}

_start() {
    # redo mount filesystems
    mount -t devtmpfs devtmpfs /dev
    mount -t proc none /proc
    mount -t sysfs none /sys
    mount -t tmpfs tmpfs /tmp

    # redo mount tracefs and securityfs pseudo-filesystems
    mount -t tracefs tracefs /sys/kernel/tracing/
    mount -t debugfs debugfs /sys/kernel/debug/
    mount -t securityfs securityfs /sys/kernel/security/
    EOF &&
        #
        #
        #
        # redo set up hostname
        echo "kjx" >/etc/hostname && hostname -F /etc/hostname

    # redo bring up the connection
    /sbin/ip link set lo up             # bring up loopback interface
    /sbin/ip link set eth0 up           # bring up ethernet interface
    /sbin/ip addr add 192.168.0.27 eth0 # static ipv4 assignment

    # redo alternate method, built-in inside busybox
    #udhcpc -i eth0 # dynamic ipv4 assignment

    # ================================

    # sets up BRK keyboard
    setxkbmap -model abnt2 -layout br -variant abnt2
    echo && echo

    cat <<'asciiart'
 .-"``"-.
/  _.-` (_) `-._
\   (_.----._)  /
 \     /    \  /
  `\  \____/  /`
    `-.____.-`      __     _
     /      \      / /__  (_)_ __
    /        \    /  '_/ / /\ \ /
   /_ |  | _\    /_/\_\_/ //_\_\
     |  | |          |___/         deomorxsy/kjx
     |__|__|  ----------------------------------------------
     /_ | _\   Reboot (01.00.0, ${GIT_CONTAINERFILE_HASH})
              ----------------------------------------------
asciiart

    # get a shell
    sh

    asciiart

    printf "Uptime: %s\n" "$(cut -d' ' -f1 /proc/uptime)"
    printf "System config: %s\n" "$(uname -a)"
    ## get a shell
    #sh

    exec /bin/busybox runsvdir /etc/runit/runsvdir/default

    # load early bpf program
    # /bin/libkjx_runqlat
}

# =========================================

# copy initramfs to the artifacts qcow2 directory, then copy the latter to the squashfs directory
# tryout.sh
# set_rootfs() {
#MODE="-setvars" . ./scripts/isogen/set-vars.sh

echo "$ROOTFS_PATH"

if [ -d "$ROOTFS_PATH" ]; then
    rm -rf "${ROOTFS_PATH:?}/"*
else
    mkdir -p "${ROOTFS_PATH}"
fi

# decompress and extract initramfs into rootfs_path // sudo
busybox gzip -dc "$RAMDISK_PATH" | (cd "$ROOTFS_PATH" || return && busybox cpio -idmv && cd - || return)

printf '##                     (30%%)\r'
sleep 1

# newfrdir
#
# cp ./newfrdir/* $ROOTFS_PATH

if [ -d "$SQ_ROOTFS" ]; then
    rm -rf "${SQ_ROOTFS:?}/"*
else
    mkdir -p "$SQ_ROOTFS"
fi

# copy rootfs_path contents to the squashed_rootfs
# cp -r "$ROOTFS_PATH/" "$SQ_ROOTFS"

#}

# mount the loop device into the rootfs
#mount_loopdev() {
printf "=============|> [STEP 6]: mount the loop device into the rootfs.\n=============\n\n"
mkdir -p "$UPPER_MOUNTPOINT"/rootfs # mkdir a directory for the rootfs

# busybox-sh based
# mountns_sasquatch() {

# sink to the mount namespace
#mkdir -p /tmp/host_dir

#KJX="/mnt/kjx"

# these are idempotent
mkdir -pv "$KJX/dev"
mkdir -pv "$KJX/tmp"
mkdir -pv "$KJX/proc"
mkdir -pv "$KJX/sys"
mkdir -pv "$KJX/run"
# chapter 5 - fake the cross-compiler toolchain
mkdir -pv "$KJX/tools"

printf '##                     (32%%)\r'
sleep 1

# mounts are for compiled LFS step
## populating /dev for the kjx mount (before chroot), all sudo
sudo mount -t devtmpfs devtmpfs "$KJX/dev/" #
sudo mount -t tmpfs tmpfs "$KJX/tmp/"

## mounting virtual kernel filesystems (before chroot), all sudo
sudo mount -vt devpts devpts -o gid=5,mode=0620 "$KJX/dev/pts"
sudo mount -vt proc proc "$KJX/proc"
sudo mount -vt sysfs sysfs "$KJX/sys"
sudo mount -vt tmpfs tmpfs "$KJX/run"

# setting up the bind mount
TMPDIR=$(/bin/busybox mktemp -d)
mkdir -p "$KJX/sources/release"
sudo mount --bind "$KJX/sources/release" "$TMPDIR"

# squashfs
mkdir -pv "$SQ_ROOTFS"
mkdir -pv "$SQ_SQUASHFS"
mkdir -pv "$SQ_OVERLAY/upperdir/usr/local/bin/"

mkdir -pv "$SQ_OVERLAY/upperdir"
mkdir -pv "$SQ_OVERLAY/workdir"
mkdir -pv "$SQ_OVERLAY/merged"

# =============
# populate rootfs directory using the busybox directory tree from the initramfs
# =============
#BACK_HERE
mkdir -pv "$ROOTFS_PATH"

# sudo
# sudo mount "$UPPER_LOOPDEV" "$ROOTFS_PATH"

sudo mount "$UPPER_LOOPDEV" "$UPPER_MOUNTPOINT"/rootfs # mount loop device into the generic dir
# sudo mount
#}

# verify_check_loop()
#
#runit_directories() {
# runit/runsv/runsvdir setup
mkdir -p "$ROOTFS_PATH/etc/runit"
mkdir -p "$ROOTFS_PATH/etc/runit/runsvdir/default"
mkdir -p "$ROOTFS_PATH/etc/sv"
mkdir -p "$ROOTFS_PATH/var/service"
mkdir -p "$ROOTFS_PATH/usr/local/bin"

# runit: service scripts, get a shell
mkdir -p "$ROOTFS_PATH/etc/sv/getty-tty1"

# }
