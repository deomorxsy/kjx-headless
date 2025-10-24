FROM alpine:3.22 AS vml

# RUN <<EOF
# apk upgrade && \
#     apk update && \
#     apk add bpftool && \
#     bpftool btf dump file /sys/kernel/btf/vmlinux format c > /vmlinux.h
# EOF

FROM ubuntu:22.04 AS builder
USER root
ARG BPF_USER
ENV BPF_USER="bpf"
ENV PATH="/home/${BPF_USER}/.local/bin:${PATH}"

#COPY --from=vml /vmlinux.h /usr/src/linux/vmlinux.h

RUN <<EOF

apt-get update -y && \
    apt-get install -yqq \
        build-essential clang llvm zlib1g-dev libc++-dev libc++abi-dev \
        sudo git curl bash rlwrap unzip wget \
        && \
    apt-get -y clean

EOF

RUN <<EOF

BPF_USER="bpf"

groupadd -g 1000 -r "${BPF_USER}" && \
    useradd -s /bin/bash -u 1000 -g "${BPF_USER}" \
        -d "/home/${BPF_USER}" -m "${BPF_USER}"

# cp -r /app/* /home/bpf/app/
# chmod -R ${BPF_USER}:${BPF_USER} /home/bpf/app/
EOF

USER ${BPF_USER}
WORKDIR /home/bpf/app/
RUN <<EOF

# install xmake as rootless user
wget https://xmake.io/shget.text -O - | bash
. /home/bpf/.xmake/profile

# clone libbpf-bootstrap base repository
git clone --recursive https://github.com/libbpf/libbpf-bootstrap.git

cp ./libbpf-bootstrap/vmlinux.h/include/arm64/vmlinux.h /usr/include/

# build project with cross-compilation to the arm64-v8a ISA
if [ -d ./libbpf-bootstrap/examples/c/ ]; then
    cd ./libbpf-bootstrap/examples/c && xmake f -p android -a arm64-v8a --require-bpftool=y -y && xmake -y
else
    printf "\n|> Build path does not exist! Exiting now...\n\n"
fi
#make runqlat

EOF

FROM alpine:3.22 AS relay

ENTRYPOINT ["/bin/sh", "-c"]
CMD ["echo", "hmm"]
