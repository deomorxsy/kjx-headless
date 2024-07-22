// Definitions for system call wrappers for
// commands supported by the sys_bpf system call.

#ifndef __BOOTSTRAP_H
#define __BOOTSTRAP_H

#define TASK_COMM_LEN 16
#define MAX_FILENAME_LEN 127

// filename: executable file path
// pid: process id
// comm: process name
struct event {
    int pid;
    int ppid;
    unsigned exit_code;
    unsigned long long duration_ns;
    char comm[TASK_COMM_LEN];
    char filename[MAX_FILENAME_LEN];
    bool exit_event;
};
#endif /*__BOOTSTRAP_H*/
