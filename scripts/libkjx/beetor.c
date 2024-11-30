#include <bits/types/siginfo_t.h>
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


void sigchld_handler(int, siginfo_t*, void*);

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

int main(void) {

    CURL *handle; //*curl
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
    kill(pid2, SIGUSR2);

    /*call send_flamegraph logic*/
    //const char *post_args = "";
    generate_flamegraph();
    send_flamegraph();
    curl_global_cleanup();

    waitpid(pid1, NULL, 0);
    waitpid(pid2, NULL, 0);

    printf("program complete. Exiting now...");
    return 0;


}
