#!/bin/sh

QCOW_PATH="./artifacts/foo.qcow2"
IMAGE_PATH="./artifacts/foo.img"
INITRAMFS_BASE="./artifacts/netpowered.cpio.gz"
UPPER_MOUNTPOINT="./artifacts/qcow2-rootfs"
KJX="/mnt/kjx"
ROOTFS_PATH="$UPPER_MOUNTPOINT/rootfs"
SCRIPTS_DIR_PATH=./scripts

# squashfs
SQ_ROOTFS="/tmp/kjx_rootfs/"
SQ_SQUASHFS="/tmp/kjx_squashfs/"
SQ_OVERLAY="/tmp/kjx_overlay/"

# wget-lists
WGET_BIN_FILES="./artifacts/wget-list-bin.txt"
WGET_COMPILE="./artifacts/wget-list-compile.txt"

# isogen
ISO_DIR="./artifacts/burn"
# fetch bzImage and initramfs.cpio.gz from previous actions:
KERNEL_PATH="./artifacts/bzImage"
RAMDISK_PATH="./artifacts/netpowered.cpio.gz"
ROOTFS_PATH="./artifacts/qcow2-rootfs/rootfs"





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


# ==================================================================
#
# FIRST BATCH
#
# ==================================================================

# 1. if there is no file IMAGE_PATH, create one
# workdir /app
mkdir -p ./artifacts
if ! [ -f "$IMAGE_PATH" ]; then

    printf "\n\n======\nCreating image now!!!\n=========\n\n"
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
rm "$IMAGE_PATH"

# 6. print qcow file type
file "$QCOW_PATH"

# 7. list partition mappings as a block device
kpartx -a "$QCOW_PATH"

# 8. check if user_allow_other is enabled on /etc/fuse.conf for rootless passing
#IS_FUSE_ALLOWED=$(grep -n '#user_allow_other' /etc/fuse.conf | tail -1)
#IS_FUSE_ALLOWED=$(grep -n -o '#user_allow_other' /etc/fuse.conf | tail -1 | cut -d: -f2-)
IS_FUSE_ALLOWED=$(grep -E '^user_allow_other' /etc/fuse.conf)
# this bypass but not parse the '#' symbol. It does not detect if it is allowed.
#cat /etc/fuse.conf > /etc/fuse.conf.bak

if [ -n "$IS_FUSE_ALLOWED" ]; then
# if user_allow_other is non-zero:
#
# 9. run qsd on background; SIGKILL when finished
qemu-storage-daemon \
    --blockdev node-name=prot-node,driver=file,filename="$QCOW_PATH" \
    --blockdev node-name=fmt-node,driver=qcow2,file=prot-node \
    --export type=fuse,id=exp0,node-name=fmt-node,mountpoint="$QCOW_PATH",writable=on \
    &

# 10.
mount | grep qcow2

# 11. add partition mappings, verbose, under /dev/mapper/loopX
kpartx -av "$QCOW_PATH"

# 12. get info from mounted qcow2 device mapping
qemu-img info "$QCOW_PATH"
#foo.qcow2

else
    echo "Could not start qemu-storage-daemon process since user_allow_other is not enabled at /etc/fuse.conf."
fi


# 13. mount the loop device

sudo losetup -fP "$QCOW_PATH"
# -f: find and -P: scan the partition table on newly created loop device

# 14. list status of all loop devices
losetup -a

# 15. mount loopback device into the mountpoint to setup rootfs
UPPER_LOOPDEV=$(losetup -l | awk 'NR==2 {print $1}')
upper_base_img=$(losetup -l | awk 'NR==2 {print $6}')

# 16.
setcap cap_sys_admin+eip "$(readlink -f "$(which mkfs.ext4)")"
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
    echo "Error: The provided qcow2 image $check_loopdevfs is already formatted with a filesystem mounted as Loop Device at $upper_base_img."
fi

# 17. mount the loop device into the rootfs
printf "=============|> [STEP 6]: mount the loop device into the rootfs.\n=============\n\n"

mkdir -p "$UPPER_MOUNTPOINT"/rootfs # mkdir a directory for the rootfs
sudo mount "$UPPER_LOOPDEV" "$UPPER_MOUNTPOINT"/rootfs # mount loop device into the generic dir
# sudo mount


# sudo mkdir
mkdir -p $KJX/sources/bin
#
# ==================================================================
#
# 18. mount namespaces
#
# ==================================================================

# 25. fetch binaries
# fetch binaries
fetch_bin() {
    #mkdir -p "$KJX/sources/bin"
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

cp ./artifacts/sources/* "$KJX/sources/bin/"
cd "$KJX/sources/bin/" || return

# decompress tarballs
for item in  ./*.tar.gz; do
    tar -xvf "$item"
done

cd - || return
}


verify_check_loop() {
#
#
#verify_bin
fetch_counter=0

if verify_bin; then
    cd "$KJX/sources/bin/" || return
    listdirs=$(find . -maxdepth 1 -type f,d ! -name "*.tar*")
    # echo $listdirs
    #. ./syslinux-6.03 ./grub-2.12 ./sha256sums_isogen.txt ./k3s ./gvisor-release-20240807.0 ./libcap-1.2.70

    listtars=$(find . -maxdepth 1 -type f,d -name "*.tar*")
    istardir=$(echo "$listtars" | sed 's/\.tar\.\(xz\|gz\)//g')

    for item in $istardir; do
        case "$item" in
            *"$listdirs"*)
                echo "substring found!"
                #pass
                ;;
            *)
                echo "substring not found."
                #extract_bin
                ;;
        esac
    done


    cd - || return

    cp -r "$KJX/sources/bin/" "$SQ_OVERLAY/upperdir/usr/local/bin/"
    cp -r "$SQ_OVERLAY/merged" "$ROOTFS_PATH"


elif ! verify_bin; then
    while [ $fetch_counter -le 3 ]
    do
        fetch_bin
        fetch_counter=$((fetch_counter+1))
    done
else
    printf "\n\n=======\nVerification of fetched files failed T_T. Maybe you should exit the mount namespace... ;] \n============\n"
fi

}



set_sandboxes() {
printf  "\n==========\nSetting up sandboxes! \o/ \n===========\n\n"
# always inside a mount-namespace --make-private and after a chroot.
. ./scripts/ccr.sh; checker && \
    . $SCRIPTS_DIR_PATH/sandbox/gvisor-startup.sh && \
    . $SCRIPTS_DIR_PATH/sandbox/firecracker-startup.sh && \
    . $SCRIPTS_DIR_PATH/sandbox/kata-startup.sh && \
    . $SCRIPTS_DIR_PATH/sandbox/qemu-startup.sh && \
    . $SCRIPTS_DIR_PATH/sandbox/youki-startup.sh
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
/bin/runqlat

INIT_EOF

chmod +x "$ROOTFS_PATH/etc/runit/1"

ln -sf "$ROOTFS_PATH/etc/runit/1" "$ROOTFS_PATH/sbin/init"
}
#runit_step




runit_symlinks() {
#set_sandboxes

# runtime link
for item in "$ROOTFS_PATH/etc/sv/"*; do
ln -s "$item" "$ROOTFS_PATH/var/service/"
done

# runit: symbolic link convention
for index in "$ROOTFS_PATH/etc/sv/"*; do
ln -s "$index" "$ROOTFS_PATH/etc/runit/runsvdir/default/"
done
}







# ==============================================
# 2. prepare final distro's ISO directory structure
# ==============================================

# =========
# boot/grub

## call grub config function
#grub_config

# grub config: ext2 supports ext3 and ext4 too
grub_config() {
cat <<"EOF" > "$ISO_DIR/boot/grub/grub.cfg"
# begin /boot/grub/grub.cfg
#
set default=0
set timeout=5

insmod part_gpt
insmod ext2
set root=(hd0,2)

menuentry "Busybox/Linux, Linux 6.6.22-kjx-12.1" {
        linux       /boot/vmlinuz-6.6.22-kjx-12.1 root=/dev/sda2 ro
}
EOF
}
#grub_config
# =========
# boot/isolinux

#isolinux_config

# =========
# kernel
kernel_config() {
cp "$KERNEL_PATH" "$ISO_DIR/kernel"
cp "$RAMDISK_PATH" "$ISO_DIR/kernel"
}
# =========
# syslinux

## call isolinux config function
#isolinux_config


# isolinux config to boot from USB flash drive or CD-ROM
isolinux_config() {
cat <<"EOF" > "$ISO_DIR/syslinux/isolinux.cfg"
DEFAULT linux

LABEL linux
    KERNEL /boot/vmlinuz
    APPEND initrd=/boot/initrd.img security=selinux

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

cat <<"EOF" > "$ISO_DIR/syslinux/boot.txt"
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
cp "$KJX/sources/bin/syslinux-6.03/bios/core/isolinux.bin" "$ISO_DIR/syslinux/isolinux.bin"
cp "$KJX/sources/bin/syslinux-6.03/bios/com32/elflink/ldlinux/ldlinux.c32" "$ISO_DIR/syslinux/ldlinux.c32"
}
# =========
# EFI


# =========
# rootfs
# cp -r "$ROOTFS_PATH" "$ISO_DIR/rootfs"

system_info() {
# Linux Standard Base (LSB)-based system status
cat <<"EOF" > "$ISO_DIR/rootfs/etc/lsb-release"
DISTRIB_ID="LFS: kjx-headless"
DISTRIB_RELEASE="1.0"
DISTRIB_CODENAME="Mantis"
DISTRIB_DESCRIPTION="Linux From Scratch: kjx-headless build for virtual labs"
EOF

# init-system specific system status
cat <<"EOF" > "$ISO_DIR/rootfs/etc/lsb-release"
NAME="kjx-headless"
VERSION="1.0"
ID=kjx
PRETTY_NAME="LFS: kjx-headless 1.0"
VERSION_CODENAME="Mantis"
HOME_URL="github.com/kijinix/kjx-headless"
EOF

}
#system_info

# =====================
#
#   3. Build step
#
# =====================






# busybox-sh based
mountns_sasquatch() {

mbr_bin_path="$KJX/sources/bin/syslinux-6.03/bios/mbr/isohdpfx.bin"
# sink to the mount namespace
mkdir -p /tmp/host_dir


# make sure propagation is used, so mount --make-private starts by default
unshare --mount --propagation=private \
        --uts --ipc --net \
        --fork --pid \
        --mount-proc \
        /bin/sh -c <<EOF


KJX="/mnt/kjx"

mkdir -p $KJX/dev
mkdir -p $KJX/tmp
mkdir -p $KJX/proc
mkdir -p $KJX/sys
mkdir -p $KJX/run
mkdir -p $KJX/tools

# populating /dev for the kjx mount (before chroot)
mount -t devtmpfs devtmpfs "$KJX/dev/" #
mount -t tmpfs tmpfs "$KJX/tmp/"

# mounting virtual kernel filesystems (before chroot)
mount -vt devpts devpts -o gid=5,mode=0620 $LFS/dev/pts
mount -vt proc proc "$KJX/proc"
mount -vt sysfs sysfs "$KJX/sys"
mount -vt tmpfs tmpfs "$KJX/run"

# setting up the bind mount
mkdir -p $KJX/sources/release
mount --bind /mnt/kjx/sources/release /tmp/host_dir

# chapter 5 - fake the cross-compiler toolchain
mkdir -p "$KJX/tools"

# squashfs
SQ_ROOTFS="/tmp/kjx_rootfs/"
SQ_SQUASHFS="/tmp/kjx_squashfs/"
SQ_OVERLAY="/tmp/kjx_overlay/"

QCOW_PATH="./artifacts/foo.qcow2"
IMAGE_PATH="./artifacts/foo.img"
INITRAMFS_BASE="./artifacts/netpowered.cpio.gz"
UPPER_MOUNTPOINT="./artifacts/qcow2-rootfs"
KJX="/mnt/kjx"
ROOTFS_PATH="$UPPER_MOUNTPOINT/rootfs"
SCRIPTS_DIR_PATH=./scripts

# squashfs
SQ_ROOTFS="/tmp/kjx_rootfs"
SQ_SQUASHFS="/tmp/kjx_squashfs"
SQ_OVERLAY="/tmp/kjx_overlay"



mkdir -p "$SQ_ROOTFS"
mkdir -p "$SQ_SQUASHFS"
#mkdir -p "$SQ_OVERLAY/upperdir/usr/local/bin/"

mkdir -p "$SQ_OVERLAY/upperdir"
mkdir -p "$SQ_OVERLAY/workdir"
mkdir -p "$SQ_OVERLAY/merged"

# =============
# populate rootfs directory using the busybox directory tree from the initramfs
# =============

mkdir -p "$ROOTFS_PATH"
mount "$UPPER_LOOPDEV" "$ROOTFS_PATH"

# copy initramfs to the artifacts qcow2 directory, then copy the latter to the squashfs directory
set_rootfs() {
gzip -dc "$INITRAMFS_BASE" | (cd "$ROOTFS_PATH" || return && cpio -idmv && cd - || return)
cp -r "$ROOTFS_PATH/" "$SQ_ROOTFS"
}
set_rootfs

#compare

# ================
# squashfs logic
# ================
mksquashfs "$SQ_ROOTFS" "$SQ_SQUASHFS/busybox.squashfs" -comp xz -b 256K -Xbcj x86

# use fuse-overlayfs to stack files and install additional programs
mount -t squashfs "$SQ_SQUASHFS/busybox.squashfs" "$SQ_OVERLAY/merged"

fuse-overlayfs -o lowerdir="$SQ_OVERLAY/merged",upperdir="$SQ_OVERLAY/upperdir",workdir="$SQ_OVERLAY/workdir" "$SQ_OVERLAY/merged"
# unmounting:
# fusermount -u "$SQ_OVERLAY/merged"
# umount "$SQ_OVERLAY/merged"



# function to set the fetch-verify-extract logic
verify_check_loop

# function to setup sandboxes
set_sandboxes

# create runit-related directories
runit_directories

# function to setup busybox runit
runit_step

# setup symlinks
runit_symlinks

# PS: always inside a mount-namespace --make-private and after a chroot.



# ====================
# b. compilation step [TODO]
# ====================
#pre_compile() {
#}

#if verify_bin; then
cp -r "$KJX/sources/bin/" "$SQ_OVERLAY/upperdir/usr/local/bin/"
cp -r "$SQ_OVERLAY/merged" "$ROOTFS_PATH"

#else
#    printf "\n\nVerification of binaries failed. Exiting mount #namespace...\n\n"
#    break
#fi

# prepare final distro's ISO directory structure
mkdir -p "$ISO_DIR"/boot/grub "$ISO_DIR"/boot/isolinux \
    "$ISO_DIR"/kernel "$ISO_DIR"/syslinux \
    "$ISO_DIR"/EFI/boot "$ISO_DIR"/rootfs

# setup grub
grub_config

# setup kernel
kernel_config

# setup isolinux
isolinux_config
isolinux_config_binaries

# setup system info
system_info

#compare


### 5. package the final filesystem into an ISO9660 image using xorriso.

# xorriso -as mkisofs -o /mnt/output/my_custom.iso /mnt/overlay/merged


# search workdir: /boot/syslinux directory
xorriso -as mkisofs -o output.iso \
    -isohybrid-mbr "$mbr_bin_path" \
    -b "$ISO_DIR/syslinux/isolinux.bin" \
    -c boot/boot.cat -b boot/grub/i386-pc/eltorito.img \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -eltorito-alt-boot -e boot/grub/efi.img \
    -no-emul-boot -isohybrid-gpt-basdat \
    -V "My Linux" ./artifacts/burn/



### 6. Copy the iso file outside the namespace

cp /mnt/output/my_custom.iso "./artifacts/kjx-headless.iso"

# exits the mount namespace
exit

EOF
}
#mountns_sasquatch








if [ "$1" = "fetch_bin" ]; then
    fetch_bin
elif [ "$1" = "verify_bin" ]; then
    verify_bin
elif [ "$1" = "extract_bin" ]; then
    extract_bin
fi
