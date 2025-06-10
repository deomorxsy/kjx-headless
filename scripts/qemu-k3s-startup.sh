#!/bin/sh

# prepare run directory for containerd and k3s
mkdir -p /run /var/run
mount -t tmpfs tmpfs /run
ln -s /run /var/ 2>/dev/null

mkdir -p /run/k3s/containerd
mkdir -p /var/lib/rancher/k3s
mkdir -p /etc/rancher/k3s

# Unsquash the squashfs with the airgap images inside
mkdir -p /mnt/airgap-registry-image/
mkdir -p /mnt/k3s-squashfs

mount /dev/sdb /mnt/airgap-registry-image/

cd /mnt/airgap-registry-image || return

ls -allhtr /mnt/airgap-registry-image

unsquashfs -d ../k3s-squashfs/ ./k3s-tarball.squashfs

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


k3s server --disable-agent --default-runtime=runc --disable=traefik --snapshotter=fuse-overlayfs > /dev/null 2>&1 &


# works now
k3s ctr namespace list

# create namespace and import the airgap tarball

k3s kubectl create namespace k8s.io

# !!!!!!! IMPORTANT !!!!!!
# these airgap images should be converted to oci in order to push to the registry
#
# k3s ctr -n="k8s.io" images import /mnt/k3s-squashfs/k3s-airgap-images-amd64.tar
# k3s ctr -n="registry" images import /mnt/k3s-squashfs/oci-registry-tarball.tar


k3s ctr -n="k8s.io" images import /mnt/k3s-squashfs/skopeo-convert-registry.oci.tar

# Get name of the image at the time of import
OR_IMG_NAME=$(k3s ctr -n="k8s.io" images import /mnt/k3s-squashfs/skopeo-convert-registry.oci.tar | grep "unpacking" | awk '{ print $2 }')

# Tag image with the default name for localhost registry deploys
k3s ctr -n="k8s.io" images tag "$OR_IMG_NAME" "localhost:5000/registry:3.0"

# Check the tagged image on the list
k3s ctr images ls

# verify if image is imported
# k3s ctr -n k8s.io images ls

# create the container with k3s ctr,
# which will be run by k3s containerd
k3s ctr -n k8s.io run --rm -t \
  localhost:5000/registry:3.0 \
  registry-test \
  /entrypoint.sh

# Check metrics-server state
CHECK_POD_NAME="$(k3s kubectl get pods -n=kube-system | grep "metrics-server" | awk '{ print $1 }')"
k3s kubectl describe pod "$CHECK_POD_NAME" -n=kube-system


(
cat <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: local-registry
spec:
  containers:
  - name: registry
    image: registry:2
    ports:
    - containerPort: 5000
      hostPort: 5000
EOF
)
