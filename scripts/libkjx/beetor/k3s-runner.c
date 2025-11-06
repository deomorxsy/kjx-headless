#include <fcntl.h>
#include <unistd.h>
#include <sys/wait.h>
#include <stdlib.h>
#include <stdio.h>
#include "./k3s_runner.h"

extern char **environ;

void run_k3s_cmd(char *const argv[]) {
    pid_t pid = fork();
    if (pid == 0) {
        execve("/bin/k3s", argv, environ);
        perror("execve failed");
        exit(1);
    } else if (pid > 0) {
        waitpid(pid, NULL, 0);  // Wait for the command to complete
    } else {
        perror("fork failed");
        exit(1);
    }
}

int main() {
    // Start the server in background
    pid_t server_pid = fork();
    if (server_pid == 0) {
        char *const argv[] = {
            "k3s",
            "server",
            "--disable-agent",
            "--default-runtime=runc",
            "--disable=traefik",
            "--snapshotter=fuse-overlayfs",
            NULL
        };
        int fd = open("/dev/null", O_RDWR);
        dup2(fd, STDOUT_FILENO);
        dup2(fd, STDERR_FILENO);
        execve("/bin/k3s", argv, environ);
        perror("execve server failed");
        exit(1);
    }

    sleep(5);  // Let k3s server initialize

    // 1. `k3s ctr namespace list`
    char *const cmd1[] = { "k3s", "ctr", "namespace", "list", NULL };
    run_k3s_cmd(cmd1);

    // 2. `k3s kubectl create namespace pia`
    char *const cmd2[] = { "k3s", "kubectl", "create", "namespace", "pia", NULL };
    run_k3s_cmd(cmd2);

    // 3. `k3s ctr -n=pia images import image at the mounted volume`
    char *const cmd3[] = {
        "k3s", "ctr", "-n=pia", "images", "import", "/mnt/k3s-squashfs/k3s-airgap-images-amd64.tar", NULL
    };
    run_k3s_cmd(cmd3);

    // 4. `k3s kubectl apply -f ...`
    char *const cmd4[] = {
        "k3s", "kubectl", "apply", "-f", "/app/artifacts/manifest.yaml", "-n=pia", NULL
    };
    run_k3s_cmd(cmd4);

    return 0;
}

