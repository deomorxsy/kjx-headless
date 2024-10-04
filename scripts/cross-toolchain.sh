#!/bin/bash

mkdir -pv build
cd build || return

# LFS_TGT will emulate a cross-toolchain.

#===============
# binutils PASS 1
# ==============
binutils() {
#
#
../configure "--prefix=$LFS/tools" \
             "--with-sysroot=$LFS" \
             "--target=$LFS_TGT"   \
             --disable-nls       \
             --enable-gprofng=no \
             --disable-werror    \
             --enable-default-hash-style=gnu

make && make install
}
# ===============
# gcc PASS 1
# ==============
#
# requires: mpfr, gmp, mpc, elf (left out of LFS)
gcc() {
#
#
tar -xf "$KJX/sources/gcc-13.2.0.tar.xz" "$KJX/tools/"
cd "$KJX/tools/gcc-13.2.0/" || return

#cp "$KJX/sources/compile/mpfr-4.2.1.tar.xz" "$KJX/tools/"
#cp "$KJX/sources/compile/gmp-6.3.0.tar.xz" "$KJX/tools/"
#cp "$KJX/sources/compile/mpc-1.3.1.tar.gz" "$KJX/tools/"

# extract gcc sources to current gcc directory
tar -xf "$KJX/sources/compile/mpfr-4.2.1.tar.xz"
tar -xf "$KJX/sources/compile/gmp-6.3.0.tar.xz"
tar -xf "$KJX/sources/compile/mpc-1.3.1.tar.gz"

#tar -xf "$KJX/tools/mpfr-4.2.1.tar.xz"
#tar -xf "$KJX/tools/gmp-6.3.0.tar.xz"
#tar -xf "$KJX/tools/mpc-1.3.1.tar.gz"

# rename to dependencies without version
mv -v "$KJX/tools/mpfr-4.2.1" mpfr
mv -v "$KJX/tools/gmp-6.3.0" gmp
mv -v "$KJX/tools/mpc-1.3.1" mpc

case $(uname -m) in
    x86_64)
        sed -e '/m64=/s/lib64/lib/' \
            -i.orig gcc/config/i386/
esac

mkdir -v build && cd ./build || return

../configure                  \
    --target="$LFS_TGT"         \
    --prefix="$LFS/tools"       \
    --with-glibc-version=2.39 \
    --with-sysroot="$LFS"       \
    --with-newlib             \
    --without-headers         \
    --enable-default-pie      \
    --enable-default-ssp      \
    --disable-nls             \
    --disable-shared          \
    --disable-multilib        \
    --disable-threads         \
    --disable-libatomic       \
    --disable-libgomp         \
    --disable-libquadmath     \
    --disable-libssp          \
    --disable-libvtv          \
    --disable-libstdcxx       \
    --enable-languages=c,c++

make && make install
}

#========

build_toolchain=("$binutils" "$gcc")

#for tool in "${build_toolchain[@]}"; do
#    docker compose -f ./compose.yml --progress=plain build cross_toolchain
#done

if [ "$1" == "binutils" ]; then
    binutils
elif [ "$1" == "gcc" ]; then
    gcc
elif [ "$1" == "thirdver" ]; then
    thirdver
elif [ "$1" == "kjx" ]; then
    kjx
else
    echo "Invalid function name. Please specify one of: function1, function2, function3"
fi
