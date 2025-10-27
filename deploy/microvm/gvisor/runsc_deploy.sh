#!/bin/sh

cat > ./deploy/microvm/gvisor/runsc_rcpod.yaml.test <<EOF #| kubectl apply -f -
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: gvisor
handler: runsc
EOF

echo "---" >> ./deploy/microvm/gvisor/runsc_rcpod.yaml.test

cat >> ./deploy/microvm/gvisor/runsc_rcpod.yaml.test <<EOF #| kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: nginx-gvisor
spec:
  runtimeClassName: gvisor
  containers:
  - name: nginx
    image: nginx
  nodeName: asari
EOF

cat > /etc/containerd/runsc.toml <<EOF
log_path = "/var/log/runsc/%ID%/shim.log"
log_level = "debug"
binary_name = "/usr/bin/containerd-shim-runsc-v1"
[runsc_config]
  debug = "true"
  debug-log = "/var/log/runsc/%ID%/gvisor.%COMMAND%.log"
  #nvproxy = "true"
EOF

cat > /var/lib/rancher/k3s/agent/etc/containerd/config.toml.tmpl <<EOF
  # runsc runtime
  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
    runtime_type = "io.containerd.runc.v2"
  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runsc]
    runtime_type = "io.containerd.runsc.v1"
    [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runsc.options]
      TypeUrl = "io.containerd.runsc.v1.options"
      ConfigPath = "/etc/containerd/runsc.toml"
      BinaryName = "/usr/local/bin/containerd-shim-runsc-v1"


EOF
