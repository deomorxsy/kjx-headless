// ######
// beetor without curl
// ######

#include <bits/types/siginfo_t.h>
// #include <csignal> // for cpp
#include <signal.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdarg.h>
// #include <string.h> // strlen
#include <sys/types.h>
#include <unistd.h>


#include <stdio.h>
#include <sys/stat.h>
#include <fcntl.h>

// waitpid
#include <sys/types.h>
#include <sys/wait.h>

// k3s-runner program
// #include "./k3s_runner.h"
#include "./k3s-runner.c"

#define NUMCHLDS 10

__attribute__((constructor)) void haha()
{
    puts("Hello, world!");
}

// making the code possible for future ebpf-on-windows
#ifdef _WIN32
#ifdef _WIN64
#pragma message("Compiling curl on 64-bit windows")
else
#pragma message("Compiling curl on 32-bit windows")
#endif
#include <winsock2.h>
#endif



void sigchld_handler(int sig) {
    //noop
};

void sighandler(int signo, siginfo_t *sinfo, void *context) {
    pid_t pid;

    while ((pid = waitpid(-1, NULL, WNOHANG)) > 0) {

    }
    //sigempty(&set);
    //sigaddset(&set, SIGUSR1);
    //sigaddset(&set, SIGUSR2);

    //pthread_sigmask(SIG_BLOCK, &set, NULL);
}

void cleanup(int signal) {
    while (waitpid((pid_t) (-1), 0, WNOHANG) > 0){}

}

sig_atomic_t nexitedchlds = 0; // the atomic data type allowed to use in the context of the signal handling
int pipe_fd[2]; // pipe file descriptors
pid_t child2_pid; // pid of the second child

void handle_pipe_tunnel(int sig) { // for the childs!!
    if (sig == SIGCHLD) {
        printf("Parent: child1 has exited. Stopping child2.\n");
        kill(child2_pid, SIGTERM); // send SIGTERM to child2
    }
}



void signal_resume_child1(int sig) {
    // noop
}


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

int main(void) {

    /*
     * =================
     * SELF-CONTAINED
     * ================
     * */

    sigset_t set;
    int sig;
    pid_t pid1; // libbpf
    pid_t pid2; // k3s
                //


    // step 1. block signals for parent
    sigemptyset(&set);
    sigaddset(&set, SIGUSR1);
    sigaddset(&set, SIGUSR2);
    pthread_sigmask(SIG_BLOCK, &set, NULL);

    // low-level runtimes
    char llrt[5][10] ={"runc", "crun", "runsc", "youki"};
    char runtime_arg[64];
    // snprintf(runtime_arg, sizeof(runtime_arg), "--disable-agent --default-runtime=%s --disable=traefik, --snapshotter=fuse-overlayfs", llrt[0], NULL);
    // k3s server --disable-agent --default-runtime=runc --disable=traefik --snapshotter=fuse-overlayfs > /dev/null 2>&1 &

    // k3s
    char *const k3s_argv[] = {
        "k3s",
        "server",
        "--disable-agent",
        "--default-runtime=runc",
        "--disable=traefik",
        "--snapshotter=fuse-overlayfs",
        NULL
    }; // /bin/k3s
    char *const k3s_envp[] = {NULL};

    // libbpf-hw
    char *const ebpf_argv[] = {"tracepoint", NULL}; // default arguments
    char *const ebpf_envp[] = {NULL}; // environment pointer


    // initialize pipe_fd
    if (pipe(pipe_fd) == -1) {
    perror("pipe");
    exit(EXIT_FAILURE);
    }


    // pipe file descriptor
    pid_t child1_pid = fork();
    if (child1_pid < 0) {
        perror("fork");
        exit(EXIT_FAILURE);
    }

    // ==========================================
    //
    // --------- k3s TRACEE CHILD PROCESS ----------
    if (child1_pid == 0) {

        pid_t received_pid;
        read(pipe_fd[0], &received_pid, sizeof(received_pid));
        close(pipe_fd[0]); // close read end of the pipe


        printf("Child1: my pid is %d. Writing it to the pipe\n.", getpid());
        pid_t my_pid = getpid();
        write(pipe_fd[1], &my_pid, sizeof(my_pid));
        close(pipe_fd[1]); // close write end of the pipe

        printf("|> Child1: waiting indefinitely...\n");


        // set up signal handler to resume execution
        struct sigaction sa;
        sa.sa_handler = signal_resume_child1;
        sa.sa_flags = 0;
        sigemptyset(&sa.sa_mask);

        if(sigaction(SIGUSR1, &sa, NULL) == -1) {
            perror("sigaction");
            exit(EXIT_FAILURE);
        }

        /* pause() causes the calling process (or thread)
         * to sleep until a signal is delivered that either
         * terminates the process or causes the invocation
         * of a signal-catching function.
        */
        pause(); // wait indefinitely
        printf("\n|> Child1: Resuming k3s execution...\n\n");  // received the signal

        // run the k3s binary
        //execlp("k3s", "k3s", "server", NULL);
        //execlp("/bin/k3s", ebpf_argv, ebpf_envp);


        printf("child2: Received PID from child1 (k3s): %d. Resuming the run of child1...\n", received_pid);

        char recpid_buffer[32]; // enough space
        snprintf(recpid_buffer, sizeof(recpid_buffer), "RECEIVED_PID=%d", received_pid); // SNPRINTF: redirect output of the printf into the received_pid[32] char buffer.



        /*
         * k3s arguments and environment
         *
         */
        char *const k3s_argv[] = {"tracepoint", NULL}; // default arguments
        char *const k3s_envp[] = {
            "VAR1=value1",
            "VAR2=value2",
            recpid_buffer,
            NULL
        };

        // execve gives you a fine-grained control over environment variables
        int exec_child1 = execve("/bin/k3s", k3s_argv, k3s_envp);
        if ( exec_child1  < 0) {
            perror("execve");
            exit(EXIT_FAILURE);

        }
        //printf("Child1: Exiting.\n");
        exit(EXIT_SUCCESS);
    }

    //fork second child
    child2_pid = fork();
    if (child2_pid < 0) {
        perror("fork");
        exit(EXIT_FAILURE);

    }

    if (child2_pid == 0) {
        // child2 process
        close(pipe_fd[1]); // close unused write end of the pipe

        pid_t received_pid;
        read(pipe_fd[0], &received_pid, sizeof(received_pid));
        close(pipe_fd[0]); // close end of pipe

        printf("child2: Received PID from child1 (k3s): %d. Resuming the run of child1...\n", received_pid);

        char recpid_buffer[32]; // enough space
        snprintf(recpid_buffer, sizeof(recpid_buffer), "RECEIVED_PID=%d", received_pid); // SNPRINTF: redirect output of the printf into the received_pid[32] char buffer.


        /*
         * libbpf-hw arguments and environment
         *
         */
        char *const ebpf_argv[] = {"tracepoint", NULL}; // default arguments
        char *const ebpf_envp[] = {
            "VAR1=value1",
            "VAR2=value2",
            recpid_buffer,
            NULL
        };


        int exec_child2 = execve("/bin/libbpf-hw", ebpf_argv, ebpf_envp);
        if ( exec_child2  < 0) {
            perror("execve");
            exit(EXIT_FAILURE);

        }

        //printf("Child1: Exiting.\n");
        exit(EXIT_SUCCESS);
        //while (1) {
        //    printf("Child2: running...\n");
        //    sleep(1);
        //}
    }

    // parent process
    close(pipe_fd[0]); // close read end of pipe
    close(pipe_fd[1]); // close write end of pipe



    sleep(5);
    printf("Parent: signaling child1 to resume\n");
    kill(child1_pid, SIGUSR1);

    // wait for child1 and child2 to complete
    waitpid(child1_pid, NULL, 0);
    printf("Parent: child1 (k3s) has exited.\n");

    kill(child2_pid, SIGTERM);
    waitpid(child2_pid, NULL, 0);
    printf("Parent: child2 (tracer) has exited.\n");

    printf("Parent: exiting....\n");
    return 0;

}
