#!/bin/sh

# simply runs the release binary for ebpf_exporter
# PS: note that to visualize it with grafana you will
#     need the prometheus scrape server also running.

sudo ./ebpf_exporter.x86_64 \
    --config.dir=./sample/examples/ \
    --config.names=sched-trace \
    --debug
