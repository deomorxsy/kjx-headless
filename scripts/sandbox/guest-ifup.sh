#!/bin/sh
#
# on the guest os vm
#
# 1. statically via udhcpc
ip addr add "$(udhcpc 2>&1 | awk 'NR==4 {print $4}')" dev eth0
#
# 2. statically via iproute2
#/sbin/ip a add 192.168.0.27/24 dev "$1" DOES NOT WORK, USE UDHCPC
#
#
# 3. dinamically, just run udhcpc
# run these two before udhcpc if raising error:
#
# udhcpc: sendto: Network is down
# udhcpc: read error: Network is down, reopening socket

#/sbin/ip link set eth0 up
#/sbin/ip link set lo up
# udhcpc
#
# if enp4s0 is down on host, run:
#; sudo ip link set enp4s0 nomaster
#; ip link set enp4s0 master vmbr0

#setup network on guest vm
echo "eulab" > /etc/hostname
hostname -F /etc/hostname

# system hostname
cat << "EOF" > /etc/hosts
127.0.0.1       localhost
127.0.1.1       $(hostname).localdomain $(hostname)
::1             localhost ipv6-localhost ipv6-loopback
fe00::0         ipv6-localnet
ff00::0         ipv6-mcastprefix
ff02::1         ipv6-allnodes
ff02::2         ipv6-allrouters
ff02::3         ipv6-allhosts
EOF

# DNS
cat << "EOF" > /etc/resolv.conf
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF

# interfaces (network devices)
mkdir -p /etc/network/
cat << "EOF" > /etc/network/interfaces
# loopback interface
auto lo
iface lo inet loopback

# ethernet interface
auto eth0

# dynamic ipv4 assign with busybox udhcpc
# iface eth0 inet dhcp

# static ipv4 assign with iproute2
iface eth0 inet static
        address 192.168.1.150
        netmask 255.255.255.0
        gateway 192.168.1.1

iface eth0 inet6 static
        address 2001:470:ffff:ff::2
        netmask 64
        gateway 2001:470:ffff:ff::1
        pre-up echo 0 > /proc/sys/net/ipv6/conf/eth0/accept_ra
EOF

# bring up the connection
/sbin/ip link set eth0 up
/sbin/ip link set lo up
/sbin/ip addr add 192.168.0.27 eth0
