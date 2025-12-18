#!/bin/sh

builder() {
    # Build docker image
    podman run -d -p 5000:5000 --name registry registry:3.0
    # env git_hash env goes into the compose.yml
    #
    CCR_MODE="-checker"
    export CCR_MODE

    if ! . ./scripts/ccr.sh; then
        printf "\n|> FUNCTION CALL: ./scripts/isogen/initramfs.sh"
        printf "\n|> SCOPE: builder, test [01]"
        printf "\n|> Error: CCR script has [FAILED]! \n"
        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/isogen/initramfs.sh"
        printf "\n|> SCOPE: builder, test [01]"
        printf "\n|> run the CCR script. ...[PASSED]\n"
        ;;
    esac
    printf "\n|> CCR script and Podman Service created with success.\n\n"

    #CCR_MODE="-checker" . ./scripts/ccr.sh &&
    # invoke compose to build the initramfs target
    if ! docker compose -f ./compose.yml --progress=plain build initramfs; then
        printf "\n|> FUNCTION CALL: ./scripts/isogen/initramfs.sh"
        printf "\n|> SCOPE: builder, test [02]"
        echo "|> Error: was not possible to build the initramfs target with compose. Exiting now..."
        echo
        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/isogen/initramfs.sh"
        printf "\n|> SCOPE: builder, test [02]"
        printf "\n|> invoke compose and build the initramfs target. ...[PASSED]\n"
        ;;
    esac
    printf "\n|> invoked compose and build the initramfs target with success.\n\n"

    if ! docker push localhost:5000/initramfs:latest; then
        printf "\n|> FUNCTION CALL: ./scripts/isogen/initramfs.sh"
        printf "\n|> SCOPE: builder, test [03]"
        echo "|> Error: it was not possible to push the OCI image to the localhost:5000 registry. Exiting now..."
        return 1
    fi
    #podman build -t initramfs:latest -f ./utils/busybox/Dockerfile
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/isogen/initramfs.sh"
        printf "\n|> SCOPE: builder, test [03]"
        printf "\n|> push the built OCI image into the localhost:5000 registry. ...[PASSED]\n"
        ;;
    esac
    printf "\n|> pushed the built OCI image into the localhost:5000 registry. with success.\n\n"

    # invoke compose create to retrieve the artifact from the OCI image
    mkdir -p ./artifacts/isogen/
    if ! docker compose -f ./compose.yml create initramfs; then
        #if ! docker run -it --name initramfs -d localhost:5000/initramfs:latest; then
        printf "\n|> FUNCTION CALL: ./scripts/isogen/initramfs.sh"
        printf "\n|> SCOPE: builder, test [04]"
        echo "|> Error: it was not possible to invoke compose create to retrieve the artifact from the OCI image. Exiting now..."
        echo
        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/isogen/initramfs.sh"
        printf "\n|> SCOPE: builder, test [04]"
        printf "\n|> invoke compose create to retrieve the initramfs.cpio.gz artifact from the OCI image. ...[PASSED]\n"
        ;;
    esac
    printf "\n|> invoked compose create to retrieve the initramfs.cpio.gz artifact from the OCI image. \n\n"

    # copy initramfs.cpio.gz from the OCI image into artifacts
    if ! docker cp initramfs:./initramfs.cpio.gz ./artifacts/isogen/; then
        printf "\n|> FUNCTION CALL: ./scripts/isogen/initramfs.sh"
        printf "\n|> SCOPE: builder, test [05]"
        echo "|> Error: it was not possible to copy initramfs.cpio.gz from the OCI image into artifacts. Exiting now..."
        echo
        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/isogen/initramfs.sh"
        printf "\n|> SCOPE: builder, test [05]"
        printf "\n|> copy the initramfs.cpio.gz tarball artifact from the container into the local artifacts directory. ...[PASSED]\n"
        ;;
    esac
    printf "\n|> copy initramfs.cpio.gz from the OCI image into artifacts with success. \n\n"

}

inita() {
    # Repack initramfs init bootscript
    if [ "$(basename "$PWD")" = "kjx-headless" ] && [ -f "$ISO_DIR"/kernel/initramfs-ssh.cpio.gz ]; then

        if [ -d "$ISO_DIR"/kernel/repack_initramfs ]; then
            rm -rf "$ISO_DIR"/kernel/repack_initramfs/
        fi

        cd "$ISO_DIR"/kernel/ || return
        mkdir -p ./repack_initramfs

        # Decompress gunzip and then cpio to the specified path
        echo "Trying to decompress the cpio.gz tarball..."
        if ! gzip -cd ./initramfs-ssh.cpio.gz | cpio -idmv -D ./repack_initramfs; then
            printf "\n |> Failed to decompress cpio.gz tarball. Exiting now..."
        fi
        printf "\n|> initramfs decompressed successfully."

        # Copy kernel modules tarball into the repack directory
        cp -r ./tmp_modules/mnt/lfs/* ./repack_initramfs/

        rm -rf ./tmp_modules/*

        cd - || return

        (
            cat <<"INIT_EOF"
#!/bin/busybox sh

# Redo mount filesystems
mount -t devtmpfs   devtmpfs    /dev
mount -t proc       proc        /proc
mount -t sysfs      sysfs       /sys
mount -t tmpfs      tmpfs       /tmp
mount -t tmpfs      tmpfs       /run

mkdir /dev/pts
mount -t devpts devpts /dev/pts

# Redo mount tracefs and securityfs pseudo-filesystems
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



printf "Uptime: $(cut -d' ' -f1 /proc/uptime) \n"
printf "System config: $(uname -a) \n"

# Parse kernel command line for our custom parameters
ISO_DEVICE=$(cat /proc/cmdline | sed -n 's/.*root=\([^ ]*\).*/\1/p')
SQUASHFS_IMAGE_PATH=$(cat /proc/cmdline | sed -n 's/.*rootfs_path=\([^ ]*\).*/\1/p')
FULL_SQUASHFS_PATH="/mnt/iso_live$SQUASHFS_IMAGE_PATH"


# Base directories for overlayfs over the squashfs image
SQ_ROOTFS="/tmp/kjx_rootfs"
SQ_SQUASHFS="/tmp/kjx_squashfs"
SQ_OVERLAY="/tmp/kjx_overlay"

# Create squashfs destination paths
mkdir -p "$SQ_ROOTFS"
mkdir -p "$SQ_SQUASHFS"
mkdir -p "$SQ_OVERLAY/lower"
mkdir -p "$SQ_OVERLAY/upperdir/usr/local/bin/"
mkdir -p "$SQ_OVERLAY/workdir"
mkdir -p "$SQ_OVERLAY/merged"

# Create temporary mount points
mkdir -p /mnt/iso_live
mkdir -p /new_root


# Mount the ISO device
echo "Attempting to mount ISO device ($ISO_DEVICE) to /mnt/iso_live..."
if ! mount -r -t iso9660 "$ISO_DEVICE" /mnt/iso_live; then
    printf "\n|> Failed to mount ISO device %s. Dropping to shell.\n" "$ISO_DEVICE"
    exec /bin/sh && asciiart
fi
echo "ISO device mounted successfully."


# If the path for the squashfs exists,
echo "Attempting to mount SquashFS image from $FULL_SQUASHFS_PATH to /new_root..."
if [ ! -f "$FULL_SQUASHFS_PATH" ]; then
    printf "\n\n|> Error: SquashFS image not found at $FULL_SQUASHFS_PATH. Dropping to shell."
    exec /bin/sh && asciiart
fi

# Mount the squashfs
#
# -r for read-only mount, -t squashfs for filesystem type
if ! mount -r -t squashfs "$FULL_SQUASHFS_PATH" "$SQ_OVERLAY"/lower; then
    printf "\n|> Failed to mount SquashFS image $FULL_SQUASHFS_PATH. Dropping to shell."
    printf "\n|> Check if 'squashfs' kernel module is loaded or compiled into kernel."
    exec /bin/sh && asciiart
fi
echo "SquashFS root filesystem mounted successfully."

# Unmount the ISO since it is not needed anymore
umount /mnt/iso_live 2>/dev/null || true # Ignore if it fails (e.g., if busy)

# Load the overlay kernel module
#
echo "Loading the overlayfs kernel module..."
if ! modprobe overlay && lsmod | grep overlay; then
    printf "|> Error: failed to load the overlayfs kernel module. Dropping to shell. \n"
    printf "|> check if overlayfs kernel module is loaded or compiled into kernel."
    exec /bin/sh && asciiart

fi
echo "overlayfs kernel module was successfully loaded!"

# Mount the overlayfs over squashfs
#
# hint: this mounts an read-write overlayfs upperdir atop of the decompressed read-only lowerdir squashfs
#
echo "Mounting overlayfs..."
if ! mount -t overlay overlay -o lowerdir="$SQ_OVERLAY"/lower,upperdir="$SQ_OVERLAY"/upperdir,workdir="$SQ_OVERLAY"/workdir "$SQ_OVERLAY"/merged; then
    printf "|> Failed to mount overlayfs. Dropping to shell.\n"
    printf "|> Check if 'overlayfs' kernel module is loaded or compiled into kernel."
    exec /bin/sh && asciiart
fi
echo "Overlayfs mounted successfully to $SQ_OVERLAY/merged"



# Setup podman storage outside the overlay
#
echo "Mounting tmpfs at podman's graphroot storage directory..."
mkdir -p "$SQ_OVERLAY/merged/var/lib/containers"
mount -t tmpfs tmpfs "$SQ_OVERLAY/merged/var/lib/containers"

mkdir -p "$SQ_OVERLAY/merged/run"
mount -t tmpfs tmpfs "$SQ_OVERLAY/merged/run"

# unmount base directories, rootfs init bootscript
# will mount them again
umount /proc
umount /sys
umount /dev

printf "\n\n===========\n|> Switching root to the new filesystem...\n===============\n\n"
# The 'switch_root' command expects the new root directory and the path to 'init'
# within that new root.
exec switch_root "$SQ_OVERLAY"/merged /sbin/init


# Should not reach here if switch_root is successful
echo "ERROR: switch_root failed! Dropping to shell."
exec /bin/sh && asciiart


INIT_EOF
        ) | tee "$ISO_DIR"/kernel/repack_initramfs/init

        chmod +x "$ISO_DIR"/kernel/repack_initramfs/init

    else
        printf "\n|> ERROR: initramfs-ssh.cpio.gz file not found. Exiting now...\n\n"
    fi

    # Create reviewed cpio.gz rootfs tarball
    #
    if [ "$(basename "$PWD")" = "kjx-headless" ] && [ -d "$ISO_DIR"/kernel/repack_initramfs ]; then
        cd "$ISO_DIR"/kernel/repack_initramfs || return
        mv ../initramfs-ssh.cpio.gz ../initramfs-ssh_bak.cpio.gz
        find . -print0 | busybox cpio --null -ov --format=newc | gzip -9 >../initramfs-ssh.cpio.gz &&
            echo "done!!"

        cd - || return
    else
        printf "\n|> Error: could not find the repack directory. Exiting now...\n\n"
    fi

}
