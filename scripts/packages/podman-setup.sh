#!/bin/sh

set_podman_deps() {

    # Depends (13)
    # conmon
    # oci-runtime
    # passt
    # shadow-subids
    # containers-common
    # netavark
    # aardvark-dns
    # catatonit
    # /bin/sh
    # so:libc.musl-x86.so.1
    # so:libgpgme.so.11
    # so:libseccomp.so.2
    # so:libsqlite3.so.0

    # conmon
    for f in /usr/sbin/*; do
        case $f in
        /usr/sbin/conmon) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        esac
    done

    # oci-runtime
    ## cmd provided: oci-runtime, crun
    for f in /usr/sbin/*; do
        case $f in
        /usr/sbin/oci-runtime) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/crun) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        esac
    done

    # passt
    ## CMD provided: passt-repair, passt, pasta, qrap
    for f in /usr/sbin/*; do
        case $f in
        /usr/sbin/passt-repair) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/passt) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/pasta) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/qrap) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        esac
    done

    # shadow-subids
    # containers-common
    # netavark
    # aardvark-dns
    # catatonit
    # /bin/sh
    # so:libc.musl-x86.so.1
    # so:libgpgme.so.11
    # so:libseccomp.so.2
    # so:libsqlite3.so.0

}

set_podman_so() {

    # podman commands
    for f in /usr/sbin/*; do
        case $f in
        /usr/sbin/podman) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/podmansh) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        esac
    done

    # doas shared objects
    ldd "$(readlink -f "$(which "doas")")" | awk '{print $3}' >>/foo.txt

    # podman shared objects
    for f in /usr/sbin/*; do
        case $f in
        /usr/sbin/chage) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/chfn) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/chgpasswd) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/chpasswd) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/chsh) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/expiry) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/gpasswd) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/groupadd) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/groupdel) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/groupmems) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/groupmod) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/grpck) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/logoutd) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/newusers) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/passwd) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/pwck) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/useradd) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/userdel) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/usermod) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/vigr) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/vipw) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;

        esac
    done

    # other dependencies shared objects
    for f in /usr/lib/*; do
        case $f in
        # musl
        /usr/lib/libc.musl-x86*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        # linux-pam deps
        /usr/lib/libpam*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        #/usr/lib/libpam_misc*) ldd "$(readlink -f "$(which "$f")")"        | awk '{print $3}' >> /foo.txt ;;
        #/usr/lib/libpamc*) ldd "$(readlink -f "$(which "$f")")"            | awk '{print $3}' >> /foo.txt ;;

        # utmps-libs shared objects
        /usr/lib/libutm*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        # libbsd deps
        /usr/lib/libbsd*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/lib/libmd*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        # skalibs-libs
        /usr/lib/libskarnet*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;

        esac
    done

    # linux-pam shared objects
    for f in /usr/sbin/*; do
        case $f in
        # pam dynamicaly linked user binaries
        /usr/sbin/chage) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/faillock) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/mkhomedir_helper) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/pam_namespace_helper) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/pam_timestamp_check) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/pwhistory_helper) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/unix_chkpwd) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;

        esac
    done

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
    tar -czf /podman-so-pkg.tar.gz -T /quux.txt

}

set_podman_bin() {
    (
        cat <<EOL
chage
chfn
chgpasswd
chpasswd
chsh
expiry
gpasswd
groupadd
groupdel
groupmems
groupmod
grpck
logoutd
newusers
passwd
pwck
useradd
userdel
usermod
vigr
vipw
chage
faillock
mkhomedir_helper
pam_namespace_helper
pam_timestamp_check
pwhistory_helper
unix_chkpwd
EOL
    ) | tee /podman-list.txt

    (
        cat <<EOL
faillock
mkhomedir_helper
pam_namespace_helper
pam_timestamp_check
pwhistory_helper
unix_chkpwd
EOL
    ) | tee /libpam-list.txt

    # set IFS: input field separator
    IFS=$(printf '\n\t')

    # read each line defining the input field separator,
    # follow the soft link and append readlink output line to a new file
    while IFS= read -r line; do
        readlink -f "$(which "$line")" >>/podman-bin-bar.txt
    done </podman-list.txt

    # set the libpam-list alongside podman-bin-bar just to leverage the others.
    while IFS= read -r line; do
        readlink -f "$(which "$line")" >>/podman-bin-bar.txt
    done </libpam-list.txt

    # set IFS: input field separator
    IFS=$(printf '\n\t')

    # remove new lines on the lists, then create new file
    sed '/^$/d' /podman-bin-bar.txt >/podman-bin-foobar.txt &&
        #sed '/^$/d' /bar.txt >> /foobar.txt

        # then remove duplicate shared objects
        sort /podman-bin-foobar.txt | uniq >/podman-bin-quux.txt &&

        # generate a tarball of shared objects from filepaths on a text file
        tar -czf /podman-bin-pkg.tar.gz -T /podman-bin-quux.txt

}

print_usage() {
    cat <<-END >&2
USAGE: podman-setup.sh [-options]
                - podman-so
                - podman-bin
                - version
                - help
eg,
MODE="podman-so"    ./podman-setup.sh   # setup podman shared objects
MODE="podman-bin"   ./podman-setup.sh   # setup podman (musl) dynamically linked binaries
MODE="version"      ./podman-setup.sh   # shows script version
MODE="help"         ./podman-setup.sh   # shows this help message

See the man page and example file for more info.

END

}

# Check the argument passed from the command line
if ! [ -z "${MODE}" ] &&
    [ "${MODE}" = "podman-so" ] ||
    [ "${MODE}" = "podman-bin" ]; then
    case "${MODE}" in
    "podman-so") set_podman_so ;;
    "podman-bin") set_podman_bin ;;
    *)
        echo "Invalid microvm. Please specify one of: podman-so, podman-bin"
        print_usage
        ;;
    esac

elif [ "${MODE}" = "help" ] || [ "${MODE}" = "-h" ] || [ "${MODE}" = "--help" ]; then
    print_usage
elif [ "${MODE}" = "version" ] || [ "${MODE}" = "-v" ] || [ "${MODE}" = "--version" ]; then
    printf "\n|> Version: podman-setup 1.0.0"
else
    echo "Invalid function name. Please specify one of the available functions:"
    print_usage
fi

old_deps() {
    ldd "$(readlink -f "$(which conmon)")" | awk '{print $3}' >>/foo.txt
    ldd "$(readlink -f "$(which podman)")" | awk '{print $3}' >>/foo.txt

    ldd "$(readlink -f /usr/libexec/podman/netavark)" | awk '{print $3}' >>/foo.txt
    ldd "$(readlink -f /usr/libexec/podman/aardvark-dns)" | awk '{print $3}' >>/foo.txt
    ldd "$(readlink -f /usr/libexec/podman/rootlessport)" | awk '{print $3}' >>/foo.txt

    # since catatonit is a static binary
    echo "$(readlink -f /usr/libexec/podman/catatonit)" >>/foo.txt

    # if [ -d /usr/libexec/podman ]; then
    #
    # fi

    # crun support
    ldd "$(readlink -f "$(which crun)")" | awk '{print $3}' >>/foo.txt

}
#
