#!/bin/sh

QCOW_PATH="./artifacts/foo.qcow2"
IMAGE_PATH="./artifacts/foo.img"

# 100M
qemu-img create -f raw "$IMAGE_PATH" 3G

#grep | awk | printf
partit=$(parted -s "$IMAGE_PATH" print 2>&1 | grep "Partition" | awk 'NR==1 {print $3}')


if [ "$partit" = "unknown" ]; then

# 2.a define partition properties such as filesystem type.
parted -s "$IMAGE_PATH" \
    mklabel msdos \
    mkpart primary ext4 2048s 100%

partit=$(parted -s "$IMAGE_PATH" print 2>&1 | grep "Partition" | awk 'NR==1 {print $3}')

else
    printf "[EXIT]: It seems there is already a partition in this file.\n"

fi

#6. convert raw sparse file to qcow2
qemu-img convert -p \
    -f raw \
    -O qcow2 \
    "$IMAGE_PATH" "$QCOW_PATH"

#7. call to *.img destructor
rm "$IMAGE_PATH"

# print qcow file type
file "$QCOW_PATH"

# list partition mappings as a block device
kpartx -a "$QCOW_PATH"

# c. check if user_allow_other is enabled on /etc/fuse.conf for rootless passing
IS_FUSE_ALLOWED=$(grep -n '#user_allow_other' /etc/fuse.conf | tail -1)

if [ -n "$IS_FUSE_ALLOWED" ]; then

# d. run qsd on background; SIGKILL when finished
qemu-storage-daemon \
    --blockdev node-name=prot-node,driver=file,filename="$QCOW_PATH" \
    --blockdev node-name=fmt-node,driver=qcow2,file=prot-node \
    --export type=fuse,id=exp0,node=name=fmt-node,mountpoint="$QCOW_PATH",writable=on \
    &

# e. get pid of qsd
#qsd_pid=!$

mount | grep foo.qcow2

# f. add partition mappings, verbose
sudo kpartx -av "$QCOW_PATH"

# g. get info from mounted qcow2 device mapping
qemu-img info "$QCOW_PATH"
#foo.qcow2

else
    echo: "Could not start qemu-storage-daemon process since user_allow_other is not enabled at /etc/fuse.conf."
fi


 # 5. mount the loop device
# -f: find and -P: scan the partition table on newly created loop device
losetup -fP "$QCOW_PATH"

losetup -a # list status of all loop devices

# mount loopback device into the mountpoint to setup rootfs
upper_loopdev=$(losetup -a | awk -F: 'NR==1 {print $1}')
upper_base_img=$(losetup -a | awk -F: 'NR==1 {print $3}')
upper_mountpoint=./artifacts/qcow2-rootfs

check_loopdevfs=$(blkid ./artifacts/foo.qcow2 | awk 'NR==1 {print $4}' | grep ext4)
if [ -z "$check_loopdevfs" ]; then
    # actually create the filesystem for the already created partition
    mkfs.ext4 "$upper_loopdev" #/dev/loop0p1
else
    echo "Error: The provided qcow2 image $check_loopdevfs is already formatted with a filesystem mounted as Loop Device at $upper_base_img."
fi

# 6. mount the loop device into the rootfs
printf "=============|> [STEP 6]: mount the loop device into the rootfs.\n============="

mkdir -p "$upper_mountpoint"/rootfs # mkdir a directory for the rootfs
mount "$upper_loopdev" "$upper_mountpoint"/rootfs # mount loop device into the generic dir

# =============
# populate rootfs directory using the
# busybox directory tree from the initramfs
# =============

initramfs_base="./artifacts/netpowered.cpio.gz"

# squashfs logic

cp "$initramfs_base" "$upper_mountpoint"
#cd "$upper_mountpoint" || return

#sudo gzip -dc netpowered.cpio.gz | (cd ./rootfs/ || return && sudo cpio -idmv && cd - || return)
gzip -dc netpowered.cpio.gz | (cd ./rootfs/ || return && cpio -idmv && cd - || return)

# LFS packaging: fakeroot+diff hint strategy
#mkdir -p "$upper_mountpoint"/rootfs
cp -r "$upper_mountpoint"/netpowered/* "$upper_mountpoint"/rootfs
cp -r ./artifacts/deps "$upper_mountpoint"

diff --brief --recursive "$upper_mountpoint" "$upper_mountpoint"/rootfs

#cp -a rootfs/* /mnt/qcow2/ # copy files, etc
#
# populate the rootfs; generate iso
#
# 7. packaging: call ./scripts/rootfs.sh
#. ./scripts/rootfs.sh

## 7.1 squashfs + overlayfs inside a mount namespace.


### 7.1.1 sets up the LFS variable
#lfsvar_setup() {
KJX="/mnt/kjx"

cat >> "$HOME/.bashrc" << EOF

# sets up the LFS variable
#
export KJX=/mnt/kjx

EOF
#}
#lsvar_setup



# mount namespaces
mountns_sasquatch() {

unshare --mount --uts --ipc --net --fork --pid --mount-proc /bin/bash <<EOF
# populating /dev for the kjx mount (before chroot)
mount -t devtmpfs devtmpfs "$KJX/dev/" #
mount -t tmpfs tmpfs "$KJX/tmp/"

# mounting virtual kernel filesystems (before chroot)
mount -vt devpts devpts -o gid=5,mode=0620 $LFS/dev/pts
mount -vt proc proc $KJX/proc
mount -vt sysfs sysfs $KJX/sys
mount -vt tmpfs tmpfs $KJX/run

# chapter 5 - fake the cross-compiler toolchain
mkdir -p "$KJX/tools"

# squashfs
mkdir -p /tmp/kjx_rootfs
mkdir -p /tmp/kjx_squashfs
mkdir -p /tmp/kjx_overlay/upperdir
mkdir -p /tmp/kjx_overlay/workdir
mkdir -p /tmp/kjx_overlay/merged

gzip -dc ./artifacts/netpowered.cpio.gz | (cd ./artifacts/rootfs/ || return && cpio -idmv && cd - || return)
cp -r ./artifacts/rootfs/* /tmp/kjx_rootfs/


# ================
# squashfs logic
# ================
mksquashfs /tmp/kjx_rootfs /tmp/kjx_squashfs/busybox.squashfs -comp xz -b 256K -Xbcj x86

### 4. use fuse-overlayfs to stack files and install additional programs
mount -t squashfs /tmp/squashfs/busybox.squashfs /tmp/kjx_overlay/merged

fuse-overlayfs -o lowerdir=/tmp/kjx_overlay/merged,upperdir=/tmp/kjx_overlay/upperdir,workdir=/tmp/kjx_overlay/workdir /tmp/kjx_overlay/merged

# a. download the binaries
fetch_binaries() {
wget --input-file=./artifacts/wget-list-sysv.txt --continue --directory-prefix="$KJX/sources"
tar -xvf "$KJX/sources/prebuilt-program.tar.gz"

gpg --verify "$KJX/sources/prebuilt-program/pp.sig $KJX/sources/prebuilt-program.tar.gz"
cp -r "$KJX/sources/prebuilt-program/*" "/tmp/kjx_overlay/upperdir/usr/local/bin/"
}
fetch_binaries

# ====================
# b. compilation step
# ====================
pre_compile() {
}


cp /tmp/overlay/merged ./artifacts/qcow2-rootfs/rootfs/

### 5. package the final filesystem into an ISO9660 image using xorriso.

# xorriso -as mkisofs -o /mnt/output/my_custom.iso /mnt/overlay/merged

### 6. Copy the iso file outside the namespace

cp /mnt/output/my_custom.iso "./artifacts/kjx-headless.iso"

# exits the mount namespace
exit

EOF
}

initramfs_base="./artifacts/netpowered.cpio.gz"
#mountns_sasquatch "$initramfs_base" "$upper_mountpoint"
mountns_sasquatch

# echo $KJX
#
#cat > $KJX/etc/group << EOF
#root:x:0:
#bin:x:1:
#
#EOF

# version check

#bail()

# chapter 2.7 Compile software dependencies setup: create user and group, check, build, move, link

fetch_compile() {
mkdir -pv "$KJX"
mount -v -t ext4 /dev/kjxpart "$KJX"

mkdir -pv "$KJX/home"
mount -v -t ext4 /dev/

# chapter 3.1

mkdir -pv "$KJX/sources"

# make it sticky
chmod -v a+wt "$KJX/sources"

wget --input-file=./artifacts/wget-list-sysv.txt --continue --directory-prefix="$KJX/sources"

# check md5sums
pushd "$KJX/sources"
  md5sum -c md5sums
popd

chown root:root "$KJX/sources/*"

## 3.2: all packages
## 3.3: patches

# chapter 4.

mkdir -pv "$KJX/{etc,var}" "$KJX/usr/{bin,lib,sbin}"

for i in bin lib sbin; do
    ln -sv usr/$i $KJX/$i
done

case $(uname -m) in
    x86_64) mkdir -pv "$KJX/lib64" ;;
esac

mkdir -pv "$KJX/tools"

## 4.3 setup user environment, busybox-based
# groupadd
# useradd
sudo addgroup kjx
sudo adduser -s /bin/bash -g kjx -m -k /dev/null kjx

#sudo passwd kjx
cat <<EOF >~/.setuser.sh
#!/usr/bin/expect

log_user 0
spawn /bin/passwd kjx
expect "Password: "
send "${KJX_USER_PASSWD}"
EOF
sudo ./setuser.sh

# ==== user kjx =====
cat > ~/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF

cat > ~/.bashrc << "EOF"
set +h
umask 022
LFS=/mnt/kjx
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/usr/bin
if [ ! -L /bin ]; then PATH=/bin:$PATH; fi
PATH=$LFS/tools/bin:$PATH
CONFIG_SITE=$LFS/usr/share/config.site
export LFS LC_ALL LFS_TGT PATH CONFIG_SITE
EOF

if [ "$(whoami)" = 'kjx' ]; then
    exit
fi
# ===== exiting user kjx.... =====

# grant kjx access to all directories and files under $KJX
#chown -v kjx $KJX/{usr{,/*},lib,var,etc,bin,sbin,tools}
chown -v kjx "$KJX/usr/"
chown -v kjx "$KJX/usr/*"
chown -v kjx "$KJX/lib/"
chown -v kjx "$KJX/var/"
chown -v kjx "$KJX/etc/"
chown -v kjx "$KJX/bin/"
chown -v kjx "$KJX/sbin/"
chown -v kjx "$KJX/tools/"

case $(uname -m) in
    x86_64) chown -v kjx "$KJX/lib64";
esac

}
#fetch_compile

# =============================
# runit/runsv/runsvdir stup
mkdir -p "$rootfs_path/etc/runit"
mkdir -p "$rootfs_path/etc/runit/runsvdir/default"
mkdir -p "$rootfs_path/service"

# runit: symbolic link convention
ln -s "$rootfs_path/etc/runit/runsvdir/default/" "$rootfs_path/service/"

# runit: service scripts, get a shell
mkdir -p "$rootfs_path/etc/runit/runsvdir/default/getty-tty1"

cat <<EOF > "$rootfs_path/etc/runit/runsvdir/default/getty-tty1/run"
#!/bin/sh
#
exec /sbin/getty 38400 tty1
EOF
chmod +x "$rootfs_path/etc/runit/runsvdir/default/getty-tty1/run"

# ============================

RUN cat > ./rootfs/etc/runit/1 <<"INIT_EOF"
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

chmod +x "$rootfs_path/etc/runit/1"

ln -sf "$rootfs_path/etc/runit/1" "$rootfs_path/sbin/init"

# setup sandbox (1 for each image)
. ./scripts/sandbox/firecracker-startup.sh
. ./scripts/sandbox/gvisor-startup.sh
. ./scripts/sandbox/kata-startup.sh
. ./scripts/sandbox/qemu-startup.sh
. ./scripts/sandbox/youki-startup.sh

## ebpf program placement ///
#. ./scripts/libbpf.sh

#
#KJX=/mnt/kjx
#KJX_UUID=$()
#KJX_UUID=/dev/sda1/
#QCOW_FILE="./utils/storage/kjxh.qcow2"
#
umount /mnt/qcow2 # umount the loop device passing the path
losetup -d /dev/loop0 # detach loop device


# ISO9660 image phase 9: bootloader config
#
## scaffold project for a ISO9660 compressed distro

iso_dir=./artifacts/burn
# fetch bzImage and initramfs.cpio.gz from previous actions:
kernel_path=./artifacts/bzImage
ramdisk_path=./artifacts/netpowered.cpio.gz
rootfs_path=./artifacts/qcow2-rootfs/rootfs

# 1. Scaffolding and check sources: call scaff_burn config function
#scaff_burn

# create sources
mkdir -p ./artifacts/sources

# prepare final distro's ISO directory structure
mkdir -p "$iso_dir"/boot/grub "$iso_dir"/boot/isolinux \
    "$iso_dir"/kernel "$iso_dir"/syslinux \
    "$iso_dir"/EFI/boot "$iso_dir"/rootfs

# syslinux or isolinux
#mkdir -p ./artifacts/burn/boot/grub ./artifacts/burn/syslinux

# move kernel and ramdisk
cp $kernel_path ./artifacts/burn/boot/vmlinuz
cp $ramdisk_path ./artifacts/burn/boot/initrd.img
cp -r $rootfs_path ./artifacts/burn/rootfs/

# call sources config function
#sources

# isogen sources
mkdir -p ./artifacts/sources
#cd ./artifacts/sources || return

src_contents=$(ls -1 ./artifacts/sources)

fuse-overlayfs -o "lowerdir=$SASQUATCH/overlay/merged,upperdir=$SASQUATCH/overlay/upperdir,workdir=$SASQUATCH/overlay/workdir $SASQUATCH/overlay/merged"

#
# iterate over contents of the directory
for slice in $src_contents; do
    # if there is grub, syslinux or efi sources present,
    case $slice in
        *grub*|*syslinux*|*efi*)
            printf "\n===========\n|> One or more sources missing. Wgetting...\n"
            cd ./artifacts/source || return
            # remove failed checksums and download it again
            failed_sums=$(sha256sum -c ./sha256sums_isogen.asc | grep "FAILED" | awk '{print $1}' | cut -d : -f 1)
            for index in $failed_sums; do
                rm ./"$index"

                retry_wget
                #wget -nc \
                #    --input-file=./artifacts/wget-list-static.txt \
                #    --continue --directory-prefix=./artifacts/sources \
                #    -retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 -t 0

                # if specific slice exists, decompress it
                if [ -f "$slice" ]; then
                    tar -xvf "$slice"
                else
                    echo "$slice file don't exist after download"
                fi
            done
            #rm ./sha256sums.asc
            cd - || { echo "Failed to change directory back"; exit 1; }
            ;;
    esac
done

# ==============================================
# 2. prepare final distro's ISO directory structure
# ==============================================

# =========
# boot/grub

## call grub config function
#grub_config

# grub config: ext2 supports ext3 and ext4 too
#grub_config() {
cat <<"EOF" > ./artifacts/burn/boot/grub/grub.cfg
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
#}

# =========
# boot/isolinux

#isolinux_config

# =========
# kernel

cp "$kernel_path" "$iso_dir/kernel"
cp "$ramdisk_path" "$iso_dir/kernel"

# =========
# syslinux

## call isolinux config function
#isolinux_config


# isolinux config to boot from USB flash drive or CD-ROM
#isolinux_config() {
cat <<"EOF" > ./artifacts/burn/syslinux/isolinux.cfg
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

cat <<"EOF" > ./artifacts/burn/syslinux/boot.txt
☼09a☼07 - Boot A:
☼09b☼07 - Boot first HDD
☼09c☼07 - Boot next device

☼091☼07 - ☼0fPC-DOS☼07
☼092☼07 - Darik's Boot and Nuke
☼093☼07 - memtest86+
EOF
#}

cp ./artifacts/sources/syslinux-6.03/bios/core/isolinux.bin "$iso_dir/syslinux/isolinux.bin"
cp ./artifacts/sources/syslinux-6.03/bios/com32/elflink/ldlinux/ldlinux.c32 "$iso_dir/syslinux/ldlinux.c32"


# =========
# EFI


# =========
# rootfs
cp -r "$rootfs_path" "$iso_dir/rootfs"

system_info() {
# Linux Standard Base (LSB)-based system status
cat <<"EOF" > ./artifacts/burn/rootfs/etc/lsb-release
DISTRIB_ID="LFS: kjx-headless"
DISTRIB_RELEASE="1.0"
DISTRIB_CODENAME="Mantis"
DISTRIB_DESCRIPTION="Linux From Scratch: kjx-headless build for virtual labs"
EOF

# init-system specific system status
cat <<"EOF" > ./artifacts/burn/rootfs/etc/lsb-release
NAME="kjx-headless"
VERSION="1.0"
ID=kjx
PRETTY_NAME="LFS: kjx-headless 1.0"
VERSION_CODENAME="Mantis"
HOME_URL="github.com/kijinix/kjx-headless"
EOF

}


# =====================
#
#   3. Build step
#
# =====================
mbr_bin_path=./artifacts/sources/syslinux-6.03/bios/mbr/isohdpfx.bin

# search workdir: /boot/syslinux directory
xorriso -as mkisofs -o output.iso \
    -isohybrid-mbr "$mbr_bin_path" \
    -b ./artifacts/burn/syslinux/isolinux.bin \
    -c boot/boot.cat -b boot/grub/i386-pc/eltorito.img \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -eltorito-alt-boot -e boot/grub/efi.img \
    -no-emul-boot -isohybrid-gpt-basdat \
    -V "My Linux" burn/



# ======================
# chore: functions to
# create patches or checksums
# =====================

SHA() {

    sha256sum ./artifacts/sources > ./artifacts/sources/sha256sums_isogen.asc
}


#mount
#losetup
#blkid
#mkfs.ext4
#mkdir
#gzip
#cpio
#diff
#umount

#addgroup
#adduser
#wget
#ln
#cat
#chmod
#sleep
#sha256sum
#cut
#tar
#xorriso

