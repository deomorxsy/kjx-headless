package system

import (
    "fmt"
    //"bytes"
    "context"
    //"os"
    //"os/exec"
    //"testing"
)



func fbe() {
    ctx := context.Background()

    image_path := "./artifacts/foo.qcow2"
    //new_fmt_mp := image_path

    mockOptionsFactory := &DefaultOptionsFactory{}
    mockCleanupStrategy := &DefaultCleanupStrategy{}
    mockExecutor := &DefaultCommandExecutor{}

    // 1. rvdsfDefault

    //func Runna(ctx context.Context, optionsFactory OptionsFactory, cleaner CleanupStrategy, cmdExecutor CommandExecutor, opts *Options) (string, error){
    //mockCmdExecutor.Execute(Runna())

    mockOpts := &Options{
            // 1. raw virtual disk sparse file
            RvdsfDefault: "qemu-img",
            RvdsfArgs: []string{
                "create", "-f",
                "raw", "foo.img", "100M",
            },

            // 2. parted
            PartedDefault: "parted",
            PartedArgs: []string{
                "-s", "foo.img", "mklabel",
                "msdos", "mkpart", "primary",
                "ext4", "2048s", "100%",
            },

            // 3. qemu-img
            QemuImgDefault: "qemu-img",
            QemuImgArgs: []string{
                "convert", "-p", "-f",
                "raw", "-O", "qcow2",
                "foo.img", "foo.qcow2",
            },

            // 4. kpartx
            KpartxDefault: "kpartx",
            KpartxArgs: []string{"-a", "foo.qcow2"},

            // 5. qemu-storage-daemon
            QsdDefault: "qemu-storage-daemon",
            QsdArgs: []string{
                fmt.Sprintf(
                    "--blockdev node-name=prot-node," +
                    "driver=file,filename=%s",
                    image_path,
                ),
                "--blockdev node-name=fmt-node,driver=qcow2,file=prot-node",
                "--export",
                fmt.Sprintf("type=fuse,id=exp0," +
                    "node-name=fmt-node,mountpoint=%s,writable=on",
                    image_path,
                ),
            },
        }

    _, err := Runna(ctx, mockOptionsFactory, mockCleanupStrategy, mockExecutor, mockOpts)
    if err != nil {
        fmt.Println(err)
        return
    }
    fmt.Println("qemu-img exited successfully")

}
