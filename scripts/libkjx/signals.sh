# signals are asynchronous

stop_signal = 0

smoke_handler() {
    if [[ stop_signal != 1 ]]; then
        echo "running... . . ."
        # trap action condition1 condition2
        stop_signal=1
        capabilities=$(getpcaps $pid)
        if $capabilities
    else
        echo "signal stopped."
        exit
    fi
}


trap smoke_handler SIGINT


while true
do
    echo "sleeping!"
    sleep 15
done

stop_signal = 0

smoke_handler() {
    if [[ stop_signal != 1 ]]; then
        echo "running... . . ."
        # trap action condition1 condition2
        stop_signal=1
        capabilities=$(getpcaps $pid)
        if $capabilities
    else
        echo "signal stopped."
        exit
    fi
}


trap smoke_handler SIGINT


while true
do
    echo "sleeping!"
    sleep 15
done


if [ "$1" = "getcap" ]; then
     pid=$$
     capabilities=$(getpcaps $pid)
     printf "Process %s capabilities: %s\n" "$pid" "$capabilities"
     return $pid
     smoke
     #return ("process capabilities: %s", $capabilities)
fi

if []
