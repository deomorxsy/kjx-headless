#!/bin/sh

# =======================
#  user, groups and shadow password management
packaja_dotfiles() {
    # Configure passwd management
    (
        cat <<EOF
root:x:0:0:root:/root:/bin/ash
kjx:x:1000:1000:kjx:/home/kjx:/bin/ash
EOF
    ) | tee "${ROOTFS_PATH:-[EMPTY_STR]}"/etc/passwd

    # Configure groups management
    (
        cat <<EOF
root:x:0:
bin:x:1:
EOF
    ) | tee "${ROOTFS_PATH:-[EMPTY_STR]}"/etc/group

    # Setup doas superuser management
    #
    echo "permit persist :wheel" >>"${ROOTFS_PATH:-[EMPTY_STR]}"/etc/doas.d/20-wheel.conf

    # Setup ash shell dotfiles

    # Openrc-based profile.d
    (
        cat <<EOF
if [ -f "${HOME:-[EMPTY_STR]}/.config/ash/profile" ]; then
	. "${HOME:-[EMPTY_STR]}/.config/ash/profile"
fi
EOF
    ) | tee "${ROOTFS_PATH:-[EMPTY_STR]}"/etc/profile.d/profile.sh

    # Ash profile
    (
        cat <<EOF
export ENV="${HOME:-[EMPTY_STR]}"/.config/ash/ashrc"
EOF
    ) | tee "${ROOTFS_PATH:-[EMPTY_STR]}"/home/kjx/.config/ash/profile
    echo "su="doas -s"" >>"${ROOTFS_PATH:-[EMPTY_STR]}"/home/kjx/.config/ash/ashrc

}

packaja() {

    packaja_dotfiles

    # Setup usgp-man with shadow and iptables networking
    if ! (INSTALL_PKG="set_network set_shadow" . ./scripts/packages/usgp-man.sh); then
        echo "|> Error: could not "
        return 1
    fi

}
