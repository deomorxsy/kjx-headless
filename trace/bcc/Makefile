all: epbf

%.bpf.o: %.bpf.c vmlinux.h
	clang \
		-target bpf \
		-D __TARGET_ARCH_$(ARCH) \
		-I/user/include/$(shell uname -m) -linux-gnu \
		-Wall \
		-O2 -g \
		-c $< -o $@
	llvm-strip -g $@

%.skel.h: %.bpf.o
	bpftool gen skeleton $< > $@

ebpf: ebpf.c config.h ebpf.skel.h
	gcc -Wall -O2 $< -o $@ -lbpf

.PHONY: clean
clean:
	rm -f *.o

.PHONY: build
build: $(OBJ)
