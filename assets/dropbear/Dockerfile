ARG GIT_CONTAINERFILE_HASH=${GIT_COMPOSE_SHA}

FROM busybox:1.36.1-musl as builder
# just to get the statically compiled files


FROM alpine:3.20 as relay

ARG GIT_CONTAINERFILE_HASH
ENV GIT_CONTAINERFILE_HASH=${GIT_COMPOSE_SHA}

WORKDIR /ramdisk/
RUN mkdir -p bin dev etc lib mnt/root proc root sbin sys tmp var && \
# ======== NETWORK SETUP ===========
# system hostname
cat > /ramdisk/etc/hosts <<"EOF"
127.0.0.1       localhost
127.0.1.1       $(hostname).localdomain $(hostname)
::1             localhost ipv6-localhost ipv6-loopback
fe00::0         ipv6-localnet
ff00::0         ipv6-mcastprefix
ff02::1         ipv6-allnodes
ff02::2         ipv6-allrouters
ff02::3         ipv6-allhosts
EOF && \
#
# DNS setup
cat > /ramdisk/etc/resolv.conf <<"EOF"
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF && \
#
# interfaces (network devices)
RUN cat > /ramdisk/etc/network/interfaces <<"EOF"
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

RUN <<EOF

(
cat <<INIT_EOF
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
# INIT_EOF && \
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
#setxkbmap -model abnt2 -layout br -variant abnt2
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
) | tee ./init

EOF

FROM alpine:3.20 as sshbear

WORKDIR /app/

#COPY --from=relay /ramdisk/ /app/ramdisk/
RUN <<EOF

apk upgrade && apk update && \
    apk add musl-dev gcc make
# zig cc

# set variables
db_link="https://matt.ucc.asn.au/dropbear/dropbear-2025.87.tar.bz2"
db_tarball="dropbear-2025.87.tar.bz2"
db_path="./artifacts/dropbear"

# fetch artifact and decompress tarball
mkdir -p "$db_path"
wget "$db_link" --directory-prefix="$db_path"
cd "$db_path" || return
cp "./$db_tarball" "./v2_$db_tarball"
bzip2 -d "./$db_tarball" && \
    tar -xvf "./dropbear-2025.87.tar" && \
        printf "\n|> Dropbear tarball extracted with success.\n"
cd - || return

# configure and install binary
cd ./artifacts/dropbear/dropbear-2025.87 || return

# # set zig env
# export CC="zig cc"
# export CXX="zig c++"
# export CFLAGS="-target x86_64-linux-musl"
# export CXXFLAGS="-target x86_64-linux-musl"
# export LDFLAGS="-target x86_64-linux-musl"

# set gcc options for stripping unused code
LDFLAGS="$LDFLAGS -Wl,--gc-sections"
CFLAGS="$CFLAGS -ffunction-sections -fdata-sections"

# compile statically and disable zlib so it gets slim
./configure --prefix=/usr --enable-static --disable-zlib

# create the dropbear multi-binary
make PROGRAMS="dropbear dropbearkey dropbearconvert scp dbclient" MULTI=1

# setup symlinks for the multi-binary
# ln -s ./dropbearmulti "$HOME/app/artifacts/dropbear-multi/dropbear"
# ln -s ./dropbearmulti "$HOME/app/artifacts/dropbear-multi/dropbearkey"
# ln -s ./dropbearmulti "$HOME/app/artifacts/dropbear-multi/dropbearconvert"
# ln -s ./dropbearmulti "$HOME/app/artifacts/dropbear-multi/scp"
# ln -s ./dropbearmulti "$HOME/app/artifacts/dropbear-multi/dbclient"

#/home/rkd/app/artifacts/dropbear-multi/*

#mkdir -p /app/extract; tar -czf /app/extract/results.tar.gz /home/rkd/app/artifacts/dropbear-multi/*'

# if [ $(nproc) = "1" ]; then
# make -j$(nproc)
# else
# make -j$($(nproc)-1)
# fi
#
# mkdir -p /app/final/
#
# make install DESTDIR=/app/final/

# ======================
# # convert openssh to dropbear style public key
# dropbearconvert openssh dropbear ~/.ssh/id_rsa  ~/.ssh/id_rsa.db
# # associate hostname with the public key
# dbclient -i ~/.ssh/id_rsa.db <hostname>
# # create local dropbear key, then pipe the public key to an existing path
# ./dropbearkey -y -f ~/.ssh/id_ed25519 | grep "^ssh-" > ~/.ssh/id_ed25519.pub
# # generate server keys and then run the server
# ./dropbearkey -t ed25519 -f dropbear_ed25519_host_key
#

# ========================
EOF


FROM alpine:3.20 as packer


WORKDIR /app/dropbear/

#COPY --from=sshbear /home/rkd/app/artifacts/dropbear/dropbear-2025.87/dropbearmulti .
COPY --from=sshbear /app/artifacts/dropbear/dropbear-2025.87/dropbearmulti .


WORKDIR /app/ramdisk/
COPY --from=relay /ramdisk/ .

WORKDIR /app/dropbear/


RUN <<EOF

# check directories
ls -allhtr /app/
ls -allhtr /app/dropbear/
ls -allhtr /app/ramdisk/
ls -allhtr /app/ramdisk/init

EOF

RUN <<EOF

# setup symlinks for the multi-binary
ln -s "./dropbearmulti" "./dropbear"
ln -s "./dropbearmulti" "./dropbearkey"
ln -s "./dropbearmulti" "./dropbearconvert"
ln -s "./dropbearmulti" "./scp"
ln -s "./dropbearmulti" "./dbclient"

# change dropber to the ramdisk binaries directory
cp /app/dropbear/*  /app/ramdisk/bin/

# create cpio tarball with busybox and dropbear
chmod +x /app/ramdisk/init && \
    cd /app/ramdisk || return && \
    find . -print0 | busybox cpio --null -ov --format=newc | gzip -9 > ../rootfs-with-ssh.cpio.gz && \
    cd - || return

EOF

#FROM scratch as empty
FROM alpine:3.20 as empty

COPY --from=packer /app/rootfs-with-ssh.cpio.gz .

RUN echo "done!!!"

ENTRYPOINT ["/bin/sh"]
