package system

import (
    "os"
    "os/exec"
    "fmt"
    "testing"
)

func FuzzCheckPart(f *testing.F) {
    f.Add("checkpart")
    f.Fuzz(func(t *testing.T, input string)) {
        cmd := exec.Command("/bin/busybox", "sh", "../../scripts/fuse-blkexp.sh", input)
    }
}
