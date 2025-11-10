#!/bin/sh

# builds the project and fetch binaries for
# qemu-storage-daemon on qemu automation for the builder

# N. global variables
SEC_SED="./scripts/rep-secrets.sed"
THIS_SCRIPT="./scripts/qonq-qdb.sh"
REPLACED_SCRIPT="./artifacts/replaSED-qonq.sh"

# N. final_qemu global variables
QEMU_NEWART="./newart"
OTHER_BINARIES_DIR="./newart/other-bins"
QEMU_BINARIES_DIR="./newart/qemu-bins"

# N. ssh-enabled-rootfs
DBSSH_PATH="./artifacts/ssh-rootfs"
ROOTFS_ZIP="rootfs-tarball.zip"
DBSSH_FAKEROOTDIR="${DBSSH_PATH}"/fakerootdir
SSH_ROOTFS_COMPRESSED="${DBSSH_PATH}/${ROOTFS_ZIP}"
ROOTFS_CPIO_GZ="./artifacts/ssh-rootfs/rootfs-with-ssh.cpio.gz"

# N. ssh-enabled-rootfs: dropbear SSH logic setup
DROPBEAR_DIR="${DBSSH_FAKEROOTDIR}/etc/dropbear/"
DROPBEAR_SSH_KEYS_DIR="./artifacts/ssh-keys"
DROPBEAR_KEYPAIR="./artifacts/ssh-keys/kjx-keypair"
DROPBEAR_PUB_KEY="./artifacts/ssh-keys/kjx-keypair.pub"


bqm() {

CCR_MODE="checker" . ./scripts/ccr.sh && \
	docker compose -f ./compose.yml --progress=plain build builda_qemu

}


# replaces the github actions syntax with a environment variable syntax
replace() {

if [ -f "${SEC_SED}" ] && [ "${GITHUB_ACTIONS}" = "true" ]; then

    echo "================================"
    printf "\n|> Running inside a Github Actions workflow. Adjusting the script...\n\n"

    # replace syntax
    sed 's|\$FETCH_ARTIFACT|${{ secrets.FETCH_ARTIFACT }}|g' "${THIS_SCRIPT}" > "${REPLACED_SCRIPT}"

    # give execution permissions to the script
    chmod +x "${REPLACED_SCRIPT}"

    printf "\n|> Replacement shellscript created. Running it now...\n\n"

    # shellcheck source=./artifacts/replaSED-qonq.sh
    CCR_MODE="checker" . ./scripts/ccr.sh && \
        MODE="-fq" . "${REPLACED_SCRIPT}" && echo "okok!!"

    if ! rm "${REPLACED_SCRIPT}"; then
        printf "\n|> Could not clean the replaced script! Exiting now...\n\n"
        echo "================================"
    fi
    printf "\n|> Program run completed. Cleaning...\n"
    echo "================================"


elif [ "$GITHUB_ACTIONS" = "" ]; then

    echo "================================"
    printf "|> Running outside Actions Workflow. Using default syntax...\n\n"

    # shellcheck source=./scripts/qonq-qdb.sh
    CCR_MODE="checker" . ./scripts/ccr.sh && \
        MODE="-fq" . ${THIS_SCRIPT} && echo "okok!!"

else
    printf "\n|> Error: secrets parsing sed script not found. Exiting now...\n"
    echo "================================"
fi

}

# ====================
# Distro core binary dependencies
#
# ====================

# Setup core dependencies of the qemu on qemu qemu-distro-builder qonq-qdb
core_deps() {

    # get the linkage tarball
    docker cp qemu_kjx:/app/shared_deps/archive.tar.gz ./newart/              && \

    # get the qemu binaries
    docker cp qemu_kjx:/usr/bin/qemu-edid "${QEMU_BINARIES_DIR}"/                 && \
    docker cp qemu_kjx:/usr/bin/qemu-ga "${QEMU_BINARIES_DIR}"/                   && \
    docker cp qemu_kjx:/usr/bin/qemu-img "${QEMU_BINARIES_DIR}"/                  && \
    docker cp qemu_kjx:/usr/bin/qemu-io "${QEMU_BINARIES_DIR}"/                   && \
    docker cp qemu_kjx:/usr/bin/qemu-nbd "${QEMU_BINARIES_DIR}"/                  && \
    docker cp qemu_kjx:/usr/bin/qemu-pr-helper "${QEMU_BINARIES_DIR}"/            && \
    docker cp qemu_kjx:/usr/bin/qemu-storage-daemon "${QEMU_BINARIES_DIR}"/       && \
    docker cp qemu_kjx:/usr/bin/qemu-system-x86_64 "${QEMU_BINARIES_DIR}"/        && \
    docker cp qemu_kjx:/usr/bin/qemu-vmsr-helper "${QEMU_BINARIES_DIR}"/          && \

    # get the other binaries
    docker cp qemu_kjx:/usr/sbin/setcap   "${OTHER_BINARIES_DIR}"/usr/sbin/       && \
    docker cp qemu_kjx:/usr/sbin/parted   "${OTHER_BINARIES_DIR}"/usr/sbin/       && \
    docker cp qemu_kjx:/usr/sbin/kpartx   "${OTHER_BINARIES_DIR}"/usr/sbin/       && \
    docker cp qemu_kjx:/sbin/mkfs.ext4    "${OTHER_BINARIES_DIR}"/sbin/           && \

    # from fuser3
    docker cp qemu_kjx:/usr/bin/fusermount3   "${OTHER_BINARIES_DIR}"/usr/bin/    && \

    # fuse-overlayfs as an snapshotter alternative for k3s
    docker cp qemu_kjx:/usr/bin/fuse-overlayfs "${OTHER_BINARIES_DIR}"/usr/bin/fuse-overlayfs           && \

    # it must be based on util-linux/losetup, not on the busybox/losetup version.
    docker cp qemu_kjx:/sbin/losetup     "${OTHER_BINARIES_DIR}"/sbin/
}

# Setup tracers:
tracers() {
    # get bpftrace binary
    docker cp qemu_kjx:/usr/bin/bpftrace "${OTHER_BINARIES_DIR}"/usr/bin/bpftrace

}

# Setup Linux Kernel Modules (LKM) support: get kmod
lkm() {
    docker cp qemu_kjx:/app/kmod-34.2/build/kmod "${OTHER_BINARIES_DIR}"/app/kmod/                      && \
    docker cp qemu_kjx:/archive.tar.gz "${OTHER_BINARIES_DIR}"/app/kmod-archive.tar.gz                  && \
    docker cp qemu_kjx:/app/kmod-34.2/build/libkmod.so.2.5.1 "${OTHER_BINARIES_DIR}"/app/kmod-deps/
}

# Setup high-level container runtimes:
hlcr() {
    # setup podman and its dependencies
    docker cp qemu_kjx:/podman-so.tar.gz "${OTHER_BINARIES_DIR}"/app/                   && \
    docker cp qemu_kjx:/usr/bin/podman "${OTHER_BINARIES_DIR}"/app/                     && \
    mkdir -p "${OTHER_BINARIES_DIR}"/usr/libexec/podman/                                            && \
    docker cp qemu_kjx:/usr/libexec/podman/netavark "${OTHER_BINARIES_DIR}"/app/        && \

    # setup netavark, aardvark-dns, rootlessport and catatonit init
    docker cp qemu_kjx:/usr/libexec/podman/netavark       "${OTHER_BINARIES_DIR}"/usr/libexec/podman/netavark        && \
    docker cp qemu_kjx:/usr/libexec/podman/aardvark-dns   "${OTHER_BINARIES_DIR}"/usr/libexec/podman/aardvark-dns    && \
    docker cp qemu_kjx:/usr/libexec/podman/rootlessport   "${OTHER_BINARIES_DIR}"/usr/libexec/podman/rootlessport    && \
    docker cp qemu_kjx:/usr/bin/catatonit                 "${OTHER_BINARIES_DIR}"/usr/bin/catatonit                  && \
    docker cp qemu_kjx:/usr/libexec/podman/catatonit      "${OTHER_BINARIES_DIR}"/usr/libexec/podman/catatonit       && \
    ln -s "${OTHER_BINARIES_DIR}"/usr/bin/catatonit "${OTHER_BINARIES_DIR}"/usr/libexec/podman/catatonit

    # get conmon
    docker cp qemu_kjx:/conmon-archive.tar.gz "${OTHER_BINARIES_DIR}"/app/  && \
    docker cp qemu_kjx:/usr/bin/conmon "${OTHER_BINARIES_DIR}"/usr/bin/

}

# Setup low-level container runtimes:
llcr() {
# get crun
docker cp qemu_kjx:/usr/bin/crun "${OTHER_BINARIES_DIR}"/usr/bin/ && \
docker cp qemu_kjx:/archive.tar.gz ./app/crun-archive.tar.gz
}





final_qemu_aio() {


# OTHER_BINARIES_DIR is old newfrdir
OTHER_BINARIES_DIR="./newart/other-bins"
QEMU_BINARIES_DIR="./newart/qemu-bins"


printf "\n|> Building qemu_kjx image..."

CCR_MODE="checker" . ./scripts/ccr.sh && \

# ========================================
# FUNCTION CALL: the builda_qemu container
# specified on the ./compose.yml
bqm

# Create directories
mkdir -p "${OTHER_BINARIES_DIR}"            && \
mkdir -p "${QEMU_BINARIES_DIR}"             && \


# Run all build jobs
CCR_MODE="checker" . ./scripts/ccr.sh       && \
    # ========================================
    # FUNCTION CALL: Setup core dependencies
    core_deps && \
    # ========================================
    # FUNCTION CALL: Setup tracers
    tracers && \
    # ========================================
    # FUNCTION CALL: Linux Kernel Modules (LKM) support
    lkm && \
    # ========================================
    # FUNCTION CALL: High-Level Container Runtime support
    hlcr && \
    # ========================================
    # FUNCTION CALL: Low-Level Container Runtime support
    llcr && \


# ================
# Remaining binaries


# trace loading, debugging and dumping;
# vmlinux generation, btf debug info: bpftool, pahole, expect
# iso generation: xorriso, mksquashfs
# peripherals support: expect

docker run -it docker://alpine:3.20 \
    sh -c "apk upgrade && \
            apk update && \
            apk add bpftool pahole squashfs-tools setxkbmap xorriso expect && \
            echo $(readlink -f "$(which setxkbmap)" ) && \
            sleep 300
            " &

TMP_CONT_NAME=$(
    docker ps -a | \
    grep alpine | \
    grep Created | \
    awk 'END {print $1}' \
    )

docker start "$TMP_CONT_NAME"

getnames=$(docker exec "$TMP_CONT_NAME" sh -c '
  readlink -f "$(which bpftool)"
  readlink -f "$(which pahole)"
  readlink -f "$(which setxkbmap)"
  readlink -f "$(which mksquashfs)"
  readlink -f "$(which xorriso)"
  readlink -f "$(which expect)"
  ')

# make sure dir pathname exist beforehand
mkdir -p "${OTHER_BINARIES_DIR}"/usr/sbin/
mkdir -p "${OTHER_BINARIES_DIR}"/usr/bin/

# without quotes for word splitting
for index in $getnames; do
    docker cp "$TMP_CONT_NAME:$index" "${OTHER_BINARIES_DIR}$index"
done



# ================


#tar -xvf /app/shared_deps/archive.tar.gz
cd ./newart || return
tar -xvf ./archive.tar.gz
cd - || return


# The action will fetch this from the actions secret environment variable
# also export for envsubst
#eval "$(
#cat <<EOF
#export PAT_KJX_ARTIFACT="${{ secrets.FETCH_ARTIFACT }}"
export PAT_KJX_ARTIFACT="$FETCH_ARTIFACT"
#EOF
#)"

# from ssh-enabled-rootfs to rootfs-with-ssh
CUSTOM_ROOTFS_BUILDER=$(
    curl -H "Authorization: token ${PAT_KJX_ARTIFACT}" https://api.github.com/repos/deomorxsy/kjx-headless/actions/artifacts \
        | jq -C -r '.artifacts[] | select(.name == "rootfs-with-ssh") | .archive_download_url' | awk 'NR==1 {print $1}'
    )


# run container image with curl that gets it

# get container ID
BASECONT=$(docker run -it -d alpine:3.20 /bin/sh)


docker exec -it "$BASECONT" \
    sh -c "apk upgrade && apk update && apk add curl jq && curl -L -H \"Authorization: token $PAT_KJX_ARTIFACT\" -o rootfs-tarball.zip ${CUSTOM_ROOTFS_BUILDER}"

# ========================================================================
# N. ssh-enabled-rootfs
# ========================================================================


# cleanup 1
if [ -d "${DBSSH_PATH}" ] && ls -allhtr "${DBSSH_PATH}"; then
    rm -rf "${DBSSH_PATH}"
fi
mkdir -p "${DBSSH_PATH}"

# cleanup 2
if [ -d "${DBSSH_FAKEROOTDIR}" ] && ls -allhtr "${DBSSH_FAKEROOTDIR}"; then
    rm -rf "${DBSSH_FAKEROOTDIR}"
fi
mkdir -p "${DBSSH_FAKEROOTDIR}"

# cleanup 3
if [ -f "${SSH_ROOTFS_COMPRESSED}" ]; then
    rm -rf "${SSH_ROOTFS_COMPRESSED}"
fi
# Copy the artifact outside and then come back to the function
docker cp "${BASECONT}":rootfs-tarball.zip "${SSH_ROOTFS_COMPRESSED}"

# stop and remove the container
docker stop "${BASECONT}"
docker rm "${BASECONT}" --force


# check if the decompressed rootfs cpio.gz already exists to avoid unzip dialog
if [ -f "${ROOTFS_CPIO_GZ}" ]; then
    rm "${ROOTFS_CPIO_GZ}"
fi

# Unzip the zip tarball containin the cpio.gz
cd "${DBSSH_PATH}" || return

if ! [ -f "${ROOTFS_ZIP}" ]; then
    printf "\n\n|> Error: %s does not exist."  "${ROOTFS_ZIP}"
    return
fi
unzip "./${ROOTFS_ZIP}"
cd - || return

# Clean the fakerootdir tree if it exists
if [ -d "${DBSSH_FAKEROOTDIR}" ]; then
    rm -rf "${DBSSH_FAKEROOTDIR}"
fi && \

# Decompress gunzip and then cpio to the specified path
if ! (gzip -cd "${ROOTFS_CPIO_GZ}" | cpio -idmv -D "${DBSSH_FAKEROOTDIR}") ; then

    printf "\n\n|> Error: could NOT decompress gunzip and cpio to specified path at %s" "${DBSSH_FAKEROOTDIR}. Exiting now..."
    return

fi

# ========================================================
#
# 3. ssh-enabled-rootfs: dropbear SSH logic setup

# Setup dropbear keypair directory
mkdir -p "${DROPBEAR_DIR}"

# Make sure the directory exists and keypair
# already exists (locally) to avoid dialog
mkdir -p "${DROPBEAR_SSH_KEYS_DIR}"

# Clean last keypair if it exists
if [ -f "${DROPBEAR_KEYPAIR}" ]; then
    rm "${DROPBEAR_KEYPAIR}"
fi

# Create SSH keypair
if ! ssh-keygen -t ed25519 \
        -C "dropbear" \
        -f "${DROPBEAR_KEYPAIR}" \
        -N ""; then

    printf "\n\n|> Error: could not generate ssh keypair to specified path. Exiting now..."
    return
fi

# Mark generated public key as authorized by dropbear
if ! [ -f "${DROPBEAR_DIR}/authorized_keys" ] && [ -f "${DROPBEAR_PUB_KEY}" ]; then
    printf "\n\n|> Error: dropbear directory authorized_keys and public ssh key path were not found. Exiting now..."
    return
fi
cat "${DROPBEAR_PUB_KEY}" >> "${DROPBEAR_DIR}/authorized_keys"

# =====================

# Setup qemu binaries
cp -r "${QEMU_NEWART}/lib/*"      "${DBSSH_FAKEROOTDIR}/lib/"
cp -r "${QEMU_NEWART}/usr/*"      "${DBSSH_FAKEROOTDIR}/usr/"
cp -r "${QEMU_BINARIES_DIR}/*"    "${DBSSH_FAKEROOTDIR}/bin/"


# Enter dir just to run find
cd "${DBSSH_FAKEROOTDIR}" || return && \

# Patch the specified file with anything
# TODO
# ROOTFS_SEMVER=1.0.3

# create revised cpio.gz rootfs tarball
#find . -print0 | busybox cpio --null -ov --format=newc | gzip -9 > "../ssh-rootfs-revised_${ROOTFS_SEMVER}.cpio.gz" && \
find . -print0 | busybox cpio --null -ov --format=newc | gzip -9 > "../ssh-rootfs.cpio.gz" && \
cd - || return && \
printf "\n|> done!! Exiting now...\n\n"

}




configure_vm_ssh() {

ssh-keygen -t ed25519 -f ~/.ssh/qemu_vm_key -N ""

}

print_usage() {
cat <<-END >&2
USAGE: MODE="option" . ./path/to/run-qemu [-options]
                - fq
                - debug
                - help
                - version
eg,
run-qemu -fq        # final qemu
run-qemu -debug     # the same of thirdver but with serial and pty flags for kernel debug
run-qemu -help      # shows this help message
run-qemu -version   # shows script version

See the man page and example file for more info.

END

}


builder() {
# opt1 = build all high-level container runtime
# opt2 = build all low-level container runtime
# opt3 = build all microvms

core_deps

##############################

if ! [ -z "${MICROVM_RC}" ]; then
    case "${MICROVM_RC}" in
        "microvm-aio")
            . ./scripts/sandbox/microvm-setup.sh
            ;;
        "firecracker")
            . ./scripts/sandbox/firecracker-startup.sh
            ;;
        "gvisor")
            . ./scripts/sandbox/gvisor-setup.sh
            ;;
        "kata")
            . ./scripts/sandbox/kata-setup.sh
            ;;
        *)
            echo "Invalid microvm. Please specify one of: firecracker, gvisor, kata"
            print_usage
            ;;
    esac
    fi

    # high-level container runtime
    if ! [ -z "${HLCR_RC}" ]; then
    case "${HLCR_RC}" in
        "docker")
            hlcr docker
            ;;
        "podman")
            hlcr podman
            ;;
        "crio")
            hlcr crio
            ;;
        "aio")
            hlcr aio
            ;;
        *)
            echo "Invalid hlcr. Please specify one of: docker, podman, crio"
            print_usage
            ;;
    esac
    fi

    # runc, crun, containerd, youki
    if ! [ -z "${LLCR_RC}" ]; then
    case "${LLCR_RC}" in
        "runc")
            llcr runc
            ;;
        "crun")
            llcr crun
            ;;
        "containerd")
            llcr containerd
            ;;
        "youki")
            # builder "${LLCR_RC}"
            ;;
        "aio")
            printf "\n|> Not ready yet!"
            #builder "${LLCR_RC}"
            ;;
        *)
            echo "Invalid hlcr. Please specify one of: runc, crun, containerd, youki, aio".

            print_usage
            ;;
    esac
    fi

    if ! [ -z "${TRACER}" ]; then
    case "${TRACER}" in
        "libbpf-core")
            builder "${TRACER}"
            ;;
        "ayaya")
            builder "${TRACER}"
            ;;
        "ftrace")
            builder "${TRACER}"
            ;;
        "bpftrace")
            builder "${TRACER}"
            ;;
        #"libbpfgo")
            #builder "${TRACER}"
            #;;
        #"ocaml")
            #builder "${TRACER}"
            #;;
        #"zig-wasm")
            #builder "${TRACER}"
            #;;
        *)
            echo "Invalid hlcr. Please specify one of: runc, crun, containerd, youki, aio".

            print_usage
            ;;
    esac
    fi


### # Run all build jobs
### CCR_MODE="checker" . ./scripts/ccr.sh       && \
###     # ========================================
###     # FUNCTION CALL: Setup core dependencies
###     core_deps && \
###     # ========================================
###     # FUNCTION CALL: Setup tracers
###     tracers && \
###     # ========================================
###     # FUNCTION CALL: Linux Kernel Modules (LKM) support
###     lkm && \
###     # ========================================
###     # FUNCTION CALL: High-Level Container Runtime support
###     hlcr && \
###     # ========================================
###     # FUNCTION CALL: Low-Level Container Runtime support
###     llcr


}

# Check the argument passed from the command line
# if [ "$MODE" = "-fq" ] || [ "$MODE" = "--builder" ] || [ "$MODE" = "builder" ] ; then
if [ "$MODE" = "-builder" ] || [ "$MODE" = "--builder" ] || [ "$MODE" = "builder" ] ; then
    if ! [ -z "${MICROVM_RC}" ]; then
    case "${MICROVM_RC}" in
        "firecracker")
            builder "${MICROVM_RC}"
            ;;
        "gvisor")
            builder "${MICROVM_RC}"
            ;;
        "kata")
            builder "${MICROVM_RC}"
            ;;
        *)
            echo "Invalid microvm. Please specify one of: firecracker, gvisor, kata"
            print_usage
            ;;
    esac
    fi

    # high-level container runtime
    if ! [ -z "${HLCR_RC}" ]; then
    case "${HLCR_RC}" in
        "docker")
        #    builder "${HLCR_RC}"
            printf "\n|> Not ready yet!"
            ;;
        "podman")
            builder "${HLCR_RC}"
            ;;
        "crio")
        #    builder "${HLCR_RC}"
            printf "\n|> Not ready yet!"
            ;;
        "aio")
            builder "${HLCR_RC}"
            ;;
        *)
            echo "Invalid hlcr. Please specify one of: docker, podman, crio"
            print_usage
            ;;
    esac
    fi

    # runc, crun, containerd, youki
    if ! [ -z "${LLCR_RC}" ]; then
    case "${LLCR_RC}" in
        "runc")
            builder "${LLCR_RC}"
            ;;
        "crun")
            builder "${LLCR_RC}"
            ;;
        "containerd")
            printf "\n|> Not ready yet!"
            # builder "${LLCR_RC}"
            ;;
        "youki")
            # builder "${LLCR_RC}"
            ;;
        "aio")
            printf "\n|> Not ready yet!"
            #builder "${LLCR_RC}"
            ;;
        *)
            echo "Invalid hlcr. Please specify one of: runc, crun, containerd, youki, aio".

            print_usage
            ;;
    esac
    fi

    if ! [ -z "${TRACER}" ]; then
    case "${TRACER}" in
        "libbpf-core")
            builder "${TRACER}"
            ;;
        "ayaya")
            builder "${TRACER}"
            ;;
        "ftrace")
            builder "${TRACER}"
            ;;
        "bpftrace")
            builder "${TRACER}"
            ;;
        #"libbpfgo")
            #builder "${TRACER}"
            #;;
        #"ocaml")
            #builder "${TRACER}"
            #;;
        #"zig-wasm")
            #builder "${TRACER}"
            #;;
        *)
            echo "Invalid hlcr. Please specify one of: runc, crun, containerd, youki, aio".

            print_usage
            ;;
    esac
    fi

elif [ "$MODE" = "-rep" ] || [ "$MODE" = "--rep" ] || [ "$MODE" = "replace" ] ; then
    replace
elif [ "$MODE" = "help" ] || [ "$MODE" = "-h" ] || [ "$MODE" = "--help" ]; then
    print_usage
elif [ "$MODE" = "debug" ]; then
    debug
else
    echo "Invalid function name. Please specify one of: function1, function2, function3"
    print_usage
fi
