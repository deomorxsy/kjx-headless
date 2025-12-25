### trace!
> "Why implementing in this language?" - Why not?


### aya-rs's rust
> This which does not depends on LLVM.

As explained on [lockc's discussion forum](https://github.com/lockc-project/lockc/issues/49#issuecomment-971809300):
- it has no direct dependency on LLVM aside from the internal LLVM used by rust
- bindgen/FFI is not needed in order to share data structures between userspace and BPF code; its native.
- bindgen/FFI is needed for bindings to kernel structures but hidden on the aya-rs API for developers

### bpftrace's awk/c syntax
> a high-level tracing language for Linux based on the awk programming language.

It was inspired by the syntax of awk, C and tracers from Solaris and FreeBSD such as Dtrace and SystemTAP. It depends on BCC and LLVM but a trade-off lies on its capacity for pretty-printing through code helpers.

### Ftrace's shellscript
> through ```/sys/kernel/debug/tracing/events``` it is one of the interfaces alongside perf for the Tracing subsystem used by eBPF.
- [libbpf CO-RE]() attempts to statically compile the BTF debug information into ELF binaries for older kernels.


#### jvm languages:
> incoming: java, clojure and kotlin.
- wasm: this directory was inspired by eunomia's wasm-bpf, the [zbpf](https://github.com/tw4452852/zbpf/) library, and overall deno and typescript ecosystem.
