#!/usr/bin/bash

bpftool btf dump file /sys/kernel/btf/vmlinux format c > ./artifacts/vmlinux.h
