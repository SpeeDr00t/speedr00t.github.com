/*
    Must be compiled against (within)
	gnome-libs-1.4.2/zvt
    because it uses *.h files from there.
    Code "stolen" from subshell.c .
*/

#include <sys/types.h>

#include "subshell-includes.h"
#define ZVT_TERM_DO_UTMP_LOG 1
#define ZVT_TERM_DO_WTMP_LOG 2
#define ZVT_TERM_DO_LASTLOG  4

/* Pid of the helper SUID process */
static pid_t helper_pid;

/* The socketpair used for the protocol */
int helper_socket_protocol  [2];

/* The parallel socketpair used to transfer file descriptors */
int helper_socket_fdpassing [2];

#include <sys/socket.h>
#include <sys/uio.h>

static struct cmsghdr *cmptr;
#define CONTROLLEN  sizeof (struct cmsghdr) + sizeof (int)

static int
receive_fd (int helper_fd)
{
	struct iovec iov [1];
	struct msghdr msg;
	char buf [32];
	
	iov [0].iov_base = buf;
	iov [0].iov_len  = sizeof (buf);
	msg.msg_iov      = iov;
	msg.msg_iovlen   = 1;
	msg.msg_name     = NULL;
	msg.msg_namelen  = 0;

	if (cmptr == NULL && (cmptr = malloc (CONTROLLEN)) == NULL)
		return -1;
	msg.msg_control = (caddr_t) cmptr;
	msg.msg_controllen = CONTROLLEN;

	if (recvmsg (helper_fd, &msg, 0) <= 0)
		return -1;

	return *(int *) CMSG_DATA (cmptr);
}

static int
s_pipe (int fd [2])
{
	return socketpair (AF_UNIX, SOCK_STREAM, 0, fd);
}

static void *
get_ptys (int *master, int *slave, int update_wutmp)
{
	GnomePtyOps op;
	int result, n;
	void *tag;
	
	if (helper_pid == -1)
		return NULL;

	if (helper_pid == 0){
		if (s_pipe (helper_socket_protocol) == -1)
			return NULL;

		if (s_pipe (helper_socket_fdpassing) == -1){
			close (helper_socket_protocol [0]);
			close (helper_socket_protocol [1]);
			return NULL;
		}
		
		helper_pid = fork ();
		
		if (helper_pid == -1){
			close (helper_socket_protocol [0]);
			close (helper_socket_protocol [1]);
			close (helper_socket_fdpassing [0]);
			close (helper_socket_fdpassing [1]);
			return NULL;
		}

		if (helper_pid == 0){
			close (0);
			close (1);
			dup2 (helper_socket_protocol  [1], 0);
			dup2 (helper_socket_fdpassing [1], 1);

			/* Close aliases */
			close (helper_socket_protocol  [0]);
			close (helper_socket_protocol  [1]);
			close (helper_socket_fdpassing [0]);
			close (helper_socket_fdpassing [1]);

			execl ("/usr/sbin/gnome-pty-helper", "gnome-pty-helper", NULL);
			exit (1);
		} else {
			close (helper_socket_fdpassing [1]);
			close (helper_socket_protocol  [1]);

			/*
			 * Set the close-on-exec flag for the other
			 * descriptors, these should never propagate
			 * (otherwise gnome-pty-heler wont notice when
			 * this process is killed).
			 */
			fcntl (helper_socket_protocol [0], F_SETFD, FD_CLOEXEC);
			fcntl (helper_socket_fdpassing [0], F_SETFD, FD_CLOEXEC);
		}
	}
	op = GNOME_PTY_OPEN_NO_DB_UPDATE;
	
	if (update_wutmp & ZVT_TERM_DO_UTMP_LOG){
		if (update_wutmp & (ZVT_TERM_DO_WTMP_LOG | ZVT_TERM_DO_LASTLOG))
			op = GNOME_PTY_OPEN_PTY_LASTLOGUWTMP;
		else if (update_wutmp & ZVT_TERM_DO_WTMP_LOG)
			op = GNOME_PTY_OPEN_PTY_UWTMP;
		else if (update_wutmp & ZVT_TERM_DO_LASTLOG)
			op = GNOME_PTY_OPEN_PTY_LASTLOGUTMP;
		else
			op = GNOME_PTY_OPEN_PTY_UTMP;
	} else if (update_wutmp & ZVT_TERM_DO_WTMP_LOG) {
		if (update_wutmp & (ZVT_TERM_DO_WTMP_LOG | ZVT_TERM_DO_LASTLOG))
			op = GNOME_PTY_OPEN_PTY_LASTLOGWTMP;
		else if (update_wutmp & ZVT_TERM_DO_WTMP_LOG)
			op = GNOME_PTY_OPEN_PTY_WTMP;
	} else
		if (update_wutmp & ZVT_TERM_DO_LASTLOG)
			op = GNOME_PTY_OPEN_PTY_LASTLOG;
	
	if (write (helper_socket_protocol [0], &op, sizeof (op)) < 0)
		return NULL;
	
	n = read (helper_socket_protocol [0], &result, sizeof (result));
	if (n == -1 || n != sizeof (result)){
		helper_pid = 0;
		return NULL;
	}
	
	if (result == 0)
		return NULL;

	n = read (helper_socket_protocol [0], &tag, sizeof (tag));
	
	if (n == -1 || n != sizeof (tag)){
		helper_pid = 0;
		return NULL;
	}

	*master = receive_fd (helper_socket_fdpassing [0]);
	*slave  = receive_fd (helper_socket_fdpassing [0]);
	
	return tag;
}

int main (int argc, char* argv[])
{
	int slave_pty, master_pty;
	void* mytag;
	int log = ZVT_TERM_DO_UTMP_LOG;
	char buf[1000];

printf("Writing utmp (who) record for DISPLAY=%s\n", argv[1]);
setenv("DISPLAY",argv[1],1);

	if ((mytag = get_ptys (&master_pty, &slave_pty, log)) == NULL)
		return;

sprintf(buf,"who | grep %s",argv[1]);
printf("Running %s\n",buf);
system(buf);
printf("utmp (who) record will be cleaned up when we exit.\n");
printf("To leave it behind, kill gnome-pty-helper: kill %d\n",helper_pid);

printf("Sleeping for 5 secs...\n");
sleep (5);
}



