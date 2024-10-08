#!/bin/bash
#
random_mac() {
    printf -v macaddr "52:54:%02x:%02x:%02x:%02x" \
        $(( RANDOM & 0xff )) \
        $(( RANDOM & 0xff )) \
        $(( RANDOM & 0xff )) \
        $(( RANDOM & 0xff ))
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
    . ./scripts/sandbox/net-qemu_myifup.sh bridge
    printf "\n=========\nSetting up the bridge...\n============\n\n"

    # generate a macaddr
    random_mac

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

    # clean up bridge
    . ./scripts/sandbox/net-qemu_myifup.sh clean_bridge
    #echo runqemu1


    . ./scripts/sandbox/net-qemu_myifup.sh clean_cap
    #echo runqemu2
    #printf "\n=========\nCleaning now...\n============\n"

    #echo HMMMMMMMMM
}

# Check the argument passed from the command line
if [ "$1" == "firstver" ]; then
    firstver
elif [ "$1" == "macaddr" ]; then
    macaddr
elif [ "$1" == "thirdver" ]; then
    thirdver
elif [ "$1" == "kjx" ]; then
    kjx
elif [ "$1" == "debug" ]; then
    debug
else
    echo "Invalid function name. Please specify one of: function1, function2, function3"
fi
