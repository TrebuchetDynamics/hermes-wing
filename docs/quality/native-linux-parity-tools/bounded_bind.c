#define _GNU_SOURCE
#include <dlfcn.h>
#include <errno.h>
#include <netinet/in.h>
#include <pthread.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>

static pthread_once_t initialized = PTHREAD_ONCE_INIT;
static int (*system_bind)(int, const struct sockaddr *, socklen_t);
static unsigned sequence;
static void initialize(void) { system_bind = dlsym(RTLD_NEXT, "bind"); }

// Test invocation only: constrain OS-assigned TCP listener ports, including
// Flutter's internal VM/test sockets for which `flutter test` has no port flag.
int bind(int fd, const struct sockaddr *address, socklen_t length) {
  pthread_once(&initialized, initialize);
  const char *value = getenv("AUTOWORK_PORT_BASE");
  int type = 0; socklen_t type_length = sizeof(type);
  if (!value || !address || getsockopt(fd, SOL_SOCKET, SO_TYPE, &type, &type_length)
      || type != SOCK_STREAM || (address->sa_family != AF_INET && address->sa_family != AF_INET6))
    return system_bind(fd, address, length);
  char *end; long base = strtol(value, &end, 10);
  if (!*value || *end || base < 1024 || base > 65436 || length > sizeof(struct sockaddr_storage)) {
    errno = EINVAL; return -1;
  }
  struct sockaddr_storage copy; memset(&copy, 0, sizeof(copy)); memcpy(&copy, address, length);
  unsigned short *port = address->sa_family == AF_INET
    ? &((struct sockaddr_in *)&copy)->sin_port : &((struct sockaddr_in6 *)&copy)->sin6_port;
  if (*port) {
    unsigned supplied = ntohs(*port);
    if (supplied < base || supplied > base + 99) { errno = EACCES; return -1; }
    return system_bind(fd, address, length);
  }
  unsigned start = __atomic_fetch_add(&sequence, 1, __ATOMIC_RELAXED);
  for (unsigned i = 0; i < 20; i++) {
    *port = htons(base + 80 + (start + i) % 20);
    if (system_bind(fd, (const struct sockaddr *)&copy, length) == 0) return 0;
    if (errno != EADDRINUSE) return -1;
  }
  errno = EADDRINUSE; return -1;
}
