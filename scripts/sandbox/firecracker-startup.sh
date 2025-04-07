#!/bin/sh

fire_up() {

if [ -z "$(ls -l ./assets/firecracker)" ]; then
    git clone https://github.com/firecracker-microvm/firecracker ./assets
    cd firecracker || return
    tools/devtool build
    toolchain="$(uname -m)-unknown-linux-musl"

    cd - || return
fi
}

net_fire() {
    # this is run at startup once
    sudo ip tuntap add dev ftap0 mode tap && \
        sudo ip addr add 192.168.0.1/24 dev ftap0 && \
        sudo ip link set ftap0 up && \
        ip addr show dev ftap0

}

runsv_service() {
mkdir -p /etc/runit/sv/firecracker

cat <<"EOF" > /etc/runit/sv/firecracker/fire-up.sh
#!/bin/sh

firecracker -p
EOF

ln -s /etc/runit/sv/firecracker/fck-up.sh /run/runit/service/
}


# on submitting jobs to firecracker
submit_fire() {

    # submit kernel, macvlan
curl --unix-socket /tmp/firecracker.socket -i \
      -X PUT 'http://localhost/boot-source'   \
      -H 'Accept: application/json'           \
      -H 'Content-Type: application/json'     \
      -d "{
            \"kernel_image_path\": \"./artifacts/bzImage\",
            \"boot_args\": \"console=ttyS0 reboot=k panic=1 pci=off init=/init ip=172.16.0.2::172.16.0.1:255.255.255.0::eth0:off\"
       }"

# Configure memory and vCPUs
sudo curl --unix-socket /tmp/firecracker.socket -i \
    -X PUT 'http://localhost/machine-config' \
    -H 'Accept: application/json'           \
    -H 'Content-Type: application/json'     \
    -d '{
        "vcpu_count": 2,
        "mem_size_mib": 256
    }'

# configure network device
sudo curl -X put \
    --unix-socket /tmp/firecracker.socket \
    'http://localhost:network-interfaces/eth0' \
    -H accept:application/json \
    -H content-type:application/json \
    -d '{
        "iface_id": "eth0",
        "host_dev_name": "ftap0"
        }'

# the first drive should look to the rootfs image
sudo curl --unix-socket /tmp/firecracker.socket -i  \
    -X PUT 'http://localhost:actions'               \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -d "{ \
            \"drive_id\": \"./rootfs.img\",
            \"path_on_host\": \"./rootfs.img\",
            \"is_root_device\": true,
            \"is_read_only\": false
    }"

# boot the vm
sudo curl --unix-socket /tmp/firecracker.socket -i \
    -X PUT 'http://localhost:actions' \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -d '{
        "action_type": "InstanceStart"
    }'
}
