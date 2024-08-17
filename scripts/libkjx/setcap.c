#include <linux/capability.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <unistd.h>
#include <sys/prctl.h>
#include <sys/capability.h>
#include <signal.h>
#include <sys/wait.h>
//#include <cap-ng.h>


// 0. maybe drop all capabilities
// 1. fork the process
// 2. it gets the same PID and capabilities (TGID)
// 3. get current process TGID (Thread Group ID)
// 4. commit capabilities list, caplist
// 5. set capability on process TGID
int net_cap_set() {
    // get current process pid (this will be a forked child)
    // forked processes get the same capabilities as the parent.
    cap_t caps = cap_get_proc(); // gets the TGID (Thread Group ID)

    // PS: to get the PID (Thread ID), for just one thread
    // use cap_get_pid() instead with the same cap_t type.


    // if the pid of the process wasn't stored...
    if (!caps || caps == NULL) {
        perror("cap_get_proc");
        return -1;
    }

    // initialize caplist with two types of capabilities
    cap_value_t cap_list[2];
    cap_list[0] = CAP_NET_ADMIN;
    cap_list[1] = CAP_FSETID;

    // commit caplist into the thread of the current process
    // (actually, getpid() returns the TGID, Thread Group ID.
    // gettid() returns the PID, which is the Thread ID.
    // cap_get_proc() up there concerns the TGID, so it's like
    // getpid().)
    cap_set_flag(caps, CAP_INHERITABLE, 1, cap_list, CAP_SET);

    // set capability on process
    if (cap_set_proc(caps) == -1) {
        perror("cap_set_proc");
        cap_free(caps);
        return -1;
    }

    // free capt_t structure
    cap_free(caps);
    return 0;
}

int callscript(){
    // alternatively to a fork, use system()
    // int foo = system("busybox sh ./scripts/qemu-myifup.sh");

    pid_t pid = fork();

    if (pid == -1) {
        perror("fork");
        exit(EXIT_FAILURE);
    } else if (pid == 0){
        execl("/bin/sh", "./scripts/virt-platforms/qemu-myifup.sh", (char *)NULL);

        perror("execl");
        exit(EXIT_FAILURE);
    } else if (pid > 0) {
        // wait for children to exit
        printf("Child PID: %d\n", pid);
        int status;
        waitpid(pid, &status, 0);
        if (WIFEXITED(status) && WEXITSTATUS(status) == 0) {
            printf("Network setup success! :-D");
        } else {
            fprintf(stderr, "network setup failed :(");
            return EXIT_FAILURE;
        }
        return EXIT_SUCCESS;
    } else {
        perror("fork");
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}

int main(int argc, char *argv[]) {
    //int bar = system("$$");
    int foobar = getpid();
    printf("current process pid: %d\n", foobar);

    callscript();
    //dace(pid_t target_pid);

    if (net_cap_set()) {
        fprintf(stderr, "Failed to set CAP_NET_ADMIN");
        return EXIT_FAILURE;
    }



}

