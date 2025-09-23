# FROM busybox:1.36.1-musl as builder
FROM alpine:3.20 as builder
USER root

WORKDIR /app/
# COPY ./trace/libbpf-core/ /app/
COPY ./trace/libbpf-core/ /app/



RUN <<EOF

apk upgrade && apk update && \
    apk add musl-dev make clang libbpf-dev

# CC=clang

mkdir -p /app/ && cd /app/ || return

(
cat <<HMM
http://dl-cdn.alpinelinux.org/alpine/edge/main
http://dl-cdn.alpinelinux.org/alpine/edge/community
http://dl-cdn.alpinelinux.org/alpine/edge/testing
HMM
) > /etc/apk/repositories

apk add zstd-dev zstd-static

# the libbpf main repo
BPF_USER=bpf

# create user and group
addgroup -g 1000 -S "${BPF_USER}" && \
adduser -s /bin/sh -u 1000 -G "${BPF_USER}" \
    -h "/home/${BPF_USER}" -D "${BPF_USER}" && \

# certify it will have the correct user:group permissions
chown -R ${BPF_USER}:${BPF_USER} /home/${BPF_USER}  && \

su "${BPF_USER}" -c "

cp -r /app /home/bpf/

cd /home/bpf/app/final || return

mkdir build root
BUILD_STATIC_ONLY=y OBJDIR=build DESTDIR=root make install




# set zig cc
# export CC="zig cc"
# export CXX="zig c++"
# export CFLAGS="-target x86_64-linux-musl"
# export CXXFLAGS="-target x86_64-linux-musl"
# export LDFLAGS="-target x86_64-linux-musl"

# autoreconf -i
"

EOF
# with git clone supermin



# run tests
WORKDIR /app
COPY . .
RUN ls -allhtr
RUN <<EOF
ocaml_tests() {
for dir in /app/*; do
    if [ -d $dir ]; then
    cd "$dir" && dune runtest && dune clean && \
    cat ./stack.yaml && \
    stack build --test >> /app/test_result_"$(basename "$dir")"_.txt 2>&1
    cd - || return
    elif [ -f $dir ]; then
        echo "A file $dir was found. Skipping..."
    fi
done
}
ocaml_tests
EOF


# ======================
# 2. Relay Step
# ======================
FROM alpine:3.20 as relay

WORKDIR /tests

COPY --from=builder /app/test_result_*_.txt .

# set command to be executed when the container starts
ENTRYPOINT ["/bin/sh", "-c"]

# set argument to be fed to the entrypoint
#CMD ["apk upgrade && apk update && apk add dune ocaml musl-dev"]
# C
