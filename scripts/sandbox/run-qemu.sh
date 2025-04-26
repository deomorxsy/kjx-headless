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
    qemu-system-x86_64 \
    -kernel ./artifacts/bzImage \
    -initrd ./artifacts/distro/mar.initramfs.cpio.gz \
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
    /bin/sh ./scripts/sandbox/net-qemu_myifup.sh bridge
    printf "\n=========\nSetting up the bridge...\n============\n\n"

    # generate a macaddr
    random_mac
    # "$HOME/Downloads/dropbear-image/rootfs-with-ssh.cpio.gz"
    # ./artifacts/distro/mar.initramfs.cpio.gz
    #  /home/asari/Downloads/initramfs/initramfs.cpio.gz
    qemu-system-x86_64 \
    -kernel ./artifacts/bzImage \
    -initrd "/home/asari/Downloads/dropbear-image/modified/ssh-rootfs-revised.cpio_0.2.1.gz" \
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


configure_vm_ssh() {

    ssh-keygen -t ed25519 -f ~/.ssh/qemu_vm_key -N ""

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
elif [ "$1" = "help" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    print_usage
elif [ "$1" = "debug" ]; then
    debug
else
    echo "Invalid function name. Please specify one of: function1, function2, function3"
    print_usage
fi

