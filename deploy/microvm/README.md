### microvms
> low-overhead virtual machines more close to the concept of Full Virtualization by Popek and Goldberg.


Below, all of these are either used as runtimeClass or as a way to talk to the host from the guest machine.

- gvisor's runsc: it creates a sandbox that actually implements a lot of system calls.
- kata-containers:
  - containerd shimv2 implementation
  - dragonball: An optional built-in VMM brings out-of-the-box Kata Containers experience with optimizations on container workloads
- firecracker: it acts alongside kvm and inherits some features from rust-vmm.
- rutabaga: a component from crosvm for the graphics stack. The Rutabaga Virtual Graphics Interface (VGI) is a cross-platform abstraction for GPU and display virtualization.
- crosvm: a hosted/type-2 VMM (virtual machine monitor) similar to QEMU/KVM.i
  - minijail: a C library that is often used alongside its rust wrapper in the case of crosvm.
  - virtio-pmem: ito provide a virtual device emulating a byte-addressable persistent memory device. The disk image is provided to the guest using a memory-mapped view of the image file, and this mapping can be directly mapped into the guest's address space if the guest operating system and filesystem support DAX. [10]
- rust-vmm: he initial idea behind rust-vmm was to create a place for sharing common virtualization components between two existing VMMs written in Rust: CrosVM and Firecracker.
  - similar KVM ioctls
  - virtio device interaction
- virtio
  - virtfs: a new paravirtualized filesystem interface designed for improving passthrough technologies in the KVM environment. It is based on the VirtIO framework and uses the 9P protocol. [9]
  - virtiofsd: vhost-user virtio-fs device backend written in Rust




#### References

- [ ] [9] [kvm virtfs](https://linux-kvm.org/page/VirtFS)
- [ ] [10] [virtio-pmem](https://crosvm.dev/book/devices/pmem/basic.html) from crosvm book
