#include "vmlinux.h"
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_core_read.h>
//#include <maps.bpf.h>
//

int counter = 0;

SEC("xdp")
int hello(void *ctx) {
    bpf_printk("hullo %d", counter);
    counter++;
    return XDP_PASS;
}

char LICENSE[] SEC("license") = "Dual BSD/GPL";
