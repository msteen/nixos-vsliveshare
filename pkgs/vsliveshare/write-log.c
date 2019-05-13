#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>

int main(int argc, char **argv) {
  int fd = socket(AF_UNIX, SOCK_DGRAM, 0);
  if (fd < 0) {
    perror("opening UNIX DGRAM socket");
    exit(1);
  }
  struct sockaddr addr;
  memset(&addr, 0, sizeof(addr));
  addr.sa_family = AF_UNIX;
  strcpy(addr.sa_data, "/dev/log");
  if (connect(fd, &addr, sizeof(addr)) < 0) {
    close(fd);
    perror("connecting to UNIX DGRAM socket");
    exit(1);
  }
  char *data = argc > 1 ? argv[1] : "Hello World!";
  if (write(fd, data, strlen(data)) < 0) {
    close(fd);
    perror("writing to UNIX DGRAM socket");
    exit(1);
  }
  return 0;
}
