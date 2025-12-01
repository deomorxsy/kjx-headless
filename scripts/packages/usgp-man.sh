#!/bin/sh
# usgp-man: user-group management
#

SHADOW_PKG_URI="https://github.com/shadow-maint/shadow/releases/download/4.18.0/shadow-4.18.0.tar.xz"

set_network() {

    CCR_MODE="-checker" . ./scripts/ccr.sh && \
        docker compose -f ./compose.yml --progress=plain build --no-cache qonq-iptables

}

set_shadow() {

    CCR_MODE="-checker" . ./scripts/ccr.sh && \
        docker compose -f ./compose.yml --progress=plain build --no-cache qonq-shadow

echo
}

main_usgp_man() {

if ! set_shadow; then
    return 1
fi
echo "|> shadow setup with success."
}

print_usage() {
cat <<-END >&2
USAGE: usgp-man [-options]
                - shadow
                - firecracker
                - gvisor
                - kata
                - version
                - help
eg,
MODE="all"          ./usgp-man.sh   # Fetch all default dependencies
MODE="shadow"       ./usgp-man.sh   # Setup firecracker as main microvm
MODE="network"      ./usgp-man.sh   # Setup gvisor as main microvm
MODE="kata"         ./usgp-man.sh   # Setup kata-containers as main microvm
MODE="version"      ./usgp-man.sh   # shows script version
MODE="help"         ./usgp-man.sh   # shows this help message

See the man page and example file for more info.

END

}


# Check the argument passed from the command line
if ! [ -z "${MODE}" ] && \
    [ "${MODE}" = "shadow" ] || \
    [ "${MODE}" = "network" ] || \
    [ "${MODE}" = "all" ]; then
    case "${MODE}" in
        "all")
            main_usgp_man
            ;;
        "shadow")
            set_shadow
            ;;
        "network")
            set_iptables # iptables, conntrack, etc
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


