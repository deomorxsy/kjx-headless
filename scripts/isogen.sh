#!/usr/bin/sh
#
# scaffold project for a
# ISO9660 compressed distro
scaff_burn() {

kernel=./artifacts/bzImage
ramdisk=./artifacts/netpowered.cpio.gz
#ramdisk=./artifacts/initramfs.cpio.gz
#fr_batch=

mkdir -p ./burn/boot ./burn/isolinux
# move kernel and ramdisk
cp $kernel ./burn/boot/vmlinuz
cp $ramdisk ./burn/boot/initrd.img
}

# grub config
grub_config() {
cat <<"EOF" > ./burn/boot/grub/grub.cfg
# begin /boot/grub/grub.cfg
#
set default=0
set timeout=5

insmod ext2
set root=(hd0,2)

menuentry "Busybox/Linux, Linux 6.6.22-lfs-10.0" {
        linux       /boot/vmlinuz-6.6.22-lfs-10.0 root=/dev/sda2 ro
}
EOF
}


# isolinux config
isolinux_config() {
cat <<"EOF" > ./burn/isolinux/isolinux.cfg
DEFAULT linux
LABEL linux
    KERNEL /boot/vmlinuz
    APPEND initrd=/boot/initrd.img
EOF
}

