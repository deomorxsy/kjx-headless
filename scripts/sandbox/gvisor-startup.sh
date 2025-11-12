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
ROOTFS_PATH="${UPPER_MOUNTPOINT}/rootfs"
FETCH_GVISOR_SOURCES_DIR="${HOME}/artifacts/sources"

RAND="$(od -An -N2 /dev/urandom | awk '{print $1 % 32768}')"

# manual builds
build_gvisor() {

KJX="/mnt/kjx"
#./gvaizado
# ./artifacts/sources will eventually be copied into $KJX/sources/bin.
if ! [ -d "${FETCH_GVISOR_SOURCES_DIR}" ]; then
    printf "\n|> Error: sources directory does not exist. Creating...\n\n"
fi
mkdir -p "${FETCH_GVISOR_SOURCES_DIR}/bin"

# ./assets/gvisor
#if [ -z "$(ls -l "$KJX/sources/bin/gvisor-release"*)" ]; then
if ! [ -f "${FETCH_GVISOR_SOURCES_DIR}/bin/gvisor-*" ]; then
(
  set -e
  ARCH=$(uname -m)
  URL=https://storage.googleapis.com/gvisor/releases/release/latest/${ARCH}
  wget "${URL}/runsc" "${URL}/runsc.sha512" \
    "${URL}/containerd-shim-runsc-v1" "${URL}/containerd-shim-runsc-v1.sha512" \
    --directory-prefix="${FETCH_GVISOR_SOURCES_DIR}" && \

  cd "${FETCH_GVISOR_SOURCES_DIR}" || return &&
  sha512sum -c runsc.sha512 -c containerd-shim-runsc-v1.sha512 && \
  checksum=$? && \

  if [ "$checksum" -eq 0 ]; then
      rm -f ./*.sha512 && \
      chmod a+rx ./runsc ./containerd-shim-runsc-v1 && \
      #sudo mv
      tar -czf ./gvisor-core.tar.gz .
  fi
  cd - || return
)
fi
}

runit_service() {

ROOTFS_DIR="/tmp/runscdir_${RAND}"
# RAND="$(od -An -N2 /dev/urandom | awk '{print $1 % 32768}')"

# gvisor
mkdir -p "$ROOTFS_PATH/etc/sv/runsc"
mkdir -p "$ROOTFS_PATH/var/log/runsc"

# start
cat > "$ROOTFS_PATH/etc/sv/runsc/run" <<EOF
#!/bin/sh

mount -t tmpfs tmpfs /tmp
#size=790M


HLCR=podman
CMD="/bin/sh"
CONTAINER_NAME=""

mkdir -p --mode=0755 "${ROOTFS_DIR}"

/bin/ccr; checker && \
    docker export $(docker create hello-world) \
    | sudo tar -xf - -C rootfs \
    --same-owner \
    --same-permissions

exec runsc run --rootless --network=host \
    --rootfs "${ROOTFS_DIR}" "${CONTAINER_NAME}"

EOF

# finish
(
cat <<EOF
#!/bin/sh

exec chpst -ulog svlogd -tt /bin/runsc
EOF
) | tee "${ROOTFS_PATH}"/etc/sv/runsc/finish


# logging
(
cat <<EOF
#!/bin/sh

exec svlogd -tt /var/log/runsc | tee -a /var/log/runsc.log
EOF
) | tee "${ROOTFS_PATH}/etc/sv/runsc/log/run"

ln -s "$ROOTFS_PATH/etc/runit/sv/gvisor/runsc-up.sh" "$ROOTFS_PATH/run/runit/service/"

}


print_usage() {
cat <<-END >&2
USAGE: gvisor-startup [-options]
                - build
                - version
                - help
eg,
MODE="build"        ./gvisor-startup.sh   # Fetch dependencies for all-in-one gvisor
MODE="version"      ./gvisor-startup.sh   # shows script version
MODE="help"         ./gvisor-startup.sh   # shows this help message

See the man page and example file for more info.

END

}


# Check the argument passed from the command line
# if ! [ -z "${MODE}" ]; then
#     case "${MODE}" in
#         "build")
#             build_gvisor
#             ;;
#         *)
#             echo "Invalid option. Please specify one of: build, help, version"
#             print_usage
#             ;;
#     esac


if [ "${MODE}" = "-build" ] || [ "${MODE}" = "--build" ] || [ "${MODE}" = "build" ]; then
    build_gvisor
elif [ "${MODE}" = "-help" ] || [ "${MODE}" = "-h" ] || [ "${MODE}" = "--help" ]; then
    print_usage
elif [ "${MODE}" = "version" ] || [ "${MODE}" = "-v" ] || [ "${MODE}" = "--version" ]; then
    printf "\n|> Version: gvisor 1.0.0"
else
    echo "Invalid function name. Please specify one of the available functions:"
    print_usage
fi





