#!/bin/sh

#where $1 is the ROOTFS_PATH
if [ "$1" = "./artifacts/qcow2-rootfs" ]; then
cat <<EOF | tee rootfs/etc/runit/runsvdir/youki/youkiRC.yaml
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: youki
handler: youki
---
EOF
fi


cat <<EOF | tee ./deploy/k8s/youki.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kjx-deployment
spec:
  selector:
    matchLabels:
      app: kjx
  replicas: 1
  template:
    metadata:
      labels:
        app: kjx
    spec:
      runtimeClassName: youki
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
EOF
