#!/bin/sh


# Create runtime class for Kata Containers
cat <<EOF | tee rootfs/etc/runit/runsvdir/kata/kataRC.yaml
# RuntimeClass is defined in the node.k8s.io API group
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  # The name the RuntimeClass will be referenced by.
  # RuntimeClass is a non-namespaced resource.
  name: kata
# The name of the corresponding CRI configuration
handler: kata
EOF

cat << EOF | tee nginx-kata.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-kata
spec:
  runtimeClassName: kata
  containers:
  - name: nginx
    image: nginx

EOF



sed -i 's/runtimeClassName: kata/runtimeClassName: youki/' ./deploy/k8s/deployment.yaml
sed '/spec:/a \  runtimeClassName: kata' ./deploy/k8s/deployment.yaml

#cat << EOF | tee kjx-kata.yaml
#apiVersion: v1
#kind: Pod
#metadata:
#  name: kjx-kata
#spec:
#  runtimeClassName: kata
#  containers:
#  - name: kjx-build
#    image: kjx_linux_x64:01
#
#EOF

cat << EOF | tee rootfs/etc/runit/runsvdir/kata/kubectl.yaml
# create pod
sudo -E kubectl apply -f ./nginx-kata.yaml

# check pod state
sudo -E k3s kubectl get pods -n kjx-kata

# check type-1 vmm (hypervisor) state
#ps aux | grep qemu
pgrep -l qemu
EOF

delete_pod() {
    sudo -E k3s kubectl delete -f nginx-kata.yaml
}

