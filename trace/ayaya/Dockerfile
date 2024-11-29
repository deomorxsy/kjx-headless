FROM alpine:3.20 as builder



ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH \
    RUST_VERSION=1.82.0

RUN <<EOF
set -eux;
apkArch="$(apk --print-arch)";
case "$apkArch" in
    x86_64) rustArch='x86_64-unknown-linux-musl'; rustupSha256='1455d1df3825c5f24ba06d9dd1c7052908272a2cae9aa749ea49d67acbe22b47' ;;
    aarch64) rustArch='aarch64-unknown-linux-musl'; rustupSha256='7087ada906cd27a00c8e0323401a46804a03a742bd07811da6dead016617cc64' ;;
    *) echo >&2 "unsupported architecture: $apkArch"; exit 1 ;;
esac;
url="https://static.rust-lang.org/rustup/archive/1.27.1/${rustArch}/rustup-init";
wget "$url";
echo "${rustupSha256} *rustup-init" | sha256sum -c -;
chmod +x rustup-init;
./rustup-init -y --no-modify-path --profile minimal --default-toolchain $RUST_VERSION --default-host ${rustArch};
rm rustup-init;
chmod -R a+w $RUSTUP_HOME $CARGO_HOME;
rustup --version;
cargo --version;
rustc --version;

EOF


WORKDIR /app
COPY . /app/

RUN <<EOF

# stable rust toolchain
rustup toolchain install stable

# nightly rust toolchain
rust toolchain install nightly --component rust-src

# Setup bpf-linker
cargo install bpf-linker
cargo xtask build-ebpf

# Build Userspace
cargo build

# Build eBPF and Userspace
cargo xtask build

# Run app
RUST_LOG=info cargo xtask run 2>&1 > /app/cargotest_results.txt

EOF

# set command to be executed when the container starts
ENTRYPOINT ["/bin/sh", "-c"]

# set argument to be fed to the entrypoint
CMD ["echo build finished"]

# ======== runtime
FROM alpine:3.20 as relay

WORKDIR /app

COPY --from-builder=/app/cargotest_results.txt /app/

# set command to be executed when the container starts
ENTRYPOINT ["/bin/sh", "-c"]

# set argument to be fed to the entrypoint
CMD ["cat /app/cargotest_results.txt"]

#CMD ["apk upgrade && apk update && \
#    apk add --no-cache curl ca-certificates gcc &&
#    RUST_LOG=info cargo xtask run "]
