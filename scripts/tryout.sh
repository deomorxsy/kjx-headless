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
# KERNEL_PATH="./artifacts/bzImage"
# RAMDISK_PATH="./artifacts/netpowered.cpio.gz"
WHICH_VIRT="./artifacts/capScope"
#ISO_GRUB_PRELOAD_MODULES="part_gpt part_msdos linux normal iso9660 udf all_video video_fb search configfile echo cat"
ISO_GRUB_PRELOAD_MODULES="part_gpt part_msdos ext2 normal linux iso9660 udf all_video video_fb search configfile echo cat"


KERNEL_PATH="$HOME/Downloads/kjxh-artifacts/bzImage"
RAMDISK_PATH="$HOME/Downloads/kjxh-artifacts/another/rootfs_v15.cpio.gz"
ROOTFS_PATH="./artifacts/burn/rootfs/"
#ROOTFS_PATH="./artifacts/qcow2-rootfs/rootfs"

# loop device handling with u
# from part 17 of ./scripts/squashed
UPPER_LOOPDEV="$(losetup  | awk 'NR==2 {print $1}')"
UPPER_BASE_IMG=$(losetup  | awk 'NR==2 {print $6}')


# for bootloaders, isolinux/syslinux or grub
KERNEL_BASENAME=$(basename "$KERNEL_PATH")
INITRAMFS_BASENAME=$(basename "$RAMDISK_PATH")
SYSLINUX_BOOTBIN="./artifacts/distro/syslinux-6.03/bios/core/isolinux.bin"
ELTORITO_PATH="./eltorito.img"
ISOHDPFX_PATH="./artifacts/distro/syslinux-6.03/bios/mbr/isohdpfx.bin"
ISO_FINAL_PATH="$PWD/artifacts/kjx-headless.iso"
EFI_PATH="$ISO_DIR/boot/grub/efi.img"

#
}



#scaffolding() {
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
    # qemu-img create -f raw "$IMAGE_PATH" 250M
    qemu-img create -f raw "$IMAGE_PATH" 512M

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
losetup -fP "$QCOW_PATH"

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
# UPPER_LOOPDEV=$(losetup -a | awk 'NR==2 {print $1}' )
#UPPER_BASE_IMG=$(losetup -a | awk 'NR==2 {print $4}' | sed 's/(//' | sed 's/)//')

UPPER_LOOPDEV="$(losetup  | awk 'NR==2 {print $1}')"
UPPER_BASE_IMG=$(losetup  | awk 'NR==2 {print $6}')
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
#}


# =========================================

# copy initramfs to the artifacts qcow2 directory, then copy the latter to the squashfs directory
#set_rootfs() {

if [ -d "$ROOTFS_PATH" ]; then
    rm -rf "${ROOTFS_PATH:?}/"*
else
    mkdir -p "$ROOTFS_PATH"
fi

# decompress and extract initramfs into rootfs_path // sudo
busybox gzip -dc "$RAMDISK_PATH" | (cd "$ROOTFS_PATH" || return && busybox cpio -idmv && cd - || return)


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

# 17. mount the loop device into the rootfs
#mount_loopdev() {
printf "=============|> [STEP 6]: mount the loop device into the rootfs.\n=============\n\n"
mkdir -p "$UPPER_MOUNTPOINT"/rootfs # mkdir a directory for the rootfs




# busybox-sh based
# mountns_sasquatch() {

MBR_BIN_PATH="$KJX/sources/bin/syslinux-6.03/bios/mbr/isohdpfx.bin"
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

#}

# runit_step() {
# =============================

(
cat <<"EOF"
#!/bin/sh
#
exec /sbin/getty 38400 tty1


EOF
) | tee "$ROOTFS_PATH/etc/sv/getty-tty1/run"

chmod +x "$ROOTFS_PATH/etc/sv/getty-tty1/run"




# ============================

(
cat <<"INIT_EOF"
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
) | tee "$ROOTFS_PATH/etc/runit/1"

chmod +x "$ROOTFS_PATH/etc/runit/1"

ln -sf "$ROOTFS_PATH/etc/runit/1" "$ROOTFS_PATH/sbin/init"
#}

#runit_symlinks() {
# this bootstraps the set_sandboxes function
# inside runit, as well as any hotfixes needed
# from the previous mksquashfs (deep copy) followed
# by cp (shallow copy) steps.


# setup runit to start the C program to control both k3s and the tracer at startup
mkdir -p "$ROOTFS_PATH"/etc/sv/clusterbuild/

(
cat <<BEETOR_EOF
#!/bin/sh

#exec /usr/bin/cpuram_task


mkdir -p /app/piest.yaml
(
cat <<PIEST
apiVersion: v1
kind: Pod
metadata:
  name: pi
  namespace: kjx
spec:
  runtimeClassName: runc  # Change to crun or runsc in different tests
  containers:
  - name: pi
    image: busybox
    command: ["sh", "-c", "awk 'BEGIN { for(i=1;i<10000;i+=2) s+=4*((i%4==1)?1:-1)/i; print s }'"]
    resources:
      limits:
        memory: "32Mi"
        cpu: "100m"
  restartPolicy: Never

PIEST
 ) | tee ./app/piest.yaml


# Orchestrator script
exec /usr/bin/bwcoff
# -> calls k3s with Pi approximation workload (tracee
#    |
#    --> calls /app/piest.yaml to get the manifest
#
# -> calls Ftrace/libbpf CO-RE (tracers)

# prepare run directory for containerd and k3s
mkdir -p /run /var/run
mount -t tmpfs tmpfs /run
ln -s /run /var/ 2>/dev/null

mkdir -p /run/k3s/containerd
mkdir -p /var/lib/rancher/k3s
mkdir -p /etc/rancher/k3s

# Unsquash the squashfs with the airgap images inside
mkdir -p /mnt/airgap-registry-image/
mkdir -p /mnt/k3s-squashfs

mount /dev/sdb /mnt/airgap-registry-image/

cd /mnt/airgap-registry-image || return

ls -allhtr /mnt/airgap-registry-image

unsquashfs -d ../k3s-squashfs/ ./k3s-tarball.squashfs

cd - || return

# Bring network up
ip link set lo up


ln -s /run/containerd/containerd.sock /run/k3s/containerd/
containerd &

mkdir -p /app


ls -allhtr

(
cat <<TRACEE_EOF
#!/bin/sh

unshare --fork --pid --mount-proc --uts --net --ipc '
k3s server --disable-agent --default-runtime=runc & > /dev/null 2>&1

# works now
k3s ctr namespace list

# create namespace and import the airgap tarball

k3s kubectl create namespace pia
k3s ctr -n=pia images import /mnt/k3s-squashfs/k3s-airgap-images-amd64.tar

# kubectl apply manifest
# manifest references image inside the localhost registry
# pull from registry on localhost
'
TRACEE_EOF
) | tee /app/tracee_unshared.sh

chmod +x /app/tracee_unshared.sh

mkdir -p /sys/fs/cgroup/k3s-tracee/
echo $$ > /sys/fs/cgroup/k3s-tracee/cgroup.procs
/app/tracee_unshared.sh



exec /usr/bin/beetor

BEETOR_EOF
) | tee "$ROOTFS_PATH"/etc/sv/clusterbuild/run

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

#}

#enable_containers_isodir() {

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

#}

# Create squashfs destination paths
mkdir -pv "$SQ_ROOTFS"
mkdir -pv "$SQ_SQUASHFS"
mkdir -pv "$SQ_OVERLAY/upperdir/usr/local/bin/"

mkdir -pv "$SQ_OVERLAY/upperdir"
mkdir -pv "$SQ_OVERLAY/workdir"
mkdir -pv "$SQ_OVERLAY/merged"


BUILDER_ROOTFS_DIR=$HOME/Downloads/kjxh-artifacts/another/newfrdir
cp -r $BUILDER_ROOTFS_DIR/* "$ROOTFS_PATH"
sudo cp $BUILDER_ROOTFS_DIR/lib/libdevmapper.so.1.02 $ROOTFS_PATH/lib/
sudo cp $BUILDER_ROOTFS_DIR/usr/lib/libtcl8.6.so $ROOTFS_PATH/usr/lib/



sudo cp -r "$ROOTFS_PATH"/* "$SQ_ROOTFS"

# ================
# squashfs logic
# ================
mksquashfs "$SQ_ROOTFS" "$SQ_SQUASHFS/busybox.squashfs" -comp xz -b 256K -Xbcj x86

# use fuse-overlayfs to stack files and install additional programs
sudo mount -t squashfs "$SQ_SQUASHFS/busybox.squashfs" "$SQ_OVERLAY/merged"

sudo fuse-overlayfs -o lowerdir="$SQ_OVERLAY/merged",upperdir="$SQ_OVERLAY/upperdir",workdir="$SQ_OVERLAY/workdir" "$SQ_OVERLAY/merged"
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
mkdir -pv "$ISO_DIR"/boot/grub "$ISO_DIR"/boot/isolinux \
    "$ISO_DIR"/kernel "$ISO_DIR"/syslinux \
    "$ISO_DIR"/EFI/boot "$ISO_DIR"/rootfs

#grub_config() {
## call grub config function

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
        linux       /boot/bzImage-6.6.22-kjx-12.1 root=/dev/sda2 ro
}
EOF

else
    printf "\nThe %s/boot/grub/ directory doesn't exist.\n\n" "$ISO_DIR"
fi
#}

#kernel_config() {
# Copy kernel and initramfs
sudo cp "$KERNEL_PATH" "$ISO_DIR/kernel"
sudo cp "$RAMDISK_PATH" "$ISO_DIR/kernel"
#}

# =========
# syslinux
# =========

# =========
# boot/isolinux
# ============

# prepare memdisk
cp ./artifacts/distro/syslinux-6.03/bios/memdisk/memdisk "$ISO_DIR/kernel/"


## call isolinux_config function to boot from USB flash drive or CD-ROM
#isolinux_config() {

KERNEL_BASENAME=$(basename "$KERNEL_PATH")
INITRAMFS_BASENAME=$(basename "$RAMDISK_PATH")

#cp $INITRAMFS_BASENAME $ISO_DIR/kernel/

sudo tee "$ISO_DIR/syslinux/isolinux.cfg" > /dev/null <<EOF
DEFAULT linux

LABEL linux
    KERNEL /kernel/${KERNEL_BASENAME}
    APPEND initrd=/kernel/${INITRAMFS_BASENAME} security=selinux console=ttyS0 root=/dev/sda earlyprintk net.ifnames=0 cgroup_no_v1=all

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

#}
#isolinux_config

#isolinux_config_binaries() {

# KJX/sources/bin or ROOTFS_PATH/usr/local/bin/syslinux-6.03/
# this function invocation comes after lines 673-675,
# which copies from the first to the second.

sudo cp "$KJX/sources/bin/syslinux-6.03/bios/core/isolinux.bin" "$ISO_DIR/syslinux/isolinux.bin"
sudo cp "$KJX/sources/bin/syslinux-6.03/bios/com32/elflink/ldlinux/ldlinux.c32" "$ISO_DIR/syslinux/ldlinux.c32"
#}




# =========
# EFI
# TODO



#system_info() {

# =========
# rootfs
#cp -r "$ROOTFS_PATH"/* "$ISO_DIR"/rootfs

sudo cp -r "$SQ_ROOTFS"/* "$ISO_DIR"/rootfs

mkdir -p "$ISO_DIR"/rootfs/app/scripts/
cp -r ./scripts/* "$ISO_DIR"/rootfs/app/scripts

### WARNING: REDO!
## ADAPTED FROM the runit_symlinks function.

# redo symlinks, gambi
# runtime link
sudo rm -rf "$ISO_DIR"/rootfs/var/service/*
for item in "$ISO_DIR"/rootfs/etc/sv/*; do
sudo ln -sf "$item" "$ISO_DIR"/rootfs/var/service/
done

# redo symlinks, gambi
sudo rm -rf "$ISO_DIR"/rootfs/etc/runit/runsvdir/default/*
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

#}
#system_info


# final_move

touch "$ISO_DIR"/boot/grub/efi.img
dd if=/dev/zero of="$ISO_DIR"/boot/grub/efi.img bs=1M count=20
mkfs.vfat "$ISO_DIR"/boot/grub/efi.img

EFI_TMPDIR=$(/bin/busybox mktemp -d)
sudo mount "$ISO_DIR"/boot/grub/efi.img "$EFI_TMPDIR"

sudo mkdir -pv "$EFI_TMPDIR/EFI/boot"
sudo grub-mkstandalone -O x86_64-efi -o "$EFI_TMPDIR/EFI/boot/bootx64.efi" "boot/grub/grub.cfg=/boot/grub/grub.cfg"

sudo umount "$EFI_TMPDIR"


# eltorito part
ISO_GRUB_PRELOAD_MODULES="part_gpt part_msdos ext2 normal linux iso9660 udf all_video video_fb search configfile echo cat"
mkdir -p "$ISO_DIR/boot/grub/i386-pc"

routine=$(uname -m)

# if [[ $routine = x86_64 ]]; then
#     grub-mkimage \
#         -O i386-pc \
#         -o /tmp/core.img \
#         -p /boot/grub biosdisk $ISO_GRUB_PRELOAD_MODULES
#     cat /usr/lib/grub/i386-pc/cdboot.img /tmp/core.img \
#         > $ISO_DIR/boot/grub/i386-pc/eltorito.img
# fi


SYSLINUX_BOOTBIN="./artifacts/distro/syslinux-6.03/bios/core/isolinux.bin"
ELTORITO_PATH="./eltorito.img"

# artifacts/distro/packages/syslinux-4.05/mbr/isohdpfx.bin
# artifacts/distro/syslinux-6.03/efi64/mbr/isohdpfx.bin
# artifacts/distro/syslinux-6.03/efi32/mbr/isohdpfx.bin
#▌artifacts/distro/syslinux-6.03/bios/mbr/isohdpfx.bin

ISOHDPFX_PATH="./artifacts/distro/syslinux-6.03/bios/mbr/isohdpfx.bin"

ISO_FINAL_PATH="$PWD/artifacts/kjx-headless.iso"
EFI_PATH="$ISO_DIR/boot/grub/efi.img"

### 5. package the final filesystem into an ISO9660 image using xorriso.
# search workdir: /boot/syslinux directory
# xorriso -as mkisofs -o "$ISO_FINAL_PATH" \
#     -J -l \
#     -b "$SYSLINUX_BOOTBIN" \
#     -c boot/boot.cat \
#     -b "$ELTORITO_PATH" \
#     -no-emul-boot \
#     -boot-load-size 4 \
#     -boot-info-table \
#     -eltorito-alt-boot \
#     -e "$EFI_PATH" \
#     -no-emul-boot \
#     -isohybrid-mbr "$ISOHDPFX_PATH" \
#     -isohybrid-gpt-basdat \
#     -r -V "My Linux" "$ISO_DIR"

# fixed
xorriso -as mkisofs -o "$ISO_FINAL_PATH"_v2.iso \
  -J -l \
  -V "KJX_HEADLESS" \
  -b syslinux/isolinux.bin \
    -c boot/boot.cat \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
  -eltorito-alt-boot \
    -e boot/grub/efi.img \
    -no-emul-boot \
    -isohybrid-mbr artifacts/distro/syslinux-6.03/bios/mbr/isohdpfx.bin \
    -isohybrid-gpt-basdat \
    -r "$ISO_DIR"

### 6. Copy the iso file outside the namespace
# cp /mnt/output/my_custom.iso "./artifacts/kjx-headless.iso"
printf "\n=============================="
printf "\n\n|> ISO Build complete with success! \n\n"

