#include <bits/types/siginfo_t.h>
// #include <csignal> // for cpp
#include <curl/system.h>
#include <signal.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h> // strlen
#include <sys/types.h>
#include <unistd.h>


#include <stdio.h>
#include <curl/curl.h>
#include <sys/stat.h>
#include <fcntl.h>

// gcc/g++ linking is sensitive to order, so you must
// specify the curl header before the easy header.
#include <curl/easy.h>

// waitpid
#include <sys/types.h>
#include <sys/wait.h>

#define NUMCHLDS 10

// HTTP request variables
#define SERVER_URL "${ARTIFACT_STORE}"

// artifact
#define FLAME_OUT "/app/flamegraph.svg"

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
/* In Windows, this inits the Winsock stuff */
curl_global_init(CURL_GLOBAL_ALL);
#endif


#define AWS_ACCESS_KEY "${{ secrets.S3_ACCESS_KEY }}"
#define AWS_SECRET_KEY "${{ secrets.S3_SECRET_KEY }}"
#define BUCKET_NAME    "kjx-flamegraphs"
#define REGION         "your-region"
#define FILE_PATH      "path/to/your/file"
#define OBJECT_KEY     "object-key-in-s3"

int s3_uploads() {
    CURL *handle; //*curl
    CURLcode res;
    struct curl_slist *slist = NULL;
    struct stat file_info;
    curl_off_t speed_upload, total_time;
    FILE *fd;

    // open file to upload
    fd = fopen("debugit", "rb");
    if (!fd)
        return 1;

    // get file size
    if (fstat(fileno(fd), &file_info) != 0)
        return 1; /* cannot continue */

    handle = curl_easy_init();
    if (handle) {

         va_list ap;

        // Set custom headers
        slist = curl_slist_append(slist, "Host: kjx-demo");
        slist = curl_slist_append(slist, "X-libcurl: coolness");
        slist = curl_slist_append(slist, "Content-Type: application/x-www-form-urlencoded");

        if (!slist)
            return -1;

        curl_easy_setopt(handle, CURLOPT_HTTPHEADER, slist);

        // set upload destination
        curl_easy_setopt(handle, CURLOPT_URL,
                "https://<bucket-name>.s3.<region>.amazonaws.com/<object-key>");
        // upload to the url
        curl_easy_setopt(handle, CURLOPT_UPLOAD, 1L);

        // read the data being upload from the file descriptor
        curl_easy_setopt(handle, CURLOPT_READDATA, fd);

        // give the size of the upload beforehand
        curl_easy_setopt(handle, CURLOPT_INFILESIZE_LARGE,
                (curl_off_t)file_info.st_size);

        // enable verbose for tracing
        curl_easy_setopt(handle, CURLOPT_VERBOSE, 1L);

        // perform request
        res = curl_easy_perform(handle);

        /* error checking */
        if(res != CURLE_OK) {
            fprintf(stderr, "curl_easy_perform() failed: %s\n", curl_easy_strerror(res));
        } else {
            printf("Request sent sucessfully.\n");
        }

        curl_slist_free_all(slist);
    }

    return 0;
}


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



int main(void) {

    CURL *handle; //*curl
    sigset_t set;
    int sig;
    pid_t pid1; // libbpf
    pid_t pid2; // k3s

    // libbpf-hw
    char *const ebpf_argv[] = {"tracepoint", NULL}; // default arguments
    char *const ebpf_envp[] = {NULL}; // environment pointer

    // k3s
    char *const k3s_argv[] = {"--disable-agent", NULL}; // /bin/k3s
    char *const k3s_envp[] = {NULL};

    // step 1. block signals for parent
    sigemptyset(&set);
    sigaddset(&set, SIGUSR1);
    sigaddset(&set, SIGUSR2);
    pthread_sigmask(SIG_BLOCK, &set, NULL);




    /*
     * =====================================================
     *
     *              OLD BELOW!!!!!!!!
     *
     * -----------------------------------------------------
     *
     * */

    // redo
    struct sigaction act;
    memset(&act, 0, sizeof(struct sigaction));
    sigemptyset(&act.sa_mask);

    act.sa_handler = sigchld_handler;
    //act.sa_sigaction = sigchld_handler;
    act.sa_flags = SA_SIGINFO;

    if (-1 == sigaction(SIGCHLD, &act, NULL))
    {
        perror("sigaction()");
        exit(EXIT_FAILURE);
    }

    for (int i = 0; i < NUMCHLDS; i++)
    {
        switch(fork())
        {
            case 0:
                return 1234567890;
            case -1:
                write(STDERR_FILENO, "fork ERROR!", 11);
                exit(EXIT_FAILURE);
            default:
                printf("Child created\n");
        }

    }

    while (1)
    {
        if (nexitedchlds < NUMCHLDS)
            pause();
        else
         exit(EXIT_SUCCESS);
    }

    // fork 1
    if (sigaction(SIGINT, &act, NULL) == -1) {
        perror("signal");
        exit(EXIT_FAILURE);
    }
    pid1 = fork();
    if (pid1 == 0) {
        sigwait(&set, &sig);
        if (sig == SIGUSR1) {
            execve("/bin/libbpf-hw", ebpf_argv, ebpf_envp);
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
    sleep(10);

    kill(pid2, SIGUSR2);

    /*call send_flamegraph logic*/
    //const char *post_args = "";
    s3_uploads();
    curl_global_cleanup();

    waitpid(pid1, NULL, 0);
    waitpid(pid2, NULL, 0);

    printf("program complete. Exiting now...");
    return 0;


}


void signal_resume_child1(int sig) {
    // noop
}

int new_main(void) {

    /*
     * =================
     * SELF-CONTAINED
     * ================
     * */




    // k3s
    char *const k3s_argv[] = {"--disable-agent", NULL}; // /bin/k3s
    char *const k3s_envp[] = {NULL};

    // pipe file descriptor
    pid_t child1_pid = fork();
    if (child1_pid < 0) {
        perror("fork");
        exit(EXIT_FAILURE);
    }

    if (child1_pid == 0) {
        close(pipe_fd[0]); // close unused read end of the pipe

        printf("Child1: my pid is %d. Writing it to the pipe\n.", getpid());
        pid_t my_pid = getpid();
        write(pipe_fd[1], &my_pid, sizeof(my_pid));
        close(pipe_fd[1]); // close write end of the pipe

        printf("Child1: waiting indefinitely\n");


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
        printf("Child1: Resuming k3s execution");  // received the signal

        // run the k3s binary
        //execlp("k3s", "k3s", "server", NULL);
        //execlp("/bin/k3s", ebpf_argv, ebpf_envp);

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


        int exec_child2 = execve("/bin/k3s", ebpf_argv, ebpf_envp);
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

    /*
    struct sigaction sa;
    sa.sa_handler = handle_pipe_tunnel;
    sa.sa_flags = 0;
    sigemptyset(&sa.sa_mask); //sa_mask specifies mask of signals that should be blocked

    if (sigaction(SIGCHLD, &sa, NULL) == -1) {
        perror("sigaction");
        exit(EXIT_FAILURE);
    }
    */

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
