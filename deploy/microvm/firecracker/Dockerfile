# FROM alpine:3.22 AS builder
# FROM rust:1.90.0-alpine3.20 as builder
FROM golang:1.24-alpine3.22 AS builder

ENV PATH="/usr/lib/go-1.23/bin:$PATH"
ENV PATH="/usr/lib/go-1.24/bin:${PATH}"

ARG GIT_CONTAINERFILE_HASH
ENV GIT_CONTAINERFILE_HASH=${GIT_COMPOSE_SHA}

WORKDIR /app/
COPY ./scripts/sandbox/firecracker-startup.sh /app/scripts/

RUN <<EOF


# Set dependencies
apk upgrade && apk update && \
    apk add git make curl

# fzf file vim

mkdir -p /app && cd /app || return



export PATH="/usr/lib/go-1.24/bin:${PATH}"

mkdir -p /app/ && cd /app/ || return

(
cat <<HMM
http://dl-cdn.alpinelinux.org/alpine/edge/main
http://dl-cdn.alpinelinux.org/alpine/edge/community
http://dl-cdn.alpinelinux.org/alpine/edge/testing
HMM
) > /etc/apk/repositories

apk add e2fsprogs bc util-linux gnupg device-mapper

SANDBOX_USER=firecontainerd


# Create user and group
addgroup -g 1000 -S "${SANDBOX_USER}" && \
adduser -s /bin/sh -u 1000 -G "${SANDBOX_USER}" \
    -h "/home/${SANDBOX_USER}" -D "${SANDBOX_USER}" && \

# Certify it will have the correct user:group permissions
chown -R ${SANDBOX_USER}:${SANDBOX_USER} /home/${SANDBOX_USER}  && \

cd /home/${SANDBOX_USER}/app || return && \

# su "${SANDBOX_USER}" -c "
#
# MODE="build" . ./scripts/firecracker-startup.sh
# "
#
# ls -allhtr
git clone https://github.com/firecracker-microvm/firecracker-containerd.git
cd firecracker-containerd/ || return
make



EOF

FROM alpine:3.22 AS empty

COPY --from=builder /root/artifacts/sources/firecracker-core.tar.gz .

RUN echo "done!!!"

ENTRYPOINT ["/bin/sh"]
