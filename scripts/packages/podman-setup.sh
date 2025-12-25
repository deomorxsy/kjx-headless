#!/bin/sh

core_routine() {
    # PODMAN_PKGDEPS_PLACEHOLDER=""
    # export PODMAN_PKGDEPS_PLACEHOLDER
    mkdir -p /app

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
    #escape awk $3 with a blackslash '\'

    if ! [ -f "./scripts/packages/demo-replased.sh" ]; then

        cp
        echo "|> Error: it was not possible to resolve dependency list for [conmon]. Exiting now..."
        echo "|> SCOPE: [set_podman_deps], file [./scripts/packages/podman-setup.sh]; check: 02"
        return 1
    fi
    echo "|> Successfully resolved dependency list for [conmon]. Proceeding..."
    echo "|> SCOPE: [set_podman_deps], file [./scripts/packages/podman-setup.sh]; check: 02"

    ###     if ! (
    ###
    ###         (
    ###             cat <<EOF
    ### PODMAN_PKGDEPS_PLACEHOLDER="\$(apk info -L placeholder | awk 'NR > 1')"
    ### export PODMAN_PKGDEPS_PLACEHOLDER
    ###
    ### # redirect the filepath of dotfiles for the [PLACEHOLDER] apk package
    ### if ! (for f in \$PODMAN_PKGDEPS_PLACEHOLDER; do
    ###     echo "\$f" >>/foo.txt
    ### done); then
    ###     echo "|> Error: it was not possible to redirect the filepath of dotfiles for the [PLACEHOLDER] apk package. Exiting now..."
    ###     return 1
    ### fi
    ### echo "|> Successfully redirected the filepath of dotfiles for the [PLACEHOLDER] apk package. Proceeding..."
    ###
    ### # redirect filepath of dynamically linked binary dependencies (shared objects)
    ### if ! (ldd "\$(readlink -f "\$(apk info -L placeholder | awk 'NR > 1')")" | awk '{print \$3}' >>foo.txt); then
    ###     echo "|> Error: it was not possible to redirect the filepath of [PLACEHOLDER] dynamically linked binary dependencies (shared objects). Exiting now..."
    ###     return 1
    ### fi
    ### echo "|> Successfully redirected the filepath of [PLACEHOLDER] dynamically linked binary dependencies (shared objects). Proceeding..."
    ###
    ### #
    ### for f in /bin/* /usr/bin/* /usr/sbin/*; do
    ###     case \$f in
    ###     */placeholder) ldd "\$(readlink -f "\$(which "\$f")")" | awk '{print \$3}' >>/foo.txt ;;
    ###     esac
    ### done
    ###
    ### EOF
    ###         ) | tee /app/depslist.sh
    ###     ); then
    ###         echo "|> Error: could not create the filepath [/app/depslist.sh]. Exiting now..."
    ###         echo "|> SCOPE: [core_routine], file [./scripts/packages/podman-setup.sh]; check: 01"
    ###         return 1
    ###     fi
    ###     echo "|> Successfully created the filepath [/app/depslist.sh]. Proceeding..."
    ###     echo "|> SCOPE: [core_routine], file [./scripts/packages/podman-setup.sh]; check: 01"

    if ! (for f in $CORE_PODMAN_DEPS; do
        COREUPPER="$(echo "$f" | tr '[:lower:]' '[:upper:]')"
        export COREUPPER

        sed -e "s/PLACEHOLDER/$COREUPPER/g" -e "s/placeholder/$f/g" /app/depslist.sh >"/app/depslist-replaSED_$f.sh"
    done); then
        echo "|> Error: could not replace every PLACEHOLDER with the uppercase string of the name of the dependency and every lowercase with its counterpart. Exiting now..."
        echo "|> SCOPE: [core_routine], file [./scripts/packages/podman-setup.sh]; check: 02"
        return 1
    fi
    echo "|> Successfully replaced every PLACEHOLDER with the uppercase string of the name of the dependency and every lowercase with its counterpart. Proceeding..."
    echo "|> SCOPE: [core_routine], file [./scripts/packages/podman-setup.sh]; check: 02"

    if ! (sed -i -E 's/([A-Z])-([A-Z])/\1_\2/g' /app/depslist-replaSED_*); then
        echo "|> Error: could not replace every hyphen between uppercase characters into an underscore with sed and extended regex [-r/-E]. Exiting now..."
        echo "|> SCOPE: [core_routine], file [./scripts/packages/podman-setup.sh]; check: 03"
        return 1
    fi
    echo "|> Successfully replaced every hyphen between uppercase characters into an underscore with sed and extended regex [-r/-E]. Proceeding..."
    echo "|> SCOPE: [core_routine], file [./scripts/packages/podman-setup.sh]; check: 03"

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
        return 1
    fi
    echo "|> Successfully ran the function [core_routine]. Proceeding..."
    echo "|> SCOPE: [set_podman_deps], file [./scripts/packages/podman-setup.sh]; check: 01"

    # conmon
    ## provides: cmd:conmon
    if ! (/bin/sh -c "/app/depslist-replaSED_conmon.sh"); then
        echo "|> Error: it was not possible to resolve dependency list for [conmon]. Exiting now..."
        echo "|> SCOPE: [set_podman_deps], file [./scripts/packages/podman-setup.sh]; check: 02"
        return 1
    fi
    echo "|> Successfully resolved dependency list for [conmon]. Proceeding..."
    echo "|> SCOPE: [set_podman_deps], file [./scripts/packages/podman-setup.sh]; check: 02"

    # oci-runtime
    # provides: cmd:oci-runtime, cmd:crun
    if ! (/bin/sh -c "/app/depslist-replaSED_oci-runtime.sh"); then
        echo "|> Error: it was not possible to resolve dependency list for [oci-runtime]. Exiting now..."
        echo "|> SCOPE: [set_podman_deps], file [./scripts/packages/podman-setup.sh]; check: 03"
        return 1
    fi
    echo "|> Successfully resolved dependency list for [oci-runtime]. Proceeding..."
    echo "|> SCOPE: [set_podman_deps], file [./scripts/packages/podman-setup.sh]; check: 03"

    # passt
    # provides: cmd:passt-repair, cmd:passt, cmd:pasta, cmd:qrap
    if ! (/bin/sh -c "/app/depslist-replaSED_passt.sh"); then
        echo "|> Error: it was not possible to resolve dependency list for [passt]. Exiting now..."
        echo "|> SCOPE: [set_podman_deps], file [./scripts/packages/podman-setup.sh]; check: 04"
        return 1
    fi
    echo "|> Successfully resolved dependency list for [passt]. Proceeding..."
    echo "|> SCOPE: [set_podman_deps], file [./scripts/packages/podman-setup.sh]; check: 04"

    # containers-common
    # non-cmds: dotfiles and dynamically linked binary dependencies (shared objects)

    if ! (/bin/sh -c "/app/depslist-replaSED_containers-common.sh"); then
        echo "|> Error: it was not possible to resolve dependency list for [containers-common]. Exiting now..."
        echo "|> SCOPE: [set_podman_deps], file [./scripts/packages/podman-setup.sh]; check: 05"
        return 1
    fi
    echo "|> Successfully resolved dependency list for [containers-common]. Proceeding..."
    echo "|> SCOPE: [set_podman_deps], file [./scripts/packages/podman-setup.sh]; check: 05"

    # netavark
    # ldd "$(readlink -f "$(apk info -L netavark | awk 'NR > 1')")" | awk '{print $3}' >>foo.txt
    if ! (/bin/sh -c "/app/depslist-replaSED_containers-netavark.sh"); then
        echo "|> Error: it was not possible to resolve dependency list for [netavark]. Exiting now..."
        echo "|> SCOPE: [set_podman_deps], file [./scripts/packages/podman-setup.sh]; check: 06"
        return 1
    fi
    echo "|> Successfully resolved dependency list for [netavark]. Proceeding..."
    echo "|> SCOPE: [set_podman_deps], file [./scripts/packages/podman-setup.sh]; check: 06"

    # aardvark-dns
    if ! (/bin/sh -c "/app/depslist-replaSED_containers-aardvark-dns.sh"); then
        echo "|> Error: it was not possible to resolve dependency list for [aardvark-dns]. Exiting now..."
        echo "|> SCOPE: [set_podman_deps], file [./scripts/packages/podman-setup.sh]; check: 07"
        return 1
    fi
    echo "|> Successfully resolved dependency list for [aardvark-dns]. Proceeding..."
    echo "|> SCOPE: [set_podman_deps], file [./scripts/packages/podman-setup.sh]; check: 07"

    # catatonit
    if ! (/bin/sh -c "/app/depslist-replaSED_containers-catatonit.sh"); then
        echo "|> Error: it was not possible to resolve dependency list for [catatonit]. Exiting now..."
        echo "|> SCOPE: [set_podman_deps], file [./scripts/packages/podman-setup.sh]; check: 08"
        return 1
    fi
    echo "|> Successfully resolved dependency list for [catatonit]. Proceeding..."
    echo "|> SCOPE: [set_podman_deps], file [./scripts/packages/podman-setup.sh]; check: 08"

}

set_podman_so() {

    if ! set_podman_deps; then
        echo "|> Error: it was not possible to resolve podman dependencies. Exiting now..."
        echo "|> SCOPE: [set_podman_so], file [./scripts/packages/podman-setup.sh]; check: 01"
        return 1
    fi
    echo "|> Successfully resolved podman dependencies. Proceeding..."
    echo "|> SCOPE: [set_podman_so], file [./scripts/packages/podman-setup.sh]; check: 01"

    # podman commands
    for f in /usr/sbin/*; do
        case $f in
        /usr/sbin/podman) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
        /usr/sbin/podmansh) ldd "$(readlink -f "$(which "$f")")" | awk '{print $3}' >>/foo.txt ;;
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
    tar -czf /podman-so-pkg.tar.gz -T /quux.txt

}

set_podman_bin() {
    #
    # set IFS: input field separator
    IFS=$(printf '\n\t')

    # read each line defining the input field separator,
    # follow the soft link and append readlink output line to a new file
    while IFS= read -r line; do
        readlink -f "$(which "$line")" >>/podman-bin-bar.txt
    done </podman-list.txt

    # set the libpam-list alongside podman-bin-bar just to leverage the others.
    while IFS= read -r line; do
        readlink -f "$(which "$line")" >>/podman-bin-bar.txt
    done </libpam-list.txt

    # set IFS: input field separator
    IFS=$(printf '\n\t')

    # remove new lines on the lists, then create new file
    sed '/^$/d' /podman-bin-bar.txt >/podman-bin-foobar.txt &&
        #sed '/^$/d' /bar.txt >> /foobar.txt

        # then remove duplicate shared objects
        sort /podman-bin-foobar.txt | uniq >/podman-bin-quux.txt &&

        # generate a tarball of shared objects from filepaths on a text file
        tar -czf /podman-bin-pkg.tar.gz -T /podman-bin-quux.txt

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
    [ "${MODE}" = "podman-bin" ]; then
    case "${MODE}" in
    "podman-so") set_podman_so ;;
    "podman-bin") set_podman_bin ;;
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

old_deps() {
    ldd "$(readlink -f "$(which conmon)")" | awk '{print $3}' >>/foo.txt
    ldd "$(readlink -f "$(which podman)")" | awk '{print $3}' >>/foo.txt

    ldd "$(readlink -f /usr/libexec/podman/netavark)" | awk '{print $3}' >>/foo.txt
    ldd "$(readlink -f /usr/libexec/podman/aardvark-dns)" | awk '{print $3}' >>/foo.txt
    ldd "$(readlink -f /usr/libexec/podman/rootlessport)" | awk '{print $3}' >>/foo.txt

    # since catatonit is a static binary
    echo "$(readlink -f /usr/libexec/podman/catatonit)" >>/foo.txt

    # if [ -d /usr/libexec/podman ]; then
    #
    # fi

    # crun support
    ldd "$(readlink -f "$(which crun)")" | awk '{print $3}' >>/foo.txt

}
#
