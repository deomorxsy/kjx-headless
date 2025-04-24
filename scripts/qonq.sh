#!/bin/sh

bqm() {
    . ./scripts/ccr.sh; checker; \
	docker compose -f ./compose.yml --progress=plain build builda_qemu
}


# replaces the github actions syntax with a environment variable syntax
replace() {

sec_sed="./scripts/rep-secrets.sed"

if [ -f "$sec_sed" ] && [ -f ./artifacts/sso.sh ]; then

sed -f="$sec_sed" < "./scripts/qonq.sh" > ./artifacts/replaSED-qonq.sh && \
    envsubst < ./artifacts/replaSED-qonq.sh > ./artifacts/unsealed-qonq.sh

printf "\n|> Replacement shellscript created. Running it now...\n\n"

. ./scripts/ccr.sh; checker && \
    . ./artifacts/unsealed-qonq.sh; final_qemu && echo "okok!!"

printf "\n|> Program run completed. Cleaning...\n"

(
cat <<EOF
#!/bin/sh

echo "keep"
EOF
) | tee ./artifacts/unsealed-qonq.sh && \
    printf "\n|> Cleaning finished."

else
    printf "\n|> Error: secrets parsing sed script not found. Exiting now..."
fi

}


# the ccr script should be called before this function
final_qemu() {

QEMU_KJX_LINKED=$(docker ps | grep qemu_kjx | awk {'print $1'})


if [ "$QEMU_KJX_LINKED" = "" ]; then
    printf "\n|> did not found the qemu_kjx image. Building it now...\n\n"
    bqm
else
    printf "\n|> found qemu_kjx image. Preparing...\n\n"

fi

mkdir -p ./newart/qemu-bins/

# get the linkage tarball
docker cp "$QEMU_KJX_LINKED":/app/shared_deps/archive.tar.gz ./newart/

# get the qemu binaries
docker cp "$QEMU_KJX_LINKED":/usr/bin/qemu-edid ./newart/qemu-bins/
docker cp "$QEMU_KJX_LINKED":/usr/bin/qemu-ga ./newart/qemu-bins/
docker cp "$QEMU_KJX_LINKED":/usr/bin/qemu-img ./newart/qemu-bins/
docker cp "$QEMU_KJX_LINKED":/usr/bin/qemu-io ./newart/qemu-bins/
docker cp "$QEMU_KJX_LINKED":/usr/bin/qemu-nbd ./newart/qemu-bins/
docker cp "$QEMU_KJX_LINKED":/usr/bin/qemu-pr-helper ./newart/qemu-bins/
docker cp "$QEMU_KJX_LINKED":/usr/bin/qemu-storage-daemon ./newart/qemu-bins/
docker cp "$QEMU_KJX_LINKED":/usr/bin/qemu-system-x86_64 ./newart/qemu-bins/
docker cp "$QEMU_KJX_LINKED":/usr/bin/qemu-vmsr-helper ./newart/qemu-bins/

tar -xvf /app/shared_deps/archive.tar.gz




PAT_KJX_ARTIFACT=${{ secrets.FETCH_ARTIFACT }}

CUSTOM_ROOTFS_BUILDER=$(curl -H "Authorization: token $PAT_KJX_ARTIFACT" https://api.github.com/repos/deomorxsy/kjx-headless/actions/artifacts | jq -C -r '.artifacts[] | select(.name == "ssh-enabled-rootfs") | .archive_download_url' | awk 'NR==1 {print $1}')


# run container image with curl that gets it

# get container ID
BASECONT=$(docker run -it -d alpine:3.20 /bin/sh)

docker exec -it "$BASECONT" sh -c "apk upgrade && apk update && apk add curl jq && curl -L -H \"Authorization: token $PAT_KJX_ARTIFACT\" -o rootfs-ssh.zip $CUSTOM_ROOTFS_BUILDER"

#
DBSSH_PATH="./artifacts/ssh-rootfs"
DBSSH_FAKEROOTDIR="$DBSSH_PATH/fakerootdir"

# cleanup 1
rm -rf "./artifacts/ssh-rootfs/*"
mkdir -p "$DBSSH_PATH"

# cleanup 2
rm -rf "./artifacts/ssh-rootfs/fakerootdir/*"
mkdir -p "$DBSSH_FAKEROOTDIR"

#now copy the artifact outside and then come back to the function
docker cp "$BASECONT":rootfs-with-ssh.zip "$DBSSH_PATH"

# stop and remove the container
docker stop "$BASECONT"
docker rm "$BASECONT" --force



# clean the rootfs tree if it exists
rm -rf "./artifacts/ssh-rootfs/fakerootdir/*" && \

# decompress gunzip and then cpio to the specified path
gzip -cd ./artifacts/ssh-rootfs/rootfs-with-ssh.cpio.gz | cpio -idmv -D ./artifacts/ssh-rootfs/fakerootdir/

# setup dropbear keypair
ssh-keygen -t ed25519 -C "dropbear" -f ./artifacts/ssh-keys/kjx-keys -N ""
cat ./artifacts/ssh-keys/kjx-keys.pub >> ./artifacts/ssh-rootfs/fakerootdir/etc/dropbear/authorized_keys

# enter dir just to run find
cd ./artifacts/ssh-rootfs/fakerootdir/ || return && \

# patch the specified file with anything
#
ROOTFS_SEMVER=0.3.1
# create revised cpio.gz rootfs tarball
find . -print0 | busybox cpio --null -ov --format=newc | gzip -9 > ../ssh-rootfs-revised.cpio_"$ROOTFS_SEMVER".gz && \
echo done!!
}




configure_vm_ssh() {

ssh-keygen -t ed25519 -f ~/.ssh/qemu_vm_key -N ""

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
run-qemu -debug # the same of thirdver but with serial and pty flags for kernel debug
run-qemu -help    # shows this help message
run-qemu -version # shows script version

See the man page and example file for more info.

END

}


# Check the argument passed from the command line
elif [ "$1" = "-fq" ] || [ "$1" = "--finalqemu" ] || [ "$1" = "finalqemu" ] ; then
    replace
elif [ "$1" = "dropbear" ] || [ "$1" = "-d" ] || [ "$1" = "--dropbear" ] ; then
    dropbear
elif [ "$1" = "kjx" ]; then
    kjx
elif [ "$1" = "help" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    print_usage
elif [ "$1" = "debug" ]; then
    debug
else
    echo "Invalid function name. Please specify one of: function1, function2, function3"
    print_usage
fi
