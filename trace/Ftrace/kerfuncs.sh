#!/bin/sh

#
#DATA_SOURCE=$(. ./trace/Ftrace/)

FTRACE_DIR=/sys/kernel/debug/tracing
OUT_FILE=$(mktemp -t)
SECS=10

#TARGET_PID=$()
#TRACE_TYPE=""

TRACE_TYPE_POOL=$(
    cat <<EOF
    function function_graph blk \
    hwlat irqsoff preepmptoff \
    preemptirqsoff wakeup wakeup_rt \
    wakeup_dl mmiotrace branch \
    nop
EOF
)

ftrace_pipeline() {
    # --------- Data sources logic
    CHOSEN_FUNTRACER="${USR_TRACE_FUNCTION}"

    # --------- Tracing steps

    #  tell Ftrace to get traces from this PID only
    if ! echo "${TARGET_PID}" | sudo tee "${FTRACE_DIR}/set_ftrace_pid"; then
        echo "|> Error: it was not possible to write ${TARGET_PID:-[EMPTY_VAR]} to get traces from this PID only. Exiting now..."
        echo && echo
        return 1
    fi

    # ensure that tracing is enabled for Ftrace
    if ! echo 1 | sudo tee "$FTRACE_DIR"/tracing_on; then
        echo "|> Error: failed in writing to [$FTRACE_DIR/tracing_on] in order to ensure tracing is enabled for Ftrace. Exiting now..."
        echo && echo
        return 1
    fi
    echo "|> wrote to [$FTRACE_DIR/tracing_on] to ensure tracing is enabled for Ftrace with success."

    # set the Ftrace filter for functions by the matching below
    if ! echo '*sleep' | sudo tee "$FTRACE_DIR"/set_ftrace_filter; then
        echo "|> Error: it was not possible write to [$FTRACE_DIR/set_ftrace_filter] with the filter for functions. Exiting now..."
        echo && echo
        return 1
    fi
    echo "|> wrote to $FTRACE_DIR/set_ftrace_filter using the filter for functions with success."

    # set Ftrace's current tracer file to get function traces
    if ! echo "${CHOSEN_FUNTRACER}" | sudo tee "$FTRACE_DIR"/current_tracer; then
        echo "|> Error: it was not possible to write to [$FTRACE_DIR/current_tracer] to get function traces from the current tracer. Exiting now..."
        echo && echo
        return 1
    fi
    echo "|> wrote to $FTRACE_DIR/current_tracer to get function traces from the current tracer with success."

    sleep "$SECS"

    # copy the result of the trace for later analysis
    if ! sudo cp "$FTRACE_DIR"/trace "$OUT_FILE"; then
        echo "|> Error: it was not possible to copy [$FTRACE_DIR/trace] to [OUT_FILE=$OUT_FILE] for later analysis. Exiting now..."
        echo && echo
        return 1
    fi
    echo "|> Copied [$FTRACE_DIR/trace] to [OUT_FILE=$OUT_FILE] for later analysis with success."

    # set no operation for Ftrace's current tracer file
    if ! echo nop | sudo tee "$FTRACE_DIR"/current_tracer; then
        echo "|> Error: it was not possible to set No-OPeration [NOP] for [$FTRACE_DIR/current_tracer] file. Exiting now..."
        echo && echo
        return 1
    fi
    echo "|> Set No-OPeration [NOP] for Ftrace's current tracer file with success."

    # overwrite the Ftrace filter to none
    if ! echo | sudo tee "$FTRACE_DIR"/set_ftrace_filter; then
        echo "|> Error: it was not possible to overwrite the [$FTRACE_DIR/set_ftrace_filter] to [none]. Exiting now..."
        echo && echo
        return 1
    fi
    echo "|> Overwrote the [$FTRACE_DIR/set_ftrace_filter] file to [none] with success."

    # change ownership of the OUT_FILE.
    if ! sudo chown "$USER":users "$OUT_FILE"; then
        echo "|> Error: it was not possible to change the ownership of the [OUT_FILE=$OUT_FILE] . Exiting now..."
        echo && echo
        return 1
    fi
    echo "|> Changed the ownership of the [OUT_FILE=$OUT_FILE] with success."

    # finally print the output
    if ! cat "$OUT_FILE"; then
        echo "|> Error: it was not possible to print the output of [OUT_FILE=$OUT_FILE] . Exiting now..."
        echo && echo
        return 1
    fi
    echo "|> Printed the output of [OUT_FILE=$OUT_FILE] with success."
    echo && echo
}

print_usage() {
    cat <<-END >&2
USAGE: kerfuncs [-]

# USAGE: TARGET_PID="xxx" USR_TRACE_FUNCTION=""  USR_TRACE_FILTER="dsadas" . ./trace/Ftrace/kerfuncs.sh
# USAGE: kerfuncs [-options] [-m source] [-p PID] [-L TID] [-d secs] funcstri

eg,
TARGET_PID="xxx" USR_TRACE_FUNCTION="" USR_TRACE_FILTER="do_sys_open" . ./trace/Ftrace/kerfuncs.sh
kerfuncs -f 3 do_sys_open # trace do_sys_open() to 3 levels only
kerfuncs -a do_sys_open    # include timestamps and process name
kerfuncs -p 198 do_sys_open # trace vfs_read() for PID 198 only
kerfuncs -d 1 do_sys_open >out # trace 1 sec, then write to file

See the man page and example file for more info.

END
}

# USAGE: TARGET_PID="xxx" USR_TRACE_FUNCTION=""  USR_TRACE_FILTER="dsadas" . ./trace/Ftrace/kerfuncs.sh
# USAGE: kerfuncs [-options] [-m source] [-p PID] [-L TID] [-d secs] funcstring

# run with:
# TARGET_PID="yyy" USR_TRACE_FUNCTION="zzz" . ./trace/Ftrace/kerfuncs.sh

# Check if the provided TARGET_PID is valid
if ! ps -p "$TARGET_PID" | awk 'NR==2 {print $1}'; then
    echo "|> Error: TARGET_PID=$TARGET_PID does is not in a running state on the system. Exiting now..."
    echo && echo
    return 1
fi
echo "|> The provided TARGET_PID=$TARGET_PID was found in a running state on the system. Proceeding..."
echo && echo

# check if the USR_TRACE_FUNCTION is inside the TRACE_TYPE_POOL
if ! [ "*$USR_TRACE_FUNCTION*" = "$TRACE_TYPE_POOL" ]; then
    echo "|> Error: USR_TRACE_FUNCTION=$USR_TRACE_FUNCTION is not part of the TRACE_TYPE_POOL=$TRACE_TYPE_POOL. Exiting now..."
    echo && echo
    return 1
fi
echo "|> USR_TRACE_FUNCTION was recognized as part of the TRACE_TYPE_POOL. Proceeding..."
echo && echo

if ! ftrace_pipeline; then
    echo "|> Error: it was not possible to run the function [ftrace_pipeline]. Exiting now..."
    echo && echo
    return 1
fi
echo "|> [ftrace_pipeline] was run with success. Exiting now..."
echo && echo
