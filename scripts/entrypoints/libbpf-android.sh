#!/bin/sh


builder() {

CCR_MODE="checker" . ./scripts/ccr.sh && \
    docker compose -f ./compose.yml --progress=plain build --no-cache android
}

runner() {
# set -euxo pipefail

apt-get update -y && \
    apt-get install -yqq \
        build-essential clang llvm zlib1g-dev libc++-dev libc++abi-dev \
        sudo git wget bash rlwrap unzip \
        && \
    apt-get -y clean


wget -h

# set -euxo pipefail

BPF_USER="bpf"

groupadd -g 1000 -r "${BPF_USER}" && \
    useradd -s /bin/bash -u 1000 -g "${BPF_USER}" \
        -d "/home/${BPF_USER}" -m "${BPF_USER}"

# cp -r /app/* /home/bpf/app/
# chmod -R ${BPF_USER}:${BPF_USER} /home/bpf/app/

su bpf -c '
wget https://xmake.io/shget.text -O - | bash

source ~/.xmake/profile

git clone https://github.com/libbpf/libbpf-bootstrap.git

ls -allhtr

if [ -d ./libbpf-bootstrap/examples/c/ ]; then
    ls -allhtr ./libbpf-bootstrap/
    cd ./libbpf-bootstrap/examples/c || return \
    && xmake f -p android -a arm64-v8a --require-bpftool=y -y && xmake -y
else
    printf "\n|> Build path does not exist! Exiting now...\n\n"
fi

'

}


print_usage() {
cat <<-END >&2
USAGE: libbpf-android [-options]
                - runner
                - builder
                - version
                - help
e.g.,
libbpf-static -builder  # builds the project
libbpf-static -version  # shows script version
libbpf-static -help     # shows this help message

See the man page and example file for more info.

END

}


# Check the argument passed from the command line
if [ "$MODE" = "-builder" ] || [ "$MODE" = "--builder" ] || [ "$MODE" = "builder" ]; then
    builder
elif [ "$1" = "help" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    print_usage
elif [ "$1" = "version" ] || [ "$1" = "-v" ] || [ "$1" = "--version" ]; then
    printf "version"
else
    echo "Invalid function name. Please specify one of: function1, function2, function3"
    print_usage
fi


