#!/bin/sh

patch_k3s() {

fakerootdir="/var/lib/rancher/k3s/agent/etc/containerd/config.toml.tmpl"

(
cat <<EOF
version = 2

[plugins."io.containerd.internal.v1.opt"]
  path = "/var/lib/rancher/k3s/agent/containerd"
[plugins."io.containerd.grpc.v1.cri"]
  stream_server_address = "127.0.0.1"
  stream_server_port = "10010"
  enable_selinux = false
  enable_unprivileged_ports = true
  enable_unprivileged_icmp = true
  device_ownership_from_security_context = false
  sandbox_image = "rancher/mirrored-pause:3.6"

[plugins."io.containerd.grpc.v1.cri".containerd]
  snapshotter = "overlayfs"
  disable_snapshot_annotations = true

[plugins."io.containerd.grpc.v1.cri".cni]
  bin_dir = "/var/lib/rancher/k3s/data/cni"
  conf_dir = "/var/lib/rancher/k3s/agent/etc/cni/net.d"

[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
  runtime_type = "io.containerd.runc.v2"

[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
  BinaryName = "/usr/bin/runc"
  SystemdCgroup = false

[plugins."io.containerd.grpc.v1.cri".registry]
  config_path = "/var/lib/rancher/k3s/agent/etc/containerd/certs.d"

[plugins."io.containerd.grpc.v1.cri".containerd.runtimes."crun"]
  runtime_type = "io.containerd.runc.v2"
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes."crun".options]
  BinaryName = "/usr/bin/crun"
  SystemdCgroup = false

# gVisor: https://gvisor.dev/
[plugins."io.containerd.cri.v1.runtime".containerd.runtimes.gvisor]
  runtime_type = "io.containerd.runsc.v1"
  BinaryName = "/usr/local/bin/runsc"
# Kata Containers: https://katacontainers.io/
[plugins."io.containerd.cri.v1.runtime".containerd.runtimes.kata]
  runtime_type = "io.containerd.kata.v2"
  BinaryName = "/usr/local/bin/kata-runtime


EOF
) | tee /var/lib/rancher/k3s/agent/containerd/config.toml.tmpl


# "/var/lib/rancher/k3s/agent/etc/containerd/config.toml.tmpl"

    # setup the k3s toml
( cat <<EOF
version = 3
[plugins."io.containerd.cri.v1.runtime".containerd]
  default_runtime_name = "crun"
  [plugins."io.containerd.cri.v1.runtime".containerd.runtimes]
    # crun: https://github.com/containers/crun
    [plugins."io.containerd.cri.v1.runtime".containerd.runtimes.crun]
      runtime_type = "io.containerd.runc.v2"
      [plugins."io.containerd.cri.v1.runtime".containerd.runtimes.crun.options]
        BinaryName = "/usr/local/bin/crun"
    # gVisor: https://gvisor.dev/
    [plugins."io.containerd.cri.v1.runtime".containerd.runtimes.gvisor]
      runtime_type = "io.containerd.runsc.v1"
    # Kata Containers: https://katacontainers.io/
    [plugins."io.containerd.cri.v1.runtime".containerd.runtimes.kata]
      runtime_type = "io.containerd.kata.v2"
EOF
) | tee ./artifacts/custom-rc.toml.tmpl

# setup the kind runtimeClass for each
( cat <<EOF
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: runc
handler: runc
---
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: crun
handler: crun
---
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: gvisor
handler: gvisor
---
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: kata
handler: kata
---
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: youki
handler: youki
---
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: wasmtime
handler: wasmtime
---
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: wasmedge
handler: wasmedge
EOF
) | ./k3s kubectl apply -f -

}
