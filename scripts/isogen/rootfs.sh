#!/bin/busybox sh

builder() {
    # prepare registry
    if ! docker run -d -p 5000:5000 --name registry registry:3.0; then
        return 1
    fi

    # env git_hash env goes into the compose.yml
    # invoke compose to build the dropbear target which will become the root filesystem (rootfs)
    if ! docker compose -f ./compose.yml --progress=plain build dropbear; then
        return 1
    fi

    # push the built image into the localhost:5000
    if ! docker push localhost:5000/dropbear:latest; then
        return 1
    fi
    #podman build -t initramfs:latest -f ./utils/busybox/Dockerfile

    # Retrieve artifact from docker image
    if ! docker run -it --name dropbear -d localhost:5000/dropbear:latest; then
        return 1
    fi

    # Copy the rootfs into artifacts
    mkdir -p ./artifacts/isogen/
    if ! docker cp dropbear:./rootfs-with-ssh.cpio.gz ./artifacts/isogen/rootfs-with-ssh.cpio.gz; then
        return 1
    fi

}

_start() {

    ASCII_DATE="$(date | awk '{print $1"-"$2"-"$3"-"$4"_"$5}' | tr ":" "-")"

    ISO_DIR="./artifacts/burn"
    #RAMDISK_PATH="/home/asari/Downloads/kjxh-artifacts/another/rootfs_v28.cpio.gz"
    ISODIR_RAMDISK_PATH="./artifacts/packages/initramfs_${ASCII_DATE:-[EMPTY_VARIABLE]}.cpio.gz"
    ISODIR_ROOTFS_PATH="./artifacts/burn/rootfs"
    ISODIR_ROOTFS_CPIO_GZ="./artifacts/burn/rootfs/rootfs-with-ssh.cpio.gz"

    ASCII_DATE="$(date | awk '{print $1"-"$2"-"$3"-"$4"_"$5}' | tr ":" "-")"
    ISO_DIR="./artifacts/burn"
    #RAMDISK_PATH="/home/asari/Downloads/kjxh-artifacts/another/rootfs_v28.cpio.gz"
    ISODIR_RAMDISK_PATH="./artifacts/packages/initramfs_${ASCII_DATE:-[EMPTY_VARIABLE]}.cpio.gz"
    ISODIR_ROOTFS_PATH="./artifacts/burn/rootfs"
    ISODIR_ROOTFS_CPIO_GZ="./artifacts/burn/rootfs/rootfs-with-ssh.cpio.gz"

    if ! (
        (
            cat <<"INIT_EOF"
#!/bin/busybox sh
    # redo mount filesystems
    if ! (mount -t devtmpfs devtmpfs /dev); then
        echo "|> Error: could not mount devtmpfs at ROOTFS/dev";
        return 1
    fi

    if ! (mount -t proc none /proc); then
        echo "|> Error: could not mount ..."
        return 1
    fi

    if ! (mount -t sysfs none /sys); then
        echo "|> Error: could not mount ..."
        return 1
    fi

    if ! (mount -t tmpfs tmpfs /tmp); then
        echo "|> Error: could not mount ..."
        return 1
    fi

    # redo mount tracefs and securityfs pseudo-filesystems
    if ! (mount -t tracefs tracefs /sys/kernel/tracing/); then
        echo "|> Error: could not mount ..."
        return 1
    fi

    if ! (mount -t debugfs debugfs /sys/kernel/debug/); then
        return 1
    fi

    if ! (mount -t securityfs securityfs /sys/kernel/security/); then
        echo "|> Error: could not mount ..."
        return 1
    fi
    EOF &&
        #
        #
        #
        # redo set up hostname
        echo "kjx" >/etc/hostname && hostname -F /etc/hostname

    # redo bring up the connection
    # bring up loopback interface
    if ! (/sbin/ip link set lo up); then
        echo "|> Error: could not link set lo up"
    fi
    # bring up ethernet interface); then
    if ! (/sbin/ip link set eth0 up); then
        echo "|> Error: could not set eth0 network interface up"
    fi
    # static ipv4 assignment     ); then
    if ! (/sbin/ip addr add 192.168.0.27 eth0); then
        echo "|> Error: could not add the address 192.168.0.27 at eth0"
    fi

    # redo alternate method, built-in inside busybox
    #udhcpc -i eth0 # dynamic ipv4 assignment

    # ================================

    # sets up BRK keyboard
    if ! (setxkbmap -model abnt2 -layout br -variant abnt2); then
        echo "|> Error: could not set the keyboard to BRK :("
    fi
    echo "|> Sucessfully setup the keyboard to BRK ;)"
    echo && echo

# ==============================================
#
# AIRGAP PROOF-OF-CONCEPT
#
#
    # virtio virtfs interface for
# file sharing between guest and host
VIRTIO_PASSTHRU_DIR="/mnt/virtio-test"
export VIRTIO_PASSTHRU_DIR

# check if inside guest vm
if ! (cat /proc/cpuinfo | grep QEMU >/dev/null 2>&1); then
    echo && echo "|> Error: not running inside QEMU, outside of POC scope. Exiting now..."
    echo "|> SCOPE: global, file: [./scripts/isogen/poc-bootscript.sh], check: 01"
    echo && echo
    # ETC_CONTAINERS_CONF="${ISO_DIR:-[EMPTY_VARIABLE]}/rootfs/etc/containers/containers.conf"
    # ETC_CONTAINERS_STORAGE_CONF="${ISO_DIR:-[EMPTY_VARIABLE]}/rootfs/etc/containers/storage.conf"
    return 1
fi
echo "|> Sucessfully running inside QEMU, inside of the POC scope. Proceeding..."
echo "|> SCOPE: global, file: [./scripts/isogen/poc-bootscript.sh], check: 01"
echo && echo
###
### mkdir -p "${VIRTIO_PASSTHRU_DIR}"
### mount -t 9p -o trans=virtio hostshare "${VIRTIO_PASSTHRU_DIR}"
###
mkdir -p "${VIRTIO_PASSTHRU_DIR}"
mkdir -p /app

if [ -f "${VIRTIO_PASSTHRU_DIR:-[EMPTY_VARIABLE]}/poc-bootscript.sh" ]; then

    if ! (cp "${VIRTIO_PASSTHRU_DIR:-[EMPTY_VARIABLE]}/poc-bootscript.sh" /app); then
        echo "|> Error: could not copy the bootscript"
        echo "|> SCOPE: global, file: [./scripts/isogen/poc-bootscript.sh], check: 02"
        return 1
    fi
    echo "|> Sucessfully copied the bootscript"
    echo
fi

if (mount | grep hostshare); then
    if ! umount "${VIRTIO_PASSTHRU_DIR:-[EMPTY_VARIABLE]}"; then
        echo "|> Error: could not unmount the hostshare 9P virtio for the virtfs option of QEMU. Exiting now..."
        return 1
    fi
    echo "|> Sucessfully unmounted the hostshare 9P virtio for the virtfs option of QEMU. Proceeding..."
fi

if ! (mount -t 9p -o trans=virtio hostshare "${VIRTIO_PASSTHRU_DIR}"); then
    echo && echo "|> Error: it was not possible to mount 9P using virtio as transport option. Exiting now..."
    echo "|> SCOPE: global, file: [./scripts/isogen/poc-bootscript.sh], check: 02"
    echo && echo
    return 1
fi
echo "|> Successfully mounted 9P using virtio as transport option. Proceeding..."
echo "|> SCOPE: global, file: [./scripts/isogen/poc-bootscript.sh], check: 02"
echo && echo

# ==============================================

echo

    if ! (cat <<'asciiart'
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

); then
    echo "|> Error: could not setup the ASCIIART"
    return 1
    fi

    # get a shell
    sh

    asciiart

    printf "Uptime: %s\n" "$(cut -d' ' -f1 /proc/uptime)"
    printf "System config: %s\n" "$(uname -a)"
    ## get a shell
    #sh

    if ! (exec /bin/busybox runsvdir /etc/runit/runsvdir/default); then
        echo "|> Error: could not run rsvdir. Exiting now..."
        return 1
    fi
        echo "|> Sucessfully ran runsvdir. Exiting now..."
    # load early bpf program
    # /bin/libkjx_runqlat

#}
INIT_EOF
        ) | tee "${ISODIR_ROOTFS_PATH:-[EMPTY_VARIABLE]}/etc/runit/1"
    ); then
        echo "|> Error: it was not possible to write the bootscript of the [ISODIR_ROOTFS_PATH] to its [/etc/runit/1]. Exiting now..."
        return 1
    fi
    echo "|> Sucessfully wrote the bootscript of the [ISODIR_ROOTFS_PATH] to its [/etc/runit/1]. Proceeding..."

    if ! (chmod +x "${ISODIR_ROOTFS_PATH:-[EMPTY_VARIABLE]}/etc/runit/1"); then
        echo "|> Error: it was not possible to change file bits of permissions of the bootscript for the [ISODIR_ROOTFS_PATH]. Exiting now..."
        return 1
    fi
    echo "|> Sucessfully changed file bits of permissions of the bootscript for the [ISODIR_ROOTFS_PATH]. Proceeding..."

    # sudo ln -sf "$ISO_DIR"/rootfs/etc/runit/1 "$ISO_DIR"/rootfs/sbin/init
    if ! (ln -sf "${ROOTFS_PATH:-[EMPTY_VARIABLE]}/etc/runit/1" "${ISODIR_ROOTFS_PATH:-[EMPTY_VARIABLE]}/sbin/init"); then
        echo "|> Error: it was not possible to create a [SYMLINK] (soft-link/symbolic link) from [ISODIR_ROOTFS_PATH]'s runit-1 to the sbin/init bootscript. Exiting now..."
        return 1
    fi
    echo "|> Sucessfully created a [SYMLINK] (soft-link/symbolic link) from [ISODIR_ROOTFS_PATH]'s runit-1 to the sbin/init bootscript. Exiting now..."
    #}

    #runit_symlinks() {
    # this bootstraps the set_sandboxes function
    # inside runit, as well as any hotfixes needed
    # from the previous mksquashfs (deep copy) followed
    # by cp (shallow copy) steps.

    # setup runit to start the C program to control both k3s and the tracer at startup
    mkdir -p "$ROOTFS_PATH"/etc/sv/clusterbuild/

    # =========================================

    # copy initramfs to the artifacts qcow2 directory, then copy the latter to the squashfs directory
    # tryout.sh
    # set_rootfs() {
    #MODE="-setvars" . ./scripts/isogen/set-vars.sh

    # CALL TO BUILD THE ROOTFS
    #
    # if ! (CCR_MODE="-checker" . ./scripts/ccr.sh; \
    #     docker compose -f ./compose.yml --progress=plain build rootfs); then
    # echo "|> Error: could not build the [ROOTFS] OCI image. Exiting now..."
    # return 1
    # fi
    if ! (MODE="tarball" . ./scripts/packages/rootfs-setup.sh); then
        echo "|> Error: it was not possible to get the [rootfs.cpio.gz] initial tarball. Exiting now..."
        return 1
    fi
    echo "|> Sucessfully got the rootfs tarball. Proceeding..."

    if ! (MODE="tarball" . ./scripts/packages/initramfs-setup.sh); then
        echo "|> Error: it was not possible to get the initramfs.cpio.gz tarball. Exiting now..."
        return 1
    fi
    echo "|> Sucessfully got the rootfs tarball. Proceeding..."

    # PART 23
    # decompress and extract initramfs into rootfs_path // sudo

    mkdir -p "${ISODIR_ROOTFS_PATH}"

    if ! (
        busybox gzip -dc "${ISODIR_ROOTFS_CPIO_GZ}" | (cd "${ISODIR_ROOTFS_PATH:-[EMPTY_VARIABLE]}" || return && busybox cpio -idmv && cd - || return)
    ); then
        echo "|> Error: it was not possible to run gzip to decompress the [ISODIR_ROOTFS_CPIO_GZ]"
        return 1
    fi

    printf '##                     (30%%)\r'
    sleep 1

    # newfrdir
    #
    # cp ./newfrdir/* $ROOTFS_PATH

    if ! [ -d "${SQ_ROOTFS}" ]; then
        echo "|> Error: the [SQUASHED_ROOTFS] does not exist. Exiting now..."
        return 1
    fi
    echo "|> Sucessfully found the [SQUASHED_ROOTFS]. Proceeding..."

    # copy rootfs_path contents to the squashed_rootfs
    # cp -r "$ROOTFS_PATH/" "$SQ_ROOTFS"

    #}

    # mount the loop device into the rootfs
    #mount_loopdev() {
    printf "=============|> [STEP 6]: mount the loop device into the rootfs.\n=============\n\n"
    mkdir -p "$UPPER_MOUNTPOINT"/rootfs # mkdir a directory for the rootfs

    # busybox-sh based
    # mountns_sasquatch() {

    # sink to the mount namespace
    #mkdir -p /tmp/host_dir

    #KJX="/mnt/kjx"

    # these are idempotent
    mkdir -pv "$KJX/dev"
    mkdir -pv "$KJX/tmp"
    mkdir -pv "$KJX/proc"
    mkdir -pv "$KJX/sys"
    mkdir -pv "$KJX/run"
    # chapter 5 - fake the cross-compiler toolchain
    mkdir -pv "$KJX/tools"

    printf '##                     (32%%)\r'
    sleep 1

    # mounts are for compiled LFS step
    ## populating /dev for the kjx mount (before chroot), all sudo
    sudo mount -t devtmpfs devtmpfs "$KJX/dev/" #
    sudo mount -t tmpfs tmpfs "$KJX/tmp/"

    ## mounting virtual kernel filesystems (before chroot), all sudo
    sudo mount -vt devpts devpts -o gid=5,mode=0620 "$KJX/dev/pts"
    sudo mount -vt proc proc "$KJX/proc"
    sudo mount -vt sysfs sysfs "$KJX/sys"
    sudo mount -vt tmpfs tmpfs "$KJX/run"

    # setting up the bind mount
    TMPDIR=$(/bin/busybox mktemp -d)
    mkdir -p "$KJX/sources/release"
    sudo mount --bind "$KJX/sources/release" "$TMPDIR"

    # squashfs
    mkdir -pv "$SQ_ROOTFS"
    mkdir -pv "$SQ_SQUASHFS"
    mkdir -pv "$SQ_OVERLAY/upperdir/usr/local/bin/"

    mkdir -pv "$SQ_OVERLAY/upperdir"
    mkdir -pv "$SQ_OVERLAY/workdir"
    mkdir -pv "$SQ_OVERLAY/merged"

    # =============
    # populate rootfs directory using the busybox directory tree from the initramfs
    # =============
    #BACK_HERE
    mkdir -pv "$ROOTFS_PATH"

    # sudo
    # sudo mount "$UPPER_LOOPDEV" "$ROOTFS_PATH"

    sudo mount "$UPPER_LOOPDEV" "$UPPER_MOUNTPOINT"/rootfs # mount loop device into the generic dir
    # sudo mount
    #}

    # verify_check_loop()
    #
    #runit_directories() {
    # runit/runsv/runsvdir setup
    mkdir -p "${ISODIR_ROOTFS_PATH}/etc/runit"
    mkdir -p "${ISODIR_ROOTFS_PATH}/etc/runit/runsvdir/default"
    mkdir -p "${ISODIR_ROOTFS_PATH}/etc/sv"
    mkdir -p "${ISODIR_ROOTFS_PATH}/var/service"
    mkdir -p "${ISODIR_ROOTFS_PATH}/usr/local/bin"

    # runit: service scripts, get a shell
    mkdir -p "$ROOTFS_PATH/etc/sv/getty-tty1"

    mkdir -p /run /var

    # if [tmpfs] filesystem is not already mounted at /run, attempt to mount it
    if ! (mount | grep "/run" | grep "tmpfs"); then
        echo "|> WARNING: There is no known [tmpfs] filesystem mounted at [/run]. Attempting to create symlink..."

        if ! (mount -t tmpfs tmpfs /run); then
            echo && echo "|> Error: could not mount type tmpfs at [/run]. Exiting now..."
            echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 05"
            echo && echo
            return 1
        fi
        echo "|> Sucessfully mounted type tmpfs at [/run]. Proceeding..."
        echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 05"
        echo && echo

    fi
    echo "|> Found an already mounted [tmpfs] filesystem at [/run]. Proceeding..."

    # soft link of the previous mounted tmpfs filesystem at /run
    if ! [ -f /var/run ]; then
        echo "|> WARNING: There is no known [/var/run]. Attempting to create symlink..."

        if ! (ln -s /run /var/ 2>/dev/null); then
            echo "|> Error: could not create symlink (soft link) of [/run] at [/var]. Exiting now..."
            echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 06"
            echo && echo
            return 1
        fi
        echo "|> Sucessfully created symlink (soft link) of [/run] at [/var]. Proceeding..."
        echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 06"
        echo && echo

    fi
    echo "|> Sucessfully created symlink of [/run] at [/var/run] There is no known [/var/run]. Attempting to create symlink..."
    echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 06"

    # =============
    #
    # =========
    # rootfs
    #cp -r "$ROOTFS_PATH"/* "$ISO_DIR"/rootfs

    sudo cp -r "$SQ_ROOTFS"/* "$ISO_DIR"/rootfs

    mkdir -p "$ISO_DIR"/rootfs/app/scripts/
    cp -r ./scripts/* "$ISO_DIR"/rootfs/app/scripts

    ### WARNING: REDO!
    ## ADAPTED FROM the runit_symlinks function.

    # redo symlinks, gambi
    # runtime link
    sudo rm -rf "$ISO_DIR"/rootfs/var/service/*
    for item in "$ISO_DIR"/rootfs/etc/sv/*; do
        sudo ln -sf "$item" "$ISO_DIR"/rootfs/var/service/
    done

    # redo symlinks, gambi
    sudo rm -rf "$ISO_DIR"/rootfs/etc/runit/runsvdir/default/*
    for index in "$ISO_DIR"/rootfs/etc/sv/*; do
        sudo ln -sf "$index" "$ISO_DIR"/rootfs/etc/runit/runsvdir/default/
    done

    sudo ln -sf "$ISO_DIR"/rootfs/etc/runit/1 "$ISO_DIR"/rootfs/sbin/init

    # Linux Standard Base (LSB)-based system status
    sudo tee "$ISO_DIR"/rootfs/etc/lsb-release >/dev/null <<"EOF"
DISTRIB_ID="LFS: kjx-headless"
DISTRIB_RELEASE="1.0"
DISTRIB_CODENAME="Mantis"
DISTRIB_DESCRIPTION="Linux From Scratch: kjx-headless build for virtual labs"


EOF

    # init-system specific system status
    sudo tee "$ISO_DIR"/rootfs/etc/lsb-release >/dev/null <<"EOF"
NAME="kjx-headless"
VERSION="1.0"
ID=kjx
PRETTY_NAME="LFS: kjx-headless 1.0"
VERSION_CODENAME="Mantis"
HOME_URL="github.com/kijinix/kjx-headless"


EOF

    #}
    #system_info

    # final_move

    # ISO_DIR
    # EFI_TMPDIR mktmp

}
