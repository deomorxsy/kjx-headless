Some instructions from [aya-template](https://github.com/aya-rs/aya-template):

setup
```sh
; cargo install bpf-linker
; cargo xtask build-ebpf
```
Build Userspace
```sh
; cargo build
```

Build eBPF and Userspace
```sh
; cargo xtask build
```

Run
```sh
; RUST_LOG=info cargo xtask run
```
