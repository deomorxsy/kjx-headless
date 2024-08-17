#!/bin/sh

ARCH=$(uname -m | sed 's/x86_64/x86/')
#bpftool btf dump file /sys/kernel/btf/vmlinux format c > "./artifacts/vmlinux/$ARCH/vmlinux.h"
#GENERATE_BTF=$(bpftool btf dump file /sys/kernel/btf/vmlinux format c > "./vmlinux.h")

touch ./artifacts/vmlinux/x86/vmlinux.h
bpftool btf dump file /sys/kernel/btf/vmlinux format c > "./vmlinux.h"
diff -Naru ./artifacts/vmlinux/x86/vmlinux.h ./vmlinux.h > ./artifacts/vmlinux/x86/vmlinux.h.patch
rm ./vmlinux.h && rm ./artifacts/vmlinux/x86/vmlinux.h


