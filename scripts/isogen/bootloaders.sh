#!/bin/sh

# prepare final distro's ISO directory structure
mkdir -pv "$ISO_DIR"/boot/grub "$ISO_DIR"/boot/isolinux \
    "$ISO_DIR"/kernel "$ISO_DIR"/syslinux \
    "$ISO_DIR"/EFI/boot "$ISO_DIR"/rootfs

#grub_config() {
## call grub config function

if [ -d "$ISO_DIR"/boot/grub/ ]; then

    sudo tee "$ISO_DIR"/boot/grub/grub.cfg >/dev/null <<"EOF"
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

# SYSLINUX_BOOTBIN="./artifacts/distro/syslinux-6.03/bios/core/isolinux.bin"
# ELTORITO_PATH="./eltorito.img"
# ISOHDPFX_PATH="./artifacts/distro/syslinux-6.03/bios/mbr/isohdpfx.bin"
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
) | sudo tee "$ISO_DIR/syslinux/isolinux.cfg" >/dev/null

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
