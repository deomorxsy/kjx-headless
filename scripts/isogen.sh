#!/usr/bin/sh
#
# scaffold project for a
# ISO9660 compressed distro
scaff_burn() {

kernel=./artifacts/bzImage
ramdisk=./artifacts/netpowered.cpio.gz
#ramdisk=./artifacts/initramfs.cpio.gz
#fr_batch=

mkdir -p ./artifacts/burn/boot/grub ./artifacts/burn/isolinux
# move kernel and ramdisk
cp $kernel ./artifacts/burn/boot/vmlinuz
cp $ramdisk ./artifacts/burn/boot/initrd.img
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
cat <<"EOF" > ./artifacts/burn/isolinux/isolinux.cfg
DEFAULT linux

LABEL linux
    KERNEL /boot/vmlinuz
    APPEND initrd=/boot/initrd.img security=selinux

LABEL fallback
    MENU LABEL KJX Linux Fallback
    LINUX ../vmlinuz-6.6.22-lfs-12.1
    APPEND root=/dev/sa3 rw
    INITRD ../initramfs-linux-fallback.img

EOF

# search workdir: /boot/syslinux directory
xorriso -as mkisofs -o output.iso \
    -b syslinux/isolinux.bin -c syslinux/boot.cat \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    CD_root

}

system_info() {
# Linux Standard Base (LSB)-based system status
cat <<"EOF" > ./artifacts/burn/etc/lsb-release
DISTRIB_ID="LFS: kjx-headless"
DISTRIB_RELEASE="1.0"
DISTRIB_CODENAME="Mantis"
DISTRIB_DESCRIPTION="Linux From Scratch: kjx-headless build for virtual labs"
EOF

# init-system specific system status
cat <<"EOF" > ./artifacts/burn/etc/lsb-release
NAME="kjx-headless"
VERSION="1.0"
ID=kjx
PRETTY_NAME="LFS: kjx-headless 1.0"
VERSION_CODENAME="Mantis"
HOME_URL="github.com/kijinix/kjx-headless"
EOF

}


