#!/bin/sh

podman run --rm -it \
    -v ./trace/libbpf-core/:/app/:ro \
    --entrypoint=/bin/sh \
    alpine:3.20

# busybox does not have apk. resort to copy dependencies between the root filesystem instead if needed
# busybox:1.36.1-musl

