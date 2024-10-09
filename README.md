### kjx-headless // WIP
> POC for a custom headless LFS distro setup, deploy and monitoring

[![initramfs](https://github.com/deomorxsy/kjx-headless/actions/workflows/ramdisk-builder.yml/badge.svg)](https://github.com/deomorxsy/kjx-headless/actions/workflows/ramdisk-builder.yml)
[![bzImage](https://github.com/deomorxsy/kjx-headless/actions/workflows/kernel-builder.yml/badge.svg)](https://github.com/deomorxsy/kjx-headless/actions/workflows/kernel-builder.yml)
[![CI](https://github.com/deomorxsy/kjx-headless/actions/workflows/ci.yml/badge.svg)](https://github.com/deomorxsy/kjx-headless/actions/workflows/ci.yml)
[![unit-tests](https://github.com/deomorxsy/kjx-headless/actions/workflows/unit.yml/badge.svg)](https://github.com/deomorxsy/kjx-headless/actions/workflows/unit.yml)
[![coverage](https://github.com/deomorxsy/kjx-headless/actions/workflows/unit.yml/coverage.svg)](https://github.com/deomorxsy/kjx-headless/actions/workflows/coverage.yml)

[![libbpf](https://github.com/deomorxsy/kjx-headless/actions/workflows/bee.yml/badge.svg)](https://github.com/deomorxsy/kjx-headless/actions/workflows/bee.yml)
[![libbpfgo](https://github.com/deomorxsy/kjx-headless/actions/workflows/libbpfgo.yml/badge.svg)](https://github.com/deomorxsy/kjx-headless/actions/workflows/libbpfgo.yml)
[![ayaya](https://github.com/deomorxsy/kjx-headless/actions/workflows/ayaya.yml/badge.svg)](https://github.com/deomorxsy/kjx-headless/actions/workflows/ayaya.yml)



Taking up from where [eulab-poc](https://github.com/deomorxsy/eulab-poc) left ;D

This proof-of-concept monorepo gathers concepts from several [1] constrained systems to create a *NIX Distro, Linux-based. Composed by Busybox/LFS, it applies CI/CD for infrastructure automation. Aimed to explore the performance of virtualized environments.

Check the [Gitlab mirror]() for an example using Jenkins instead of Github Actions.


The entire boot flowchart, from kernel init scripts to k3s initialization:
```
                                          kernel
                                            |
                                           1|
      .--- /etc/runit/reboot ---.                    14
  ,---|            2            |<--- (runit-init) <---- init 0|6
  |   '--- /etc/runit/stopit ---'          |
  |                                 13     |
  '------------------------------------>  3|
                                 .-----> runit
                                 |         |
                                 |         |
                        .---<---------<----+-------->---------.
                        |        |         |                  |
                       4|        |        6|                10|
                     runit/1     |      runit/2            runit/3
                        |        |         |                  |
                       5|        |        7|                11|
                   start things  |     runsvdir              sv
                        |        |         |                  |
                        |        |        8|                  |
   +---------------+    '--->---'|       runsv         /var/service/*
   | Parent Process|             |         |                  |
   +---------------+<------------'         |                  |
       |                                   |                12|
       |1. Fork libbpf                     |             stop things
       |2. Fork k3s process                |                  |
       |                                   |                  |
       |3. Send signal SIGUSR1 to libbpf   |            send SIGTERM
       v                                   v                   v
   +--------------------+             +--------------------+   |
   | Child: libbpf      |             | Child: k3s Process |---'
   | Program            |             | Wait for SIGUSR2   |
   +--------------------+             +--------------------+
            ^                                    ^
            | 4. Wait for SIGUSR1                | 6. Wait for SIGUSR2
            | (self-loop)                        | (self-loop)
            v                                    v
   +--------------------+             +--------------------+
   | Start Monitoring   |------------>| Signal: Monitoring |
   +--------------------+             | Started            |
            |                         +--------------------+
            |                                    |
            |                                    |
            | 5. Send SIGUSR2 to k3s Process     |
            v                                    v
    +--------------------+             +--------------------+
    | Monitoring Active  |             | Start k3s Process  |
    +--------------------+             +--------------------+
      |                    ┌──────────────────────┘
      |                    │
      |   ┌─────────────── ▼ ───────────────────┐
      v   │       ┌──────────────┐              │
 +--------│-------│server process│------------+ │
 |        ▼       └──────────────┘            | │
 |   +----------+                             | │
 |   |supervisor|──┐      +-------+ ◄───────┐ | │        ┌──────────────┐
 |   +----------+  │      |flannel|--------┐| | │ +------│client process│----+
 |                 ▼      +-------+        || | │ |      └──────────────┘    |
 | +----+    +----------+                  || | │ |    +-------+             |
 | |kine|◄───|API-server| ◄-┐ +----------+ || | │ |    |flannel|──────┐      |
 | +----+    +----------+   └-|kube-proxy|◄┘| | │ |    +-------+      ▼      |
 |               ▲  ▲  ▲      +----------+  | | │ |          ▲   +----------+|
 | +----------+  │  │  │                    | | │ | +------+ |   |kube-proxy||
 | |controller|  |  |  |      +-------+     | | │ | |tunnel| └─┐ +----------+|
 | |manager   |──┘  |  └──────|kubelet|─────┘ | └───|proxy |◄┐ |             |
 | +----------+  +---------+  +-------+       |   | +------+ | └─────┐       |
 +---------------|scheduler|-----│------------+   |      ▲   └────┐  |       |
                 +---------+     │                |      └───── +-------+    |
                                 │                +-------------|kubelet|----+
            +----------+         │                              +-------+
            |containerd| ◄───────┘               +----------+        │
            +----------+                         |containerd|◄───────┘
               │                                 +----------+
               │   +---+                            │
               └─► |Pod|                            │   +---+
                   +---+                            └─► |Pod|
                                                        +---+
```

Unit and Integration tests use the go testing package with code coverage. Currently exploring fuzz tests. There is also a chore using [bats-core](https://bats-core.readthedocs.io/). The adopted strategy is composed by spinning up a container, setting permissions with libcap and
```
1. CommandExecutor (Strategy Pattern)
2. Options (Functional Options Pattern)
3. OptionsFactory (Abstract Factory Pattern)
4. CleanupStrategy (Strategy Pattern)
5. Runna (Dependency Injection)
6. Tests (Mocking/Dependency Injection)
7. Main (Composition Root)
```

and leverages Linux Namespaces API to interact with an ext4 filesystem:
1. create userns
2. create mountns through unshare
3. bound userns to the newly created mountns
4. setup a tmpfs (RAM-based filesystem for fast access)
5. assert test
6. clean artifacts

### References

[1] LFS, Sabotage, Alpine, Busybox OS, ALFS, PILFS, Cross Linux from Scratch, Embedded Linux from Scratch, Dragora Linux, Alpine Linux and Void Linux.

- [Alpine Wiki](https://wiki.alpinelinux.org/)
- [Sabotage](https://sabotage-linux.github.io/) && [devsonacid](https://sabotage-linux.neocities.org/blog/)
- [Buildroot manual](https://buildroot.org/downloads/manual/manual.pdf)
- [ALFS](https://www.linuxfromscratch.org/alfs/)
- [Cross Linux from Scratch](https://trac.clfs.org/)
- [Embedded Linux from Scratch](https://bootlin.com/doc/legacy/elfs/embedded_lfs.pdf)
- Dragora Linux [Handbook](http://www.dragora.org/download/web-handbook/) || [archive](https://archive.fo/FQekg)
- VoidLinux [docs](https://docs.voidlinux.org/)
- Alpine User [Handbook](https://docs.alpinelinux.org/user-handbook/0.1a/index.html)
- [TinyEmu](https://bellard.org/tinyemu/readme.txt)
- [Hardened Gentoo](https://wiki.gentoo.org/wiki/Project:Hardened)
- [Linux From Scratch on the Raspberry Pi](https://intestinate.com/pilfs/about.html)
