#!/bin/env bats

function setup() {

    load ../../scripts/fuse-blkexp.sh
    # Makes test logs easier to read
    BATS_TEST_NAME_PREFIX="[001] "

}

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

@test "Test 2nd step: checkpart" {
    run _test_2_checkpart

    assert_output --partial '[EXIT]: It seems there is already a partition in this file.\n'
    assert_exist "$STORAGE"

    expected=$(cat <<-TXT
bar.img
)

    if ["${output}" = "${expected}"]; then
        teardown
    elif [ "bar.img" in "${expected}" ]; then

    fi
}

teardown(artifacts) {
    rm -rf "$STORAGE"
}

teardown_file() {
    rm -rf "$STORAGE"
}

#if [ "$1" = "_test_2_checkpart" ]; then
#    _test_2_checkpart
#elif [ "$1" = "function2" ]; then
#    function2
#elif [ "$1" = "function3" ]; then
#    function3
#elif [ "$1" =  "*" ]; then
#    echo "Invalid function name. Please specify one of: function1, function2, function3"
#else
#    echo "EXITING NOW...."
#fi
#}


