#!/bin/sh

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
