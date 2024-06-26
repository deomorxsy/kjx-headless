.DEFAULT_GOAL := all

all: getvmlinux hello.bpf.o

hello.bpf.o: %.o: %.c
	clang \
		-target bpf \
		-I/usr/include/$(shell uname -m)-linux-gnu \
		-g \
		-O2 -c $< -o $@

getvmlinux:
	bpftool btf dump file /sys/kernel/btf/vmlinux format c > "./vmlinux.h"

load:
	bpftool prog load hello.bpf.o /sys/fs/bpf/hello

list:
	bpftool prog list --pretty | tail

dumpde: # dump before kernel rewrites
	llvm-objdump -d hello.bpf.o
	llvm-objdump -S hello.bpf.o

dumpar: # dump after kernel rewrites
	bpftool prog dump xlated name hello
