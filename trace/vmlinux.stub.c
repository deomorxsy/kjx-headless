// This program loads the vmlinux header diff patch into memory, so it
// can be recognized by clangd. By doing this, the environment both
// supports: 1) the pattern of not including direct headers (the
// patch) into the git repository, and 2) Any language server protocol
// (LSP) that needs the header. It maps via a parent-server and
// fork-execve which is the child-client.

#define _GNU_SOURCE
#include <signal.h> // handle signals
#include <err.h>
#include <fcntl.h> // allow file sealing operations
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h> // memfd_create
#include <sys/types.h>
#include <unistd.h> // ftruncate

#define MAX_COMMAND_LENGTH 1000
#define MAX_FILE_SIZE 3*(10000000)

#define TYPEOF(x) _Generic((x), \
    int: "int", \
    float: "float", \
    double: "double", \
    char*: "char*", \
    default: "unknown")

#ifdef novmlinux
#pragma message "Patch vmlinux into virtual memory"

std::ifstream

#endif
// before: void for both
int prod(char *name);//, ssize_t len, char *seals_arg); // producer
//int cons(char *fd_path); // consumer
//int cons(int fd, unsigned int seals);
void cons(int fd_path, unsigned int seals);

// handle signals
void intp_signal(int signum) {
    printf("Intercepted signal: %d\n", signum);
    //exit(1);
    exit(130);

}

// create tmpfs file with memfd_create
void tmpfs_create(char *name, ssize_t len, char *seals_arg) {

    // file descriptor declarations
    int             fd;
    unsigned int    seals;



    // 1. create anonymous file into tmpfs
    fd = memfd_create(name, MFD_ALLOW_SEALING | MFD_CLOEXEC); // MFD_ALLOW_SEALING);
    if (fd == -1) {
        err(EXIT_FAILURE, "memfd_create");
        exit(1);
    }

    // 2. enforce the file size to match the specified by len
    if (ftruncate(fd, len) == -1) {
        err(EXIT_FAILURE, "truncate");
        exit(1);
    }

    printf("PID: %jd; fd: %d; /proc/%jd/fd/%d\n",
        (intmax_t) getpid(), fd, (intmax_t) getpid(), fd);

    // 3. check if there are seals supplied at seals_arg, then increment the seal bit flags (the seal integer)
    if (seals_arg != NULL) {
        seals = 0;
        // |= performs bitwise XOR and stores result in the left operand.
        if (strchr(seals_arg, 'g') != NULL)
            seals |= F_SEAL_GROW;
        if (strchr(seals_arg, 's') != NULL)
            seals |= F_SEAL_SHRINK;
        if (strchr(seals_arg, 'w') != NULL)
            seals |= F_SEAL_WRITE;
        if (strchr(seals_arg, 'W') != NULL)
            seals |= F_SEAL_FUTURE_WRITE;
        if (strchr(seals_arg, 'S') != NULL)
            seals |= F_SEAL_GROW;

        if (fcntl(fd, F_ADD_SEALS, seals) == -1) {
            err(EXIT_FAILURE, "fcntl");
            exit(1);
        }
    }



}

int prod(char *name) {//, ssize_t len, char *seals_arg) {
    // declare size of the command and piped stdout result
    char apply_diff[MAX_COMMAND_LENGTH];
    char result_patch[MAX_FILE_SIZE];
    ssize_t result_patch_len = strlen(result_patch);

    // command to be run over the pipe
    snprintf(apply_diff, sizeof(apply_diff), "patch -p1 < ./artifacts/vmlinux/x86/vmlinux.h.patch");

    // open a pipe (command_pipe) to run the command
    FILE *command_pipe = popen(apply_diff, "r");
    if (command_pipe == NULL) {
        perror("Error opening pipe for command");
        return 1;
    }

    // execute the program and store its result into result_patch
    if (fgets(result_patch, sizeof(result_patch), command_pipe) == NULL) {
        perror("Error reading command output");
        pclose(command_pipe); // close if error
        return 1;
    }

    // close the pipe (command_pipe)
    pclose(command_pipe);

    // print contents of the diff patch to the stdout
    //printf("Result of command: %s", result_patch);
    //printf("result_patch is of type:[ %s ].", result_patch);

    // invoke method containing the memfd_create function
    //
    // also always start with the MFD_ALLOW_SEALING by default.
    tmpfs_create(name, result_patch_len, "WwS"); //, MFD_ALLOW_SEALING);

    //
    return 0;
}

// consume the memory-mapped file
void cons(int fd_path, unsigned int seals) {
//int cons(int fd, unsigned int seals) {
    printf("Existing seals:");
    if (seals & F_SEAL_SEAL)
       printf(" SEAL");
    if (seals & F_SEAL_GROW)
       printf(" GROW");
    if (seals & F_SEAL_WRITE)
       printf(" WRITE");
    if (seals & F_SEAL_FUTURE_WRITE)
       printf(" FUTURE_WRITE");
    if (seals & F_SEAL_SHRINK)
       printf(" SHRINK");
    printf("\n");

    // signal receive declarations (from make build)
    struct sigaction sa;
    sa.sa_handler = intp_signal;
    sigemptyset(&sa.sa_mask); // clear all the bits of the sa_mask, which is the mask of signals to be blocked during execution
    sa.sa_flags = 0;

    // 4. keep running; if signal is received to end the memfd creation,
    // stop the tmpfs file
    if (sigaction(SIGINT, &sa, NULL) == -1) {
        perror("sigaction");
        pause();
        exit(EXIT_SUCCESS); //0
    }
}

int main(int argc, char *argv[]){
    // file to raw bytes
    // file conversion to tmpfs
    FILE *inputFile;
    char *contentFile;
    long sizeFile;
    size_t bytesRead;
    int fd;
    unsigned int seals;

    //if (strcmp(argv[1], "prod") == 0) {
    if (argc < 3) {
        //fprintf(stderr, "Usage: %s /*(prod || cons)*/ name size seals\n", argv[0]);
        fprintf(stderr, "Usage: %s name\n", argv[0]);
    }

    if (argc < 2) {
        fprintf(stderr, "%s name size [seals]\n", argv[0]);
        fprintf(stderr, "\t'seals' can contain any of the "
                "following characters:\n");
        fprintf(stderr, "\t\tg - F_SEAL_GROW\n");
        fprintf(stderr, "\t\ts - F_SEAL_SHRINK\n");
        fprintf(stderr, "\t\tw - F_SEAL_WRITE\n");
        fprintf(stderr, "\t\tW - F_SEAL_FUTURE_WRITE\n");
        fprintf(stderr, "\t\tS - F_SEAL_SEAL\n");
        exit(EXIT_FAILURE); // 1

    }

    char *name = argv[1];
    //ssize_t len = atoi(argv[2]);
    //char *seals_arg = argc > 3 ? argv[3] : NULL;
    //
    // seals isn't needed since it is already defined by default on prod
    prod(name);//, len, seals_arg);
    //}
    /*
    else if (strcmp(argv[1], "cons") == 0) {
        if (argc != 2) {
            fprintf(stderr, "%s /proc/PID/fd/FD\n", argv[0]);
            exit(EXIT_FAILURE);
        }

        fd = open(argv[1], O_RDWR);
        if (fd == -1)
            err(EXIT_FAILURE, "open");

        seals = fcntl(fd, F_GET_SEALS);
        if (seals == -1)
            err(EXIT_FAILURE, "fcntl");

        cons(fd, seals);
    }*/

    pid_t pid;
    pid = fork();

    if (pid < 0) {
        fprintf(stderr, "Fork failed");
        return 1;
    }
    else if (pid == 0) {
        cons(fd, seals);
        sleep(1000);
        //exit(0);
    }

    return 0;
}

void outro() {
    char command[1000];
    snprintf(command, sizeof(command), "echo idk");
    printf("command is of type: %s\n", TYPEOF(command));
}
