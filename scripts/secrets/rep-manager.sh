#!/bin/sh

sed_replace() {

SEC_SED="./scripts/secrets/rep-secrets.sed"
INPUT_SCRIPT_FILE="path"

if [ -f "${SEC_SED}" ] && [ -f "${INPUT_SCRIPT_FILE}" ]; then

    sed -f "${SEC_SED}" < "./artifacts/sso.sh" > ./artifacts/replaSED-sso.sh && \
        envsubst < ./artifacts/replaSED-sso.sh > ./artifacts/unsealed-sso.sh
else
    printf "\n|> Error: secrets parsing sed script not found. Exiting now..."
fi

}


print_usage() {
cat <<-END >&2
USAGE: rep [-options]
                - checker
                - version
                - help
eg,
rep -checker   # runs qemu pointing to a custom initramfs and kernel bzImage
rep -version # shows script version
rep -help    # shows this help message

See the man page and example file for more info.

END

}


# Check the argument passed from the command line
if [ "$MODE" = "-rep" ] || [ "$MODE" = "--rep" ] || [ "$MODE" = "rep" ]; then
    if [ -z "${FILE_PATH}" ]; then
        return # unconditional branch
    fi
    # main logic
    sed_replace "${FILE_PATH}"
elif [ "$1" = "help" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    print_usage
elif [ "$1" = "version" ] || [ "$1" = "-v" ] || [ "$1" = "--version" ]; then
    printf "\n|> Version: "
else
    echo "Invalid function name. Please specify one of: function1, function2, function3"
    print_usage
fi


