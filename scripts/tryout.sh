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
#RAMDISK_PATH="$HOME/Downloads/kjxh-artifacts/another/rootfs_v15.cpio.gz"
RAMDISK_PATH="/home/asari/Downloads/kjxh-artifacts/another/rootfs_v28.cpio.gz"
ROOTFS_PATH="./artifacts/burn/rootfs"
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
ISO_FINAL_PATH="$PWD/artifacts"
EFI_PATH="$ISO_DIR/boot/grub/efi.img"



SOURCE_ROOTFS_DIR="./artifacts/burn/rootfs"
SQUASHFS_IMAGE="./artifacts/rootfs.sqfs"
ISO_INITRAMFS="initramfs-ssh.cpio.gz"

#
BUILDER_ROOTFS_DIR="$HOME"/Downloads/kjxh-artifacts/another/newfrdir
}

set_vars

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

# sudo ln -sf "$ISO_DIR"/rootfs/etc/runit/1 "$ISO_DIR"/rootfs/sbin/init
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


# Setup storage info for containers
# this need user management enabled
(
cat <<EOF
[storage]
driver = "overlay"

# Default Storage Driver, Must be set for proper operation.
driver = "overlay"

# Temporary storage location
runroot = "/run/containers/storage"
graphroot = "/var/lib/containers/storage"

# Storage path for rootless users
rootless_storage_path = "$HOME/.local/share/containers/storage"

[storage.options]
pull_options = {enable_partial_images = "false", use_hard_links = "false", ostree_repos=""}
additionalimagestores = [
]

[storage.options.overlay]

# Path to an helper program to use for mounting the file system instead of mounting it
# directly.
mount_program = "/usr/bin/fuse-overlayfs"

# mountopt specifies comma separated list of extra mount options
mountopt = "nodev"


EOF
) | tee /etc/containers/storage.conf


# =======================
#  User, groups and shadow password management

# Configure passwd management
(
cat <<EOF
root:x:0:0:root:/root:/bin/ash
kjx:x:1000:1000:kjx:/home/kjx:/bin/ash
EOF
) | tee "$ROOTFS_PATH"/etc/passwd


# Configure group management
(
cat <<EOF
root:x:0:
bin:x:1:
EOF
) | tee "$ROOTFS_PATH"/etc/group

# Setup doas superuser management
#
echo "permit persist :wheel" >> "$ROOTFS_PATH"/etc/doas.d/20-wheel.conf

# Setup ash shell dotfiles

# Openrc-based profile.d
(
cat <<EOF
if [ -f "$HOME/.config/ash/profile" ]; then
	. "$HOME/.config/ash/profile"
fi
EOF
) | tee "$ROOTFS_PATH"/etc/profile.d/profile.sh

# Ash profile
(
cat <<EOF
export ENV="$HOME"/.config/ash/ashrc"
EOF
) | tee "$ROOTFS_PATH"/home/kjx/.config/ash/profile
echo "su="doas -s""                             >>      "$ROOTFS_PATH"/home/kjx/.config/ash/ashrc



#}

# Create squashfs destination paths
mkdir -pv "$SQ_ROOTFS"
mkdir -pv "$SQ_SQUASHFS"
mkdir -pv "$SQ_OVERLAY/upperdir/usr/local/bin/"

mkdir -pv "$SQ_OVERLAY/upperdir"
mkdir -pv "$SQ_OVERLAY/workdir"
mkdir -pv "$SQ_OVERLAY/merged"


# This includes kernel modules
BUILDER_ROOTFS_DIR="$HOME"/Downloads/kjxh-artifacts/another/newfrdir

if [ "$(basename "$PWD")" = "kjx-headless" ] && [ -d "$ROOTFS_PATH" ] ; then
    cp -r "$BUILDER_ROOTFS_DIR"/* "$ROOTFS_PATH"
    sudo cp "$BUILDER_ROOTFS_DIR"/lib/libdevmapper.so.1.02 "$ROOTFS_PATH"/lib/
    sudo cp "$BUILDER_ROOTFS_DIR"/usr/lib/libtcl8.6.so "$ROOTFS_PATH"/usr/lib/

    printf "\n\n|> Sucessfully copied the BUILDER_ROOTFS directory to the ISO ROOTFS_PATH, including the libdevmapper and libtcl shared objects. Exiting now...\n\n"
else
    printf "\n==========\n|> Error: not on the root of the repository project (kjx-headless). \n|> Change it before running this block. Exiting now...\n\n"
fi



sudo cp -r "$ROOTFS_PATH"/* "$SQ_ROOTFS"

# ================
# squashfs logic
# ================
mksquashfs "$SQ_ROOTFS" "$SQ_SQUASHFS/busybox.squashfs" -comp xz -b 256K -Xbcj x86

# use fuse-overlayfs to stack files and install additional programs
sudo mount -t squashfs "$SQ_SQUASHFS/busybox.squashfs" "$SQ_OVERLAY/merged"

sudo fuse-overlayfs -o lowerdir=$SQ_OVERLAY/merged,upperdir="${SQ_OVERLAY}/upperdir",workdir="$SQ_OVERLAY/workdir" "$SQ_OVERLAY/merged"
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

#ANODA="/home/asari/Downloads/kjxh-artifacts/another/rootfs_v28.cpio.gz"

#cp $INITRAMFS_BASENAME $ISO_DIR/kernel/

# "initrd=/kernel/rootfs_v28.cpio.gz"
(
cat <<EOF

DEFAULT linux

LABEL linux
    KERNEL  /kernel/bzImage
    APPEND  initrd=/kernel/${INITRAMFS_BASENAME} security=selinux console=ttyS0 root=/dev/sr0 rootfs_path=/images/rootfs.sqfs earlyprintk net.ifnames=0 cgroup_no_v1=all

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
) | tee "$ISO_DIR/syslinux/isolinux.cfg"

(
cat <<EOF
☼09a☼07 - Boot A:
☼09b☼07 - Boot first HDD
☼09c☼07 - Boot next device

☼091☼07 - ☼0fPC-DOS☼07
☼092☼07 - Darik's Boot and Nuke
☼093☼07 - memtest86+
EOF
) | tee "$ISO_DIR/syslinux/boot.txt"

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

# ISO_DIR
# EFI_TMPDIR mktmp

# ====================================
#
# Create EFI.img artifact
#
touch "$ISO_DIR"/boot/grub/efi.img
dd if=/dev/zero of="$ISO_DIR"/boot/grub/efi.img bs=1M count=20
mkfs.vfat "$ISO_DIR"/boot/grub/efi.img

if [ "$EFI_TMPDIR" = "" ]; then
EFI_TMPDIR=$(/bin/busybox mktemp -d)
fi

sudo mount "$ISO_DIR"/boot/grub/efi.img "$EFI_TMPDIR"

sudo mkdir -pv "$EFI_TMPDIR/EFI/boot"
sudo grub-mkstandalone -O x86_64-efi -o "$EFI_TMPDIR/EFI/boot/bootx64.efi" "boot/grub/grub.cfg=/boot/grub/grub.cfg"

sudo umount "$EFI_TMPDIR"


routine=$(uname -m)


SYSLINUX_BOOTBIN="./artifacts/distro/syslinux-6.03/bios/core/isolinux.bin"
ELTORITO_PATH="./eltorito.img"
ISOHDPFX_PATH="./artifacts/distro/syslinux-6.03/bios/mbr/isohdpfx.bin"
ISO_FINAL_PATH="$PWD/artifacts/kjx-headless.iso"
EFI_PATH="$ISO_DIR/boot/grub/efi.img"


# ====================================
#
# FINISH ISOLINUX

(
cat <<EOF
DEFAULT linux

LABEL linux
    KERNEL  /kernel/bzImage
    APPEND  initrd=/kernel/initramfs-ssh.cpio.gz security=selinux console=ttyS0 root=/dev/sr0 rootfs_path=/images/rootfs.sqfs earlyprintk net.ifnames=0 cgroup_no_v1=all

LABEL fallback
    MENU LABEL KJX Linux Fallback
    LINUX /kernel/bzImage-6.6.22-kjx-1.0
    APPEND root=/dev/sa3 rw
    INITRD /kernel/initramfs-ssh.cpio.gz


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
) | sudo tee "$ISO_DIR/syslinux/isolinux.cfg" > /dev/null


#export PAT_KJX_ARTIFACT="${{ secrets.FETCH_ARTIFACT }}"
export PAT_KJX_ARTIFACT="${FETCH_ARTIFACT_RUNTIME}"

if [ -z "${PAT_KJX_ARTIFACT}" ] || ! [ "${PAT_KJX_ARTIFACT}" = "github_pat*" ]; then
    #
    # from ssh-enabled-rootfs to rootfs-with-ssh
    KO_TARBALL_LINK=$( curl -H "Authorization: token $PAT_KJX_ARTIFACT" https://api.github.com/repos/deomorxsy/kjx-headless/actions/artifacts | jq -C -r '.artifacts[] | select(.name == "ko_tarball") | .archive_download_url' | awk 'NR==1 {print $1}')

    # wget --header="Authorization: token $PAT_KJX_ARTIFACT" -P ./artifacts/ "$KO_TARBALL_LINK"

    mkdir -p "$ISO_DIR"/kernel/tmp_modules/
    curl -L -H "Authorization: token $PAT_KJX_ARTIFACT" \
        --output-dir "$ISO_DIR/kernel/tmp_modules/" -O "$KO_TARBALL_LINK"

    cd "$ISO_DIR"/kernel/tmp_modules || return
    unzip ./"$(basename "$KO_TARBALL_LINK")"

    for f in ./*; do
        case $f in
            *.tar.gz) tar -xvf "$f" ;;
        esac
    done

    cd - || return

fi
#cp ./artifacts/ko_tarball.zip "$ISO_DIR"/kernel/
#unzip ./ko_tarball.zip


# Repack initramfs init bootscript
if [ "$(basename "$PWD")" = "kjx-headless" ] && [ -f "$ISO_DIR"/kernel/initramfs-ssh.cpio.gz ]; then

    if [ -d "$ISO_DIR"/kernel/repack_initramfs ]; then
        rm -rf "$ISO_DIR"/kernel/repack_initramfs/
    fi

cd "$ISO_DIR"/kernel/ || return
mkdir -p ./repack_initramfs

# Decompress gunzip and then cpio to the specified path
echo "Trying to decompress the cpio.gz tarball..."
if ! gzip -cd ./initramfs-ssh.cpio.gz | cpio -idmv -D ./repack_initramfs; then
    printf "\n |> Failed to decompress cpio.gz tarball. Exiting now..."
fi
printf "\n|> initramfs decompressed successfully."


# Copy kernel modules tarball into the repack directory
cp -r ./tmp_modules/mnt/lfs/* ./repack_initramfs/

rm -rf ./tmp_modules/*

cd - || return



(
cat <<"INIT_EOF"
#!/bin/busybox sh

# Redo mount filesystems
mount -t devtmpfs   devtmpfs    /dev
mount -t proc       proc        /proc
mount -t sysfs      sysfs       /sys
mount -t tmpfs      tmpfs       /tmp
mount -t tmpfs      tmpfs       /run

mkdir /dev/pts
mount -t devpts devpts /dev/pts

# Redo mount tracefs and securityfs pseudo-filesystems
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



printf "Uptime: $(cut -d' ' -f1 /proc/uptime) \n"
printf "System config: $(uname -a) \n"

# Parse kernel command line for our custom parameters
ISO_DEVICE=$(cat /proc/cmdline | sed -n 's/.*root=\([^ ]*\).*/\1/p')
SQUASHFS_IMAGE_PATH=$(cat /proc/cmdline | sed -n 's/.*rootfs_path=\([^ ]*\).*/\1/p')
FULL_SQUASHFS_PATH="/mnt/iso_live$SQUASHFS_IMAGE_PATH"


# Base directories for overlayfs over the squashfs image
SQ_ROOTFS="/tmp/kjx_rootfs"
SQ_SQUASHFS="/tmp/kjx_squashfs"
SQ_OVERLAY="/tmp/kjx_overlay"

# Create squashfs destination paths
mkdir -p "$SQ_ROOTFS"
mkdir -p "$SQ_SQUASHFS"
mkdir -p "$SQ_OVERLAY/lower"
mkdir -p "$SQ_OVERLAY/upperdir/usr/local/bin/"
mkdir -p "$SQ_OVERLAY/workdir"
mkdir -p "$SQ_OVERLAY/merged"

# Create temporary mount points
mkdir -p /mnt/iso_live
mkdir -p /new_root


# Mount the ISO device
echo "Attempting to mount ISO device ($ISO_DEVICE) to /mnt/iso_live..."
if ! mount -r -t iso9660 "$ISO_DEVICE" /mnt/iso_live; then
    printf "\n|> Failed to mount ISO device %s. Dropping to shell.\n" "$ISO_DEVICE"
    exec /bin/sh && asciiart
fi
echo "ISO device mounted successfully."


# If the path for the squashfs exists,
echo "Attempting to mount SquashFS image from $FULL_SQUASHFS_PATH to /new_root..."
if [ ! -f "$FULL_SQUASHFS_PATH" ]; then
    printf "\n\n|> Error: SquashFS image not found at $FULL_SQUASHFS_PATH. Dropping to shell."
    exec /bin/sh && asciiart
fi

# Mount the squashfs
#
# -r for read-only mount, -t squashfs for filesystem type
if ! mount -r -t squashfs "$FULL_SQUASHFS_PATH" "$SQ_OVERLAY"/lower; then
    printf "\n|> Failed to mount SquashFS image $FULL_SQUASHFS_PATH. Dropping to shell."
    printf "\n|> Check if 'squashfs' kernel module is loaded or compiled into kernel."
    exec /bin/sh && asciiart
fi
echo "SquashFS root filesystem mounted successfully."

# Unmount the ISO since it is not needed anymore
umount /mnt/iso_live 2>/dev/null || true # Ignore if it fails (e.g., if busy)

# Load the overlay kernel module
#
echo "Loading the overlayfs kernel module..."
if ! modprobe overlay && lsmod | grep overlay; then
    printf "|> Error: failed to load the overlayfs kernel module. Dropping to shell. \n"
    printf "|> check if overlayfs kernel module is loaded or compiled into kernel."
    exec /bin/sh && asciiart

fi
echo "overlayfs kernel module was successfully loaded!"

# Mount the overlayfs over squashfs
#
# hint: this mounts an read-write overlayfs upperdir atop of the decompressed read-only lowerdir squashfs
#
echo "Mounting overlayfs..."
if ! mount -t overlay overlay -o lowerdir="$SQ_OVERLAY"/lower,upperdir="$SQ_OVERLAY"/upperdir,workdir="$SQ_OVERLAY"/workdir "$SQ_OVERLAY"/merged; then
    printf "|> Failed to mount overlayfs. Dropping to shell.\n"
    printf "|> Check if 'overlayfs' kernel module is loaded or compiled into kernel."
    exec /bin/sh && asciiart
fi
echo "Overlayfs mounted successfully to $SQ_OVERLAY/merged"



# Setup podman storage outside the overlay
#
echo "Mounting tmpfs at podman's graphroot storage directory..."
mkdir -p "$SQ_OVERLAY/merged/var/lib/containers"
mount -t tmpfs tmpfs "$SQ_OVERLAY/merged/var/lib/containers"

mkdir -p "$SQ_OVERLAY/merged/run"
mount -t tmpfs tmpfs "$SQ_OVERLAY/merged/run"

# unmount base directories, rootfs init bootscript
# will mount them again
umount /proc
umount /sys
umount /dev

printf "\n\n===========\n|> Switching root to the new filesystem...\n===============\n\n"
# The 'switch_root' command expects the new root directory and the path to 'init'
# within that new root.
exec switch_root "$SQ_OVERLAY"/merged /sbin/init


# Should not reach here if switch_root is successful
echo "ERROR: switch_root failed! Dropping to shell."
exec /bin/sh && asciiart


INIT_EOF
) | tee "$ISO_DIR"/kernel/repack_initramfs/init

chmod +x "$ISO_DIR"/kernel/repack_initramfs/init

else
    printf "\n|> ERROR: initramfs-ssh.cpio.gz file not found. Exiting now...\n\n"
fi


# Create revised cpio.gz rootfs tarball
#
if [ "$(basename "$PWD")" = "kjx-headless" ] && [ -d "$ISO_DIR"/kernel/repack_initramfs ]; then
cd "$ISO_DIR"/kernel/repack_initramfs || return
    mv ../initramfs-ssh.cpio.gz ../initramfs-ssh_bak.cpio.gz
    find . -print0 | busybox cpio --null -ov --format=newc | gzip -9 > ../initramfs-ssh.cpio.gz && \
        echo "done!!"

cd - || return
else
    printf "\n|> Error: could not find the repack directory. Exiting now...\n\n"
fi


SOURCE_ROOTFS_DIR="./artifacts/burn/rootfs"
SQUASHFS_IMAGE="./artifacts/rootfs.sqfs"
KERNEL_BASENAME=$(basename "$KERNEL_PATH")
ISO_INITRAMFS="initramfs-ssh.cpio.gz"

# 4. Create squashfs file for the rootfs
if [ "$(basename "$PWD")" = "kjx-headless" ] && [ -d "$SOURCE_ROOTFS_DIR" ] && [ -d "$ISO_DIR" ]; then
    if [ -f $SQUASHFS_IMAGE ]; then

        printf "\n|> Error: found a previous squashfs file. Removing...\n\n"
        rm "$SQUASHFS_IMAGE"

        mksquashfs "$SOURCE_ROOTFS_DIR" "$SQUASHFS_IMAGE" -comp xz -b 256K -Xbcj x86 &&
            printf "\n|> squashfs file created with success! \n\n"


    fi

mkdir -p "$ISO_DIR"/images/
cp $SQUASHFS_IMAGE "$ISO_DIR"/images/

# ======================
# Eltorito
#
# no-emulation setup with xorriso and the ISOLINUX's isohybrid
#
# ${ISO_GRUB_PRELOAD_MODULES} was previously used on grub-mkimage for an alternate
# way of getting the eltorito artifact. Now located at ./assets/grub/Dockerfile
# ISO_GRUB_PRELOAD_MODULES="part_gpt part_msdos ext2 normal linux iso9660 udf all_video video_fb search configfile echo cat"

# Fetch eltorito artifact and place it under the ./burn/boot/grub/i386-pc/eltorito.img path

#ELTORITO_PATH="./eltorito.img"
mkdir -p "$ISO_DIR/boot/grub/i386-pc"
if ! [ -f "${ELTORITO_PATH}" ]; then

    cp "${ELTORITO_PATH}" "${ISO_DIR}"/boot/grub/i386-pc/
else
    printf "\n|> Error: eltorito file was not found. Exiting now...\n"

fi

# 5. Package the final filesystem into an ISO9660 image using xorriso.
# xorriso -as mkisofs -o "$ISO_FINAL_PATH"/kjx-headless_v2.iso \
#
    if ! [ -f "$ISO_FINAL_PATH"/kjx-headless_v3.iso ]; then
    xorriso -as mkisofs -o "$ISO_FINAL_PATH"/kjx-headless_v3.iso \
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
        -r "$ISO_DIR" \
        -m 'rootfs'
    else
        printf "\n|> Error: a file was found with the same name. Exiting now...\n"
    fi


else
    printf "\n\n|> Error: not on the root of the kjx-headless repository. hint: Change dir and try again! \n|> Exiting now...\n\n"
fi



### 6. Copy the iso file outside the namespace
# cp /mnt/output/my_custom.iso "./artifacts/kjx-headless.iso"
printf "\n=============================="
printf "\n\n|> ISO Build complete with success! \n\n"


print_usage() {
cat <<-END >&2
USAGE: fa-gha [-options]
                - isogen
                - version
                - help
eg,
MODE="isogen"       . ./fa-gha   # breaks everything but builds the iso.
MODE="version"      . ./fa-gha   # shows script version
MODE="help"         . ./fa-gha   # shows this help message

See the man page and example file for more info.

END

}


# Check the argument passed from the command line
if [ "$MODE" = "-isogen" ] || [ "$MODE" = "--isogen" ] || [ "$MODE" = "isogen" ]; then
    isogen
elif [ "$1" = "help" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    print_usage
elif [ "$1" = "version" ] || [ "$1" = "-v" ] || [ "$1" = "--version" ]; then
    printf "\n|> Version: 1.0.0"
else
    echo "Invalid function name. Please specify one of the available functions:"
    print_usage
fi


