OUTPUT := .output

# userspace program

# kernel program

# bpftool source, output and bootstrap
BPFTOOL_SRC := $(abspath ../../assets/bpftool/src)
BPFTOOL_OUTPUT ?= $(abspath $(OUTPUT)/bpftool)
BPFTOOL ?= $(BPFTOOL_OUTPUT)/bootstrap/bpftool

# libbpf source, object file and output
LIBBPF_SRC := $(abspath ../../assets/libbpf/src)
LIBBPF_OBJ := $(abspath $(OUTPUT)/libbpf.a)

# symbol resolution library source, includes and object file
LIBBLAZESYM_SRC := $(abspath ../../blazesym/)
LIBBLAZESYM_INC := $(abspath $(LIBBLAZESYM_SRC)/capi/include)
LIBBLAZESYM_OBJ := $(abspath $(OUTPUT)/libblazesym_c.a)

# vmlinux include
GET_VMLINUX:
	cd ../../ || return && \
	chmod +x ./scripts/getvml.sh && \
	. ./scripts/getvml.sh && \
	cd - || return

# arch resolution
ARCH ?= $(shell uname -m | sed 's/x86_64/x86/' \
			 | sed 's/arm.*/arm/' \
			 | sed 's/aarch64/arm64/' \
			 | sed 's/ppc64le/powerpc/' \
			 | sed 's/mips.*/mips/' \
			 | sed 's/riscv64/riscv/' \
			 | sed 's/loongarch64/loongarch/')

# assign vmlinux path using the resolved arch
VMLINUX := ../../artifacts/vmlinux/$(ARCH)/vmlinux.h

CLANG?=clang
LLVM_STRIP=
INCLUDES=

APPS = cpu ram diskio net

ifeq ($(foobar), 1)
	Q =
	msg =
else
	Q = @
	msg = @printf '%-8s %s%s\n' \
		  "$(1)" \
		  "$(patsubst $(abspath $(OUTPUT))/%,%,$(2))" \
		  "$(if $(3), $(3))";
	MAKEFLAGS += --no-print-directory
endif


.PHONY: all
all: $(APPS)

.PHONY: clean
clean:
	rm -f *.o

.PHONY: build
build: $(OBJ)

#vmlinux.h
$(OUTPUT)/%.bpf.o: %.bpf.c $(LIBBPF_OBJ) $(wildcard %.h) %(VMLINUX) | $(OUTPUT) $(BPFTOOL)
	$(Q)$(CLANG)clang \
		-target bpf \
		-D __TARGET_ARCH_$(ARCH) \
		-I/user/include/$(shell uname -m) -linux-gnu \
		-Wall \
		-O2 -g \
		-c $< -o $@
	llvm-strip -g $@

# Build BPF code
$(OUTPUT)/%.bpf.o: %.bpf.c $(LIBBPF_OBJ) $(wildcard %.h) $(VMLINUX) | $(OUTPUT) $(BPFTOOL)
	$(call msg,BPF,$@)
	$(Q)$(CLANG) -g -O2 -target bpf -D__TARGET_ARCH_$(ARCH)		      \
		     $(INCLUDES) $(CLANG_BPF_SYS_INCLUDES)		      \
		     -c $(filter %.c,$^) -o $(patsubst %.bpf.o,%.tmp.bpf.o,$@)
	$(Q)$(BPFTOOL) gen object $@ $(patsubst %.bpf.o,%.tmp.bpf.o,$@)


# Generate BPF skeletons
$(OUTPUT)/%.skel.h: $(OUTPUT)/%.bpf.o | $(OUTPUT) $(BPFTOOL)
	$(call msg,GEN-SKEL,$@)
	$(Q)$(BPFTOOL) gen skeleton $< > $@

%.skel.h: %.bpf.o
	bpftool gen skeleton $< > $@

#ebpf: ebpf.c config.h ebpf.skel.h
#	gcc -Wall -O2 $< -o $@ -lbpf
#
load:
	bpftool prog load hello.bpf.o /sys/fs/bpf/hello

list:
	bpftool prog list --pretty | tail

dumpde: # dump before kernel rewrites
	llvm-objdump -d hello.bpf.o
	llvm-objdump -S hello.bpf.o

dumpar: # dump after kernel rewrites
	bpftool prog dump xlated name hello


