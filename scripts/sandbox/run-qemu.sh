#!/bin/sh
#
random_mac() {

#check_shell=$(ps -p $$ | awk "NR==2" | awk '{ print $4 }')

rh1=$(head -c 64 /dev/urandom | tr -cd 0-9 | head -c 20)
rh2=$(head -c 64 /dev/urandom | tr -cd 0-9 | head -c 20)
rh3=$(head -c 64 /dev/urandom | tr -cd 0-9 | head -c 20)
rh4=$(head -c 64 /dev/urandom | tr -cd 0-9 | head -c 20)

bubo=$(command -v busybox)
macaddress=$($bubo printf "52:54:%02x:%02x:%02x:%02x" \
    "$rh1" "$rh2" \
    "$rh3" "$rh4")

printf "\n\n%s\n" "$macaddress"

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

if [ -f ./artifacts/ssh-rootfs/rootfs-with-ssh.cpio.gz ]; then

    # clean the rootfs tree if it exists
    rm -rf ./artifacts/ssh-rootfs/fakerootdir/* && \

    # decompress gunzip and then cpio to the specified path
    gzip -cd ./artifacts/ssh-rootfs/rootfs-with-ssh.cpio.gz | cpio -idmv -D ./artifacts/ssh-rootfs/fakerootdir/

    ssh-keygen -t ed25519 -C "dropbear" -f ./artifacts/ssh-keys/kjx-keys -N ""
    cat ./artifacts/ssh-keys/kjx-keys.pub >> ./artifacts/ssh-rootfs/fakerootdir/etc/dropbear/authorized_keys
    #./artifacts/dropbear/~/Downloads/dropbear-image/modified/fakerootdir/etc/dropbear/authorized_keys



    # enter dir just to run find
    cd ./artifacts/ssh-rootfs/fakerootdir/ || return && \

    # patch the specified file with anything
    #
    ROOTFS_SEMVER=0.2.1
    # create revised cpio.gz rootfs tarball
    find . -print0 | busybox cpio --null -ov --format=newc | gzip -9 > ../ssh-rootfs-revised.cpio_"$ROOTFS_SEMVER".gz && \
    echo done!!

else
    printf "\n|> tarball file not found inside ./artifacts/ssh-rootfs .\n"
fi


echo
}


patch_k3s() {

fakerootdir="/var/lib/rancher/k3s/agent/etc/containerd/config.toml.tmpl"

    # setup the k3s toml
( cat <<EOF
version = 3
[plugins."io.containerd.cri.v1.runtime".containerd]
  default_runtime_name = "crun"
  [plugins."io.containerd.cri.v1.runtime".containerd.runtimes]
    # crun: https://github.com/containers/crun
    [plugins."io.containerd.cri.v1.runtime".containerd.runtimes.crun]
      runtime_type = "io.containerd.runc.v2"
      [plugins."io.containerd.cri.v1.runtime".containerd.runtimes.crun.options]
        BinaryName = "/usr/local/bin/crun"
    # gVisor: https://gvisor.dev/
    [plugins."io.containerd.cri.v1.runtime".containerd.runtimes.gvisor]
      runtime_type = "io.containerd.runsc.v1"
    # Kata Containers: https://katacontainers.io/
    [plugins."io.containerd.cri.v1.runtime".containerd.runtimes.kata]
      runtime_type = "io.containerd.kata.v2"
EOF
) | tee ./artifacts/custom-rc.toml.tmpl

# setup the kind runtimeClass for each
( cat <<EOF
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: runc
handler: runc
---
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: crun
handler: crun
---
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: gvisor
handler: gvisor
---
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: kata
handler: kata
---
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: youki
handler: youki
---
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: wasmtime
handler: wasmtime
---
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: wasmedge
handler: wasmedge
EOF
) | ./k3s kubectl apply -f -

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
    # ANODA="/home/asari/Downloads/kjxh-artifacts/another/ssh-rootfs-revised_0.3.3.cpio.gz"
    # ANODA="/home/asari/Downloads/kjxh-artifacts/another/rootfs_v5.cpio.gz"
    # ANODA="/home/asari/Downloads/kjxh-artifacts/another/rootfs_v6.cpio.gz"
    # ANODA="/home/asari/Downloads/kjxh-artifacts/another/rootfs_v7.cpio.gz"
    # ANODA="/home/asari/Downloads/kjxh-artifacts/another/rootfs_v8.cpio.gz"
    # ANODA="/home/asari/Downloads/kjxh-artifacts/another/rootfs_v9.cpio.gz"
    # ANODA="/home/asari/Downloads/kjxh-artifacts/another/rootfs_v10.cpio.gz"
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

save_registry() {
# function that saves the registry for
# containerd

podman pull docker://registry:3.0

REG_NAME=$(podman images | grep registry | awk '{print $3}')
TARBALL_ARTIFACT="/tmp/skopeo-convert-registry.oci.tar"

# This creates a docker-save tarball bundle
# podman save -o ./artifacts/oci-registry-tarball.tar "$REG_NAME"

# Check the contents
# tar tf ./artifacts/oci-registry-tarball.tar | head

# convert the docker-save tarball bundle to OCI spec so it can
mkdir -p ./skopeo-test
## idempotent
# skopeo copy containers-storage:localhost:5000/registry:3.0 dir:$PWD/skopeo-test/
skopeo copy containers-storage:localhost:5000/registry:3.0 oci:$PWD/skopeo-test:3.0

# inspect with umoci
# umoci unpack --image /tmp/oci-layout:myimage /tmp/umoci-rootfs

# list output contents
ls -allhtr ./skopeo-test/

# create tarball
# tar -C /tmp/oci-registry-tarball -cf /tmp/registry.oci.tar .
# tar -cf "$TARBALL_ARTIFACT" "$PWD/skopeo-test/"
tar -C ./skopeo-test -cf "$TARBALL_ARTIFACT" .


rm -rf ./skopeo-test

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

airgap_k3s() {

    # setup bridge
    /bin/sh ./scripts/sandbox/net-qemu_myifup.sh fallin

    printf "\n=========\nSetting up the bridge...\n============\n\n"

    # generate a macaddr
    random_mac

    if ! [ -f ./utils/storage/k3s-tarball-squashfs.img ]; then
        squash_k3s
    fi

    # ANODA is the initramfs.cpio.gz that serves temporarily as a rootfs
    #
    # this one enables cgroupsv2 only, without cgroupsv1
    # ANODA="/home/asari/Downloads/kjxh-artifacts/another/rootfs_v13.cpio.gz"

    # this one have containerd dynamically linked against musl
    #ANODA="/home/asari/Downloads/kjxh-artifacts/another/rootfs_v14.cpio.gz"

    # this one have fuse-overlayfs
    # ANODA="/home/asari/Downloads/kjxh-artifacts/another/rootfs_v15.cpio.gz"
    #
    # this one have bpftrace
    # ANODA="/home/asari/Downloads/kjxh-artifacts/another/rootfs_v16.cpio.gz"
    # ANODA="/home/asari/Downloads/kjxh-artifacts/another/rootfs_v18.cpio.gz"
    # ANODA="/home/asari/Downloads/kjxh-artifacts/another/rootfs_v19.cpio.gz"
    # ANODA="/home/asari/Downloads/kjxh-artifacts/another/rootfs_v20.cpio.gz"
    # ANODA="/home/asari/Downloads/kjxh-artifacts/another/rootfs_v21.cpio.gz"
    # ANODA="/home/asari/Downloads/kjxh-artifacts/another/rootfs_v22.cpio.gz"
    # ANODA="/home/asari/Downloads/kjxh-artifacts/another/rootfs_v23.cpio.gz"
    # ANODA="/home/asari/Downloads/kjxh-artifacts/another/rootfs_v24.cpio.gz"
    ANODA="/home/asari/Downloads/kjxh-artifacts/another/rootfs_v25.cpio.gz"


    # PS: this kernel image needs to have squashfs support.
    #KERNEL_IMAGE="./artifacts/bzImage"
    #KERNEL_IMG="$HOME/Downloads/kjxh-artifacts/bzImage"
    #MEMCG_KERNEL_IMG="$HOME/Downloads/kjxh-artifacts/2_memcg-kernel/bzImage"
    #OVERLAYFS_KERNEL_IMG="$HOME/Downloads/kjxh-artifacts/3_overlay_support/bzImage"
    # OVERLAY_KO="$HOME/Downloads/kjxh-artifacts/3_overlay_support/bzImage"

    # OVERLAY_CONFIGZ_KO="$HOME/Downloads/kjxh-artifacts/4_bzImage_kos/bzImage"
    # NETBZ="$HOME/Downloads/kjxh-artifacts/5_last-k3s/bzImage"
    # MISSING="$HOME/Downloads/kjxh-artifacts/7_missing/bzImage"
    # ORDERED="$HOME/Downloads/kjxh-artifacts/8_ordered/bzImage"
    # ORDERED="./assets/module_kernel_build/lfs/lib/modules/6.6.22/build/arch/x86/boot/bzImage"
    TIDY="$HOME/Downloads/kjxh-artifacts/9_tidying/bzImage"

    qemu-system-x86_64 \
        -kernel "$TIDY" \
        -initrd "$ANODA" \
        -enable-kvm \
        -m 3072 \
        -append 'console=ttyS0 root=/dev/sda earlyprintk net.ifnames=0 cgroup_no_v1=all' \
        -nographic \
        -no-reboot \
        -drive file="./utils/storage/eulab-hd",format=raw \
        -drive file="./utils/storage/k3s-tarball-squashfs.img",format=raw \
        -net nic,model=virtio,macaddr="$macaddr" \
        -net tap,helper=/usr/lib/qemu/qemu-bridge-helper,br=vmbr0
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

qemu-system-x86_64 \
    -m 1024 \
    -cdrom ./artifacts/kjx-headless.iso \
    -boot d \
    -enable-kvm \
    -nographic \
    -no-reboot \
    -cpu host \
    -serial mon:stdio
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
if [ "$1" = "firstver" ]; then
    firstver
elif [ "$1" = "macaddr" ]; then
    macaddr
elif [ "$1" = "thirdver" ] || [ "$1" = "-t" ] || [ "$1" = "--thirdver" ] ; then
    thirdver
elif [ "$1" = "dropbear" ] || [ "$1" = "-d" ] || [ "$1" = "--dropbear" ] ; then
    dropbear
elif [ "$1" = "kjx" ]; then
    kjx
elif [ "$1" = "--airgap" ] || [ "$1" = "-ag" ] || [ "$1" = "-airgap" ] ; then
    airgap_k3s
elif [ "$1" = "--squash" ] || [ "$1" = "-sq" ] || [ "$1" = "-sq" ] || [ "$1" = "-squash" ]; then
    squash_k3s
elif [ "$1" = "--runiso" ] || [ "$1" = "-runiso" ] || [ "$1" = "runiso" ] ; then
    runiso
elif [ "$1" = "help" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    print_usage
elif [ "$1" = "debug" ]; then
    debug
else
    echo "Invalid function name. Please specify one of: function1, function2, function3"
    print_usage
fi

