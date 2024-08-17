#!/bin/sh
#
build_fck() {

if [ -z "$(ls -l ./assets/firecracker)" ]; then
    git clone https://github.com/firecracker-microvm/firecracker ./assets
    cd firecracker || return
    tools/devtool build
    toolchain="$(uname -m)-unknown-linux-musl"

    cd - || return
fi
}

runsv_service() {
mkdir -p /etc/runit/sv/firecracker

cat <<"EOF" > /etc/runit/sv/firecracker/fck-up.sh
#!/bin/sh

firecracker -p
EOF

ln -s /etc/runit/sv/firecracker/fck-up.sh /run/runit/service/
}

