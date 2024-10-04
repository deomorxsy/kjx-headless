#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <unistd.h>

// waitpid
#include <sys/types.h>
#include <sys/wait.h>

void sighandler() {
    pid_t pid;

    sigempty(&set);
    sigaddset(&set, SIGUSR1);
    sigaddset(&set, SIGUSR2);

    pthread_sigmask(SIG_BLOCK, &set, NULL);
}

void cleanup(int signal) {
    while (waitpid((pid_t) (-1), 0, WNOHANG) > 0){}

}

int main(void) {

    sigset_t set;
    int sig;
    pid_t pid1; // libbpf
    pid_t pid2; // k3s

    char *const ebpf_argv[] = {"libbpf", NULL};
    char *const ebpf_envp[] = {NULL};

    char *const k3s_argv[] = {"libbpf", NULL};
    char *const k3s_envp[] = {NULL};

    // step 1. block signals for parent
    sigemptyset(&set);
    sigaddset(&set, SIGUSR1);
    sigaddset(&set, SIGUSR2);
    pthread_sigmask(SIG_BLOCK, &set, NULL);


    // fork 1
    if (sigaction(SIGCHLD, SIG_IGN) == SIG_ERR) {
        perror("signal");
        exit(EXIT_FAILURE);
    }
    pid1 = fork();
    if (pid1 == 0) {
        sigwait(&set, &sig);
        if (sig == SIGUSR1) {
            execve("/bin/libkjx/libbpf", ebpf_argv, ebpf_envp);
        }
        exit(0);
    }
    switch (pid1) {
        case -1:
            perror("fork");
            exit(EXIT_FAILURE);

        case 0:
            puts("Child exiting.");
            exit(EXIT_SUCCESS);
        default:
            printf("Child is PID %jd\n", (intmax_t) pid1);
            puts("Parent exiting.");
            exit(EXIT_SUCCESS);
    }


    // fork 2
    pid2 = fork();
    if (pid2 == 0) {
        sigwait(&set, &sig);
        if (sig == SIGUSR2) {
            execve("/bin/k3s", k3s_argv, k3s_envp);
        }
        exit(0);
    }

    // step 4. send signal to children ebpf to start monitoring tgid
    kill(pid1, SIGUSR1);
    //waitpid(pid1, NULL, 0);

    // step 5.
    kill(pid2, SIGUSR2);
    //waitpid(pid2, NULL, 0);

    return 0;


}
