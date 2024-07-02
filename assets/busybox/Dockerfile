ARG GIT_CONTAINERFILE_HASH=${GIT_COMPOSE_SHA}

FROM busybox:1.36.1-musl as builder
# just to get the statically compiled files


FROM alpine:3.18 as relay

ARG GIT_CONTAINERFILE_HASH
ENV GIT_CONTAINERFILE_HASH=${GIT_COMPOSE_SHA}

WORKDIR /ramdisk/
RUN mkdir -p bin dev etc lib mnt/root proc root sbin sys tmp var
COPY --from=builder / .
#RUN ln -s /bin/busybox ./linuxrc
RUN <<"EOF"
cp ./utils/busybox/busybox-1.36.1/busybox ./ramdisk/
for binary in $(./ramdisk/busybox --list); do
    ln -s /bin/busybox ./ramdisk/sbin/"$binary"
    ln -s /bin/busybox ./ramdisk/usr/bin/"$binary"
    ln -s /bin/busybox ./ramdisk/usr/sbin/"$binary"
done
EOF

RUN cat > ./init <<"INIT_EOF"
#!/bin/busybox sh

# mount filesystems
mount -t devtmpfs   devtmpfs    /dev
mount -t proc       none        /proc
mount -t sysfs      none       /sys
mount -t tmpfs      tmpfs       /tmp

# mount tracefs and securityfs pseudo-filesystems
mount -t tracefs tracefs /sys/kernel/tracing/
mount -t debugfs debugfs /sys/kernel/debug/
mount -t securityfs securityfs /sys/kernel/security/
EOF && \
#
#
#
# set up hostname
echo "kjx" > /etc/hostname && hostname -F /etc/hostname

# bring up the connection
/sbin/ip link set lo up                         # bring up loopback interface
/sbin/ip link set eth0 up                       # bring up ethernet interface
/sbin/ip addr add 192.168.0.27 eth0             # static ipv4 assignment

# alternate method, built-in inside busybox
#udhcpc -i eth0 # dynamic ipv4 assignment

# ================================


sysctl -w kernel.printk="2 4 1 7"

# sets up BRK keyboard
setxkbmap -model abnt2 -layout br -variant abnt2
echo && echo

# get rootfs UUID from kernel parameters on /proc/cmdline
ROOTFS=$(cat /proc/cmdline | awk -F= 'NR==1 {print $4}' | awk '{print $1}')
exec /bin/busybox switch_root -c /dev/console $ROOTFS /usr/bin/init

current_commit_hash = subprocess.run(["git", "rev-parse", "--short", "HEAD"], stdout=subprocess.PIPE, text=True)
current_commit_hash = current_commit_hash.stdout.strip()
print ("\033[93;1;4mCurrent Commit Hash    : " + current_commit_hash + "\033[0m")

cat << 'asciiart'
 .-"``"-.
/  _.-` (_) `-._
\   (_.----._)  /
 \     /    \  /
  `\  \____/  /`
    `-.____.-`      __     _
     /      \      / /__  (_)_ __
    /        \    /  '_/ / /\ \ /
   /_ |  | _\    /_/\_\_/ //_\_\
     |  | |          |___/         deomorxsy/kjx
     |__|__|  ----------------------------------------------
     /_ | _\   Reboot (01.00.0, ${GIT_CONTAINERFILE_HASH})
              ----------------------------------------------
asciiart

# get a shell
sh

asciiart

printf "Boot took $(cut -d' ' -f1 /proc/uptime) seconds btw\n"

# get a shell
sh
INIT_EOF

# ======== NETWORK SETUP ===========


# system hostname
RUN cat > /etc/hosts <<"EOF"
127.0.0.1       localhost
127.0.1.1       $(hostname).localdomain $(hostname)
::1             localhost ipv6-localhost ipv6-loopback
fe00::0         ipv6-localnet
ff00::0         ipv6-mcastprefix
ff02::1         ipv6-allnodes
ff02::2         ipv6-allrouters
ff02::3         ipv6-allhosts
EOF

# DNS setup
RUN cat > /etc/resolv.conf <<"EOF"
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF

# interfaces (network devices)
RUN cat > /etc/network/interfaces <<"EOF"
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


FROM alpine:3.18 as packer

WORKDIR /app/

COPY --from=relay /ramdisk/ /app/ramdisk/

RUN chmod +x ./ramdisk/init && \
    cd ./ramdisk || return && \
    find . -print0 | busybox cpio --null -ov --format=newc | gzip -9 > ../initramfs.cpio.gz && \
    cd - || return


#FROM scratch as empty
FROM alpine:3.18 as empty

COPY --from=packer /app/initramfs.cpio.gz .

ENTRYPOINT ["/bin/sh"]
