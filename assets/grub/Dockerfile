#!/bin/sh


FROM alpine:3.18 as builder

# STEP 1

# bash for lwrap
RUN <<EOF
apk upgrade && apk update && apk add bash linux-headers \
    build-base bison flex gettext \
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



# ============ function
conf_gen() {

PACKAGES_DIR="/app/artifacts/distro/packages"
BUILD_DIR="/app/build"
GRUB_TARBALL="https://ftp.gnu.org/gnu/grub/grub-2.12.tar.gz"

cd "$PACKAGES_DIR/grub-2.12/" || return
./configure
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

}
# ===============

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
EOF


FROM alpine:3.18 as relay

WORKDIR /app/
COPY --from=builder /app/eltorito.img /app/eltorito.img

ENTRYPOINT ["/bin/sh"]
