#!/bin/sh

CCR=checker . ./scripts/ccr.sh && \
    docker compose build wasm_bpf -f ./compose.yml
