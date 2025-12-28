#!/bin/sh

# ====================
#
# Global variables
#
# Checks if the current directory is root of the repository
KJXPATH=$(basename "$PWD")
# Raw Virtual Disk Sparse file path
RVDSF_EULAB="./utils/storage/eulab-hd"

# utils directory path for the raw image
K3S_SQUASHFS_IMAGE_PATH="./utils/storage/k3s-tarball-squashfs.img"
# k3s airgap image path and basenames
K3S_AIRGAP_PATH="./artifacts/k3s-airgap"
K3S_AIRGAP_TARBALL_GZ="${K3S_AIRGAP_PATH}/k3s-airgap-images-amd64.tar.gz"
K3S_AIRGAP_TARBALL_GZ_NAME="k3s-airgap-images-amd64.tar.gz"
K3S_AIRGAP_TAR_NAME="k3s-airgap-images-amd64.tar"

# /tmp directories to unpack and squashfs
K3S_UNPACK_TMP="/tmp/k3s-unpack"
K3S_SQUASHFS_FILE="/tmp/k3s-tarball.squashfs"

# mount point for the k3s-squashfs
MOUNTPOINT_K3S_SQUASHFS="/mnt/k3s-squashfs"

# OCI image artifact from the conversion using skopeo
SKOPEO_TARBALL_ARTIFACT="/tmp/skopeo-convert-registry.oci.tar"
# ===========
# Virtio utils
# virtfs path
VIRTFS_ART_PATH="./artifacts/qemu-sink"

# =====================
# Recording variables
# asciinema recording file path
ASCII_DATE="$(date | awk '{print $1"-"$2"-"$3"-"$4"_"$5}' | tr ":" "-")"
#RUNISO_RECORDING_PATH="./artifacts/run-qemu_runiso_$(date | awk '{print $1"-"$2"-"$3"-"$4"_"$5}' | tr ":" "-").cast"
RUNISO_RECORDING_PATH="./artifacts/run-qemu_runiso_${ASCII_DATE}.cast"
AIRGAP_RECORDING_PATH="./artifacts/run-qemu_airgap_${ASCII_DATE}.cast"

# default recording state
IS_RECORDING="NO"

# ======================
# Packaging or INFRA artifacts
# ======================
#
# Artifacts variables
ANODA_INITRAMFS="/home/asari/Downloads/kjxh-artifacts/another/rootfs_v28.cpio.gz"
MANUAL_AIRGAP_BZIMAGE="$HOME/Downloads/kjxh-artifacts/10_fuse-support/bzImage"

# Microvm artifact variables
#MICROVM_GVISOR_TARBALL="./artifacts/microvms/gvisor-core.tar.gz"
#MICROVM_FIRECRACKER_TARBALL="./artifacts/microvms/firecracker-containerd.tar.gz"
#MICROVM_KATA_TARBALL="./artifacts/microvms/kata-containerd.tar.gz"

MICROVM_GVISOR_TARBALL="./artifacts/microvms/gvisor-tarball-pkg.tar.gz"
MICROVM_FIRECRACKER_TARBALL="./artifacts/microvms/firecracker-tarball-pkg.tar.gz"
MICROVM_KATA_TARBALL="./artifacts/microvms/kata-tarball-pkg.tar.gz"
MICROVM_KATA_BIN="./artifacts/microvms/kata-bin-pkg.tar.gz"

# Tracers artifact variables
TRACERS_BPFTRACE_TARBALL="./artifacts/packaging/bpftrace-tarball-pkg.tar.gz"

# User Management artifacts
PACKAGING_IPTABLES_TARBALL="./artifacts/packaging/iptables-tarball-pkg.tar.gz"
PACKAGING_SHADOW_TARBALL="./artifacts/packaging/shadow-tarball-pkg.tar.gz"

# ======================
# BOOTSCRIPTS
# ======================

# poc-bootscript filepath
POC_BOOTSCRIPT="./scripts/isogen/poc-bootscript.sh"

prepare_packaging() {

    # Packaging

    # setup user and groups management with shadow, doas and others
    if ! (MODE="shadow" . ./scripts/packages/usgp-man.sh); then
        echo "|> Error: it was not possible to setup user and groups management with the ./scripts/packages/usgp-man.sh shellscript. Exiting now..."
        echo "|> SCOPE: [prepare_packaging], file [./scripts/sandbox/run-qemu.sh]; check: 01"
        echo && echo
        return 1
    fi
    echo "|> Successfully ran the setup for user and groups management with the ./scripts/packages/usgp-man.sh shellscript. Proceeding..."
    echo "|> SCOPE: [prepare_packaging], file [./scripts/sandbox/run-qemu.sh]; check: 01"
    echo && echo

    # setup iptables, conntrack, netfilter, bpf and other network things for k3s and OCI-CRI.
    if ! (MODE="iptables" . ./scripts/packages/usgp-man.sh); then
        echo "|> Error: it was not possible to run the usgp-man shellscript to build iptables dependencies. Exiting now..."
        echo "|> SCOPE: [prepare_packaging], file [./scripts/sandbox/run-qemu.sh]; check: 02"
        echo && echo
        return 1
    fi
    echo "|> Successfully ran the usgp-man shellscript to build iptables dependencies. Proceeding..."
    echo "|> SCOPE: [prepare_packaging], file [./scripts/sandbox/run-qemu.sh]; check: 02"
    echo && echo

    # setup podman shared objects
    if ! [ -f "${VIRTFS_ART_PATH:-[EMPTY_VARIABLE]}/podman-archive.tar.gz" ]; then

        # MODE="podman-deps" . ./scripts/isogen/qonq-qdb.sh
        MODE="podman-deps" . ./scripts/qonq-qdb.sh

    fi

    # prepre bpftrace shared objects (just for the flamegraph and log2 histograms)

    # setup firecracker dependencies
    ## iptables/networking already met
    ##

}

prepare_rootfs() {

    if (CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose -f ./compose.yml --progress=plain build --no-cache rootfs); then
        echo "|> Error: could not run the [./deploy/isogen/rootfs/Dockerfile] script to build the rootfs (based on dropbear ssh and others). Exiting now..."
        echo "|> SCOPE: [prepare_rootfs], file [./scripts/sandbox/run-qemu.sh]; check: 01"
        return 1
    fi
    echo "|> Sucessfully ran the [./deploy/isogen/rootfs/Dockerfile] script to build the rootfs (based on dropbear ssh and others). Exiting now..."
    echo "|> SCOPE: [prepare_rootfs], file [./scripts/sandbox/run-qemu.sh]; check: 01"

    if ! prepare_packaging; then
        echo "|> Error: could not run the [prepare_packaging] function. Exiting now..."
        echo "|> SCOPE: [prepare_rootfs], file [./scripts/sandbox/run-qemu.sh]; check: 02"
        return 1
    fi
    echo "|> Sucessfully ran the [prepare_packaging] function. Proceeding..."
    echo "|> SCOPE: [prepare_rootfs], file [./scripts/sandbox/run-qemu.sh]; check: 02"

}

airgap_clean() {

    CLEAN_K3S_TARBALL_SQUASHFS_ARTIFACT="/tmp/k3s-tarball.squashfs"
    CLEAN_K3S_TARBALL_IMAGE="./utils/storage/k3s-tarball-squashfs.img"
    CLEAN_GVISOR_TARBALL="./artifacts/microvms/gvisor-core.tar.gz"
    #CLEAN_BPFTRACE_TARBALL="./artifacts/packaging/bpftrace-tarball-pkg.tar.gz"

    if [ -f "${CLEAN_K3S_TARBALL_SQUASHFS_ARTIFACT:-[EMPTY_VARIABLE]}" ]; then
        echo "|> Artifact found. Attempting to remove now..."
        echo && echo

        if ! (rm "${CLEAN_K3S_TARBALL_SQUASHFS_ARTIFACT:-[EMPTY_VARIABLE]}"); then
            echo "|> Error: could not remove [${CLEAN_K3S_TARBALL_SQUASHFS_ARTIFACT:-[EMPTY_VARIABLE]}]. Exiting now..."
            echo "|> SCOPE: [airgap_clean], file: [./scripts/sandbox/run-qemu.sh], CHECK: 01"
            echo && echo
            return 1
        fi
        echo "|> Sucessfully removed the [${CLEAN_K3S_TARBALL_SQUASHFS_ARTIFACT:-[EMPTY_VARIABLE]}]. Proceeding..."
        echo "|> SCOPE: [airgap_clean], file: [./scripts/sandbox/run-qemu.sh], CHECK: 01"
        echo && echo

        return
    fi

    if [ -f "${CLEAN_K3S_TARBALL_IMAGE:-[EMPTY_VARIABLE]}" ]; then
        echo "|> Artifact found. Attempting to remove now..."
        echo && echo

        if ! (rm "${CLEAN_K3S_TARBALL_IMAGE:-[EMPTY_VARIABLE]}"); then
            echo "|> Error: could not remove [${CLEAN_K3S_TARBALL_IMAGE:-[EMPTY_VARIABLE]}]. Exiting now..."
            echo "|> SCOPE: [airgap_clean], file: [./scripts/sandbox/run-qemu.sh], CHECK: 02"
            echo && echo
            return 1
        fi
        echo "|> Sucessfully removed [${CLEAN_K3S_TARBALL_IMAGE:-[EMPTY_VARIABLE]}]. Proceeding..."
        echo "|> SCOPE: [airgap_clean], file: [./scripts/sandbox/run-qemu.sh], CHECK: 02"
        echo && echo

        return
    fi

    if [ -f "${CLEAN_GVISOR_TARBALL:-[EMPTY_VARIABLE]}" ]; then
        echo "|> Artifact found. Attempting to remove now..."
        echo && echo

        if ! (rm "${CLEAN_GVISOR_TARBALL:-[EMPTY_VARIABLE]}"); then
            echo "|> Error: could not remove [${CLEAN_GVISOR_TARBALL:-[EMPTY_VARIABLE]}]. Exiting now..."
            echo "|> SCOPE: [airgap_clean], file: [./scripts/sandbox/run-qemu.sh], CHECK: 03"
            echo && echo
            return 1
        fi
        echo "|> Sucessfully removed [${CLEAN_GVISOR_TARBALL:-[EMPTY_VARIABLE]}]. Proceeding..."
        echo "|> SCOPE: [airgap_clean], file: [./scripts/sandbox/run-qemu.sh], CHECK: 03"
        echo && echo

        return

    fi

    ### if [ -f "${CLEAN_BPFTRACE_TARBALL:-[EMPTY_VARIABLE]}" ]; then
    ###     echo "|> Artifact found. Attempting to remove now..."
    ###     echo && echo

    ###     if ! (rm "${CLEAN_BPFTRACE_TARBALL:-[EMPTY_VARIABLE]}"); then
    ###         echo "|> Error: could not remove [${CLEAN_BPFTRACE_TARBALL:-[EMPTY_VARIABLE]}]. Exiting now..."
    ###         echo "|> SCOPE: [airgap_clean], file: [./scripts/sandbox/run-qemu.sh], CHECK: 03"
    ###         echo && echo
    ###         return 1
    ###     fi
    ###     echo "|> Sucessfully removed [${CLEAN_BPFTRACE_TARBALL:-[EMPTY_VARIABLE]}]. Proceeding..."
    ###     echo "|> SCOPE: [airgap_clean], file: [./scripts/sandbox/run-qemu.sh], CHECK: 03"
    ###     echo && echo

    ###     return

    ### fi

}

prepare_tracers() {
    echo
}

microvm_poc_gvisor() {
    if ! (MODE="gvisor" . ./scripts/entrypoints/microvms.sh); then
        echo "|> Error: could not invoke the function [mvm_gvisor] from the [./scripts/entrypoints/microvms.sh] shellscript. Exiting now..."
        echo "|> Sucessfully invoked the function [mvm_firecracker] from the [./scripts/entrypoints/microvms.sh] shellscript. Proceeding..."
        return 1
    fi
    echo "|> SCOPE: [microvm_poc_gvisor], file: [./scripts/sandbox/run-qemu.sh], CHECK: 01"
    echo "|> Sucessfully invoked the function [mvm_firecracker] from the [./scripts/entrypoints/microvms.sh] shellscript. Proceeding..."

}

microvm_poc_firecracker() {
    if ! (MODE="firecracker" . ./scripts/entrypoints/microvms.sh); then
        echo "|> Error: could not invoke the function [mvm_firecracker] from the [./scripts/entrypoints/microvms.sh] shellscript. Exiting now..."
        echo "|> SCOPE: [microvm_poc_firecracker], file: [./scripts/sandbox/run-qemu.sh], CHECK: 01"
        return 1
    fi
    echo "|> Sucessfully invoked the function [mvm_firecracker] from the [./scripts/entrypoints/microvms.sh] shellscript. Proceeding..."
    echo "|> SCOPE: [microvm_poc_firecracker], file: [./scripts/sandbox/run-qemu.sh], CHECK: 01"
}

microvm_poc_kata() {
    if ! (MODE="kata" . ./scripts/entrypoints/microvms.sh); then
        echo "|> Error: could not invoke the function [mvm_kata] from the [./scripts/entrypoints/microvms.sh] shellscript. Exiting now..."
        echo "|> SCOPE: [microvm_poc_kata], file: [./scripts/sandbox/run-qemu.sh], CHECK: 01"
        return 1
    fi
    echo "|> Sucessfully invoked the function [mvm_kata] from the [./scripts/entrypoints/microvms.sh] shellscript. Exiting now..."
    echo "|> SCOPE: [microvm_poc_kata], file: [./scripts/sandbox/run-qemu.sh], CHECK: 01"
    #### # start OCI registry server
    #### if ! podman start registry; then
    ####     echo "|> Error: could not start OCI registry server. Attempting to run the image..."
    ####     echo && echo
    ####     #return 1

    ####     # run the registry:3.0 container image.
    ####     if ! (podman run -d -p 5000:5000 --name registry registry:3.0); then
    ####         echo "|> Error: could not run the registry:3.0 container image. Exiting now..."
    ####         echo && echo
    ####         return 1
    ####     fi
    ####     echo "|> Ran the OCI registry server with success. Proceeding..."
    ####     echo && echo
    #### fi
    #### echo "|> OCI registry server started with success"

    #### # check if the image already exists
    #### if ! (podman images | grep "localhost:5000/kata" | awk '{print $1}'); then
    ####     echo "|> Error: could not find the localhost:5000/kata image at the OCI registry:3.0 server. Attempting to build now..."
    ####     echo && echo
    ####     # return 1
    ####     # Build the kata container with ccr.sh to use  Podman Service as the compose tool
    ####     if ! CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose -f ./compose.yml --progress=plain build --no-cache kata; then
    ####         echo "|> Error: could not run the ccr.sh script for Podman Service as the compose tool. Exiting now..."
    ####         echo && echo
    ####         return 1

    ####     fi
    ####     echo "|> Build the kata container with ccr.sh to use  Podman Service as the compose tool with success. Proceeding..."
    ####     echo && echo

    ####     # push built image into the registry:3.0 localhost:5000 server container.
    ####     if ! podman push localhost:5000/kata:latest; then
    ####         echo "|> Error: could not push the built kata image into the registry:3.0 localhost:5000 server container. Exiting now..."
    ####         echo && echo
    ####         return 1
    ####     fi
    ####     echo "|> Pushed built image into the registry:3.0 localhost:5000 server container. Proceeding..."
    ####     echo && echo
    #### fi
    #### echo "|> kata image found at the localhost:5000/kata OCI registry:3.0 server. Proceeding..."

    #### # Create the built kata container
    #### # podman run -it --name kata -d localhost:5000/kata:latest
    #### if ! (CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose -f ./compose.yml create kata); then
    ####     echo "|> Error: could not create the built kata container using the ccr.sh script to use Podman Service as the compose tool"
    ####     echo && echo
    ####     return 1
    #### fi
    #### echo "|> Created the built kata container using the ccr.sh script to use Podman Service as the compose tool with success. Proceeding..."
    #### echo && echo

    #### # check created containers
    #### CCR_MODE="-checker" . ./scripts/ccr.sh && docker compose ps --all

    #### # check for the kata image at localhost:5000/kata
    #### podman images | grep "localhost:5000/kata" | awk '{print $1}'

    #### # copy kata tarball into the ./artifacts/microvms directory.
    #### mkdir -p ./artifacts/microvms/
    #### if ! podman cp kata:/kata-core.tar.gz ${MICROVM_KATA_TARBALL:-[EMPTY_VARIABLE]}; then
    ####     echo "|> Error: could not copy the kata tarball to the MICROVM_KATA_TARBALL=${MICROVM_KATA_TARBALL:-[EMPTY_VARIABLE]} filepath. Exiting now..."
    ####     return 1
    #### fi
    #### echo "|> Copied kata tarball into the MICROVM_KATA_TARBALL=${MICROVM_KATA_TARBALL:-[EMPTY_VARIABLE]} filepath with success. Proceeding... "

    #### # Stop container registry
    #### if ! (podman stop registry); then
    ####     echo "|> Error: could not stop the OCI registry server! Exiting now..."
    ####     echo && echo
    ####     return 1
    #### fi
    #### echo "|> Successfully stopped the OCI registry server."
    #### echo && echo
}

artifacts_builder() {

    if ! "${ANODA_INITRAMFS}"; then

        case "${ISOGEN_ART}" in
        # scaffolding
        "-scaff")
            if ! MODE="-scaff" . ./scripts/isogen/scaffolding.sh; then
                return 1
            fi
            ;;
        # Retrieve bzImage artifact from previous actions workflow
        "-buildakernel")
            if ! MODE="-buildakernel" . ./scripts/isogen/bzImage.sh; then
                return 1
            fi
            ;;
        # Retrieve initramfs artifact from previous actions workflow
        "-inita")
            if ! MODE="-inita" . ./scripts/isogen/initramfs.sh; then
                return 1
            fi
            ;;
        # Retrieve dropbear-based ssh-enabled-rootfs artifact from previous actions workflow
        "-rootafail")
            if ! MODE="-rootafail". ./scripts/isogen/rootfs.sh; then
                return 1
            fi
            ;;
        # Retrieve qonq-qdb packaging
        "-packaja")
            if ! MODE="-packaja". ./scripts/isogen/packaging.sh; then
                return 1
            fi
            ;;
        # Retrieve beetor_bwc signal-based tracing orchestration from previous actions workflow
        "-sting")
            if ! MODE="-sting" . ./scripts/isogen/beetor.sh; then
                return 1
            fi
            ;;
        # Retrieve runit service tree
        "-itarun")
            if ! MODE="-itarun" . ./scripts/isogen/runit.sh; then
                return 1
            fi
            ;;
        # Bootloaders setup
        "-bootaeloada")
            if ! MODE="-bootaeloada" . ./scripts/isogen/bootloaders.sh; then
                return 1
            fi
            ;;
        # Build ISO9660
        "-isaisa")
            if ! MODE="-isaisa" . ./scripts/isogen/iso9660.sh; then
                return 1
            fi
            ;;
        "*")
            echo && echo "|> Error: ISOGEN_ART is not a valid artifact option. Options are:"
            echo
            echo "Exiting now..."
            echo
            return 1
            ;;
        esac
        echo "|> The artifact ${ISOGEN_ART} was built with success."
        echo

    fi

}

random_mac() {

    #check_shell=$(ps -p $$ | awk "NR==2" | awk '{ print $4 }')

    rh1=$(head -c 64 /dev/urandom | tr -cd 0-9 | head -c 20)
    rh2=$(head -c 64 /dev/urandom | tr -cd 0-9 | head -c 20)
    rh3=$(head -c 64 /dev/urandom | tr -cd 0-9 | head -c 20)
    rh4=$(head -c 64 /dev/urandom | tr -cd 0-9 | head -c 20)

    bubo=$(command -v busybox)
    MACADDRESS=$($bubo printf "52:54:%02x:%02x:%02x:%02x" \
        "$rh1" "$rh2" \
        "$rh3" "$rh4")

    export MACADDRESS
    printf "\n\n%s\n" "${MACADDRESS}"

    # printf -v macaddr "52:54:%02x:%02x:%02x:%02x" \
    #     $(( RANDOM & 0xff )) \
    #     $(( RANDOM & 0xff )) \
    #     $(( RANDOM & 0xff )) \
    #     $(( RANDOM & 0xff ))
}

kjx() {

    # setup the bridge
    . ./scripts/sandbox/net-qemu_myifup.sh

    # bring back connection to the host
    #ip link set enp4s0 nomaster
    #ip link set enp4s0 master vmbr0
    echo "net done"

    # generate a macaddr
    random_mac

    qemu-system-x86_64 \
        -kernel "$HOME/Downloads/kjx-headless/bzImage" \
        -initrd "$HOME/Downloads/kjx-headless/initramfs.cpio.gz" \
        -enable-kvm \
        -m 1024 \
        -append 'console=ttyS0 root=/dev/sda selinux=0 earlyprintk net.ifnames=0' \
        -nographic \
        -no-reboot \
        -drive file="./utils/storage/eulab-hd",format=raw \
        -net nic,model=virtio,macaddr="$macaddr" \
        -net tap,helper=/usr/lib/qemu/qemu-bridge-helper,br=vmbr0 \
        -s -S

}

debug() {

    # setup the bridge
    . ./scripts/sandbox/net-qemu_myifup.sh

    # generate a macaddr
    random_mac

    qemu-system-x86_64 \
        -kernel "$HOME/Downloads/kjx-headless/bzImage" \
        -initrd "$HOME/Downloads/kjx-headless/initramfs.cpio.gz" \
        -enable-kvm \
        -m 1024 \
        -append 'console=ttyS0 root=/dev/sda earlyprintk net.ifnames=0' \
        -nographic \
        -no-reboot \
        -drive file="./utils/storage/eulab-hd",format=raw \
        -net nic,model=virtio,macaddr="$macaddr" \
        -net tap,helper=/usr/lib/qemu/qemu-bridge-helper,br=vmbr0 \
        -s -S
}

thirdver() {

    # setup bridge
    /bin/sh ./scripts/sandbox/net-qemu_myifup.sh bridge
    printf "\n=========\nSetting up the bridge...\n============\n\n"

    # generate a macaddr
    random_mac
    # "$HOME/Downloads/dropbear-image/rootfs-with-ssh.cpio.gz"
    # ./artifacts/distro/mar.initramfs.cpio.gz
    # ./artifacts/distro/mar.initramfs.cpio.gz
    qemu-system-x86_64 \
        -kernel ./artifacts/bzImage \
        -initrd ./artifacts/ssh-rootfs/ssh-rootfs-revised.cpio_0.3.1.gz \
        -enable-kvm \
        -m 1024 \
        -append 'console=ttyS0 root=/dev/sda earlyprintk net.ifnames=0' \
        -nographic \
        -no-reboot \
        -drive file="./utils/storage/eulab-hd",format=raw \
        -net nic,model=virtio,macaddr="$macaddr" \
        -net tap,helper=/usr/lib/qemu/qemu-bridge-helper,br=vmbr0
    #-serial pty
    #-s -S

    # clean up bridge
    /bin/sh ./scripts/sandbox/net-qemu_myifup.sh clean_bridge
    #echo runqemu1

    /bin/sh ./scripts/sandbox/net-qemu_myifup.sh clean_cap
    #echo runqemu2
    #printf "\n=========\nCleaning now...\n============\n"

    #echo HMMMMMMMMM
}

repack_switch() {

    # check for ./.github/workflows/dropbear.yml artifact
    if [ -f ./artifacts/ssh-rootfs/rootfs-with-ssh.cpio.gz ]; then

        # clean the rootfs tree if it exists
        rm -rf ./artifacts/ssh-rootfs/fakerootdir/* &&

            # decompress gunzip and then cpio to the specified path
            gzip -cd ./artifacts/ssh-rootfs/rootfs-with-ssh.cpio.gz | cpio -idmv -D ./artifacts/ssh-rootfs/fakerootdir/

        ssh-keygen -t ed25519 -C "dropbear" -f ./artifacts/ssh-keys/kjx-keys -N ""
        cat ./artifacts/ssh-keys/kjx-keys.pub >>./artifacts/ssh-rootfs/fakerootdir/etc/dropbear/authorized_keys
        #./artifacts/dropbear/~/Downloads/dropbear-image/modified/fakerootdir/etc/dropbear/authorized_keys

        # enter dir just to run find
        cd ./artifacts/ssh-rootfs/fakerootdir/ || return &&

            # patch the specified file with anything
            #
            ROOTFS_SEMVER=0.2.1
        # create revised cpio.gz rootfs tarball
        find . -print0 | busybox cpio --null -ov --format=newc | gzip -9 >../ssh-rootfs-revised.cpio_"$ROOTFS_SEMVER".gz &&
            echo done!!

    else
        printf "\n|> tarball file not found inside ./artifacts/ssh-rootfs. Attempting to download...\n"

        wget
    fi

    echo
}

dropbear() {

    # setup bridge
    #/bin/sh ./scripts/sandbox/net-qemu_myifup.sh bridge

    /bin/sh ./scripts/sandbox/net-qemu_myifup.sh fallin

    printf "\n=========\nSetting up the bridge...\n============\n\n"

    # generate a macaddr
    random_mac
    # "$HOME/Downloads/dropbear-image/rootfs-with-ssh.cpio.gz"
    # ./artifacts/distro/mar.initramfs.cpio.gz
    #  /home/asari/Downloads/initramfs/initramfs.cpio.gz

    DROBE="./artifacts/ssh-rootfs/ssh-rootfs-revised.cpio_0.3.2.gz"
    ANODA="/home/asari/Downloads/kjxh-artifacts/another/rootfs_v13.cpio.gz"

    qemu-system-x86_64 \
        -kernel ./artifacts/bzImage \
        -initrd "$ANODA" \
        -enable-kvm \
        -m 1024 \
        -append 'console=ttyS0 root=/dev/sda earlyprintk net.ifnames=0' \
        -nographic \
        -no-reboot \
        -drive file="./utils/storage/eulab-hd",format=raw \
        -net nic,model=virtio,macaddr="$macaddr" \
        -net tap,helper=/usr/lib/qemu/qemu-bridge-helper,br=vmbr0
    #-serial pty
    #-s -S

    # clean up bridge
    # /bin/sh ./scripts/sandbox/net-qemu_myifup.sh clean_bridge
    /bin/sh ./scripts/sandbox/net-qemu_myifup.sh clean_fallin
    #echo runqemu1

    /bin/sh ./scripts/sandbox/net-qemu_myifup.sh clean_cap
    #echo runqemu2
    #printf "\n=========\nCleaning now...\n============\n"

    #echo HMMMMMMMMM
}

create_rvdsf() {

    # invoke the rvdsf script to create a virtual disk sparse file as needed
    if ! [ -f "${RVDSF_EULAB}" ]; then
        printf "\n|> Error: the Raw Virtual Disk Sparse File (RVDSF) path was not found. Attempting to create it...\n\n"
    fi
    MODE="-sf" LOG_VERBOSE="yes" . ./scripts/isogen/rvdsf.sh

}

save_registry() {
    # Function that saves the registry itself for containerd to be able to serve images in an
    # airgap context inside the ISO. Useful for either DMZ, no WAN or running on a guest without
    # WAN access and without using virtfs.
    # REGISTRY_PULLER() {
    #     CCR_MODE="-checker" . ./scripts/ccr.sh && docker pull registry:3.0
    # }

    # if ! "$REGISTRY_PULLER"; then printf "ERRADO"; fi

    CCR_MODE="-checker"
    export CCR_MODE
    #. ./scripts/ccr.sh || printf "\n|> Error: CCR script has failed! \n" && echo
    #return 1

    # if ! docker pull registry:3.0; then printf "ERRADO"; fi

    if ! . ./scripts/ccr.sh ||
        printf "\n|> Error: CCR script has failed! \n" &&
        podman pull registry:3.0; then
        #docker
        #if ! docker pull registry:3.0; then
        # will raise an "invalid reference format" if using vanilla docker.
        # podman, skopeo and buildah does not have this problem.
        printf "\n|> Error: it was not possible to pull the registry:3.0 OCI image. Exiting now..."
        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: save_registry"
        printf "\n|> CHECK: 01"
        printf "\n|> pull the registry:3.0 OCI image. ...[PASSED]\n"
        ;;
    esac
    printf "\n|> registry:3.0 OCI image pulled with success.\n\n"

    REG_NAME=$(
        #CCR_MODE="-checker" . ./scripts/ccr.sh &&
        #    docker images |
        podman images |
            grep "docker.io" |
            grep "registry" -m 1 |
            awk '{print $3}'
    )

    # echo
    # echo "|> THIS IS REG_NAME=${REG_NAME}"
    # echo

    # convert the registry tarball bundle (continers-storage) to the OCI spec at tmp.
    REGISTRY_NAMING=$(podman images | grep registry | grep docker -m 1 | awk '{print $1}')
    if ! skopeo copy containers-storage:"${REGISTRY_NAMING}:3.0" oci:/tmp/skopeo-test-registry:3.0; then
        printf "\n|> Error: it was not possible to copy the registry image bundle from containers-storage (after pull) to oci bundle at tmp. Exiting now...\n\n"
        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: save_registry"
        printf "\n|> CHECK: 03"
        printf "\n|> convert the registry tarball bundle (continers-storage) to the OCI spec at tmp. ...[PASSED]\n"
        ;;
    esac
    printf "\n|> skopeo-copy the registry OCI image from containers-storage (after pull) format into oci bundle copied with success.\n\n"

    # create a docker-save compliant tarball bundle
    # registry size: at around 56MB
    # skopeo will recognize this as whatis called a "docker-archive"
    # https://github.com/containers/image/blob/main/docs/containers-transports.5.md
    ### if ! podman save -o ./artifacts/oci-registry_3.0_tarball.tar "$REG_NAME"; then
    ###     printf "\n|> Error: it was not possible to create a docker-save compliant tarball bundle (docker-archive format). Exiting now...\n\n"
    ###     return 1
    ### fi
    ### case "${LOG_VERBOSE}" in
    ### "yes")
    ###     printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
    ###     printf "\n|> SCOPE: save_registry"
    ###     printf "\n|> CHECK: 04"
    ###     printf "\n|> fetch tarball.gz image with said version on the filepath. ...[PASSED]\n"
    ###     ;;
    ### esac
    ### printf "\n|> docker-save compliant tarball bundle created with success.\n\n"

    # Check the contents (todo: sha256sum)
    ## if ! tar tf ./artifacts/oci-registry_3.0_tarball.tar | head; then
    ##     printf "\n|> Error: it was not possible to check the contents of the oci registry:3.0 tarball. Exiting now...\n\n"
    ##     return 1
    ## fi
    ## case "${LOG_VERBOSE}" in
    ## "yes")
    ##     printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
    ##     printf "\n|> SCOPE: save_registry"
    ##     printf "\n|> CHECK: 03"
    ##     printf "\n|> check contents of the oci registry:3.0 tarball ...[PASSED]\n"
    ##     ;;
    ## esac
    ## printf "\n|> contents of the oci registry:3.0 tarball checked with success.\n\n"

    ### # convert the docker-save tarball bundle (docker-archive) to OCI spec so it can
    ### if ! skopeo copy docker-archive:./artifacts/oci-registry_3.0_tarball.tar oci:/tmp/skopeo-test-registry:3.0; then
    ###     printf "\n|> Error: it was not possible to conver the docker-save tarball bundle to OCI spec. Exiting now..."
    ###     return 1
    ### fi
    ### case "${LOG_VERBOSE}" in
    ### "yes")
    ###     printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
    ###     printf "\n|> SCOPE: save_registry"
    ###     printf "\n|> CHECK: 04"
    ###     printf "\n|> convert the docker-save tarball bundle (docker-archive) to OCI spec. ...[PASSED]\n"
    ###     ;;
    ### esac
    ### printf "\n|> conversion of the docker-save tarball bundle (docker-archive) to OCI spec was done with success.\n\n"

    # create a rootless umoci-unpack from the containers-storage format directory, which is an unpacked filesystem bundle
    if ! umoci unpack --rootless --image /tmp/skopeo-test-registry:3.0 /tmp/umoci-rootfs; then
        printf "\n|> Error: could not create a rootless umoci-unpack rootfs from the [containers-storage] format directory (the OCI image for the registry:3.0 container's unpacked filesystem bundle). Exiting now..."
        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: save_registry"
        printf "\n|> CHECK: 04"
        printf "\n|> create a rootless umoci-unpack from the [containers-storage] format directory (the OCI image for the registry:3.0 container's unpacked filesystem bundle). ...[PASSED]\n"
        ;;
    esac
    printf "\n|> created a rootless umoci-unpack from the [containers-storage] format directory (the OCI image for the registry:3.0 container's unpacked filesystem bundle) with success.\n\n"

    # list output contents
    ls -allhtr /tmp/skopeo-test-registry

    # create tarball from the containers-storage format unpacked filesystemm bundle
    if ! (tar -C /tmp/skopeo-test-registry -cf "${SKOPEO_TARBALL_ARTIFACT}" .); then
        printf "\n|> Error: could not create tarball from the [containers-storage] format directory (the OCI image for the registry:3.0 container's unpacked filesystem bundle). Exiting now...\n\n"
        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: save_registry"
        printf "\n|> CHECK: 05"
        printf "\n|> created a tarball from the containers-storage format tarball bundle with success. ...[PASSED]\n"
        ;;
    esac
    printf "\n|> created a tarball from the [containers-storage] format directory (the OCI image for the registry:3.0 container's unpacked filesystem bundle) with success.\n\n"

    # cleanup: remove the umoci-rootfs (the unpacked filesystem bundle) directory at tmp
    if [ -d /tmp/umoci-rootfs ]; then
        if ! rm -rf /tmp/umoci-rootfs; then
            printf "\n|> Error: could not remove the the umoci-unpack directory AT TMP-UMOCI-ROOTFS from the [containers-storage] format directory (the OCI image for the registry:3.0 container's unpacked filesystem bundle). Exiting now...\n\n"
            return 1
        fi
        case "${LOG_VERBOSE}" in
        "yes")
            printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
            printf "\n|> SCOPE: save_registry"
            printf "\n|> CHECK: 06"
            printf "\n|> remove the umoci-rootfs runtime bundle artifact dir at tmp. ...[PASSED]\n"
            ;;
        esac
        printf "\n|> removed the umoci-unpack directory AT TMP-UMOCI-ROOTFS from the [containers-storage] format directory (the OCI image for the registry:3.0 container's unpacked filesystem bundle) with success.\n\n"
    fi

    # cleanup: remove the containers-storage format tarball bundle directory
    if [ -d /tmp/skopeo-test-registry ]; then
        if ! rm -rf /tmp/skopeo-test-registry; then
            printf "\n|> Error: could not removed the [containers-storage] format directory (the OCI image for the registry:3.0 container's unpacked filesystem bundle). Exiting now...\n\n"
            return 1
        fi
        case "${LOG_VERBOSE}" in
        "yes")
            printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
            printf "\n|> SCOPE: save_registry"
            printf "\n|> CHECK: 07"
            printf "\n|> remove the [containers-storage] format directory (the OCI image for the registry:3.0 container's unpacked filesystem bundle). ...[PASSED]\n"
            ;;
        esac
        printf "\n|> remove the [containers-storage] format directory (the OCI image for the registry:3.0 container's unpacked filesystem bundle) with success.\n\n"
    fi

}

fetch_k3s() {
    # fetch the base OCI/CRI images for an k3s
    # airgap cluster since it might be inside a DMZ.

    OLD_K3S_VERSION=""
    K3S_VERSION="v1.34.2"

    K3S_AIRGAP_URI="https://github.com/k3s-io/k3s/releases/download/v1.34.2%2Bk3s1/k3s-airgap-images-amd64.tar.gz"
    K3S_AIRGAP_URI_SHA256SUM="https://github.com/k3s-io/k3s/releases/download/v1.34.2%2Bk3s1/k3s-airgap-images-amd64.sha256sum"

    K3S_AIRGAP_PATH="./artifacts/k3s-airgap/outro"
    K3S_AIRGAP_TARBALL_GZ="${K3S_AIRGAP_PATH}/k3s-airgap-images_${K3S_VERSION}-amd64.tar.gz"
    K3S_AIRGAP_TARGZ_SHA256SUM="${K3S_AIRGAP_PATH}/k3s-airgap-images_${K3S_VERSION}-amd64.sha256sum"

    # make sure the k3s airgap path exists
    if ! [ -d "${K3S_AIRGAP_PATH}" ]; then
        mkdir -p "${K3S_AIRGAP_PATH}" &&
            printf "\n|> Creating k3s airgap path...\n\n"
        # idempotent
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: fetch_k3s"
        printf "\n|> CHECK: 01"
        printf "\n|> make sure the k3s airgap path exists...[PASSED]\n"
        ;;
    esac

    # Fetch tarball.gz images and name it with said version
    if ! wget -O "${K3S_AIRGAP_TARBALL_GZ}" "${K3S_AIRGAP_URI}"; then
        printf "\n|> Error: could not download the k3s airgap tarball.gz. Exiting now...\n\n"
        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: fetch_k3s"
        printf "\n|> CHECK: 02"
        printf "\n|> fetch tarball.gz image with said version on the filepath...[PASSED]\n"
        ;;
    esac
    printf "\n|> k3s airgap tarball.gz download has finished.\n\n"

    # Fetch tarball.gz images SHA256SUM and name it with said version
    if ! wget -O "${K3S_AIRGAP_TARGZ_SHA256SUM}" "${K3S_AIRGAP_URI_SHA256SUM}"; then
        printf "\n|> Error: could not download the k3s airgap tarball.gz SHA256SUM. Exiting now...\n\n"
        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: fetch_k3s"
        printf "\n|> CHECK: 03"
        printf "\n|> fetch tarball.gz image SHA256SUM with said version on the filepath...[PASSED]\n"
        ;;
    esac
    printf "\n|> k3s airgap tarball.gz SHA256SUM download has finished.\n\n"

    # Check the SHA256SUM if it is the correct tarball
    cd "${K3S_AIRGAP_PATH}" || return
    FILECHECK=$(sha256sum "${K3S_AIRGAP_TARBALL_GZ}")
    cd - || return

    ORIGINALSHA=$(grep "${K3S_AIRGAP_TARBALL_GZ}" ./artifacts/wget-checksums.txt | awk '{print $1}')

    if ! [ "${FILECHECK}" = "${ORIGINALSHA}" ]; then
        echo "checksum failed: files are different."
        return 1
    fi
    echo "checksum success: files are valid."
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: fetch_k3s"
        printf "\n|> CHECK: 04"
        printf "\n|> check the SHA256SUM if it is the correct tarball...[PASSED]\n"
        ;;
    esac
    printf "\n|> Checksum check was successful.\n\n"

}

squash_k3s() {
    # PS-2: kind of unecessary since with virtio/virtfs
    # the artifact can be shared between host and guest without
    # relying on the qemu device.

    # PS-1: here goes both the airgap images and the registry so containerd can
    # gunzip,
    KJXPATH=$(basename "$PWD")

    SKOPEO_TARBALL_ARTIFACT="/tmp/skopeo-convert-registry.oci.tar"

    # k3s airgap image path and basenames
    K3S_AIRGAP_PATH="./artifacts/k3s-airgap"
    K3S_AIRGAP_TARBALL_GZ="${K3S_AIRGAP_PATH}/k3s-airgap-images-amd64.tar.gz"
    K3S_AIRGAP_TARBALL_GZ_NAME="k3s-airgap-images-amd64.tar.gz"
    K3S_AIRGAP_TAR_NAME="k3s-airgap-images-amd64.tar"

    # /tmp directories to unpack and squashfs
    K3S_UNPACK_TMP="/tmp/k3s-unpack"
    K3S_SQUASHFS_FILE="/tmp/k3s-tarball.squashfs"

    #K3S_SQUASHFS_IMAGE_PATH="./utils/storage/k3s-tarball-squashfs.img"

    # mount point for the k3s-squashfs
    MOUNTPOINT_K3S_SQUASHFS="/mnt/k3s-squashfs"

    # moved to caller scope, on airgap
    # now, the squas_k3s function is called only
    # after the conditional branch for save_registry.
    #
    # if ! [ -f "${SKOPEO_TARBALL_ARTIFACT}" ]; then
    #     printf "\n|> skopeo tarball artifact was not found. Running the [ save_registry ] function now...\n\n"
    #     save_registry
    # fi
    # case "${LOG_VERBOSE}" in
    # "yes")
    #     printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
    #     printf "\n|> SCOPE: squash_k3s"
    #     printf "\n|> CHECK: 01"
    #     printf "\n|> Does the SKOPEO_TARBALL_ARTIFACT filepath exists?...[PASSED]\n\n"
    #     ;;
    # esac

    # check if k3s airgap tarball.gz already exists.
    if ! [ -f "${K3S_AIRGAP_TARBALL_GZ}" ]; then
        printf "\n|> k3s airgap tarball.gz was not found. Attempting to run the [ fetch_k3s ] function now...\n\n"
        fetch_k3s
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: squash_k3s"
        printf "\n|> CHECK: 02"
        printf "\n|> Does the K3S_AIRGAP_TARBALL_GZ filepath exists?...[PASSED]\n\n"
        ;;
    esac

    # check if PWD is the root of the repository
    if ! [ "${KJXPATH}" = "kjx-headless" ]; then
        # printf "\n|> Error: not on the root of the kjx-headless repository. Exiting now..."
        printf "\n|> Error: outside of the path root directory. Exiting now...\n\n"
        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: squash_k3s"
        printf "\n|> CHECK: 03"
        printf "\n|> Is PWD the root of the kjx-headless repository?...[PASSED]\n\n"
        ;;
    esac

    #if [ "${KJXPATH}" = "kjx-headless" ]; then

    # make sure the K3S_UNPACK_TMP directory exists
    mkdir -p "${K3S_UNPACK_TMP}"

    # Copy the save_registry function artifact to the directory
    if ! cp "${SKOPEO_TARBALL_ARTIFACT}" "${K3S_UNPACK_TMP}"; then
        printf "\n|> Error: could not copy save_registry function artifact to the directory "
        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: squash_k3s"
        printf "\n|> CHECK: 05"
        printf "\n|> handle the airgap tarball gzip-ed, gunzip it and finish cleaning. ...[PASSED]\n"
        ;;
    esac
    printf "\n|> Copied the save_registry function artifact to the directory. ...[PASSED]"

    # copy the k3s airgap tarball files into the umoci-unpack
    if ! cp "${K3S_AIRGAP_TARBALL_GZ}" "${K3S_UNPACK_TMP}"; then
        printf "\n|> Error: could not copy the k3s airgap tarball files into the umoci unpack"
        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: squash_k3s"
        printf "\n|> CHECK: 06"
        printf "\n|> handle the airgap tarball gzip-ed, gunzip it and finish cleaning. ...[PASSED]\n"
        ;;
    esac

    cd "${K3S_UNPACK_TMP}" || return

    if ! gunzip -c "${K3S_AIRGAP_TARBALL_GZ_NAME}" >"${K3S_AIRGAP_TAR_NAME}"; then
        printf "\n|> Error: it was not possible to unzip the tar.gz tarball of the K3S_AIRGAP_TARBALL_GZ_NAME. Exiting now...\n\n"
        cd - || return
        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: squash_k3s"
        printf "\n|> CHECK: 07"
        printf "\n|> handle the airgap tarball gzip-ed, gunzip it and finish cleaning. ...[PASSED]\n"
        ;;
    esac

    ls -allhtr "${K3S_AIRGAP_TAR_NAME}"

    if ! rm "${K3S_AIRGAP_TARBALL_GZ_NAME}"; then
        printf "\n|> Error: it was not possible to remove the K3S_AIRGAP_TARBALL_GZ_NAME artifact. Exiting now...\n\n"
        cd - || return
        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: squash_k3s"
        printf "\n|> CHECK: 08"
        printf "\n|> handle the airgap tarball gzip-ed, gunzip it and finish cleaning. ...[PASSED]\n"
        ;;
    esac
    printf "\n|> Removed the K3S_AIRGAP_TARBALL_GZ_NAME artifact. ...[PASSED] \n\n"

    # Exit the dir anyway
    cd - || return

    # Create a mksquashfs from k3s-unpack tmp directory
    if ! mksquashfs "${K3S_UNPACK_TMP}" "${K3S_SQUASHFS_FILE}" -comp zstd; then
        printf "|> Error: it was not possible to create a mksquashfs from the k3s-unpack tmp directory at the %s filepath. Exiting now..." "${K3S_SQUASHFS_FILE:-[EMPTY_VARIABLE]}"
        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: squash_k3s"
        printf "\n|> CHECK: 05"
        printf "\n|> create a mksquashfs from k3s-unpack tmp directory. ...[PASSED]\n"
        ;;
    esac
    printf "\n|> Successfully created a mksquashfs from k3s-unpack tmp directory.\n\n"

    # Create raw image for it to be added as drive input for QEMU
    # with unconditional branch
    if ! [ -d "$(dirname "${K3S_SQUASHFS_IMAGE_PATH}")" ]; then
        printf "\n|> Error: the directory path %s does not exist. Attempting to create dir...\n\n" "$(dirname "${K3S_SQUASHFS_IMAGE_PATH}")"
        mkdir -p "$(dirname "${K3S_SQUASHFS_IMAGE_PATH}")"
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: squash_k3s"
        printf "\n|> CHECK: 06"
        printf "\n|> create the K3S_SQUASHFS_IMAGE_PATH. ...[PASSED]\n"
        ;;
    esac
    printf "\n|> Successfully created the K3S_SQUASHFS_IMAGE_PATH. \n\n"

    # create a raw image with dd.
    if ! dd if=/dev/zero of="${K3S_SQUASHFS_IMAGE_PATH}" bs=1M count=200; then
        printf "|> Error: dd failed with exit code %s. Exiting now...\n" $?
        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: squash_k3s"
        printf "\n|> CHECK: 07"
        printf "\n|> create a raw image with dd. ...[PASSED]\n"
        ;;
    esac
    printf "\n|> Successfully created a raw image with dd.\n\n"

    # format the k3s squashfs image path filename with the ext4 filesystem
    # deps:
    if ! mkfs.ext4 "${K3S_SQUASHFS_IMAGE_PATH}"; then
        printf "|> Error: mkfs.ext4 failed with exit code %s\n" $?
        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: squash_k3s"
        printf "\n|> CHECK: 08"
        printf "\n|> format the k3s squashfs image filepath with the ext4 filesystem. ...[PASSED]\n"
        ;;
    esac
    printf "\n|> Successfully formatted the k3s squashfs image filepath image with a ext4 filesystem with mkfs.ext4.\n\n"

    mkdir -p "${MOUNTPOINT_K3S_SQUASHFS}"

    # Create mountpoint directory and create a loop mount with the k3s squashfs image path
    if ! sudo mount -o loop "${K3S_SQUASHFS_IMAGE_PATH}" "${MOUNTPOINT_K3S_SQUASHFS}"; then
        printf "\n|> Error: it was not possible to create MOUNTPOINT_K3S_SQUASHFS directory and a loop mount of K3S_SQUASHFS_IMAGE_PATH at MOUNTPOINT_K3S_SQUASHFS. Exiting now...\n\n"
        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: squash_k3s"
        printf "\n|> CHECK: 09"
        printf "\n|> create mountpoint dir and a loop mount with the k3s squashfs image path. ...[PASSED]\n"
        ;;
    esac
    echo && echo "|> Successfully created a loop mount of K3S_SQUASHFS_IMAGE_PATH=$K3S_SQUASHFS_IMAGE_PATH at MOUNTPOINT_K3S_SQUASHFS=$MOUNTPOINT_K3S_SQUASHFS."
    echo && echo

    # Copy the K3S_SQUASHFS_FILE to the MOUNTPOINT_K3S_SQUASHFS mount point path
    # available at [/dev/sdb on /mnt/airgap-registry-image type ext4 (rw,relatime)]
    # reference: ./scripts/isogen/poc-bootscript.sh

    ls -allhtr $K3S_SQUASHFS_FILE
    ls -allhtr $MOUNTPOINT_K3S_SQUASHFS
    echo "HEREEEEEEEEEEEEEEEEEEEEE HEEEEEEEEEEEEEEEEEEEEEEEEEEEERE"

    if ! sudo cp "${K3S_SQUASHFS_FILE}" "${MOUNTPOINT_K3S_SQUASHFS}"; then
        echo
        echo "|> Error: it was not possible to copy the K3S_SQUASHFS_FILE=$K3S_SQUASHFS_FILE to the MOUNTPOINT_K3S_SQUASHFS=$MOUNTPOINT_K3S_SQUASHFS. Exiting now..."
        echo && echo
        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: squash_k3s"
        printf "\n|> CHECK 10"
        printf "\n|> copy the K3S_SQUASHFS_FILE to the MOUNTPOINT_K3S_SQUASHFS. ...[PASSED]\n"
        ;;
    esac
    printf "\n|> Successfully copied the K3S_SQUASHFS_FILE to the MOUNTPOINT_K3S_SQUASHFS. \n\n"

    # Copy the K3S_SQUASHFS_FILE to the VIRTFS_ART_PATH mount point path
    # available at [hostshare on /mnt/virtio-test type 9p (rw,relatime,access=client,trans=virtio)
    # reference: ./scripts/isogen/poc-bootscript.sh

    # check permissions
    ls -allhtr $K3S_SQUASHFS_FILE

    if ! sudo cp "${K3S_SQUASHFS_FILE}" "${VIRTFS_ART_PATH}"; then
        echo "|> Error: it was not possible to copy the K3S_SQUASHFS_FILE=$K3S_SQUASHFS_FILE to the VIRTFS_ART_PATH=$VIRTFS_ART_PATH. Exiting now... "
        echo "|> SCOPE: squash_k3s, CHECK: 09"
        echo
        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: squash_k3s"
        printf "\n|> CHECK: 09"
        printf "\n|> copy the K3S_SQUASHFS_FILE to the VIRTFS_ART_PATH. ...[PASSED]\n"
        ;;
    esac
    printf "\n|> Successfully copied the K3S_SQUASHFS_FILE to the VIRTFS_ART_PATH. \n\n"

    # cleanup: artifacts and their directories
    if ! [ -f "${K3S_SQUASHFS_FILE}" ]; then
        if ! rm "${K3S_SQUASHFS_FILE}"; then
            printf "\n|> Error: was not possible to remove %s" $K3S_SQUASHFS_FILE
            return 1
        fi
        echo "|> Removed ${K3S_SQUASHFS_FILE} with success."
    fi
    if [ -d "${K3S_UNPACK_TMP}" ]; then
        if ! rm -rf "${K3S_UNPACK_TMP}"; then
            printf "\n|> Error: it was not possible to remove %s" $K3S_UNPACK_TMP
            return 1
        fi
        echo "|> Removed ${K3S_UNPACK_TMP} with success."
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: squash_k3s"
        printf "\n|> CHECK 10"
        printf "\n|> clean artifacts. ...[PASSED]\n"
        ;;
    esac
    printf "\n|> Successfully cleaned the artifacts.\n\n"

    # cleanup: unmount loopback device
    if ! (sudo umount "${MOUNTPOINT_K3S_SQUASHFS}"); then
        printf "\n|> Error: it was not possible to unmount the loopback device. Exiting now..."
        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: squash_k3s"
        printf "\n|> CHECK 11"
        printf "\n|> unmount loopback device. ...[PASSED]\n"
        ;;
    esac
    printf "\n|> Successfully unmounted the loopback device.\n\n"

    #else
    #    printf "\n|> Error: outside of the path root directory. Exiting now...\n\n"
    #fi

}

# Function to manually test configuration
# with an airgap k3s build.
# todo: virtfs
airgap_k3s() {

    #K3S_SQUASHFS_IMAGE_PATH="./utils/storage/k3s-tarball-squashfs.img"

    # Setup bridge
    /bin/sh ./scripts/sandbox/net-qemu_myifup.sh fallin

    printf "\n=========\nSetting up the bridge...\n============\n\n"

    # Generate a macaddr
    if ! random_mac; then
        printf "\n|> It was not possible to generate a macaddr. Exiting now..."
        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: airgap_k3s"
        printf "\n|> CHECK: 01"
        printf "\n|> Generating a macaddr... [PASSED]\n"
        ;;
    esac
    printf "\n|> macaddr generated with success.\n\n"

    # check if PWD is the root of the repository
    if ! [ "${KJXPATH}" = "kjx-headless" ]; then
        printf "|> Error: not on the root of the kjx-headless repository. Change dir and try again.\nExiting now...\n\n"
        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: airgap_k3s"
        printf "\n|> CHECK: 02"
        printf "\n|> Is PWD the root of the repository?... [PASSED]\n"
        ;;
    esac
    printf "\n|> success: the PWD DOES correspond to the root of the repository.\n\n"

    # independent call to save_registry
    if ! [ -f "${SKOPEO_TARBALL_ARTIFACT}" ]; then
        printf "\n|> skopeo tarball artifact was not found. Calling the [ save_registry ] function now...\n\n"
        if ! save_registry; then
            printf "\n|> Error: it was not possible to call [save_registry] and create the SKOPEO_TARBALL_ARTIFACT."
            return 1
        fi
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: airgap_k3s"
        printf "\n|> CHECK: 03"
        printf "\n|> Does the SKOPEO_TARBALL_ARTIFACT filepath exists?...[PASSED]\n"
        ;;
    esac
    printf "\n|> success: the SKOPEO_TARBALL_ARTIFACT filepath exists.\n\n"

    # it will only run if the k3s squashfs image does not exist.
    #if [ "${KJXPATH}" = "kjx-headless" ]; then
    # Check if raw image exists at utils

    if ! [ -f "${K3S_SQUASHFS_IMAGE_PATH}" ]; then
        #&& ! [ -f "${SKOPEO_TARBALL_ARTIFACT}" ]; then
        # Check if Skopeo OCI conversion image artifact exists
        # so it gets generated every run as needed
        printf "\n|> Error: the filepath %s does not exist. Attempting to create it..." "${K3S_SQUASHFS_IMAGE_PATH:-[EMPTY_VARIABLE]}"
        #"${SKOPEO_TARBALL_ARTIFACT:-[EMPTY_VARIABLE]}"

        if ! squash_k3s; then
            echo && echo "|> SCOPE: airgap_k3s, CHECK: 04"
            echo "|> Error: it was not possible to create the K3S_SQUASHFS_IMAGE_PATH=$K3S_SQUASHFS_IMAGE_PATH filepath. Exiting now..."
            echo
            return 1
        fi
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: airgap_k3s"
        printf "\n|> CHECK: 04"
        printf "\n|> check if raw image exists at utils. ... [PASSED]\n"
        ;;
    esac
    printf "\n|> success: the raw image DOES exists at utils.\n\n"

    # Check if raw virtual disk sparse file exists at utils
    #if ! [ -f "${RVDSF_EULAB}" ]; then
    #    printf "\n|> Error: raw virtual disk sparse file does not exist. Attempting to create now..."

    if ! create_rvdsf; then
        printf "\n|> Error: the Raw Virtual Disk Sparse File (RVDSF) path was not found. Attempting to create it...\n\n"
        return 1
    fi
    #fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: airgap_k3s"
        printf "\n|> CHECK: 04"
        printf "\n|> Does RVDSF filepath exists?...[PASSED]\n"
        ;;
    esac
    printf "\n|> checked if the RVDSF filepath exists.\n\n"

    ######## ANODA ###########
    #
    # PS: ANODA is the initramfs.cpio.gz that serves temporarily as a rootfs
    #
    # v13: This one enables cgroupsv2 only, without cgroupsv1
    #   rootfs_v13.cpio.gz"
    #
    # v14: This one have containerd dynamically linked against musl
    #   rootfs_v14.cpio.gz"
    #
    # v15: This one have fuse-overlayfs
    #   rootfs_v15.cpio.gz"
    #
    # v16-v25: These already one have bpftrace
    #   rootfs_v16.cpio.gz
    #   ...
    #   ...
    #   rootfs_v25.cpio.gz

    # v26: New kernel modules properly setup
    #   rootfs_v26.cpio.gz"

    # v27: gvisor runsv, kata and crun binaries enabled
    #   rootfs_v27.cpio.gz"

    CALL_TO_QONQ_QDB() {
        echo "Dependencies for the initramfs and rootfs"
    }

    # v28: Full podman dynamic binaries and shared objects
    ANODA_INITRAMFS="/home/asari/Downloads/kjxh-artifacts/another/rootfs_v28.cpio.gz"
    if ! [ -f "${ANODA_INITRAMFS}" ]; then
        printf "\n|> Error: missing initramfs.cpio.gz (passing as a rootfs) - Not found in given path!\n\n"
        printf "\n|> Exiting now...\n\n"

        # call the initramfs.cpio.gz builder function
        ISOGEN_ART="initramfs"
        export ISOGEN_ART
        if ! artifacts_builder; then
            echo && echo "|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
            echo "|> SCOPE: from airgap_k3s, calling artifacts_builder with ISOGEN_ART=$ISOGEN_ART"
            echo
            return 1
        fi
        case "${LOG_VERBOSE}" in
        "yes")
            printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
            echo "|> SCOPE: from airgap_k3s, calling artifacts_builder with ISOGEN_ART=$ISOGEN_ART"
            echo "|> call the initramfs.cpio.gz builder function (airgap_k3s) with ISOGEN_ART=$ISOGEN_ART . ...[PASSED]"
            echo
            ;;
        esac
        printf "\n|> the initramfs.cpio.gz do in fact exist.\n\n"

        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: airgap_k3s"
        printf "\n|> CHECK: 05"
        printf "\n|> check if the initramfs.cpio.gz exists ...[PASSED]\n"
        ;;
    esac
    printf "\n|> the initramfs.cpio.gz do in fact exist.\n\n"

    # PS: this kernel image needs to have the kernel modules *.ko,
    # then squashfs, memcg, fuse, overlayfs support.
    # Also user namagement (shadow-setup) and iptables related (iptales-setup) configuration
    MANUAL_AIRGAP_BZIMAGE="$HOME/Downloads/kjxh-artifacts/10_fuse-support/bzImage"
    if ! [ -f "${MANUAL_AIRGAP_BZIMAGE}" ]; then
        printf "\n|> Error: missing bzImage kernel - Not found in given path!\n\n"

        ISOGEN_ART="-buildakernel"
        export ISOGEN_ART
        if ! artifacts_builder; then
            echo && echo "|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
            echo "|> SCOPE: from airgap_k3s, calling artifacts_builder with ISOGEN_ART=$ISOGEN_ART"
            echo
            return 1
        fi
        printf "\n|> Exiting now...\n\n"
        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: airgap_k3s"
        printf "\n|> CHECK: 06"
        printf "\n|> setup the kernel bzImage with some kernel modules and other k3s dependencies.  ...[PASSED]\n"
        ;;
    esac
    printf "\n|> checked for kernel modules and other k3s dependencies on the kernel bzImage. \n\n"

    # create the virtfs directory path to be shared between host and guest
    # if ! [ -d "${VIRTFS_ART_PATH}" ]; then
    #     mkdir -p "${VIRTFS_ART_PATH}" &&
    #         printf "\n|> Creating virtfs artifact directory...\n\n"
    # f
    # idempotent
    if ! mkdir -p "${VIRTFS_ART_PATH}"; then
        printf "\n|> Creating virtfs artifact directory...\n\n"
        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: airgap_k3s"
        printf "\n|> CHECK: 07"
        printf "\n|> Create the virtfs directory path to be shared between host and guest. ...[PASSED]\n"
        ;;
    esac
    printf "\n|> created the virtfs directory to be shared between host and guest. \n\n"

    # Copy the registry to serve the images locally to the single-node k3s cluster
    if ! cp "${SKOPEO_TARBALL_ARTIFACT}" "${VIRTFS_ART_PATH}"; then
        printf "\n|>SCOPE: airgap_k3s, file: [./scripts/sandbox/run-qemu.sh], CHECK: 08"
        printf "\n|> Error: could not copy the SKOPEO_TARBALL_ARTIFACT into the VIRTFS_ART_PATH. Exiting now... \n\n"
        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|>SCOPE: airgap_k3s, file: [./scripts/sandbox/run-qemu.sh], CHECK: 08"
        printf "\n|> copy the registry to serve the images locally to the single-node k3s cluster. ...[PASSED]\n"
        ;;
    esac
    printf "\n|> copied the registry tarball into the virtfs directory successfully. \n\n"

    if ! sudo cp "${K3S_SQUASHFS_FILE}" "${VIRTFS_ART_PATH}"; then
        echo
        echo "|> Error: it was not possible to copy the [K3S_SQUASHFS_FILE=${K3S_SQUASHFS_FILE:-[EMPTY_VARIABLE]} to the [VIRTFS_ART_PATH=${VIRTFS_ART_PATH:-[EMPTY_VARIABLE]}]. Exiting now..."
        printf "\n|>SCOPE: airgap_k3s, file: [./scripts/sandbox/run-qemu.sh], check: 09"
        printf "\n|> SCOPE: airgap_k3s"
        printf "\n|> CHECK: 09"
        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: airgap_k3s"
        printf "\n|> CHECK: 09"
        printf "\n|> copy the K3S_SQUASHFS_FILE to the VIRTFS_ART_PATH. ...[PASSED]\n"
        ;;
    esac
    printf "\n|> Successfully copied the K3S_SQUASHFS_FILE to the VIRTFS_ART_PATH. \n\n"

    # ================================
    # Microvms
    #
    # ================================
    # # returns if the [MICROVM_FIRECRACKER_TARBALL] filepath does not exist
    ### if ! [ -f ${MICROVM_FIRECRACKER_TARBALL:-[EMPTY_VARIABLE]} ]; then
    ###     echo "|> Warning: MICROVM_FIRECRACKER_TARBALL=${MICROVM_FIRECRACKER_TARBALL} does not exist in this filepath. Attempting to generate it:"
    ###     echo && echo
    ###     #return 1
    ###     if ! microvm_poc_firecracker; then
    ###         echo "|> Error: could not run the [microvm_poc_firecracker] function! Exiting now..."
    ###         echo && echo
    ###         return 1
    ###     fi
    ### fi
    ### case "${LOG_VERBOSE}" in
    ### "yes")
    ###     printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
    ###     printf "\n|> SCOPE: airgap_k3s, CHECK: 10\n"
    ###     echo "|> create the MICROVM_FIRECRACKER_TARBALL=${MICROVM_FIRECRACKER_TARBALL} filepath. ...[PASSED]"
    ###     echo && echo
    ###     ;;
    ### esac
    ### echo "|> Successfully created the [MICROVM_FIRECRACKER_TARBALL=${MICROVM_FIRECRACKER_TARBALL:-[EMPTY_VARIABLE]}] filepath."

    # returns if the [MICROVM_GVISOR_TARBALL] filepath does not exist
    if ! [ -f "${MICROVM_GVISOR_TARBALL:-[EMPTY_VARIABLE]}" ]; then
        echo "|> Warning: MICROVM_GVISOR_TARBALL=$MICROVM_GVISOR_TARBALL does not exist in this filepath. Attempting to generate it:"
        echo && echo
        #return 1
        if ! microvm_poc_gvisor; then
            echo "|> Error: could not run the [microvm_poc_gvisor] function! Exiting now..."
            echo && echo
            return 1
        fi
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: airgap_k3s, CHECK: 10\n"
        echo "|> create the MICROVM_GVISOR_TARBALL=$MICROVM_GVISOR_TARBALL filepath. ...[PASSED]"
        echo && echo
        ;;
    esac
    echo "|> Successfully created the [MICROVM_GVISOR_TARBALL=${MICROVM_GVISOR_TARBALL:-[EMPTY_VARIABLE]}] filepath."

    # Will only run if the previous work.
    # Copy MICROVM_GVISOR_TARBALL to the VIRTFS_ART_PATH
    if ! cp "${MICROVM_GVISOR_TARBALL}" "${VIRTFS_ART_PATH}"; then
        echo "|> Error: it was not possible to copy the MICROVM_GVISOR_TARBALL=$MICROVM_GVISOR_TARBALL to the VIRTFS_ART_PATH=$VIRTFS_ART_PATH. Exiting now... "
        echo && echo
        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: airgap_k3s, CHECK: 11\n"
        echo "|> copy the MICROVM_GVISOR_TARBALL=$MICROVM_GVISOR_TARBALL to the VIRTFS_ART_PATH=$VIRTFS_ART_PATH. ...[PASSED]"
        echo && echo
        ;;
    esac
    echo "|> Successfully copied the MICROVM_GVISOR_TARBALL=$MICROVM_GVISOR_TARBALL to the VIRTFS_ART_PATH=$VIRTFS_ART_PATH."
    echo && echo

    # =======================
    # TRACERS: BPFTRACE
    #
    # returns if the [TRACERS_BPFTRACE_TARBALL] filepath does not exist
    if ! [ -f ${TRACERS_BPFTRACE_TARBALL:-[EMPTY_VARIABLE]} ]; then
        echo "|> Warning: TRACERS_BPFTRACE_TARBALL=${TRACERS_BPFTRACE_TARBALL:-[EMPTY_VARIABLE]} does not exist in this filepath. Attempting to generate it:"
        echo && echo
        #return 1
        if ! (MODE="bpftrace" . ./scripts/entrypoints/tracers-aio.sh); then
            echo "|> Error: could not run the [tracers-aio.sh] script to build [bpftrace] tarball! Exiting now..."
            echo && echo
            return 1
        fi
        echo "|> Sucessfully called the [tracers-aio.sh] script to build [bpftrace] tarball! ...[PASSED]"
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: airgap_k3s, CHECK: 12\n"
        echo "|> create the TRACERS_BPFTRACE_TARBALL=${TRACERS_BPFTRACE_TARBALL:-[EMPTY_VARIABLE]} filepath. ...[PASSED]"
        echo && echo
        ;;
    esac
    echo "|> Successfully created the [TRACERS_BPFTRACE_TARBALL=${TRACERS_BPFTRACE_TARBALL:-[EMPTY_VARIABLE]}] filepath."

    if ! (cp "${TRACERS_BPFTRACE_TARBALL:-[EMPTY_VARIABLE]}" "${VIRTFS_ART_PATH:-[EMPTY_VARIABLE]}"); then
        echo "|> Error: it was not possible to copy the TRACERS_BPFTRACE_TARBALL=${TRACERS_BPFTRACE_TARBALL:-[EMPTY_VARIABLE]} to the VIRTFS_ART_PATH=${VIRTFS_ART_PATH:-[EMPTY_VARIABLE]}. Exiting now... "
        echo && echo
        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: airgap_k3s, CHECK: 13\n"
        echo "|> copy the TRACERS_BPFTRACE_TARBALL=${TRACERS_BPFTRACE_TARBALL:-[EMPTY_VARIABLE]} to the VIRTFS_ART_PATH=${VIRTFS_ART_PATH:-[EMPTY_VARIABLE]}. ...[PASSED]"
        echo && echo
        ;;
    esac
    echo "|> Successfully copied the [TRACERS_BPFTRACE_TARBALL=${TRACERS_BPFTRACE_TARBALL:-[EMPTY_VARIABLE]}] to the [VIRTFS_ART_PATH=${VIRTFS_ART_PATH:-[EMPTY_VARIABLE]}]."
    echo && echo

    # =======================
    # PACKAGING: IPTABLES
    #
    # returns if the [PACKAGING_IPTABLES_TARBALL] filepath does not exist
    if ! [ -f ${PACKAGING_IPTABLES_TARBALL:-[EMPTY_VARIABLE]} ]; then
        echo "|> Warning: PACKAGING_IPTABLES_TARBALL=${PACKAGING_IPTABLES_TARBALL:-[EMPTY_VARIABLE]} does not exist in this filepath. Attempting to generate it:"
        echo && echo
        #return 1
        if ! (MODE="iptables" . ./scripts/packages/usgp-man.sh); then
            echo "|> Error: could not run the [usgp-man.sh] script to build [iptables] tarball! Exiting now..."
            echo && echo
            return 1
        fi
        echo "|> Sucessfully called the [usgp-man.sh] script to build [iptables] tarball! ...[PASSED]"
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: airgap_k3s, CHECK: 13\n"
        echo "|> create the PACKAGING_IPTABLES_TARBALL=${PACKAGING_IPTABLES_TARBALL:-[EMPTY_VARIABLE]} filepath. ...[PASSED]"
        echo && echo
        ;;
    esac
    echo "|> Successfully created the [PACKAGING_IPTABLES_TARBALL=${PACKAGING_IPTABLES_TARBALL:-[EMPTY_VARIABLE]}] filepath."

    if ! (cp "${PACKAGING_IPTABLES_TARBALL:-[EMPTY_VARIABLE]}" "${VIRTFS_ART_PATH:-[EMPTY_VARIABLE]}"); then
        echo "|> Error: it was not possible to copy the PACKAGING_IPTABLES_TARBALL=${PACKAGING_IPTABLES_TARBALL:-[EMPTY_VARIABLE]} to the VIRTFS_ART_PATH=${VIRTFS_ART_PATH:-[EMPTY_VARIABLE]}. Exiting now... "
        echo && echo
        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: airgap_k3s, CHECK: 14\n"
        echo "|> copy the PACKAGING_IPTABLES_TARBALL=${PACKAGING_IPTABLES_TARBALL:-[EMPTY_VARIABLE]} to the VIRTFS_ART_PATH=${VIRTFS_ART_PATH:-[EMPTY_VARIABLE]}. ...[PASSED]"
        echo && echo
        ;;
    esac
    echo "|> Successfully copied the [PACKAGING_IPTABLES_TARBALL=${PACKAGING_IPTABLES_TARBALL:-[EMPTY_VARIABLE]}] to the [VIRTFS_ART_PATH=${VIRTFS_ART_PATH:-[EMPTY_VARIABLE]}]."
    echo && echo

    # =====================
    # PACKAGING: SHADOW

    # returns if the [PACKAGING_SHADOW_TARBALL] filepath does not exist
    if ! [ -f ${PACKAGING_SHADOW_TARBALL:-[EMPTY_VARIABLE]} ]; then
        echo "|> Warning: PACKAGING_SHADOW_TARBALL=${PACKAGING_SHADOW_TARBALL:-[EMPTY_VARIABLE]} does not exist in this filepath. Attempting to generate it:"
        echo && echo
        #return 1
        if ! (MODE="shadow" . ./scripts/packages/usgp-man.sh); then
            echo "|> Error: could not run the [usgp-man.sh] script to build [shadow] tarball! Exiting now..."
            echo && echo
            return 1
        fi
        echo "|> Sucessfully called the [usgp-man.sh] script to build [shadow] tarball! ...[PASSED]"
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: airgap_k3s, CHECK: 15\n"
        echo "|> create the PACKAGING_SHADOW_TARBALL=${PACKAGING_SHADOW_TARBALL:-[EMPTY_VARIABLE]} filepath. ...[PASSED]"
        echo && echo
        ;;
    esac
    echo "|> Successfully created the [PACKAGING_SHADOW_TARBALL=${PACKAGING_SHADOW_TARBALL:-[EMPTY_VARIABLE]}] filepath."

    if ! (cp "${PACKAGING_SHADOW_TARBALL:-[EMPTY_VARIABLE]}" "${VIRTFS_ART_PATH:-[EMPTY_VARIABLE]}"); then
        echo "|> Error: it was not possible to copy the PACKAGING_SHADOW_TARBALL=${PACKAGING_SHADOW_TARBALL:-[EMPTY_VARIABLE]} to the VIRTFS_ART_PATH=${VIRTFS_ART_PATH:-[EMPTY_VARIABLE]}. Exiting now... "
        echo && echo
        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: airgap_k3s, CHECK: 16\n"
        echo "|> copy the PACKAGING_SHADOW_TARBALL=${PACKAGING_SHADOW_TARBALL:-[EMPTY_VARIABLE]} to the VIRTFS_ART_PATH=${VIRTFS_ART_PATH:-[EMPTY_VARIABLE]}. ...[PASSED]"
        echo && echo
        ;;
    esac
    echo "|> Successfully copied the [PACKAGING_SHADOW_TARBALL=${PACKAGING_SHADOW_TARBALL:-[EMPTY_VARIABLE]}] to the [VIRTFS_ART_PATH=${VIRTFS_ART_PATH:-[EMPTY_VARIABLE]}]."
    echo && echo

    # Copy the POC_BOOTSCRIPT to the VIRTFS_ART_PATH so it becomes available on the guest vm
    if ! cp "${POC_BOOTSCRIPT}" "${VIRTFS_ART_PATH}"; then
        echo "|> Error: it was not possible to copy the POC_BOOTSCRIPT=${POC_BOOTSCRIPT:-[EMPTY_VARIABLE]} to the VIRTFS_ART_PATH=${VIRTFS_ART_PATH:-EMPTY_VARIABLE}. Exiting now... "
        echo && echo
        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: airgap_k3s, CHECK: 17\n"
        echo "|> copy the POC_BOOTSCRIPT=${POC_BOOTSCRIPT:-[EMPTY_VARIABLE]} to the VIRTFS_ART_PATH=${VIRTFS_ART_PATH:-[EMPTY_VARIABLE]}. ...[PASSED]"
        echo && echo
        ;;
    esac
    echo "|> Successfully copied the POC_BOOTSCRIPT=${POC_BOOTSCRIPT:-[EMPTY_VARIABLE]} to the VIRTFS_ART_PATH=${VIRTFS_ART_PATH:-[EMPTY_VARIABLE]} ."
    echo && echo

    # Either copy the k3s-squashfs tarball OR the k3s-squashfs image into the VIRTFS_ART_PATH
    # (./scripts/isogen/demo.sh's squash_k3s)
    # (./scripts/sandbox/run-qemu.sh's squash_k3s)

    # Mind that this will need fuse-overlayfs since the -initrd flag
    # runs an initramfs.cpio.gz over ramfs/tmpfs, that is, on RAM, and not
    # in a filesystem storage. For overlayfs only, use the ISO.
    qemu-system-x86_64 \
        -kernel "${MANUAL_AIRGAP_BZIMAGE}" \
        -initrd "${ANODA_INITRAMFS}" \
        -enable-kvm \
        -m 3072 \
        -append 'console=ttyS0 root=/dev/sda earlyprintk net.ifnames=0 cgroup_no_v1=all' \
        -nographic \
        -no-reboot \
        -drive file="${RVDSF_EULAB}",format=raw \
        -drive file="${K3S_SQUASHFS_IMAGE_PATH}",format=raw \
        -net nic,model=virtio,macaddr="${MACADDRESS}" \
        -net tap,helper=/usr/lib/qemu/qemu-bridge-helper,br=vmbr0 \
        -virtfs local,path="${VIRTFS_ART_PATH}",mount_tag=hostshare,security_model=mapped-xattr
    # -virtfs local,path="./artifacts/qemu-sink/",security_model=mapped-xattr \
    #-serial
    # -s -S
    #-serial pty
    #-s -S

    # clean up bridge
    if ! (/bin/sh ./scripts/sandbox/net-qemu_myifup.sh clean_fallin); then
        printf "\n|> Error: it was not possible to cleanup the bridge. Exiting now...\n\n"
        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: airgap_k3s"
        printf "\n|> CHECK: 07"
        printf "\n|> cleanup the bridge.  ...[PASSED]\n"
        ;;
    esac
    printf "\n|> cleaning up the bridge.\n\n"

    # clean capabilities
    if ! (/bin/sh ./scripts/sandbox/net-qemu_myifup.sh clean_cap); then
        printf "\n|> Error: it was not possible to cleanup the capabilities. Exiting now...\n\n"
        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> FUNCTION CALL: ./scripts/sandbox/run-qemu.sh"
        printf "\n|> SCOPE: airgap_k3s"
        printf "\n|> CHECK: 08"
        printf "\n|> cleanup the capabilities.  ...[PASSED]\n"
        ;;
    esac
    printf "\n|> cleaning up the capabilities.\n\n"

}

configure_vm_ssh() {

    ssh-keygen -t ed25519 -f ~/.ssh/qemu_vm_key -N ""

}

# run the final iso artifact (POC)
## the ISO artifact will not include every option,
## just the default distro, relying into virtfs instead.
runiso() {

    CURRENT_ISO="./artifacts/kjx-headless_v3.iso"
    OLD_ISO="./artifacts/kjx-headless.iso"

    # check if PWD is the root of the repository
    if ! [ "${KJXPATH}" = "kjx-headless" ]; then
        printf "|> Error: not on the root of the kjx-headless repository. Change dir and try again.\nExiting now...\n\n"
        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> Is PWD the root of the repository?... [PASSED]\n"
        echo "|> SCOPE: [runiso], file [./scripts/sandbox/run-qemu.sh]; check: 01"
        ;;
    esac
    printf "\n|> success: the PWD DOES correspond to the root of the repository.\n\n"
    echo "|> SCOPE: [runiso], file [./scripts/sandbox/run-qemu.sh]; check: 01"

    # independent call to save_registry
    if ! [ -f "${SKOPEO_TARBALL_ARTIFACT}" ]; then
        printf "\n|> skopeo tarball artifact was not found. Calling the [ save_registry ] function now...\n\n"
        if ! save_registry; then
            printf "\n|> Error: it was not possible to call [save_registry] and create the SKOPEO_TARBALL_ARTIFACT."
            return 1
        fi
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> Does the SKOPEO_TARBALL_ARTIFACT filepath exists?...[PASSED]\n"
        echo "|> SCOPE: [runiso], file [./scripts/sandbox/run-qemu.sh]; check: 02"
        ;;
    esac
    printf "\n|> success: the SKOPEO_TARBALL_ARTIFACT filepath exists.\n\n"
    echo "|> SCOPE: [runiso], file [./scripts/sandbox/run-qemu.sh]; check: 02"

    if ! [ -f "${K3S_SQUASHFS_IMAGE_PATH}" ]; then
        printf "\n|> Error: the filepath %s does not exist. Attempting to create it..." "${K3S_SQUASHFS_IMAGE_PATH:-[EMPTY_VARIABLE]}"

        if ! squash_k3s; then
            echo "|> Error: it was not possible to create the $K3S_SQUASHFS_IMAGE_PATH filepath. Exiting now..."
            echo "|> SCOPE: [runiso], file [./scripts/sandbox/run-qemu.sh]; check: 03"
            return 1
        fi
        echo "|> Sucessfully created the $K3S_SQUASHFS_IMAGE_PATH filepath. Exiting now..."
        echo "|> SCOPE: [runiso], file [./scripts/sandbox/run-qemu.sh]; check: 03"
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> check if raw image exists at utils. ... [PASSED]\n"
        echo "|> SCOPE: [runiso], file [./scripts/sandbox/run-qemu.sh]; check: 03"
        ;;
    esac
    printf "\n|> success: the raw image DOES exists at utils.\n\n"
    echo "|> SCOPE: [runiso], file [./scripts/sandbox/run-qemu.sh]; check: 03"

    # Check if raw virtual disk sparse file exists at utils
    if ! create_rvdsf; then
        printf "\n|> Error: the Raw Virtual Disk Sparse File (RVDSF) path was not found. Attempting to create it...\n\n"
        return 1
    fi
    #fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> Does RVDSF filepath exists?...[PASSED]\n"
        echo "|> SCOPE: [runiso], file [./scripts/sandbox/run-qemu.sh]; check: 04"
        ;;
    esac
    printf "\n|> checked if the RVDSF filepath exists.\n\n"
    echo "|> SCOPE: [runiso], file [./scripts/sandbox/run-qemu.sh]; check: 04"

    # create the virtfs directory path to be shared between host and guest
    if ! [ -d "${VIRTFS_ART_PATH}" ]; then
        mkdir -p "${VIRTFS_ART_PATH}" &&
            printf "\n|> Creating virtfs artifact directory...\n\n"
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> Create the virtfs directory path to be shared between host and guest. ...[PASSED]\n"
        echo "|> SCOPE: [runiso], file [./scripts/sandbox/run-qemu.sh]; check: 05"
        ;;
    esac
    printf "\n|> created the virtfs directory to be shared between host and guest. \n\n"
    echo "|> SCOPE: [runiso], file [./scripts/sandbox/run-qemu.sh]; check: 05"

    # Copy the registry to serve the images locally to the single-node k3s cluster
    if ! cp "${SKOPEO_TARBALL_ARTIFACT}" "${VIRTFS_ART_PATH}"; then
        printf "\n|> Error: could not copy the SKOPEO_TARBALL_ARTIFACT into the VIRTFS_ART_PATH. Exiting now... \n\n"
        echo "|> SCOPE: [runiso], file [./scripts/sandbox/run-qemu.sh]; check: 06"
        return 1
    fi
    case "${LOG_VERBOSE}" in
    "yes")
        printf "\n|> copy the registry to serve the images locally to the single-node k3s cluster. ...[PASSED]\n"
        echo "|> SCOPE: [runiso], file [./scripts/sandbox/run-qemu.sh]; check: 06"
        ;;
    esac
    printf "\n|> copied the registry tarball into the virtfs directory successfully. \n\n"

    mkdir -p ./artifacts/burn-runiso

    if ! prepare_rootfs; then
        echo "|> Error: could not run the function [prepare_rootfs]. Exiting now..."
        echo "|> SCOPE: [runiso], file [./scripts/sandbox/run-qemu.sh]; check: 07"
        return 1
    fi
    echo "|> Sucessfully ran the function [prepare_rootfs]. Proceeding..."
    echo "|> SCOPE: [runiso], file [./scripts/sandbox/run-qemu.sh]; check: 07"

    ### # it will only run if the k3s squashfs image does not exist.
    ### if [ "${KJXPATH}" = "kjx-headless" ]; then
    ###     # Check if raw image exists at utils
    ###     if ! [ -f "${K3S_SQUASHFS_IMAGE_PATH}" ]; then
    ###         squash_k3s
    ###     fi

    ###     # Check if raw virtual disk sparse file exists at utils
    ###     if ! [ -f "${RVDSF_EULAB}" ]; then
    ###         create_rvdsf
    ###     fi
    ### fi

    qemu-system-x86_64 \
        -m 1024 \
        -cdrom "${CURRENT_ISO}" \
        -boot d \
        -enable-kvm \
        -nographic \
        -no-reboot \
        -cpu host \
        -serial mon:stdio \
        -drive file="${RVDSF_EULAB}",format=raw \
        -drive file="${K3S_SQUASHFS_IMAGE_PATH}",format=raw \
        -virtfs local,path="${VIRTFS_ART_PATH}",mount_tag=hostshare,security_model=mapped-xattr

}

record_airgap() {
    # creates a file at "${AIRGAP_RECORDING_PATH}"
    IS_RECORDING="YES"

    if [ "${IS_RECORDING}" = "YES" ]; then
        if ! command -v asciinema; then
            printf "\n|> Error: asciinema was not found. Nothing to be done.\n|> Exiting now...\n\n" &&
                return 1
        fi
        printf "\n|> Recording section is in course. Invoking asciinema...\n\n" &&
            asciinema rec "${AIRGAP_RECORDING_PATH}" --command="make airgap" &&

            #if [ "${IS_RECORDING}" = "YES" ]; then
            # asciinema stop && \
            exec <&- &&
            printf "\n|> Stop recording the asciinema section. Exiting now...\n\n"
        #fi
    fi

    # runiso

}

record_runiso() {
    # creates a file at "${RUNISO_RECORDING_PATH}"
    IS_RECORDING="YES"

    if [ "${IS_RECORDING}" = "YES" ]; then
        if ! command -v asciinema; then
            printf "\n|> Error: asciinema was not found. Nothing to be done.\n|> Exiting now...\n\n" &&
                return 1
        fi
        printf "\n|> Recording section is in course. Invoking asciinema...\n\n" &&
            asciinema rec "${RUNISO_RECORDING_PATH}" --command="make runiso" &&

            #if [ "${IS_RECORDING}" = "YES" ]; then
            # asciinema stop && \
            exec <&- &&
            printf "\n|> Stop recording the asciinema section. Exiting now...\n\n"
        #fi
    fi

    # runiso

}

print_usage() {
    cat <<-END >&2
USAGE: run-qemu [-options]
                - thirdver
                - dropbear
                - debug
                - help
                - version
eg,
run-qemu -thirdver   # runs qemu pointing to a custom initramfs and kernel bzImage
run-qemu -dropbear  # runs qemu enabled with ssh for quick file copying between target vm and host
run-qemu -airgap  # runs qemu with files to run k3s air-gapped
run-qemu -debug # the same of thirdver but with serial and pty flags for kernel debug
run-qemu -help    # shows this help message
run-qemu -version # shows script version

See the man page and example file for more info.

END

}

# Check the argument passed from the command line
if [ "${MODE}" = "firstver" ]; then
    firstver
elif [ "${MODE}" = "macaddr" ]; then
    macaddr
elif [ "${MODE}" = "thirdver" ] || [ "${MODE}" = "-t" ] || [ "${MODE}" = "--thirdver" ]; then
    thirdver
elif [ "${MODE}" = "dropbear" ] || [ "${MODE}" = "-d" ] || [ "${MODE}" = "--dropbear" ]; then
    dropbear
elif [ "${MODE}" = "kjx" ]; then
    kjx
elif [ "${MODE}" = "--airgap" ] || [ "${MODE}" = "-ag" ] || [ "${MODE}" = "-airgap" ]; then
    airgap_k3s
elif [ "${MODE}" = "--airgap_clean" ] || [ "${MODE}" = "-agc" ] || [ "${MODE}" = "-airgap_clean" ]; then
    airgap_clean
elif [ "${MODE}" = "--squash" ] || [ "${MODE}" = "-sq" ] || [ "${MODE}" = "-sq" ] || [ "${MODE}" = "-squash" ]; then
    squash_k3s
elif [ "${MODE}" = "--runiso" ] || [ "${MODE}" = "-runiso" ] || [ "${MODE}" = "runiso" ]; then
    runiso
elif [ "${MODE}" = "--record-runiso" ] || [ "${MODE}" = "-record-runiso" ] || [ "${MODE}" = "record-runiso" ]; then
    record_runiso
elif [ "${MODE}" = "--record-airgap" ] || [ "${MODE}" = "-record-airgap" ] || [ "${MODE}" = "record-airgap" ]; then
    record_airgap
elif [ "${MODE}" = "help" ] || [ "${MODE}" = "-h" ] || [ "${MODE}" = "--help" ]; then
    print_usage
elif [ "${MODE}" = "debug" ]; then
    debug
else
    echo "Invalid function name. Please specify one of: function1, function2, function3"
    print_usage
fi
