#!/bin/sh

CCR_MODE=checker . ./scripts/ccr.sh && \
    docker compose -f ./compose.yml --progress=plain build zwtd_bpf
