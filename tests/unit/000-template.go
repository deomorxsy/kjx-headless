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

    GrepDefault string
    GrepArgs []string

    AwkDefault string
    AwkArgs []string

    PrintfDefault string
    PrintfArgs []string

    // 3. qemu-img convert img to qcow2
    QemuImgDefault string
    QemuImgArgs []string

    RmDefault string
    RmArgs []string

    FileDefault string
    FileArgs []string

    // 4. kpartx
    KpartxDefault string
    KpartxArgs []string

    TailDefault string
    TailArgs []string

    // 5. qemu-storage-daemon
    QsdDefault string
    QsdArgs []string

    // 6. mount-then-grep
    MountDefault string
    MountArgs []string

    // 7. kpartx again
    // args "-av", image_path

    // 8. qemu-img "info", image_path

    // 9. echo/fmt

    //10. losetup
    LosetupDefault string
    LosetupArgs []string

    // 11. blkid
    BlkidDefault string
    BlkidArgs []string

    // 12. mkfs.ext4
    MkfsExt4Default string
    MkfsExt4Args []string

    // 13. mkdir?
    MkdirDefault string
    MkdirArgs []string

    // 14. cp?

    // 15. gzip!
    GzipDefault string
    GzipArgs []string

    // 16. cpio!
    CpioDefault string
    CpioArgs []string

    // 17. diff!
    DiffDefault string
    DiffArgs []string

    // 18. umount
    UmountDefault string
    UmountArgs []string

    // 19. losetup again

    // ========== rootfs =========
    // 20. addgroup
    AddGroupDefault string
    AddGroupArgs []string

    // 21. adduser
    AddUserDefault string
    AddUserArgs []string

    // 22. wget
    WgetDefault string
    WgetArgs []string

    // 23. hard and soft links
    LinkDefault string
    LinkArgs []string

    // 24. cat
    CatDefault string
    CatArgs []string

    // 25. chmod
    ChmodDefault string
    ChmodArgs []string

    // ===== ISOGEN =====

    // 26. sleep
    SleepDefault string
    SleepArgs []string

    // 27. exit
    //exitDefault int

    // 28. sha256sum
    ShaSumDefault string
    ShaSumArgs []string

    // 29. cut
    CutDefault string
    CutArgs []string

    // 30. tar
    TarDefault string
    TarArgs []string

    // 31. xorriso
    XorrisoDefault string
    XorrisoArgs []string

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

        GrepDefault: "grep",
        GrepArgs: []string{},

        AwkDefault: "awk",
        AwkArgs: []string{},

        PrintfDefault: "printf",
        PrintfArgs: []string{},


        // 3. qemu-img
        QemuImgDefault: "qemu-img",
        QemuImgArgs: []string{},

        RmDefault: "rm",
        RmArgs: []string{},

        FileDefault: "file",
        FileArgs: []string{},

        // 4. kpartx
        KpartxDefault: "kpartx",
        KpartxArgs: []string{},

        TailDefault: "tail",
        TailArgs: []string{},

        // 5. qemu-storage-daemon
        QsdDefault: "qemu-storage-daemon",
        QsdArgs: []string{},

        // 6. mount-then-grep
        MountDefault: "mount",
        MountArgs: []string{},

        // 7. kpartx again
        // args "-av", image_path

        // 8. qemu-img "info", image_path

        // 9. echo/fmt

        //10. losetup
        LosetupDefault: "losetup",
        LosetupArgs: []string{},

        // 11. blkid
        BlkidDefault: "blkid",
        BlkidArgs: []string{},

        // 12. mkfs.ext4
        MkfsExt4Default: "mkfs.ext4",
        MkfsExt4Args: []string{},

        // 13. mkdir?
        MkdirDefault: "mkdir",
        MkdirArgs: []string{},

        // 14. cp?

        // 15. gzip!
        GzipDefault: "gzip",
        GzipArgs: []string{},

        // 16. cpio!
        CpioDefault: "cpio",
        CpioArgs: []string{},

        // 17. diff!
        DiffDefault: "diff",
        DiffArgs: []string{},

        // 18. umount
        UmountDefault: "umount",
        UmountArgs: []string{},

        // 19. losetup again

        // ========== rootfs =========
        // 20. addgroup, alpine
        AddGroupDefault: "addgroup",
        AddGroupArgs: []string{},

        // 21. adduser
        AddUserDefault: "adduser",
        AddUserArgs: []string{},

        // 22. wget
        WgetDefault: "wget",
        WgetArgs: []string{},

        // 23. hard and soft links
        LinkDefault: "ln",
        LinkArgs: []string{},

        // 24. cat
        CatDefault: "cat",
        CatArgs: []string{},

        // 25. chmod
        ChmodDefault: "chmod",
        ChmodArgs: []string{},

        // ===== ISOGEN =====

        // 26. sleep
        SleepDefault: "sleep",
        SleepArgs: []string{},

        // 27. exit
        //exitDefault int

        // 28. sha256sum
        ShaSumDefault: "sha256sum",
        ShaSumArgs: []string{},

        // 29. cut
        CutDefault: "cut",
        CutArgs: []string{},

        // 30. tar
        TarDefault: "tar",
        TarArgs: []string{},

        // 31. xorriso
        XorrisoDefault: "xorriso",
        XorrisoArgs: []string{},
    }
}

// clean up strategy for instantiated variables from options
type CleanupStrategy interface {

        Cleanup(
            ctx context.Context, cmd, rvdsfCmd,
            partedCmd, grepCmd, awkCmd,
            printfCmd, QemuImgCmd, rmCmd,
            fileCmd, kpartxCmd, tailCmd, qsdCmd,
            mountCmd, losetupCmd, blkidCmd,
            mkfsExt4Cmd, mkdirCmd, gzipCmd,
            cpioCmd, diffCmd, umountCmd,
            addGroupCmd, addUserCmd, wgetCmd,
            linkCmd, catCmd, chmodCmd,
            sleepCmd, exitCmd, shaSumCmd,
            cutCmd, tarCmd, xorrisoCmd *exec.Cmd,) error

        CleanupOutput(
            ctx context.Context, cmd, rvdsfCmd,
            partedCmd, grepCmd, awkCmd,
            printfCmd, QemuImgCmd, rmCmd,
            fileCmd, kpartxCmd, tailCmd, qsdCmd,
            mountCmd, losetupCmd, blkidCmd,
            mkfsExt4Cmd, mkdirCmd, gzipCmd,
            cpioCmd, diffCmd, umountCmd,
            addGroupCmd, addUserCmd, wgetCmd,
            linkCmd, catCmd, chmodCmd,
            sleepCmd, exitCmd, shaSumCmd,
            cutCmd, tarCmd, xorrisoCmd []byte,) error
}

type DefaultCleanupStrategy struct{}


func (s *DefaultCleanupStrategy) Cleanup( ctx context.Context,
    cmd, rvdsfCmd, partedCmd, grepCmd, awkCmd, printfCmd,
    qemuImgCmd, rmCmd, fileCmd, kpartxCmd, tailCmd, qsdCmd,
    mountCmd, losetupCmd, blkidCmd, mkfsExt4Cmd, mkdirCmd,
    gzipCmd, cpioCmd, diffCmd, umountCmd, addGroupCmd,
    addUserCmd, wgetCmd, linkCmd, catCmd, chmodCmd,
    sleepCmd, exitCmd, shaSumCmd, cutCmd, tarCmd,
    xorrisoCmd *exec.Cmd,
    ) error {
    //
    //
    commands := []*exec.Cmd{
        cmd, rvdsfCmd, partedCmd, grepCmd, awkCmd, printfCmd,
        qemuImgCmd, rmCmd, fileCmd, kpartxCmd, tailCmd, qsdCmd,
        mountCmd, losetupCmd, blkidCmd, mkfsExt4Cmd, mkdirCmd,
        gzipCmd, cpioCmd, diffCmd, umountCmd, addGroupCmd,
        addUserCmd, wgetCmd, linkCmd, catCmd, chmodCmd,
        sleepCmd, exitCmd, shaSumCmd, cutCmd, tarCmd,
        xorrisoCmd,
    }
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

func (s *DefaultCleanupStrategy) CleanupOutput( ctx context.Context,
    cmdOutput, rvdsfOutput, partedOutput, grepOutput, awkOutput, printfOutput,
    qemuImgOutput, rmOutput, fileOutput, kpartxOutput, tailOutput, qsdOutput,
    mountOutput, losetupOutput, blkidOutput, mkfsExt4Output, mkdirOutput,
    gzipOutput, cpioOutput, diffOutput, umountOutput, addGroupOutput,
    addUserOutput, wgetOutput, linkOutput, catOutput, chmodOutput,
    sleepOutput, exitOutput, shaSumOutput, cutOutput, tarOutput,
    xorrisoOutput []byte,
    ) error {
    // 1. a slice of bytes


    // 2. a slice of byte slices
    outputs := [][]byte{
        cmdOutput, rvdsfOutput, partedOutput, grepOutput, awkOutput, printfOutput,
        qemuImgOutput, rmOutput, fileOutput, kpartxOutput, tailOutput, qsdOutput,
        mountOutput, losetupOutput, blkidOutput, mkfsExt4Output, mkdirOutput,
        gzipOutput, cpioOutput, diffOutput, umountOutput, addGroupOutput,
        addUserOutput, wgetOutput, linkOutput, catOutput, chmodOutput,
        sleepOutput, exitOutput, shaSumOutput, cutOutput, tarOutput,
        xorrisoOutput,
    }
    var errs []string

    for _, c := range outputs {
        if c != nil {
            c = nil
            err := c
            // c.Process.Kill()
            if err != nil {
                errs = append(errs, fmt.Sprintf("Failed to nullify string %s: %v", c, err))
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

    //err := cmd.Run()
    cmdOutput, err := cmd.Output()
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
    //return out.String(), nil

    // 2. parted
    partedCmd := exec.CommandContext(ctx, opts.PartedDefault, opts.PartedArgs...)
    //partedCmd.Stdin = bytes.NewReader(opts.Stdin)
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

    // grep
    grepCmd := exec.CommandContext(ctx, opts.GrepDefault, opts.GrepArgs...)
    //grepCmd.Stdin = bytes.NewReader(opts.Stdin)
    grepCmd.Stdin = bytes.NewReader(partedOutput)
    // *[]byte

    out.Reset()
    grepCmd.Stdout = &out

    grepOutput, err := grepCmd.Output()
    if err != nil {
        if exitErr, ok := err.(*exec.ExitError); ok {
            return "", fmt.Errorf("Invoked grep failed with exit code %d", exitErr.ExitCode())
        }
        return "", fmt.Errorf("Failed to execute command: %w", err)
    }

    // awk
    awkCmd := exec.CommandContext(ctx, opts.AwkDefault, opts.AwkArgs...)
    awkCmd.Stdin = bytes.NewReader(opts.Stdin)

    out.Reset()
    awkCmd.Stdout = &out

    awkOutput, err := awkCmd.Output()
    if err != nil {
        if exitErr, ok := err.(*exec.ExitError); ok {
            return "", fmt.Errorf("Invoked awk failed with exit code %d", exitErr.ExitCode())
        }
        return "", fmt.Errorf("Failed to execute command: %w", err)
    }

    // printf
    printfCmd := exec.CommandContext(ctx, opts.PrintfDefault, opts.PrintfArgs...)
    printfCmd.Stdin = bytes.NewReader(opts.Stdin)

    out.Reset()
    printfCmd.Stdout = &out

    printfOutput, err := printfCmd.Output()
    if err != nil {
        if exitErr, ok := err.(*exec.ExitError); ok {
            return "", fmt.Errorf("Invoked printf failed with exit code %d", exitErr.ExitCode())
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

    // rm
    rmCmd := exec.CommandContext(ctx, opts.RmDefault, opts.RmArgs...)
    rmCmd.Stdin = bytes.NewReader(opts.Stdin)

    out.Reset()
    rmCmd.Stdout = &out

    rmOutput, err:= rmCmd.Output()
    if err != nil {
        if exitErr, ok := err.(*exec.ExitError); ok {
            return "", fmt.Errorf("Invoked rm failed with exit code %d", exitErr.ExitCode())
        }
        return "", fmt.Errorf("Failed to execute command: %w", err)
    }

    // file
    fileCmd := exec.CommandContext(ctx, opts.FileDefault, opts.FileArgs...)
    fileCmd.Stdin = bytes.NewReader(opts.Stdin)

    out.Reset()
    fileCmd.Stdout = &out

    fileOutput, err := fileCmd.Output()
    if err != nil {
        if exitErr, ok := err.(*exec.ExitError); ok {
            return "", fmt.Errorf("Invoked file failed with exit code %d", exitErr.ExitCode())
        }
        return "", fmt.Errorf("Failed to execute command: %w", err)
    }


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

    tailCmd := exec.CommandContext(ctx, opts.TailDefault, opts.TailArgs...)
    tailCmd.Stdin = bytes.NewReader(opts.Stdin)

    out.Reset()
    tailCmd.Stdout = &out

    tailOutput, err := tailCmd.Output()
    if err != nil {
        if exitErr, ok := err.(*exec.ExitError); ok {
            return "", fmt.Errorf("Invoked tail failed with exit code %d", exitErr.ExitCode())
        }
        return "", fmt.Errorf("Failed to execute command: %w", err)
    }

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

    // mount
    mountCmd := exec.CommandContext(ctx, opts.MountDefault, opts.MountArgs...)
    mountCmd.Stdin = bytes.NewReader(opts.Stdin)

    out.Reset()
    mountCmd.Stdout = &out

    mountOutput, err := mountCmd.Output()
    if err != nil {
        if exitErr, ok := err.(*exec.ExitError); ok {
            return "", fmt.Errorf("Invoked mount failed with exit code %d", exitErr.ExitCode())
        }
        return "", fmt.Errorf("Failed to execute command: %w", err)
    }

    // losetup
    losetupCmd := exec.CommandContext(ctx, opts.MountDefault, opts.MountArgs...)
    losetupCmd.Stdin = bytes.NewReader(opts.Stdin)

    out.Reset()
    losetupCmd.Stdout = &out

    losetupOutput, err := losetupCmd.Output()
    if err != nil {
        if exitErr, ok := err.(*exec.ExitError); ok {
            return "", fmt.Errorf("Invoked losetup failed with exit code %d", exitErr.ExitCode())
        }
        return "", fmt.Errorf("Failed to execute command: %w", err)
    }

    //blkid

    blkidCmd := exec.CommandContext(ctx, opts.BlkidDefault, opts.BlkidArgs...)
    blkidCmd.Stdin = bytes.NewReader(opts.Stdin)

    out.Reset()
    blkidCmd.Stdout = &out

    blkidOutput, err := blkidCmd.Output()
    if err != nil {
        if exitErr, ok := err.(*exec.ExitError); ok {
            return "", fmt.Errorf("Invoked blkid failed with exit code %d", exitErr.ExitCode())
        }
        return "", fmt.Errorf("Failed to execute command: %w", err)
    }

    // mkfs.ext4
    mkfsExt4Cmd := exec.CommandContext(ctx, opts.MkfsExt4Default, opts.MkfsExt4Args...)
    mkfsExt4Cmd.Stdin = bytes.NewReader(opts.Stdin)

    out.Reset()
    mkfsExt4Cmd.Stdout = &out

    mkfsExt4Output, err := mkfsExt4Cmd.Output()
    if err != nil {
        if exitErr, ok := err.(*exec.ExitError); ok {
            return "", fmt.Errorf("Invoked mkfs.ext4 failed with exit code %d", exitErr.ExitCode())
        }
        return "", fmt.Errorf("Failed to execute command: %w", err)
    }

    // mkdir
    mkdirCmd := exec.CommandContext(ctx, opts.MkdirDefault, opts.MkdirArgs...)
    mkdirCmd.Stdin = bytes.NewReader(opts.Stdin)

    out.Reset()
    mkdirCmd.Stdout = &out

    mkdirOutput, err := mkdirCmd.Output()
    if err != nil {
        if exitErr, ok := err.(*exec.ExitError); ok {
            return "", fmt.Errorf("Invoked mkdir failed with exit code %d", exitErr.ExitCode())
        }
        return "", fmt.Errorf("Failed to execute command: %w", err)
    }

    // gzip
    gzipCmd := exec.CommandContext(ctx, opts.GzipDefault, opts.GzipArgs...)
    gzipCmd.Stdin = bytes.NewReader(opts.Stdin)

    out.Reset()
    gzipCmd.Stdout = &out

    gzipOutput, err := gzipCmd.Output()
    if err != nil {
        if exitErr, ok := err.(*exec.ExitError); ok {
            return "", fmt.Errorf("Invoked gzip failed with exit code %d", exitErr.ExitCode())
        }
        return "", fmt.Errorf("Failed to execute command: %w", err)
    }

    // cpio
    cpioCmd := exec.CommandContext(ctx, opts.CpioDefault, opts.CpioArgs...)
    cpioCmd.Stdin = bytes.NewReader(opts.Stdin)

    out.Reset()
    cpioCmd.Stdout = &out

    cpioOutput, err := cpioCmd.Output()
    if err != nil {
        if exitErr, ok := err.(*exec.ExitError); ok {
            return "", fmt.Errorf("Invoked cpio failed with exit code %d", exitErr.ExitCode())
        }
        return "", fmt.Errorf("Failed to execute command: %w", err)
    }

    // diff
    diffCmd := exec.CommandContext(ctx, opts.DiffDefault, opts.DiffArgs...)
    diffCmd.Stdin = bytes.NewReader(opts.Stdin)

    out.Reset()
    diffCmd.Stdout = &out

    diffOutput, err := diffCmd.Output()
    if err != nil {
        if exitErr, ok := err.(*exec.ExitError); ok {
            return "", fmt.Errorf("Invoked diff failed with exit code %d", exitErr.ExitCode())
        }
        return "", fmt.Errorf("Failed to execute command: %w", err)
    }

    // umount
    umountCmd := exec.CommandContext(ctx, opts.UmountDefault, opts.UmountArgs...)
    umountCmd.Stdin = bytes.NewReader(opts.Stdin)

    out.Reset()
    umountCmd.Stdout = &out

    umountOutput, err := umountCmd.Output()
    if err != nil {
        if exitErr, ok := err.(*exec.ExitError); ok {
            return "", fmt.Errorf("Invoked umount failed with exit code %d", exitErr.ExitCode())
        }
        return "", fmt.Errorf("Failed to execute command: %w", err)
    }

    // addgroup
    addGroupCmd := exec.CommandContext(ctx, opts.AddGroupDefault, opts.AddGroupArgs...)
    addGroupCmd.Stdin = bytes.NewReader(opts.Stdin)

    out.Reset()
    addGroupCmd.Stdout = &out

    addGroupOutput, err := addGroupCmd.Output()
    if err != nil {
        if exitErr, ok := err.(*exec.ExitError); ok {
            return "", fmt.Errorf("Invoked addgroup failed with exit code %d", exitErr.ExitCode())
        }
        return "", fmt.Errorf("Failed to execute command: %w", err)
    }

    // adduser
    addUserCmd := exec.CommandContext(ctx, opts.AddUserDefault, opts.AddUserArgs...)
    addUserCmd.Stdin = bytes.NewReader(opts.Stdin)

    out.Reset()
    addUserCmd.Stdout = &out

    addUserOutput, err := addUserCmd.Output()
    if err != nil {
        if exitErr, ok := err.(*exec.ExitError); ok {
            return "", fmt.Errorf("Invoked user failed with exit code %d", exitErr.ExitCode())
        }
        return "", fmt.Errorf("Failed to execute command: %w", err)
    }

    // wget
    wgetCmd := exec.CommandContext(ctx, opts.WgetDefault, opts.WgetArgs...)
    wgetCmd.Stdin = bytes.NewReader(opts.Stdin)

    out.Reset()
    wgetCmd.Stdout = &out

    wgetOutput, err := wgetCmd.Output()
    if err != nil {
        if exitErr, ok := err.(*exec.ExitError); ok {
            return "", fmt.Errorf("Invoked wget failed with exit code %d", exitErr.ExitCode())
        }
        return "", fmt.Errorf("Failed to execute command: %w", err)
    }

    // ln
    linkCmd := exec.CommandContext(ctx, opts.LinkDefault, opts.LinkArgs...)
    linkCmd.Stdin = bytes.NewReader(opts.Stdin)

    out.Reset()
    linkCmd.Stdout = &out

    linkOutput, err := wgetCmd.Output()
    if err != nil {
        if exitErr, ok := err.(*exec.ExitError); ok {
            return "", fmt.Errorf("Invoked ln failed with exit code %d", exitErr.ExitCode())
        }
        return "", fmt.Errorf("Failed to execute command: %w", err)
    }

    // cat
    catCmd := exec.CommandContext(ctx, opts.CatDefault, opts.CatArgs...)
    catCmd.Stdin = bytes.NewReader(opts.Stdin)

    out.Reset()
    catCmd.Stdout = &out

    catOutput, err := catCmd.Output()
    if err != nil {
        if exitErr, ok := err.(*exec.ExitError); ok {
            return "", fmt.Errorf("Invoked cat failed with exit code %d", exitErr.ExitCode())
        }
        return "", fmt.Errorf("Failed to execute command: %w", err)
    }

    // chmod
    chmodCmd := exec.CommandContext(ctx, opts.ChmodDefault, opts.ChmodArgs...)
    chmodCmd.Stdin = bytes.NewReader(opts.Stdin)

    out.Reset()
    chmodCmd.Stdout = &out

    chmodOutput, err := chmodCmd.Output()
    if err != nil {
        if exitErr, ok := err.(*exec.ExitError); ok {
            return "", fmt.Errorf("Invoked chmod failed with exit code %d", exitErr.ExitCode())
        }
        return "", fmt.Errorf("Failed to execute command: %w", err)
    }

    // sleep
    sleepCmd := exec.CommandContext(ctx, opts.SleepDefault, opts.SleepArgs...)
    sleepCmd.Stdin = bytes.NewReader(opts.Stdin)

    out.Reset()
    sleepCmd.Stdout = &out

    sleepOutput, err := sleepCmd.Output()
    if err != nil {
        if exitErr, ok := err.(*exec.ExitError); ok {
            return "", fmt.Errorf("Invoked sleep failed with exit code %d", exitErr.ExitCode())
        }
        return "", fmt.Errorf("Failed to execute command: %w", err)
    }

    // exit
    exitCmd := exec.CommandContext(ctx, opts.ChmodDefault, opts.ChmodArgs...)
    exitCmd.Stdin = bytes.NewReader(opts.Stdin)

    out.Reset()
    exitCmd.Stdout = &out

    exitOutput, err := exitCmd.Output()
    if err != nil {
        if exitErr, ok := err.(*exec.ExitError); ok {
            return "", fmt.Errorf("Invoked exit failed with exit code %d", exitErr.ExitCode())
        }
        return "", fmt.Errorf("Failed to execute command: %w", err)
    }

    // sha256sum
    shaSumCmd := exec.CommandContext(ctx, opts.ShaSumDefault, opts.ShaSumArgs...)
    shaSumCmd.Stdin = bytes.NewReader(opts.Stdin)

    out.Reset()
    shaSumCmd.Stdout = &out

    shaSumOutput, err := shaSumCmd.Output()
    if err != nil {
        if exitErr, ok := err.(*exec.ExitError); ok {
            return "", fmt.Errorf("Invoked sha256sum failed with exit code %d", exitErr.ExitCode())
        }
        return "", fmt.Errorf("Failed to execute command: %w", err)
    }

    // cut, probably piped to
    cutCmd := exec.CommandContext(ctx, opts.CutDefault, opts.CutArgs...)
    cutCmd.Stdin = bytes.NewReader(opts.Stdin)

    out.Reset()
    cutCmd.Stdout = &out

    cutOutput, err := cutCmd.Output()
    if err != nil {
        if exitErr, ok := err.(*exec.ExitError); ok {
            return "", fmt.Errorf("Invoked cut failed with exit code %d", exitErr.ExitCode())
        }
        return "", fmt.Errorf("Failed to execute command: %w", err)
    }


    // tar
    tarCmd := exec.CommandContext(ctx, opts.TarDefault, opts.TarArgs...)
    tarCmd.Stdin = bytes.NewReader(opts.Stdin)

    out.Reset()
    tarCmd.Stdout = &out

    tarOutput, err := tarCmd.Output()
    if err != nil {
        if exitErr, ok := err.(*exec.ExitError); ok {
            return "", fmt.Errorf("Invoked grep failed with exit code %d", exitErr.ExitCode())
        }
        return "", fmt.Errorf("Failed to execute command: %w", err)
    }

    // xorriso
    xorrisoCmd := exec.CommandContext(ctx, opts.XorrisoDefault, opts.XorrisoArgs...)
    xorrisoCmd.Stdin = bytes.NewReader(opts.Stdin)

    out.Reset()
    xorrisoCmd.Stdout = &out

    xorrisoOutput, err := xorrisoCmd.Output()
    if err != nil {
        if exitErr, ok := err.(*exec.ExitError); ok {
            return "", fmt.Errorf("Invoked xorriso failed with exit code %d", exitErr.ExitCode())
        }
        return "", fmt.Errorf("Failed to execute command: %w", err)
    }

    // Output variables will be type []byte


    // n. clean variables
    err = cleaner.Cleanup(
    ctx, cmd, rvdsfCmd, partedCmd, grepCmd, awkCmd, printfCmd,
    qemuImgCmd, rmCmd, fileCmd, kpartxCmd, tailCmd, qsdCmd,
    mountCmd, losetupCmd, blkidCmd, mkfsExt4Cmd, mkdirCmd,
    gzipCmd, cpioCmd, diffCmd, umountCmd, addGroupCmd,
    addUserCmd, wgetCmd, linkCmd, catCmd, chmodCmd,
    sleepCmd, exitCmd, shaSumCmd, cutCmd, tarCmd,
    xorrisoCmd,
    )

    if err != nil {
        return "", fmt.Errorf("Cleanup failed: %w", err)
    }
    // show the output

    dumpOutput := fmt.Sprintf("", //string(ctx) + "\n",
        //string(cmd) + "\n" +
        string(rvdsfOutput) + "\n" + string(partedOutput) + "\n" + string(grepOutput) + "\n" + string(awkOutput) + "\n" +
        string(printfOutput) + "\n" + string(qemuImgOutput) + "\n" + string(rmOutput) + "\n" + string(fileOutput) + "\n" +
        string(kpartxOutput) + "\n" + string(tailOutput) + "\n" + string(qsdOutput) + "\n" + string(mountOutput) + "\n" +
        string(losetupOutput) + "\n" + string(blkidOutput) + "\n" + string(mkfsExt4Output) + "\n" + string(mkdirOutput) + "\n" +
        string(gzipOutput) + "\n" + string(cpioOutput) + "\n" + string(diffOutput) + "\n" + string(umountOutput) + "\n" +
        string(addGroupOutput) + "\n" + string(addUserOutput) + "\n" + string(wgetOutput) + "\n" + string(linkOutput) + "\n" +
        string(catOutput) + "\n" + string(chmodOutput) + "\n" + string(sleepOutput) + "\n" + string(exitOutput) + "\n" +
        string(shaSumOutput) + "\n" + string(cutOutput) + "\n" + string(tarOutput) + "\n" + string(xorrisoOutput) + "\n",
    )

    err = cleaner.CleanupOutput(ctx,
    cmdOutput, rvdsfOutput, partedOutput, grepOutput, awkOutput, printfOutput,
    qemuImgOutput, rmOutput, fileOutput, kpartxOutput, tailOutput, qsdOutput,
    mountOutput, losetupOutput, blkidOutput, mkfsExt4Output, mkdirOutput,
    gzipOutput, cpioOutput, diffOutput, umountOutput, addGroupOutput,
    addUserOutput, wgetOutput, linkOutput, catOutput, chmodOutput,
    sleepOutput, exitOutput, shaSumOutput, cutOutput, tarOutput,
    xorrisoOutput,
    )

    //return fmt.Sprintf(out.String() + "\n" + string(rvdsfOutput) + "\n" + string(partedOutput) + "\n" + string(qemuImgOutput) + "\n" + string(kpartxOutput) + "\n" + string(qsdOutput) + "\n"), nil
    return dumpOutput, nil

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
            Command: "",
            Args: []string{},
            Stdin: []byte{},

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

            // 3. grep
            GrepDefault: "grep",
            GrepArgs: []string{},

            // 4. awk
            AwkDefault: "awk",
            AwkArgs: []string{},

            // 5. printf
            PrintfDefault: "printf",
            PrintfArgs: []string{},

            // 6. qemu-img
            QemuImgDefault: "qemu-img",
            QemuImgArgs: []string{
                "convert", "-p", "-f",
                "raw", "-O", "qcow2",
                "../../artifacts/foo.img", "../../artifacts/foo.qcow2",
            },

            // 7. rm
            RmDefault: "rm",
            RmArgs: []string{},

            // 8. file
            FileDefault: "file",
            FileArgs: []string{},

            // 9. kpartx
            KpartxDefault: "kpartx",
            KpartxArgs: []string{"-a", "../../artifacts/foo.qcow2"},

            // 10. tail
            TailDefault: "tail",
            TailArgs: []string{},

            // 11. qemu-storage-daemon
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

            // 12. mount-then-grep
            MountDefault: "mount",
            MountArgs: []string{},

            // 13. kpartx again
            //  args "-av", image_path

            // 14. qemu-img "info", image_path

            // 15. echo/fmt

            //16. losetup
            LosetupDefault: "losetup",
            LosetupArgs: []string{},

            // 17. blkid
            BlkidDefault: "blkid",
            BlkidArgs: []string{},

            // 18. mkfs.ext4
            MkfsExt4Default: "mkfs.ext4",
            MkfsExt4Args: []string{},

            // 19. mkdir?
            MkdirDefault: "mkdir",
            MkdirArgs: []string{},

            // 20. cp?

            // 21. gzip!
            GzipDefault: "gzip",
            GzipArgs: []string{},

            // 22. cpio!
            CpioDefault: "cpio",
            CpioArgs: []string{},

            // 23. diff!
            DiffDefault: "diff",
            DiffArgs: []string{},

            // 24. umount
            UmountDefault: "umount",
            UmountArgs: []string{},

            // 25. losetup again

            // ========== rootfs =========
            // 26. addgroup, alpine
            AddGroupDefault: "addgroup",
            AddGroupArgs: []string{},

            // 27. adduser
            AddUserDefault: "adduser",
            AddUserArgs: []string{},

            // 28. wget
            WgetDefault: "wget",
            WgetArgs: []string{},

            // 29. hard and soft links
            LinkDefault: "ln",
            LinkArgs: []string{},

            // 30. cat
            CatDefault: "cat",
            CatArgs: []string{},

            // 31. chmod
            ChmodDefault: "chmod",
            ChmodArgs: []string{},

            // ===== ISOGEN =====

            // 32. sleep
            SleepDefault: "sleep",
            SleepArgs: []string{},

            // 33. exit
            //exitDefault int

            // 34. sha256sum
            ShaSumDefault: "sha256sum",
            ShaSumArgs: []string{},

            // 35. cut
            CutDefault: "cut",
            CutArgs: []string{},

            // 36. tar
            TarDefault: "tar",
            TarArgs: []string{},

            // 37. xorriso
            XorrisoDefault: "xorriso",
            XorrisoArgs: []string{},
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
        // 0. base
        Command: "",
        Args: []string{},
        Stdin: []byte{},

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

        // 3. grep
        GrepDefault: "grep",
        GrepArgs: []string{},

        // 4. awk
        AwkDefault: "awk",
        AwkArgs: []string{},

        // 5. printf
        PrintfDefault: "printf",
        PrintfArgs: []string{},

        // 6. qemu-img
        QemuImgDefault: "qemu-img",
        QemuImgArgs: []string{
            "convert", "-p", "-f",
            "raw", "-O", "qcow2",
            "foo.img", "foo.qcow2",
        },

        // 7. rm
        RmDefault: "rm",
        RmArgs: []string{},

        // 8. file
        FileDefault: "file",
        FileArgs: []string{},

        // 9. kpartx
        KpartxDefault: "kpartx",
        KpartxArgs: []string{"-a", "foo.qcow2"},

        // 10. tail
        TailDefault: "tail",
        TailArgs: []string{},

        // 11. qemu-storage-daemon
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

        // 12. mount-then-grep
        MountDefault: "mount",
        MountArgs: []string{},

        // 13. kpartx again
        // args "-av", image_path

        // 14. qemu-img "info", image_path

        // 15. echo/fmt

        // 16. losetup
        LosetupDefault: "losetup",
        LosetupArgs: []string{},

        // 17. blkid
        BlkidDefault: "blkid",
        BlkidArgs: []string{},

        // 18. mkfs.ext4
        MkfsExt4Default: "mkfs.ext4",
        MkfsExt4Args: []string{},

        // 19. mkdir?
        MkdirDefault: "mkdir",
        MkdirArgs: []string{},

        // 20. cp?

        // 21. gzip!
        GzipDefault: "gzip",
        GzipArgs: []string{},

        // 22. cpio!
        CpioDefault: "cpio",
        CpioArgs: []string{},

        // 23. diff!
        DiffDefault: "diff",
        DiffArgs: []string{},

        // 24. umount
        UmountDefault: "umount",
        UmountArgs: []string{},

        // 25. losetup again

        // ========== rootfs =========
        // 26. addgroup, alpine
        AddGroupDefault: "addgroup",
        AddGroupArgs: []string{},

        // 27. adduser
        AddUserDefault: "adduser",
        AddUserArgs: []string{},

        // 28. wget
        WgetDefault: "wget",
        WgetArgs: []string{},

        // 29. hard and soft links
        LinkDefault: "ln",
        LinkArgs: []string{},

        // 30. cat
        CatDefault: "cat",
        CatArgs: []string{},

        // 31. chmod
        ChmodDefault: "chmod",
        ChmodArgs: []string{},

        // ===== ISOGEN =====

        // 32. sleep
        SleepDefault: "sleep",
        SleepArgs: []string{},

        // 33. exit
        //exitDefault int

        // 34. sha256sum
        ShaSumDefault: "sha256sum",
        ShaSumArgs: []string{},

        // 35. cut
        CutDefault: "cut",
        CutArgs: []string{},

        // 36. tar
        TarDefault: "tar",
        TarArgs: []string{},

        // 37. xorriso
        XorrisoDefault: "xorriso",
        XorrisoArgs: []string{},
        }

    _, err := Runna(ctx, mockOptionsFactory, mockCleanupStrategy, mockExecutor, mockOpts)
    if err != nil {
        fmt.Println(err)
        return
    }
    fmt.Println("qemu-img exited successfully")



}
