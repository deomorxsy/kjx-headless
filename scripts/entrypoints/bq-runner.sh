#!/bin/sh
# alpine 3.22

apk upgrade && apk update &&
        apk add libcap parted device-mapper fuse-overlayfs qemu qemu-img qemu-system-x86_64 \
          file multipath-tools e2fsprogs xorriso expect libseccomp &&
        setcap cap_sys_admin,cap_dac_override+eip "$(readlink -f "$(which qemu-img)")" && \
        setcap cap_sys_admin+eip "$(readlink -f "$(which parted)")" && \
        setcap cap_sys_admin,cap_dac_override,cap_dac_read_search+eip "$(readlink -f "$(which kpartx)")" && \
        setcap cap_sys_admin+eip "$(readlink -f "$(which mkfs.ext4)")" && \
        setcap cap_sys_admin,cap_dac_override+ep "$(readlink -f "$(which losetup)")"
