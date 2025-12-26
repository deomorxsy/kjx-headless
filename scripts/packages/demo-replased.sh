#!/bin/sh

# run the first part of the [core_routine] function here for a live runtime environment

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
#
#
if ! (
    ldd "$(readlink -f "$(apk info -L placeholder | awk 'NR > 1' | grep -v contains | grep -v -e "^$" | sed 's/^/\//')")" | awk '{print $3}' >>foo.txt
); then
    echo "|> Error: it was not possible to redirect the filepath of [PLACEHOLDER] dynamically linked binary dependencies (shared objects). Exiting now..."
    echo "|> SCOPE: [DEMO_REPLASED]; check: 02"
    return 1
fi
echo "|> Successfully redirected the filepath of [placeholder] dynamically linked binary dependencies (shared objects). Proceeding..."
echo "|> SCOPE: [DEMO_REPLASED]; check: 02"

#### PKGNAME_PKGDEPS_PLACEHOLDER="$(apk info -L placeholder | awk 'NR > 1' | grep -v contains | grep -v -e "^$" | sed 's/^/\//')"
#### export PKGNAME_PKGDEPS_PLACEHOLDER
####
#### if ! (
####     for f in $PKGNAME_PKGDEPS_PLACEHOLDER; do
####         case $f in
####         # "$(file "$f" | grep ASCII)")
####         "$(file "$f" | grep -v ELF)")
####             echo "|> Sucessfully detected a [$(file "$f")] filepath at [$f]. Redirecting to [/foo.txt]..."
####             echo "$f" >>/foo.txt
####             ;;
####         "$(file "$f" | grep ELF)")
####             echo "|> WARNING: [ELF] filepath detected at [$f]. Redirecting to [/foo.txt]..."
####             ldd "$(readlink -f "$f")" | awk '{print $3}' >>/foo.txt
####             ;;
####         # *)
####         #     echo "|> Error: Invalid filetype that is NEITHER [ASCII] NOR [ELF]. Exiting now..."
####         #     echo "|> BTW, the file is: $(file "$f")"
####         #     #return 1
####         #     ;;
####         esac
####
####     done
#### ) then
####     echo "|> Error: could not detect [DYNAMIC BINARIES] nor [ASCII dotfiles/config-files]. Exiting now..."
####     #return 1
#### fi
####
#### PKGS="$(apk info -L bpftrace | awk 'NR > 1' | grep -v contains | grep -v -e "^$" | sed 's/^/\//')"
####
#### for f in $PKGS; do
####     case $f in
####     # "$(file "$f" | grep ASCII)")
####     "$(file "$f" | grep -v ELF)")
####         echo "|> Sucessfully detected a [$(file "$f")] filepath at [$f]. Redirecting to [/foo.txt]..."
####         echo "$f" >>/foo.txt
####         ;;
####     "$(file "$f" | grep ELF)")
####         echo "|> WARNING: [ELF] filepath detected at [$f]. Redirecting to [/foo.txt]..."
####         ldd "$(readlink -f "$f")" | awk '{print $3}' >>/foo.txt
####         ;;
####     # *)
####     #     echo "|> Error: Invalid filetype that is NEITHER [ASCII] NOR [ELF]. Exiting now..."
####     #     echo "|> BTW, the file is: $(file "$f")"
####     #     #return 1
####     #     ;;
####     esac
#### done

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
