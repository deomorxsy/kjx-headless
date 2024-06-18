BUILD_USER := $(shell id -u -n)@$(shell hostname)
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

GET_VMLINUX:
	chmod +x ./scripts/getvml.sh && \
	. ./scripts/getvml.sh


KERNEL_SRC := /path/to/kernel/source

all:
    $(MAKE) -C $(KERNEL_SRC) M=$(PWD) modules

clean:
    $(MAKE) -C $(KERNEL_SRC) M=$(PWD) clean

menuconfig:
    $(MAKE) -C $(KERNEL_SRC) M=$(PWD) menuconfig

