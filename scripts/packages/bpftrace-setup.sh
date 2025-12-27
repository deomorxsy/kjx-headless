#!/bin/sh

new_routine() {
    echo

    ### BPFTRACE_DEPS=$(
    ###     # 1) gets dependency list,
    ###     # 2) removes lines with [depends:] and
    ###     # 3) removes the leading [so:]
    ###     apk info --depends bpftrace |
    ###         grep -v depends |
    ###         sed -n 's/so://p'

    ### )
    ### export BPFTRACE_DEPS
    ### echo "$BPFTRACE_DEPS"

    ### BPFTRACE_SO=$(ldd "$(readlink -f "$(which bpftrace)")" | awk '{print $3}')
    ### export BPFTRACE_SO

    ### for xis in ${BPFTRACE_SO:-[EMPTY_VARIABLE]}; do
    ###     apk info -W "$xis" | awk '{print $5}' | awk -F- '{print $1}' >>/bpftrace-TRIMMED-deps.txt

    ### done

    ### BTD="$(cat /bpftrace-TRIMMED-deps.txt)"

    ### CURRENT_APK_INFO="$(apk info)"

    ### for index in $BTD; do
    ###     if ! [ "$BTD" = "*$index*" ]; then
    ###         echo ACHOU
    ###         # return 1
    ###     fi
    ### done

    ### apk info -W /usr/lib/libxml2.so.2 | awk '{print $5}' | awk -F- '{print $1}'

    apk dot bpftrace --installed | grep -v "shape=box" | grep -v "rankdir=LR" | grep -v "digraph" | awk '{print $1}' | sed -E 's/-[0-9].*$//' | tr -d '"' | tr -d "}" | sort -u

}

core_routine() {
    # BPFTRACE_PKGDEPS_PLACEHOLDER=""
    # export BPFTRACE_PKGDEPS_PLACEHOLDER
    #
    mkdir -p /app/scripts/packages

    DEPSLIST="/app/scripts/packages/demo-replased.sh"
    export DEPSLIST

    #ldd "$(readlink -f "$(which bpftrace)")" | awk '{print $3}'

    CORE_BPFTRACE_DEPS="$(
        apk dot bpftrace --installed | grep -v "shape=box" | grep -v "rankdir=LR" | grep -v "digraph" | awk '{print $1}' | sed -E 's/-[0-9].*$//' | tr -d '"' | tr -d "}" | sort -u
    )"
    export CORE_BPFTRACE_DEPS

    ### CORE_BPFTRACE_DEPS="
    ### llvm20-libs
    ### bcc
    ### binutils
    ### libbpf
    ### musl
    ### clang20-libs
    ### libdw
    ### libelf
    ### llvm-next-libgcc
    ### libstdc++
    ### zlib
    ### bpftrace
    ### "

    if ! [ -f "${DEPSLIST:-[EMPTY_VARIABLE]}" ]; then

        # cp
        echo "|> Error: it was not possible to resolve dependency list for [bpftrace]. Exiting now..."
        echo "|> SCOPE: [core_routine], file [./scripts/packages/bpftrace-setup.sh]; check: 01"
        echo
        return 1
    fi
    echo "|> Successfully resolved dependency list for [bpftrace]. Proceeding..."
    echo "|> SCOPE: [core_routine], file [./scripts/packages/bpftrace-setup.sh]; check: 01"
    echo

    # generalize the install by replacing every placeholder with the desired dependency
    if ! (for f in $CORE_BPFTRACE_DEPS; do
        COREUPPER="$(echo "$f" | tr '[:lower:]' '[:upper:]')"
        export COREUPPER

        sed -e "s/PKGNAME_PKGDEPS_PLACEHOLDER/BPFTRACE_PKGDEPS_PLACEHOLDER/g" -e "s/PLACEHOLDER/$COREUPPER/g" -e "s/placeholder/$f/g" "${DEPSLIST:-[EMPTY_VARIABLE]}" >"/app/depslist-replaSED_$f.sh"
    done); then
        echo "|> Error: could not replace every PLACEHOLDER with the uppercase string of the name of the dependency and every lowercase with its counterpart. Exiting now..."
        echo "|> SCOPE: [core_routine], file [./scripts/packages/bpftrace-setup.sh]; check: 02"
        echo
        return 1
    fi
    echo "|> Successfully replaced every PLACEHOLDER with the uppercase string of the name of the dependency and every lowercase with its counterpart. Proceeding..."
    echo "|> SCOPE: [core_routine], file [./scripts/packages/bpftrace-setup.sh]; check: 02"
    echo

    # echo "BPFTRACE_PKGDEPS_LLVM20-LIBS" | sed -E 's/([A-Z0-9])-([A-Z0-9])/\1_\2/g'
    # |> BPFTRACE_PKGDEPS_LLVM20_LIBS
    # if ! (sed -i -E 's/([A-Z])-([A-Z])/\1_\2/g' /app/depslist-replaSED_*); then
    #
    # now use the extended regex [-r/-E] to replace hyphen between uppecase characters
    if ! (sed --in-place -E 's/([A-Z0-9])-([A-Z0-9])/\1_\2/g' /app/depslist-replaSED_*); then
        echo "|> Error: could not replace every hyphen between uppercase characters into an underscore with sed and extended regex [-r/-E]. Exiting now..."
        echo "|> SCOPE: [core_routine], file [./scripts/packages/bpftrace-setup.sh]; check: 03"
        return 1
    fi
    echo "|> Successfully replaced every hyphen between uppercase characters into an underscore with sed and extended regex [-r/-E]. Proceeding..."
    echo "|> SCOPE: [core_routine], file [./scripts/packages/bpftrace-setup.sh]; check: 03"

    #cat /app/plus.sh  | sed -e 's/[A-Z0-9]++/\1PP\2/g'
    if ! (sed -i -e 's/[A-Z0-9]++/\1PP\2/g' /app/depslist-replaSED_*); then
        echo "|> Error: could not replace every plus sign by "
        #return 1
    fi

    ls -allhtr /app

    if ! (chmod +x -R /app/"depslist"*); then
        echo "|> Error: it was not possible to change file bits of execution permission [recursively] under [/app]. Exiting now..."
        echo "|> SCOPE: [core_routine], file [./scripts/packages/bpftrace-setup.sh]; check: 04"
        echo
        return 1
    fi
    echo "|> Sucessfully changed file bits of execution permission [recursively] under [/app]. Proceeding..."
    echo "|> SCOPE: [core_routine], file [./scripts/packages/bpftrace-setup.sh]; check: 04"
    echo

    ls -allhtr /app

}

set_bpftrace_deps() {

    # Depends (13)
    ## so:libLLVM.so.20.1
    ## so:libbcc_bpf.so.0
    ## so:libbfd-2.45.1.so
    ## so:libbpf.so.1
    ## so:libc.musl-x86_64.so.1
    ## so:libclang-cpp.so.20.1
    ## so:libclang.so.20.1
    ## so:libdw.so.1
    ## so:libelf.so.1
    ## so:libgcc_s.so.1
    ## so:libopcodes-2.45.1.so
    ## so:libstdc++.so.6
    ## so:libz.so.1

    if ! core_routine; then
        echo "|> Error: could not run the function [core_routine]. Exiting now..."
        echo "|> SCOPE: [set_bpftrace_deps], file [./scripts/packages/bpftrace-setup.sh]; check: 01"
        return 1
    fi
    echo "|> Successfully ran the function [core_routine]. Proceeding..."
    echo "|> SCOPE: [set_bpftrace_deps], file [./scripts/packages/bpftrace-setup.sh]; check: 01"

    #ls -allhtr /app | awk '{print $10}'
    find /app \( -iname '*depslist-replaSED_*.sh' \)

    ALL_SCRIPTS="$(find /app \( -iname '*depslist-replaSED_*.sh' \))"
    # NAMBA_AS=$(echo "$ALL_SCRIPTS" | wc -w)
    # counter=0
    ## while [ "$counter" -lt "$NAMBA_AS" ]; do
    ##     echo "|> SCOPE: [set_bpftrace_deps], file [./scripts/packages/bpftrace-setup.sh]; check [$counter]"
    ## done
    # counter=$((counter + 1))
    for jooj in $ALL_SCRIPTS; do
        if ! (/bin/sh -c "$jooj"); then
            echo "|> Error: it was not possible to resolve dependency list for [$jooj]. Exiting now..."
            echo "|> SCOPE: [set_bpftrace_deps], file [./scripts/packages/bpftrace-setup.sh]; "
            return 1
        fi
        echo "|> Sucessfully resolved dependency list for [$jooj]. Proceeding..."
    done

    #### CORE_SCRIPTS="$(ls /app)"

    #### for filesa in $CORE_SCRIPTS; do
    ####     if [ -f "$filesa" ]; then
    ####         echo "$filesa"

    ####         if ! (/bin/sh -c "$filesa"); then
    ####             echo "|> Error: could not run [FILESA=$filesa]"
    ####         fi
    ####     fi
    #### done

    ### # llvm20-libs
    ### if ! (/bin/sh -c "/app/depslist-replaSED_llvm20-libs.sh"); then
    ###     echo "|> Error: it was not possible to resolve dependency list for [llvm20-libs]. Exiting now..."
    ###     echo "|> SCOPE: [set_bpftrace_deps], file [./scripts/packages/bpftrace-setup.sh]; check: 02"
    ###     return 1
    ### fi
    ### echo "|> Successfully resolved dependency list for [llvm20-libs]. Proceeding..."
    ### echo "|> SCOPE: [set_bpftrace_deps], file [./scripts/packages/bpftrace-setup.sh]; check: 02"

    ### # bcc
    ### if ! (/bin/sh -c "/app/depslist-replaSED_bcc.sh"); then
    ###     echo "|> Error: it was not possible to resolve dependency list for [bcc]. Exiting now..."
    ###     echo "|> SCOPE: [set_bpftrace_deps], file [./scripts/packages/bpftrace-setup.sh]; check: 03"
    ###     return 1
    ### fi
    ### echo "|> Successfully resolved dependency list for [bcc]. Proceeding..."
    ### echo "|> SCOPE: [set_bpftrace_deps], file [./scripts/packages/bpftrace-setup.sh]; check: 03"

    ### # binutils
    ### if ! (/bin/sh -c "/app/depslist-replaSED_binutils.sh"); then
    ###     echo "|> Error: it was not possible to resolve dependency list for [binutils]. Exiting now..."
    ###     echo "|> SCOPE: [set_bpftrace_deps], file [./scripts/packages/bpftrace-setup.sh]; check: 04"
    ###     return 1
    ### fi
    ### echo "|> Successfully resolved dependency list for [binutils]. Proceeding..."
    ### echo "|> SCOPE: [set_bpftrace_deps], file [./scripts/packages/bpftrace-setup.sh]; check: 04"

    ### # libbpf
    ### if ! (/bin/sh -c "/app/depslist-replaSED_libbpf.sh"); then
    ###     echo "|> Error: it was not possible to resolve dependency list for [libbpf]. Exiting now..."
    ###     echo "|> SCOPE: [set_bpftrace_deps], file [./scripts/packages/bpftrace-setup.sh]; check: 05"
    ###     return 1
    ### fi
    ### echo "|> Successfully resolved dependency list for [libbpf]. Proceeding..."
    ### echo "|> SCOPE: [set_bpftrace_deps], file [./scripts/packages/bpftrace-setup.sh]; check: 05"

    ### # musl
    ### if ! (/bin/sh -c "/app/depslist-replaSED_musl.sh"); then
    ###     echo "|> Error: it was not possible to resolve dependency list for [musl]. Exiting now..."
    ###     echo "|> SCOPE: [set_bpftrace_deps], file [./scripts/packages/bpftrace-setup.sh]; check: 06"
    ###     return 1
    ### fi
    ### echo "|> Successfully resolved dependency list for [musl]. Proceeding..."
    ### echo "|> SCOPE: [set_bpftrace_deps], file [./scripts/packages/bpftrace-setup.sh]; check: 06"

    ### # clang20-libs
    ### if ! (/bin/sh -c "/app/depslist-replaSED_clang20-libs.sh"); then
    ###     echo "|> Error: it was not possible to resolve dependency list for [clang20-libs]. Exiting now..."
    ###     echo "|> SCOPE: [set_bpftrace_deps], file [./scripts/packages/bpftrace-setup.sh]; check: 07"
    ###     return 1
    ### fi
    ### echo "|> Successfully resolved dependency list for [clang20-libs]. Proceeding..."
    ### echo "|> SCOPE: [set_bpftrace_deps], file [./scripts/packages/bpftrace-setup.sh]; check: 07"

    ### # libdw
    ### if ! (/bin/sh -c "/app/depslist-replaSED_libdw.sh"); then
    ###     echo "|> Error: it was not possible to resolve dependency list for [libdw]. Exiting now..."
    ###     echo "|> SCOPE: [set_bpftrace_deps], file [./scripts/packages/bpftrace-setup.sh]; check: 08"
    ###     return 1
    ### fi
    ### echo "|> Successfully resolved dependency list for [libdw]. Proceeding..."
    ### echo "|> SCOPE: [set_bpftrace_deps], file [./scripts/packages/bpftrace-setup.sh]; check: 08"

    ### # libelf
    ### if ! (/bin/sh -c "/app/depslist-replaSED_libelf.sh"); then
    ###     echo "|> Error: it was not possible to resolve dependency list for [libelf]. Exiting now..."
    ###     echo "|> SCOPE: [set_bpftrace_deps], file [./scripts/packages/bpftrace-setup.sh]; check: 09"
    ###     return 1
    ### fi
    ### echo "|> Successfully resolved dependency list for [libelf]. Proceeding..."
    ### echo "|> SCOPE: [set_bpftrace_deps], file [./scripts/packages/bpftrace-setup.sh]; check: 09"

    ### # llvm-next-libgcc
    ### if ! (/bin/sh -c "/app/depslist-replaSED_llvm-next-libgcc.sh"); then
    ###     echo "|> Error: it was not possible to resolve dependency list for [llvm-next-libgcc]. Exiting now..."
    ###     echo "|> SCOPE: [set_bpftrace_deps], file [./scripts/packages/bpftrace-setup.sh]; check: 10"
    ###     return 1
    ### fi
    ### echo "|> Successfully resolved dependency list for [llvm-next-libgcc]. Proceeding..."
    ### echo "|> SCOPE: [set_bpftrace_deps], file [./scripts/packages/bpftrace-setup.sh]; check: 10"

    # libstdc++
    ### if ! (/bin/sh -c "/app/depslist-replaSED_libstdc++.sh"); then
    ###     echo "|> Error: it was not possible to resolve dependency list for [libstdc++]. Exiting now..."
    ###     echo "|> SCOPE: [set_bpftrace_deps], file [./scripts/packages/bpftrace-setup.sh]; check: 11"
    ###     return 1
    ### fi
    ### echo "|> Successfully resolved dependency list for [libstdc++]. Proceeding..."
    ### echo "|> SCOPE: [set_bpftrace_deps], file [./scripts/packages/bpftrace-setup.sh]; check: 11"

    ### # zlib
    ### if ! (/bin/sh -c "/app/depslist-replaSED_zlib.sh"); then
    ###     echo "|> Error: it was not possible to resolve dependency list for [zlib]. Exiting now..."
    ###     echo "|> SCOPE: [set_bpftrace_deps], file [./scripts/packages/bpftrace-setup.sh]; check: 12"
    ###     return 1
    ### fi
    ### echo "|> Successfully resolved dependency list for [zlib]. Proceeding..."
    ### echo "|> SCOPE: [set_bpftrace_deps], file [./scripts/packages/bpftrace-setup.sh]; check: 12"

    ### # bpftrace
    ### if ! (/bin/sh -c "/app/depslist-replaSED_bpftrace.sh"); then
    ###     echo "|> Error: it was not possible to resolve dependency list for [bpftrace]. Exiting now..."
    ###     echo "|> SCOPE: [set_bpftrace_deps], file [./scripts/packages/bpftrace-setup.sh]; check: 13"
    ###     return 1
    ### fi
    ### echo "|> Successfully resolved dependency list for [bpftrace]. Proceeding..."
    ### echo "|> SCOPE: [set_bpftrace_deps], file [./scripts/packages/bpftrace-setup.sh]; check: 13"

}

# single tarball
set_bpftrace_tarball() {

    if ! set_bpftrace_deps; then
        echo "|> Error: it was not possible to resolve bpftrace dependencies. Exiting now..."
        echo "|> SCOPE: [set_bpftrace], file [./scripts/packages/bpftrace-setup.sh]; check: 01"
        return 1
    fi
    echo "|> Successfully resolved bpftrace dependencies. Proceeding..."
    echo "|> SCOPE: [set_bpftrace], file [./scripts/packages/bpftrace-setup.sh]; check: 01"

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
    # tar -czf /bpftrace-single-pkg.tar.gz -T /quux.txt
    tar -czf /bpftrace-tarball-pkg.tar.gz -T /quux.txt

}

print_usage() {
    cat <<-END >&2
USAGE: bpftrace-setup.sh [-options]
                - bpftrace-so
                - bpftrace-bin
                - tarball
                - version
                - help
eg,
MODE="bpftrace-so"  . ./bpftrace-setup.sh   # setup bpftrace shared objects
MODE="bpftrace-bin" . ./bpftrace-setup.sh   # setup bpftrace (musl) dynamically linked binaries
MODE="tarball"      . ./bpftrace-setup.sh   # create a single tarball
MODE="version"      . ./bpftrace-setup.sh   # shows script version
MODE="help"         . ./bpftrace-setup.sh   # shows this help message

See the man page and example file for more info.

END

}

# Check the argument passed from the command line
if ! [ -z "${MODE}" ] &&
    [ "${MODE}" = "bpftrace-tarball" ]; then
    case "${MODE}" in
    "bpftrace-tarball") set_bpftrace_tarball ;;
    *)
        echo "Invalid option. Please specify one of: bpftrace-so, bpftrace-bin, tarball"
        print_usage
        ;;
    esac

elif [ "${MODE}" = "help" ] || [ "${MODE}" = "-h" ] || [ "${MODE}" = "--help" ]; then
    print_usage
elif [ "${MODE}" = "version" ] || [ "${MODE}" = "-v" ] || [ "${MODE}" = "--version" ]; then
    printf "\n|> Version: bpftrace-setup 1.0.0"
else
    echo "Invalid function name. Please specify one of the available functions:"
    print_usage
fi
