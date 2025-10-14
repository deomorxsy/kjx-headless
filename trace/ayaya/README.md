Some instructions from [aya-template](https://github.com/aya-rs/aya-template).

Changelog
- PS: The xtask template workflow is a pattern for rust project automation. It seems until [oct 31, 2024](https://github.com/aya-rs/aya-template/commit/b1d6fb31eae96c63b66981c995f4013c89d40dfb) it was the default way to build aya-rs with the [aya-template](https://github.com/aya-rs/aya-template). As of 14-oct-2025 it is now deprecated.

## Prerequisites

1. stable rust toolchains: `rustup toolchain install stable`
1. nightly rust toolchains: `rustup toolchain install nightly --component rust-src`
1. (if cross-compiling) rustup target: `rustup target add ${ARCH}-unknown-linux-musl`
1. (if cross-compiling) LLVM: (e.g.) `brew install llvm` (on macOS)
1. (if cross-compiling) C toolchain: (e.g.) [`brew install filosottile/musl-cross/musl-cross`](https://github.com/FiloSottile/homebrew-musl-cross) (on macOS)
1. bpf-linker: `cargo install bpf-linker` (`--no-default-features` on macOS)

setup
```sh
; cargo install bpf-linker
```
Build eBPF and Userspace
```sh
; cargo build
```


Run
```sh
; RUST_LOG=info cargo xtask run
```
