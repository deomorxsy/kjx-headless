#!/bin/sh

GET_ARCH=$(uname -m)
BOOTSTRAP_DIR="./trace/libbpf-core/examples"
CLANG_VERSION=$(clang --version | awk 'NR==1 {print $3}' | cut -d. -f1)

# ensure libbpf is built, so you can get the libbpf.a static library
LIBBPF_SRC=./assets/libbpf-bootstrap/libbpf
OUTPUT=".output"
LIBBPF_OBJ="$OUTPUT"/libbpf.a
UAPI_HEADERS="$LIBBPF_SRC"/include/uapi
OTHER_INCLUDES="$LIBBPF_SRC"/include
VMLINUX_HEADER_PATH="$BOOTSTRAP_DIR"
STATIC_LIBBPF="./assets/libbpf-bootstrap/libbpf/src/.output/libbpf.a"



mkdir -p "$OUTPUT"/libbpf

# create vmlinux header if it doesn't exist
if readlink -f "$(which bpftool)" && ! [ -f $VMLINUX_HEADER_PATH/vmlinux.h ]; then
    bpftool btf dump \
        file /sys/kernel/btf/vmlinux \
        format c > "$VMLINUX_HEADER_PATH"/vmlinux.h
else
    printf "\nFound %s/vmlinux.h, skipping..." "$VMLINUX_HEADER_PATH"
fi



if ! [ -f "$STATIC_LIBBPF" ] || ! [ -d "$OTHER_INCLUDES" ]; then
    #
    make -C "${LIBBPF_SRC}"/src BUILD_STATIC_ONLY=1 \
    OBJDIR="${OUTPUT}/libbpf" \
    DESTDIR="${OUTPUT}" \
    INCLUDEDIR= LIBDIR= UAPIDIR= install
else
    printf "=======\nFound the libbpf.a static library. Skipping...\n=========\n\n"
fi


if [ "$CLANG_VERSION" -gt 16 ]; then
# compile kernel space program
clang -v -target bpf \
    -D__TARGET_ARCH_"$GET_ARCH" \
    -I/usr/include/"$GET_ARCH"-linux-gnu \
    -Wall \
    -O2 -g \
    -c "$BOOTSTRAP_DIR"/bootstrap.bpf.c \
    -o "$BOOTSTRAP_DIR"/bootstrap.tmp.bpf.o
else
    printf "\nCouldn't compile because either clang isn't installed or its version is too old. Exiting now...\n\n"
# additional: llvm-strip -g <object file> removes DWARF debuginfo
fi

if  readlink -f "$(which bpftool)" && [ -f "$BOOTSTRAP_DIR"/bootstrap.tmp.bpf.o ]; then
    # creates bootstrap.bpf.o
    bpftool gen object "$BOOTSTRAP_DIR"/bootstrap.bpf.o "$BOOTSTRAP_DIR"/bootstrap.tmp.bpf.o

    # creates skeleton header
    bpftool gen skeleton "$BOOTSTRAP_DIR"/bootstrap.bpf.o > "$BOOTSTRAP_DIR"/bootstrap.skel.h

else
    printf "\nCould not create bootstrap.bpf.o\n\n"
fi


# compile userspace program
if ! [ -f "$UAPI_HEADERS" ] || \
    ! [ -f "$OTHER_INCLUDES" ] || \
    ! [ -f "$VMLINUX_HEADER_PATH" ] ||\
    ! [ -f "$BOOTSTRAP_DIR"/bootstrap.c ] || \
    ! [ -f "$BOOTSTRAP_DIR"/bootstrap.o ]; then
 clang -v -g -Wall                   \
    -I"$UAPI_HEADERS"               \
    -I"$OTHER_INCLUDES"             \
    -I"$VMLINUX_HEADER_PATH"        \
    -c "$BOOTSTRAP_DIR"/bootstrap.c \
    -o "$BOOTSTRAP_DIR"/bootstrap.o
else
    printf "\nCould not compile the userspace program. Exiting now...\n\n"
fi

# link final executable
if [ -f "$BOOTSTRAP_DIR"/bootstrap.o ] || \
   [ -f "$STATIC_LIBBPF" ]; then
clang -g        \
    -Wall "$BOOTSTRAP_DIR"/bootstrap.o "$STATIC_LIBBPF" \
    -lrt        \
    -ldl        \
    -lpthread   \
    -lm         \
    -lelf       \
    -lz         \
    -o "$BOOTSTRAP_DIR"/ocisnoop

    generated=$?

    if [ $generated -eq 0 ]; then
        printf "\n=============\nSuccessfully generated eBPF CO-RE program \o/\n----|> Check it at %s !!\n\n" "$BOOTSTRAP_DIR"/ocisnoop
    fi
else
    printf "\nCouldn't link the final executable. Exiting now...\n\n"

fi
