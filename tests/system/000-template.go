package system

import (
    "fmt"
    "bytes"
    "context"
    "os/exec"
    "testing"
    "strings"
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
    // qemu-img create
    RvdsfDefault string
    RvdsfArgs []string

    // parted
    PartedDefault string
    PartedArgs []string

    // qemu-img convert img to qcow2
    QemuImgDefault string
    QemuImgArgs []string

    // kpartx
    KpartxDefault string
    KpartxArgs []string

    // qemu-storage-daemon
    QsdDefault string
    QsdArgs []string
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


        // 3. qemu-img
        QemuImgDefault: "qemu-img",
        QemuImgArgs: []string{},

        // 4. kpartx
        KpartxDefault: "kpartx",
        KpartxArgs: []string{},

        // 5. qemu-storage-daemon
        QsdDefault: "qemu-storage-daemon",
        QsdArgs: []string{},

    }
}

// clean up strategy
type CleanupStrategy interface {
        Cleanup(ctx context.Context, cmd, rvdsfCmd, partedCmd, qemuImgCmd, kpartxCmd, qsdCmd *exec.Cmd,) error
}

type DefaultCleanupStrategy struct{}

func (s *DefaultCleanupStrategy) Cleanup(ctx context.Context, cmd, rvdsfCmd, partedCmd, qemuImgCmd, kpartxCmd, qsdCmd *exec.Cmd) error {
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
    return out.String(), "\n" + rvdsfOutput + "\n" + partedOutput + "\n" + qemuImgOutput + "\n" + kpartxOutput + "\n" + qsdOutput + "\n", nil

}

func testRunna(t *testing.T) {
    ctx := context.Background()

    qemu_args := "convert -p -f raw -O qcow2"
    base_img := "foo.img"
    final_qcow  := "foo.qcow2"

    tmpDir := "/app/test/system/"

    // create factory and strategy for testing
    //optionsFactory := &DefaultOptionsFactory{}
    //cleanupStrategy := &DefaultCleanupStrategy{}
    //mockCmdExecutor := NewMockCommandExecutor(t)
    //mockOptionsFactory := NewMockOptionsFactory(t)
    //mockCleanupStrategy := NewMockDefaultCleanupStrategy(t)
    mockCmdExecutor := &DefaultCommandExecutor
    mockOptionsFactory := &DefaultOptionsFactory
    mockCleanupStrategy := &DefaultCleanupStrategy

    // 1. rvdsfDefault
    // qemu-img or ftruncate
    mockCmdExecutor.EXPECT(Runna(ctx, mockOptionsFactory, mockCleanupStrategy, mockCmdExecutor, "qemu-img",[]string {
        "create", "-f",
        "raw", "foo.img",
        "100M",
    }))

    // 2. expectation for parted
    mockCmdExecutor.EXPECT(Runna(ctx, mockOptionsFactory, mockCleanupStrategy, mockCmdExecutor, "parted", []string {
        "-s", "foo.img", "mklabel",
        "msdos", "mkpart", "primary",
        "ext4", "2048s", "100%",
    }))

    // 3. expectation for qemu-img
    mockCmdExecutor.EXPECT(Runna(ctx, mockOptionsFactory, mockCleanupStrategy, mockCmdExecutor,"qemu-img", []string{
        "convert", "-p", "-f", "raw",
        "-O", "qcow2", "foo.img",
        "foo.qcow2",
    }, []byte{})).Return("qemu-img output", nil)

    // 4. expectation for kpartx
    mockCmdExecutor.EXPECT(Runna(ctx, mockOptionsFactory, mockCleanupStrategy, mockCmdExecutor, "kpartx", []string{
        "-a", "foo.qcow2",
    }, []byte{})).Return("kpartx output", nil)

    // options with expected values
    mockOptionsFactory.EXPECT(NewOptions()).Return(&Options {
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
    })

    // 1. no argument and no input
    output, err := Runna(ctx, mockOptionsFactory, mockCleanupStrategy, mockCmdExecutor, &Options {
        Command: "qemu-img",
        Args:    []string{qemu_args, base_img, fmt.Sprintf("./%s", final_qcow)},
    })

    if err != nil {
        exitError, ok := err.(*exec.ExitError)
        if !ok {
            t.Fatalf("Expected *exec.ExitError, got %T", exitError)
        }
        //t.Errorf("unexpected error: %v", err)
    }

    // test 2. verify output file
    _, err = os.Stat(fmt.Sprintf("%s/%s", tmpDir, final_qcow))
    if err != nil {
        t.Errorf("Output file not created: %v", err)
    }

    // test 3. nonexistent command
    _, err = Runna(ctx, mockOptionsFactory, mockCleanupStrategy, mockCmdExecutor, &Options{
        Command: "nonexistentcommand",
    })

    if err != nil {
        t.Errorf("expected command not found error")
    } else if _, ok := err.(*exec.ExitError); !ok {
        t.Errof("unexpected error type: %T", err)
    }


}

func main() {
    ctx := context.Background()

    optionsFactory := &DefaultOptionsFactory{}
    cleanupStrategy := &DefaultCleanupStrategy{}

    err := Runna(ctx, mockOptionsFactory, mockCleanupStrategy, mockCmdExecutor, &Options{
        Command: "qemu-img",
        Args:[]string{qemu_args, base_img, fmt.Sprintf("./%s", final_qcow)},
    })
    if err != nil {
        fmt.Println(err)
        return
    }
    fmt.Println("qemu-img exited successfully")

}
