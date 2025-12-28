#!/bin/sh

# STEP 2
conf_gen() {

PACKAGES_DIR="/app/artifacts/distro/packages"
BUILD_DIR="/app/build"

# cd /app/build || return
cd "$PACKAGES_DIR/grub-2.12/" || return

#$PACKAGES_DIR/grub-2.12/configure \
./configure
#--prefix="$PACKAGES_DIR/grub-2.12/INSTALL" \
#     --target=i386 \
#     --with-platform=pc

make install

# generate the eltorito.img floppy image for CD/DVD
# needs grub-bios for the file /usr/lib/grub/i386-pc/moddep.lst
grub-mkimage \
  -O i386-pc \
  -o eltorito.img \
  -p /boot/grub \
  biosdisk iso9660 multiboot normal configfile linux

cp ./eltorito.img /app/

cd - || return

printf "\n============\n|> Done! Exiting in 150 seconds...\n\n"

# copy the artifact
# sleep 150

}

# STEP 1
image_runtime()  {

# bash for lwrap
apk add bash linux-headers build-base bison flex gettext \
    autoconf automake libtool texinfo xorriso e2fsprogs-dev \
    fuse3-dev device-mapper util-linux-dev parted python3 m4 \
    grub-dev grub-bios grub zlib-dev ncurses-dev fzf

(
cat <<HMM
http://dl-cdn.alpinelinux.org/alpine/edge/main
http://dl-cdn.alpinelinux.org/alpine/edge/community
http://dl-cdn.alpinelinux.org/alpine/edge/testing
HMM
) > /etc/apk/repositories

# get lzma
apk add xz-dev

# replace uuid-dev
apk add util-linux-dev

PACKAGES_DIR="/app/artifacts/distro/packages"
BUILD_DIR="/app/build"
GRUB_TARBALL="https://ftp.gnu.org/gnu/grub/grub-2.12.tar.gz"


mkdir -p "$BUILD_DIR"
mkdir -p "$PACKAGES_DIR"

if ! [ -d "$PACKAGES_DIR/grub-2.12/" ]; then
    wget -P "$PACKAGES_DIR" "$GRUB_TARBALL"
    cd "$PACKAGES_DIR" || return
    tar -xvf ./grub-2.12.tar.gz
    cd - || return
    #
    conf_gen
else
    conf_gen
fi


}


image_runtime
