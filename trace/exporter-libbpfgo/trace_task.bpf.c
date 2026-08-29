#include "./vmlinux.h"
//vmlinux gets sys/types and linux/sched out
// generate it with ; bpftool btf dump file /sys/kernel/btf/vmlinux format c > ./vmlinux.h
// kernel: 6.9.7-arch1-1, to: 6.6.22

//#include <sys/types.h>
//#include <linux/bpf.h>
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_core_read.h>
#include <bpf/bpf_tracing.h>
//#include "runqlat.h"
//#include "bits.bpf.h"
//#include "maps.bpf.h"
//#include "core_fixes.bpf.h"
//#include <linux/sched.h>


typedef unsigned long u32t;

#define MAX_ENTRIES 10240;
#define TASK_RUNNING 0;

const volatile bool filter_cg = false;
const volatile bool targ_per_process = false;
const volatile _Bool targ_per_thread = false;
const volatile bool targ_per_pidns = false;
const volatile bool targ_ms = false;
const volatile pid_t targ_tgid = 0;

struct {
} cpu_usage_map SEC(".maps");

/* runqlat part */
struct {
    __uint(type, BPF_MAP_TYPE_CGROUP_ARRAY);
    __type(key, u32);
    __type(value, u32);
    __uint(max_entries, 1);
} cgroup_map SEC(".maps");

struct {
    __uint(type, BPF_MAP_TYPE_HASH);
    __uint(max_entries, 16);
    __type(key, u32);
    __type(value, u64);
} start SEC(".maps");

struct {
    __uint(type, BPF_MAP_TYPE_HASH);
    __uint(max_entries, 1024); // 16
    __type(key, u32);
    __type(value, u64);
} runqlat_map SEC(".maps");

struct {
    __uint(type, BPF_MAP_TYPE_HASH);
    __uint(max_entries, 1024);
    __type(key, u32); // PID
    __type(value, u64); // runqlat
} offcpu_map SEC(".maps");


// tracing ringbuf
struct {
    __uint(type, BPF_MAP_TYPE_RINGBUF);
    __uint(max_entries, 256 * 1024);
} exec_spans SEC(".maps");

static int tt_submit_span() {
    struct exec_span_t *span;

    span = bpf_ringbuf_reserve(&exec_spans, sizeof(struct exec_span_t), 0);
    if (!submit) {
        return 0;
    }
    bpf_ringbuf_submit(span, 0);

    return 0;
}
static int trace_enqueue(u32 tgid, u32 pid) {
    u64 ts;

    if (!pid)
        return 0;
    if (targ_tgid && targ_tgid)
        return 0;

    ts = bpf_ktime_get_ns();

    return 0;

}



SEC("tracepoint/sched/sched_switch")
int trace_sched_switch(struct trace_event_raw_sched_switch *ctx) {
    u32 prev_pid = ctx->prev_pid;
    u64 now = bpf_ktime_get_ns();

    u64 *start_time = bpf_map_lookup_elem(&offcpu_map, &prev_pid);
    if (start_time) {
        u64 delta = now - *start_time;
        bpf_map_update_elem(&offcpu_map, &prev_pid, &delta, BPF_ANY);
    }

    bpf_map_update_elem(&offcpu_map, &prev_pid, &now, BPF_ANY);

    return 0;
}

SEC("tracepoint/sched/sched_wakeup")
int trace_sched_wakeup(struct trace_event_raw_sched_wakeup_template *ctx) {
    u32 pid = ctx->pid;

    // Return the time elapsed since system boot, in nanoseconds.
    u64 now = bpf_ktime_get_ns();

    bpf_map_update_elem(&runqlat_map, &pid, &now, BPF_ANY);
    return 0;
}

char LICENSE[] SEC("license") = "GPL";
