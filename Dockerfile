# ==================
# 1. Builder Step
# ==================

FROM golang:1.23-alpine3.20 as builder

RUN apk upgrade && apk update && \
    apk add libcap parted qemu qemu-img qemu-system-x86_64 \
    file multipath-tools e2fsprogs

WORKDIR /app

#COPY ["./tests/system/go.sum", "./tests/system/go.mod", "."]
#RUN go mod download

COPY "./artifacts/" /app/artifacts/
COPY "./scripts/" /app/scripts/
COPY "./tests/" /app/tests/

# Set capabilities
RUN setcap cap_sys_admin,cap_dac_override+ep /usr/bin/qemu-img; \
    setcap cap_sys_admin+eip /usr/sbin/parted; \
    setcap cap_sys_admin+eip /usr/sbin/kpartx; \
    setcap cap_sys_admin+eip /sbin/mkfs.ext4

RUN ls -allht

#WORKDIR /app/tests/system/
WORKDIR /app/scripts/

RUN printf "\n===== Entering scripts directory ======\n\n"
RUN ls -allht
#RUN go get
#RUN go mod tidy
RUN chmod +x ./squashed.sh && \
    . ./squashed.sh

ENTRYPOINT ["/bin/sh"]


# ======================
# 2. Relay Step
#
# Get only test results #
# ======================
FROM alpine:3.20 as relay

RUN apk upgrade && apk add file

WORKDIR /app

COPY --from=builder /app/scripts/output.iso .

# set command to be executed when the container starts
ENTRYPOINT ["/bin/sh", "-c"]

# set argument to be fed to the entrypoint
CMD ["file", "/app/output.iso" && "ls", "-allhtr" "/app/output.iso"]
