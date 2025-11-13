# -*- makefile -*- : Force emacs to use Makefile mode
#.DEFAULT_GOAL := all
#SHELL := /bin/sh

GIT_SHA=$(shell git rev-parse HEAD)
# if changes are detected, append "-local" to hash
GIT_DIFF=$(shell git diff -s --exit-code || echo "-local")
GIT_COMMIT_HASH := $(GIT_SHA)$(GIT_DIFF)
#USER=${USER}

KERNEL_SRC="./assets/kernel/linux-6.6.22/"

BUILD_USER := $(shell id -u -n)@$(shell id -u)
BUILD_DATE := $(shell date --iso-8601=seconds)

FAKEROOT=/usr/fakeroot/$pkg-$ver

SRC_DIR="./first-stage"
BUILD_DIR="./artifacts"
TRACE_SRC="./trace"

ASM=nasm

# isogen image logic
TIMESTAMP=$(shell date +%s)
MARKER = .target_isogen_done
TARGET = my_target

#$(FAKEROOT)/

$(BUILD_DIR)/disk.img: $(SRC_DIR)/disk.bin
	cp $(BUILD_DIR)/disk.bin $(BUILD_DIR)/disk.img.img
	truncate -s 1440k $(BUILD_DIR)/disk.img.img

$(BUILD_DIR)/disk.bin: $(SRC_DISC)/btl.asm
	$(ASM) $(SRC_DIR)/btl.asm -f bin -o $(BUILD_DIR)/disk.bin


#all:
#	$(MAKE) -C $(KERNEL_SRC) M=$(PWD) modules

#clean:
#	$(MAKE) -C $(KERNEL_SRC) M=$(PWD) clean

#.PHONY: clean
#clean:
#	$(call msg,CLEAN)
#	$(Q)rm -rf $(OUTPUT) $(APPS)

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

localstack:
	CCR_MODE="-checker" . ./scripts/ccr.sh; \
	docker compose -f ./compose.yml --progress=plain build localstack

initramfs:
	CCR_MODE="-checker" . ./scripts/ccr.sh; \
	docker compose -f ./compose.yml --progress=plain build initramfs

kernel:
	CCR_MODE="-checker" . ./scripts/ccr.sh; \
	docker compose -f ./compose.yml --progress=plain build kernel

bzImage:
	. ./scripts/gen-bzimage.sh

.PHONY: dropbear
dropbear:
	MODE="-builder" . ./scripts/entrypoints/build-dropbear.sh
	#CCR_MODE="-checker" . ./scripts/ccr.sh; \
	#docker compose -f ./compose.yml --progress=plain build dropbear
	#docker compose -f ./compose.yml --progress=plain build --no-cache dropbear


builda_qemu:
	CCR_MODE="-checker" . ./scripts/ccr.sh; \
	docker compose -f ./compose.yml --progress=plain build builda_qemu

# builds the project and fetch binaries for qemu-storage-daemon on qemu automation for the builder
.PHONY: qonq
qonq:
	MODE="-rep" . ./scripts/qonq-qdb.sh

.PHONY: isogen
isogen:
	CCR_MODE="-checker" . ./scripts/ccr.sh; \
	docker start registry && \
	docker compose -f ./compose.yml --progress=plain build --no-cache isogen_new && \
	docker compose images | grep isogen | awk '{ print $4 }' && \
	docker push localhost:5000/isogen_new:latest && \
	docker stop registry

#	touch $(MARKER) # create marker file


#$(MARKER):
#	@touch $(MARKER)

# avoid rebuilds
#check_build_timestamp:
#	@if [ -f $(MARKER) ] && [ $$(( $(TIMESTAMP) - $$(stat -c %Y $(MARKER)) )) -lt 60 ]; then \
#		echo "Target was just run, skipping ;D"; \
#		exit 0; \
#	else \
#		$(MAKE) $(isogen); \
#	fi


counter="0"
finalbase="kjx_isogen_"
semver="$(eval tr -dc A-Za-z0-9 </dev/urandom | head -c 13; echo)"

contname=$(finalbase)$(semver)

#generate: check_build_timestamp
generate:
	CCR_MODE="-checker" . ./scripts/ccr.sh;  \
	docker start registry; \
	docker create --userns=auto --cap-drop=ALL --cap-add=CAP_SYS_ADMIN,CAP_DAC_OVERRIDE --rm --name kjx_isogen $(podman images | head | grep isogen_new | awk 'NR==2 {print $3}') 2>&1 | grep "already in use"; \
	if [ $$? -eq 0 ]; then \
		printf "\n======\nContainer name available. Running it now...\n========="; \
		docker start $(contname); \
		docker logs -f $(contname); \
		docker cp $(contname):/app/output.iso ./artifacts/kjx-headless.iso; \
		docker rm $(contname); \
		docker stop registry; \
#		# $(MAKE) $(clean) \
	else \
		echo hmmm; \
	#	printf "\n========\nContainer name is already in use. Stopping and removing the previous one...\n=======\n\n"; \
	fi \
	docker rm $(contname) && \
	docker stop registry;


#system-test-iso, STI
sti:
	chmod +x ./scripts/fuse-blkexp.sh
	CCR_MODE="-checker" . ./scripts/ccr.sh; \
	docker compose -f ./compose.yml --progress=plain build iso_system_test

#docker run -d -p 5000:5000 --name registry registry:latest \
#&& registry \

mock_sti:
	chmod +x ./scripts/fuse-blkexp.sh;
	CCR_MODE="-checker" . ./scripts/ccr.sh; \
	docker start registry && \
	docker compose -f ./compose.yml --progress=plain build mock_ist && \
	docker compose images | awk 'NR==2 { print $4 }' && \
	docker push localhost:5000/mock_ist:latest && \
	docker stop registry

#podman create -rm --name mock_ist localhost:5000/mock_ist:latest 2>&1 | grep "already in use"
# solve  ImagePullBackOff
kube_mock:
	CCR_MODE="-checker" . ./scripts/ccr.sh; \
	docker create --name mock_ist localhost:5000/mock_ist:latest 2>&1 | grep "already in use";  \
	if [ $? -eq 0 ]; then echo hmmm && \
	docker start registry && \
	curl -s -i -X GET http://registry.localhost:5000/v2/_catalog && \
	docker push mock_ist localhost:5000/mock_ist:latest && \
	podman generate kube mock_ist > ./artifacts/mock_ist.yaml
	sudo k3s kubectl create namespace gotests && \
	k3s kubectl apply -f ./artifacts/mock_ist.yaml -n=gotests && \
	k3s crictl pods | head; \
	k3s crictl pods | awk 'NR==2 {print $1}' \
	k3s kubectl get pods -n=gotests \
	k3s kubectl cluster-info
	printf "\n ===== Cleaning now... ======\n\n" && \
	sudo k3s kubectl delete -f ./artifacts/mock_ist.yaml -n=gotests && \
	docker stop registry \
	else echo yo wtf; fi

	#echo && echo
	#podman generate kube mock_ist > ./artifacts/mock_ist.yaml
	#sudo k3s kubectl apply -f ./artifacts/mock_ist.yaml
	#podman images | head && ec
	#k3s kubectl apply -f ./artifacts/mock_ist.yaml -n=gotests


# ============================
# Observability and Monitoring
#
exporter:
	CCR_MODE="-checker" . ./scripts/ccr.sh; \
	docker compose -f ./compose.yml --progress=plain build exporter

heatmap:
	../assets/HeatMap/trace2heatmap.pl \
		--unitstime=us \
		--unitslabel=latency \
		--grid \
		--maxlat=15000 \
		--title="Latency Heat Map: 15ms max" \
		out.lat_us > out.latzoom.svg

grafana:
	MODE="runner" . ./scripts/monitor/grafana.sh
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

# ===============
# ISO9660 build phase creation with mount namespaces and squashfs
.PHONY: iso

# ==============
# ISO9660 runtime phase with mount namespaces, libguestfs and squashfs

# ===============
# runit supervised scripts
#

# libkjx/beetor_bwc
.PHONY: beetor
beetor:
	MODE="builder" PROGRAM="beetor" . ./scripts/entrypoints/static_beetor.sh


# fix beetor synchronization program
.PHONY: bwc
bwc:
	MODE="builder" PROGRAM="bwc" . ./scripts/entrypoints/static_beetor.sh

#.PHONY: libkjx_valgrind
#libkjx_valgrind: beetor, bwc
#   MODE="-profiler"


# old setcap script
# untested
.PHONY: setcap
setcap:
	gcc -Wall -o ./scripts/libkjx/cap_example ./scripts/libkjx/setcap.c -lcap
    # gcc -Wall -o cap_example setcap.c -lcap -static -fPIE -pie


# generate stack call graph
.PHONY: valprof
valprof:
	. ./scripts/libkjx/static_beetor.sh profiler


.PHONY: k9s
k9s:
	sudo -E k9s --kubeconfig /etc/rancher/k3s/k3s.yaml

# ==================
# proof verification
#

# sel4 verifiable kernel
.PHONY: sel4
sel4:
	echo "not yet!"

# ocaml to USDT ebpf
.PHONY: beeml
beeml:
	echo "not yet!"

# menhir backend to coq
.PHONY: cohir
cohir:
	echo "not yet!"

# ============
# context switch tasks
#

# device driver
.PHONY: ddkjx
ddkjx:
	gcc -Wl -no-as-needed -lcap -o ./scripts/libkjx/device-driver/sample ./scripts/libkjx/device-driver/sample.c

# LKM
#
obj-m += hello-1.o
obj-m += hello-2.o

LKM_PWD := $(CURDIR)/scripts/libkjx/lkm_idk

all_lkm:
	$(MAKE) -C /lib/modules/$(shell uname -r)/build M=$(LKM_PWD) modules

clean_lkm:
	$(MAKE) -C /lib/modules/$(shell uname -r)/build M=$(LKM_PWD) clean

.PHONY: lkmkjx
lkmkjx:
	gcc -Wl --no-as-needed -lcap -o ./scripts/libkjx/lkm_idk/lkm-sample ./scripts/libkjx/lkm_idk/main.c


# ====================
# Tracers
# ====================

# aya-rs
.PHONY: ayaya
ayaya:
	BUILD_PAR="builder" . ./scripts/ayabuild.sh

# aya-rs from the justfile
.PHONY: justaya
justaya:
	(cd ./trace/ayaya || return) && just build && (cd - || return)

# libbpf-based tracing
.PHONY: libbpf-core
libbpf-core:
	$(MAKE) -C trace/libbpf-core/ bootstrap


# honey-potion
.PHONY: hpota
hpota:
	MODE="builder" . ./scripts/tracers/hpota.sh

.PHONY: hpota_runner
hpota_runner:
	MODE="runner" . ./scripts/tracers/hpota.sh

# =========
# qemu builder runtime

.PHONY: qemu_builder
qemu_builder:
	. ./scripts/sandbox/run-qemu.sh -d

# airgap k3s inside QEMU
.PHONY: airgap
airgap:
	. ./scripts/sandbox/run-qemu.sh -airgap


# generate k3s dependencies
.PHONY: squash
squash:
	. ./scripts/sandbox/run-qemu.sh -squash


# ======== boot related

# generate eltorito.img before xorriso
.PHONY: eltorito
eltorito:
	#. ./scripts/usfs.sh
	# --rm -it
	CCR_MODE="-checker" . ./scripts/ccr.sh && \
	docker run -d --name eltorito-builder  \
		-v "$$PWD/scripts:/app/scripts/" \
		alpine:3.20 \
		/bin/sh -c "chmod +x /app/scripts/install_grub.sh && /app/scripts/install_grub.sh && sleep 100"
	# wait a few seconds
	sleep 2
	# retrieve artifact
	mkdir -p ./artifacts/bootloader/
	docker cp eltorito-builder:/app/eltorito.img ./artifacts/bootloader/
	# cleanup container runtime
	docker rm -f eltorito-builder


.PHONY: itoeltor
itoeltor:
	CCR_MODE="-checker" . ./scripts/ccr.sh && \
	docker compose -f ./compose.yml --progress=plain build grub

# GOTO: airgap instead
.PHONY: runiso
runiso:
	MODE="-runiso" . ./scripts/sandbox/run-qemu.sh

.PHONY: record-runiso
record-runiso: runiso
	MODE="-record-runiso" . ./scripts/sandbox/run-qemu.sh

# zig-wasm-typescript-deno-bpf
.PHONY: zwtd-bpf
zwtd-bpf:
	. ./scripts/entrypoints/wasm-runner.sh

.PHONY: final-builder
final:
	MODE="builder" . ./scripts/entrypoints/libbpf-static.sh

.PHONY: runner-final
runner-final:
	MODE="runner" . ./scripts/entrypoints/libbpf-static.sh

.PHONY: android
android:
	MODE="builder" . ./scripts/entrypoints/libbpf-android.sh

.PHONY: libbpfgo
libbpfgo:
	MODE="builder" . ./scripts/entrypoints/libbpf-go.sh

# ==============
# Microvms
#
# uses: qonq-qdb
# ==============
.PHONY: microvms-aio
microvms-aio:
	MODE="microvms-aio" . ./scripts/entrypoints/microvms.sh

.PHONY: mvm-kata
mvm-kata:
	MODE="kata" . ./scripts/entrypoints/microvms.sh

.PHONY: mvm-gvisor
mvm-gvisor:
	MODE="gvisor" . ./scripts/entrypoints/microvms.sh

.PHONY: mvm-firecracker
mvm-firecracker:
	MODE="firecracker" . ./scripts/entrypoints/microvms.sh


# ===========
# HLCR: High-Level Container Runtime
#
# uses: qonq-qdb
# ==============
.PHONY: hlcr-aio
hlcr-aio: hlcr-docker hlcr-podman hlcr-crio
	MODE="hlcr-aio" . ./scripts/entrypoints/hlcr.sh

.PHONY: hlcr-docker
hlcr-docker:
	MODE="hlcr-docker" . ./scripts/entrypoints/hlcr.sh

.PHONY: hlcr-podman
hlcr-podman:
	MODE="hlcr-podman" . ./scripts/entrypoints/hlcr.sh

.PHONY: hlcr-crio
hlcr-crio:
	MODE="hlcr-crio" . ./scripts/entrypoints/hlcr.sh

# ===========
# LLCR: High-Level Container Runtime
# ==============
.PHONY: llcr-aio
llcr-aio: llcr-runc llcr-crun llcr-containerd llcr-youki
	MODE="llcr-aio" . ./scripts/entrypoints/llcr.sh

.PHONY: llcr-runc
llcr-runc:
	MODE="llcr-runc" . ./scripts/entrypoints/llcr.sh

.PHONY: llcr-crun
llcr-crun:
	MODE="llcr-crun" . ./scripts/entrypoints/llcr.sh

.PHONY: llcr-containerd
llcr-containerd:
	MODE="llcr-containerd" . ./scripts/entrypoints/llcr.sh

.PHONY: llcr-youki
llcr-youki:
	MODE="llcr-youki" . ./scripts/entrypoints/llcr.sh

# ==========================
# Fetch-GHA Artifacts logic
#
# ==========================
#
.PHONY: fa-kernel
fa-kernel:
	MODE="-kernel" . ./scripts/ci-cd/fa-gha.sh
.PHONY: fa-initramfs
fa-initramfs:
	MODE="-initramfs" . ./scripts/ci-cd/fa-gha.sh
.PHONY: fa-ssh-rootfs
fa-ssh-rootfs:
	MODE="-ssh-rootfs" . ./scripts/ci-cd/fa-gha.sh
.PHONY: fa-qonq-qdb
fa-qonq-qdb:
	MODE="-qonq-qdb" . ./scripts/ci-cd/fa-gha.sh
.PHONY: fa-beetor
fa-beetor:
	MODE="-beetor" . ./scripts/ci-cd/fa-gha.sh
.PHONY: fa-runit
fa-runit:
	MODE="-runit" . ./scripts/ci-cd/fa-gha.sh
# .PHONY: fa-iso
# fa-iso:
# 	MODE="-iso" . ./scripts/ci-cd/fa-gha.sh

.PHONY: iso9660
iso9660:
	MODE="isogen" . ./scripts/tryout.sh

