.DEFAULT_GOAL := all

GIT_SHA=$(shell git rev-parse HEAD)
# if changes are detected, append "-local" to hash
GIT_DIFF=$(shell git diff -s --exit-code || echo "-local")
GIT_COMMIT_HASH := $(GIT_SHA)$(GIT_DIFF)

KERNEL_SRC := ./assets/kernel/linux-6.6.22/

BUILD_USER := $(shell id -u -n)@$(shell id -u)
BUILD_DATE := $(shell date --iso-8601=seconds)

FAKEROOT=/usr/fakeroot/$pkg-$ver

SRC_DIR="./first-stage"
BUILD_DIR="./artifacts"

ASM=nasm


#$(FAKEROOT)/

$(BUILD_DIR)/disk.img: $(SRC_DIR)/disk.bin
	cp $(BUILD_DIR)/disk.bin $(BUILD_DIR)/disk.img.img
	truncate -s 1440k $(BUILD_DIR)/disk.img.img

$(BUILD_DIR)/disk.bin: $(SRC_DISC)/btl.asm
	$(ASM) $(SRC_DIR)/btl.asm -f bin -o $(BUILD_DIR)/disk.bin


all:
	$(MAKE) -C $(KERNEL_SRC) M=$(PWD) modules

clean:
	$(MAKE) -C $(KERNEL_SRC) M=$(PWD) clean

menuconfig:
	$(MAKE) -C $(KERNEL_SRC) M=$(PWD) menuconfig


vmlinux:
	$(MAKE) -C $(TRACE_SRC) M=$(PWD) getvmlinux
	#chmod +x ./scripts/getvml.sh; \
	#. ./scripts/getvml.sh

initramfs:
	. ./scripts/ccr.sh; checker; \
	docker compose -f ./compose.yml --progress=plain build initramfs

kernel:
	. ./scripts/ccr.sh; checker; \
	docker compose -f ./compose.yml --progress=plain build kernel

exporter:
	. ./scripts/ccr.sh; checker; \
	docker compose -f ./compose.yml --progress=plain build exporter
