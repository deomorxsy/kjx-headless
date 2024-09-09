package system

import (
    "fmt"
    "bytes"
    "context"
    "os"
    "os/exec"
    "testing"
)

type CommandExecutor interface {
    //Runna
    Execute(ctx context.Context, cmd string, args []string, stdin []byte) (string, error)
}
type DefaultCommandExecutor struct{}
func (e *DefaultCommandExecutor) Execute(ctx context.Context, cmd string, args []string, stdin []byte) (string, error) {
    cmdExec := exec.CommandContext(ctx, cmd, args...)
    cmdExec.Stdin = bytes.NewReader(stdin)

    var out bytes.Buffer
    cmdExec.Stdout = &out

    err := cmdExec.Run()
    if err != nil {
        return "", fmt.Errorf("Failed to execute command: %w", err)
    }

    return out.String(), nil
}


type Options struct {
    Command string
    Args []string
    Stdin []byte
    // raw virtual device sparse file
    // 1. qemu-img create
    RvdsfDefault string
    RvdsfArgs []string

    // 2. parted
    PartedDefault string
    PartedArgs []string

    grepDefault string
    grepArgs []string

    awkDefault string
    awkArgs []string

    printfDefault string
    printfArgs []string

    // 3. qemu-img convert img to qcow2
    QemuImgDefault string
    QemuImgArgs []string

    rmDefault string
    rmArgs []string

    fileDefault string
    fileArgs []string

    // 4. kpartx
    KpartxDefault string
    KpartxArgs []string

    tailDefault string
    tailArgs []string

    // 5. qemu-storage-daemon
    QsdDefault string
    QsdArgs []string

    // 6. mount-then-grep
    mountDefault string
    mountArgs []string

    // 7. kpartx again
    // args "-av", image_path

    // 8. qemu-img "info", image_path

    // 9. echo/fmt

    //10. losetup
    losetupDefault string
    losetupArgs []string

    // 11. blkid
    blkidDefault string
    blkidArgs []string

    // 12. mkfs.ext4
    mkfsExt4Default string
    mkfsExt4Args []string

    // 13. mkdir?
    mkdirDefault string
    mkdirArgs []string

    // 14. cp?

    // 15. gzip!
    gzipDefault string
    gzipArgs []string

    // 16. cpio!
    cpioDefault string
    cpioArgs []string

    // 17. diff!
    diffDefault string
    diffArgs []string

    // 18. umount
    umountDefault string
    umountArgs []string

    // 19. losetup again

    // ========== rootfs =========
    // 20. addgroup
    addGroupDefault string
    addGroupArgs []string

    // 21. adduser
    addUserDefault string
    addUserArgs []string

    // 22. wget
    wgetDefault string
    wgetArgs []string

    // 23. hard and soft links
    linkDefault string
    linkArgs []string

    // 24. cat
    catDefault string
    catArgs []string

    // 25. chmod
    chmodDefault string
    chmodArgs []string

    // ===== ISOGEN =====

    // 26. sleep
    sleepDefault string
    sleepArgs []string

    // 27. exit
    //exitDefault int

    // 28. sha256sum
    shaSumDefault string
    shaSumArgs []string

    // 29. cut
    cutDefault string
    cutArgs []string

    // 30. tar
    tarDefault string
    tarArgs []string

    // 31. xorriso
    xorrisoDefault string
    xorrisoArgs []string

}

type OptionsFactory interface {
    NewOptions() *Options
}

type DefaultOptionsFactory struct{}

func (f *DefaultOptionsFactory) NewOptions() *Options {
    return &Options{

        Command: "",
        Args: []string{},
        Stdin: []byte{},

        // 1. raw virtual disk sparse file
        RvdsfDefault: "qemu-img",
        RvdsfArgs: []string{},

        // 2. parted
        PartedDefault: "parted",
        PartedArgs: []string{},

        grepDefault: "grep",
        grepArgs: []string{},

        awkDefault: "awk",
        awkArgs: []string{},

        printfDefault: "printf",
        printfArgs: []string{},


        // 3. qemu-img
        QemuImgDefault: "qemu-img",
        QemuImgArgs: []string{},

        rmDefault: "rm",
        rmArgs: []string{},

        fileDefault: "file",
        fileArgs: []string{},

        // 4. kpartx
        KpartxDefault: "kpartx",
        KpartxArgs: []string{},

        tailDefault: "tail",
        tailArgs: []string{},

        // 5. qemu-storage-daemon
        QsdDefault: "qemu-storage-daemon",
        QsdArgs: []string{},

        // 6. mount-then-grep
        mountDefault: "mount",
        mountArgs: []string{},

        // 7. kpartx again
        // args "-av", image_path

        // 8. qemu-img "info", image_path

        // 9. echo/fmt

        //10. losetup
        losetupDefault: "losetup",
        losetupArgs: []string{},

        // 11. blkid
        blkidDefault: "blkid",
        blkidArgs: []string{},

        // 12. mkfs.ext4
        mkfsExt4Default: "mkfs.ext4",
        mkfsExt4Args: []string{},

        // 13. mkdir?
        mkdirDefault: "mkdir",
        mkdirArgs: []string{},

        // 14. cp?

        // 15. gzip!
        gzipDefault: "gzip",
        gzipArgs: []string{},

        // 16. cpio!
        cpioDefault: "cpio",
        cpioArgs: []string{},

        // 17. diff!
        diffDefault: "diff",
        diffArgs: []string{},

        // 18. umount
        umountDefault: "umount",
        umountArgs: []string{},

        // 19. losetup again

        // ========== rootfs =========
        // 20. addgroup, alpine
        addGroupDefault: "addgroup",
        addGroupArgs: []string{},

        // 21. adduser
        addUserDefault: "adduser",
        addUserArgs: []string{},

        // 22. wget
        wgetDefault: "wget",
        wgetArgs: []string{},

        // 23. hard and soft links
        linkDefault: "ln",
        linkArgs: []string{},

        // 24. cat
        catDefault: "cat",
        catArgs: []string{},

        // 25. chmod
        chmodDefault: "chmod",
        chmodArgs: []string{},

        // ===== ISOGEN =====

        // 26. sleep
        sleepDefault: "sleep",
        sleepArgs: []string{},

        // 27. exit
        //exitDefault int

        // 28. sha256sum
        shaSumDefault: "sha256sum",
        shaSumArgs: []string{},

        // 29. cut
        cutDefault: "cut",
        cutArgs: []string{},

        // 30. tar
        tarDefault: "tar",
        tarArgs: []string{},

        // 31. xorriso
        xorrisoDefault: "xorriso",
        xorrisoArgs: []string{},
    }
}

// clean up strategy
type CleanupStrategy interface {
        Cleanup(ctx context.Context, cmd, rvdsfCmd, partedCmd, qemuImgCmd, kpartxCmd, qsdCmd *exec.Cmd,) error
}

type DefaultCleanupStrategy struct{}

commands := [
    Command, Stdin, RvdsfCmd,
    PartedCmd, grepCmd, awkCmd,
    printfCmd, QemuImgCmd, rmCmd,
    fileCmdKpartxCmd, tailCmd, QsdCmd,
    mountCmd, losetupCmd, blkidCmd,
    mkfsExt4Cmd, mkdirCmd, gzipCmd,
    cpioCmd, diffCmd, umountCmd,
    addGroupCmd, addUserCmd, wgetCmd,
    linkCmd, catCmd, chmodCmd,
    sleepCmd, exitCmd intshaSumCmd,
    cutCmd, tarCmd, xorrisoCmd
]

func (s *DefaultCleanupStrategy) Cleanup(ctx context.Context, cmd, rvdsfCmd, partedCmd, qemuImgCmd, kpartxCmd, qsdCmd *exec.Cmd) error {
    commands := []*exec.Cmd{cmd, rvdsfCmd, partedCmd, qemuImgCmd, kpartxCmd, qsdCmd}
    var errs []string

    for _, c := range commands {
        if c != nil {
            err := c.Process.Kill()
            if err != nil {
                errs = append(errs, fmt.Sprintf("Failed to kill process %s: %v", c.Path, err))
            }
        }
    }

    if len(errs) > 0 {
        return fmt.Errorf("Cleanup failed:\n%s", fmt.Sprint(errs))
    }

    return nil
}

// Inject OptionsFactory and CleanupStrategy Dependencies into Runna
func Runna(ctx context.Context, optionsFactory OptionsFactory, cleaner CleanupStrategy, cmdExecutor CommandExecutor, opts *Options) (string, error){

    // 0. base
    cmd := exec.CommandContext(ctx, opts.Command, opts.Args...)
    cmd.Stdin = bytes.NewReader(opts.Stdin)

    var out bytes.Buffer
    cmd.Stdout = &out

    err := cmd.Run()
    if err != nil {
        // golang type-switch
        switch e := err.(type) {
        case *exec.ExitError:
            return "", fmt.Errorf("Invoked program failed with exit code %d", e.ExitCode())
        default:
            return "", fmt.Errorf("Failed to execute command: %w", err)
        }
        //if exitErr, ok := err.(*exec.ExitError); ok {
        //    return "", fmt.Errorf("Invoked program failed with exit code %d", exitErr.ExitCode())
        //}
        // handle other errors
        //return "", fmt.Errorf("Failed to execute command: %w", err)
    }



    // 1. virtual raw disk sparse file step
    rvdsfCmd := exec.CommandContext(ctx, opts.RvdsfDefault, opts.RvdsfArgs...)
    rvdsfCmd.Stdin = bytes.NewReader(opts.Stdin)

    //var out = bytes.Buffer{}
    out.Reset()
    rvdsfCmd.Stdout = &out

    rvdsfOutput, err := rvdsfCmd.Output()
    //err := rvdsfCmd.Run()
    if err != nil {
        if exitErr, ok := err.(*exec.ExitError); ok {
            return "", fmt.Errorf("Invoked qemu-img (rvdsf) failed with exit code %d", exitErr.ExitCode())
        }
        // handle other errors
        return "", fmt.Errorf("Failed to execute command: %w", err)
    }
    // show the output
    return out.String(), nil

    // 2. parted
    partedCmd := exec.CommandContext(ctx, opts.PartedDefault, opts.PartedArgs...)
    partedCmd.Stdin = bytes.NewReader(opts.Stdin)

    //var out = bytes.Buffer{}
    out.Reset()
    partedCmd.Stdout = &out

    partedOutput, err := partedCmd.Output()
    if err != nil {
        if exitErr,ok := err.(*exec.ExitError); ok {
            return "", fmt.Errorf("Invoked parted failed with exit code %d", exitErr.ExitCode())
        }
        return "", fmt.Errorf("Failed to execute command: %w", err)
    }

    // show the output
    //return out.String(), nil
    // 3. qemu-img convert
    qemuImgCmd := exec.CommandContext(ctx, opts.QemuImgDefault, opts.QemuImgArgs...)
    qemuImgCmd.Stdin = bytes.NewReader(opts.Stdin)

    //var out = bytes.Buffer{}
    out.Reset()
    qemuImgCmd.Stdout = &out

    qemuImgOutput, err := qemuImgCmd.Output()
    if err != nil {
        if exitErr, ok := err.(*exec.ExitError); ok {
            return "", fmt.Errorf("Invoked qemuImg failed with exit code %d", exitErr.ExitCode())
        }
        return "", fmt.Errorf("Failed to execute command: %w", err)
    }
    // show the output
    //return out.String(), nil
    //return qemuImgOutput.String(), nil

    // 4. kpartx
    kpartxCmd := exec.CommandContext(ctx, opts.KpartxDefault, opts.KpartxArgs...)
    kpartxCmd.Stdin = bytes.NewReader(opts.Stdin)

    //var out = bytes.Buffer{}
    out.Reset()
    kpartxCmd.Stdout = &out

    kpartxOutput, err := kpartxCmd.Output()
    if err != nil {
        if exitErr, ok := err.(*exec.ExitError); ok {
            return "", fmt.Errorf("Invoked kpartx failed with exit code %d", exitErr.ExitCode())
        }
        return "", fmt.Errorf("Failed to execute command: %w", err)
    }
    // show the output
    //return out.String(), nil

    // 5. qemu-storage-daemon
    qsdCmd := exec.CommandContext(ctx, opts.QsdDefault, opts.QsdArgs...)
    qsdCmd.Stdin = bytes.NewReader(opts.Stdin)

    //var out = bytes.Buffer{}
    out.Reset()
    qsdCmd.Stdout = &out

    qsdOutput, err := qsdCmd.Output()
    if err != nil {
        if exitErr, ok := err.(*exec.ExitError); ok {
            return "", fmt.Errorf("Invoked qemu-storage-daemon failed with exit code %d", exitErr.ExitCode())
        }
        return "", fmt.Errorf("Failed to execute command: %w", err)
    }

    // 6. show the output
    err = cleaner.Cleanup(ctx, cmd,rvdsfCmd, partedCmd, qemuImgCmd, kpartxCmd, qsdCmd)
    if err != nil {
        return "", fmt.Errorf("Cleanup failed: %w", err)
    }
    // show the output
    return fmt.Sprintf(out.String() + "\n" + string(rvdsfOutput) + "\n" + string(partedOutput) + "\n" + string(qemuImgOutput) + "\n" + string(kpartxOutput) + "\n" + string(qsdOutput) + "\n"), nil

}


func testRunna(t *testing.T) {
    ctx := context.Background()

    //tmpDir := "/app/test/system/"
    // WORKDIR tmpDir
    image_path := "../../artifacts/foo.img"
    final_qcow := "../../artifacts/foo.qcow2"
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
                "raw", "../../artifacts/foo.img", "100M",
            },

            // 2. parted
            PartedDefault: "parted",
            PartedArgs: []string{
                "-s", "../../artifacts/foo.img", "mklabel",
                "msdos", "mkpart", "primary",
                "ext4", "2048s", "100%",
            },

            // 3. qemu-img
            QemuImgDefault: "qemu-img",
            QemuImgArgs: []string{
                "convert", "-p", "-f",
                "raw", "-O", "qcow2",
                "../../artifacts/foo.img", "../../artifacts/foo.qcow2",
            },

            // 4. kpartx
            KpartxDefault: "kpartx",
            KpartxArgs: []string{"-a", "../../artifacts/foo.qcow2"},

            // 5. qemu-storage-daemon
            QsdDefault: "qemu-storage-daemon",
            QsdArgs: []string{
                fmt.Sprintf(
                    "--blockdev node-name=prot-node," +
                    "driver=file,filename=%s",
                    final_qcow,
                ),
                "--blockdev node-name=fmt-node,driver=qcow2,file=prot-node",
                "--export",
                fmt.Sprintf("type=fuse,id=exp0," +
                    "node-name=fmt-node,mountpoint=%s,writable=on",
                    final_qcow,
                ),
            },
        }

    _, err := Runna(ctx, mockOptionsFactory, mockCleanupStrategy, mockExecutor, mockOpts)

    // test 1. no output or nonexisted command
    if err != nil {
        exitError, ok := err.(*exec.ExitError)
        if !ok {
            t.Fatalf("Expected *exec.ExitError, got %T", exitError)
        }
        //t.Errorf("unexpected error: %v", err)
    }

    // test 2. verify output file
    _, err = os.Stat(fmt.Sprintf("%s", image_path))
    if err != nil {
        t.Errorf("Output file not created: %v", err)
    }

}

func main() {
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
