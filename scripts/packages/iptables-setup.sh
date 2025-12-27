#!/bin/sh

PACKAGES_DIR="/app/artifacts/distro/packages"
BUILD_DIR="/app/build"
IPTABLES_TARBALL="https://www.netfilter.org/projects/iptables/files/iptables-1.8.11.tar.xz"
LIBPCAP_TARBALL="https://www.tcpdump.org/release/libpcap-1.10.5.tar.gz"
LIBNFNETLINK_TARBALL=""

# git based
LIBNETFILTER_CONNTRACK_GIT_URI="https://git.netfilter.org/libnetfilter_conntrack/"

# nftables project and its dependencies
LIBNFTNL_GIT_URI="git://git.netfilter.org/libnftnl"
NFTABLES_TARBALL=""

core_routine() {
    mkdir -p /app/scripts/packages

    DEPSLIST="/app/scripts/packages/demo-replased.sh"
    export DEPSLIST

    CORE_IPTABLES_DEPS="$(
        # apk dot iptables --installed | grep -v "shape=box" | grep -v "rankdir=LR" | grep -v "digraph" | awk '{print $1}' | sed -E 's/-[0-9].*$//' | tr -d '"' | tr -d "}" | sort -u

        apk dot libmnl libnftnl libxtables \
            ip6tables iptables conntrack-tools \
            libnetfilter_conntrack libnetfilter_cthelper \
            libnetfilter_cttimeout libnetfilter_queue \
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
    export CORE_IPTABLES_DEPS

    ### CORE_IPTABLES_DEPS="
    # busybox
    ### busybox-binsh
    ### conntrack-tools
    ### iptables
    ### libmnl
    ### libnetfilter_conntrack
    ### libnetfilter_cthelper
    ### libnetfilter_cttimeout
    ### libnetfilter_queue
    ### libnfnetlink
    ### libnftnl
    ### libxtables
    ### "

    if ! [ -f "${DEPSLIST:-[EMPTY_VARIABLE]}" ]; then

        # cp
        echo "|> Error: it was not possible to resolve dependency list for [iptables-setup]. Exiting now..."
        echo "|> SCOPE: [core_routine], file [./scripts/packages/iptables-setup.sh]; check: 01"
        echo
        return 1
    fi
    echo "|> Successfully resolved dependency list for [iptables-setup]. Proceeding..."
    echo "|> SCOPE: [core_routine], file [./scripts/packages/iptables-setup.sh]; check: 01"
    echo

    # generalize the install by replacing every placeholder with the desired dependency
    if ! (for f in $CORE_IPTABLES_DEPS; do
        COREUPPER="$(echo "$f" | tr '[:lower:]' '[:upper:]')"
        export COREUPPER

        sed -e "s/PKGNAME_PKGDEPS_PLACEHOLDER/IPTABLES_PKGDEPS_PLACEHOLDER/g" -e "s/PLACEHOLDER/$COREUPPER/g" -e "s/placeholder/$f/g" "${DEPSLIST:-[EMPTY_VARIABLE]}" >"/app/depslist-replaSED_$f.sh"
    done); then
        echo "|> Error: could not replace every PLACEHOLDER with the uppercase string of the name of the dependency and every lowercase with its counterpart. Exiting now..."
        echo "|> SCOPE: [core_routine], file [./scripts/packages/iptables-setup.sh]; check: 02"
        echo
        return 1
    fi
    echo "|> Successfully replaced every PLACEHOLDER with the uppercase string of the name of the dependency and every lowercase with its counterpart. Proceeding..."
    echo "|> SCOPE: [core_routine], file [./scripts/packages/iptables-setup.sh]; check: 02"
    echo

    # echo "IPTABLES_PKGDEPS_LLVM20-LIBS" | sed -E 's/([A-Z0-9])-([A-Z0-9])/\1_\2/g'
    # |> IPTABLES_PKGDEPS_LLVM20_LIBS
    # if ! (sed -i -E 's/([A-Z])-([A-Z])/\1_\2/g' /app/depslist-replaSED_*); then
    #
    # now use the extended regex [-r/-E] to replace hyphen between uppecase characters
    if ! (sed --in-place -E 's/([A-Z0-9])-([A-Z0-9])/\1_\2/g' /app/depslist-replaSED_*); then
        echo "|> Error: could not replace every hyphen between uppercase characters into an underscore with sed and extended regex [-r/-E]. Exiting now..."
        echo "|> SCOPE: [core_routine], file [./scripts/packages/iptables-setup.sh]; check: 03"
        return 1
    fi
    echo "|> Successfully replaced every hyphen between uppercase characters into an underscore with sed and extended regex [-r/-E]. Proceeding..."
    echo "|> SCOPE: [core_routine], file [./scripts/packages/iptables-setup.sh]; check: 03"

    #cat /app/plus.sh  | sed -e 's/[A-Z0-9]++/\1PP\2/g'
    if ! (sed -i -e 's/[A-Z0-9]++/\1PP\2/g' /app/depslist-replaSED_*); then
        echo "|> Error: could not replace every uppercase, followed by numbers, followed by plus sign, by PP"
        return 1
    fi
    echo "|> Error: Successfully replaced [--in-place] every uppercase, followed by numbers, followed by plus sign [++], by PP"

    ls -allhtr /app

    if ! (chmod +x -R /app/"depslist"*); then
        echo "|> Error: it was not possible to change file bits of execution permission [recursively] under [/app]. Exiting now..."
        echo "|> SCOPE: [core_routine], file [./scripts/packages/iptables-setup.sh]; check: 04"
        echo
        return 1
    fi
    echo "|> Sucessfully changed file bits of execution permission [recursively] under [/app]. Proceeding..."
    echo "|> SCOPE: [core_routine], file [./scripts/packages/iptables-setup.sh]; check: 04"
    echo

    ls -allhtr /app

}

set_iptables_tarball() {
    if ! set_iptables_deps; then
        echo "|> Error: it was not possible to resolve iptables dependencies. Exiting now..."
        echo "|> SCOPE: [set_iptables], file [./scripts/packages/iptables-setup.sh]; check: 01"
        return 1
    fi
    echo "|> Successfully resolved iptables dependencies. Proceeding..."
    echo "|> SCOPE: [set_iptables], file [./scripts/packages/iptables-setup.sh]; check: 01"

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
    # tar -czf /iptables-single-pkg.tar.gz -T /quux.txt
    tar -czf /iptables-tarball-pkg.tar.gz -T /quux.txt

}

set_iptables_so() {

    # iptables
    # libmnl:Library for minimalistic netlink
    # libnftnl: Netfilter library providing interface to the nf_tables subsystem
    # libxtables: Linux kernel firewall, NAT and packet mangling tools (xtables library)
    # iptables: Linux kernel firewall, NAT and packet mangling tools
    # conntrack-tools: Connection tracking userspace tools

    #conntrack
    # libnetfilter_cthelper: A Netfilter netlink library for connection tracking helpers
    # libnetfilter_cttimeoutconntrack: Library for the connection tracking timeout infrastructure
    # libnetfilter_queue: API to packets that have been queued by the kernel packet filter
    # libnfnetlink: low-level library for netfilter related kernel/userspace communication

    # shared objects
    for f in /usr/lib/*; do
        case $f in
        # musl
        /usr/lib/libc.musl-x86*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;

        esac
    done

    # conntrack shared objects
    for f in /usr/lib/*; do
        case $f in
        /usr/lib/libc.musl-x86*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/lib/libmnl*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/lib/libnetfilter_conntrack*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/lib/libnetfilter_cthelper*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/lib/libnetfilter_cttimeout*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/lib/libnetfilter_queue*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/lib/libnfnetlink*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        esac
    done

    # binary shared objects provided by netfilter
    for f in /usr/sbin/*; do
        case $f in
        /usr/sbin/chage) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/ip6tables*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/ebtables*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/arptables-nft-restore*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/arptables-nft-save*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/arptables-nft*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/arptables-restore*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/arptables-save*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/arptables-translate*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/arptables*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/ebtables-nft-restore*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/ebtables-nft-save*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/ebtables-nft*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/ebtables-restore*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/ebtables-save*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/ebtables-translate*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/ebtables*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/ip6tables-apply*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/ip6tables-nft-restore*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/ip6tables-nft-save*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/ip6tables-nft*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/ip6tables-restore-translate*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/ip6tables-restore*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/ip6tables-save*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/ip6tables-translate*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/ip6tables*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/iptables-apply*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/iptables-nft-restore*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/iptables-nft-save*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/iptables-nft*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/iptables-restore-translate*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/iptables-restore*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/iptables-save*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/iptables-translate*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/iptables*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/xtables-monitor*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/xtables-nft-multi*) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;

        esac
    done

    # so:libmnl.so.0
    # # Netfilter library providing interface to the nf_tables subsystem
    # libnftnl-libs
    # so:libnftnl.so.11
    # so:libxtables.so.12

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
    tar -czf /app/iptables-so-pkg.tar.gz -T /quux.txt

}
set_iptables_bin() {
    (
        cat <<EOL
ip6tables
ebtables
arptables-nft-restore
arptables-nft-save
arptables-nft
arptables-restore
arptables-save
arptables-translate
arptables
ebtables-nft-restore
ebtables-nft-save
ebtables-nft
ebtables-restore
ebtables-save
ebtables-translate
ebtables
ip6tables-apply
ip6tables-nft-restore
ip6tables-nft-save
ip6tables-nft
ip6tables-restore-translate
ip6tables-restore
ip6tables-save
ip6tables-translate
ip6tables
iptables-apply
iptables-nft-restore
iptables-nft-save
iptables-nft
iptables-restore-translate*
iptables-restore
iptables-save
iptables-translate
iptables
xtables-monitor
xtables-nft-multi
EOL
    ) | tee /iptables-list.txt

    # set IFS: input field separator
    IFS=$(printf '\n\t')

    # read each line defining the input field separator,
    # follow the soft link and append readlink output line to a new file
    while IFS= read -r line; do
        readlink -f "$(which "$line")" >>/iptables-bin-bar.txt
    done </iptables-list.txt

    # set IFS: input field separator
    IFS=$(printf '\n\t')

    # remove new lines on the lists, then create new file
    sed '/^$/d' /iptables-bin-bar.txt >/iptables-bin-foobar.txt &&
        #sed '/^$/d' /bar.txt >> /foobar.txt

        # then remove duplicate shared objects
        sort /iptables-bin-foobar.txt | uniq >/iptables-bin-quux.txt &&

        # generate a tarball of shared objects from filepaths on a text file
        tar -czf /app/iptables-bin-pkg.tar.gz -T /iptables-bin-quux.txt

}

env_runner() {
    podman run \
        --rm \
        -it \
        --entrypoint=/bin/sh \
        alpine:3.22
}

fetch_all() {

    wget -P "$PACKAGES_DIR" "$IPTABLES_TARBALL"
    wget -P "$PACKAGES_DIR" "$LIBPCAP_TARBALL"
    wget -P "$PACKAGES_DIR" "$LIBNFNETLINK_TARBALL"
    wget -P "$PACKAGES_DIR" "$LIBNETFILTER_CONNTRACK_URI"
    wget -P "$PACKAGES_DIR" "$IPTABLES_TARBALL"
    wget -P "$PACKAGES_DIR" "$IPTABLES_TARBALL"

}

# BPF compiler or nfsynproxy support
# libpcap-1.10.5
set_libpcap() {

    if ! [ -d "$PACKAGES_DIR/iptables-1.8.11/" ]; then
        wget -P "$PACKAGES_DIR" "$IPTABLES_TARBALL"
        cd "$PACKAGES_DIR" || return
        tar -xvf ./iptables-1.8.11.tar.xz
        cd - || return
        #
        conf_gen
    else
        conf_gen
    fi

    cd "${PACKAGES_DIR}/iptables-1.8.11/" || return

    ./configure --prefix=/usr &&
        make
}
# Berkeley Packet Filter support
# bpf-utils
set_bpf_utils() {
    echo
}

# connlabel support
# libnfnetlink
# low-level library for netfilter related kernel/userspace communication.
# It provides a generic messaging infrastructure for in-kernel netfilter
# subsystems and their respective users and/or management tools in userspace.
set_libnfnetlink() {
    # useful for
    # - nfnetlink_log
    # - nfnetlink_queue
    # - nfnetlink_conntrack
    cd "$PACKAGES_DIR" || return
    git clone https://git.netfilter.org/libnfnetlink/
    cd - || return

    cd "${PACKAGES_DIR}"/libnfnetlink || return
    ./autogen.sh &&
        ./configure

    cd - || return
}

# connlabel support
# libnetfilter_conntrack
set_libnetfilter_conntrack() {
    echo
}

# nftables
set_nftables() {

    # dependencies
    cd "${PACKAGES_DIR}" || return
    git clone "${LIBNFTNL_GIT_URI}"
    cd - || return

    cd "${PACKAGES_DIR}/libnftnl" || return &&
        sh autogen.sh &&
        ./configure &&
        make
    #sudo make install
    cd - || return

}

main_iptables() {

    if ! set_libpcap; then
        return 1
    fi
    printf "|> libcap setup with success!\n\n"

    if ! set_bpf_utils; then
        return 1
    fi
    printf "|> bpf-utils setup with success!\n\n"

    if ! set_libnfnetlink; then
        return 1
    fi
    printf "|>  libnfnetlink setup with success!\n\n"

    if ! set_libnetfilter_conntrack; then
        return 1
    fi
    printf "|> libnetfilter_conntrack setup with success!\n\n"

    if ! [ -d "$PACKAGES_DIR/iptables-1.8.11/" ]; then
        wget -P "$PACKAGES_DIR" "$IPTABLES_TARBALL"
        cd "$PACKAGES_DIR" || return
        tar -xvf ./iptables-1.8.11.tar.xz
        cd - || return
        #
        conf_gen
    else
        conf_gen
    fi

    export CFLAGS="-g -O2 -pipe -D_LINUX_IF_ETHER_H"
    cd "${PACKAGES_DIR}/iptables-1.8.11/" || return
    ./configure --prefix=/usr \
        --disable-nftables \
        --enable-libipq &&
        make

    # as root
    make install
    cd - || return

}

# libpcap
# bpf-utils
# libnfnetlink
# connlabel
# libnetfilter_conntrack
# nftables

# # Check the argument passed from the command line
# if ! [ -z "${MODE}" ] && \
#     [ "${MODE}" = "libpcap" ] || \
#     [ "${MODE}" = "bpf-utils" ] || \
#     [ "${MODE}" = "nftables" ] || \
#     [ "${MODE}" = "conntrack" ] || \
#     [ "${MODE}" = "libnetfilter_conntrack" ] || \
#     [ "${MODE}" = "libnfnetlink" ] || \
#     [ "${MODE}" = "iptables-setup" ]; then
#     case "${MODE}" in
#         "libpcap")
#             set_libpcap
#             ;;
#         "bpf-utils")
#             set_bpf-utils
#             ;;
#         "nftables")
#             set_nftables
#             ;;
#         "conntrack")
#             set_conntrack
#             ;;
#         "libnetfilter_conntrack")
#             set_libnetfilter_conntrack
#             ;;
#         "libnfnetlink")
#             set_libnfnetlink
#             ;;
#         "iptables-setup")
#             main_iptables
#             ;;
#         *)
#             echo "Invalid microvm. Please specify one of: firecracker, gvisor, kata"
#             print_usage
#             ;;
#     esac
#
# elif [ "${MODE}" = "help" ] || [ "${MODE}" = "-h" ] || [ "${MODE}" = "--help" ]; then
#     print_usage
# elif [ "${MODE}" = "version" ] || [ "${MODE}" = "-v" ] || [ "${MODE}" = "--version" ]; then
#     printf "\n|> Version: iptables-setup 1.0.0"
# else
#     echo "Invalid function name. Please specify one of the available functions:"
#     print_usage
# fi

print_usage() {
    cat <<-END >&2
USAGE: iptables-setup.sh [-options]
                - iptables-so
                - iptables-bin
                - version
                - help
eg,
MODE="iptables-so"    ./iptables.sh   # setup iptables (linked with musl) shared objects
MODE="iptables-bin"   ./iptables.sh   # setup iptables (linked with musl) dynamically linked binaries
MODE="version"      ./iptables-setup.sh   # shows script version
MODE="help"         ./iptables-setup.sh   # shows this help message

See the man page and example file for more info.

END

}

# Check the argument passed from the command line
if ! [ -z "${MODE}" ] &&
    [ "${MODE}" = "iptables-so" ] ||
    [ "${MODE}" = "iptables-bin" ]; then
    case "${MODE}" in
    "iptables-so") set_iptables_so ;;
    "iptables-bin") set_iptables_bin ;;
    *)
        echo "Invalid microvm. Please specify one of: iptables-so, iptables-bin"
        print_usage
        ;;
    esac

elif [ "${MODE}" = "help" ] || [ "${MODE}" = "-h" ] || [ "${MODE}" = "--help" ]; then
    print_usage
elif [ "${MODE}" = "version" ] || [ "${MODE}" = "-v" ] || [ "${MODE}" = "--version" ]; then
    printf "\n|> Version: iptables-setup 1.0.0"
else
    echo "Invalid function name. Please specify one of the available functions:"
    print_usage
fi
