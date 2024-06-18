#!/bin/sh

ARCH=$(uname -m | sed 's/x86_64/x86/')
bpftool btf dump file /sys/kernel/btf/vmlinux format c > "./artifacts/vmlinux/$ARCH/vmlinux.h"
