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
	. ./scripts/ccr.sh; checker; \
	docker compose -f ./compose.yml --progress=plain build localstack

initramfs:
	. ./scripts/ccr.sh; checker; \
	docker compose -f ./compose.yml --progress=plain build initramfs

kernel:
	. ./scripts/ccr.sh; checker; \
	docker compose -f ./compose.yml --progress=plain build kernel

bzImage:
	. ./scripts/gen-bzimage.sh

dropbear:
	. ./scripts/ccr.sh; checker; \
	docker compose -f ./compose.yml --progress=plain build dropbear
	#docker compose -f ./compose.yml --progress=plain build --no-cache dropbear


builda_qemu:
	. ./scripts/ccr.sh; checker; \
	docker compose -f ./compose.yml --progress=plain build builda_qemu

.PHONY: isogen
isogen:
	. ./scripts/ccr.sh; checker; \
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
	. ./scripts/ccr.sh; checker;  \
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
	. ./scripts/ccr.sh; checker; \
	docker compose -f ./compose.yml --progress=plain build iso_system_test

#docker run -d -p 5000:5000 --name registry registry:latest \
#&& registry \

mock_sti:
	chmod +x ./scripts/fuse-blkexp.sh;
	. ./scripts/ccr.sh; checker; \
	docker start registry && \
	docker compose -f ./compose.yml --progress=plain build mock_ist && \
	docker compose images | awk 'NR==2 { print $4 }' && \
	docker push localhost:5000/mock_ist:latest && \
	docker stop registry

#podman create -rm --name mock_ist localhost:5000/mock_ist:latest 2>&1 | grep "already in use"
# solve  ImagePullBackOff
kube_mock:
	. ./scripts/ccr.sh; checker; \
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

# ===============
# ISO9660 build phase creation with mount namespaces and squashfs
.PHONY: iso

# ==============
# ISO9660 runtime phase with mount namespaces, libguestfs and squashfs

# ===============
# runit supervised scripts
#
.PHONY: beetor
beetor:
	. ./scripts/ccr.sh; checker; \
	docker run -d -p 5000:5000 --name registry registry:3.0
	docker start registry && \
	docker compose -f ./compose.yml --progress=plain build beetor && \
	docker compose images | grep beetor | awk '{ print $4 }' && \
	docker push localhost:5000/beetor:latest && \
	docker stop registry

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

# ==========
#
.PHONY: ayaya
ayaya:
	. ./scripts/ayabuild.sh
