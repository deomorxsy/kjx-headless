#!/bin/sh

core_routine() {
    mkdir -p /app/scripts/packages

    DEPSLIST="/app/scripts/packages/demo-replased.sh"
    export DEPSLIST

    CORE_QEMUKJX_DEPS="$(

        # libcap parted device-mapper fuse-overlayfs qemu qemu-img qemu-system-x86_64 \
        # file multipath-tools e2fsprogs xorriso expect libseccomp libcgroup \
        # bpftool pahole bpftrace squashfs-tools setxkbmap losetup fuse3 \
        # perl runit openssh git podman conmon crun runc

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
    export CORE_QEMUKJX_DEPS

    if ! [ -f "${DEPSLIST:-[EMPTY_VARIABLE]}" ]; then

        # cp
        echo "|> Error: it was not possible to resolve dependency list for [qemukjx]. Exiting now..."
        echo "|> SCOPE: [core_routine], file [./scripts/packages/qemukjx-setup.sh]; check: 01"
        echo
        return 1
    fi
    echo "|> Successfully resolved dependency list for [qemukjx]. Proceeding..."
    echo "|> SCOPE: [core_routine], file [./scripts/packages/qemukjx-setup.sh]; check: 01"
    echo

    # generalize the install by replacing every placeholder with the desired dependency
    if ! (for f in $CORE_QEMUKJX_DEPS; do
        COREUPPER="$(echo "$f" | tr '[:lower:]' '[:upper:]')"
        export COREUPPER

        sed -e "s/PKGNAME_PKGDEPS_PLACEHOLDER/QEMUKJX_PKGDEPS_PLACEHOLDER/g" -e "s/PLACEHOLDER/$COREUPPER/g" -e "s/placeholder/$f/g" "${DEPSLIST:-[EMPTY_VARIABLE]}" >"/app/depslist-replaSED_$f.sh"
    done); then
        echo "|> Error: could not replace every PLACEHOLDER with the uppercase string of the name of the dependency and every lowercase with its counterpart. Exiting now..."
        echo "|> SCOPE: [core_routine], file [./scripts/packages/qemukjx-setup.sh]; check: 02"
        echo
        return 1
    fi
    echo "|> Successfully replaced every PLACEHOLDER with the uppercase string of the name of the dependency and every lowercase with its counterpart. Proceeding..."
    echo "|> SCOPE: [core_routine], file [./scripts/packages/qemukjx-setup.sh]; check: 02"
    echo

    # now use the extended regex [-r/-E] to replace hyphen between uppecase characters
    if ! (sed --in-place -E 's/([A-Z0-9])-([A-Z0-9])/\1_\2/g' /app/depslist-replaSED_*); then
        echo "|> Error: could not replace every hyphen between uppercase characters into an underscore with sed and extended regex [-r/-E]. Exiting now..."
        echo "|> SCOPE: [core_routine], file [./scripts/packages/qemukjx-setup.sh]; check: 03"
        return 1
    fi
    echo "|> Successfully replaced every hyphen between uppercase characters into an underscore with sed and extended regex [-r/-E]. Proceeding..."
    echo "|> SCOPE: [core_routine], file [./scripts/packages/qemukjx-setup.sh]; check: 03"

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
        echo "|> SCOPE: [core_routine], file [./scripts/packages/qemukjx-setup.sh]; check: 04"
        echo
        return 1
    fi
    echo "|> Sucessfully changed file bits of execution permission [recursively] under [/app]. Proceeding..."
    echo "|> SCOPE: [core_routine], file [./scripts/packages/qemukjx-setup.sh]; check: 04"
    echo

    ls -allhtr /app

}

set_qemukjx_deps() {

    if ! core_routine; then
        echo "|> Error: could not run the function [core_routine]. Exiting now..."
        echo "|> SCOPE: [set_qemukjx_deps], file [./scripts/packages/qemukjx-setup.sh]; check: 01"
        return 1
    fi
    echo "|> Successfully ran the function [core_routine]. Proceeding..."
    echo "|> SCOPE: [set_qemukjx_deps], file [./scripts/packages/qemukjx-setup.sh]; check: 01"

    #ls -allhtr /app | awk '{print $10}'
    find /app \( -iname '*depslist-replaSED_*.sh' \)

    ALL_SCRIPTS="$(find /app \( -iname '*depslist-replaSED_*.sh' \))"

    for jooj in $ALL_SCRIPTS; do
        if ! (/bin/sh -c "$jooj"); then
            echo "|> Error: it was not possible to resolve dependency list for [$jooj]. Exiting now..."
            echo "|> SCOPE: [set_qemukjx_deps], file [./scripts/packages/qemukjx-setup.sh]; "
            return 1
        fi
        echo "|> Sucessfully resolved dependency list for [$jooj]. Proceeding..."
    done

    #### CORE_SCRIPTS="$(ls /app)"
}

# single tarball
set_qemukjx_tarball() {

    if ! set_qemukjx_deps; then
        echo "|> Error: it was not possible to resolve [qemukjx] dependencies. Exiting now..."
        echo "|> SCOPE: [set_qemukjx_tarball], file [./scripts/packages/qemukjx-setup.sh]; check: 01"
        return 1
    fi
    echo "|> Successfully resolved [qemukjx] dependencies. Proceeding..."
    echo "|> SCOPE: [set_qemukjx_tarball], file [./scripts/packages/qemukjx-setup.sh]; check: 01"

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
    # tar -czf /qemukjx-single-pkg.tar.gz -T /quux.txt
    tar -czf /qemukjx-tarball-pkg.tar.gz -T /quux.txt

}

set_qemukjx_builda() {

    CCR_MODE="-checker" . ./scripts/ccr.sh &&
        docker compose -f ./compose.yml --progress=plain build --no-cache qemu_kjx

}

print_usage() {
    cat <<-END >&2
USAGE: qemu-kjx-setup [-options]
                - tarball
                - version
                - help
eg,
qemu-kjx -tarball # setup the full tarball for qemu-kjx
qemu-kjx -help    # shows this help message
qemu-kjx -version # shows script version

or,
MODE="tarball"  . ./qemu-kjx-setup.sh   # setup the full tarball for qemu-kjx

See the man page and example file for more info.

END

}

# Check the argument passed from the command line
if ! [ -z "${MODE}" ] &&
    [ "${MODE}" = "builda" ] ||
    [ "${MODE}" = "tarball" ]; then
    case "${MODE}" in
    "builda") set_qemukjx_builda ;;
    "tarball") set_qemukjx_tarball ;;
    *)
        echo "Invalid option. Please specify one of: tarball, builda"
        print_usage
        ;;
    esac

elif [ "${MODE}" = "help" ] || [ "${MODE}" = "-h" ] || [ "${MODE}" = "--help" ]; then
    print_usage
elif [ "${MODE}" = "version" ] || [ "${MODE}" = "-v" ] || [ "${MODE}" = "--version" ]; then
    printf "\n|> Version: qemukjx-setup 1.0.0"
else
    echo "Invalid function name. Please specify one of the available functions:"
    print_usage
fi
