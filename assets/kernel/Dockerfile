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

# code coverage
./scripts/config --enable CONFIG_DEBUG_FS
./scripts/config --enable CONFIG_GCOV_KERNEL

# set BTF parameters
./scripts/config --enable CONFIG_DEBUG_INFO_BTF
./scripts/config --enable CONFIG_PAHOLE_HAS_SPLIT_BTF
./scripts/config --enable CONFIG_DEBUG_INFO_BTF_MODULES
./scripts/config --disable CONFIG_MODULE_ALLOW_BTF_MISMATCH
./scripts/config --enable CONFIG_PROBE_EVENTS_BTF_ARGS

# set BPF parameters
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

# Enable modules support
./scripts/config --enable CONFIG_MODULES

# Enable the securityfs filesystem
./scripts/config --enable CONFIG_SECURITY
./scripts/config --enable CONFIG_SECURITYFS

# to be able to append to /sys/fs/cgroup/cgroup.subtree_control,
# you need a kernel with the memory controller available.
./scripts/config --enable CONFIG_MEMCG
./scripts/config --enable CONFIG_MEMCG_KMEM

# enable overlay support
# this is needed in order to mount the containerd device at /tmp
./scripts/config --enable CONFIG_LD_CAN_USE_KEEP_IN_OVERLAY
./scripts/config --enable CONFIG_EFI_CUSTOM_SSDT_OVERLAYS
./scripts/config --module CONFIG_OVERLAY_FS
# ./scripts/config --enable CONFIG_OVERLAY_FS
./scripts/config --enable CONFIG_OVERLAY_FS_REDIRECT_DIR
# ./scripts/config --enable # CONFIG_OVERLAY_FS_REDIRECT_ALWAYS_FOLLOW is not set
./scripts/config --enable CONFIG_OVERLAY_FS_INDEX
./scripts/config --enable CONFIG_OVERLAY_FS_XINO_AUTO
./scripts/config --enable CONFIG_OVERLAY_FS_METACOPY
# ./scripts/config --enable # CONFIG_OVERLAY_FS_DEBUG is not set

# enable /proc/config.gz file at runtime
./scripts/config --enable CONFIG_IKCONFIG
./scripts/config --enable CONFIG_IKCONFIG_PROC

# enable cgroups support
./scripts/config --enable CONFIG_CGROUPS
./scripts/config --enable CONFIG_BLK_CGROUP
./scripts/config --enable CONFIG_CGROUP_WRITEBACK
./scripts/config --enable CONFIG_CGROUP_SCHED
./scripts/config --enable CONFIG_CGROUP_PIDS
./scripts/config --enable CONFIG_CGROUP_RDMA
./scripts/config --enable CONFIG_CGROUP_FREEZER
./scripts/config --enable CONFIG_CGROUP_HUGETLB
./scripts/config --enable CONFIG_CGROUP_DEVICE
./scripts/config --enable CONFIG_CGROUP_CPUACCT
./scripts/config --enable CONFIG_CGROUP_PERF
./scripts/config --enable CONFIG_CGROUP_BPF
./scripts/config --enable CONFIG_CGROUP_MISC
./scripts/config --enable CONFIG_SOCK_CGROUP_DATA
./scripts/config --enable CONFIG_BLK_CGROUP_RWSTAT
./scripts/config --enable CONFIG_BLK_CGROUP_PUNT_BIO
./scripts/config --enable CONFIG_BLK_CGROUP_IOLATENCY
./scripts/config --enable CONFIG_BLK_CGROUP_FC_APPID
./scripts/config --enable CONFIG_BLK_CGROUP_IOCOST
./scripts/config --enable CONFIG_BLK_CGROUP_IOPRIO
./scripts/config --module CONFIG_NETFILTER_XT_MATCH_CGROUP
./scripts/config --module CONFIG_NET_CLS_CGROUP
./scripts/config --enable CONFIG_CGROUP_NET_PRIO
./scripts/config --enable CONFIG_CGROUP_NET_CLASSID

# trace support
./scripts/config --enable CONFIG_TASKS_TRACE_RCU
./scripts/config --enable CONFIG_SYSCTL_EXCEPTION_TRACE
./scripts/config --enable CONFIG_TRACEPOINTS
./scripts/config --enable CONFIG_STACKTRACE_SUPPORT
./scripts/config --enable CONFIG_PM_TRACE
./scripts/config --enable CONFIG_PM_TRACE_RTC
./scripts/config --enable CONFIG_KPROBES_ON_FTRACE
./scripts/config --enable CONFIG_HAVE_KPROBES_ON_FTRACE
./scripts/config --enable CONFIG_ARCH_CORRECT_STACKTRACE_ON_KRETPROBE
./scripts/config --enable CONFIG_TRACE_IRQFLAGS_SUPPORT
./scripts/config --enable CONFIG_TRACE_IRQFLAGS_NMI_SUPPORT
./scripts/config --enable CONFIG_HAVE_ARCH_TRACEHOOK
./scripts/config --enable CONFIG_HAVE_RELIABLE_STACKTRACE
./scripts/config --enable CONFIG_SCSI_IPR_TRACE
./scripts/config --enable CONFIG_ATH5K_TRACER
./scripts/config --enable CONFIG_STACKTRACE_BUILD_ID
./scripts/config --enable CONFIG_STACKTRACE
./scripts/config --enable CONFIG_USER_STACKTRACE_SUPPORT
./scripts/config --enable CONFIG_NOP_TRACER
./scripts/config --enable CONFIG_HAVE_FUNCTION_TRACER
./scripts/config --enable CONFIG_HAVE_FUNCTION_GRAPH_TRACER
./scripts/config --enable CONFIG_HAVE_DYNAMIC_FTRACE
./scripts/config --enable CONFIG_HAVE_DYNAMIC_FTRACE_WITH_REGS
./scripts/config --enable CONFIG_HAVE_DYNAMIC_FTRACE_WITH_DIRECT_CALLS
./scripts/config --enable CONFIG_HAVE_DYNAMIC_FTRACE_WITH_ARGS
./scripts/config --enable CONFIG_HAVE_DYNAMIC_FTRACE_NO_PATCHABLE
./scripts/config --enable CONFIG_HAVE_FTRACE_MCOUNT_RECORD
./scripts/config --enable CONFIG_HAVE_SYSCALL_TRACEPOINTS
./scripts/config --enable CONFIG_TRACER_MAX_TRACE
./scripts/config --enable CONFIG_TRACE_CLOCK
./scripts/config --enable CONFIG_CONTEXT_SWITCH_TRACER
./scripts/config --enable CONFIG_GENERIC_TRACER
./scripts/config --enable CONFIG_FTRACE
./scripts/config --enable CONFIG_FUNCTION_TRACER
./scripts/config --enable CONFIG_FUNCTION_GRAPH_TRACER
./scripts/config --enable CONFIG_DYNAMIC_FTRACE
./scripts/config --enable CONFIG_DYNAMIC_FTRACE_WITH_REGS
./scripts/config --enable CONFIG_DYNAMIC_FTRACE_WITH_DIRECT_CALLS
./scripts/config --enable CONFIG_DYNAMIC_FTRACE_WITH_ARGS
./scripts/config --enable CONFIG_STACK_TRACER
./scripts/config --enable CONFIG_SCHED_TRACER
./scripts/config --enable CONFIG_HWLAT_TRACER
./scripts/config --enable CONFIG_OSNOISE_TRACER
./scripts/config --enable CONFIG_TIMERLAT_TRACER
./scripts/config --enable CONFIG_MMIOTRACE
./scripts/config --enable CONFIG_FTRACE_SYSCALLS
./scripts/config --enable CONFIG_TRACER_SNAPSHOT
./scripts/config --enable CONFIG_BLK_DEV_IO_TRACE
./scripts/config --enable CONFIG_FTRACE_MCOUNT_RECORD
./scripts/config --enable CONFIG_FTRACE_MCOUNT_USE_CC
./scripts/config --enable CONFIG_HAVE_SAMPLE_FTRACE_DIRECT
./scripts/config --enable CONFIG_HAVE_SAMPLE_FTRACE_DIRECT_MULTI
./scripts/config --enable CONFIG_HAVE_MMIOTRACE_SUPPORT
./scripts/config --enable CONFIG_CC_HAS_SANCOV_TRACE_PC

# ftrace modules
./scripts/config --module CONFIG_STM_SOURCE_FTRACE
./scripts/config --module CONFIG_NETFILTER_XT_TARGET_TRACE


# enable SELinux as LSM; PS: also mount the securityfs at boot
./scripts/config --enable CONFIG_SECURITY_SELINUX
./scripts/config --enable CONFIG_SECURITY_SELINUX_BOOTPARAM
./scripts/config --set-str CONFIG_SECURITY_SELINUX_BOOTPARAM_VALUE 1

# provide symbol table to debug startup
./scripts/config --enable CONFIG_DEBUG_INFO
./scripts/config --enable DEBUG_INFO


# other security configs
./scripts/config --enable CONFIG_HAVE_ARCH_SECCOMP
./scripts/config --enable CONFIG_HAVE_ARCH_SECCOMP_FILTER
./scripts/config --enable CONFIG_SECCOMP
./scripts/config --enable CONFIG_SECCOMP_FILTER
./scripts/config --enable CONFIG_SECRETMEM
./scripts/config --enable CONFIG_NETWORK_SECMARK
./scripts/config --enable CONFIG_NF_CONNTRACK_SECMARK
./scripts/config --module CONFIG_NETFILTER_XT_TARGET_CONNSECMARK
./scripts/config --module CONFIG_NETFILTER_XT_TARGET_SECMARK
./scripts/config --module CONFIG_IP_NF_SECURITY
./scripts/config --module CONFIG_IP6_NF_SECURITY
./scripts/config --enable CONFIG_EFI_COCO_SECRET
./scripts/config --enable CONFIG_MTD_SPI_NOR_USE_4K_SECTORS
./scripts/config --enable CONFIG_DM_VERITY_VERIFY_ROOTHASH_SIG_SECONDARY_KEYRING
./scripts/config --module CONFIG_MACSEC
./scripts/config --module CONFIG_CHELSIO_IPSEC_INLINE
./scripts/config --enable CONFIG_IXGBEVF_IPSEC
./scripts/config --enable CONFIG_MLX5_MACSEC
./scripts/config --enable CONFIG_MLX5_EN_IPSEC
./scripts/config --enable CONFIG_NFP_NET_IPSEC
./scripts/config --module CONFIG_CEC_SECO
./scripts/config --enable CONFIG_CEC_SECO_RC
./scripts/config --enable CONFIG_DRM_AMD_SECURE_DISPLAY
./scripts/config --module CONFIG_EFI_SECRET
./scripts/config --module CONFIG_INTEL_VSEC
./scripts/config --module CONFIG_FPGA_M10_BMC_SEC_UPDATE
./scripts/config --enable CONFIG_EXT4_FS_SECURITY
./scripts/config --enable CONFIG_F2FS_FS_SECURITY
./scripts/config --enable CONFIG_JFFS2_FS_SECURITY
./scripts/config --enable CONFIG_UBIFS_FS_SECURITY
./scripts/config --enable CONFIG_EROFS_FS_SECURITY
./scripts/config --enable CONFIG_NFS_V4_SECURITY_LABEL
./scripts/config --enable CONFIG_NFSD_V4_SECURITY_LABEL
./scripts/config --module CONFIG_RPCSEC_GSS_KRB5
./scripts/config --enable CONFIG_RPCSEC_GSS_KRB5_ENCTYPES_AES_SHA1
./scripts/config --enable CONFIG_RPCSEC_GSS_KRB5_ENCTYPES_CAMELLIA
./scripts/config --enable CONFIG_RPCSEC_GSS_KRB5_ENCTYPES_AES_SHA2
./scripts/config --enable CONFIG_CEPH_FS_SECURITY_LABEL
./scripts/config --enable CONFIG_CIFS_ALLOW_INSECURE_LEGACY
./scripts/config --enable CONFIG_9P_FS_SECURITY
./scripts/config --enable CONFIG_SECURITY_DMESG_RESTRICT
./scripts/config --enable CONFIG_SECURITY
./scripts/config --enable CONFIG_SECURITYFS
./scripts/config --enable CONFIG_SECURITY_NETWORK
./scripts/config --enable CONFIG_SECURITY_INFINIBAND
./scripts/config --enable CONFIG_SECURITY_NETWORK_XFRM
./scripts/config --enable CONFIG_SECURITY_PATH
./scripts/config --enable CONFIG_SECURITY_SELINUX
./scripts/config --enable CONFIG_SECURITY_SELINUX_BOOTPARAM
./scripts/config --enable CONFIG_SECURITY_SELINUX_DEVELOP
./scripts/config --enable CONFIG_SECURITY_SELINUX_AVC_STATS
./scripts/config --set-val CONFIG_SECURITY_SELINUX_SIDTAB_HASH_BITS 9
./scripts/config --set-val CONFIG_SECURITY_SELINUX_SID2STR_CACHE_SIZE 256
./scripts/config --enable CONFIG_SECURITY_SMACK
./scripts/config --enable CONFIG_SECURITY_SMACK_BRINGUP
./scripts/config --enable CONFIG_SECURITY_SMACK_NETFILTER
./scripts/config --enable CONFIG_SECURITY_SMACK_APPEND_SIGNALS
./scripts/config --enable CONFIG_SECURITY_TOMOYO
./scripts/config --set-val CONFIG_SECURITY_TOMOYO_MAX_ACCEPT_ENTRY 2048
./scripts/config --set-val CONFIG_SECURITY_TOMOYO_MAX_AUDIT_LOG 1024
./scripts/config --set-str CONFIG_SECURITY_TOMOYO_POLICY_LOADER "/usr/bin/tomoyo-init"
./scripts/config --set-str CONFIG_SECURITY_TOMOYO_ACTIVATION_TRIGGER "/usr/lib/systemd/systemd"
./scripts/config --enable CONFIG_SECURITY_APPARMOR
./scripts/config --enable CONFIG_SECURITY_APPARMOR_INTROSPECT_POLICY
./scripts/config --enable CONFIG_SECURITY_APPARMOR_HASH
./scripts/config --enable CONFIG_SECURITY_APPARMOR_HASH_DEFAULT
./scripts/config --enable CONFIG_SECURITY_APPARMOR_EXPORT_BINARY
./scripts/config --enable CONFIG_SECURITY_APPARMOR_PARANOID_LOAD
./scripts/config --enable CONFIG_SECURITY_LOADPIN
./scripts/config --enable CONFIG_SECURITY_LOADPIN_ENFORCE
./scripts/config --enable CONFIG_SECURITY_YAMA
./scripts/config --enable CONFIG_SECURITY_SAFESETID
./scripts/config --enable CONFIG_SECURITY_LOCKDOWN_LSM
./scripts/config --enable CONFIG_SECURITY_LANDLOCK
./scripts/config --enable CONFIG_SECURITY_IPE
./scripts/config --enable CONFIG_IPE_POLICY_SIG_SECONDARY_KEYRING
./scripts/config --enable CONFIG_DEFAULT_SECURITY_DAC
./scripts/config --enable CONFIG_SECONDARY_TRUSTED_KEYRING
./scripts/config --enable CONFIG_SECTION_MISMATCH_WARN_ONLY


# enable squashfs support
./scripts/config --enable CONFIG_SQUASHFS
./scripts/config --enable CONFIG_SQUASHFS_ZLIB
./scripts/config --enable CONFIG_SQUASHFS_LZ4
./scripts/config --enable CONFIG_SQUASHFS_LZO
./scripts/config --enable CONFIG_SQUASHFS_XZ
./scripts/config --enable CONFIG_SQUASHFS_4K_DEVBLK_SIZE

# final make commands
make kvm_guest.config
echo "kvm_guest.config done"
make olddefconfig
echo "olddefconfig done"
make bzImage
echo "bzImage done"
make -j"$(nproc)"
echo "final kernel make done"

printf "\n|> Modules setup ========="

# modules setup
make modules

mkdir -p /mnt/lfs/

make INSTALL_MOD_PATH=/mnt/lfs modules_install

cd - || return

cd /app
tar -czf ./ko_tarball.tar.gz /mnt/lfs/

EOF

FROM alpine:3.18 as relay
ARG KERNEL_VERSION=6.6.22
WORKDIR /app/
COPY --from=download-boot ./utils/kernel/linux-${KERNEL_VERSION}/arch/x86/boot/bzImage /app/artifacts/
COPY --from=download-boot /app/ko_tarball.tar.gz /app/artifacts/
