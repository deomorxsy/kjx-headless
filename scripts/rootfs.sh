#!/bin/sh
#
# ISO9660 image phase 8: rootfs script
#
LFS=/mnt/kjxh
#LFS_UUID=$()
LFS_UUID=/dev/sda1/
QCOW_FILE="./utils/storage/kjxh.qcow2"
rootfs_path=./artifacts/qcow2-rootfs/rootfs

packaging() {

printf "=============|> [STEP 8]: rootfs script \n============="

groupadd kjx
useradd -sR /bin/bash -g kjx -m -k /dev/null kjx

# get software
wget --input-file=./artifacts/wget-list-sysv.txt --continue --directory-prefix="$LFS/sources"
# =============================
# runit/runsv/runsvdir stup
mkdir -p "$rootfs_path/etc/runit"
mkdir -p "$rootfs_path/etc/runit/runsvdir/default"
mkdir -p "$rootfs_path/service"

# runit: symbolic link convention
ln -s "$rootfs_path/etc/runit/runsvdir/default/" "$rootfs_path/service/"

# runit: service scripts, get a shell
mkdir -p "$rootfs_path/etc/runit/runsvdir/default/getty-tty1"

cat <<EOF > "$rootfs_path/etc/runit/runsvdir/default/getty-tty1/run"
#!/bin/sh
#
exec /sbin/getty 38400 tty1
EOF
chmod +x "$rootfs_path/etc/runit/runsvdir/default/getty-tty1/run"

# runit: initialization
#cat <<EOF > rootfs/etc/runit/1


# ============================

RUN cat > ./rootfs/etc/runit/1 <<"INIT_EOF"
#!/bin/busybox sh

# redo mount filesystems
mount -t devtmpfs   devtmpfs    /dev
mount -t proc       none        /proc
mount -t sysfs      none       /sys
mount -t tmpfs      tmpfs       /tmp

# redo mount tracefs and securityfs pseudo-filesystems
mount -t tracefs tracefs /sys/kernel/tracing/
mount -t debugfs debugfs /sys/kernel/debug/
mount -t securityfs securityfs /sys/kernel/security/
EOF && \
#
#
#
# redo set up hostname
echo "kjx" > /etc/hostname && hostname -F /etc/hostname

# redo bring up the connection
/sbin/ip link set lo up                         # bring up loopback interface
/sbin/ip link set eth0 up                       # bring up ethernet interface
/sbin/ip addr add 192.168.0.27 eth0             # static ipv4 assignment

# redo alternate method, built-in inside busybox
#udhcpc -i eth0 # dynamic ipv4 assignment

# ================================

# sets up BRK keyboard
setxkbmap -model abnt2 -layout br -variant abnt2
echo && echo

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

printf "Uptime: $(cut -d' ' -f1 /proc/uptime) \n"
printf "System config: $(uname -a) \n"
## get a shell
#sh

exec /bin/busybox runsvdir /etc/runit/runsvdir/default

# load early bpf program
/bin/runqlat

INIT_EOF

chmod +x "$rootfs_path/etc/runit/1"

ln -sf "$rootfs_path/etc/runit/1" "$rootfs_path/sbin/init"

# setup sandbox (1 for each image)
. ./scripts/sandbox/firecracker-startup.sh
. ./scripts/sandbox/gvisor-startup.sh
. ./scripts/sandbox/kata-startup.sh
. ./scripts/sandbox/qemu-startup.sh
. ./scripts/sandbox/youki-startup.sh

}




# Alternative script ================
#
previous_packaging() {


groupadd kjx
useradd -sR /bin/bash -g kjx -m -k /dev/null kjx

# get software (libcap, k3s)
wget --input-file=wget-list-static.txt --continue --directory-prefix="$LFS/sources"

# start fakeroot
fakeroot
# apk-tools
cp -r ./artifacts/deps mount-point-fuse/bin
chmod +x ./mount-point-fuse/bin
ln -s ./artifacts/mount-point-fuse/bin/x mount-point-fuse/sbin/x

# soft links
sudo ln -s ./artifacts/mount-point-fuse/usr/local/bin/apk /sbin/apk
sudo ln -s ./artifacts/mount-point-fuse/usr/local/bin/apk /usr/bin/apk
sudo ln -s ./artifacts/mount-point-fuse/usr/local/bin/apk /usr/sbin/apk

. ./scripts/sandbox/firecracker-startup.sh
. ./scripts/sandbox/gvisor-startup.sh
. ./scripts/sandbox/kata-startup.sh
. ./scripts/sandbox/qemu-startup.sh
. ./scripts/sandbox/youki-startup.sh
#cp -r ./artifacts/deps/mount-point-fuse/
#exit # exit fakeroot
}

packaging
