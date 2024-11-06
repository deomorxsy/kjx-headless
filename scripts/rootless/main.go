package main

import (
    "context"
    "fmt"
    "log"
    "github.com/fsnotify/fsnotify"
    "bytes"
    "os"
    "os/exec"
    containerd "github.com/containerd/containerd/v2/client"
    "github.com/containerd/nerdctl/pkg/clientutil"
	"github.com/containerd/nerdctl/pkg/rootlessutil"
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

func main() {

    watcher, err := fsnotify.NewWatcher()
    if err != nil {
        log.Fatal(err)

    }
    defer watcher.Close()

    go func() {
    }

    if err := redisExample(); err != nil {
        log.Fatal(err)
    }
}

func redisExample(ctx context.Context, cmd string, args []string) error {
    XDG_RUNTIME_DIR := exec.CommandContext(ctx, cmd, args...)
    DOCKER_HOST := fmt.Sprintf("unix://%s/podman/podman.sock", XDG_RUNTIME_DIR)

    client, err := containerd.New("")

    rvdsfCmd := exec.CommandContext(ctx, opts.RvdsfDefault, opts.RvdsfArgs...)
    rvdsfCmd.Stdin = bytes.NewReader(opts.Stdin)

    //var out = bytes.Buffer{}
    var out bytes.Buffer
    out.Reset()
    cmd.Stdout = &out

    rvdsfOutput, err := rvdsfCmd.Output()
    //err := rvdsfCmd.Run()
    if err != nil {
        if exitErr, ok := err.(*exec.ExitError); ok {
            return "", fmt.Errorf("Invoked qemu-img (rvdsf) failed with exit code %d", exitErr.ExitCode())
        }
        // handle other errors
        return "", fmt.Errorf("Failed to execute command: %w", err)
    }
}
