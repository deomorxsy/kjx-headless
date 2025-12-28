#!/bin/sh

VIRTIO_PASSTHRU_DIR="/mnt/virtio-test"
export VIRTIO_PASSTHRU_DIR

# from ./scripts/isogen/poc-bootscript.sh

# ======================
# Packaging or INFRA artifacts
# ======================
#
# adapted from ./scripts/sandbox/run-qemu.sh
#

ROOTFS_PATH="./artifacts/burn/rootfs"

# Microvm artifact variables
MICROVM_GVISOR_POCPACKA="/mnt/virtio-test/gvisor-core.tar.gz"
MICROVM_FIRECRACKER_POCPACKA="/mnt/virtio-test/firecracker-containerd.tar.gz"
MICROVM_KATA_POCPACKA="/mnt/virtio-test/kata-containerd.tar.gz"
export MICROVM_GVISOR_POCPACKA
export MICROVM_FIRECRACKER_POCPACKA
export MICROVM_KATA_POCPACKA

# Tracers artifact variables
TRACERS_BPFTRACE_POCPACKA="/mnt/virtio-test/bpftrace-tarball-pkg.tar.gz"
export TRACERS_BPFTRACE_POCPACKA

# User Management artifacts
PACKAGING_IPTABLES_POCPACKA="/mnt/virtio-test/iptables-tarball-pkg.tar.gz"
PACKAGING_SHADOW_POCPACKA="/mnt/virtio-test/shadow-tarball-pkg.tar.gz"
PACKAGING_QEMUKJX_POCPACKA="/mnt/virtio-test/qemukjx-tarball-pkg.tar.gz"
export PACKAGING_IPTABLES_POCPACKA
export PACKAGING_SHADOW_POCPACKA
export PACKAGING_QEMUKJX_POCPACKA

poc_pack_gvisor() {
    mkdir -p /outro/gvisor
    if ! (tar -xvf "${VIRTIO_PASSTHRU_DIR:-[EMPTY_VARIABLE]}/gvisor-tarball-pkg.tar.gz" -C /outro/gvisor/); then
        echo "|> Error: could not decompress the [gvisor-tarball-pkg.tar.gz]. Exiting now...  "
        return 1
    fi
    echo "|> Sucessfully decompressed the [gvisor-tarball-pkg.tar.gz]. Proceeding..."
    ls -l /outro/gvisor/
    # if ! (cp -r /outro/gvisor/bin/* ${ROOTFS_PATH:-[EMPTY_VARIABLE]}/bin/); then
    #     echo "|> Error: could not copy [/outro/gvisor/bin/*] into  [/bin/]. Exiting now..."
    #     return 1
    # fi
    if ! (cp -r /outro/gvisor/etc/* ${ROOTFS_PATH:-[EMPTY_VARIABLE]}/etc/); then
        echo "|> Error: could not copy [/outro/gvisor/etc/*] into  [/etc/]. Exiting now..."
        return 1
    fi
    echo "|> Sucessfully copied [/outro/gvisor/etc/*] into  [/etc/]. Proceeding..."
    if ! (cp -r /outro/gvisor/usr/* ${ROOTFS_PATH:-[EMPTY_VARIABLE]}/usr/); then
        echo "|> Error: could not copy [/outro/gvisor/usr/*] into  [/usr/]. Exiting now..."
        return 1
    fi
    echo "|> Sucessfully copied [/outro/gvisor/usr/*] into  [/usr/]. Proceeding..."
}

poc_pack_firecracker() {
    mkdir -p /outro/firecracker
    if ! (tar -xvf "${VIRTIO_PASSTHRU_DIR:-[EMPTY_VARIABLE]}/firecracker-tarball-pkg.tar.gz" -C /outro/firecracker/); then
        echo "|> Error: could not decompress the [firecracker-tarball-pkg.tar.gz]. Exiting now...  "
        return 1
    fi
    echo "|> Sucessfully decompressed the [firecracker-tarball-pkg.tar.gz]. Proceeding..."
    ls -l /outro/firecracker/
    # if ! (cp -r /outro/firecracker/bin/* ${ROOTFS_PATH:-[EMPTY_VARIABLE]}/bin/); then
    #     echo "|> Error: could not copy [/outro/firecracker/bin/*] into  [/bin/]. Exiting now..."
    #     return 1
    # fi
    if ! (cp -r /outro/firecracker/home/firecontainerd/fireart/bin/* ${ROOTFS_PATH:-[EMPTY_VARIABLE]}/bin/); then
        echo "|> Error: could not copy [/outro/firecracker/etc/*] into  [/etc/]. Exiting now..."
        return 1
    fi
    echo "|> Sucessfully copied [/outro/firecracker/home/firecontainerd/fireart/bin/*] into  [/bin/]. Proceeding..."
    if ! (cp -r /outro/firecracker/home/firecontainerd/fireart/containerd-shim-aws-firecracker ${ROOTFS_PATH:-[EMPTY_VARIABLE]}/usr/bin/); then
        echo "|> Error: could not copy [/outro/firecracker/home/firecontainerd/fireart/containerd-shim-aws-firecracker] into  [/usr/bin/]. Exiting now..."
        return 1
    fi
    echo "|> Sucessfully copied [containerd-shim-aws-firecracker] into  [/usr/bin/]. Proceeding..."

    if ! (cp -r /outro/firecracker/home/firecontainerd/fireart/firecracker-containerd ${ROOTFS_PATH:-[EMPTY_VARIABLE]}/usr/bin/); then
        echo "|> Error: could not copy [containerd-shim-aws-firecracker] into  [/usr/bin/]. Exiting now..."
        return 1
    fi
    echo "|> Sucessfully copied [containerd-shim-aws-firecracker] into  [/usr/bin/]. Proceeding..."

    if ! (cp -r /outro/firecracker/home/firecontainerd/fireart/firecracker-ctr ${ROOTFS_PATH:-[EMPTY_VARIABLE]}/usr/bin/); then
        echo "|> Error: could not copy [containerd-shim-aws-firecracker] into  [/usr/bin/]. Exiting now..."
        return 1
    fi
    echo "|> Sucessfully copied [containerd-shim-aws-firecracker] into  [/usr/bin/]. Proceeding..."

}
poc_pack_kata() {
    mkdir -p /outro/kata
    if ! (tar -xvf "${VIRTIO_PASSTHRU_DIR:-[EMPTY_VARIABLE]}/kata-tarball-pkg.tar.gz" -C /outro/kata/); then
        echo "|> Error: could not decompress the [kata-tarball-pkg.tar.gz]. Exiting now...  "
        return 1
    fi
    echo "|> Sucessfully decompressed the [kata-tarball-pkg.tar.gz]. Proceeding..."
    ls -l /outro/kata/
    # if ! (cp -r /outro/kata/bin/* ${ROOTFS_PATH:-[EMPTY_VARIABLE]}/bin/); then
    #     echo "|> Error: could not copy [/outro/kata/bin/*] into  [/bin/]. Exiting now..."
    #     return 1
    # fi
    if ! (cp -r /outro/kata/etc/* ${ROOTFS_PATH:-[EMPTY_VARIABLE]}/etc/); then
        echo "|> Error: could not copy [/outro/kata/etc/*] into  [/etc/]. Exiting now..."
        return 1
    fi
    echo "|> Sucessfully copied [/outro/kata/etc/*] into  [/etc/]. Proceeding..."
    if ! (cp -r /outro/kata/usr/* ${ROOTFS_PATH:-[EMPTY_VARIABLE]}/usr/); then
        echo "|> Error: could not copy [/outro/kata/usr/*] into  [/usr/]. Exiting now..."
        return 1
    fi
    echo "|> Sucessfully copied [/outro/kata/usr/*] into  [/usr/]. Proceeding..."
}

poc_pack_bpftrace() {
    #    ;, [27/12/2025 08:41]
    # Packaging and installing bpftrace
    mkdir -p /outro/bpftrace
    if ! (tar -xvf "${VIRTIO_PASSTHRU_DIR:-[EMPTY_VARIABLE]}/bpftrace-tarball-pkg.tar.gz" -C /outro/bpftrace/); then
        echo "|> Error: could not decompress the [bpftrace-tarball-pkg.tar.gz]. Exiting now..."
        return 1
    fi
    echo "|> Sucessfully decompressed the [bpftrace-tarball-pkg.tar.gz]. Proceeding..."
    echo
    ls -l /outro/bpftrace/
    if ! (cp -r /outro/bpftrace/usr/* ${ROOTFS_PATH:-[EMPTY_VARIABLE]}/usr/); then
        echo "|> Error: could not copy [/outro/bpftrace/usr/*] into  [/usr/]. Exiting now..."
        return 1
    fi
    echo "|> Sucessfully copied [/outro/bpftrace/usr/*] into [/usr/]. Exiting now..."
    bpftrace -h

}

poc_pack_iptables() {
    # ;, [27/12/2025 08:47]
    # Packaging and installing iptables
    mkdir -p /outro/iptables
    if ! (tar -xvf "${VIRTIO_PASSTHRU_DIR:-[EMPTY_VARIABLE]}/iptables-tarball-pkg.tar.gz" -C /outro/iptables/); then
        echo "|> Error: could not decompress the [iptables-tarball-pkg.tar.gz]. Exiting now...  "
        return 1
    fi
    echo "|> Sucessfully decompressed the [iptables-tarball-pkg.tar.gz]. Proceeding..."
    ls -l /outro/iptables/
    # if ! (cp -r /outro/iptables/bin/* ${ROOTFS_PATH:-[EMPTY_VARIABLE]}/bin/); then
    #     echo "|> Error: could not copy [/outro/iptables/bin/*] into  [/bin/]. Exiting now..."
    #     return 1
    # fi
    if ! (cp -r /outro/iptables/etc/* ${ROOTFS_PATH:-[EMPTY_VARIABLE]}/etc/); then
        echo "|> Error: could not copy [/outro/iptables/etc/*] into  [/etc/]. Exiting now..."
        return 1
    fi
    echo "|> Sucessfully copied [/outro/iptables/etc/*] into  [/etc/]. Proceeding..."
    if ! (cp -r /outro/iptables/usr/* ${ROOTFS_PATH:-[EMPTY_VARIABLE]}/usr/); then
        echo "|> Error: could not copy [/outro/iptables/usr/*] into  [/usr/]. Exiting now..."
        return 1
    fi
    echo "|> Sucessfully copied [/outro/iptables/usr/*] into  [/usr/]. Proceeding..."
    iptables -h

}

poc_pack_qemukjx() {

    mkdir -p /outro/qemukjx
    if ! (tar -xvf "${VIRTIO_PASSTHRU_DIR:-[EMPTY_VARIABLE]}/qemukjx-tarball-pkg.tar.gz" -C /outro/qemukjx/); then
        echo "|> Error: could not decompress the [iptables-tarball-pkg.tar.gz]. Exiting now...  "
        return 1
    fi
    echo "|> Sucessfully decompressed the [qemukjx-tarball-pkg.tar.gz]. Proceeding..."
    ls -l /outro/qemukjx/
    # if ! (cp -r /outro/iptables/bin/* ${ROOTFS_PATH:-[EMPTY_VARIABLE]}/bin/); then
    #     echo "|> Error: could not copy [/outro/iptables/bin/*] into  [/bin/]. Exiting now..."
    #     return 1
    # fi
    if ! (cp -r /outro/qemukjx/etc/* ${ROOTFS_PATH:-[EMPTY_VARIABLE]}/etc/); then
        echo "|> Error: could not copy [/outro/iptables/etc/*] into  [/etc/]. Exiting now..."
        return 1
    fi
    echo "|> Sucessfully copied [/outro/qemukjx/etc/*] into  [/etc/]. Proceeding..."
    if ! (cp -r /outro/qemukjx/usr/* ${ROOTFS_PATH:-[EMPTY_VARIABLE]}/usr/); then
        echo "|> Error: could not copy [/outro/qemukjx/usr/*] into  [/usr/]. Exiting now..."
        return 1
    fi
    echo "|> Sucessfully copied [/outro/qemukjx/usr/*] into  [/usr/]. Proceeding..."

    if ! (cp -r /outro/qemukjx/bin/udevadm ${ROOTFS_PATH:-[EMPTY_VARIABLE]}/bin/); then
        echo "|> Error: could not copy [/outro/qemukjx/bin/udevadm] into  [/bin/]. Exiting now..."
        return 1
    fi
    echo "|> Sucessfully copied [/outro/qemukjx/bin/udevadm] into  [/bin/udevadm]. Proceeding..."

    if ! (cp -r /outro/qemukjx/sbin/* ${ROOTFS_PATH:-[EMPTY_VARIABLE]}/sbin/); then
        echo "|> Error: could not copy [/outro/qemukjx/sbin/*] into  [/sbin/]. Exiting now..."
        return 1
    fi
    echo "|> Sucessfully copied [/outro/qemukjx/sbin/*] into  [/sbin/]. Proceeding..."

}

poc_packaging() {

    if ! poc_pack_bpftrace; then
        echo "|> Error: could not run [poc_pack_bpftrace]. Exiting now..."
        return 1
    fi
    echo "|> Sucessfully ran [poc_pack_bpftrace]. Proceeding..."

    if ! poc_pack_iptables; then
        echo "|> Error: could not run [poc_pack_iptables]. Exiting now..."
        return 1
    fi
    echo "|> Sucessfully ran [poc_pack_iptables]. Proceeding..."

    if ! poc_pack_qemukjx; then
        echo "|> Error: could not run [poc_pack_qemukjx]. Exiting now..."
        return 1
    fi
    echo "|> Sucessfully ran [poc_pack_qemukjx]. Proceeding..."

}

# =======================
#  user, groups and shadow password management
packaja_dotfiles() {
    # Configure passwd management
    (
        cat <<EOF
root:x:0:0:root:/root:/bin/ash
kjx:x:1000:1000:kjx:/home/kjx:/bin/ash
EOF
    ) | tee "${ROOTFS_PATH:-[EMPTY_STR]}"/etc/passwd

    # Configure groups management
    (
        cat <<EOF
root:x:0:
bin:x:1:
EOF
    ) | tee "${ROOTFS_PATH:-[EMPTY_STR]}"/etc/group

    # Setup doas superuser management
    #
    echo "permit persist :wheel" >>"${ROOTFS_PATH:-[EMPTY_STR]}"/etc/doas.d/20-wheel.conf

    # Setup ash shell dotfiles

    # Openrc-based profile.d
    (
        cat <<EOF
if [ -f "${HOME:-[EMPTY_STR]}/.config/ash/profile" ]; then
	. "${HOME:-[EMPTY_STR]}/.config/ash/profile"
fi
EOF
    ) | tee "${ROOTFS_PATH:-[EMPTY_STR]}"/etc/profile.d/profile.sh

    # Ash profile
    (
        cat <<EOF
export ENV="${HOME:-[EMPTY_STR]}"/.config/ash/ashrc"
EOF
    ) | tee "${ROOTFS_PATH:-[EMPTY_STR]}"/home/kjx/.config/ash/profile
    echo "su="doas -s"" >>"${ROOTFS_PATH:-[EMPTY_STR]}"/home/kjx/.config/ash/ashrc

}

packaja() {

    packaja_dotfiles

    # Setup usgp-man with shadow and iptables networking
    if ! (INSTALL_PKG="set_network set_shadow" . ./scripts/packages/usgp-man.sh); then
        echo "|> Error: could not "
        return 1
    fi

}
