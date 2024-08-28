.DEFAULT_GOAL := all

GIT_SHA=$(shell git rev-parse HEAD)
# if changes are detected, append "-local" to hash
GIT_DIFF=$(shell git diff -s --exit-code || echo "-local")
GIT_COMMIT_HASH := $(GIT_SHA)$(GIT_DIFF)
#USER=${USER}

KERNEL_SRC := ./assets/kernel/linux-6.6.22/

BUILD_USER := $(shell id -u -n)@$(shell id -u)
BUILD_DATE := $(shell date --iso-8601=seconds)

FAKEROOT=/usr/fakeroot/$pkg-$ver

SRC_DIR="./first-stage"
BUILD_DIR="./artifacts"
TRACE_SRC="./trace"

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

# ====================
# kernel-bound tasks
#
# - kbuild system
menuconfig:
	$(MAKE) -C $(KERNEL_SRC) M=$(PWD) menuconfig
#
# - eBPF symbols support: kallsyms request (vmlinux)
vmlinux:
	$(MAKE) -C $(TRACE_SRC) M=$(PWD) getvmlinux
	#chmod +x ./scripts/getvml.sh; \
	#. ./scripts/getvml.sh

# =============================
# Custom LFS build requirements
#
initramfs:
	. ./scripts/ccr.sh; checker; \
	docker compose -f ./compose.yml --progress=plain build initramfs

kernel:
	. ./scripts/ccr.sh; checker; \
	docker compose -f ./compose.yml --progress=plain build kernel

isogen:
	. ./scripts/ccr.sh; checker; \
	perf trace -e 'tracepoint:syscalls:sys_enter_open*' docker compose -f ./compose.yml --progress=plain build isogen
	#sudo --preserve-env=USER,HOME perf trace -e 'syscalls:sys_enter_open*' -- \
	#	sudo -u ${USER} docker compose -f ./compose.yml --progress=plain build isogen

#system-test-iso, STI
sti:
	chmod +x ./scripts/fuse-blkexp.sh
	. ./scripts/ccr.sh; checker; \
	docker compose -f ./compose.yml --progress=plain build iso_system_test

#docker run -d -p 5000:5000 --name registry registry:latest \

mock_sti:
	chmod +x ./scripts/fuse-blkexp.sh;
	. ./scripts/ccr.sh; checker && registry \
	docker start registry && \
	docker compose -f ./compose.yml --progress=plain build mock_ist && \
	docker compose images | awk 'NR==2 { print $4 }' && \
	docker push localhost:5000/linux_build:latest && \
	docker stop registry

kube_mock:
	podman create -rm --name mock_ist localhost:5000/mock_ist:latest
	echo
	ps -a
	echo && echo
	podman generate kube mock_ist > ./artifacts/mock_ist.yaml
	sudo k3s kubectl apply -f ./artifacts/mock_ist.yaml
	podman images | head && ec
	k3s kubectl apply -f ./artifacts/mock_ist.yaml -n=gotests


# ============================
# Observability and Monitoring
#
exporter:
	. ./scripts/ccr.sh; checker; \
	docker compose -f ./compose.yml --progress=plain build exporter

heatmap:
	../assets/HeatMap/trace2heatmap.pl \
		--unitstime=us \
		--unitslabel=latency \
		--grid \
		--maxlat=15000 \
		--title="Latency Heat Map: 15ms max" \
		out.lat_us > out.latzoom.svg

monitor: exporter heatmap

# ================
# Integration Tests
#
tf_test:
	tofu test -test-directory=./modules

qemu_bridge:
	gcc -Wl,--no-as-needed -lcap -o ./scripts/cap-test ./scripts/capng.c
	#CAP_PID=$(./scripts/virt-platforms/qemu-myifup.sh getcap) &
	#sudo setcap 'cap_fsetid=ep cap_net_admin=ep' $(CAP_PID) &
	#wait
# ===========================
# Infrastructure Provisioning
#
k8s:
	kubectl apply -f ./deploy/
