#include <sys/socket.h>
#include <string.h>

// Needed to define `RTLD_NEXT`.
#define __USE_GNU
#include <dlfcn.h>

typedef int (*orig_connect_t)(int, const struct sockaddr*, socklen_t)

int connect(int fd, const struct sockaddr *orig_addr, socklen_t len) {
  orig_connect_t orig_connect;
  if (!orig_connect) {
    orig_connect = (orig_connect_t)dlsym(RTLD_NEXT, "connect");
  }
  struct sockaddr addr = *orig_addr;
  if (addr.sa_family == AF_UNIX && strcmp(addr.sa_data, "/dev/log") == 0) {
    strcpy(addr.sa_data, "/dev/null");
  }
  return orig_connect(fd, orig_addr, len);
}
