# 1. add deb-src
FROM debian:12.1 AS debian-builder

COPY <<EOF /etc/apt/sources.list
deb http://deb.debian.org/debian bookworm main
deb-src http://deb.debian.org/debian bookworm main

deb http://deb.debian.org/debian-security/ bookworm-security main
deb-src http://deb.debian.org/debian-security/ bookworm-security main

deb http://deb.debian.org/debian bookworm-updates main
deb-src http://deb.debian.org/debian bookworm-updates main
EOF

# 2. build dependencies

FROM debian-builder AS dependencies
RUN <<"EOF"
apt-get update
apt-get install build-essential wget git -y
apt-get build-dep linux -y
EOF


# 3. fetch kernel config

FROM dependencies AS download-boot
ARG KERNEL_VERSION=6.6.22

RUN <<"EOF"

WORKDIR /app
mkdir -p ./utils/kernel/
version="./utils/kernel/linux-${KERNEL_VERSION}/"

if [ ! -e $version ]; then
    wget -P ./utils/kernel/ https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VERSION}.tar.xz
    tar -xvf ./utils/kernel/linux-${KERNEL_VERSION}.tar.xz -C ./utils/kernel/
    rm ./utils/kernel/linux-${KERNEL_VERSION}.tar.xz
else
    echo "linux source already downloaded"
fi
# or simply make -f
cd ./utils/kernel/linux-${KERNEL_VERSION}/ || exit

make defconfig
#make kvmconfig removed after Linux 5.10

# add BTF parameters

# Setting BTF parameters
./scripts/config --module CONFIG_VIDEO_SONY_BTF_MPX
./scripts/config --enable CONFIG_DEBUG_INFO_BTF
./scripts/config --enable CONFIG_PAHOLE_HAS_SPLIT_BTF
./scripts/config --enable CONFIG_DEBUG_INFO_BTF_MODULES
./scripts/config --disable CONFIG_MODULE_ALLOW_BTF_MISMATCH
./scripts/config --enable CONFIG_PROBE_EVENTS_BTF_ARGS

# Setting BPF parameters
./scripts/config --enable CONFIG_BPF
./scripts/config --enable CONFIG_HAVE_EBPF_JIT
./scripts/config --enable CONFIG_ARCH_WANT_DEFAULT_BPF_JIT
./scripts/config --enable CONFIG_BPF_SYSCALL
./scripts/config --enable CONFIG_BPF_JIT
./scripts/config --enable CONFIG_BPF_JIT_ALWAYS_ON
./scripts/config --enable CONFIG_BPF_JIT_DEFAULT_ON
./scripts/config --enable CONFIG_BPF_UNPRIV_DEFAULT_OFF
./scripts/config --disable CONFIG_BPF_PRELOAD
./scripts/config --enable CONFIG_BPF_LSM
./scripts/config --enable CONFIG_CGROUP_BPF
./scripts/config --enable CONFIG_IPV6_SEG6_BPF
./scripts/config --enable CONFIG_NETFILTER_BPF_LINK
./scripts/config --module CONFIG_NETFILTER_XT_MATCH_BPF
./scripts/config --disable CONFIG_BPFILTER
./scripts/config --module CONFIG_NET_CLS_BPF
./scripts/config --module CONFIG_NET_ACT_BPF
./scripts/config --enable CONFIG_BPF_STREAM_PARSER
./scripts/config --enable CONFIG_LWTUNNEL_BPF
./scripts/config --enable CONFIG_BPF_LIRC_MODE2
./scripts/config --enable CONFIG_HID_BPF
./scripts/config --enable CONFIG_BPF_EVENTS
./scripts/config --enable CONFIG_BPF_KPROBE_OVERRIDE
./scripts/config --disable CONFIG_TEST_BPF

make kvm_guest.config
echo "kvm_guest.config done"
make olddefconfig
echo "olddefconfig done"
make bzImage
echo "bzImage done"
make -j"$(nproc)"
echo "final kernel make done"
cd - || return
EOF

FROM alpine:3.18 as relay
ARG KERNEL_VERSION=6.6.22
WORKDIR /app/
COPY --from=download-boot ./utils/kernel/linux-${KERNEL_VERSION}/arch/x86/boot/bzImage /app/artifacts/
