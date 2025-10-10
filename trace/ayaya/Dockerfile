# FROM alpine:3.20 as builder
FROM rust:1.90.0-alpine3.20 as builder

ARG AYA_USER
ENV AYA_USER=aya

ENV RUSTUP_HOME=/home/aya/rustup
ENV CARGO_HOME=/home/aya/cargo
ENV RUST_VERSION=1.90.0
ENV RUSTUP_VERSION=1.28.2

# create user and group
RUN <<EOF
addgroup -g 1000 -S "${AYA_USER}" && \
    adduser -s /bin/sh -u 1000 -G "${AYA_USER}" \
        -h "/home/${AYA_USER}" -D "${AYA_USER}"
EOF

# Switch to the custom user
USER ${AYA_USER}

# Set workdir
WORKDIR /home/${AYA_USER}

RUN <<EOF

apk upgrade && apk update && \
    apk add musl-dev clang-dev llvm

apk upgrade && apk update && \
    apk add clang llvm lld libelf \
        zlib-dev libc-dev pkgconf \
        make ca-certificates


RUSTUP_HOME=/home/aya/rustup
CARGO_HOME=/home/aya/cargo
RUST_VERSION=1.90.0
RUSTUP_VERSION=1.28.2

EOF



RUN <<EOF

# stable rust toolchain
# rustup toolchain install stable

# nightly rust toolchain
rustup toolchain install nightly \
    && rustup component add rust-src --toolchain nightly \
    && rustup default nightly \
    && rustup override set ${RUST_VERSION}

EOF

WORKDIR /app
#COPY ./trace/ayaya/ /app/
# Copy manifests first for better layer caching
COPY ./trace/ayaya/Cargo.toml Cargo.lock ./
COPY ./trace/ayaya/ayaya/Cargo.toml ./ayaya/
COPY ./trace/ayaya/ayaya-common/Cargo.toml ./ayaya-common/
COPY ./trace/ayaya/ayaya-ebpf/Cargo.toml ./ayaya-ebpf/

# Fetch dependencies
RUN cargo fetch

RUN <<EOF

# Setup bpf-linker
cargo install bpf-linker
cargo xtask build-ebpf

# Build Userspace
cargo build

# Build eBPF and Userspace
cargo xtask build

# Run app
RUST_LOG=info cargo xtask run 2>&1 > /app/cargotest_results.txt

# Run XDP app
#RUST_LOG=info cargo xtask run -- --iface <network_interface>

EOF

# set command to be executed when the container starts
ENTRYPOINT ["/bin/sh", "-c"]

# set argument to be fed to the entrypoint
CMD ["echo build finished"]

# ======== runtime
FROM alpine:3.20 as relay

WORKDIR /app

COPY --from=builder /app/cargotest_results.txt /app/

# set command to be executed when the container starts
ENTRYPOINT ["/bin/sh", "-c"]

# set argument to be fed to the entrypoint
CMD ["cat /app/cargotest_results.txt"]

#CMD ["apk upgrade && apk update && \
#    apk add --no-cache curl ca-certificates gcc &&
#    RUST_LOG=info cargo xtask run "]
