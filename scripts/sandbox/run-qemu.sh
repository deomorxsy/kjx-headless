#!/bin/sh

# ====================
#
# Global variables
#
# Checks if the current directory is root of the repository
KJXPATH=$(basename "$PWD")
# Raw Virtual Disk Sparse file path
RVDSF_EULAB="./utils/storage/eulab-hd"

# utils directory path for the raw image
K3S_SQUASHFS_IMAGE_PATH="./utils/storage/k3s-tarball-squashfs.img"

# OCI image artifact from the conversion using skopeo
#
SKOPEO_TARBALL_ARTIFACT="/tmp/skopeo-convert-registry.oci.tar"
# ===========
# Virtio utils
# virtfs path
VIRTFS_ART_PATH="./artifacts/qemu-sink/"

# =====================
# Recording variables
# asciinema recording file path
ASCII_DATE="$(date | awk '{print $1"-"$2"-"$3"-"$4"_"$5}' | tr ":" "-")"
RUNISO_RECORDING_PATH="./artifacts/run-qemu_runiso_$(date | awk '{print $1"-"$2"-"$3"-"$4"_"$5}' | tr ":" "-").cast"

# default recording state
IS_RECORDING="NO"

random_mac() {

    #check_shell=$(ps -p $$ | awk "NR==2" | awk '{ print $4 }')

    rh1=$(head -c 64 /dev/urandom | tr -cd 0-9 | head -c 20)
    rh2=$(head -c 64 /dev/urandom | tr -cd 0-9 | head -c 20)
    rh3=$(head -c 64 /dev/urandom | tr -cd 0-9 | head -c 20)
    rh4=$(head -c 64 /dev/urandom | tr -cd 0-9 | head -c 20)

    bubo=$(command -v busybox)
    MACADDRESS=$($bubo printf "52:54:%02x:%02x:%02x:%02x" \
        "$rh1" "$rh2" \
        "$rh3" "$rh4")

    export MACADDRESS
    printf "\n\n%s\n" "${MACADDRESS}"

    # printf -v macaddr "52:54:%02x:%02x:%02x:%02x" \
    #     $(( RANDOM & 0xff )) \
    #     $(( RANDOM & 0xff )) \
    #     $(( RANDOM & 0xff )) \
    #     $(( RANDOM & 0xff ))
}

kjx() {

    # setup the bridge
    . ./scripts/sandbox/net-qemu_myifup.sh

    # bring back connection to the host
    #ip link set enp4s0 nomaster
    #ip link set enp4s0 master vmbr0
    echo "net done"

    # generate a macaddr
    random_mac

    qemu-system-x86_64 \
        -kernel "$HOME/Downloads/kjx-headless/bzImage" \
        -initrd "$HOME/Downloads/kjx-headless/initramfs.cpio.gz" \
        -enable-kvm \
        -m 1024 \
        -append 'console=ttyS0 root=/dev/sda selinux=0 earlyprintk net.ifnames=0' \
        -nographic \
        -no-reboot \
        -drive file="./utils/storage/eulab-hd",format=raw \
        -net nic,model=virtio,macaddr="$macaddr" \
        -net tap,helper=/usr/lib/qemu/qemu-bridge-helper,br=vmbr0 \
        -s -S
}

debug() {

    # setup the bridge
    . ./scripts/sandbox/net-qemu_myifup.sh

    # generate a macaddr
    random_mac

    qemu-system-x86_64 \
        -kernel "$HOME/Downloads/kjx-headless/bzImage" \
        -initrd "$HOME/Downloads/kjx-headless/initramfs.cpio.gz" \
        -enable-kvm \
        -m 1024 \
        -append 'console=ttyS0 root=/dev/sda earlyprintk net.ifnames=0' \
        -nographic \
        -no-reboot \
        -drive file="./utils/storage/eulab-hd",format=raw \
        -net nic,model=virtio,macaddr="$macaddr" \
        -net tap,helper=/usr/lib/qemu/qemu-bridge-helper,br=vmbr0 \
        -s -S
}

thirdver() {

    # setup bridge
    /bin/sh ./scripts/sandbox/net-qemu_myifup.sh bridge
    printf "\n=========\nSetting up the bridge...\n============\n\n"

    # generate a macaddr
    random_mac
    # "$HOME/Downloads/dropbear-image/rootfs-with-ssh.cpio.gz"
    # ./artifacts/distro/mar.initramfs.cpio.gz
    # ./artifacts/distro/mar.initramfs.cpio.gz
    qemu-system-x86_64 \
        -kernel ./artifacts/bzImage \
        -initrd ./artifacts/ssh-rootfs/ssh-rootfs-revised.cpio_0.3.1.gz \
        -enable-kvm \
        -m 1024 \
        -append 'console=ttyS0 root=/dev/sda earlyprintk net.ifnames=0' \
        -nographic \
        -no-reboot \
        -drive file="./utils/storage/eulab-hd",format=raw \
        -net nic,model=virtio,macaddr="$macaddr" \
        -net tap,helper=/usr/lib/qemu/qemu-bridge-helper,br=vmbr0
    #-serial pty
    #-s -S

    # clean up bridge
    /bin/sh ./scripts/sandbox/net-qemu_myifup.sh clean_bridge
    #echo runqemu1

    /bin/sh ./scripts/sandbox/net-qemu_myifup.sh clean_cap
    #echo runqemu2
    #printf "\n=========\nCleaning now...\n============\n"

    #echo HMMMMMMMMM
}

repack_switch() {

    # check for ./.github/workflows/dropbear.yml artifact
    if [ -f ./artifacts/ssh-rootfs/rootfs-with-ssh.cpio.gz ]; then

        # clean the rootfs tree if it exists
        rm -rf ./artifacts/ssh-rootfs/fakerootdir/* &&

            # decompress gunzip and then cpio to the specified path
            gzip -cd ./artifacts/ssh-rootfs/rootfs-with-ssh.cpio.gz | cpio -idmv -D ./artifacts/ssh-rootfs/fakerootdir/

        ssh-keygen -t ed25519 -C "dropbear" -f ./artifacts/ssh-keys/kjx-keys -N ""
        cat ./artifacts/ssh-keys/kjx-keys.pub >>./artifacts/ssh-rootfs/fakerootdir/etc/dropbear/authorized_keys
        #./artifacts/dropbear/~/Downloads/dropbear-image/modified/fakerootdir/etc/dropbear/authorized_keys

        # enter dir just to run find
        cd ./artifacts/ssh-rootfs/fakerootdir/ || return &&

            # patch the specified file with anything
            #
            ROOTFS_SEMVER=0.2.1
        # create revised cpio.gz rootfs tarball
        find . -print0 | busybox cpio --null -ov --format=newc | gzip -9 >../ssh-rootfs-revised.cpio_"$ROOTFS_SEMVER".gz &&
            echo done!!

    else
        printf "\n|> tarball file not found inside ./artifacts/ssh-rootfs. Attempting to download...\n"

        wget
    fi

    echo
}

dropbear() {

    # setup bridge
    #/bin/sh ./scripts/sandbox/net-qemu_myifup.sh bridge

    /bin/sh ./scripts/sandbox/net-qemu_myifup.sh fallin

    printf "\n=========\nSetting up the bridge...\n============\n\n"

    # generate a macaddr
    random_mac
    # "$HOME/Downloads/dropbear-image/rootfs-with-ssh.cpio.gz"
    # ./artifacts/distro/mar.initramfs.cpio.gz
    #  /home/asari/Downloads/initramfs/initramfs.cpio.gz

    DROBE="./artifacts/ssh-rootfs/ssh-rootfs-revised.cpio_0.3.2.gz"
    ANODA="/home/asari/Downloads/kjxh-artifacts/another/rootfs_v13.cpio.gz"

    qemu-system-x86_64 \
        -kernel ./artifacts/bzImage \
        -initrd "$ANODA" \
        -enable-kvm \
        -m 1024 \
        -append 'console=ttyS0 root=/dev/sda earlyprintk net.ifnames=0' \
        -nographic \
        -no-reboot \
        -drive file="./utils/storage/eulab-hd",format=raw \
        -net nic,model=virtio,macaddr="$macaddr" \
        -net tap,helper=/usr/lib/qemu/qemu-bridge-helper,br=vmbr0
    #-serial pty
    #-s -S

    # clean up bridge
    # /bin/sh ./scripts/sandbox/net-qemu_myifup.sh clean_bridge
    /bin/sh ./scripts/sandbox/net-qemu_myifup.sh clean_fallin
    #echo runqemu1

    /bin/sh ./scripts/sandbox/net-qemu_myifup.sh clean_cap
    #echo runqemu2
    #printf "\n=========\nCleaning now...\n============\n"

    #echo HMMMMMMMMM
}

create_rvdsf() {
    if ! [ -f "${RVDSF_EULAB}" ]; then
        printf "|> Raw Virtual Disk Sparse File was not found. Creating..."
    else
        printf "|> Raw Virtual Disk Sparse File already exist. Exiting now..."
        return 1
    fi
    MODE="-sf" . ./scripts/isogen/rvdsf.sh

}

save_registry() {
    # Function that saves the registry itself for
    # containerd to be able to serve images in an
    # airgap context inside the ISO. Useful for
    # either DMZ, no WAN or running on a guest without
    # WAN access and without using virtfs.

    CCR_MODE="-checker" . ./scripts/ccr.sh &&
        docker pull docker://registry:3.0

    REG_NAME=$(podman images | grep registry | awk '{print $3}')
    SKOPEO_TARBALL_ARTIFACT="/tmp/skopeo-convert-registry.oci.tar"

    # This creates a docker-save tarball bundle
    # podman save -o ./artifacts/oci-registry-tarball.tar "$REG_NAME"

    # Check the contents
    # tar tf ./artifacts/oci-registry-tarball.tar | head

    # convert the docker-save tarball bundle to OCI spec so it can
    mkdir -p ./skopeo-test
    ## idempotent
    # skopeo copy containers-storage:localhost:5000/registry:3.0 dir:$PWD/skopeo-test/
    skopeo copy containers-storage:localhost:5000/registry:3.0 oci:"$PWD"/skopeo-test:3.0

    # inspect with umoci
    # umoci unpack --image /tmp/oci-layout:myimage /tmp/umoci-rootfs

    # list output contents
    ls -allhtr ./skopeo-test/

    # create tarball
    # tar -C /tmp/oci-registry-tarball -cf /tmp/registry.oci.tar .
    # tar -cf "$SKOPEO_TARBALL_ARTIFACT" "$PWD/skopeo-test/"
    tar -C ./skopeo-test -cf "${SKOPEO_TARBALL_ARTIFACT}" .

    rm -rf ./skopeo-test

}

fetch_k3s() {
    # fetch the base OCI/CRI images for an k3s
    # airgap cluster since it might be inside a DMZ.

    OLD_K3S_VERSION=""
    K3S_VERSION="v1.34.2"

    K3S_AIRGAP_URI="https://github.com/k3s-io/k3s/releases/download/v1.34.2%2Bk3s1/k3s-airgap-images-amd64.tar.gz"
    K3S_AIRGAP_URI_SHA256SUM="https://github.com/k3s-io/k3s/releases/download/v1.34.2%2Bk3s1/k3s-airgap-images-amd64.sha256sum"

    K3S_AIRGAP_PATH="./artifacts/k3s-airgap/outro"
    K3S_AIRGAP_TARBALL_GZ="${K3S_AIRGAP_PATH}/k3s-airgap-images_${K3S_VERSION}-amd64.tar.gz"
    K3S_AIRGAP_TARGZ_SHA256SUM="${K3S_AIRGAP_PATH}/k3s-airgap-images_${K3S_VERSION}-amd64.sha256sum"

    # make sure the k3s airgap path exists
    if ! [ -d "${K3S_AIRGAP_PATH}" ]; then
        mkdir -p "${K3S_AIRGAP_PATH}" &&
            printf "\n|> Creating k3s airgap path...\n\n"
        # idempotent
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: fetch_k3s"
        printf "\n|> CHECK 01:"
        printf "\n|> Does the SKOPEO_TARBALL_ARTIFACT filepath exists?...[PASSED]\n\n"
        ;;
    esac

    # Fetch tarball.gz images and name it with said version
    if ! wget -O "${K3S_AIRGAP_TARBALL_GZ}" "${K3S_AIRGAP_URI}"; then
        printf "\n|> Error: could not download the k3s airgap tarball.gz. Exiting now...\n\n"
        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: fetch_k3s"
        printf "\n|> CHECK 02:"
        printf "\n|> fetch tarball.gz image with said version on the filepath...[PASSED]\n\n"
        ;;
    esac
    printf "\n|> k3s airgap tarball.gz download has finished.\n\n"

    # Fetch tarball.gz images SHA256SUM and name it with said version
    if ! wget -O "${K3S_AIRGAP_TARGZ_SHA256SUM}" "${K3S_AIRGAP_URI_SHA256SUM}"; then
        printf "\n|> Error: could not download the k3s airgap tarball.gz SHA256SUM. Exiting now...\n\n"
        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: fetch_k3s"
        printf "\n|> CHECK 03:"
        printf "\n|> fetch tarball.gz image SHA256SUM with said version on the filepath...[PASSED]\n\n"
        ;;
    esac
    printf "\n|> k3s airgap tarball.gz SHA256SUM download has finished.\n\n"

    # Check the SHA256SUM if it is the correct tarball
    cd "${K3S_AIRGAP_PATH}" || return
    FILECHECK=$(sha256sum "${K3S_AIRGAP_TARBALL_GZ}")
    cd - || return

    ORIGINALSHA=$(grep "${K3S_AIRGAP_TARBALL_GZ}" ./artifacts/wget-checksums.txt | awk '{print $1}')

    if [ "${FILECHECK}" = "${ORIGINALSHA}" ]; then
        echo "checksum success: files are valid."
    else
        echo "checksum failed: files are different."
        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: fetch_k3s"
        printf "\n|> CHECK 04:"
        printf "\n|> check the SHA256SUM if it is the correct tarball...[PASSED]\n\n"
        ;;
    esac
    printf "\n|> Checksum check was successful."

}

squash_k3s() {
    # PS-2: kind of unecessary since with virtio/virtfs
    # the artifact can be shared between host and guest without
    # relying on the qemu device.

    # PS-1: here goes both the airgap images and the registry so containerd can
    # gunzip,
    KJXPATH=$(basename "$PWD")

    # REG_FILE_PATH="./artifacts/oci-registry-tarball.tar"
    OCI_SKOPEO_IMG="./skopeo-test"
    #SKOPEO_TARBALL_ARTIFACT="./skopeo-convert-registry.oci.tar"
    SKOPEO_TARBALL_ARTIFACT="/tmp/skopeo-convert-registry.oci.tar"
    # REG_BUILD_DIR="/tmp/k3s-unpack/"

    # k3s airgap image path and basenames
    K3S_AIRGAP_PATH="./artifacts/k3s-airgap"
    K3S_AIRGAP_TARBALL_GZ="${K3S_AIRGAP_PATH}/k3s-airgap-images-amd64.tar.gz"
    K3S_AIRGAP_TARBALL_GZ_NAME="k3s-airgap-images-amd64.tar.gz"
    K3S_AIRGAP_TAR_NAME="k3s-airgap-images-amd64.tar"

    # /tmp directories to unpack and squashfs
    K3S_UNPACK_TMP="/tmp/k3s-unpack"
    K3S_SQUASHFS_FILE="/tmp/k3s-tarball.squashfs"

    #K3S_SQUASHFS_IMAGE_PATH="./utils/storage/k3s-tarball-squashfs.img"

    # mount point for the k3s-squashfs
    MOUNTPOINT_K3S_SQUASHFS="/mnt/k3s-squashfs"

    if ! [ -f "${SKOPEO_TARBALL_ARTIFACT}" ]; then
        printf "\n|> skopeo tarball artifact was not found. Running the [ save_registry ] function now...\n\n"
        save_registry
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: squash_k3s"
        printf "\n|> CHECK 01:"
        printf "\n|> Does the SKOPEO_TARBALL_ARTIFACT filepath exists?...[PASSED]\n\n"
        ;;
    esac

    # check if k3s airgap tarball.gz already exists.
    if ! [ -f "${K3S_AIRGAP_TARBALL_GZ}" ]; then
        printf "\n|> k3s airgap tarball.gz was not found. Attempting to run the [ fetch_k3s ] function now...\n\n"
        fetch_k3s
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: squash_k3s"
        printf "\n|> CHECK 02:"
        printf "\n|> Does the K3S_AIRGAP_TARBALL_GZ filepath exists?...[PASSED]\n\n"
        ;;
    esac

    # check if PWD is the root of the repository
    if ! [ "${KJXPATH}" = "kjx-headless" ]; then
        # printf "\n|> Error: not on the root of the kjx-headless repository. Exiting now..."
        printf "\n|> Error: outside of the path root directory. Exiting now...\n\n"
        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: squash_k3s"
        printf "\n|> CHECK 03:"
        printf "\n|> Is PWD the root of the kjx-headless repository?...[PASSED]\n\n"
        ;;
    esac

    #if [ "${KJXPATH}" = "kjx-headless" ]; then

    # make sure the K3S_UNPACK_TMP directory exists
    if ! mkdir -p "${K3S_UNPACK_TMP}" &&

        # Copy the save_registry function artifact to the directory
        cp "${SKOPEO_TARBALL_ARTIFACT}" "${K3S_UNPACK_TMP}" &&

        # Copy the airgap tarball gzip-ed and then gunzip it
        cp "${K3S_AIRGAP_TARBALL_GZ}" "${K3S_UNPACK_TMP}" &&
        cd "${K3S_UNPACK_TMP}" || return &&
        gunzip -c "${K3S_AIRGAP_TARBALL_GZ_NAME}" >"${K3S_AIRGAP_TAR_NAME}" &&
        ls -allhtr "${K3S_AIRGAP_TAR_NAME}" &&
        rm "${K3S_AIRGAP_TARBALL_GZ_NAME}" &&
        cd - || return; then
        printf "\n|> Error: it was not possible to handle the airgap tarball gzip-ed, gunzip it and finish cleaning. Exiting now..."
        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: squash_k3s"
        printf "\n|> CHECK 04:"
        printf "\n|> handle the airgap tarball gzip-ed, gunzip it and finish cleaning. ...[PASSED]\n\n"
        ;;
    esac
    printf "\n|> K3S_AIRGAP_TAR_NAME created with success. Proceeding..."

    # Create a mksquashfs from k3s-unpack tmp directory
    if ! mksquashfs "${K3S_UNPACK_TMP}" "${K3S_SQUASHFS_FILE}" -comp zstd; then
        printf "|> Error: it was not possible to create a mksquashfs from the k3s-unpack tmp directory at the %s filepath. Exiting now..." "${K3S_SQUASHFS_FILE:-[EMPTY_VARIABLE]}"
        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: squash_k3s"
        printf "\n|> CHECK 05:"
        printf "\n|> create a mksquashfs from k3s-unpack tmp directory. ...[PASSED]\n\n"
        ;;
    esac
    printf "\n|> Successfully created a mksquashfs from k3s-unpack tmp directory.\n\n"

    # Create raw image for it to be added as drive input for QEMU
    # with unconditional branch
    if ! [ -d "$(dirname "${K3S_SQUASHFS_IMAGE_PATH}")" ]; then
        printf "\n|> Error: the directory path %s does not exist Creating..." "$(dirname "${K3S_SQUASHFS_IMAGE_PATH}")"
        mkdir -p "$(dirname "${K3S_SQUASHFS_IMAGE_PATH}")"
    fi
    if ! dd if=/dev/zero of="${K3S_SQUASHFS_IMAGE_PATH}" bs=1M count=200; then
        printf "|> Error: dd failed with exit code %s\n" $?
        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: squash_k3s"
        printf "\n|> CHECK 06:"
        printf "\n|> create a raw image with dd. ...[PASSED]\n\n"
        ;;
    esac
    printf "\n|> Successfully created a raw image with dd.\n\n"

    # format the k3s squashfs image path filename with the ext4 filesystem
    # deps:
    if ! mkfs.ext4 "${K3S_SQUASHFS_IMAGE_PATH}"; then
        printf "|> Error: mkfs.ext4 failed with exit code %s\n" $?
        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: squash_k3s"
        printf "\n|> CHECK 07:"
        printf "\n|> create a raw image with dd. ...[PASSED]\n\n"
        ;;
    esac
    printf "\n|> Successfully formatted the image with a ext4 filesystem with mkfs.ext4.\n\n"

    # Create mountpoint dir and create a loop mount with the squashfs image path
    mkdir -p "${MOUNTPOINT_K3S_SQUASHFS}"
    sudo mount -o loop "${K3S_SQUASHFS_IMAGE_PATH}" "${MOUNTPOINT_K3S_SQUASHFS}"

    # Copy the file itself to the mount point path
    sudo cp "${K3S_SQUASHFS_FILE}" "${MOUNTPOINT_K3S_SQUASHFS}"

    # clean artifacts
    if [ -f "${K3S_SQUASHFS_FILE}" ]; then
        rm "${K3S_SQUASHFS_FILE}"
        echo "|> Removed ${K3S_SQUASHFS_FILE} with success."
    fi &&
        if [ -d "${K3S_UNPACK_TMP}" ]; then
            rm -rf "${K3S_UNPACK_TMP}"
            echo "|> Removed ${K3S_UNPACK_TMP} with success."
        fi

    # unmount loopback device
    sudo umount "${MOUNTPOINT_K3S_SQUASHFS}"

    #else
    #    printf "\n|> Error: outside of the path root directory. Exiting now...\n\n"
    #fi

}

# Function to manually test configuration
# with an airgap k3s build.
# todo: virtfs
airgap_k3s() {

    #K3S_SQUASHFS_IMAGE_PATH="./utils/storage/k3s-tarball-squashfs.img"

    # Setup bridge
    /bin/sh ./scripts/sandbox/net-qemu_myifup.sh fallin

    printf "\n=========\nSetting up the bridge...\n============\n\n"

    # Generate a macaddr
    if ! random_mac; then
        printf "\n|> It was not possible to generate a macaddr. Exiting now..."
        return 1
    fi
    printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh_AIRGAP_K3S"
    printf "\n|> CHECK 01:"
    printf "\n|> Generating a macaddr... [PASSED]\n\n"

    if ! [ "${KJXPATH}" = "kjx-headless" ]; then
        printf "|> Error: not on the root of the kjx-headless repository. Change dir and try again.\nExiting now...\n\n"
        return 1
    fi
    printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh_AIRGAP_K3S"
    printf "\n|> CHECK 02:"
    printf "\n|> Is PWD the root of the repository?... [PASSED]\n\n"

    # it will only run if the k3s squashfs image does not exist.
    #if [ "${KJXPATH}" = "kjx-headless" ]; then
    # Check if raw image exists at utils

    if ! [ -f "${K3S_SQUASHFS_IMAGE_PATH}" ] && ! [ -f "${SKOPEO_TARBALL_ARTIFACT}" ]; then
        # Check if Skopeo OCI conversion image artifact exists
        # so it gets generated every run as needed
        printf "\n|> Error: either one or both of the filepaths %s and %s \
            does not exist. Attempting to generate it..." \
            "${K3S_SQUASHFS_IMAGE_PATH:-[EMPTY_VARIABLE]}" "${SKOPEO_TARBALL_ARTIFACT:-[EMPTY_VARIABLE]}"

        if ! squash_k3s; then
            printf "|> Error: it was not possible to generate at least one of the filepaths. Exiting now..."
            return 1
        fi
    fi
    printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh_AIRGAP_K3S"
    printf "\n|> CHECK 03:"
    printf "\n|> Does K3S_SQUASHFS_IMAGE_PATH AND SKOPEO_TARBALL_ARTIFACT exists?... [PASSED]\n\n"

    # Check if raw virtual disk sparse file exists at utils
    if ! [ -f "${RVDSF_EULAB}" ]; then
        printf "|> Error: raw virtual disk sparse file does not exist. Attempting to create now..."

        if ! create_rvdsf; then
            printf "|> Error: it was not possible to create a RVDSF. Exiting now..."
            return 1
        fi
    fi
    printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh_AIRGAP_K3S"
    printf "\n|> CHECK 04:"
    printf "\n|> Does RVDSF filepath exists?...[PASSED]\n\n"

    ######## ANODA ###########
    #
    # PS: ANODA is the initramfs.cpio.gz that serves temporarily as a rootfs
    #
    # v13: This one enables cgroupsv2 only, without cgroupsv1
    #   rootfs_v13.cpio.gz"
    #
    # v14: This one have containerd dynamically linked against musl
    #   rootfs_v14.cpio.gz"
    #
    # v15: This one have fuse-overlayfs
    #   rootfs_v15.cpio.gz"
    #
    # v16-v25: These already one have bpftrace
    #   rootfs_v16.cpio.gz
    #   ...
    #   ...
    #   rootfs_v25.cpio.gz

    # v26: New kernel modules properly setup
    #   rootfs_v26.cpio.gz"

    # v27: gvisor runsv, kata and crun binaries enabled
    #   rootfs_v27.cpio.gz"

    # v28: Full podman dynamic binaries and shared objects
    ANODA="/home/asari/Downloads/kjxh-artifacts/another/rootfs_v28.cpio.gz"
    if ! [ -f "${ANODA}" ]; then
        printf "\n|> Error: missing initramfs.cpio.gz (passing as a rootfs) - Not found in given path!"
        printf "\n|> Exiting now...\n\n"
        return 1
    fi

    # PS: this kernel image needs to have the
    # kernel modules *.ko,
    # then squashfs, memcg, fuse, overlayfs support.
    MANUAL_AIRGAP_BZIMAGE="$HOME/Downloads/kjxh-artifacts/10_fuse-support/bzImage"
    if ! [ -f "${MANUAL_AIRGAP_BZIMAGE}" ]; then
        printf "\n|> Error: missing initramfs.cpio.gz (passing as a rootfs) - Not found in given path!"
        printf "\n|> Exiting now...\n\n"
        return 1
    fi

    # Mind that this will need fuse-overlayfs since the -initrd flag
    # runs an initramfs.cpio.gz over ramfs/tmpfs, that is, on RAM, and not
    # in a filesystem storage. For overlayfs only, use the ISO.
    qemu-system-x86_64 \
        -kernel "$MANUAL_AIRGAP_BZIMAGE" \
        -initrd "$ANODA" \
        -enable-kvm \
        -m 3072 \
        -append 'console=ttyS0 root=/dev/sda earlyprintk net.ifnames=0 cgroup_no_v1=all' \
        -nographic \
        -no-reboot \
        -drive file="${RVDSF_EULAB}",format=raw \
        -drive file="${K3S_SQUASHFS_IMAGE_PATH}",format=raw \
        -net nic,model=virtio,macaddr="${MACADDRESS}" \
        -net tap,helper=/usr/lib/qemu/qemu-bridge-helper,br=vmbr0 \
        -virtfs local,path="${VIRTFS_ART_PATH}",mount_tag=hostshare,security_model=mapped-xattr
    # -virtfs local,path="./artifacts/qemu-sink/",security_model=mapped-xattr \
    #-serial
    # -s -S
    #-serial pty
    #-s -S

    # clean up bridge
    /bin/sh ./scripts/sandbox/net-qemu_myifup.sh clean_fallin

    # clean capabilities
    /bin/sh ./scripts/sandbox/net-qemu_myifup.sh clean_cap

}

configure_vm_ssh() {

    ssh-keygen -t ed25519 -f ~/.ssh/qemu_vm_key -N ""

}

# run the final iso artifact
runiso() {

    CURRENT_ISO="./artifacts/kjx-headless_v3.iso"
    OLD_ISO="./artifacts/kjx-headless.iso"

    if ! [ -d "${VIRTFS_ART_PATH}" ]; then
        mkdir -p "${VIRTFS_ART_PATH}" &&
            printf "\n|> Creating virtfs artifact directory...\n\n"
    fi

    # it will only run if the k3s squashfs image does not exist.
    if [ "${KJXPATH}" = "kjx-headless" ]; then
        # Check if raw image exists at utils
        if ! [ -f "${K3S_SQUASHFS_IMAGE_PATH}" ]; then
            squash_k3s
        fi

        # Check if raw virtual disk sparse file exists at utils
        if ! [ -f "${RVDSF_EULAB}" ]; then
            create_rvdsf
        fi
    fi

    qemu-system-x86_64 \
        -m 1024 \
        -cdrom "${CURRENT_ISO}" \
        -boot d \
        -enable-kvm \
        -nographic \
        -no-reboot \
        -cpu host \
        -serial mon:stdio \
        -drive file="${RVDSF_EULAB}",format=raw \
        -drive file="${K3S_SQUASHFS_IMAGE_PATH}",format=raw \
        -virtfs local,path="${VIRTFS_ART_PATH}",mount_tag=hostshare,security_model=mapped-xattr

}

record_runiso() {
    # creates a file at "${RUNISO_RECORDING_PATH}"
    IS_RECORDING="YES"

    if [ "${IS_RECORDING}" = "YES" ]; then
        if ! command -v asciinema; then
            printf "\n|> Error: asciinema was not found. Nothing to be done.\n|> Exiting now...\n\n" &&
                return 1
        fi
        printf "\n|> Recording section is in course. Invoking asciinema...\n\n" &&
            asciinema rec "${RUNISO_RECORDING_PATH}" --command="make runiso" &&

            #if [ "${IS_RECORDING}" = "YES" ]; then
            # asciinema stop && \
            exec <&- &&
            printf "\n|> Stop recording the asciinema section. Exiting now...\n\n"
        #fi
    fi

    # runiso

}

print_usage() {
    cat <<-END >&2
USAGE: run-qemu [-options]
                - thirdver
                - dropbear
                - debug
                - help
                - version
eg,
run-qemu -thirdver   # runs qemu pointing to a custom initramfs and kernel bzImage
run-qemu -dropbear  # runs qemu enabled with ssh for quick file copying between target vm and host
run-qemu -airgap  # runs qemu with files to run k3s air-gapped
run-qemu -debug # the same of thirdver but with serial and pty flags for kernel debug
run-qemu -help    # shows this help message
run-qemu -version # shows script version

See the man page and example file for more info.

END

}

# Check the argument passed from the command line
if [ "${MODE}" = "firstver" ]; then
    firstver
elif [ "${MODE}" = "macaddr" ]; then
    macaddr
elif [ "${MODE}" = "thirdver" ] || [ "${MODE}" = "-t" ] || [ "${MODE}" = "--thirdver" ]; then
    thirdver
elif [ "${MODE}" = "dropbear" ] || [ "${MODE}" = "-d" ] || [ "${MODE}" = "--dropbear" ]; then
    dropbear
elif [ "${MODE}" = "kjx" ]; then
    kjx
elif [ "${MODE}" = "--airgap" ] || [ "${MODE}" = "-ag" ] || [ "${MODE}" = "-airgap" ]; then
    airgap_k3s
elif [ "${MODE}" = "--squash" ] || [ "${MODE}" = "-sq" ] || [ "${MODE}" = "-sq" ] || [ "${MODE}" = "-squash" ]; then
    squash_k3s
elif [ "${MODE}" = "--runiso" ] || [ "${MODE}" = "-runiso" ] || [ "${MODE}" = "runiso" ]; then
    runiso
elif [ "${MODE}" = "--record-runiso" ] || [ "${MODE}" = "-record-runiso" ] || [ "${MODE}" = "record-runiso" ]; then
    record_runiso
elif [ "${MODE}" = "help" ] || [ "${MODE}" = "-h" ] || [ "${MODE}" = "--help" ]; then
    print_usage
elif [ "${MODE}" = "debug" ]; then
    debug
else
    echo "Invalid function name. Please specify one of: function1, function2, function3"
    print_usage
fi
