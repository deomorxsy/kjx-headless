#!/bin/sh


install_deps() {
# Install the basic required dependencies to run 'neovim'/'nvim'
    apk upgrade --no-cache &&
        apk add --no-cache \
        neovim
}

core_routine() {

mkdir -p /app/scripts/packages

DEPSLIST="/app/scripts/packages/demo-replased.sh"
export DEPSLIST

CORE_NEOVIM_DEPS="$(

    apk dot neovim --installed |
        grep -v "shape=box"    |
        grep -v "rankdir=LR"   |
        grep -v "digraph"      |
        awk '{print $1}'       |
        sed -E 's/-[0-9].*$//' |
        tr -d '"'              |
        tr -d "}"              |
        sort -u )"

export CORE_NEOVIM_DEPS

    if ! [ -f "${DEPSLIST:-[EMPTY_VARIABLE]}" ]; then

        # cp
        # ERROR branch
    (
cat <<-END >&2

|> [SCOPE]: function [core_routine], file [./scripts/packages/neovim-setup.sh]; check: 01
|> [ERROR]: it was not possible to resolve dependency list for [neovim]. Exiting now...

END
    ) && return 1
    fi

    (
cat <<-END >&2

|> [SCOPE]: function [core_routine], file [./scripts/packages/neovim-setup.sh]; check: 01
|> [PASS]: Successfully resolved dependency list for [neovim]. Proceeding...

END
    )



    # =======================
    # generalize the install by replacing every placeholder with the desired dependency
    if ! (for f in $CORE_NEOVIM_DEPS; do
        COREUPPER="$(echo "$f" | tr '[:lower:]' '[:upper:]')"
        export COREUPPER

        sed -e "s/PKGNAME_PKGDEPS_PLACEHOLDER/NEOVIM_PKGDEPS_PLACEHOLDER/g" \
            -e "s/PLACEHOLDER/$COREUPPER/g" \
            -e "s/placeholder/$f/g" "${DEPSLIST:-[EMPTY_VARIABLE]}" \
            >"/app/depslist-replaSED_$f.sh"
    done); then

    # ERROR branch
    (
cat <<-END >&2

|> [SCOPE]: function [core_routine], file [./scripts/packages/neovim-setup.sh]; check: 02
|> [ERROR]: could not replace every PLACEHOLDER
with the uppercase string of the name of
the dependency and every lowercase with its counterpart.
Exiting now...

END
    ) && \
        return 1
    fi

    # PASS branch
    (
cat <<-END >&2

|> [SCOPE]: function [core_routine], file [./scripts/packages/neovim-setup.sh]; check: 02"
|> [PASS]: Successfully replaced every PLACEHOLDER with
the uppercase string of the name of the
dependency and every lowercase with its
counterpart. Proceeding..."

END
    )

    # =======================
    # use the extended regular expressions (regex) [-r/-E]
    # to replace hyphen between uppercase characters
    if ! (sed --in-place -E 's/([A-Z0-9])-([A-Z0-9])/\1_\2/g' "/app/depslist-replaSED_"*); then
        echo "|> [ERROR]: could not replace every hyphen between uppercase characters into an underscore with sed and extended regex [-r/-E]. Exiting now..."
        echo "|> [SCOPE]: function [core_routine], file [./scripts/packages/neovim-setup.sh]; check: 03"
        return 1
    fi
    echo "|> [PASS]: Successfully replaced every hyphen between uppercase characters into an underscore with sed and extended regex [-r/-E]. Proceeding..."
    echo "|> [SCOPE]: function [core_routine], file [./scripts/packages/neovim-setup.sh]; check: 03"

    # =======================
    #cat /app/plus.sh  | sed -e 's/[A-Z0-9]++/\1PP\2/g'
    if ! (sed -i -e 's/[A-Z0-9]++/\1PP\2/g' "/app/depslist-replaSED_"*); then
        #echo "|> [ERROR]: could not replace every plus sign by "
        echo "|> [ERROR]: could not replace every uppercase, followed by numbers, followed by plus sign, by PP"
        return 1
    fi
    echo "|> [ERROR]: Successfully replaced [--in-place] every uppercase, followed by numbers, followed by plus sign [++], by PP"

    ls -allhtr /app

    # =======================
    if ! (chmod +x -R "/app/depslist"*); then
        echo "|> [ERROR]: it was not possible to change file bits of execution permission [recursively] under [/app]. Exiting now..."
        echo "|> [SCOPE]: function [core_routine], file [./scripts/packages/neovim-setup.sh]; check: 04"
        echo
        return 1
    fi
    echo "|> Sucessfully changed file bits of execution permission [recursively] under [/app]. Proceeding..."
    echo "|> [SCOPE]: function [core_routine], file [./scripts/packages/neovim-setup.sh]; check: 04"
    echo

    ls -allhtr /app

}

set_neovim_deps() {

    if ! core_routine; then
        echo "|> [ERROR]: could not run the function [core_routine]. Exiting now..."
        echo "|> [SCOPE]: function [set_neovim_deps], file [./scripts/packages/neovim-setup.sh]; check: 01"
        return 1
    fi
    echo "|> [PASS]: Successfully ran the function [core_routine]. Proceeding..."
    echo "|> [SCOPE]: function [set_neovim_deps], file [./scripts/packages/neovim-setup.sh]; check: 01"

    #ls -allhtr /app | awk '{print $10}'
    #find /app \( -iname '*depslist-replaSED_*.sh' \)

    ALL_SCRIPTS=`$(find /app \( -iname '*depslist-replaSED_*.sh' \))`

    for JOOJ in "${ALL_SCRIPTS}"; do
        if ! (/bin/sh -c "${JOOJ}"); then
            echo "|> [ERROR]: it was not possible to resolve dependency list for [${JOOJ}]. Exiting now..."
            echo "|> [SCOPE]: function [set_neovim_deps], file [./scripts/packages/neovim-setup.sh]; "
            return 1
        fi
        echo "|> Sucessfully resolved dependency list for [${JOOJ}]. Proceeding..."
    done

    #### CORE_SCRIPTS="$(ls /app)"
}

# single tarball
set_neovim_tarball() {
    NEOVIM_SHOBJ_TARBALL="neovim-tarball-pkg.tar.gz"

    # attempt to install dependencies for neovim
    if ! set_neovim_deps; then
        echo "|> [ERROR]: it was not possible to resolve [neovim] dependencies. Exiting now..."
        echo "|> [SCOPE]: function [set_neovim_tarball], file [./scripts/packages/neovim-setup.sh]; check: 01"
        return 1
    fi
    echo "|> [PASS]: Successfully resolved [neovim] dependencies. Proceeding..."
    echo "|> [SCOPE]: function [set_neovim_tarball], file [./scripts/packages/neovim-setup.sh]; check: 01"

    # set IFS: input field separator
    #IFS='\n\t'
    IFS=`$(printf '\n\t')`

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
    # tar -czf /neovim-single-pkg.tar.gz -T /quux.txt
    tar -czf "/${NEOVIM_SHOBJ_TARBALL}" -T /quux.txt

}

print_usage() {
    cat <<-END >&2
USAGE: neovim-setup [-options]
                - tarball
                - version
                - help
eg,
neovim-setup -tarball # setup the full tarball for neovim-setup
neovim-setup -help    # shows this help message
neovim-setup -version # shows script version

or,
MODE="tarball"  . ./neovim-setup.sh   # setup the full tarball for neovim-setup

See the man page and example file for more info.

END

}

# Check the argument passed from the command line
if ! [ -z "${MODE}" ] &&
    [ "${MODE}" = "build" ] ||
    [ "${MODE}" = "tarball" ]; then
    case "${MODE}" in
    "build") set_neovim_build ;;
    "tarball") set_neovim_tarball ;;
    *)
        echo "Invalid option. Please specify one of: tarball, build"
        print_usage
        ;;
    esac

elif [ "${MODE}" = "help" ] || [ "${MODE}" = "-h" ] || [ "${MODE}" = "--help" ]; then
    print_usage
elif [ "${MODE}" = "version" ] || [ "${MODE}" = "-v" ] || [ "${MODE}" = "--version" ]; then
    printf "\n|> Version: neovim-setup 1.0.0"
else
    echo "Invalid function name. Please specify one of the available functions:"
    print_usage
fi
