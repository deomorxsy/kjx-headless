#!/usr/bin/sh
# (busybox sh)
#
# ISO9660 image phase 9: bootloader config
#
## scaffold project for a ISO9660 compressed distro

iso_dir=./artifacts/burn
# fetch bzImage and initramfs.cpio.gz from previous actions:
kernel_path=./artifacts/bzImage
ramdisk_path=./artifacts/netpowered.cpio.gz
rootfs_path=./artifacts/qcow2-rootfs/rootfs
#ramdisk=./artifacts/initramfs.cpio.gz
#fr_batch=


# =====================
# Function Definitions
# =====================

scaff_burn() {

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
}


# grub config: ext2 supports ext3 and ext4 too
grub_config() {
cat <<"EOF" > ./artifacts/burn/boot/grub/grub.cfg
# begin /boot/grub/grub.cfg
#
set default=0
set timeout=5

insmod part_gpt
insmod ext2
set root=(hd0,2)

menuentry "Busybox/Linux, Linux 6.6.22-lfs-12.1" {
        linux       /boot/vmlinuz-6.6.22-lfs-12.1 root=/dev/sda2 ro
}
EOF
}


# isolinux config to boot from USB flash drive or CD-ROM
isolinux_config() {
cat <<"EOF" > ./artifacts/burn/syslinux/isolinux.cfg
DEFAULT linux

LABEL linux
    KERNEL /boot/vmlinuz
    APPEND initrd=/boot/initrd.img security=selinux

LABEL fallback
    MENU LABEL KJX Linux Fallback
    LINUX ../vmlinuz-6.6.22-lfs-12.1
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
}

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



# ================
#
# Dependency Check
#
# =================


WGET_MAX_RETRIES=5
RETRY_DELAY=10

retry_wget(){
    attempt=1
    success=0

    while attempt <= MAX_RETRIES; do
        if wget -nc --input-file=./artifacts/wget-list-static.txt --continue --directory-prefix=./artifacts/sources ; then
            success=1
            break
        else
            echo "Attempt $attempt failed, retrying in $RETRY_DELAY seconds..."
            sleep "$RETRY_DELAY"
            attempt=$(( attempt+1 ))
        fi
    done

    if [ $success = 0 ]; then
        echo "Failed to download files after $MAX_RETRIES attempts."
        exit 1
    fi

}

# 1. directories in place
# 2. needed packages

sources() {
# isogen sources
mkdir -p ./artifacts/sources
#cd ./artifacts/sources || return

src_contents=$(ls -1 ./artifacts/sources)

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


}

# 1. Scaffolding and check sources

# call scaff_burn config function
scaff_burn

# call sources config function
sources

# ==============================================
#
# 2. prepare final distro's ISO directory structure
#
# ==============================================

# =========
# boot/grub

## call grub config function
grub_config


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
isolinux_config

cp ./artifacts/sources/syslinux-6.03/bios/core/isolinux.bin "$iso_dir/syslinux/isolinux.bin"
cp ./artifacts/sources/syslinux-6.03/bios/com32/elflink/ldlinux/ldlinux.c32 "$iso_dir/syslinux/ldlinux.c32"


# =========
# EFI


# =========
# rootfs
cp -r "$rootfs_path" "$iso_dir/rootfs"

system_info


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
