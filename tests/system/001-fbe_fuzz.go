package system

import (
    "os"
    "os/exec"
    "fmt"
    "testing"
    "bytes"
    "io/ioutil"
)

// fuzz test
func FuzzCheckPart(f *testing.F) {
    f.Add("checkpart")

    // fuzz target
    f.Fuzz(func(t *testing.T, i int, s string){ //input []byte) {
        tmpFile, err := ioutil.TempFile("", "fuzz-checkpart-input")
        if err != nil {
            t.Fatalf(err)
        }
        defer os.Remove(tmpFile.Name())

        if _, err := tmpFile.Close(); err != nil {
            t.Fatalf(err)
        }


        // build command
        cmd := exec.Command("/bin/busybox", "sh", "../../scripts/fuse-blkexp.sh", input)

        // get stdout
        var out bytes.Buffer
        cmd.Stdout = &out

        // run command and check for errors
        if err := cmd.Run(); err != nil {
            t.Logf("fuzz input: %s\n", string(input))
            t.Logf("command error: %v\n", err)
            t.Logf("command output: %v\n", out.String())
        }
    })
}
