FROM alpine:3.20 AS deps
USER root


RUN <<EOF

apk upgrade && apk update && \
    apk add musl-dev make libc-dev \
        libbpf-dev file linux-headers libcap \
        ldd libelf zlib-dev libc-dev pkgconf \
        fzf
    #bpftool

# CC=clang

mkdir -p /app/ && cd /app/ || return

(
cat <<HMM
http://dl-cdn.alpinelinux.org/alpine/edge/main
http://dl-cdn.alpinelinux.org/alpine/edge/community
http://dl-cdn.alpinelinux.org/alpine/edge/testing
HMM
) > /etc/apk/repositories

apk add llvm21-dev clang zstd-dev zstd-static


EOF

FROM busybox:1.36.1-musl AS builder

# copy installed binaries from deps
COPY --from=deps /* /

WORKDIR /app/
# COPY ./trace/libbpf-core/ /app/
COPY ./trace/libbpf-core /app/trace/
COPY ./assets/blazesym /app/assets/
COPY ./assets/bpftool /app/assets/
COPY ./assets/libbpf /app/assets/
COPY ./assets/libbpf-bootstrap /app/assets/


RUN <<EOF
# the libbpf main repo
BPF_USER=bpf

# create user and group
addgroup -g 1000 -S "${BPF_USER}" && \
adduser -s /bin/sh -u 1000 -G "${BPF_USER}" \
    -h "/home/${BPF_USER}" -D "${BPF_USER}" && \

EOF

USER bpf
#su "${BPF_USER}" -c "
RUN mkdir -p /home/bpf/app && cp -r /app/* /home/bpf/app/

#WORKDIR /home/bpf/app/trace/libbpf-core/final
WORKDIR /home/bpf/app/assets/libbpf-bootstrap/examples/c/
RUN <<EOF
#cd /home/bpf/app/final || return
mkdir build root
make clean
BUILD_STATIC_ONLY=y OBJDIR=build DESTDIR=root make runqlat
EOF



# set zig cc
# export CC="zig cc"
# export CXX="zig c++"
# export CFLAGS="-target x86_64-linux-musl"
# export CXXFLAGS="-target x86_64-linux-musl"
# export LDFLAGS="-target x86_64-linux-musl"

# autoreconf -i
#"

## # run tests
## WORKDIR /app
## COPY . .
## RUN ls -allhtr
## RUN <<EOF
## libbpf_tests() {
## for dir in /app/*; do
##     if [ -d $dir ]; then
##     cd "$dir" && dune runtest && dune clean && \
##     cat ./stack.yaml && \
##     stack build --test >> /app/test_result_"$(basename "$dir")"_.txt 2>&1
##     cd - || return
##     elif [ -f $dir ]; then
##         echo "A file $dir was found. Skipping..."
##     fi
## done
## }
## libbpf_tests
## EOF


# ======================
# 2. Relay Step
# ======================
FROM alpine:3.20 AS relay

WORKDIR /tests

# COPY --from=builder /app/test_result_*_.txt .

RUN ls -allhtr

# set command to be executed when the container starts
ENTRYPOINT ["/bin/sh", "-c"]

# set argument to be fed to the entrypoint
#CMD ["apk upgrade && apk update && apk add dune ocaml musl-dev"]
# C
