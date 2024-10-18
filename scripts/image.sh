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
cat <<"EOF"
==========
Running now:

podman run --userns=auto --cap-drop=ALL \
    --cap-add=CAP_SYS_ADMIN,CAP_DAC_OVERRIDE,CAP_CHOWN,CAP_SETFCAP,CAP_MKNOD \
    --device=/dev/mapper/control --device=/dev/loop-control \
    --device=/dev/fuse \
    --rm -it 324bc02ae123
==========

EOF

podman run --userns=auto --cap-drop=ALL \
    --cap-add=CAP_SYS_ADMIN,CAP_DAC_OVERRIDE,CAP_CHOWN,CAP_SETFCAP,CAP_MKNOD \
    --device=/dev/mapper/control --device=/dev/loop-control \
    --device=/dev/fuse \
    --rm -it 324bc02ae123
}

debug() {
    echo
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
else
    echo "Invalid function name. Please specify one of: function1, function2, function3"
fi
