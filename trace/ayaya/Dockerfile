# FROM alpine:3.20 as builder
FROM rust:1.90.0-alpine3.20 as builder

ARG AYA_USER
ENV AYA_USER=aya

ENV RUSTUP_HOME=/home/aya/rustup
ENV CARGO_HOME=/home/aya/cargo
ENV RUST_VERSION=1.90.0
ENV RUSTUP_VERSION=1.28.2
ENV LOCAL_BIN="/home/aya/cargo/bin"

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

#apk upgrade && apk update && \
#    apk add musl-dev clang-dev llvm

# add musl-dev to get the crti shared object
apk upgrade && apk update && \
    apk add musl-dev lld libelf \
        zlib-dev libc-dev pkgconf \
        make ca-certificates

(
cat <<HMM
http://dl-cdn.alpinelinux.org/alpine/edge/main
http://dl-cdn.alpinelinux.org/alpine/edge/community
http://dl-cdn.alpinelinux.org/alpine/edge/testing
HMM
) > /etc/apk/repositories

apk add llvm21-dev clang


RUSTUP_HOME=/home/aya/rustup
CARGO_HOME=/home/aya/cargo
RUST_VERSION=1.90.0
RUSTUP_VERSION=1.28.2
LOCAL_BIN="/home/aya/cargo/bin"

EOF

RUN <<EOF

# stable rust toolchain
# rustup toolchain install stable
mkdir -p /home/aya/cargo/bin/

cp /usr/local/cargo/bin/rustup /home/aya/cargo/bin/

LOCAL_BIN="/home/aya/cargo/bin"
/bin/ln -sf "${LOCAL_BIN}"/rustup cargo
/bin/ln -sf "${LOCAL_BIN}"/rustup cargo-clippy
/bin/ln -sf "${LOCAL_BIN}"/rustup cargo-fmt
/bin/ln -sf "${LOCAL_BIN}"/rustup cargo-miri
/bin/ln -sf "${LOCAL_BIN}"/rustup clippy-driver
/bin/ln -sf "${LOCAL_BIN}"/rustup rls
/bin/ln -sf "${LOCAL_BIN}"/rustup rust-analyzer
/bin/ln -sf "${LOCAL_BIN}"/rustup rust-gdb
/bin/ln -sf "${LOCAL_BIN}"/rustup rust-gdbgui
/bin/ln -sf "${LOCAL_BIN}"/rustup rust-lldb
/bin/ln -sf "${LOCAL_BIN}"/rustup rustc
/bin/ln -sf "${LOCAL_BIN}"/rustup rustdoc
/bin/ln -sf "${LOCAL_BIN}"/rustup rustfmt

# nightly rust toolchain
rustup toolchain install nightly \
    && rustup component add rust-src --toolchain nightly \
    && rustup default nightly \
    && rustup override set ${RUST_VERSION}

EOF

WORKDIR /app
#COPY ./trace/ayaya/ /app/
# Copy manifests first for better layer caching
COPY ./trace/ayaya/Cargo.toml ./
COPY ./trace/ayaya/Cargo.lock ./
COPY ./trace/ayaya/ayaya/Cargo.toml ./ayaya/
COPY ./trace/ayaya/ayaya-common/Cargo.toml ./ayaya-common/
COPY ./trace/ayaya/ayaya-ebpf/Cargo.toml ./ayaya-ebpf/

# Fetch dependencies
RUN cargo fetch

# Final build
RUN <<EOF

# Setup bpf-linker
cargo install bpf-linker
#cargo xtask build-ebpf

# Build Userspace
# cargo build

# Build eBPF and Userspace
#cargo xtask build

# Run app
# RUST_LOG=info cargo run 2>&1 > /app/cargotest_results.txt

# Run XDP app
#RUST_LOG=info cargo run -- --iface <network_interface>

EOF

# set command to be executed when the container starts
ENTRYPOINT ["/bin/sh", "-c"]

# set argument to be fed to the entrypoint
CMD ["echo build finished"]

# ======== runtime
# Fetch artifacts
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
