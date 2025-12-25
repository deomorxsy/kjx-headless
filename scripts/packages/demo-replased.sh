#!/bin/sh

PODMAN_PKGDEPS_PLACEHOLDER="$(apk info -L placeholder | awk 'NR > 1')"
export PODMAN_PKGDEPS_PLACEHOLDER

# redirect the filepath of dotfiles for the [PLACEHOLDER] apk package
if ! (for f in $PODMAN_PKGDEPS_PLACEHOLDER; do
    echo "$f" >>/foo.txt
done); then
    echo "|> Error: it was not possible to redirect the filepath of dotfiles for the [PLACEHOLDER] apk package. Exiting now..."
    return 1
fi
echo "|> Successfully redirected the filepath of dotfiles for the [PLACEHOLDER] apk package. Proceeding..."

# redirect filepath of dynamically linked binary dependencies (shared objects)
if ! (
    ldd "$(readlink -f "$(apk info -L placeholder | awk 'NR > 1')")" | awk '{print $3}' >>foo.txt
); then
    echo "|> Error: it was not possible to redirect the filepath of [PLACEHOLDER] dynamically linked binary dependencies (shared objects). Exiting now..."
    return 1
fi
echo "|> Successfully redirected the filepath of [PLACEHOLDER] dynamically linked binary dependencies (shared objects). Proceeding..."

#
for f in /bin/* /usr/bin/* /usr/sbin/*; do
    case $f in
    */placeholder) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
    esac
done
