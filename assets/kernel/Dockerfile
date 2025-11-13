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

WORKDIR /app

RUN <<"EOF"

mkdir -p /app/utils/kernel/
version="/app/utils/kernel/linux-${KERNEL_VERSION}/"

if [ ! -e $version ]; then
    wget -P /app/utils/kernel/ https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VERSION}.tar.xz
    tar -xvf /app/utils/kernel/linux-${KERNEL_VERSION}.tar.xz -C /app/utils/kernel/
    rm /app/utils/kernel/linux-${KERNEL_VERSION}.tar.xz
else
    echo "linux source already downloaded"
fi
# or simply make -f
cd /app/utils/kernel/linux-${KERNEL_VERSION}/ || exit

make defconfig
#make kvmconfig removed after Linux 5.10

# KVM Configuration
make kvm_guest.config
echo "kvm_guest.config done"


## Defaults the config
make olddefconfig
echo "olddefconfig done"


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

./scripts/config --enable CONFIG_IPV6
./scripts/config --enable CONFIG_IPV6_SEG6_LWTUNNEL
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

# enable fuse-overlayfs support
./scripts/config --enable CONFIG_FUSE_FS

    # fuse_dax dependencies
    ./scripts/config --enable CONFIG_VIRTIO_FS

    # CONFIG_ZONE_DEVICE Device memory (pmem, HMM, etc...) hotplug support
    ./scripts/config --enable CONFIG_ZONE_DEVICE

        ./scripts/config --enable CONFIG_SPARSEMEM_VMEMMAP

            ./scripts/config --enable CONFIG_SPARSEMEM
            ./scripts/config --enable CONFIG_ARCH_SPARSEMEM_ENABLE
            ./scripts/config --enable CONFIG_SPARSEMEM_VMEMMAP_ENABLE

        ./scripts/config --enable CONFIG_ARCH_HAS_PTE_DEVMAP

        ./scripts/config --enable CONFIG_MEMORY_HOTPLUG
        ./scripts/config --enable CONFIG_MEMORY_HOTREMOVE

            # CONFIG_MEMORY_HOTPLUG
            ./scripts/config --enableCONFIG_ARCH_ENABLE_MEMORY_HOTREMOVE
            # page migration support
            ./scripts/config --enable CONFIG_MIGRATION

            ./scripts/config --enable CONFIG_SPARSEMEM_VMEMMAP
        # CONFIG_ARCH_HAS_PTE_DEVMAP dependencies
        ./scripts/config --enable CONFIG_ARCH_HAS_PTE_DEVMAP
        # ( CONFIG_NUMA || CONFIG_ARCH_ENABLE_MEMORY_HOTREMOVE || CONFIG_COMPACTION || CONFIG_CMA ) && CONFIG_MMU
            # NUMA dependencies
            ./scripts/config --enable CONFIG_NUMA
            # ( CONFIG_SMP ) && ( CONFIG_X86_64 )
            ./scripts/config --enable CONFIG_CPU_CK860
            ./scripts/config --enable CONFIG_SMP
            ./scripts/config --enable CONFIG_X86_64

        ./scripts/config --enable CONFIG_ARCH_ENABLE_MEMORY_HOTREMOVE
        ./scripts/config --enable CONFIG_MMU
        ./scripts/config --enable CONFIG_COMPACTION
        ./scripts/config --enable CONFIG_CMA


# CONFIG_MEMORY_HOTPLUG support
    ./scripts/config --enable CONFIG_ARCH_ENABLE_MEMORY_HOTPLUG
    ./scripts/config --enable CONFIG_64BIT

    # Sparsemem support
    # this should not be set: CONFIG_SELECT_MEMORY_MODEL
    ./scripts/config --enable CONFIG_ARCH_SPARSEMEM_ENABLE
    ./scripts/config --enable CONFIG_SPARSEMEM


#####
./scripts/config --enable CONFIG_FS_DAX

# FS_DAX_PMD support
./scripts/config --enable CONFIG_FS_DAX_PMD
./scripts/config --enable CONFIG_HAVE_ARCH_TRANSPARENT_HUGEPAGE
# do not set: CONFIG_PREEMPT_RT

# CONFIG_DAX support
./scripts/config --enable CONFIG_DAX
./scripts/config --enable CONFIG_FUSE_DAX

# fuse_passthrough dependencies
./scripts/config --enable CONFIG_FUSE_PASSTHROUGH

# fuse_io_uring dependencies
./scripts/config --enable CONFIG_FUSE_IO_URING
./scripts/config --enable CONFIG_IO_URING
./scripts/config --enable CONFIG_EXPERT

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

# Ftrace function profiler support
./scripts/config --enable CONFIG_FUNCTION_PROFILER

# hist-triggers trace support
./scripts/config --enable CONFIG_ARCH_HAVE_NMI_SAFE_CMPXCHG
./scripts/config --enable CONFIG_HIST_TRIGGERS

# Enable the kernel runtime verification infrastructure
# also related to ftrace
./scripts/config --enable CONFIG_TRACING
./scripts/config --enable CONFIG_TRACING_SUPPORT
./scripts/config --enable CONFIG_TRACING_MAP
./scripts/config --enable CONFIG_RV

# other ftrace modules
./scripts/config --module CONFIG_STM_SOURCE_FTRACE
./scripts/config --module CONFIG_NETFILTER_XT_TARGET_TRACE


# enable SELinux as LSM; PS: also mount the securityfs at boot
./scripts/config --enable CONFIG_SECURITY_SELINUX
./scripts/config --enable CONFIG_SECURITY_SELINUX_BOOTPARAM
./scripts/config --set-str CONFIG_SECURITY_SELINUX_BOOTPARAM_VALUE 1

# provide symbol table to debug startup
./scripts/config --enable CONFIG_DEBUG_INFO
./scripts/config --enable DEBUG_INFO

# ensure 9P/9pfs options are available
./scripts/config --enable CONFIG_NET_9P
./scripts/config --enable CONFIG_9P_FS
./scripts/config --enable CONFIG_9P_FS_SECURITY
./scripts/config --enable CONFIG_NET_9P_VIRTIO
./scripts/config --enable CONFIG_NET_9P_DEBUG # (Optional)
./scripts/config --enable CONFIG_9P_FS_POSIX_ACL

# PCI and virtio
./scripts/config --enable CONFIG_PCI
./scripts/config --enable CONFIG_VIRTIO_PCI
./scripts/config --enable CONFIG_PCI_HOST_GENERIC # QEMU arm virt board

# frame pointer for tracing kernel functions with kprobes
./scripts/config --enable CONFIG_FRAME_POINTER

# enable trace events for preempt and irq disable/enable
./scripts/config --enable CONFIG_PREEMPTIRQ_EVENTS

# enable tracing and statistics about kernel locks from /proc/lock_stat
./scripts/config --enable CONFIG_LOCK_STAT

# SLUB (unqueued allocator), a slab allocator
./scripts/config --enable CONFIG_SLUB
# SLUB is a slab allocator that minimizes cache line usage instead of managing queues of cached objects (SLAB approach).
# Per cpu caching is realized using slabs of objects instead of queues of objects. SLUB can use memory efficiently and
# has enhanced diagnostics. SLUB is the default choice for a slab allocator.

# trace CPU statistics accuracy
    # measures CPU utilization with a granularity of clock ticks [Weisbecker 13]
    ./scripts/config --enable CONFIG_TICK_CPU_ACCOUNTING
    # timer frequency
    ./scripts/config --enable CONFIG_HZ_1000
    ./scripts/config --set-val CONFIG_HZ 1000

    ./scripts/config --enable CONFIG_VIRT_CPU_ACCOUNTING
    ./scripts/config --enable CONFIG_VIRT_CPU_ACCOUNTING_GEN
    ./scripts/config --enable CONFIG_HAVE_VIRT_CPU_ACCOUNTING_GEN

    # Collect scheduler statistics
    ./scripts/config --enable CONFIG_SCHEDSTATS
    ./scripts/config --enable CONFIG_SCHED_DEBUG
    ./scripts/config --enable CONFIG_PSI

# Enable per-task delay accounting
# ( sourced from /proc/schedstat but exposed with other delay accounting states
# found in struct sched_info.

    # pre-requisites for delay accounting
    ./scripts/config --enable CONFIG_EXPERT
    ./scripts/config --enable CONFIG_MULTIUSER
    ./scripts/config --enable CONFIG_NET

    # (* taskstats is a netlink-based interface to send per-task
    # and per-process statistics from the kernel to userspace.*)
    ./scripts/config --enable CONFIG_TASKSTATS
    ./scripts/config --enable CONFIG_TASK_DELAY_ACCT

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
./scripts/config --enable CONFIG_SECURITY_DMESG_RESTRICT
./scripts/config --enable CONFIG_SECURITY
./scripts/config --enable CONFIG_SECURITYFS
./scripts/config --enable CONFIG_AUDIT
./scripts/config --enable CONFIG_AUDITSYSCALL
./scripts/config --enable CONFIG_AUDIT_ARCH
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
# ./scripts/config --enable CONFIG_DEFAULT_SECURITY_DAC
./scripts/config --enable CONFIG_SECONDARY_TRUSTED_KEYRING
./scripts/config --enable CONFIG_SECTION_MISMATCH_WARN_ONLY


# enable squashfs support
./scripts/config --enable CONFIG_SQUASHFS
./scripts/config --enable CONFIG_SQUASHFS_ZLIB
./scripts/config --enable CONFIG_SQUASHFS_LZ4
./scripts/config --enable CONFIG_SQUASHFS_LZO
./scripts/config --enable CONFIG_SQUASHFS_XZ
./scripts/config --enable CONFIG_SQUASHFS_4K_DEVBLK_SIZE

# enable the tun module
./scripts/config --module CONFIG_TUN

# Enable dynamic management of the /dev directory with
# devtmpfs + mdev
./scripts/config --enable CONFIG_DEVTMPFS
./scripts/config --enable CONFIG_DEVTMPFS_MOUNT
./scripts/config --enable CONFIG_DEVTMPFS_SAFE

# More modules to shut up the autoconf restart config
./scripts/config --module CONFIG_BRIDGE_NF_EBTABLES_LEGACY
./scripts/config --module CONFIG_BRIDGE_NF_EBTABLES

# More network virt subsystem dependencies for k3s
./scripts/config --module CONFIG_VETH
./scripts/config --module CONFIG_BRIDGE

# Generate the br_netfilter module
# ./scripts/config --enable CONFIG_IPV6
# ./scripts/config --enable CONFIG_IPV6_SEG6_LWTUNNEL

# CONFIG_BRIDGE_NETFILTER resolution
./scripts/config --module CONFIG_BRIDGE
./scripts/config --enable CONFIG_NETFILTER
./scripts/config --enable CONFIG_INET
./scripts/config --enable CONFIG_NETFILTER_ADVANCED
./scripts/config --module CONFIG_BRIDGE_NETFILTER

./scripts/config --module CONFIG_NETFILTER_XT_MATCH_IPVS
./scripts/config --module CONFIG_NETFILTER_XT_MATCH_COMMENT
./scripts/config --module CONFIG_NETFILTER_XT_MATCH_MULTIPORT

# Some kernel symbols
./scripts/config --enable CONFIG_KALLSYMS
./scripts/config --enable CONFIG_KALLSYMS_ALL
./scripts/config --enable CONFIG_KALLSYMS_ABSOLUTE_PERCPU

# Ring buffer
./scripts/config --enable CONFIG_RING_BUFFER

# Netboot/PXE
./scripts/config --enable CONFIG_IP_PNP         # IP: kernel level autoconfiguration
./scripts/config --enable CONFIG_IP_PNP_BOOTP   # BOOTP support. Check the if the network ROM already doesn't does it
./scripts/config --enable CONFIG_IP_PNP_DHCP    # DHCP support
# Add more missing modules
./scripts/config --enable CONFIG_USER_NS
./scripts/config --enable CONFIG_BLK_DEV_THROTTLING
./scripts/config --enable CONFIG_CFS_BANDWIDTH
# CONFIG_RT_GROUP_SCHED: missing
./scripts/config --enable CONFIG_IP_NF_TARGET_REDIRECT
./scripts/config --module CONFIG_IP_SET
./scripts/config --module CONFIG_IP_VS
./scripts/config --enable CONFIG_IP_VS_NFCT
./scripts/config --enable CONFIG_IP_VS_PROTO_TCP
./scripts/config --enable CONFIG_IP_VS_PROTO_UDP
./scripts/config --module CONFIG_IP_VS_RR
./scripts/config --module CONFIG_VXLAN
./scripts/config --module CONFIG_INET_ESP
#    - CONFIG_INET_XFRM_MODE_TRANSPORT: missing

# ===========================================
# conntrack for iptables, k3s and microvms
#
./scripts/config --enable CONFIG_NETFILTER_XTABLES
./scripts/config --enable CONFIG_NETFILTER

# log target support
./scripts/config --module NETFILTER_XT_TARGET_LOG
# IP tables support (required for filtering/masq/NAT)
./scripts/config --module IP_NF_IPTABLES

# some conntrack dependencies (ovs, )
./scripts/config --module CONFIG_OPENVSWITCH


## conntrack enabled
./scripts/config --enable CONFIG_NF_CONNTRACK_MARK
./scripts/config --enable CONFIG_NF_CONNTRACK_SECMARK
./scripts/config --enable CONFIG_NF_CONNTRACK_ZONES
./scripts/config --enable CONFIG_NF_CONNTRACK_PROCFS
./scripts/config --enable CONFIG_NF_CONNTRACK_EVENTS
./scripts/config --enable CONFIG_NF_CONNTRACK_TIMEOUT
./scripts/config --enable CONFIG_NF_CONNTRACK_TIMESTAMP
./scripts/config --enable CONFIG_NF_CONNTRACK_LABELS
./scripts/config --enable CONFIG_NF_CONNTRACK_OVS


## conntrack modules
./scripts/config --module CONFIG_NF_CONNTRACK
./scripts/config --module CONFIG_NF_CONNTRACK_AMANDA
./scripts/config --module CONFIG_NF_CONNTRACK_FTP
./scripts/config --module CONFIG_NF_CONNTRACK_H323
./scripts/config --module CONFIG_NF_CONNTRACK_IRC
./scripts/config --module CONFIG_NF_CONNTRACK_BROADCAST
./scripts/config --module CONFIG_NF_CONNTRACK_NETBIOS_NS
./scripts/config --module CONFIG_NF_CONNTRACK_SNMP
./scripts/config --module CONFIG_NF_CONNTRACK_PPTP
./scripts/config --module CONFIG_NF_CONNTRACK_SANE
./scripts/config --module CONFIG_NF_CONNTRACK_SIP
./scripts/config --module CONFIG_NF_CONNTRACK_TFTP
./scripts/config --module CONFIG_NF_CONNTRACK_BRIDGE


# code coverage for fuzzing

## Defaults the config
# make olddefconfig
# echo "olddefconfig done"

# Final make commands
#make KCFLAGS="-std=gnu89" bzImage
# make KCFLAGS="-std=gnu99" bzImage
# make CC="gcc -std=gnu89" KBUILD_CFLAGS="-std=gnu89" KBUILD_CFLAGS_REALMODE="-std=gnu89" bzImage
#export CC="gcc -std=gnu89"
#make bzImage

# make \
#   CC="gcc -std=gnu89" \
#   REALMODE_CFLAGS="-m16 -std=gnu89" \
#   bzImage
# make CC="gcc -std=gnu89 -fcf-protection=none" bzImage

# Do not invoke a prompt, and align
# the .config file with Kconfig enforcement
yes "" | make olddefconfig

if grep CONFIG_BRIDGE_NETFILTER ./.config; then

make CC="gcc -std=gnu99 -fcf-protection=none" -j"$(nproc)" bzImage modules

mkdir -p /mnt/lfs/
make INSTALL_MOD_PATH=/mnt/lfs modules_install

printf "\n|> bzImage and modules done!! \n\n"

else
    printf "\n|> Error: .config was overwritten and CONFIG_BRIDGE_NETFILTER is nowhere to be found. Exiting now, fix the code...\n\n"
fi

cd - || return

EOF

WORKDIR /app

RUN <<EOF

if [ $PWD = "/app" ]; then
tar -czf ./ko_tarball.tar.gz /mnt/lfs/
else

printf "WRONG PATH!"
fi

EOF

FROM alpine:3.18 as relay
ARG KERNEL_VERSION=6.6.22
WORKDIR /app/
COPY --from=download-boot /app/utils/kernel/linux-${KERNEL_VERSION}/arch/x86/boot/bzImage /app/artifacts/
COPY --from=download-boot /app/ko_tarball.tar.gz /app/artifacts/
