/bin/bash
#
random_mac() {
    printf -v macaddr "52:54:%02x:%02x:%02x:%02x" \
        $(( RANDOM & 0xff )) \
        $(( RANDOM & 0xff )) \
        $(( RANDOM & 0xff )) \
        $(( RANDOM & 0xff ))
}

thirdver() {
    # generate a macaddr
    random_mac

    qemu-system-x86_64 \
    -kernel ./artifacts/bzImage \
    -initrd ./artifacts/netpowered.cpio.gz \
    -enable-kvm \
    -m 1024 \
    -append 'console=ttyS0 root=/dev/sda earlyprintk net.ifnames=0' \
    -nographic \
    -no-reboot \
    -drive file="./utils/storage/eulab-hd",format=raw \
    -net nic,model=virtio,macaddr="$macaddr" \
    -net tap,helper=/usr/lib/qemu/qemu-bridge-helper,br=vmbr0
}

# Check the argument passed from the command line
if [ "$1" == "firstver" ]; then
    firstver
elif [ "$1" == "macaddr" ]; then
    macaddr
elif [ "$1" == "thirdver" ]; then
    thirdver
else
    echo "Invalid function name. Please specify one of: function1, function2, function3"
fi
