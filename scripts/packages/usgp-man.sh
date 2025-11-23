#!/bin/sh
# usgp-man: user-group management
#

SHADOW_PKG_URI="https://github.com/shadow-maint/shadow/releases/download/4.18.0/shadow-4.18.0.tar.xz"


set_shadow() {
echo
}
main_usgp_man() {
echo
}

print_usage() {
cat <<-END >&2
USAGE: usgp-man [-options]
                - usgp-man
                - firecracker
                - gvisor
                - kata
                - version
                - help
eg,
MODE="usgp-man" ./usgp-man.sh   # Fetch dependencies for all-in-one usgp-man
MODE="firecracker"  ./usgp-man.sh   # Setup firecracker as main microvm
MODE="gvisor"       ./usgp-man.sh   # Setup gvisor as main microvm
MODE="kata"         ./usgp-man.sh   # Setup kata-containers as main microvm
MODE="version"      ./usgp-man.sh   # shows script version
MODE="help"         ./usgp-man.sh   # shows this help message

See the man page and example file for more info.

END

}


# Check the argument passed from the command line
if ! [ -z "${MODE}" ] && \
    [ "${MODE}" = "usgp-man-aio" ] || \
    [ "${MODE}" = "nftables" ] || \
    [ "${MODE}" = "conntrack" ] || \
    [ "${MODE}" = "kata" ]; then
    case "${MODE}" in
        "usgp-man")
            mvm_aio
            ;;
        "firecracker")
            mvm_firecracker
            ;;
        "gvisor")
            mvm_gvisor
            ;;
        "kata")
            mvm_kata
            ;;
        *)
            echo "Invalid microvm. Please specify one of: firecracker, gvisor, kata"
            print_usage
            ;;
    esac

elif [ "${MODE}" = "help" ] || [ "${MODE}" = "-h" ] || [ "${MODE}" = "--help" ]; then
    print_usage
elif [ "${MODE}" = "version" ] || [ "${MODE}" = "-v" ] || [ "${MODE}" = "--version" ]; then
    printf "\n|> Version: usgp-man 1.0.0"
else
    echo "Invalid function name. Please specify one of the available functions:"
    print_usage
fi


