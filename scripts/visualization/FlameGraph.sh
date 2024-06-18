#!/bin/sh
#

sudo bpftrace -e 'kprobe:vfs_* /pid == 69865/ { @[ustack, comm, func] = count(); }' > ./artifacts/stacktraces/out.stackcount.txt

#
./assets/FlameGraph/flamegraph.pl \
    --hash \
    --bgcolors=grey \
    < ./artifacts/stacktraces/out.stackcount.txt \
    > ./artifacts/flamegraphs/out.stackcount.svg

