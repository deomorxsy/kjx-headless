#!/bin/sh

mvm_aio() {

    #MODE="microvm, hlcr" STACK="firecracker, podman" . ./scripts/qonq-qdb.sh
    MODE="microvm" STACK="firecracker, gvisor, kata" . ./scripts/qonq-qdb.sh
}

mvm_firecracker() {

    MODE="microvm" STACK="firecracker" . ./scripts/qonq-qdb.sh
}

mvm_gvisor() {

    MODE="microvm" STACK="gvisor" . ./scripts/qonq-qdb.sh
}

mvm_kata() {

    MODE="microvm" STACK="kata" . ./scripts/qonq-qdb.sh
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
if ! [ -z "${MODE}" ]; then
    case "${MODE}" in
        "microvms-aio")
            mvm-aio
            ;;
        "firecracker")
            mvm-firecracker
            ;;
        "gvisor")
            mvm-gvisor
            ;;
        "kata")
            mvm-kata
            ;;
        *)
            echo "Invalid microvm. Please specify one of: firecracker, gvisor, kata"
            print_usage
            ;;
    esac
fi


if [ "${MODE}" = "help" ] || [ "${MODE}" = "-h" ] || [ "${MODE}" = "--help" ]; then
    print_usage
elif [ "${MODE}" = "version" ] || [ "${MODE}" = "-v" ] || [ "${MODE}" = "--version" ]; then
    printf "\n|> Version: microvms 1.0.0"
else
    echo "Invalid function name. Please specify one of the available functions:"
    print_usage
fi


