#/bin/sh

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
    UPPER_LOOPDEV="$(losetup | awk 'NR==2 {print $1}')"
    UPPER_BASE_IMG=$(losetup | awk 'NR==2 {print $6}')

    # for bootloaders, isolinux/syslinux or grub
    KERNEL_BASENAME=$(basename "$KERNEL_PATH")
    INITRAMFS_BASENAME=$(basename "$RAMDISK_PATH")
    SYSLINUX_BOOTBIN="./artifacts/distro/syslinux-6.03/bios/core/isolinux.bin"
    # at ./assets/grub/Dockerfile
    ELTORITO_PATH="./eltorito.img"
    ISOHDPFX_PATH="./artifacts/distro/syslinux-6.03/bios/mbr/isohdpfx.bin"
    ISO_FINAL_PATH="$PWD/artifacts"
    EFI_PATH="$ISO_DIR/boot/grub/efi.img"

    SOURCE_ROOTFS_DIR="./artifacts/burn/rootfs"
    SQUASHFS_IMAGE="./artifacts/rootfs.sqfs"
    ISO_INITRAMFS="initramfs-ssh.cpio.gz"

    #
    BUILDER_ROOTFS_DIR="$HOME"/Downloads/kjxh-artifacts/another/newfrdir

    # ==========
    # RULE: at a given time, there will not be
    # two ISO9660 files with the same name.
    # ==========
    ISO_FILENAME_DATE="$(date | awk '{print $1"-"$2"-"$3"-"$4"_"$5}' | tr ":" "-")"
    ISO_FINAL_NAME="${ISO_FINAL_PATH}/kjx-headless_${ISO_FILENAME_DATE}.iso"

}
