#!/bin/sh


(
cat <<EOF
config boot linux
        option filename boot/grub/i386-pc/core.0
        option servername boot
        option serveraddress 84.246.161.86
EOF
) | tee "${ISO_DIR}"/etc/config/dhcp

# grub
(
cat <<EOF
menuentry "kjx install" {
    linux /kjx/kernel root=/dev/ram0 init=/linuxrc  dokeymap looptype=squashfs loop=/image.squashfs  cdroot net.ifnames=0
    initrd /kjx/network.igz
EOF
) | tee "${ISO_DIR}"/tftproot/boot/grub/grub.cfg

# syslinux/pxelinux
(
cat <<EOF
EOF
) | tee "${ISO_DIR}"/tftproot/pxelinux.cfg/default

# dhcpd.conf
(
cat <<EOF
option option-150 code 150 = text ;
ddns-update-style none ;
host eta {
hardware ethernet 00:00:00:00:00:00;
fixed-address ip.add.re.ss;
option option-150 "/eta/boot/grub.lst";
filename "/eta/boot/pxegrub";
}

EOF
) | tee "${ISO_DIR}"/diskless/etc/dhcp/dhcpd.conf


#
(
cat <<EOF
config_eth0="noop"
EOF
) | tee "${ISO_DIR}"/diskless/etc/conf.d/net

(
cat <<EOF
config_eth0="noop"
EOF
) | tee "${ISO_DIR}"/diskless/etc/exports

(
cat <<EOF
config_eth0="noop"
EOF
) | tee "${ISO_DIR}"/diskless/etc/hosts
