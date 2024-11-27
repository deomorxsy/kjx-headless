#!/bin/sh


set_vars() {
QCOW_PATH="./artifacts/foo.qcow2"
IMAGE_PATH="./artifacts/foo.img"
INITRAMFS_BASE="./artifacts/netpowered.cpio.gz"
UPPER_MOUNTPOINT="./artifacts/qcow2-rootfs"
KJX="/mnt/kjx"
ROOTFS_PATH="$UPPER_MOUNTPOINT/rootfs"
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
if [ -f "$WHICH_VIRT" ]; then
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
    sudo setcap cap_sys_admin,cap_dac_override+eip "$(readlink -f "$(which qemu-img)")"
    sudo setcap cap_sys_admin+eip "$(readlink -f "$(which parted)")"
    sudo setcap cap_sys_admin,cap_dac_override,cap_dac_read_search+eip "$(readlink -f "$(which kpartx)")"
    sudo setcap cap_sys_admin+eip "$(readlink -f "$(which mkfs.ext4)")"
    sudo setcap cap_sys_admin,cap_dac_override+ep "$(readlink -f "$(which losetup)")"
    sudo setcap cap_sys_admin+ep "$(readlink -f "$(which mount)")"
    sudo setcap cap_dac_override,cap_fowner+ep "$(readlink -f "$(which mkdir)")"
    sudo setcap cap_dac_read_search,cap_dac_override+ep "$(readlink -f "$(which busybox)")"
fi || { echo "Error message: failed setting capabilities."; exit 1; }

}

# 0. Sets up the CONST LFS variable (cross-compilation step)
lfsvar_setup() {
#KJX="/mnt/kjx"

cat >> "$HOME/.bashrc" << EOF

# sets up the LFS variable
#
export KJX=/mnt/kjx

EOF
}
lfsvar_setup




scaffolding() {
# ==================================================================
#
# FIRST BATCH
#
# ==================================================================


cd ./outro/ || return

# 1. if there is no file IMAGE_PATH, create one
# workdir /app
mkdir -p ./artifacts
if ! [ -f "$IMAGE_PATH" ]; then

    printf "\n\n======\nCreating image now\n=========\n\n"
    qemu-img create -f raw "$IMAGE_PATH" 3G
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
    echo "=======SQUASHING================= "
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
    echo "Could not start qemu-storage-daemon process since user_allow_other is not enabled at /etc/fuse.conf."
fi


# 13. mount the loop device
## second row on losetup list
losetup -fP "$QCOW_PATH"
# -f: find and -P: scan the partition table on newly created loop device

# 14. list status of all loop devices
losetup -a

# 15. mount loopback device into the mountpoint to setup rootfs
UPPER_LOOPDEV=$(losetup -l | awk 'NR==2 {print $1}')
upper_base_img=$(losetup -l | awk 'NR==2 {print $6}')

# 16.
#setcap cap_sys_admin+eip "$(readlink -f "$(which mkfs.ext4)")"
check_loopdevfs=$(blkid "$QCOW_PATH" | awk 'NR==1 {print $4}' | grep ext4)
if [ -f /etc/alpine-release ] && [ -z "$check_loopdevfs" ]; then
# actually create the filesystem for the already created partition
#sudo
printf "\n\n=====\nCreating filesystem...[BUSYBOX]\n=======\n\n"
mkfs.ext4 -F "$UPPER_LOOPDEV" #/dev/loop0p1

# this expect is to be run on a capability-enabled environment
# in specific busybox/alpine, or adapted to include sudo
#
# setcap cap_sys_admin+eip $(readlink -f $(which mkfs.ext4))

elif [ -f /etc/lsb-release ] && [ -z "$check_loopdevfs" ]; then
# create filesystem only if the output is zero, meaning it don't have a filesystem yet.
printf "\n\n=====\nCreating filesystem [GNU]...\n=======\n\n"
#mkfs.ext4 -F "$UPPER_LOOPDEV" #/dev/loop0p1
mkfs.ext4 -F "$UPPER_LOOPDEV"

else
    echo "Skipping: The provided qcow2 image $check_loopdevfs is already formatted with a filesystem mounted as Loop Device at $upper_base_img."
fi

# sudo mkdir
mkdir -p $KJX/sources/bin
}


GNT=$( cat <<FULL



QCOW_PATH="./artifacts/foo.qcow2"
IMAGE_PATH="./artifacts/foo.img"
INITRAMFS_BASE="./artifacts/netpowered.cpio.gz"
UPPER_MOUNTPOINT="./artifacts/qcow2-rootfs"
KJX="/mnt/kjx"
ROOTFS_PATH="$UPPER_MOUNTPOINT/rootfs"
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


# 17. mount the loop device into the rootfs
mount_loopdev() {
printf "=============|> [STEP 6]: mount the loop device into the rootfs.\n=============\n\n"
mkdir -p "$UPPER_MOUNTPOINT"/rootfs # mkdir a directory for the rootfs
sudo mount "$UPPER_LOOPDEV" "$UPPER_MOUNTPOINT"/rootfs # mount loop device into the generic dir
# sudo mount
}


# ==================================================================
# 18. mount namespaces
# ==================================================================

# 25. fetch binaries
# fetch binaries
fetch_bin() {
    mkdir -p "$KJX/sources/bin"
    art_sources_dir=./artifacts/sources
    mkdir -p "$art_sources_dir"
    wget -nc --input-file="$WGET_BIN_FILES" \
        --continue --directory-prefix="$art_sources_dir"
}

verify_bin(){
art_sources_dir=./artifacts/sources
sha256sum -c "$art_sources_dir/sha256sums_isogen.txt"
}
#fetch_bin

extract_bin() {

#sudo chmod +rw $KJX/sources/bin
if [ "$USER" = "root" ]; then
    chown -R "$USER" $KJX/sources/bin/
else
    sudo chown -R "$USER" $KJX/sources/bin/
fi

ART_SOURCES_DIR=./artifacts/sources
cp $ART_SOURCES_DIR/* "$KJX/sources/bin/"
cd "$KJX/sources/bin/" || return

# Decompress tarballs
for item in  ./*.tar.gz; do
    tar -xvf "$item" || return 1
done

cd - || return 1
}


verify_check_loop() {
#
fetch_counter=0

if verify_bin; then
    cd "$KJX/sources/bin/" || return
    listdirs=$(find . -maxdepth 1 -type f,d ! -name "*.tar*")
    # echo $listdirs
    #. ./syslinux-6.03 ./grub-2.12 ./sha256sums_isogen.txt ./k3s ./gvisor-release-20240807.0 ./libcap-1.2.70

    listtars=$(find . -maxdepth 1 -type f,d -name "*.tar*")
    istardir=$(echo "$listtars" | sed 's/\.tar\.\(xz\|gz\)//g')

    # break the loop after three wrong verify attempts
    while [ $fetch_counter -le 3 ]; do
        if verify_bin; then
            break
        else
            fetch_bin || return 1
            fetch_counter=$((fetch_counter + 1))
        fi
    done

    if ! verify_bin; then
        printf "\n\n=======\nVerification of fetched files failed T_T. Maybe you should exit the mount namespace... ;] \n============\n"
    fi

    # process extracted directories
    for item in $listtars; do
        tar_dir=$(basename "$item%.tar.*")
        if [ ! -d "$tar_dir" ]; then
            echo "$tar_dir do not exist after extraction. Extracting."
            extracting_bin || return 1
        else
            echo "$tar_dir exists".
        fi
    done

    cd - || return

    mkdir -pv "$SQ_OVERLAY/upperdir/usr/local/bin/"
    cp -r "$KJX/sources/bin/" "$SQ_OVERLAY/upperdir/usr/local/"
    cp -r "$SQ_OVERLAY/merged/rootfs/" "$ROOTFS_PATH"
fi

}



#SCRIPTS_DIR_PATH=./scripts

runit_directories() {
# runit/runsv/runsvdir setup
mkdir -p "$ROOTFS_PATH/etc/runit"
mkdir -p "$ROOTFS_PATH/etc/runit/runsvdir/default"
mkdir -p "$ROOTFS_PATH/etc/sv"
mkdir -p "$ROOTFS_PATH/var/service"
mkdir -p "$ROOTFS_PATH/usr/local/bin"

# runit: service scripts, get a shell
mkdir -p "$ROOTFS_PATH/etc/sv/getty-tty1"

}

runit_step() {
# =============================

cat <<"EOF" > "$ROOTFS_PATH/etc/sv/getty-tty1/run"
#!/bin/sh
#
exec /sbin/getty 38400 tty1

EOF
chmod +x "$ROOTFS_PATH/etc/sv/getty-tty1/run"




# ============================

cat <<"INIT_EOF" > "$ROOTFS_PATH/etc/runit/1"
#!/bin/busybox sh

# redo mount filesystems
mount -t devtmpfs   devtmpfs    /dev
mount -t proc       none        /proc
mount -t sysfs      none       /sys
mount -t tmpfs      tmpfs       /tmp

# redo mount tracefs and securityfs pseudo-filesystems
mount -t tracefs tracefs /sys/kernel/tracing/
mount -t debugfs debugfs /sys/kernel/debug/
mount -t securityfs securityfs /sys/kernel/security/
EOF && \
#
#
#
# redo set up hostname
echo "kjx" > /etc/hostname && hostname -F /etc/hostname

# redo bring up the connection
/sbin/ip link set lo up                         # bring up loopback interface
/sbin/ip link set eth0 up                       # bring up ethernet interface
/sbin/ip addr add 192.168.0.27 eth0             # static ipv4 assignment

# redo alternate method, built-in inside busybox
#udhcpc -i eth0 # dynamic ipv4 assignment

# ================================

# sets up BRK keyboard
setxkbmap -model abnt2 -layout br -variant abnt2
echo && echo

cat << 'asciiart'
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

printf "Uptime: $(cut -d' ' -f1 /proc/uptime) \n"
printf "System config: $(uname -a) \n"
## get a shell
#sh

exec /bin/busybox runsvdir /etc/runit/runsvdir/default

# load early bpf program
# /bin/libkjx_runqlat

INIT_EOF

chmod +x "$ROOTFS_PATH/etc/runit/1"

ln -sf "$ROOTFS_PATH/etc/runit/1" "$ROOTFS_PATH/sbin/init"
}
#runit_step



runit_symlinks() {
# this bootstraps the set_sandboxes function
# inside runit, as well as any hotfixes needed
# from the previous mksquashfs (deep copy) followed
# by cp (shallow copy) steps.


# setup runit to start the C program to control both k3s and the tracer at startup
mkdir -p "$ROOTFS_PATH"/etc/sv/clusterbuild/
cat > "$ROOTFS_PATH"/etc/sv/clusterbuild/run <<EOF
#!/bin/sh

exec /usr/bin/cpuram_task

EOF
chmod +x "$ROOTFS_PATH"/etc/sv/clusterbuild/run
# this will be linked by the following steps

# runtime link
for item in "$ROOTFS_PATH/etc/sv/"*; do
ln -sf "$item" "$ROOTFS_PATH/var/service/"
done

# runit: symbolic link convention
for index in "$ROOTFS_PATH/etc/sv/"*; do
ln -sf "$index" "$ROOTFS_PATH"/etc/runit/runsvdir/default/
done

# already done in a previous step
#ln -sf "$ROOTFS_PATH"/etc/runit/1" "$ROOTFS_PATH"/sbin/init

}



enable_containers() {

if ! [ -d "$ROOTFS_PATH"/etc/containers ]; then
    mkdir -pv "$ROOTFS_PATH"/etc/containers
else
    printf "\nDirectory already exists.\n\n"
fi

tee "$ROOTFS_PATH"/etc/containers/containers.conf > /dev/null <<"EOF"

# Paths to look for a valid OCI runtime (crun, runc, kata, runsc, krun, etc)
[engine.runtimes]
crun = [
  "/usr/bin/crun",
  "/usr/sbin/crun",
  "/usr/local/bin/crun",
  "/usr/local/sbin/crun",
  "/sbin/crun",
  "/bin/crun",
  "/run/current-system/sw/bin/crun",
]

crun-vm = [
  "/usr/bin/crun-vm",
  "/usr/local/bin/crun-vm",
  "/usr/local/sbin/crun-vm",
  "/sbin/crun-vm",
  "/bin/crun-vm",
  "/run/current-system/sw/bin/crun-vm",
]

kata = [
  "/usr/bin/kata-runtime",
  "/usr/sbin/kata-runtime",
  "/usr/local/bin/kata-runtime",
  "/usr/local/sbin/kata-runtime",
  "/sbin/kata-runtime",
  "/bin/kata-runtime",
  "/usr/bin/kata-qemu",
  "/usr/bin/kata-fc",
]

runc = [
  "/usr/bin/runc",
  "/usr/sbin/runc",
  "/usr/local/bin/runc",
  "/usr/local/sbin/runc",
  "/sbin/runc",
  "/bin/runc",
  "/usr/lib/cri-o-runc/sbin/runc",
]

runsc = [
  "/usr/bin/runsc",
  "/usr/sbin/runsc",
  "/usr/local/bin/runsc",
  "/usr/local/sbin/runsc",
  "/bin/runsc",
  "/sbin/runsc",
  "/run/current-system/sw/bin/runsc",
]

youki = [
  "/usr/local/bin/youki",
  "/usr/bin/youki",
  "/bin/youki",
  "/run/current-system/sw/bin/youki",
]

krun = [
  "/usr/bin/krun",
  "/usr/local/bin/krun",
]



EOF

}




# ==============================================
# 2. prepare final distro's ISO directory structure
# ==============================================

# =========
# boot/grub

# grub config: ext2 supports ext3 and ext4 too
grub_config() {

if [ -d "$ISO_DIR"/boot/grub/ ]; then

sudo tee "$ISO_DIR"/boot/grub/grub.cfg > /dev/null <<"EOF"
# begin /boot/grub/grub.cfg
#
set default=0
set timeout=5

insmod part_gpt
insmod ext2
set root=(hd0,1)

menuentry "Busybox/Linux, Linux 6.6.22-kjx-12.1" {
        linux       /boot/vmlinuz-6.6.22-kjx-12.1 root=/dev/sda2 ro
}
EOF

else
    printf "\nThe $ISO_DIR/boot/grub/ directory doesn't exist.\n\n"
fi
}
#grub_config


# =========
# kernel and initramfs
kernel_config() {
sudo cp "$KERNEL_PATH" "$ISO_DIR/kernel"
sudo cp "$RAMDISK_PATH" "$ISO_DIR/kernel"
}

# =========
# syslinux
# =========

# =========
# boot/isolinux
# ============

## call isolinux_config function to boot from USB flash drive or CD-ROM
isolinux_config() {
sudo tee "$ISO_DIR/syslinux/isolinux.cfg" > /dev/null <<"EOF"
DEFAULT linux

LABEL linux
    KERNEL /kernel/$(basename "$KERNEL_PATH")
    APPEND initrd=/kernel/$(basename "$KERNEL_PATH")) security=selinux

LABEL fallback
    MENU LABEL KJX Linux Fallback
    LINUX ../vmlinuz-6.6.22-kjx-12.1
    APPEND root=/dev/sa3 rw
    INITRD ../initramfs-linux-fallback.img


# PC-DOS
LABEL pcdos
    KERNEL /kernel/memdisk
    APPEND initrd=/images/tools.imz

# Darik's boot and nuke
LABEL bootnuke
    KERNEL /kernel/memdisk
    APPEND initrd=/images/bootnuke.imz

# memtest86+
LABEL memtestp
    KERNEL /kernel/memtp170

EOF

sudo tee "$ISO_DIR/syslinux/boot.txt" > /dev/null <<"EOF"
☼09a☼07 - Boot A:
☼09b☼07 - Boot first HDD
☼09c☼07 - Boot next device

☼091☼07 - ☼0fPC-DOS☼07
☼092☼07 - Darik's Boot and Nuke
☼093☼07 - memtest86+
EOF

}
#isolinux_config

isolinux_config_binaries() {

# KJX/sources/bin or ROOTFS_PATH/usr/local/bin/syslinux-6.03/
# this function invocation comes after lines 673-675,
# which copies from the first to the second.

sudo cp "$KJX/sources/bin/syslinux-6.03/bios/core/isolinux.bin" "$ISO_DIR/syslinux/isolinux.bin"
sudo cp "$KJX/sources/bin/syslinux-6.03/bios/com32/elflink/ldlinux/ldlinux.c32" "$ISO_DIR/syslinux/ldlinux.c32"
}

# =========
# EFI
# TODO



system_info() {

# =========
# rootfs
#cp -r "$ROOTFS_PATH"/* "$ISO_DIR"/rootfs
sudo cp -r "$SQ_ROOTFS"/* "$ISO_DIR"/rootfs

### WARNING: REDO!
## ADAPTED FROM the runit_symlinks function.

# redo symlinks, gambi
# runtime link
sudo rm -rf "$ISO_DIR"/rootfs/var/service/*
for item in "$ISO_DIR"/rootfs/etc/sv/*; do
sudo ln -sf "$item" "$ISO_DIR"/rootfs/var/service/
done

# redo symlinks, gambi
sudo rm -rf $ISO_DIR/rootfs/etc/runit/runsvdir/default/*
for index in "$ISO_DIR"/rootfs/etc/sv/*; do
sudo ln -sf "$index" "$ISO_DIR"/rootfs/etc/runit/runsvdir/default/
done

sudo ln -sf "$ISO_DIR"/rootfs/etc/runit/1 "$ISO_DIR"/rootfs/sbin/init

# Linux Standard Base (LSB)-based system status
sudo tee "$ISO_DIR"/rootfs/etc/lsb-release > /dev/null <<"EOF"
DISTRIB_ID="LFS: kjx-headless"
DISTRIB_RELEASE="1.0"
DISTRIB_CODENAME="Mantis"
DISTRIB_DESCRIPTION="Linux From Scratch: kjx-headless build for virtual labs"


EOF

# init-system specific system status
sudo tee "$ISO_DIR"/rootfs/etc/lsb-release > /dev/null <<"EOF"
NAME="kjx-headless"
VERSION="1.0"
ID=kjx
PRETTY_NAME="LFS: kjx-headless 1.0"
VERSION_CODENAME="Mantis"
HOME_URL="github.com/kijinix/kjx-headless"


EOF

}
#system_info


set_sandboxes() {
printf  "\n==========\nSetting up sandboxes! \o/ \n===========\n\n"

#sudo mount -t tmpfs tmpfs "$KJX/tmp/"
kata_tmpdir=$(basename "$(mktemp -p "$KJX"/tmp/)")

# if base base bootable filesystem exists, leverage it and customize its rootfs
if [ -d $ISO_DIR ]; then
    cp -r "$ISO_DIR/*" "$kata_tmpdir"/

    #kata_tmpdir=$(basename "$(mktemp -p "$KJX"/tmp/"$kata_rootfs")")
    mkdir -p "$KJX"/tmp/"$kata_tmpdir"/rootfs/etc/kata-containers/
    mkdir -p "$KJX"/tmp/"$kata_tmpdir"/rootfs/opt/kata/bin/
    mkdir -p "$KJX"/tmp/"$kata_tmpdir"/rootfs/opt/kata/share/kata-containers/

    # all of kata-containers /opt/ directory is copied into the rootfs. Technically previous mkdirs are not needed.
    tar -xvf "$KJX"/sources/bin/kata-static-3.7.0-amd64.tar.xz -C "$KJX"/tmp/"$kata_tmpdir"/rootfs

    #sudo cp $KJX/tmp/"$kata_tmpdir"/opt/kata/bin/kata-runtime "$ROOTFS_PATH"/bin/
    #sudo cp $KJX/tmp/"$kata_tmpdir"/opt/kata/share/defaults/kata-containers/configuration.toml "$ROOTFS_PATH"/etc/kata-containers/
    #sudo cp $KJX/tmp/"$kata_tmpdir"/opt/kata/bin/qemu-system-x86_64  "$ROOTFS_PATH"/opt/kata/bin/
    #sudo cp $KJX/tmp/"$kata_tmpdir"/opt/kata/share/kata-containers/vmlinux.container "$ROOTFS_PATH"/opt/kata/share/kata-containers/
fi


# always inside a mount-namespace --make-private and after a chroot.
#. ./scripts/ccr.sh; checker && \
#    . $SCRIPTS_DIR_PATH/sandbox/getk3s.sh && \
#    . $SCRIPTS_DIR_PATH/sandbox/rootless-k3s.sh && \
#    . $SCRIPTS_DIR_PATH/sandbox/gvisor-startup.sh && \
#    . $SCRIPTS_DIR_PATH/sandbox/kata-startup.sh && \
#    . $SCRIPTS_DIR_PATH/sandbox/firecracker-startup.sh && \
#    . $SCRIPTS_DIR_PATH/sandbox/qemu-startup.sh && \
#    . $SCRIPTS_DIR_PATH/sandbox/youki-startup.sh
}

# =====================
#   3. Build step
# =====================

# busybox-sh based
mountns_sasquatch() {

MBR_BIN_PATH="$KJX/sources/bin/syslinux-6.03/bios/mbr/isohdpfx.bin"
# sink to the mount namespace
#mkdir -p /tmp/host_dir



#KJX="/mnt/kjx"


# these are idempotent
mkdir -pv $KJX/dev
mkdir -pv $KJX/tmp
mkdir -pv $KJX/proc
mkdir -pv $KJX/sys
mkdir -pv $KJX/run
# chapter 5 - fake the cross-compiler toolchain
mkdir -pv $KJX/tools

# mounts are for compiled LFS step
## populating /dev for the kjx mount (before chroot), all sudo
sudo mount -t devtmpfs devtmpfs "$KJX/dev/" #
sudo mount -t tmpfs tmpfs "$KJX/tmp/"

## mounting virtual kernel filesystems (before chroot), all sudo
sudo mount -vt devpts devpts -o gid=5,mode=0620 $KJX/dev/pts
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
sudo mount "$UPPER_LOOPDEV" "$ROOTFS_PATH"


# ================== OPEN =========================================



# copy initramfs to the artifacts qcow2 directory, then copy the latter to the squashfs directory
set_rootfs() {

if [ -d "$ROOTFS_PATH" ]; then
    sudo rm -rf "$ROOTFS_PATH"/*
else
    mkdir -p "$ROOTFS_PATH"
fi

# decompress and extract initramfs into rootfs_path // sudo
busybox gzip -dc "$INITRAMFS_BASE" | (cd "$ROOTFS_PATH" || return && busybox cpio -idmv && cd - || return)

if [ -d "$SQ_ROOTFS" ]; then
    rm -rf "$SQ_ROOTFS"/*
else
    mkdir -p "$SQ_ROOTFS"
fi

# copy rootfs_path contents to the squashed_rootfs
# cp -r "$ROOTFS_PATH/" "$SQ_ROOTFS"

}
set_rootfs

#compare


# mount the loop device into the rootfs
mount_loopdev

# function to set the fetch-verify-extract logic
verify_check_loop


# create runit-related directories
runit_directories

# function to setup busybox runit
runit_step

# setup symlinks
runit_symlinks

# PS: always inside a mount-namespace --make-private and after a chroot.

# copy rootfs_path contents to the squashed_rootfs

# enable containers
enable_containers

cp -r "$ROOTFS_PATH"/* "$SQ_ROOTFS"

# ================
# squashfs logic
# ================
mksquashfs "$SQ_ROOTFS" "$SQ_SQUASHFS/busybox.squashfs" -comp xz -b 256K -Xbcj x86

# use fuse-overlayfs to stack files and install additional programs
sudo mount -t squashfs "$SQ_SQUASHFS/busybox.squashfs" "$SQ_OVERLAY/merged"

fuse-overlayfs -o lowerdir="$SQ_OVERLAY/merged",upperdir="$SQ_OVERLAY/upperdir",workdir="$SQ_OVERLAY/workdir" "$SQ_OVERLAY/merged"
# unmounting:
# fusermount -u "$SQ_OVERLAY/merged"
# umount "$SQ_OVERLAY/merged"


# ====================
# b. compilation step [TODO]
# ====================
#pre_compile() {
#}

# function to setup sandboxes
# REFACTOR!! !! set_sandboxes



# prepare final distro's ISO directory structure
mkdir -p "$ISO_DIR"/boot/grub "$ISO_DIR"/boot/isolinux \
    "$ISO_DIR"/kernel "$ISO_DIR"/syslinux \
    "$ISO_DIR"/EFI/boot "$ISO_DIR"/rootfs

## call grub config function
grub_config

# setup kernel
kernel_config

# setup isolinux
isolinux_config
isolinux_config_binaries

# setup system info
system_info


enable_containers_isodir() {

if ! [ -d "$ISO_DIR"/rootfs/etc/containers ]; then
    mkdir -pv "$ISO_DIR"/rootfs/etc/containers
else
    printf "\nDirectory already exists.\n\n"
fi

tee "$ISO_DIR"/rootfs/etc/containers/containers.conf > /dev/null <<"EOF"

# Paths to look for a valid OCI runtime (crun, runc, kata, runsc, krun, etc)
[engine.runtimes]
crun = [
  "/usr/bin/crun",
  "/usr/sbin/crun",
  "/usr/local/bin/crun",
  "/usr/local/sbin/crun",
  "/sbin/crun",
  "/bin/crun",
  "/run/current-system/sw/bin/crun",
]

crun-vm = [
  "/usr/bin/crun-vm",
  "/usr/local/bin/crun-vm",
  "/usr/local/sbin/crun-vm",
  "/sbin/crun-vm",
  "/bin/crun-vm",
  "/run/current-system/sw/bin/crun-vm",
]

kata = [
  "/usr/bin/kata-runtime",
  "/usr/sbin/kata-runtime",
  "/usr/local/bin/kata-runtime",
  "/usr/local/sbin/kata-runtime",
  "/sbin/kata-runtime",
  "/bin/kata-runtime",
  "/usr/bin/kata-qemu",
  "/usr/bin/kata-fc",
]

runc = [
  "/usr/bin/runc",
  "/usr/sbin/runc",
  "/usr/local/bin/runc",
  "/usr/local/sbin/runc",
  "/sbin/runc",
  "/bin/runc",
  "/usr/lib/cri-o-runc/sbin/runc",
]

runsc = [
  "/usr/bin/runsc",
  "/usr/sbin/runsc",
  "/usr/local/bin/runsc",
  "/usr/local/sbin/runsc",
  "/bin/runsc",
  "/sbin/runsc",
  "/run/current-system/sw/bin/runsc",
]

youki = [
  "/usr/local/bin/youki",
  "/usr/bin/youki",
  "/bin/youki",
  "/run/current-system/sw/bin/youki",
]

krun = [
  "/usr/bin/krun",
  "/usr/local/bin/krun",
]



EOF

}

enable_containers_isodir

final_move() {
if verify_bin; then
#cp -r "$KJX"/sources/bin/* "$SQ_OVERLAY/upperdir/usr/local/bin/"

# custom binaries logic here
#cp -r $SQ_OVERLAY/upperdir/usr/local/bin/* $SQ_OVERLAY/merged/rootfs/usr/local/bin/

#cp -r $SQ_OVERLAY/merged/* $ROOTFS_PATH/

else
    printf "\n\nVerification of binaries failed. Exiting mount #namespace...\n\n"
fi


}
final_move


touch "$ISO_DIR"/boot/grub/efi.img
dd if=/dev/zero of="$ISO_DIR"/boot/grub/efi.img bs=1M count=20
mkfs.vfat "$ISO_DIR"/boot/grub/efi.img

efi_tmpdir=$(/bin/busybox mktemp -d)
sudo mount "$ISO_DIR"/boot/grub/efi.img "$efi_tmpdir"

sudo mkdir -pv "$efi_tmpdir"/EFI/boot
sudo grub-mkstandalone -O x86_64-efi -o "$efi_tmpdir"/EFI/boot/bootx64.efi "boot/grub/grub.cfg=/boot/grub/grub.cfg"

sudo umount $efi_tmpdir


# eltorito part
ISO_GRUB_PRELOAD_MODULES="part_gpt part_msdos ext2 normal linux iso9660 udf all_video video_fb search configfile echo cat"

mkdir -p $ISO_DIR/boot/grub/i386-pc

routine=$(uname -m)


if [[ $routine = x86_64 ]]; then
    grub-mkimage \
        -O i386-pc \
        -o /tmp/core.img \
        -p /boot/grub biosdisk $ISO_GRUB_PRELOAD_MODULES
    cat /usr/lib/grub/i386-pc/cdboot.img /tmp/core.img \
        > $ISO_DIR/boot/grub/i386-pc/eltorito.img
fi

#"$MBR_BIN_PATH"

### 5. package the final filesystem into an ISO9660 image using xorriso.
# search workdir: /boot/syslinux directory
xorriso -as mkisofs -o kjx-headless.iso \
    -J -l \
    -isohybrid-mbr /usr/lib/syslinux/bios/isohdpfx.bin \
    -b syslinux/isolinux.bin \
    -c boot/boot.cat \
    -b boot/grub/i386-pc/eltorito.img \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -eltorito-alt-boot \
    -e /boot/grub/efi.img \
    -no-emul-boot \
    -isohybrid-gpt-basdat \
    -r -V "My Linux" "$ISO_DIR"



### 6. Copy the iso file outside the namespace

cp /mnt/output/my_custom.iso "./artifacts/kjx-headless.iso"

# exits the mount namespace
exit

}

FULL
)



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
        /bin/sh -c "$GNT"

# set environment variables
set_vars


# stop loop devices
losetup -D

# kill the daemon
kill -SIGTERM qsd_pid


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
