#!/bin/sh
#
#.
#├── artifacts
#│   ├── qcow2-rootfs
#│   │   └── rootfs  <------------------------+-----+
#│   ├── sources                              |     |
#│   │   ├── firecracker                      |     |
#│   │   ├── grub-2.12.tar.gz                 |     |
#│   │   ├── k3s                              |     |
#│   │   ├── kata-static-3.7.0-amd64.tar.xz   |     |
#│   │   ├── libcap-1.2.70.tar.gz             |     |
#│   │   ├── qemu-9.0.2.tar.xz                |     |
#│   │   ├── release-20240807.0.tar.gz        |     |
#│   │   ├── sha256sums_isogen.txt            |     |
#│   │   └── syslinux-6.03.tar.gz             |     |
#├── gvaizado                                 |     |
#│   ├── containerd-shim-runsc-v1 ------------+     |
#│   ├── containerd-shim-runsc-v1.sha512            |
#│   ├── runsc -------------------------------------+
#│   └── runsc.sha512
#

UPPER_MOUNTPOINT="./artifacts/qcow2-rootfs"
KJX="/mnt/kjx"
ROOTFS_PATH="$UPPER_MOUNTPOINT/rootfs"

# manual builds
build_gvisor() {

KJX="/mnt/kjx"
FETCH_GVISOR_SOURCES_DIR=./artifacts/sources
#./gvaizado
# ./artifacts/sources will eventually be copied into $KJX/sources/bin.

# ./assets/gvisor
if [ -z "$(ls -l "$KJX/sources/bin/gvisor-release"*)" ]; then
(
  set -e
  ARCH=$(uname -m)
  URL=https://storage.googleapis.com/gvisor/releases/release/latest${ARCH}
  wget "${URL}/runsc" "${URL}/runsc.sha512" \
    "${URL}/containerd-shim-runsc-v1" "${URL}/containerd-shim-runsc-v1.sha512" \
    --directory-prefix="$FETCH_GVISOR_SOURCES_DIR"

  cd $FETCH_GVISOR_SOURCES_DIR || return
  sha512sum -c runsc.sha512 -c containerd-shim-runsc-v1.sha512
  checksum=$?

  if [ "$checksum" -eq 0 ]; then
      rm -f ./*.sha512
      chmod a+rx ./runsc ./containerd-shim-runsc-v1
      #sudo mv
      cp ./runsc ./containerd-shim-runsc-v1 "../$ROOTFS_PATH/usr/local/bin"
      #
      # enter a mount namespace beforehand.
      pivot_root "../$ROOTFS_PATH/usr/local/bin/runsc install"
      # invoke podman with runsc as high-level container runtime
      ../../scripts/ccr.sh; checker && \
        docker run --rm -it --runtime=runsc hello-world && \
        sleep 15 && \
        docker stop hello-world
      umount -l

  fi
  cd - || return
)
fi
}

runsv_service() {
# gvisor
mkdir -p "$ROOTFS_PATH/etc/sv/runsc"
mkdir -p "$ROOTFS_PATH/var/log/runsc"

# start
cat > "$ROOTFS_PATH/etc/sv/runsc/run" <<EOF
#!/bin/sh

mount -t tmpfs -o size=

RAND=$(od -An -N2 i /dev/urandom | awk '{print $1 % 32768}')
ROOTFS_DIR="/tmp/runscdir_$RAND"

#HLR= high-level runtime
HLR=podman
CMD="/bin/sh"
CONTAINER_NAME=""

#mkdir --mode=0755 "$ROOTFS_DIR"

/bin/ccr; checker && \
    docker export $(docker create hello-world) \
    | sudo tar -xf - -C rootfs \
    --same-owner \
    --same-permissions

exec runsc run --rootless --network=host \
    --rootfs "${ROOTFS_DIR}" "${CONTAINER_NAME}"

EOF

# finish
cat > "$ROOTFS_PATH"/etc/sv/runsc/finish << EOF
#!/bin/sh

echo "runsc service exited with status $1" >> /var/log/runsc.log
EOF



# logging
cat > "$ROOTFS_PATH"/etc/sv/runsc/log/run <<EOF
#!/bin/sh

exec svlogd -tt /var/log/runsc | tee -a /var/log/runsc.log
EOF

#ln -s "$ROOTFS_PATH/etc/runit/sv/gvisor/runsc-up.sh" "$ROOTFS_PATH/run/runit/service/"
}

