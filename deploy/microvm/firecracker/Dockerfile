# FROM alpine:3.22 AS builder
# FROM rust:1.90.0-alpine3.20 as builder
FROM golang:1.24-alpine3.22 AS builder

ENV PATH="/usr/lib/go-1.23/bin:$PATH"
ENV PATH="/usr/lib/go-1.24/bin:${PATH}"

ARG PATH="/usr/lib/go-1.23/bin:$PATH"
ARG PATH="/usr/lib/go-1.24/bin:${PATH}"

# user management
ENV SANDBOX_USER="firecontainerd"
ARG SANDBOX_USER="firecontainerd"

ARG GIT_CONTAINERFILE_HASH
ENV GIT_CONTAINERFILE_HASH=${GIT_COMPOSE_SHA}

WORKDIR /app/
COPY ./scripts/sandbox/firecracker-startup.sh /app/scripts/

RUN <<EOF

# Set dependencies
apk upgrade && apk update && \
    apk add git make curl

# Set dependencies from [edge] branch
(
cat <<HMM
http://dl-cdn.alpinelinux.org/alpine/edge/main
http://dl-cdn.alpinelinux.org/alpine/edge/community
http://dl-cdn.alpinelinux.org/alpine/edge/testing
HMM
) > /etc/apk/repositories

apk add e2fsprogs bc util-linux gnupg device-mapper

EOF

WORKDIR /app
RUN <<EOF

export PATH="/usr/lib/go-1.24/bin:${PATH}"

SANDBOX_USER=firecontainerd

# Create user and group
addgroup -g 1000 -S "${SANDBOX_USER}" && \
adduser -s /bin/sh -u 1000 -G "${SANDBOX_USER}" \
    -h "/home/${SANDBOX_USER}" -D "${SANDBOX_USER}" && \

# Certify it will have the correct user:group permissions
chown -R ${SANDBOX_USER}:${SANDBOX_USER} /home/${SANDBOX_USER}

EOF


# su "${SANDBOX_USER}" -c "
#
# MODE="build" . ./scripts/firecracker-startup.sh
# "
#
# ls -allhtr
WORKDIR "/home/${SANDBOX_USER}/app"

RUN <<EOF

if ! (git clone https://github.com/firecracker-microvm/firecracker-containerd.git); then
    echo "|> Error: could not clone the firecracker-containerd repository. Exiting now..."
    return 1
    fi
    echo "|> Sucessfully cloned the firecracker-containerd repository. Proceeding..."

cd ./firecracker-containerd/ || return
# make

# Set firecracker-containerd directories
SNAPSHOTTER_BIN_DIR="/etc/firecracker-containerd"
ALTERNATE_STORAGE_DIR="/var/lib/firecracker-containerd/containerd"
SHIM_BASE_DIR="/var/lib/firecracker-containerd"
# Set device mapper thin pool
DEVMAPPER_DIR="/var/lib/firecracker-containerd/snapshotter/devmapper"
DEVMAPPER_POOL="fc-dev-thinpool"

# Create paths
mkdir -p "${SNAPSHOTTER_BIN_DIR}"
mkdir -p "${ALTERNATE_STORAGE_DIR}"
mkdir -p "${SHIM_BASE_DIR}"
mkdir -p "${DEVMAPPER_DIR}"


(
cat <<EOF
version = 2
disabled_plugins = ["io.containerd.grpc.v1.cri"]
root = "/var/lib/firecracker-containerd/containerd"
state = "/run/firecracker-containerd"
[grpc]
  address = "/run/firecracker-containerd/containerd.sock"
[plugins]
  [plugins."io.containerd.snapshotter.v1.devmapper"]
    pool_name = "fc-dev-thinpool"
    base_image_size = "10GB"
    root_path = "/var/lib/firecracker-containerd/snapshotter/devmapper"

[debug]
  level = "debug"
EOF
) | tee "${SNAPSHOTTER_BIN_DIR}"/config.toml



EOF

FROM alpine:3.22 AS empty

COPY --from=builder /root/artifacts/sources/firecracker-core.tar.gz .

RUN echo "done!!!"

ENTRYPOINT ["/bin/sh"]
