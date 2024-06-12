#!/bin/sh
#


build_gvisor() {

if [ -z "$(ls -l ./assets/gvisor)" ]; then
(
  set -e
  ARCH=$(uname -m)
  URL=https://storage.googleapis.com/gvisor/releases/release/latest/${ARCH}
  wget "${URL}/runsc" "${URL}/runsc.sha512" \
    "${URL}/containerd-shim-runsc-v1" "${URL}/containerd-shim-runsc-v1.sha512"
  sha512sum -c runsc.sha512 \
    -c containerd-shim-runsc-v1.sha512
  rm -f ./*.sha512
  chmod a+rx runsc containerd-shim-runsc-v1
  sudo mv runsc containerd-shim-runsc-v1 /usr/local/bin
  /usr/local/bin/runsc install
  docker run --rm --runtime=runsc hello-world
)
fi
}

runsv_service() {
mkdir -p /etc/runit/sv/gvisor

cat <<"EOF" > /etc/runit/sv/gvisor/runsc-up.sh
#!/bin/sh

runsc -p
EOF

ln -s /etc/runit/sv/gvisor/runsc-up.sh /run/runit/service/
}

