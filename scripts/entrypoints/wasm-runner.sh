#!/bin/sh

CCR=checker . ./scripts/ccr.sh && \
    docker compose build zwtd_bpf -f ./compose.yml
