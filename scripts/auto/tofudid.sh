#!/bin/sh

set -e

TOFU_VERSION="1.6.0"
OS="$(uname | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m | sed -e 's/aarch64/arm64/' -e 's/x86_64/amd64/')"
TEMPDIR="$(mktemp -d)"
cd "$TEMPDIR" || return
wget "https://github.com/opentofu/opentofu/releases/download/v${TOFU_VERSION}/tofu_${TOFU_VERSION}_${OS}_${ARCH}.zip"
unzip "tofu_${TOFU_VERSION}_${OS}_${ARCH}.zip"
sudo mv tofu /usr/local/bin/tofu
cd - || return
rm -rf "${TEMPDIR}"
echo "OpenTofu is now available at /usr/local/bin/tofu."


