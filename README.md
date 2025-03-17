### kjx-headless // WIP
> POC for a custom headless LFS distro setup, deploy and monitoring

[![initramfs](https://github.com/deomorxsy/kjx-headless/actions/workflows/initramfs.yml/badge.svg)](https://github.com/deomorxsy/kjx-headless/actions/workflows/initramfs.yml)
[![bzImage](https://github.com/deomorxsy/kjx-headless/actions/workflows/kernel.yml/badge.svg)](https://github.com/deomorxsy/kjx-headless/actions/workflows/kernel.yml)
[![iso9660](https://github.com/deomorxsy/kjx-headless/actions/workflows/ci.yml/badge.svg)](https://github.com/deomorxsy/kjx-headless/actions/workflows/ci.yml)
[![libbpf-core](https://github.com/deomorxsy/kjx-headless/actions/workflows/bee.yml/badge.svg)](https://github.com/deomorxsy/kjx-headless/actions/workflows/bee.yml)
[![cronaws](https://github.com/deomorxsy/kjx-headless/actions/workflows/cronaws.yml/badge.svg)](https://github.com/deomorxsy/kjx-headless/actions/workflows/cronaws.yml)
[![unit-tests](https://github.com/deomorxsy/kjx-headless/actions/workflows/unit.yml/badge.svg)](https://github.com/deomorxsy/kjx-headless/actions/workflows/unit.yml)
[![libbpfgo](https://github.com/deomorxsy/kjx-headless/actions/workflows/libbpfgo.yml/badge.svg)](https://github.com/deomorxsy/kjx-headless/actions/workflows/libbpfgo.yml)
[![ayaya](https://github.com/deomorxsy/kjx-headless/actions/workflows/ayaya.yml/badge.svg)](https://github.com/deomorxsy/kjx-headless/actions/workflows/ayaya.yml)
[![coverage](https://github.com/deomorxsy/kjx-headless/actions/workflows/coverage.yml/badge.svg)](https://github.com/deomorxsy/kjx-headless/actions/workflows/coverage.yml)
[![ocaml-ci](https://github.com/deomorxsy/kjx-headless/actions/workflows/ocaml-ci.yml/badge.svg)](https://github.com/deomorxsy/kjx-headless/actions/workflows/ocaml-ci.yml)
[![dropbear](https://github.com/deomorxsy/kjx-headless/actions/workflows/dropbear.yml/badge.svg)](https://github.com/deomorxsy/kjx-headless/actions/workflows/dropbear.yml)

Taking up from where [eulab-poc](https://github.com/deomorxsy/eulab-poc) left ;D

This proof-of-concept monorepo gathers concepts from several [1] constrained systems to create a *NIX Distro, Linux-based. Composed by Busybox/LFS, it applies CI/CD for infrastructure automation. Aimed to explore the performance of virtualized environments.

Check the [Gitlab mirror]() for an example using Jenkins instead of Github Actions.


```sh
 .-"``"-.
/  _.-` (_) `-._
\   (_.----._)  /
 \     /    \  /
  `\  \____/  /`
    `-.____.-`      __     _
     /      \      / /__  (_)_ __
    /        \    /  '_/ / /\ \ /
   /_ |  | _\    /_/\_\_/ //_\_\
     |  | |          |___/         deomorxsy/kjx
     |__|__|  ----------------------------------------------
     /_ | _\   Reboot (01.00.0, ${GIT_CONTAINERFILE_HASH})
              ----------------------------------------------
```



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

Unit and Integration tests use the go testing package with code coverage. Currently exploring fuzz tests. There is also a chore using [bats-core](https://bats-core.readthedocs.io/). The adopted strategy is composed by spinning up a container, setting permissions with libcap and switching between test scopes for different containerized environments.


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
- [runit-for-lfs](https://github.com/inthecloud247/runit-for-lfs)
- [containerd-rootless](https://github.com/containerd/nerdctl/blob/main/extras/rootless/containerd-rootless.sh)
- [rootless containers initiative](https://rootlesscontaine.rs/)
- [rhatdan's Podman in Action](https://www.manning.com/books/podman-in-action)
- [qemu-fuse-disk-export script](https://gitlab.com/hreitz/qemu-scripts/-/blob/main/qemu-fuse-disk-export.py)
- [youki tests!](https://github.com/containers/youki/blob/main/tests/k8s/Dockerfile)
- [the cromwell runntime](https://github.com/guni1192/cromwell)
- The firecracker scripts from [kubefire](https://github.com/innobead/kubefire)
