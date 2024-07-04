// This program loads the vmlinux header patch into memory, so it can be
// recognized by clangd. By doing this, the environment both supports:
// 1) the pattern of not including direct headers (the patch) into the
// git repository, and 2) Any language server protocol (LSP) that needs
// the header. -deomorxsy

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

#ifdef novmlinux
#pragma message "Patch vmlinux into virtual memory"

std::ifstream

#endif
// handle signals
void intp_signal(int signum) {
    printf("Intercepted signal: %d\n", signum);
    exit(1);

}

// create tmpfs file with memfd_create
void tmpfs_create(char *name, ssize_t len, char *seals_arg) {

    // file descriptor declarations
    int             fd;
    unsigned int    seals;

    // signal receive declarations (from make build)
    struct sigaction sa;
    sa.sa_handler = intp_signal;
    sigemptyset(&sa.sa_mask); // clear all the bits of the sa_mask, which is the mask of signals to be blocked during execution
    sa.sa_flags = 0;

    // 1. create anonymous file into tmpfs
    fd = memfd_create(name, MFD_ALLOW_SEALING);
    if (fd == -1)
        err(EXIT_FAILURE, "memfd_create");

    // 2. enforce the file size to match the specified by len
    if (ftruncate(fd, len) == -1)
        err(EXIT_FAILURE, "truncate");

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

        if (fcntl(fd, F_ADD_SEALS, seals) == -1)
            err(EXIT_FAILURE, "fcntl");
    }

    // 4. keep running; if signal is received to end the memfd creation,
    // stop the tmpfs file
    if (sigaction(SIGINT, &sa, NULL) == -1) {
        perror("sigaction");
        pause();
        exit(EXIT_SUCCESS);
    }

}


int main(int argc, char *argv[]){
    // file to raw bytes
    // file conversion to tmpfs
    FILE *inputFile;
    char *contentFile;
    long sizeFile;
    size_t bytesRead;

    // declare size of the command and piped stdout result
    char apply_diff[MAX_COMMAND_LENGTH];
    char result_patch[MAX_FILE_SIZE];

    // local function call (tmpfs_create) declarations
    char *name, *seals_arg;
    ssize_t len;

    if (argc < 3) {
        fprintf(stderr, "%s name size [seals]\n", argv[0]);
        fprintf(stderr, "\t'seals' can contain any of the "
                "following characters:\n");
        fprintf(stderr, "\t\tg - F_SEAL_GROW\n");
        fprintf(stderr, "\t\ts - F_SEAL_SHRINK\n");
        fprintf(stderr, "\t\tw - F_SEAL_WRITE\n");
        fprintf(stderr, "\t\tW - F_SEAL_FUTURE_WRITE\n");
        fprintf(stderr, "\t\tS - F_SEAL_SEAL\n");
        exit(EXIT_FAILURE);

    }

    // variable assignment
    name = argv[1];
    len = atoi(argv[2]);
    seals_arg = argv[3];


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
    tmpfs_create(result_patch, MFD_ALLOW_SEALING);

    //
    return 0;
}





void outro() {
    char command[1000];
    snprintf(command, sizeof(command), "echo idk");
    printf("command is of type:", typeof(command));
}
