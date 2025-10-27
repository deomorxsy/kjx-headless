#!/bin/sh

# builds the project and fetch binaries for
# qemu-storage-daemon on qemu automation for the builder

# global variables
SEC_SED="./scripts/rep-secrets.sed"
THIS_SCRIPT="./scripts/qonq-qdb.sh"
REPLACED_SCRIPT="./artifacts/replaSED-qonq.sh"

# final_qemu global variables
OTHER_BINARIES_DIR="./newart/other-bins"
QEMU_BINARIES_DIR="./newart/qemu-bins"

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
# Distro core dependencies
#
# ====================

# Setup core dependencies of the qemu on qemu qemu-distro-builder qonq-qdb
core_deps() {

    # get the linkage tarball
    docker cp "${QEMU_KJX_LINKED}":/app/shared_deps/archive.tar.gz ./newart/              && \

    # get the qemu binaries
    docker cp "${QEMU_KJX_LINKED}":/usr/bin/qemu-edid "${QEMU_BINARIES_DIR}"/                 && \
    docker cp "${QEMU_KJX_LINKED}":/usr/bin/qemu-ga "${QEMU_BINARIES_DIR}"/                   && \
    docker cp "${QEMU_KJX_LINKED}":/usr/bin/qemu-img "${QEMU_BINARIES_DIR}"/                  && \
    docker cp "${QEMU_KJX_LINKED}":/usr/bin/qemu-io "${QEMU_BINARIES_DIR}"/                   && \
    docker cp "${QEMU_KJX_LINKED}":/usr/bin/qemu-nbd "${QEMU_BINARIES_DIR}"/                  && \
    docker cp "${QEMU_KJX_LINKED}":/usr/bin/qemu-pr-helper "${QEMU_BINARIES_DIR}"/            && \
    docker cp "${QEMU_KJX_LINKED}":/usr/bin/qemu-storage-daemon "${QEMU_BINARIES_DIR}"/       && \
    docker cp "${QEMU_KJX_LINKED}":/usr/bin/qemu-system-x86_64 "${QEMU_BINARIES_DIR}"/        && \
    docker cp "${QEMU_KJX_LINKED}":/usr/bin/qemu-vmsr-helper "${QEMU_BINARIES_DIR}"/          && \

    # get the other binaries
    docker cp "${QEMU_KJX_LINKED}":/usr/sbin/setcap   "${OTHER_BINARIES_DIR}"/usr/sbin/       && \
    docker cp "${QEMU_KJX_LINKED}":/usr/sbin/parted   "${OTHER_BINARIES_DIR}"/usr/sbin/       && \
    docker cp "${QEMU_KJX_LINKED}":/usr/sbin/kpartx   "${OTHER_BINARIES_DIR}"/usr/sbin/       && \
    docker cp "${QEMU_KJX_LINKED}":/sbin/mkfs.ext4    "${OTHER_BINARIES_DIR}"/sbin/           && \

    # from fuser3
    docker cp "${QEMU_KJX_LINKED}":/usr/bin/fusermount3   "${OTHER_BINARIES_DIR}"/usr/bin/    && \

    # fuse-overlayfs as an snapshotter alternative for k3s
    docker cp "${QEMU_KJX_LINKED}":/usr/bin/fuse-overlayfs "${OTHER_BINARIES_DIR}"/usr/bin/fuse-overlayfs           && \

    # it must be based on util-linux/losetup, not on the busybox/losetup version.
    docker cp "${QEMU_KJX_LINKED}":/sbin/losetup     "${OTHER_BINARIES_DIR}"/sbin/
}

# Setup tracers:
tracers() {
    # get bpftrace binary
    docker cp "${QEMU_KJX_LINKED}":/usr/bin/bpftrace "${OTHER_BINARIES_DIR}"/usr/bin/bpftrace

}

# Setup Linux Kernel Modules (LKM) support: get kmod
lkm() {
    docker cp "${QEMU_KJX_LINKED}":/app/kmod-34.2/build/kmod "${OTHER_BINARIES_DIR}"/app/kmod/                      && \
    docker cp "${QEMU_KJX_LINKED}":/archive.tar.gz "${OTHER_BINARIES_DIR}"/app/kmod-archive.tar.gz                  && \
    docker cp "${QEMU_KJX_LINKED}":/app/kmod-34.2/build/libkmod.so.2.5.1 "${OTHER_BINARIES_DIR}"/app/kmod-deps/
}

# Setup high-level container runtimes:
hlcr() {
    # setup podman and its dependencies
    docker cp "${QEMU_KJX_LINKED}":/podman-so.tar.gz "${OTHER_BINARIES_DIR}"/app/                   && \
    docker cp "${QEMU_KJX_LINKED}":/usr/bin/podman "${OTHER_BINARIES_DIR}"/app/                     && \
    mkdir -p "${OTHER_BINARIES_DIR}"/usr/libexec/podman/                                            && \
    docker cp "${QEMU_KJX_LINKED}":/usr/libexec/podman/netavark "${OTHER_BINARIES_DIR}"/app/        && \

    # setup netavark, aardvark-dns, rootlessport and catatonit init
    docker cp "${QEMU_KJX_LINKED}":/usr/libexec/podman/netavark       "${OTHER_BINARIES_DIR}"/usr/libexec/podman/netavark        && \
    docker cp "${QEMU_KJX_LINKED}":/usr/libexec/podman/aardvark-dns   "${OTHER_BINARIES_DIR}"/usr/libexec/podman/aardvark-dns    && \
    docker cp "${QEMU_KJX_LINKED}":/usr/libexec/podman/rootlessport   "${OTHER_BINARIES_DIR}"/usr/libexec/podman/rootlessport    && \
    docker cp "${QEMU_KJX_LINKED}":/usr/bin/catatonit                 "${OTHER_BINARIES_DIR}"/usr/bin/catatonit                  && \
    docker cp "${QEMU_KJX_LINKED}":/usr/libexec/podman/catatonit      "${OTHER_BINARIES_DIR}"/usr/libexec/podman/catatonit       && \
    ln -s "${OTHER_BINARIES_DIR}"/usr/bin/catatonit "${OTHER_BINARIES_DIR}"/usr/libexec/podman/catatonit

    # get conmon
    docker cp "${QEMU_KJX_LINKED}":/conmon-archive.tar.gz "${OTHER_BINARIES_DIR}"/app/  && \
    docker cp "${QEMU_KJX_LINKED}":/usr/bin/conmon "${OTHER_BINARIES_DIR}"/usr/bin/

}

# Setup low-level container runtimes:
llcr() {
# get crun
docker cp "${QEMU_KJX_LINKED}":/usr/bin/crun "${OTHER_BINARIES_DIR}"/usr/bin/ && \
docker cp "${QEMU_KJX_LINKED}":/archive.tar.gz ./app/crun-archive.tar.gz
}




# the ccr script should be called before this function
final_qemu() {

# opt1 = build all high-level container runtime
# opt2 = build all low-level container runtime
# opt3 = build all microvms

# OTHER_BINARIES_DIR is old newfrdir
OTHER_BINARIES_DIR="./newart/other-bins"
QEMU_BINARIES_DIR="./newart/qemu-bins"


printf "\n|> Building qemu_kjx image..."

CCR_MODE="checker" . ./scripts/ccr.sh && \

#if [ "${QEMU_KJX_LINKED}" = "" ]; then
#    printf "\n|> did not found the qemu_kjx image. Building it now...\n\n"

# FUNCTION CALL: the builda_qemu container specified on the ./compose.yml
bqm

# check if built image exists
if ! docker ps | grep qemu_kjx | awk '{print $1}'; then
    printf "\n|> There is no built container called qemu_kjx. Exiting now...\n\n"
    return
else
    QEMU_KJX_LINKED=$(docker ps | grep qemu_kjx | awk '{print $1}')
    printf "\n|> Found the qemu_kjx image. Preparing...\n\n"
fi && \

# create directories
mkdir -p "${OTHER_BINARIES_DIR}"            && \
mkdir -p "${QEMU_BINARIES_DIR}"             && \


# Run all build jobs
CCR_MODE="checker" . ./scripts/ccr.sh       && \
    # FUNCTION CALL: Setup core dependencies
    core_deps && \
    # FUNCTION CALL: Setup tracers
    tracers && \
    # FUNCTION CALL: Linux Kernel Modules (LKM) support
    lkm && \
    # FUNCTION CALL: High-Level Container Runtime support
    hlcr && \
    # FUNCTION CALL: Low-Level Container Runtime support
    llcr && \


# ================
# remaining binaries


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

# reference:
# /home/asari/Downloads/kjxh-artifacts/another/
# "${OTHER_BINARIES_DIR}"
#
# make sure dir pathname exist beforehand
mkdir -p "${OTHER_BINARIES_DIR}"/usr/sbin/
mkdir -p "${OTHER_BINARIES_DIR}"/usr/bin/

# without quotes for word splitting
for index in $getnames; do
    docker cp "$TMP_CONT_NAME:$index" ""${OTHER_BINARIES_DIR}"$index"
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

#
DBSSH_PATH="./artifacts/ssh-rootfs"
DBSSH_FAKEROOTDIR="${DBSSH_PATH}"/fakerootdir

# cleanup 1
#rm -rf "./artifacts/ssh-rootfs/*"
mkdir -p "./artifacts/ssh-rootfs/"

# cleanup 2
#rm -rf "./artifacts/ssh-rootfs/fakerootdir/*"
mkdir -p "./artifacts/ssh-rootfs/fakerootdir/"

# cleanup 3
#rm ./artifacts/ssh-rootfs/rootfs-tarball.zip

#now copy the artifact outside and then come back to the function
#docker cp "$BASECONT":rootfs-tarball.zip "$DBSSH_PATH"
docker cp "${BASECONT}":rootfs-tarball.zip ./artifacts/ssh-rootfs/rootfs-tarball.zip

# stop and remove the container
docker stop "${BASECONT}"
docker rm "${BASECONT}" --force


# check if the decompressed rootfs cpio.gz already exists to avoid unzip dialog
if [ -f ./artifacts/ssh-rootfs/rootfs-with-ssh.cpio.gz ]; then
    rm ./artifacts/ssh-rootfs/rootfs-with-ssh.cpio.gz
fi

# unzip the zip tarball containin the cpio.gz
# cd "$DBSSH_PATH" || return
cd ./artifacts/ssh-rootfs/ || return
unzip ./rootfs-tarball.zip
cd - || return

# clean the rootfs tree if it exists
#rm -rf "./artifacts/ssh-rootfs/fakerootdir/*" && \

# decompress gunzip and then cpio to the specified path
gzip -cd ./artifacts/ssh-rootfs/rootfs-with-ssh.cpio.gz \
    | cpio -idmv -D ./artifacts/ssh-rootfs/fakerootdir/


# setup dropbear keypair
mkdir -p ./artifacts/ssh-rootfs/fakerootdir/etc/dropbear/


# make sure the directory exists and keypair
# already exists (locally) to avoid dialog
mkdir -p ./artifacts/ssh-keys

if [ -f ./artifacts/ssh-keys/kjx-keypair ]; then
    rm ./artifacts/ssh-keys/kjx-keypair
fi


ssh-keygen -t ed25519 \
        -C "dropbear" \
        -f ./artifacts/ssh-keys/kjx-keypair \
        -N ""

cat ./artifacts/ssh-keys/kjx-keypair.pub >> ./artifacts/ssh-rootfs/fakerootdir/etc/dropbear/authorized_keys

# setup qemu binaries
cp -r ./newart/lib/* ./artifacts/ssh-rootfs/fakerootdir/lib/
cp -r ./newart/usr/* ./artifacts/ssh-rootfs/fakerootdir/usr/
cp -r "${QEMU_BINARIES_DIR}"/* ./artifacts/ssh-rootfs/fakerootdir/bin/


# enter dir just to run find
cd ./artifacts/ssh-rootfs/fakerootdir/ || return && \

# patch the specified file with anything
#
#ROOTFS_SEMVER=0.3.1
ROOTFS_SEMVER=0.3.3

# create revised cpio.gz rootfs tarball
find . -print0 | busybox cpio --null -ov --format=newc | gzip -9 > "../ssh-rootfs-revised_${ROOTFS_SEMVER}.cpio.gz" && \
    cd - || return && \
printf "\n|> done!! Exiting now...\n\n"


# find . -print0 | busybox cpio --null -ov --format=newc | gzip -9 > ../rootfs_v7.cpio.gz

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


# Check the argument passed from the command line
if [ "$MODE" = "-fq" ] || [ "$MODE" = "--final_qemu" ] || [ "$MODE" = "final_qemu" ] ; then
    final_qemu
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
