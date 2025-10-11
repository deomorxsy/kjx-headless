#!/bin/sh


CCR_MODE="checker" . ./scripts/ccr.sh && \
	docker run -d --name eltorito-builder  \
		-v "$$PWD/scripts:/app/scripts/" \
		alpine:3.20 \
		/bin/sh -c "chmod +x /app/scripts/install_grub.sh && /app/scripts/install_grub.sh && sleep 100"

# wait a few seconds
sleep 2

# retrieve artifact
mkdir -p ./artifacts/bootloader/

CCR_MODE="checker" . ./scripts/ccr.sh && \
    docker cp eltorito-builder:/app/eltorito.img ./artifacts/bootloader/ && \
    # cleanup container runtime
    docker rm -f eltorito-builder
