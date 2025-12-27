#!/bin/sh

poc_packaging() {

    VIRTIO_PASSTHRU_DIR="/mnt/virtio-test"
    export VIRTIO_PASSTHRU_DIR
    # from ./scripts/isogen/poc-bootscript.sh

    # ======================
    # Packaging or INFRA artifacts
    # ======================
    #
    # from ./scripts/sandbox/run-qemu.sh
    #

    # Microvm artifact variables
    MICROVM_GVISOR_TARBALL="/mnt/virtio-test/gvisor-core.tar.gz"
    MICROVM_FIRECRACKER_TARBALL="/mnt/virtio-test/firecracker-containerd.tar.gz"
    MICROVM_KATA_TARBALL="/mnt/virtio-test/kata-containerd.tar.gz"

    # Tracers artifact variables
    TRACERS_BPFTRACE_TARBALL="/mnt/virtio-test/bpftrace-tarball-pkg.tar.gz"

    # User Management artifacts
    PACKAGING_IPTABLES_TARBALL="/mnt/virtio-test/iptables-tarball-pkg.tar.gz"
    PACKAGING_SHADOW_TARBALL="/mnt/virtio-test/shadow-tarball-pkg.tar.gz"

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
    if ! (cp -r /outro/bpftrace/usr/* /usr/); then
        echo "|> Error: could not copy [/outro/bpftrace/usr/*] into  [/usr/]. Exiting now..."
        return 1
    fi
    echo "|> Sucessfully copied [/outro/bpftrace/usr/*] into [/usr/]. Exiting now..."
    bpftrace -h

    # ;, [27/12/2025 08:47]
    # Packaging and installing iptables
    mkdir -p /outro/iptables
    if ! (tar -xvf "${VIRTIO_PASSTHRU_DIR:-[EMPTY_VARIABLE]}/iptables-tarball-pkg.tar.gz" -C /outro/iptables/); then
        echo "|> Error: could not decompress the [iptables-tarball-pkg.tar.gz]. Exiting now...  "
        return 1
    fi
    echo "|> Sucessfully decompressed the [iptables-tarball-pkg.tar.gz]. Proceeding..."
    ls -l /outro/iptables/
    # if ! (cp -r /outro/iptables/bin/* /bin/); then
    #     echo "|> Error: could not copy [/outro/iptables/bin/*] into  [/bin/]. Exiting now..."
    #     return 1
    # fi
    if ! (cp -r /outro/iptables/etc/* /etc/); then
        echo "|> Error: could not copy [/outro/iptables/etc/*] into  [/etc/]. Exiting now..."
        return 1
    fi
    echo "|> Sucessfully copied [/outro/iptables/etc/*] into  [/etc/]. Proceeding..."
    if ! (cp -r /outro/iptables/usr/* /usr/); then
        echo "|> Error: could not copy [/outro/iptables/usr/*] into  [/usr/]. Exiting now..."
        return 1
    fi
    echo "|> Sucessfully copied [/outro/iptables/usr/*] into  [/usr/]. Proceeding..."
    iptables -h

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
