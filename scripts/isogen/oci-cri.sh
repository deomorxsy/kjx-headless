#!/bin/sh

setacontainers() {
    #enable_containers_isodir() {

    mkdir -pv "$ISO_DIR"/rootfs/etc/containers

    if ! ( (
        cat <<EOF
# Paths to look for a valid OCI runtime (crun, runc, kata, runsc, krun, etc)
[engine.runtimes]
crun = [
  "/usr/bin/crun",
  "/usr/sbin/crun",
  "/usr/local/bin/crun",
  "/usr/local/sbin/crun",
  "/sbin/crun",
  "/bin/crun",
  "/run/current-system/sw/bin/crun",
]

# crun-vm is an OCI Runtime that enables Podman,
# Docker, and Kubernetes to run QEMU-compatible
# Virtual Machine (VM) images.
crun-vm = [
  "/usr/bin/crun-vm",
  "/usr/local/bin/crun-vm",
  "/usr/local/sbin/crun-vm",
  "/sbin/crun-vm",
  "/bin/crun-vm",
  "/run/current-system/sw/bin/crun-vm",
]

kata = [
  "/usr/bin/kata-runtime",
  "/usr/sbin/kata-runtime",
  "/usr/local/bin/kata-runtime",
  "/usr/local/sbin/kata-runtime",
  "/sbin/kata-runtime",
  "/bin/kata-runtime",
  "/usr/bin/kata-qemu",
  "/usr/bin/kata-fc",
]

runc = [
  "/usr/bin/runc",
  "/usr/sbin/runc",
  "/usr/local/bin/runc",
  "/usr/local/sbin/runc",
  "/sbin/runc",
  "/bin/runc",
  "/usr/lib/cri-o-runc/sbin/runc",
]

runsc = [
  "/usr/bin/runsc",
  "/usr/sbin/runsc",
  "/usr/local/bin/runsc",
  "/usr/local/sbin/runsc",
  "/bin/runsc",
  "/sbin/runsc",
  "/run/current-system/sw/bin/runsc",
]

youki = [
  "/usr/local/bin/youki",
  "/usr/bin/youki",
  "/bin/youki",
  "/run/current-system/sw/bin/youki",
]

krun = [
  "/usr/bin/krun",
  "/usr/local/bin/krun",
]

EOF
    ) | tee "$ISO_DIR/rootfs/etc/containers/containers.conf"); then
        echo "|> Error: could not set containers configuration at $ISO_DIR/rootfs/etc/containers/containers.conf"
        echo && echo
        return 1
    fi
    echo "|> Setup containers configuration at $ISO_DIR/rootfs/etc/containers/containers.conf filepath. Exiting now..."
    echo && echo

    # Setup storage info for containers
    # this need user management enabled
    if ! ( (
        cat <<EOF
[storage]
driver = "overlay"

# Default Storage Driver, Must be set for proper operation.
driver = "overlay"

# Temporary storage location
runroot = "/run/containers/storage"
graphroot = "/var/lib/containers/storage"

# Storage path for rootless users
rootless_storage_path = "$HOME/.local/share/containers/storage"

[storage.options]
pull_options = {enable_partial_images = "false", use_hard_links = "false", ostree_repos=""}
additionalimagestores = [
]

[storage.options.overlay]

# Path to an helper program to use for mounting the file system instead of mounting it
# directly.
mount_program = "/usr/bin/fuse-overlayfs"

# mountopt specifies comma separated list of extra mount options
mountopt = "nodev"


EOF
    ) | tee /etc/containers/storage.conf); then
        echo "|> Error: could not pipe a write to the OCI configuration at /etc/containers/storage.conf filepath. Exiting now..."
        echo && echo
        return 1
    fi

}
