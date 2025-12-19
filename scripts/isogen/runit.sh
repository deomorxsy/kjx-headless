#!/bin/sh

_main() {
    docker compose -f ./compose.yml create runit
    mkdir -p ./artifacts/runitsv &&
        docker cp runit:/app/runit.tar.gz ./artifacts/runitsv/ &&
        chmod -c +rX ./artifacts/runitsv/beetor
    docker stop registry

}

itarun() {

    # runit_step() {
    # =============================

    if ! (

        (
            cat <<"EOF"
#!/bin/sh
#
exec /sbin/getty 38400 tty1


EOF
        ) | tee "$ROOTFS_PATH/etc/sv/getty-tty1/run"
    ); then
        echo "|> Error: could not write to $ROOTFS_PATH/etc/sv/getty-tty1/run filepath. Exiting now..."
        echo && echo
        return 1
    fi

    # alter the file mode bit of the run script for getty
    if ! chmod +x "$ROOTFS_PATH/etc/sv/getty-tty1/run"; then
        echo "|> Error: could not alter the file mode bits of the given $ROOTFS_PATH/etc/sv/getty-tty1/run filepath. Exiting now..."
        return 1
    fi
    echo "|> Altered the file mode bits of the given $ROOTFS_PATH/etc/sv/getty-tty1/run filepath. Proceeding..."
    echo && echo

    # ============================

    if ! ( (
        cat <<"INIT_EOF"
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
# /bin/libkjx_runqlat

INIT_EOF
    ) | tee "$ROOTFS_PATH/etc/runit/1"); then
        echo "|> Error: it was not possible to pipe the bootscript to $ROOTFS_PATH/etc/runit/1 filepath. Exiting now..."
        echo && echo
        return 1
    fi
    echo "|> Bootscript piped with success to $ROOTFS_PATH/etc/runit/1 filepath. Proceeding..."

    if ! chmod +x "$ROOTFS_PATH/etc/runit/1"; then
        echo "|> Error: it was not possible to change the file bits of $ROOTFS_PATH/etc/runit/1 filepath. Exiting now..."
        return 1
    fi
    echo "|> Changed the file bits of $ROOTFS_PATH/etc/runit/1 filepath. Proceeding..."

    # sudo ln -sf "$ISO_DIR"/rootfs/etc/runit/1 "$ISO_DIR"/rootfs/sbin/init
    if ! ln -sf "$ROOTFS_PATH/etc/runit/1" "$ROOTFS_PATH/sbin/init"; then
        echo "|> Error: could not create a symlink (soft link) of $ROOTFS_PATH/etc/runit/1 at the $ROOTFS_PATH/sbin/init filepath. Exiting now..."
        echo && echo
        return 1
    fi
    echo "|> Create a symlink (soft link) of $ROOTFS_PATH/etc/runit/1 at the $ROOTFS_PATH/sbin/init filepath. Proceeding..."
    #}

    #runit_symlinks() {
    # this bootstraps the set_sandboxes function inside runit, as well as any hotfixes needed
    # from the previous mksquashfs (deep copy) followed by cp (shallow copy) steps.

    # setup runit to start the C program to control both k3s and the tracer at startup
    mkdir -p "$ROOTFS_PATH"/etc/sv/clusterbuild/

    if ! ( (
        cat <<BEETOR_EOF
#!/bin/sh

#exec /usr/bin/cpuram_task


mkdir -p /app/piest.yaml
(
cat <<PIEST
apiVersion: v1
kind: Pod
metadata:
  name: pi
  namespace: kjx
spec:
  runtimeClassName: runc  # Change to crun or runsc in different tests
  containers:
  - name: pi
    image: busybox
    command: ["sh", "-c", "awk 'BEGIN { for(i=1;i<10000;i+=2) s+=4*((i%4==1)?1:-1)/i; print s }'"]
    resources:
      limits:
        memory: "32Mi"
        cpu: "100m"
  restartPolicy: Never

PIEST
 ) | tee ./app/piest.yaml


# Orchestrator script
exec /usr/bin/bwcoff
# -> calls k3s with Pi approximation workload (tracee
#    |
#    --> calls /app/piest.yaml to get the manifest
#
# -> calls Ftrace/libbpf CO-RE (tracers)

# prepare run directory for containerd and k3s
mkdir -p /run /var/run
mount -t tmpfs tmpfs /run
ln -s /run /var/ 2>/dev/null

mkdir -p /run/k3s/containerd
mkdir -p /var/lib/rancher/k3s
mkdir -p /etc/rancher/k3s

# Unsquash the squashfs with the airgap images inside
mkdir -p /mnt/airgap-registry-image/
mkdir -p /mnt/k3s-squashfs

mount /dev/sdb /mnt/airgap-registry-image/

cd /mnt/airgap-registry-image || return

ls -allhtr /mnt/airgap-registry-image

unsquashfs -d ../k3s-squashfs/ ./k3s-tarball.squashfs

cd - || return

# Bring network up
ip link set lo up


ln -s /run/containerd/containerd.sock /run/k3s/containerd/
containerd &

mkdir -p /app


ls -allhtr

(
cat <<TRACEE_EOF
#!/bin/sh

unshare --fork --pid --mount-proc --uts --net --ipc '
k3s server --disable-agent --default-runtime=runc & > /dev/null 2>&1

# works now
k3s ctr namespace list

# create namespace and import the airgap tarball

k3s kubectl create namespace pia
k3s ctr -n=pia images import /mnt/k3s-squashfs/k3s-airgap-images-amd64.tar

# kubectl apply manifest
# manifest references image inside the localhost registry
# pull from registry on localhost
'
TRACEE_EOF
) | tee /app/tracee_unshared.sh

chmod +x /app/tracee_unshared.sh

mkdir -p /sys/fs/cgroup/k3s-tracee/
echo $$ > /sys/fs/cgroup/k3s-tracee/cgroup.procs
/app/tracee_unshared.sh



exec /usr/bin/beetor

BEETOR_EOF
    ) | tee "$ROOTFS_PATH/etc/sv/clusterbuild/run"); then
        echo "|> Error: could not setup runit to start the C program to control both k3s and the tracer at startup. Exiting now..."
        echo && echo
        return 1
    fi
    echo "|> Setup runit to start the C program to control both k3s and the tracer at startup with success. Proceeding..."
    echo && echo

    if ! chmod +x "$ROOTFS_PATH/etc/sv/clusterbuild/run"; then
        echo "|> Error: could not alter the file mode bits of the given $ROOTFS_PATH/etc/sv/clusterbuild/run filepath. Exiting now..."
        return 1
    fi
    echo "|> Altered the file mode bits of the given $ROOTFS_PATH/etc/sv/clusterbuild/run filepath with success. Proceeding..."
    # this will be linked by the following steps

    # runtime link
    if ! (
        for item in "$ROOTFS_PATH/etc/sv/"*; do
            ln -sf "$item" "$ROOTFS_PATH/var/service/"
        done
    ); then
        echo "|> Error: could not traverse the loop over the files under $ROOTFS_PATH/etc/sv/* directory. Exiting now..."
        echo && echo
        return 1
    fi
    echo "|> Traversed the loop over the files under $ROOTFS_PATH/etc/sv/* directory with success. Proceeding..."
    echo && echo

    # runit: symbolic link convention
    if ! (
        for index in "$ROOTFS_PATH/etc/sv/"*; do
            ln -sf "$index" "$ROOTFS_PATH"/etc/runit/runsvdir/default/
        done
    ); then
        echo "|> Error: could not traverse the loop over the files under $ROOTFS_PATH/etc/sv/* directory to create default scripts to the runsvdir utility. Exiting now..."
        return 1
    fi
    echo "|> Traversed the loop over the files under $ROOTFS_PATH/etc/sv/* directory to create default scripts to the runsvdir utility with success. Exiting now..."

    # already done in a previous step
    #ln -sf "$ROOTFS_PATH"/etc/runit/1" "$ROOTFS_PATH"/sbin/init

    #}

}
