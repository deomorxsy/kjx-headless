#!/bin/sh

set_shadow_so() {

    # doas shared objects
    ldd "$(readlink -f "$(which "doas")")" | awk '{print $3}' >>/foo.txt

    # shadow shared objects
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
    tar -czf /shadow-so-pkg.tar.gz -T /quux.txt

}

set_shadow_bin() {
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
    ) | tee /shadow-list.txt

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
        readlink -f "$(which "$line")" >>/shadow-bin-bar.txt
    done </shadow-list.txt

    # set the libpam-list alongside shadow-bin-bar just to leverage the others.
    while IFS= read -r line; do
        readlink -f "$(which "$line")" >>/shadow-bin-bar.txt
    done </libpam-list.txt

    # set IFS: input field separator
    IFS=$(printf '\n\t')

    # remove new lines on the lists, then create new file
    sed '/^$/d' /shadow-bin-bar.txt >/shadow-bin-foobar.txt &&
        #sed '/^$/d' /bar.txt >> /foobar.txt

        # then remove duplicate shared objects
        sort /shadow-bin-foobar.txt | uniq >/shadow-bin-quux.txt &&

        # generate a tarball of shared objects from filepaths on a text file
        tar -czf /shadow-bin-pkg.tar.gz -T /shadow-bin-quux.txt

}

print_usage() {
    cat <<-END >&2
USAGE: shadow.sh [-options]
                - shadow-so
                - shadow-bin
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
