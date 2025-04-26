#!/bin/sh

# prepare dropbear
bear() {

    db_link="https://matt.ucc.asn.au/dropbear/dropbear-2025.87.tar.bz2"
    db_tarball="dropbear-2025.87.tar.bz2"
    db_path="./artifacts/dropbear"

    mkdir -p "$db_path"
    wget "$db_link" --directory-prefix="$db_path"
    cd "$db_path" || return
    cp "./$db_tarball" "./v2_$db_tarball"
    bzip2 -d "./$db_tarball" && \
        tar -xvf "./dropbear-2025.87.tar" && \
            printf "\n|> Dropbear tarball extracted with success.\n"



}
