#!/bin/sh

_main() {
    # run subroutine to build beetor
    if ! make beetor; then
        return 1
    fi
    # docker create beeotr -d localhost:5000/beetor:latest

    # create a container with compose
    if ! docker compose -f ./compose.yml create beetor; then
        return 1
    fi

    # copy logs of the artifact into the dir
    mkdir -p ./artifacts/isogen/libkjx/
    if ! docker cp beetor:/app/foo-beetor.txt ./artifacts/isogen/libkjx/foo-beetor.txt; then
        return 1
    fi

}
