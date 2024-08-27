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

# unit test
RUN go test -v > /app/test_result.txt; getcap /usr/sbin/parted >> /app/test_result.txt && cat /app/test_result.txt

# coverage
RUN go test -coverprofile=/app/artifacts/coverage_go.out || cat /app/artifacts/coverage_go.out


ENTRYPOINT ["/bin/sh"]


# ======================
# 2. Relay Step
#
# Get only test results #
# ======================
FROM alpine:3.20 as relay

WORKDIR /tests

COPY --from=builder /app/test_result.txt .
COPY --from=builder /app/artifacts/coverage_go.out .

# set command to be executed when the container starts
ENTRYPOINT ["/bin/sh", "-c"]

# set argument to be fed to the entrypoint
CMD ["printf \"===== UNIT TEST =====\\n\\n\" && cat /tests/test_result.txt && printf \"\\n\\n===== FUZZA =======\\n\\n\" && cat /tests/coverage_go.out"]
