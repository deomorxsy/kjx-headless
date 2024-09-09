package system

import (
    "fmt"
    "bytes"
    "context"
    "os"
    "os/exec"
    "testing"
)

func rootfs() {
    ctx := context.Background()

    image_path := "./artifacts/foo.qcow2"

    //mockOptionsFactory
    rootMockOF := &DefaultOptionsFactory{}
    // mockCleanupStrategy
    rootCS := &DefaultCleanupStrategy{}
    // mockExecutor
    rootExecutor := &DefaultCommandExecutor{}

    rootMockOpts := &Options{

    }

}
