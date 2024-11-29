#!/bin/sh

TARGET_TGID=$(pgrep firefox)

sudo bpftrace -e '

tracepoint:sched {
    @start[args->dev] = nsecs;
    @start[tid] = counts
}

tracepoint:sched:sched_switch
/has_key(@start, tid)

args->prev_pid == "$TARGET_TGID" || args->next_pid == "$TARGET_TGID"/
{
  printf("CPU %d: Switched from %s (PID: %d, TGID: %d) to %s (PID: %d, TGID: %d)\n",
    cpu, args->prev_comm, args->prev_pid, args->prev_tgid,
    args->next_comm, args->next_pid, args->next_tgid);
}
' | tee trace.firefox.data


