#!/bin/sh

#
#DATA_SOURCE=$(. ./trace/Ftrace/)

FTRACE_DIR=/sys/kernel/debug/tracing
OUT_FILE=$(mktemp -t)
SECS=10

#TARGET_PID=$()

ftrace_pipeline() {
# --------- data sources

#echo 1 > "$FTRACE_DIR"/events/

# /*
# * --------- ensure it is going to work in
# *           the busybox fork of posix shell -----------
# *
# set trace types



set -- \
    function function_graph blk \
    hwlat irqsoff preepmptoff \
    preemptirqsoff wakeup wakeup_rt \
    wakeup_dl mmiotrace branch \
    nop
# create
somefile=$(mktemp -t)

# set the parameter number for the specific function
echo "$1" > "$somefile"

# or just echo $2
TRACER=$(cat "$somefile")
rm "$somefile"

# * -----------------------------------------------------





# --------- actual tracing

# ensure that tracing is enabled for Ftrace
echo 1 | sudo tee "$FTRACE_DIR"/tracing_on

# set the Ftrace filter for functions by the matching below
echo '*sleep' | sudo tee "$FTRACE_DIR"/set_ftrace_filter

# set Ftrace's current tracer file to get function traces
echo "$TRACER" | sudo tee "$FTRACE_DIR"/current_tracer

sleep "$SECS"

# copy the result of the trace for later analysis
sudo cp "$FTRACE_DIR"/trace "$OUT_FILE"

# set no operation for Ftrace's current tracer file
echo nop | sudo tee "$FTRACE_DIR"/current_tracer

# overwrite the Ftrace filter to none
echo | sudo tee "$FTRACE_DIR"/set_ftrace_filter

# finally print the output
sudo chown "$USER":users "$OUT_FILE"

cat "$OUT_FILE"
}


print_usage() {
cat <<-END >&2
USAGE: kerfuncs [-]


USAGE: kerfuncs [-options] [-m source] [-p PID] [-L TID] [-d secs] funcstring
                - f     - function
                - fg    - function_graph
                - blk   - block I/O
                - hwl   - hwlat (hardware latency)
                - irq   - irqsoff (interrupts off)
                - po    - preemptoff
                - pis   - preemptirqsoff
                - wu    - wakeup
                - wrt   - wakeup_rt
                - wdl   - wakeup_dl
                - mt    - mmiotrace
                - bra   - branch
                - nop   - nop (no operation profiling)
eg,
kerfuncs do_nanosleep    # trace do_nanosleep() and children
kerfuncs -f 3 do_sys_open # trace do_sys_open() to 3 levels only
kerfuncs -a do_sys_open    # include timestamps and process name
kerfuncs -p 198 do_sys_open # trace vfs_read() for PID 198 only
kerfuncs -d 1 do_sys_open >out # trace 1 sec, then write to file

See the man page and example file for more info.

END

exit
}

# check valid input
if ps -p "$1" | awk 'NR==2 {print $1}'; then
    ftrace_pipeline "$1"
else
    printf "\nThe PID doesn't exist. Exiting...\n\n"
fi

