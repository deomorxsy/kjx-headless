#include <stdio.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <linux/wireless.h>

int main(int argc, char *argv[]) {

    int ret;
    struct ifreq req;
    //struct sockaddr_in *addr;
    int s;

    if (argc != 2) {
        fprintf(stderr, "Missing interface name (e.g. enp4s0)");
        return 1;
    }

    s = socket(AF_INET, SOCK_DGRAM, 0);
    if (s < 0) {
        perror("Cannot open socket");
        return 1;
    }

    strncpy(req.ifr_name, argv[1], sizeof(req.ifr_name));
    //SIOCGIWNAME is used to verify the presence of Wireless Extensions
    ret = ioctl(s, SIOCGIWNAME, &req);

    if (ret < 0) {
        fprintf(stderr, "No wireless extension\n");
        return 1;
    }

    printf("%s\n", req.ifr_name);
    printf("%s\n", req.ifr_newname);
    return 0;
}
