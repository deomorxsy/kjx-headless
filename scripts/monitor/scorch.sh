#!/bin/sh
#

caller() {

TGID="$1"

mkdir -p ./artifacts/stacktraces
mkdir -p ./artifacts/flamegraphs


STACKCOUNT_OUTPUT="./artifacts/stacktraces/out.stackcount.txt"
FLAMEGRAPH_OUTPUT="./artifacts/flamegraphs/out.stackcount.svg"

# kprobe:vfs_* /pid == 37008 / { @[ustack, comm, func] = count(); }
# interval:s:10 { exit(); }


# printf("%-6d %-16s %s\n", pid, comm, str(args.filename));
(
sudo timeout 30s bpftrace -e '

kprobe:syscalls:sys_enter_open,
kprobe:syscalls:sys_enter_openat {
    @start[tid] = nsecs;
}

kretprobe:syscalls:sys_enter_open,
kretprobe:syscalls:sys_enter_openat
/@start[tid]/{
    $duration_us = (nsecs - @start[tid]) / 1000;
    @us = hist($duration_us);
    delete(@start[tid]);
}

'
) | tee "${STACKCOUNT_OUTPUT}"
#
./assets/FlameGraph/flamegraph.pl \
    --hash \
    --bgcolors=grey \
    < "${STACKCOUNT_OUTPUT}" \
    > "${FLAMEGRAPH_OUTPUT}"
}

print_usage() {
cat <<-END >&2
USAGE: scorch [-options]
                - pid/tgid
                - version
                - help
eg,
scorch -p   # runs qemu pointing to a custom initramfs and kernel bzImage
scorch -version # shows script version
scorch -help    # shows this help message

See the man page and example file for more info.

END

}


# Check the argument passed from the command line
if [ "$MODE" = "pid" ] || [ "$MODE" = "-pid" ] || [ "$MODE" = "--pid" ]; then
    checker "$MODE"
elif [ "$1" = "help" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    print_usage
elif [ "$1" = "version" ] || [ "$1" = "-v" ] || [ "$1" = "--version" ]; then
    printf "version"
else
    echo "Invalid function name. Please specify one of: function1, function2, function3"
    print_usage
fi


