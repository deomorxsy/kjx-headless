# ==================
# 1. Builder Step
# ==================

FROM alpine:3.20 as builder

WORKDIR /app

COPY "./artifacts/" /app/artifacts/
COPY "./scripts/" /app/scripts/
COPY "./tests/" /app/tests/

RUN ls -allht

RUN printf "\n===== Currently on /app directory ======\n\n"
RUN chmod +x /app/scripts/squashed.sh
RUN ls -allht

# set command to be executed when the container starts
ENTRYPOINT ["/bin/sh", "-c"]

# set argument to be fed to the entrypoint
CMD ["apk upgrade && apk update && \
    apk add libcap parted qemu qemu-img qemu-system-x86_64 file multipath-tools e2fsprogs && \
    setcap cap_sys_admin,cap_dac_override+eip $(readlink -f $(which qemu-img)) && \
    setcap cap_sys_admin+eip $(readlink -f $(which parted)) && \
    setcap cap_sys_admin+eip $(readlink -f $(which kpartx)) && \
    setcap cap_sys_admin+eip $(readlink -f $(which mkfs.ext4)) && \
    . /app/scripts/squashed.sh"]

