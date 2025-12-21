#!/bin/sh

apk upgrade && apk update &&
    apk add musl-dev gcc make
# zig cc

# set variables

mkdir -p /app/artifacts/dropbear/

# previous: DB_LINK="https://matt.ucc.asn.au/dropbear/dropbear-2025.87.tar.bz2"
# DB_TARBALL="dropbear-2025.87.tar.bz2"
DB_LINK="https://matt.ucc.asn.au/dropbear/releases/dropbear-2025.88.tar.bz2"
DB_TARBALL_BZADO="dropbear-2025.88.tar.bz2"
DB_TARBALL="dropbear-2025.88.tar"
DB_PATH="artifacts/dropbear"
DROPBEAR_VERSION="dropbear-2025.88"

IS_IN_ROOT_REPO=$(basename "$PWD")
IS_IN_BUILD_ENV=$(
    cat /etc/os-release | grep "Alpine" 2>&1 >/dev/null
)

if ! [ "${IS_IN_ROOT_REPO:-[EMPTY_VARIABLE]}" = "kjx-headless" ]; then
    return
fi

if ! (${IS_IN_BUILD_ENV}); then

    mkdir -p /app/artifacts/dropbear/
    # fetch artifact and decompress tarball
    #mkdir -p "${DB_PATH:-[EMPTY_VARIABLE]}"

    #if ! (wget "${DB_LINK:-[EMPTY_VARIABLE]}" --directory-prefix="${DB_PATH:-[EMPTY_VARIABLE]}"); then
    if ! (wget "${DB_LINK:-[EMPTY_VARIABLE]}" --directory-prefix="/app/artifacts/dropbear/"); then
        echo "|> Error: could not fetch ${DB_TARBALL_BZADO:-[EMPTY_VARIABLE]} from the URL ${DB_LINK:-[EMPTY_VARIABLE]}. Exiting now..."
        return 1
    fi
    echo "|> Sucessfully fetched ${DB_TARBALL_BZADO:-[EMPTY_VARIABLE]} from the URL ${DB_LINK:-[EMPTY_VARIABLE]}. Proceeding..."

    #cd "${DB_PATH:-[EMPTY_VARIABLE]}" || return
    cd "/app/artifacts/dropbear/" || return

    if ! (cp "./${DB_TARBALL_BZADO:-[EMPTY_VARIABLE]}" "./v2_${DB_TARBALL_BZADO:-[EMPTY_VARIABLE]}"); then
        echo "|> Error: it was not possible to copy the DB_TARBALL_BZADO into a v2 backup. Exiting now..."
        return 1
    fi
    echo "|> Sucessfully copied the DB_TARBALL_BZADO into a v2 backup. Proceding..."

    if ! (bzip2 -d "./${DB_TARBALL_BZADO:-[EMPTY_VARIABLE]}"); then
        echo "|> Error: could not decompress the bzip2 file at [DB_TARBALL_BZADO=${DB_TARBALL_BZADO}]. Exiting now..."
        return 1
    fi
    echo "|> Sucessfully decompressed the bzip2 file at [DB_TARBALL_BZADO=${DB_TARBALL_BZADO}]. Proceeding..."

    if ! (tar -xvf "${DB_TARBALL:-[EMPTY_VARIABLE]}"); then
        echo "|> Error: could not decompress the tarball at [${DB_TARBALL:-[EMPTY_VARIABLE]}]. Exiting now..."
        return 1
    fi
    echo "|> Sucessfully decompressed the tarball at [${DB_TARBALL:-[EMPTY_VARIABLE]}]. Proceeding..."

    echo "=========="
    echo "|> Dropbear tarball extracted with success."
    echo "=========="

    cd - || return

    # configure and install binary
    #cd ./artifacts/dropbear/dropbear-2025.87 || return
    cd /app/artifacts/dropbear/${DROPBEAR_VERSION:-[EMPTY_VARIABLE]} || return

    # # set zig env
    # export CC="zig cc"
    # export CXX="zig c++"
    # export CFLAGS="-target x86_64-linux-musl"
    # export CXXFLAGS="-target x86_64-linux-musl"
    # export LDFLAGS="-target x86_64-linux-musl"

    # set gcc options for stripping unused code
    LDFLAGS="$LDFLAGS -Wl,--gc-sections"
    CFLAGS="$CFLAGS -ffunction-sections -fdata-sections"

    # compile statically and disable zlib so it gets slim
    ./configure --prefix=/usr --enable-static --disable-zlib

    # create the dropbear multi-binary
    make PROGRAMS="dropbear dropbearkey dropbearconvert scp dbclient" MULTI=1

    # setup symlinks for the multi-binary
    ln -s ./dropbearmulti "$HOME/app/artifacts/dropbear-multi/dropbear"
    ln -s ./dropbearmulti "$HOME/app/artifacts/dropbear-multi/dropbearkey"
    ln -s ./dropbearmulti "$HOME/app/artifacts/dropbear-multi/dropbearconvert"
    ln -s ./dropbearmulti "$HOME/app/artifacts/dropbear-multi/scp"
    ln -s ./dropbearmulti "$HOME/app/artifacts/dropbear-multi/dbclient"

    cd - || return

#/home/rkd/app/artifacts/dropbear-multi/*

#mkdir -p /app/extract; tar -czf /app/extract/results.tar.gz /home/rkd/app/artifacts/dropbear-multi/*'

# if [ $(nproc) = "1" ]; then
# make -j$(nproc)
# else
# make -j$($(nproc)-1)
# fi
#
# mkdir -p /app/final/
#
# make install DESTDIR=/app/final/

# ======================
# # convert openssh to dropbear style public key
# dropbearconvert openssh dropbear ~/.ssh/id_rsa  ~/.ssh/id_rsa.db
# # associate hostname with the public key
# dbclient -i ~/.ssh/id_rsa.db <hostname>
# # create local dropbear key, then pipe the public key to an existing path
# ./dropbearkey -y -f ~/.ssh/id_ed25519 | grep "^ssh-" > ~/.ssh/id_ed25519.pub
# # generate server keys and then run the server
# ./dropbearkey -t ed25519 -f dropbear_ed25519_host_key
#

# ========================

fi
