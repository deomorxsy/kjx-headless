#!/bin/sh

GHCUP_VERSION="0.1.50.2"
# GHCUP_SHA256="ff6288df9758211372d8242fe830d8e6be6a8365d9406f1c9bde144b7e744143  /usr/bin/ghcup"
GHCUP_SHA256="ff6288df9758211372d8242fe830d8e6be6a8365d9406f1c9bde144b7e744143  /tmp/bin/ghcup"
GHCUP_URI="https://downloads.haskell.org/~ghcup/${GHCUP_VERSION}/x86_64-linux-ghcup-${GHCUP_VERSION}"

GHC_VERSION=9.12.4
CABAL_VERSION=3.16.0.0
STACK_VERSION=3.9.3
PANDOCADA_USER="pandoca"

export GHCUP_VERSION GHCUP_SHA256 GHCUP_URI
export GHCUP_VERSION CABAL_VERSION STACK_VERSION
export PANDOCADA_USER

core_routine() {

    # Install the basic required dependencies to run 'ghcup' and 'stack'
    # bash and shadow needed for stack --docker
    # openssh-client needed for stack private packages
    # binutils-gold needed for ld.gold
    # zlib-static is just a common dependency

    apk upgrade --no-cache &&
        apk add --no-cache \
            curl \
            gcc \
            g++ \
            gmp-dev \
            ncurses-dev \
            libffi-dev \
            zlib-dev \
            make \
            xz \
            tar \
            perl \
            bash \
            shadow \
            openssh-client \
            binutils-gold \
            zlib-static \
            gpg gpg-agent \
            # libx11-dev libxft-dev libxinerama-dev libxrandr-dev libxscrnsaver-dev
    # libxss-dev

    ### # setup keys to check the binaries
    ### gpg --batch --keyserver keyserver.ubuntu.com --recv-keys 7D1E8AFD1D4A16D71FADA2F2CCC85C0E40C06A8C
    ### gpg --batch --keyserver keyserver.ubuntu.com --recv-keys FE5AB6C91FEA597C3B31180B73EDE9E8CFBAEF01
    ### gpg --batch --keyserver keyserver.ubuntu.com --recv-keys 88B57FCF7DB53B4DB3BFA4B1588764FBE22D19C4
    ### gpg --batch --keyserver keyserver.ubuntu.com --recv-keys EAF2A9A722C0C96F2B431CA511AAD8CEDEE0CAEF

}

managers() {

    # Download, verify, and install ghcup
    # as of 17-May-2025, the newest version was 0.1.50.2
    # https://downloads.haskell.org/~ghcup/0.1.50.2/
    # 0.1.30.0 -> 0.1.50.2
    # checksum for version 0.1.30.0: GHCUP_SHA256="fea4499d0cbdf71c554bfb7febebb81d1bcd09a4c4cfb7a90905ef9bff4931cb  /usr/bin/ghcup" &&\
    # checksum for version 0.1.50.2: ff6288df9758211372d8242fe830d8e6be6a8365d9406f1c9bde144b7e744143

    # ff6288df9758211372d8242fe830d8e6be6a8365d9406f1c9bde144b7e744143  ./x86_64-linux-ghcup-0.1.50.2

    # manually setup ghcup
    echo "Downloading and installing ghcup"
    cd /tmp || return

    mkdir -p /tmp/bin/
    if ! wget -O /tmp/bin/ghcup "${GHCUP_URI}"; then
        echo "|> Error: it was not possible to download from the [GHCUP_URI=${GHCUP_URI}]. Exiting now..."
        return 1
    fi
    echo "|> Sucessfully downloaded from the [GHCUP_URI]. Proceeding..."

    if ! printf "%s" "${GHCUP_SHA256}" | sha256sum -c -; then
        echo "|> Error: ghcup checksum failed. Exiting now..." >&2
        return 1
        # exit 1 ;\
    fi
    echo "|> Sucessfully ran ghcup checksum. Proceeding..."

    if ! chmod +x /tmp/bin/ghcup; then
        echo "|> Error: could not change bits of the ghcup binary with [chmod]. Exiting now..."
        return 1
    fi
    echo "|> Sucesfully changed bits of the ghcup binary with [chmod]. Proceeding..."

    cd - || return

    PATH="/tmp/bin/:${PATH}"

    # setup ghc
    mkdir -p /tmp/pandoca
    if ! chown -R "${PANDOCADA_USER}:${PANDOCADA_USER}" "/tmp/pandoca/"; then
        echo "|> Error: it was not possible to chown [/tmp/pandoc]. Exiting now..."
        return 1
    fi
    echo "|> Sucessfully chown [/tmp/pandoc]. Proceeding..."
    echo

    cd /tmp/pandoca || return

    GHCUP_INSTALL_BASE_PREFIX="/home/${PANDOCADA_USER}/"
    export GHCUP_INSTALL_BASE_PREFIX

    if ! (ghcup install ghc "${GHC_VERSION}" &&
        ghcup set ghc "${GHC_VERSION}"); then

        printf "\n|> Error: it was not possible to setup ghc."
        return 1
    fi
    printf "\n|> ghc was successfully installed.\n"

    cd - || return

    # setup cabal
    # if ! (ghcup install cabal $CABAL_VERSION &&
    #     ghcup set cabal $CABAL_VERSION); then
    #
    #     printf "\n|> it was not possible to setup cabal."
    # else
    #     printf "\n|> cabal was successfully installed.\n"
    # fi

    # setup stack
    if ! (ghcup install stack "${STACK_VERSION}" &&
        ghcup set stack "${STACK_VERSION}" &&
        stack config set system-ghc --global true); then

        printf "\n|> it was not possible to setup stack.\n"
        return 1
    fi
    printf "\n|> stack was successfully installed.\n"

}

usermode() {

    GHC_VERSION=9.12.4
    CABAL_VERSION=3.16.0.0
    STACK_VERSION=3.9.3
    PANDOCADA_USER="pandoca"

    PATH="/home/${PANDOCADA_USER}/.ghcup/bin:${PATH}"
    export PATH

    # ghcup install cabal 3.16.0.0
    # ghcup install stack 3.7.1
    # cabal update
    # cabal install

    # sync custom config
    mkdir -p "${HOME}/app/"
    cp -r /app/* "${HOME}/app/"
    cd "${HOME}/app/" || return

    # setup stack
    stack install pandoc-cli
    stack init
    stack build
    stack install

}

set_pandoc_tarball() {

    if ! core_routine; then
        echo "|> Error: could not run the [core_routine] function. Exiting now..."
        echo
        return 1
    fi
    echo "|> Sucessfully ran the [core_routine] function. Proceeding..."
    echo

    getent group "${PANDOCADA_USER}" >/dev/null || addgroup --gid 1000 "${PANDOCADA_USER}"

    # PANDOCA_GID=$(getent group "${PANDOCADA_USER}" | cut -d: -f3)

    getent passwd "${PANDOCADA_USER}" >/dev/null ||
        adduser --shell /bin/bash \
            --uid 1000 \
            -G "${PANDOCADA_USER}" \
            --gecos "" \
            --disabled-password \
            --home "/home/${PANDOCADA_USER}" \
            "${PANDOCADA_USER}"

    mkdir -p "/home/${PANDOCADA_USER}/app/"

    if ! chown -R "${PANDOCADA_USER}:${PANDOCADA_USER}" "/home/${PANDOCADA_USER}/app/"; then
        echo "|> Error: it was not possible to change bits recursively for the home directory of [PANDOCADA_USER=$PANDOCADA_USER]. Exiting now..."
        return 1
    fi
    echo "|> Sucessfully changed bits recursively for the home directory of [PANDOCADA_USER]. Proceeding..."

    if ! managers; then
        echo "|> Error: could not run the managers function. Exiting now..."
        return 1
    fi
    echo "|> Sucessfully ran the managers function. Proceeding..."

    PATH="/home/${PANDOCADA_USER}/.ghcup/bin:${PATH}"
    export PATH

    if ! su "${PANDOCADA_USER}" -c '
    cp /app/scripts/pandoc-setup.sh "${HOME}/"
    cd "${HOME}" || return
    chmod +x "${HOME}/pandoc-setup.sh"

    MODE="usermode" . ./pandoc-setup.sh
    '; then
        echo "|> Error: could not run script with [su] as the [PANDOCADA_USER=${PANDOCADA_USER}] user. Exiting now..."
        return 1
    fi
    echo "|> Sucessfully ran the [usermode] function setup with [su] as the [PANDOCADA_USER=${PANDOCADA_USER}] user. Proceeding..."
    echo

    echo "|> Sucessfully finished the [pandoc-setup.sh] script."
    return

    touch "/home/pandoca/pandoc-tarball-pkg.tar.gz"

}

print_usage() {
    cat <<-END >&2
USAGE: pandoc-setup.sh [-options]
                - pandoc-tarball
                - version
                - help
eg,
MODE="pandoc-tarball"   ./pandoc-setup.sh   # setup pandoc (musl)
MODE="usermode"
MODE="managers"
MODE="version"      ./pandoc-setup.sh   # shows script version
MODE="help"         ./pandoc-setup.sh   # shows this help message

See the man page and example file for more info.

END

}

# Check the argument passed from the command line
if ! [ -z "${MODE}" ] &&
    [ "${MODE}" = "usermode" ] ||
    [ "${MODE}" = "pandoc-tarball" ]; then
    case "${MODE}" in
    "usermode") usermode ;;
    "pandoc-tarball") set_pandoc_tarball ;;
    *)
        echo "Invalid option. Please specify one of: pandoc-tarball help version"
        print_usage
        ;;
    esac

elif [ "${MODE}" = "help" ] || [ "${MODE}" = "-h" ] || [ "${MODE}" = "--help" ]; then
    print_usage
elif [ "${MODE}" = "version" ] || [ "${MODE}" = "-v" ] || [ "${MODE}" = "--version" ]; then
    printf "\n|> Version: pandoc-setup 1.0.0"
else
    echo "Invalid function name. Please specify one of the available functions:"
    print_usage
fi
