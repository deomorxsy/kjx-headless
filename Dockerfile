FROM alpine:3.18 as relay

WORKDIR /app

RUN apk upgrade && apk update && \
    apk add parted qemu qemu-img qemu-system-x86_64 \
    file kpartx


