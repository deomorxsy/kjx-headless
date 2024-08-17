#!/bin/sh
#
# from https://github.com/deomorxsy/eulab-poc/blob/main/scripts/qemu-myifup.sh
#
# allow all instead. virtbr0 is an arbitrary name for the virtual bridge
#echo "allow vmbr0" | sudo tee "/etc/qemu/${USER}.conf"
#echo "include /etc/qemu/${USER}.conf" | sudo tee --append "/etc/qemu/bridge.conf"

bridge() {
# permit user to use the bridge to run rootless QEMU
chmod +s  /usr/lib/qemu/qemu-bridge-helper

# create the network bridge, deprecated brctl
#brctl addbr vmbr0
#brctl addif vmbr0 enp3s0

# create bridge, set NIC as part of bridge,
# assign IP with CIDR subnet, bring up the bridge
ip link add name vmbr0 type bridge
ip link set enp4s0 master vmbr0
ip addr add "192.168.0.20/24" dev vmbr0
ip link set dev vmbr0 up
}
# bring back connection to the host
#ip link set enp4s0 nomaster
#ip link set enp4s0 master vmbr0


