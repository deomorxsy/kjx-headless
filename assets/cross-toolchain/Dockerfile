ARG GIT_CONTAINERFILE_HASH=${GIT_COMPOSE_SHA}

FROM busybox:1.36.1-musl as builder
# just to get the statically compiled files


FROM alpine:3.18 as relay

ARG GIT_CONTAINERFILE_HASH
ENV GIT_CONTAINERFILE_HASH=${GIT_COMPOSE_SHA}

WORKDIR /tmp/cross-toolchain/

#RUN rm -rf /tmp/cross-toolchain/

FROM alpine:3.18 as packer

WORKDIR /app/

COPY --from=relay / /app/newroot/

RUN chroot /app/newroot/

RUN chmod +x ./ramdisk/init && \
    cd ./ramdisk || return && \
    find . -print0 | busybox cpio --null -ov --format=newc | gzip -9 > ../initramfs.cpio.gz && \
    cd - || return


#FROM scratch as empty
FROM alpine:3.18 as empty

COPY --from=packer /app/initramfs.cpio.gz .

ENTRYPOINT ["/bin/sh"]
