#!/bin/sh
#
# toolchain


# linker
cargo install bpf-linker

# use the xtask scaffolding/polyfill tool
# to build for both userspace and eBPF
cargo xtask build-ebpf

#Build Userspace
cargo build

#Build eBPF and Userspace
cargo xtask build

# Run
RUST_LOG=info cargo xtask run -C ./trace/ayaya/
