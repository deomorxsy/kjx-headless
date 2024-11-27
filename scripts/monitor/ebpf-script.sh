#!/bin/sh

LOCALDIR="$(pwd)"/../assets/ebpf_exporter/tracing

# if inside "./kjx-headless/sample"
if ! [ -d "$LOCALDIR" ]; then
    echo "Directory don't exist. Skipping..."

else

    echo "Directory found. Starting pipeline..."

    podman images | grep "cloudflare/ebpf_exporter" | awk '{print $3}'

    image_checker=$?

    if [ $image_checker -eq 0 ]; then
        image1=$(podman images | grep "cloudflare/ebpf_exporter" | awk '{print $3}')
    else
        image1="ghcr.io/cloudflare/ebpf_exporter:v2.4.0"
    fi

    sudo podman run --rm -it \
        --privileged \
        --net host \
        -e OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318 \
        -v "$LOCALDIR":/tracing \
         "$image1" \
        --config.dir=examples/ \
        --config.names=sched-trace


fi




