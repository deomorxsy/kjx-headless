#!/bin/sh

# old filename: ./scripts/qemu-k3s-startup.sh

# virtio virtfs interface for
# file sharing between guest and host
VIRTIO_PASSTHRU_DIR="/mnt/virtio-test"
export VIRTIO_PASSTHRU_DIR
# mkdir -p "${VIRTIO_PASSTHRU_DIR}"
# mount -t 9p -o trans=virtio hostshare "${VIRTIO_PASSTHRU_DIR}"
# module diagnostics file
MDPB_DIAG_FILE="/modprobe-diagnostics.txt"

load_modules() {

    if ! (
        (modprobe bridge 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo "|> Error: could not load module [bridge]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [bridge]. Proceeding..."
    echo && echo

    if ! (
        (modprobe br_netfilter 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo "|> Error: could not load module [br_netfilter]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [br_netfilter]. Proceeding..."
    echo && echo

    if ! (
        (modprobe veth 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo "|> Error: could not load module [veth]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [veth]. Proceeding..."
    echo && echo

    if ! (
        (modprobe tun 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo "|> Error: could not load module [tun]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [tun]. Proceeding..."
    echo && echo

    if ! (
        (modprobe overlay 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo "|> Error: could not load module [overlay]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [overlay]. Proceeding..."
    echo && echo

    if ! (
        (modprobe iptable_nat 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo "|> Error: could not load module [iptable_nat]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [iptable_nat]. Proceeding..."
    echo && echo

    if ! (
        (modprobe iptable_security 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo "|> Error: could not load module [iptable_security]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [iptable_security]. Proceeding..."
    echo && echo

    if ! (
        (modprobe ip6table_security 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo "|> Error: could not load module [ip6table_security]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [ip6table_security]. Proceeding..."
    echo && echo

    if ! (
        (modprobe xt_nat 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo "|> Error: could not load module [xt_nat]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [xt_nat]. Proceeding..."
    echo && echo

    if ! (
        (modprobe xt_MASQUERADE 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo "|> Error: could not load module [xt_MASQUERADE]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [xt_MASQUERADE]. Proceeding..."
    echo && echo

    if ! (
        (modprobe xt_addrtype 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo "|> Error: could not load module [xt_addrtype]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [xt_addrtype]. Proceeding..."
    echo && echo

    if ! (
        (modprobe xt_multiport 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo "|> Error: could not load module [xt_multiport]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [xt_multiport]. Proceeding..."
    echo && echo

    if ! (
        (modprobe xt_mark 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo "|> Error: could not load module [xt_mark]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [xt_mark]. Proceeding..."
    echo && echo

    if ! (
        (modprobe xt_ipvs 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo "|> Error: could not load module [xt_ipvs]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [xt_ipvs]. Proceeding..."
    echo && echo

    if ! (
        (modprobe xt_comment 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo "|> Error: could not load module [xt_comment]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [xt_comment]. Proceeding..."
    echo && echo

    if ! (
        (modprobe xt_cgroup 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo "|> Error: could not load module [xt_cgroup]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [xt_cgroup]. Proceeding..."
    echo && echo

    if ! (
        (modprobe xt_bpf 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo "|> Error: could not load module [xt_bpf]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [xt_bpf]. Proceeding..."
    echo && echo

    if ! (
        (modprobe xt_SECMARK 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo "|> Error: could not load module [xt_SECMARK]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [xt_SECMARK]. Proceeding..."
    echo && echo

    if ! (
        (modprobe xt_REDIRECT 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo "|> Error: could not load module [xt_REDIRECT]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [xt_REDIRECT]. Proceeding..."
    echo && echo

    if ! (
        (modprobe xt_LOG 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo "|> Error: could not load module [xt_LOG]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [xt_LOG]. Proceeding..."
    echo && echo

    if ! (
        (modprobe xt_CONNSECMARK 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo "|> Error: could not load module [xt_CONNSECMARK]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [xt_CONNSECMARK]. Proceeding..."
    echo && echo

    if ! (
        (modprobe nf_log_syslog 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo "|> Error: could not load module [nf_log_syslog]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [nf_log_syslog]. Proceeding..."
    echo && echo

    if ! (
        (modprobe ip_set 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo "|> Error: could not load module [ip_set]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [ip_set]. Proceeding..."
    echo && echo

    if ! (
        (modprobe ip_vs 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo "|> Error: could not load module [ip_vs]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [ip_vs]. Proceeding..."
    echo && echo

    if ! (
        (modprobe ip_vs_rr 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo "|> Error: could not load module [ip_vs_rr]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [ip_vs_rr]. Proceeding..."
    echo && echo

    if ! (
        (modprobe cls_bpf 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo "|> Error: could not load module [cls_bpf]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [cls_bpf]. Proceeding..."
    echo && echo

    if ! (
        (modprobe cls_cgroup 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo "|> Error: could not load module [cls_cgroup]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [cls_cgroup]. Proceeding..."
    echo && echo

    if ! (
        (modprobe act_bpf 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo "|> Error: could not load module [act_bpf]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [act_bpf]. Proceeding..."
    echo && echo

    if ! (
        (modprobe vxlan 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo "|> Error: could not load module [vxlan]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [vxlan]. Proceeding..."
    echo && echo

    if ! (
        (modprobe udp_tunnel 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo "|> Error: could not load module [udp_tunnel]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [udp_tunnel]. Proceeding..."
    echo && echo

    if ! (
        (modprobe ip6_udp_tunnel 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo "|> Error: could not load module [ip6_udp_tunnel]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [ip6_udp_tunnel]. Proceeding..."
    echo && echo

    if ! (
        (modprobe esp4 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo "|> Error: could not load module [esp4]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [esp4]. Proceeding..."
    echo && echo

    if ! (
        (modprobe macsec 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo "|> Error: could not load module [macsec]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [macsec]. Proceeding..."
    echo && echo

    if ! (
        (modprobe stp 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo "|> Error: could not load module [stp]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [stp]. Proceeding..."
    echo && echo

    if ! (
        (modprobe p8022 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo "|> Error: could not load module [p8022]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [p8022]. Proceeding..."
    echo && echo

    if ! (
        (modprobe psnap 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo "|> Error: could not load module [psnap]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [psnap]. Proceeding..."
    echo && echo

    if ! (
        (modprobe llc 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo "|> Error: could not load module [llc]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [llc]. Proceeding..."
    echo && echo

    if ! (
        (modprobe ebtables 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo "|> Error: could not load module [ebtables]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [ebtables]. Proceeding..."
    echo && echo

    if ! (
        (modprobe rpcsec_gss_krb5 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo "|> Error: could not load module [rpcsec_gss_krb5]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [rpcsec_gss_krb5]. Proceeding..."
    echo && echo

    if ! (
        (modprobe auth_rpcgss 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo "|> Error: could not load module [auth_rpcgss]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [auth_rpcgss]. Proceeding..."
    echo && echo

    if ! (
        (modprobe intel_vsec 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo "|> Error: could not load module [intel_vsec]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [intel_vsec]. Proceeding..."
    echo && echo

    if ! (
        (modprobe x86_pkg_temp_thermal 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo "|> Error: could not load module [x86_pkg_temp_thermal]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [x86_pkg_temp_thermal]. Proceeding..."
    echo && echo

    if ! (
        (modprobe efivarfs 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo "|> Error: could not load module [efivarfs]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [efivarfs]. Proceeding..."
    echo && echo

    ### modprobe bridge
    ### modprobe br_netfilter
    ### modprobe veth
    ### modprobe tun
    ### modprobe overlay
    ### modprobe iptable_nat
    ### modprobe iptable_security
    ### modprobe ip6table_security
    ### modprobe xt_nat
    ### modprobe xt_MASQUERADE
    ### modprobe xt_addrtype
    ### modprobe xt_multiport
    ### modprobe xt_mark
    ### modprobe xt_ipvs
    ### modprobe xt_comment
    ### modprobe xt_cgroup
    ### modprobe xt_bpf
    ### modprobe xt_SECMARK
    ### modprobe xt_REDIRECT
    ### modprobe xt_LOG
    ### modprobe xt_CONNSECMARK
    ### modprobe nf_log_syslog
    ### modprobe ip_set
    ### modprobe ip_vs
    ### modprobe ip_vs_rr
    ### modprobe cls_bpf
    ### modprobe cls_cgroup
    ### modprobe act_bpf
    ### modprobe vxlan
    ### modprobe udp_tunnel
    ### modprobe ip6_udp_tunnel
    ### modprobe esp4
    ### modprobe macsec
    ### modprobe stp
    ### modprobe p8022
    ### modprobe psnap
    ### modprobe llc
    ### modprobe ebtables
    ### modprobe rpcsec_gss_krb5
    ### modprobe auth_rpcgss
    ### modprobe intel_vsec
    ### # Error: x86_pkg_temp_thermal not loading
    ### #modprobe x86_pkg_temp_thermal
    ### modprobe efivarfs

}

unpack_microvms() {
    if ! [ -f "${VIRTIO_PASSTHRU_DIR:-[EMPTY_VARIABLE]}/gvisor-core.tar.gz" ]; then
        echo "|> Error: it was not possible to find the gvisor tarball. Exiting now..."
        return 1
    fi
    tar -C "${VIRTIO_PASSTHRU_DIR:-[EMPTY_VARIABLE]}" -xvf ./gvisor-core.tar.gz

}

bpftrace_function() {
    GETK3S_PID=$(pgrep k3s)
    (
        cat <<EOF
#!/bin/sh

bpftrace -e 'profile:hz:49 /pid == ${GETK3S_PID}/ { @[ustack] = count(); }' \
    > /app/trace.data &

echo \$! > /app/bpftrace.pid


EOF
    ) | tee /app/getk3s_pid_tracer.sh

    chmod +x /app/getk3s_pid_tracer.sh
    /app/getk3s_pid_tracer.sh

    BPFTRACE_PID=$(cat /app/bpftrace.pid)
    printf "\n|> bpftrace PID is: %s\n" "$BPFTRACE_PID"
}

unsquash_squashfs_sdb() {

    MOUNT_SQUASHFS_DIR="/mnt/airgap-registry-image"
    UNSQUASHED_DIR="/mnt/k3s-squashfs"
    SQUASH_FS_FILE="${MOUNT_SQUASHFS_DIR:-[EMPTY_VARIABLE]}/k3s-tarball.squashfs"

    # create directories for the squashfs file and its decompression
    mkdir -p "${MOUNT_SQUASHFS_DIR:-[EMPTY_VARIABLE]}"
    mkdir -p "${UNSQUASHED_DIR:-[EMPTY_VARIABLE]}"

    if ! (mount /dev/sdb "${MOUNT_SQUASHFS_DIR:-[EMPTY_VARIABLE]}"); then
        echo "|> Error: could not mount /dev/sdb into the ${MOUNT_SQUASHFS_DIR:-[EMPTY_VARIABLE]} filepath. Exiting now..."
        echo && echo
        return 1
    fi
    echo "|> Successfully mount /dev/sdb into /mnt/airgap-registry-image filepath. Proceeding..."
    echo && echo

    #cd "${MOUNT_SQUASHFS_DIR:-[EMPTY_VARIABLE]}" || return

    ls -allhtr "${MOUNT_SQUASHFS_DIR:-[EMPTY_VARIABLE]}"

    if ! [ -f "${SQUASH_FS_FILE:-[EMPTY_VARIABLE]}" ]; then
        echo "|> Error: it was not possible to find the ${SQUASH_FS_FILE:-[EMPTY_VARIABLE]} at ${MOUNT_SQUASHFS_DIR:-[EMPTY_VARIABLE]}. Exiting now..."
        echo && echo
        return 1
    fi
    echo "|> Successfully found the ${SQUASH_FS_FILE:-[EMPTY_VARIABLE]} at ${MOUNT_SQUASHFS_DIR:-[EMPTY_VARIABLE]}. Proceeding..."

    # unsquash the squashfs with the airgap images inside
    if ! (unsquashfs -d "${UNSQUASHED_DIR:-[EMPTY_VARIABLE]}" "${SQUASH_FS_FILE:-[EMPTY_VARIABLE]}"); then
        echo "|> Error: could not unsquash the /mnt/airgap-registry-image/k3s-tarball.squashfs into the /mnt/k3s-squashfs directory."
        return 1
    fi
    echo "|> Successfully unsquashed the ${SQUASH_FS_FILE:-[EMPTY_VARIABLE]} into the ${UNSQUASHED_DIR:-[EMPTY_VARIABLE]} directory. Proceeding..."

    if ! [ -f "${UNSQUASHED_DIR:-[EMPTY_VARIABLE]/k3s-airgap-images-amd64.tar}" ]; then
        echo "|> It was not possible to find the k3s-airgap-images-amd64.tar unsquashed. Possible error on the previous step. Exiting now..."
        echo && echo
        return 1
    fi
    echo "|> Successfully found the k3s-airgap-images-amd64.tar unsquashed. Proceeding..."
    echo && echo

    #cd - || return

}

runtimeClass_job() {
    mkdir -p /app/piest.yaml
    (
        cat <<PIEST
apiVersion: v1
kind: Pod
metadata:
  name: pi
  namespace: kjx
spec:
  runtimeClassName: runc  # Change to crun or runsc in different tests
  containers:
  - name: pi
    image: busybox
    command: ["sh", "-c", "awk 'BEGIN { for(i=1;i<10000;i+=2) s+=4*((i%4==1)?1:-1)/i; print s }'"]
    resources:
      limits:
        memory: "32Mi"
        cpu: "100m"
  restartPolicy: Never

PIEST
    ) | tee ./app/piest.yaml
}

_main_scope() {

    mkdir -p "${VIRTIO_PASSTHRU_DIR}"
    if ! (mount -t 9p -o trans=virtio hostshare "${VIRTIO_PASSTHRU_DIR}"); then
        echo "|> Error: it was not possible to mount 9P using virtio as transport option. Exiting now..."
        echo && echo
        return 1
    fi
    echo "|> Successfully mounted 9P using virtio as transport option. Proceeding..."
    echo && echo

    # if user is on the root of repository, define containers.conf
    # using the ISO_DIR environment variables.
    #
    if ! (cat /proc/cpuinfo | grep QEMU); then
        echo "|> Error: not running inside QEMU, outside of POC scope. Exiting now..."
        echo && echo
        # ETC_CONTAINERS_CONF="${ISO_DIR:-[EMPTY_VARIABLE]}/rootfs/etc/containers/containers.conf"
        # ETC_CONTAINERS_STORAGE_CONF="${ISO_DIR:-[EMPTY_VARIABLE]}/rootfs/etc/containers/storage.conf"
        return 1
    fi
    ETC_CONTAINERS_CONF="/etc/containers/containers.conf"
    ETC_CONTAINERS_STORAGE_CONF="/etc/containers/storage.conf"

    # rootless containers
    # podman

    # Load modules and get diagnostic over any malfunction
    if ! load_modules; then
        echo "|> Error: could not run the [load_modules] function to get diagnostics while loading with modprobe. Exiting now..."
        echo && echo
        return 1
    fi
    echo "|> Successfully ran the [load_modules] function to get diagnostics while loading with modprobe. Proceeding..."

    lsmod

    # echo tun >>/etc/modules
    # echo <USER>:100000:65536 >/etc/subuid
    # echo <USER>:100000:65536 >/etc/subgid

    lsmod | grep overlay

    #cd /app/shared-deps/

    # Setup kmod early
    cp /app/kmod /bin/kmod

    # todo: remove hard-coded symlinks
    if ! (
        ln -s "/bin/kmod" "/bin/lsmod"
        ln -s "/bin/kmod" "/bin/rmmod"
        ln -s "/bin/kmod" "/bin/insmod"
        ln -s "/bin/kmod" "/bin/modinfo"
        ln -s "/bin/kmod" "/bin/modprobe"
        ln -s "/bin/kmod" "/bin/depmod"

        ln -s "/bin/lsmod" "/sbin/lsmod"
        ln -s "/bin/rmmod" "/sbin/rmmod"
        ln -s "/bin/insmod" "/sbin/insmod"
        ln -s "/bin/modinfo" "/sbin/modinfo"
        ln -s "/bin/modprobe" "/sbin/modprobe"
        ln -s "/bin/depmod" "/sbin/depmod"
    ); then
        echo "|> Error: could not create symlinks from [/bin/kmod] to [/bin/kmod-based] and from each [/bin/kmod-based] command to [/sbin]. Exiting now..."
        echo && echo
        return 1
    fi
    echo "|> Successfully created symlinks from kmod to [/bin/kmod-based] and from each [/bin/kmod-based] command to [/sbin]. Proceeding..."
    echo && echo

    # Prepare run directory for containerd and k3s
    mkdir -p /run /var/run
    if ! (mount -t tmpfs tmpfs /run); then
        echo "|> Error: could not mount type tmpfs at [/run]. Exiting now..."
        echo && echo
        return 1
    fi
    echo "|> Sucessfully mounted type tmpfs at [/run]. Proceeding..."
    echo && echo

    if ! (ln -s /run /var/ 2>/dev/null); then
        echo "|> could not create symlink (soft link) of [/run] at [/var]. Exiting now..."
        echo && echo
        return 1
    fi
    echo "|> Sucessfully created symlink (soft link) of [/run] at [/var]. Proceeding..."
    echo && echo

    # creaate k3s directories
    if ! (
        mkdir -p /run/k3s/containerd
        mkdir -p /var/lib/rancher/k3s
        mkdir -p /etc/rancher/k3s
    ); then
        echo "|> Error: could not create k3s directories. Exiting now..."
        echo && echo
        return 1
    fi
    echo "|> Sucessfully created k3s directories. Proceding..."
    echo && echo

    # Generate a sample crictl.yaml, any path will suffice.
    # originally located on the server at: /var/lib/rancher/k3s/server/etc/crictl.yaml
    # originally located on the server at: /var/lib/rancher/k3s/agent/etc/crictl.yaml
    if ! (
        (
            cat <<EOF
runtime-endpoint: unix:///run/k3s/containerd/containerd.sock
EOF
        ) | tee /app/crictl.yaml
    ); then
        echo "|> Error: could not generate a simple crictl.yaml at [/app/crictl.yaml]. Exiting now..."
        echo && echo
        return 1
    fi
    echo "|> Sucessfully generated a simple crictl.yaml at [/app/crictl.yaml]. Proceding..."

    # ===============================================
    #
    # runtimeClass setup for k3s
    if ! (
        (
            cat <<EOF
# Paths to look for a valid OCI runtime (crun, runc, kata, runsc, krun, etc)
[engine.runtimes]
crun = [
  "/usr/bin/crun",
  "/usr/sbin/crun",
  "/usr/local/bin/crun",
  "/usr/local/sbin/crun",
  "/sbin/crun",
  "/bin/crun",
  "/run/current-system/sw/bin/crun",
]

# crun-vm is an OCI Runtime that enables Podman,
# Docker, and Kubernetes to run QEMU-compatible
# Virtual Machine (VM) images.
crun-vm = [
  "/usr/bin/crun-vm",
  "/usr/local/bin/crun-vm",
  "/usr/local/sbin/crun-vm",
  "/sbin/crun-vm",
  "/bin/crun-vm",
  "/run/current-system/sw/bin/crun-vm",
]

kata = [
  "/usr/bin/kata-runtime",
  "/usr/sbin/kata-runtime",
  "/usr/local/bin/kata-runtime",
  "/usr/local/sbin/kata-runtime",
  "/sbin/kata-runtime",
  "/bin/kata-runtime",
  "/usr/bin/kata-qemu",
  "/usr/bin/kata-fc",
]

runc = [
  "/usr/bin/runc",
  "/usr/sbin/runc",
  "/usr/local/bin/runc",
  "/usr/local/sbin/runc",
  "/sbin/runc",
  "/bin/runc",
  "/usr/lib/cri-o-runc/sbin/runc",
]

runsc = [
  "/usr/bin/runsc",
  "/usr/sbin/runsc",
  "/usr/local/bin/runsc",
  "/usr/local/sbin/runsc",
  "/bin/runsc",
  "/sbin/runsc",
  "/run/current-system/sw/bin/runsc",
]

youki = [
  "/usr/local/bin/youki",
  "/usr/bin/youki",
  "/bin/youki",
  "/run/current-system/sw/bin/youki",
]

krun = [
  "/usr/bin/krun",
  "/usr/local/bin/krun",
]

EOF
        ) | tee "${ETC_CONTAINERS_CONF:-[EMPTY_VARIABLE]}"
    ); then
        echo "|> Error: could not create ${ETC_CONTAINERS_CONF:-[EMPTY_VARIABLE]} . Exiting now..."
        echo && echo
        return 1
    fi
    echo "|> Sucessfully created ${ETC_CONTAINERS_CONF:-[EMPTY_VARIABLE]} . Proceeding..."
    echo && echo

    # Setup storage info for containers
    # this need user management enabled
    if ! (

        (
            cat <<EOF
[storage]
driver = "overlay"

# Default Storage Driver, Must be set for proper operation.
driver = "overlay"

# Temporary storage location
runroot = "/run/containers/storage"
graphroot = "/var/lib/containers/storage"

# Storage path for rootless users
rootless_storage_path = "$HOME/.local/share/containers/storage"

[storage.options]
pull_options = {enable_partial_images = "false", use_hard_links = "false", ostree_repos=""}
additionalimagestores = [
]

[storage.options.overlay]

# Path to an helper program to use for mounting the file system instead of mounting it
# directly.
mount_program = "/usr/bin/fuse-overlayfs"

# mountopt specifies comma separated list of extra mount options
mountopt = "nodev"


EOF

            # /etc/containers/storage.conf
        ) | tee "${ETC_CONTAINERS_STORAGE_CONF:-[EMPTY_VARIABLE]}"
    ); then
        echo "|> Error: could not create the ${ETC_CONTAINERS_STORAGE_CONF}"
        return 1
    fi

    # ======
    # Setup the crictl configuration file: crictl.yaml
    (
        cat <<EOF

runtime-endpoint: unix:///run/k3s/containerd/containerd.sock
image-endpoint: unix:///run/k3s/containerd/containerd.sock
timeout: 10
debug: false
EOF
    ) | tee /var/lib/rancher/k3s/data/cb3f5c92b6adfd5917414d1bb3622a60abec60b103aa6f4faddd48356682e9c3/bin/crictl.yaml
    # k3s crictl --config=/app/crictl.yaml ps --all

    # FUNCTION CALL
    unsquash_squashfs_sdb

    # Setup bpftrace
    # bpftrace dependencies, libclang from llvm17
    #cp /app/archive.tar.gz /app/shared-deps/
    cp /app/archive.tar.gz /app/shared-deps/

    cp "${VIRTIO_PASSTHRU_DIR:-[EMPTY_VARIABLE]}/archive.tar.gz" /app/shared-deps/
    cd /app/shared-deps/ || return
    tar -xvf ./archive.tar.gz
    cp -r ./lib/* /lib/
    cp -r ./usr/* /usr/

    # cleanup the current if it exists
    rm /usr/lib/libclang.so.17

    # Create a symlink
    ln -s /usr/lib/llvm17/lib/libclang.so.17.0.6 /usr/lib/libclang.so.17
    # =============
    cd - || return

    # Bring network up
    ip link set lo up

    # Create soft link for the container socket be found by k3s
    containerd &
    ln -s /run/containerd/containerd.sock /run/k3s/containerd/

    #k3s server --disable-agent --default-runtime=runc & > /dev/null 2>&1
    #k3s server --default-runtime=runc --disable=traefik & > /dev/null 2>&1

    (
        cat <<EOF
containerd:
  snapshotter: fuse-overlayfs
EOF
    ) | tee /etc/rancher/k3s/agent-config.yaml

    # /etc/rancher/k3s/registries.yaml

    # k3s server --default-runtime=runc --disable=traefik --config=/etc/rancher/k3s/agent-config.yaml & > /dev/null 2>&1
    # k3s server --disable-agent --default-runtime=runc --disable=traefik --snapshotter=fuse-overlayfs > /dev/null 2>&1 &
    # k3s server --disable-agent --default-runtime="crun" --disable=traefik --snapshotter=overlayfs > /dev/null 2>&1 &
    k3s server --disable-agent --default-runtime="crun" --disable=traefik --snapshotter=fuse-overlayfs >/dev/null 2>&1 &

    # FUNCTION CALL
    bpftrace_function

    # works now
    k3s ctr namespace list

    # create namespace and import the airgap tarball
    # k3s kubectl create namespace "k8s.io"
    # ================================================================
    # !!!!!!! IMPORTANT !!!!!!
    # these airgap images should be previously converted to oci
    # in order to push to the registry. umoci can help with that.
    # ================================================================

    # import the k3s airgap images with k3s ctr
    if ! (k3s ctr -n="k8s.io" images import /mnt/k3s-squashfs/k3s-airgap-images-amd64.tar); then
        echo "|> Error: could not import the k3s airgap images with k3s ctr. Exiting now..."
        echo && echo
        return 1
    fi
    echo "|> Successfully imported the k3s airgap images with k3s ctr. Proceeding..."
    echo && echo

    # Make sure to unmount the /dev/sdb that had the squashfs now
    # that it isn't needed anymore (previous test).
    if (mount | grep /dev/sdb); then
        echo "|> Found a /dev/sdb mounted. Attempting to unmount..."
        echo && echo
        if ! (umount /dev/sdb); then
            echo "|> Error: could not unmount /dev/sdb. Exiting now..."
            echo && echo
            return 1
        fi
    fi
    echo "|> Successfully unmounted /dev/sdb. Proceeding..."
    echo && echo

    # import the OCI registry:3.0 server image
    if ! (k3s ctr -n="k8s.io" images import /mnt/k3s-squashfs/skopeo-convert-registry.oci.tar); then
        echo && echo
        echo "|> Error: could not import the OCI registry:3.0 server image. Exiting now..."
        return 1
    fi
    echo "|> Successfully imported the OCI registry:3.0 server image. Proceeding..."
    echo && echo

    # get name of the image at the time of import
    # OR_IMG_NAME=$(k3s ctr -n="k8s.io" images import /mnt/k3s-squashfs/skopeo-convert-registry.oci.tar | grep "unpacking" | awk '{ print $2 }')
    if ! UNPACK_NAME=$(k3s ctr images list | grep import | awk '{print $1}'); then
        echo "|> Error: could not get the name of the image at the time of import (with the UNPACK_NAME variable). Exiting now..."
        echo && echo
        return 1
    fi
    echo "|> Successfully got the name of the image at the time of import (with the UNPACK_NAME variable). Exiting now..."

    # tag image with the default name for localhost registry deploys
    if ! (k3s ctr -n="k8s.io" images tag "$UNPACK_NAME" "localhost:5000/registry:3.0"); then
        echo "|> Error: could not tag image with the default name for localhost registry deploys. Exiting now..."
        echo && echo
        return 1
    fi

    # check the tagged image on the list
    if ! (k3s ctr images ls); then
        echo "|> Error: could not check the tagged image on the list. Exiting now..."
        echo && echo
        return 1
    fi
    echo "|> Successfully checked the tagged image on the list. Exiting now..."
    echo && echo

    # verify if image is imported
    # k3s ctr -n k8s.io images ls

    # if pgrep k3s; then
    #     kill -SIGTERM "$GET_BPFTRACE_PID"
    # fi
    # create the container with k3s ctr, which will be run by k3s containerd
    if ! (k3s ctr -n="k8s.io" run --rm -t \
        localhost:5000/registry:3.0 \
        registry-test \
        /entrypoint.sh); then
        echo "|> Error: could not create the container with k3s ctr, which would be run by k3s containerd. Exiting now..."
        echo && echo
        return 1
    fi
    echo "|> Successfully created the container with k3s ctr, which would be run by k3s containerd. Proceeding..."

    # define variable to check the metrics-server state
    # (beware sub-shell scopes)
    if ! CHECK_METRICS_SERVER="$(k3s kubectl get pods -n=kube-system | grep "metrics-server" | awk '{ print $1 }')"; then
        echo "|> Error: could not check metrics-server state. Exiting now..."
        echo && echo
        return 1
    fi

    # describe Pod of the metrics-server state
    if ! (k3s kubectl describe pod "${CHECK_METRICS_SERVER:-[EMPTY_VARIABLE]}" -n=kube-system); then
        echo "|> Error: could not describe Pod of the metrics-server state. Exiting now..."
        echo && echo
        return 1
    fi
    echo "|> Successfully described the Pod of the metrics-server state. Proceeding..."

    # (
    # cat <<EOF
    # apiVersion: v1
    # kind: Pod
    # metadata:
    #   name: local-registry
    # spec:
    #   containers:
    #   - name: registry
    #     image: registry:2
    #     ports:
    #     - containerPort: 5000
    #       hostPort: 5000
    # EOF
    # )

    # FUNCTION CALL
    runtimeClass_job

    # Gracefully exit bpftrace and return plot graph
    kill -SIGINT "$BPFTRACE_PID"

    # Kill k3s
    kill -SIGTERM $(pgrep k3s)

    # reboot: power down
    # stops recording the asciinema section
    poweroff -f

}
