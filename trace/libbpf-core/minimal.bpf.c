//#include <linux/bpf.h>
#include "../vmlinux.stub.c"
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_core_read.h>
#include "base.h"

char LICENSE[] SEC("license") = "Dual BSD/GLP";

// ringbuf map
struct {
    __uint(type, BPF_MAP_TYPE_RINGBUF)
};
