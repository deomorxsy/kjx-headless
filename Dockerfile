# ==================
# 1. Builder Step
# ==================

FROM alpine:3.20 as builder

RUN <<"EOF"
apk upgrade && apk update && \
apk add python3 musl-dev iasl \
    sparse xen-dev sphinx ninja git make bash fuse3-dev && \
mkdir -p downloads && \
cd downloads/ && \
wget https://download.qemu.org/qemu-9.1.0.tar.bz2 && \
tar -xvf qemu-9.1.0.tar.bz2 && \
cd qemu-9.1.0/ && \
./configure --enable-fuse && \
make
EOF

ENTRYPOINT ["/bin/sh", "-c"]

# ==================
# 2. relay step
# ==================
FROM alpine:3.20 as relay

WORKDIR /app

COPY "./artifacts/" /app/artifacts/
COPY "./scripts/" /app/scripts/
COPY "./tests/" /app/tests/
COPY --from=builder "/bin/qemu*" /bin/

RUN ls -allht

RUN printf "\n===== Currently on /app directory ======\n\n"
RUN chmod +x /app/scripts/squashed.sh
RUN ls -allht

# set command to be executed when the container starts
ENTRYPOINT ["/bin/sh", "-c"]

# set argument to be fed to the entrypoint
CMD ["apk upgrade && apk update && \
    apk add libcap parted device-mapper fuse-overlayfs qemu qemu-img qemu-system-x86_64 \
        file multipath-tools e2fsprogs xorriso && \
    setcap cap_sys_admin,cap_dac_override+eip $(readlink -f $(which qemu-img)) && \
    setcap cap_sys_admin+eip $(readlink -f $(which parted)) && \
    setcap cap_sys_admin,cap_dac_override,cap_dac_read_search+eip $(readlink -f $(which kpartx)) && \
    setcap cap_sys_admin+eip $(readlink -f $(which mkfs.ext4)) && \
    setcap cap_sys_admin,cap_dac_override+ep $(readlink -f $(which losetup)) && \
    . /app/scripts/squashed.sh"]

