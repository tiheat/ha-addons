/* LD_PRELOAD shim: reports $HOSTNAME_OVERRIDE as the hostname to uname() and
 * gethostname(). The Supervisor picks the container hostname and the add-on
 * has no CAP_SYS_ADMIN to change it, but the machine name shown in
 * claude.ai/code comes from these calls (both imported from musl). */
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <sys/syscall.h>
#include <sys/utsname.h>
#include <unistd.h>

static const char *name(void) {
  const char *n = getenv("HOSTNAME_OVERRIDE");
  return n && *n ? n : NULL;
}

int uname(struct utsname *u) {
  if (syscall(SYS_uname, u) != 0) return -1;
  const char *n = name();
  if (n) {
    strncpy(u->nodename, n, sizeof u->nodename - 1);
    u->nodename[sizeof u->nodename - 1] = 0;
  }
  return 0;
}

int gethostname(char *buf, size_t len) {
  struct utsname u;
  if (uname(&u) != 0) return -1;
  size_t l = strlen(u.nodename);
  if (l >= len) { errno = ENAMETOOLONG; return -1; }
  memcpy(buf, u.nodename, l + 1);
  return 0;
}
