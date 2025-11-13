#!/bin/sh

mvm_aio() {

    #MODE="microvm, hlcr" STACK="firecracker, podman" . ./scripts/qonq-qdb.sh
    MODE="microvm" STACK="firecracker, gvisor, kata" . ./scripts/qonq-qdb.sh
}

mvm_firecracker() {

    CCR_MODE="-checker" . ./scripts/ccr.sh && \
        docker compose -f ./compose.yml --progress=plain build --no-cache firecracker
}

mvm_gvisor() {

    CCR_MODE="-checker" . ./scripts/ccr.sh && \
        docker compose -f ./compose.yml --progress=plain build --no-cache gvisor

}

mvm_kata() {

    CCR_MODE="-checker" . ./scripts/ccr.sh && \
        docker compose -f ./compose.yml --progress=plain build --no-cache kata
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
if ! [ -z "${MODE}" ] && \
    [ "${MODE}" = "microvms-aio" ] || \
    [ "${MODE}" = "firecracker" ] || \
    [ "${MODE}" = "gvisor" ] || \
    [ "${MODE}" = "kata" ]; then
    case "${MODE}" in
        "microvms-aio")
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
    printf "\n|> Version: microvms 1.0.0"
else
    echo "Invalid function name. Please specify one of the available functions:"
    print_usage
fi


