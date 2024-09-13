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
    // mockCleanupStrategy
    // mockExecutor

    rootMockOF := &DefaultOptionsFactory{}
    rootCS := &DefaultCleanupStrategy{}
    rootExecutor := &DefaultCommandExecutor{}

    rootMockOpts := &Options{

    }

}
