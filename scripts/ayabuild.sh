#!/bin/sh

. ./scripts/ccr.sh; checker && \
    docker compose -f ./compose.yml --progress=plain build ayaya
