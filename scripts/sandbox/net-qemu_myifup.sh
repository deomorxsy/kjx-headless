#!/bin/bash
#
# adapted from https://github.com/deomorxsy/eulab-poc/blob/main/scripts/qemu-myifup.sh
#
# allow all instead. virtbr0 is an arbitrary name for the virtual bridge
#echo "allow vmbr0" | sudo tee "/etc/qemu/${USER}.conf"
#echo "include /etc/qemu/${USER}.conf" | sudo tee --append "/etc/qemu/bridge.conf"

bridge() {

# always check busybox image first for the source location of the utilities.
printf "\n\n=====\n[bridge()] sudo setcap permission:\n"
sudo setcap 'cap_dac_override,cap_fowner+eip' /bin/chmod
#sudo setcap 'cap_dac_override,cap_net_admin,cap_net_raw+eip' /sbin/ip

# permit user to use the bridge to run rootless QEMU
chmod +s  /usr/lib/qemu/qemu-bridge-helper

# create the network bridge, deprecated brctl
#brctl addbr vmbr0
#brctl addif vmbr0 enp3s0

# create bridge, set NIC as part of bridge,
# assign IP with CIDR subnet, bring up the bridge
sudo /sbin/ip link add name vmbr0 type bridge
sudo /sbin/ip link set enp4s0 master vmbr0
sudo /sbin/ip addr add "192.168.0.20/24" dev vmbr0
sudo /sbin/ip link set dev vmbr0 up

#clean_bridge
#clean_cap
}
# bring back connection to the host
#ip link set enp4s0 nomaster
#ip link set enp4s0 master vmbr0

clean_bridge() {

# remove bridge

# 1. bring down the interface
sudo /sbin/ip link set dev vmbr0 down
# 2. remove IP with CIDR subnet from bridge network interface device
sudo /sbin/ip addr del "192.168.0.20/24" dev vmbr0
# 3. remove every master from NIC main network interface
sudo /sbin/ip link set enp4s0 nomaster
# 4. delete bridge
sudo /sbin/ip link delete vmbr0 type bridge

printf "\n=========\nCleaning bridge...\n============\n"
echo bridge-myifup
}

clean_cap() {
# cleanup capabilities
printf "\n\n=====\n[clean_cap()] sudo setcap permission:\n"
sudo setcap -r /bin/chmod
sudo setcap -r /sbin/ip

printf "\n=========\nCleaning capabilities...\n============\n"
echo cap-myifup
}


# Check the argument passed from the command line
if [ "$1" == "bridge" ]; then
    bridge
elif [ "$1" == "clean_bridge" ]; then
    clean_bridge
elif [ "$1" == "clean_cap" ]; then
    clean_cap
else
    echo "Invalid function name. Please specify one of: function1, function2, function3"
fi
