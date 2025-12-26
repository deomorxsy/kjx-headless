#!/bin/sh

core_routine() {
    # PODMAN_PKGDEPS_PLACEHOLDER=""
    # export PODMAN_PKGDEPS_PLACEHOLDER
    mkdir -p /app/scripts/packages

    DEPSLIST="/app/scripts/packages/demo-replased.sh"
    export DEPSLIST

    CORE_PODMAN_DEPS="
    conmon
    oci-runtime
    passt
    shadow-subids
    containers-common
    netavark
    aardvark-dns
    catatonit
    podman
    "
    export CORE_PODMAN_DEPS

    if ! [ -f "${DEPSLIST:-[EMPTY_VARIABLE]}" ]; then

        # cp
        echo "|> Error: it was not possible to resolve dependency list for [podman]. Exiting now..."
        echo "|> SCOPE: [core_routine], file [./scripts/packages/podman-setup.sh]; check: 01"
        echo
        return 1
    fi
    echo "|> Successfully resolved dependency list for [podman]. Proceeding..."
    echo "|> SCOPE: [core_routine], file [./scripts/packages/podman-setup.sh]; check: 01"
    echo

    if ! (for f in $CORE_PODMAN_DEPS; do
        COREUPPER="$(echo "$f" | tr '[:lower:]' '[:upper:]')"
        export COREUPPER

        sed -e "s/PKGNAME_PKGDEPS_PLACEHOLDER/PODMAN_PKGDEPS_PLACEHOLDER/g" -e "s/PLACEHOLDER/$COREUPPER/g" -e "s/placeholder/$f/g" "${DEPSLIST:-[EMPTY_VARIABLE]}" >"/app/depslist-replaSED_$f.sh"
    done); then
        echo "|> Error: could not replace every PLACEHOLDER with the uppercase string of the name of the dependency and every lowercase with its counterpart. Exiting now..."
        echo "|> SCOPE: [core_routine], file [./scripts/packages/podman-setup.sh]; check: 02"
        echo
        return 1
    fi
    echo "|> Successfully replaced every PLACEHOLDER with the uppercase string of the name of the dependency and every lowercase with its counterpart. Proceeding..."
    echo "|> SCOPE: [core_routine], file [./scripts/packages/podman-setup.sh]; check: 02"
    echo

    #echo "BPFTRACE_PKGDEPS_LLVM20-LIBS" |
    #if ! (sed -i -E 's/([A-Z])-([A-Z])/\1_\2/g' /app/depslist-replaSED_*); then
    if ! (sed --in-place -E 's/([A-Z0-9])-([A-Z0-9])/\1_\2/g' /app/depslist-replaSED_*); then
        echo "|> Error: could not replace every hyphen between uppercase characters into an underscore with sed and extended regex [-r/-E]. Exiting now..."
        echo "|> SCOPE: [core_routine], file [./scripts/packages/podman-setup.sh]; check: 03"
        echo
        return 1
    fi
    echo "|> Successfully replaced every hyphen between uppercase characters into an underscore with sed and extended regex [-r/-E]. Proceeding..."
    echo "|> SCOPE: [core_routine], file [./scripts/packages/podman-setup.sh]; check: 03"
    echo

    ls -allhtr /app

    if ! (chmod +x -R /app/"depslist"*); then
        echo "|> Error: it was not possible to change file bits of execution permission [recursively] under [/app]. Exiting now..."
        echo "|> SCOPE: [core_routine], file [./scripts/packages/podman-setup.sh]; check: 04"
        echo
        return 1
    fi
    echo "|> Sucessfully changed file bits of execution permission [recursively] under [/app]. Proceeding..."
    echo "|> SCOPE: [core_routine], file [./scripts/packages/podman-setup.sh]; check: 04"
    echo

    ls -allhtr /app

}

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

    if ! core_routine; then
        echo "|> Error: could not run the function [core_routine]. Exiting now..."
        echo "|> SCOPE: [set_podman_deps], file [./scripts/packages/podman-setup.sh]; check: 01"
        echo
        return 1
    fi
    echo "|> Successfully ran the function [core_routine]. Proceeding..."
    echo "|> SCOPE: [set_podman_deps], file [./scripts/packages/podman-setup.sh]; check: 01"
    echo

    # conmon
    ## provides: cmd:conmon
    if ! (/bin/sh -c "/app/depslist-replaSED_conmon.sh"); then
        echo "|> Error: it was not possible to resolve dependency list for [conmon]. Exiting now..."
        echo "|> SCOPE: [set_podman_deps], file [./scripts/packages/podman-setup.sh]; check: 02"
        echo
        return 1
    fi
    echo "|> Successfully resolved dependency list for [conmon]. Proceeding..."
    echo "|> SCOPE: [set_podman_deps], file [./scripts/packages/podman-setup.sh]; check: 02"
    echo

    # oci-runtime
    # provides: cmd:oci-runtime, cmd:crun
    if ! (/bin/sh -c "/app/depslist-replaSED_oci-runtime.sh"); then
        echo "|> Error: it was not possible to resolve dependency list for [oci-runtime]. Exiting now..."
        echo "|> SCOPE: [set_podman_deps], file [./scripts/packages/podman-setup.sh]; check: 03"
        echo
        return 1
    fi
    echo "|> Successfully resolved dependency list for [oci-runtime]. Proceeding..."
    echo "|> SCOPE: [set_podman_deps], file [./scripts/packages/podman-setup.sh]; check: 03"
    echo

    # passt
    # provides: cmd:passt-repair, cmd:passt, cmd:pasta, cmd:qrap
    if ! (/bin/sh -c "/app/depslist-replaSED_passt.sh"); then
        echo "|> Error: it was not possible to resolve dependency list for [passt]. Exiting now..."
        echo "|> SCOPE: [set_podman_deps], file [./scripts/packages/podman-setup.sh]; check: 04"
        echo
        return 1
    fi
    echo "|> Successfully resolved dependency list for [passt]. Proceeding..."
    echo "|> SCOPE: [set_podman_deps], file [./scripts/packages/podman-setup.sh]; check: 04"
    echo

    # containers-common
    # non-cmds: dotfiles and dynamically linked binary dependencies (shared objects)

    if ! (/bin/sh -c "/app/depslist-replaSED_containers-common.sh"); then
        echo "|> Error: it was not possible to resolve dependency list for [containers-common]. Exiting now..."
        echo "|> SCOPE: [set_podman_deps], file [./scripts/packages/podman-setup.sh]; check: 05"
        echo
        return 1
    fi
    echo "|> Successfully resolved dependency list for [containers-common]. Proceeding..."
    echo "|> SCOPE: [set_podman_deps], file [./scripts/packages/podman-setup.sh]; check: 05"
    echo

    # netavark
    # ldd "$(readlink -f "$(apk info -L netavark | awk 'NR > 1')")" | awk '{print $3}' >>foo.txt
    if ! (/bin/sh -c "/app/depslist-replaSED_netavark.sh"); then
        echo "|> Error: it was not possible to resolve dependency list for [netavark]. Exiting now..."
        echo "|> SCOPE: [set_podman_deps], file [./scripts/packages/podman-setup.sh]; check: 06"
        echo
        return 1
    fi
    echo "|> Successfully resolved dependency list for [netavark]. Proceeding..."
    echo "|> SCOPE: [set_podman_deps], file [./scripts/packages/podman-setup.sh]; check: 06"
    echo

    # aardvark-dns
    if ! (/bin/sh -c "/app/depslist-replaSED_aardvark-dns.sh"); then
        echo "|> Error: it was not possible to resolve dependency list for [aardvark-dns]. Exiting now..."
        echo "|> SCOPE: [set_podman_deps], file [./scripts/packages/podman-setup.sh]; check: 07"
        echo
        return 1
    fi
    echo "|> Successfully resolved dependency list for [aardvark-dns]. Proceeding..."
    echo "|> SCOPE: [set_podman_deps], file [./scripts/packages/podman-setup.sh]; check: 07"
    echo

    # catatonit
    if ! (/bin/sh -c "/app/depslist-replaSED_catatonit.sh"); then
        echo "|> Error: it was not possible to resolve dependency list for [catatonit]. Exiting now..."
        echo "|> SCOPE: [set_podman_deps], file [./scripts/packages/podman-setup.sh]; check: 08"
        echo
        return 1
    fi
    echo "|> Successfully resolved dependency list for [catatonit]. Proceeding..."
    echo "|> SCOPE: [set_podman_deps], file [./scripts/packages/podman-setup.sh]; check: 08"
    echo

}

set_podman_tarball() {

    if ! set_podman_deps; then
        echo "|> Error: it was not possible to resolve podman dependencies. Exiting now..."
        echo "|> SCOPE: [set_podman_tarball], file [./scripts/packages/podman-setup.sh]; check: 01"
        echo
        return 1
    fi
    echo "|> Successfully resolved podman dependencies. Proceeding..."
    echo "|> SCOPE: [set_podman_tarball], file [./scripts/packages/podman-setup.sh]; check: 01"
    echo

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
    tar -czf /podman-tarball-pkg.tar.gz -T /quux.txt

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
    [ "${MODE}" = "podman-bin" ] ||
    [ "${MODE}" = "podman-tarball" ]; then
    case "${MODE}" in
    "podman-so") set_podman_so ;;
    "podman-bin") set_podman_bin ;;
    "podman-tarball") set_podman_tarball ;;
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
