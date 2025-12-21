#!/bin/sh

# old filename: ./scripts/qemu-k3s-startup.sh

# virtio virtfs interface for
# file sharing between guest and host
VIRTIO_PASSTHRU_DIR="/mnt/virtio-test"
export VIRTIO_PASSTHRU_DIR

# check if inside guest vm
if ! (cat /proc/cpuinfo | grep QEMU >/dev/null 2>&1); then
    echo && echo "|> Error: not running inside QEMU, outside of POC scope. Exiting now..."
    echo "|> SCOPE: global, file: [./scripts/isogen/poc-bootscript.sh], check: 01"
    echo && echo
    # ETC_CONTAINERS_CONF="${ISO_DIR:-[EMPTY_VARIABLE]}/rootfs/etc/containers/containers.conf"
    # ETC_CONTAINERS_STORAGE_CONF="${ISO_DIR:-[EMPTY_VARIABLE]}/rootfs/etc/containers/storage.conf"
    return 1
fi
echo "|> Sucessfully running inside QEMU, inside of the POC scope. Proceeding..."
echo "|> SCOPE: global, file: [./scripts/isogen/poc-bootscript.sh], check: 01"
echo && echo
###
### mkdir -p "${VIRTIO_PASSTHRU_DIR}"
### mount -t 9p -o trans=virtio hostshare "${VIRTIO_PASSTHRU_DIR}"
###
mkdir -p "${VIRTIO_PASSTHRU_DIR}"
mkdir -p /app

if [ -f "${VIRTIO_PASSTHRU_DIR:-[EMPTY_VARIABLE]}/poc-bootscript.sh" ]; then

    if ! (cp "${VIRTIO_PASSTHRU_DIR:-[EMPTY_VARIABLE]}/poc-bootscript.sh" /app); then
        echo "|> Error: could not copy the bootscript"
        echo "|> SCOPE: global, file: [./scripts/isogen/poc-bootscript.sh], check: 02"
        return 1
    fi
    echo "|> Sucessfully copied the bootscript"
    echo
fi

if (mount | grep hostshare); then
    if ! umount "${VIRTIO_PASSTHRU_DIR:-[EMPTY_VARIABLE]}"; then
        echo "|> Error: could not unmount the hostshare 9P virtio for the virtfs option of QEMU. Exiting now..."
        return 1
    fi
    echo "|> Sucessfully unmounted the hostshare 9P virtio for the virtfs option of QEMU. Proceeding..."
fi

if ! (mount -t 9p -o trans=virtio hostshare "${VIRTIO_PASSTHRU_DIR}"); then
    echo && echo "|> Error: it was not possible to mount 9P using virtio as transport option. Exiting now..."
    echo "|> SCOPE: global, file: [./scripts/isogen/poc-bootscript.sh], check: 02"
    echo && echo
    return 1
fi
echo "|> Successfully mounted 9P using virtio as transport option. Proceeding..."
echo "|> SCOPE: global, file: [./scripts/isogen/poc-bootscript.sh], check: 02"
echo && echo

#MODE="-main" . /app/poc-bootscript.sh

### first_setup() {
###
###     mkdir -p "${VIRTIO_PASSTHRU_DIR}"
###     # attempt to mount the hostpath 9P with virtio as transport option.
###     if ! mount -t 9p -o trans=virtio hostshare "${VIRTIO_PASSTHRU_DIR}"; then
###         echo && echo "|> Error: it was not possible to mount 9P using virtio as transport option. Exiting now..."
###         echo "|> SCOPE: global, file: [./scripts/isogen/poc-bootscript.sh], check: 02"
###         echo && echo
###         return 1
###     fi
###     echo "|> Successfully mounted 9P using virtio as transport option. Proceeding..."
###     echo "|> SCOPE: global, file: [./scripts/isogen/poc-bootscript.sh], check: 02"
###     echo && echo
###
###     mkdir -p /app
###     if ! (cp "${VIRTIO_PASSTHRU_DIR:-[EMPTY_VARIABLE]}/poc-bootscript.sh" /app/); then
###         echo "|> Error: could not copy the [${VIRTIO_PASSTHRU_DIR:-[EMPTY_VARIABLE]}/poc-bootscript.sh] to /app. Exiting now..."
###         return 1
###     fi
###     echo "|> Sucessfully copied the poc-bootscript to /app. Exiting now..."
###     echo && echo
### }

# mkdir -p "${VIRTIO_PASSTHRU_DIR}"
# mount -t 9p -o trans=virtio hostshare "${VIRTIO_PASSTHRU_DIR}"
# module diagnostics file
MDPB_DIAG_FILE="/modprobe-diagnostics.txt"

# setup k3s crictl configuration file
K3S_CRICTL_CONF_FILE="/var/lib/rancher/k3s/data/cb3f5c92b6adfd5917414d1bb3622a60abec60b103aa6f4faddd48356682e9c3/bin/crictl.yaml"
export K3S_CRICTL_CONF_FILE

K3S_AGENT_CONF_FILE="/etc/rancher/k3s/agent-config.yaml"
export K3S_AGENT_CONF_FILE

load_modules() {

    if ! (
        (modprobe bridge 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo && echo "|> Error: could not load module [bridge]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [bridge]. Proceeding..."

    if ! (
        (modprobe br_netfilter 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo && echo "|> Error: could not load module [br_netfilter]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [br_netfilter]. Proceeding..."

    if ! (
        (modprobe veth 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo && echo "|> Error: could not load module [veth]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [veth]. Proceeding..."

    if ! (
        (modprobe tun 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo && echo "|> Error: could not load module [tun]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [tun]. Proceeding..."

    if ! (
        (modprobe overlay 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo && echo "|> Error: could not load module [overlay]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [overlay]. Proceeding..."

    if ! (
        (modprobe iptable_nat 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo && echo "|> Error: could not load module [iptable_nat]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [iptable_nat]. Proceeding..."

    if ! (
        (modprobe iptable_security 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo && echo "|> Error: could not load module [iptable_security]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [iptable_security]. Proceeding..."

    if ! (
        (modprobe ip6table_security 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo && echo "|> Error: could not load module [ip6table_security]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [ip6table_security]. Proceeding..."

    if ! (
        (modprobe xt_nat 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo && echo "|> Error: could not load module [xt_nat]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [xt_nat]. Proceeding..."

    if ! (
        (modprobe xt_MASQUERADE 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo && echo "|> Error: could not load module [xt_MASQUERADE]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [xt_MASQUERADE]. Proceeding..."

    if ! (
        (modprobe xt_addrtype 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo && echo "|> Error: could not load module [xt_addrtype]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [xt_addrtype]. Proceeding..."

    if ! (
        (modprobe xt_multiport 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo && echo "|> Error: could not load module [xt_multiport]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [xt_multiport]. Proceeding..."

    if ! (
        (modprobe xt_mark 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo && echo "|> Error: could not load module [xt_mark]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [xt_mark]. Proceeding..."

    if ! (
        (modprobe xt_ipvs 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo && echo "|> Error: could not load module [xt_ipvs]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [xt_ipvs]. Proceeding..."

    if ! (
        (modprobe xt_comment 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo && echo "|> Error: could not load module [xt_comment]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [xt_comment]. Proceeding..."

    if ! (
        (modprobe xt_cgroup 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo && echo "|> Error: could not load module [xt_cgroup]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [xt_cgroup]. Proceeding..."

    if ! (
        (modprobe xt_bpf 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo && echo "|> Error: could not load module [xt_bpf]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [xt_bpf]. Proceeding..."

    if ! (
        (modprobe xt_SECMARK 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo && echo "|> Error: could not load module [xt_SECMARK]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [xt_SECMARK]. Proceeding..."

    if ! (
        (modprobe xt_REDIRECT 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo && echo "|> Error: could not load module [xt_REDIRECT]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [xt_REDIRECT]. Proceeding..."

    if ! (
        (modprobe xt_LOG 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo && echo "|> Error: could not load module [xt_LOG]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [xt_LOG]. Proceeding..."

    if ! (
        (modprobe xt_CONNSECMARK 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo && echo "|> Error: could not load module [xt_CONNSECMARK]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [xt_CONNSECMARK]. Proceeding..."

    if ! (
        (modprobe nf_log_syslog 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo && echo "|> Error: could not load module [nf_log_syslog]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [nf_log_syslog]. Proceeding..."

    if ! (
        (modprobe ip_set 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo && echo "|> Error: could not load module [ip_set]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [ip_set]. Proceeding..."

    if ! (
        (modprobe ip_vs 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo && echo "|> Error: could not load module [ip_vs]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [ip_vs]. Proceeding..."

    if ! (
        (modprobe ip_vs_rr 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo && echo "|> Error: could not load module [ip_vs_rr]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [ip_vs_rr]. Proceeding..."

    if ! (
        (modprobe cls_bpf 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo && echo "|> Error: could not load module [cls_bpf]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [cls_bpf]. Proceeding..."

    if ! (
        (modprobe cls_cgroup 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo && echo "|> Error: could not load module [cls_cgroup]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [cls_cgroup]. Proceeding..."

    if ! (
        (modprobe act_bpf 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo && echo "|> Error: could not load module [act_bpf]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [act_bpf]. Proceeding..."

    if ! (
        (modprobe vxlan 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo && echo "|> Error: could not load module [vxlan]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [vxlan]. Proceeding..."

    if ! (
        (modprobe udp_tunnel 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo && echo "|> Error: could not load module [udp_tunnel]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [udp_tunnel]. Proceeding..."

    if ! (
        (modprobe ip6_udp_tunnel 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo && echo "|> Error: could not load module [ip6_udp_tunnel]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [ip6_udp_tunnel]. Proceeding..."

    if ! (
        (modprobe esp4 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo && echo "|> Error: could not load module [esp4]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [esp4]. Proceeding..."

    if ! (
        (modprobe macsec 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo && echo "|> Error: could not load module [macsec]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [macsec]. Proceeding..."

    if ! (
        (modprobe stp 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo && echo "|> Error: could not load module [stp]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [stp]. Proceeding..."

    if ! (
        (modprobe p8022 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo && echo "|> Error: could not load module [p8022]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [p8022]. Proceeding..."

    if ! (
        (modprobe psnap 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo && echo "|> Error: could not load module [psnap]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [psnap]. Proceeding..."

    if ! (
        (modprobe llc 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo && echo "|> Error: could not load module [llc]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [llc]. Proceeding..."

    if ! (
        (modprobe ebtables 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo && echo "|> Error: could not load module [ebtables]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [ebtables]. Proceeding..."

    if ! (
        (modprobe rpcsec_gss_krb5 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo && echo "|> Error: could not load module [rpcsec_gss_krb5]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [rpcsec_gss_krb5]. Proceeding..."

    if ! (
        (modprobe auth_rpcgss 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo && echo "|> Error: could not load module [auth_rpcgss]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [auth_rpcgss]. Proceeding..."

    if ! (
        (modprobe intel_vsec 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo && echo "|> Error: could not load module [intel_vsec]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [intel_vsec]. Proceeding..."

    if ! (
        (modprobe x86_pkg_temp_thermal 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo && echo "|> Error: could not load module [x86_pkg_temp_thermal]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [x86_pkg_temp_thermal]. Proceeding..."

    if ! (
        (modprobe efivarfs 2>&1) >>"${MDPB_DIAG_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo && echo "|> Error: could not load module [efivarfs]. Exiting now..."
        echo && echo
        return
    fi
    echo "|> Sucessfully loaded the module [efivarfs]. Proceeding..."

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

kmod_lkm_setup() {
    # Load modules and get diagnostic over any malfunction
    if ! load_modules; then
        echo && echo "|> Error: could not run the [load_modules] function to get diagnostics while loading with modprobe. Exiting now..."
        echo "|> SCOPE: kmod_lkm_setup, file: [./scripts/isogen/poc-bootscript.sh], check: 01"
        echo && echo
        return 1
    fi
    echo "|> Successfully ran the [load_modules] function to get diagnostics while loading with modprobe. Proceeding..."
    echo "|> SCOPE: kmod_lkm_setup, file: [./scripts/isogen/poc-bootscript.sh], check: 01"
    echo && echo

    # echo tun >>/etc/modules
    # echo <USER>:100000:65536 >/etc/subuid
    # echo <USER>:100000:65536 >/etc/subgid

    lsmod
    lsmod | grep overlay

    #cd /app/shared-deps/

    # Setup kmod early
    cp /app/kmod /bin/kmod

    # todo: remove hard-coded symlinks
    if ! (

        if ! [ -f "/bin/lsmod" ]; then
            echo "|> WARNING: [/bin/lsmod] was not found on this filepath. Attempting to create..."
            if ! (ln -s "/bin/kmod" "/bin/lsmod"); then
                echo "|> Error: could not create symlink (soft link) of [/bin/kmod] at [/bin/lsmod], which is part of the kmod tooling. Exiting now..."
                echo "|> SCOPE: kmod_lkm_setup, file: [./scripts/isogen/poc-bootscript.sh], check: 02"
            fi
            echo "|> Sucessfully created symlink (soft link) of [/bin/kmod] at [/bin/lsmod], which is part of the kmod tooling. Proceeding..."
        fi

        if ! [ -f "/bin/rmmod" ]; then
            echo "|> WARNING: [/bin/rmmod] was not found on this filepath. Attempting to create..."
            if ! (ln -s "/bin/kmod" "/bin/rmmod"); then
                echo "|> Error: could not create symlink (soft link) of [/bin/kmod] at [/bin/rmmod], which is part of the kmod tooling. Exiting now..."
                echo "|> SCOPE: kmod_lkm_setup, file: [./scripts/isogen/poc-bootscript.sh], check: 02"
            fi
            echo "|> Sucessfully created symlink (soft link) of [/bin/kmod] at [/bin/rmmod], which is part of the kmod tooling. Proceeding..."
        fi

        if ! [ -f "/bin/insmod" ]; then
            echo "|> WARNING: [/bin/insmod] was not found on this filepath. Attempting to create..."
            if ! (ln -s "/bin/kmod" "/bin/insmod"); then
                echo "|> Error: could not create symlink (soft link) of [/bin/kmod] at [/bin/insmod], which is part of the kmod tooling. Exiting now..."
                echo "|> SCOPE: kmod_lkm_setup, file: [./scripts/isogen/poc-bootscript.sh], check: 02"
            fi
            echo "|> Sucessfully created symlink (soft link) of [/bin/kmod] at [/bin/insmod], which is part of the kmod tooling. Proceeding..."
        fi

        if ! [ -f "/bin/modinfo" ]; then
            echo "|> WARNING: [/bin/modinfo] was not found on this filepath. Attempting to create..."
            if ! (ln -s "/bin/kmod" "/bin/modinfo"); then
                echo "|> Error: could not create symlink (soft link) of [/bin/kmod] at [/bin/modinfo], which is part of the kmod tooling. Exiting now..."
                echo "|> SCOPE: kmod_lkm_setup, file: [./scripts/isogen/poc-bootscript.sh], check: 02"
            fi
            echo "|> Error: Sucessfully created(soft link) of [/bin/kmod] at [/bin/modinfo], which is part of the kmod tooling. Proceeding..."
        fi

        if ! [ -f "/bin/modprobe" ]; then
            echo "|> WARNING: [/bin/modprobe] was not found on this filepath. Attempting to create..."
            if ! (ln -s "/bin/kmod" "/bin/modprobe"); then
                echo "|> Error: could not create symlink (soft link) of [/bin/kmod] at [/bin/modprobe], which is part of the kmod tooling. Exiting now..."
                echo "|> SCOPE: kmod_lkm_setup, file: [./scripts/isogen/poc-bootscript.sh], check: 02"
            fi
            echo "|> Error: Sucessfully created(soft link) of [/bin/kmod] at [/bin/modprobe], which is part of the kmod tooling. Proceeding..."
        fi

        if ! [ -f "/bin/depmod" ]; then
            echo "|> WARNING: [/bin/depmod] was not found on this filepath. Attempting to create..."
            if ! (ln -s "/bin/kmod" "/bin/depmod"); then
                echo "|> Error: could not create symlink (soft link) of [/bin/kmod] at [/bin/depmod], which is part of the kmod tooling. Exiting now..."
                echo "|> SCOPE: kmod_lkm_setup, file: [./scripts/isogen/poc-bootscript.sh], check: 02"
            fi
            echo "|> Sucessfully created symlink (soft link) of [/bin/kmod] at [/bin/depmod], which is part of the kmod tooling. Proceeding..."
        fi

        if ! [ -f "/sbin/lsmod" ]; then
            echo "|> WARNING: [/sbin/lsmod] was not found on this filepath. Attempting to create..."
            if ! (ln -s "/bin/lsmod" "/sbin/lsmod"); then
                echo "|> Error: could not create symlink (soft link) of [/bin/lsmod] at [/sbin/lsmod], which is part of the kmod tooling. Exiting now..."
                echo "|> SCOPE: kmod_lkm_setup, file: [./scripts/isogen/poc-bootscript.sh], check: 02"
            fi
            echo "|> Error: Sucessfully created(soft link) of [/bin/lsmod] at [/sbin/lsmod], which is part of the kmod tooling. Proceeding..."
        fi

        if ! [ -f "/sbin/rmmod" ]; then
            echo "|> WARNING: [/sbin/rmmod] was not found on this filepath. Attempting to create..."
            if ! (ln -s "/bin/rmmod" "/sbin/rmmod"); then
                echo "|> Error: could not create symlink (soft link) of [/bin/rmmod] at [/sbin/rmmod], which is part of the kmod tooling. Exiting now..."
                echo "|> SCOPE: kmod_lkm_setup, file: [./scripts/isogen/poc-bootscript.sh], check: 02"
            fi
            echo "|> Error: Sucessfully created(soft link) of [/bin/rmmod] at [/sbin/rmmod], which is part of the kmod tooling. Proceeding..."
        fi

        if ! [ -f "/sbin/insmod" ]; then
            echo "|> WARNING: [/sbin/insmod] was not found on this filepath. Attempting to create..."
            if ! (ln -s "/bin/insmod" "/sbin/insmod"); then
                echo "|> Error: could not create symlink (soft link) of [/bin/insmod] at [/sbin/insmodt], which is  of the kmod tooling. Exiting now..."
                echo "|> SCOPE: kmod_lkm_setup, file: [./scripts/isogen/poc-bootscript.sh], check: 02"
            fi
            echo "|> Sucessfully created symlink (soft link) of [/bin/insmod] at [/sbin/insmodt], which is  of the kmod tooling. Proceeding..."
        fi

        if ! [ -f "/sbin/modinfo" ]; then
            echo "|> WARNING: [/sbin/modinfo] was not found on this filepath. Attempting to create..."
            if ! (ln -s "/bin/modinfo" "/sbin/modinfo"); then
                echo "|> Error: could not create symlink (soft link) of [/bin/modinfo] at [/sbin/modinfot], which is  of the kmod tooling. Exiting now..."
                echo "|> SCOPE: kmod_lkm_setup, file: [./scripts/isogen/poc-bootscript.sh], check: 02"
            fi
            echo "|> Error: Sucessfully created(soft link) of [/bin/modinfo] at [/sbin/modinfot], which is  of the kmod tooling. Proceeding..."
        fi

        if ! [ -f "/sbin/modprobe" ]; then
            echo "|> WARNING: [/sbin/modprobe] was not found on this filepath. Attempting to create..."
            if ! (ln -s "/bin/modprobe" "/sbin/modprobe"); then
                echo "|> Error: could not create symlink (soft link) of [/bin/modprobe] at [/sbin/modprobet], which is  of the kmod tooling. Exiting now..."
                echo "|> SCOPE: kmod_lkm_setup, file: [./scripts/isogen/poc-bootscript.sh], check: 02"
            fi
            echo "|> Error: Sucessfully created(soft link) of [/bin/modprobe] at [/sbin/modprobet], which is  of the kmod tooling. Proceeding..."
        fi

        if ! [ -f "/sbin/depmod" ]; then
            echo "|> WARNING: [/sbin/depmod] was not found on this filepath. Attempting to create..."
            if ! (ln -s "/bin/depmod" "/sbin/depmod"); then
                echo "|> Error: could not create symlink (soft link) of [/bin/depmod] at [/sbin/depmodt], which is  of the kmod tooling. Exiting now..."
                echo "|> SCOPE: kmod_lkm_setup, file: [./scripts/isogen/poc-bootscript.sh], check: 02"
            fi
            echo "|> Sucessfully created symlink (soft link) of [/bin/depmod] at [/sbin/depmodt], which is  of the kmod tooling. Proceeding..."
        fi

    ); then
        echo && echo "|> Error: could not create symlinks from [/bin/kmod] to [/bin/kmod-based] and from each [/bin/kmod-based] command to [/sbin]. Exiting now..."
        echo "|> SCOPE: kmod_lkm_setup, file: [./scripts/isogen/poc-bootscript.sh], check: 02"
        echo && echo
        return 1
    fi
    echo "|> Successfully created symlinks from kmod to [/bin/kmod-based] and from each [/bin/kmod-based] command to [/sbin]. Proceeding..."
    echo "|> SCOPE: kmod_lkm_setup, file: [./scripts/isogen/poc-bootscript.sh], check: 02"
    echo && echo

}

bpftrace_function() {
    GETK3S_PID=$(pgrep k3s)

    BPFTRACE_SCRIPT="/app/getk3s_pid_tracer.sh"

    mkdir -p /app

    if ! ( (
        cat <<EOF
#!/bin/sh

bpftrace -e 'profile:hz:49 /pid == ${GETK3S_PID:-[EMPTY_VARIABLE]}/ { @[ustack] = count(); }' \
    > /app/trace.data &

echo \$! > /app/bpftrace.pid


EOF
    ) | tee "${BPFTRACE_SCRIPT:-[EMPTY_VARIABLE]}"); then
        echo && echo "|> Error: could not create the ${BPFTRACE_SCRIPT:-[EMPTY_VARIABLE]} filepath. Exiting now..."
        echo "|> SCOPE: [bpftrace_function], file: [./scripts/isogen/poc-bootscript.sh], check 01"
        echo && echo
        return 1
    fi
    echo "|> Sucessfully created the ${BPFTRACE_SCRIPT:-[EMPTY_VARIABLE]} filepath. Proceeding..."
    echo "|> SCOPE: [bpftrace_function], file: [./scripts/isogen/poc-bootscript.sh], check 01"
    echo && echo

    if ! (chmod +x "${BPFTRACE_SCRIPT:-[EMPTY_VARIABLE]}"); then
        echo && echo "|> Error: it was not possible to change file bits to run of ${BPFTRACE_SCRIPT:-[EMPTY_VARIABLE]}. Exiting now..."
        echo "|> SCOPE: [bpftrace_function], file: [./scripts/isogen/poc-bootscript.sh], check 02"
        echo && echo
        return 1
    fi
    echo "|> was not possible to change file bits to run of ${BPFTRACE_SCRIPT:-[EMPTY_VARIABLE]}. Exiting now..."
    echo "|> SCOPE: [bpftrace_function], file: [./scripts/isogen/poc-bootscript.sh], check 02"
    echo && echo
    echo && echo

    # Execute the bpftrace script. If previous step passes, it will already be an executable.
    if ! (/bin/sh -c "${BPFTRACE_SCRIPT:-[EMPTY_VARIABLE]}"); then
        echo && echo "|> Error: it was not possible to run the bpftrace script. Exiting now..."
        echo "|> SCOPE: [bpftrace_function], file: [./scripts/isogen/poc-bootscript.sh], check 03"
        echo && echo
    fi
    echo "|> Sucessfully ran the bpftrace script. Proceeding..."
    echo "|> SCOPE: [bpftrace_function], file: [./scripts/isogen/poc-bootscript.sh], check 03"
    echo && echo

    if ! BPFTRACE_PID=$(cat /app/bpftrace.pid); then
        echo && echo "|> Error: could not find the /app/bpftrace.pid filepath. Exiting now..."
        echo "|> SCOPE: [bpftrace_function], file: [./scripts/isogen/poc-bootscript.sh], check 04"
        echo && echo
    fi
    echo "|> Sucessfully found the /app/bpftrace.pid filepath. Proceeding..."
    echo "|> SCOPE: [bpftrace_function], file: [./scripts/isogen/poc-bootscript.sh], check 04"
    echo && echo

    echo "|> HINT: the PID for the running BPFTRACE is: ${BPFTRACE_PID}. kill it to finish tracing with bpftrace."
    echo && echo

}

ftrace_function() {
    if ! (TARGET_PID="${FTRACE_PID:-[EMPTY_VARIABLE]}" \
        USR_TRACE_FUNCTION="function_graph" \
        USR_TRACE_FILTER="dsadas" \
        . "${VIRTIO_PASSTHRU_DIR:-[EMPTY_VARIABLE]}/trace/Ftrace/kerfuncs.sh"); then
        echo && echo "|> Error: could not run the kerfuncs scripts for Ftrace. Exiting now..."
        echo "|> SCOPE: [ftrace], file: [./scripts/isogen/poc-bootscript.sh], check 01"
        echo && echo
    fi
    echo "|> Sucessfully ran the kerfuncs scripts for Ftrace. Proceeding..."
    echo "|> SCOPE: [ftrace_function], file: [./scripts/isogen/poc-bootscript.sh], check 01"
    echo && echo

}

beetor_function() {
    if ! /app/beetor; then
        echo && echo "|> Error: could not run [/app/beetor]. Exiting now..."
        echo "|> SCOPE: [beetor_function], file: [./scripts/isogen/poc-bootscript.sh], check 01"
        echo && echo
    fi
    echo && echo "|> Error: could not run [/app/beetor]. Exiting now..."
    echo "|> SCOPE: [beetor_function], file: [./scripts/isogen/poc-bootscript.sh], check 01"
    echo && echo

}

tracer_type_caller() {

    if ! [ "${WHICH_TRACER_FUNCTION:-[EMPTY_VARIABLE]}" = "" ]; then

        # if the WHICH_TRACER_FUNCTION isn't empty, pattern matching the case
        case "${WHICH_TRACER_FUNCTION}" in
        # call bpftrace
        "-bpftrace")
            BPFTRACE_VIS="flamegraph, histogram"
            export BPFTRACE_VIS
            if ! bpftrace_function; then
                echo && echo "|> Error: the [tracer_type_caller] function could not call [bpftrace_function]. Exiting now..."
                echo && echo
                return 1
            fi
            echo "|> Sucessfully called the [bpftrace_function] with [tracer_type_caller]. Proceeding..."
            ;;
        # call ftrace
        "-ftrace")
            FTRACE_PID="${FTRACE_PID:-[EMPTY_VARIABLE]}"
            export FTRACE_PID
            FTRACE_ARGS="HMM..."
            export FTRACE_ARGS
            if ! ftrace_function; then
                echo && echo "|> Error: the [tracer_type_caller] function could not call [ftrace_function]. Exiting now..."
                echo && echo
                return 1
            fi
            echo "|> Sucessfully called the [ftrace_function] with [tracer_type_caller]. Proceeding..."
            echo && echo
            ;;
        # call libbpftrace
        "-libbpftrace")
            BEETOR_ARGS="HMM"
            export BEETOR_ARGS
            if ! beetor_function; then
                echo && echo "|> Error: the [tracer_type_caller] function could not call [beetor_function]. Exiting now..."
                return 1
            fi
            echo "|> Sucessfully used [tracer_type_caller] function to call [beetor_function]. Proceeding..."
            echo && echo
            ;;
        # call zig ebpf with wasm on deno
        "-zwtd_bpf")
            ZWTD_BPF_ARGS="HMM"
            export ZWTD_BPF_ARGS
            if ! zwtd_function; then
                echo && echo "|> Error: the [tracer_type_caller] function could not call [zwtd_function]. Exiting now..."
                return 1
            fi
            echo "|> Sucessfully used [tracer_type_caller] function to call [zwtd_function]. Proceeding..."
            echo && echo
            ;;
        # call aya-rs
        "-ayaya")
            AYA_BPF_ARGS="HMM"
            export AYA_BPF_ARGS
            if ! ayaya_function; then
                echo && echo "|> Error: the [tracer_type_caller] function could not call [ayaya_function]. Exiting now..."
                return 1
            fi
            echo "|> Sucessfully used [tracer_type_caller] function to call [ayaya_function]. Proceeding..."
            echo && echo
            ;;
        # call elixir's honey-potion
        "-hpota")
            HPOTA_BPF_ARGS="HMM"
            export HPOTA_BPF_ARGS
            if ! hpota_function; then
                echo && echo "|> Error: the [tracer_type_caller] function could not call [hpota_function]. Exiting now..."
                return 1
            fi
            echo "|> Sucessfully used [tracer_type_caller] function to call [hpota_function]. Proceeding..."
            echo && echo
            ;;
            # call elixir's honey-potion
        "-jvm")
            JVM_BPF_ARGS="HMM"
            export JVM_BPF_ARGS
            if ! jvm_function; then
                echo && echo "|> Error: the [tracer_type_caller] function could not call [jvm_function]. Exiting now..."
                return 1
            fi
            echo "|> Sucessfully used [tracer_type_caller] function to call [jvm_function]. Proceeding..."
            echo && echo
            ;;
        # call ebpf with ocaml posix interface
        "-ocaml")
            OCAML_BPF_ARGS="HMM"
            export OCAML_BPF_ARGS
            if ! ocaml_function; then
                echo && echo "|> Error: the [tracer_type_caller] function could not call [ocaml_function]. Exiting now..."
                return 1
            fi
            echo "|> Sucessfully used [tracer_type_caller] function to call [ocaml_function]. Proceeding..."
            echo && echo
            ;;
        # call lunatik bpf
        "-lua")
            LUA_BPF_ARGS="HMM"
            export LUA_BPF_ARGS
            if ! lua_function; then
                echo && echo "|> Error: the [tracer_type_caller] function could not call [lua_function]. Exiting now..."
                return 1
            fi
            echo "|> Sucessfully used [tracer_type_caller] function to call [lua_function]. Proceeding..."
            echo && echo
            ;;
        "*")
            echo && echo "|> Error: WHICH_TRACER_FUNCTION=${WHICH_TRACER_FUNCTION:-[EMPTY_VARIABLE]} is not a valid [TRACER] option. Options are:"
            # print TRACER TYPE CALLER usage
            print_TTC_usage
            echo "|> Exiting now..."
            echo && echo
            return 1
            ;;
        esac
    fi
    echo "|> Sucessfully ran the tracer_type_caller. Proceeding..."
    return
}

unpack_gvisor() {
    if ! [ -f "${VIRTIO_PASSTHRU_DIR:-[EMPTY_VARIABLE]}/gvisor-core.tar.gz" ]; then
        echo && echo "|> Error: it was not possible to find the gvisor tarball. Exiting now..."
        echo "|> SCOPE: [unpack_gvisor], file: [./scripts/isogen/poc-bootscript.sh], check 01"
        echo && echo
        return 1
    fi
    echo "|> Sucessfully found the gvisor tarball. Proceeding..."
    echo "|> SCOPE: [unpack_gvisor], file: [./scripts/isogen/poc-bootscript.sh], check 01"
    echo && echo

    # decompress the gvisor-core.tar.gz
    if ! (tar -xvf "${VIRTIO_PASSTHRU_DIR:-[EMPTY_VARIABLE]}/gvisor-core.tar.gz" -C /app/microvms/); then
        echo && echo "|> Error: could not enter VIRTIO_PASSTHRU_DIR=${VIRTIO_PASSTHRU_DIR:-[EMPTY_VARIABLE]} and decompress the gvisor-core.tar.gz into the path /app/microvms/ . Exiting now..."
        echo "|> SCOPE: [unpack_gvisor], file: [./scripts/isogen/poc-bootscript.sh], check 02"
        echo && echo
        return 1
    fi
    echo "|> Sucessfully entered VIRTIO_PASSTHRU_DIR=${VIRTIO_PASSTHRU_DIR:-[EMPTY_VARIABLE]} and decompress the gvisor-core.tar.gz into the path /app/microvms/ . Proceeding..."
    echo "|> SCOPE: [unpack_gvisor], file: [./scripts/isogen/poc-bootscript.sh], check 02"
    echo && echo
}

unpack_firecracker() {
    if ! [ -f "${VIRTIO_PASSTHRU_DIR:-[EMPTY_VARIABLE]}/firecracker-core.tar.gz" ]; then
        echo && echo "|> Error: it was not possible to find the firecracker tarball. Exiting now..."
        echo "|> SCOPE: [unpack_firecracker], file: [./scripts/isogen/poc-bootscript.sh], check 01"
        echo && echo
        return 1
    fi
    echo "|> Sucessfully found the firecracker tarball. Proceeding..."
    echo "|> SCOPE: [unpack_firecracker], file: [./scripts/isogen/poc-bootscript.sh], check 01"
    echo && echo

    # decompress the firecracker-core.tar.gz
    if ! (tar -xvf "${VIRTIO_PASSTHRU_DIR:-[EMPTY_VARIABLE]}/firecracker-core.tar.gz" -C /app/microvms/); then
        echo && echo "|> Error: could not enter VIRTIO_PASSTHRU_DIR=${VIRTIO_PASSTHRU_DIR:-[EMPTY_VARIABLE]} and decompress the firecracker-core.tar.gz into the path /app/microvms/ . Exiting now..."
        echo "|> SCOPE: [unpack_firecracker], file: [./scripts/isogen/poc-bootscript.sh], check 02"
        echo && echo
        return 1
    fi
    echo "|> Sucessfully entered VIRTIO_PASSTHRU_DIR=${VIRTIO_PASSTHRU_DIR:-[EMPTY_VARIABLE]} and decompress the firecracker-core.tar.gz into the path /app/microvms/ . Proceeding..."
    echo "|> SCOPE: [unpack_firecracker], file: [./scripts/isogen/poc-bootscript.sh], check 02"
    echo && echo
}

unpack_kata() {
    if ! [ -f "${VIRTIO_PASSTHRU_DIR:-[EMPTY_VARIABLE]}/kata-core.tar.gz" ]; then
        echo && echo "|> Error: it was not possible to find the kata tarball. Exiting now..."
        echo "|> SCOPE: [unpack_kata], file: [./scripts/isogen/poc-bootscript.sh], check 01"
        echo && echo
        return 1
    fi
    echo "|> Sucessfully found the kata tarball. Proceeding..."
    echo "|> SCOPE: [unpack_kata], file: [./scripts/isogen/poc-bootscript.sh], check 01"
    echo && echo

    # decompress the kata-core.tar.gz
    if ! (tar -xvf "${VIRTIO_PASSTHRU_DIR:-[EMPTY_VARIABLE]}/kata-core.tar.gz" -C /app/microvms/); then
        echo && echo "|> Error: could not enter VIRTIO_PASSTHRU_DIR=${VIRTIO_PASSTHRU_DIR:-[EMPTY_VARIABLE]} and decompress the kata-core.tar.gz into the path /app/microvms/ . Exiting now..."
        echo "|> SCOPE: [unpack_kata], file: [./scripts/isogen/poc-bootscript.sh], check 02"
        echo && echo
        return 1
    fi
    echo "|> Sucessfully entered VIRTIO_PASSTHRU_DIR=${VIRTIO_PASSTHRU_DIR:-[EMPTY_VARIABLE]} and decompress the kata-core.tar.gz into the path /app/microvms/ . Proceeding..."
    echo "|> SCOPE: [unpack_kata], file: [./scripts/isogen/poc-bootscript.sh], check 02"
    echo && echo
}

unpack_microvms() {

    mkdir -p /app/microvms

    if ! unpack_gvisor; then
        echo && echo "|> Error: could not unpack gvisor. Exiting now..."
        echo "|> SCOPE: [unpack_microvms], file: [./scripts/isogen/poc-bootscript.sh], check 01"
        echo && echo
        return 1
    fi
    echo "|> Sucessfully unpacked gvisor. Proceeding..."
    echo "|> SCOPE: [unpack_microvms], file: [./scripts/isogen/poc-bootscript.sh], check 01"
    echo && echo

    ### if ! unpack_firecracker; then
    ###     echo && echo "|> Error: could not unpack firecracker-containerd with the [unpack_firecracker] function. Exiting now..."
    ###     echo "|> SCOPE: [unpack_microvms], file: [./scripts/isogen/poc-bootscript.sh], check 02"
    ###     echo && echo
    ###     return 1
    ### fi
    ### echo "|> Sucessfully unpacked firecracker-containerd with the [unpack_firecracker] function. Proceeding..."
    ### echo "|> SCOPE: [unpack_microvms], file: [./scripts/isogen/poc-bootscript.sh], check 02"
    ### echo && echo

    ### if ! unpack_kata; then
    ###     echo && echo "|> Error: could not unpack kata. Exiting now..."
    ###     echo "|> SCOPE: [unpack_microvms], file: [./scripts/isogen/poc-bootscript.sh], check 03"
    ###     echo && echo
    ###     return 1
    ### fi
    ### echo "|> Sucessfully unpacked kata. Proceeding..."
    ### echo "|> SCOPE: [unpack_microvms], file: [./scripts/isogen/poc-bootscript.sh], check 03"
    ### echo && echo

}

# here lies the k3s airgap images
unsquash_squashfs_sdb() {

    MOUNT_SQUASHFS_DIR="/mnt/airgap-registry-image"
    UNSQUASHED_DIR="/mnt/k3s-squashfs"
    SQUASH_FS_FILE="${MOUNT_SQUASHFS_DIR:-[EMPTY_VARIABLE]}/k3s-tarball.squashfs"

    # create directories for the squashfs file and its decompression
    mkdir -p "${MOUNT_SQUASHFS_DIR:-[EMPTY_VARIABLE]}"
    mkdir -p "${UNSQUASHED_DIR:-[EMPTY_VARIABLE]}"

    if ! (mount /dev/sdb "${MOUNT_SQUASHFS_DIR:-[EMPTY_VARIABLE]}"); then
        echo && echo "|> Error: could not mount /dev/sdb into the ${MOUNT_SQUASHFS_DIR:-[EMPTY_VARIABLE]} filepath. Exiting now..."
        echo "|> SCOPE: [unsquash_squashfs_sdb], file: [./scripts/isogen/poc-bootscript.sh], check: 01"
        echo && echo
        return 1
    fi
    echo "|> Successfully mount /dev/sdb into /mnt/airgap-registry-image filepath. Proceeding..."
    echo "|> SCOPE: [unsquash_squashfs_sdb], file: [./scripts/isogen/poc-bootscript.sh], check: 01"
    echo && echo

    #cd "${MOUNT_SQUASHFS_DIR:-[EMPTY_VARIABLE]}" || return

    ls -allhtr "${MOUNT_SQUASHFS_DIR:-[EMPTY_VARIABLE]}"

    if ! [ -f "${SQUASH_FS_FILE:-[EMPTY_VARIABLE]}" ]; then
        echo && echo "|> Error: it was not possible to find the ${SQUASH_FS_FILE:-[EMPTY_VARIABLE]} at ${MOUNT_SQUASHFS_DIR:-[EMPTY_VARIABLE]}. Exiting now..."
        echo "|> SCOPE: [unsquash_squashfs_sdb], file: [./scripts/isogen/poc-bootscript.sh], check: 02"
        echo && echo
        return 1
    fi
    echo "|> Successfully found the ${SQUASH_FS_FILE:-[EMPTY_VARIABLE]} at ${MOUNT_SQUASHFS_DIR:-[EMPTY_VARIABLE]}. Proceeding..."
    echo "|> SCOPE: [unsquash_squashfs_sdb], file: [./scripts/isogen/poc-bootscript.sh], check: 02"
    echo && echo

    # unsquash the squashfs with the airgap images inside
    if ! (unsquashfs -d "${UNSQUASHED_DIR:-[EMPTY_VARIABLE]}" "${SQUASH_FS_FILE:-[EMPTY_VARIABLE]}"); then
        echo && echo "|> Error: could not unsquash the /mnt/airgap-registry-image/k3s-tarball.squashfs into the /mnt/k3s-squashfs directory."
        echo "|> SCOPE: [unsquash_squashfs_sdb], file: [./scripts/isogen/poc-bootscript.sh], check: 03"
        return 1
    fi
    echo "|> Successfully unsquashed the ${SQUASH_FS_FILE:-[EMPTY_VARIABLE]} into the ${UNSQUASHED_DIR:-[EMPTY_VARIABLE]} directory. Proceeding..."
    echo "|> SCOPE: [unsquash_squashfs_sdb], file: [./scripts/isogen/poc-bootscript.sh], check: 03"
    echo && echo

    if ! [ -f "${UNSQUASHED_DIR:-[EMPTY_VARIABLE]/k3s-airgap-images-amd64.tar}" ]; then
        echo "|> It was not possible to find the k3s-airgap-images-amd64.tar unsquashed. Possible error on the previous step. Exiting now..."
        echo "|> SCOPE: [unsquash_squashfs_sdb], file: [./scripts/isogen/poc-bootscript.sh], check: 04"
        echo && echo
        return 1
    fi
    echo "|> Successfully found the k3s-airgap-images-amd64.tar unsquashed. Proceeding..."
    echo "|> SCOPE: [unsquash_squashfs_sdb], file: [./scripts/isogen/poc-bootscript.sh], check: 04"
    echo && echo

    #cd - || return

}

runtimeclass_job() {
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

    if ! (cat /proc/cpuinfo | grep QEMU); then
        echo && echo "|> Error: not running inside QEMU, outside of POC scope. Exiting now..."
        echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 01"
        echo && echo
        # ETC_CONTAINERS_CONF="${ISO_DIR:-[EMPTY_VARIABLE]}/rootfs/etc/containers/containers.conf"
        # ETC_CONTAINERS_STORAGE_CONF="${ISO_DIR:-[EMPTY_VARIABLE]}/rootfs/etc/containers/storage.conf"
        return 1
    fi
    echo "|> Sucessfully running inside QEMU, inside of the POC scope. Proceeding..."
    echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 01"
    echo && echo

    ETC_CONTAINERS_CONF="/etc/containers/containers.conf"
    ETC_CONTAINERS_STORAGE_CONF="/etc/containers/storage.conf"

    mkdir -p "${VIRTIO_PASSTHRU_DIR}"

    # FUNCTION CALL
    first_setup

    ### if (mount | grep hostshare); then
    ###     if ! umount "${VIRTIO_PASSTHRU_DIR:-[EMPTY_VARIABLE]}"; then
    ###         echo "|> Error: could not unmount the hostshare 9P virtio for the virtfs option of QEMU. Exiting now..."
    ###         return 1
    ###     fi
    ###     echo "|> Sucessfully unmounted the hostshare 9P virtio for the virtfs option of QEMU. Proceeding..."
    ### fi

    ### if ! (mount -t 9p -o trans=virtio hostshare "${VIRTIO_PASSTHRU_DIR}"); then
    ###     echo && echo "|> Error: it was not possible to mount 9P using virtio as transport option. Exiting now..."
    ###     echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 02"
    ###     echo && echo
    ###     return 1
    ### fi
    ### echo "|> Successfully mounted 9P using virtio as transport option. Proceeding..."
    ### echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 02"
    ### echo && echo

    # if user is on the root of repository, define containers.conf
    # using the ISO_DIR environment variables.
    #

    # rootless containers
    # podman

    # KMOD / LKM Linux Kernel Modules base setup
    if ! kmod_lkm_setup; then
        echo "|> Error: could not run the [kmod_lkm_setup] function, which handles kmod/LKM Linux Kernel Modules base setup. Exiting now..."
        echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 04"
    fi
    echo "|> Sucessfully ran the [kmod_lkm_setup] function. Proceeding..."
    echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 04"

    # Prepare run directory for containerd and k3s
    # mkdir -p /run /var/run
    mkdir -p /run /var
    if ! (mount -t tmpfs tmpfs /run); then
        echo && echo "|> Error: could not mount type tmpfs at [/run]. Exiting now..."
        echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 05"
        echo && echo
        return 1
    fi
    echo "|> Sucessfully mounted type tmpfs at [/run]. Proceeding..."
    echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 05"
    echo && echo

    # soft link of the previous mounted tmpfs filesystem at /run
    if ! (ln -s /run /var/ 2>/dev/null); then
        echo "|> could not create symlink (soft link) of [/run] at [/var]. Exiting now..."
        echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 06"
        echo && echo
        #return 1
    fi
    echo "|> Sucessfully created symlink (soft link) of [/run] at [/var]. Proceeding..."
    echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 06"
    echo && echo

    # create k3s directories
    if ! (
        mkdir -p /run/k3s/containerd
        mkdir -p /var/lib/rancher/k3s
        mkdir -p /etc/rancher/k3s
    ); then
        echo && echo "|> Error: could not create k3s directories. Exiting now..."
        echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 07"
        echo && echo
        return 1
    fi
    echo "|> Sucessfully created k3s directories. Proceding..."
    echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 07"
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
        echo && echo "|> Error: could not generate a simple crictl.yaml at [/app/crictl.yaml]. Exiting now..."
        echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 08"
        echo && echo
        return 1
    fi
    echo "|> Sucessfully generated a simple crictl.yaml at [/app/crictl.yaml]. Proceding..."
    echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 08"

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
        echo && echo "|> Error: could not create ${ETC_CONTAINERS_CONF:-[EMPTY_VARIABLE]} configuration file, the runtimeClass lookup filepaths for k3s. Exiting now..."
        echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 09"
        echo && echo
        return 1
    fi
    echo "|> Sucessfully created ${ETC_CONTAINERS_CONF:-[EMPTY_VARIABLE]} configuration file, the runtimeClass lookup filepaths for k3s. Proceeding..."
    echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 09"
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
rootless_storage_path = "${HOME:-[EMPTY_VARIABLE]}/.local/share/containers/storage"

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
        echo && echo "|> Error: could not create the ${ETC_CONTAINERS_STORAGE_CONF:-[EMPTY_VARIABLE]}, the storage info for OCI containers. Exiting now..."
        echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 10"
        echo && echo
        return 1
    fi
    echo "|> Sucessfully created the ${ETC_CONTAINERS_STORAGE_CONF:-[EMPTY_VARIABLE]}, the storage info for OCI containers. Proceeding..."
    echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 10"
    echo && echo

    # setup the k3s crictl configuration file: crictl.yaml
    if ! (
        (
            cat <<EOF

runtime-endpoint: unix:///run/k3s/containerd/containerd.sock
image-endpoint: unix:///run/k3s/containerd/containerd.sock
timeout: 10
debug: false
EOF
        ) | tee "${K3S_CRICTL_CONF_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo && echo "|> Error: could not setup the k3s crictl configuration file K3S_CRICTL_CONF_FILE=${K3S_CRICTL_CONF_FILE:-[EMPTY_VARIABLE]} . Exiting now..."
        echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 11"
        echo && echo
        return 1
    fi
    echo "|> Sucessfully setup the k3s crictl configuration file K3S_CRICTL_CONF_FILE=${K3S_CRICTL_CONF_FILE:-[EMPTY_VARIABLE]} . Proceeding..."
    echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 11"
    echo && echo

    # k3s crictl --config=/app/crictl.yaml ps --all

    # FUNCTION CALL
    if ! unsquash_squashfs_sdb; then
        echo && echo "|> Error: cannot call the [unsquash_squashfs_sdb] function to decompress the squashfs filesystem holding the k3s airgap images. Exiting now..."
        echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 12"
        echo && echo
        return 1
    fi
    echo "|> Sucessfully called the [unsquash_squashfs_sdb] function to decompress the squashfs filesystem holding the k3s airgap images. Proceeding..."
    echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 12"
    echo && echo

    # bpftrace dependencies, libclang from llvm17, podman dependencies
    #cp /app/archive.tar.gz /app/shared-deps/

    # copy the tarball of the shared dependencies
    ### if ! (cp /app/archive.tar.gz /app/shared-deps/); then
    ###     echo && echo "|> Error: could not copy the [/app/archive.tar.gz] file to [/app/shared-deps]. Exiting now..."
    ###     echo && echo
    ###     return 1
    ### fi
    ### echo "|> Sucessfully copied the [/app/archive.tar.gz] file to [/app/shared-deps]. Proceeding..."
    ### echo && echo

    # copy the tarball of the shared dependencies
    if ! (cp "${VIRTIO_PASSTHRU_DIR:-[EMPTY_VARIABLE]}/archive.tar.gz" /app/shared-deps/); then
        echo && echo "|> Error: could not copy the [${VIRTIO_PASSTHRU_DIR:-[EMPTY_VARIABLE]}/archive.tar.gz] file to [/app/shared-deps]. Exiting now..."
        echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 13"
        echo && echo
        return 1
    fi
    echo "|> Sucessfully copied the [/app/archive.tar.gz] file to [/app/shared-deps]. Proceeding..."
    echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 13"
    echo && echo

    cd /app/shared-deps/ || return

    if ! (
        (tar -tvf "${VIRTFS_ART_PATH:-[EMPTY_VARIABLE]}/archive.tar.gz" | grep lib -m 1)
        (tar -tvf "${VIRTFS_ART_PATH:-[EMPTY_VARIABLE]}/archive.tar.gz" | grep usr -m 1)
        (tar -tvf "${VIRTFS_ART_PATH:-[EMPTY_VARIABLE]}/archive.tar.gz" | grep musl -m 1)
    ); then
        echo && echo "|> Error: either lib or usr or musl were not found on the contents of this archive.tar.gz "
        echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 14"
        echo && echo
        return 1
    fi
    echo "|> Successfully: found the [lib] and [usr] directories alongside with musl on the contents of this [archive.tar.gz]. Proceeding..."
    echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 14"
    echo && echo

    if ! (tar -xvf ./archive.tar.gz); then
        echo && echo "|> Error: could not decompress the [./archive.tar.gz] filepath. Exiting now..."
        echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 15"
        echo && echo
        return 1
    fi
    echo "|> Successfully decompressed the [./archive.tar.gz] filepath. Proceeding..."
    echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 15"
    echo && echo

    # copy archive tarball local lib directory to the global at the rootfs of the guest virtual machine.
    if ! (cp -r ./lib/* /lib/); then
        echo && echo "|> Error: could not copy the local directory [./lib/*] to the global [/lib] at the rootfs of the guest virtual machine. Exiting now..."
        echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 16"
        echo && echo
        return 1
    fi
    echo "|> Sucessfully copied the local directory [./lib/*] to the global [/lib] at the rootfs of the guest virtual machine. Proceeding..."
    echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 16"
    echo && echo

    # copy archive tarball local usr directory to the global at the rootfs of the guest virtual machine.
    if ! (cp -r ./usr/* /usr/); then
        echo && echo "|> Error: could not copy the local directory [./usr/*] to the global [/usr] at the rootfs of the guest virtual machine. Exiting now..."
        echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 17"
        echo && echo
        return 1
    fi
    echo "|> Sucessfully copied the local directory [./usr/*] to the global [/usr] at the rootfs of the guest virtual machine. Proceeding..."
    echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 17"
    echo && echo

    # cleanup the current clang shared object if it exists
    if ! (rm /usr/lib/libclang.so.17); then
        echo && echo "|> Error: could not remove the /usr/lib/libclang.so.17 filepath. Exiting now..."
        echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 18"
        echo && echo
        return 1
    fi
    echo "|> Sucessfully removed the /usr/lib/libclang.so.17 filepath. Proceeding..."
    echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 18"
    echo && echo

    # Create a clang symlink
    if ! (ln -s /usr/lib/llvm17/lib/libclang.so.17.0.6 /usr/lib/libclang.so.17); then
        echo && echo "|> Error: could not create a symlink (symbolic link) of libclang. Exiting now..."
        echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 19"
        echo && echo
        return 1
    fi
    echo "|> Sucessfully created a symlink (symbolic link) of libclang. Proceeding..."
    echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 19"
    echo && echo

    # =============
    cd - || return

    # ===============================
    # Microvms setup
    # FUNCTION CALL
    if ! unpack_microvms; then
        echo && echo "|> Error: cannot run the [unpack_microvms] function. Exiting now..."
        echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 20"
        echo && echo
        return 1
    fi
    echo "|> Sucessfully ran the [unpack_microvms] function. Proceeding..."
    echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 20"
    echo && echo

    #============================================

    # Bring network up
    if ! (ip link set lo up); then
        echo && echo "|> Error: could not bring the network up with iproute2 ip (busybox). Exiting now..."
        echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 21"
        echo && echo
        return 1
    fi
    echo "|> Sucessfully bring the network up with iproute2 ip (busybox). Proceeding..."
    echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 21"
    echo && echo

    # run containerd in background.
    if ! (containerd &) then
        echo && echo "|> Error: could not run containerd in background. Exiting now..."
        echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 22"
        echo && echo
        return 1
    fi
    echo "|> Sucessfully ran containerd in background. Proceeding..."
    echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 22"
    echo && echo

    # create soft link (symlink) for the container socket to be found by k3s
    if ! (ln -s /run/containerd/containerd.sock /run/k3s/containerd/); then
        echo && echo "|> Error: could not create soft link (symlink) for the containerd socket to be found by k3s. Exiting now..."
        echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 23"
        echo && echo
        return 1
    fi
    echo "|> Sucessfully created soft link (symlink) for the containerd socket to be found by k3s. Proceeding..."
    echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 23"
    echo && echo

    if ! (
        (
            cat <<EOF
containerd:
  snapshotter: fuse-overlayfs
EOF
        ) | tee "${K3S_AGENT_CONF_FILE:-[EMPTY_VARIABLE]}"
    ); then
        echo && echo "|> Error: could not create declarative yaml config  at [K3S_AGENT_CONF_FILE=${K3S_AGENT_CONF_FILE:-[EMPTY_VARIABLE]}] telling the agent config to use fuse-overlayfs as containerd's default snapshotter. Exiting now..."
        echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 24"
        echo && echo
        return 1
    fi
    echo "|> Sucessfully created declarative yaml config  at [K3S_AGENT_CONF_FILE=${K3S_AGENT_CONF_FILE:-[EMPTY_VARIABLE]}] telling the agent config to use fuse-overlayfs as containerd's default snapshotter. Proceeding..."
    echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 24"
    echo && echo

    # /etc/rancher/k3s/registries.yaml

    #k3s server --disable-agent --default-runtime=runc & > /dev/null 2>&1
    #k3s server --default-runtime=runc --disable=traefik & > /dev/null 2>&1
    # k3s server --default-runtime=runc --disable=traefik --config=/etc/rancher/k3s/agent-config.yaml & > /dev/null 2>&1
    # k3s server --disable-agent --default-runtime=runc --disable=traefik --snapshotter=fuse-overlayfs > /dev/null 2>&1 &
    # k3s server --disable-agent --default-runtime="crun" --disable=traefik --snapshotter=overlayfs > /dev/null 2>&1 &

    if ! (k3s server --disable-agent --default-runtime="crun" --disable=traefik --snapshotter=fuse-overlayfs >/dev/null 2>&1 &) then
        echo && echo "|> Error: could not start the k3s server. Exiting now..."
        echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 25"
        return 1
    fi
    echo "|> Sucessfully started the k3s server. Proceeding..."
    echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 25"
    echo && echo

    # Setup bpftrace
    WHICH_TRACER_FUNCTION="-bpftrace"
    if ! tracer_type_caller; then
        echo && echo "|> Error: could not run [tracer_type_caller]. Exiting now..."
        echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 26"
        echo && echo
        return 1
    fi
    echo && echo "|> Error: could not run [tracer_type_caller]. Exiting now..."
    echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 26"
    echo && echo

    ### # FUNCTION CALL
    ### if ! bpftrace_function; then
    ###     echo && echo "|> Error: could not run the bpftrace function to perform tracing over the k3s process and its kernel subsystem usage. Exiting now..."
    ###     echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 26"
    ###     echo && echo
    ###     return 1
    ### fi
    ### echo "|> Sucessfully ran the bpftrace function to perform tracing over the k3s process and its kernel subsystem usage. Proceeding..."
    ### echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 26"
    ### echo && echo

    # list namespaces of k3s with ctr
    if ! (k3s ctr namespace list); then
        echo && echo "|> Error: could not list namespaces of k3s with ctr. Exiting now..."
        echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 27"
        echo && echo
        return 1
    fi
    echo "|> Sucessfully listed namespaces of k3s with ctr. Proceeding..."
    echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 27"
    echo && echo

    # create namespace and import the airgap tarball
    # k3s kubectl create namespace "k8s.io"
    # ================================================================
    # !!!!!!! IMPORTANT !!!!!!
    # these airgap images should be previously converted to oci
    # in order to push to the registry. umoci can help with that.
    # ================================================================

    # import the k3s airgap images with k3s ctr
    if ! (k3s ctr -n="k8s.io" images import /mnt/k3s-squashfs/k3s-airgap-images-amd64.tar); then
        echo && echo "|> Error: could not import the k3s airgap images with k3s ctr. Exiting now..."
        echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 28"
        echo && echo
        return 1
    fi
    echo "|> Successfully imported the k3s airgap images with k3s ctr. Proceeding..."
    echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 28"
    echo && echo

    # Make sure to unmount the /dev/sdb that had the squashfs now
    # that it isn't needed anymore (previous test).
    if ! (mount | grep /dev/sdb); then
        echo && echo "|> Error: DID NOT found the /dev/sdb mounted. Exiting now..."
        echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 29"
        echo && echo
        return 1
    fi
    echo "|> Sucessfully found a /dev/sdb mounted. Attempting to unmount..."
    echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 29"
    echo && echo

    if ! (umount /dev/sdb); then
        echo && echo "|> Error: could not unmount /dev/sdb. Exiting now..."
        echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 30"
        echo && echo
        return 1
    fi
    echo "|> Successfully unmounted /dev/sdb. Proceeding..."
    echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 30"
    echo && echo

    # import the OCI registry:3.0 server image
    if ! (k3s ctr -n="k8s.io" images import /mnt/k3s-squashfs/skopeo-convert-registry.oci.tar); then
        echo && echo "|> Error: could not import the OCI registry:3.0 server image. Exiting now..."
        echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 31"
        echo && echo
        return 1
    fi
    echo "|> Successfully imported the OCI registry:3.0 server image. Proceeding..."
    echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 31"
    echo && echo

    # get name of the image at the time of import
    # OR_IMG_NAME=$(k3s ctr -n="k8s.io" images import /mnt/k3s-squashfs/skopeo-convert-registry.oci.tar | grep "unpacking" | awk '{ print $2 }')
    if ! UNPACK_NAME=$(k3s ctr images list | grep import | awk '{print $1}'); then
        echo && echo "|> Error: could not get the name of the image at the time of import (with the UNPACK_NAME variable). Exiting now..."
        echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 32"
        echo && echo
        return 1
    fi
    echo "|> Successfully got the name of the image at the time of import (with the UNPACK_NAME variable). Proceeding..."
    echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 32"
    echo && echo

    # tag image with the default name for localhost registry deploys
    if ! (k3s ctr -n="k8s.io" images tag "$UNPACK_NAME" "localhost:5000/registry:3.0"); then
        echo && echo "|> Error: could not tag image with the default name for localhost registry deploys. Exiting now..."
        echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 33"
        echo && echo
        return 1
    fi
    echo "|> Sucessfully tagged image with the default name for localhost registry deploys. Proceeding..."
    echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 32"
    echo && echo

    # check the tagged image on the list
    if ! (k3s ctr images ls); then
        echo && echo "|> Error: could not check the tagged image on the list. Exiting now..."
        echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 33"
        echo && echo
        return 1
    fi
    echo "|> Successfully checked the tagged image on the list. Proceeding..."
    echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 33"
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
        echo && echo "|> Error: could not create the container with k3s ctr, which would be run by k3s containerd. Exiting now..."
        echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 34"
        echo && echo
        return 1
    fi
    echo "|> Successfully created the container with k3s ctr, which would be run by k3s containerd. Proceeding..."
    echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 34"
    echo && echo

    # define variable to check the metrics-server state
    # (beware sub-shell scopes)
    if ! CHECK_METRICS_SERVER="$(k3s kubectl get pods -n=kube-system | grep "metrics-server" | awk '{ print $1 }')"; then
        echo && echo "|> Error: could not check metrics-server state. Exiting now..."
        echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 35"
        echo && echo
        return 1
    fi
    echo "|> Sucessfully checked metrics-server state. Proceeding..."
    echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 35"
    echo && echo

    # describe Pod of the metrics-server state
    if ! (k3s kubectl describe pod "${CHECK_METRICS_SERVER:-[EMPTY_VARIABLE]}" -n=kube-system); then
        echo && echo "|> Error: could not describe Pod of the metrics-server state. Exiting now..."
        echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 36"
        echo && echo
        return 1
    fi
    echo "|> Successfully described the Pod of the metrics-server state. Proceeding..."
    echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 36"
    echo && echo

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
    if ! runtimeclass_job; then
        echo && echo "|> Error: could not create the runtimeClass(rc) job to be performed to each of the microvms and other (rc) classes in k3s. Exiting now..."
        echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 37"
        echo && echo
        return 1
    fi
    echo "|> Created the runtimeClass(rc) job to be performed to each of the microvms and other (rc) classes in k3s. Proceeding..."
    echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 37"
    echo && echo

    # Gracefully exit (with SIGTERM) bpftrace and return plot graph
    if ! [ "${BPFTRACE_PID:-[EMPTY_VARIABLE]}" = "" ]; then
        #(kill -SIGINT "$BPFTRACE_PID")
        if ! (kill -SIGTERM "$BPFTRACE_PID"); then
            echo && echo "|> Error: could not gracefully exit BPFTRACE_PID=${BPFTRACE_PID:-[EMPTY_VARIABLE]}. Exiting now..."
            echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 38"
            echo && echo
            return 1
        fi
        echo "|> Sucessfully performed a gracefully exit over the BPFTRACE_PID=${BPFTRACE_PID:-[EMPTY_VARIABLE]}. Proceeding..."
        echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 38"
        echo && echo
    fi

    # Kill k3s
    if ! (kill -SIGTERM $(pgrep k3s)); then
        echo && echo "|> Error: could not kill k3s. Exiting now..."
        echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 39"
        echo && echo
        return 1
    fi
    echo "|> Sucessfully killed k3s. Proceeding..."
    echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 39"
    echo && echo

    # reboot: power down
    # stops recording the asciinema section
    if ! (poweroff -f); then
        echo && echo "|> Error: could not reboot/power-down the QEMU guest virtual machine. Exiting now (anyway! haha)..."
        echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 40"
        echo && echo
        return 1
    fi
    echo "|> Sucessfully reboot/power-down the QEMU guest virtual machine. Will this even be reached?"
    echo "|> SCOPE: main, file: [./scripts/isogen/poc-bootscript.sh], check: 40"
    echo && echo

}

print_usage() {
    cat <<-END >&2
USAGE: poc-bootscript [-options]
                - main
                - help
                - version
eg,
MODE="-main" . /app/poc-bootscript.sh
MODE="-main" . /mnt/virtio-test/poc-bootscript.sh

poc-bootscript -main    # runs the [_main_scope] function of this program.
poc-bootscript -help    # shows this help message
poc-bootscript -version # shows script version

See the man page and example file for more info.

END

}

if [ "${MODE}" = "--main" ] || [ "${MODE}" = "-m" ] || [ "${MODE}" = "-main" ]; then
    if ! _main_scope; then
        echo && echo "|> Error: could not run the [_main_scope] function of [poc-bootscript] shellscript. Exiting now..."
        print_usage
        echo && echo
        return 1
    fi
    echo
    echo "|> Sucessfully ran the [_main_scope] function of [poc-bootscript] shellscript. Proceeding..."
    echo && echo
else
    echo && echo "|> Error: could not run the [_main_scope], probably no option was oferred. Exiting now..."
    echo
    return 1
fi
