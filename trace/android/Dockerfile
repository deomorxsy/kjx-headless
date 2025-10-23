FROM ubuntu:22.04 AS builder
USER root
ARG BPF_USER
ENV BPF_USER="bpf"

RUN <<EOF

apt-get update -y && \
    apt-get install -yqq \
        build-essential clang llvm zlib1g-dev libc++-dev libc++abi-dev \
        sudo git curl bash rlwrap unzip \
        && \
    apt-get -y clean

EOF

RUN <<EOF

BPF_USER="bpf"

groupadd -g 1000 -r "${BPF_USER}" && \
    useradd -s /bin/sh -u 1000 -g "${BPF_USER}" \
        -d "/home/${BPF_USER}" -m "${BPF_USER}"

# cp -r /app/* /home/bpf/app/
# chmod -R ${BPF_USER}:${BPF_USER} /home/bpf/app/
EOF

USER ${BPF_USER}
WORKDIR /home/bpf/app/

RUN <<EOF

# install xmake as rootless user
wget https://xmake.io/shget.text -O - | bash
source ~/.xmake/profile

# clone libbpf-bootstrap base repository
git clone https://github.com/libbpf/libbpf-bootstrap.git

# build project with cross-compilation to the arm64-v8a ISA
if [ -d ./libbpf-bootstrap/examples/c/ ]; then
    cd ./libbpf-bootstrap/examples/c && xmake f -p android -a arm64-v8a --require-bpftool=y -y && xmake -y
else
    printf "\n|> Build path does not exist! Exiting now...\n\n"

#make runqlat

EOF


