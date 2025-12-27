#!/bin/sh

core_routine() {
    mkdir -p /app/scripts/packages

    DEPSLIST="/app/scripts/packages/demo-replased.sh"
    export DEPSLIST

    CORE_SHADOW_DEPS="$(

        apk dot libcap parted device-mapper fuse-overlayfs qemu qemu-img qemu-system-x86_64 \
            file multipath-tools e2fsprogs xorriso expect libseccomp libcgroup \
            squashfs-tools setxkbmap losetup fuse3 \
            perl \
            --installed |
            grep -v "shape=box" |
            grep -v "rankdir=LR" |
            grep -v "digraph" |
            awk '{print $1}' |
            sed -E 's/-[0-9].*$//' |
            tr -d '"' |
            tr -d "}" |
            sort -u

    )"
    export CORE_SHADOW_DEPS

    if ! [ -f "${DEPSLIST:-[EMPTY_VARIABLE]}" ]; then

        # cp
        echo "|> Error: it was not possible to resolve dependency list for [shadow]. Exiting now..."
        echo "|> SCOPE: [core_routine], file [./scripts/packages/shadow-setup.sh]; check: 01"
        echo
        return 1
    fi
    echo "|> Successfully resolved dependency list for [shadow]. Proceeding..."
    echo "|> SCOPE: [core_routine], file [./scripts/packages/shadow-setup.sh]; check: 01"
    echo

    # generalize the install by replacing every placeholder with the desired dependency
    if ! (for f in $CORE_SHADOW_DEPS; do
        COREUPPER="$(echo "$f" | tr '[:lower:]' '[:upper:]')"
        export COREUPPER

        sed -e "s/PKGNAME_PKGDEPS_PLACEHOLDER/SHADOW_PKGDEPS_PLACEHOLDER/g" -e "s/PLACEHOLDER/$COREUPPER/g" -e "s/placeholder/$f/g" "${DEPSLIST:-[EMPTY_VARIABLE]}" >"/app/depslist-replaSED_$f.sh"
    done); then
        echo "|> Error: could not replace every PLACEHOLDER with the uppercase string of the name of the dependency and every lowercase with its counterpart. Exiting now..."
        echo "|> SCOPE: [core_routine], file [./scripts/packages/shadow-setup.sh]; check: 02"
        echo
        return 1
    fi
    echo "|> Successfully replaced every PLACEHOLDER with the uppercase string of the name of the dependency and every lowercase with its counterpart. Proceeding..."
    echo "|> SCOPE: [core_routine], file [./scripts/packages/shadow-setup.sh]; check: 02"
    echo

    # now use the extended regex [-r/-E] to replace hyphen between uppecase characters
    if ! (sed --in-place -E 's/([A-Z0-9])-([A-Z0-9])/\1_\2/g' /app/depslist-replaSED_*); then
        echo "|> Error: could not replace every hyphen between uppercase characters into an underscore with sed and extended regex [-r/-E]. Exiting now..."
        echo "|> SCOPE: [core_routine], file [./scripts/packages/shadow-setup.sh]; check: 03"
        return 1
    fi
    echo "|> Successfully replaced every hyphen between uppercase characters into an underscore with sed and extended regex [-r/-E]. Proceeding..."
    echo "|> SCOPE: [core_routine], file [./scripts/packages/shadow-setup.sh]; check: 03"

    #cat /app/plus.sh  | sed -e 's/[A-Z0-9]++/\1PP\2/g'
    if ! (sed -i -e 's/[A-Z0-9]++/\1PP\2/g' /app/depslist-replaSED_*); then
        #echo "|> Error: could not replace every plus sign by "
        echo "|> Error: could not replace every uppercase, followed by numbers, followed by plus sign, by PP"
        return 1
    fi
    echo "|> Error: Successfully replaced [--in-place] every uppercase, followed by numbers, followed by plus sign [++], by PP"

    ls -allhtr /app

    if ! (chmod +x -R /app/"depslist"*); then
        echo "|> Error: it was not possible to change file bits of execution permission [recursively] under [/app]. Exiting now..."
        echo "|> SCOPE: [core_routine], file [./scripts/packages/shadow-setup.sh]; check: 04"
        echo
        return 1
    fi
    echo "|> Sucessfully changed file bits of execution permission [recursively] under [/app]. Proceeding..."
    echo "|> SCOPE: [core_routine], file [./scripts/packages/shadow-setup.sh]; check: 04"
    echo

    ls -allhtr /app

}

set_shadow_deps() {

    if ! core_routine; then
        echo "|> Error: could not run the function [core_routine]. Exiting now..."
        echo "|> SCOPE: [set_shadow_deps], file [./scripts/packages/shadow-setup.sh]; check: 01"
        return 1
    fi
    echo "|> Successfully ran the function [core_routine]. Proceeding..."
    echo "|> SCOPE: [set_shadow_deps], file [./scripts/packages/shadow-setup.sh]; check: 01"

    #ls -allhtr /app | awk '{print $10}'
    find /app \( -iname '*depslist-replaSED_*.sh' \)

    ALL_SCRIPTS="$(find /app \( -iname '*depslist-replaSED_*.sh' \))"

    for jooj in $ALL_SCRIPTS; do
        if ! (/bin/sh -c "$jooj"); then
            echo "|> Error: it was not possible to resolve dependency list for [$jooj]. Exiting now..."
            echo "|> SCOPE: [set_shadow_deps], file [./scripts/packages/shadow-setup.sh]; "
            return 1
        fi
        echo "|> Sucessfully resolved dependency list for [$jooj]. Proceeding..."
    done

    #### CORE_SCRIPTS="$(ls /app)"
}

# single tarball
set_shadow_tarball() {

    if ! set_shadow_deps; then
        echo "|> Error: it was not possible to resolve [shadow] dependencies. Exiting now..."
        echo "|> SCOPE: [set_shadow_tarball], file [./scripts/packages/shadow-setup.sh]; check: 01"
        return 1
    fi
    echo "|> Successfully resolved [shadow] dependencies. Proceeding..."
    echo "|> SCOPE: [set_shadow_tarball], file [./scripts/packages/shadow-setup.sh]; check: 01"

    # set IFS: input field separator
    #IFS='\n\t'
    IFS=$(printf '\n\t')

    # read each line defining the input field separator,
    # follow the soft link and append readlink output line to a new file
    while IFS= read -r line; do
        readlink -f "$line" >>/bar.txt
    done </foo.txt

    # remove new lines on the lists, then create new file
    sed '/^$/d' /foo.txt >/foobar.txt
    sed '/^$/d' /bar.txt >>/foobar.txt

    # then remove duplicate shared objects
    sort /foobar.txt | uniq >/quux.txt

    # generate a tarball of shared objects from filepaths on a text file
    # tar -czf /shadow-single-pkg.tar.gz -T /quux.txt
    tar -czf /shadow-tarball-pkg.tar.gz -T /quux.txt

}

### set_shadow_so() {
###
###     # doas shared objects
###     ldd "$(readlink -f "$(which "doas")")" | awk '{print $3}' >>/foo.txt
###
###     # shadow shared objects
###     for f in /usr/sbin/*; do
###         case $f in
###         /usr/sbin/chage) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
###         /usr/sbin/chfn) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
###         /usr/sbin/chgpasswd) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
###         /usr/sbin/chpasswd) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
###         /usr/sbin/chsh) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
###         /usr/sbin/expiry) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
###         /usr/sbin/gpasswd) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
###         /usr/sbin/groupadd) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
###         /usr/sbin/groupdel) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
###         /usr/sbin/groupmems) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
###         /usr/sbin/groupmod) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
###         /usr/sbin/grpck) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
###         /usr/sbin/logoutd) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
###         /usr/sbin/newusers) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
###         /usr/sbin/passwd) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
###         /usr/sbin/pwck) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
###         /usr/sbin/useradd) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
###         /usr/sbin/userdel) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
###         /usr/sbin/usermod) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
###         /usr/sbin/vigr) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
###         /usr/sbin/vipw) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
###
###         esac
###     done
###
###     # other dependencies shared objects
###     for f in /usr/lib/*; do
###         case $f in
###         # musl
###         /usr/lib/libc.musl-x86*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
###         # linux-pam deps
###         /usr/lib/libpam*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
###         #/usr/lib/libpam_misc*) ldd "$(readlink -f "$(which "$f")")"        | awk '{print $3}' >> /foo.txt ;;
###         #/usr/lib/libpamc*) ldd "$(readlink -f "$(which "$f")")"            | awk '{print $3}' >> /foo.txt ;;
###
###         # utmps-libs shared objects
###         /usr/lib/libutm*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
###         # libbsd deps
###         /usr/lib/libbsd*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
###         /usr/lib/libmd*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
###         # skalibs-libs
###         /usr/lib/libskarnet*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
###
###         esac
###     done
###
###     # linux-pam shared objects
###     for f in /usr/sbin/*; do
###         case $f in
###         # pam dynamicaly linked user binaries
###         /usr/sbin/chage) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
###         /usr/sbin/faillock) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
###         /usr/sbin/mkhomedir_helper) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
###         /usr/sbin/pam_namespace_helper) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
###         /usr/sbin/pam_timestamp_check) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
###         /usr/sbin/pwhistory_helper) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
###         /usr/sbin/unix_chkpwd) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
###
###         esac
###     done
###
###     # set IFS: input field separator
###     #IFS='\n\t'
###     IFS=$(printf '\n\t')
###
###     # read each line defining the input field separator,
###     # follow the soft link and append readlink output line to a new file
###     while IFS= read -r line; do
###         readlink -f "$line" >>/bar.txt
###     done </foo.txt
###
###     # remove new lines on the lists, then create new file
###     sed '/^$/d' /foo.txt >/foobar.txt
###     sed '/^$/d' /bar.txt >>/foobar.txt
###
###     # then remove duplicate shared objects
###     sort /foobar.txt | uniq >/quux.txt
###
###     # generate a tarball of shared objects from filepaths on a text file
###     tar -czf /shadow-so-pkg.tar.gz -T /quux.txt
###
### }
###
### set_shadow_bin() {
###     (
###         cat <<EOL
### chage
### chfn
### chgpasswd
### chpasswd
### chsh
### expiry
### gpasswd
### groupadd
### groupdel
### groupmems
### groupmod
### grpck
### logoutd
### newusers
### passwd
### pwck
### useradd
### userdel
### usermod
### vigr
### vipw
### chage
### faillock
### mkhomedir_helper
### pam_namespace_helper
### pam_timestamp_check
### pwhistory_helper
### unix_chkpwd
### EOL
###     ) | tee /shadow-list.txt
###
###     (
###         cat <<EOL
### faillock
### mkhomedir_helper
### pam_namespace_helper
### pam_timestamp_check
### pwhistory_helper
### unix_chkpwd
### EOL
###     ) | tee /libpam-list.txt
###
###     # set IFS: input field separator
###     IFS=$(printf '\n\t')
###
###     # read each line defining the input field separator,
###     # follow the soft link and append readlink output line to a new file
###     while IFS= read -r line; do
###         readlink -f "$(which "$line")" >>/shadow-bin-bar.txt
###     done </shadow-list.txt
###
###     # set the libpam-list alongside shadow-bin-bar just to leverage the others.
###     while IFS= read -r line; do
###         readlink -f "$(which "$line")" >>/shadow-bin-bar.txt
###     done </libpam-list.txt
###
###     # set IFS: input field separator
###     IFS=$(printf '\n\t')
###
###     # remove new lines on the lists, then create new file
###     sed '/^$/d' /shadow-bin-bar.txt >/shadow-bin-foobar.txt &&
###         #sed '/^$/d' /bar.txt >> /foobar.txt
###
###         # then remove duplicate shared objects
###         sort /shadow-bin-foobar.txt | uniq >/shadow-bin-quux.txt &&
###
###         # generate a tarball of shared objects from filepaths on a text file
###         tar -czf /shadow-bin-pkg.tar.gz -T /shadow-bin-quux.txt
###
### }

print_usage() {
    cat <<-END >&2
USAGE: shadow.sh [-options]
                - shadow-tarball
                - version
                - help
eg,
MODE="shadow-so"    ./shadow.sh   # setup shadow shared objects
MODE="shadow-bin"   ./shadow.sh   # setup shadow (musl) dynamically linked binaries
MODE="version"      ./shadow.sh   # shows script version
MODE="help"         ./shadow.sh   # shows this help message

See the man page and example file for more info.

END

}

# Check the argument passed from the command line
if ! [ -z "${MODE}" ] &&
    [ "${MODE}" = "shadow-so" ] ||
    [ "${MODE}" = "shadow-bin" ]; then
    case "${MODE}" in
    "shadow-so") set_shadow_so ;;
    "shadow-bin") set_shadow_bin ;;
    *)
        echo "Invalid microvm. Please specify one of: shadow-so, shadow-bin"
        print_usage
        ;;
    esac

elif [ "${MODE}" = "help" ] || [ "${MODE}" = "-h" ] || [ "${MODE}" = "--help" ]; then
    print_usage
elif [ "${MODE}" = "version" ] || [ "${MODE}" = "-v" ] || [ "${MODE}" = "--version" ]; then
    printf "\n|> Version: shadow-setup 1.0.0"
else
    echo "Invalid function name. Please specify one of the available functions:"
    print_usage
fi
