#!/bin/sh
UPPER_MOUNTPOINT="./artifacts/qcow2-rootfs"
KJX="/mnt/kjx"
ROOTFS_PATH="$UPPER_MOUNTPOINT/rootfs"

core_routine() {
    mkdir -p /app/scripts/packages

    DEPSLIST="/app/scripts/packages/demo-replased.sh"
    export DEPSLIST

    CORE_KATA_DEPS="$(
        apk dot busybox-binsh libbsd musl linux-pam shadow doas \
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
    export CORE_KATA_DEPS

    if ! [ -f "${DEPSLIST:-[EMPTY_VARIABLE]}" ]; then

        # cp
        echo "|> Error: it was not possible to resolve dependency list for [kata]. Exiting now..."
        echo "|> SCOPE: [core_routine], file [./scripts/packages/kata-startup.sh]; check: 01"
        echo
        return 1
    fi
    echo "|> Successfully resolved dependency list for [kata]. Proceeding..."
    echo "|> SCOPE: [core_routine], file [./scripts/packages/kata-startup.sh]; check: 01"
    echo

    # generalize the install by replacing every placeholder with the desired dependency
    if ! (for f in $CORE_KATA_DEPS; do
        COREUPPER="$(echo "$f" | tr '[:lower:]' '[:upper:]')"
        export COREUPPER

        sed -e "s/PKGNAME_PKGDEPS_PLACEHOLDER/KATA_PKGDEPS_PLACEHOLDER/g" -e "s/PLACEHOLDER/$COREUPPER/g" -e "s/placeholder/$f/g" "${DEPSLIST:-[EMPTY_VARIABLE]}" >"/app/depslist-replaSED_$f.sh"
    done); then
        echo "|> Error: could not replace every PLACEHOLDER with the uppercase string of the name of the dependency and every lowercase with its counterpart. Exiting now..."
        echo "|> SCOPE: [core_routine], file [./scripts/packages/kata-startup.sh]; check: 02"
        echo
        return 1
    fi
    echo "|> Successfully replaced every PLACEHOLDER with the uppercase string of the name of the dependency and every lowercase with its counterpart. Proceeding..."
    echo "|> SCOPE: [core_routine], file [./scripts/packages/kata-startup.sh]; check: 02"
    echo

    # now use the extended regex [-r/-E] to replace hyphen between uppecase characters
    if ! (sed --in-place -E 's/([A-Z0-9])-([A-Z0-9])/\1_\2/g' /app/depslist-replaSED_*); then
        echo "|> Error: could not replace every hyphen between uppercase characters into an underscore with sed and extended regex [-r/-E]. Exiting now..."
        echo "|> SCOPE: [core_routine], file [./scripts/packages/kata-startup.sh]; check: 03"
        return 1
    fi
    echo "|> Successfully replaced every hyphen between uppercase characters into an underscore with sed and extended regex [-r/-E]. Proceeding..."
    echo "|> SCOPE: [core_routine], file [./scripts/packages/kata-startup.sh]; check: 03"

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
        echo "|> SCOPE: [core_routine], file [./scripts/packages/kata-startup.sh]; check: 04"
        echo
        return 1
    fi
    echo "|> Sucessfully changed file bits of execution permission [recursively] under [/app]. Proceeding..."
    echo "|> SCOPE: [core_routine], file [./scripts/packages/kata-startup.sh]; check: 04"
    echo

    ls -allhtr /app

}

set_kata_deps() {

    if ! core_routine; then
        echo "|> Error: could not run the function [core_routine]. Exiting now..."
        echo "|> SCOPE: [set_kata_deps], file [./scripts/packages/kata-startup.sh]; check: 01"
        return 1
    fi
    echo "|> Successfully ran the function [core_routine]. Proceeding..."
    echo "|> SCOPE: [set_kata_deps], file [./scripts/packages/kata-startup.sh]; check: 01"

    #ls -allhtr /app | awk '{print $10}'
    find /app \( -iname '*depslist-replaSED_*.sh' \)

    ALL_SCRIPTS="$(find /app \( -iname '*depslist-replaSED_*.sh' \))"

    for jooj in $ALL_SCRIPTS; do
        if ! (/bin/sh -c "$jooj"); then
            echo "|> Error: it was not possible to resolve dependency list for [$jooj]. Exiting now..."
            echo "|> SCOPE: [set_kata_deps], file [./scripts/packages/kata-startup.sh]; "
            return 1
        fi
        echo "|> Sucessfully resolved dependency list for [$jooj]. Proceeding..."
    done

    #### CORE_SCRIPTS="$(ls /app)"
}

# single tarball
set_kata_tarball() {

    if ! set_kata_deps; then
        echo "|> Error: it was not possible to resolve [kata] dependencies. Exiting now..."
        echo "|> SCOPE: [set_kata_tarball], file [./scripts/packages/kata-startup.sh]; check: 01"
        return 1
    fi
    echo "|> Successfully resolved [kata] dependencies. Proceeding..."
    echo "|> SCOPE: [set_kata_tarball], file [./scripts/packages/kata-startup.sh]; check: 01"

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
    # tar -czf /kata-single-pkg.tar.gz -T /quux.txt
    tar -czf /kata-tarball-pkg.tar.gz -T /quux.txt

}

kata_rc_containerd() {
    # Context: isogen (it sets )

    # Create runtime class for Kata Containers
    # future symlink to "$ROOTFS_PATH/etc/runit/runsvdir/kata/kataRC.yaml"

    (
        cat <<EOF
# RuntimeClass is defined in the node.k8s.io API group
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  # The name the RuntimeClass will be referenced by.
  # RuntimeClass is a non-namespaced resource.
  name: kata
# The name of the corresponding CRI configuration
handler: kata
EOF
    ) | tee "$ROOTFS_PATH/etc/sv/kata/kataRC.yaml"

    # Registry has to have
    (
        cat <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: nginx-kata
spec:
  runtimeClassName: kata
  containers:
  - name: nginx
    image: nginx

EOF
    ) | tee nginx-kata.yaml

}

kata_misc() {
    sed -i 's/runtimeClassName: kata/runtimeClassName: youki/' ./deploy/k3s/deployment.yaml
    sed '/spec:/a \  runtimeClassName: kata' ./deploy/k3s/deployment.yaml

    #cat << EOF | tee kjx-kata.yaml
    #apiVersion: v1
    #kind: Pod
    #metadata:
    #  name: kjx-kata
    #spec:
    #  runtimeClassName: kata
    #  containers:
    #  - name: kjx-build
    #    image: kjx_linux_x64:01
    #
    #EOF

    # future symlink to $ROOTFS_PATH/etc/runit/runsvdir/kata/kubectl.yaml
    cat >"$ROOTFS_PATH/etc/sv/k3s/kata" <<EOF
# create pod
sudo -E kubectl apply -f ./nginx-kata.yaml

# check pod state
sudo -E k3s kubectl get pods -n kjx-kata

# check type-1 vmm (hypervisor) state
#ps aux | grep qemu
pgrep -l qemu
EOF

    cat >"$ROOTFS_PATH/etc/sv/kata/run" <<EOF
exec /usr/bin/kata-runtime --log=/var/log/kata.log --agent-log=/var/log/kata-agent.log
EOF

    # delete_pod()
    sudo -E k3s kubectl delete -f nginx-kata.yaml

}

print_usage() {
    cat <<-END >&2
USAGE: kata-startup.sh [-options]
                - kata-tarball
                - version
                - help
eg,
MODE="kata-so"    ./kata-startup.sh   # setup kata-startup shared objects
MODE="kata-bin"   ./kata-startup.sh   # setup kata (musl) dynamically linked binaries
MODE="version"      ./kata-startup.sh   # shows script version
MODE="help"         ./kata-startup.sh   # shows this help message

See the man page and example file for more info.

END

}

# Check the argument passed from the command line
if ! [ -z "${MODE}" ] &&
    [ "${MODE}" = "kata-so" ] ||
    [ "${MODE}" = "kata-bin" ] ||
    [ "${MODE}" = "kata-tarball" ]; then
    case "${MODE}" in
    "kata-so") set_kata_so ;;
    "kata-bin") set_kata_bin ;;
    "kata-tarball") set_kata_tarball ;;
    *)
        echo "Invalid microvm. Please specify one of: kata-so, kata-bin"
        print_usage
        ;;
    esac

elif [ "${MODE}" = "help" ] || [ "${MODE}" = "-h" ] || [ "${MODE}" = "--help" ]; then
    print_usage
elif [ "${MODE}" = "version" ] || [ "${MODE}" = "-v" ] || [ "${MODE}" = "--version" ]; then
    printf "\n|> Version: kata-setup 1.0.0"
else
    echo "Invalid function name. Please specify one of the available functions:"
    print_usage
fi
