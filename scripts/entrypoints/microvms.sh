#!/bin/sh

mvm_aio() {

    MODE="microvm, hlcr" STACK="firecracker, podman" . ./scripts/qonq-qdb.sh
}

mvm_firecracker() {

    MODE="microvm, hlcr" STACK="firecracker, podman" . ./scripts/qonq-qdb.sh
}

mvm_gvisor() {

    MODE="microvm, hlcr" STACK="gvisor, podman" . ./scripts/qonq-qdb.sh
}

mvm_kata() {

    MODE="microvm, hlcr" STACK="kata, podman" . ./scripts/qonq-qdb.sh
}

print_usage() {
cat <<-END >&2
USAGE: microvms [-options]
                - microvms-aio
                - firecracker
                - gvisor
                - kata
                - version
                - help
eg,
MODE="microvms-aio" . microvms.sh   # Fetch dependencies for all-in-one microvms
MODE="firecracker"  . microvms.sh   # Setup firecracker as main microvm
MODE="gvisor"       . microvms.sh   # Setup gvisor as main microvm
MODE="kata"         . microvms.sh   # Setup kata-containers as main microvm
MODE="version"      ./microvms.sh   # shows script version
MODE="help"         ./microvms.sh   # shows this help message

See the man page and example file for more info.

END

}


# Check the argument passed from the command line
if [ "$MODE" = "-initramfs" ] || [ "$MODE" = "--initramfs" ] || [ "$MODE" = "initramfs" ]; then
    fetch_initramfs
elif [ "$MODE" = "-kernel" ] || [ "$MODE" = "--kernel" ] || [ "$MODE" = "kernel" ]; then
    fetch_kernel
elif [ "$MODE" = "-beetor" ] || [ "$MODE" = "--beetor" ] || [ "$MODE" = "beetor" ]; then
    fetch_beetor_bwc
elif [ "$MODE" = "-runit" ] || [ "$MODE" = "--runit" ] || [ "$MODE" = "runit" ]; then
    fetch_runit
elif [ "$MODE" = "-iso" ] || [ "$MODE" = "--iso" ] || [ "$MODE" = "iso" ]; then
    # if [ -z "${FILE_PATH}" ]; then
    #     return # unconditional branch
    # fi
    # main logic
    #fa-gha "${FILE_PATH}"
    fetch_isogen
elif [ "$1" = "help" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    print_usage
elif [ "$1" = "version" ] || [ "$1" = "-v" ] || [ "$1" = "--version" ]; then
    printf "\n|> Version: "
else
    echo "Invalid function name. Please specify one of the available functions:"
    print_usage
fi


