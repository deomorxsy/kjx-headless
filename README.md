### kjx-headless // WIP
> POC for a custom headless LFS distro setup, deploy and monitoring

[![initramfs](https://github.com/deomorxsy/kjx-headless/actions/workflows/ramdisk-builder.yml/badge.svg)](https://github.com/deomorxsy/kjx-headless/actions/workflows/ramdisk-builder.yml)
[![bzImage](https://github.com/deomorxsy/kjx-headless/actions/workflows/kernel-builder.yml/badge.svg)](https://github.com/deomorxsy/kjx-headless/actions/workflows/kernel-builder.yml)
[![parse.bpf.c](https://github.com/deomorxsy/kjx-headless/actions/workflows/bee.yml/badge.svg)](https://github.com/deomorxsy/kjx-headless/actions/workflows/bee.yml)
[![iso9660](https://github.com/deomorxsy/kjx-headless/actions/workflows/ci.yml/badge.svg)](https://github.com/deomorxsy/kjx-headless/actions/workflows/ci.yml)

Taking up from where [eulab-poc](https://github.com/deomorxsy/eulab-poc) left ;D

This proof-of-concept monorepo gathers concepts from several constrained systems to create a *NIX Distro, Linux-based. Composed by Busybox/LFS, it applies CI/CD for infrastructure automation. Aimed to explore the performance of virtualized environments.

Check the [Gitlab mirror]() for an example using Jenkins instead of Github Actions.


eBPF envp vs argp, sec, kprobe
```
          ---------
      ---|program.c|---
      |   ---------   |
      v               v
    -------          -------------
   | eBPF  |   IPC  | k3s service |
   | child |========| child       |
    -------          -------------
```

System/Integration [Tests](https://bats-core.readthedocs.io/) use bats-core and leverages Linux Namespaces API to interact with an ext4 filesystem:
1. create userns
2. create mountns through unshare
3. bound userns to the newly created mountns
4. setup a tmpfs (RAM-based filesystem for fast access)
5. assert test
6. clean artifacts
