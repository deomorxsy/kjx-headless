#!/usr/bin/bash
#
# ccr: check container runtime
#

registry() {
    checker
}

dddsad(){
    echo
}

checker() {
    exists_wgh=$(which podman 2>&1 | grep -o "no" | head -n 1)
    exists_command=$(command -v podman &>/dev/null)

    # bash square bracket eval to check for empty expanded variable in a string,
    # AND if the podman binary have a path.
    if [ "$exists_command" == '1' ]; then
        echo 'Using default DOCKER_HOST...'
        return
    # if true, command with the v flag outputs a line.
    elif $exists_command; then
        echo 'Podman found. Invoking podman_compose...'
        # hook to set podman service (systemd socket unit file) as DOCKER_HOST
        podman_compose
        return
    fi
}

podman_compose() {
# systemd creates the podman UNIX socket under /run/user/1000/podman/
# that have a File Descriptor
systemctl --user start podman.socket

# if isn't already set, replace the DOCKER_HOST environment variable for the podman UNIXsocket
if [ -z "$DOCKER_HOST" ]; then
    export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"
fi

# curl acts as a client making a request to the systemd's socket unit file (Podman API Socket),
# which triggers the podman service unit file. podman.service inherits the socket File Descriptor
# and accept connection; this is an instance of a podman process in running state.
curl -H "Content-Type: application/json" --unix-socket "$XDG_RUNTIME_DIR/podman/podman.sock" http://127.0.0.1/_ping
printf "\n\n"
# source this file before running docker compose
####

#docker compose -f ./oci/container-compose.yml build
}

