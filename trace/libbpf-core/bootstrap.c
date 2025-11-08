/* userspace program */

#include <argp.h>
#include <linux/bpf.h>
#include <signal.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h> // strtol
#include <string.h>
#include <time.h>
#include <sys/resource.h> // locked memory limits
#include <bpf/libbpf.h>
#include "bootstrap.h"
#include "bootstrap.skel.h"


static struct env {
    bool verbose;
    long min_duration_ns;

    // tracee
    int pgid;
    int tgid;
    int pid;
    int tid;
} env;


/*--------------------------------*/
// parsing command-line arguments with ARGP
//

// 1. define version, 2. define bugs community; 3. define docs
const char *argp_program_version = "bootstrap 0.0";
const char *argp_program_bug_address = "https://github.com/deomorxsy/kjx-headless/issues";
const char argp_program_doc[] =
"BPF bootstrap demo app"
"\n"
"Tracing process starts and exits\n"
"associated info. (filename, duration, PID/PPID, etc)"
"\n"
"USAGE: ./bootstrap [-d <min-duration-ms>] [-v]\n";

static const struct argp_option opts[] = {
    { "verbose", 'v', NULL, 0, "verbose output debug" },
    { "duration", 'd', "DURATION-MS", 0, "minimum process duration (ms) to report" },
    {},
};

static error_t parse_arg(int key, char *arg, struct argp_state *state)
{
    switch (key) {
        case 'v':
            env.verbose = true;
            break;
        case 'd':
            errno = 0;
            env.min_duration_ns = strtol(arg, NULL, 10);
        if (errno || env.min_duration_ns <= 0) {
        fprintf(stderr, "Invalid duration: %s\n", arg);
        argp_usage(state);

        }

        break;
        case ARGP_KEY_ARG:
            argp_usage(state);
            break;
        default:
            return ARGP_ERR_UNKNOWN;
    }
    return 0;
}


static const struct argp argp = {
.options = opts,
.parser = parse_arg,
.doc = argp_program_doc,
};

/*--------------------------------*/
// investigate logs with printk() for message logging
static int libbpf_print_fn(enum libbpf_print_level level, const char *format, va_list args)
{
    if (level == LIBBPF_DEBUG && !env.verbose)
        return 0;
    return vfprintf(stderr, format, args);
}

static volatile bool exiting = false;

static void sig_handler(int sig)
{
    exiting = true;
}

static int handle_event(void *ctx, void *data, size_t data_sz)
{
    const struct event *e = data;
    struct tm *tm; // time structure containing calendar date and time broken into components
    char ts[32]; // char array of 32 characters
    time_t t;

    time(&t);
    tm = localtime(&t);
    strftime(ts, sizeof(ts), "%H:%M:%S", tm);

    // gets the member called "exit_event" from the struct that "e" points to.
    if (e->exit_event)
    { // e->exit_event == (*foo).exit_event, where foo is a struct
        printf("%-8s %-5s %-16s %-7d %-7d [%u]",
                ts,
                "EXIT",
                e->comm /*(*e).comm*/,
                e->pid /* (*e).pid */,
                e->ppid /* (*e).ppid */,
                e->exit_code /* (*e).exit_code */
                );
        if (e->duration_ns)
            printf("(%llums)", e->duration_ns / 10000000);
        printf("\n");
    } else {
        printf("%-8s %-5s %-16s %-7d %-7d %s\n",
                ts,
                "EXEC",
                e->comm /*(*e).comm*/,
                e->pid /* (*e).pid */,
                e->ppid /* (*e).ppid */,
                e->filename /* (*e).exit_code */
                );
    }

    return 0;
}

/*--------------------------------*/
// setting resource limits with the resource controller
//
// "BPF programs and maps are memcg accounted. setrlimit is obsolete. Remove its use from bpf preload."
// ---> from Alexei at the bpf-next mailing list: https://patchwork.kernel.org/project/netdevbpf/patch/20220131220528.98088-5-alexei.starovoitov@gmail.com/#24720170
struct rlimit rlim = { // set resource limits
        // 512MBs = 512 * 2^20
        .rlim_cur = 512UL << 20,
        .rlim_max = 512UL << 20,
    };

int main(int argc, char **argv) {

    // sets resource limits with the resource controller
    int err;
    err = setrlimit(RLIMIT_MEMLOCK, &rlim);
    if (err) {
        perror("setrlimit");
        return 1;
    }

    struct ring_buffer *rb = NULL;
    struct bootstrap_bpf *skel;
    //int err;

    err = argp_parse(&argp, argc, argv, 0, NULL, NULL);
    if (err)
        return err;

    /* set up libbpf errors and debug info callback */
    libbpf_set_print(libbpf_print_fn);

    /* cleaner handling of Ctrl-C */
    signal(SIGINT, sig_handler);
    signal(SIGTERM, sig_handler);

    /* Load and verify BPF application */
    skel = bootstrap_bpf__open();
    if (!skel) {
        fprintf(stderr, "Failed to open and load BPF skeleton\n");
        return 1;
    }

    /* parametrize BPF code with minimum duration parameter */
    skel->rodata->min_duration_ns = env.min_duration_ns * 1000000ULL;
    // (*skel)
    // (*skel).rodata
    // (*(*skel).rodata)
    // (*(*skel).rodata).min_duration_ns
    //
    // foo->bar is equivalent to (*foo).bar, i.e. it gets the member called bar from the struct that foo points to.




    /* Load and verify BPF programs */
    err = bootstrap_bpf__load(skel);
    if (err) {
        fprintf(stderr, "Failed to load and verify BPF skeleton\n");
        goto cleanup;
    }

    /* attach tracepoints */
    err = bootstrap_bpf__attach(skel);
    if (err) {
        fprintf(stderr, "Failed to attach BPF skeleton\n");
        goto cleanup;
    }

    /* set up ring buffer polling */
    // bpf maps depends on file descriptors and can be accessed by userspace also using fds.
    rb = ring_buffer__new(bpf_map__fd(skel->maps.rb), handle_event, NULL, NULL);
    if (!rb) {
        err = -1;
        fprintf(stderr, "Failed to create ring buffer!\n");
        goto cleanup;
    }

    /* process events */
    printf("%-8s %-5s %-16s %-7s %-7s %s\n", "TIME", "EVENT", "COMM", "PID", "PPID",
	       "FILENAME/EXIT CODE");
    while (!exiting) {
        err = ring_buffer__poll(rb, 100 /*timeout, ms*/);
        /* ctrl+c will return -EINTR */
        if (err == -EINTR) {
            err = 0;
            break;
        }
        if (err < 0) {
            printf("Error polling perf buffer: %d\n", err);
            break;
        }
    }




    cleanup:
        /* clean up */
        ring_buffer__free(rb);
        bootstrap_bpf__destroy(skel);

        return err < 0 ? -err : 0;


}
