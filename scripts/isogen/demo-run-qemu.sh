#!/bin/sh

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

squash_k3s() {
# here goes both the airgap images and the registry so containerd can

KJXPATH=$(basename "$PWD")

# REG_FILE_PATH="./artifacts/oci-registry-tarball.tar"
OCI_SKOPEO_IMG="./skopeo-test"
#TARBALL_ARTIFACT="./skopeo-convert-registry.oci.tar"
TARBALL_ARTIFACT="/tmp/skopeo-convert-registry.oci.tar"
REG_BUILD_DIR="/tmp/k3s-unpack/"

if ! [ -f "$TARBALL_ARTIFACT" ]; then
    save_registry
fi


if [ "$KJXPATH" = "kjx-headless" ]; then

    mkdir -p /tmp/k3s-unpack

    # copy the save_registry function artifact to the directory
    cp "$TARBALL_ARTIFACT" "$REG_BUILD_DIR"


    # copy the airgap tarball gzip-ed and then gunzip it
    cp ./artifacts/k3s-airgap/k3s-airgap-images-amd64.tar.gz /tmp/k3s-unpack/
    cd /tmp/k3s-unpack/ || return
    # gzip -c ./k3s-airgap-images-amd64.tar.gz > ./k3s-airgap-images-amd64.tar && \
    gunzip -c ./k3s-airgap-images-amd64.tar.gz > ./k3s-airgap-images-amd64.tar && \
        ls -allhtr ./k3s-airgap-images-amd64.tar && \
        rm ./k3s-airgap-images-amd64.tar.gz

    cd - || return
    #gzip ./artifacts/k3s-airgap/k3s-airgap-images-amd64.tar.gz -c /tmp/k3s-unpack/

    #tar -xzf ./artifacts/k3s-airgap/k3s-airgap-images-amd64.tar.gz -C /tmp/k3s-unpack
    mksquashfs /tmp/k3s-unpack /tmp/k3s-tarball.squashfs -comp zstd

    #mksquashfs ./artifacts/k3s-airgap/k3s-airgap-images-amd64.tar.gz /tmp/k3s-tarball.squashfs -comp zstd
    dd if=/dev/zero of=./utils/storage/k3s-tarball-squashfs.img bs=1M count=200
    mkfs.ext4 ./utils/storage/k3s-tarball-squashfs.img


    mkdir -p /mnt/k3s-squashfs

    sudo mount -o loop ./utils/storage/k3s-tarball-squashfs.img /mnt/k3s-squashfs/
    #sudo cp /tmp/k3s-tarball.squashfs /mnt/k3s-squashfs/
    sudo cp /tmp/k3s-tarball.squashfs /mnt/k3s-squashfs

    # clean artifacts
    rm /tmp/k3s-tarball.squashfs
    rm -rf /tmp/k3s-unpack/

    # unmount loopback device
    sudo umount /mnt/k3s-squashfs/

else
    printf "\n|> Error: outside of the path root directory. Exiting now...\n\n"
fi


}

qemu_runner() {
    # . ./scripts/sandbox/run-qemu.sh -airgap
    #

    # setup bridge
    /bin/sh ./scripts/sandbox/net-qemu_myifup.sh fallin
    printf "\n=========\nSetting up the bridge...\n============\n\n"
    # generate a macaddr
    random_mac

    if ! [ -f ./utils/storage/k3s-tarball-squashfs.img ]; then
        squash_k3s
    fi

    ANODA="/home/asari/Downloads/kjxh-artifacts/another/rootfs_v28.cpio.gz"
    FUSE="$HOME/Downloads/kjxh-artifacts/10_fuse-support/bzImage"

    qemu-system-x86_64 \
        -kernel "$FUSE" \
        -initrd "$ANODA" \
        -enable-kvm \
        -m 3072 \
        -append 'console=ttyS0 root=/dev/sda earlyprintk net.ifnames=0 cgroup_no_v1=all' \
        -nographic \
        -no-reboot \
        -drive file="./utils/storage/eulab-hd",format=raw \
        -drive file="./utils/storage/k3s-tarball-squashfs.img",format=raw \
        -net nic,model=virtio,macaddr="${MACADDRESS}" \
        -net tap,helper=/usr/lib/qemu/qemu-bridge-helper,br=vmbr0 \
        #-virtfs local,path="./artifacts/qemu-sink/",security_model=mapped-xattr
        #-serial
        # -s -S
        #-serial pty
        #-s -S

    # clean up bridge
    /bin/sh ./scripts/sandbox/net-qemu_myifup.sh clean_fallin

    # clean capabilities
    /bin/sh ./scripts/sandbox/net-qemu_myifup.sh clean_cap



}

#flamegraph() {
#}

asciiart() {

    asciinema rec demo.cast
        qemu_runner
    exit
}

all() {
    asciiart
    qemu_runner

    sleep 60s

    flamegraph
}


