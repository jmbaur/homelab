/* FFI helpers for homelab-backup-recv.scm. */
#include <arpa/inet.h>
#include <errno.h>
#include <fcntl.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <unistd.h>

static char ip6_buf[INET6_ADDRSTRLEN];

static const char *canonical_ip6(const char *s)
{
	struct in6_addr addr;

	if (inet_pton(AF_INET6, s, &addr) != 1)
		return NULL;
	return inet_ntop(AF_INET6, &addr, ip6_buf, sizeof(ip6_buf));
}

static const char *peer_ip6(int fd)
{
	struct sockaddr_in6 sa;
	socklen_t len = sizeof(sa);

	if (getpeername(fd, (struct sockaddr *)&sa, &len) < 0 || sa.sin6_family != AF_INET6)
		return NULL;
	return inet_ntop(AF_INET6, &sa.sin6_addr, ip6_buf, sizeof(ip6_buf));
}

/* Returns -errno on failure. */
static int listen6(int port)
{
	int on = 1, err, fd = socket(AF_INET6, SOCK_STREAM | SOCK_CLOEXEC, 0);
	struct sockaddr_in6 sa = {
		.sin6_family = AF_INET6,
		.sin6_port = htons(port),
		.sin6_addr = IN6ADDR_ANY_INIT,
	};

	if (fd < 0)
		return -errno;
	if (setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &on, sizeof(on)) < 0 ||
		bind(fd, (struct sockaddr *)&sa, sizeof(sa)) < 0 ||
		listen(fd, SOMAXCONN) < 0) {
		err = errno;
		close(fd);
		return -err;
	}
	return fd;
}
