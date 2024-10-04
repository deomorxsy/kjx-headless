//package system
//package other

import (
    "fmt"
	"os"
    "os/exec"
	"testing"
    "strings"
)

// 00 . Dependency Injection skeleton
type qsDaemon interface {
    qsDae() (string, error)
    start() (string, error)
    stop() (string, error)
}

type systemDeps interface {
    startQemu(args, ...string) error
    startParted(args, ...string) error
    //
    runKpartx(args, ...string) error
    //
    runQSD()

}

type resource struct {
    cmd systemDeps

}


func (dd *resource) Run() {
    dd.cmd.startQemu
    dd.cmd.startParted
    dd.cmd.runKpartx
    dd.cmd.runQSD
}

type idk func(*House)

// constructor function
func newHouse(opts ...idk) *House {
    const (
        defaultSmt = 2
        defaultOther = true
        defaultMm = "food"
    )

    h := &House {
        Mm: defaultMm,
        Other: defaultOther,
        Smt: defaultSmt,
    }

    // loop through each option
    for _, opt := range opts {
        opt(h)
    }

    // modified house instance
    return h
}
//qemu-img-create, parted, qemu-img-convert, kpartx, qemu-storage-daemon
type qic struct {}

func (dd *qic) Run()

func qsDaemonSpec(t *testing.TB, qsd qsDaemon) {
    output, err := qsd.qsDae()
    assert.NoError(t, err)
    asser.Equal(t, output, "Hello, world!")
}



// 2. checkPart t for unit testing and f for fuzzing
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
        t.Fatalf("Failed to execute shell script: %v\nOutput: %s", err, string(output))
    }

    // 5. validate: output verification
    if !strings.Contains(string(output), "[EXIT]: It seems there is already a partition in this file.") {
        t.Fatalf("Unexpected output: %s", string(output))
    }

    // 6. validate: check partition / assign
    //output, err = exec.Command("parted", "-s", testImg, "print").Output()
    //if err != nil {
    //    t.Fatalf("Failed to check partition: %v", err)

    //}

   //if !strings.Contains(string(output), "ext4") {
       //t.Fatalf("This raw virtual disk sparse file doesn't have a ext4 filesystem on its partition table..")
   //}

}

// 3. showasblock
func TestShowAsBlock(t *testing.T) {
    testImg := "./test.img"
    testQcow := "./test.qcow2"

    err := exec.Command(
        "qemu-img", "convert",
        "-p", "-f", "raw",
        "-O", "qcow2",
        testImg, testQcow,
        "&&", "rm", testImg,
    ).Run()

    if err != nil {
//t.Fatalf("Failed to create test image: %v", err)
        t.Fatalf("[Test 3] Failed to create test image: %v", err)
    }

    // 3b. clean: artifact by sending the
    // remove destructor to the post-return
    // execution stack
    defer os.Remove(testImg)
    defer os.Remove(testQcow)

    err := exec.Command("file", testQcow).Run()

    if err != nil {
        t.Fatalf("[Test 3] Failed to file the qcow test image: %v", err)
    }

    // remember using capabilities-enabled kpartx here
    // so sudo isn't needed
    err := exec.Command("kpartx", "-l", testQcow).Run()
    if err != nil {
        t.Fatalf("[Test 3]Failed to use kpartx on the Qcow image: %v", err)
    }
}

// 4. qsd_up
func testQsdUp(t *testing.T)  {
    testQcow_path = "./artifacts/test.Qcow"
    new_fmt_mp = testQcow_path


    //fuse_uao_check
    grepa := exec.Command(
    "grep", "-n", "'#user_allow_other'", "'/etc/fuse.conf'",
    "|", "tail", "-1",
    "|", "awk", "-F", ":", "{print $2}",
    )

    output, err := grepa.Output()

    if err != nil {
        t.Fatalf("[Test 4] Failed to grep /etc/fuse.conf: %v", err)
    } else {
        fmt.Println("Command output:", string(output))
    }

    if output == "user_allow_other" {
        qsd := exec.Command(
            "qemu-storage-daemon",
            "--blockdev", fmt.sprintf("node-name=prot-node,driver=file,filename=%s", testQcow_path),
            "--blockdev", "node-name=fmt-node,driver=qcow2,file=prot-node",
            "--export", fmt.sprintf("type=fuse,id=exp0,node-name=fmt-node,mountpoint=%s,writable=on", new_fmt_mp),
            "&",
        )

        output, err := qsd.Output()

        if err != nil {
            t.Fatalf("[Test 4 - qsd_up()] Failed to run qemu-storage-daemon: %v", err)
        } else { // it should just be a daemon on the system, passed through a channel here
            fmt.Println("Command output:", string(output))
        }

        checkmounts := exec.Command("mount", "|", "grep", "foo.qcow2")
        output, err := checkmounts.Output()
        if err != nil {
            t.Fatalf("[Test 4 - qsd_up()] Failed to run mount-pipe-grep: %v", err)
        } else {
            fmt.Println("Command output:", string(output))
        }

        // f. add partition mappings, verbose: enable capabilities first
        partmap := exec.Command("kpartx", "-av", testQcow_path)
        output, err := partmap.Output()
        if err != nil {
            t.Fatalf("[Test 4 - qsd_up()] Failed to run kpartx: %v", err)
        } else {
            fmt.Println("Command output:", string(output))
        }

        // g. get info from mounted qcow2 device mapping
        qemuinfo := exec.Command("qemu-img", "info", testQcow_path)
        output, err := qemuinfo.Output()
        if err != nil {
            t.Fatalf("[Test 4 - qsd_up()] Failed to run qemu-img: %v", err)
        } else {
            fmt.Println("Command output:", string(output))
        }
    } else{
        fmt.Println("[Test 4 - qsd_up()] Could not start qemu-storage-daemon process since user_allow_other is not enabled at /etc/fuse.conf.")
    }

}

// 5. rootfs_lp_setup
func testRls(t *testing.T) {
    testQcow_path = "./artifacts/test.Qcow"
    new_fmt_mp = testQcow_path

    loScanPart := exec.Command("losetup -fP")
    output, err := loScanPart.Output()
    if err != nil {
        t.Fatalf("[Test 5 - rootfs_lp_setup()] Failed to scan the partition table of the loop device with losetup: %v", err)
    } else {
        fmt.Println("Command output:", string(output))
    }

    loStatusDev := exec.Command("losetup", "-a")
    output, err := loStatusDev.Output()
    if err != nil {
        t.Fatalf("[Test 5 - rootfs_lp_setup()] Failed to list status of all loop devices: %v", err)
    } else {
        fmt.Println("Command output:", string(output))
    }

    // mount loopback device into the mountpoint to setup rootfs

    uld_out, uld_err := exec.Command("losetup -a | awk -F: 'NR==1 {print $1}'").Output()
    //upper_loopdev := exec.Command("losetup -a | awk -F: 'NR==1 {print $1}'")

    ubi_out, ubi_err  := exec.Command("losetup -a | awk -F: 'NR==1 {print $3}'").Output()
    //upper_base_img := exec.Command("losetup -a | awk -F: 'NR==1 {print $3}'")


    checkLoopDevfs := exec.Command("blkid", testQcow_path,"| awk 'NR==1 {print $4}' | grep ext4")
    output, err := checkLoopDevfs.Output()
    if err != nil {
        t.Fatalf("[Test 5 - rootfs_lp_setup()] Failed to check loop device filesystem: %v", err)
    } else if (output == "") { // if blkid |awk | grep output is empty, there is no ext4 yet.
        // actually create the filesystem for the already created partition
        createFsPart:= exec.Command("mkfs.ext4", uld_out) // upper_loopdev output
        output, err := createFsPart.Output()
        if err != nil {
            t.Fatalf("[Test 5] - mkfs.ext4 FAILED to create the filesystem for the already created partition: %v", err)
        } else {
            fmt.Println("[Test 5] - Command output:", string(output))
        }

    } else {
        fmt.Println("[Test 5] Command output:", string(output))
        fmt.Println("[Test 5]- Error formatting: [Test 5] - Command output: The provided qcow2 image ", checkLoopDevfs, "is already formatted with a filesystem mounted as Loop Device at",  ubi_out)
    }

}

func step_6(t *testing.T) {
    testQcow_path = "./artifacts/test.Qcow"
    upper_mountpoint = "./artifacts/qcow2-rootfs"
    umr = upper_mountpoint + "/rootfs"
    initramfs_base = "./artifacts/netpowered.cpio.gz"
    rootfs_deps= "./artifacts/deps/"

    uld_out, uld_err := exec.Command("losetup -a | awk -F: 'NR==1 {print $1}'").Output()
    //upper_loopdev := exec.Command("losetup -a | awk -F: 'NR==1 {print $1}'")

    ubi_out, ubi_err  := exec.Command("losetup -a | awk -F: 'NR==1 {print $3}'").Output()
    //upper_base_img := exec.Command("losetup -a | awk -F: 'NR==1 {print $3}'")

    check_loopdevfs := exec.Command("mkdir", "-p", umr)
    output, err := check_loopdevfs.Output()
    if err != nil {
        t.Fatalf("[Test 6] - failed to create directory for the rootfs: %v", err )
    } else {
        fmt.Println("[Test 6] - Command output:", string(output))
    }

    mountLD := exec.Command("mount", uld_out, umr)
    output, err := mountLD.Output()
    if err != nil {
        t.Fatalf("[Test 6] - Failed to mount loop device into the generic dir: %v", err)
    } else {
        fmt.Println("[Test 6] - Command output:", string(output))
    }

    place_ramdisk := exec.Command("cp", initramfs_base, upper_mountpoint)
    output, err := place_ramdisk.Output()
    if err != nil {
        t.Fatalf("[Test 6] - Failed to copy initramfs_base to upper_mountpoint: %v", err)
    } else {
        fmt.Println("[Test 6] - Command output:", string(output))
    }


    unzip_ramdisk := exec.Command("gzip -dc netpowered.cpio.gz | (cd ./rootfs/ || return && sudo cpio -idmv && cd - || return)")
    output, err := unzip_ramdisk.Output()
    if err != nil {
        t.Fatalf("[Test 6] - Failed to unzip ramdisk: %v", err)
    } else {
        fmt.Println("[Test 6] - Command output:", string(output))
    }

    // copy ramdisk rootfs to the actual rootfs being made
    cprr := exec.Command("cp -r", upper_mountpoint+"/netpowered/*", upper_mountpoint+"/rootfs/")
    output, err := cprr.Output()
    if err != nil {
        t.Fatalf("[Test 6] - Failed to copy ramdisk rootfs to the actual rootfs being made: %v", err)
    } else {
        fmt.Println("[Test 6] - Command output:", string(output))
    }

    // copy dependencies to the rootfs
    cpDeps := exec.Command("cp", "-r", rootfs_deps, upper_mountpoint+"/rootfs/")
    output, err := cpDeps.Output()
    if err != nil {
        t.Fatalf("[Test 6] - Failed to copy dependencies to the rootfs", err)
    } else {
        fmt.Println("[Test 6] - Command output:", string(output))
    }

    // packaging: calculate diff between two directories
    pacDiff := exec.Command("diff --brief --recursive", upper_mountpoint, upper_mountpoint+"/rootfs/")
    output, err := pacDiff.Output()
    if err != nil {
        t.Fatalf("[Test 6] - Failed to calculate diff between base directories: %v", err)
    } else {
        fmt.Println("[Test 6] - Command output:", string(output))
    }
}
