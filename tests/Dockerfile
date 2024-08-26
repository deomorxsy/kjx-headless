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
RUN setcap cap_sys_admin,cap_dac_override+ep /usr/bin/qemu-img \
    && setcap cap_sys_admin+ep /usr/sbin/parted \
    && setcap cap_sys_admin+ep /usr/sbin/kpartx

#COPY ["./artifacts/", "./scripts/", "./tests/", "."]
#"./tests/", "."]

RUN ls -allht
#&& cd /app/tests/system/ || return

WORKDIR /app/tests/system/

RUN printf "\n===== Entering test directory ======\n\n"
RUN ls -allht
RUN go get
RUN go mod tidy
RUN go test
RUN go test -v > /app/test_result.txt


ENTRYPOINT ["/bin/sh"]


# ======================
# 2. Relay Step
#
# Get only test results #
# ======================
FROM alpine:3.20 as relay

WORKDIR /tests

COPY --from=builder /app/test_result.txt .

CMD cat /app/test_result.txt
ENTRYPOINT ["/bin/sh"]
