#!/bin/sh

build_release() {

    KJX="/app/kjx"
    FIRE_URL="https://github.com/firecracker-microvm/firecracker/releases/download/v1.13.1/firecracker-v1.13.1-x86_64.tgz"

    if ! [ -d "${KJX}" ]; then

        mkdir -p "${KJX}/sources" || return &&
            cd "${KJX}/sources" || return &&
            wget "${FIRE_URL}" --continue --directory-prefix="${KJX}/sources"
    fi
}

build_firecracker() {

    echo TESTTTTTTTTTTTTTTT

    ls -allhtr

    if ! [ -d "./assets/firecracker" ]; then
        mkdir -p ./assets/ &&
            cd ./assets/ || return &&
            git clone https://github.com/firecracker-microvm/firecracker &&
            tools/devtool build &&
            tools/devtool test &&
            toolchain="$(uname -m)-unknown-linux-musl" &&
            cd - || return
    fi
}

net_fire() {
    # this is run at startup once
    sudo ip tuntap add dev ftap0 mode tap &&
        sudo ip addr add 192.168.0.1/24 dev ftap0 &&
        sudo ip link set ftap0 up &&
        ip addr show dev ftap0

}

runsv_service() {
    mkdir -p /etc/runit/sv/firecracker

    cat <<"EOF" >/etc/runit/sv/firecracker/fire-up.sh
#!/bin/sh

firecracker -p
EOF

    ln -s /etc/runit/sv/firecracker/fck-up.sh /run/runit/service/
}

# on submitting jobs to firecracker
submit_fire() {

    # submit kernel, macvlan
    curl --unix-socket /tmp/firecracker.socket -i \
        -X PUT 'http://localhost/boot-source' \
        -H 'Accept: application/json' \
        -H 'Content-Type: application/json' \
        -d "{
            \"kernel_image_path\": \"./artifacts/bzImage\",
            \"boot_args\": \"console=ttyS0 reboot=k panic=1 pci=off init=/init ip=172.16.0.2::172.16.0.1:255.255.255.0::eth0:off\"
       }"

    # Configure memory and vCPUs
    sudo curl --unix-socket /tmp/firecracker.socket -i \
        -X PUT 'http://localhost/machine-config' \
        -H 'Accept: application/json' \
        -H 'Content-Type: application/json' \
        -d '{
        "vcpu_count": 2,
        "mem_size_mib": 256
    }'

    # configure network device
    sudo curl -X put \
        --unix-socket /tmp/firecracker.socket \
        'http://localhost:network-interfaces/eth0' \
        -H accept:application/json \
        -H content-type:application/json \
        -d '{
        "iface_id": "eth0",
        "host_dev_name": "ftap0"
        }'

    # the first drive should look to the rootfs image
    sudo curl --unix-socket /tmp/firecracker.socket -i \
        -X PUT 'http://localhost:actions' \
        -H 'Accept: application/json' \
        -H 'Content-Type: application/json' \
        -d "{ \
            \"drive_id\": \"./rootfs.img\",
            \"path_on_host\": \"./rootfs.img\",
            \"is_root_device\": true,
            \"is_read_only\": false
    }"

    # boot the vm
    sudo curl --unix-socket /tmp/firecracker.socket -i \
        -X PUT 'http://localhost:actions' \
        -H 'Accept: application/json' \
        -H 'Content-Type: application/json' \
        -d '{
        "action_type": "InstanceStart"
    }'
}

fc_pre_req() {
    # https://github.com/firecracker-microvm/firecracker-containerd/blob/main/docs/getting-started.md#prerequisites

    echo

    if ! [ "$(uname) $(uname -m)" = "Linux x86_64" ]; then
        echo "|> ERROR: your system is not Linux x86_64. ...[FAILED]"
        return 1
    fi
    echo "|> Sucessfully detected your system as [Linux x86_64]. ...[PASSED]"

    # -w file exists and is writable
    # -r file exists and is readable
    if ! [ -r /dev/kvm ] && ! [ -w /dev/kvm ]; then
        echo "|> ERROR: /dev/kvm is inaccessible."
        return 1
    fi
    echo "|> Sucessfully detected  [/dev/kvm] as acessible. ...[PASSED]"

    #!/bin/sh
    err=""
    [ "$(uname) $(uname -m)" = "Linux x86_64" ] ||
        err="ERROR: your system is not Linux x86_64."
    [ -r /dev/kvm ] && [ -w /dev/kvm ] ||
        err="$err\nERROR: /dev/kvm is inaccessible."
    ( ("$(uname -r | cut -d. -f1)*1000" + "$(uname -r | cut -d. -f2)" 4014 >=)) ||
        err="$err\nERROR: your kernel version ($(uname -r)) is too old."
    dmesg | grep -i "hypervisor detected" &&
        echo "WARNING: you are running in a virtual machine. Firecracker is not well tested under nested virtualization."
    [ -z "$err" ] && echo "Your system looks ready for Firecracker!" || echo -e "$err"
}

firecracker_containerd() {
    # docs: https://github.com/firecracker-microvm/firecracker-containerd/blob/main/docs/
    # run on a container pipeline

    # Previous dependencies goes into Dockerfile logic
    DISTRO_CHECK="$(cat "/etc/os-release" | grep Alpine)"

    if ! "${DISTRO_CHECK}"; then
        printf
        return 1
    fi
    printf "\n|> Running on an Alpine distro... proceeding...\n\n"

    # Set firecracker-containerd directories
    SNAPSHOTTER_BIN_DIR="/etc/firecracker-containerd"
    ALTERNATE_STORAGE_DIR="/var/lib/firecracker-containerd/containerd"
    SHIM_BASE_DIR="/var/lib/firecracker-containerd"
    # Set device mapper thin pool
    DEVMAPPER_DIR="/var/lib/firecracker-containerd/snapshotter/devmapper"
    DEVMAPPER_POOL="fc-dev-thinpool"

    # Create paths
    mkdir -p "${SNAPSHOTTER_BIN_DIR}"
    mkdir -p "${ALTERNATE_STORAGE_DIR}"
    mkdir -p "${SHIM_BASE_DIR}"
    mkdir -p "${DEVMAPPER_DIR}"

    (
        cat <<EOF
version = 2
disabled_plugins = ["io.containerd.grpc.v1.cri"]
root = "/var/lib/firecracker-containerd/containerd"
state = "/run/firecracker-containerd"
[grpc]
  address = "/run/firecracker-containerd/containerd.sock"
[plugins]
  [plugins."io.containerd.snapshotter.v1.devmapper"]
    pool_name = "fc-dev-thinpool"
    base_image_size = "10GB"
    root_path = "/var/lib/firecracker-containerd/snapshotter/devmapper"

[debug]
  level = "debug"
EOF
    ) | tee "${SNAPSHOTTER_BIN_DIR}"/config.toml

    # Device Mapper Thin provisioning setup
    #
    # See Documentation/device-mapper/thin-provisioning.txt for parameters and usage.
    # Thin pools are to block devices what sparse files are to filesystems.

    if ! [ -f "${DEVMAPPER_DIR}/data" ]; then
        if ! (touch "${DEVMAPPER_DIR:-[EMPTY_VARIABLE]}/data"); then
            echo "|> Error: could not create the [${DEVMAPPER_DIR:-[EMPTY_VARIABLE]}/data] filepath. Exiting now..."
            return 1
        fi
        echo "|> Sucessfully created the [${DEVMAPPER_DIR:-[EMPTY_VARIABLE]}/data] filepath. Proceeding..."

        # if ! (truncate -s 100G "${DEVMAPPER_DIR:-[EMPTY_VARIABLE]}/data"); then
        # sparse file
        if ! (truncate -s 200MB "${DEVMAPPER_DIR:-[EMPTY_VARIABLE]}/data"); then
            echo "|> Error: could not create the SPARSE FILE [${DEVMAPPER_DIR:-[EMPTY_VARIABLE]}/data] filepath with truncate. Exiting now..."
            return 1
        fi
        echo "|> Sucessfully created the SPARSE FILE [${DEVMAPPER_DIR:-[EMPTY_VARIABLE]}/data] filepath with truncate. Proceeding..."
    fi

    if ! [ -f "${DEVMAPPER_DIR}/metadata" ]; then

        if ! (touch "${DEVMAPPER_DIR}/metadata"); then
            echo "|> Error: could not create the [${DEVMAPPER_DIR:-[EMPTY_VARIABLE]}/metadata] filepath. Exiting now..."
            return 1
        fi
        echo "|> Sucessfully created the [${DEVMAPPER_DIR:-[EMPTY_VARIABLE]}/metadata] filepath. Proceeding..."

        if ! (truncate -s 2G "${DEVMAPPER_DIR}/metadata"); then
            echo "|> Error: could not create the SPARSE FILE [${DEVMAPPER_DIR:-[EMPTY_VARIABLE]}/metadata] filepath with truncate. Exiting now..."
            return 1
        fi
        echo "|> Sucessfully created the SPARSE FILE [${DEVMAPPER_DIR:-[EMPTY_VARIABLE]}/metadata] filepath with truncate. Proceeding..."
    fi

    DATADEV="$(losetup --output NAME --noheadings --associated ${DEVMAPPER_DIR}/data)"
    if [ -z "${DATADEV}" ]; then
        DATADEV="$(losetup --find --show ${DEVMAPPER_DIR}/data)"
    fi

    METADEV="$(losetup --output NAME --noheadings --associated ${DEVMAPPER_DIR}/metadata)"
    if [ -z "${METADEV}" ]; then
        METADEV="$(losetup --find --show ${DEVMAPPER_DIR}/metadata)"
    fi

    SECTORSIZE=512
    DATASIZE="$(blockdev --getsize64 -q "${DATADEV}")"
    LENGTH_SECTORS=$(
        bc <<EOF
    "${DATASIZE}/${SECTORSIZE}"
EOF
    )
    DATA_BLOCK_SIZE=128
    LOW_WATER_MARK=32768
    THINP_TABLE="0 ${LENGTH_SECTORS} thin-pool ${METADEV} ${DATADEV} ${DATA_BLOCK_SIZE} ${LOW_WATER_MARK} 1 skip_block_zeroing"
    echo "${THINP_TABLE}"
    DMSETUP_RELOAD="$(dmsetup reload "${POOL}" --table "${THINP_TABLE}")"

    if ! "${DMSETUP_RELOAD}"; then
        dmsetup create "${POOL}" --table "${THINP_TABLE}"
    fi

}

print_usage() {
    cat <<-END >&2
USAGE: firecracker-startup [-options]
                - build
                - version
                - help
eg,
MODE="build"        ./firecracker-startup.sh   # Fetch dependencies for all-in-one gvisor
MODE="version"      ./firecracker-startup.sh   # shows script version
MODE="help"         ./firecracker-startup.sh   # shows this help message

See the man page and example file for more info.

END

}

if [ "${MODE}" = "-build" ] || [ "${MODE}" = "--build" ] || [ "${MODE}" = "build" ]; then
    #build_firecracker
    build_release
elif [ "${MODE}" = "-help" ] || [ "${MODE}" = "-h" ] || [ "${MODE}" = "--help" ]; then
    print_usage
elif [ "${MODE}" = "version" ] || [ "${MODE}" = "-v" ] || [ "${MODE}" = "--version" ]; then
    printf "\n|> Version: firecracker-startup 1.0.0"
else
    echo "Invalid function name. Please specify one of the available functions:"
    print_usage
fi
