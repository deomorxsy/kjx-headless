#!/bin/bash

check_registry() {
#. ./scripts/ccr.sh; checker
isrerun=$(docker ps | grep registry | awk '{print $7}')
# if the output is not empty
if [ -z "$isrerun" ]; then
    if [[ "$isrerun" == *"Exited"* ]]; then
        printf "\n====\ncheck_registry: starting registry...\n=====\n\n"
        docker start registry
    elif [[ "$isrerun" == *"Up"* ]]; then
        printf "\n====\ncheck_registry: starting registry...\n=====\n\n"
        docker stop registry
    fi
# if the output is empty, there is no registry.
# So, create the registry.
else
    docker run -d -p 5000:5000 --name registry registry:latest
fi
}




build() {
compose_ctx=$(docker images | grep isogen_new | awk 'NR==1 {print $3}')
contname="isogen_new"

. ./scripts/ccr.sh; checker && \
# check if the registry is started
#check_registry && \
docker start registry && \
docker compose -f ./compose.yml --progress=plain build --no-cache isogen_new && \
docker compose images | grep isogen | awk '{ print $4 }' && \
docker push localhost:5000/isogen_new:latest && \
# if the registry is started, stop it
#check_registry && \
docker stop registry && \
touch ./BUILD_MARKER && printf "\n========\nCreating build marker...\n========\n\n"
}

runtime() {
compose_ctx=$(docker images | grep isogen_new | awk 'NR==1 {print $3}')
contname="isogen_new"

. ./scripts/ccr.sh; checker && \
#docker start registry
echo beforeeeeeeeeeeeeee && \
podman create --userns=auto --cap-drop=ALL --cap-add=CAP_SYS_ADMIN,CAP_DAC_OVERRIDE,CAP_CHOWN,CAP_SETFCAP --rm --name "$contname" "$compose_ctx" 2>&1 && \
echo afterrrrrrrrrr && \
docker start "$contname" && docker logs -f "$contname"
#docker cp "$contname":/app/output.iso ./artifacts/kjx-headless.iso
#docker rm "$contname"
#docker stop registry
}

# build based on a timestamp
timed() {
timestamp=$(date +%s)
timecheck=$(stat -c %Y ./BUILD_MARKER)

if [ $(("$timestamp" - "$timecheck")) -lt 60 ]; then
    runtime
else
    build
fi
}

# execute instantly
instant() {
    build
    runtime
}


standalone(){

image1=324bc02ae123
image2="28e4439b1801"
image3="03026fbd3c2c"

# adjusted capabilities
image4="6dbcc58a236d" # 20/10/2024

cat <<EOF
==========
Running now:

podman run --userns=auto --cap-drop=ALL \
    --cap-add=CAP_SYS_ADMIN,CAP_DAC_OVERRIDE,CAP_CHOWN,CAP_SETFCAP,CAP_MKNOD \
    --device=/dev/mapper/control --device=/dev/loop-control \
    --device=/dev/fuse \
    --rm -it \
    --entrypoint=/bin/sh "$image4"
==========

EOF

podman run --userns=auto --cap-drop=ALL \
    --cap-add=CAP_SYS_ADMIN,CAP_DAC_OVERRIDE,CAP_DAC_READ_SEARCH,CAP_CHOWN,CAP_SETFCAP,CAP_MKNOD \
    --device=/dev/mapper/control \
    --device=/dev/loop-control \
    --device=/dev/fuse \
    --rm -it \
    --entrypoint=/bin/sh "$image4"


#--rm -it "$image2" #\
#--entrypoint=/bin/sh "$image2"
}

debug() {
    echo
}

ubuntu() {
#--userns=keep-id
    podman run  --user "$(id -u):$(id -g)" \
    --cap-drop=ALL \
    --cap-add=CAP_SYS_ADMIN,CAP_DAC_OVERRIDE,CAP_DAC_READ_SEARCH,CAP_CHOWN,CAP_SETFCAP,CAP_MKNOD \
    --device=/dev/mapper/control --device=/dev/loop-control \
    --device=/dev/fuse \
    --rm -it \
    --entrypoint=/bin/bash \
    ubuntu:22.04
}

qemux() {

image1="735e7725222e"

podman run --userns=keep-id --cap-drop=ALL \
--cap-add=CAP_SYS_ADMIN,CAP_DAC_OVERRIDE,CAP_DAC_READ_SEARCH,CAP_CHOWN,CAP_SETFCAP,CAP_MKNOD \
--device=/dev/mapper/control --device=/dev/loop-control \
--device=/dev/fuse \
--rm -it \
--entrypoint=/bin/sh "$image1"

}

fish() {

image1="./libguestfs/rootfs.qcow2"

export LIBGUESTFS_DEBUG=1 LIBGUESTFS_TRACE=1

guestfish -a "$image1" : run   \
: part-disk /dev/sda mbr        \
: pvcreate /dev/sda1            \
: vgcreate vmsys /dev/sda1      \
: lvcreate root vmsys 1024      \
: mkfs ext4 /dev/vmsys/root     \
: mount /dev/vmsys/root /       \
: mkdir-p /var/log              \
: lvcreate varlog vmsys 2048    \
: mkfs ext4 /dev/vmsys/varlog

}

otherfish(){
image1="./libguestfs/rootfs.qcow2"
export LIBGUESTFS_DEBUG=1 LIBGUESTFS_TRACE=1

guestfish -a "$image1" <<_EOF_
run
part-disk /dev/sda mbr
pvcreate /dev/sda1
vgcreate vmsys /dev/sda1
lvcreate root vmsys 1024
mkfs ext4 /dev/vmsys/root
mount /dev/vmsys/root
mkdir-p /var/log
lvcreate varlog vmsys 2048
mkfs ext4 /dev/vmsys/varlog
_EOF_
}

podyouki() {
    # adjusted capabilities
image4="6dbcc58a236d" # 20/10/2024

podman --runtime=youki run --userns=auto --cap-drop=ALL \
    --cap-add=CAP_SYS_ADMIN,CAP_DAC_OVERRIDE,CAP_DAC_READ_SEARCH,CAP_CHOWN,CAP_SETFCAP,CAP_MKNOD \
    --device=/dev/mapper/control --device=/dev/loop-control \
    --device=/dev/fuse \
    --rm -it \
    --entrypoint=/bin/sh "$image4"
}

nerdctl() {
#
# running on ubuntu:22.04
#
#youki spec >./deploy/newconfig.json

CAPABILITIES=$(
cat <<"EOF"
        "CAP_SYS_ADMIN",
        "CAP_DAC_OVERRIDE",
        "CAP_DAC_READ_SEARCH",
        "CAP_CHOWN",
        "CAP_SETFCAP",
        "CAP_MKNOD"
EOF
)
#printf "\t%s\n" $CAPABILITIES

#jq '.process.capabilities.ambient' ./deploy/config.json > idk-edited.txt

#perl -MJSON -0ne '
#    my $DS = decode_json $_;
#    $DS->{name} = "qux";
#    print encode_json $DS
#' json > perl.json

#./deploy/config.json

if ! "$(readlink -f "$(which containerd)")"; then
    cd ./assets/ || return
    git clone git@github.com:containerd/nerdctl.git
    cd - || return
    # install rootless containerd
    ./assets/nerdctl/extras/rootless/containerd-rootless-setuptool.sh install
else
    systemctl --user start containerd.service
fi

systemctl --user start containerd.service

image4="6dbcc58a236d" # 20/10/2024
# todo: edit: if lsb_release AND the network package
# 2>&1 will still output the path to ip
if (readlink -f "$(which ip 2>&1)"); then
    # iproute2, enp4s0
    interface=$(ip a | grep enp4s0 | awk 'NR==2 {print $2}')
elif (readlink -f "$(which ifconfig 2>&1)"); then
    # net-tools, eth0
    interface=$(ifconfig -a | grep 192.168 | awk '{print $2}')
fi

#HOST_IP=$(ip a | grep enp4s0 | awk 'NR==2 {print $2}')

# ■■ Parameter expansion can't be applied to command substitutions. Use temporary variables.
#ANOTHER_IP=${$(ip a | grep enp4s0 | awk 'NR==2 {print $2}')//"/24"/}

#nerdctl run --config ./deploy/newconfig.json "$image4"

#--address unix:///run/user/1000/podman/podman.sock \

# substring replacement
trim_host_ip=${interface//"/24"/}

#--device=/dev/mapper/control \
#--device=/dev/loop-control \
#--device=/dev/fuse \
#--cap-drop=ALL \

# add runit, openssh

nerdctl --address=/proc/"$(cat "$XDG_RUNTIME_DIR/containerd-rootless/child_pid")"/root/run/containerd/containerd.sock \
    run --privileged\
    --rm -it \
    --entrypoint=/bin/sh \
    --insecure-registry "$trim_host_ip:5000/isogen_new:latest"

podman run --rm -it -v /boot:/boot -v /lib/modules:/lib/modules --entrypoint=/bin/bash

nerdctl --address=/proc/"$(cat "$XDG_RUNTIME_DIR/containerd-rootless/child_pid")"/root/run/containerd/containerd.sock \
    run \
    --cap-drop=ALL \
    --cap-add=CAP_SYS_ADMIN,CAP_DAC_OVERRIDE,CAP_CHOWN,CAP_SETFCAP,CAP_MKNOD \
    --rm -it \
    --device=/dev/mapper/control \
    --device=/dev/loop-control \
    --device=/dev/fuse \
    --entrypoint=/bin/sh \
    --insecure-registry "$trim_host_ip:5000/isogen_new:latest"

nerdctl --address=/proc/"$(cat "$XDG_RUNTIME_DIR/containerd-rootless/child_pid")"/root/run/containerd/containerd.sock \
    run     --cap-drop=ALL     --cap-add=CAP_SYS_ADMIN,CAP_DAC_OVERRIDE,CAP_CHOWN,CAP_SETFCAP,CAP_MKNOD     --rm -it     --entrypoint=/bin/sh --insecure-registry localhost:5000/isogen_new


}

nerdqemu() {
    ./scripts/sandbox/run-qemu.sh thirdver

    nerdctl --address=/proc/"$(cat "$XDG_RUNTIME_DIR/containerd-rootless/child_pid")"/root/run/containerd/containerd.sock \
    run --privileged\
    --rm -it \
    --entrypoint=/bin/sh \
    --insecure-registry "$trim_host_ip:5000/isogen_new:latest"
}

crictl() {
    k3s crictl list && echo
}

# Check the argument passed from the command line
if [ "$1" == "build" ]; then
    build
elif [ "$1" == "runtime" ]; then
    runtime
elif [ "$1" == "instant" ]; then
    instant
elif [ "$1" == "standalone" ]; then
    standalone
elif [ "$1" == "debug" ]; then
    debug
elif [ "$1" == "ubuntu" ]; then
    ubuntu
elif [ "$1" == "qemux" ]; then
    qemux
elif [ "$1" == "fish" ]; then
    fish
elif [ "$1" == "otherfish" ]; then
    otherfish
elif [ "$1" == "podyouki" ]; then
    podyouki
elif [ "$1" == "nerdqemu" ]; then
    nerdqemu
else
    echo "Invalid function name. Please specify one of these as argv1: function1, function2, function3"
fi
