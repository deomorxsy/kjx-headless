FROM alpine:3.20 as builder

WORKDIR /app

RUN apk upgrade && apk update && \
    apk add parted qemu qemu-img qemu-system-x86_64 \
    file multipath-tools e2fsprogs wget=1.24.5-r0
    #file kpartx losetup=2.40.2-r0 e2fsprogs=1.47.1-r0 blkid=2.40.2-r0 umount=2.40.2-r0 \


WORKDIR /app

COPY ["./artifacts/", "./scripts/", "."]

ENTRYPOINT ["/bin/sh"]
RUN ./scripts/fuse-blkexp.sh "./artifacts/foo.img"


FROM alpine:3.20 as relay

WORKDIR /app
COPY --from-builder=./artifacts/image.iso
