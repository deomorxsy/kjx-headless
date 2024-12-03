#!/bin/sh

sudo bpftrace -e '
tracepoint:syscalls:sys_exit_read* /pid == 8011/ {
    @ret = hist(args->ret);
}'

sudo bpftrace -e '
tracepoint:syscalls:sys_enter_* /pid == 8011/ {
    @ret = hist(args->ret);
}'

sudo bpftrace -e '
tracepoint:syscalls:sys_enter_* /pid == 8011/ {
    @entry_ts[tid] = nsecs;
}'

sudo bpftrace -e '
tracepoint:syscalls:sys_exit_* /pid == 8011/ {
    @exit_ts = nsecs;
    @latency = hist((@exit_ts - @entry_ts[tid]) / 1000);
    delete(@entry_ts[tid]);
}'
