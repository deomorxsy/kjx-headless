#!/bin/sh

bqm() {
    . ./scripts/ccr.sh; checker; \
	docker compose -f ./compose.yml --progress=plain build builda_qemu

}


# replaces the github actions syntax with a environment variable syntax
replace() {

sec_sed="./scripts/rep-secrets.sed"


# if [ -f "$sec_sed" ] &&
if [ "$GITHUB_ACTIONS" = "true" ]; then

#sed -f "$sec_sed" < "./scripts/qonq.sh" > ./artifacts/replaSED-qonq.sh && \
#    envsubst < ./artifacts/replaSED-qonq.sh > ./artifacts/unsealed-qonq.sh

printf "|> Running inside a Github Actions workflow. Adjusting the script...\n\n"

sed 's|\$FETCH_ARTIFACT|${{ secrets.FETCH_ARTIFACT }}|g' "./scripts/qonq.sh" > "./artifacts/replaSED-qonq.sh"
#&& \
#    envsubst < ./artifacts/replaSED-qonq.sh >

#(
#cat <<EOF
#export PAT_KJX_ARTIFACT="\${{ secrets.FETCH_ARTIFACT }}"
#EOF
#) | sed -f "$sec_sed" > ./artifacts/replaSED-qonq.sh && \
#    envsubst < ./artifacts/replaSED-qonq.sh > ./artifacts/unsealed-qonq.sh

#chmod +x ./artifacts/unsealed-qonq.sh
chmod +x ./artifacts/replaSED-qonq.sh

printf "\n|> Replacement shellscript created. Running it now...\n\n"

. ./scripts/ccr.sh; checker && \
    ./artifacts/replaSED-qonq.sh; final_qemu && echo "okok!!"
    #./artifacts/unsealed-qonq.sh; final_qemu && echo "okok!!"

printf "\n|> Program run completed. Cleaning...\n"

(
cat <<EOF
#!/bin/sh

echo "keep"
EOF
) | tee ./artifacts/replaSED-qonq.sh && \
    printf "\n|> Cleaning finished.\n"

#| tee ./artifacts/unsealed-qonq.sh && \
#    printf "\n|> Cleaning finished."
elif [ "$GITHUB_ACTIONS" = "" ]; then

    printf "|> Running outside Actions Workflow. Using default syntax...\n\n"
    . ./scripts/ccr.sh; checker && \
        ./scripts/qonq.sh; final_qemu && echo "okok!!"

else
    printf "\n|> Error: secrets parsing sed script not found. Exiting now...\n"
fi

}


# the ccr script should be called before this function
final_qemu() {

printf "\n|> Building qemu_kjx image..."

. ./scripts/ccr.sh; checker && \

#if [ "$QEMU_KJX_LINKED" = "" ]; then
#    printf "\n|> did not found the qemu_kjx image. Building it now...\n\n"

bqm

docker ps | grep qemu_kjx | awk {'print $1'}

QEMU_KJX_LINKED=$(docker ps | grep qemu_kjx | awk {'print $1'})
#else
#    printf "\n|> found qemu_kjx image. Preparing...\n\n"

#fi && \

mkdir -p ./newart/qemu-bins/ && \

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
CUSTOM_ROOTFS_BUILDER=$(curl -H "Authorization: token $PAT_KJX_ARTIFACT" https://api.github.com/repos/deomorxsy/kjx-headless/actions/artifacts | jq -C -r '.artifacts[] | select(.name == "rootfs-with-ssh") | .archive_download_url' | awk 'NR==1 {print $1}')


# run container image with curl that gets it

# get container ID
BASECONT=$(docker run -it -d alpine:3.20 /bin/sh)


printf "\n|> The token is: %s\n\n" "$PAT_KJX_ARTIFACT"

docker exec -it "$BASECONT" sh -c "apk upgrade && apk update && apk add curl jq && curl -L -H \"Authorization: token $PAT_KJX_ARTIFACT\" -o rootfs-tarball.zip $CUSTOM_ROOTFS_BUILDER"

#
DBSSH_PATH="./artifacts/ssh-rootfs"
DBSSH_FAKEROOTDIR="$DBSSH_PATH/fakerootdir"

# cleanup 1
rm -rf "./artifacts/ssh-rootfs/*"
mkdir -p "./artifacts/ssh-rootfs/"

# cleanup 2
rm -rf "./artifacts/ssh-rootfs/fakerootdir/*"
mkdir -p "./artifacts/ssh-rootfs/fakerootdir/"

#now copy the artifact outside and then come back to the function
docker cp "$BASECONT":rootfs-tarball.zip "$DBSSH_PATH"

# stop and remove the container
docker stop "$BASECONT"
docker rm "$BASECONT" --force


# check if the decompressed rootfs cpio.gz already exists to avoid unzip dialog
if [ -f ./artifacts/ssh-rootfs/rootfs-with-ssh.cpio.gz ]; then
    rm ./artifacts/ssh-rootfs/rootfs-with-ssh.cpio.gz
    rm ./artifacts/ssh-rootfs/rootfs-tarball.zip
fi

# unzip the zip tarball containin the cpio.gz
cd "$DBSSH_PATH" || return
unzip ./rootfs-tarball.zip
cd - || return

# clean the rootfs tree if it exists
#rm -rf "./artifacts/ssh-rootfs/fakerootdir/*" && \

# decompress gunzip and then cpio to the specified path
gzip -cd ./artifacts/ssh-rootfs/rootfs-with-ssh.cpio.gz | cpio -idmv -D ./artifacts/ssh-rootfs/fakerootdir/


# setup dropbear keypair
mkdir -p ./artifacts/ssh-rootfs/fakerootdir/etc/dropbear/

# check if keypair already exists to avoid dialog
if [ -f ./artifacts/ssh-keys/kjx-keypair ]; then
    rm ./artifacts/ssh-keys/kjx-keypair
fi

ssh-keygen -t ed25519 -C "dropbear" -f ./artifacts/ssh-keys/kjx-keypair -N ""

cat ./artifacts/ssh-keys/kjx-keypair.pub >> ./artifacts/ssh-rootfs/fakerootdir/etc/dropbear/authorized_keys

# setup qemu binaries
cp -r ./newart/lib/* ./artifacts/ssh-rootfs/fakerootdir/lib/
cp -r ./newart/usr/* ./artifacts/ssh-rootfs/fakerootdir/usr/
cp -r ./newart/qemu-bins/* ./artifacts/ssh-rootfs/fakerootdir/bin/


# enter dir just to run find
cd ./artifacts/ssh-rootfs/fakerootdir/ || return && \

# patch the specified file with anything
#
#ROOTFS_SEMVER=0.3.1
ROOTFS_SEMVER=0.3.2

# create revised cpio.gz rootfs tarball
find . -print0 | busybox cpio --null -ov --format=newc | gzip -9 > ../ssh-rootfs-revised.cpio_"$ROOTFS_SEMVER".gz && \
    cd - || return && \

printf "\n|> done!! Exiting now...\n\n"
}




configure_vm_ssh() {

ssh-keygen -t ed25519 -f ~/.ssh/qemu_vm_key -N ""

}

print_usage() {
cat <<-END >&2
USAGE: run-qemu [-options]
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
if [ "$1" = "-fq" ] || [ "$1" = "--final_qemu" ] || [ "$1" = "final_qemu" ] ; then
    replace
elif [ "$1" = "help" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    print_usage
elif [ "$1" = "debug" ]; then
    debug
else
    echo "Invalid function name. Please specify one of: function1, function2, function3"
    print_usage
fi
