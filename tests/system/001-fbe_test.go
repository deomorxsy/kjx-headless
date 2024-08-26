package system

import (
    //"fmt"
	"os"
    "os/exec"
	"testing"
    "strings"
)


// t for unit testing and f for fuzzing
func TestCheckPart(t *testing.T) {
    // 2a. create: test image file artifact
    testImg := "./test.img"
    err := exec.Command("truncate", "-s", "100M", testImg).Run()
    if err != nil {
        //t.Fatalf("Failed to create test image: %v", err)
        t.Fatalf("Failed to create test image: %v", err)
    }

    // 2b. clean: artifact by sending the
    // remove destructor to the post-return
    // execution stack
    defer os.Remove(testImg)

    // 3. run: shellscript / declaration+assign
    cmd := exec.Command("/bin/busybox", "sh", "../../scripts/fuse-blkexp.sh", "checkpart", testImg)
    output, err := cmd.CombinedOutput()

    // 4. check: output validation
    if err != nil {
        //t.Fatalf("hmmmm")
        //f.Fatalf("Failed to execute shell script: %v\nOutput: %s", err, string(output))
        t.Fatalf("Failed to execute shell script: %v\nOutput: %s", err, string(output))
        //fmt.Print("the error is: %v", output)
    }

    // 5. validate: output verification
    if !strings.Contains(string(output), "[EXIT]: It seems there is already a partition in this file.") {
        //f.Fatalf("Unexpected output: %s", string(output))
        t.Fatalf("Unexpected output: %s", string(output))
    }

    // 6. validate: check partition / assign
    output, err = exec.Command("/bin/busybox", "parted", "-s", testImg, "print").Output()
    if err != nil {
        //f.Fatalf("Failed to check partition: %v", err)
        t.Fatalf("Failed to check partition: %v", err)

    }

   if !strings.Contains(string(output), "ext4") {
       //f.Fatalf("This raw virtual disk sparse file doesn't have a ext4 filesystem on its partition table..")
       t.Fatalf("This raw virtual disk sparse file doesn't have a ext4 filesystem on its partition table..")
   }




}
