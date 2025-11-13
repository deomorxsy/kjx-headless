#!/bin/sh

# virtio virtfs interface for
# file sharing between guest and host
VIRTIO_PASSTHRU_DIR="/mnt/virtio-test"
mkdir -p "${VIRTIO_PASSTHRU_DIR}"
mount -t 9p -o trans=virtio hostshare "${VIRTIO_PASSTHRU_DIR}"

# Setup kmod early
# cd /app/
# cp /app/kmod /bin/kmod
#cd /app/shared-deps/

# rootless containers
# podman
modprobe bridge
modprobe br_netfilter
modprobe veth
modprobe tun
modprobe overlay
modprobe iptable_nat
modprobe iptable_security
modprobe ip6table_security
modprobe xt_nat
modprobe xt_MASQUERADE
modprobe xt_addrtype
modprobe xt_multiport
modprobe xt_mark
modprobe xt_ipvs
modprobe xt_comment
modprobe xt_cgroup
modprobe xt_bpf
modprobe xt_SECMARK
modprobe xt_REDIRECT
modprobe xt_LOG
modprobe xt_CONNSECMARK
modprobe nf_log_syslog
modprobe ip_set
modprobe ip_vs
modprobe ip_vs_rr
modprobe cls_bpf
modprobe cls_cgroup
modprobe act_bpf
modprobe vxlan
modprobe udp_tunnel
modprobe ip6_udp_tunnel
modprobe esp4
modprobe macsec
modprobe stp
modprobe p8022
modprobe psnap
modprobe llc
modprobe ebtables
modprobe rpcsec_gss_krb5
modprobe auth_rpcgss
modprobe intel_vsec
modprobe x86_pkg_temp_thermal
modprobe efivarfs

lsmod

# echo tun >>/etc/modules
# echo <USER>:100000:65536 >/etc/subuid
# echo <USER>:100000:65536 >/etc/subgid

lsmod | grep overlay

cp /app/kmod /bin/kmod

# todo: remove hard-coded symlinks
ln -s "/bin/kmod" "/bin/lsmod"
ln -s "/bin/kmod" "/bin/rmmod"
ln -s "/bin/kmod" "/bin/insmod"
ln -s "/bin/kmod" "/bin/modinfo"
ln -s "/bin/kmod" "/bin/modprobe"
ln -s "/bin/kmod" "/bin/depmod"

ln -s "/bin/lsmod"     "/sbin/lsmod"
ln -s "/bin/rmmod"     "/sbin/rmmod"
ln -s "/bin/insmod"    "/sbin/insmod"
ln -s "/bin/modinfo"   "/sbin/modinfo"
ln -s "/bin/modprobe"  "/sbin/modprobe"
ln -s "/bin/depmod"    "/sbin/depmod"


# Prepare run directory for containerd and k3s
mkdir -p /run /var/run
mount -t tmpfs tmpfs /run
ln -s /run /var/ 2>/dev/null

mkdir -p /run/k3s/containerd
mkdir -p /var/lib/rancher/k3s
mkdir -p /etc/rancher/k3s

# Generate a sample crictl.yaml, any path will suffice.
# originally located on the server at: /var/lib/rancher/k3s/server/etc/crictl.yaml
# originally located on the server at: /var/lib/rancher/k3s/agent/etc/crictl.yaml
(
cat <<EOF
runtime-endpoint: unix:///run/k3s/containerd/containerd.sock
EOF
) | tee /app/crictl.yaml

# now the crictl.yaml
#
cat <<EOF > ./var/lib/rancher/k3s/data/cb3f5c92b6adfd5917414d1bb3622a60abec60b103aa6f4faddd48356682e9c3/bin/crictl.yaml

runtime-endpoint: unix:///run/k3s/containerd/containerd.sock
image-endpoint: unix:///run/k3s/containerd/containerd.sock
timeout: 10
debug: false
EOF

# k3s crictl --config=/app/crictl.yaml ps --all

# Unsquash the squashfs with the airgap images inside
mkdir -p /mnt/airgap-registry-image/
mkdir -p /mnt/k3s-squashfs

mount /dev/sdb /mnt/airgap-registry-image/

cd /mnt/airgap-registry-image || return

ls -allhtr /mnt/airgap-registry-image

unsquashfs -d ../k3s-squashfs/ ./k3s-tarball.squashfs

cd - || return


# Setup bpftrace
# bpftrace dependencies, libclang from llvm17
cp /app/archive.tar.gz /app/shared-deps/
cd /app/shared-deps/ || return
tar -xvf ./archive.tar.gz
cp -r ./lib/* /lib/
cp -r ./usr/* /usr/

# Just cleanup the current
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

#k3s server --default-runtime=runc --disable=traefik --config=/etc/rancher/k3s/agent-config.yaml & > /dev/null 2>&1


# k3s server --disable-agent --default-runtime=runc --disable=traefik --snapshotter=fuse-overlayfs > /dev/null 2>&1 &

k3s server --disable-agent --default-runtime="crun" --disable=traefik --snapshotter=fuse-overlayfs > /dev/null 2>&1 &

# k3s server --disable-agent --default-runtime="crun" --disable=traefik --snapshotter=overlayfs > /dev/null 2>&1 &

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

# works now
k3s ctr namespace list

# create namespace and import the airgap tarball
# k3s kubectl create namespace "k8s.io"

# !!!!!!! IMPORTANT !!!!!!
# these airgap images should be converted to oci in order to push to the registry
#
k3s ctr -n="k8s.io" images import /mnt/k3s-squashfs/k3s-airgap-images-amd64.tar
k3s ctr -n="k8s.io" images import /mnt/k3s-squashfs/skopeo-convert-registry.oci.tar

# Get name of the image at the time of import
#OR_IMG_NAME=$(k3s ctr -n="k8s.io" images import /mnt/k3s-squashfs/skopeo-convert-registry.oci.tar | grep "unpacking" | awk '{ print $2 }')

UNPACK_NAME=$(k3s ctr images list | grep import | awk '{print $1}')

# Tag image with the default name for localhost registry deploys
k3s ctr -n="k8s.io" images tag "$UNPACK_NAME" "localhost:5000/registry:3.0"

# Check the tagged image on the list
k3s ctr images ls

# verify if image is imported
# k3s ctr -n k8s.io images ls


# if pgrep k3s; then
#     kill -SIGTERM "$GET_BPFTRACE_PID"
# fi
# create the container with k3s ctr,
# which will be run by k3s containerd
k3s ctr -n="k8s.io" run --rm -t \
  localhost:5000/registry:3.0 \
  registry-test \
  /entrypoint.sh

# Check metrics-server state
CHECK_POD_NAME="$(k3s kubectl get pods -n=kube-system | grep "metrics-server" | awk '{ print $1 }')"
k3s kubectl describe pod "$CHECK_POD_NAME" -n=kube-system


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

# Gracefully exit bpftrace and return plot graph
kill -SIGINT "$BPFTRACE_PID"

# Kill k3s
#
kill -SIGTERM $(pgrep k3s)
