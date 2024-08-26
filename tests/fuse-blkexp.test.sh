#!/bin/busybox sh

_test_2_checkpart() {

STORAGE=./artifacts/bar.img

truncate -s 100M $STORAGE

runner=$(source ./scripts/fuse-blkexp.sh checkpart $STORAGE)

if [ "$runner" = 0 ]; then
    printf "\n|=> [PASSED]: Test 2: checkpart\nCleaning..."
    # Cleanup
    rm $STORAGE
    printf "Cleaning complete.\n"
else
    printf "\nFAILED!\n"

fi
}

if [ "$1" = "_test_2_checkpart" ]; then
    _test_2_checkpart
elif [ "$1" = "function2" ]; then
    function2
elif [ "$1" = "function3" ]; then
    function3
elif [ "$1" =  "*" ]; then
    echo "Invalid function name. Please specify one of: function1, function2, function3"
else
    echo "EXITING NOW...."
fi
