ARG GIT_CONTAINERFILE_HASH=${GIT_COMPOSE_SHA}

# FROM busybox:1.36.1-musl as builder
FROM busybox:1.37.0-musl as builder
# just to get the statically compiled files


FROM alpine:3.22 as relay

ARG GIT_CONTAINERFILE_HASH
ENV GIT_CONTAINERFILE_HASH=${GIT_COMPOSE_SHA}

ENV DROPBEAR_VERSION="dropbear-2025.88"
ARG DROPBEAR_VERSION="dropbear-2025.88"

WORKDIR /ramdisk/
RUN mkdir -p bin dev etc lib mnt/root proc root sbin sys tmp var
# ======== NETWORK SETUP ===========
# system hostname
RUN <<BUILD_EOF
(
cat <<EOF
127.0.0.1       localhost
127.0.1.1       $(hostname).localdomain $(hostname)
::1             localhost ipv6-localhost ipv6-loopback
fe00::0         ipv6-localnet
ff00::0         ipv6-mcastprefix
ff02::1         ipv6-allnodes
ff02::2         ipv6-allrouters
ff02::3         ipv6-allhosts
EOF
) | tee  /ramdisk/etc/hosts
BUILD_EOF

#
# DNS setup
RUN <<BUILD_EOF
(
cat  <<EOF
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF
) | tee /ramdisk/etc/resolv.conf

BUILD_EOF


# interfaces (network devices)
RUN <<BUILD_EOF

mkdir -p /ramdisk/etc/network/

(
cat  <<EOF
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
) | tee /ramdisk/etc/network/interfaces
#
BUILD_EOF

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

# Mount filesystems
mount -t devtmpfs   devtmpfs    /dev
mount -t proc       proc        /proc
mount -t sysfs      sysfs       /sys
mount -t tmpfs      tmpfs       /tmp
mount -t tmpfs      tmpfs       /run

# Mount pts for dynamic management of
# the /dev directory using devtmpfs + mdev
mkdir /dev/pts
mount -t devpts devpts /dev/pts


# Mount tracefs and securityfs pseudo-filesystems
mount -t tracefs tracefs /sys/kernel/tracing/
mount -t debugfs debugfs /sys/kernel/debug/
mount -t securityfs securityfs /sys/kernel/security/

# Setup cgroupv1 config
# mount cgroupfs to enable oci/cri based containers
# mount -t tmpfs cgroup_root /sys/fs/cgroup
# mkdir -p /sys/fs/cgroup/cpuset
# mount -t cgroup -ocpuset cpuset /sys/fs/cgroup/cpuset

# Setup cgroupv2 config
# mount -t cgroup2 cgroup2 /sys/fs/cgroup

mount -t cgroup2 -o rw,nosuid,nodev,noexec,relatime,nsdelegate,memory_recursiveprot cgroup2 /sys/fs/cgroup

# mount -t cgroup2 -o nsdelegate,cpuset,cpu,memory,io,hugetlb,pids,rdma,misc cgroup2 /sys/fs/cgroup
echo "+cpu +memory -io" > /sys/fs/cgroup/cgroup.subtree_control

#cat c

# INIT_EOF && \
#
#
#
# set up hostname
echo "kjx" > /etc/hostname && hostname -F /etc/hostname

# bring up the connection
/bin/ip link set lo up                         # bring up loopback interface
/bin/ip link set eth0 up                       # bring up ethernet interface
/bin/ip addr add 192.168.0.27 eth0             # static ipv4 assignment

# alternate method, built-in inside busybox
#udhcpc -i eth0 # dynamic ipv4 assignment


# now configure the default route for k3s

# only for QEMU user-mode networking:
# ifconfig eth0 10.0.2.15
# route add default gw 10.0.2.2

# ============

ip link set lo up
ip link set eth0 up

ip addr del 192.168.0.27/24 dev eth0  # if needed
ip addr add 192.168.0.27/24 dev eth0

ip route del default            # delete the existing one
ip route add default via 192.168.0.20







# mount -t cgroup2 cgroup2 /sys/fs/cgroup
# echo "+cpu +memory -io" > /sys/fs/cgroup/cgroup.subtree_control
# echo "+cpu +memory -io" | tee /sys/fs/cgroup/cgroup.subtree_control
# k3s server --disable-agent --default-runtime=runsc & > /dev/null 2>&1

# ================================


sysctl -w kernel.printk="3 4 1 7"


/bin/ln -sf /sbin/mke2fs /sbin/mkfs.ext4
/bin/ln -sf /sbin/mke2fs /sbin/mkfs.ext3
/bin/ln -sf /sbin/mke2fs /sbin/mkfs.ext2


# sets up BRK keyboard
#setxkbmap -model abnt2 -layout br -variant abnt2
echo && echo

# get rootfs UUID from kernel parameters on /proc/cmdline
# ROOTFS=$(cat /proc/cmdline | awk -F= 'NR==1 {print $4}' | awk '{print $1}')
# exec /bin/busybox switch_root -c /dev/console $ROOTFS /usr/bin/init

# current_commit_hash = subprocess.run(["git", "rev-parse", "--short", "HEAD"], stdout=subprocess.PIPE, text=True)
# current_commit_hash = current_commit_hash.stdout.strip()
# print ("\033[93;1;4mCurrent Commit Hash    : " + current_commit_hash + "\033[0m")

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


/bin/beetor

INIT_EOF
) | tee ./init

(
cat <<FUSECONF
# The file /etc/fuse.conf allows for the following parameters:
#
# user_allow_other - Using the allow_other mount option works fine as root, but
# in order to have it work as a regular user, you need to set user_allow_other
# in /etc/fuse.conf as well. This option allows non-root users to use the
# allow_other option. You need allow_other if you want users other than the
# owner of a mounted fuse to access it. This option must appear on a line by
# itself. There is no value; just the presence of the option activates it.

user_allow_other


# mount_max = n - this option sets the maximum number of mounts.
# It must be typed exactly as shown (with a single space before and after the
# equals sign).

#mount_max = 1000
FUSECONF
) | tee /etc/fuse.conf
#

EOF

FROM alpine:3.22 as sshbear

WORKDIR /app/

COPY ./deploy/isogen/rootfs/setup-dropbear.sh /app/scripts/setup-dropbear.sh

#COPY --from=relay /ramdisk/ /app/ramdisk/
RUN <<EOF

apk upgrade && apk update && \
    apk add musl-dev gcc make

ls -allhtr /app/scripts/

# if ! (. /app/scripts/setup-dropbear.sh); then
#     echo "|> Error: could not run [./deploy/isogen/rootfs/setup-dropbear.sh]. Exiting now..."
#     return 1
# fi
#     echo "|> Sucessfully ran [./deploy/isogen/rootfs/setup-dropbear.sh]. Proceeding..."
#
#
# ls -allhtr /app/artifacts/dropbear/

EOF

RUN <<EOF
DB_LINK="https://matt.ucc.asn.au/dropbear/releases/dropbear-2025.88.tar.bz2"
DB_TARBALL_BZADO="dropbear-2025.88.tar.bz2"
DB_TARBALL="dropbear-2025.88.tar"
DB_PATH="artifacts/dropbear"
DROPBEAR_VERSION="dropbear-2025.88"

mkdir -p /app/artifacts/dropbear/
    # fetch artifact and decompress tarball
    #mkdir -p "${DB_PATH:-[EMPTY_VARIABLE]}"

    #if ! (wget "${DB_LINK:-[EMPTY_VARIABLE]}" --directory-prefix="${DB_PATH:-[EMPTY_VARIABLE]}"); then
    if ! (wget "${DB_LINK:-[EMPTY_VARIABLE]}" --directory-prefix="/app/artifacts/dropbear/"); then
        echo "|> Error: could not fetch ${DB_TARBALL_BZADO:-[EMPTY_VARIABLE]} from the URL ${DB_LINK:-[EMPTY_VARIABLE]}. Exiting now..."
        return 1
    fi
    echo "|> Sucessfully fetched ${DB_TARBALL_BZADO:-[EMPTY_VARIABLE]} from the URL ${DB_LINK:-[EMPTY_VARIABLE]}. Proceeding..."

    #cd "${DB_PATH:-[EMPTY_VARIABLE]}" || return
    cd "/app/artifacts/dropbear/" || return

    if ! (cp "./${DB_TARBALL_BZADO:-[EMPTY_VARIABLE]}" "./v2_${DB_TARBALL_BZADO:-[EMPTY_VARIABLE]}"); then
        echo "|> Error: it was not possible to copy the DB_TARBALL_BZADO into a v2 backup. Exiting now..."
        return 1
    fi
    echo "|> Sucessfully copied the DB_TARBALL_BZADO into a v2 backup. Proceding..."

    if ! (bzip2 -d "./${DB_TARBALL_BZADO:-[EMPTY_VARIABLE]}"); then
        echo "|> Error: could not decompress the bzip2 file at [DB_TARBALL_BZADO=${DB_TARBALL_BZADO}]. Exiting now..."
        return 1
    fi
    echo "|> Sucessfully decompressed the bzip2 file at [DB_TARBALL_BZADO=${DB_TARBALL_BZADO}]. Proceeding..."

    if ! (tar -xvf "${DB_TARBALL:-[EMPTY_VARIABLE]}"); then
        echo "|> Error: could not decompress the tarball at [${DB_TARBALL:-[EMPTY_VARIABLE]}]. Exiting now..."
        return 1
    fi
    echo "|> Sucessfully decompressed the tarball at [${DB_TARBALL:-[EMPTY_VARIABLE]}]. Proceeding..."

    echo "=========="
    echo "|> Dropbear tarball extracted with success."
    echo "=========="

    cd - || return

EOF

RUN <<EOF

DB_LINK="https://matt.ucc.asn.au/dropbear/releases/dropbear-2025.88.tar.bz2"
DB_TARBALL_BZADO="dropbear-2025.88.tar.bz2"
DB_TARBALL="dropbear-2025.88.tar"
DB_PATH="artifacts/dropbear"
DROPBEAR_VERSION="dropbear-2025.88"


cd /app/artifacts/dropbear/${DROPBEAR_VERSION:-[EMPTY_VARIABLE]} || return

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
    ln -s ./dropbearmulti "$HOME/app/artifacts/dropbear-multi/dropbear"
    ln -s ./dropbearmulti "$HOME/app/artifacts/dropbear-multi/dropbearkey"
    ln -s ./dropbearmulti "$HOME/app/artifacts/dropbear-multi/dropbearconvert"
    ln -s ./dropbearmulti "$HOME/app/artifacts/dropbear-multi/scp"
    ln -s ./dropbearmulti "$HOME/app/artifacts/dropbear-multi/dbclient"

cd - || return

EOF


FROM alpine:3.22 as packer


WORKDIR /app/dropbear/

#COPY --from=sshbear /home/rkd/app/artifacts/dropbear/dropbear-2025.87/dropbearmulti .
# COPY --from=sshbear /app/artifacts/dropbear/dropbear-2025.87/dropbearmulti .
# COPY --from=sshbear /app/artifacts/dropbear/dropbear-2025.88/dropbearmulti .
ENV DROPBEAR_VERSION="dropbear-2025.88"
ARG DROPBEAR_VERSION="dropbear-2025.88"

COPY --from=sshbear /app/artifacts/dropbear/${DROPBEAR_VERSION}/dropbearmulti .


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
FROM alpine:3.22 as empty

COPY --from=packer /app/rootfs-with-ssh.cpio.gz .

RUN echo "done!!!"

ENTRYPOINT ["/bin/sh"]
