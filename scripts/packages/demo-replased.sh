#!/bin/sh

PKGNAME_PKGDEPS_PLACEHOLDER="$(apk info -L placeholder | awk 'NR > 1' | grep -v contains | grep -v -e "^$" | sed 's/^/\//')"
export PKGNAME_PKGDEPS_PLACEHOLDER

# redirect the filepath of dotfiles for the [PLACEHOLDER] apk package
if ! (for f in $PKGNAME_PKGDEPS_PLACEHOLDER; do
    echo "$f" >>/foo.txt
done); then
    echo "|> Error: it was not possible to redirect the filepath of dotfiles for the [PLACEHOLDER] apk package. Exiting now..."
    echo "|> SCOPE: [DEMO_REPLASED]; check: 01"
    return 1
fi
echo "|> Successfully redirected the filepath of dotfiles for the [PLACEHOLDER] apk package. Proceeding..."
echo "|> SCOPE: [DEMO_REPLASED]; check: 01"

# redirect filepath of dynamically linked binary dependencies (shared objects)
if ! (
    ldd "$(readlink -f "$(apk info -L placeholder | awk 'NR > 1')")" | awk '{print $3}' >>foo.txt
); then
    echo "|> Error: it was not possible to redirect the filepath of [PLACEHOLDER] dynamically linked binary dependencies (shared objects). Exiting now..."
    echo "|> SCOPE: [DEMO_REPLASED]; check: 02"
    return 1
fi
echo "|> Successfully redirected the filepath of [placeholder] dynamically linked binary dependencies (shared objects). Proceeding..."
echo "|> SCOPE: [DEMO_REPLASED]; check: 02"

#
### if ! (
###     for f in /bin/* /usr/bin/* /usr/sbin/*; do
###         case $f in
###         */placeholder) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
###         esac
###     done
### ) then
###     echo "|> Error: could not find binaries of [placeholder] at [/bin, /usr/bin or /usr/sbin] to ldd (list dynamic dependencies). Exiting now..."
###     echo "|> SCOPE: [DEMO_REPLASED]; check: 03"
###     return 1
### fi
### echo "|> Error: could not find binaries of [placeholder] at [/bin, /usr/bin or /usr/sbin] to ldd (list dynamic dependencies). Exiting now..."
### echo "|> SCOPE: [DEMO_REPLASED]; check: 03"
