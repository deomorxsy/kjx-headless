#!/bin/sh

(
cat <<EOF
DEFAULT linux

LABEL linux
    KERNEL  /kernel/${KERNEL_BASENAME}
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

sudo tee "$ISO_DIR/syslinux/boot.txt" > /dev/null <<"EOF"
☼09a☼07 - Boot A:
☼09b☼07 - Boot first HDD
☼09c☼07 - Boot next device

☼091☼07 - ☼0fPC-DOS☼07
☼092☼07 - Darik's Boot and Nuke
☼093☼07 - memtest86+
EOF

) | tee ./artifacts/burn/syslinux/isolinux.cfg
